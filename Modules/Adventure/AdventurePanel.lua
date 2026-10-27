local addonName, NS = ...
local L = NS.L

local Panel = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local BOSS_DEFAULT = "Interface\\EncounterJournal\\UI-EJ-BOSS-Default"

local PANEL_W = 900
local PANEL_H = 620
local PAD = 18
local BODY_TOP = 112
local BODY_BOTTOM = 46
local BODY_H = PANEL_H - BODY_TOP - BODY_BOTTOM
local LIST_W = 252
local SCROLL_W = 8
local CARD_COLUMNS = 4
local CARD_GAP = 8
local CARD_W = math.floor((PANEL_W - PAD * 2 - 16 - SCROLL_W - (CARD_COLUMNS - 1) * CARD_GAP) / CARD_COLUMNS)
local CARD_H = math.floor(CARD_W * 96 / 174)
local CARD_ROWS = math.max(1, math.floor((BODY_H - 16 + CARD_GAP) / (CARD_H + CARD_GAP)))
local CARD_TEX_RIGHT = 0.68359375
local CARD_TEX_BOTTOM = 0.7421875
local BOSS_ROWS = 12
local SECTION_ROWS = 12
local LOOT_ROWS = 9
local CREATURE_MAX = 9
local SUGGEST_ROWS = 3
local SUGGEST_PRIMARY_W = 340
local SUGGEST_SECONDARY_H = math.floor((BODY_H - 16 - 8) / 2)
local SUGGEST_SECONDARY_W = PANEL_W - PAD * 2 - SUGGEST_PRIMARY_W - 24
local SUGGEST_REWARDS = 5
local SET_H = 44
local SET_GAP = 6
local SET_ROWS = math.max(1, math.floor((BODY_H - 16 + SET_GAP) / (SET_H + SET_GAP)))
local SET_ITEMS = 12
local SET_ITEM_X = 400

local DIFFICULTIES = {
    { size = "5", prefix = "PLAYER_DIFFICULTY1", difficultyID = 1 },
    { size = "5", prefix = "PLAYER_DIFFICULTY2", difficultyID = 2 },
    { size = "5", prefix = "PLAYER_DIFFICULTY3", difficultyID = 3 },
    { size = "10", prefix = "PLAYER_DIFFICULTY1", difficultyID = 1, raid = true },
    { size = "25", prefix = "PLAYER_DIFFICULTY1", difficultyID = 2, raid = true },
    { size = "10", prefix = "PLAYER_DIFFICULTY2", difficultyID = 3, raid = true },
    { size = "25", prefix = "PLAYER_DIFFICULTY2", difficultyID = 4, raid = true },
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

    return frame
end

local function ScrollBar(parent, onScroll)
    local S = NS.Styling

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetWidth(SCROLL_W)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -8)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 8)

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

    thumb:SetScript("OnEnter", function() fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9) end)
    thumb:SetScript("OnLeave", function() fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55) end)

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
        local value = math.floor(self.grabOffset + moved / span * range + 0.5)
        value = math.max(0, math.min(range, value))

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

local function Available()
    return EJ_GetNumTiers and EJ_GetInstanceByIndex
end

function Panel:Tiers()
    local list = {}

    for index = 1, (EJ_GetNumTiers() or 0) do
        local name = EJ_GetTierInfo(index)
        if name then list[#list + 1] = { value = index, label = name } end
    end

    return list
end

function Panel:Instances()
    local list = {}
    local isRaid = self.tab == "raids"
    local index = 1

    while true do
        local instanceID, name, description, _, buttonImage, _, _, _, link, _, mapID =
            EJ_GetInstanceByIndex(index, isRaid)

        if not instanceID then break end

        local isOpen, isActual, minItemLevel, maxItemLevel = true, true, 0, 0
        if C_EncounterJournal and C_EncounterJournal.GetInstanceInfoEx then
            local ok, open, actual, minLevel, maxLevel =
                pcall(C_EncounterJournal.GetInstanceInfoEx, instanceID)
            if ok then
                isOpen, isActual, minItemLevel, maxItemLevel = open, actual, minLevel or 0, maxLevel or 0
            end
        end

        local hasRequirements, requirements
        if C_EncounterJournal and C_EncounterJournal.GetInstanceRequirementsEx then
            local ok, has, list = pcall(C_EncounterJournal.GetInstanceRequirementsEx, instanceID)
            if ok then hasRequirements, requirements = has, list end
        end

        local currencyItemID
        if isOpen and C_EncounterJournal and C_EncounterJournal.GetInstanceCurrencyReward then
            local ok, itemID = pcall(C_EncounterJournal.GetInstanceCurrencyReward, instanceID)
            if ok then currencyItemID = itemID end
        end

        list[#list + 1] = {
            id = instanceID,
            name = name,
            description = description,
            image = buttonImage,
            link = link,
            mapID = mapID,
            isOpen = isOpen,
            isActual = isActual,
            minItemLevel = minItemLevel,
            maxItemLevel = maxItemLevel,
            hasRequirements = hasRequirements,
            requirements = requirements,
            currencyItemID = currencyItemID,
            isRaid = isRaid,
        }

        index = index + 1
    end

    return list
end

function Panel:Suggestions()
    local list = {}
    if not C_AdventureJournal or not C_AdventureJournal.GetSuggestions then return list end

    pcall(C_AdventureJournal.UpdateSuggestions)

    local buffer = {}
    if not pcall(C_AdventureJournal.GetSuggestions, buffer) then return list end

    for index, entry in ipairs(buffer) do
        entry.index = index

        local ok, reward = pcall(C_AdventureJournal.GetReward, index)
        entry.reward = ok and reward or nil

        list[#list + 1] = entry
    end

    return list
end

function Panel:SuggestionRewards(entry)
    local list = {}
    local reward = entry and entry.reward
    if not reward then return list end

    if reward.isRewardList then
        for index = 1, SUGGEST_REWARDS do
            local item = reward[index]
            if not item then break end
            list[#list + 1] = { icon = item.itemIcon, link = item.itemLink }
        end
        return list
    end

    list[1] = {
        icon = reward.itemIcon or reward.currencyIcon,
        link = reward.itemLink,
        text = reward.rewardDesc,
    }

    return list
end

function Panel:ItemSets()
    local list = {}
    if not C_LootJournal or not C_LootJournal.GenerateLootData then return list end

    if not pcall(C_LootJournal.GenerateLootData, self.setClass or 0, self.setSpec or 0) then
        return list
    end

    for index = 1, (C_LootJournal.GetNumItemSets() or 0) do
        local setIndex, name, tierName, itemLevel, sourceText, isPVP, items, numItems =
            C_LootJournal.GetItemSetInfo(index)

        if not name then break end

        list[#list + 1] = {
            setIndex = setIndex,
            name = name,
            tierName = tierName,
            itemLevel = itemLevel,
            source = sourceText,
            isPVP = isPVP,
            items = items,
            numItems = numItems or 0,
        }
    end

    return list
end

function Panel:SetClassOptions()
    local list = { { value = 0, label = Global("ALL_CLASSES", "Все классы") } }

    for index = 1, (GetNumClasses and GetNumClasses() or 0) do
        local name, _, classID = GetClassInfo(index)
        if name and classID and classID ~= 10 then
            list[#list + 1] = { value = classID, label = name }
        end
    end

    return list
end

function Panel:SetSpecOptions()
    local list = { { value = 0, label = Global("ALL_SPECS", "Все специализации") } }

    local classID = self.setClass or 0
    if classID == 0 or not GetNumSpecializationsForClassID then return list end

    for index = 1, (GetNumSpecializationsForClassID(classID) or 0) do
        local _, name = GetSpecializationInfoForClassID(classID, index)
        if name then list[#list + 1] = { value = index, label = name } end
    end

    return list
end

function Panel:Encounters()
    local list = {}
    local index = 1

    while true do
        local name, description, bossID, rootSectionID, link = EJ_GetEncounterInfoByIndex(index)
        if not bossID then break end

        local _, _, _, _, image = EJ_GetCreatureInfo(1, bossID)

        list[#list + 1] = {
            id = bossID,
            name = name,
            description = description,
            rootSectionID = rootSectionID,
            link = link,
            image = image or BOSS_DEFAULT,
        }

        index = index + 1
    end

    return list
end

function Panel:Sections()
    local list = {}
    if not self.encounterID then return list end

    local _, _, _, rootSectionID = EJ_GetEncounterInfo(self.encounterID)
    if not rootSectionID or rootSectionID == 0 then return list end

    self.expandedSections = self.expandedSections or {}

    local function Walk(sectionID, depth)
        while sectionID and sectionID ~= 0 do
            local title, description, headerType, abilityIcon, displayInfo, siblingID, childID,
                _, link, startsOpen = EJ_GetSectionInfo(sectionID)

            if not title then return end

            if self.expandedSections[sectionID] == nil and startsOpen then
                self.expandedSections[sectionID] = true
            end

            list[#list + 1] = {
                id = sectionID,
                title = title,
                description = description,
                icon = abilityIcon,
                displayInfo = displayInfo,
                depth = depth,
                link = link,
                hasChildren = childID and childID ~= 0,
            }

            if childID and childID ~= 0 and self.expandedSections[sectionID] then
                Walk(childID, depth + 1)
            end

            sectionID = siblingID
        end
    end

    Walk(rootSectionID, 0)

    return list
end

function Panel:Creatures()
    local list = {}
    if not self.encounterID then return list end

    for index = 1, CREATURE_MAX do
        local id, name, description, displayInfo = EJ_GetCreatureInfo(index, self.encounterID)
        if not id then break end
        list[#list + 1] = { id = id, name = name, description = description, displayInfo = displayInfo }
    end

    return list
end

function Panel:Loot()
    local list = {}

    for index = 1, (EJ_GetNumLoot() or 0) do
        local itemID, encounterID, name, icon, slot, armorType, link = EJ_GetLootInfoByIndex(index)
        list[#list + 1] = {
            itemID = itemID,
            encounterID = encounterID,
            name = name,
            icon = icon,
            slot = slot,
            armorType = armorType,
            link = link,
        }
    end

    return list
end

function Panel:DifficultyOptions()
    local list = {}
    if not self.instanceID then return list end

    local isRaid = EJ_InstanceIsRaidByID and EJ_InstanceIsRaidByID(self.instanceID)

    for _, entry in ipairs(DIFFICULTIES) do
        local matchesKind = (entry.raid and true or false) == (isRaid and true or false)
        if matchesKind and EJ_IsValidInstanceDifficulty(entry.difficultyID) then
            local prefix = Global(entry.prefix, "Режим")
            local label = entry.raid and string.format("(%s) %s", entry.size, prefix) or prefix
            list[#list + 1] = { value = entry.difficultyID, label = label }
        end
    end

    return list
end

function Panel:SelectInstance(instanceID)
    self.instanceID = instanceID
    self.encounterID = nil
    self.view = "instance"
    self.infoTab = self.infoTab or "sections"
    self.sectionOffset = 0
    self.lootOffset = 0
    self.expandedSections = {}

    if EJ_InstanceIsRaidByID then
        self.tab = EJ_InstanceIsRaidByID(instanceID) and "raids" or "dungeons"
    end

    EJ_SelectInstance(instanceID)
    self:Update()
end

function Panel:SelectEncounter(encounterID)
    self.encounterID = encounterID
    self.sectionOffset = 0
    self.lootOffset = 0
    self.expandedSections = {}

    if encounterID then
        EJ_SelectEncounter(encounterID)
    elseif self.instanceID then
        EJ_SelectInstance(self.instanceID)
    end

    local creatures = self:Creatures()
    self.creatureIndex = creatures[1] and 1 or nil

    self:Update()
end

function Panel:BackToList()
    self.view = "list"
    self.instanceID = nil
    self.encounterID = nil
    self:Update()
end

function Panel:SetSearch(text)
    self.searchText = text or ""

    if self.searchText == "" then
        if EJ_ClearSearch then EJ_ClearSearch() end
        self.searching = false
        self:Update()
        return
    end

    if not EJ_SetSearch then return end

    EJ_SetSearch(self.searchText)
    self.searching = true
    self.searchOffset = 0
    self:Update()
end

function Panel:SearchResults()
    local list = {}
    if not EJ_GetNumSearchResults then return list end

    for index = 1, math.min(EJ_GetNumSearchResults() or 0, 100) do
        local id, stype, _, instanceID, encounterID, itemLink = EJ_GetSearchResult(index)
        list[#list + 1] = {
            id = id,
            stype = stype,
            instanceID = instanceID,
            encounterID = encounterID,
            link = itemLink,
        }
    end

    return list
end

function Panel:RequirementTooltip(anchor)
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:SetText(Global("EJ_INSTANCE_REQUIREMENT_LABLE", "Требования:"), 1, 1, 1)

    if anchor.isRaid and anchor.mapID ~= 1 and anchor.mapID ~= 10009 then
        GameTooltip:AddLine(Global("EJ_INSTANCE_REQUIREMENT_RAID_GROUP",
            "Для входа требуется быть участником рейдовой группы"), 1, 1, 1, true)
    else
        GameTooltip:AddLine(Global("EJ_INSTANCE_REQUIREMENT_NONE", "Вход свободный"), 1, 1, 1, true)
    end

    local level = UnitLevel("player") or 1
    local averageItemLevel = GetAverageItemLevel and GetAverageItemLevel() or 0

    for _, requirement in ipairs(anchor.requirements or {}) do
        GameTooltip:AddLine(" ")

        local prefix, size = EJ_GetDifficultyInfo(requirement.difficultyID, requirement.isRaid)
        local difficulty = prefix and string.format("(%s) %s", size, prefix)
            or tostring(requirement.difficultyID)

        GameTooltip:AddLine(string.format(
            Global("EJ_INSTANCE_REQUIREMENT_DIFFICULTY", "Сложность: %s"), difficulty), 1, 0.82, 0)

        if requirement.minLevel and requirement.maxLevel then
            local done = level >= requirement.minLevel and level <= requirement.maxLevel
            local r, g, b = done and 0.1 or 1, done and 1 or 1, done and 0.1 or 1

            if requirement.minLevel == requirement.maxLevel then
                GameTooltip:AddLine(string.format(
                    Global("EJ_INSTANCE_REQUIREMENT_LEVEL", "Уровень: %s"), requirement.maxLevel), r, g, b)
            else
                GameTooltip:AddLine(string.format(
                    Global("EJ_INSTANCE_REQUIREMENT_LEVEL_RANGE", "Уровень: %s-%s"),
                    requirement.minLevel, requirement.maxLevel), r, g, b)
            end
        end

        if requirement.itemLevel then
            local done = averageItemLevel >= requirement.itemLevel
            GameTooltip:AddLine(string.format(
                Global("EJ_INSTANCE_REQUIREMENT_ITEM_LEVEL", "Средний уровень предметов: %s"),
                requirement.itemLevel), done and 0.1 or 1, 1, done and 0.1 or 1)
        end

        if requirement.quests then
            GameTooltip:AddLine(Global("EJ_INSTANCE_REQUIREMENT_QUESTS", "Задания:"), 1, 0.82, 0)

            for _, questID in ipairs(requirement.quests) do
                local done = IsQuestCompleted and IsQuestCompleted(questID)
                local name = GetTitleForQuestID and GetTitleForQuestID(questID)
                if not name and RequestLoadQuestByID then pcall(RequestLoadQuestByID, questID) end
                GameTooltip:AddLine(name or Global("UNKNOWN", "Неизвестно"),
                    done and 0.1 or 1, 1, done and 0.1 or 1, true)
            end
        end

        if requirement.achievements then
            GameTooltip:AddLine(Global("EJ_INSTANCE_REQUIREMENT_ACHIEVEMENTS", "Достижения:"), 1, 0.82, 0)

            for _, achievementID in ipairs(requirement.achievements) do
                local _, name, _, done = GetAchievementInfo(achievementID)
                GameTooltip:AddLine(name or Global("UNKNOWN", "Неизвестно"),
                    done and 0.1 or 1, 1, done and 0.1 or 1, true)
            end
        end
    end

    GameTooltip:Show()
end

function Panel:CreateCard(parent, index)
    local S = NS.Styling

    local column = (index - 1) % CARD_COLUMNS
    local row = math.floor((index - 1) / CARD_COLUMNS)

    local card = CreateFrame("Button", nil, parent)
    card:SetSize(CARD_W, CARD_H)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT",
        8 + column * (CARD_W + CARD_GAP), -8 - row * (CARD_H + CARD_GAP))

    local image = card:CreateTexture(nil, "BACKGROUND")
    image:SetAllPoints()
    image:SetTexCoord(0, CARD_TEX_RIGHT, 0, CARD_TEX_BOTTOM)
    card.image = image

    local shade = card:CreateTexture(nil, "ARTWORK")
    shade:SetAllPoints()
    shade:SetTexture(WHITE)
    shade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.85, 0, 0, 0, 0.10)

    local dim = card:CreateTexture(nil, "OVERLAY")
    dim:SetAllPoints()
    dim:SetTexture(WHITE)
    dim:SetVertexColor(0, 0, 0, 0.5)
    dim:Hide()
    card.dim = dim

    local border = CreateFrame("Frame", nil, card)
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    card.border = border

    local name = card:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    name:SetPoint("TOP", card, "TOP", 0, -10)
    name:SetWidth(CARD_W - 22)
    name:SetJustifyH("CENTER")
    card.name = name

    local itemLevel = card:CreateFontString(nil, "OVERLAY")
    itemLevel:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    itemLevel:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 7)
    card.itemLevel = itemLevel

    local currency = CreateFrame("Button", nil, card)
    currency:SetSize(22, 22)
    currency:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 6)

    local currencyIcon = currency:CreateTexture(nil, "OVERLAY")
    currencyIcon:SetAllPoints()
    currencyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    currency.icon = currencyIcon

    local currencyBorder = CreateFrame("Frame", nil, currency)
    currencyBorder:SetAllPoints()
    currencyBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    currencyBorder:SetBackdropBorderColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.8)
    currencyBorder:EnableMouse(false)

    currency:SetScript("OnEnter", function(self)
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    currency:SetScript("OnLeave", function() GameTooltip:Hide() end)
    currency:SetScript("OnClick", function(self)
        if self.link then HandleModifiedItemClick(self.link) end
    end)
    currency:Hide()
    card.currency = currency

    local requirements = CreateFrame("Frame", nil, card)
    requirements:SetSize(18, 18)
    requirements:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -6)
    requirements:EnableMouse(true)

    local mark = requirements:CreateFontString(nil, "OVERLAY")
    mark:SetFont(NS.FONT, NS.FS(15), "OUTLINE")
    mark:SetPoint("CENTER")
    mark:SetText("!")
    requirements.mark = mark

    requirements:SetScript("OnEnter", function(self)
        Panel:RequirementTooltip(self)
    end)
    requirements:SetScript("OnLeave", function() GameTooltip:Hide() end)
    requirements:Hide()
    card.requirementsIcon = requirements

    local closed = card:CreateFontString(nil, "OVERLAY")
    closed:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    closed:SetTextColor(0.9, 0.35, 0.35)
    closed:SetPoint("CENTER", card, "CENTER", 0, 0)
    closed:SetText(L["закрыто"])
    closed:Hide()
    card.closed = closed

    card:SetScript("OnEnter", function(self)
        self.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        if not self.instanceID then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.name:GetText() or "", 1, 1, 1)
        if self.description then GameTooltip:AddLine(self.description, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function(self)
        self.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        GameTooltip:Hide()
    end)
    card:SetScript("OnClick", function(self)
        if self.instanceID then Panel:SelectInstance(self.instanceID) end
    end)

    card:Hide()
    return card
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
        if not row.suggestionIndex then return end
        pcall(C_AdventureJournal.ActivateEntry, row.suggestionIndex)
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

        action:SetPoint("TOP", description, "BOTTOM", 0, -14)
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

    row.rewards = {}
    for slot = 1, SUGGEST_REWARDS do
        local reward = CreateFrame("Button", nil, row)
        reward:SetSize(24, 24)

        local rewardIcon = reward:CreateTexture(nil, "ARTWORK")
        rewardIcon:SetAllPoints()
        rewardIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        reward.icon = rewardIcon

        local rewardBorder = CreateFrame("Frame", nil, reward)
        rewardBorder:SetAllPoints()
        rewardBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        rewardBorder:SetBackdropBorderColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.7)
        rewardBorder:EnableMouse(false)

        reward:SetScript("OnEnter", function(self)
            if self.link then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.link)
                GameTooltip:Show()
            elseif self.text then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.text, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        reward:SetScript("OnLeave", function() GameTooltip:Hide() end)
        reward:SetScript("OnClick", function(self)
            if self.link then HandleModifiedItemClick(self.link) end
        end)
        reward:Hide()

        row.rewards[slot] = reward
    end

    if primary then
        local prev = NS.Widgets.CreateThemedButton(row, "<", 26, 22, function()
            if not C_AdventureJournal then return end
            local offset = C_AdventureJournal.GetPrimaryOffset() or 0
            if offset > 0 then
                pcall(C_AdventureJournal.SetPrimaryOffset, offset - 1)
                Panel:Update()
            end
        end)
        prev:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 14, 14)
        row.prev = prev

        local forward = NS.Widgets.CreateThemedButton(row, ">", 26, 22, function()
            if not C_AdventureJournal then return end
            local offset = C_AdventureJournal.GetPrimaryOffset() or 0
            if offset < (C_AdventureJournal.GetNumAvailableSuggestions() or 1) - 1 then
                pcall(C_AdventureJournal.SetPrimaryOffset, offset + 1)
                Panel:Update()
            end
        end)
        forward:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -14, 14)
        row.forward = forward
    end

    row:Hide()
    return row
end

function Panel:CreateSetRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(SET_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8 - (index - 1) * (SET_H + SET_GAP))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8 - SCROLL_W - 4, -8 - (index - 1) * (SET_H + SET_GAP))
    row:EnableMouse(true)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

    local highlight = row:CreateTexture(nil, "BORDER")
    highlight:SetAllPoints()
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
    highlight:Hide()

    local pvp = row:CreateFontString(nil, "OVERLAY")
    pvp:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    pvp:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    pvp:SetPoint("LEFT", row, "LEFT", 8, 0)
    pvp:SetText("PvP")
    pvp:Hide()
    row.pvp = pvp

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -6)
    name:SetWidth(SET_ITEM_X - 60)
    name:SetHeight(15)
    name:SetJustifyH("LEFT")
    row.name = name

    local level = row:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(11), "")
    level:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    level:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    level:SetWidth(SET_ITEM_X - 60)
    level:SetHeight(14)
    level:SetJustifyH("LEFT")
    row.level = level

    row:SetScript("OnEnter", function(self)
        highlight:Show()
        if not self.source or self.source == "" then return end

        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(Global("LOOTJOURNAL_SOURCE_TOOLTIP_HEAD", "Способ получения:"), 1, 1, 1)
        GameTooltip:AddLine(self.source, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        highlight:Hide()
        GameTooltip:Hide()
    end)

    row.items = {}
    for slot = 1, SET_ITEMS do
        local button = CreateFrame("Button", nil, row)
        button:SetSize(26, 26)
        button:SetPoint("LEFT", row, "LEFT", SET_ITEM_X + (slot - 1) * 30, 0)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon = icon

        local border = CreateFrame("Frame", nil, button)
        border:SetAllPoints()
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        button:SetScript("OnEnter", function(self)
            if not self.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.link)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("OnClick", function(self)
            if self.link then HandleModifiedItemClick(self.link) end
        end)
        button:Hide()

        row.items[slot] = button
    end

    row:Hide()
    return row
end

function Panel:CreateBossRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(34)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * 36)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * 36)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

    local selected = row:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetTexture(WHITE)
    selected:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    selected:Hide()
    row.selected = selected

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    row:SetScript("OnClick", function(self)
        Panel:SelectEncounter(self.encounterID)
    end)

    row:Hide()
    return row
end

function Panel:CreateSectionRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("LEFT", parent, "LEFT", 8, 0)
    row:SetPoint("RIGHT", parent, "RIGHT", -8, 0)
    row:SetHeight(30)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.26 or 0.10)
    row.plate = plate

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local title = row:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(12), "")
    title:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -4)
    title:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    title:SetJustifyH("LEFT")
    row.title = title

    local description = row:CreateFontString(nil, "OVERLAY")
    description:SetFont(NS.FONT, NS.FS(11), "")
    description:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    description:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    description:SetJustifyH("LEFT")
    row.description = description

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.08)

    row:SetScript("OnClick", function(self)
        if not self.sectionID then return end
        Panel.expandedSections[self.sectionID] = not Panel.expandedSections[self.sectionID]
        Panel:Update()
    end)

    row:Hide()
    return row
end

function Panel:CreateLootRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(38)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8 - (index - 1) * 40)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -8 - (index - 1) * 40)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    name:SetJustifyH("LEFT")
    row.name = name

    local slot = row:CreateFontString(nil, "OVERLAY")
    slot:SetFont(NS.FONT, NS.FS(10), "")
    slot:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    slot:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    slot:SetJustifyH("LEFT")
    row.slot = slot

    local boss = row:CreateFontString(nil, "OVERLAY")
    boss:SetFont(NS.FONT, NS.FS(10), "")
    boss:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    boss:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 5)
    boss:SetJustifyH("RIGHT")
    row.boss = boss

    row:SetHighlightTexture(WHITE, "ADD")
    row:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)

    row:SetScript("OnEnter", function(self)
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        if self.searchResult then
            local result = self.searchResult

            if result.stype == "instance" and result.id then
                Panel.searching = false
                Panel.searchText = ""
                Panel.frame.search:SetText("")
                Panel:SelectInstance(result.id)
                return
            elseif result.instanceID then
                Panel.searching = false
                Panel.searchText = ""
                Panel.frame.search:SetText("")
                Panel:SelectInstance(result.instanceID)
                if result.encounterID or result.stype == "encounter" then
                    Panel:SelectEncounter(result.encounterID or result.id)
                end
                return
            end
        end

        if not self.link then return end

        if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(self.link)
        elseif IsModifiedClick("DRESSUP") then
            DressUpItemLink(self.link)
        end
    end)

    row:Hide()
    return row
end

function Panel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_Adventure", UIParent)
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
    title:SetText(Global("ADVENTURE", "Приключения"))

    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(11), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)
    f.subtitle = subtitle

    local close = NS.Widgets.CreateCloseButton(f, 18, function() Panel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -46)
    search:SetScript("OnTextChanged", function(self)
        Panel:SetSearch(self:GetText() or "")
    end)
    f.search = search

    S.CreateAnimatedSeparator(f, -72)

    f.tabs = {}
    local contentTabs = {
        { key = "suggest", label = Global("AJ_SUGGESTED_CONTENT_TAB", "Рекомендуемый контент") },
        { key = "dungeons", label = Global("INSTANCES", "Подземелья") },
        { key = "raids", label = Global("RAIDS", "Рейды") },
        { key = "sets", label = Global("LOOT_JOURNAL_ITEM_SETS", "Комплекты") },
    }

    local tabX = PAD
    for index, tab in ipairs(contentTabs) do
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
            Panel.setOffset = 0
            Panel:BackToList()
        end)

        button:SetPoint("TOPLEFT", f, "TOPLEFT", tabX, -84)
        tabX = tabX + button:GetWidth() + 6

        button.tabKey = tab.key
        f.tabs[index] = button
    end

    local tierDrop = NS.Widgets.CreateThemedDropdown(f, 200, function(value)
        EJ_SelectTier(value)
        Panel.offset = 0
        Panel:Update()
    end)
    tierDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -86)
    f.tierDrop = tierDrop

    local setClassDrop = NS.Widgets.CreateThemedDropdown(f, 160, function(value)
        Panel.setClass = value
        Panel.setSpec = 0
        Panel.setOffset = 0
        Panel:Update()
    end)
    setClassDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 170, -86)
    setClassDrop:Hide()
    f.setClassDrop = setClassDrop

    local setSpecDrop = NS.Widgets.CreateThemedDropdown(f, 160, function(value)
        Panel.setSpec = value
        Panel.setOffset = 0
        Panel:Update()
    end)
    setSpecDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -86)
    setSpecDrop:Hide()
    f.setSpecDrop = setSpecDrop

    local back = NS.Widgets.CreateThemedButton(f, L["к списку"], 110, 20, function()
        Panel:BackToList()
    end)
    back:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -86)
    back:Hide()
    f.back = back

    local difficulty = NS.Widgets.CreateThemedDropdown(f, 200, function(value)
        EJ_SetDifficulty(value)
        Panel:Update()
    end)
    difficulty:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -86)
    difficulty:Hide()
    f.difficulty = difficulty

    local grid = CreateFrame("Frame", nil, f)
    grid:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    grid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(grid)
    f.grid = grid

    local function ScrollList(value)
        Panel.offset = value
        Panel:Update()
    end

    grid:EnableMouseWheel(true)
    grid:SetScript("OnMouseWheel", function(_, delta)
        local rows = math.ceil(#Panel:Instances() / CARD_COLUMNS)
        if rows <= CARD_ROWS then return end
        ScrollList(math.max(0, math.min(rows - CARD_ROWS, (Panel.offset or 0) - delta)))
    end)

    f.gridScroll = ScrollBar(grid, ScrollList)

    f.cards = {}
    for index = 1, CARD_COLUMNS * CARD_ROWS do
        f.cards[index] = self:CreateCard(grid, index)
    end

    local suggest = CreateFrame("Frame", nil, f)
    suggest:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    suggest:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(suggest)
    suggest:Hide()
    f.suggest = suggest

    f.suggestRows = {}
    for index = 1, SUGGEST_ROWS do
        f.suggestRows[index] = self:CreateSuggestion(suggest, index)
    end

    local suggestEmpty = suggest:CreateFontString(nil, "OVERLAY")
    suggestEmpty:SetFont(NS.FONT, NS.FS(12), "")
    suggestEmpty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    suggestEmpty:SetPoint("TOPLEFT", suggest, "TOPLEFT", 14, -14)
    suggestEmpty:SetText(L["сейчас нет рекомендаций"])
    suggestEmpty:Hide()
    f.suggestEmpty = suggestEmpty

    local sets = CreateFrame("Frame", nil, f)
    sets:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    sets:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(sets)
    sets:Hide()
    f.sets = sets

    local function ScrollSets(value)
        Panel.setOffset = value
        Panel:Update()
    end

    sets:EnableMouseWheel(true)
    sets:SetScript("OnMouseWheel", function(_, delta)
        local total = #Panel:ItemSets()
        if total <= SET_ROWS then return end
        ScrollSets(math.max(0, math.min(total - SET_ROWS, (Panel.setOffset or 0) - delta)))
    end)

    f.setScroll = ScrollBar(sets, ScrollSets)

    f.setRows = {}
    for index = 1, SET_ROWS do
        f.setRows[index] = self:CreateSetRow(sets, index)
    end

    local setsEmpty = sets:CreateFontString(nil, "OVERLAY")
    setsEmpty:SetFont(NS.FONT, NS.FS(12), "")
    setsEmpty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    setsEmpty:SetPoint("TOPLEFT", sets, "TOPLEFT", 14, -14)
    setsEmpty:SetText(L["по этим фильтрам ничего не найдено"])
    setsEmpty:Hide()
    f.setsEmpty = setsEmpty

    local bosses = CreateFrame("Frame", nil, f)
    bosses:SetWidth(LIST_W)
    bosses:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -BODY_TOP)
    bosses:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, BODY_BOTTOM)
    Chrome(bosses)
    bosses:Hide()
    f.bosses = bosses

    f.bossRows = {}
    for index = 1, BOSS_ROWS do
        f.bossRows[index] = self:CreateBossRow(bosses, index)
    end

    local infoX = PAD + LIST_W + 14

    local infoTabs = {}
    local tabDefs = {
        { key = "sections", label = Global("ABILITIES", "Способности") },
        { key = "model", label = Global("MODEL", "Модель") },
        { key = "loot", label = Global("LOOT", "Трофеи") },
    }

    local x = infoX
    for _, def in ipairs(tabDefs) do
        local button = NS.Widgets.CreateThemedButton(f, def.label, 88, 20, function()
            Panel.infoTab = def.key
            Panel:Update()
        end)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", x, -110)
        button:Hide()
        button.tabKey = def.key
        x = x + 94
        infoTabs[#infoTabs + 1] = button
    end
    f.infoTabs = infoTabs

    local info = CreateFrame("Frame", nil, f)
    info:SetPoint("TOPLEFT", f, "TOPLEFT", infoX, -136)
    info:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, BODY_BOTTOM)
    Chrome(info)
    info:Hide()
    f.info = info

    info:EnableMouseWheel(true)
    info:SetScript("OnMouseWheel", function(_, delta)
        if Panel.infoTab == "loot" then
            local total = #Panel:Loot()
            if total <= LOOT_ROWS then return end
            Panel.lootOffset = math.max(0, math.min(total - LOOT_ROWS, (Panel.lootOffset or 0) - delta))
        elseif Panel.infoTab == "sections" then
            local total = #Panel:Sections()
            if total <= SECTION_ROWS then return end
            Panel.sectionOffset = math.max(0, math.min(total - SECTION_ROWS,
                (Panel.sectionOffset or 0) - delta))
        end
        Panel:Update()
    end)

    f.sectionRows = {}
    for index = 1, SECTION_ROWS do
        f.sectionRows[index] = self:CreateSectionRow(info, index)
    end

    f.lootRows = {}
    for index = 1, LOOT_ROWS do
        f.lootRows[index] = self:CreateLootRow(info, index)
    end

    local classDrop = NS.Widgets.CreateThemedDropdown(f, 150, function(value)
        EJ_SetLootFilter(value)
        Panel.lootOffset = 0
        Panel:Update()
    end)
    classDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - 158, -110)
    classDrop:Hide()
    f.classDrop = classDrop

    local slotDrop = NS.Widgets.CreateThemedDropdown(f, 150, function(value)
        if value == 0 then
            C_EncounterJournal.ResetSlotFilter()
        else
            C_EncounterJournal.SetSlotFilter(value)
        end
        Panel.lootOffset = 0
        Panel:Update()
    end)
    slotDrop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -110)
    slotDrop:Hide()
    f.slotDrop = slotDrop

    local model = CreateFrame("PlayerModel", nil, info)
    model:SetPoint("TOPLEFT", info, "TOPLEFT", 6, -6)
    model:SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", -6, 46)
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self) self.rotating = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.rotating = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.rotating then return end
        local cursor = GetCursorPosition()
        local delta = (cursor - self.rotating) * 0.02
        self.rotating = cursor
        self.facing = (self.facing or 0) + delta
        self:SetFacing(self.facing)
    end)
    model:Hide()
    f.model = model

    f.creatureButtons = {}
    for index = 1, CREATURE_MAX do
        local button = NS.Widgets.CreateThemedButton(f.info, "", 96, 20, function()
            Panel.creatureIndex = index
            Panel:Update()
        end)
        button:SetPoint("BOTTOMLEFT", f.info, "BOTTOMLEFT", 8 + ((index - 1) % 5) * 102,
            8 + math.floor((index - 1) / 5) * 24)
        button:Hide()
        f.creatureButtons[index] = button
    end

    local empty = info:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(12), "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOPLEFT", info, "TOPLEFT", 14, -14)
    empty:SetWidth(400)
    empty:SetJustifyH("LEFT")
    empty:Hide()
    f.empty = empty

    local events = CreateFrame("Frame")
    events:RegisterEvent("EJ_LOOT_DATA_RECIEVED")
    events:RegisterEvent("EJ_DIFFICULTY_UPDATE")
    events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    events:SetScript("OnEvent", function(_, event)
        if not Panel.frame or not Panel.frame:IsShown() then return end

        if event == "GET_ITEM_INFO_RECEIVED" then
            if Panel.itemRefresh then return end
            Panel.itemRefresh = true
            NS.After(0.4, function()
                Panel.itemRefresh = nil
                if Panel.frame and Panel.frame:IsShown() then Panel:Update() end
            end)
            return
        end

        Panel:Update()
    end)

    if events.RegisterCustomEvent then
        pcall(events.RegisterCustomEvent, events, "AJ_REFRESH_DISPLAY")
        pcall(events.RegisterCustomEvent, events, "AJ_REWARD_DATA_RECEIVED")
    end

    f.events = events

    if NS.CreateJournalTabs then
        f.journalTabs = NS.CreateJournalTabs(f, "adventure")
    end

    tinsert(UISpecialFrames, "NarcissusSirus_Adventure")

    self.frame = f
    self.tab = self.tab or "suggest"
    self.view = "list"
    self.infoTab = self.infoTab or "sections"
    self.offset = 0
    self.sectionOffset = 0
    self.lootOffset = 0
    self.searchOffset = 0
    self.setOffset = 0

    if not self.setClass then
        local _, _, classID = UnitClass("player")
        self.setClass = classID or 0
        self.setSpec = C_Talent and C_Talent.GetCurrentSpecTabIndex
            and C_Talent.GetCurrentSpecTabIndex() or 0
    end

    f:Hide()
end

function Panel:ClassOptions()
    local list = { { value = 0, label = Global("ALL_CLASSES", "Все классы") } }

    for index = 1, (GetNumClasses and GetNumClasses() or 0) do
        local name, _, classID = GetClassInfo(index)
        if name and classID then
            list[#list + 1] = { value = classID, label = name }
        end
    end

    return list
end

function Panel:SlotOptions()
    local list = { { value = 0, label = Global("ALL_INVENTORY_SLOTS", "Все слоты") } }

    if C_EncounterJournal and C_EncounterJournal.GetNumSlotFilters then
        for index = 1, (C_EncounterJournal.GetNumSlotFilters() or 0) do
            local invType, invTypeName = C_EncounterJournal.GetSlotFilterInfo(index)
            if invTypeName then
                list[#list + 1] = { value = invType, label = invTypeName }
            end
        end
    end

    return list
end

function Panel:UpdateList()
    local f = self.frame
    local instances = self:Instances()
    local perPage = CARD_COLUMNS * CARD_ROWS
    local rows = math.ceil(#instances / CARD_COLUMNS)
    local rowOffset = math.max(0, math.min(self.offset or 0, math.max(0, rows - CARD_ROWS)))
    self.offset = rowOffset

    local offset = rowOffset * CARD_COLUMNS

    for index = 1, perPage do
        local card = f.cards[index]
        local instance = instances[index + offset]

        if instance then
            card.instanceID = instance.id
            card.description = instance.description

            if instance.image then
                card.image:SetTexture(instance.image)
                card.image:SetTexCoord(0, CARD_TEX_RIGHT, 0, CARD_TEX_BOTTOM)
            else
                card.image:SetTexture(WHITE)
                card.image:SetTexCoord(0, 1, 0, 1)
                card.image:SetVertexColor(0.08, 0.09, 0.12, 1)
            end

            if instance.image then card.image:SetVertexColor(1, 1, 1, 1) end
            card.image:SetDesaturated(not instance.isOpen)
            card.dim:SetShown(not instance.isOpen)
            card.name:SetText(instance.name or "")
            card.closed:SetShown(not instance.isOpen)

            if instance.minItemLevel and instance.minItemLevel > 0 and instance.isOpen then
                if instance.minItemLevel == instance.maxItemLevel then
                    card.itemLevel:SetText(instance.minItemLevel)
                else
                    card.itemLevel:SetFormattedText("%d - %d", instance.minItemLevel, instance.maxItemLevel)
                end
                card.itemLevel:SetTextColor(instance.isActual and 1 or 0.5,
                    instance.isActual and 0.82 or 0.5, instance.isActual and 0 or 0.5)
            else
                card.itemLevel:SetText("")
            end

            if instance.currencyItemID then
                local _, link, _, _, _, _, _, _, _, icon = GetItemInfo(instance.currencyItemID)
                card.currency.link = link
                card.currency.icon:SetTexture(icon or QUESTION)
                card.currency:Show()
            else
                card.currency.link = nil
                card.currency:Hide()
            end

            local marker = card.requirementsIcon
            marker.requirements = instance.hasRequirements and instance.requirements or nil
            marker.isRaid = instance.isRaid
            marker.mapID = instance.mapID
            marker.mark:SetTextColor(instance.hasRequirements and 1 or 0.7,
                instance.hasRequirements and 0.82 or 0.7, instance.hasRequirements and 0 or 0.7)
            marker:SetShown(instance.isRaid and true or false)

            card:Show()
        else
            card.instanceID = nil
            card:Hide()
        end
    end

    f.gridScroll:SetState(rows, CARD_ROWS, rowOffset)
    f.subtitle:SetText(self.tab == "raids" and Global("RAIDS", "Рейды")
        or Global("INSTANCES", "Подземелья"))
end

function Panel:UpdateSuggest()
    local f = self.frame
    local suggestions = self:Suggestions()

    f.subtitle:SetText(Global("AJ_SUGGESTED_CONTENT_TAB", "Рекомендуемый контент"))
    f.suggestEmpty:SetShown(#suggestions == 0)

    local offset = C_AdventureJournal and C_AdventureJournal.GetPrimaryOffset
        and C_AdventureJournal.GetPrimaryOffset() or 0
    local available = C_AdventureJournal and C_AdventureJournal.GetNumAvailableSuggestions
        and C_AdventureJournal.GetNumAvailableSuggestions() or 0

    for index = 1, SUGGEST_ROWS do
        local row = f.suggestRows[index]
        local entry = suggestions[index]

        if entry then
            row.suggestionIndex = entry.index
            row.icon:SetTexture(entry.iconPath or QUESTION)
            row.title:SetText(entry.title or "")
            row.description:SetText(entry.description or "")

            if entry.buttonText and entry.buttonText ~= "" then
                row.action:SetText(entry.buttonText)
                row.action:Show()
            else
                row.action:Hide()
            end

            local rewards = self:SuggestionRewards(entry)
            local count = 0

            for slot, reward in ipairs(row.rewards) do
                local data = rewards[slot]
                if data and (data.icon or data.link) then
                    reward.link = data.link
                    reward.text = data.text
                    reward.icon:SetTexture(data.icon or QUESTION)
                    reward:Show()
                    count = count + 1
                else
                    reward.link = nil
                    reward:Hide()
                end
            end

            local titleHeight = row.title:GetStringHeight() or 14
            local textHeight = row.description:GetStringHeight() or 0
            local actionHeight = row.action:IsShown() and 36 or 0
            local rewardHeight = count > 0 and 32 or 0
            local height = row:GetHeight() or 0

            if index == 1 then
                local block = 99 + titleHeight + textHeight + actionHeight + rewardHeight
                row.iconFrame:ClearAllPoints()
                row.iconFrame:SetPoint("TOP", row, "TOP", 0,
                    -math.max(16, math.floor((height - block) / 2)))
            else
                local block = 13 + titleHeight + textHeight + actionHeight + rewardHeight
                local top = math.max(12, math.floor((height - block) / 2))

                row.title:ClearAllPoints()
                row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 82, -top)
                row.iconFrame:ClearAllPoints()
                row.iconFrame:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -top)
            end

            for slot = 1, count do
                local reward = row.rewards[slot]
                reward:ClearAllPoints()

                if slot > 1 then
                    reward:SetPoint("LEFT", row.rewards[slot - 1], "RIGHT", 4, 0)
                elseif index == 1 then
                    reward:SetPoint("TOP", row.action, "BOTTOM", -(count - 1) * 14, -10)
                else
                    reward:SetPoint("TOPLEFT", row.action, "BOTTOMLEFT", 0, -8)
                end
            end

            if row.prev then
                row.prev:SetShown(available > 1)
                row.forward:SetShown(available > 1)
                row.prev:SetAlpha(offset > 0 and 1 or 0.4)
                row.prev:EnableMouse(offset > 0)
                row.forward:SetAlpha(offset < available - 1 and 1 or 0.4)
                row.forward:EnableMouse(offset < available - 1)
            end

            row:Show()
        else
            row.suggestionIndex = nil
            row:Hide()
        end
    end
end

function Panel:UpdateSets()
    local S = NS.Styling
    local f = self.frame
    local sets = self:ItemSets()
    local offset = math.max(0, math.min(self.setOffset or 0, math.max(0, #sets - SET_ROWS)))
    self.setOffset = offset

    f.subtitle:SetText(Global("LOOT_JOURNAL_ITEM_SETS", "Комплекты"))
    f.setsEmpty:SetShown(#sets == 0)

    for index = 1, SET_ROWS do
        local row = f.setRows[index]
        local set = sets[index + offset]

        if set then
            row.source = set.source
            row.name:SetText(set.name or "")
            row.level:SetFormattedText(Global("EJ_SET_ITEM_LEVEL", "[%s] Уровень предмета: %d"),
                set.tierName or "", tonumber(set.itemLevel) or 0)
            row.pvp:SetShown(set.isPVP and true or false)

            local quality
            for slot, button in ipairs(row.items) do
                local item = set.items and set.items[slot]

                if item and slot <= set.numItems then
                    local _, link, itemQuality = GetItemInfo(item.itemID)
                    quality = quality or itemQuality
                    button.link = link
                    button.icon:SetTexture(item.icon or QUESTION)

                    if itemQuality and BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[itemQuality] then
                        local color = BAG_ITEM_QUALITY_COLORS[itemQuality]
                        button.border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
                    else
                        button.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
                    end

                    button:Show()
                else
                    button.link = nil
                    button:Hide()
                end
            end

            if quality and BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[quality] then
                local color = BAG_ITEM_QUALITY_COLORS[quality]
                row.name:SetTextColor(color.r, color.g, color.b)
            else
                row.name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            end

            row:Show()
        else
            row.source = nil
            row:Hide()
        end
    end

    f.setScroll:SetState(#sets, SET_ROWS, offset)
end

function Panel:UpdateBosses()
    local S = NS.Styling
    local f = self.frame
    local encounters = self:Encounters()

    for index = 1, BOSS_ROWS do
        local row = f.bossRows[index]

        if index == 1 then
            row.encounterID = nil
            row.icon:SetTexture("Interface\\EncounterJournal\\UI-EJ-Home-Icon")
            row.name:SetText(Global("OVERVIEW", "Обзор"))
            row.selected:SetShown(self.encounterID == nil)
            row:Show()
        else
            local encounter = encounters[index - 1]

            if encounter then
                row.encounterID = encounter.id
                row.icon:SetTexture(encounter.image)
                row.name:SetText(encounter.name or "")
                row.selected:SetShown(self.encounterID == encounter.id)
                row:Show()
            else
                row.encounterID = nil
                row:Hide()
            end
        end
    end
end

function Panel:UpdateSections()
    local f = self.frame
    local sections = self:Sections()
    local offset = math.max(0, math.min(self.sectionOffset or 0, math.max(0, #sections - SECTION_ROWS)))
    self.sectionOffset = offset

    local y = -8

    for index = 1, SECTION_ROWS do
        local row = f.sectionRows[index]
        local section = sections[index + offset]

        if section then
            row.sectionID = section.id
            row.icon:SetTexture(section.icon or QUESTION)
            row.icon:SetShown(section.icon and true or false)

            local prefix = string.rep("   ", section.depth or 0)
            local marker = section.hasChildren and (self.expandedSections[section.id] and "- " or "+ ") or ""
            row.title:SetText(prefix .. marker .. (section.title or ""))

            local showDescription = not section.hasChildren or self.expandedSections[section.id]
            if showDescription and section.description and section.description ~= "" then
                row.description:SetText(section.description)
                row.description:Show()
            else
                row.description:SetText("")
                row.description:Hide()
            end

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.info, "TOPLEFT", 8, y)
            row:SetPoint("TOPRIGHT", f.info, "TOPRIGHT", -8, y)

            local height = 26
            if row.description:IsShown() then
                height = math.max(height, 26 + row.description:GetStringHeight() + 6)
            end

            row:SetHeight(height)
            row:Show()

            y = y - height - 2
        else
            row.sectionID = nil
            row:Hide()
        end
    end

    if #sections == 0 then
        f.empty:Show()
        f.empty:SetText(self.encounterID and L["у этого босса нет описания способностей"]
            or L["выберите босса, чтобы увидеть его способности"])
    else
        f.empty:Hide()
    end
end

function Panel:UpdateModel()
    local f = self.frame
    local creatures = self:Creatures()

    if #creatures == 0 then
        f.model:Hide()
        for _, button in ipairs(f.creatureButtons) do button:Hide() end
        f.empty:Show()
        f.empty:SetText(L["для этого раздела нет модели"])
        return
    end

    f.empty:Hide()

    local index = math.max(1, math.min(self.creatureIndex or 1, #creatures))
    self.creatureIndex = index

    local creature = creatures[index]

    f.model:Show()
    if creature.displayInfo and self.shownDisplay ~= creature.displayInfo then
        f.model:SetDisplayInfo(creature.displayInfo)
        f.model.facing = 0
        self.shownDisplay = creature.displayInfo
    end

    for position, button in ipairs(f.creatureButtons) do
        local entry = creatures[position]
        if entry then
            button:SetText(entry.name or "")
            button:SetAlpha(position == index and 1 or 0.6)
            button:Show()
        else
            button:Hide()
        end
    end
end

function Panel:UpdateLoot()
    local S = NS.Styling
    local f = self.frame
    local loot = self:Loot()
    local offset = math.max(0, math.min(self.lootOffset or 0, math.max(0, #loot - LOOT_ROWS)))
    self.lootOffset = offset

    for index = 1, LOOT_ROWS do
        local row = f.lootRows[index]
        local item = loot[index + offset]

        if item then
            row.link = item.link
            row.itemID = item.itemID
            row.searchResult = nil

            row.icon:SetTexture(item.icon or QUESTION)
            row.name:SetText(item.name or Global("RETRIEVING_ITEM_INFO", "Загрузка"))

            local quality = item.link and select(3, GetItemInfo(item.link))
            if quality and BAG_ITEM_QUALITY_COLORS and BAG_ITEM_QUALITY_COLORS[quality] then
                local color = BAG_ITEM_QUALITY_COLORS[quality]
                row.name:SetTextColor(color.r, color.g, color.b)
            else
                row.name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            end

            local slotText = item.slot or ""
            if item.armorType and item.armorType ~= "" and item.armorType ~= ITEM_SUB_CLASS_15_0 then
                slotText = string.format("%s, %s", slotText, item.armorType)
            end
            row.slot:SetText(slotText)

            row.boss:SetText(item.encounterID and (EJ_GetEncounterInfo(item.encounterID) or "") or "")
            row:Show()
        else
            row.link = nil
            row:Hide()
        end
    end

    if #loot == 0 then
        f.empty:Show()
        f.empty:SetText(L["по этим фильтрам ничего не найдено"])
    else
        f.empty:Hide()
    end
end

function Panel:UpdateSearch()
    local S = NS.Styling
    local f = self.frame
    local results = self:SearchResults()
    local offset = math.max(0, math.min(self.searchOffset or 0, math.max(0, #results - LOOT_ROWS)))
    self.searchOffset = offset

    for index = 1, LOOT_ROWS do
        local row = f.lootRows[index]
        local result = results[index + offset]

        if result then
            local name, icon, link

            if result.stype == "item" then
                name = result.link and GetItemInfo(result.link)
                icon = result.link and select(10, GetItemInfo(result.link))
                link = result.link
            elseif result.stype == "encounter" then
                name = EJ_GetEncounterInfo(result.id)
                icon = "Interface\\EncounterJournal\\UI-EJ-BOSS-Default"
            elseif result.stype == "instance" then
                name = EJ_GetInstanceInfo(result.id)
                icon = "Interface\\EncounterJournal\\UI-EJ-Home-Icon"
            else
                name = EJ_GetSectionInfo(result.id)
                icon = select(4, EJ_GetSectionInfo(result.id))
            end

            row.link = link
            row.icon:SetTexture(icon or QUESTION)
            row.name:SetText(name or "")
            row.name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            row.slot:SetText(result.instanceID and (EJ_GetInstanceInfo(result.instanceID) or "") or "")
            row.boss:SetText(result.encounterID and (EJ_GetEncounterInfo(result.encounterID) or "") or "")

            row.searchResult = result
            row:Show()
        else
            row.searchResult = nil
            row:Hide()
        end
    end

    if #results == 0 then
        f.empty:Show()
        f.empty:SetText(L["ничего не найдено"])
    else
        f.empty:Hide()
    end
end

function Panel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end

    local S = NS.Styling

    if not Available() then
        f.subtitle:SetText(L["журнал приключений недоступен на этом сервере"])
        return
    end

    local searching = self.searching and self.searchText and self.searchText ~= ""
    local listView = self.view == "list" and not searching
    local instanceList = listView and (self.tab == "dungeons" or self.tab == "raids")
    local suggestView = listView and self.tab == "suggest"
    local setsView = listView and self.tab == "sets"

    for _, button in ipairs(f.tabs) do
        local active = button.tabKey == self.tab
        button:SetShown(listView)
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

    f.tierDrop:SetShown(instanceList or suggestView)
    f.setClassDrop:SetShown(setsView)
    f.setSpecDrop:SetShown(setsView)
    f.grid:SetShown(instanceList)
    f.suggest:SetShown(suggestView)
    f.sets:SetShown(setsView)
    f.back:SetShown(not listView)
    f.bosses:SetShown(not listView and not searching)
    f.info:SetShown(not listView)
    f.difficulty:SetShown(not listView and not searching)

    for _, button in ipairs(f.infoTabs) do
        button:SetShown(not listView and not searching)
        button:SetAlpha(button.tabKey == self.infoTab and 1 or 0.55)
    end

    f.classDrop:SetShown(not listView and not searching and self.infoTab == "loot")
    f.slotDrop:SetShown(not listView and not searching and self.infoTab == "loot")

    if listView then
        f.model:Hide()
        for _, row in ipairs(f.sectionRows) do row:Hide() end
        for _, row in ipairs(f.lootRows) do row:Hide() end
        for _, button in ipairs(f.creatureButtons) do button:Hide() end
        f.empty:Hide()

        if instanceList or suggestView then
            f.tierDrop:SetEntries(self:Tiers())
            f.tierDrop:SetValue(EJ_GetCurrentTier())
        end

        if instanceList then
            self:UpdateList()
        elseif suggestView then
            self:UpdateSuggest()
        else
            f.setClassDrop:SetEntries(self:SetClassOptions())
            f.setClassDrop:SetValue(self.setClass or 0)
            f.setSpecDrop:SetEntries(self:SetSpecOptions())
            f.setSpecDrop:SetValue(self.setSpec or 0)
            self:UpdateSets()
        end

        return
    end

    if searching then
        f.subtitle:SetText(string.format(L["поиск: %s"], self.searchText))
        f.model:Hide()
        for _, row in ipairs(f.sectionRows) do row:Hide() end
        for _, button in ipairs(f.creatureButtons) do button:Hide() end
        self:UpdateSearch()
        return
    end

    local instanceName = EJ_GetInstanceInfo()
    if self.encounterID then
        f.subtitle:SetFormattedText("%s - %s", instanceName or "", EJ_GetEncounterInfo(self.encounterID) or "")
    else
        f.subtitle:SetText(instanceName or "")
    end

    f.difficulty:SetEntries(self:DifficultyOptions())
    f.difficulty:SetValue(EJ_GetDifficulty and EJ_GetDifficulty() or 1)

    self:UpdateBosses()

    local sections = self.infoTab == "sections"
    local model = self.infoTab == "model"
    local loot = self.infoTab == "loot"

    f.model:SetShown(model)
    for _, button in ipairs(f.creatureButtons) do button:SetShown(model) end
    for _, row in ipairs(f.sectionRows) do row:SetShown(sections) end
    for _, row in ipairs(f.lootRows) do row:SetShown(loot) end

    if sections then
        self:UpdateSections()
    elseif model then
        self:UpdateModel()
    else
        f.classDrop:SetEntries(self:ClassOptions())
        f.classDrop:SetValue(EJ_GetLootFilter and EJ_GetLootFilter() or 0)
        f.slotDrop:SetEntries(self:SlotOptions())
        f.slotDrop:SetValue(C_EncounterJournal and C_EncounterJournal.GetSlotFilter
            and C_EncounterJournal.GetSlotFilter() or 0)
        self:UpdateLoot()
    end
end

function Panel:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if C_EncounterJournal and C_EncounterJournal.OnOpen then pcall(C_EncounterJournal.OnOpen) end

    self.frame:Show()
    self:Update()
end

function Panel:Hide()
    if not self.frame then return end

    if C_EncounterJournal and C_EncounterJournal.OnClose then pcall(C_EncounterJournal.OnClose) end

    self.frame:Hide()
end

function Panel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() then self:Hide() else self:Show() end
end

NS.AdventurePanel = Panel
