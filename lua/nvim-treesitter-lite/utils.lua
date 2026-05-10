---Runs a command
---@param cmd string[]
---@param on_error fun(vim.SystemCompleted)?
----@return vim.SystemCompleted
function run_cmd_sync(cmd, on_error)
    local res = vim.system(cmd, { text = true }):wait()
    if on_error ~= nil and res.code ~= 0 then
        on_error(res)
    end
    return res
end

---Gets the basename of a path
----@param path string
----@return string
function get_basename(path)
    return vim.fn.fnamemodify(path, ":t")
end

---Can return macos, linux, windows
---@return string
local function get_os()
    local osname = ""

    -- ask LuaJIT first
    if jit then
        osname = jit.os
    else
        -- Unix, Linux variants
        local fh, _ = assert(io.popen("uname -o 2>/dev/null","r"))
        if fh then
            osname = fh:read()
        end
    end

    osname = string.lower(osname)
    if osname == "osx" or osname == "macos" or osname == "darwin" then
        return "macos"
    elseif string.find(osname, "linux") then
        return "linux"
    else
        return "windows"
    end
end


---Get the system's c++ compiler. Returns its path
----@return string?
function get_cpp_comp_path()
    local os = get_os()

    local function try_executables(execs)
        for _, comp in ipairs(execs) do
            if vim.fn.executable(comp) then
                return comp
            end
        end
        return nil
    end

    if os == "macos" then
        local compilers = { "clang++", "g++", "c++" }
        return try_executables(compilers)
    elseif os == "linux" then
        local compilers = { "g++", "clang++", "c++", "clang" }
        return try_executables(compilers)
    else
        vim.notify("Windows not supported", vim.log.levels.WARN)
        return nil
    end
end

---Get the system's c++ compiler. Returns its path
---@return string?
function get_c_comp_path()
    local os = get_os()

    local function try_executables(execs)
        for _, comp in ipairs(execs) do
            if vim.fn.executable(comp) then
                return comp
            end
        end
        return nil
    end

    if os == "macos" then
        local compilers = { "clang", "gcc", "cc" }
        return try_executables(compilers)
    elseif os == "linux" then
        local compilers = { "gcc", "clang", "cc" }
        return try_executables(compilers)
    else
        vim.notify("Windows not supported", vim.log.levels.WARN)
        return nil
    end
end

local M = {
    run_cmd_sync = run_cmd_sync,
    get_basename = get_basename,
    get_cpp_comp_path = get_cpp_comp_path,
    get_c_comp_path = get_c_comp_path,
}

return M

