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
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
