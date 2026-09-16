# opencode2.nvim ⚡

> Seamless, project-aware Neovim & tmux integration for **OpenCode v2** (`@opencode-ai/cli`).

`opencode2.nvim` provides a blazing-fast, robust bridge between Neovim and OpenCode 2 running in tmux. Unlike in-buffer terminal plugins that slow down editor rendering or crash when Neovim restarts, `opencode2.nvim` delegates the AI agent interface to a dedicated tmux pane managed through an **isolated background stash session (`_opencode_stash`)**.

Your agent stays alive in the background, preserves conversation context across project switches, and can be summoned, queried, or stashed instantly with zero latency.

---

## ✨ Features

- 🏎️ **Zero Editor Latency**: Runs OpenCode 2 in a dedicated tmux pane; Neovim remains 100% responsive.
- 📦 **Isolated Background Stash**: Toggling hides the pane into a hidden tmux session (`_opencode_stash`). No clutter in your tmux window list.
- 🔄 **Persistent Long-Running Tasks**: Tasks continue executing in the background even when hidden or if you restart Neovim.
- 🎯 **Project-Aware**: Automatically resolves project git roots. Switching projects restores the matching OpenCode session or spawns a new one on demand.
- ✂️ **Send Visual Selections (`<leader>as`)**: Highlight code and send it straight to OpenCode with relative file paths, line ranges, and language syntax tags.
- 🩺 **Fix Diagnostic Errors (`<leader>ae`)**: Press a key on any LSP/linter error line to package the exact error message and code context into a fix request.
- 💬 **Quick Query Popup (`<leader>aq`)**: Ask questions via a clean `vim.ui.input` prompt without switching focus away from your editor buffer.
- 🔭 **Focus Navigation (`<leader>af`)**: Seamlessly switch cursor focus between Neovim and OpenCode without accidentally hiding the pane.
- ⚡ **Auto File Reloading**: Automatically synchronizes buffers (`autoread` + `checktime`) when OpenCode writes code in the background.
- 🪟 **Fallback Outside Tmux**: Uses `Snacks.terminal` or native vertical split if not running inside tmux.

---

## 📋 Requirements

- **Neovim** >= 0.9.0
- **tmux** >= 3.0
- **OpenCode 2** CLI (`opencode2`, installed via `npm install -g @opencode-ai/cli@beta`)

---

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) / LazyVim

```lua
return {
  "vaskoyudha/opencode2.nvim",
  dependencies = { "folke/which-key.nvim" },
  keys = {
    -- Toggle OpenCode 2
    { "<A-a>", function() require("opencode2").toggle() end, mode = { "n", "i" }, desc = "Toggle OpenCode 2" },
    { "<leader>ao", function() require("opencode2").toggle(require("opencode2").get_buffer_dir()) end, desc = "Toggle OpenCode 2 (buffer dir)" },
    { "<leader>aO", function() require("opencode2").toggle() end, desc = "Toggle OpenCode 2 (project root)" },
    
    -- Interaction & Context
    { "<leader>as", function() require("opencode2").send_selection() end, mode = "v", desc = "Send selection to OpenCode" },
    { "<leader>ae", function() require("opencode2").send_diagnostic() end, desc = "Send line diagnostic to OpenCode" },
    { "<leader>aq", function() require("opencode2").ask() end, desc = "Quick query to OpenCode" },
    { "<leader>af", function() require("opencode2").focus() end, desc = "Focus OpenCode pane" },
  },
  opts = {
    cmd = "opencode2",
    tmux_width_percentage = 28,
    min_width = 45,
    auto_reload = true,
  },
}
```

---

## ⌨️ User Commands

| Command | Description |
| :--- | :--- |
| `:OpenCodeToggle [dir]` | Toggle OpenCode 2 pane at project root or specified directory |
| `:OpenCodeToggleBufferDir` | Toggle OpenCode 2 pane in current buffer directory |
| `:OpenCodeSendSelection` | Send visual selection with file name and line range |
| `:OpenCodeSendDiagnostic` | Send diagnostic error under cursor to OpenCode |
| `:OpenCodeQuery [text]` | Open quick query popup or send direct prompt |
| `:OpenCodeFocus` | Jump focus to OpenCode pane without toggling |

---

## ⚙️ Configuration Options

```lua
require("opencode2").setup({
  -- Command to execute for OpenCode 2
  cmd = "opencode2",
  
  -- Width percentage of the tmux window (default: 28%)
  tmux_width_percentage = 28,
  
  -- Minimum width in columns (default: 45)
  min_width = 45,
  
  -- Automatically reload buffers when files are edited externally
  auto_reload = true,
  
  -- Custom path to toggle script (optional, auto-detected by default)
  script_path = nil,
})
```

---

## 📄 License

MIT License © 2026 Vasco Yudha Nodyatama Sera
