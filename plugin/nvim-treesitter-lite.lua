local cmds = require("nvim-treesitter-lite.cmds")

vim.api.nvim_create_user_command("TSInstall", function (opts)
    local lang = opts.args:lower()
    cmds.ts_install(lang)
end, {
    nargs = 1,
    complete = function(arglead)
        local languages = require("nvim-treesitter-lite").languages
        local matches = {}
        for lang, _ in pairs(languages) do
            if lang:find("^" .. arglead) then
                table.insert(matches, lang)
            end
        end
        table.sort(matches)
        return matches
    end,
})

vim.api.nvim_create_user_command("TSUninstall", function (opts)
    if opts.args == "" then
        vim.notify("TSUninstall: at least one argument is required", vim.log.levels.ERROR)
        return
    end
    for lang in opts.args:gmatch("%S+") do
        cmds.ts_uninstall(lang:lower())
    end
end, { nargs = "?" })

vim.api.nvim_create_user_command("TSUpdate", function (opts)
    if opts.args == "" then
        cmds.ts_update_all()
        return
    end

    for lang in opts.args:gmatch("%S+") do
        cmds.ts_update_single(lang:lower())
    end
end, { nargs = "*" })

vim.api.nvim_create_user_command("TSInfo", function (opts)
    local langs = cmds.get_installed_languages()
    local langs_str = ""

    for i, lang in ipairs(langs) do
        langs_str = langs_str .. " - " .. lang
        if i < #langs then
            langs_str = langs_str .. "\n"
        end
    end

    vim.notify("TSInfo: installed languages are\n" .. langs_str, vim.log.levels.INFO)
end, { nargs = 0 })

vim.api.nvim_create_user_command("TSList", function (opts)
    local langs = cmds.ts_list()
    local langs_str = ""

    for i, lang in ipairs(langs) do
        langs_str = langs_str .. " - " .. lang
        if i < #langs then
            langs_str = langs_str .. "\n"
        end
    end

    vim.notify("TSList: available languages\n" .. langs_str, vim.log.levels.INFO)
end, { nargs = 0 })
