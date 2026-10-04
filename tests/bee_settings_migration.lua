-- 從 MOD 目錄執行：lua tests/bee_settings_migration.lua
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
-- 模擬原版 GetModConfigData：已儲存值優先，沒有時回傳 default。
local function ConfigEnvironment(options, is_map)
    local environment = {
        no_group_aggro = { modid = "no_group_aggro" },
        GetModConfigData = function(name)
            if is_map then return options[name] end
            for _, option in pairs(options) do
                if option.name == name then
                    if option.saved_server ~= nil then return option.saved_server end
                    if option.saved ~= nil then return option.saved end
                    return option.default
                end
            end
        end,
    }
    environment.env = environment
    return environment
end
local function ReadOptions(options, is_map)
    local config = Load("scripts/no_group_aggro/config.lua", ConfigEnvironment(options, is_map)).no_group_aggro.config
    return config.bee, config.beehive, config.beebox
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
    local bee, hive, box = ReadOptions(definitions, false)
    Triple(bee, hive, box, { true, true, true })
end

local legacy_profiles = {
    { false, false, true, true },
    { "bee", true, true, true },
    { "killerbee", true, false, true },
}
-- 新版三個布林值須原樣保留。
for _, bee in ipairs({ false, true }) do
    for _, hive in ipairs({ false, true }) do
        for _, box in ipairs({ false, true }) do
            local raw = Saved(bee, hive, box)
            local a, b, c = ReadOptions(raw, false)
            Triple(a, b, c, { bee, hive, box })
        end
    end
end

-- 舊字串搭配已儲存的新選項：蜂箱保留 false，蜂巢僅受 killerbee 特例影響。
for _, legacy in ipairs({ "bee", "killerbee" }) do
    for _, hive in ipairs({ false, true }) do
        for _, box in ipairs({ false, true }) do
            local expected_hive = hive
            if legacy == "killerbee" then expected_hive = false end
            local a, b, c = ReadOptions(Saved(legacy, hive, box), false)
            Triple(a, b, c, { true, expected_hive, box })
        end
    end
end

-- 舊字串只轉換蜜蜂；killerbee 關閉蜂巢，其餘值及缺省值不受影響。
for _, profile in ipairs(legacy_profiles) do
    local expected_hive = nil
    if profile[1] == "killerbee" then expected_hive = false end
    local a, b, c = ReadOptions({ [keys[1]] = profile[1] }, true)
    Triple(a, b, c, { profile[2], expected_hive, nil })
    local options = Definitions()
    Record(options, keys[1]).saved = profile[1]
    a, b, c = ReadOptions(options, false)
    Triple(a, b, c, { profile[2], profile[3], profile[4] })
    Eq(Record(options, keys[1]).saved, profile[1], "read does not rewrite old saved value")
end
do
    local a, b, c = ReadOptions({}, true)
    Triple(a, b, c, { false, nil, nil })
    local options = Definitions()
    Record(options, keys[1]).saved = false
    Record(options, keys[1]).saved_server = "killerbee"
    a, b, c = ReadOptions(options, false)
    Triple(a, b, c, { true, false, true })
end

-- 執行實際 config.lua 與 bees.lua，確認新布林值能驅動原來的 Prefab hooks。
for _, profile in ipairs(legacy_profiles) do
    for _, master in ipairs({ false, true }) do
        local raw = { [keys[1]] = profile[1], [keys[2]] = true, [keys[3]] = true }
        local environment = ConfigEnvironment(raw, true)
        environment.TheWorld = { ismastersim = master }
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

print("PASS: " .. assertions .. " assertions for boolean menus, unchanged legacy data, killerbee hive override, independent preferences and runtime hooks")
