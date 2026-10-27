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
local RANDOM_FAVORITE_SPELL = 317619

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_PetJournal and C_PetJournal.GetNumPets
end

local function PickupPet(petID)
    if not petID then return end
    local petIndex = C_PetJournal.GetPetCompanionIndex and C_PetJournal.GetPetCompanionIndex(petID)
    if not petIndex then return end
    pcall(PickupCompanion, "CRITTER", petIndex)
end

local function PickupRandomFavorite()
    local spellName = GetSpellInfo(RANDOM_FAVORITE_SPELL)
    if spellName then pcall(PickupSpell, spellName) end
end

local function PetTypeTexture(petType)
    if PET_TYPE_SUFFIX and petType and PET_TYPE_SUFFIX[petType] then
        return "Interface\\PetBattles\\PetIcon-" .. PET_TYPE_SUFFIX[petType]
    end
    return "Interface\\PetBattles\\PetIcon-NO_TYPE"
end

function Page:SortOptions()
    return {
        { key = "name", label = Global("NAME", "Имя") },
        { key = "type", label = Global("TYPE", "Тип") },
    }
end

function Page:ApplySort(key)
    self.sort = key

    if not C_PetJournal.SetPetSortParameter then return end

    if key == "type" and LE_SORT_BY_PETTYPE then
        C_PetJournal.SetPetSortParameter(LE_SORT_BY_PETTYPE)
    elseif LE_SORT_BY_NAME then
        C_PetJournal.SetPetSortParameter(LE_SORT_BY_NAME)
    end
end

function Page:FilterSpec()
    return {
        onChange = function() Page:Update() end,
        reset = function() C_PetJournal.SetDefaultFilters() end,
        sections = {
            {
                checks = {
                    {
                        text = Global("COLLECTED", "Собрано"),
                        get = function() return C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED) end,
                        set = function(value)
                            C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, value)
                        end,
                    },
                    {
                        text = Global("NOT_COLLECTED", "Не собрано"),
                        get = function() return C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED) end,
                        set = function(value)
                            C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, value)
                        end,
                    },
                },
            },
            {
                title = Global("PET_FAMILIES", "Семейства"),
                prepend = "COLLECTION_PET_NAME_",
                num = C_PetJournal.GetNumPetTypes,
                get = C_PetJournal.IsPetTypeChecked,
                set = C_PetJournal.SetPetTypeFilter,
                all = C_PetJournal.SetAllPetTypesChecked,
            },
            {
                title = Global("SOURCES", "Источники"),
                prepend = "COLLECTION_PET_SOURCE_",
                num = C_PetJournal.GetNumPetSources,
                get = C_PetJournal.IsPetSourceChecked,
                set = C_PetJournal.SetPetSourceChecked,
                all = C_PetJournal.SetAllPetSourcesChecked,
            },
        },
    }
end

function Page:ToggleFavorite(petID)
    if not petID then return end
    C_PetJournal.SetFavorite(petID, not C_PetJournal.PetIsFavorite(petID))
    self:Update()
end

function Page:CreateRow(parent, index)
    local S = NS.Styling

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6 - (index - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6 - (index - 1) * ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self) PickupPet(self.petID) end)

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
    name:SetWidth(LIST_W - 130)
    name:SetJustifyH("LEFT")
    row.name = name

    local petType = row:CreateTexture(nil, "OVERLAY")
    petType:SetSize(20, 20)
    petType:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.petType = petType

    local active = row:CreateTexture(nil, "OVERLAY")
    active:SetSize(16, 16)
    active:SetPoint("RIGHT", row, "RIGHT", -30, 0)
    active:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    active:Hide()
    row.active = active

    local favorite = CreateFrame("Button", nil, row)
    favorite:SetSize(18, 18)
    favorite:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    local star = favorite:CreateTexture(nil, "OVERLAY")
    star:SetAllPoints()
    star:SetTexture(STAR)
    favorite.star = star

    favorite:SetScript("OnClick", function(self) Page:ToggleFavorite(self.petID) end)
    favorite:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(Global("FAVORITES", "Избранное"))
        GameTooltip:Show()
    end)
    favorite:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.favorite = favorite

    row:SetScript("OnClick", function(self, button)
        if not self.petID then return end

        if button == "RightButton" then
            if self.isCollected then Page:ToggleFavorite(self.petID) end
        elseif IsModifiedClick("CHATLINK") then
            local link = C_PetJournal.GetPetLink and C_PetJournal.GetPetLink(self.petID)
            if link then
                ChatEdit_InsertLink(link)
            elseif self.spellID then
                ChatEdit_InsertLink(GetSpellInfo(self.spellID))
            end
        else
            Page.selectedPetID = self.petID
            Page:Update()
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
    local pad = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -64)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.sort = self.sort or "name"
    self.offset = 0

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    search:SetScript("OnTextChanged", function(self)
        C_PetJournal.SetSearchFilter(self:GetText() or "")
        Page.offset = 0
        Page:Update()
    end)
    f.search = search

    local filterPopup = panel:CreateFilterPopup("pets", self:FilterSpec())
    local filterButton = panel:CreateFilterButton(f, filterPopup)
    filterButton:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 0)
    f.filterPopup = filterPopup

    local picker = NS.Widgets.CreateOptionPicker(f, self:SortOptions(), self.sort, function(key)
        Page:ApplySort(key)
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
        local total = C_PetJournal.GetNumPets() or 0
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

    local typeIcon = display:CreateTexture(nil, "OVERLAY")
    typeIcon:SetSize(22, 22)
    typeIcon:SetPoint("LEFT", infoName, "RIGHT", 8, 0)
    f.typeIcon = typeIcon

    local favorite = CreateFrame("Button", nil, display)
    favorite:SetSize(20, 20)
    favorite:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -12, 66)

    local favoriteStar = favorite:CreateTexture(nil, "OVERLAY")
    favoriteStar:SetAllPoints()
    favoriteStar:SetTexture(STAR)
    favorite.star = favoriteStar
    favorite:SetScript("OnClick", function() Page:ToggleFavorite(Page.selectedPetID) end)
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
    summonLabel:SetText(Global("SUMMON", "Призвать"))
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

    self.summonButton = panel:SecureButton("PetSummon")
    self.randomButton = panel:SecureButton("PetRandom")

    if self.summonButton then
        self.summonButton:RegisterForDrag("LeftButton")
        self.summonButton:SetScript("OnDragStart", function()
            PickupPet(Page.selectedPetID)
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
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)
    events:RegisterEvent("COMPANION_UPDATE")

    if events.RegisterCustomEvent then
        pcall(events.RegisterCustomEvent, events, "PET_JOURNAL_LIST_UPDATE")
    end

    f.events = events
    f:Hide()

    return f
end

function Page:UpdateList()
    local S = NS.Styling
    local f = self.frame

    local total, owned = C_PetJournal.GetNumPets()
    total = total or 0

    local summonedID = C_PetJournal.GetSummonedPetID and C_PetJournal.GetSummonedPetID()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, total - ROWS)))
    self.offset = offset

    for index = 1, ROWS do
        local row = f.rows[index]
        local petIndex = index + offset

        if petIndex <= total then
            local name, spellID, icon, petType, _, _, isFavorite, isCollected, petID =
                C_PetJournal.GetPetInfoByIndex(petIndex)

            row.petID = petID
            row.spellID = spellID
            row.isCollected = isCollected

            row.icon:SetTexture(icon or EMPTY_ICON)
            row.icon:SetDesaturated(not isCollected)
            row.icon:SetAlpha(isCollected and 1 or 0.5)

            row.name:SetText(name or "")
            row.name:SetTextColor(
                isCollected and S.TEXT_BRIGHT[1] or 0.5,
                isCollected and S.TEXT_BRIGHT[2] or 0.5,
                isCollected and S.TEXT_BRIGHT[3] or 0.52)

            row.petType:SetTexture(PetTypeTexture(petType))
            row.petType:SetDesaturated(not isCollected)

            row.active:SetShown(petID and summonedID and petID == summonedID)
            row.selected:SetShown(petID == self.selectedPetID)

            row.favorite.petID = petID
            row.favorite.star:SetVertexColor(1, 1, 1, isFavorite and 1 or 0.25)
            row.favorite:SetShown(isCollected and true or false)

            row:Show()
        else
            row:Hide()
        end
    end

    f.count:SetText(string.format("%d / %d", owned or 0, total))
end

function Page:UpdateDisplay()
    local f = self.frame
    local panel = self.panel

    if not self.selectedPetID and (C_PetJournal.GetNumPets() or 0) > 0 then
        self.selectedPetID = select(9, C_PetJournal.GetPetInfoByIndex(1))
    end

    if not self.selectedPetID then
        f.model:Hide()
        f.infoIcon:Hide()
        f.typeIcon:Hide()
        f.infoName:SetText("")
        f.source:SetText("")
        f.lore:SetText("")
        f.favorite:Hide()
        if self.summonButton then NS.CollectionsPanel:HideSecure(self.summonButton) end
        return
    end

    local name, spellID, icon, petType, _, _, isFavorite, isCollected, petID, creatureID,
        _, _, _, _, priceText, descriptionText, holidayText = C_PetJournal.GetPetInfoByPetID(self.selectedPetID)

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

    f.typeIcon:SetTexture(PetTypeTexture(petType))
    f.typeIcon:Show()

    local sourceText = priceText or ""
    if holidayText and holidayText ~= "" then
        sourceText = string.format("%s\n%s", holidayText, sourceText)
    end
    f.source:SetText(sourceText)
    f.lore:SetText(descriptionText or "")

    f.favorite:SetShown(isCollected and true or false)
    f.favorite.star:SetVertexColor(1, 1, 1, isFavorite and 1 or 0.25)

    local summoned = C_PetJournal.GetSummonedPetID and C_PetJournal.GetSummonedPetID()
    f.summonLabel:SetText(petID and summoned == petID and Global("PET_DISMISS", "Отозвать")
        or Global("SUMMON", "Призвать"))

    local summonable = C_PetJournal.PetIsSummonable and C_PetJournal.PetIsSummonable(self.selectedPetID)
    f.summonPlate:SetAlpha(summonable and 1 or 0.4)

    if self.summonButton then
        if summonable and spellID then
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
        f.count:SetText(L["коллекция питомцев недоступна на этом сервере"])
        return
    end

    f.picker:Refresh(self.sort)
    self:UpdateList()
    self:UpdateDisplay()
end

function Page:Show()
    if not self.frame then return end

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

NS.PetCollectionPage = Page
