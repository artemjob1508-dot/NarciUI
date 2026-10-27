local addonName, NS = ...
local L = NS.L

local TooltipSkin = {}
NS.TooltipSkin = TooltipSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local TOOLTIPS = {
    "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "WorldMapTooltip", "FriendsTooltip", "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2", "AutoCompleteBox",
}

local function FillSettings()
    if not NS.db then return end

    if not NS.db.tooltip then NS.db.tooltip = {} end

    local db = NS.db.tooltip
    if db.enabled == nil then db.enabled = false end
    if db.colorByQuality == nil then db.colorByQuality = true end
    if db.cursorAnchor == nil then db.cursorAnchor = false end
    if db.hideInCombat == nil then db.hideInCombat = false end
    if db.showItemID == nil then db.showItemID = false end
    if db.showItemLevel == nil then db.showItemLevel = true end
    if db.showTarget == nil then db.showTarget = true end
    if db.healthBar == nil then db.healthBar = true end
    if db.guildRank == nil then db.guildRank = true end
    if db.unitBorder == nil then db.unitBorder = true end
    if db.showSpellID == nil then db.showSpellID = false end
    if db.showNpcID == nil then db.showNpcID = false end
    if db.auraCaster == nil then db.auraCaster = true end
    if db.sellPrice == nil then db.sellPrice = false end
    db.healthText = db.healthText or "none"
    db.healthHeight = db.healthHeight or 5
    db.scale = db.scale or 1
    db.style = db.style or "modern"
    db.styledStyle = db.styledStyle or "ornate"

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.tooltip
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local STYLES = {
    modern = true, classic = true, pixel = true, glass = true, minimal = true,
    neon = true, stripe = true, card = true, gradient = true, flat = true, double = true, soft = true,
}

local STYLED = {
    ornate = { corners = "filigree", crest = true, header = true, shade = 0.45, sheen = true },
    royal = { corners = "geo", double = true, gold = true, crest = true, footer = "filigree", shade = 0.35 },
    runic = { corners = "rune", pattern = "scales", shade = 0.6, footer = "chain" },
    arcane = { corners = "rune", halo = true, sheen = true, crest = true, header = true },
    banner = { corners = "filigree", band = true, crest = true, footer = "orb", shade = 0.3 },
    grove = { corners = "leaf", pattern = "dots", band = true, footer = "wave", shade = 0.5 },
}

local EXTRA = { double = { double = true } }

local ORN_CORNERS = {
    { "TOPLEFT", 1, -1, 0, 1, 0, 1 },
    { "TOPRIGHT", -1, -1, 1, 0, 0, 1 },
    { "BOTTOMLEFT", 1, 1, 0, 1, 1, 0 },
    { "BOTTOMRIGHT", -1, 1, 1, 0, 1, 0 },
}

local CLASSIC_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
}

local function TipStyle()
    local db = Settings()
    if not db then return "modern" end
    if TooltipSkin.forceStyle then return TooltipSkin.forceStyle end
    if NS.Styling.DECOR then
        return STYLED[db.styledStyle] and db.styledStyle or "ornate"
    end
    return STYLES[db.style] and db.style or "modern"
end

local function Ornaments(frame)
    if frame.narciOrn then return frame.narciOrn end

    local S = NS.Styling
    local o = { corners = {} }
    frame.narciOrn = o

    local shade = frame:CreateTexture(nil, "BORDER")
    shade:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    shade:SetTexture(S.Media("DecorVignette"))
    o.shade = shade

    o.pattern = S.TileArea(frame, "BORDER", -1, 2)

    local sheen = frame:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    sheen:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    sheen:SetTexture(S.Media("DecorSheen"))
    sheen:SetBlendMode("ADD")
    o.sheen = sheen

    local header = frame:CreateTexture(nil, "BORDER")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -2)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -2)
    header:SetHeight(40)
    header:SetTexture(S.Media("DecorHeader"))
    header:SetBlendMode("ADD")
    o.header = header

    local band = frame:CreateTexture(nil, "BORDER")
    band:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    band:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    band:SetHeight(24)
    band:SetTexture(WHITE)
    o.band = band

    for _, c in ipairs(ORN_CORNERS) do
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetSize(22, 22)
        t:SetPoint(c[1], frame, c[1], c[2] * 2, c[3] * 2)
        t:SetTexCoord(c[4], c[5], c[6], c[7])
        o.corners[#o.corners + 1] = t
    end

    local crest = frame:CreateTexture(nil, "OVERLAY")
    crest:SetSize(64, 16)
    crest:SetPoint("CENTER", frame, "TOP", 0, -1)
    crest:SetTexture(S.Media("DecorCrest"))
    o.crest = crest

    local footer = frame:CreateTexture(nil, "OVERLAY")
    footer:SetSize(110, 12)
    footer:SetPoint("CENTER", frame, "BOTTOM", 0, 2)
    o.footer = footer

    local inner = CreateFrame("Frame", nil, frame)
    inner:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    inner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    inner:EnableMouse(false)
    o.inner = inner
    o.innerEdges = S.CreateEdges(inner, "OVERLAY", 1, 1, 1, 1)

    o.halo = S.GlowPieces(frame, 8, "BACKGROUND", "ADD", true)

    frame:HookScript("OnSizeChanged", function(self) TooltipSkin:FitOrnaments(self) end)

    return o
end

function TooltipSkin:LookOrnaments(frame, spec)
    local o = frame.narciOrn

    if not spec then
        if not o then return end
        o.spec = nil
        for _, key in ipairs({ "shade", "pattern", "sheen", "header", "band", "crest", "footer", "inner" }) do o[key]:Hide() end
        for _, t in ipairs(o.corners) do t:Hide() end
        for _, t in ipairs(o.halo) do t:Hide() end
        return
    end

    o = Ornaments(frame)
    o.spec = spec

    local S = NS.Styling
    local dr, dg, db = S.DecorColor(true)

    o.shade:SetVertexColor(0, 0, 0, spec.shade or 0)
    o.shade:SetShown((spec.shade or 0) > 0)

    local pattern = spec.pattern and S.PATTERNS[spec.pattern]
    if pattern then
        o.pattern:SetTexture(S.Media(pattern))
        local pr, pg, pb = S.DecorColor(true)
        o.pattern:SetVertexColor(pr, pg, pb, 0.22)
    end
    o.pattern:SetShown(pattern ~= nil)

    o.sheen:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)
    o.sheen:SetShown(spec.sheen and true or false)
    o.header:SetVertexColor(dr, dg, db, 0.16)

    local corner = S.Media(S.CORNER_STYLES[spec.corners or ""] or "DecorCorner")
    for _, t in ipairs(o.corners) do
        t:SetTexture(corner)
        t:SetVertexColor(dr, dg, db, 0.85)
    end

    o.crest:SetVertexColor(dr, dg, db, 0.95)
    if spec.footer then
        o.footer:SetTexture(S.Media(S.DIVIDER_STYLES[spec.footer] or "DecorDivider"))
        o.footer:SetVertexColor(dr, dg, db, 0.85)
    end

    o.inner:SetShown(spec.double and true or false)
    for _, t in ipairs(o.halo) do t:SetShown(spec.halo and true or false) end
    o.band:SetShown(spec.band and true or false)

    self:FitOrnaments(frame)
end

function TooltipSkin:FitOrnaments(frame)
    local o = frame.narciOrn
    local spec = o and o.spec
    if not spec then return end

    local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
    local big = w >= 110 and h >= 44

    for _, t in ipairs(o.corners) do t:SetShown(spec.corners ~= nil and big) end
    o.crest:SetShown((spec.crest and w >= 90) and true or false)
    o.footer:SetShown((spec.footer and w >= 130) and true or false)
    o.header:SetShown((spec.header and w > 0) and true or false)

    if w > 0 then
        local span = math.min(1, (w / 40) / 16)
        local left = (1 - span) / 2
        o.header:SetTexCoord(left, left + span, 0, 1)
    end
end

function TooltipSkin:Skin(frame)
    if not frame or frame.narciTooltip then return end
    frame.narciTooltip = true

    local S = NS.Styling

    frame:SetBackdrop(nil)

    local ground = frame:CreateTexture(nil, "BACKGROUND")
    ground:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    ground:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL",
        0.012, 0.014, 0.020, 0.96,
        0.034, 0.038, 0.052, 0.96)

    local wash = frame:CreateTexture(nil, "BORDER")
    wash:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    wash:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    wash:SetHeight(26)
    wash:SetTexture(WHITE)

    local edges = S.CreateEdges(frame, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)

    local glowLeft = frame:CreateTexture(nil, "ARTWORK")
    glowLeft:SetHeight(2)
    glowLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    glowLeft:SetPoint("TOPRIGHT", frame, "TOP", 0, 0)
    glowLeft:SetTexture(WHITE)

    local glowRight = frame:CreateTexture(nil, "ARTWORK")
    glowRight:SetHeight(2)
    glowRight:SetPoint("TOPLEFT", frame, "TOP", 0, 0)
    glowRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    glowRight:SetTexture(WHITE)

    if S.CreateSoftShadow then frame.narciShadow = S.CreateSoftShadow(frame, 7, 0.55) end

    local stripe = frame:CreateTexture(nil, "ARTWORK")
    stripe:SetWidth(3)
    stripe:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    stripe:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    stripe:SetTexture(WHITE)

    local sheen = frame:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    sheen:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    sheen:SetHeight(18)
    sheen:SetTexture(WHITE)
    sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.08)

    frame.narciGround = ground
    frame.narciEdges = edges
    frame.narciWash = wash
    frame.narciGlow = { glowLeft, glowRight }
    frame.narciStripe = stripe
    frame.narciSheen = sheen

    self:Look(frame)
    self:Paint(frame)
end

function TooltipSkin:Look(frame)
    if not frame or not frame.narciGround then return end

    local style = TipStyle()
    local classic = style == "classic"

    if classic then
        frame:SetBackdrop(CLASSIC_BACKDROP)
        frame:SetBackdropColor(0.06, 0.06, 0.10, 0.92)
    else
        frame:SetBackdrop(nil)
    end

    local ground = frame.narciGround
    ground:SetShown(not classic)
    if style == "pixel" then
        ground:SetGradientAlpha("VERTICAL", 0.07, 0.07, 0.075, 0.95, 0.07, 0.07, 0.075, 0.95)
    elseif style == "glass" then
        ground:SetGradientAlpha("VERTICAL", 0.04, 0.06, 0.10, 0.62, 0.08, 0.10, 0.16, 0.62)
    elseif style == "minimal" then
        ground:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.86, 0, 0, 0, 0.86)
    elseif style == "neon" then
        ground:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.92, 0.01, 0.01, 0.02, 0.92)
    elseif style == "gradient" then
        local A = NS.Styling.ACCENT
        ground:SetGradientAlpha("VERTICAL", 0.012, 0.014, 0.020, 0.96, A[1] * 0.22, A[2] * 0.22, A[3] * 0.22, 0.96)
    elseif style == "flat" then
        local A = NS.Styling.ACCENT
        ground:SetGradientAlpha("VERTICAL", A[1] * 0.10, A[2] * 0.10, A[3] * 0.10, 0.95, A[1] * 0.10, A[2] * 0.10, A[3] * 0.10, 0.95)
    elseif style == "soft" then
        ground:SetGradientAlpha("VERTICAL", 0.03, 0.03, 0.04, 0.90, 0.05, 0.05, 0.065, 0.90)
    else
        ground:SetGradientAlpha("VERTICAL", 0.012, 0.014, 0.020, 0.96, 0.034, 0.038, 0.052, 0.96)
    end
    local gr, gg, gb = NS.Look:Color("tooltip", "bg")
    if gr then
        ground:SetGradientAlpha("VERTICAL", gr, gg, gb, 0.95, gr, gg, gb, 0.95)
        if classic then frame:SetBackdropColor(gr, gg, gb, 0.92) end
    end

    local styled = STYLED[style] ~= nil

    for _, line in ipairs(frame.narciEdges) do
        line:SetShown(style == "modern" or style == "pixel" or style == "glass" or style == "neon"
            or style == "stripe" or style == "card" or style == "gradient" or style == "double" or styled)
    end
    frame.narciWash:SetShown(style == "modern" or style == "card" or style == "soft")
    for _, line in ipairs(frame.narciGlow) do
        line:SetShown(style == "modern" or style == "glass" or style == "neon" or style == "card" or styled)
    end
    if frame.narciShadow then
        frame.narciShadow:SetShown(style == "modern" or style == "glass" or style == "card" or style == "neon"
            or style == "flat" or style == "double" or style == "soft" or styled)
    end
    frame.narciStripe:SetShown(style == "minimal" or style == "stripe")
    frame.narciSheen:SetShown(style == "glass" or style == "card")

    self:LookOrnaments(frame, STYLED[style] or EXTRA[style])
end

function TooltipSkin:SkinHealthBar()
    local bar = _G.GameTooltipStatusBar
    if not bar or bar.narciBar then return end
    bar.narciBar = true

    local S = NS.Styling

    for _, region in ipairs({ bar:GetRegions() }) do
        if region:GetObjectType() == "Texture" and region ~= bar:GetStatusBarTexture() then
            region:SetTexture(nil)
        end
    end

    NS.Look:SetBar(bar, "tooltip", WHITE)
    bar:SetHeight(5)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 1, -3)
    bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -1, -3)

    local back = bar:CreateTexture(nil, "BACKGROUND")
    back:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    back:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    back:SetTexture(WHITE)
    back:SetVertexColor(0.012, 0.014, 0.020, 0.95)

    local sheen = bar:CreateTexture(nil, "ARTWORK")
    sheen:SetAllPoints(bar)
    sheen:SetTexture(WHITE)
    sheen:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, 1, 1, 1, 0.12)

    local text = _G.GameTooltipStatusBarText
    if text then text:Hide() end

    local value = bar:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(value, "tooltip", 9, "OUTLINE")
    value:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.narciText = value

    bar:HookScript("OnValueChanged", function(self)
        local color = self.narciColor
        if color then self:SetStatusBarColor(color[1], color[2], color[3]) end
        TooltipSkin:HealthText(self)
    end)
    self:ApplyHealthBar()
end

function TooltipSkin:ApplyHealthBar()
    local bar = _G.GameTooltipStatusBar
    if not bar or not bar.narciBar then return end
    local db = Settings()
    local height = db.healthHeight or 5
    if db.healthText ~= "none" and height < 10 then height = 10 end
    bar:SetHeight(height)
    NS.LSetFont(bar.narciText, "tooltip", math.max(8, math.min(12, height - 1)), "OUTLINE")
    self:HealthText(bar)
end

local function Short(value)
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(math.floor(value))
end

function TooltipSkin:HealthText(bar)
    local text = bar.narciText
    if not text then return end
    local mode = Settings().healthText or "none"
    local _, maxValue = bar:GetMinMaxValues()
    local value = bar:GetValue()
    if mode == "none" or not maxValue or maxValue <= 0 then
        text:SetText("")
        return
    end
    local percent = math.floor(value / maxValue * 100 + 0.5) .. "%"
    if mode == "percent" then
        text:SetText(percent)
    elseif mode == "value" then
        text:SetText(Short(value) .. " / " .. Short(maxValue))
    else
        text:SetText(Short(value) .. " - " .. percent)
    end
end

local function NpcID(unit)
    local guid = UnitGUID(unit)
    if not guid or UnitIsPlayer(unit) then return end
    local kind = tonumber(guid:sub(5, 5), 16)
    if not kind then return end
    kind = kind % 8
    if kind ~= 3 and kind ~= 5 then return end
    return tonumber(guid:sub(9, 12), 16)
end

local GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

local function Money(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local rest = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. GOLD end
    if silver > 0 then parts[#parts + 1] = silver .. SILVER end
    if rest > 0 or #parts == 0 then parts[#parts + 1] = rest .. COPPER end
    return table.concat(parts, " ")
end

function TooltipSkin:AuraLines(tooltip, unit, index, filter)
    local db = Settings()
    if not Enabled() or not (db.showSpellID or db.auraCaster) then return end
    local name, _, _, _, _, _, _, caster, _, _, spellID = UnitAura(unit, index, filter)
    if not name then return end
    local added
    if db.auraCaster and caster and UnitExists(caster) then
        local r, g, b = 0.8, 0.8, 0.8
        if UnitIsPlayer(caster) then
            local _, class = UnitClass(caster)
            local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            if c then r, g, b = c.r, c.g, c.b end
        end
        tooltip:AddDoubleLine(L["Наложил"], UnitName(caster) or "?", 0.6, 0.62, 0.66, r, g, b)
        added = true
    end
    if db.showSpellID and spellID then
        tooltip:AddDoubleLine("ID", tostring(spellID), 0.6, 0.62, 0.66, 0.85, 0.86, 0.9)
        added = true
    end
    if added then tooltip:Show() end
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function UnitColor(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end

    if UnitIsTapped and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
        return 0.55, 0.55, 0.55
    end

    local reaction = UnitReaction(unit, "player")

    if reaction and reaction <= 3 then return 0.85, 0.28, 0.25 end
    if reaction == 4 then return 0.90, 0.78, 0.30 end

    local S = NS.Styling
    return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
end

function TooltipSkin:DecorateUnit(tooltip, unit)
    local S = NS.Styling
    local r, g, b = UnitColor(unit)
    local prefix = tooltip:GetName()

    local nameLine = _G[prefix .. "TextLeft1"]
    if nameLine then nameLine:SetTextColor(r, g, b) end

    local db = Settings()
    local guild, rank = nil, nil
    if UnitIsPlayer(unit) then guild, rank = GetGuildInfo(unit) end
    local level = UnitLevel(unit)
    local levelText = level and level > 0 and tostring(level) or nil

    for index = 2, tooltip:NumLines() do
        local line = _G[prefix .. "TextLeft" .. index]
        local text = line and line:GetText()

        if text then
            if guild and text:find(guild, 1, true) then
                line:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                if db.guildRank and rank and rank ~= "" and not text:find(rank, 1, true) then
                    line:SetText(text .. "  |cff9a9ca3" .. rank .. "|r")
                end
                guild = nil
            elseif levelText and text:find(levelText, 1, true) then
                line:SetTextColor(0.78, 0.78, 0.82)
                levelText = nil
            end
        end
    end

    local target = unit .. "target"

    if db.showTarget and UnitExists(target) then
        local label

        if UnitIsUnit(target, "player") then
            label = "|cffff5f5f" .. L["Вы"] .. "|r"
        else
            local tr, tg, tb = UnitColor(target)
            label = Hex(tr, tg, tb) .. (UnitName(target) or "?") .. "|r"
        end

        tooltip:AddLine(L["Цель"] .. ": " .. label, S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if db.showNpcID then
        local npc = NpcID(unit)
        if npc then tooltip:AddDoubleLine("ID", tostring(npc), 0.6, 0.62, 0.66, 0.85, 0.86, 0.9) end
    end

    self:Paint(tooltip, r, g, b, true)

    local bar = _G.GameTooltipStatusBar
    if bar and bar.narciBar then
        local hr, hg, hb = r * 0.9, g * 0.9, b * 0.9
        local cr, cg, cb = NS.Look:Color("tooltip", "bar")
        if cr then hr, hg, hb = cr, cg, cb end
        bar.narciColor = { hr, hg, hb }
        bar:SetStatusBarColor(hr, hg, hb)
        bar:SetAlpha(db.healthBar and 1 or 0)
    end

    tooltip:Show()
end

function TooltipSkin:Paint(frame, r, g, b, unitColor)
    if not frame or not frame.narciEdges then return end

    local full = unitColor and r ~= nil and Settings().unitBorder ~= false

    local S = NS.Styling
    local tinted = r ~= nil
    local style = TipStyle()

    r = r or S.ACCENT[1]
    g = g or S.ACCENT[2]
    b = b or S.ACCENT[3]

    if style == "classic" then
        if tinted then
            frame:SetBackdropBorderColor(r, g, b, 1)
        else
            frame:SetBackdropBorderColor(1, 1, 1, 1)
        end
    end

    frame.narciStripe:SetVertexColor(r, g, b, 1)

    for _, line in ipairs(frame.narciEdges) do
        if style == "neon" then
            line:SetVertexColor(r, g, b, 1)
        elseif style == "pixel" then
            if tinted then
                line:SetVertexColor(r, g, b, 1)
            else
                line:SetVertexColor(0, 0, 0, 1)
            end
        elseif style == "glass" and not tinted then
            line:SetVertexColor(S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.95)
        elseif full then
            line:SetVertexColor(r, g, b, 1)
        elseif tinted then
            line:SetVertexColor(r * 0.55 + S.BORDER[1] * 0.45, g * 0.55 + S.BORDER[2] * 0.45, b * 0.55 + S.BORDER[3] * 0.45, 0.95)
        else
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
        end
    end

    if not tinted then
        local er, eg, eb = NS.Look:Color("tooltip", "border")
        if er then
            for _, line in ipairs(frame.narciEdges) do line:SetVertexColor(er, eg, eb, 1) end
            if style == "classic" then frame:SetBackdropBorderColor(er, eg, eb, 1) end
        end
    end

    if frame.narciGlow then
        frame.narciGlow[1]:SetGradientAlpha("HORIZONTAL", r, g, b, 0.05, r, g, b, 0.95)
        frame.narciGlow[2]:SetGradientAlpha("HORIZONTAL", r, g, b, 0.95, r, g, b, 0.05)
    end

    if frame.narciWash then
        frame.narciWash:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, tinted and 0.12 or 0.06)
    end

    local o = frame.narciOrn
    local spec = o and o.spec
    if spec then
        local ir, ig, ib = r, g, b
        if not tinted then
            if spec.gold then
                ir, ig, ib = S.GOLD[1], S.GOLD[2], S.GOLD[3]
            else
                ir, ig, ib = S.DecorColor(true)
            end
        end
        for _, line in ipairs(o.innerEdges) do line:SetVertexColor(ir, ig, ib, 0.55) end
        local dr, dg, db = S.DecorColor(true)
        if full then dr, dg, db = r, g, b end
        for _, t in ipairs(o.corners) do t:SetVertexColor(dr, dg, db, 0.85) end
        o.crest:SetVertexColor(dr, dg, db, 0.95)
        o.footer:SetVertexColor(dr, dg, db, 0.85)
        o.header:SetVertexColor(dr, dg, db, 0.16)
        for _, t in ipairs(o.halo) do t:SetVertexColor(r, g, b, tinted and 0.45 or 0.3) end
        o.band:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, tinted and 0.26 or 0.18)
    end
end

function TooltipSkin:ItemLines(tooltip, link)
    local db = Settings()
    if not db.showItemID and not db.showItemLevel and not db.sellPrice then return end

    local itemID = tonumber(link:match("item:(%d+)"))
    local _, _, _, itemLevel = GetItemInfo(link)
    local added = false

    if db.showItemLevel and itemLevel and itemLevel > 1 then
        local found = false
        local label = L["Уровень предмета"]
        local prefix = tooltip:GetName()

        for index = 2, tooltip:NumLines() do
            local line = _G[prefix .. "TextLeft" .. index]
            local text = line and line:GetText()
            if text and text:find(tostring(itemLevel), 1, true) and (text:find(label, 1, true) or text:find(ITEM_LEVEL_ABBR or "ilvl", 1, true)) then
                found = true
                break
            end
        end

        if not found then
            tooltip:AddDoubleLine(label, tostring(itemLevel), 0.6, 0.62, 0.66, 1, 0.82, 0.2)
            added = true
        end
    end

    if db.sellPrice and not (MerchantFrame and MerchantFrame:IsShown()) then
        local price = select(11, GetItemInfo(link))
        if price and price > 0 then
            tooltip:AddDoubleLine(L["Цена у торговца"], Money(price), 0.6, 0.62, 0.66, 1, 1, 1)
        end
    end

    if db.showItemID and itemID then
        tooltip:AddDoubleLine("ID", tostring(itemID), 0.6, 0.62, 0.66, 0.85, 0.86, 0.9)
        added = true
    end

    if added then tooltip:Show() end
end

function TooltipSkin:ApplyScale()
    local db = Settings()
    for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ShoppingTooltip3" }) do
        local frame = _G[name]
        if frame then frame:SetScale(db.scale or 1) end
    end
end

function TooltipSkin:Apply()
    if not Enabled() then return end

    local db = Settings()

    self:ApplyScale()

    for _, name in ipairs(TOOLTIPS) do
        self:Skin(_G[name])
    end

    self:SkinHealthBar()

    if self.hooked then return end
    self.hooked = true

    local tooltip = _G.GameTooltip
    if not tooltip then return end

    tooltip:HookScript("OnTooltipSetItem", function(self)
        if not Enabled() then return end

        local _, link = self:GetItem()
        if link then TooltipSkin:ItemLines(self, link) end

        if not link or not db.colorByQuality then
            TooltipSkin:Paint(self)
            return
        end

        local _, _, quality = GetItemInfo(link)
        local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]

        if color then
            TooltipSkin:Paint(self, color.r, color.g, color.b, true)
        else
            TooltipSkin:Paint(self)
        end
    end)

    tooltip:HookScript("OnTooltipSetSpell", function(self)
        if not Enabled() or not Settings().showSpellID then return end
        local _, _, spellID = self:GetSpell()
        if spellID then
            self:AddDoubleLine("ID", tostring(spellID), 0.6, 0.62, 0.66, 0.85, 0.86, 0.9)
            self:Show()
        end
    end)

    hooksecurefunc(tooltip, "SetUnitAura", function(self, unit, index, filter)
        TooltipSkin:AuraLines(self, unit, index, filter)
    end)
    hooksecurefunc(tooltip, "SetUnitBuff", function(self, unit, index, filter)
        TooltipSkin:AuraLines(self, unit, index, "HELPFUL" .. (filter and ("|" .. filter) or ""))
    end)
    hooksecurefunc(tooltip, "SetUnitDebuff", function(self, unit, index, filter)
        TooltipSkin:AuraLines(self, unit, index, "HARMFUL" .. (filter and ("|" .. filter) or ""))
    end)

    tooltip:HookScript("OnTooltipSetUnit", function(self)
        if not Enabled() then return end

        local _, unit = self:GetUnit()

        if db.hideInCombat and InCombatLockdown() and self:GetOwner() == UIParent then
            self:Hide()
            return
        end

        if not unit then
            TooltipSkin:Paint(self)
            return
        end

        TooltipSkin:DecorateUnit(self, unit)
    end)

    tooltip:HookScript("OnHide", function(self)
        TooltipSkin:Paint(self)

        local bar = _G.GameTooltipStatusBar
        if bar then bar.narciColor = nil end
    end)

    if type(_G.GameTooltip_SetDefaultAnchor) == "function" then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self, owner)
            if not Enabled() then return end
            if Settings().cursorAnchor then
                self:SetOwner(owner, "ANCHOR_CURSOR")
                return
            end
            local Movers = NS.Movers
            if Movers and Movers.HasTooltipAnchor and Movers:HasTooltipAnchor() then
                local anchor = Movers:TooltipAnchor()
                self:ClearAllPoints()
                self:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
            end
        end)
    end
end

function TooltipSkin:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Apply()
        NS.Print("подсказки в стиле аддона")
    else
        NS.Print("подсказки вернутся к клиентским после /reload")
    end
end

function TooltipSkin:CreateSample(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(230, 96)
    local lines = {}
    local data = {
        { "GameTooltipHeaderText", "" },
        { "GameTooltipText", "<Стражи Рассвета>" },
        { "GameTooltipText", "" },
        { "GameTooltipText", "Нацелен на: Торвальд" },
    }
    for index, entry in ipairs(data) do
        local line = frame:CreateFontString(nil, "OVERLAY", entry[1])
        line:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10 - (index - 1) * 18)
        line:SetText(L[entry[2]])
        lines[index] = line
    end
    frame.lines = lines
    self:Skin(frame)
    local bar = CreateFrame("StatusBar", nil, frame)
    NS.Look:SetBar(bar, "tooltip", WHITE)
    bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, -3)
    bar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3)
    local back = bar:CreateTexture(nil, "BACKGROUND")
    back:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    back:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    back:SetTexture(WHITE)
    back:SetVertexColor(0.012, 0.014, 0.020, 0.95)
    local value = bar:CreateFontString(nil, "OVERLAY")
    value:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.narciText = value
    frame.healthBar = bar
    return frame
end

function TooltipSkin:PaintSample(frame, opts)
    local db = Settings()
    if not db or not frame then return end
    self.forceStyle = opts and opts.field and db[opts.field] or nil
    local name = UnitName("player") or ""
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    frame.lines[1]:SetText(name)
    if color then frame.lines[1]:SetTextColor(color.r, color.g, color.b) end
    frame.lines[3]:SetText(string.format("%s %d %s", L["Уровень"], UnitLevel("player") or 80, UnitClass("player") or ""))
    local bar = frame.healthBar
    if bar then
        local height = db.healthHeight or 5
        if db.healthText ~= "none" and height < 10 then height = 10 end
        bar:SetHeight(height)
        NS.LSetFont(bar.narciText, "tooltip", math.max(8, math.min(12, height - 1)), "OUTLINE")
        local maxHealth = math.max(UnitHealthMax("player") or 1, 1)
        bar:SetMinMaxValues(0, maxHealth)
        bar:SetValue(math.min(UnitHealth("player") or maxHealth, maxHealth))
        bar:SetStatusBarColor(0.2, 0.85, 0.3)
        self:HealthText(bar)
    end
    local ok = pcall(function()
        self:Look(frame)
        if color then self:Paint(frame, color.r, color.g, color.b, true) else self:Paint(frame) end
        if self.FitOrnaments then self:FitOrnaments(frame) end
    end)
    self.forceStyle = nil
end

function TooltipSkin:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value

    if field == "scale" then self:ApplyScale() end

    if field == "style" or field == "styledStyle" then
        for _, name in ipairs(TOOLTIPS) do
            local frame = _G[name]
            if frame and frame.narciGround then
                self:Look(frame)
                self:Paint(frame)
            end
        end
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")

driver:SetScript("OnEvent", function()
    if not Enabled() then return end

    if NS.After then
        NS.After(2, function() TooltipSkin:Apply() end)
    end
end)
