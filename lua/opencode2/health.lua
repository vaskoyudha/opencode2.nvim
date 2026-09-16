local M = {}

local health = vim.health or require("health")

function M.check()
  health.start("opencode2.nvim report")

  -- Check tmux
  if vim.fn.executable("tmux") == 1 then
    local version = vim.trim(vim.fn.system("tmux -V"))
    health.ok(string.format("tmux found: %s", version))
  else
    health.error("tmux is not installed or not in PATH")
  end

  -- Check if inside tmux
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    health.ok(string.format("Running inside tmux session ($TMUX=%s)", vim.env.TMUX:match("([^,]+)")))
  else
    health.warn("Not running inside tmux (will use Snacks.terminal or split fallback)")
  end

  -- Check OpenCode 2 binary
  local oc2 = require("opencode2")
  local cmd = oc2.config.cmd or "opencode2"
  if vim.fn.executable(cmd) == 1 then
    local bin_path = vim.trim(vim.fn.system(string.format("which %s", cmd)))
    local ver = vim.trim(vim.fn.system(string.format("%s --version 2>&1", cmd)))
    health.ok(string.format("%s executable found at %s (%s)", cmd, bin_path, ver))
  else
    health.error(string.format("'%s' command not found in PATH", cmd), {
      "Install OpenCode 2 via: npm install -g @opencode-ai/cli@beta",
    })
  end

  -- Check script path
  local script = oc2.get_script_path()
  if vim.fn.filereadable(script) == 1 then
    health.ok(string.format("Toggle script found: %s", script))
  else
    health.warn(string.format("Toggle script path '%s' not readable directly", script))
  end
end

return M
