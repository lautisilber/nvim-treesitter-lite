-- Terminology:
-- - parser path: a tree-sitter .so file
-- - parser: the name of the parser, meaning the file name of a parser without the .so extension
-- - language: refers to a programming language, which may have multiple parsers associated to it
--
-- All languages and parsers are cast to lowercase

local utils = require("nvim-treesitter-lite.utils")
local ntl = require("nvim-treesitter-lite")


local bundled_languages = {
    [ "c" ] = true,
    [ "lua" ] = true,
    [ "markdown" ] = true,
    [ "vimscript" ] = true,
    [ "vimdoc" ] = true,
    [ "tsq" ] = true, -- tree-sitter query files
    [ "query" ] = true, -- another name for tree-sitter query
};

-- The directory where parsers have to be saved for nvim's bundled tree-sitter to detect them
local parser_dir = vim.fn.stdpath("data") .. "/site/parser"

---Get the path to the parser from the parser
---@param parser string
---@return string
local function get_parser_path_from_parser(parser)
    return parser_dir .. "/" .. parser .. ".so"
end

---Get all parsers associated with a language
---@param lang string
---@return string[]
local function get_parsers_from_lang(lang)
    local lang_def = require("nvim-treesitter-lite").languages[lang]
    if lang_def ~= nil and lang_def.parsers ~= nil then -- tier 2 or 3
        local parsers = {}
        for _, p in ipairs(lang_def.parsers) do
            table.insert(parsers, p.name)
        end
        return parsers
    end
    return { lang }
end

---Get lang associated with parser
---@param parser string
---@return string
local function get_lang_from_parser(parser)
    for lang, obj in pairs(require("nvim-treesitter-lite").languages) do
        if obj.parsers ~= nil then -- tier 2 or tier 3
            for _, p in ipairs(obj.parsers) do
                if parser == p.name then
                    return lang
                end
            end
        end
    end
    return parser
end

---Get all parser paths associated with a language
---@param lang string
---@return string[]
local function get_parser_paths_from_lang(lang)
    local paths = {}
    for _, parser in ipairs(get_parsers_from_lang(lang)) do
        table.insert(paths, get_parser_path_from_parser(parser))
    end
    return paths
end

---Get parser from parser path
---@param path string
local function get_parser_from_parser_path(path)
    return utils.get_basename(path):match("(.+)%.")
end

---Check if file exists
---@param path string
---@return boolean
local function file_exists(path)
    -- vim.fn.findfile returns a string (or a string array) if files are found
    -- otherwise it returns an empty string
    local ret = vim.fn.findfile(path)
    return ret ~= ""
end

---Check if directory exists
---@param path string
---@return boolean
local function dir_exists(path)
    -- vim.fn.finddir returns a string (or a string array) if directories are found
    -- otherwise it returns an empty string
local ret = vim.fn.finddir(path)
    return ret ~= ""
end

---Makes sure that a directory exists
---@param path string
local function ensure_dir(path)
    if not dir_exists(path) then
        vim.fn.mkdir(path, "-p")
    end
end

---Checks if language is installed (if strict is true, all associated parsers
---need to be present for the program to be considered installed)
---@param lang string
---@param strict boolean
---@return boolean
local function is_language_installed(lang, strict)
    local paths = get_parser_paths_from_lang(lang)

    local count = 0
    for _, path in ipairs(paths) do
        if file_exists(path) then
            if not strict then return true end
            count = count + 1
        end
    end

    if strict and count == #paths then
        return true
    end

    return false
end

---Clones a git repo to a temporary file
---@param url string
---@param tmp string
---@param prefix string
---@param tag string?
---@return boolean
local function clone_git_repo(url, tmp, prefix, tag)
    vim.notify(prefix .. ": cloning " .. url, vim.log.levels.INFO)

    local res = utils.run_cmd_sync({ "git", "clone", "--depth=1", url, tmp })
    if res.code ~= 0 then
        vim.notify(prefix .. ": couldn't clone git repository \"" .. url .. "\" with error: " .. res.stderr)
        return false
    end
    if tag ~= nil then
       res = utils.run_cmd_sync({ "git", "fetch", "--all", "--tags", "--prune", "&&", "git", "checkout", tag })
       if res.code ~= 0 then
           vim.notify(prefix .. ": couldn't checkout to tag " .. tag .. " with error: " .. res.stderr)
           return false
       end
    end
    return true
end

---Install a language's parser(s)
---@param lang string
---@param prefix string?
local function ts_install(lang, prefix)
    if prefix == nil then
        prefix = "TSInstall"
    end

    if bundled_languages[lang] ~= nil then
        vim.notify(prefix .. ": " .. lang .. " is already bundled with nvim >= 0.12. No need to install it manually", vim.log.levels.INFO)
        return
    end
    if is_language_installed(lang, true) then
        vim.notify(prefix .. ": " .. lang .. " is already installed (call :TSUpdate " .. lang .. " if you want to update it)", vim.log.levels.WARN)
        return
    end

    if require("nvim-treesitter-lite").languages[lang] == nil then
        vim.notify(prefix .. ": language '" .. lang .. "' is not supported", vim.log.levels.ERROR)
        return
    end

    ensure_dir(parser_dir)

    local function install_parser(repo_path, parser)
        local out = get_parser_path_from_parser(parser)

        local c_comp = utils.get_c_comp_path()
        if c_comp == nil then
            vim.notify(prefix .. ": couldn't find a c compiler", vim.log.levels.ERROR)
            return false
        end

        ---Produce a compilation command with appropiate arguments
        ---@param comp string
        ---@param out string
        ---@param includes string[]
        ---@param sources string[]
        ---@param shared boolean
        ---@param no_link boolean
        ---@param stdlibpp boolean
        ---@return string[]
        local function get_comp_cmd(comp, out, includes, sources, shared, no_link, stdlibpp)
            local cmd = {
                comp,
                "-fPIC",
                "-O3",
                "-o", out,
            }

            if shared then
                table.insert(cmd, "-shared")
            end

            if stdlibpp then
                table.insert(cmd, "-lstdc++")
            end

            for _, include_path in ipairs(includes) do
                table.insert(cmd, "-I" .. include_path)
            end

            if no_link then
                table.insert(cmd, "-c")
            end

            for _, source_path in ipairs(sources) do
                table.insert(cmd, source_path)
            end

            return cmd
        end

        local function on_compile_error(vim_system_completed)
            local code = vim_system_completed.code
            local stderr = vim_system_completed.stderr
            vim.notify(prefix .. ": couldn't finish compile step with code " .. code .. " and error: " .. stderr, vim.log.levels.ERROR)
        end

        local parser_c = repo_path .. "/parser.c"
        local scanner_c = repo_path .. "/scanner.c"
        local scanner_cc = repo_path .. "/scanner.cc"

        if file_exists(repo_path .. "/scanner.cc") then
            -- we have a c++ file
            local cpp_comp = utils.get_cpp_comp_path()
            if cpp_comp == nil then
                vim.notify(prefix .. ": couldn't find a c++ compiler", vim.log.levels.ERROR)
                return false
            end


            local parser_o = repo_path .. "/parser.o"
            local scanner_o = repo_path .. "/scanner.o"

            -- compile parser
            local comp_parser = get_comp_cmd(c_comp, parser_o, { repo_path }, { parser_c }, false, true, false)
            if utils.run_cmd_sync(comp_parser, on_compile_error).code ~= 0 then
                return false
            end

            -- compile scanner
            local comp_scanner = get_comp_cmd(cpp_comp, scanner_o, { repo_path }, { scanner_cc }, false, true, false)
            if utils.run_cmd_sync(comp_scanner, on_compile_error).code ~= 0 then
                return false
            end

            -- link
            local link_cmd = get_comp_cmd(cpp_comp, out, { repo_path }, { scanner_cc, parser_c }, true, false, true)
            if utils.run_cmd_sync(link_cmd, on_compile_error).code ~= 0 then
                return false
            end

        else
            -- we only have c files
            local sources = {}
            if file_exists(parser_c) then
                table.insert(sources, parser_c)
            end
            if file_exists(scanner_c) then
                table.insert(sources, scanner_c)
            end
            local comp_cmd = get_comp_cmd(c_comp, out, { repo_path }, sources, true, false, false)
            if utils.run_cmd_sync(comp_cmd, on_compile_error).code ~= 0 then
                return false
            end
        end

        vim.notify(prefix .. ": installed " .. parser, vim.log.levels.INFO)
        return true
    end

    -- from here on, we can't crash, since we need to remove the tmp file
    local tmp = vim.fn.tempname()
    local ok, err = pcall(function ()
        local url = utils.git_repo_url(require("nvim-treesitter-lite").languages[lang]["url"])
        if not clone_git_repo(url, tmp, prefix, require("nvim-treesitter-lite").languages[lang]["tag"]) then return end

        if require("nvim-treesitter-lite").languages[lang].build ~= nil then
            local cmd = require("nvim-treesitter-lite").languages[lang].build(utils, tmp, parser_dir)
            if cmd == nil then
                vim.notify(prefix .. ": failed to create custom build command for " .. lang, vim.log.levels.ERROR)
                return
            end
            if utils.run_cmd_sync(cmd).code ~= 0 then
                vim.notify(prefix .. ": custom build failed for " .. lang, vim.log.levels.ERROR)
                return
            end
        elseif require("nvim-treesitter-lite").languages[lang].parsers then
            for _, parser in ipairs(require("nvim-treesitter-lite").languages[lang].parsers) do
                local parser_name = parser.name
                local repo_path = tmp .. "/" .. parser.subpath .. "/src"
                install_parser(repo_path, parser_name)
            end
        else
            install_parser(tmp .. "/src", lang)
        end

    end)

    -- always delete temporary file
    vim.fn.delete(tmp, "rf")

    if not ok then
        vim.notify(prefix .. ": Unexpected error: " .. err, vim.log.levels.ERROR)
    end
end

---Uninstalls all parsers linked to a language
---@param lang string
---@param prefix string?
local function ts_uninstall(lang, prefix)
    if prefix == nil then
        prefix = "TSUninstall"
    end

    local paths = get_parser_paths_from_lang(lang)
    local missing_paths = {}

    for _, path in ipairs(paths) do
        local parser = get_parser_from_parser_path(path)
        if file_exists(path) then
            if vim.fn.delete(path) ~= 0 then
                vim.notify(prefix .. ": error deleting parser " .. parser .. " (path '" .. path .. "')", vim.log.levels.ERROR)
            end
        else
            table.insert(missing_paths, { path = path, parser = parser })
        end
    end

    if #missing_paths == 0 then
        vim.notify(prefix .. ": uninstalled " .. lang, vim.log.levels.INFO)
    elseif #missing_paths == #paths then
        vim.notify(prefix .. ": couldn't uninstall any parser linked to the language " .. lang, vim.log.levels.ERROR)
    else
        local msg_parsers = ""
        local msg_paths = ""
        for i, pair in ipairs(missing_paths) do
            msg_parsers = msg_parsers .. pair.name
            msg_paths = msg_paths .. "'" .. pair["path"] .. "'"
            if i < #missing_paths then
                msg_parsers = msg_parsers .. ", "
                msg_paths = msg_paths .. ", "
            end
        end
        vim.notify(prefix .. ": couldn't uninstall parsers " .. msg_parsers .. " in paths " .. msg_paths, vim.log.levels.ERROR)
    end
end

---Will update all parsers linked to a lang by uninstalling and installing them
---@param lang string
local function ts_update_single(lang)
    if not is_language_installed(lang, false) then
        vim.notify("TSUpdate: '" .. lang .. "' isn't installed", vim.log.levels.WARN)
        return
    end

    local prefix = "TSUpdate"
    ts_uninstall(lang, prefix)
    ts_install(lang, prefix)
end

---Will update all found languages
local function ts_update_all()
    local parser_files = vim.fn.glob(parser_dir .. "/*.so", false, true)
    if #parser_files == 0 then
        vim.notify("TSUpdate: no languages installed", vim.log.levels.WARN)
        return
    end

    local langs_to_update = {}
    for _, path in ipairs(parser_files) do
        local parser = get_parser_from_parser_path(path)
        local lang = get_lang_from_parser(parser)
        langs_to_update[lang] = true
    end

    for lang, _ in pairs(langs_to_update) do
        ts_update_single(lang)
    end
end

---Get all installed parsers
---@return string[]
local function get_installed_parsers()
    local parser_files = vim.fn.glob(parser_dir .. "/*.so", false, true)
    for i, _ in ipairs(parser_files) do
        parser_files[i] = get_parser_from_parser_path(parser_files[i])
    end
    return parser_files
end

---Get all installed language parsers
---@return string[]
local function get_installed_languages()
    local parsers = get_installed_parsers()

    local langs_set = {}
    for _, parser in ipairs(parsers) do
        local lang = get_lang_from_parser(parser)
        langs_set[lang] = true
    end

    local langs = {}
    for lang, _ in pairs(langs_set) do
        table.insert(langs, lang)
    end

    return langs
end

---Lists all available languages
---@return string[]
local function ts_list()
    local langs = {}
    for lang, _ in pairs(require("nvim-treesitter-lite").languages) do
        table.insert(langs, lang)
    end
    table.sort(langs)
    return langs
end


return {
    ts_install = ts_install,
    ts_uninstall = ts_uninstall,
    ts_update_single = ts_update_single,
    ts_update_all = ts_update_all,
    get_installed_languages = get_installed_languages,
    ts_list = ts_list,
}
