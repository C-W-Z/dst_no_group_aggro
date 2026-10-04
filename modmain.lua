GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 組裝入口：modimport 在同一個 MOD 環境執行各檔案，不回傳模組結果。
env.no_group_aggro = { modid = 'no_group_aggro' }

modimport("scripts/no_group_aggro/config.lua")
modimport("scripts/no_group_aggro/creatures.lua")
modimport("scripts/no_group_aggro/bees.lua")
modimport("scripts/no_group_aggro/spiders.lua")
modimport("scripts/no_group_aggro/penguins.lua")
modimport("scripts/no_group_aggro/monkeys.lua")
