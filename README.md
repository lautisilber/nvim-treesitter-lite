# nvim-treesitter-lite

A lightweight Neovim plugin for managing [tree-sitter](https://tree-sitter.github.io/tree-sitter/) parsers without the overhead of nvim-treesitter. It installs, uninstalls, and updates parsers by cloning their repositories and compiling them locally.

## Requirements

- Neovim 0.10+
- `git`
- A C compiler (`cc`, `gcc`, or `clang`)
- A C++ compiler (`c++`, `g++`, or `clang++`) — only needed for parsers with a C++ scanner

## Installation

**lazy.nvim**
```lua
{
    "lautisilber/nvim-treesitter-lite",
}
```

**packer.nvim**
```lua
use {
    "lautisilber/nvim-treesitter-lite",
}
```

**Manual (runtimepath)**
```lua
-- in your init.lua
vim.opt.runtimepath:append("~/path/to/nvim-treesitter-lite")
```

## Commands

| Command | Description |
|---|---|
| `:TSInstall <lang>` | Install the parser for `<lang>` |
| `:TSUninstall [lang ...]` | Uninstall the parser for all provided `<lang>` |
| `:TSUpdate [lang ...]` | Update one or more parsers, or all installed parsers if no argument is given |
| `:TSInfo` | List all installed languages |

## Configuration

Call `setup()` with a table to override the defaults. All keys are optional.

```lua
require("nvim-treesitter-lite").setup({
    -- Languages with multiple parsers or non-standard repo layouts.
    -- Each entry needs a url and a list of { subpath, pname } pairs.
    special_languages = {
        typescript = {
            url = "https://github.com/tree-sitter/tree-sitter-typescript",
            pnames = {
                { subpath = "typescript", pname = "typescript" },
                { subpath = "tsx",        pname = "tsx" },
            },
        },
    },

    -- Languages whose parser urls don't follow the standard
    -- https://github.com/tree-sitter/tree-sitter-<lang> pattern.
    special_language_urls = {
        -- example = "https://github.com/someone/tree-sitter-example",
    },
})
```

### Adding a language with a non-standard URL

```lua
require("nvim-treesitter-lite").setup({
    special_language_urls = {
        blade = "https://github.com/EmranMR/tree-sitter-blade",
    },
})
```

### Adding a language with multiple parsers

```lua
require("nvim-treesitter-lite").setup({
    special_languages = {
        markdown = {
            url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
            pnames = {
                { subpath = "tree-sitter-markdown",            pname = "markdown" },
                { subpath = "tree-sitter-markdown-inline",     pname = "markdown_inline" },
            },
        },
    },
})
```

## How it works

Parsers are compiled from source and saved to `{stdpath("data")}/site/parser/`, which is on Neovim's default runtime path. Neovim's built-in tree-sitter integration picks them up from there automatically.

Installation clones the parser's repository to a temporary directory, compiles the sources with the system C/C++ compiler, copies the resulting `.so` to the parser directory, and cleans up the temporary directory.

## License

MIT
