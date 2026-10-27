local addonName, NS = ...
local L = NS.L

local Settings = {}
NS.Settings = Settings

local WHITE = "Interface\\Buttons\\WHITE8x8"

local PANEL_W = 720
local PANEL_H = 640
local SIDE_W = 190
local TOP_H = 46
local FOOT_H = 26
local PAD = 16

local pages = {}
local buttons = {}
local current

local HINT_W = 270
local HINT_FADE = 0.18
local HINT_TYPE_SPEED = 170

local function Style()
    return NS.Styling
end

local function HintGroup(key)
    if key:find("^bar%d") or key == "stance" then return "bar" end
    if key:find("^unit_") then return "unit" end
    return key
end

local function HintText(page, text)
    local hints = NS.SettingsHints
    if not hints or type(text) ~= "string" then return end
    local source = NS.LSource and NS.LSource(text) or text
    return hints[(page.hintGroup or "") .. "|" .. source] or hints[source]
end

local function AddHint(page, text, top, frame)
    page.pendingHint = nil
    local body = HintText(page, text)
    if not body then return end
    page.hints = page.hints or {}
    page.hints[#page.hints + 1] = { title = text, body = body, top = top, bottom = page.offset, frame = frame }
end

local function TakePending(page)
    local pending = page.pendingHint
    page.pendingHint = nil
    if pending then AddHint(page, pending.text, pending.top) end
end

local function CharEnds(text)
    local ends = {}
    local index, length = 1, #text
    while index <= length do
        local byte = text:byte(index)
        index = index + (byte >= 240 and 4 or byte >= 224 and 3 or byte >= 192 and 2 or 1)
        ends[#ends + 1] = index - 1
    end
    return ends
end

local function Lower(text)
    text = tostring(text or ""):gsub("[A-Z]", function(c) return string.char(c:byte() + 32) end)
    text = text:gsub("\208\129", "\209\145")
    text = text:gsub("\208([\144-\175])", function(c)
        local b = c:byte()
        if b < 160 then return "\208" .. string.char(b + 32) end
        return "\209" .. string.char(b - 32)
    end)
    return text
end

local function Index(page, text)
    if type(text) ~= "string" or text == "" then return end
    page.search = (page.search or "") .. "\n" .. Lower(text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function Section(page, text)
    local S = Style()
    page.pendingHint = nil

    Index(page, text)
    local label = page:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    label:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    label:SetText(text)

    S.CreateSectionRule(page, label, PANEL_W - SIDE_W - 70)
    page.offset = page.offset - 26

    return label
end

local function Check(page, text, value, callback)
    Index(page, text)
    local top = page.offset
    local widget = NS.Widgets.CreateThemedCheckbox(page, text, value, callback)
    widget:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    page.offset = page.offset - 24
    AddHint(page, text, top)
    return widget
end

local function Slider(page, text, minimum, maximum, step, value, callback, suffix)
    Index(page, text)
    local top = page.offset
    local widget = NS.Widgets.CreateThemedSlider(page, text, minimum, maximum, step, value, callback, suffix)
    widget:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    widget:SetWidth(PANEL_W - SIDE_W - 80)
    page.offset = page.offset - 40
    AddHint(page, text, top)
    return widget
end

local function Label(page, text)
    local S = Style()

    local label = page:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(11), "")
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    label:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    label:SetText(text)
    Index(page, text)
    page.pendingHint = { text = text, top = page.offset }
    page.offset = page.offset - 20

    return label
end

local function Note(page, text)
    local S = Style()

    local label = page:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(10), "")
    label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    label:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    label:SetWidth(PANEL_W - SIDE_W - 80)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    Index(page, text)
    local lines = math.ceil((label:GetStringWidth() or 0) * 1.08 / (PANEL_W - SIDE_W - 80))
    local height = math.max(math.ceil(label:GetStringHeight() or 0), lines * 12)
    page.offset = page.offset - math.max(26, height + 14)

    return label
end

local function Buttons(page, list)
    local previous
    local made = {}

    for _, entry in ipairs(list) do
        Index(page, entry.label)
        local button = NS.Widgets.CreateThemedButton(page, entry.label, entry.width or 130, 24, entry.action)
        AddHint(page, entry.label, nil, button)
        made[#made + 1] = button

        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
        end

        previous = button
    end

    page.offset = page.offset - 32
    return made
end

local function PV(name, ...)
    local P = NS.SettingsPreview
    local fn = P and P[name]
    if not fn then return end
    if select("#", ...) > 0 then return fn(...) end
    return fn
end

local function Picker(page, options, value, callback, width, preview)
    for _, option in ipairs(options or {}) do Index(page, option.label) end
    local widget = NS.Widgets.CreateOptionPicker(page, options, value, callback, width or (PANEL_W - SIDE_W - 80))
    if preview and NS.SettingsPreview then NS.SettingsPreview:Attach(widget, preview) end
    widget:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    page.offset = page.offset - (widget:GetHeight() + 10)
    TakePending(page)
    return widget
end

local function TextInput(page, text, value, callback, maxLetters)
    Label(page, text)
    local box = NS.Widgets.CreateThemedEditBox(page, PANEL_W - SIDE_W - 80, 22, maxLetters or 40)
    box:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    box:SetText(value or "")
    box:SetCursorPosition(0)
    local function Commit(self)
        if self:GetText() ~= (self.committed or "") then
            self.committed = self:GetText()
            callback(self.committed)
        end
    end
    box.committed = value or ""
    box:SetScript("OnEnterPressed", function(self)
        Commit(self)
        self:ClearFocus()
    end)
    box:HookScript("OnEditFocusLost", Commit)
    page.offset = page.offset - 32
    TakePending(page)
    return box
end

local function WithExtras(options, extras)
    for _, extra in ipairs(extras or {}) do
        options[#options + 1] = { key = extra.key, label = extra.label }
    end
    return options
end

local function UIExtras(kind)
    return NS.NarciUI and NS.NarciUI.Extras and NS.NarciUI:Extras(kind) or {}
end

function Settings:FindHint()
    if NS.SettingsPreview and NS.SettingsPreview:IsShown() then return end
    local page = current and pages[current]
    if not page or not page.hints or not page.scroll:IsShown() or not page.scroll:IsMouseOver() then return end

    local top = page:GetTop()
    if not top then return end

    local _, y = GetCursorPosition()
    local offset = y / page:GetEffectiveScale() - top

    for _, hint in ipairs(page.hints) do
        if hint.frame then
            if hint.frame:IsShown() and hint.frame:IsMouseOver() then return hint end
        elseif offset <= hint.top and offset > hint.bottom then
            return hint
        end
    end
end

function Settings:BuildHint(f)
    local S = Style()

    local card = CreateFrame("Frame", nil, f)
    card:SetWidth(HINT_W)
    card:SetFrameStrata("FULLSCREEN_DIALOG")
    card:SetFrameLevel(f:GetFrameLevel() + 40)
    card:SetClampedToScreen(true)
    card:EnableMouse(false)

    S.CreateShadow(card, 5, 0.45)

    local ground = card:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(card)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Tint(0.016, 0.018, 0.026, 0.97))

    S.CreateEdges(card, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local stripe = card:CreateTexture(nil, "ARTWORK")
    stripe:SetTexture(WHITE)
    stripe:SetWidth(2)
    stripe:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    stripe:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 1, 1)
    stripe:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
    title:SetWidth(HINT_W - 22)
    title:SetJustifyH("LEFT")

    local body = card:CreateFontString(nil, "OVERLAY")
    body:SetFont(NS.FONT, NS.FS(11), "")
    body:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    body:SetWidth(HINT_W - 22)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")

    card.title, card.body = title, body
    card:Hide()

    card:SetScript("OnUpdate", function(selfCard, step) Settings:AnimateHint(selfCard, step) end)

    local poll = 0
    f:SetScript("OnUpdate", function(_, step)
        poll = poll + step
        if poll < 0.05 then return end
        poll = 0

        local hint = Settings:FindHint()
        if hint then
            Settings:ShowHint(hint)
        elseif card.hint and not card.leaving then
            card.leaving = 0
        end
    end)

    f:HookScript("OnHide", function()
        card:Hide()
        card.hint, card.leaving = nil, nil
    end)

    self.hintCard = card
end

function Settings:PlaceHint(card, slide)
    local f = NS.settingsFrame
    card:ClearAllPoints()
    if card.side > 0 then
        card:SetPoint("TOPLEFT", f, "TOPRIGHT", 10 + slide, card.offsetY + 4)
    else
        card:SetPoint("TOPRIGHT", f, "TOPLEFT", -10 - slide, card.offsetY + 4)
    end
end

function Settings:ShowHint(hint)
    local card, f = self.hintCard, NS.settingsFrame
    if not card or not f then return end

    if card.hint == hint then
        if card.leaving then
            card.leaving = nil
            card:SetAlpha(1)
        end
        return
    end

    local visible = card:IsShown() and not card.leaving
    card.hint, card.leaving = hint, nil

    local text = L[hint.body]
    card.title:SetText(hint.title)
    card.body:SetHeight(600)
    card.body:SetText(text)
    local width = HINT_W - 22
    local lines = math.ceil((card.body:GetStringWidth() or 0) * 1.12 / width)
    local height = math.max(math.ceil(card.body:GetStringHeight() or 12), lines * 13, 13)
    card.body:SetHeight(height)
    card:SetHeight(10 + math.ceil(card.title:GetStringHeight() or 12) + 6 + height + 12)

    card.fullText = text
    card.ends = CharEnds(text)
    card.typed = 0
    card.elapsed = visible and HINT_FADE or 0
    card.settled = nil
    card.body:SetText("")

    local page = pages[current]
    local top = hint.frame and hint.frame:GetTop() or (page:GetTop() or 0) + hint.top
    card.offsetY = top - (f:GetTop() or top)

    local scale = f:GetEffectiveScale()
    local room = UIParent:GetRight() * UIParent:GetEffectiveScale() - (f:GetRight() or 0) * scale
    card.side = room >= (HINT_W + 14) * scale and 1 or -1

    if not Style().AnimationsEnabled() then
        card.elapsed = HINT_FADE
        card.typed = #card.ends
        card.body:SetText(text)
    end

    card:SetAlpha(visible and 1 or 0)
    self:PlaceHint(card, visible and 0 or 14)
    card:Show()
end

function Settings:AnimateHint(card, step)
    if card.leaving then
        card.leaving = card.leaving + step
        local alpha = 1 - card.leaving / 0.12
        if alpha <= 0 then
            card:Hide()
            card.hint, card.leaving = nil, nil
            return
        end
        card:SetAlpha(alpha)
        return
    end

    if not card.hint then return end

    card.elapsed = card.elapsed + step

    if not card.settled then
        local progress = math.min(1, card.elapsed / HINT_FADE)
        local eased = 1 - (1 - progress) ^ 3
        card:SetAlpha(eased)
        self:PlaceHint(card, (1 - eased) * 14)
        if progress >= 1 then card.settled = true end
    end

    if card.typed < #card.ends then
        local typing = card.elapsed - HINT_FADE * 0.5
        if typing > 0 then
            local count = math.min(#card.ends, math.floor(typing * HINT_TYPE_SPEED))
            if count > card.typed then
                card.typed = count
                card.body:SetText(card.fullText:sub(1, card.ends[count]))
            end
        end
    end
end

function Settings:Select(key)
    for name, page in pairs(pages) do
        page.scroll:SetShown(name == key)
    end

    for name, button in pairs(buttons) do
        local active = name == key

        button.bar:SetShown(active)
        button.wash:SetShown(active)

        if active then
            button.label:SetTextColor(Style().ACCENT_GLOW[1], Style().ACCENT_GLOW[2], Style().ACCENT_GLOW[3])
        else
            button.label:SetTextColor(Style().TEXT_BRIGHT[1], Style().TEXT_BRIGHT[2], Style().TEXT_BRIGHT[3])
        end
    end

    current = key
    self.folds = self.folds or {}
    self.folds[(self.parentOf and self.parentOf[key]) or key] = nil
    self:LayoutSide()
end

function Settings:Expanded(key)
    local fold = self.folds and self.folds[key]
    if fold ~= nil then return fold end
    return current ~= nil and ((self.parentOf and self.parentOf[current]) or current) == key
end

function Settings:ToggleFold(key)
    self.folds = self.folds or {}
    self.folds[key] = not self:Expanded(key)
    self:LayoutSide()
end

function Settings:LayoutSide()
    local entries, holder = self.sideEntries, self.sideHolder
    if not entries or not holder then return end

    local S = Style()
    local query = self.searchQuery
    local groupShown = {}
    local found = 0

    for _, entry in ipairs(entries) do
        if entry.key then
            local show
            if query then
                local page = pages[entry.key]
                show = entry.lower:find(query, 1, true) ~= nil
                    or (page and page.search and page.search:find(query, 1, true) ~= nil)
            elseif entry.parent then
                show = self:Expanded(entry.parent)
            else
                show = true
            end
            entry.visible = show and true or false
            if show then
                groupShown[entry.group] = true
                found = found + 1
            end
        end
    end

    local y = 2
    for _, entry in ipairs(entries) do
        if entry.header then
            local show = groupShown[entry.group]
            entry.header:SetShown(show and true or false)
            if entry.rule then entry.rule:SetShown(show and true or false) end
            if show then
                y = y + 8
                entry.header:ClearAllPoints()
                entry.header:SetPoint("TOPLEFT", holder, "TOPLEFT", 12, -y)
                y = y + 18
            end
        else
            local button = entry.button
            button:SetShown(entry.visible)
            if entry.visible then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", holder, "TOPLEFT", (entry.parent and not query) and 22 or 10, -y)
                y = y + (entry.parent and 22 or 28)
            end
            if entry.arrow then
                entry.arrow:SetShown(not query)
                if entry.fold then entry.fold:SetShown(not query) end
                entry.arrow:SetTexture(S.Media(self:Expanded(entry.key) and "IconMinus" or "IconPlus"))
            end
        end
    end

    if self.sideEmpty then
        local none = query ~= nil and found == 0
        self.sideEmpty:SetShown(none)
        self.sideEmpty:ClearAllPoints()
        self.sideEmpty:SetPoint("TOPLEFT", holder, "TOPLEFT", 14, -12)
        if none then y = 40 end
    end

    holder:SetHeight(y + 8)
    if self.updateSide then self.updateSide() end
end

Settings.extensions = {}

function Settings:Extend(key, builder, owner)
    if type(key) ~= "string" or type(builder) ~= "function" then return false end
    self.extensions[key] = self.extensions[key] or {}
    table.insert(self.extensions[key], { build = builder, owner = owner })
    return true
end

Settings.extraCategories = {}

function Settings:AddExtraCategory(def, owner)
    if type(def) ~= "table" or type(def.key) ~= "string" or type(def.build) ~= "function" then return false end
    local key = "ext_" .. def.key
    for _, entry in ipairs(self.extraCategories) do
        if entry.key == key then return false end
    end
    local builder = def.build
    table.insert(self.extraCategories, {
        key = key, title = def.title or def.key, group = def.group, parent = def.parent,
        build = function(page)
            local ok, err = pcall(builder, page, NS.SettingsUI)
            if not ok then NS.Print("|cffff6060" .. tostring(owner or def.key) .. "|r - settings: " .. tostring(err)) end
        end,
    })
    return true
end

function Settings:RunExtensions(key, page)
    for _, ext in ipairs(self.extensions[key] or {}) do
        local ok, err = pcall(ext.build, page, NS.SettingsUI)
        if not ok then NS.Print(tostring(ext.owner or "?") .. " - " .. key .. ": " .. tostring(err)) end
    end
end

function Settings:Search(text)
    text = Lower(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    self.searchQuery = text ~= "" and text or nil
    if self.sideScroll then self.sideScroll:SetVerticalScroll(0) end
    self:LayoutSide()
end

function Settings:AddCategory(frame, key, title, index, child)
    local S = Style()

    local holder = self.sideContent or frame
    local button = CreateFrame("Button", nil, holder)
    button:SetSize(SIDE_W - (child and 28 or 20), child and 22 or 26)
    if self.sideContent then
        button:SetPoint("TOPLEFT", holder, "TOPLEFT", child and 22 or 10, -index - 2)
    else
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", child and 22 or 10, -TOP_H - index)
    end

    local wash = button:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(button)
    if S.CORNER_RADIUS > 0 then
        wash:SetTexture(S.Media("Fade"))
        wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.32)
    else
        wash:SetTexture(WHITE)
        wash:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.20,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.01)
    end
    wash:Hide()

    local bar = button:CreateTexture(nil, "BORDER")
    bar:SetWidth(2)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    if S.CORNER_RADIUS > 0 then
        bar:SetWidth(3)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -4)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 4)
        S.RoundTexture(bar, 1.5)
    else
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    end
    bar:Hide()

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(child and 11 or 12), "")
    label:SetPoint("LEFT", button, "LEFT", child and 8 or 12, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    label:SetText(title)

    button.wash = wash
    button.bar = bar
    button.label = label

    button:SetScript("OnEnter", function(self)
        if current ~= key then self.wash:Show() end
    end)

    button:SetScript("OnLeave", function(self)
        if current ~= key then self.wash:Hide() end
    end)

    button:SetScript("OnClick", function()
        if current == key and Settings.hasChildren and Settings.hasChildren[key] then
            Settings:ToggleFold(key)
        else
            Settings:Select(key)
        end
    end)

    local scroll = CreateFrame("ScrollFrame", "NarcissusSirus_SettingsPage_" .. key, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_W + 6, -TOP_H)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, FOOT_H)
    scroll:Hide()
    S.StyleScrollBar(scroll)

    local page = CreateFrame("Frame", nil, scroll)
    page:SetWidth(PANEL_W - SIDE_W - 50)
    page:SetHeight(1)
    page.offset = -4
    page.scroll = scroll
    page.hintGroup = HintGroup(key)
    scroll:SetScrollChild(page)

    buttons[key] = button
    pages[key] = page

    return page
end

local function BuildCharacter(page)
    local db = NS.db

    local function RefreshSlots()
        if NS.NarciUI and NS.NarciUI.isShown then NS.NarciUI:UpdateSlots() end
    end

    Section(page, L["Слоты и предметы"])

    Check(page, L["Показывать ур. предметов на слотах"], db.showItemLevel, function(val)
        db.showItemLevel = val
        if NS.ItemLevel then
            if val then NS.ItemLevel:Update() else NS.ItemLevel:Hide() end
        end
        RefreshSlots()
    end)

    Check(page, L["Показывать метки чар"], db.showEnchantInfo, function(val)
        db.showEnchantInfo = val
        if NS.EnchantInfo then
            if val then NS.EnchantInfo:Update() else NS.EnchantInfo:Hide() end
        end
        RefreshSlots()
    end)

    Check(page, L["Показывать самоцветы у слотов"], db.showGemInfo, function(val)
        db.showGemInfo = val
        RefreshSlots()
    end)

    Check(page, L["Показывать сравнение предметов"], db.showComparison, function(val)
        db.showComparison = val
        if NS.ItemComparison then
            if val then NS.ItemComparison:Enable() else NS.ItemComparison:Disable() end
        end
    end)

    Check(page, L["Показывать названия предметов"], db.showItemNames, function(val)
        db.showItemNames = val
        RefreshSlots()
    end)

    Check(page, L["Скрывать пустые ячейки"], db.hideEmptySlots, function(val)
        db.hideEmptySlots = val
        RefreshSlots()
    end)

    Check(page, L["Смена вещей по Alt"], db.slotFlyout, function(val)
        db.slotFlyout = val
        if not val and NS.SlotFlyout then NS.SlotFlyout:Hide() end
    end)

    Slider(page, L["Длина названий предметов"], 12, 40, 1, db.nameLength or 24, function(val)
        db.nameLength = val
        RefreshSlots()
    end)

    Section(page, L["Окно"])

    Check(page, L["Подсвечивать важные характеристики"], db.showStatCaps, function(val)
        db.showStatCaps = val
        if NS.StatsPanel and NS.StatsPanel.frame and NS.StatsPanel.frame:IsShown() then
            NS.StatsPanel:Update()
        end
    end)

    if NS.StatPriority and NS.StatPriority.Tiers then
        Label(page, L["Комплект для подсветки"])
        local tierOptions = { { key = "auto", label = "авто" } }
        for _, tier in ipairs(NS.StatPriority:Tiers()) do
            tierOptions[#tierOptions + 1] = { key = tostring(tier), label = "Т" .. tier }
        end
        local tierPicker
        tierPicker = Picker(page, tierOptions, db.tierOverride and tostring(db.tierOverride) or "auto", function(value)
            tierPicker:Refresh(value)
            NS.StatPriority:SetTierOverride(value ~= "auto" and tonumber(value) or nil)
        end)
        Note(page, L["Обычно комплект определяется по надетым вещам. Выберите его вручную, если определение ошиблось."])
    end

    Check(page, L["Открывать окно в бою"], db.showInCombat, function(val)
        db.showInCombat = val
    end)

    Check(page, L["Скрывать штатный интерфейс"], db.hideBlizzardUI, function(val)
        db.hideBlizzardUI = val
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:RestoreOtherAddons()
            NS.NarciUI:HideOtherAddons()
        end
    end)

    Label(page, L["Вкладка при открытии"])

    local openOptions = {
        { key = "none",             label = L["нет"] },
        { key = "StatsPanel",       label = L["Статы"] },
        { key = "Enhancements",     label = L["Усиления"] },
        { key = "TalentPanel",      label = L["Таланты"] },
        { key = "ProfessionsPanel", label = L["Профессии"] },
        { key = "TitleManager",     label = L["Титулы"] },
        { key = "OutfitManager",    label = L["Быстрые наборы"] },
    }

    local openPicker
    openPicker = Picker(page, openOptions, db.openPanel or "none", function(key)
        db.openPanel = key
        db.showStatsPanel = (key == "StatsPanel")
        openPicker:Refresh(key)
    end)

end

local function BuildLook(page)
    local db = NS.db

    Section(page, L["Оформление"])

    Slider(page, L["Затемнение мира"], 0, 100, 5, db.worldDim or 0, function(val)
        db.worldDim = val
        if NS.NarciUI then NS.NarciUI:ApplyWorldDim() end
    end, "%")

    local scaleSlider
    local autoScaleCheck = Check(page, L["Подбирать масштаб автоматически"], db.scaleOverride == nil, function(val)
        if val then
            db.scaleOverride = nil
        else
            local ui = NS.NarciUI
            db.scaleOverride = (ui and ui._appliedScale) or 1
            if scaleSlider then
                scaleSlider:SetValue(math.floor(db.scaleOverride * 100 + 0.5))
            end
        end
        if NS.NarciUI then NS.NarciUI:ApplyScale() end
    end)

    page.offset = page.offset - 6

    scaleSlider = Slider(page, L["Масштаб окна"], 55, 100, 1,
        math.floor(((db.scaleOverride or (NS.NarciUI and NS.NarciUI:GetAutoScale()) or 1) * 100) + 0.5),
        function(val)
            db.scaleOverride = val / 100
            autoScaleCheck:SetChecked(false)
            if NS.NarciUI then NS.NarciUI:ApplyScale() end
        end, "%")

    Section(page, L["Масштаб интерфейса"])

    local uiScaleSlider
    local uiScale = db.uiScale or {}

    Check(page, L["Уменьшать весь интерфейс"], uiScale.enabled, function(val)
        if NS.UIScale then NS.UIScale:SetEnabled(val) end
    end)

    Check(page, L["Подбирать под разрешение"], uiScale.auto ~= false, function(val)
        if NS.UIScale then
            NS.UIScale:SetAuto(val)
            if val and uiScaleSlider then
                uiScaleSlider:SetValue(math.floor(NS.UIScale:Best() * 100 + 0.5))
            end
        end
    end)

    page.offset = page.offset - 6

    uiScaleSlider = Slider(page, L["Масштаб"], 40, 115, 1,
        math.floor(((NS.UIScale and NS.UIScale:Current()) or 1) * 100 + 0.5),
        function(val)
            if NS.UIScale then NS.UIScale:SetValue(val / 100) end
        end, "%")

    Note(page, L["Чем меньше масштаб, тем больше помещается на экране и тем мельче всё выглядит. Галка выше подбирает значение, при котором интерфейс рисуется пиксель в пиксель."])

    Section(page, L["Оформление"])

    Check(page, L["Подсветка за моделью"], db.modelBacklight, function(val)
        db.modelBacklight = val
        if NS.NarciUI then NS.NarciUI:ApplyBacklight() end
    end)

    Check(page, L["Запоминать поворот модели"], db.rememberModelView, function(val)
        db.rememberModelView = val
    end)

    Check(page, L["Показывать кнопку на миникарте"], db.minimapButton, function(val)
        db.minimapButton = val
        if NS.MinimapButton then
            if val then NS.MinimapButton:Show() else NS.MinimapButton:Hide() end
        end
    end)

    Section(page, L["Цвет и язык"])

    Label(page, L["Цвет темы"])

    local accentPicker

    local function OpenCustomAccent()
        local S = NS.Styling
        local current = db.accentCustom or { S.ACCENT[1], S.ACCENT[2], S.ACCENT[3] }
        local previous = { current[1], current[2], current[3] }
        local cancelled = false

        if type(OpenColorPicker) ~= "function" or not ColorPickerFrame then return end

        OpenColorPicker({
            r = current[1], g = current[2], b = current[3],
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                db.accentCustom = { r, g, b }
                if accentPicker then accentPicker:SetCustomColor(r, g, b) end
            end,
            cancelFunc = function()
                cancelled = true
                db.accentCustom = previous
                if accentPicker then accentPicker:SetCustomColor(previous[1], previous[2], previous[3]) end
            end,
        })

        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(260)

        if not ColorPickerFrame.narciHooked then
            ColorPickerFrame.narciHooked = true
            ColorPickerFrame:HookScript("OnHide", function(self)
                local done = self.narciDone
                self.narciDone = nil
                if done then done() end
            end)
        end

        ColorPickerFrame.narciDone = function()
            if cancelled or not db.accentCustom then return end

            NS.Widgets.ShowConfirm(
                L["Применить свой цвет темы?\nИнтерфейс будет перезагружен."],
                L["Сменить"],
                function()
                    db.accentColor = "custom"
                    ReloadUI()
                end)
        end
    end

    accentPicker = NS.Widgets.CreateAccentPicker(page, db.accentColor or "emerald", function(key)
        if key == "custom" then
            OpenCustomAccent()
            return
        end

        if key == db.accentColor then return end
        NS.Widgets.ShowConfirm(
            L["Сменить цвет темы?\nИнтерфейс будет перезагружен."],
            L["Сменить"],
            function()
                db.accentColor = key
                ReloadUI()
            end)
    end)
    if NS.SettingsPreview then NS.SettingsPreview:Attach(accentPicker, PV("Accent")) end
    accentPicker:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    page.offset = page.offset - 30
    TakePending(page)

    Label(page, L["Язык"])

    Picker(page, NS.LOCALE_OPTIONS, db.locale or "auto", function(key)
        if key == (db.locale or "auto") then return end
        NS.Widgets.ShowConfirm(
            L["Сменить язык?\nИнтерфейс будет перезагружен."],
            L["Сменить"],
            function()
                db.locale = key
                ReloadUI()
            end)
    end)

    Label(page, L["Шрифт аддона"])

    local fontOptions = NS.FontOptions and NS.FontOptions() or {}
    local preview
    local fontPicker
    fontPicker = Picker(page, fontOptions, db.font or "default", function(key)
        fontPicker:Refresh(key)

        for _, option in ipairs(fontOptions) do
            if option.key == key and preview and NS.FontWorks(option.path) then
                preview:SetFont(option.path, 14, "")
            end
        end

        if key == (db.font or "default") then return end
        NS.Widgets.ShowConfirm(
            L["Сменить шрифт аддона?\nИнтерфейс будет перезагружен."],
            L["Сменить"],
            function()
                db.font = key
                ReloadUI()
            end)
    end, nil, PV("FontSample"))

    preview = page:CreateFontString(nil, "OVERLAY")
    preview:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    preview:SetWidth(PANEL_W - SIDE_W - 80)
    preview:SetJustifyH("LEFT")
    preview:SetFont(NS.FONT, NS.FS(14), "")
    preview:SetTextColor(0.92, 0.93, 0.96)
    preview:SetText(L["Съешь же ещё этих мягких французских булок. 1234567890"])
    page.offset = page.offset - 26

    Note(page, L["Меняет шрифт всех окон и панелей аддона. Шрифты клиента и других аддонов не трогает. Если в шрифте нет русских букв, они покажутся пустыми, тогда верните стандартный."])
end

local function BuildTheme(page)
    local db = NS.db
    db.theme = db.theme or {}
    local theme = db.theme
    local S = Style()

    local applyButton

    local function Store(key, value)
        theme[key] = value
        if applyButton then applyButton:Show() end
    end

    local function Choice(label, key, options, fallback, live)
        Label(page, label)
        local picker
        picker = Picker(page, options, theme[key] or fallback, function(value)
            picker:Refresh(value)
            if live then
                theme[key] = value
                live(value)
            else
                Store(key, value)
            end
        end, nil, PV("With", "theme", key, PV("Theme")))
        return picker
    end

    Note(page, L["Цвета, фон, рамки и шрифт применяются после перезагрузки интерфейса: виджеты берут их при создании. Скорость анимаций и звуки работают сразу."])

    applyButton = NS.Widgets.CreateThemedButton(page, L["Применить и перезагрузить"], 220, 24, function()
        ReloadUI()
    end)
    applyButton:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    applyButton:Hide()
    page.offset = page.offset - 34

    Section(page, L["Фон окон"])

    local tones = {}
    for _, tone in ipairs(S.BG_TONES) do
        tones[#tones + 1] = { key = tone.key, label = L[tone.name] }
    end
    Choice(L["Тон фона"], "bgTone", tones, "obsidian")

    Slider(page, L["Плотность фона"], 40, 100, 5, theme.bgDensity or 100, function(val)
        Store("bgDensity", val)
    end, "%")

    Note(page, L["Плотность меньше 100% делает окна полупрозрачными, как стекло: сквозь них виден мир. Полосы и элементы HUD настраиваются на своих страницах."])

    Section(page, L["Рамки и тени"])

    Choice(L["Рамки окон"], "border", {
        { key = "thin",     label = L["тонкая"] },
        { key = "contrast", label = L["контрастная"] },
        { key = "accent",   label = L["цвет темы"] },
        { key = "none",     label = L["без рамки"] },
    }, "thin")

    Choice(L["Тень под окнами"], "shadow", {
        { key = "none",   label = L["нет"] },
        { key = "soft",   label = L["мягкая"] },
        { key = "normal", label = L["обычная"] },
        { key = "deep",   label = L["глубокая"] },
    }, "normal")

    Choice(L["Углы окон"], "corners", {
        { key = "none",   label = L["прямые"] },
        { key = "small",  label = L["чуть скруглённые"] },
        { key = "medium", label = L["скруглённые"] },
        { key = "large",  label = L["сильно скруглённые"] },
    }, "medium")

    Section(page, L["Текст"])

    Choice(L["Оттенок текста"], "textTone", {
        { key = "neutral", label = L["нейтральный"] },
        { key = "warm",    label = L["тёплый"] },
        { key = "cool",    label = L["холодный"] },
    }, "neutral")

    Choice(L["Контраст текста"], "contrast", {
        { key = "soft",   label = L["мягкий"] },
        { key = "normal", label = L["обычный"] },
        { key = "high",   label = L["высокий"] },
    }, "normal")

    Slider(page, L["Размер шрифта аддона"], 90, 120, 5, theme.fontScale or 100, function(val)
        Store("fontScale", val)
    end, "%")

    Note(page, L["Меняет все надписи аддона сразу. Размеры, заданные ползунками на страницах рамок, панелей и чата, остаются как есть."])

    Section(page, L["Анимации и звук"])

    local speed = db.animations == false and "off" or (theme.animSpeed or "normal")
    Label(page, L["Скорость анимаций"])
    local speedPicker
    speedPicker = Picker(page, {
        { key = "off",    label = L["выкл"] },
        { key = "slow",   label = L["медленно"] },
        { key = "normal", label = L["обычно"] },
        { key = "fast",   label = L["быстро"] },
    }, speed, function(value)
        speedPicker:Refresh(value)
        if value == "off" then
            db.animations = false
        else
            db.animations = true
            theme.animSpeed = value
            S.ANIM_SCALE = S.ANIM_SPEEDS[value] or 1
        end
    end)

    Choice(L["Появление панелей"], "motion", {
        { key = "slide", label = L["сдвиг и прозрачность"] },
        { key = "fade",  label = L["только прозрачность"] },
    }, "slide", function(value)
        S.PANEL_MOTION = value ~= "fade"
    end)

    Check(page, L["Звуки интерфейса"], theme.sounds, function(val)
        theme.sounds = val and true or false
        if val then PlaySound("igCharacterInfoTab") end
    end)
end

local function PartFlag(path, defaultOn, root)
    local function Table(create)
        local t = root and root() or NS.db
        for i = 1, #path - 1 do
            if not t then return end
            if create and type(t[path[i]]) ~= "table" then t[path[i]] = {} end
            t = t[path[i]]
        end
        return t
    end

    return {
        default = defaultOn,
        get = function()
            local t = Table(false)
            local value = t and t[path[#path]]
            if value == nil then return defaultOn end
            return value and true or false
        end,
        set = function(value)
            local t = Table(true)
            if t then t[path[#path]] = value end
        end,
    }
end

local function AuctionDB()
    return NS.Auc and NS.Auc.db
end

local PARTS = {
    { section = "Окно персонажа" },
    { label = "Окно персонажа (клавиша C)", flag = PartFlag({ "replaceCharacter" }, true) },
    { label = "Таланты", flag = PartFlag({ "replaceTalents" }, true) },
    { label = "Книга заклинаний", flag = PartFlag({ "replaceSpellbook" }, true) },
    { label = "Осмотр игроков", flag = {
        default = true,
        get = function() return NS.db.inspectStyle ~= "window" end,
        set = function(value) NS.db.inspectStyle = value and "scene" or "window" end,
    } },

    { section = "Большие окна" },
    { label = "Гильдия", flag = PartFlag({ "replaceGuild" }, true) },
    { label = "Общение", flag = PartFlag({ "replaceSocial" }, true) },
    { label = "Поиск группы", flag = PartFlag({ "replaceGroupFinder" }, true) },
    { label = "Коллекции", flag = PartFlag({ "replaceCollections" }, true) },
    { label = "Достижения", flag = PartFlag({ "replaceAchievements" }, true) },
    { label = "Приключения", flag = PartFlag({ "replaceAdventure" }, true) },
    { label = "Испытания", flag = PartFlag({ "replaceChallenges" }, true) },
    { label = "Охота за головами", flag = PartFlag({ "replaceHeadHunting" }, true) },
    { label = "Журнал заданий", flag = PartFlag({ "quests", "replaceLog" }, true) },
    { label = "Меню Esc", flag = PartFlag({ "replaceGameMenu" }, true) },

    { section = "Окна клиента" },
    { label = "Диалоги с НПС", flag = PartFlag({ "dialogue", "enabled" }, true) },
    { label = "Торговцы", flag = {
        default = true,
        get = function() return NS.db.skinMerchant ~= false end,
        set = function(value)
            NS.db.skinMerchant = value
            if not value then NS.db.merchantStyle = "window" end
        end,
    } },
    { label = "Карта мира", flag = PartFlag({ "quests", "skinWorldMap" }, true) },
    { label = "Почта", flag = PartFlag({ "skinMail" }, true) },
    { label = "Учителя", flag = PartFlag({ "skinTrainer" }, true) },
    { label = "Проверка готовности", flag = PartFlag({ "skinReadyCheck" }, true) },
    { label = "Обмен", flag = PartFlag({ "skinTrade" }, true) },
    { label = "Трекер заданий", flag = PartFlag({ "tracker", "enabled" }, true) },
    { label = "Значок поиска группы", flag = PartFlag({ "queueEye", "enabled" }, true) },
    { label = "Окно очереди", flag = PartFlag({ "queueStatus", "enabled" }, true) },
    { label = "Окно профессии", flag = PartFlag({ "skinTradeSkill" }, true) },
    { label = "Трекер добычи RaidRoll", flag = PartFlag({ "skinLootTracker" }, true) },
    { label = "Окно добычи", flag = PartFlag({ "skinLootWindow" }, true) },
    { label = "Примерочная", flag = PartFlag({ "skinDressUp" }, true) },
    { label = "Книги и письма", flag = PartFlag({ "skinItemText" }, true) },
    { label = "Карта полётов", flag = PartFlag({ "skinTaxi" }, true) },
    { label = "Гербы гильдии", flag = PartFlag({ "skinTabard" }, true) },
    { label = "Хартии и регистраторы", flag = PartFlag({ "skinCharters" }, true) },
    { label = "Стойла питомцев", flag = PartFlag({ "skinPetStable" }, true) },
    { label = "Вставка камней", flag = PartFlag({ "skinSocketing" }, true) },
    { label = "Гильдейский банк", flag = PartFlag({ "skinGuildBank" }, true) },
    { label = "Таблица поля боя и мини-игр", flag = PartFlag({ "skinScore" }, true) },
    { label = "Часы и секундомер", flag = PartFlag({ "skinTimeManager" }, true) },
    { label = "Календарь", flag = PartFlag({ "skinCalendar" }, true) },
    { label = "Отчёт о смерти", flag = PartFlag({ "skinDeathRecap" }, true) },
    { label = "Улучшение предметов", flag = PartFlag({ "skinItemUpgrade" }, true) },
    { label = "Настройки чата", flag = PartFlag({ "skinChatConfig" }, true) },
    { label = "Карта поля боя", flag = PartFlag({ "skinBattleMap" }, true) },
    { label = "Окна Sirus (пропуск, рулетка, чёрный рынок)", flag = PartFlag({ "skinSirusWindows" }, true) },
    { label = "Опрос и база знаний", flag = PartFlag({ "skinSupport" }, true) },
    { label = "Уведомления", flag = PartFlag({ "skinAlerts" }, true) },
    { label = "Полосы дыхания и усталости", flag = PartFlag({ "skinMirrorTimers" }, true) },
    { label = "Кнопка особого действия", flag = PartFlag({ "skinExtraAction" }, true) },
    { label = "Панель транспорта", flag = PartFlag({ "skinVehicle" }, true) },
    { label = "Таймер начала и кнопка «Готов»", flag = PartFlag({ "skinTimer" }, true) },
    { label = "Потеря контроля", flag = PartFlag({ "skinLossOfControl" }, true) },
    { label = "Таймер заданий", flag = PartFlag({ "skinQuestTimer" }, true) },
    { label = "Приглашение в гильдию", flag = PartFlag({ "skinGuildInvite" }, true) },
    { label = "Аукцион", flag = PartFlag({ "skinAuction" }, true) },
    { label = "Магазин", flag = PartFlag({ "skinStore" }, true) },
    { label = "Окна меню", flag = PartFlag({ "skinMenus" }, true) },
    { label = "Окна группы и броски на добычу", flag = PartFlag({ "skinGroup" }, true) },
    { label = "Всплывающие окна клиента", flag = PartFlag({ "skinPopups" }, true) },
    { label = "Omen", flag = PartFlag({ "skinOmen" }, true) },

    { section = "Интерфейс на экране" },
    { label = "Рамки игрока и цели", flag = PartFlag({ "playerUI", "enabled" }, false) },
    { label = "Панели команд", flag = PartFlag({ "actionBars", "enabled" }, false) },
    { label = "Полоса заклинания", flag = PartFlag({ "castBar", "enabled" }, false) },
    { label = "Бафы", flag = PartFlag({ "auras", "enabled" }, true) },
    { label = "Миникарта", flag = PartFlag({ "minimap", "enabled" }, true) },
    { label = "Кнопки аддонов", flag = PartFlag({ "minimap", "collect" }, false) },
    { label = "Чат", flag = PartFlag({ "chat", "enabled" }, false) },
    { label = "Подсказки", flag = PartFlag({ "tooltip", "enabled" }, false) },
    { label = "Показатели", flag = PartFlag({ "dataTexts", "enabled" }, false) },
    { label = "Полоса восстановления", flag = PartFlag({ "cooldownBar", "enabled" }, true) },
    { label = "Рейд-фреймы", flag = PartFlag({ "raidFrames", "enabled" }, true) },
    { label = "Утилиты рейда", flag = PartFlag({ "raidUtility", "enabled" }, true) },
    { label = "Окно сообщений (шёпот)", flag = PartFlag({ "messenger", "enabled" }, true) },
    { label = "Масштаб интерфейса", flag = PartFlag({ "uiScale", "enabled" }, false) },
    { label = "Измеритель угрозы", flag = PartFlag({ "threat", "enabled" }, true) },
    { label = "Неймплейты", flag = PartFlag({ "nameplates", "enabled" }, true) },
    { label = "Сумки и банк", flag = PartFlag({ "bags", "enabled" }, true) },
    { label = "Экран AFK", flag = PartFlag({ "afk", "enabled" }, true) },

    { section = "Дополнения к подсказкам" },
    { label = "Сравнение предметов", flag = PartFlag({ "showComparison" }, true) },
    { label = "История цен с аукциона", flag = PartFlag({ "enabled" }, true, AuctionDB) },
    { label = "Баннеры заданий", flag = PartFlag({ "quests", "banners" }, true) },

    { section = "Кнопка аддона" },
    { label = "Кнопка на миникарте", flag = PartFlag({ "minimapButton" }, true), keep = true },
}

local function BuildParts(page)
    local checks = {}

    if not PARTS.narciPlugins then
        PARTS.narciPlugins = true
        local list = NS.Plugins and NS.Plugins:List() or {}
        if #list > 0 then
            PARTS[#PARTS + 1] = { section = "Плагины" }
            for _, plugin in ipairs(list) do
                PARTS[#PARTS + 1] = { label = plugin.title, flag = PartFlag({ "pluginsEnabled", plugin.name }, true) }
            end
        end
    end
    local applyButton

    local function Changed()
        if applyButton then applyButton:Show() end
    end

    local function SetAll(stock)
        for _, entry in ipairs(PARTS) do
            if entry.flag and not (stock and entry.keep) then
                local value = not stock and entry.flag.default
                entry.flag.set(value)
                if checks[entry] then checks[entry]:SetChecked(value) end
            end
        end
        Changed()
    end

    Section(page, L["Части аддона"])

    Note(page, L["Здесь можно выключить любую часть аддона, и на её месте останется окно или элемент клиента. Изменения применяются после перезагрузки интерфейса. Окно аддона по-прежнему открывается командой /narci."])

    Buttons(page, {
        { label = L["Стандартный интерфейс везде"], width = 230, action = function()
            NS.Widgets.ShowConfirm(
                L["Выключить все части аддона и вернуть окна клиента?"],
                L["Выключить"],
                function() SetAll(true) end)
        end },
        { label = L["Как по умолчанию"], width = 170, action = function() SetAll(false) end },
    })

    applyButton = NS.Widgets.CreateThemedButton(page, L["Применить и перезагрузить"], 220, 24, function()
        ReloadUI()
    end)
    applyButton:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    applyButton:Hide()
    page.offset = page.offset - 34

    for _, entry in ipairs(PARTS) do
        if entry.section then
            Section(page, L[entry.section])
        else
            local flag = entry.flag
            local ok, value = pcall(flag.get)
            checks[entry] = Check(page, L[entry.label], ok and value, function(val)
                flag.set(val and true or false)
                Changed()
            end)
        end
    end
end

local function BuildThreat(page)
    local threat = NS.ThreatMeter
    local db = threat and threat.Settings() or {}
    db.show = db.show or {}
    db.warn = db.warn or {}
    db.classes = db.classes or {}

    local function Refresh()
        if not threat then return end
        if threat.frame then
            threat:Layout()
            threat:UpdateVisible()
        end
        threat:Update()
    end

    local function Set(key, value)
        db[key] = value
        Refresh()
    end

    Section(page, L["Угроза"])

    Note(page, L["Встроенный измеритель угрозы на замену аддону Omen: полоски угрозы всей группы на вашу цель, порог срыва агро, угроза в секунду и предупреждение, когда вы подбираетесь к танку. Данные берутся из клиента, другим игрокам ничего ставить не нужно."])

    if threat and threat:OmenLoaded() then
        Note(page, L["Сейчас включён аддон Omen, поэтому встроенный измеритель ждёт. Отключите Omen, и после перезагрузки заработает этот."])
        Buttons(page, {
            { label = L["Отключить Omen"], width = 170, action = function()
                NS.Widgets.ShowConfirm(
                    L["Отключить Omen и перезагрузить интерфейс?"],
                    L["Отключить"],
                    function()
                        DisableAddOn("Omen")
                        ReloadUI()
                    end)
            end },
        })
    end

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        db.enabled = val
        if threat then
            if val then threat:Apply() elseif threat.frame then threat.frame:Hide() end
        end
    end)

    Buttons(page, {
        { label = L["Показать / скрыть"], width = 160, action = function() if threat then threat:Toggle() end end },
        { label = L["Тестовый режим"], width = 150, action = function()
            if threat then threat:SetTestMode(not threat:IsTestMode()) end
        end },
        { label = L["Вернуть на место"], width = 150, action = function() if threat then threat:ResetPosition() end end },
    })

    Note(page, L["Окно двигается за заголовок, размер меняется за правый нижний угол. Правый клик по заголовку открывает быстрое меню."])

    Label(page, L["Стиль окна"])

    local stylePicker
    stylePicker = Picker(page, {
        { key = "modern", label = L["современный"] },
        { key = "classic", label = L["классика WoW"] },
        { key = "pixel", label = L["пиксель"] },
        { key = "glass", label = L["стекло"] },
        { key = "neon", label = L["неон"] },
        { key = "minimal", label = L["минимал"] },
        { key = "thick", label = L["толстая рамка"] },
    }, db.style or "modern", function(value)
        stylePicker:Refresh(value)
        Set("style", value)
    end, nil, PV("Sample", "ThreatMeter", "threat", "style"))

    Check(page, L["Закрепить окно"], db.locked, function(val) Set("locked", val) end)
    Check(page, L["Клики проходят сквозь окно"], db.clickThrough, function(val) Set("clickThrough", val) end)

    Slider(page, L["Масштаб"], 50, 150, 5, db.scale or 100, function(val) Set("scale", val) end, "%")
    Slider(page, L["Плотность фона"], 10, 100, 5, db.alpha or 85, function(val) Set("alpha", val) end, "%")
    Slider(page, L["Высота полос"], 8, 30, 1, db.barHeight or 14, function(val) Set("barHeight", val) end)
    Slider(page, L["Промежуток между полосами"], 0, 6, 1, db.barSpacing or 1, function(val) Set("barSpacing", val) end)
    Slider(page, L["Размер шрифта"], 7, 16, 1, db.fontSize or 10, function(val) Set("fontSize", val) end)

    Check(page, L["Подгонять высоту под число полос"], db.autoCollapse, function(val) Set("autoCollapse", val) end)
    Slider(page, L["Полос не больше"], 1, 40, 1, db.numBars or 10, function(val) Set("numBars", val) end)
    Check(page, L["Прятать окно, когда полос нет"], db.collapseHide, function(val) Set("collapseHide", val) end)

    Section(page, L["Полосы"])

    Check(page, L["Заголовок с именем цели"], db.showTitle ~= false, function(val) Set("showTitle", val) end)
    Check(page, L["Строка с названиями столбцов"], db.showHeadings ~= false, function(val) Set("showHeadings", val) end)
    Check(page, L["Значение угрозы"], db.showValue ~= false, function(val) Set("showValue", val) end)
    Check(page, L["Процент от угрозы танка"], db.showPercent ~= false, function(val) Set("showPercent", val) end)
    Check(page, L["Сокращать большие числа"], db.shortNumbers ~= false, function(val) Set("shortNumbers", val) end)
    Check(page, L["Угроза в секунду"], db.showTPS ~= false, function(val) Set("showTPS", val) end)
    Slider(page, L["Окно расчёта угрозы в секунду, сек"], 3, 30, 1, db.tpsWindow or 10, function(val) Set("tpsWindow", val) end)
    Check(page, L["Цвета классов"], db.classColors ~= false, function(val) Set("classColors", val) end)
    Check(page, L["Своя полоса цветом темы"], db.myColor, function(val) Set("myColor", val) end)
    Check(page, L["Полоса танка красным"], db.tankColor, function(val) Set("tankColor", val) end)
    Check(page, L["Плавное движение полос"], db.animate ~= false, function(val) Set("animate", val) end)
    Check(page, L["Всегда показывать свою полосу"], db.alwaysShowSelf ~= false, function(val) Set("alwaysShowSelf", val) end)
    Check(page, L["Полоса порога срыва агро"], db.showAggroBar ~= false, function(val) Set("showAggroBar", val) end)
    Note(page, L["Порог срыва - угроза, при которой моб переключится на вас: 110% от угрозы танка вблизи и 130% издалека."])
    Check(page, L["Сначала фокус, потом цель"], db.useFocus, function(val) Set("useFocus", val) end)
    Check(page, L["Не показывать угрозу на питомцах игроков"], db.ignorePets ~= false, function(val) Set("ignorePets", val) end)

    Section(page, L["Чьи полосы показывать"])

    for _, class in ipairs(threat and threat.CLASSES or {}) do
        local label
        if class == "PET" then
            label = L["Питомцы"]
        elseif class == "NOTINPARTY" then
            label = L["Не из группы"]
        else
            label = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
        end
        Check(page, label, db.classes[class] ~= false, function(val)
            db.classes[class] = val
            Refresh()
        end)
    end

    Section(page, L["Когда показывать окно"])

    local function SetShow(key, value)
        db.show[key] = value
        Refresh()
    end

    Check(page, L["Есть питомец"], db.show.pet ~= false, function(val) SetShow("pet", val) end)
    Check(page, L["В группе"], db.show.party ~= false, function(val) SetShow("party", val) end)
    Check(page, L["В рейде"], db.show.raid ~= false, function(val) SetShow("raid", val) end)
    Check(page, L["Одному"], db.show.alone, function(val) SetShow("alone", val) end)
    Check(page, L["Прятать в зоне отдыха"], db.show.hideResting ~= false, function(val) SetShow("hideResting", val) end)
    Check(page, L["Прятать на полях боя и аренах"], db.show.hidePvP ~= false, function(val) SetShow("hidePvP", val) end)
    Check(page, L["Прятать вне боя"], db.show.hideOOC, function(val) SetShow("hideOOC", val) end)

    Section(page, L["Предупреждение"])

    local function SetWarn(key, value)
        db.warn[key] = value
    end

    Slider(page, L["Порог предупреждения"], 50, 130, 5, db.warn.threshold or 90, function(val) SetWarn("threshold", val) end, "%")
    Check(page, L["Не предупреждать, когда я танкую"], db.warn.notTanking ~= false, function(val) SetWarn("notTanking", val) end)
    Check(page, L["Звук"], db.warn.sound ~= false, function(val) SetWarn("sound", val) end)

    Label(page, L["Какой звук"])

    local sounds = {}
    for _, sound in ipairs(threat and threat.SOUNDS or {}) do
        sounds[#sounds + 1] = { key = sound.key, label = L[sound.label] }
    end

    local soundPicker
    soundPicker = Picker(page, sounds, db.warn.soundKey or "felnova", function(value)
        soundPicker:Refresh(value)
        SetWarn("soundKey", value)
        for _, sound in ipairs(threat and threat.SOUNDS or {}) do
            if sound.key == value then PlaySoundFile(sound.path) end
        end
    end)

    Check(page, L["Красная вспышка по краям экрана"], db.warn.flash ~= false, function(val) SetWarn("flash", val) end)
    Check(page, L["Встряхнуть экран"], db.warn.shake, function(val) SetWarn("shake", val) end)
    Check(page, L["Надпись посреди экрана"], db.warn.message, function(val) SetWarn("message", val) end)

    Buttons(page, {
        { label = L["Проверить предупреждение"], width = 220, action = function()
            if threat then threat:Warn(L["Проверка предупреждения об угрозе"]) end
        end },
    })
end

local TIDY_ADDONS = { "TidyPlates", "TidyPlates_Graphite", "TidyPlates_Grey", "TidyPlates_Neon", "TidyPlates_Quatre", "TidyPlates_ThreatPlates" }

local function BuildNameplates(page)
    local plates = NS.Nameplates
    local db = plates and plates.Settings() or {}

    local function Set(key, value)
        db[key] = value
        if plates then plates:Refresh() end
    end

    local function Choice(label, key, options)
        Label(page, label)
        local picker
        picker = Picker(page, options, db[key], function(value)
            picker:Refresh(value)
            Set(key, value)
        end, nil, PV("Sample", "Nameplates", "nameplates", key))
        return picker
    end

    Section(page, L["Неймплейты"])

    Note(page, L["Полоски здоровья над головами в оформлении аддона на замену TidyPlates: 16 стилей, полоса заклинания, ваши дебаффы с таймером, окраска по угрозе и подсветка цели. Работают на новых плашках клиента Sirus и берут данные прямо у клиента."])

    local blocked = plates and plates:Blocked()

    if blocked == "old" then
        Note(page, L["Сейчас включены старые плашки клиента. Неймплейты аддона работают на новых, их можно включить кнопкой ниже или в настройках клиента: Интерфейс, Имена, новые индикаторы здоровья."])
        Buttons(page, {
            { label = L["Включить новые плашки"], width = 220, action = function()
                SetCVar("nameplateEnableNew", "1")
                ReloadUI()
            end },
        })
    elseif blocked == "tidy" then
        Note(page, L["Сейчас включён TidyPlates, поэтому неймплейты аддона ждут. Отключите его вместе с темами, и после перезагрузки заработают эти."])
        Buttons(page, {
            { label = L["Отключить TidyPlates"], width = 220, action = function()
                NS.Widgets.ShowConfirm(L["Отключить TidyPlates с темами и перезагрузить интерфейс?"], L["Отключить"], function()
                    for _, name in ipairs(TIDY_ADDONS) do pcall(DisableAddOn, name) end
                    ReloadUI()
                end)
            end },
        })
    end

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        db.enabled = val
        NS.Print(L["Нужен /reload"])
    end)

    Label(page, L["Стиль"])

    if plates then
        local preview = plates:CreatePreview(page)
        preview:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
        page.offset = page.offset - 94
    end

    local styles = {}
    for _, style in ipairs(plates and plates.STYLES or {}) do
        styles[#styles + 1] = { key = style.key, label = L[style.name] }
    end

    local stylePicker
    stylePicker = Picker(page, styles, db.style or "obsidian", function(value)
        stylePicker:Refresh(value)
        Set("style", value)
    end, nil, PV("Sample", "Nameplates", "nameplates", "style"))

    Slider(page, L["Масштаб"], 50, 200, 5, db.scale or 100, function(val) Set("scale", val) end, "%")
    Slider(page, L["Ширина"], 50, 200, 5, db.widthScale or 100, function(val) Set("widthScale", val) end, "%")
    Slider(page, L["Высота"], 50, 300, 10, db.heightScale or 100, function(val) Set("heightScale", val) end, "%")

    Choice(L["Текст здоровья"], "hpText", {
        { key = "style",   label = L["как в стиле"] },
        { key = "none",    label = L["скрыть"] },
        { key = "percent", label = L["проценты"] },
        { key = "value",   label = L["число"] },
        { key = "both",    label = L["число и %"] },
        { key = "deficit", label = L["сколько не хватает"] },
    })

    Check(page, L["Имя"], db.showName ~= false, function(val) Set("showName", val) end)
    Check(page, L["Уровень"], db.showLevel ~= false, function(val) Set("showLevel", val) end)
    Check(page, L["Метки рейда"], db.raidIcon ~= false, function(val) Set("raidIcon", val) end)
    Check(page, L["Цвет класса у вражеских игроков"], db.classColorEnemy ~= false, function(val) Set("classColorEnemy", val) end)
    Check(page, L["Цвет класса у союзников"], db.classColorFriend ~= false, function(val) Set("classColorFriend", val) end)

    Section(page, L["Цель"])

    Choice(L["Подсветка цели"], "target", {
        { key = "glow",      label = L["свечение"] },
        { key = "outline",   label = L["рамка"] },
        { key = "underline", label = L["линия снизу"] },
        { key = "none",      label = L["нет"] },
    })

    Slider(page, L["Увеличение цели"], 100, 150, 5, db.targetScale or 110, function(val) Set("targetScale", val) end, "%")
    Slider(page, L["Прозрачность остальных при цели"], 20, 100, 5, db.otherAlpha or 70, function(val) Set("otherAlpha", val) end, "%")

    Section(page, L["Заклинания и эффекты"])

    Check(page, L["Полоса заклинания"], db.castBar ~= false, function(val) Set("castBar", val) end)
    Check(page, L["Иконка заклинания"], db.castIcon ~= false, function(val) Set("castIcon", val) end)
    Note(page, L["Серая полоса с белой рамкой - заклинание нельзя прервать."])
    Check(page, L["Мои дебаффы на врагах"], db.debuffs ~= false, function(val) Set("debuffs", val) end)
    Slider(page, L["Размер дебаффов"], 12, 32, 1, db.debuffSize or 18, function(val) Set("debuffSize", val) end)
    Slider(page, L["Дебаффов не больше"], 1, 10, 1, db.debuffCount or 5, function(val) Set("debuffCount", val) end)

    Section(page, L["Цвет полосы"])

    Choice(L["Окраска по угрозе"], "threat", {
        { key = "off",    label = L["выкл"] },
        { key = "tank",   label = L["для танка"] },
        { key = "damage", label = L["для бойца"] },
    })

    Note(page, L["Для танка: зелёный - моб на вас, жёлтый и оранжевый - его вот-вот сорвут, красный - моб бьёт другого. Для бойца наоборот: оранжевый - вы близки к срыву, красный - моб уже на вас."])

    Check(page, L["Подсвечивать добивание"], db.execute, function(val) Set("execute", val) end)
    Slider(page, L["Добивание с"], 5, 50, 5, db.executeAt or 20, function(val) Set("executeAt", val) end, "%")

    Section(page, L["Какие плашки показывать"])

    local function CVarCheck(label, cvar)
        Check(page, label, GetCVar(cvar) == "1", function(val)
            if InCombatLockdown() then
                NS.Print(L["В бою это переключить нельзя"])
                return
            end
            SetCVar(cvar, val and "1" or "0")
        end)
    end

    CVarCheck(L["Враги"], "nameplateShowEnemies")
    CVarCheck(L["Питомцы врагов"], "nameplateShowEnemyPets")
    CVarCheck(L["Тотемы врагов"], "nameplateShowEnemyTotems")
    CVarCheck(L["Союзники"], "nameplateShowFriends")
    CVarCheck(L["Питомцы союзников"], "nameplateShowFriendlyPets")
    CVarCheck(L["Тотемы союзников"], "nameplateShowFriendlyTotems")
end

local function BuildBags(page)
    local bags = NS.Bags
    local db = bags and bags.Settings() or {}

    local function Set(key, value)
        db[key] = value
        if bags then bags:Refresh() end
    end

    Section(page, L["Сумки"])

    Note(page, L["Свои сумки и банк на замену стандартным, AdiBags и Bagnon: все сумки в одном окне общей сеткой или по разделам, банк с вкладкой реагентов Sirus, сортировка, поиск, уровень предметов, подсветка новых, продажа хлама и сумки других персонажей."])

    local blocked, other = nil, nil
    if bags then blocked, other = bags:Blocked() end

    if blocked == "addon" then
        Note(page, string.format(L["Сейчас включён %s, поэтому сумки аддона ждут. Отключите его, и после перезагрузки заработают эти."], other))
        Buttons(page, {
            { label = string.format(L["Отключить %s"], other), width = 220, action = function()
                NS.Widgets.ShowConfirm(string.format(L["Отключить %s и перезагрузить интерфейс?"], other), L["Отключить"], function()
                    for index = 1, GetNumAddOns() do
                        local name = GetAddOnInfo(index)
                        if name and name:find("^" .. other) then pcall(DisableAddOn, name) end
                    end
                    ReloadUI()
                end)
            end },
        })
    end

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        db.enabled = val
        NS.Print(L["Нужен /reload"])
    end)

    Label(page, L["Стиль"])
    local stylePicker
    local styleOptions = {}
    for _, style in ipairs(bags and bags.STYLES or {}) do
        styleOptions[#styleOptions + 1] = { key = style.key, label = L[style.name] }
    end
    stylePicker = Picker(page, styleOptions, db.style or "obsidian", function(value)
        stylePicker:Refresh(value)
        Set("style", value)
    end, nil, PV("Sample", "Bags", "bags", "style"))

    Label(page, L["Раскладка"])
    local layoutPicker
    layoutPicker = Picker(page, {
        { key = "grid",       label = L["общая сетка"] },
        { key = "categories", label = L["по разделам"] },
    }, db.layout or "grid", function(value)
        layoutPicker:Refresh(value)
        Set("layout", value)
    end)

    Slider(page, L["Колонок в сумках"], 6, 24, 1, db.columns or 12, function(val) Set("columns", val) end)
    Slider(page, L["Колонок в банке"], 8, 30, 1, db.bankColumns or 14, function(val) Set("bankColumns", val) end)
    Slider(page, L["Размер ячейки"], 26, 48, 1, db.size or 34, function(val) Set("size", val) end)
    Slider(page, L["Отступ между ячейками"], 0, 8, 1, db.spacing or 3, function(val) Set("spacing", val) end)
    Slider(page, L["Масштаб"], 50, 150, 5, db.scale or 100, function(val) Set("scale", val) end, "%")

    Section(page, L["Ячейки"])

    Check(page, L["Уровень предметов"], db.itemLevel ~= false, function(val) Set("itemLevel", val) end)
    Check(page, L["Рамка по качеству"], db.qualityBorder ~= false, function(val) Set("qualityBorder", val) end)
    Check(page, L["Монетка на хламе"], db.junkIcon ~= false, function(val) Set("junkIcon", val) end)
    Check(page, L["Подсветка новых предметов"], db.newGlow ~= false, function(val) Set("newGlow", val) end)

    Section(page, L["Разделы"])

    Check(page, L["Раздел «Новое»"], db.newSection ~= false, function(val) Set("newSection", val) end)
    Check(page, L["Свой раздел для каждого комплекта экипировки"], db.setsSection ~= false, function(val) Set("setsSection", val) end)
    Check(page, L["Свободные ячейки одной клеткой"], db.compactFree ~= false, function(val) Set("compactFree", val) end)

    Section(page, L["Хлам и сортировка"])

    Check(page, L["Продавать хлам у торговца сам"], db.autoSellJunk ~= false, function(val) Set("autoSellJunk", val) end)
    Note(page, L["Сортировка собирает неполные стопки и раскладывает предметы по типу, качеству и уровню. Сумки профессий она не трогает, банк реагентов сортирует сервер."])

    Section(page, L["Другие персонажи"])

    Check(page, L["Сколько предметов у персонажей, в подсказке"], db.tooltipCounts ~= false, function(val) Set("tooltipCounts", val) end)
    Note(page, L["Аддон запоминает сумки, банк и надетое каждого персонажа, когда вы им играете. Посмотреть их можно кнопкой Персонажи в окне сумок."])
    Buttons(page, {
        { label = L["Забыть других персонажей"], width = 220, action = function()
            NS.Widgets.ShowConfirm(L["Забыть сумки и банк всех персонажей, кроме текущего?"], L["Забыть"], function()
                if bags then bags:ForgetOthers() end
            end)
        end },
    })
end

local function BuildBagCurrency(page)
    local bags = NS.Bags
    local db = bags and bags.Settings() or {}
    if type(db.currencies) ~= "table" then db.currencies = {} end

    local function Apply()
        if bags then bags:Refresh() end
    end

    Section(page, L["Валюта в сумке"])

    Note(page, L["Строка валют над нижней строкой окна сумок: значок и количество, при наведении - подсказка с недельным пределом. Отметьте валюты ниже. Если не отмечена ни одна, показываются те, что отмечены в окне Валюта клиента как «Показывать на панели рюкзака»."])

    Check(page, L["Показывать валюту в окне сумок"], db.showCurrency ~= false, function(val)
        db.showCurrency = val and true or false
        Apply()
    end)

    Section(page, L["Валюты"])

    local list = bags and bags:ListCurrencies(nil) or {}
    if #list == 0 then
        Note(page, L["Персонаж ещё не получил ни одной валюты."])
    end
    for _, entry in ipairs(list) do
        local name = entry.name
        local label = (entry.icon and ("|T" .. entry.icon .. ":14:14:0:0|t ") or "") .. name .. "  |cff9a9ca3" .. tostring(entry.count) .. "|r"
        Check(page, label, db.currencies[name] and true or false, function(val)
            db.currencies[name] = val and true or nil
            Apply()
        end)
    end
end

local function LookOptions(list, defaultLabel)
    local options = {}
    for _, entry in ipairs(list) do
        options[#options + 1] = { key = entry.key, label = entry.key == "default" and defaultLabel or L[entry.name] }
    end
    return options
end

local function FontChoices(defaultLabel)
    local options = { { key = "default", label = defaultLabel } }
    for _, option in ipairs(NS.FontOptions()) do
        if NS.FontWorks(option.path) then
            options[#options + 1] = { key = option.key, label = option.label }
        end
    end
    return options
end

local function OpenColor(current, onChange, onCancel)
    if type(OpenColorPicker) ~= "function" or not ColorPickerFrame then return end
    local previous = current and { current[1], current[2], current[3] }
    OpenColorPicker({
        r = current and current[1] or 1,
        g = current and current[2] or 1,
        b = current and current[3] or 1,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            onChange(r, g, b)
        end,
        cancelFunc = function()
            onCancel(previous)
        end,
    })
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    ColorPickerFrame:SetFrameLevel(260)
end

local function ColorSetting(page, text, getColor, setColor)
    local S = Style()

    local row = CreateFrame("Frame", nil, page)
    row:SetSize(PANEL_W - SIDE_W - 80, 22)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)

    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(34, 18)
    swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetTexture(WHITE)
    S.CreateEdges(swatch, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(11), "")
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    label:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
    label:SetText(text)

    local function Refresh()
        local r, g, b = getColor()
        fill:SetGradientAlpha("HORIZONTAL", r or 1, g or 1, b or 1, 1, r or 1, g or 1, b or 1, 1)
    end

    swatch:SetScript("OnClick", function()
        local r, g, b = getColor()
        OpenColor({ r or 1, g or 1, b or 1 }, function(nr, ng, nb)
            setColor(nr, ng, nb)
            Refresh()
        end, function(previous)
            if previous then setColor(previous[1], previous[2], previous[3]) end
            Refresh()
        end)
    end)

    Refresh()
    page.offset = page.offset - 28
    return row
end

local function ColorRow(page, text, element, slot)
    local S = Style()
    local Look = NS.Look

    local row = CreateFrame("Frame", nil, page)
    row:SetSize(PANEL_W - SIDE_W - 80, 22)
    row:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)

    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(34, 18)
    swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetTexture(WHITE)
    S.CreateEdges(swatch, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(11), "")
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    label:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
    label:SetText(text)

    local state = row:CreateFontString(nil, "OVERLAY")
    state:SetFont(NS.FONT, NS.FS(10), "")
    state:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    state:SetPoint("LEFT", label, "RIGHT", 8, 0)

    local reset = NS.Widgets.CreateThemedButton(row, L["Сбросить"], 80, 18, function()
        Look:SetColor(element, slot, nil)
        row:Refresh()
        Look:Refresh(element)
    end)
    reset:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    function row:Refresh()
        local r, g, b = Look:OwnColor(element, slot)
        if r then
            fill:SetVertexColor(r, g, b, 1)
            fill:SetGradientAlpha("HORIZONTAL", r, g, b, 1, r, g, b, 1)
            state:SetText("")
            reset:Show()
        else
            fill:SetGradientAlpha("HORIZONTAL", 0.2, 0.2, 0.25, 1, 0.5, 0.5, 0.55, 1)
            state:SetText(L["как в стиле"])
            reset:Hide()
        end
    end

    swatch:SetScript("OnClick", function()
        local r, g, b = Look:OwnColor(element, slot)
        OpenColor(r and { r, g, b }, function(nr, ng, nb)
            Look:SetColor(element, slot, nr, ng, nb)
            row:Refresh()
            Look:Refresh(element)
        end, function(previous)
            if previous then
                Look:SetColor(element, slot, previous[1], previous[2], previous[3])
            else
                Look:SetColor(element, slot, nil)
            end
            row:Refresh()
            Look:Refresh(element)
        end)
    end)

    row:Refresh()
    page.offset = page.offset - 28
    return row
end

local function LookApplyButtons(page, resetText, onReset)
    Buttons(page, {
        { label = L["Перезагрузить интерфейс"], width = 180, action = function() ReloadUI() end },
        { label = resetText, width = 180, action = function()
            NS.Widgets.ShowConfirm(L["Сбросить настройки вида и перезагрузить интерфейс?"], L["Сбросить"], function()
                onReset()
                ReloadUI()
            end)
        end },
    })
end

local function BuildElementLookGeneral(page)
    local Look = NS.Look
    local db = Look and Look:Settings() or {}

    Section(page, L["Вид элементов"])

    Note(page, L["Общие текстура полос, шрифт и обводка для всех элементов интерфейса: рамок, неймплейтов, панелей, чата, подсказок, сумок. На страницах ниже каждый элемент можно настроить отдельно и задать ему свои цвета. Изменения видны сразу; если какой-то элемент не обновился, перезагрузите интерфейс."])

    Section(page, L["Готовые образы"])

    Note(page, L["Образ переключает стили сразу всех элементов: рамок, панелей, полосы заклинания, подсказок, чата, миникарты, рейд-фреймов, бафов, показателей, неймплейтов и сумок. Потом любой элемент можно поменять на его странице."])

    local texturePicker, outlinePicker
    local presetButtons = {}

    local function PresetLabel(preset)
        local label = L[preset.name]
        if db.preset == preset.key then label = "> " .. label .. " <" end
        return label
    end

    local row = {}
    for index, preset in ipairs(Look and Look.PRESETS or {}) do
        local presetKey, presetName = preset.key, preset.name
        row[#row + 1] = { label = PresetLabel(preset), width = 150, action = function()
            NS.Widgets.ShowConfirm(string.format(L["Применить образ %s? Стили всех элементов поменяются."], L[presetName]), L["Применить"], function()
                Look:ApplyPreset(presetKey)
                for button, entry in pairs(presetButtons) do button:SetText(PresetLabel(entry)) end
                if texturePicker then texturePicker:Refresh(db.texture or "default") end
                if outlinePicker then outlinePicker:Refresh(db.outline or "default") end
                Look:Refresh()
            end)
        end }
        row[#row].preset = preset
        if #row == 3 or index == #Look.PRESETS then
            local made = Buttons(page, row)
            for i, button in ipairs(made) do presetButtons[button] = row[i].preset end
            row = {}
        end
    end

    Section(page, L["Общие настройки"])

    Label(page, L["Текстура полос"])
    texturePicker = Picker(page, LookOptions(Look and Look.TEXTURES or {}, L["как в стиле"]), db.texture or "default", function(value)
        texturePicker:Refresh(value)
        db.texture = value
        Look:Refresh()
    end, nil, PV("LookBar", "texture"))

    Label(page, L["Шрифт интерфейса"])
    local fontPicker
    fontPicker = Picker(page, FontChoices(L["шрифт аддона"]), db.font or "default", function(value)
        fontPicker:Refresh(value)
        db.font = value
        Look:Refresh()
    end, nil, PV("LookBar", "font"))

    Label(page, L["Обводка текста"])
    outlinePicker = Picker(page, LookOptions(Look and Look.OUTLINES or {}, L["как в стиле"]), db.outline or "default", function(value)
        outlinePicker:Refresh(value)
        db.outline = value
        Look:Refresh()
    end, nil, PV("LookBar", "outline"))

    Slider(page, L["Размер шрифта"], 70, 150, 5, db.fontScale or 100, function(val)
        db.fontScale = val
        Look:Refresh()
    end, "%")

    LookApplyButtons(page, L["Сбросить всё"], function() if Look then Look:ResetAll() end end)
end

local function BuildAFK(page)
    if type(NS.db.afk) ~= "table" then NS.db.afk = {} end
    local db = NS.db.afk

    local function Flag(key)
        return db[key] ~= false
    end

    Section(page, L["Экран AFK"])

    Note(page, L["Когда клиент отмечает вас «Отошёл» (через 5 минут бездействия или по команде /afk), интерфейс прячется, камера медленно кружит вокруг персонажа, а внизу появляется панель с логотипом NarciUI, именем, гильдией, временем отсутствия и часами. Любая клавиша или щелчок мыши возвращают интерфейс. В бою, при приглашении в подземелье или на поле боя и при проверке готовности экран закрывается сам."])

    Check(page, L["Включить"], Flag("enabled"), function(val)
        db.enabled = val and true or false
        if not val and NS.AFKScreen then NS.AFKScreen:Leave(false) end
    end)

    Check(page, L["Вращать камеру"], Flag("spin"), function(val)
        db.spin = val and true or false
    end)

    Slider(page, L["Скорость вращения"], 1, 20, 1, db.spinSpeed or 4, function(val)
        db.spinSpeed = val
    end)

    Check(page, L["Показывать модель персонажа"], Flag("model"), function(val)
        db.model = val and true or false
    end)

    Check(page, L["Показывать сообщения шёпота, гильдии, группы и рейда"], Flag("chat"), function(val)
        db.chat = val and true or false
    end)

    Section(page, L["Вид"])
    Label(page, L["Раскладка"])
    local layoutPicker
    layoutPicker = Picker(page, {
        { key = "bottom",  label = L["панель снизу"] },
        { key = "top",     label = L["панель сверху"] },
        { key = "minimal", label = L["без панели, логотип в центре"] },
    }, db.layout or "bottom", function(value)
        db.layout = value
        layoutPicker:Refresh(value)
    end, nil, PV("With", "afk", "layout", PV("AFK")))
    Label(page, L["Цвет линий и рамок"])
    local tintPicker
    tintPicker = Picker(page, {
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
        { key = "brand",  label = L["как подпись"] },
        { key = "gold",   label = L["золото"] },
        { key = "silver", label = L["серебро"] },
    }, db.tint or "accent", function(value)
        db.tint = value
        tintPicker:Refresh(value)
    end, nil, PV("With", "afk", "tint", PV("AFK")))
    Slider(page, L["Плотность панели"], 20, 100, 5, db.panelAlpha or 96, function(val)
        db.panelAlpha = val
    end, "%")

    local AFKMod = NS.AFKScreen
    if AFKMod and AFKMod.PANEL_STYLE_ORDER then
        Label(page, L["Стиль панели"])
        local afkStyles = {}
        for _, key in ipairs(AFKMod.PANEL_STYLE_ORDER) do
            afkStyles[#afkStyles + 1] = { key = key, label = L[AFKMod.PANEL_STYLE_LABELS[key]] }
        end
        local afkStylePicker
        afkStylePicker = Picker(page, afkStyles, db.panelStyle or "narci", function(value)
            db.panelStyle = value
            afkStylePicker:Refresh(value)
        end, nil, PV("AFK"))
        Note(page, L["Ночное небо, Рассвет и Пергамент кладут на панель картинку, Аркана - вращающийся рунный круг за эмблемой. Посмотреть - кнопкой Показать сейчас."])
    end

    Section(page, L["Что показывать"])
    Check(page, L["Логотип"], Flag("showLogo"), function(val) db.showLogo = val and true or false end)
    Check(page, L["Имя, уровень и гильдию"], Flag("showInfo"), function(val) db.showInfo = val and true or false end)
    Check(page, L["Часы и дату"], Flag("showClock"), function(val) db.showClock = val and true or false end)
    Check(page, L["Время отсутствия"], Flag("showTimer"), function(val) db.showTimer = val and true or false end)
    Check(page, L["Подсказку «нажмите любую клавишу»"], Flag("showHint"), function(val) db.showHint = val and true or false end)
    Check(page, L["Сменяющиеся советы по интерфейсу"], Flag("tips"), function(val) db.tips = val and true or false end)
    TextInput(page, L["Свой текст вместо «Вы отошли»"], db.awayText, function(text)
        db.awayText = text
    end, 60)
    Note(page, L["Девиз, эмблему и название задаёт страница «Подпись и эмблема»."])

    Section(page, L["Модель"])
    Label(page, L["Эмоция модели"])
    local emotePicker
    emotePicker = Picker(page, {
        { key = "stand",   label = L["обычная"] },
        { key = "wave",    label = L["приветствие"] },
        { key = "dance",   label = L["танец"] },
        { key = "sit",     label = L["сидя"] },
        { key = "kneel",   label = L["на колене"] },
        { key = "cheer",   label = L["ликование"] },
        { key = "salute",  label = L["салют"] },
        { key = "laugh",   label = L["смех"] },
        { key = "flex",    label = L["сила"] },
        { key = "random",  label = L["случайная"] },
    }, db.emote or "stand", function(value)
        db.emote = value
        emotePicker:Refresh(value)
    end, nil, PV("Pose"))

    Buttons(page, {
        { label = L["Показать сейчас"], width = 200, action = function()
            if not NS.AFKScreen then return end
            if _G.NarcissusSirus_SettingsFrame then _G.NarcissusSirus_SettingsFrame:Hide() end
            NS.AFKScreen:Test()
        end },
    })
end

local function BuildNarciColors(page)
    local Look = NS.Look
    if not Look then return end
    local db = Look:Settings()

    Section(page, L["Цвета NarciUI"])

    Note(page, L["Общие цвета всего интерфейса, как цвета в ElvUI: рамка, фон полос и плашек, фон панелей (чат, показатели, сумки, подсказки, угроза, восстановление) и цвет значений. Их берут все элементы, у которых на своей странице не задан свой цвет. Пустой цвет - как в стиле элемента."])

    for _, slot in ipairs({ "border", "bg", "fade", "value" }) do
        ColorRow(page, L[Look.GLOBAL_SLOTS[slot]], Look.GLOBAL, slot)
    end

    Check(page, L["Цвет значений - цвет класса"], db.valueClass, function(val)
        db.valueClass = val and true or nil
        Look:Refresh()
    end)

    Note(page, L["Цвет значений используют показатели, если у них выбран цвет «цвета NarciUI»."])

    LookApplyButtons(page, L["Сбросить цвета"], function() Look:Reset(Look.GLOBAL) end)
end

local function BuildElementLook(key)
    return function(page)
        local Look = NS.Look
        if not Look then return end
        local info = Look.ELEMENT_BY_KEY[key]
        local element = Look:Element(key)

        Section(page, L[info.name])

        Note(page, L["Пустые значения берутся с общей страницы Вид элементов, а цвета - из стиля самого элемента."])

        if info.bars then
            Label(page, L["Текстура полос"])
            local texturePicker
            texturePicker = Picker(page, LookOptions(Look.TEXTURES, L["как у всех"]), element.texture or "default", function(value)
                texturePicker:Refresh(value)
                element.texture = value
                Look:Refresh(key)
            end, nil, PV("LookBar", "texture", key))
        end

        Label(page, L["Шрифт"])
        local fontPicker
        fontPicker = Picker(page, FontChoices(L["как у всех"]), element.font or "default", function(value)
            fontPicker:Refresh(value)
            element.font = value
            Look:Refresh(key)
        end, nil, PV("LookBar", "font", key))

        Label(page, L["Обводка текста"])
        local outlinePicker
        outlinePicker = Picker(page, LookOptions(Look.OUTLINES, L["как у всех"]), element.outline or "default", function(value)
            outlinePicker:Refresh(value)
            element.outline = value
            Look:Refresh(key)
        end, nil, PV("LookBar", "outline", key))

        Slider(page, L["Размер шрифта"], 70, 150, 5, element.fontScale or 100, function(val)
            element.fontScale = val
            Look:Refresh(key)
        end, "%")

        Section(page, L["Цвета"])

        for _, slot in ipairs(info.colors or {}) do
            ColorRow(page, L[Look.COLOR_SLOTS[slot]], key, slot)
        end

        LookApplyButtons(page, L["Сбросить этот элемент"], function() Look:Reset(key) end)
    end
end

local function BuildLayouts(page)
    local Movers = NS.Movers
    local db = Movers and Movers:Layouts() or { saved = {}, bySpec = {} }

    Section(page, L["Раскладки под роль"])

    Note(page, L["Раскладка запоминает, где стоят рамки, панели, полоса заклинания, чат, миникарта, рейд-фреймы и остальное. Расставьте элементы, сохраните раскладку в ячейку и переключайтесь между ними одной кнопкой или автоматически при смене специализации."])

    Buttons(page, {
        { label = L["Расставить элементы"], width = 200, action = function()
            if NS.Movers then NS.Movers:Toggle() end
        end },
    })

    local function Status(slot)
        local saved = db.saved[slot]
        if not saved then return "|cff808080" .. L["не сохранена"] .. "|r" end
        local mark = db.current == slot and ("  |cff40ff80" .. L["сейчас"] .. "|r") or ""
        return date("%d.%m %H:%M", saved.time or 0) .. mark
    end

    local labels = {}
    local function RefreshLabels()
        for slot, label in pairs(labels) do
            label:SetText(L[Movers:SlotName(slot)] .. "   " .. Status(slot))
        end
    end

    for _, entry in ipairs(Movers and Movers.LAYOUT_SLOTS or {}) do
        local slot = entry.key
        labels[slot] = Label(page, L[entry.name] .. "   " .. Status(slot))
        Buttons(page, {
            { label = L["Сохранить текущую"], width = 170, action = function()
                Movers:SaveLayout(slot)
                RefreshLabels()
            end },
            { label = L["Применить"], width = 120, action = function()
                Movers:LoadLayout(slot)
                RefreshLabels()
            end },
            { label = L["Удалить"], width = 100, action = function()
                db.saved[slot] = nil
                if db.current == slot then db.current = nil end
                RefreshLabels()
            end },
        })
    end

    Section(page, L["Переключение по специализации"])

    Check(page, L["Менять раскладку при смене специализации"], db.auto, function(val)
        db.auto = val
        if val and Movers then Movers:CheckSpec() end
    end)

    local options = { { key = "none", label = L["не менять"] } }
    for _, entry in ipairs(Movers and Movers.LAYOUT_SLOTS or {}) do
        options[#options + 1] = { key = entry.key, label = L[entry.name] }
    end

    for tab = 1, GetNumTalentTabs and GetNumTalentTabs() or 0 do
        local name = GetTalentTabInfo(tab)
        if name then
            Label(page, name)
            local picker
            picker = Picker(page, options, db.bySpec[tab] or "none", function(value)
                picker:Refresh(value)
                db.bySpec[tab] = value
            end)
        end
    end
end

local function BuildUnitLook(page)
    local db = NS.db.playerUI or {}

    local function Set(field, value)
        if NS.PlayerUI then NS.PlayerUI:SetLook(field, value) end
    end

    Section(page, L["Вид рамок"])

    Label(page, L["Стиль рамок"])

    local stylePicker
    stylePicker = Picker(page, WithExtras({
        { key = "classic", label = L["классика"] },
        { key = "slim",    label = L["тонкие"] },
        { key = "float",   label = L["выносной портрет"] },
        { key = "neon",    label = L["неон"] },
        { key = "glass",   label = L["стекло"] },
        { key = "plates",  label = L["плашки"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "dark",    label = L["тёмные"] },
        { key = "outline", label = L["контур"] },
    }, NS.PlayerUI and NS.PlayerUI.EXTRA_LIST), db.frameStyle or "classic", function(value)
        Set("frameStyle", value)
        stylePicker:Refresh(value)
    end, nil, PV("Sample", "PlayerUI", "playerUI", "frameStyle"))

    Note(page, L["Классика - плитка с портретом. Тонкие - без плитки и портрета, имя над полосой. Выносной портрет - большой портрет выступает за край рамки. Неон - свечение вместо рамки и градиентная заливка. Стекло - прозрачная плитка с рамкой цвета темы. Плашки - имя, здоровье, ресурс и портрет отдельными плашками. Стиль меняется вне боя."])

    Label(page, L["Цвет полосы здоровья"])

    local colorPicker
    colorPicker = Picker(page, {
        { key = "class",    label = L["цвет класса"] },
        { key = "accent",   label = L["цвет темы"] },
        { key = "gradient", label = L["по запасу здоровья"] },
        { key = "dark",     label = L["тёмный"] },
    }, db.healthColor or "class", function(value)
        Set("healthColor", value)
        colorPicker:Refresh(value)
    end, nil, PV("Sample", "PlayerUI", "playerUI", "healthColor"))

    Label(page, L["Текст здоровья"])

    local textPicker
    textPicker = Picker(page, {
        { key = "auto",    label = L["авто"] },
        { key = "percent", label = L["проценты"] },
        { key = "value",   label = L["число"] },
        { key = "both",    label = L["число и %"] },
        { key = "full",    label = L["текущее / макс."] },
        { key = "deficit", label = L["сколько не хватает"] },
        { key = "none",    label = L["скрыть"] },
    }, db.textFormat or "auto", function(value)
        Set("textFormat", value)
        textPicker:Refresh(value)
    end, nil, PV("Sample", "PlayerUI", "playerUI", "textFormat"))

    Note(page, L["Авто: на крупных рамках число и проценты, на маленьких только проценты."])

    Slider(page, L["Размер шрифта имени"], 0, 18, 1, db.nameSize or 0, function(val)
        Set("nameSize", val)
    end)

    Slider(page, L["Размер шрифта значений"], 0, 18, 1, db.valueSize or 0, function(val)
        Set("valueSize", val)
    end)

    Note(page, L["0 - размер подбирается по высоте рамки."])

    Slider(page, L["Высота полосы ресурса"], 4, 20, 1, db.powerHeight or 10, function(val)
        Set("powerHeight", val)
    end)

    Label(page, L["Текст ресурса"])
    local powerPicker
    powerPicker = Picker(page, {
        { key = "full",    label = L["текущее / макс."] },
        { key = "current", label = L["число"] },
        { key = "percent", label = L["проценты"] },
        { key = "none",    label = L["скрыть"] },
    }, db.powerFormat or "full", function(value)
        Set("powerFormat", value)
        powerPicker:Refresh(value)
    end, nil, PV("Sample", "PlayerUI", "playerUI", "powerFormat"))

    Label(page, L["Цвет имени"])
    local namePicker
    namePicker = Picker(page, {
        { key = "text",  label = L["как текст"] },
        { key = "class", label = L["класс или отношение"] },
    }, db.nameColor or "text", function(value)
        Set("nameColor", value)
        namePicker:Refresh(value)
    end, nil, PV("Sample", "PlayerUI", "playerUI", "nameColor"))

    Slider(page, L["Длина имени"], 0, 24, 1, db.nameLength or 0, function(val)
        Set("nameLength", val)
    end)

    Section(page, L["Теги"])
    Note(page, L["Свой текст из тегов в квадратных скобках, например [name] [level] или [health:current] / [health:max]. Пусто - как настроено выше. Теги цвета ([classcolor], [reactioncolor], [healthcolor], [powercolor], [threatcolor], [difficultycolor], [accent]) ставятся перед текстом, [close] - после него."])
    if NS.PlayerUI and NS.PlayerUI.TagNames then
        local list = {}
        for _, key in ipairs(NS.PlayerUI:TagNames()) do list[#list + 1] = "[" .. key .. "]" end
        Note(page, L["Все теги"] .. ": " .. table.concat(list, " "))
    end
    TextInput(page, L["Текст имени"], db.tagName or "", function(value) Set("tagName", value) end, 200)
    TextInput(page, L["Текст здоровья"], db.tagValue or "", function(value) Set("tagValue", value) end, 200)
    TextInput(page, L["Текст ресурса"], db.tagPower or "", function(value) Set("tagPower", value) end, 200)
    TextInput(page, L["Строка уровня и класса"], db.tagDetail or "", function(value) Set("tagDetail", value) end, 200)
    Note(page, L["У каждой рамки на её странице можно задать свои теги - они главнее общих."])
    Note(page, L["0 - имя целиком. Иначе длинное имя обрезается до этого числа букв."])
end

local function BuildPlayerUI(page)
    local db = NS.db

    Section(page, L["Рамки юнитов"])

    Note(page, L["Свои рамки игрока, цели, цели цели и питомца."])

    Check(page, L["Включить свой интерфейс игрока"], db.playerUI and db.playerUI.enabled, function(val)
        if NS.PlayerUI then NS.PlayerUI:Toggle() end
    end)

    Check(page, L["Скрывать рамки клиента"], not db.playerUI or db.playerUI.hideBlizzard ~= false, function(val)
        if db.playerUI then db.playerUI.hideBlizzard = val end
        if val and NS.PlayerUI then NS.PlayerUI:HideBlizzard() end
    end)

    Check(page, L["Показывать полосу ресурса"], not db.playerUI or db.playerUI.showPower ~= false, function()
        if NS.PlayerUI then NS.PlayerUI:TogglePower() end
    end)

    Check(page, L["Ресурсы класса под рамкой игрока: серия приёмов, руны, тотемы"], not db.playerUI or db.playerUI.classPower ~= false, function(val)
        if db.playerUI then db.playerUI.classPower = val and true or false end
        NS.Print(L["Нужен /reload"])
    end)

    Slider(page, L["Масштаб рамок"], 50, 200, 5,
        math.floor(((db.playerUI and db.playerUI.scale) or 1) * 100),
        function(val)
            if NS.PlayerUI then NS.PlayerUI:SetScale(val / 100) end
        end, "%")

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.PlayerUI then NS.PlayerUI:Move() end
        end },
        { label = L["Сбросить расположение"], action = function()
            if NS.PlayerUI then NS.PlayerUI:ResetPositions() end
        end, width = 180 },
    })

    Section(page, L["Шкала кулдаунов"])

    Note(page, L["Горизонтальная шкала: иконка едет к левому краю по мере отката."])

    Check(page, L["Включить шкалу"], not db.cooldownBar or db.cooldownBar.enabled ~= false, function()
        if NS.CooldownBar then NS.CooldownBar:Toggle() end
    end)

    Slider(page, L["Длина шкалы, сек"], 30, 600, 30,
        (db.cooldownBar and db.cooldownBar.maxTime) or 180,
        function(val)
            if NS.CooldownBar then NS.CooldownBar:SetMax(val) end
        end)

    Slider(page, L["Сжатие шкалы"], 10, 100, 5,
        math.floor(((db.cooldownBar and db.cooldownBar.compression) or 0.4) * 100 + 0.5),
        function(val)
            if NS.CooldownBar and NS.CooldownBar.SetCompression then NS.CooldownBar:SetCompression(val / 100) end
        end, "%")
    Note(page, L["Чем меньше, тем больше места на шкале у коротких откатов. 100% - равномерная шкала."])

    Slider(page, L["Ширина шкалы"], 200, 900, 20,
        (db.cooldownBar and db.cooldownBar.width) or 460,
        function(val)
            if NS.CooldownBar then NS.CooldownBar:SetWidth(val) end
        end)

    Label(page, L["Стиль шкалы"])

    local barStylePicker
    barStylePicker = Picker(page, {
        { key = "rail",  label = L["линия с подложкой"] },
        { key = "track", label = L["дорожка"] },
        { key = "line",  label = L["только линия"] },
        { key = "neon",  label = L["неон"] },
        { key = "zones", label = L["зоны"] },
        { key = "pixel", label = L["пиксель"] },
        { key = "glass", label = L["стекло"] },
        { key = "dark",  label = L["тёмная"] },
    }, (db.cooldownBar and db.cooldownBar.style) or "rail", function(value)
        if NS.CooldownBar then NS.CooldownBar:SetOption("style", value) end
        barStylePicker:Refresh(value)
    end, nil, PV("Sample", "CooldownBar", "cooldownBar", "style"))

    Check(page, L["Линия по центру шкалы"], db.cooldownBar and db.cooldownBar.rail, function(val)
        if NS.CooldownBar then NS.CooldownBar:SetOption("rail", val and true or false) end
    end)

    Check(page, L["Прятать шкалу, когда нет откатов"], db.cooldownBar and db.cooldownBar.hideIdle, function(val)
        if NS.CooldownBar then NS.CooldownBar:SetOption("hideIdle", val) end
    end)

    Label(page, L["Что показывать на шкале"])
    local cdb = db.cooldownBar or {}
    for _, entry in ipairs({
        { key = "srcSpells",  label = "Заклинания из книги" },
        { key = "srcPet",     label = "Способности питомца" },
        { key = "srcActions", label = "Всё с панелей команд (макросы, вещи)" },
        { key = "srcEquip",   label = "Надетые вещи (аксессуары, пояс, перчатки)" },
        { key = "srcBags",    label = "Расходники в сумках (зелья, камни здоровья)" },
    }) do
        Check(page, L[entry.label], cdb[entry.key] ~= false, function(val)
            if NS.CooldownBar then NS.CooldownBar:SetOption(entry.key, val and true or false) end
        end)
    end

    Slider(page, L["Не показывать откаты короче, сек"], 2, 30, 1, cdb.minDuration or 2, function(val)
        if NS.CooldownBar then NS.CooldownBar:SetOption("minDuration", val) end
    end)

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.Movers then NS.Movers:Toggle("cooldown") end
        end },
        { label = L["Сбросить расположение"], action = function()
            if NS.CooldownBar then NS.CooldownBar:ResetPosition() end
        end, width = 180 },
    })
end

local function BuildActionBars(page)
    local db = NS.db
    local bars = db.actionBars or {}

    Section(page, L["Панели команд"])

    Note(page, L["Кнопки остаются клиентскими, поэтому привязки, макросы и перетаскивание работают как обычно."])

    Check(page, L["Включить свои панели"], bars.enabled, function()
        if NS.ActionBars then NS.ActionBars:Toggle() end
    end)

    Check(page, L["Показывать привязки клавиш"], bars.showHotKey ~= false, function()
        if NS.ActionBars then NS.ActionBars:ToggleHotKeys() end
    end)

    Slider(page, L["Размер кнопки"], 18, 64, 1, bars.size or 32, function(val)
        if NS.ActionBars then NS.ActionBars:SetSize(val) end
    end)

    Slider(page, L["Отступ между кнопками"], 0, 20, 1, bars.spacing or 4, function(val)
        if NS.ActionBars then NS.ActionBars:SetSpacing(val) end
    end)

    Check(page, L["Цвета по состоянию кнопки"], bars.stateColors ~= false, function(val)
        if NS.db.actionBars then NS.db.actionBars.stateColors = val end
    end)

    Check(page, L["Цифры отката на кнопках"], bars.cooldownText ~= false, function(val)
        if NS.db.actionBars then NS.db.actionBars.cooldownText = val end
    end)

    Check(page, L["Скрывать пустые ячейки"], bars.hideEmpty ~= false, function(val)
        if NS.db.actionBars then NS.db.actionBars.hideEmpty = val end
        if NS.ActionBars then NS.ActionBars:Apply() end
    end)

    Check(page, L["Прижимать шкалу кулдаунов"], (NS.db.cooldownBar or {}).snap ~= false, function(val)
        if NS.db.cooldownBar then NS.db.cooldownBar.snap = val end
        if NS.ActionBars then NS.ActionBars:Apply() end
    end)

    Check(page, L["Подложка под панелями"], bars.panel, function(val)
        if NS.db.actionBars then NS.db.actionBars.panel = val end
        if NS.ActionBars then NS.ActionBars:Apply() end
    end)

    Check(page, L["В бою показывать скрытые панели"], bars.fadeCombat and true or false, function(val)
        if NS.db.actionBars then NS.db.actionBars.fadeCombat = val end
    end)

    Slider(page, L["Видимость скрытых панелей"], 0, 60, 5, bars.fadeAlpha or 0, function(val)
        if NS.db.actionBars then NS.db.actionBars.fadeAlpha = val end
    end, "%")
    Note(page, L["Сколько видно панели «только при наведении» или «только в бою», пока она спрятана. Действует и на микро-меню."])

    Label(page, L["Скорость появления и исчезновения"])
    local fadeSpeedPicker
    fadeSpeedPicker = Picker(page, {
        { key = 50,  label = L["медленно"] },
        { key = 100, label = L["обычно"] },
        { key = 200, label = L["быстро"] },
        { key = 600, label = L["сразу"] },
    }, bars.fadeSpeed or 100, function(value)
        if NS.db.actionBars then NS.db.actionBars.fadeSpeed = value end
        fadeSpeedPicker:Refresh(value)
    end)

    Note(page, L["Панель, которая показывается только при наведении, включается на её собственной странице."])

    Check(page, L["Скрывать штатную панель"], bars.hideBlizzard ~= false, function(val)
        if NS.db.actionBars then NS.db.actionBars.hideBlizzard = val end
        if val and NS.ActionBars then NS.ActionBars:Apply() else NS.Print(L["Нужен /reload"]) end
    end)


    Note(page, L["Вне дистанции - красным, не хватает ресурса - синим, нельзя применить - серым."])

    for _, entry in ipairs({
        { key = "rangeColor",    label = "Цвет: вне дистанции" },
        { key = "powerColor",    label = "Цвет: не хватает ресурса" },
        { key = "unusableColor", label = "Цвет: нельзя применить" },
    }) do
        ColorSetting(page, L[entry.label], function()
            local defaults = NS.ActionBars and NS.ActionBars.STATE_COLORS or {}
            local c = (NS.db.actionBars or {})[entry.key] or defaults[entry.key] or { 1, 1, 1 }
            return c[1], c[2], c[3]
        end, function(r, g, b)
            if NS.db.actionBars then NS.db.actionBars[entry.key] = { r, g, b } end
        end)
    end

    Buttons(page, {
        { label = L["Режим привязок"], action = function()
            if NS.ActionBars then NS.ActionBars:KeybindMode() end
        end, width = 170 },
    })

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.ActionBars then NS.ActionBars:Move() end
        end },
        { label = L["Сбросить расположение"], action = function()
            if NS.ActionBars then NS.ActionBars:ResetPositions() end
        end, width = 180 },
    })
end

local function BuildMicroPage(page)
    local bars = NS.db.actionBars or {}

    Section(page, L["Микро-меню"])

    local micro = bars.micro or {}

    Label(page, L["Где стоит микро-меню"])

    local microPicker
    microPicker = Picker(page, {
        { key = "chat", label = L["под чатом"] },
        { key = "bars", label = L["у панелей"] },
        { key = "free", label = L["свободно"] },
    }, micro.dock or "chat", function(value)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.dock = value
        end
        if NS.ActionBars then NS.ActionBars:AnchorMicro() end
        microPicker:Refresh(value)
    end)

    Label(page, L["Стиль микро-меню"])

    local microStylePicker
    microStylePicker = Picker(page, {
        { key = "tiles", label = L["плитки"] },
        { key = "flat",  label = L["плоские"] },
        { key = "strip", label = L["лента"] },
        { key = "glow",  label = L["подсветка"] },
        { key = "dock",  label = L["док"] },
    }, micro.style or "tiles", function(value)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.style = value
        end
        if NS.ActionBars then NS.ActionBars:LayoutMicro() end
        microStylePicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.micro", "style", { kind = "micro" }))

    Label(page, L["Иконки микро-меню"])

    local microIconPicker
    local microSets = NS.ActionBars and NS.ActionBars.MicroIconSets and NS.ActionBars:MicroIconSets() or {}
    local microCurrent = micro.icons or "minimal"
    local microBase = {
        { key = "minimal", label = L["минималистичные"] },
        { key = "full",    label = L["полноценные"] },
    }
    local AB = NS.ActionBars
    for _, key in ipairs(AB and AB.MICRO_BUILTIN_ORDER or {}) do
        microBase[#microBase + 1] = { key = key, label = L[AB.MICRO_BUILTIN_LABELS[key]] }
    end
    local microKnown = false
    for _, option in ipairs(microBase) do if option.key == microCurrent then microKnown = true end end
    for _, set in ipairs(microSets) do if set.key == microCurrent then microKnown = true end end
    microIconPicker = Picker(page, WithExtras(microBase, microSets), microKnown and microCurrent or "minimal", function(value)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.icons = value
        end
        if NS.ActionBars then NS.ActionBars:RefreshMicroIcons() end
        microIconPicker:Refresh(value)
    end, nil, PV("MicroIcons"))

    local function MicroSet(key, value)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro[key] = value
        end
        if NS.ActionBars then NS.ActionBars:RefreshMicroIcons() end
    end

    Slider(page, L["Размер иконок"], 60, 130, 5, micro.iconScale or 100, function(val)
        MicroSet("iconScale", val)
    end, "%")

    Label(page, L["Цвет минималистичных иконок"])

    local microTintPicker
    microTintPicker = Picker(page, {
        { key = "theme",  label = L["как текст"] },
        { key = "white",  label = L["белый"] },
        { key = "gold",   label = L["золото"] },
        { key = "silver", label = L["серебро"] },
        { key = "class",  label = L["цвет класса"] },
    }, micro.iconColor or "theme", function(value)
        MicroSet("iconColor", value)
        microTintPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.micro", "iconColor", { kind = "micro" }))

    Check(page, L["Подсвечивать иконку цветом темы при наведении"], micro.hoverAccent ~= false, function(val)
        MicroSet("hoverAccent", val and true or false)
    end)

    Note(page, L["Плитки - каждая кнопка в своей рамке. Плоские - только иконки, при наведении полоска снизу. Лента - кнопки слиты в одну полосу с разделителями. Подсветка - тёмные кнопки с полоской цвета темы снизу. Док - иконки плавно увеличиваются под курсором, соседние чуть меньше."])

    Check(page, L["Показывать сумки в микро-меню"], micro.bags ~= false, function(val)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.bags = val
        end
        if NS.ActionBars then NS.ActionBars:LayoutMicro() end
    end)

    Slider(page, L["Микро-кнопок в ряд"], 1, 12, 1, micro.perRow or 6, function(val)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.perRow = val
        end
        if NS.ActionBars then NS.ActionBars:LayoutMicro() end
    end)

    Slider(page, L["Размер микро-кнопок"], 14, 40, 1, micro.size or 22, function(val)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro.size = val
        end
        if NS.ActionBars then NS.ActionBars:LayoutMicro() end
    end)

    Check(page, L["Скрывать микро-меню и сумки"], bars.hideMicro, function(val)
        if NS.db.actionBars then NS.db.actionBars.hideMicro = val end
        if NS.ActionBars then NS.ActionBars:LayoutMicro() end
    end)

    local function SetMicro(field, value, relayout)
        if NS.db.actionBars and NS.db.actionBars.micro then
            NS.db.actionBars.micro[field] = value
        end
        if not NS.ActionBars then return end
        if relayout then NS.ActionBars:LayoutMicro() end
        NS.ActionBars:StyleMicro()
    end

    Slider(page, L["Отступ между микро-кнопками"], 0, 12, 1, micro.spacing or 2, function(val)
        SetMicro("spacing", val, true)
    end)

    Label(page, L["Цвет рамки микро-кнопок"])

    local microColor
    microColor = Picker(page, {
        { key = "dark",   label = L["тёмный"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
    }, micro.borderColor or "dark", function(value)
        SetMicro("borderColor", value)
        microColor:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.micro", "borderColor", { kind = "micro" }))

    Check(page, L["Подложка под микро-меню"], micro.panel, function(val)
        SetMicro("panel", val)
    end)

    Check(page, L["Микро-меню только при наведении"], micro.mouseover, function(val)
        SetMicro("mouseover", val, true)
        if NS.ActionBars then NS.ActionBars:StartFader() end
    end)

    Slider(page, L["Прозрачность микро-меню"], 20, 100, 5, math.floor((micro.alpha or 1) * 100 + 0.5), function(val)
        SetMicro("alpha", val / 100, true)
    end, "%")

    Check(page, L["Прятать микро-меню в бою"], micro.combatHide, function(val)
        SetMicro("combatHide", val and true or nil)
        if NS.ActionBars then NS.ActionBars:StartFader() end
    end)

    Check(page, L["Без подсказок при наведении"], micro.noTooltip, function(val)
        SetMicro("noTooltip", val and true or nil)
    end)

    Slider(page, L["Плотность фона микро-кнопок"], 0, 100, 5, micro.groundAlpha or 100, function(val)
        SetMicro("groundAlpha", val)
    end, "%")

    Slider(page, L["Увеличение в стиле «док»"], 110, 170, 5, micro.dockZoom or 135, function(val)
        SetMicro("dockZoom", val)
    end, "%")

    Section(page, L["Порядок и состав микро-меню"])

    Check(page, L["Обратный порядок кнопок"], micro.reverse, function(val)
        SetMicro("reverse", val and true or nil, true)
    end)

    Check(page, L["Заполнять по столбцам"], micro.vertical, function(val)
        SetMicro("vertical", val and true or nil, true)
    end)
    Note(page, L["По столбцам «Микро-кнопок в ряд» задаёт, сколько кнопок в одном столбце."])

    Label(page, L["Какие кнопки показывать"])
    local microEntries = {
        { name = "CharacterMicroButton",        label = "Персонаж" },
        { name = "SpellbookMicroButton",        label = "Заклинания" },
        { name = "TalentMicroButton",           label = "Таланты" },
        { name = "AchievementMicroButton",      label = "Достижения" },
        { name = "QuestLogMicroButton",         label = "Задания" },
        { name = "SocialsMicroButton",          label = "Общение" },
        { name = "GuildMicroButton",            label = "Гильдия" },
        { name = "LFDMicroButton",              label = "Поиск группы" },
        { name = "CollectionsMicroButton",      label = "Коллекции" },
        { name = "EncounterJournalMicroButton", label = "Путеводитель" },
        { name = "StoreMicroButton",            label = "Магазин" },
        { name = "MainMenuMicroButton",         label = "Главное меню" },
    }
    for _, extra in ipairs(NS.ActionBars and NS.ActionBars.MICRO_EXTRA or {}) do microEntries[#microEntries + 1] = extra end
    for _, entry in ipairs(microEntries) do
        local hiddenList = type(micro.hidden) == "table" and micro.hidden or {}
        Check(page, L[entry.label], not hiddenList[entry.name], function(val)
            local store = NS.db.actionBars and NS.db.actionBars.micro
            if not store then return end
            if type(store.hidden) ~= "table" then store.hidden = {} end
            store.hidden[entry.name] = (not val) or nil
            if NS.ActionBars then NS.ActionBars:LayoutMicro() end
        end)
    end

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.Movers then NS.Movers:Toggle("bars") end
        end },
    })
end

local function BuildButtonLook(page)
    local bars = NS.db.actionBars or {}
    local look = bars.look or {}

    local function Set(field, value)
        if NS.ActionBars then NS.ActionBars:SetLook(field, value) end
    end

    Section(page, L["Вид кнопок"])

    Note(page, L["Меняется сразу на всех панелях, перезагрузка не нужна."])

    Label(page, L["Стиль кнопок"])

    local buttonStylePicker
    buttonStylePicker = Picker(page, {
        { key = "flat",    label = L["плоские"] },
        { key = "classic", label = L["классика WoW"] },
        { key = "glow",    label = L["свечение"] },
        { key = "bevel",   label = L["объём"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "neon",    label = L["неон"] },
        { key = "shadow",  label = L["тень"] },
        { key = "dark",    label = L["тёмная рамка"] },
    }, look.style or "flat", function(value)
        Set("style", value)
        buttonStylePicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "style"))

    Note(page, L["Классика WoW - родная рамка кнопок клиента и полная иконка. Свечение - без рамки, мягкий свет вокруг кнопки. Объём - светлый верхний и тёмный нижний край, как у выпуклой кнопки. Пиксель - чёрная рамка с серой внутренней линией. Настройки рамки ниже действуют на плоские кнопки."])

    Label(page, L["Рамка"])

    local borderPicker
    borderPicker = Picker(page, {
        { key = "thin",  label = L["тонкая"] },
        { key = "thick", label = L["толстая"] },
        { key = "none",  label = L["без рамки"] },
    }, look.border or "thin", function(value)
        Set("border", value)
        borderPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "border"))

    Label(page, L["Цвет рамки"])

    local colorPicker
    colorPicker = Picker(page, {
        { key = "dark",   label = L["тёмный"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
    }, look.borderColor or "dark", function(value)
        Set("borderColor", value)
        colorPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "borderColor"))

    Slider(page, L["Высота кнопки"], 50, 100, 5, math.floor((look.ratio or 1) * 100 + 0.5), function(val)
        Set("ratio", val / 100)
    end, "%")

    Check(page, L["Приблизить иконку"], look.zoom, function(val)
        Set("zoom", val)
    end)

    Check(page, L["Блик на кнопках"], look.gloss ~= false, function(val)
        Set("gloss", val)
    end)

    Slider(page, L["Плотность пустых ячеек"], 0, 100, 5, math.floor((look.groundAlpha or 1) * 100 + 0.5), function(val)
        Set("groundAlpha", val / 100)
    end, "%")

    Label(page, L["Где писать клавишу"])

    local hotkeyPicker
    hotkeyPicker = Picker(page, {
        { key = "TOPRIGHT",   label = L["справа сверху"] },
        { key = "TOPLEFT",    label = L["слева сверху"] },
        { key = "BOTTOMLEFT", label = L["слева снизу"] },
    }, look.hotkeyPos or "TOPRIGHT", function(value)
        Set("hotkeyPos", value)
        hotkeyPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "hotkeyPos"))

    Slider(page, L["Размер клавиши"], 7, 16, 1, look.hotkeySize or 10, function(val)
        Set("hotkeySize", val)
    end)

    Slider(page, L["Размер числа предметов"], 8, 18, 1, look.countSize or 11, function(val)
        Set("countSize", val)
    end)

    Label(page, L["Цвет клавиши"])

    local keyColorPicker
    keyColorPicker = Picker(page, {
        { key = "white",  label = L["белый"] },
        { key = "gray",   label = L["серый"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "gold",   label = L["золотой"] },
    }, look.hotkeyColor or "white", function(value)
        Set("hotkeyColor", value)
        keyColorPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "hotkeyColor"))

    Label(page, L["Откат"])

    Slider(page, L["Размер цифр отката"], 0, 24, 1, look.cdSize or 0, function(val)
        Set("cdSize", val)
    end)

    Note(page, L["0 - размер подбирается по кнопке."])

    Check(page, L["Цифры меняют цвет к концу отката"], look.cdColors ~= false, function(val)
        Set("cdColors", val)
    end)

    Slider(page, L["Затемнение кнопки на откате"], 0, 100, 5, look.cdDim or 100, function(val)
        Set("cdDim", val)
    end, "%")

    Check(page, L["Названия макросов"], bars.showMacroName, function(val)
        if NS.db.actionBars then NS.db.actionBars.showMacroName = val end
        if NS.ActionBars then NS.ActionBars:RestyleAll() end
    end)

    Slider(page, L["Размер названий макросов"], 7, 14, 1, look.macroSize or 9, function(val)
        Set("macroSize", val)
    end)

    Slider(page, L["Цифры отката от длительности"], 2, 30, 1, bars.cdMin or 2, function(val)
        if NS.db.actionBars then NS.db.actionBars.cdMin = val end
    end, L[" с"])
    Note(page, L["Короче этого откат показывается только затемнением, без цифр."])

    Section(page, L["Клавиши и подсветка"])

    Check(page, L["Сокращать названия клавиш (S1, CM4, N5, WU)"], look.hotkeyShort, function(val)
        Set("hotkeyShort", val and true or nil)
    end)

    Label(page, L["Цвет числа предметов"])
    local countColorPicker
    countColorPicker = Picker(page, {
        { key = "gold",   label = L["золотой"] },
        { key = "white",  label = L["белый"] },
        { key = "accent", label = L["цвет темы"] },
    }, look.countColor or "gold", function(value)
        Set("countColor", value)
        countColorPicker:Refresh(value)
    end, nil, PV("Sample", "ActionBars", "actionBars.look", "countColor"))

    Slider(page, L["Подсветка кнопки под курсором"], 0, 60, 5, look.hoverAlpha or 25, function(val)
        Set("hoverAlpha", val)
    end, "%")
end

local GROWTH = {
    { key = "RIGHT", label = "вправо" },
    { key = "LEFT",  label = "влево" },
    { key = "DOWN",  label = "вниз" },
    { key = "UP",    label = "вверх" },
}

local function BuildBarPage(key, index)
    return function(page)
        local bars = NS.db.actionBars or {}
        local store = bars.bars and bars.bars[key] or {}

        local named = ({ stance = "Панель форм", pet = "Панель питомца" })[key]
        Section(page, named and L[named] or (L["Панель"] .. " " .. index))

        if index > 5 and not named then
            Note(page, L["Эту панель создаёт аддон, у клиента её нет."])
        end

        Check(page, L["Включить"], store.enabled ~= false, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarEnabled(key, val) end
        end)

        Slider(page, L["Кнопок"], 1, 12, 1, store.buttons or 12, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "buttons", val) end
        end)

        Slider(page, L["Кнопок в ряд"], 1, 12, 1, store.perRow or 12, function(val)
            if NS.ActionBars then NS.ActionBars:SetPerRow(key, val) end
        end)

        Slider(page, L["Прозрачность"], 10, 100, 5, math.floor((store.alpha or 1) * 100), function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "alpha", val / 100) end
        end, "%")

        Check(page, L["Прятать пустые ячейки этой панели"], store.hideEmpty, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "hideEmpty", val) end
        end)

        Check(page, L["Показывать только при наведении"], store.mouseover, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "mouseover", val) end
        end)

        Check(page, L["Показывать только в бою"], store.combatOnly, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "combatOnly", val) end
        end)

        Check(page, L["Клавиши на кнопках этой панели"], not store.hideKeys, function(val)
            if NS.ActionBars then
                NS.ActionBars:SetBarOption(key, "hideKeys", (not val) or nil)
                NS.ActionBars:RestyleAll()
            end
        end)

        Slider(page, L["Свой размер кнопок"], 0, 64, 1, store.size or 0, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "size", val) end
        end)

        Slider(page, L["Свой отступ"], -1, 20, 1, store.spacing or -1, function(val)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "spacing", val) end
        end)

        Note(page, L["0 у размера и -1 у отступа - как у всех панелей."])

        Label(page, L["Направление роста"])

        local options = {}
        for _, entry in ipairs(GROWTH) do
            options[#options + 1] = { key = entry.key, label = L[entry.label] }
        end

        local picker
        picker = Picker(page, options, store.growth or "RIGHT", function(value)
            if NS.ActionBars then NS.ActionBars:SetBarOption(key, "growth", value) end
            picker:Refresh(value)
        end)

        Buttons(page, {
            { label = L["Расставить"], action = function()
                if NS.Movers then NS.Movers:Toggle("bars") end
            end },
        })
    end
end

local AURA_KEYS = {
    target = { on = "targetAuras", buffs = "targetBuffs", debuffs = "targetDebuffs" },
    focus  = { on = "focusAuras",  buffs = "focusBuffs",  debuffs = "focusDebuffs" },
}

local function BuildUnitPage(unit, title)
    local units = type(unit) == "table" and unit or { unit }
    unit = units[1]
    local function Each(fn)
        for _, each in ipairs(units) do fn(each) end
    end
    return function(page)
        local playerUI = NS.db.playerUI or {}
        local store = playerUI.units and playerUI.units[unit] or {}

        Section(page, L[title])

        local function TagSet(field, value)
            Each(function(each)
                local own = NS.db.playerUI and NS.db.playerUI.units and NS.db.playerUI.units[each]
                if own then own[field] = value ~= "" and value or nil end
            end)
            if NS.PlayerUI then NS.PlayerUI:UpdateAll() end
        end
        TextInput(page, L["Свой текст имени (теги)"], store.tagName or "", function(value) TagSet("tagName", value) end, 200)
        TextInput(page, L["Свой текст здоровья (теги)"], store.tagValue or "", function(value) TagSet("tagValue", value) end, 200)
        TextInput(page, L["Свой текст ресурса (теги)"], store.tagPower or "", function(value) TagSet("tagPower", value) end, 200)
        Note(page, L["Пусто - общие теги со страницы Вид рамок. Список тегов там же."])

        local auraKeys = AURA_KEYS[unit]

        if auraKeys then
            local function AuraSet(field, value)
                if NS.db.playerUI then NS.db.playerUI[field] = value end
                if NS.PlayerUI then NS.PlayerUI:UpdateAll() end
            end

            local function AuraStore(field, value)
                if NS.db.playerUI and NS.db.playerUI.units then
                    for _, each in ipairs(units) do
                        local own = NS.db.playerUI.units[each]
                        if own then own[field] = value end
                    end
                end
                if NS.PlayerUI then NS.PlayerUI:UpdateAll() end
            end

            Section(page, L["Ауры"])

            Check(page, L["Ауры над рамкой"], playerUI[auraKeys.on] ~= false, function(val)
                AuraSet(auraKeys.on, val and true or false)
            end)

            Check(page, L["Показывать баффы"], playerUI[auraKeys.buffs] ~= false, function(val)
                AuraSet(auraKeys.buffs, val and true or false)
            end)

            Check(page, L["Показывать дебаффы"], playerUI[auraKeys.debuffs] ~= false, function(val)
                AuraSet(auraKeys.debuffs, val and true or false)
            end)

            Slider(page, L["Размер бафов"], 14, 36, 1, store.auraSize or playerUI.auraSize or 22, function(val)
                AuraStore("auraSize", val)
            end)

            Slider(page, L["Размер дебафов"], 14, 48, 1, store.auraDebuffSize or playerUI.auraDebuffSize or 30, function(val)
                AuraStore("auraDebuffSize", val)
            end)

            Slider(page, L["Аур в ряд"], 4, 20, 1, store.auraPerRow or playerUI.auraPerRow or 12, function(val)
                AuraStore("auraPerRow", val)
            end)

            Note(page, L["Размер значков и число в ряд можно задать отдельно у каждой рамки."])

            if unit == "target" then
                Check(page, L["Дебаффы: только наложенные мной"], playerUI.auraDebuffMine, function(val) AuraSet("auraDebuffMine", val and true or nil) end)
                Check(page, L["Выделять мои дебаффы цветом темы"], playerUI.auraMineHighlight ~= false, function(val) AuraSet("auraMineHighlight", val and true or false) end)
                Check(page, L["Баффы: только наложенные мной"], playerUI.auraBuffMine, function(val) AuraSet("auraBuffMine", val and true or nil) end)
                Slider(page, L["Не показывать ауры длиннее, мин"], 0, 60, 1, playerUI.auraMaxDuration or 0, function(val) AuraSet("auraMaxDuration", val) end)
                Note(page, L["0 - показывать любые. Иначе прячутся постоянные ауры и те, что дольше заданного."])
                TextInput(page, L["Скрывать дебаффы (названия или номера через запятую)"], playerUI.auraDebuffBlacklist or "", function(value) AuraSet("auraDebuffBlacklist", value) end, 400)
                TextInput(page, L["Показывать только эти дебаффы (пусто - все)"], playerUI.auraDebuffWhitelist or "", function(value) AuraSet("auraDebuffWhitelist", value) end, 400)
                TextInput(page, L["Скрывать баффы (названия или номера через запятую)"], playerUI.auraBuffBlacklist or "", function(value) AuraSet("auraBuffBlacklist", value) end, 400)
                TextInput(page, L["Показывать только эти баффы (пусто - все)"], playerUI.auraBuffWhitelist or "", function(value) AuraSet("auraBuffWhitelist", value) end, 400)
                Note(page, L["Эти фильтры общие для цели и фокуса."])
            else
                Note(page, L["Какие ауры скрывать или показывать, задаётся на странице «Цель»: фильтры общие для цели и фокуса."])
            end
        end

        if unit == "player" then
            Label(page, L["Портрет"])

            local portraitPicker
            portraitPicker = Picker(page, {
                { key = "3D",  label = L["модель"] },
                { key = "2D",  label = L["картинка"] },
                { key = "off", label = L["без портрета"] },
            }, playerUI.portrait or "3D", function(value)
                if NS.PlayerUI then NS.PlayerUI:SetPortraitStyle(value) end
                portraitPicker:Refresh(value)
            end, nil, PV("Sample", "PlayerUI", "playerUI", "portrait"))
        end

        Check(page, L["Включить"], store.enabled ~= false, function(val)
            if NS.PlayerUI then Each(function(each) NS.PlayerUI:SetUnitEnabled(each, val) end) end
        end)

        Slider(page, L["Ширина"], 80, 400, 4, store.width or 200, function(val)
            if NS.PlayerUI then Each(function(each) NS.PlayerUI:SetUnitSize(each, val, nil) end) end
        end)

        Slider(page, L["Высота"], 18, 80, 2, store.height or 40, function(val)
            if NS.PlayerUI then Each(function(each) NS.PlayerUI:SetUnitSize(each, nil, val) end) end
        end)

        Slider(page, L["Прозрачность"], 10, 100, 5, math.floor((store.alpha or 1) * 100), function(val)
            if NS.PlayerUI then Each(function(each) NS.PlayerUI:SetUnitOption(each, "alpha", val / 100) end) end
        end, "%")

        if #units > 1 then
            Note(page, L["Настройки применяются ко всем рамкам группы. Рамки видны, только когда юниты существуют: боссы в бою с боссом, противники на арене."])
        end

        Buttons(page, {
            { label = L["Расставить"], action = function()
                if NS.Movers then NS.Movers:Toggle("units") end
            end },
        })
    end
end

local function BuildCastBar(page)
    local db = NS.db.castBar or {}

    Section(page, L["Полоса заклинания"])

    Note(page, L["Своя полоса для игрока и цели, клиентская прячется."])

    Check(page, L["Включить"], db.enabled, function()
        if NS.CastBar then NS.CastBar:Toggle() end
    end)

    Check(page, L["Показывать иконку"], db.showIcon ~= false, function(val)
        if NS.CastBar then NS.CastBar.narciSkip = nil end
        if db then db.showIcon = val end
        if NS.CastBar then NS.CastBar:Restyle() end
    end)

    Check(page, L["Показывать время"], db.showTime ~= false, function(val)
        if db then db.showTime = val end
    end)

    Label(page, L["Стиль полосы"])

    local castStylePicker
    castStylePicker = Picker(page, {
        { key = "line",    label = L["линии"] },
        { key = "classic", label = L["классика WoW"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "neon",    label = L["неон"] },
        { key = "thin",    label = L["тонкая"] },
        { key = "glass",   label = L["стекло"] },
        { key = "outline", label = L["контур"] },
        { key = "gradient", label = L["градиент"] },
        { key = "shadow",  label = L["тень"] },
        { key = "underline", label = L["подчёркивание"] },
    }, db.style or "line", function(value)
        if db then db.style = value end
        castStylePicker:Refresh(value)
        if NS.CastBar then
            NS.CastBar:Restyle()
            NS.CastBar:Preview()
        end
    end, nil, PV("Sample", "CastBar", "castBar", "style"))

    Note(page, L["Классика WoW - золотая полоса в родной рамке клиента. Пиксель - серая полоса с чёрной рамкой, иконка отдельно слева. Неон - светящаяся рамка и градиентная заливка. Тонкая - узкая полоса, название и время над ней. При выборе стиля показывается пример."])

    Buttons(page, {
        { label = L["Показать пример"], width = 150, action = function()
            if NS.CastBar then NS.CastBar:Preview() end
        end },
    })

    local function Apply(field, value)
        db[field] = value
        if NS.CastBar then
            NS.CastBar:Restyle()
            NS.CastBar:Preview()
        end
    end

    Section(page, L["Цвета"])

    Label(page, L["Цвет заливки"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "theme",  label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
        { key = "custom", label = L["свои цвета"] },
    }, db.colorMode or "theme", function(value)
        colorPicker:Refresh(value)
        Apply("colorMode", value)
    end, nil, PV("Sample", "CastBar", "castBar", "colorMode"))

    local function ColorField(text, field, default)
        ColorSetting(page, text, function()
            local c = db[field] or default
            return c[1], c[2], c[3]
        end, function(r, g, b)
            Apply(field, { r, g, b })
        end)
    end
    ColorField(L["Заклинание (свои цвета)"], "castColor", { 0.30, 0.65, 1.00 })
    ColorField(L["Поддерживаемое (свои цвета)"], "channelColor", { 0.35, 0.85, 0.50 })
    ColorField(L["Нельзя прервать"], "lockedColor", { 0.70, 0.25, 0.25 })

    Slider(page, L["Плотность фона"], 0, 100, 5, db.bgAlpha or 92, function(val)
        Apply("bgAlpha", val)
    end, "%")

    Section(page, L["Иконка и текст"])

    Label(page, L["Сторона иконки"])
    local sidePicker
    sidePicker = Picker(page, {
        { key = "left",  label = L["слева"] },
        { key = "right", label = L["справа"] },
    }, db.iconSide or "left", function(value)
        sidePicker:Refresh(value)
        Apply("iconSide", value)
    end, nil, PV("Sample", "CastBar", "castBar", "iconSide"))

    Label(page, L["Название"])
    local alignPicker
    alignPicker = Picker(page, {
        { key = "left",   label = L["слева"] },
        { key = "center", label = L["по центру"] },
    }, db.textAlign or "left", function(value)
        alignPicker:Refresh(value)
        Apply("textAlign", value)
    end, nil, PV("Sample", "CastBar", "castBar", "textAlign"))

    Slider(page, L["Размер текста (0 - по высоте полосы)"], 0, 20, 1, db.nameSize or 0, function(val)
        Apply("nameSize", val)
    end)

    Label(page, L["Формат времени"])
    local timePicker
    timePicker = Picker(page, {
        { key = "both",    label = L["осталось / всего"] },
        { key = "left",    label = L["осталось"] },
        { key = "elapsed", label = L["прошло"] },
    }, db.timeFormat or "both", function(value)
        timePicker:Refresh(value)
        Apply("timeFormat", value)
    end, nil, PV("Sample", "CastBar", "castBar", "timeFormat"))

    Section(page, L["Поведение"])

    Check(page, L["Искра на краю заливки"], db.spark ~= false, function(val) Apply("spark", val) end)
    Check(page, L["Задержка сети в конце полосы игрока"], db.latency ~= false, function(val) Apply("latency", val) end)
    Check(page, L["Плавно гаснуть после каста"], db.fade ~= false, function(val) db.fade = val end)
    Check(page, L["Показывать прерванные и сорванные касты"], db.flash ~= false, function(val) db.flash = val end)

    Note(page, L["Задержка - красная зона в конце полосы: если нажать следующее заклинание, когда заливка дошла до неё, каст начнётся без паузы."])

    for _, entry in ipairs({ { key = "player", label = "Игрок" }, { key = "target", label = "Цель" }, { key = "focus", label = "Фокус" } }) do
        local store = db.units and db.units[entry.key] or {}

        Section(page, L[entry.label])

        Check(page, L["Включить"], store.enabled == true or (store.enabled == nil and entry.key ~= "focus"), function(val)
            if NS.CastBar then NS.CastBar:SetUnitOption(entry.key, "enabled", val) end
        end)

        Slider(page, L["Ширина"], 120, 500, 10, store.width or 300, function(val)
            if NS.CastBar then NS.CastBar:SetUnitOption(entry.key, "width", val) end
        end)

        Slider(page, L["Высота"], 14, 48, 2, store.height or 26, function(val)
            if NS.CastBar then NS.CastBar:SetUnitOption(entry.key, "height", val) end
        end)
    end

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.Movers then NS.Movers:Toggle("cast") end
        end },
    })
end

local function BuildAuras(page)
    local db = NS.db.auras or {}

    Section(page, L["Бафы и дебафы"])

    Note(page, L["Иконки клиента остаются на месте, меняется только вид."])

    Check(page, L["Включить"], db.enabled, function()
        if NS.AuraSkin then NS.AuraSkin:Toggle() end
    end)

    local function Set(field, value)
        if NS.AuraSkin then NS.AuraSkin:SetOption(field, value) end
    end

    Label(page, L["Стиль бафов"])

    local auraStylePicker
    auraStylePicker = Picker(page, {
        { key = "square",  label = L["квадраты"] },
        { key = "classic", label = L["классика WoW"] },
        { key = "thick",   label = L["толстая рамка"] },
        { key = "glow",    label = L["свечение"] },
        { key = "bar",     label = L["полоска времени"] },
        { key = "minimal", label = L["только иконки"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "neon",    label = L["неон"] },
        { key = "underline", label = L["подчёркивание"] },
    }, db.style or "square", function(value)
        Set("style", value)
        auraStylePicker:Refresh(value)
    end, nil, PV("Sample", "AuraSkin", "auras", "style"))

    Note(page, L["Квадраты - тёмная рамка и цветная полоска у дебафов. Классика WoW - иконки как в клиенте, время золотом. Толстая рамка - рамка в 2 пикселя, время внутри иконки. Свечение - вместо рамки свет цвета дебафа или темы. Полоска времени - под иконкой тает полоска оставшегося времени. Только иконки - без рамок, время внутри."])

    Slider(page, L["Размер иконки"], 20, 48, 1, db.size or 30, function(val)
        Set("size", val)
    end)

    Slider(page, L["Размер дебафов"], 20, 60, 1, db.debuffSize or db.size or 30, function(val)
        Set("debuffSize", val)
    end)

    Slider(page, L["Иконок в ряд"], 4, 20, 1, db.perRow or 8, function(val)
        Set("perRow", val)
    end)

    Label(page, L["Куда растут"])

    local growPicker
    growPicker = Picker(page, {
        { key = "left",  label = L["влево"] },
        { key = "right", label = L["вправо"] },
    }, db.grow or "left", function(value)
        Set("grow", value)
        growPicker:Refresh(value)
    end, nil, PV("Sample", "AuraSkin", "auras", "grow"))

    Label(page, L["Таймер"])

    Check(page, L["Показывать время под иконкой"], db.showTimers ~= false, function(val)
        Set("showTimers", val)
    end)

    Slider(page, L["Размер таймера"], 7, 16, 1, db.timerSize or 10, function(val)
        Set("timerSize", val)
    end)

    Check(page, L["Не показывать время у бафов длиннее 10 минут"], db.hideLongTimers, function(val)
        Set("hideLongTimers", val)
    end)

    Slider(page, L["Порог длинных бафов, минут"], 1, 60, 1, db.longAt or 10, function(val)
        Set("longAt", val)
    end)

    Label(page, L["Где время"])
    local timerPosPicker
    timerPosPicker = Picker(page, {
        { key = "style",  label = L["как у стиля"] },
        { key = "below",  label = L["под иконкой"] },
        { key = "inside", label = L["внутри иконки"] },
    }, db.timerPos or "style", function(value)
        Set("timerPos", value)
        timerPosPicker:Refresh(value)
    end, nil, PV("Sample", "AuraSkin", "auras", "timerPos"))

    Slider(page, L["Красное время с, секунд"], 0, 30, 1, db.warnAt or 5, function(val)
        Set("warnAt", val)
    end)

    Label(page, L["Иконки"])

    Slider(page, L["Расстояние между иконками"], 0, 16, 1, db.spacing or 5, function(val)
        Set("spacing", val)
    end)

    Slider(page, L["Обрезка краёв иконки, %"], 0, 20, 1, db.iconZoom or 8, function(val)
        Set("iconZoom", val)
    end)

    Slider(page, L["Размер числа стаков"], 7, 20, 1, db.countSize or 11, function(val)
        Set("countSize", val)
    end)

    Label(page, L["Положение"])

    Buttons(page, {
        { label = L["Переместить"], action = function()
            if NS.AuraSkin then NS.AuraSkin:Move() end
        end },
        { label = L["Сбросить"], action = function()
            if NS.AuraSkin then NS.AuraSkin:ResetPosition() end
        end },
    })
end

local function BuildMinimap(page)
    local db = NS.db.minimap or {}

    Section(page, L["Миникарта"])

    Check(page, L["Включить"], db.enabled, function()
        if NS.MinimapSkin then NS.MinimapSkin:Toggle() end
    end)

    Label(page, L["Стиль миникарты"])

    local mapStylePicker
    mapStylePicker = Picker(page, {
        { key = "frame",    label = L["рамка"] },
        { key = "classic",  label = L["классика WoW"] },
        { key = "round",    label = L["круглая с кольцом"] },
        { key = "pixel",    label = L["пиксель"] },
        { key = "neon",     label = L["неон"] },
        { key = "photo",    label = L["фото"] },
        { key = "vignette", label = L["виньетка"] },
        { key = "thick",    label = L["толстая рамка"] },
        { key = "glass",    label = L["стекло"] },
        { key = "bare",     label = L["без рамки"] },
    }, db.style or "frame", function(value)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("style", value) end
        mapStylePicker:Refresh(value)
    end, nil, PV("Sample", "MinimapSkin", "minimap", "style"))

    Note(page, L["Классика WoW - круглая карта с родной рамкой клиента. Круглая с кольцом - кольцо цвета темы и тень. Пиксель - серая рамка в 2 пикселя с чёрной линией. Неон - светящаяся рамка цвета темы. Фото - светлая рамка с широким нижним краем, как у снимка. Виньетка - без рамки, края карты затемнены. Круглые стили не зависят от галочки Квадратная."])

    Check(page, L["Квадратная"], db.square ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("square", val) end
    end)

    Check(page, L["Скрывать название зоны"], db.hideZoneText, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("hideZoneText", val) end
    end)

    Check(page, L["Скрывать часы"], db.hideClock, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("hideClock", val) end
    end)

    Check(page, L["Сохранённые подземелья и рейды в подсказке часов"], NS.db.clockLockouts ~= false, function(val)
        NS.db.clockLockouts = val and true or false
    end)

    Label(page, L["Выбор объекта слежения"])

    local trackingPicker
    trackingPicker = Picker(page, {
        { key = "button", label = L["кнопка"] },
        { key = "click",  label = L["правый клик по миникарте"] },
        { key = "both",   label = L["оба способа"] },
    }, db.tracking or "button", function(value)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("tracking", value) end
        trackingPicker:Refresh(value)
    end)

    Note(page, L["С правым кликом кнопку-лупу у миникарты можно убрать: меню слежения откроется под курсором. Shift + правый клик и средняя кнопка работают как раньше. Работает и без стиля миникарты аддона."])

    Check(page, L["Координаты на миникарте"], db.infoCoords ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoCoords", val) end
    end)

    local MS = NS.MinimapSkin
    if MS and MS.COORD_STYLES then
        Label(page, L["Стиль координат"])
        local coordStyleOptions = {}
        for _, key in ipairs(MS.COORD_STYLES) do
            coordStyleOptions[#coordStyleOptions + 1] = { key = key, label = L[MS.COORD_STYLE_LABELS[key]] }
        end
        local coordStylePicker
        coordStylePicker = Picker(page, coordStyleOptions, db.coordStyle or "plate", function(value)
            coordStylePicker:Refresh(value)
            MS:SetOption("coordStyle", value)
        end, nil, PV("Sample", "MinimapSkin", "minimap", "coordStyle"))

        Label(page, L["Вид координат"])
        local coordFormatPicker
        coordFormatPicker = Picker(page, {
            { key = "xy", label = "X 46.5  Y 35.1" },
            { key = "comma", label = "46.5, 35.1" },
            { key = "brackets", label = "[ 46.5 , 35.1 ]" },
            { key = "spaced", label = "46.5  35.1" },
        }, db.coordFormat or "xy", function(value)
            coordFormatPicker:Refresh(value)
            MS:SetOption("coordFormat", value)
        end, nil, PV("Sample", "MinimapSkin", "minimap", "coordFormat"))

        Label(page, L["Где координаты"])
        local coordPosPicker
        coordPosPicker = Picker(page, {
            { key = "bottom", label = L["внизу, над часами"] },
            { key = "top", label = L["вверху, под зоной"] },
            { key = "edge", label = L["на нижнем краю"] },
            { key = "free", label = L["где угодно"] },
        }, db.coordPos or "bottom", function(value)
            coordPosPicker:Refresh(value)
            if value == "free" and not (db.coordFree and db.coordFree.point) then
                local pill = MS.coordPill
                if pill and pill:GetCenter() then
                    local x, y = pill:GetCenter()
                    local k = pill:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    db.coordFree = { point = "CENTER", relativePoint = "BOTTOMLEFT", x = x * k / pill:GetScale(), y = y * k / pill:GetScale() }
                end
            end
            MS:SetOption("coordPos", value)
        end, nil, PV("Sample", "MinimapSkin", "minimap", "coordPos"))
        Note(page, L["Где угодно - координаты больше не привязаны к миникарте: перетащите их в режиме расстановки интерфейса, и они останутся там. Перетаскивание из любого положения само переключает на этот вариант. Координаты работают и без стиля миникарты аддона."])

        Slider(page, L["Размер координат"], 50, 250, 5, db.coordScale or 100, function(val)
            MS:SetOption("coordScale", val)
        end, "%")

        Buttons(page, {
            { label = L["Переместить"], width = 140, action = function()
                if NS.Movers then NS.Movers:Toggle() end
            end },
            { label = L["Вернуть к миникарте"], width = 180, action = function()
                db.coordFree = nil
                MS:SetOption("coordPos", "bottom")
                coordPosPicker:Refresh("bottom")
            end },
        })
    end

    Label(page, L["Панель под миникартой"])

    Check(page, L["Показывать панель"], db.infoPanel ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoPanel", val) end
    end)

    Check(page, L["Кадры в секунду"], db.infoFps ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoFps", val) end
    end)

    Check(page, L["Пинг"], db.infoPing ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoPing", val) end
    end)

    Check(page, L["Друзья в сети"], db.infoFriends ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoFriends", val) end
    end)

    Check(page, L["Гильдия в сети"], db.infoGuild ~= false, function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("infoGuild", val) end
    end)

    Label(page, L["Кнопки"])

    Buttons(page, {
        { label = L["Настроить кнопки аддонов"], width = 220, action = function() Settings:Select("minibag") end },
    })

    Slider(page, L["Масштаб"], 50, 200, 5, math.floor((db.scale or 1) * 100), function(val)
        if NS.MinimapSkin then NS.MinimapSkin:SetOption("scale", val / 100) end
    end, "%")

    Label(page, L["Поведение"])

    Slider(page, L["Отдалять карту обратно через, сек (0 - не отдалять)"], 0, 60, 5, db.autoZoom or 0, function(val)
        if NS.db.minimap then NS.db.minimap.autoZoom = val end
    end)

    Slider(page, L["Прозрачность миникарты"], 20, 100, 5, db.mapAlpha or 100, function(val)
        if NS.db.minimap then NS.db.minimap.mapAlpha = val end
    end, "%")

    Slider(page, L["Прозрачность миникарты в бою"], 0, 100, 5, db.combatAlpha or 100, function(val)
        if NS.db.minimap then NS.db.minimap.combatAlpha = val end
    end, "%")

    Note(page, L["Под курсором миникарта всегда становится плотной. Работает и без стиля миникарты аддона."])

    Label(page, L["Положение"])

    Buttons(page, {
        { label = L["Переместить"], action = function()
            if NS.MinimapSkin then NS.MinimapSkin:Move() end
        end },
        { label = L["Сбросить"], action = function()
            if NS.MinimapSkin then NS.MinimapSkin:ResetPosition() end
        end },
    })
end

local function BuildChat(page)
    local db = NS.db.chat or {}

    Section(page, L["Чат"])

    Check(page, L["Включить"], db.enabled, function()
        if NS.ChatSkin then NS.ChatSkin:Toggle() end
    end)

    Check(page, L["Скрывать кнопки чата"], db.hideButtons ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("hideButtons", val) end
    end)

    Check(page, L["Полоса прокрутки чата"], db.scrollBar ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("scrollBar", val) end
    end)

    Slider(page, L["Размер шрифта"], 9, 20, 1, db.fontSize or 12, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("fontSize", val) end
    end)

    Check(page, L["Подложка под чатом"], db.panel ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("panel", val) end
    end)

    Label(page, L["Стиль чата"])

    local chatStylePicker
    chatStylePicker = Picker(page, {
        { key = "panel",    label = L["панель"] },
        { key = "gradient", label = L["градиент"] },
        { key = "card",     label = L["карточка"] },
        { key = "side",     label = L["полоса сбоку"] },
        { key = "glass",    label = L["стекло"] },
        { key = "tooltip",  label = L["подсказка WoW"] },
        { key = "dialog",   label = L["окно WoW"] },
        { key = "pixel",    label = L["пиксель"] },
        { key = "terminal", label = L["терминал"] },
        { key = "bare",     label = L["без фона"] },
    }, db.style or "panel", function(value)
        if NS.ChatSkin then NS.ChatSkin:SetOption("style", value) end
        chatStylePicker:Refresh(value)
    end, nil, PV("Sample", "ChatSkin", "chat", "style"))

    Note(page, L["Панель - рамка с полосой вкладок. Градиент - без рамки, фон тает кверху. Карточка - рамка с тенью, полоса цвета темы сверху, активная вкладка залита. Полоса сбоку - фон тает вправо, слева светящаяся полоса. Стекло - прозрачный фон с бликом и рамкой цвета темы."])
    Note(page, L["Подсказка WoW и окно WoW - рамки самого клиента. Пиксель - плоский серый фон с чёрной рамкой в 1 пиксель. Терминал - чёрный фон, зелёная рамка и строки развёртки. Без фона - только текст и вкладки."])

    Label(page, L["Шрифт"])

    local fontOptions = {
        { key = "default", label = L["стандартный"] },
        { key = "narrow",  label = L["узкий"] },
        { key = "pt",      label = "PT Sans Narrow" },
    }

    local fontPicker
    fontPicker = Picker(page, fontOptions, db.font or "default", function(value)
        if NS.ChatSkin then NS.ChatSkin:SetOption("font", value) end
        fontPicker:Refresh(value)
    end, nil, PV("Sample", "ChatSkin", "chat", "font"))

    Check(page, L["Обводка букв"], db.outline, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("outline", val) end
    end)

    Note(page, L["Шрифт и обводка работают при включённом чате в стиле аддона."])

    Label(page, L["Сообщения"])

    Check(page, L["Имена цветом класса"], db.classNames, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("classNames", val) end
    end)

    Check(page, L["Короткие названия каналов: [4] вместо [4. Мир]"], db.shortChannels, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("shortChannels", val) end
    end)

    Check(page, L["Ссылки в чате можно копировать кликом"], db.links ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("links", val) end
    end)

    Label(page, L["Подсказки при наведении"])

    Check(page, L["Предметы, заклинания и достижения"], db.hoverItems ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("hoverItems", val) end
    end)

    Check(page, L["Ссылки на группы из поиска групп (ЗСГ)"], db.hoverGroups ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("hoverGroups", val) end
    end)

    local stampPicker
    stampPicker = Picker(page, {
        { key = "none",       label = L["без времени"] },
        { key = "%H:%M ",     label = "12:34" },
        { key = "%H:%M:%S ",  label = "12:34:56" },
        { key = "[%H:%M] ",   label = "[12:34]" },
    }, db.timestamps or GetCVar("showTimestamps") or "none", function(value)
        if NS.ChatSkin then NS.ChatSkin:SetOption("timestamps", value) end
        stampPicker:Refresh(value)
    end, nil, PV("Sample", "ChatSkin", "chat", "timestamps"))

    Check(page, L["Сообщения тают со временем"], db.fade ~= false, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("fade", val) end
    end)

    Slider(page, L["Через сколько секунд таять"], 10, 600, 10, db.fadeTime or 120, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("fadeTime", val) end
    end)

    Check(page, L["Вкладки только при наведении"], db.hideTabs, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("hideTabs", val) end
    end)

    Label(page, L["Вид"])

    Slider(page, L["Плотность подложки"], 0, 100, 5, db.panelAlpha or 60, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetOption("panelAlpha", val) end
    end, "%")

    Label(page, L["Строка ввода"])

    local inputPicker
    inputPicker = Picker(page, {
        { key = "top",    label = L["над чатом"] },
        { key = "bottom", label = L["под чатом"] },
        { key = "free",   label = L["свободно"] },
    }, db.editPos or "top", function(value)
        if NS.ChatSkin then NS.ChatSkin:SetOption("editPos", value) end
        inputPicker:Refresh(value)
    end)

    Label(page, L["Размер окна чата"])

    local chat = _G.ChatFrame1
    Slider(page, L["Ширина"], 200, 900, 10, chat and math.floor(chat:GetWidth() + 0.5) or 430, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetChatSize(val, nil) end
    end)

    Slider(page, L["Высота"], 60, 600, 10, chat and math.floor(chat:GetHeight() + 0.5) or 120, function(val)
        if NS.ChatSkin then NS.ChatSkin:SetChatSize(nil, val) end
    end)

    Buttons(page, {
        { label = L["Двигать чат и ввод"], action = function()
            if NS.ChatSkin then NS.ChatSkin:Move() end
        end, width = 190 },
        { label = L["Чат на стандартное место"], action = function()
            if NS.ChatSkin then NS.ChatSkin:ResetPosition() end
        end, width = 210 },
    })
end

local function BuildDialogue(page)
    local db = NS.db.dialogue or {}

    local function Set(field, value)
        if NS.db.dialogue then NS.db.dialogue[field] = value end
    end

    Section(page, L["Диалоги"])

    Note(page, L["Разговор с НПС на весь экран: мир затемняется, справа персонаж, слева текст, снизу ответы. Взятие и сдача заданий работают как в окне клиента."])

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        Set("enabled", val)
    end)

    Check(page, L["Прятать интерфейс во время диалога"], db.hideInterface ~= false, function(val)
        Set("hideInterface", val)
    end)

    Check(page, L["Текст проявляется постепенно"], db.typewriter ~= false, function(val)
        Set("typewriter", val)
    end)

    Check(page, L["Ответы клавишами 1-9, пробел - дальше"], db.keys ~= false, function(val)
        Set("keys", val)
    end)

    Slider(page, L["Затемнение мира"], 0, 100, 5, db.dim or 75, function(val)
        Set("dim", val)
        if NS.Dialogue then NS.Dialogue:ApplyDim() end
    end, "%")

    local function Look(field, value)
        Set(field, value)
        if NS.Dialogue and NS.Dialogue.ApplyLook then NS.Dialogue:ApplyLook() end
    end

    Section(page, L["Стиль"])
    local Dlg = NS.Dialogue
    if Dlg and Dlg.STYLE_ORDER then
        local dlgStyles = {}
        for _, key in ipairs(Dlg.STYLE_ORDER) do
            dlgStyles[#dlgStyles + 1] = { key = key, label = L[Dlg.STYLE_LABELS[key]] }
        end
        local dlgPicker
        dlgPicker = Picker(page, dlgStyles, db.style or "narci", function(value)
            dlgPicker:Refresh(value)
            Look("style", value)
        end, nil, PV("Dialogue"))
    end
    Slider(page, L["Плотность подложки"], 30, 100, 2, db.cardAlpha or 92, function(val) Look("cardAlpha", val) end, "%")
    Note(page, L["NarciUI - текст прямо поверх мира, как раньше. Остальные стили кладут под текст подложку и оформляют кнопки ответов: Свиток - пергамент с сургучной печатью, Ночное небо и Рассвет - картинки, Аркана - вращающийся рунный круг."])

    Section(page, L["Текст"])

    Slider(page, L["Размер текста"], 12, 24, 1, db.bodySize or 17, function(val) Look("bodySize", val) end)
    Slider(page, L["Размер имени"], 18, 40, 1, db.nameSize or 28, function(val) Look("nameSize", val) end)
    Slider(page, L["Скорость проявления текста"], 25, 400, 25, db.revealSpeed or 100, function(val) Set("revealSpeed", val) end, "%")

    Label(page, L["Цвет текста"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "white",     label = L["белый"] },
        { key = "parchment", label = L["пергамент"] },
        { key = "silver",    label = L["серебро"] },
        { key = "theme",     label = L["цвет темы"] },
    }, db.textColor or "white", function(value)
        colorPicker:Refresh(value)
        Look("textColor", value)
    end, nil, PV("With", "dialogue", "textColor", PV("Dialogue")))

    Section(page, L["Собеседник"])

    Check(page, L["Показывать модель собеседника"], db.showModel ~= false, function(val) Look("showModel", val) end)
    Check(page, L["Подсветка за моделью"], db.modelLight ~= false, function(val) Look("modelLight", val) end)
end

local function BuildAuction(page)
    local auc = NS.Auc
    local db = auc and auc.db or {}

    Section(page, L["Аукцион"])

    Note(page, L["История цен с аукциона (бывший AucBourse): строки в подсказке предмета и окно с графиком у аукциона."])

    if auc and auc.standalone then
        Note(page, L["Сейчас включён отдельный AucBourse. Отключите его в списке модификаций и перезапустите клиент."])
    end

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        db.enabled = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["История в подсказке предмета"], db.tooltip ~= false, function(val)
        db.tooltip = val
    end)

    Check(page, L["Окно с графиком у аукциона"], db.window ~= false, function(val)
        db.window = val
        if auc and auc.Window then
            if val then auc.Window:Show() else auc.Window:Hide() end
        end
    end)

    Check(page, L["Автоскан при открытии аукциона"], db.autoScan ~= false, function(val)
        db.autoScan = val
    end)

    Slider(page, L["Автоскан не чаще, минут"], 5, 120, 5, db.autoScanInterval or 30, function(val)
        db.autoScanInterval = val
    end)

    Slider(page, L["Хранить сканов"], 2, 30, 1, db.keep or 10, function(val)
        if val ~= db.keep and auc and auc.History and auc.initialized then
            auc.History:Resize(val)
        end
        db.keep = val
    end)

    Slider(page, L["Забывать предмет через, дней"], 1, 365, 1, db.pruneDays or 30, function(val)
        db.pruneDays = val
    end)

    Buttons(page, {
        { label = L["Скан сейчас"], action = function()
            if auc and auc.initialized and auc.Scanner then auc.Scanner:Start() end
        end, width = 150 },
    })
end

local function BuildTooltip(page)
    local db = NS.db.tooltip or {}

    Section(page, L["Подсказки"])

    Check(page, L["Включить"], db.enabled, function()
        if NS.TooltipSkin then NS.TooltipSkin:Toggle() end
    end)

    Check(page, L["Рамка и украшения в цвете класса, отношения или качества предмета"], db.unitBorder ~= false, function(val)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption("unitBorder", val) end
    end)

    Check(page, L["Рамка по качеству предмета"], db.colorByQuality ~= false, function(val)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption("colorByQuality", val) end
    end)

    local styledLook = NS.Styling.DECOR

    Label(page, L["Стиль подсказок"] .. " - " .. L["обычный вид"] .. (styledLook and "" or (" (" .. L["сейчас"] .. ")")))

    local tipStylePicker
    tipStylePicker = Picker(page, {
        { key = "modern",  label = L["современный"] },
        { key = "classic", label = L["классика WoW"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "glass",   label = L["стекло"] },
        { key = "minimal", label = L["полоса сбоку"] },
        { key = "neon",    label = L["неон"] },
        { key = "stripe",  label = L["полоса и рамка"] },
        { key = "card",    label = L["карточка"] },
        { key = "gradient", label = L["градиент"] },
        { key = "flat",    label = L["плоский"] },
        { key = "double",  label = L["двойная рамка"] },
        { key = "soft",    label = L["мягкий"] },
    }, db.style or "modern", function(value)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption("style", value) end
        tipStylePicker:Refresh(value)
    end, nil, PV("Sample", "TooltipSkin", "tooltip", "style", { field = "style" }))

    Label(page, L["Стиль подсказок"] .. " - " .. L["стилизованный вид"] .. (styledLook and (" (" .. L["сейчас"] .. ")") or ""))

    local styledPicker
    styledPicker = Picker(page, {
        { key = "ornate", label = L["орнамент"] },
        { key = "royal",  label = L["королевский"] },
        { key = "runic",  label = L["руны"] },
        { key = "arcane", label = L["тайный"] },
        { key = "banner", label = L["знамя"] },
        { key = "grove",  label = L["роща"] },
    }, db.styledStyle or "ornate", function(value)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption("styledStyle", value) end
        styledPicker:Refresh(value)
    end, nil, PV("Sample", "TooltipSkin", "tooltip", "styledStyle", { field = "styledStyle" }))

    Note(page, L["Какой из двух наборов действует, решает вид окон на странице «Стиль». Стилизованные стили берут углы, герб и узоры из «Деталей стиля» и их цвет."])

    Note(page, L["Классика WoW - родная рамка подсказок клиента, цвет рамки по качеству. Пиксель - плоский серый фон и рамка в 1 пиксель. Стекло - полупрозрачный фон с бликом. Полоса сбоку - чёрный фон без рамки, цветная полоса слева."])

    local function Set(field, value)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption(field, value) end
    end

    Slider(page, L["Масштаб подсказок"], 70, 150, 5, math.floor((db.scale or 1) * 100 + 0.5), function(val)
        Set("scale", val / 100)
    end, "%")

    Check(page, L["Прятать подсказки персонажей и НИП в бою"], db.hideInCombat, function(val)
        Set("hideInCombat", val)
    end)

    Label(page, L["Персонажи и НИП"])

    Check(page, L["Полоса здоровья под подсказкой"], db.healthBar ~= false, function(val)
        Set("healthBar", val)
    end)

    Label(page, L["Текст на полосе здоровья"])
    local healthPicker
    healthPicker = Picker(page, {
        { key = "none",    label = L["нет"] },
        { key = "percent", label = L["проценты"] },
        { key = "value",   label = L["значение"] },
        { key = "both",    label = L["значение и проценты"] },
    }, (NS.db.tooltip or {}).healthText or "none", function(value)
        healthPicker:Refresh(value)
        if NS.db.tooltip then NS.db.tooltip.healthText = value end
        if NS.TooltipSkin and NS.TooltipSkin.ApplyHealthBar then NS.TooltipSkin:ApplyHealthBar() end
    end, nil, PV("Sample", "TooltipSkin", "tooltip", "healthText"))

    Slider(page, L["Высота полосы здоровья"], 2, 16, 1, (NS.db.tooltip or {}).healthHeight or 5, function(val)
        if NS.db.tooltip then NS.db.tooltip.healthHeight = val end
        if NS.TooltipSkin and NS.TooltipSkin.ApplyHealthBar then NS.TooltipSkin:ApplyHealthBar() end
    end)

    Check(page, L["ID НИП"], (NS.db.tooltip or {}).showNpcID, function(val)
        if NS.db.tooltip then NS.db.tooltip.showNpcID = val end
    end)

    Check(page, L["Строка «Цель: ...»"], db.showTarget ~= false, function(val)
        Set("showTarget", val)
    end)

    Check(page, L["Звание в гильдии"], db.guildRank ~= false, function(val)
        Set("guildRank", val)
    end)

    Label(page, L["Предметы"])

    Check(page, L["Уровень предмета"], db.showItemLevel ~= false, function(val)
        Set("showItemLevel", val)
    end)

    Check(page, L["ID предмета"], db.showItemID, function(val)
        Set("showItemID", val)
    end)

    Check(page, L["Цена у торговца"], db.sellPrice, function(val)
        Set("sellPrice", val)
    end)

    Label(page, L["Сравнение с надетым"])

    local compare = NS.db.compare
    if type(compare) ~= "table" then
        compare = {}
        NS.db.compare = compare
    end
    Check(page, L["Только с зажатым Shift"], compare.shift, function(val) compare.shift = val and true or false end)
    Check(page, L["Сравнивать с обоими кольцами, аксессуарами и оружием"], compare.both, function(val) compare.both = val and true or false end)
    Check(page, L["Строка про чары"], compare.enchants ~= false, function(val) compare.enchants = val and true or false end)
    Check(page, L["Строка про пустые разъёмы"], compare.sockets ~= false, function(val) compare.sockets = val and true or false end)
    Check(page, L["Названия характеристик без цвета"], compare.plainNames, function(val) compare.plainNames = val and true or false end)
    Note(page, L["Сравнение включается на странице «Части аддона»."])

    Label(page, L["Заклинания и ауры"])

    Check(page, L["ID заклинаний и аур"], db.showSpellID, function(val)
        Set("showSpellID", val)
    end)

    Check(page, L["Кто наложил бафф или дебафф"], db.auraCaster ~= false, function(val)
        Set("auraCaster", val)
    end)

    Label(page, L["Положение"])

    Check(page, L["Подсказка у курсора"], db.cursorAnchor, function(val)
        if NS.TooltipSkin then NS.TooltipSkin:SetOption("cursorAnchor", val) end
    end)
end

local function BuildDataTexts(page)
    local db = NS.db.dataTexts or {}
    local blocks = db.blocks or {}

    local function Set(field, value)
        if NS.DataTexts then NS.DataTexts:SetOption(field, value) end
    end

    Section(page, L["Панель показателей"])

    Check(page, L["Включить"], db.enabled, function()
        if NS.DataTexts then NS.DataTexts:Toggle() end
    end)

    Label(page, L["Что показывать"])

    for _, entry in ipairs(NS.DataTexts and NS.DataTexts.BLOCKS or {}) do
        Check(page, L[entry.label], blocks[entry.key] ~= false, function(val)
            if NS.DataTexts then NS.DataTexts:SetBlock(entry.key, val) end
        end)
    end

    Label(page, L["Вид"])

    Check(page, L["Подписи у значений"], db.labels ~= false, function(val)
        Set("labels", val)
    end)

    Check(page, L["Подложка"], db.panel ~= false, function(val)
        Set("panel", val)
    end)

    Label(page, L["Стиль панели"])

    local dataStylePicker
    dataStylePicker = Picker(page, {
        { key = "panel", label = L["панель"] },
        { key = "pills", label = L["капсулы"] },
        { key = "pixel", label = L["пиксель"] },
        { key = "fade",  label = L["тающий фон"] },
        { key = "glass", label = L["стекло"] },
        { key = "neon",  label = L["неон"] },
        { key = "dark",  label = L["тёмная полоса"] },
        { key = "underline", label = L["подчёркивание"] },
    }, db.style or "panel", function(value)
        Set("style", value)
        dataStylePicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "style"))

    Note(page, L["Капсулы - каждый показатель на своей плашке. Тающий фон - фон без рамки, плавно исчезает к краям. Работает, когда включена подложка."])

    Check(page, L["Растянуть по нижнему краю экрана"], db.fullWidth, function(val)
        Set("fullWidth", val)
    end)

    Label(page, L["Цвет значений"])

    local colorPicker
    colorPicker = Picker(page, {
        { key = "white",  label = L["белый"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
        { key = "gold",   label = L["золотой"] },
        { key = "narci",  label = L["цвета NarciUI"] },
    }, db.valueColor or "white", function(value)
        Set("valueColor", value)
        colorPicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "valueColor"))

    Slider(page, L["Размер шрифта"], 8, 16, 1, db.fontSize or 11, function(val)
        Set("fontSize", val)
    end)

    Slider(page, L["Высота"], 16, 40, 2, db.height or 22, function(val)
        Set("height", val)
    end)

    Label(page, L["Значения"])

    Check(page, L["Местное время вместо серверного"], db.localTime, function(val)
        Set("localTime", val)
    end)

    Check(page, L["Подсвечивать проблемы: прочность ниже 30%, мало места в сумках, низкий fps или высокий пинг"], db.warn, function(val)
        if NS.DataTexts then NS.DataTexts:SetOption("warn", val) end
    end)

    Label(page, L["Цвет подписей"])
    local labelPicker
    labelPicker = Picker(page, {
        { key = "dim",    label = L["приглушённый"] },
        { key = "white",  label = L["белый"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
        { key = "gold",   label = L["золотой"] },
    }, db.labelColor or "dim", function(value)
        labelPicker:Refresh(value)
        if NS.DataTexts then NS.DataTexts:SetOption("labelColor", value) end
    end, nil, PV("Sample", "DataTexts", "dataTexts", "labelColor"))

    Check(page, L["Разделители между блоками"], db.dividers ~= false, function(val)
        if NS.DataTexts then NS.DataTexts:SetOption("dividers", val) end
    end)

    Slider(page, L["Отступы внутри блоков"], 10, 60, 1, db.blockPad or 25, function(val)
        if NS.DataTexts then NS.DataTexts:SetOption("blockPad", val) end
    end)

    Slider(page, L["Плотность подложки"], 0, 100, 5, db.bgAlpha or 100, function(val)
        if NS.DataTexts then NS.DataTexts:SetOption("bgAlpha", val) end
    end, "%")

    Label(page, L["Как показывать золото"])
    local moneyStylePicker
    moneyStylePicker = Picker(page, {
        { key = "text", label = L["текстом (27488з 34с 67м)"] },
        { key = "coins", label = L["монетами"] },
        { key = "colored", label = L["цветными числами"] },
    }, db.moneyStyle or "text", function(value)
        Set("moneyStyle", value)
        moneyStylePicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "moneyStyle", { focus = "money" }))

    Check(page, L["Только золото, без серебра и меди"], db.goldOnly, function(val)
        Set("goldOnly", val)
    end)

    Check(page, L["Разделять тысячи в золоте (25 235)"], db.goldSep, function(val)
        Set("goldSep", val and true or nil)
    end)

    Check(page, L["Двоеточие после подписи"], db.labelColon, function(val)
        Set("labelColon", val and true or nil)
    end)

    Label(page, L["Прочность"])
    local durPicker
    durPicker = Picker(page, {
        { key = "worst",   label = L["худшая вещь"] },
        { key = "average", label = L["средняя"] },
    }, db.durMode or "worst", function(value)
        Set("durMode", value)
        durPicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "durMode", { focus = "durability" }))

    Label(page, L["Сумки"])
    local bagsPicker
    bagsPicker = Picker(page, {
        { key = "freetotal", label = L["свободно / всего"] },
        { key = "free",      label = L["только свободно"] },
        { key = "used",      label = L["занято / всего"] },
    }, db.bagsMode or "freetotal", function(value)
        Set("bagsMode", value)
        bagsPicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "bagsMode", { focus = "bags" }))

    Label(page, L["Скорость"])
    local speedPicker
    speedPicker = Picker(page, {
        { key = "both", label = L["fps и пинг"] },
        { key = "fps",  label = L["только fps"] },
        { key = "ping", label = L["только пинг"] },
    }, db.speedMode or "both", function(value)
        Set("speedMode", value)
        speedPicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "speedMode", { focus = "speed" }))

    Label(page, L["Знаков в координатах"])
    local coordPicker
    coordPicker = Picker(page, {
        { key = 0, label = "56  42" },
        { key = 1, label = "56.6  42.1" },
        { key = 2, label = "56.63  42.18" },
    }, db.coordDigits or 1, function(value)
        Set("coordDigits", value)
        coordPicker:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "coordDigits", { focus = "coords" }))

    Label(page, L["Вид координат"])
    local dtCoordFormat
    dtCoordFormat = Picker(page, {
        { key = "xy", label = "X 46.5  Y 35.1" },
        { key = "comma", label = "46.5, 35.1" },
        { key = "brackets", label = "[ 46.5 , 35.1 ]" },
        { key = "spaced", label = "46.5  35.1" },
    }, db.coordFormat or "xy", function(value)
        Set("coordFormat", value)
        dtCoordFormat:Refresh(value)
    end, nil, PV("Sample", "DataTexts", "dataTexts", "coordFormat", { focus = "coords" }))

    Check(page, L["12-часовой формат времени"], db.clock12, function(val)
        Set("clock12", val and true or nil)
    end)

    Check(page, L["Секунды (для местного времени)"], db.clockSeconds, function(val)
        Set("clockSeconds", val and true or nil)
    end)

    Section(page, L["Порядок блоков"])

    local orderLabel = Label(page, "")
    local function OrderText()
        local names = {}
        for _, block in ipairs(NS.DataTexts and NS.DataTexts:Order() or {}) do
            names[#names + 1] = L[block.label]
        end
        orderLabel:SetText(table.concat(names, "  -  "))
    end
    OrderText()

    local selected = (NS.DataTexts and NS.DataTexts.BLOCKS[1] or {}).key
    local blockOptions = {}
    for _, entry in ipairs(NS.DataTexts and NS.DataTexts.BLOCKS or {}) do
        blockOptions[#blockOptions + 1] = { key = entry.key, label = L[entry.label] }
    end
    local blockPicker
    blockPicker = Picker(page, blockOptions, selected, function(value)
        selected = value
        blockPicker:Refresh(value)
    end)

    Buttons(page, {
        { label = L["Левее"], action = function()
            if NS.DataTexts and selected then NS.DataTexts:Shift(selected, -1) end
            OrderText()
        end },
        { label = L["Правее"], action = function()
            if NS.DataTexts and selected then NS.DataTexts:Shift(selected, 1) end
            OrderText()
        end },
        { label = L["Как было"], action = function()
            if NS.db.dataTexts then NS.db.dataTexts.order = nil end
            if NS.DataTexts then NS.DataTexts:Relayout() end
            OrderText()
        end },
    })

    Section(page, L["Поведение панели показателей"])

    Slider(page, L["Прозрачность панели"], 20, 100, 5, db.alpha or 100, function(val)
        Set("alpha", val)
    end, "%")

    Check(page, L["Показывать только при наведении"], db.mouseover, function(val)
        Set("mouseover", val and true or nil)
    end)

    Slider(page, L["Видимость, пока не наведена"], 0, 60, 5, db.restAlpha or 0, function(val)
        Set("restAlpha", val)
    end, "%")

    Check(page, L["Прятать в бою"], db.combatHide, function(val)
        Set("combatHide", val and true or nil)
    end)

    Check(page, L["Клики по блокам открывают окна"], db.clicks, function(val)
        Set("clicks", val and true or nil)
    end)
    Note(page, L["Прочность - персонаж, сумки и золото - сумки, координаты - карта, время - часы и будильник."])

    Buttons(page, {
        { label = L["Расставить"], action = function()
            if NS.Movers then NS.Movers:Toggle("data") end
        end },
    })
end

local READY_HUD = {
    playerUI = { enabled = true },
    actionBars = { enabled = true },
    castBar = { enabled = true },
    auras = { enabled = true },
    minimap = { enabled = true, collect = true },
    chat = { enabled = true },
    tooltip = { enabled = true },
    dataTexts = { enabled = true },
}

local READY_PROFILES = {
    {
        key = "obsidian", name = "NarciUI - Обсидиан", preset = "obsidian",
        about = "Весь интерфейс аддона в родном виде: тёмные панели, изумрудный цвет, стилизованные окна.",
        values = { accentColor = "emerald", theme = { decor = "styled", bgTone = "obsidian" } },
    },
    {
        key = "minimal", name = "NarciUI - Минимализм", preset = "minimal",
        about = "Тонкие рамки и полосы, ничего лишнего: боковые панели, микро-меню и показатели появляются при наведении, чат гаснет.",
        values = {
            accentColor = "frost",
            theme = { decor = "classic", bgTone = "graphite", shadow = "soft" },
            actionBars = {
                fadeAlpha = 0, fadeSpeed = 200,
                micro = { mouseover = true },
                bars = { bar3 = { mouseover = true }, bar4 = { mouseover = true }, bar5 = { mouseover = true } },
            },
            dataTexts = { mouseover = true, restAlpha = 25, labels = false },
            chat = { fade = true, fadeTime = 30 },
        },
    },
    {
        key = "raid", name = "NarciUI - Рейдер", preset = "glass",
        about = "Для рейдов: стеклянный вид, рамки фокуса и боссов, полоса заклинаний фокуса, измеритель угрозы и откаты в полосе восстановления.",
        values = {
            accentColor = "azure",
            theme = { decor = "styled", bgTone = "midnight" },
            castBar = { units = { focus = { enabled = true } } },
            threat = { enabled = true },
            raidFrames = { enabled = true },
            cooldownBar = { enabled = true, srcSpells = true },
            actionBars = { fadeCombat = true },
        },
    },
    {
        key = "pvp", name = "NarciUI - PvP", preset = "neon",
        about = "Для арены и полей боя: неоновый вид, багровый цвет, полоса заклинаний фокуса, сокращённые клавиши и короткие откаты с цифрами.",
        values = {
            accentColor = "crimson",
            theme = { decor = "classic", bgTone = "coal" },
            castBar = { units = { focus = { enabled = true } }, latency = true },
            actionBars = { cdMin = 2, look = { hotkeyShort = true } },
            cooldownBar = { enabled = true, srcSpells = true },
        },
    },
    {
        key = "classic", name = "NarciUI - Классика", preset = "blizzard",
        about = "Привычный вид WoW: рамки и кнопки клиента в аддоне, тёплый фон, янтарный цвет, обычные окна без узоров.",
        values = { accentColor = "amber", theme = { decor = "classic", bgTone = "warm" } },
    },
    {
        key = "windows", name = "NarciUI - Только окна", hudOff = true,
        about = "Аддон заменяет только окна (персонаж, поиск группы, коллекции и другие), весь интерфейс на экране остаётся стандартным.",
        values = {
            accentColor = "violet",
            raidFrames = { enabled = false }, cooldownBar = { enabled = false }, threat = { enabled = false },
            nameplates = { enabled = false }, bags = { enabled = false },
        },
    },
}

local function ReadyProfileData(entry)
    local data = {}
    local function Merge(into, from)
        for key, value in pairs(from) do
            if type(value) == "table" then
                if type(into[key]) ~= "table" then into[key] = {} end
                Merge(into[key], value)
            else
                into[key] = value
            end
        end
    end
    if not entry.hudOff then Merge(data, READY_HUD) end
    if entry.preset and NS.Look and NS.Look.PresetTable then
        local look = NS.Look:PresetTable(entry.preset)
        if look then Merge(data, look) end
    end
    Merge(data, entry.values or {})
    return data
end

Settings.READY_PROFILES = READY_PROFILES
Settings.ReadyProfileData = ReadyProfileData

local function BuildAutoAccept(page)
    local Auto = NS.AutoAccept
    local db = Auto and Auto.Settings() or {}

    Section(page, L["Приглашения в группу"])
    Check(page, L["Принимать приглашения автоматически"], db.invite, function(val) db.invite = val and true or false end)
    Check(page, L["От друзей"], db.friends, function(val) db.friends = val and true or false end)
    Check(page, L["От согильдийцев"], db.guild, function(val)
        db.guild = val and true or false
        if val and IsInGuild() and GuildRoster then GuildRoster() end
    end)
    Check(page, L["Не принимать, пока стою в очереди"], db.notQueued, function(val) db.notQueued = val and true or false end)
    Note(page, L["Приглашения от остальных игроков показываются как обычно. В очереди на подземелье или поле боя вступление в группу может сбросить очередь, поэтому там лучше решать самому."])

    Section(page, L["Призыв"])
    Check(page, L["Принимать призыв автоматически"], db.summon, function(val) db.summon = val and true or false end)
    Label(page, L["От кого"])
    local fromPicker
    fromPicker = Picker(page, {
        { key = "group", label = L["только из группы"] },
        { key = "known", label = L["из группы, друзья и гильдия"] },
    }, db.summonFrom or "group", function(value)
        db.summonFrom = value
        fromPicker:Refresh(value)
    end)
    Slider(page, L["Задержка перед принятием"], 0, 10, 1, db.summonDelay or 0, function(val) db.summonDelay = val end, L[" с"])
    Note(page, L["Пока идёт задержка, призыв можно отклонить вручную. В бою призыв ждёт конца боя, если время ещё не вышло."])

    Section(page, L["Сообщения"])
    Check(page, L["Писать в чат, что принято автоматически"], db.announce, function(val) db.announce = val and true or false end)
end

local function BuildMiniGame(page)
    local Mode = NS.MiniGameHUD
    if not Mode then return end
    local db = Mode.Settings()

    Section(page, L["«Ботва против мертвяков»"])
    Check(page, L["Прятать интерфейс во время игры"], db.enabled, function(val)
        db.enabled = val and true or false
        if val then Mode:Refresh() elseif Mode.active then Mode:Leave() end
    end)
    Note(page, L["Поле занимает почти весь экран, а рамки и панели поверх него перехватывают клики. На время игры они прячутся и возвращаются сами, когда вы выходите. Панель растений, таймер и кнопка «Готов» остаются. Чат клиент прячет сам."])

    Section(page, L["Что прятать"])
    for _, group in ipairs(Mode.GROUPS) do
        Check(page, L[group.label], db.hide[group.key], function(val)
            db.hide[group.key] = val and true or false
            Mode:Refresh()
        end)
    end
    Note(page, L["Микро-меню и кнопка выхода из транспорта не прячутся никогда. Окна других аддонов (Details, Questie) этот режим не трогает."])
end

local function BuildReadyProfiles(page)
    Section(page, L["Готовые профили"])

    Note(page, L["Каждый готовый профиль создаётся как новый профиль с чистыми настройками и сразу включается. Текущий профиль не меняется: к нему можно вернуться на странице Профили. Положение элементов - по умолчанию, его можно поменять кнопкой Расставить интерфейс."])

    local Profiles = NS.Profiles
    local existing = {}
    for _, name in ipairs(Profiles and Profiles:List() or {}) do existing[name] = true end

    for _, entry in ipairs(READY_PROFILES) do
        local name = L[entry.name]
        Label(page, name .. (existing[name] and ("  |cff909090" .. L["уже создан"] .. "|r") or ""))
        Note(page, L[entry.about])
        if existing[name] then
            Buttons(page, {
                { label = L["Включить"], width = 150, action = function()
                    NS.Widgets.ShowConfirm(L["Переключить профиль? Интерфейс будет перезагружен."], L["Переключить"],
                        function() Profiles:Use(name) end)
                end },
            })
        else
            Buttons(page, {
                { label = L["Создать и включить"], width = 190, action = function()
                    NS.Widgets.ShowConfirm(L["Создать профиль"] .. " " .. name .. "? " .. L["Интерфейс будет перезагружен."], L["Создать"],
                        function() Profiles:CreateFromTemplate(name, ReadyProfileData(entry)) end)
                end },
            })
        end
    end
end

local function BuildProfiles(page)
    Section(page, L["Профили"])

    Note(page, L["Профиль хранит все настройки аддона. У каждого персонажа свой выбор профиля."])

    Label(page, L["Текущий профиль"] .. ": " .. (NS.Profiles and NS.Profiles:Current() or "?"))

    Buttons(page, {
        { label = L["Мастер первоначальной настройки"], width = 260, action = function()
            if NS.Installer then NS.Installer:Show() end
        end },
    })

    local options = {}

    for _, name in ipairs(NS.Profiles and NS.Profiles:List() or {}) do
        options[#options + 1] = { key = name, label = name }
    end

    if #options > 1 then
        Picker(page, options, NS.Profiles:Current(), function(key)
            if key == NS.Profiles:Current() then return end

            NS.Widgets.ShowConfirm(
                L["Переключить профиль? Интерфейс будет перезагружен."],
                L["Переключить"],
                function() NS.Profiles:Use(key) end)
        end)
    end

    local newName = ""
    local nameBox = TextInput(page, L["Название профиля"], "", function(value) newName = value end, 40)
    local function TypedName()
        local text = nameBox and nameBox:GetText() or newName
        return NS.Profiles and NS.Profiles:CleanName(text)
    end

    Buttons(page, {
        { label = L["Создать с этим названием"], width = 220, action = function()
            local name = TypedName()
            if not name then NS.Print(L["Введите название профиля"]) return end
            NS.Profiles:Create(name, NS.Profiles:Current())
        end },
        { label = L["Переименовать текущий"], width = 200, action = function()
            local name = TypedName()
            if not name then NS.Print(L["Введите название профиля"]) return end
            local old = NS.Profiles:Current()
            NS.Widgets.ShowConfirm(
                L["Переименовать профиль"] .. " " .. old .. " -> " .. name .. "? " .. L["Интерфейс будет перезагружен."],
                L["Переименовать"],
                function() NS.Profiles:Rename(old, name) end)
        end },
    })
    Note(page, L["Новый профиль создаётся копией текущего. Общий профиль переименовать нельзя: на него переключаются все персонажи без своего выбора."])

    Buttons(page, {
        { label = L["Создать для персонажа"], action = function()
            if not NS.Profiles then return end

            local name = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
            NS.Profiles:Create(name, NS.Profiles:Current())
        end, width = 200 },
        { label = L["Сбросить профиль"], action = function()
            NS.Widgets.ShowConfirm(
                L["Сбросить все настройки профиля? Интерфейс будет перезагружен."],
                L["Сбросить"],
                function() if NS.Profiles then NS.Profiles:Reset() end end)
        end, width = 180 },
    })

    Buttons(page, {
        { label = L["Удалить профиль"], action = function()
            if not NS.Profiles then return end
            local name = NS.Profiles:Current()

            NS.Widgets.ShowConfirm(
                L["Удалить профиль"] .. " " .. name .. "?",
                L["Удалить"],
                function() NS.Profiles:Delete(name) end)
        end, width = 180 },
    })

    Section(page, L["Экспорт и импорт"])

    Note(page, L["Строка ниже содержит все настройки текущего профиля. Её можно отправить другому игроку или перенести на другой компьютер. Журнал EPGP, гильдейские записи и избранные маунты в неё не попадают."])

    local S = Style()
    local boxW, boxH = PANEL_W - SIDE_W - 80, 96

    local holder = CreateFrame("Frame", nil, page)
    holder:SetSize(boxW, boxH)
    holder:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    holder:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    holder:SetBackdropColor(S.Tint(0.02, 0.02, 0.04, 0.9))
    holder:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local scroll = CreateFrame("ScrollFrame", nil, holder)
    scroll:SetPoint("TOPLEFT", holder, "TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -6, 6)
    scroll:EnableMouseWheel(true)

    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetMaxLetters(0)
    box:SetWidth(boxW - 12)
    box:SetFont(NS.FONT, NS.FS(10), "")
    box:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    scroll:SetScrollChild(box)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, box:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 20)))
    end)

    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        holder:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    end)
    box:SetScript("OnEditFocusLost", function()
        holder:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end)
    box:SetScript("OnCursorChanged", function(self, x, y, w, h)
        local top = -y
        local visible = scroll:GetHeight()
        local offset = scroll:GetVerticalScroll()
        if top < offset then
            scroll:SetVerticalScroll(top)
        elseif top + h > offset + visible then
            scroll:SetVerticalScroll(top + h - visible)
        end
    end)

    holder:EnableMouse(true)
    holder:SetScript("OnMouseDown", function() box:SetFocus() end)

    page.offset = page.offset - boxH - 10

    Buttons(page, {
        { label = L["Экспортировать"], action = function()
            local text = NS.Profiles and NS.Profiles:Export()
            if not text then
                NS.Print(L["не удалось собрать строку профиля"])
                return
            end
            box:SetText(text)
            box:SetFocus()
            box:HighlightText()
            NS.Print(L["строка профиля выделена, скопируйте её: Ctrl+C"])
        end, width = 160 },
        { label = L["Импортировать"], action = function()
            local text = box:GetText()
            if not NS.Profiles or not NS.Profiles:Decode(text) then
                NS.Print(L["строка не распознана: вставьте её целиком, Ctrl+V"])
                return
            end

            NS.Widgets.ShowConfirm(
                L["Заменить настройки профиля"] .. " " .. NS.Profiles:Current() .. "?\n" .. L["Интерфейс будет перезагружен."],
                L["Заменить"],
                function() NS.Profiles:Import(text) end)
        end, width = 160 },
        { label = L["Очистить"], action = function()
            box:SetText("")
            box:ClearFocus()
        end, width = 110 },
    })
end

local function BuildProfileRules(page)
    local P = NS.Profiles
    if not P then return end
    local S = Style()

    local function ProfileOptions(first)
        local options = {}
        if first then options[1] = first end
        for _, name in ipairs(P:List()) do
            options[#options + 1] = { key = name, label = name }
        end
        return options
    end

    local function Ask(name)
        if name == P:Current() then return end
        NS.Widgets.ShowConfirm(
            string.format(L["Сейчас должен действовать профиль «%s». Перезагрузить интерфейс?"], name),
            L["Перезагрузить"],
            function() ReloadUI() end)
    end

    Note(page, L["Какой профиль берёт персонаж: сначала его собственный выбор, если это не общий профиль; иначе профиль его класса; иначе общий. Профиль по специализации предлагает переключиться, когда специализация сменилась."])

    Section(page, L["Этот персонаж"])
    Label(page, P.CharKey() .. ": " .. P:Current())
    Picker(page, ProfileOptions(), P:Own(), function(key)
        if key == P:Own() then return end
        NS.Widgets.ShowConfirm(
            string.format(L["Закрепить за персонажем профиль «%s»? Интерфейс будет перезагружен."], key),
            L["Переключить"],
            function() P:Use(key) end)
    end)
    Note(page, string.format(L["Выбор «%s» означает: следовать профилю класса, если он задан."], P.DEFAULT))

    local _, class = UnitClass("player")
    local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class or "?"
    Section(page, L["По классу"])
    Label(page, string.format(L["Профиль для всех персонажей класса %s"], className))
    local classRules = P:ClassRules()
    local classPicker
    classPicker = Picker(page, ProfileOptions({ key = "none", label = L["нет"] }), class and classRules[class] or "none", function(key)
        if not class then return end
        classRules[class] = key ~= "none" and key or nil
        classPicker:Refresh(key)
        Ask(P:Resolve())
    end)
    local others = {}
    for token, name in pairs(classRules) do
        if token ~= class then
            local label = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
            others[#others + 1] = label .. ": " .. name
        end
    end
    if #others > 0 then
        table.sort(others)
        Note(page, L["Другие классы"] .. ": " .. table.concat(others, ", "))
    end

    Section(page, L["По специализации"])
    local specRules = P:SpecRules()
    local tabs = GetNumTalentTabs and GetNumTalentTabs() or 0
    for tab = 1, tabs do
        local tabName = GetTalentTabInfo(tab)
        Label(page, tabName or (L["Специализация"] .. " " .. tab))
        local picker
        picker = Picker(page, ProfileOptions({ key = "none", label = L["не менять"] }), specRules[tab] or "none", function(key)
            specRules[tab] = key ~= "none" and key or nil
            picker:Refresh(key)
            P.lastSpec = nil
            P:CheckSpec()
        end)
    end

    Section(page, L["Персонажи"])
    local lines = {}
    for _, entry in ipairs(P:Characters()) do
        lines[#lines + 1] = entry.key .. " - " .. entry.profile
    end
    Note(page, #lines > 0 and table.concat(lines, "\n") or L["Пока ни один персонаж не выбрал профиль сам."])
end

local TOOLBAR_TOOLS = {
    { tool = "ToolStats",       label = "Статы" },
    { tool = "ToolEnhance",     label = "Усиления" },
    { tool = "ToolTalents",     label = "Таланты" },
    { tool = "ToolTitles",      label = "Титулы" },
    { tool = "ToolOutfits",     label = "Быстрые наборы" },
    { tool = "ToolReputation",  label = "Репутация" },
    { tool = "ToolCurrency",    label = "Валюта" },
    { tool = "ToolSpells",      label = "Заклинания" },
    { tool = "ToolProfessions", label = "Профессии" },
}

local function BuildToolbarButtons(page)
    local db = NS.db
    if type(db.toolbarHidden) ~= "table" then db.toolbarHidden = {} end
    Section(page, L["Кнопки внизу окна персонажа"])
    Note(page, L["Уберите кнопки вкладок, которыми не пользуетесь. Кнопка настроек остаётся всегда. Применяется после перезагрузки интерфейса."])
    for _, entry in ipairs(TOOLBAR_TOOLS) do
        Check(page, L[entry.label], not db.toolbarHidden[entry.tool], function(val)
            db.toolbarHidden[entry.tool] = (not val) or nil
        end)
    end
    Buttons(page, {
        { label = L["Перезагрузить интерфейс"], width = 220, action = function() ReloadUI() end },
    })

    if type(db.repTab) ~= "table" then db.repTab = {} end
    if type(db.currencyTab) ~= "table" then db.currencyTab = {} end
    local rep, cur = db.repTab, db.currencyTab
    local function RefreshRep() if NS.ReputationPanel and NS.ReputationPanel.frame then NS.ReputationPanel:Update() end end
    local function RefreshCur() if NS.CurrencyPanel and NS.CurrencyPanel.frame then NS.CurrencyPanel:Update() end end

    Section(page, L["Вкладка «Репутация»"])
    Check(page, L["Скрывать фракции на «Превознесении»"], rep.hideExalted, function(val) rep.hideExalted = val and true or nil RefreshRep() end)
    Check(page, L["Скрывать враждебные фракции (ненависть, враждебность)"], rep.hideHated, function(val) rep.hideHated = val and true or nil RefreshRep() end)
    Label(page, L["Число справа от полосы"])
    local repPicker
    repPicker = Picker(page, {
        { key = "value",   label = L["значение"] },
        { key = "percent", label = L["проценты"] },
        { key = "left",    label = L["сколько осталось"] },
        { key = "none",    label = L["ничего"] },
    }, rep.value or "value", function(value)
        repPicker:Refresh(value)
        rep.value = value
        RefreshRep()
    end)

    if type(db.titleTab) ~= "table" then db.titleTab = {} end
    local titles = db.titleTab
    local function RefreshTitles() if NS.TitleManager and NS.TitleManager.frame then NS.TitleManager:Update() end end
    Section(page, L["Вкладка «Титулы»"])
    Label(page, L["Порядок"])
    local titlePicker
    titlePicker = Picker(page, {
        { key = "game",    label = L["как в игре"] },
        { key = "alpha",   label = L["по алфавиту"] },
        { key = "reverse", label = L["новые сверху"] },
    }, titles.sort or "game", function(value)
        titlePicker:Refresh(value)
        titles.sort = value
        RefreshTitles()
    end)
    Check(page, L["Компактные строки"], titles.compact, function(val) titles.compact = val and true or nil RefreshTitles() end)

    if type(db.profTab) ~= "table" then db.profTab = {} end
    local prof = db.profTab
    local function RefreshProf()
        if NS.ProfessionsPanel and NS.ProfessionsPanel.frame and not InCombatLockdown() then NS.ProfessionsPanel:Update() end
    end
    Section(page, L["Вкладка «Профессии»"])
    Check(page, L["Скрывать вторичные (рыбная ловля, кулинария, первая помощь)"], prof.hideSecondary, function(val)
        prof.hideSecondary = val and true or nil
        RefreshProf()
    end)
    Label(page, L["Порядок"])
    local profPicker
    profPicker = Picker(page, {
        { key = "game", label = L["как в игре"] },
        { key = "rank", label = L["по уровню навыка"] },
    }, prof.sort or "game", function(value)
        profPicker:Refresh(value)
        prof.sort = value
        RefreshProf()
    end)

    if type(db.talentTab) ~= "table" then db.talentTab = {} end
    local tal = db.talentTab
    local function RefreshTalents()
        if NS.TalentPanel and NS.TalentPanel.frame and NS.TalentPanel.frame:IsShown() and NS.TalentPanel.Update then
            pcall(NS.TalentPanel.Update, NS.TalentPanel)
        end
    end
    Section(page, L["Вкладка «Таланты»"])
    Label(page, L["Ранг на значке"])
    local rankPicker
    rankPicker = Picker(page, {
        { key = "both",    label = L["вложено / всего"] },
        { key = "current", label = L["только вложено"] },
        { key = "spent",   label = L["только у изученных"] },
        { key = "none",    label = L["не показывать"] },
    }, tal.rank or "both", function(value)
        rankPicker:Refresh(value)
        tal.rank = value
        RefreshTalents()
    end)
    Check(page, L["Обесцвечивать неизученные таланты"], tal.desaturate ~= false, function(val) tal.desaturate = val and true or false RefreshTalents() end)
    Check(page, L["Стрелки требований между талантами"], tal.links ~= false, function(val) tal.links = val and true or false RefreshTalents() end)
    Label(page, L["Цвет полностью изученных"])
    local maxPicker
    maxPicker = Picker(page, {
        { key = "gold",   label = L["золотой"] },
        { key = "accent", label = L["цвет темы"] },
    }, tal.maxColor or "gold", function(value)
        maxPicker:Refresh(value)
        tal.maxColor = value
        RefreshTalents()
    end)

    if type(db.outfitTab) ~= "table" then db.outfitTab = {} end
    local outfit = db.outfitTab
    local function RefreshOutfits()
        if NS.OutfitManager and NS.OutfitManager.frame then NS.OutfitManager:UpdateList() end
    end
    Section(page, L["Вкладка «Быстрые наборы»"])
    Label(page, L["Порядок"])
    local outfitPicker
    outfitPicker = Picker(page, {
        { key = "saved", label = L["как сохранены"] },
        { key = "alpha", label = L["по алфавиту"] },
    }, outfit.sort or "saved", function(value)
        outfitPicker:Refresh(value)
        outfit.sort = value
        RefreshOutfits()
    end)
    Check(page, L["Иконки вещей в строке набора"], outfit.icons ~= false, function(val) outfit.icons = val and true or false RefreshOutfits() end)
    Check(page, L["Спрашивать перед удалением набора"], outfit.confirm, function(val) outfit.confirm = val and true or nil end)

    Section(page, L["Вкладка «Усиления»"])
    Label(page, L["Сколько очков добавляет обычный клик"])
    local stepPicker
    stepPicker = Picker(page, {
        { key = 1, label = "1" },
        { key = 5, label = "5" },
        { key = 10, label = "10" },
        { key = 25, label = "25" },
    }, db.enhanceStep or 1, function(value)
        stepPicker:Refresh(value)
        db.enhanceStep = value
    end)
    Check(page, L["Спрашивать перед сбросом очков"], db.enhanceConfirm, function(val) db.enhanceConfirm = val and true or nil end)

    Section(page, L["Вкладка «Валюта»"])
    Check(page, L["Скрывать валюты, которых нет"], cur.hideZero, function(val) cur.hideZero = val and true or nil RefreshCur() end)
    Check(page, L["Скрывать валюты, помеченные «Не используется»"], cur.hideUnused, function(val) cur.hideUnused = val and true or nil RefreshCur() end)
end

local function BuildAddonWindows(page)
    local Movers = NS.Movers
    if not Movers or not Movers.WindowPrefs then
        Note(page, L["Модуль окон не загружен."])
        return
    end
    local db = Movers:WindowPrefs()

    Section(page, L["Окна аддона"])
    Note(page, L["Большие окна аддона: поиск группы, приключения, общение, гильдия, коллекции, книга заклинаний, журнал заданий. Их можно таскать мышью за свободное место; здесь задаётся масштаб и запоминание положения. В бою окна с защищёнными кнопками не меняются до конца боя."])

    Check(page, L["Запоминать, где окно оставили"], db.remember ~= false, function(val)
        db.remember = val and true or false
    end)

    Slider(page, L["Масштаб всех окон"], 60, 150, 5, db.scale or 100, function(val)
        db.scale = val
        Movers:ApplyAllWindows()
    end, "%")

    Slider(page, L["Плотность списков во всех окнах"], 80, 130, 5, db.density or 100, function(val)
        db.density = val
    end, "%")
    Note(page, L["Меньше 100% - строки ниже и их видно больше, больше 100% - строки просторнее. Размер окна не меняется. Применяется после перезагрузки интерфейса."])

    local function WindowStyleOptions(inherit)
        local list = {}
        if inherit then list[1] = { key = "all", label = L["как у всех"] } end
        for _, key in ipairs(Movers.WINDOW_STYLE_ORDER or {}) do
            list[#list + 1] = { key = key, label = L[Movers.WINDOW_STYLE_LABELS[key]] }
        end
        return list
    end
    if Movers.WINDOW_STYLE_ORDER then
        Label(page, L["Стиль всех окон"])
        local allPicker
        allPicker = Picker(page, WindowStyleOptions(false), db.style or "theme", function(value)
            allPicker:Refresh(value)
            db.style = value
            Movers:ApplyAllWindows()
        end, nil, PV("Window"))
        Note(page, L["Как окна аддона - общий вид со страницы Стиль. Остальные кладут поверх свой фон и рамку: стекло, золото, картинки ночного неба, рассвета и пергамента, рунный круг арканы. Списки и плашки внутри окна остаются своими, картинка видна между ними. У каждого окна ниже можно выбрать свой стиль."])
    end

    Check(page, L["Только одно окно за раз (открытие закрывает остальные)"], db.single, function(val)
        db.single = val and true or false
    end)

    Check(page, L["Не открывать окна друг на друге"], db.arrange ~= false, function(val)
        db.arrange = val and true or false
    end)
    Note(page, L["Если новое окно ложится на уже открытое, оно встаёт рядом с ним - справа, а если не помещается, слева. Когда места нет совсем, окно сдвигается лесенкой. Запомненное место окна при этом не меняется."])

    Check(page, L["Закрывать окна при входе в бой"], db.closeInCombat, function(val)
        db.closeInCombat = val and true or false
    end)

    Buttons(page, {
        { label = L["Вернуть все окна в центр"], width = 220, action = function()
            for _, entry in ipairs(Movers.WINDOWS) do Movers:ResetWindow(entry.name) end
        end },
    })

    for _, entry in ipairs(Movers.WINDOWS) do
        Section(page, L[entry.label])
        if type(db.each[entry.name]) ~= "table" then db.each[entry.name] = {} end
        local store = db.each[entry.name]
        Slider(page, L["Масштаб окна"], 60, 150, 5, store.scale or 100, function(val)
            store.scale = val
            Movers:ApplyAllWindows()
        end, "%")
        Slider(page, L["Плотность фона окна"], 20, 100, 5, store.bg or 100, function(val)
            store.bg = val
            Movers:ApplyAllWindows()
        end, "%")
        if Movers.WINDOW_STYLE_ORDER then
            Label(page, L["Стиль окна"])
            local stylePicker
            stylePicker = Picker(page, WindowStyleOptions(true), store.style or "all", function(value)
                stylePicker:Refresh(value)
                store.style = value
                Movers:ApplyAllWindows()
            end, nil, PV("Window"))
            Slider(page, L["Затемнение картинки"], 0, 80, 5, store.shade or 35, function(val)
                store.shade = val
                Movers:ApplyAllWindows()
            end, "%")
        end
        if entry.density then
            Slider(page, L["Высота строк в списках"], 80, 130, 5, store.density or 100, function(val)
                store.density = val
            end, "%")
        end
        if entry.tabs then
            Label(page, L["Вкладка при открытии"])
            local options = { { key = "last", label = L["последняя"] } }
            for _, tab in ipairs(entry.tabs) do options[#options + 1] = { key = tab.key, label = L[tab.label] } end
            local picker
            picker = Picker(page, options, store.tab or "last", function(value)
                picker:Refresh(value)
                store.tab = value
                Movers:StartState(entry)
            end)
        end
        if entry.filters then
            Label(page, L["Какие показывать при открытии"])
            local options = { { key = "last", label = L["как в прошлый раз"] } }
            for _, filter in ipairs(entry.filters) do options[#options + 1] = { key = filter.key, label = L[filter.label] } end
            local picker
            picker = Picker(page, options, store.filter or "last", function(value)
                picker:Refresh(value)
                store.filter = value
                Movers:StartState(entry)
            end)
        end
        Buttons(page, {
            { label = L["В центр"], width = 120, action = function() Movers:ResetWindow(entry.name) end },
        })
    end
end

local function BuildMailOptions(page)
    local db = NS.db
    Section(page, L["Почта"])
    Note(page, L["Работает, когда почта в стиле аддона включена на странице «Части аддона». Применяется при следующем обновлении списка писем."])
    Check(page, L["Полоса у непрочитанных писем"], db.mailUnreadMark ~= false, function(val) db.mailUnreadMark = val and true or false end)
    Slider(page, L["Затемнение прочитанных писем"], 0, 80, 5, db.mailReadDim or 40, function(val) db.mailReadDim = val end, "%")
    Check(page, L["Рамки вложений цветом качества"], db.mailQuality ~= false, function(val) db.mailQuality = val and true or false end)
end

local function BuildTrainerOptions(page)
    local db = NS.db
    if type(db.trainerFilter) ~= "table" then db.trainerFilter = {} end
    local filters = db.trainerFilter
    Section(page, L["Учителя"])
    Note(page, L["Какие навыки показывать, когда открывается окно учителя. Работает и без стиля аддона. Пока галка не тронута, окно помнит фильтр само, как в клиенте."])
    for _, entry in ipairs({
        { key = "available",   label = "Доступные" },
        { key = "unavailable", label = "Недоступные" },
        { key = "used",        label = "Уже изученные" },
    }) do
        local current = filters[entry.key]
        if current == nil then current = entry.key ~= "used" end
        Check(page, L[entry.label], current, function(val) filters[entry.key] = val and true or false end)
    end
    Slider(page, L["Яркость выделения выбранного навыка"], 5, 60, 1, db.trainerSelect or 22, function(val)
        db.trainerSelect = val
        local highlight = _G.ClassTrainerSkillHighlight
        if highlight and _G.ClassTrainerSkillHighlightFrame and _G.ClassTrainerSkillHighlightFrame.narciSelection then
            highlight:SetAlpha(val / 100)
        end
    end, "%")
end

local function BuildGameMenu(page)
    local db = NS.db

    Section(page, L["Меню Esc"])

    Check(page, L["Меню Esc в стиле аддона"], db.replaceGameMenu ~= false, function(val)
        db.replaceGameMenu = val
    end)

    Label(page, L["Стиль меню Esc"])

    local escPicker
    escPicker = Picker(page, {
        { key = "panel",     label = L["Компактное окно"] },
        { key = "cinematic", label = L["Стилизованное"] },
    }, db.gameMenuStyle == "cinematic" and "cinematic" or "panel", function(value)
        db.gameMenuStyle = value
        escPicker:Refresh(value)
    end, nil, PV("EscMenu"))

    Note(page, L["Стиль применяется при следующем нажатии Esc."])

    Slider(page, L["Размер меню Esc"], 70, 150, 5, db.escScale or 100, function(val)
        db.escScale = val
    end, "%")

    Section(page, L["Стилизованное меню"])

    Label(page, L["Кто стоит на сцене"])
    local modelPicker
    modelPicker = Picker(page, {
        { key = "lichking", label = L["Король-лич"] },
        { key = "player",   label = L["ваш персонаж"] },
        { key = "none",     label = L["никого"] },
    }, db.escModel or "lichking", function(value)
        db.escModel = value
        modelPicker:Refresh(value)
    end, nil, PV("Pose"))

    Slider(page, L["Затемнение мира"], 30, 100, 5, db.escDim or 82, function(val)
        db.escDim = val
    end, "%")

    Check(page, L["Логотип сервера"], db.escLogo ~= false, function(val) db.escLogo = val end)
    Check(page, L["Строка с именем, уровнем и миром"], db.escWho ~= false, function(val) db.escWho = val end)
end

local function BuildGroupWindows(page)
    local db = NS.db
    local skins = NS.GroupSkins

    Section(page, L["Окна группы"])

    Check(page, L["Готовность в подземелье, проверка ролей и ролл добычи в стиле аддона"], db.skinGroup ~= false, function(val)
        db.skinGroup = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Всплывающие окна клиента (смерть, подтверждения) в стиле аддона"], db.skinPopups ~= false, function(val)
        db.skinPopups = val
        NS.Print(L["Нужен /reload"])
    end)

    Slider(page, L["Непрозрачность панелей"], 50, 100, 1, db.groupPanelAlpha or 97, function(val)
        db.groupPanelAlpha = val
        if skins then skins:ApplyPanelAlpha() end
    end, "%")

    Label(page, L["Стиль окон"])

    local groupStylePicker
    groupStylePicker = Picker(page, {
        { key = "modern",  label = L["современный"] },
        { key = "classic", label = L["окно WoW"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "glass",   label = L["стекло"] },
    }, db.groupStyle or "modern", function(value)
        db.groupStyle = value
        groupStylePicker:Refresh(value)
        if skins then skins:ApplyPanelAlpha() end
    end, nil, PV("Sample", "GroupSkins", "", "groupStyle"))

    Label(page, L["Ролл добычи"])

    local rollPicker
    rollPicker = Picker(page, {
        { key = "window", label = L["окна"] },
        { key = "list",   label = L["компактный список"] },
    }, db.rollStyle == "list" and "list" or "window", function(value)
        db.rollStyle = value
        rollPicker:Refresh(value)
    end)
    Note(page, L["Окна - каждый предмет в отдельном окне, как в клиенте. Компактный список - все предметы строками в одном месте. Вид списка, ширина, масштаб списка и полоска таймера ниже относятся только к списку; выбор вида списка сам включает список. Новый режим действует для следующих роллов."])

    Label(page, L["Вид списка"])

    local lookPicker
    lookPicker = Picker(page, {
        { key = "rows",    label = L["строки"] },
        { key = "cards",   label = L["карточки"] },
        { key = "minimal", label = L["минимал"] },
        { key = "fill",    label = L["заливка"] },
        { key = "tiles",   label = L["плитки"] },
    }, db.rollLook or "rows", function(value)
        db.rollLook = value
        lookPicker:Refresh(value)
        if db.rollStyle ~= "list" then
            db.rollStyle = "list"
            rollPicker:Refresh("list")
        end
        if skins then skins:LayoutRows() end
    end, nil, PV("Sample", "GroupSkins", "", "rollLook", { kind = "roll" }))

    Slider(page, L["Масштаб окон ролла"], 60, 150, 5, db.rollScale or 100, function(val)
        db.rollScale = val
        if skins then skins:ApplyRollScale() end
    end, "%")

    Slider(page, L["Ширина списка"], 260, 520, 10, db.rollWidth or 340, function(val)
        db.rollWidth = val
        if skins then skins:LayoutRows() end
    end)

    Slider(page, L["Масштаб списка"], 60, 150, 5, db.rollListScale or 100, function(val)
        db.rollListScale = val
        if skins then skins:LayoutRows() end
    end, "%")

    Label(page, L["Новые строки"])

    local growPicker
    growPicker = Picker(page, {
        { key = "up",   label = L["новые сверху"] },
        { key = "down", label = L["новые снизу"] },
    }, db.rollGrow == "down" and "down" or "up", function(value)
        db.rollGrow = value
        growPicker:Refresh(value)
        if skins then skins:LayoutRows() end
    end)

    Check(page, L["Полоска таймера в списке"], db.rollTimer ~= false, function(val)
        db.rollTimer = val
        if skins then skins:LayoutRows() end
    end)

    Buttons(page, {
        { label = L["Показать пример"], width = 150, action = function()
            if skins then skins:Preview() end
        end },
        { label = L["Переместить список"], width = 170, action = function()
            if NS.Movers then NS.Movers:Toggle("lootroll") end
        end },
    })

    Label(page, "Omen")

    Check(page, L["Omen в стиле аддона"], db.skinOmen ~= false, function(val)
        db.skinOmen = val
        NS.Print(L["Нужен /reload"])
    end)

    Label(page, L["Стиль Omen"])

    local omenStylePicker
    omenStylePicker = Picker(page, {
        { key = "modern",  label = L["современный"] },
        { key = "classic", label = L["подсказка WoW"] },
        { key = "pixel",   label = L["пиксель"] },
        { key = "glass",   label = L["стекло"] },
    }, db.omenStyle or "modern", function(value)
        db.omenStyle = value
        omenStylePicker:Refresh(value)
        if NS.OmenSkin then NS.OmenSkin:Refresh() end
    end)

    Slider(page, L["Непрозрачность фона Omen"], 0, 100, 1, db.omenAlpha or 72, function(val)
        db.omenAlpha = val
        if NS.OmenSkin then NS.OmenSkin:Refresh() end
    end, "%")

    Check(page, L["Блик на полосах Omen"], db.omenSheen ~= false, function(val)
        db.omenSheen = val
        if NS.OmenSkin then NS.OmenSkin:Refresh() end
    end)

end

local FILTER_ROWS = 10

local function BuildPlateFilters(page)
    local plates = NS.Nameplates
    if not plates then return end
    local db = plates.Settings() or {}
    local S = Style()
    local list = plates:Filters()
    local selected = list[1] and 1 or nil
    local controls = {}
    local rows = {}

    local function Rule()
        return selected and list[selected]
    end

    local RefreshAll

    local function Changed()
        plates:RefreshFilters()
    end

    local function Set(field, value)
        local rule = Rule()
        if not rule then return end
        rule[field] = value
        Changed()
        if field == "label" or field == "enabled" then RefreshAll() end
    end

    Section(page, L["Правила неймплейтов"])
    Note(page, L["Правило меняет вид плашки, пока выполнены все его условия: красит полосу, зажигает свечение, увеличивает или прячет. Правила проверяются сверху вниз, срабатывает первое подходящее. Пустое условие не проверяется. Названия заклинаний и аур - через запятую, можно номерами."])

    Check(page, L["Правила включены"], db.filtersOn ~= false, function(val)
        db.filtersOn = val
        plates:Refresh()
    end)

    Label(page, L["Список правил"])

    local holder = CreateFrame("Frame", nil, page)
    holder:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    holder:SetSize(PANEL_W - SIDE_W - 80, FILTER_ROWS * 22)
    for index = 1, FILTER_ROWS do
        local row = CreateFrame("Button", nil, holder)
        row:SetSize(PANEL_W - SIDE_W - 80, 20)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(index - 1) * 22)
        local ground = row:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(row)
        ground:SetTexture(WHITE)
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetPoint("LEFT", row, "LEFT", 8, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -90, 0)
        text:SetJustifyH("LEFT")
        local state = row:CreateFontString(nil, "OVERLAY")
        state:SetFont(NS.FONT, NS.FS(10), "")
        state:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.ground, row.text, row.state = ground, text, state
        row:SetScript("OnClick", function()
            selected = index
            RefreshAll()
        end)
        rows[index] = row
    end
    page.offset = page.offset - FILTER_ROWS * 22 - 6

    Buttons(page, {
        { label = L["Добавить"], width = 100, action = function()
            if #list >= FILTER_ROWS then
                NS.Print(L["Правил не больше десяти"])
                return
            end
            list[#list + 1] = plates:NewFilter()
            selected = #list
            RefreshAll()
            Changed()
        end },
        { label = L["Удалить"], width = 100, action = function()
            if not selected then return end
            table.remove(list, selected)
            if selected > #list then selected = #list > 0 and #list or nil end
            RefreshAll()
            Changed()
        end },
        { label = L["Выше"], width = 80, action = function()
            if not selected or selected <= 1 then return end
            list[selected], list[selected - 1] = list[selected - 1], list[selected]
            selected = selected - 1
            RefreshAll()
            Changed()
        end },
        { label = L["Ниже"], width = 80, action = function()
            if not selected or selected >= #list then return end
            list[selected], list[selected + 1] = list[selected + 1], list[selected]
            selected = selected + 1
            RefreshAll()
            Changed()
        end },
    })

    Section(page, L["Выбранное правило"])

    controls.label = TextInput(page, L["Название"], "", function(value) Set("label", value) end, 60)
    controls.enabled = Check(page, L["Правило работает"], false, function(val) Set("enabled", val) end)

    local function Choice(text, field, options)
        Label(page, text)
        local picker
        picker = Picker(page, options, "any", function(value)
            picker:Refresh(value)
            Set(field, value)
        end)
        controls[field] = picker
    end

    Section(page, L["Условия"])
    Choice(L["Кто"], "reaction", {
        { key = "any",    label = L["все"] },
        { key = "enemy",  label = L["враги"] },
        { key = "friend", label = L["союзники"] },
    })
    Choice(L["Тип"], "kind", {
        { key = "any",    label = L["любой"] },
        { key = "player", label = L["игроки"] },
        { key = "boss",   label = L["боссы"] },
        { key = "elite",  label = L["элита"] },
        { key = "rare",   label = L["редкие"] },
        { key = "normal", label = L["обычные"] },
    })
    controls.units = TextInput(page, L["Только эти существа (имена через запятую)"], "", function(value) Set("units", value) end, 400)
    Choice(L["Бой"], "combat", {
        { key = "any", label = L["неважно"] },
        { key = "in",  label = L["в бою"] },
        { key = "out", label = L["вне боя"] },
    })
    Choice(L["Цель"], "target", {
        { key = "any", label = L["неважно"] },
        { key = "yes", label = L["это моя цель"] },
        { key = "no",  label = L["не моя цель"] },
    })
    controls.healthBelow = Slider(page, L["Здоровье не больше, %"], 0, 100, 1, 0, function(val) Set("healthBelow", val) end, "%")
    controls.healthAbove = Slider(page, L["Здоровье не меньше, %"], 0, 100, 1, 0, function(val) Set("healthAbove", val) end, "%")
    Note(page, L["0 - здоровье не проверяется."])
    Choice(L["Заклинание"], "casting", {
        { key = "any",           label = L["неважно"] },
        { key = "casting",       label = L["что-то кастует"] },
        { key = "interruptible", label = L["каст можно прервать"] },
        { key = "list",          label = L["кастует из списка"] },
    })
    controls.castList = TextInput(page, L["Список заклинаний"], "", function(value) Set("castList", value) end, 400)
    controls.myDebuffs = TextInput(page, L["Висит мой дебафф"], "", function(value) Set("myDebuffs", value) end, 400)
    controls.missingDebuffs = TextInput(page, L["Нет моего дебаффа"], "", function(value) Set("missingDebuffs", value) end, 400)
    controls.buffs = TextInput(page, L["Висит бафф (например, исступление)"], "", function(value) Set("buffs", value) end, 400)
    local extraFields = {}
    for _, cond in ipairs(plates and plates.CONDITIONS or {}) do
        local options = { { key = "any", label = L["неважно"] } }
        local list = type(cond.options) == "table" and cond.options or { { key = "yes", label = L["выполнено"] }, { key = "no", label = L["не выполнено"] } }
        for _, option in ipairs(list) do options[#options + 1] = { key = option.key, label = option.label or option.key } end
        Choice(cond.label, "x_" .. cond.key, options)
        extraFields[#extraFields + 1] = "x_" .. cond.key
    end

    Section(page, L["Что сделать"])

    local function Swatch(field, text)
        local row = CreateFrame("Frame", nil, page)
        row:SetSize(PANEL_W - SIDE_W - 80, 22)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
        local box = NS.Widgets.CreateThemedCheckbox(row, text, false, function(val)
            local rule = Rule()
            if not rule then return end
            if val then
                rule[field] = rule[field] or { 1, 0.8, 0.1 }
            else
                rule[field] = nil
            end
            Changed()
            row:Refresh()
        end)
        box:SetPoint("LEFT", row, "LEFT", 0, 0)
        local swatch = CreateFrame("Button", nil, row)
        swatch:SetSize(34, 16)
        swatch:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", -1, 1)
        fill:SetTexture(WHITE)
        S.CreateEdges(swatch, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)
        function row:Refresh()
            local rule = Rule()
            local color = rule and rule[field]
            box:SetChecked(color and true or false)
            swatch:SetShown(color and true or false)
            if color then fill:SetVertexColor(color[1], color[2], color[3], 1) end
        end
        swatch:SetScript("OnClick", function()
            local rule = Rule()
            local color = rule and rule[field]
            if not color then return end
            OpenColor(color, function(r, g, b)
                rule[field] = { r, g, b }
                row:Refresh()
                Changed()
            end, function(previous)
                if previous then rule[field] = previous end
                row:Refresh()
                Changed()
            end)
        end)
        Index(page, text)
        page.offset = page.offset - 26
        controls[field] = row
    end

    Swatch("color", L["Покрасить полосу здоровья"])
    Swatch("glow", L["Зажечь свечение вокруг плашки"])
    controls.scale = Slider(page, L["Размер плашки"], 50, 200, 5, 100, function(val) Set("scale", val) end, "%")
    controls.alpha = Slider(page, L["Прозрачность плашки"], 0, 100, 5, 100, function(val) Set("alpha", val) end, "%")
    Note(page, L["100% прозрачности оставляет плашку как есть, 0% прячет её совсем."])

    RefreshAll = function()
        for index, row in ipairs(rows) do
            local rule = list[index]
            if rule then
                row:Show()
                row.text:SetText(rule.label ~= "" and rule.label or (L["Правило"] .. " " .. index))
                row.state:SetText(rule.enabled and L["включено"] or L["выключено"])
                local active = index == selected
                if active then
                    row.ground:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
                    row.text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                else
                    row.ground:SetVertexColor(S.Tint(0.03, 0.035, 0.05, index % 2 == 0 and 0.6 or 0.35))
                    row.text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                end
                if rule.enabled then
                    row.state:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                else
                    row.state:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                end
            else
                row:Hide()
            end
        end

        local rule = Rule() or {}
        for _, field in ipairs({ "label", "units", "castList", "myDebuffs", "missingDebuffs", "buffs" }) do
            local box = controls[field]
            box.committed = rule[field] or ""
            box:SetText(box.committed)
            box:SetCursorPosition(0)
        end
        controls.enabled:SetChecked(rule.enabled)
        for _, field in ipairs({ "reaction", "kind", "combat", "target", "casting" }) do
            controls[field]:Refresh(rule[field] or "any")
        end
        for _, field in ipairs(extraFields) do
            controls[field]:Refresh(rule[field] or "any")
        end
        controls.healthBelow:SetValue(rule.healthBelow or 0)
        controls.healthAbove:SetValue(rule.healthAbove or 0)
        controls.scale:SetValue(rule.scale or 100)
        controls.alpha:SetValue(rule.alpha or 100)
        controls.color:Refresh()
        controls.glow:Refresh()
    end

    RefreshAll()
end

local function BuildHealPredict(page)
    local HP = NS.HealPrediction
    local db = HP and HP:Settings() or {}
    local raidDb = NS.db.raidFrames or {}
    local unitDb = NS.db.playerUI or {}

    local function Refresh()
        if NS.RaidFrames then NS.RaidFrames:UpdateAll() end
        if NS.PlayerUI then NS.PlayerUI:UpdateAll() end
    end
    local function Set(field, value)
        db[field] = value
        Refresh()
    end

    Section(page, L["Лечение и щиты"])
    Note(page, L["На полосе здоровья видно лечение, которое вот-вот придёт, щиты, поглощающие урон, и эффекты, поглощающие лечение. Щиты клиент Sirus сообщает сам. Входящее лечение считает библиотека LibHealComm: ваши заклинания видны всегда, чужие - если у лекаря стоит аддон с этой библиотекой (HealBot, ElvUI, Grid, VuhDo или этот аддон)."])

    if HP and not HP:Available() then
        Note(page, L["Библиотека LibHealComm не загрузилась - видны только щиты. Перезапустите клиент целиком."])
    end

    Check(page, L["На рейд-рамках"], raidDb.healPrediction ~= false, function(val)
        if NS.db.raidFrames then NS.db.raidFrames.healPrediction = val end
        Refresh()
    end)
    Check(page, L["На рамках игрока, цели и остальных"], unitDb.healPrediction ~= false, function(val)
        if NS.db.playerUI then NS.db.playerUI.healPrediction = val end
        Refresh()
    end)

    Label(page, L["Что показывать"])
    Check(page, L["Учитывать лечение по времени (на 3 секунды вперёд)"], db.hots ~= false, function(val) Set("hots", val) end)
    Check(page, L["Щиты (поглощение урона)"], db.absorbs ~= false, function(val) Set("absorbs", val) end)
    Check(page, L["Поглощение лечения (красным поверх здоровья)"], db.healAbsorbs ~= false, function(val) Set("healAbsorbs", val) end)
    Note(page, L["Если щит больше недостающего здоровья, на краю полосы загорается яркая черта."])

    Label(page, L["Цвета"])
    local function ColorFor(field, text)
        ColorSetting(page, text, function()
            local color = db[field] or (HP and HP.DEFAULTS[field]) or { 1, 1, 1 }
            return color[1], color[2], color[3]
        end, function(r, g, b)
            local color = db[field] or {}
            color[1], color[2], color[3] = r, g, b
            color[4] = color[4] or (HP and HP.DEFAULTS[field][4]) or 0.5
            Set(field, color)
        end)
    end
    ColorFor("myColor", L["Моё лечение"])
    ColorFor("otherColor", L["Лечение других"])
    ColorFor("absorbColor", L["Щиты"])
    ColorFor("healAbsorbColor", L["Поглощение лечения"])

    Slider(page, L["Непрозрачность"], 20, 100, 5, math.floor(((db.myColor and db.myColor[4]) or 0.55) * 100), function(val)
        for _, field in ipairs({ "myColor", "otherColor", "absorbColor", "healAbsorbColor" }) do
            if db[field] then db[field][4] = val / 100 end
        end
        Refresh()
    end, "%")

    Buttons(page, {
        { label = L["Цвета по умолчанию"], width = 180, action = function()
            if not HP then return end
            for _, field in ipairs({ "myColor", "otherColor", "absorbColor", "healAbsorbColor" }) do
                db[field] = nil
            end
            HP:Settings()
            Refresh()
            NS.Print(L["Цвета сброшены, откройте страницу заново"])
        end },
    })
end

local RAID_LAYOUTS = {
    { key = "party",  title = "Группа (до 5)" },
    { key = "raid10", title = "Рейд до 10" },
    { key = "raid25", title = "Рейд до 25" },
    { key = "raid40", title = "Рейд до 40" },
}

local function BuildRaidLayouts(page)
    local raid = NS.RaidFrames
    local db = NS.db.raidFrames or {}
    if type(db.layouts) ~= "table" then db.layouts = {} end

    local function Apply()
        if raid then
            raid:ApplyLayout()
            raid:UpdateAll()
        end
    end

    Section(page, L["Раскладки рейда"])
    Note(page, L["У каждого размера группы может быть своя раскладка: размер рамок, отступ, направление и полоса ресурса. Аддон сам переключает раскладку, когда меняется число людей в рейде. Без своей раскладки размер берётся со страницы Рейд-фреймы. Раскладка меняется вне боя."])

    for _, entry in ipairs(RAID_LAYOUTS) do
        local own = db.layouts[entry.key] or {}
        db.layouts[entry.key] = own
        local function Set(field, value)
            own[field] = value
            Apply()
        end

        Section(page, L[entry.title])
        Check(page, L["Своя раскладка"], own.enabled, function(val) Set("enabled", val) end)
        Slider(page, L["Ширина"], 40, 200, 2, own.width or db.width or 92, function(val) Set("width", val) end)
        Slider(page, L["Высота"], 16, 80, 1, own.height or db.height or 40, function(val) Set("height", val) end)
        Slider(page, L["Отступ"], 0, 12, 1, own.spacing or db.spacing or 3, function(val) Set("spacing", val) end)
        Slider(page, L["Размер имени"], 8, 16, 1, own.nameSize or db.nameSize or 11, function(val) Set("nameSize", val) end)
        Check(page, L["Полоса ресурса"], own.showPower ~= false and (own.showPower or db.showPower ~= false), function(val) Set("showPower", val) end)
        Label(page, L["Группы"])
        local picker
        picker = Picker(page, {
            { key = "RIGHT", label = L["столбцами"] },
            { key = "DOWN",  label = L["строками"] },
        }, own.growth or db.growth or "RIGHT", function(value)
            picker:Refresh(value)
            Set("growth", value)
        end)
    end

    Section(page, L["Главные танки"])
    Note(page, L["Отдельная колонка с главными танками рейда. Их назначает лидер рейда: правый клик по игроку в окне рейда - Главный танк. Танк при этом остаётся и в общей сетке."])
    local function SetTank(field, value)
        db[field] = value
        Apply()
    end
    Check(page, L["Показывать главных танков"], db.tanks, function(val) SetTank("tanks", val) end)
    Slider(page, L["Ширина"], 60, 240, 2, db.tankWidth or 120, function(val) SetTank("tankWidth", val) end)
    Slider(page, L["Высота"], 16, 80, 1, db.tankHeight or 32, function(val) SetTank("tankHeight", val) end)

    Buttons(page, {
        { label = L["Переместить"], width = 140, action = function()
            if NS.Movers then NS.Movers:Toggle("raid") end
        end },
    })
end

local function BuildRaidFrames(page)
    local raid = NS.RaidFrames
    local db = NS.db.raidFrames or {}

    local function Set(field, value)
        if raid then raid:SetOption(field, value) end
    end

    Section(page, L["Рейд-фреймы"])

    Check(page, L["Свои рейд-фреймы"], db.enabled ~= false, function(val)
        db.enabled = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Показывать и в группе (вместо рамок группы)"], db.party ~= false, function(val) Set("party", val) end)
    Check(page, L["Показывать без группы (для настройки)"], db.solo, function(val) Set("solo", val) end)
    Check(page, L["Скрывать рейд и группу клиента"], db.hideBlizzard ~= false, function(val)
        db.hideBlizzard = val
        NS.Print(L["Нужен /reload"])
    end)

    Label(page, L["Стиль"])

    local widthSlider, heightSlider, powerSlider

    local stylePicker
    stylePicker = Picker(page, WithExtras({
        { key = "blocks",   label = L["блоки"] },
        { key = "cards",    label = L["карточки"] },
        { key = "glow",     label = L["неон"] },
        { key = "minimal",  label = L["минимал"] },
        { key = "outline",  label = L["контур"] },
        { key = "portrait", label = L["портрет"] },
        { key = "segments", label = L["сегменты"] },
        { key = "glass",    label = L["стекло"] },
    }, NS.RaidFrames and NS.RaidFrames.EXTRA_LIST), db.style or "blocks", function(value)
        stylePicker:Refresh(value)
        if not raid then return end
        raid:SetStyle(value)
        local store = NS.db.raidFrames
        if widthSlider then widthSlider:SetValue(store.width) end
        if heightSlider then heightSlider:SetValue(store.height) end
        if powerSlider then powerSlider:SetValue(store.powerSize) end
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "style", { styleSizes = true }))

    Note(page, L["Блоки - сплошная заливка цветом класса. Карточки - тёмная плитка с полоской класса слева и отдельной тонкой полосой здоровья. Неон - градиентная заливка, недостающее здоровье красным, вместо рамки свечение. Минимал - без плитки: имя над полосой здоровья. Контур - толстая рамка цвета класса и полупрозрачная заливка. Портрет - лицо персонажа слева. Сегменты - полоса здоровья поделена на десятки. Стекло - прозрачная плитка с бликом и рамкой цвета темы."])

    Check(page, L["Заливка снизу вверх"], db.vertical, function(val) Set("vertical", val) end)

    Label(page, L["Размер"])

    widthSlider = Slider(page, L["Ширина"], 40, 200, 2, db.width or 92, function(val) Set("width", val) end)
    heightSlider = Slider(page, L["Высота"], 16, 80, 1, db.height or 40, function(val) Set("height", val) end)
    Slider(page, L["Отступ"], 0, 12, 1, db.spacing or 3, function(val) Set("spacing", val) end)
    powerSlider = Slider(page, L["Высота полосы ресурса"], 2, 10, 1, db.powerSize or 4, function(val) Set("powerSize", val) end)
    Slider(page, L["Толщина полосы здоровья (карточки)"], 3, 16, 1, db.barSize or 6, function(val) Set("barSize", val) end)

    Label(page, L["Группы"])

    local growthPicker
    growthPicker = Picker(page, {
        { key = "RIGHT", label = L["столбцами"] },
        { key = "DOWN",  label = L["строками"] },
    }, db.growth or "RIGHT", function(value)
        Set("growth", value)
        growthPicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "growth"))

    Label(page, L["Цвет полосы здоровья"])

    local colorPicker
    colorPicker = Picker(page, {
        { key = "class",  label = L["класс"] },
        { key = "dark",   label = L["тёмный"] },
        { key = "accent", label = L["акцент"] },
    }, db.colorMode or "class", function(value)
        Set("colorMode", value)
        colorPicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "colorMode"))

    Label(page, L["Цвет имени"])

    local namePicker
    namePicker = Picker(page, {
        { key = "auto",  label = L["авто"] },
        { key = "class", label = L["класс"] },
        { key = "white", label = L["белый"] },
    }, db.nameColor or "auto", function(value)
        Set("nameColor", value)
        namePicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "nameColor"))

    Label(page, L["Текст здоровья"])

    local textPicker
    textPicker = Picker(page, {
        { key = "deficit", label = L["недостающее"] },
        { key = "percent", label = L["проценты"] },
        { key = "none",    label = L["нет"] },
    }, db.healthText or "deficit", function(value)
        Set("healthText", value)
        textPicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "healthText"))

    Label(page, L["Шрифт и фон"])

    Slider(page, L["Размер имени"], 8, 16, 1, db.nameSize or 11, function(val) Set("nameSize", val) end)
    Slider(page, L["Размер текста здоровья"], 7, 14, 1, db.textSize or 10, function(val) Set("textSize", val) end)
    Slider(page, L["Непрозрачность фона"], 0, 100, 1, db.groundAlpha or 92, function(val) Set("groundAlpha", val) end, "%")
    Slider(page, L["Размер дебаффов"], 10, 24, 1, db.debuffSize or 14, function(val) Set("debuffSize", val) end)
    Check(page, L["Блик на полосе здоровья"], db.sheen ~= false, function(val) Set("sheen", val) end)

    Label(page, L["Что показывать"])

    Check(page, L["Полоса ресурса"], db.showPower ~= false, function(val) Set("showPower", val) end)
    Check(page, L["Роль игрока"], db.showRole ~= false, function(val) Set("showRole", val) end)
    local roleStylePicker
    roleStylePicker = Picker(page, {
        { key = "both", label = L["значок и надпись"] },
        { key = "icon", label = L["значок"] },
        { key = "text", label = L["надпись"] },
    }, db.roleStyle or "both", function(value)
        roleStylePicker:Refresh(value)
        Set("roleStyle", value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "roleStyle"))
    Note(page, L["Роль берётся из поиска группы (её выбирают при записи в подземелье или рейд). Свою роль аддон знает по специализации, а главного танка - по назначению лидера рейда. Если игрок пришёл в группу не через поиск, его роль клиенту неизвестна, и надписи у него не будет."])
    Check(page, L["Лидер и помощники"], db.showLeader ~= false, function(val) Set("showLeader", val) end)
    Check(page, L["Ответственный за добычу"], db.showLooter ~= false, function(val) Set("showLooter", val) end)
    Check(page, L["Дебаффы (до трёх)"], db.showDebuffs ~= false, function(val) Set("showDebuffs", val) end)
    Check(page, L["Входящее лечение"], db.healPrediction ~= false, function(val) Set("healPrediction", val) end)
    Check(page, L["Затемнять тех, кто далеко"], db.rangeFade ~= false, function(val) Set("rangeFade", val) end)

    Note(page, L["Рамка белая у вашей цели, красная у того, кто держит агро, и цвета дебаффа, который вы можете снять. Размеры и раскладка в бою не меняются и применятся после боя."])

    Buttons(page, {
        { label = L["Переместить"], width = 140, action = function()
            if NS.Movers then NS.Movers:Toggle("raid") end
        end },
    })
end

local function BuildMessenger(page)
    local Msg = NS.Messenger
    local db = Msg and Msg:Settings() or {}

    local function Set(field, value)
        db[field] = value
        if Msg then
            Msg:ApplyLook()
            Msg:UpdateButton()
        end
    end

    local function Choice(text, field, options, preview)
        Label(page, text)
        local picker
        picker = Picker(page, options, db[field], function(value)
            picker:Refresh(value)
            Set(field, value)
        end, nil, preview)
    end

    Section(page, L["Сообщения"])
    Note(page, L["Шёпот открывается в отдельном окне, как в мессенджере: список собеседников, переписка с каждым, история между сессиями, кнопки пригласить, в друзья, игнор и кто. Всё берётся из самого клиента, другим игрокам ничего ставить не нужно. Ссылки на предметы работают, ссылки на сайты открываются для копирования. Shift+клик по предмету вставляет его в окно, Tab переключает собеседника."])

    if Msg and Msg:OtherAddon() then
        Note(page, L["Сейчас включён аддон WIM - окно сообщений аддона ждёт. Выключите WIM, чтобы пользоваться этим окном."])
        Buttons(page, {
            { label = L["Выключить WIM и перезагрузить"], width = 240, action = function()
                if DisableAddOn then
                    DisableAddOn("WIM")
                    DisableAddOn("Wim")
                end
                ReloadUI()
            end },
        })
    end

    Check(page, L["Включить"], db.enabled ~= false, function(val)
        db.enabled = val
        NS.Print(L["Нужен /reload"])
    end)
    Check(page, L["Убирать шёпот из чата"], db.hideInChat ~= false, function(val) Set("hideInChat", val) end)
    Check(page, L["R и Шепнуть открывают это окно"], db.intercept ~= false, function(val) Set("intercept", val) end)
    Note(page, L["Если после этого команды вида /cast из чата начнут блокироваться, выключите этот пункт: так перехват шёпота устроен и у WIM."])

    Choice(L["Когда открывать окно само"], "popup", {
        { key = "incoming", label = L["при входящем"] },
        { key = "outgoing", label = L["только когда пишу я"] },
        { key = "never",    label = L["никогда"] },
    })
    Choice(L["Шёпот от незнакомых"], "strangers", {
        { key = "popup", label = L["как от всех"] },
        { key = "quiet", label = L["без окна, только счётчик"] },
    })
    Note(page, L["Знакомые - друзья, гильдия и группа."])
    Check(page, L["Открывать окно и в бою"], db.combatPopup, function(val) Set("combatPopup", val) end)
    Check(page, L["Сразу ставить курсор в поле ввода"], db.focusOnPopup, function(val) Set("focusOnPopup", val) end)
    Check(page, L["Звук входящего"], db.sound ~= false, function(val) Set("sound", val) end)
    Check(page, L["Время у сообщений"], db.timestamps ~= false, function(val) Set("timestamps", val) end)
    Check(page, L["Кнопка с числом непрочитанных"], db.showButton ~= false, function(val) Set("showButton", val) end)
    Choice(L["Стиль кнопки"], "buttonStyle", NS.Styling.BoxOptions(), PV("Box", "button", { count = "3" }))
    Slider(page, L["Размер кнопки"], 20, 60, 1, db.buttonSize or 34, function(val) Set("buttonSize", val) end)

    Section(page, L["Вид и история"])
    local styleOptions = {}
    for _, key in ipairs(Msg and Msg.STYLE_ORDER or {}) do
        styleOptions[#styleOptions + 1] = { key = key, label = L[Msg.STYLES[key].label] }
    end
    Choice(L["Стиль окна"], "style", styleOptions, PV("Messenger"))
    Note(page, L["Ночное небо, Рассвет, Письмо и Аркана - с картинками: звёздное небо с горами, рассвет над озером, старый пергамент с сургучной печатью, медленно вращающийся рунный круг. Стиль меняется сразу, открытое окно перерисовывается."])
    Slider(page, L["Яркость картинки"], 0, 100, 5, db.artAlpha or 100, function(val) Set("artAlpha", val) end, "%")
    Slider(page, L["Размер шрифта"], 9, 18, 1, db.fontSize or 12, function(val) Set("fontSize", val) end)
    Slider(page, L["Непрозрачность окна"], 30, 100, 5, db.alpha or 95, function(val) Set("alpha", val) end, "%")
    Slider(page, L["Хранить дней"], 1, 365, 1, db.keepDays or 30, function(val) Set("keepDays", val) end)
    Slider(page, L["Сообщений на собеседника"], 50, 1000, 50, db.keepCount or 300, function(val) Set("keepCount", val) end)
    Note(page, L["История хранится у каждого персонажа отдельно и не попадает в экспорт профиля. Старое удаляется при входе в игру."])
    TextInput(page, L["Не показывать шёпот со словами (через запятую)"], db.blockWords or "", function(value) Set("blockWords", value) end, 400)

    Buttons(page, {
        { label = L["Открыть окно"], width = 140, action = function() if Msg then Msg:Show() end end },
        { label = L["Переместить кнопку"], width = 160, action = function() if NS.Movers then NS.Movers:Toggle("chat") end end },
    })
end

local function BuildTracker(page)
    local T = NS.TrackerSkin
    local db = T and T.Settings() or {}

    Section(page, L["Трекер заданий"])
    Note(page, L["Трекер заданий клиента (задания, подземелья, достижения, боевой пропуск, рецепты) в стиле аддона. Логика остаётся клиентской: сворачивание, фильтры, клики по заданиям и предметы заданий работают как раньше. Включение и выключение применяются после перезагрузки, остальное сразу."])
    Check(page, L["Трекер в стиле аддона"], db.enabled ~= false, function(val)
        db.enabled = val and true or false
    end)

    Label(page, L["Фон трекера"])
    local styleOptions = {}
    for _, key in ipairs(T and T.STYLES or {}) do
        styleOptions[#styleOptions + 1] = { key = key, label = L[T.STYLE_LABELS[key]] }
    end
    local stylePicker
    stylePicker = Picker(page, styleOptions, db.style or "fade", function(value)
        stylePicker:Refresh(value)
        if T then T:SetOption("style", value) end
    end, nil, PV("Sample", "TrackerSkin", "tracker", "style"))
    Slider(page, L["Плотность фона"], 10, 100, 5, db.alpha or 70, function(val)
        if T then T:SetOption("alpha", val) end
    end, "%")

    Label(page, L["Цвет заголовков"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "accent", label = L["цвет темы"] },
        { key = "gold", label = L["золотой"] },
        { key = "white", label = L["белый"] },
        { key = "class", label = L["цвет класса"] },
    }, db.headerColor or "accent", function(value)
        colorPicker:Refresh(value)
        if T then T:SetOption("headerColor", value) end
    end, nil, PV("Sample", "TrackerSkin", "tracker", "headerColor"))

    Slider(page, L["Размер текста"], 9, 18, 1, db.fontSize or 12, function(val)
        if T then T:SetOption("fontSize", val) end
    end)
    Check(page, L["Обводка текста"], db.outline ~= false, function(val)
        if T then T:SetOption("outline", val and true or false) end
    end)

    Note(page, L["Трекер можно передвинуть в режиме расстановки интерфейса. Надпись «Активные задания» поверх трекера рисует аддон Questie - его трекер настраивается в самом Questie."])
    Buttons(page, {
        { label = L["Переместить"], width = 140, action = function()
            if NS.Movers then NS.Movers:Toggle() end
        end },
        { label = L["Перезагрузить интерфейс"], width = 200, action = function() ReloadUI() end },
    })
end

local function BuildQueueEye(page)
    local Q = NS.QueueEye
    local db = Q and Q.Settings() or {}

    Section(page, L["Значок поиска группы"])
    Note(page, L["Глаз у миникарты, который появляется, пока вы в очереди, заменяется анимированным значком аддона. Пока идёт поиск, значок двигается и мягко светится, когда группа найдена - светится ярче и быстрее. Кнопка остаётся клиентской: клик, меню очереди и подсказка работают как раньше. Включение и выключение применяются после перезагрузки."])
    Check(page, L["Свой значок вместо глаза"], db.enabled ~= false, function(val)
        db.enabled = val and true or false
    end)

    Label(page, L["Анимация"])
    local options = {}
    for _, key in ipairs(Q and Q.STYLES or {}) do
        options[#options + 1] = { key = key, label = L[Q.LABELS[key]] }
    end
    local stylePicker
    stylePicker = Picker(page, options, db.style or "arcane", function(value)
        stylePicker:Refresh(value)
        if Q then Q:SetOption("style", value) end
    end, nil, PV("Sample", "QueueEye", "queueEye", "style"))

    Note(page, L["Первые шесть - цветные, со своими цветами и свечением, выбор цвета ниже на них не действует. Остальные - контурные и красятся в выбранный цвет."])

    Label(page, L["Цвет"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "accent", label = L["цвет темы"] },
        { key = "class", label = L["цвет класса"] },
        { key = "gold", label = L["золотой"] },
        { key = "green", label = L["зелёный"] },
        { key = "white", label = L["белый"] },
    }, db.color or "accent", function(value)
        colorPicker:Refresh(value)
        if Q then Q:SetOption("color", value) end
    end, nil, PV("Sample", "QueueEye", "queueEye", "color"))

    Label(page, L["Цвет, когда группа найдена"])
    local foundPicker
    foundPicker = Picker(page, {
        { key = "green", label = L["зелёный"] },
        { key = "gold", label = L["золотой"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "white", label = L["белый"] },
    }, db.foundColor or "green", function(value)
        foundPicker:Refresh(value)
        if Q then Q:SetOption("foundColor", value) end
    end, nil, PV("Sample", "QueueEye", "queueEye", "foundColor"))
    Note(page, L["У каждого значка своя анимация на момент, когда группа найдена: глаз широко раскрывается, радар берёт цель в рамку, компас замирает на севере, орбиты сходятся в центр, у сонара, песочных часов и лупы появляется галочка, руна вспыхивает. Цветные значки меняют цвета на свои: зелёный глаз, золотой шар, сияющий портал. Работает и для поиска подземелий, и для полей боя, и для приглашения в собранную группу."])

    Label(page, L["Значок, когда вы в игре"])
    local ingameOptions = {}
    for _, key in ipairs(Q and Q.INGAME_ORDER or {}) do
        ingameOptions[#ingameOptions + 1] = { key = key, label = L[Q.INGAME_LABELS[key]] }
    end
    local ingamePicker
    ingamePicker = Picker(page, ingameOptions, db.ingame or "auto", function(value)
        ingamePicker:Refresh(value)
        if Q then Q:SetOption("ingame", value) end
    end, nil, PV("Sample", "QueueEye", "queueEye", "ingame", { ingame = true }))
    Note(page, L["Пока вы в подземелье из поиска группы, на поле боя или в мини-игре, кнопка у миникарты остаётся: через неё телепортируются из подземелья, открывают счёт и выходят. На ней тогда стоит не анимация, а этот значок. По месту - свой значок для каждого случая: врата для подземелья, мечи для поля боя, пьедестал или кубок для мини-игры. Контурные красятся в цвет значка, цветные рисуются своими цветами."])

    Label(page, L["Подложка"])
    local platePicker
    platePicker = Picker(page, {
        { key = "disc", label = L["тёмный круг с кольцом"] },
        { key = "ring", label = L["только кольцо"] },
        { key = "none", label = L["без подложки"] },
    }, db.plate or "disc", function(value)
        platePicker:Refresh(value)
        if Q then Q:SetOption("plate", value) end
    end, nil, PV("Sample", "QueueEye", "queueEye", "plate"))

    Slider(page, L["Скорость анимации, кадров в секунду"], 4, 30, 1, db.speed or 12, function(val)
        if Q then Q:SetOption("speed", val) end
    end)
    Slider(page, L["Размер значка"], 60, 160, 5, db.size or 100, function(val)
        if Q then Q:SetOption("size", val) end
    end, "%")
end

local function BuildQueueStatus(page)
    local Q = NS.QueueStatus
    local db = Q and Q.Settings() or {}

    Section(page, L["Окно очереди"])
    Note(page, L["Окно, которое открывается при наведении на значок поиска группы: название очереди, ваши роли, сколько танков, лекарей и бойцов уже найдено, среднее время ожидания и время в очереди. Аддон меняет только его вид, данные и клики остаются клиентскими. Включение и выключение применяются после перезагрузки, стиль и значки ролей - сразу."])
    Check(page, L["Свой вид окна очереди"], db.enabled ~= false, function(val)
        db.enabled = val and true or false
    end)

    Label(page, L["Стиль окна"])
    local styles = {}
    for _, key in ipairs(Q and Q.STYLE_ORDER or {}) do
        styles[#styles + 1] = { key = key, label = L[Q.STYLES[key].label] }
    end
    local stylePicker
    stylePicker = Picker(page, styles, db.style or "crest", function(value)
        stylePicker:Refresh(value)
        if Q then Q:SetOption("style", value) end
    end, nil, PV("Sample", "QueueStatus", "queueStatus", "style"))
    Note(page, L["Первые четыре нарисованы новыми текстурами: герб с золотыми углами и полосой под заголовком, тайный со светящейся руной, сияние с лучами из угла и ночное небо. Остальные - обычные рамки, как у других элементов интерфейса."])

    Label(page, L["Значки ролей"])
    local roles = {}
    for _, key in ipairs(Q and Q.ROLE_ORDER or {}) do
        roles[#roles + 1] = { key = key, label = L[Q.ROLE_LABELS[key]] }
    end
    local rolePicker
    rolePicker = Picker(page, roles, db.roles or "crest", function(value)
        rolePicker:Refresh(value)
        if Q then Q:SetOption("roles", value) end
    end, nil, PV("Sample", "QueueStatus", "queueStatus", "roles"))
    Note(page, L["Роль, которую ещё ищут, показывается серой и без свечения, найденная - в своём цвете: танк синим, лекарь зелёным, боец красным."])

    Slider(page, L["Непрозрачность фона"], 30, 100, 5, db.alpha or 92, function(val)
        if Q then Q:SetOption("alpha", val) end
    end, "%")
end

local function BuildRaidUtility(page)
    local RU = NS.RaidUtility
    local db = RU and RU.Settings() or {}

    local function Set(field, value)
        db[field] = value
        if RU then RU:Update() end
    end

    Section(page, L["Утилиты рейда"])
    Note(page, L["Кнопка Рейд вверху экрана открывает панель лидера: проверка готовности, отсчёт перед пуллом, проверка ролей, главный танк и наводчик для цели, метки на цель и на землю, все помощники и роспуск группы. Действия лидера работают, только если вы лидер или помощник. Панель открывается вне боя."])
    Check(page, L["Включить"], db.enabled ~= false, function(val) Set("enabled", val) end)
    Check(page, L["Показывать и в группе, не только в рейде"], db.partyToo ~= false, function(val) Set("partyToo", val) end)
    Slider(page, L["Отсчёт перед пуллом, секунд"], 3, 30, 1, db.countdown or 10, function(val) Set("countdown", val) end)

    local function Restyle(field, value)
        db[field] = value
        if RU then RU:ApplyLook() end
    end
    Section(page, L["Вид"])
    Label(page, L["Стиль кнопки Рейд"])
    local togglePicker
    togglePicker = Picker(page, NS.Styling.ThemeBoxOptions(), db.toggleStyle or "theme", function(value)
        togglePicker:Refresh(value)
        Restyle("toggleStyle", value)
    end, nil, PV("Box", "toggle"))
    Slider(page, L["Ширина кнопки"], 40, 200, 2, db.toggleWidth or 90, function(val) Restyle("toggleWidth", val) end)
    Slider(page, L["Высота кнопки"], 14, 40, 1, db.toggleHeight or 18, function(val) Restyle("toggleHeight", val) end)
    Label(page, L["Стиль панели"])
    local panelPicker
    panelPicker = Picker(page, NS.Styling.ThemeBoxOptions(), db.panelStyle or "theme", function(value)
        panelPicker:Refresh(value)
        Restyle("panelStyle", value)
    end, nil, PV("Box", "panel"))
    Slider(page, L["Плотность фона панели"], 30, 100, 2, db.panelAlpha or 94, function(val) Restyle("panelAlpha", val) end, "%")

    Buttons(page, {
        { label = L["Переместить"], width = 140, action = function()
            if NS.Movers then NS.Movers:Toggle("raid") end
        end },
    })
end

local function BuildClassPower(page)
    local db = NS.db.playerUI or {}
    local function Set(field, value)
        db[field] = value
        if NS.PlayerUI and NS.PlayerUI.RestyleClassPower then NS.PlayerUI:RestyleClassPower() end
    end
    local function Choice(label, field, options, fallback, preview)
        Label(page, label)
        local picker
        picker = Picker(page, options, db[field] or fallback, function(value)
            picker:Refresh(value)
            Set(field, value)
        end, nil, preview)
    end

    Section(page, L["Ресурсы класса"])
    Note(page, L["Серия приёмов у разбойника и друида, руны у рыцаря смерти, тотемы у шамана - полоса под рамкой игрока. Данные берутся из клиента. Тотемы всегда остаются полосками с иконками, форма к ним не применяется."])
    Check(page, L["Показывать ресурсы класса"], db.classPower ~= false, function(val)
        db.classPower = val and true or false
        NS.Print(L["Нужен /reload"])
    end)
    Choice(L["Форма"], "classPowerShape", {
        { key = "bars",    label = L["полоски"] },
        { key = "orbs",    label = L["сферы"] },
        { key = "hex",     label = L["шестиугольники"] },
        { key = "diamond", label = L["ромбы"] },
    }, "bars", PV("ClassPower", "shape"))
    Choice(L["Рамка"], "classPowerStyle", NS.Styling.BoxOptions(), "flat", PV("ClassPower", "style"))
    Slider(page, L["Высота полосок"], 4, 24, 1, db.classPowerHeight or 8, function(val) Set("classPowerHeight", val) end)
    Slider(page, L["Размер фигур"], 10, 40, 1, db.classPowerSize or 16, function(val) Set("classPowerSize", val) end)
    Slider(page, L["Промежуток"], 0, 12, 1, db.classPowerGap or 3, function(val) Set("classPowerGap", val) end)
    Slider(page, L["Плотность фона"], 0, 100, 5, db.classPowerBg or 92, function(val) Set("classPowerBg", val) end, "%")
    Slider(page, L["Сдвиг по горизонтали"], -200, 200, 1, db.classPowerX or 0, function(val) Set("classPowerX", val) end)
    Slider(page, L["Сдвиг по вертикали"], -200, 200, 1, db.classPowerY or 0, function(val) Set("classPowerY", val) end)
end

local function BuildUtilities(page)
    local U = NS.Utilities
    local db = U and U.Settings() or {}

    Section(page, L["Ремонт и хлам"])
    Label(page, L["Автоматический ремонт у торговца"])
    local repairPicker
    repairPicker = Picker(page, {
        { key = "off",    label = L["выключен"] },
        { key = "player", label = L["за свой счёт"] },
        { key = "guild",  label = L["за счёт гильдии, если можно"] },
    }, db.repair or "off", function(value)
        db.repair = value
        repairPicker:Refresh(value)
    end)
    Check(page, L["Писать в чат, сколько стоил ремонт"], db.repairReport ~= false, function(val) db.repairReport = val and true or false end)
    Check(page, L["Продавать серый хлам, даже когда сумки аддона выключены"], db.sellJunk, function(val) db.sellJunk = val and true or false end)
    Note(page, L["С включёнными сумками аддона хлам продаётся по их собственной настройке."])

    Section(page, L["Красные ошибки"])
    Label(page, L["Сообщения об ошибках посреди экрана"])
    local errorPicker
    errorPicker = Picker(page, {
        { key = "show",       label = L["показывать все"] },
        { key = "spam",       label = L["без частых (откат, нет ресурса, нет цели)"] },
        { key = "spamcombat", label = L["без частых только в бою"] },
        { key = "combat",     label = L["скрывать все в бою"] },
        { key = "all",        label = L["скрывать все"] },
    }, db.errors or "show", function(value)
        db.errors = value
        errorPicker:Refresh(value)
        if U then U:ApplyErrors() end
    end)

    Section(page, L["Объявление о прерывании"])
    Label(page, L["Куда писать, когда вы прервали заклинание"])
    local interruptPicker
    interruptPicker = Picker(page, {
        { key = "off",   label = L["никуда"] },
        { key = "self",  label = L["только себе"] },
        { key = "group", label = L["в группу или рейд"] },
        { key = "auto",  label = L["в группу, иначе /сказать"] },
        { key = "say",   label = L["/сказать"] },
        { key = "yell",  label = L["/крик"] },
    }, db.interrupt or "off", function(value)
        db.interrupt = value
        interruptPicker:Refresh(value)
        if U then U:ApplyInterrupt() end
    end)
    Check(page, L["Учитывать прерывания питомца"], db.interruptPet ~= false, function(val) db.interruptPet = val and true or false end)
    TextInput(page, L["Текст (пусто - по умолчанию)"], db.interruptText or "", function(value) db.interruptText = value end, 200)
    Note(page, L["{spell} заменяется ссылкой на прерванное заклинание, {target} - именем цели. По умолчанию: Прервано: {spell} ({target})."])

    Section(page, L["Прочее"])
    Check(page, L["Сразу выходить духом после смерти на поле боя и в зонах сражений"], db.autoRelease, function(val) db.autoRelease = val and true or false end)
    Check(page, L["Снимок экрана при получении достижения"], db.screenshotAchievement, function(val) db.screenshotAchievement = val and true or false end)
end

local function BuildChatExtras(page)
    local X = NS.ChatExtras
    local db = X and X.Settings() or {}

    Section(page, L["Копирование"])
    Check(page, L["Кнопка копирования в углу каждого окна чата"], db.copyButton, function(val)
        db.copyButton = val and true or false
        if X then X:ApplyCopy() end
    end)
    Buttons(page, {
        { label = L["Скопировать чат сейчас"], width = 220, action = function() if X then X:Copy() end end },
    })
    Note(page, L["Открывает окно с текстом выбранной вкладки, его можно выделить и скопировать. То же делает команда /narci copy."])

    Section(page, L["Ключевые слова"])
    Check(page, L["Подсвечивать ключевые слова"], db.highlight, function(val) db.highlight = val and true or false end)
    Check(page, L["Моё имя - тоже ключевое слово"], db.ownName, function(val) db.ownName = val and true or false end)
    TextInput(page, L["Слова через запятую"], db.keywords or "", function(value) db.keywords = value end, 400)
    Label(page, L["Цвет подсветки"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "accent", label = L["цвет темы"] },
        { key = "gold",   label = L["золотой"] },
        { key = "red",    label = L["красный"] },
        { key = "white",  label = L["белый"] },
    }, db.highlightColor or "accent", function(value)
        db.highlightColor = value
        colorPicker:Refresh(value)
    end, nil, PV("Highlight"))
    Check(page, L["Звук, когда встречается ключевое слово (не чаще раза в 5 секунд)"], db.keywordSound, function(val) db.keywordSound = val and true or false end)

    Section(page, L["Фильтр спама"])
    Check(page, L["Скрывать повторы и сообщения со стоп-словами"], db.spam, function(val) db.spam = val and true or false end)
    Slider(page, L["Повтор от того же игрока скрывается в течение"], 5, 300, 5, db.spamWindow or 30, function(val) db.spamWindow = val end, L[" с"])
    TextInput(page, L["Стоп-слова через запятую"], db.blockWords or "", function(value) db.blockWords = value end, 400)
    Note(page, L["Повторы ищутся в общих каналах, /сказать и /крик. Стоп-слова скрывают сообщение в любом канале, кроме ваших собственных."])

    Section(page, L["История чата"])
    Check(page, L["Сохранять историю и показывать её после входа и перезагрузки"], db.history, function(val) db.history = val and true or false end)
    Slider(page, L["Сколько сообщений хранить"], 20, 500, 10, db.historySize or 100, function(val) db.historySize = val end)
    Label(page, L["Что сохранять"])
    for _, entry in ipairs({
        { key = "say",     label = "Сказать и крик" },
        { key = "guild",   label = "Гильдия и офицеры" },
        { key = "party",   label = "Группа" },
        { key = "raid",    label = "Рейд и поле боя" },
        { key = "channel", label = "Общие каналы" },
        { key = "whisper", label = "Шёпот" },
    }) do
        Check(page, L[entry.label], db.historyTypes and db.historyTypes[entry.key], function(val)
            db.historyTypes[entry.key] = val and true or false
        end)
    end
    Note(page, L["История хранится для каждого персонажа отдельно и не попадает в экспорт профиля. При показе шёпота клиент играет звук шёпота."])
    Buttons(page, {
        { label = L["Очистить историю"], width = 180, action = function() if X then X:Clear() end end },
    })
end

local function BuildRaidAuras(page)
    local raid = NS.RaidFrames
    local db = NS.db.raidFrames or {}
    NS.db.raidFrames = db
    local F = NS.AuraFilters

    local function Set(field, value)
        db[field] = value
        if F then F.Reset() end
        if raid then raid:UpdateAll() end
    end

    Section(page, L["Дебаффы на рамках"])
    Label(page, L["Какие дебаффы показывать"])
    local filterPicker
    filterPicker = Picker(page, {
        { key = "all",         label = L["все"] },
        { key = "dispellable", label = L["только те, что я могу снять"] },
        { key = "important",   label = L["важные рейдовые и снимаемые"] },
    }, db.debuffFilter or "all", function(value)
        Set("debuffFilter", value)
        filterPicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "debuffFilter"))
    Slider(page, L["Сколько дебаффов в ряду"], 1, 3, 1, db.maxDebuffs or 3, function(val) Set("maxDebuffs", val) end)
    Check(page, L["Скрывать серверные дебаффы"], db.hideServerDebuffs ~= false, function(val)
        Set("hideServerDebuffs", val and true or false)
    end)
    Note(page, L["Метки сервера Sirus, которые висят как дебаффы: VIP-статус, премиум, категория персонажа, знак зодиака, смена фракции. Список берётся из клиента, тот же, по которому их прячут стандартные рейд-рамки."])
    TextInput(page, L["Никогда не показывать (названия или номера через запятую)"], db.debuffBlacklist or "", function(value)
        Set("debuffBlacklist", value)
    end, 400)

    Section(page, L["Дебаффы, которые вы можете снять"])
    Label(page, L["Как выделять рамку"])
    local dispelPicker
    dispelPicker = Picker(page, {
        { key = "border", label = L["цветной край"] },
        { key = "fill",   label = L["заливка полосы"] },
        { key = "both",   label = L["край и заливка"] },
        { key = "off",    label = L["не выделять"] },
    }, db.dispelMode or "border", function(value)
        Set("dispelMode", value)
        dispelPicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "dispelMode"))
    Slider(page, L["Яркость заливки"], 10, 80, 5, db.dispelAlpha or 35, function(val) Set("dispelAlpha", val) end, "%")
    Note(page, L["Цвет по типу: магия синяя, проклятие фиолетовое, болезнь коричневая, яд зелёный. Учитывается только то, что может снять ваш персонаж."])

    Section(page, L["Важные рейдовые дебаффы"])
    Check(page, L["Крупный значок в центре рамки"], db.centerDebuff ~= false, function(val) Set("centerDebuff", val and true or false) end)
    Slider(page, L["Размер значка"], 12, 36, 1, db.centerSize or 22, function(val) Set("centerSize", val) end)
    Check(page, L["Встроенный список (Наксрамас, Ульдуар, Испытание крестоносца, Цитадель Ледяной Короны, Рубиновое святилище)"], db.raidBuiltin ~= false, function(val)
        Set("raidBuiltin", val and true or false)
    end)
    TextInput(page, L["Свои важные дебаффы (названия или номера через запятую)"], db.raidDebuffs or "", function(value)
        Set("raidDebuffs", value)
    end, 400)

    Section(page, L["Индикаторы баффов"])
    Note(page, L["Цветные метки по краям рамки показывают ваши баффы на союзниках: обновления и щиты у жреца, омоложение и жизнецвет у друида, частицу Света у паладина, быстрину и щит земли у шамана. Таймер идёт по метке."])
    Check(page, L["Показывать индикаторы"], db.indicators ~= false, function(val) Set("indicators", val and true or false) end)
    Check(page, L["Только мои баффы"], db.indicatorMine ~= false, function(val) Set("indicatorMine", val and true or false) end)
    Check(page, L["Таймер на индикаторе"], db.indicatorTimer ~= false, function(val) Set("indicatorTimer", val and true or false) end)
    Label(page, L["Вид индикатора"])
    local stylePicker
    stylePicker = Picker(page, {
        { key = "square", label = L["цветной квадрат"] },
        { key = "icon",   label = L["значок заклинания"] },
    }, db.indicatorStyle or "square", function(value)
        Set("indicatorStyle", value)
        stylePicker:Refresh(value)
    end, nil, PV("Sample", "RaidFrames", "raidFrames", "indicatorStyle"))
    Slider(page, L["Размер индикатора"], 5, 20, 1, db.indicatorSize or 8, function(val) Set("indicatorSize", val) end)

    local _, class = UnitClass("player")
    local defaults = F and F.CLASS_INDICATORS[class or ""] or {}
    if #defaults > 0 then
        Label(page, L["Баффы вашего класса"])
        if type(db.indicatorOff) ~= "table" then db.indicatorOff = {} end
        for _, entry in ipairs(defaults) do
            local name = F.SpellName(entry.id) or ("#" .. entry.id)
            Check(page, name, not db.indicatorOff[entry.id], function(val)
                db.indicatorOff[entry.id] = (not val) or nil
                Set("indicatorOff", db.indicatorOff)
            end)
        end
    end
    TextInput(page, L["Свои баффы для индикаторов (названия или номера через запятую)"], db.indicatorExtra or "", function(value)
        Set("indicatorExtra", value)
    end, 400)
end

local function BuildMiniBag(page)
    local db = NS.db.minimap or {}

    local function Apply(field, value)
        db[field] = value
        local skin = NS.MinimapSkin
        if not skin then return end
        if field == "collect" then
            skin:SetOption("collect", value)
        else
            skin:ApplyBag()
        end
    end

    Section(page, L["Кнопки аддонов"])

    Note(page, L["Собирает кнопки аддонов с миникарты в одну панель и заменяет аддон MBB: новые кнопки подхватываются сами, ненужные можно оставить на миникарте. Правый клик по значку открывает эту страницу."])

    if IsAddOnLoaded and IsAddOnLoaded("MBB") then
        Note(page, L["Сейчас включён аддон MBB, он перехватывает те же кнопки, поэтому сборщик аддона ждёт. Отключите MBB, исключения из него перенесутся."])
        Buttons(page, {
            { label = L["Отключить MBB"], width = 160, action = function()
                NS.Widgets.ShowConfirm(
                    L["Отключить MBB и перезагрузить интерфейс?"],
                    L["Отключить"],
                    function()
                        DisableAddOn("MBB")
                        db.collect = true
                        ReloadUI()
                    end)
            end },
        })
    end

    Check(page, L["Собирать кнопки аддонов в одну"], db.collect, function(val) Apply("collect", val) end)

    Label(page, L["Как открывать"])

    local openPicker
    openPicker = Picker(page, {
        { key = "click", label = L["по клику"] },
        { key = "hover", label = L["при наведении"] },
        { key = "always", label = L["всегда открыта"] },
    }, db.bagOpen or "click", function(value)
        Apply("bagOpen", value)
        openPicker:Refresh(value)
    end)

    Label(page, L["Куда раскрывать"])

    local directionPicker
    directionPicker = Picker(page, {
        { key = "left",  label = L["влево"] },
        { key = "right", label = L["вправо"] },
        { key = "up",    label = L["вверх"] },
        { key = "down",  label = L["вниз"] },
    }, db.bagDirection or "left", function(value)
        Apply("bagDirection", value)
        directionPicker:Refresh(value)
    end)

    Slider(page, L["Кнопок в ряд"], 1, 12, 1, db.bagPerRow or 5, function(val) Apply("bagPerRow", val) end)
    Slider(page, L["Размер кнопок"], 20, 40, 1, db.bagSize or 28, function(val) Apply("bagSize", val) end)
    Slider(page, L["Отступ между кнопками"], 0, 10, 1, db.bagSpacing or 4, function(val) Apply("bagSpacing", val) end)
    Slider(page, L["Сворачивать через, сек"], 0, 10, 1, db.bagCollapse or 2, function(val) Apply("bagCollapse", val) end)
    Note(page, L["0 - панель закрывается только повторным кликом."])

    Check(page, L["Квадратные иконки без круглых рамок"], db.bagSquare ~= false, function(val) Apply("bagSquare", val) end)

    Buttons(page, {
        { label = L["Переместить значок"], width = 170, action = function()
            if NS.Movers then NS.Movers:Toggle("minimap") end
        end },
        { label = L["Вернуть к миникарте"], width = 170, action = function()
            db.bagPoint, db.bagRelativePoint, db.bagX, db.bagY = nil, nil, nil, nil
            if NS.MinimapSkin then NS.MinimapSkin:ApplyBag() end
        end },
    })

    Label(page, L["Какие кнопки собирать"])
    Note(page, L["Снимите галочку, и кнопка вернётся на миникарту. Новые кнопки появляются в списке, когда аддон их создаст."])

    local list = CreateFrame("Frame", nil, page)
    list:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    list:SetSize(PANEL_W - SIDE_W - 80, 1)
    local base = page.offset
    local rows = {}

    local function Refresh()
        local skin = NS.MinimapSkin
        if skin and skin.Candidates and _G.Minimap then skin:Candidates() end

        local names = {}
        local seen = {}
        for name in pairs(skin and skin.KnownButtons and skin:KnownButtons() or {}) do
            if not seen[name] then seen[name] = true names[#names + 1] = name end
        end
        for name in pairs(db.bagExclude or {}) do
            if not seen[name] then seen[name] = true names[#names + 1] = name end
        end
        table.sort(names)

        for _, row in pairs(rows) do row:Hide() end

        for index, name in ipairs(names) do
            local row = rows[name]
            if not row then
                local label = name:gsub("^LibDBIcon10_", "")
                row = NS.Widgets.CreateThemedCheckbox(list, label, not (db.bagExclude and db.bagExclude[name]), function(val)
                    db.bagExclude = db.bagExclude or {}
                    db.bagExclude[name] = (not val) or nil
                    if NS.MinimapSkin then
                        NS.MinimapSkin.bagDirty = true
                        NS.MinimapSkin:Collect()
                    end
                end)
                rows[name] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(index - 1) * 24)
            row:Show()
        end

        local height = math.max(1, #names * 24)
        list:SetHeight(height)
        page:SetHeight(-base + height + 20)
    end

    page.scroll:HookScript("OnShow", Refresh)
    page.offset = page.offset - 24
end

local function BuildMerchant(page)
    local db = NS.db

    Section(page, L["Торговцы"])

    Label(page, L["Вид торговца"])

    local merchantPicker
    merchantPicker = Picker(page, {
        { key = "window", label = L["Окно"] },
        { key = "scene",  label = L["Как диалог"] },
    }, db.merchantStyle == "scene" and "scene" or "window", function(value)
        db.merchantStyle = value
        merchantPicker:Refresh(value)
    end)

    Note(page, L["Вид применяется при следующем разговоре с торговцем."])

    Check(page, L["Окно торговца в стиле аддона"], db.skinMerchant ~= false, function(val)
        db.skinMerchant = val
        NS.Print(L["Нужен /reload"])
    end)

    Section(page, L["Товары"])

    Check(page, L["Названия цветом качества"], db.merchantQualityNames, function(val)
        db.merchantQualityNames = val
        if NS.MerchantSkin and NS.MerchantSkin.Paint then pcall(NS.MerchantSkin.Paint, NS.MerchantSkin) end
    end)

    Slider(page, L["Подкраска карточек цветом качества"], 0, 40, 5, db.merchantTint or 0, function(val)
        db.merchantTint = val
        if NS.MerchantSkin and NS.MerchantSkin.Paint then pcall(NS.MerchantSkin.Paint, NS.MerchantSkin) end
    end, "%")

    Note(page, L["Работает в окне торговца в стиле аддона. Обычные (белые) и серые вещи не подкрашиваются."])
end

local function BuildInspect(page)
    local db = NS.db

    Section(page, L["Осмотр"])

    Label(page, L["Вид окна осмотра"])

    local inspectPicker
    inspectPicker = Picker(page, {
        { key = "window", label = L["Окно клиента"] },
        { key = "scene",  label = L["Как окно персонажа"] },
    }, db.inspectStyle == "window" and "window" or "scene", function(value)
        db.inspectStyle = value
        inspectPicker:Refresh(value)
    end)

    Note(page, L["Вид применяется при следующем осмотре. В самой сцене есть кнопка, которая открывает обычное окно для текущего осмотра."])

    if type(db.inspect) ~= "table" then db.inspect = {} end
    local opts = db.inspect

    Section(page, L["Сцена осмотра"])

    Slider(page, L["Затемнение мира"], 0, 100, 5, opts.dim or 62, function(val)
        opts.dim = val
        if NS.InspectScene and NS.InspectScene.ApplyLook then NS.InspectScene:ApplyLook() end
    end, "%")

    Label(page, L["Подсветка за моделью"])
    local lightPicker
    lightPicker = Picker(page, {
        { key = "cold",  label = L["холодная"] },
        { key = "theme", label = L["цвет темы"] },
        { key = "class", label = L["цвет класса"] },
        { key = "off",   label = L["выкл"] },
    }, opts.light or "cold", function(value)
        opts.light = value
        lightPicker:Refresh(value)
        if NS.InspectScene and NS.InspectScene.ApplyLook then NS.InspectScene:ApplyLook() end
    end, nil, PV("Light"))

    Slider(page, L["Сила подсветки"], 5, 60, 5, opts.lightPower or 20, function(val)
        opts.lightPower = val
        if NS.InspectScene and NS.InspectScene.ApplyLook then NS.InspectScene:ApplyLook() end
    end, "%")

    Label(page, L["Вкладка при открытии"])
    local tabPicker
    tabPicker = Picker(page, {
        { key = "last",    label = L["последняя"] },
        { key = "talents", label = L["Таланты"] },
        { key = "glyphs",  label = L["Символы"] },
        { key = "pvp",     label = L["PvP"] },
        { key = "guild",   label = L["Гильдия"] },
    }, opts.startTab or "last", function(value)
        opts.startTab = value
        tabPicker:Refresh(value)
    end)

    Check(page, L["Прятать интерфейс во время осмотра"], opts.hideHUD ~= false, function(val)
        opts.hideHUD = val
    end)
end

local function BuildClientWindows(page)
    local db = NS.db

    Section(page, L["Окна клиента"])

    Note(page, L["Перекраска окон, которые рисует клиент."])

    Check(page, L["Скин окон меню"], db.skinMenus ~= false, function(val)
        db.skinMenus = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Скин магазина"], db.skinStore ~= false, function(val)
        db.skinStore = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Почта в стиле аддона"], db.skinMail ~= false, function(val)
        db.skinMail = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Учителя в стиле аддона"], db.skinTrainer ~= false, function(val)
        db.skinTrainer = val
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Аукцион в стиле аддона"], db.skinAuction ~= false, function(val)
        db.skinAuction = val
        NS.Print(L["Нужен /reload"])
    end)

    for _, entry in ipairs({
        { "skinReadyCheck", "Проверка готовности в стиле аддона" },
        { "skinTrade", "Обмен в стиле аддона" },
        { "skinTradeSkill", "Окно профессии в стиле аддона" },
        { "skinLootTracker", "Трекер добычи RaidRoll в стиле аддона" },
    }) do
        Check(page, L[entry[2]], db[entry[1]] ~= false, function(val)
            db[entry[1]] = val
            NS.Print(L["Нужен /reload"])
        end)
    end

    Section(page, L["Прочие окна клиента"])
    for _, entry in ipairs(NS.WindowSkins and NS.WindowSkins.EXTRA or {}) do
        Check(page, L[entry.label], db[entry.flag] ~= false, function(val)
            db[entry.flag] = val
            NS.Print(L["Нужен /reload"])
        end)
    end

    Buttons(page, {
        { label = L["Перерисовать окна"], action = function()
            if NS.MenuSkins then NS.MenuSkins:Redo() end
        end },
        { label = L["Состояние"], action = function()
            if NS.MenuSkins then NS.MenuSkins:Status() end
        end },
    })

    Section(page, L["Задания и карта"])

    local quests = db.quests or {}

    Check(page, L["Свой журнал заданий"], quests.replaceLog ~= false, function(val)
        quests.replaceLog = val
        NS.Print(L["Нужен /reload"])
    end)

end

local function BuildWorldMap(page)
    local quests = NS.db.quests or {}

    Section(page, L["Карта мира"])

    Check(page, L["Карта в стиле аддона"], quests.skinWorldMap ~= false, function()
        if NS.WorldMapSkin then NS.WorldMapSkin:Toggle() end
    end)

    Check(page, L["Компактная карта мира"], quests.compactMap ~= false, function(val)
        quests.compactMap = val
        if not val then SetCVar("miniWorldMap", "0") end
        NS.Print(L["Нужен /reload"])
    end)

    Check(page, L["Показывать неоткрытые области"], quests.revealMap ~= false, function(val)
        quests.revealMap = val
        if NS.WorldMapSkin then NS.WorldMapSkin:RevealFog() end
    end)

    Label(page, L["Цвет неоткрытых областей"])
    local fogPicker
    fogPicker = Picker(page, {
        { key = "grey",   label = L["серый"] },
        { key = "bright", label = L["как открытые"] },
        { key = "dark",   label = L["тёмный"] },
        { key = "sepia",  label = L["сепия"] },
        { key = "theme",  label = L["цвет темы"] },
    }, quests.fogColor or "grey", function(value)
        quests.fogColor = value
        fogPicker:Refresh(value)
        if NS.WorldMapSkin then NS.WorldMapSkin:RevealFog() end
    end, nil, PV("Fog"))

    Slider(page, L["Яркость неоткрытых областей"], 20, 100, 5, quests.fogAlpha or 85, function(val)
        quests.fogAlpha = val
        if NS.WorldMapSkin then NS.WorldMapSkin:RevealFog() end
    end, "%")

    Label(page, L["Координаты"])

    Check(page, L["Показывать координаты игрока и курсора"], quests.mapCoords ~= false, function(val)
        quests.mapCoords = val
    end)

    local digitsPicker
    digitsPicker = Picker(page, {
        { key = 0, label = L["целые"] },
        { key = 1, label = L["1 знак"] },
        { key = 2, label = L["2 знака"] },
    }, quests.mapCoordDigits or 1, function(value)
        quests.mapCoordDigits = value
        digitsPicker:Refresh(value)
    end)

    Slider(page, L["Прозрачность карты на ходу"], 20, 100, 5, quests.mapMoveAlpha or 100, function(val)
        quests.mapMoveAlpha = val
    end, "%")

    Note(page, L["Пока персонаж движется, карта становится прозрачнее, чтобы был виден путь; при наведении мыши она снова плотная. 100% - выключено."])

    Label(page, L["Окно"])

    Note(page, L["Масштаб также меняется колесом мыши с зажатым Ctrl над заголовком карты."])

    Slider(page, L["Масштаб карты"], 60, 200, 5, math.floor((quests.mapScale or 1.2) * 100 + 0.5), function(val)
        if NS.WorldMapSkin then NS.WorldMapSkin:SetScale(val / 100) end
    end, "%")

    Buttons(page, {
        { label = L["Карту в центр"], action = function()
            if NS.WorldMapSkin then NS.WorldMapSkin:CenterWindow() end
        end, width = 150 },
        { label = L["Открыть карту"], action = function()
            if ToggleFrame and WorldMapFrame then ToggleFrame(WorldMapFrame) end
        end, width = 150 },
    })
end

local function BuildActions(page)
    Section(page, L["Панели"])

    Buttons(page, {
        { label = L["Характеристики"], action = function() NS:ToggleStatsPanel() end },
        { label = L["Титулы"], action = function() NS:ToggleTitleManager() end },
        { label = L["Превью"], action = function() NS:ToggleCharPreview() end },
    })

    Buttons(page, {
        { label = L["Быстрые наборы"], action = function() NS:ToggleOutfitManager() end },
    })

    Section(page, L["Скриншот"])

    Check(page, L["Прятать интерфейс на снимке"], NS.db.shotHideUI ~= false, function(val)
        NS.db.shotHideUI = val and true or false
    end)

    Slider(page, L["Отсчёт перед снимком, сек"], 1, 10, 1, NS.db.shotDelay or 3, function(val)
        NS.db.shotDelay = val
    end)

    Buttons(page, {
        { label = L["Снять сейчас"], action = function()
            if NS.settingsFrame then NS.settingsFrame:Hide() end
            NS.After(0.3, function() NS.ScreenshotTool:Take(NS.db.shotHideUI ~= false) end)
        end },
        { label = L["С отсчётом"], action = function()
            if NS.settingsFrame then NS.settingsFrame:Hide() end
            NS.ScreenshotTool:TakeWithCountdown(NS.db.shotDelay or 3, NS.db.shotHideUI ~= false)
        end },
    })

    Section(page, L["Подсказки к характеристикам"])

    Check(page, L["Показывать подсказки при наведении на характеристику"], NS.db.statTips ~= false, function(val)
        NS.db.statTips = val and true or false
    end)

    Label(page, L["Где показывать"])
    local tipPicker
    tipPicker = Picker(page, {
        { key = "left",   label = L["слева"] },
        { key = "right",  label = L["справа"] },
        { key = "cursor", label = L["у курсора"] },
    }, NS.db.statTipAnchor or "left", function(value)
        tipPicker:Refresh(value)
        NS.db.statTipAnchor = value
    end)
end

local function SampleText(parent, text, size, color, point, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(NS.FONT, NS.FS(size), "")
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetPoint(point, parent, point, x, y)
    fs:SetText(text)
    return fs
end

local function SampleTitle(win, text)
    local S = Style()
    local title = win:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(14), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", win, "TOP", 0, -13)
    title:SetText(text)
    return title
end

local function SampleBadge(win)
    local banner = win.tabBanner
    if not (banner and banner.hex) then return end
    banner.hex:SetScale(0.7)
    banner.hex:ClearAllPoints()
    banner.hex:SetPoint("CENTER", banner.edge, "RIGHT", -20 / 0.7, 0)
end

local function SamplePlateRow(win, i, top, left, right)
    local S = Style()
    local row = CreateFrame("Frame", nil, win)
    row:SetPoint("TOPLEFT", win, "TOPLEFT", 10, top - (i - 1) * 18)
    row:SetPoint("TOPRIGHT", win, "TOPRIGHT", -10, top - (i - 1) * 18)
    row:SetHeight(17)
    if NS.TabStyle then NS.TabStyle.Plate(row, nil, i) end
    SampleText(row, left, 10, S.TEXT_NORMAL, "LEFT", 6, 0)
    SampleText(row, right, 10, S.TEXT_BRIGHT, "RIGHT", -6, 0)
    return row
end

local SAMPLE_W = 222

local STYLE_SAMPLES = {
    {
        title = "Вкладка персонажа", height = 126,
        build = function(holder)
            local S = Style()
            local win = CreateFrame("Frame", nil, holder)
            win:SetPoint("TOPLEFT")
            S.ApplyPanelStyle(win, SAMPLE_W, 126)
            S.ApplyTabChrome(win)
            SampleTitle(win, L["Валюта"])
            if NS.TabStyle then
                NS.TabStyle.Header(win, { art = "BannerCurrency", height = 34, right = 8, left = 8, badge = function() return 12 end })
                SampleBadge(win)
            end
            S.CreateAnimatedSeparator(win, -48)
            SamplePlateRow(win, 1, -56, L["Золото"], "1520")
            SamplePlateRow(win, 2, -56, L["Эмблемы льда"], "245")
            SamplePlateRow(win, 3, -56, L["Очки чести"], "9800")
        end,
    },
    {
        title = "Список с полосами", height = 104,
        build = function(holder)
            local S = Style()
            local win = CreateFrame("Frame", nil, holder)
            win:SetPoint("TOPLEFT")
            S.ApplyPanelStyle(win, SAMPLE_W, 104)
            local factions = { { L["Серебряный Авангард"], 1.0 }, { L["Рыцари Черного Клинка"], 0.62 }, { L["Кирин-Тор"], 0.35 }, { L["Сыновья Ходира"], 0.8 } }
            for i, data in ipairs(factions) do
                local row = CreateFrame("Frame", nil, win)
                row:SetPoint("TOPLEFT", win, "TOPLEFT", 10, -14 - (i - 1) * 21)
                row:SetPoint("TOPRIGHT", win, "TOPRIGHT", -10, -14 - (i - 1) * 21)
                row:SetHeight(19)
                if NS.TabStyle then NS.TabStyle.Plate(row, nil, i) end
                SampleText(row, data[1], 9, S.TEXT_NORMAL, "LEFT", 6, 0)
                local bg = row:CreateTexture(nil, "ARTWORK")
                bg:SetSize(64, 7)
                bg:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                bg:SetVertexColor(0, 0, 0, 0.5)
                local fill = row:CreateTexture(nil, "OVERLAY")
                fill:SetSize(64 * data[2], 7)
                fill:SetPoint("LEFT", bg, "LEFT", 0, 0)
                fill:SetTexture("Interface\\Buttons\\WHITE8x8")
                fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
                if NS.TabStyle then
                    NS.TabStyle.Row(bg, 3)
                    NS.TabStyle.Row(fill, 3)
                end
            end
        end,
    },
    {
        title = "Кнопки и поля", height = 92,
        build = function(holder)
            local S = Style()
            local win = CreateFrame("Frame", nil, holder)
            win:SetPoint("TOPLEFT")
            S.ApplyPanelStyle(win, SAMPLE_W, 92)
            local ok = NS.Widgets.CreateThemedButton(win, L["Принять"], 92, 22)
            ok:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -14)
            ok:EnableMouse(false)
            local cancel = NS.Widgets.CreateThemedButton(win, L["Отмена"], 92, 22, nil, { 0.85, 0.35, 0.35 })
            cancel:SetPoint("TOPRIGHT", win, "TOPRIGHT", -14, -14)
            cancel:EnableMouse(false)
            S.CreateAnimatedSeparator(win, -46)
            local box = NS.Widgets.CreateThemedEditBox(win, 120, 22, 20)
            box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -56)
            box:SetText(L["Набор 1"])
            box:EnableMouse(false)
            local plus = NS.Widgets.CreateThemedButton(win, "+", 22, 22)
            plus:SetPoint("LEFT", box, "RIGHT", 8, 0)
            plus:EnableMouse(false)
        end,
    },
    {
        title = "Диалог", height = 96,
        build = function(holder)
            local S = Style()
            local win = CreateFrame("Frame", nil, holder)
            win:SetPoint("TOPLEFT")
            S.ApplyPanelStyle(win, SAMPLE_W, 96)
            S.ApplyTabChrome(win)
            local text = win:CreateFontString(nil, "OVERLAY")
            text:SetFont(NS.FONT, NS.FS(10), "")
            text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            text:SetPoint("TOP", win, "TOP", 0, -20)
            text:SetWidth(SAMPLE_W - 30)
            text:SetText(L["Сбросить все усиления за 200 золотых?"])
            local yes = NS.Widgets.CreateThemedButton(win, L["Сбросить"], 86, 22)
            yes:SetPoint("BOTTOMRIGHT", win, "BOTTOM", -5, 14)
            yes:EnableMouse(false)
            local no = NS.Widgets.CreateThemedButton(win, L["Отмена"], 86, 22)
            no:SetPoint("BOTTOMLEFT", win, "BOTTOM", 5, 14)
            no:EnableMouse(false)
        end,
    },
    {
        title = "Шапки вкладок", height = 4 * 44 - 4,
        build = function(holder)
            local S = Style()
            local heads = {
                { "Усиления", "BannerEnhance" }, { "Профессии", "BannerProfessions" },
                { "Титулы", "BannerTitles" }, { "Репутация", "BannerReputation" },
            }
            for i, data in ipairs(heads) do
                local win = CreateFrame("Frame", nil, holder)
                win:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(i - 1) * 44)
                S.ApplyPanelStyle(win, SAMPLE_W, 40)
                SampleTitle(win, L[data[1]]):SetPoint("TOP", win, "TOP", 0, -12)
                if NS.TabStyle then NS.TabStyle.Header(win, { art = data[2], height = 28, right = 6, left = 6 }) end
            end
        end,
    },
}

local function BuildStyle(page)
    local db = NS.db
    db.theme = db.theme or {}
    local theme = db.theme
    local S = Style()
    local loaded = theme.decor or "styled"
    local GAP = 16
    local CARD_H = 70

    Note(page, L["Выберите вид окон аддона. Ниже - настоящие образцы обоих вариантов, нарисованные теми же средствами, что и сами окна. Стиль применяется после перезагрузки интерфейса."])

    local applyButton = NS.Widgets.CreateThemedButton(page, L["Применить и перезагрузить"], SAMPLE_W * 2 + GAP, 24, function()
        ReloadUI()
    end)

    local options = {
        { key = "classic", label = L["Обычный"], text = L["Прежний плоский вид: ровные линии и рамки, без картинок и узоров."] },
        { key = "styled", label = L["Стилизованный"], text = L["Картинки в шапках, шестиугольные значки, узорные уголки, гребень, орнамент и блики."] },
    }

    local top = page.offset
    local bodyH = 0
    for _, sample in ipairs(STYLE_SAMPLES) do bodyH = bodyH + 22 + sample.height + 10 end
    local columnH = CARD_H + 10 + bodyH

    local columns = {}
    local function Refresh()
        local current = theme.decor or "styled"
        for _, col in ipairs(columns) do
            local on = col.key == current
            local A = on and S.ACCENT or S.BORDER
            col.card:SetBackdropBorderColor(A[1], A[2], A[3], on and 0.95 or 0.5)
            col.card:SetBackdropColor(S.ACCENT[1] * 0.22, S.ACCENT[2] * 0.22, S.ACCENT[3] * 0.22, on and 0.6 or 0.12)
            col.label:SetTextColor(unpack(on and S.ACCENT_GLOW or S.TEXT_NORMAL))
            col.wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], on and 0.07 or 0)
            col.edge:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], on and 0.35 or 0)
            if on then col.check:Show() col.pill:Show() else col.check:Hide() col.pill:Hide() end
        end
        if current ~= loaded then applyButton:Show() else applyButton:Hide() end
    end

    for i, option in ipairs(options) do
        local x = PAD + (i - 1) * (SAMPLE_W + GAP)
        local col = CreateFrame("Button", nil, page)
        col:SetPoint("TOPLEFT", page, "TOPLEFT", x - 6, top + 6)
        col:SetSize(SAMPLE_W + 12, columnH + 12)
        col.key = option.key

        local wash = col:CreateTexture(nil, "BACKGROUND")
        wash:SetAllPoints(col)
        wash:SetTexture("Interface\\Buttons\\WHITE8x8")
        col.wash = wash
        local edge = CreateFrame("Frame", nil, col)
        edge:SetAllPoints(col)
        edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        edge:EnableMouse(false)
        S.RoundCorners(edge, 6, { edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        col.edge = edge

        local card = CreateFrame("Frame", nil, col)
        card:SetPoint("TOPLEFT", col, "TOPLEFT", 6, -6)
        card:SetSize(SAMPLE_W, CARD_H)
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        S.RoundCorners(card, 6)
        col.card = card

        local label = card:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(15), "OUTLINE")
        label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -11)
        label:SetText(option.label)
        col.label = label

        local text = card:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(10), "")
        text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        text:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
        text:SetWidth(SAMPLE_W - 24)
        text:SetJustifyH("LEFT")
        text:SetText(option.text)

        local check = card:CreateTexture(nil, "OVERLAY")
        check:SetSize(16, 16)
        check:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
        check:SetTexture(S.Media("IconCheck"))
        check:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        col.check = check

        local pill = card:CreateFontString(nil, "OVERLAY")
        pill:SetFont(NS.FONT, NS.FS(9), "")
        pill:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        pill:SetPoint("RIGHT", check, "LEFT", -4, 0)
        pill:SetText(L["выбран"])
        col.pill = pill

        local hover = col:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints(col)
        hover:SetTexture("Interface\\Buttons\\WHITE8x8")
        hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

        col:SetScript("OnClick", function(self)
            theme.decor = self.key
            Refresh()
        end)
        columns[#columns + 1] = col
    end

    local y = top - CARD_H - 10
    for _, sample in ipairs(STYLE_SAMPLES) do
        local caption = page:CreateFontString(nil, "OVERLAY")
        caption:SetFont(NS.FONT, NS.FS(10), "")
        caption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        caption:SetPoint("TOP", page, "TOPLEFT", PAD + SAMPLE_W + GAP / 2, y - 4)
        caption:SetText(L[sample.title])
        for side = -1, 1, 2 do
            local rule = page:CreateTexture(nil, "ARTWORK")
            rule:SetHeight(1)
            rule:SetTexture("Interface\\Buttons\\WHITE8x8")
            rule:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.5)
            if side < 0 then
                rule:SetPoint("LEFT", page, "TOPLEFT", PAD + 6, y - 9)
                rule:SetPoint("RIGHT", caption, "LEFT", -8, 0)
            else
                rule:SetPoint("LEFT", caption, "RIGHT", 8, 0)
                rule:SetPoint("RIGHT", page, "TOPLEFT", PAD + SAMPLE_W * 2 + GAP - 6, y - 9)
            end
        end
        y = y - 22
        for i, col in ipairs(columns) do
            local saved = S.DECOR
            S.DECOR = col.key == "styled"
            local holder = CreateFrame("Frame", nil, col)
            holder:SetPoint("TOPLEFT", page, "TOPLEFT", PAD + (i - 1) * (SAMPLE_W + GAP), y)
            holder:SetSize(SAMPLE_W, sample.height)
            local ok, err = pcall(sample.build, holder)
            S.DECOR = saved
            if not ok then NS.Print(tostring(err)) end
        end
        y = y - sample.height - 10
    end

    page.offset = y - 12
    applyButton:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    page.offset = page.offset - 34
    Refresh()
end

local PREVIEW_CORNERS = {
    { "TOPLEFT", 1, -1, 0, 1, 0, 1 },
    { "TOPRIGHT", -1, -1, 1, 0, 0, 1 },
    { "BOTTOMLEFT", 1, 1, 0, 1, 1, 0 },
    { "BOTTOMRIGHT", -1, 1, 1, 0, 1, 0 },
}

local function StylePreview(page, theme)
    local S = Style()
    local W, H = 300, 220
    local host = _G.NarcissusSirus_SettingsFrame

    local p = CreateFrame("Frame", nil, page.scroll)
    p:SetSize(W, H)
    if host then
        p:SetPoint("TOPLEFT", host, "TOPRIGHT", 10, 0)
    else
        p:SetPoint("TOPLEFT", page.scroll, "TOPRIGHT", 40, 0)
    end
    p:SetFrameLevel((page.scroll:GetFrameLevel() or 0) + 10)

    local ground = p:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(p)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], 0.97)

    S.CreateEdges(p, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)

    local pattern = S.TileArea(p, "BORDER", -1, 2)

    local shade = p:CreateTexture(nil, "BORDER")
    shade:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
    shade:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
    shade:SetTexture(S.Media("DecorVignette"))

    local sheen = p:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
    sheen:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
    sheen:SetTexture(S.Media("DecorSheen"))
    sheen:SetBlendMode("ADD")

    local line = p:CreateTexture(nil, "OVERLAY")
    line:SetHeight(2)
    line:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -3)
    line:SetPoint("TOPRIGHT", p, "TOPRIGHT", -4, -3)
    line:SetTexture(WHITE)
    line:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)

    local header = p:CreateTexture(nil, "BORDER")
    header:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", line, "BOTTOMRIGHT", 0, 0)
    header:SetHeight(56)
    header:SetTexture(S.Media("DecorHeader"))
    header:SetBlendMode("ADD")
    local span = math.min(1, ((W - 8) / 56) / 16)
    header:SetTexCoord((1 - span) / 2, (1 + span) / 2, 0, 1)

    local crest = p:CreateTexture(nil, "OVERLAY")
    crest:SetSize(72, 18)
    crest:SetPoint("CENTER", line, "CENTER", 0, 0)
    crest:SetTexture(S.Media("DecorCrest"))

    local corners = {}
    for _, c in ipairs(PREVIEW_CORNERS) do
        local t = p:CreateTexture(nil, "OVERLAY")
        t:SetPoint(c[1], p, c[1], c[2] * 3, c[3] * 3)
        t:SetTexCoord(c[4], c[5], c[6], c[7])
        corners[#corners + 1] = t
    end

    local title = p:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(15), "")
    title:SetPoint("TOP", p, "TOP", 0, -16)
    title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    title:SetText(L["Пример окна"])

    local divider = p:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("LEFT", p, "TOPLEFT", 10, -48)
    divider:SetPoint("RIGHT", p, "TOPRIGHT", -10, -48)
    divider:SetTexture(WHITE)

    local rows = {}
    for index, text in ipairs({ L["Строка списка"], L["Ещё одна строка"], L["Третья строка"] }) do
        local row = p:CreateFontString(nil, "OVERLAY")
        row:SetFont(NS.FONT, NS.FS(11), "")
        row:SetPoint("TOPLEFT", p, "TOPLEFT", 18, -60 - (index - 1) * 22)
        row:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        row:SetText(text)
        rows[index] = row
    end

    local button = CreateFrame("Frame", nil, p)
    button:SetSize(150, 26)
    button:SetPoint("BOTTOM", p, "BOTTOM", 0, 22)
    local face = button:CreateTexture(nil, "BACKGROUND")
    face:SetAllPoints(button)
    face:SetTexture(WHITE)
    face:SetVertexColor(S.ACCENT[1] * 0.35, S.ACCENT[2] * 0.35, S.ACCENT[3] * 0.35, 0.95)
    S.CreateEdges(button, "BORDER", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.8)
    local gloss = button:CreateTexture(nil, "ARTWORK")
    gloss:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    gloss:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    gloss:SetTexture(S.Media("DecorGloss"))
    gloss:SetBlendMode("ADD")
    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(11), "")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    label:SetText(L["Кнопка"])

    local caption = p:CreateFontString(nil, "OVERLAY")
    caption:SetFont(NS.FONT, NS.FS(10), "")
    caption:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 2, -6)
    caption:SetWidth(W - 4)
    caption:SetJustifyH("LEFT")
    caption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    caption:SetText(L["Так окна будут выглядеть после перезагрузки в стилизованном виде."])

    function p:Refresh()
        local tint = theme.decorTint or "accent"
        local br, bg, bb = S.DecorColorFor(tint, true)
        local dr, dg, db = S.DecorColorFor(tint, false)

        local size = theme.decorCornerSize or 30
        local cornerPath = S.Media(S.CORNER_STYLES[theme.decorCornerStyle or "filigree"] or "DecorCorner")
        for _, t in ipairs(corners) do
            t:SetSize(size, size)
            t:SetTexture(cornerPath)
            t:SetVertexColor(br, bg, bb, 0.8)
            t:SetShown(theme.decorCorners ~= false)
        end

        crest:SetVertexColor(br, bg, bb, 0.95)
        crest:SetShown(theme.decorCrest ~= false)

        if tint == "accent" then
            header:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.16)
        else
            header:SetVertexColor(dr, dg, db, 0.16)
        end
        header:SetShown(theme.decorHeader ~= false)

        divider:ClearAllPoints()
        if theme.decorDivider ~= false then
            divider:SetHeight(10)
            divider:SetPoint("LEFT", p, "TOPLEFT", 10, -48)
            divider:SetPoint("RIGHT", p, "TOPRIGHT", -10, -48)
            divider:SetTexture(S.Media(S.DIVIDER_STYLES[theme.decorDividerStyle or "filigree"] or "DecorDivider"))
            divider:SetVertexColor(dr, dg, db, 0.85)
        else
            divider:SetHeight(1)
            divider:SetPoint("LEFT", p, "TOPLEFT", 10, -48)
            divider:SetPoint("RIGHT", p, "TOPRIGHT", -10, -48)
            divider:SetTexture(WHITE)
            divider:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
        end

        gloss:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
        gloss:SetShown(theme.decorGloss ~= false)

        local patternKey = S.PATTERNS[theme.decorPattern or "none"]
        if patternKey then
            pattern:SetVertexColor(br, bg, bb, (theme.decorPatternAlpha or 25) / 100)
            pattern:SetTexture(S.Media(patternKey))
            pattern:Show()
        else
            pattern:Hide()
        end

        local sheenValue = (theme.decorSheen or 100) / 100
        sheen:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.09 * sheenValue)
        sheen:SetShown(sheenValue > 0)

        local shadeValue = (theme.decorShade or 100) / 100
        shade:SetVertexColor(0, 0, 0, math.min(1, 0.5 * shadeValue))
        shade:SetShown(shadeValue > 0)
    end

    p:Refresh()
    return p
end

local function BuildStyleDetails(page)
    local db = NS.db
    db.theme = db.theme or {}
    local theme = db.theme

    local applyButton
    local preview

    local function Store(key, value)
        theme[key] = value
        if applyButton then applyButton:Show() end
        if preview then preview:Refresh() end
    end

    local function Flag(text, key)
        Check(page, text, theme[key] ~= false, function(val) Store(key, val and true or false) end)
    end

    local function Choice(label, key, options, fallback)
        Label(page, label)
        local picker
        picker = Picker(page, options, theme[key] or fallback, function(value)
            picker:Refresh(value)
            Store(key, value)
        end)
    end

    Note(page, L["Тонкая настройка стилизованного вида. Работает, когда на странице «Стиль» выбран стилизованный вариант, и применяется после перезагрузки интерфейса."])

    applyButton = NS.Widgets.CreateThemedButton(page, L["Применить и перезагрузить"], 220, 24, function()
        ReloadUI()
    end)
    applyButton:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    applyButton:Hide()
    page.offset = page.offset - 34

    preview = StylePreview(page, theme)

    Section(page, L["Орнамент окон"])
    Flag(L["Узоры в углах окон"], "decorCorners")
    Slider(page, L["Размер узоров в углах"], 20, 44, 2, theme.decorCornerSize or 30, function(val)
        Store("decorCornerSize", val)
    end)
    Flag(L["Герб на верхней линии"], "decorCrest")
    Flag(L["Узор в шапке окна"], "decorHeader")
    Flag(L["Разделители с орнаментом"], "decorDivider")
    Flag(L["Блеск на кнопках"], "decorGloss")
    Choice(L["Цвет орнамента"], "decorTint", {
        { key = "accent", label = L["цвет темы"] },
        { key = "gold",   label = L["золото"] },
        { key = "silver", label = L["серебро"] },
        { key = "bronze", label = L["бронза"] },
        { key = "white",  label = L["белый"] },
    }, "accent")

    Choice(L["Вид узоров в углах"], "decorCornerStyle", WithExtras({
        { key = "filigree", label = L["вязь"] },
        { key = "rune",     label = L["руны"] },
        { key = "leaf",     label = L["листья"] },
        { key = "geo",      label = L["геометрия"] },
    }, NS.Styling.Extras("corners")), "filigree")
    Choice(L["Вид разделителей"], "decorDividerStyle", WithExtras({
        { key = "filigree", label = L["вязь"] },
        { key = "chain",    label = L["цепь"] },
        { key = "orb",      label = L["сфера"] },
        { key = "wave",     label = L["волна"] },
    }, NS.Styling.Extras("dividers")), "filigree")

    Section(page, L["Узор фона окон"])
    Choice(L["Узор"], "decorPattern", WithExtras({
        { key = "none",   label = L["нет"] },
        { key = "dots",   label = L["точки"] },
        { key = "diag",   label = L["диагональ"] },
        { key = "grid",   label = L["сетка"] },
        { key = "carbon", label = L["карбон"] },
        { key = "scales", label = L["чешуя"] },
        { key = "noise",  label = L["дымка"] },
    }, NS.Styling.Extras("patterns")), "none")
    Slider(page, L["Заметность узора"], 5, 80, 1, theme.decorPatternAlpha or 25, function(val)
        Store("decorPatternAlpha", val)
    end, "%")

    Section(page, L["Свет и тень"])
    Slider(page, L["Блик на окнах"], 0, 200, 10, theme.decorSheen or 100, function(val)
        Store("decorSheen", val)
    end, "%")
    Slider(page, L["Затенение краёв окон"], 0, 200, 10, theme.decorShade or 100, function(val)
        Store("decorShade", val)
    end, "%")

    Section(page, L["Окно персонажа"])
    Flag(L["Картинки в шапках вкладок"], "tabBanners")
    Slider(page, L["Яркость картинок"], 20, 100, 5, theme.bannerAlpha or 100, function(val)
        Store("bannerAlpha", val)
    end, "%")
    Flag(L["Шестиугольный значок в шапке"], "tabBadges")
    Choice(L["Форма кнопок панели инструментов"], "toolbarShape", {
        { key = "auto",   label = L["по стилю"] },
        { key = "hex",    label = L["шестиугольник"] },
        { key = "square", label = L["квадрат"] },
    }, "auto")

    Buttons(page, {
        { label = L["Сбросить детали"], width = 180, action = function()
            for _, key in ipairs({ "decorCorners", "decorCornerSize", "decorCrest", "decorHeader", "decorDivider",
                "decorGloss", "decorTint", "decorSheen", "decorShade", "tabBanners", "bannerAlpha", "tabBadges",
                "toolbarShape", "decorPattern", "decorPatternAlpha", "decorCornerStyle", "decorDividerStyle" }) do
                theme[key] = nil
            end
            ReloadUI()
        end },
    })
end

local function BuildCharSlots(page)
    local db = NS.db

    local function Live()
        if NS.NarciUI then
            if NS.NarciUI.UpdateSlots then NS.NarciUI:UpdateSlots() end
            if NS.NarciUI.ApplyBacklight then NS.NarciUI:ApplyBacklight() end
        end
    end

    Note(page, L["Всё на этой странице применяется сразу, перезагрузка не нужна."])

    Section(page, L["Названия предметов"])
    Slider(page, L["Размер шрифта названий"], 10, 16, 1, db.slotNameSize or 13, function(val)
        db.slotNameSize = val
        Live()
    end)
    Check(page, L["Тёмная подложка под названиями"], db.slotNamePlate ~= false, function(val)
        db.slotNamePlate = val and true or false
        Live()
    end)
    Slider(page, L["Плотность подложки"], 0, 100, 5, db.slotPlateAlpha or 75, function(val)
        db.slotPlateAlpha = val
        Live()
    end, "%")

    Section(page, L["Слоты"])
    Label(page, L["Форма слотов"])
    local shapePicker
    shapePicker = Picker(page, WithExtras({
        { key = "square",  label = L["квадрат"] },
        { key = "circle",  label = L["круг"] },
        { key = "hex",     label = L["шестиугольник"] },
        { key = "octa",    label = L["восьмиугольник"] },
        { key = "diamond", label = L["ромб"] },
        { key = "shield",  label = L["щит"] },
        { key = "ornate",  label = L["кольцо с рунами"] },
        { key = "classic", label = L["как в клиенте"] },
    }, UIExtras("shapes")), db.slotShape or "square", function(value)
        db.slotShape = value
        shapePicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "slotShape", PV("Scene")))
    Label(page, L["Цвет рамки фигурных слотов"])
    local ringPicker
    ringPicker = Picker(page, {
        { key = "quality", label = L["качество предмета"] },
        { key = "accent",  label = L["цвет темы"] },
    }, db.slotRingColor or "quality", function(value)
        db.slotRingColor = value
        ringPicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "slotRingColor", PV("Scene")))
    Check(page, L["Цветной шлейф качества"], db.slotTrail ~= false, function(val)
        db.slotTrail = val and true or false
        Live()
    end)
    Slider(page, L["Яркость шлейфа"], 0, 100, 5, db.slotTrailAlpha or 40, function(val)
        db.slotTrailAlpha = val
        Live()
    end, "%")
    Slider(page, L["Видимость пустых слотов"], 10, 100, 5, db.emptySlotAlpha or 75, function(val)
        db.emptySlotAlpha = val
        Live()
    end, "%")

    Section(page, L["Подсветка за моделью"])
    Label(page, L["Цвет подсветки"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "cool",   label = L["холодный"] },
        { key = "warm",   label = L["тёплый"] },
        { key = "white",  label = L["белый"] },
        { key = "rose",   label = L["розовый"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
    }, db.backlightColor or "cool", function(value)
        db.backlightColor = value
        colorPicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "backlightColor", PV("Scene")))
    Slider(page, L["Сила подсветки"], 0, 250, 10, db.backlightPower or 100, function(val)
        db.backlightPower = val
        Live()
    end, "%")
    Label(page, L["Вид подсветки"])
    local stylePicker
    stylePicker = Picker(page, WithExtras({
        { key = "glow", label = L["свечение"] },
        { key = "rays", label = L["лучи"] },
        { key = "halo", label = L["ореол"] },
    }, UIExtras("backlights")), db.backlightStyle or "glow", function(value)
        db.backlightStyle = value
        stylePicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "backlightStyle", PV("Scene")))

    Section(page, L["Круг под ногами"])
    local floorPicker
    floorPicker = Picker(page, WithExtras({
        { key = "none",  label = L["нет"] },
        { key = "runes", label = L["рунный круг"] },
        { key = "glow",  label = L["пятно света"] },
    }, UIExtras("floors")), db.modelFloor or "none", function(value)
        db.modelFloor = value
        floorPicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "modelFloor", PV("Scene")))
    Slider(page, L["Размер круга"], 200, 560, 10, db.floorSize or 360, function(val)
        db.floorSize = val
        Live()
    end)
    Slider(page, L["Высота круга"], -320, -100, 5, db.floorY or -205, function(val)
        db.floorY = val
        Live()
    end)
    Check(page, L["Медленно вращать круг и лучи"], db.modelSpin ~= false, function(val)
        db.modelSpin = val and true or false
        Live()
    end)
end

local function BuildBrand(page)
    local S = Style()
    local db = S.Brand()

    local function Changed()
        S.BrandChanged()
    end

    Note(page, L["Своё название вместо логотипа NarciUI, девиз и эмблема. Применяются сразу: заголовок окна настроек, окно персонажа и экран AFK."])

    local preview = CreateFrame("Frame", nil, page)
    preview:SetSize(PANEL_W - SIDE_W - 80, 110)
    preview:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, page.offset)
    local ground = preview:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(preview)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(S.Tint(0.03, 0.03, 0.05, 0.9))
    S.RoundTexture(ground, 6)
    local glow = preview:CreateTexture(nil, "BORDER")
    glow:SetSize(110, 110)
    glow:SetPoint("LEFT", preview, "LEFT", 4, 0)
    glow:SetBlendMode("ADD")
    local emblem = preview:CreateTexture(nil, "ARTWORK")
    emblem:SetSize(76, 76)
    emblem:SetPoint("CENTER", glow, "CENTER", 0, 0)
    local word = preview:CreateTexture(nil, "ARTWORK")
    word:SetSize(200, 50)
    word:SetPoint("TOPLEFT", preview, "TOPLEFT", 112, -18)
    local wordText = preview:CreateFontString(nil, "ARTWORK")
    wordText:SetPoint("LEFT", word, "LEFT", 6, 0)
    local motto = preview:CreateFontString(nil, "ARTWORK")
    motto:SetFont(NS.FONT, NS.FS(12), "")
    motto:SetPoint("TOPLEFT", word, "BOTTOMLEFT", 6, -4)
    local function Paint()
        S.PaintEmblem(emblem, glow, 0.3)
        S.PaintWordmark(word, wordText)
        local _, _, _, r, g, b = S.BrandColor()
        local text = S.BrandMotto()
        motto:SetText(text and ("\"" .. text .. "\"") or "")
        motto:SetTextColor(r, g, b, 0.9)
    end
    Paint()
    S.WatchBrand(Paint)
    page.offset = page.offset - 122

    Section(page, L["Подпись"])
    TextInput(page, L["Название интерфейса (пусто - логотип NarciUI)"], db.name, function(text)
        db.name = text
        Changed()
    end, 24)
    TextInput(page, L["Девиз"], db.motto, function(text)
        db.motto = text
        Changed()
    end, 60)
    Check(page, L["Девиз под именем в окне персонажа"], db.mottoChar ~= false, function(val)
        db.mottoChar = val and true or false
        Changed()
    end)
    Check(page, L["Девиз на экране AFK"], db.mottoAFK ~= false, function(val)
        db.mottoAFK = val and true or false
        Changed()
    end)

    Section(page, L["Эмблема"])
    local emblemPicker
    emblemPicker = Picker(page, {
        { key = "narcissus", label = L["нарцисс"] },
        { key = "star",      label = L["звезда"] },
        { key = "moon",      label = L["луна"] },
        { key = "shield",    label = L["щит"] },
        { key = "flame",     label = L["пламя"] },
        { key = "crown",     label = L["корона"] },
        { key = "class",     label = L["значок класса"] },
    }, db.emblem or "narcissus", function(value)
        db.emblem = value
        emblemPicker:Refresh(value)
        Changed()
    end, nil, PV("With", "brand", "emblem", PV("Brand")))
    Label(page, L["Оправа эмблемы"])
    local framePicker
    framePicker = Picker(page, {
        { key = "crest",   label = L["орнамент"] },
        { key = "hex",     label = L["шестигранник"] },
        { key = "circle",  label = L["круг"] },
        { key = "diamond", label = L["ромб"] },
        { key = "badge",   label = L["геральдический щит"] },
        { key = "runic",   label = L["руническое кольцо"] },
        { key = "laurel",  label = L["венец"] },
        { key = "medal",   label = L["медальон"] },
        { key = "bare",    label = L["без оправы"] },
    }, db.frame or "crest", function(value)
        db.frame = value
        framePicker:Refresh(value)
        Changed()
    end, nil, PV("With", "brand", "frame", PV("Brand")))
    Note(page, L["Оправа не действует на значок класса. Новые картинки появляются только после полного перезапуска игры (выход на рабочий стол), /reload их не подхватывает."])
    Slider(page, L["Свечение эмблемы"], 0, 200, 10, db.glow or 100, function(val)
        db.glow = val
        Changed()
    end, "%")
    Label(page, L["Цвет подписи и эмблемы"])
    local colorPicker
    colorPicker = Picker(page, {
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
        { key = "gold",   label = L["золото"] },
        { key = "silver", label = L["серебро"] },
        { key = "white",  label = L["белый"] },
    }, db.color or "accent", function(value)
        db.color = value
        colorPicker:Refresh(value)
        Changed()
    end, nil, PV("With", "brand", "color", PV("Brand")))
end

local function BuildCharScene(page)
    local db = NS.db

    local function Live()
        if NS.NarciUI and NS.NarciUI.ApplyScene then NS.NarciUI:ApplyScene() end
    end

    Note(page, L["Всё на этой странице применяется сразу, перезагрузка не нужна. Откройте окно персонажа рядом, чтобы видеть изменения."])

    Section(page, L["Фон за моделью"])
    local backPicker
    backPicker = Picker(page, {
        { key = "none",   label = L["нет, виден мир"] },
        { key = "dusk",   label = L["сумерки"] },
        { key = "abyss",  label = L["бездна"] },
        { key = "ember",  label = L["угли"] },
        { key = "forest", label = L["лес"] },
        { key = "frost",  label = L["иней"] },
        { key = "violet", label = L["фиалка"] },
        { key = "accent", label = L["цвет темы"] },
        { key = "class",  label = L["цвет класса"] },
    }, db.sceneBackdrop or "none", function(value)
        db.sceneBackdrop = value
        backPicker:Refresh(value)
        Live()
    end, nil, PV("With", "", "sceneBackdrop", PV("Scene")))
    Slider(page, L["Плотность фона"], 10, 100, 5, db.sceneAlpha or 85, function(val)
        db.sceneAlpha = val
        Live()
    end, "%")

    Section(page, L["Атмосфера"])
    Slider(page, L["Туман у ног"], 0, 100, 5, db.sceneFog or 0, function(val)
        db.sceneFog = val
        Live()
    end, "%")
    Slider(page, L["Парящие искры"], 0, 60, 2, db.sceneMotes or 0, function(val)
        db.sceneMotes = val
        Live()
    end)
    Note(page, L["Туман и искры берут цвет подсветки за моделью (страница «Слоты и модель»)."])

    Section(page, L["Поза модели"])
    local posePicker
    posePicker = Picker(page, {
        { key = "stand",   label = L["обычная"] },
        { key = "ready",   label = L["боевая стойка"] },
        { key = "dance",   label = L["танец"] },
        { key = "wave",    label = L["приветствие"] },
        { key = "cheer",   label = L["ликование"] },
        { key = "bow",     label = L["поклон"] },
        { key = "salute",  label = L["салют"] },
        { key = "flex",    label = L["сила"] },
        { key = "roar",    label = L["рёв"] },
        { key = "laugh",   label = L["смех"] },
        { key = "kneel",   label = L["на колене"] },
        { key = "applaud", label = L["аплодисменты"] },
        { key = "sit",     label = L["сидя"] },
        { key = "random",  label = L["случайная при открытии"] },
    }, db.modelPose or "stand", function(value)
        db.modelPose = value
        posePicker:Refresh(value)
        if NS.NarciUI and NS.NarciUI.ApplyPose then NS.NarciUI:ApplyPose() end
    end, nil, PV("With", "", "modelPose", PV("Scene")))

    Section(page, L["Камера"])
    Note(page, L["Левая кнопка мыши на модели поворачивает её, колесо приближает, правая кнопка сдвигает модель в кадре."])
    Check(page, L["Запоминать поворот, приближение и сдвиг модели"], db.rememberModelView, function(val)
        db.rememberModelView = val
    end)
    Buttons(page, {
        { label = L["Сбросить положение модели"], width = 220, action = function()
            if NS.NarciUI and NS.NarciUI.ResetModelView then NS.NarciUI:ResetModelView() end
        end },
    })
end

local HOME_GROUPS = {
    { title = "Части аддона", note = "Какие части NarciUI включены. Здесь каждую можно выключить и вернуть стандартный вид клиента, а настраивается часть на своей странице.",
        links = { { "Части аддона", "parts" } } },
    { title = "Внешний вид", note = "Стиль и фон окон, цвет темы, шрифт, масштаб интерфейса и общие шрифты и полосы для всех элементов сразу.",
        links = { { "Стиль", "style" }, { "Тема окон", "theme" }, { "Масштаб, цвет и язык", "look" } } },
    { title = "Окно персонажа", note = "Окно на клавише персонажа: слоты, модель, сцена вокруг неё, вкладки внизу и осмотр других игроков.",
        links = { { "Окно персонажа", "character" }, { "Вкладки окна персонажа", "toolbarbuttons" }, { "Осмотр", "inspect" } } },
    { title = "Окна игры", note = "Сумки, торговцы, аукцион, почта, учителя, карта мира, диалоги с NPC, окна группы и остальные окна клиента.",
        links = { { "Сумки", "bags" }, { "Карта мира", "worldmap" }, { "Прочие окна клиента", "client" } } },
    { title = "Рамки и панели", note = "Рамки игрока, цели и группы, рейд-фреймы, панели команд, полоса заклинания, бафы и неймплейты. У каждого элемента внутри есть страница «Шрифт, полосы и цвета».",
        links = { { "Рамки юнитов", "playerui" }, { "Рейд-фреймы", "raid" }, { "Панели команд", "bars" } } },
    { title = "Информация на экране", note = "Миникарта и кнопки аддонов, панель показателей, подсказки, трекер заданий, угроза и значок поиска группы.",
        links = { { "Миникарта", "minimap" }, { "Показатели", "data" }, { "Подсказки", "tooltip" } } },
    { title = "Чат и общение", note = "Чат, окно личных сообщений, автоматическое принятие приглашений и призыва.",
        links = { { "Чат", "chat" }, { "Сообщения", "messenger" }, { "Приглашения и призыв", "autoaccept" } } },
    { title = "Помощники", note = "Автопочинка и продажа хлама, утилиты рейда, интерфейс мини-игр и экран AFK.",
        links = { { "Утилиты", "utilities" }, { "Утилиты рейда", "raidutility" }, { "Экран AFK", "afk" } } },
    { title = "Профили", note = "Профили настроек, готовые наборы, раскладки под роль, перенос настроек между персонажами.",
        links = { { "Профили", "profiles" }, { "Готовые профили", "readyprofiles" }, { "Раскладки под роль", "layouts" } } },
}

local function BuildHome(page)
    Section(page, L["Как устроены настройки"])
    Note(page, L["Слева - разделы, сгруппированные по тому, что они меняют. У раздела с плюсом есть вложенные страницы, они раскрываются при выборе. Поле над списком ищет по названиям и по всему тексту страниц: попробуйте «шрифт», «прозрачность» или «кулдаун»."])
    Note(page, L["Если что-то из NarciUI мешает, выключите эту часть в «Частях аддона» - вернётся стандартный вид клиента. При наведении на вариант в списке выбора рядом с окном показывается образец."])

    Section(page, L["Быстрый старт"])
    Buttons(page, {
        { label = L["Мастер настройки"], width = 156, action = function() if NS.Installer then NS.Installer:Show() end end },
        { label = L["Расставить интерфейс"], width = 156, action = function() if NS.Movers then NS.Movers:Toggle() end end },
        { label = L["Готовые профили"], width = 156, action = function() Settings:Select("readyprofiles") end },
    })

    Section(page, L["Где что настраивать"])
    for _, group in ipairs(HOME_GROUPS) do
        Label(page, L[group.title])
        Note(page, L[group.note])
        local row = {}
        for _, link in ipairs(group.links) do
            local key = link[2]
            row[#row + 1] = { label = L[link[1]], width = 156, action = function() Settings:Select(key) end }
        end
        Buttons(page, row)
    end
end

local GROUP_ALIAS = { ["Окна"] = "Окна игры", ["Интерфейс в игре"] = "Информация на экране", ["Управление"] = "Профили" }

local ELEMENT_HOME = {
    unitframes = "playerui", cooldowns = "playerui", raid = "raid", nameplates = "nameplates", castbar = "cast",
    threat = "threat", tooltip = "tooltip", auras = "auras", actionbars = "bars", chat = "chat",
    minimap = "minimap", datatexts = "data", bags = "bags",
}
local ELEMENT_TITLE = { cooldowns = "Шкала кулдаунов: шрифт и цвета" }

local CATEGORIES = {
    { key = "home", title = "Главная", build = BuildHome, group = "Начало" },
    { key = "parts",     title = "Части аддона",   build = BuildParts,    group = "Начало" },
    {
        key = "style", title = "Стиль", build = BuildStyle, group = "Внешний вид",
        children = {
            { key = "styledetails", title = "Детали стиля", build = BuildStyleDetails },
        },
    },
    { key = "theme",     title = "Тема окон",      build = BuildTheme, group = "Внешний вид" },
    { key = "look",      title = "Масштаб, цвет и язык",     build = BuildLook,  group = "Внешний вид" },
    {
        key = "elementlook", title = "Шрифты и полосы везде", build = BuildElementLookGeneral, group = "Внешний вид",
        children = {
            { key = "narcicolors",   title = "Цвета NarciUI", build = BuildNarciColors },
        },
    },
    { key = "brand",     title = "Подпись и эмблема", build = BuildBrand, group = "Внешний вид" },
    {
        key = "character", title = "Окно персонажа", build = BuildCharacter, group = "Окно персонажа",
        children = {
            { key = "charslots", title = "Слоты и модель", build = BuildCharSlots },
            { key = "charscene", title = "Сцена", build = BuildCharScene },
        },
    },
    { key = "toolbarbuttons", title = "Вкладки окна персонажа", build = BuildToolbarButtons, group = "Окно персонажа" },
    { key = "inspect",   title = "Осмотр",         build = BuildInspect,       group = "Окно персонажа" },
    {
        key = "bags", title = "Сумки", build = BuildBags, group = "Окна игры",
        children = {
            { key = "bagcurrency", title = "Валюта в сумке", build = BuildBagCurrency },
        },
    },
    { key = "merchant",  title = "Торговцы",       build = BuildMerchant,      group = "Окна игры" },
    { key = "auction",   title = "Аукцион",        build = BuildAuction,       group = "Окна игры" },
    { key = "mailoptions", title = "Почта", build = BuildMailOptions, group = "Окна игры" },
    { key = "traineroptions", title = "Учителя", build = BuildTrainerOptions, group = "Окна игры" },
    { key = "worldmap",  title = "Карта мира",     build = BuildWorldMap,      group = "Окна игры" },
    { key = "dialogue",  title = "Диалоги",        build = BuildDialogue,      group = "Окна игры" },
    { key = "group",     title = "Окна группы",    build = BuildGroupWindows,  group = "Окна игры" },
    { key = "gamemenu",  title = "Меню Esc",       build = BuildGameMenu,      group = "Окна игры" },
    { key = "client",    title = "Прочие окна клиента",   build = BuildClientWindows, group = "Окна игры" },
    { key = "addonwindows", title = "Окна аддона", build = BuildAddonWindows, group = "Окна игры" },
    {
        key = "playerui", title = "Рамки юнитов", build = BuildPlayerUI, group = "Рамки и панели",
        children = {
            { key = "unitlook",          title = "Вид рамок", build = BuildUnitLook },
            { key = "classpower",        title = "Ресурсы класса", build = BuildClassPower },
            { key = "unit_player",       title = "Игрок",     build = BuildUnitPage("player", "Игрок") },
            { key = "unit_target",       title = "Цель",      build = BuildUnitPage("target", "Цель") },
            { key = "unit_targettarget", title = "Цель цели", build = BuildUnitPage("targettarget", "Цель цели") },
            { key = "unit_pet",          title = "Питомец",   build = BuildUnitPage("pet", "Питомец") },
            { key = "unit_focus",        title = "Фокус",     build = BuildUnitPage("focus", "Фокус") },
            { key = "unit_focustarget",  title = "Цель фокуса", build = BuildUnitPage("focustarget", "Цель фокуса") },
            { key = "unit_pettarget",    title = "Цель питомца", build = BuildUnitPage("pettarget", "Цель питомца") },
            { key = "unit_tott",         title = "Цель цели цели", build = BuildUnitPage("targettargettarget", "Цель цели цели") },
            { key = "unit_boss",         title = "Боссы",     build = BuildUnitPage({ "boss1", "boss2", "boss3", "boss4" }, "Боссы") },
            { key = "unit_arena",        title = "Арена",     build = BuildUnitPage({ "arena1", "arena2", "arena3", "arena4", "arena5" }, "Арена") },
        },
    },
    { key = "raid",       title = "Рейд-фреймы",    build = BuildRaidFrames,    group = "Рамки и панели",
        children = {
            { key = "raidauras", title = "Ауры на рейд-рамках", build = BuildRaidAuras },
            { key = "raidlayouts", title = "Раскладки рейда", build = BuildRaidLayouts },
        } },
    { key = "healpredict", title = "Лечение и щиты", build = BuildHealPredict,  group = "Рамки и панели" },
    {
        key = "bars", title = "Панели команд", build = BuildActionBars, group = "Рамки и панели",
        children = {
            { key = "buttonlook", title = "Вид кнопок", build = BuildButtonLook },
            { key = "micro", title = "Микро-меню", build = BuildMicroPage },
            { key = "bar1", title = "Панель 1", build = BuildBarPage("bar1", 1) },
            { key = "bar2", title = "Панель 2", build = BuildBarPage("bar2", 2) },
            { key = "bar3", title = "Панель 3", build = BuildBarPage("bar3", 3) },
            { key = "bar4", title = "Панель 4", build = BuildBarPage("bar4", 4) },
            { key = "bar5", title = "Панель 5", build = BuildBarPage("bar5", 5) },
            { key = "bar6", title = "Панель 6", build = BuildBarPage("bar6", 6) },
            { key = "bar7", title = "Панель 7", build = BuildBarPage("bar7", 7) },
            { key = "bar8", title = "Панель 8", build = BuildBarPage("bar8", 8) },
            { key = "bar9", title = "Панель 9", build = BuildBarPage("bar9", 9) },
            { key = "stance", title = "Панель форм", build = BuildBarPage("stance", 10) },
            { key = "petbar", title = "Панель питомца", build = BuildBarPage("pet", 11) },
            { key = "xpbar", title = "Полоса опыта", build = function(page)
                local db = NS.db.actionBars or {}
                Section(page, L["Полоса опыта"])
                Note(page, L["Опыт до максимального уровня, затем отслеживаемая репутация. Появляется вместо полосы клиента, когда стандартное оформление панелей скрыто. Двигается вместе с панелями (Расставить). Кнопка выхода из транспорта появляется сама, когда из него можно выйти."])
                Check(page, L["Показывать полосу опыта"], db.xpBar ~= false, function(val)
                    db.xpBar = val and true or false
                    if NS.ActionBars and NS.ActionBars.xpBar then
                        if val then NS.ActionBars:UpdateXPBar() else NS.ActionBars.xpBar:Hide() end
                    elseif val and NS.ActionBars then
                        NS.ActionBars:BuildExtras()
                    end
                end)
                Slider(page, L["Ширина"], 120, 1200, 10, db.xpWidth or 420, function(val)
                    db.xpWidth = val
                    if NS.ActionBars and NS.ActionBars.xpBar then NS.ActionBars:ApplyXPLook() end
                end)
                Slider(page, L["Высота"], 4, 24, 1, db.xpHeight or 8, function(val)
                    db.xpHeight = val
                    if NS.ActionBars and NS.ActionBars.xpBar then NS.ActionBars:ApplyXPLook() end
                end)

                local function Look(field, value)
                    db[field] = value
                    if NS.ActionBars and NS.ActionBars.ApplyXPLook then NS.ActionBars:ApplyXPLook() end
                end
                local function Choice(label, field, options, fallback, preview)
                    Label(page, label)
                    local picker
                    picker = Picker(page, options, db[field] or fallback, function(value)
                        picker:Refresh(value)
                        Look(field, value)
                    end, nil, preview or PV("Sample", "ActionBars", "actionBars", field, { kind = "xp" }))
                end
                local function Color(label, field, default)
                    ColorSetting(page, label, function()
                        local c = db[field] or default
                        return c[1], c[2], c[3]
                    end, function(r, g, b) Look(field, { r, g, b }) end)
                end

                Section(page, L["Цвета"])
                Color(L["Опыт"], "xpColor", { 0.58, 0.30, 0.85 })
                Color(L["Отдых"], "xpRestedColor", { 0.25, 0.45, 0.90 })
                Check(page, L["Показывать отдых (бонус опыта)"], db.xpShowRested ~= false, function(val) Look("xpShowRested", val) end)
                Choice(L["Цвет репутации"], "xpRepColor", {
                    { key = "reaction", label = L["по отношению"] },
                    { key = "theme",    label = L["цвет темы"] },
                    { key = "custom",   label = L["свой цвет"] },
                }, "reaction")
                Color(L["Свой цвет репутации"], "xpRepCustom", { 0.3, 0.7, 0.3 })

                Section(page, L["Текст на полосе"])
                Choice(L["Что писать"], "xpText", {
                    { key = "none",    label = L["ничего"] },
                    { key = "percent", label = L["проценты"] },
                    { key = "value",   label = L["значение"] },
                    { key = "both",    label = L["значение и проценты"] },
                    { key = "left",    label = L["сколько осталось"] },
                }, "none")
                Choice(L["Где"], "xpTextPlace", {
                    { key = "inside", label = L["на полосе"] },
                    { key = "above",  label = L["над полосой"] },
                    { key = "below",  label = L["под полосой"] },
                }, "inside")
                Slider(page, L["Размер текста"], 7, 18, 1, db.xpTextSize or 10, function(val) Look("xpTextSize", val) end)
                Check(page, L["Только при наведении мыши"], db.xpTextHover, function(val) Look("xpTextHover", val) end)
                Check(page, L["Название фракции у репутации"], db.xpTextName ~= false, function(val) Look("xpTextName", val) end)
                Check(page, L["Бонус отдыха в тексте"], db.xpTextRested ~= false, function(val) Look("xpTextRested", val) end)

                Section(page, L["Вид"])
                Choice(L["Стиль"], "xpStyle", NS.Styling.BoxOptions(), "flat")
                Note(page, L["Пункт Рамка ниже действует при плоском стиле."])
                Choice(L["Рамка"], "xpBorder", {
                    { key = "thin",   label = L["тонкая"] },
                    { key = "black",  label = L["чёрная"] },
                    { key = "accent", label = L["цвет темы"] },
                    { key = "none",   label = L["без рамки"] },
                }, "thin")
                Slider(page, L["Плотность фона"], 0, 100, 5, db.xpBgAlpha or 90, function(val) Look("xpBgAlpha", val) end, "%")
                Check(page, L["Деления по 10%"], db.xpTicks, function(val) Look("xpTicks", val) end)
                Check(page, L["Искра на конце заливки"], db.xpSpark, function(val) Look("xpSpark", val) end)

                Section(page, L["Поведение"])
                Check(page, L["На максимальном уровне показывать репутацию"], db.xpRep ~= false, function(val) Look("xpRep", val) end)
                Check(page, L["Прятать в бою"], db.xpCombatHide, function(val) Look("xpCombatHide", val) end)

                Section(page, L["Кнопка выхода из транспорта"])
                local function Leave(field, value)
                    db[field] = value
                    if NS.ActionBars and NS.ActionBars.ApplyLeaveLook then NS.ActionBars:ApplyLeaveLook() end
                end
                Label(page, L["Стиль кнопки"])
                local leavePicker
                leavePicker = Picker(page, NS.Styling.BoxOptions(), db.leaveStyle or "flat", function(value)
                    leavePicker:Refresh(value)
                    Leave("leaveStyle", value)
                end, nil, PV("Box", "button", { icon = "Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up", iconCoords = { 0.14, 0.86, 0.14, 0.86 }, tint = { 0.85, 0.3, 0.3 } }))
                Slider(page, L["Размер кнопки"], 20, 64, 1, db.leaveSize or 32, function(val) Leave("leaveSize", val) end)
            end },
        },
    },
    { key = "cast",       title = "Полоса заклинания", build = BuildCastBar,    group = "Рамки и панели" },
    { key = "auras",      title = "Бафы",           build = BuildAuras,         group = "Рамки и панели" },
    { key = "nameplates", title = "Неймплейты",     build = BuildNameplates,    group = "Рамки и панели",
        children = { { key = "platefilters", title = "Правила неймплейтов", build = BuildPlateFilters } } },
    { key = "minimap",    title = "Миникарта",      build = BuildMinimap,       group = "Информация на экране" },
    { key = "minibag",    title = "Кнопки аддонов", build = BuildMiniBag,       group = "Информация на экране" },
    { key = "data",       title = "Показатели",     build = BuildDataTexts,     group = "Информация на экране" },
    { key = "tooltip",    title = "Подсказки",      build = BuildTooltip,       group = "Информация на экране" },
    { key = "tracker",    title = "Трекер заданий", build = BuildTracker,       group = "Информация на экране" },
    { key = "threat",     title = "Угроза",         build = BuildThreat,        group = "Информация на экране" },
    { key = "queueeye",   title = "Значок поиска группы", build = BuildQueueEye, group = "Информация на экране",
        children = { { key = "queuestatus", title = "Окно очереди", build = BuildQueueStatus } } },
    { key = "chat",       title = "Чат",            build = BuildChat,          group = "Чат и общение",
        children = { { key = "chatextras", title = "Копирование, слова, спам, история", build = BuildChatExtras } } },
    { key = "messenger", title = "Сообщения", build = BuildMessenger, group = "Чат и общение" },
    { key = "autoaccept", title = "Приглашения и призыв", build = BuildAutoAccept, group = "Чат и общение" },
    { key = "utilities",  title = "Утилиты", build = BuildUtilities, group = "Помощники" },
    { key = "raidutility", title = "Утилиты рейда", build = BuildRaidUtility, group = "Помощники" },
    { key = "minigames", title = "Мини-игры", build = BuildMiniGame, group = "Помощники" },
    { key = "afk",        title = "Экран AFK",      build = BuildAFK,           group = "Помощники" },
    {
        key = "profiles", title = "Профили", build = BuildProfiles, group = "Профили",
        children = {
            { key = "profilerules", title = "Автовыбор профиля", build = BuildProfileRules },
            { key = "readyprofiles", title = "Готовые профили", build = BuildReadyProfiles },
        },
    },
    { key = "layouts", title = "Раскладки под роль", build = BuildLayouts, group = "Профили" },
    { key = "actions",   title = "Прочие действия",       build = BuildActions,  group = "Профили" },
}

local PLUGIN_STATUS = {
    loaded   = { "работает", 0.4, 1, 0.5 },
    waiting  = { "ждёт входа в игру", 0.8, 0.8, 0.8 },
    disabled = { "выключен", 0.6, 0.6, 0.6 },
    outdated = { "нужна новая версия NarciUI", 1, 0.55, 0.2 },
    error    = { "ошибка при запуске", 1, 0.3, 0.3 },
}

local function BuildPlugins(page)
    local Plugins = NS.Plugins
    local list = Plugins and Plugins:List() or {}

    Section(page, L["Плагины"])

    Note(page, L["Плагины - отдельные аддоны, которые дополняют NarciUI через его API: добавляют свои страницы настроек, стили неймплейтов и сумок, текстуры, шрифты, готовые образы и блоки показателей."])

    if #list == 0 then
        Note(page, L["Плагинов пока нет. Как написать свой - в файле PLUGINS.md в папке аддона, там же лежит пример."])
        return
    end

    for _, plugin in ipairs(list) do
        local status = PLUGIN_STATUS[plugin.status] or PLUGIN_STATUS.waiting
        local color = string.format("|cff%02x%02x%02x", math.floor(status[2] * 255), math.floor(status[3] * 255), math.floor(status[4] * 255))
        Label(page, plugin.title .. "  |cff909090" .. plugin.version .. "|r   " .. color .. L[status[1]] .. "|r")
        local about = plugin.description or ""
        if plugin.author then about = about .. (about ~= "" and "  " or "") .. L["Автор"] .. ": " .. plugin.author end
        if plugin.lastError then about = about .. "\n|cffff6060" .. plugin.lastError .. "|r" end
        if about ~= "" then Note(page, about) end
        Check(page, L["Включён"], Plugins:Enabled(plugin.name), function(val)
            if type(NS.db.pluginsEnabled) ~= "table" then NS.db.pluginsEnabled = {} end
            NS.db.pluginsEnabled[plugin.name] = val and true or false
            NS.Print(plugin.title .. ": " .. L["изменение вступит в силу после перезагрузки интерфейса"])
        end)
        if plugin.settings and plugin.status == "loaded" then
            Buttons(page, {
                { label = L["Настройки плагина"], width = 180, action = function() Settings:Select("plugin_" .. plugin.name) end },
            })
        end
    end

    Note(page, L["Включение и выключение применяется после перезагрузки. Если плагин сам менял настройки аддона (как «Сумерки» при установке), сначала верните их кнопкой в настройках плагина, а потом выключайте его - иначе изменения останутся."])
    Buttons(page, {
        { label = L["Перезагрузить интерфейс"], width = 220, action = function() ReloadUI() end },
    })
end


local function PluginPage(plugin)
    return function(page)
        if plugin.status ~= "loaded" then
            Section(page, plugin.title)
            Note(page, L["Плагин не запущен."])
            return
        end
        local ok, err = pcall(plugin.settings, page, NS.SettingsUI, plugin.db, NS.PluginAPI)
        if not ok then
            plugin.lastError = tostring(err)
            NS.Print("|cffff6060" .. plugin.title .. "|r - settings: " .. tostring(err))
        end
    end
end

function Settings:Categories()
    local list = {}
    for _, category in ipairs(CATEGORIES) do list[#list + 1] = category end

    local extraChildren = {}
    local leading = {}
    for _, element in ipairs(NS.Look and NS.Look.ELEMENTS or {}) do
        local home = not element.extra and ELEMENT_HOME[element.key]
        if home then
            leading[home] = leading[home] or {}
            table.insert(leading[home], { key = "el_" .. element.key, title = ELEMENT_TITLE[element.key] or "Шрифт, полосы и цвета", build = BuildElementLook(element.key) })
        else
            extraChildren.elementlook = extraChildren.elementlook or {}
            table.insert(extraChildren.elementlook, { key = "el_" .. element.key, title = element.name, build = BuildElementLook(element.key) })
        end
    end
    for _, extra in ipairs(self.extraCategories) do
        if extra.parent then
            extraChildren[extra.parent] = extraChildren[extra.parent] or {}
            table.insert(extraChildren[extra.parent], { key = extra.key, title = extra.title, build = extra.build })
        else
            local group = GROUP_ALIAS[extra.group] or extra.group or "Дополнения"
            local at = #list + 1
            for index, category in ipairs(list) do
                if category.group == group then at = index + 1 end
            end
            table.insert(list, at, { key = extra.key, title = extra.title, build = extra.build, group = group })
        end
    end
    for index, category in ipairs(list) do
        local more = extraChildren[category.key]
        local first = leading[category.key]
        if more or first then
            local copy = {}
            for field, value in pairs(category) do copy[field] = value end
            copy.children = {}
            for _, child in ipairs(first or {}) do copy.children[#copy.children + 1] = child end
            for _, child in ipairs(category.children or {}) do copy.children[#copy.children + 1] = child end
            for _, child in ipairs(more or {}) do copy.children[#copy.children + 1] = child end
            list[index] = copy
        end
    end

    local children = {}
    for _, plugin in ipairs(NS.Plugins and NS.Plugins:List() or {}) do
        if type(plugin.settings) == "function" then
            children[#children + 1] = { key = "plugin_" .. plugin.name, title = plugin.title, build = PluginPage(plugin) }
        end
    end
    list[#list + 1] = { key = "plugins", title = "Плагины", build = BuildPlugins, children = children, group = "Дополнения" }
    return list
end

function Settings:Create()
    if NS.settingsFrame then return NS.settingsFrame end

    local S = Style()

    local f = CreateFrame("Frame", "NarcissusSirus_SettingsFrame", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(240)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, "NarcissusSirus_SettingsFrame")

    S.ApplyPanelStyle(f, PANEL_W, PANEL_H)
    S.WindowSounds(f, "igMainMenuOpen", "igMainMenuClose")

    local solid = f:CreateTexture(nil, "BACKGROUND")
    solid:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    solid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    solid:SetTexture(WHITE)
    solid:SetVertexColor(S.Tint(0.016, 0.018, 0.026, 1))
    if f.narciRound then S.RoundTexture(solid, math.max(2, S.CORNER_RADIUS - 1)) end

    local wordGlow = f:CreateTexture(nil, "ARTWORK")
    wordGlow:SetSize(184, 46)
    wordGlow:SetPoint("TOP", f, "TOP", 0, -1)
    wordGlow:SetTexture(S.Media("LogoTitleGlow"))
    wordGlow:SetBlendMode("ADD")
    local word = f:CreateTexture(nil, "OVERLAY")
    word:SetAllPoints(wordGlow)
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 1)
    local emblem = f:CreateTexture(nil, "OVERLAY")
    emblem:SetSize(36, 36)

    local function PaintTitle()
        S.PaintWordmark(word, title, "LogoTitle", 20)
        local _, _, _, r, g, b = S.BrandColor()
        wordGlow:SetVertexColor(r, g, b, 0.55)
        wordGlow:SetShown(word:IsShown())
        emblem:ClearAllPoints()
        if word:IsShown() then
            emblem:SetPoint("RIGHT", word, "LEFT", 26, 3)
        else
            emblem:SetPoint("RIGHT", title, "LEFT", -8, 0)
        end
        S.PaintEmblem(emblem, nil, nil, true)
    end
    PaintTitle()
    S.WatchBrand(PaintTitle)

    local close = NS.Widgets.CreateCloseButton(f, 22, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local moveAll = NS.Widgets.CreateThemedButton(f, L["Расставить интерфейс"], 170, 22, function()
        if not NS.Movers then return end
        f:Hide()
        NS.Movers:Toggle()
    end)
    moveAll:SetPoint("RIGHT", close, "LEFT", -8, 0)

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE_W, -TOP_H + 6)
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDE_W, FOOT_H)
    divider:SetTexture(WHITE)
    divider:SetGradientAlpha("VERTICAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30)

    local search = NS.Widgets.CreateThemedEditBox(f, SIDE_W - 22, 22, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -TOP_H + 2)

    local searchHint = search:CreateFontString(nil, "OVERLAY")
    searchHint:SetFont(NS.FONT, NS.FS(11), "")
    searchHint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    searchHint:SetPoint("LEFT", search, "LEFT", 8, 0)
    searchHint:SetText(L["Поиск настройки..."])

    local focused
    local function SearchHint()
        searchHint:SetShown(search:GetText() == "" and not focused)
    end
    search:HookScript("OnEditFocusGained", function() focused = true; SearchHint() end)
    search:HookScript("OnEditFocusLost", function() focused = false; SearchHint() end)
    search:SetScript("OnTextChanged", function(selfBox)
        SearchHint()
        Settings:Search(selfBox:GetText())
    end)
    search:SetScript("OnEscapePressed", function(selfBox)
        if selfBox:GetText() ~= "" then selfBox:SetText("") else selfBox:ClearFocus() end
    end)
    search:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        for _, entry in ipairs(Settings.sideEntries or {}) do
            if entry.key and entry.visible then
                Settings:Select(entry.key)
                break
            end
        end
    end)
    f.search = search

    local side = CreateFrame("ScrollFrame", nil, f)
    side:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -TOP_H - 26)
    side:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", SIDE_W - 2, FOOT_H + 2)
    side:EnableMouseWheel(true)

    local sideContent = CreateFrame("Frame", nil, side)
    sideContent:SetSize(SIDE_W - 2, 1)
    side:SetScrollChild(sideContent)

    local track = f:CreateTexture(nil, "ARTWORK")
    track:SetWidth(2)
    track:SetPoint("TOPRIGHT", side, "TOPRIGHT", -3, -4)
    track:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", -3, 4)
    track:SetTexture(WHITE)
    track:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.5)

    local thumb = f:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(2)
    thumb:SetTexture(WHITE)
    thumb:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)

    local fade = f:CreateTexture(nil, "OVERLAY")
    fade:SetHeight(24)
    fade:SetPoint("BOTTOMLEFT", side, "BOTTOMLEFT", 0, 0)
    fade:SetPoint("BOTTOMRIGHT", side, "BOTTOMRIGHT", -8, 0)
    fade:SetTexture(WHITE)
    local fr, fg, fb = S.Tint(0.016, 0.018, 0.026)
    fade:SetGradientAlpha("VERTICAL", fr, fg, fb, 1, fr, fg, fb, 0)

    local function UpdateSide()
        local visible = side:GetHeight() or 1
        local total = sideContent:GetHeight() or 1
        local range = math.max(0, total - visible)
        local value = math.min(range, side:GetVerticalScroll() or 0)

        local overflow = range > 1
        track:SetShown(overflow)
        thumb:SetShown(overflow)
        fade:SetShown(overflow and value < range - 1)
        if not overflow then return end

        local trackHeight = visible - 8
        local thumbHeight = math.max(24, trackHeight * visible / total)
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", side, "TOPRIGHT", -3, -4 - (trackHeight - thumbHeight) * value / range)
    end

    local function ScrollSide(value)
        local range = math.max(0, sideContent:GetHeight() - side:GetHeight())
        side:SetVerticalScroll(math.max(0, math.min(range, value)))
        UpdateSide()
    end

    side:SetScript("OnMouseWheel", function(selfFrame, delta)
        ScrollSide(selfFrame:GetVerticalScroll() - delta * 44)
    end)

    side:SetScript("OnShow", UpdateSide)
    side:SetScript("OnSizeChanged", UpdateSide)

    self.sideContent = sideContent

    local entries = {}
    local parentOf = {}
    self.hasChildren = {}
    local lastGroup

    for _, category in ipairs(self:Categories()) do
        local group = category.group or "Дополнения"
        if group ~= lastGroup then
            lastGroup = group
            local header = sideContent:CreateFontString(nil, "OVERLAY")
            header:SetFont(NS.FONT, NS.FS(10), "")
            header:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            header:SetText(L[group])
            local rule = sideContent:CreateTexture(nil, "ARTWORK")
            rule:SetHeight(1)
            rule:SetTexture(WHITE)
            rule:SetPoint("LEFT", header, "RIGHT", 6, 0)
            rule:SetPoint("RIGHT", sideContent, "RIGHT", -12, 0)
            rule:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
            entries[#entries + 1] = { header = header, rule = rule, group = group }
        end

        local title = L[category.title]
        local page = self:AddCategory(f, category.key, title, 0)
        local entry = { key = category.key, button = buttons[category.key], group = group, lower = Lower(title) }
        entries[#entries + 1] = entry
        Index(page, title)

        local ok, err = pcall(category.build, page)
        if not ok then NS.Print("настройки " .. category.key .. ": " .. tostring(err)) end
        self:RunExtensions(category.key, page)

        page:SetHeight(-page.offset + 10)

        if category.children and #category.children > 0 then
            local arrow = entry.button:CreateTexture(nil, "OVERLAY")
            arrow:SetSize(9, 9)
            arrow:SetPoint("RIGHT", entry.button, "RIGHT", -8, 0)
            arrow:SetTexture(S.Media("IconPlus"))
            arrow:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 0.9)
            entry.arrow = arrow
            self.hasChildren[category.key] = true

            local fold = CreateFrame("Button", nil, entry.button)
            fold:SetSize(24, 22)
            fold:SetPoint("RIGHT", entry.button, "RIGHT", 0, 0)
            fold:SetFrameLevel(entry.button:GetFrameLevel() + 2)
            local parentKey = category.key
            fold:SetScript("OnClick", function() Settings:ToggleFold(parentKey) end)
            fold:SetScript("OnEnter", function() arrow:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1) end)
            fold:SetScript("OnLeave", function() arrow:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 0.9) end)
            entry.fold = fold
        end

        for _, child in ipairs(category.children or {}) do
            local childTitle = L[child.title]
            local childPage = self:AddCategory(f, child.key, childTitle, 0, true)
            entries[#entries + 1] = {
                key = child.key, button = buttons[child.key], group = group, parent = category.key,
                lower = Lower(childTitle .. " " .. title),
            }
            parentOf[child.key] = category.key
            Index(childPage, childTitle)

            local childOk, childErr = pcall(child.build, childPage)
            if not childOk then NS.Print("настройки " .. child.key .. ": " .. tostring(childErr)) end
            self:RunExtensions(child.key, childPage)

            childPage:SetHeight(-childPage.offset + 10)
        end
    end

    local empty = sideContent:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(11), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetText(L["Ничего не найдено"])
    empty:Hide()

    self.sideEntries = entries
    self.parentOf = parentOf
    self.sideHolder = sideContent
    self.sideScroll = side
    self.sideEmpty = empty
    self.updateSide = UpdateSide
    self.sideContent = nil
    self:LayoutSide()

    local footRule = f:CreateTexture(nil, "ARTWORK")
    footRule:SetHeight(1)
    footRule:SetTexture(WHITE)
    footRule:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 40, FOOT_H)
    footRule:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, FOOT_H)
    footRule:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.7)

    local info = f:CreateFontString(nil, "OVERLAY")
    info:SetFont(NS.FONT, NS.FS(9), "")
    info:SetTextColor(0.5, 0.5, 0.5)
    info:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    info:SetText("NarciUI v0.0.7 | /narci - " .. L["команды"])

    NS.settingsFrame = f
    self:BuildHint(f)
    f:Hide()

    self:Select(CATEGORIES[1].key)

    return f
end

function Settings:Toggle()
    self:Create()

    if NS.settingsFrame:IsShown() then
        NS.settingsFrame:Hide()
    else
        NS.settingsFrame:Show()
    end
end

NS.SettingsUI = {
    Section = Section,
    Check = Check,
    Slider = Slider,
    Label = Label,
    Note = Note,
    Buttons = Buttons,
    Picker = Picker,
    Color = ColorSetting,
}
