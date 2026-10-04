-- 猴子的原版事件移除與單體反擊；保留既有事件篩選方式。
return function(api, config)
    local GLOBAL = api.GLOBAL
    local AddPrefabPostInit = api.AddPrefabPostInit

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
                if GLOBAL.type(fn) == "function" then
                    local info = GLOBAL.debug.getinfo(fn, "S")
                    -- 透過來源路徑比對是否為官方寫在該生物 lua 檔中的函數
                    if info and info.source and GLOBAL.string.find(info.source, filename) then
                        -- 找到目標後，使用底層標準的 API 乾淨地移除它
                        inst:RemoveEventCallback(event, fn)
                    end
                end
            end
        end
    end

    if config.monkey then
        AddPrefabPostInit("monkey", function(inst)
            if not GLOBAL.TheWorld.ismastersim then return end

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

                    self_inst.task = self_inst:DoTaskInTime(GLOBAL.math.random(55, 65), function(i)
                        if i.components.combat then i.components.combat:SetTarget(nil) end
                    end)
                end
            end

            -- 綁定我們安全處理過的新事件
            inst:ListenForEvent("attacked", SafeOnAttacked)
        end)
    end
end
