local M = {}

M.config = {
  cmd = "opencode2",
  script_path = nil,
  tmux_width_percentage = 28,
  min_width = 45,
}

local function get_plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  -- source is .../lua/opencode2/init.lua
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
    -- Fallback outside tmux: Snacks terminal or terminal split
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
end

return M
