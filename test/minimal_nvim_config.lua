function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)") or "./"
end

local working_dir = script_path() .. ".."

vim.opt.runtimepath:prepend(working_dir)
require("nvim-treesitter-lite").setup()
