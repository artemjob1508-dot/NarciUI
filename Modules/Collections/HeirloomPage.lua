local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local COLUMNS = 3
local VISIBLE_ROWS = 11
local CELL_W = 276
local CELL_H = 48
local HEADER_H = 24

local NO_CLASS_FILTER = 0
local NO_SPEC_FILTER = 0

local CATEGORY_ORDER = {
    "HEIRLOOMS_CATEGORY_HEAD",
    "HEIRLOOMS_CATEGORY_SHOULDER",
    "HEIRLOOMS_CATEGORY_BACK",
    "HEIRLOOMS_CATEGORY_CHEST",
    "HEIRLOOMS_CATEGORY_HAND",
    "HEIRLOOMS_CATEGORY_WRIST",
    "HEIRLOOMS_CATEGORY_LEGS",
    "HEIRLOOMS_CATEGORY_WAIST",
    "HEIRLOOMS_CATEGORY_FEET",
    "HEIRLOOMS_CATEGORY_WEAPON",
    "HEIRLOOMS_CATEGORY_TRINKETS_RINGS_NECKLACES_AND_RELIC",
}

local SLOT_CATEGORY = {
    INVTYPE_HEAD = "HEIRLOOMS_CATEGORY_HEAD",
    INVTYPE_SHOULDER = "HEIRLOOMS_CATEGORY_SHOULDER",
    INVTYPE_CHEST = "HEIRLOOMS_CATEGORY_CHEST",
    INVTYPE_ROBE = "HEIRLOOMS_CATEGORY_CHEST",
    INVTYPE_HAND = "HEIRLOOMS_CATEGORY_HAND",
    INVTYPE_WRIST = "HEIRLOOMS_CATEGORY_WRIST",
    INVTYPE_LEGS = "HEIRLOOMS_CATEGORY_LEGS",
    INVTYPE_WAIST = "HEIRLOOMS_CATEGORY_WAIST",
    INVTYPE_FEET = "HEIRLOOMS_CATEGORY_FEET",
    INVTYPE_CLOAK = "HEIRLOOMS_CATEGORY_BACK",
    INVTYPE_WEAPON = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_SHIELD = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_RANGED = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_RANGEDRIGHT = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_2HWEAPON = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_WEAPONMAINHAND = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_WEAPONOFFHAND = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_HOLDABLE = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_THROWN = "HEIRLOOMS_CATEGORY_WEAPON",
    INVTYPE_FINGER = "HEIRLOOMS_CATEGORY_TRINKETS_RINGS_NECKLACES_AND_RELIC",
    INVTYPE_TRINKET = "HEIRLOOMS_CATEGORY_TRINKETS_RINGS_NECKLACES_AND_RELIC",
    INVTYPE_NECK = "HEIRLOOMS_CATEGORY_TRINKETS_RINGS_NECKLACES_AND_RELIC",
    INVTYPE_RELIC = "HEIRLOOMS_CATEGORY_TRINKETS_RINGS_NECKLACES_AND_RELIC",
}

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_Heirloom and C_Heirloom.GetNumDisplayedHeirlooms
end

function Page:BuildLayout()
    local buckets = {}
    local known, possible = 0, 0

    for index = 1, (C_Heirloom.GetNumDisplayedHeirlooms() or 0) do
        local itemID = C_Heirloom.GetHeirloomItemIDFromDisplayedIndex(index)
        if itemID then
            local name, equipLoc, texture = C_Heirloom.GetHeirloomInfo(itemID)
            local category = equipLoc and SLOT_CATEGORY[equipLoc]

            if category then
                buckets[category] = buckets[category] or {}
                table.insert(buckets[category], {
                    itemID = itemID,
                    name = name,
                    texture = texture,
                    collected = C_Heirloom.PlayerHasHeirloom(itemID) and true or false,
                })

                if C_Heirloom.PlayerHasHeirloom(itemID) then known = known + 1 end
                possible = possible + 1
            end
        end
    end

    local rows = {}

    for _, key in ipairs(CATEGORY_ORDER) do
        local bucket = buckets[key]
        if bucket and #bucket > 0 then
            rows[#rows + 1] = { header = _G[key] or key }

            local current
            for position, entry in ipairs(bucket) do
                if (position - 1) % COLUMNS == 0 then
                    current = { items = {} }
                    rows[#rows + 1] = current
                end
                table.insert(current.items, entry)
            end
        end
    end

    self.rows = rows
    self.known = known
    self.possible = possible

    return rows
end

function Page:FilterSpec()
    return {
        onChange = function()
            Page.offset = 0
            Page:Update()
        end,
        reset = function()
            if C_HeirloomInfo and C_HeirloomInfo.SetDefaultFilters then C_HeirloomInfo.SetDefaultFilters() end
        end,
        sections = {
            {
                checks = {
                    {
                        text = Global("COLLECTED", "Собрано"),
                        get = C_Heirloom.GetCollectedHeirloomFilter,
                        set = C_Heirloom.SetCollectedHeirloomFilter,
                    },
                    {
                        text = Global("NOT_COLLECTED", "Не собрано"),
                        get = C_Heirloom.GetUncollectedHeirloomFilter,
                        set = C_Heirloom.SetUncollectedHeirloomFilter,
                    },
                },
            },
            {
                title = Global("SOURCES", "Источники"),
                prepend = "COLLECTION_PET_SOURCE_",
                num = C_PetJournal and C_PetJournal.GetNumPetSources,
                get = C_Heirloom.GetHeirloomSourceFilter,
                set = C_Heirloom.SetHeirloomSourceFilter,
                valid = C_HeirloomInfo and C_HeirloomInfo.IsHeirloomSourceValid,
                all = C_HeirloomInfo and C_HeirloomInfo.SetAllSourceFilters,
            },
        },
    }
end

function Page:ClassEntries()
    local entries = { { value = NO_CLASS_FILTER, label = Global("ALL_CLASSES", "Все классы") } }

    for index = 1, (GetNumClasses and GetNumClasses() or 0) do
        if index ~= 10 then
            local displayName, _, classID = GetClassInfo(index)
            if displayName and classID then
                entries[#entries + 1] = { value = classID, label = displayName }
            end
        end
    end

    return entries
end

function Page:SpecEntries(classID)
    local entries = { { value = NO_SPEC_FILTER, label = Global("ALL_SPECS", "Все специализации") } }

    if not classID or classID == NO_CLASS_FILTER then return entries end
    if not GetNumSpecializationsForClassID then return entries end

    for index = 1, (GetNumSpecializationsForClassID(classID) or 0) do
        local specID, specName = GetSpecializationInfoForClassID(classID, index)
        if specID and specName then
            entries[#entries + 1] = { value = specID, label = specName }
        end
    end

    return entries
end

function Page:SetClassFilter(classID, specID)
    C_Heirloom.SetClassAndSpecFilters(classID or NO_CLASS_FILTER, specID or NO_SPEC_FILTER)
    self.offset = 0
    self:Update()
end

function Page:CreateCell(parent, index)
    local S = NS.Styling

    local cell = CreateFrame("Frame", nil, parent)
    cell:SetSize(CELL_W, CELL_H)

    local plate = cell:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture(WHITE)
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.35)

    local border = CreateFrame("Frame", nil, cell)
    border:SetAllPoints()
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    border:EnableMouse(false)
    cell.border = border

    local icon = cell:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", cell, "LEFT", 7, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.icon = icon

    local name = cell:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:SetWidth(CELL_W - 62)
    name:SetJustifyH("LEFT")
    cell.name = name

    cell:Hide()
    return cell
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
    self.offset = 0

    local search = NS.Widgets.CreateThemedEditBox(f, 200, 20, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    search:SetScript("OnTextChanged", function(self)
        C_Heirloom.SetSearch(self:GetText() or "")
        Page.offset = 0
        Page:Update()
    end)
    f.search = search

    local filterPopup = panel:CreateFilterPopup("heirlooms", self:FilterSpec())
    local filterButton = panel:CreateFilterButton(f, filterPopup)
    filterButton:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 0)
    f.filterPopup = filterPopup

    local classDrop = NS.Widgets.CreateThemedDropdown(f, 160, function(value)
        Page:SetClassFilter(value, NO_SPEC_FILTER)
    end)
    classDrop:SetPoint("TOPLEFT", filterButton, "TOPRIGHT", 10, 0)
    classDrop:SetEntries(self:ClassEntries())
    f.classDrop = classDrop

    local specDrop = NS.Widgets.CreateThemedDropdown(f, 170, function(value)
        local classID = C_Heirloom.GetClassAndSpecFilters()
        Page:SetClassFilter(classID, value)
    end)
    specDrop:SetPoint("TOPLEFT", classDrop, "TOPRIGHT", 8, 0)
    f.specDrop = specDrop

    local progressTrack = f:CreateTexture(nil, "ARTWORK")
    progressTrack:SetSize(180, 14)
    progressTrack:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -3)
    progressTrack:SetTexture(WHITE)
    progressTrack:SetVertexColor(NS.Styling.Tint(0.02, 0.02, 0.04, 0.9))
    f.progressTrack = progressTrack

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
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -30)
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 24)
    Chrome(body)
    f.body = body

    f.headers = {}
    f.cells = {}

    for index = 1, VISIBLE_ROWS do
        local header = body:CreateFontString(nil, "OVERLAY")
        header:SetFont(NS.FONT, NS.FS(11), "")
        header:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        header:SetJustifyH("LEFT")
        header:Hide()
        f.headers[index] = header
    end

    for index = 1, VISIBLE_ROWS * COLUMNS do
        f.cells[index] = self:CreateCell(body, index)
    end

    body:EnableMouseWheel(true)
    body:SetScript("OnMouseWheel", function(_, delta)
        local total = Page.rows and #Page.rows or 0
        if total <= VISIBLE_ROWS then return end
        Page.offset = math.max(0, math.min(total - VISIBLE_ROWS, (Page.offset or 0) - delta))
        Page:Update()
    end)

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 4)
    hint:SetText(L["клик по собранному предмету создает его"])

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        pcall(events.RegisterCustomEvent, events, "HEIRLOOMS_UPDATED")
    end

    f.events = events
    f:Hide()

    return f
end

function Page:UpdateFilterControls()
    local f = self.frame
    local classID, specID = C_Heirloom.GetClassAndSpecFilters()

    f.classDrop:SetEntries(self:ClassEntries())
    f.classDrop:SetValue(classID or NO_CLASS_FILTER)

    f.specDrop:SetEntries(self:SpecEntries(classID))
    f.specDrop:SetValue(specID or NO_SPEC_FILTER)
end

function Page:Update()
    if not self.frame then return end

    local S = NS.Styling
    local f = self.frame
    local panel = self.panel

    if not Available() then
        f.progressText:SetText(L["наследство недоступно на этом сервере"])
        return
    end

    self:UpdateFilterControls()

    local rows = self:BuildLayout()
    local offset = math.max(0, math.min(self.offset or 0, math.max(0, #rows - VISIBLE_ROWS)))
    self.offset = offset

    local secures = panel:SecureCells("Heirloom", VISIBLE_ROWS * COLUMNS)
    local cellIndex = 0
    local y = -8

    local limit = (f.body:GetHeight() or 400) - 12

    for index = 1, VISIBLE_ROWS do
        local row = rows[index + offset]
        local header = f.headers[index]
        local needed = row and (row.header and HEADER_H or CELL_H + 4) or 0

        header:Hide()

        if row and (-y + needed) > limit then
            row = nil
        end

        if row and row.header then
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", f.body, "TOPLEFT", 10, y)
            header:SetText(string.upper(row.header))
            header:Show()
            y = y - HEADER_H
        elseif row and row.items then
            for column = 1, COLUMNS do
                local entry = row.items[column]
                cellIndex = cellIndex + 1
                local cell = f.cells[cellIndex]
                local secure = secures and secures[cellIndex]

                if entry then
                    cell:ClearAllPoints()
                    cell:SetPoint("TOPLEFT", f.body, "TOPLEFT", 8 + (column - 1) * (CELL_W + 4), y)
                    cell.icon:SetTexture(entry.texture or QUESTION)
                    cell.icon:SetDesaturated(not entry.collected)
                    cell.name:SetText(entry.name or ("#" .. entry.itemID))
                    cell.name:SetTextColor(
                        entry.collected and S.GOLD[1] or 0.45,
                        entry.collected and S.GOLD[2] or 0.45,
                        entry.collected and S.GOLD[3] or 0.48)
                    cell.itemID = entry.itemID
                    cell:Show()

                    if secure then
                        local spellID = C_Heirloom.GetHeirloomSpellID
                            and C_Heirloom.GetHeirloomSpellID(entry.itemID)

                        if entry.collected and spellID then
                            panel:SetSecureSpell(secure, spellID)
                        else
                            panel:SetSecureSpell(secure, nil)
                        end

                        panel:PlaceSecure(secure, cell)
                        secure:RegisterForClicks("LeftButtonUp")

                        local itemID = entry.itemID
                        secure:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                            if GameTooltip.SetHeirloomByItemID then
                                GameTooltip:SetHeirloomByItemID(itemID)
                            else
                                local link = C_Heirloom.GetHeirloomLink and C_Heirloom.GetHeirloomLink(itemID)
                                GameTooltip:SetHyperlink(link or ("item:" .. itemID))
                            end
                            GameTooltip:Show()
                        end)
                        secure:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    end
                else
                    cell:Hide()
                    if secure then panel:HideSecure(secure) end
                end
            end

            y = y - CELL_H - 4
        end
    end

    for index = cellIndex + 1, VISIBLE_ROWS * COLUMNS do
        f.cells[index]:Hide()
        if secures and secures[index] then panel:HideSecure(secures[index]) end
    end

    local ratio = self.possible > 0 and self.known / self.possible or 0
    f.progressFill:SetWidth(math.max(1, 180 * ratio))
    f.progressText:SetText(string.format(HEIRLOOMS_PROGRESS_FORMAT or "%d / %d", self.known, self.possible))
end

function Page:Show()
    if not self.frame then return end

    if Available() and not self.filtersSet then
        local _, _, classID = UnitClass("player")
        local specID = C_Talent and C_Talent.GetCurrentSpecID and C_Talent.GetCurrentSpecID()
        C_Heirloom.SetClassAndSpecFilters(classID or NO_CLASS_FILTER, specID or NO_SPEC_FILTER)
        self.filtersSet = true
    end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if not self.frame then return end

    self.frame:Hide()
    if self.frame.filterPopup then self.frame.filterPopup:Hide() end
    if self.panel then self.panel:HideSecureCells("Heirloom") end
end

NS.HeirloomPage = Page
