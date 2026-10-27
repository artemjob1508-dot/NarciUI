local addonName, NS = ...

local Styling = {}
NS.Styling = Styling

Styling.BG_DARK      = { 0.03, 0.03, 0.06 }
Styling.BG_DARK_A    = 0.94
Styling.BG_SLOT      = { 0.06, 0.07, 0.10 }
Styling.BG_STRIPE    = { 0.05, 0.09, 0.16 }

Styling.ACCENT       = { 0.0, 0.68, 0.48 }
Styling.ACCENT_DIM   = { 0.0, 0.40, 0.28 }
Styling.ACCENT_GLOW  = { 0.0, 0.85, 0.60 }

Styling.ACCENT_PRESETS = {
    { key = "emerald", name = "Изумруд",  base = { 0.00, 0.68, 0.48 }, dim = { 0.00, 0.40, 0.28 }, glow = { 0.00, 0.85, 0.60 } },
    { key = "azure",   name = "Лазурь",   base = { 0.10, 0.55, 0.85 }, dim = { 0.06, 0.32, 0.50 }, glow = { 0.25, 0.72, 1.00 } },
    { key = "amber",   name = "Янтарь",   base = { 0.88, 0.62, 0.12 }, dim = { 0.52, 0.36, 0.07 }, glow = { 1.00, 0.78, 0.28 } },
    { key = "crimson", name = "Багрянец", base = { 0.80, 0.20, 0.28 }, dim = { 0.48, 0.12, 0.17 }, glow = { 1.00, 0.36, 0.42 } },
    { key = "violet",  name = "Аметист",  base = { 0.58, 0.36, 0.86 }, dim = { 0.34, 0.21, 0.52 }, glow = { 0.74, 0.53, 1.00 } },
    { key = "frost",   name = "Иней",     base = { 0.45, 0.72, 0.78 }, dim = { 0.26, 0.43, 0.47 }, glow = { 0.62, 0.90, 0.96 } },
}

function Styling.DeriveAccent(r, g, b)
    return { r, g, b },
        { r * 0.6, g * 0.6, b * 0.6 },
        { r + (1 - r) * 0.3, g + (1 - g) * 0.3, b + (1 - b) * 0.3 }
end

function Styling.ClassColor()
    local _, class = UnitClass("player")
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local color = class and colors and colors[class]
    if not color then return end
    return color.r, color.g, color.b
end

function Styling.AddAccent(key, name, r, g, b)
    if type(key) ~= "string" or key == "class" or key == "custom" then return false end
    for _, preset in ipairs(Styling.ACCENT_PRESETS) do
        if preset.key == key then return false end
    end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not (r and g and b) then return false end
    local base, dim, glow = Styling.DeriveAccent(r, g, b)
    table.insert(Styling.ACCENT_PRESETS, { key = key, name = name or key, base = base, dim = dim, glow = glow })
    return true
end

function Styling.AddBackgroundTone(key, name, r, g, b)
    if type(key) ~= "string" then return false end
    for _, tone in ipairs(Styling.BG_TONES) do
        if tone.key == key then return false end
    end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not (r and g and b) then return false end
    table.insert(Styling.BG_TONES, #Styling.BG_TONES, { key = key, name = name or key, rgb = { r, g, b } })
    return true
end

function Styling.ApplyAccent(key)
    if key == "class" then
        local r, g, b = Styling.ClassColor()
        if not r then return false end

        local base, dim, glow = Styling.DeriveAccent(r * 0.85, g * 0.85, b * 0.85)

        for i = 1, 3 do
            Styling.ACCENT[i] = base[i]
            Styling.ACCENT_DIM[i] = dim[i]
            Styling.ACCENT_GLOW[i] = glow[i]
        end

        return true
    end

    if key == "custom" then
        local custom = NS.db and NS.db.accentCustom
        if not custom then return false end

        local base, dim, glow = Styling.DeriveAccent(custom[1], custom[2], custom[3])

        for i = 1, 3 do
            Styling.ACCENT[i] = base[i]
            Styling.ACCENT_DIM[i] = dim[i]
            Styling.ACCENT_GLOW[i] = glow[i]
        end

        return true
    end

    for _, preset in ipairs(Styling.ACCENT_PRESETS) do
        if preset.key == key then
            for i = 1, 3 do
                Styling.ACCENT[i] = preset.base[i]
                Styling.ACCENT_DIM[i] = preset.dim[i]
                Styling.ACCENT_GLOW[i] = preset.glow[i]
            end
            return true
        end
    end
    return false
end

Styling.GOLD         = { 1.0, 0.82, 0.0 }
Styling.GOLD_DIM     = { 0.80, 0.65, 0.0 }
Styling.ORN = {
    corners = true, crest = true, header = true, divider = true, gloss = true,
    sheen = 1, shade = 1, tint = "accent", cornerSize = 30,
    banners = true, badges = true, toolbar = "auto", bannerAlpha = 1,
    pattern = "none", patternAlpha = 0.25, cornerStyle = "filigree", dividerStyle = "filigree",
}

Styling.PATTERNS = {
    dots = "PatternDots", diag = "PatternDiag", grid = "PatternGrid",
    carbon = "PatternCarbon", noise = "PatternNoise", scales = "PatternScales",
}
Styling.CORNER_STYLES = {
    filigree = "DecorCorner", rune = "DecorCornerRune", leaf = "DecorCornerLeaf", geo = "DecorCornerGeo",
}
local DECOR_EXTRAS = { patterns = {}, corners = {}, dividers = {} }

local TEXTURE_OVERRIDES = NS.MEDIA_OVERRIDES or {}

function Styling.Media(path)
    if type(path) == "string" and path:find("\\", 1, true) then return path end
    return TEXTURE_OVERRIDES[path] or (Styling.MEDIA .. (path or ""))
end

function Styling.ReplaceTexture(name, path)
    if type(name) ~= "string" or name:find("\\", 1, true) or type(path) ~= "string" then return false end
    TEXTURE_OVERRIDES[name] = path
    if name == "Glow" then Styling.GLOW = path end
    return true
end

function Styling.Font(file)
    return NS.OwnFont(file)
end

function Styling.AddDecor(kind, key, label, path)
    local target = (kind == "patterns" and Styling.PATTERNS) or (kind == "corners" and Styling.CORNER_STYLES)
        or (kind == "dividers" and Styling.DIVIDER_STYLES)
    if not target or type(key) ~= "string" or key == "none" or type(path) ~= "string" or target[key] then return false end
    target[key] = path
    table.insert(DECOR_EXTRAS[kind], { key = key, label = label or key })
    return true
end

function Styling.Extras(kind)
    return DECOR_EXTRAS[kind] or {}
end

Styling.DIVIDER_STYLES = {
    filigree = "DecorDivider", chain = "DecorDividerChain", orb = "DecorDividerOrb", wave = "DecorDividerWave",
}

Styling.TEXT_BRIGHT  = { 0.92, 0.92, 0.92 }
Styling.TEXT_NORMAL  = { 0.70, 0.70, 0.75 }
Styling.TEXT_DIM     = { 0.45, 0.45, 0.50 }

Styling.BORDER       = { 0.18, 0.20, 0.28, 0.85 }
Styling.BORDER_LIGHT = { 0.25, 0.30, 0.40, 0.6 }

local function Copy(list)
    local copy = {}
    for i = 1, #list do copy[i] = list[i] end
    return copy
end

local function Clamp(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local BASE = {
    BG_DARK      = Copy(Styling.BG_DARK),
    BG_SLOT      = Copy(Styling.BG_SLOT),
    BG_STRIPE    = Copy(Styling.BG_STRIPE),
    TEXT_BRIGHT  = Copy(Styling.TEXT_BRIGHT),
    TEXT_NORMAL  = Copy(Styling.TEXT_NORMAL),
    TEXT_DIM     = Copy(Styling.TEXT_DIM),
    BORDER       = Copy(Styling.BORDER),
    BORDER_LIGHT = Copy(Styling.BORDER_LIGHT),
}

Styling.BG_SHIFT     = { 0, 0, 0 }
Styling.BG_SCALE     = 1
Styling.SHADOW_SCALE = 1
Styling.ANIM_SCALE   = 1
Styling.PANEL_MOTION = true

Styling.BG_TONES = {
    { key = "obsidian", name = "Обсидиан",  rgb = { 0.030, 0.030, 0.060 } },
    { key = "graphite", name = "Графит",    rgb = { 0.046, 0.046, 0.050 } },
    { key = "coal",     name = "Уголь",     rgb = { 0.012, 0.012, 0.014 } },
    { key = "warm",     name = "Тёплый",    rgb = { 0.066, 0.048, 0.032 } },
    { key = "midnight", name = "Полночь",   rgb = { 0.012, 0.034, 0.080 } },
    { key = "accent",   name = "Цвет темы" },
}

Styling.TEXT_TONES = {
    neutral = { BASE.TEXT_BRIGHT, BASE.TEXT_NORMAL, BASE.TEXT_DIM },
    warm    = { { 0.95, 0.91, 0.83 }, { 0.76, 0.71, 0.63 }, { 0.50, 0.46, 0.40 } },
    cool    = { { 0.88, 0.93, 0.98 }, { 0.66, 0.72, 0.80 }, { 0.42, 0.47, 0.55 } },
}

Styling.SHADOW_LEVELS = { none = 0, soft = 0.55, normal = 1, deep = 1.7 }
Styling.CORNER_RADII  = { none = 0, small = 6, medium = 10, large = 14 }
Styling.CORNER_RADIUS = 0
Styling.ANIM_SPEEDS   = { slow = 1.6, normal = 1, fast = 0.55 }

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function Set(target, source)
    for i = 1, #source do target[i] = source[i] end
end

function Styling.ApplyTheme(theme)
    theme = theme or {}

    local target
    if theme.bgTone == "accent" then
        local A = Styling.ACCENT
        target = { 0.012 + A[1] * 0.07, 0.012 + A[2] * 0.07, 0.012 + A[3] * 0.07 }
    else
        for _, tone in ipairs(Styling.BG_TONES) do
            if tone.key == theme.bgTone and tone.rgb then target = tone.rgb end
        end
    end
    target = target or BASE.BG_DARK

    for i = 1, 3 do
        local shift = target[i] - BASE.BG_DARK[i]
        Styling.BG_SHIFT[i] = shift
        Styling.BG_DARK[i] = Clamp(target[i])
        Styling.BG_SLOT[i] = Clamp(BASE.BG_SLOT[i] + shift)
        Styling.BG_STRIPE[i] = Clamp(BASE.BG_STRIPE[i] + shift)
    end

    Styling.BG_SCALE = math.max(0.2, math.min(1, (theme.bgDensity or 100) / 100))

    local border = theme.border or "thin"
    if border == "accent" then
        local D, A = Styling.ACCENT_DIM, Styling.ACCENT
        Set(Styling.BORDER, { D[1], D[2], D[3], 0.9 })
        Set(Styling.BORDER_LIGHT, { A[1], A[2], A[3], 0.6 })
    elseif border == "contrast" then
        Set(Styling.BORDER, { 0.34, 0.38, 0.50, 0.95 })
        Set(Styling.BORDER_LIGHT, { 0.44, 0.50, 0.62, 0.75 })
    elseif border == "none" then
        Set(Styling.BORDER, BASE.BORDER)
        Set(Styling.BORDER_LIGHT, BASE.BORDER_LIGHT)
        Styling.BORDER[4] = 0
        Styling.BORDER_LIGHT[4] = 0
    else
        Set(Styling.BORDER, BASE.BORDER)
        Set(Styling.BORDER_LIGHT, BASE.BORDER_LIGHT)
    end

    Styling.SHADOW_SCALE = Styling.SHADOW_LEVELS[theme.shadow or "normal"] or 1
    Styling.CORNER_RADIUS = Styling.CORNER_RADII[theme.corners or "medium"] or 0
    Styling.DECOR = theme.decor == "styled"
    local O = Styling.ORN
    O.corners = theme.decorCorners ~= false
    O.crest = theme.decorCrest ~= false
    O.header = theme.decorHeader ~= false
    O.divider = theme.decorDivider ~= false
    O.gloss = theme.decorGloss ~= false
    O.sheen = (theme.decorSheen or 100) / 100
    O.shade = (theme.decorShade or 100) / 100
    O.tint = theme.decorTint or "accent"
    O.cornerSize = theme.decorCornerSize or 30
    O.banners = theme.tabBanners ~= false
    O.badges = theme.tabBadges ~= false
    O.toolbar = theme.toolbarShape or "auto"
    O.bannerAlpha = (theme.bannerAlpha or 100) / 100
    O.pattern = theme.decorPattern or "none"
    O.patternAlpha = (theme.decorPatternAlpha or 25) / 100
    O.cornerStyle = theme.decorCornerStyle or "filigree"
    O.dividerStyle = theme.decorDividerStyle or "filigree"

    local tone = Styling.TEXT_TONES[theme.textTone or "neutral"] or Styling.TEXT_TONES.neutral
    local bright, normal, dim = Copy(tone[1]), Copy(tone[2]), Copy(tone[3])

    if theme.contrast == "high" then
        for i = 1, 3 do
            bright[i] = Lerp(bright[i], 1, 0.6)
            dim[i] = Lerp(dim[i], normal[i], 0.35)
            normal[i] = Lerp(normal[i], bright[i], 0.35)
        end
    elseif theme.contrast == "soft" then
        for i = 1, 3 do
            bright[i] = bright[i] * 0.9
            normal[i] = Lerp(normal[i], dim[i], 0.2)
            dim[i] = dim[i] * 0.88
        end
    end

    Set(Styling.TEXT_BRIGHT, bright)
    Set(Styling.TEXT_NORMAL, normal)
    Set(Styling.TEXT_DIM, dim)

    Styling.ANIM_SCALE = Styling.ANIM_SPEEDS[theme.animSpeed or "normal"] or 1
    Styling.PANEL_MOTION = theme.motion ~= "fade"

    local quest = NS.QuestStyle
    if quest then
        if quest.BG then Set(quest.BG, { Styling.Bg(Styling.BG_DARK_A) }) end
        if quest.BG_ROW then Set(quest.BG_ROW, { Styling.BG_SLOT[1], Styling.BG_SLOT[2], Styling.BG_SLOT[3], 0.9 }) end
        if quest.BG_ROW_ALT then Set(quest.BG_ROW_ALT, { Styling.BG_STRIPE[1], Styling.BG_STRIPE[2], Styling.BG_STRIPE[3], 0.55 }) end
    end
end

function Styling.Tint(r, g, b, a)
    local d = Styling.BG_SHIFT
    return Clamp(r + d[1]), Clamp(g + d[2]), Clamp(b + d[3]), a
end

function Styling.Panel(r, g, b, a)
    local d = Styling.BG_SHIFT
    return Clamp(r + d[1]), Clamp(g + d[2]), Clamp(b + d[3]), (a or 1) * Styling.BG_SCALE
end

function Styling.Bg(a)
    local B = Styling.BG_DARK
    return B[1], B[2], B[3], (a or Styling.BG_DARK_A) * Styling.BG_SCALE
end

local lastSound = {}

function Styling.Sound(name)
    local theme = NS.db and NS.db.theme
    if not theme or not theme.sounds or not name then return end

    local now = GetTime()
    if lastSound[name] and now - lastSound[name] < 0.15 then return end
    lastSound[name] = now

    PlaySound(name)
end

function Styling.WindowSounds(frame, openSound, closeSound)
    if not frame or frame._narciSounds then return end
    frame._narciSounds = true

    frame:HookScript("OnShow", function() Styling.Sound(openSound or "igCharacterInfoOpen") end)
    frame:HookScript("OnHide", function() Styling.Sound(closeSound or "igCharacterInfoClose") end)
end

Styling.PANEL_WIDTH  = 440
Styling.PANEL_HEIGHT = 340
Styling.PANEL_X      = -8
Styling.PANEL_GAP    = 6

Styling.PANEL_Y      = (Styling.PANEL_HEIGHT + Styling.PANEL_GAP) / 2

function Styling.CreateGradientTopBorder(parent, height, r, g, b, a)
    height = height or 2
    r = r or Styling.ACCENT[1]
    g = g or Styling.ACCENT[2]
    b = b or Styling.ACCENT[3]
    a = a or 0.9

    local inset = parent.narciRound and math.max(4, Styling.CORNER_RADIUS) or 4
    local border = parent:CreateTexture(nil, "OVERLAY")
    border:SetHeight(height)
    border:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -3)
    border:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -3)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(r, g, b, a)

    if Styling.DECOR and Styling.ORN.crest then
        local crest = parent:CreateTexture(nil, "OVERLAY")
        crest:SetSize(72, 18)
        crest:SetPoint("CENTER", border, "CENTER", 0, 0)
        crest:SetTexture(Styling.Media("DecorCrest"))
        local cr, cg, cb = Styling.DecorColor(true)
        crest:SetVertexColor(cr, cg, cb, 0.95)
        border.crest = crest
    end

    if Styling.DECOR and Styling.ORN.header then
        local pattern = parent:CreateTexture(nil, "BORDER")
        pattern:SetPoint("TOPLEFT", border, "BOTTOMLEFT", 0, 0)
        pattern:SetPoint("TOPRIGHT", border, "BOTTOMRIGHT", 0, 0)
        pattern:SetHeight(56)
        pattern:SetTexture(Styling.Media("DecorHeader"))
        pattern:SetBlendMode("ADD")
        if Styling.ORN.tint == "accent" then
            pattern:SetVertexColor(r, g, b, 0.16)
        else
            local pr, pg, pb = Styling.DecorColor(false)
            pattern:SetVertexColor(pr, pg, pb, 0.16)
        end
        local function Crop()
            local w = parent:GetWidth() or 0
            if w <= 0 then return end
            local span = math.min(1, (w / 56) / 16)
            local left = (1 - span) / 2
            pattern:SetTexCoord(left, left + span, 0, 1)
        end
        parent:HookScript("OnSizeChanged", Crop)
        Crop()
        border.pattern = pattern
    end

    local glow = parent:CreateTexture(nil, "BORDER")
    glow:SetTexture(Styling.GLOW)
    glow:SetTexCoord(0, 1, 0.5, 1)
    glow:SetBlendMode("ADD")
    glow:SetPoint("TOPLEFT", border, "BOTTOMLEFT", 30, 0)
    glow:SetPoint("TOPRIGHT", border, "BOTTOMRIGHT", -30, 0)
    glow:SetHeight(34)
    glow:SetVertexColor(r, g, b, 0.14)
    border.glow = glow
    return border
end

function Styling.AddHoverGlow(frame, r, g, b, size)
    r = r or Styling.ACCENT_GLOW[1]
    g = g or Styling.ACCENT_GLOW[2]
    b = b or Styling.ACCENT_GLOW[3]
    size = size or 1

    local glow = CreateFrame("Frame", nil, frame)
    glow:SetPoint("TOPLEFT", -size - 1, size + 1)
    glow:SetPoint("BOTTOMRIGHT", size + 1, -size - 1)
    glow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = size,
    })
    glow:SetBackdropBorderColor(r, g, b, 0)
    glow:SetFrameLevel(frame:GetFrameLevel() + 1)
    glow:EnableMouse(false)

    local elapsed = 0
    local duration = 0.15

    frame:HookScript("OnEnter", function(self)
        elapsed = 0
        glow:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            self:SetBackdropBorderColor(r, g, b, t * 0.7)
            if t >= 1 then self:SetScript("OnUpdate", nil) end
        end)
    end)

    frame:HookScript("OnLeave", function(self)
        elapsed = 0
        glow:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            self:SetBackdropBorderColor(r, g, b, (1 - t) * 0.7)
            if t >= 1 then
                self:SetScript("OnUpdate", nil)
                self:SetBackdropBorderColor(r, g, b, 0)
            end
        end)
    end)

    return glow
end

function Styling.CreateRingBorder(parent, radius, r, g, b)
    r = r or Styling.ACCENT[1]
    g = g or Styling.ACCENT[2]
    b = b or Styling.ACCENT[3]

    local ring = CreateFrame("Frame", nil, parent)
    ring:SetPoint("TOPLEFT", -3, 3)
    ring:SetPoint("BOTTOMRIGHT", 3, -3)
    ring:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ring:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 0.5)
    ring:SetFrameLevel(parent:GetFrameLevel() + 1)
    ring:EnableMouse(false)

    local elapsed = 0
    local duration = 0.2

    parent:HookScript("OnEnter", function(self)
        elapsed = 0
        ring:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            local ease = t * t * (3 - 2 * t)
            self:SetBackdropBorderColor(
                r * 0.5 + r * 0.5 * ease,
                g * 0.5 + g * 0.5 * ease,
                b * 0.5 + b * 0.5 * ease,
                0.5 + 0.4 * ease
            )
            if t >= 1 then self:SetScript("OnUpdate", nil) end
        end)
    end)

    parent:HookScript("OnLeave", function(self)
        elapsed = 0
        ring:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            local ease = t * t * (3 - 2 * t)
            self:SetBackdropBorderColor(
                r * (1 - 0.5 * ease),
                g * (1 - 0.5 * ease),
                b * (1 - 0.5 * ease),
                0.9 - 0.4 * ease
            )
            if t >= 1 then
                self:SetScript("OnUpdate", nil)
                self:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 0.5)
            end
        end)
    end)

    return ring
end

local CORNER_LEN = 12
local CORNERS = {
    { point = "TOPLEFT",     x =  3, y = -3 },
    { point = "TOPRIGHT",    x = -3, y = -3 },
    { point = "BOTTOMLEFT",  x =  3, y =  3 },
    { point = "BOTTOMRIGHT", x = -3, y =  3 },
}

function Styling.ApplyTabChrome(frame)
    if not frame or frame._tabChrome then return end
    frame._tabChrome = true

    local grad = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    grad:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grad:SetTexture("Interface\\Buttons\\WHITE8x8")
    grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.32, 0, 0, 0, 0)

    local bevel = frame:CreateTexture(nil, "BORDER")
    bevel:SetHeight(1)
    bevel:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    bevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    bevel:SetTexture("Interface\\Buttons\\WHITE8x8")
    bevel:SetVertexColor(0.45, 0.50, 0.62, 0.28)

    if Styling.DECOR then return end
    local A = Styling.ACCENT
    for _, c in ipairs(CORNERS) do
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetSize(CORNER_LEN, 1)
        h:SetPoint(c.point, frame, c.point, c.x, c.y)
        h:SetTexture("Interface\\Buttons\\WHITE8x8")
        h:SetVertexColor(A[1], A[2], A[3], 0.75)

        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetSize(1, CORNER_LEN)
        v:SetPoint(c.point, frame, c.point, c.x, c.y)
        v:SetTexture("Interface\\Buttons\\WHITE8x8")
        v:SetVertexColor(A[1], A[2], A[3], 0.75)
    end
end

local PANEL_SLIDE = 28
local PANEL_ANIM  = 0.22

local function GetBasePoint(frame)
    if not frame._basePoint then
        local point, rel, relPoint, x, y = frame:GetPoint()
        frame._basePoint = {
            point or "TOPRIGHT",
            rel or frame:GetParent(),
            relPoint or "TOPRIGHT",
            x or 0,
            y or 0,
        }
    end
    return frame._basePoint
end

local function ApplyOffset(frame, dx)
    local b = frame._basePoint
    if not b then return end
    frame:ClearAllPoints()
    frame:SetPoint(b[1], b[2], b[3], b[4] + dx, b[5])
end

function Styling.AnimationsEnabled()
    return not NS.db or NS.db.animations ~= false
end

function Styling.PanelIn(frame, duration)
    if not frame then return end
    duration = (duration or PANEL_ANIM) * Styling.ANIM_SCALE
    local slide = Styling.PANEL_MOTION and PANEL_SLIDE or 0
    GetBasePoint(frame)

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1)
        ApplyOffset(frame, 0)
        frame:Show()
        return
    end

    local elapsed = 0
    frame:SetAlpha(0)
    ApplyOffset(frame, slide)
    frame:Show()

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetAlpha(1)
            ApplyOffset(self, 0)
            self:SetScript("OnUpdate", nil)
        else
            local ease = 1 - (1 - t) ^ 3
            self:SetAlpha(ease)
            ApplyOffset(self, slide * (1 - ease))
        end
    end)
end

function Styling.PanelOut(frame, duration)
    if not frame or not frame:IsShown() then return end
    duration = (duration or (PANEL_ANIM * 0.65)) * Styling.ANIM_SCALE
    local slide = Styling.PANEL_MOTION and PANEL_SLIDE or 0
    GetBasePoint(frame)

    if not Styling.AnimationsEnabled() then
        Styling.PanelHideNow(frame)
        return
    end

    local startAlpha = frame:GetAlpha()
    local elapsed = 0

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            ApplyOffset(self, 0)
            self:Hide()
            self:SetAlpha(1)
        else
            local ease = t * t
            self:SetAlpha(startAlpha * (1 - ease))
            ApplyOffset(self, slide * 0.6 * ease)
        end
    end)
end

function Styling.PanelHideNow(frame)
    if not frame then return end
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    frame:SetAlpha(1)
    ApplyOffset(frame, 0)
end

function Styling.SetClassIcon(texture, class)
    if not texture then return end
    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not coords then
        texture:Hide()
        return
    end
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    texture:SetVertexColor(1, 1, 1, 1)
    texture:Show()
end

function Styling.StyleScrollBar(scrollFrame)
    local bar = scrollFrame and scrollFrame.ScrollBar
    if not bar or bar._narciStyled then return end
    bar._narciStyled = true

    for _, btn in ipairs({ bar.ScrollUpButton, bar.ScrollDownButton }) do
        if btn then
            btn:Hide()
            btn:SetAlpha(0)
            btn:EnableMouse(false)
        end
    end

    bar:SetWidth(6)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, 0)
    track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 0)
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(Styling.BORDER[1], Styling.BORDER[2], Styling.BORDER[3], 0.35)
    Styling.RoundTexture(track, 2)

    local thumb = bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetTexCoord(0, 1, 0, 1)
        thumb:SetVertexColor(Styling.ACCENT[1], Styling.ACCENT[2], Styling.ACCENT[3], 0.75)
        thumb:SetSize(6, 36)
        Styling.RoundTexture(thumb, 3)
    end

    local FADE_HEIGHT = 14
    local holder = CreateFrame("Frame", nil, scrollFrame:GetParent())
    holder:SetAllPoints(scrollFrame)
    holder:SetFrameLevel(scrollFrame:GetFrameLevel() + 4)
    holder:Hide()

    local B = Styling.BG_DARK
    local function Fade(atTop)
        local t = holder:CreateTexture(nil, "OVERLAY")
        t:SetHeight(FADE_HEIGHT)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        if atTop then
            t:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -8, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0, B[1], B[2], B[3], 0.95)
        else
            t:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -8, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0.95, B[1], B[2], B[3], 0)
        end
        return t
    end
    local topFade, bottomFade = Fade(true), Fade(false)

    local function UpdateFades()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local offset = scrollFrame:GetVerticalScroll() or 0
        if offset > 1 then topFade:Show() else topFade:Hide() end
        if offset < range - 1 then bottomFade:Show() else bottomFade:Hide() end
    end
    scrollFrame:HookScript("OnVerticalScroll", UpdateFades)

    local function UpdateBarVisibility()
        local range = scrollFrame:GetVerticalScrollRange()
        if range and range > 1 then
            bar:Show()
            holder:Show()
            UpdateFades()
        else
            bar:Hide()
            holder:Hide()
        end
    end
    scrollFrame:HookScript("OnScrollRangeChanged", UpdateBarVisibility)
    scrollFrame:HookScript("OnShow", UpdateBarVisibility)
    UpdateBarVisibility()

    return bar
end

function Styling.CreateShadow(parent, size, alpha)
    size = size or 4
    alpha = math.min(1, (alpha or 0.4) * Styling.SHADOW_SCALE)

    Styling.RoundCorners(parent)
    Styling.Decorate(parent)
    local inset = parent.narciRound and Styling.CORNER_RADIUS or 0
    local shadow = Styling.CreateHalo(parent, math.floor(size * 2.5 + 0.5) + inset, 0, 0, 0, math.min(1, alpha * 1.1), nil, nil, inset)
    shadow:SetFrameLevel(math.max(parent:GetFrameLevel() - 1, 0))

    local fill = shadow:CreateTexture(nil, "BACKGROUND")
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetAllPoints(shadow.narciHaloAnchor)
    fill:SetVertexColor(0, 0, 0, alpha * 0.3)
    shadow.fill = fill

    return shadow
end

function Styling.FadeIn(frame, duration)
    if not frame then return end
    duration = (duration or 0.25) * Styling.ANIM_SCALE

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1)
        frame:Show()
        return
    end

    frame:SetAlpha(0)
    frame:Show()

    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local progress = elapsed / duration
        if progress >= 1 then
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        else
            self:SetAlpha(1 - (1 - progress) ^ 3)
        end
    end)
end

function Styling.FadeOut(frame, duration, hideOnComplete)
    if not frame then return end
    duration = (duration or 0.2) * Styling.ANIM_SCALE
    hideOnComplete = (hideOnComplete == nil) and true or hideOnComplete

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(0)
        if hideOnComplete then frame:Hide() end
        return
    end

    local startAlpha = frame:GetAlpha()
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local progress = elapsed / duration
        if progress >= 1 then
            self:SetAlpha(0)
            self:SetScript("OnUpdate", nil)
            if hideOnComplete then
                self:Hide()
            end
        else
            self:SetAlpha(startAlpha * (1 - progress) ^ 3)
        end
    end)
end

function Styling.ApplyPanelStyle(frame, width, height)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(Styling.Bg(Styling.BG_DARK_A))
        frame:SetBackdropBorderColor(Styling.BORDER[1], Styling.BORDER[2], Styling.BORDER[3], Styling.BORDER[4])
    end

    Styling.CreateShadow(frame, 5, 0.4)
    Styling.CreateGradientTopBorder(frame)

    local bottomAccent = frame:CreateTexture(nil, "OVERLAY")
    bottomAccent:SetHeight(1)
    local inset = frame.narciRound and math.max(3, Styling.CORNER_RADIUS) or 3
    bottomAccent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", inset, 3)
    bottomAccent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, 3)
    bottomAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
    bottomAccent:SetVertexColor(Styling.ACCENT_DIM[1], Styling.ACCENT_DIM[2], Styling.ACCENT_DIM[3], 0.3)

    return frame
end

local breathDriver = CreateFrame("Frame")
local breathJobs = {}

local function JobIsVisible(job)
    return not job.parent or job.parent:IsVisible()
end

breathDriver:SetScript("OnUpdate", function(self, elapsed)
    local anim = Styling.AnimationsEnabled()
    local i = 1
    while i <= #breathJobs do
        local job = breathJobs[i]
        if not job.tex or not job.tex:GetTexture() then
            tremove(breathJobs, i)
        else
            if not anim then
                if not job.frozen then
                    job.tex:SetAlpha((job.minAlpha + job.maxAlpha) / 2)
                    job.frozen = true
                end
            elseif JobIsVisible(job) then
                job.frozen = nil
                job.elapsed = job.elapsed + elapsed
                local t = (job.elapsed % job.speed) / job.speed
                local a = job.minAlpha + (job.maxAlpha - job.minAlpha) * (0.5 + 0.5 * math.sin(t * 6.28318))
                job.tex:SetAlpha(a)
            end
            i = i + 1
        end
    end
    if #breathJobs == 0 then self:Hide() end
end)

function Styling.AddBreathingGlow(texture, minAlpha, maxAlpha, speed)
    minAlpha = minAlpha or 0.5
    maxAlpha = maxAlpha or 0.8
    speed = speed or 0.8

    tinsert(breathJobs, {
        tex = texture,
        parent = texture.GetParent and texture:GetParent() or nil,
        minAlpha = minAlpha,
        maxAlpha = maxAlpha,
        speed = speed,
        elapsed = math.random() * 100,
    })
    breathDriver:Show()
end

function Styling.GetILvlColor(itemLevel)
    if not itemLevel or itemLevel <= 0 then return 0.5, 0.5, 0.5 end
    if itemLevel >= 260 then
        return Styling.ACCENT_GLOW[1], Styling.ACCENT_GLOW[2], Styling.ACCENT_GLOW[3]
    elseif itemLevel >= 240 then
        return 0.2, 0.9, 0.2
    elseif itemLevel >= 200 then
        return 1.0, 0.82, 0.0
    elseif itemLevel >= 170 then
        return 1.0, 0.6, 0.0
    else
        return 0.8, 0.2, 0.2
    end
end

local sepDriver = CreateFrame("Frame")
local sepJobs = {}

sepDriver:SetScript("OnUpdate", function(self, elapsed)
    local anim = Styling.AnimationsEnabled()
    local i = 1
    while i <= #sepJobs do
        local job = sepJobs[i]
        if not job.dot or not job.dot:GetTexture() then
            tremove(sepJobs, i)
        else
            if not anim then
                if not job.frozen then
                    job.dot:Hide()
                    job.frozen = true
                end
            elseif JobIsVisible(job) then
                if job.frozen then
                    job.dot:Show()
                    job.frozen = nil
                end
                job.elapsed = job.elapsed + elapsed
                local p = (job.elapsed % (job.cycleTime * 2)) / job.cycleTime
                local t = p <= 1 and p or (2 - p)
                local parentWidth = job.parent:GetWidth() or 260
                local travel = parentWidth - 20 - job.dotWidth
                if travel < 0 then travel = 0 end
                local x = 10 + travel * t
                job.dot:ClearAllPoints()
                job.dot:SetPoint("TOPLEFT", job.parent, "TOPLEFT", x, job.y)
            end
            i = i + 1
        end
    end
    if #sepJobs == 0 then self:Hide() end
end)

function Styling.CreateAnimatedSeparator(parent, y, height)
    height = height or 1
    local S = Styling

    local base = parent:CreateTexture(nil, "ARTWORK")
    if S.DECOR and S.ORN.divider then
        base:SetHeight(10)
        base:SetPoint("LEFT", parent, "TOPLEFT", 10, y - height / 2)
        base:SetPoint("RIGHT", parent, "TOPRIGHT", -10, y - height / 2)
        base:SetTexture(S.Media(S.DIVIDER_STYLES[S.ORN.dividerStyle] or "DecorDivider"))
        local dr, dg, db = S.DecorColor(false)
        base:SetVertexColor(dr, dg, db, 0.85)
    else
        base:SetHeight(height)
        base:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        base:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, y)
        base:SetTexture("Interface\\Buttons\\WHITE8x8")
        base:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.06)
    end

    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetSize(40, height + 1)
    dot:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")
    dot:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.45)

    tinsert(sepJobs, {
        dot = dot,
        dotWidth = 40,
        parent = parent,
        y = y,
        elapsed = 0,
        cycleTime = 4.0,
    })
    sepDriver:Show()

    return { base = base, dot = dot }
end

local flashDriver = CreateFrame("Frame")
local flashJobs = {}

flashDriver:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local i = 1
    while i <= #flashJobs do
        local job = flashJobs[i]
        if not job.fs or not job.fs:GetFont() then
            tremove(flashJobs, i)
        else
            local t = (now - job.startTime) / job.duration
            if t >= 1 then
                job.fs:SetTextColor(job.endR, job.endG, job.endB)
                tremove(flashJobs, i)
            else
                local fade = t * t
                local r = job.startR * (1 - fade) + job.endR * fade
                local g = job.startG * (1 - fade) + job.endG * fade
                local b = job.startB * (1 - fade) + job.endB * fade
                job.fs:SetTextColor(r, g, b)
                i = i + 1
            end
        end
    end
    if #flashJobs == 0 then self:Hide() end
end)

function Styling.FlashValue(fontString, duration, endColor)
    if not fontString then return end
    duration = duration or 0.4
    local S = Styling
    local finish = endColor or S.TEXT_BRIGHT

    if not Styling.AnimationsEnabled() then
        fontString:SetTextColor(finish[1], finish[2], finish[3])
        return
    end

    for i = #flashJobs, 1, -1 do
        if flashJobs[i].fs == fontString then tremove(flashJobs, i) end
    end

    local r, g, b = fontString:GetTextColor()
    fontString:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    tinsert(flashJobs, {
        fs = fontString,
        startTime = GetTime(),
        duration = duration,
        startR = S.ACCENT_GLOW[1], startG = S.ACCENT_GLOW[2], startB = S.ACCENT_GLOW[3],
        endR = finish[1], endG = finish[2], endB = finish[3],
    })
    flashDriver:Show()
end

function Styling.CreateEnchantDot(parent, side)
    local dot = parent:CreateTexture(nil, "OVERLAY", nil, 3)
    dot:SetSize(6, 6)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")

    if side == "LEFT" then
        dot:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -4, 4)
    elseif side == "RIGHT" then
        dot:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 4, 4)
    else
        dot:SetPoint("TOP", parent, "BOTTOM", 14, -3)
    end

    dot:SetVertexColor(0.4, 0.4, 0.4, 0.5)
    return dot
end

function Styling.SetEnchantDotStatus(dot, status)
    if not dot then return end
    local S = Styling
    if status == "enchanted" then
        dot:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.8)
    elseif status == "missing" then
        dot:SetVertexColor(0.9, 0.2, 0.2, 0.8)
    else
        dot:SetVertexColor(0.4, 0.4, 0.4, 0.3)
    end
end

function Styling.CreateSectionRule(parent, anchorTo, width)
    local A = Styling.ACCENT
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -3)
    t:SetWidth(width or 260)
    t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0.45, A[1], A[2], A[3], 0)
    return t
end

function Styling.CreateEdges(parent, layer, r, g, b, a)
    local edges = {}

    for index = 1, 4 do
        local line = parent:CreateTexture(nil, layer or "OVERLAY")
        line:SetTexture("Interface\\Buttons\\WHITE8x8")
        line:SetVertexColor(r, g, b, a or 1)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    return edges
end

Styling.MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
Styling.GLOW = Styling.Media("Glow")

Styling.GLYPH_ICONS = {
    X = "IconClose", x = "IconClose", ["+"] = "IconPlus", ["-"] = "IconMinus",
    v = "IconDown", ["^"] = "IconUp", [">"] = "IconRight", ["<"] = "IconLeft",
}

function Styling.GlyphIcon(fontString, size)
    if not fontString or fontString.narciGlyph then return fontString and fontString.narciGlyph end
    local icon = fontString:GetParent():CreateTexture(nil, fontString:GetDrawLayer() or "OVERLAY")
    icon:SetPoint("CENTER", fontString, "CENTER", 0, 0)
    fontString.narciGlyph = icon

    local function Sync()
        local name = Styling.GLYPH_ICONS[fontString:GetText() or ""]
        if not name then
            fontString:SetAlpha(1)
            icon:Hide()
            return
        end
        local side = size
        if not side then
            local _, fontSize = fontString:GetFont()
            side = math.max(8, math.floor((fontSize or 12) * 0.8 + 0.5))
        end
        icon:SetTexture(Styling.Media(name))
        icon:SetSize(side, side)
        fontString:SetAlpha(0)
        if fontString:IsShown() then icon:Show() else icon:Hide() end
    end

    local r, g, b, a = fontString:GetTextColor()
    icon:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    hooksecurefunc(fontString, "SetText", Sync)
    hooksecurefunc(fontString, "SetTextColor", function(_, nr, ng, nb, na) icon:SetVertexColor(nr, ng, nb, na or 1) end)
    hooksecurefunc(fontString, "Show", Sync)
    hooksecurefunc(fontString, "Hide", function() icon:Hide() end)
    if fontString.SetShown then hooksecurefunc(fontString, "SetShown", Sync) end
    Sync()
    return icon
end

local HALO_TEXEL = 1 / 64
local HALO_MID_A, HALO_MID_B = 0.5 - HALO_TEXEL / 2, 0.5 + HALO_TEXEL / 2

local HALO_PIECES = {
    { "BOTTOMRIGHT", "TOPLEFT", 0, 0.5, 0, 0.5, "corner" },
    { "BOTTOMLEFT", "TOPRIGHT", 0.5, 1, 0, 0.5, "corner" },
    { "TOPRIGHT", "BOTTOMLEFT", 0, 0.5, 0.5, 1, "corner" },
    { "TOPLEFT", "BOTTOMRIGHT", 0.5, 1, 0.5, 1, "corner" },
    { "TOP", nil, HALO_MID_A, HALO_MID_B, 0, 0.5, "top" },
    { "BOTTOM", nil, HALO_MID_A, HALO_MID_B, 0.5, 1, "bottom" },
    { "LEFT", nil, 0, 0.5, HALO_MID_A, HALO_MID_B, "left" },
    { "RIGHT", nil, 0.5, 1, HALO_MID_A, HALO_MID_B, "right" },
}

function Styling.GlowPieces(parent, size, layer, blend, hidden)
    local pieces = {}
    for _, piece in ipairs(HALO_PIECES) do
        local t = parent:CreateTexture(nil, layer or "BACKGROUND")
        t:SetTexture(Styling.GLOW)
        t:SetTexCoord(piece[3], piece[4], piece[5], piece[6])
        if blend then t:SetBlendMode(blend) end
        local kind, anchor = piece[7], parent.narciHaloAnchor or parent
        if kind == "corner" then
            t:SetSize(size, size)
            t:SetPoint(piece[1], anchor, piece[2], 0, 0)
        elseif kind == "top" then
            t:SetHeight(size)
            t:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 0)
        elseif kind == "bottom" then
            t:SetHeight(size)
            t:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
        elseif kind == "left" then
            t:SetWidth(size)
            t:SetPoint("TOPRIGHT", anchor, "TOPLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT", 0, 0)
        else
            t:SetWidth(size)
            t:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
            t:SetPoint("BOTTOMLEFT", anchor, "BOTTOMRIGHT", 0, 0)
        end
        if hidden then t:Hide() end
        pieces[#pieces + 1] = t
    end
    return pieces
end

function Styling.CreateHalo(parent, size, r, g, b, a, layer, blend, inset)
    inset = inset or 0
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", inset - size, size - inset)
    holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", size - inset, inset - size)
    holder:SetFrameLevel(math.max(parent:GetFrameLevel() - 1, 0))
    holder.narciHaloAnchor = parent
    if inset > 0 then
        local anchor = holder:CreateTexture(nil, "BACKGROUND")
        anchor:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
        anchor:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
        holder.narciHaloAnchor = anchor
    end
    holder.pieces = Styling.GlowPieces(holder, size, layer, blend)

    function holder:SetHaloColor(nr, ng, nb, na)
        for _, t in ipairs(self.pieces) do t:SetVertexColor(nr, ng, nb, na) end
    end
    holder:SetHaloColor(r or 0, g or 0, b or 0, a or 0.5)

    return holder
end

local ROUND_MID_A, ROUND_MID_B = 0.5 - 1 / 128, 0.5 + 1 / 128

local ROUND_PIECES = {
    { "TOPLEFT", 0, 0.5, 0, 0.5, "corner" },
    { "TOPRIGHT", 0.5, 1, 0, 0.5, "corner" },
    { "BOTTOMLEFT", 0, 0.5, 0.5, 1, "corner" },
    { "BOTTOMRIGHT", 0.5, 1, 0.5, 1, "corner" },
    { "TOP", ROUND_MID_A, ROUND_MID_B, 0, 0.5, "top" },
    { "BOTTOM", ROUND_MID_A, ROUND_MID_B, 0.5, 1, "bottom" },
    { "LEFT", 0, 0.5, ROUND_MID_A, ROUND_MID_B, "left" },
    { "RIGHT", 0.5, 1, ROUND_MID_A, ROUND_MID_B, "right" },
}

local FLAT_WHITE = "Interface\\Buttons\\WHITE8x8"

local function IsFlat(path)
    if type(path) ~= "string" then return false end
    path = path:lower()
    return path:find("white8x8", 1, true) ~= nil or path:find("chatframebackground", 1, true) ~= nil
end

local function RoundPieces(owner, frame, texture, r, sublevel, center, layer)
    local pieces = {}
    for _, piece in ipairs(ROUND_PIECES) do
        local t = owner:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
        t:SetTexture(texture)
        t:SetTexCoord(piece[2], piece[3], piece[4], piece[5])
        local kind = piece[6]
        if kind == "corner" then
            t:SetSize(r, r)
            t:SetPoint(piece[1], frame, piece[1], 0, 0)
        elseif kind == "top" then
            t:SetHeight(r)
            t:SetPoint("TOPLEFT", frame, "TOPLEFT", r, 0)
            t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -r, 0)
        elseif kind == "bottom" then
            t:SetHeight(r)
            t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", r, 0)
            t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -r, 0)
        elseif kind == "left" then
            t:SetWidth(r)
            t:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -r)
            t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, r)
        else
            t:SetWidth(r)
            t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -r)
            t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, r)
        end
        pieces[#pieces + 1] = t
    end
    if center then
        local t = owner:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
        t:SetTexture(FLAT_WHITE)
        t:SetPoint("TOPLEFT", frame, "TOPLEFT", r, -r)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -r, r)
        pieces[#pieces + 1] = t
    end
    return pieces
end

local function RoundFits(backdrop)
    if type(backdrop) ~= "table" then return false end
    if backdrop.bgFile and not IsFlat(backdrop.bgFile) then return false end
    if backdrop.edgeFile and (not IsFlat(backdrop.edgeFile) or (tonumber(backdrop.edgeSize) or 1) > 2) then return false end
    return (backdrop.bgFile or backdrop.edgeFile) and true or false
end

local function CurrentBackdrop(frame)
    if frame.GetBackdrop then
        local ok, backdrop = pcall(frame.GetBackdrop, frame)
        if ok then return backdrop end
    end
    local okBg, bg = pcall(frame.GetBackdropColor, frame)
    local okEdge, edge = pcall(frame.GetBackdropBorderColor, frame)
    bg = okBg and bg or nil
    edge = okEdge and edge or nil
    if not bg and not edge then return nil end
    return { bgFile = bg and FLAT_WHITE or nil, edgeFile = edge and FLAT_WHITE or nil, edgeSize = 1 }
end

function Styling.RoundCorners(frame, radius, known)
    local r = radius or Styling.CORNER_RADIUS
    if Styling.CORNER_RADIUS <= 0 or not frame or frame.narciRound or frame.narciNoRound then return end
    if not frame.SetBackdrop or not frame.GetBackdropColor then return end
    local name = frame:GetName()
    if name and not name:find("^Narci") then return end
    if select(2, frame:IsProtected()) then return end
    local current = known or CurrentBackdrop(frame)
    if not RoundFits(current) then return end

    local real = {
        SetBackdrop = frame.SetBackdrop,
        SetBackdropColor = frame.SetBackdropColor,
        SetBackdropBorderColor = frame.SetBackdropBorderColor,
        GetBackdrop = frame.GetBackdrop,
        GetBackdropColor = frame.GetBackdropColor,
        GetBackdropBorderColor = frame.GetBackdropBorderColor,
    }
    local br, bg, bb, ba = frame:GetBackdropColor()
    local er, eg, eb, ea = frame:GetBackdropBorderColor()

    local state = { bg = { 1, 1, 1, 1 }, edge = { 1, 1, 1, 1 } }
    state.fill = RoundPieces(frame, frame, Styling.Media("RoundFill"), r, -8, true)
    state.ring = RoundPieces(frame, frame, Styling.Media("RoundRing" .. r), r, 7)
    for index = 5, 8 do
        local t = state.ring[index]
        t:SetTexture(FLAT_WHITE)
        t:SetTexCoord(0, 1, 0, 1)
        t:ClearAllPoints()
        if index == 5 then
            t:SetHeight(1)
            t:SetPoint("TOPLEFT", frame, "TOPLEFT", r, 0)
            t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -r, 0)
        elseif index == 6 then
            t:SetHeight(1)
            t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", r, 0)
            t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -r, 0)
        elseif index == 7 then
            t:SetWidth(1)
            t:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -r)
            t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, r)
        else
            t:SetWidth(1)
            t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -r)
            t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, r)
        end
    end
    frame.narciRound = state

    local function Paint()
        local backdrop = state.backdrop
        for _, t in ipairs(state.fill) do
            t:SetVertexColor(state.bg[1], state.bg[2], state.bg[3], state.bg[4])
            if backdrop and backdrop.bgFile then t:Show() else t:Hide() end
        end
        for _, t in ipairs(state.ring) do
            t:SetVertexColor(state.edge[1], state.edge[2], state.edge[3], state.edge[4])
            if backdrop and backdrop.edgeFile then t:Show() else t:Hide() end
        end
    end

    function frame:SetBackdrop(backdrop)
        if RoundFits(backdrop) then
            state.backdrop = backdrop
            state.bg = { 1, 1, 1, 1 }
            state.edge = { 1, 1, 1, 1 }
            real.SetBackdrop(self, nil)
        else
            state.backdrop = nil
            real.SetBackdrop(self, backdrop)
        end
        Paint()
    end

    function frame:SetBackdropColor(nr, ng, nb, na)
        if not state.backdrop then return real.SetBackdropColor(self, nr, ng, nb, na) end
        state.bg = { nr or 1, ng or 1, nb or 1, na or 1 }
        Paint()
    end

    function frame:SetBackdropBorderColor(nr, ng, nb, na)
        if not state.backdrop then return real.SetBackdropBorderColor(self, nr, ng, nb, na) end
        state.edge = { nr or 1, ng or 1, nb or 1, na or 1 }
        Paint()
    end

    function frame:GetBackdrop()
        if state.backdrop then return state.backdrop end
        return real.GetBackdrop(self)
    end

    function frame:GetBackdropColor()
        if state.backdrop then return state.bg[1], state.bg[2], state.bg[3], state.bg[4] end
        return real.GetBackdropColor(self)
    end

    function frame:GetBackdropBorderColor()
        if state.backdrop then return state.edge[1], state.edge[2], state.edge[3], state.edge[4] end
        return real.GetBackdropBorderColor(self)
    end

    frame:SetBackdrop(current)
    frame:SetBackdropColor(br, bg, bb, ba)
    frame:SetBackdropBorderColor(er, eg, eb, ea)
end

local function MirrorTexture(texture, pieces)
    local muted = false
    local function Color(_, r, g, b, a)
        for _, p in ipairs(pieces) do p:SetVertexColor(r or 1, g or 1, b or 1, a or 1) end
    end
    local function Visible()
        local shown = texture:IsShown()
        for _, p in ipairs(pieces) do if shown then p:Show() else p:Hide() end end
    end
    local function Alpha(_, a)
        if muted then return end
        for _, p in ipairs(pieces) do p:SetAlpha(a or 1) end
        muted = true
        texture:SetAlpha(0)
        muted = false
    end
    Color(nil, texture:GetVertexColor())
    Alpha(nil, texture:GetAlpha())
    Visible()
    hooksecurefunc(texture, "SetVertexColor", Color)
    hooksecurefunc(texture, "SetAlpha", Alpha)
    hooksecurefunc(texture, "Show", Visible)
    hooksecurefunc(texture, "Hide", Visible)
    if texture.SetShown then hooksecurefunc(texture, "SetShown", Visible) end
end

function Styling.RoundTexture(texture, r)
    if Styling.CORNER_RADIUS <= 0 or not texture or texture.narciRound then return end
    local layer, sublevel = texture:GetDrawLayer()
    local pieces = RoundPieces(texture:GetParent(), texture, Styling.Media("RoundFill"), r, sublevel, true, layer)
    texture.narciRound = pieces
    MirrorTexture(texture, pieces)
end

function Styling.RoundHighlight(button, r)
    if Styling.CORNER_RADIUS <= 0 or not button or not button.GetHighlightTexture then return end
    local highlight = button:GetHighlightTexture()
    if not highlight or highlight.narciRound then return end
    local pieces = RoundPieces(button, button, Styling.Media("RoundFill"), r, nil, true, "HIGHLIGHT")
    local blend = highlight.GetBlendMode and highlight:GetBlendMode()
    for _, p in ipairs(pieces) do p:SetBlendMode(blend or "ADD") end
    highlight.narciRound = pieces
    MirrorTexture(highlight, pieces)
end

local DECOR_TINTS = {
    gold = { 1.0, 0.80, 0.40 },
    silver = { 0.80, 0.84, 0.92 },
    bronze = { 0.86, 0.56, 0.32 },
    white = { 1, 1, 1 },
}

function Styling.DecorColorFor(tint, bright)
    local t = DECOR_TINTS[tint]
    if t then return t[1], t[2], t[3] end
    local c = bright and Styling.ACCENT_GLOW or Styling.ACCENT
    return c[1], c[2], c[3]
end

function Styling.DecorColor(bright)
    return Styling.DecorColorFor(Styling.ORN.tint, bright)
end

local DECOR_CORNERS = {
    { "TOPLEFT", 1, -1, 0, 1, 0, 1 },
    { "TOPRIGHT", -1, -1, 1, 0, 0, 1 },
    { "BOTTOMLEFT", 1, 1, 0, 1, 1, 0 },
    { "BOTTOMRIGHT", -1, 1, 1, 0, 1, 0 },
}

local MAX_TILES = 240

function Styling.TileArea(parent, layer, sublevel, inset)
    local area = { tiles = {}, inset = inset or 0, shown = true, size = 64, color = { 1, 1, 1, 1 } }

    function area:Layout()
        local w = (parent:GetWidth() or 0) - self.inset * 2
        local h = (parent:GetHeight() or 0) - self.inset * 2
        local used = 0
        if self.path and self.shown and w > 0 and h > 0 then
            local s = self.size
            while math.ceil(w / s) * math.ceil(h / s) > MAX_TILES do s = s * 2 end
            local c = self.color
            for row = 0, math.ceil(h / s) - 1 do
                local th = math.min(s, h - row * s)
                for col = 0, math.ceil(w / s) - 1 do
                    local tw = math.min(s, w - col * s)
                    used = used + 1
                    local t = self.tiles[used]
                    if not t then
                        t = parent:CreateTexture(nil, layer or "BORDER", nil, sublevel)
                        self.tiles[used] = t
                    end
                    t:ClearAllPoints()
                    t:SetPoint("TOPLEFT", parent, "TOPLEFT", self.inset + col * s, -(self.inset + row * s))
                    t:SetSize(tw, th)
                    t:SetTexture(self.path)
                    t:SetTexCoord(0, tw / s, 0, th / s)
                    t:SetVertexColor(c[1], c[2], c[3], c[4])
                    t:Show()
                end
            end
        end
        for index = used + 1, #self.tiles do self.tiles[index]:Hide() end
    end

    function area:SetTexture(path, size)
        self.path = path
        self.size = size or ((type(path) == "string" and path:find("Noise")) and 128 or 64)
        self:Layout()
    end

    function area:SetVertexColor(r, g, b, a)
        self.color = { r, g, b, a or 1 }
        for _, t in ipairs(self.tiles) do t:SetVertexColor(r, g, b, a or 1) end
    end

    function area:SetShown(shown)
        self.shown = shown and true or false
        self:Layout()
    end

    function area:Show() self:SetShown(true) end
    function area:Hide() self:SetShown(false) end

    parent:HookScript("OnSizeChanged", function() area:Layout() end)

    return area
end

function Styling.Decorate(frame, force)
    if not Styling.DECOR or not frame or frame.narciDecor or frame.narciNoRound or not frame.CreateTexture then return end
    local name = frame.GetName and frame:GetName()
    if name and not name:match("^Narci") and not force then return end
    if frame.IsProtected and select(2, frame:IsProtected()) then return end
    local A, O = Styling.ACCENT, Styling.ORN
    local decor = { corners = {} }
    frame.narciDecor = decor

    local shade = frame:CreateTexture(nil, "BORDER")
    shade:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    shade:SetTexture(Styling.Media("DecorVignette"))
    shade:SetVertexColor(0, 0, 0, math.min(1, 0.5 * O.shade))
    decor.shade = shade

    local sheen = frame:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    sheen:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    sheen:SetTexture(Styling.Media("DecorSheen"))
    sheen:SetBlendMode("ADD")
    sheen:SetVertexColor(A[1], A[2], A[3], 0.09 * O.sheen)
    decor.sheen = sheen
    if O.sheen <= 0 then sheen:Hide() end

    local offset = 3 + (frame.narciRound and math.floor(Styling.CORNER_RADIUS / 3) or 0)
    local gr, gg, gb = Styling.DecorColor(true)
    for _, c in ipairs(O.corners and DECOR_CORNERS or {}) do
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetSize(O.cornerSize, O.cornerSize)
        t:SetPoint(c[1], frame, c[1], c[2] * offset, c[3] * offset)
        t:SetTexture(Styling.Media(Styling.CORNER_STYLES[O.cornerStyle] or "DecorCorner"))
        t:SetTexCoord(c[4], c[5], c[6], c[7])
        t:SetVertexColor(gr, gg, gb, 0.8)
        decor.corners[#decor.corners + 1] = t
    end

    local pattern = Styling.PATTERNS[O.pattern]
    if pattern and O.patternAlpha > 0 then
        local inset = 2 + (frame.narciRound and math.floor(Styling.CORNER_RADIUS * 0.6) or 0)
        local tile = Styling.TileArea(frame, "BORDER", -1, inset)
        local pr, pg, pb = Styling.DecorColor(true)
        tile:SetVertexColor(pr, pg, pb, O.patternAlpha)
        tile:SetTexture(Styling.Media(pattern))
        decor.pattern = tile
    end

    local function Fit()
        local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
        local big = w >= 160 and h >= 90
        for _, t in ipairs(decor.corners) do
            if big then t:Show() else t:Hide() end
        end
        if w >= 120 and h >= 60 and O.shade > 0 then shade:Show() else shade:Hide() end
    end
    frame:HookScript("OnSizeChanged", Fit)
    Fit()
end

function Styling.Gloss(frame, r, g, b, a)
    if not Styling.DECOR or not Styling.ORN.gloss or not frame or frame.narciGloss then return end
    local t = frame:CreateTexture(nil, "ARTWORK")
    t:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    t:SetTexture(Styling.Media("DecorGloss"))
    t:SetBlendMode("ADD")
    t:SetVertexColor(r or Styling.ACCENT[1], g or Styling.ACCENT[2], b or Styling.ACCENT[3], a or 0.22)
    frame.narciGloss = t
    return t
end

function Styling.RoundWidget(frame, bg, border)
    if bg and frame and frame.GetObjectType and frame:GetObjectType() == "Button" then Styling.Gloss(frame) end
    if Styling.CORNER_RADIUS <= 0 then return end
    if bg then Styling.RoundTexture(bg, 5) end
    if border then Styling.RoundCorners(border, 6, { edgeFile = FLAT_WHITE, edgeSize = 1 }) end
    Styling.RoundHighlight(frame, 5)
end

function Styling.CreateSoftShadow(parent, size, alpha)
    size = size or 6
    alpha = math.min(1, (alpha or 0.5) * Styling.SHADOW_SCALE)
    return Styling.CreateHalo(parent, math.floor(size * 1.5 + 0.5), 0, 0, 0, alpha)
end

Styling.EMBLEMS = {
    narcissus = "LogoEmblem", star = "LogoEmblemStar", moon = "LogoEmblemMoon",
    shield = "LogoEmblemShield", flame = "LogoEmblemFlame", crown = "LogoEmblemCrown",
}
Styling.WORDMARK_FONT = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\Expressway.ttf"

local BRAND_COLORS = {
    gold = { 1, 0.80, 0.32 },
    silver = { 0.80, 0.84, 0.90 },
    white = { 1, 1, 1 },
}
local brandWatchers = {}

function Styling.Brand()
    if not NS.db then return {} end
    if type(NS.db.brand) ~= "table" then NS.db.brand = {} end
    return NS.db.brand
end

function Styling.BrandName()
    local name = Styling.Brand().name
    if type(name) == "string" and name:match("%S") then return name end
end

function Styling.BrandMotto()
    local motto = Styling.Brand().motto
    if type(motto) == "string" and motto:match("%S") then return motto end
end

function Styling.BrandColor()
    local key = Styling.Brand().color or "accent"
    if key == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then
            return c.r, c.g, c.b, math.min(1, c.r * 0.7 + 0.3), math.min(1, c.g * 0.7 + 0.3), math.min(1, c.b * 0.7 + 0.3)
        end
    end
    local c = BRAND_COLORS[key]
    if c then return c[1], c[2], c[3], c[1], c[2], c[3] end
    local A, G = Styling.ACCENT, Styling.ACCENT_GLOW
    return A[1], A[2], A[3], G[1], G[2], G[3]
end

Styling.EMBLEM_FRAMES = {
    crest = "Crest", circle = "Circle", diamond = "Diamond", badge = "Badge", runic = "Runic",
    laurel = "Laurel", medal = "Medal", bare = "Bare",
}

local EMBLEM_SYMBOLS = {
    narcissus = "Narcissus", star = "Star", moon = "Moon", shield = "Shield", flame = "Flame", crown = "Crown",
}

function Styling.EmblemPath(key, frame)
    local part = Styling.EMBLEM_FRAMES[frame or "crest"]
    local symbol = EMBLEM_SYMBOLS[key] or EMBLEM_SYMBOLS.narcissus
    if part then return "Emblem" .. part .. symbol end
    return Styling.EMBLEMS[key] or Styling.EMBLEMS.narcissus
end

function Styling.PaintEmblem(texture, glowTexture, glowAlpha, small)
    local brand = Styling.Brand()
    local key = brand.emblem or "narcissus"
    local _, _, _, r, g, b = Styling.BrandColor()
    if brand.glow then glowAlpha = (glowAlpha or 0.3) * brand.glow / 100 end
    if key == "class" then
        Styling.SetClassIcon(texture, select(2, UnitClass("player")))
        texture:SetVertexColor(1, 1, 1, 1)
        if glowTexture then
            glowTexture:SetTexture(Styling.GLOW)
            glowTexture:SetVertexColor(r, g, b, glowAlpha or 0.3)
        end
        return
    end
    local path = Styling.EmblemPath(key, brand.frame)
    local file = path
    if small and (brand.frame or "crest") == "crest" then file = path .. "Small" end
    texture:SetTexture(Styling.Media(file))
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetVertexColor(r, g, b, 1)
    if glowTexture then
        glowTexture:SetTexture(Styling.Media(path .. "Glow"))
        glowTexture:SetVertexColor(r, g, b, glowAlpha or 0.3)
    end
end

function Styling.PaintWordmark(texture, text, file, size)
    local name = Styling.BrandName()
    local _, _, _, r, g, b = Styling.BrandColor()
    if name then
        texture:Hide()
        text:SetFont(Styling.Font("Expressway.ttf"), NS.FS(size or 30), "")
        text:SetText(name)
        text:SetTextColor(r, g, b)
        text:Show()
    else
        text:Hide()
        texture:SetTexture(Styling.Media(file or "LogoText"))
        texture:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 1, r, g, b, 1)
        texture:Show()
    end
end

function Styling.WatchBrand(fn)
    brandWatchers[#brandWatchers + 1] = fn
end

function Styling.BrandChanged()
    for _, fn in ipairs(brandWatchers) do pcall(fn) end
end

Styling.BOX_ORDER = { "flat", "pixel", "glass", "neon", "soft", "classic", "gold", "none" }
Styling.BOX_LABELS = {
    flat = "плоский", pixel = "пиксельный", glass = "стекло", neon = "неон",
    soft = "мягкая тень", classic = "клиент", gold = "золото", none = "без рамки",
}
Styling.BOX_EXTRA = {}

function Styling.AddBox(key, label, row)
    if type(key) ~= "string" or key == "" or key == "theme" or Styling.BOX_LABELS[key] or type(row) ~= "table" then return false end
    Styling.BOX_EXTRA[key] = row
    table.insert(Styling.BOX_ORDER, key)
    Styling.BOX_LABELS[key] = label or key
    return true
end

function Styling.BoxOptions()
    local L = NS.L
    local list = {}
    for _, key in ipairs(Styling.BOX_ORDER) do
        list[#list + 1] = { key = key, label = L[Styling.BOX_LABELS[key]] }
    end
    return list
end

function Styling.BoxRing(key, tint)
    local extra = Styling.BOX_EXTRA[key]
    if extra then
        if extra.ring then return extra.ring[1], extra.ring[2], extra.ring[3], extra.ring[4] or 1 end
        key = extra.base or "flat"
    end
    local A, B = Styling.ACCENT_GLOW, Styling.BORDER
    if key == "none" or key == "soft" then return nil end
    if key == "pixel" then return 0, 0, 0, 1 end
    if key == "glass" then return 1, 1, 1, 0.4 end
    if key == "neon" then
        if tint then return tint[1], tint[2], tint[3], 1 end
        return A[1], A[2], A[3], 1
    end
    if key == "classic" then return 0.75, 0.75, 0.75, 1 end
    if key == "gold" then return 1, 0.82, 0.3, 1 end
    if tint then return tint[1], tint[2], tint[3], 0.9 end
    return B[1], B[2], B[3], 0.9
end

local function PaintBox(frame, key, opts)
    if not frame then return end
    opts = opts or {}
    local box = frame.narciBox
    if not box then
        box = {}
        box.ground = frame:CreateTexture(nil, "BACKGROUND")
        box.ground:SetAllPoints(frame)
        box.ground:SetTexture(FLAT_WHITE)
        box.edges = Styling.CreateEdges(frame, opts.edgeLayer or "BORDER", 1, 1, 1, 1)
        box.glow = Styling.GlowPieces(frame, opts.glowSize or 6, "BACKGROUND", "ADD", true)
        box.sheen = frame:CreateTexture(nil, "BORDER")
        box.sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        box.sheen:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        box.sheen:SetTexture(Styling.Media("DecorGloss"))
        box.sheen:SetBlendMode("ADD")
        box.border = CreateFrame("Frame", nil, frame)
        box.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
        box.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
        box.border:SetFrameLevel(frame:GetFrameLevel() + (opts.borderLevel or 4))
        box.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = opts.edgeSize or 12 })
        box.shadow = Styling.CreateHalo(frame, opts.shadowSize or 8, 0, 0, 0, 0.7)
        box.edgeFileSize = opts.edgeSize or 12
        frame.narciBox = box
    end
    box.key = key

    local A, B = Styling.ACCENT_GLOW, Styling.BORDER
    local alpha = opts.alpha or 0.92
    local tint = opts.tint
    local function Ground(r, g, b, a)
        box.ground:SetVertexColor(r, g, b, a)
        box.ground:Show()
    end
    local function Edges(r, g, b, a, top)
        for index, line in ipairs(box.edges) do
            if index == 1 and top then
                line:SetVertexColor(top[1], top[2], top[3], top[4])
            else
                line:SetVertexColor(r, g, b, a)
            end
            line:Show()
        end
    end

    box.ground:Hide()
    for _, line in ipairs(box.edges) do line:Hide() end
    for _, t in ipairs(box.glow) do t:Hide() end
    box.sheen:Hide()
    box.border:Hide()
    box.shadow:Hide()

    if key == "none" then return box end
    if opts.noGround ~= true then
        if key == "pixel" then
            Ground(0, 0, 0, alpha)
        elseif key == "glass" then
            Ground(0.1, 0.11, 0.15, alpha * 0.45)
        elseif key == "neon" then
            Ground(0.01, 0.01, 0.02, alpha)
        elseif key == "soft" then
            Ground(0.03, 0.03, 0.045, alpha * 0.85)
        elseif key == "classic" then
            Ground(0, 0, 0, alpha * 0.75)
        elseif key == "gold" then
            Ground(0.05, 0.04, 0.02, alpha * 0.85)
        else
            Ground(0.016, 0.018, 0.026, alpha)
        end
    end

    if key == "glass" then
        Edges(1, 1, 1, 0.16, { 1, 1, 1, 0.38 })
        box.sheen:SetVertexColor(A[1], A[2], A[3], 0.2)
        box.sheen:Show()
    elseif key == "neon" or key == "flat" or key == "pixel" then
        Edges(Styling.BoxRing(key, tint))
        if key == "neon" then
            local r, g, b = Styling.BoxRing(key, tint)
            for _, t in ipairs(box.glow) do
                t:SetVertexColor(r, g, b, 0.5)
                t:Show()
            end
        end
    elseif key == "soft" then
        box.shadow:Show()
    elseif key == "classic" or key == "gold" then
        local r, g, b = Styling.BoxRing(key, tint)
        box.border:SetBackdropBorderColor(r, g, b, 1)
        box.border:Show()
    end
    return box
end

function Styling.SkinBox(frame, key, opts)
    if not frame then return end
    local extra = Styling.BOX_EXTRA[key]
    local box = PaintBox(frame, extra and (extra.base or "flat") or key, opts)
    box.key = key
    if box.narciCustomBorder and not extra then
        box.narciCustomBorder = nil
        box.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = box.edgeFileSize or 12 })
    end
    if box.art then box.art:Hide() end
    if not extra then return box end
    opts = opts or {}
    local alpha = opts.alpha or 0.92
    if extra.ground and opts.noGround ~= true then
        local c = extra.ground
        box.ground:SetVertexColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
        box.ground:Show()
    end
    if extra.edge then
        local c = extra.edge
        for _, line in ipairs(box.edges) do
            line:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            line:Show()
        end
    end
    if extra.glow then
        local c = extra.glow
        for _, t in ipairs(box.glow) do
            t:SetVertexColor(c[1], c[2], c[3], c[4] or 0.5)
            t:Show()
        end
    end
    if extra.border then
        local b = extra.border
        box.narciCustomBorder = true
        box.border:SetBackdrop({ edgeFile = Styling.Media(b.file), edgeSize = b.size or box.edgeFileSize or 12 })
        local c = b.color or { 1, 1, 1, 1 }
        box.border:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
        box.border:Show()
    end
    if extra.art then
        local a = extra.art
        if not box.art then
            box.art = frame:CreateTexture(nil, "BORDER")
            box.art:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
            box.art:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end
        box.art:SetTexture(Styling.Media(a.file))
        box.art:SetBlendMode(a.blend or "BLEND")
        local c = a.color or { 1, 1, 1 }
        box.art:SetVertexColor(c[1], c[2], c[3], (a.alpha or 1) * alpha)
        box.art:Show()
    end
    if type(extra.paint) == "function" then
        local ok, err = pcall(extra.paint, frame, box, opts)
        if not ok and NS.Print then NS.Print("SkinBox " .. tostring(key) .. ": " .. tostring(err)) end
    end
    return box
end

function Styling.FadeChrome(frame, on)
    local decor = frame and frame.narciDecor
    if not decor then return end
    local list = { decor.shade, decor.sheen }
    for _, t in ipairs(decor.corners or {}) do list[#list + 1] = t end
    for _, t in pairs(list) do
        if t.narciChromeAlpha == nil then t.narciChromeAlpha = t:GetAlpha() end
        t:SetAlpha(on and t.narciChromeAlpha or 0)
    end
    if decor.pattern then
        if on then decor.pattern:Show() else decor.pattern:Hide() end
    end
end

function Styling.ThemeBoxOptions(themeLabel)
    local list = { { key = "theme", label = NS.L[themeLabel or "как окна аддона"] } }
    for _, option in ipairs(Styling.BoxOptions()) do list[#list + 1] = option end
    return list
end

Styling.SCENE_ART = {
    night = { file = "MessengerNight", aspect = 2, anchor = "bottom" },
    dawn = { file = "ArtDawn", aspect = 2, anchor = 0.42 },
    parchment = { file = "MessengerParchment", aspect = 1 },
}

function Styling.AddSceneArt(key, file, aspect, anchor)
    if type(key) ~= "string" or type(file) ~= "string" or Styling.SCENE_ART[key] then return false end
    Styling.SCENE_ART[key] = { file = file, aspect = tonumber(aspect) or 1, anchor = anchor }
    return true
end

function Styling.CoverArt(texture, aspect, anchor)
    if not texture then return end
    local w, h = texture:GetWidth() or 0, texture:GetHeight() or 0
    if w <= 0 or h <= 0 or not aspect then return end
    local ratio = w / h
    if ratio > aspect then
        local v = aspect / ratio
        local center = anchor == "bottom" and 1 - v / 2 or anchor == "top" and v / 2 or tonumber(anchor) or 0.5
        local top = math.max(0, math.min(1 - v, center - v / 2))
        texture:SetTexCoord(0, 1, top, top + v)
    else
        local u = ratio / aspect
        texture:SetTexCoord((1 - u) / 2, (1 + u) / 2, 0, 1)
    end
end

function Styling.SceneArt(texture, key)
    local art = Styling.SCENE_ART[key]
    if not texture or not art then return false end
    texture:SetTexture(Styling.Media(art.file))
    Styling.CoverArt(texture, art.aspect, art.anchor)
    if not texture.narciCover then
        texture.narciCover = true
        local holder = texture:GetParent()
        if holder and holder.HookScript then
            holder:HookScript("OnSizeChanged", function()
                if texture.narciScene then
                    local a = Styling.SCENE_ART[texture.narciScene]
                    if a then Styling.CoverArt(texture, a.aspect, a.anchor) end
                end
            end)
        end
    end
    texture.narciScene = key
    return true
end

function Styling.ThemePalette(theme)
    theme = theme or {}
    local out = {}
    local target
    if theme.bgTone == "accent" then
        local A = Styling.ACCENT
        target = { 0.012 + A[1] * 0.07, 0.012 + A[2] * 0.07, 0.012 + A[3] * 0.07 }
    else
        for _, tone in ipairs(Styling.BG_TONES) do
            if tone.key == theme.bgTone and tone.rgb then target = tone.rgb end
        end
    end
    target = target or BASE.BG_DARK
    out.bg = { target[1], target[2], target[3] }
    out.slot = {}
    for i = 1, 3 do out.slot[i] = Clamp(BASE.BG_SLOT[i] + target[i] - BASE.BG_DARK[i]) end
    out.density = math.max(0.2, math.min(1, (theme.bgDensity or 100) / 100))
    local border = theme.border or "thin"
    if border == "accent" then
        local D = Styling.ACCENT_DIM
        out.border = { D[1], D[2], D[3], 0.9 }
    elseif border == "contrast" then
        out.border = { 0.34, 0.38, 0.50, 0.95 }
    elseif border == "none" then
        out.border = { BASE.BORDER[1], BASE.BORDER[2], BASE.BORDER[3], 0 }
    else
        out.border = Copy(BASE.BORDER)
    end
    out.shadow = Styling.SHADOW_LEVELS[theme.shadow or "normal"] or 1
    out.radius = Styling.CORNER_RADII[theme.corners or "medium"] or 0
    local tone = Styling.TEXT_TONES[theme.textTone or "neutral"] or Styling.TEXT_TONES.neutral
    local bright, normal, dim = Copy(tone[1]), Copy(tone[2]), Copy(tone[3])
    if theme.contrast == "high" then
        for i = 1, 3 do
            bright[i] = Lerp(bright[i], 1, 0.6)
            dim[i] = Lerp(dim[i], normal[i], 0.35)
            normal[i] = Lerp(normal[i], bright[i], 0.35)
        end
    elseif theme.contrast == "soft" then
        for i = 1, 3 do
            bright[i] = bright[i] * 0.9
            normal[i] = Lerp(normal[i], dim[i], 0.2)
            dim[i] = dim[i] * 0.88
        end
    end
    out.bright, out.normal, out.dim = bright, normal, dim
    return out
end
