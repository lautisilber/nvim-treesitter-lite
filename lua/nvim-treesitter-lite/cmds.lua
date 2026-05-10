-- Terminology:
-- - parser: a tree-sitter .so file
-- - pname: the name of the parser, meaning the file name of a parser without the .so extension
-- - language: refers to a programming language, which may have multiple pnames associated to it
--
-- All languages and pnames are cast to lowercase

local ntl = require("nvim-treesitter-lite")
local utils = require("nvim-treesitter-lite.utils")

local bundled_languages = {
    [ "c" ] = true,
    [ "lua" ] = true,
    [ "markdown" ] = true,
    [ "vimscript" ] = true,
    [ "vimdoc" ] = true,
    [ "query" ] = true, -- tree-sitter query files
};

-- The directory where parsers have to be saved for nvim's bundled tree-sitter to detect them
local parser_dir = vim.fn.stdpath("data") .. "/site/parser"

---Get the path to the parser from the pname
---@param pname string
---@return string
local function get_parser_path_from_pname(pname)
    return parser_dir .. "/" .. pname .. ".so"
end

---Get all pnames associated with a language
---@param lang string
---@return string[]
local function get_pnames_from_lang(lang)
    local pnames = {}
    if ntl.config.special_languages[lang] ~= nil then
for _, pname in ipairs(ntl.config.special_languages[lang]["pnames"]) do
            table.insert(pnames, pname["pname"])
        end
    else
        table.insert(pnames, lang)
    end
    return pnames
end

---Get lang associated with pname
---@param pname string
---@return string
local function get_lang_from_pname(pname)
    for lang, obj in pairs(ntl.config.special_languages) do
        for _, _pname in ipairs(obj["pnames"]) do
            if pname == _pname["pname"] then
                return lang
            end
        end
    end
    return pname
end

---Get all parser paths associated with a language
---@param lang string
---@return string[]
local function get_parser_paths_from_lang(lang)
    local paths = {}
    for _, pname in ipairs(get_pnames_from_lang(lang)) do
        table.insert(paths, get_parser_path_from_pname(pname))
    end
    return paths
end

---Get pname from parser path
---@param path string
local function get_pname_from_parser_path(path)
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
---@return boolean
local function clone_git_repo(url, tmp, prefix)
    vim.notify(prefix .. ": cloning " .. url, vim.log.levels.INFO)

    local res = utils.run_cmd_sync({ "git", "clone", "--depth=1", url, tmp })
    if res.code ~= 0 then
        vim.notify(prefix .. ": couldn't clone git repository \"" .. url .. "\" with error: " .. res.stderr)
        return false
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

    ensure_dir(parser_dir)

    local function install_parser(repo_path, pname)
        local out = get_parser_path_from_pname(pname)

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

            for _, source_path in ipairs(sources) do
                if no_link then
                    table.insert(cmd, "-c")
                end
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
            local comp_cmd = get_comp_cmd(c_comp, out, { repo_path }, { scanner_c, parser_c }, true, false, false)
            if utils.run_cmd_sync(comp_cmd, on_compile_error).code ~= 0 then
                return false
            end
        end

        vim.notify(prefix .. ": installed " .. pname, vim.log.levels.INFO)
        return true
    end

    -- from here on, we can't crash, since we need to remove the tmp file
    local tmp = vim.fn.tempname()
    local ok, err = pcall(function ()
        if ntl.config.special_languages[lang] ~= nil then
            local url = ntl.config.special_languages[lang]["url"]
            if not clone_git_repo(url, tmp, prefix) then return end
            for _, pname_all in ipairs(ntl.config.special_languages[lang]["pnames"]) do
                local pname = pname_all["pname"]
                local repo_path = tmp .. "/" .. pname_all["subpath"] .. "/src"
                install_parser(repo_path, pname)
            end
        else
            local url = (ntl.config.special_language_urls[lang] and
                ntl.config.special_language_urls[lang] or
                "https://github.com/tree-sitter/tree-sitter-" .. lang
            )
            if not clone_git_repo(url, tmp, prefix) then return end
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
        local pname = get_pname_from_parser_path(path)
        if file_exists(path) then
            if vim.fn.delete(path) ~= 0 then
                vim.notify(prefix .. ": error deleting parser " .. pname .. " (path '" .. path .. "')", vim.log.levels.ERROR)
            end
        else
            table.insert(missing_paths, { path = path, pname = pname })
        end
    end

    if #missing_paths == 0 then
        vim.notify(prefix .. ": uninstalled " .. lang, vim.log.levels.INFO)
    elseif #missing_paths == #paths then
        vim.notify(prefix .. ": couldn't uninstall any parser linked to the language " .. lang, vim.log.levels.ERROR)
    else
        local msg_pnames = ""
        local msg_paths = ""
        for i, pair in ipairs(missing_paths) do
            msg_pnames = msg_pnames .. pair["pname"]
            msg_paths = msg_paths .. "'" .. pair["path"] .. "'"
            if i < #missing_paths then
                msg_pnames = msg_pnames .. ", "
                msg_paths = msg_paths .. ", "
            end
        end
        vim.notify(prefix .. ": couldn't uninstall parsers " .. msg_pnames .. " in paths " .. msg_paths, vim.log.levels.ERROR)
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
        local pname = get_pname_from_parser_path(path)
        local lang = get_lang_from_pname(pname)
        langs_to_update[lang] = true
    end

    for lang, _ in pairs(langs_to_update) do
        ts_update_single(lang)
    end
end

---Get all installed pnames
---@return string[]
local function get_installed_pnames()
    local parser_files = vim.fn.glob(parser_dir .. "/*.so", false, true)
    for i, _ in ipairs(parser_files) do
        parser_files[i] = get_pname_from_parser_path(parser_files[i])
    end
    return parser_files
end

---Get all installed language parsers
---@return string[]
local function get_installed_languages()
    local pnames = get_installed_pnames()

    local langs_set = {}
    for _, pname in ipairs(pnames) do
        local lang = get_lang_from_pname(pname)
        langs_set[lang] = true
    end

    local langs = {}
    for lang, _ in pairs(langs_set) do
        table.insert(langs, lang)
    end

    return langs
end


return {
    ts_install = ts_install,
    ts_uninstall = ts_uninstall,
    ts_update_single = ts_update_single,
    ts_update_all = ts_update_all,
    get_installed_languages = get_installed_languages,
}
