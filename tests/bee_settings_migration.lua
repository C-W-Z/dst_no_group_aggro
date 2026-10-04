-- 從 MOD 目錄執行：lua tests/bee_settings_migration.lua
package.path = "scripts/?.lua;" .. package.path
local Settings = require("no_group_aggro/bee_settings")
local keys = { "no_group_aggro_bee", "no_group_aggro_beehive", "no_group_aggro_beebox" }
local assertions = 0
local function Eq(actual, expected, message)
    assertions = assertions + 1
    assert(actual == expected, (message or "value") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end
local function Load(path, environment)
    setmetatable(environment, { __index = _G })
    local fn
    if setfenv then
        fn = assert(loadfile(path))
        setfenv(fn, environment)
    else
        fn = assert(loadfile(path, "t", environment))
    end
    fn()
    return environment
end
local function Definitions(locale)
    return Load("modinfo.lua", { locale = locale or "en" }).configuration_options
end
local function Record(options, name)
    for _, option in ipairs(options) do
        if option.name == name then return option end
    end
end
local function Saved(bee, hive, box)
    local result = {}
    local values = { bee, hive, box }
    for i = 1, 3 do
        if values[i] ~= nil then result[#result + 1] = { name = keys[i], saved = values[i] } end
    end
    return result
end
local function Triple(bee, hive, box, expected)
    Eq(bee, expected[1], "bee")
    Eq(hive, expected[2], "hive")
    Eq(box, expected[3], "box")
end

for _, locale in ipairs({ "en", "zh", "zhr", "zht" }) do
    local definitions = Definitions(locale)
    for _, name in ipairs(keys) do
        local option = assert(Record(definitions, name))
        Eq(option.default, true, "new defaults")
        Eq(#option.options, 2, "two menu choices")
        Eq(option.options[1].data, false, "vanilla value")
        Eq(option.options[2].data, true, "enabled value")
    end
    local bee, hive, box = Settings.ReadOptions(definitions, false)
    Triple(bee, hive, box, { true, true, true })
    Eq(Settings.Migrate(definitions, definitions, false), nil, "new installation needs no write")
end

local legacy_profiles = {
    { false, false, false, false },
    { "bee", true, true, true },
    { "killerbee", true, false, true },
}
for _, profile in ipairs(legacy_profiles) do
    for _, client in ipairs({ false, true }) do
        local definitions = Definitions()
        local unrelated = { name = "removed_or_unrelated_option", saved = "keep", default = "old" }
        local raw = Saved(profile[1])
        raw[#raw + 1] = unrelated
        local migrated = assert(Settings.Migrate(definitions, raw, client))
        for i = 1, 3 do
            Eq(Record(migrated, keys[i]).saved, profile[i + 1], "old profile conversion")
            Eq(Record(definitions, keys[i])[client and "saved_client" or "saved_server"], profile[i + 1], "active field updated")
        end
        Eq(Record(raw, keys[1]).saved, profile[1], "source saved data untouched")
        Eq(Record(migrated, unrelated.name).saved, "keep", "unrelated saved value preserved")
        Eq(Record(migrated, unrelated.name).default, "old", "unrelated metadata preserved")
        Eq(Settings.Migrate(definitions, migrated, client), nil, "migration is idempotent")
    end
end

-- 新版三個布林值須原樣保留，不能在重開後再次繼承或重設。
for _, bee in ipairs({ false, true }) do
    for _, hive in ipairs({ false, true }) do
        for _, box in ipairs({ false, true }) do
            local definitions = Definitions()
            local raw = Saved(bee, hive, box)
            Eq(Settings.Migrate(definitions, raw, false), nil, "modern settings unchanged")
            local a, b, c = Settings.ReadOptions(raw, false)
            Triple(a, b, c, { bee, hive, box })
        end
    end
end

-- 舊 dedicated override 是字典，列表則區分 default 與 saved。
for _, profile in ipairs(legacy_profiles) do
    local a, b, c = Settings.ReadOptions({ [keys[1]] = profile[1] }, true)
    Triple(a, b, c, { profile[2], profile[3], profile[4] })
    local options = Definitions()
    Record(options, keys[1]).saved = profile[1]
    a, b, c = Settings.ReadOptions(options, false)
    Triple(a, b, c, { profile[2], profile[3], profile[4] })
end
do
    local a, b, c = Settings.ReadOptions({}, true)
    Triple(a, b, c, { false, false, false })
    local options = Definitions()
    Record(options, keys[1]).saved = false
    Record(options, keys[1]).saved_server = "killerbee"
    a, b, c = Settings.ReadOptions(options, false)
    Triple(a, b, c, { true, false, true })
end

local function Frontend(deferred, initial)
    local options = Definitions()
    local other_options = Definitions()
    local index = { writes = {}, info = { configuration_options = options }, disk = { server = initial } }
    function index:GetModInfo(name)
        Eq(name, "test_mod", "scoped mod lookup")
        return self.info
    end
    function index:UpdateConfigurationOptions(target, savedata, client, extra)
        for _, old in ipairs(savedata) do
            local option = Record(target, old.name)
            if option and old.saved ~= nil then
                option.saved = old.saved
                option[client and "saved_client" or "saved_server"] = old.saved
            end
        end
        return "original", nil, extra
    end
    function index:SaveConfigurationOptions(callback, name, data, client)
        Eq(name, "test_mod", "only own mod saved")
        self.writes[#self.writes + 1] = { data = data, client = client }
        self.disk[client and "client" or "server"] = data
        local function Finish()
            callback()
            self:LoadModConfigurationOptions(name, client)
        end
        if deferred then self.pending = Finish else Finish() end
    end
    function index:LoadModConfigurationOptions(name, client)
        local data = self.disk[client and "client" or "server"]
        if data then self:UpdateConfigurationOptions(options, data, client) end
        return options
    end
    if initial then index:LoadModConfigurationOptions("test_mod", false) end
    local environment = { GLOBAL = { KnownModIndex = index }, modname = "test_mod" }
    environment.env = environment
    Load("modservercreationmain.lua", environment)
    local installed = index.UpdateConfigurationOptions
    Load("modservercreationmain.lua", environment)
    Eq(index.UpdateConfigurationOptions, installed, "no duplicate wrappers")
    return index, options, other_options
end

do
    local initial = Saved("killerbee")
    initial[#initial + 1] = { name = "old_removed_key", saved = "preserved" }
    local index, options, other = Frontend(false, initial)
    Eq(#index.writes, 1, "initial load migrates and saves once")
    Eq(Record(options, keys[2]).saved, false, "old option 2 selected before UI")
    Eq(Record(index.writes[1].data, "old_removed_key").saved, "preserved", "initial migration retains unknown keys")
    local a, b, c = index:UpdateConfigurationOptions(other, Saved("bee"), false, "tail")
    Triple(a, b, c, { "original", nil, "tail" })
    Eq(#index.writes, 1, "foreign configuration is never saved")
    Eq(Record(other, keys[1]).saved, "bee", "foreign configuration retains original merge")
    -- 全新的 index／包裝狀態，模擬重開遊戲後讀取已遷移的設定檔。
    local restarted, restarted_options = Frontend(false, index.disk.server)
    Eq(#restarted.writes, 0, "fresh session does not migrate again")
    local bee, hive, box = Settings.ReadOptions(restarted_options, false)
    Triple(bee, hive, box, { true, false, true })
end
do
    local index, options = Frontend(false)
    local a, b, c = index:UpdateConfigurationOptions(options, Saved(false), false, "tail")
    Triple(a, b, c, { "original", nil, "tail" })
    Eq(#index.writes, 1, "subsequent load migrates once")
    Eq(Record(options, keys[2]).saved, false, "vanilla hive retained")
    Eq(Record(options, keys[3]).saved, false, "vanilla box retained")
    index:UpdateConfigurationOptions(options, Saved(false, true, false), false)
    Eq(#index.writes, 1, "manual boolean preferences not overwritten or resaved")
    Eq(Record(options, keys[2]).saved, true, "new independent hive preference retained")
end
do
    local index, options = Frontend(true)
    index:UpdateConfigurationOptions(options, Saved("bee"), false)
    index:UpdateConfigurationOptions(options, Saved("bee"), false)
    Eq(#index.writes, 1, "pending save not duplicated")
    index.pending()
    Eq(#index.writes, 1, "reload after async save does not recurse")
    index:UpdateConfigurationOptions(options, Saved("killerbee"), true)
    Eq(#index.writes, 2, "client file migrated separately")
    index.pending()
    Eq(Record(options, keys[2]).saved_client, false, "client hive value migrated")
end

-- 執行實際 config.lua 與 bees.lua，確認新布林值能驅動原來的 Prefab hooks。
for _, profile in ipairs(legacy_profiles) do
    for _, master in ipairs({ false, true }) do
        local raw = { [keys[1]] = profile[1] }
        local environment = {
            GLOBAL = { KnownModIndex = { GetModConfigurationOptions_Internal = function() return raw, true end } },
            modname = "test_mod",
            no_group_aggro = { modid = "no_group_aggro" },
            GetModConfigData = function() return false end,
            TheWorld = { ismastersim = master },
        }
        environment.env = environment
        Load("scripts/no_group_aggro/config.lua", environment)
        local config = environment.no_group_aggro.config
        Triple(config.bee, config.beehive, config.beebox, { profile[2], profile[3], profile[4] })
        local hooks = {}
        environment.AddPrefabPostInit = function(name, fn) hooks[name] = fn end
        Load("scripts/no_group_aggro/bees.lua", environment)
        Eq(hooks.bee ~= nil, profile[2], "bee hook enabled")
        Eq(hooks.killerbee ~= nil, profile[2], "killer bee hook retained")
        Eq(hooks.beehive ~= nil, profile[3], "boolean hive hook enabled")
        Eq(hooks.beebox ~= nil, profile[4], "box hook enabled")
        if hooks.beehive then
            local target = {}
            local received_target, received_prefab, received_radius
            local release = function(self, attacker, prefab, radius)
                received_target, received_prefab, received_radius = attacker, prefab, radius
                return "released", nil, "tail"
            end
            local hive = { components = { childspawner = { ReleaseAllChildren = release } } }
            hooks.beehive(hive)
            local a, b, c = hive.components.childspawner:ReleaseAllChildren(target, "killerbee", 9)
            Triple(a, b, c, { "released", nil, "tail" })
            if master then
                Eq(received_target, nil, "master hive has no target")
            else
                Eq(received_target, target, "client keeps vanilla target")
            end
            Eq(received_prefab, master and "bee" or "killerbee", "hive release type")
            Eq(received_radius, 9, "release radius retained")
            if not master then Eq(hive.components.childspawner.ReleaseAllChildren, release, "client component unchanged") end
        end
    end
end

print("PASS: " .. assertions .. " assertions for menus, migration, legacy overrides, independent preferences and frontend saves")
