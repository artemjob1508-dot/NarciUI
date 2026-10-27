local addonName, NS = ...

local Quests = {}
NS.QuestData = Quests

Quests.own = {}
Quests.ready = false

local PROGRESS_PATTERN = "(%d+)%s*/%s*(%d+)"
local scanning = false

local function ParseObjective(text, finished)
    local have, need = nil, nil
    if text then
        local a, b = text:match(PROGRESS_PATTERN)
        have, need = tonumber(a), tonumber(b)
    end
    if not have or not need then
        have = finished and 1 or 0
        need = 1
    end
    return have, need
end

local function ObjectiveName(text)
    if not text then return "" end
    local name = text:gsub("%s*%d+%s*/%s*%d+%s*$", "")
    name = name:gsub("[:%s]+$", "")
    return NS.Trim(name)
end

function Quests:Scan()
    if scanning then return nil end
    scanning = true

    local collapsed = {}
    local total = GetNumQuestLogEntries() or 0
    local logOpen = QuestLogFrame and QuestLogFrame:IsShown()
    if not logOpen then
        for index = total, 1, -1 do
            local _, _, _, _, isHeader, isCollapsed = GetQuestLogTitle(index)
            if isHeader and isCollapsed then
                collapsed[#collapsed + 1] = index
                ExpandQuestHeader(index)
            end
        end
    end

    local snapshot = {}
    total = GetNumQuestLogEntries() or 0
    for index = 1, total do
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(index)
        if title and not isHeader and questID and questID > 0 then
            local quest = {
                id = questID,
                title = title,
                level = level or 0,
                complete = isComplete == 1,
                failed = isComplete == -1,
                daily = isDaily and true or false,
                objectives = {},
            }

            local numObjectives = GetNumQuestLeaderBoards(index) or 0
            for objIndex = 1, numObjectives do
                local text, objType, finished = GetQuestLogLeaderBoard(objIndex, index)
                if text then
                    local have, need = ParseObjective(text, finished)
                    quest.objectives[objIndex] = {
                        name = ObjectiveName(text),
                        text = text,
                        have = have,
                        need = need,
                        finished = finished and true or false,
                    }
                end
            end

            if numObjectives == 0 and quest.complete then
                quest.objectives[1] = { name = title, text = title, have = 1, need = 1, finished = true }
            end

            snapshot[questID] = quest
        end
    end

    for index = #collapsed, 1, -1 do
        CollapseQuestHeader(collapsed[index])
    end

    scanning = false
    return snapshot
end

local function CopyQuest(quest)
    local copy = {
        id = quest.id,
        title = quest.title,
        level = quest.level,
        complete = quest.complete,
        failed = quest.failed,
        daily = quest.daily,
        objectives = {},
    }
    for index, objective in ipairs(quest.objectives) do
        copy.objectives[index] = {
            name = objective.name,
            text = objective.text,
            have = objective.have,
            need = objective.need,
            finished = objective.finished,
        }
    end
    return copy
end

function Quests:AllComplete(quest)
    if quest.complete then return true end
    if #quest.objectives == 0 then return false end
    for _, objective in ipairs(quest.objectives) do
        if not objective.finished and objective.have < objective.need then return false end
    end
    return true
end

function Quests:Refresh()
    local snapshot = self:Scan()
    if not snapshot then return nil end

    local events = {}
    local first = not self.ready

    for questID, quest in pairs(snapshot) do
        local previous = self.own[questID]
        if not previous then
            if not first then
                events[#events + 1] = { type = "accept", quest = quest }
            end
        else
            for objIndex, objective in ipairs(quest.objectives) do
                local before = previous.objectives[objIndex]
                if before and objective.have > before.have then
                    if objective.finished or objective.have >= objective.need then
                        events[#events + 1] = { type = "objdone", quest = quest, objIndex = objIndex }
                    else
                        events[#events + 1] = { type = "progress", quest = quest, objIndex = objIndex }
                    end
                end
            end
            if quest.failed and not previous.failed then
                events[#events + 1] = { type = "fail", quest = quest }
            elseif self:AllComplete(quest) and not self:AllComplete(previous) then
                events[#events + 1] = { type = "complete", quest = quest }
            end
        end
    end

    for questID, previous in pairs(self.own) do
        if not snapshot[questID] then
            local kind = (previous.complete or self:AllComplete(previous)) and "turnin" or "abandon"
            if not first then
                events[#events + 1] = { type = kind, quest = previous }
            end
        end
    end

    self.own = {}
    for questID, quest in pairs(snapshot) do
        self.own[questID] = CopyQuest(quest)
    end
    self.ready = true

    return events, first
end

function Quests:Count()
    local count = 0
    for _ in pairs(self.own) do count = count + 1 end
    return count
end

function Quests:Get(questID)
    return self.own[questID]
end
