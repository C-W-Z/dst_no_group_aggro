GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid = 'no_group_aggro' -- 定义唯一modid

---@param inst ent
local function RemoveGroupAggro(inst)
    if not TheWorld.ismastersim then return end

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

if GetModConfigData(modid .. "_frog") then
    AddPrefabPostInit("frog", RemoveGroupAggro)
    AddPrefabPostInit("lunarfrog", RemoveGroupAggro)
end

local bee_type = GetModConfigData(modid .. "_bee")
if bee_type then
    local function DisableBeeHerdAggro(inst)
        if not TheWorld.ismastersim then return end

        -- 清除原版的受擊與被網子抓的事件，切斷原版的所有連動
        inst:RemoveAllEventCallbacks("attacked")
        inst:RemoveAllEventCallbacks("worked")

        -- 重新編寫受擊邏輯
        ---@param self_inst ent
        ---@param data table
        local function SafeOnAttacked(self_inst, data)
            local attacker = data and data.attacker
            if attacker and self_inst.components.combat then
                self_inst.components.combat:SetTarget(attacker)

                -- 讓蜂巢釋放蜜蜂，但不傳遞仇恨 (傳入 nil)
                -- 並根據被打的蜜蜂種類，決定出來的種類
                if self_inst.components.homeseeker and self_inst.components.homeseeker.home then
                    local home = self_inst.components.homeseeker.home
                    if home and home.components.childspawner then
                        -- 不呼叫 ShareTarget，也不傳遞 attacker
                        home.components.childspawner:ReleaseAllChildren(nil, bee_type)
                    end
                end
            end
        end

        local function SafeOnWorked(self_inst, data)
            SafeOnAttacked(self_inst, { attacker = data.worker })
        end

        -- 綁定新的安全事件
        inst:ListenForEvent("attacked", SafeOnAttacked)
        inst:ListenForEvent("worked", SafeOnWorked)
    end

    AddPrefabPostInit("bee", DisableBeeHerdAggro)
    -- AddPrefabPostInit("killerbee", DisableBeeHerdAggro)
end

if GetModConfigData(modid .. "_beefalo") then
    AddPrefabPostInit("beefalo", RemoveGroupAggro)
    AddPrefabPostInit("babybeefalo", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_pigman") then
    AddPrefabPostInit("pigman", RemoveGroupAggro)
    AddPrefabPostInit("pigguard", RemoveGroupAggro)
    AddPrefabPostInit("moonpig", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_bunnyman") then
    AddPrefabPostInit("bunnyman", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_merm") then
    AddPrefabPostInit("merm", RemoveGroupAggro)
    AddPrefabPostInit("mermguard", RemoveGroupAggro)
    -- AddPrefabPostInit("merm_shadow", RemoveGroupAggro)
    -- AddPrefabPostInit("mermguard_shadow", RemoveGroupAggro)
    -- AddPrefabPostInit("merm_lunar", RemoveGroupAggro)
    -- AddPrefabPostInit("mermguard_lunar", RemoveGroupAggro)
    AddPrefabPostInit("mermking", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.combat then
            inst.components.combat.ShareTarget = function()
                -- Do nothing，魚人王不再向周圍廣播仇恨，但還是會召喚4隻專屬護衛
            end
        end
    end)
end

if GetModConfigData(modid .. "_penguin") then
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

    local function SafeRemovePenguinHerdAggro(inst)
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

    AddPrefabPostInit("penguin", SafeRemovePenguinHerdAggro)
    AddPrefabPostInit("mutated_penguin", SafeRemovePenguinHerdAggro)
end

if GetModConfigData(modid .. "otter") then
    AddPrefabPostInit("otter", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_lightninggoat") then
    AddPrefabPostInit("lightninggoat", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_rocky") then
    AddPrefabPostInit("rocky", RemoveGroupAggro)
end
