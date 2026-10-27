local addonName, NS = ...
local L = NS.L

local TitleManager = {}

local format = string.format
local max = math.max

function TitleManager:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_TitleManager", parent)
    f:SetWidth(S.PANEL_WIDTH)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText(L["Титулы"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerTitles", module = TitleManager, method = "Update", badge = function()
        local known = 0
        for i = 1, GetNumTitles() do
            local k = IsTitleKnown(i)
            if k and k ~= 0 then known = known + 1 end
        end
        return known, L["ТИТУЛОВ"]
    end }) end

    local currentTitle = f:CreateFontString(nil, "OVERLAY")
    currentTitle:SetFont(NS.FONT, NS.FS(11), "")
    currentTitle:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    currentTitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    currentTitle:SetText(L["Текущий: "] .. L["нет"])
    f.currentTitle = currentTitle

    local removeBtn = NS.Widgets.CreateThemedButton(f, L["Убрать титул"], 120, 20, function()
        SetCurrentTitle(-1)
        TitleManager:Update()
    end)
    removeBtn:SetPoint("TOP", currentTitle, "BOTTOM", 0, -6)

    S.CreateAnimatedSeparator(f, -80)

    local scrollFrame = CreateFrame("ScrollFrame", "NarcissusSirus_TitleScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(400)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)
    f.scrollChild = scrollChild
    f.scrollFrame = scrollFrame

    self.frame = f
    self.buttons = {}
    f:Hide()
end

function TitleManager:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local f = self.frame

    for _, btn in pairs(self.buttons) do btn:Hide() end

    local currentIndex = GetCurrentTitle()
    local currentName = L["нет"]

    local yOffset = 0
    local buttonIndex = 0
    local numTitles = GetNumTitles()
    local opts = NS.db and NS.db.titleTab or {}
    local rowHeight = opts.compact and 18 or 22

    local order = {}
    for i = 1, numTitles do
        if IsTitleKnown(i) ~= 0 then order[#order + 1] = i end
    end
    if opts.sort == "alpha" then
        table.sort(order, function(a, b) return (GetTitleName(a) or "") < (GetTitleName(b) or "") end)
    elseif opts.sort == "reverse" then
        local reversed = {}
        for index = #order, 1, -1 do reversed[#reversed + 1] = order[index] end
        order = reversed
    end

    for _, i in ipairs(order) do
        do
            local name = GetTitleName(i)
            if name and strtrim(name) ~= "" then
                buttonIndex = buttonIndex + 1

                if not self.buttons[buttonIndex] then
                    local btn = CreateFrame("Button", nil, f.scrollChild)
                    btn:SetHeight(22)
                    btn:SetWidth(400)

                    local strip = btn:CreateTexture(nil, "OVERLAY")
                    strip:SetSize(2, 16)
                    strip:SetPoint("LEFT", btn, "LEFT", 0, 0)
                    strip:SetTexture("Interface\\Buttons\\WHITE8x8")
                    strip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
                    btn.strip = strip

                    local text = btn:CreateFontString(nil, "OVERLAY")
                    text:SetFont(NS.FONT, NS.FS(11), "")
                    text:SetPoint("LEFT", btn, "LEFT", 6, 0)
                    text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                    btn.text = text

                    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                    highlight:SetAllPoints()
                    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.08)
                    if NS.TabStyle then NS.TabStyle.Plate(btn, highlight, buttonIndex) end

                    btn:SetScript("OnClick", function(self)
                        SetCurrentTitle(self.titleIndex)
                        TitleManager:Update()
                    end)

                    self.buttons[buttonIndex] = btn
                end

                local btn = self.buttons[buttonIndex]
                btn:SetHeight(rowHeight)
                btn.titleIndex = i
                btn.text:SetText(name)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -yOffset)

                if i == currentIndex then
                    btn.text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                    btn.strip:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.8)
                    currentName = name
                else
                    btn.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                    btn.strip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
                end

                btn:Show()
                yOffset = yOffset + rowHeight
            end
        end
    end

    f.currentTitle:SetText(L["Текущий: "] .. currentName)
    f.scrollChild:SetHeight(max(yOffset, 1))
end

function TitleManager:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function TitleManager:Hide()
    NS.Styling.PanelHideNow(self.frame)
end

NS.TitleManager = TitleManager
