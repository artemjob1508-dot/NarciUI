local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local CLASS_ICONS = "Interface\\WorldStateFrame\\Icons-Classes"
local STATUS_ICONS = {
    [1] = "Interface\\FriendsFrame\\StatusIcon-Offline",
    [2] = "Interface\\FriendsFrame\\StatusIcon-Away",
    [3] = "Interface\\FriendsFrame\\StatusIcon-Online",
}

local PANEL_W = 900
local PANEL_H = 620
local PAD = 18
local BODY_TOP = 112
local BODY_BOTTOM = 46
local BODY_H = PANEL_H - BODY_TOP - BODY_BOTTOM
local SCROLL_W = 8
local LIST_W = 250
local CHALLENGE_ROW_H = 42
local TABLE_ROW_H = 26
local TABLE_HEADER_H = 22
local TABLE_ROWS = math.max(1, math.floor((BODY_H - 16 - TABLE_HEADER_H - 6) / TABLE_ROW_H))

NS.Densify("NarcissusSirus_Challenges", function(f)
    TABLE_ROW_H = math.max(12, math.floor(26 * f + 0.5))
    TABLE_ROWS = math.max(1, math.floor((BODY_H - 16 - TABLE_HEADER_H - 6) / TABLE_ROW_H))
end)
local FEATURE_ROWS = 12
local REWARD_ROWS = 6
local SUGGEST_PRIMARY_W = 340
local SUGGEST_SECONDARY_W = PANEL_W - PAD * 2 - SUGGEST_PRIMARY_W - 24
local SUGGEST_SECONDARY_H = math.floor((BODY_H - 16 - 8) / 2)
local SUGGEST_ROWS = 3

local SORT_NAME = 1
local SORT_CLASS = 2
local SORT_LEVEL = 3
local SORT_TIME = 4
local SORT_STATUS = 5

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Chrome(frame)
    local S = NS.Styling

    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(NS.Styling.Panel(0.035, 0.04, 0.055, 0.92))
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    local grad = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    grad:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    grad:SetTexture(WHITE)
    grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    return frame
end

local function ScrollBar(parent, onScroll)
    local S = NS.Styling

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(SCROLL_W)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -8)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 8)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetTexture(WHITE)
    track:SetVertexColor(0, 0, 0, 0.4)

    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetWidth(SCROLL_W)
    thumb:SetHeight(40)
    thumb:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)

    local fill = thumb:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetTexture(WHITE)
    fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    thumb:SetScript("OnEnter", function() fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9) end)
    thumb:SetScript("OnLeave", function() fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55) end)

    thumb:SetScript("OnMouseDown", function(self)
        local _, y = GetCursorPosition()
        self.grabY = y
        self.grabOffset = bar.offset or 0
        self.dragging = true
    end)
    thumb:SetScript("OnMouseUp", function(self) self.dragging = nil end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.dragging then return end

        local range = (bar.total or 0) - (bar.visible or 0)
        local span = bar:GetHeight() - self:GetHeight()
        if range <= 0 or span <= 0 then return end

        local _, y = GetCursorPosition()
        local moved = (self.grabY - y) / (bar:GetEffectiveScale() or 1)
        local value = math.max(0, math.min(range,
            math.floor(self.grabOffset + moved / span * range + 0.5)))

        if value ~= bar.offset then onScroll(value) end
    end)

    bar.thumb = thumb

    function bar:SetState(total, visible, offset)
        self.total, self.visible, self.offset = total, visible, offset

        local range = total - visible
        if range <= 0 then
            self:Hide()
            return
        end

        self:Show()

        local height = self:GetHeight()
        local size = math.max(20, height * visible / total)
        self.thumb:SetHeight(size)
        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(height - size) * (offset / range))
    end

    bar:Hide()
    return bar
end

local function ClassInfo(classID)
    if not classID or not C_CreatureInfo or not C_CreatureInfo.GetClassInfoEx then return end
    local ok, _, classFile, _, className = pcall(C_CreatureInfo.GetClassInfoEx, classID)
    if not ok then return end
    return classFile, className
end

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.85, 0.88
end

local function RaceIcon(raceID, gender)
    if not raceID or not C_CreatureInfo or not C_CreatureInfo.GetRaceInfoEx then return end
    local ok, _, raceFile = pcall(C_CreatureInfo.GetRaceInfoEx, raceID)
    if not ok or not raceFile then return end
    local suffix = (S_GENDER_FILESTRING and S_GENDER_FILESTRING[gender]) or "MALE"
    return string.format("Interface\\Custom\\RaceIcon\\RACE_ICON_%s%s", string.upper(raceFile), suffix)
end

local function Service(method, ...)
    if not C_Service or not C_Service[method] then return nil end
    local ok, value = pcall(C_Service[method], ...)
    if not ok then return nil end
    return value
end

local JOURNAL_TABS = {
    { key = "adventure", label = "ADVENTURE_JOURNAL", fallback = "Путеводитель по приключениям" },
    { key = "headhunting", label = "HEADHUNTING", fallback = "Охота за головами" },
    { key = "challenges", label = "HARDCORE_CHALLENGES_TITLE", fallback = "Испытания" },
    { key = "items", label = "ITEM_BROWSER", fallback = "Предметы" },
}

local function OpenJournalTab(key)
    if key == "adventure" then
        if NS.ChallengePanel then NS.ChallengePanel:Hide() end
        if NS.HeadHuntingPanel then NS.HeadHuntingPanel:Hide() end
        if NS.AdventurePanel then NS.AdventurePanel:Show() end
    elseif key == "challenges" then
        if NS.AdventurePanel then NS.AdventurePanel:Hide() end
        if NS.HeadHuntingPanel then NS.HeadHuntingPanel:Hide() end
        if NS.ChallengePanel then NS.ChallengePanel:Show() end
    elseif key == "headhunting" then
        if NS.HeadHuntingPanel then
            if NS.AdventurePanel then NS.AdventurePanel:Hide() end
            if NS.ChallengePanel then NS.ChallengePanel:Hide() end
            NS.HeadHuntingPanel:Show()
        elseif HeadHuntingFrame then
            ShowUIPanel(HeadHuntingFrame)
        end
    elseif key == "items" then
        if ItemBrowser then ShowUIPanel(ItemBrowser) end
    end
end

local function TabAvailable(key)
    if key == "headhunting" then
        return Service("IsRenegadeRealm") and true or false
    elseif key == "challenges" then
        return Service("IsHardcoreEnabledOnRealm") and true or false
    elseif key == "items" then
        return Service("IsGMAccount") and true or false
    end

    return true
end

function NS.CreateJournalTabs(frame, current)
    local S = NS.Styling
    local tabs = {}
    local x = PAD - 4

    for _, tab in ipairs(JOURNAL_TABS) do
        if TabAvailable(tab.key) then
            local button = CreateFrame("Button", nil, frame)
            button:SetHeight(24)
            Chrome(button)

            local label = button:CreateFontString(nil, "OVERLAY")
            label:SetFont(NS.FONT, NS.FS(11), "")
            label:SetPoint("CENTER")
            label:SetText(Global(tab.label, tab.fallback))
            button:SetWidth(label:GetStringWidth() + 24)

            local active = tab.key == current
            button:SetBackdropBorderColor(
                active and S.ACCENT[1] or S.BORDER[1],
                active and S.ACCENT[2] or S.BORDER[2],
                active and S.ACCENT[3] or S.BORDER[3], active and 1 or S.BORDER[4])
            label:SetTextColor(
                active and S.TEXT_BRIGHT[1] or S.TEXT_DIM[1],
                active and S.TEXT_BRIGHT[2] or S.TEXT_DIM[2],
                active and S.TEXT_BRIGHT[3] or S.TEXT_DIM[3])

            local bar = button:CreateTexture(nil, "OVERLAY")
            bar:SetHeight(2)
            bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 3)
            bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
            bar:SetTexture(WHITE)
            bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
            bar:SetShown(active)

            button:SetHighlightTexture(WHITE, "ADD")
            button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

            button:SetScript("OnClick", function()
                if tab.key ~= current then OpenJournalTab(tab.key) end
            end)

            button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 12)
            x = x + button:GetWidth() + 6

            tabs[#tabs + 1] = button
        end
    end

    return tabs
end

function Panel:Challenges()
    local list = {}
    if not C_Hardcore or not C_Hardcore.GetNumChallenges then return list end

    for index = 1, (C_Hardcore.GetNumChallenges() or 0) do
        local id, name, icon, achievementID = C_Hardcore.GetChallengeInfo(index)
        if not id then break end
        list[#list + 1] = { index = index, id = id, name = name, icon = icon, achievementID = achievementID }
    end

    return list
end

function Panel:SelectedChallenge()
    if not C_Hardcore then return end

    local index = C_Hardcore.GetSelectedChallenge()
    if not index then
        local list = self:Challenges()
        if not list[1] then return end
        C_Hardcore.SetSelectChallenge(1)
        index = 1
    end

    local id, name, icon, achievementID = C_Hardcore.GetChallengeInfo(index)
    if not id then return end

    return id, name, icon, achievementID, index
end

function Panel:Suggestions()
    local list = {}
    if not C_Hardcore or not C_Hardcore.GetSuggestions then return list end

    local buffer = {}
    if not pcall(C_Hardcore.GetSuggestions, buffer) then return list end

    for index, entry in ipairs(buffer) do
        entry.index = index
        list[#list + 1] = entry
    end

    return list
end

function Panel:Features(challengeID)
    local list = {}
    if not challengeID or not C_Hardcore then return list end

    local function Collect(getter, describe)
        if not getter then return end
        local ok, features = pcall(getter, challengeID)
        if not ok or type(features) ~= "table" then return end

        for _, feature in ipairs(features) do
            local description
            if describe then
                local fine, text = pcall(describe, feature.index)
                if fine then description = text end
            end

            list[#list + 1] = { name = feature.name, description = description }
        end
    end

    Collect(C_Hardcore.GetChallengeFeaturesByID, C_Hardcore.GetFeatureDescription)
    Collect(C_Hardcore.GetChallengeFeatures1ByID, C_Hardcore.GetFeature1Description)

    if C_Hardcore.GetChallengeFeaturesCustomByID then
        local ok, features = pcall(C_Hardcore.GetChallengeFeaturesCustomByID)
        if ok and type(features) == "table" then
            for _, feature in ipairs(features) do
                local description
                if C_Hardcore.GetFeatureCustomDescription then
                    local fine, text = pcall(C_Hardcore.GetFeatureCustomDescription, feature.index)
                    if fine then description = text end
                end

                list[#list + 1] = { name = feature.name, description = description }
            end
        end
    end

    return list
end

function Panel:Rewards(challengeID, achievementID)
    local list = {}
    if not challengeID or not C_Hardcore or not C_Hardcore.GetChallengeRewardsByID then return list end

    local ok, rewards = pcall(C_Hardcore.GetChallengeRewardsByID, challengeID)
    if ok and type(rewards) == "table" then
        for _, itemID in ipairs(rewards) do
            local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            list[#list + 1] = {
                itemID = itemID,
                link = link,
                icon = icon,
                name = name,
                quality = quality,
            }
        end
    end

    if achievementID then
        local _, name, _, _, _, _, _, _, _, icon, rewardText = GetAchievementInfo(achievementID)
        local title = rewardText and rewardText ~= "" and ACHIEVEMENT_REWARD_TITLE_PATTERN
            and string.match(rewardText, ACHIEVEMENT_REWARD_TITLE_PATTERN)

        list[#list + 1] = {
            achievementID = achievementID,
            icon = icon,
            name = title
                and string.format(Global("HARDCORE_ACHIEVEMENT_TITLE_TEXT", "Достижение \"%s\" и звание \"%s\""),
                    name or "", title)
                or string.format(Global("HARDCORE_ACHIEVEMENT_TEXT", "Достижение \"%s\""), name or ""),
        }
    end

    return list
end

function Panel:TableKey()
    local challengeID, _, _, _, challengeIndex = self:SelectedChallenge()
    if not challengeID or not C_Hardcore then return end

    local count = self.tab == "participants"
        and C_Hardcore.GetNumParticipantsEntries or C_Hardcore.GetNumLeaderboardEntries

    if (count(challengeID) or 0) > 0 then return challengeID end
    if challengeIndex and (count(challengeIndex) or 0) > 0 then return challengeIndex end

    return challengeID
end

function Panel:TableEntries()
    local list = {}
    local key = self:TableKey()
    if not key or not C_Hardcore then return list end

    if self.tab == "participants" then
        for index = 1, (C_Hardcore.GetNumParticipantsEntries(key) or 0) do
            local entry = C_Hardcore.GetParticipantsEntry(key, index)
            if not entry then break end
            list[#list + 1] = entry
        end
    else
        for index = 1, (C_Hardcore.GetNumLeaderboardEntries(key) or 0) do
            local entry = C_Hardcore.GetLeaderboardEntry(key, index)
            if not entry then break end
            list[#list + 1] = entry
        end
    end

    return list
end

function Panel:Sort(sortIndex)
    local key = self:TableKey()
    if not key or not C_Hardcore then return end

    if self.tab == "participants" then
        local _, reverse = C_Hardcore.GetSortParticipants(key)
        C_Hardcore.SetSortParticipants(key, sortIndex, not reverse)
    else
        local _, reverse = C_Hardcore.GetSortLeaderboard(key)
        C_Hardcore.SetSortLeaderboard(key, sortIndex, not reverse)
    end

    self.tableOffset = 0
    self:Update()
end

function Panel:SortState()
    local key = self:TableKey()
    if not key or not C_Hardcore then return end

    if self.tab == "participants" then
        return C_Hardcore.GetSortParticipants(key)
    end

    return C_Hardcore.GetSortLeaderboard(key)
end

function Panel:CreateSuggestion(parent, index)
    local S = NS.Styling
    local primary = index == 1

    local row = CreateFrame("Frame", nil, parent)

    if primary then
        row:SetWidth(SUGGEST_PRIMARY_W)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
        row:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
    else
        row:SetHeight(SUGGEST_SECONDARY_H)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", SUGGEST_PRIMARY_W + 16,
            -8 - (index - 2) * (SUGGEST_SECONDARY_H + 8))
        row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    end

    Chrome(row)
    row:SetBackdropColor(NS.Styling.Tint(0.05, 0.055, 0.075, primary and 0.85 or 0.65))

    local sheen = row:CreateTexture(nil, "BORDER")
    sheen:SetHeight(1)
    sheen:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    sheen:SetPoint("TOPRIGHT", row, "TOPRIGHT", -1, -1)
    sheen:SetTexture(WHITE)
    sheen:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    iconFrame:SetBackdropColor(0, 0, 0, 0.8)
    iconFrame:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
    iconFrame:EnableMouse(false)
    row.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local title = row:CreateFontString(nil, "OVERLAY")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    row.title = title

    local rule = row:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetTexture(WHITE)
    rule:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28)
    row.rule = rule

    local description = row:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    description:SetJustifyV("TOP")
    row.description = description

    local action = NS.Widgets.CreateThemedButton(row, "", 170, 22, function()
        if index == 2 then
            Panel.tab = "list"
        elseif index == 3 then
            Panel.tab = "ladder"
        end
        Panel:Update()
    end)
    action:Hide()
    row.action = action

    local summary = row:CreateFontString(nil, "OVERLAY")
    summary:SetFont(NS.FONT, NS.FS(11), "")
    summary:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    summary:SetPoint("BOTTOM", row, "BOTTOM", 0, 16)
    summary:Hide()
    row.summary = summary

    if primary then
        iconFrame:SetSize(70, 70)

        title:SetFont(NS.FONT, NS.FS(15), "")
        title:SetWidth(SUGGEST_PRIMARY_W - 28)
        title:SetJustifyH("CENTER")
        title:SetPoint("TOP", iconFrame, "BOTTOM", 0, -12)

        rule:SetWidth(90)
        rule:SetPoint("TOP", title, "BOTTOM", 0, -8)

        description:SetWidth(SUGGEST_PRIMARY_W - 34)
        description:SetJustifyH("CENTER")
        description:SetPoint("TOP", rule, "BOTTOM", 0, -8)

        action:SetPoint("TOP", description, "BOTTOM", 0, -14)
    else
        iconFrame:SetSize(58, 58)

        title:SetFont(NS.FONT, NS.FS(13), "")
        title:SetWidth(SUGGEST_SECONDARY_W - 96)
        title:SetJustifyH("LEFT")

        rule:SetWidth(SUGGEST_SECONDARY_W - 96)
        rule:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

        description:SetWidth(SUGGEST_SECONDARY_W - 96)
        description:SetJustifyH("LEFT")
        description:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -6)

        action:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)
    end

    row:Hide()
    return row
end

function Panel:CreateChallengeRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(CHALLENGE_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * (CHALLENGE_ROW_H + 4))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * (CHALLENGE_ROW_H + 4))

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.2)

    local selected = row:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetTexture(WHITE)
    selected:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    selected:Hide()
    row.selected = selected

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local active = row:CreateFontString(nil, "OVERLAY")
    active:SetFont(NS.FONT, NS.FS(10), "")
    active:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    active:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 4)
    active:SetText(Global("HARDCORE_CHALLENGE_STATUS_2", "В процессе"))
    active:Hide()
    row.active = active

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    row:SetScript("OnClick", function(self)
        if not self.challengeIndex then return end
        C_Hardcore.SetSelectChallenge(self.challengeIndex)
        Panel.featureOffset = 0
        Panel.tableOffset = 0
        Panel:Update()
    end)

    row:Hide()
    return row
end

function Panel:CreateFeatureRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    row:SetHeight(30)

    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(4, 4)
    dot:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -6)
    dot:SetTexture(WHITE)
    dot:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    row.dot = dot

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    name:SetPoint("TOPLEFT", row, "TOPLEFT", 12, 0)
    name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local description = row:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    description:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    description:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    row.description = description

    row:Hide()
    return row
end

function Panel:CreateRewardRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(28)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local border = CreateFrame("Frame", nil, row)
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    row.border = border

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    row:SetScript("OnEnter", function(self)
        if self.link then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.link)
            GameTooltip:Show()
        elseif self.achievementID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.name:GetText() or "", 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        if self.link then HandleModifiedItemClick(self.link) end
    end)

    row:Hide()
    return row
end

function Panel:CreateTableRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(TABLE_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -(8 + TABLE_HEADER_H + 4) - (index - 1) * TABLE_ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8 - SCROLL_W - 4,
        -(8 + TABLE_HEADER_H + 4) - (index - 1) * TABLE_ROW_H)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.28 or 0.10)

    local race = row:CreateTexture(nil, "ARTWORK")
    race:SetSize(20, 20)
    race:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.race = race

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", race, "RIGHT", 8, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local class = row:CreateTexture(nil, "ARTWORK")
    class:SetSize(20, 20)
    row.class = class

    local level = row:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(12), "")
    level:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    level:SetJustifyH("LEFT")
    row.level = level

    local time = row:CreateFontString(nil, "OVERLAY")
    time:SetFont(NS.FONT, NS.FS(12), "")
    time:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    time:SetJustifyH("LEFT")
    row.time = time

    local statusIcon = row:CreateTexture(nil, "ARTWORK")
    statusIcon:SetSize(16, 16)
    row.statusIcon = statusIcon

    local status = row:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    status:SetPoint("LEFT", statusIcon, "RIGHT", 4, 0)
    status:SetJustifyH("LEFT")
    row.status = status

    row:Hide()
    return row
end

function Panel:CreateHeader(parent, sortIndex, label)
    local S = NS.Styling

    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(TABLE_HEADER_H)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(11), "")
    text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    text:SetPoint("LEFT", button, "LEFT", 0, 0)
    text:SetText(label)
    button.text = text

    local arrow = button:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(NS.FONT, NS.FS(9), "")
    arrow:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    arrow:SetPoint("LEFT", text, "RIGHT", 4, 0)
    arrow:Hide()
    button.arrow = arrow

    button:SetHighlightTexture(WHITE, "ADD")
    button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    button:SetScript("OnClick", function() Panel:Sort(sortIndex) end)
    button.sortIndex = sortIndex

    return button
end

function Panel:CreateFilterPopup(parent)
    local S = NS.Styling

    local popup = CreateFrame("Frame", nil, parent)
    popup:SetWidth(260)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(parent:GetFrameLevel() + 40)
    Chrome(popup)
    S.CreateShadow(popup, 5, 0.5)
    popup:EnableMouse(true)
    popup:Hide()

    popup.checks = {}

    local y = -12

    local function AddTitle(text)
        local caption = popup:CreateFontString(nil, "OVERLAY")
        caption:SetFont(NS.FONT, NS.FS(10), "")
        caption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        caption:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, y - 2)
        caption:SetText(string.upper(text or ""))
        y = y - 20
    end

    AddTitle(Global("HARDCORE_CHALLENGE_FILTER_SEARCH", "Поиск"))

    local search = NS.Widgets.CreateThemedEditBox(popup, 230, 20, 32)
    search:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, y)
    search:SetScript("OnTextChanged", function(box)
        local text = box:GetText() or ""
        if Panel.tab == "participants" then
            C_Hardcore.SetParticipantsSearch(text)
        else
            C_Hardcore.SetLeaderboardSearch(text)
        end
        Panel.tableOffset = 0
        Panel:Update()
    end)
    popup.search = search
    y = y - 28

    AddTitle(Global("HARDCORE_CHALLENGE_FILTER_LEVEL", "Уровень"))

    local minLevel = NS.Widgets.CreateThemedEditBox(popup, 108, 20, 3)
    minLevel:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, y)
    popup.minLevel = minLevel

    local maxLevel = NS.Widgets.CreateThemedEditBox(popup, 108, 20, 3)
    maxLevel:SetPoint("TOPLEFT", minLevel, "TOPRIGHT", 14, 0)
    popup.maxLevel = maxLevel

    local function ApplyLevels()
        local low = tonumber(minLevel:GetText()) or 0
        local high = tonumber(maxLevel:GetText()) or 0

        if high ~= 0 and low > high then
            low = high
            minLevel:SetText(tostring(low))
        end

        if Panel.tab == "participants" then
            C_Hardcore.SetParticipantsLevelFilter(low, high)
        else
            C_Hardcore.SetLeaderboardLevelFilter(low, high)
        end

        Panel.tableOffset = 0
        Panel:Update()
    end

    minLevel:SetScript("OnTextChanged", ApplyLevels)
    maxLevel:SetScript("OnTextChanged", ApplyLevels)
    y = y - 28

    local function AddCheck(text, get, set)
        local check = NS.Widgets.CreateThemedCheckbox(popup, text, false, function(value)
            set(value)
            Panel:RefreshFilters()
            Panel.tableOffset = 0
            Panel:Update()
        end)
        check:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, y)
        y = y - 22
        popup.checks[#popup.checks + 1] = { check = check, get = get }
    end

    AddTitle(Global("HARDCORE_CHALLENGE_FILTER_STATUS", "Статус"))

    for index = 1, (C_Hardcore and C_Hardcore.GetNumLeaderboardStatusFilters
        and C_Hardcore.GetNumLeaderboardStatusFilters() or 0) do
        if not C_Hardcore.IsValidLeaderboardStatusFilter or C_Hardcore.IsValidLeaderboardStatusFilter(index) then
            local label = Global("HARDCORE_CHALLENGE_STATUS_" .. index, "Статус " .. index)
            AddCheck(label,
                function() return C_Hardcore.IsLeaderboardStatusChecked(index) end,
                function(value) C_Hardcore.SetLeaderboardStatusFilter(index, value) end)
        end
    end

    popup.statusCount = #popup.checks

    AddTitle(Global("HARDCORE_CHALLENGE_FILTER_CLASS", "Класс"))

    for index = 1, (GetNumClasses and GetNumClasses() or 0) do
        local name, _, classID = GetClassInfo(index)
        if name and classID then
            AddCheck(name,
                function()
                    if Panel.tab == "participants" then
                        return C_Hardcore.IsParticipantsClassChecked(classID)
                    end
                    return C_Hardcore.IsLeaderboardClassChecked(classID)
                end,
                function(value)
                    if Panel.tab == "participants" then
                        C_Hardcore.SetParticipantsClassFilter(classID, value)
                    else
                        C_Hardcore.SetLeaderboardClassFilter(classID, value)
                    end
                end)
        end
    end

    local reset = NS.Widgets.CreateThemedButton(popup, Global("RESET_FILTERS", "Сбросить фильтры"), 232, 20, function()
        if Panel.tab == "participants" then
            C_Hardcore.SetParticipantsDefaultFilters()
        else
            C_Hardcore.SetLeaderboardDefaultFilters()
        end

        popup.search:SetText("")
        popup.minLevel:SetText("")
        popup.maxLevel:SetText("")

        Panel:RefreshFilters()
        Panel.tableOffset = 0
        Panel:Update()
    end)
    reset:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, y - 4)
    y = y - 28

    popup:SetHeight(math.max(80, -y + 8))

    return popup
end

function Panel:RefreshFilters()
    local popup = self.frame and self.frame.filterPopup
    if not popup then return end

    for index, row in ipairs(popup.checks) do
        local statusRow = index <= (popup.statusCount or 0)
        if statusRow and self.tab == "participants" then
            row.check:Hide()
        else
            row.check:Show()
            local ok, value = pcall(row.get)
            row.check:SetChecked(ok and value and true or false)
        end
    end
end

function Panel:Confirm(challengeID, isActive)
    local S = NS.Styling
    local f = self.frame

    local confirm = f.confirm
    confirm.challengeID = challengeID
    confirm.isActive = isActive

    local name = C_Hardcore.GetChallengeInfoByID(challengeID)

    if isActive then
        confirm.text:SetText(string.format(Global("HARDCORE_CANCEL_CHALLENGE_TEXT",
            "Вы уверены, что хотите прервать прохождение испытания %s?"), name or ""))
        confirm.edit:Show()
        confirm.edit:SetText("")
        confirm.accept:SetAlpha(0.4)
        confirm.accept:EnableMouse(false)
    else
        confirm.text:SetText(string.format(Global("HARDCORE_START_CHALLENGE_TEXT",
            "Вы уверены, что хотите начать испытание %s?"), name or ""))
        confirm.edit:Hide()
        confirm.accept:SetAlpha(1)
        confirm.accept:EnableMouse(true)
    end

    confirm:Show()
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_Challenges", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.97))
    S.WindowSounds(f)
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 6, 0.45)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -16)
    title:SetText(Global("HARDCORE_CHALLENGES_TITLE", "Испытания"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    S.CreateAnimatedSeparator(f, -72)

    f.tabs = {}
    local topTabs = {
        { key = "home", label = Global("HEADHUNTING_HOME", "Главная") },
        { key = "list", label = Global("HARDCORE_CHALLENGES_LIST", "Список испытаний") },
        { key = "participants", label = Global("HARDCORE_CHALLENGES_PARTICIPANTS_LIST", "Список участников") },
        { key = "ladder", label = Global("LADDER", "Ладдер") },
    }

    local tabX = PAD
    for index, tab in ipairs(topTabs) do
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(24)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        button.label = label
        button:SetWidth(label:GetStringWidth() + 24)

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 3)
        bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

        button:SetScript("OnClick", function()
            Panel.tab = tab.key
            Panel.tableOffset = 0
            Panel.featureOffset = 0
            Panel:Update()
        end)

        button:SetPoint("TOPLEFT", f, "TOPLEFT", tabX, -84)
        tabX = tabX + button:GetWidth() + 6

        button.tabKey = tab.key
        f.tabs[index] = button
    end

    local filterButton = NS.Widgets.CreateThemedButton(f, Global("FILTER", "Фильтр"), 90, 22, function()
        local popup = f.filterPopup
        if popup:IsShown() then
            popup:Hide()
        else
            Panel:RefreshFilters()
            popup:Show()
        end
    end)
    filterButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -85)
    filterButton:Hide()
    f.filterButton = filterButton

    local suggest = CreateFrame("Frame", nil, f)
    suggest:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    suggest:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(suggest)
    suggest:Hide()
    f.suggest = suggest

    f.suggestRows = {}
    for index = 1, SUGGEST_ROWS do
        f.suggestRows[index] = self:CreateSuggestion(suggest, index)
    end

    local list = CreateFrame("Frame", nil, f)
    list:SetWidth(LIST_W)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, BODY_BOTTOM)
    Chrome(list)
    list:Hide()
    f.list = list

    f.challengeRows = {}
    for index = 1, math.floor((BODY_H - 12) / (CHALLENGE_ROW_H + 4)) do
        f.challengeRows[index] = self:CreateChallengeRow(list, index)
    end

    local detailX = PAD + LIST_W + 14

    local detailTabs = {}
    local detailDefs = {
        { key = "description", label = Global("HARDCORE_CHALLENGE_TAB_DESCRIPTION", "Описание") },
        { key = "features", label = Global("HARDCORE_CHALLENGE_TAB_RESTRICTIONS", "Ограничения") },
        { key = "finish", label = Global("HARDCORE_CHALLENGE_TAB_VICTORY_CONDITIONS", "Конец испытания") },
    }

    local x = detailX
    for _, def in ipairs(detailDefs) do
        local button = NS.Widgets.CreateThemedButton(f, def.label, 132, 20, function()
            Panel.detailTab = def.key
            Panel.featureOffset = 0
            Panel:Update()
        end)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", x, -110)
        button:Hide()
        button.tabKey = def.key
        x = x + 138
        detailTabs[#detailTabs + 1] = button
    end
    f.detailTabs = detailTabs

    local detail = CreateFrame("Frame", nil, f)
    detail:SetPoint("TOPLEFT", f, "TOPLEFT", detailX, -136)
    detail:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(detail)
    detail:Hide()
    f.detail = detail

    detail:EnableMouseWheel(true)
    detail:SetScript("OnMouseWheel", function(_, delta)
        if Panel.detailTab ~= "features" then return end
        local total = #Panel:Features(Panel:SelectedChallenge())
        if total <= FEATURE_ROWS then return end
        Panel.featureOffset = math.max(0, math.min(total - FEATURE_ROWS, (Panel.featureOffset or 0) - delta))
        Panel:Update()
    end)

    local text = detail:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(12), "")
    text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    text:SetPoint("TOPLEFT", detail, "TOPLEFT", 12, -12)
    text:SetPoint("RIGHT", detail, "RIGHT", -12, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    f.detailText = text

    local rewardCaption = detail:CreateFontString(nil, "OVERLAY")
    rewardCaption:SetFont(NS.FONT, NS.FS(10), "")
    rewardCaption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    rewardCaption:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -14)
    rewardCaption:SetText(string.upper(Global("REWARDS", "Награды")))
    rewardCaption:Hide()
    f.rewardCaption = rewardCaption

    f.rewardRows = {}
    for index = 1, REWARD_ROWS do
        local row = self:CreateRewardRow(detail, index)
        if index == 1 then
            row:SetPoint("TOPLEFT", rewardCaption, "BOTTOMLEFT", 0, -6)
        else
            row:SetPoint("TOPLEFT", f.rewardRows[index - 1], "BOTTOMLEFT", 0, -2)
        end
        row:SetPoint("RIGHT", detail, "RIGHT", -12, 0)
        f.rewardRows[index] = row
    end

    f.featureRows = {}
    for index = 1, FEATURE_ROWS do
        f.featureRows[index] = self:CreateFeatureRow(detail, index)
    end

    local start = NS.Widgets.CreateThemedButton(f, Global("HARDCORE_START_CHALLENGE", "Начать испытание"),
        200, 24, function(button)
            if not button.challengeID then return end
            Panel:Confirm(button.challengeID, button.isActive)
        end)
    start:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -12, 12)
    start:Hide()

    start:SetScript("OnEnter", function(button)
        if not button.disabledReason then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("HARDCORE_CHALLENGES_DISABLE_REASON_UNAVAILABLE",
            "Испытание недоступно."), 1, 1, 1)
        local reason = _G[string.format("HARDCORE_CHALLENGES_DISABLE_REASON_%d_DESCRIPTION", button.disabledReason)]
        if reason then GameTooltip:AddLine(reason, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    start:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.start = start

    local tableFrame = CreateFrame("Frame", nil, f)
    tableFrame:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    tableFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(tableFrame)
    tableFrame:Hide()
    f.table = tableFrame

    local function ScrollTable(value)
        Panel.tableOffset = value
        Panel:Update()
    end

    tableFrame:EnableMouseWheel(true)
    tableFrame:SetScript("OnMouseWheel", function(_, delta)
        local total = #Panel:TableEntries()
        if total <= TABLE_ROWS then return end
        ScrollTable(math.max(0, math.min(total - TABLE_ROWS, (Panel.tableOffset or 0) - delta)))
    end)

    f.tableScroll = ScrollBar(tableFrame, ScrollTable)

    f.headers = {
        name = self:CreateHeader(tableFrame, SORT_NAME, Global("HARDCORE_HEADER_COLUMN_PLAYER", "Игрок")),
        class = self:CreateHeader(tableFrame, SORT_CLASS, Global("HARDCORE_HEADER_COLUMN_CLASS", "Класс")),
        level = self:CreateHeader(tableFrame, SORT_LEVEL, Global("HARDCORE_HEADER_COLUMN_LEVEL", "Уровень")),
        time = self:CreateHeader(tableFrame, SORT_TIME, Global("HARDCORE_HEADER_COLUMN_TIME", "Время")),
        status = self:CreateHeader(tableFrame, SORT_STATUS, Global("HARDCORE_HEADER_COLUMN_STATUS", "Статус")),
    }

    f.tableRows = {}
    for index = 1, TABLE_ROWS do
        f.tableRows[index] = self:CreateTableRow(tableFrame, index)
    end

    local empty = tableFrame:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 14, -(TABLE_HEADER_H + 24))
    empty:SetText(L["по этим фильтрам ничего не найдено"])
    empty:Hide()
    f.tableEmpty = empty

    f.filterPopup = self:CreateFilterPopup(f)
    f.filterPopup:ClearAllPoints()
    f.filterPopup:SetPoint("TOPRIGHT", filterButton, "BOTTOMRIGHT", 0, -4)

    local confirm = CreateFrame("Frame", nil, f)
    confirm:SetPoint("CENTER", f, "CENTER", 0, 0)
    confirm:SetSize(420, 260)
    confirm:SetFrameStrata("DIALOG")
    confirm:SetFrameLevel(f:GetFrameLevel() + 60)
    Chrome(confirm)
    confirm:SetBackdropColor(NS.Styling.Panel(0.03, 0.035, 0.05, 0.98))
    S.CreateShadow(confirm, 6, 0.6)
    confirm:EnableMouse(true)
    confirm:Hide()
    f.confirm = confirm

    local confirmText = confirm:CreateFontString(nil, "OVERLAY")
    confirmText:SetFont(NS.FONT, NS.FS(12), "")
    confirmText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    confirmText:SetPoint("TOPLEFT", confirm, "TOPLEFT", 16, -16)
    confirmText:SetPoint("RIGHT", confirm, "RIGHT", -16, 0)
    confirmText:SetJustifyH("LEFT")
    confirmText:SetJustifyV("TOP")
    confirm.text = confirmText

    local confirmEdit = NS.Widgets.CreateThemedEditBox(confirm, 200, 22, 32)
    confirmEdit:SetPoint("BOTTOM", confirm, "BOTTOM", 0, 52)
    confirmEdit:Hide()
    confirm.edit = confirmEdit

    local accept = NS.Widgets.CreateThemedButton(confirm, Global("ACCEPT", "Принять"), 130, 24, function()
        local challengeID = confirm.challengeID
        if not challengeID then return end

        if confirm.isActive then
            pcall(SendServerMessage, "ACMSG_REMOVE_HARDCORE", 3)
        else
            pcall(SendServerMessage, "ACMSG_HARDCORE_CHALLENGE", challengeID)
        end

        confirm:Hide()
        Panel:Update()
    end)
    accept:SetPoint("BOTTOMLEFT", confirm, "BOTTOMLEFT", 60, 16)
    confirm.accept = accept

    local decline = NS.Widgets.CreateThemedButton(confirm, Global("CANCEL", "Отмена"), 130, 24, function()
        confirm:Hide()
    end)
    decline:SetPoint("BOTTOMRIGHT", confirm, "BOTTOMRIGHT", -60, 16)

    confirmEdit:SetScript("OnTextChanged", function(box)
        local agree = Global("CONFIRM_TEXT_AGREE", "СОГЛАСЕН")
        local matches = string.upper(box:GetText() or "") == string.upper(agree)
        accept:SetAlpha(matches and 1 or 0.4)
        accept:EnableMouse(matches)
    end)

    f.journalTabs = NS.CreateJournalTabs(f, "challenges")

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:SetScript("OnEvent", function()
        if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
    end)

    if events.RegisterCustomEvent then
        for _, event in ipairs({
            "HARDCORE_SELECTED_CHALLENGE",
            "HARDCORE_PARTICIPANTS_UPDATE",
            "HARDCORE_LADDER_UPDATE",
            "CUSTOM_CHALLENGE_ACTIVATED",
            "CUSTOM_CHALLENGE_DEACTIVATED",
            "SERVICE_DATA_UPDATE",
        }) do
            pcall(events.RegisterCustomEvent, events, event)
        end
    end

    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_Challenges")

    self.frame = f
    self.tab = self.tab or "home"
    self.detailTab = self.detailTab or "description"
    self.tableOffset = 0
    self.featureOffset = 0

    f:Hide()
end

function Panel:UpdateSuggest()
    local f = self.frame
    local suggestions = self:Suggestions()

    f.subtitle:SetText(Global("HEADHUNTING_HOME", "Главная"))

    for index = 1, SUGGEST_ROWS do
        local row = f.suggestRows[index]
        local entry = suggestions[index]

        if entry then
            row.icon:SetTexture(entry.iconPath or QUESTION)
            row.title:SetText(entry.title or "")
            row.description:SetText(entry.description or "")

            if index == 1 then
                row.action:Hide()
                row.summary:SetText(entry.buttonText or "")
                row.summary:SetShown(entry.buttonText and entry.buttonText ~= "")
            elseif entry.buttonText and entry.buttonText ~= "" then
                row.action:SetText(entry.buttonText)
                row.action:Show()
            else
                row.action:Hide()
            end

            local titleHeight = row.title:GetStringHeight() or 14
            local textHeight = row.description:GetStringHeight() or 0
            local actionHeight = row.action:IsShown() and 36 or 0
            local height = row:GetHeight() or 0

            if index == 1 then
                local block = 99 + titleHeight + textHeight + actionHeight
                row.iconFrame:ClearAllPoints()
                row.iconFrame:SetPoint("TOP", row, "TOP", 0,
                    -math.max(16, math.floor((height - block) / 2)))
            else
                local block = 13 + titleHeight + textHeight + actionHeight
                local top = math.max(12, math.floor((height - block) / 2))

                row.title:ClearAllPoints()
                row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 82, -top)
                row.iconFrame:ClearAllPoints()
                row.iconFrame:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -top)
            end

            row:Show()
        else
            row:Hide()
        end
    end
end

function Panel:UpdateList()
    local f = self.frame
    local challenges = self:Challenges()
    local selectedID = self:SelectedChallenge()

    f.subtitle:SetText(Global("HARDCORE_CHALLENGES_LIST", "Список испытаний"))

    for index, row in ipairs(f.challengeRows) do
        local challenge = challenges[index]

        if challenge then
            row.challengeIndex = challenge.index
            row.challengeID = challenge.id
            row.icon:SetTexture(challenge.icon or QUESTION)
            row.name:SetText(challenge.name or "")
            row.selected:SetShown(challenge.id == selectedID)
            row.active:SetShown(Service("IsChallengeActive", challenge.id) and true or false)
            row:Show()
        else
            row.challengeIndex = nil
            row:Hide()
        end
    end

    local challengeID, name, _, achievementID = self:SelectedChallenge()

    for _, button in ipairs(f.detailTabs) do
        button:Show()
        button:SetAlpha(button.tabKey == self.detailTab and 1 or 0.55)
    end

    if not challengeID then
        f.detailText:SetText(L["выберите испытание"])
        f.rewardCaption:Hide()
        for _, row in ipairs(f.rewardRows) do row:Hide() end
        for _, row in ipairs(f.featureRows) do row:Hide() end
        f.start:Hide()
        return
    end

    if self.detailTab == "description" then
        f.detailText:SetText(C_Hardcore.GetChallengeDescriptionByID(challengeID) or "")
        f.detailText:Show()

        for _, row in ipairs(f.featureRows) do row:Hide() end

        local rewards = self:Rewards(challengeID, achievementID)
        f.rewardCaption:SetShown(#rewards > 0)

        for index, row in ipairs(f.rewardRows) do
            local reward = rewards[index]

            if reward then
                row.link = reward.link
                row.achievementID = reward.achievementID
                row.icon:SetTexture(reward.icon or QUESTION)
                row.name:SetText(reward.name or Global("RETRIEVING_ITEM_INFO", "Загрузка"))

                if reward.quality and BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[reward.quality] then
                    local color = BAG_ITEM_QUALITY_COLORS[reward.quality]
                    row.name:SetTextColor(color.r, color.g, color.b)
                    row.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
                else
                    row.name:SetTextColor(1, 1, 1)
                    row.border:SetBackdropBorderColor(0.4, 0.4, 0.45, 0.9)
                end

                row:Show()
            else
                row.link = nil
                row:Hide()
            end
        end
    elseif self.detailTab == "finish" then
        f.detailText:SetText(C_Hardcore.GetChallengeFinishConditionsByID(challengeID) or "")
        f.detailText:Show()
        f.rewardCaption:Hide()
        for _, row in ipairs(f.rewardRows) do row:Hide() end
        for _, row in ipairs(f.featureRows) do row:Hide() end
    else
        f.detailText:SetText("")
        f.rewardCaption:Hide()
        for _, row in ipairs(f.rewardRows) do row:Hide() end

        local features = self:Features(challengeID)
        local offset = math.max(0, math.min(self.featureOffset or 0, math.max(0, #features - FEATURE_ROWS)))
        self.featureOffset = offset

        local y = -10

        for index, row in ipairs(f.featureRows) do
            local feature = features[index + offset]

            if feature then
                row.name:SetText(feature.name or "")
                row.description:SetText(feature.description or "")

                local height = 4 + (row.name:GetStringHeight() or 12)
                    + (feature.description and 3 + (row.description:GetStringHeight() or 0) or 0)

                row:SetHeight(height)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", f.detail, "TOPLEFT", 10, y)
                row:SetPoint("TOPRIGHT", f.detail, "TOPRIGHT", -10, y)
                row:Show()

                y = y - height - 6
            else
                row:Hide()
            end
        end
    end

    local start = f.start
    start.challengeID = challengeID
    start.disabledReason = nil
    start.isActive = Service("IsChallengeActive", challengeID) and true or false
    start:Show()

    local function Enable(enabled)
        start:SetAlpha(enabled and 1 or 0.4)
        start:EnableMouse(enabled)
    end

    if Service("IsHardcoreCharacter") then
        if Service("HasActiveChallenges") then
            if start.isActive then
                Enable(not UnitIsDeadOrGhost("player"))
                if UnitIsDeadOrGhost("player") then start.disabledReason = 2 end
                start:SetText(Global("HARDCORE_CANCEL_CHALLENGE", "Отменить испытание"))
            else
                start.disabledReason = 1
                Enable(false)
                start:SetText(Global("HARDCORE_START_CHALLENGE", "Начать испытание"))
            end
        else
            local allowed = UnitLevel("player") == 1 and not UnitIsDeadOrGhost("player")
            if not allowed then start.disabledReason = 3 end
            Enable(allowed)
            start:SetText(Global("HARDCORE_START_CHALLENGE", "Начать испытание"))
        end
    else
        start.disabledReason = 4
        Enable(false)
        start:SetText(Global("HARDCORE_START_CHALLENGE", "Начать испытание"))
    end
end

function Panel:UpdateTable()
    local S = NS.Styling
    local f = self.frame
    local ladder = self.tab == "ladder"
    local entries = self:TableEntries()
    local offset = math.max(0, math.min(self.tableOffset or 0, math.max(0, #entries - TABLE_ROWS)))
    self.tableOffset = offset

    local _, challengeName = self:SelectedChallenge()
    f.subtitle:SetFormattedText("%s - %s",
        ladder and Global("LADDER", "Ладдер")
            or Global("HARDCORE_CHALLENGES_PARTICIPANTS_LIST", "Список участников"),
        challengeName or "")

    local width = f.table:GetWidth() - SCROLL_W - 16
    local nameX = 8
    local classX = ladder and width - 300 or width - 150
    local levelX = ladder and width - 230 or width - 70
    local timeX = width - 160
    local statusX = width - 90

    local headers = f.headers
    local positions = {
        [headers.name] = nameX,
        [headers.class] = classX,
        [headers.level] = levelX,
        [headers.time] = timeX,
        [headers.status] = statusX,
    }

    local sortIndex, reverse = self:SortState()

    for header, x in pairs(positions) do
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", f.table, "TOPLEFT", x + 8, -8)
        header:SetWidth(math.max(40, header.text:GetStringWidth() + 16))
        header:SetShown(ladder or (header ~= headers.time and header ~= headers.status))
        header.arrow:SetText(reverse and "v" or "^")
        header.arrow:SetShown(sortIndex == header.sortIndex)
    end

    for index = 1, TABLE_ROWS do
        local row = f.tableRows[index]
        local entry = entries[index + offset]

        if entry then
            local classFile = ClassInfo(entry.class)

            local racePath = RaceIcon(entry.race, entry.gender)
            if racePath then
                row.race:SetTexture(racePath)
                row.race:Show()
            else
                row.race:Hide()
            end

            row.name:SetText(entry.name or "?")
            row.name:SetTextColor(ClassColor(classFile))

            row.class:ClearAllPoints()
            row.class:SetPoint("LEFT", row, "LEFT", classX + 8, 0)
            row.class:SetTexture(CLASS_ICONS)
            if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
                row.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
                row.class:Show()
            else
                row.class:Hide()
            end

            row.level:ClearAllPoints()
            row.level:SetPoint("LEFT", row, "LEFT", levelX + 8, 0)
            row.level:SetText(entry.level or "")

            if ladder then
                row.time:ClearAllPoints()
                row.time:SetPoint("LEFT", row, "LEFT", timeX + 8, 0)
                row.time:SetText(SecondsToTime and SecondsToTime(entry.time or 0) or (entry.time or ""))
                row.time:Show()

                row.statusIcon:ClearAllPoints()
                row.statusIcon:SetPoint("LEFT", row, "LEFT", statusX + 8, 0)
                row.statusIcon:SetTexture(STATUS_ICONS[entry.status or 0] or STATUS_ICONS[2])
                row.statusIcon:Show()
                row.status:SetText(Global("HARDCORE_CHALLENGE_STATUS_" .. (entry.status or 2), ""))
                row.status:Show()
            else
                row.time:Hide()
                row.statusIcon:Hide()
                row.status:Hide()
            end

            row:Show()
        else
            row:Hide()
        end
    end

    f.tableEmpty:SetShown(#entries == 0)
    f.tableScroll:SetState(#entries, TABLE_ROWS, offset)
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling

    if not C_Hardcore or not C_Hardcore.GetNumChallenges then
        f.subtitle:SetText(L["испытания недоступны на этом сервере"])
        return
    end

    for _, button in ipairs(f.tabs) do
        local active = button.tabKey == self.tab
        button:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or S.BORDER[4])
        button.bar:SetShown(active)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_DIM[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_DIM[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_DIM[3])
    end

    local home = self.tab == "home"
    local list = self.tab == "list"
    local isTable = self.tab == "participants" or self.tab == "ladder"

    f.suggest:SetShown(home)
    f.list:SetShown(list)
    f.detail:SetShown(list)
    f.table:SetShown(isTable)
    f.filterButton:SetShown(isTable)

    if not isTable and f.filterPopup:IsShown() then f.filterPopup:Hide() end

    for _, button in ipairs(f.detailTabs) do button:SetShown(list) end
    f.start:SetShown(list)

    if home then
        self:UpdateSuggest()
    elseif list then
        self:UpdateList()
    else
        self:UpdateTable()
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self.frame:Show()
    self:Update()
end

function Panel:Hide()
    if not self.frame then return end
    self.frame:Hide()
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.ChallengePanel = Panel
