if vim.g.loaded_opencode2 then
  return
end
vim.g.loaded_opencode2 = 1

local opencode2 = require("opencode2")

vim.api.nvim_create_user_command("OpenCodeToggle", function(opts)
  local dir
  if opts.args and opts.args ~= "" then
    dir = vim.fn.expand(opts.args)
  end
  opencode2.toggle(dir)
end, {
  nargs = "?",
  complete = "dir",
  desc = "Toggle OpenCode 2 pane (project root or specified directory)",
})

vim.api.nvim_create_user_command("OpenCodeToggleBufferDir", function()
  opencode2.toggle(opencode2.get_buffer_dir())
end, {
  desc = "Toggle OpenCode 2 pane in current buffer directory",
})

vim.api.nvim_create_user_command("OpenCodeSendSelection", function()
  opencode2.send_selection()
end, {
  range = true,
  desc = "Send visual selection to OpenCode with line and file context",
})

vim.api.nvim_create_user_command("OpenCodeSendDiagnostic", function()
  opencode2.send_diagnostic()
end, {
  desc = "Send diagnostic error on current line to OpenCode for fixing",
})

vim.api.nvim_create_user_command("OpenCodeQuery", function(opts)
  opencode2.ask(opts.args)
end, {
  nargs = "?",
  desc = "Quick query to OpenCode via floating input prompt",
})

vim.api.nvim_create_user_command("OpenCodeFocus", function()
  opencode2.focus()
end, {
  desc = "Focus OpenCode pane without toggling or hiding it",
})
