-- 蜜蜂、野生蜂巢與蜂箱；設定繼承已由 config.lua 解析。
return function(api, config)
    local GLOBAL = api.GLOBAL
    local AddPrefabPostInit = api.AddPrefabPostInit

    -- 仇恨由受擊的蜂傳遞，普通蜜蜂及殺人蜂都需要攔截 ShareTarget。
    -- 保留原版受擊、捕捉和呼叫巢穴放蜂的事件，由巢穴的獨立設定處理放蜂。
    if config.bee then
        local function DisableBeeGroupAggro(inst)
            if not GLOBAL.TheWorld.ismastersim then return end
            if inst.components.combat then
                inst.components.combat.ShareTarget = function() end
            end
        end

        AddPrefabPostInit("bee", DisableBeeGroupAggro)
        AddPrefabPostInit("killerbee", DisableBeeGroupAggro)
    end

    -- 蜂巢獨立決定放出的蜂種與目標，包括巢外蜜蜂受擊／捕捉時的放蜂請求。
    if config.beehive == "bee" then
        AddPrefabPostInit("beehive", function(inst)
            if not GLOBAL.TheWorld.ismastersim then return end
            if inst.components.childspawner then
                local old_ReleaseAllChildren = inst.components.childspawner.ReleaseAllChildren
                inst.components.childspawner.ReleaseAllChildren = function(self, target, prefab, ...)
                    return old_ReleaseAllChildren(self, nil, "bee", ...)
                end
            end
        end)
    end

    -- 蜂箱獨立控制採蜜和其他放蜂反應，不受蜜蜂或野生蜂巢設定影響。
    if config.beebox then
        local function SafeBeebox(inst)
            if not GLOBAL.TheWorld.ismastersim then return end

            if inst.components.harvestable and inst.components.harvestable.onharvestfn then
                local old_onharvest = inst.components.harvestable.onharvestfn
                inst.components.harvestable.onharvestfn = function(self_inst, picker, produce, ...)
                    if self_inst.components.childspawner then
                        local spawner = self_inst.components.childspawner
                        local old_release = spawner.ReleaseAllChildren
                        spawner.ReleaseAllChildren = function() end

                        -- 完成原版採蜜後恢復放蜂方法，並保留所有回傳值。
                        local function FinishHarvest(...)
                            spawner.ReleaseAllChildren = old_release
                            return ...
                        end
                        return FinishHarvest(old_onharvest(self_inst, picker, produce, ...))
                    end
                    return old_onharvest(self_inst, picker, produce, ...)
                end
            end

            if inst.components.childspawner then
                local old_ReleaseAllChildren = inst.components.childspawner.ReleaseAllChildren
                inst.components.childspawner.ReleaseAllChildren = function(self, target, prefab, ...)
                    return old_ReleaseAllChildren(self, nil, "bee", ...)
                end
            end
        end

        AddPrefabPostInit("beebox", SafeBeebox)
        AddPrefabPostInit("beebox_hermit", SafeBeebox)
    end
end
