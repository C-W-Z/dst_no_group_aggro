-- modmain 在選單之後才執行；前端必須先遷移舊值，兩個布林選項才能正確選中。
local BeeSettings = require("no_group_aggro/bee_settings")
---@type string
local modname = env.modname
local index = GLOBAL.KnownModIndex

-- 設定畫面 PostConstruct 時舊值已進入 spinner；這裡需在画面建立前轉換。
-- 只包裝目前 index 的合併方法，且只處理本 MOD 的 configuration_options。
index._no_group_aggro_bee_migration = index._no_group_aggro_bee_migration or {}
if not index._no_group_aggro_bee_migration[modname] then
    index._no_group_aggro_bee_migration[modname] = true
    local old_UpdateConfigurationOptions = index.UpdateConfigurationOptions
    local saving = {}

    local function Migrate(self, options, savedata, client_config)
        local info = self:GetModInfo(modname)
        if not info or options ~= info.configuration_options then return end
        local migrated = BeeSettings.Migrate(options, savedata, client_config)
        local context = client_config and "client" or "server"
        if migrated and not saving[context] then
            saving[context] = true
            self:SaveConfigurationOptions(function()
                saving[context] = nil
            end, modname, migrated, client_config)
        end
    end

    index.UpdateConfigurationOptions = function(self, options, savedata, client_config, ...)
        local function AfterUpdate(...)
            Migrate(self, options, savedata, client_config)
            return ...
        end
        return AfterUpdate(old_UpdateConfigurationOptions(self, options, savedata, client_config, ...))
    end

    -- 首次載入在安裝包裝之前；重讀原始 savedata，保留未顯示在新版選單的舊 key。
    index:LoadModConfigurationOptions(modname, false)
end
