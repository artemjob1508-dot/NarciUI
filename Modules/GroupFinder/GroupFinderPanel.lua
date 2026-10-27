local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local ROLE_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"

local PANEL_W = 860
local PANEL_H = 588
local PAD = 18
local RAIL_W = 198
local ROW_H = 24
local ROWS = 12

NS.Densify("NarcissusSirus_GroupFinder", function(f)
    ROW_H, ROWS = NS.DensityRows(24, 12, f)
end)
local LIST_TOP = 196
local LIST_BOTTOM = 76

local TABS = {
    { key = "lfg" },
    { key = "pvp" },
    { key = "mythic" },
    { key = "ladder" },
}

local CATEGORIES = {
    { key = "dungeons",  icon = "Interface\\Icons\\INV_Helmet_08" },
    { key = "minigames", icon = "Interface\\Icons\\inv_misc_toy_07" },
    { key = "premade",   icon = "Interface\\Icons\\Achievement_General_StayClassy" },
}

local ROLES = {
    { key = "tank",   role = "TANK" },
    { key = "healer", role = "HEALER" },
    { key = "damage", role = "DAMAGER" },
    { key = "leader", role = "GUIDE" },
}

local FIELDS = {
    name = 1,
    typeID = 2,
    minLevel = 3,
    maxLevel = 4,
    recLevel = 5,
    groupID = 9,
}

local function Field(key)
    local map = LFG_RETURN_VALUES or FIELDS
    return map[key] or FIELDS[key]
end

local function TabLabel(key)
    if key == "lfg" then return LOOK_FOR_GROUP or L["Поиск группы"] end
    if key == "pvp" then return PLAYER_V_PLAYER or L["Игрок против игрока"] end
    if key == "mythic" then return MYTHIC_PLUS_TAB_NAME or L["Эпохальные подземелья"] end
    return LADDER_TAB_NAME or L["Таблицы лидеров"]
end

local function CategoryLabel(key)
    if key == "dungeons" then return LOOKING_FOR_DUNGEON or L["Поиск подземелий"] end
    if key == "minigames" then return MINI_GAMES or L["Мини-игры"] end
    return LFGLIST_NAME or L["Заранее собранные группы"]
end

local function RoleLabel(key)
    if key == "tank" then return TANK or L["Танк"] end
    if key == "healer" then return HEALER or L["Лекарь"] end
    if key == "damage" then return DAMAGER or L["Боец"] end
    return LEADER or L["Лидер"]
end

local function DifficultyColor(level)
    if GetQuestDifficultyColor then
        local color = GetQuestDifficultyColor(level or 0)
        if color then return color.r, color.g, color.b end
    end
    return 0.85, 0.85, 0.88
end

local function QualityColor(quality)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b end
    return 0.55, 0.55, 0.6
end

local function DungeonInfo(id)
    if LFGGetDungeonInfoByID then
        local info = LFGGetDungeonInfoByID(id)
        if info then return info end
    end
    return nil
end

local function IsHeader(id)
    return id and id < 0
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

local function CreateCheck(parent, size, onClick)
    local S = NS.Styling
    size = size or 13

    local check = CreateFrame("Button", nil, parent)
    check:SetSize(size, size)

    local bg = check:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local border = CreateFrame("Frame", nil, check)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    check.border = border

    local fill = check:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", -2, 2)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    fill:Hide()
    check.fill = fill

    check:SetHighlightTexture(WHITE, "ADD")
    check:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)

    function check:SetChecked(value)
        self.checked = value and true or false
        local S2 = NS.Styling
        if self.checked then
            self.fill:Show()
            self.border:SetBackdropBorderColor(S2.ACCENT[1], S2.ACCENT[2], S2.ACCENT[3], 0.95)
        else
            self.fill:Hide()
            self.border:SetBackdropBorderColor(S2.BORDER[1], S2.BORDER[2], S2.BORDER[3], 0.9)
        end
    end

    check:SetChecked(false)
    if onClick then check:SetScript("OnClick", onClick) end

    return check
end

Panel.Chrome = Chrome
Panel.Caption = Caption
Panel.CreateCheck = CreateCheck
Panel.ROW_HEIGHT = ROW_H

function Panel:Geometry()
    return PAD + RAIL_W + 22, PANEL_W - (PAD + RAIL_W + 22) - PAD, LIST_TOP, LIST_BOTTOM, PAD
end

function Panel:PageFor(key)
    if key == "minigames" then return NS.MiniGamesPage end
    if key == "premade" then return NS.PremadeGroupsPage end
    if key == "pvp" then return NS.PvPPage end
    if key == "mythic" then return NS.MythicPlusPage end
    if key == "ladder" then return NS.LadderPage end
    return nil
end

function Panel:TabPages()
    return { "pvp", "mythic", "ladder" }
end

function Panel:SyncPages()
    for _, key in ipairs({ "minigames", "premade", "pvp", "mythic", "ladder" }) do
        local page = self:PageFor(key)
        if page and page.frame then
            if key == self.category and self.tab == "lfg" then
                page:Show()
            elseif key == self.tab and self.tab ~= "lfg" then
                page:Show()
            else
                page:Hide()
            end
        end
    end
end

function Panel:EnsureLists()
    if LFGDungeonList_Setup then pcall(LFGDungeonList_Setup) end
    if LFDQueueFrame_Update then pcall(LFDQueueFrame_Update) end
end

function Panel:Entries()
    local list = LFDDungeonList or {}
    local entries = {}
    for index = 1, #list do entries[index] = list[index] end
    return entries
end

function Panel:DungeonCount()
    local total = 0
    for _, id in ipairs(self:Entries()) do
        if not IsHeader(id) then total = total + 1 end
    end
    for _, id in pairs(LFDHiddenByCollapseList or {}) do
        if not IsHeader(id) then total = total + 1 end
    end
    return total
end

function Panel:QueueType()
    if LFDQueueFrame and LFDQueueFrame.type then return LFDQueueFrame.type end
    return self.queueType or "specific"
end

function Panel:SetQueueType(value)
    self.queueType = value

    if LFDQueueFrame_SetType then
        pcall(LFDQueueFrame_SetType, value)
    elseif LFDQueueFrame then
        LFDQueueFrame.type = value
    end

    self:Update()
end

function Panel:TypeEntries()
    local entries = {
        { value = "specific", label = SPECIFIC_DUNGEONS or L["Конкретное подземелье"] },
    }

    local total = GetNumRandomDungeons and GetNumRandomDungeons() or 0
    local level = UnitLevel("player")
    local expansion = GetExpansionLevel and GetExpansionLevel() or 0

    for index = 1, total do
        local id, name = GetLFGRandomDungeonInfo(index)
        if id and name then
            local _, _, minLevel, maxLevel, _, _, _, expansionLevel = GetLFGDungeonInfo(id)
            local fits = level >= (minLevel or 0) and level <= (maxLevel or 0)
                and expansion >= (expansionLevel or 0)

            if fits then
                local joinable = not IsLFGDungeonJoinable or IsLFGDungeonJoinable(id)
                entries[#entries + 1] = {
                    value = id,
                    label = joinable and name or ("|cff808080" .. name .. "|r"),
                    locked = not joinable,
                }
            end
        end
    end

    return entries
end

function Panel:RandomGroupID(dungeonID)
    local total = GetNumRandomDungeons and GetNumRandomDungeons() or 0

    for index = 1, total do
        local id, _, _, _, _, _, _, _, _, groupID = GetLFGRandomDungeonInfo(index)
        if id == dungeonID then return groupID end
    end

    return nil
end

function Panel:Roles()
    if not GetLFGRoles then return false, false, false, false end
    return GetLFGRoles()
end

function Panel:ApplyRoles()
    if not SetLFGRoles then return end

    local buttons = self.frame.roles
    SetLFGRoles(buttons.leader.checked, buttons.tank.checked,
        buttons.healer.checked, buttons.damage.checked)

    self:Update()
end

function Panel:Mode()
    if not GetLFGMode then return nil end
    return GetLFGMode()
end

function Panel:CreateRail(f)
    local S = NS.Styling

    f.categories = {}

    for index, category in ipairs(CATEGORIES) do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(RAIL_W, 66)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -76 - (index - 1) * 74)
        Chrome(button)

        local glow = button:CreateTexture(nil, "BORDER")
        glow:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        glow:SetTexture(WHITE)
        glow:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.24,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
        glow:Hide()
        button.glow = glow

        local bar = button:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -3)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("LEFT", button, "LEFT", 14, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetTexture(category.icon)
        button.icon = icon

        local iconBorder = CreateFrame("Frame", nil, button)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        iconBorder:SetBackdropBorderColor(0, 0, 0, 0.85)
        iconBorder:EnableMouse(false)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(12), "")
        label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -3)
        label:SetWidth(RAIL_W - 76)
        label:SetJustifyH("LEFT")
        label:SetText(CategoryLabel(category.key))
        button.label = label

        local note = button:CreateFontString(nil, "OVERLAY")
        note:SetFont(NS.FONT, NS.FS(10), "")
        note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        note:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 12, 2)
        note:SetWidth(RAIL_W - 76)
        note:SetJustifyH("LEFT")
        button.note = note

        button:SetScript("OnEnter", function(self)
            if not self.active then self.glow:Show() end
        end)
        button:SetScript("OnLeave", function(self)
            if not self.active then self.glow:Hide() end
        end)

        button:SetScript("OnClick", function()
            Panel.category = category.key
            Panel:Update()
        end)

        f.categories[category.key] = button
    end
end

function Panel:CreateRoles(parent, x)
    local S = NS.Styling
    local f = self.frame

    f.roles = {}

    for index, role in ipairs(ROLES) do
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(58, 62)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", x + (index - 1) * 66, -86)
        Chrome(button)

        local glow = button:CreateTexture(nil, "BORDER")
        glow:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        glow:SetTexture(WHITE)
        glow:SetGradientAlpha("VERTICAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28)
        glow:Hide()
        button.glow = glow

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("TOP", button, "TOP", 0, -7)
        icon:SetTexture(ROLE_TEXTURE)
        if GetTexCoordsForRole then
            icon:SetTexCoord(GetTexCoordsForRole(role.role))
        end
        button.icon = icon

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "")
        label:SetPoint("BOTTOM", button, "BOTTOM", 0, 6)
        label:SetText(RoleLabel(role.key))
        button.label = label

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 3)
        bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetScript("OnClick", function(self)
            if self.locked then return end
            self.checked = not self.checked
            Panel:ApplyRoles()
        end)

        button:SetScript("OnEnter", function(self)
            if not self.checked and not self.locked then self.glow:Show() end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(RoleLabel(role.key), 1, 1, 1)
            if self.lockReason then
                GameTooltip:AddLine(self.lockReason, 0.85, 0.5, 0.5, true)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            if not self.checked then self.glow:Hide() end
            GameTooltip:Hide()
        end)

        f.roles[role.key] = button
    end
end

function Panel:CreateRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -6 - (index - 1) * ROW_H)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.26 or 0.10)
    row.plate = plate

    local glow = row:CreateTexture(nil, "BORDER")
    glow:SetAllPoints()
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
    glow:Hide()
    row.glow = glow

    local bar = row:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    bar:Hide()
    row.bar = bar

    local expand = CreateFrame("Button", nil, row)
    expand:SetSize(16, 16)
    expand:SetPoint("LEFT", row, "LEFT", 8, 0)

    local expandText = expand:CreateFontString(nil, "OVERLAY")
    expandText:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    expandText:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    expandText:SetPoint("CENTER")
    expand.text = expandText

    expand:SetScript("OnClick", function()
        if not row.id then return end
        if LFDList_SetHeaderCollapsed then
            LFDList_SetHeaderCollapsed(row.id, not row.collapsed)
        end
        Panel:Update()
    end)
    row.expand = expand

    local check = CreateCheck(row, 13, function(self)
        if row.locked or not row.id then return end
        Panel:SetEnabled(row.id, not self.checked)
    end)
    check:SetPoint("LEFT", row, "LEFT", 28, 0)
    row.check = check

    local lock = row:CreateTexture(nil, "ARTWORK")
    lock:SetSize(14, 14)
    lock:SetPoint("LEFT", row, "LEFT", 28, 0)
    lock:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK")
    lock:Hide()
    row.lock = lock

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", row, "LEFT", 50, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local level = row:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(11), "")
    level:SetWidth(90)
    level:SetPoint("LEFT", name, "RIGHT", 12, 0)
    level:SetJustifyH("LEFT")
    row.level = level

    local note = row:CreateFontString(nil, "OVERLAY")
    note:SetFont(NS.FONT, NS.FS(10), "")
    note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    note:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    note:SetJustifyH("RIGHT")
    row.note = note

    row:SetScript("OnEnter", function(self)
        self.glow:Show()

        if not self.id or not self.locked then return end
        if IsHeader(self.id) then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(YOU_MAY_NOT_QUEUE_FOR_DUNGEON or L["Вы не можете встать в очередь"], 1, 1, 1)

        local players = GetLFDLockPlayerCount and GetLFDLockPlayerCount() or 0
        for player = 1, players do
            local playerName, reason = GetLFDLockInfo(self.id, player)
            if reason and reason ~= 0 then
                local who = player == 1 and "SELF_" or "OTHER_"
                local key = "INSTANCE_UNAVAILABLE_" .. who ..
                    ((LFG_INSTANCE_INVALID_CODES and LFG_INSTANCE_INVALID_CODES[reason]) or "OTHER")
                local text = _G[key]
                if text then GameTooltip:AddLine(string.format(text, playerName), 0.85, 0.5, 0.5) end
            end
        end

        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function(self)
        self.glow:Hide()
        GameTooltip:Hide()
    end)

    row:SetScript("OnClick", function(self)
        if not self.id then return end

        if IsHeader(self.id) then
            if LFDList_SetHeaderCollapsed then
                LFDList_SetHeaderCollapsed(self.id, not self.collapsed)
            end
            Panel:Update()
            return
        end

        if self.locked then return end
        Panel:SetEnabled(self.id, not self.check.checked)
    end)

    row:Hide()
    return row
end

function Panel:SetEnabled(id, enabled)
    if IsHeader(id) then
        if LFDList_SetHeaderEnabled then LFDList_SetHeaderEnabled(id, enabled) end
    else
        if LFDList_SetDungeonEnabled then LFDList_SetDungeonEnabled(id, enabled) end
        if LFGListUpdateHeaderEnabledAndLockedStates then
            LFGListUpdateHeaderEnabledAndLockedStates(LFDDungeonList, LFGEnabledList,
                LFGLockList, LFDHiddenByCollapseList)
        end
    end

    self:Update()
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_GroupFinder", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

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
    title:SetText(LOOK_FOR_GROUP or L["Поиск группы"])

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    S.CreateAnimatedSeparator(f, -58)

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    self.frame = f
    self:CreateRail(f)

    local contentX = PAD + RAIL_W + 22
    local contentW = PANEL_W - contentX - PAD

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", contentX - 14, -70)
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", contentX - 14, 18)
    divider:SetTexture(WHITE)
    divider:SetGradientAlpha("VERTICAL",
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.1,
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.7)
    f.divider = divider

    local rolesCaption = Caption(f, L["ВАШИ РОЛИ"])
    rolesCaption:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -72)
    f.rolesCaption = rolesCaption
    f.rolesRule = S.CreateSectionRule(f, rolesCaption, contentW)

    self:CreateRoles(f, contentX)

    local typeCaption = Caption(f, L["ТИП ОЧЕРЕДИ"])
    typeCaption:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -160)
    f.typeCaption = typeCaption

    local typeDrop = NS.Widgets.CreateThemedDropdown(f, contentW - 116, function(value)
        Panel:SetQueueType(value)
    end)
    typeDrop:SetPoint("TOPLEFT", f, "TOPLEFT", contentX + 108, -156)
    f.typeDrop = typeDrop

    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -LIST_TOP)
    list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, LIST_BOTTOM)
    Chrome(list)
    f.list = list

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(list, index)
    end

    local track = list:CreateTexture(nil, "ARTWORK")
    track:SetWidth(3)
    track:SetPoint("TOPRIGHT", list, "TOPRIGHT", -5, -6)
    track:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -5, 6)
    track:SetTexture(WHITE)
    track:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.5)
    f.track = track

    local thumb = list:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(3)
    thumb:SetTexture(WHITE)
    thumb:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.85)
    f.thumb = thumb

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        if Panel.category ~= "dungeons" or Panel:QueueType() ~= "specific" then return end
        Panel.offset = math.max(0, (Panel.offset or 0) - delta)
        Panel:Update()
    end)

    local randomTitle = list:CreateFontString(nil, "OVERLAY")
    randomTitle:SetFont(NS.FONT, NS.FS(15), "OUTLINE")
    randomTitle:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    randomTitle:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -14)
    randomTitle:SetWidth(300)
    randomTitle:SetJustifyH("LEFT")
    f.randomTitle = randomTitle

    local randomMeta = list:CreateFontString(nil, "OVERLAY")
    randomMeta:SetFont(NS.FONT, NS.FS(11), "")
    randomMeta:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    randomMeta:SetPoint("TOPLEFT", randomTitle, "BOTTOMLEFT", 0, -6)
    f.randomMeta = randomMeta

    local randomText = list:CreateFontString(nil, "OVERLAY")
    randomText:SetFont(NS.FONT, NS.FS(11), "")
    randomText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    randomText:SetPoint("TOPLEFT", randomMeta, "BOTTOMLEFT", 0, -10)
    randomText:SetWidth(300)
    randomText:SetJustifyH("LEFT")
    f.randomText = randomText

    local rewardCaption = Caption(list, LFD_REWARDS or L["Награды"])
    rewardCaption:SetPoint("TOPLEFT", randomText, "BOTTOMLEFT", 0, -16)
    f.rewardCaption = rewardCaption
    f.rewardRule = S.CreateSectionRule(list, rewardCaption, 300)

    f.rewards = {}
    for index = 1, 5 do
        local button = CreateFrame("Button", nil, list)
        button:SetSize(42, 42)
        if index == 1 then
            button:SetPoint("TOPLEFT", rewardCaption, "BOTTOMLEFT", 0, -14)
        else
            button:SetPoint("LEFT", f.rewards[index - 1], "RIGHT", 10, 0)
        end

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        local count = button:CreateFontString(nil, "OVERLAY")
        count:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.count = count

        button:SetScript("OnEnter", function(self)
            if not self.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if not pcall(GameTooltip.SetHyperlink, GameTooltip, self.link) then
                GameTooltip:AddLine(self.itemName or "", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button:Hide()
        f.rewards[index] = button
    end

    local rewardText = list:CreateFontString(nil, "OVERLAY")
    rewardText:SetFont(NS.FONT, NS.FS(11), "")
    rewardText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    rewardText:SetPoint("TOPLEFT", f.rewards[1], "BOTTOMLEFT", 0, -12)
    rewardText:SetWidth(300)
    rewardText:SetJustifyH("LEFT")
    f.rewardText = rewardText

    local poolCaption = Caption(list, L["ВХОДЯТ ПОДЗЕМЕЛЬЯ"])
    poolCaption:SetPoint("TOPLEFT", list, "TOPLEFT", 340, -14)
    f.poolCaption = poolCaption
    f.poolRule = S.CreateSectionRule(list, poolCaption, contentW - 380)

    f.pool = {}
    for index = 1, 14 do
        local text = list:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetJustifyH("LEFT")
        text:SetWidth(contentW - 380)
        text:SetPoint("TOPLEFT", list, "TOPLEFT", 340, -36 - (index - 1) * 19)

        f.pool[index] = text
    end

    local lock = CreateFrame("Frame", nil, list)
    lock:SetAllPoints(list)
    lock:SetFrameLevel(list:GetFrameLevel() + 20)
    lock:EnableMouse(true)
    lock:Hide()
    local lockBg = lock:CreateTexture(nil, "BACKGROUND")
    lockBg:SetAllPoints()
    lockBg:SetTexture(WHITE)
    lockBg:SetVertexColor(0.02, 0.02, 0.03, 0.9)

    local lockIcon = lock:CreateTexture(nil, "ARTWORK")
    lockIcon:SetSize(44, 44)
    lockIcon:SetTexture("Interface\\Icons\\Ability_Druid_Cower")
    lockIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    lock.icon = lockIcon

    local lockText = lock:CreateFontString(nil, "OVERLAY")
    lockText:SetFont(NS.FONT, NS.FS(13), "")
    lockText:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    lockText:SetWidth(contentW - 80)
    lockText:SetJustifyH("CENTER")
    lock.text = lockText

    local lockTime = lock:CreateFontString(nil, "OVERLAY")
    lockTime:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    lockTime:SetTextColor(1, 0.35, 0.3)
    lockTime:SetPoint("TOP", lockText, "BOTTOM", 0, -10)
    lock.time = lockTime

    lock.names, lock.states = {}, {}
    for index = 1, 4 do
        local name = lock:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(12), "")
        name:SetJustifyH("RIGHT")
        name:SetWidth(180)
        name:SetPoint("TOPRIGHT", lock, "TOP", -8, -40 - (index - 1) * 20)
        local state = lock:CreateFontString(nil, "OVERLAY")
        state:SetFont(NS.FONT, NS.FS(12), "")
        state:SetJustifyH("LEFT")
        state:SetWidth(180)
        state:SetPoint("TOPLEFT", lock, "TOP", 8, -40 - (index - 1) * 20)
        lock.names[index], lock.states[index] = name, state
    end

    lock:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) + elapsed
        if self.wait < 0.25 then return end
        self.wait = 0
        if not self.expires then return end
        local left = self.expires - GetTime()
        if left > 0 then
            self.time:SetText(SecondsToTime(math.ceil(left)))
        else
            Panel:Update()
        end
    end)
    f.lock = lock

    local lockEvents = CreateFrame("Frame")
    lockEvents:RegisterEvent("UNIT_AURA")
    lockEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    lockEvents:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" and unit ~= "player" and not (unit and unit:sub(1, 5) == "party") then return end
        if Panel.frame and Panel.frame:IsShown() and Panel.category == "dungeons" and Panel.tab == "lfg" then
            Panel:UpdateStatus()
        end
    end)

    local placeholder = f:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(NS.FONT, NS.FS(12), "")
    placeholder:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    placeholder:SetPoint("TOPLEFT", f, "TOPLEFT", contentX, -80)
    placeholder:SetWidth(contentW)
    placeholder:SetJustifyH("LEFT")
    placeholder:Hide()
    f.placeholder = placeholder

    local status = f:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", contentX, 28)
    status:SetWidth(contentW - 230)
    status:SetJustifyH("LEFT")
    f.status = status

    local join = CreateFrame("Button", nil, f)
    join:SetSize(210, 30)
    join:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 20)

    local joinBg = join:CreateTexture(nil, "BACKGROUND")
    joinBg:SetAllPoints()
    joinBg:SetTexture(WHITE)
    joinBg:SetGradientAlpha("VERTICAL",
        S.ACCENT[1] * 0.35, S.ACCENT[2] * 0.35, S.ACCENT[3] * 0.35, 0.95,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)
    join.bg = joinBg

    local joinBorder = CreateFrame("Frame", nil, join)
    joinBorder:SetPoint("TOPLEFT", -1, 1)
    joinBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    joinBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    joinBorder:SetBackdropBorderColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    joinBorder:EnableMouse(false)
    join.border = joinBorder

    local joinLabel = join:CreateFontString(nil, "OVERLAY")
    joinLabel:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    joinLabel:SetTextColor(1, 1, 1)
    joinLabel:SetPoint("CENTER")
    joinLabel:SetText(FIND_A_GROUP or L["Найти группу"])
    join.label = joinLabel

    join:SetHighlightTexture(WHITE, "ADD")
    join:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.22)
    join.SetText = function(self, text) self.label:SetText(text) end
    join:SetScript("OnClick", function() Panel:JoinOrLeave() end)
    f.join = join

    f.tabs = {}
    for index, tab in ipairs(TABS) do
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(26)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(TabLabel(tab.key))
        button.label = label

        button:SetWidth(math.max(label:GetStringWidth() + 26, 120))

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
    for index, button in ipairs(f.tabs) do
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x, -30)
        x = x + button:GetWidth() + 6
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("LFG_UPDATE")
    events:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
    events:RegisterEvent("LFG_ROLE_UPDATE")
    events:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
    events:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:SetScript("OnEvent", function()
        if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_GroupFinder")

    self.category = self.category or "dungeons"
    self.tab = self.tab or "lfg"
    self.offset = self.offset or 0
    f:Hide()
end

function Panel:JoinOrLeave()
    local mode = self:Mode()

    if mode == "queued" or mode == "listed" or mode == "rolecheck" then
        if LeaveLFG then LeaveLFG() end
    elseif LFDQueueFrame_Join then
        LFDQueueFrame_Join()
    end

    NS.After(0.5, function() Panel:Update() end)
end

function Panel:UpdateRoles()
    local f = self.frame
    local S = NS.Styling

    local leader, tank, healer, damage = self:Roles()
    local values = { leader = leader, tank = tank, healer = healer, damage = damage }

    local canTank, canHealer, canDamage = true, true, true
    if GetAvailableRoles then canTank, canHealer, canDamage = GetAvailableRoles() end

    local canLead = (GetNumPartyMembers() == 0 or IsPartyLeader())
        and (GetNumRaidMembers() == 0 or IsRaidLeader())

    local mode = self:Mode()
    local frozen = mode == "queued" or mode == "listed" or mode == "rolecheck" or mode == "proposal"

    local allowed = {
        tank = canTank, healer = canHealer, damage = canDamage, leader = canLead,
    }

    for key, button in pairs(f.roles) do
        local available = allowed[key] and not frozen
        button.checked = values[key] and true or false
        button.locked = not available
        button.lockReason = frozen and L["в очереди роли не меняются"] or nil

        if button.checked then
            button:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            button.glow:Show()
            button.bar:Show()
            button.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            button.icon:SetDesaturated(false)
        else
            button:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            button.glow:Hide()
            button.bar:Hide()
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            button.icon:SetDesaturated(true)
        end

        button:SetAlpha(available and 1 or 0.4)
    end
end

function Panel:UpdateList()
    local f = self.frame
    local S = NS.Styling

    local entries = self:Entries()
    local maxOffset = math.max(0, #entries - ROWS)
    self.offset = math.min(self.offset or 0, maxOffset)

    local mode = self:Mode()
    local queued = mode == "queued" or mode == "listed"
    local source = (queued and LFGQueuedForList) or LFGEnabledList or {}

    for index = 1, ROWS do
        local row = f.rows[index]
        local id = entries[index + self.offset]

        if id then
            local info = DungeonInfo(id)
            row.id = id
            row.locked = LFGLockList and LFGLockList[id] and true or false
            row.note:SetText("")

            local name = info and info[Field("name")] or ("#" .. id)

            if IsHeader(id) then
                row.collapsed = LFGCollapseList and LFGCollapseList[id] and true or false
                row.expand:Show()
                row.expand.text:SetText(row.collapsed and "+" or "-")
                row.name:SetText(name)
                row.name:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
                row.level:SetText("")
                row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)
                row.bar:Show()

                local children = LFGGetDungeonListByHeaderID and LFGGetDungeonListByHeaderID(-id)
                if children then
                    row.note:SetText(string.format(L["подземелий: %d"], #children))
                end
            else
                row.collapsed = false
                row.expand:Hide()
                row.bar:Hide()
                row.name:SetText(name)
                row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                    index % 2 == 0 and 0.26 or 0.10)

                local minLevel = info and info[Field("minLevel")] or 0
                local maxLevel = info and info[Field("maxLevel")] or 0
                local recLevel = info and info[Field("recLevel")] or 0

                if minLevel == maxLevel then
                    row.level:SetText(string.format(LFD_LEVEL_FORMAT_SINGLE or "(%d)", minLevel))
                else
                    row.level:SetText(string.format(LFD_LEVEL_FORMAT_RANGE or "(%d-%d)", minLevel, maxLevel))
                end

                local red, green, blue = DifficultyColor(recLevel)
                row.name:SetTextColor(red, green, blue)
                row.level:SetTextColor(red * 0.7, green * 0.7, blue * 0.7)
            end

            if row.locked then
                row.check:Hide()
                row.lock:Show()
                row.name:SetTextColor(0.5, 0.5, 0.52)
                row.level:SetTextColor(0.5, 0.5, 0.52)
            else
                row.lock:Hide()
                row.check:Show()

                local state = source[id]
                local checked = state and state ~= 0 and true or false
                row.check:SetChecked(checked)
                row.check:SetAlpha(queued and 0.5 or 1)

                if checked and not IsHeader(id) then row.bar:Show() end
            end

            row:Show()
        else
            row.id = nil
            row:Hide()
        end
    end

    if #entries > ROWS then
        f.track:Show()
        f.thumb:Show()

        local trackHeight = ROWS * ROW_H
        local height = math.max(24, trackHeight * ROWS / #entries)
        local travel = maxOffset > 0 and (trackHeight - height) * (self.offset / maxOffset) or 0

        f.thumb:SetHeight(height)
        f.thumb:ClearAllPoints()
        f.thumb:SetPoint("TOP", f.track, "TOP", 0, -travel)
    else
        f.track:Hide()
        f.thumb:Hide()
    end
end

function Panel:UpdateRandom(dungeonID)
    local f = self.frame
    local S = NS.Styling

    local name, _, minLevel, maxLevel, _, _, _, _, _, _, difficulty, maxPlayers,
        description, isHoliday = GetLFGDungeonInfo(dungeonID)

    f.randomTitle:SetText(name or (LFG_TYPE_RANDOM_DUNGEON or ""))

    local meta = {}
    if minLevel and maxLevel then
        meta[#meta + 1] = string.format(L["уровни %d-%d"], minLevel, maxLevel)
    end
    if maxPlayers and maxPlayers > 0 then
        meta[#meta + 1] = string.format(L["игроков: %d"], maxPlayers)
    end
    if difficulty and difficulty > 0 then
        meta[#meta + 1] = L["героический режим"]
    end
    f.randomMeta:SetText(table.concat(meta, "  |  "))

    f.randomText:SetText(isHoliday and (description or "")
        or (LFD_RANDOM_EXPLANATION or description or ""))

    local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards =
        GetLFGDungeonRewards(dungeonID)

    local randoms = 4 - GetNumPartyMembers()
    local money = (moneyBase or 0) + (moneyVar or 0) * randoms
    local experience = (experienceBase or 0) + (experienceVar or 0) * randoms

    local slot = 1
    for index = 1, (numRewards or 0) do
        if slot > #f.rewards then break end

        local rewardName, texture, numItems = GetLFGDungeonRewardInfo(dungeonID, index)
        local quality = GetLFGDungeonRewardItemQuality and GetLFGDungeonRewardItemQuality(dungeonID, index)
        local button = f.rewards[slot]

        button.icon:SetTexture(texture)
        button.itemName = rewardName
        button.link = GetLFGDungeonRewardLink and GetLFGDungeonRewardLink(dungeonID, index) or nil
        button.count:SetText((numItems or 1) > 1 and numItems or "")
        button.border:SetBackdropBorderColor(QualityColor(quality))
        button:Show()
        slot = slot + 1
    end

    for index = slot, #f.rewards do f.rewards[index]:Hide() end

    local lines = {}
    lines[#lines + 1] = doneToday and (LFD_RANDOM_REWARD_EXPLANATION2 or "")
        or (LFD_RANDOM_REWARD_EXPLANATION1 or "")
    if money > 0 then
        lines[#lines + 1] = string.format("%s: %s", MONEY or L["Деньги"], GetMoneyString(money))
    end
    if experience > 0 then
        lines[#lines + 1] = string.format("%s: %d", XP or L["Опыт"], experience)
    end
    f.rewardText:SetText(table.concat(lines, string.char(10)))

    local groupID = self:RandomGroupID(dungeonID)
    local pool = groupID and LFGGetDungeonListByHeaderID and LFGGetDungeonListByHeaderID(groupID)

    f.poolCaption:SetShown(pool and #pool > 0 or false)
    f.poolRule:SetShown(pool and #pool > 0 or false)

    for index = 1, #f.pool do
        local text = f.pool[index]
        local id = pool and pool[index]

        if id then
            local info = DungeonInfo(id)
            local poolName = info and info[Field("name")] or ("#" .. id)

            text:SetText(poolName)

            if LFGLockList and LFGLockList[id] then
                text:SetTextColor(0.5, 0.5, 0.52)
            else
                text:SetTextColor(DifficultyColor(info and info[Field("recLevel")] or 0))
            end

            text:Show()
        else
            text:Hide()
        end
    end
end

function Panel:UpdateLock()
    local f = self.frame
    local lock = f and f.lock
    if not lock then return false end

    local deserter = GetLFGDeserterExpiration and GetLFGDeserterExpiration()
    local random = self:QueueType() ~= "specific"
    local expires = deserter
    if not expires and random and GetLFGRandomCooldownExpiration then expires = GetLFGRandomCooldownExpiration() end
    if expires and GetTime() >= expires then expires = nil end

    local hasDeserter = deserter and expires and true or false
    local blocked = expires and true or false
    local members = GetNumPartyMembers() or 0

    for index = 1, 4 do
        local name, state = lock.names[index], lock.states[index]
        local unit = "party" .. index
        if index <= members and UnitExists(unit) then
            local _, class = UnitClass(unit)
            local c = class and RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR
            name:SetText(UnitName(unit) or "")
            name:SetTextColor(c.r, c.g, c.b)
            if UnitHasLFGDeserter and UnitHasLFGDeserter(unit) then
                state:SetText(DESERTER or L["Дезертир"])
                state:SetTextColor(1, 0.3, 0.3)
                blocked, hasDeserter = true, true
            elseif random and UnitHasLFGRandomCooldown and UnitHasLFGRandomCooldown(unit) then
                state:SetText(ON_COOLDOWN or L["Восстановление"])
                state:SetTextColor(1, 0.3, 0.3)
                blocked = true
            else
                state:SetText(READY or L["Готово"])
                state:SetTextColor(0.35, 1, 0.45)
            end
            name:Show()
            state:Show()
        else
            name:Hide()
            state:Hide()
        end
    end

    if not blocked then
        lock.expires = nil
        lock:Hide()
        return false
    end

    lock.icon:ClearAllPoints()
    if members > 0 then
        lock.icon:SetPoint("TOP", lock, "TOP", 0, -50 - members * 20)
    else
        lock.icon:SetPoint("TOP", lock, "TOP", 0, -70)
    end
    lock.text:ClearAllPoints()
    lock.text:SetPoint("TOP", lock.icon, "BOTTOM", 0, -14)

    if expires then
        lock.text:SetText(hasDeserter and deserter and LFG_DESERTER_YOU or LFG_RANDOM_COOLDOWN_YOU or "")
        lock.time:SetText(SecondsToTime(math.ceil(expires - GetTime())))
        lock.time:Show()
    else
        lock.text:SetText(hasDeserter and LFG_DESERTER_OTHER or LFG_RANDOM_COOLDOWN_OTHER or "")
        lock.time:Hide()
    end
    lock.icon:SetDesaturated(not hasDeserter)
    lock.expires = expires
    lock:Show()
    return true
end

function Panel:UpdateStatus()
    local f = self.frame
    local mode = self:Mode()

    if mode == "queued" or mode == "listed" or mode == "rolecheck" then
        f.join:SetText(LEAVE_QUEUE or L["Покинуть очередь"])
    elseif GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then
        f.join:SetText(JOIN_AS_PARTY or L["Встать в очередь группой"])
    else
        f.join:SetText(FIND_A_GROUP or L["Найти группу"])
    end

    local empowered = not LFD_IsEmpowered or LFD_IsEmpowered()
    local locked = self:UpdateLock()
    local usable = empowered and mode ~= "proposal"
    if locked and mode ~= "queued" and mode ~= "listed" and mode ~= "rolecheck" then usable = false end

    f.join:EnableMouse(usable)
    f.join:SetAlpha(usable and 1 or 0.4)

    if mode ~= "queued" then
        f.status:SetText(empowered and "" or L["очередью управляет лидер группы"])
        return
    end

    local hasData, _, tankNeeds, healerNeeds, dpsNeeds, _, instanceName,
        _, _, _, _, myWait, queuedTime = GetLFGQueueStats()

    local parts = {}

    if instanceName and instanceName ~= "" then
        parts[#parts + 1] = instanceName
    end

    if hasData and queuedTime then
        local elapsed = GetTime() - queuedTime
        parts[#parts + 1] = string.format(TIME_IN_QUEUE or "%s",
            elapsed >= 60 and SecondsToTime(elapsed) or (LESS_THAN_ONE_MINUTE or "< 1"))
    end

    if hasData then
        parts[#parts + 1] = string.format(L["ждем: танков %d, лекарей %d, бойцов %d"],
            tankNeeds or 0, healerNeeds or 0, dpsNeeds or 0)
    end

    if hasData and myWait and myWait > 0 then
        parts[#parts + 1] = string.format(LFG_STATISTIC_AVERAGE_WAIT or "%s",
            SecondsToTime(myWait, false, false, 1))
    end

    f.status:SetText(table.concat(parts, "  |  "))
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end
    local S = NS.Styling

    self.tab = self.tab or "lfg"

    for index, tab in ipairs(TABS) do
        local button = f.tabs[index]
        if tab.key == self.tab then
            button:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            button.bar:Show()
            button.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        else
            button:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            button.bar:Hide()
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end

    if self.tab ~= "lfg" then
        for _, button in pairs(f.categories) do button:Hide() end
        for _, button in pairs(f.roles) do button:Hide() end
        for _, row in ipairs(f.rows) do row:Hide() end

        f.typeCaption:Hide()
        f.typeDrop:Hide()
        f.join:Hide()
        f.status:Hide()
        f.list:Hide()
        f.rolesCaption:Hide()
        f.rolesRule:Hide()
        f.divider:Hide()
        f.placeholder:Hide()

        local page = self:PageFor(self.tab)
        if page then
            page:Attach(self)
            self:SyncPages()
            page:Update()
        else
            self:SyncPages()
            f.placeholder:Show()
            f.placeholder:SetText(L["этот раздел ещё не перенесен в наш интерфейс"])
        end

        f.subtitle:SetText(TabLabel(self.tab))
        return
    end

    for _, button in pairs(f.categories) do button:Show() end

    local premadeEnabled = C_LFGList and C_LFGList.IsPremadeGroupFinderEnabled
        and C_LFGList.IsPremadeGroupFinderEnabled()
    local miniGames = C_MiniGames and C_MiniGames.GetNumGames and C_MiniGames.GetNumGames() or 0

    local available = {
        dungeons = UnitLevel("player") >= (SHOW_LFD_LEVEL or 15),
        minigames = miniGames > 0,
        premade = premadeEnabled and true or false,
    }

    if not available[self.category] then self.category = "dungeons" end

    local dungeons = self.category == "dungeons"

    if dungeons then
        self:EnsureLists()
    end

    local notes = {
        dungeons = string.format(L["доступно: %d"], self:DungeonCount()),
        minigames = miniGames > 0 and string.format(L["доступно: %d"], miniGames) or L["недоступно"],
        premade = premadeEnabled and L["поиск и создание групп"] or L["недоступно"],
    }

    for key, button in pairs(f.categories) do
        local active = key == self.category

        button.active = active
        button.icon:SetDesaturated(not available[key])
        button.note:SetText(notes[key] or "")

        if active then
            button:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            button.glow:Show()
            button.bar:Show()
            button.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        else
            button:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            button.glow:Hide()
            button.bar:Hide()
            button.label:SetTextColor(
                available[key] and S.TEXT_NORMAL[1] or 0.4,
                available[key] and S.TEXT_NORMAL[2] or 0.4,
                available[key] and S.TEXT_NORMAL[3] or 0.42)
        end
    end

    for _, button in pairs(f.roles) do
        button:SetShown(dungeons)
    end

    f.divider:Show()
    f.rolesCaption:SetShown(dungeons)
    f.rolesRule:SetShown(dungeons)
    f.typeCaption:SetShown(dungeons)
    f.typeDrop:SetShown(dungeons)
    f.join:SetShown(dungeons)
    f.status:SetShown(dungeons)
    f.list:SetShown(dungeons)

    if not dungeons then
        local page = self:PageFor(self.category)

        if page then
            page:Attach(self)
            self:SyncPages()
            page:Update()
            f.placeholder:Hide()
        else
            self:SyncPages()
            f.placeholder:Show()
            f.placeholder:SetText(L["этот раздел ещё не перенесен в наш интерфейс"])
        end

        f.subtitle:SetText(CategoryLabel(self.category))
        return
    end

    self:SyncPages()
    f.placeholder:Hide()
    self:UpdateRoles()

    f.typeDrop:SetEntries(self:TypeEntries())
    f.typeDrop:SetValue(self:QueueType())

    local queueType = self:QueueType()
    local specific = queueType == "specific"

    for _, row in ipairs(f.rows) do row:SetShown(specific) end

    f.randomTitle:SetShown(not specific)
    f.randomMeta:SetShown(not specific)
    f.randomText:SetShown(not specific)
    f.rewardCaption:SetShown(not specific)
    f.rewardRule:SetShown(not specific)
    f.rewardText:SetShown(not specific)

    if specific then
        for _, button in pairs(f.rewards) do button:Hide() end
        for _, text in ipairs(f.pool) do text:Hide() end
        f.poolCaption:Hide()
        f.poolRule:Hide()
        self:UpdateList()
    else
        f.track:Hide()
        f.thumb:Hide()
        self:UpdateRandom(queueType)
    end

    f.subtitle:SetText(string.format(L["ваш уровень %d, доступных подземелий %d"],
        UnitLevel("player"), self:DungeonCount()))

    self:UpdateStatus()
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self:Update()
    self.frame:Show()
end

function Panel:Hide()
    if self.frame then self.frame:Hide() end
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.GroupFinderPanel = Panel
