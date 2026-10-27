local addonName, NS = ...
local L = NS.L

local CastBar = {}
NS.CastBar = CastBar

local WHITE = "Interface\\Buttons\\WHITE8x8"

local LAYOUT = {
    player = { width = 300, height = 26, point = "BOTTOM", x = 0, y = 250, label = "Полоса заклинания" },
    target = { width = 260, height = 22, point = "TOP", x = 0, y = -220, label = "Заклинание цели" },
    focus = { width = 220, height = 18, point = "CENTER", x = 0, y = 160, label = "Заклинание фокуса", off = true },
}

local ORDER = { "player", "target", "focus" }

local bars = {}

local function FillSettings()
    if not NS.db then return end

    if not NS.db.castBar then NS.db.castBar = {} end

    local db = NS.db.castBar
    if db.enabled == nil then db.enabled = false end
    if db.showIcon == nil then db.showIcon = true end
    if db.showTime == nil then db.showTime = true end
    db.style = db.style or "line"
    db.units = db.units or {}
    db.colorMode = db.colorMode or "theme"
    db.castColor = db.castColor or { 0.30, 0.65, 1.00 }
    db.channelColor = db.channelColor or { 0.35, 0.85, 0.50 }
    db.lockedColor = db.lockedColor or { 0.70, 0.25, 0.25 }
    if db.latency == nil then db.latency = true end
    if db.spark == nil then db.spark = true end
    if db.fade == nil then db.fade = true end
    if db.flash == nil then db.flash = true end
    db.iconSide = db.iconSide or "left"
    db.timeFormat = db.timeFormat or "both"
    db.textAlign = db.textAlign or "left"
    db.nameSize = db.nameSize or 0
    db.bgAlpha = db.bgAlpha or 92

    for unit, preset in pairs(LAYOUT) do
        local store = db.units[unit] or {}
        if store.enabled == nil then store.enabled = not preset.off end
        store.width = store.width or preset.width
        store.height = store.height or preset.height
        store.point = store.point or preset.point
        store.x = store.x or preset.x
        store.y = store.y or preset.y
        db.units[unit] = store
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.castBar
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local STYLES = {
    line = true, classic = true, pixel = true, neon = true, thin = true,
    glass = true, outline = true, gradient = true, shadow = true, underline = true,
}
local SHADED = "Interface\\TargetingFrame\\UI-StatusBar"
local GLOW_SIZE = 7

local function CastStyle()
    local db = Settings()
    return db and STYLES[db.style] and db.style or "line"
end

local function CreateGlow(f)
    return NS.Styling.GlowPieces(f, GLOW_SIZE, "BACKGROUND", "ADD", true)
end

local function PaintGlow(glow, r, g, b, a)
    for _, texture in ipairs(glow) do
        texture:SetVertexColor(r, g, b, a)
    end
end

local function CreateCastFrame(parent, unit, name, store)
    local S = NS.Styling
    local f = CreateFrame("Frame", name, parent)
    f:SetSize(store.width, store.height)
    f:SetFrameStrata(parent == UIParent and "MEDIUM" or parent:GetFrameStrata())
    f:Hide()

    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.022, 0.025, 0.034, 0.92)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    icon:SetWidth(store.height - 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local status = CreateFrame("StatusBar", nil, f)
    status:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
    status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    NS.Look:SetBar(status, "castbar", WHITE)
    status:SetStatusBarColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    status:SetMinMaxValues(0, 1)

    local rail = status:CreateTexture(nil, "BACKGROUND")
    rail:SetAllPoints(status)
    rail:SetTexture(WHITE)
    rail:SetVertexColor(0.055, 0.060, 0.080, 0.95)

    local lag = status:CreateTexture(nil, "OVERLAY")
    lag:SetTexture(WHITE)
    lag:SetVertexColor(1, 0.15, 0.15, 0.45)
    lag:Hide()
    f.lag = lag

    local spark = status:CreateTexture(nil, "OVERLAY")
    spark:SetWidth(2)
    spark:SetPoint("TOP", status, "TOP", 0, 0)
    spark:SetPoint("BOTTOM", status, "BOTTOM", 0, 0)
    spark:SetTexture(WHITE)
    spark:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)

    local name = status:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(name, "castbar", NS.FS(store.height >= 24 and 12 or 11), "")
    name:SetPoint("LEFT", status, "LEFT", 6, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    local timer = status:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(timer, "castbar", NS.FS(store.height >= 24 and 12 or 11), "OUTLINE")
    timer:SetPoint("RIGHT", status, "RIGHT", -6, 0)
    timer:SetJustifyH("RIGHT")
    timer:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    name:SetPoint("RIGHT", timer, "LEFT", -6, 0)
    NS.LSetFont(name, "castbar", NS.FS(store.height >= 24 and 12 or 11), "OUTLINE")

    local top = f:CreateTexture(nil, "OVERLAY")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 8, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, 0)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.40)

    local bottom = f:CreateTexture(nil, "OVERLAY")
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 0)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 0)
    bottom:SetTexture(WHITE)
    bottom:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.40,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
    border:Hide()

    local iconFrame = CreateFrame("Frame", nil, f)
    iconFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)

    f.ground, f.top, f.bottom, f.rail = ground, top, bottom, rail
    f.border = border
    f.edges = S.CreateEdges(f, "BORDER", 0, 0, 0, 1)
    f.iconEdges = S.CreateEdges(iconFrame, "OVERLAY", 0, 0, 0, 1)
    f.glow = CreateGlow(f)
    f.softShadow = S.CreateSoftShadow(f, 6, 0.6)
    f.icon = icon
    f.status = status
    f.spark = spark
    f.name = name
    f.timer = timer
    f.unit = unit
    return f
end

function CastBar:Build(unit)
    if bars[unit] then return bars[unit] end

    local db = Settings()
    if not db then return end

    local store = db.units[unit]
    local preset = LAYOUT[unit]
    local S = NS.Styling

    local f = CreateCastFrame(UIParent, unit, "NarciSirus_Cast_" .. unit, store)
    f:SetPoint(store.point, UIParent, store.relativePoint or store.point, store.x, store.y)

    if NS.Movers then
        NS.Movers:Register(f, L[preset.label], function(point, relativePoint, x, y)
            local settings = Settings()
            local unitStore = settings.units[unit]
            unitStore.point, unitStore.relativePoint, unitStore.x, unitStore.y = point, relativePoint, x, y
        end, "cast")
        if not CastBar.moverFinish then
            CastBar.moverFinish = true
            table.insert(NS.Movers.finish, function()
                for key, bar in pairs(bars) do
                    if not bar.endTime or GetTime() >= bar.endTime then bar:Hide() end
                end
            end)
        end
    end

    f.narciForceShow = true

    bars[unit] = f
    self:Style(f)
    return f
end

function CastBar:Style(f)
    local db = Settings()
    local store = db and db.units[f.unit]
    if not store then return end

    local S = NS.Styling
    local style = CastStyle()
    local width, height = store.width, store.height
    local A, G = S.ACCENT, S.ACCENT_GLOW

    f.style = style
    f:SetSize(width, height)
    f.showIcon = db.showIcon and style ~= "classic" and style ~= "thin"

    f.ground:SetShown(style == "line" or style == "pixel" or style == "neon" or style == "glass"
        or style == "gradient" or style == "shadow")
    local dens = (db.bgAlpha or 92) / 92
    if style == "pixel" then
        f.ground:SetVertexColor(0.07, 0.07, 0.075, math.min(1, 0.92 * dens))
    elseif style == "glass" then
        f.ground:SetVertexColor(0.05, 0.07, 0.11, math.min(1, 0.5 * dens))
    elseif style == "neon" then
        f.ground:SetVertexColor(0.010, 0.010, 0.016, math.min(1, 0.88 * dens))
    else
        f.ground:SetVertexColor(0.022, 0.025, 0.034, math.min(1, 0.92 * dens))
    end
    local Look = NS.Look
    local gr, gg, gb = Look:Color("castbar", "bg")
    if gr then f.ground:SetVertexColor(gr, gg, gb, math.min(1, 0.92 * dens)) end
    if (db.nameSize or 0) > 0 then
        NS.LSetFont(f.name, "castbar", db.nameSize, "OUTLINE")
        NS.LSetFont(f.timer, "castbar", db.nameSize, "OUTLINE")
    end
    local tr, tg, tb = Look:Color("castbar", "text")
    if not tr then tr, tg, tb = S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3] end
    f.name:SetTextColor(tr, tg, tb)
    f.timer:SetTextColor(tr, tg, tb)

    f.top:SetShown(style == "line")
    f.bottom:SetShown(style == "line" or style == "underline")
    f.bottom:SetHeight(style == "underline" and 2 or 1)
    if style == "underline" then
        f.bottom:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.95, G[1], G[2], G[3], 0.95)
    else
        f.bottom:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.40, A[1], A[2], A[3], 0.05)
    end

    local framed = style == "pixel" or style == "outline" or style == "glass"
    local thickness = style == "outline" and 2 or 1
    f.edges[1]:SetHeight(thickness)
    f.edges[2]:SetHeight(thickness)
    f.edges[3]:SetWidth(thickness)
    f.edges[4]:SetWidth(thickness)
    for _, line in ipairs(f.edges) do
        line:SetShown(framed)
        if style == "glass" then
            line:SetVertexColor(A[1] * 0.8, A[2] * 0.8, A[3] * 0.8, 0.95)
        elseif style == "outline" then
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)
        else
            line:SetVertexColor(0, 0, 0, 1)
        end
    end
    for _, line in ipairs(f.iconEdges) do line:SetShown((style == "pixel" or style == "outline") and f.showIcon) end
    f.softShadow:SetShown(style == "shadow")

    local er, eg, eb = Look:Color("castbar", "border")
    if er then
        for _, line in ipairs(f.edges) do line:SetVertexColor(er, eg, eb, 1) end
        f.top:SetGradientAlpha("HORIZONTAL", er, eg, eb, 1, er, eg, eb, 1)
        f.bottom:SetGradientAlpha("HORIZONTAL", er, eg, eb, 1, er, eg, eb, 1)
    end
    for _, texture in ipairs(f.glow) do texture:SetShown(style == "neon") end
    PaintGlow(f.glow, A[1], A[2], A[3], 0.45)
    f.border:SetShown(style == "classic")

    NS.Look:SetBar(f.status, "castbar", (style == "classic" or style == "pixel") and SHADED or WHITE)
    local railAlpha = 0.95
    if style == "classic" then railAlpha = 0.7 elseif style == "glass" then railAlpha = 0.4 elseif style == "underline" then railAlpha = 0.25 end
    f.rail:SetVertexColor(0.055, 0.060, 0.080, railAlpha)

    f.icon:ClearAllPoints()
    f.status:ClearAllPoints()
    f.name:ClearAllPoints()
    f.timer:ClearAllPoints()
    f.spark:ClearAllPoints()

    local statusHeight = height - 2

    local right = db.iconSide == "right"

    if style == "pixel" or style == "outline" then
        local inset = style == "outline" and 2 or 1
        if right then
            f.icon:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
            f.icon:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 4, 0)
        else
            f.icon:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0)
            f.icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -4, 0)
        end
        f.icon:SetWidth(height)
        f.status:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
        f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
    elseif style == "classic" then
        f.status:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        statusHeight = height
        f.border:ClearAllPoints()
        f.border:SetSize(width * 256 / 195, height * 64 / 13)
        f.border:SetPoint("TOP", f, "TOP", 0, 28 * height / 13)
    elseif style == "thin" then
        statusHeight = 6
        f.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        f.status:SetHeight(statusHeight)
    elseif right then
        f.icon:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        f.icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        f.icon:SetWidth(height - 2)
        f.status:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        if f.showIcon then
            f.status:SetPoint("BOTTOMRIGHT", f.icon, "BOTTOMLEFT", -2, 0)
        else
            f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        end
    else
        f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        f.icon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
        f.icon:SetWidth(height - 2)
        if f.showIcon then
            f.status:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 2, 0)
        else
            f.status:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        end
        f.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    end

    if style == "thin" then
        f.name:SetPoint("BOTTOMLEFT", f.status, "TOPLEFT", 0, 3)
        f.timer:SetPoint("BOTTOMRIGHT", f.status, "TOPRIGHT", 0, 3)
        f.name:SetPoint("RIGHT", f.timer, "LEFT", -6, 0)
    elseif style == "classic" then
        f.timer:SetPoint("RIGHT", f.status, "RIGHT", -4, 0)
        f.name:SetPoint("LEFT", f.status, "LEFT", 22, 0)
        f.name:SetPoint("RIGHT", f.status, "RIGHT", -22, 0)
    else
        f.timer:SetPoint("RIGHT", f.status, "RIGHT", -6, 0)
        f.name:SetPoint("LEFT", f.status, "LEFT", 6, 0)
        f.name:SetPoint("RIGHT", f.timer, "LEFT", -6, 0)
    end
    f.name:SetJustifyH((style == "classic" or db.textAlign == "center") and "CENTER" or "LEFT")

    if style == "classic" then
        f.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        f.spark:SetBlendMode("ADD")
        f.spark:SetVertexColor(1, 1, 1, 1)
        f.spark:SetSize(32 * height / 13, 32 * height / 13)
    else
        f.spark:SetTexture(WHITE)
        f.spark:SetBlendMode(style == "neon" and "ADD" or "BLEND")
        f.spark:SetVertexColor(G[1], G[2], G[3], 0.9)
        f.spark:SetSize(style == "neon" and 4 or 2, statusHeight)
    end
    f.spark:SetPoint("CENTER", f.status, "LEFT", 0, 0)
    f.spark:SetShown(db.spark ~= false)

    f.icon:SetShown(f.showIcon)
end

local function CastColor(unit, channel, locked)
    local db = Settings()
    local S = NS.Styling
    if locked then
        local c = db.lockedColor
        return c[1], c[2], c[3]
    end
    if db.colorMode == "class" and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then return c.r, c.g, c.b end
    elseif db.colorMode == "custom" then
        local c = channel and db.channelColor or db.castColor
        return c[1], c[2], c[3]
    end
    return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
end

local function Latency()
    local _, _, home, world = GetNetStats()
    return math.max(home or 0, world or 0) / 1000
end

function CastBar:PlaceLatency(f, unit, span)
    local db = Settings()
    if unit ~= "player" or not db.latency or not span or span <= 0 then
        f.lag:Hide()
        return
    end
    local width = f.status:GetWidth() or 0
    local share = math.min(1, Latency() / span)
    if width <= 0 or share <= 0 then
        f.lag:Hide()
        return
    end
    f.lag:ClearAllPoints()
    if f.channel then
        f.lag:SetPoint("TOPLEFT", f.status, "TOPLEFT", 0, 0)
        f.lag:SetPoint("BOTTOMLEFT", f.status, "BOTTOMLEFT", 0, 0)
    else
        f.lag:SetPoint("TOPRIGHT", f.status, "TOPRIGHT", 0, 0)
        f.lag:SetPoint("BOTTOMRIGHT", f.status, "BOTTOMRIGHT", 0, 0)
    end
    f.lag:SetWidth(math.max(1, width * share))
    f.lag:Show()
end

function CastBar:Fill(f, r, g, b)
    local style = f.style
    if style == "classic" and not f.locked and Settings().colorMode == "theme" then
        r, g, b = 1, 0.7, 0
    end
    if not f.locked then
        local lr, lg, lb = NS.Look:Color("castbar", "bar")
        if lr then r, g, b = lr, lg, lb end
    end

    if style == "neon" or style == "gradient" then
        f.status:SetStatusBarColor(r, g, b, 1)
        f.status:GetStatusBarTexture():SetGradientAlpha("HORIZONTAL", r * 0.3, g * 0.3, b * 0.3, 1, r, g, b, 1)
    elseif style == "glass" then
        f.status:SetStatusBarColor(r, g, b, 0.6)
    else
        f.status:SetStatusBarColor(r, g, b, 0.9)
    end
end

function CastBar:Restyle()
    for _, f in pairs(bars) do self:Style(f) end
end

function CastBar:Wake()
    if self.ticker then self.ticker:Show() end
end

function CastBar:Start(unit, channel)
    if not Enabled() then return end

    local db = Settings()
    local store = db.units[unit]
    if not store or not store.enabled then return end

    local f = self:Build(unit)
    if not f then return end

    local name, _, text, texture, startTime, endTime, _, _, notInterruptible

    if channel then
        name, _, text, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
    else
        name, _, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    end

    if not name then
        f:Hide()
        return
    end

    local S = NS.Styling

    f.startTime = startTime / 1000
    f.endTime = endTime / 1000
    f.channel = channel and true or false
    f.casting = true
    f.fading = nil
    f.failed = nil
    f:SetAlpha(1)

    if f.style ~= CastStyle() then self:Style(f) end

    f.name:SetText(text or name)
    f.icon:SetTexture(texture)
    f.icon:SetShown(f.showIcon and true or false)
    f.timer:SetShown(db.showTime)
    f.spark:SetShown(db.spark ~= false)

    f.locked = notInterruptible and true or false
    self:Fill(f, CastColor(unit, channel, notInterruptible))

    f:Show()
    self:PlaceLatency(f, unit, f.endTime - f.startTime)

    self:Wake()
end

function CastBar:Preview()
    local f = self:Build("player")
    if not f then return end

    local S = NS.Styling
    self:Style(f)

    f.startTime = GetTime()
    f.endTime = f.startTime + 3
    f.channel = false
    f.locked = false
    f.casting = true
    f.fading = nil
    f.failed = nil
    f:SetAlpha(1)
    f.name:SetText(L["Пример заклинания"])
    f.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    f.icon:SetShown(f.showIcon and true or false)
    f.timer:SetShown(Settings().showTime)
    f.spark:SetShown(Settings().spark ~= false)
    self:Fill(f, CastColor("player", false, false))
    f:Show()
    self:PlaceLatency(f, "player", 3)
    self:Wake()
end

function CastBar:Stop(unit)
    local f = bars[unit]
    if f then
        f.casting = nil
        f.fading = nil
        f:Hide()
        f:SetAlpha(1)
    end
end

function CastBar:Finish(unit, kind)
    local f = bars[unit]
    if not f then return end
    local db = Settings()
    local now = GetTime()

    if not f.casting then
        if kind ~= "done" and db.flash and f.fading and not f.failed and now - f.fading < 0.15 then
            f.casting = true
        else
            if not f.fading then f:Hide() end
            return
        end
    end
    f.casting = nil

    if kind ~= "done" and db.flash then
        f.failed = true
        f.locked = true
        f.status:SetValue(1)
        f.spark:Hide()
        f.lag:Hide()
        f.name:SetText(kind == "interrupt" and L["Прервано"] or L["Не удалось"])
        f.timer:SetText("")
        self:Fill(f, 0.85, 0.20, 0.20)
        f.fading = now
        self:Wake()
        return
    end

    f.failed = nil
    if db.fade then
        f.status:SetValue(f.channel and 0 or 1)
        f.spark:Hide()
        f.fading = now
        self:Wake()
    else
        f:Hide()
    end
end

local function FormatTime(f, now, span)
    local format = Settings().timeFormat
    local left = math.max(0, f.endTime - now)
    if format == "left" then
        return string.format("%.1f", left)
    elseif format == "elapsed" then
        return string.format("%.1f", math.max(0, now - f.startTime))
    end
    return string.format("%.1f / %.1f", left, span)
end

function CastBar:Update(unit)
    local f = bars[unit]
    if not f or not f:IsShown() then return end

    local now = GetTime()

    if f.fading then
        local t = now - f.fading
        local hold = f.failed and 0.6 or 0.1
        if t < hold then
            f:SetAlpha(1)
        elseif t < hold + 0.35 then
            f:SetAlpha(1 - (t - hold) / 0.35)
        else
            f.fading = nil
            f.failed = nil
            f:Hide()
            f:SetAlpha(1)
        end
        return
    end

    if not f.endTime then return end

    local span = f.endTime - f.startTime
    if span <= 0 then span = 1 end

    if now >= f.endTime then
        self:Finish(unit, "done")
        return
    end

    local done = now - f.startTime
    local share = f.channel and (1 - done / span) or (done / span)

    f.status:SetValue(share)
    f.spark:SetPoint("CENTER", f.status, "LEFT", share * f.status:GetWidth(), 0)

    if f.timer:IsShown() then
        f.timer:SetText(FormatTime(f, now, span))
    end
end

function CastBar:CreateSample(parent)
    local db = Settings()
    if not db then return end
    local f = CreateCastFrame(parent, "player", nil, db.units.player)
    f.sample = true
    f:Show()
    return f
end

function CastBar:PaintSample(f)
    local db = Settings()
    if not db or not f then return end
    local store = db.units.player
    f:SetScale(math.min(1, 280 / math.max(store.width, 1)))
    self:Style(f)
    f.startTime = 0
    f.endTime = 3
    f.channel = false
    f.locked = false
    f.name:SetText(L["Пример заклинания"])
    f.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    f.icon:SetShown(f.showIcon and true or false)
    f.timer:SetShown(db.showTime)
    f.timer:SetText(FormatTime(f, 1.86, 3))
    f.spark:SetShown(db.spark ~= false)
    self:Fill(f, CastColor("player", false, false))
    f.status:SetValue(0.62)
    f.spark:ClearAllPoints()
    f.spark:SetPoint("CENTER", f.status, "LEFT", 0.62 * (f.status:GetWidth() or 0), 0)
    self:PlaceLatency(f, "player", 3)
    f:Show()
end

function CastBar:HideBlizzard()
    local db = Settings()
    if not db or not db.enabled then return end

    local frame = _G.CastingBarFrame
    if frame and not frame.narciSilenced then
        frame.narciSilenced = true
        frame:UnregisterAllEvents()
        frame:Hide()
        frame:SetScript("OnShow", function(self) self:Hide() end)
    end
end

function CastBar:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        for _, unit in ipairs(ORDER) do
            if db.units[unit] and db.units[unit].enabled then self:Build(unit) end
        end
        self:HideBlizzard()
        NS.Print("полоса заклинания включена")
    else
        for _, f in pairs(bars) do f:Hide() end
        NS.Print("полоса заклинания выключена, окно клиента вернётся после /reload")
    end
end

function CastBar:SetUnitOption(unit, field, value)
    local db = Settings()
    local store = db and db.units[unit]
    if not store then return end

    store[field] = value

    local f = bars[unit]
    if not f and field == "enabled" and value and Enabled() then f = self:Build(unit) end
    if f then
        if field == "enabled" and not value then self:Stop(unit) end
        self:Style(f)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("UNIT_SPELLCAST_START")
driver:RegisterEvent("UNIT_SPELLCAST_STOP")
driver:RegisterEvent("UNIT_SPELLCAST_FAILED")
driver:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
driver:RegisterEvent("UNIT_SPELLCAST_DELAYED")
driver:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
driver:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
driver:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("PLAYER_FOCUS_CHANGED")

driver:SetScript("OnEvent", function(self, event, unit)
    if not Enabled() then return end

    if event == "PLAYER_LOGIN" then
        if NS.After then
            NS.After(3, function()
                local db = Settings()
                for _, key in ipairs(ORDER) do
                    if db.units[key] and db.units[key].enabled then CastBar:Build(key) end
                end
                CastBar:HideBlizzard()
            end)
        end
        return
    end

    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
        local which = event == "PLAYER_TARGET_CHANGED" and "target" or "focus"
        if UnitCastingInfo(which) then
            CastBar:Start(which, false)
        elseif UnitChannelInfo(which) then
            CastBar:Start(which, true)
        else
            CastBar:Stop(which)
        end
        return
    end

    if unit ~= "player" and unit ~= "target" and unit ~= "focus" then return end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
        CastBar:Start(unit, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        CastBar:Start(unit, true)
    elseif UnitCastingInfo(unit) then
        CastBar:Start(unit, false)
    elseif UnitChannelInfo(unit) then
        CastBar:Start(unit, true)
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        CastBar:Finish(unit, "interrupt")
    elseif event == "UNIT_SPELLCAST_FAILED" then
        CastBar:Finish(unit, "fail")
    else
        CastBar:Finish(unit, "done")
    end
end)

local ticker = CreateFrame("Frame")
ticker:Hide()

ticker:SetScript("OnUpdate", function(self)
    local running = false

    for _, unit in ipairs(ORDER) do
        local f = bars[unit]
        if f and f:IsShown() and (f.endTime or f.fading) then
            CastBar:Update(unit)
            if f:IsShown() then running = true end
        end
    end

    if not running then self:Hide() end
end)

CastBar.ticker = ticker
