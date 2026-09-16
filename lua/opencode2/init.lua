local M = {}

M.config = {
  cmd = "opencode2",
  script_path = nil,
  tmux_width_percentage = 28,
  min_width = 45,
  auto_reload = true,
}

local function get_plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  local lua_dir = vim.fs.dirname(source)
  local lua_parent = vim.fs.dirname(lua_dir)
  return vim.fs.dirname(lua_parent)
end

function M.get_script_path()
  if M.config.script_path and vim.fn.filereadable(M.config.script_path) == 1 then
    return M.config.script_path
  end

  -- Try bundled script in plugin root
  local bundled = get_plugin_root() .. "/bin/tmux-opencode-toggle"
  if vim.fn.filereadable(bundled) == 1 then
    return bundled
  end

  -- Try user local bin fallback
  local local_bin = vim.fn.expand("~/.local/bin/tmux-opencode-toggle")
  if vim.fn.filereadable(local_bin) == 1 then
    return local_bin
  end

  return "tmux-opencode-toggle"
end

function M.get_buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name and name ~= "" then
    local stat = vim.uv.fs_stat(name)
    if stat and stat.type == "directory" then
      return name
    end
    local parent = vim.fs.dirname(name)
    if parent and parent ~= "" and vim.uv.fs_stat(parent) then
      return parent
    end
  end
  return vim.fn.getcwd()
end

function M.get_project_root()
  local ok, lazy_root = pcall(function()
    return require("lazyvim.util").root()
  end)
  if ok and lazy_root and lazy_root ~= "" then
    return lazy_root
  end

  local git_root = vim.fs.root(0, { ".git" })
  if git_root and git_root ~= "" then
    return git_root
  end

  return vim.fn.getcwd()
end

--- Get the visible OpenCode tmux pane id in the current window (if any)
function M.get_visible_pane()
  if not (vim.env.TMUX and vim.env.TMUX ~= "") then
    return nil
  end
  local current_win = vim.trim(vim.fn.system("tmux display-message -p '#{window_id}'"))
  local cmd = string.format("tmux list-panes -t %s -F '#{pane_id} #{@opencode}' | awk '$2 == \"1\" {print $1; exit}'", current_win)
  local pane = vim.trim(vim.fn.system(cmd))
  if pane ~= "" then
    return pane
  end
  return nil
end

--- Ensure OpenCode pane is visible, returning its pane_id
function M.ensure_visible_pane(dir)
  local pane = M.get_visible_pane()
  if pane then
    return pane
  end

  -- Not visible: toggle it open
  M.toggle(dir)

  -- Wait briefly for tmux pane creation/join
  for _ = 1, 10 do
    vim.cmd("sleep 30m")
    pane = M.get_visible_pane()
    if pane then
      return pane
    end
  end
  return M.get_visible_pane()
end

--- Send arbitrary text to OpenCode pane via tmux buffer
function M.send_text(text, submit)
  if not (vim.env.TMUX and vim.env.TMUX ~= "") then
    vim.notify("OpenCode send_text requires running inside tmux", vim.log.levels.WARN)
    return
  end

  local pane = M.ensure_visible_pane()
  if not pane then
    vim.notify("Could not find or open OpenCode pane", vim.log.levels.ERROR)
    return
  end

  local buf_name = "oc2_" .. vim.uv.hrtime()

  -- Load text into tmux buffer via stdin to preserve special characters & formatting
  local p = io.popen(string.format("tmux load-buffer -b %s -", buf_name), "w")
  if p then
    p:write(text)
    p:close()
    vim.fn.system(string.format("tmux paste-buffer -b %s -t %s -d", buf_name, pane))
    if submit then
      vim.fn.system(string.format("tmux send-keys -t %s Enter", pane))
    end
  else
    vim.notify("Failed to write to tmux load-buffer", vim.log.levels.ERROR)
  end
end

--- Send visual selection to OpenCode with relative path and line numbers
function M.send_selection()
  -- Exit visual mode to set '< and '> marks
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd("normal! \27")
  end

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local content = table.concat(lines, "\n")
  local file = vim.fn.expand("%:.")
  if file == "" then
    file = "[buffer]"
  end
  local ft = vim.bo.filetype or ""

  local payload = string.format(
    "In `%s` (lines %d-%d):\n```%s\n%s\n```\n",
    file,
    start_line,
    end_line,
    ft,
    content
  )

  M.send_text(payload, false)
  vim.notify(string.format("Sent lines %d-%d of %s to OpenCode", start_line, end_line, file), vim.log.levels.INFO)
end

--- Send the LSP/diagnostic error under cursor to OpenCode
function M.send_diagnostic()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local diags = vim.diagnostic.get(0, { lnum = lnum })

  if #diags == 0 then
    vim.notify("No diagnostic on current line", vim.log.levels.WARN)
    return
  end

  local file = vim.fn.expand("%:.")
  if file == "" then
    file = "[buffer]"
  end
  local line_content = vim.api.nvim_get_current_line()
  local ft = vim.bo.filetype or ""

  local diag_msgs = {}
  for i, d in ipairs(diags) do
    local source = d.source and ("[" .. d.source .. "] ") or ""
    table.insert(diag_msgs, string.format("- %s%s", source, d.message))
  end

  local prompt = string.format(
    "Please fix this diagnostic issue in `%s` (line %d):\n\n**Diagnostic:**\n%s\n\n**Code:**\n```%s\n%s\n```\n",
    file,
    lnum + 1,
    table.concat(diag_msgs, "\n"),
    ft,
    line_content
  )

  M.send_text(prompt, false)
  vim.notify(string.format("Sent diagnostic on line %d to OpenCode", lnum + 1), vim.log.levels.INFO)
end

--- Quick query input popup
function M.ask(query)
  if query and query ~= "" then
    local file = vim.fn.expand("%:.")
    local msg
    if file and file ~= "" then
      msg = string.format("[Context: %s] %s\n", file, query)
    else
      msg = string.format("%s\n", query)
    end
    M.send_text(msg, true)
    return
  end

  vim.ui.input({ prompt = "Ask OpenCode: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end
    local file = vim.fn.expand("%:.")
    local msg
    if file and file ~= "" then
      msg = string.format("[Context: %s] %s\n", file, input)
    else
      msg = string.format("%s\n", input)
    end
    M.send_text(msg, true)
  end)
end

--- Focus navigation: switch focus to OpenCode pane without toggling/hiding it
function M.focus()
  if not (vim.env.TMUX and vim.env.TMUX ~= "") then
    return
  end

  local pane = M.get_visible_pane()
  if pane then
    vim.fn.system(string.format("tmux select-pane -t %s", pane))
  else
    M.toggle()
  end
end

function M.toggle(dir, cmd)
  cmd = cmd or M.config.cmd
  dir = dir or M.get_project_root()

  if vim.env.TMUX and vim.env.TMUX ~= "" then
    local current_pane = vim.env.TMUX_PANE
    if not current_pane or current_pane == "" then
      current_pane = vim.trim(vim.fn.system("tmux display-message -p '#{pane_id}'"))
    end
    local session = vim.trim(
      vim.fn.system(string.format("tmux display-message -p -t %s '#{session_name}'", current_pane))
    )
    local script = M.get_script_path()
    vim.fn.system({ script, current_pane, session, dir })
  else
    -- Fallback outside tmux: Snacks terminal or vertical split
    local ok_snacks, snacks = pcall(require, "snacks")
    if ok_snacks and snacks.terminal then
      snacks.terminal.toggle(cmd, {
        cwd = dir,
        win = {
          position = "right",
          width = M.config.tmux_width_percentage / 100,
        },
      })
    else
      vim.cmd(
        string.format(
          "botright %dvsplit | lcd %s | terminal %s",
          M.config.tmux_width_percentage,
          vim.fn.fnameescape(dir),
          cmd
        )
      )
    end
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if M.config.auto_reload then
    vim.opt.autoread = true
    local group = vim.api.nvim_create_augroup("OpenCodeAutoReload", { clear = true })
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
      group = group,
      desc = "Reload files changed externally by OpenCode",
      callback = function()
        if vim.fn.getcmdwintype() == "" then
          vim.cmd("checktime")
        end
      end,
    })
  end
end

return M
