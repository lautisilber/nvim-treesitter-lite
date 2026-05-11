-- prints every language followed by the associated parsers, separated by ':'

local args = false
local tiers = {}
for _, a in ipairs(arg) do
    local tier = tonumber(a)
    if tier ~= nil and tier >= 1 and tier <= 3 then
        tiers[tier] = true
        args = true
    end
end

if not args then
    tiers = {
        [1] = true,
        [2] = true,
        [3] = true,
    }
end

local languages = require("languages")
local sep = ":"
for lang, obj in pairs(languages) do
    local s = lang

    local is_tier_3 = obj.build ~= nil
    local is_tier_2 = obj.parsers ~= nil and not is_tier_3
    local is_tier_1 = not is_tier_2 and not is_tier_3

    local wanted_lang = (
            (is_tier_3 and tiers[3] ~= nil) or
            (is_tier_2 and tiers[2] ~= nil) or
            (is_tier_1 and tiers[1] ~= nil)
        )

    if wanted_lang then
        if obj.parsers ~= nil then
            for _, parser in ipairs(obj.parsers) do
                s = s .. sep .. parser.name
            end
        else
            s = s .. sep .. lang
        end
        print(s)
    end
end
