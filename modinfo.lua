---@diagnostic disable: lowercase-global, undefined-global

local modid = 'no_group_aggro'

local onof_zh = {
    { '有群體仇恨', false },
    { '無群體仇恨', true },
}

local onof_en = {
    { 'Has Group Aggro', false },
    { 'No Group Aggro',  true },
}

local LANGS = {
    ['zh'] = {
        name = '無群體仇恨',
        description = '移除青蛙、皮弗婁牛、豬人、企鷗等生物的群體仇恨機制，每個生物可單獨開關，不影響玩家雇傭的生物。',
        config = {
            { modid .. '_frog', '青蛙', '包含明眼青蛙', true, onof_zh },
            { modid .. '_beefalo', '皮弗婁牛', '包含小皮弗婁牛', true, onof_zh },
            { modid .. '_pigman', '豬人', '包含豬人守衛和瘋豬，不含面具豬人', true, onof_zh },
            { modid .. '_bunnyman', '兔人', '不含面具兔人', true, onof_zh },
            { modid .. '_merm', '魚人', '包含魚人守衛，不含面具魚人', true, onof_zh },
            { modid .. '_penguin', '企鷗', '包含永冻企鸥', true, onof_zh },
        }
    },
    ['en'] = {
        name = "Extra Circular Lunar Island",
        description =
        "Remove the group hatred mechanism from creatures such as frogs, beefalo, pigmen, and penguins; each creature can be individually toggled on/off.",
        config = {
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
