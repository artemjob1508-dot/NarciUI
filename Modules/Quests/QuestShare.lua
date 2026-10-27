local addonName, NS = ...
local L = NS.L

local function HookQuestLog()
    if not QuestLogFrame or QuestLogFrame._narciQuestHooked then return end
    QuestLogFrame._narciQuestHooked = true
    QuestLogFrame:HookScript("OnShow", function()
        if not NS.questDB or not NS.questDB.replaceLog then return end
        if InCombatLockdown() then return end
        NS.After(0, function()
            if QuestLogFrame:IsShown() then HideUIPanel(QuestLogFrame) end
            if NS.QuestLog:IsShown() then
                NS.QuestLog:HideWindow()
            else
                NS.QuestLog:Show()
            end
        end)
    end)
end

local driver = CreateFrame("Frame", "NarciSirus_QuestDriver")
local pendingScan = false
local loggedIn = false

local function ScheduleScan()
    if pendingScan then return end
    pendingScan = true
    NS.After(1.0, function()
        pendingScan = false
        if not loggedIn then return end

        local events = NS.QuestData:Refresh()
        if not events then return end

        for _, event in ipairs(events) do
            NS.QuestBanner:Show({
                type = event.type,
                id = event.quest.id,
                title = event.quest.title,
                objective = event.objIndex and event.quest.objectives[event.objIndex]
                    and event.quest.objectives[event.objIndex].name or "",
                have = event.objIndex and event.quest.objectives[event.objIndex]
                    and event.quest.objectives[event.objIndex].have or 0,
                need = event.objIndex and event.quest.objectives[event.objIndex]
                    and event.quest.objectives[event.objIndex].need or 0,
                sender = nil,
            })
            NS.QuestComm:SendEvent(event)
            NS.QuestBanner:Announce(event)
        end

        if NS.QuestLog then NS.QuestLog:Refresh() end
    end)
end

driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("QUEST_LOG_UPDATE")
driver:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
driver:RegisterEvent("QUEST_ACCEPTED")
driver:RegisterEvent("QUEST_WATCH_UPDATE")
driver:RegisterEvent("PARTY_MEMBERS_CHANGED")
driver:RegisterEvent("RAID_ROSTER_UPDATE")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")

driver:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        NS.questDB = NS.db and NS.db.quests
        NS.QuestComm:Init()
        HookQuestLog()
        loggedIn = true
        NS.After(3, function()
            NS.QuestData:Refresh()
            NS.QuestComm:Hello()
            NS.QuestComm:SendFullState()
        end)

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        NS.QuestComm:Prune()
        NS.After(2, function()
            NS.QuestComm:Hello()
            NS.QuestComm:SendFullState()
        end)
        if NS.QuestLog then NS.QuestLog:Refresh() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        ScheduleScan()

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if NS.QuestLog and NS.QuestLog:IsShown() then
            NS.After(0.5, function() NS.QuestLog:Refresh() end)
        end

    else
        ScheduleScan()
    end
end)

function NS:QuestCommand(msg)
    msg = NS.Trim(NS.Lower(msg or ""))

    if msg == "" then
        NS.QuestLog:Toggle()
    elseif msg == "config" or msg == "настройки" then
        NS.QuestOptions:Toggle()
    elseif msg == "sync" then
        NS.QuestComm:Hello()
        NS.QuestComm:SendFullState()
        NS.Print("состояние отправлено")
    elseif msg == "map" then
        local fileName = GetMapInfo()
        NS.Print("зона: " .. tostring(fileName))
        NS.Print("исследованных участков от клиента: " .. tostring(GetNumMapOverlays and GetNumMapOverlays() or "нет функции"))
        if not NS.MAP_OVERLAYS then
            NS.Print("таблица участков не загружена - нужен полный перезапуск клиента")
        else
            local zones, entries = 0, 0
            for _ in pairs(NS.MAP_OVERLAYS) do zones = zones + 1 end
            local known = fileName and NS.MAP_OVERLAYS[fileName]
            if known then
                for _ in pairs(known) do entries = entries + 1 end
            end
            NS.Print(string.format("таблица загружена: зон %d, участков для этой зоны %d", zones, entries))
        end
        NS.Print("дорисовка неисследованного: " .. (NS.questDB.revealMap and "включена" or "выключена"))
        if NS.QuestLog then
            local drawn, hidden = NS.QuestLog:OverlayStats()
            NS.Print(string.format("нарисовано кусков карты: %d, скрыто: %d", drawn, hidden))
        end
    elseif msg == "worldmap" then
        if NS.WorldMapSkin then
            local on = NS.WorldMapSkin:Toggle()
            NS.Print(on and "карта мира оформлена в стиле аддона" or "карта мира в штатном виде")
        end
    elseif msg == "fog" then
        NS.questDB.revealMap = not NS.questDB.revealMap
        NS.Print(NS.questDB.revealMap and "неисследованные области карты показываются"
            or "неисследованные области карты скрыты")
        if NS.QuestLog and NS.QuestLog:IsShown() then NS.QuestLog:Refresh() end
    elseif msg == "stock" then
        NS.questDB.replaceLog = not NS.questDB.replaceLog
        NS.Print(NS.questDB.replaceLog and "кнопка журнала открывает окно заданий аддона"
            or "кнопка журнала открывает штатное окно")
    elseif msg == "status" then
        local peers = 0
        for _ in pairs(NS.QuestComm.peers) do peers = peers + 1 end
        NS.Print(string.format("моих заданий: %d, игроков с аддоном рядом: %d", NS.QuestData:Count(), peers))
        local channels = {}
        if NS.questDB.channels.party then channels[#channels + 1] = "группа" end
        if NS.questDB.channels.raid then channels[#channels + 1] = "рейд" end
        if NS.questDB.channels.guild then channels[#channels + 1] = "гильдия" end
        NS.Print("каналы: " .. (#channels > 0 and table.concat(channels, ", ") or "нет"))
    else
        NS.Print("команды: /narci quests, config, sync, status, stock, worldmap, fog, map")
    end
end

function NS:ToggleQuestLog()
    if not NS.QuestLog then
        NS.Print("модуль заданий не загружен")
        return
    end
    NS.QuestLog:Toggle()
end
