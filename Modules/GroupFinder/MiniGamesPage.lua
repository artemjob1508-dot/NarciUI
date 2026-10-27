local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local TILE = 54
local MAX_TILES = 8
local MAX_REWARDS = 6

local function Games()
    local games = {}
    if not C_MiniGames or not C_MiniGames.GetNumGames then return games end

    local total = C_MiniGames.GetNumGames() or 0
    for index = 1, total do
        local id = C_MiniGames.GetGameIDFromIndex(index)
        if id then games[#games + 1] = id end
    end

    return games
end

function Page:QueueIndexFor(miniGameID)
    if not C_MiniGames or not C_MiniGames.GetMaxQueues then return nil end

    for index = 1, C_MiniGames.GetMaxQueues() or 0 do
        local status, _, id = C_MiniGames.GetQueueInfo(index)
        if status == "queued" and id == miniGameID then return index end
    end

    return nil
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome
    local Caption = panel.Caption
    local contentX, contentW, listTop, listBottom, pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", contentX, -72)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    local gamesCaption = Caption(f, L["ИГРЫ"])
    gamesCaption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.gamesRule = S.CreateSectionRule(f, gamesCaption, contentW)

    f.tiles = {}
    for index = 1, MAX_TILES do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(TILE, TILE)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", (index - 1) * (TILE + 8), -18)
        Chrome(button)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 3)
        bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.15)

        button:SetScript("OnClick", function(self)
            Page.selected = self.gameID
            Page:Update()
        end)

        button:SetScript("OnEnter", function(self)
            if not self.gameName then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.gameName, 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button:Hide()
        f.tiles[index] = button
    end

    local detail = CreateFrame("Frame", nil, f)
    detail:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -18 - TILE - 16)
    detail:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 44)
    Chrome(detail)
    f.detail = detail

    local title = detail:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(15), "OUTLINE")
    title:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    title:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -14)
    title:SetWidth(contentW - 200)
    title:SetJustifyH("LEFT")
    f.title = title

    local meta = detail:CreateFontString(nil, "OVERLAY")
    meta:SetFont(NS.FONT, NS.FS(11), "")
    meta:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    f.meta = meta

    local description = detail:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    description:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -10)
    description:SetWidth(contentW - 40)
    description:SetJustifyH("LEFT")
    f.description = description

    local objectiveCaption = Caption(detail, L["ЗАДАЧА"])
    objectiveCaption:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -16)
    f.objectiveCaption = objectiveCaption
    f.objectiveRule = S.CreateSectionRule(detail, objectiveCaption, contentW - 40)

    local objective = detail:CreateFontString(nil, "OVERLAY")
    objective:SetFont(NS.FONT, NS.FS(11), "")
    objective:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    objective:SetPoint("TOPLEFT", objectiveCaption, "BOTTOMLEFT", 0, -12)
    objective:SetWidth(contentW - 40)
    objective:SetJustifyH("LEFT")
    f.objective = objective

    local rewardCaption = Caption(detail, LFD_REWARDS or L["Награды"])
    rewardCaption:SetPoint("TOPLEFT", objective, "BOTTOMLEFT", 0, -16)
    f.rewardCaption = rewardCaption
    f.rewardRule = S.CreateSectionRule(detail, rewardCaption, contentW - 40)

    f.rewards = {}
    for index = 1, MAX_REWARDS do
        local button = CreateFrame("Button", nil, detail)
        button:SetSize(42, 42)

        if index == 1 then
            button:SetPoint("TOPLEFT", rewardCaption, "BOTTOMLEFT", 0, -14)
        else
            button:SetPoint("LEFT", f.rewards[index - 1], "RIGHT", 10, 0)
        end

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        local count = button:CreateFontString(nil, "OVERLAY")
        count:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.count = count

        button:SetScript("OnEnter", function(self)
            if not self.itemID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if not pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.itemID) then
                GameTooltip:AddLine(self.itemName or "", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button:Hide()
        f.rewards[index] = button
    end

    local rewardText = detail:CreateFontString(nil, "OVERLAY")
    rewardText:SetFont(NS.FONT, NS.FS(11), "")
    rewardText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    rewardText:SetPoint("TOPLEFT", f.rewards[1], "BOTTOMLEFT", 0, -12)
    rewardText:SetWidth(contentW - 40)
    rewardText:SetJustifyH("LEFT")
    f.rewardText = rewardText

    local empty = detail:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -16)
    empty:SetWidth(contentW - 40)
    empty:SetJustifyH("LEFT")
    empty:Hide()
    f.empty = empty

    local status = f:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 8)
    status:SetWidth(contentW - 230)
    status:SetJustifyH("LEFT")
    f.status = status

    local join = CreateFrame("Button", nil, f)
    join:SetSize(210, 30)
    join:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    local joinBg = join:CreateTexture(nil, "BACKGROUND")
    joinBg:SetAllPoints()
    joinBg:SetTexture(WHITE)
    joinBg:SetGradientAlpha("VERTICAL",
        S.ACCENT[1] * 0.35, S.ACCENT[2] * 0.35, S.ACCENT[3] * 0.35, 0.95,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    local joinBorder = CreateFrame("Frame", nil, join)
    joinBorder:SetPoint("TOPLEFT", -1, 1)
    joinBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    joinBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    joinBorder:SetBackdropBorderColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    joinBorder:EnableMouse(false)

    local joinLabel = join:CreateFontString(nil, "OVERLAY")
    joinLabel:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    joinLabel:SetTextColor(1, 1, 1)
    joinLabel:SetPoint("CENTER")
    join.label = joinLabel

    join:SetHighlightTexture(WHITE, "ADD")
    join:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.22)
    join:SetScript("OnClick", function() Page:JoinOrLeave() end)
    f.join = join

    local events = CreateFrame("Frame")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        for _, name in ipairs({ "UPDATE_MINI_GAMES_STATUS", "UPDATE_MINI_GAME",
            "UPDATE_AVAILABLE_MINI_GAMES" }) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events
    f:Hide()

    self.frame = f
    self.panel = panel
    return f
end

function Page:JoinOrLeave()
    if not self.selected or not C_MiniGames then return end

    local queueIndex = self:QueueIndexFor(self.selected)

    if queueIndex then
        C_MiniGames.QueueLeave(queueIndex)
    else
        local inGroup = GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
        local isLeader = IsPartyLeader() or IsRaidLeader()
        C_MiniGames.QueueJoin(self.selected, inGroup and isLeader or false)
    end

    NS.After(0.5, function() Page:Update() end)
end

function Page:UpdateTiles(games)
    local f = self.frame
    local S = NS.Styling

    for index = 1, MAX_TILES do
        local button = f.tiles[index]
        local id = games[index]

        if id then
            local name, _, icon = C_MiniGames.GetGameInfo(id)
            button.gameID = id
            button.gameName = name
            button.icon:SetTexture(icon)

            if id == self.selected then
                button:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
                button.bar:Show()
                button.icon:SetDesaturated(false)
            else
                button:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
                button.bar:Hide()
                button.icon:SetDesaturated(true)
            end

            button:Show()
        else
            button.gameID = nil
            button:Hide()
        end
    end
end

function Page:UpdateDetail()
    local f = self.frame
    local S = NS.Styling

    local name, description, _, _, objective, minPlayers, maxPlayers = C_MiniGames.GetGameInfo(self.selected)

    if not name then
        f.empty:Show()
        f.empty:SetText(L["данные об игре ещё не получены от сервера"])
        return
    end

    f.empty:Hide()
    f.title:SetText(name)

    local meta = {}
    if minPlayers and maxPlayers then
        meta[#meta + 1] = string.format(LFD_NUM_PLAYERS_FORMAT_RANGE or "(%d - %d)", minPlayers, maxPlayers)
    end
    f.meta:SetText(table.concat(meta, "  |  "))

    f.description:SetText(description or "")

    f.objectiveCaption:SetShown(objective and objective ~= "" or false)
    f.objectiveRule:SetShown(objective and objective ~= "" or false)
    f.objective:SetText(objective or "")

    local doneToday, money, rewards = C_MiniGames.GetGameRewards(self.selected)
    rewards = rewards or {}

    local slot = 1
    for index = 1, #rewards do
        if slot > MAX_REWARDS then break end

        local reward = rewards[index]
        local button = f.rewards[slot]
        local itemName, _, quality, _, _, _, _, _, _, texture = GetItemInfo(reward.itemID)

        button.itemID = reward.itemID
        button.itemName = itemName
        button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        button.count:SetText((reward.itemCount or 1) > 1 and reward.itemCount or "")

        local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        if color then
            button.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        else
            button.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        end

        button:Show()
        slot = slot + 1
    end

    for index = slot, MAX_REWARDS do f.rewards[index]:Hide() end

    local lines = {}
    lines[#lines + 1] = doneToday and (LFD_HOLIDAY_REWARD_EXPLANATION2 or "")
        or (LFD_HOLIDAY_REWARD_EXPLANATION1 or "")
    if money and money > 0 then
        lines[#lines + 1] = string.format("%s: %s", MONEY or L["Деньги"], GetMoneyString(money))
    end

    f.rewardCaption:Show()
    f.rewardRule:Show()
    f.rewardText:SetText(table.concat(lines, string.char(10)))
end

function Page:UpdateButton()
    local f = self.frame
    local queueIndex = self.selected and self:QueueIndexFor(self.selected)

    if queueIndex then
        f.join.label:SetText(LEAVE_QUEUE or L["Выйти из очереди"])

        local waited = C_MiniGames.GetQueueTimeWaited and C_MiniGames.GetQueueTimeWaited(queueIndex) or 0
        local estimated = C_MiniGames.GetQueueEstimatedWaitTime
            and C_MiniGames.GetQueueEstimatedWaitTime(queueIndex) or 0

        local parts = {}
        if waited and waited > 0 then
            parts[#parts + 1] = string.format(TIME_IN_QUEUE or "%s", SecondsToTime(waited / 1000))
        end
        if estimated and estimated > 0 then
            parts[#parts + 1] = string.format(LFG_STATISTIC_AVERAGE_WAIT or "%s",
                SecondsToTime(estimated / 1000, false, false, 1))
        end

        f.status:SetText(table.concat(parts, "  |  "))
    else
        local inGroup = GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
        local isLeader = IsPartyLeader() or IsRaidLeader()

        if inGroup and isLeader then
            f.join.label:SetText(JOIN_AS_PARTY or L["Вступить группой"])
        else
            f.join.label:SetText(FIND_A_MINI_GAME or L["Найти игру"])
        end

        if inGroup and not isLeader then
            f.status:SetText(L["очередью управляет лидер группы"])
        else
            f.status:SetText("")
        end
    end

    local usable = self.selected and (not (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
        or IsPartyLeader() or IsRaidLeader() or queueIndex) and true or false

    f.join:EnableMouse(usable)
    f.join:SetAlpha(usable and 1 or 0.4)
end

function Page:Update()
    if not self.frame then return end
    local f = self.frame

    local games = Games()

    if #games == 0 then
        self:UpdateTiles(games)
        f.detail:Hide()
        f.join:Hide()
        f.status:SetText(L["сейчас нет доступных мини-игр"])
        return
    end

    f.detail:Show()
    f.join:Show()

    if not self.selected or not C_MiniGames.IsValidGameID(self.selected) then
        self.selected = games[1]
    end

    self:UpdateTiles(games)
    self:UpdateDetail()
    self:UpdateButton()
end

function Page:Show()
    if not self.frame then return end
    self.frame:Show()
end

function Page:Hide()
    if self.frame then self.frame:Hide() end
end

NS.MiniGamesPage = Page
