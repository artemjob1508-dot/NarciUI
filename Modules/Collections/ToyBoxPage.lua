local addonName, NS = ...
local L = NS.L

local Page = {}

local WHITE = "Interface\\Buttons\\WHITE8x8"
local STAR = "Interface\\Common\\FavoritesIcon"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local COLUMNS = 3
local ROWS = 6
local PER_PAGE = COLUMNS * ROWS
local CELL_W = 276
local CELL_H = 60

local function Global(key, fallback)
    local value = _G[key]
    if type(value) == "string" and value ~= "" then return value end
    return L[fallback]
end

local function Available()
    return C_ToyBox and C_ToyBox.GetNumFilteredToys
end

function Page:MaxPages()
    local total = C_ToyBox.GetNumFilteredToys() or 0
    return math.max(1, 1 + math.floor(math.max(total - 1, 0) / PER_PAGE))
end

function Page:FilterSpec()
    return {
        onChange = function()
            Page.page = 1
            Page:Update()
        end,
        reset = function()
            if C_ToyBoxInfo and C_ToyBoxInfo.SetDefaultFilters then C_ToyBoxInfo.SetDefaultFilters() end
        end,
        sections = {
            {
                checks = {
                    {
                        text = Global("COLLECTED", "Собрано"),
                        get = C_ToyBox.GetCollectedShown,
                        set = C_ToyBox.SetCollectedShown,
                    },
                    {
                        text = Global("NOT_COLLECTED", "Не собрано"),
                        get = C_ToyBox.GetUncollectedShown,
                        set = C_ToyBox.SetUncollectedShown,
                    },
                },
            },
            {
                title = Global("SOURCES", "Источники"),
                prepend = "COLLECTION_PET_SOURCE_",
                num = C_PetJournal and C_PetJournal.GetNumPetSources,
                get = C_ToyBox.IsSourceTypeFilterChecked,
                set = C_ToyBox.SetSourceTypeFilter,
                valid = C_ToyBoxInfo and C_ToyBoxInfo.IsToySourceValid,
                all = C_ToyBox.SetAllSourceTypeFilters,
            },
        },
    }
end

function Page:ToggleFavorite(itemID)
    if not itemID then return end
    C_ToyBox.SetIsFavorite(itemID, not C_ToyBox.GetIsFavorite(itemID))
    self:Update()
end

function Page:CreateCell(parent, index)
    local S = NS.Styling

    local column = (index - 1) % COLUMNS
    local row = math.floor((index - 1) / COLUMNS)

    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(CELL_W, CELL_H)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", 8 + column * (CELL_W + 4), -8 - row * (CELL_H + 4))
    cell:RegisterForClicks("RightButtonUp")

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
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", cell, "LEFT", 8, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.icon = icon

    local name = cell:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(12), "")
    name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    name:SetWidth(CELL_W - 76)
    name:SetJustifyH("LEFT")
    cell.name = name

    local favorite = cell:CreateTexture(nil, "OVERLAY")
    favorite:SetSize(14, 14)
    favorite:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -4, -4)
    favorite:SetTexture(STAR)
    favorite:Hide()
    cell.favorite = favorite

    cell:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if C_ToyBox.SetToyTooltipByItemID then
            C_ToyBox.SetToyTooltipByItemID(self.itemID)
        else
            GameTooltip:SetHyperlink("item:" .. self.itemID)
        end
        GameTooltip:Show()
        self.border:SetBackdropBorderColor(NS.Styling.ACCENT[1], NS.Styling.ACCENT[2], NS.Styling.ACCENT[3], 1)
    end)
    cell:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.border:SetBackdropBorderColor(NS.Styling.BORDER[1], NS.Styling.BORDER[2], NS.Styling.BORDER[3], 0.8)
    end)
    cell:SetScript("OnClick", function(self, button)
        if button == "RightButton" and self.itemID and PlayerHasToy(self.itemID) then
            Page:ToggleFavorite(self.itemID)
        end
    end)

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
    self.page = self.page or 1

    local search = NS.Widgets.CreateThemedEditBox(f, 220, 20, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    search:SetScript("OnTextChanged", function(self)
        C_ToyBox.SetFilterString(self:GetText() or "")
        Page.page = 1
        Page:Update()
    end)
    f.search = search

    local filterPopup = panel:CreateFilterPopup("toys", self:FilterSpec())
    local filterButton = panel:CreateFilterButton(f, filterPopup)
    filterButton:SetPoint("TOPLEFT", search, "TOPRIGHT", 8, 0)
    f.filterPopup = filterPopup

    local progressTrack = f:CreateTexture(nil, "ARTWORK")
    progressTrack:SetSize(260, 14)
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
    body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 30)
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
    prev:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 2)

    local pageText = f:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(NS.FONT, NS.FS(11), "")
    pageText:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pageText:SetPoint("LEFT", prev, "RIGHT", 10, 0)
    f.pageText = pageText

    local next = NS.Widgets.CreateThemedButton(f, ">", 30, 20, function()
        Page:SetPage((Page.page or 1) + 1)
    end)
    next:SetPoint("LEFT", pageText, "RIGHT", 10, 0)

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 6)
    hint:SetText(L["левый клик — использовать, правый — избранное"])

    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function()
        if Page.frame and Page.frame:IsShown() then Page:Update() end
    end)

    if events.RegisterCustomEvent then
        pcall(events.RegisterCustomEvent, events, "TOYS_UPDATED")
    end

    f.events = events
    f:Hide()

    return f
end

function Page:SetPage(page)
    local maxPages = self:MaxPages()
    self.page = math.max(1, math.min(maxPages, page))
    self:Update()
end

function Page:Update()
    if not self.frame then return end

    local S = NS.Styling
    local f = self.frame
    local panel = self.panel

    if not Available() then
        f.progressText:SetText(L["игрушки недоступны на этом сервере"])
        return
    end

    local maxPages = self:MaxPages()
    self.page = math.max(1, math.min(maxPages, self.page or 1))

    local cells = panel:SecureCells("Toy", PER_PAGE)

    for index = 1, PER_PAGE do
        local cell = f.cells[index]
        local itemIndex = (self.page - 1) * PER_PAGE + index
        local itemID, spellID = C_ToyBox.GetToyFromIndex(itemIndex)
        local secure = cells and cells[index]

        if itemID and itemID ~= -1 then
            local _, _, toyName, icon, _ = C_ToyBox.GetToyInfo(itemID)
            local collected = PlayerHasToy(itemID)

            cell.itemID = itemID
            cell.spellID = spellID
            cell.icon:SetTexture(icon or QUESTION)
            cell.icon:SetDesaturated(not collected)
            cell.name:SetText(toyName or ("#" .. itemID))
            cell.name:SetTextColor(
                collected and S.GOLD[1] or 0.45,
                collected and S.GOLD[2] or 0.45,
                collected and S.GOLD[3] or 0.48)
            cell.favorite:SetShown(C_ToyBox.GetIsFavorite(itemID) and true or false)
            cell:Show()

            if secure then
                if collected and spellID then
                    panel:SetSecureSpell(secure, spellID)
                    panel:PlaceSecure(secure, cell)
                    secure:RegisterForClicks("LeftButtonUp")
                    secure:RegisterForDrag("LeftButton")
                    secure:SetScript("OnDragStart", function()
                        local spellName = GetSpellInfo(spellID)
                        if spellName then pcall(PickupSpell, spellName) end
                    end)
                    secure:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                        if C_ToyBox.SetToyTooltipByItemID then
                            C_ToyBox.SetToyTooltipByItemID(itemID)
                        else
                            GameTooltip:SetHyperlink("item:" .. itemID)
                        end
                        GameTooltip:Show()
                    end)
                    secure:SetScript("OnLeave", function() GameTooltip:Hide() end)
                else
                    panel:SetSecureSpell(secure, nil)
                    panel:HideSecure(secure)
                end
            end
        else
            cell.itemID = nil
            cell:Hide()
            if secure then panel:HideSecure(secure) end
        end
    end

    local learned = C_ToyBox.GetNumLearnedDisplayedToys() or 0
    local totalDisplayed = C_ToyBox.GetNumTotalDisplayedToys() or 0
    local ratio = totalDisplayed > 0 and learned / totalDisplayed or 0

    f.progressFill:SetWidth(math.max(1, 260 * ratio))
    f.progressText:SetText(string.format(TOY_PROGRESS_FORMAT or "%d / %d", learned, totalDisplayed))
    f.pageText:SetText(string.format(L["страница %d из %d"], self.page, maxPages))
end

function Page:Show()
    if not self.frame then return end

    if C_ToyBox and C_ToyBox.ForceToyRefilter then pcall(C_ToyBox.ForceToyRefilter) end

    self.frame:Show()
    self:Update()
end

function Page:Hide()
    if not self.frame then return end

    self.frame:Hide()
    if self.frame.filterPopup then self.frame.filterPopup:Hide() end
    if self.panel then self.panel:HideSecureCells("Toy") end
end

NS.ToyBoxPage = Page
