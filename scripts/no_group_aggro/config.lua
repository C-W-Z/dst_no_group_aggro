-- 集中讀取設定；保留舊存檔的繼承與缺省行為。
local modid = env.no_group_aggro.modid
local function Read(suffix, default)
    local value = GetModConfigData(modid .. suffix)
    if value == nil then return default end
    return value
end

local config = {
    frog = Read("_frog"),
    bee = Read("_bee"),
    beehive = Read("_beehive"),
    beebox = Read("_beebox"),
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
    -- 原入口讀取的是無底線 key；本次結構重構保留既有行為。
    otter = Read("otter"),
    lightninggoat = Read("_lightninggoat"),
    rocky = Read("_rocky"),
    monkey = Read("_monkey"),
}

-- 舊 modoverrides.lua 缺少新 key，或選擇 inherit 時跟隨蜜蜂設定。
if config.beehive == nil or config.beehive == "inherit" then
    config.beehive = config.bee == "bee" and "bee" or false
end
if config.beebox == nil or config.beebox == "inherit" then
    config.beebox = config.bee ~= nil and config.bee ~= false
end
env.no_group_aggro.config = config
