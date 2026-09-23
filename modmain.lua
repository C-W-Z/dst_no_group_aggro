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
    local function CustomBeeOnAttacked(inst, data)
        local attacker = data and data.attacker
        if attacker and inst.components.combat then
            inst.components.combat:SetTarget(attacker)
        end

        -- 處理蜂巢釋放邏輯
        if inst.components.combat and inst.components.combat:HasTarget() then
            if inst.components.homeseeker and inst.components.homeseeker.home then
                local home = inst.components.homeseeker.home
                if home and home.components.childspawner then
                    if inst.prefab == "bee" then
                        -- 根據設定決定普通蜜蜂巢穴的反應
                        if bee_type == "bee" then
                            home.components.childspawner:ReleaseAllChildren(nil, "bee")
                        else
                            home.components.childspawner:ReleaseAllChildren(attacker, "killerbee")
                        end
                    else
                        -- 如果是殺人蜂 (killerbee) 被打，永遠放出帶仇恨的殺人蜂
                        home.components.childspawner:ReleaseAllChildren(attacker, "killerbee")
                    end
                end
            end
        end
        -- 這裡完全不呼叫 ShareTarget，切斷外面蜜蜂的仇恨傳播
    end

    local function CustomBeeOnWorked(inst, data)
        CustomBeeOnAttacked(inst, { attacker = data.worker })
    end

    local function DisableBeeHerdAggro(inst)
        if not TheWorld.ismastersim then
            return
        end

        -- 清除原版事件
        inst:RemoveAllEventCallbacks("attacked")
        inst:RemoveAllEventCallbacks("worked")

        -- 綁定我們自定義的事件
        inst:ListenForEvent("attacked", CustomBeeOnAttacked)
        inst:ListenForEvent("worked", CustomBeeOnWorked)

        -- 保險起見，掏空 ShareTarget 避免其他模組或底層邏輯呼叫
        if inst.components.combat then
            inst.components.combat.ShareTarget = function()
            end
        end
    end

    AddPrefabPostInit("bee", DisableBeeHerdAggro)
    AddPrefabPostInit("killerbee", DisableBeeHerdAggro)

    -- 處理蜂巢/蜂箱本體被打、被燒、被收蜜的邏輯
    -- 針對建築物 (蜂巢與蜂箱) 的 Patch
    AddPrefabPostInit("beehive", function(inst)
        if not TheWorld.ismastersim then
            return
        end

        if inst.components.childspawner then
            -- 備份原版的釋放函數
            local old_ReleaseAllChildren = inst.components.childspawner.ReleaseAllChildren

            -- 攔截並覆寫釋放函數
            inst.components.childspawner.ReleaseAllChildren = function(self, target, prefab)
                -- 這個攔截只針對 bee_type == "bee" 的設定起作用
                -- 如果是 "killerbee"，就維持原版行為
                if bee_type == "bee" then
                    -- 強制將目標設為 nil，出來的蜂種強制設為 "bee"
                    return old_ReleaseAllChildren(self, nil, "bee")
                else
                    -- 原版設定：交由原始函數處理 (可能帶有 target 和 "killerbee")
                    return old_ReleaseAllChildren(self, target, prefab)
                end
            end
        end
    end)

    local function SafeBeebox(inst)
        if not TheWorld.ismastersim then
            return
        end

        -- 處理收蜜時不釋放蜜蜂的邏輯
        if inst.components.harvestable then
            local old_onharvest = inst.components.harvestable.onharvestfn
            inst.components.harvestable.onharvestfn = function(self_inst, picker, produce)
                if self_inst.components.childspawner then
                    -- 暫存原版函數，並在收蜜期間短暫替換為空函數
                    local old_release = self_inst.components.childspawner.ReleaseAllChildren
                    self_inst.components.childspawner.ReleaseAllChildren = function() end

                    -- 執行原版收蜜邏輯
                    old_onharvest(self_inst, picker, produce)

                    -- 恢復原版釋放函數
                    self_inst.components.childspawner.ReleaseAllChildren = old_release
                else
                    old_onharvest(self_inst, picker, produce)
                end
            end
        end

        -- 處理被燒等其他情況釋放但無仇恨的邏輯
        if inst.components.childspawner then
            local old_ReleaseAllChildren = inst.components.childspawner.ReleaseAllChildren
            inst.components.childspawner.ReleaseAllChildren = function(self, target, prefab)
                -- 強制清除仇恨目標，並保證出來的是普通蜜蜂
                return old_ReleaseAllChildren(self, nil, "bee")
            end
        end
    end

    AddPrefabPostInit("beebox", SafeBeebox)
    AddPrefabPostInit("beebox_hermit", SafeBeebox)
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
