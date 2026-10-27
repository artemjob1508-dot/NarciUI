local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local BRAWL_ID = 63
local WINTERGRASP_ID = 0
local RAIL_W = 196
local ROW_H = 34
local ROWS = 6

NS.Densify("NarcissusSirus_GroupFinder", function(f)
    ROW_H, ROWS = NS.DensityRows(34, 6, f)
end)
local STAT_ROWS = 8

local CONQUEST_SIZES = { 1, 2, 3 }
local ARENA_BRACKETS = {
    { id = 2, container = "rated" },
    { id = 5, container = "rated" },
    { id = 1, container = "solo" },
}
local SKIRMISH_BRACKETS = { 2, 5 }

local CATEGORIES = {
    {
        key = "service",
        label = "PVP_TAB_SERVICES", fallback = "Служба",
        icon = "Interface\\Icons\\Achievement_ChallengeMode_StormstoutBrewery_Bronze",
    },
    {
        key = "conquest",
        label = "PVP_TAB_CONQUEST", fallback = "Рейтинговые",
        icon = "Interface\\Icons\\achievement_bg_killxenemies_generalsroom",
        currency = "arena",
    },
    {
        key = "honor",
        label = "HONOR_CONTRIBUTION_POINTS", fallback = "Честь",
        icon = "Interface\\Icons\\achievement_bg_winwsg",
        currency = "honor",
    },
}

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Call(namespace, method, ...)
    if not namespace or not namespace[method] then return nil end
    local results = { pcall(namespace[method], ...) }
    if not results[1] then return nil end
    return unpack(results, 2)
end

local function FactionName()
    if C_Unit and C_Unit.GetFactionID and PLAYER_FACTION_GROUP then
        local factionID = Call(C_Unit, "GetFactionID", "player")
        local name = factionID and PLAYER_FACTION_GROUP[factionID]
        if name then return name end
    end
    return UnitFactionGroup("player") or "Alliance"
end

local function Enable(button, enabled)
    button:EnableMouse(enabled and true or false)
    button:SetAlpha(enabled and 1 or 0.4)
end

local function IsNeutral()
    if C_Unit and C_Unit.IsNeutral then
        return Call(C_Unit, "IsNeutral", "player") and true or false
    end
    return false
end

local function Battlegrounds()
    local list = {}

    for index = 1, (GetNumBattlegroundTypes and GetNumBattlegroundTypes() or 0) do
        local name, canEnter, isHoliday, isRandom, battlegroundID = GetBattlegroundInfo(index)
        if name then
            list[#list + 1] = {
                index = index,
                id = battlegroundID,
                name = name,
                canEnter = canEnter,
                isHoliday = isHoliday,
                isRandom = isRandom,
            }
        end
    end

    return list
end

function Page:RandomIndex()
    for _, entry in ipairs(Battlegrounds()) do
        if entry.isRandom and not entry.isHoliday then return entry.index end
    end
end

function Page:Specific()
    local list = {}

    for _, entry in ipairs(Battlegrounds()) do
        if entry.canEnter and not entry.isRandom then
            local gameType, description, maxPlayers, icon, _, isHidden =
                Call(C_PvP, "GetBattlegroundInfoEx", entry.id)

            if not isHidden then
                entry.gameType = gameType
                entry.description = description
                entry.maxPlayers = maxPlayers
                entry.icon = icon
                list[#list + 1] = entry
            end
        end
    end

    return list
end

function Page:SelectedArena()
    if self.arenaMode == "skirmish" then return self.skirmishID end
    return self.arenaID
end

function Page:CanQueueHonor()
    if IsNeutral() then return false end

    if self.honorMode == "specific" then
        return self.specificIndex and true or false
    end

    local selected = self.bonusID
    if not selected then return false end

    if selected == WINTERGRASP_ID then
        return Call(C_PvP, "CanRegisterWintergrasp") and true or false
    elseif selected == BRAWL_ID then
        return UnitLevel("player") == 80
    end

    return true
end

function Page:QueueHonor(isParty, forceSolo)
    if not isParty and not forceSolo and GetNumPartyMembers() > 1 then
        NS.Widgets.ShowConfirm(Global("CONFIRM_JOIN_SOLO", "Вы уверены, что хотите встать в очередь одни?"),
            YES or L["Да"], function() Page:QueueHonor(false, true) end)
        return
    end

    if self.honorMode == "specific" and self.specificIndex then
        RequestBattlegroundInstanceInfo(self.specificIndex)
        JoinBattlefield(self.specificIndex, isParty)
        return
    end

    if self.honorMode ~= "bonus" or not self.bonusID then return end

    if self.bonusID == WINTERGRASP_ID then
        Call(C_PvP, "RegisterWintergrasp")
    elseif self.bonusID == BRAWL_ID then
        Call(C_PvP, "RegisterBrawl", isParty)
    else
        RequestBattlegroundInstanceInfo(self.bonusID)
        JoinBattlefield(self.bonusID, isParty)
    end
end

function Page:ArenaJoinState()
    if IsNeutral() then return false, nil end

    if self.arenaMode == "skirmish" then
        if self.skirmishID then return true, nil end
        return false, Global("PVP_SELECT_BRACKET", "Выберите брекет")
    end

    local seasonOpen = Call(C_PvP, "IsNonSeasonArenaAllowed")
        or (GetCurrentArenaSeason and NO_ARENA_SEASON and GetCurrentArenaSeason() ~= NO_ARENA_SEASON)

    if not seasonOpen then
        return false, Global("PVPFRAME_LABEL_NOSEASON", "Сезон окончен")
    end

    local selected = self.arenaID
    if not selected then
        return false, Global("PVP_SELECT_BRACKET", "Выберите брекет")
    end

    if selected == 1 or selected == 5 then return true, nil end

    local groupSize = GetNumPartyMembers() + 1

    if not IsPartyLeader() and groupSize > 1 then
        return false, Global("PVP_NOT_LEADER", "Очередь может занять только лидер группы.")
    end

    local needed = CONQUEST_SIZES[selected]
    if needed ~= groupSize then
        return false, string.format(
            Global("RATED_BATTLEGROUND_GROUP_MEMBER_ERROR", "Нужно %d игроков."), needed or 0)
    end

    for index = 1, groupSize - 1 do
        if not UnitIsConnected("party" .. index) then
            return false, Global("PVP_NO_QUEUE_DISCONNECTED_GROUP", "Участник группы не в сети.")
        end
    end

    return true, nil
end

function Page:QueueArena()
    local selected = self:SelectedArena()
    if not selected then return end

    local isRated = self.arenaMode ~= "skirmish"
    local asGroup = not (selected == 1 or selected == 5) and GetNumPartyMembers() >= 1

    Call(C_PvP, "RegisterArena", selected - 1, asGroup, isRated)
end

function Page:CreateRail(f, panel)
    local S = NS.Styling
    local Chrome = panel.Chrome

    f.categories = {}

    for index, category in ipairs(CATEGORIES) do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(RAIL_W, 62)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(index - 1) * 70)
        Chrome(button)

        local glow = button:CreateTexture(nil, "BORDER")
        glow:SetPoint("TOPLEFT", 2, -2)
        glow:SetPoint("BOTTOMRIGHT", -2, 2)
        glow:SetTexture(WHITE)
        glow:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.26,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
        glow:Hide()
        button.glow = glow

        local bar = button:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", 2, -3)
        bar:SetPoint("BOTTOMLEFT", 2, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("LEFT", button, "LEFT", 12, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetTexture(category.icon)
        button.icon = icon

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(12), "")
        label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
        label:SetWidth(RAIL_W - 70)
        label:SetJustifyH("LEFT")
        label:SetText(Global(category.label, category.fallback))
        button.label = label

        local amount = button:CreateFontString(nil, "OVERLAY")
        amount:SetFont(NS.FONT, NS.FS(12), "")
        amount:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        amount:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 12, 2)
        button.amount = amount

        button:SetScript("OnEnter", function(self)
            if Page.category ~= category.key then self.glow:Show() end
        end)
        button:SetScript("OnLeave", function(self)
            if Page.category ~= category.key then self.glow:Hide() end
        end)
        button:SetScript("OnClick", function()
            Page.category = category.key
            Page:Update()
        end)

        f.categories[index] = button
    end
end

function Page:CreateCapStrip(f, panel, x, width)
    local S = NS.Styling
    local Chrome = panel.Chrome

    local strip = CreateFrame("Frame", nil, f)
    strip:SetSize(width, 52)
    strip:SetPoint("TOPLEFT", f, "TOPLEFT", x, 0)
    Chrome(strip)
    f.cap = strip

    local label = strip:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(10), "")
    label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    label:SetPoint("TOPLEFT", strip, "TOPLEFT", 14, -10)
    label:SetText(L["НЕДЕЛЬНЫЙ ЛИМИТ"])

    local reset = strip:CreateFontString(nil, "OVERLAY")
    reset:SetFont(NS.FONT, NS.FS(10), "")
    reset:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    reset:SetPoint("TOPRIGHT", strip, "TOPRIGHT", -14, -10)
    reset:SetJustifyH("RIGHT")
    strip.reset = reset

    local track = strip:CreateTexture(nil, "ARTWORK")
    track:SetHeight(12)
    track:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", 14, 10)
    track:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", -14, 10)
    track:SetTexture(WHITE)
    track:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))
    strip.track = track

    local fill = strip:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(12)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    fill:SetTexture(WHITE)
    strip.fill = fill

    local value = strip:CreateFontString(nil, "OVERLAY")
    value:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    value:SetPoint("CENTER", track, "CENTER", 0, 0)
    strip.value = value
end

function Page:CreateSteps(f, panel, x, width)
    local S = NS.Styling
    local Chrome = panel.Chrome

    local strip = CreateFrame("Frame", nil, f)
    strip:SetSize(width, 48)
    strip:SetPoint("TOPLEFT", f, "TOPLEFT", x, -58)
    Chrome(strip)
    f.steps = strip

    local caption = strip:CreateFontString(nil, "OVERLAY")
    caption:SetFont(NS.FONT, NS.FS(10), "")
    caption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    caption:SetPoint("TOPLEFT", strip, "TOPLEFT", 14, -8)
    caption:SetText(L["ЗА СЕГОДНЯ"])

    strip.chips = {}
    for index = 1, 5 do
        local chip = CreateFrame("Frame", nil, strip)
        chip:SetSize(26, 20)
        chip:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", 14 + (index - 1) * 30, 8)

        local plate = chip:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        chip.plate = plate

        local border = CreateFrame("Frame", nil, chip)
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:EnableMouse(false)
        chip.border = border

        local text = chip:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetPoint("CENTER")
        text:SetText(index)
        chip.text = text

        strip.chips[index] = chip
    end

    local rewardIcon = strip:CreateTexture(nil, "ARTWORK")
    rewardIcon:SetSize(18, 18)
    rewardIcon:SetPoint("RIGHT", strip, "RIGHT", -14, -6)
    strip.rewardIcon = rewardIcon

    local reward = strip:CreateFontString(nil, "OVERLAY")
    reward:SetFont(NS.FONT, NS.FS(12), "")
    reward:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    reward:SetPoint("RIGHT", rewardIcon, "LEFT", -6, 0)
    reward:SetJustifyH("RIGHT")
    strip.reward = reward

    local rewardLabel = strip:CreateFontString(nil, "OVERLAY")
    rewardLabel:SetFont(NS.FONT, NS.FS(10), "")
    rewardLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    rewardLabel:SetPoint("RIGHT", reward, "LEFT", -8, 0)
    rewardLabel:SetJustifyH("RIGHT")
    strip.rewardLabel = rewardLabel
end

function Page:CreateCard(parent, height)
    local S = NS.Styling
    local panel = self.panel

    local card = CreateFrame("Button", nil, parent)
    card:SetHeight(height or 52)
    panel.Chrome(card)

    local glow = card:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", 2, -2)
    glow:SetPoint("BOTTOMRIGHT", -2, 2)
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
    glow:Hide()
    card.glow = glow

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", card, "LEFT", 10, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.icon = icon

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(13), "")
    title:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    title:SetJustifyH("LEFT")
    card.title = title

    local note = card:CreateFontString(nil, "OVERLAY")
    note:SetFont(NS.FONT, NS.FS(10), "")
    note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    note:SetJustifyH("LEFT")
    card.note = note

    local right = card:CreateFontString(nil, "OVERLAY")
    right:SetFont(NS.FONT, NS.FS(12), "")
    right:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    right:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    right:SetJustifyH("RIGHT")
    card.right = right

    card:SetScript("OnEnter", function(self)
        if not self.selected then self.glow:Show() end
        if self.OnTooltip then self:OnTooltip() end
    end)
    card:SetScript("OnLeave", function(self)
        if not self.selected then self.glow:Hide() end
        GameTooltip:Hide()
    end)

    function card:SetSelected(value)
        self.selected = value
        self.glow:SetShown(value)
        if value then
            self:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        else
            self:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        end
    end

    return card
end

function Page:CreateArenaCard(parent)
    local S = NS.Styling
    local card = self:CreateCard(parent, 48)

    card.icon:Hide()
    card.title:ClearAllPoints()
    card.title:SetPoint("LEFT", card, "LEFT", 16, 0)
    card.title:SetFont(NS.FONT, NS.FS(14), "")
    card.note:Hide()
    card.right:Hide()

    local function Column(offset, labelText)
        local label = card:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "")
        label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        label:SetPoint("TOP", card, "TOPRIGHT", offset, -8)
        label:SetText(labelText)

        local value = card:CreateFontString(nil, "OVERLAY")
        value:SetFont(NS.FONT, NS.FS(13), "")
        value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        value:SetPoint("TOP", label, "BOTTOM", 0, -3)

        return value
    end

    card.wins = Column(-240, Global("PVPFRAME_WINS_LABEL", "Побед"))
    card.losses = Column(-160, Global("PVP_LOSES", "Поражений"))
    card.rating = Column(-70, Global("RATINGS_MENU", "Рейтинг"))
    card.rating:SetFont(NS.FONT, NS.FS(16), "OUTLINE")

    return card
end

function Page:CreateHonorBody(f, panel, x, width, top)
    local S = NS.Styling
    local Caption = panel.Caption
    local Chrome = panel.Chrome

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", x, top)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 34)
    f.honorBody = body

    local picker = NS.Widgets.CreateOptionPicker(body, {
        { key = "bonus", label = Global("BONUS_BATTLEGROUNDS", "Поле боя с бонусом") },
        { key = "specific", label = Global("SPECIFIC_BATTLEGROUNDS", "Конкретное поле боя") },
    }, "bonus", function(key)
        Page.honorMode = key
        Page:Update()
    end, width)
    picker:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    body.picker = picker

    local bonus = CreateFrame("Frame", nil, body)
    bonus:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -30)
    bonus:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    body.bonus = bonus

    local fieldCaption = Caption(bonus, string.upper(Global("BATTLEFIELDS", "Поля боя")))
    fieldCaption:SetPoint("TOPLEFT", bonus, "TOPLEFT", 0, 0)

    local random = self:CreateCard(bonus)
    random:SetPoint("TOPLEFT", bonus, "TOPLEFT", 0, -16)
    random:SetPoint("TOPRIGHT", bonus, "TOPRIGHT", 0, -16)
    random.icon:SetTexture("Interface\\Icons\\achievement_bg_winwsg")
    random.title:SetText(Global("RANDOM_BATTLEGROUND", "Случайное поле боя"))
    random.note:SetText(L["случайная карта, повышенная награда за первую победу"])
    random:SetScript("OnClick", function()
        Page.bonusID = Page:RandomIndex()
        Page:Update()
    end)
    random.OnTooltip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("BATTLEGROUND_RANDOM_HEADER_TOOLTIP", "Случайное поле боя"), 1, 1, 1)
        GameTooltip:AddLine(Global("BATTLEGROUND_RANDOM_BODY_TOOLTIP", ""), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end
    body.random = random

    local brawl = self:CreateCard(bonus)
    brawl:SetPoint("TOPLEFT", random, "BOTTOMLEFT", 0, -6)
    brawl:SetPoint("TOPRIGHT", random, "BOTTOMRIGHT", 0, -6)
    brawl.icon:SetTexture("Interface\\Icons\\Achievement_BG_KillingBlow_KillingBlow")
    brawl.title:SetText(Global("PVP_BRAWL", "Потасовка"))
    brawl.note:SetText(Global("PVP_BRAWL_DESC", "Новые правила и свежие эмоции!"))
    brawl:SetScript("OnClick", function()
        if not Call(C_PvP, "IsBrawlActive") then return end
        Page.bonusID = BRAWL_ID
        Page:Update()
    end)
    brawl.OnTooltip = function(self)
        local brawlID, brawlName = Call(C_PvP, "GetBrawlInfo")
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("BATTLEGROUND_BRAWL_TOOLTIP_HEADER", "Потасовка"), 1, 1, 1)
        if brawlID and brawlName then
            GameTooltip:AddLine(brawlName, 0.9, 0.9, 0.9)
        end
        if Call(C_PvP, "IsDailyBrawlComplete") then
            GameTooltip:AddLine(Global("BATTLEGROUND_BRAWL_DAILY_COMPLETE", "Награда уже получена"), 0, 1, 0, true)
        end
        if UnitLevel("player") < 80 then
            GameTooltip:AddLine(Global("BRAWL_QUEUE_ERROR", "Доступно с 80 уровня."), 1, 0.3, 0.3, true)
        end
        GameTooltip:Show()
    end
    body.brawl = brawl

    local worldCaption = Caption(bonus, string.upper(Global("WORLD_BATTLEFIELD", "Мировые битвы")))
    worldCaption:SetPoint("TOPLEFT", brawl, "BOTTOMLEFT", 0, -12)

    local wintergrasp = self:CreateCard(bonus)
    wintergrasp:SetPoint("TOPLEFT", worldCaption, "BOTTOMLEFT", 0, -8)
    wintergrasp:SetPoint("RIGHT", brawl, "RIGHT", 0, 0)
    wintergrasp.icon:SetTexture("Interface\\Icons\\INV_Jewelry_Ring_38")
    wintergrasp.title:SetText(Global("WINTERGRASP", "Озеро ледяных оков"))
    wintergrasp.note:SetText(L["мировое поле боя"])
    wintergrasp:SetScript("OnClick", function()
        Page.bonusID = WINTERGRASP_ID
        Page:Update()
    end)
    body.wintergrasp = wintergrasp

    local rewardCaption = Caption(bonus, L["НАГРАДА ЗА ПОБЕДЫ"])
    rewardCaption:SetPoint("TOPLEFT", wintergrasp, "BOTTOMLEFT", 0, -12)

    local reward = bonus:CreateFontString(nil, "OVERLAY")
    reward:SetFont(NS.FONT, NS.FS(11), "")
    reward:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    reward:SetPoint("TOPLEFT", rewardCaption, "BOTTOMLEFT", 0, -8)
    reward:SetWidth(width - 20)
    reward:SetJustifyH("LEFT")
    body.reward = reward

    local specific = CreateFrame("Frame", nil, body)
    specific:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -30)
    specific:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    Chrome(specific)
    specific:Hide()
    body.specific = specific

    specific.rows = {}
    for index = 1, ROWS do
        local row = CreateFrame("Button", nil, specific)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT", specific, "TOPLEFT", 8, -8 - (index - 1) * (ROW_H + 2))
        row:SetPoint("TOPRIGHT", specific, "TOPRIGHT", -8, -8 - (index - 1) * (ROW_H + 2))

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

        local hover = row:CreateTexture(nil, "BORDER")
        hover:SetAllPoints()
        hover:SetTexture(WHITE)
        hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.16)
        hover:Hide()
        row.hover = hover

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(12), "")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
        name:SetJustifyH("LEFT")
        row.name = name

        local note = row:CreateFontString(nil, "OVERLAY")
        note:SetFont(NS.FONT, NS.FS(10), "")
        note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        note:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        note:SetJustifyH("LEFT")
        row.note = note

        local size = row:CreateFontString(nil, "OVERLAY")
        size:SetFont(NS.FONT, NS.FS(11), "")
        size:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        size:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        size:SetJustifyH("RIGHT")
        row.size = size

        row:SetScript("OnEnter", function(self)
            self.hover:Show()
            if self.description then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.name:GetText() or "", 1, 1, 1)
                GameTooltip:AddLine(self.description, 0.9, 0.9, 0.9, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.hover:Hide()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self)
            Page.specificIndex = self.battlegroundIndex
            Page:Update()
        end)

        row:Hide()
        specific.rows[index] = row
    end
end

function Page:CreateConquestBody(f, panel, x, width, top)
    local S = NS.Styling
    local Caption = panel.Caption

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", x, top)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 34)
    f.conquestBody = body

    local picker = NS.Widgets.CreateOptionPicker(body, {
        { key = "rated", label = Global("RATED_BATTLE_LABEL", "Рейтинговые бои") },
        { key = "skirmish", label = Global("SKIRMISH_LABEL", "Тренировочные") },
    }, "rated", function(key)
        Page.arenaMode = key
        Page:Update()
    end, width)
    picker:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    body.picker = picker

    local rated = CreateFrame("Frame", nil, body)
    rated:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -30)
    rated:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    body.rated = rated

    local ratedCaption = Caption(rated, string.upper(Global("RATED_BATTLE_LABEL", "Рейтинговые бои")))
    ratedCaption:SetPoint("TOPLEFT", rated, "TOPLEFT", 0, 0)

    rated.cards = {}

    local previous
    for _, entry in ipairs(ARENA_BRACKETS) do
        local card = self:CreateArenaCard(rated)

        if entry.container == "solo" then
            local soloCaption = Caption(rated, string.upper(Global("PVPFRAME_SOLO_ARENA_LABEL", "Арена (SoloQ)")))
            soloCaption:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12)
            card:SetPoint("TOPLEFT", soloCaption, "BOTTOMLEFT", 0, -8)
            card:SetPoint("RIGHT", rated, "RIGHT", 0, 0)
        elseif previous then
            card:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
            card:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -6)
        else
            card:SetPoint("TOPLEFT", ratedCaption, "BOTTOMLEFT", 0, -8)
            card:SetPoint("RIGHT", rated, "RIGHT", 0, 0)
        end

        card.title:SetText(_G["ARENA_INSPECT_BRECKET_" .. entry.id] or "")
        card.bracketID = entry.id
        card:SetScript("OnClick", function(self)
            Page.arenaID = self.bracketID
            Page:Update()
        end)
        card.OnTooltip = function(self)
            local rating, todayGames, todayWins, weekGames, weekWins, seasonGames, seasonWins =
                Call(C_PvP, "GetBracketStats", self.bracketID)
            if not rating then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.title:GetText() or "", 1, 1, 1)
            GameTooltip:AddDoubleLine(L["сегодня"],
                string.format("%d / %d", todayWins or 0, todayGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)
            GameTooltip:AddDoubleLine(Global("PVP_LADDER_WEEK", "Неделя"),
                string.format("%d / %d", weekWins or 0, weekGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)
            GameTooltip:AddDoubleLine(Global("PVP_LADDER_SEASON", "Сезон"),
                string.format("%d / %d", seasonWins or 0, seasonGames or 0), 0.8, 0.8, 0.85, 1, 1, 1)

            local qualifiedWeeks, qualifiedWeeksRequired, qualifiedWeeksMax, requiredMatches =
                Call(C_PvP, "GetBracketQualificationInfo", self.bracketID)
            if qualifiedWeeks then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["квалификация: %d из %d недель, %d игр в неделю"],
                    qualifiedWeeks, qualifiedWeeksMax or 0, requiredMatches or 0), 0.55, 0.78, 0.58, true)
            end

            GameTooltip:Show()
        end

        rated.cards[entry.id] = card
        previous = card
    end

    local skirmish = CreateFrame("Frame", nil, body)
    skirmish:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -30)
    skirmish:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    skirmish:Hide()
    body.skirmish = skirmish

    local skirmishCaption = Caption(skirmish, string.upper(Global("SKIRMISH_LABEL", "Тренировочные")))
    skirmishCaption:SetPoint("TOPLEFT", skirmish, "TOPLEFT", 0, 0)

    skirmish.cards = {}
    previous = nil

    for _, bracketID in ipairs(SKIRMISH_BRACKETS) do
        local card = self:CreateCard(skirmish, 44)
        card.icon:Hide()
        card.title:ClearAllPoints()
        card.title:SetPoint("LEFT", card, "LEFT", 16, 0)
        card.title:SetFont(NS.FONT, NS.FS(14), "")
        card.note:Hide()
        card.right:SetText(L["без рейтинга"])
        card.right:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])

        if previous then
            card:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
            card:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -6)
        else
            card:SetPoint("TOPLEFT", skirmishCaption, "BOTTOMLEFT", 0, -8)
            card:SetPoint("RIGHT", skirmish, "RIGHT", 0, 0)
        end

        card.title:SetText(string.format(Global("PVP_SKIRMISH", "%s"),
            _G["ARENA_INSPECT_BRECKET_" .. bracketID] or ""))
        card.bracketID = bracketID
        card:SetScript("OnClick", function(self)
            Page.skirmishID = self.bracketID
            Page:Update()
        end)

        skirmish.cards[bracketID] = card
        previous = card
    end
end

function Page:CreateServiceBody(f, panel, x, width, top)
    local S = NS.Styling
    local Caption = panel.Caption
    local Chrome = panel.Chrome

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", x, top)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.serviceBody = body

    local rank = CreateFrame("Frame", nil, body)
    rank:SetHeight(150)
    rank:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    rank:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    Chrome(rank)
    body.rank = rank

    local rankName = rank:CreateFontString(nil, "OVERLAY")
    rankName:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    rankName:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    rankName:SetPoint("TOPLEFT", rank, "TOPLEFT", 16, -14)
    rank.name = rankName

    local rating = rank:CreateFontString(nil, "OVERLAY")
    rating:SetFont(NS.FONT, NS.FS(12), "")
    rating:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    rating:SetPoint("TOPLEFT", rankName, "BOTTOMLEFT", 0, -6)
    rank.rating = rating

    local nextRank = rank:CreateFontString(nil, "OVERLAY")
    nextRank:SetFont(NS.FONT, NS.FS(11), "")
    nextRank:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    nextRank:SetPoint("TOPRIGHT", rank, "TOPRIGHT", -16, -16)
    nextRank:SetJustifyH("RIGHT")
    rank.next = nextRank

    local track = rank:CreateTexture(nil, "ARTWORK")
    track:SetHeight(10)
    track:SetPoint("BOTTOMLEFT", rank, "BOTTOMLEFT", 16, 16)
    track:SetPoint("BOTTOMRIGHT", rank, "BOTTOMRIGHT", -16, 16)
    track:SetTexture(WHITE)
    track:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))
    rank.track = track

    local fill = rank:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(10)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
    rank.fill = fill

    local progressText = rank:CreateFontString(nil, "OVERLAY")
    progressText:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    progressText:SetPoint("CENTER", track, "CENTER", 0, 0)
    rank.progress = progressText

    local function Cell(anchorX, anchorY, labelText, size)
        local label = rank:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "")
        label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        label:SetPoint("BOTTOMLEFT", rank, "BOTTOMLEFT", anchorX, anchorY + 54)
        label:SetText(labelText)

        local value = rank:CreateFontString(nil, "OVERLAY")
        value:SetFont(NS.FONT, NS.FS(size or 12), "")
        value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)

        return value
    end

    rank.weekLabel = Cell(16, 0, "", 11)
    rank.weekWins = Cell(120, 0, Global("RATED_BATTLEGROUND_WINS", "Победы"))
    rank.weekGames = Cell(220, 0, Global("RATED_BATTLEGROUND_TOTAL", "Всего"))
    rank.weekProc = Cell(320, 0, Global("RATED_BATTLEGROUND_PROCWINS", "% Побед"))

    local statsCaption = Caption(body, string.upper(Global("STATISTICS", "Статистика")))
    statsCaption:SetPoint("TOPLEFT", rank, "BOTTOMLEFT", 0, -12)

    local stats = CreateFrame("Frame", nil, body)
    stats:SetPoint("TOPLEFT", statsCaption, "BOTTOMLEFT", 0, -8)
    stats:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", 0, 0)
    Chrome(stats)
    body.stats = stats

    local headRecord = stats:CreateFontString(nil, "OVERLAY")
    headRecord:SetFont(NS.FONT, NS.FS(10), "")
    headRecord:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    headRecord:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -16, -10)
    headRecord:SetText(L["победы - поражения"])

    stats.rows = {}
    for index = 1, STAT_ROWS do
        local row = CreateFrame("Button", nil, stats)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", stats, "TOPLEFT", 8, -26 - (index - 1) * 27)
        row:SetPoint("TOPRIGHT", stats, "TOPRIGHT", -8, -26 - (index - 1) * 27)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(12), "")
        name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        name:SetJustifyH("LEFT")
        row.name = name

        local record = row:CreateFontString(nil, "OVERLAY")
        record:SetFont(NS.FONT, NS.FS(12), "")
        record:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        record:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        record:SetJustifyH("RIGHT")
        row.record = record

        row:SetScript("OnEnter", function(self)
            if not self.battlegroundID then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.name:GetText() or "", 1, 1, 1)

            local total = Call(C_PvP, "GetNumBattlegroundStatistics", self.battlegroundID) or 0
            if total > 0 then
                GameTooltip:AddDoubleLine(" ", string.format("%s / %s",
                    Global("RATED_BATTLEGROUND_WEEK", "Неделя"),
                    Global("RATED_BATTLEGROUND_SEASON", "Сезон")), 1, 1, 1, 0.7, 0.7, 0.75)
            end

            for statIndex = 1, total do
                local statName = Call(C_PvP, "GetBattlegroundStatisticInfo", self.battlegroundID, statIndex)
                local week, season = Call(C_Inspect, "GetBattlegroundStatistics",
                    "player", self.battlegroundID, statIndex)
                GameTooltip:AddDoubleLine(statName or "-",
                    string.format("%s / %s", week or 0, season or 0), 0.8, 0.8, 0.85, 1, 1, 1)
            end

            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row:Hide()
        stats.rows[index] = row
    end

    local empty = stats:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOPLEFT", stats, "TOPLEFT", 16, -30)
    empty:SetWidth(width - 40)
    empty:SetJustifyH("LEFT")
    empty:Hide()
    stats.empty = empty
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local host = panel.frame
    local _, _, _, _, pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -64)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.category = self.category or "honor"
    self.honorMode = self.honorMode or "bonus"
    self.arenaMode = self.arenaMode or "rated"
    self.arenaID = self.arenaID or 2
    self.skirmishID = self.skirmishID or 2

    local contentX = RAIL_W + 18
    local contentW = 824 - contentX

    self:CreateRail(f, panel)
    self:CreateCapStrip(f, panel, contentX, contentW)
    self:CreateSteps(f, panel, contentX, contentW)
    self:CreateHonorBody(f, panel, contentX, contentW, -118)
    self:CreateConquestBody(f, panel, contentX, contentW, -118)
    self:CreateServiceBody(f, panel, contentX, contentW, 0)

    local join = NS.Widgets.CreateThemedButton(f, Global("BATTLEFIELD_JOIN", "Вступить в бой"), 160, 24, function()
        if Page.category == "honor" then
            Page:QueueHonor(false)
        elseif Page.category == "conquest" then
            Page:QueueArena()
        end
    end, NS.Styling.ACCENT)
    join:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -170, 0)
    f.join = join

    local groupJoin = NS.Widgets.CreateThemedButton(f, Global("BATTLEFIELD_GROUP_JOIN", "Вступить группой"),
        160, 24, function()
            if Page.category == "honor" then Page:QueueHonor(true) end
        end)
    groupJoin:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.groupJoin = groupJoin

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(11), "")
    hint:SetTextColor(0.85, 0.45, 0.45)
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", RAIL_W + 18, 6)
    hint:SetWidth(400)
    hint:SetJustifyH("LEFT")
    f.hint = hint

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    events:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
    events:RegisterEvent("HONOR_CURRENCY_UPDATE")
    events:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")

    if events.RegisterCustomEvent then
        for _, name in ipairs({ "PVP_WEEKLY_LIMIT_UPDATE", "PVP_SEASON_UPDATE", "PVP_REWARDS_UPDATE",
            "BATTLEGROUND_LOCK_UPDATE" }) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events

    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then return end
        self.elapsed = 0
        Page:UpdateTimers()
    end)

    f:Hide()

    return f
end

function Page:UpdateRail()
    local S = NS.Styling
    local f = self.frame

    for index, button in ipairs(f.categories) do
        local category = CATEGORIES[index]
        local active = category.key == self.category

        button:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or S.BORDER[4])
        button.bar:SetShown(active)
        button.glow:SetShown(active)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_NORMAL[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_NORMAL[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_NORMAL[3])

        if category.currency == "honor" then
            button.amount:SetText(GetHonorCurrency and GetHonorCurrency() or "")
        elseif category.currency == "arena" then
            button.amount:SetText(GetArenaCurrency and GetArenaCurrency() or "")
        else
            button.amount:SetText("")
        end
    end
end

function Page:UpdateTimers()
    local f = self.frame
    if not f or not f:IsShown() then return end

    if f.cap:IsShown() then
        local _, weekly = Call(C_PvP, "GetLimitResetTime")
        if weekly and weekly > 0 then
            f.cap.reset:SetText(string.format(L["обновление через %s"], SecondsToTime(weekly, true, false, 2)))
        else
            f.cap.reset:SetText("")
        end
    end

    if self.category == "honor" and self.honorMode == "bonus" then
        local wait = GetWintergraspWaitTime and GetWintergraspWaitTime()
        local card = f.honorBody.wintergrasp
        if wait and wait > 0 then
            card.right:SetText(SecondsToTime(wait, true, false, 2))
        else
            card.right:SetText(L["битва идет"])
        end
    end
end

function Page:UpdateCap()
    local S = NS.Styling
    local f = self.frame
    local currentArena, maxArena, previousArena, currentHonor, maxHonor, previousHonor,
        currentSolo, maxSolo, previousSolo = Call(C_PvP, "GetWeeklyLimits")

    local value, maximum = 0, 0

    if self.category == "honor" then
        value, maximum = currentHonor or 0, (maxHonor or 0) + (previousHonor or 0)
        f.cap.fill:SetVertexColor(0.67, 1, 0, 0.9)
    elseif self.arenaID == 1 then
        value, maximum = currentSolo or 0, (maxSolo or 0) + (previousSolo or 0)
        f.cap.fill:SetVertexColor(1, 0.7, 1, 0.9)
    else
        value, maximum = currentArena or 0, (maxArena or 0) + (previousArena or 0)
        f.cap.fill:SetVertexColor(1, 0.85, 0.3, 0.9)
    end

    if maximum > 0 and value >= maximum then
        f.cap.fill:SetVertexColor(0, 0.8, 0, 0.9)
    end

    local width = f.cap.track:GetWidth() or 1
    local ratio = maximum > 0 and math.min(1, value / maximum) or 0

    f.cap.fill:SetWidth(math.max(1, width * ratio))
    f.cap.value:SetText(string.format("%d / %d", value, maximum))
    f.cap.value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
end

function Page:UpdateSteps()
    local S = NS.Styling
    local f = self.frame
    local strip = f.steps

    local bgGames, arenaGames, soloGames, oneGames = Call(C_PvP, "GetDailyStats")
    local bgReward, reward2v2, reward1v1, rewardSolo = Call(C_PvP, "GetDailyRewards")

    local played, total, reward, currency

    if self.category == "honor" then
        played, total, reward = bgGames or 0, 3, bgReward
        currency = "Interface\\PVPFrame\\PVPCurrency-Honor-" .. FactionName()
    elseif self.arenaID == 1 then
        played, total, reward = soloGames or 0, 5, rewardSolo
        currency = "Interface\\PVPFrame\\PVPCurrency-Conquest-" .. FactionName()
    elseif self.arenaID == 5 then
        played, total, reward = oneGames or 0, 5, reward1v1
        currency = "Interface\\PVPFrame\\PVPCurrency-Conquest-" .. FactionName()
    else
        played, total, reward = arenaGames or 0, 5, reward2v2
        currency = "Interface\\PVPFrame\\PVPCurrency-Conquest-" .. FactionName()
    end

    for index, chip in ipairs(strip.chips) do
        if index > total then
            chip:Hide()
        else
            chip:Show()

            local done = played >= index
            local current = played + 1 == index or (played == 0 and index == 1)

            chip.plate:SetVertexColor(
                done and 0.10 or 0.06,
                done and 0.30 or 0.07,
                done and 0.16 or 0.10, 0.9)
            chip.border:SetBackdropBorderColor(
                done and 0.3 or (current and S.ACCENT[1] or S.BORDER[1]),
                done and 0.85 or (current and S.ACCENT[2] or S.BORDER[2]),
                done and 0.4 or (current and S.ACCENT[3] or S.BORDER[3]), 1)
            chip.text:SetTextColor(
                done and 0.55 or (current and 1 or 0.45),
                done and 0.9 or (current and 1 or 0.45),
                done and 0.6 or (current and 1 or 0.48))
        end
    end

    strip.rewardLabel:SetText(string.format(
        Global("PVPFRAME_STEPEND_WINS_LABEL", "За %d побед"), total))
    strip.reward:SetText(reward or 0)
    strip.rewardIcon:SetTexture(currency)
end

function Page:UpdateHonor()
    local S = NS.Styling
    local f = self.frame
    local body = f.honorBody

    body.picker:Refresh(self.honorMode)

    local bonus = self.honorMode == "bonus"
    body.bonus:SetShown(bonus)
    body.specific:SetShown(not bonus)

    if bonus then
        local randomIndex = self:RandomIndex()

        body.random:SetSelected(self.bonusID == randomIndex and randomIndex ~= nil)
        Enable(body.random, UnitLevel("player") >= 10)
        body.random.title:SetTextColor(
            UnitLevel("player") >= 10 and S.TEXT_BRIGHT[1] or 0.5,
            UnitLevel("player") >= 10 and S.TEXT_BRIGHT[2] or 0.5,
            UnitLevel("player") >= 10 and S.TEXT_BRIGHT[3] or 0.5)

        local brawlActive = Call(C_PvP, "IsBrawlActive") and true or false
        local _, brawlName, brawlItemLevel = Call(C_PvP, "GetBrawlInfo")

        body.brawl:SetSelected(self.bonusID == BRAWL_ID)
        body.brawl.icon:SetDesaturated(not brawlActive)
        body.brawl.title:SetTextColor(
            brawlActive and S.TEXT_BRIGHT[1] or 0.5,
            brawlActive and S.TEXT_BRIGHT[2] or 0.5,
            brawlActive and S.TEXT_BRIGHT[3] or 0.5)
        body.brawl.note:SetText(brawlActive and (brawlName or Global("PVP_BRAWL_DESC", ""))
            or L["сейчас недоступна"])

        if Call(C_PvP, "IsDailyBrawlComplete") then
            body.brawl.right:SetText(L["награда получена"])
            body.brawl.right:SetTextColor(0.4, 0.85, 0.45)
        elseif brawlItemLevel and brawlItemLevel > 0 then
            body.brawl.right:SetText(string.format("%s %d",
                Global("LFG_LIST_ITEM_LEVEL_INSTR_SHORT", "Уровень предметов"), brawlItemLevel))
            body.brawl.right:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        else
            body.brawl.right:SetText("")
        end

        body.wintergrasp:SetSelected(self.bonusID == WINTERGRASP_ID)

        local honorReward = Call(C_PvP, "GetRewardInfo",
            Enum and Enum.PvPRewardType and Enum.PvPRewardType.BATTLEGROUND)
        local worldReward = Call(C_PvP, "GetRewardInfo",
            Enum and Enum.PvPRewardType and Enum.PvPRewardType.WINTERGRASP)

        local lines = {}
        if honorReward and honorReward > 0 then
            lines[#lines + 1] = string.format(L["за победу на поле боя: %d %s"],
                honorReward, Global("HONOR", "Честь"))
        end
        if worldReward and worldReward > 0 then
            lines[#lines + 1] = string.format(L["за мировую битву: %d %s"],
                worldReward, Global("HONOR", "Честь"))
        end

        local locks = Call(C_PvP, "GetBattlegroundLocks")
        if locks and #locks > 0 then
            lines[#lines + 1] = string.format(L["закрыты: %s"], table.concat(locks, ", "))
        end

        body.reward:SetText(table.concat(lines, "\n"))
        self:UpdateTimers()
    else
        local list = self:Specific()

        for index, row in ipairs(body.specific.rows) do
            local entry = list[index]
            if entry then
                row.battlegroundIndex = entry.index
                row.description = entry.description
                row.icon:SetTexture(entry.icon or QUESTION)
                row.name:SetText(entry.name)
                row.note:SetText(entry.gameType or "")
                row.size:SetText(entry.maxPlayers
                    and string.format(Global("BATTLEGROUND_TEAM_SIZE", "%d на %d"),
                        entry.maxPlayers, entry.maxPlayers) or "")

                local selected = self.specificIndex == entry.index
                row.name:SetTextColor(
                    selected and S.TEXT_BRIGHT[1] or S.TEXT_NORMAL[1],
                    selected and S.TEXT_BRIGHT[2] or S.TEXT_NORMAL[2],
                    selected and S.TEXT_BRIGHT[3] or S.TEXT_NORMAL[3])
                row.hover:SetShown(selected)

                row:Show()
            else
                row:Hide()
            end
        end
    end

    local canQueue = self:CanQueueHonor()
    Enable(f.join, canQueue)
    f.groupJoin:Show()
    Enable(f.groupJoin, canQueue and IsPartyLeader()
        and self.bonusID ~= nil and self.bonusID ~= WINTERGRASP_ID)

    if not canQueue and self.honorMode == "bonus" and self.bonusID == BRAWL_ID
        and UnitLevel("player") < 80 then
        f.hint:SetText(Global("BRAWL_QUEUE_ERROR", "Потасовки доступны с 80 уровня."))
    elseif not canQueue then
        f.hint:SetText(L["выберите поле боя"])
    else
        f.hint:SetText("")
    end
end

function Page:UpdateConquest()
    local S = NS.Styling
    local f = self.frame
    local body = f.conquestBody

    body.picker:Refresh(self.arenaMode)

    local rated = self.arenaMode == "rated"
    body.rated:SetShown(rated)
    body.skirmish:SetShown(not rated)

    if rated then
        for bracketID, card in pairs(body.rated.cards) do
            local rating, _, _, _, _, seasonGames, seasonWins = Call(C_PvP, "GetBracketStats", bracketID)

            card.wins:SetText(seasonWins or 0)
            card.losses:SetText((seasonGames or 0) - (seasonWins or 0))
            card.rating:SetText(rating or 0)
            card.rating:SetTextColor(
                (rating or 0) > 0 and S.GOLD[1] or S.TEXT_DIM[1],
                (rating or 0) > 0 and S.GOLD[2] or S.TEXT_DIM[2],
                (rating or 0) > 0 and S.GOLD[3] or S.TEXT_DIM[3])
            card:SetSelected(self.arenaID == bracketID)
        end
    else
        for bracketID, card in pairs(body.skirmish.cards) do
            card:SetSelected(self.skirmishID == bracketID)
        end
    end

    local canQueue, reason = self:ArenaJoinState()
    Enable(f.join, canQueue)
    f.groupJoin:Hide()
    f.hint:SetText(canQueue and "" or (reason or ""))
end

function Page:UpdateService()
    local S = NS.Styling
    local f = self.frame
    local body = f.serviceBody
    local rank = body.rank

    local rankName, rankBaseRating, rankID, _, rating, nextRankName, _, _, nextRating,
        weekWins, weekGames, totalWins, totalGames = Call(C_PvP, "GetRatedBattlegroundRankInfo")

    rank.name:SetText(rankName or Global("RATED_BATTLEGROUND_NORANK", "Нет звания"))
    rank.rating:SetText(string.format(
        Global("RATED_BATTLEGROUND_YOURATING", "Ваш рейтинг: %s (Ранг %s)"),
        (rating or 0) > 0 and rating or "-", rankID or 0))

    if nextRankName and (rankID or 0) < 14 then
        rank.next:SetText(string.format(
            Global("RATED_BATTLEGROUND_NEXTRANK", "Следующее звание \"%s\""), nextRankName))
    else
        rank.next:SetText("")
    end

    local width = rank.track:GetWidth() or 1
    local ratio = 0

    if rating and nextRating and rankBaseRating and nextRating > rankBaseRating then
        ratio = math.max(0, math.min(1, (rating - rankBaseRating) / (nextRating - rankBaseRating)))
    end

    rank.fill:SetWidth(math.max(1, width * ratio))
    rank.progress:SetText(nextRating and string.format("%d / %d", rating or 0, nextRating) or "")

    rank.weekLabel:SetText(string.format("%s / %s",
        Global("RATED_BATTLEGROUND_WEEK", "Неделя"), Global("RATED_BATTLEGROUND_SEASON", "Сезон")))
    rank.weekWins:SetText(string.format("%d / %d", weekWins or 0, totalWins or 0))
    rank.weekGames:SetText(string.format("%d / %d", weekGames or 0, totalGames or 0))
    rank.weekProc:SetText(string.format("%d%% / %d%%",
        (weekGames or 0) > 0 and math.ceil(weekWins / weekGames * 100) or 0,
        (totalGames or 0) > 0 and math.ceil(totalWins / totalGames * 100) or 0))

    local stats = body.stats
    local shown = 0

    for _, entry in ipairs(Battlegrounds()) do
        local total = Call(C_PvP, "GetNumBattlegroundStatistics", entry.id) or 0

        if total > 0 and shown < STAT_ROWS then
            shown = shown + 1
            local row = stats.rows[shown]
            local _, _, _, icon = Call(C_PvP, "GetBattlegroundInfoEx", entry.id)
            local recordWin, recordLose = Call(C_Inspect, "GetBattlegroundRecordStatistics", "player", entry.id)

            row.battlegroundID = entry.id
            row.icon:SetTexture(icon or QUESTION)
            row.name:SetText(entry.name)
            row.record:SetText(string.format("%d - %d", recordWin or 0, recordLose or 0))
            row:Show()
        end
    end

    for index = shown + 1, STAT_ROWS do stats.rows[index]:Hide() end

    stats.empty:SetShown(shown == 0)
    if shown == 0 then
        stats.empty:SetText(L["сервер еще не прислал статистику полей боя"])
    end

    f.join:Hide()
    f.groupJoin:Hide()
    f.hint:SetText("")
end

function Page:Update()
    if not self.frame then return end

    local f = self.frame

    self:UpdateRail()

    local service = self.category == "service"

    f.cap:SetShown(not service)
    f.steps:SetShown(not service)
    f.honorBody:SetShown(self.category == "honor")
    f.conquestBody:SetShown(self.category == "conquest")
    f.serviceBody:SetShown(service)

    if not service then
        f.join:Show()
        self:UpdateCap()
        self:UpdateSteps()
    end

    if self.category == "honor" then
        f.join:SetText(Global("BATTLEFIELD_JOIN", "Вступить в бой"))
        self:UpdateHonor()
    elseif self.category == "conquest" then
        f.join:SetText(Global("BATTLEFIELD_JOIN", "Вступить в бой"))
        self:UpdateConquest()
    else
        self:UpdateService()
    end
end

function Page:Show()
    if not self.frame then return end

    if self.category == "honor" and self.honorMode == "bonus" and not self.bonusID then
        self.bonusID = self:RandomIndex()
    end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if self.frame then self.frame:Hide() end
end

NS.PvPPage = Page
