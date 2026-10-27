local addonName, NS = ...
local L = NS.L

local SpellBookPanel = {}

local PANEL_W = 620
local PANEL_H = 545
local PAD = 16
local HEADER_H = 76
local COLUMNS = 2
local ROWS = 6
local PER_PAGE = COLUMNS * ROWS
local COL_W = 272
local ROW_H = 56
local ICON_SIZE = 40
local TAB_SIZE = 38

local BOOK_SPELL = "spell"
local BOOK_PET = "pet"

local VIEWS = {
    { key = "spells",      label = "Заклинания" },
    { key = "professions", label = "Профессии" },
    { key = "mounts",      label = "Транспорт" },
    { key = "critters",    label = "Спутники" },
}

local function CastName(name, rank)
    if not name then return nil end
    if rank and rank ~= "" and string.find(rank, "%d") then
        return name .. "(" .. rank .. ")"
    end
    return name
end

local function KnownSlot(slot, showAllRanks)
    local index = slot
    if not showAllRanks and GetKnownSlotFromHighestRankSlot then
        index = GetKnownSlotFromHighestRankSlot(slot)
    end
    if type(index) ~= "number" or index < 1 then return nil end
    return index
end

local function SpellIDFor(index, bookType)
    if not index then return nil end
    local gotLink, link = pcall(GetSpellLink, index, bookType)
    if not gotLink or not link then return nil end

    if C_SpellBook and C_SpellBook.GetSpellIDFromLink then
        local gotID, spellID = pcall(C_SpellBook.GetSpellIDFromLink, link)
        if gotID and spellID then return spellID end
    end

    local id = string.match(link, "spell:(%d+)")
    return id and tonumber(id) or nil
end

local function FlyoutFor(spellID)
    if not spellID or not GetFlyoutInfo then return nil end
    local ok, name, _, numSlots = pcall(GetFlyoutInfo, spellID)
    if ok and name and numSlots and numSlots > 0 then return spellID end
    return nil
end

local function HiddenForUI(index, bookType)
    if not index then return true end
    if not C_SpellBook or not C_SpellBook.IsSpellHiddenForUI then return false end

    local gotLink, link = pcall(GetSpellLink, index, bookType)
    if not gotLink or not link then return false end

    local gotID, spellID = pcall(C_SpellBook.GetSpellIDFromLink, link)
    if not gotID or not spellID then return false end

    local answered, hidden = pcall(C_SpellBook.IsSpellHiddenForUI, spellID)
    return answered and hidden or false
end

function SpellBookPanel:CollectTab(tabIndex)
    local entries = {}
    local showAllRanks = GetCVarBool and GetCVarBool("ShowAllSpellRanks")

    local name, texture, offset, numSpells, highestOffset, highestNumSpells = GetSpellTabInfo(tabIndex)
    if not showAllRanks and highestNumSpells then
        offset, numSpells = highestOffset, highestNumSpells
    end
    if not numSpells then return entries, name, texture end

    local seen = {}

    for slot = offset + 1, offset + numSpells do
        local index = KnownSlot(slot, showAllRanks)
        local spellName, rank

        if index then
            local ok, first, second = pcall(GetSpellName, index, BOOK_SPELL)
            if ok then spellName, rank = first, second end
        end

        local key = spellName and (spellName .. "|" .. (rank or ""))
        if spellName and not seen[key] and not HiddenForUI(index, BOOK_SPELL) then
            seen[key] = true
            local spellID = SpellIDFor(index, BOOK_SPELL)
            entries[#entries + 1] = {
                index = index,
                bookType = BOOK_SPELL,
                name = spellName,
                rank = rank,
                texture = GetSpellTexture(index, BOOK_SPELL),
                passive = IsPassiveSpell and IsPassiveSpell(index, BOOK_SPELL) or false,
                castName = CastName(spellName, rank),
                spellID = spellID,
                flyoutID = FlyoutFor(spellID),
            }
        end
    end

    return entries, name, texture
end

function SpellBookPanel:CollectPet()
    local entries = {}
    local numSpells = HasPetSpells and HasPetSpells() or 0

    for index = 1, numSpells do
        local spellName, rank
        local ok, first, second = pcall(GetSpellName, index, BOOK_PET)
        if ok then spellName, rank = first, second end

        if spellName then
            entries[#entries + 1] = {
                index = index,
                bookType = BOOK_PET,
                name = spellName,
                rank = rank,
                texture = GetSpellTexture(index, BOOK_PET),
                passive = IsPassiveSpell and IsPassiveSpell(index, BOOK_PET) or false,
                castName = CastName(spellName, rank),
            }
        end
    end

    return entries
end

local FLYING_ABILITIES = { [3] = true, [4] = true }

local function MountIsFlying(spellID)
    if not spellID or not C_MountJournal then return false end
    if not C_MountJournal.GetMountFromSpell or not C_MountJournal.GetMountAbilitiesInfoByID then
        return false
    end

    local ok, _, _, _, _, _, _, _, _, _, hash = pcall(C_MountJournal.GetMountFromSpell, spellID)
    if not ok or not hash then return false end

    local gotAbilities, abilities = pcall(C_MountJournal.GetMountAbilitiesInfoByID, hash)
    if not gotAbilities or type(abilities) ~= "table" then return false end

    for _, ability in ipairs(abilities) do
        if FLYING_ABILITIES[ability] then return true end
    end
    return false
end

function SpellBookPanel:Favorites()
    if not NS.db then return {} end
    NS.db.mountFavorites = NS.db.mountFavorites or {}
    return NS.db.mountFavorites
end

function SpellBookPanel:ToggleFavorite(spellID)
    if not spellID then return end
    local favorites = self:Favorites()
    favorites[spellID] = (not favorites[spellID]) or nil
    self:Update()
end

function SpellBookPanel:RandomFavorite()
    local favorites = self:Favorites()
    local pool = {}

    for _, entry in ipairs(self:CollectCompanions("MOUNT")) do
        if favorites[entry.spellID] and entry.castName then
            pool[#pool + 1] = entry.castName
        end
    end

    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

function SpellBookPanel:CollectCompanions(kind)
    local entries = {}
    local count = GetNumCompanions and GetNumCompanions(kind) or 0

    for index = 1, count do
        local creatureID, creatureName, spellID, icon, active = GetCompanionInfo(kind, index)
        if creatureName then
            entries[#entries + 1] = {
                creatureID = creatureID,
                name = creatureName,
                rank = active and L["призван"] or nil,
                texture = icon,
                spellID = spellID,
                castName = GetSpellInfo(spellID),
                companionKind = kind,
                companionIndex = index,
                flying = kind == "MOUNT" and MountIsFlying(spellID) or false,
            }
        end
    end

    return entries
end

local MACRO_NAME = "NarciMounts"
local MACRO_ICON = "Ability_Mount_RidingHorse"
local FALLBACK_ICON = "INV_Misc_QuestionMark"

function SpellBookPanel:FavoriteNames()
    local favorites = self:Favorites()
    local names = {}

    for _, entry in ipairs(self:CollectCompanions("MOUNT")) do
        if favorites[entry.spellID] and entry.castName then
            names[#names + 1] = entry.castName
        end
    end

    return names
end

function SpellBookPanel:FavoriteMacro()
    if InCombatLockdown() then
        NS.Print(L["в бою макрос не создаётся"])
        return nil
    end

    local names = self:FavoriteNames()
    if #names == 0 then return nil end

    local body = "#showtooltip" .. string.char(10) .. "/castrandom " .. table.concat(names, ", ")
    if #body > 255 then
        body = NS.Cut(body, 255)
        body = string.gsub(body, ",%s*[^,]*$", "")
    end

    local index = GetMacroIndexByName and GetMacroIndexByName(MACRO_NAME) or 0

    if index and index > 0 then
        local edited = pcall(EditMacro, index, MACRO_NAME, MACRO_ICON, body)
        if not edited then
            pcall(EditMacro, index, MACRO_NAME, FALLBACK_ICON, body)
        end
        return index
    end

    local ok, created = pcall(CreateMacro, MACRO_NAME, MACRO_ICON, body, nil)
    if not ok or not created then
        ok, created = pcall(CreateMacro, MACRO_NAME, FALLBACK_ICON, body, nil)
    end

    if not ok or not created then
        NS.Print(L["не удалось создать макрос: заняты все ячейки"])
        return nil
    end

    return created
end

function SpellBookPanel:PickupFavoriteMacro()
    if #self:FavoriteNames() == 0 then
        NS.Print(L["сначала отметьте средства передвижения в избранном"])
        return
    end

    local index = self:FavoriteMacro()
    if not index then return end
    if not PickupMacro then return end

    ClearCursor()
    local ok = pcall(PickupMacro, index)
    if not ok then
        NS.Print(L["макрос создан, перетащите его из окна макросов"])
    end
end

function SpellBookPanel:MountList()
    local favorites = self:Favorites()
    local ground, flying = {}, {}

    for _, entry in ipairs(self:CollectCompanions("MOUNT")) do
        entry.favorite = favorites[entry.spellID] and true or false
        if entry.flying then
            flying[#flying + 1] = entry
        else
            ground[#ground + 1] = entry
        end
    end

    local list = {}

    local hasFavorite = false
    for spellID in pairs(favorites) do
        if spellID then hasFavorite = true break end
    end

    if hasFavorite then
        list[#list + 1] = {
            name = L["Случайный из избранных"],
            rank = L["перетащите на панель"],
            texture = "Interface\\Icons\\Ability_Mount_RidingHorse",
            random = true,
        }
    end

    if #ground > 0 then
        list[#list + 1] = { name = L["Наземные"], header = true }
        for _, entry in ipairs(ground) do list[#list + 1] = entry end
    end

    if #flying > 0 then
        list[#list + 1] = { name = L["Воздушные"], header = true }
        for _, entry in ipairs(flying) do list[#list + 1] = entry end
    end

    return list
end

function SpellBookPanel:CollectProfessions()
    local entries = {}
    local collect = NS.ProfessionsPanel and NS.ProfessionsPanel.Collect
    if not collect then return entries end

    for _, info in ipairs(collect()) do
        local skill = info.entry
        local name, _, icon = GetSpellInfo(skill.open)

        local entry = {
            name = skill.skill or name,
            rank = string.format("%d / %d", (info.rank or 0) + (info.modifier or 0), info.maxRank or 0),
            texture = icon,
            spellID = skill.open,
            castName = name,
        }

        if skill.extra then
            local extraName, _, extraIcon = GetSpellInfo(skill.extra)
            if extraName then
                entry.extra = {
                    name = extraName,
                    texture = extraIcon,
                    spellID = skill.extra,
                    castName = extraName,
                }
            end
        end

        entries[#entries + 1] = entry
    end

    return entries
end

function SpellBookPanel:BuildTabs()
    local tabs = {}

    for tab = 1, (GetNumSpellTabs and GetNumSpellTabs() or 0) do
        local entries, name, texture = self:CollectTab(tab)
        if #entries > 0 then
            tabs[#tabs + 1] = { label = name or ("#" .. tab), texture = texture, entries = entries }
        end
    end

    local guildIndex
    for index, tab in ipairs(tabs) do
        if SKILLNAME_GUILD_BONUSES and tab.label == SKILLNAME_GUILD_BONUSES then
            guildIndex = index
        end
    end
    if guildIndex and guildIndex < #tabs then
        tabs[#tabs + 1] = table.remove(tabs, guildIndex)
    end

    local pet = self:CollectPet()
    if #pet > 0 then
        tabs[#tabs + 1] = {
            label = L["Питомец"],
            texture = "Interface\\Icons\\Ability_Hunter_BeastCall",
            entries = pet,
        }
    end

    return tabs
end

local function EntryTooltip(entry)
    local data = entry.data
    if not data then return end

    GameTooltip:SetOwner(entry, "ANCHOR_RIGHT")
    local shown = false

    if data.index and data.bookType then
        local ok, link = pcall(GetSpellLink, data.index, data.bookType)
        if ok and link then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
    end
    if not shown and data.spellID and GameTooltip.SetSpellByID then
        shown = pcall(GameTooltip.SetSpellByID, GameTooltip, data.spellID)
    end
    if not shown then
        GameTooltip:AddLine(data.name or "", 1, 1, 1)
        if data.rank then GameTooltip:AddLine(data.rank, 0.6, 0.6, 0.65) end
    end

    GameTooltip:Show()
end

function SpellBookPanel:CreateEntry(parent, slot)
    local S = NS.Styling

    local column = (slot - 1) % COLUMNS
    local row = math.floor((slot - 1) / COLUMNS)

    local entry = CreateFrame("Button", "NarciSirus_SpellRow" .. slot, parent, "SecureActionButtonTemplate")
    entry:SetSize(COL_W - 10, ROW_H - 8)
    entry:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    entry:SetPoint("TOPLEFT", parent, "TOPLEFT", PAD + column * COL_W, -HEADER_H - row * ROW_H)
    entry:RegisterForDrag("LeftButton")

    local plate = entry:CreateTexture(nil, "BACKGROUND")
    plate:SetAllPoints()
    plate:SetTexture("Interface\\Buttons\\WHITE8x8")
    plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.45)
    S.RoundTexture(plate, 6)
    entry.plate = plate

    local icon = entry:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", entry, "LEFT", 5, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    entry.icon = icon

    local border = CreateFrame("Frame", nil, entry)
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    border:EnableMouse(false)
    entry.border = border

    local title = entry:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(12), "")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -6)
    title:SetWidth(COL_W - ICON_SIZE - 40)
    title:SetJustifyH("LEFT")
    entry.title = title

    local subtitle = entry:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(NS.FONT, NS.FS(10), "")
    subtitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetJustifyH("LEFT")
    entry.subtitle = subtitle

    local extraIcon = entry:CreateTexture(nil, "ARTWORK")
    extraIcon:SetSize(28, 28)
    extraIcon:SetPoint("RIGHT", entry, "RIGHT", -8, 0)
    extraIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    extraIcon:Hide()
    entry.extraIcon = extraIcon

    local extraBorder = CreateFrame("Frame", nil, entry)
    extraBorder:SetPoint("TOPLEFT", extraIcon, "TOPLEFT", -1, 1)
    extraBorder:SetPoint("BOTTOMRIGHT", extraIcon, "BOTTOMRIGHT", 1, -1)
    extraBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    extraBorder:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    extraBorder:EnableMouse(false)
    extraBorder:Hide()
    entry.extraBorder = extraBorder

    local flyoutMark = entry:CreateFontString(nil, "OVERLAY")
    flyoutMark:SetFont(NS.FONT, NS.FS(14), "OUTLINE")
    flyoutMark:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    flyoutMark:SetPoint("RIGHT", entry, "RIGHT", -8, 0)
    flyoutMark:SetText(">")
    NS.Styling.GlyphIcon(flyoutMark)
    flyoutMark:Hide()
    entry.flyoutMark = flyoutMark

    local favourite = CreateFrame("Button", nil, entry)
    favourite:SetSize(16, 16)
    favourite:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    favourite:SetFrameLevel(entry:GetFrameLevel() + 4)

    local favMark = favourite:CreateTexture(nil, "ARTWORK")
    favMark:SetPoint("TOPLEFT", favourite, "TOPLEFT", 3, -3)
    favMark:SetPoint("BOTTOMRIGHT", favourite, "BOTTOMRIGHT", -3, 3)
    favMark:SetTexture("Interface\\Buttons\\WHITE8x8")
    favourite.mark = favMark

    local favBorder = CreateFrame("Frame", nil, favourite)
    favBorder:SetPoint("TOPLEFT", -1, 1)
    favBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    favBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    favBorder:SetBackdropBorderColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.8)
    favBorder:EnableMouse(false)

    favourite:SetScript("OnClick", function()
        local data = entry.data
        if data and data.spellID then SpellBookPanel:ToggleFavorite(data.spellID) end
    end)
    favourite:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Избранное средство передвижения"], 1, 1, 1)
        GameTooltip:Show()
    end)
    favourite:SetScript("OnLeave", function() GameTooltip:Hide() end)
    favourite:Hide()
    entry.favourite = favourite

    local macroButton = CreateFrame("Button", nil, entry)
    macroButton:SetSize(72, 20)
    macroButton:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    macroButton:SetFrameLevel(entry:GetFrameLevel() + 4)
    macroButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    macroButton:SetBackdropColor(NS.Styling.Tint(0.08, 0.09, 0.13, 0.95))
    macroButton:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.7)

    local macroLabel = macroButton:CreateFontString(nil, "OVERLAY")
    macroLabel:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    macroLabel:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    macroLabel:SetPoint("CENTER")
    macroLabel:SetText(L["макрос"])

    macroButton:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    macroButton:GetHighlightTexture():SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)

    macroButton:SetScript("OnClick", function() SpellBookPanel:PickupFavoriteMacro() end)
    macroButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Взять макрос со случайным избранным транспортом"], 1, 1, 1)
        GameTooltip:AddLine(L["затем перетащите его на панель способностей"], 0.6, 0.6, 0.65)
        GameTooltip:Show()
    end)
    macroButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    macroButton:Hide()
    entry.macroButton = macroButton

    entry:SetScript("PreClick", function(self)
        local data = self.data
        if not data or not data.random then return end
        if InCombatLockdown() then return end

        local pick = SpellBookPanel:RandomFavorite()
        if pick then
            self:SetAttribute("type", "spell")
            self:SetAttribute("spell", pick)
        end
    end)

    entry:HookScript("OnClick", function(self)
        local data = self.data
        if data and data.creatureID then
            SpellBookPanel:ShowPreview(data)
            return
        end

        if not data or not data.flyoutID then return end
        if InCombatLockdown() then return end
        if not SpellFlyout or not SpellFlyout.Toggle then return end

        SpellFlyout:Toggle(data.flyoutID, self, "RIGHT", 1, false, 0, true)
        if SpellFlyout.SetBorderColor then
            SpellFlyout:SetBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        end
    end)

    entry:SetScript("OnEnter", function(self)
        EntryTooltip(self)
        self.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        self.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
    end)
    entry:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
        self.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.45)
    end)
    entry:SetScript("OnDragStart", function(self)
        local data = self.data
        if not data then return end
        if data.random then
            SpellBookPanel:PickupFavoriteMacro()
        elseif data.companionKind and data.companionIndex and PickupCompanion then
            pcall(PickupCompanion, data.companionKind, data.companionIndex)
        elseif data.index and data.bookType == BOOK_SPELL then
            pcall(PickupSpell, data.index, BOOK_SPELL)
        elseif data.spellID then
            pcall(PickupSpell, data.spellID)
        end
    end)

    entry:Hide()
    return entry
end

function SpellBookPanel:CreateCastButton(parent, entry, slot, kind)
    local name = "NarciSirus_SpellCast" .. kind .. slot
    local anchor = kind == "Extra" and entry.extraIcon or entry.icon
    local size = kind == "Extra" and 30 or (ICON_SIZE + 4)

    local button = CreateFrame("Button", name, entry, "SecureActionButtonTemplate")
    button:SetSize(size, size)
    button:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    button:SetFrameLevel(entry:GetFrameLevel() + 4)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    button.entry = entry
    button.kind = kind

    button:SetScript("OnEnter", function(self)
        local data = entry.data
        if kind == "Extra" then data = data and data.extra end
        if not data then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local shown = false
        if data.spellID and GameTooltip.SetSpellByID then
            shown = pcall(GameTooltip.SetSpellByID, GameTooltip, data.spellID)
        end
        if not shown and data.index and data.bookType then
            local ok, link = pcall(GetSpellLink, data.index, data.bookType)
            if ok and link then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
        end
        if not shown then GameTooltip:AddLine(data.name or "", 1, 1, 1) end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    button:SetScript("OnDragStart", function()
        local data = entry.data
        if kind == "Extra" then data = data and data.extra end
        if not data then return end

        if data.index and data.bookType == BOOK_SPELL then
            pcall(PickupSpell, data.index, BOOK_SPELL)
        elseif data.spellID then
            pcall(PickupSpell, data.spellID)
        end
    end)

    button:Hide()
    return button
end

function SpellBookPanel:CreateTabButton(parent, index)
    local S = NS.Styling

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(TAB_SIZE, TAB_SIZE)
    button:SetPoint("TOPLEFT", parent, "TOPRIGHT", 8, -HEADER_H - (index - 1) * (TAB_SIZE + 10))

    local backdrop = CreateFrame("Frame", nil, button)
    backdrop:SetPoint("TOPLEFT", -3, 3)
    backdrop:SetPoint("BOTTOMRIGHT", 3, -3)
    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    backdrop:SetBackdropColor(S.Bg(0.97))
    backdrop:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    backdrop:SetFrameLevel(math.max(button:GetFrameLevel() - 1, 1))
    button.backdrop = backdrop

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.25)

    button:SetScript("OnEnter", function(self)
        if not self.label then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", function()
        SpellBookPanel.tab = index
        SpellBookPanel.page = 1
        SpellBookPanel:Update()
    end)

    button:Hide()
    return button
end

function SpellBookPanel:CreatePreview()
    if self.previewFrame then return self.previewFrame end
    local S = NS.Styling
    local host = self.frame
    if not host then return nil end

    local preview = CreateFrame("Frame", "NarcissusSirus_MountPreview", host)
    preview:SetSize(260, 340)
    preview:SetPoint("TOPLEFT", host, "TOPRIGHT", 56, 0)
    preview:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    preview:SetBackdropColor(S.Bg(0.97))
    preview:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(preview, 5, 0.4)

    local title = preview:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", preview, "TOP", 0, -12)
    title:SetWidth(230)
    preview.title = title

    local model = CreateFrame("PlayerModel", nil, preview)
    model:SetPoint("TOPLEFT", preview, "TOPLEFT", 10, -34)
    model:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -10, 34)
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseDown", function(self)
        self.rotating = true
        self.lastX = GetCursorPosition()
    end)
    model:SetScript("OnMouseUp", function(self) self.rotating = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.rotating then return end
        local x = GetCursorPosition()
        local delta = (x - (self.lastX or x)) * 0.01
        self.lastX = x
        self.facing = (self.facing or 0) + delta
        self:SetFacing(self.facing)
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(-1, math.min(2, (self.zoom or 0) + delta * 0.2))
        pcall(self.SetPosition, self, self.zoom, 0, 0)
    end)
    preview.model = model

    local hint = preview:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("BOTTOM", preview, "BOTTOM", 0, 12)
    hint:SetText(L["перетаскивание - поворот, колесо - масштаб"])

    local close = NS.Widgets.CreateCloseButton(preview, 16, function() preview:Hide() end)
    close:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -8, -8)

    preview:Hide()
    self.previewFrame = preview
    return preview
end

function SpellBookPanel:ShowPreview(data)
    if not data or not data.creatureID then return end

    local preview = self:CreatePreview()
    if not preview then return end

    preview.title:SetText(data.name or "")
    preview.model.facing = 0
    preview.model.zoom = 0
    preview.model:SetFacing(0)
    pcall(preview.model.SetCreature, preview.model, data.creatureID)
    pcall(preview.model.SetPosition, preview.model, 0, 0, 0)
    preview:Show()
end

function SpellBookPanel:Create()
    if self.frame then return end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarcissusSirus_SpellBook", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 120, 40)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(S.Bg(0.97))
    S.WindowSounds(f, "igSpellBookOpen", "igSpellBookClose")
    f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(f, 5, 0.4)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(16), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText(L["Заклинания"])
    f.title = title

    local close = NS.Widgets.CreateCloseButton(f, 18, function() SpellBookPanel:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)

    local search = NS.Widgets.CreateThemedEditBox(f, 190, 22, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -40)
    search:SetScript("OnTextChanged", function(box)
        SpellBookPanel.filter = NS.Lower(strtrim(box:GetText() or ""))
        SpellBookPanel.page = 1
        SpellBookPanel:Update()
    end)
    f.search = search

    local ranks = NS.Widgets.CreateThemedCheckbox(f, L["Все ранги"],
        GetCVarBool and GetCVarBool("ShowAllSpellRanks"), function(value)
            SetCVar("ShowAllSpellRanks", value and "1" or "0")
            SpellBookPanel.page = 1
            SpellBookPanel:Update()
        end)
    ranks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD - math.ceil(ranks.text:GetStringWidth()) - 8, -40)
    f.ranks = ranks

    local rule = f:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -HEADER_H + 14)
    rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -HEADER_H + 14)
    rule:SetTexture("Interface\\Buttons\\WHITE8x8")
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    f.entries = {}
    for slot = 1, PER_PAGE do
        f.entries[slot] = self:CreateEntry(f, slot)
    end

    f.tabButtons = {}
    for index = 1, 8 do
        f.tabButtons[index] = self:CreateTabButton(f, index)
    end

    local pageLabel = f:CreateFontString(nil, "OVERLAY")
    pageLabel:SetFont(NS.FONT, NS.FS(11), "")
    pageLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pageLabel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -104, 20)
    f.pageLabel = pageLabel

    local prev = NS.Widgets.CreateThemedButton(f, "<", 30, 20, function()
        SpellBookPanel.page = math.max(1, (SpellBookPanel.page or 1) - 1)
        SpellBookPanel:Update()
    end)
    prev:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -56, 16)
    f.prev = prev

    local nextPage = NS.Widgets.CreateThemedButton(f, ">", 30, 20, function()
        SpellBookPanel.page = (SpellBookPanel.page or 1) + 1
        SpellBookPanel:Update()
    end)
    nextPage:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 16)
    f.nextPage = nextPage

    f.viewButtons = {}
    for index, view in ipairs(VIEWS) do
        local button = NS.Widgets.CreateThemedButton(f, L[view.label], 104, 22, function()
            SpellBookPanel.view = view.key
            SpellBookPanel.page = 1
            SpellBookPanel:Update()
        end)
        button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + (index - 1) * 110, 16)
        f.viewButtons[index] = button
    end

    f:SetScript("OnHide", function()
        if SpellBookPanel.previewFrame then SpellBookPanel.previewFrame:Hide() end
        SpellBookPanel:SyncButtons()
    end)

    local events = CreateFrame("Frame")
    events:RegisterEvent("SPELLS_CHANGED")
    events:RegisterEvent("LEARNED_SPELL_IN_TAB")
    events:RegisterEvent("COMPANION_LEARNED")
    events:RegisterEvent("COMPANION_UPDATE")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            for index = #UISpecialFrames, 1, -1 do
                if UISpecialFrames[index] == "NarcissusSirus_SpellBook" then table.remove(UISpecialFrames, index) end
            end
            return
        end
        if event == "PLAYER_REGEN_ENABLED" then
            local listed = false
            for _, name in ipairs(UISpecialFrames) do
                if name == "NarcissusSirus_SpellBook" then listed = true end
            end
            if not listed then tinsert(UISpecialFrames, "NarcissusSirus_SpellBook") end
            if SpellBookPanel._hidePending then
                SpellBookPanel._hidePending = nil
                SpellBookPanel.frame:Hide()
                SpellBookPanel.frame:SetAlpha(1)
            end
            if SpellBookPanel._pending then
                SpellBookPanel._pending = nil
                SpellBookPanel:BuildCastButtons()
                SpellBookPanel:SyncButtons()
            end
            if SpellBookPanel._updatePending then
                SpellBookPanel._updatePending = nil
                if SpellBookPanel.frame:IsShown() then SpellBookPanel:Update() end
            end
            return
        end
        if SpellBookPanel.frame and SpellBookPanel.frame:IsShown() then
            SpellBookPanel:Update()
        end
    end)
    f.events = events

    tinsert(UISpecialFrames, "NarcissusSirus_SpellBook")

    self.view = self.view or "spells"
    self.tab = self.tab or 1
    self.page = self.page or 1
    self.frame = f
    f:Hide()

    self:BuildCastButtons()
end

function SpellBookPanel:BuildCastButtons()
    local f = self.frame
    if not f or f.extraButtons then return end
    if InCombatLockdown() then
        self._pending = true
        return
    end

    f.extraButtons = {}
    f.iconButtons = {}
    for slot = 1, PER_PAGE do
        f.extraButtons[slot] = self:CreateCastButton(f, f.entries[slot], slot, "Extra")
        f.iconButtons[slot] = self:CreateCastButton(f, f.entries[slot], slot, "Icon")
    end
end

function SpellBookPanel:CurrentEntries()
    if self.view == "mounts" then
        return self:MountList()
    elseif self.view == "critters" then
        return self:CollectCompanions("CRITTER")
    elseif self.view == "professions" then
        return self:CollectProfessions()
    end

    local tabs = self.tabs or {}
    local tab = tabs[self.tab] or tabs[1]
    return tab and tab.entries or {}
end

function SpellBookPanel:Filtered(entries)
    local filter = self.filter
    if not filter or filter == "" then return entries end

    local matched = {}
    for _, entry in ipairs(entries) do
        if not entry.header and string.find(NS.Lower(entry.name), filter, 1, true) then
            matched[#matched + 1] = entry
        end
    end
    return matched
end

function SpellBookPanel:RaiseWidgets()
    local f = self.frame
    if not f then return end

    local base = f:GetFrameLevel()

    for slot = 1, PER_PAGE do
        local entry = f.entries[slot]
        if entry then entry:SetFrameLevel(base + 2) end

        local extra = f.extraButtons and f.extraButtons[slot]
        if extra and entry then extra:SetFrameLevel(entry:GetFrameLevel() + 4) end

        local iconButton = f.iconButtons and f.iconButtons[slot]
        if iconButton and entry then iconButton:SetFrameLevel(entry:GetFrameLevel() + 4) end
    end

    for _, button in ipairs(f.tabButtons) do
        button:SetFrameLevel(base + 4)
        button.backdrop:SetFrameLevel(base + 3)
    end
end

local function BindSpell(button, data)
    if not data or not data.castName then
        button:Hide()
        return
    end

    if button._castName ~= data.castName then
        button:SetAttribute("type", "spell")
        button:SetAttribute("spell", data.castName)
        button._castName = data.castName
    end
    button:Show()
end

function SpellBookPanel:SyncButtons()
    local f = self.frame
    if not f or not f.extraButtons then return end

    if InCombatLockdown() then
        self._pending = true
        return
    end

    self:RaiseWidgets()

    local shown = f:IsShown()
    for slot = 1, PER_PAGE do
        local entry = f.entries[slot]
        local data = shown and entry and entry.data or nil

        if data and data.companionKind then
            if entry._castName then
                entry:SetAttribute("type", nil)
                entry:SetAttribute("spell", nil)
                entry._castName = nil
            end
        elseif data and data.random then
            local pick = self:RandomFavorite()
            if pick then
                entry:SetAttribute("type", "spell")
                entry:SetAttribute("spell", pick)
                entry._castName = pick
            end
        elseif data and data.castName and not data.passive and not data.flyoutID and not data.header then
            if entry._castName ~= data.castName then
                entry:SetAttribute("type", "spell")
                entry:SetAttribute("spell", data.castName)
                entry._castName = data.castName
            end
        elseif entry._castName then
            entry:SetAttribute("type", nil)
            entry:SetAttribute("spell", nil)
            entry._castName = nil
        end

        BindSpell(f.extraButtons[slot], data and data.extra or nil)

        if data and data.companionKind then
            BindSpell(f.iconButtons[slot], data)
        else
            f.iconButtons[slot]:Hide()
        end
    end
end

function SpellBookPanel:ViewLabel()
    for _, view in ipairs(VIEWS) do
        if view.key == self.view then return L[view.label] end
    end
    return L["Заклинания"]
end

function SpellBookPanel:Update()
    if not self.frame then self:Create() end
    local f = self.frame
    if not f then return end
    if InCombatLockdown() then
        self._updatePending = true
        return
    end
    local S = NS.Styling

    self.tabs = self:BuildTabs()
    if not self.tabs[self.tab] then self.tab = 1 end

    local spellsView = self.view == "spells"

    for index, button in ipairs(f.tabButtons) do
        local tab = spellsView and self.tabs[index]
        if tab then
            button.label = tab.label
            button.icon:SetTexture(tab.texture)
            if index == self.tab then
                button.backdrop:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
                button.icon:SetDesaturated(false)
                button.icon:SetAlpha(1)
            else
                button.backdrop:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
                button.icon:SetDesaturated(true)
                button.icon:SetAlpha(0.7)
            end
            button:Show()
        else
            button:Hide()
        end
    end

    for index, view in ipairs(VIEWS) do
        local button = f.viewButtons[index]
        if view.key == self.view then
            button.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            button.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end

    local entries = self:Filtered(self:CurrentEntries())
    local pages = math.max(1, math.ceil(#entries / PER_PAGE))
    self.page = math.min(math.max(1, self.page or 1), pages)
    local first = (self.page - 1) * PER_PAGE

    for slot = 1, PER_PAGE do
        local entry = f.entries[slot]
        local data = entries[first + slot]

        if data then
            entry.data = data
            entry.icon:SetTexture(data.texture)
            entry.title:SetText(data.name)

            if data.header then
                entry.icon:Hide()
                entry.border:Hide()
                entry.plate:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)
                entry.title:ClearAllPoints()
                entry.title:SetPoint("LEFT", entry, "LEFT", 10, 0)
                entry.title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                entry.subtitle:SetText("")
            else
                entry.icon:Show()
                entry.border:Show()
                entry.plate:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.45)
                entry.title:ClearAllPoints()
                entry.title:SetPoint("TOPLEFT", entry.icon, "TOPRIGHT", 10, -6)
            end

            if data.header then
                entry.title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            elseif data.passive then
                entry.title:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                entry.subtitle:SetText(L["Пассивная"])
                entry.icon:SetDesaturated(true)
            else
                entry.title:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                entry.subtitle:SetText(data.rank or "")
                entry.icon:SetDesaturated(false)
            end

            if data.extra then
                entry.extraIcon:SetTexture(data.extra.texture)
                entry.extraIcon:Show()
                entry.extraBorder:Show()
            else
                entry.extraIcon:Hide()
                entry.extraBorder:Hide()
            end

            if data.flyoutID then entry.flyoutMark:Show() else entry.flyoutMark:Hide() end

            if data.random then entry.macroButton:Show() else entry.macroButton:Hide() end

            if data.companionKind == "MOUNT" and data.spellID then
                local favorites = self:Favorites()
                local marked = favorites[data.spellID]
                entry.favourite.mark:SetVertexColor(
                    marked and S.GOLD[1] or 0.15,
                    marked and S.GOLD[2] or 0.16,
                    marked and S.GOLD[3] or 0.20, 1)
                entry.favourite:Show()
            else
                entry.favourite:Hide()
            end

            entry:Show()
        else
            entry.data = nil
            entry.extraIcon:Hide()
            entry.extraBorder:Hide()
            entry.flyoutMark:Hide()
            entry.favourite:Hide()
            entry.macroButton:Hide()
            entry:Hide()
        end
    end

    f.pageLabel:SetText(string.format(L["Стр. %d из %d"], self.page, pages))

    if spellsView and self.tabs[self.tab] then
        f.title:SetText(self.tabs[self.tab].label)
    else
        f.title:SetText(self:ViewLabel())
    end

    self:SyncButtons()
end

function SpellBookPanel:Show()
    if InCombatLockdown() then
        NS.Print(L["в бою книга заклинаний не открывается"])
        return
    end
    if not self.frame then self:Create() end
    if not self.frame then return end
    self._hidePending = nil
    self.frame:SetAlpha(1)
    self:Update()
    self.frame:Show()
    self:RaiseWidgets()
    self:SyncButtons()
end

function SpellBookPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end

    if self.frame:IsShown() and not self._hidePending then
        self:Hide()
    else
        self:Show()
    end
end

function SpellBookPanel:Hide()
    if not self.frame then return end
    if InCombatLockdown() then
        if self.frame:IsShown() then
            self.frame:SetAlpha(0)
            self._hidePending = true
        end
        return
    end
    self.frame:Hide()
    self:SyncButtons()
end

NS.SpellBookPanel = SpellBookPanel
