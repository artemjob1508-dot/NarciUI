local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local FALLBACK_ICON = "Interface\\Icons\\achievement_bg_wineos_underxminutes"

local LEFT_W = 322
local ROW_H = 30
local ROWS = 9

NS.Densify("NarcissusSirus_GroupFinder", function(f)
    ROW_H, ROWS = NS.DensityRows(30, 9, f)
end)
local MAX_AFFIXES = 5
local VAULT_ROWS = 3

local function Available()
    return C_ChallengeMode and C_MythicPlus and C_ChallengeMode.GetMapTable
end

local function Call(namespace, method, ...)
    if not namespace or not namespace[method] then return nil end
    local results = { pcall(namespace[method], ...) }
    if not results[1] then return nil end
    return unpack(results, 2)
end

local function RarityColor(color)
    if not color then return nil end
    if color.GetRGB then return color:GetRGB() end
    return color.r, color.g, color.b
end

local function LevelColor(level)
    if not level or level <= 0 then return 0.45, 0.45, 0.48 end
    local r, g, b = RarityColor(Call(C_ChallengeMode, "GetKeystoneLevelRarityColor", level))
    if r then return r, g, b end
    return 0.9, 0.9, 0.95
end

local function ScoreColor(score)
    if not score or score <= 0 then return 0.45, 0.45, 0.48 end
    local r, g, b = RarityColor(Call(C_ChallengeMode, "GetDungeonScoreRarityColor", score))
    if r then return r, g, b end
    return 0.9, 0.9, 0.95
end

local function MapScoreColor(score)
    if not score or score <= 0 then return 0.45, 0.45, 0.48 end
    local r, g, b = RarityColor(Call(C_ChallengeMode, "GetSpecificDungeonScoreRarityColor", score))
    if r then return r, g, b end
    return 0.9, 0.9, 0.95
end

local function Duration(seconds)
    if not seconds or seconds <= 0 then return "-" end
    return SecondsToTime(seconds, true, false, 2)
end

function Page:Maps()
    local list = {}
    if not Available() then return list end

    for _, mapID in ipairs(C_ChallengeMode.GetMapTable() or {}) do
        local name, _, timeLimit, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        local inTime, overtime = C_MythicPlus.GetSeasonBestForMap(mapID)
        local weeklyTime, weeklyLevel = C_MythicPlus.GetWeeklyBestForMap(mapID)
        local _, score = Call(C_MythicPlus, "GetSeasonBestAffixScoreInfoForMap", mapID)

        list[#list + 1] = {
            id = mapID,
            name = name or ("#" .. mapID),
            texture = texture or FALLBACK_ICON,
            timeLimit = timeLimit,
            best = inTime and inTime.level or (overtime and overtime.level) or 0,
            bestTime = inTime and inTime.durationSec or (overtime and overtime.durationSec),
            inTime = inTime and true or false,
            weekly = weeklyLevel or 0,
            weeklyTime = weeklyTime,
            score = score or 0,
        }
    end

    table.sort(list, function(left, right)
        if left.best ~= right.best then return left.best > right.best end
        return left.name < right.name
    end)

    return list
end

function Page:AffixTile(parent, size)
    local S = NS.Styling

    local tile = CreateFrame("Frame", nil, parent)
    tile:SetSize(size, size)

    local icon = tile:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tile.icon = icon

    local border = CreateFrame("Frame", nil, tile)
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    tile.border = border

    tile:EnableMouse(true)
    tile:SetScript("OnEnter", function(self)
        if not self.affixID then return end
        local name, description = C_ChallengeMode.GetAffixInfo(self.affixID)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(name or "", 1, 1, 1)
        if self.requiredLevel then
            GameTooltip:AddLine(string.format(L["действует с уровня %d"], self.requiredLevel),
                0.55, 0.78, 0.58)
        end
        if description then
            GameTooltip:AddLine(description, 0.9, 0.9, 0.9, true)
        end
        GameTooltip:Show()
    end)
    tile:SetScript("OnLeave", function() GameTooltip:Hide() end)

    function tile:SetAffix(affixID, requiredLevel, active)
        self.affixID = affixID
        self.requiredLevel = requiredLevel

        local _, _, texture = C_ChallengeMode.GetAffixInfo(affixID)
        self.icon:SetTexture(texture or FALLBACK_ICON)
        self.icon:SetDesaturated(not active)

        if active then
            self.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        else
            self.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        end

        self:Show()
    end

    return tile
end

function Page:CreateKeystone(f, panel, width)
    local S = NS.Styling
    local Chrome = panel.Chrome
    local Caption = panel.Caption

    local caption = Caption(f, L["ВАШ КЛЮЧ"])
    caption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

    local box = CreateFrame("Frame", nil, f)
    box:SetSize(width, 104)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -16)
    Chrome(box)
    f.keystone = box

    local icon = box:CreateTexture(nil, "ARTWORK")
    icon:SetSize(56, 40)
    icon:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -12)
    icon:SetTexCoord(0.06, 0.94, 0.12, 0.88)
    box.icon = icon

    local iconBorder = CreateFrame("Frame", nil, box)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    iconBorder:SetBackdropBorderColor(0, 0, 0, 0.85)
    iconBorder:EnableMouse(false)
    box.iconBorder = iconBorder

    local name = box:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(13), "")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    name:SetWidth(width - 96)
    name:SetJustifyH("LEFT")
    box.name = name

    local level = box:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(20), "OUTLINE")
    level:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    box.level = level

    local timer = box:CreateFontString(nil, "OVERLAY")
    timer:SetFont(NS.FONT, NS.FS(11), "")
    timer:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    timer:SetPoint("LEFT", level, "RIGHT", 10, 0)
    box.timer = timer

    box.affixes = {}
    for index = 1, MAX_AFFIXES do
        local tile = self:AffixTile(box, 22)
        if index == 1 then
            tile:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 12, 10)
        else
            tile:SetPoint("LEFT", box.affixes[index - 1], "RIGHT", 6, 0)
        end
        tile:Hide()
        box.affixes[index] = tile
    end

    local empty = box:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("LEFT", box, "LEFT", 14, 0)
    empty:SetWidth(width - 28)
    empty:SetJustifyH("LEFT")
    empty:Hide()
    box.empty = empty
end

function Page:CreateScore(f, panel, width)
    local S = NS.Styling
    local Chrome = panel.Chrome
    local Caption = panel.Caption

    local caption = Caption(f, L["РЕЙТИНГ"])
    caption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -128)

    local box = CreateFrame("Frame", nil, f)
    box:SetSize(width, 96)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -144)
    Chrome(box)
    f.score = box

    local value = box:CreateFontString(nil, "OVERLAY")
    value:SetFont(NS.FONT, NS.FS(24), "OUTLINE")
    value:SetPoint("TOPLEFT", box, "TOPLEFT", 14, -12)
    box.value = value

    local valueLabel = box:CreateFontString(nil, "OVERLAY")
    valueLabel:SetFont(NS.FONT, NS.FS(10), "")
    valueLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    valueLabel:SetPoint("LEFT", value, "RIGHT", 10, -2)
    valueLabel:SetText(L["общий счет"])

    local season = box:CreateFontString(nil, "OVERLAY")
    season:SetFont(NS.FONT, NS.FS(11), "")
    season:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    season:SetPoint("TOPRIGHT", box, "TOPRIGHT", -14, -16)
    season:SetJustifyH("RIGHT")
    box.season = season

    local weeks = box:CreateFontString(nil, "OVERLAY")
    weeks:SetFont(NS.FONT, NS.FS(11), "")
    weeks:SetPoint("TOPLEFT", box, "TOPLEFT", 14, -50)
    weeks:SetWidth(width - 28)
    weeks:SetJustifyH("LEFT")
    box.weeks = weeks

    local runs = box:CreateFontString(nil, "OVERLAY")
    runs:SetFont(NS.FONT, NS.FS(11), "")
    runs:SetPoint("TOPLEFT", weeks, "BOTTOMLEFT", 0, -4)
    runs:SetWidth(width - 28)
    runs:SetJustifyH("LEFT")
    box.runs = runs
end

function Page:CreateVault(f, panel, width)
    local S = NS.Styling
    local Chrome = panel.Chrome
    local Caption = panel.Caption

    local caption = Caption(f, L["НАГРАДА НЕДЕЛИ"])
    caption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -252)

    local box = CreateFrame("Frame", nil, f)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -268)
    box:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    box:SetWidth(width)
    Chrome(box)
    f.vault = box

    local status = box:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    status:SetPoint("TOPLEFT", box, "TOPLEFT", 14, -12)
    status:SetWidth(width - 28)
    status:SetJustifyH("LEFT")
    box.status = status

    box.rows = {}
    for index = 1, VAULT_ROWS do
        local row = CreateFrame("Button", nil, box)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -62 - (index - 1) * 28)
        row:SetPoint("TOPRIGHT", box, "TOPRIGHT", -12, -62 - (index - 1) * 28)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.5)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon = icon

        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        label:SetWidth(width - 110)
        label:SetJustifyH("LEFT")
        row.label = label

        local progress = row:CreateFontString(nil, "OVERLAY")
        progress:SetFont(NS.FONT, NS.FS(11), "")
        progress:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        progress:SetJustifyH("RIGHT")
        row.progress = progress

        row:SetScript("OnEnter", function(self)
            if not self.itemLink and not self.itemID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink or ("item:" .. self.itemID))
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        box.rows[index] = row
    end
end

function Page:CreateRow(parent, index, width)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -30 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -30 - (index - 1) * ROW_H)

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

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 22)
    icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    icon:SetTexCoord(0.06, 0.94, 0.12, 0.88)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:SetWidth(width - 300)
    name:SetJustifyH("LEFT")
    row.name = name

    local limit = row:CreateFontString(nil, "OVERLAY")
    limit:SetFont(NS.FONT, NS.FS(11), "")
    limit:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    limit:SetPoint("RIGHT", row, "RIGHT", -206, 0)
    limit:SetJustifyH("RIGHT")
    row.limit = limit

    local weekly = row:CreateFontString(nil, "OVERLAY")
    weekly:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    weekly:SetPoint("RIGHT", row, "RIGHT", -142, 0)
    weekly:SetJustifyH("RIGHT")
    row.weekly = weekly

    local best = row:CreateFontString(nil, "OVERLAY")
    best:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    best:SetPoint("RIGHT", row, "RIGHT", -78, 0)
    best:SetJustifyH("RIGHT")
    row.best = best

    local score = row:CreateFontString(nil, "OVERLAY")
    score:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    score:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    score:SetJustifyH("RIGHT")
    row.score = score

    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        if not self.map then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.map.name, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["лимит времени"], Duration(self.map.timeLimit), 0.8, 0.8, 0.85, 1, 1, 1)

        if self.map.best > 0 then
            GameTooltip:AddDoubleLine(L["рекорд сезона"],
                string.format("+%d  %s", self.map.best, Duration(self.map.bestTime)),
                0.8, 0.8, 0.85, LevelColor(self.map.best))
            GameTooltip:AddLine(self.map.inTime and L["уложились в лимит"] or L["время превышено"],
                self.map.inTime and 0.4 or 0.85, self.map.inTime and 0.85 or 0.4, 0.4)
        end

        if self.map.weekly > 0 then
            GameTooltip:AddDoubleLine(CHALLENGE_MODE_THIS_WEEK or L["На этой неделе"],
                string.format("+%d  %s", self.map.weekly, Duration(self.map.weeklyTime)),
                0.8, 0.8, 0.85, LevelColor(self.map.weekly))
        end

        if self.map.score > 0 then
            GameTooltip:AddLine(string.format(DUNGEON_SCORE_TOTAL_SCORE or L["Счет: %s"], self.map.score),
                MapScoreColor(self.map.score))
        end

        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
    end)

    row:Hide()
    return row
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome
    local Caption = panel.Caption
    local _, _, _, _, pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -86)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.offset = 0

    local season = f:CreateFontString(nil, "OVERLAY")
    season:SetFont(NS.FONT, NS.FS(12), "")
    season:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    season:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 6)
    season:SetWidth(560)
    season:SetJustifyH("LEFT")
    f.seasonText = season

    local seasonRuns = f:CreateFontString(nil, "OVERLAY")
    seasonRuns:SetFont(NS.FONT, NS.FS(11), "")
    seasonRuns:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    seasonRuns:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 6)
    seasonRuns:SetJustifyH("RIGHT")
    f.seasonRuns = seasonRuns

    self:CreateKeystone(f, panel, LEFT_W)
    self:CreateScore(f, panel, LEFT_W)
    self:CreateVault(f, panel, LEFT_W)

    local rightX = LEFT_W + 18
    local rightW = 824 - rightX

    local affixCaption = Caption(f, L["АФФИКСЫ НЕДЕЛИ"])
    affixCaption:SetPoint("TOPLEFT", f, "TOPLEFT", rightX, 0)

    local affixBox = CreateFrame("Frame", nil, f)
    affixBox:SetSize(rightW, 76)
    affixBox:SetPoint("TOPLEFT", f, "TOPLEFT", rightX, -16)
    Chrome(affixBox)
    f.affixBox = affixBox

    f.affixes = {}
    f.affixNames = {}
    f.affixLevels = {}

    for index = 1, MAX_AFFIXES do
        local tile = self:AffixTile(affixBox, 38)
        tile:SetPoint("TOPLEFT", affixBox, "TOPLEFT", 12 + (index - 1) * 94, -18)

        local name = affixBox:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(11), "")
        name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        name:SetPoint("TOPLEFT", tile, "TOPRIGHT", 8, -2)
        name:SetWidth(46)
        name:SetJustifyH("LEFT")

        local level = affixBox:CreateFontString(nil, "OVERLAY")
        level:SetFont(NS.FONT, NS.FS(10), "")
        level:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        level:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        level:SetWidth(46)
        level:SetJustifyH("LEFT")

        tile:Hide()
        name:Hide()
        level:Hide()

        f.affixes[index] = tile
        f.affixNames[index] = name
        f.affixLevels[index] = level
    end

    local listCaption = Caption(f, L["ПОДЗЕМЕЛЬЯ"])
    listCaption:SetPoint("TOPLEFT", f, "TOPLEFT", rightX, -104)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", rightX, -120)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    Chrome(body)
    f.body = body

    local headLimit = body:CreateFontString(nil, "OVERLAY")
    headLimit:SetFont(NS.FONT, NS.FS(10), "")
    headLimit:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headLimit:SetPoint("TOPRIGHT", body, "TOPRIGHT", -214, -12)
    headLimit:SetText(L["лимит"])

    local headWeekly = body:CreateFontString(nil, "OVERLAY")
    headWeekly:SetFont(NS.FONT, NS.FS(10), "")
    headWeekly:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headWeekly:SetPoint("TOPRIGHT", body, "TOPRIGHT", -150, -12)
    headWeekly:SetText(L["неделя"])

    local headBest = body:CreateFontString(nil, "OVERLAY")
    headBest:SetFont(NS.FONT, NS.FS(10), "")
    headBest:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headBest:SetPoint("TOPRIGHT", body, "TOPRIGHT", -86, -12)
    headBest:SetText(L["сезон"])

    local headScore = body:CreateFontString(nil, "OVERLAY")
    headScore:SetFont(NS.FONT, NS.FS(10), "")
    headScore:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headScore:SetPoint("TOPRIGHT", body, "TOPRIGHT", -18, -12)
    headScore:SetText(L["счет"])

    local rule = body:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -26)
    rule:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -26)
    rule:SetTexture(WHITE)
    rule:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(body, index, rightW)
    end

    local empty = body:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOPLEFT", body, "TOPLEFT", 14, -40)
    empty:SetWidth(rightW - 40)
    empty:SetJustifyH("LEFT")
    empty:Hide()
    f.empty = empty

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local total = #Page:Maps()
        if total <= ROWS then return end
        Page.offset = math.max(0, math.min(total - ROWS, (Page.offset or 0) - delta))
        Page:Update()
    end)

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        for _, name in ipairs({ "MYTHIC_PLUS_OWNED_KEYSTONE_UPDATE", "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE",
            "CHALLENGE_MODE_MAPS_UPDATE", "MYTHIC_PLUS_PLAYER_SCORE_UPDATE" }) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events
    f:Hide()

    return f
end

function Page:UpdateSeason()
    local f = self.frame
    local currentSeason, currentWeek = Call(C_MythicPlus, "GetCurrentSeason")

    if not currentSeason then
        f.seasonText:SetText(MYTHIC_PLUS_TAB_NAME or L["Эпохальные подземелья"])
    else
        local timeLeft = Call(C_MythicPlus, "GetSeasonTimeLeft") or 0
        local tail = timeLeft > 0 and SecondsToTime(timeLeft, true, false, 2)
            or (CHALLENGE_MODE_SEASON_ENDED or L["Сезон окончен"])
        local template = MYTHIC_DUNGEON_SEASON or L["Неделя %d, сезон %d (%s)"]
        f.seasonText:SetText(string.format(template, currentWeek or 0, currentSeason or 0, tail))
    end

    local runs = Call(C_MythicPlus, "GetRunHistory", false, false)
    f.seasonRuns:SetText(string.format(L["прохождений на этой неделе: %d"], runs and #runs or 0))
end

function Page:UpdateKeystone()
    local box = self.frame.keystone
    local _, mapID, level, affixIDs = Call(C_MythicPlus, "GetOwnerKeystoneInfo")

    if not mapID then
        box.icon:Hide()
        box.iconBorder:Hide()
        box.name:Hide()
        box.level:Hide()
        box.timer:Hide()
        for _, tile in ipairs(box.affixes) do tile:Hide() end
        box.empty:Show()
        box.empty:SetText(L["ключа нет, пройдите эпохальное подземелье чтобы получить его"])
        return
    end

    local name, _, timeLimit, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)

    box.icon:SetTexture(texture or FALLBACK_ICON)
    box.icon:Show()
    box.iconBorder:Show()

    box.name:SetText(name or "")
    box.name:Show()

    box.level:SetText("+" .. (level or 0))
    box.level:SetTextColor(LevelColor(level))
    box.level:Show()

    local keystoneTime = Call(C_MythicPlus, "GetOwnerKeystoneTime")
    if keystoneTime and keystoneTime > 0 then
        box.timer:SetText(string.format(L["действует еще %s"], SecondsToTime(keystoneTime, true, false, 1)))
    else
        box.timer:SetText(string.format("%s %s", L["лимит времени"], Duration(timeLimit)))
    end
    box.timer:Show()

    for index, tile in ipairs(box.affixes) do
        local affixID = affixIDs and affixIDs[index]
        if affixID then
            tile:SetAffix(affixID, nil, true)
        else
            tile:Hide()
        end
    end

    box.empty:Hide()
end

function Page:UpdateScore()
    local box = self.frame.score
    local overall = Call(C_ChallengeMode, "GetOverallDungeonScore") or 0

    box.value:SetText(overall)
    box.value:SetTextColor(ScoreColor(overall))

    local bestSeasonScore, bestSeasonNumber = Call(C_MythicPlus, "GetSeasonBestMythicRating")
    if bestSeasonScore and bestSeasonScore > 0 then
        box.season:SetText(string.format(L["лучший сезон %d: %d"], bestSeasonNumber or 0, bestSeasonScore))
    else
        box.season:SetText("")
    end

    local qualifiedWeeks, qualifiedWeekRuns, qualifiedWeeksRequired, qualifiedWeeksMax, requiredRuns =
        Call(C_MythicPlus, "GetQualificationInfo")

    if qualifiedWeeks and qualifiedWeeksRequired and requiredRuns then
        local weeksDone = qualifiedWeeks >= qualifiedWeeksRequired
        local runsDone = qualifiedWeekRuns >= requiredRuns

        box.weeks:SetText(string.format(CHALLENGE_MODE_QUALIFICATION_PROGRESS_WEEKS or L["квалификация: %d из %d"],
            math.min(qualifiedWeeks, qualifiedWeeksRequired), qualifiedWeeksRequired))
        box.weeks:SetTextColor(weeksDone and 0.4 or 0.9, weeksDone and 0.85 or 0.9, weeksDone and 0.4 or 0.95)
        box.weeks:Show()

        box.runs:SetText(string.format(CHALLENGE_MODE_QUALIFICATION_PROGRESS_RUNS or L["текущая неделя: %d из %d"],
            math.min(qualifiedWeekRuns, requiredRuns), requiredRuns))
        box.runs:SetTextColor(runsDone and 0.4 or 0.9, runsDone and 0.85 or 0.9, runsDone and 0.4 or 0.95)
        box.runs:Show()
    else
        box.weeks:Hide()
        box.runs:Hide()
    end
end

function Page:UpdateVault()
    local S = NS.Styling
    local box = self.frame.vault

    local canClaim = Call(C_MythicPlus, "CanClaimRewards")
    local available = Call(C_MythicPlus, "IsWeeklyRewardAvailable")
    local bestRuns = Call(C_MythicPlus, "GetLastWeeklyBestRuns")

    local status
    if canClaim then
        status = MYTHIC_PLUS_CHOOSE_REWARD_MESSAGE or L["Вы можете выбрать только одну награду."]
    elseif available then
        status = MYTHIC_PLUS_CLAIM_REWARD_MESSAGE or L["Вам стал доступен сундук с трофеями."]
    else
        status = MYTHIC_PLUS_INCOMPLETE_WEEKLY_KEYSTONE
            or L["Завершайте подземелья с эпохальным ключом, чтобы получить сундук."]
    end

    box.status:SetText(string.format("%s\n%s: %d", status,
        L["зачтено прохождений"], bestRuns and #bestRuns or 0))

    local info = Call(C_MythicPlus, "GetWeeklyChestVaultInfo") or {}

    for index, row in ipairs(box.rows) do
        local vault = info[index]
        if vault then
            row.itemID = vault.itemID
            row.itemLink = nil

            local label = string.format(L["%d прохождений"], vault.threshold)

            if vault.itemID then
                local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(vault.itemID)
                row.icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_Bag_10")
                row.itemLink = itemLink
                if itemName then label = itemName end
            else
                row.icon:SetTexture("Interface\\Icons\\INV_Box_01")
            end

            row.label:SetText(label)
            row.progress:SetText(string.format("%d / %d", vault.progress or 0, vault.threshold))

            if vault.isCompleted then
                row.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                row.progress:SetTextColor(0.4, 0.85, 0.45)
                row.icon:SetDesaturated(false)
            else
                row.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                row.progress:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                row.icon:SetDesaturated(true)
            end

            row:Show()
        else
            row:Hide()
        end
    end
end

function Page:UpdateAffixes()
    local f = self.frame
    local affixes = Call(C_MythicPlus, "GetCurrentAffixes") or {}
    local _, _, keystoneLevel = Call(C_MythicPlus, "GetOwnerKeystoneInfo")

    for index = 1, MAX_AFFIXES do
        local affix = affixes[index]
        local tile, name, level = f.affixes[index], f.affixNames[index], f.affixLevels[index]

        if affix then
            local active = keystoneLevel and affix.requiredLevel and affix.requiredLevel <= keystoneLevel
            tile:SetAffix(affix.id, affix.requiredLevel, active and true or false)

            local affixName = C_ChallengeMode.GetAffixInfo(affix.id)
            name:SetText(affixName or "")
            name:Show()

            level:SetText(string.format(L["с уровня %d"], affix.requiredLevel or 0))
            level:Show()
        else
            tile:Hide()
            name:Hide()
            level:Hide()
        end
    end
end

function Page:Update()
    if not self.frame then return end

    local f = self.frame

    if not Available() then
        for _, row in ipairs(f.rows) do row:Hide() end
        f.empty:Show()
        f.empty:SetText(L["эпохальные подземелья недоступны на этом сервере"])
        return
    end

    self:UpdateSeason()
    self:UpdateKeystone()
    self:UpdateScore()
    self:UpdateVault()
    self:UpdateAffixes()

    local maps = self:Maps()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #maps - ROWS)))
    self.offset = offset

    for index = 1, ROWS do
        local row = f.rows[index]
        local map = maps[index + offset]

        if map then
            row.map = map
            row.icon:SetTexture(map.texture)
            row.icon:SetDesaturated(map.best == 0)
            row.name:SetText(map.name)
            row.limit:SetText(Duration(map.timeLimit))

            if map.weekly > 0 then
                row.weekly:SetText("+" .. map.weekly)
                row.weekly:SetTextColor(LevelColor(map.weekly))
            else
                row.weekly:SetText("-")
                row.weekly:SetTextColor(0.4, 0.4, 0.44)
            end

            if map.best > 0 then
                row.best:SetText("+" .. map.best)
                row.best:SetTextColor(LevelColor(map.best))
            else
                row.best:SetText("-")
                row.best:SetTextColor(0.4, 0.4, 0.44)
            end

            if map.score > 0 then
                row.score:SetText(map.score)
                row.score:SetTextColor(MapScoreColor(map.score))
            else
                row.score:SetText("-")
                row.score:SetTextColor(0.4, 0.4, 0.44)
            end

            row:Show()
        else
            row:Hide()
        end
    end

    if #maps == 0 then
        f.empty:Show()
        f.empty:SetText(L["сервер еще не прислал список подземелий"])
    else
        f.empty:Hide()
    end
end

function Page:Show()
    if not self.frame then return end

    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        pcall(C_MythicPlus.RequestMapInfo)
    end
    if C_MythicPlus and C_MythicPlus.RequestVaultRewards then
        pcall(C_MythicPlus.RequestVaultRewards)
    end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if self.frame then self.frame:Hide() end
end

NS.MythicPlusPage = Page
