local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local STAR = "Interface\\Common\\FavoritesIcon"

local COLUMNS = 6
local ROWS = 3
local PER_PAGE = COLUMNS * ROWS
local GRID_MARGIN = 8
local GRID_GAP = 4
local BODY_TOP = 72
local BODY_BOTTOM = 30
local WEAPON_CREATURE = 413

local SLOTS = {
    { key = "HEADSLOT", inv = "HeadSlot" },
    { key = "SHOULDERSLOT", inv = "ShoulderSlot" },
    { key = "BACKSLOT", inv = "BackSlot" },
    { key = "CHESTSLOT", inv = "ChestSlot" },
    { key = "SHIRTSLOT", inv = "ShirtSlot" },
    { key = "TABARDSLOT", inv = "TabardSlot" },
    { key = "WRISTSLOT", inv = "WristSlot" },
    { key = "HANDSSLOT", inv = "HandsSlot" },
    { key = "WAISTSLOT", inv = "WaistSlot" },
    { key = "LEGSSLOT", inv = "LegsSlot" },
    { key = "FEETSLOT", inv = "FeetSlot" },
    { key = "MAINHANDSLOT", inv = "MainHandSlot" },
    { key = "SECONDARYHANDSLOT", inv = "SecondaryHandSlot" },
    { key = "RANGEDSLOT", inv = "RangedSlot" },
}

local MODEL_SETUP = {
    HEADSLOT = { CHESTSLOT = true },
    SHOULDERSLOT = { CHESTSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    BACKSLOT = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    CHESTSLOT = { HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    TABARDSLOT = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    SHIRTSLOT = { HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    WRISTSLOT = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    HANDSSLOT = { CHESTSLOT = true, LEGSSLOT = true, FEETSLOT = true, HEADSLOT = true },
    WAISTSLOT = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
    LEGSSLOT = { CHESTSLOT = true, HANDSSLOT = true, FEETSLOT = true, HEADSLOT = true },
    FEETSLOT = { CHESTSLOT = true, HANDSSLOT = true, LEGSSLOT = true, HEADSLOT = true },
}

local MODEL_GEAR = {
    CHESTSLOT = 110001,
    LEGSSLOT = 110003,
    FEETSLOT = 110004,
    HANDSSLOT = 110002,
    HEADSLOT = 110000,
}

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_TransmogCollection and C_TransmogCollection.GetCategoryAppearances and TransmogUtil
end

local FALLBACK_CAMERA = {
    HEADSLOT = { 1.6, 0, 0.62 },
    SHOULDERSLOT = { 1.3, 0, 0.5 },
    BACKSLOT = { 0.6, 0, 0.1 },
    CHESTSLOT = { 1.0, 0, 0.2 },
    SHIRTSLOT = { 1.0, 0, 0.2 },
    TABARDSLOT = { 1.0, 0, 0.15 },
    WRISTSLOT = { 1.5, 0, 0.0 },
    HANDSSLOT = { 1.5, 0, 0.0 },
    WAISTSLOT = { 1.4, 0, -0.1 },
    LEGSSLOT = { 1.0, 0, -0.45 },
    FEETSLOT = { 1.6, 0, -0.85 },
}

local function IsWeaponSlot(key)
    return key == "MAINHANDSLOT" or key == "SECONDARYHANDSLOT" or key == "RANGEDSLOT"
end

function Page:Location()
    if not self.slot then return nil end
    local ok, location = pcall(TransmogUtil.GetTransmogLocation, self.slot,
        Enum.TransmogType.Appearance, Enum.TransmogModification.Main)
    if ok then return location end
end

function Page:Exclusion()
    if self.slot == "MAINHANDSLOT" then return LE_ITEM_FILTER_TYPE_OFF_HAND end
    if self.slot == "SECONDARYHANDSLOT" then return LE_ITEM_FILTER_TYPE_MAIN_HAND end
end

function Page:WeaponCategories()
    local list = {}
    local location = self:Location()
    if not location then return list end

    for categoryID = (FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE or 12), (LAST_TRANSMOG_COLLECTION_WEAPON_TYPE or 30) do
        local name, isWeapon, _, canMainHand, canOffHand, canRanged =
            C_TransmogCollection.GetCategoryInfo(categoryID)

        if name and isWeapon then
            local fits = (location:IsMainHand() and canMainHand)
                or (location:IsOffHand() and canOffHand)
                or (location:IsRanged() and canRanged)

            if fits then
                list[#list + 1] = { value = categoryID, label = name }
            end
        end
    end

    return list
end

function Page:ArmorSubCategories(category)
    local list = {}
    if not category then return list end

    for subCategory = (FIRST_TRANSMOG_COLLECTION_SUB_CATEGORY or 0), (LAST_TRANSMOG_COLLECTION_SUB_CATEGORY or 5) do
        local name = C_TransmogCollection.GetSubCategoryInfo(category, subCategory)
        if name then
            list[#list + 1] = { value = subCategory, label = name }
        end
    end

    return list
end

function Page:SetSlot(key)
    self.slot = key
    self.page = 1
    self.category = nil
    self.subCategory = nil

    local location = self:Location()
    if not location then return end

    if IsWeaponSlot(key) then
        local categories = self:WeaponCategories()
        self.category = categories[1] and categories[1].value
        self.subCategory = nil
    else
        self.category = location:GetArmorCategoryID()
        self.subCategory = nil

        for subCategory = (LAST_TRANSMOG_COLLECTION_SUB_CATEGORY or 5) - 1,
            (FIRST_TRANSMOG_COLLECTION_SUB_CATEGORY or 0), -1 do
            if C_TransmogCollection.GetSubCategoryInfo(self.category, subCategory) then
                self.subCategory = subCategory
                break
            end
        end
    end

    self:ApplyCategory()
end

function Page:ApplyCategory()
    if not self.category then return end

    if C_TransmogCollection.SetSearchAndFilterCategory then
        pcall(C_TransmogCollection.SetSearchAndFilterCategory, self.category, self.subCategory, self:Exclusion())
    end

    self.visuals = nil
    self:Update()
end

function Page:Visuals()
    if self.visuals then return self.visuals end
    if not self.category then return {} end

    local list = C_TransmogCollection.GetCategoryAppearances(self.category, self.subCategory, self:Exclusion()) or {}
    local filtered = {}

    for _, info in ipairs(list) do
        if not info.isHideVisual then filtered[#filtered + 1] = info end
    end

    table.sort(filtered, function(left, right)
        if left.isCollected ~= right.isCollected then return left.isCollected end
        if left.isFavorite ~= right.isFavorite then return left.isFavorite and true or false end
        if left.uiOrder and right.uiOrder then return left.uiOrder > right.uiOrder end
        return (left.visualID or 0) > (right.visualID or 0)
    end)

    self.visuals = filtered
    return filtered
end

function Page:SourcesFor(visualID)
    if CollectionWardrobeUtil and CollectionWardrobeUtil.GetSortedAppearanceSources then
        local ok, sources = pcall(CollectionWardrobeUtil.GetSortedAppearanceSources,
            visualID, self.category, self.subCategory, self:Exclusion())
        if ok and sources then return sources end
    end

    local ok, sources = pcall(C_TransmogCollection.GetAppearanceSources,
        visualID, self.category, self.subCategory, self:Exclusion())
    if ok and sources then return sources end

    return {}
end

function Page:SourceFor(visualID)
    local chosen = self.chosenSources and self.chosenSources[visualID]
    if chosen then return chosen end

    local sources = self:SourcesFor(visualID)
    return sources[1] and sources[1].sourceID
end

function Page:ToggleFavorite(visualID)
    if not visualID or not C_TransmogCollection.SetIsAppearanceFavorite then return end

    local isFavorite = C_TransmogCollection.GetIsAppearanceFavorite
        and C_TransmogCollection.GetIsAppearanceFavorite(visualID)

    C_TransmogCollection.SetIsAppearanceFavorite(visualID, not isFavorite)
    self.visuals = nil
    self:Update()
end

function Page:FilterSpec()
    return {
        onChange = function()
            Page.visuals = nil
            Page.page = 1
            Page:Update()
        end,
        reset = function() C_TransmogCollection.SetDefaultFilters() end,
        sections = {
            {
                checks = {
                    {
                        text = Global("COLLECTED", "Собрано"),
                        get = C_TransmogCollection.GetCollectedShown,
                        set = C_TransmogCollection.SetCollectedShown,
                    },
                    {
                        text = Global("NOT_COLLECTED", "Не собрано"),
                        get = C_TransmogCollection.GetUncollectedShown,
                        set = C_TransmogCollection.SetUncollectedShown,
                    },
                },
            },
            {
                title = Global("SOURCES", "Источники"),
                prepend = "COLLECTION_PET_SOURCE_",
                num = C_PetJournal and C_PetJournal.GetNumPetSources,
                get = C_TransmogCollection.IsSourceTypeFilterChecked,
                set = C_TransmogCollection.SetSourceTypeFilter,
                all = C_TransmogCollection.SetAllSourceTypeFilters,
            },
        },
    }
end

function Page:DressModel(model, sourceID)
    if not sourceID then return false end

    model:SetPosition(0, 0, 0)
    model:ClearModel()

    if IsWeaponSlot(self.slot) then
        model:SetCreature(WEAPON_CREATURE)
        pcall(model.Undress, model)
    else
        model:SetUnit("player")
        pcall(model.Undress, model)

        local setup = MODEL_SETUP[self.slot]
        if setup then
            for slot, equip in pairs(setup) do
                if equip and MODEL_GEAR[slot] then
                    pcall(model.TryOn, model, MODEL_GEAR[slot])
                end
            end
        end
    end

    local framed = false

    if Model_ApplyUICamera and GetUICameraInfo and C_TransmogCollection.GetAppearanceCameraIDBySource then
        local ok, cameraID = pcall(C_TransmogCollection.GetAppearanceCameraIDBySource, sourceID)
        if ok and cameraID and cameraID ~= 0 and GetUICameraInfo(cameraID) then
            pcall(Model_ApplyUICamera, model, cameraID)
            framed = true
        end
    end

    if not framed then
        local camera = FALLBACK_CAMERA[self.slot]
        if camera then
            model:SetPosition(camera[1], camera[2], camera[3])
            model:SetFacing(0.4)
        else
            model:SetPosition(0, 0, 0)
            model:SetFacing(0.6)
        end
    end

    if not GetItemInfo(sourceID) then
        if C_Item and C_Item.RequestServerCache then
            pcall(C_Item.RequestServerCache, sourceID)
        end
        return false
    end

    pcall(model.TryOn, model, string.format("item:%s:0", sourceID))
    return true
end

function Page:CreateCell(parent, index)
    local S = NS.Styling

    local column = (index - 1) % COLUMNS
    local row = math.floor((index - 1) / COLUMNS)

    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(self.cellWidth, self.cellHeight)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT",
        GRID_MARGIN + column * (self.cellWidth + GRID_GAP),
        -GRID_MARGIN - row * (self.cellHeight + GRID_GAP))
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local plate = cell:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.4)

    local model = CreateFrame("DressUpModel", nil, cell)
    model:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
    model:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -2, 2)
    model:EnableMouse(false)
    cell.model = model

    local border = CreateFrame("Frame", nil, cell)
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    border:SetFrameLevel(model:GetFrameLevel() + 2)
    cell.border = border

    local favorite = border:CreateTexture(nil, "OVERLAY")
    favorite:SetSize(14, 14)
    favorite:SetPoint("TOPLEFT", cell, "TOPLEFT", 3, -3)
    favorite:SetTexture(STAR)
    favorite:Hide()
    cell.favorite = favorite

    local newLabel = border:CreateFontString(nil, "OVERLAY")
    newLabel:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    newLabel:SetTextColor(0.2, 0.9, 0.4)
    newLabel:SetPoint("BOTTOM", cell, "BOTTOM", 0, 4)
    newLabel:SetText(Global("NEW", "Новое"))
    newLabel:Hide()
    cell.newLabel = newLabel

    cell:SetScript("OnEnter", function(self)
        if not self.visualID then return end

        self.border:SetBackdropBorderColor(NS.Styling.ACCENT_GLOW[1], NS.Styling.ACCENT_GLOW[2],
            NS.Styling.ACCENT_GLOW[3], 1)

        local sources = Page:SourcesFor(self.visualID)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if CollectionWardrobeUtil and CollectionWardrobeUtil.SetAppearanceTooltip and #sources > 0 then
            pcall(CollectionWardrobeUtil.SetAppearanceTooltip, GameTooltip, sources, self.sourceID, 1, false)
        elseif self.sourceID then
            local _, _, _, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(self.sourceID)
            if link then GameTooltip:SetHyperlink(link) end
        end

        GameTooltip:Show()

        if C_TransmogCollection.ClearNewAppearance and C_TransmogCollection.IsNewAppearance
            and C_TransmogCollection.IsNewAppearance(self.visualID) then
            C_TransmogCollection.ClearNewAppearance(self.visualID)
            self.newLabel:Hide()
        end
    end)

    cell:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        Page:RefreshBorder(self)
    end)

    cell:SetScript("OnClick", function(self, button)
        if not self.visualID then return end

        if button == "RightButton" then
            Page:ToggleFavorite(self.visualID)
        elseif IsModifiedClick("CHATLINK") and self.sourceID then
            local _, _, _, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(self.sourceID)
            if link then HandleModifiedItemClick(link) end
        elseif self.sourceID then
            Page:CycleSource(self.visualID)
        end
    end)

    cell:Hide()
    return cell
end

function Page:CycleSource(visualID)
    local sources = self:SourcesFor(visualID)
    if #sources < 2 then return end

    self.chosenSources = self.chosenSources or {}

    local current = self.chosenSources[visualID] or sources[1].sourceID
    local index = 1

    for position, source in ipairs(sources) do
        if source.sourceID == current then index = position end
    end

    local nextSource = sources[index % #sources + 1]
    self.chosenSources[visualID] = nextSource and nextSource.sourceID
    self:Update()
end

function Page:RefreshBorder(cell)
    local S = NS.Styling

    if not cell.visualID then
        cell.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        return
    end

    if not cell.isCollected then
        cell.border:SetBackdropBorderColor(0.45, 0.45, 0.48, 0.9)
    elseif not cell.isUsable then
        cell.border:SetBackdropBorderColor(0.85, 0.35, 0.35, 0.9)
    else
        cell.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
    end
end

function Page:Attach(panel)
    if self.frame then return self.frame end

    local S = NS.Styling
    local host = panel.frame
    local Chrome = panel.Chrome

    local pad, contentW, panelH = panel:Geometry()

    local f = CreateFrame("Frame", nil, host)
    f:SetPoint("TOPLEFT", host, "TOPLEFT", pad, -64)
    f:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -pad, 20)

    self.frame = f
    self.panel = panel
    self.page = self.page or 1
    self.chosenSources = self.chosenSources or {}

    local bodyHeight = panelH - 64 - 20 - BODY_TOP - BODY_BOTTOM
    self.cellWidth = math.floor((contentW - GRID_MARGIN * 2 - (COLUMNS - 1) * GRID_GAP) / COLUMNS)
    self.cellHeight = math.floor((bodyHeight - GRID_MARGIN * 2 - (ROWS - 1) * GRID_GAP) / ROWS)

    f.slots = {}
    for index, slot in ipairs(SLOTS) do
        local button = CreateFrame("Button", nil, f)
        button:SetSize(34, 34)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", (index - 1) * 38, 0)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local _, texture = GetInventorySlotInfo(slot.inv)
        icon:SetTexture(texture)
        button.icon = icon

        local border = CreateFrame("Frame", nil, button)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        border:EnableMouse(false)
        button.border = border

        button:SetScript("OnClick", function()
            Page:SetSlot(slot.key)
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(_G[slot.key] or slot.key)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)

        button.slotKey = slot.key
        f.slots[index] = button
    end

    local categoryDrop = NS.Widgets.CreateThemedDropdown(f, 190, function(value)
        if IsWeaponSlot(Page.slot) then
            Page.category = value
        else
            Page.subCategory = value
        end
        Page.page = 1
        Page:ApplyCategory()
    end)
    categoryDrop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -44)
    f.categoryDrop = categoryDrop

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPLEFT", categoryDrop, "TOPRIGHT", 10, 0)
    search:SetScript("OnTextChanged", function(self)
        if C_TransmogCollection.SetSearch and Enum and Enum.TransmogSearchType then
            C_TransmogCollection.SetSearch(Enum.TransmogSearchType.Items, self:GetText() or "")
        end
        Page.visuals = nil
        Page.page = 1
        Page:Update()
    end)
    f.search = search

    local filterPopup = panel:CreateFilterPopup("wardrobe", self:FilterSpec())
    local filterButton = panel:CreateFilterButton(f, filterPopup)
    filterButton:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 0)
    f.filterPopup = filterPopup

    local progressTrack = f:CreateTexture(nil, "ARTWORK")
    progressTrack:SetSize(180, 14)
    progressTrack:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -47)
    progressTrack:SetTexture(WHITE)
    progressTrack:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))

    local progressFill = f:CreateTexture(nil, "OVERLAY")
    progressFill:SetHeight(14)
    progressFill:SetPoint("LEFT", progressTrack, "LEFT", 0, 0)
    progressFill:SetTexture(WHITE)
    progressFill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    f.progressFill = progressFill

    local progressText = f:CreateFontString(nil, "OVERLAY")
    progressText:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    progressText:SetPoint("CENTER", progressTrack, "CENTER", 0, 0)
    f.progressText = progressText

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -BODY_TOP)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, BODY_BOTTOM)
    Chrome(body)
    f.body = body

    f.cells = {}
    for index = 1, PER_PAGE do
        f.cells[index] = self:CreateCell(body, index)
    end

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        Page:SetPage((Page.page or 1) - delta)
    end)

    local prev = NS.Widgets.CreateThemedButton(f, "<", 30, 20, function()
        Page:SetPage((Page.page or 1) - 1)
    end)
    prev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 4)

    local pageText = f:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(NS.FONT, NS.FS(11), "")
    pageText:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pageText:SetPoint("LEFT", prev, "RIGHT", 10, 0)
    f.pageText = pageText

    local nextButton = NS.Widgets.CreateThemedButton(f, ">", 30, 20, function()
        Page:SetPage((Page.page or 1) + 1)
    end)
    nextButton:SetPoint("LEFT", pageText, "RIGHT", 10, 0)

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 8)
    hint:SetText(L["левый клик — другой источник, правый — избранное"])

    local events = CreateFrame("Frame")
    events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    events:SetScript("OnEvent", function(_, event)
        if not Page.frame or not Page.frame:IsShown() then return end

        if event ~= "GET_ITEM_INFO_RECEIVED" then Page.visuals = nil end
        Page:Update()
    end)

    if events.RegisterCustomEvent then
        for _, name in ipairs({ "TRANSMOG_COLLECTION_UPDATED", "TRANSMOG_COLLECTION_ITEM_UPDATE",
            "TRANSMOG_SEARCH_UPDATED" }) do
            pcall(events.RegisterCustomEvent, events, name)
        end
    end

    f.events = events
    f:Hide()

    return f
end

function Page:SetPage(page)
    local total = #self:Visuals()
    local maxPages = math.max(1, math.ceil(total / PER_PAGE))
    self.page = math.max(1, math.min(maxPages, page))
    self:Update()
end

function Page:UpdateSlots()
    local S = NS.Styling
    local f = self.frame

    for _, button in ipairs(f.slots) do
        local active = button.slotKey == self.slot
        button.border:SetBackdropBorderColor(
            active and S.ACCENT[1] or S.BORDER[1],
            active and S.ACCENT[2] or S.BORDER[2],
            active and S.ACCENT[3] or S.BORDER[3], active and 1 or 0.9)
        button.icon:SetAlpha(active and 1 or 0.6)
    end
end

function Page:UpdateCategoryDrop()
    local f = self.frame

    if IsWeaponSlot(self.slot) then
        f.categoryDrop:SetEntries(self:WeaponCategories())
        f.categoryDrop:SetValue(self.category)
        f.categoryDrop:Show()
    else
        local subs = self:ArmorSubCategories(self.category)
        f.categoryDrop:SetEntries(subs)
        f.categoryDrop:SetValue(self.subCategory)
        f.categoryDrop:SetShown(#subs > 1)
    end
end

function Page:Update()
    if not self.frame then return end

    local f = self.frame

    if not Available() then
        f.progressText:SetText(L["гардероб недоступен на этом сервере"])
        return
    end

    self:UpdateSlots()
    self:UpdateCategoryDrop()

    local visuals = self:Visuals()
    local maxPages = math.max(1, math.ceil(#visuals / PER_PAGE))
    self.page = math.max(1, math.min(maxPages, self.page or 1))

    local offset = (self.page - 1) * PER_PAGE
    local pending = false

    for index = 1, PER_PAGE do
        local cell = f.cells[index]
        local info = visuals[index + offset]

        if info then
            local sourceID = self:SourceFor(info.visualID)

            cell.visualID = info.visualID
            cell.sourceID = sourceID
            cell.isCollected = info.isCollected
            cell.isUsable = info.isUsable

            if cell.shownSource ~= sourceID or not cell.dressed then
                cell.dressed = self:DressModel(cell.model, sourceID)
                cell.shownSource = sourceID
                if not cell.dressed then pending = true end
            end

            cell.model:SetAlpha(info.isCollected and 1 or 0.45)
            cell.favorite:SetShown(info.isCollected and info.isFavorite and true or false)
            cell.newLabel:SetShown(C_TransmogCollection.IsNewAppearance
                and C_TransmogCollection.IsNewAppearance(info.visualID) or false)

            self:RefreshBorder(cell)
            cell:Show()
        else
            cell.visualID = nil
            cell.shownSource = nil
            cell.dressed = nil
            cell:Hide()
        end
    end

    if pending and not self.retryScheduled then
        self.retryScheduled = true
        NS.After(0.75, function()
            Page.retryScheduled = nil
            if Page.frame and Page.frame:IsShown() then Page:Update() end
        end)
    end

    local collected = C_TransmogCollection.GetCategoryCollectedCount
        and C_TransmogCollection.GetCategoryCollectedCount(self.category, self.subCategory, self:Exclusion()) or 0
    local total = C_TransmogCollection.GetCategoryTotal
        and C_TransmogCollection.GetCategoryTotal(self.category, self.subCategory, self:Exclusion()) or 0

    local ratio = total > 0 and collected / total or 0
    f.progressFill:SetWidth(math.max(1, 180 * ratio))
    f.progressText:SetText(string.format("%d / %d", collected, total))
    f.pageText:SetText(string.format(L["страница %d из %d"], self.page, maxPages))
end

function Page:Show()
    if not self.frame then return end

    if Available() and not self.slot then
        self:SetSlot("HEADSLOT")
    end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if not self.frame then return end

    self.frame:Hide()
    if self.frame.filterPopup then self.frame.filterPopup:Hide() end
end

NS.WardrobePage = Page
