-- 集中讀取設定；保留舊存檔的繼承與缺省行為。
local modid = env.no_group_aggro.modid
---@type string
local modname = env.modname

-- 遊戲端讀取新版布林值及工坊 1.0.1 舊字串；不改寫儲存設定。

local keys = { "no_group_aggro_bee", "no_group_aggro_beehive", "no_group_aggro_beebox" }

local function Resolve(bee, hive, box)
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
local function ReadBeeOptions(options, is_map)
    local values, present = {}, {}
    local fallback = {}
    if GLOBAL.type(options) == "table" then
        for i = 1, #keys do
            if is_map then
                values[i] = options[keys[i]]
                present[i] = values[i] ~= nil
            else
                for _, option in GLOBAL.pairs(options) do
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
        -- 有已儲存的蜜蜂值、沒有獨立設定：延續舊設定的行為。
    if not present[1] then
        values[1] = fallback[1]
        if not present[2] then values[2] = fallback[2] end
        if not present[3] then values[3] = fallback[3] end
    end
    return Resolve(values[1], values[2], values[3])
end
local options, is_map = GLOBAL.KnownModIndex:GetModConfigurationOptions_Internal(modname)
local bee, beehive, beebox = ReadBeeOptions(options, is_map)
local function Read(suffix, default)
    local value = GetModConfigData(modid .. suffix)
    if value == nil then return default end
    return value
end

local config = {
    frog = Read("_frog"),
    bee = bee,
    beehive = beehive,
    beebox = beebox,
    spider = Read("_spider", true),
    spider_nest_help = Read("_spider_nest_help", true),
    spider_nest_defense = Read("_spider_nest_defense", "untargeted"),
    spider_nest_alarm = Read("_spider_nest_alarm", "vanilla"),
    spiderqueen = Read("_spiderqueen", true),
    beefalo = Read("_beefalo"),
    pigman = Read("_pigman"),
    bunnyman = Read("_bunnyman"),
    merm = Read("_merm"),
    penguin = Read("_penguin"),
    otter = Read("_otter"),
    lightninggoat = Read("_lightninggoat"),
    rocky = Read("_rocky"),
    monkey = Read("_monkey"),
}

env.no_group_aggro.config = config
