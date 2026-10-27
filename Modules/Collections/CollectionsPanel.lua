local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"

local PANEL_W = 900
local PANEL_H = 620
local PAD = 18

local TABS = {
    { key = "mounts", label = "MOUNTS", fallback = "Транспорт" },
    { key = "pets", label = "PETS", fallback = "Питомцы" },
    { key = "wardrobe", label = "WARDROBE", fallback = "Модели" },
    { key = "toys", label = "TOY_BOX", fallback = "Игрушки" },
    { key = "heirlooms", label = "HEIRLOOMS", fallback = "Наследство" },
}

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Caption(parent, text)
    local S = NS.Styling
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(NS.FONT, NS.FS(10), "")
    font:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end

local function Chrome(frame)
    local S = NS.Styling

    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(NS.Styling.Panel(0.035, 0.04, 0.055, 0.92))
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    local grad = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    grad:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    grad:SetTexture(WHITE)
    grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    local bevel = frame:CreateTexture(nil, "BORDER")
    bevel:SetHeight(1)
    bevel:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    bevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    bevel:SetTexture(WHITE)
    bevel:SetVertexColor(0.45, 0.50, 0.62, 0.25)

    return frame
end

Panel.Chrome = Chrome
Panel.Caption = Caption
Panel.Global = Global

function Panel:Geometry()
    return PAD, PANEL_W - PAD * 2, PANEL_H
end

function Panel:SecureHost()
    if self.secureHost then return self.secureHost end

    local host = CreateFrame("Frame", "NarciSirus_CollectionAnchor", UIParent)
    host:SetAllPoints(UIParent)
    host:SetFrameStrata("DIALOG")
    host:Show()

    self.secureHost = host
    return host
end

function Panel:SecureButton(name)
    if InCombatLockdown() then return nil end

    local host = self:SecureHost()
    local button = CreateFrame("Button", "NarciSirus_Collection_" .. name, host, "SecureActionButtonTemplate")

    button:RegisterForClicks("AnyUp")
    button:SetFrameLevel(host:GetFrameLevel() + 20)
    button:Hide()

    return button
end

function Panel:PlaceSecure(button, target)
    if not button or not target then return end
    if InCombatLockdown() then
        self.securePending = true
        return
    end

    local left, bottom = target:GetLeft(), target:GetBottom()
    if not left or not bottom then
        self:HideSecure(button)
        return
    end

    button:SetSize(target:GetWidth(), target:GetHeight())
    button:ClearAllPoints()
    button:SetPoint("BOTTOMLEFT", self:SecureHost(), "BOTTOMLEFT", left, bottom)
    button:SetAlpha(1)
    button:Show()
end

function Panel:HideSecure(button)
    if not button then return end
    if InCombatLockdown() then
        button:SetAlpha(0)
        self.fadedSecure = self.fadedSecure or {}
        self.fadedSecure[button] = true
        self.securePending = true
        return
    end
    button:Hide()
end

function Panel:SetSecureSpell(button, spellID)
    if not button or InCombatLockdown() then
        self.securePending = true
        return
    end

    if spellID then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", spellID)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("spell", nil)
    end
end

function Panel:SetSecureItem(button, itemID)
    if not button or InCombatLockdown() then
        self.securePending = true
        return
    end

    if itemID then
        button:SetAttribute("type", "item")
        button:SetAttribute("item", "item:" .. itemID)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("item", nil)
    end
end

function Panel:PageFor(key)
    if key == "mounts" then return NS.MountCollectionPage end
    if key == "pets" then return NS.PetCollectionPage end
    if key == "wardrobe" then return NS.WardrobePage end
    if key == "toys" then return NS.ToyBoxPage end
    if key == "heirlooms" then return NS.HeirloomPage end
    return nil
end

function Panel:SyncPages()
    for _, tab in ipairs(TABS) do
        local page = self:PageFor(tab.key)
        if page and page.frame then
            if tab.key == self.tab then page:Show() else page:Hide() end
        end
    end
end

function Panel:TabLabel(key)
    for _, tab in ipairs(TABS) do
        if tab.key == key then return Global(tab.label, tab.fallback) end
    end
    return ""
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_Collections", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Panel:Update()
    end)

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.97))
    S.WindowSounds(f)
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 6, 0.45)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -16)
    title:SetText(Global("COLLECTIONS", "Коллекция"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    S.CreateAnimatedSeparator(f, -58)

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local placeholder = f:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(NS.FONT, NS.FS(12), "")
    placeholder:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    placeholder:SetPoint("CENTER", f, "CENTER", 0, 0)
    placeholder:SetWidth(PANEL_W - 200)
    placeholder:SetJustifyH("CENTER")
    placeholder:Hide()
    f.placeholder = placeholder

    f.tabs = {}
    for index, tab in ipairs(TABS) do
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(26)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(Global(tab.label, tab.fallback))
        button.label = label

        button:SetWidth(math.max(label:GetStringWidth() + 26, 110))

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
        bar:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

        button:SetScript("OnClick", function()
            Panel.tab = tab.key
            Panel:Update()
        end)

        f.tabs[index] = button
    end

    local x = PAD
    for _, button in ipairs(f.tabs) do
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, -30)
        x = x + button:GetWidth() + 6
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and Panel.securePending then
            Panel.securePending = nil
            if Panel.fadedSecure then
                for button in pairs(Panel.fadedSecure) do
                    if button:GetAlpha() == 0 then button:Hide() end
                end
                Panel.fadedSecure = nil
            end
            if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
        end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_Collections")

    self.frame = f
    self.tab = self.tab or "mounts"
    f:Hide()
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling
    self.tab = self.tab or "mounts"

    for index, tab in ipairs(TABS) do
        local button = f.tabs[index]
        local active = tab.key == self.tab

        button:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or S.BORDER[4])
        button.bar:SetShown(active)
        button.label:SetTextColor(
            active and S.TEXT_BRIGHT[1] or S.TEXT_DIM[1],
            active and S.TEXT_BRIGHT[2] or S.TEXT_DIM[2],
            active and S.TEXT_BRIGHT[3] or S.TEXT_DIM[3])
    end

    f.subtitle:SetText(self:TabLabel(self.tab))

    local page = self:PageFor(self.tab)

    if page then
        page:Attach(self)
        self:SyncPages()
        page:Update()
        f.placeholder:Hide()
    else
        self:SyncPages()
        f.placeholder:Show()
        f.placeholder:SetText(L["этот раздел ещё не перенесен, перезапустите клиент"])
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self.frame:Show()
    self:Update()
end

function Panel:Hide()
    if not self.frame then return end

    self.frame:Hide()

    for _, tab in ipairs(TABS) do
        local page = self:PageFor(tab.key)
        if page and page.frame then page:Hide() end
    end
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

function Panel:SecureCells(prefix, count)
    self.cellPools = self.cellPools or {}

    local pool = self.cellPools[prefix]
    if not pool then
        pool = {}
        self.cellPools[prefix] = pool
    end

    for index = #pool + 1, count do
        local button = self:SecureButton(prefix .. index)
        if not button then break end
        pool[index] = button
    end

    return pool
end

function Panel:HideSecureCells(prefix)
    local pool = self.cellPools and self.cellPools[prefix]
    if not pool then return end
    for _, button in ipairs(pool) do self:HideSecure(button) end
end

function Panel:CreateFilterPopup(name, spec)
    local S = NS.Styling

    local popup = CreateFrame("Frame", nil, self.frame)
    popup:SetWidth(250)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(self.frame:GetFrameLevel() + 40)
    Chrome(popup)
    S.CreateShadow(popup, 5, 0.5)
    popup:EnableMouse(true)
    popup:Hide()

    popup.rows = {}
    popup.spec = spec

    local y = -12

    local function AddCheck(text, get, set)
        local check = NS.Widgets.CreateThemedCheckbox(popup, text, false, function(value)
            set(value)
            Panel:RefreshFilters(popup)
            if spec.onChange then spec.onChange() end
        end)
        check:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, y)
        y = y - 22
        popup.rows[#popup.rows + 1] = { check = check, get = get }
        return check
    end

    local function AddTitle(text)
        local caption = Caption(popup, string.upper(text or ""))
        caption:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, y - 4)
        y = y - 22
    end

    local function AddButtons(all)
        local checkAll = NS.Widgets.CreateThemedButton(popup, Global("CHECK_ALL", "Отметить все"), 104, 18, function()
            all(true)
            Panel:RefreshFilters(popup)
            if spec.onChange then spec.onChange() end
        end)
        checkAll:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, y)

        local uncheckAll = NS.Widgets.CreateThemedButton(popup, Global("UNCHECK_ALL", "Снять все"), 104, 18, function()
            all(false)
            Panel:RefreshFilters(popup)
            if spec.onChange then spec.onChange() end
        end)
        uncheckAll:SetPoint("TOPLEFT", checkAll, "TOPRIGHT", 6, 0)
        y = y - 24
    end

    for _, section in ipairs(spec.sections) do
        if section.title then AddTitle(section.title) end

        if section.checks then
            for _, entry in ipairs(section.checks) do
                AddCheck(entry.text, entry.get, entry.set)
            end
        end

        if section.num then
            if section.all then AddButtons(section.all) end

            local total = section.num() or 0
            for index = 1, total do
                local valid = not section.valid or section.valid(index)
                if valid then
                    local label = _G[section.prepend .. index] or (section.prepend .. index)
                    AddCheck(label,
                        function() return section.get(index) end,
                        function(value) section.set(index, value) end)
                end
            end
        end
    end

    if spec.reset then
        local reset = NS.Widgets.CreateThemedButton(popup, Global("RESET_FILTERS", "Сбросить фильтры"), 214, 20, function()
            spec.reset()
            Panel:RefreshFilters(popup)
            if spec.onChange then spec.onChange() end
        end)
        reset:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, y - 4)
        y = y - 28
    end

    popup:SetHeight(math.max(60, -y + 8))

    return popup
end

function Panel:RefreshFilters(popup)
    if not popup then return end

    for _, row in ipairs(popup.rows) do
        local value = row.get()
        row.check:SetChecked(value and true or false)
    end
end

function Panel:CreateFilterButton(parent, popup)
    local button = NS.Widgets.CreateThemedButton(parent, Global("FILTER", "Фильтр"), 84, 20, function()
        if popup:IsShown() then
            popup:Hide()
        else
            Panel:RefreshFilters(popup)
            popup:Show()
        end
    end)

    popup:ClearAllPoints()
    popup:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -4)

    return button
end

NS.CollectionsPanel = Panel
