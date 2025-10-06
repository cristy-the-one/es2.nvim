# es2.nvim

A Neovim plugin that integrates [Everything Search](https://www.voidtools.com/) (ES command-line utility) with [fzf-lua](https://github.com/ibhagwan/fzf-lua) for lightning-fast fuzzy file searching on Windows.

## Features

- 🚀 **Blazing Fast Search** - Leverages Everything's instant file indexing
- 🎯 **Fuzzy Matching** - Automatically converts your query to fuzzy search (e.g., `example.txt` finds `example_somethingelse.txt`)
- ⚡ **Smart Auto-Open** - Automatically opens files when only one result is found
- 🎨 **fzf-lua Integration** - Beautiful fuzzy finder interface with preview
- 🚫 **Smart Filtering** - Excludes executables and DLLs by default (configurable)
- 📁 **Directory Support** - Open directories in neo-tree or change working directory
- 📋 **Quickfix Fallback** - Falls back to quickfix list if fzf-lua is unavailable

## Requirements

- Neovim >= 0.8.0
- Windows 11/10
- [Everything by voidtools](https://www.voidtools.com/) installed and running
- [ES (Everything Command Line Interface)](https://www.voidtools.com/support/everything/command_line_interface/) - `es.exe` must be in your PATH
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) (optional but recommended)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/es2.nvim",
  dependencies = {
    "ibhagwan/fzf-lua", -- Optional but recommended
  },
  config = function()
    local es2 = require("es2")
    
    -- Setup with default options
    es2.setup({
      use_fzf = true,
      exclude_extensions = { "exe", "dll" },
      auto_open_single = true,
    })
    
    -- Create user command
    vim.api.nvim_create_user_command("ES", function(opts)
      local use_fzf = opts.bang and false or nil
      es2.search(opts.args, use_fzf)
    end, { 
      nargs = "?", 
      bang = true, 
      desc = "ES Search (fzf or quickfix)" 
    })
    
    -- Optional keymap
    vim.keymap.set("n", "<leader>es", "<cmd>ES<CR>", { desc = "Everything Search" })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/es2.nvim",
  requires = {
    "ibhagwan/fzf-lua", -- Optional but recommended
  },
  config = function()
    require("es2").setup()
    -- Add commands and keymaps as shown above
  end,
}
```

## Configuration

### Default Options

```lua
require("es2").setup({
  use_fzf = true,                        -- Use fzf-lua interface
  exclude_extensions = { "exe", "dll" }, -- File extensions to exclude
  auto_open_single = true,               -- Auto-open when only 1 result
})
```

### Exclude More Extensions

```lua
require("es2").setup({
  exclude_extensions = { 
    "exe", "dll", "sys", "tmp", "cache", "log",
    "obj", "pdb", "ilk", "bak"
  },
})
```

### Disable Auto-Open

```lua
require("es2").setup({
  auto_open_single = false, -- Always show fzf list
})
```

## Usage

### Command

```vim
:ES                  " Prompt for search query
:ES myfile.txt       " Search for 'myfile.txt' (fuzzy)
:ES! myfile.txt      " Force quickfix list (skip fzf)
```

### Fuzzy Search Examples

The plugin automatically converts your search to fuzzy matching:

- `:ES config.lua` → finds `config.lua`, `my_config.lua`, `config_backup.lua`, etc.
- `:ES init vim` → finds `init.vim`, `init_custom.vim`, `neovim_init.lua`, etc.
- `:ES project readme` → finds `project_readme.md`, `my_project_readme.txt`, etc.

### fzf-lua Keybindings

When using fzf-lua interface:

- `<Enter>` - Open selected file(s)
- `<Tab>` - Select multiple files
- `<Ctrl-q>` - Send selected files to quickfix list
- `<Ctrl-c>` / `<Esc>` - Close fzf

### Directory Handling

When a directory is selected:
- Changes current working directory (`cd`)
- Opens neo-tree at that location (if neo-tree is installed)

## How It Works

1. **Fuzzy Query Building**: Splits your search terms and joins them with wildcards (`*`)
   - Input: `example.txt` → ES query: `example*txt`
   - This allows flexible matching across filename parts

2. **ES Command**: Runs `es.exe` with `-full-path-and-name` flag

3. **Smart Filtering**: 
   - Validates Windows absolute paths
   - Excludes configured extensions
   - Checks file/directory existence

4. **Result Handling**:
   - 1 result → Auto-open (if enabled)
   - Multiple results → fzf-lua interface with preview
   - No fzf-lua → Quickfix list

## Troubleshooting

### "es: command not found"

Make sure `es.exe` is in your Windows PATH:

1. Download ES from [Everything Command Line Interface](https://www.voidtools.com/support/everything/command_line_interface/)
2. Place `es.exe` in a directory in your PATH (e.g., `C:\Windows\System32`)
3. Restart PowerShell/Neovim

### "No results found" but files exist

1. Ensure Everything is running and indexing is complete
2. Check Everything settings: Tools → Options → Indexes
3. Try searching directly with ES: `es.exe yourquery` in PowerShell

### fzf-lua not working

The plugin will automatically fall back to quickfix list if fzf-lua is not available. Install it for the best experience:

```lua
{ "ibhagwan/fzf-lua" }
```

## License

MIT

## Credits

- [Everything by voidtools](https://www.voidtools.com/)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) by ibhagwan
- Inspired by the need for fast file searching on Windows in Neovim
