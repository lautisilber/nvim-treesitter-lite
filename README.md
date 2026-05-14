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
| `:TSList` | List all available languages |

## Configuration

Call `setup()` with a table to override the defaults (defined in `languages.lua`). All keys are optional.

```lua
require("nvim-treesitter-lite").setup({
    languages = {
        -- your custom language definitions here
    },
})
```

User-provided definitions are merged with the built-in ones. If you define a language that already exists, your definition takes full precedence.

## Language definitions
 
Languages are defined in three tiers depending on their repository layout.

### Tier 1 — standard layout
 
The repository has a single parser at `src/parser.c` and queries at `queries/`. Only a `url` is needed, in `owner/repo` format:
 
```lua
python = { url = "tree-sitter/tree-sitter-python" },
```

### Tier 2 — multiple parsers
 
The repository contains multiple parsers, each in its own subdirectory. Each parser needs a `subpath` (relative to the repo root) and a `name`. Queries follow the same pattern:
 
```lua
typescript = {
    url = "tree-sitter/tree-sitter-typescript",
    parsers = {
        { subpath = "typescript", name = "typescript" },
        { subpath = "tsx",        name = "tsx" },
    },
    queries = {
        { subpath = "queries", name = "typescript" },
        { subpath = "queries", name = "tsx" },
    },
},
```

### Tier 3 — custom build

For repositories with a non-standard build process, provide a `build` function. It receives a `utils` table (as defined in `utils.lua`), the cloned `repo_path`, and the `parser_dir` where the `.so` should be placed. It should return a list of commands to execute, or `nil` on failure:

```lua
mylang = {
    url = "someone/tree-sitter-mylang",
    build = function(utils, repo_path, parser_dir)
        return {
            utils.get_c_comp_path(),
            "-shared", "-fPIC", "-O3",
            "-o", parser_dir .. "/mylang.so",
            repo_path .. "/src/parser.c",
        }
    end,
    parsers = {
        { name = "mylang" },
    },
    queries = {
        { name = "mylang" },
    },
},
```

### Adding languages via `setup()`
 
```lua
require("nvim-treesitter-lite").setup({
    languages = {
        -- tier 1
        blade = { url = "EmranMR/tree-sitter-blade" },
 
        -- tier 2
        markdown = {
            url = "tree-sitter-grammars/tree-sitter-markdown",
            parsers = {
                { subpath = "tree-sitter-markdown",        name = "markdown" },
                { subpath = "tree-sitter-markdown-inline", name = "markdown_inline" },
            },
            queries = {
                { subpath = "tree-sitter-markdown/queries",        name = "markdown" },
                { subpath = "tree-sitter-markdown-inline/queries", name = "markdown_inline" },
            },
        },
    },
})
```

## How it works

Parsers are compiled from source and saved to `{stdpath("data")}/site/parser/`, and queries are saved to `{stdpath("data")}/site/queries/`, both of which are on Neovim's default runtime path. Neovim's built-in tree-sitter integration picks them up automatically.

Installation clones the repository to a temporary directory, compiles the sources with the system C/C++ compiler, copies the resulting `.so` and `.scm` files to the appropriate directories, and cleans up the temporary directory.

## TODO

- Add queries! (parsers are compiled and installed, but we still need to install the queries)
- Keep all parser intermediate compilation files in the tmp dir, instead of the parser_dir, so if it fails, the intermediate files are deleted
- Add a way for languages to track specific tags rather than just the latest main

## License

MIT
