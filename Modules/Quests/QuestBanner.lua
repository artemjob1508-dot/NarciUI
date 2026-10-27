local addonName, NS = ...

local Banner = {}
NS.QuestBanner = Banner

local COLORS = {
    accept   = { r = 0.35, g = 0.75, b = 1.00 },
    progress = { r = 0.70, g = 0.70, b = 0.75 },
    objdone  = { r = 0.20, g = 0.85, b = 0.55 },
    complete = { r = 0.00, g = 0.85, b = 0.60 },
    turnin   = { r = 1.00, g = 0.82, b = 0.00 },
    abandon  = { r = 0.60, g = 0.60, b = 0.65 },
    fail     = { r = 0.85, g = 0.30, b = 0.30 },
    everyone = { r = 0.75, g = 0.45, b = 1.00 },
}

local VERBS = {
    accept   = "взял задание",
    progress = "продвинулся",
    objdone  = "выполнил цель",
    complete = "завершил задание",
    turnin   = "сдал задание",
    abandon  = "бросил задание",
    fail     = "провалил задание",
}

local CHAT_VERBS = {
    accept   = "взял",
    progress = "прогресс",
    objdone  = "цель выполнена",
    complete = "завершил",
    turnin   = "сдал",
    abandon  = "бросил",
    fail     = "провалил",
}

local function Enabled(eventType, own)
    local db = NS.questDB
    if not db then return false end
    if own then
        if not db.ownBanners then return false end
    end
    if db.events[eventType] == false then return false end
    return true
end

function Banner:Line(event)
    local verb = VERBS[event.type] or event.type
    local objective = ""
    if event.objective and event.objective ~= "" and event.need and event.need > 0 then
        objective = string.format(" (%s %d/%d)", event.objective, event.have, event.need)
    end
    return string.format("%s: %s [%s]%s", event.sender or NS.PlayerName(), verb, event.title or "", objective)
end

function Banner:Show(event)
    local own = event.sender == nil or event.sender == NS.PlayerName()
    if not Enabled(event.type, own) then return end
    if not NS.questDB.banners then return end

    local color = COLORS[event.type] or COLORS.progress
    RaidNotice_AddMessage(RaidWarningFrame, self:Line(event), color)

    if NS.questDB.chatOutput then
        NS.Print(self:Line(event))
    end

    if event.type == "complete" or event.type == "objdone" then
        self:CheckEveryone(event.id, event.title)
    end
end

function Banner:CheckEveryone(questID, title)
    if not questID or not NS.questDB.everyoneNotice then return end

    local own = NS.QuestData:Get(questID)
    local total, done = 0, 0

    if own then
        total = total + 1
        if NS.QuestData:AllComplete(own) then done = done + 1 end
    end

    for _, peer in pairs(NS.QuestComm.peers) do
        local quest = peer.quests[questID]
        if quest then
            total = total + 1
            if quest.complete then done = done + 1 end
        end
    end

    if total >= 2 and done == total then
        if self._announced and self._announced[questID] then return end
        self._announced = self._announced or {}
        self._announced[questID] = true
        RaidNotice_AddMessage(RaidWarningFrame,
            string.format("Все закончили: [%s]", title or ("#" .. questID)), COLORS.everyone)
    end
end

function Banner:Announce(event)
    local db = NS.questDB
    if not db or not db.announce then return end
    local channel = NS.GroupChannel()
    if not channel then return end

    local objective = ""
    local quest = event.quest
    local objectiveData = event.objIndex and quest.objectives[event.objIndex]
    if objectiveData then
        objective = string.format(" (%s %d/%d)", objectiveData.name, objectiveData.have, objectiveData.need)
    end

    SendChatMessage(string.format("Задание %s: [%s]%s",
        CHAT_VERBS[event.type] or event.type, quest.title, objective), channel)
end
