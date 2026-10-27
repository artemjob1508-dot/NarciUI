local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local STAR = "Interface\\Common\\FavoritesIcon"
local EMPTY_ICON = "Interface\\PetBattles\\MountJournalEmptyIcon"

local LIST_W = 320
local ROW_H = 44
local ROWS = 10

NS.Densify("NarcissusSirus_Collections", function(f)
    ROW_H, ROWS = NS.DensityRows(44, 10, f)
end)
local MAX_ABILITIES = 6
local RANDOM_FAVORITE_SPELL = 305495

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_MountJournal and C_MountJournal.GetNumDisplayedMounts
end

local function PickupMount(mountID)
    if not mountID then return end
    local companionIndex = C_MountJournal.GetMountCompanionIndex(mountID)
    if not companionIndex then return end
    pcall(PickupCompanion, "MOUNT", companionIndex)
end

local function PickupRandomFavorite()
    local spellName = GetSpellInfo(RANDOM_FAVORITE_SPELL)
    if spellName then pcall(PickupSpell, spellName) end
end

function Page:Categories()
    return {
        { key = "collected", label = Global("MY_COLLECTIONS", "Моя коллекция") },
        { key = "favorites", label = Global("FAVORITES", "Избранное") },
        { key = "all", label = Global("ALL_MOUNTS", "Весь транспорт") },
    }
end

function Page:ApplyCategory(key)
    if not Available() then return end

    self.category = key

    if key == "collected" and LE_MOUNT_JOURNAL_FILTER_COLLECTED then
        C_MountJournal.SetCategoryFilter(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
    elseif key == "favorites" and LE_MOUNT_JOURNAL_FILTER_FAVORITES then
        C_MountJournal.SetCategoryFilter(LE_MOUNT_JOURNAL_FILTER_FAVORITES)
    else
        C_MountJournal.ClearCategoryFilter()
    end
end

function Page:Select(displayIndex)
    local mountID, _, itemID = select(10, C_MountJournal.GetDisplayedMountInfo(displayIndex))
    self.selectedMountID = mountID
    self.selectedItemID = itemID
    self:Update()
end

function Page:ToggleFavorite(displayIndex)
    local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(displayIndex)
    if not canFavorite then return end

    C_MountJournal.SetIsFavorite(displayIndex, not isFavorite)
    self:Update()
end

function Page:FilterSpec()
    return {
        onChange = function() Page:Update() end,
        reset = function() C_MountJournal.SetDefaultFilters() end,
        sections = {
            {
                checks = {
                    {
                        text = Global("COLLECTED", "Собрано"),
                        get = function()
                            return C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED)
                        end,
                        set = function(value)
                            C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_COLLECTED, value)
                        end,
                    },
                    {
                        text = Global("NOT_COLLECTED", "Не собрано"),
                        get = function()
                            return C_MountJournal.GetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED)
                        end,
                        set = function(value)
                            C_MountJournal.SetCollectedFilterSetting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, value)
                        end,
                    },
                },
            },
            {
                title = Global("COLLECTION_MOUNT_ABILITIES", "Способности"),
                prepend = "COLLECTION_MOUNT_ABILITY_",
                num = C_MountJournal.GetNumMountAbilities,
                get = C_MountJournal.IsAbilityChecked,
                set = C_MountJournal.SetAbilityFilter,
                valid = C_MountJournal.IsValidAbilityFilter,
                all = C_MountJournal.SetAllAbilityFilters,
            },
            {
                title = Global("SOURCES", "Источники"),
                prepend = "COLLECTION_PET_SOURCE_",
                num = C_PetJournal and C_PetJournal.GetNumPetSources,
                get = C_MountJournal.IsSourceChecked,
                set = C_MountJournal.SetSourceFilter,
                valid = C_MountJournal.IsValidSourceFilter,
                all = C_MountJournal.SetAllSourceFilters,
            },
            {
                title = Global("FACTION", "Фракция"),
                prepend = "COLLECTION_MOUNT_FACTION_",
                num = function() return 4 end,
                get = C_MountJournal.IsFactionChecked,
                set = C_MountJournal.SetFactionFilter,
                valid = C_MountJournal.IsValidFactionFilter,
                all = C_MountJournal.SetAllFactionFilters,
            },
        },
    }
end

function Page:CreateRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self) PickupMount(self.mountID) end)

    local plate = row:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], index % 2 == 0 and 0.30 or 0.12)

    local selected = row:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetTexture(WHITE)
    selected:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.20)
    selected:Hide()
    row.selected = selected

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", row, "LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local iconBorder = CreateFrame("Frame", nil, row)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    iconBorder:SetBackdropBorderColor(0, 0, 0, 0.85)
    iconBorder:EnableMouse(false)

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:SetWidth(LIST_W - 110)
    name:SetJustifyH("LEFT")
    row.name = name

    local active = row:CreateTexture(nil, "OVERLAY")
    active:SetSize(16, 16)
    active:SetPoint("RIGHT", row, "RIGHT", -30, 0)
    active:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    active:Hide()
    row.active = active

    local faction = row:CreateTexture(nil, "OVERLAY")
    faction:SetSize(16, 16)
    faction:SetPoint("RIGHT", active, "LEFT", -4, 0)
    faction:Hide()
    row.faction = faction

    local favorite = CreateFrame("Button", nil, row)
    favorite:SetSize(18, 18)
    favorite:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    local star = favorite:CreateTexture(nil, "OVERLAY")
    star:SetAllPoints()
    star:SetTexture(STAR)
    favorite.star = star

    favorite:SetScript("OnClick", function(self)
        if self.displayIndex then Page:ToggleFavorite(self.displayIndex) end
    end)
    favorite:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("FAVORITES", "Избранное"))
        GameTooltip:Show()
    end)
    favorite:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.favorite = favorite

    row:SetScript("OnClick", function(self, button)
        if not self.displayIndex then return end

        if button == "RightButton" then
            Page:ToggleFavorite(self.displayIndex)
        elseif IsModifiedClick("CHATLINK") and self.spellID then
            local spellName = GetSpellInfo(self.spellID)
            if self.itemID and COLLECTION_MOUNTS_HYPERLINK_FORMAT then
                ChatEdit_InsertLink(string.format(COLLECTION_MOUNTS_HYPERLINK_FORMAT, self.itemID, spellName or ""))
            elseif spellName then
                ChatEdit_InsertLink(spellName)
            end
        else
            Page:Select(self.displayIndex)
        end
    end)

    row:SetScript("OnEnter", function(self)
        if not self.spellID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:" .. self.spellID)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row:Hide()
    return row
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome
    local Caption = panel.Caption
    local pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -64)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.category = self.category or "collected"
    self.offset = 0

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    search:SetScript("OnTextChanged", function(self)
        Page.searchText = self:GetText() or ""
        C_MountJournal.SetSearch(Page.searchText)
        Page.offset = 0
        Page:Update()
    end)
    f.search = search

    local filterPopup = panel:CreateFilterPopup("mounts", self:FilterSpec())
    local filterButton = panel:CreateFilterButton(f, filterPopup)
    filterButton:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 0)
    f.filterPopup = filterPopup
    f.filterButton = filterButton

    local picker = NS.Widgets.CreateOptionPicker(f, self:Categories(), self.category, function(key)
        Page:ApplyCategory(key)
        Page.offset = 0
        Page:Update()
    end, LIST_W)
    picker:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -28)
    f.picker = picker

    local list = CreateFrame("Frame", nil, f)
    list:SetWidth(LIST_W)
    list:SetPoint("TOPLEFT", picker, "BOTTOMLEFT", 0, -10)
    list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 30)
    Chrome(list)
    f.list = list

    f.rows = {}
    for index = 1, ROWS do
        f.rows[index] = self:CreateRow(list, index)
    end

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        local total = #Page:Visible()
        if total <= ROWS then return end
        Page.offset = math.max(0, math.min(total - ROWS, (Page.offset or 0) - delta))
        Page:Update()
    end)

    local count = f:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(11), "")
    count:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    count:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 10)
    f.count = count

    local displayX = LIST_W + 16

    local display = CreateFrame("Frame", nil, f)
    display:SetPoint("TOPLEFT", f, "TOPLEFT", displayX, 0)
    display:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 36)
    Chrome(display)
    f.display = display

    local model = CreateFrame("PlayerModel", nil, display)
    model:SetPoint("TOPLEFT", display, "TOPLEFT", 4, -4)
    model:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -4, 96)
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseDown", function(self) self.rotating = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.rotating = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.rotating then return end
        local x = GetCursorPosition()
        local delta = (x - self.rotating) * 0.02
        self.rotating = x
        self.facing = (self.facing or 0) + delta
        self:SetFacing(self.facing)
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(-2, math.min(4, (self.zoom or 0) + delta * 0.4))
        self:SetPosition(self.zoom, 0, 0)
    end)
    f.model = model

    f.abilities = {}
    for index = 1, MAX_ABILITIES do
        local button = CreateFrame("Frame", nil, display)
        button:SetSize(26, 26)
        if index == 1 then
            button:SetPoint("TOPRIGHT", display, "TOPRIGHT", -10, -10)
        else
            button:SetPoint("TOP", f.abilities[index - 1], "BOTTOM", 0, -6)
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

        button:EnableMouse(true)
        button:SetScript("OnEnter", function(self)
            if not self.abilityID then return end
            local name, _, text, description = C_MountJournal.GetAbilityInfo(self.abilityID)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(name or "", 1, 1, 1)
            if text then GameTooltip:AddLine(text, 0.55, 0.78, 0.58, true) end
            if description then GameTooltip:AddLine(description, 0.9, 0.9, 0.9, true) end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button:Hide()
        f.abilities[index] = button
    end

    local infoIcon = display:CreateTexture(nil, "ARTWORK")
    infoIcon:SetSize(38, 38)
    infoIcon:SetPoint("BOTTOMLEFT", display, "BOTTOMLEFT", 12, 52)
    infoIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.infoIcon = infoIcon

    local infoName = display:CreateFontString(nil, "OVERLAY")
    infoName:SetFont(NS.FONT, NS.FS(15), "")
    infoName:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    infoName:SetPoint("BOTTOMLEFT", infoIcon, "BOTTOMRIGHT", 10, 20)
    infoName:SetJustifyH("LEFT")
    f.infoName = infoName

    local favorite = CreateFrame("Button", nil, display)
    favorite:SetSize(20, 20)
    favorite:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -12, 66)

    local favoriteStar = favorite:CreateTexture(nil, "OVERLAY")
    favoriteStar:SetAllPoints()
    favoriteStar:SetTexture(STAR)
    favorite.star = favoriteStar

    favorite:SetScript("OnClick", function()
        if not Page.selectedMountID then return end
        local index = Page:DisplayIndexFor(Page.selectedMountID)
        if index then Page:ToggleFavorite(index) end
    end)
    f.favorite = favorite

    local source = display:CreateFontString(nil, "OVERLAY")
    source:SetFont(NS.FONT, NS.FS(11), "")
    source:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    source:SetPoint("TOPLEFT", infoIcon, "BOTTOMLEFT", 0, -6)
    source:SetWidth(500)
    source:SetJustifyH("LEFT")
    f.source = source

    local lore = display:CreateFontString(nil, "OVERLAY")
    lore:SetFont(NS.FONT, NS.FS(11), "")
    lore:SetTextColor(0.75, 0.72, 0.62)
    lore:SetPoint("TOPLEFT", source, "BOTTOMLEFT", 0, -6)
    lore:SetWidth(500)
    lore:SetJustifyH("LEFT")
    f.lore = lore

    local summon = CreateFrame("Frame", nil, f)
    summon:SetSize(220, 26)
    summon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    Chrome(summon)
    f.summonPlate = summon

    local summonLabel = summon:CreateFontString(nil, "OVERLAY")
    summonLabel:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    summonLabel:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    summonLabel:SetPoint("CENTER")
    summonLabel:SetText(Global("MOUNT", "Призвать"))
    f.summonLabel = summonLabel

    local random = CreateFrame("Frame", nil, f)
    random:SetSize(26, 26)
    random:SetPoint("BOTTOMRIGHT", summon, "BOTTOMLEFT", -8, 0)
    Chrome(random)

    local randomIcon = random:CreateTexture(nil, "ARTWORK")
    randomIcon:SetPoint("TOPLEFT", 3, -3)
    randomIcon:SetPoint("BOTTOMRIGHT", -3, 3)
    randomIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local _, _, randomTexture = GetSpellInfo(RANDOM_FAVORITE_SPELL)
    randomIcon:SetTexture(randomTexture or EMPTY_ICON)
    f.randomPlate = random

    self.summonButton = panel:SecureButton("MountSummon")
    self.randomButton = panel:SecureButton("MountRandom")

    if self.summonButton then
        self.summonButton:RegisterForDrag("LeftButton")
        self.summonButton:SetScript("OnDragStart", function()
            PickupMount(Page.selectedMountID)
        end)
    end

    if self.randomButton then
        panel:SetSecureSpell(self.randomButton, RANDOM_FAVORITE_SPELL)
        self.randomButton:RegisterForDrag("LeftButton")
        self.randomButton:SetScript("OnDragStart", PickupRandomFavorite)
        self.randomButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("spell:" .. RANDOM_FAVORITE_SPELL)
            GameTooltip:Show()
        end)
        self.randomButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("COMPANION_LEARNED")
    events:RegisterEvent("COMPANION_UNLEARNED")
    events:RegisterEvent("COMPANION_UPDATE")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        pcall(events.RegisterCustomEvent, events, "MOUNT_JOURNAL_SEARCH_UPDATED")
    end

    f.events = events
    f:Hide()

    return f
end

function Page:DisplayIndexFor(mountID)
    for index = 1, (C_MountJournal.GetNumDisplayedMounts() or 0) do
        local currentID = select(10, C_MountJournal.GetDisplayedMountInfo(index))
        if currentID == mountID then return index end
    end
end

local visible = {}

function Page:Visible()
    for key in pairs(visible) do visible[key] = nil end
    local count = C_MountJournal.GetNumDisplayedMounts() or 0
    local text = self.searchText or ""
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local needle = text ~= "" and C_MountJournal.GetCategoryFilter and C_MountJournal.GetCategoryFilter()
        and (NS.Lower and NS.Lower(text) or text:lower())
    for index = 1, count do
        if needle then
            local name = C_MountJournal.GetDisplayedMountInfo(index)
            if name and (NS.Lower and NS.Lower(name) or name:lower()):find(needle, 1, true) then
                visible[#visible + 1] = index
            end
        else
            visible[#visible + 1] = index
        end
    end
    return visible
end

function Page:UpdateList()
    local S = NS.Styling
    local f = self.frame

    local shown = self:Visible()
    local total = #shown
    local owned = C_MountJournal.GetNumMounts() or 0
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, total - ROWS)))
    self.offset = offset

    for index = 1, ROWS do
        local row = f.rows[index]
        local displayIndex = shown[index + offset]

        if displayIndex then
            local name, spellID, icon, active, _, isFavorite, isFactionSpecific, faction,
                isCollected, mountID, _, itemID = C_MountJournal.GetDisplayedMountInfo(displayIndex)

            row.displayIndex = displayIndex
            row.mountID = mountID
            row.itemID = itemID
            row.spellID = spellID

            row.icon:SetTexture(icon or EMPTY_ICON)
            row.icon:SetDesaturated(not isCollected)
            row.icon:SetAlpha(isCollected and 1 or 0.5)

            row.name:SetText(name or "")
            row.name:SetTextColor(
                isCollected and S.TEXT_BRIGHT[1] or 0.5,
                isCollected and S.TEXT_BRIGHT[2] or 0.5,
                isCollected and S.TEXT_BRIGHT[3] or 0.52)

            row.active:SetShown(active and true or false)
            row.selected:SetShown(mountID == self.selectedMountID)

            row.favorite.displayIndex = displayIndex
            row.favorite.star:SetVertexColor(1, 1, 1, isFavorite and 1 or 0.25)
            row.favorite:SetShown(isCollected and true or false)

            if isFactionSpecific and faction then
                row.faction:SetTexture(faction == 1
                    and "Interface\\PVPFrame\\PVP-Currency-Alliance"
                    or "Interface\\PVPFrame\\PVP-Currency-Horde")
                row.faction:Show()
            else
                row.faction:Hide()
            end

            row:Show()
        else
            row:Hide()
        end
    end

    f.count:SetText(string.format("%d / %d", owned, total))
end

function Page:UpdateDisplay()
    local f = self.frame
    local panel = self.panel

    local first = self:Visible()[1]
    if not self.selectedMountID and first then
        local mountID, _, itemID = select(10, C_MountJournal.GetDisplayedMountInfo(first))
        self.selectedMountID = mountID
        self.selectedItemID = itemID
    end

    if not self.selectedMountID then
        f.model:Hide()
        f.infoIcon:Hide()
        f.infoName:SetText("")
        f.source:SetText("")
        f.lore:SetText("")
        f.favorite:Hide()
        for _, button in ipairs(f.abilities) do button:Hide() end
        if self.summonButton then NS.CollectionsPanel:HideSecure(self.summonButton) end
        return
    end

    local name, spellID, icon, active, _, isFavorite, _, _, isCollected, mountID, creatureID,
        itemID, _, _, _, priceText, descriptionText, holidayText = C_MountJournal.GetMountInfoByID(self.selectedMountID)

    f.model:Show()
    if creatureID and self.shownCreature ~= creatureID then
        f.model:SetCreature(creatureID)
        f.model.facing = 0
        f.model.zoom = 0
        self.shownCreature = creatureID
    end

    f.infoIcon:SetTexture(icon)
    f.infoIcon:Show()
    f.infoName:SetText(name or "")

    local sourceText = priceText or ""
    if holidayText and holidayText ~= "" then
        sourceText = string.format("%s\n%s", holidayText, sourceText)
    end
    f.source:SetText(sourceText)
    f.lore:SetText(descriptionText or "")

    f.favorite:SetShown(isCollected and true or false)
    f.favorite.star:SetVertexColor(1, 1, 1, isFavorite and 1 or 0.25)

    local abilities = C_MountJournal.GetMountAbilitiesInfoByID(self.selectedMountID)
    for index, button in ipairs(f.abilities) do
        local abilityID = abilities and abilities[index]
        if abilityID then
            local _, abilityIcon = C_MountJournal.GetAbilityInfo(abilityID)
            button.abilityID = abilityID
            button.icon:SetTexture(abilityIcon)
            button:Show()
        else
            button:Hide()
        end
    end

    f.summonLabel:SetText(active and Global("BINDING_NAME_DISMOUNT", "Спешиться")
        or Global("MOUNT", "Призвать"))
    f.summonPlate:SetAlpha(isCollected and 1 or 0.4)

    if self.summonButton then
        if isCollected and spellID then
            panel:SetSecureSpell(self.summonButton, spellID)
            panel:PlaceSecure(self.summonButton, f.summonPlate)
        else
            panel:SetSecureSpell(self.summonButton, nil)
            panel:HideSecure(self.summonButton)
        end
    end

    if self.randomButton then
        panel:PlaceSecure(self.randomButton, f.randomPlate)
    end
end

function Page:Update()
    if not self.frame then return end

    local f = self.frame

    if not Available() then
        f.count:SetText(L["коллекция транспорта недоступна на этом сервере"])
        return
    end

    f.picker:Refresh(self.category)
    self:UpdateList()
    self:UpdateDisplay()
end

function Page:Show()
    if not self.frame then return end

    if Available() then
        self:ApplyCategory(self.category or "collected")
    end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if not self.frame then return end

    self.frame:Hide()
    if self.frame.filterPopup then self.frame.filterPopup:Hide() end
    if self.summonButton then NS.CollectionsPanel:HideSecure(self.summonButton) end
    if self.randomButton then NS.CollectionsPanel:HideSecure(self.randomButton) end
end

NS.MountCollectionPage = Page
