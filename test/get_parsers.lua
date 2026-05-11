-- prints every language followed by the associated parsers, separated by ':'

local languages = require("languages")
local sep = ":"
for lang, obj in pairs(languages) do
    local s = lang
    if obj.parsers ~= nil then
        for _, parser in ipairs(obj.parsers) do
            s = s .. sep .. parser.parser
        end
    else
        s = s .. sep .. lang
    end
    print(s)
end
