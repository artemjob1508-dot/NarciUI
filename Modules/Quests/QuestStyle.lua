local addonName, NS = ...

local S = {}
NS.QuestStyle = S

S.WHITE = "Interface\\Buttons\\WHITE8x8"
S.FONT = NS.FONT

local host = NS.Styling

S.BG = { host.BG_DARK[1], host.BG_DARK[2], host.BG_DARK[3], host.BG_DARK_A }
S.BG_ROW = { host.BG_SLOT[1], host.BG_SLOT[2], host.BG_SLOT[3], 0.9 }
S.BG_ROW_ALT = { host.BG_STRIPE[1], host.BG_STRIPE[2], host.BG_STRIPE[3], 0.55 }
S.BORDER = host.BORDER
S.ACCENT = host.ACCENT
S.ACCENT_GLOW = host.ACCENT_GLOW
S.GOLD = host.GOLD
S.RED = { 0.85, 0.30, 0.30 }
S.TEXT = host.TEXT_BRIGHT
S.TEXT_DIM = host.TEXT_DIM

function S.Backdrop(frame, r, g, b, a)
    frame:SetBackdrop({ bgFile = S.WHITE, edgeFile = S.WHITE, edgeSize = 1 })
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
end

function S.Label(parent, size, flags)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(S.FONT, NS.FS(size), flags or "")
    text:SetTextColor(S.TEXT[1], S.TEXT[2], S.TEXT[3])
    text:SetJustifyH("LEFT")
    return text
end

function S.Bar(parent, height)
    local background = parent:CreateTexture(nil, "ARTWORK")
    background:SetHeight(height)
    background:SetTexture(S.WHITE)
    background:SetVertexColor(1, 1, 1, 0.07)

    local fill = parent:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(height)
    fill:SetTexture(S.WHITE)
    fill:SetPoint("TOPLEFT", background, "TOPLEFT", 0, 0)
    fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)

    return background, fill
end

function S.Button(parent, caption, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height or 22)
    S.Backdrop(button, 0.08, 0.09, 0.13, 0.95)

    local label = S.Label(button, 11)
    label:SetPoint("CENTER")
    label:SetJustifyH("CENTER")
    label:SetText(caption)
    NS.Styling.GlyphIcon(label)
    button.label = label
    NS.Styling.RoundCorners(button, 6)
    NS.Styling.RoundHighlight(button, 6)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(S.WHITE)
    highlight:SetVertexColor(1, 1, 1, 0.08)

    return button
end

function S.CheckBox(parent, caption, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width or 200)
    button:SetHeight(20)

    local box = CreateFrame("Frame", nil, button)
    box:SetWidth(14)
    box:SetHeight(14)
    box:SetPoint("LEFT", button, "LEFT", 0, 0)
    S.Backdrop(box, 0.06, 0.07, 0.10, 0.95)

    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
    mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
    mark:SetTexture(S.WHITE)
    mark:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    button.mark = mark

    local label = S.Label(button, 11)
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetText(caption)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(S.WHITE)
    highlight:SetVertexColor(1, 1, 1, 0.05)

    function button:SetChecked(state)
        if state then self.mark:Show() else self.mark:Hide() end
    end

    return button
end
