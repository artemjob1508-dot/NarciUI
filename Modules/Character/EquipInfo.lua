local addonName, NS = ...

local EquipInfo = {}

local format = string.format
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local tsort = table.sort
local strsplit = strsplit
local strmatch = strmatch
local gmatch = string.gmatch
local tonumber = tonumber
local GetInventoryItemLink = GetInventoryItemLink
local GetInventorySlotInfo = GetInventorySlotInfo
local GetItemInfo = GetItemInfo

local SLOT_NAMES = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
    "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
    "MainHandSlot", "SecondaryHandSlot", "RangedSlot",
}

local NO_ENCHANT = {
    NeckSlot=true, WaistSlot=true, Finger0Slot=true, Finger1Slot=true,
    Trinket0Slot=true, Trinket1Slot=true, RangedSlot=true, SecondaryHandSlot=true,
}

local function L(key)
    if not key or key == "" then return key or "" end
    return NS.L[key]
end

local GetNumSockets
do
    local ttName = "NS_EQ_Scan" .. random(100000, 9999999)
    local tt = CreateFrame("GameTooltip", ttName, UIParent, "GameTooltipTemplate")
    tt:SetOwner(UIParent, "ANCHOR_NONE")
    local tex = {}
    for i = 1, 10 do tex[i] = _G[ttName .. "Texture" .. i] end
    local cache = setmetatable({}, {__index = function(t, link)
        tt:SetOwner(UIParent, "ANCHOR_NONE")
        tt:ClearLines()
        tt:SetHyperlink(link)
        local n = 0
        for i = 1, 10 do if tex[i]:IsShown() then n = n + 1 end end
        if tt:NumLines() > 0 then t[link] = n end
        return n
    end})
    function GetNumSockets(link) return link and cache[link] or 0 end
end

local srctypes_d = { ["n"]="Обычка", ["h"]="Героик", ["q"]="Награда за задание" }
local srctypes_r = { ["N"]="Героик", ["H"]="Героик", ["q"]="Награда за задание", ["Q"]="Награда за задание" }
local pvptypes = {
    ["m"]="Ассоциации", ["l"]="Низкоуровневое PvP", ["w"]="Мировое PvP",
    ["s1"]=" Сезон 1", ["s2"]=" Сезон 2", ["s3"]=" Сезон 3", ["s4"]=" Сезон 4",
    ["s5"]=" Сезон 5", ["s6"]=" Сезон 6", ["s7"]=" Сезон 7", ["s8"]=" Сезон 8",
    ["s9"]=" Сезон 9", ["s10"]=" Сезон 10", ["s11"]=" Сезон 11",
    ["g"]="Озеро Ледяных Оков",
}

local function FindItemSource(itemLink)
    local IS = InspectEquip_ItemSources
    if not IS or not IS.Items then return nil end
    local id = tonumber(itemLink:match("item:(%d+)"))
    if not id then return nil end
    local data = IS.Items[id]
    if not data then return nil end
    local sources = {}
    for entry in gmatch(data, "[^;]+") do
        local next_field = gmatch(entry, "[^_]+")
        local cat = next_field()
        if cat == "r" or cat == "d" then
            local catname = cat == "r" and "Рейды" or "Подземелья"
            local zoneId = tonumber(next_field() or 0)
            local zone = IS.Zones and IS.Zones[zoneId] or ("Зона#"..zoneId)
            local lootTable = next_field()
            local srctype
            if cat == "r" then
                srctype = srctypes_r[lootTable]
                if lootTable == "n" or lootTable == "N" or lootTable == "q" then
                    zone = zone .. "-10"
                elseif lootTable == "h" or lootTable == "H" or lootTable == "Q" then
                    zone = zone .. "-25"
                elseif lootTable == "4" then
                    zone = zone .. "-40"
                end
            else
                srctype = srctypes_d[lootTable]
            end
            local boss = IS.Bosses and IS.Bosses[tonumber(next_field() or 0)] or nil
            local setname = next_field()
            if setname == "+" then setname = "Сложный уровень" end
            tinsert(sources, {catname, zone, srctype, boss, nil, setname})
        elseif cat == "v" then
            tinsert(sources, {"PvE награды", "Очки доблести", nil, nil, tonumber(next_field())})
        elseif cat == "z" then
            tinsert(sources, {"PvE награды", "Жетон Запределья", nil, nil, tonumber(next_field())})
        elseif cat == "c" then
            tinsert(sources, {"Ремесло"})
        elseif cat == "f" then
            tinsert(sources, {"За репутацию"})
        elseif cat == "e" then
            tinsert(sources, {"Мировые события"})
        elseif cat == "m" then
            tinsert(sources, {"Ярмарка Новолуния"})
        elseif cat == "g" then
            tinsert(sources, {"Продавец"})
        elseif cat == "l" then
            tinsert(sources, {"Лили"})
        elseif cat == "tol" then
            tinsert(sources, {"Тол'Гарод"})
        elseif cat == "kel" then
            tinsert(sources, {"Остров Кель'Данас"})
        elseif cat == "auс" then
            tinsert(sources, {"Аукцион"})
        elseif cat == "b" then
            tinsert(sources, {"Героические БК подземелья"})
        elseif cat == "p" then
            local pvptype = pvptypes[next_field()]
            tinsert(sources, {"PvP награды", pvptype})
        elseif cat == "t" then
            tinsert(sources, {"Серебряный турнир", nil, nil, nil, tonumber(next_field())})
        end
    end
    if #sources > 0 then return sources[1] end
    return nil
end

local function ScanEquipment()
    local groups = {}
    local totalItems = 0
    local iLevelSum, iCount = 0, 0

    for _, slotName in ipairs(SLOT_NAMES) do
        local slotId = GetInventorySlotInfo(slotName)
        if slotId then
            local link = GetInventoryItemLink("player", slotId)
            if link then
                local source = FindItemSource(link)
                local groupName

                if source then
                    local cat, subcat, lootTable = source[1], source[2], source[3]
                    groupName = L(cat)
                    if subcat then
                        groupName = L(subcat)
                        if lootTable and lootTable == "Героик" then
                            groupName = groupName .. " (" .. L("Героик") .. ")"
                        end
                    end
                else
                    groupName = L("Неизвестно")
                end

                if not groups[groupName] then
                    groups[groupName] = { count = 0, items = {} }
                end
                local g = groups[groupName]
                g.count = g.count + 1

                local enchantId = tonumber(link:match("Hitem:%d+:(%d+):")) or 0
                local numSockets = GetNumSockets(link)
                local _, _, _, gem1, gem2, gem3, gem4 = strsplit(":", strmatch(link, "|H(.-)|h") or "")
                local ilvl = select(4, GetItemInfo(link))

                g.items[g.count] = {
                    link = link, slot = slotName, enchant = enchantId,
                    gem1 = tonumber(gem1) or 0, gem2 = tonumber(gem2) or 0,
                    gem3 = tonumber(gem3) or 0, gem4 = tonumber(gem4) or 0,
                    numSockets = numSockets, ilvl = ilvl,
                }

                totalItems = totalItems + 1
                if ilvl then iLevelSum = iLevelSum + ilvl; iCount = iCount + 1 end
            end
        end
    end

    return groups, totalItems, iCount > 0 and (iLevelSum / iCount) or 0
end

local function BuildLines()
    local groups, totalItems, avgLevel = ScanEquipment()
    local sorted = {}
    for name, data in pairs(groups) do
        tinsert(sorted, { name = name, count = data.count, items = data.items })
    end
    tsort(sorted, function(a, b) return a.count > b.count end)

    local lines = {}
    for _, group in ipairs(sorted) do
        tinsert(lines, {
            text = group.name .. " |cff808080(" .. group.count .. ")|r",
            isHeader = true,
        })
        for _, item in ipairs(group.items) do
            local prefix = item.ilvl and ("|cffaaaaaa[" .. item.ilvl .. "]|r ") or ""
            local suffix = ""
            if item.enchant > 0 and not NO_ENCHANT[item.slot] then
                suffix = " - |cff00ff00" .. L("Есть чарка") .. "|r"
            elseif item.enchant == 0 and not NO_ENCHANT[item.slot] then
                suffix = " - |cffff0000" .. L("Нет чарки") .. "|r"
            end
            if item.numSockets > 0 then
                local hasEmpty = false
                for s = 1, item.numSockets do
                    if item["gem" .. s] == 0 then hasEmpty = true; break end
                end
                if hasEmpty then suffix = suffix .. " |cffff0000" .. L("Есть гнёзда") .. "|r" end
            end
            tinsert(lines, { text = prefix .. item.link .. suffix, link = item.link })
        end
    end
    tinsert(lines, {
        text = L("Сред. значение уровня вещей: ") .. format("%.2f", avgLevel),
        isFooter = true,
    })
    return lines
end

function EquipInfo:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_EquipInfo", parent)
    f:SetWidth(S.PANEL_WIDTH)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y - S.PANEL_HEIGHT - S.PANEL_GAP)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetFrameLevel(parent:GetFrameLevel() + 3)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText(L("Снаряжение"))
    if NS.TabStyle then NS.TabStyle.Header(f, { art = "BannerGear", module = EquipInfo, method = "Update", badge = function()
        return math.floor(NS.GetAverageItemLevel()), L("УР.ПРЕДМ.")
    end }) end

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 6, (NS.TabStyle and NS.TabStyle.Styled()) and -56 or -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 6)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(400)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)

    self.frame = f
    self.scrollChild = scrollChild
    self.linePool = {}
    self.usedLines = 0
end

function EquipInfo:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local sc = self.scrollChild

    for i = 1, self.usedLines do
        if self.linePool[i] then self.linePool[i]:Hide() end
    end
    self.usedLines = 0

    local lines = BuildLines()
    local yOffset = 0

    for _, ld in ipairs(lines) do
        self.usedLines = self.usedLines + 1
        local line = self.linePool[self.usedLines]
        if not line then
            line = CreateFrame("Frame", nil, sc)
            line:SetWidth(400)
            local txt = line:CreateFontString(nil, "ARTWORK")
            txt:SetFont(NS.FONT, NS.FS(10), "")
            txt:SetJustifyH("LEFT")
            txt:SetPoint("TOPLEFT", line, "TOPLEFT", 4, 0)
            txt:SetPoint("TOPRIGHT", line, "TOPRIGHT", -4, 0)
            line.text = txt

            local divider = line:CreateTexture(nil, "ARTWORK")
            divider:SetHeight(1)
            divider:SetPoint("TOPLEFT", line, "TOPLEFT", 4, 2)
            divider:SetPoint("TOPRIGHT", line, "TOPRIGHT", -4, 2)
            divider:SetTexture("Interface\\Buttons\\WHITE8x8")
            divider:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.4)
            divider:Hide()
            line.divider = divider
            line:EnableMouse(true)
            line:SetScript("OnEnter", function(s)
                if s.link then
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(s.link)
                    GameTooltip:Show()
                end
            end)
            line:SetScript("OnLeave", function() GameTooltip:Hide() end)
            line:SetScript("OnMouseDown", function(s)
                if s.link then
                    if IsControlKeyDown() then DressUpItemLink(s.link)
                    elseif IsShiftKeyDown() then ChatEdit_InsertLink(s.link) end
                end
            end)
            self.linePool[self.usedLines] = line
        end

        line.link = ld.link
        line.text:SetText(ld.text)

        if ld.isHeader then
            line.text:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
            line.text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            line:SetHeight(16)
            if self.usedLines > 1 then line.divider:Show() else line.divider:Hide() end
            yOffset = yOffset + 2
        elseif ld.isFooter then
            line.text:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
            line.text:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
            line:SetHeight(16)
            line.divider:Hide()
            yOffset = yOffset + 6
        else
            line.text:SetFont(NS.FONT, NS.FS(10), "")
            line.text:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            line:SetHeight(13)
            line.divider:Hide()
        end

        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, -yOffset)
        line:Show()

        if ld.isHeader then yOffset = yOffset + 16
        elseif ld.isFooter then yOffset = yOffset + 18
        else yOffset = yOffset + 14 end
    end

    sc:SetHeight(math.max(yOffset, 1))
end

function EquipInfo:Show()
    if not self.frame then self:Create() end
    self:Update()
    if self.frame then self.frame:Show() end
end

function EquipInfo:Hide()
    if self.frame then self.frame:Hide() end
end

NS.EquipInfo = EquipInfo
