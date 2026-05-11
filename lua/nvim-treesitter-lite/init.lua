local languages = require("nvim-treesitter-lite.languages")

function setup(user_config)
    -- merge user language definitions into the built-in ones
    if user_config ~= nil and user_config.languages ~= nil then
        languages = vim.tbl_deep_extend("force", languages, user_config.languages)
    end
end

return {
    setup = setup,
    languages = languages,
}
