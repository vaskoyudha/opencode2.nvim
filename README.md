# opencode2.nvim ⚡

> Seamless, project-aware Neovim & tmux integration for **OpenCode v2** (`@opencode-ai/cli`).

`opencode2.nvim` provides a high-performance bridge between Neovim and OpenCode 2 running in tmux. Unlike in-buffer terminal plugins that lag your editor or get killed when Neovim restarts, `opencode2.nvim` uses an **isolated background stash session (`_opencode_stash`)**.

Your agent stays alive, maintains state across project switches, and can be summoned or stashed away instantly with zero latency.

---

## ✨ Features

- 🏎️ **Zero Editor Latency**: Runs OpenCode 2 in a dedicated tmux pane; Neovim remains 100% responsive.
- 📦 **Isolated Background Stash**: Toggling hides the pane into a hidden tmux session (`_opencode_stash`). No clutter in your tmux window list.
- 🔄 **Persistent Long-Running Tasks**: Background tasks keep executing even when the pane is hidden or if you restart Neovim.
- 🎯 **Project-Aware**: Automatically tracks project git roots. Switching projects restores the matching OpenCode session or spawns a new one on demand.
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
    { "<A-a>", function() require("opencode2").toggle() end, mode = { "n", "i" }, desc = "Toggle OpenCode 2" },
    { "<leader>ao", function() require("opencode2").toggle(require("opencode2").get_buffer_dir()) end, desc = "Toggle OpenCode 2 (buffer dir)" },
    { "<leader>aO", function() require("opencode2").toggle() end, desc = "Toggle OpenCode 2 (project root)" },
  },
  opts = {
    cmd = "opencode2",
    tmux_width_percentage = 28,
    min_width = 45,
  },
}
```

---

## ⌨️ Default Commands

| Command | Description |
| :--- | :--- |
| `:OpenCodeToggle [dir]` | Toggle OpenCode 2 pane at project root or specified directory |
| `:OpenCodeToggleBufferDir` | Toggle OpenCode 2 pane in current buffer's directory |

---

## 📄 License

MIT License © 2026 Vasco Yudha Nodyatama Sera
