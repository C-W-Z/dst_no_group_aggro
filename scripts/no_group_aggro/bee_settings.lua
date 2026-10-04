-- 遊戲端讀取新版布林值及工坊 1.0.1 舊字串；不改寫儲存設定。
local BeeSettings = {}
local keys = { "no_group_aggro_bee", "no_group_aggro_beehive", "no_group_aggro_beebox" }

function BeeSettings.Resolve(bee, hive, box)
    local enabled = bee == true or bee == "bee" or bee == "killerbee"
    if hive == nil then
        hive = bee == true or bee == "bee"
    end
    if box == nil then
        box = enabled
    end
    return enabled, hive == true, box == true
end

-- present 區分實際儲存值與新版 default；舊設定缺少獨立值時才能正確繼承。
function BeeSettings.ReadOptions(options, is_map)
    local values, present = {}, {}
    local fallback = {}
    if type(options) == "table" then
        for i = 1, #keys do
            if is_map then
                values[i] = options[keys[i]]
                present[i] = values[i] ~= nil
            else
                for _, option in pairs(options) do
                    if option.name == keys[i] then
                        local value = option.saved_server
                        if value == nil then value = option.saved end
                        values[i], present[i] = value, value ~= nil
                        fallback[i] = option.default
                        break
                    end
                end
            end
        end
    end
    if not present[1] then values[1] = fallback[1] end
    -- 有已儲存的蜜蜂值、沒有獨立設定：延續舊設定的行為。
    if not present[1] then
        if not present[2] then values[2] = fallback[2] end
        if not present[3] then values[3] = fallback[3] end
    end
    return BeeSettings.Resolve(values[1], values[2], values[3])
end

return BeeSettings
