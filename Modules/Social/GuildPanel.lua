local addonName, NS = ...
local L = NS.L

local GuildPanel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local CLASS_ICON_TEXTURE = "Interface\\WorldStateFrame\\Icons-Classes"

local PANEL_W = 830
local PANEL_H = 560
local PAD = 16
local HEADER_H = 118
local ROW_H = 26
local ROWS = 14

NS.Densify("NarcissusSirus_GuildPanel", function(f)
    ROW_H, ROWS = NS.DensityRows(26, 14, f)
end)
local TAB_SIZE = 38

local COLUMNS = {
    { key = "name",  label = "Имя",   x = 32,  width = 168 },
    { key = "level", label = "Ур.",   x = 205, width = 40  },
    { key = "ilvl",  label = "УрП",   x = 250, width = 50  },
    { key = "rank",  label = "Ранг",  x = 305, width = 150 },
    { key = "zone",  label = "Зона",  x = 460, width = 320 },
}

local VIEWS = {
    { key = "roster",     label = "Состав",      icon = "Interface\\Icons\\Achievement_BG_winWSG" },
    { key = "applicants", label = "Заявки",      icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { key = "epgp",       label = "EPGP",        icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    { key = "perks",      label = "Привилегии",  icon = "Interface\\Icons\\Spell_Holy_BlessingOfStrength" },
    { key = "rewards",    label = "Награды",     icon = "Interface\\Icons\\INV_Chest_Chain_04" },
    { key = "log",        label = "Журнал",      icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "manage",     label = "Управление гильдией", icon = "Interface\\Icons\\Achievement_Reputation_01" },
    { key = "info",       label = "Информация",  icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}

local PERK_LABELS = {
    name = "Привилегия",
    level = "Ур.",
    ilvl = "",
    rank = "Открывается",
    zone = "",
}

local REWARD_LABELS = {
    name = "Награда",
    level = "",
    ilvl = "Цена",
    rank = "Требуется",
    zone = "",
}

local STANDING_NAMES = {
    [1] = "Ненависть",
    [2] = "Враждебность",
    [3] = "Недружелюбие",
    [4] = "Нейтралитет",
    [5] = "Дружелюбие",
    [6] = "Уважение",
    [7] = "Почтение",
    [8] = "Превознесение",
}

local EPGP_LABELS = {
    name = "Имя",
    level = "EP",
    ilvl = "GP",
    rank = "PR",
    zone = "Ранг",
}

local APPLICANT_LABELS = {
    name = "Имя",
    level = "Ур.",
    ilvl = "Роли",
    rank = "Комментарий",
    zone = "Осталось",
}

local classTokens

local function ClassToken(class)
    if not class then return nil end

    if not classTokens then
        classTokens = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
            classTokens[name] = token
        end
        for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
            classTokens[name] = token
        end
    end

    if classTokens[class] then return classTokens[class] end
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then return class end

    if GetClassFile then
        local ok, token = pcall(GetClassFile, class)
        if ok and token then return token end
    end

    return nil
end

local function ClassColor(class)
    local token = ClassToken(class)
    local colors = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if colors then return colors.r, colors.g, colors.b end
    return 0.85, 0.85, 0.88
end

local function ItemLevelColor(level)
    if not level then return 0.6, 0.6, 0.65 end

    if GetItemLevelColor then
        local ok, color = pcall(GetItemLevelColor, level)
        if ok and color and color.r then return color.r, color.g, color.b end
    end

    if level >= 264 then return 0.64, 0.21, 0.93 end
    if level >= 245 then return 0.00, 0.44, 0.87 end
    if level >= 200 then return 0.12, 1.00, 0.00 end
    return 0.85, 0.85, 0.88
end

local function MemberItemLevel(name)
    if not GetGuildMemberItemLevel then return nil end
    local ok, level = pcall(GetGuildMemberItemLevel, name)
    if ok and level and level > 0 then return level end
    return nil
end

local function LastOnline(baseIndex)
    if not baseIndex or not GetGuildRosterLastOnline then return nil end
    local ok, years, months, days, hours = pcall(GetGuildRosterLastOnline, baseIndex)
    if not ok then return nil end
    if RecentTimeDate then
        local shown, text = pcall(RecentTimeDate, years, months, days, hours)
        if shown and text then return text end
    end
    return nil
end

function GuildPanel:ClassColorOf(class)
    return ClassColor(class)
end

function GuildPanel:CollectApplicants()
    local applicants = {}
    if not GetNumGuildApplicants then return applicants end

    local total = GetNumGuildApplicants() or 0

    for index = 1, total do
        local name, _, level, class, online, inviteSent, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
            isTank, isHealer, isDamage, comment, _, timeLeft = GetGuildApplicantInfo(index)

        if name then
            local roles = {}
            if isTank then roles[#roles + 1] = L["Т"] end
            if isHealer then roles[#roles + 1] = L["Л"] end
            if isDamage then roles[#roles + 1] = L["У"] end

            local days = timeLeft and math.floor(timeLeft / 86400) or 0

            applicants[#applicants + 1] = {
                index = index,
                name = name,
                level = level or 0,
                class = class,
                online = online and true or false,
                inviteSent = inviteSent and true or false,
                roles = table.concat(roles, " "),
                comment = comment or "",
                timeLeft = days > 0 and string.format(L["%d дн."], days) or L["сегодня"],
            }
        end
    end

    return applicants
end

function GuildPanel:RequestApplicants()
    if RequestGuildApplicantsList then pcall(RequestGuildApplicantsList) end
end

function GuildPanel:RequestRoster()
    if SetGuildRosterShowOffline then
        SetGuildRosterShowOffline(self.showOffline and true or false)
    end
    if GuildRoster then GuildRoster() end
end

function GuildPanel:Collect()
    local members = {}
    if not IsInGuild or not IsInGuild() then return members end

    local total = GetNumGuildMembers and GetNumGuildMembers() or 0

    for index = 1, total do
        local reader = GetGuildRosterInfoEx or GetGuildRosterInfo
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, baseIndex =
            reader(index)

        if name then
            members[#members + 1] = {
                index = index,
                name = name,
                rank = rank,
                rankIndex = rankIndex or 0,
                level = level or 0,
                class = class,
                zone = zone,
                note = note,
                officerNote = officerNote,
                online = online and true or false,
                ilvl = MemberItemLevel(name),
                lastOnline = LastOnline(baseIndex),
            }
        end
    end

    return members
end

function GuildPanel:Sorted(members)
    local key = self.sortKey or "name"
    local descending = self.sortDescending

    local function value(member)
        if key == "level" then return member.level end
        if key == "ilvl" then return member.ilvl or 0 end
        if key == "rank" then return -(member.rankIndex or 0) end
        if key == "zone" then return NS.Lower(member.zone) end
        return NS.Lower(member.name)
    end

    table.sort(members, function(left, right)
        if left.online ~= right.online then return left.online end

        local a, b = value(left), value(right)
        if a == b then return (left.name or "") < (right.name or "") end
        if descending then return a > b end
        return a < b
    end)

    return members
end

function GuildPanel:Visible()
    local members = self:Collect()
    local filter = self.filter
    local showOffline = self.showOffline

    local result = {}
    for _, member in ipairs(members) do
        local pass = showOffline or member.online
        if pass and filter and filter ~= "" then
            pass = string.find(NS.Lower(member.name), filter, 1, true)
                or (member.zone and string.find(NS.Lower(member.zone), filter, 1, true))
                or (member.rank and string.find(NS.Lower(member.rank), filter, 1, true))
        end
        if pass then result[#result + 1] = member end
    end

    return self:Sorted(result)
end

function GuildPanel:CreateRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetSize(PANEL_W - PAD * 2, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD, -HEADER_H - (index - 1) * ROW_H)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.35 or 0.18)
    row.plate = plate

    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", row, "LEFT", 2, 0)
    dot:SetTexture(WHITE)
    row.dot = dot

    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(16, 16)
    classIcon:SetPoint("LEFT", row, "LEFT", 12, 0)
    classIcon:SetTexture(CLASS_ICON_TEXTURE)
    row.classIcon = classIcon

    row.cells = {}
    for _, column in ipairs(COLUMNS) do
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetPoint("LEFT", row, "LEFT", column.x, 0)
        text:SetWidth(column.width)
        text:SetJustifyH("LEFT")
        row.cells[column.key] = text
    end

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)

    row:SetScript("OnEnter", function(self)
        if self.perk and self.perk.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local link = GetSpellLink and GetSpellLink(self.perk.spellID)
            if not link or not pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
                GameTooltip:AddLine(self.perk.name, 1, 1, 1)
            end
            GameTooltip:Show()
            return
        end

        if self.reward and self.reward.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if not pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.reward.itemID) then
                GameTooltip:AddLine(self.reward.name, 1, 1, 1)
            end
            GameTooltip:Show()
            return
        end

        if self.standing then
            local standing = self.standing
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(standing.name, ClassColor(standing.class))
            GameTooltip:AddLine(string.format("EP %d, GP %d, PR %.3f",
                standing.ep or 0, standing.gp or 0, standing.pr or 0), 0.8, 0.8, 0.85)
            if not standing.qualified then
                GameTooltip:AddLine(L["EP ниже минимального"], 0.85, 0.5, 0.5)
            end
            if standing.alts then
                GameTooltip:AddLine(L["твинки: "] .. table.concat(standing.alts, ", "),
                    0.6, 0.6, 0.65, true)
            end
            GameTooltip:Show()
            return
        end

        if self.applicant then
            local applicant = self.applicant
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(applicant.name, ClassColor(applicant.class))
            GameTooltip:AddLine(string.format("%s %d", L["уровень"], applicant.level), 0.8, 0.8, 0.85)
            if applicant.roles ~= "" then
                GameTooltip:AddLine(L["роли: "] .. applicant.roles, 0.6, 0.6, 0.65)
            end
            if applicant.comment ~= "" then
                GameTooltip:AddLine(applicant.comment, 0.55, 0.75, 0.55, true)
            end
            GameTooltip:Show()
            return
        end

        local member = self.member
        if not member then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(member.name, ClassColor(member.class))
        GameTooltip:AddLine(string.format("%s %d, %s", L["уровень"], member.level, member.rank or ""),
            0.8, 0.8, 0.85)
        if member.zone then GameTooltip:AddLine(member.zone, 0.6, 0.6, 0.65) end
        if member.note and member.note ~= "" then
            GameTooltip:AddLine(L["заметка: "] .. member.note, 0.55, 0.75, 0.55, true)
        end
        if member.officerNote and member.officerNote ~= "" then
            GameTooltip:AddLine(L["заметка офицера: "] .. member.officerNote, 0.55, 0.65, 0.85, true)
        end
        if not member.online and member.lastOnline then
            GameTooltip:AddLine(L["был в сети: "] .. member.lastOnline, 0.6, 0.6, 0.65)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row:SetScript("OnClick", function(self)
        if self.standing then
            GuildPanel.selectedEPGP = self.standing.name
            GuildPanel:Update()
            return
        end
        if self.reward then
            GuildPanel.selectedReward = self.reward.itemID
            GuildPanel:Update()
            return
        end
        if self.perk then
            return
        end
        if self.applicant then
            GuildPanel.selectedApplicant = self.applicant.name
            GuildPanel:Update()
            return
        end
        if not self.member then return end
        GuildPanel.selected = self.member.name
        GuildPanel:Update()

        if not NS.GuildMemberCard then
            NS.Print(L["карточка игрока не загружена, перезапустите клиент"])
            return
        end

        local ok, err = pcall(NS.GuildMemberCard.Show, NS.GuildMemberCard,
            GuildPanel.frame, self.member)
        if not ok then NS.Print("GuildMemberCard: " .. tostring(err)) end
    end)

    row:SetScript("OnDoubleClick", function(self)
        local who = self.member or self.applicant
        if not who then return end
        if ChatFrame_OpenChat then
            ChatFrame_OpenChat("/w " .. who.name .. " ")
        end
    end)

    row:Hide()
    return row
end

function GuildPanel:CreateHeaderButton(parent, column)
    local S = NS.Styling

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(column.width, 18)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD + column.x, -HEADER_H + 20)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    label:SetPoint("LEFT")
    label:SetText(L[column.label])
    button.label = label

    button:SetScript("OnClick", function()
        if GuildPanel.sortKey == column.key then
            GuildPanel.sortDescending = not GuildPanel.sortDescending
        else
            GuildPanel.sortKey = column.key
            GuildPanel.sortDescending = (column.key == "level" or column.key == "ilvl")
        end
        GuildPanel:Update()
    end)

    return button
end

function GuildPanel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_GuildPanel", UIParent)
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
    S.CreateShadow(f, 5, 0.4)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(17), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -14)
    f.title = title

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    f.subtitle = subtitle

    local close = NS.Widgets.CreateCloseButton(f, 18, function() GuildPanel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 22, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -62)
    search:SetScript("OnTextChanged", function(box)
        GuildPanel.filter = NS.Lower(strtrim(box:GetText() or ""))
        GuildPanel.page = 1
        GuildPanel:Update()
    end)
    f.search = search

    local offline = NS.Widgets.CreateThemedCheckbox(f, L["Показывать не в сети"],
        GetGuildRosterShowOffline and GetGuildRosterShowOffline() or false, function(value)
            GuildPanel.showOffline = value
            GuildPanel.page = 1
            GuildPanel:RequestRoster()
            GuildPanel:Update()
        end)
    offline:SetPoint("TOPRIGHT", f, "TOPRIGHT",
        -PAD - (offline.text:GetStringWidth() or 0) - 10, -64)
    f.offline = offline

    f.headers = {}
    for _, column in ipairs(COLUMNS) do
        f.headers[column.key] = self:CreateHeaderButton(f, column)
    end

    local rule = f:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -HEADER_H + 2)
    rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -HEADER_H + 2)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(f, index)
    end

    local info = CreateFrame("ScrollFrame", "NarcissusSirus_GuildInfoScroll", f, "UIPanelScrollFrameTemplate")
    info:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -HEADER_H + 10)
    info:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD - 24, 54)

    local infoBody = CreateFrame("Frame", nil, info)
    infoBody:SetSize(PANEL_W - PAD * 2 - 30, 10)
    info:SetScrollChild(infoBody)

    local motdTitle = infoBody:CreateFontString(nil, "OVERLAY")
    motdTitle:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    motdTitle:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    motdTitle:SetPoint("TOPLEFT", infoBody, "TOPLEFT", 0, 0)
    motdTitle:SetText(L["Объявление дня"])

    local motd = infoBody:CreateFontString(nil, "OVERLAY")
    motd:SetFont(NS.FONT, NS.FS(12), "")
    motd:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    motd:SetPoint("TOPLEFT", motdTitle, "BOTTOMLEFT", 0, -8)
    motd:SetWidth(PANEL_W - PAD * 2 - 40)
    motd:SetJustifyH("LEFT")
    infoBody.motd = motd

    local textTitle = infoBody:CreateFontString(nil, "OVERLAY")
    textTitle:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    textTitle:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    textTitle:SetPoint("TOPLEFT", motd, "BOTTOMLEFT", 0, -18)
    textTitle:SetText(L["О гильдии"])

    local infoText = infoBody:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(NS.FONT, NS.FS(12), "")
    infoText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    infoText:SetPoint("TOPLEFT", textTitle, "BOTTOMLEFT", 0, -8)
    infoText:SetWidth(PANEL_W - PAD * 2 - 40)
    infoText:SetJustifyH("LEFT")
    infoBody.infoText = infoText

    info.body = infoBody
    info:Hide()
    f.info = info

    local pageLabel = f:CreateFontString(nil, "OVERLAY")
    pageLabel:SetFont(NS.FONT, NS.FS(11), "")
    pageLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pageLabel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -104, 20)
    f.pageLabel = pageLabel

    local prev = NS.Widgets.CreateThemedButton(f, "<", 30, 20, function()
        GuildPanel.page = math.max(1, (GuildPanel.page or 1) - 1)
        GuildPanel:Update()
    end)
    prev:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -56, 16)
    f.prev = prev

    local nextPage = NS.Widgets.CreateThemedButton(f, ">", 30, 20, function()
        GuildPanel.page = (GuildPanel.page or 1) + 1
        GuildPanel:Update()
    end)
    nextPage:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 16)
    f.nextPage = nextPage

    f.viewButtons = {}
    for index, view in ipairs(VIEWS) do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(TAB_SIZE, TAB_SIZE)
        button:SetPoint("TOPLEFT", f, "TOPRIGHT", 8, -HEADER_H - (index - 1) * (TAB_SIZE + 10))

        local backdrop = CreateFrame("Frame", nil, button)
        backdrop:SetPoint("TOPLEFT", -3, 3)
        backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
        backdrop:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        backdrop:SetBackdropColor(S.Bg(0.97))
        backdrop:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        backdrop:SetFrameLevel(math.max(button:GetFrameLevel() - 1, 1))
        button.backdrop = backdrop

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetTexture(view.icon)
        button.icon = icon

        local badge = button:CreateFontString(nil, "OVERLAY")
        badge:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
        badge:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        badge:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        button.badge = badge

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(WHITE)
        highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.25)

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L[view.label], 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnClick", function()
            GuildPanel.view = view.key
            GuildPanel.page = 1
            GuildPanel:Update()
        end)

        f.viewButtons[index] = button
    end

    f.actions = {}
    local actions = {
        { key = "whisper", label = L["Шепнуть"] },
        { key = "invite",  label = L["В группу"] },
        { key = "promote", label = L["Повысить"] },
        { key = "demote",  label = L["Понизить"] },
        { key = "remove",  label = L["Исключить"] },
    }

    for index, action in ipairs(actions) do
        local button = NS.Widgets.CreateThemedButton(f, action.label, 92, 22, function()
            GuildPanel:RunAction(action.key)
        end)
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + (index - 1) * 98, 16)
        f.actions[action.key] = button
    end

    f.applicantActions = {}
    local applicantActions = {
        { key = "invite",  label = L["Пригласить"] },
        { key = "decline", label = L["Отклонить"] },
        { key = "tell",    label = L["Шепнуть"] },
    }

    for index, action in ipairs(applicantActions) do
        local button = NS.Widgets.CreateThemedButton(f, action.label, 92, 22, function()
            GuildPanel:RunApplicantAction(action.key)
        end)
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + (index - 1) * 98, 16)
        button:Hide()
        f.applicantActions[action.key] = button
    end

    local value = NS.Widgets.CreateThemedEditBox(f, 90, 22, 8)
    value:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -62)
    value:SetText("0")
    value:Hide()
    f.value = value

    local valueLabel = f:CreateFontString(nil, "OVERLAY")
    valueLabel:SetFont(NS.FONT, NS.FS(11), "")
    valueLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    valueLabel:SetPoint("LEFT", value, "RIGHT", 10, 0)
    valueLabel:SetText(L["значение для начислений и списаний"])
    valueLabel:Hide()
    f.valueLabel = valueLabel

    f.epgpActions = {}
    local epgpActions = {
        { key = "ep",      label = L["+EP"] },
        { key = "epminus", label = L["-EP"] },
        { key = "gp",      label = L["+GP"] },
        { key = "gpminus", label = L["-GP"] },
        { key = "raid",    label = L["EP рейду"] },
        { key = "cut",     label = L["Срез EP %"] },
        { key = "decay",   label = L["Спад"] },
        { key = "undo",    label = L["Отменить"] },
    }

    for index, action in ipairs(epgpActions) do
        local button = NS.Widgets.CreateThemedButton(f, action.label, 88, 22, function()
            GuildPanel:RunEPGPAction(action.key)
        end)
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + (index - 1) * 96, 16)
        button:Hide()
        f.epgpActions[action.key] = button
    end

    f.extraActions = {}
    local extraActions = {
        { key = "buy",    label = L["Купить"] },
        { key = "invite", label = L["Добавить игрока"] },
    }

    local extraSlots = { buy = 0, invite = 5 }

    for _, action in ipairs(extraActions) do
        local button = NS.Widgets.CreateThemedButton(f, action.label, 140, 22, function()
            GuildPanel:RunExtraAction(action.key)
        end)
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + extraSlots[action.key] * 98, 16)
        button:Hide()
        f.extraActions[action.key] = button
    end

    StaticPopupDialogs["NARCISSUSSIRUS_GUILD_INVITE"] = {
        text = L["Кого пригласить в гильдию?"],
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        maxLetters = 24,
        OnAccept = function(popup)
            local box = popup and popup.editBox or _G["StaticPopup1EditBox"]
            local name = box and strtrim(box:GetText() or "")
            if name and name ~= "" and GuildInvite then GuildInvite(name) end
        end,
        EditBoxOnEnterPressed = function(box)
            local name = strtrim(box:GetText() or "")
            if name ~= "" and GuildInvite then GuildInvite(name) end
            box:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    }

    local events = CreateFrame("Frame")
    events:RegisterEvent("GUILD_ROSTER_UPDATE")
    events:RegisterEvent("PLAYER_GUILD_UPDATE")
    events:RegisterEvent("LF_GUILD_RECRUIT_LIST_CHANGED")
    events:SetScript("OnEvent", function()
        if GuildPanel.frame and GuildPanel.frame:IsShown() then GuildPanel:Update() end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_GuildPanel")

    self.view = self.view or "roster"
    self.page = self.page or 1
    self.sortKey = self.sortKey or "name"
    if self.showOffline == nil then
        self.showOffline = GetGuildRosterShowOffline and GetGuildRosterShowOffline() or false
    end
    self.frame = f
    f:Hide()
end

function GuildPanel:SelectedMember()
    if not self.selected then return nil end
    for _, member in ipairs(self:Collect()) do
        if member.name == self.selected then return member end
    end
    return nil
end

function GuildPanel:RunAction(key)
    local member = self:SelectedMember()
    if not member then
        NS.Print(L["сначала выберите игрока в списке"])
        return
    end

    if key == "whisper" then
        if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. member.name .. " ") end
    elseif key == "invite" then
        if InviteUnit then InviteUnit(member.name) end
    elseif key == "promote" then
        NS.Widgets.ShowConfirm(string.format(L["Повысить %s?"], member.name), L["Повысить"], function()
            if GuildPromote then GuildPromote(member.name) end
        end)
    elseif key == "demote" then
        NS.Widgets.ShowConfirm(string.format(L["Понизить %s?"], member.name), L["Понизить"], function()
            if GuildDemote then GuildDemote(member.name) end
        end)
    elseif key == "remove" then
        NS.Widgets.ShowConfirm(string.format(L["Исключить %s из гильдии?"], member.name), L["Исключить"], function()
            if GuildUninvite then GuildUninvite(member.name) end
        end)
    end
end

function GuildPanel:SelectedApplicant()
    if not self.selectedApplicant then return nil end
    for _, applicant in ipairs(self:CollectApplicants()) do
        if applicant.name == self.selectedApplicant then return applicant end
    end
    return nil
end

function GuildPanel:RunApplicantAction(key)
    local applicant = self:SelectedApplicant()
    if not applicant then
        NS.Print(L["сначала выберите заявку в списке"])
        return
    end

    if key == "invite" then
        NS.Widgets.ShowConfirm(string.format(L["Пригласить %s в гильдию?"], applicant.name),
            L["Пригласить"], function()
                if GuildInviteApplicant then GuildInviteApplicant(applicant.name) end
                GuildPanel:RequestApplicants()
            end)
    elseif key == "decline" then
        NS.Widgets.ShowConfirm(string.format(L["Отклонить заявку %s?"], applicant.name),
            L["Отклонить"], function()
                if DeclineGuildApplicant then DeclineGuildApplicant(applicant.index) end
                GuildPanel.selectedApplicant = nil
                GuildPanel:RequestApplicants()
            end)
    elseif key == "tell" then
        if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. applicant.name .. " ") end
    end
end

function GuildPanel:RunExtraAction(key)
    if key == "invite" then
        if not CanGuildInvite or not CanGuildInvite() then
            NS.Print(L["нет права приглашать в гильдию"])
            return
        end
        StaticPopup_Show("NARCISSUSSIRUS_GUILD_INVITE")
        return
    end

    if key == "buy" then
        if not self.selectedReward then
            NS.Print(L["сначала выберите награду в списке"])
            return
        end
        if BuyGuildReward then
            local itemID = self.selectedReward
            NS.Widgets.ShowConfirm(L["Купить выбранную награду?"], L["Купить"], function()
                pcall(BuyGuildReward, itemID)
            end)
        end
    end
end

function GuildPanel:UpdateRewardActions()
    local f = self.frame
    local S = NS.Styling
    local button = f.extraActions.buy

    if self.selectedReward then
        button:Enable()
        button.label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    else
        button:Disable()
        button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end
end

function GuildPanel:EPGPValue()
    local f = self.frame
    local amount = tonumber(f.value:GetText() or "0") or 0
    return math.floor(amount)
end

function GuildPanel:RunEPGPAction(key)
    local epgp = NS.EPGP
    if not epgp then return end

    local amount = self:EPGPValue()
    local member = self.selectedEPGP

    if key == "undo" then
        epgp:Undo()
        self:Update()
        return
    end

    if key == "cut" then
        local percent = math.abs(amount)
        if percent <= 0 or percent > 100 then
            NS.Print(L["введите процент от 1 до 100 в поле слева"])
            return
        end

        NS.Widgets.ShowConfirm(string.format(L["Срезать %d%% EP у всей гильдии?"], percent),
            L["Срезать"], function()
                local changed = NS.EPGP:CutEP(percent)
                NS.Print(string.format(L["EP срезано у записей: %d"], changed))
                GuildPanel:Update()
            end)
        return
    end

    if key == "decay" then
        NS.Widgets.ShowConfirm(string.format(L["Списать %d%% у всех?"], epgp.config.decay_p or 0),
            L["Спад"], function()
                local changed = epgp:Decay()
                NS.Print(string.format(L["спад применён к %d записям"], changed))
                GuildPanel:Update()
            end)
        return
    end

    if amount == 0 then
        NS.Print(L["введите значение в поле слева"])
        return
    end

    if key == "raid" then
        NS.Widgets.ShowConfirm(string.format(L["Начислить %d EP всем в рейде?"], amount),
            L["Начислить"], function()
                local awarded = epgp:MassEP(amount, string.format(L["Рейд: %d EP"], amount))
                NS.Print(string.format(L["EP начислено игрокам: %d"], awarded))
                GuildPanel:Update()
            end)
        return
    end

    if not member then
        NS.Print(L["сначала выберите игрока в списке"])
        return
    end

    if key == "ep" or key == "epminus" then
        local delta = key == "epminus" and -math.abs(amount) or amount
        epgp:IncEPBy(member, delta, string.format(L["%s: %d EP"], member, delta))
    elseif key == "gp" or key == "gpminus" then
        local delta = key == "gpminus" and -math.abs(amount) or amount
        epgp:IncGPBy(member, delta, string.format(L["%s: %d GP"], member, delta))
    end

    self:Update()
end

function GuildPanel:UpdateEPGPActions()
    local f = self.frame
    local epgp = NS.EPGP
    local S = NS.Styling
    local canWrite = epgp and epgp:CanWrite()

    local hasTarget = canWrite and self.selectedEPGP ~= nil

    local states = {
        ep = hasTarget,
        epminus = hasTarget,
        gp = hasTarget,
        gpminus = hasTarget,
        raid = canWrite,
        cut = canWrite,
        decay = canWrite and (epgp.config.decay_p or 0) > 0,
        undo = canWrite and #epgp:Log() > 0,
    }

    for key, button in pairs(f.epgpActions) do
        if states[key] then
            button:Enable()
            button.label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        else
            button:Disable()
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
end

function GuildPanel:ShowStandings()
    local f = self.frame
    local S = NS.Styling
    local epgp = NS.EPGP

    local standings = epgp and epgp:Standings() or {}

    local filter = self.filter
    if filter and filter ~= "" then
        local matched = {}
        for _, member in ipairs(standings) do
            if string.find(NS.Lower(member.name), filter, 1, true) then
                matched[#matched + 1] = member
            end
        end
        standings = matched
    end

    local pages = math.max(1, math.ceil(#standings / ROWS))
    self.page = math.min(math.max(1, self.page or 1), pages)
    local first = (self.page - 1) * ROWS

    for index = 1, ROWS do
        local row = f.rows[index]
        local member = standings[first + index]

        if member then
            self:ClearRow(row)
            row.standing = member
            row.dot:Show()

            local red, green, blue = ClassColor(member.class)
            local dim = member.qualified and 1 or 0.55

            row.dot:SetVertexColor(member.online and 0.3 or 0.35,
                member.online and 0.85 or 0.35, member.online and 0.4 or 0.4, 1)

            local token = ClassToken(member.class)
            local coords = token and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
            if coords then
                row.classIcon:SetTexture(CLASS_ICON_TEXTURE)
                row.classIcon:SetTexCoord(unpack(coords))
                row.classIcon:SetVertexColor(dim, dim, dim, 1)
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end

            row.cells.name:SetText(member.name)
            row.cells.name:SetTextColor(red * dim, green * dim, blue * dim)
            row.cells.level:SetText(member.ep or 0)
            row.cells.ilvl:SetText(member.gp or 0)
            row.cells.rank:SetText(string.format("%.3f", member.pr or 0))
            row.cells.zone:SetText(member.rank or "")

            for key, cell in pairs(row.cells) do
                if key ~= "name" then
                    cell:SetTextColor(S.TEXT_NORMAL[1] * dim, S.TEXT_NORMAL[2] * dim, S.TEXT_NORMAL[3] * dim)
                end
            end

            row.cells.rank:SetTextColor(S.GOLD[1] * dim, S.GOLD[2] * dim, S.GOLD[3] * dim)

            if self.selectedEPGP == member.name then
                row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
            else
                row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                    index % 2 == 0 and 0.35 or 0.18)
            end

            row:Show()
        else
            self:ClearRow(row)
            row.classIcon:Hide()
            row:Hide()
        end
    end

    f.pageLabel:SetText(string.format(L["Стр. %d из %d"], self.page, pages))
    self:UpdateEPGPActions()
end

function GuildPanel:UpdateApplicantActions()
    local f = self.frame
    local applicant = self:SelectedApplicant()
    local S = NS.Styling
    local canInvite = CanGuildInvite and CanGuildInvite()

    local states = {
        invite = applicant ~= nil and canInvite and not applicant.inviteSent,
        decline = applicant ~= nil and canInvite,
        tell = applicant ~= nil,
    }

    for key, button in pairs(f.applicantActions) do
        if states[key] then
            button:Enable()
            button.label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        else
            button:Disable()
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
end

function GuildPanel:UpdateActions()
    local f = self.frame
    local member = self:SelectedMember()
    local S = NS.Styling

    local _, _, myRankIndex = GetGuildInfo("player")
    myRankIndex = myRankIndex or 0
    local maxRank = (GuildControlGetNumRanks and GuildControlGetNumRanks() or 1) - 1

    local canPromote = member and CanGuildPromote and CanGuildPromote()
        and member.rankIndex > myRankIndex + 1
    local canDemote = member and CanGuildDemote and CanGuildDemote()
        and member.rankIndex < maxRank and member.rankIndex > myRankIndex
    local canRemove = member and CanGuildRemove and CanGuildRemove()
        and member.rankIndex >= 1 and member.rankIndex > myRankIndex

    local states = {
        whisper = member ~= nil,
        invite = member ~= nil and member.online,
        promote = canPromote,
        demote = canDemote,
        remove = canRemove,
    }

    for key, button in pairs(f.actions) do
        if states[key] then
            button:Enable()
            button.label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        else
            button:Disable()
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
end

function GuildPanel:UpdateLog()
    local f = self.frame
    local body = f.info.body

    if QueryGuildEventLog then pcall(QueryGuildEventLog) end

    body.motd:SetText("")
    body.infoText:SetText(self:EventText())

    local height = 60 + body.infoText:GetStringHeight()
    body:SetHeight(math.max(height, 10))
end

function GuildPanel:UpdateInfo()
    local f = self.frame
    local body = f.info.body

    body.motd:SetText(GetGuildRosterMOTD and GetGuildRosterMOTD() or "")
    body.infoText:SetText(GetGuildInfoText and GetGuildInfoText() or "")

    local height = 60 + body.motd:GetStringHeight() + body.infoText:GetStringHeight()
    body:SetHeight(math.max(height, 10))
end

function GuildPanel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end
    local S = NS.Styling

    local guildName, rankName = GetGuildInfo("player")
    f.title:SetText(guildName or L["Гильдия"])

    local members = self:Collect()
    local online = 0
    for _, member in ipairs(members) do
        if member.online then online = online + 1 end
    end
    local level = GetGuildLevel and GetGuildLevel() or 0
    local xp, nextLevel = 0, 0
    if UnitGetGuildXP then xp, nextLevel = UnitGetGuildXP("player") end
    local standing, repMin, repMax = 0, 0, 0
    if GetGuildReputation then standing, repMin, repMax = GetGuildReputation() end

    local details = string.format(L["в сети %d, всего в списке %d, ваш ранг: %s"],
        online, #members, rankName or "-")

    if level and level > 0 then
        details = details .. string.format(L["  |  уровень гильдии %d (%d/%d)"],
            level, xp or 0, nextLevel or 0)
    end

    if standing and standing > 0 then
        details = details .. string.format(L["  |  репутация: %s (%d/%d)"],
            STANDING_NAMES[standing] and L[STANDING_NAMES[standing]] or standing, repMin or 0, repMax or 0)
    end

    f.subtitle:SetText(details)

    local numApplicants = GetNumGuildApplicants and GetNumGuildApplicants() or 0

    for index, view in ipairs(VIEWS) do
        local button = f.viewButtons[index]

        if view.key == "applicants" and numApplicants > 0 then
            button.badge:SetText(numApplicants)
        else
            button.badge:SetText("")
        end

        if view.key == self.view then
            button.backdrop:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            button.icon:SetDesaturated(false)
            button.icon:SetAlpha(1)
        else
            button.backdrop:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            button.icon:SetDesaturated(true)
            button.icon:SetAlpha(0.7)
        end
    end

    local rosterView = self.view == "roster"
    local applicantView = self.view == "applicants"
    local epgpView = self.view == "epgp"
    local perkView = self.view == "perks"
    local rewardView = self.view == "rewards"
    local manageView = self.view == "manage"
    local logView = self.view == "log"
    local listView = rosterView or applicantView or epgpView or perkView or rewardView

    for _, column in ipairs(COLUMNS) do
        local header = f.headers[column.key]
        if listView then header:Show() else header:Hide() end

        local labels = (applicantView and APPLICANT_LABELS)
            or (epgpView and EPGP_LABELS)
            or (perkView and PERK_LABELS)
            or (rewardView and REWARD_LABELS)
        header.label:SetText(L[labels and labels[column.key] or column.label])

        if rosterView and column.key == self.sortKey then
            header.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            header.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end

    if NS.GuildMemberCard then
        if rosterView then
            local selected = self:SelectedMember()
            if selected then NS.GuildMemberCard:Refresh(selected) end
        else
            NS.GuildMemberCard:Hide()
        end
    end

    f.search:SetShown(rosterView or epgpView)
    f.offline:SetShown(rosterView)
    f.value:SetShown(epgpView)
    f.valueLabel:SetShown(epgpView)

    if epgpView then
        f.search:ClearAllPoints()
        f.search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -62)
    else
        f.search:ClearAllPoints()
        f.search:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -62)
    end
    f.prev:SetShown(listView)
    f.nextPage:SetShown(listView)
    f.pageLabel:SetShown(listView)

    for _, button in pairs(f.actions) do
        button:SetShown(rosterView)
    end

    for _, button in pairs(f.applicantActions) do
        button:SetShown(applicantView)
    end

    for _, button in pairs(f.epgpActions) do
        button:SetShown(epgpView)
    end

    f.extraActions.buy:SetShown(rewardView)
    f.extraActions.invite:SetShown(rosterView or self.view == "info")

    if manageView then
        for _, row in ipairs(f.rows) do row:Hide() end
        f.info:Hide()
        if NS.GuildAdminView then NS.GuildAdminView:Show(f) end
        return
    end

    if NS.GuildAdminView then NS.GuildAdminView:Hide() end

    if not listView then
        for _, row in ipairs(f.rows) do row:Hide() end
        f.info:Show()
        if logView then self:UpdateLog() else self:UpdateInfo() end
        return
    end

    f.info:Hide()

    if applicantView then
        self:ShowApplicants()
        return
    end

    if epgpView then
        self:ShowStandings()
        return
    end

    if perkView then
        self:ShowPerks()
        return
    end

    if rewardView then
        self:ShowRewards()
        return
    end

    local visible = self:Visible()
    local pages = math.max(1, math.ceil(#visible / ROWS))
    self.page = math.min(math.max(1, self.page or 1), pages)
    local first = (self.page - 1) * ROWS

    for index = 1, ROWS do
        local row = f.rows[index]
        local member = visible[first + index]

        if member then
            self:ClearRow(row)
            row.member = member
            row.dot:Show()

            local red, green, blue = ClassColor(member.class)
            local dim = member.online and 1 or 0.45

            row.dot:SetVertexColor(member.online and 0.3 or 0.35,
                member.online and 0.85 or 0.35, member.online and 0.4 or 0.4, 1)

            row.cells.name:SetText(member.name)
            row.cells.name:SetTextColor(red * dim, green * dim, blue * dim)

            row.cells.level:SetText(member.level)
            row.cells.ilvl:SetText(member.ilvl or "-")
            row.cells.rank:SetText(member.rank or "")
            row.cells.zone:SetText(member.zone or "")

            for key, cell in pairs(row.cells) do
                if key ~= "name" and key ~= "ilvl" then
                    cell:SetTextColor(S.TEXT_NORMAL[1] * dim, S.TEXT_NORMAL[2] * dim, S.TEXT_NORMAL[3] * dim)
                end
            end

            local ilvlRed, ilvlGreen, ilvlBlue = ItemLevelColor(member.ilvl)
            row.cells.ilvl:SetTextColor(ilvlRed * dim, ilvlGreen * dim, ilvlBlue * dim)

            local token = ClassToken(member.class)
            local coords = token and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
            if coords then
                row.classIcon:SetTexture(CLASS_ICON_TEXTURE)
                row.classIcon:SetTexCoord(unpack(coords))
                row.classIcon:SetVertexColor(dim, dim, dim, member.online and 1 or 0.7)
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end

            if self.selected == member.name then
                row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
            else
                row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                    index % 2 == 0 and 0.35 or 0.18)
            end

            row:Show()
        else
            self:ClearRow(row)
            row.classIcon:Hide()
            row:Hide()
        end
    end

    f.pageLabel:SetText(string.format(L["Стр. %d из %d"], self.page, pages))
    self:UpdateActions()
end

function GuildPanel:ShowApplicants()
    local f = self.frame
    local S = NS.Styling

    local applicants = self:CollectApplicants()
    local pages = math.max(1, math.ceil(#applicants / ROWS))
    self.page = math.min(math.max(1, self.page or 1), pages)
    local first = (self.page - 1) * ROWS

    for index = 1, ROWS do
        local row = f.rows[index]
        local applicant = applicants[first + index]

        if applicant then
            self:ClearRow(row)
            row.applicant = applicant
            row.dot:Show()

            local red, green, blue = ClassColor(applicant.class)
            local dim = applicant.online and 1 or 0.55

            row.dot:SetVertexColor(applicant.online and 0.3 or 0.35,
                applicant.online and 0.85 or 0.35, applicant.online and 0.4 or 0.4, 1)

            local coords = applicant.class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[applicant.class]
            if coords then
                row.classIcon:SetTexture(CLASS_ICON_TEXTURE)
                row.classIcon:SetTexCoord(unpack(coords))
                row.classIcon:SetVertexColor(dim, dim, dim, 1)
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end

            row.cells.name:SetText(applicant.name)
            row.cells.name:SetTextColor(red * dim, green * dim, blue * dim)
            row.cells.level:SetText(applicant.level)
            row.cells.ilvl:SetText(applicant.roles)
            row.cells.rank:SetText(applicant.comment)
            row.cells.zone:SetText(applicant.inviteSent and L["приглашён"] or applicant.timeLeft)

            for key, cell in pairs(row.cells) do
                if key ~= "name" then
                    cell:SetTextColor(S.TEXT_NORMAL[1] * dim, S.TEXT_NORMAL[2] * dim, S.TEXT_NORMAL[3] * dim)
                end
            end

            if self.selectedApplicant == applicant.name then
                row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
            else
                row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                    index % 2 == 0 and 0.35 or 0.18)
            end

            row:Show()
        else
            self:ClearRow(row)
            row.classIcon:Hide()
            row:Hide()
        end
    end

    f.pageLabel:SetText(string.format(L["Стр. %d из %d"], self.page, pages))
    self:UpdateApplicantActions()
end

function GuildPanel:RowIcon(row, texture)
    if not texture then
        row.classIcon:Hide()
        return
    end
    row.classIcon:SetTexture(texture)
    row.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.classIcon:SetVertexColor(1, 1, 1, 1)
    row.classIcon:Show()
end

function GuildPanel:ClearRow(row)
    row.member = nil
    row.applicant = nil
    row.standing = nil
    row.perk = nil
    row.reward = nil
    row.rankInfo = nil
    row.dot:Hide()
end

function GuildPanel:CollectPerks()
    local perks = {}
    local total = GetNumGuildPerks and GetNumGuildPerks() or 0

    for index = 1, total do
        local name, spellID, icon, level = GetGuildPerkInfo(index)
        if name then
            perks[#perks + 1] = { name = name, spellID = spellID, icon = icon, level = level or 0 }
        end
    end

    table.sort(perks, function(left, right)
        if left.level == right.level then return left.name < right.name end
        return left.level < right.level
    end)

    return perks
end

function GuildPanel:CollectRewards()
    local rewards = {}
    local total = GetNumGuildRewards and GetNumGuildRewards() or 0

    for index = 1, total do
        local _, itemID, itemName, icon, standing, cost = GetGuildRewardInfo(index)
        if itemID then
            rewards[#rewards + 1] = {
                itemID = itemID,
                name = itemName or ("#" .. itemID),
                icon = icon,
                standing = standing or 0,
                cost = cost or 0,
            }
        end
    end

    return rewards
end

function GuildPanel:ShowList(entries, fill)
    local f = self.frame
    local S = NS.Styling

    local pages = math.max(1, math.ceil(#entries / ROWS))
    self.page = math.min(math.max(1, self.page or 1), pages)
    local first = (self.page - 1) * ROWS

    for index = 1, ROWS do
        local row = f.rows[index]
        local entry = entries[first + index]

        self:ClearRow(row)

        if entry then
            fill(row, entry)
            row.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3],
                index % 2 == 0 and 0.35 or 0.18)
            row:Show()
        else
            row.classIcon:Hide()
            row:Hide()
        end
    end

    f.pageLabel:SetText(string.format(L["Стр. %d из %d"], self.page, pages))
end

function GuildPanel:ShowPerks()
    local S = NS.Styling
    local level = GetGuildLevel and GetGuildLevel() or 0

    self:ShowList(self:CollectPerks(), function(row, perk)
        row.perk = perk
        self:RowIcon(row, perk.icon)

        local reached = perk.level <= level
        local dim = reached and 1 or 0.5

        row.cells.name:SetText(perk.name)
        row.cells.name:SetTextColor(S.TEXT_BRIGHT[1] * dim, S.TEXT_BRIGHT[2] * dim, S.TEXT_BRIGHT[3] * dim)
        row.cells.level:SetText(perk.level)
        row.cells.ilvl:SetText("")
        row.cells.rank:SetText(reached and L["открыта"] or string.format(L["%d-й уровень"], perk.level))
        row.cells.zone:SetText("")

        row.cells.level:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        row.cells.rank:SetTextColor(reached and S.ACCENT[1] or S.GOLD[1],
            reached and S.ACCENT[2] or S.GOLD[2], reached and S.ACCENT[3] or S.GOLD[3])
    end)
end

function GuildPanel:ShowRewards()
    local S = NS.Styling
    local standing = GetGuildReputation and GetGuildReputation() or 0

    self:ShowList(self:CollectRewards(), function(row, reward)
        row.reward = reward
        self:RowIcon(row, reward.icon)

        local available = reward.standing <= standing
        local dim = available and 1 or 0.55

        row.cells.name:SetText(reward.name)
        row.cells.name:SetTextColor(S.TEXT_BRIGHT[1] * dim, S.TEXT_BRIGHT[2] * dim, S.TEXT_BRIGHT[3] * dim)
        row.cells.level:SetText("")
        row.cells.ilvl:SetText(reward.cost > 0 and reward.cost or "")
        row.cells.rank:SetText(STANDING_NAMES[reward.standing] and L[STANDING_NAMES[reward.standing]] or reward.standing)
        row.cells.zone:SetText("")

        row.cells.ilvl:SetTextColor(S.GOLD[1] * dim, S.GOLD[2] * dim, S.GOLD[3] * dim)
        row.cells.rank:SetTextColor(available and S.ACCENT[1] or 0.85,
            available and S.ACCENT[2] or 0.45, available and S.ACCENT[3] or 0.45)

        if self.selectedReward == reward.itemID then
            row.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
        end
    end)

    self:UpdateRewardActions()
end

function GuildPanel:EventText()
    local lines = {}
    local total = GetNumGuildEvents and GetNumGuildEvents() or 0

    for index = total, 1, -1 do
        local kind, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(index)
        player1 = player1 or UNKNOWN
        player2 = player2 or UNKNOWN

        local message
        if kind == "invite" then
            message = string.format(GUILDEVENT_TYPE_INVITE, player1, player2)
        elseif kind == "join" then
            message = string.format(GUILDEVENT_TYPE_JOIN, player1)
        elseif kind == "promote" then
            message = string.format(GUILDEVENT_TYPE_PROMOTE, player1, player2, rank or "")
        elseif kind == "demote" then
            message = string.format(GUILDEVENT_TYPE_DEMOTE, player1, player2, rank or "")
        elseif kind == "remove" then
            message = string.format(GUILDEVENT_TYPE_REMOVE, player1, player2)
        elseif kind == "quit" then
            message = string.format(GUILDEVENT_TYPE_QUIT, player1)
        end

        if message then
            lines[#lines + 1] = string.format("|cff8a8a94%02d.%02d %02d:00|r  %s",
                day or 0, month or 0, hour or 0, message)
        end
    end

    if #lines == 0 then return L["журнал пуст"] end
    return table.concat(lines, string.char(10))
end

function GuildPanel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self:RequestRoster()
    self:RequestApplicants()
    self:Update()
    self.frame:Show()
end

function GuildPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function GuildPanel:Hide()
    if self.frame then self.frame:Hide() end
end

NS.GuildPanel = GuildPanel
