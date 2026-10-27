local addonName, NS = ...
local L = NS.L

local Inspect = {}
NS.InspectScene = Inspect

local WHITE = "Interface\\Buttons\\WHITE8x8"

local SLOT_SIZE = 48
local PANEL_W = 440
local PANEL_H = 430
local TREE_W = 136
local TALENT_STEP = 30
local PVP_BRACKETS = { 1, 2, 5 }
local GLYPH_ORDER = { 1, 4, 6, 2, 3, 5 }
local MAX_RETRIES = 12

local function Style()
    return NS.Styling
end

local function Enabled()
    return NS.db and NS.db.inspectStyle ~= "window"
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function Pass(ok, ...)
    if ok then return ... end
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    return Pass(pcall(fn, ...))
end

local function Silence(on)
    local frame = InspectFrame
    if not frame then return end

    if on then
        frame:SetAlpha(0)
        frame:SetScale(0.001)
        frame.narciSilenced = true
    elseif frame.narciSilenced then
        frame.narciSilenced = nil
        frame:SetScale(1)
        frame:SetAlpha(1)
    end
end

local function Text(parent, size, flags, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(size), flags or "")
    return text
end

local function TextButton(parent, text, width)
    local S = Style()

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 140, 26)

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Panel(0.035, 0.040, 0.058, 0.92))

    S.CreateEdges(button, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)

    local label = Text(button, 12)
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetTextColor(0.92, 0.93, 0.95)
    label:SetText(text)
    button.label = label

    return button
end

function Inspect:BuildDim()
    local dim = CreateFrame("Frame", "NarciSirus_InspectDim", UIParent)
    dim:SetAllPoints(UIParent)
    dim:SetFrameStrata("BACKGROUND")
    dim:SetFrameLevel(1)
    dim:Hide()

    local flat = dim:CreateTexture(nil, "BACKGROUND")
    flat:SetAllPoints(dim)
    flat:SetTexture(WHITE)
    flat:SetVertexColor(0.015, 0.015, 0.03, 0.62)
    dim.flat = flat

    local top = dim:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", dim, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", dim, "TOPRIGHT", 0, 0)
    top:SetHeight(220)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("VERTICAL", 0.02, 0.02, 0.04, 0, 0.02, 0.02, 0.04, 0.7)

    local bottom = dim:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", dim, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", dim, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(220)
    bottom:SetTexture(WHITE)
    bottom:SetGradientAlpha("VERTICAL", 0.02, 0.02, 0.04, 0.7, 0.02, 0.02, 0.04, 0)

    self.dim = dim
end

function Inspect:BuildBacklight(root, modelX)
    local light = root:CreateTexture(nil, "BACKGROUND")
    light:SetTexture(NS.Styling.GLOW)
    light:SetBlendMode("ADD")
    light:SetSize(620, 720)
    light:SetPoint("CENTER", root, "CENTER", modelX, 0)
    light:SetVertexColor(0.34, 0.44, 0.62, 0.2)
    self.light = light
end

local function Options()
    if not NS.db then return {} end
    if type(NS.db.inspect) ~= "table" then NS.db.inspect = {} end
    return NS.db.inspect
end

function Inspect:ApplyLook()
    local db = Options()
    if self.dim and self.dim.flat then
        self.dim.flat:SetVertexColor(0.015, 0.015, 0.03, (db.dim or 62) / 100)
    end
    local light = self.light
    if light then
        local kind = db.light or "cold"
        if kind == "off" then
            light:Hide()
        else
            light:Show()
            local r, g, b = 0.34, 0.44, 0.62
            if kind == "theme" then
                local A = Style().ACCENT
                r, g, b = A[1], A[2], A[3]
            elseif kind == "class" and self.unit then
                local _, class = UnitClass(self.unit)
                local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                if c then r, g, b = c.r, c.g, c.b end
            end
            light:SetVertexColor(r, g, b, (db.lightPower or 20) / 100)
        end
    end
end

function Inspect:BuildModel(root, modelX)
    local model = CreateFrame("PlayerModel", "NarciSirus_InspectModel", root)
    model:SetSize(440, 480)
    model:SetPoint("CENTER", root, "CENTER", modelX, 0)
    model:SetFrameLevel(root:GetFrameLevel() + 1)

    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.dragging = true
            self.startX = GetCursorPosition()
        end
    end)
    model:SetScript("OnMouseUp", function(self) self.dragging = false end)
    model:SetScript("OnHide", function(self) self.dragging = false end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local x = GetCursorPosition()
        self:SetFacing(self:GetFacing() + (x - (self.startX or x)) * 0.01)
        self.startX = x
    end)

    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        local scale = self:GetModelScale() or 1
        if delta > 0 then scale = math.min(scale * 1.05, 2.0) else scale = math.max(scale * 0.95, 0.5) end
        self:SetModelScale(scale)
    end)

    self.model = model
end

function Inspect:BuildHeader(root)
    local S = Style()

    local name = Text(root, 22, "OUTLINE")
    name:SetPoint("TOP", root, "TOP", 0, -12)
    self.nameText = name

    local classIcon = root:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("RIGHT", name, "LEFT", -8, 0)
    self.classIcon = classIcon

    local details = Text(root, 12)
    details:SetTextColor(0.55, 0.55, 0.60)
    details:SetPoint("TOP", name, "BOTTOM", 0, -4)
    self.detailsText = details

    local spec = Text(root, 12)
    spec:SetPoint("TOP", details, "BOTTOM", 0, -3)
    self.specText = spec

    local A = S.ACCENT
    for half = 1, 2 do
        local rule = root:CreateTexture(nil, "ARTWORK")
        rule:SetHeight(1)
        rule:SetTexture(WHITE)
        if half == 1 then
            rule:SetPoint("TOPLEFT", root, "TOPLEFT", 60, -82)
            rule:SetPoint("TOPRIGHT", root, "TOP", 0, -82)
            rule:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0, A[1], A[2], A[3], 0.45)
        else
            rule:SetPoint("TOPLEFT", root, "TOP", 0, -82)
            rule:SetPoint("TOPRIGHT", root, "TOPRIGHT", -60, -82)
            rule:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0.45, A[1], A[2], A[3], 0)
        end
    end

    local levelLabel = Text(root, 9)
    levelLabel:SetTextColor(0.40, 0.42, 0.50)
    levelLabel:SetPoint("TOP", root, "TOPRIGHT", -120, -12)
    levelLabel:SetText(L["УРОВЕНЬ ПРЕДМЕТОВ"])

    local levelValue = Text(root, 20, "OUTLINE")
    levelValue:SetPoint("TOP", levelLabel, "BOTTOM", 0, -2)
    self.levelText = levelValue

    local close = CreateFrame("Button", nil, root)
    close:SetSize(32, 32)
    close:SetPoint("TOPRIGHT", root, "TOPRIGHT", -16, -10)

    local closeGround = close:CreateTexture(nil, "BACKGROUND")
    closeGround:SetAllPoints(close)
    closeGround:SetTexture(WHITE)
    closeGround:SetVertexColor(0.12, 0.12, 0.18, 0.85)
    S.CreateEdges(close, "BORDER", 0.6, 0.2, 0.2, 0.8)

    local closeHover = close:CreateTexture(nil, "HIGHLIGHT")
    closeHover:SetAllPoints(close)
    closeHover:SetTexture(WHITE)
    closeHover:SetVertexColor(0.8, 0.2, 0.2, 0.25)

    local closeMark = Text(close, 16, "OUTLINE")
    closeMark:SetPoint("CENTER", close, "CENTER", 0, 0)
    closeMark:SetText("X")
    closeMark:SetTextColor(0.9, 0.35, 0.35)
    S.GlyphIcon(closeMark)

    close:SetScript("OnClick", function() Inspect:Dismiss() end)
end

function Inspect:BuildSlot(root, info)
    local S = Style()
    local side = info.side

    local slot = CreateFrame("Button", nil, root)
    slot:SetSize(SLOT_SIZE, SLOT_SIZE)
    slot:SetPoint("CENTER", root, "CENTER", info.x, info.y)
    slot:SetFrameLevel(root:GetFrameLevel() + 5)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot.slotId = info.id
    slot.side = side

    local ground = slot:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(slot)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)

    slot.edges = S.CreateEdges(slot, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.icon = icon

    local strip = slot:CreateTexture(nil, "OVERLAY")
    strip:SetSize(2, SLOT_SIZE - 4)
    strip:SetTexture(WHITE)
    strip:SetPoint(side == "RIGHT" and "RIGHT" or "LEFT", slot, side == "RIGHT" and "RIGHT" or "LEFT", 0, 0)
    slot.strip = strip

    local glow = root:CreateTexture(nil, "BACKGROUND")
    if side == "LEFT" then
        glow:SetTexture(S.Media("Fade"))
        glow:SetTexCoord(1, 0, 0, 1)
        glow:SetPoint("TOPRIGHT", slot, "TOPLEFT", 0, 8)
        glow:SetPoint("BOTTOMRIGHT", slot, "BOTTOMLEFT", 0, -8)
        glow:SetWidth(90)
    elseif side == "RIGHT" then
        glow:SetTexture(S.Media("Fade"))
        glow:SetPoint("TOPLEFT", slot, "TOPRIGHT", 0, 8)
        glow:SetPoint("BOTTOMLEFT", slot, "BOTTOMRIGHT", 0, -8)
        glow:SetWidth(90)
    else
        glow:SetTexture(S.Media("FadeV"))
        glow:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", -14, 0)
        glow:SetPoint("TOPRIGHT", slot, "BOTTOMRIGHT", 14, 0)
        glow:SetHeight(64)
    end
    glow:Hide()
    slot.glow = glow

    local levelGround = slot:CreateTexture(nil, "OVERLAY")
    levelGround:SetTexture(WHITE)
    levelGround:SetVertexColor(0, 0, 0, 0.6)
    levelGround:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 2, 2)
    levelGround:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    levelGround:SetHeight(14)
    slot.levelGround = levelGround

    local level = Text(slot, 12, "OUTLINE")
    level:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2)
    slot.level = level

    slot.enchantDot = S.CreateEnchantDot(slot, side)

    slot.gems = {}
    for index = 1, 4 do
        local gem = CreateFrame("Button", nil, slot)
        gem:SetSize(14, 14)
        gem:SetFrameLevel(slot:GetFrameLevel() + 2)
        if side == "LEFT" then
            gem:SetPoint("TOPLEFT", slot, "TOPRIGHT", 3, -2 - (index - 1) * 15)
        elseif side == "RIGHT" then
            gem:SetPoint("TOPRIGHT", slot, "TOPLEFT", -3, -2 - (index - 1) * 15)
        else
            gem:SetPoint("BOTTOMLEFT", slot, "TOPLEFT", 1 + (index - 1) * 15, 3)
        end

        local texture = gem:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(gem)
        gem.texture = texture

        gem:SetScript("OnEnter", function(self)
            if not self.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.link)
            GameTooltip:Show()
        end)
        gem:SetScript("OnLeave", function() GameTooltip:Hide() end)
        gem:Hide()

        slot.gems[index] = gem
    end

    local label = Text(slot, 13, "OUTLINE")
    if side == "LEFT" then
        label:SetPoint("RIGHT", slot, "LEFT", -10, 0)
        label:SetJustifyH("RIGHT")
    elseif side == "RIGHT" then
        label:SetPoint("LEFT", slot, "RIGHT", 10, 0)
        label:SetJustifyH("LEFT")
    else
        label:SetPoint("TOP", slot, "BOTTOM", 0, -14)
        label:SetJustifyH("CENTER")
    end
    slot.label = label

    local plate = slot:CreateTexture(nil, "BACKGROUND")
    plate:SetTexture(S.Media("Pill"))
    plate:SetPoint("TOPLEFT", label, "TOPLEFT", -22, 7)
    plate:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 22, -7)
    plate:SetVertexColor(0, 0, 0, 0.75)
    plate:Hide()
    slot.plate = plate

    local ok, _, empty = pcall(GetInventorySlotInfo, info.name)
    slot.emptyTexture = ok and empty or nil

    local highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(slot)
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.15)

    slot:SetScript("OnEnter", function(self)
        local unit = Inspect.unit
        if not unit then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if not GameTooltip:SetInventoryItem(unit, self.slotId) then
            GameTooltip:SetText(_G[string.upper(info.name)] or "")
        end
        GameTooltip:Show()
        self.label:SetTextColor(1, 1, 1)
    end)
    slot:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        local color = self.color
        if color then self.label:SetTextColor(color[1], color[2], color[3]) end
    end)
    slot:SetScript("OnClick", function(self)
        local link = Inspect.unit and GetInventoryItemLink(Inspect.unit, self.slotId)
        if link and HandleModifiedItemClick then HandleModifiedItemClick(link) end
    end)

    return slot
end

function Inspect:BuildTab(key, text, index)
    local S = Style()
    local panel = self.panel
    local width = math.floor((PANEL_W - 24) / 4)

    local tab = CreateFrame("Button", nil, panel)
    tab:SetSize(width - 4, 26)
    tab:SetPoint("TOPLEFT", panel, "TOPLEFT", 12 + (index - 1) * width, -12)

    local ground = tab:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(tab)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Tint(0.04, 0.045, 0.065, 0.9))

    local hover = tab:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(tab)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)

    local mark = tab:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    mark:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
    mark:SetHeight(2)
    mark:SetTexture(WHITE)
    mark:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
    tab.mark = mark

    local label = Text(tab, 12)
    label:SetPoint("CENTER", tab, "CENTER", 0, 1)
    label:SetText(text)
    tab.label = label

    tab:SetScript("OnClick", function() Inspect:SelectTab(key) end)

    self.tabs[key] = tab

    local page = CreateFrame("Frame", nil, panel)
    page:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
    page:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
    page:Hide()
    self.pages[key] = page

    return page
end

function Inspect:BuildTree(page, index)
    local tree = CreateFrame("Frame", nil, page)
    tree:SetSize(TREE_W - 6, 370)
    tree:SetPoint("TOPLEFT", page, "TOPLEFT", (index - 1) * (TREE_W + 2), 0)

    local ground = tree:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(tree)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Tint(0.03, 0.035, 0.05, 0.75))

    local icon = tree:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("TOPLEFT", tree, "TOPLEFT", 4, -4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tree.icon = icon

    local name = Text(tree, 10)
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", tree, "RIGHT", -28, 0)
    name:SetJustifyH("LEFT")
    tree.name = name

    local points = Text(tree, 14, "OUTLINE")
    points:SetPoint("RIGHT", tree, "RIGHT", -5, 0)
    points:SetPoint("TOP", tree, "TOP", 0, -8)
    tree.points = points

    local grid = CreateFrame("Frame", nil, tree)
    grid:SetPoint("TOPLEFT", tree, "TOPLEFT", 4, -32)
    grid:SetPoint("BOTTOMRIGHT", tree, "BOTTOMRIGHT", -4, 4)
    tree.grid = grid

    tree.buttons = {}
    return tree
end

function Inspect:BuildTalent(tree)
    local S = Style()

    local button = CreateFrame("Button", nil, tree.grid)
    button:RegisterForClicks("LeftButtonUp")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    button.edges = S.CreateEdges(button, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local rank = Text(button, 9, "OUTLINE")
    rank:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.rank = rank

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetTalent(self.tab, self.index, true, false, self.group)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function(self)
        if not IsModifiedClick("CHATLINK") then return end
        local link = GetTalentLink(self.tab, self.index, true, false, self.group)
        if link then ChatEdit_InsertLink(link) end
    end)

    return button
end

function Inspect:BuildRows(page, count)
    page.rows = {}

    for index = 1, count do
        local row = CreateFrame("Frame", nil, page)
        row:SetHeight(20)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -(index - 1) * 21)
        row:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -(index - 1) * 21)

        local left = Text(row, 12)
        left:SetPoint("LEFT", row, "LEFT", 0, 0)
        left:SetJustifyH("LEFT")

        local right = Text(row, 12)
        right:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        right:SetJustifyH("RIGHT")

        local rule = row:CreateTexture(nil, "BACKGROUND")
        rule:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        rule:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        rule:SetHeight(1)
        rule:SetTexture(WHITE)

        row.left, row.right, row.rule = left, right, rule
        page.rows[index] = row
    end
end

local function ResetRows(page)
    page.used = 0
    for _, row in ipairs(page.rows) do row:Hide() end
end

local function AddRow(page, left, right, header)
    local S = Style()
    page.used = page.used + 1
    local row = page.rows[page.used]
    if not row then return end

    row.left:SetText(left or "")
    row.right:SetText(right or "")

    if header then
        row.left:SetFont(NS.FONT, NS.FS(12), "")
        row.left:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        row.right:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        row.rule:SetGradientAlpha("Horizontal", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
    else
        row.left:SetFont(NS.FONT, NS.FS(12), "")
        row.left:SetTextColor(0.70, 0.71, 0.76)
        row.right:SetTextColor(0.94, 0.94, 0.96)
        row.rule:SetGradientAlpha("Horizontal", 1, 1, 1, 0.05, 1, 1, 1, 0.05)
    end

    row:Show()
end

function Inspect:BuildPanel(root)
    local S = Style()

    local panel = CreateFrame("Frame", nil, root)
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -96)
    panel:SetFrameLevel(root:GetFrameLevel() + 8)
    panel:EnableMouse(true)
    S.ApplyPanelStyle(panel, PANEL_W, PANEL_H)
    self.panel = panel

    self.tabs, self.pages = {}, {}

    local talents = self:BuildTab("talents", L["Таланты"], 1)
    talents.trees = {}
    for index = 1, 3 do talents.trees[index] = self:BuildTree(talents, index) end

    local glyphs = self:BuildTab("glyphs", L["Символы"], 2)
    glyphs.items = {}
    for index = 1, #GLYPH_ORDER do
        local item = CreateFrame("Button", nil, glyphs)
        item:SetHeight(46)
        item:SetPoint("TOPLEFT", glyphs, "TOPLEFT", 4, -(index - 1) * 52)
        item:SetPoint("TOPRIGHT", glyphs, "TOPRIGHT", -4, -(index - 1) * 52)

        local ground = item:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(item)
        ground:SetTexture(WHITE)
        ground:SetVertexColor(NS.Styling.Tint(0.03, 0.035, 0.05, 0.75))

        local hover = item:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints(item)
        hover:SetTexture(WHITE)
        hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

        local icon = item:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("LEFT", item, "LEFT", 6, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local frame = CreateFrame("Frame", nil, item)
        frame:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        frame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        item.edges = S.CreateEdges(frame, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

        local name = Text(item, 13)
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        name:SetPoint("RIGHT", item, "RIGHT", -8, 0)
        name:SetJustifyH("LEFT")

        local kind = Text(item, 10)
        kind:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2)
        kind:SetTextColor(0.50, 0.52, 0.58)

        item.icon, item.name, item.kind = icon, name, kind

        item:SetScript("OnEnter", function(self)
            if not self.spell then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("spell:" .. self.spell)
            GameTooltip:Show()
        end)
        item:SetScript("OnLeave", function() GameTooltip:Hide() end)
        item:SetScript("OnClick", function(self)
            if self.spell and IsModifiedClick("CHATLINK") then
                local link = GetSpellLink(self.spell)
                if link then ChatEdit_InsertLink(link) end
            end
        end)

        glyphs.items[index] = item
    end

    local pvp = self:BuildTab("pvp", L["PvP"], 3)
    self:BuildRows(pvp, 17)

    local guild = self:BuildTab("guild", L["Гильдия"], 4)

    local guildName = Text(guild, 18, "OUTLINE")
    guildName:SetPoint("TOP", guild, "TOP", 0, -24)
    guildName:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    guild.name = guildName

    local guildRule = guild:CreateTexture(nil, "ARTWORK")
    guildRule:SetSize(260, 1)
    guildRule:SetPoint("TOP", guildName, "BOTTOM", 0, -10)
    guildRule:SetTexture(WHITE)
    guildRule:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.45)

    guild.lines = {}
    for index = 1, 4 do
        local line = Text(guild, 12)
        line:SetPoint("TOP", guildRule, "BOTTOM", 0, -12 - (index - 1) * 22)
        line:SetTextColor(0.80, 0.81, 0.85)
        guild.lines[index] = line
    end

    local dress = TextButton(root, L["Примерочная"], 150)
    dress:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, -8)
    dress:SetFrameLevel(panel:GetFrameLevel())
    dress:SetScript("OnClick", function() Inspect:DressUp() end)

    local stock = TextButton(root, L["Окно клиента"], 150)
    stock:SetPoint("RIGHT", dress, "LEFT", -8, 0)
    stock:SetFrameLevel(panel:GetFrameLevel())
    stock:SetScript("OnClick", function() Inspect:ShowStock() end)
end

function Inspect:Build()
    if self.root then return true end

    local ui = NS.NarciUI
    local layout = ui and ui.SLOT_LAYOUT
    if not layout then return false end

    local modelX = ui.MODEL_X or -190

    self:BuildDim()

    local root = CreateFrame("Frame", "NarciSirus_InspectScene", UIParent)
    root:SetAllPoints(UIParent)
    root:SetFrameStrata("FULLSCREEN_DIALOG")
    root:SetFrameLevel(200)
    root:EnableMouse(true)
    root:Hide()
    self.root = root

    self:BuildBacklight(root, modelX)
    self:BuildModel(root, modelX)
    self:BuildHeader(root)

    self.slots = {}
    for _, info in ipairs(layout) do
        self.slots[#self.slots + 1] = self:BuildSlot(root, info)
    end

    self:BuildPanel(root)
    self:SelectTab("talents")

    return true
end

function Inspect:ApplyScale()
    local scale = NS.db and NS.db.scaleOverride
    if not scale or scale <= 0 then
        local ui = NS.NarciUI
        scale = ui and ui.GetAutoScale and ui:GetAutoScale() or 1
    end
    self.root:SetScale(scale)
end

function Inspect:SelectTab(key)
    local S = Style()
    self.tab = key

    for name, tab in pairs(self.tabs) do
        local on = name == key
        tab.mark:SetShown(on)
        if on then
            tab.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            tab.label:SetTextColor(0.62, 0.64, 0.70)
        end
        self.pages[name]:SetShown(on)
    end

    self:FillPage()
end

function Inspect:FillPage()
    if not self.active then return end

    if self.tab == "talents" then
        self:FillTalents()
    elseif self.tab == "glyphs" then
        self:FillGlyphs()
    elseif self.tab == "pvp" then
        self:FillPvP()
    elseif self.tab == "guild" then
        self:FillGuild()
    end
end

local function AverageLevel(unit)
    local avg = C_Inspect and Call(C_Inspect.GetAvgItemLevel, unit)
    if avg and avg > 0 then return avg end

    local total, count = 0, 0
    for slot = 1, 18 do
        if slot ~= 4 then
            local link = GetInventoryItemLink(unit, slot)
            local level = link and select(4, GetItemInfo(link))
            if level and level > 0 then
                total, count = total + level, count + 1
            end
        end
    end

    return count > 0 and total / count or 0
end

local talentCache = {}
local MAX_TALENT_TRIES = 8

local function ReadTalents()
    local group = Call(GetActiveTalentGroup, true) or 1
    local tabs = Call(GetNumTalentTabs, true) or 0
    if tabs == 0 then return nil end

    local data = { group = group, total = 0 }
    for tab = 1, tabs do
        local name, icon, spent = Call(GetTalentTabInfo, tab, true, false, group)
        spent = tonumber(spent) or 0

        local tree = { name = name, icon = icon, spent = spent, talents = {} }
        local count = Call(GetNumTalents, tab, true, false) or 0
        for talent = 1, count do
            local talentName, talentIcon, tier, column, rank, maxRank = Call(GetTalentInfo, tab, talent, true, false, group)
            if talentName and tier and column then
                tree.talents[#tree.talents + 1] = { talent, talentIcon, tier, column, rank or 0, maxRank or 1 }
            end
        end

        data.total = data.total + spent
        data[tab] = tree
    end

    if data.total <= 0 then return nil end
    return data
end

function Inspect:Talents()
    local guid = self.unit and UnitGUID(self.unit)
    if not guid then return nil end

    if not self.stale then
        local data = ReadTalents()
        if data then
            talentCache[guid] = data
            return data
        end
    end

    local cached = talentCache[guid]
    if not cached then self:RequestTalents() end
    return cached
end

function Inspect:RequestTalents()
    local unit = self.unit
    if not unit or (UnitLevel(unit) or 0) < 10 then return end
    if (self.talentTries or 0) >= MAX_TALENT_TRIES then return end

    local now = GetTime()
    if self.talentAsked and now - self.talentAsked < 1.5 then return end
    self.talentAsked = now
    self.talentTries = (self.talentTries or 0) + 1

    if CanInspect and not CanInspect(unit) then return end
    Call(NotifyInspect, unit)

    if NS.After then
        NS.After(1.6, function()
            if not Inspect.active then return end
            Inspect:FillHeader()
            Inspect:FillPage()
        end)
    end
end

local function TalentSummary()
    local data = Inspect:Talents()
    if not data then return nil end

    local points, best, bestName = {}, -1, nil
    for tab, tree in ipairs(data) do
        points[tab] = tree.spent
        if tree.spent > best then best, bestName = tree.spent, tree.name end
    end

    return bestName, table.concat(points, "/")
end

function Inspect:FillHeader()
    local S = Style()
    local unit = self.unit

    local name = UnitName(unit) or ""
    local className, class = UnitClass(unit)
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]

    if color then
        self.nameText:SetText(Hex(color.r, color.g, color.b) .. name .. "|r")
    else
        self.nameText:SetText(name)
    end
    S.SetClassIcon(self.classIcon, class)

    local level = UnitLevel(unit)
    local levelText = (level and level > 0) and tostring(level) or "??"
    local details = string.format("|cff00ccff%s|r %s %s", levelText, UnitRace(unit) or "", className or "")

    local guildName, rankName = GetGuildInfo(unit)
    if guildName and guildName ~= "" then
        details = details .. "   " .. Hex(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]) .. "<" .. guildName .. ">|r"
    end
    self.detailsText:SetText(details)

    local specName, points = TalentSummary()
    if specName then
        local A = S.ACCENT_GLOW
        self.specText:SetText(Hex(A[1], A[2], A[3]) .. specName .. "|r  |cff8a8c94" .. points .. "|r")
    else
        self.specText:SetText("")
    end

    local avg = AverageLevel(unit)
    if avg > 0 then
        self.levelText:SetText(string.format("%.1f", avg))
        self.levelText:SetTextColor(S.GetILvlColor(avg))
    else
        self.levelText:SetText("-")
        self.levelText:SetTextColor(0.5, 0.5, 0.55)
    end
end

function Inspect:FillSlot(slot)
    local S = Style()
    local unit = self.unit
    local link = GetInventoryItemLink(unit, slot.slotId)
    local texture = GetInventoryItemTexture(unit, slot.slotId)

    if not link and not texture then
        slot.icon:SetTexture(slot.emptyTexture)
        slot.icon:SetVertexColor(1, 1, 1, 0.5)
        slot.level:Hide()
        slot.levelGround:Hide()
        slot.label:SetText("")
        slot.plate:Hide()
        slot.glow:Hide()
        slot.color = nil
        for _, gem in ipairs(slot.gems) do gem:Hide(); gem.link = nil end
        for _, edge in ipairs(slot.edges) do edge:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.4) end
        slot.strip:SetVertexColor(0.2, 0.2, 0.25, 0.3)
        S.SetEnchantDotStatus(slot.enchantDot, "none")
        return
    end

    local name, quality, itemLevel, itemTexture
    if link then
        local _
        name, _, quality, itemLevel, _, _, _, _, _, itemTexture = GetItemInfo(link)
        if not name then self.missing = true end
    else
        self.missing = true
    end

    slot.icon:SetTexture(itemTexture or texture)
    slot.icon:SetVertexColor(1, 1, 1, 1)

    local r, g, b = NS.GetQualityColor(quality)
    for _, edge in ipairs(slot.edges) do edge:SetVertexColor(r, g, b, 0.9) end
    slot.strip:SetVertexColor(r, g, b, 0.85)

    slot.glow:Show()
    slot.glow:SetVertexColor(r, g, b, 0.4)

    if itemLevel and itemLevel > 0 then
        slot.level:SetText(itemLevel)
        slot.level:SetTextColor(S.GetILvlColor(itemLevel))
        slot.level:Show()
        slot.levelGround:Show()
    else
        slot.level:Hide()
        slot.levelGround:Hide()
    end

    if name then
        local length = (NS.db and NS.db.nameLength) or 24
        slot.label:SetText(NS.TruncateText(name, length))
        slot.label:SetTextColor(r, g, b)
        slot.color = { r, g, b }
        slot.plate:Show()
    else
        slot.label:SetText("")
        slot.plate:Hide()
    end

    if link and NS.ENCHANTABLE_SLOTS and NS.ENCHANTABLE_SLOTS[slot.slotId] then
        S.SetEnchantDotStatus(slot.enchantDot, NS.GetEnchantInfo(link) and "enchanted" or "missing")
    else
        S.SetEnchantDotStatus(slot.enchantDot, "none")
    end

    local sockets = 0
    if link and NS.TooltipScanner then
        sockets = Call(NS.TooltipScanner.GetSocketCountFromTextures, NS.TooltipScanner, link) or 0
    end
    local gems = sockets > 0 and NS.GetGemInfo(link) or {}

    for index, gem in ipairs(slot.gems) do
        if index <= sockets then
            local info = gems[index]
            if info and info.texture then
                gem.texture:SetTexture(info.texture)
                gem.link = info.link
            else
                local socket = NS.TooltipScanner and Call(NS.TooltipScanner.GetSocketTexture, NS.TooltipScanner, link, index)
                gem.texture:SetTexture(socket or "Interface\\ItemSocketingFrame\\UI-EmptySocket")
                gem.link = nil
            end
            gem:Show()
        else
            gem:Hide()
            gem.link = nil
        end
    end
end

function Inspect:FillSlots()
    self.missing = nil
    for _, slot in ipairs(self.slots) do self:FillSlot(slot) end
end

function Inspect:FillTalents()
    local S = Style()
    local page = self.pages.talents
    local data = self:Talents()
    local tabs = data and #data or 0
    local group = data and data.group or 1

    if not page.status then
        page.status = page:CreateFontString(nil, "OVERLAY")
        page.status:SetFont(NS.FONT, NS.FS(12), "")
        page.status:SetPoint("CENTER", page, "CENTER", 0, 0)
        page.status:SetTextColor(0.60, 0.62, 0.68)
    end

    if data then
        page.status:SetText("")
    elseif (UnitLevel(self.unit) or 0) < 10 then
        page.status:SetText(L["Таланты появляются с 10 уровня"])
    elseif (self.talentTries or 0) >= MAX_TALENT_TRIES then
        page.status:SetText(L["Клиент не прислал таланты. Подойдите ближе и откройте осмотр ещё раз."])
    else
        page.status:SetText(L["Загрузка талантов..."])
    end

    local best, bestTab = -1, nil
    for tab = 1, tabs do
        if data[tab].spent > best then best, bestTab = data[tab].spent, tab end
    end

    for index, tree in ipairs(page.trees) do
        if index > tabs then
            tree:Hide()
        else
            tree:Show()

            local treeData = data[index]
            local name, icon, spent = treeData.name, treeData.icon, treeData.spent
            tree.icon:SetTexture(icon)
            tree.name:SetText(name or "")
            tree.points:SetText(spent)

            if index == bestTab and best > 0 then
                tree.name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                tree.points:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            else
                tree.name:SetTextColor(0.80, 0.81, 0.85)
                tree.points:SetTextColor(0.80, 0.81, 0.85)
            end

            local talents, maxTier, maxColumn = treeData.talents, 1, 1
            for _, entry in ipairs(talents) do
                if entry[3] > maxTier then maxTier = entry[3] end
                if entry[4] > maxColumn then maxColumn = entry[4] end
            end

            local gridW, gridH = TREE_W - 14, 330
            local step = math.floor(math.min(TALENT_STEP, gridW / maxColumn, gridH / maxTier))
            local size = step - 4
            local offsetX = math.floor((gridW - step * maxColumn) / 2)

            for slot, data in ipairs(talents) do
                local button = tree.buttons[slot]
                if not button then
                    button = self:BuildTalent(tree)
                    tree.buttons[slot] = button
                end

                local talent, talentIcon, tier, column, rank, maxRank = unpack(data)

                button.tab, button.index, button.group = index, talent, group
                button:SetSize(size, size)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", tree.grid, "TOPLEFT", offsetX + (column - 1) * step + 2, -(tier - 1) * step)

                button.icon:SetTexture(talentIcon)

                if rank > 0 then
                    button.icon:SetDesaturated(false)
                    button.icon:SetVertexColor(1, 1, 1, 1)
                    button.rank:SetText(rank)
                    if rank >= maxRank then
                        button.rank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
                        for _, edge in ipairs(button.edges) do edge:SetVertexColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.9) end
                    else
                        button.rank:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                        for _, edge in ipairs(button.edges) do edge:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9) end
                    end
                else
                    button.icon:SetDesaturated(true)
                    button.icon:SetVertexColor(1, 1, 1, 0.3)
                    button.rank:SetText("")
                    for _, edge in ipairs(button.edges) do edge:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6) end
                end

                button:Show()
            end

            for slot = #talents + 1, #tree.buttons do tree.buttons[slot]:Hide() end
        end
    end
end

function Inspect:FillGlyphs()
    local S = Style()
    local page = self.pages.glyphs
    local unit = self.unit

    for row, glyphIndex in ipairs(GLYPH_ORDER) do
        local item = page.items[row]
        local glyphType, spell
        if C_Inspect then glyphType, spell = Call(C_Inspect.GetGlyphSocketInfo, unit, glyphIndex) end

        local minor = glyphType == 2 or (glyphType == nil and (glyphIndex == 2 or glyphIndex == 3 or glyphIndex == 5))
        item.kind:SetText(minor and L["Малый символ"] or L["Большой символ"])

        local name, _, icon
        if spell then name, _, icon = GetSpellInfo(spell) end

        item.spell = spell
        if name then
            item.name:SetText(name)
            item.name:SetTextColor(0.94, 0.94, 0.96)
            item.icon:SetTexture(icon or GetSpellTexture(spell))
            item.icon:SetVertexColor(1, 1, 1, 1)
            local edge = minor and S.ACCENT or S.GOLD
            for _, line in ipairs(item.edges) do line:SetVertexColor(edge[1], edge[2], edge[3], 0.9) end
        else
            item.name:SetText(L["Пусто"])
            item.name:SetTextColor(0.45, 0.46, 0.50)
            item.icon:SetTexture(WHITE)
            item.icon:SetVertexColor(0.08, 0.09, 0.12, 1)
            for _, line in ipairs(item.edges) do line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6) end
        end
    end
end

local function WinRate(wins, games)
    if not games or games <= 0 then return "-" end
    return math.floor(wins / games * 100 + 0.5) .. "%"
end

function Inspect:FillPvP()
    local page = self.pages.pvp
    local unit = self.unit
    ResetRows(page)

    AddRow(page, L["Арена"], L["рейтинг / игры / победы"], true)

    for _, bracket in ipairs(PVP_BRACKETS) do
        local label = _G["ARENA_INSPECT_BRECKET_" .. bracket] or tostring(bracket)
        local has, rating, games, wins
        if C_Inspect then has, rating, games, wins = Call(C_Inspect.GetPvpStats, unit, bracket) end
        if has then
            AddRow(page, label, string.format("%d / %d / %d (%s)", rating or 0, games or 0, wins or 0, WinRate(wins, games)))
        else
            AddRow(page, label, "-")
        end
    end

    local rankName, _, _, rating, weekWins, weekGames, totalWins, totalGames
    if C_PvP then
        rankName, _, _, rating, weekWins, weekGames, totalWins, totalGames = Call(C_PvP.GetUnitRatedBattlegroundRankInfo, unit)
    end

    AddRow(page, L["Рейтинговые поля боя"], nil, true)
    AddRow(page, L["Звание"], rankName or "-")
    AddRow(page, L["Рейтинг"], (rating and rating > 0) and tostring(rating) or "-")
    AddRow(page, L["Неделя"], string.format("%d / %d (%s)", weekWins or 0, weekGames or 0, WinRate(weekWins, weekGames)))
    AddRow(page, L["Сезон"], string.format("%d / %d (%s)", totalWins or 0, totalGames or 0, WinRate(totalWins, totalGames)))

    local todayHK, todayHonor, yesterdayHK, yesterdayHonor, lifetimeHK = Call(GetInspectHonorData)

    AddRow(page, L["Честь"], nil, true)
    AddRow(page, L["Почётные победы сегодня"], tostring(todayHK or 0))
    AddRow(page, L["Почётные победы вчера"], tostring(yesterdayHK or 0))
    AddRow(page, L["Честь вчера"], tostring(yesterdayHonor or 0))
    AddRow(page, L["Почётные победы всего"], tostring(lifetimeHK or 0))
end

function Inspect:FillGuild()
    local page = self.pages.guild
    local unit = self.unit
    local guildName, rankName = GetGuildInfo(unit)

    for _, line in ipairs(page.lines) do line:SetText("") end

    if not guildName or guildName == "" then
        page.name:SetText(L["Не состоит в гильдии"])
        return
    end

    page.name:SetText("<" .. guildName .. ">")
    page.lines[1]:SetText(L["Звание"] .. ": |cffffffff" .. (rankName or "-") .. "|r")

    if C_Inspect then
        local level, members, factionID = Call(C_Inspect.GetGuildInfo, unit)
        local factionGroup = UnitFactionGroup(unit)
        local faction = factionGroup == "Alliance" and FACTION_ALLIANCE or FACTION_HORDE
        if factionID and PLAYER_FACTION_GROUP and PLAYER_FACTION_GROUP[factionID] then
            faction = _G["FACTION_" .. string.upper(PLAYER_FACTION_GROUP[factionID])] or faction
        end

        if level and INSPECT_GUILD_LEVEL then
            page.lines[2]:SetFormattedText(INSPECT_GUILD_LEVEL, level, faction or "")
        end
        if members and INSPECT_GUILD_ONLINE then
            page.lines[3]:SetFormattedText(INSPECT_GUILD_ONLINE, members)
        end
    end
end

function Inspect:Refresh()
    if not self.active then return end

    local unit = InspectFrame and InspectFrame.unit or self.unit
    if not unit or not UnitExists(unit) then return end
    self.unit = unit

    self:FillHeader()
    self:FillSlots()
    self:FillPage()

    if self.missing then self:Retry() end
end

function Inspect:Retry()
    if self.retryQueued or (self.retries or 0) >= MAX_RETRIES or not NS.After then return end
    self.retryQueued = true
    self.retries = (self.retries or 0) + 1

    NS.After(0.5, function()
        Inspect.retryQueued = nil
        Inspect:Refresh()
    end)
end

function Inspect:Request()
    local unit = self.unit
    if not unit then return end

    if C_Inspect then
        Call(C_Inspect.RequestInspectInfoEx, unit)
        Call(C_Inspect.RequestAvgItemLevel, unit)
        local guildName = GetGuildInfo(unit)
        if guildName and guildName ~= "" then Call(C_Inspect.RequestGuildInfo, unit) end
    end

    if HasInspectHonorData and not HasInspectHonorData() and RequestInspectHonorData then
        Call(RequestInspectHonorData)
    end
end

function Inspect:ShowModel()
    local model = self.model
    model:ClearModel()
    model:SetUnit(self.unit)
    model:SetFacing(0.4)
    pcall(model.SetPortraitZoom, model, 0.85)
    pcall(model.SetCamDistanceScale, model, 0.9)
    pcall(model.SetPosition, model, 0, 0, 0)
    pcall(model.SetModelScale, model, 1)
end

function Inspect:Open()
    local unit = InspectFrame and InspectFrame.unit
    if not unit or not Enabled() then
        Silence(false)
        return
    end

    if not self:Build() then
        Silence(false)
        return
    end

    local ui = NS.NarciUI
    if ui and ui.isShown and ui.Hide then pcall(ui.Hide, ui) end

    self.active = true
    self.unit = unit
    self.retries = 0
    self.stale = false
    self.talentTries, self.talentAsked = 0, nil

    Silence(true)
    if Options().hideHUD ~= false then self:HideHUD() end
    self:ApplyScale()
    self:ApplyLook()

    self:ShowModel()
    self:Request()

    local S = Style()
    self.dim:Show()
    self.root:Show()
    if S.FadeIn then
        S.FadeIn(self.dim, 0.3)
        S.FadeIn(self.root, 0.25)
    end

    local startTab = Options().startTab or "last"
    self:SelectTab(startTab ~= "last" and startTab or self.tab or "talents")
    self:Refresh()
end

function Inspect:Close()
    if not self.active then return end
    self.active = nil
    self.unit = nil
    self.retryQueued = nil

    GameTooltip:Hide()
    if self.root then self.root:Hide() end
    if self.dim then self.dim:Hide() end
    if self.model then self.model:ClearModel() end

    Silence(false)
    self:RestoreHUD()
end

function Inspect:Dismiss()
    if InspectFrame and InspectFrame:IsShown() then
        HideUIPanel(InspectFrame)
    end
    self:Close()
end

function Inspect:ShowStock()
    self.stockOnce = true
    self:Close()
end

function Inspect:DressUp()
    local unit = self.unit
    if not unit then return end

    if type(InspectPaperDollViewButton_OnClick) == "function" then
        pcall(InspectPaperDollViewButton_OnClick)
    end

    self:Dismiss()

    if DressUpFrame and not DressUpFrame:IsShown() then
        ShowUIPanel(DressUpFrame)
    end
end

function Inspect:HideHUD()
    if self.hidHUD or InCombatLockdown() then return end

    local ui = NS.NarciUI
    if not ui or ui.isShown or not ui.HideOtherAddons then return end

    self.hidHUD = true
    pcall(ui.HideOtherAddons, ui)

    self.hiddenMap = {}
    for _, name in ipairs({ "MinimapCluster", "Minimap", "NarciSirus_MinimapFrame" }) do
        local frame = _G[name]
        if frame and frame:IsShown() then
            frame:Hide()
            self.hiddenMap[#self.hiddenMap + 1] = frame
        end
    end
end

function Inspect:RestoreHUD()
    if not self.hidHUD then return end
    self.hidHUD = nil

    local ui = NS.NarciUI
    if ui and not ui.isShown and ui.RestoreOtherAddons then
        pcall(ui.RestoreOtherAddons, ui)
    end

    for _, frame in ipairs(self.hiddenMap or {}) do frame:Show() end
    self.hiddenMap = nil
end

function Inspect:Hook()
    if self.hooked or not InspectFrame then return end
    self.hooked = true

    if type(_G.NotifyInspect) == "function" then
        hooksecurefunc("NotifyInspect", function(unit)
            if not Inspect.active or not Inspect.unit then return end
            Inspect.stale = not (unit and UnitIsUnit(unit, Inspect.unit))
        end)
    end

    if type(_G.ClearInspectPlayer) == "function" then
        hooksecurefunc("ClearInspectPlayer", function()
            if Inspect.active then Inspect.stale = true end
        end)
    end

    InspectFrame:HookScript("OnShow", function()
        if not Enabled() or Inspect.stockOnce then
            Silence(false)
            return
        end

        Silence(true)
        if NS.After then
            NS.After(0, function()
                if InspectFrame:IsShown() then Inspect:Open() end
            end)
        else
            Inspect:Open()
        end
    end)

    InspectFrame:HookScript("OnHide", function()
        Inspect.stockOnce = nil
        Inspect:Close()
    end)

    if type(_G.InspectFrame_UnitChanged) == "function" then
        hooksecurefunc("InspectFrame_UnitChanged", function()
            if not Inspect.active then return end
            Inspect.unit = InspectFrame.unit
            Inspect.retries = 0
            Inspect.stale = false
            Inspect.talentTries, Inspect.talentAsked = 0, nil
            Inspect:ShowModel()
            Inspect:Request()
            Inspect:Refresh()
        end)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("UNIT_INVENTORY_CHANGED")
driver:RegisterEvent("UNIT_MODEL_CHANGED")
driver:RegisterEvent("INSPECT_TALENT_READY")
driver:RegisterEvent("INSPECT_HONOR_UPDATE")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")

local register = driver.RegisterCustomEvent or _G.RegisterCustomEvent
if register then
    for _, event in ipairs({
        "INSPECT_ITEM_LEVEL_UPDATE", "INSPECT_GLYPH_INFO_UPDATE",
        "INSPECT_GUILD_INFO_UPDATE", "INSPECT_BG_INFO_AVAILABLE",
    }) do
        pcall(register, driver, event)
    end
end

driver:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
        Inspect:Hook()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        Inspect:RestoreHUD()
        return
    end

    if not Inspect.active then return end

    if event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == Inspect.unit then
            Inspect.retries = 0
            Inspect:Refresh()
        end
    elseif event == "UNIT_MODEL_CHANGED" then
        if arg1 == Inspect.unit then Inspect:ShowModel() end
    elseif event == "INSPECT_TALENT_READY" or event == "INSPECT_HONOR_UPDATE"
        or event == "INSPECT_GLYPH_INFO_UPDATE" or event == "INSPECT_GUILD_INFO_UPDATE"
        or event == "INSPECT_BG_INFO_AVAILABLE" then
        Inspect:FillHeader()
        Inspect:FillPage()
    elseif event == "INSPECT_ITEM_LEVEL_UPDATE" then
        Inspect:FillHeader()
    end
end)
