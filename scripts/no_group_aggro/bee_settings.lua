-- 前端遷移及專用伺服器的舊值相容；不依賴 MOD／世界全域。
local BeeSettings = {}
local keys = { "no_group_aggro_bee", "no_group_aggro_beehive", "no_group_aggro_beebox" }

function BeeSettings.Resolve(bee, hive, box)
    local enabled = bee == true or bee == "bee" or bee == "killerbee"
    if hive == nil then hive = bee == true or bee == "bee" end
    if box == nil then box = enabled end
    return enabled, hive == true, box == true
end

local function Copy(option)
    local copy = {}
    for key, value in pairs(option) do copy[key] = value end
    return copy
end

-- 只轉換工坊 1.0.1：舊字串，或沒有兩項新設定的 false。
-- 已轉成布林值的設定不再儲存，也不覆蓋玩家後來修改的選項。
function BeeSettings.Migrate(config_options, savedata, client_config)
    local definitions, previous = {}, {}
    for _, option in ipairs(config_options) do definitions[option.name] = option end
    for _, option in ipairs(savedata) do previous[option.name] = option end
    local bee = previous[keys[1]] and previous[keys[1]].saved
    local hive = previous[keys[2]] and previous[keys[2]].saved
    local box = previous[keys[3]] and previous[keys[3]].saved
    if bee ~= "bee" and bee ~= "killerbee" and
        not (bee == false and hive == nil and box == nil) then
        return nil
    end
    for _, name in ipairs(keys) do
        if not definitions[name] then return nil end
    end

    local a, b, c = BeeSettings.Resolve(bee, hive, box)
    local values = { [keys[1]] = a, [keys[2]] = b, [keys[3]] = c }
    local field = client_config and "saved_client" or "saved_server"
    for _, name in ipairs(keys) do
        definitions[name].saved = values[name]
        definitions[name][field] = values[name]
    end

    -- 更新三項蜜蜂設定，其餘已儲存值（包括移除的 key）完整保留。
    local migrated = {}
    for _, option in ipairs(savedata) do
        local source = option
        if values[option.name] ~= nil then source = definitions[option.name] end
        migrated[#migrated + 1] = Copy(source)
    end
    for _, name in ipairs(keys) do
        if not previous[name] then migrated[#migrated + 1] = Copy(definitions[name]) end
    end
    return migrated
end

return BeeSettings
