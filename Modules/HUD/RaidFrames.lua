local addonName, NS = ...
local L = NS.L

local RaidFrames = {}
NS.RaidFrames = RaidFrames

local WHITE = "Interface\\Buttons\\WHITE8x8"
local MAX_DEBUFFS = 3
local RANGE_INTERVAL = 0.3

local POWER_EVENTS = {
    "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER",
    "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXENERGY", "UNIT_MAXFOCUS", "UNIT_MAXRUNIC_POWER",
    "UNIT_DISPLAYPOWER",
}

local POWER_COLORS = {
    MANA = { 0.25, 0.50, 0.90 },
    RAGE = { 0.78, 0.25, 0.25 },
    FOCUS = { 0.75, 0.55, 0.25 },
    ENERGY = { 0.90, 0.82, 0.35 },
    RUNIC_POWER = { 0.35, 0.65, 0.80 },
}

local DEBUFF_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
}

local READY_TEXTURES = {
    ready = "Interface\\RaidFrame\\ReadyCheck-Ready",
    notready = "Interface\\RaidFrame\\ReadyCheck-NotReady",
    waiting = "Interface\\RaidFrame\\ReadyCheck-Waiting",
}

local BLIZZARD_FRAMES = {
    "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
    "PartyMemberBackground", "CompactPartyFrame",
    "CompactRaidFrameManager", "CompactRaidFrameContainer",
}

local byUnit = {}
local buttons = {}

local STYLE_SIZES = {
    blocks = { width = 92, height = 40, powerSize = 4 },
    cards = { width = 116, height = 44, powerSize = 2 },
    glow = { width = 84, height = 46, powerSize = 3 },
    minimal = { width = 100, height = 32, powerSize = 3 },
    outline = { width = 88, height = 40, powerSize = 3 },
    portrait = { width = 124, height = 38, powerSize = 3 },
    segments = { width = 96, height = 38, powerSize = 3 },
    glass = { width = 92, height = 42, powerSize = 3 },
}
RaidFrames.EXTRA_STYLES = {}
RaidFrames.EXTRA_LIST = {}

local function BaseStyle(style)
    local extra = RaidFrames.EXTRA_STYLES[style]
    return extra and extra.base or style
end

local TICKS = 9

local GLOW_SIZE = 6

local function FillSettings()
    if not NS.db then return end

    if not NS.db.raidFrames then NS.db.raidFrames = {} end

    local db = NS.db.raidFrames
    if db.enabled == nil then db.enabled = true end
    if db.party == nil then db.party = true end
    if db.solo == nil then db.solo = false end
    if db.hideBlizzard == nil then db.hideBlizzard = true end
    if db.showPower == nil then db.showPower = true end
    if db.showRole == nil then db.showRole = true end
    if not db.roleStyleBoth then
        db.roleStyleBoth = true
        if db.roleStyle == nil or db.roleStyle == "text" then db.roleStyle = "both" end
    end
    if db.roleStyle ~= "icon" and db.roleStyle ~= "text" and db.roleStyle ~= "both" then db.roleStyle = "both" end
    if db.showLeader == nil then db.showLeader = true end
    if db.showLooter == nil then db.showLooter = true end
    if db.showDebuffs == nil then db.showDebuffs = true end
    if db.hideServerDebuffs == nil then db.hideServerDebuffs = true end
    if db.rangeFade == nil then db.rangeFade = true end
    if db.healPrediction == nil then db.healPrediction = true end
    db.width = db.width or 92
    db.height = db.height or 40
    db.spacing = db.spacing or 3
    db.growth = db.growth or "RIGHT"
    db.colorMode = db.colorMode or "class"
    db.healthText = db.healthText or "deficit"
    db.style = db.style or "blocks"
    if not STYLE_SIZES[db.style] then db.style = "blocks" end
    if db.vertical == nil then db.vertical = false end
    db.barSize = db.barSize or 6
    db.nameSize = db.nameSize or 11
    db.textSize = db.textSize or 10
    db.nameColor = db.nameColor or "auto"
    db.groundAlpha = db.groundAlpha or 92
    if db.sheen == nil then db.sheen = true end
    db.debuffSize = db.debuffSize or 14
    db.powerSize = db.powerSize or 4

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.raidFrames
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local LAYOUT_KINDS = { "party", "raid10", "raid25", "raid40" }
local LAYOUT_FIELDS = { "width", "height", "spacing", "growth", "showPower", "powerSize", "nameSize", "textSize" }
RaidFrames.LAYOUT_KINDS = LAYOUT_KINDS
RaidFrames.LAYOUT_FIELDS = LAYOUT_FIELDS

local function SizeKind()
    local count = GetNumRaidMembers and GetNumRaidMembers() or 0
    if count > 25 then return "raid40" end
    if count > 10 then return "raid25" end
    if count > 0 then return "raid10" end
    return "party"
end

RaidFrames.SizeKind = SizeKind

local view, viewBase

local function Current()
    local db = Settings()
    if not db then return nil end
    local own = type(db.layouts) == "table" and db.layouts[RaidFrames.sizeKind or "party"]
    if type(own) ~= "table" or not own.enabled then return db end
    if not view or viewBase ~= db then
        view = setmetatable({}, { __index = db })
        viewBase = db
    end
    for _, field in ipairs(LAYOUT_FIELDS) do
        rawset(view, field, own[field])
    end
    return view
end

local function ButtonSize(button, db)
    if button.narciTank then
        local base = Settings()
        return base.tankWidth or 120, base.tankHeight or 32
    end
    return db.width, db.height
end

local function Style()
    return NS.Styling
end

local function Short(value)
    if value >= 1000000 then return string.format("%.1fm", value / 1000000) end
    if value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end

local function Paint(edges, r, g, b, a)
    for _, line in ipairs(edges) do line:SetVertexColor(r, g, b, a or 1) end
end

local function CreateGlow(button)
    return NS.Styling.GlowPieces(button, GLOW_SIZE, "BACKGROUND", "ADD")
end

local function PaintGlow(glow, r, g, b, a)
    for _, texture in ipairs(glow) do
        texture:SetVertexColor(r, g, b, a)
    end
end

local function ClassColor(unit)
    local _, class = UnitClass(unit)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.55, 0.57, 0.62
end

local function Holder()
    if RaidFrames.holder then return RaidFrames.holder end

    local db = Current()
    local holder = CreateFrame("Frame", "NarciSirus_RaidHolder", UIParent)
    holder:SetSize(db.width * 5 + db.spacing * 4, db.height * 5 + db.spacing * 4)
    holder:SetFrameStrata("LOW")

    if db.point then
        holder:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -260)
    end

    RaidFrames.holder = holder

    if NS.Movers then
        NS.Movers:Register(holder, L["Рейд-фреймы"], function(point, relativePoint, x, y)
            local store = Settings()
            if not store then return end
            store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
        end, "raid")
    end

    return holder
end

function RaidFrames:BuildButton(button, sample)
    local db = Current()
    local S = Style()

    local width, height = ButtonSize(button, db)
    button:SetWidth(width)
    button:SetHeight(height)
    if not sample then
        button:RegisterForClicks("AnyUp")
        button:SetAttribute("*type1", "target")
        button:SetAttribute("*type2", "togglemenu")

        _G.ClickCastFrames = _G.ClickCastFrames or {}
        _G.ClickCastFrames[button] = true
    end

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.02, 0.022, 0.03, 0.92)

    local shade = button:CreateTexture(nil, "BORDER")
    shade:SetAllPoints(button)
    shade:SetTexture(WHITE)
    shade:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.06)

    local stripe = button:CreateTexture(nil, "BORDER")
    stripe:SetTexture(WHITE)
    stripe:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    stripe:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
    stripe:SetWidth(3)

    local glow = CreateGlow(button)

    local portrait = button:CreateTexture(nil, "ARTWORK")
    portrait:SetTexCoord(0.15, 0.85, 0.15, 0.85)

    local health = CreateFrame("StatusBar", nil, button)
    NS.Look:SetBar(health, "raid", WHITE)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    health:SetFrameLevel(button:GetFrameLevel() + 1)

    local barFrame = CreateFrame("Frame", nil, button)
    barFrame:SetPoint("TOPLEFT", health, "TOPLEFT", -1, 1)
    barFrame:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 1, -1)
    barFrame:SetFrameLevel(button:GetFrameLevel() + 2)
    local barEdges = S.CreateEdges(barFrame, "OVERLAY", 0, 0, 0, 1)

    local deficit = health:CreateTexture(nil, "BACKGROUND")
    deficit:SetAllPoints(health)
    deficit:SetTexture(WHITE)

    local predict = NS.HealPrediction and NS.HealPrediction:Attach(health)

    local ticks = {}
    for index = 1, TICKS do
        local tick = health:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(WHITE)
        tick:SetVertexColor(0, 0, 0, 0.6)
        tick:Hide()
        ticks[index] = tick
    end

    local sheen = health:CreateTexture(nil, "OVERLAY")
    sheen:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
    sheen:SetPoint("BOTTOMRIGHT", health, "RIGHT", 0, 0)
    sheen:SetTexture(WHITE)
    sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.08)

    local power = CreateFrame("StatusBar", nil, button)
    NS.Look:SetBar(power, "raid", WHITE)
    power:SetMinMaxValues(0, 1)
    power:SetValue(1)
    power:SetFrameLevel(button:GetFrameLevel() + 1)

    local powerGround = power:CreateTexture(nil, "BACKGROUND")
    powerGround:SetAllPoints(power)
    powerGround:SetTexture(WHITE)
    powerGround:SetVertexColor(0.03, 0.035, 0.05, 1)

    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 3)

    local name = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(name, "raid", NS.FS(11), "OUTLINE")
    name:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -5)
    name:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -5)
    name:SetJustifyH("CENTER")

    local status = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(status, "raid", NS.FS(10), "OUTLINE")
    status:SetPoint("TOP", name, "BOTTOM", 0, -2)
    status:SetTextColor(0.85, 0.86, 0.9)

    local role = overlay:CreateTexture(nil, "OVERLAY")
    role:SetSize(12, 12)
    role:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    role:Hide()

    local roleText = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(roleText, "raid", NS.FS(9), "OUTLINE")
    roleText:SetJustifyH("LEFT")
    roleText:Hide()

    local badges = CreateFrame("Frame", nil, button)
    badges:SetAllPoints(button)
    badges:SetFrameLevel(button:GetFrameLevel() + 6)

    local rank = badges:CreateTexture(nil, "OVERLAY")
    rank:SetSize(12, 12)
    rank:SetPoint("CENTER", button, "TOPLEFT", 9, 1)
    rank:Hide()

    local looter = badges:CreateTexture(nil, "OVERLAY")
    looter:SetSize(11, 11)
    looter:SetTexture("Interface\\GroupFrame\\UI-Group-MasterLooter")
    looter:Hide()

    local mark = overlay:CreateTexture(nil, "OVERLAY")
    mark:SetSize(14, 14)
    mark:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    mark:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    mark:Hide()

    local ready = overlay:CreateTexture(nil, "OVERLAY")
    ready:SetSize(18, 18)
    ready:SetPoint("CENTER", button, "CENTER", 0, 0)
    ready:Hide()

    local debuffs = {}
    for index = 1, MAX_DEBUFFS do
        local icon = CreateFrame("Frame", nil, overlay)
        icon:SetSize(14, 14)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2 - (index - 1) * 15, db.showPower and 6 or 2)
        icon:SetFrameLevel(overlay:GetFrameLevel() + 1)

        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
        texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local back = icon:CreateTexture(nil, "BACKGROUND")
        back:SetAllPoints(icon)
        back:SetTexture(WHITE)
        back:SetVertexColor(0, 0, 0, 1)

        local count = icon:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(count, "raid", NS.FS(8), "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 0)

        icon.texture, icon.back, icon.count = texture, back, count
        icon:Hide()
        debuffs[index] = icon
    end

    local edges = S.CreateEdges(overlay, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local glassLine = overlay:CreateTexture(nil, "OVERLAY")
    glassLine:SetTexture(WHITE)
    glassLine:SetHeight(1)
    glassLine:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    glassLine:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    glassLine:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.05, 1, 1, 1, 0.45)

    local hover = overlay:CreateTexture(nil, "ARTWORK")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(1, 1, 1, 0.08)
    hover:Hide()

    button.ground, button.sheen = ground, sheen
    button.shade, button.stripe, button.glow, button.barEdges = shade, stripe, glow, barEdges
    button.portrait, button.ticks, button.glassLine = portrait, ticks, glassLine
    button.health, button.deficit, button.predict = health, deficit, predict
    button.power = power
    button.nameText, button.status = name, status
    button.role, button.mark, button.ready = role, mark, ready
    button.roleText, button.rank, button.looter = roleText, rank, looter
    button.debuffs, button.edges, button.hover = debuffs, edges, hover

    button:HookScript("OnEnter", function(self)
        self.hover:Show()
        local unit = self:GetAttribute("unit")
        if unit and UnitExists(unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(unit)
            GameTooltip:Show()
        end
    end)
    button:HookScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
    end)

    button:HookScript("OnAttributeChanged", function(self, key, value)
        if key == "unit" then RaidFrames:Assign(self, value) end
    end)
    button:HookScript("OnShow", function(self) RaidFrames:Assign(self, self:GetAttribute("unit")) end)

    if not sample then buttons[#buttons + 1] = button end

    self:Layout(button)
end

local SAMPLE_PEOPLE = {
    { share = 1, rank = 2, looter = true },
    { name = "Торвальд", class = "PALADIN", share = 0.55, role = "TANK", rank = 1 },
    { name = "Шейд", class = "ROGUE", share = 0.22, role = "DAMAGER", debuff = { "Порча", "Interface\\Icons\\Spell_Shadow_AbominationExplosion", "Magic" } },
    { name = "Мирра", class = "DRUID", share = 0.8, role = "HEALER", debuff = { "Яд", "Interface\\Icons\\Ability_Creature_Poison_06", "Poison" } },
}

function RaidFrames:CreateSample(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder.buttons = {}
    for index = 1, #SAMPLE_PEOPLE do
        local button = CreateFrame("Button", nil, holder)
        button.narciSample = true
        self:BuildButton(button, true)
        button.unit = "player"
        button.narciPerson = SAMPLE_PEOPLE[index]
        local debuff = SAMPLE_PEOPLE[index].debuff
        if debuff then
            button.narciFakeDebuff = function(_, auraIndex)
                if auraIndex == 1 then return debuff[1], nil, debuff[2], 1, debuff[3], 20, GetTime() + 12, "boss1" end
            end
        else
            button.narciFakeDebuff = function() end
        end
        holder.buttons[index] = button
    end
    return holder
end

function RaidFrames:PaintSample(holder, opts)
    local base = Settings()
    if not base or not holder then return end
    if opts and opts.styleSizes and STYLE_SIZES[base.style] then
        local preset = STYLE_SIZES[base.style]
        local keep = { base.width, base.height, base.powerSize }
        base.width, base.height, base.powerSize = preset.width, preset.height, preset.powerSize
        local ok = pcall(self.PaintSample, self, holder)
        base.width, base.height, base.powerSize = keep[1], keep[2], keep[3]
        return
    end
    local db = Current()
    local gap = db.spacing or 4
    local width, height = 0, 0
    for index, button in ipairs(holder.buttons) do
        local w, h = ButtonSize(button, db)
        button:SetSize(w, h)
        self:Layout(button)
        self:Update(button)
        local person = SAMPLE_PEOPLE[index]
        local _, maxHealth = button.health:GetMinMaxValues()
        button.health:SetValue((maxHealth or 1) * person.share)
        if person.share < 1 and db.healthText ~= "none" then
            if db.healthText == "percent" then
                button.status:SetText(math.floor(person.share * 100 + 0.5) .. "%")
            else
                button.status:SetText("-" .. Short((maxHealth or 1) * (1 - person.share)))
            end
        end
        if person.name then
            button.nameText:SetText(person.name)
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[person.class]
            local mode = db.nameColor
            if mode == "auto" then mode = db.colorMode == "class" and "white" or "class" end
            if c and mode == "class" and not NS.Look:Color("raid", "text") then button.nameText:SetTextColor(c.r, c.g, c.b) end
            if c and db.colorMode ~= "dark" and db.colorMode ~= "accent" then
                local style = BaseStyle(db.style)
                if style == "glow" then
                    button.health:GetStatusBarTexture():SetGradientAlpha(button.healVertical and "VERTICAL" or "HORIZONTAL",
                        c.r * 0.3, c.g * 0.3, c.b * 0.3, 0.95, c.r, c.g, c.b, 0.95)
                elseif style == "glass" then
                    button.health:SetStatusBarColor(c.r, c.g, c.b, 0.55)
                elseif style == "outline" then
                    button.health:SetStatusBarColor(c.r * 0.55, c.g * 0.55, c.b * 0.55, 0.75)
                else
                    button.health:SetStatusBarColor(c.r * 0.85, c.g * 0.85, c.b * 0.85, 1)
                end
                if button.stripe then button.stripe:SetVertexColor(c.r, c.g, c.b, 1) end
            end
        end
        button:ClearAllPoints()
        local count = #holder.buttons
        if db.growth == "DOWN" then
            button:SetPoint("TOPLEFT", holder, "TOPLEFT", (index - 1) * (w + gap), 0)
            width, height = count * w + (count - 1) * gap, h
        else
            button:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(index - 1) * (h + gap))
            width, height = w, count * h + (count - 1) * gap
        end
        button:Show()
    end
    holder:SetSize(width, height)
    holder:SetScale(math.min(1.6, 290 / math.max(width, 1), 200 / math.max(height, 1)))
end

local function SetShownAll(list, shown)
    for _, item in ipairs(list) do item:SetShown(shown) end
end

local function EdgeWidth(edges, width)
    edges[1]:SetHeight(width)
    edges[2]:SetHeight(width)
    edges[3]:SetWidth(width)
    edges[4]:SetWidth(width)
end

function RaidFrames:Layout(button)
    local db = Current()
    local width, height = ButtonSize(button, db)
    local style = BaseStyle(db.style)
    local powerHeight = db.showPower and db.powerSize or 0
    local centered = style ~= "cards" and style ~= "minimal" and style ~= "portrait"
    local vertical = db.vertical and centered or false
    local lift = powerHeight / 2
    local roleSpace = 0
    local size = db.debuffSize
    local alpha = db.groundAlpha / 100
    local barred = style == "cards" or style == "minimal"
    local powerGap = powerHeight > 0 and 1 or 0

    if style == "glass" then
        button.ground:SetVertexColor(0.06, 0.08, 0.12, alpha * 0.55)
    else
        button.ground:SetVertexColor(0.02, 0.022, 0.03, style == "minimal" and alpha * 0.4 or alpha)
    end
    local gr, gg, gb = NS.Look:Color("raid", "bg")
    if gr then
        local _, _, _, ga = button.ground:GetVertexColor()
        button.ground:SetVertexColor(gr, gg, gb, ga)
    end
    button.shade:SetShown(style == "cards" or style == "glass")
    button.stripe:SetShown(style == "cards")
    button.glassLine:SetShown(style == "glass")
    SetShownAll(button.glow, style == "glow")
    SetShownAll(button.edges, style ~= "glow" and style ~= "minimal")
    SetShownAll(button.barEdges, barred)
    EdgeWidth(button.edges, style == "outline" and 2 or 1)

    local inset = style == "outline" and 2 or 1
    local face = 0
    button.portrait:ClearAllPoints()
    if style == "portrait" then
        face = height - 2
        button.portrait:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        button.portrait:SetSize(face, face)
        button.portrait:Show()
        face = face + 1
    else
        button.portrait:Hide()
    end
    button.sheen:SetShown(db.sheen and true or false)

    button.health:ClearAllPoints()
    button.power:ClearAllPoints()

    if style == "cards" then
        local bottom = 4 + powerHeight + powerGap
        button.power:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 8, 4)
        button.power:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 4)
        button.health:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 8, bottom)
        button.health:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, bottom)
        button.health:SetHeight(db.barSize)
    elseif style == "minimal" then
        button.power:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
        button.power:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.health:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -(db.nameSize + 5))
        button.health:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1 + powerHeight + powerGap)
    else
        button.power:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", inset + face, inset)
        button.power:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
        button.health:SetPoint("TOPLEFT", button, "TOPLEFT", inset + face, -inset)
        button.health:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset + powerHeight)
    end

    button.health:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")

    local length = vertical and (height - inset * 2 - powerHeight) or (width - inset * 2 - face)
    for index, tick in ipairs(button.ticks) do
        local at = math.floor(length * index / (TICKS + 1) + 0.5)
        tick:ClearAllPoints()
        if vertical then
            tick:SetHeight(1)
            tick:SetPoint("BOTTOMLEFT", button.health, "BOTTOMLEFT", 0, at)
            tick:SetPoint("BOTTOMRIGHT", button.health, "BOTTOMRIGHT", 0, at)
        else
            tick:SetWidth(1)
            tick:SetPoint("TOPLEFT", button.health, "TOPLEFT", at, 0)
            tick:SetPoint("BOTTOMLEFT", button.health, "BOTTOMLEFT", at, 0)
        end
        tick:SetShown(style == "segments")
    end

    button.healVertical = vertical

    button.power:SetHeight(math.max(barred and powerHeight or powerHeight - 1, 1))
    button.power:SetShown(db.showPower and true or false)

    NS.LSetFont(button.nameText, "raid", db.nameSize, "OUTLINE")
    NS.LSetFont(button.status, "raid", db.textSize, "OUTLINE")

    button.nameText:ClearAllPoints()
    button.status:ClearAllPoints()
    button.role:ClearAllPoints()

    if not centered then
        local left = style == "cards" and 8 or style == "portrait" and face + 4 or 1
        local top = style == "minimal" and -2 or -5
        if style == "cards" then
            button.role:SetPoint("BOTTOMLEFT", button.health, "TOPLEFT", 0, 2)
        else
            button.role:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", left + 1, powerHeight + 3)
        end
        button.status:SetPoint("TOPRIGHT", button, "TOPRIGHT", style == "minimal" and -1 or -5, top)
        button.status:SetJustifyH("RIGHT")
        button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", left + roleSpace, top)

        button.nameText:SetPoint("RIGHT", button.status, "LEFT", -4, 0)
        button.nameText:SetJustifyH("LEFT")

        for index, icon in ipairs(button.debuffs) do
            icon:SetSize(size, size)
            icon:ClearAllPoints()
            if style == "cards" then
                icon:SetPoint("BOTTOMRIGHT", button.health, "TOPRIGHT", -(index - 1) * (size + 1), 3)
            elseif style == "portrait" then
                icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3 - (index - 1) * (size + 1), powerHeight + 3)
            else
                icon:SetPoint("RIGHT", button.health, "RIGHT", -2 - (index - 1) * (size + 1), 0)
            end
        end
    else
        button.role:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", inset + 2, powerHeight + inset + 2)
        button.status:SetJustifyH("CENTER")
        button.nameText:SetJustifyH("CENTER")

        if vertical or style == "glow" then
            button.nameText:SetPoint("LEFT", button, "LEFT", 2, 3 + lift)
            button.nameText:SetPoint("RIGHT", button, "RIGHT", -2, 3 + lift)
            button.status:SetPoint("TOP", button.nameText, "BOTTOM", 0, -1)
        else
            button.nameText:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -5)
            button.nameText:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -5)
            button.status:SetPoint("TOP", button.nameText, "BOTTOM", 0, -2)
        end

        for index, icon in ipairs(button.debuffs) do
            icon:SetSize(size, size)
            icon:ClearAllPoints()
            icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1 - inset - (index - 1) * (size + 1), powerHeight + inset + 1)
        end
    end
end

function RaidFrames:AddStyle(key, label, row)
    if type(key) ~= "string" or key == "" or STYLE_SIZES[key] or type(row) ~= "table" then return false end
    local base = (STYLE_SIZES[row.base or ""] and not self.EXTRA_STYLES[row.base]) and row.base or "blocks"
    local sizes = type(row.sizes) == "table" and row.sizes or STYLE_SIZES[base]
    STYLE_SIZES[key] = { width = sizes.width or 92, height = sizes.height or 40, powerSize = sizes.powerSize or 3 }
    self.EXTRA_STYLES[key] = { base = base, paint = row.paint }
    table.insert(self.EXTRA_LIST, { key = key, label = label or key })
    if not self.extraHooked then
        self.extraHooked = true
        local function Paint(_, button)
            local db = Settings()
            local extra = db and button and RaidFrames.EXTRA_STYLES[db.style]
            if extra and type(extra.paint) == "function" then pcall(extra.paint, button, db) end
        end
        hooksecurefunc(self, "Layout", Paint)
        hooksecurefunc(self, "UpdateBorder", Paint)
    end
    return true
end

function RaidFrames:SetStyle(style)
    local db = Settings()
    if not db or not STYLE_SIZES[style] then return end

    local preset = STYLE_SIZES[style]
    db.style = style
    db.width, db.height, db.powerSize = preset.width, preset.height, preset.powerSize

    self:ApplyLayout()
    self:UpdateAll()
end

function RaidFrames:Assign(button, unit)
    if button.unit and byUnit[button.unit] then byUnit[button.unit][button] = nil end
    button.unit = unit
    if unit then
        byUnit[unit] = byUnit[unit] or {}
        byUnit[unit][button] = true
        self:Update(button)
    end
end

function RaidFrames:UpdateHealth(button)
    local unit = button.unit
    local db = Settings()
    local S = Style()

    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    if maxHealth <= 0 then maxHealth = 1 end

    button.health:SetMinMaxValues(0, maxHealth)
    button.health:SetValue(health)

    local r, g, b
    if db.colorMode == "dark" then
        r, g, b = 0.24, 0.26, 0.32
    elseif db.colorMode == "accent" then
        r, g, b = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
    else
        r, g, b = ClassColor(unit)
    end
    local lr, lg, lb = NS.Look:Color("raid", "bar")
    if lr then r, g, b = lr, lg, lb end

    local style = BaseStyle(db.style)
    if style == "glow" then
        button.health:GetStatusBarTexture():SetGradientAlpha(button.healVertical and "VERTICAL" or "HORIZONTAL",
            r * 0.30, g * 0.30, b * 0.30, 0.95, r, g, b, 0.95)
        button.deficit:SetVertexColor(0.17, 0.03, 0.045, 0.85)
    elseif style == "cards" or style == "minimal" or style == "segments" then
        button.health:SetStatusBarColor(r * 0.92, g * 0.92, b * 0.92, 1)
        button.deficit:SetVertexColor(r * 0.10 + 0.02, g * 0.10 + 0.02, b * 0.10 + 0.03, 1)
    elseif style == "outline" then
        button.health:SetStatusBarColor(r * 0.55, g * 0.55, b * 0.55, 0.75)
        button.deficit:SetVertexColor(0, 0, 0, 0)
    elseif style == "glass" then
        button.health:SetStatusBarColor(r, g, b, 0.55)
        button.deficit:SetVertexColor(0.05, 0.06, 0.09, 0.35)
    else
        button.health:SetStatusBarColor(r * 0.8, g * 0.8, b * 0.8, 1)
        button.deficit:SetVertexColor(r * 0.16 + 0.03, g * 0.16 + 0.03, b * 0.16 + 0.04, 0.95)
    end

    if style == "cards" then
        local cr, cg, cb = ClassColor(unit)
        button.stripe:SetVertexColor(cr, cg, cb, 1)
    end

    self:UpdatePrediction(button, health, maxHealth)

    local text
    if not UnitIsConnected(unit) then
        text = "|cff8a8c94" .. L["не в сети"] .. "|r"
    elseif UnitIsGhost(unit) then
        text = "|cff9aa0ac" .. L["дух"] .. "|r"
    elseif UnitIsDead(unit) then
        text = "|cffe05050" .. L["мёртв"] .. "|r"
    elseif UnitIsAFK and UnitIsAFK(unit) then
        text = "|cffd8b04a" .. L["отошёл"] .. "|r"
    elseif db.healthText == "percent" then
        text = math.floor(health / maxHealth * 100 + 0.5) .. "%"
    elseif db.healthText == "none" then
        text = ""
    elseif health < maxHealth then
        text = "-" .. Short(maxHealth - health)
    else
        text = ""
    end

    button.status:SetText(text)
end

function RaidFrames:UpdatePrediction(button, health, maxHealth)
    local HP = NS.HealPrediction
    if not HP or not button.predict then return end
    if not Settings().healPrediction then
        HP:Clear(button.predict)
        return
    end
    local unit = button.unit
    if not health then
        health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    end
    HP:Paint(button.predict, unit, health, maxHealth, button.healVertical)
end

function RaidFrames:UpdatePower(button)
    local db = Current()
    if not db.showPower then return end

    local unit = button.unit
    local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
    if maxPower <= 0 then maxPower = 1 end

    button.power:SetMinMaxValues(0, maxPower)
    button.power:SetValue(power)

    local _, token = UnitPowerType(unit)
    local color = POWER_COLORS[token] or POWER_COLORS.MANA
    local pr, pg, pb = NS.Look:Color("raid", "power")
    if pr then
        button.power:SetStatusBarColor(pr, pg, pb, 1)
    else
        button.power:SetStatusBarColor(color[1], color[2], color[3], 1)
    end
end

function RaidFrames:UpdateName(button)
    local unit = button.unit
    local name = UnitName(unit) or ""
    local db = Current()
    local width, height = ButtonSize(button, db)

    local style = BaseStyle(db.style)
    local room = (width or 92) - ((style == "cards" or style == "minimal") and 46 or 8)
    if style == "portrait" then room = room - height - 30 end
    local chars = math.max(4, math.floor(room / math.max(db.nameSize * 0.62, 1)))
    name = NS.TruncateText and NS.TruncateText(name, chars) or name

    button.nameText:SetText(name)

    local mode = db.nameColor
    if mode == "auto" then mode = db.colorMode == "class" and "white" or "class" end

    local tr, tg, tb = NS.Look:Color("raid", "text")
    if tr then
        button.nameText:SetTextColor(tr, tg, tb)
    elseif mode == "class" then
        button.nameText:SetTextColor(ClassColor(unit))
    else
        button.nameText:SetTextColor(0.95, 0.95, 0.97)
    end
end

local ROLE_COORDS = {
    TANK = { 0, 19 / 64, 22 / 64, 41 / 64 },
    HEALER = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 },
    DAMAGER = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
}

local ROLE_TEXT = {
    TANK = { "Танк", 0.40, 0.65, 1 },
    HEALER = { "Хил", 0.40, 0.92, 0.45 },
    DAMAGER = { "ДД", 0.98, 0.45, 0.40 },
}

local function RosterIndex(unit)
    local index = unit and unit:match("^raid(%d+)$")
    if index then return tonumber(index) end
    for i = 1, GetNumRaidMembers() do
        if UnitIsUnit("raid" .. i, unit) then return i end
    end
end

local specRoles = {}
local inspectTried = {}
local inspectPending

local function SpecRole(unit)
    local _, _, classID = UnitClass(unit)
    local data = classID and _G.S_CALSS_SPECIALIZATION_DATA and _G.S_CALSS_SPECIALIZATION_DATA[classID]
    if not data then return end
    local active = GetActiveTalentGroup and GetActiveTalentGroup(true)
    local best, bestPoints = nil, 0
    for _, group in ipairs({ active or false, false, 1, 2 }) do
        for tab = 1, 3 do
            local ok, _, _, points
            if group then
                ok, _, _, points = pcall(GetTalentTabInfo, tab, true, false, group)
            else
                ok, _, _, points = pcall(GetTalentTabInfo, tab, true)
            end
            points = ok and tonumber(points) or 0
            if points > bestPoints then best, bestPoints = tab, points end
        end
        if best then break end
    end
    local spec = best and data[best]
    if not spec or type(spec[5]) ~= "number" then return end
    local flags = spec[5]
    local tank = bit.band(flags, _G.S_SPECIALIZATION_ROLE_TANK_FLAG or 2) ~= 0
    local damage = bit.band(flags, _G.S_SPECIALIZATION_ROLE_DAMAGER_FLAG or 1) ~= 0
    if tank and damage then return "DAMAGER", true end
    if tank then return "TANK" end
    if bit.band(flags, _G.S_SPECIALIZATION_ROLE_HEAL_FLAG or 4) ~= 0 then return "HEALER" end
    return "DAMAGER"
end

local TANK_AURAS = { 5487, 9634, 48263 }
local tankAuraNames

local function TankAura(unit)
    if not tankAuraNames then
        tankAuraNames = {}
        for _, id in ipairs(TANK_AURAS) do
            local name = GetSpellInfo(id)
            if name then tankAuraNames[#tankAuraNames + 1] = name end
        end
    end
    for _, name in ipairs(tankAuraNames) do
        if UnitBuff(unit, name) then return true end
    end
    return false
end

local function InspectBusy()
    if InCombatLockdown() then return true end
    if _G.InspectFrame and _G.InspectFrame:IsShown() then return true end
    local scene = NS.InspectScene
    return scene and scene.active and true or false
end

local function GroupUnits()
    local list = {}
    local raid = GetNumRaidMembers() or 0
    if raid > 0 then
        for index = 1, raid do list[#list + 1] = "raid" .. index end
    else
        for index = 1, (GetNumPartyMembers() or 0) do list[#list + 1] = "party" .. index end
    end
    return list
end

local function AssignedRole(unit)
    if type(UnitGroupRolesAssigned) ~= "function" then return end
    local ok, isTank, isHealer, isDamage = pcall(UnitGroupRolesAssigned, unit)
    if not ok then return end
    if isTank == "TANK" or isTank == "HEALER" or isTank == "DAMAGER" then return isTank end
    return isTank == true and "TANK" or isHealer == true and "HEALER" or isDamage == true and "DAMAGER" or nil
end

local roleScan = CreateFrame("Frame")
local roleWait = 0
roleScan:SetScript("OnUpdate", function(_, elapsed)
    roleWait = roleWait + elapsed
    if roleWait < 1.5 then return end
    roleWait = 0
    if not RaidFrames.header or not RaidFrames.header:IsShown() or not Settings().showRole then return end
    local now = GetTime()
    if inspectPending and now - inspectPending.time < 5 then return end
    inspectPending = nil
    if InspectBusy() or type(NotifyInspect) ~= "function" then return end
    for _, unit in ipairs(GroupUnits()) do
        local guid = UnitGUID(unit)
        local cached = guid and specRoles[guid]
        if guid and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and UnitIsConnected(unit)
            and not AssignedRole(unit) and (not cached or now - cached.time > 600)
            and now - (inspectTried[guid] or -60) > 30
            and CanInspect(unit) and CheckInteractDistance(unit, 1) then
            inspectTried[guid] = now
            inspectPending = { unit = unit, guid = guid, time = now }
            NotifyInspect(unit)
            return
        end
    end
end)

local roleEvents = CreateFrame("Frame")
roleEvents:RegisterEvent("INSPECT_TALENT_READY")
roleEvents:SetScript("OnEvent", function()
    local pending = inspectPending
    if not pending or UnitGUID(pending.unit) ~= pending.guid then return end
    inspectPending = nil
    local role, dual = SpecRole(pending.unit)
    if role then
        specRoles[pending.guid] = { role = role, dual = dual, time = GetTime() }
        RaidFrames:ForEachShown(RaidFrames.UpdateRole)
    end
end)

function RaidFrames:DiagnoseRoles()
    local now = GetTime()
    for _, unit in ipairs(GroupUnits()) do
        local guid = UnitGUID(unit)
        local cached = guid and specRoles[guid]
        NS.Print(string.format("%s: assigned=%s cached=%s tried=%s inspect=%s range=%s online=%s",
            UnitName(unit) or unit, tostring(AssignedRole(unit)),
            cached and (cached.role .. (cached.dual and "/dual" or "")) or "-",
            guid and inspectTried[guid] and string.format("%.0fs", now - inspectTried[guid]) or "-",
            tostring(CanInspect(unit) and true or false), tostring(CheckInteractDistance(unit, 1) and true or false),
            tostring(UnitIsConnected(unit) and true or false)))
    end
    if inspectPending then NS.Print("pending: " .. tostring(UnitName(inspectPending.unit))) end
    NS.Print("busy=" .. tostring(InspectBusy()))
end

local function UnitRoleFallback(button)
    local person = button.narciPerson
    if person and person.role then return person.role end
    local unit = button.unit
    if not unit then return end
    if UnitIsUnit(unit, "player") and C_Talent and C_Talent.GetCurrentSpecRole then
        local ok, role = pcall(C_Talent.GetCurrentSpecRole)
        if ok and ROLE_TEXT[role] then return role end
    end
    local index = GetNumRaidMembers() > 0 and RosterIndex(unit)
    if index and select(10, GetRaidRosterInfo(index)) == "MAINTANK" then return "TANK" end
    local guid = UnitGUID(unit)
    local cached = guid and specRoles[guid]
    if cached then
        if cached.dual then return TankAura(unit) and "TANK" or "DAMAGER" end
        return cached.role
    end
end

function RaidFrames:UpdateRole(button)
    local db = Settings()
    local role

    if type(UnitGroupRolesAssigned) == "function" and button.unit and not button.narciPerson then
        local ok, isTank, isHealer, isDamage = pcall(UnitGroupRolesAssigned, button.unit)
        if ok then
            if isTank == "TANK" or isTank == "HEALER" or isTank == "DAMAGER" then
                role = isTank
            else
                role = isTank == true and "TANK" or isHealer == true and "HEALER" or isDamage == true and "DAMAGER" or nil
            end
        end
    end

    role = role or UnitRoleFallback(button)
    local style = db.roleStyle
    if not db.showRole then role = nil end

    if role and style ~= "text" then
        local c = ROLE_COORDS[role]
        button.role:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
        button.role:SetTexCoord(c[1], c[2], c[3], c[4])
        button.role:SetAlpha(1)
        button.role:Show()
    else
        button.role:Hide()
    end

    local iconSize = math.max(10, (Current().textSize or 10) + 1)
    button.role:SetSize(iconSize, iconSize)
    button.roleText:ClearAllPoints()
    if button.role:IsShown() then
        button.roleText:SetPoint("LEFT", button.role, "RIGHT", 2, 0)
    else
        button.roleText:SetPoint("LEFT", button.role, "LEFT", 0, 0)
    end

    local text = role and style ~= "icon" and ROLE_TEXT[role]
    if text then
        NS.LSetFont(button.roleText, "raid", math.max((Current().textSize or 10) - 1, 7), "OUTLINE")
        button.roleText:SetText(L[text[1]])
        button.roleText:SetTextColor(text[2], text[3], text[4])
        button.roleText:Show()
    else
        button.roleText:Hide()
    end
end

function RaidFrames:UpdateRank(button)
    local db = Settings()
    local unit = button.unit
    local person = button.narciPerson
    local leader, assist, looter

    if person then
        leader, assist, looter = person.rank == 2, person.rank == 1, person.looter
    elseif unit and UnitExists(unit) then
        if GetNumRaidMembers() > 0 then
            local index = RosterIndex(unit)
            if index then
                local _, rank, _, _, _, _, _, _, _, _, isLooter = GetRaidRosterInfo(index)
                leader, assist, looter = rank == 2, rank == 1, isLooter and true or false
                local method, _, raidMaster = GetLootMethod()
                if method == "master" and raidMaster then looter = raidMaster == index end
            end
        else
            local isLeader = UnitIsGroupLeader or UnitIsPartyLeader
            leader = isLeader and isLeader(unit) and true or false
            local method, partyMaster = GetLootMethod()
            if method == "master" and partyMaster then
                looter = partyMaster == 0 and UnitIsUnit(unit, "player") or partyMaster > 0 and UnitIsUnit(unit, "party" .. partyMaster)
            end
        end
    end

    if db.showLeader and (leader or assist) then
        button.rank:SetTexture(leader and "Interface\\GroupFrame\\UI-Group-LeaderIcon" or "Interface\\GroupFrame\\UI-Group-AssistantIcon")
        button.rank:Show()
    else
        button.rank:Hide()
    end

    button.looter:ClearAllPoints()
    if button.rank:IsShown() then
        button.looter:SetPoint("LEFT", button.rank, "RIGHT", 1, 0)
    else
        button.looter:SetPoint("CENTER", button, "TOPLEFT", 9, 1)
    end
    button.looter:SetShown(db.showLooter and looter and true or false)
end

function RaidFrames:UpdateMark(button)
    local index = GetRaidTargetIndex(button.unit)
    if index and SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(button.mark, index)
        button.mark:Show()
    else
        button.mark:Hide()
    end
end

function RaidFrames:UpdateReady(button)
    local state = GetReadyCheckStatus and GetReadyCheckStatus(button.unit)
    local texture = state and READY_TEXTURES[state]

    if texture then
        button.ready:SetTexture(texture)
        button.ready:Show()
    elseif not self.readyHold then
        button.ready:Hide()
    end
end

local INDICATOR_POINTS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "TOP", "BOTTOM", "LEFT", "RIGHT", "BOTTOMRIGHT" }

function RaidFrames:CenterIcon(button)
    if button.narciCenter then return button.narciCenter end
    local holder = CreateFrame("Frame", nil, button)
    holder:SetFrameLevel(button:GetFrameLevel() + 6)
    local back = holder:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints(holder)
    back:SetTexture(WHITE)
    local texture = holder:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", holder, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -1, 1)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local cooldown = CreateFrame("Cooldown", nil, holder)
    cooldown:SetAllPoints(texture)
    local text = holder:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(text, "raid", NS.FS(9), "OUTLINE")
    text:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 1, 0)
    holder.back, holder.texture, holder.cooldown, holder.count = back, texture, cooldown, text
    holder:Hide()
    button.narciCenter = holder
    return holder
end

function RaidFrames:Indicator(button, index)
    button.narciIndicators = button.narciIndicators or {}
    local frame = button.narciIndicators[index]
    if frame then return frame end
    frame = CreateFrame("Frame", nil, button)
    frame:SetFrameLevel(button:GetFrameLevel() + 7)
    local back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints(frame)
    back:SetTexture(WHITE)
    back:SetVertexColor(0, 0, 0, 1)
    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    local cooldown = CreateFrame("Cooldown", nil, frame)
    cooldown:SetAllPoints(fill)
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    frame.fill, frame.cooldown = fill, cooldown
    frame:Hide()
    button.narciIndicators[index] = frame
    return frame
end

local function SetTimer(cooldown, duration, expires, shown)
    if shown and duration and duration > 0 and expires and expires > 0 and CooldownFrame_SetTimer then
        CooldownFrame_SetTimer(cooldown, expires - duration, duration, 1)
        cooldown:Show()
    else
        cooldown:Hide()
    end
end

function RaidFrames:UpdateIndicators(button)
    local db = Settings()
    local F = NS.AuraFilters
    local unit = button.unit
    local list = (db.indicators ~= false and F) and F.Indicators(db.indicatorOff, db.indicatorExtra) or {}
    local size = db.indicatorSize or 8
    local icons = db.indicatorStyle == "icon"
    local used = 0

    for _, entry in ipairs(list) do
        if used >= #INDICATOR_POINTS then break end
        local name, _, icon, _, _, duration, expires, caster = UnitAura(unit, entry.name, nil, db.indicatorMine ~= false and "HELPFUL|PLAYER" or "HELPFUL")
        if name then
            used = used + 1
            local frame = self:Indicator(button, used)
            local point = INDICATOR_POINTS[used]
            frame:ClearAllPoints()
            frame:SetPoint(point, button, point, 0, 0)
            frame:SetSize(size, size)
            if icons then
                frame.fill:SetTexture(icon)
                frame.fill:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                frame.fill:SetVertexColor(1, 1, 1, 1)
            else
                frame.fill:SetTexture(WHITE)
                frame.fill:SetTexCoord(0, 1, 0, 1)
                frame.fill:SetVertexColor(entry.color[1], entry.color[2], entry.color[3], 1)
            end
            SetTimer(frame.cooldown, duration, expires, db.indicatorTimer ~= false)
            frame:Show()
        end
    end

    for index = used + 1, #(button.narciIndicators or {}) do button.narciIndicators[index]:Hide() end
end

local SERVER_AURA_TABLES = {
    "CUF_SPELL_VISIBILITY_BLACKLIST", "FACTION_OVERRIDE_BY_DEBUFFS", "ZODIAC_DEBUFFS",
    "S_CATEGORY_SPELL_ID", "S_VIP_STATUS_DATA", "S_PREMIUM_SPELL_ID",
}

local LFG_AURAS = { 71328, 71041 }
local lfgNames

local function LFGAura(name)
    if not name then return false end
    if not lfgNames then
        lfgNames = {}
        for _, id in ipairs(LFG_AURAS) do
            local spell = GetSpellInfo(id)
            if spell then lfgNames[spell] = true end
        end
    end
    return lfgNames[name] or false
end

local function ServerAura(spellId, name)
    if LFGAura(name) then return true end
    if not spellId then return false end
    if spellId == LFG_AURAS[1] or spellId == LFG_AURAS[2] then return true end
    for _, tableName in ipairs(SERVER_AURA_TABLES) do
        local list = _G[tableName]
        if type(list) == "table" and list[spellId] then return true end
    end
    return false
end
RaidFrames.ServerAura = ServerAura

function RaidFrames:DiagnoseDebuffs()
    local units = { "player" }
    for index = 1, (GetNumPartyMembers() or 0) do units[#units + 1] = "party" .. index end
    for _, unit in ipairs(units) do
        for index = 1, 40 do
            local name, _, icon, _, _, _, _, caster, _, _, spellId = UnitDebuff(unit, index)
            if not name then break end
            NS.Print(string.format("%s: %s  id=%s  caster=%s  icon=%s  %s", UnitName(unit) or unit, name,
                tostring(spellId), tostring(caster), tostring(icon), ServerAura(spellId, name) and "|cff66ff66hidden|r" or "|cffff6666shown|r"))
        end
    end
end

function RaidFrames:UpdateAuras(button)
    local db = Settings()
    local F = NS.AuraFilters
    local unit = button.unit
    local shown = 0
    local limit = math.min(MAX_DEBUFFS, db.maxDebuffs or MAX_DEBUFFS)
    local mode = db.debuffFilter or "all"

    local dispellable = button.narciDispellable or {}
    button.narciDispellable = dispellable
    for key in pairs(dispellable) do dispellable[key] = nil end

    local Debuff = button.narciFakeDebuff or UnitDebuff
    local dispel
    for index = 1, 40 do
        local name, _, _, _, debuffType = Debuff(unit, index, "RAID")
        if not name then break end
        if DEBUFF_COLORS[debuffType] then
            dispellable[name] = true
            dispel = dispel or DEBUFF_COLORS[debuffType]
        end
    end

    local centerShown = false
    for index = 1, 40 do
        local name, _, icon, count, debuffType, duration, expires, caster, _, _, spellId = Debuff(unit, index)
        if not name then break end

        local server = db.hideServerDebuffs ~= false and ServerAura(spellId, name)
        local important = not server and F and F.IsRaidDebuff(name, db.raidDebuffs, db.raidBuiltin) or false
        local isCenter = false

        if important and db.centerDebuff ~= false and not centerShown then
            centerShown, isCenter = true, true
            local center = self:CenterIcon(button)
            local size = db.centerSize or 22
            center:SetSize(size, size)
            center:ClearAllPoints()
            center:SetPoint("CENTER", button, "CENTER", 0, 0)
            center.texture:SetTexture(icon)
            center.count:SetText((count and count > 1) and count or "")
            local color = DEBUFF_COLORS[debuffType]
            if color then
                center.back:SetVertexColor(color[1], color[2], color[3], 1)
            else
                center.back:SetVertexColor(0.8, 0.1, 0.1, 1)
            end
            SetTimer(center.cooldown, duration, expires, true)
            center:Show()
        end

        local pass = mode == "all" or (mode == "dispellable" and dispellable[name])
            or (mode == "important" and (important or dispellable[name]))
        if db.showDebuffs and not isCenter and not server and shown < limit and pass
            and (not F or F.Allowed(name, caster, db, "debuff")) then
            shown = shown + 1
            local frame = button.debuffs[shown]
            frame.texture:SetTexture(icon)
            frame.count:SetText((count and count > 1) and count or "")

            local color = DEBUFF_COLORS[debuffType]
            if color then
                frame.back:SetVertexColor(color[1], color[2], color[3], 1)
            else
                frame.back:SetVertexColor(0, 0, 0, 1)
            end

            frame:Show()
        end
    end

    for index = shown + 1, MAX_DEBUFFS do button.debuffs[index]:Hide() end
    if not centerShown and button.narciCenter then button.narciCenter:Hide() end

    local dispelMode = db.dispelMode or "border"
    button.dispel = (dispelMode == "border" or dispelMode == "both") and dispel or nil

    if dispelMode == "fill" or dispelMode == "both" then
        if not button.narciDispelFill then
            local fill = button.health:CreateTexture(nil, "OVERLAY")
            fill:SetAllPoints(button.health)
            fill:SetTexture(WHITE)
            fill:SetBlendMode("ADD")
            button.narciDispelFill = fill
        end
        if dispel then
            local strength = (db.dispelAlpha or 35) / 100
            button.narciDispelFill:SetVertexColor(dispel[1] * strength, dispel[2] * strength, dispel[3] * strength, 1)
            button.narciDispelFill:Show()
        else
            button.narciDispelFill:Hide()
        end
    elseif button.narciDispelFill then
        button.narciDispelFill:Hide()
    end

    self:UpdateIndicators(button)
    self:UpdateBorder(button)
end

function RaidFrames:UpdateBorder(button)
    local S = Style()
    local style = BaseStyle(Settings().style)
    local unit = button.unit
    local r, g, b
    local marked = true

    local threat = UnitThreatSituation and UnitThreatSituation(unit)
    if UnitIsUnit(unit, "target") then
        r, g, b = 1, 1, 1
    elseif threat and threat >= 2 then
        r, g, b = 0.95, 0.25, 0.20
    elseif button.dispel then
        r, g, b = button.dispel[1], button.dispel[2], button.dispel[3]
    else
        r, g, b = S.BORDER[1], S.BORDER[2], S.BORDER[3]
        marked = false
    end

    if style == "glow" then
        if marked then
            PaintGlow(button.glow, r, g, b, 0.8)
        else
            local cr, cg, cb = ClassColor(unit)
            PaintGlow(button.glow, cr, cg, cb, 0.22)
        end
    elseif style == "minimal" then
        if marked then
            Paint(button.barEdges, r, g, b, 1)
        else
            Paint(button.barEdges, 0, 0, 0, 1)
        end
    else
        if not marked and style == "outline" then
            r, g, b = ClassColor(unit)
        elseif not marked and style == "glass" then
            r, g, b = S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8
        end
        if not marked then
            local er, eg, eb = NS.Look:Color("raid", "border")
            if er then r, g, b = er, eg, eb end
        end
        Paint(button.edges, r, g, b, 1)
        Paint(button.barEdges, 0, 0, 0, 0.9)
    end
end

function RaidFrames:UpdatePortrait(button)
    if BaseStyle(Settings().style) ~= "portrait" then return end
    SetPortraitTexture(button.portrait, button.unit)
end

function RaidFrames:UpdateRange(button)
    local db = Settings()
    local unit = button.unit
    local alpha = 1

    if db.rangeFade and not UnitIsUnit(unit, "player") and UnitIsConnected(unit) then
        local ok, inRange, checked = pcall(UnitInRange, unit)
        if ok and not inRange and checked ~= false then alpha = 0.4 end
    end

    if button.narciAlpha ~= alpha then
        button.narciAlpha = alpha
        button:SetAlpha(alpha)
    end
end

function RaidFrames:Update(button)
    if not button.unit or not UnitExists(button.unit) then return end

    self:UpdateHealth(button)
    self:UpdatePower(button)
    self:UpdateName(button)
    self:UpdatePortrait(button)
    self:UpdateRole(button)
    self:UpdateRank(button)
    self:UpdateMark(button)
    self:UpdateReady(button)
    self:UpdateAuras(button)
    self:UpdateRange(button)
end

function RaidFrames:UpdateAll()
    for _, button in ipairs(buttons) do
        if button:IsShown() and button.unit then self:Update(button) end
    end
end

function RaidFrames:ForEachShown(fn)
    for _, button in ipairs(buttons) do
        if button:IsShown() and button.unit and UnitExists(button.unit) then fn(self, button) end
    end
end

function RaidFrames:Header()
    if self.header then return self.header end
    if InCombatLockdown() then return end

    local holder = Holder()

    local header = CreateFrame("Frame", "NarciSirus_RaidHeader", holder, "SecureGroupHeaderTemplate")
    header:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    header:SetAttribute("template", "SecureUnitButtonTemplate")
    header:SetAttribute("templateType", "Button")
    header.initialConfigFunction = function(button)
        RaidFrames:BuildButton(button)
    end

    self.header = header
    return header
end

function RaidFrames:TankHeader()
    if self.tankHeader then return self.tankHeader end
    if InCombatLockdown() then return end

    local db = Settings()
    local holder = CreateFrame("Frame", "NarciSirus_TankHolder", UIParent)
    holder:SetFrameStrata("LOW")
    holder:SetSize(db.tankWidth or 120, (db.tankHeight or 32) * 2 + 3)
    if db.tankPoint then
        holder:SetPoint(db.tankPoint, UIParent, db.tankRelative or db.tankPoint, db.tankX or 0, db.tankY or 0)
    else
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -170)
    end

    if NS.Movers then
        NS.Movers:Register(holder, L["Главные танки"], function(point, relativePoint, x, y)
            local store = Settings()
            if not store then return end
            store.tankPoint, store.tankRelative, store.tankX, store.tankY = point, relativePoint, x, y
        end, "raid")
    end

    local header = CreateFrame("Frame", "NarciSirus_TankHeader", holder, "SecureGroupHeaderTemplate")
    header:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    header:SetAttribute("template", "SecureUnitButtonTemplate")
    header:SetAttribute("templateType", "Button")
    header:SetAttribute("groupFilter", "MAINTANK")
    header:SetAttribute("showRaid", true)
    header:SetAttribute("point", "TOP")
    header:SetAttribute("xOffset", 0)
    header.initialConfigFunction = function(button)
        button.narciTank = true
        RaidFrames:BuildButton(button)
    end

    self.tankHolder, self.tankHeader = holder, header
    return header
end

function RaidFrames:ApplyTanks()
    local db = Settings()
    local header = db.tanks and self:TankHeader() or self.tankHeader
    if not header then return end

    header:Hide()
    if not db.tanks or not Enabled() then
        self.tankHolder:Hide()
        return
    end

    local width, height = db.tankWidth or 120, db.tankHeight or 32
    header:SetAttribute("yOffset", -(db.spacing or 3))
    for _, button in ipairs(buttons) do
        if button.narciTank then
            button:SetWidth(width)
            button:SetHeight(height)
            self:Layout(button)
        end
    end
    self.tankHolder:SetSize(width, height * 2 + (db.spacing or 3))
    self.tankHolder:Show()
    header:Show()
end

function RaidFrames:ApplyLayout()
    if InCombatLockdown() then
        self.layoutPending = true
        return
    end
    self.layoutPending = nil

    self.sizeKind = SizeKind()
    local db = Current()
    local header = self:Header()
    if not header then return end

    header:Hide()

    header:SetAttribute("showRaid", true)
    header:SetAttribute("showParty", db.party and true or false)
    header:SetAttribute("showPlayer", db.party and true or false)
    header:SetAttribute("showSolo", db.solo and true or false)
    header:SetAttribute("groupBy", "GROUP")
    header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
    header:SetAttribute("sortMethod", "INDEX")
    header:SetAttribute("maxColumns", 8)
    header:SetAttribute("unitsPerColumn", 5)
    header:SetAttribute("columnSpacing", db.spacing)

    if db.growth == "DOWN" then
        header:SetAttribute("point", "LEFT")
        header:SetAttribute("xOffset", db.spacing)
        header:SetAttribute("yOffset", 0)
        header:SetAttribute("columnAnchorPoint", "TOP")
    else
        header:SetAttribute("point", "TOP")
        header:SetAttribute("xOffset", 0)
        header:SetAttribute("yOffset", -db.spacing)
        header:SetAttribute("columnAnchorPoint", "LEFT")
    end

    if not self.prebuilt then
        self.prebuilt = true
        header:SetAttribute("showSolo", true)
        header:SetAttribute("startingIndex", -39)
        header:Show()
        header:Hide()
        header:SetAttribute("startingIndex", 1)
        header:SetAttribute("showSolo", db.solo and true or false)
    end

    for _, button in ipairs(buttons) do
        if not button.narciTank then
            button:SetWidth(db.width)
            button:SetHeight(db.height)
            self:Layout(button)
        end
    end

    local holder = Holder()
    if db.growth == "DOWN" then
        holder:SetSize(db.width * 5 + db.spacing * 4, db.height * 2 + db.spacing)
    else
        holder:SetSize(db.width * 2 + db.spacing, db.height * 5 + db.spacing * 4)
    end

    if Enabled() then
        header:Show()
        holder:Show()
    else
        holder:Hide()
    end

    self:ApplyTanks()
    self:UpdateAll()
end

function RaidFrames:RefreshHeaders()
    if InCombatLockdown() then
        self.refreshPending = true
        return
    end
    self.refreshPending = nil
    self.refreshCount = (self.refreshCount or 0) + 1
    for _, header in ipairs({ self.header, self.tankHeader }) do
        if header and header:IsVisible() then header:SetAttribute("narciRefresh", self.refreshCount) end
    end
end

function RaidFrames:QueueRefresh()
    if not NS.After then return end
    for _, delay in ipairs({ 0.5, 3 }) do
        NS.After(delay, function() RaidFrames:RefreshHeaders() end)
    end
end

local hiddenParent

function RaidFrames:HideBlizzard()
    local db = Settings()
    if not db or not db.enabled or not db.hideBlizzard then return end

    if InCombatLockdown() then
        self.blizzardPending = true
        return
    end
    self.blizzardPending = nil

    hiddenParent = hiddenParent or CreateFrame("Frame")
    hiddenParent:Hide()

    if NS.DFUI and not self.dfPartyHooked and type(_G.CompactPartyFrame_Generate) == "function" then
        self.dfPartyHooked = true
        hooksecurefunc("CompactPartyFrame_Generate", function() RaidFrames:HideBlizzard() end)
    end

    local names = BLIZZARD_FRAMES
    if NS.DFUI then
        names = {}
        for _, name in ipairs(BLIZZARD_FRAMES) do names[#names + 1] = name end
        names[#names + 1] = "PartyFrame"
    end

    for _, name in ipairs(names) do
        local frame = _G[name]
        local skipParty = not db.party and (name:find("^Party") or (NS.DFUI and name == "CompactPartyFrame"))
        if frame and not frame.narciRaidHidden and not skipParty then
            frame.narciRaidHidden = true
            pcall(frame.UnregisterAllEvents, frame)
            pcall(frame.SetParent, frame, hiddenParent)
            pcall(frame.Hide, frame)
        end
    end
end

function RaidFrames:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value
    self:ApplyLayout()
    self:UpdateAll()
end

function RaidFrames:Init()
    if not Enabled() then return end
    self:ApplyLayout()
    self:HideBlizzard()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("PARTY_MEMBERS_CHANGED")
driver:RegisterEvent("RAID_ROSTER_UPDATE")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("RAID_TARGET_UPDATE")
driver:RegisterEvent("READY_CHECK")
driver:RegisterEvent("READY_CHECK_CONFIRM")
driver:RegisterEvent("READY_CHECK_FINISHED")
driver:RegisterEvent("PARTY_MEMBER_ENABLE")
driver:RegisterEvent("PARTY_MEMBER_DISABLE")
driver:RegisterEvent("PLAYER_FLAGS_CHANGED")
driver:RegisterEvent("UNIT_HEALTH")
driver:RegisterEvent("UNIT_MAXHEALTH")
driver:RegisterEvent("UNIT_AURA")
driver:RegisterEvent("UNIT_NAME_UPDATE")
driver:RegisterEvent("UNIT_PORTRAIT_UPDATE")
driver:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
pcall(driver.RegisterEvent, driver, "PLAYER_ROLES_ASSIGNED")
driver:RegisterEvent("PARTY_LEADER_CHANGED")
driver:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

if NS.HealPrediction then
    NS.HealPrediction:Watch(function(guids)
        if not Enabled() then return end
        for _, button in ipairs(buttons) do
            if button.unit and button:IsShown() then
                local guid = UnitGUID(button.unit)
                if guid and guids[guid] then RaidFrames:UpdatePrediction(button) end
            end
        end
    end)
end

local POWER = {}
for _, event in ipairs(POWER_EVENTS) do
    POWER[event] = true
    driver:RegisterEvent(event)
end

local rangeElapsed = 0
driver:SetScript("OnUpdate", function(self, step)
    rangeElapsed = rangeElapsed + step
    if rangeElapsed < RANGE_INTERVAL then return end
    rangeElapsed = 0

    if not Enabled() or not RaidFrames.header or not RaidFrames.header:IsShown() then return end
    local fading = Settings().rangeFade and true or false
    if not fading and not RaidFrames.rangeFaded then return end
    RaidFrames.rangeFaded = fading
    RaidFrames:ForEachShown(RaidFrames.UpdateRange)
end)

driver:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        if NS.After then
            NS.After(1, function() RaidFrames:Init() end)
        else
            RaidFrames:Init()
        end
        return
    end

    if not Enabled() then return end

    if event == "PLAYER_REGEN_ENABLED" then
        if RaidFrames.layoutPending or not RaidFrames.header then RaidFrames:ApplyLayout() end
        if RaidFrames.blizzardPending then RaidFrames:HideBlizzard() end
        if RaidFrames.refreshPending then RaidFrames:RefreshHeaders() end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE"
        or event == "PLAYER_ROLES_ASSIGNED" then
        if not RaidFrames.header or SizeKind() ~= RaidFrames.sizeKind then RaidFrames:ApplyLayout() end
        RaidFrames:HideBlizzard()
        RaidFrames:QueueRefresh()
        if NS.After then
            NS.After(0.2, function() RaidFrames:UpdateAll() end)
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        RaidFrames:ForEachShown(RaidFrames.UpdateBorder)
        return
    end

    if event == "PARTY_LEADER_CHANGED" or event == "PARTY_LOOT_METHOD_CHANGED" then
        RaidFrames:ForEachShown(RaidFrames.UpdateRank)
        return
    end

    if event == "RAID_TARGET_UPDATE" then
        RaidFrames:ForEachShown(RaidFrames.UpdateMark)
        return
    end

    if event == "READY_CHECK" or event == "READY_CHECK_CONFIRM" then
        RaidFrames.readyHold = nil
        RaidFrames:ForEachShown(RaidFrames.UpdateReady)
        return
    end

    if event == "READY_CHECK_FINISHED" then
        RaidFrames.readyHold = true
        RaidFrames:ForEachShown(RaidFrames.UpdateReady)
        if NS.After then
            NS.After(6, function()
                RaidFrames.readyHold = nil
                for _, button in ipairs(buttons) do button.ready:Hide() end
            end)
        end
        return
    end

    if event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" or event == "PLAYER_FLAGS_CHANGED" then
        RaidFrames:ForEachShown(RaidFrames.UpdateHealth)
        return
    end

    local set = unit and byUnit[unit]
    if not set then return end

    for button in pairs(set) do
        if button:IsShown() and button.unit == unit then
            if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                RaidFrames:UpdateHealth(button)
            elseif POWER[event] then
                RaidFrames:UpdatePower(button)
            elseif event == "UNIT_AURA" then
                RaidFrames:UpdateAuras(button)
                local cached = specRoles[UnitGUID(unit) or ""]
                if cached and cached.dual then RaidFrames:UpdateRole(button) end
            elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
                RaidFrames:UpdateBorder(button)
            elseif event == "UNIT_NAME_UPDATE" then
                RaidFrames:UpdateName(button)
            elseif event == "UNIT_PORTRAIT_UPDATE" then
                RaidFrames:UpdatePortrait(button)
            end
        end
    end
end)
