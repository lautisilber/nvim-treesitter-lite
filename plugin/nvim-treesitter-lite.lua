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
    for lang in opts.args:gmatch("%S+") do
        cmds.ts_uninstall(lang:lower())
    end
end, {
    nargs = "+",
    complete = function(arglead, cmdline)
        local function escape_pattern(s)
            return s:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        end

        local installed = cmds.get_installed_languages()

        -- parse already-typed languages from the cmdline
        -- cmdline looks like "TSUninstall python typescript ..."
        local already_typed = {}
        for word in cmdline:gmatch("%S+") do
            already_typed[word] = true
        end
        -- remove the command name itself
        already_typed["TSUninstall"] = nil

        local matches = {}
        for _, lang in ipairs(installed) do
            if lang:find("^" .. escape_pattern(arglead))
                and not already_typed[lang] then
                table.insert(matches, lang)
            end
        end
        table.sort(matches)
        return matches
    end,
})

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
