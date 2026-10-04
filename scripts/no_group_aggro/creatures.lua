-- 通用 ShareTarget 攔截與魚人王的個別處理。
return function(api, config)
    local GLOBAL = api.GLOBAL
    local AddPrefabPostInit = api.AddPrefabPostInit

    ---@param inst ent
    local function RemoveGroupAggro(inst)
        if not GLOBAL.TheWorld.ismastersim then return end

        if inst.components.combat then
            local old_ShareTarget = inst.components.combat.ShareTarget

            inst.components.combat.ShareTarget = function(self_inst, target, range, fn, maxnum, musttags)
                if not self_inst.inst or not self_inst.inst:IsValid() then
                    return
                end

                -- 如果是玩家招募的隨從，保留仇恨聯動
                if self_inst.inst.components.follower and self_inst.inst.components.follower.leader ~= nil then
                    return old_ShareTarget(self_inst, target, range, fn, maxnum, musttags)
                end

                -- 如果是面具生物，保留其群體機制
                if self_inst.inst:HasTag("shadowthrall_parasite_hosted") then
                    return old_ShareTarget(self_inst, target, range, fn, maxnum, musttags)
                end

                -- 其他情況直接阻斷，不呼叫原本的 ShareTarget
                return
            end
        end
    end

    if config.frog then
        AddPrefabPostInit("frog", RemoveGroupAggro)
        AddPrefabPostInit("lunarfrog", RemoveGroupAggro)
    end

    if config.beefalo then
        AddPrefabPostInit("beefalo", RemoveGroupAggro)
        AddPrefabPostInit("babybeefalo", RemoveGroupAggro)
    end

    if config.pigman then
        AddPrefabPostInit("pigman", RemoveGroupAggro)
        AddPrefabPostInit("pigguard", RemoveGroupAggro)
        AddPrefabPostInit("moonpig", RemoveGroupAggro)
    end

    if config.bunnyman then
        AddPrefabPostInit("bunnyman", RemoveGroupAggro)
    end

    if config.merm then
        AddPrefabPostInit("merm", RemoveGroupAggro)
        AddPrefabPostInit("mermguard", RemoveGroupAggro)
        -- AddPrefabPostInit("merm_shadow", RemoveGroupAggro)
        -- AddPrefabPostInit("mermguard_shadow", RemoveGroupAggro)
        -- AddPrefabPostInit("merm_lunar", RemoveGroupAggro)
        -- AddPrefabPostInit("mermguard_lunar", RemoveGroupAggro)
        AddPrefabPostInit("mermking", function(inst)
            if not GLOBAL.TheWorld.ismastersim then return end
            if inst.components.combat then
                inst.components.combat.ShareTarget = function()
                    -- Do nothing，魚人王不再向周圍廣播仇恨，但還是會召喚4隻專屬護衛
                end
            end
        end)
    end

    if config.otter then
        AddPrefabPostInit("otter", RemoveGroupAggro)
    end

    if config.lightninggoat then
        AddPrefabPostInit("lightninggoat", RemoveGroupAggro)
    end

    if config.rocky then
        AddPrefabPostInit("rocky", RemoveGroupAggro)
    end
end
