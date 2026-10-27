local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local CLASS_ICONS = "Interface\\WorldStateFrame\\Icons-Classes"
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"

local PANEL_W = 900
local PANEL_H = 620
local PAD = 18
local BODY_TOP = 112
local BODY_BOTTOM = 46
local BODY_H = PANEL_H - BODY_TOP - BODY_BOTTOM
local SCROLL_W = 8
local ROW_H = 28
local HEADER_H = 22
local CONTRACT_STRIP_H = 52
local DETAIL_H = 96
local LIST_H = BODY_H - 16 - HEADER_H - CONTRACT_STRIP_H - DETAIL_H - 12
local LIST_ROWS = math.max(1, math.floor(LIST_H / ROW_H))

NS.Densify("NarcissusSirus_HeadHunting", function(f)
    ROW_H = math.max(12, math.floor(28 * f + 0.5))
    LIST_ROWS = math.max(1, math.floor(LIST_H / ROW_H))
end)
local SEARCH_ROWS = 5
local SUGGEST_PRIMARY_W = 340
local SUGGEST_SECONDARY_W = PANEL_W - PAD * 2 - SUGGEST_PRIMARY_W - 24
local SUGGEST_SECONDARY_H = math.floor((BODY_H - 16 - 8) / 2)

local TAB_HOME = 1
local TAB_ALL = 2
local TAB_YOURS = 3

local CATEGORY_HEAD = 1
local CATEGORY_GUILD = 2

local SORT_NAME = 0
local SORT_HAS_GUILD_CONTRACTS = 1
local SORT_CLASS = 2
local SORT_FACTION = 3
local SORT_MONEY_PER_KILL = 4
local SORT_MONEY_BANK = 5
local SORT_ONLINE = 6

local FILTER_ALL_ONLINE = 0x01
local FILTER_ONLY_ONLINE = 0x02
local FILTER_ONLY_OFFLINE = 0x04
local FILTER_ALL_GUILD_CONTRACTS = 0x08
local FILTER_ONLY_GUILD_CONTRACTS = 0x10
local FILTER_ONLY_WITHOUT_GUILD_CONTRACTS = 0x20

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local COLUMNS = {
    [TAB_ALL] = {
        [CATEGORY_HEAD] = {
            { key = "player", text = "HEADHUNTING_COLUMN_PLAYER", fallback = "Игрок", width = 160, sort = SORT_NAME },
            { key = "wanted", text = "HEADHUNTING_COLUMN_GUILD_WANTED", fallback = "Розыск гильдии", width = 172, sort = SORT_HAS_GUILD_CONTRACTS },
            { key = "class", text = "HEADHUNTING_COLUMN_CLASS", fallback = "Класс", width = 56, sort = SORT_CLASS },
            { key = "faction", text = "HEADHUNTING_COLUMN_FACTION", fallback = "Фракция", width = 70, sort = SORT_FACTION },
            { key = "perKill", text = "HEADHUNTING_COLUMN_REWARD_PER_KILL", fallback = "За убийство", width = 90, sort = SORT_MONEY_PER_KILL },
            { key = "bank", text = "HEADHUNTING_COLUMN_TOTAL_REWARDS", fallback = "Общая награда", width = 120, sort = SORT_MONEY_BANK },
            { key = "status", text = "HEADHUNTING_COLUMN_STATUS", fallback = "Статус", width = 108, sort = SORT_ONLINE },
        },
        [CATEGORY_GUILD] = {
            { key = "guild", text = "HEADHUNTING_COLUMN_GUILD_NAME", fallback = "Гильдия", width = 418, sort = SORT_NAME },
            { key = "faction", text = "HEADHUNTING_COLUMN_FACTION", fallback = "Фракция", width = 100, sort = SORT_FACTION },
            { key = "perKill", text = "HEADHUNTING_COLUMN_REWARD_PER_KILL", fallback = "За убийство", width = 120, sort = SORT_MONEY_PER_KILL },
            { key = "bank", text = "HEADHUNTING_COLUMN_TOTAL_REWARDS", fallback = "Общая награда", width = 120, sort = SORT_MONEY_BANK },
        },
    },
    [TAB_YOURS] = {
        [CATEGORY_HEAD] = {
            { key = "player", text = "HEADHUNTING_COLUMN_PLAYER", fallback = "Игрок", width = 298 },
            { key = "class", text = "HEADHUNTING_COLUMN_CLASS", fallback = "Класс", width = 80 },
            { key = "faction", text = "HEADHUNTING_COLUMN_FACTION", fallback = "Фракция", width = 80 },
            { key = "kills", text = "HEADHUNTING_COLUMN_KILLED", fallback = "Убито", width = 90 },
            { key = "time", text = "HEADHUNTING_COLUMN_TIME_LEFT", fallback = "Осталось", width = 90 },
            { key = "bank", text = "HEADHUNTING_COLUMN_TOTAL_REWARDS", fallback = "Общая награда", width = 120 },
        },
        [CATEGORY_GUILD] = {
            { key = "guild", text = "HEADHUNTING_COLUMN_GUILD_NAME", fallback = "Гильдия", width = 356 },
            { key = "faction", text = "HEADHUNTING_COLUMN_FACTION", fallback = "Фракция", width = 80 },
            { key = "kills", text = "HEADHUNTING_COLUMN_KILLED", fallback = "Убито", width = 90 },
            { key = "time", text = "HEADHUNTING_COLUMN_TIME_LEFT", fallback = "Осталось", width = 90 },
            { key = "bank", text = "HEADHUNTING_COLUMN_TOTAL_REWARDS", fallback = "Общая награда", width = 140 },
        },
    },
}

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

local function ClassInfo(classID)
    if not classID or not C_CreatureInfo or not C_CreatureInfo.GetClassInfoEx then return end
    local ok, _, classFile, _, className = pcall(C_CreatureInfo.GetClassInfoEx, classID)
    if not ok then return end
    return classFile, className
end

local function ClassColor(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return 0.85, 0.85, 0.88
end

local function RaceIcon(raceID, gender)
    if not raceID or not C_CreatureInfo or not C_CreatureInfo.GetRaceInfoEx then return end
    local ok, _, raceFile = pcall(C_CreatureInfo.GetRaceInfoEx, raceID)
    if not ok or not raceFile then return end
    local suffix = (S_GENDER_FILESTRING and S_GENDER_FILESTRING[gender]) or "MALE"
    return string.format("Interface\\Custom\\RaceIcon\\RACE_ICON_%s%s", string.upper(raceFile), suffix)
end

local function FactionName(factionID)
    if not factionID or not PLAYER_FACTION_GROUP then return "" end

    local group = PLAYER_FACTION_GROUP[factionID]
    if group == "Horde" then return Global("FACTION_HORDE", "Орда") end
    if group == "Alliance" then return Global("FACTION_ALLIANCE", "Альянс") end
    if group == "Renegade" then return L["Ренегат"] end

    return ""
end

local function Money(value)
    return string.format("%s%s", value or 0, GOLD_ICON)
end

local function Call(method, ...)
    if not C_HeadHunting or not C_HeadHunting[method] then return end
    local ok, value = pcall(C_HeadHunting[method], ...)
    if not ok then return end
    return value
end

function Panel:Category()
    return self.category or CATEGORY_HEAD
end

function Panel:Records()
    local list = {}
    if not C_HeadHunting then return list end

    local category = self:Category()

    if self.tab == TAB_ALL then
        for index = 1, (Call("GetNumListedContracts", category) or 0) do
            local record = Call("GetListedContractInfo", category, index)
            if not record then break end
            list[#list + 1] = record
        end
    elseif self.tab == TAB_YOURS then
        for index = 1, (Call("GetNumPlayerContracts", category) or 0) do
            local record = Call("GetPlayerContractInfo", category, index)
            if not record then break end
            list[#list + 1] = record
        end
    end

    return list
end

function Panel:SearchResults()
    local list = {}
    if not C_HeadHunting then return list end

    local category = self:Category()

    for index = 1, (Call("GetNumSearchResults", category) or 0) do
        local record = Call("GetSearchResultInfo", category, index)
        if not record then break end
        list[#list + 1] = record
    end

    return list
end

function Panel:Request()
    if not C_HeadHunting then return end

    local category = self:Category()

    if self.tab == TAB_ALL then
        Call("RequestContractsList", category, self.sortOrder or SORT_MONEY_PER_KILL,
            self.sortReversed and true or false,
            self.filterFlags or bit.bor(FILTER_ALL_ONLINE, FILTER_ALL_GUILD_CONTRACTS),
            self.searchName)
    elseif self.tab == TAB_YOURS then
        Call("RequestPlayerContractsList", category)
    end
end

function Panel:Sort(sortOrder)
    if not sortOrder then return end

    if self.sortOrder == sortOrder then
        self.sortReversed = not self.sortReversed
    else
        self.sortOrder = sortOrder
        self.sortReversed = false
    end

    self.offset = 0
    self:Request()
    self:Update()
end

function Panel:SetFilter(flag, group)
    local flags = self.filterFlags or bit.bor(FILTER_ALL_ONLINE, FILTER_ALL_GUILD_CONTRACTS)

    flags = bit.band(flags, bit.bnot(group))
    self.filterFlags = bit.bor(flags, flag)

    self.offset = 0
    self:Request()
    self:Update()
end

function Panel:ContractPrice()
    local f = self.frame
    if not f then return 0 end

    local kills = tonumber(f.reward.kills:GetText()) or 0
    local gold = tonumber(f.reward.gold:GetText()) or 0
    if kills <= 0 or gold <= 0 then return 0 end

    return Call("CalculateContractPrice", kills, gold) or 0
end

function Panel:RewardState()
    local f = self.frame
    local reasons = {}

    local minPlayerKills, minGuildKills, minGoldPerKill, maxGoldPerKill, maxGoldTotal
    if C_HeadHunting and C_HeadHunting.GetContractLimits then
        local ok, a, b, c, d, e = pcall(C_HeadHunting.GetContractLimits)
        if ok then
            minPlayerKills, minGuildKills, minGoldPerKill, maxGoldPerKill, maxGoldTotal = a, b, c, d, e
        end
    end

    minPlayerKills = minPlayerKills or 1
    minGuildKills = minGuildKills or 10
    minGoldPerKill = minGoldPerKill or 1
    maxGoldPerKill = maxGoldPerKill or 100000
    maxGoldTotal = maxGoldTotal or 1000000

    local guildCategory = self:Category() == CATEGORY_GUILD
    local requiredKills = guildCategory and minGuildKills or minPlayerKills

    local kills = tonumber(f.reward.kills:GetText()) or 0
    local gold = tonumber(f.reward.gold:GetText()) or 0
    local total = self:ContractPrice()
    local playerGold = math.floor(GetMoney() / 10000)

    local killsValid = kills >= requiredKills
    local goldValid = gold >= minGoldPerKill and gold <= maxGoldPerKill

    if not killsValid then
        reasons[#reasons + 1] = string.format(
            Global("HEADHUNTING_SET_REWARD_BUTTON_DISABLE_REASON_1", "Минимум %d убийств"), requiredKills)
    end

    if gold <= 0 then
        reasons[#reasons + 1] = Global("HEADHUNTING_SET_REWARD_BUTTON_DISABLE_REASON_2", "Укажите награду")
    end

    if not self.selectedGUID then
        reasons[#reasons + 1] = Global("HEADHUNTING_SET_REWARD_BUTTON_DISABLE_REASON_4", "Выберите цель")
    end

    local moneyError
    if gold > 0 and not goldValid then
        moneyError = Global("HEADHUNTING_SET_REWARD_HELP_MONEY_ERROR_2", "Недопустимая награда")
    elseif total > maxGoldTotal then
        moneyError = string.format(Global("HEADHUNTING_SET_REWARD_HELP_MONEY_ERROR_1", "Не больше %d золота"), maxGoldTotal)
    elseif total > 0 and total >= playerGold then
        moneyError = string.format(Global("HEADHUNTING_SET_REWARD_HELP_MONEY_ERROR_3", "Нужно %d золота"), total)
    end

    if moneyError then reasons[#reasons + 1] = moneyError end

    return reasons, moneyError, total, killsValid, goldValid, requiredKills
end

function Panel:CreateSuggestion(parent, index)
    local S = NS.Styling
    local primary = index == 1

    local row = CreateFrame("Frame", nil, parent)

    if primary then
        row:SetWidth(SUGGEST_PRIMARY_W)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
        row:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 8, 8)
    else
        row:SetHeight(SUGGEST_SECONDARY_H)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", SUGGEST_PRIMARY_W + 16,
            -8 - (index - 2) * (SUGGEST_SECONDARY_H + 8))
        row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    end

    Chrome(row)
    row:SetBackdropColor(NS.Styling.Tint(0.05, 0.055, 0.075, primary and 0.85 or 0.65))

    local sheen = row:CreateTexture(nil, "BORDER")
    sheen:SetHeight(1)
    sheen:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    sheen:SetPoint("TOPRIGHT", row, "TOPRIGHT", -1, -1)
    sheen:SetTexture(WHITE)
    sheen:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    iconFrame:SetBackdropColor(0, 0, 0, 0.8)
    iconFrame:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
    iconFrame:EnableMouse(false)
    row.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local title = row:CreateFontString(nil, "OVERLAY")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    row.title = title

    local rule = row:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetTexture(WHITE)
    rule:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28)
    row.rule = rule

    local description = row:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    description:SetJustifyV("TOP")
    row.description = description

    local action = NS.Widgets.CreateThemedButton(row, "", 170, 22, function()
        Panel.tab = index == 2 and TAB_ALL or TAB_YOURS
        Panel.offset = 0
        Panel:Request()
        Panel:Update()
    end)
    action:Hide()
    row.action = action

    if primary then
        iconFrame:SetSize(70, 70)

        title:SetFont(NS.FONT, NS.FS(15), "")
        title:SetWidth(SUGGEST_PRIMARY_W - 28)
        title:SetJustifyH("CENTER")
        title:SetPoint("TOP", iconFrame, "BOTTOM", 0, -12)

        rule:SetWidth(90)
        rule:SetPoint("TOP", title, "BOTTOM", 0, -8)

        description:SetWidth(SUGGEST_PRIMARY_W - 34)
        description:SetJustifyH("CENTER")
        description:SetPoint("TOP", rule, "BOTTOM", 0, -8)

        local players = row:CreateFontString(nil, "OVERLAY")
        players:SetFont(NS.FONT, NS.FS(11), "")
        players:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        players:SetPoint("TOP", description, "BOTTOM", 0, -16)
        row.players = players

        local guilds = row:CreateFontString(nil, "OVERLAY")
        guilds:SetFont(NS.FONT, NS.FS(11), "")
        guilds:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        guilds:SetPoint("TOP", players, "BOTTOM", 0, -4)
        row.guilds = guilds
    else
        iconFrame:SetSize(58, 58)

        title:SetFont(NS.FONT, NS.FS(13), "")
        title:SetWidth(SUGGEST_SECONDARY_W - 96)
        title:SetJustifyH("LEFT")

        rule:SetWidth(SUGGEST_SECONDARY_W - 96)
        rule:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

        description:SetWidth(SUGGEST_SECONDARY_W - 96)
        description:SetJustifyH("LEFT")
        description:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -6)

        action:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)
    end

    row:Hide()
    return row
end

function Panel:CreateRow(parent, index, height, onClick)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(height)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.28 or 0.10)

    local selected = row:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetTexture(WHITE)
    selected:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    selected:Hide()
    row.selected = selected

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    local race = row:CreateTexture(nil, "ARTWORK")
    race:SetSize(20, 20)
    row.race = race

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetJustifyH("LEFT")
    row.name = name

    local wanted = row:CreateFontString(nil, "OVERLAY")
    wanted:SetFont(NS.FONT, NS.FS(11), "")
    wanted:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    wanted:SetJustifyH("LEFT")
    row.wanted = wanted

    local class = row:CreateTexture(nil, "ARTWORK")
    class:SetSize(20, 20)
    row.class = class

    local faction = row:CreateFontString(nil, "OVERLAY")
    faction:SetFont(NS.FONT, NS.FS(11), "")
    faction:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    faction:SetJustifyH("LEFT")
    row.faction = faction

    local perKill = row:CreateFontString(nil, "OVERLAY")
    perKill:SetFont(NS.FONT, NS.FS(12), "")
    perKill:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    perKill:SetJustifyH("LEFT")
    row.perKill = perKill

    local bank = row:CreateFontString(nil, "OVERLAY")
    bank:SetFont(NS.FONT, NS.FS(12), "")
    bank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    bank:SetJustifyH("LEFT")
    row.bank = bank

    local statusIcon = row:CreateTexture(nil, "ARTWORK")
    statusIcon:SetSize(16, 16)
    row.statusIcon = statusIcon

    local status = row:CreateFontString(nil, "OVERLAY")
    status:SetFont(NS.FONT, NS.FS(11), "")
    status:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    status:SetPoint("LEFT", statusIcon, "RIGHT", 4, 0)
    status:SetJustifyH("LEFT")
    row.status = status

    local kills = row:CreateFontString(nil, "OVERLAY")
    kills:SetFont(NS.FONT, NS.FS(12), "")
    kills:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    kills:SetJustifyH("LEFT")
    row.kills = kills

    local time = row:CreateFontString(nil, "OVERLAY")
    time:SetFont(NS.FONT, NS.FS(12), "")
    time:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    time:SetJustifyH("LEFT")
    row.time = time

    if onClick then row:SetScript("OnClick", onClick) end

    row:Hide()
    return row
end

function Panel:FillRow(row, record, columns)
    local x = 8
    local classFile = ClassInfo(record.classID)

    row.race:Hide()
    row.name:Hide()
    row.wanted:Hide()
    row.class:Hide()
    row.faction:Hide()
    row.perKill:Hide()
    row.bank:Hide()
    row.statusIcon:Hide()
    row.status:Hide()
    row.kills:Hide()
    row.time:Hide()

    for _, column in ipairs(columns) do
        if column.key == "player" then
            local racePath = RaceIcon(record.raceID, record.genderID)
            row.race:ClearAllPoints()
            row.race:SetPoint("LEFT", row, "LEFT", x, 0)
            if racePath then
                row.race:SetTexture(racePath)
                row.race:Show()
            end

            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row, "LEFT", x + (racePath and 24 or 0), 0)
            row.name:SetWidth(column.width - (racePath and 26 or 2))
            row.name:SetText(record.name or "")
            row.name:SetTextColor(ClassColor(classFile))
            row.name:Show()
        elseif column.key == "guild" then
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row, "LEFT", x, 0)
            row.name:SetWidth(column.width - 4)
            row.name:SetText(record.name or "")
            row.name:SetTextColor(1, 0.82, 0)
            row.name:Show()
        elseif column.key == "wanted" then
            row.wanted:ClearAllPoints()
            row.wanted:SetPoint("LEFT", row, "LEFT", x, 0)
            row.wanted:SetWidth(column.width - 4)
            if record.hasGuildContracts then
                row.wanted:SetText(string.format("%s %s",
                    Global("HEADHUNTING_WANTED_GUILD_BUTTON", "Розыск!"), record.guildName or ""))
            else
                row.wanted:SetText(record.guildName or "")
            end
            row.wanted:Show()
        elseif column.key == "class" then
            row.class:ClearAllPoints()
            row.class:SetPoint("LEFT", row, "LEFT", x, 0)
            row.class:SetTexture(CLASS_ICONS)
            if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
                row.class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFile]))
                row.class:Show()
            end
        elseif column.key == "faction" then
            row.faction:ClearAllPoints()
            row.faction:SetPoint("LEFT", row, "LEFT", x, 0)
            row.faction:SetWidth(column.width - 4)
            row.faction:SetText(FactionName(record.teamID))
            row.faction:Show()
        elseif column.key == "perKill" then
            row.perKill:ClearAllPoints()
            row.perKill:SetPoint("LEFT", row, "LEFT", x, 0)
            row.perKill:SetWidth(column.width - 4)
            row.perKill:SetText(Money(record.moneyPerKill))
            row.perKill:Show()
        elseif column.key == "bank" then
            row.bank:ClearAllPoints()
            row.bank:SetPoint("LEFT", row, "LEFT", x, 0)
            row.bank:SetWidth(column.width - 4)
            row.bank:SetText(Money(record.moneyInBank))
            row.bank:Show()
        elseif column.key == "status" then
            row.statusIcon:ClearAllPoints()
            row.statusIcon:SetPoint("LEFT", row, "LEFT", x, 0)
            row.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-"
                .. (record.isOnline and "Online" or "Offline"))
            row.statusIcon:Show()
            row.status:SetText(record.isOnline and Global("FRIENDS_LIST_ONLINE", "В сети")
                or Global("FRIENDS_LIST_OFFLINE", "Не в сети"))
            row.status:Show()
        elseif column.key == "kills" then
            row.kills:ClearAllPoints()
            row.kills:SetPoint("LEFT", row, "LEFT", x, 0)
            row.kills:SetWidth(column.width - 4)
            row.kills:SetFormattedText("%s / %s", record.currentKills or 0, record.totalKills or 0)
            row.kills:Show()
        elseif column.key == "time" then
            row.time:ClearAllPoints()
            row.time:SetPoint("LEFT", row, "LEFT", x, 0)
            row.time:SetWidth(column.width - 4)
            row.time:SetText(SecondsToTime and SecondsToTime(record.timeLeft or 0) or (record.timeLeft or ""))
            row.time:Show()
        end

        x = x + column.width
    end
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_HeadHunting", UIParent)
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
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -16)
    title:SetText(Global("HEADHUNTING", "Охота за головами"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 32)
    search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -46)
    search:SetScript("OnEnterPressed", function(box)
        Panel.searchName = box:GetText()
        if Panel.searchName == "" then Panel.searchName = nil end
        Panel.offset = 0
        Panel:Request()
        Panel:Update()
    end)
    search:Hide()
    f.search = search

    S.CreateAnimatedSeparator(f, -72)

    f.tabs = {}
    local topTabs = {
        { key = TAB_HOME, label = Global("HEADHUNTING_HOME", "Главная") },
        { key = TAB_ALL, label = Global("HEADHUNTING_TARGETS", "Цели") },
        { key = TAB_YOURS, label = Global("HEADHUNTING_YOU_TARGETS", "Ваши цели") },
    }

    local tabX = PAD
    for index, tab in ipairs(topTabs) do
        local button = CreateFrame("Button", nil, f)
        button:SetHeight(24)
        Chrome(button)

        local label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(11), "")
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        button.label = label
        button:SetWidth(label:GetStringWidth() + 24)

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
            Panel.selectedGUID = nil
            Panel.details = nil
            Panel:Request()
            Panel:Update()
        end)

        button:SetPoint("TOPLEFT", f, "TOPLEFT", tabX, -84)
        tabX = tabX + button:GetWidth() + 6

        button.tabKey = tab.key
        f.tabs[index] = button
    end

    local categoryDrop = NS.Widgets.CreateThemedDropdown(f, 200, function(value)
        Panel.category = value
        Panel.offset = 0
        Panel.selectedGUID = nil
        Panel.details = nil
        Panel:Request()
        Panel:Update()
    end)
    categoryDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -85)
    categoryDrop:Hide()
    f.categoryDrop = categoryDrop

    local statusDrop = NS.Widgets.CreateThemedDropdown(f, 150, function(value)
        Panel:SetFilter(value, bit.bor(FILTER_ALL_ONLINE, FILTER_ONLY_ONLINE, FILTER_ONLY_OFFLINE))
    end)
    statusDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 210, -85)
    statusDrop:Hide()
    f.statusDrop = statusDrop

    local guildDrop = NS.Widgets.CreateThemedDropdown(f, 190, function(value)
        Panel:SetFilter(value, bit.bor(FILTER_ALL_GUILD_CONTRACTS, FILTER_ONLY_GUILD_CONTRACTS,
            FILTER_ONLY_WITHOUT_GUILD_CONTRACTS))
    end)
    guildDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 366, -85)
    guildDrop:Hide()
    f.guildDrop = guildDrop

    local rewardButton = NS.Widgets.CreateThemedButton(f, Global("HEADHUNTING_SET_REWARD", "Назначить награду"),
        170, 22, function()
            Panel.selectedGUID = nil
            Panel.rewardOpen = true
            Call("ClearSearchResults")
            Panel:Update()
        end)
    rewardButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 210, -85)
    rewardButton:Hide()
    f.rewardButton = rewardButton

    local suggest = CreateFrame("Frame", nil, f)
    suggest:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    suggest:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(suggest)
    suggest:Hide()
    f.suggest = suggest

    f.suggestRows = {}
    for index = 1, 3 do
        f.suggestRows[index] = self:CreateSuggestion(suggest, index)
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(body)
    body:Hide()
    f.body = body

    local strip = CreateFrame("Frame", nil, body)
    strip:SetHeight(CONTRACT_STRIP_H)
    strip:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
    strip:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, -8)
    strip:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    strip:SetBackdropColor(0.06, 0.05, 0.04, 0.9)
    strip:SetBackdropBorderColor(1, 0.5, 0, 0.7)
    f.strip = strip

    local stripText = strip:CreateFontString(nil, "OVERLAY")
    stripText:SetFont(NS.FONT, NS.FS(12), "")
    stripText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    stripText:SetPoint("LEFT", strip, "LEFT", 12, 0)
    stripText:SetPoint("RIGHT", strip, "RIGHT", -12, 0)
    stripText:SetJustifyH("LEFT")
    f.stripText = stripText

    f.headers = {}
    for index = 1, 8 do
        local button = CreateFrame("Button", nil, body)
        button:SetHeight(HEADER_H)

        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(11), "")
        text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        text:SetPoint("LEFT", button, "LEFT", 0, 0)
        button.text = text

        local arrow = button:CreateFontString(nil, "OVERLAY")
        arrow:SetFont(NS.FONT, NS.FS(9), "")
        arrow:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        arrow:SetPoint("LEFT", text, "RIGHT", 4, 0)
        arrow:Hide()
        button.arrow = arrow

        button:SetHighlightTexture(WHITE, "ADD")
        button:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

        button:SetScript("OnClick", function(self)
            if self.sortOrder then Panel:Sort(self.sortOrder) end
        end)

        button:Hide()
        f.headers[index] = button
    end

    local function ScrollList(value)
        Panel.offset = value
        Panel:Update()
    end

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local total = #Panel:Records()
        if total <= LIST_ROWS then return end
        ScrollList(math.max(0, math.min(total - LIST_ROWS, (Panel.offset or 0) - delta)))
    end)

    f.listScroll = ScrollBar(body, ScrollList)
    f.listScroll:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4, -(8 + CONTRACT_STRIP_H + 8 + HEADER_H + 4))
    f.listScroll:SetHeight(LIST_ROWS * ROW_H)

    f.rows = {}
    for index = 1, LIST_ROWS do
        local row = self:CreateRow(body, index, ROW_H, function(self)
            if not self.record then return end
            Panel:SelectRecord(self.record)
        end)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8,
            -(8 + CONTRACT_STRIP_H + 8 + HEADER_H + 4) - (index - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8 - SCROLL_W - 4,
            -(8 + CONTRACT_STRIP_H + 8 + HEADER_H + 4) - (index - 1) * ROW_H)
        f.rows[index] = row
    end

    local detail = CreateFrame("Frame", nil, body)
    detail:SetHeight(DETAIL_H)
    detail:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 8, 8)
    detail:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -8, 8)
    detail:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    detail:SetBackdropColor(NS.Styling.Panel(0.03, 0.035, 0.05, 0.9))
    detail:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    f.detail = detail

    local detailTitle = detail:CreateFontString(nil, "OVERLAY")
    detailTitle:SetFont(NS.FONT, NS.FS(12), "")
    detailTitle:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    detailTitle:SetPoint("TOPLEFT", detail, "TOPLEFT", 12, -10)
    f.detailTitle = detailTitle

    local detailText = detail:CreateFontString(nil, "OVERLAY")
    detailText:SetFont(NS.FONT, NS.FS(11), "")
    detailText:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    detailText:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -6)
    detailText:SetPoint("RIGHT", detail, "RIGHT", -220, 0)
    detailText:SetJustifyH("LEFT")
    detailText:SetJustifyV("TOP")
    f.detailText = detailText

    local killCheck = NS.Widgets.CreateThemedCheckbox(detail,
        Global("HEADHUNTING_SETTINGS_NOTIFICATION_AT_KILL_LABEL", "Уведомлять об убийстве"), false, function(value)
            if not Panel.selectedGUID then return end
            Call("ChangeNotification", Panel:Category(), Panel.selectedGUID, false, value and true or false)
        end)
    killCheck:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -190, -12)
    killCheck:Hide()
    f.killCheck = killCheck

    local completeCheck = NS.Widgets.CreateThemedCheckbox(detail,
        Global("HEADHUNTING_SETTINGS_NOTIFICATION_AT_COMPLETE_LABEL", "Уведомлять о завершении"), false, function(value)
            if not Panel.selectedGUID then return end
            Call("ChangeNotification", Panel:Category(), Panel.selectedGUID, true, value and true or false)
        end)
    completeCheck:SetPoint("TOPLEFT", killCheck, "BOTTOMLEFT", 0, -8)
    completeCheck:Hide()
    f.completeCheck = completeCheck

    local withdraw = NS.Widgets.CreateThemedButton(detail,
        Global("HEADHUNTING_WITHDRAW_AWARD", "Отозвать награду"), 170, 22, function()
            if not Panel.selectedGUID then return end

            NS.Widgets.ShowConfirm(Global("HEADHUNTING_REMOVE_CONTRACT", "Отозвать награду?"),
                Global("ACCEPT", "Принять"), function()
                    Call("CancelContract", Panel:Category(), Panel.selectedGUID)
                    Panel.selectedGUID = nil
                    Panel.details = nil
                    Panel:Update()
                end)
        end)
    withdraw:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -12, 12)
    withdraw:Hide()
    f.withdraw = withdraw

    local reward = CreateFrame("Frame", nil, f)
    reward:SetSize(440, 420)
    reward:SetPoint("CENTER", f, "CENTER", 0, -10)
    reward:SetFrameStrata("DIALOG")
    reward:SetFrameLevel(f:GetFrameLevel() + 50)
    Chrome(reward)
    reward:SetBackdropColor(NS.Styling.Panel(0.03, 0.035, 0.05, 0.98))
    S.CreateShadow(reward, 6, 0.6)
    reward:EnableMouse(true)
    reward:Hide()
    f.reward = reward

    local rewardTitle = reward:CreateFontString(nil, "OVERLAY")
    rewardTitle:SetFont(NS.FONT, NS.FS(14), "")
    rewardTitle:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    rewardTitle:SetPoint("TOPLEFT", reward, "TOPLEFT", 14, -12)
    rewardTitle:SetText(Global("HEADHUNTING_SET_REWARD", "Назначить награду"))

    local rewardClose = NS.Widgets.CreateCloseButton(reward, 16, function()
        Panel.rewardOpen = nil
        Panel:Update()
    end)
    rewardClose:SetPoint("TOPRIGHT", reward, "TOPRIGHT", -10, -10)

    local rewardSearch = NS.Widgets.CreateThemedEditBox(reward, 260, 20, 32)
    rewardSearch:SetPoint("TOPLEFT", reward, "TOPLEFT", 14, -40)
    reward.search = rewardSearch

    local rewardSearchButton = NS.Widgets.CreateThemedButton(reward, Global("SEARCH", "Поиск"), 140, 20, function()
        Panel.selectedGUID = nil
        Call("RequestSearch", Panel:Category(), rewardSearch:GetText() or "")
        Panel:Update()
    end)
    rewardSearchButton:SetPoint("LEFT", rewardSearch, "RIGHT", 8, 0)

    reward.searchRows = {}
    for index = 1, SEARCH_ROWS do
        local row = self:CreateRow(reward, index, 26, function(self)
            if not self.record then return end
            Panel.selectedGUID = Panel.selectedGUID ~= self.record.GUID and self.record.GUID or nil
            Panel:Update()
        end)
        row:SetPoint("TOPLEFT", reward, "TOPLEFT", 12, -70 - (index - 1) * 26)
        row:SetPoint("TOPRIGHT", reward, "TOPRIGHT", -12, -70 - (index - 1) * 26)
        reward.searchRows[index] = row
    end

    local killsLabel = reward:CreateFontString(nil, "OVERLAY")
    killsLabel:SetFont(NS.FONT, NS.FS(11), "")
    killsLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    killsLabel:SetPoint("TOPLEFT", reward, "TOPLEFT", 14, -70 - SEARCH_ROWS * 26 - 12)
    killsLabel:SetText(Global("HEADHUNTING_KILLS", "Количество убийств"))

    local kills = NS.Widgets.CreateThemedEditBox(reward, 90, 20, 5)
    kills:SetPoint("LEFT", killsLabel, "RIGHT", 10, 0)
    kills:SetText("1")
    reward.kills = kills

    local goldLabel = reward:CreateFontString(nil, "OVERLAY")
    goldLabel:SetFont(NS.FONT, NS.FS(11), "")
    goldLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    goldLabel:SetPoint("TOPLEFT", killsLabel, "BOTTOMLEFT", 0, -14)
    goldLabel:SetText(Global("HEADHUNTING_GOLD_FOR_KILL", "Золота за убийство"))

    local gold = NS.Widgets.CreateThemedEditBox(reward, 90, 20, 7)
    gold:SetPoint("LEFT", goldLabel, "RIGHT", 10, 0)
    gold:SetText("100")
    reward.gold = gold

    kills:SetScript("OnTextChanged", function() Panel:UpdateReward() end)
    gold:SetScript("OnTextChanged", function() Panel:UpdateReward() end)

    reward.steps = {}
    for index = 1, 4 do
        local step = reward:CreateFontString(nil, "OVERLAY")
        step:SetFont(NS.FONT, NS.FS(11), "")
        step:SetPoint("TOPLEFT", reward, "TOPLEFT", 14, -70 - SEARCH_ROWS * 26 - 58 - (index - 1) * 16)
        step:SetPoint("RIGHT", reward, "RIGHT", -14, 0)
        step:SetJustifyH("LEFT")
        reward.steps[index] = step
    end

    local total = reward:CreateFontString(nil, "OVERLAY")
    total:SetFont(NS.FONT, NS.FS(12), "")
    total:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    total:SetPoint("BOTTOMLEFT", reward, "BOTTOMLEFT", 14, 44)
    total:SetPoint("RIGHT", reward, "RIGHT", -14, 0)
    total:SetJustifyH("LEFT")
    reward.total = total

    local confirmButton = NS.Widgets.CreateThemedButton(reward,
        Global("HEADHUNTING_SET_REWARD", "Назначить награду"), 200, 24, function(button)
            if button.disabled then return end

            local numKills = tonumber(kills:GetText()) or 0
            local goldPerKill = tonumber(gold:GetText()) or 0
            if numKills <= 0 or goldPerKill <= 0 or not Panel.selectedGUID then return end

            local name = Panel.selectedName or ""
            local text = string.format(Panel:Category() == CATEGORY_GUILD
                and Global("HEADHUNTING_TOAST_CONTRACT_GUILD_CONFIRMATION_REQUEST", "Назначить %d золота за %d убийств для %s?")
                or Global("HEADHUNTING_TOAST_CONTRACT_CONFIRMATION_REQUEST", "Назначить %d золота за %d убийств для %s?"),
                goldPerKill * numKills, numKills, name)

            NS.Widgets.ShowConfirm(text, Global("ACCEPT", "Принять"), function()
                Call("RegisterContract", Panel:Category(), Panel.selectedGUID, numKills, goldPerKill)
                Panel.rewardOpen = nil
                Panel:Request()
                Panel:Update()
            end)
        end)
    confirmButton:SetPoint("BOTTOM", reward, "BOTTOM", 0, 14)
    reward.confirm = confirmButton

    confirmButton:SetScript("OnEnter", function(button)
        if not button.reasons or #button.reasons == 0 then return end

        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("HEADHUNTING_SET_REWARD_BUTTON_TOOLTIP", "Назначить награду"), 1, 1, 1)
        GameTooltip:AddLine(Global("HEADHUNTING_SET_REWARD_BUTTON_TOOLTIP_DESC", ""), 1, 1, 1, true)
        for _, reason in ipairs(button.reasons) do
            GameTooltip:AddLine(reason, 1, 0.3, 0.3, true)
        end
        GameTooltip:Show()
    end)
    confirmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    if NS.CreateJournalTabs then
        f.journalTabs = NS.CreateJournalTabs(f, "headhunting")
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_MONEY")
    events:SetScript("OnEvent", function(_, event, ...)
        if not Panel.frame or not Panel.frame:IsShown() then return end

        if event == "HEADHUNTINE_CONTRACT_DETAILS" then
            Panel:ReadDetails()
        elseif event == "HEADHUNTINE_CONTRACT_NOTIFICATIONS" then
            Panel:ReadNotifications()
        elseif event == "HEADHUNTINE_ERROR" then
            local text = ...
            if type(text) == "string" then NS.Print(text) end
        end

        Panel:Update()
    end)

    if events.RegisterCustomEvent then
        for _, event in ipairs({
            "HEADHUNTING_CONTRACTS_LIST",
            "HEADHUNTING_PLAYER_CONTRACTS_LIST_UPDATE",
            "HEADHUNTING_CONTRACTS_ON_PLAYER",
            "HEADHUNTING_SUMMARY_INFO",
            "HEADHUNTING_SEARCH_RESULT",
            "HEADHUNTING_CONTRACT_REGISTED",
            "HEADHUNTING_CONTRACT_CANCELED",
            "HEADHUNTING_CONTRACT_NOTIFICATION_CHANGED",
            "HEADHUNTINE_CONTRACT_DETAILS",
            "HEADHUNTINE_CONTRACT_NOTIFICATIONS",
            "HEADHUNTINE_ERROR",
        }) do
            pcall(events.RegisterCustomEvent, events, event)
        end
    end

    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_HeadHunting")

    self.frame = f
    self.tab = self.tab or TAB_HOME
    self.category = self.category or CATEGORY_HEAD
    self.filterFlags = bit.bor(FILTER_ALL_ONLINE, FILTER_ALL_GUILD_CONTRACTS)
    self.sortOrder = SORT_MONEY_PER_KILL
    self.offset = 0

    f:Hide()
end

function Panel:SelectRecord(record)
    self.selectedGUID = record.GUID
    self.selectedName = record.name
    self.details = nil

    if self.tab == TAB_ALL then
        Call("RequestContractDetails", self:Category(), record.GUID)
    else
        Call("RequestContractNotificationSettings", self:Category(), record.GUID)
    end

    self:Update()
end

function Panel:ReadDetails()
    local text = ""

    for index = 1, (Call("GetNumContractDetails") or 0) do
        local moneyPerKill, killsLeft, timeLeft
        if C_HeadHunting and C_HeadHunting.GetContractDetailInfo then
            local ok, a, b, c = pcall(C_HeadHunting.GetContractDetailInfo, index)
            if ok then moneyPerKill, killsLeft, timeLeft = a, b, c end
        end

        if killsLeft then
            text = text .. string.format(
                Global("HEADHUNTING_CONTRACT_DETAILS", "Контракт на %s убийств, банк %s, за убийство %s, осталось %s"),
                killsLeft, killsLeft * (moneyPerKill or 0), moneyPerKill or 0,
                SecondsToTime and SecondsToTime(timeLeft or 0) or (timeLeft or ""))
        end
    end

    self.details = text
end

function Panel:ReadNotifications()
    local f = self.frame
    if not f then return end

    f.completeCheck:SetChecked(Call("IsContractNotificationEnabled", 1) and true or false)
    f.killCheck:SetChecked(Call("IsContractNotificationEnabled", 2) and true or false)
    self.details = ""
end

function Panel:UpdateSuggest()
    local f = self.frame

    local entries = {
        {
            title = Global("HEADHUNTING", "Охота за головами"),
            description = Global("HEADHUNTING_DESC", ""),
            icon = "Interface\\Icons\\Warrior_Wild_strike",
        },
        {
            title = Global("HEADHUNTING_TARGETS", "Цели"),
            description = Global("HEADHUNTING_TARGETS_DESC", ""),
            icon = "Interface\\Icons\\Warrior_talent_icon_Stormbolt",
            button = Global("HEADHUNTING_TARGETS", "Цели"),
        },
        {
            title = Global("HEADHUNTING_YOU_TARGETS", "Ваши цели"),
            description = Global("HEADHUNTING_YOU_TARGETS_DESC", ""),
            icon = "Interface\\Icons\\Ability_rogue_ambush",
            button = Global("HEADHUNTING_SET_REWARD", "Назначить награду"),
        },
    }

    local playerCount, playerMoney, guildCount, guildMoney = 0, 0, 0, 0
    if C_HeadHunting and C_HeadHunting.GetSummery then
        local ok, a, b, c, d = pcall(C_HeadHunting.GetSummery)
        if ok then playerCount, playerMoney, guildCount, guildMoney = a, b, c, d end
    end

    f.subtitle:SetText(Global("HEADHUNTING_HOME", "Главная"))

    for index = 1, 3 do
        local row = f.suggestRows[index]
        local entry = entries[index]

        row.icon:SetTexture(entry.icon or QUESTION)
        row.title:SetText(entry.title)
        row.description:SetText(entry.description)

        if entry.button then
            row.action:SetText(entry.button)
            row.action:Show()
        else
            row.action:Hide()
        end

        if index == 1 then
            row.players:SetText(string.format(
                Global("HEADHUNTING_STATS_PLAYER", "Игроки: %d контрактов на %s"), playerCount or 0, playerMoney or 0))
            row.players:SetShown((playerCount or 0) > 0)
            row.guilds:SetText(string.format(
                Global("HEADHUNTING_STATS_GUILD", "Гильдии: %d контрактов на %s"), guildCount or 0, guildMoney or 0))
            row.guilds:SetShown((guildCount or 0) > 0)
        end

        local titleHeight = row.title:GetStringHeight() or 14
        local textHeight = row.description:GetStringHeight() or 0
        local actionHeight = row.action:IsShown() and 36 or 0
        local statsHeight = index == 1 and 48 or 0
        local height = row:GetHeight() or 0

        if index == 1 then
            local block = 99 + titleHeight + textHeight + statsHeight
            row.iconFrame:ClearAllPoints()
            row.iconFrame:SetPoint("TOP", row, "TOP", 0, -math.max(16, math.floor((height - block) / 2)))
        else
            local block = 13 + titleHeight + textHeight + actionHeight
            local top = math.max(12, math.floor((height - block) / 2))

            row.title:ClearAllPoints()
            row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 82, -top)
            row.iconFrame:ClearAllPoints()
            row.iconFrame:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -top)
        end

        row:Show()
    end
end

function Panel:UpdateHeaders(columns)
    local f = self.frame
    local x = 8

    for index, header in ipairs(f.headers) do
        local column = columns[index]

        if column then
            header.sortOrder = column.sort
            header.text:SetText(Global(column.text, column.fallback))
            header:SetWidth(math.max(30, header.text:GetStringWidth() + 14))
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", f.body, "TOPLEFT", x, -(8 + CONTRACT_STRIP_H + 8))
            header.arrow:SetText(self.sortReversed and "v" or "^")
            header.arrow:SetShown(column.sort ~= nil and self.sortOrder == column.sort)
            header:Show()
            x = x + column.width
        else
            header:Hide()
        end
    end
end

function Panel:UpdateStrip()
    local f = self.frame
    local category = self:Category()
    local count = Call("GetNumContractsOnPlayer", category) or 0

    if count == 0 then
        local guildName = GetGuildInfo("player")
        local text

        if category == CATEGORY_GUILD then
            text = guildName and Global("HEADHUNTING_NO_CONTRACT_ON_PLAYER_GUILD", "На вашу гильдию нет контрактов")
                or Global("HEADHUNTING_PLAYER_NO_GUILD", "Вы не состоите в гильдии")
        else
            text = Global("HEADHUNTING_NO_CONTRACT_ON_PLAYER", "На вас нет контрактов")
        end

        f.stripText:SetText(text)
        f.stripText:SetTextColor(0.6, 0.6, 0.65)
        return
    end

    local info = Call("GetContractOnPlayerInfo", category, 1)
    if not info then return end

    f.stripText:SetFormattedText("%s   %s %s   %s %s",
        category == CATEGORY_GUILD and Global("HEADHUNTING_REWARD_FOR_YOU_GUILD", "Награда за вашу гильдию")
            or Global("HEADHUNTING_REWARD_FOR_YOU_HEAD", "Награда за вашу голову"),
        Global("HEADHUNTING_COLUMN_REWARD_PER_KILL", "За убийство"), Money(info.moneyPerKill),
        Global("HEADHUNTING_COLUMN_TOTAL_REWARDS", "Общая награда"), Money(info.moneyInBank))
    f.stripText:SetTextColor(1, 0.75, 0.3)
end

function Panel:UpdateReward()
    local f = self.frame
    if not f or not f.reward:IsShown() then return end

    local S = NS.Styling
    local results = self:SearchResults()
    local columns = self:Category() == CATEGORY_GUILD
        and { { key = "guild", width = 260 }, { key = "faction", width = 120 } }
        or { { key = "player", width = 220 }, { key = "class", width = 40 }, { key = "faction", width = 120 } }

    for index = 1, SEARCH_ROWS do
        local row = f.reward.searchRows[index]
        local record = results[index]

        if record then
            row.record = record
            self:FillRow(row, record, columns)
            row.selected:SetShown(self.selectedGUID == record.GUID)
            if self.selectedGUID == record.GUID then self.selectedName = record.name end
            row:Show()
        else
            row.record = nil
            row:Hide()
        end
    end

    local reasons, moneyError, total, killsValid, goldValid, requiredKills = self:RewardState()

    local guildCategory = self:Category() == CATEGORY_GUILD
    local steps = {
        {
            text = string.format(Global("HEADHUNTING_SET_REWARD_HELP_BOX_STEP_1", "Найдите цель: %s"),
                guildCategory and Global("HEADHUNTING_SET_REWARD_HELP_BOX_GUILD", "гильдия")
                or Global("HEADHUNTING_SET_REWARD_HELP_BOX_PLAYER", "игрок")),
            done = #results > 0,
        },
        {
            text = guildCategory and Global("HEADHUNTING_SET_REWARD_HELP_BOX_STEP_2_GUILD", "Выберите гильдию")
                or Global("HEADHUNTING_SET_REWARD_HELP_BOX_STEP_2_PLAYER", "Выберите игрока"),
            done = self.selectedGUID and true or false,
        },
        {
            text = string.format(Global("HEADHUNTING_SET_REWARD_HELP_BOX_STEP_3", "Укажите число убийств: %d"),
                requiredKills),
            done = killsValid,
        },
        {
            text = Global("HEADHUNTING_SET_REWARD_HELP_BOX_STEP_4", "Укажите награду за убийство"),
            done = goldValid,
        },
    }

    for index, step in ipairs(steps) do
        local line = f.reward.steps[index]
        line:SetText(step.text)
        if step.done then
            line:SetTextColor(0.1, 1, 0.1)
        else
            line:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    if moneyError then
        f.reward.total:SetText(moneyError)
        f.reward.total:SetTextColor(1, 0.3, 0.3)
    else
        f.reward.total:SetFormattedText(
            Global("HEADHUNTING_SET_REWARD_HELP_BOX_TOTAL_MONEY", "Итого: %d"), total)
        f.reward.total:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    end

    local button = f.reward.confirm
    button.reasons = reasons
    button.disabled = #reasons > 0
    button:SetAlpha(button.disabled and 0.4 or 1)
end

function Panel:UpdateBody()
    local f = self.frame
    local columns = COLUMNS[self.tab] and COLUMNS[self.tab][self:Category()]
    if not columns then return end

    local records = self:Records()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #records - LIST_ROWS)))
    self.offset = offset

    f.subtitle:SetFormattedText("%s - %s",
        self.tab == TAB_ALL and Global("HEADHUNTING_TARGETS", "Цели")
            or Global("HEADHUNTING_YOU_TARGETS", "Ваши цели"),
        self:Category() == CATEGORY_GUILD and Global("HEADHUNTING_REWARD_FOR_GUILDS", "Награда за гильдии")
            or Global("HEADHUNTING_REWARD_FOR_HEADS", "Награда за головы"))

    self:UpdateStrip()
    self:UpdateHeaders(columns)

    for index = 1, LIST_ROWS do
        local row = f.rows[index]
        local record = records[index + offset]

        if record then
            row.record = record
            self:FillRow(row, record, columns)
            row.selected:SetShown(self.selectedGUID == record.GUID)
            row:Show()
        else
            row.record = nil
            row:Hide()
        end
    end

    f.listScroll:SetState(#records, LIST_ROWS, offset)

    local hasSelection = self.selectedGUID and true or false

    f.detailTitle:SetText(Global("HEADHUNTING_DETAILS_TITLE", "Контракт"))
    f.detailText:SetText(hasSelection and (self.details or Global("SEARCH_LOADING_TEXT", "Загрузка")) or
        L["выберите цель из списка"])

    f.killCheck:SetShown(hasSelection and self.tab == TAB_YOURS)
    f.completeCheck:SetShown(hasSelection and self.tab == TAB_YOURS)
    f.withdraw:SetShown(hasSelection and self.tab == TAB_YOURS)
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling

    if not C_HeadHunting then
        f.subtitle:SetText(L["охота за головами недоступна на этом сервере"])
        return
    end

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

    local home = self.tab == TAB_HOME
    local all = self.tab == TAB_ALL

    f.suggest:SetShown(home)
    f.body:SetShown(not home)
    f.search:SetShown(all)
    f.statusDrop:SetShown(all)
    f.guildDrop:SetShown(all and self:Category() == CATEGORY_HEAD)
    f.categoryDrop:SetShown(not home)
    f.rewardButton:SetShown(self.tab == TAB_YOURS)
    f.reward:SetShown(self.rewardOpen and self.tab == TAB_YOURS or false)

    if not home then
        f.categoryDrop:SetEntries({
            { value = CATEGORY_HEAD, label = Global("HEADHUNTING_REWARD_FOR_HEADS", "Награда за головы") },
            { value = CATEGORY_GUILD, label = Global("HEADHUNTING_REWARD_FOR_GUILDS", "Награда за гильдии") },
        })
        f.categoryDrop:SetValue(self:Category())
    end

    if all then
        f.statusDrop:SetEntries({
            { value = FILTER_ALL_ONLINE, label = Global("HEADHUNTING_FILTER_STATUS_SHOW_ALL", "Все") },
            { value = FILTER_ONLY_ONLINE, label = Global("HEADHUNTING_FILTER_STATUS_ONLY_ONLINE", "Только в сети") },
            { value = FILTER_ONLY_OFFLINE, label = Global("HEADHUNTING_FILTER_STATUS_ONLY_OFFLINE", "Только не в сети") },
        })
        f.statusDrop:SetValue(bit.band(self.filterFlags or 0, FILTER_ONLY_ONLINE) ~= 0 and FILTER_ONLY_ONLINE
            or bit.band(self.filterFlags or 0, FILTER_ONLY_OFFLINE) ~= 0 and FILTER_ONLY_OFFLINE
            or FILTER_ALL_ONLINE)

        f.guildDrop:SetEntries({
            { value = FILTER_ALL_GUILD_CONTRACTS, label = Global("HEADHUNTING_FILTER_HAS_GUILD_CONTRACTS_SHOW_ALL", "Все") },
            { value = FILTER_ONLY_GUILD_CONTRACTS, label = Global("HEADHUNTING_FILTER_ONLY_GUILD_CONTRACTS", "С розыском гильдии") },
            { value = FILTER_ONLY_WITHOUT_GUILD_CONTRACTS, label = Global("HEADHUNTING_FILTER_ONLY_WITHOUT_GUILD_CONTRACTS", "Без розыска гильдии") },
        })
        f.guildDrop:SetValue(bit.band(self.filterFlags or 0, FILTER_ONLY_GUILD_CONTRACTS) ~= 0 and FILTER_ONLY_GUILD_CONTRACTS
            or bit.band(self.filterFlags or 0, FILTER_ONLY_WITHOUT_GUILD_CONTRACTS) ~= 0 and FILTER_ONLY_WITHOUT_GUILD_CONTRACTS
            or FILTER_ALL_GUILD_CONTRACTS)
    end

    if home then
        self:UpdateSuggest()
    else
        for _, row in ipairs(f.suggestRows) do row:Hide() end
        self:UpdateBody()
        self:UpdateReward()
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self.frame:Show()
    self:Request()
    self:Update()
end

function Panel:Hide()
    if not self.frame then return end
    self.rewardOpen = nil
    self.frame:Hide()
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.HeadHuntingPanel = Panel
