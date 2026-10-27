local addonName, NS = ...
local L = NS.L

local View = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"

local MUTE_ROWS = 8
local CLEAN_ROWS = 6
local RANK_COLUMNS = 3

local PAGES = {
    { key = "players",  label = "Управление игроками" },
    { key = "mutes",    label = "Активные муты" },
    { key = "settings", label = "Настройки" },
    { key = "cleanup",  label = "Очистка" },
}

local function Label(parent, text, size, color)
    local S = NS.Styling
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(NS.FONT, NS.FS(size or 11), size and size > 11 and "OUTLINE" or "")
    local tint = color or S.TEXT_DIM
    font:SetTextColor(tint[1], tint[2], tint[3])
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end

local function Plate(parent, height)
    local S = NS.Styling
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(height)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.75))
    frame:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    return frame
end

local function RankEntries()
    local ranks, num = NS.GuildAdmin:Ranks()
    local entries = {}

    for index = 0, num - 1 do
        entries[#entries + 1] = { value = index, label = index .. " - " .. (ranks[index] or "?") }
    end

    return entries
end

function View:CreatePlayers(parent)
    local S = NS.Styling
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)

    local searchLabel = Label(page, L["Поиск игрока:"], 11, S.ACCENT_GLOW)
    searchLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local search = NS.Widgets.CreateThemedEditBox(page, 220, 22, 24)
    search:SetPoint("TOPLEFT", page, "TOPLEFT", 110, 4)
    page.search = search

    local find = NS.Widgets.CreateThemedButton(page, L["Поиск"], 90, 22, function()
        View:Search(strtrim(search:GetText() or ""))
    end)
    find:SetPoint("TOPLEFT", page, "TOPLEFT", 345, 4)

    search:SetScript("OnEnterPressed", function(box)
        box:ClearFocus()
        View:Search(strtrim(box:GetText() or ""))
    end)

    local info = Plate(page, 130)
    info:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -32)
    info:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -32)

    local infoTitle = Label(info, L["Информация об игроке"], 12, S.ACCENT_GLOW)
    infoTitle:SetPoint("TOP", info, "TOP", 0, -8)
    infoTitle:SetJustifyH("CENTER")

    local infoText = Label(info, L["Введите ник игрока и нажмите Поиск"], 11, S.TEXT_NORMAL)
    infoText:SetPoint("TOPLEFT", info, "TOPLEFT", 12, -30)
    infoText:SetPoint("TOPRIGHT", info, "TOPRIGHT", -12, -30)
    page.infoText = infoText

    local notesTitle = Label(page, L["Управление заметками:"], 12, S.ACCENT_GLOW)
    notesTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -172)

    local publicLabel = Label(page, L["Публичная заметка:"], 11)
    publicLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -200)

    local publicNote = NS.Widgets.CreateThemedEditBox(page, 400, 22, 31)
    publicNote:SetPoint("TOPLEFT", page, "TOPLEFT", 150, -196)
    page.publicNote = publicNote

    local savePublic = NS.Widgets.CreateThemedButton(page, L["Сохранить"], 100, 22, function()
        View:SaveNote(false)
    end)
    savePublic:SetPoint("TOPLEFT", page, "TOPLEFT", 562, -196)

    local officerLabel = Label(page, L["Офицерская заметка:"], 11)
    officerLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -230)

    local officerNote = NS.Widgets.CreateThemedEditBox(page, 400, 22, 31)
    officerNote:SetPoint("TOPLEFT", page, "TOPLEFT", 150, -226)
    page.officerNote = officerNote

    local saveOfficer = NS.Widgets.CreateThemedButton(page, L["Сохранить"], 100, 22, function()
        View:SaveNote(true)
    end)
    saveOfficer:SetPoint("TOPLEFT", page, "TOPLEFT", 562, -226)

    local rankTitle = Label(page, L["Изменение ранга:"], 12, S.ACCENT_GLOW)
    rankTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -262)

    local rankLabel = Label(page, L["Новый ранг:"], 11)
    rankLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -290)

    local rankDrop = NS.Widgets.CreateThemedDropdown(page, 200, nil)
    rankDrop:SetPoint("TOPLEFT", page, "TOPLEFT", 150, -286)
    page.rankDrop = rankDrop

    local applyRank = NS.Widgets.CreateThemedButton(page, L["Изменить ранг"], 120, 22, function()
        View:ApplyRank()
    end)
    applyRank:SetPoint("TOPLEFT", page, "TOPLEFT", 365, -286)

    local muteTitle = Label(page, L["Система мута:"], 12, S.ACCENT_GLOW)
    muteTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -322)

    local timeLabel = Label(page, L["Время (минуты):"], 11)
    timeLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -350)

    local timeBox = NS.Widgets.CreateThemedEditBox(page, 60, 22, 5)
    timeBox:SetPoint("TOPLEFT", page, "TOPLEFT", 110, -346)
    timeBox:SetNumeric(true)
    page.timeBox = timeBox

    local reasonLabel = Label(page, L["Причина:"], 11)
    reasonLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 185, -350)

    local reasonBox = NS.Widgets.CreateThemedEditBox(page, 250, 22, 40)
    reasonBox:SetPoint("TOPLEFT", page, "TOPLEFT", 245, -346)
    page.reasonBox = reasonBox

    local mute = NS.Widgets.CreateThemedButton(page, L["Замутить"], 110, 22, function()
        View:Mute()
    end)
    mute:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -380)

    local unmute = NS.Widgets.CreateThemedButton(page, L["Размутить"], 110, 22, function()
        View:Unmute()
    end)
    unmute:SetPoint("TOPLEFT", page, "TOPLEFT", 118, -380)

    local kick = NS.Widgets.CreateThemedButton(page, L["Исключить"], 110, 22, function()
        View:Kick()
    end, { 0.85, 0.3, 0.3 })
    kick:SetPoint("TOPLEFT", page, "TOPLEFT", 236, -380)

    return page
end

function View:CreateMutes(parent)
    local S = NS.Styling
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)

    local title = Label(page, L["Активные муты"], 12, S.ACCENT_GLOW)
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local empty = Label(page, L["Активных мутов нет"], 12, S.GOLD)
    empty:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -30)
    page.empty = empty

    page.rows = {}
    for index = 1, MUTE_ROWS do
        local row = CreateFrame("Frame", nil, page)
        row:SetHeight(38)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -26 - (index - 1) * 42)
        row:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -26 - (index - 1) * 42)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.35 or 0.18)

        local name = Label(row, "", 12, S.TEXT_BRIGHT)
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -5)
        row.name = name

        local details = Label(row, "", 11, S.TEXT_DIM)
        details:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -21)
        row.details = details

        local remaining = Label(row, "", 12, S.GOLD)
        remaining:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        remaining:SetJustifyH("RIGHT")
        row.remaining = remaining

        local release = NS.Widgets.CreateThemedButton(row, L["Размутить"], 90, 20, nil)
        release:SetPoint("RIGHT", row, "RIGHT", -90, 0)
        release:SetScript("OnClick", function(self)
            if self.target then NS.GuildAdmin:Unmute(self.target) end
            View:Update()
        end)
        row.release = release

        row:Hide()
        page.rows[index] = row
    end

    local refresh = NS.Widgets.CreateThemedButton(page, L["Обновить"], 110, 22, function()
        if GuildRoster then GuildRoster() end
        View:Update()
    end)
    refresh:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)

    return page
end

function View:CreateSettings(parent)
    local S = NS.Styling
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)

    local rankLabel = Label(page, L["Ранг для мута:"], 11, S.ACCENT_GLOW)
    rankLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local rankDrop = NS.Widgets.CreateThemedDropdown(page, 200, function(value)
        NS.GuildAdmin:Settings().muteRank = value
        View:Update()
    end)
    rankDrop:SetPoint("TOPLEFT", page, "TOPLEFT", 150, 4)
    page.rankDrop = rankDrop

    local officer = NS.Widgets.CreateThemedCheckbox(page, L["Использовать офицерские заметки"], true, function(value)
        NS.GuildAdmin:Settings().useOfficerNotes = value
        View:Update()
    end)
    officer:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -44)
    page.officer = officer

    local notify = NS.Widgets.CreateThemedCheckbox(page, L["Показывать уведомления"], true, function(value)
        NS.GuildAdmin:Settings().notify = value
        View:Update()
    end)
    notify:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -74)
    page.notify = notify

    local daysLabel = Label(page, L["Дней для очистки:"], 11)
    daysLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -110)

    local days = NS.Widgets.CreateThemedEditBox(page, 60, 22, 4)
    days:SetPoint("TOPLEFT", page, "TOPLEFT", 150, -106)
    days:SetNumeric(true)
    days:SetScript("OnTextChanged", function(box)
        local value = tonumber(box:GetText())
        if value and value > 0 then NS.GuildAdmin:Settings().cleanupDays = value end
    end)
    page.days = days

    local statsTitle = Label(page, L["Статистика:"], 12, S.ACCENT_GLOW)
    statsTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)

    local stats = Label(page, "", 11, S.TEXT_NORMAL)
    stats:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -174)
    page.stats = stats

    local refresh = NS.Widgets.CreateThemedButton(page, L["Обновить статистику"], 160, 22, function()
        if GuildRoster then GuildRoster() end
        View:Update()
    end)
    refresh:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)

    return page
end

function View:CreateCleanup(parent)
    local S = NS.Styling
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)

    local daysLabel = Label(page, L["Дней неактивности:"], 11)
    daysLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local days = NS.Widgets.CreateThemedEditBox(page, 60, 22, 4)
    days:SetPoint("TOPLEFT", page, "TOPLEFT", 140, 4)
    days:SetNumeric(true)
    page.days = days

    local levelLabel = Label(page, L["Макс. уровень для кика:"], 11)
    levelLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 230, 0)

    local level = NS.Widgets.CreateThemedEditBox(page, 50, 22, 3)
    level:SetPoint("TOPLEFT", page, "TOPLEFT", 390, 4)
    level:SetNumeric(true)
    page.level = level

    local excludeTitle = Label(page, L["Исключить из поиска:"], 12, S.ACCENT_GLOW)
    excludeTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -36)

    local excludePublic = NS.Widgets.CreateThemedCheckbox(page, L["Игроков с публичной заметкой"], false, function(value)
        NS.GuildAdmin:Settings().excludePublicNote = value
    end)
    excludePublic:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -64)
    page.excludePublic = excludePublic

    local excludeOfficer = NS.Widgets.CreateThemedCheckbox(page, L["Игроков с офицерской заметкой"], false, function(value)
        NS.GuildAdmin:Settings().excludeOfficerNote = value
    end)
    excludeOfficer:SetPoint("TOPLEFT", page, "TOPLEFT", 300, -64)
    page.excludeOfficer = excludeOfficer

    local ranksTitle = Label(page, L["Ранги для проверки:"], 12, S.ACCENT_GLOW)
    ranksTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -96)

    page.rankChecks = {}

    local search = NS.Widgets.CreateThemedButton(page, L["Найти неактивных"], 150, 22, function()
        View:FindInactive()
    end)
    search:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -226)
    page.search = search

    page.rows = {}
    for index = 1, CLEAN_ROWS do
        local row = CreateFrame("Frame", nil, page)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -258 - (index - 1) * 24)
        row:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -258 - (index - 1) * 24)

        local plate = row:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture(WHITE)
        plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.35 or 0.18)

        local check = NS.Widgets.CreateThemedCheckbox(row, "", false, function(value)
            local target = row.target
            if target then View.selected[target] = value or nil end
        end)
        check:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.check = check

        local text = Label(row, "", 11, S.TEXT_NORMAL)
        text:SetPoint("LEFT", row, "LEFT", 32, 0)
        row.text = text

        local offline = Label(row, "", 11, S.GOLD)
        offline:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        offline:SetJustifyH("RIGHT")
        row.offline = offline

        row:Hide()
        page.rows[index] = row
    end

    local prev = NS.Widgets.CreateThemedButton(page, "<", 30, 20, function()
        View.cleanPage = math.max(1, (View.cleanPage or 1) - 1)
        View:ShowCandidates()
    end)
    prev:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -76, 0)
    page.prev = prev

    local nextPage = NS.Widgets.CreateThemedButton(page, ">", 30, 20, function()
        View.cleanPage = (View.cleanPage or 1) + 1
        View:ShowCandidates()
    end)
    nextPage:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -40, 0)
    page.nextPage = nextPage

    local remove = NS.Widgets.CreateThemedButton(page, L["Удалить отмеченных"], 160, 22, function()
        View:RemoveSelected()
    end, { 0.85, 0.3, 0.3 })
    remove:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    page.remove = remove

    local status = Label(page, L["Нажмите Найти неактивных для поиска"], 11, S.GOLD)
    status:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 170, 6)
    page.status = status

    return page
end

function View:RefreshRankChecks()
    local S = NS.Styling
    local page = self.pages.cleanup
    local ranks, num = NS.GuildAdmin:Ranks()

    for index = 0, math.max(num - 1, 0) do
        local check = page.rankChecks[index]

        if not check then
            check = NS.Widgets.CreateThemedCheckbox(page, "", true, nil)
            page.rankChecks[index] = check
        end

        local column = index % RANK_COLUMNS
        local row = math.floor(index / RANK_COLUMNS)
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", page, "TOPLEFT", 4 + column * 200, -124 - row * 24)
        check.text:SetText(index .. " - " .. (ranks[index] or "?"))
        check.rankIndex = index
        check:Show()
    end

    for index = num, 20 do
        if page.rankChecks[index] then page.rankChecks[index]:Hide() end
    end
end

function View:SelectedRanks()
    local ranks = {}
    for index, check in pairs(self.pages.cleanup.rankChecks) do
        if check:IsShown() and check.checked then ranks[#ranks + 1] = index end
    end
    return ranks
end

function View:Create(parent)
    if self.frame then return self.frame end
    local S = NS.Styling

    local f = CreateFrame("Frame", nil, parent)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -92)
    f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 14)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -32)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    self.frame = f
    self.body = body
    self.selected = {}
    self.candidates = {}
    self.cleanPage = 1
    self.page = self.page or "players"

    self.pages = {
        players = self:CreatePlayers(body),
        mutes = self:CreateMutes(body),
        settings = self:CreateSettings(body),
        cleanup = self:CreateCleanup(body),
    }

    local picker = NS.Widgets.CreateOptionPicker(f, PAGES, self.page, function(key)
        View.page = key
        View:Update()
    end, 700)
    picker:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    self.picker = picker

    f:Hide()
    return f
end

function View:Search(name)
    if not name or name == "" then
        self.pages.players.infoText:SetText("|cFFFF5555" .. L["Введите ник игрока"] .. "|r")
        return
    end

    local member = NS.GuildAdmin:Find(name)
    if not member then
        self.current = nil
        self.pages.players.infoText:SetText("|cFFFF5555" ..
            string.format(L["Игрок %s не найден в гильдии"], name) .. "|r")
        return
    end

    self.current = member.name
    self:ShowPlayer(member)
end

function View:ShowPlayer(member)
    local page = self.pages.players
    local newline = string.char(10)

    local lines = {
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Игрок:"], member.name),
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s (%d)|r", L["Ранг:"], member.rank or "?", member.rankIndex),
        string.format("|cFFFFD100%s|r %s", L["Статус:"],
            member.online and ("|cFF44DD66" .. L["в сети"] .. "|r") or ("|cFFAA5555" .. L["не в сети"] .. "|r")),
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s, %d %s|r", L["Класс:"],
            member.class or "?", member.level or 0, L["ур."]),
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Зона:"], member.zone or "?"),
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Публичная заметка:"],
            member.note ~= "" and member.note or L["нет"]),
        string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Офицерская заметка:"],
            member.officerNote ~= "" and member.officerNote or L["нет"]),
    }

    local mute = NS.GuildAdmin:MuteOf(member.name)
    if mute then
        local remaining = math.max(0, (mute.expireTime or 0) - time())
        lines[#lines + 1] = ""
        lines[#lines + 1] = "|cFFFF5555" .. L["СТАТУС: ЗАМУЧЕН"] .. "|r"
        lines[#lines + 1] = string.format("|cFFFFD100%s|r |cFFFFFFFF%d:%02d|r", L["Осталось:"],
            math.floor(remaining / 60), remaining % 60)
        lines[#lines + 1] = string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Причина:"],
            mute.reason ~= "" and mute.reason or L["не указана"])
        lines[#lines + 1] = string.format("|cFFFFD100%s|r |cFFFFFFFF%s|r", L["Выдал:"], mute.mutedBy or "?")
    end

    page.infoText:SetText(table.concat(lines, newline))
    page.publicNote:SetText(member.note or "")
    page.officerNote:SetText(member.officerNote or "")
    page.rankDrop:SetEntries(RankEntries())
    page.rankDrop:SetValue(member.rankIndex)
end

function View:Current()
    if not self.current then
        NS.GuildAdmin:Notify(L["сначала найдите игрока"])
        return nil
    end
    return self.current
end

function View:SaveNote(officer)
    local name = self:Current()
    if not name then return end

    local page = self.pages.players
    local box = officer and page.officerNote or page.publicNote

    if NS.GuildAdmin:SetNote(name, box:GetText() or "", officer) then
        NS.GuildAdmin:Notify(officer and L["офицерская заметка обновлена"] or L["публичная заметка обновлена"])
        NS.After(1, function() View:Search(name) end)
    end
end

function View:ApplyRank()
    local name = self:Current()
    if not name then return end

    local target = self.pages.players.rankDrop:GetValue()
    if not target then return end

    if NS.GuildAdmin:ChangeRank(name, target) then
        NS.After(2, function() View:Search(name) end)
    end
end

function View:Mute()
    local name = self:Current()
    if not name then return end

    local page = self.pages.players
    local minutes = tonumber(page.timeBox:GetText())

    if not minutes or minutes <= 0 then
        NS.GuildAdmin:Notify(L["укажите время в минутах"])
        return
    end

    if NS.GuildAdmin:Mute(name, minutes, strtrim(page.reasonBox:GetText() or "")) then
        page.timeBox:SetText("")
        page.reasonBox:SetText("")
        NS.After(2, function() View:Search(name) end)
    end
end

function View:Unmute()
    local name = self:Current()
    if not name then return end

    if NS.GuildAdmin:Unmute(name) then
        NS.After(2, function() View:Search(name) end)
    end
end

function View:Kick()
    local name = self:Current()
    if not name then return end

    NS.Widgets.ShowConfirm(string.format(L["Исключить %s из гильдии? Отменить это нельзя."], name),
        L["Исключить"], function()
            NS.GuildAdmin:Kick(name)
            NS.After(2, function() View:Search(name) end)
        end)
end

function View:FindInactive()
    local page = self.pages.cleanup
    local settings = NS.GuildAdmin:Settings()

    local days = tonumber(page.days:GetText()) or settings.cleanupDays or 30
    local level = tonumber(page.level:GetText()) or settings.cleanupLevel or 80

    settings.cleanupDays = days
    settings.cleanupLevel = level

    if GuildRoster then GuildRoster() end

    self.selected = {}
    self.cleanPage = 1
    self.candidates = NS.GuildAdmin:FindInactive(days, level, self:SelectedRanks(),
        page.excludePublic.checked, page.excludeOfficer.checked)

    page.status:SetText(string.format(L["Найдено: %d (не в сети %d дн. и дольше, уровень до %d)"],
        #self.candidates, days, level))

    self:ShowCandidates()
end

function View:ShowCandidates()
    local page = self.pages.cleanup
    local pages = math.max(1, math.ceil(#self.candidates / CLEAN_ROWS))
    self.cleanPage = math.min(math.max(1, self.cleanPage or 1), pages)
    local first = (self.cleanPage - 1) * CLEAN_ROWS

    for index = 1, CLEAN_ROWS do
        local row = page.rows[index]
        local candidate = self.candidates[first + index]

        if candidate then
            row.target = candidate.name
            row.check:SetChecked(self.selected[candidate.name] and true or false)
            row.text:SetText(string.format("%s  |cFF888888%s, %d %s|r",
                candidate.name, candidate.rank or "?", candidate.level or 0, L["ур."]))
            row.offline:SetText(string.format(L["%d дн. не в сети"], candidate.daysOffline or 0))
            row:Show()
        else
            row.target = nil
            row:Hide()
        end
    end

    page.prev:SetShown(#self.candidates > CLEAN_ROWS)
    page.nextPage:SetShown(#self.candidates > CLEAN_ROWS)
end

function View:RemoveSelected()
    local names = {}
    for name in pairs(self.selected) do names[#names + 1] = name end

    if #names == 0 then
        NS.GuildAdmin:Notify(L["не отмечен ни один игрок"])
        return
    end

    local page = self.pages.cleanup

    NS.Widgets.ShowConfirm(string.format(L["Исключить отмеченных игроков (%d)? Отменить это нельзя."], #names),
        L["Исключить"], function()
            NS.GuildAdmin:RemoveBatch(names, function(index, total)
                page.status:SetText(string.format(L["Исключение... (%d/%d)"], index, total))
            end, function(removed, skipped)
                page.status:SetText(string.format(L["Исключено: %d, пропущено: %d"], removed, skipped))
                View.selected = {}
                View:FindInactive()
            end)
        end)
end

function View:UpdateMutes()
    local page = self.pages.mutes
    local mutes = NS.GuildAdmin:ActiveMutes()

    page.empty:SetShown(#mutes == 0)

    for index = 1, MUTE_ROWS do
        local row = page.rows[index]
        local mute = mutes[index]

        if mute then
            row.name:SetText(mute.name)
            row.details:SetText(string.format("%s %s  |  %s %s",
                L["Причина:"], mute.reason ~= "" and mute.reason or L["не указана"],
                L["Выдал:"], mute.mutedBy or "?"))
            row.remaining:SetText(string.format("%d:%02d",
                math.floor(mute.remaining / 60), mute.remaining % 60))
            row.release.target = mute.name
            row:Show()
        else
            row:Hide()
        end
    end
end

function View:UpdateSettings()
    local page = self.pages.settings
    local settings = NS.GuildAdmin:Settings()
    local ranks, num = NS.GuildAdmin:Ranks()

    page.rankDrop:SetEntries(RankEntries())
    page.rankDrop:SetValue(settings.muteRank or 4)
    page.officer:SetChecked(settings.useOfficerNotes)
    page.notify:SetChecked(settings.notify)

    if not page.days:HasFocus() then
        page.days:SetText(tostring(settings.cleanupDays or 30))
    end

    local members = NS.GuildAdmin:Members()
    local offline = 0
    for _, member in ipairs(members) do
        if not member.online then offline = offline + 1 end
    end

    local newline = string.char(10)
    local lines = {
        string.format("%s |cFFFFFFFF%d|r", L["Активных мутов:"], NS.GuildAdmin:CountMutes()),
        string.format("%s |cFFFFFFFF%d|r", L["Всего рангов:"], num),
        string.format("%s |cFFFFFFFF%d|r", L["Участников в гильдии:"], #members),
        string.format("%s |cFFFFFFFF%d|r", L["Не в сети:"], offline),
        string.format("%s |cFFFFFFFF%d|r", L["Дней для очистки:"], settings.cleanupDays or 30),
        string.format("%s |cFFFFFFFF%d - %s|r", L["Текущий ранг мута:"],
            settings.muteRank or 4, ranks[settings.muteRank or 4] or "?"),
        string.format("%s |cFFFFFFFF%s|r", L["Заметки:"],
            settings.useOfficerNotes and L["Вкл"] or L["Выкл"]),
        string.format("%s |cFFFFFFFF%s|r", L["Уведомления:"],
            settings.notify and L["Вкл"] or L["Выкл"]),
    }

    page.stats:SetText(table.concat(lines, newline))
end

function View:Update()
    if not self.frame then return end

    local settings = NS.GuildAdmin:Settings()

    for key, page in pairs(self.pages) do
        page:SetShown(key == self.page)
    end

    if self.picker then self.picker:Refresh(self.page) end

    if self.page == "players" then
        if self.current then
            local member = NS.GuildAdmin:Find(self.current)
            if member then self:ShowPlayer(member) end
        else
            self.pages.players.rankDrop:SetEntries(RankEntries())
        end
    elseif self.page == "mutes" then
        self:UpdateMutes()
    elseif self.page == "settings" then
        self:UpdateSettings()
    elseif self.page == "cleanup" then
        local page = self.pages.cleanup
        self:RefreshRankChecks()

        if not page.days:HasFocus() then
            page.days:SetText(tostring(settings.cleanupDays or 30))
        end
        if not page.level:HasFocus() then
            page.level:SetText(tostring(settings.cleanupLevel or 80))
        end

        page.excludePublic:SetChecked(settings.excludePublicNote)
        page.excludeOfficer:SetChecked(settings.excludeOfficerNote)
        self:ShowCandidates()
    end
end

function View:Show(parent)
    self:Create(parent)
    self.frame:Show()
    self:Update()
end

function View:Hide()
    if self.frame then self.frame:Hide() end
end

NS.GuildAdminView = View
