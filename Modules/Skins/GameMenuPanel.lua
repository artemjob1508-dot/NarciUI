local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"

local PANEL_W = 248
local PAD = 14
local TITLE_H = 42
local ROW_H = 26
local ROW_GAP = 2
local GROUP_GAP = 12
local BOTTOM_PAD = 12

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Enabled()
    return not NS.db or NS.db.replaceGameMenu ~= false
end

local function Cinematic()
    return NS.db and NS.db.gameMenuStyle == "cinematic"
end

local CINE_ROW_W = 380
local CINE_ROW_H = 44
local CINE_GAP = 4
local CINE_GROUP = 18
local LOGO_FALLBACK = "Custom-Realm-Logo-Sirus"
local LICH_KING = "Creature\\ArthasLichKing\\ArthasLichKing.m2"

function Panel:Entries()
    local menu = _G.GameMenuFrame
    local list = {}
    if not menu then return list end

    for _, child in ipairs({ menu:GetChildren() }) do
        if child.IsObjectType and child:IsObjectType("Button") and child:IsShown() then
            local text = child.GetText and child:GetText()

            if text and text ~= "" then
                list[#list + 1] = {
                    button = child,
                    text = text,
                    top = child:GetTop() or 0,
                    height = child:GetHeight() or ROW_H,
                    enabled = child.IsEnabled and child:IsEnabled() == 1,
                }
            end
        end
    end

    table.sort(list, function(a, b) return a.top > b.top end)

    for index = 2, #list do
        local previous = list[index - 1]
        local bottom = previous.top - previous.height
        list[index].gap = (bottom - list[index].top) > 6
    end

    self:AddAddonsEntry(list)

    return list
end

function Panel:AddAddonsEntry(list)
    if not NS.AddonListPanel then return end
    if (GetNumAddOns() or 0) == 0 then return end

    for _, entry in ipairs(list) do
        if entry.addons then return end
    end

    local anchor

    for index, entry in ipairs(list) do
        if entry.button == _G.GameMenuButtonMacros then anchor = index break end
    end

    if not anchor then
        for index, entry in ipairs(list) do
            if entry.button == _G.GameMenuButtonLogout then anchor = index - 1 break end
        end
    end

    local entry = {
        text = NS.L["Модификации"],
        enabled = true,
        addons = true,
        action = function() NS.AddonListPanel:Toggle() end,
    }

    if anchor and anchor >= 1 then
        table.insert(list, anchor + 1, entry)
    else
        list[#list + 1] = entry
    end
end

function Panel:CreateRow(parent)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetSize(PANEL_W - PAD * 2, ROW_H)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(row)
    hover:SetTexture(WHITE)
    hover:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
    hover:Hide()

    local bar = row:CreateTexture(nil, "BORDER")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 2)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    bar:Hide()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(13), "")
    label:SetPoint("LEFT", row, "LEFT", 12, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

    local rule = row:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 0, GROUP_GAP / 2)
    rule:SetPoint("BOTTOMRIGHT", row, "TOPRIGHT", 0, GROUP_GAP / 2)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
    rule:Hide()

    row.hover = hover
    row.bar = bar
    row.label = label
    row.rule = rule

    row:SetScript("OnEnter", function(self)
        if not self.target and not self.action then return end
        self.hover:Show()
        self.bar:Show()
        self.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end)

    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        self.bar:Hide()
        self.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end)

    row:SetScript("OnClick", function(self)
        if self.action then
            Panel:Release()
            pcall(self.action)
            return
        end

        local target = self.target
        if not target then return end
        if target.IsEnabled and target:IsEnabled() ~= 1 then return end

        Panel:Release()
        pcall(target.Click, target)
    end)

    return row
end

function Panel:Create()
    if self.frame then return end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_GameMenu", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(220)
    f:SetWidth(PANEL_W)
    f:SetHeight(200)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    f:EnableMouse(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(NS.Styling.Panel(0.020, 0.023, 0.032, 0.96))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])

    local grad = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    grad:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    grad:SetTexture(WHITE)
    grad:SetGradientAlpha("VERTICAL",
        0.000, 0.000, 0.000, 0.35,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    S.CreateShadow(f, 5, 0.45)
    S.CreateGradientTopBorder(f, 2)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(15), "")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetText(Global("MAINMENU_BUTTON", "Главное меню"))
    f.title = title

    local rule = f:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -TITLE_H + 8)
    rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -TITLE_H + 8)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.45,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)

    f.rows = {}

    self.frame = f
end

function Panel:CreateCineRow(parent)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetSize(CINE_ROW_W, CINE_ROW_H)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints(row)
    hover:SetTexture(WHITE)
    hover:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
    hover:Hide()

    local bar = row:CreateTexture(nil, "BORDER")
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -6)
    bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 6)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    bar:Hide()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(22), "")
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 0.9)
    label:SetPoint("LEFT", row, "LEFT", 18, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.86, 0.88, 0.92)

    row.hover = hover
    row.bar = bar
    row.label = label

    row:SetScript("OnEnter", function(self)
        if not self.target and not self.action then return end
        self.hover:Show()
        self.bar:Show()
        self.label:SetPoint("LEFT", self, "LEFT", 26, 0)
        self.label:SetTextColor(1, 1, 1)
    end)

    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        self.bar:Hide()
        self.label:SetPoint("LEFT", self, "LEFT", 18, 0)
        self.label:SetTextColor(0.86, 0.88, 0.92)
    end)

    row:SetScript("OnClick", function(self)
        if self.action then
            Panel:Release()
            pcall(self.action)
            return
        end

        local target = self.target
        if not target then return end
        if target.IsEnabled and target:IsEnabled() ~= 1 then return end

        Panel:Release()
        pcall(target.Click, target)
    end)

    return row
end

function Panel:CreateCinematic()
    if self.cine then return end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_GameMenuScene", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(220)
    f:SetAllPoints(UIParent)
    f:EnableMouse(true)
    f:Hide()

    local dim = f:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints(f)
    dim:SetTexture(WHITE)
    dim:SetVertexColor(0, 0, 0, 0.82)
    f.dim = dim

    local left = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    left:SetWidth(UIParent:GetWidth() * 0.45)
    left:SetTexture(WHITE)
    left:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.75, 0, 0, 0, 0)

    local stage = CreateFrame("Frame", nil, f)
    stage:SetAllPoints(f)
    stage:SetFrameLevel(f:GetFrameLevel() + 1)

    local model = CreateFrame("PlayerModel", nil, stage)
    model:SetFrameLevel(stage:GetFrameLevel() + 1)
    model:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -UIParent:GetWidth() * 0.04, -UIParent:GetHeight() * 0.04)
    model:SetSize(UIParent:GetWidth() * 0.46, UIParent:GetHeight() * 0.86)
    f.model = model

    local logo = stage:CreateTexture(nil, "ARTWORK")
    logo:SetSize(420, 252)
    logo:SetPoint("TOPRIGHT", f, "TOPRIGHT", -50, -30)
    f.logo = logo

    local menu = CreateFrame("Frame", nil, f)
    menu:SetFrameLevel(f:GetFrameLevel() + 5)
    menu:SetSize(CINE_ROW_W, 100)
    menu:SetPoint("LEFT", f, "LEFT", UIParent:GetWidth() * 0.07, 0)
    f.menu = menu

    local title = menu:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(34), "")
    title:SetShadowOffset(2, -2)
    title:SetShadowColor(0, 0, 0, 1)
    title:SetPoint("BOTTOMLEFT", menu, "TOPLEFT", 18, 18)
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetText(Global("MAINMENU_BUTTON", "Главное меню"))

    local rule = menu:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", menu, "TOPLEFT", 18, 8)
    rule:SetWidth(CINE_ROW_W - 18)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.7,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

    local who = menu:CreateFontString(nil, "OVERLAY")
    who:SetFont(NS.FONT, NS.FS(13), "")
    who:SetPoint("TOPLEFT", menu, "BOTTOMLEFT", 18, -24)
    who:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    f.who = who

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(12), "")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", UIParent:GetWidth() * 0.07 + 18, 40)
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetText(L["Esc - вернуться в игру"])

    f.rows = {}

    self.cine = f
end

function Panel:DressStage()
    local f = self.cine

    local logo = f.logo
    local realm
    if C_RealmInfo and C_RealmInfo.GetServerLogo and GetServerID then
        local ok, atlas = pcall(function() return C_RealmInfo.GetServerLogo(GetServerID()) end)
        if ok and type(atlas) == "string" then realm = atlas end
    end

    local ok = logo.SetAtlas and pcall(logo.SetAtlas, logo, realm or LOGO_FALLBACK)
    if not ok and realm and logo.SetAtlas then pcall(logo.SetAtlas, logo, LOGO_FALLBACK) end
    logo:SetSize(420, 252)

    local db = NS.db or {}
    f.dim:SetVertexColor(0, 0, 0, (db.escDim or 82) / 100)
    logo:SetShown(db.escLogo ~= false)
    f.who:SetShown(db.escWho ~= false)

    local model = f.model
    local kind = db.escModel or "lichking"
    model:ClearModel()
    if kind == "none" then
        model:Hide()
    else
        model:Show()
        if kind == "player" then
            model:SetUnit("player")
            model:SetFacing(-0.45)
        else
            model:SetModel(LICH_KING)
            model:SetFacing(-0.35)
        end
    end

    local name = UnitName("player") or ""
    local level = UnitLevel("player") or ""
    local class = UnitClass("player") or ""
    local realmName = GetRealmName and GetRealmName() or ""
    f.who:SetText(name .. "  -  " .. level .. " " .. class .. "  -  " .. realmName)
end

function Panel:UpdateCinematic()
    if not self.cine then self:CreateCinematic() end

    local f = self.cine
    local entries = self:Entries()
    local offset = 0

    for index, entry in ipairs(entries) do
        local row = f.rows[index]

        if not row then
            row = self:CreateCineRow(f.menu)
            f.rows[index] = row
        end

        if entry.gap and index > 1 then offset = offset + CINE_GROUP end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", f.menu, "TOPLEFT", 0, -offset)

        row.target = entry.button
        row.action = entry.action
        row.label:SetText(entry.text)
        row:SetAlpha(entry.enabled and 1 or 0.35)
        row:EnableMouse(entry.enabled and true or false)
        row:GetScript("OnLeave")(row)
        row:Show()

        offset = offset + CINE_ROW_H + CINE_GAP
    end

    for index = #entries + 1, #f.rows do
        f.rows[index].target = nil
        f.rows[index].action = nil
        f.rows[index]:Hide()
    end

    f.menu:SetHeight(math.max(offset, 1))
end

function Panel:Update()
    if not self.frame then self:Create() end

    local f = self.frame
    local entries = self:Entries()
    local offset = TITLE_H

    for index, entry in ipairs(entries) do
        local row = f.rows[index]

        if not row then
            row = self:CreateRow(f)
            f.rows[index] = row
        end

        if entry.gap and index > 1 then
            offset = offset + GROUP_GAP
            row.rule:Show()
        else
            row.rule:Hide()
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -offset)
        row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -offset)

        row.target = entry.button
        row.action = entry.action
        row.label:SetText(entry.text)
        row:SetAlpha(entry.enabled and 1 or 0.4)
        row:EnableMouse(entry.enabled and true or false)
        row:GetScript("OnLeave")(row)
        row:Show()

        offset = offset + ROW_H + ROW_GAP
    end

    for index = #entries + 1, #f.rows do
        f.rows[index].target = nil
        f.rows[index].action = nil
        f.rows[index]:Hide()
    end

    f:SetHeight(offset + BOTTOM_PAD)
end

local NEWS_PANELS = { "GameMenuFrameServerAnnounces", "GameMenuFrameServerChanges" }

function Panel:AdoptNews()
    local f = self.frame
    if not f then return end

    for index, name in ipairs(NEWS_PANELS) do
        local panel = _G[name]

        if panel and panel:IsShown() and not panel.narciAdopted then
            panel.narciAdopted = true
            panel.narciParent = panel:GetParent()
            panel.narciPoints = {}

            for point = 1, panel:GetNumPoints() do
                panel.narciPoints[point] = { panel:GetPoint(point) }
            end

            panel.narciHeight = panel:GetHeight()
            panel:SetParent(f)
            panel:ClearAllPoints()
            panel:SetHeight(math.min(540, UIParent:GetHeight() * 0.7))

            if index == 1 then
                panel:SetPoint("RIGHT", f, "LEFT", -14, 0)
            else
                panel:SetPoint("LEFT", f, "RIGHT", 14, 0)
            end
        end
    end
end

function Panel:ReleaseNews()
    for _, name in ipairs(NEWS_PANELS) do
        local panel = _G[name]

        if panel and panel.narciAdopted then
            panel.narciAdopted = nil
            panel:SetParent(panel.narciParent or _G.GameMenuFrame)
            panel:ClearAllPoints()

            if panel.narciHeight then panel:SetHeight(panel.narciHeight) end

            for _, point in ipairs(panel.narciPoints or {}) do
                pcall(panel.SetPoint, panel, unpack(point))
            end
        end
    end
end

function Panel:Release()
    self:ReleaseNews()

    local menu = _G.GameMenuFrame
    if menu and menu.narciAlpha then
        menu:SetAlpha(menu.narciAlpha)
        menu.narciAlpha = nil
    end

    if self.frame then self.frame:Hide() end
    if self.cine then self.cine:Hide() end
end

function Panel:Show()
    if not Enabled() then return end

    local menu = _G.GameMenuFrame
    if not menu then return end

    if not self.frame then self:Create() end

    menu.narciAlpha = menu.narciAlpha or menu:GetAlpha() or 1
    menu:SetAlpha(0)

    local scale = ((NS.db and NS.db.escScale) or 100) / 100
    if Cinematic() then
        if self.frame then self.frame:Hide() end
        self:UpdateCinematic()
        self.cine.menu:SetScale(scale)
        self:DressStage()
        if NS.Styling.FadeIn then NS.Styling.FadeIn(self.cine, 0.25) else self.cine:Show() end
        return
    end

    if self.cine then self.cine:Hide() end
    self:Update()
    self.frame:SetScale(scale)
    self.frame:Show()
    self:AdoptNews()

    if NS.After then
        NS.After(0.1, function()
            if self.frame and self.frame:IsShown() then self:AdoptNews() end
        end)
    end
end

function Panel:Hide()
    self:Release()
end

function Panel:Toggle()
    if (self.frame and self.frame:IsShown()) or (self.cine and self.cine:IsShown()) then
        self:Hide()
    else
        self:Show()
    end
end

function Panel:PlaceMenuButton()
    local menu, logout, button = _G.GameMenuFrame, _G.GameMenuButtonLogout, self.menuButton
    if not menu or not logout or not button then return end

    local _, relativeTo = logout:GetPoint()
    if relativeTo ~= button then
        button:ClearAllPoints()
        button:SetPoint("TOP", relativeTo or _G.GameMenuButtonMacros, "BOTTOM", 0, -1)
        logout:ClearAllPoints()
        logout:SetPoint("TOP", button, "BOTTOM", 0, -16)
    end

    menu:SetHeight(menu:GetHeight() + button:GetHeight() + 1)
end

function Panel:CreateMenuButton()
    local menu, logout = _G.GameMenuFrame, _G.GameMenuButtonLogout
    if self.menuButton or not menu or not logout then return end

    local button = CreateFrame("Button", "NarcissusSirus_GameMenuButton", menu, "GameMenuButtonTemplate")
    button:SetSize(logout:GetWidth(), logout:GetHeight())
    button:SetText("NarciUI")
    button:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(menu)
        if NS.Settings then
            NS.Settings:Create()
            NS.settingsFrame:Show()
        end
    end)

    self.menuButton = button

    menu:HookScript("OnShow", function() Panel:PlaceMenuButton() end)
end

function Panel:Hook()
    local menu = _G.GameMenuFrame
    if not menu or menu.narciMenuHook then return end
    menu.narciMenuHook = true

    self:CreateMenuButton()

    menu:HookScript("OnShow", function()
        if not Enabled() then return end
        local ok, err = pcall(function() Panel:Show() end)
        if not ok then NS.Print("меню: " .. tostring(err)) end
    end)

    menu:HookScript("OnHide", function()
        Panel:Release()
    end)

    if menu:IsShown() then Panel:Show() end
end

NS.GameMenuPanel = Panel

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
    Panel:Hook()
end)
