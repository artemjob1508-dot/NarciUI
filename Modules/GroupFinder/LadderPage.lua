local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local CLASS_ICONS = "Interface\\WorldStateFrame\\Icons-Classes"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local RAIL_W = 190
local ROW_H = 26
local ROWS = 12

NS.Densify("NarcissusSirus_GroupFinder", function(f)
    ROW_H, ROWS = NS.DensityRows(26, 12, f)
end)

local BRACKETS = {
    {
        bracket = 0, value = "rating", group = "pvp",
        label = "PVP_LADDER_SOLO_LABEL", fallback = "SoloQ",
        atlas = "Custom-Ladder-Category-Icon-Solo-Rectangle",
        icon = "Interface\\Icons\\Achievement_Arena_2v2_7",
    },
    {
        bracket = 1, value = "rating", group = "pvp",
        label = "PVP_LADDER_2V2_LABEL", fallback = "Арена 2х2",
        atlas = "Custom-Ladder-Category-Icon-2x2-Rectangle",
        icon = "Interface\\Icons\\Achievement_Arena_2v2_1",
    },
    {
        bracket = 2, value = "rating", group = "pvp",
        label = "PVP_LADDER_1V1_LABEL", fallback = "Арена 1х1",
        atlas = "Custom-Ladder-Category-Icon-3x3-Rectangle",
        icon = "Interface\\Icons\\Achievement_Arena_3v3_1",
    },
    {
        bracket = 3, value = "rating", group = "pvp",
        label = "PVP_LADDER_BG_LABEL", fallback = "Поля боя",
        atlas = "Custom-Ladder-Category-Icon-Battleground-Rectangle",
        icon = "Interface\\Icons\\Achievement_BG_winWSG",
    },
    {
        bracket = 4, value = "kills", group = "other",
        label = "LADDER_RENEGADE", fallback = "Ренегаты",
        atlas = "Custom-Ladder-Category-Icon-Renegade-Rectangle",
        icon = "Interface\\Icons\\Ability_Rogue_Ambush",
    },
    {
        bracket = 8, value = "dps", group = "other",
        label = "LADDER_DUMMY_HEROIC_LABEL", fallback = "Манекен 83 уровня",
        atlas = "Custom-Ladder-Category-Icon-2x2-Rectangle",
        icon = "Interface\\Icons\\Ability_Warrior_InnerRage",
    },
    {
        bracket = 9, value = "score", group = "other",
        label = "LADDER_MYTHIC_PLUS_LABEL", fallback = "Эпохальный+",
        atlas = "Custom-Ladder-Category-Icon-3x3-Rectangle",
        icon = "Interface\\Icons\\Achievement_ChallengeMode_Gold",
    },
}

local CLASS_TABS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 }

local EVENTS = {
    "PVP_LADDER_TOP", "PVP_LADDER_CLASS_TOP", "PVP_LADDER_PLAYER",
    "PVP_LADDER_SEARCH_RESULT", "PVP_LADDER_SEARCH_ERROR", "PVP_LADDER_SEARCH_DELAY",
    "RENEGADE_LADDER_TOP", "RENEGADE_LADDER_CLASS_TOP", "RENEGADE_LADDER_PLAYER",
    "RENEGADE_LADDER_SEARCH_RESULT", "RENEGADE_LADDER_SEARCH_ERROR", "RENEGADE_LADDER_SEARCH_DELAY",
    "LADDER_DUMMY_TOP", "LADDER_DUMMY_CLASS_TOP", "LADDER_DUMMY_PLAYER",
    "LADDER_DUMMY_SEARCH_RESULT", "LADDER_DUMMY_SEARCH_ERROR", "LADDER_DUMMY_SEARCH_DELAY",
    "LADDER_MYTHIC_PLUS_TOP", "LADDER_MYTHIC_PLUS_CLASS_TOP", "LADDER_MYTHIC_PLUS_PLAYER",
    "LADDER_MYTHIC_PLUS_SEARCH_RESULT", "LADDER_MYTHIC_PLUS_SEARCH_ERROR", "LADDER_MYTHIC_PLUS_SEARCH_DELAY",
}

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_Ladder and C_Ladder.RequestTopPlayers and C_Ladder.GetNumTopPlayers
end

local function SetIcon(texture, atlas, icon)
    if atlas and texture.SetAtlas and C_Texture and C_Texture.HasAtlasInfo then
        local ok, has = pcall(C_Texture.HasAtlasInfo, atlas)
        if ok and has then
            local applied = pcall(texture.SetAtlas, texture, atlas)
            if applied then return end
        end
    end
    texture:SetTexture(icon or QUESTION)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

local function ClassInfo(classID)
    if not classID or not GetClassInfo then return nil, nil end
    local ok, className, classFile = pcall(GetClassInfo, classID)
    if not ok then return nil, nil end
    return className, classFile
end

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.85, 0.88
end

local function RaceIcon(raceID, gender)
    if not raceID or not C_CreatureInfo or not C_CreatureInfo.GetRaceInfoEx then return nil, nil end
    local ok, _, raceFile, raceName = pcall(C_CreatureInfo.GetRaceInfoEx, raceID)
    if not ok or not raceFile then return nil, nil end
    local suffix = (S_GENDER_FILESTRING and S_GENDER_FILESTRING[gender]) or "MALE"
    return string.format("Interface\\Custom\\RaceIcon\\RACE_ICON_%s%s",
        string.upper(raceFile), suffix), raceName
end

local function FactionAtlas(factionID)
    if not factionID or not PLAYER_FACTION_GROUP then return nil, nil end
    local name = PLAYER_FACTION_GROUP[factionID]
    if not name then return nil, nil end

    local atlas =
        name == "Horde" and "objectivewidget-icon-right"
        or name == "Alliance" and "objectivewidget-icon-left"
        or name == "Renegade" and "objectivewidget-icon-Renegade"
        or "TargetingFrame-UI-PVP-FFA"

    return atlas, _G["FACTION_" .. string.upper(name)] or name
end

function Page:Bracket()
    for _, entry in ipairs(BRACKETS) do
        if entry.bracket == self.bracket then return entry end
    end
    return BRACKETS[1]
end

function Page:ValueLabel(entry)
    if entry.value == "kills" then return Global("RENEGADE_LADDER_KILLS", "Убийств") end
    if entry.value == "dps" then return Global("LADDER_DUMMY_DPS", "УВС") end
    if entry.value == "score" then return Global("LADDER_MYTHIC_PLUS_SCORE", "Счет") end
    return Global("PVP_LADDER_RATING", "Рейтинг")
end

function Page:EmptyText(entry)
    if self.tab == "search" then
        if self.searchText and self.searchText ~= "" then
            return Global("PVP_LADDER_SEARCH_NOT_RESULT", "Нам не удалось ничего найти по вашему запросу.")
        end
        if entry.value == "kills" then
            return Global("RENEGADE_LADDER_SEARCH_TUTORIAL", "Введите имя персонажа или его часть.")
        end
        if entry.value == "dps" then
            return Global("LADDER_DUMMY_SEARCH_TUTORIAL", "Введите имя персонажа или его часть.")
        end
        return Global("PVP_LADDER_SEARCH_TUTORIAL", "Введите имя персонажа или его часть.")
    end
    return Global("PVP_LADDER_SEARCH_NOT_RESULT", "Нам не удалось ничего найти по вашему запросу.")
end

function Page:NotRankedText(entry)
    if entry.value == "kills" then
        return Global("RENEGADE_LADDER_NOT_RANK", "Вы не попали в историю как Ренегат")
    end
    if entry.value == "dps" then
        return Global("LADDER_DUMMY_NOT_RANKED", "Запишите хотя бы один лог, чтобы занять место в таблице.")
    end
    return Global("PVP_LADDER_NOT_RANKING", "Сыграйте хотя бы одну игру в текущем сезоне.")
end

function Page:Count()
    if not Available() then return 0 end

    local bracket = self.bracket

    if self.tab == "search" then
        return C_Ladder.GetNumSearchResults and C_Ladder.GetNumSearchResults(bracket) or 0
    elseif self.tab == "class" then
        return C_Ladder.GetNumClassPlayers and C_Ladder.GetNumClassPlayers(bracket, self.classID) or 0
    end

    return C_Ladder.GetNumTopPlayers(bracket) or 0
end

function Page:Info(index)
    local bracket = self.bracket

    if self.tab == "search" then
        return C_Ladder.GetSearchResultPlayerInfo(bracket, index)
    elseif self.tab == "class" then
        return C_Ladder.GetClassPlayerInfo(bracket, self.classID, index)
    end

    return C_Ladder.GetTopPlayerInfo(bracket, index)
end

function Page:Request(force)
    if not Available() then return end

    local bracket = self.bracket

    if self.tab == "top" then
        local has, expired = C_Ladder.HasTopPlayerInfo(bracket)
        if force or expired or not has or C_Ladder.GetNumTopPlayers(bracket) == 0 then
            self.loading = true
            pcall(C_Ladder.RequestTopPlayers, bracket)
        end
    elseif self.tab == "class" then
        local has, expired = C_Ladder.HasClassPlayerInfo(bracket, self.classID)
        if force or expired or not has or C_Ladder.GetNumClassPlayers(bracket, self.classID) == 0 then
            self.loading = true
            pcall(C_Ladder.RequestClassPlayers, bracket, self.classID)
        end
    elseif self.tab == "search" and self.searchText and self.searchText ~= "" then
        self.loading = true
        pcall(C_Ladder.RequestSearch, bracket, self.searchText)
    end
end

function Page:SetBracket(bracket)
    if self.bracket == bracket then return end
    self.bracket = bracket
    self.offset = 0
    self.message = nil
    self:Request()
    self:Update()
end

function Page:SetTab(tab, classID)
    self.tab = tab
    self.classID = classID or self.classID
    self.offset = 0
    self.message = nil
    self:Request()
    self:Update()
end

function Page:CreateRail(f, panel)
    local S = NS.Styling
    local Caption = panel.Caption

    local caption = Caption(f, L["ТАБЛИЦЫ"])
    caption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    f.buttons = {}

    local y = -18
    local lastGroup

    for index, entry in ipairs(BRACKETS) do
        if lastGroup and entry.group ~= lastGroup then y = y - 10 end
        lastGroup = entry.group

        local button = CreateFrame("Button", nil, f)
        button:SetSize(RAIL_W, 34)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)

        local plate = button:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.55)
        button.plate = plate

        local glow = button:CreateTexture(nil, "BORDER")
        glow:SetAllPoints()
        glow:SetTexture(WHITE)
        glow:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
        glow:Hide()
        button.glow = glow

        local bar = button:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", button, "LEFT", 10, 0)
        SetIcon(icon, entry.atlas, entry.icon)
        button.icon = icon

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(12), "")
        label:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        label:SetWidth(RAIL_W - 52)
        label:SetJustifyH("LEFT")
        label:SetText(Global(entry.label, entry.fallback))
        button.label = label

        button:SetScript("OnEnter", function(self)
            if Page.bracket ~= entry.bracket then self.glow:Show() end
        end)
        button:SetScript("OnLeave", function(self)
            if Page.bracket ~= entry.bracket then self.glow:Hide() end
        end)
        button:SetScript("OnClick", function() Page:SetBracket(entry.bracket) end)

        f.buttons[index] = button
        y = y - 38
    end
end

function Page:CreateTabs(f, panel, x, width)
    local S = NS.Styling

    local function TextTab(text, key)
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(22)

        local plate = button:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(0.10, 0.11, 0.14, 0.85)
        button.plate = plate

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(text)
        button.label = label

        button:SetWidth(label:GetStringWidth() + 22)
        button:SetScript("OnClick", function() Page:SetTab(key) end)
        button.tabKey = key

        return button
    end

    f.tabs = {}
    f.tabs[1] = TextTab(Global("TOP_PLAYERS", "Топ игроков"), "top")
    f.tabs[1]:SetPoint("TOPLEFT", f, "TOPLEFT", x, -2)

    f.tabs[2] = TextTab(Global("SEARCH", "Поиск"), "search")
    f.tabs[2]:SetPoint("LEFT", f.tabs[1], "RIGHT", 6, 0)

    f.classTabs = {}

    local prev
    for index, classID in ipairs(CLASS_TABS) do
        local className, classFile = ClassInfo(classID)
        local button = CreateFrame("Button", nil, f)
        button:SetSize(22, 22)

        if index == 1 then
            button:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -2)
        else
            button:SetPoint("RIGHT", prev, "LEFT", -4, 0)
        end

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", -2, 2)
        icon:SetTexture(CLASS_ICONS)
        if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
            icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
        end
        button.icon = icon

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", 0, 0)
        border:SetPoint("BOTTOMRIGHT", 0, 0)
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(className or "")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnClick", function() Page:SetTab("class", classID) end)

        button.classID = classID
        f.classTabs[index] = button
        prev = button
    end

    local search = NS.Widgets.CreateThemedEditBox(f, 190, 20, 20)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", x, -30)
    search:SetScript("OnEnterPressed", function(self)
        Page.searchText = strtrim(self:GetText() or "")
        Page.message = nil
        Page:Request(true)
        Page:Update()
        self:ClearFocus()
    end)
    f.search = search

    local go = NS.Widgets.CreateThemedButton(f, Global("SEARCH", "Поиск"), 90, 20, function()
        Page.searchText = strtrim(f.search:GetText() or "")
        Page.message = nil
        Page:Request(true)
        Page:Update()
    end)
    go:SetPoint("LEFT", search, "RIGHT", 8, 0)
    f.go = go

    local refresh = NS.Widgets.CreateThemedButton(f, REFRESH or L["Обновить"], 100, 20, function()
        Page.message = nil
        Page:Request(true)
        Page:Update()
    end)
    refresh:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -30)
    f.refresh = refresh

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(13), "")
    title:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", x, -34)
    title:SetJustifyH("LEFT")
    f.title = title
end

function Page:CreateRow(parent, index, width)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -28 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -28 - (index - 1) * ROW_H)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

    local hover = row:CreateTexture(nil, "BORDER")
    hover:SetAllPoints()
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.14)
    hover:Hide()
    row.hover = hover

    local rank = row:CreateFontString(nil, "OVERLAY")
    rank:SetFont(NS.FONT, NS.FS(12), "")
    rank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    rank:SetPoint("LEFT", row, "LEFT", 8, 0)
    rank:SetWidth(38)
    rank:SetJustifyH("LEFT")
    row.rank = rank

    local race = row:CreateTexture(nil, "ARTWORK")
    race:SetSize(18, 18)
    race:SetPoint("LEFT", row, "LEFT", 46, 0)
    row.race = race

    local class = row:CreateTexture(nil, "ARTWORK")
    class:SetSize(16, 16)
    class:SetPoint("LEFT", race, "RIGHT", 4, 0)
    class:SetTexture(CLASS_ICONS)
    row.class = class

    local faction = row:CreateTexture(nil, "ARTWORK")
    faction:SetSize(15, 15)
    faction:SetPoint("LEFT", class, "RIGHT", 4, 0)
    row.faction = faction

    local zodiac = row:CreateTexture(nil, "ARTWORK")
    zodiac:SetSize(15, 15)
    zodiac:SetPoint("LEFT", faction, "RIGHT", 4, 0)
    row.zodiac = zodiac

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", zodiac, "RIGHT", 8, 0)
    name:SetWidth(width - 320)
    name:SetJustifyH("LEFT")
    row.name = name

    local games = row:CreateFontString(nil, "OVERLAY")
    games:SetFont(NS.FONT, NS.FS(11), "")
    games:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    games:SetPoint("RIGHT", row, "RIGHT", -110, 0)
    games:SetJustifyH("RIGHT")
    row.games = games

    local value = row:CreateFontString(nil, "OVERLAY")
    value:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    value:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    value:SetJustifyH("RIGHT")
    row.value = value

    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        Page:RowTooltip(self)
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
    end)

    row:Hide()
    return row
end

function Page:RowTooltip(row)
    if not row.playerName then return end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.playerName, ClassColor(row.classFile))

    if row.raceName then
        GameTooltip:AddLine(string.format("%s  %s", row.raceName, row.className or ""), 0.8, 0.8, 0.85)
    end
    if row.factionName then
        GameTooltip:AddLine(row.factionName, 0.7, 0.7, 0.75)
    end
    if row.zodiacName then
        GameTooltip:AddLine(row.zodiacName, 0.7, 0.7, 0.75)
    end

    if row.seasonGames then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(Global("PVP_LADDER_SEASON", "Сезон"),
            string.format("%d / %d", row.seasonWins or 0, row.seasonGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)
        GameTooltip:AddDoubleLine(Global("PVP_LADDER_WEEK", "Неделя"),
            string.format("%d / %d", row.weekWins or 0, row.weekGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)
        GameTooltip:AddDoubleLine(Global("PVP_LADDER_DAY", "День"),
            string.format("%d / %d", row.dayWins or 0, row.dayGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)
    end

    GameTooltip:Show()
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome
    local Caption = panel.Caption
    local _, _, _, _, pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -64)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.bracket = self.bracket or 0
    self.tab = self.tab or "top"
    self.classID = self.classID or 1
    self.offset = 0

    self:CreateRail(f, panel)

    local contentX = RAIL_W + 18
    local contentW = 824 - contentX

    self:CreateTabs(f, panel, contentX, contentW)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -58)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 52)
    Chrome(body)
    f.body = body

    local headRank = body:CreateFontString(nil, "OVERLAY")
    headRank:SetFont(NS.FONT, NS.FS(10), "")
    headRank:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headRank:SetPoint("TOPLEFT", body, "TOPLEFT", 16, -11)
    headRank:SetText("#")

    local headName = body:CreateFontString(nil, "OVERLAY")
    headName:SetFont(NS.FONT, NS.FS(10), "")
    headName:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headName:SetPoint("TOPLEFT", body, "TOPLEFT", 128, -11)
    headName:SetText(Global("CALENDAR_PLAYER_NAME", "Игрок"))

    local headGames = body:CreateFontString(nil, "OVERLAY")
    headGames:SetFont(NS.FONT, NS.FS(10), "")
    headGames:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headGames:SetPoint("TOPRIGHT", body, "TOPRIGHT", -118, -11)
    headGames:SetJustifyH("RIGHT")
    f.headGames = headGames

    local headValue = body:CreateFontString(nil, "OVERLAY")
    headValue:SetFont(NS.FONT, NS.FS(10), "")
    headValue:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headValue:SetPoint("TOPRIGHT", body, "TOPRIGHT", -18, -11)
    headValue:SetJustifyH("RIGHT")
    f.headValue = headValue

    local rule = body:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -25)
    rule:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -25)
    rule:SetTexture(WHITE)
    rule:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(body, index, contentW)
    end

    local message = body:CreateFontString(nil, "OVERLAY")
    message:SetFont(NS.FONT, NS.FS(12), "")
    message:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    message:SetPoint("TOPLEFT", body, "TOPLEFT", 16, -40)
    message:SetWidth(contentW - 40)
    message:SetJustifyH("LEFT")
    message:Hide()
    f.message = message

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local total = Page:Count()
        if total <= ROWS then return end
        Page.offset = math.max(0, math.min(total - ROWS, (Page.offset or 0) - delta))
        Page:Update()
    end)

    local own = CreateFrame("Frame", nil, f)
    own:SetHeight(42)
    own:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", contentX, 0)
    own:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    Chrome(own)
    f.own = own

    local ownCaption = Caption(own, L["ВАШЕ МЕСТО"])
    ownCaption:SetPoint("TOPLEFT", own, "TOPLEFT", 14, -8)

    local ownRank = own:CreateFontString(nil, "OVERLAY")
    ownRank:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    ownRank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    ownRank:SetPoint("LEFT", own, "LEFT", 110, 0)
    f.ownRank = ownRank

    local ownName = own:CreateFontString(nil, "OVERLAY")
    ownName:SetFont(NS.FONT, NS.FS(13), "")
    ownName:SetPoint("LEFT", ownRank, "RIGHT", 12, 0)
    f.ownName = ownName

    local ownValue = own:CreateFontString(nil, "OVERLAY")
    ownValue:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    ownValue:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    ownValue:SetPoint("RIGHT", own, "RIGHT", -18, 0)
    f.ownValue = ownValue

    local ownNote = own:CreateFontString(nil, "OVERLAY")
    ownNote:SetFont(NS.FONT, NS.FS(11), "")
    ownNote:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    ownNote:SetPoint("LEFT", own, "LEFT", 110, 0)
    ownNote:SetPoint("RIGHT", own, "RIGHT", -18, 0)
    ownNote:SetJustifyH("LEFT")
    f.ownNote = ownNote

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function(_, event, ...)
        Page:OnEvent(event, ...)
    end)

    if events.RegisterCustomEvent then
        for _, name in ipairs(EVENTS) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events
    f:Hide()

    return f
end

function Page:OnEvent(event, ...)
    self.loading = false

    if string.find(event, "SEARCH_ERROR") then
        local _, text = ...
        self.message = text
    elseif string.find(event, "SEARCH_DELAY") then
        self.message = Global("PVP_LADDER_SEARCH_DELAY", "Подождите некоторое время.")
    else
        self.message = nil
    end

    if self.frame and self.frame:IsShown() then self:Update() end
end

function Page:FillRow(row, index, entry)
    local rank, name, raceID, classID, gender, zodiacID, factionID, a, b, c, d, e, g, h = self:Info(index)

    if not name then
        row:Hide()
        return false
    end

    local className, classFile = ClassInfo(classID)

    row.rank:SetText(rank or index)
    row.name:SetText(name)
    row.name:SetTextColor(ClassColor(classFile))

    row.playerName = name
    row.classFile = classFile
    row.className = className

    local racePath, raceName = RaceIcon(raceID, gender)
    if racePath then
        row.race:SetTexture(racePath)
        row.race:Show()
    else
        row.race:Hide()
    end
    row.raceName = raceName

    if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
        row.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
        row.class:Show()
    else
        row.class:Hide()
    end

    local atlas, factionName = FactionAtlas(factionID)
    if atlas and row.faction.SetAtlas and C_Texture and C_Texture.HasAtlasInfo
        and select(2, pcall(C_Texture.HasAtlasInfo, atlas)) then
        pcall(row.faction.SetAtlas, row.faction, atlas)
        row.faction:Show()
    else
        row.faction:Hide()
    end
    row.factionName = factionName

    row.zodiacName = nil
    if zodiacID and C_ZodiacSign and C_ZodiacSign.GetZodiacSignInfo then
        local ok, _, zodiacName, _, zodiacIcon = pcall(C_ZodiacSign.GetZodiacSignInfo, zodiacID)
        if ok and zodiacIcon then
            row.zodiac:SetTexture(zodiacIcon)
            row.zodiac:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.zodiac:Show()
            row.zodiacName = zodiacName
        else
            row.zodiac:Hide()
        end
    else
        row.zodiac:Hide()
    end

    row.seasonGames = nil

    if entry.value == "rating" then
        row.value:SetText(a or 0)
        row.seasonGames, row.weekGames, row.dayGames = b, c, d
        row.seasonWins, row.weekWins, row.dayWins = e, g, h
        row.games:SetText(string.format("%d / %d", e or 0, b or 0))
    elseif entry.value == "dps" then
        row.value:SetText(string.format("%.0f", b or 0))
        row.games:SetText("")
    else
        row.value:SetText(a or 0)
        row.games:SetText("")
    end

    row:Show()
    return true
end

function Page:UpdateOwn(entry)
    local f = self.frame
    local rank, name, raceID, classID, gender, zodiacID, factionID, a, b, _, _, e

    if Available() and C_Ladder.GetNumPersonalRecords and C_Ladder.GetNumPersonalRecords(entry.bracket) > 0 then
        rank, name, raceID, classID, gender, zodiacID, factionID, a, b, _, _, e =
            C_Ladder.GetPersonalRecordInfo(entry.bracket, 1)
    end

    if rank and name then
        local className, classFile = ClassInfo(classID)

        f.ownRank:SetText("#" .. rank)
        f.ownName:SetText(name)
        f.ownName:SetTextColor(ClassColor(classFile))

        if entry.value == "rating" then
            f.ownValue:SetText(string.format("%s: %s   %s: %d / %d",
                self:ValueLabel(entry), a or 0,
                Global("PVP_LADDER_SEASON", "Сезон"), e or 0, b or 0))
        elseif entry.value == "dps" then
            f.ownValue:SetText(string.format("%s: %.0f", self:ValueLabel(entry), b or 0))
        else
            f.ownValue:SetText(string.format("%s: %s", self:ValueLabel(entry), a or 0))
        end

        f.ownRank:Show()
        f.ownName:Show()
        f.ownValue:Show()
        f.ownNote:Hide()
    else
        f.ownRank:Hide()
        f.ownName:Hide()
        f.ownValue:Hide()
        f.ownNote:Show()
        f.ownNote:SetText(self:NotRankedText(entry))
    end
end

function Page:Update()
    if not self.frame then return end

    local S = NS.Styling
    local f = self.frame
    local entry = self:Bracket()

    for index, button in ipairs(f.buttons) do
        local active = BRACKETS[index].bracket == self.bracket
        button.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], active and 0.9 or 0.55)
        button.bar:SetShown(active)
        button.glow:SetShown(active)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_NORMAL[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_NORMAL[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_NORMAL[3])
    end

    for _, button in ipairs(f.tabs) do
        local active = button.tabKey == self.tab
        button.border:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or 0.9)
        button.plate:SetVertexColor(
            active and S.ACCENT[1] or 0.10,
            active and S.ACCENT[2] or 0.11,
            active and S.ACCENT[3] or 0.14, active and 0.18 or 0.85)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_DIM[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_DIM[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_DIM[3])
    end

    for _, button in ipairs(f.classTabs) do
        local active = self.tab == "class" and button.classID == self.classID
        button.border:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or 0.9)
        button.icon:SetDesaturated(not active and self.tab == "class")
        button.icon:SetAlpha(active and 1 or 0.75)
    end

    local searching = self.tab == "search"
    f.search:SetShown(searching)
    f.go:SetShown(searching)
    f.title:SetShown(not searching)

    if self.tab == "class" then
        local className = ClassInfo(self.classID)
        f.title:SetText(className or "")
    else
        f.title:SetText(Global("TOP_PLAYERS", "Топ игроков"))
    end

    f.headValue:SetText(self:ValueLabel(entry))
    f.headGames:SetText(entry.value == "rating"
        and string.format("%s / %s", Global("PVP_LADDER_TOTAL_WINS", "Побед"), L["игр"]) or "")

    if not Available() then
        for _, row in ipairs(f.rows) do row:Hide() end
        f.message:Show()
        f.message:SetText(L["таблицы лидеров недоступны на этом сервере"])
        f.own:Hide()
        return
    end

    f.own:Show()

    local total = self:Count()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, total - ROWS)))
    self.offset = offset

    local shown = 0
    for index = 1, ROWS do
        local row = f.rows[index]
        if index + offset <= total and self:FillRow(row, index + offset, entry) then
            shown = shown + 1
        else
            row:Hide()
        end
    end

    if total == 0 then
        f.message:Show()
        if self.message then
            f.message:SetText(self.message)
        elseif self.loading then
            f.message:SetText(L["запрос отправлен, ждем ответ сервера"])
        else
            f.message:SetText(self:EmptyText(entry))
        end
    else
        f.message:Hide()
    end

    self:UpdateOwn(entry)
end

function Page:Show()
    if not self.frame then return end

    self:Request()
    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if self.frame then self.frame:Hide() end
end

NS.LadderPage = Page
