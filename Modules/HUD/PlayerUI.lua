local addonName, NS = ...
local L = NS.L

local PlayerUI = {}
NS.PlayerUI = PlayerUI

local WHITE = "Interface\\Buttons\\WHITE8x8"

local POWER_EVENTS = {
    "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS",
    "UNIT_RUNIC_POWER", "UNIT_HAPPINESS",
    "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXENERGY", "UNIT_MAXFOCUS",
    "UNIT_MAXRUNIC_POWER", "UNIT_MAXHAPPINESS",
}

local POWER_COLORS = {
    MANA = { 0.25, 0.50, 0.90 },
    RAGE = { 0.78, 0.25, 0.25 },
    FOCUS = { 0.75, 0.55, 0.25 },
    ENERGY = { 0.90, 0.82, 0.35 },
    RUNIC_POWER = { 0.35, 0.65, 0.80 },
    HAPPINESS = { 0.35, 0.75, 0.45 },
}

local LAYOUT = {
    player = { width = 236, height = 42, point = "BOTTOM", x = -190, y = 250, label = "Игрок" },
    target = { width = 236, height = 42, point = "BOTTOM", x = 190, y = 250, label = "Цель", mirror = true },
    targettarget = { width = 130, height = 28, point = "BOTTOM", x = 386, y = 250, label = "Цель цели", mirror = true },
    pet = { width = 130, height = 28, point = "BOTTOM", x = -386, y = 250, label = "Питомец" },
    focus = { width = 180, height = 32, point = "BOTTOM", x = -190, y = 330, label = "Фокус" },
    focustarget = { width = 130, height = 26, point = "BOTTOM", x = -20, y = 330, label = "Цель фокуса", off = true },
    pettarget = { width = 110, height = 24, point = "BOTTOM", x = -386, y = 290, label = "Цель питомца", off = true },
    targettargettarget = { width = 110, height = 24, point = "BOTTOM", x = 386, y = 290, label = "Цель цели цели", mirror = true, off = true },
}

local ORDER = { "player", "target", "targettarget", "pet", "focus", "focustarget", "pettarget", "targettargettarget" }
local POLLED = { "targettarget", "focustarget", "pettarget", "targettargettarget" }

for index = 1, 4 do
    LAYOUT["boss" .. index] = { width = 190, height = 34, point = "RIGHT", x = -250, y = 200 - (index - 1) * 56, label = "Босс " .. index, mirror = true }
    ORDER[#ORDER + 1] = "boss" .. index
end
for index = 1, 5 do
    LAYOUT["arena" .. index] = { width = 190, height = 34, point = "RIGHT", x = -250, y = 160 - (index - 1) * 56, label = "Арена " .. index, mirror = true }
    ORDER[#ORDER + 1] = "arena" .. index
end

local MODEL_UNITS = { player = true, target = true }
local AURA_UNITS = { target = true, focus = true }

local AURA_TOGGLES = {
    target = { on = "targetAuras", buffs = "targetBuffs", debuffs = "targetDebuffs" },
    focus  = { on = "focusAuras",  buffs = "focusBuffs",  debuffs = "focusDebuffs" },
}

local DEBUFF_COLORS = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
}

local DEBUFF_DEFAULT = { 0.80, 0.20, 0.20 }

local BAR_EVENTS = { UNIT_HEALTH = true, UNIT_MAXHEALTH = true }
for _, event in ipairs(POWER_EVENTS) do BAR_EVENTS[event] = true end

local frames = {}
local moving = false

local FRAME_STYLES = {
    classic = true, slim = true, float = true, neon = true, glass = true, plates = true,
    pixel = true, dark = true, outline = true,
}
PlayerUI.EXTRA_STYLES = {}
PlayerUI.EXTRA_LIST = {}

local function BaseFrameStyle(style)
    local extra = PlayerUI.EXTRA_STYLES[style]
    return extra and extra.base or style
end
local GLOW_SIZE = 7

local function ShowAll(list, shown)
    for _, region in ipairs(list) do region:SetShown(shown) end
end

local function CreateGlow(f)
    return NS.Styling.GlowPieces(f, GLOW_SIZE, "BACKGROUND", "ADD", true)
end

local function PaintGlow(glow, r, g, b, a)
    for _, texture in ipairs(glow) do
        texture:SetVertexColor(r, g, b, a)
    end
end

local function FillSettings()
    if not NS.db then return end

    if not NS.db.playerUI then NS.db.playerUI = {} end

    local db = NS.db.playerUI
    if db.enabled == nil then db.enabled = false end
    if db.hideBlizzard == nil then db.hideBlizzard = true end
    if db.showPower == nil then db.showPower = true end
    if db.targetAuras == nil then db.targetAuras = true end
    if db.focusAuras == nil then db.focusAuras = true end
    for _, keys in pairs(AURA_TOGGLES) do
        if db[keys.buffs] == nil then db[keys.buffs] = true end
        if db[keys.debuffs] == nil then db[keys.debuffs] = true end
    end
    if db.healPrediction == nil then db.healPrediction = true end
    db.powerHeight = db.powerHeight or 10
    db.auraSize = db.auraSize or 22
    db.auraDebuffSize = db.auraDebuffSize or 30
    db.auraPerRow = db.auraPerRow or 12
    db.portrait = db.portrait or "2D"
    db.healthColor = db.healthColor or "class"
    db.textFormat = db.textFormat or "auto"
    db.nameSize = db.nameSize or 0
    db.valueSize = db.valueSize or 0
    db.scale = db.scale or 1
    db.units = db.units or {}
    if not FRAME_STYLES[db.frameStyle] then db.frameStyle = "classic" end

    if not db.layoutV2 then
        db.layoutV2 = true

        for unit, preset in pairs(LAYOUT) do
            local store = db.units[unit]
            if store then
                store.point, store.x, store.y = preset.point, preset.x, preset.y
                store.width, store.height = preset.width, preset.height
            end
        end
    end

    for unit, preset in pairs(LAYOUT) do
        local store = db.units[unit] or {}
        store.width = store.width or preset.width
        store.height = store.height or preset.height
        store.point = store.point or preset.point
        store.x = store.x or preset.x
        store.y = store.y or preset.y
        if store.enabled == nil then store.enabled = not preset.off end
        store.alpha = store.alpha or 1
        db.units[unit] = store
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.playerUI
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function FrameHeight(db, store)
    if db.showPower then return store.height + db.powerHeight + 2 end
    return store.height
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

function PlayerUI:AuraShown(unit, db)
    local keys = AURA_TOGGLES[unit]
    db = db or Settings()
    if not keys or not db or db[keys.on] == false then return false, false end
    return db[keys.buffs] ~= false, db[keys.debuffs] ~= false
end

local function Short(value)
    if value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(value)
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function Percent(value, maximum)
    if not maximum or maximum <= 0 then return "0" end
    return tostring(math.floor(value / maximum * 100 + 0.5))
end

local TAGS = {
    name = function(u) return UnitName(u) or "" end,
    level = function(u)
        local level = UnitLevel(u)
        return (level and level > 0) and tostring(level) or "??"
    end,
    class = function(u) return UnitIsPlayer(u) and (UnitClass(u) or "") or (UnitCreatureType(u) or "") end,
    race = function(u) return UnitRace(u) or "" end,
    classification = function(u)
        local kind = UnitClassification(u)
        if kind == "worldboss" then return L["босс"] end
        if kind == "rareelite" then return L["редкий элита"] end
        if kind == "elite" then return L["элита"] end
        if kind == "rare" then return L["редкий"] end
        return ""
    end,
    status = function(u)
        if not UnitIsConnected(u) then return L["не в сети"] end
        if UnitIsGhost(u) then return L["дух"] end
        if UnitIsDead(u) then return L["мёртв"] end
        if UnitIsAFK and UnitIsAFK(u) then return "AFK" end
        return ""
    end,
    ["health:current"] = function(u) return Short(UnitHealth(u) or 0) end,
    ["health:max"] = function(u) return Short(UnitHealthMax(u) or 0) end,
    ["health:percent"] = function(u) return Percent(UnitHealth(u) or 0, UnitHealthMax(u)) .. "%" end,
    ["health:deficit"] = function(u)
        local missing = (UnitHealthMax(u) or 0) - (UnitHealth(u) or 0)
        return missing > 0 and ("-" .. Short(missing)) or ""
    end,
    ["power:current"] = function(u) return Short(UnitPower(u) or 0) end,
    ["power:max"] = function(u) return Short(UnitPowerMax(u) or 0) end,
    ["power:percent"] = function(u) return Percent(UnitPower(u) or 0, UnitPowerMax(u)) .. "%" end,
    classcolor = function(u)
        local _, class = UnitClass(u)
        local color = UnitIsPlayer(u) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return Hex(color.r, color.g, color.b) end
        local reaction = UnitReaction(u, "player")
        local tint = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
        if tint then return Hex(tint.r, tint.g, tint.b) end
        return "|cffffffff"
    end,
    accent = function() local A = NS.Styling.ACCENT_GLOW return Hex(A[1], A[2], A[3]) end,
    close = function() return "|r" end,
}

local function Cut(text, limit)
    text = text or ""
    local count, cut = 0, nil
    for position in text:gmatch("()[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > limit then cut = position break end
    end
    return cut and text:sub(1, cut - 1) or text
end

local function HealthRatio(u)
    local maximum = UnitHealthMax(u) or 0
    if maximum <= 0 then return 0 end
    return (UnitHealth(u) or 0) / maximum
end

local function Exact(value)
    value = math.floor(value or 0)
    local text = tostring(value)
    local formatted = text:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (formatted:gsub("^ ", ""))
end

local function Threat(u)
    if not UnitCanAttack("player", u) then return end
    local _, status, percent = UnitDetailedThreatSituation("player", u)
    return status, percent
end

local EXTRA_TAGS = {
    ["name:veryshort"] = function(u) return Cut(UnitName(u), 5) end,
    ["name:short"] = function(u) return Cut(UnitName(u), 10) end,
    ["name:medium"] = function(u) return Cut(UnitName(u), 15) end,
    ["name:long"] = function(u) return Cut(UnitName(u), 20) end,
    ["level:smart"] = function(u)
        local level = UnitLevel(u)
        if not level or level <= 0 then return "??" end
        if UnitIsPlayer(u) and level == UnitLevel("player") then return "" end
        return tostring(level)
    end,
    ["classification:short"] = function(u)
        local kind = UnitClassification(u)
        if kind == "worldboss" then return "B" end
        if kind == "rareelite" then return "R+" end
        if kind == "elite" then return "+" end
        if kind == "rare" then return "R" end
        return ""
    end,
    creature = function(u) return UnitCreatureType(u) or "" end,
    faction = function(u)
        local _, localized = UnitFactionGroup(u)
        return localized or ""
    end,
    guild = function(u)
        local guild = UnitIsPlayer(u) and GetGuildInfo(u)
        return guild and ("<" .. guild .. ">") or ""
    end,
    group = function(u)
        local index = UnitInRaid(u)
        if not index then return "" end
        local _, _, subgroup = GetRaidRosterInfo(index + 1)
        return subgroup and tostring(subgroup) or ""
    end,
    target = function(u) return UnitName(u .. "target") or "" end,
    pvp = function(u) return UnitIsPVP(u) and "PvP" or "" end,
    resting = function(u) return (UnitIsUnit(u, "player") and IsResting()) and "zzz" or "" end,
    combat = function(u) return UnitAffectingCombat(u) and L["бой"] or "" end,
    leader = function(u) return (UnitIsPartyLeader and UnitIsPartyLeader(u)) and L["лидер"] or "" end,
    afk = function(u) return (UnitIsAFK and UnitIsAFK(u)) and "AFK" or "" end,
    dnd = function(u) return (UnitIsDND and UnitIsDND(u)) and "DND" or "" end,
    dead = function(u) return UnitIsDeadOrGhost(u) and L["мёртв"] or "" end,
    offline = function(u) return (not UnitIsConnected(u)) and L["не в сети"] or "" end,
    ["health:exact"] = function(u) return Exact(UnitHealth(u)) end,
    ["health:current-max"] = function(u) return Short(UnitHealth(u) or 0) .. " / " .. Short(UnitHealthMax(u) or 0) end,
    ["health:current-percent"] = function(u)
        return Short(UnitHealth(u) or 0) .. " | " .. Percent(UnitHealth(u) or 0, UnitHealthMax(u)) .. "%"
    end,
    ["health:current-max-percent"] = function(u)
        return Short(UnitHealth(u) or 0) .. " / " .. Short(UnitHealthMax(u) or 0) .. " | " .. Percent(UnitHealth(u) or 0, UnitHealthMax(u)) .. "%"
    end,
    ["health:deficit-percent"] = function(u)
        local ratio = HealthRatio(u)
        if ratio >= 1 then return "" end
        return "-" .. math.floor((1 - ratio) * 100 + 0.5) .. "%"
    end,
    ["health:percent-status"] = function(u)
        if not UnitIsConnected(u) then return L["не в сети"] end
        if UnitIsDeadOrGhost(u) then return L["мёртв"] end
        return Percent(UnitHealth(u) or 0, UnitHealthMax(u)) .. "%"
    end,
    ["power:deficit"] = function(u)
        local missing = (UnitPowerMax(u) or 0) - (UnitPower(u) or 0)
        return missing > 0 and ("-" .. Short(missing)) or ""
    end,
    ["power:current-max"] = function(u) return Short(UnitPower(u) or 0) .. " / " .. Short(UnitPowerMax(u) or 0) end,
    ["power:current-percent"] = function(u)
        return Short(UnitPower(u) or 0) .. " | " .. Percent(UnitPower(u) or 0, UnitPowerMax(u)) .. "%"
    end,
    ["mana:current"] = function(u) return Short(UnitPower(u, 0) or 0) end,
    ["mana:percent"] = function(u) return Percent(UnitPower(u, 0) or 0, UnitPowerMax(u, 0)) .. "%" end,
    absorb = function(u)
        local HP = NS.HealPrediction
        local value = HP and HP:Absorbs(u) or 0
        return value > 0 and Short(value) or ""
    end,
    incheals = function(u)
        local HP = NS.HealPrediction
        if not HP then return "" end
        local mine, other = HP:Incoming(u)
        local total = mine + other
        return total > 0 and ("+" .. Short(total)) or ""
    end,
    ["incheals:mine"] = function(u)
        local HP = NS.HealPrediction
        if not HP then return "" end
        local mine = HP:Incoming(u)
        return mine > 0 and ("+" .. Short(mine)) or ""
    end,
    ["threat:percent"] = function(u)
        local _, percent = Threat(u)
        return percent and (math.floor(percent + 0.5) .. "%") or ""
    end,
    threatcolor = function(u)
        local status = Threat(u)
        if status and status > 0 and GetThreatStatusColor then
            return Hex(GetThreatStatusColor(status))
        end
        return "|cffffffff"
    end,
    reactioncolor = function(u)
        local reaction = UnitReaction(u, "player")
        local tint = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
        if tint then return Hex(tint.r, tint.g, tint.b) end
        return "|cffffffff"
    end,
    difficultycolor = function(u)
        local color = GetQuestDifficultyColor and GetQuestDifficultyColor(UnitLevel(u) or 0)
        if color then return Hex(color.r, color.g, color.b) end
        return "|cffffffff"
    end,
    powercolor = function(u)
        local _, token = UnitPowerType(u)
        local color = token and POWER_COLORS[token] or POWER_COLORS.MANA
        return Hex(color[1], color[2], color[3])
    end,
    healthcolor = function(u)
        local ratio = HealthRatio(u)
        if ratio >= 0.5 then
            local t = (ratio - 0.5) * 2
            return Hex(0.92 + (0.25 - 0.92) * t, 0.78 + (0.82 - 0.78) * t, 0.20 + (0.30 - 0.20) * t)
        end
        local t = ratio * 2
        return Hex(0.88 + (0.92 - 0.88) * t, 0.18 + (0.78 - 0.18) * t, 0.18 + (0.20 - 0.18) * t)
    end,
}

for key, fn in pairs(EXTRA_TAGS) do TAGS[key] = fn end

PlayerUI.TAGS = TAGS

function PlayerUI:AddTag(key, fn)
    if type(key) ~= "string" or not key:match("^[%w:%-]+$") or TAGS[key] or type(fn) ~= "function" then return false end
    TAGS[key] = function(unit)
        local ok, value = pcall(fn, unit)
        return ok and tostring(value or "") or ""
    end
    return true
end

function PlayerUI:TagNames()
    local names = {}
    for key in pairs(TAGS) do names[#names + 1] = key end
    table.sort(names)
    return names
end

local function Tags(template, unit)
    return (template:gsub("%[([%w:%-]+)%]", function(key)
        local fn = TAGS[key]
        if fn then return fn(unit) end
    end))
end

PlayerUI.Tags = Tags

local function TagFor(db, unit, field)
    local store = db.units and db.units[unit]
    local own = store and store[field]
    if type(own) == "string" and own ~= "" then return own end
    local shared = db[field]
    if type(shared) == "string" and shared ~= "" then return shared end
end

local function ClassColor(unit)
    local S = NS.Styling

    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end

    if UnitIsFriend("player", unit) then
        return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
    end

    return 0.70, 0.25, 0.25
end

local function PowerColor(unit)
    local _, token = UnitPowerType(unit)
    local color = token and POWER_COLORS[token]
    if color then return color[1], color[2], color[3] end
    return POWER_COLORS.MANA[1], POWER_COLORS.MANA[2], POWER_COLORS.MANA[3]
end

local function Blend(a, b, t)
    return a + (b - a) * t
end

local function HealthColor(unit, ratio, mode)
    local S = NS.Styling

    if mode == "accent" then
        return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
    elseif mode == "dark" then
        return 0.24, 0.26, 0.32
    elseif mode == "gradient" then
        if ratio >= 0.5 then
            local t = (ratio - 0.5) * 2
            return Blend(0.92, 0.25, t), Blend(0.78, 0.82, t), Blend(0.20, 0.30, t)
        end
        local t = ratio * 2
        return Blend(0.88, 0.92, t), Blend(0.18, 0.78, t), Blend(0.18, 0.20, t)
    end

    return ClassColor(unit)
end

local function ValueText(f, health, maxHealth, mode)
    local percent = math.floor(health / maxHealth * 100) .. "%"

    if mode == "percent" then return percent end
    if mode == "value" then return Short(health) end
    if mode == "full" then return Short(health) .. " / " .. Short(maxHealth) end
    if mode == "none" then return "" end
    if mode == "deficit" then return health < maxHealth and ("-" .. Short(maxHealth - health)) or "" end
    if mode == "both" or f.big then
        return Short(health) .. "  |cffd8d8dc" .. percent .. "|r"
    end

    return percent
end

function PlayerUI:ApplyFonts(f)
    local db = Settings()
    local nameSize = (db.nameSize or 0) > 0 and db.nameSize or (f.big and 12 or 10)
    local valueSize = (db.valueSize or 0) > 0 and db.valueSize or (f.big and 12 or 10)

    if f.fontName == nameSize and f.fontValue == valueSize then return end
    f.fontName, f.fontValue = nameSize, valueSize

    NS.LSetFont(f.name, "unitframes", nameSize, "OUTLINE")
    NS.LSetFont(f.value, "unitframes", valueSize, "OUTLINE")
end

function PlayerUI:AddStyle(key, label, row)
    if type(key) ~= "string" or key == "" or FRAME_STYLES[key] or type(row) ~= "table" then return false end
    local base = (FRAME_STYLES[row.base or ""] and not self.EXTRA_STYLES[row.base]) and row.base or "classic"
    FRAME_STYLES[key] = true
    self.EXTRA_STYLES[key] = { base = base, paint = row.paint }
    table.insert(self.EXTRA_LIST, { key = key, label = label or key })
    if not self.extraHooked then
        self.extraHooked = true
        hooksecurefunc(self, "Relayout", function(_, f)
            local db = Settings()
            local extra = db and f and PlayerUI.EXTRA_STYLES[db.frameStyle]
            if extra and type(extra.paint) == "function" then pcall(extra.paint, f, db) end
        end)
    end
    return true
end

function PlayerUI:Relayout(f)
    local db = Settings()
    local store = db.units[f.unit]
    if not store then return end

    if InCombatLockdown() and not f.sample then
        self.layoutPending = true
        return
    end

    local S = NS.Styling
    local style = BaseFrameStyle(db.frameStyle)
    local height = FrameHeight(db, store)
    local near = f.mirror and "RIGHT" or "LEFT"
    local far = f.mirror and "LEFT" or "RIGHT"
    local dir = f.mirror and -1 or 1
    local showPower = db.showPower
    local powerHeight = db.powerHeight
    local bottom = showPower and (powerHeight + 3) or 2
    local lift = f.big and 6 or 0
    local tiled = style == "plates"
    local framed = style == "classic" or style == "float" or style == "glass" or style == "pixel" or style == "outline"
    local portraitOn = db.portrait ~= "off" and style ~= "slim"

    f.style = style
    f:SetSize(store.width, height)

    if style == "glass" then
        f.ground:SetVertexColor(0.06, 0.08, 0.12, 0.5)
    elseif style == "pixel" then
        f.ground:SetVertexColor(0.07, 0.07, 0.075, 0.95)
    elseif style == "dark" then
        f.ground:SetVertexColor(0, 0, 0, 0.85)
    else
        f.ground:SetVertexColor(0.016, 0.018, 0.026, style == "neon" and 0.7 or 0.92)
    end
    local Look = NS.Look
    local gr, gg, gb = Look:Color("unitframes", "bg")
    if gr then f.ground:SetVertexColor(gr, gg, gb, style == "glass" and 0.5 or (style == "neon" and 0.7 or 0.92)) end
    f.ground:SetShown(style ~= "slim" and not tiled)
    f.shadow:SetShown(style ~= "slim" and not tiled)
    f.top:SetShown(framed and style ~= "pixel" and style ~= "outline")
    ShowAll(f.edges, framed)
    local edgeSize = style == "outline" and 2 or 1
    f.edges[1]:SetHeight(edgeSize)
    f.edges[2]:SetHeight(edgeSize)
    f.edges[3]:SetWidth(edgeSize)
    f.edges[4]:SetWidth(edgeSize)
    for _, line in ipairs(f.edges) do
        if style == "glass" then
            line:SetVertexColor(S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 1)
        elseif style == "pixel" then
            line:SetVertexColor(0, 0, 0, 1)
        elseif style == "outline" then
            line:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        else
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        end
    end
    local er, eg, eb = Look:Color("unitframes", "border")
    if er then
        for _, line in ipairs(f.edges) do line:SetVertexColor(er, eg, eb, 1) end
    end
    local tr, tg, tb = Look:Color("unitframes", "text")
    if not tr then tr, tg, tb = S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3] end
    f.name:SetTextColor(tr, tg, tb)
    f.value:SetTextColor(tr, tg, tb)
    if f.powerText then f.powerText:SetTextColor(tr, tg, tb) end
    ShowAll(f.glow, style == "neon")
    ShowAll(f.barEdges, style == "slim")
    ShowAll(f.portraitEdges, style == "float" or tiled)
    f.portraitEdge:SetShown(style == "classic" or style == "glass" or style == "neon" or style == "pixel"
        or style == "dark" or style == "outline")
    for _, tile in ipairs(f.tiles) do tile:SetShown(tiled) end

    local holder, health, power = f.portraitHolder, f.health, f.power
    holder:ClearAllPoints()
    health:ClearAllPoints()
    power:ClearAllPoints()
    f.name:ClearAllPoints()
    f.value:ClearAllPoints()
    f.detail:ClearAllPoints()

    if style == "slim" then
        holder:SetSize(1, 1)
        holder:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        health:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -16)
        health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, showPower and (powerHeight + 3) or 1)
        power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -2)
        power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -2)
        power:SetPoint("BOTTOM", f, "BOTTOM", 0, 1)
        f.value:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 3)
        f.name:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, 3)
        f.name:SetPoint("BOTTOMRIGHT", f.value, "BOTTOMLEFT", -6, 0)
        f.detail:SetPoint("LEFT", health, "LEFT", 4, 0)
    elseif tiled then
        local nameHeight = f.big and 16 or 12
        local inner = portraitOn and (height + 3) or 0
        local nameTile, healthTile, powerTile = f.tiles[1], f.tiles[2], f.tiles[3]

        holder:SetSize(height, height)
        holder:SetPoint("TOP" .. near, f, "TOP" .. near, 0, 0)

        nameTile:ClearAllPoints()
        healthTile:ClearAllPoints()
        powerTile:ClearAllPoints()

        nameTile:SetPoint("TOP" .. near, f, "TOP" .. near, dir * inner, 0)
        nameTile:SetPoint("TOP" .. far, f, "TOP" .. far, 0, 0)
        nameTile:SetHeight(nameHeight)

        powerTile:SetPoint("BOTTOM" .. near, f, "BOTTOM" .. near, dir * inner, 0)
        powerTile:SetPoint("BOTTOM" .. far, f, "BOTTOM" .. far, 0, 0)
        powerTile:SetHeight(powerHeight + 2)
        powerTile:SetShown(showPower)

        healthTile:SetPoint("TOP" .. near, nameTile, "BOTTOM" .. near, 0, -3)
        healthTile:SetPoint("TOP" .. far, nameTile, "BOTTOM" .. far, 0, -3)
        if showPower then
            healthTile:SetPoint("BOTTOM", powerTile, "TOP", 0, 3)
        else
            healthTile:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
        end

        health:SetPoint("TOPLEFT", healthTile, "TOPLEFT", 1, -1)
        health:SetPoint("BOTTOMRIGHT", healthTile, "BOTTOMRIGHT", -1, 1)
        power:SetPoint("TOPLEFT", powerTile, "TOPLEFT", 1, -1)
        power:SetPoint("BOTTOMRIGHT", powerTile, "BOTTOMRIGHT", -1, 1)

        f.value:SetPoint("RIGHT", nameTile, "RIGHT", -5, 0)
        f.name:SetPoint("LEFT", nameTile, "LEFT", 5, 0)
        f.name:SetPoint("RIGHT", f.value, "LEFT", -6, 0)
        f.detail:SetPoint("LEFT", health, "LEFT", 5, 0)
    else
        local start
        if style == "float" then
            local size = height + 12
            holder:SetSize(size, size)
            holder:SetPoint(far, f, near, -dir * 4, 0)
            start = 2
        else
            local size = height - 4
            holder:SetSize(size, size)
            holder:SetPoint("TOP" .. near, f, "TOP" .. near, dir * 2, -2)
            start = portraitOn and (size + 4) or 2
        end

        health:SetPoint("TOP" .. near, f, "TOP" .. near, dir * start, -2)
        health:SetPoint("BOTTOM" .. far, f, "BOTTOM" .. far, -dir * 2, bottom)
        power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
        power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
        power:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)

        f.value:SetPoint("RIGHT", health, "RIGHT", -6, lift)
        f.name:SetPoint("LEFT", health, "LEFT", 6, lift)
        f.name:SetPoint("RIGHT", f.value, "LEFT", -6, 0)
        f.detail:SetPoint("LEFT", health, "LEFT", 6, -7)
    end

    if f.powerText then
        NS.LSetFont(f.powerText, "unitframes", NS.FS(powerHeight >= 10 and 9 or 8), "OUTLINE")
    end
end

function PlayerUI:SetLook(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value

    for _, f in pairs(frames) do
        if field == "powerHeight" or field == "showPower" or field == "frameStyle" then self:Relayout(f) end
        self:ApplyFonts(f)
    end

    self:UpdateAll()
end

local function BuildBody(f, unit, db, store, preset)
    local S = NS.Styling

    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.92)

    local edges = S.CreateEdges(f, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    local shadow = S.CreateSoftShadow(f, 6, 0.55)
    local glow = CreateGlow(f)

    local tiles = {}
    for index = 1, 3 do
        local tile = CreateFrame("Frame", nil, f)
        tile:SetFrameLevel(f:GetFrameLevel())

        local tileGround = tile:CreateTexture(nil, "BACKGROUND")
        tileGround:SetAllPoints(tile)
        tileGround:SetTexture(WHITE)
        tileGround:SetVertexColor(0.016, 0.018, 0.026, 0.92)

        S.CreateEdges(tile, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        tile:Hide()
        tiles[index] = tile
    end

    local mirror = preset.mirror
    local portraitSize = FrameHeight(db, store) - 4

    local portraitHolder = CreateFrame("Frame", nil, f)
    portraitHolder:SetSize(portraitSize, portraitSize)

    if mirror then
        portraitHolder:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    else
        portraitHolder:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    end

    local portraitBase = portraitHolder:CreateTexture(nil, "BACKGROUND")
    portraitBase:SetAllPoints(portraitHolder)
    portraitBase:SetTexture(WHITE)
    portraitBase:SetVertexColor(0.04, 0.045, 0.06, 1)

    local portraitEdges = S.CreateEdges(portraitHolder, "OVERLAY", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.8)
    ShowAll(portraitEdges, false)

    local portrait = portraitHolder:CreateTexture(nil, "BORDER")
    portrait:SetPoint("TOPLEFT", portraitHolder, "TOPLEFT", 1, -1)
    portrait:SetPoint("BOTTOMRIGHT", portraitHolder, "BOTTOMRIGHT", -1, 1)
    portrait:SetTexCoord(0.14, 0.86, 0.14, 0.86)

    local model = CreateFrame("PlayerModel", nil, portraitHolder)
    model:SetPoint("TOPLEFT", portraitHolder, "TOPLEFT", 1, -1)
    model:SetPoint("BOTTOMRIGHT", portraitHolder, "BOTTOMRIGHT", -1, 1)
    model:SetScript("OnShow", function(self)
        if self.unit and self.visible and UnitExists(self.unit) then
            pcall(self.SetUnit, self, self.unit)
        end
        pcall(self.SetCamera, self, 0)
    end)
    model:SetScript("OnHide", function(self) self.guid = nil end)
    model:Hide()

    local portraitEdge = portraitHolder:CreateTexture(nil, "OVERLAY")
    portraitEdge:SetWidth(1)
    if mirror then
        portraitEdge:SetPoint("TOPLEFT", portraitHolder, "TOPLEFT", 0, 0)
        portraitEdge:SetPoint("BOTTOMLEFT", portraitHolder, "BOTTOMLEFT", 0, 0)
    else
        portraitEdge:SetPoint("TOPRIGHT", portraitHolder, "TOPRIGHT", 0, 0)
        portraitEdge:SetPoint("BOTTOMRIGHT", portraitHolder, "BOTTOMRIGHT", 0, 0)
    end
    portraitEdge:SetTexture(WHITE)
    portraitEdge:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    local portraitShade = portraitHolder:CreateTexture(nil, "ARTWORK")
    portraitShade:SetPoint("TOPLEFT", portraitHolder, "TOPLEFT", 1, -1)
    portraitShade:SetPoint("BOTTOMRIGHT", portraitHolder, "BOTTOMRIGHT", -1, 1)
    portraitShade:SetTexture(WHITE)
    portraitShade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.45, 0, 0, 0, 0)

    local health = CreateFrame("StatusBar", nil, f)
    if mirror then
        health:SetPoint("TOPRIGHT", portraitHolder, "TOPLEFT", -2, 0)
        health:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, db.showPower and (db.powerHeight + 3) or 2)
    else
        health:SetPoint("TOPLEFT", portraitHolder, "TOPRIGHT", 2, 0)
        health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, db.showPower and (db.powerHeight + 3) or 2)
    end
    NS.Look:SetBar(health, "unitframes", WHITE)
    health:SetMinMaxValues(0, 1)

    local barFrame = CreateFrame("Frame", nil, f)
    barFrame:SetPoint("TOPLEFT", health, "TOPLEFT", -1, 1)
    barFrame:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 1, -1)
    barFrame:SetFrameLevel(f:GetFrameLevel() + 3)
    local barEdges = S.CreateEdges(barFrame, "OVERLAY", 0, 0, 0, 1)
    ShowAll(barEdges, false)

    local deficit = health:CreateTexture(nil, "BACKGROUND")
    deficit:SetAllPoints(health)
    deficit:SetTexture(WHITE)
    deficit:SetVertexColor(0.055, 0.060, 0.080, 0.95)

    local sheen = health:CreateTexture(nil, "ARTWORK")
    sheen:SetAllPoints(health)
    sheen:SetTexture(WHITE)
    sheen:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.45, 1, 1, 1, 0.10)

    local gloss = health:CreateTexture(nil, "ARTWORK")
    gloss:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
    gloss:SetPoint("TOPRIGHT", health, "TOPRIGHT", 0, 0)
    gloss:SetHeight(1)
    gloss:SetTexture(WHITE)
    gloss:SetVertexColor(1, 1, 1, 0.14)

    local predict = NS.HealPrediction and NS.HealPrediction:Attach(health)

    local power = CreateFrame("StatusBar", nil, f)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
    power:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)
    NS.Look:SetBar(power, "unitframes", WHITE)
    power:SetMinMaxValues(0, 1)
    power:SetShown(db.showPower)

    local powerBase = power:CreateTexture(nil, "BACKGROUND")
    powerBase:SetAllPoints(power)
    powerBase:SetTexture(WHITE)
    powerBase:SetVertexColor(0.04, 0.045, 0.06, 0.95)

    local powerSheen = power:CreateTexture(nil, "ARTWORK")
    powerSheen:SetAllPoints(power)
    powerSheen:SetTexture(WHITE)
    powerSheen:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, 1, 1, 1, 0.08)

    local overlay = CreateFrame("Frame", nil, f)
    overlay:SetAllPoints(f)
    overlay:SetFrameLevel(f:GetFrameLevel() + 4)

    local top = overlay:CreateTexture(nil, "OVERLAY")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    top:SetTexture(WHITE)
    if mirror then
        top:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0,
            S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.85)
    else
        top:SetGradientAlpha("HORIZONTAL",
            S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.85,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
    end

    local big = store.height >= 36

    local value = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(value, "unitframes", NS.FS(big and 12 or 10), "OUTLINE")
    value:SetPoint("RIGHT", health, "RIGHT", -6, big and 6 or 0)
    value:SetJustifyH("RIGHT")
    value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    local name = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(name, "unitframes", NS.FS(big and 12 or 10), "OUTLINE")
    name:SetPoint("LEFT", health, "LEFT", 6, big and 6 or 0)
    name:SetPoint("RIGHT", value, "LEFT", -6, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    local powerText = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(powerText, "unitframes", NS.FS(db.powerHeight >= 10 and 9 or 8), "OUTLINE")
    powerText:SetPoint("RIGHT", power, "RIGHT", -4, 0)
    powerText:SetJustifyH("RIGHT")
    powerText:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    local detail = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(detail, "unitframes", NS.FS(10), "OUTLINE")
    detail:SetPoint("LEFT", health, "LEFT", 6, -7)
    detail:SetJustifyH("LEFT")
    detail:SetTextColor(0.80, 0.80, 0.84)
    detail:SetShown(big)

    local tag = overlay:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(tag, "unitframes", NS.FS(12), "")
    tag:SetPoint("CENTER", f, "CENTER", 0, 0)
    tag:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    tag:SetText(L[preset.label])
    tag:Hide()

    local grip = overlay:CreateTexture(nil, "OVERLAY")
    grip:SetAllPoints(f)
    grip:SetTexture(WHITE)
    grip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
    grip:Hide()

    if AURA_UNITS[unit] then
        local auras = CreateFrame("Frame", nil, f)
        auras:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 6)
        auras:SetSize(store.width, store.auraSize or db.auraSize)

        local auraElapsed = 0

        auras:SetScript("OnUpdate", function(self, step)
            auraElapsed = auraElapsed + step
            if auraElapsed < 0.1 then return end
            auraElapsed = 0
            PlayerUI:TickAuras(f)
        end)

        auras:SetScript("OnHide", function()
            if f.hoverAura then
                f.hoverAura = nil
                GameTooltip:Hide()
            end
        end)

        f.auras = auras
        f.auraIcons = {}
    end

    f.overlay = overlay
    f.deficit = deficit
    f.ground, f.edges, f.shadow, f.glow, f.top = ground, edges, shadow, glow, top
    f.tiles, f.barEdges, f.portraitEdges, f.portraitEdge = tiles, barEdges, portraitEdges, portraitEdge
    f.big = big
    f.mirror = mirror
    f.unit = f.unit or unit
    f.portraitHolder = portraitHolder
    f.portrait = portrait
    f.model = model
    f.health = health
    f.predict = predict
    f.power = power
    f.name = name
    f.value = value
    f.powerText = powerText
    f.detail = detail
    f.tag = tag
    f.grip = grip
end

function PlayerUI:Build(unit)
    if frames[unit] then return frames[unit] end
    if InCombatLockdown() then return end

    local db = Settings()
    if not db then return end

    local store = db.units[unit]
    local preset = LAYOUT[unit]
    local S = NS.Styling

    local f = CreateFrame("Button", "NarciSirus_Unit_" .. unit, UIParent, "SecureUnitButtonTemplate")
    f:SetSize(store.width, FrameHeight(db, store))
    f:SetPoint(store.point, UIParent, store.point, store.x, store.y)
    f:SetFrameStrata("LOW")
    f:SetScale(db.scale)
    f:SetMovable(true)
    f:RegisterForClicks("AnyUp")
    f:SetAttribute("unit", unit)
    f:SetAttribute("type1", "target")
    f:SetAttribute("type2", "togglemenu")
    f.unit = unit

    BuildBody(f, unit, db, store, preset)

    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function(self)
        if not moving then return end
        self:StartMoving()
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, _, x, y = self:GetPoint()
        local settings = Settings()
        local unitStore = settings.units[self.unit]
        unitStore.point, unitStore.x, unitStore.y = point, x, y
    end)

    f:SetScript("OnEnter", function(self)
        if moving then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnit(self.unit)
        GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    f.narciForceShow = true

    if NS.Movers then
        NS.Movers:Register(f, L[preset.label], function(point, _, x, y)
            local settings = Settings()
            local unitStore = settings.units[unit]
            unitStore.point, unitStore.x, unitStore.y = point, x, y
        end, "units")
    end

    frames[unit] = f
    self:Relayout(f)

    if type(RegisterUnitWatch) == "function" and not InCombatLockdown() then
        RegisterUnitWatch(f)
    end

    return f
end

function PlayerUI:CreateSample(parent, opts)
    local db = Settings()
    if not db then return end
    local unit = opts and opts.unit or "player"
    local store = db.units[unit]
    local preset = LAYOUT[unit]
    if not store or not preset then return end
    local f = CreateFrame("Frame", nil, parent)
    f.unit = unit
    f.sample = true
    BuildBody(f, unit, db, store, preset)
    if f.auras then f.auras:SetScript("OnUpdate", nil) end
    return f
end

function PlayerUI:PaintSample(f)
    local db = Settings()
    if not db or not f then return end
    local store = db.units[f.unit]
    f.fontName = nil
    self:Relayout(f)
    f:SetScale(math.min(1.4, 280 / math.max(store.width or 200, 1)))
    self:UpdateUnit("player", f)
end

function PlayerUI:ApplyWatch(unit)
    local f = frames[unit]
    if not f then return end

    if InCombatLockdown() then
        self.watchPending = true
        return
    end

    local db = Settings()
    local store = db and db.units[unit]
    local wanted = store and store.enabled ~= false and Enabled() and not self.suspended

    if wanted then
        if not UnitWatchRegistered(f) then RegisterUnitWatch(f) end
        return
    end

    if UnitWatchRegistered(f) then UnregisterUnitWatch(f) end
    f:Hide()
end

function PlayerUI:Suspend()
    if self.suspended then return end
    self.suspended = true

    for _, f in pairs(frames) do
        f:SetAlpha(0)
    end

    if InCombatLockdown() then
        self.watchPending = true
        return
    end

    self:ApplyWatchAll()
end

function PlayerUI:Resume()
    if not self.suspended then return end
    self.suspended = nil

    local db = Settings()

    for unit, f in pairs(frames) do
        local store = db and db.units[unit]
        f:SetAlpha(store and store.alpha or 1)
    end

    if InCombatLockdown() then
        self.watchPending = true
        return
    end

    self:ApplyWatchAll()
    self:UpdateAll()
end

function PlayerUI:ApplyWatchAll()
    self.watchPending = nil

    for _, unit in ipairs(ORDER) do
        self:ApplyWatch(unit)
    end
end

function PlayerUI:UpdateBars(unit, frame)
    local f = frame or frames[unit]
    if not f then return end

    local db = Settings()

    if not f.sample and (not UnitExists(unit) or not db.units[unit].enabled) then return end

    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    if maxHealth <= 0 then maxHealth = 1 end

    f.health:SetMinMaxValues(0, maxHealth)
    f.health:SetValue(health)
    self:ApplyFonts(f)

    local r, g, b = HealthColor(unit, health / maxHealth, db.healthColor)
    local cr, cg, cb = NS.Look:Color("unitframes", "bar")
    if cr then r, g, b = cr, cg, cb end
    if f.style == "neon" then
        f.health:GetStatusBarTexture():SetGradientAlpha("HORIZONTAL", r * 0.3, g * 0.3, b * 0.3, 1, r, g, b, 1)
        f.deficit:SetVertexColor(0.17, 0.03, 0.045, 0.85)
        PaintGlow(f.glow, r, g, b, 0.35)
    elseif f.style == "glass" then
        f.health:SetStatusBarColor(r, g, b, 0.6)
        f.deficit:SetVertexColor(0.05, 0.06, 0.09, 0.35)
    else
        f.health:SetStatusBarColor(r * 0.82, g * 0.82, b * 0.82, 1)
        f.deficit:SetVertexColor(r * 0.16 + 0.03, g * 0.16 + 0.03, b * 0.16 + 0.04, 0.95)
    end

    self:UpdatePrediction(f, unit, health, maxHealth)

    local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
    if maxPower <= 0 then maxPower = 1 end

    f.power:SetMinMaxValues(0, maxPower)
    f.power:SetValue(power)
    local pr, pg, pb = NS.Look:Color("unitframes", "power")
    if pr then
        f.power:SetStatusBarColor(pr, pg, pb)
    else
        f.power:SetStatusBarColor(PowerColor(unit))
    end
    f.power:SetShown(db.showPower and UnitPowerMax(unit) > 0)

    if f.powerText then
        if db.showPower and UnitPowerMax(unit) > 0 then
            local mode = db.powerFormat or "full"
            local powerTag = TagFor(db, unit, "tagPower")
            if powerTag then
                f.powerText:SetText(Tags(powerTag, unit))
                mode = "tag"
            elseif mode == "current" then
                f.powerText:SetText(Short(power))
            elseif mode == "percent" then
                f.powerText:SetText(math.floor(power / maxPower * 100) .. "%")
            else
                f.powerText:SetText(Short(power) .. " / " .. Short(maxPower))
            end
            f.powerText:SetShown(mode ~= "none")
        else
            f.powerText:Hide()
        end
    end

    local valueTag = TagFor(db, unit, "tagValue")
    if valueTag then
        f.value:SetText(Tags(valueTag, unit))
    elseif UnitIsDeadOrGhost(unit) then
        f.value:SetText(L["мёртв"])
    else
        f.value:SetText(ValueText(f, health, maxHealth, db.textFormat))
    end

    return f
end

function PlayerUI:UpdatePrediction(f, unit, health, maxHealth)
    local HP = NS.HealPrediction
    if not HP or not f.predict then return end
    if not Settings().healPrediction or not UnitExists(unit) then
        HP:Clear(f.predict)
        return
    end
    if not health then
        health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    end
    HP:Paint(f.predict, unit, health, maxHealth, false)
end

function PlayerUI:UpdateUnit(unit, frame)
    local f = self:UpdateBars(unit, frame)
    if not f then return end

    local db = Settings()
    local name = UnitName(unit) or ""
    local limit = db.nameLength or 0
    if limit > 0 then
        local count, cut = 0, nil
        for position in name:gmatch("()[%z\1-\127\194-\244][\128-\191]*") do
            count = count + 1
            if count > limit then cut = position break end
        end
        if cut then name = name:sub(1, cut - 1) .. ".." end
    end
    local nameTag = TagFor(db, unit, "tagName")
    if nameTag then name = Tags(nameTag, unit) end
    f.name:SetText(name)
    if db.nameColor == "class" then
        local r, g, b
        if UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            if color then r, g, b = color.r, color.g, color.b end
        else
            local reaction = UnitReaction(unit, "player")
            local color = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
            if color then r, g, b = color.r, color.g, color.b end
        end
        if r then f.name:SetTextColor(r, g, b) end
        f.narciNameTinted = true
    elseif f.narciNameTinted then
        f.narciNameTinted = nil
        local tr, tg, tb = NS.Look:Color("unitframes", "text")
        if not tr then
            local S = NS.Styling
            tr, tg, tb = S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]
        end
        f.name:SetTextColor(tr, tg, tb)
    end

    self:UpdatePortrait(f, unit)
    self:UpdateAuras(f, unit)

    local detailTag = TagFor(db, unit, "tagDetail")
    if f.detail:IsShown() and detailTag then
        f.detail:SetText(Tags(detailTag, unit))
    elseif f.detail:IsShown() then
        local level = UnitLevel(unit)
        local classification = UnitClassification(unit)
        local text = (level and level > 0) and tostring(level) or "??"

        if classification == "elite" or classification == "rareelite" then
            text = text .. "+"
        end

        if UnitIsPlayer(unit) then
            text = text .. " " .. (UnitClass(unit) or "")
        else
            text = text .. " " .. (UnitCreatureType(unit) or "")
        end

        f.detail:SetText(text)
    end
end

function PlayerUI:BuildAura(f)
    local S = NS.Styling
    local db = Settings()

    local icon = CreateFrame("Frame", nil, f.auras)
    icon:SetSize(db.auraSize, db.auraSize)
    icon:EnableMouse(true)
    icon.auraOwner = f

    local base = icon:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints(icon)
    base:SetTexture(WHITE)
    base:SetVertexColor(0.02, 0.022, 0.03, 1)

    local texture = icon:CreateTexture(nil, "BORDER")
    texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local edges = {}

    for index = 1, 4 do
        local line = icon:CreateTexture(nil, "OVERLAY")
        line:SetTexture(WHITE)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", icon, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", icon, "TOPRIGHT")
    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT")
    edges[2]:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", icon, "TOPLEFT")
    edges[3]:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT")
    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", icon, "TOPRIGHT")
    edges[4]:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")

    local count = icon:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(count, "unitframes", NS.FS(10), "OUTLINE")
    count:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, -1)
    count:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])

    local timer = icon:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(timer, "unitframes", NS.FS(10), "OUTLINE")
    timer:SetPoint("BOTTOM", icon, "BOTTOM", 0, 1)
    timer:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    icon.texture = texture
    icon.edges = edges
    icon.count = count
    icon.timer = timer

    icon:SetScript("OnEnter", function(self)
        if not self.unit or not self.index then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitAura(self.unit, self.index, self.filter)
        GameTooltip:Show()
        local owner = self.auraOwner
        if owner then owner.hoverAura = self end
    end)

    icon:SetScript("OnLeave", function(self)
        local owner = self.auraOwner
        if owner and owner.hoverAura == self then owner.hoverAura = nil end
        GameTooltip:Hide()
    end)

    return icon
end

local function TimeText(seconds)
    if seconds >= 3600 then return math.floor(seconds / 3600 + 0.5) .. "ч" end
    if seconds >= 60 then return math.floor(seconds / 60 + 0.5) .. "м" end
    if seconds >= 10 then return math.floor(seconds) .. "" end
    return string.format("%.1f", seconds)
end

function PlayerUI:TickAuras(f)
    if not f.auraIcons then return end

    local now = GetTime()

    for index = 1, #f.auraIcons do
        local icon = f.auraIcons[index]

        if icon:IsShown() and icon.expires then
            local left = icon.expires - now

            if left > 0 then
                icon.timer:SetText(TimeText(left))

                if left <= 5 then
                    icon.timer:SetTextColor(0.95, 0.35, 0.35)
                else
                    local S = NS.Styling
                    icon.timer:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                end
            else
                icon.timer:SetText("")
            end
        end
    end
end

function PlayerUI:UpdateAuras(f, unit)
    if not f.auras then return end

    local db = Settings()
    if not db then return end
    local S = NS.Styling
    local store = db.units[unit] or {}

    local buffsOn, debuffsOn = self:AuraShown(unit, db)

    if (not buffsOn and not debuffsOn) or not UnitExists(unit) then
        if f.hoverAura then
            f.hoverAura = nil
            GameTooltip:Hide()
        end
        f.auras:Hide()
        return
    end

    f.auras:Show()

    local perRow = store.auraPerRow or db.auraPerRow
    local shown = 0

    local function Place(filter, hostile, size, baseY)
        local placed = 0

        local F = NS.AuraFilters
        local prefix = hostile and "auraDebuff" or "auraBuff"
        local longest = (db.auraMaxDuration or 0) * 60

        for index = 1, 40 do
            local name, _, texture, count, debuffType, duration, expires, caster =
                UnitAura(unit, index, filter)
            if not name then break end

            local pass = not F or F.Allowed(name, caster, db, prefix)
            if pass and longest > 0 and (not duration or duration == 0 or duration > longest) then pass = false end

            if pass then
                placed = placed + 1
                if placed > perRow then break end

                shown = shown + 1

                local icon = f.auraIcons[shown]
                if not icon then
                    icon = self:BuildAura(f)
                    f.auraIcons[shown] = icon
                end

                icon:ClearAllPoints()
                icon:SetSize(size, size)
                icon:SetPoint("BOTTOMLEFT", f.auras, "BOTTOMLEFT",
                    (placed - 1) * (size + 2), baseY)

                icon.texture:SetTexture(texture)
                icon.count:SetText(count and count > 1 and count or "")

                icon.expires = (duration and duration > 0 and expires and expires > 0) and expires or nil
                icon.timer:SetText("")

                icon.unit, icon.index, icon.filter = unit, index, filter
                if f.hoverAura == icon then
                    GameTooltip:SetUnitAura(unit, index, filter)
                end

                local color = hostile and (DEBUFF_COLORS[debuffType] or DEBUFF_DEFAULT) or S.BORDER
                if hostile and db.auraMineHighlight ~= false and (caster == "player" or caster == "pet") then
                    color = S.ACCENT_GLOW
                end

                for _, line in ipairs(icon.edges) do
                    line:SetVertexColor(color[1], color[2], color[3], 0.95)
                end

                icon:Show()
            end
        end

        return placed
    end

    local debuffSize = store.auraDebuffSize or db.auraDebuffSize
    local buffSize = store.auraSize or db.auraSize

    local debuffs = debuffsOn and Place("HARMFUL", true, debuffSize, 0) or 0
    local buffY = debuffs > 0 and (debuffSize + 3) or 0

    local buffs = buffsOn and Place("HELPFUL", false, buffSize, buffY) or 0

    for index = shown + 1, #f.auraIcons do
        local icon = f.auraIcons[index]
        if f.hoverAura == icon then
            f.hoverAura = nil
            GameTooltip:Hide()
        end
        icon:Hide()
        icon.expires = nil
    end

    local height = buffY + (buffs > 0 and buffSize or 0)
    if height < 1 then height = 1 end
    f.auras:SetHeight(height)

    self:TickAuras(f)
end

local function FreezeModel(self)
    pcall(self.SetSequenceTime, self, 0, 0)
end

function PlayerUI:UpdatePortrait(f, unit)
    local db = Settings()
    if not db or not f.portraitHolder then return end

    local style = db.portrait

    if style == "off" or BaseFrameStyle(db.frameStyle) == "slim" then
        f.portraitHolder:Hide()
        return
    end

    f.portraitHolder:Show()

    local still = style == "2D" and unit == "player"
    if (style == "3D" or still) and f.model and MODEL_UNITS[unit] then
        local model = f.model
        local guid = UnitGUID(unit)
        local visible = UnitIsVisible(unit) and UnitIsConnected(unit)

        if model.guid == guid and model.visible == visible and model:IsShown() then
            f.portrait:Hide()
            return
        end

        model.guid = guid
        model.visible = visible
        model.unit = unit
        model.animStarted = nil
        model.still = still and model.SetSequenceTime and true or nil

        f.portrait:Hide()
        model:Show()

        local ok, err = pcall(function()
            if visible then
                model:ClearModel()
                model:SetModelScale(1)
                model:SetPosition(0, 0, 0)
                model:SetUnit(unit)
                model:SetCamera(0)
            else
                model:SetModelScale(4.25)
                model:SetPosition(0, 0, -1.5)
                model:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
            end
        end)

        if ok then
            if visible then
                model.waited, model.tries, model.loadedFor = 0, 0, nil
                model:SetScript("OnUpdate", function(self, elapsed)
                    if self.guid ~= guid or UnitGUID(unit) ~= guid then
                        self:SetScript("OnUpdate", nil)
                        return
                    end

                    if type(self:GetModel()) == "string" then
                        self.loadedFor = (self.loadedFor or 0) + elapsed
                        if self.still then
                            FreezeModel(self)
                            if self.loadedFor >= 1.5 then self:SetScript("OnUpdate", FreezeModel) end
                            return
                        end
                        if not self.animStarted and self.loadedFor >= 0.3 then
                            self.animStarted = true
                            pcall(self.SetSequence, self, 0)
                        elseif self.loadedFor >= 1.5 then
                            pcall(self.SetSequence, self, 0)
                            self:SetScript("OnUpdate", nil)
                        end
                        return
                    end

                    self.waited = self.waited + elapsed
                    if self.waited < 0.5 then return end
                    self.waited = 0
                    self.tries = self.tries + 1

                    pcall(self.SetUnit, self, unit)
                    pcall(self.SetCamera, self, 0)

                    if self.tries >= 40 then self:SetScript("OnUpdate", nil) end
                end)
            else
                model:SetScript("OnUpdate", nil)
            end
            return
        end

        model.lastError = err
        model.guid = nil
        model:Hide()
    end

    if f.model then f.model:Hide() end
    f.portrait:Show()

    local guid = UnitGUID(unit)
    if f.portraitGUID == guid then return end
    f.portraitGUID = guid

    if type(SetPortraitTexture) == "function" then
        pcall(SetPortraitTexture, f.portrait, unit)

        if NS.After then
            for _, delay in ipairs({ 0.5, 1.5, 3, 6, 10 }) do
                NS.After(delay, function()
                    if f.portraitGUID == guid and UnitGUID(unit) == guid then
                        pcall(SetPortraitTexture, f.portrait, unit)
                    end
                end)
            end
        end
    end
end

function PlayerUI:DiagnosePortraits()
    local db = Settings()
    NS.Print("portrait: style=" .. tostring(db and db.portrait) .. " frameStyle=" .. tostring(db and db.frameStyle)
        .. " enabled=" .. tostring(Enabled()))

    for _, unit in ipairs({ "player", "target" }) do
        local f = frames[unit]
        if not f then
            NS.Print(unit .. ": no frame")
        else
            local model = f.model
            NS.Print(string.format("%s: exists=%s holder=%s tex=%s model=%s/%s file=%s guid=%s visible=%s tries=%s err=%s",
                unit,
                tostring(UnitExists(unit)),
                tostring(f.portraitHolder and f.portraitHolder:IsVisible()),
                tostring(f.portrait and f.portrait:IsShown()),
                tostring(model and model:IsShown()), tostring(model and model:IsVisible()),
                tostring(model and model.GetModel and model:GetModel()),
                tostring(model and model.guid and "set" or "nil"),
                tostring(model and model.visible),
                tostring(model and model.tries),
                tostring(model and model.lastError)))
            if f.portrait then
                local before = f.portrait:GetTexture()
                local ok, err = true, nil
                if UnitExists(unit) and type(SetPortraitTexture) == "function" then
                    ok, err = pcall(SetPortraitTexture, f.portrait, unit)
                end
                NS.Print(string.format("%s 2D: before=%s after=%s ok=%s err=%s mounted=%s vehicle=%s alpha=%.2f size=%dx%d",
                    unit, tostring(before), tostring(f.portrait:GetTexture()), tostring(ok), tostring(err),
                    tostring(IsMounted() and true or false), tostring(UnitHasVehicleUI and UnitHasVehicleUI(unit) and true or false),
                    f.portrait:GetAlpha() or -1, f.portrait:GetWidth() or 0, f.portrait:GetHeight() or 0))
            end
        end
    end
end

local PORTRAIT_TESTS = {
    { "SetUnit", function(m, u) m:SetUnit(u) end },
    { "RefreshUnit", function(m) m:RefreshUnit() end },
    { "SetCamera(0)", function(m) m:SetCamera(0) end },
    { "SetCamera(1)", function(m) m:SetCamera(1) end },
    { "SetSequence(0)", function(m) m:SetSequence(0) end },
    { "SetSequence(3)", function(m) m:SetSequence(3) end },
    { "Hide + Show", function(m) m:Hide() m:Show() end },
    { "ClearModel + SetUnit + SetCamera(0)", function(m, u) m:ClearModel() m:SetUnit(u) m:SetCamera(0) end },
    { "SetUnit + SetCamera(0) + SetSequence(0)", function(m, u) m:SetUnit(u) m:SetCamera(0) m:SetSequence(0) end },
    { "SetModel(file) + SetCamera(0)", function(m) local file = m:GetModel() if type(file) == "string" then m:SetModel(file) end m:SetCamera(0) end },
}

function PlayerUI:TestFreshModel(unit, camera)
    local box = self.testBox
    if not box then
        box = CreateFrame("Button", nil, UIParent)
        box:SetSize(160, 160)
        box:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        box:SetFrameStrata("DIALOG")
        local ground = box:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(box)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(0, 0, 0, 0.8)
        box.label = box:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(box.label, "unitframes", 11, "OUTLINE")
        box.label:SetPoint("TOP", box, "BOTTOM", 0, -4)
        box:SetScript("OnClick", function(self) self:Hide() end)
        self.testBox = box
    end

    if box.model then box.model:Hide() end
    local model = CreateFrame("PlayerModel", nil, box)
    model:SetAllPoints(box)
    box.model = model
    box:Show()

    local ok, err = pcall(function()
        model:SetUnit(unit)
        if camera then model:SetCamera(0) end
    end)

    box.label:SetText(unit .. (camera and ", camera 0" or ", full") .. " - click to close")
    NS.Print("fresh model " .. unit .. (ok and " - ok" or (" - error: " .. tostring(err))))
end

function PlayerUI:TestPortrait(index)
    if index == 11 then return self:TestFreshModel("player", true) end
    if index == 12 then return self:TestFreshModel("player", false) end
    if index == 13 then return self:TestFreshModel("target", true) end

    local test = PORTRAIT_TESTS[index]
    if not test then
        for i, entry in ipairs(PORTRAIT_TESTS) do NS.Print("/narci portrait " .. i .. " - " .. entry[1]) end
        return
    end

    for _, unit in ipairs({ "player", "target" }) do
        local f = frames[unit]
        local model = f and f.model
        if model and model:IsVisible() then
            local ok, err = pcall(test[2], model, unit)
            NS.Print(unit .. ": " .. test[1] .. (ok and " - ok" or (" - error: " .. tostring(err))))
        end
    end
end

function PlayerUI:RefreshPortraits()
    for unit, f in pairs(frames) do
        f.portraitGUID = nil
        if f.model then f.model.guid = nil end
        if UnitExists(unit) then self:UpdatePortrait(f, unit) end
    end
end

function PlayerUI:SetPortraitStyle(style)
    local db = Settings()
    if not db then return end

    db.portrait = style
    for _, f in pairs(frames) do self:Relayout(f) end
    self:RefreshPortraits()
end

function PlayerUI:UpdateAll()
    for _, unit in ipairs(ORDER) do
        self:UpdateUnit(unit)
    end
end

local stockParking

local function Park(frame)
    if not frame or frame.narciParked then return end
    frame.narciParked = true
    if not stockParking then
        stockParking = CreateFrame("Frame")
        stockParking:Hide()
    end
    pcall(UnregisterUnitWatch, frame)
    frame:UnregisterAllEvents()
    frame:SetParent(stockParking)
end

function PlayerUI:HideGroupStock()
    local db = Settings()
    if not db or not db.hideBlizzard or InCombatLockdown() then return end
    if db.units.boss1 and db.units.boss1.enabled ~= false then
        for index = 1, 4 do Park(_G["Boss" .. index .. "TargetFrame"]) end
    end
    if db.units.arena1 and db.units.arena1.enabled ~= false then
        Park(_G.ArenaEnemyFrames)
        for index = 1, 5 do Park(_G["ArenaEnemyFrame" .. index]) end
    end
end

function PlayerUI:HideBlizzard()
    local db = Settings()
    if not db or not db.hideBlizzard or InCombatLockdown() then return end
    self:HideGroupStock()

    for _, name in ipairs({ "PlayerFrame", "TargetFrame", "TargetFrameToT", "PetFrame", "FocusFrame" }) do
        local frame = _G[name]

        if frame and not frame.narciSilenced then
            frame.narciSilenced = true
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", function(self) self:Hide() end)
        end
    end
end

local RUNE_ORDER = { 1, 2, 5, 6, 3, 4 }
local RUNE_COLORS = {
    [1] = { 0.90, 0.22, 0.22 },
    [2] = { 0.30, 0.80, 0.25 },
    [3] = { 0.25, 0.62, 1.00 },
    [4] = { 0.72, 0.38, 0.95 },
}
local TOTEM_COLORS = {
    { 1.00, 0.45, 0.15 },
    { 0.70, 0.52, 0.28 },
    { 0.30, 0.65, 1.00 },
    { 0.70, 0.85, 1.00 },
}

local CLASS_POWER_SHAPES = {
    orbs = { fill = "RoundFill", ring = "PortraitRing", ringScale = 1.12 },
    hex = { fill = "HexFill", ring = "HexRing", ringScale = 1 },
    diamond = { fill = "ShapeDiamondFill", ring = "ShapeDiamondRing", ringScale = 1 },
}
PlayerUI.CLASS_POWER_SHAPES = CLASS_POWER_SHAPES

local function ClassPowerKind()
    local _, class = UnitClass("player")
    if class == "ROGUE" or class == "DRUID" then return "combo", 5 end
    if class == "DEATHKNIGHT" then return "runes", 6 end
    if class == "SHAMAN" then return "totems", 4 end
end

function PlayerUI:BuildClassPower()
    local db = Settings()
    local player = frames.player
    if not db or db.classPower == false or not player then return end
    local kind, count = ClassPowerKind()
    if not kind then return end
    if self.classPower then return self.classPower end

    local S = NS.Styling
    local bar = CreateFrame("Frame", "NarciSirus_ClassPower", player)
    bar:SetFrameLevel(player:GetFrameLevel() + 2)
    bar.kind, bar.count, bar.segments = kind, count, {}

    for index = 1, count do
        local seg = CreateFrame("Frame", nil, bar)
        local fill = CreateFrame("StatusBar", nil, seg)
        fill:SetPoint("TOPLEFT", seg, "TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", -1, 1)
        fill:SetMinMaxValues(0, 1)
        if NS.Look and NS.Look.SetBar then NS.Look:SetBar(fill, "unitframes") else fill:SetStatusBarTexture(WHITE) end
        seg.fill, seg.barFill = fill, fill
        if kind ~= "totems" then
            local glow = seg:CreateTexture(nil, "BACKGROUND")
            glow:SetTexture(S.GLOW)
            glow:SetBlendMode("ADD")
            glow:SetPoint("CENTER", seg, "CENTER", 0, 0)
            glow:Hide()
            local shapeGround = seg:CreateTexture(nil, "BORDER")
            shapeGround:SetAllPoints(seg)
            shapeGround:Hide()
            local orb = CreateFrame("StatusBar", nil, seg)
            orb:SetAllPoints(seg)
            orb:SetMinMaxValues(0, 1)
            orb:SetOrientation("VERTICAL")
            orb:Hide()
            local top = CreateFrame("Frame", nil, seg)
            top:SetAllPoints(seg)
            top:SetFrameLevel(orb:GetFrameLevel() + 1)
            local ring = top:CreateTexture(nil, "OVERLAY")
            ring:SetPoint("CENTER", seg, "CENTER", 0, 0)
            ring:Hide()
            seg.shapeGlow, seg.shapeGround, seg.orbFill, seg.shapeRing = glow, shapeGround, orb, ring
        end
        if kind == "totems" then
            local icon = seg:CreateTexture(nil, "ARTWORK")
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            seg.icon = icon
            local time = fill:CreateFontString(nil, "OVERLAY")
            NS.LSetFont(time, "unitframes", NS.FS(9), "OUTLINE")
            time:SetPoint("CENTER", fill, "CENTER", 0, 0)
            seg.time = time
        end
        bar.segments[index] = seg
    end

    bar:SetScript("OnEvent", function() PlayerUI:UpdateClassPower() end)
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    if kind == "combo" then
        bar:RegisterEvent("UNIT_COMBO_POINTS")
        bar:RegisterEvent("PLAYER_TARGET_CHANGED")
        bar:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    elseif kind == "runes" then
        bar:RegisterEvent("RUNE_POWER_UPDATE")
        bar:RegisterEvent("RUNE_TYPE_UPDATE")
    else
        bar:RegisterEvent("PLAYER_TOTEM_UPDATE")
    end
    local elapsedTotal = 0
    local ticker = CreateFrame("Frame", nil, bar)
    ticker:Hide()
    ticker:SetScript("OnUpdate", function(self, elapsed)
        elapsedTotal = elapsedTotal + elapsed
        if elapsedTotal < 0.05 then return end
        elapsedTotal = 0
        if not PlayerUI:TickClassPower() then self:Hide() end
    end)
    bar.ticker = ticker

    self.classPower = bar
    self:LayoutClassPower()
    self:HideStockClassPower()
    self:UpdateClassPower()
    return bar
end

function PlayerUI:HideStockClassPower()
    for _, name in ipairs({ "ComboFrame", "RuneFrame" }) do
        local frame = _G[name]
        if frame and not frame.narciSilenced then
            frame.narciSilenced = true
            frame:SetAlpha(0)
            if not InCombatLockdown() then frame:Hide() end
            frame:HookScript("OnShow", function(self) self:SetAlpha(0) end)
        end
    end
end

function PlayerUI:LayoutClassPower()
    local bar = self.classPower
    local player = frames.player
    if not bar or not player then return end
    local db = Settings()
    local S = NS.Styling
    local height = db.classPowerHeight or 8
    if bar.kind == "totems" then height = math.max(height, 14) end
    local gap = db.classPowerGap or 3
    local width = player:GetWidth()
    local style = db.classPowerStyle or "flat"
    local shape = bar.kind ~= "totems" and CLASS_POWER_SHAPES[db.classPowerShape or "bars"]
    local alpha = (db.classPowerBg or 92) / 100
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", player, "BOTTOMLEFT", db.classPowerX or 0, -4 + (db.classPowerY or 0))
    if shape then
        local size = db.classPowerSize or math.max(14, height * 2)
        local total = size * bar.count + gap * (bar.count - 1)
        bar:SetSize(width, size)
        for index, seg in ipairs(bar.segments) do
            seg:ClearAllPoints()
            seg:SetSize(size, size)
            seg:SetPoint("LEFT", bar, "LEFT", (width - total) / 2 + (index - 1) * (size + gap), 0)
            S.SkinBox(seg, "none")
            seg.barFill:Hide()
            seg.fill = seg.orbFill
            seg.orbFill:SetStatusBarTexture(S.Media(shape.fill))
            seg.orbFill:Show()
            seg.shapeGround:SetTexture(S.Media(shape.fill))
            seg.shapeGround:SetVertexColor(0.02, 0.022, 0.03, alpha)
            seg.shapeGround:Show()
            local r, g, b, a = S.BoxRing(style)
            seg.shapeRing:SetTexture(S.Media(shape.ring))
            seg.shapeRing:SetSize(size * shape.ringScale, size * shape.ringScale)
            if r then
                seg.shapeRing:SetVertexColor(r, g, b, a)
                seg.shapeRing:Show()
            else
                seg.shapeRing:Hide()
            end
            seg.shapeGlow:SetSize(size * 2, size * 2)
            if style == "neon" or style == "soft" then
                local A = S.ACCENT_GLOW
                if style == "soft" then
                    seg.shapeGlow:SetBlendMode("BLEND")
                    seg.shapeGlow:SetVertexColor(0, 0, 0, 0.7)
                else
                    seg.shapeGlow:SetBlendMode("ADD")
                    seg.shapeGlow:SetVertexColor(A[1], A[2], A[3], 0.45)
                end
                seg.shapeGlow:Show()
            else
                seg.shapeGlow:Hide()
            end
        end
        return
    end
    bar:SetSize(width, height)
    local segWidth = (width - gap * (bar.count - 1)) / bar.count
    for index, seg in ipairs(bar.segments) do
        seg:ClearAllPoints()
        seg:SetSize(segWidth, height)
        seg:SetPoint("LEFT", bar, "LEFT", (index - 1) * (segWidth + gap), 0)
        S.SkinBox(seg, style, { alpha = alpha })
        seg.fill = seg.barFill
        seg.barFill:Show()
        if seg.orbFill then
            seg.orbFill:Hide()
            seg.shapeGround:Hide()
            seg.shapeRing:Hide()
            seg.shapeGlow:Hide()
        end
        if seg.icon then
            seg.icon:ClearAllPoints()
            seg.icon:SetSize(height - 2, height - 2)
            seg.icon:SetPoint("LEFT", seg, "LEFT", 1, 0)
            seg.fill:ClearAllPoints()
            seg.fill:SetPoint("TOPLEFT", seg.icon, "TOPRIGHT", 1, 0)
            seg.fill:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", -1, 1)
        end
    end
end

function PlayerUI:RestyleClassPower()
    if not self.classPower then return end
    self:LayoutClassPower()
    self:UpdateClassPower()
end

function PlayerUI:UpdateClassPower()
    local bar = self.classPower
    if not bar then return end
    local A = NS.Styling.ACCENT_GLOW
    if bar.kind == "combo" then
        local points = GetComboPoints("player", "target") or 0
        local _, class = UnitClass("player")
        local show = class == "ROGUE" or points > 0 or UnitPowerType("player") == 3
        bar:SetShown(show)
        for index, seg in ipairs(bar.segments) do
            seg.fill:SetValue(index <= points and 1 or 0)
            local warm = index == bar.count and points == bar.count
            seg.fill:SetStatusBarColor(warm and 1 or A[1], warm and 0.35 or A[2], warm and 0.25 or A[3])
        end
        return
    end
    bar:Show()
    if self:TickClassPower() and bar.ticker then bar.ticker:Show() end
end

function PlayerUI:TickClassPower()
    local bar = self.classPower
    if not bar then return end
    local now = GetTime()
    local busy = false
    if bar.kind == "runes" then
        for index, seg in ipairs(bar.segments) do
            local rune = RUNE_ORDER[index]
            local start, duration, ready = GetRuneCooldown(rune)
            local color = RUNE_COLORS[GetRuneType(rune) or 1] or RUNE_COLORS[1]
            local value = 1
            if not ready and start and duration and duration > 0 then
                value = math.min(1, math.max(0, (now - start) / duration))
            end
            seg.fill:SetValue(value)
            local dim = ready and 1 or 0.45
            seg.fill:SetStatusBarColor(color[1] * dim, color[2] * dim, color[3] * dim)
            if not ready then busy = true end
        end
    elseif bar.kind == "totems" then
        for index, seg in ipairs(bar.segments) do
            local have, _, start, duration, icon = GetTotemInfo(index)
            local color = TOTEM_COLORS[index]
            if have and duration and duration > 0 then
                local left = math.max(0, start + duration - now)
                seg.icon:SetTexture(icon)
                seg.icon:Show()
                seg.fill:SetValue(left / duration)
                seg.fill:SetStatusBarColor(color[1], color[2], color[3])
                seg.time:SetText(left >= 60 and string.format("%dm", math.ceil(left / 60)) or string.format("%d", left))
                busy = true
            else
                seg.icon:Hide()
                seg.fill:SetValue(0)
                seg.time:SetText("")
            end
        end
    end
    return busy
end

function PlayerUI:Show()
    if not Enabled() then return end

    for _, unit in ipairs(ORDER) do
        self:Build(unit)
    end

    if self.layoutPending and not InCombatLockdown() then
        self.layoutPending = nil
        for _, f in pairs(frames) do self:Relayout(f) end
    end

    self:HideBlizzard()
    self:BuildClassPower()
    self:ApplyWatchAll()
    self:UpdateAll()
end

function PlayerUI:Hide()
    if InCombatLockdown() then
        self.watchPending = true
        return
    end

    for _, f in pairs(frames) do
        if UnitWatchRegistered(f) then UnregisterUnitWatch(f) end
        f:Hide()
    end
end

function PlayerUI:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Show()
        NS.Print("свой интерфейс игрока включён")
    else
        self:Hide()
        NS.Print("свой интерфейс игрока выключен, рамки клиента вернутся после /reload")
    end
end

function PlayerUI:Move()
    if NS.Movers then NS.Movers:Toggle() end
end

function PlayerUI:PrepareMove()
    if not NS.Movers or InCombatLockdown() or not Enabled() then return end

    if not PlayerUI.narciFinish then
        PlayerUI.narciFinish = true
        table.insert(NS.Movers.finish, function()
            PlayerUI:ApplyWatchAll()
            PlayerUI:UpdateAll()
        end)
    end

    for _, f in pairs(frames) do
        if UnitWatchRegistered(f) then UnregisterUnitWatch(f) end
    end
end

function PlayerUI:SetScale(value)
    local db = Settings()
    local scale = tonumber(value)

    if not db or not scale or scale < 0.5 or scale > 2 then
        NS.Print("масштаб от 0.5 до 2, например /narci ui scale 1.1")
        return
    end

    db.scale = scale

    for _, f in pairs(frames) do
        f:SetScale(scale)
    end

    NS.Print("масштаб рамок: " .. scale)
end

function PlayerUI:SetUnitEnabled(unit, value)
    local db = Settings()
    if not db or not db.units[unit] then return end

    db.units[unit].enabled = value and true or false
    self:ApplyWatch(unit)
    self:UpdateAll()
end

function PlayerUI:SetUnitSize(unit, width, height)
    local db = Settings()
    local store = db and db.units[unit]
    if not store then return end

    if width then store.width = width end
    if height then store.height = height end

    local f = frames[unit]
    if f then self:Relayout(f) end

    self:UpdateAll()
end

function PlayerUI:SetUnitOption(unit, field, value)
    local db = Settings()
    local store = db and db.units[unit]
    if not store then return end

    store[field] = value

    local f = frames[unit]
    if f and field == "alpha" then f:SetAlpha(value) end

    self:UpdateAll()
end

function PlayerUI:ResetPositions()
    local db = Settings()
    if not db then return end

    for unit, preset in pairs(LAYOUT) do
        local store = db.units[unit]
        store.point, store.x, store.y = preset.point, preset.x, preset.y
        store.width, store.height = preset.width, preset.height

        local f = frames[unit]
        if f then
            f:ClearAllPoints()
            f:SetPoint(store.point, UIParent, store.point, store.x, store.y)
            self:Relayout(f)
        end
    end

    NS.Print("расположение рамок сброшено")
end

function PlayerUI:TogglePower()
    local db = Settings()
    if not db then return end

    db.showPower = not db.showPower
    for _, f in pairs(frames) do self:Relayout(f) end
    self:UpdateAll()

    NS.Print(db.showPower and "полоса ресурса показана" or "полоса ресурса скрыта")
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("UNIT_PET")
driver:RegisterEvent("UNIT_HEALTH")
driver:RegisterEvent("UNIT_MAXHEALTH")
driver:RegisterEvent("UNIT_NAME_UPDATE")
driver:RegisterEvent("UNIT_LEVEL")
driver:RegisterEvent("UNIT_DISPLAYPOWER")
driver:RegisterEvent("UNIT_MODEL_CHANGED")
driver:RegisterEvent("UNIT_PORTRAIT_UPDATE")
driver:RegisterEvent("UNIT_AURA")
driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("PLAYER_FOCUS_CHANGED")
driver:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
driver:RegisterEvent("ARENA_OPPONENT_UPDATE")
driver:RegisterEvent("ADDON_LOADED")
pcall(driver.RegisterEvent, driver, "PORTRAITS_UPDATED")

for _, event in ipairs(POWER_EVENTS) do
    driver:RegisterEvent(event)
end

local TRACKED = { player = true, target = true, targettarget = true, pet = true, focus = true,
    focustarget = true, pettarget = true, targettargettarget = true }
for index = 1, 4 do TRACKED["boss" .. index] = true end
for index = 1, 5 do TRACKED["arena" .. index] = true end

driver:SetScript("OnEvent", function(self, event, unit)
    if not Enabled() then return end

    if event == "PORTRAITS_UPDATED" then
        PlayerUI:RefreshPortraits()
        return
    end

    if event == "UNIT_AURA" and unit == "player" then
        local mounted = IsMounted() and true or false
        if mounted ~= PlayerUI.wasMounted then
            PlayerUI.wasMounted = mounted
            local f = frames.player
            if f then
                f.portraitGUID = nil
                if f.model then f.model.guid = nil end
                PlayerUI:UpdatePortrait(f, "player")
            end
        end
    end

    if event == "PLAYER_LOGIN" then
        if NS.After then NS.After(3, function() PlayerUI:Show() end) end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
        PlayerUI:Show()
        if event == "PLAYER_ENTERING_WORLD" and NS.After then
            for _, delay in ipairs({ 2, 5 }) do
                NS.After(delay, function() PlayerUI:RefreshPortraits() end)
            end
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        PlayerUI:UpdateUnit("target")
        PlayerUI:UpdateUnit("targettarget")
        PlayerUI:UpdateUnit("targettargettarget")
        return
    end

    if event == "ADDON_LOADED" then
        if unit == "Blizzard_ArenaUI" then PlayerUI:HideGroupStock() end
        return
    end

    if event == "PLAYER_FOCUS_CHANGED" then
        PlayerUI:UpdateUnit("focus")
        PlayerUI:UpdateUnit("focustarget")
        return
    end

    if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        for index = 1, 4 do PlayerUI:UpdateUnit("boss" .. index) end
        return
    end

    if event == "ARENA_OPPONENT_UPDATE" then
        for index = 1, 5 do PlayerUI:UpdateUnit("arena" .. index) end
        return
    end

    if event == "UPDATE_SHAPESHIFT_FORM" then unit = "player" end

    if unit then
        if not TRACKED[unit] then return end

        if BAR_EVENTS[event] then
            PlayerUI:UpdateBars(unit)
            return
        end

        if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED"
            or event == "UPDATE_SHAPESHIFT_FORM" then
            local f = frames[unit]
            if f then
                f.portraitGUID = nil
                if f.model then f.model.guid = nil end
            end
        end

        PlayerUI:UpdateUnit(unit)

        if unit == "player" then PlayerUI:UpdateUnit("pet") end
        if unit == "target" then PlayerUI:UpdateUnit("targettarget") end

        return
    end

    PlayerUI:UpdateAll()
end)

if NS.HealPrediction then
    NS.HealPrediction:Watch(function(guids)
        if not Enabled() then return end
        for unit, f in pairs(frames) do
            if f:IsShown() then
                local guid = UnitGUID(unit)
                if guid and guids[guid] then PlayerUI:UpdatePrediction(f, unit) end
            end
        end
    end)
end

local totTicker = CreateFrame("Frame")
local totElapsed = 0

totTicker:SetScript("OnUpdate", function(self, step)
    totElapsed = totElapsed + step
    if totElapsed < 0.3 then return end
    totElapsed = 0

    if not Enabled() then return end

    for _, unit in ipairs(POLLED) do
        local f = frames[unit]
        if f and f:IsShown() then PlayerUI:UpdateUnit(unit) end
    end
end)
