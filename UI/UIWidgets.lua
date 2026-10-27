local addonName, NS = ...
local L = NS.L

local Widgets = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
NS.Widgets = Widgets

function Widgets.CreateCloseButton(parent, size, onClick)
    local S = NS.Styling
    size = size or 22

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.12, 0.12, 0.18, 0.85)

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    border:EnableMouse(false)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(size > 24 and 16 or 12), "OUTLINE")
    text:SetTextColor(0.9, 0.3, 0.3)
    text:SetPoint("CENTER")
    text:SetText("X")
    S.GlyphIcon(text)

    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    btn:GetHighlightTexture():SetVertexColor(0.5, 0.1, 0.1, 0.3)

    if onClick then btn:SetScript("OnClick", onClick) end
    NS.Styling.RoundWidget(btn, bg, border)
    return btn
end

function Widgets.CreateThemedEditBox(parent, width, height, maxLetters)
    local S = NS.Styling

    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width or 160, height or 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(maxLetters or 30)
    box:SetFont(NS.FONT, NS.FS(11), "")
    box:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    box:SetTextInsets(7, 7, 0, 0)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local border = CreateFrame("Frame", nil, box)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)

    box:SetScript("OnEditFocusGained", function()
        border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    end)
    box:SetScript("OnEditFocusLost", function()
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    NS.Styling.RoundWidget(box, bg, border)
    return box
end

function Widgets.CreateThemedCheckbox(parent, label, default, onClick)
    local S = NS.Styling

    local box = CreateFrame("Button", nil, parent)
    box:SetSize(16, 16)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local border = CreateFrame("Frame", nil, box)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:EnableMouse(false)

    local fill = box:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetTexture(S.Media("IconCheck"))
    fill:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)

    local text = box:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(11), "")
    text:SetPoint("LEFT", box, "RIGHT", 8, 0)
    text:SetJustifyH("LEFT")
    text:SetText(label)
    box.text = text

    box:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    box:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.2)

    box.checked = default and true or false

    local function Refresh()
        if box.checked then
            fill:Show()
            border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        else
            fill:Hide()
            border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
    Refresh()

    box:SetScript("OnClick", function(self)
        self.checked = not self.checked
        Refresh()
        if onClick then onClick(self.checked) end
    end)

    function box:SetChecked(value)
        self.checked = value and true or false
        Refresh()
    end

    NS.Styling.RoundWidget(box, bg, border)
    return box
end

function Widgets.CreateThemedButton(parent, text, width, height, onClick, color)
    local S = NS.Styling
    color = color or S.ACCENT

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 100, height or 22)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(color[1], color[2], color[3], 0.7)
    border:EnableMouse(false)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    label:SetTextColor(color[1], color[2], color[3])
    label:SetPoint("CENTER")
    label:SetText(text)
    S.GlyphIcon(label)
    btn.label = label

    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    btn:GetHighlightTexture():SetVertexColor(color[1], color[2], color[3], 0.2)

    btn.SetText = function(self, s) self.label:SetText(s) end

    if onClick then btn:SetScript("OnClick", onClick) end
    NS.Styling.RoundWidget(btn, bg, border)
    return btn
end

local confirmFrame

function Widgets.ShowConfirm(text, acceptText, onAccept)
    local S = NS.Styling

    if not confirmFrame then
        local scrim = CreateFrame("Frame", "NarcissusSirus_ConfirmScrim", UIParent)
        scrim:SetAllPoints(UIParent)
        scrim:SetFrameStrata("FULLSCREEN_DIALOG")
        scrim:SetFrameLevel(280)
        scrim:EnableMouse(true)
        local shade = scrim:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetTexture("Interface\\Buttons\\WHITE8x8")
        shade:SetVertexColor(0, 0, 0, 0.55)

        local f = CreateFrame("Frame", "NarcissusSirus_ConfirmFrame", scrim)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(285)
        f:EnableMouse(true)
        S.ApplyPanelStyle(f, 340, 132)
        S.CreateShadow(f, 6, 0.5)
        S.ApplyTabChrome(f)
        S.CreateGradientTopBorder(f)

        local body = f:CreateFontString(nil, "OVERLAY")
        body:SetFont(NS.FONT, NS.FS(12), "")
        body:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        body:SetPoint("TOP", f, "TOP", 0, -24)
        body:SetWidth(300)
        body:SetJustifyH("CENTER")
        f.body = body

        local accept = Widgets.CreateThemedButton(f, "", 110, 24, function()
            local fn = f._onAccept
            Widgets.HideConfirm()
            if fn then fn() end
        end)
        accept:SetPoint("BOTTOM", f, "BOTTOM", -60, 16)
        f.accept = accept

        local cancel = Widgets.CreateThemedButton(f, L["Отмена"], 110, 24, function()
            Widgets.HideConfirm()
        end, S.TEXT_NORMAL)
        cancel:SetPoint("BOTTOM", f, "BOTTOM", 60, 16)

        tinsert(UISpecialFrames, "NarcissusSirus_ConfirmFrame")
        f:SetScript("OnHide", function() scrim:Hide() end)

        confirmFrame = f
        f.scrim = scrim
    end

    confirmFrame.body:SetText(text or "")
    confirmFrame.accept:SetText(acceptText or L["Да"])
    confirmFrame._onAccept = onAccept
    confirmFrame.scrim:Show()
    confirmFrame:Show()
    S.FadeIn(confirmFrame, 0.15)
end

function Widgets.HideConfirm()
    if not confirmFrame then return end
    confirmFrame._onAccept = nil
    confirmFrame:Hide()
    confirmFrame.scrim:Hide()
end

function Widgets.CreateThemedSlider(parent, label, minValue, maxValue, step, value, onChange, suffix)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(280, 32)

    local caption = holder:CreateFontString(nil, "OVERLAY")
    caption:SetFont(NS.FONT, NS.FS(11), "")
    caption:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    caption:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    caption:SetText(label)

    local readout = holder:CreateFontString(nil, "OVERLAY")
    readout:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    readout:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    readout:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 2)
    slider:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
    slider:SetHeight(12)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step or 1)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(2)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local round = S.CORNER_RADIUS > 0
    slider:SetThumbTexture(round and S.Media("RoundFill") or "Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    if thumb then
        if round then thumb:SetSize(12, 12) else thumb:SetSize(8, 14) end
        thumb:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        local filled = slider:CreateTexture(nil, "BORDER")
        filled:SetHeight(2)
        filled:SetPoint("LEFT", slider, "LEFT", 0, 0)
        filled:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
        filled:SetTexture("Interface\\Buttons\\WHITE8x8")
        filled:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.8)
    end

    local function Readout(v)
        readout:SetText(tostring(v) .. (suffix or ""))
    end

    local quiet = false
    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v + 0.5)
        Readout(v)
        if onChange and not quiet then onChange(v) end
    end)

    quiet = true
    slider:SetValue(value or minValue)
    quiet = false
    Readout(math.floor((value or minValue) + 0.5))

    function holder:SetValue(v)
        quiet = true
        slider:SetValue(v)
        quiet = false
        Readout(math.floor(v + 0.5))
    end

    holder.slider = slider
    return holder
end

function Widgets.CreateThemedDropdown(parent, width, onPick)
    local S = NS.Styling

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 22)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local border = CreateFrame("Frame", nil, button)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(11), "")
    text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    text:SetPoint("LEFT", button, "LEFT", 8, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    text:SetJustifyH("LEFT")
    button.text = text

    local arrow = button:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(NS.FONT, NS.FS(9), "")
    arrow:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    arrow:SetPoint("RIGHT", button, "RIGHT", -7, -1)
    arrow:SetText("v")
    S.GlyphIcon(arrow)

    button:SetHighlightTexture(WHITE, "ADD")
    button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.15)

    local menu = CreateFrame("Frame", nil, button)
    menu:SetWidth(width)
    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    menu:SetBackdropColor(NS.Styling.Panel(0.04, 0.04, 0.06, 0.98))
    menu:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.8)
    menu:Hide()
    menu.rows = {}

    button.entries = {}

    local function BuildMenu()
        local count = #button.entries

        for index = 1, count do
            local row = menu.rows[index]

            if not row then
                row = CreateFrame("Button", nil, menu)
                row:SetHeight(18)
                row:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - (index - 1) * 18)
                row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -3, -3 - (index - 1) * 18)

                local rowText = row:CreateFontString(nil, "OVERLAY")
                rowText:SetFont(NS.FONT, NS.FS(11), "")
                rowText:SetPoint("LEFT", row, "LEFT", 5, 0)
                rowText:SetJustifyH("LEFT")
                row.text = rowText

                row:SetHighlightTexture(WHITE, "ADD")
                row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)

                row:SetScript("OnClick", function(self)
                    button:SetValue(self.value)
                    menu:Hide()
                    if onPick then onPick(self.value) end
                end)

                menu.rows[index] = row
            end

            local entry = button.entries[index]
            row.value = entry.value
            row.text:SetText(entry.label)
            row.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            row:Show()
        end

        for index = count + 1, #menu.rows do menu.rows[index]:Hide() end
        menu:SetHeight(math.max(count * 18 + 6, 10))
    end

    function button:SetEntries(entries)
        self.entries = entries or {}
        BuildMenu()

        local found
        for _, entry in ipairs(self.entries) do
            if entry.value == self.value then found = entry.label end
        end

        if found then
            self.text:SetText(found)
        elseif self.entries[1] then
            self.value = self.entries[1].value
            self.text:SetText(self.entries[1].label)
        else
            self.text:SetText("-")
        end
    end

    function button:SetValue(value)
        self.value = value
        for _, entry in ipairs(self.entries) do
            if entry.value == value then self.text:SetText(entry.label) end
        end
    end

    function button:GetValue()
        return self.value
    end

    button:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            menu:SetFrameLevel(button:GetFrameLevel() + 20)
            BuildMenu()
            menu:Show()
        end
    end)

    button.menu = menu
    NS.Styling.RoundWidget(button, bg, border)
    return button
end

function Widgets.CreateAccentPicker(parent, current, onPick)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(280, 20)

    local swatches = {}
    local function Refresh(active)
        for key, sw in pairs(swatches) do
            if key == active then
                sw.ring:SetBackdropBorderColor(0.95, 0.95, 0.95, 0.95)
            else
                sw.ring:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            end
        end
    end

    for i, preset in ipairs(S.ACCENT_PRESETS) do
        local sw = CreateFrame("Button", nil, holder)
        sw:SetSize(20, 20)
        sw:SetPoint("LEFT", holder, "LEFT", (i - 1) * 26, 0)

        local fill = sw:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", -2, 2)
        fill:SetTexture("Interface\\Buttons\\WHITE8x8")
        fill:SetVertexColor(preset.glow[1], preset.glow[2], preset.glow[3], 1)

        local ring = CreateFrame("Frame", nil, sw)
        ring:SetPoint("TOPLEFT", 0, 0)
        ring:SetPoint("BOTTOMRIGHT", 0, 0)
        ring:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        ring:EnableMouse(false)
        sw.ring = ring

        sw:RegisterForClicks("LeftButtonUp")
        sw:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L[preset.name], preset.glow[1], preset.glow[2], preset.glow[3])
            GameTooltip:Show()
            if holder.onHover then holder.onHover(self, preset.key, preset.name) end
        end)
        sw:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if holder.onHoverEnd then holder.onHoverEnd(self) end
        end)
        sw:SetScript("OnClick", function()
            Refresh(preset.key)
            if onPick then onPick(preset.key) end
        end)

        swatches[preset.key] = sw
    end

    local custom = CreateFrame("Button", nil, holder)
    custom:SetSize(20, 20)
    custom:SetPoint("LEFT", holder, "LEFT", #S.ACCENT_PRESETS * 26 + 8, 0)

    local customFill = custom:CreateTexture(nil, "ARTWORK")
    customFill:SetPoint("TOPLEFT", 2, -2)
    customFill:SetPoint("BOTTOMRIGHT", -2, 2)
    customFill:SetTexture(WHITE)

    local customRing = CreateFrame("Frame", nil, custom)
    customRing:SetAllPoints(custom)
    customRing:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    customRing:EnableMouse(false)
    custom.ring = customRing

    local plus = custom:CreateFontString(nil, "OVERLAY")
    plus:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    plus:SetPoint("CENTER", custom, "CENTER", 0, 0)
    plus:SetText("+")
    NS.Styling.GlyphIcon(plus)

    function holder:SetCustomColor(r, g, b)
        if r then
            local _, _, glow = S.DeriveAccent(r, g, b)
            customFill:SetVertexColor(glow[1], glow[2], glow[3], 1)
            plus:Hide()
        else
            customFill:SetVertexColor(0.08, 0.09, 0.12, 1)
            plus:Show()
        end
    end

    local stored = NS.db and NS.db.accentCustom
    holder:SetCustomColor(stored and stored[1], stored and stored[2], stored and stored[3])

    custom:RegisterForClicks("LeftButtonUp")
    custom:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Свой цвет"], 1, 1, 1)
        GameTooltip:AddLine(L["Выбрать любой цвет на круге"], 0.7, 0.7, 0.75)
        GameTooltip:Show()
    end)
    custom:SetScript("OnLeave", function() GameTooltip:Hide() end)
    custom:SetScript("OnClick", function()
        if onPick then onPick("custom") end
    end)

    swatches.custom = custom

    local classSwatch = CreateFrame("Button", nil, holder)
    classSwatch:SetSize(20, 20)
    classSwatch:SetPoint("LEFT", custom, "RIGHT", 6, 0)

    local cr, cg, cb = S.ClassColor()
    cr, cg, cb = cr or 0.6, cg or 0.6, cb or 0.6

    local classFill = classSwatch:CreateTexture(nil, "ARTWORK")
    classFill:SetPoint("TOPLEFT", 2, -2)
    classFill:SetPoint("BOTTOMRIGHT", -2, 2)
    classFill:SetTexture(WHITE)
    classFill:SetVertexColor(cr, cg, cb, 1)

    local classIcon = classSwatch:CreateTexture(nil, "OVERLAY")
    classIcon:SetPoint("TOPLEFT", 4, -4)
    classIcon:SetPoint("BOTTOMRIGHT", -4, 4)
    S.SetClassIcon(classIcon, select(2, UnitClass("player")))

    local classRing = CreateFrame("Frame", nil, classSwatch)
    classRing:SetAllPoints(classSwatch)
    classRing:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    classRing:EnableMouse(false)
    classSwatch.ring = classRing

    classSwatch:RegisterForClicks("LeftButtonUp")
    classSwatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["Цвет класса"], cr, cg, cb)
        GameTooltip:AddLine(L["Берётся из класса персонажа, у каждого свой"], 0.7, 0.7, 0.75)
        GameTooltip:Show()
    end)
    classSwatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    classSwatch:SetScript("OnClick", function()
        Refresh("class")
        if onPick then onPick("class") end
    end)

    swatches.class = classSwatch

    holder.Refresh = Refresh
    holder:SetWidth(#S.ACCENT_PRESETS * 26 + 8 + 20 + 26)

    Refresh(current)
    return holder
end

function Widgets.CreateOptionPicker(parent, options, current, onPick, maxWidth)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(20)

    local buttons = {}
    local function Refresh(active)
        for _, b in ipairs(buttons) do
            if b.optionKey == active then
                b.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
                b.text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                b.bg:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
            else
                b.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
                b.text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                b.bg:SetVertexColor(S.Tint(0.10, 0.11, 0.14, 0.85))
            end
        end
    end

    local x, rows, widest = 0, 1, 0
    for _, option in ipairs(options) do
        local btn = CreateFrame("Button", nil, holder)
        btn:SetHeight(20)
        btn.optionKey = option.key

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.bg = bg

        local border = CreateFrame("Frame", nil, btn)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        border:EnableMouse(false)
        btn.border = border

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetPoint("CENTER")
        text:SetText(NS.L[option.label])
        btn.text = text

        local w = text:GetStringWidth() + 18
        btn:SetWidth(w)
        if maxWidth and x > 0 and x + w > maxWidth then
            x = 0
            rows = rows + 1
        end
        btn:SetPoint("TOPLEFT", holder, "TOPLEFT", x, -(rows - 1) * 26)
        x = x + w + 6
        if x - 6 > widest then widest = x - 6 end

        btn:RegisterForClicks("LeftButtonUp")
        btn:SetScript("OnClick", function(self)
            if onPick then onPick(self.optionKey) end
            if holder.onHover then holder.onHover(self, self.optionKey, option.label) end
        end)
        btn:SetScript("OnEnter", function(self)
            if holder.onHover then holder.onHover(self, self.optionKey, option.label) end
        end)
        btn:SetScript("OnLeave", function(self)
            if holder.onHoverEnd then holder.onHoverEnd(self) end
        end)

        S.RoundWidget(btn, bg, border)
        buttons[#buttons + 1] = btn
    end

    holder:SetWidth(widest > 0 and widest or 1)
    holder:SetHeight(rows * 20 + (rows - 1) * 6)
    holder.Refresh = function(_, active) Refresh(active) end
    Refresh(current)
    return holder
end
