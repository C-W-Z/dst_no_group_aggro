-- 同時供前端遷移及遊戲端讀取使用，不依賴 MOD／世界全域。
local BeeSettings = {}
local keys = { "no_group_aggro_bee", "no_group_aggro_beehive", "no_group_aggro_beebox" }

function BeeSettings.Resolve(bee, hive, box)
    local enabled = bee == true or bee == "bee" or bee == "killerbee"
    if hive == nil or hive == "inherit" then
        hive = bee == true or bee == "bee"
    end
    if box == nil or box == "inherit" then
        box = enabled
    end
    return enabled, hive == true or hive == "bee", box == true
end

-- present 區分實際儲存值與新版 default；舊設定缺少獨立值時才能正確繼承。
function BeeSettings.ReadOptions(options, is_map, field, defaults)
    local values, present = {}, {}
    local fallback = {}
    for i = 1, #keys do
        fallback[i] = defaults and defaults[keys[i]]
    end
    if type(options) == "table" then
        for i = 1, #keys do
            if is_map then
                values[i] = options[keys[i]]
                present[i] = values[i] ~= nil
            else
                for _, option in pairs(options) do
                    if option.name == keys[i] then
                        local value = option[field or "saved_server"]
                        if value == nil then value = option.saved end
                        values[i], present[i] = value, value ~= nil
                        if fallback[i] == nil then fallback[i] = option.default end
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

-- 回傳新的儲存資料；已是三個布林值時回傳 nil，避免重複寫入／載入遞迴。
function BeeSettings.Migrate(config_options, savedata, client_config)
    if type(config_options) ~= "table" or type(savedata) ~= "table" then return nil end
    local definitions, defaults, old, present = {}, {}, {}, {}
    for _, option in pairs(config_options) do
        for i = 1, #keys do
            if option.name == keys[i] then
                definitions[i], defaults[keys[i]] = option, option.default
            end
        end
    end
    if not definitions[1] or not definitions[2] or not definitions[3] then return nil end
    for _, option in pairs(savedata) do
        for i = 1, #keys do
            if option.name == keys[i] then
                old[i], present[i] = option.saved, option.saved ~= nil
            end
        end
    end
    -- 新安裝且尚未儲存的設定直接用新版 default，不需建立設定檔。
    if not present[1] and not present[2] and not present[3] then return nil end
    local bee, hive, box = BeeSettings.ReadOptions(savedata, false, "saved", defaults)
    local values = { bee, hive, box }
    local changed = false
    for i = 1, #keys do
        if not present[i] or old[i] ~= values[i] then changed = true end
    end
    if not changed then return nil end

    local field = client_config and "saved_client" or "saved_server"
    for i = 1, #keys do
        definitions[i].saved = values[i]
        definitions[i][field] = values[i]
    end
    local migrated, included = {}, {}
    local function CopyOption(option)
        local copy = {}
        for key, value in pairs(option) do copy[key] = value end
        return copy
    end
    -- 保留其他設定及舊資料中未出現在新版選單的 key，不整批重設。
    for _, option in ipairs(savedata) do
        local replacement = option
        for i = 1, #keys do
            if option.name == keys[i] then
                replacement, included[i] = definitions[i], true
                break
            end
        end
        migrated[#migrated + 1] = CopyOption(replacement)
    end
    for i = 1, #keys do
        if not included[i] then migrated[#migrated + 1] = CopyOption(definitions[i]) end
    end
    return migrated
end

return BeeSettings
