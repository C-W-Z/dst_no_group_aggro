# 程式結構

此 MOD 只需伺服器安裝。`modmain.lua` 是組裝入口：讀取設定，將
`GLOBAL` 和 `AddPrefabPostInit` 明確傳入功能模組，再註冊各生物的 Hook。
它不再替 MOD 環境設定全域 fallback。

| 檔案（相對於 MOD 根目錄） | 職責 |
| --- | --- |
| `modmain.lua` | 設定與功能模組的組裝及載入順序 |
| `scripts/no_group_aggro/config.lua` | 設定 key、蜘蛛缺省值、蜂巢與蜂箱的繼承規則 |
| `scripts/no_group_aggro/creatures.lua` | 通用 ShareTarget 攔截、隨從與寄生宿主例外、魚人王 |
| `scripts/no_group_aggro/bees.lua` | 蜜蜂分享仇恨、蜂巢放蜂、蜂箱採蜜與放蜂 |
| `scripts/no_group_aggro/spiders.lua` | 蜘蛛、巢穴與女王，以及它們共用的生成上下文和存檔標記 |
| `scripts/no_group_aggro/penguins.lua` | 企鵝與月亮企鵝的索敵、維持目標及受擊事件 |
| `scripts/no_group_aggro/monkeys.lua` | 猴子的受擊事件篩選、反擊及騷擾任務清理 |

## 載入與依賴

遊戲將 MOD 的 `scripts/?.lua` 加入模組搜尋路徑，因此入口以
`GLOBAL.require("no_group_aggro/模組名稱")` 載入。獨立的 `no_group_aggro/`
名稱空間避免與其他 MOD 的一般檔名混用。

`config.lua` 回傳設定解析函式，介面為 `(GetModConfigData, modid)`；
其他模組回傳註冊函式，介面為 `(api, config)`。`api` 只提供上述兩個依賴。
模組載入本身不註冊 Hook；入口每次呼叫註冊函式才建立 callbacks 和私有狀態，
不把某次載入的設定或蜘蛛生成上下文留在 `require` 的快取中。

蜘蛛、巢穴與女王的 Hook 依賴同一個 `spider_context`，因此保留在同一模組。
新增功能優先放入對應功能模組；新增設定集中在 `config.lua` 解析，選單仍由
獨立環境中的 `modinfo.lua` 定義。遊戲全域採明確的 `GLOBAL` 引用，
修改 components 的 callbacks 先檢查 `GLOBAL.TheWorld.ismastersim`。

## 重構範圍與既有問題

此次只調整結構，保留設定值、缺省行為、Hook 對象與遊戲邏輯。
水獺原入口讀取 `no_group_aggrootter`，而選單使用 `no_group_aggro_otter`；
`config.lua` 暫時保留原讀取 key，修正此問題需要另外的行為變更。
猴子依來源檔名篩選原版事件、企鵝移除全部 `attacked` callbacks 的既有做法
也維持原狀，仍有與其他 MOD 互動的相容性風險。

## 驗證

本次以重構前的 Git HEAD 與新入口作對照，通過蜘蛛 685 項斷言、蜜蜂 65 組
情境，以及 3,273 項設定與生物行為對照斷言（135 組設定、102 組生物情境）。
涵蓋重複載入時的設定隔離、客戶端檢查、隨從／寄生宿主例外、多重回傳、
企鵝索敵及猴子事件／任務清理。未執行 DST 遊戲內測試。

語法檢查只涵蓋本次修改的入口與功能模組。Lua 5.5 的語法檢查、設定／Hook
對照及模擬引擎回歸測試不能證明 Lua 5.1 或 DST 遊戲內相容性。

遊戲內仍需驗證：主機搭配遠端客戶端或 dedicated server、地表／洞穴、
設定開關與舊設定繼承、存檔重載，以及原版對照和其他 MOD 的相容性。
重點包括隨從與寄生宿主、蜂箱採蜜、蜘蛛巢防衛／警報／女王生成、
企鵝索敵及猴子受擊反應。打包時必須一起包含 `scripts/no_group_aggro/`。
