local addonName, NS = ...
local L = NS.L
local Enhancements = {}
local format = string.format
local floor = math.floor

local PANEL_WIDTH = 440
local ROW_HEIGHT = 28

local DANGER_COLOR = { 0.85, 0.35, 0.30 }

local STRENGTHEN_STATS = {
    { index = 1, labelFunc = function() return SPELL_STAT1_NAME or "STR" end },
    { index = 2, labelFunc = function() return SPELL_STAT2_NAME or "AGI" end },
    { index = 3, labelFunc = function() return SPELL_STAT3_NAME or "STA" end },
    { index = 4, labelFunc = function() return SPELL_STAT4_NAME or "INT" end },
    { index = 5, labelFunc = function() return SPELL_STAT5_NAME or "SPI" end },
    { index = 6, labelFunc = function() return PAPERDOLLFRAME_UPS_SPELL_POWER or "SP" end },
    { index = 7, labelFunc = function() return ATTACK_POWER or "AP" end },
}

local function GetAvailablePoints()
    if C_PlayerInfo and C_PlayerInfo.GetBonusStatPointInfo then
        local total, maxPoints, available = C_PlayerInfo.GetBonusStatPointInfo()
        return total or 0, maxPoints or 0, available or 0
    end
    return 0, 0, 0
end

local function GetStatInfo(statIndex)
    if C_PlayerInfo and C_PlayerInfo.GetBonusStatInfo then
        local _, value, baseValue, multiplier = C_PlayerInfo.GetBonusStatInfo(statIndex)
        return value or 0, baseValue or 0, multiplier or 1
    end
    return 0, 0, 1
end

local function AddPoints(statIndex, amount)
    if C_PlayerInfo and C_PlayerInfo.InceaseBonusStat then C_PlayerInfo.InceaseBonusStat(statIndex, amount) end
end

function Enhancements:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_Enhancements", parent)
    f:SetWidth(PANEL_WIDTH)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
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
    title:SetText(L["Усиления"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerEnhance", module = Enhancements, method = "Update", badge = function()
        local _, _, available = GetAvailablePoints()
        return available or 0, L["ДОСТУПНО"]
    end }) end
    f.title = title

    local availLabel = f:CreateFontString(nil, "OVERLAY")
    availLabel:SetFont(NS.FONT, NS.FS(11), "")
    availLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    availLabel:SetPoint("TOP", title, "BOTTOM", 0, -6)
    f.availLabel = availLabel

    S.CreateAnimatedSeparator(f, -54)

    local scrollTop = -60
    local scrollBottom = 40

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, scrollTop)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, scrollBottom)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(PANEL_WIDTH - 20)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)

    f.rows = {}
    for i, statInfo in ipairs(STRENGTHEN_STATS) do
        local y = -(i - 1) * ROW_HEIGHT
        local row = {}

        if i % 2 == 0 then
            local stripe = scrollChild:CreateTexture(nil, "BACKGROUND")
            stripe:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, y + 4)
            stripe:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMRIGHT", -4, y - ROW_HEIGHT + 4)
            stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
            stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.10)
            if NS.TabStyle then NS.TabStyle.Row(stripe) end
        end

        local name = scrollChild:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(11), "")
        name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        name:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 14, y)
        name:SetText(statInfo.labelFunc())

        local valText = scrollChild:CreateFontString(nil, "OVERLAY")
        valText:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
        valText:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        valText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 136, y)
        valText:SetJustifyH("RIGHT")

        local plusBtn = CreateFrame("Button", nil, scrollChild)
        plusBtn:SetSize(22, 22)
        plusBtn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, y + 1)

        local plusBg = plusBtn:CreateTexture(nil, "BACKGROUND")
        plusBg:SetAllPoints()
        plusBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        plusBg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.9)

        local plusBorder = CreateFrame("Frame", nil, plusBtn)
        plusBorder:SetPoint("TOPLEFT", -1, 1); plusBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        plusBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        plusBorder:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.7)
        plusBorder:EnableMouse(false)
        row.plusBorder = plusBorder

        local plusText = plusBtn:CreateFontString(nil, "OVERLAY")
        plusText:SetFont(NS.FONT, NS.FS(14), "OUTLINE")
        plusText:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        plusText:SetPoint("CENTER")
        plusText:SetText("+")
        NS.Styling.GlyphIcon(plusText)

        plusBtn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
        plusBtn:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.25)

        S.AddHoverGlow(plusBtn, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

        local statIdx = statInfo.index
        plusBtn:SetScript("OnClick", function()
            local step = NS.db and NS.db.enhanceStep or 1
            if IsModifiedClick("SHIFT") then AddPoints(statIdx, 10)
            elseif IsModifiedClick("CTRL") then AddPoints(statIdx, 100)
            elseif IsModifiedClick("ALT") then local _, _, avail = GetAvailablePoints(); AddPoints(statIdx, avail)
            else AddPoints(statIdx, step) end
            Enhancements:Update()
        end)
        plusBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(L["Клик +1 / Shift +10 / Ctrl +100 / Alt все"], 0.7, 0.7, 0.7, 1)
            GameTooltip:Show()
        end)
        plusBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.valText = valText; row.plusBtn = plusBtn; row.statIndex = statInfo.index
        f.rows[i] = row
    end
    scrollChild:SetHeight(#STRENGTHEN_STATS * ROW_HEIGHT + 4)

    local resetBtn = NS.Widgets.CreateThemedButton(f, L["Сбросить"], PANEL_WIDTH - 20, 22, function()
        if not (C_PlayerInfo and C_PlayerInfo.ResetBonusStats) then return end
        local function Reset()
            C_PlayerInfo.ResetBonusStats()
            Enhancements:Update()
        end
        if NS.db and NS.db.enhanceConfirm and NS.Widgets.ShowConfirm then
            NS.Widgets.ShowConfirm(L["Сбросить все очки усилений?"], L["Сбросить"], Reset)
        else
            Reset()
        end
    end, DANGER_COLOR)
    resetBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    f.resetText = resetBtn.label
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Сбросить все очки усилений"], 0.9, 0.4, 0.3)
        local cost = 0
        if C_PlayerInfo and C_PlayerInfo.GetResetBonusStatsCost then
            cost = C_PlayerInfo.GetResetBonusStatsCost() or 0
        end
        if cost > 0 then
            SetTooltipMoney(GameTooltip, cost)
        else
            GameTooltip:AddLine(L["Бесплатно"], 0.3, 1, 0.3)
        end
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.resetBtn = resetBtn

    self.frame = f; f:Hide()
end

function Enhancements:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local f = self.frame
    local total, maxPoints, available = GetAvailablePoints()
    f.availLabel:SetText(format(L["Доступно усилений: %d"], available))

    if f.resetText then
        local cost = 0
        if C_PlayerInfo and C_PlayerInfo.GetResetBonusStatsCost then
            cost = C_PlayerInfo.GetResetBonusStatsCost() or 0
        end
        if cost > 0 then
            local gold = floor(cost / 10000)
            local silver = floor((cost % 10000) / 100)
            local copper = cost % 100
            local parts = {}
            if gold > 0 then tinsert(parts, gold .. L["г"]) end
            if silver > 0 then tinsert(parts, silver .. L["с"]) end
            tinsert(parts, copper .. L["б"])
            f.resetText:SetText(L["Сбросить ("] .. strjoin(" ", unpack(parts)) .. ")")
        else
            f.resetText:SetText(L["Сбросить (бесплатно)"])
        end
    end

    for i, row in ipairs(f.rows) do
        local value, baseValue = GetStatInfo(row.statIndex)
        local newText
        if value and value > 0 then
            newText = format("%d (+|cff00FF00%d|r)", value, baseValue)
        else
            newText = "0 (+|cff00FF000|r)"
        end
        if row.valText:GetText() ~= newText then
            row.valText:SetText(newText)
            S.FlashValue(row.valText, 0.4)
        end
        if available <= 0 then
            row.plusBtn:Disable(); row.plusBtn:SetAlpha(0.3)
        else
            row.plusBtn:Enable(); row.plusBtn:SetAlpha(1)
        end
    end
end

function Enhancements:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function Enhancements:Hide() NS.Styling.PanelHideNow(self.frame) end

NS.Enhancements = Enhancements
