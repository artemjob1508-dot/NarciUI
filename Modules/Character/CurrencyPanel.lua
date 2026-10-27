local addonName, NS = ...
local L = NS.L

local CurrencyPanel = {}

local format = string.format
local max = math.max

local ROW_WIDTH = 396
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 22

local function CountText(count)
    if not count or count == 0 then return "0" end
    if count >= 10000 then
        return format("%.1fk", count / 1000)
    end
    return tostring(count)
end

function CurrencyPanel:CreateRow(index)
    local S = NS.Styling
    local f = self.frame

    local btn = CreateFrame("Button", nil, f.scrollChild)
    btn:SetWidth(ROW_WIDTH)
    btn:SetHeight(ROW_HEIGHT)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = icon

    local name = btn:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetJustifyH("LEFT")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetWidth(ROW_WIDTH - 120)
    btn.name = name

    local count = btn:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    count:SetJustifyH("RIGHT")
    count:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    btn.count = count

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.08)
    if NS.TabStyle then NS.TabStyle.Plate(btn, highlight, index) end

    btn:SetScript("OnClick", function(self)
        if not self.listIndex then return end
        if self.isHeader then
            ExpandCurrencyList(self.listIndex, self.isExpanded and 0 or 1)
            CurrencyPanel:Update()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        if self.isHeader or not self.listIndex then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local ok = pcall(GameTooltip.SetCurrencyToken, GameTooltip, self.listIndex)
        if not ok then
            GameTooltip:SetText(self.name:GetText() or "")
        end
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.rows[index] = btn
    return btn
end

function CurrencyPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_CurrencyPanel", parent)
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
    title:SetText(L["Валюта"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerCurrency", module = CurrencyPanel, method = "Update", badge = function()
        local count = 0
        for i = 1, (GetCurrencyListSize and GetCurrencyListSize() or 0) do
            local name, isHeader = GetCurrencyListInfo(i)
            if name and name ~= "" and not isHeader then count = count + 1 end
        end
        return count, L["ВАЛЮТ"]
    end }) end

    local money = f:CreateFontString(nil, "OVERLAY")
    money:SetFont(NS.FONT, NS.FS(12), "")
    money:SetPoint("TOP", title, "BOTTOM", 0, -6)
    money:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    f.money = money

    S.CreateAnimatedSeparator(f, -62)

    local scrollFrame = CreateFrame("ScrollFrame", "NarcissusSirus_CurrencyScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -72)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(ROW_WIDTH)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)
    f.scrollChild = scrollChild
    f.scrollFrame = scrollFrame

    self.frame = f
    self.rows = {}
    f:Hide()
end

function CurrencyPanel:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end

    local S = NS.Styling
    local f = self.frame

    for _, row in ipairs(self.rows) do row:Hide() end

    f.money:SetText(GetMoneyString and GetMoneyString(GetMoney()) or tostring(GetMoney()))

    local yOffset = 0
    local shown = 0
    local total = GetCurrencyListSize and GetCurrencyListSize() or 0

    local opts = NS.db and NS.db.currencyTab or {}

    for index = 1, total do
        local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon = GetCurrencyListInfo(index)

        if name and not isHeader and opts.hideZero and (not count or count == 0) then name = nil end
        if name and not isHeader and opts.hideUnused and isUnused then name = nil end

        if name and name ~= "" then
            shown = shown + 1
            local row = self.rows[shown] or self:CreateRow(shown)
            row.listIndex = index
            row.isHeader = isHeader
            row.isExpanded = isExpanded

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -yOffset)
            row.name:ClearAllPoints()

            if isHeader then
                row:SetHeight(HEADER_HEIGHT)
                row.icon:Hide()
                row.name:SetPoint("LEFT", row, "LEFT", 6, 0)
                row.name:SetText((isExpanded and "- " or "+ ") .. name)
                row.name:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
                row.count:SetText("")
                yOffset = yOffset + HEADER_HEIGHT
            else
                row:SetHeight(ROW_HEIGHT)
                row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.icon:Show()
                row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
                row.name:SetText(name)
                row.count:SetText(CountText(count))

                if not count or count == 0 then
                    row.name:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                    row.count:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                    row.icon:SetAlpha(0.4)
                else
                    row.name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                    row.count:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                    row.icon:SetAlpha(1)
                end

                yOffset = yOffset + ROW_HEIGHT
            end

            row:Show()
        end
    end

    f.scrollChild:SetHeight(max(yOffset, 1))
end

function CurrencyPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function CurrencyPanel:Hide()
    NS.Styling.PanelHideNow(self.frame)
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    watcher:RegisterEvent("PLAYER_MONEY")
    watcher:SetScript("OnEvent", function()
        local panel = CurrencyPanel
        if panel.frame and panel.frame:IsShown() then
            NS.After(0.2, function() panel:Update() end)
        end
    end)
end

NS.CurrencyPanel = CurrencyPanel
