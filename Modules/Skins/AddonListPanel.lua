local addonName, NS = ...
local L = NS.L

local Panel = {}
NS.AddonListPanel = Panel

local WHITE = "Interface\\Buttons\\WHITE8x8"

local PANEL_W = 460
local PANEL_H = 480
local TITLE_H = 40
local PAD = 12
local ROW_H = 26
local FOOTER_H = 44

local rows = {}
local entries = {}
local scrollOffset = 0

local function Style()
    return NS.Styling
end

function Panel:Collect()
    for index = #entries, 1, -1 do entries[index] = nil end

    local count = GetNumAddOns() or 0

    for index = 1, count do
        local name, title, notes, enabled, loadable, reason = GetAddOnInfo(index)

        entries[#entries + 1] = {
            index = index,
            name = name,
            title = title and title ~= "" and title or name,
            enabled = enabled and true or false,
            loaded = IsAddOnLoaded(index) and true or false,
            version = GetAddOnMetadata(name, "Version"),
            reason = reason,
            loadable = loadable and true or false,
        }
    end

    table.sort(entries, function(a, b)
        return NS.Lower(a.title) < NS.Lower(b.title)
    end)
end

function Panel:CreateRow(parent, position)
    local S = Style()

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(position - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(position - 1) * ROW_H)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(row)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)
    hover:Hide()

    local box = CreateFrame("Button", nil, row)
    box:SetSize(14, 14)
    box:SetPoint("LEFT", row, "LEFT", 4, 0)

    local boxBase = box:CreateTexture(nil, "BACKGROUND")
    boxBase:SetAllPoints(box)
    boxBase:SetTexture(WHITE)
    boxBase:SetVertexColor(NS.Styling.Tint(0.04, 0.045, 0.06, 1))

    local boxEdge = {}

    for index = 1, 4 do
        local line = box:CreateTexture(nil, "BORDER")
        line:SetTexture(WHITE)
        line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        boxEdge[index] = line
    end

    boxEdge[1]:SetHeight(1)
    boxEdge[1]:SetPoint("TOPLEFT", box, "TOPLEFT")
    boxEdge[1]:SetPoint("TOPRIGHT", box, "TOPRIGHT")
    boxEdge[2]:SetHeight(1)
    boxEdge[2]:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT")
    boxEdge[2]:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT")
    boxEdge[3]:SetWidth(1)
    boxEdge[3]:SetPoint("TOPLEFT", box, "TOPLEFT")
    boxEdge[3]:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT")
    boxEdge[4]:SetWidth(1)
    boxEdge[4]:SetPoint("TOPRIGHT", box, "TOPRIGHT")
    boxEdge[4]:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT")

    local tick = box:CreateTexture(nil, "ARTWORK")
    tick:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
    tick:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
    tick:SetTexture(WHITE)
    tick:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    tick:Hide()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(12), "")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetJustifyH("LEFT")

    local note = row:CreateFontString(nil, "OVERLAY")
    note:SetFont(NS.FONT, NS.FS(11), "")
    note:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    note:SetJustifyH("RIGHT")
    note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])

    label:SetPoint("RIGHT", note, "LEFT", -8, 0)

    row.hover = hover
    row.box = box
    row.tick = tick
    row.label = label
    row.note = note

    local function Flip(self)
        local entry = row.entry
        if not entry then return end

        if entry.enabled then
            DisableAddOn(entry.name)
        else
            EnableAddOn(entry.name)
        end

        entry.enabled = not entry.enabled
        Panel:Refresh()
    end

    row:SetScript("OnClick", Flip)
    box:SetScript("OnClick", Flip)

    row:SetScript("OnEnter", function(self) self.hover:Show() end)
    row:SetScript("OnLeave", function(self) self.hover:Hide() end)

    return row
end

function Panel:Create()
    if self.frame then return self.frame end

    local S = Style()

    local f = CreateFrame("Frame", "NarcissusSirus_AddonList", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(230)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    tinsert(UISpecialFrames, "NarcissusSirus_AddonList")

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(NS.Styling.Panel(0.020, 0.023, 0.032, 0.96))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    if S.CreateGradientTopBorder then S.CreateGradientTopBorder(f, 2) end
    if S.CreateShadow then S.CreateShadow(f, 5, 0.4) end

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(15), "")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetText(L["Модификации"])

    if NS.Widgets and NS.Widgets.CreateCloseButton then
        local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    end

    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -TITLE_H)
    list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, FOOTER_H)
    list:EnableMouseWheel(true)

    list:SetScript("OnMouseWheel", function(self, delta)
        Panel:Scroll(-delta * 3)
    end)

    f.list = list
    f.visibleRows = math.floor((PANEL_H - TITLE_H - FOOTER_H) / ROW_H)

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(11), "")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, 16)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetText(L["Изменения применятся после перезагрузки интерфейса"])

    f.hint = hint

    if NS.Widgets and NS.Widgets.CreateThemedButton then
        local reload = NS.Widgets.CreateThemedButton(f, L["Перезагрузить"], 120, 22, function()
            ReloadUI()
        end)
        reload:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 12)
    end

    self.frame = f

    for position = 1, f.visibleRows do
        rows[position] = self:CreateRow(list, position)
    end

    return f
end

function Panel:Scroll(step)
    local f = self.frame
    if not f then return end

    local maximum = #entries - f.visibleRows
    if maximum < 0 then maximum = 0 end

    scrollOffset = scrollOffset + step
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maximum then scrollOffset = maximum end

    self:Refresh(true)
end

function Panel:Refresh(keepList)
    local f = self.frame
    if not f then return end

    if not keepList then self:Collect() end

    local S = Style()

    for position = 1, f.visibleRows do
        local row = rows[position]
        local entry = entries[position + scrollOffset]

        if entry then
            row.entry = entry
            row.label:SetText(entry.title)
            row.tick:SetShown(entry.enabled)

            if entry.enabled then
                row.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            else
                row.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            end

            local note = entry.version or ""
            if entry.enabled and not entry.loaded then note = L["нужен /reload"] end
            row.note:SetText(note)

            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end
end

function Panel:Toggle()
    local f = self:Create()

    if f:IsShown() then
        self:Hide()
        return
    end

    scrollOffset = 0
    self:Refresh()
    f:Show()
end

function Panel:Hide()
    if self.frame then self.frame:Hide() end
end
