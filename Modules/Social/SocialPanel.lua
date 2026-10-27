local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local CLASS_ICONS = "Interface\\WorldStateFrame\\Icons-Classes"
local TEXTURE_ONLINE = "Interface\\FriendsFrame\\StatusIcon-Online"
local TEXTURE_AFK = "Interface\\FriendsFrame\\StatusIcon-Away"
local TEXTURE_DND = "Interface\\FriendsFrame\\StatusIcon-DnD"
local TEXTURE_OFFLINE = "Interface\\FriendsFrame\\StatusIcon-Offline"
local LEADER_ICON = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
local ASSIST_ICON = "Interface\\GroupFrame\\UI-Group-AssistantIcon"

local PANEL_W = 420
local PANEL_H = 540
local PAD = 14
local BODY_TOP = 122
local BODY_BOTTOM = 16
local BODY_H = PANEL_H - BODY_TOP - BODY_BOTTOM
local BODY_W = PANEL_W - PAD * 2
local SCROLL_W = 6
local STRIP_H = 28
local SUBHEADER_H = 24
local LIST_H = BODY_H - 12 - STRIP_H - SUBHEADER_H
local LIST_W = BODY_W - 16 - SCROLL_W - 4

local FRIEND_ROW_H = 30
local FRIEND_ROWS = math.max(1, math.floor(LIST_H / FRIEND_ROW_H))
local WHO_ROW_H = 20
local WHO_ROWS = math.max(1, math.floor((LIST_H - 16) / WHO_ROW_H))
local CHANNEL_ROW_H = 18
local CHANNEL_ROWS = math.max(1, math.floor((LIST_H / 2 - 18) / CHANNEL_ROW_H))
local RAID_ROW_H = 18
local RAID_ROWS = math.max(1, math.floor(LIST_H / RAID_ROW_H))

NS.Densify("NarcissusSirus_Social", function(f)
    local function Size(base) return math.max(12, math.floor(base * f + 0.5)) end
    FRIEND_ROW_H = Size(30)
    FRIEND_ROWS = math.max(1, math.floor(LIST_H / FRIEND_ROW_H))
    WHO_ROW_H = Size(20)
    WHO_ROWS = math.max(1, math.floor((LIST_H - 16) / WHO_ROW_H))
    CHANNEL_ROW_H = Size(18)
    CHANNEL_ROWS = math.max(1, math.floor((LIST_H / 2 - 18) / CHANNEL_ROW_H))
    RAID_ROW_H = Size(18)
    RAID_ROWS = math.max(1, math.floor(LIST_H / RAID_ROW_H))
end)

local TAB_FRIENDS = 1
local TAB_WHO = 2
local TAB_CHANNELS = 3
local TAB_RAID = 4

local STATUS_ONLINE = 1
local STATUS_AFK = 2
local STATUS_DND = 3
local STATUS_INVISIBLE = 4

local WHO_COLUMNS = {
    { key = "zone", label = "ZONE", fallback = "Зона" },
    { key = "guild", label = "GUILD", fallback = "Гильдия" },
    { key = "race", label = "RACE", fallback = "Раса" },
    { key = "category", label = "CATEGORY", fallback = "Категория" },
    { key = "mythicRating", label = "MYTHIC_RATING", fallback = "Рейтинг" },
}

local WHO_X_NAME = 6
local WHO_X_LEVEL = 118
local WHO_X_ILVL = 146
local WHO_X_CLASS = 182
local WHO_X_VARIABLE = 258

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
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

    return frame
end

local function ScrollBar(parent, onScroll)
    local S = NS.Styling

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(SCROLL_W)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetTexture(WHITE)
    track:SetVertexColor(0, 0, 0, 0.4)

    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetWidth(SCROLL_W)
    thumb:SetHeight(40)
    thumb:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)

    local fill = thumb:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetTexture(WHITE)
    fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    thumb:SetScript("OnMouseDown", function(self)
        local _, y = GetCursorPosition()
        self.grabY = y
        self.grabOffset = bar.offset or 0
        self.dragging = true
    end)
    thumb:SetScript("OnMouseUp", function(self) self.dragging = nil end)
    thumb:SetScript("OnUpdate", function(self)
        if not self.dragging then return end

        local range = (bar.total or 0) - (bar.visible or 0)
        local span = bar:GetHeight() - self:GetHeight()
        if range <= 0 or span <= 0 then return end

        local _, y = GetCursorPosition()
        local moved = (self.grabY - y) / (bar:GetEffectiveScale() or 1)
        local value = math.max(0, math.min(range,
            math.floor(self.grabOffset + moved / span * range + 0.5)))

        if value ~= bar.offset then onScroll(value) end
    end)

    bar.thumb = thumb

    function bar:SetState(total, visible, offset)
        self.total, self.visible, self.offset = total, visible, offset

        local range = total - visible
        if range <= 0 then
            self:Hide()
            return
        end

        self:Show()

        local height = self:GetHeight()
        local size = math.max(20, height * visible / total)
        self.thumb:SetHeight(size)
        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(height - size) * (offset / range))
    end

    bar:Hide()
    return bar
end

local classLookup

local function ClassFileFromName(className)
    if not className then return end

    if not classLookup then
        classLookup = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do classLookup[name] = token end
        for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do classLookup[name] = token end
    end

    return classLookup[className]
end

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.85, 0.88
end

function Panel:Friends()
    local list = {}

    for index = 1, (GetNumFriends() or 0) do
        local name, level, class, area, connected, status, note = GetFriendInfo(index)
        if not name then break end

        list[#list + 1] = {
            index = index,
            name = name,
            level = level,
            class = class,
            area = area,
            connected = connected,
            status = status,
            note = note,
        }
    end

    table.sort(list, function(a, b)
        if (a.connected and true or false) ~= (b.connected and true or false) then
            return a.connected and true or false
        end
        return (a.name or "") < (b.name or "")
    end)

    return list
end

function Panel:Ignores()
    local list = {}

    for index = 1, (GetNumIgnores() or 0) do
        local name = GetIgnoreName(index)
        if not name or name == UNKNOWN then break end
        list[#list + 1] = { index = index, name = name }
    end

    return list
end

function Panel:WhoResults()
    local list = {}
    if not GetNumWhoResults then return list, 0 end

    local numWhos, totalCount = GetNumWhoResults()

    for index = 1, (numWhos or 0) do
        local name, guild, level, race, class, zone, classFile, itemLevel, mythicRating, category =
            GetWhoInfo(index)
        if not name then break end

        list[#list + 1] = {
            index = index,
            name = name,
            guild = guild,
            level = level,
            race = race,
            class = class,
            zone = zone,
            classFile = classFile,
            itemLevel = itemLevel,
            mythicRating = mythicRating,
            category = category,
        }
    end

    return list, totalCount or #list
end

function Panel:Channels()
    local list = {}
    if not GetNumDisplayChannels then return list end

    for index = 1, (GetNumDisplayChannels() or 0) do
        local name, header, collapsed, channelNumber, count, active, category = GetChannelDisplayInfo(index)
        if not name then break end

        list[#list + 1] = {
            index = index,
            name = name,
            header = header,
            collapsed = collapsed,
            number = channelNumber,
            count = count,
            active = active,
            category = category,
        }
    end

    return list
end

function Panel:ChannelRoster()
    local list = {}
    local id = self.selectedChannel
    if not id or not GetChannelRosterInfo then return list end

    local _, header, _, _, count = GetChannelDisplayInfo(id)
    if header or not count then return list end

    for index = 1, count do
        local name, owner, moderator, muted = GetChannelRosterInfo(id, index)
        if not name then break end
        list[#list + 1] = { name = name, owner = owner, moderator = moderator, muted = muted }
    end

    return list
end

function Panel:RaidRows()
    local rows = {}
    local roster = {}

    for index = 1, (GetNumRaidMembers() or 0) do
        local name, rank, subgroup, level, class, classFile, zone, online, isDead = GetRaidRosterInfo(index)
        if name then
            roster[subgroup or 1] = roster[subgroup or 1] or {}
            table.insert(roster[subgroup or 1], {
                name = name,
                rank = rank,
                level = level,
                classFile = classFile,
                online = online,
                isDead = isDead,
            })
        end
    end

    for group = 1, 8 do
        local members = roster[group]
        if members then
            rows[#rows + 1] = { header = true, text = string.format(Global("GROUP_NUMBER", "%d-я группа"), group) }
            for _, member in ipairs(members) do
                rows[#rows + 1] = member
            end
        end
    end

    return rows
end

function Panel:SavedInstances()
    local list = {}

    for index = 1, (GetNumSavedInstances() or 0) do
        local name, id, reset, difficulty, locked, extended, mostSig, isRaid, maxPlayers, difficultyName =
            GetSavedInstanceInfo(index)
        if not name then break end

        list[#list + 1] = {
            index = index,
            name = name,
            id = id,
            reset = reset,
            locked = locked,
            extended = extended,
            isRaid = isRaid,
            maxPlayers = maxPlayers,
            difficultyName = difficultyName,
        }
    end

    return list
end

function Panel:SelectedFriend()
    local list = self.ignoreView and self:Ignores() or self:Friends()

    for _, entry in ipairs(list) do
        if entry.name == self.selectedName then return entry end
    end
end

function Panel:Status()
    if C_FriendList and C_FriendList.IsInvisible and C_FriendList.IsInvisible() then return STATUS_INVISIBLE end
    if UnitIsAFK("player") then return STATUS_AFK end
    if UnitIsDND("player") then return STATUS_DND end
    return STATUS_ONLINE
end

function Panel:SetStatus(status)
    if status == self:Status() then return end

    local invisible = C_FriendList and C_FriendList.IsInvisible and C_FriendList.IsInvisible()

    if status == STATUS_ONLINE then
        if UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        elseif UnitIsDND("player") then
            SendChatMessage("", "DND")
        elseif invisible then
            C_FriendList.ToggleInvisible()
        end
    elseif status == STATUS_AFK then
        if invisible then C_FriendList.ToggleInvisible() end
        SendChatMessage("", "AFK")
    elseif status == STATUS_DND then
        if invisible then C_FriendList.ToggleInvisible() end
        SendChatMessage("", "DND")
    elseif status == STATUS_INVISIBLE then
        if UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        elseif UnitIsDND("player") then
            SendChatMessage("", "DND")
        end
        if C_FriendList and C_FriendList.ToggleInvisible then C_FriendList.ToggleInvisible() end
    end

    self:Update()
end

function Panel:ShowFriendMenu(row, entry)
    if not entry then return end

    self.menuFrame = self.menuFrame
        or CreateFrame("Frame", "NarciSirus_SocialMenu", UIParent, "UIDropDownMenuTemplate")

    local menu = {}

    if self.ignoreView then
        menu[#menu + 1] = { text = entry.name, isTitle = true, notCheckable = true }
        menu[#menu + 1] = {
            text = Global("REMOVE", "Исключить"),
            notCheckable = true,
            func = function()
                DelIgnore(entry.name)
                Panel.selectedName = nil
                Panel:Update()
            end,
        }
    else
        menu[#menu + 1] = { text = entry.name, isTitle = true, notCheckable = true }
        menu[#menu + 1] = {
            text = Global("WHISPER", "Шепнуть"),
            notCheckable = true,
            disabled = not entry.connected,
            func = function() ChatFrame_SendTell(entry.name) end,
        }
        menu[#menu + 1] = {
            text = Global("GROUP_INVITE", "Пригласить"),
            notCheckable = true,
            disabled = not entry.connected,
            func = function() InviteUnit(entry.name) end,
        }
        menu[#menu + 1] = {
            text = L["Заметка"],
            notCheckable = true,
            func = function()
                FriendsFrame.NotesID = entry.index
                StaticPopup_Show("SET_FRIENDNOTE", entry.name)
            end,
        }
        menu[#menu + 1] = {
            text = Global("REMOVE", "Исключить"),
            notCheckable = true,
            func = function()
                RemoveFriend(entry.name)
                Panel.selectedName = nil
                Panel:Update()
            end,
        }
    end

    EasyMenu(menu, self.menuFrame, "cursor", 0, 0, "MENU", 2)
end

function Panel:CreateListRow(parent, index, height)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(height)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.26 or 0.08)

    local selected = row:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetTexture(WHITE)
    selected:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    selected:Hide()
    row.selected = selected

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    row:Hide()
    return row
end

function Panel:CreateFriendRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, FRIEND_ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local status = row:CreateTexture(nil, "ARTWORK")
    status:SetSize(14, 14)
    status:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.status = status

    local class = row:CreateTexture(nil, "ARTWORK")
    class:SetSize(16, 16)
    class:SetPoint("LEFT", status, "RIGHT", 5, 0)
    class:SetTexture(CLASS_ICONS)
    row.class = class

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("TOPLEFT", class, "TOPRIGHT", 6, 1)
    name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local info = row:CreateFontString(nil, "OVERLAY")
    info:SetFont(NS.FONT, NS.FS(10), "")
    info:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    info:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    info:SetJustifyH("LEFT")
    row.info = info

    row:SetScript("OnClick", function(self, button)
        Panel.selectedName = self.friendName
        Panel:Update()

        if button == "RightButton" then
            Panel:ShowFriendMenu(self, Panel:SelectedFriend())
        end
    end)

    row:SetScript("OnDoubleClick", function(self)
        if self.friendName and not Panel.ignoreView then ChatFrame_SendTell(self.friendName) end
    end)

    return row
end

function Panel:CreateWhoRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, WHO_ROW_H)

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("LEFT", row, "LEFT", WHO_X_NAME, 0)
    name:SetWidth(WHO_X_LEVEL - WHO_X_NAME - 4)
    name:SetJustifyH("LEFT")
    row.name = name

    local level = row:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(11), "")
    level:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    level:SetPoint("LEFT", row, "LEFT", WHO_X_LEVEL, 0)
    level:SetWidth(WHO_X_ILVL - WHO_X_LEVEL - 4)
    level:SetJustifyH("LEFT")
    row.level = level

    local itemLevel = row:CreateFontString(nil, "OVERLAY")
    itemLevel:SetFont(NS.FONT, NS.FS(11), "")
    itemLevel:SetPoint("LEFT", row, "LEFT", WHO_X_ILVL, 0)
    itemLevel:SetWidth(WHO_X_CLASS - WHO_X_ILVL - 4)
    itemLevel:SetJustifyH("LEFT")
    row.itemLevel = itemLevel

    local class = row:CreateFontString(nil, "OVERLAY")
    class:SetFont(NS.FONT, NS.FS(11), "")
    class:SetPoint("LEFT", row, "LEFT", WHO_X_CLASS, 0)
    class:SetWidth(WHO_X_VARIABLE - WHO_X_CLASS - 4)
    class:SetJustifyH("LEFT")
    row.class = class

    local variable = row:CreateFontString(nil, "OVERLAY")
    variable:SetFont(NS.FONT, NS.FS(11), "")
    variable:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    variable:SetPoint("LEFT", row, "LEFT", WHO_X_VARIABLE, 0)
    variable:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    variable:SetJustifyH("LEFT")
    row.variable = variable

    row:SetScript("OnClick", function(self)
        Panel.selectedWho = self.whoName
        Panel:Update()
    end)

    row:SetScript("OnDoubleClick", function(self)
        if self.whoName then ChatFrame_SendTell(self.whoName) end
    end)

    return row
end

function Panel:CreateChannelRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, CHANNEL_ROW_H)

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("LEFT", row, "LEFT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -34, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local count = row:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(10), "")
    count:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.count = count

    row:SetScript("OnClick", function(self)
        if not self.channelID or self.isHeader then return end
        Panel.selectedChannel = self.channelID
        if SetSelectedDisplayChannel then SetSelectedDisplayChannel(self.channelID) end
        if GetNumChannelMembers then GetNumChannelMembers(self.channelID) end
        Panel.rosterOffset = 0
        Panel:Update()
    end)

    return row
end

function Panel:CreateMemberRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, CHANNEL_ROW_H)

    local rank = row:CreateTexture(nil, "ARTWORK")
    rank:SetSize(12, 12)
    rank:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.rank = rank

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    name:SetPoint("LEFT", rank, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    row:SetScript("OnDoubleClick", function(self)
        if self.memberName then ChatFrame_SendTell(self.memberName) end
    end)

    return row
end

function Panel:CreateRaidRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, RAID_ROW_H)

    local rank = row:CreateTexture(nil, "ARTWORK")
    rank:SetSize(12, 12)
    rank:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.rank = rank

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("LEFT", rank, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local level = row:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(11), "")
    level:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    level:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.level = level

    return row
end

function Panel:CreateInstanceRow(parent, index)
    local S = NS.Styling

    local row = self:CreateListRow(parent, index, 26)

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(11), "")
    name:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -2)
    name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local reset = row:CreateFontString(nil, "OVERLAY")
    reset:SetFont(NS.FONT, NS.FS(10), "")
    reset:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    reset:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    reset:SetJustifyH("LEFT")
    row.reset = reset

    row:SetScript("OnClick", function(self)
        Panel.selectedInstance = self.instanceIndex
        Panel:Update()
    end)

    return row
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_Social", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
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
    title:SetFont(NS.FONT, NS.FS(16), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -12)
    title:SetText(Global("SOCIAL_BUTTON", "Общение"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(10), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -4)
    f.subtitle = subtitle

    local close = NS.Widgets.CreateCloseButton(f, 16, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local statusDrop = NS.Widgets.CreateThemedDropdown(f, 150, function(value)
        Panel:SetStatus(value)
    end)
    statusDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -34)
    f.statusDrop = statusDrop

    local whoBox = NS.Widgets.CreateThemedEditBox(f, 170, 20, 64)
    whoBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 76, -34)
    whoBox:SetScript("OnEnterPressed", function(box) SendWho(box:GetText() or "") end)
    whoBox:Hide()
    f.whoBox = whoBox

    local whoButton = NS.Widgets.CreateThemedButton(f, Global("WHO", "Кто"), 70, 20, function()
        SendWho(whoBox:GetText() or "")
    end)
    whoButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -34)
    whoButton:Hide()
    f.whoButton = whoButton

    S.CreateAnimatedSeparator(f, -62)

    f.tabs = {}
    local topTabs = {
        { key = TAB_FRIENDS, label = Global("FRIENDS", "Друзья") },
        { key = TAB_WHO, label = Global("WHO", "Кто") },
        { key = TAB_CHANNELS, label = Global("CHANNELS", "Каналы") },
        { key = TAB_RAID, label = Global("RAID", "Рейд") },
    }

    local tabWidth = math.floor((BODY_W - 12) / 4)

    for index, tab in ipairs(topTabs) do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(tabWidth, 22)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        button.label = label

        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetHeight(2)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 3, 3)
        bar:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()
        button.bar = bar

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

        button:SetScript("OnClick", function()
            Panel.tab = tab.key
            Panel.offset = 0
            Panel:Refresh()
            Panel:Update()
        end)

        button:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + (index - 1) * (tabWidth + 4), -78)

        button.tabKey = tab.key
        f.tabs[index] = button
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(body)
    f.body = body

    local friendsTab = NS.Widgets.CreateThemedButton(body, Global("FRIENDS", "Друзья"),
        math.floor((BODY_W - 22) / 2), 18, function()
            Panel.ignoreView = nil
            Panel.offset = 0
            Panel.selectedName = nil
            Panel:Update()
        end)
    friendsTab:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -6)
    friendsTab:Hide()
    f.friendsTab = friendsTab

    local ignoreTab = NS.Widgets.CreateThemedButton(body, Global("IGNORE_LIST", "Черный список"),
        math.floor((BODY_W - 22) / 2), 18, function()
            Panel.ignoreView = true
            Panel.offset = 0
            Panel.selectedName = nil
            Panel:Update()
        end)
    ignoreTab:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -6)
    ignoreTab:Hide()
    f.ignoreTab = ignoreTab

    local whoColumn = NS.Widgets.CreateThemedDropdown(f, 150, function(value)
        Panel.whoColumn = value
        Panel:Update()
    end)
    whoColumn:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -6)
    whoColumn:SetHeight(18)
    whoColumn:Hide()
    f.whoColumn = whoColumn

    local whoHeader = body:CreateFontString(nil, "OVERLAY")
    whoHeader:SetFont(NS.FONT, NS.FS(10), "")
    whoHeader:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    whoHeader:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -10)
    whoHeader:SetText(Global("NAME", "Имя"))
    whoHeader:Hide()
    f.whoHeader = whoHeader

    local caption = body:CreateFontString(nil, "OVERLAY")
    caption:SetFont(NS.FONT, NS.FS(10), "")
    caption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    caption:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
    caption:Hide()
    f.caption = caption

    local caption2 = body:CreateFontString(nil, "OVERLAY")
    caption2:SetFont(NS.FONT, NS.FS(10), "")
    caption2:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    caption2:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -(SUBHEADER_H + CHANNEL_ROWS * CHANNEL_ROW_H + 14))
    caption2:Hide()
    f.caption2 = caption2

    local function ScrollList(value)
        Panel.offset = value
        Panel:Update()
    end

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local total, visible = Panel:ListSize()
        if total <= visible then return end
        ScrollList(math.max(0, math.min(total - visible, (Panel.offset or 0) - delta)))
    end)

    f.listScroll = ScrollBar(body, ScrollList)

    local listTop = SUBHEADER_H

    f.friendRows = {}
    for index = 1, FRIEND_ROWS do
        local row = self:CreateFriendRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -listTop - (index - 1) * FRIEND_ROW_H)
        row:SetWidth(LIST_W)
        f.friendRows[index] = row
    end

    f.whoRows = {}
    for index = 1, WHO_ROWS do
        local row = self:CreateWhoRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -listTop - 16 - (index - 1) * WHO_ROW_H)
        row:SetWidth(LIST_W)
        f.whoRows[index] = row
    end

    f.channelRows = {}
    for index = 1, CHANNEL_ROWS do
        local row = self:CreateChannelRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -listTop - (index - 1) * CHANNEL_ROW_H)
        row:SetWidth(LIST_W)
        f.channelRows[index] = row
    end

    f.memberRows = {}
    for index = 1, CHANNEL_ROWS do
        local row = self:CreateMemberRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8,
            -(SUBHEADER_H + CHANNEL_ROWS * CHANNEL_ROW_H + 30) - (index - 1) * CHANNEL_ROW_H)
        row:SetWidth(LIST_W)
        f.memberRows[index] = row
    end

    f.raidRows = {}
    for index = 1, RAID_ROWS do
        local row = self:CreateRaidRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -listTop - (index - 1) * RAID_ROW_H)
        row:SetWidth(LIST_W)
        f.raidRows[index] = row
    end

    f.instanceRows = {}
    for index = 1, 6 do
        local row = self:CreateInstanceRow(body, index)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -listTop - 20 - (index - 1) * 26)
        row:SetWidth(LIST_W)
        f.instanceRows[index] = row
    end

    local raidText = body:CreateFontString(nil, "OVERLAY")
    raidText:SetFont(NS.FONT, NS.FS(11), "")
    raidText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    raidText:SetPoint("TOPLEFT", body, "TOPLEFT", 10, -listTop)
    raidText:SetWidth(BODY_W - 24)
    raidText:SetJustifyH("LEFT")
    raidText:SetJustifyV("TOP")
    raidText:Hide()
    f.raidText = raidText

    local totals = body:CreateFontString(nil, "OVERLAY")
    totals:SetFont(NS.FONT, NS.FS(10), "")
    totals:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    totals:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 10, STRIP_H + 4)
    totals:Hide()
    f.totals = totals

    local strip = CreateFrame("Frame", nil, body)
    strip:SetHeight(STRIP_H)
    strip:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 6, 4)
    strip:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -6, 4)
    f.strip = strip

    f.buttons = {}

    local function AddButton(key, text, width, onClick)
        local button = NS.Widgets.CreateThemedButton(strip, text, width, 20, onClick)
        button:Hide()
        f.buttons[key] = button
        return button
    end

    AddButton("add", Global("ADD_FRIEND", "Добавить"), 120, function()
        if Panel.ignoreView then
            StaticPopup_Show("ADD_IGNORE")
        else
            StaticPopup_Show("ADD_FRIEND")
        end
    end)

    AddButton("whisper", Global("SEND_MESSAGE", "Сообщение"), 130, function()
        local entry = Panel:SelectedFriend()
        if entry then ChatFrame_SendTell(entry.name) end
    end)

    AddButton("whoAdd", Global("ADD_FRIEND", "Добавить"), 116, function()
        if Panel.selectedWho then AddFriend(Panel.selectedWho) end
    end)

    AddButton("whoInvite", Global("GROUP_INVITE", "Пригласить"), 116, function()
        if Panel.selectedWho then InviteUnit(Panel.selectedWho) end
    end)

    AddButton("whoWhisper", Global("SEND_MESSAGE", "Сообщение"), 124, function()
        if Panel.selectedWho then ChatFrame_SendTell(Panel.selectedWho) end
    end)

    AddButton("channelJoin", L["Новый канал"], 140, function()
        StaticPopup_Show("NARCI_JOIN_CHANNEL")
    end)

    AddButton("channelLeave", L["Покинуть"], 130, function()
        for _, channel in ipairs(Panel:Channels()) do
            if channel.index == Panel.selectedChannel and not channel.header then
                LeaveChannelByName(channel.name)
                Panel.selectedChannel = nil
                Panel:Update()
                return
            end
        end
    end)

    AddButton("convert", Global("CONVERT_TO_RAID", "Создать рейд"), 150, function()
        ConvertToRaid()
    end)

    AddButton("ready", Global("READY_CHECK", "Готовность"), 130, function()
        DoReadyCheck()
    end)

    AddButton("info", Global("RAID_INFO", "Сохранения"), 130, function()
        Panel.raidInfoView = not Panel.raidInfoView
        RequestRaidInfo()
        Panel:Update()
    end)

    AddButton("extend", Global("EXTEND_RAID_LOCK", "Продлить"), 150, function()
        local entry = Panel.selectedInstance and Panel:SavedInstances()[Panel.selectedInstance]
        if not entry or not SetSavedInstanceExtend then return end

        SetSavedInstanceExtend(entry.index, not entry.extended)
        RequestRaidInfo()
        Panel:Update()
    end)

    local assist = NS.Widgets.CreateThemedCheckbox(strip,
        Global("ALL_ASSIST_LABEL", "Все помощники"), false, function(value)
            if SetEveryoneIsAssistant then SetEveryoneIsAssistant(value and true or false) end
            Panel:Update()
        end)
    assist:Hide()
    f.assist = assist

    StaticPopupDialogs["NARCI_JOIN_CHANNEL"] = StaticPopupDialogs["NARCI_JOIN_CHANNEL"] or {
        text = L["Новый канал"],
        button1 = Global("ACCEPT", "Принять"),
        button2 = Global("CANCEL", "Отмена"),
        hasEditBox = 1,
        maxLetters = 31,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        OnAccept = function(self)
            local box = self.editBox or _G[self:GetName() .. "EditBox"]
            local name = box and box:GetText()
            if name and name ~= "" then JoinPermanentChannel(name, nil, DEFAULT_CHAT_FRAME:GetID(), 1) end
            if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
        end,
        EditBoxOnEnterPressed = function(self)
            local name = self:GetText()
            if name and name ~= "" then JoinPermanentChannel(name, nil, DEFAULT_CHAT_FRAME:GetID(), 1) end
            self:GetParent():Hide()
            if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    }

    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "FRIENDLIST_UPDATE",
        "IGNORELIST_UPDATE",
        "WHO_LIST_UPDATE",
        "CHANNEL_UI_UPDATE",
        "CHANNEL_COUNT_UPDATE",
        "CHANNEL_ROSTER_UPDATE",
        "RAID_ROSTER_UPDATE",
        "PARTY_MEMBERS_CHANGED",
        "PARTY_LEADER_CHANGED",
        "UPDATE_INSTANCE_INFO",
        "PLAYER_FLAGS_CHANGED",
    }) do
        pcall(events.RegisterEvent, events, event)
    end

    events:SetScript("OnEvent", function()
        if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_Social")

    self.frame = f
    self.tab = self.tab or TAB_FRIENDS
    self.whoColumn = self.whoColumn or 1
    self.offset = 0

    f:Hide()
end

function Panel:ListSize()
    if self.tab == TAB_FRIENDS then
        local list = self.ignoreView and self:Ignores() or self:Friends()
        return #list, FRIEND_ROWS
    elseif self.tab == TAB_WHO then
        local list = self:WhoResults()
        return #list, WHO_ROWS
    elseif self.tab == TAB_CHANNELS then
        return #self:Channels(), CHANNEL_ROWS
    elseif self.tab == TAB_RAID and not self.raidInfoView then
        return #self:RaidRows(), RAID_ROWS
    end

    return 0, 1
end

function Panel:Refresh()
    if self.tab == TAB_FRIENDS then
        ShowFriends()
    elseif self.tab == TAB_RAID then
        RequestRaidInfo()
    elseif self.tab == TAB_CHANNELS and self.selectedChannel and GetNumChannelMembers then
        GetNumChannelMembers(self.selectedChannel)
    end
end

function Panel:UpdateFriends()
    local S = NS.Styling
    local f = self.frame
    local ignore = self.ignoreView and true or false
    local list = ignore and self:Ignores() or self:Friends()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #list - FRIEND_ROWS)))
    self.offset = offset

    local online = 0
    for _, entry in ipairs(list) do
        if entry.connected then online = online + 1 end
    end

    f.subtitle:SetText(ignore and string.format("%s: %d", Global("IGNORE_LIST", "Черный список"), #list)
        or string.format("%s: %d/%d", Global("FRIENDS_LIST_ONLINE", "В сети"), online, #list))

    for index = 1, FRIEND_ROWS do
        local row = f.friendRows[index]
        local entry = list[index + offset]

        if entry then
            row.friendName = entry.name
            row.selected:SetShown(self.selectedName == entry.name)

            if ignore then
                row.status:SetTexture(TEXTURE_OFFLINE)
                row.class:Hide()
                row.name:SetText(entry.name)
                row.name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                row.info:SetText("")
            else
                if entry.connected then
                    if entry.status == CHAT_FLAG_AFK then
                        row.status:SetTexture(TEXTURE_AFK)
                    elseif entry.status == CHAT_FLAG_DND then
                        row.status:SetTexture(TEXTURE_DND)
                    else
                        row.status:SetTexture(TEXTURE_ONLINE)
                    end
                else
                    row.status:SetTexture(TEXTURE_OFFLINE)
                end

                local classFile = ClassFileFromName(entry.class)
                if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
                    row.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
                    row.class:SetDesaturated(not entry.connected)
                    row.class:Show()
                else
                    row.class:Hide()
                end

                if entry.connected and entry.level and entry.level > 0 and entry.class then
                    row.name:SetFormattedText("%s - %s", entry.name,
                        string.format(Global("FRIENDS_LEVEL_TEMPLATE", "%2$s %1$d-го уровня"),
                            entry.level, entry.class))
                else
                    row.name:SetText(entry.name)
                end

                if entry.connected then
                    row.name:SetTextColor(ClassColor(classFile))
                else
                    row.name:SetTextColor(0.5, 0.5, 0.55)
                end

                local info = entry.area
                if not info or info == "" or info == UNKNOWN then
                    info = entry.connected and "" or Global("FRIENDS_LIST_OFFLINE", "Не в сети")
                end

                if entry.note and entry.note ~= "" then
                    info = info ~= "" and string.format("%s - %s", info, entry.note) or entry.note
                end

                row.info:SetText(info)
            end

            row:Show()
        else
            row.friendName = nil
            row:Hide()
        end
    end

    f.listScroll:ClearAllPoints()
    f.listScroll:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", -4, -SUBHEADER_H)
    f.listScroll:SetHeight(FRIEND_ROWS * FRIEND_ROW_H)
    f.listScroll:SetState(#list, FRIEND_ROWS, offset)

    local entry = self:SelectedFriend()
    local canWhisper = entry and not ignore and entry.connected and true or false
    f.buttons.whisper:SetAlpha(canWhisper and 1 or 0.4)
    f.buttons.whisper:EnableMouse(canWhisper)
end

function Panel:UpdateWho()
    local S = NS.Styling
    local f = self.frame
    local list, total = self:WhoResults()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #list - WHO_ROWS)))
    self.offset = offset

    local column = WHO_COLUMNS[self.whoColumn or 1]

    f.subtitle:SetFormattedText(Global("WHO_FRAME_TOTAL_TEMPLATE", "Найдено игроков: %d"), total or 0)

    for index = 1, WHO_ROWS do
        local row = f.whoRows[index]
        local entry = list[index + offset]

        if entry then
            row.whoName = entry.name
            row.selected:SetShown(self.selectedWho == entry.name)

            row.name:SetText(entry.name)
            row.name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            row.level:SetText(entry.level or "")
            row.itemLevel:SetText(entry.itemLevel or "")
            row.itemLevel:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
            row.class:SetText(entry.class or "")
            row.class:SetTextColor(ClassColor(entry.classFile or ClassFileFromName(entry.class)))

            local value = entry[column.key]
            if column.key == "category" then
                local categoryName
                if value and value ~= 0 and C_CategorySpell and C_CategorySpell.GetCategoryInfo then
                    local ok, name = pcall(C_CategorySpell.GetCategoryInfo, value)
                    if ok then categoryName = name end
                end
                value = categoryName or ""
            end

            row.variable:SetText(value or "")
            row:Show()
        else
            row.whoName = nil
            row:Hide()
        end
    end

    f.listScroll:ClearAllPoints()
    f.listScroll:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", -4, -SUBHEADER_H - 16)
    f.listScroll:SetHeight(WHO_ROWS * WHO_ROW_H)
    f.listScroll:SetState(#list, WHO_ROWS, offset)

    local canAct = self.selectedWho and true or false
    for _, key in ipairs({ "whoAdd", "whoInvite", "whoWhisper" }) do
        local button = f.buttons[key]
        button:SetAlpha(canAct and 1 or 0.4)
        button:EnableMouse(canAct)
    end
end

function Panel:UpdateChannels()
    local S = NS.Styling
    local f = self.frame
    local channels = self:Channels()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #channels - CHANNEL_ROWS)))
    self.offset = offset

    f.subtitle:SetFormattedText("%s: %d", Global("CHANNELS", "Каналы"), #channels)

    for index = 1, CHANNEL_ROWS do
        local row = f.channelRows[index]
        local channel = channels[index + offset]

        if channel then
            row.channelID = channel.index
            row.isHeader = channel.header
            row.selected:SetShown(self.selectedChannel == channel.index)

            if channel.header then
                row.name:SetText(channel.name or "")
                row.name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                row.count:SetText("")
            else
                row.name:SetFormattedText("%s %s", channel.number or "", channel.name or "")
                if channel.active then
                    row.name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                else
                    row.name:SetTextColor(0.5, 0.5, 0.55)
                end
                row.count:SetText(channel.count and channel.count > 0 and channel.count or "")
            end

            row:Show()
        else
            row.channelID = nil
            row:Hide()
        end
    end

    local roster = self:ChannelRoster()
    local rosterOffset = math.max(0, math.min(self.rosterOffset or 0, math.max(0, #roster - CHANNEL_ROWS)))
    self.rosterOffset = rosterOffset

    for index = 1, CHANNEL_ROWS do
        local row = f.memberRows[index]
        local member = roster[index + rosterOffset]

        if member then
            row.memberName = member.name
            row.name:SetText(member.name)

            if member.owner then
                row.rank:SetTexture(LEADER_ICON)
                row.rank:Show()
            elseif member.moderator then
                row.rank:SetTexture(ASSIST_ICON)
                row.rank:Show()
            else
                row.rank:Hide()
            end

            row:Show()
        else
            row.memberName = nil
            row:Hide()
        end
    end

    f.caption2:SetFormattedText("%s: %d", L["В канале"], #roster)

    f.listScroll:ClearAllPoints()
    f.listScroll:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", -4, -SUBHEADER_H)
    f.listScroll:SetHeight(CHANNEL_ROWS * CHANNEL_ROW_H)
    f.listScroll:SetState(#channels, CHANNEL_ROWS, offset)

    local canLeave = self.selectedChannel and true or false
    f.buttons.channelLeave:SetAlpha(canLeave and 1 or 0.4)
    f.buttons.channelLeave:EnableMouse(canLeave)
end

function Panel:UpdateRaid()
    local S = NS.Styling
    local f = self.frame
    local rows = self:RaidRows()
    local inRaid = #rows > 0
    local instances = self:SavedInstances()

    f.subtitle:SetText(inRaid and string.format("%s: %d", Global("RAID", "Рейд"), GetNumRaidMembers() or 0)
        or Global("RAID", "Рейд"))

    if self.raidInfoView then
        f.raidText:Hide()
        for _, row in ipairs(f.raidRows) do row:Hide() end

        f.caption:SetText(string.upper(Global("RAID_INFO", "Сохранения")))
        f.caption:Show()

        for index = 1, 6 do
            local row = f.instanceRows[index]
            local entry = instances[index]

            if entry then
                row.instanceIndex = index
                row.selected:SetShown(self.selectedInstance == index)
                row.name:SetFormattedText("%s (%s)", entry.name, entry.difficultyName or entry.maxPlayers or "")

                if entry.locked or entry.extended then
                    row.reset:SetText(SecondsToTime and SecondsToTime(entry.reset or 0, true, nil, 3) or "")
                    row.name:SetTextColor(1, 0.82, 0)
                else
                    row.reset:SetText(Global("RAID_INSTANCE_EXPIRES_EXPIRED", "Истекло"))
                    row.name:SetTextColor(0.5, 0.5, 0.5)
                end

                row:Show()
            else
                row.instanceIndex = nil
                row:Hide()
            end
        end

        if #instances == 0 then
            f.raidText:SetText(L["нет сохранений"])
            f.raidText:Show()
        end
    else
        f.caption:Hide()
        for _, row in ipairs(f.instanceRows) do row:Hide() end

        local offset = math.max(0, math.min(self.offset or 0, math.max(0, #rows - RAID_ROWS)))
        self.offset = offset

        for index = 1, RAID_ROWS do
            local row = f.raidRows[index]
            local entry = rows[index + offset]

            if entry then
                if entry.header then
                    row.rank:Hide()
                    row.name:SetText(entry.text)
                    row.name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                    row.level:SetText("")
                else
                    row.name:SetText(entry.name)
                    row.name:SetTextColor(ClassColor(entry.classFile))
                    row.name:SetAlpha(entry.online and 1 or 0.5)
                    row.level:SetText(entry.level or "")

                    if entry.rank == 2 then
                        row.rank:SetTexture(LEADER_ICON)
                        row.rank:Show()
                    elseif entry.rank == 1 then
                        row.rank:SetTexture(ASSIST_ICON)
                        row.rank:Show()
                    else
                        row.rank:Hide()
                    end
                end

                row:Show()
            else
                row:Hide()
            end
        end

        f.raidText:SetShown(not inRaid)
        if not inRaid then
            f.raidText:SetText(Global("RAID_DESCRIPTION", "Рейд объединяет до 40 игроков."))
        end

        f.listScroll:ClearAllPoints()
        f.listScroll:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", -4, -SUBHEADER_H)
        f.listScroll:SetHeight(RAID_ROWS * RAID_ROW_H)
        f.listScroll:SetState(#rows, RAID_ROWS, offset)
    end

    local convert = f.buttons.convert
    local canConvert = not inRaid and GetPartyMember(1) and IsPartyLeader()
        and (UnitLevel("player") or 1) >= 10 and not (HasLFGRestrictions and HasLFGRestrictions())
    convert:SetShown(not inRaid and not self.raidInfoView)
    convert:SetAlpha(canConvert and 1 or 0.4)
    convert:EnableMouse(canConvert and true or false)

    local ready = f.buttons.ready
    local canReady = inRaid and (IsRaidLeader() or IsRaidOfficer())
    ready:SetShown(inRaid and not self.raidInfoView)
    ready:SetAlpha(canReady and 1 or 0.4)
    ready:EnableMouse(canReady and true or false)

    local extend = f.buttons.extend
    local entry = self.selectedInstance and instances[self.selectedInstance]
    extend:SetShown(self.raidInfoView and (not CanExtendSavedInstance or CanExtendSavedInstance()))
    extend:SetAlpha(entry and 1 or 0.4)
    extend:EnableMouse(entry and true or false)

    if entry then
        extend:SetText(entry.extended and Global("UNEXTEND_RAID_LOCK", "Отменить продление")
            or entry.locked and Global("EXTEND_RAID_LOCK", "Продлить")
            or Global("REACTIVATE_RAID_LOCK", "Восстановить"))
    end

    f.buttons.info:SetText(self.raidInfoView and L["к рейду"] or Global("RAID_INFO", "Сохранения"))

    f.assist:SetShown(inRaid and not self.raidInfoView)
    if inRaid and not self.raidInfoView then
        f.assist:SetChecked(IsEveryoneAssistant and IsEveryoneAssistant() or false)
        f.assist:SetAlpha(IsRaidLeader() and 1 or 0.4)
        f.assist:EnableMouse(IsRaidLeader() and true or false)
    end
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling

    for _, button in ipairs(f.tabs) do
        local active = button.tabKey == self.tab
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

    local friends = self.tab == TAB_FRIENDS
    local who = self.tab == TAB_WHO
    local channels = self.tab == TAB_CHANNELS
    local raid = self.tab == TAB_RAID

    if SetWhoToUI and self.whoUI ~= who then
        self.whoUI = who
        SetWhoToUI(who and 1 or 0)
    end

    f.statusDrop:SetShown(friends)
    f.whoBox:SetShown(who)
    f.whoButton:SetShown(who)
    f.whoColumn:SetShown(who)
    f.whoHeader:SetShown(who)
    f.friendsTab:SetShown(friends)
    f.ignoreTab:SetShown(friends)
    f.caption2:SetShown(channels)

    if friends then
        f.statusDrop:SetEntries({
            { value = STATUS_ONLINE, label = Global("FRIENDS_LIST_AVAILABLE", "В сети") },
            { value = STATUS_AFK, label = Global("FRIENDS_LIST_AWAY", "Отсутствует") },
            { value = STATUS_DND, label = Global("FRIENDS_LIST_BUSY", "Не беспокоить") },
            { value = STATUS_INVISIBLE, label = Global("FRIENDS_LIST_INVISIBLE", "Невидимый") },
        })
        f.statusDrop:SetValue(self:Status())

        f.friendsTab:SetAlpha(self.ignoreView and 0.55 or 1)
        f.ignoreTab:SetAlpha(self.ignoreView and 1 or 0.55)
    end

    if who then
        local entries = {}
        for index, column in ipairs(WHO_COLUMNS) do
            entries[index] = { value = index, label = Global(column.label, column.fallback) }
        end
        f.whoColumn:SetEntries(entries)
        f.whoColumn:SetValue(self.whoColumn or 1)

        local column = WHO_COLUMNS[self.whoColumn or 1]
        f.whoHeader:SetFormattedText("%s", Global(column.label, column.fallback))
        f.whoHeader:ClearAllPoints()
        f.whoHeader:SetPoint("TOPLEFT", f.body, "TOPLEFT", 8 + WHO_X_VARIABLE, -SUBHEADER_H - 2)
    end

    for _, row in ipairs(f.friendRows) do if not friends then row:Hide() end end
    for _, row in ipairs(f.whoRows) do if not who then row:Hide() end end
    for _, row in ipairs(f.channelRows) do if not channels then row:Hide() end end
    for _, row in ipairs(f.memberRows) do if not channels then row:Hide() end end
    for _, row in ipairs(f.raidRows) do if not raid then row:Hide() end end
    for _, row in ipairs(f.instanceRows) do if not raid then row:Hide() end end
    if not raid then
        f.raidText:Hide()
        f.caption:Hide()
        f.assist:Hide()
    end
    f.listScroll:Hide()
    f.totals:Hide()

    local layout = {
        [TAB_FRIENDS] = { "add", "whisper" },
        [TAB_WHO] = { "whoAdd", "whoInvite", "whoWhisper" },
        [TAB_CHANNELS] = { "channelJoin", "channelLeave" },
        [TAB_RAID] = { "convert", "ready", "info", "extend" },
    }

    for _, button in pairs(f.buttons) do button:Hide() end

    self.stripOrder = layout[self.tab] or {}
    for _, key in ipairs(self.stripOrder) do f.buttons[key]:Show() end

    if raid then
        f.assist:ClearAllPoints()
        f.assist:SetPoint("RIGHT", f.strip, "RIGHT", -8 - math.ceil(f.assist.text:GetStringWidth()) - 8, 0)
    end

    if friends then
        self:UpdateFriends()
    elseif who then
        self:UpdateWho()
    elseif channels then
        self:UpdateChannels()
    else
        self:UpdateRaid()
    end

    self:LayoutStrip()
end

function Panel:LayoutStrip()
    local f = self.frame
    local x = 2

    for _, key in ipairs(self.stripOrder or {}) do
        local button = f.buttons[key]

        if button:IsShown() then
            button:ClearAllPoints()
            button:SetPoint("LEFT", f.strip, "LEFT", x, 0)
            x = x + button:GetWidth() + 6
        end
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self.frame:Show()
    self:Refresh()
    self:Update()
end

function Panel:Hide()
    if not self.frame then return end

    if SetWhoToUI and self.whoUI then
        self.whoUI = nil
        SetWhoToUI(0)
    end

    self.frame:Hide()
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.SocialPanel = Panel
