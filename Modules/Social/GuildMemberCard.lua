local addonName, NS = ...
local L = NS.L

local Card = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local CARD_W = 232
local NORM_H = 236
local OFFICER_H = 304

local function Label(parent, size, color, bold)
    local S = NS.Styling
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(NS.FONT, NS.FS(size or 11), bold and "OUTLINE" or "")
    local tint = color or S.TEXT_DIM
    font:SetTextColor(tint[1], tint[2], tint[3])
    font:SetJustifyH("LEFT")
    return font
end

local function SetEnabled(button, enabled)
    button:EnableMouse(enabled and true or false)
    button:SetAlpha(enabled and 1 or 0.35)
end

local function ClassColor(class)
    if NS.GuildPanel and NS.GuildPanel.ClassColorOf then
        return NS.GuildPanel:ClassColorOf(class)
    end
    return 0.85, 0.85, 0.88
end

function Card:CreateNote(parent, officer)
    local S = NS.Styling

    local plate = CreateFrame("Button", nil, parent)
    plate:SetSize(CARD_W - 28, 40)
    plate:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    plate:SetBackdropColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.85))
    plate:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local text = plate:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(11), "")
    text:SetPoint("TOPLEFT", plate, "TOPLEFT", 6, -5)
    text:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", -6, 5)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    plate.text = text

    local box = CreateFrame("EditBox", nil, plate)
    box:SetPoint("TOPLEFT", plate, "TOPLEFT", 5, -4)
    box:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", -5, 4)
    box:SetAutoFocus(false)
    box:SetMultiLine(true)
    box:SetMaxLetters(31)
    box:SetFont(NS.FONT, NS.FS(11), "")
    box:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    box:Hide()
    plate.box = box

    local function Commit(save)
        if plate.committing then return end
        plate.committing = true

        local value = box:GetText() or ""
        box:Hide()
        text:Show()
        plate:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

        if save then
            Card:SaveNote(officer, value)
        else
            Card:Refill()
        end

        plate.committing = nil
    end

    plate:SetScript("OnClick", function(self)
        if not self.editable then return end
        text:Hide()
        box:SetText(self.value or "")
        box:Show()
        box:SetFocus()
        box:HighlightText()
        plate:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    end)

    box:SetScript("OnEnterPressed", function() Commit(true) end)
    box:SetScript("OnEscapePressed", function() Commit(false) end)
    box:SetScript("OnEditFocusLost", function() Commit(false) end)

    function plate:SetNote(value, editable, placeholder)
        local S2 = NS.Styling
        self.value = value or ""
        self.editable = editable and true or false

        if self.value == "" and editable then
            self.text:SetText(placeholder)
            self.text:SetTextColor(S2.TEXT_DIM[1], S2.TEXT_DIM[2], S2.TEXT_DIM[3])
        else
            self.text:SetText(self.value)
            if editable then
                self.text:SetTextColor(S2.TEXT_BRIGHT[1], S2.TEXT_BRIGHT[2], S2.TEXT_BRIGHT[3])
            else
                self.text:SetTextColor(0.65, 0.65, 0.65)
            end
        end
    end

    return plate
end

function Card:Create(parent)
    if self.frame then return self.frame end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_GuildMemberCard", parent)
    f:SetSize(CARD_W, NORM_H)
    f:SetPoint("TOPLEFT", parent, "TOPRIGHT", 56, -28)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(parent:GetFrameLevel() + 20)
    f:EnableMouse(true)

    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.98))
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 5, 0.45)
    S.CreateGradientTopBorder(f)

    local close = NS.Widgets.CreateCloseButton(f, 16, function() Card:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local name = Label(f, 13, S.TEXT_BRIGHT, true)
    name:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
    f.name = name

    local level = Label(f, 11, S.TEXT_DIM)
    level:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    f.level = level

    local zoneLabel = Label(f, 11, S.ACCENT_GLOW)
    zoneLabel:SetPoint("TOPLEFT", level, "BOTTOMLEFT", 0, -12)
    zoneLabel:SetText(ZONE_COLON or L["Зона:"])

    local zone = Label(f, 11, S.TEXT_BRIGHT)
    zone:SetPoint("LEFT", zoneLabel, "RIGHT", 4, 0)
    zone:SetPoint("RIGHT", f, "RIGHT", -14, 0)
    zone:SetJustifyH("LEFT")
    f.zone = zone

    local rankLabel = Label(f, 11, S.ACCENT_GLOW)
    rankLabel:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", 0, -8)
    rankLabel:SetText(RANK_COLON or L["Звание:"])
    f.rankLabel = rankLabel

    local rank = Label(f, 11, S.TEXT_BRIGHT)
    rank:SetPoint("LEFT", rankLabel, "RIGHT", 4, 0)
    f.rank = rank

    local rankDrop = NS.Widgets.CreateThemedDropdown(f, 118, function(value)
        Card:PickRank(value)
    end)
    rankDrop:SetPoint("LEFT", rankLabel, "RIGHT", 4, 0)
    rankDrop:Hide()
    f.rankDrop = rankDrop

    local onlineLabel = Label(f, 11, S.ACCENT_GLOW)
    onlineLabel:SetPoint("TOPLEFT", rankLabel, "BOTTOMLEFT", 0, -8)
    f.onlineLabel = onlineLabel

    local online = Label(f, 11, S.TEXT_BRIGHT)
    online:SetPoint("LEFT", onlineLabel, "RIGHT", 4, 0)
    f.online = online

    local noteLabel = Label(f, 11, S.ACCENT_GLOW)
    noteLabel:SetPoint("TOPLEFT", onlineLabel, "BOTTOMLEFT", 0, -8)
    noteLabel:SetText(NOTE_COLON or L["Заметка:"])

    local note = self:CreateNote(f, false)
    note:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -4)
    f.note = note

    local officerLabel = Label(f, 11, S.ACCENT_GLOW)
    officerLabel:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -8)
    officerLabel:SetText(OFFICER_NOTE_COLON or L["Заметка для офицеров:"])
    f.officerLabel = officerLabel

    local officer = self:CreateNote(f, true)
    officer:SetPoint("TOPLEFT", officerLabel, "BOTTOMLEFT", 0, -4)
    f.officer = officer

    local remove = NS.Widgets.CreateThemedButton(f, REMOVE or L["Исключить"], 96, 22, function()
        local target = Card.member
        if not target then return end

        NS.Widgets.ShowConfirm(string.format(L["Исключить %s из гильдии? Отменить это нельзя."], target),
            REMOVE or L["Исключить"], function()
                if NS.GuildAdmin then NS.GuildAdmin:Kick(target) end
                Card:Hide()
                if NS.GuildPanel then NS.After(2, function() NS.GuildPanel:Update() end) end
            end)
    end, { 0.85, 0.3, 0.3 })
    remove:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    f.remove = remove

    local invite = NS.Widgets.CreateThemedButton(f, GROUP_INVITE or L["Пригласить"], 96, 22, function()
        if Card.member and InviteUnit then InviteUnit(Card.member) end
    end)
    invite:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    f.invite = invite

    f:Hide()
    self.frame = f
    return f
end

function Card:PickRank(listRank)
    if not self.member or not listRank or not NS.GuildAdmin then return end

    NS.GuildAdmin:ChangeRank(self.member, listRank - 1)
    NS.After(2, function()
        if NS.GuildPanel then NS.GuildPanel:Update() end
    end)
end

function Card:RankEntries(rankIndex)
    local entries = {}
    if not GuildControlGetNumRanks then return entries end

    local numRanks = GuildControlGetNumRanks() or 0
    local _, _, myRankIndex = GetGuildInfo("player")
    myRankIndex = (myRankIndex or 0) + 1

    local memberRank = rankIndex + 1
    local highest = myRankIndex + 1
    local lowest = numRanks

    if not (CanGuildPromote and CanGuildPromote()) then highest = memberRank end
    if not (CanGuildDemote and CanGuildDemote()) then lowest = memberRank end

    for listRank = highest, lowest do
        entries[#entries + 1] = { value = listRank, label = GuildControlGetRankName(listRank) or "?" }
    end

    return entries
end

function Card:CanChangeRank(rankIndex)
    local _, _, myRankIndex = GetGuildInfo("player")
    myRankIndex = myRankIndex or 0
    local maxRankIndex = (GuildControlGetNumRanks and GuildControlGetNumRanks() or 1) - 1

    local canPromote = CanGuildPromote and CanGuildPromote() and rankIndex > myRankIndex + 1
    local canDemote = CanGuildDemote and CanGuildDemote()
        and rankIndex < maxRankIndex and rankIndex > myRankIndex

    return canPromote or canDemote
end

function Card:SaveNote(officer, text)
    if not self.member or not NS.GuildAdmin then return end

    NS.GuildAdmin:SetNote(self.member, text, officer)
    NS.After(1, function()
        if NS.GuildPanel then NS.GuildPanel:Update() end
    end)
end

function Card:Refill()
    if not self.member or not NS.GuildPanel then return end

    for _, member in ipairs(NS.GuildPanel:Collect()) do
        if member.name == self.member then
            self:Show(self.frame:GetParent(), member)
            return
        end
    end
end

function Card:Show(parent, member)
    if not member then return end
    self:Create(parent)

    local f = self.frame
    local S = NS.Styling
    local wasShown = f:IsShown()

    self.member = member.name

    local red, green, blue = ClassColor(member.class)
    f.name:SetText(member.name)
    f.name:SetTextColor(red, green, blue)

    if FRIENDS_LEVEL_TEMPLATE_2 then
        f.level:SetFormattedText(FRIENDS_LEVEL_TEMPLATE_2, member.level or 0, member.class or "")
    else
        f.level:SetText(string.format("%s %d", member.class or "", member.level or 0))
    end

    f.zone:SetText(member.zone or "")

    if self:CanChangeRank(member.rankIndex or 0) then
        f.rank:Hide()
        f.rankDrop:SetEntries(self:RankEntries(member.rankIndex or 0))
        f.rankDrop:SetValue((member.rankIndex or 0) + 1)
        f.rankDrop:Show()
    else
        f.rankDrop:Hide()
        f.rank:SetText(member.rank or "")
        f.rank:Show()
    end

    if member.online then
        f.onlineLabel:SetText(L["Статус:"])
        f.online:SetText(GUILD_ONLINE_LABEL or L["В сети"])
        f.online:SetTextColor(0.35, 0.85, 0.45)
    else
        f.onlineLabel:SetText(LAST_ONLINE_COLON or L["Последний раз в игре:"])
        f.online:SetText(member.lastOnline or "")
        f.online:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end

    local canEditPublic = not CanEditPublicNote or CanEditPublicNote()
    f.note:SetNote(member.note or "", canEditPublic, GUILD_NOTE_EDITLABEL or "")

    local canViewOfficer = not CanViewOfficerNote or CanViewOfficerNote()
    f.officerLabel:SetShown(canViewOfficer and true or false)
    f.officer:SetShown(canViewOfficer and true or false)

    if canViewOfficer then
        local canEditOfficer = CanEditOfficerNote and CanEditOfficerNote()
        f.officer:SetNote(member.officerNote or "", canEditOfficer, GUILD_OFFICERNOTE_EDITLABEL or "")
        f:SetHeight(OFFICER_H)
    else
        f:SetHeight(NORM_H)
    end

    local _, _, myRankIndex = GetGuildInfo("player")
    myRankIndex = myRankIndex or 0
    local canRemove = CanGuildRemove and CanGuildRemove()
        and (member.rankIndex or 0) >= 1 and (member.rankIndex or 0) > myRankIndex
    SetEnabled(f.remove, canRemove)

    local canInvite = member.online and member.name ~= UnitName("player")
    SetEnabled(f.invite, canInvite)

    f:Show()
    self:Reposition(parent)
    if not wasShown then S.FadeIn(f, 0.12) end
end

function Card:Reposition(parent)
    local f = self.frame
    if not f or not parent then return end

    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", parent, "TOPRIGHT", 56, -28)

    local screen = UIParent:GetRight() or 0
    if (f:GetRight() or 0) <= screen then return end

    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", parent, "TOPLEFT", -8, -28)

    if (f:GetLeft() or 0) >= (UIParent:GetLeft() or 0) then return end

    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, -112)
end

function Card:Hide()
    if self.frame then
        if self.frame.note then self.frame.note.box:ClearFocus() end
        if self.frame.officer then self.frame.officer.box:ClearFocus() end
        self.frame:Hide()
    end
    self.member = nil
end

function Card:Refresh(member)
    if not self.frame or not self.frame:IsShown() then return end
    if not member or member.name ~= self.member then return end
    if self.frame.note.box:HasFocus() or self.frame.officer.box:HasFocus() then return end

    self:Show(self.frame:GetParent(), member)
end

NS.GuildMemberCard = Card
