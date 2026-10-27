local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local ROW_H = 34
local ROWS = 7

NS.Densify("NarcissusSirus_GroupFinder", function(f)
    ROW_H, ROWS = NS.DensityRows(34, 7, f)
end)
local ROLE_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
local VOICE_TEXTURE = "Interface\\LFGFrame\\GroupFinder"
local VOICE_COORDS = { 0.9814453125, 0.9970703125, 0.0576171875, 0.0712890625 }

local MODES = {
    { key = "browse", label = "Поиск групп" },
    { key = "own",    label = "Моя группа" },
}

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.85, 0.88
end

local function Enabled()
    return C_LFGList and C_LFGList.IsPremadeGroupFinderEnabled
        and C_LFGList.IsPremadeGroupFinderEnabled()
end

local function ActivityName(activityID, questID)
    if not activityID or not C_LFGList.GetActivityFullName then return "" end
    local ok, name = pcall(C_LFGList.GetActivityFullName, activityID, questID)
    return ok and name or ""
end

function Page:Categories()
    local list = {}
    if not Enabled() then return list end

    for _, categoryID in ipairs(C_LFGList.GetAvailableCategories(0) or {}) do
        local info = C_LFGList.GetLfgCategoryInfo(categoryID)
        if info and info.name then
            list[#list + 1] = { value = categoryID, label = info.name }
        end
    end

    return list
end

function Page:Groups(categoryID)
    local list = { { value = 0, label = L["все"] } }
    if not Enabled() or not categoryID then return list end

    for _, groupID in ipairs(C_LFGList.GetAvailableActivityGroups(categoryID, 0) or {}) do
        local name = C_LFGList.GetActivityGroupInfo(groupID)
        if name then list[#list + 1] = { value = groupID, label = name } end
    end

    return list
end

function Page:Activities(categoryID, groupID)
    local list = {}
    if not Enabled() or not categoryID then return list end

    local activities = C_LFGList.GetAvailableActivities(categoryID,
        (groupID and groupID ~= 0) and groupID or nil, 0)

    for _, activityID in ipairs(activities or {}) do
        list[#list + 1] = { value = activityID, label = ActivityName(activityID) }
    end

    return list
end

function Page:Results()
    if not Enabled() or not C_LFGList.GetSearchResults then return {} end

    local _, results = C_LFGList.GetSearchResults()
    local list = {}

    for _, resultID in ipairs(results or {}) do
        local info = C_LFGList.GetSearchResultInfo(resultID)
        if info and not info.isDelisted then list[#list + 1] = info end
    end

    table.sort(list, function(left, right)
        return (left.age or 0) < (right.age or 0)
    end)

    return list
end

function Page:ApplicationStatus(resultID)
    if not C_LFGList.GetApplicationInfo then return "none" end
    local _, status = C_LFGList.GetApplicationInfo(resultID)
    return status or "none"
end

function Page:Applicants()
    local list = {}
    if not Enabled() or not C_LFGList.GetApplicants then return list end

    for _, applicantID in ipairs(C_LFGList.GetApplicants() or {}) do
        local info = C_LFGList.GetApplicantInfo(applicantID)
        if info then
            local name, classFile, className, level, itemLevel, tank, healer, damage =
                C_LFGList.GetApplicantMemberInfo(applicantID, 1)

            info.name = name
            info.classFile = classFile
            info.className = className
            info.level = level
            info.itemLevel = itemLevel
            info.tank = tank
            info.healer = healer
            info.damage = damage

            list[#list + 1] = info
        end
    end

    table.sort(list, function(left, right)
        return (left.displayOrderID or 0) < (right.displayOrderID or 0)
    end)

    return list
end

function Page:Roles()
    local availTank, availHealer, availDamage = true, true, true
    if C_LFGList.GetAvailableRoles then
        availTank, availHealer, availDamage = C_LFGList.GetAvailableRoles()
    end

    local _, tank, healer, damage = false, false, false, false
    if GetLFGRoles then _, tank, healer, damage = GetLFGRoles() end

    tank = tank and availTank
    healer = healer and availHealer
    damage = damage and availDamage

    if not tank and not healer and not damage then
        return availTank, availHealer, availDamage
    end

    return tank, healer, damage
end

local INFO_W = 340
local MAX_MEMBERS = 26
local MAX_BOSSES = 12

function Page:CreateInfo()
    if self.info then return self.info end

    local S = NS.Styling
    local panel = self.panel

    local f = CreateFrame("Frame", "NarcissusSirus_GroupInfo", panel.frame)
    f:SetWidth(INFO_W)
    f:SetHeight(200)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(panel.frame:GetFrameLevel() + 40)
    panel.Chrome(f)
    S.CreateShadow(f, 5, 0.5)

    local stripe = f:CreateTexture(nil, "ARTWORK")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    stripe:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    stripe:SetTexture(WHITE)
    stripe:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.05)

    local function Text(size, color, bold, width)
        local font = f:CreateFontString(nil, "OVERLAY")
        font:SetFont(NS.FONT, NS.FS(size), bold and "OUTLINE" or "")
        font:SetTextColor(color[1], color[2], color[3])
        font:SetJustifyH("LEFT")
        font:SetWidth(width or (INFO_W - 28))
        return font
    end

    f.title = Text(14, S.GOLD, true)
    f.activity = Text(11, S.TEXT_DIM)
    f.comment = Text(11, { 0.55, 0.78, 0.58 })
    f.meta = Text(11, S.TEXT_NORMAL)

    f.rulesCaption = Text(10, S.ACCENT_GLOW)
    f.rulesCaption:SetText(LFG_LIST_RAID_RULES or L["Правила рейда"])
    f.rules = Text(11, S.TEXT_BRIGHT)

    f.lootCaption = Text(10, S.ACCENT_GLOW)
    f.lootCaption:SetText(LFG_LIST_LOOT_METHOD_LABEL or L["Добыча"])
    f.loot = Text(11, S.TEXT_BRIGHT)

    f.voiceCaption = Text(10, S.ACCENT_GLOW)
    f.voiceCaption:SetText(L["СРЕДСТВО СВЯЗИ"])
    f.voice = Text(11, S.TEXT_BRIGHT)

    f.membersCaption = Text(10, S.ACCENT_GLOW)
    f.membersCaption:SetText(MEMBERS_COLON or L["Участники:"])

    f.members = {}
    for index = 1, MAX_MEMBERS do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(INFO_W - 28, 15)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(13, 13)
        icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        icon:SetTexture(ROLE_TEXTURE)
        row.icon = icon

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(NS.FONT, NS.FS(11), "")
        name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        name:SetJustifyH("LEFT")
        row.name = name

        local ilvl = row:CreateFontString(nil, "OVERLAY")
        ilvl:SetFont(NS.FONT, NS.FS(11), "")
        ilvl:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        ilvl:SetJustifyH("RIGHT")
        row.ilvl = ilvl

        row:Hide()
        f.members[index] = row
    end

    f.bossCaption = Text(10, S.ACCENT_GLOW)
    f.bossCaption:SetText(LFG_LIST_BOSSES_DEFEATED or L["Побежденные боссы"])

    f.bosses = {}
    for index = 1, MAX_BOSSES do
        local line = f:CreateFontString(nil, "OVERLAY")
        line:SetFont(NS.FONT, NS.FS(11), "")
        line:SetTextColor(0.85, 0.4, 0.4)
        line:SetJustifyH("LEFT")
        line:SetWidth(INFO_W - 28)
        line:Hide()
        f.bosses[index] = line
    end

    f.friendsCaption = Text(10, S.ACCENT_GLOW)
    f.friendsCaption:SetText(LFG_LIST_TOOLTIP_FRIENDS_IN_GROUP or L["Друзья в этой группе:"])
    f.friends = Text(11, S.TEXT_BRIGHT)

    f.footer = Text(11, { 0.5, 0.7, 0.95 })

    f:Hide()
    self.info = f
    return f
end

function Page:PlaceInfo(row)
    local f = self.info

    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", row, "TOPRIGHT", 12, 6)

    local right = f:GetRight() or 0
    if right > (UIParent:GetRight() or 0) then
        f:ClearAllPoints()
        f:SetPoint("TOPRIGHT", row, "TOPLEFT", -12, 6)
    end

    local bottom = f:GetBottom() or 0
    if bottom < 10 then
        local point, relative, relativePoint, x = f:GetPoint()
        f:ClearAllPoints()
        f:SetPoint(point, relative, relativePoint, x, 6 + (10 - bottom))
    end
end

function Page:ShowResultTooltip(row)
    local info = C_LFGList.GetSearchResultInfo(row.resultID)
    if not info then return end

    local S = NS.Styling
    local f = self:CreateInfo()
    local width = INFO_W - 28
    local y = -14

    local function Place(font, gap, text)
        if not text or text == "" then
            font:Hide()
            return
        end

        font:SetText(text)
        font:ClearAllPoints()
        font:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - (gap or 0))
        font:Show()
        y = y - (gap or 0) - font:GetStringHeight() - 2
    end

    Place(f.title, 0, info.name ~= "" and info.name or ActivityName(info.activityID, info.questID))
    Place(f.activity, 2, ActivityName(info.activityID, info.questID))
    Place(f.comment, 6, info.comment)

    local meta = {}
    if info.leaderName and info.leaderName ~= "" then
        meta[#meta + 1] = string.format(L["лидер: %s"], info.leaderName)
    end
    if info.requiredItemLevel and info.requiredItemLevel > 0 then
        meta[#meta + 1] = string.format("%s %d",
            LFG_LIST_ITEM_LEVEL_INSTR_SHORT or L["Уровень предметов"], info.requiredItemLevel)
    end
    if info.age and info.age > 0 then
        meta[#meta + 1] = string.format(L["создана %s назад"],
            SecondsToTime(info.age, false, false, 1))
    end
    Place(f.meta, 8, table.concat(meta, "  |  "))

    local rules
    if info.raidRules and info.raidRules ~= "" and C_LFGList.GetRaidRulesString then
        local ok, value = pcall(C_LFGList.GetRaidRulesString, info.raidRules)
        if ok then rules = value end
    end

    if rules and rules ~= "" then
        Place(f.rulesCaption, 10, f.rulesCaption:GetText())
        Place(f.rules, 2, rules)
    else
        f.rulesCaption:Hide()
        f.rules:Hide()
    end

    local loot
    if info.lootMethod and C_LFGList.GetLootMethodString then
        local ok, value = pcall(C_LFGList.GetLootMethodString, info.lootMethod)
        if ok then loot = value end
    end

    if loot and loot ~= "" then
        Place(f.lootCaption, 10, f.lootCaption:GetText())
        Place(f.loot, 2, loot)
    else
        f.lootCaption:Hide()
        f.loot:Hide()
    end

    if info.voiceChat and info.voiceChat ~= "" then
        Place(f.voiceCaption, 10, f.voiceCaption:GetText())
        Place(f.voice, 2, info.voiceChat)
    else
        f.voiceCaption:Hide()
        f.voice:Hide()
    end

    Place(f.membersCaption, 12, f.membersCaption:GetText())

    local shown = 0
    for index = 1, math.min(info.numMembers or 0, MAX_MEMBERS) do
        local member = C_LFGList.GetSearchResultPlayerInfo
            and C_LFGList.GetSearchResultPlayerInfo(row.resultID, index)

        if member then
            shown = shown + 1
            local line = f.members[shown]

            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 2)
            line:SetWidth(width)

            if GetTexCoordsForRole and member.assignedRole then
                line.icon:SetTexCoord(GetTexCoordsForRole(member.assignedRole))
                line.icon:Show()
            else
                line.icon:Hide()
            end

            local name = member.name or "?"
            if member.isLeader then name = name .. " |cffffd100*|r" end
            if member.specName and member.specName ~= "" then
                name = string.format("%s  |cff8a8a92%s|r", name, member.specName)
            end

            line.name:SetText(name)

            local color = member.classFilename and RAID_CLASS_COLORS
                and RAID_CLASS_COLORS[member.classFilename]
            line.name:SetTextColor(color and color.r or 0.9, color and color.g or 0.9,
                color and color.b or 0.95)

            if member.level and member.level > 0 then
                line.ilvl:SetText(member.level)
                line.ilvl:SetTextColor(S.GetILvlColor(member.level))
            else
                line.ilvl:SetText("")
            end

            line:Show()
            y = y - 17
        end
    end

    for index = shown + 1, MAX_MEMBERS do f.members[index]:Hide() end

    local encounters
    if C_LFGList.GetSearchResultEncounterInfo then
        local ok, value = pcall(C_LFGList.GetSearchResultEncounterInfo, row.resultID)
        if ok then encounters = value end
    end

    if encounters and #encounters > 0 then
        Place(f.bossCaption, 12, f.bossCaption:GetText())

        for index = 1, MAX_BOSSES do
            local line = f.bosses[index]
            local name = encounters[index]

            if name then
                line:SetText(name)
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y - 2)
                line:Show()
                y = y - line:GetStringHeight() - 3
            else
                line:Hide()
            end
        end
    else
        f.bossCaption:Hide()
        for index = 1, MAX_BOSSES do f.bosses[index]:Hide() end
    end

    if (info.numCharFriends or 0) + (info.numGuildMates or 0) > 0 then
        local friends
        if LFGListSearchEntryUtil_GetFriendList then
            local ok, value = pcall(LFGListSearchEntryUtil_GetFriendList, row.resultID)
            if ok then friends = value end
        end

        Place(f.friendsCaption, 12, f.friendsCaption:GetText())
        Place(f.friends, 2, friends or "")
    else
        f.friendsCaption:Hide()
        f.friends:Hide()
    end

    Place(f.footer, 8, info.autoAccept and (LFG_LIST_TOOLTIP_AUTO_ACCEPT or "") or nil)

    f:SetHeight(math.max(-y + 14, 80))
    f:Show()
    self:PlaceInfo(row)
end

function Page:HideInfo()
    if self.info then self.info:Hide() end
end

function Page:CreateRow(parent, index, width)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * ROW_H)

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

    local title = row:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(12), "")
    title:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
    title:SetWidth(width - 230)
    title:SetJustifyH("LEFT")
    row.title = title

    local voice = row:CreateTexture(nil, "ARTWORK")
    voice:SetSize(16, 14)
    voice:SetTexture(VOICE_TEXTURE)
    voice:SetTexCoord(unpack(VOICE_COORDS))
    voice:Hide()
    row.voice = voice

    function row:SetVoice(value)
        if not value or value == "" then
            self.voice:Hide()
            self.voiceText = nil
            return
        end

        self.voiceText = value
        self.voice:ClearAllPoints()
        self.voice:SetPoint("LEFT", self.title, "LEFT",
            math.min(self.title:GetStringWidth() + 6, self.title:GetWidth() - 18), 1)
        self.voice:Show()
    end

    local note = row:CreateFontString(nil, "OVERLAY")
    note:SetFont(NS.FONT, NS.FS(10), "")
    note:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    note:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)
    note:SetWidth(width - 210)
    note:SetJustifyH("LEFT")
    row.note = note

    row.roles = {}
    for index, role in ipairs(ROLE_ORDER) do
        local group = CreateFrame("Frame", nil, row)
        group:SetSize(38, 18)
        group:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10 - (#ROLE_ORDER - index) * 40, -4)

        local icon = group:CreateTexture(nil, "ARTWORK")
        icon:SetSize(17, 17)
        icon:SetPoint("LEFT", group, "LEFT", 0, 0)
        icon:SetTexture(ROLE_TEXTURE)
        if GetTexCoordsForRole then
            icon:SetTexCoord(GetTexCoordsForRole(role))
        end
        group.icon = icon

        local count = group:CreateFontString(nil, "OVERLAY")
        count:SetFont(NS.FONT, NS.FS(12), "")
        count:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        count:SetJustifyH("LEFT")
        group.count = count

        group:SetScript("OnEnter", nil)
        row.roles[role] = group
    end

    function row:SetRoleCounts(tank, healer, damage)
        local S2 = NS.Styling
        local values = { TANK = tank or 0, HEALER = healer or 0, DAMAGER = damage or 0 }

        for role, group in pairs(self.roles) do
            local value = values[role] or 0
            group.count:SetText(value)

            if value > 0 then
                group.icon:SetDesaturated(false)
                group.icon:SetAlpha(1)
                group.count:SetTextColor(S2.TEXT_BRIGHT[1], S2.TEXT_BRIGHT[2], S2.TEXT_BRIGHT[3])
            else
                group.icon:SetDesaturated(true)
                group.icon:SetAlpha(0.45)
                group.count:SetTextColor(S2.TEXT_DIM[1], S2.TEXT_DIM[2], S2.TEXT_DIM[3])
            end
        end
    end

    local right = row:CreateFontString(nil, "OVERLAY")
    right:SetFont(NS.FONT, NS.FS(11), "")
    right:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    right:SetPoint("TOPRIGHT", row, "TOPRIGHT", -134, -5)
    right:SetJustifyH("RIGHT")
    row.right = right

    local status = row:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(10), "")
    status:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    status:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 5)
    status:SetJustifyH("RIGHT")
    row.status = status

    row:SetScript("OnEnter", function(self)
        self.glow:Show()

        if self.resultID then
            Page:ShowResultTooltip(self)
            return
        end

        if not self.comment or self.comment == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.title:GetText() or "", 1, 1, 1)
        GameTooltip:AddLine(self.comment, 0.6, 0.75, 0.6, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.glow:Hide()
        GameTooltip:Hide()
        Page:HideInfo()
    end)

    row:SetScript("OnClick", function(self)
        if self.resultID then
            Page.selectedResult = self.resultID
        elseif self.applicantID then
            Page.selectedApplicant = self.applicantID
        end
        Page:Update()
    end)

    row:Hide()
    return row
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome
    local Caption = panel.Caption
    local contentX, contentW, listTop, listBottom, pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", contentX, -72)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    local picker = NS.Widgets.CreateOptionPicker(f, MODES, "browse", function(key)
        Page.mode = key
        Page:Update()
    end, contentW)
    picker:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.picker = picker

    local categoryLabel = Caption(f, CATEGORY or L["Категория"])
    categoryLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -34)
    f.categoryLabel = categoryLabel

    local categoryDrop = NS.Widgets.CreateThemedDropdown(f, 200, function(value)
        Page.categoryID = value
        Page.groupID = 0
        Page.activityID = nil
        Page:Search()
    end)
    categoryDrop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -50)
    f.categoryDrop = categoryDrop

    local search = NS.Widgets.CreateThemedEditBox(f, contentW - 330, 22, 40)
    search:SetPoint("TOPLEFT", categoryDrop, "TOPRIGHT", 10, 0)
    search:SetScript("OnEnterPressed", function(box)
        box:ClearFocus()
        Page:Search()
    end)
    f.search = search

    local refresh = NS.Widgets.CreateThemedButton(f, LFG_LIST_REFRESH or L["Обновить"], 110, 22, function()
        Page:Search()
    end)
    refresh:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -50)
    f.refresh = refresh

    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -82)
    list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 44)
    Chrome(list)
    f.list = list

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(list, index, contentW - 12)
    end

    local emptyText = list:CreateFontString(nil, "OVERLAY")
    emptyText:SetFont(NS.FONT, NS.FS(12), "")
    emptyText:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    emptyText:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -16)
    emptyText:SetWidth(contentW - 40)
    emptyText:SetJustifyH("LEFT")
    emptyText:Hide()
    f.emptyText = emptyText

    local formTitle = list:CreateFontString(nil, "OVERLAY")
    formTitle:SetFont(NS.FONT, NS.FS(14), "OUTLINE")
    formTitle:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    formTitle:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -14)
    formTitle:SetWidth(contentW - 40)
    formTitle:SetJustifyH("LEFT")
    f.formTitle = formTitle

    local groupLabel = Caption(list, L["ГРУППА ЗАНЯТИЙ"])
    groupLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -46)
    f.groupLabel = groupLabel

    local groupDrop = NS.Widgets.CreateThemedDropdown(list, 220, function(value)
        Page.groupID = value
        Page.activityID = nil
        Page:Update()
    end)
    groupDrop:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -62)
    f.groupDrop = groupDrop

    local activityLabel = Caption(list, L["ЗАНЯТИЕ"])
    activityLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 252, -46)
    f.activityLabel = activityLabel

    local activityDrop = NS.Widgets.CreateThemedDropdown(list, 240, function(value)
        Page.activityID = value
        Page:Update()
    end)
    activityDrop:SetPoint("TOPLEFT", list, "TOPLEFT", 252, -62)
    f.activityDrop = activityDrop

    local nameLabel = Caption(list, LFG_LIST_TITLE or L["Название"])
    nameLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -96)
    f.nameLabel = nameLabel

    local nameBox = NS.Widgets.CreateThemedEditBox(list, contentW - 40, 22, 60)
    nameBox:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -112)
    f.nameBox = nameBox

    local commentLabel = Caption(list, COMMENT or L["Комментарий"])
    commentLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -146)
    f.commentLabel = commentLabel

    local commentBox = NS.Widgets.CreateThemedEditBox(list, contentW - 40, 22, 120)
    commentBox:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -162)
    f.commentBox = commentBox

    local ilvlLabel = Caption(list, LFG_LIST_ITEM_LEVEL_REQ or L["Мин. уровень предметов"])
    ilvlLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -196)
    f.ilvlLabel = ilvlLabel

    local ilvlBox = NS.Widgets.CreateThemedEditBox(list, 70, 22, 4)
    ilvlBox:SetPoint("TOPLEFT", list, "TOPLEFT", 16, -212)
    ilvlBox:SetNumeric(true)
    f.ilvlBox = ilvlBox

    local voiceLabel = Caption(list, L["СРЕДСТВО СВЯЗИ"])
    voiceLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 110, -196)
    f.voiceLabel = voiceLabel

    local voiceBox = NS.Widgets.CreateThemedEditBox(list, 220, 22, 40)
    voiceBox:SetPoint("TOPLEFT", list, "TOPLEFT", 110, -212)
    f.voiceBox = voiceBox

    local entryInfo = list:CreateFontString(nil, "OVERLAY")
    entryInfo:SetFont(NS.FONT, NS.FS(11), "")
    entryInfo:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    entryInfo:SetPoint("TOPLEFT", formTitle, "BOTTOMLEFT", 0, -8)
    entryInfo:SetWidth(contentW - 40)
    entryInfo:SetJustifyH("LEFT")
    f.entryInfo = entryInfo

    local status = f:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 8)
    status:SetWidth(contentW - 340)
    status:SetJustifyH("LEFT")
    f.status = status

    local decline = NS.Widgets.CreateThemedButton(f, DECLINE or L["Отклонить"], 120, 26, function()
        Page:DeclineApplicant()
    end, { 0.85, 0.3, 0.3 })
    decline:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -222, 2)
    f.decline = decline

    local action = CreateFrame("Button", nil, f)
    action:SetSize(210, 30)
    action:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    local actionBg = action:CreateTexture(nil, "BACKGROUND")
    actionBg:SetAllPoints()
    actionBg:SetTexture(WHITE)
    actionBg:SetGradientAlpha("VERTICAL",
        S.ACCENT[1] * 0.35, S.ACCENT[2] * 0.35, S.ACCENT[3] * 0.35, 0.95,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    local actionBorder = CreateFrame("Frame", nil, action)
    actionBorder:SetPoint("TOPLEFT", -1, 1)
    actionBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    actionBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    actionBorder:SetBackdropBorderColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    actionBorder:EnableMouse(false)

    local actionLabel = action:CreateFontString(nil, "OVERLAY")
    actionLabel:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    actionLabel:SetTextColor(1, 1, 1)
    actionLabel:SetPoint("CENTER")
    action.label = actionLabel

    action:SetHighlightTexture(WHITE, "ADD")
    action:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.22)
    action:SetScript("OnClick", function() Page:RunAction() end)
    f.action = action

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        for _, name in ipairs({
            "LFG_LIST_AVAILABILITY_UPDATE",
            "LFG_LIST_ACTIVE_ENTRY_UPDATE",
            "LFG_LIST_SEARCH_RESULTS_RECEIVED",
            "LFG_LIST_SEARCH_RESULT_UPDATED",
            "LFG_LIST_APPLICANT_LIST_UPDATED",
            "LFG_LIST_APPLICANT_UPDATED",
        }) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events
    f:Hide()

    self.frame = f
    self.panel = panel
    self.mode = self.mode or "browse"
    return f
end

function Page:Search()
    if not Enabled() then return end

    local f = self.frame
    if not f then return end

    if not self.categoryID then
        local categories = self:Categories()
        if categories[1] then self.categoryID = categories[1].value end
    end

    if not self.categoryID then return end

    self.selectedResult = nil
    self.searching = true

    pcall(C_LFGList.Search, self.categoryID, f.search:GetText() or "", 0, nil)
    self:Update()

    NS.After(1.5, function()
        Page.searching = false
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)
end

function Page:RunAction()
    if self.mode == "own" then
        if C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo() then
            if self.selectedApplicant and C_LFGList.InviteApplicant then
                C_LFGList.InviteApplicant(self.selectedApplicant)
            elseif C_LFGList.RemoveListing then
                C_LFGList.RemoveListing()
            end
        else
            self:CreateListing()
        end

        NS.After(0.5, function() Page:Update() end)
        return
    end

    if not self.selectedResult then return end

    if self:ApplicationStatus(self.selectedResult) == "applied" then
        if C_LFGList.CancelApplication then C_LFGList.CancelApplication(self.selectedResult) end
    else
        local tank, healer, damage = self:Roles()
        if C_LFGList.ApplyToGroup then
            C_LFGList.ApplyToGroup(self.selectedResult, self.frame.commentBox:GetText() or "",
                tank, healer, damage)
        end
    end

    NS.After(0.5, function() Page:Update() end)
end

function Page:CreateListing()
    local f = self.frame

    local name = strtrim(f.nameBox:GetText() or "")
    if name == "" then
        NS.Print(LFG_LIST_MUST_HAVE_NAME or L["Нужно ввести название группы."])
        return
    end

    if not self.activityID then
        NS.Print(LFG_LIST_SELECT_A_CATEGORY or L["Выберите занятие."])
        return
    end

    local itemLevel = tonumber(f.ilvlBox:GetText()) or 0
    local comment = strtrim(f.commentBox:GetText() or "")

    local voiceChat = strtrim(f.voiceBox:GetText() or "")

    if C_LFGList.CreateListing then
        pcall(C_LFGList.CreateListing, self.activityID, name, itemLevel, voiceChat, comment, false, false)
    end
end

function Page:DeclineApplicant()
    if not self.selectedApplicant or not C_LFGList.DeclineApplicant then return end

    C_LFGList.DeclineApplicant(self.selectedApplicant)
    self.selectedApplicant = nil

    NS.After(0.5, function() Page:Update() end)
end

function Page:ShowResults()
    local f = self.frame
    local S = NS.Styling

    local results = self:Results()

    for index = 1, ROWS do
        local row = f.rows[index]
        local info = results[index]

        if info then
            row.resultID = info.searchResultID
            row.applicantID = nil
            row.comment = info.comment

            row.title:SetText(info.name ~= "" and info.name or ActivityName(info.activityID, info.questID))
            row:SetVoice(info.voiceChat)
            row.note:SetText(string.format("%s  |  %s",
                ActivityName(info.activityID, info.questID),
                info.leaderName ~= "" and info.leaderName or "?"))

            local counts = C_LFGList.GetSearchResultMemberCounts
                and C_LFGList.GetSearchResultMemberCounts(info.searchResultID) or {}

            row:SetRoleCounts(counts.TANK, counts.HEALER, counts.DAMAGER)

            local right = string.format(LFG_LIST_MEMBER_COUNT or "%d", info.numMembers or 0)
            if info.requiredItemLevel and info.requiredItemLevel > 0 then
                right = string.format("%s   %s %d", right,
                    LFG_LIST_ITEM_LEVEL_INSTR_SHORT or "ilvl", info.requiredItemLevel)
            end
            row.right:SetText(right)

            local status = self:ApplicationStatus(info.searchResultID)
            if status == "applied" then
                row.status:SetText(LFG_LIST_PENDING or L["заявка отправлена"])
            elseif status == "invited" then
                row.status:SetText(LFG_LIST_APP_INVITED or L["приглашение"])
            elseif status == "declined" then
                row.status:SetText(LFG_LIST_APP_DECLINED or L["отклонено"])
            else
                row.status:SetText(info.age and info.age > 0
                    and string.format(L["создана %s назад"], SecondsToTime(info.age, false, false, 1)) or "")
            end

            row.bar:SetShown(self.selectedResult == info.searchResultID)
            row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                self.selectedResult == info.searchResultID and 0.4 or (index % 2 == 0 and 0.26 or 0.10))

            row:Show()
        else
            row.resultID = nil
            row:Hide()
        end
    end

    if #results == 0 then
        f.emptyText:Show()
        f.emptyText:SetText(self.searching and (LFG_LIST_LOADING or L["Идет загрузка..."])
            or (LFG_LIST_NO_RESULTS_FOUND or L["Группы не найдены."]))
    else
        f.emptyText:Hide()
    end

    return #results
end

function Page:ShowApplicants()
    local f = self.frame
    local S = NS.Styling

    local applicants = self:Applicants()

    for index = 1, ROWS do
        local row = f.rows[index]
        local info = applicants[index]

        if info then
            row.applicantID = info.applicantID
            row.resultID = nil
            row.comment = info.comment

            row.title:SetText(info.name or "?")
            row.title:SetTextColor(ClassColor(info.classFile))
            row:SetVoice(nil)

            row:SetRoleCounts(info.tank and 1 or 0, info.healer and 1 or 0, info.damage and 1 or 0)
            row.note:SetText(info.className or "")

            local right = string.format("%s %d", LEVEL or L["уровень"], info.level or 0)
            if info.itemLevel and info.itemLevel > 0 then
                right = string.format("%s   %s %d", right,
                    LFG_LIST_ITEM_LEVEL_INSTR_SHORT or "ilvl", info.itemLevel)
            end
            row.right:SetText(right)

            if info.applicationStatus == "invited" then
                row.status:SetText(LFG_LIST_APP_INVITED or L["приглашен"])
            elseif info.applicationStatus == "declined" then
                row.status:SetText(LFG_LIST_APP_DECLINED or L["отклонен"])
            else
                row.status:SetText("")
            end

            row.bar:SetShown(self.selectedApplicant == info.applicantID)
            row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                self.selectedApplicant == info.applicantID and 0.4 or (index % 2 == 0 and 0.26 or 0.10))

            row:Show()
        else
            row.applicantID = nil
            row:Hide()
        end
    end

    return #applicants
end

function Page:UpdateBrowse()
    local f = self.frame

    f.categoryLabel:Show()
    f.categoryDrop:Show()
    f.search:Show()
    f.refresh:Show()
    f.decline:Hide()

    f.formTitle:Hide()
    f.entryInfo:Hide()
    f.groupLabel:Hide()
    f.groupDrop:Hide()
    f.activityLabel:Hide()
    f.activityDrop:Hide()
    f.nameLabel:Hide()
    f.nameBox:Hide()
    f.ilvlLabel:Hide()
    f.ilvlBox:Hide()
    f.voiceLabel:Hide()
    f.voiceBox:Hide()

    f.commentLabel:Hide()
    f.commentBox:Hide()

    local categories = self:Categories()
    if not self.categoryID and categories[1] then self.categoryID = categories[1].value end

    f.categoryDrop:SetEntries(categories)
    f.categoryDrop:SetValue(self.categoryID)

    self:ShowResults()

    local status = self.selectedResult and self:ApplicationStatus(self.selectedResult) or "none"
    if status == "applied" then
        f.action.label:SetText(L["Отозвать заявку"])
    else
        f.action.label:SetText(L["Подать заявку"])
    end

    local usable = self.selectedResult and true or false
    f.action:EnableMouse(usable)
    f.action:SetAlpha(usable and 1 or 0.4)

    f.status:SetText(self.selectedResult and "" or (LFG_LIST_SELECT_A_SEARCH_RESULT or ""))
end

function Page:UpdateOwn()
    local f = self.frame

    f.categoryLabel:Show()
    f.categoryDrop:Show()
    f.search:Hide()
    f.refresh:Hide()

    local categories = self:Categories()
    if not self.categoryID and categories[1] then self.categoryID = categories[1].value end
    f.categoryDrop:SetEntries(categories)
    f.categoryDrop:SetValue(self.categoryID)

    local active = C_LFGList.GetActiveEntryInfo and C_LFGList.GetActiveEntryInfo()

    if active then
        f.formTitle:Show()
        f.formTitle:SetText(active.name ~= "" and active.name or ActivityName(active.activityID, active.questID))

        local counts = active.roleCounts or {}
        local lines = {
            ActivityName(active.activityID, active.questID),
            string.format("%s: %d / %s: %d / %s: %d",
                TANK or "Т", counts.TANK or 0,
                HEALER or "Л", counts.HEALER or 0,
                DAMAGER or "Б", counts.DAMAGER or 0),
        }
        if active.comment and active.comment ~= "" then
            lines[#lines + 1] = string.format(LFG_LIST_COMMENT_FORMAT or "%s", active.comment)
        end
        if active.requiredItemLevel and active.requiredItemLevel > 0 then
            lines[#lines + 1] = string.format("%s: %d",
                LFG_LIST_ITEM_LEVEL_REQ or "ilvl", active.requiredItemLevel)
        end
        if active.voiceChat and active.voiceChat ~= "" then
            lines[#lines + 1] = string.format("%s: %s", L["средство связи"], active.voiceChat)
        end

        f.entryInfo:Show()
        f.entryInfo:SetText(table.concat(lines, string.char(10)))

        f.groupLabel:Hide()
        f.groupDrop:Hide()
        f.activityLabel:Hide()
        f.activityDrop:Hide()
        f.nameLabel:Hide()
        f.nameBox:Hide()
        f.commentLabel:Hide()
        f.commentBox:Hide()
        f.ilvlLabel:Hide()
        f.ilvlBox:Hide()
        f.voiceLabel:Hide()
        f.voiceBox:Hide()

        for index = 1, ROWS do
            local row = f.rows[index]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.list, "TOPLEFT", 6, -110 - (index - 1) * ROW_H)
            row:SetPoint("TOPRIGHT", f.list, "TOPRIGHT", -6, -110 - (index - 1) * ROW_H)
        end

        local total = self:ShowApplicants()

        f.emptyText:SetShown(total == 0)
        if total == 0 then
            f.emptyText:ClearAllPoints()
            f.emptyText:SetPoint("TOPLEFT", f.list, "TOPLEFT", 16, -114)
            f.emptyText:SetText(LFG_LIST_NO_APPLICANTS or L["Кандидатов пока нет."])
        end

        f.decline:SetShown(self.selectedApplicant and true or false)

        if self.selectedApplicant then
            f.action.label:SetText(INVITE or L["Пригласить"])
        else
            f.action.label:SetText(L["Снять объявление"])
        end

        f.action:EnableMouse(true)
        f.action:SetAlpha(1)
        f.status:SetText(string.format(LFG_LIST_PENDING_APPLICANTS or "%d", total))
        return
    end

    f.formTitle:Show()
    f.formTitle:SetText(LFG_LIST_CREATING_ENTRY or L["Создание группы"])
    f.entryInfo:Hide()

    f.groupLabel:Show()
    f.groupDrop:Show()
    f.activityLabel:Show()
    f.activityDrop:Show()
    f.nameLabel:Show()
    f.nameBox:Show()
    f.commentLabel:Show()
    f.commentBox:Show()
    f.ilvlLabel:Show()
    f.ilvlBox:Show()
    f.voiceLabel:Show()
    f.voiceBox:Show()

    for index = 1, ROWS do f.rows[index]:Hide() end
    f.emptyText:Hide()
    f.decline:Hide()

    local groups = self:Groups(self.categoryID)
    f.groupDrop:SetEntries(groups)
    f.groupDrop:SetValue(self.groupID or 0)

    local activities = self:Activities(self.categoryID, self.groupID)
    f.activityDrop:SetEntries(activities)

    if not self.activityID and activities[1] then self.activityID = activities[1].value end
    f.activityDrop:SetValue(self.activityID)

    f.action.label:SetText(L["Создать группу"])
    f.action:EnableMouse(true)
    f.action:SetAlpha(1)

    local canList = (GetNumPartyMembers() == 0 or IsPartyLeader())
        and (GetNumRaidMembers() == 0 or IsRaidLeader())

    if not canList then
        f.status:SetText(LFG_LIST_NOT_LEADER or L["нужно быть лидером группы"])
        f.action:EnableMouse(false)
        f.action:SetAlpha(0.4)
    else
        f.status:SetText("")
    end
end

function Page:Update()
    if not self.frame then return end
    local f = self.frame

    if not Enabled() then
        for index = 1, ROWS do f.rows[index]:Hide() end
        f.emptyText:Show()
        f.emptyText:SetText(L["поиск заранее собранных групп отключен на сервере"])
        f.action:Hide()
        f.decline:Hide()
        return
    end

    f.action:Show()
    f.picker:Refresh(self.mode)

    if self.mode == "own" then
        self:UpdateOwn()
    else
        for index = 1, ROWS do
            local row = f.rows[index]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.list, "TOPLEFT", 6, -6 - (index - 1) * ROW_H)
            row:SetPoint("TOPRIGHT", f.list, "TOPRIGHT", -6, -6 - (index - 1) * ROW_H)
        end

        f.emptyText:ClearAllPoints()
        f.emptyText:SetPoint("TOPLEFT", f.list, "TOPLEFT", 16, -16)

        self:UpdateBrowse()
    end
end

function Page:Show()
    if not self.frame then return end
    self.frame:Show()

    if self.mode ~= "own" and not self.searched then
        self.searched = true
        self:Search()
    end
end

function Page:Hide()
    self:HideInfo()
    if self.frame then self.frame:Hide() end
end

NS.PremadeGroupsPage = Page
