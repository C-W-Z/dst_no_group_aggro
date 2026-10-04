-- 集中讀取設定；只相容舊蜜蜂字串，不改寫儲存值。
local modid = env.no_group_aggro.modid
local function Read(suffix, default)
    local value = GetModConfigData(modid .. suffix)
    if value == nil then return default end
    return value
end

-- N/A 的舊字串仍可直接讀取；只有舊 killerbee 會覆蓋蜂巢行為。
local bee = Read("_bee")
local beehive = Read("_beehive")
if bee == "killerbee" then beehive = false end

local config = {
    frog = Read("_frog"),
    bee = bee == true or bee == "bee" or bee == "killerbee",
    beehive = beehive,
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
    otter = Read("_otter"),
    lightninggoat = Read("_lightninggoat"),
    rocky = Read("_rocky"),
    monkey = Read("_monkey"),
}

env.no_group_aggro.config = config
