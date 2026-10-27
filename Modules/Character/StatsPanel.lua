local addonName, NS = ...
local L = NS.L
local StatsPanel = {}
local format = string.format
local floor = math.floor

local PANEL_WIDTH = 440
local ROW_HEIGHT = 16

local LIST_WIDTH  = 412
local COL_WIDTH   = 196
local COL_GAP     = 12
local LEFT_X      = 4
local RIGHT_X     = LEFT_X + COL_WIDTH + COL_GAP
local DIVIDER_X   = LEFT_X + COL_WIDTH + COL_GAP / 2
local LABEL_INSET = 8
local VALUE_WIDTH = 78
local LABEL_WIDTH = COL_WIDTH - LABEL_INSET - VALUE_WIDTH

local WHITE = "Interface\\Buttons\\WHITE8x8"
local BASIC_TOP = -180
local BASIC_ROW = 19
local BASIC_COL = 206
local BASIC_LABEL = 128
local RADAR_SIZE = 76
local RADAR_REACH = 0.47

local function GetAttackPower()
    local base, pos, neg = UnitAttackPower("player")
    return floor((base or 0) + (pos or 0) + (neg or 0))
end

local function ValueColor(text)
    local S = NS.Styling
    if text == "0" or text == "-" or text:match("^0%.0+%%?$") then
        return S.TEXT_DIM
    end
    return S.TEXT_BRIGHT
end

local function MaxSpellCrit()
    local maxCrit = 0
    for i = 2, 7 do
        local c = GetSpellCritChance(i) or 0
        if c > maxCrit then maxCrit = c end
    end
    return maxCrit
end

local function MaxSpellDamage()
    local maxDmg = 0
    for i = 2, 7 do
        local d = GetSpellBonusDamage(i) or 0
        if d > maxDmg then maxDmg = d end
    end
    return maxDmg
end

local STAT_LEFT = {
    { label = "Сила",         key = "STR",   tip = "STR",              func = function() return floor(UnitStat("player", 1)) end },
    { label = "Ловкость",     key = "AGI",   tip = "AGI",              func = function() return floor(UnitStat("player", 2)) end },
    { label = "Выносливость", key = "STA",   tip = "STA",              func = function() return floor(UnitStat("player", 3)) end },
    { label = "Интеллект",    key = "INT",   tip = "INT",              func = function() return floor(UnitStat("player", 4)) end },
    { label = "Дух",          key = "SPI",   tip = "SPI",              func = function() return floor(UnitStat("player", 5)) end },
    { label = "Здоровье",                    tip = "HEALTH",           func = function() return UnitHealthMax("player") end },
    { label = "Броня",        key = "ARMOR", tip = "ARMOR",            func = function() return select(2, UnitArmor("player")) end },
    { label = "Ресурс",                      tip = "POWER",            func = function() return UnitPowerMax("player") end },
    { label = "Скорость",     key = "HASTE", tip = "ATTACKSPEED",      func = function() return format("%.2f", UnitAttackSpeed("player")) end },
    { label = "Уклонение",                   tip = "DODGE",            func = function() return format("%.1f%%", GetDodgeChance()) end },
    { label = "Парирование",                 tip = "PARRY",            func = function() return format("%.1f%%", GetParryChance()) end },
    { label = "Блок",         key = "BLOCK", tip = "BLOCK",            func = function() return format("%.1f%%", GetBlockChance()) end },
}

local STAT_RIGHT = {
    { label = "Сила атаки",  key = "AP",         tip = "AP",               func = GetAttackPower },
    { label = "Крит.",       key = "CRIT",       tip = "CRIT",             func = function() return format("%.1f%%", GetCritChance()) end },
    { label = "Крит. закл.", key = "SPELLCRIT",  tip = "SPELLCRIT",        func = function() return format("%.1f%%", MaxSpellCrit()) end },
    { label = "Меткость",    key = "HIT",        tip = "HIT",              func = function() return GetCombatRating(CR_HIT_MELEE) end },
    { label = "Мастерство",  key = "EXP",        tip = "EXP",              func = function() return (GetExpertise()) end },
    { label = "Защита",      key = "DEF",        tip = "DEF",              func = function()
        local base, modifier = UnitDefense("player")
        return floor((base or 0) + (modifier or 0))
    end },
    { label = "Пробивание",  key = "ARP",        tip = "ARP",              func = function() return format("%.1f%%", GetArmorPenetration()) end },
    { label = "Стойкость",                       tip = "RESIL",            func = function() return GetCombatRating(CR_CRIT_TAKEN_MELEE) end },
    { label = "Скор. закл.", key = "SPELLHASTE", tip = "SPELLHASTE",       func = function() return GetCombatRating(CR_HASTE_SPELL) end },
    { label = "Проб. брони", key = "ARP",        tip = "ARPRATING",        func = function() return GetCombatRating(CR_ARMOR_PENETRATION) end },
    { label = "Урон закл.",  key = "SP",         tip = "SP",               func = MaxSpellDamage },
    { label = "Исцеление",   key = "HEAL",       tip = "HEAL",             func = function() return GetSpellBonusHealing() end },
    { label = "МП5",         key = "MP5",        tip = "MANAREGEN",        func = function()
        if UnitPowerType("player") ~= 0 then return "-" end
        local base = select(1, GetManaRegen()) or 0
        return format("%.1f", base * 5)
    end },
    { label = "МП5 в бою",   key = "MP5",        tip = "MANAREGENCASTING", func = function()
        if UnitPowerType("player") ~= 0 then return "-" end
        local casting = select(2, GetManaRegen()) or 0
        return format("%.1f", casting * 5)
    end },
}

local BASIC_LEFT = { STAT_LEFT[1], STAT_LEFT[2], STAT_LEFT[3], STAT_LEFT[4], STAT_LEFT[5], STAT_LEFT[6], STAT_LEFT[7], STAT_LEFT[8] }
local BASIC_RIGHT = { STAT_RIGHT[1], STAT_RIGHT[11], STAT_RIGHT[12], STAT_RIGHT[7], STAT_RIGHT[6], STAT_LEFT[10], STAT_LEFT[11], STAT_RIGHT[8] }

local function Rating(id)
    return function() return GetCombatRating(id) end
end

local function Bonus(id)
    return function() return GetCombatRatingBonus(id) end
end

local AXES = {
    MELEE = {
        { label = "Крит.",      key = "CRIT",  tip = "CRIT",        value = function() return GetCritChance() end, max = 50 },
        { label = "Скорость",   key = "HASTE", tip = "ATTACKSPEED", value = Bonus(CR_HASTE_MELEE), rating = Rating(CR_HASTE_MELEE), max = 30 },
        { label = "Меткость",   key = "HIT",   tip = "HIT",         value = Bonus(CR_HIT_MELEE), rating = Rating(CR_HIT_MELEE), max = 8 },
        { label = "Мастерство", key = "EXP",   tip = "EXP",         value = function() return GetExpertisePercent() end, rating = function() return (GetExpertise()) end, max = 6.5 },
    },
    RANGED = {
        { label = "Крит.",      key = "CRIT",  tip = "CRIT",        value = function() return GetRangedCritChance() end, max = 50 },
        { label = "Скорость",   key = "HASTE", tip = "ATTACKSPEED", value = Bonus(CR_HASTE_RANGED), rating = Rating(CR_HASTE_RANGED), max = 30 },
        { label = "Меткость",   key = "HIT",   tip = "HIT",         value = Bonus(CR_HIT_RANGED), rating = Rating(CR_HIT_RANGED), max = 8 },
        { label = "Пробивание", key = "ARP",   tip = "ARP",         value = function() return GetArmorPenetration() end, rating = Rating(CR_ARMOR_PENETRATION), max = 100 },
    },
    CASTER = {
        { label = "Крит. закл.", key = "SPELLCRIT",  tip = "SPELLCRIT",  value = MaxSpellCrit, max = 50 },
        { label = "Скор. закл.", key = "SPELLHASTE", tip = "SPELLHASTE", value = Bonus(CR_HASTE_SPELL), rating = Rating(CR_HASTE_SPELL), max = 30 },
        { label = "Меткость",    key = "HIT",        tip = "HIT",        value = Bonus(CR_HIT_SPELL), rating = Rating(CR_HIT_SPELL), max = 17 },
        { label = "Урон закл.",  key = "SP",         tip = "SP",         value = MaxSpellDamage, max = 3500, plain = true },
    },
    HEALER = {
        { label = "Крит. закл.", key = "SPELLCRIT",  tip = "SPELLCRIT",        value = MaxSpellCrit, max = 50 },
        { label = "Скор. закл.", key = "SPELLHASTE", tip = "SPELLHASTE",       value = Bonus(CR_HASTE_SPELL), rating = Rating(CR_HASTE_SPELL), max = 30 },
        { label = "МП5 в бою",   key = "MP5",        tip = "MANAREGENCASTING", value = function() return (select(2, GetManaRegen()) or 0) * 5 end, max = 800, plain = true },
        { label = "Исцеление",   key = "HEAL",       tip = "HEAL",             value = function() return GetSpellBonusHealing() end, max = 4000, plain = true },
    },
    TANK = {
        { label = "Уклонение",   key = "DODGE", tip = "DODGE", value = function() return GetDodgeChance() end, max = 40 },
        { label = "Парирование", key = "PARRY", tip = "PARRY", value = function() return GetParryChance() end, max = 40 },
        { label = "Блок",        key = "BLOCK", tip = "BLOCK", value = function() return GetBlockChance() end, max = 60 },
        { label = "Защита",      key = "DEF",   tip = "DEF",   value = function()
            local base, modifier = UnitDefense("player")
            return (base or 0) + (modifier or 0)
        end, max = 600, plain = true },
    },
}
AXES.MELEE_MAGIC = AXES.MELEE

local RADAR_DIRS = { { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 0 } }
local RADAR_ORDER = { 1, 2, 4, 3 }

local function Box(parent, S, r, g, b, a, er, eg, eb, ea, radius)
    local box = CreateFrame("Frame", nil, parent)
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    box:SetBackdropColor(r, g, b, a)
    box:SetBackdropBorderColor(er, eg, eb, ea)
    S.RoundCorners(box, radius)
    return box
end

local function Text(parent, size, flags, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(NS.FONT, NS.FS(size), flags or "")
    return fs
end

function StatsPanel:BuildBadge(f, S)
    local centerX = 115

    local left = Box(f, S, S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85, S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.6, 6)
    left:SetSize(84, 32)
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -60)
    local eaLabel = Text(left, 8)
    eaLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    eaLabel:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -4)
    eaLabel:SetText(L["ЧАРЫ"])
    local eaValue = Text(left, 12, "OUTLINE")
    eaValue:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    eaValue:SetPoint("TOPLEFT", eaLabel, "BOTTOMLEFT", 0, -2)
    f.eaValue = eaValue

    local right = Box(f, S, S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85, S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.6, 6)
    right:SetSize(84, 32)
    right:SetPoint("TOPRIGHT", f, "TOPLEFT", 216, -60)
    local tierLabel = Text(right, 8)
    tierLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    tierLabel:SetPoint("TOPRIGHT", right, "TOPRIGHT", -8, -4)
    tierLabel:SetText(L["НАБОР"])
    local tierValue = Text(right, 12, "OUTLINE")
    tierValue:SetPoint("TOPRIGHT", tierLabel, "BOTTOMRIGHT", 0, -2)
    f.tierValue = tierValue

    local hex = CreateFrame("Frame", nil, f)
    hex:SetSize(80, 80)
    hex:SetPoint("CENTER", f, "TOPLEFT", centerX, -78)
    hex:SetFrameLevel(left:GetFrameLevel() + 3)

    local glow = hex:CreateTexture(nil, "BACKGROUND")
    glow:SetAllPoints(hex)
    glow:SetTexture(S.Media("HexGlow"))
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)
    S.AddBreathingGlow(glow, 0.2, 0.45, 2.5)

    local shadow = hex:CreateTexture(nil, "BACKGROUND", nil, 1)
    shadow:SetAllPoints(hex)
    shadow:SetTexture(S.Media("HexFill"))
    shadow:SetVertexColor(0, 0, 0, 0.6)

    local fill = hex:CreateTexture(nil, "BORDER")
    fill:SetPoint("TOPLEFT", hex, "TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", hex, "BOTTOMRIGHT", -3, 3)
    fill:SetTexture(S.Media("HexFill"))
    fill:SetVertexColor(S.Tint(0.05, 0.05, 0.09, 0.97))

    local inner = hex:CreateTexture(nil, "ARTWORK")
    inner:SetAllPoints(fill)
    inner:SetTexture(S.Media("HexInner"))
    inner:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.4)

    local ring = hex:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints(fill)
    ring:SetTexture(S.Media("HexRing"))
    ring:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)

    local maxLabel = Text(hex, 7)
    maxLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    maxLabel:SetPoint("CENTER", hex, "CENTER", 0, 11)
    maxLabel:SetText(L["УР.ПРЕДМ."])

    local maxValue = Text(hex, 20, "OUTLINE")
    maxValue:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    maxValue:SetPoint("CENTER", hex, "CENTER", 0, -4)
    f.maxValue = maxValue
end

function StatsPanel:BuildBanner(f, S)
    local banner = CreateFrame("Frame", nil, f)
    banner:SetSize(202, 36)
    banner:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -112)

    local art = banner:CreateTexture(nil, "BACKGROUND")
    art:SetAllPoints(banner)
    art:SetTexCoord(0, 1, 0.3, 0.58)
    f.bannerArt = art

    local shade = banner:CreateTexture(nil, "BORDER")
    shade:SetAllPoints(banner)
    shade:SetTexture(WHITE)
    shade:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.75, 0, 0, 0, 0.15)

    local edge = CreateFrame("Frame", nil, banner)
    edge:SetAllPoints(banner)
    edge:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    edge:SetBackdropBorderColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.7)
    S.RoundCorners(edge, 6, { edgeFile = WHITE, edgeSize = 1 })

    local spec = Text(edge, 12, "OUTLINE")
    spec:SetPoint("TOPLEFT", banner, "TOPLEFT", 10, -5)
    spec:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    f.bannerSpec = spec

    local role = Text(edge, 9)
    role:SetPoint("TOPLEFT", spec, "BOTTOMLEFT", 0, -2)
    role:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    f.bannerRole = role
end

function StatsPanel:BuildRadar(f, S)
    local block = Box(f, S, S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.55, S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    block:SetSize(204, 136)
    block:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -12)

    local canvas = CreateFrame("Frame", nil, block)
    canvas:SetSize(RADAR_SIZE, RADAR_SIZE)
    canvas:SetPoint("CENTER", block, "CENTER", 0, 0)

    local tr, tg, tb, ta = S.Tint(0.03, 0.03, 0.06, 0.9)
    local frameBox = Box(block, S, tr, tg, tb, ta, S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9, 6)
    frameBox:SetPoint("TOPLEFT", canvas, "TOPLEFT", -6, 6)
    frameBox:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", 6, -6)
    canvas:SetFrameLevel(frameBox:GetFrameLevel() + 2)

    local grid = canvas:CreateTexture(nil, "BACKGROUND")
    grid:SetAllPoints(canvas)
    grid:SetTexture(S.Media("RadarGrid"))
    grid:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 0.8)

    canvas.lines, canvas.dots, canvas.halos = {}, {}, {}
    for i = 1, 4 do
        local line = canvas:CreateTexture(nil, "ARTWORK")
        line:SetTexture(S.Media("Line"))
        line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        canvas.lines[i] = line

        local halo = canvas:CreateTexture(nil, "OVERLAY", nil, 1)
        halo:SetSize(18, 18)
        halo:SetTexture(S.GLOW)
        halo:SetBlendMode("ADD")
        halo:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.6)
        canvas.halos[i] = halo

        local dot = canvas:CreateTexture(nil, "OVERLAY", nil, 2)
        dot:SetSize(7, 7)
        dot:SetTexture(S.Media("RoundFill"))
        dot:SetVertexColor(1, 1, 1, 1)
        canvas.dots[i] = dot
    end
    f.radar = canvas

    local CELLS = {
        { "TOPLEFT", 8, -8, "LEFT" },
        { "TOPRIGHT", -8, -8, "RIGHT" },
        { "BOTTOMLEFT", 8, 8, "LEFT" },
        { "BOTTOMRIGHT", -8, 8, "RIGHT" },
    }
    f.radarCells = {}
    for i, spec in ipairs(CELLS) do
        local cell = CreateFrame("Frame", nil, block)
        cell:SetSize(54, 42)
        cell:SetPoint(spec[1], block, spec[1], spec[2], spec[3])
        cell:EnableMouse(true)

        local label = Text(cell, 9)
        label:SetPoint("TOP" .. spec[4], cell, "TOP" .. spec[4], 0, 0)
        label:SetJustifyH(spec[4])
        local value = Text(cell, 13, "OUTLINE")
        value:SetPoint("TOP" .. spec[4], label, "BOTTOM" .. spec[4], 0, -3)
        value:SetJustifyH(spec[4])
        local sub = Text(cell, 8)
        sub:SetPoint("TOP" .. spec[4], value, "BOTTOM" .. spec[4], 0, -2)
        sub:SetJustifyH(spec[4])
        sub:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])

        cell.label, cell.value, cell.sub = label, value, sub
        cell:SetScript("OnEnter", function(self)
            if self.tip and NS.StatTooltip then NS.StatTooltip:Show(self, self.tip) end
        end)
        cell:SetScript("OnLeave", function()
            if NS.StatTooltip then NS.StatTooltip:Hide() end
        end)
        f.radarCells[i] = cell
    end
end

function StatsPanel:BuildTabs(f, S)
    f.tabs = {}
    local TABS = { { "basic", L["Основные"] }, { "all", L["Все характеристики"] } }
    local x = 16
    for _, spec in ipairs(TABS) do
        local tab = CreateFrame("Button", nil, f)
        tab:SetHeight(18)
        tab:SetPoint("TOPLEFT", f, "TOPLEFT", x, -158)
        local label = Text(tab, 11)
        label:SetPoint("LEFT", tab, "LEFT", 0, 1)
        label:SetText(spec[2])
        tab:SetWidth(label:GetStringWidth() + 4)
        x = x + label:GetStringWidth() + 22

        local underline = tab:CreateTexture(nil, "ARTWORK")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, -1)
        underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, -1)
        underline:SetTexture(WHITE)
        underline:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        S.RoundTexture(underline, 1)

        tab.key, tab.label, tab.underline = spec[1], label, underline
        tab:SetScript("OnClick", function() StatsPanel:SetView(spec[1]) end)
        f.tabs[#f.tabs + 1] = tab
    end

    local rule = f:CreateTexture(nil, "BORDER")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -177)
    rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -177)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9, S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.1)
end

function StatsPanel:BuildBasic(f, S)
    local view = CreateFrame("Frame", nil, f)
    view:SetPoint("TOPLEFT", f, "TOPLEFT", 12, BASIC_TOP)
    view:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 8)
    f.basicView = view
    f.basicCells = {}

    local function Cell(stat, column, index)
        local x = (column - 1) * (BASIC_COL + 4)
        local y = -(index - 1) * BASIC_ROW

        local cell = CreateFrame("Frame", nil, view)
        cell:SetSize(BASIC_COL, BASIC_ROW - 1)
        cell:SetPoint("TOPLEFT", view, "TOPLEFT", x, y)
        cell:EnableMouse(true)

        local labelPlate = cell:CreateTexture(nil, "BACKGROUND")
        labelPlate:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        labelPlate:SetPoint("BOTTOMRIGHT", cell, "BOTTOMLEFT", BASIC_LABEL, 0)
        labelPlate:SetTexture(WHITE)
        S.RoundTexture(labelPlate, 3)

        local valuePlate = cell:CreateTexture(nil, "BACKGROUND")
        valuePlate:SetPoint("TOPLEFT", cell, "TOPLEFT", BASIC_LABEL + 2, 0)
        valuePlate:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
        valuePlate:SetTexture(WHITE)
        S.RoundTexture(valuePlate, 3)

        local label = Text(cell, 11)
        label:SetPoint("LEFT", cell, "LEFT", 8, 0)
        label:SetText(L[stat.label])

        local value = Text(cell, 11, "OUTLINE")
        value:SetPoint("RIGHT", cell, "RIGHT", -8, 0)
        value:SetJustifyH("RIGHT")

        cell.stat, cell.index = stat, index
        cell.labelPlate, cell.valuePlate = labelPlate, valuePlate
        cell.label, cell.value = label, value

        cell:SetScript("OnEnter", function(self)
            self.hover = true
            StatsPanel:PaintCell(self)
            if stat.tip and NS.StatTooltip then NS.StatTooltip:Show(self, stat.tip) end
        end)
        cell:SetScript("OnLeave", function(self)
            self.hover = false
            StatsPanel:PaintCell(self)
            if NS.StatTooltip then NS.StatTooltip:Hide() end
        end)
        f.basicCells[#f.basicCells + 1] = cell
    end

    for i, stat in ipairs(BASIC_LEFT) do Cell(stat, 1, i) end
    for i, stat in ipairs(BASIC_RIGHT) do Cell(stat, 2, i) end
end

function StatsPanel:PaintCell(cell)
    local S = NS.Styling
    local A = S.ACCENT
    local odd = cell.index % 2 == 1
    if cell.capped then
        cell.labelPlate:SetVertexColor(A[1], A[2], A[3], cell.hover and 0.42 or 0.30)
        cell.valuePlate:SetVertexColor(A[1], A[2], A[3], cell.hover and 0.32 or 0.20)
        cell.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    else
        local base = odd and 0.07 or 0.04
        local lift = cell.hover and 0.05 or 0
        cell.labelPlate:SetVertexColor(S.Tint(base + 0.03 + lift, base + 0.035 + lift, base + 0.05 + lift, 0.9))
        cell.valuePlate:SetVertexColor(S.Tint(base + lift, base + 0.005 + lift, base + 0.02 + lift, 0.9))
        cell.label:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    end
end

function StatsPanel:BuildAll(f, S, top)
    local view = CreateFrame("Frame", nil, f)
    view:SetPoint("TOPLEFT", f, "TOPLEFT", 0, top or BASIC_TOP)
    view:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.allView = view

    local legend = view:CreateFontString(nil, "OVERLAY")
    legend:SetFont(NS.FONT, NS.FS(9), "")
    legend:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    legend:SetPoint("TOPLEFT", view, "TOPLEFT", LEFT_X + LABEL_INSET + 11, -2)
    legend:SetJustifyH("LEFT")
    legend:SetText(L["важные статы"])

    local swatch = view:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(6, 6)
    swatch:SetPoint("RIGHT", legend, "LEFT", -5, 0)
    swatch:SetTexture(WHITE)
    swatch:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)

    f.capsLegend = legend
    f.capsSwatch = swatch

    local source = view:CreateFontString(nil, "OVERLAY")
    source:SetFont(NS.FONT, NS.FS(9), "")
    source:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    source:SetPoint("TOPRIGHT", view, "TOPRIGHT", -(PANEL_WIDTH - (RIGHT_X + COL_WIDTH)), -2)
    source:SetJustifyH("RIGHT")
    f.sourceText = source

    local scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", view, "TOPLEFT", 0, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -24, 8)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(LIST_WIDTH)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)

    local tableY = 0

    local function DividerHalf(upper)
        local t = scrollChild:CreateTexture(nil, "BACKGROUND")
        t:SetWidth(1)
        t:SetTexture(WHITE)
        local B = S.BORDER
        if upper then
            t:SetPoint("TOP", scrollChild, "TOPLEFT", DIVIDER_X, 0)
            t:SetPoint("BOTTOM", scrollChild, "LEFT", DIVIDER_X, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0.55, B[1], B[2], B[3], 0)
        else
            t:SetPoint("TOP", scrollChild, "LEFT", DIVIDER_X, 0)
            t:SetPoint("BOTTOM", scrollChild, "BOTTOMLEFT", DIVIDER_X, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0, B[1], B[2], B[3], 0.55)
        end
    end
    DividerHalf(true)
    DividerHalf(false)

    local function CreateHighlight(x1, x2, y)
        local plate = scrollChild:CreateTexture(nil, "BORDER")
        plate:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        plate:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", x2, y - ROW_HEIGHT + 3)
        plate:SetTexture(WHITE)
        plate:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.20,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
        plate:Hide()

        local bar = scrollChild:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        bar:SetPoint("BOTTOMLEFT", scrollChild, "TOPLEFT", x1, y - ROW_HEIGHT + 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()

        return { plate = plate, bar = bar }
    end

    local function CreateHover(x1, x2, y, id)
        local plate = scrollChild:CreateTexture(nil, "BORDER")
        plate:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        plate:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", x2, y - ROW_HEIGHT + 3)
        plate:SetTexture(WHITE)
        plate:SetGradientAlpha("HORIZONTAL",
            S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3], 0.12,
            S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3], 0.0)
        plate:Hide()

        local hover = CreateFrame("Frame", nil, scrollChild)
        hover:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        hover:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", x2, y - ROW_HEIGHT + 3)
        hover:EnableMouse(true)
        hover:SetScript("OnEnter", function(self)
            plate:Show()
            if NS.StatTooltip then NS.StatTooltip:Show(self, id) end
        end)
        hover:SetScript("OnLeave", function()
            plate:Hide()
            if NS.StatTooltip then NS.StatTooltip:Hide() end
        end)
    end

    f.statRows = {}
    local maxRows = math.max(#STAT_LEFT, #STAT_RIGHT)

    for i = 1, maxRows do
        local y = tableY - (i - 1) * ROW_HEIGHT
        local row = {}

        if i % 2 == 0 then
            local stripe = scrollChild:CreateTexture(nil, "BACKGROUND")
            stripe:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X, y + 2)
            stripe:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", RIGHT_X + COL_WIDTH, y - ROW_HEIGHT + 2)
            stripe:SetTexture(WHITE)
            stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.10)
        end

        if STAT_LEFT[i] then
            local ll = scrollChild:CreateFontString(nil, "OVERLAY")
            ll:SetFont(NS.FONT, NS.FS(11), "")
            ll:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            ll:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X + LABEL_INSET, y)
            ll:SetWidth(LABEL_WIDTH)
            ll:SetJustifyH("LEFT")
            ll:SetText(L[STAT_LEFT[i].label])
            local lv = scrollChild:CreateFontString(nil, "OVERLAY")
            lv:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
            lv:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            lv:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X + COL_WIDTH - VALUE_WIDTH, y)
            lv:SetWidth(VALUE_WIDTH)
            lv:SetJustifyH("RIGHT")
            row.leftValue = lv
            row.leftFunc = STAT_LEFT[i].func
            row.leftLabel = ll
            row.leftKey = STAT_LEFT[i].key
            if row.leftKey then
                row.leftHL = CreateHighlight(LEFT_X, LEFT_X + COL_WIDTH, y)
            end
            if STAT_LEFT[i].tip then
                CreateHover(LEFT_X, LEFT_X + COL_WIDTH, y, STAT_LEFT[i].tip)
            end
        end

        if STAT_RIGHT[i] then
            local rl = scrollChild:CreateFontString(nil, "OVERLAY")
            rl:SetFont(NS.FONT, NS.FS(11), "")
            rl:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            rl:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_X + LABEL_INSET, y)
            rl:SetWidth(LABEL_WIDTH)
            rl:SetJustifyH("LEFT")
            rl:SetText(L[STAT_RIGHT[i].label])
            local rv = scrollChild:CreateFontString(nil, "OVERLAY")
            rv:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
            rv:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            rv:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_X + COL_WIDTH - VALUE_WIDTH, y)
            rv:SetWidth(VALUE_WIDTH)
            rv:SetJustifyH("RIGHT")
            row.rightValue = rv
            row.rightFunc = STAT_RIGHT[i].func
            row.rightLabel = rl
            row.rightKey = STAT_RIGHT[i].key
            if row.rightKey then
                row.rightHL = CreateHighlight(RIGHT_X, RIGHT_X + COL_WIDTH, y)
            end
            if STAT_RIGHT[i].tip then
                CreateHover(RIGHT_X, RIGHT_X + COL_WIDTH, y, STAT_RIGHT[i].tip)
            end
        end

        f.statRows[i] = row
    end

    scrollChild:SetHeight(maxRows * ROW_HEIGHT + 4)
end

function StatsPanel:BuildSimpleHeader(f, S)
    local nameLabel = Text(f, 18, "OUTLINE")
    nameLabel:SetPoint("TOP", f, "TOP", 0, -12)
    f.nameLabel = nameLabel

    local titleLine = Text(f, 11)
    titleLine:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    titleLine:SetPoint("TOP", nameLabel, "BOTTOM", 0, -2)
    f.titleLine = titleLine

    local barY = -48
    local infoBox = CreateFrame("Frame", nil, f)
    infoBox:SetSize(PANEL_WIDTH - 20, 42)
    infoBox:SetPoint("TOP", f, "TOP", 0, barY - 4)
    infoBox:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    infoBox:SetBackdropColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.6)
    infoBox:SetBackdropBorderColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.35)

    local eaLabel = Text(infoBox, 9)
    eaLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    eaLabel:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 10, -4)
    eaLabel:SetText(L["ЧАРЫ"])
    local eaValue = Text(infoBox, 13, "OUTLINE")
    eaValue:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    eaValue:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 10, -17)
    f.eaValue = eaValue

    local maxBox = CreateFrame("Frame", nil, infoBox)
    maxBox:SetSize(84, 36)
    maxBox:SetPoint("CENTER", infoBox, "CENTER", 0, 0)
    maxBox:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    maxBox:SetBackdropColor(S.Tint(0.04, 0.04, 0.08, 0.9))
    maxBox:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
    local maxLbl = Text(maxBox, 8)
    maxLbl:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    maxLbl:SetPoint("TOP", maxBox, "TOP", 0, -3)
    maxLbl:SetText(L["УР.ПРЕДМ."])
    local maxVal = Text(maxBox, 20, "OUTLINE")
    maxVal:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    maxVal:SetPoint("TOP", maxLbl, "BOTTOM", 0, -1)
    f.maxValue = maxVal

    local maxGlow = maxBox:CreateTexture(nil, "OVERLAY", nil, -1)
    maxGlow:SetAllPoints(maxVal)
    maxGlow:SetTexture(WHITE)
    maxGlow:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.3)
    S.AddBreathingGlow(maxGlow, 0.15, 0.35, 2.5)

    local tierLabel = Text(infoBox, 9)
    tierLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    tierLabel:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -10, -4)
    tierLabel:SetText(L["НАБОР"])
    local tierValue = Text(infoBox, 13, "OUTLINE")
    tierValue:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -10, -17)
    f.tierValue = tierValue

    S.CreateAnimatedSeparator(f, barY - 52)
end

function StatsPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = (NS.NarciUI and NS.NarciUI.mainFrame) or UIParent

    local f = CreateFrame("Frame", "NarcissusSirus_StatsPanel", parent)
    f:SetWidth(PANEL_WIDTH)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = WHITE,
            edgeFile = WHITE,
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    if NS.TabStyle and not NS.TabStyle.Styled() then
        self:BuildSimpleHeader(f, S)
        self:BuildAll(f, S, -102)
        self.frame = f
        f:Hide()
        return
    end

    local nameLabel = Text(f, 18, "OUTLINE")
    nameLabel:SetPoint("TOP", f, "TOPLEFT", 115, -14)
    nameLabel:SetWidth(206)
    f.nameLabel = nameLabel

    local titleLine = Text(f, 10)
    titleLine:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    titleLine:SetPoint("TOP", nameLabel, "BOTTOM", 0, -3)
    titleLine:SetWidth(206)
    titleLine:SetHeight(12)
    f.titleLine = titleLine

    self:BuildBadge(f, S)
    self:BuildBanner(f, S)
    self:BuildRadar(f, S)
    self:BuildTabs(f, S)
    self:BuildBasic(f, S)
    self:BuildAll(f, S)

    self.frame = f
    self:SetView(NS.db and NS.db.statsView or "basic")
    f:Hide()
end

function StatsPanel:SetView(key)
    local f = self.frame
    if not f or not f.tabs then return end
    if key ~= "all" then key = "basic" end
    if NS.db then NS.db.statsView = key end
    local S = NS.Styling
    for _, tab in ipairs(f.tabs) do
        local active = tab.key == key
        if active then
            tab.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            tab.underline:Show()
        else
            tab.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            tab.underline:Hide()
        end
    end
    if key == "all" then
        f.basicView:Hide()
        f.allView:Show()
    else
        f.allView:Hide()
        f.basicView:Show()
    end
end

function StatsPanel:UpdateRadar(f, role, priority)
    local S = NS.Styling
    local axes = AXES[role or ""] or AXES.MELEE
    local canvas = f.radar
    local reach = RADAR_SIZE * RADAR_REACH
    local points = {}

    for i, axis in ipairs(axes) do
        local ok, raw = pcall(axis.value)
        local number = (ok and tonumber(raw)) or 0
        local norm = math.max(0.06, math.min(1, number / axis.max))
        local dir = RADAR_DIRS[i]
        points[i] = { dir[1] * reach * norm, dir[2] * reach * norm }

        local cell = f.radarCells[i]
        cell.tip = axis.tip
        cell.label:SetText(L[axis.label])
        local capped = axis.key and priority[axis.key]
        if capped then
            cell.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            cell.label:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
        if axis.plain then
            cell.value:SetText(floor(number + 0.5))
        else
            cell.value:SetText(format("%.2f%%", number))
        end
        cell.value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        if axis.rating then
            local okr, rating = pcall(axis.rating)
            cell.sub:SetText(okr and rating and tostring(floor(rating)) or "")
        else
            cell.sub:SetText("")
        end

        local dot, halo = canvas.dots[i], canvas.halos[i]
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", canvas, "CENTER", points[i][1], points[i][2])
        halo:ClearAllPoints()
        halo:SetPoint("CENTER", dot, "CENTER", 0, 0)
    end

    if type(DrawLine) ~= "function" then
        for _, line in ipairs(canvas.lines) do line:Hide() end
        return
    end
    for n = 1, 4 do
        local a = points[RADAR_ORDER[n]]
        local b = points[RADAR_ORDER[n % 4 + 1]]
        local line = canvas.lines[n]
        line:ClearAllPoints()
        local ok = pcall(DrawLine, line, canvas, a[1], a[2], b[1], b[2], 4, 1, "CENTER")
        if ok then line:Show() else line:Hide() end
    end
end

function StatsPanel:UpdateBanner(f, info)
    local S = NS.Styling
    local tab = info and info.tab
    local background
    if tab then
        local ok, _, _, _, bg = pcall(GetTalentTabInfo, tab)
        if ok then background = bg end
    end
    if background and background ~= "" then
        f.bannerArt:SetTexture("Interface\\TalentFrame\\" .. background .. "-TopLeft")
        f.bannerArt:SetVertexColor(1, 1, 1, 1)
    else
        f.bannerArt:SetTexture(WHITE)
        f.bannerArt:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.35)
    end
    local _, localizedClass = UnitClass("player")
    f.bannerSpec:SetText((info and info.specName) or localizedClass or "")
    f.bannerRole:SetText((info and info.roleName) or "")
end

function StatsPanel:Update()
    if not self.frame then self:Create() end
    local S = NS.Styling
    local f = self.frame

    local showCaps = not NS.db or NS.db.showStatCaps ~= false
    local priority, info, tierText, sourceText
    if NS.StatPriority then
        local ok, set, detected = pcall(NS.StatPriority.Get, NS.StatPriority)
        if ok then
            priority, info = set, detected
            local okt, t = pcall(NS.StatPriority.GetTierLabel, NS.StatPriority, info)
            if okt then tierText = t end
            local oks, s = pcall(NS.StatPriority.GetSourceLabel, NS.StatPriority, info)
            if oks then sourceText = s end
        end
    end
    priority = (showCaps and priority) or {}
    f.sourceText:SetText(showCaps and (sourceText or "") or "")
    if showCaps then
        f.capsLegend:Show()
        f.capsSwatch:Show()
    else
        f.capsLegend:Hide()
        f.capsSwatch:Hide()
    end

    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        f.nameLabel:SetText(format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))
    else
        f.nameLabel:SetText(name or "")
    end
    local level = UnitLevel("player")
    local localizedClass = UnitClass("player")
    local subtitle
    if f.radar then
        local guild = GetGuildInfo("player")
        subtitle = format("|cff00ccff%d|r %s", level, localizedClass)
        if guild then
            subtitle = guild .. "  |  " .. subtitle
        else
            subtitle = format("|cff00ccff%d|r %s %s", level, UnitRace("player") or "", localizedClass)
        end
    else
        subtitle = format("|cff00ccff%d|r %s %s", level, UnitRace("player") or "", localizedClass)
        if info and info.specName then
            subtitle = subtitle .. format("  |cff%02x%02x%02x%s|r",
                S.ACCENT_GLOW[1] * 255, S.ACCENT_GLOW[2] * 255, S.ACCENT_GLOW[3] * 255, info.specName)
        end
    end
    f.titleLine:SetText(subtitle)

    f.maxValue:SetText(floor(NS.GetAverageItemLevel()))
    local enchantCount, totalEnchantable = 0, 0
    for slotId, _ in pairs(NS.ENCHANTABLE_SLOTS or {}) do
        totalEnchantable = totalEnchantable + 1
        local link = GetInventoryItemLink("player", slotId)
        if link and NS.GetEnchantInfo(link) then enchantCount = enchantCount + 1 end
    end
    f.eaValue:SetText(format("%d/%d", enchantCount, totalEnchantable))
    f.tierValue:SetText(tierText or L["нет"])
    if info and info.tier then
        f.tierValue:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    else
        f.tierValue:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if f.radar then
        self:UpdateBanner(f, info)
        self:UpdateRadar(f, info and info.role, priority)
    end

    for _, cell in ipairs(f.basicCells or {}) do
        local ok, val = pcall(cell.stat.func)
        local text = ok and tostring(val) or "-"
        local valueColor = ValueColor(text)
        local changed = cell.value:GetText() ~= text
        cell.value:SetText(text)
        cell.value:SetTextColor(valueColor[1], valueColor[2], valueColor[3])
        if changed then S.FlashValue(cell.value, 0.35, valueColor) end
        cell.capped = (cell.stat.key and priority[cell.stat.key]) and true or false
        self:PaintCell(cell)
    end

    local function UpdateValue(fs, func)
        if not func then return end
        local ok, val = pcall(func)
        local newText = ok and tostring(val) or "-"
        local valueColor = ValueColor(newText)
        local changed = fs:GetText() ~= newText
        fs:SetText(newText)
        fs:SetTextColor(valueColor[1], valueColor[2], valueColor[3])
        if changed then S.FlashValue(fs, 0.35, valueColor) end
    end

    local function UpdateLabel(fs, hl, key)
        if not fs then return end
        local on = (key and priority[key]) and true or false
        if on then
            fs:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            fs:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
        if hl then
            if on then
                hl.plate:Show()
                hl.bar:Show()
            else
                hl.plate:Hide()
                hl.bar:Hide()
            end
        end
    end

    for _, row in ipairs(f.statRows) do
        UpdateValue(row.leftValue, row.leftFunc)
        UpdateValue(row.rightValue, row.rightFunc)
        UpdateLabel(row.leftLabel, row.leftHL, row.leftKey)
        UpdateLabel(row.rightLabel, row.rightHL, row.rightKey)
    end
end

function StatsPanel:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function StatsPanel:Hide() NS.Styling.PanelHideNow(self.frame) end

NS.StatsPanel = StatsPanel
