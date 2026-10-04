-- 組裝入口：讀取設定，並將 MOD API 明確傳入各功能模組。
local modid = 'no_group_aggro'
local config = GLOBAL.require("no_group_aggro/config")(GetModConfigData, modid)
local api = {
    GLOBAL = GLOBAL,
    AddPrefabPostInit = AddPrefabPostInit,
}

GLOBAL.require("no_group_aggro/creatures")(api, config)
GLOBAL.require("no_group_aggro/bees")(api, config)
GLOBAL.require("no_group_aggro/spiders")(api, config)
GLOBAL.require("no_group_aggro/penguins")(api, config)
GLOBAL.require("no_group_aggro/monkeys")(api, config)
