-- prints every language and its configurations separated by a '|'. Each configuration parameter is in turn separated by ":"

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
local sep = "|"
local subsep = ":"
for lang, obj in pairs(languages) do
    local s = lang .. sep

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
            for i, parser in ipairs(obj.parsers) do
                s = s .. parser.name
                if i < #obj.parsers then
                    s = s .. subsep
                else
                    s = s .. sep
                end
            end
        else
            s = s .. lang .. sep
        end

        if obj.queries ~= nil then
            for i, queries in ipairs(obj.queries) do
                s = s .. queries.name
                if i < #obj.queries then
                    s = s .. subsep
                else
                    s = s .. sep
                end
            end
        end

        print(s)
    end
end
