-- 企鵝與月亮企鵝的單體索敵及受擊反應。
local config = env.no_group_aggro.config

if config.penguin then
    -- 重寫企鵝的防呆單體索敵邏輯
    local function PenguinSafeRetarget(inst)
        if inst.components.hunger and not inst.components.hunger:IsStarving() then
            return nil
        end
        -- 只回傳目標，不呼叫 MakeTeam
        return FindEntity(inst, 3, function(guy) return inst.components.combat:CanTarget(guy) end,
            { "_combat" }, { "penguin" }, { "character", "monster", "wall" })
    end

    -- 重寫月亮企鵝的單體索敵邏輯
    local function MutatedPenguinSafeRetarget(inst)
        return FindEntity(inst, 4, function(guy) return inst.components.combat:CanTarget(guy) end,
            { "_combat" }, { "penguin", "mutantdominant" }, { "character", "monster", "smallcreature", "animal", "wall" })
    end

    local function SafeRemovePenguinGroupAggro(inst)
        if not TheWorld.ismastersim then return end

        if inst.components.combat then
            -- 替換索敵函數，切斷主動組隊
            if inst.prefab == "mutated_penguin" then
                inst.components.combat:SetRetargetFunction(2, MutatedPenguinSafeRetarget)
            else
                inst.components.combat:SetRetargetFunction(3, PenguinSafeRetarget)
            end

            -- 替換維持目標邏輯，不再依賴隊長指令
            inst.components.combat:SetKeepTargetFunction(function(self_inst, target)
                return self_inst.components.combat:CanTarget(target)
            end)
        end

        -- 處理受擊邏輯：移除原版帶有呼朋引伴功能的事件
        inst:RemoveAllEventCallbacks("attacked")

        -- 補回單兵作戰的受擊反應
        inst:ListenForEvent("attacked", function(self_inst, data)
            local attacker = data and data.attacker or nil
            if attacker and self_inst.components.combat then
                self_inst.components.combat:SetTarget(attacker)
                -- 不呼叫 ShareTarget，也不使用 teamattacker
            end
        end)
    end

    AddPrefabPostInit("penguin", SafeRemovePenguinGroupAggro)
    AddPrefabPostInit("mutated_penguin", SafeRemovePenguinGroupAggro)
end
