local addonName, NS = ...

local Window = {}
NS.QuestLog = Window

local WIDTH = 1040
local HEIGHT = 760
local LEFT_WIDTH = 320
local LIST_ROW = 22
local HEADER_ROW = 20

NS.Densify("NarcissusSirus_QuestLog", function(f)
    LIST_ROW = math.max(14, math.floor(22 * f + 0.5))
    HEADER_ROW = math.max(14, math.floor(20 * f + 0.5))
end)
local TOP = 54
local BOTTOM = 40

local frame
local listRows = {}
local textLines = {}
local selectedID
local currentView = "text"

local function S()
    return NS.QuestStyle
end

local function DifficultyColor(level)
    if GetQuestDifficultyColor and level and level > 0 then
        local color = GetQuestDifficultyColor(level)
        if color then return color.r, color.g, color.b end
    end
    local st = S()
    return st.TEXT[1], st.TEXT[2], st.TEXT[3]
end

local function QuestProgress(quest)
    if quest.complete then return 1 end
    local total, done = 0, 0
    for _, objective in ipairs(quest.objectives) do
        local need = objective.need > 0 and objective.need or 1
        total = total + need
        done = done + (objective.finished and need or math.min(objective.have, need))
    end
    if total == 0 then return 0 end
    return done / total
end

local function PeersWithQuest(questID)
    local list = {}
    for name, peer in pairs(NS.QuestComm.peers) do
        if peer.quests[questID] then
            list[#list + 1] = { name = name, quest = peer.quests[questID] }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local function PartyMembersOnQuest(index)
    local names = {}
    if not IsUnitOnQuest then return names end
    local count = GetNumPartyMembers() or 0
    for i = 1, count do
        local unit = "party" .. i
        local ok, result = pcall(IsUnitOnQuest, index, unit)
        if ok and result then names[#names + 1] = UnitName(unit) end
    end
    return names
end

local function TagText(entry)
    local parts = {}
    if entry.tag and entry.tag ~= "" then parts[#parts + 1] = entry.tag end
    if entry.daily then parts[#parts + 1] = "ежедн." end
    if #parts == 0 then return "" end
    return "(" .. table.concat(parts, ", ") .. ")"
end

function Window:BuildEntries()
    local entries = {}
    local total = GetNumQuestLogEntries() or 0
    local currentHeader

    for index = 1, total do
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(index)
        if title then
            if isHeader then
                currentHeader = title
                entries[#entries + 1] = { header = title }
            elseif questID and questID > 0 then
                entries[#entries + 1] = {
                    index = index,
                    id = questID,
                    title = title,
                    level = level or 0,
                    tag = questTag,
                    daily = isDaily and true or false,
                    complete = isComplete == 1,
                    failed = isComplete == -1,
                    zone = currentHeader,
                }
            end
        end
    end

    return entries
end

function Window:IndexForQuest(questID)
    local total = GetNumQuestLogEntries() or 0
    for index = 1, total do
        local _, _, _, _, isHeader, _, _, _, id = GetQuestLogTitle(index)
        if not isHeader and id == questID then return index end
    end
    return nil
end

local function GetListRow(index)
    local row = listRows[index]
    if row then return row end
    local st = S()

    row = CreateFrame("Button", nil, frame.listChild)
    row:SetWidth(LEFT_WIDTH - 26)
    row:SetHeight(LIST_ROW)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(st.WHITE)
    row.bg:SetVertexColor(0, 0, 0, 0)

    row.title = st.Label(row, 11)
    row.title:SetPoint("LEFT", row, "LEFT", 12, 0)

    row.tag = st.Label(row, 10)
    row.tag:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.tag:SetJustifyH("RIGHT")
    row.tag:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])

    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetWidth(12)
    row.check:SetHeight(12)
    row.check:SetPoint("RIGHT", row.tag, "LEFT", -4, 0)
    row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    row.check:Hide()

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(st.WHITE)
    row.highlight:SetVertexColor(1, 1, 1, 0.06)

    row:SetScript("OnClick", function(self)
        if self.questID then
            selectedID = self.questID
            Window:Refresh()
        end
    end)

    listRows[index] = row
    return row
end

function Window:RefreshList()
    local st = S()
    local entries = self:BuildEntries()
    local offset = 0
    local hasSelection = false

    for _, entry in ipairs(entries) do
        if entry.id == selectedID then hasSelection = true end
    end
    if not hasSelection then
        selectedID = nil
        for _, entry in ipairs(entries) do
            if entry.id then
                selectedID = entry.id
                break
            end
        end
    end

    for index = 1, math.max(#entries, #listRows) do
        local row = listRows[index]
        if index <= #entries and not row then row = GetListRow(index) end
        if not row then break end

        if index > #entries then
            row:Hide()
        else
            local entry = entries[index]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", frame.listChild, "TOPLEFT", 0, -offset)
            row.questID = entry.id
            row.title:ClearAllPoints()

            if entry.header then
                row:SetHeight(HEADER_ROW)
                row.title:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.title:SetText(entry.header)
                row.title:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
                row.tag:SetText("")
                row.check:Hide()
                row.bg:SetVertexColor(0, 0, 0, 0)
                row.title:SetWidth(LEFT_WIDTH - 40)
                offset = offset + HEADER_ROW
            else
                row:SetHeight(LIST_ROW)
                row.title:SetPoint("LEFT", row, "LEFT", 12, 0)
                row.title:SetText(entry.title)

                local r, g, b = DifficultyColor(entry.level)
                if entry.failed then r, g, b = st.RED[1], st.RED[2], st.RED[3] end
                row.title:SetTextColor(r, g, b)

                local peers = PeersWithQuest(entry.id)
                local tag = TagText(entry)
                if #peers > 0 then
                    tag = tag .. " |cff00ae7a+" .. #peers .. "|r"
                end
                row.tag:SetText(tag)

                if entry.complete then row.check:Show() else row.check:Hide() end

                if entry.id == selectedID then
                    row.bg:SetVertexColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3], 0.16)
                else
                    row.bg:SetVertexColor(0, 0, 0, 0)
                end

                local reserved = math.max(row.tag:GetStringWidth() + 24, 44)
                row.title:SetWidth(math.max(LEFT_WIDTH - 26 - 12 - reserved, 60))
                offset = offset + LIST_ROW
            end

            row:Show()
        end
    end

    frame.listChild:SetHeight(math.max(offset, 1))

    local _, numQuests = GetNumQuestLogEntries()
    frame.title:SetText(string.format("Задания: %d/%d", numQuests or 0, MAX_QUESTLOG_QUESTS or 25))
end

local function GetRewardButton(panel, index)
    local button = panel.buttons[index]
    if button then return button end
    local st = S()

    button = CreateFrame("Button", nil, panel)
    button:SetWidth(36)
    button:SetHeight(36)

    local backdrop = button:CreateTexture(nil, "BACKGROUND")
    backdrop:SetAllPoints()
    backdrop:SetTexture(st.WHITE)
    backdrop:SetVertexColor(0, 0, 0, 0.6)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.border = CreateFrame("Frame", nil, button)
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    button.border:SetBackdrop({ edgeFile = st.WHITE, edgeSize = 1 })
    button.border:SetBackdropBorderColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], 1)
    button.border:EnableMouse(false)

    button.count = st.Label(button, 10, "OUTLINE")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.count:SetJustifyH("RIGHT")

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button.icon)
    highlight:SetTexture(st.WHITE)
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(1, 1, 1, 0.15)

    button:SetScript("OnEnter", function(self)
        if not self.rewardType or not self.rewardIndex then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local ok = pcall(GameTooltip.SetQuestLogItem, GameTooltip, self.rewardType, self.rewardIndex)
        if not ok then GameTooltip:SetText(self.rewardName or "") end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    panel.buttons[index] = button
    return button
end

local function CreateRewardPanel(parent, width)
    local st = S()
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(width)
    panel:SetHeight(1)
    panel.buttons = {}

    panel.header = st.Label(panel, 12)
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.header:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
    panel.header:SetText("Награда")

    panel.money = st.Label(panel, 12)
    panel.money:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -18)
    panel.money:SetTextColor(st.GOLD[1], st.GOLD[2], st.GOLD[3])

    panel.choiceLabel = st.Label(panel, 10)
    panel.choiceLabel:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])

    panel.rewardLabel = st.Label(panel, 10)
    panel.rewardLabel:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])

    panel.empty = st.Label(panel, 11)
    panel.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -20)
    panel.empty:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])

    return panel
end

local function SetRewardButton(button, rewardType, rewardIndex, name, texture, count, quality)
    button.rewardType = rewardType
    button.rewardIndex = rewardIndex
    button.rewardName = name
    button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.count:SetText((count and count > 1) and tostring(count) or "")

    local color = quality and quality >= 2 and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color then
        button.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
    else
        local st = S()
        button.border:SetBackdropBorderColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], 1)
    end
    button:Show()
end

local function UpdateRewardPanel(panel, questIndex)
    SelectQuestLogEntry(questIndex)

    local money = GetQuestLogRewardMoney() or 0
    local numChoices = GetNumQuestLogChoices() or 0
    local numRewards = GetNumQuestLogRewards() or 0

    local perRow = math.max(1, math.floor(panel:GetWidth() / 42))
    local used = 0
    local offset = 20

    if money > 0 then
        local text = GetCoinTextureString and GetCoinTextureString(money) or tostring(money)
        panel.money:ClearAllPoints()
        panel.money:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -offset)
        panel.money:SetText("деньги: " .. text)
        panel.money:Show()
        offset = offset + 18
    else
        panel.money:Hide()
    end

    panel.choiceLabel:Hide()
    panel.rewardLabel:Hide()
    panel.empty:Hide()

    if numChoices > 0 then
        panel.choiceLabel:ClearAllPoints()
        panel.choiceLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -offset)
        panel.choiceLabel:SetText("на выбор:")
        panel.choiceLabel:Show()
        offset = offset + 14

        for index = 1, numChoices do
            local name, texture, count, quality = GetQuestLogChoiceInfo(index)
            used = used + 1
            local button = GetRewardButton(panel, used)
            SetRewardButton(button, "choice", index, name, texture, count, quality)
            local column = math.fmod(index - 1, perRow)
            local row = math.floor((index - 1) / perRow)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", panel, "TOPLEFT", column * 42, -(offset + row * 42))
        end
        offset = offset + math.ceil(numChoices / perRow) * 42 + 4
    end

    if numRewards > 0 then
        panel.rewardLabel:ClearAllPoints()
        panel.rewardLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -offset)
        panel.rewardLabel:SetText("вы получите:")
        panel.rewardLabel:Show()
        offset = offset + 14

        for index = 1, numRewards do
            local name, texture, count, quality = GetQuestLogRewardInfo(index)
            used = used + 1
            local button = GetRewardButton(panel, used)
            SetRewardButton(button, "reward", index, name, texture, count, quality)
            local column = math.fmod(index - 1, perRow)
            local row = math.floor((index - 1) / perRow)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", panel, "TOPLEFT", column * 42, -(offset + row * 42))
        end
        offset = offset + math.ceil(numRewards / perRow) * 42 + 4
    end

    if numChoices == 0 and numRewards == 0 then
        if money == 0 then
            panel.empty:ClearAllPoints()
            panel.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -offset)
            panel.empty:SetText("без награды")
            panel.empty:Show()
            offset = offset + 18
        end
    end

    for index = used + 1, #panel.buttons do
        panel.buttons[index]:Hide()
    end

    panel:SetHeight(math.max(offset, 20))
    return offset
end

local function TextLine(index)
    local line = textLines[index]
    if line then return line end
    local st = S()
    line = st.Label(frame.textChild, 11)
    line:SetJustifyV("TOP")
    textLines[index] = line
    return line
end

local function AddLine(state, text, size, r, g, b, gap)
    local st = S()
    state.count = state.count + 1
    local line = TextLine(state.count)
    line:SetFont(st.FONT, NS.FS(size or 11), "")
    line:SetText(text)
    line:SetTextColor(r or st.TEXT[1], g or st.TEXT[2], b or st.TEXT[3])
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", frame.textChild, "TOPLEFT", 4, -(state.offset + (gap or 0)))
    line:SetPoint("TOPRIGHT", frame.textChild, "TOPRIGHT", -4, -(state.offset + (gap or 0)))
    line:Show()
    state.offset = state.offset + (gap or 0) + math.max(line:GetStringHeight() or 0, size or 11) + 4
end

local function FinishText(state)
    for index = state.count + 1, #textLines do
        textLines[index]:Hide()
    end
    frame.textChild:SetHeight(math.max(state.offset, 1))
end

function Window:RefreshText(entry)
    local st = S()
    local state = { count = 0, offset = 0 }

    SelectQuestLogEntry(entry.index)

    local description, objectivesText = GetQuestLogQuestText()

    AddLine(state, "Цели", 12, st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])

    if objectivesText and objectivesText ~= "" then
        AddLine(state, objectivesText, 11, 0.78, 0.78, 0.82)
    end

    local peers = PeersWithQuest(entry.id)
    local numObjectives = GetNumQuestLeaderBoards(entry.index) or 0

    for objIndex = 1, numObjectives do
        local text, _, finished = GetQuestLogLeaderBoard(objIndex, entry.index)
        if text then
            local r, g, b = st.TEXT[1], st.TEXT[2], st.TEXT[3]
            if finished then r, g, b = st.GOLD[1], st.GOLD[2], st.GOLD[3] end
            AddLine(state, "- " .. text, 11, r, g, b, 2)

            for _, peerEntry in ipairs(peers) do
                local peerObjective = peerEntry.quest.objectives[objIndex]
                if peerObjective then
                    local line
                    if peerObjective.need > 1 then
                        line = string.format("     %s: %d/%d", peerEntry.name, peerObjective.have, peerObjective.need)
                    else
                        line = string.format("     %s: %s", peerEntry.name, peerObjective.finished and "готово" or "нет")
                    end
                    AddLine(state, line, 10, st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
                end
            end
        end
    end

    if entry.complete then
        AddLine(state, "Задание можно сдать", 11, st.GOLD[1], st.GOLD[2], st.GOLD[3], 4)
    end

    local timeLeft = GetQuestLogTimeLeft and GetQuestLogTimeLeft()
    if timeLeft and SecondsToTime then
        AddLine(state, "Осталось времени: " .. SecondsToTime(timeLeft), 10,
            st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    end

    local partyNames = PartyMembersOnQuest(entry.index)
    if #partyNames > 0 then
        AddLine(state, "В группе делают: " .. table.concat(partyNames, ", "), 10,
            st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3], 2)
    end

    if description and description ~= "" then
        AddLine(state, "Описание", 12, st.ACCENT[1], st.ACCENT[2], st.ACCENT[3], 10)
        AddLine(state, description, 11, 0.78, 0.78, 0.82)
    end

    state.offset = state.offset + 10
    frame.textRewards:ClearAllPoints()
    frame.textRewards:SetPoint("TOPLEFT", frame.textChild, "TOPLEFT", 4, -state.offset)
    frame.textRewards:SetWidth(frame.textChild:GetWidth() - 12)
    local rewardHeight = UpdateRewardPanel(frame.textRewards, entry.index)
    frame.textRewards:Show()
    state.offset = state.offset + rewardHeight + 8

    FinishText(state)
end

function Window:RefreshGroup()
    local st = S()
    local state = { count = 0, offset = 0 }
    local names = {}

    frame.textRewards:Hide()

    for name in pairs(NS.QuestComm.peers) do names[#names + 1] = name end
    table.sort(names)

    if #names == 0 then
        AddLine(state, "Рядом нет игроков с NarciUI", 11, st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    end

    for _, name in ipairs(names) do
        local peer = NS.QuestComm.peers[name]
        local quests = {}
        for _, quest in pairs(peer.quests) do quests[#quests + 1] = quest end
        table.sort(quests, function(a, b) return a.title < b.title end)

        AddLine(state, string.format("%s (%d)", name, #quests), 12,
            st.ACCENT[1], st.ACCENT[2], st.ACCENT[3], 8)

        for _, quest in ipairs(quests) do
            local ratio = QuestProgress(quest)
            local mine = NS.QuestData:Get(quest.id) and " |cff00ae7a(есть и у вас)|r" or ""
            local r, g, b = st.TEXT[1], st.TEXT[2], st.TEXT[3]
            if quest.complete then r, g, b = st.GOLD[1], st.GOLD[2], st.GOLD[3] end
            AddLine(state, string.format("%s - %d%%%s", quest.title,
                math.floor(ratio * 100 + 0.5), mine), 11, r, g, b)
        end
    end

    FinishText(state)
end

function Window:RefreshMap(entry)
    local map = frame.map

    map:SelectQuest(entry.id)
    map:ShowQuest(entry.id)

    frame.mapZone:SetText(map.areaName or "")

    local hasPin = false
    for index = 1, #map.pins do
        local pin = map.pins[index]
        if pin:IsShown() and pin.questID == entry.id then hasPin = true break end
    end

    if hasPin then
        frame.mapLegend:SetText("изумруд - ваша цель, золото - можно сдать, серые - другие")
    else
        frame.mapLegend:SetText("у этого задания нет точки на карте")
    end

    local lines = {}
    local numObjectives = GetNumQuestLeaderBoards(entry.index) or 0
    for objIndex = 1, numObjectives do
        local text, _, finished = GetQuestLogLeaderBoard(objIndex, entry.index)
        if text then
            if finished then
                lines[#lines + 1] = "|cff40c060- " .. text .. "|r"
            else
                lines[#lines + 1] = "- " .. text
            end
        end
    end

    if #lines == 0 then
        SelectQuestLogEntry(entry.index)
        local _, objectivesText = GetQuestLogQuestText()
        if objectivesText and objectivesText ~= "" then lines[1] = objectivesText end
    end

    if entry.complete then
        lines[#lines + 1] = "|cffffd200задание можно сдать|r"
    end

    frame.mapObjectives:SetText(#lines > 0 and table.concat(lines, "\n") or "у этого задания нет отдельных целей")

    local objectivesHeight = (frame.mapObjectives:GetStringHeight() or 12) + 22
    local rewardHeight = UpdateRewardPanel(frame.mapRewards, entry.index)

    frame.mapContent:SetHeight(objectivesHeight + 12 + rewardHeight + 8)
    frame.mapScroll:Show()
end

local function SetView(view)
    currentView = view
    local st = S()
    for key, button in pairs(frame.viewButtons) do
        if key == view then
            button:SetBackdropColor(NS.Styling.Tint(0.09, 0.11, 0.15, 0.95))
            button.label:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
        else
            button:SetBackdropColor(NS.Styling.Tint(0.05, 0.06, 0.09, 0.9))
            button.label:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
        end
    end
    Window:Refresh()
end

function Window:Refresh()
    if not frame or not frame:IsShown() then return end
    local st = S()

    self:RefreshList()

    local entry
    if selectedID then
        local index = self:IndexForQuest(selectedID)
        if index then
            local title, level, questTag, _, _, _, isComplete, isDaily, questID = GetQuestLogTitle(index)
            entry = {
                index = index,
                id = questID,
                title = title,
                level = level or 0,
                tag = questTag,
                daily = isDaily and true or false,
                complete = isComplete == 1,
                failed = isComplete == -1,
            }
        end
    end

    if not entry then
        frame.questTitle:SetText("Задание не выбрано")
        frame.questSub:SetText("")
        frame.map:Hide()
        frame.mapScroll:Hide()
        frame.textRewards:Hide()
        frame.textScroll:Show()
        if currentView == "group" then
            self:RefreshGroup()
        else
            local state = { count = 0, offset = 0 }
            FinishText(state)
        end
        return
    end

    frame.questTitle:SetText(entry.title)

    local subParts = {}
    if entry.level > 0 then subParts[#subParts + 1] = "уровень " .. entry.level end
    local tag = TagText(entry)
    if tag ~= "" then subParts[#subParts + 1] = tag end
    local peers = PeersWithQuest(entry.id)
    if #peers > 0 then subParts[#subParts + 1] = "делают ещё: " .. #peers end
    frame.questSub:SetText(table.concat(subParts, "    "))

    if currentView == "map" then
        frame.textScroll:Hide()
        frame.map:Show()
        self:RefreshMap(entry)
    elseif currentView == "group" then
        frame.map:Hide()
        frame.mapScroll:Hide()
        frame.textScroll:Show()
        self:RefreshGroup()
    else
        frame.map:Hide()
        frame.mapScroll:Hide()
        frame.textScroll:Show()
        self:RefreshText(entry)
    end

    local watched = IsQuestWatched and IsQuestWatched(entry.index)
    frame.watchButton.label:SetText(watched and "Не следить" or "Отслеживать")

    SelectQuestLogEntry(entry.index)
    local pushable = GetQuestLogPushable and GetQuestLogPushable()
    if pushable and (NS.InParty() or NS.InRaid()) then
        frame.shareButton:Enable()
        frame.shareButton.label:SetTextColor(st.TEXT[1], st.TEXT[2], st.TEXT[3])
    else
        frame.shareButton:Disable()
        frame.shareButton.label:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    end
end

function Window:Create()
    if frame then return frame end
    local st = S()

    frame = CreateFrame("Frame", "NarcissusSirus_QuestLog", UIParent)
    NS.Styling.WindowSounds(frame, "igQuestLogOpen", "igQuestLogClose")
    frame:SetWidth(WIDTH)
    frame:SetHeight(HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    st.Backdrop(frame, st.BG[1], st.BG[2], st.BG[3], st.BG[4])
    NS.Styling.RoundCorners(frame)
    tinsert(UISpecialFrames, "NarcissusSirus_QuestLog")

    local title = st.Label(frame, 15, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    title:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
    frame.title = title

    local close = st.Button(frame, "X", 22, 20)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 12 + LEFT_WIDTH, -TOP)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12 + LEFT_WIDTH, BOTTOM)
    divider:SetTexture(st.WHITE)
    divider:SetVertexColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], 0.8)

    local listScroll = CreateFrame("ScrollFrame", "NarcissusSirus_QuestListScroll", frame, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -TOP)
    listScroll:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, BOTTOM)
    listScroll:SetWidth(LEFT_WIDTH - 24)

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetWidth(LEFT_WIDTH - 26)
    listChild:SetHeight(1)
    listScroll:SetScrollChild(listChild)
    frame.listChild = listChild

    local questTitle = st.Label(frame, 14, "OUTLINE")
    questTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 24 + LEFT_WIDTH, -TOP + 4)
    questTitle:SetWidth(WIDTH - LEFT_WIDTH - 240)
    questTitle:SetTextColor(st.GOLD[1], st.GOLD[2], st.GOLD[3])
    frame.questTitle = questTitle

    local questSub = st.Label(frame, 10)
    questSub:SetPoint("TOPLEFT", questTitle, "BOTTOMLEFT", 0, -5)
    questSub:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    frame.questSub = questSub

    frame.viewButtons = {}
    local views = {
        { key = "text", caption = "Текст" },
        { key = "map", caption = "Карта" },
        { key = "group", caption = "Группа" },
    }
    for index, view in ipairs(views) do
        local button = st.Button(frame, view.caption, 64, 20)
        button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14 - (3 - index) * 68, -TOP + 2)
        button:SetScript("OnClick", function() SetView(view.key) end)
        frame.viewButtons[view.key] = button
    end

    local contentTop = TOP + 48

    local textScroll = CreateFrame("ScrollFrame", "NarcissusSirus_QuestTextScroll", frame, "UIPanelScrollFrameTemplate")
    textScroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 22 + LEFT_WIDTH, -contentTop)
    textScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, BOTTOM)
    frame.textScroll = textScroll

    local textChild = CreateFrame("Frame", nil, textScroll)
    textChild:SetWidth(WIDTH - LEFT_WIDTH - 66)
    textChild:SetHeight(1)
    textScroll:SetScrollChild(textChild)
    frame.textChild = textChild

    frame.textRewards = CreateRewardPanel(textChild, WIDTH - LEFT_WIDTH - 78)
    frame.textRewards:Hide()

    local mapWidth = WIDTH - LEFT_WIDTH - 52
    local map = NS.MapCanvas:Create(frame, "NarcissusSirus_QuestMapCanvas")
    map:SetPoint("TOPLEFT", frame, "TOPLEFT", 22 + LEFT_WIDTH, -contentTop)
    map:SetAspectWidth(mapWidth)
    map.onQuestClick = function(questID) Window:Select(questID) end
    map.onClick = function()
        if selectedID and WorldMap_OpenToQuest then
            WorldMap_OpenToQuest(selectedID)
        elseif WorldMapFrame then
            ToggleFrame(WorldMapFrame)
        end
    end
    map:Hide()
    frame.map = map

    local mapZone = st.Label(frame, 12, "OUTLINE")
    mapZone:SetPoint("TOPLEFT", map, "TOPLEFT", 8, -6)
    mapZone:SetTextColor(1, 1, 1)
    frame.mapZone = mapZone

    local mapZonePlate = map:CreateTexture(nil, "OVERLAY")
    mapZonePlate:SetPoint("TOPLEFT", map, "TOPLEFT", 0, 0)
    mapZonePlate:SetPoint("TOPRIGHT", map, "TOPRIGHT", 0, 0)
    mapZonePlate:SetHeight(22)
    mapZonePlate:SetTexture(st.WHITE)
    mapZonePlate:SetVertexColor(0, 0, 0, 0.55)

    local mapLegend = st.Label(frame, 10)
    mapLegend:SetPoint("TOPLEFT", map, "BOTTOMLEFT", 2, -4)
    mapLegend:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    frame.mapLegend = mapLegend

    local mapHint = st.Label(frame, 10)
    mapHint:SetPoint("TOPRIGHT", map, "BOTTOMRIGHT", -2, -4)
    mapHint:SetJustifyH("RIGHT")
    mapHint:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    frame.mapHint = mapHint

    map.onCoords = function(x, y)
        if x and y then
            frame.mapHint:SetText(string.format("игрок  %.1f, %.1f", x * 100, y * 100))
        else
            frame.mapHint:SetText("")
        end
    end

    local mapScroll = CreateFrame("ScrollFrame", "NarcissusSirus_QuestMapScroll", frame, "UIPanelScrollFrameTemplate")
    mapScroll:SetPoint("TOPLEFT", map, "BOTTOMLEFT", 0, -22)
    mapScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, BOTTOM)
    mapScroll:Hide()
    frame.mapScroll = mapScroll

    local mapContent = CreateFrame("Frame", nil, mapScroll)
    mapContent:SetWidth(mapWidth - 14)
    mapContent:SetHeight(1)
    mapScroll:SetScrollChild(mapContent)
    frame.mapContent = mapContent

    local objectivesTitle = st.Label(mapContent, 12)
    objectivesTitle:SetPoint("TOPLEFT", mapContent, "TOPLEFT", 0, 0)
    objectivesTitle:SetTextColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3])
    objectivesTitle:SetText("Что нужно сделать")
    frame.mapObjectivesTitle = objectivesTitle

    local objectives = st.Label(mapContent, 11)
    objectives:SetPoint("TOPLEFT", objectivesTitle, "BOTTOMLEFT", 0, -4)
    objectives:SetWidth(mapWidth - 14)
    objectives:SetJustifyV("TOP")
    frame.mapObjectives = objectives

    frame.mapRewards = CreateRewardPanel(mapContent, mapWidth - 14)
    frame.mapRewards:SetPoint("TOPLEFT", objectives, "BOTTOMLEFT", 0, -12)

    local watch = st.Button(frame, "Отслеживать", 110, 22)
    watch:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
    watch:SetScript("OnClick", function()
        if not selectedID then return end
        local index = Window:IndexForQuest(selectedID)
        if not index then return end
        if IsQuestWatched(index) then
            RemoveQuestWatch(index)
        else
            AddQuestWatch(index)
        end
        if WatchFrame_Update then WatchFrame_Update() end
        Window:Refresh()
    end)
    frame.watchButton = watch

    local share = st.Button(frame, "Предложить", 110, 22)
    share:SetPoint("BOTTOMLEFT", watch, "BOTTOMRIGHT", 8, 0)
    share:SetScript("OnClick", function()
        if not selectedID then return end
        local index = Window:IndexForQuest(selectedID)
        if not index then return end
        SelectQuestLogEntry(index)
        QuestLogPushQuest()
    end)
    frame.shareButton = share

    local abandon = st.Button(frame, "Отменить", 100, 22)
    abandon:SetPoint("BOTTOMLEFT", share, "BOTTOMRIGHT", 8, 0)
    abandon:SetScript("OnClick", function()
        if not selectedID then return end
        local index = Window:IndexForQuest(selectedID)
        if not index then return end
        local questTitle = GetQuestLogTitle(index)
        local dialog = StaticPopup_Show("NARCISSUSSIRUS_ABANDON_QUEST", questTitle)
        if dialog then dialog.data = index end
    end)

    local options = st.Button(frame, "Настройки", 100, 22)
    options:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -122, 10)
    options:SetScript("OnClick", function()
        if NS.QuestOptions then NS.QuestOptions:Toggle() end
    end)

    local closeBottom = st.Button(frame, "Закрыть", 100, 22)
    closeBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 10)
    closeBottom:SetScript("OnClick", function() frame:Hide() end)

    frame:SetScript("OnShow", function() Window:Refresh() end)
    frame:Hide()

    SetView("text")
    return frame
end

function Window:OverlayStats()
    local map = frame and frame.map
    if not map or not map.overlays then return 0, 0 end
    local drawn, hidden = 0, 0
    for index = 1, #map.overlays do
        if map.overlays[index]:IsShown() then drawn = drawn + 1 else hidden = hidden + 1 end
    end
    return drawn, hidden
end

function Window:Show()
    self:Create()
    frame:Show()
    self:Refresh()
end

function Window:HideWindow()
    if frame then frame:Hide() end
end

function Window:IsShown()
    return frame and frame:IsShown()
end

function Window:Toggle()
    self:Create()
    if frame:IsShown() then
        frame:Hide()
    else
        self:Show()
    end
end

function Window:Select(questID)
    selectedID = questID
    self:Refresh()
end

StaticPopupDialogs["NARCISSUSSIRUS_ABANDON_QUEST"] = {
    text = "Отменить задание \"%s\"?",
    button1 = YES or "Да",
    button2 = NO or "Нет",
    OnAccept = function(self)
        local index = self and self.data
        if not index then return end
        SelectQuestLogEntry(index)
        SetAbandonQuest()
        AbandonQuest()
        if NS.QuestLog then NS.QuestLog:Refresh() end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}
