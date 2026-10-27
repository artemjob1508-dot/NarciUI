local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc

local Styling = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"

Styling.WHITE = WHITE

Styling.BG_DARK = Root.Styling.BG_DARK
Styling.BG_DARK_A   = 0.94
Styling.BG_SLOT = Root.Styling.BG_SLOT
Styling.BG_STRIPE = Root.Styling.BG_STRIPE

Styling.ACCENT = Root.Styling.ACCENT
Styling.ACCENT_GLOW = Root.Styling.ACCENT_GLOW

Styling.TEXT_BRIGHT = Root.Styling.TEXT_BRIGHT
Styling.TEXT_NORMAL = Root.Styling.TEXT_NORMAL
Styling.TEXT_DIM = Root.Styling.TEXT_DIM

Styling.UP          = { 0.90, 0.45, 0.45 }
Styling.DOWN        = { 0.35, 0.85, 0.55 }

Styling.BORDER = Root.Styling.BORDER

local ACCENT = Styling.ACCENT
local BORDER = Styling.BORDER

function Styling.CreateShadow(parent, size, alpha)
    return Root.Styling.CreateShadow(parent, size or 4, alpha or 0.4)
end

function Styling.CreateTopBorder(parent)
    local border = parent:CreateTexture(nil, "OVERLAY")
    border:SetHeight(2)
    border:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -3)
    border:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -3)
    border:SetTexture(WHITE)
    border:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
    return border
end

function Styling.CreateRule(parent, width)
    local rule = parent:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetTexture(WHITE)
    rule:SetWidth(width or 260)
    rule:SetGradientAlpha("Horizontal",
        ACCENT[1], ACCENT[2], ACCENT[3], 0.45,
        ACCENT[1], ACCENT[2], ACCENT[3], 0)
    return rule
end

local SLICE_STEP = 1
local SLICE_LIMIT = 2000

function Styling.HidePolylineTail(pool, used)
    for index = (used or 0) + 1, #pool do
        pool[index]:Hide()
    end
end

function Styling.DrawPolyline(pool, parent, xs, ys, thickness, color, startIndex)
    local used = startIndex or 0
    local half = thickness / 2

    for index = 1, #xs - 1 do
        local x1, y1 = xs[index], ys[index]
        local x2, y2 = xs[index + 1], ys[index + 1]

        if x1 and y1 and x2 and y2 then
            local dx, dy = x2 - x1, y2 - y1
            local length = sqrt(dx * dx + dy * dy)
            local steps = math.max(1, math.ceil(length / SLICE_STEP))

            for step = 0, steps do
                if used >= SLICE_LIMIT then
                    return used
                end

                local progress = step / steps
                local px = x1 + dx * progress
                local py = y1 + dy * progress

                used = used + 1
                local slice = pool[used]
                if not slice then
                    slice = parent:CreateTexture(nil, "ARTWORK")
                    slice:SetTexture(WHITE)
                    pool[used] = slice
                end

                slice:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                slice:ClearAllPoints()
                slice:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", px - half, py - half)
                slice:SetPoint("TOPRIGHT", parent, "BOTTOMLEFT", px + half, py + half)
                slice:Show()
            end
        end
    end

    return used
end

function Styling.CreatePanel(name, parent, width, height)
    local panel = CreateFrame("Frame", name, parent or UIParent)
    panel:SetWidth(width)
    panel:SetHeight(height)
    panel:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
    })
    panel:SetBackdropColor(Root.Styling.Bg(Styling.BG_DARK_A))
    panel:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
    Styling.CreateShadow(panel, 5, 0.4)
    Styling.CreateTopBorder(panel)
    return panel
end

function Styling.CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height or 22)
    button:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
    })
    button:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
    button:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetText(text)
    button.label:SetTextColor(Styling.TEXT_BRIGHT[1], Styling.TEXT_BRIGHT[2], Styling.TEXT_BRIGHT[3])

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
        self:SetBackdropColor(0.10, 0.13, 0.16, 0.95)
        self.label:SetTextColor(Styling.ACCENT_GLOW[1], Styling.ACCENT_GLOW[2], Styling.ACCENT_GLOW[3])
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
        self:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
        self.label:SetTextColor(Styling.TEXT_BRIGHT[1], Styling.TEXT_BRIGHT[2], Styling.TEXT_BRIGHT[3])
    end)

    function button:SetLabel(value)
        self.label:SetText(value)
    end

    return button
end

function Styling.CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(18)
    button:SetHeight(18)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetText("X")
    button.label:SetTextColor(Styling.TEXT_DIM[1], Styling.TEXT_DIM[2], Styling.TEXT_DIM[3])
    Root.Styling.GlyphIcon(button.label)

    button:SetScript("OnEnter", function(self)
        self.label:SetTextColor(Styling.UP[1], Styling.UP[2], Styling.UP[3])
    end)
    button:SetScript("OnLeave", function(self)
        self.label:SetTextColor(Styling.TEXT_DIM[1], Styling.TEXT_DIM[2], Styling.TEXT_DIM[3])
    end)

    return button
end

function Styling.CreateEditBox(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetWidth(width)
    box:SetHeight(height or 20)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetTextInsets(6, 6, 0, 0)
    box:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
    })
    box:SetBackdropColor(Styling.BG_SLOT[1], Styling.BG_SLOT[2], Styling.BG_SLOT[3], 0.9)
    box:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])

    box.placeholder = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    box.placeholder:SetPoint("LEFT", box, "LEFT", 7, 0)

    local function UpdatePlaceholder()
        if box:GetText() == "" and not box:HasFocus() then
            box.placeholder:Show()
        else
            box.placeholder:Hide()
        end
    end

    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
        UpdatePlaceholder()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
        UpdatePlaceholder()
    end)

    box.UpdatePlaceholder = UpdatePlaceholder
    return box
end

function Styling.CreateCheck(parent, label)
    local check = CreateFrame("Button", nil, parent)
    check:SetWidth(16)
    check:SetHeight(16)
    check:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
    })
    check:SetBackdropColor(Styling.BG_SLOT[1], Styling.BG_SLOT[2], Styling.BG_SLOT[3], 0.95)
    check:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])

    check.mark = check:CreateTexture(nil, "OVERLAY")
    check.mark:SetPoint("TOPLEFT", check, "TOPLEFT", 3, -3)
    check.mark:SetPoint("BOTTOMRIGHT", check, "BOTTOMRIGHT", -3, 3)
    check.mark:SetTexture(WHITE)
    check.mark:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.95)
    check.mark:Hide()

    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.label:SetPoint("LEFT", check, "RIGHT", 8, 0)
    check.label:SetText(label)
    check.label:SetTextColor(Styling.TEXT_NORMAL[1], Styling.TEXT_NORMAL[2], Styling.TEXT_NORMAL[3])

    function check:SetChecked(value)
        self.checked = value and true or false
        if self.checked then
            self.mark:Show()
        else
            self.mark:Hide()
        end
    end

    function check:GetChecked()
        return self.checked
    end

    check:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
    end)
    check:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
    end)
    check:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if self.onToggle then
            self.onToggle(self.checked)
        end
    end)

    return check
end

function Styling.CreateSlider(parent, minValue, maxValue, step, width)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetWidth(width)
    slider:SetHeight(12)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 4, bottom = 4 },
    })
    slider:SetBackdropColor(Styling.BG_SLOT[1], Styling.BG_SLOT[2], Styling.BG_SLOT[3], 0.95)
    slider:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
    slider:SetThumbTexture(WHITE)

    local thumb = slider:GetThumbTexture()
    thumb:SetWidth(10)
    thumb:SetHeight(16)
    thumb:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.95)

    slider.label = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slider.label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 6)
    slider.label:SetTextColor(Styling.TEXT_NORMAL[1], Styling.TEXT_NORMAL[2], Styling.TEXT_NORMAL[3])

    return slider
end

NS.Styling = Styling
