local addonName, NS = ...
local L = NS.L

local Plates = {}
NS.Nameplates = Plates

local WHITE = "Interface\\Buttons\\WHITE8x8"
local SHADED = "Interface\\TargetingFrame\\UI-StatusBar"
local RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

local STYLES = {
    { key = "obsidian", name = "Обсидиан", width = 120, height = 10, texture = "flat", border = "thin", accentTop = true,
      nameAt = "above", nameAlign = "LEFT", hpAt = "header", level = "header", sheen = true },
    { key = "classic", name = "Классика", width = 116, height = 10, texture = "shaded", border = "classic",
      nameAt = "above", nameAlign = "CENTER", hpAt = "none", level = "right" },
    { key = "pixel", name = "Пиксель", width = 112, height = 8, texture = "flat", border = "pixel",
      nameAt = "above", nameAlign = "CENTER", hpAt = "none", level = "none" },
    { key = "neon", name = "Неон", width = 118, height = 9, texture = "gradient", border = "glow",
      nameAt = "above", nameAlign = "CENTER", nameColor = "health", hpAt = "center", level = "none" },
    { key = "glass", name = "Стекло", width = 122, height = 11, texture = "flat", border = "accent", bgAlpha = 0.25,
      nameAt = "above", nameAlign = "LEFT", hpAt = "right", level = "none", sheen = true, sheenStrong = true },
    { key = "slim", name = "Тонкие", width = 100, height = 4, texture = "flat", border = "pixel",
      nameAt = "above", nameAlign = "CENTER", nameSize = 9, hpAt = "none", level = "none" },
    { key = "thick", name = "Крупные", width = 140, height = 18, texture = "flat", border = "thin",
      nameAt = "inside", hpAt = "right", level = "none", sheen = true },
    { key = "plates", name = "Плашки", width = 118, height = 8, texture = "flat", border = "pixel",
      nameAt = "above", nameAlign = "CENTER", namePlate = true, hpAt = "none", level = "none" },
    { key = "graphite", name = "Графит", width = 124, height = 10, texture = "shaded", border = "thin", bgColor = { 0.16, 0.16, 0.17 },
      ticks = 4, nameAt = "above", nameAlign = "LEFT", nameColor = "grey", hpAt = "header", level = "header" },
    { key = "quatre", name = "Кватро", width = 116, height = 12, texture = "shaded", border = "pixel",
      nameAt = "above", nameAlign = "LEFT", hpAt = "right", level = "box" },
    { key = "minimal", name = "Минимал", width = 96, height = 2, texture = "flat", border = "none", bgAlpha = 0.35,
      nameAt = "above", nameAlign = "CENTER", nameColor = "health", nameSize = 11, hpAt = "none", level = "none" },
    { key = "segments", name = "Сегменты", width = 120, height = 10, texture = "flat", border = "pixel", ticks = 10,
      nameAt = "above", nameAlign = "CENTER", hpAt = "none", level = "none" },
    { key = "gradient", name = "Градиент", width = 120, height = 10, texture = "gradient", border = "none", shadow = true,
      nameAt = "above", nameAlign = "LEFT", hpAt = "header", level = "none" },
    { key = "shadow", name = "Тень", width = 118, height = 9, texture = "smooth", border = "none", shadow = true,
      nameAt = "below", nameAlign = "CENTER", hpAt = "right", level = "none" },
    { key = "tactic", name = "Тактика", width = 132, height = 12, texture = "flat", border = "thick",
      threatGlow = true, nameAt = "above", nameAlign = "LEFT", hpAt = "both", level = "box" },
    { key = "compact", name = "Компактные", width = 82, height = 7, texture = "smooth", border = "pixel",
      nameAt = "above", nameAlign = "CENTER", nameSize = 8, hpAt = "outside", level = "none" },
}
Plates.STYLES = STYLES

local STYLE_BY_KEY = {}
for _, style in ipairs(STYLES) do STYLE_BY_KEY[style.key] = style end

local REQUIRED = { "width", "height", "texture", "border", "nameAt", "nameAlign", "hpAt", "level" }

function Plates:AddStyle(row)
    if type(row) ~= "table" or type(row.key) ~= "string" or STYLE_BY_KEY[row.key] then return false end
    for _, field in ipairs(REQUIRED) do
        if row[field] == nil then row[field] = STYLES[1][field] end
    end
    row.name = row.name or row.key
    STYLES[#STYLES + 1] = row
    STYLE_BY_KEY[row.key] = row
    return true
end

local DEFAULTS = {
    enabled = true,
    style = "obsidian",
    scale = 100,
    widthScale = 100,
    heightScale = 100,
    hpText = "style",
    showName = true,
    showLevel = true,
    classColorEnemy = true,
    classColorFriend = true,
    target = "glow",
    targetScale = 110,
    otherAlpha = 70,
    castBar = true,
    castIcon = true,
    debuffs = true,
    debuffSize = 18,
    debuffCount = 5,
    threat = "off",
    execute = false,
    executeAt = 20,
    raidIcon = true,
    filtersOn = true,
}

local filledSettings

local function Settings()
    if not NS.db then return end
    if type(NS.db.nameplates) ~= "table" then NS.db.nameplates = {} end
    local db = NS.db.nameplates
    if db == filledSettings then return db end
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    filledSettings = db
    return db
end
Plates.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function Style()
    local db = Settings()
    return STYLE_BY_KEY[db and db.style] or STYLES[1]
end

function Plates:TidyLoaded()
    return IsAddOnLoaded and IsAddOnLoaded("TidyPlates") and true or false
end

function Plates:NewSystem()
    return C_NamePlate and C_NamePlate.GetNamePlateForUnit and GetCVar and GetCVar("nameplateEnableNew") ~= "0" and true or false
end

function Plates:Blocked()
    if not self:NewSystem() then return "old" end
    if self:TidyLoaded() then return "tidy" end
end

local active = {}
local plates = {}
local lastMouse

local function Edges(parent, layer, size)
    local lines = {}
    for index = 1, 4 do
        local line = parent:CreateTexture(nil, layer or "BORDER")
        line:SetTexture(WHITE)
        lines[index] = line
    end
    size = size or 1
    lines[1]:SetHeight(size)
    lines[1]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    lines[1]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    lines[2]:SetHeight(size)
    lines[2]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    lines[2]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    lines[3]:SetWidth(size)
    lines[3]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    lines[3]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    lines[4]:SetWidth(size)
    lines[4]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    lines[4]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    return lines
end

local function ColorLines(lines, r, g, b, a)
    for _, line in ipairs(lines) do
        line:SetVertexColor(r, g, b, a or 1)
        line:Show()
    end
end

local function HideLines(lines)
    for _, line in ipairs(lines) do line:Hide() end
end

local function Glow(parent)
    return NS.Styling.GlowPieces(parent, 6, "BACKGROUND", "ADD")
end

local function ColorGlow(glow, r, g, b, a)
    for _, texture in ipairs(glow) do
        texture:SetVertexColor(r, g, b, a)
        texture:Show()
    end
end

local function HideGlow(glow)
    for _, texture in ipairs(glow) do texture:Hide() end
end

local function ShortValue(value)
    if value >= 1000000 then return string.format("%.1fm", value / 1000000) end
    if value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end

local function HealthText(mode, health, maxHealth)
    if maxHealth <= 0 then return "" end
    local percent = math.floor(health / maxHealth * 100 + 0.5)
    if mode == "percent" then return percent .. "%" end
    if mode == "value" then return ShortValue(health) end
    if mode == "both" then return ShortValue(health) .. " | " .. percent .. "%" end
    if mode == "deficit" then
        local missing = maxHealth - health
        return missing > 0 and ("-" .. ShortValue(missing)) or ""
    end
    return ""
end

local function Font(text, size, flags)
    NS.LSetFont(text, "nameplates", NS.FS(size), flags or "OUTLINE")
    text:SetShadowOffset(0, 0)
end

local function CreatePlate(parent)
    local S = NS.Styling

    local p = CreateFrame("Frame", nil, parent)
    p:SetSize(120, 30)
    p:EnableMouse(false)

    local health = CreateFrame("StatusBar", nil, p)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    p.health = health

    p.bg = health:CreateTexture(nil, "BACKGROUND")
    p.bg:SetAllPoints(health)
    p.bg:SetTexture(WHITE)

    p.highlight = health:CreateTexture(nil, "OVERLAY")
    p.highlight:SetAllPoints(health)
    p.highlight:SetTexture(WHITE)
    p.highlight:SetBlendMode("ADD")
    p.highlight:SetVertexColor(1, 1, 1, 0.18)
    p.highlight:Hide()

    p.sheen = health:CreateTexture(nil, "OVERLAY")
    p.sheen:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
    p.sheen:SetPoint("BOTTOMRIGHT", health, "RIGHT", 0, 0)
    p.sheen:SetTexture(WHITE)

    p.outer = CreateFrame("Frame", nil, p)
    p.outer:SetFrameLevel(health:GetFrameLevel() + 2)
    p.outerLines = Edges(p.outer, "OVERLAY", 1)
    p.innerLines = Edges(health, "OVERLAY", 1)

    p.accentTop = health:CreateTexture(nil, "OVERLAY")
    p.accentTop:SetHeight(1)
    p.accentTop:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, 1)
    p.accentTop:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 1)
    p.accentTop:SetTexture(WHITE)
    p.accentTop:SetGradientAlpha("HORIZONTAL", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    p.glow = Glow(health)
    p.targetGlow = Glow(p.outer)

    p.shadowHolder = S.CreateSoftShadow and S.CreateSoftShadow(health, 5, 0.6)

    p.ticks = {}
    for index = 1, 9 do
        local tick = health:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(WHITE)
        tick:SetVertexColor(0, 0, 0, 0.55)
        tick:SetWidth(1)
        tick:SetPoint("TOP", health, "TOP", 0, 0)
        tick:SetPoint("BOTTOM", health, "BOTTOM", 0, 0)
        p.ticks[index] = tick
    end

    p.underline = p.outer:CreateTexture(nil, "OVERLAY")
    p.underline:SetHeight(2)
    p.underline:SetTexture(WHITE)

    p.namePlate = health:CreateTexture(nil, "BACKGROUND")
    p.namePlate:SetTexture(WHITE)

    p.name = p.outer:CreateFontString(nil, "OVERLAY")
    p.name:SetNonSpaceWrap(false)
    p.hp = p.outer:CreateFontString(nil, "OVERLAY")
    p.level = p.outer:CreateFontString(nil, "OVERLAY")

    p.levelBox = CreateFrame("Frame", nil, p)
    p.levelBox.bg = p.levelBox:CreateTexture(nil, "BACKGROUND")
    p.levelBox.bg:SetAllPoints(p.levelBox)
    p.levelBox.bg:SetTexture(WHITE)
    p.levelBox.lines = Edges(p.levelBox, "BORDER", 1)

    p.skull = p.outer:CreateTexture(nil, "OVERLAY")
    p.skull:SetTexture(SKULL)
    p.skull:SetSize(12, 12)

    p.raid = p.outer:CreateTexture(nil, "OVERLAY")
    p.raid:SetTexture(RAID_ICONS)
    p.raid:SetSize(18, 18)
    p.raid:SetPoint("RIGHT", health, "LEFT", -4, 0)

    local cast = CreateFrame("StatusBar", nil, p)
    cast:Hide()
    p.cast = cast
    cast.bg = cast:CreateTexture(nil, "BACKGROUND")
    cast.bg:SetAllPoints(cast)
    cast.bg:SetTexture(WHITE)
    cast.bg:SetVertexColor(0, 0, 0, 0.6)
    cast.lines = Edges(cast, "OVERLAY", 1)
    cast.icon = cast:CreateTexture(nil, "OVERLAY")
    cast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cast.iconFrame = CreateFrame("Frame", nil, cast)
    cast.iconLines = Edges(cast.iconFrame, "OVERLAY", 1)
    cast.text = cast:CreateFontString(nil, "OVERLAY")
    cast.text:SetNonSpaceWrap(false)
    cast.time = cast:CreateFontString(nil, "OVERLAY")

    p.auras = CreateFrame("Frame", nil, p)
    p.auras:SetSize(1, 1)
    p.auraIcons = {}

    return p
end

local function TextureFor(kind)
    if kind == "shaded" then return SHADED end
    if kind == "smooth" then return NS.Styling.Media("BarSoft") end
    return WHITE
end

function Plates:ApplyStyle(p)
    local db = Settings()
    local st = Style()
    local S = NS.Styling

    local width = math.floor(st.width * db.widthScale / 100 + 0.5)
    local height = math.max(2, math.floor(st.height * db.heightScale / 100 + 0.5))
    p.width, p.height, p.style = width, height, st

    p:SetScale(p.preview and 1 or db.scale / 100)
    p:SetSize(width, height + 30)

    local health = p.health
    health:ClearAllPoints()
    health:SetPoint("CENTER", p, "CENTER", 0, 0)
    health:SetSize(width, height)
    NS.Look:SetBar(health, "nameplates", TextureFor(st.texture))

    local bg = st.bgColor or { 0.04, 0.045, 0.06 }
    local gr, gg, gb = NS.Look:Color("nameplates", "bg")
    if gr then bg = { gr, gg, gb } end
    p.bg:SetVertexColor(bg[1], bg[2], bg[3], st.bgAlpha or 0.75)

    p.sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, st.sheenStrong and 0.22 or 0.1)
    p.sheen:SetShown(st.sheen and true or false)
    p.accentTop:SetShown(st.accentTop and true or false)

    p.outer:ClearAllPoints()
    local pad = st.border == "thick" and 2 or 1
    p.outer:SetPoint("TOPLEFT", health, "TOPLEFT", -pad, pad)
    p.outer:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", pad, -pad)

    p.outerLines[1]:SetHeight(pad)
    p.outerLines[2]:SetHeight(pad)
    p.outerLines[3]:SetWidth(pad)
    p.outerLines[4]:SetWidth(pad)

    HideLines(p.innerLines)
    if st.border == "thin" or st.border == "thick" then
        ColorLines(p.outerLines, S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
    elseif st.border == "pixel" then
        ColorLines(p.outerLines, 0, 0, 0, 1)
    elseif st.border == "classic" then
        ColorLines(p.outerLines, 0, 0, 0, 1)
        ColorLines(p.innerLines, 0.72, 0.6, 0.28, 0.9)
    elseif st.border == "accent" then
        ColorLines(p.outerLines, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.85)
    else
        HideLines(p.outerLines)
    end
    local er, eg, eb = NS.Look:Color("nameplates", "border")
    if er and st.border ~= "none" and st.border ~= "glow" then
        ColorLines(p.outerLines, er, eg, eb, 1)
    end

    if st.border ~= "glow" then HideGlow(p.glow) end
    if p.shadowHolder then p.shadowHolder:SetShown(st.shadow and true or false) end

    for index, tick in ipairs(p.ticks) do
        local count = st.ticks
        if count and index < count then
            tick:ClearAllPoints()
            tick:SetPoint("TOP", health, "TOPLEFT", width * index / count, 0)
            tick:SetPoint("BOTTOM", health, "BOTTOMLEFT", width * index / count, 0)
            tick:Show()
        else
            tick:Hide()
        end
    end

    local nameSize = st.nameSize or 10
    Font(p.name, nameSize)
    Font(p.hp, math.max(7, nameSize - 1))
    Font(p.level, math.max(7, nameSize - 1))

    p.name:ClearAllPoints()
    p.name:SetHeight(NS.FS(nameSize) + 2)
    p.name:SetJustifyH(st.nameAt == "inside" and "LEFT" or (st.nameAlign or "CENTER"))

    local headerRight = (st.hpAt == "header" or st.level == "header") and 40 or 0
    if st.nameAt == "inside" then
        p.name:SetPoint("LEFT", health, "LEFT", 4, 0)
        p.name:SetWidth(width - 48)
    elseif st.nameAt == "below" then
        p.name:SetPoint("TOP", health, "BOTTOM", 0, -3)
        p.name:SetWidth(width + 30)
    else
        local gap = st.namePlate and 5 or 3
        if st.nameAlign == "LEFT" then
            p.name:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, gap)
            p.name:SetWidth(width - headerRight)
        else
            p.name:SetPoint("BOTTOM", health, "TOP", 0, gap)
            p.name:SetWidth(width + 30)
        end
    end
    p.name:SetShown(db.showName and st.nameAt ~= "none")

    p.namePlate:ClearAllPoints()
    if st.namePlate then
        p.namePlate:SetPoint("TOPLEFT", p.name, "TOPLEFT", -4, 2)
        p.namePlate:SetPoint("BOTTOMRIGHT", p.name, "BOTTOMRIGHT", 4, -2)
        p.namePlate:SetVertexColor(S.Tint(0.03, 0.035, 0.05, 0.8))
        p.namePlate:Show()
    else
        p.namePlate:Hide()
    end

    local hpAt = st.hpAt
    if db.hpText ~= "style" and db.hpText ~= "none" and hpAt == "none" then hpAt = "right" end
    p.hpAt = hpAt
    p.hp:ClearAllPoints()
    if hpAt == "header" then
        p.hp:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 3)
        p.hp:SetJustifyH("RIGHT")
    elseif hpAt == "center" then
        p.hp:SetPoint("CENTER", health, "CENTER", 0, 0)
        p.hp:SetJustifyH("CENTER")
    elseif hpAt == "outside" then
        p.hp:SetPoint("LEFT", health, "RIGHT", 3, 0)
        p.hp:SetJustifyH("LEFT")
    elseif hpAt == "both" or hpAt == "right" then
        p.hp:SetPoint("RIGHT", health, "RIGHT", -3, 0)
        p.hp:SetJustifyH("RIGHT")
    end
    if height < 8 and (hpAt == "right" or hpAt == "center" or hpAt == "both") then
        p.hp:ClearAllPoints()
        p.hp:SetPoint("LEFT", health, "RIGHT", 3, 0)
    end
    p.hp:SetShown(hpAt ~= "none" and db.hpText ~= "none")

    p.level:ClearAllPoints()
    p.levelBox:Hide()
    if st.level == "header" then
        if hpAt == "header" then
            p.level:SetPoint("RIGHT", p.hp, "LEFT", -4, 0)
        else
            p.level:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 3)
        end
    elseif st.level == "right" then
        p.level:SetPoint("LEFT", health, "RIGHT", 4, 0)
    elseif st.level == "box" then
        local box = height + 6
        p.levelBox:SetSize(box, box)
        p.levelBox:ClearAllPoints()
        p.levelBox:SetPoint("RIGHT", health, "LEFT", -pad - 2, 0)
        p.levelBox.bg:SetVertexColor(S.Tint(0.03, 0.035, 0.05, 0.9))
        ColorLines(p.levelBox.lines, 0, 0, 0, 1)
        p.levelBox:Show()
        p.level:SetPoint("CENTER", p.levelBox, "CENTER", 0, 0)
    end
    p.level:SetShown(db.showLevel and st.level ~= "none")

    p.skull:ClearAllPoints()
    p.skull:SetPoint("CENTER", p.level, "CENTER", 0, 0)

    p.raid:ClearAllPoints()
    if st.level == "box" then
        p.raid:SetPoint("BOTTOM", p.levelBox, "TOP", 0, 2)
    else
        p.raid:SetPoint("RIGHT", health, "LEFT", -4, 0)
    end

    p.underline:ClearAllPoints()
    p.underline:SetPoint("TOPLEFT", p.outer, "BOTTOMLEFT", 0, -2)
    p.underline:SetPoint("TOPRIGHT", p.outer, "BOTTOMRIGHT", 0, -2)
    p.underline:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    p.underline:Hide()
    HideGlow(p.targetGlow)

    local cast = p.cast
    local castHeight = math.max(6, math.min(12, height))
    cast:ClearAllPoints()
    if st.nameAt == "below" and db.showName then
        cast:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -(NS.FS(nameSize) + 6))
    else
        cast:SetPoint("TOPLEFT", p.outer, "BOTTOMLEFT", pad, -3)
    end
    cast:SetWidth(width)
    cast:SetHeight(castHeight)
    NS.Look:SetBar(cast, "nameplates", TextureFor(st.texture == "gradient" and "flat" or st.texture))
    ColorLines(cast.lines, 0, 0, 0, 1)
    cast.iconFrame:ClearAllPoints()
    local iconSize = castHeight + height + 4
    cast.iconFrame:SetSize(iconSize, iconSize)
    cast.iconFrame:SetPoint("BOTTOMRIGHT", cast, "BOTTOMLEFT", -3, 0)
    cast.icon:ClearAllPoints()
    cast.icon:SetPoint("TOPLEFT", cast.iconFrame, "TOPLEFT", 1, -1)
    cast.icon:SetPoint("BOTTOMRIGHT", cast.iconFrame, "BOTTOMRIGHT", -1, 1)
    ColorLines(cast.iconLines, 0, 0, 0, 1)
    cast.iconFrame:SetShown(db.castIcon)
    cast.icon:SetShown(db.castIcon)
    Font(cast.text, math.max(7, castHeight - 1))
    Font(cast.time, math.max(7, castHeight - 1))
    cast.text:ClearAllPoints()
    cast.text:SetPoint("LEFT", cast, "LEFT", 3, 0)
    cast.text:SetPoint("RIGHT", cast, "RIGHT", -26, 0)
    cast.text:SetJustifyH("LEFT")
    cast.text:SetHeight(castHeight + 2)
    cast.time:ClearAllPoints()
    cast.time:SetPoint("RIGHT", cast, "RIGHT", -3, 0)

    p.auras:ClearAllPoints()
    local nameShown = db.showName and st.nameAt == "above"
    p.auras:SetPoint("BOTTOM", health, "TOP", 0, (nameShown and (NS.FS(nameSize) + 8) or 6))
    for _, icon in ipairs(p.auraIcons) do
        icon:SetSize(db.debuffSize, math.floor(db.debuffSize * 0.75 + 0.5))
    end
end

local function ReactionColor(unit)
    if UnitIsTapped and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitPlayerControlled(unit) then
        return 0.55, 0.55, 0.55
    end
    local reaction = UnitReaction(unit, "player") or 4
    if reaction <= 3 then return 0.85, 0.22, 0.2 end
    if reaction == 4 then return 0.92, 0.78, 0.22 end
    return 0.28, 0.78, 0.32
end

local function ClassColorOf(unit)
    local _, class = UnitClass(unit)
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local color = class and colors and colors[class]
    if color then return color.r, color.g, color.b end
end

function Plates:HealthColor(p, unit)
    local db = Settings()

    if p.preview then return 0.85, 0.22, 0.2 end

    local isPlayer = UnitIsPlayer(unit)
    local friend = UnitIsFriend("player", unit)

    if isPlayer then
        if (friend and db.classColorFriend) or (not friend and db.classColorEnemy) then
            local r, g, b = ClassColorOf(unit)
            if r then return r, g, b end
        end
        if friend then return 0.25, 0.5, 0.95 end
        return 0.85, 0.22, 0.2
    end

    local r, g, b = ReactionColor(unit)
    local lr, lg, lb = NS.Look:Color("nameplates", "bar")
    if lr and not friend then r, g, b = lr, lg, lb end

    if db.threat ~= "off" and not friend and UnitAffectingCombat(unit) then
        local isTanking, status = UnitDetailedThreatSituation("player", unit)
        if db.threat == "tank" then
            if isTanking and status == 3 then return 0.22, 0.72, 0.36 end
            if status == 2 then return 1, 0.55, 0.1 end
            if status == 1 then return 1, 0.82, 0.2 end
            if status == 0 then return 0.95, 0.2, 0.2 end
        else
            if status == 3 or status == 2 then return 0.95, 0.2, 0.2 end
            if status == 1 then return 1, 0.55, 0.1 end
        end
    end

    if db.execute and not friend then
        local maxHealth = UnitHealthMax(unit)
        if maxHealth > 0 and UnitHealth(unit) / maxHealth * 100 <= db.executeAt then
            local S = NS.Styling
            return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
        end
    end

    return r, g, b
end

local function PaintHealth(p, r, g, b)
    local st = p.style
    local texture = p.health:GetStatusBarTexture()
    p.health:SetStatusBarColor(r, g, b, 1)
    if st.texture == "gradient" then
        texture:SetGradientAlpha("VERTICAL", r * 0.55, g * 0.55, b * 0.55, 1, math.min(1, r * 1.15), math.min(1, g * 1.15), math.min(1, b * 1.15), 1)
    end
    if st.border == "glow" then ColorGlow(p.glow, r, g, b, 0.55) end
    if st.nameColor == "health" then
        p.name:SetTextColor(r, g, b)
    elseif st.nameColor == "grey" then
        p.name:SetTextColor(0.78, 0.78, 0.8)
    else
        local tr, tg, tb = NS.Look:Color("nameplates", "text")
        if tr then p.name:SetTextColor(tr, tg, tb) else p.name:SetTextColor(1, 1, 1) end
    end
end

function Plates:UpdateHealth(p)
    local unit = p.unit
    if not unit then return end
    local db = Settings()

    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    if p.preview then health, maxHealth = 65000, 100000 end
    p.health:SetMinMaxValues(0, math.max(1, maxHealth))
    p.health:SetValue(health)

    local mode = db.hpText
    if mode == "style" then
        local hpAt = p.style.hpAt
        mode = hpAt == "both" and "both" or "percent"
    end
    p.hp:SetText(HealthText(mode, health, maxHealth))
    p.hp:SetTextColor(1, 1, 1)

    PaintHealth(p, self:HealthColor(p, unit))
    p.filterColored = nil

    local st = p.style
    if st.threatGlow and not p.preview then
        local _, status = UnitDetailedThreatSituation("player", unit)
        if status and status > 0 then
            local r, g, b = GetThreatStatusColor(status)
            ColorGlow(p.glow, r, g, b, 0.6)
        else
            HideGlow(p.glow)
        end
    elseif st.threatGlow then
        ColorGlow(p.glow, 1, 0.6, 0, 0.6)
    end

    if not p.batch then self:ApplyFilter(p) end
end

function Plates:UpdateInfo(p)
    local unit = p.unit
    if not unit then return end
    local db = Settings()

    local name = p.preview and L["Страж Ониксии"] or UnitName(unit)
    p.name:SetText(name or "")

    local level = p.preview and 82 or UnitLevel(unit)
    local classification = p.preview and "elite" or UnitClassification(unit)

    if level == -1 or classification == "worldboss" then
        p.level:SetText("")
        p.skull:SetShown(db.showLevel and p.style.level ~= "none")
    else
        p.skull:Hide()
        local suffix = (classification == "elite" or classification == "rareelite") and "+" or (classification == "rare" and "r" or "")
        p.level:SetText((level or "") .. suffix)
        local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level or 0)
        if color then p.level:SetTextColor(color.r, color.g, color.b) else p.level:SetTextColor(1, 0.82, 0) end
    end

    self:UpdateRaidIcon(p)
    self:UpdateHealth(p)
end

function Plates:UpdateRaidIcon(p)
    local db = Settings()
    local index = (not p.preview) and p.unit and GetRaidTargetIndex(p.unit)
    if p.preview then index = 8 end
    if index and db.raidIcon then
        SetRaidTargetIconTexture(p.raid, index)
        p.raid:Show()
    else
        p.raid:Hide()
    end
end

function Plates:UpdateTarget(p)
    local db = Settings()
    local isTarget = p.preview or (p.unit and UnitIsUnit(p.unit, "target"))
    local hasTarget = UnitExists("target")
    local S = NS.Styling

    HideGlow(p.targetGlow)
    p.underline:Hide()

    if isTarget then
        if db.target == "glow" then
            ColorGlow(p.targetGlow, S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.7)
        elseif db.target == "underline" then
            p.underline:Show()
        elseif db.target == "outline" then
            ColorLines(p.outerLines, S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        end
        p.baseScale = p.preview and 1 or db.scale / 100 * db.targetScale / 100
        p.baseAlpha = 1
    else
        if db.target == "outline" then self:ApplyStyle(p) end
        p.baseScale = db.scale / 100
        p.baseAlpha = (hasTarget and not p.preview) and db.otherAlpha / 100 or 1
    end
    p:SetScale(p.baseScale)
    p:SetAlpha(p.baseAlpha)

    if not p.batch then self:ApplyFilter(p) end
end

local function CastUpdate(cast, elapsed)
    cast.throttle = (cast.throttle or 0) + elapsed
    local now = GetTime() * 1000

    if cast.failed then
        if now >= cast.failed then
            cast:Hide()
            cast.failed = nil
        end
        return
    end

    local progress
    if cast.channel then
        progress = cast.endTime - now
    else
        progress = now - cast.startTime
    end

    local total = cast.endTime - cast.startTime
    if total <= 0 or (cast.channel and progress <= 0) or (not cast.channel and progress >= total) then
        cast:Hide()
        return
    end

    cast:SetValue(progress / total)
    if cast.throttle >= 0.1 then
        cast.throttle = 0
        cast.time:SetText(string.format("%.1f", math.max(0, (cast.endTime - now) / 1000)))
    end
end

function Plates:UpdateCast(p, event)
    local db = Settings()
    local cast = p.cast
    if not db.castBar or not p.unit then
        cast:Hide()
        return
    end

    if p.preview then
        cast:SetMinMaxValues(0, 1)
        cast:SetValue(0.45)
        cast:SetStatusBarColor(1, 0.72, 0.1)
        cast.text:SetText(L["Огненный шар"])
        cast.time:SetText("1.4")
        cast.icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
        cast:SetScript("OnUpdate", nil)
        cast:Show()
        return
    end

    if not p.batch then self:ApplyFilter(p) end

    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        if cast:IsShown() then
            cast:SetStatusBarColor(0.85, 0.15, 0.15)
            cast:SetValue(1)
            cast.text:SetText(event == "UNIT_SPELLCAST_INTERRUPTED" and L["Прервано"] or L["Не удалось"])
            cast.time:SetText("")
            cast.failed = GetTime() * 1000 + 500
        end
        return
    end

    local name, _, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(p.unit)
    local channel = false
    if not name then
        name, _, text, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(p.unit)
        channel = name and true or false
    end

    if not name then
        if not cast.failed then cast:Hide() end
        return
    end

    cast.failed = nil
    cast.channel = channel
    cast.startTime, cast.endTime = startTime, endTime
    cast:SetMinMaxValues(0, 1)
    cast.text:SetText(text ~= "" and text or name)
    cast.icon:SetTexture(texture)

    if notInterruptible then
        cast:SetStatusBarColor(0.55, 0.55, 0.6)
        ColorLines(cast.lines, 0.85, 0.85, 0.9, 1)
    else
        if channel then cast:SetStatusBarColor(0.3, 0.7, 1) else cast:SetStatusBarColor(1, 0.72, 0.1) end
        ColorLines(cast.lines, 0, 0, 0, 1)
    end

    cast:SetScript("OnUpdate", CastUpdate)
    cast:Show()
end

local function AuraUpdate(frame, elapsed)
    frame.wait = (frame.wait or 0) + elapsed
    if frame.wait < 0.2 then return end
    frame.wait = 0
    local now = GetTime()
    for _, icon in ipairs(frame.icons) do
        if icon:IsShown() and icon.expires and icon.expires > 0 then
            local left = icon.expires - now
            if left > 0 then
                icon.timer:SetText(left >= 60 and string.format("%dm", math.floor(left / 60 + 0.5)) or string.format("%d", left))
                if left < 5 then icon.timer:SetTextColor(1, 0.3, 0.3) else icon.timer:SetTextColor(1, 1, 1) end
            else
                icon.timer:SetText("")
            end
        end
    end
end

local function AuraIcon(p, index)
    local icon = p.auraIcons[index]
    if icon then return icon end

    local db = Settings()
    icon = CreateFrame("Frame", nil, p.auras)
    icon:SetSize(db.debuffSize, math.floor(db.debuffSize * 0.75 + 0.5))
    icon.ground = icon:CreateTexture(nil, "BACKGROUND")
    icon.ground:SetAllPoints(icon)
    icon.ground:SetTexture(WHITE)
    icon.ground:SetVertexColor(0, 0, 0, 1)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexCoord(0.08, 0.92, 0.2, 0.8)
    icon.timer = icon:CreateFontString(nil, "OVERLAY")
    Font(icon.timer, 8)
    icon.timer:SetPoint("BOTTOM", icon, "TOP", 0, 1)
    icon.count = icon:CreateFontString(nil, "OVERLAY")
    Font(icon.count, 8)
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 0)
    p.auraIcons[index] = icon

    p.auras.icons = p.auraIcons
    if not p.auras:GetScript("OnUpdate") then p.auras:SetScript("OnUpdate", AuraUpdate) end
    return icon
end

function Plates:UpdateAuras(p)
    local db = Settings()
    local shown = 0

    if db.debuffs and p.unit and (p.preview or not UnitIsFriend("player", p.unit)) then
        if p.preview then
            local sample = { "Interface\\Icons\\Spell_Shadow_ShadowWordPain", "Interface\\Icons\\Spell_Shadow_AbominationExplosion", "Interface\\Icons\\Ability_Hunter_SniperShot" }
            for index, texture in ipairs(sample) do
                if index > db.debuffCount then break end
                local icon = AuraIcon(p, index)
                icon.texture:SetTexture(texture)
                icon.expires = GetTime() + 4 + index * 5
                icon.count:SetText(index == 2 and "3" or "")
                icon:Show()
                shown = index
            end
        else
            local index = 1
            while shown < db.debuffCount do
                local name, _, texture, count, _, duration, expires = UnitAura(p.unit, index, "HARMFUL|PLAYER")
                if not name then break end
                shown = shown + 1
                local icon = AuraIcon(p, shown)
                icon.texture:SetTexture(texture)
                icon.expires = (duration and duration > 0) and expires or 0
                icon.timer:SetText("")
                icon.count:SetText((count or 0) > 1 and count or "")
                icon:Show()
                index = index + 1
            end
        end
    end

    for index = shown + 1, #p.auraIcons do p.auraIcons[index]:Hide() end
    if not p.batch then self:ApplyFilter(p) end

    local size = db.debuffSize
    local total = shown * (size + 2) - 2
    for index = 1, shown do
        local icon = p.auraIcons[index]
        icon:ClearAllPoints()
        icon:SetPoint("BOTTOMLEFT", p.auras, "BOTTOM", -total / 2 + (index - 1) * (size + 2), 0)
    end
end

function Plates:UpdateAll(p)
    p.batch = true
    self:UpdateInfo(p)
    self:UpdateTarget(p)
    self:UpdateCast(p)
    self:UpdateAuras(p)
    p.batch = nil
    self:ApplyFilter(p)
end

function Plates:Filters()
    local db = Settings()
    if not db then return {} end
    if type(db.filters) ~= "table" then
        db.filters = {
            { enabled = false, label = L["Каст, который можно прервать"], reaction = "enemy", kind = "any",
              combat = "any", target = "any", casting = "interruptible", healthBelow = 0, healthAbove = 0,
              glow = { 1, 0.8, 0.1 }, scale = 110, alpha = 100 },
            { enabled = false, label = L["Меньше 20% здоровья"], reaction = "enemy", kind = "any",
              combat = "in", target = "any", casting = "any", healthBelow = 20, healthAbove = 0,
              color = { 1, 0.4, 0.1 }, scale = 100, alpha = 100 },
            { enabled = false, label = L["Нет моего дебаффа"], reaction = "enemy", kind = "any",
              combat = "in", target = "any", casting = "any", healthBelow = 0, healthAbove = 0,
              missingDebuffs = "", color = { 0.7, 0.3, 0.95 }, scale = 100, alpha = 100 },
        }
    end
    return db.filters
end

function Plates:NewFilter()
    return { enabled = true, label = L["Новое правило"], reaction = "enemy", kind = "any", combat = "any",
        target = "any", casting = "any", healthBelow = 0, healthAbove = 0, scale = 100, alpha = 100 }
end

local function HasAura(unit, list, filter)
    for name in pairs(list) do
        if UnitAura(unit, name, nil, filter) then return true end
    end
    return false
end

Plates.CONDITIONS = {}

function Plates:AddCondition(def)
    if type(def) ~= "table" or type(def.key) ~= "string" or type(def.test) ~= "function" then return false end
    for _, cond in ipairs(self.CONDITIONS) do
        if cond.key == def.key then return false end
    end
    table.insert(self.CONDITIONS, { key = def.key, label = def.label or def.key, options = def.options, test = def.test })
    return true
end

function Plates:RuleMatches(rule, unit)
    local F = NS.AuraFilters
    if not F then return false end

    local friend = UnitIsFriend("player", unit)
    if rule.reaction == "enemy" and friend then return false end
    if rule.reaction == "friend" and not friend then return false end

    if rule.combat == "in" and not UnitAffectingCombat(unit) then return false end
    if rule.combat == "out" and UnitAffectingCombat(unit) then return false end

    local isTarget = UnitIsUnit(unit, "target")
    if rule.target == "yes" and not isTarget then return false end
    if rule.target == "no" and isTarget then return false end

    local kind = rule.kind or "any"
    if kind ~= "any" then
        local classification = UnitClassification(unit)
        local boss = classification == "worldboss" or UnitLevel(unit) == -1
        local player = UnitIsPlayer(unit)
        if kind == "player" and not player then return false end
        if kind == "boss" and not boss then return false end
        if kind == "elite" and not (boss or classification == "elite" or classification == "rareelite") then return false end
        if kind == "rare" and classification ~= "rare" and classification ~= "rareelite" then return false end
        if kind == "normal" and (boss or player or classification ~= "normal") then return false end
    end

    local names = F.ParseList(rule.units)
    if next(names) and not names[UnitName(unit) or ""] then return false end

    local below, above = rule.healthBelow or 0, rule.healthAbove or 0
    if below > 0 or above > 0 then
        local maxHealth = UnitHealthMax(unit)
        local percent = maxHealth > 0 and UnitHealth(unit) / maxHealth * 100 or 100
        if below > 0 and percent > below then return false end
        if above > 0 and percent < above then return false end
    end

    local casting = rule.casting or "any"
    if casting ~= "any" then
        local name, _, _, _, _, _, _, _, shielded = UnitCastingInfo(unit)
        if not name then
            name, _, _, _, _, _, _, shielded = UnitChannelInfo(unit)
        end
        if not name then return false end
        if casting == "interruptible" and shielded then return false end
        if casting == "list" and not F.ParseList(rule.castList)[name] then return false end
    end

    local mine = F.ParseList(rule.myDebuffs)
    if next(mine) and not HasAura(unit, mine, "HARMFUL|PLAYER") then return false end
    local missing = F.ParseList(rule.missingDebuffs)
    if next(missing) and HasAura(unit, missing, "HARMFUL|PLAYER") then return false end
    local buffs = F.ParseList(rule.buffs)
    if next(buffs) and not HasAura(unit, buffs, "HELPFUL") then return false end

    for _, cond in ipairs(self.CONDITIONS) do
        local value = rule["x_" .. cond.key]
        if value ~= nil and value ~= "any" then
            local ok, pass = pcall(cond.test, unit, value)
            if not ok or not pass then return false end
        end
    end

    return true
end

function Plates:MatchFilter(p)
    local db = Settings()
    if not db or not db.filtersOn or p.preview or not p.unit then return nil end
    for _, rule in ipairs(self:Filters()) do
        if rule.enabled and self:RuleMatches(rule, p.unit) then return rule end
    end
end

function Plates:ApplyFilter(p)
    if p.preview or not p.unit then return end
    local rule = self:MatchFilter(p)
    p.filter = rule

    if rule and rule.color then
        PaintHealth(p, rule.color[1], rule.color[2], rule.color[3])
        p.filterColored = true
    elseif p.filterColored then
        p.filterColored = nil
        PaintHealth(p, self:HealthColor(p, p.unit))
    end

    if rule and rule.glow then
        if not p.filterGlow then p.filterGlow = Glow(p.outer) end
        ColorGlow(p.filterGlow, rule.glow[1], rule.glow[2], rule.glow[3], 0.85)
    elseif p.filterGlow then
        HideGlow(p.filterGlow)
    end

    local scale = p.baseScale or 1
    local alpha = p.baseAlpha or 1
    if rule then
        scale = scale * (rule.scale or 100) / 100
        if (rule.alpha or 100) ~= 100 then alpha = (rule.alpha or 100) / 100 end
    end
    p:SetScale(math.max(scale, 0.1))
    p:SetAlpha(alpha)
end

function Plates:RefreshFilters()
    for _, p in pairs(active) do self:ApplyFilter(p) end
end

local function HideBlizzard(base)
    local frame = base and base.UnitFrame
    if not frame then return end
    if not frame.narciHooked then
        frame.narciHooked = true
        frame:HookScript("OnShow", function(self)
            local parent = self:GetParent()
            if parent and parent.narci and parent.narci:IsShown() then self:Hide() end
        end)
    end
    frame:Hide()
end

function Plates:OnAdded(unit)
    if UnitIsUnit(unit, "player") then return end

    local base = C_NamePlate.GetNamePlateForUnit(unit)
    if not base then return end

    local p = base.narci
    if not p then
        p = CreatePlate(base)
        p:SetPoint("CENTER", base, "CENTER", 0, 0)
        base.narci = p
        plates[#plates + 1] = p
    end

    p.unit = unit
    active[unit] = p
    self:ApplyStyle(p)
    p:Show()
    HideBlizzard(base)
    self:UpdateAll(p)
end

function Plates:OnRemoved(unit)
    local p = active[unit]
    active[unit] = nil
    if p then
        if p == lastMouse then lastMouse = nil end
        p.highlight:Hide()
        p.unit = nil
        p.cast:Hide()
        p.cast:SetScript("OnUpdate", nil)
        p:Hide()
    end
end

function Plates:ForEach(fn)
    for _, p in pairs(active) do fn(self, p) end
end

function Plates:Refresh()
    for _, p in pairs(active) do
        self:ApplyStyle(p)
        self:UpdateAll(p)
    end
    if self.preview then
        self:ApplyStyle(self.preview)
        self:UpdateAll(self.preview)
    end
end

function Plates:CreatePreview(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(260, 84)

    local ground = holder:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(holder)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL", 0.10, 0.12, 0.10, 0.9, 0.16, 0.20, 0.24, 0.9)

    local p = CreatePlate(holder)
    p:SetPoint("CENTER", holder, "CENTER", 10, -4)
    p.preview = true
    p.unit = "player"
    self.preview = p
    self:ApplyStyle(p)
    self:UpdateAll(p)
    p:SetScale(1)

    return holder
end

function Plates:CreateSample(parent)
    local keep = self.preview
    local holder = self:CreatePreview(parent)
    holder.plate = self.preview
    self.preview = keep
    holder:SetScale(1.15)
    return holder
end

function Plates:PaintSample(holder)
    if not holder or not holder.plate then return end
    self:ApplyStyle(holder.plate)
    self:UpdateAll(holder.plate)
end

function Plates:Apply()
    if not Enabled() or self:Blocked() then return end
    self.running = true
    for _, base in ipairs(C_NamePlate.GetNamePlates() or {}) do
        if base.namePlateUnitToken then self:OnAdded(base.namePlateUnitToken) end
    end
end

local driver = CreateFrame("Frame")
local mouseWait = 0

driver:SetScript("OnUpdate", function(_, elapsed)
    if not Plates.running then return end
    mouseWait = mouseWait + elapsed
    if mouseWait < 0.1 then return end
    mouseWait = 0

    local current
    if UnitExists("mouseover") then
        for unit, p in pairs(active) do
            if UnitIsUnit(unit, "mouseover") then current = p break end
        end
    end
    if current ~= lastMouse then
        if lastMouse then lastMouse.highlight:Hide() end
        if current then current.highlight:Show() end
        lastMouse = current
    end
end)

local events = CreateFrame("Frame")
local UNIT_EVENTS = {
    UNIT_HEALTH = "health", UNIT_MAXHEALTH = "health",
    UNIT_THREAT_SITUATION_UPDATE = "health", UNIT_THREAT_LIST_UPDATE = "health",
    UNIT_NAME_UPDATE = "info", UNIT_LEVEL = "info", UNIT_FACTION = "info", UNIT_CLASSIFICATION_CHANGED = "info",
    UNIT_AURA = "auras",
    UNIT_SPELLCAST_START = "cast", UNIT_SPELLCAST_STOP = "cast", UNIT_SPELLCAST_FAILED = "cast",
    UNIT_SPELLCAST_INTERRUPTED = "cast", UNIT_SPELLCAST_DELAYED = "cast",
    UNIT_SPELLCAST_CHANNEL_START = "cast", UNIT_SPELLCAST_CHANNEL_UPDATE = "cast", UNIT_SPELLCAST_CHANNEL_STOP = "cast",
    UNIT_SPELLCAST_INTERRUPTIBLE = "cast", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "cast",
}

events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("RAID_TARGET_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
for event in pairs(UNIT_EVENTS) do events:RegisterEvent(event) end

events:SetScript("OnEvent", function(_, event, unit, ...)
    if event == "PLAYER_LOGIN" then
        if NS.After then
            NS.After(1, function()
                local blocked = Enabled() and Plates:Blocked()
                if blocked == "tidy" then
                    NS.Print(L["Неймплейты аддона ждут: сейчас плашки рисует другой аддон. Переключиться можно в настройках, страница Неймплейты."])
                end
                Plates:Apply()
            end)
        end
        return
    end

    if not Plates.running then return end

    if event == "NAME_PLATE_UNIT_ADDED" then
        Plates:OnAdded(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Plates:OnRemoved(unit)
    elseif event == "PLAYER_TARGET_CHANGED" then
        for _, p in pairs(active) do
            Plates:UpdateTarget(p)
            Plates:UpdateCast(p)
        end
    elseif event == "RAID_TARGET_UPDATE" then
        for _, p in pairs(active) do Plates:UpdateRaidIcon(p) end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        for _, p in pairs(active) do Plates:UpdateHealth(p) end
    else
        local kind = UNIT_EVENTS[event]
        local p = unit and active[unit]
        if not p then
            if kind == "health" and unit == "player" then
                for _, other in pairs(active) do Plates:UpdateHealth(other) end
            end
            return
        end
        if kind == "health" then
            Plates:UpdateHealth(p)
        elseif kind == "info" then
            Plates:UpdateInfo(p)
        elseif kind == "auras" then
            Plates:UpdateAuras(p)
        elseif kind == "cast" then
            Plates:UpdateCast(p, event)
        end
    end
end)
