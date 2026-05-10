local M = {}

M.config = {
    special_languages = {
        typescript = {
            url = "https://github.com/tree-sitter/tree-sitter-typescript",
            pnames = {
                {
                    subpath = "typescript",
                    pname = "typescript",
                },
                {
                    subpath = "tsx",
                    pname = "tsx",
                },
            }
        }
    },
    special_language_urls = {},
    bundled_languages = {
        [ "c" ] = true,
        [ "lua" ] = true,
        [ "markdown" ] = true,
        [ "vimscript" ] = true,
        [ "vimdoc" ] = true,
        [ "query" ] = true, -- tree-sitter query files
    };
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
