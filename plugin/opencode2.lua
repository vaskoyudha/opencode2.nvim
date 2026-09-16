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
