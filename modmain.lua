GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid = 'no_group_aggro' -- 定义唯一modid

--- 輔助函式，清除特定檔案中註冊的特定event的callback
---@param inst ent
---@param event string
---@param filename string
local function RemoveVanillaEventCallback(inst, event, filename)
    -- 確保事件表存在，且該實體有監聽自己的該事件
    if inst.event_listeners and inst.event_listeners[event] and inst.event_listeners[event][inst] then
        local listener_fns = inst.event_listeners[event][inst]

        -- 倒序遍歷，因為呼叫 RemoveEventCallback 會改變陣列長度 (RemoveByValue)
        for i = #listener_fns, 1, -1 do
            local fn = listener_fns[i]
            if type(fn) == "function" then
                local info = debug.getinfo(fn, "S")
                -- 透過來源路徑比對是否為官方寫在該生物 lua 檔中的函數
                if info and info.source and string.find(info.source, filename) then
                    -- 找到目標後，使用底層標準的 API 乾淨地移除它
                    inst:RemoveEventCallback(event, fn)
                end
            end
        end
    end
end

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

local bee_config = GetModConfigData(modid .. "_bee")
local beehive_config = GetModConfigData(modid .. "_beehive")
local beebox_config = GetModConfigData(modid .. "_beebox")

-- 新設定預設跟隨舊選項；也處理舊 modoverrides.lua 未包含新 key 的情況。
if beehive_config == nil or beehive_config == "inherit" then
    beehive_config = bee_config == "bee" and "bee" or false
end
if beebox_config == nil or beebox_config == "inherit" then
    beebox_config = bee_config ~= nil and bee_config ~= false
end

-- 仇恨由受擊的蜂傳遞，普通蜜蜂及殺人蜂都需要攔截 ShareTarget。
-- 保留原版受擊、捕捉和呼叫巢穴放蜂的事件，由巢穴的獨立設定處理放蜂。
if bee_config then
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
if beehive_config == "bee" then
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
if beebox_config then
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

if GetModConfigData(modid .. "otter") then
    AddPrefabPostInit("otter", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_lightninggoat") then
    AddPrefabPostInit("lightninggoat", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_rocky") then
    AddPrefabPostInit("rocky", RemoveGroupAggro)
end

if GetModConfigData(modid .. "_monkey") then
    AddPrefabPostInit("monkey", function(inst)
        if not TheWorld.ismastersim then return end

        -- 精準移除 monkey.lua 中綁定的 attacked 事件，保留其他所有模組或組件的監聽
        RemoveVanillaEventCallback(inst, "attacked", "monkey.lua")

        -- 建立一個乾淨的單體反擊事件
        local function SafeOnAttacked(self_inst, data)
            local attacker = data and data.attacker
            if attacker and self_inst.components.combat then
                self_inst.components.combat:SetTarget(attacker)

                if self_inst.harassplayer ~= nil then
                    if self_inst._harassovertask ~= nil then
                        self_inst._harassovertask:Cancel()
                        self_inst._harassovertask = nil
                    end
                    self_inst:RemoveEventCallback("onremove", self_inst._onharassplayerremoved, self_inst.harassplayer)
                    self_inst.harassplayer = nil
                end

                if self_inst.task ~= nil then
                    self_inst.task:Cancel()
                end

                self_inst.task = self_inst:DoTaskInTime(math.random(55, 65), function(i)
                    if i.components.combat then i.components.combat:SetTarget(nil) end
                end)
            end
        end

        -- 綁定我們安全處理過的新事件
        inst:ListenForEvent("attacked", SafeOnAttacked)
    end)
end
