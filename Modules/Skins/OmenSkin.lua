local addonName, NS = ...

local OmenSkin = {}
NS.OmenSkin = OmenSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local BACKDROP = {
    bgFile = WHITE,
    edgeFile = WHITE,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function Style()
    return NS.Styling
end

local OMEN_STYLES = { modern = true, classic = true, pixel = true, glass = true }
local SHADED = "Interface\\TargetingFrame\\UI-StatusBar"

local CLASSIC_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function OmenStyle()
    local style = NS.db and NS.db.omenStyle
    return OMEN_STYLES[style] and style or "modern"
end

local function Enabled()
    return not NS.db or NS.db.skinOmen ~= false
end

local function Omen()
    local omen = _G.Omen
    if type(omen) == "table" and omen.Anchor and omen.Title and omen.BarList then return omen end
end

local function BarSize()
    local db = _G.Omen and _G.Omen.db and _G.Omen.db.profile
    local size = db and db.Bar and db.Bar.FontSize
    return math.max(8, math.min(14, tonumber(size) or 10))
end

function OmenSkin:StyleFrames()
    local omen = Omen()
    if not omen then return end

    local S = Style()
    local style = OmenStyle()
    local alpha = ((NS.db and NS.db.omenAlpha) or 72) / 100
    local backdrop = style == "classic" and CLASSIC_BACKDROP or BACKDROP

    local r, g, b = 0.020, 0.023, 0.032
    local er, eg, eb, ea = S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9
    if style == "classic" then
        r, g, b = 0.06, 0.06, 0.10
        er, eg, eb, ea = 0.6, 0.6, 0.65, 1
    elseif style == "pixel" then
        r, g, b = 0.07, 0.07, 0.075
        er, eg, eb, ea = 0, 0, 0, 1
    elseif style == "glass" then
        r, g, b = 0.05, 0.07, 0.11
        alpha = alpha * 0.7
        er, eg, eb, ea = S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.95
    end

    omen.Title:SetBackdrop(backdrop)
    omen.Title:SetBackdropColor(r, g, b, 0.95)
    omen.Title:SetBackdropBorderColor(er, eg, eb, ea)

    omen.BarList:SetBackdrop(backdrop)
    omen.BarList:SetBackdropColor(r, g, b, alpha)
    omen.BarList:SetBackdropBorderColor(er, eg, eb, ea)

    if not omen.Title.narciAccent then
        local accent = omen.Title:CreateTexture(nil, "OVERLAY")
        accent:SetPoint("BOTTOMLEFT", omen.Title, "BOTTOMLEFT", 1, 0)
        accent:SetPoint("BOTTOMRIGHT", omen.Title, "BOTTOMRIGHT", -1, 0)
        accent:SetHeight(1)
        accent:SetTexture(WHITE)
        accent:SetGradientAlpha("Horizontal",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)
        omen.Title.narciAccent = accent

        if S.CreateShadow then omen.Title.narciShadow = S.CreateShadow(omen.Anchor, 5, 0.4) end
    end

    omen.Title.narciAccent:SetShown(style == "modern" or style == "glass")
    if omen.Title.narciShadow then omen.Title.narciShadow:SetShown(style ~= "classic") end

    if omen.TitleText then
        omen.TitleText:SetFont(NS.FONT, NS.FS(11), "")
        omen.TitleText:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end
end

local function StyleBar(bar, force)
    if not bar or not bar.texture then return end
    if bar.narciStyled and not force then return end
    bar.narciStyled = true

    local S = Style()
    local size = BarSize()

    local texture = (OmenStyle() == "classic" or OmenStyle() == "pixel") and SHADED or WHITE
    bar.texture:SetTexture(texture)
    if bar.texture2 then bar.texture2:SetTexture(texture) end

    if not bar.narciSheen then
        local sheen = bar:CreateTexture(nil, "OVERLAY")
        sheen:SetPoint("TOPLEFT", bar.texture, "TOPLEFT", 0, 0)
        sheen:SetPoint("BOTTOMRIGHT", bar.texture, "RIGHT", 0, 0)
        sheen:SetTexture(WHITE)
        sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.10)
        bar.narciSheen = sheen

        local ground = bar:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(bar)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(0.05, 0.055, 0.075, 0.6)
        bar.narciGround = ground
    end

    bar.narciSheen:SetShown((not NS.db or NS.db.omenSheen ~= false) and OmenStyle() ~= "classic")
    bar.narciGround:SetShown(OmenStyle() ~= "classic")

    for _, key in ipairs({ "Text1", "Text2", "Text3" }) do
        local text = bar[key]
        if text then
            text:SetFont(NS.FONT, size, "OUTLINE")
            text:SetShadowOffset(0, 0)
        end
    end

    if bar.Text1 then bar.Text1:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]) end
end

function OmenSkin:StyleBars(force)
    local omen = Omen()
    if not omen then return end

    local count = omen.BarList:GetNumChildren()
    if not force and count == self.barCount then return end
    self.barCount = count

    for _, child in ipairs({ omen.BarList:GetChildren() }) do
        StyleBar(child, force)
    end
end

function OmenSkin:Refresh()
    if not Enabled() then return end
    self:StyleFrames()
    self:StyleBars(true)
end

function OmenSkin:Apply()
    if not Enabled() then return end

    local omen = Omen()
    if not omen then return end

    self:StyleFrames()
    self:StyleBars(true)

    if self.hooked then return end
    self.hooked = true

    for _, name in ipairs({ "UpdateBackdrop", "UpdateTitleBar" }) do
        if type(omen[name]) == "function" then
            hooksecurefunc(omen, name, function() OmenSkin:StyleFrames() end)
        end
    end

    for _, name in ipairs({ "UpdateBarTextureSettings", "UpdateBarLabelSettings" }) do
        if type(omen[name]) == "function" then
            hooksecurefunc(omen, name, function() OmenSkin:StyleBars(true) end)
        end
    end

    if type(omen.UpdateBarsReal) == "function" then
        hooksecurefunc(omen, "UpdateBarsReal", function() OmenSkin:StyleBars(false) end)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Omen" then return end

    if NS.After then
        NS.After(1, function() OmenSkin:Apply() end)
    else
        OmenSkin:Apply()
    end
end)
