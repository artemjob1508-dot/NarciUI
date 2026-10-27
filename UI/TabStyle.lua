local addonName, NS = ...

local TabStyle = {}
NS.TabStyle = TabStyle

local WHITE = "Interface\\Buttons\\WHITE8x8"

function TabStyle.Styled()
    return NS.Styling and NS.Styling.DECOR and true or false
end

function TabStyle.SpecArt()
    local tab
    if C_Talent and C_Talent.GetCurrentSpecTabIndex then
        local ok, index = pcall(C_Talent.GetCurrentSpecTabIndex)
        if ok then tab = index end
    end
    if not tab then
        local best = -1
        for i = 1, (GetNumTalentTabs and GetNumTalentTabs() or 0) do
            local _, _, points = GetTalentTabInfo(i)
            if (points or 0) > best then best, tab = points or 0, i end
        end
    end
    if not tab then return end
    local ok, _, _, _, background = pcall(GetTalentTabInfo, tab)
    if ok and background and background ~= "" then
        return "Interface\\TalentFrame\\" .. background .. "-TopLeft"
    end
end

local ART_ASPECT = 8

function TabStyle.CropArt(texture, w, h, aspect)
    if not w or not h or w <= 0 or h <= 0 then
        texture:SetTexCoord(0, 1, 0.15, 0.85)
        return
    end
    local span = math.min(1, (aspect or ART_ASPECT) * h / w)
    local top = (1 - span) / 2
    texture:SetTexCoord(0, 1, top, top + span)
end

function TabStyle.PaintArt(texture, name, w, h, aspect)
    local S = NS.Styling
    texture:SetTexture(S.Media(name))
    texture:SetVertexColor(1, 1, 1, S.ORN.bannerAlpha or 1)
    TabStyle.CropArt(texture, w, h, aspect)
end

local function Hex(parent, S, size)
    local hex = CreateFrame("Frame", nil, parent)
    hex:SetSize(size, size)

    local glow = hex:CreateTexture(nil, "BACKGROUND")
    glow:SetAllPoints(hex)
    glow:SetTexture(S.Media("HexGlow"))
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.3)

    local fill = hex:CreateTexture(nil, "BORDER")
    fill:SetPoint("TOPLEFT", hex, "TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", hex, "BOTTOMRIGHT", -2, 2)
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

    local value = hex:CreateFontString(nil, "OVERLAY")
    value:SetFont(NS.FONT, NS.FS(size >= 50 and 14 or 12), "OUTLINE")
    value:SetPoint("CENTER", hex, "CENTER", 0, 0)
    value:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    hex.value = value
    return hex
end

function TabStyle.Header(f, opts)
    if not TabStyle.Styled() or not f or f.tabBanner then return end
    opts = opts or {}
    local S = NS.Styling
    local left, right = opts.left or 10, opts.right or 10
    local height = opts.height or 46

    local base = f:CreateTexture(nil, "BACKGROUND", nil, 7)
    base:SetPoint("TOPLEFT", f, "TOPLEFT", left, -6)
    base:SetPoint("TOPRIGHT", f, "TOPRIGHT", -right, -6)
    base:SetHeight(height)
    base:SetTexture(WHITE)
    base:SetVertexColor(S.Tint(0.03, 0.03, 0.055, 0.95))
    S.RoundTexture(base, 6)

    local wash = f:CreateTexture(nil, "BORDER", nil, 7)
    wash:SetPoint("TOPLEFT", base, "TOPLEFT", 2, -2)
    wash:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", -2, 2)
    wash:SetTexture(S.Media("Fade"))
    wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)

    local art = f:CreateTexture(nil, "ARTWORK", nil, -7)
    art:SetPoint("TOPLEFT", base, "TOPLEFT", 1, -1)
    art:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", -1, 1)

    local edge = CreateFrame("Frame", nil, f)
    edge:SetAllPoints(base)

    local shade = edge:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(art)
    shade:SetTexture(WHITE)
    shade:SetVertexColor(0, 0, 0, 0)

    edge:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    edge:SetBackdropBorderColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.6)
    edge:EnableMouse(false)
    S.RoundCorners(edge, 6, { edgeFile = WHITE, edgeSize = 1 })

    local banner = { art = art, shade = shade, edge = edge, provider = opts.badge, artName = opts.art, specArt = opts.specArt,
        artW = (f:GetWidth() or 0) - left - right - 2, artH = height - 2, aspect = opts.aspect }

    if opts.badge and S.ORN.badges then
        local hex = Hex(edge, S, 46)
        hex:SetPoint("CENTER", base, "RIGHT", -30, 0)
        hex:SetFrameLevel(edge:GetFrameLevel() + 2)
        local caption = edge:CreateFontString(nil, "OVERLAY")
        caption:SetFont(NS.FONT, NS.FS(8), "")
        caption:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        caption:SetPoint("RIGHT", hex, "LEFT", -2, 0)
        caption:SetJustifyH("RIGHT")
        banner.hex, banner.caption = hex, caption
    end

    f.tabBanner = banner
    f:HookScript("OnShow", function() TabStyle.Refresh(f) end)
    if opts.module and opts.method and type(opts.module[opts.method]) == "function" then
        hooksecurefunc(opts.module, opts.method, function() TabStyle.Refresh(f) end)
    end
    TabStyle.Refresh(f)
end

function TabStyle.Refresh(f)
    local banner = f and f.tabBanner
    if not banner then return end
    local S = NS.Styling
    if banner.specArt then
        local path = TabStyle.SpecArt()
        banner.art:SetTexture(path or WHITE)
        banner.art:SetTexCoord(0, 1, 0.32, 0.5)
        banner.art:SetVertexColor(1, 1, 1, path and 0.8 or 0)
        banner.shade:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.1, 0, 0, 0, 0.55)
    elseif not NS.Styling.ORN.banners then
        banner.art:Hide()
    elseif banner.artName then
        TabStyle.PaintArt(banner.art, banner.artName, banner.artW, banner.artH, banner.aspect)
    else
        banner.art:Hide()
    end
    if banner.provider and banner.hex then
        local ok, value, caption = pcall(banner.provider)
        if ok and value ~= nil then
            banner.hex.value:SetText(tostring(value))
            banner.caption:SetText(caption or "")
            banner.hex:Show()
            banner.caption:Show()
        else
            banner.hex:Hide()
            banner.caption:Hide()
        end
    end
end

function TabStyle.Row(texture, radius)
    if TabStyle.Styled() and texture then NS.Styling.RoundTexture(texture, radius or 4) end
end

function TabStyle.Plate(frame, highlight, index)
    if not TabStyle.Styled() or not frame then return end
    local S = NS.Styling
    local plate = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    plate:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -1)
    plate:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)
    plate:SetTexture(WHITE)
    local base = ((index or 1) % 2 == 1) and 0.075 or 0.05
    plate:SetVertexColor(S.Tint(base + 0.02, base + 0.025, base + 0.04, 0.85))
    S.RoundTexture(plate, 4)
    if highlight then S.RoundTexture(highlight, 4) end
    frame.tabPlate = plate
end
