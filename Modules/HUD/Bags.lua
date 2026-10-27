local addonName, NS = ...
local L = NS.L

local Bags = {}
NS.Bags = Bags

local WHITE = "Interface\\Buttons\\WHITE8x8"
local GLOW = "Interface\\Buttons\\CheckButtonHilight"
local COIN = "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
local QUEST_BANG = "Interface\\ContainerFrame\\UI-Icon-QuestBang"
local DIALOG_BG = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DIALOG_BG_DARK = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"
local DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local GOLD_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local TIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
local TIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local QUICKSLOT = "Interface\\Buttons\\UI-Quickslot2"
local EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local QUALITY_RING = "Interface\\Buttons\\UI-ActionButton-Border"
local MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local ROCK = "Interface\\FrameGeneral\\UI-Background-Rock"
local PARCHMENT = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"

local STYLES = {
    { key = "obsidian", name = "Обсидиан", frame = "flat", shadow = true, accentLines = true, cell = "edges" },
    { key = "classic", name = "Классика", frame = "dialog", pad = 14, title = "gold", cell = "stock" },
    { key = "gold", name = "Золото", frame = "gold", pad = 14, bg = { 0.55, 0.5, 0.45, 1 }, title = "gold", cell = "stock" },
    { key = "tooltip", name = "Подсказка", frame = "tooltip", pad = 10, bg = { 0.06, 0.06, 0.08, 0.94 },
      border = { 0.6, 0.6, 0.62, 1 }, title = "white", cell = "edges", cellBorder = { 0.28, 0.28, 0.3, 1 } },
    { key = "pixel", name = "Пиксель", frame = "flat", bg = { 0.06, 0.06, 0.06, 0.88 }, border = { 0, 0, 0, 1 }, shadow = true,
      title = "white", cell = "edges", cellBg = { 0.1, 0.1, 0.1, 1 }, cellBorder = { 0, 0, 0, 1 } },
    { key = "glass", name = "Стекло", frame = "flat", bg = { 0.08, 0.1, 0.14, 0.45 }, border = { 1, 1, 1, 0.15 },
      cell = "underline", cellBg = { 1, 1, 1, 0.06 } },
    { key = "neon", name = "Неон", frame = "flat", bg = { 0.01, 0.01, 0.03, 0.92 }, border = "accent", shadow = true,
      cell = "glow", cellBg = { 0.02, 0.02, 0.04, 1 }, cellBorder = "accentDim" },
    { key = "minimal", name = "Минимал", frame = "none", bg = { 0, 0, 0, 0.6 }, title = "white",
      cell = "underline", cellBg = { 1, 1, 1, 0.04 }, emptyAlpha = 0.35 },
    { key = "stained", name = "Витраж", frame = "flat", bg = { 0.04, 0.04, 0.05, 0.92 }, border = { 0.3, 0.3, 0.32, 1 },
      shadow = true, cell = "fill" },
    { key = "thick", name = "Рамки", frame = "flat", shadow = true, accentLines = true, cell = "edges", thickness = 2 },
    { key = "marble", name = "Мрамор", frame = "dialog", pad = 14, art = MARBLE, artColor = { 0.55, 0.55, 0.6, 1 },
      title = "gold", cell = "stock" },
    { key = "rock", name = "Камень", frame = "tooltip", pad = 10, art = ROCK, artColor = { 0.45, 0.42, 0.4, 1 },
      border = { 0.55, 0.5, 0.45, 1 }, title = "gold", cell = "edges", thickness = 2, cellBorder = { 0.15, 0.13, 0.11, 1 } },
    { key = "parchment", name = "Пергамент", frame = "gold", pad = 14, art = PARCHMENT, title = "brown", text = "dark", cell = "stock" },
}
Bags.STYLES = STYLES

local STYLE_BY_KEY = {}
for _, style in ipairs(STYLES) do STYLE_BY_KEY[style.key] = style end

local REQUIRED = { "frame", "cell" }

function Bags:AddStyle(row)
    if type(row) ~= "table" or type(row.key) ~= "string" or STYLE_BY_KEY[row.key] then return false end
    for _, field in ipairs(REQUIRED) do
        if row[field] == nil then row[field] = STYLES[1][field] end
    end
    row.name = row.name or row.key
    STYLES[#STYLES + 1] = row
    STYLE_BY_KEY[row.key] = row
    return true
end

local DARK_TEXT = { { 0.22, 0.13, 0.04 }, { 0.3, 0.2, 0.1 }, { 0.38, 0.27, 0.15 } }

local function Color(spec)
    local S = NS.Styling
    if spec == "accent" then return { S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1 } end
    if spec == "accentDim" then return { S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 1 } end
    return spec
end

local function TextColors(style)
    local S = NS.Styling
    local tr, tg, tb = NS.Look and NS.Look:Color("bags", "text")
    if tr then
        local custom = { tr, tg, tb }
        return custom, custom, { tr * 0.75, tg * 0.75, tb * 0.75 }
    end
    if style.text == "dark" then return DARK_TEXT[1], DARK_TEXT[2], DARK_TEXT[3] end
    return S.TEXT_BRIGHT, S.TEXT_NORMAL, S.TEXT_DIM
end
local BACKPACK = "Interface\\Buttons\\Button-Backpack-Up"
local ICON_BAGS = "Interface\\Icons\\INV_Misc_Bag_08"
local ICON_KEYS = "Interface\\Icons\\INV_Misc_Key_14"
local ICON_JUNK = "Interface\\Icons\\INV_Misc_Coin_01"

local BANK = -1
local KEYRING = -2
local REAGENT = -4
local BAG_IDS = { 0, 1, 2, 3, 4 }
local BANK_IDS = { -1, 5, 6, 7, 8, 9, 10, 11 }

local PAD = 8
local HEADER = 28
local SEARCH_H = 20
local STRIP_H = 26
local FOOTER = 22
local SECTION_TITLE = 15
local SECTION_GAP = 12
local MIN_WIDTH = 330

local OTHER_ADDONS = { "AdiBags", "Bagnon", "Combuctor", "ArkInventory", "OneBag3", "Baggins", "cargBags_Nivaya" }

local DEFAULTS = {
    enabled = true,
    style = "obsidian",
    layout = "grid",
    columns = 12,
    bankColumns = 14,
    size = 34,
    spacing = 3,
    scale = 100,
    itemLevel = true,
    qualityBorder = true,
    junkIcon = true,
    newGlow = true,
    newSection = true,
    setsSection = true,
    compactFree = true,
    autoSellJunk = true,
    tooltipCounts = true,
    showBagSlots = false,
    showKeyring = false,
}

local SECTIONS = {
    { key = "new", name = "Новое" },
    { key = "sets", name = "Комплекты" },
    { key = "equipment", name = "Экипировка" },
    { key = "consumable", name = "Расходуемое" },
    { key = "gems", name = "Самоцветы и символы" },
    { key = "trade", name = "Ремесло" },
    { key = "quest", name = "Задания" },
    { key = "containers", name = "Сумки и боеприпасы" },
    { key = "misc", name = "Прочее" },
    { key = "junk", name = "Хлам" },
    { key = "keys", name = "Ключи" },
    { key = "free", name = "Свободно" },
}

local CLASS_RANK = {
    [2] = 1, [4] = 2, [3] = 3, [16] = 4, [0] = 5, [7] = 6, [5] = 6,
    [9] = 7, [1] = 8, [11] = 9, [6] = 10, [15] = 11, [12] = 12, [13] = 13,
}

local SET_NAMES = { bags = "Сумки", bank = "Банк", reagent = "Реагенты" }
local COUNT_LABELS = {
    { "bags", "сумки" },
    { "bank", "банк" },
    { "reagent", "реагенты" },
    { "equip", "надето" },
}

local filledSettings

local function Settings()
    if not NS.db then return end
    if type(NS.db.bags) ~= "table" then NS.db.bags = {} end
    local db = NS.db.bags
    if db == filledSettings then return db end
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    filledSettings = db
    return db
end
Bags.Settings = Settings

function Bags:OtherAddon()
    if not IsAddOnLoaded then return end
    for _, name in ipairs(OTHER_ADDONS) do
        if IsAddOnLoaded(name) then return name end
    end
end

function Bags:Blocked()
    local other = self:OtherAddon()
    if other then return "addon", other end
end

local function ItemString(link)
    return link and link:match("|H(item:[%-%d:]+)|h") or (link and link:match("^item:[%-%d:]+$"))
end

local function LinkID(link)
    return link and tonumber(link:match("item:(%-?%d+)"))
end

local classByName

local function ClassFromType(itemType)
    if not itemType then return end
    if not classByName then
        classByName = {}
        for classID = 0, 16 do
            local name = GetItemClassInfo and GetItemClassInfo(classID)
            if name then classByName[name] = classID end
        end
    end
    return classByName[itemType]
end

local function Describe(e)
    if not e.link then return end
    local name, _, quality, ilvl, _, itemType, itemSubType, maxStack, equipLoc, texture, price = GetItemInfo(e.link)
    e.name = name
    e.quality = quality or e.quality
    e.ilvl = ilvl
    e.equipLoc = equipLoc
    e.maxStack = maxStack
    e.price = price
    e.itemType = itemType
    e.itemSubType = itemSubType
    e.texture = e.texture or texture or (e.id and GetItemIcon and GetItemIcon(e.id))

    local classID, subClassID
    if GetItemInfoInstant and e.id then
        local ok, _, _, _, _, _, c, s = pcall(GetItemInfoInstant, e.id)
        if ok then classID, subClassID = c, s end
    end
    e.classID = classID or ClassFromType(itemType)
    e.subClassID = subClassID
    e.pending = not name
end

local function ReadSlot(bag, slot)
    local texture, count, locked, quality, _, _, link = GetContainerItemInfo(bag, slot)
    local e = { bag = bag, slot = slot, texture = texture, count = count or 0, locked = locked and true or false, link = link }
    if link then
        if quality and quality >= 0 then e.quality = quality end
        e.id = GetContainerItemID(bag, slot) or LinkID(link)
        Describe(e)
        if bag ~= REAGENT and GetContainerItemQuestInfo then
            local isQuest, questID, active = GetContainerItemQuestInfo(bag, slot)
            e.questItem = (isQuest or questID) and true or false
            e.questStart = questID and not active and true or false
        end
        if bag >= 0 and C_NewItems and C_NewItems.IsNewItem then
            e.new = C_NewItems.IsNewItem(bag, slot)
        end
    end
    return e
end

local setItems = {}
local setOrder = {}

local function RebuildSets()
    wipe(setItems)
    wipe(setOrder)
    if not (GetNumEquipmentSets and GetEquipmentSetInfo and GetEquipmentSetItemIDs) then return end
    for index = 1, GetNumEquipmentSets() do
        local name = GetEquipmentSetInfo(index)
        local ok, ids = pcall(GetEquipmentSetItemIDs, name)
        if name and ok and type(ids) == "table" then
            setOrder[#setOrder + 1] = name
            for _, id in pairs(ids) do
                if type(id) == "number" and id > 0 and not setItems[id] then setItems[id] = name end
            end
        end
    end
end

local function SectionOf(e, db)
    if not e.link then return "free" end
    if e.bag == KEYRING then return "keys" end
    if db.newSection and e.new then return "new" end
    if e.quality == 0 then return "junk" end
    if db.setsSection and e.id and setItems[e.id] then return "set:" .. setItems[e.id] end
    local c = e.classID
    if e.questItem or c == 12 then return "quest" end
    if c == 2 or c == 4 then return "equipment" end
    if c == 0 then return "consumable" end
    if c == 3 or c == 16 then return "gems" end
    if c == 7 or c == 5 or c == 9 then return "trade" end
    if c == 1 or c == 6 or c == 11 then return "containers" end
    if c == 13 then return "keys" end
    if e.equipLoc and e.equipLoc ~= "" then return "equipment" end
    return "misc"
end

local function Rank(e)
    if e.quality == 0 then return 99 end
    return CLASS_RANK[e.classID or -1] or 50
end

local function Before(a, b)
    local ra, rb = Rank(a), Rank(b)
    if ra ~= rb then return ra < rb end
    local la, lb = a.equipLoc or "", b.equipLoc or ""
    if la ~= lb then return la < lb end
    local qa, qb = a.quality or 1, b.quality or 1
    if qa ~= qb then return qa > qb end
    local ia, ib = a.ilvl or 0, b.ilvl or 0
    if ia ~= ib then return ia > ib end
    local na, nb = a.name or "", b.name or ""
    if na ~= nb then return na < nb end
    local da, dbb = a.id or 0, b.id or 0
    if da ~= dbb then return da < dbb end
    return (a.count or 0) > (b.count or 0)
end

local function Store()
    if type(NarcissusSirusDB) ~= "table" then return end
    if type(NarcissusSirusDB.inventory) ~= "table" then NarcissusSirusDB.inventory = {} end
    local realm = GetRealmName() or "?"
    if type(NarcissusSirusDB.inventory[realm]) ~= "table" then NarcissusSirusDB.inventory[realm] = {} end
    return NarcissusSirusDB.inventory[realm]
end
Bags.Store = Store

local function Me()
    local store = Store()
    if not store then return end
    local name = UnitName("player")
    if not name then return end
    if type(store[name]) ~= "table" then store[name] = {} end
    local me = store[name]
    me.class = select(2, UnitClass("player"))
    return me, store, name
end

local function Capture(ids)
    local list = {}
    for _, bag in ipairs(ids) do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
            local item = ItemString(link)
            if item then list[#list + 1] = item .. ";" .. (count or 1) end
        end
    end
    return list
end

local counts = {}
local countsDirty = true

function Bags:SaveBags()
    local me = Me()
    if not me then return end
    me.bags = Capture(BAG_IDS)
    local equip = {}
    for slot = 1, 19 do
        local item = ItemString(GetInventoryItemLink("player", slot))
        if item then equip[#equip + 1] = item .. ";1" end
    end
    me.equip = equip
    me.money = GetMoney()
    me.time = time()
    countsDirty = true
end

function Bags:SaveBank()
    if not self.bankOpen then return end
    local me = Me()
    if not me then return end
    me.bank = Capture(BANK_IDS)
    if (GetContainerNumSlots(REAGENT) or 0) > 0 then
        me.reagent = Capture({ REAGENT })
    end
    countsDirty = true
end

local saveQueued

local function QueueSave()
    if saveQueued or not NS.After then return end
    saveQueued = true
    NS.After(1.5, function()
        saveQueued = nil
        Bags:SaveBags()
        Bags:SaveBank()
    end)
end

local function BuildCounts()
    wipe(counts)
    local store = Store()
    if not store then return end
    for char, data in pairs(store) do
        if type(data) == "table" then
            for _, pair in ipairs(COUNT_LABELS) do
                local list = data[pair[1]]
                if type(list) == "table" then
                    for _, entry in ipairs(list) do
                        local id, count = entry:match("^item:(%-?%d+).-;(%d+)$")
                        id = tonumber(id)
                        if id then
                            counts[id] = counts[id] or {}
                            local c = counts[id][char] or {}
                            counts[id][char] = c
                            c[pair[1]] = (c[pair[1]] or 0) + (tonumber(count) or 1)
                        end
                    end
                end
            end
        end
    end
    countsDirty = false
end

function Bags:ForgetCharacter(name)
    local store = Store()
    if store and name then store[name] = nil end
    countsDirty = true
    for _, f in ipairs({ self.bagWindow, self.bankWindow }) do
        if f and f.view and f.view.owner == name then self:View(f, nil) end
    end
end

function Bags:ForgetOthers()
    local store = Store()
    local me = UnitName("player")
    if not store then return end
    for name in pairs(store) do
        if name ~= me then store[name] = nil end
    end
    countsDirty = true
end

local function AddCounts(tip)
    local db = Settings()
    if not db or not db.tooltipCounts or not Bags.running or tip.narciCounted then return end
    local _, link = tip:GetItem()
    local id = LinkID(link)
    if not id then return end
    if countsDirty then BuildCounts() end
    local byChar = counts[id]
    if not byChar then return end
    tip.narciCounted = true

    local names = {}
    for name in pairs(byChar) do names[#names + 1] = name end
    table.sort(names)

    local store = Store()
    local total, lines = 0, 0
    for _, name in ipairs(names) do
        local c = byChar[name]
        local sum, parts = 0, {}
        for _, pair in ipairs(COUNT_LABELS) do
            local n = c[pair[1]]
            if n and n > 0 then
                sum = sum + n
                parts[#parts + 1] = L[pair[2]] .. " " .. n
            end
        end
        if sum > 0 then
            local class = store and store[name] and store[name].class
            local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            local r, g, b = 0.8, 0.8, 0.8
            if color then r, g, b = color.r, color.g, color.b end
            if lines == 0 then tip:AddLine(" ") end
            tip:AddDoubleLine(name, sum .. " (" .. table.concat(parts, ", ") .. ")", r, g, b, 1, 1, 1)
            total = total + sum
            lines = lines + 1
        end
    end
    if lines > 1 then
        local A = NS.Styling and NS.Styling.ACCENT or { 1, 1, 1 }
        tip:AddDoubleLine(L["Всего"], total, A[1], A[2], A[3], 1, 1, 1)
    end
    if lines > 0 then tip:Show() end
end

local function HookTooltip(tip)
    if not tip or tip.narciBagCounts then return end
    tip.narciBagCounts = true
    tip:HookScript("OnTooltipSetItem", AddCounts)
    tip:HookScript("OnTooltipCleared", function(self) self.narciCounted = nil end)
end

local pulse = CreateFrame("Frame")
local pulsing = {}
local pulseClock = 0
pulse:Hide()
pulse:SetScript("OnUpdate", function(self, elapsed)
    pulseClock = pulseClock + elapsed
    local alpha = 0.45 + 0.35 * math.sin(pulseClock * 4)
    local any
    for tex in pairs(pulsing) do
        if tex:IsShown() then
            tex:SetAlpha(alpha)
            any = true
        else
            pulsing[tex] = nil
        end
    end
    if not any then self:Hide() end
end)

local function SetGlow(b, on)
    local glow = b.narciGlow
    if on then
        glow:Show()
        pulsing[glow] = true
        pulse:Show()
    else
        glow:Hide()
        pulsing[glow] = nil
    end
end

local function SetEdgeColor(edges, r, g, b, a)
    for _, line in ipairs(edges) do line:SetVertexColor(r, g, b, a) end
end

local function Skin(b)
    local S = NS.Styling
    local name = b:GetName()

    local icon = b.icon or (name and _G[name .. "IconTexture"])
    if not icon then
        icon = b:CreateTexture(nil, "BORDER")
        b.icon = icon
    end
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.narciIcon = icon

    local normal = b:GetNormalTexture()
    if normal then
        normal:SetTexture(nil)
        normal:SetAlpha(0)
    end
    if b.IconBorder then b.IconBorder:SetAlpha(0) end
    if b.ItemContextOverlay then b.ItemContextOverlay:SetAlpha(0) end
    local quest = name and _G[name .. "IconQuestTexture"]
    if quest then quest:SetAlpha(0) end
    if b.HighlightFrame then b.HighlightFrame:SetAlpha(0) end

    local pushed = b:GetPushedTexture()
    if pushed then
        pushed:SetTexture(WHITE)
        pushed:SetVertexColor(1, 1, 1, 0.15)
        pushed:ClearAllPoints()
        pushed:SetPoint("TOPLEFT", 1, -1)
        pushed:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    b:SetHighlightTexture(WHITE, "ADD")
    local highlight = b:GetHighlightTexture()
    highlight:SetVertexColor(1, 1, 1, 0.12)
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetVertexColor(S.Tint(0.045, 0.045, 0.06, 0.9))
    b.narciBg = bg

    b.narciEdges = S.CreateEdges(b, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local frameTex = b:CreateTexture(nil, "ARTWORK")
    frameTex:SetTexture(QUICKSLOT)
    frameTex:SetPoint("CENTER", b, "CENTER", 0, -1)
    frameTex:Hide()
    b.narciFrameTex = frameTex

    local ring = b:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(QUALITY_RING)
    ring:SetBlendMode("ADD")
    ring:SetPoint("CENTER")
    ring:Hide()
    b.narciRing = ring

    local under = b:CreateTexture(nil, "OVERLAY")
    under:SetTexture(WHITE)
    under:SetHeight(2)
    under:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 1, 1)
    under:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    under:Hide()
    b.narciUnder = under

    local empty = b:CreateTexture(nil, "BORDER")
    empty:SetTexture(EMPTY_SLOT)
    empty:SetAllPoints()
    empty:Hide()
    b.narciEmpty = empty

    local count = b.Count or (name and _G[name .. "Count"])
    if not count then
        count = b:CreateFontString(nil, "OVERLAY")
        b.Count = count
    end
    NS.LSetFont(count, "bags", NS.FS(10), "OUTLINE")
    count:ClearAllPoints()
    count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
    count:SetJustifyH("RIGHT")
    b.narciCount = count

    local level = b:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(level, "bags", NS.FS(9), "OUTLINE")
    level:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
    b.narciLevel = level

    local junk = b:CreateTexture(nil, "OVERLAY")
    junk:SetTexture(COIN)
    junk:SetSize(12, 12)
    junk:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    junk:Hide()
    b.narciJunk = junk

    local questBang = b:CreateTexture(nil, "OVERLAY")
    questBang:SetTexture(_G.TEXTURE_ITEM_QUEST_BANG or QUEST_BANG)
    questBang:SetAllPoints(icon)
    questBang:Hide()
    b.narciQuest = questBang

    local glow = b:CreateTexture(nil, "OVERLAY")
    glow:SetTexture(GLOW)
    glow:SetBlendMode("ADD")
    glow:SetAllPoints()
    glow:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    glow:Hide()
    b.narciGlow = glow

    local free = b:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(free, "bags", NS.FS(12), "OUTLINE")
    free:SetPoint("CENTER")
    free:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    b.narciFree = free

    local cooldown = (name and _G[name .. "Cooldown"]) or b.Cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetPoint("TOPLEFT", 1, -1)
        cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
        b.narciCooldown = cooldown
    end

    b:HookScript("OnEnter", function(self)
        local e = self.narciEntry
        if e and e.new then
            e.new = false
            SetGlow(self, false)
        end
    end)
end

local function Paint(b, e, db)
    local S = NS.Styling
    b.narciEntry = e

    local icon = b.narciIcon
    if e.texture then
        icon:SetTexture(e.texture)
        icon:Show()
    else
        icon:Hide()
    end
    icon:SetDesaturated(e.locked and true or false)

    b.count = e.count
    if (e.count or 0) > 1 then
        b.narciCount:SetText(e.count)
        b.narciCount:Show()
    else
        b.narciCount:Hide()
    end

    local style = Bags:Style()
    local cell = style.cell or "edges"
    local size = b:GetWidth()
    local thickness = style.thickness or 1

    local qr, qg, qb
    if e.link then
        if e.questItem then
            qr, qg, qb = 1, 0.82, 0.2
        elseif db.qualityBorder and e.quality and e.quality >= 2 then
            qr, qg, qb = GetItemQualityColor(e.quality)
        end
    end

    local edges = b.narciEdges
    edges[1]:SetHeight(thickness)
    edges[2]:SetHeight(thickness)
    edges[3]:SetWidth(thickness)
    edges[4]:SetWidth(thickness)

    local inset = cell == "stock" and 0 or thickness
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", b, "TOPLEFT", inset, -inset)
    icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -inset, inset)
    if cell == "stock" then
        icon:SetTexCoord(0, 1, 0, 1)
    else
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local cellBg = Color(style.cellBg)
    if e.link then
        if cell == "fill" and qr then
            b.narciBg:SetVertexColor(qr * 0.4, qg * 0.4, qb * 0.4, 0.95)
        elseif cellBg then
            b.narciBg:SetVertexColor(cellBg[1], cellBg[2], cellBg[3], cellBg[4] or 1)
        else
            b.narciBg:SetVertexColor(S.Tint(0.045, 0.045, 0.06, 0.9))
        end
    elseif e.bagType and e.bagType ~= 0 then
        b.narciBg:SetVertexColor(S.ACCENT_DIM[1] * 0.35, S.ACCENT_DIM[2] * 0.35, S.ACCENT_DIM[3] * 0.35, 0.9)
    elseif cellBg then
        b.narciBg:SetVertexColor(cellBg[1], cellBg[2], cellBg[3], (cellBg[4] or 1) * 0.7)
    else
        b.narciBg:SetVertexColor(S.Tint(0.03, 0.03, 0.04, 0.75))
    end

    if cell == "stock" then
        b.narciFrameTex:SetSize(size * 64 / 37, size * 64 / 37)
        b.narciFrameTex:Show()
        if e.link or e.texture then b.narciEmpty:Hide() else b.narciEmpty:Show() end
    else
        b.narciFrameTex:Hide()
        b.narciEmpty:Hide()
    end

    if cell == "stock" or cell == "underline" then
        for _, line in ipairs(edges) do line:Hide() end
    else
        for _, line in ipairs(edges) do line:Show() end
        local border = Color(style.cellBorder) or S.BORDER
        local r, g, bl, a = border[1], border[2], border[3], e.link and 0.9 or 0.45
        if qr and cell ~= "glow" then
            r, g, bl, a = qr, qg, qb, 1
        end
        SetEdgeColor(edges, r, g, bl, a)
    end

    if qr and (cell == "stock" or cell == "glow") then
        b.narciRing:SetSize(size * 1.85, size * 1.85)
        b.narciRing:SetVertexColor(qr, qg, qb, cell == "glow" and 0.95 or 0.8)
        b.narciRing:Show()
    else
        b.narciRing:Hide()
    end

    if qr and cell == "underline" then
        b.narciUnder:SetVertexColor(qr, qg, qb, 1)
        b.narciUnder:Show()
    else
        b.narciUnder:Hide()
    end

    local showLevel = db.itemLevel and e.link and e.ilvl and e.ilvl > 1
        and (e.classID == 2 or e.classID == 4) and e.equipLoc and e.equipLoc ~= ""
        and e.equipLoc ~= "INVTYPE_BODY" and e.equipLoc ~= "INVTYPE_TABARD"
    if showLevel then
        b.narciLevel:SetText(e.ilvl)
        local qr, qg, qb = GetItemQualityColor(e.quality or 1)
        b.narciLevel:SetTextColor(qr, qg, qb)
        b.narciLevel:Show()
    else
        b.narciLevel:Hide()
    end

    if db.junkIcon and e.link and e.quality == 0 and (e.price or 0) > 0 then
        b.narciJunk:Show()
    else
        b.narciJunk:Hide()
    end

    if e.questStart then b.narciQuest:Show() else b.narciQuest:Hide() end

    SetGlow(b, db.newGlow and e.new and true or false)

    if e.freeCount and e.freeCount > 1 then
        b.narciFree:SetText(e.freeCount)
        b.narciFree:Show()
    else
        b.narciFree:Hide()
    end

    local cooldown = b.narciCooldown
    if cooldown then
        if e.link and not e.ghost and e.bag ~= REAGENT then
            local start, duration, enable = GetContainerItemCooldown(e.bag, e.slot)
            CooldownFrame_SetTimer(cooldown, start, duration, enable)
        else
            cooldown:Hide()
        end
    end
end

local function TemplateFor(bag)
    if bag == BANK then return "BankItemButtonGenericTemplate" end
    if bag == REAGENT then return "ReagentBankItemButtonGenericTemplate" end
    return "ContainerFrameItemButtonTemplate"
end

local DISENCHANT = 13262
local PRIME_DISENCHANT = 311891
local MILLING = 51005
local PROSPECTING = 31252
local PICK_LOCK = 1804
local SKELETON_KEYS = { 43853, 43854, 15872, 15871, 15870, 15869 }
local ICON_DECONSTRUCT = "Interface\\Icons\\INV_Rod_Enchantedcobalt"

local skills = {}
local processCache = {}
local scanTip
local overlay

local function KnownSpell(id)
    local name = GetSpellInfo(id)
    return name and GetSpellInfo(name) and name or nil
end

function Bags:UpdateSkills()
    local prime = IsSpellKnown and IsSpellKnown(PRIME_DISENCHANT) and GetSpellInfo(PRIME_DISENCHANT)
    skills.disenchant = prime or KnownSpell(DISENCHANT)
    skills.mill = KnownSpell(MILLING)
    skills.prospect = KnownSpell(PROSPECTING)
    skills.lock = KnownSpell(PICK_LOCK)
    wipe(processCache)
end

local function SkeletonKey()
    for _, id in ipairs(SKELETON_KEYS) do
        if GetItemCount(id) > 0 then return id end
    end
end

function Bags:CanDeconstruct()
    return (skills.disenchant or skills.mill or skills.prospect or skills.lock or SkeletonKey()) and true or false
end

local function ScanBagItem(bag, slot, test)
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "NarciSirus_BagScanTip", UIParent, "GameTooltipTemplate")
    end
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetBagItem(bag, slot)
    local result
    for index = 2, scanTip:NumLines() do
        local line = _G["NarciSirus_BagScanTipTextLeft" .. index]
        local text = line and line:GetText()
        if text then
            result = test(text)
            if result ~= nil then break end
        end
    end
    scanTip:Hide()
    return result
end

local disenchantPrefix = ITEM_DISENCHANT_MIN_SKILL and ITEM_DISENCHANT_MIN_SKILL:match("^(.-)%%s")

local function DisenchantLine(text)
    if text == ITEM_DISENCHANT_NOT_DISENCHANTABLE then return false end
    if text == ITEM_DISENCHANT_ANY_SKILL then return true end
    if disenchantPrefix and text:find(disenchantPrefix, 1, true) == 1 then return true end
end

local function HasLine(pattern)
    return function(text)
        if pattern and text:find(pattern, 1, true) then return true end
    end
end

local function ProcessOf(e)
    if not e or not e.link or e.ghost or not e.bag or e.bag < 0 or e.bag > 4 then return end

    local key = not skills.lock and SkeletonKey()
    if (skills.lock or key) and LOCKED and ScanBagItem(e.bag, e.slot, HasLine(LOCKED)) then
        if skills.lock then return "spell", skills.lock end
        return "item", "item:" .. key
    end

    local process = e.id and processCache[e.id]
    if process == nil and e.id then
        process = false
        if skills.prospect and ScanBagItem(e.bag, e.slot, HasLine(ITEM_PROSPECTABLE)) then
            process = "prospect"
        elseif skills.mill and ScanBagItem(e.bag, e.slot, HasLine(ITEM_MILLABLE)) then
            process = "mill"
        elseif skills.disenchant then
            local scanned = ScanBagItem(e.bag, e.slot, DisenchantLine)
            if scanned == nil then
                scanned = e.quality and e.quality >= 2 and e.quality <= 4
                    and (e.classID == 2 or e.classID == 4) and e.equipLoc and e.equipLoc ~= ""
            end
            if scanned then process = "disenchant" end
        end
        if not e.pending then processCache[e.id] = process end
    end

    if process == "prospect" and (e.count or 0) >= 5 then return "spell", skills.prospect end
    if process == "mill" and (e.count or 0) >= 5 then return "spell", skills.mill end
    if process == "disenchant" then return "spell", skills.disenchant end
end

local function HideOverlay()
    if not overlay or not overlay:IsShown() then return end
    if InCombatLockdown() then
        overlay:SetAlpha(0)
        overlay.pendingHide = true
        return
    end
    overlay:ClearAllPoints()
    overlay:SetAlpha(1)
    overlay:Hide()
    if ActionButton_HideOverlayGlow then ActionButton_HideOverlayGlow(overlay) end
end
Bags.HideOverlay = HideOverlay

local function CreateOverlay()
    overlay = CreateFrame("Button", "NarciSirus_DeconstructButton", UIParent, "SecureActionButtonTemplate")
    overlay:SetFrameStrata("TOOLTIP")
    overlay:RegisterForClicks("LeftButtonUp")
    overlay:Hide()
    overlay:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(self.bag, self.slot)
        GameTooltip:Show()
    end)
    overlay:SetScript("OnLeave", function()
        GameTooltip:Hide()
        HideOverlay()
    end)
end

local function ShowOverlay(b)
    if not Bags.deconstruct or InCombatLockdown() then return end
    local e = b.narciEntry
    local kind, value = ProcessOf(e)
    if not kind then return end
    if not overlay then CreateOverlay() end
    overlay.bag = e.bag
    overlay.slot = e.slot
    overlay:SetAttribute("type1", kind)
    overlay:SetAttribute("spell", kind == "spell" and value or nil)
    overlay:SetAttribute("item", kind == "item" and value or nil)
    overlay:SetAttribute("target-bag", e.bag)
    overlay:SetAttribute("target-slot", e.slot)
    overlay:ClearAllPoints()
    overlay:SetAllPoints(b)
    overlay:SetAlpha(1)
    overlay:Show()
    if ActionButton_ShowOverlayGlow then ActionButton_ShowOverlayGlow(overlay) end
    GameTooltip:SetOwner(overlay, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(e.bag, e.slot)
    GameTooltip:Show()
end

function Bags:SetDeconstruct(on)
    on = on and self:CanDeconstruct() or false
    self.deconstruct = on
    if not on then HideOverlay() end
    if self.bagWindow and self.bagWindow:IsShown() then self:Layout(self.bagWindow) end
    if self.bankWindow and self.bankWindow:IsShown() then self:Layout(self.bankWindow) end
end

local function SlotButton(f, bag, slot)
    f.buttons[bag] = f.buttons[bag] or {}
    local b = f.buttons[bag][slot]
    if b then return b end

    local holder = f.holders[bag]
    if not holder then
        holder = CreateFrame("Frame", nil, f.content)
        holder:SetAllPoints(f.content)
        holder:SetID(bag)
        f.holders[bag] = holder
    end

    b = CreateFrame("Button", "NarciSirus_BagSlot" .. (bag + 10) .. "_" .. slot, holder, TemplateFor(bag))
    b:SetID(slot)
    Skin(b)
    if bag ~= REAGENT then b:HookScript("OnEnter", ShowOverlay) end
    f.buttons[bag][slot] = b
    return b
end

local function GhostButton(f, index)
    local b = f.ghosts[index]
    if b then return b end

    b = CreateFrame("Button", nil, f.content)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    Skin(b)
    b:SetScript("OnEnter", function(self)
        local e = self.narciEntry
        if not (e and e.link) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(e.link)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", function(self)
        local e = self.narciEntry
        if not (e and e.link and IsModifiedClick()) then return end
        local _, full = GetItemInfo(e.link)
        if full then HandleModifiedItemClick(full) end
    end)
    f.ghosts[index] = b
    return b
end

local function BagListFor(f)
    if f.kind == "bank" then
        if f.tab == "reagent" then return { REAGENT } end
        return BANK_IDS
    end
    local list = { 0, 1, 2, 3, 4 }
    local db = Settings()
    if (db and db.showKeyring) or (IsBagOpen and IsBagOpen(KEYRING)) then
        list[#list + 1] = KEYRING
    end
    return list
end

local function Collect(f)
    local entries = {}
    for _, bag in ipairs(BagListFor(f)) do
        local size
        if bag == KEYRING then
            size = GetKeyRingSize and GetKeyRingSize() or 0
        else
            size = GetContainerNumSlots(bag) or 0
        end
        local bagType = 0
        if bag ~= KEYRING and bag ~= REAGENT and size > 0 then
            bagType = select(2, GetContainerNumFreeSlots(bag)) or 0
        end
        for slot = 1, size do
            local e = ReadSlot(bag, slot)
            e.bagType = bagType
            entries[#entries + 1] = e
        end
    end
    return entries
end

local function CachedEntries(owner, set)
    local store = Store()
    local data = store and store[owner]
    local list = data and data[set]
    local entries = {}
    if type(list) ~= "table" then return entries end
    for _, entry in ipairs(list) do
        local item, count = entry:match("^(item:[%-%d:]+);(%d+)$")
        if item then
            local e = { ghost = true, link = item, count = tonumber(count) or 1, id = LinkID(item) }
            Describe(e)
            entries[#entries + 1] = e
        end
    end
    return entries
end

local function Matches(e, text)
    if not text or text == "" then return true end
    if not e.link then return false end
    local name = e.name and NS.Lower(e.name)
    if name and name:find(text, 1, true) then return true end
    if e.itemType and NS.Lower(e.itemType):find(text, 1, true) then return true end
    if e.itemSubType and NS.Lower(e.itemSubType):find(text, 1, true) then return true end
    return false
end

function Bags:Dim(f)
    for b in pairs(f.used) do
        local e = b.narciEntry
        local alpha = 1
        if e and not e.link then alpha = self:Style().emptyAlpha or 1 end
        if e then
            if not Matches(e, f.search) then alpha = 0.2 end
            if f.focusBag and e.bag ~= f.focusBag then alpha = 0.2 end
            if self.deconstruct and not f.view and not ProcessOf(e) then alpha = math.min(alpha, 0.3) end
        end
        b:SetAlpha(alpha)
    end
end

local function Title(f, index)
    local text = f.titles[index]
    if not text then
        local S = NS.Styling
        text = f.content:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(text, "bags", NS.FS(10), "")
        text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        text:SetJustifyH("LEFT")
        local rule = f.content:CreateTexture(nil, "ARTWORK")
        rule:SetTexture(WHITE)
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
        local A = S.ACCENT
        rule:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.5, A[1], A[2], A[3], 0)
        text.rule = rule
        f.titles[index] = text
    end
    return text
end

function Bags:Style()
    local db = Settings()
    return STYLE_BY_KEY[db and db.style] or STYLES[1]
end

function Bags:ApplyWindowStyle(f)
    local S = NS.Styling
    local style = self:Style()
    local pad = style.pad or PAD
    local inset = pad - PAD
    f.pad = pad
    f.styleKey = style.key

    local artInset = 3
    if style.frame == "dialog" or style.frame == "gold" then
        f:SetBackdrop({
            bgFile = style.frame == "gold" and DIALOG_BG_DARK or DIALOG_BG,
            edgeFile = style.frame == "gold" and GOLD_EDGE or DIALOG_EDGE,
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        local bg = style.bg or { 1, 1, 1, 1 }
        f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        f:SetBackdropBorderColor(1, 1, 1, 1)
        artInset = 11
    elseif style.frame == "tooltip" then
        f:SetBackdrop({
            bgFile = TIP_BG, edgeFile = TIP_EDGE,
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        local bg = style.bg or { 0.06, 0.06, 0.08, 0.94 }
        f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        local border = Color(style.border) or { 0.6, 0.6, 0.6, 1 }
        f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        artInset = 4
    elseif style.frame == "none" then
        f:SetBackdrop({ bgFile = WHITE })
        local bg = style.bg or { 0, 0, 0, 0.6 }
        f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        artInset = 0
    else
        f:SetBackdrop({
            bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        if style.bg then
            f:SetBackdropColor(style.bg[1], style.bg[2], style.bg[3], style.bg[4] or 1)
        else
            f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        end
        local border = Color(style.border) or S.BORDER
        f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    end

    local lr, lg, lb = NS.Look:Color("bags", "bg")
    if lr then
        local _, _, _, la = f:GetBackdropColor()
        f:SetBackdropColor(lr, lg, lb, la or 0.95)
    end
    local er, eg, eb = NS.Look:Color("bags", "border")
    if er then f:SetBackdropBorderColor(er, eg, eb, 1) end

    if style.art then
        local c = style.artColor or { 1, 1, 1, 1 }
        f.art:SetTexture(style.art)
        f.art:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        f.art:ClearAllPoints()
        f.art:SetPoint("TOPLEFT", f, "TOPLEFT", artInset, -artInset)
        f.art:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -artInset, artInset)
        f.art:Show()
    else
        f.art:Hide()
    end

    if style.shadow then f.shadow:Show() else f.shadow:Hide() end
    if style.accentLines then
        f.topLine:Show()
        f.bottomLine:Show()
    else
        f.topLine:Hide()
        f.bottomLine:Hide()
    end

    local titleColor = S.ACCENT
    if style.title == "gold" then
        titleColor = S.GOLD
    elseif style.title == "white" then
        titleColor = { 1, 1, 1 }
    elseif style.title == "brown" then
        titleColor = { 0.35, 0.18, 0.03 }
    end
    f.title:SetTextColor(titleColor[1], titleColor[2], titleColor[3])

    f.title:ClearAllPoints()
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", pad + 2, -(9 + inset))
    f.close:ClearAllPoints()
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(pad - 2), -(6 + inset))
    f.searchBox:ClearAllPoints()
    f.searchBox:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -(HEADER + inset))
    f.searchBox:SetPoint("TOPRIGHT", f, "TOPRIGHT", -pad, -(HEADER + inset))

    local bright, normal, dim = TextColors(style)
    f.freeText:ClearAllPoints()
    f.freeText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", pad + 2, pad + 2)
    f.freeText:SetTextColor(dim[1], dim[2], dim[3])
    f.moneyText:ClearAllPoints()
    f.moneyText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(pad + 2), pad + 2)
    f.moneyText:SetTextColor(bright[1], bright[2], bright[3])
    f.currencyColor = normal
end

function Bags:Layout(f)
    local db = Settings()
    if not db then return end
    local S = NS.Styling

    local size, spacing = db.size, db.spacing
    local step = size + spacing
    local columns = f.kind == "bank" and db.bankColumns or db.columns
    if f.styleKey ~= self:Style().key then self:ApplyWindowStyle(f) end
    local pad = f.pad or PAD
    local minContent = MIN_WIDTH - pad * 2
    if columns * step - spacing < minContent then
        columns = math.floor((minContent + spacing) / step)
    end
    local width = columns * step - spacing

    local entries
    if f.view then
        entries = CachedEntries(f.view.owner, f.view.set)
    else
        entries = Collect(f)
    end

    local old = f.used
    f.used = {}
    f.pending = nil
    local ghostIndex = 0

    local function Place(e, x, y)
        local b
        if e.ghost then
            ghostIndex = ghostIndex + 1
            b = GhostButton(f, ghostIndex)
        else
            b = SlotButton(f, e.bag, e.slot)
        end
        b:SetSize(size, size)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f.content, "TOPLEFT", x, -y)
        Paint(b, e, db)
        b:Show()
        f.used[b] = true
        if e.pending then f.pending = true end
    end

    for _, title in ipairs(f.titles) do
        title:Hide()
        title.rule:Hide()
    end

    local height = 0
    local sections = db.layout == "categories" and f.tab ~= "reagent"

    if sections then
        local groups = {}
        for _, e in ipairs(entries) do
            local key = SectionOf(e, db)
            groups[key] = groups[key] or {}
            table.insert(groups[key], e)
        end

        local x, y, rowH, titleIndex = 0, 0, 0, 0
        local order = {}
        for _, section in ipairs(SECTIONS) do
            if section.key == "sets" then
                for _, name in ipairs(setOrder) do
                    order[#order + 1] = { key = "set:" .. name, title = name }
                end
            else
                order[#order + 1] = { key = section.key, title = L[section.name] }
            end
        end

        for _, section in ipairs(order) do
            local list = groups[section.key]
            if list and #list > 0 then
                local total = #list
                if section.key == "free" then
                    if db.compactFree then
                        local first = list[1]
                        for _, e in ipairs(list) do
                            if (e.bagType or 0) == 0 then first = e break end
                        end
                        first.freeCount = total
                        list = { first }
                    end
                else
                    table.sort(list, Before)
                end

                titleIndex = titleIndex + 1
                local title = Title(f, titleIndex)
                title:SetText(section.title .. "  " .. total)
                local cols = math.min(#list, columns)
                local w = math.min(width, math.max(cols * step - spacing, title:GetStringWidth() + 4))
                local rows = math.ceil(#list / cols)
                local h = SECTION_TITLE + rows * step - spacing

                if x > 0 and x + w > width then
                    x = 0
                    y = y + rowH + 8
                    rowH = 0
                end

                title:ClearAllPoints()
                title:SetPoint("TOPLEFT", f.content, "TOPLEFT", x, -y)
                title:SetWidth(w)
                title.rule:SetWidth(w)
                local _, _, dimText = TextColors(self:Style())
                title:SetTextColor(dimText[1], dimText[2], dimText[3])
                title:Show()
                title.rule:Show()

                for index, e in ipairs(list) do
                    local col = (index - 1) % cols
                    local row = math.floor((index - 1) / cols)
                    Place(e, x + col * step, y + SECTION_TITLE + row * step)
                end

                x = x + w + SECTION_GAP
                rowH = math.max(rowH, h)
            end
        end
        height = y + rowH
    else
        for index, e in ipairs(entries) do
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            Place(e, col * step, row * step)
        end
        local rows = math.ceil(#entries / columns)
        height = rows > 0 and rows * step - spacing or 0
    end

    if old then
        for b in pairs(old) do
            if not f.used[b] then
                b:Hide()
                b.narciEntry = nil
                SetGlow(b, false)
            end
        end
    end

    if f.lockNotice then
        local locked = f.kind == "bank" and f.tab == "reagent" and not f.view
            and IsReagentBankUnlocked and not IsReagentBankUnlocked()
        if locked then
            f.lockNotice:Show()
            height = math.max(height, 70)
        else
            f.lockNotice:Hide()
        end
    end

    self:UpdateStrip(f)
    local top = HEADER + SEARCH_H + 8 + (pad - PAD)
    if f.strip:IsShown() then top = top + STRIP_H + 4 end
    f.content:ClearAllPoints()
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", pad, -top)
    f.content:SetSize(width, math.max(height, 1))
    local currencyH = self:UpdateCurrencyRow(f, width)
    f:SetSize(width + pad * 2, top + height + 6 + FOOTER + currencyH + pad)
    f:SetScale((db.scale or 100) / 100)

    self:Dim(f)
    self:UpdateFooter(f)
    self:UpdateHeader(f)
end

local queued = {}
local layoutDriver = CreateFrame("Frame")
layoutDriver:Hide()
layoutDriver:SetScript("OnUpdate", function(self)
    self:Hide()
    for f in pairs(queued) do
        queued[f] = nil
        if f:IsShown() then Bags:Layout(f) end
    end
end)

local function Queue(f)
    if not f then return end
    queued[f] = true
    layoutDriver:Show()
end

function Bags:Refresh()
    Queue(self.bagWindow)
    Queue(self.bankWindow)
end

local CURRENCY_H = 18

function Bags:ListCurrencies(chosen)
    local list, collapsed = {}, {}
    if not GetCurrencyListSize or not GetCurrencyListInfo then return list end
    self.readingCurrencies = true
    local index = 1
    while index <= (GetCurrencyListSize() or 0) do
        local name, isHeader, isExpanded, _, _, count, extra, icon, itemID = GetCurrencyListInfo(index)
        if name then
            if isHeader then
                if not isExpanded and ExpandCurrencyList then
                    table.insert(collapsed, 1, index)
                    ExpandCurrencyList(index, 1)
                end
            elseif not chosen or chosen[name] then
                list[#list + 1] = { name = name, count = count or 0, icon = icon, itemID = itemID, extra = extra }
            end
        end
        index = index + 1
    end
    for _, header in ipairs(collapsed) do ExpandCurrencyList(header, 0) end
    self.readingCurrencies = nil
    return list
end

function Bags:Currencies()
    local db = Settings()
    if not db or db.showCurrency == false then return {} end
    if type(db.currencies) == "table" and next(db.currencies) then
        return self:ListCurrencies(db.currencies)
    end
    local list = {}
    if GetBackpackCurrencyInfo then
        for index = 1, (MAX_WATCHED_TOKENS or 3) do
            local name, count, extra, icon, itemID = GetBackpackCurrencyInfo(index)
            if name then
                list[#list + 1] = { name = name, count = count or 0, icon = icon, itemID = itemID, extra = extra, watch = index }
            end
        end
    end
    return list
end

local function CurrencyTooltip(button)
    local entry = button.entry
    if not entry then return end
    GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
    if entry.watch and GameTooltip.SetBackpackToken then
        GameTooltip:SetBackpackToken(entry.watch)
    else
        GameTooltip:SetText(entry.name, 1, 1, 1)
    end
    if entry.itemID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local ok, _, _, _, week, weekMax, total = pcall(C_CurrencyInfo.GetCurrencyInfo, entry.itemID)
        if ok then
            if weekMax and weekMax > 0 then
                GameTooltip:AddDoubleLine(L["За неделю"], (week or 0) .. " / " .. weekMax, 0.7, 0.7, 0.75, 1, 1, 1)
            end
            if total and total > 0 then
                GameTooltip:AddDoubleLine(L["Предел"], entry.count .. " / " .. total, 0.7, 0.7, 0.75, 1, 1, 1)
            end
        end
    end
    GameTooltip:Show()
end

function Bags:UpdateCurrencyRow(f, width)
    local row = f.currencyRow
    if not row then
        row = CreateFrame("Frame", nil, f)
        row.buttons = {}
        f.currencyRow = row
    end

    local items = (f.kind == "bags" and not f.view) and self:Currencies() or {}
    if #items == 0 then
        row:Hide()
        return 0
    end

    local color = f.currencyColor or NS.Styling.TEXT_NORMAL
    local x, line = 0, 0
    for index, entry in ipairs(items) do
        local button = row.buttons[index]
        if not button then
            button = CreateFrame("Button", nil, row)
            button:SetHeight(CURRENCY_H - 2)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(14, 14)
            button.icon:SetPoint("LEFT", button, "LEFT", 0, 0)
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button.text = button:CreateFontString(nil, "OVERLAY")
            NS.LSetFont(button.text, "bags", NS.FS(11), "")
            button.text:SetPoint("LEFT", button.icon, "RIGHT", 4, 0)
            button:SetScript("OnEnter", CurrencyTooltip)
            button:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.buttons[index] = button
        end
        button.entry = entry
        button.icon:SetTexture(entry.icon)
        button.text:SetText(BreakUpLargeNumbers and BreakUpLargeNumbers(entry.count) or tostring(entry.count))
        button.text:SetTextColor(color[1], color[2], color[3])
        local w = 18 + (button.text:GetStringWidth() or 20) + 12
        button:SetWidth(w)
        if x > 0 and x + w > width then
            x = 0
            line = line + 1
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", row, "TOPLEFT", x, -line * CURRENCY_H)
        button:Show()
        x = x + w
    end
    for index = #items + 1, #row.buttons do row.buttons[index]:Hide() end

    local height = (line + 1) * CURRENCY_H
    local pad = f.pad or PAD
    row:ClearAllPoints()
    row:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", pad + 2, pad + FOOTER)
    row:SetSize(width, height)
    row:Show()
    return height
end

local function FreeSlots(ids)
    local free, total = 0, 0
    for _, bag in ipairs(ids) do
        local slots = GetContainerNumSlots(bag) or 0
        if slots > 0 then
            total = total + slots
            free = free + (GetContainerNumFreeSlots(bag) or 0)
        end
    end
    return free, total
end

function Bags:UpdateFooter(f)
    if f.view then
        local store = Store()
        local data = store and store[f.view.owner]
        local stamp = data and data.time and date("%d.%m %H:%M", data.time) or ""
        f.freeText:SetText(L["Сохранено"] .. " " .. stamp)
        f.moneyText:SetText(data and data.money and GetMoneyString(data.money) or "")
        return
    end

    if f.kind == "bank" then
        if f.tab == "reagent" then
            local slots = GetContainerNumSlots(REAGENT) or 0
            local free = GetContainerNumFreeSlots(REAGENT) or 0
            f.freeText:SetText(L["Свободно"] .. ": " .. free .. "/" .. slots)
        else
            local free, total = FreeSlots(BANK_IDS)
            f.freeText:SetText(L["Свободно"] .. ": " .. free .. "/" .. total)
        end
        f.moneyText:SetText("")
        return
    end

    local free, total = FreeSlots(BAG_IDS)
    f.freeText:SetText(L["Свободно"] .. ": " .. free .. "/" .. total)
    f.moneyText:SetText(GetMoneyString(GetMoney()))
end

function Bags:UpdateHeader(f)
    local db = Settings()
    local S = NS.Styling

    if f.view then
        local store = Store()
        local data = store and store[f.view.owner]
        local class = data and data.class
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        local name = f.view.owner
        if color then name = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name) end
        f.title:SetText(name .. ": " .. L[SET_NAMES[f.view.set]])
    elseif f.kind == "bank" then
        f.title:SetText("")
    else
        f.title:SetText(L["Сумки"])
    end

    for _, button in ipairs(f.liveButtons) do
        if f.view then button:Hide() else button:Show() end
    end
    if f.backButton then
        if f.view then f.backButton:Show() else f.backButton:Hide() end
    end

    if f.layoutButton then f.layoutButton:Refresh(db.layout) end
    if f.slotsButton then f.slotsButton:SetActive(db.showBagSlots) end
    if f.keyButton then f.keyButton:SetActive(db.showKeyring) end
    if f.deconstructButton then
        f.deconstructButton:SetActive(self.deconstruct)
        if self:CanDeconstruct() and not f.view then f.deconstructButton:Show() else f.deconstructButton:Hide() end
    end

    if f.tabs then
        for key, tab in pairs(f.tabs) do
            tab:SetActive(f.tab == key)
            if key == "reagent" then
                if IsReagentBankUnlocked then tab:Show() else tab:Hide() end
            end
        end
        if f.depositButton then
            if DepositReagentBank and IsReagentBankUnlocked and IsReagentBankUnlocked() then
                f.depositButton:Show()
            else
                f.depositButton:Hide()
            end
        end
    end
end

local function HeaderButton(parent, icon, tip, onClick)
    local S = NS.Styling
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetVertexColor(S.Tint(0.06, 0.06, 0.09, 0.9))

    local edges = S.CreateEdges(b, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    if type(icon) == "string" then
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 2, -2)
        tex:SetPoint("BOTTOMRIGHT", -2, 2)
        tex:SetTexture(icon)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.iconTexture = tex
    elseif type(icon) == "function" then
        icon(b)
    end

    local highlight = b:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)

    function b:SetActive(active)
        local A = active and S.ACCENT or S.BORDER
        SetEdgeColor(edges, A[1], A[2], A[3], 0.95)
    end

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local text = type(tip) == "function" and tip() or tip
        local head, rest = text:match("^(.-)\n(.*)$")
        if head then
            GameTooltip:SetText(head, 1, 1, 1)
            GameTooltip:AddLine(rest, 0.75, 0.75, 0.75, true)
        else
            GameTooltip:SetText(text, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b:SetScript("OnClick", onClick)
    return b
end

local function SortGlyph(b)
    local A = NS.Styling.ACCENT
    for index, w in ipairs({ 10, 7, 4 }) do
        local bar = b:CreateTexture(nil, "ARTWORK")
        bar:SetTexture(WHITE)
        bar:SetVertexColor(A[1], A[2], A[3])
        bar:SetSize(w, 2)
        bar:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4 - (index - 1) * 4)
    end
end

local function LayoutGlyph(b)
    local A = NS.Styling.ACCENT
    local grid, bars = {}, {}
    for index = 1, 4 do
        local cell = b:CreateTexture(nil, "ARTWORK")
        cell:SetTexture(WHITE)
        cell:SetVertexColor(A[1], A[2], A[3])
        cell:SetSize(4, 4)
        cell:SetPoint("TOPLEFT", b, "TOPLEFT", 4 + ((index - 1) % 2) * 6, -4 - math.floor((index - 1) / 2) * 6)
        grid[index] = cell
    end
    for index = 1, 2 do
        local head = b:CreateTexture(nil, "ARTWORK")
        head:SetTexture(WHITE)
        head:SetVertexColor(A[1], A[2], A[3])
        head:SetSize(10, 1)
        head:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4 - (index - 1) * 5)
        local body = b:CreateTexture(nil, "ARTWORK")
        body:SetTexture(WHITE)
        body:SetVertexColor(A[1], A[2], A[3], 0.6)
        body:SetSize(index == 1 and 10 or 6, 2)
        body:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -1)
        bars[#bars + 1] = head
        bars[#bars + 1] = body
    end
    function b:Refresh(layout)
        for _, t in ipairs(grid) do if layout == "categories" then t:Hide() else t:Show() end end
        for _, t in ipairs(bars) do if layout == "categories" then t:Show() else t:Hide() end end
    end
end

local function TextButton(parent, text, onClick)
    local S = NS.Styling
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(18)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    bg:SetVertexColor(S.Tint(0.06, 0.06, 0.09, 0.9))

    local edges = S.CreateEdges(b, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local label = b:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(label, "bags", NS.FS(10), "")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    b.label = label
    b:SetWidth(label:GetStringWidth() + 14)

    local highlight = b:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(WHITE)
    highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)

    function b:SetActive(active)
        local A = active and S.ACCENT or S.BORDER
        SetEdgeColor(edges, A[1], A[2], A[3], 0.95)
        if active then
            label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        else
            label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end

    function b:SetLabel(value)
        label:SetText(value)
        b:SetWidth(label:GetStringWidth() + 14)
    end

    b:SetScript("OnClick", onClick)
    return b
end

local function BagInventorySlot(bag)
    if bag >= 1 and bag <= 4 then return ContainerIDToInventoryID(bag) end
    if bag >= 5 and bag <= 11 then return BankButtonIDToInvSlotID(bag - 4, 1) end
end

local function BagSlotButton(f, index)
    local b = f.slotButtons[index]
    if b then return b end

    b = CreateFrame("Button", nil, f.strip)
    b:SetSize(STRIP_H - 2, STRIP_H - 2)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    Skin(b)

    b:SetScript("OnEnter", function(self)
        f.focusBag = self.bag
        Bags:Dim(f)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if self.purchase then
            GameTooltip:SetText(L["Купить ячейку для сумки"], 1, 1, 1)
            GameTooltip:AddLine(GetMoneyString(GetBankSlotCost(GetNumBankSlots())), 1, 1, 1)
        elseif self.bag == 0 then
            GameTooltip:SetText(_G.BACKPACK_TOOLTIP or L["Рюкзак"], 1, 1, 1)
        elseif self.inv and not GameTooltip:SetInventoryItem("player", self.inv) then
            GameTooltip:SetText(_G.EQUIP_CONTAINER or L["Пустая ячейка для сумки"], 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        f.focusBag = nil
        Bags:Dim(f)
        GameTooltip:Hide()
    end)
    b:SetScript("OnClick", function(self)
        if self.purchase then
            if BankFrame then BankFrame.nextSlotCost = GetBankSlotCost(GetNumBankSlots()) end
            StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
            return
        end
        if self.locked then return end
        if self.bag == 0 then
            if CursorHasItem() then PutItemInBackpack() end
            return
        end
        if not self.inv then return end
        if CursorHasItem() then
            PutItemInBag(self.inv)
        else
            PickupBagFromSlot(self.inv)
        end
    end)
    b:SetScript("OnDragStart", function(self)
        if self.inv and not self.locked then PickupBagFromSlot(self.inv) end
    end)
    b:SetScript("OnReceiveDrag", function(self)
        if self.bag == 0 then
            PutItemInBackpack()
        elseif self.inv and not self.locked then
            PutItemInBag(self.inv)
        end
    end)

    f.slotButtons[index] = b
    return b
end

function Bags:UpdateStrip(f)
    local db = Settings()
    local show = db.showBagSlots and not f.view and not (f.kind == "bank" and f.tab == "reagent")
    if not show then
        f.strip:Hide()
        return
    end
    f.strip:Show()

    local ids
    if f.kind == "bank" then
        ids = { 5, 6, 7, 8, 9, 10, 11 }
    else
        ids = { 0, 1, 2, 3, 4 }
    end

    local owned = f.kind == "bank" and GetNumBankSlots and GetNumBankSlots() or 0
    local purchaseShown
    local S = NS.Styling

    for index, bag in ipairs(ids) do
        local b = BagSlotButton(f, index)
        b.bag = bag
        b.inv = BagInventorySlot(bag)
        b.purchase = nil
        b.locked = nil

        local texture
        if bag == 0 then
            texture = BACKPACK
        elseif b.inv then
            texture = GetInventoryItemTexture("player", b.inv)
        end

        local e = { texture = texture, count = 0 }
        if f.kind == "bank" and (bag - 4) > owned then
            b.locked = true
            if not purchaseShown then
                b.purchase = true
                purchaseShown = true
            end
        end
        Paint(b, e, db)
        if b.locked then
            SetEdgeColor(b.narciEdges, b.purchase and S.GOLD[1] or 0.6, b.purchase and S.GOLD[2] or 0.15, b.purchase and S.GOLD[3] or 0.15, 0.9)
            b.narciFree:SetText(b.purchase and "+" or "")
            b.narciFree:Show()
        end
        if bag ~= 0 and b.inv then
            local slots = GetContainerNumSlots(bag) or 0
            if slots > 0 then
                b.narciCount:SetText(slots)
                b.narciCount:Show()
            end
        end

        b:ClearAllPoints()
        b:SetPoint("LEFT", f.strip, "LEFT", (index - 1) * STRIP_H, 0)
        b:Show()
    end
    for index = #ids + 1, #f.slotButtons do f.slotButtons[index]:Hide() end
end

local function SavePosition(f)
    local db = Settings()
    local scale = f:GetScale()
    if f.kind == "bank" then
        local left = f:GetLeft() * scale
        local top = f:GetTop() * scale - UIParent:GetHeight()
        db.bankPos = { "TOPLEFT", left, top }
    else
        local right = f:GetRight() * scale - UIParent:GetWidth()
        local bottom = f:GetBottom() * scale
        db.bagPos = { "BOTTOMRIGHT", right, bottom }
    end
end

local function RestorePosition(f)
    local db = Settings()
    local scale = (db.scale or 100) / 100
    local pos = f.kind == "bank" and db.bankPos or db.bagPos
    f:ClearAllPoints()
    if type(pos) == "table" and pos[1] then
        f:SetPoint(pos[1], UIParent, pos[1], (pos[2] or 0) / scale, (pos[3] or 0) / scale)
    elseif f.kind == "bank" then
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40 / scale, -110 / scale)
    else
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40 / scale, 120 / scale)
    end
end

function Bags:View(f, owner, set)
    if owner then
        f.view = { owner = owner, set = set or "bags" }
    else
        f.view = nil
    end
    f.focusBag = nil
    self:Layout(f)
end

function Bags:CharacterMenu(f, anchor)
    local store = Store()
    if not store then return end
    if not self.menuFrame then
        self.menuFrame = CreateFrame("Frame", "NarciSirus_BagsMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local me = UnitName("player")
    local names = {}
    for name in pairs(store) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        if a == me then return true end
        if b == me then return false end
        return a < b
    end)

    local menu = {}
    menu[#menu + 1] = { text = L["Мои сумки сейчас"], notCheckable = true, func = function() Bags:View(f, nil) end }

    for _, name in ipairs(names) do
        local data = store[name]
        local color = data.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class]
        local label = name
        if color then label = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name) end
        menu[#menu + 1] = { text = label, isTitle = true, notCheckable = true }
        for _, set in ipairs({ "bags", "bank", "reagent" }) do
            if type(data[set]) == "table" then
                menu[#menu + 1] = {
                    text = "   " .. L[SET_NAMES[set]],
                    notCheckable = true,
                    func = function() Bags:View(f, name, set) end,
                }
            end
        end
        if name ~= me then
            menu[#menu + 1] = {
                text = "   |cffff6060" .. L["Забыть персонажа"] .. "|r",
                notCheckable = true,
                func = function() Bags:ForgetCharacter(name) end,
            }
        end
    end

    EasyMenu(menu, self.menuFrame, anchor or "cursor", 0, 0, "MENU")
end

local SAMPLE_ITEMS = {
    { texture = "Interface\\Icons\\INV_Sword_92", link = "sample", quality = 4, ilvl = 264, classID = 2, equipLoc = "INVTYPE_WEAPON" },
    { texture = "Interface\\Icons\\INV_Chest_Plate_26", link = "sample", quality = 3, ilvl = 245, classID = 4, equipLoc = "INVTYPE_CHEST" },
    { texture = "Interface\\Icons\\INV_Misc_Gem_Diamond_06", link = "sample", quality = 2, count = 3 },
    { texture = "Interface\\Icons\\INV_Alchemy_Elixir_04", link = "sample", quality = 1, count = 20 },
    { texture = "Interface\\Icons\\INV_Misc_Note_06", link = "sample", quality = 1, questItem = true, questStart = true },
    { texture = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", link = "sample", quality = 0, price = 10 },
    { },
    { },
}

function Bags:CreateSample(parent)
    local S = NS.Styling
    local f = CreateFrame("Frame", nil, parent)
    f.narciNoRound = true
    f.shadow = S.CreateShadow(f, 5, 0.4)
    f.topLine = S.CreateGradientTopBorder(f)
    local bottomLine = f:CreateTexture(nil, "OVERLAY")
    bottomLine:SetHeight(1)
    bottomLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)
    bottomLine:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    bottomLine:SetTexture(WHITE)
    bottomLine:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.3)
    f.bottomLine = bottomLine
    f.art = f:CreateTexture(nil, "BACKGROUND")
    f.art:Hide()
    local title = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(title, "bags", NS.FS(13), "")
    title:SetText(L["Сумки"])
    f.title = title
    f.close = NS.Widgets.CreateCloseButton(f, 18, function() end)
    f.searchBox = NS.Widgets.CreateThemedEditBox(f, 100, 20, 20)
    f.searchBox:EnableMouse(false)
    f.freeText = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(f.freeText, "bags", NS.FS(11), "")
    f.freeText:SetText("12/80")
    f.moneyText = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(f.moneyText, "bags", NS.FS(11), "")
    f.moneyText:SetText(GetCoinTextureString and GetCoinTextureString(12345678) or "1234g")
    f.cells = {}
    for index = 1, #SAMPLE_ITEMS do
        local cell = CreateFrame("Button", nil, f)
        cell:SetSize(34, 34)
        Skin(cell)
        f.cells[index] = cell
    end
    return f
end

function Bags:PaintSample(f)
    local db = Settings()
    if not db or not f then return end
    self:ApplyWindowStyle(f)
    local pad = f.pad or PAD
    local size, spacing = db.size or 34, db.spacing or 3
    local columns = 4
    for index, cell in ipairs(f.cells) do
        cell:SetSize(size, size)
        cell:ClearAllPoints()
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        cell:SetPoint("TOPLEFT", f, "TOPLEFT", pad + column * (size + spacing), -(HEADER + 28 + row * (size + spacing)))
        Paint(cell, SAMPLE_ITEMS[index], db)
        cell:Show()
    end
    local width = math.max(220, pad * 2 + columns * (size + spacing) - spacing)
    f:SetSize(width, HEADER + 28 + 2 * (size + spacing) + pad + 20)
    f:SetScale(math.min(1, 300 / width, 200 / f:GetHeight()))
end

function Bags:CreateWindow(kind)
    local S = NS.Styling
    local W = NS.Widgets

    local f = CreateFrame("Frame", kind == "bank" and "NarciSirus_BankWindow" or "NarciSirus_BagWindow", UIParent)
    f.kind = kind
    f.buttons = {}
    f.holders = {}
    f.ghosts = {}
    f.titles = {}
    f.slotButtons = {}
    f.used = {}
    f.liveButtons = {}
    f.tab = kind == "bank" and "bank" or nil
    f:Hide()
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
        RestorePosition(self)
    end)
    f:SetSize(MIN_WIDTH, 200)
    f.narciNoRound = true
    f.shadow = S.CreateShadow(f, 5, 0.4)
    f.topLine = S.CreateGradientTopBorder(f)
    local bottomLine = f:CreateTexture(nil, "OVERLAY")
    bottomLine:SetHeight(1)
    bottomLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)
    bottomLine:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    bottomLine:SetTexture(WHITE)
    bottomLine:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.3)
    f.bottomLine = bottomLine
    f.art = f:CreateTexture(nil, "BACKGROUND")
    f.art:Hide()

    local title = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(title, "bags", NS.FS(13), "")
    title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -9)
    f.title = title

    local close = W.CreateCloseButton(f, 18, function() f:Hide() end)
    f.close = close
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD + 2, -6)

    local last = close
    local function AddRight(button, live)
        button:SetPoint("RIGHT", last, "LEFT", -4, 0)
        last = button
        if live then f.liveButtons[#f.liveButtons + 1] = button end
        return button
    end

    f.layoutButton = AddRight(HeaderButton(f, LayoutGlyph, function()
        return Settings().layout == "categories" and L["Вид: разделы. Нажмите, чтобы показать общей сеткой"] or L["Вид: общая сетка. Нажмите, чтобы разложить по разделам"]
    end, function()
        local db = Settings()
        db.layout = db.layout == "categories" and "grid" or "categories"
        Bags:Refresh()
    end))

    local sort = AddRight(HeaderButton(f, SortGlyph, function()
        if kind == "bank" and f.tab == "reagent" then return L["Сортировать банк реагентов"] end
        return L["Сортировать"]
    end, function()
        if kind == "bank" and f.tab == "reagent" then
            if SortReagentBankBags then SortReagentBankBags() end
        else
            Bags:Sort(kind == "bank" and "bank" or "bags")
        end
    end), true)

    f.slotsButton = AddRight(HeaderButton(f, ICON_BAGS, L["Ячейки сумок"], function()
        local db = Settings()
        db.showBagSlots = not db.showBagSlots
        Bags:Refresh()
    end), true)

    if kind == "bags" then
        f.deconstructButton = AddRight(HeaderButton(f, ICON_DECONSTRUCT, function()
            return L["Распыление"] .. "\n" .. L["Подсвечивает предметы, которые можно распылить, растолочь, просеять или вскрыть. Наведите на предмет и щёлкните, чтобы применить."]
        end, function()
            Bags:SetDeconstruct(not Bags.deconstruct)
        end))

        f.keyButton = AddRight(HeaderButton(f, ICON_KEYS, L["Связка ключей"], function()
            local db = Settings()
            db.showKeyring = not db.showKeyring
            Bags:Refresh()
        end), true)

        AddRight(HeaderButton(f, ICON_JUNK, L["Продать хлам"], function()
            Bags:SellJunk(true)
        end), true)

        local chars = TextButton(f, L["Персонажи"], function(self)
            Bags:CharacterMenu(f, self)
        end)
        AddRight(chars)
    else
        f.depositButton = TextButton(f, L["Сложить реагенты"], function()
            if DepositReagentBank then DepositReagentBank() end
        end)
        AddRight(f.depositButton)
    end

    local back = TextButton(f, L["Назад"], function() Bags:View(f, nil) end)
    back:SetPoint("LEFT", title, "RIGHT", 8, 0)
    back:Hide()
    f.backButton = back

    if kind == "bank" then
        f.tabs = {}
        local bankTab = TextButton(f, L["Банк"], function()
            f.tab = "bank"
            Bags:Layout(f)
        end)
        local reagentTab = TextButton(f, L["Реагенты"], function()
            f.tab = "reagent"
            Bags:Layout(f)
        end)
        bankTab:SetPoint("LEFT", title, "RIGHT", 10, 0)
        reagentTab:SetPoint("LEFT", bankTab, "RIGHT", 4, 0)
        f.tabs.bank = bankTab
        f.tabs.reagent = reagentTab
    end

    local search = W.CreateThemedEditBox(f, MIN_WIDTH - PAD * 2, SEARCH_H, 40)
    search:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -HEADER)
    search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -HEADER)
    local hint = search:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(hint, "bags", NS.FS(10), "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("LEFT", search, "LEFT", 8, 0)
    hint:SetText(L["Поиск по названию или типу"])
    search:HookScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        if text == "" then hint:Show() else hint:Hide() end
        f.search = NS.Lower(text)
        Bags:Dim(f)
    end)
    search:HookScript("OnEditFocusGained", function() hint:Hide() end)
    search:HookScript("OnEditFocusLost", function(self)
        if (self:GetText() or "") == "" then hint:Show() end
    end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.searchBox = search

    local strip = CreateFrame("Frame", nil, f)
    strip:SetHeight(STRIP_H)
    strip:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -4)
    strip:SetPoint("TOPRIGHT", search, "BOTTOMRIGHT", 0, -4)
    strip:Hide()
    f.strip = strip

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(HEADER + SEARCH_H + 8))
    content:SetSize(1, 1)
    f.content = content

    if kind == "bank" then
        local notice = CreateFrame("Frame", nil, content)
        notice:SetAllPoints(content)
        local text = notice:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(text, "bags", NS.FS(11), "")
        text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        text:SetPoint("TOP", notice, "TOP", 0, -6)
        text:SetText(L["Банк реагентов ещё не куплен."])
        local buy = TextButton(notice, L["Купить"], function()
            StaticPopup_Show("CONFIRM_BUY_REAGENTBANK_TAB")
        end)
        buy:SetPoint("TOP", text, "BOTTOM", 0, -10)
        notice:SetScript("OnShow", function()
            local cost = GetReagentBankCost and GetReagentBankCost()
            buy:SetLabel(L["Купить"] .. (cost and ("  " .. GetMoneyString(cost)) or ""))
        end)
        notice:Hide()
        f.lockNotice = notice
    end

    local footerY = PAD - 2
    local freeText = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(freeText, "bags", NS.FS(10), "")
    freeText:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    freeText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD + 2, footerY + 4)
    f.freeText = freeText

    local moneyText = f:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(moneyText, "bags", NS.FS(11), "")
    moneyText:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    moneyText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD - 2, footerY + 4)
    f.moneyText = moneyText

    f:SetScript("OnShow", function(self)
        RestorePosition(self)
        Bags:Layout(self)
        PlaySound(kind == "bank" and "igMainMenuOpen" or "igBackPackOpen")
    end)
    f:SetScript("OnHide", function(self)
        PlaySound(kind == "bank" and "igMainMenuClose" or "igBackPackClose")
        self.searchBox:ClearFocus()
        self.focusBag = nil
        if kind == "bags" and Bags.deconstruct then Bags:SetDeconstruct(false) end
        if self.view then self.view = nil end
        if kind == "bank" then
            if Bags.bankOpen and CloseBankFrame then CloseBankFrame() end
        else
            if Bags:AnyBagOpen() then CloseAllBags() end
        end
    end)

    tinsert(UISpecialFrames, f:GetName())
    self:ApplyWindowStyle(f)

    if kind == "bank" then
        self.bankWindow = f
    else
        self.bagWindow = f
    end
    return f
end

local containerFrames = {}

function Bags:AnyBagOpen()
    for index = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = containerFrames[index]
        if not frame then
            frame = _G["ContainerFrame" .. index]
            containerFrames[index] = frame
        end
        if frame and frame:IsShown() then
            local id = frame:GetID()
            if (id >= 0 and id <= 4) or id == KEYRING then return true end
        end
    end
    return false
end

local watcher = CreateFrame("Frame")
watcher:Hide()
local lastState

local function BagState()
    if not Bags:AnyBagOpen() then return 0 end
    if IsBagOpen and IsBagOpen(KEYRING) then return 2 end
    return 1
end

watcher:SetScript("OnUpdate", function()
    local state = BagState()
    if state ~= lastState then
        lastState = state
        Bags:Sync()
    end
end)

function Bags:Sync()
    if not self.running then return end
    local open = self:AnyBagOpen()
    local f = self.bagWindow
    if open then
        f = f or self:CreateWindow("bags")
        if f:IsShown() then
            Queue(f)
        else
            f:Show()
        end
    elseif f and f:IsShown() and not f.view then
        f:Hide()
    end
end

function Bags:OpenBank()
    self.bankOpen = true
    local f = self.bankWindow or self:CreateWindow("bank")
    f.tab = "bank"
    f.view = nil
    if f:IsShown() then
        self:Layout(f)
    else
        f:Show()
    end
    self.bagsOpenedByBank = not self:AnyBagOpen()
    if OpenBackpack then OpenBackpack() end
    for bag = 1, 4 do
        if not IsBagOpen(bag) then OpenBag(bag) end
    end
    self:SaveBank()
end

function Bags:CloseBank()
    self:SaveBank()
    self.bankOpen = false
    if self.bankWindow and self.bankWindow:IsShown() then self.bankWindow:Hide() end
    if self.bagsOpenedByBank then
        self.bagsOpenedByBank = nil
        CloseAllBags()
    end
end

local sorter = CreateFrame("Frame")
sorter:Hide()

local function SlotLocked(slot)
    return select(3, GetContainerItemInfo(slot[1], slot[2])) and true or false
end

local function StopSort(message)
    sorter.ops = nil
    sorter:Hide()
    if message then
        if CursorHasItem() then ClearCursor() end
        NS.Print(message)
    end
    Bags:Refresh()
end

sorter:SetScript("OnUpdate", function(self, elapsed)
    self.wait = self.wait + elapsed
    if InCombatLockdown() then
        StopSort(L["Сортировка прервана: начался бой."])
        return
    end

    local op = self.ops and self.ops[self.index]
    if not op then
        StopSort()
        return
    end

    if self.busy then
        if CursorHasItem() or SlotLocked(self.slots[op.from]) or SlotLocked(self.slots[op.to]) then
            if self.wait > 4 then StopSort(L["Сортировка прервана: сервер не ответил."]) end
            return
        end
        self.busy = nil
        self.index = self.index + 1
        op = self.ops[self.index]
        if not op then
            StopSort()
            return
        end
    end

    if self.wait < 0.04 then return end

    local from, to = self.slots[op.from], self.slots[op.to]
    if GetContainerItemID(from[1], from[2]) ~= op.id then
        StopSort(L["Сортировка прервана: сумки изменились."])
        return
    end

    ClearCursor()
    if op.split then
        SplitContainerItem(from[1], from[2], op.amount)
    else
        PickupContainerItem(from[1], from[2])
    end
    PickupContainerItem(to[1], to[2])
    self.busy = true
    self.wait = 0
end)

function Bags:Sort(kind)
    if sorter.ops then return end
    if InCombatLockdown() then
        NS.Print(L["В бою сортировать нельзя."])
        return
    end
    if kind == "bank" and not self.bankOpen then return end

    local ids = kind == "bank" and BANK_IDS or BAG_IDS
    local slots, state = {}, {}
    for _, bag in ipairs(ids) do
        local size = GetContainerNumSlots(bag) or 0
        local bagType = size > 0 and select(2, GetContainerNumFreeSlots(bag)) or 0
        if size > 0 and (bagType or 0) == 0 then
            for slot = 1, size do
                local e = ReadSlot(bag, slot)
                if e.locked then
                    NS.Print(L["Сначала дождитесь, пока предметы перестанут двигаться."])
                    return
                end
                slots[#slots + 1] = { bag, slot }
                state[#slots] = e.link and e or false
            end
        end
    end

    local ops = {}

    local partial = {}
    for index = 1, #slots do
        local e = state[index]
        if e and e.id and e.maxStack and e.maxStack > 1 and e.count < e.maxStack then
            partial[e.id] = partial[e.id] or {}
            table.insert(partial[e.id], index)
        end
    end
    for id, list in pairs(partial) do
        local lo, hi = 1, #list
        while lo < hi do
            local dst, src = state[list[lo]], state[list[hi]]
            local amount = math.min(dst.maxStack - dst.count, src.count)
            ops[#ops + 1] = { from = list[hi], to = list[lo], amount = amount, split = amount < src.count, id = id }
            dst.count = dst.count + amount
            src.count = src.count - amount
            if src.count <= 0 then
                state[list[hi]] = false
                hi = hi - 1
            end
            if dst.count >= dst.maxStack then lo = lo + 1 end
        end
    end

    local items = {}
    for index = 1, #slots do
        if state[index] then items[#items + 1] = state[index] end
    end
    table.sort(items, Before)

    for index = 1, #items do
        local want = items[index]
        local here = state[index]
        if here ~= want then
            local j
            for k = index + 1, #slots do
                if state[k] == want then j = k break end
            end
            if j then
                local same = here and here.id == want.id and here.count == want.count
                if not same then
                    ops[#ops + 1] = { from = j, to = index, id = want.id }
                end
                state[index], state[j] = state[j], state[index]
            end
        end
    end

    if #ops == 0 then return end
    sorter.ops = ops
    sorter.slots = slots
    sorter.index = 1
    sorter.wait = 0
    sorter.busy = nil
    sorter:Show()
end

local seller = CreateFrame("Frame")
seller:Hide()
seller:SetScript("OnUpdate", function(self, elapsed)
    self.wait = self.wait + elapsed
    if self.wait < 0.2 then return end
    self.wait = 0
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        self:Hide()
        return
    end
    local item = self.queue[self.index]
    if not item then
        self:Hide()
        if self.total > 0 then
            NS.Print(string.format(L["Хлам продан: %s"], GetMoneyString(self.total)))
        end
        return
    end
    self.index = self.index + 1
    local _, count, locked, _, _, _, link = GetContainerItemInfo(item[1], item[2])
    if link and not locked and select(3, GetItemInfo(link)) == 0 then
        UseContainerItem(item[1], item[2])
    end
end)

function Bags:SellJunk(manual)
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        if manual then NS.Print(L["Хлам продаётся у торговца: откройте окно торговца."]) end
        return
    end
    if seller:IsShown() then return end

    local queue, total = {}, 0
    for _, bag in ipairs(BAG_IDS) do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local _, count, locked, _, _, _, link = GetContainerItemInfo(bag, slot)
            if link and not locked then
                local _, _, quality, _, _, _, _, _, _, _, price = GetItemInfo(link)
                if quality == 0 and (price or 0) > 0 then
                    queue[#queue + 1] = { bag, slot }
                    total = total + price * (count or 1)
                end
            end
        end
    end

    if #queue == 0 then
        if manual then NS.Print(L["Хлама в сумках нет."]) end
        return
    end
    seller.queue = queue
    seller.index = 1
    seller.total = total
    seller.wait = 0.2
    seller:Show()
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

local events = CreateFrame("Frame")

local function WindowForBag(bag)
    if bag == nil then return end
    if (bag >= 0 and bag <= 4) or bag == KEYRING then return Bags.bagWindow end
    return Bags.bankWindow
end

function Bags:Start()
    if self.running then return end
    local db = Settings()
    if not db or not db.enabled then return end
    if self:Blocked() then return end
    self.running = true

    for index = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = _G["ContainerFrame" .. index]
        if frame then
            frame:SetParent(hiddenParent)
        end
    end
    if BankFrame then BankFrame:UnregisterAllEvents() end

    for _, event in ipairs({
        "BAG_UPDATE", "BAG_UPDATE_COOLDOWN", "ITEM_LOCK_CHANGED", "PLAYERBANKSLOTS_CHANGED",
        "PLAYERBANKBAGSLOTS_CHANGED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYER_MONEY",
        "MERCHANT_SHOW", "GET_ITEM_INFO_RECEIVED", "EQUIPMENT_SETS_CHANGED", "QUEST_ACCEPTED",
        "UNIT_QUEST_LOG_CHANGED", "CURRENCY_DISPLAY_UPDATE", "PLAYER_EQUIPMENT_CHANGED",
        "SKILL_LINES_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_REGEN_ENABLED",
    }) do
        pcall(events.RegisterEvent, events, event)
    end
    if events.RegisterCustomEvent then
        for _, event in ipairs({ "PLAYERREAGENTBANKSLOTS_CHANGED", "REAGENTBANK_UPDATE", "REAGENTBANK_PURCHASED" }) do
            pcall(events.RegisterCustomEvent, events, event)
        end
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
    RebuildSets()
    self:UpdateSkills()
    self:SaveBags()
    watcher:Show()
end

events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "PLAYER_LOGIN" then
        if NS.After then
            NS.After(0.5, function()
                local db = Settings()
                if db and db.enabled and Bags:Blocked() then
                    NS.Print(L["Сумки аддона ждут: сейчас сумки рисует другой аддон. Переключиться можно в настройках, страница Сумки."])
                end
                Bags:Start()
            end)
        end
        return
    end

    if not Bags.running then return end

    if event == "BAG_UPDATE" then
        if Bags.deconstruct then HideOverlay() end
        Queue(WindowForBag(arg1))
        QueueSave()
    elseif event == "ITEM_LOCK_CHANGED" then
        if arg2 then
            Queue(WindowForBag(arg1))
        else
            Queue(Bags.bankWindow)
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        Bags:Refresh()
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED"
        or event == "PLAYERREAGENTBANKSLOTS_CHANGED" or event == "REAGENTBANK_UPDATE"
        or event == "REAGENTBANK_PURCHASED" then
        Queue(Bags.bankWindow)
        QueueSave()
    elseif event == "BANKFRAME_OPENED" then
        Bags:OpenBank()
    elseif event == "BANKFRAME_CLOSED" then
        Bags:CloseBank()
    elseif event == "PLAYER_MONEY" then
        if Bags.bagWindow and Bags.bagWindow:IsShown() then Bags:UpdateFooter(Bags.bagWindow) end
        QueueSave()
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        if Bags.readingCurrencies then return end
        Queue(Bags.bagWindow)
        QueueSave()
    elseif event == "MERCHANT_SHOW" then
        local db = Settings()
        if db and db.autoSellJunk and NS.After then
            NS.After(0.3, function() Bags:SellJunk(false) end)
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        for _, f in ipairs({ Bags.bagWindow, Bags.bankWindow }) do
            if f and f.pending then Queue(f) end
        end
    elseif event == "EQUIPMENT_SETS_CHANGED" then
        RebuildSets()
        Bags:Refresh()
    elseif event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        Bags:UpdateSkills()
        Bags:Refresh()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if overlay and overlay.pendingHide then
            overlay.pendingHide = nil
            HideOverlay()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        QueueSave()
    else
        Bags:Refresh()
    end
end)
