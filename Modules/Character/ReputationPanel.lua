local addonName, NS = ...
local L = NS.L

local ReputationPanel = {}

local format = string.format
local max = math.max

local ROW_WIDTH = 396
local ROW_HEIGHT = 32
local VALUE_WIDTH = 92
local HEADER_HEIGHT = 22

local function StandingLabel(standingID)
    if not standingID then return "" end
    local gender = UnitSex and UnitSex("player") or nil
    local text = GetText and GetText("FACTION_STANDING_LABEL" .. standingID, gender)
    return text or _G["FACTION_STANDING_LABEL" .. standingID] or ""
end

local function StandingColor(standingID)
    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[standingID]
    if color then return color.r, color.g, color.b end
    local S = NS.Styling
    return S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]
end

function ReputationPanel:CreateRow(index)
    local S = NS.Styling
    local f = self.frame

    local btn = CreateFrame("Button", nil, f.scrollChild)
    btn:SetWidth(ROW_WIDTH)
    btn:SetHeight(ROW_HEIGHT)

    local strip = btn:CreateTexture(nil, "OVERLAY")
    strip:SetWidth(2)
    strip:SetHeight(16)
    strip:SetPoint("LEFT", btn, "LEFT", 0, 0)
    strip:SetTexture("Interface\\Buttons\\WHITE8x8")
    strip:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0)
    btn.strip = strip

    local name = btn:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetJustifyH("LEFT")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    btn.name = name

    local standing = btn:CreateFontString(nil, "OVERLAY")
    standing:SetFont(NS.FONT, NS.FS(10), "")
    standing:SetJustifyH("RIGHT")
    standing:SetWidth(140)
    standing:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -4)
    btn.standing = standing

    local barBG = btn:CreateTexture(nil, "ARTWORK")
    barBG:SetHeight(4)
    barBG:SetTexture("Interface\\Buttons\\WHITE8x8")
    barBG:SetVertexColor(1, 1, 1, 0.07)
    btn.barBG = barBG

    local bar = btn:CreateTexture(nil, "OVERLAY")
    bar:SetHeight(4)
    bar:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.bar = bar

    local value = btn:CreateFontString(nil, "OVERLAY")
    value:SetFont(NS.FONT, NS.FS(9), "")
    value:SetJustifyH("RIGHT")
    value:SetWidth(VALUE_WIDTH - 8)
    value:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 3)
    value:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    btn.value = value

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.08)
    if NS.TabStyle then
        NS.TabStyle.Plate(btn, highlight, index)
        NS.TabStyle.Row(barBG, 2)
        NS.TabStyle.Row(bar, 2)
    end

    btn:SetScript("OnClick", function(self)
        if not self.factionIndex then return end
        if self.isHeader then
            if self.isCollapsed then
                ExpandFactionHeader(self.factionIndex)
            else
                CollapseFactionHeader(self.factionIndex)
            end
        elseif SetWatchedFactionIndex then
            SetWatchedFactionIndex(self.factionIndex)
        end
        ReputationPanel:Update()
    end)

    self.rows[index] = btn
    return btn
end

function ReputationPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_ReputationPanel", parent)
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
    title:SetText(L["Репутация"])
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerReputation", module = ReputationPanel, method = "Update", badge = function()
        local exalted = 0
        for i = 1, (GetNumFactions and GetNumFactions() or 0) do
            local _, _, standingID, _, _, _, _, _, isHeader = GetFactionInfo(i)
            if standingID == 8 and not isHeader then exalted = exalted + 1 end
        end
        return exalted, L["ПРЕВОЗНОСЯТ"]
    end }) end

    local watched = f:CreateFontString(nil, "OVERLAY")
    watched:SetFont(NS.FONT, NS.FS(11), "")
    watched:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    watched:SetPoint("TOP", title, "BOTTOM", 0, -6)
    f.watched = watched

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(9), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("TOP", watched, "BOTTOM", 0, -4)
    hint:SetText(L["клик по фракции - следить на панели опыта"])

    S.CreateAnimatedSeparator(f, -74)

    local scrollFrame = CreateFrame("ScrollFrame", "NarcissusSirus_ReputationScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -84)
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

function ReputationPanel:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end

    local S = NS.Styling
    local f = self.frame

    for _, row in ipairs(self.rows) do row:Hide() end

    local watchedName = GetWatchedFactionInfo and (GetWatchedFactionInfo()) or nil
    f.watched:SetText(L["Отслеживается: "] .. (watchedName or L["ничего"]))

    local yOffset = 0
    local shown = 0
    local total = GetNumFactions and GetNumFactions() or 0

    local opts = NS.db and NS.db.repTab or {}

    for index = 1, total do
        local name, description, standingID, barMin, barMax, barValue,
              atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(index)

        if name and not isHeader and opts.hideExalted and standingID == 8 then name = nil end
        if name and not isHeader and opts.hideHated and standingID and standingID <= 2 then name = nil end

        if name then
            shown = shown + 1
            local row = self.rows[shown] or self:CreateRow(shown)
            row.factionIndex = index
            row.isHeader = isHeader
            row.isCollapsed = isCollapsed

            local indent = isChild and 12 or 0
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -yOffset)

            row.name:ClearAllPoints()

            if isHeader and not hasRep then
                row:SetHeight(HEADER_HEIGHT)
                row.name:SetPoint("LEFT", row, "LEFT", 6 + indent, 0)
                row.name:SetText((isCollapsed and "+ " or "- ") .. name)
                row.name:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
                row.standing:SetText("")
                row.value:SetText("")
                row.barBG:Hide()
                row.bar:Hide()
                row.strip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
                yOffset = yOffset + HEADER_HEIGHT
            else
                row:SetHeight(ROW_HEIGHT)
                row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 6 + indent, -4)
                row.name:SetWidth(ROW_WIDTH - 160 - indent)
                row.name:SetText(isHeader and ((isCollapsed and "+ " or "- ") .. name) or name)
                row.name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])

                local r, g, b = StandingColor(standingID)
                row.standing:SetText(StandingLabel(standingID))
                row.standing:SetTextColor(r, g, b)

                local span = (barMax or 0) - (barMin or 0)
                local progress = span > 0 and ((barValue or 0) - barMin) / span or 0
                if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end

                local barWidth = ROW_WIDTH - 24 - indent - VALUE_WIDTH
                row.barBG:ClearAllPoints()
                row.barBG:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6 + indent, 8)
                row.barBG:SetWidth(barWidth)
                row.barBG:Show()

                row.bar:ClearAllPoints()
                row.bar:SetPoint("BOTTOMLEFT", row.barBG, "BOTTOMLEFT", 0, 0)
                row.bar:SetWidth(max(1, barWidth * progress))
                row.bar:SetVertexColor(r, g, b, 0.85)
                row.bar:Show()

                local mode = opts.value or "value"
                if span > 0 and mode == "percent" then
                    row.value:SetText(format("%d%%", progress * 100))
                elseif span > 0 and mode == "left" then
                    row.value:SetText(format("-%d", barMax - (barValue or 0)))
                elseif span > 0 and mode ~= "none" then
                    row.value:SetText(format("%d / %d", (barValue or 0) - barMin, span))
                else
                    row.value:SetText("")
                end

                if isWatched then
                    row.strip:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
                    row.name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                else
                    row.strip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
                end

                yOffset = yOffset + ROW_HEIGHT
            end

            row:Show()
        end
    end

    f.scrollChild:SetHeight(max(yOffset, 1))
end

function ReputationPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function ReputationPanel:Hide()
    NS.Styling.PanelHideNow(self.frame)
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("UPDATE_FACTION")
    watcher:SetScript("OnEvent", function()
        local panel = ReputationPanel
        if panel.frame and panel.frame:IsShown() then
            NS.After(0.2, function() panel:Update() end)
        end
    end)
end

NS.ReputationPanel = ReputationPanel
