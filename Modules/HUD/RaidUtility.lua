local addonName, NS = ...
local L = NS.L

local RU = {}
NS.RaidUtility = RU

local WHITE = "Interface\\Buttons\\WHITE8x8"
local PANEL_W = 236
local MARKER_ICON = { [0] = 6, 4, 2, 3, 7, 5, 8, 1 }

local function Settings()
    if not NS.db then return end
    if type(NS.db.raidUtility) ~= "table" then NS.db.raidUtility = {} end
    local db = NS.db.raidUtility
    if db.enabled == nil then db.enabled = true end
    if db.partyToo == nil then db.partyToo = true end
    db.countdown = db.countdown or 10
    return db
end

RU.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function InRaid()
    return (GetNumRaidMembers() or 0) > 0
end

local function InGroup()
    return InRaid() or (GetNumPartyMembers() or 0) > 0
end

local function IsLeader()
    if InRaid() then return IsRaidLeader() and true or false end
    return IsPartyLeader() and true or false
end

local function CanLead()
    if InRaid() then return (IsRaidLeader() or IsRaidOfficer()) and true or false end
    return IsPartyLeader() and true or false
end

local function Skin(button, text, width, height)
    local S = NS.Styling
    button:SetSize(width, height or 20)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetTexture(WHITE)
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)
    button.narciEdges = S.CreateEdges(button, "BORDER", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.6)
    button.narciBg = bg
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    if text then
        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
        label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        label:SetPoint("CENTER")
        label:SetText(text)
        button.label = label
    end
    return button
end

local function Tooltip(button, text)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Plain(parent, text, width, onClick, tip)
    local button = NS.Widgets.CreateThemedButton(parent, text, width, 20, onClick)
    button:RegisterForClicks("AnyUp")
    if tip then Tooltip(button, tip) end
    return button
end

local function Header(parent, text, y)
    local S = NS.Styling
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(10), "")
    label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    label:SetText(text)
    return label
end

function RU:BuildToggle()
    if self.toggle then return self.toggle end
    local db = Settings()
    local S = NS.Styling

    local toggle = CreateFrame("Button", "NarciSirus_RaidUtilityToggle", UIParent)
    Skin(toggle, L["Рейд"], 90, 18)
    toggle:SetFrameStrata("MEDIUM")
    toggle:RegisterForClicks("AnyUp")
    if db.point then
        toggle:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        toggle:SetPoint("TOP", UIParent, "TOP", -320, -2)
    end
    toggle:SetScript("OnClick", function() RU:TogglePanel() end)
    Tooltip(toggle, L["Утилиты рейда: готовность, отсчёт, метки, главные танки"])
    toggle:Hide()

    if NS.Movers then
        NS.Movers:Register(toggle, L["Утилиты рейда"], function(point, relativePoint, x, y)
            local store = Settings()
            if not store then return end
            store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
        end, "raid")
    end

    self.toggle = toggle
    self:ApplyLook()
    return toggle
end

function RU:ApplyLook()
    local db = Settings()
    if not db then return end
    local S = NS.Styling
    local toggle = self.toggle
    if toggle then
        local style = db.toggleStyle or "theme"
        local themed = style == "theme"
        toggle.narciBg:SetShown(themed)
        for _, line in ipairs(toggle.narciEdges) do line:SetShown(themed) end
        S.SkinBox(toggle, themed and "none" or style, { alpha = 0.9 })
        toggle:SetSize(db.toggleWidth or 90, db.toggleHeight or 18)
    end
    local panel = self.panel
    if panel then
        local style = db.panelStyle or "theme"
        local themed = style == "theme"
        S.FadeChrome(panel, themed)
        if themed then
            panel:SetBackdropColor(S.Bg((db.panelAlpha or 94) / 100))
            panel:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        else
            panel:SetBackdropColor(0, 0, 0, 0)
            panel:SetBackdropBorderColor(0, 0, 0, 0)
        end
        S.SkinBox(panel, themed and "none" or style, { alpha = (db.panelAlpha or 94) / 100, glowSize = 10, shadowSize = 12, edgeSize = 16 })
    end
end

function RU:BuildPanel()
    if self.panel then return self.panel end
    if InCombatLockdown() then return end
    local S = NS.Styling

    local panel = CreateFrame("Frame", "NarciSirus_RaidUtility", UIParent)
    panel:SetWidth(PANEL_W)
    panel:SetFrameStrata("MEDIUM")
    panel:SetPoint("TOP", self:BuildToggle(), "BOTTOM", 0, -4)
    panel:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    panel:SetBackdropColor(S.Bg(0.94))
    panel:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    panel:EnableMouse(true)
    S.CreateShadow(panel, 5, 0.4)
    panel:Hide()

    local half = (PANEL_W - 26) / 2
    local y = -10

    Header(panel, L["Группа"], y)
    y = y - 16
    local ready = Plain(panel, READY_CHECK or L["Готовность"], half, function()
        if CanLead() then DoReadyCheck() end
    end)
    ready:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
    local count = Plain(panel, L["Отсчёт"], half, function(_, button)
        if not (C_PartyInfo and C_PartyInfo.DoCountdown) then return end
        if button == "RightButton" then
            C_PartyInfo.DoCountdown(0)
        else
            C_PartyInfo.DoCountdown(Settings().countdown or 10)
        end
    end, L["Левый клик - начать отсчёт перед пуллом, правый - отменить"])
    count:SetPoint("TOPLEFT", ready, "TOPRIGHT", 6, 0)
    y = y - 24

    local roles = Plain(panel, L["Проверка ролей"], half, function()
        if CanLead() and type(InitiateRolePoll) == "function" then InitiateRolePoll() end
    end)
    roles:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
    local convert = Plain(panel, L["В рейд"], half, function()
        if not InRaid() and IsPartyLeader() and type(ConvertToRaid) == "function" then ConvertToRaid() end
    end, L["Превратить группу в рейд"])
    convert:SetPoint("TOPLEFT", roles, "TOPRIGHT", 6, 0)
    y = y - 24

    local tank = Skin(CreateFrame("Button", "NarciSirus_RaidUtilityTank", panel, "SecureActionButtonTemplate"), MAINTANK or L["Главный танк"], half)
    tank:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
    tank:SetAttribute("type", "maintank")
    tank:SetAttribute("unit", "target")
    tank:SetAttribute("action", "toggle")
    Tooltip(tank, L["Назначить цель главным танком или снять назначение"])
    local assist = Skin(CreateFrame("Button", "NarciSirus_RaidUtilityAssist", panel, "SecureActionButtonTemplate"), MAINASSIST or L["Помощник"], half)
    assist:SetPoint("TOPLEFT", tank, "TOPRIGHT", 6, 0)
    assist:SetAttribute("type", "mainassist")
    assist:SetAttribute("unit", "target")
    assist:SetAttribute("action", "toggle")
    Tooltip(assist, L["Назначить цель главным помощником или снять назначение"])
    y = y - 30

    Header(panel, L["Метка на цель"], y)
    y = y - 16
    local size = math.floor((PANEL_W - 20 - 8 * 3) / 9)
    local previous
    for index = 1, 9 do
        local icon = index <= 8 and index or 0
        local button = CreateFrame("Button", nil, panel)
        button:SetSize(size, size)
        button:RegisterForClicks("AnyUp")
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 3, 0)
        else
            button:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
        end
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints(button)
        if icon > 0 then
            texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            SetRaidTargetIconTexture(texture, icon)
        else
            texture:SetTexture(S.Media("IconClose"))
            texture:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints(button)
        hover:SetTexture(WHITE)
        hover:SetVertexColor(1, 1, 1, 0.2)
        button:SetScript("OnClick", function(_, mouse)
            if not UnitExists("target") then return end
            SetRaidTarget("target", (mouse == "RightButton") and 0 or icon)
        end)
        previous = button
    end
    y = y - size - 10

    Header(panel, L["Метки на землю"], y)
    y = y - 16
    previous = nil
    for marker = 0, 7 do
        local button = CreateFrame("Button", "NarciSirus_RaidUtilityMarker" .. marker, panel, "SecureActionButtonTemplate")
        button:SetSize(size, size)
        button:RegisterForClicks("AnyUp")
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", "/wm " .. marker)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 3, 0)
        else
            button:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
        end
        local back = button:CreateTexture(nil, "BACKGROUND")
        back:SetAllPoints(button)
        back:SetTexture(WHITE)
        back:SetVertexColor(0, 0, 0, 0.5)
        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        SetRaidTargetIconTexture(texture, MARKER_ICON[marker])
        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints(button)
        hover:SetTexture(WHITE)
        hover:SetVertexColor(1, 1, 1, 0.2)
        previous = button
    end
    local clear = CreateFrame("Button", nil, panel)
    clear:SetSize(size, size)
    clear:SetPoint("LEFT", previous, "RIGHT", 3, 0)
    local clearTexture = clear:CreateTexture(nil, "ARTWORK")
    clearTexture:SetAllPoints(clear)
    clearTexture:SetTexture(S.Media("IconClose"))
    clearTexture:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    clear:SetScript("OnClick", function()
        if type(ClearRaidMarker) == "function" then ClearRaidMarker() end
    end)
    Tooltip(clear, L["Снять все метки на земле"])
    y = y - size - 10

    local everyone
    if type(SetEveryoneIsAssistant) == "function" and type(IsEveryoneAssistant) == "function" then
        everyone = NS.Widgets.CreateThemedCheckbox(panel, L["Все помощники"], IsEveryoneAssistant(), function(value)
            if IsLeader() and InRaid() then SetEveryoneIsAssistant(value and true or false) end
        end)
        everyone:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
        y = y - 24
    end

    local disband = Plain(panel, L["Распустить группу"], PANEL_W - 20, function()
        if not IsLeader() then return end
        NS.Widgets.ShowConfirm(L["Распустить группу? Все участники будут исключены."], L["Распустить"], function()
            RU:Disband()
        end)
    end)
    disband:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
    y = y - 30

    panel:SetHeight(-y)

    self.leaderOnly = { ready, count, roles, disband }
    self.roles = roles
    self.convert = convert
    self.everyone = everyone
    self.panel = panel
    self:ApplyLook()
    return panel
end

function RU:Disband()
    if not IsLeader() then return end
    if InRaid() then
        for index = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(index)
            if name and name ~= UnitName("player") then UninviteUnit(name) end
        end
    else
        for index = GetNumPartyMembers(), 1, -1 do
            local name = UnitName("party" .. index)
            if name then UninviteUnit(name) end
        end
    end
    LeaveParty()
end

function RU:Refresh()
    if not self.panel then return end
    local lead = CanLead()
    for _, button in ipairs(self.leaderOnly) do
        button:SetAlpha(lead and 1 or 0.4)
    end
    if type(InitiateRolePoll) ~= "function" then self.roles:SetAlpha(0.4) end
    self.convert:SetShown(not InRaid())
    if self.everyone then
        self.everyone:SetChecked(IsEveryoneAssistant())
        self.everyone:SetAlpha((IsLeader() and InRaid()) and 1 or 0.4)
    end
end

function RU:TogglePanel()
    local panel = self.panel or self:BuildPanel()
    if not panel then
        NS.Print(L["Панель рейда откроется после боя"])
        return
    end
    if InCombatLockdown() then
        NS.Print(L["Панель рейда откроется после боя"])
        return
    end
    if panel:IsShown() then
        panel:Hide()
    else
        self:Refresh()
        panel:SetAlpha(1)
        panel:Show()
    end
end

function RU:ClosePanel()
    local panel = self.panel
    if not panel or not panel:IsShown() then return end
    if InCombatLockdown() then
        panel:SetAlpha(0)
        self.hidePending = true
        return
    end
    panel:Hide()
end

function RU:Update()
    if InCombatLockdown() then
        self.updatePending = true
        return
    end
    self.updatePending = nil
    if not Enabled() then
        if self.toggle then self.toggle:Hide() end
        self:ClosePanel()
        return
    end
    local db = Settings()
    local shown = InRaid() or (db.partyToo and InGroup())
    self:BuildToggle():SetShown(shown and true or false)
    if not shown then self:ClosePanel() end
    self:Refresh()
end

function RU:PrepareMove()
    if not Enabled() then return end
    if NS.Movers and not self.narciFinish then
        self.narciFinish = true
        table.insert(NS.Movers.finish, function() RU:Update() end)
    end
    self:BuildToggle():Show()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("RAID_ROSTER_UPDATE")
driver:RegisterEvent("PARTY_MEMBERS_CHANGED")
driver:RegisterEvent("PARTY_LEADER_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Settings()
        if NS.After then NS.After(2, function() RU:Update() end) end
        return
    end
    if not Enabled() and not RU.toggle then return end
    if event == "PLAYER_REGEN_ENABLED" then
        if RU.hidePending then
            RU.hidePending = nil
            if RU.panel and RU.panel:GetAlpha() == 0 then RU.panel:Hide() end
        end
    end
    RU:Update()
end)
