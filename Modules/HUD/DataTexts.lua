local addonName, NS = ...
local L = NS.L

local DataTexts = {}
NS.DataTexts = DataTexts

local WHITE = "Interface\\Buttons\\WHITE8x8"

local SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 }

local panels = {}
local elapsed = 0

local function FillSettings()
    if not NS.db then return end

    if not NS.db.dataTexts then NS.db.dataTexts = {} end

    local db = NS.db.dataTexts
    if db.enabled == nil then db.enabled = false end
    db.width = db.width or 420
    db.height = db.height or 22
    db.point = db.point or "BOTTOM"
    db.x = db.x or 0
    db.y = db.y or 160
    db.fontSize = db.fontSize or 11
    db.valueColor = db.valueColor or "white"
    if db.labels == nil then db.labels = true end
    if db.panel == nil then db.panel = true end
    if db.fullWidth == nil then db.fullWidth = false end
    if db.localTime == nil then db.localTime = false end
    if db.goldOnly == nil then db.goldOnly = false end
    db.blocks = db.blocks or {}
    db.style = db.style or "panel"
    db.labelColor = db.labelColor or "dim"
    if db.dividers == nil then db.dividers = true end
    if db.warn == nil then db.warn = false end
    db.blockPad = db.blockPad or 25
    db.bgAlpha = db.bgAlpha or 100

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.dataTexts
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local function Money()
    local money = GetMoney() or 0
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    if Settings().goldSep and gold >= 1000 then
        local text = tostring(gold)
        repeat
            local before = text
            text = text:gsub("^(%d+)(%d%d%d)", "%1 %2")
        until text == before
        gold = text
    end

    local db = Settings()
    local style = db.moneyStyle or "text"

    if style == "coins" then
        local size = math.max(8, (db.fontSize or 11) - 1)
        local function Icon(name)
            return "|TInterface\\MoneyFrame\\UI-" .. name .. "Icon:" .. size .. ":" .. size .. ":2:0|t"
        end
        if db.goldOnly then return gold .. Icon("Gold") end
        return gold .. Icon("Gold") .. " " .. silver .. Icon("Silver") .. " " .. copper .. Icon("Copper")
    end

    if style == "colored" then
        local text = "|cffffd34a" .. gold .. "|r"
        if db.goldOnly then return text end
        return text .. "  |cffd6d8de" .. silver .. "|r  |cffd88a52" .. copper .. "|r"
    end

    if db.goldOnly then return gold .. L["з"] end

    return gold .. L["з"] .. " " .. silver .. L["с"] .. " " .. copper .. L["м"]
end

local function Durability()
    local worst, sum, count = 100, 0, 0

    for _, slot in ipairs(SLOTS) do
        local current, maximum = GetInventoryItemDurability(slot)

        if current and maximum and maximum > 0 then
            local share = current / maximum * 100
            if share < worst then worst = share end
            sum, count = sum + share, count + 1
        end
    end

    if Settings().durMode == "average" and count > 0 then return math.floor(sum / count) .. "%" end

    return math.floor(worst) .. "%"
end

local function Bags()
    local free, total = 0, 0

    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag) or 0
        total = total + slots
        if slots > 0 then free = free + (GetContainerNumFreeSlots(bag) or 0) end
    end

    local mode = Settings().bagsMode
    if mode == "free" then return tostring(free) end
    if mode == "used" then return (total - free) .. "/" .. total end
    return free .. "/" .. total
end

local function Speed()
    local fps = math.floor(GetFramerate() or 0)
    local _, _, latency = GetNetStats()

    local mode = Settings().speedMode
    if mode == "fps" then return fps .. " fps" end
    if mode == "ping" then return math.floor(latency or 0) .. " ms" end
    return fps .. " fps  " .. math.floor(latency or 0) .. " ms"
end

local function Coords()
    local x, y = GetPlayerMapPosition("player")

    if not x or x == 0 then return "-" end

    local db = Settings()
    return NS.FormatCoords(x, y, db.coordDigits or 1, db.coordFormat or "xy")
end

local function Friends()
    local counts = NS.SocialCounts and NS.SocialCounts()
    if not counts then return "-" end
    return tostring(counts.friends)
end

local function Guild()
    local counts = NS.SocialCounts and NS.SocialCounts()
    if not counts or not (IsInGuild and IsInGuild()) then return "-" end
    return tostring(counts.guild)
end

local function Clock()
    local db = Settings()
    local hour, minute, second
    if db.localTime then
        hour, minute, second = tonumber(date("%H")), tonumber(date("%M")), tonumber(date("%S"))
    else
        hour, minute = GetGameTime()
    end
    local suffix = ""
    if db.clock12 then
        suffix = hour < 12 and " AM" or " PM"
        hour = hour % 12
        if hour == 0 then hour = 12 end
    end
    if second and db.clockSeconds then
        return string.format("%d:%02d:%02d", hour, minute, second) .. suffix
    end
    return string.format("%d:%02d", hour, minute) .. suffix
end

local BLOCKS = {
    { key = "durability", label = "Прочность", value = Durability },
    { key = "bags",       label = "Сумки",     value = Bags },
    { key = "money",      label = "Золото",    value = Money },
    { key = "speed",      label = "Скорость",  value = Speed },
    { key = "coords",     label = "Координаты", value = Coords },
    { key = "clock",      label = "Время",     value = Clock },
    { key = "friends",    label = "Друзья",    value = Friends },
    { key = "guild",      label = "Гильдия",   value = Guild },
}

DataTexts.BLOCKS = BLOCKS

local CLICKS = {
    durability = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
    bags = function() if ToggleBackpack then ToggleBackpack() end end,
    money = function() if ToggleBackpack then ToggleBackpack() end end,
    coords = function() if WorldMapFrame and ToggleFrame then ToggleFrame(WorldMapFrame) end end,
    clock = function() if ToggleTimeManager then ToggleTimeManager() end end,
    friends = function() NS.OpenFriendsList() end,
    guild = function() NS.OpenGuildList() end,
}

local ALWAYS_CLICK = { friends = true, guild = true, bags = true }

local function MoneyStore()
    if type(NarcissusSirusDB) ~= "table" then return end
    if type(NarcissusSirusDB.inventory) ~= "table" then NarcissusSirusDB.inventory = {} end
    local realm = GetRealmName() or "?"
    if type(NarcissusSirusDB.inventory[realm]) ~= "table" then NarcissusSirusDB.inventory[realm] = {} end
    return NarcissusSirusDB.inventory[realm]
end

local function SaveMoney()
    local store = MoneyStore()
    local name = UnitName("player")
    if not store or not name then return end
    if type(store[name]) ~= "table" then store[name] = {} end
    store[name].money = GetMoney() or 0
    store[name].class = select(2, UnitClass("player"))
end

local function Coins(money)
    if GetCoinTextureString then return GetCoinTextureString(money) end
    return math.floor(money / 10000) .. L["з"] .. " " .. math.floor(money % 10000 / 100) .. L["с"] .. " " .. money % 100 .. L["м"]
end

local function Currencies()
    if NS.Bags and NS.Bags.ListCurrencies then
        local ok, list = pcall(NS.Bags.ListCurrencies, NS.Bags)
        if ok and list then return list end
    end
    local list = {}
    for index = 1, (GetCurrencyListSize and GetCurrencyListSize() or 0) do
        local name, isHeader, _, _, _, count, extra, icon = GetCurrencyListInfo(index)
        if name and not isHeader then list[#list + 1] = { name = name, count = count or 0, icon = icon, extra = extra } end
    end
    return list
end

local function MoneyTooltip(owner)
    local S = NS.Styling
    SaveMoney()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(L["Золото"], S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    local shown = 0
    for _, entry in ipairs(Currencies()) do
        local count = entry.count or 0
        if entry.extra == 1 and GetArenaCurrency then count = GetArenaCurrency() or count end
        if entry.extra == 2 and GetHonorCurrency then count = GetHonorCurrency() or count end
        if count > 0 then
            if shown == 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Валюта"], S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            end
            shown = shown + 1
            local icon = entry.icon and ("|T" .. entry.icon .. ":14:14:0:0|t ") or ""
            GameTooltip:AddDoubleLine(icon .. entry.name, count, 0.9, 0.9, 0.93, 1, 1, 1)
        end
    end

    local store = MoneyStore() or {}
    local me = UnitName("player")
    local list, total = {}, 0
    for name, data in pairs(store) do
        if type(data) == "table" and type(data.money) == "number" then
            list[#list + 1] = { name = name, money = data.money, class = data.class }
            total = total + data.money
        end
    end
    table.sort(list, function(a, b)
        if (a.name == me) ~= (b.name == me) then return a.name == me end
        return a.money > b.money
    end)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Персонажи"], S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    for _, entry in ipairs(list) do
        local c = entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
        local r, g, b = 0.9, 0.9, 0.93
        if c then r, g, b = c.r, c.g, c.b end
        GameTooltip:AddDoubleLine(entry.name, Coins(entry.money), r, g, b, 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["Всего"], Coins(total), S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1, 1, 1)
    if #list <= 1 then
        GameTooltip:AddLine(L["Золото других персонажей появится, когда вы зайдёте на каждого из них хотя бы раз."], 0.6, 0.6, 0.65, true)
    end
    if NS.AddTooltipLines then NS.AddTooltipLines("money", GameTooltip) end
    GameTooltip:Show()
end

local function ClockTooltip(owner)
    local S = NS.Styling
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(L["Время"], S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    local hour, minute = GetGameTime()
    GameTooltip:AddDoubleLine(L["Время сервера"], string.format("%d:%02d", hour, minute), 0.9, 0.9, 0.93, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Местное время"], date("%H:%M"), 0.9, 0.9, 0.93, 1, 1, 1)
    if NS.AddLockouts then pcall(NS.AddLockouts, GameTooltip) end
    if NS.AddTooltipLines then NS.AddTooltipLines("clock", GameTooltip) end
    GameTooltip:Show()
end

local HOVER = { money = MoneyTooltip, clock = ClockTooltip }

local orderedCache, orderedFor, orderedCount

local function OrderedBlocks()
    local order = Settings().order
    if type(order) ~= "table" then return BLOCKS end
    if orderedCache and orderedFor == order and orderedCount == #BLOCKS then return orderedCache end
    local rank = {}
    for index, key in ipairs(order) do rank[key] = index end
    local list = {}
    for index, block in ipairs(BLOCKS) do list[index] = block end
    local base = {}
    for index, block in ipairs(BLOCKS) do base[block.key] = index end
    table.sort(list, function(a, b)
        local ra, rb = rank[a.key] or (100 + base[a.key]), rank[b.key] or (100 + base[b.key])
        return ra < rb
    end)
    orderedCache, orderedFor, orderedCount = list, order, #BLOCKS
    return list
end

function DataTexts:Order()
    local list = {}
    for index, block in ipairs(OrderedBlocks()) do list[index] = block end
    return list
end

function DataTexts:Shift(key, delta)
    local db = Settings()
    if not db then return end
    local keys = {}
    for index, block in ipairs(OrderedBlocks()) do keys[index] = block.key end
    for index, current in ipairs(keys) do
        if current == key then
            local target = index + delta
            if target >= 1 and target <= #keys then
                keys[index], keys[target] = keys[target], keys[index]
            end
            break
        end
    end
    db.order = keys
    self:Relayout()
end

local STYLES = { panel = true, pills = true, pixel = true, fade = true, glass = true, neon = true, dark = true, underline = true }
local PILL_GAP = 4

local function PanelStyle()
    local db = Settings()
    return db and STYLES[db.style] and db.style or "panel"
end

local function BlockShown(key)
    local db = Settings()
    return db.blocks[key] ~= false
end

local function ValueColor()
    local db = Settings()
    local S = NS.Styling

    if db.valueColor == "accent" then
        return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
    end

    if db.valueColor == "class" then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end

    if db.valueColor == "gold" then
        return S.GOLD[1], S.GOLD[2], S.GOLD[3]
    end

    if db.valueColor == "narci" then
        local r, g, b = NS.Look:Value()
        if r then return r, g, b end
    end

    return S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]
end

local function LabelColor()
    local db = Settings()
    local S = NS.Styling
    local mode = db.labelColor or "dim"
    if mode == "accent" then return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3] end
    if mode == "white" then return 1, 1, 1 end
    if mode == "gold" then return S.GOLD[1], S.GOLD[2], S.GOLD[3] end
    if mode == "class" then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end
    return NS.Look:Text("datatexts", S.TEXT_DIM)
end

local function Warning(key, text)
    if not Settings().warn then return end
    local number = tonumber(text:match("^(%d+)"))
    if not number then return end
    if key == "durability" and number < 30 then return 0.95, 0.30, 0.28 end
    if key == "bags" then
        local used, total = text:match("^(%d+)/(%d+)$")
        local free = (Settings().bagsMode == "used" and used) and (tonumber(total) - tonumber(used)) or number
        if free <= 5 then return 0.95, 0.30, 0.28 end
    end
    if key == "speed" then
        local latency = tonumber(text:match("(%d+) ms"))
        if number < 25 or (latency and latency > 250) then return 0.95, 0.75, 0.25 end
    end
end

function DataTexts:AddBlock(block)
    if self.frame or type(block) ~= "table" or type(block.key) ~= "string" or type(block.value) ~= "function" then
        return false
    end
    for _, existing in ipairs(BLOCKS) do
        if existing.key == block.key then return false end
    end
    BLOCKS[#BLOCKS + 1] = { key = block.key, label = block.label or block.key, value = block.value }
    return true
end

local function BuildBody(f, list)
    local db = Settings()
    local S = NS.Styling
    local chrome = {}

    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.90)
    chrome[#chrome + 1] = ground

    f.ground = ground
    f.edges = S.CreateEdges(f, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)
    for _, line in ipairs(f.edges) do
        chrome[#chrome + 1] = line
    end

    local fadeLeft = f:CreateTexture(nil, "BACKGROUND")
    fadeLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    fadeLeft:SetPoint("BOTTOMRIGHT", f, "BOTTOM", 0, 0)
    fadeLeft:SetTexture(WHITE)
    fadeLeft:SetGradientAlpha("HORIZONTAL", 0.016, 0.018, 0.026, 0, 0.016, 0.018, 0.026, 0.9)

    local fadeRight = f:CreateTexture(nil, "BACKGROUND")
    fadeRight:SetPoint("TOPLEFT", f, "TOP", 0, 0)
    fadeRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    fadeRight:SetTexture(WHITE)
    fadeRight:SetGradientAlpha("HORIZONTAL", 0.016, 0.018, 0.026, 0.9, 0.016, 0.018, 0.026, 0)
    f.fade = { fadeLeft, fadeRight }

    local top = f:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.75)
    chrome[#chrome + 1] = top
    f.top = top

    if S.CreateSoftShadow then f.shadow = S.CreateSoftShadow(f, 6, 0.45) end

    f.chrome = chrome

    for _, block in ipairs(BLOCKS) do
        local holder = CreateFrame("Frame", nil, f)
        holder:SetHeight(db.height)

        local tile = holder:CreateTexture(nil, "BACKGROUND")
        tile:SetAllPoints(holder)
        tile:SetTexture(WHITE)
        tile:SetVertexColor(0.016, 0.018, 0.026, 0.90)
        holder.tile = tile
        holder.tileEdges = S.CreateEdges(holder, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.85)

        local divider = holder:CreateTexture(nil, "ARTWORK")
        divider:SetWidth(1)
        divider:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -6)
        divider:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 6)
        divider:SetTexture(WHITE)
        divider:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

        local label = holder:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", holder, "LEFT", 10, 0)
        label:SetTextColor(NS.Look:Text("datatexts", S.TEXT_DIM))

        local value = holder:CreateFontString(nil, "OVERLAY")

        holder:SetScript("OnEnter", function(self)
            local tip = HOVER[block.key]
            if tip then pcall(tip, self) end
        end)
        holder:SetScript("OnLeave", function()
            if HOVER[block.key] then GameTooltip:Hide() end
        end)

        holder:SetScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton" or not (Settings().clicks or ALWAYS_CLICK[block.key]) then return end
            local action = CLICKS[block.key] or block.click
            if type(action) == "function" then pcall(action) end
        end)

        list[block.key] = { holder = holder, label = label, value = value, divider = divider, block = block }
    end

end

function DataTexts:Create()
    if self.frame then return self.frame end

    local db = Settings()
    if not db then return end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarciSirus_DataTexts", UIParent)
    f:SetSize(db.width, db.height)
    f:SetClampedToScreen(true)
    f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    f:SetFrameStrata("LOW")

    BuildBody(f, panels)

    if NS.Movers then
        NS.Movers:Register(f, L["Дататексты"], function(point, _, x, y)
            local store = Settings()
            store.point, store.x, store.y = point, x, y
            store.fullWidth = false
        end, "data")
    end

    self.frame = f
    self:Restyle()

    return f
end

function DataTexts:Restyle(target)
    local list = target and target.panels or panels
    local f = target and target.frame or self.frame
    local db = Settings()
    if not f or not db then return end

    local S = NS.Styling
    local style = PanelStyle()
    local panel = db.panel
    local solid = style == "panel" or style == "pixel" or style == "glass" or style == "neon" or style == "dark"
    local framed = style == "panel" or style == "pixel" or style == "glass" or style == "neon"

    f.ground:SetShown(panel and solid)
    for index, line in ipairs(f.edges) do
        line:SetShown(panel and (framed or (style == "underline" and index == 2)))
    end
    f.top:SetShown(panel and (style == "panel" or style == "glass"))
    if f.shadow then f.shadow:SetShown(panel and (style == "panel" or style == "glass")) end
    for _, texture in ipairs(f.fade) do texture:SetShown(panel and style == "fade") end

    if style == "pixel" then
        f.ground:SetVertexColor(0.07, 0.07, 0.075, 0.95)
        for _, line in ipairs(f.edges) do line:SetVertexColor(0, 0, 0, 1) end
    elseif style == "glass" then
        f.ground:SetVertexColor(0.05, 0.07, 0.11, 0.6)
        for _, line in ipairs(f.edges) do line:SetVertexColor(S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.9) end
    elseif style == "neon" then
        f.ground:SetVertexColor(0, 0, 0, 0.9)
        for _, line in ipairs(f.edges) do line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1) end
    elseif style == "dark" then
        f.ground:SetVertexColor(0, 0, 0, 0.75)
    elseif style == "underline" then
        for _, line in ipairs(f.edges) do line:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9) end
    else
        f.ground:SetVertexColor(0.016, 0.018, 0.026, 0.90)
        for _, line in ipairs(f.edges) do line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8) end
    end
    local dens = (db.bgAlpha or 100) / 100
    if dens < 1 then
        local cr, cg, cb, ca = f.ground:GetVertexColor()
        f.ground:SetVertexColor(cr, cg, cb, ca * dens)
    end
    local gr, gg, gb = NS.Look:Color("datatexts", "bg")
    if gr then
        local _, _, _, ga = f.ground:GetVertexColor()
        f.ground:SetVertexColor(gr, gg, gb, ga)
        dens = 1
    end
    local er, eg, eb = NS.Look:Color("datatexts", "border")
    if er then
        for _, line in ipairs(f.edges) do line:SetVertexColor(er, eg, eb, 1) end
    end

    for _, block in ipairs(BLOCKS) do
        local holder = list[block.key].holder
        local pill = panel and style == "pills"
        list[block.key].position = nil
        holder.tile:SetShown(pill)
        for _, line in ipairs(holder.tileEdges) do line:SetShown(pill) end
    end

    local size = db.fontSize
    local r, g, b = ValueColor()

    for _, block in ipairs(BLOCKS) do
        local entry = list[block.key]

        NS.LSetFont(entry.label, "datatexts", math.max(7, size - 2), db.panel and "" or "OUTLINE")
        entry.label:SetText(db.labels and (L[block.label] .. (db.labelColon and ":" or "")) or "")
        entry.holder:EnableMouse((HOVER[block.key] or (ALWAYS_CLICK[block.key] or db.clicks) and (CLICKS[block.key] or block.click)) and true or false)
        entry.label:SetShown(db.labels)

        NS.LSetFont(entry.value, "datatexts", size, db.panel and "" or "OUTLINE")
        entry.value:SetTextColor(r, g, b)
        entry.label:SetTextColor(LabelColor())
        entry.lastText = nil
        entry.value:ClearAllPoints()

        if db.labels then
            entry.value:SetPoint("LEFT", entry.label, "RIGHT", 5, 0)
        else
            entry.value:SetPoint("LEFT", entry.holder, "LEFT", 10, 0)
        end

        entry.holder:SetHeight(db.height)
    end

    f:SetHeight(db.height)
    if target then
        self:Refresh(target)
        return
    end
    self.fitted = nil
    self:Place()
    self:Fit()
end

function DataTexts:CreateSample(parent)
    local db = Settings()
    if not db then return end
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(db.width or 300, db.height or 22)
    local list = {}
    BuildBody(f, list)
    f.sampleTarget = { frame = f, panels = list }
    return f
end

function DataTexts:PaintSample(f, opts)
    if not f or not f.sampleTarget then return end
    f.sampleTarget.focus = opts and opts.focus
    for _, entry in pairs(f.sampleTarget.panels) do entry.width, entry.position, entry.lastText = nil, nil, nil end
    self:Restyle(f.sampleTarget)
end

function DataTexts:Place()
    local f = self.frame
    local db = Settings()
    if not f or not db then return end

    f:ClearAllPoints()

    if db.fullWidth then
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    else
        f:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    end
end

function DataTexts:Refresh(target)
    local frame = target and target.frame or self.frame
    if not frame or (not target and not frame:IsShown()) then return end

    for _, entry in pairs(target and target.panels or panels) do
        if BlockShown(entry.block.key) then
            local ok, value = pcall(entry.block.value)
            local text = ok and tostring(value) or "-"
            if text ~= entry.lastText then
                entry.lastText = text
                entry.value:SetText(text)
                local wr, wg, wb = Warning(entry.block.key, text)
                if wr then
                    entry.value:SetTextColor(wr, wg, wb)
                    entry.warned = true
                elseif entry.warned then
                    entry.warned = nil
                    entry.value:SetTextColor(ValueColor())
                end
            end
        else
            entry.lastText = nil
        end
    end

    self:Fit(target)
end

function DataTexts:Fit(target)
    local db = Settings()
    local frame = target and target.frame or self.frame
    local list = target and target.panels or panels
    if not frame or not db then return end

    local visible = {}

    for _, block in ipairs(OrderedBlocks()) do
        local entry = list[block.key]

        if entry and BlockShown(block.key) then
            visible[#visible + 1] = entry
            entry.holder:Show()
        elseif entry then
            entry.holder:Hide()
            entry.position = nil
        end
    end

    local count = #visible
    if count == 0 then
        frame:SetWidth(40)
        return
    end

    local share

    if db.fullWidth and not target then
        share = (UIParent:GetWidth() or 1024) / count
    end

    local gap = PanelStyle() == "pills" and db.panel and (target or not db.fullWidth) and PILL_GAP or 0

    if target then
        local function Measure(entry)
            return math.ceil((entry.label:GetStringWidth() + entry.value:GetStringWidth() + (db.blockPad or 25)) / 8) * 8
        end
        local ordered = {}
        for _, entry in ipairs(visible) do
            if entry.block.key == target.focus then table.insert(ordered, 1, entry) else ordered[#ordered + 1] = entry end
        end
        local kept, room = {}, 0
        for _, entry in ipairs(ordered) do
            local width = Measure(entry) + (#kept > 0 and gap or 0)
            if #kept == 0 or room + width <= (target.room or 300) then
                kept[#kept + 1] = entry
                room = room + width
            else
                entry.holder:Hide()
                entry.position = nil
            end
        end
        visible = kept
    end

    local total = 0
    local previous

    for index, entry in ipairs(visible) do
        local width = share or math.ceil((entry.label:GetStringWidth() + entry.value:GetStringWidth() + (db.blockPad or 25)) / 8) * 8

        if entry.width ~= width or entry.position ~= index then
            entry.width = width
            entry.position = index
            entry.holder:SetWidth(width)
            entry.holder:ClearAllPoints()

            if previous then
                entry.holder:SetPoint("LEFT", previous.holder, "RIGHT", gap, 0)
            else
                entry.holder:SetPoint("LEFT", frame, "LEFT", 0, 0)
            end
        end

        entry.divider:SetShown(index > 1 and gap == 0 and PanelStyle() ~= "fade" and db.dividers ~= false)
        total = total + width + (index > 1 and gap or 0)
        previous = entry
    end

    if target then
        frame:SetWidth(total)
        frame:SetScale(math.min(1.25, 300 / math.max(total, 1)))
        return
    end

    if db.fullWidth then return end

    if self.fitted ~= total then
        self.fitted = total
        self.frame:SetWidth(total)
        self:KeepOnScreen()
    end
end

function DataTexts:KeepOnScreen()
    local f = self.frame
    if not f then return end

    local left, right, bottom = f:GetLeft(), f:GetRight(), f:GetBottom()
    local limit = UIParent:GetRight()
    if not left or not right or not bottom or not limit then return end

    local shift = 0
    if right > limit then shift = limit - right end
    if left + shift < 0 then shift = -left end
    if math.abs(shift) < 0.5 then return end

    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left + shift, bottom)
end

function DataTexts:Show()
    if not Enabled() then return end

    self:Create()
    if self.frame then
        self.frame:Show()
        self:Refresh()
    end
end

function DataTexts:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Show()
        NS.Print("панель показателей включена")
    else
        if self.frame then self.frame:Hide() end
        NS.Print("панель показателей выключена")
    end
end

function DataTexts:Relayout()
    self:Restyle()
    self:Refresh()
end

function DataTexts:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value
    self:Relayout()
end

function DataTexts:SetBlock(key, value)
    local db = Settings()
    if not db then return end

    db.blocks[key] = value and true or false
    self:Relayout()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_MONEY")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function(_, event)
    SaveMoney()
    if event ~= "PLAYER_LOGIN" then return end
    if not Enabled() then return end

    if NS.After then
        NS.After(3, function() DataTexts:Show() end)
    end
end)

local function TargetAlpha(f, db)
    if NS.Movers and NS.Movers.IsActive and NS.Movers:IsActive() then return 1 end
    local full = (db.alpha or 100) / 100
    if db.combatHide and InCombatLockdown() then return 0 end
    if db.mouseover and not MouseIsOver(f) then return full * (db.restAlpha or 0) / 100 end
    return full
end

driver:SetScript("OnUpdate", function(self, step)
    local f = DataTexts.frame
    local db = f and f:IsShown() and Settings()
    if db and (db.mouseover or db.combatHide or (db.alpha or 100) < 100 or f:GetAlpha() < 1) then
        local target = TargetAlpha(f, db)
        local current = f:GetAlpha()
        if math.abs(current - target) > 0.005 then
            if current < target then
                f:SetAlpha(math.min(target, current + step * 6))
            else
                f:SetAlpha(math.max(target, current - step * 3))
            end
        end
    end

    elapsed = elapsed + step
    if elapsed < 1 then return end
    elapsed = 0

    if Enabled() then DataTexts:Refresh() end
end)
