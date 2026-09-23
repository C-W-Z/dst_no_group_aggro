---@diagnostic disable: lowercase-global, undefined-global

local modid = 'no_group_aggro'

local onof_zh = {
    { '原版', false, "不修改任何机制" },
    { '无群体仇恨', true },
}

local onof_en = {
    { 'Vanilla', false, "Do not modify any mechanics" },
    { 'No Group Aggro',  true },
}

local LANGS = {
    ['zh'] = {
        name = '无群体仇恨',
        description =
        '移除青蛙、皮弗娄牛、猪人、企鸥等生物的群体仇恨机制。\n每种生物可单独开关，不影响玩家雇佣的生物。\n注意：不会改变生物的主动仇恨范围，因此对于索敌范围大的主动敌对生物效果可能较不明显，使用远程武器才比较容易感受到，例如鱼人、猪人守卫、永冻企鸥、充电伏特羊。',
        config = {
            { modid .. '_frog', '青蛙', '包含明眼青蛙', true, onof_zh },
            { modid .. '_bee', '蜜蜂', '包含蜂箱蜜蜂，不含杀人蜂和嗡嗡蜜蜂', "bee", {
                { '有群体仇恨', false, "不修改任何机制" },
                { '无群体仇恨(1)', "bee", "被攻击或被捕虫网抓时蜂巢出无仇恨蜜蜂" },
                { '无群体仇恨(2)', "killerbee", "被攻击或被捕虫网抓时蜂巢出有仇恨杀人蜂" },
            } },
            -- { modid .. '_spider', '蜘蛛', '包含各种蜘蛛', true, onof_zh },
            { modid .. '_beefalo', '皮弗娄牛', '包含小皮弗娄牛', true, onof_zh },
            { modid .. '_pigman', '猪人', '包含猪人守卫和疯猪，不含面具猪人', true, onof_zh },
            { modid .. '_bunnyman', '兔人', '不含舒适兔人、皇家兔子警卫和面具兔人', true, onof_zh },
            { modid .. '_merm', '鱼人', '包含忠诚鱼人守卫，不含面具鱼人', true, onof_zh },
            { modid .. '_penguin', '企鸥', '包含永冻企鸥', true, onof_zh },
            { modid .. '_otter', '水獭掠夺者', '', true, onof_zh },
            { modid .. '_lightninggoat', '充电伏特羊', '', true, onof_zh },
            { modid .. '_rocky', '石虾', '不含面具石虾', true, onof_zh },
        }
    },
    ['en'] = {
        name = 'No Group Aggro',
        description =
        'Removes the group aggro mechanics from creatures like Frogs, Beefalos, Pigmen, and Pengulls.\nEach creature can be toggled individually. Does not affect followers hired by players.\nNote: This does not change the active aggro range of creatures. Therefore, the effect might be less noticeable for actively hostile creatures with large aggro radii (e.g., Merms, Guard Pigs, Mutated Pengulls, Charged Lightning Goats) unless you use ranged weapons.',
        config = {
            { modid .. '_frog', 'Frogs', 'Includes Bright-Eyed Frog', true, onof_en },
            { modid .. '_bee', 'Bees', 'Includes bees from bee boxes, excludes Killer Bees and Grumble Bees', "bee", {
                { 'Vanilla', false, "Do not modify any mechanics" },
                { 'No Group Aggro (1)', "bee", "Hives spawn non-aggressive bees when attacked or netted" },
                { 'No Group Aggro (2)', "killerbee", "Hives spawn aggressive killer bees when attacked or netted" },
            } },
            -- { modid .. '_spider', 'Spiders', 'Includes all spider variants', true, onof_en },
            { modid .. '_beefalo', 'Beefalos', 'Includes Baby Beefalos', true, onof_en },
            { modid .. '_pigman', 'Pigmen', 'Includes Guard Pigs and Werepigs, excludes Enthralled Pigmen', true, onof_en },
            { modid .. '_bunnyman', 'Bunnymen', 'Excludes Cozy Bunnymen, Royal Rabbit Enforcer, and Enthralled Bunnymen', true, onof_en },
            { modid .. '_merm', 'Merms', 'Includes Loyal Merm Guards, excludes Enthralled Merms', true, onof_en },
            { modid .. '_penguin', 'Pengulls', 'Includes Mutated Pengulls', true, onof_en },
            { modid .. '_otter', 'Marotter', '', true, onof_en },
            { modid .. '_lightninggoat', 'Charged Lightning Goats', '', true, onof_en },
            { modid .. '_rocky', 'Rock Lobsters', 'Excludes Enthralled Rock Lobsters', true, onof_en },
        }
    }
}

-- 决定当前用的语言
local cur = (locale == 'zh' or locale == 'zhr' or locale == 'zht') and 'zh' or 'en'

-- mod相关信息
version = '1.0.0'
author = 'Icya'
forumthread = ''
api_version = 10
priority = 0                                 -- 加载优先级，越低加载越晚，默认为0

dst_compatible = true                        -- 联机版适配性
dont_starve_compatible = false               -- 单机版适配性
reign_of_giants_compatible = false           -- 单机版：巨人国适配性
-- all_clients_require_mod = true     -- 服务端/所有端模组
server_only_mod = true                       -- 仅服务端模组
-- client_only_mod = true -- 仅客户端模组
server_filter_tags = { 'creature', 'tweak' } -- 创意工坊模组分类标签
icon_atlas = 'modicon.xml'                   -- 图集
icon = 'modicon.tex'                         -- 图标

-- 以下自动配置
name = LANGS[cur].name
description = version .. '\n' .. LANGS[cur].description

local config = LANGS[cur].config or {}
local _configuration_options = {}
for i = 1, #config do
    local options = {}
    if config[i][5] then
        for k = 1, #config[i][5] do
            options[k] = { description = config[i][5][k][1], data = config[i][5][k][2], hover = config[i][5][k][3] }
        end
    end
    _configuration_options[i] = {
        name = config[i][1],
        label = config[i][2],
        hover = config[i][3] or '',
        default = config[i][4] or false,
        options = #options > 0 and options or { { description = "", data = false } },
    }
    if config[i].slider_data then
        _configuration_options[i].slider_data = config[i].slider_data
    end
end

configuration_options = _configuration_options
