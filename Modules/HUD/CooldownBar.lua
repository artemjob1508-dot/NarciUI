local addonName, NS = ...
local L = NS.L

local Bar = {}
NS.CooldownBar = Bar

local WHITE = "Interface\\Buttons\\WHITE8x8"

local ACTION_SLOTS = 120
local ITEM_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local MIN_DURATION = 2
local THROTTLE = 0.1
local SCAN_DELAY = 0.2
local MARKS = { 1, 10, 30, 60, 120, 180 }

local tracked = {}
local pool = {}
local icons = {}
local occupied = nil
local elapsed = 0

local function FillSettings()
    if not NS.db then return end

    if not NS.db.cooldownBar then
        NS.db.cooldownBar = {}
    end

    local db = NS.db.cooldownBar
    if db.enabled == nil then db.enabled = true end
    db.width = db.width or 460
    db.height = db.height or 34
    db.maxTime = db.maxTime or 180
    db.compression = db.compression or 0.4
    db.locked = db.locked ~= false
    if db.snap == nil then db.snap = true end
    db.style = db.style or "rail"
    if db.hideIdle == nil then db.hideIdle = false end
    if db.srcActions == nil then db.srcActions = true end
    if db.srcSpells == nil then db.srcSpells = true end
    if db.srcPet == nil then db.srcPet = true end
    if db.srcEquip == nil then db.srcEquip = true end
    if db.srcBags == nil then db.srcBags = true end
    db.minDuration = db.minDuration or MIN_DURATION

    if not db.slimDefault then
        db.slimDefault = true
        db.height = 26
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.cooldownBar
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local STYLES = { rail = true, track = true, line = true, neon = true, zones = true, pixel = true, glass = true, dark = true }

local function BarStyle(db)
    return STYLES[db.style] and db.style or "rail"
end

local function IconEdge(icon, hover)
    local S = NS.Styling
    if hover then
        icon.edge:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    elseif icon.neon then
        icon.edge:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
    else
        icon.edge:SetVertexColor(0.0, 0.0, 0.0, 0.9)
    end
end

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function Position(value, db)
    local share = math.pow(value, db.compression) / math.pow(db.maxTime, db.compression)
    if share > 1 then share = 1 end
    if share < 0 then share = 0 end
    return share
end

local function MarkText(value)
    if value >= 60 then
        return math.floor(value / 60) .. L["м"]
    end
    return tostring(value)
end

local function TimeText(value)
    if value >= 60 then
        return math.floor(value / 60) .. ":" .. string.format("%02d", math.floor(value % 60))
    elseif value >= 10 then
        return tostring(math.floor(value))
    end
    return string.format("%.1f", value)
end

function Bar:CreateIcon(parent)
    local db = Settings()

    local icon = CreateFrame("Button", nil, parent or self.frame)
    icon:SetSize(db.height - 6, db.height - 6)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local edge = icon:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints(icon)
    edge:SetTexture(WHITE)
    edge:SetVertexColor(0.0, 0.0, 0.0, 0.9)

    local label = icon:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(label, "cooldowns", NS.FS(10), "OUTLINE")
    label:SetPoint("CENTER", icon, "CENTER", 0, 0)
    label:SetTextColor(NS.Look:Text("cooldowns", NS.Styling.TEXT_BRIGHT))

    icon.texture = texture
    icon.edge = edge
    icon.label = label

    icon:SetScript("OnEnter", function(self) IconEdge(self, true) end)
    icon:SetScript("OnLeave", function(self) IconEdge(self, false) end)

    icon.neon = BarStyle(db) == "neon"
    IconEdge(icon, false)

    return icon
end

local function BuildFrame(f)
    local S = NS.Styling
    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL",
        0.016, 0.018, 0.026, 0.80,
        0.016, 0.018, 0.026, 0.30)

    local rail = f:CreateTexture(nil, "BORDER")
    rail:SetHeight(1)
    rail:SetPoint("LEFT", f, "LEFT", 8, 0)
    rail:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    rail:SetTexture(WHITE)
    rail:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.08)

    local halo = f:CreateTexture(nil, "BORDER")
    halo:SetHeight(9)
    halo:SetPoint("LEFT", f, "LEFT", 8, 0)
    halo:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    halo:SetTexture(WHITE)
    halo:SetBlendMode("ADD")
    halo:Hide()

    local zones = {}
    for index, alpha in ipairs({ 0.30, 0.14, 0.05 }) do
        local zone = f:CreateTexture(nil, "BORDER")
        zone:SetTexture(WHITE)
        zone:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], alpha)
        zone:Hide()
        zones[index] = zone
    end

    f.ground, f.rail, f.halo, f.zones = ground, rail, halo, zones
    f.edges = S.CreateEdges(f, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    f.marks = {}

    for index, value in ipairs(MARKS) do
        local tick = f:CreateTexture(nil, "ARTWORK")
        tick:SetSize(1, 5)
        tick:SetPoint("CENTER", f, "LEFT", 0, 0)
        tick:SetTexture(WHITE)
        tick:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.45)

        local text = f:CreateFontString(nil, "OVERLAY")
        NS.LSetFont(text, "cooldowns", NS.FS(8), "")
        text:SetPoint("BOTTOM", f, "LEFT", 0, 3)
        text:SetTextColor(NS.Look:Text("cooldowns", S.TEXT_DIM))
        text:SetText(MarkText(value))

        f.marks[index] = { value = value, tick = tick, text = text }
    end

end

function Bar:Create()
    if self.frame then return end

    local db = Settings()
    if not db then return end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarciSirus_CooldownBar", UIParent)
    f:SetSize(db.width, db.height)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(not db.locked)
    f:RegisterForDrag("LeftButton")

    if db.point then
        f:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 210)
    end

    f:SetScript("OnDragStart", function(self)
        if Settings().locked then return end
        self:StartMoving()
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, relativePoint, x, y = self:GetPoint()
        local store = Settings()
        store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
    end)

    BuildFrame(f)

    self.frame = f
    self:ApplyStyle()

    if NS.Movers then
        NS.Movers:Register(f, L["Шкала кулдаунов"], function(point, relativePoint, x, y)
            local store = Settings()
            store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
        end, "cooldown")
    end
end

function Bar:Layout(frame)
    local f = frame or self.frame
    local db = Settings()
    if not f or not db then return end

    f:SetSize(db.width, db.height)

    local style = BarStyle(db)

    local bounds = { 0, Position(10, db), Position(60, db), 1 }
    for index, zone in ipairs(f.zones) do
        local left = math.floor(bounds[index] * db.width + 0.5)
        local right = math.floor(bounds[index + 1] * db.width + 0.5)
        zone:ClearAllPoints()
        zone:SetPoint("TOPLEFT", f, "TOPLEFT", left, -1)
        zone:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", left, 1)
        zone:SetWidth(math.max(right - left, 1))
    end

    for _, mark in ipairs(f.marks) do
        local offset = Position(mark.value, db) * db.width

        mark.tick:SetSize(1, style == "track" and (db.height - 2) or 5)
        mark.tick:ClearAllPoints()
        mark.tick:SetPoint("CENTER", f, "LEFT", offset, 0)

        mark.text:ClearAllPoints()
        mark.text:SetPoint("BOTTOM", f, "LEFT", offset, 4)
        mark.text:SetText(MarkText(mark.value))
    end
end

function Bar:SnapTo(left, right, top)
    local db = Settings()
    local f = self.frame
    if not db or not f or not db.snap then return end

    local width = math.floor(right - left + 0.5)
    local x = math.floor(left + 0.5)
    local y = math.floor(top + 0.5)

    if self.snapWidth == width and self.snapX == x and self.snapY == y then return end

    self.snapWidth, self.snapX, self.snapY = width, x, y
    db.width = width

    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)

    self:Layout()
end

local function Remember(key, name, texture, start, duration)
    local db = Settings()
    local minimum = db and db.minDuration or MIN_DURATION
    if not start or start == 0 or not duration or duration < minimum then return end
    if tracked["tex:" .. tostring(texture)] then return end
    key = "tex:" .. tostring(texture)

    local remaining = start + duration - GetTime()
    if remaining <= 0 then return end

    local entry = pool[key]

    if not entry then
        entry = {}
        pool[key] = entry
    end

    entry.name = name
    entry.texture = texture
    entry.remaining = remaining
    entry.stamp = nil
    entry.finish = nil

    tracked[key] = entry
end

function Bar:MapSlots()
    occupied = occupied or {}

    for index = #occupied, 1, -1 do occupied[index] = nil end

    for slot = 1, ACTION_SLOTS do
        if HasAction(slot) then occupied[#occupied + 1] = slot end
    end
end

function Bar:MapSpells()
    local list = {}
    local function Add(book, first, last)
        for index = first, last do
            local ok, name = pcall(GetSpellName, index, book)
            if ok and name and not (IsPassiveSpell and IsPassiveSpell(index, book)) then
                list[#list + 1] = { index, book }
            end
        end
    end
    for tab = 1, (GetNumSpellTabs and GetNumSpellTabs() or 0) do
        local _, _, offset, count, highOffset, highCount = GetSpellTabInfo(tab)
        if highOffset and highCount then offset, count = highOffset, highCount end
        if offset and count then Add(BOOKTYPE_SPELL or "spell", offset + 1, offset + count) end
    end
    local pets = HasPetSpells and HasPetSpells()
    if pets and pets > 0 then Add(BOOKTYPE_PET or "pet", 1, pets) end
    self.spells = list
end

function Bar:Collect()
    for key in pairs(tracked) do tracked[key] = nil end

    local db = Settings()

    if db.srcSpells or db.srcPet then
        if not self.spells then self:MapSpells() end
        local petBook = BOOKTYPE_PET or "pet"
        for _, spell in ipairs(self.spells) do
            local index, book = spell[1], spell[2]
            if (book == petBook and db.srcPet) or (book ~= petBook and db.srcSpells) then
                local start, duration, enable = GetSpellCooldown(index, book)
                if enable == 1 and start and start > 0 then
                    Remember(nil, nil, GetSpellTexture(index, book), start, duration)
                end
            end
        end
    end

    if db.srcEquip then
        for _, slot in ipairs(ITEM_SLOTS) do
            local texture = GetInventoryItemTexture("player", slot)
            if texture then
                local start, duration, enable = GetInventoryItemCooldown("player", slot)
                if enable == 1 then Remember(nil, nil, texture, start, duration) end
            end
        end
    end

    if db.srcBags then
        for bag = 0, 4 do
            for slot = 1, (GetContainerNumSlots(bag) or 0) do
                local texture = GetContainerItemInfo(bag, slot)
                if texture then
                    local start, duration, enable = GetContainerItemCooldown(bag, slot)
                    if enable == 1 then Remember(nil, nil, texture, start, duration) end
                end
            end
        end
    end

    if not db.srcActions then return end

    if not occupied then self:MapSlots() end

    for index = 1, #occupied do
        local slot = occupied[index]
        local texture = GetActionTexture(slot)

        if texture then
            local start, duration, enable = GetActionCooldown(slot)
            if enable == 1 then
                Remember("action:" .. tostring(texture), nil, texture, start, duration)
            end
        end
    end

end

function Bar:Refresh()
    local f = self.frame
    local db = Settings()
    if not f or not db then return end

    local used = 0
    local now = GetTime()

    for key, entry in pairs(tracked) do
        local remaining = entry.remaining - (now - (entry.stamp or now))

        if entry.finish and entry.finish - now > 0 then
            remaining = entry.finish - now
        end

        if remaining > 0 then
            used = used + 1

            local icon = icons[used]
            if not icon then
                icon = self:CreateIcon()
                icons[used] = icon
            end

            local clamped = remaining
            if clamped > db.maxTime then clamped = db.maxTime end

            local offset = Position(clamped, db) * (db.width - db.height)

            icon:ClearAllPoints()
            icon:SetPoint("LEFT", f, "LEFT", offset, 0)
            icon:SetSize(db.height - 6, db.height - 6)
            icon.texture:SetTexture(entry.texture)
            icon.label:SetText(TimeText(remaining))
            icon:Show()
        end
    end

    for index = used + 1, #icons do
        icons[index]:Hide()
    end

    self:Idle(used == 0)
end

function Bar:Idle(idle)
    local f = self.frame
    if not f or self.idle == idle then return end

    self.idle = idle

    for _, mark in ipairs(f.marks) do
        mark.text:SetAlpha(idle and 0.35 or 1)
        mark.tick:SetAlpha(idle and 0.5 or 1)
    end

    local db = Settings()
    if idle and db and db.hideIdle then
        f:SetAlpha(0)
    elseif idle and db and BarStyle(db) == "line" then
        f:SetAlpha(0.35)
    else
        f:SetAlpha(idle and 0.55 or 1)
    end
end

function Bar:ApplyStyle(frame, list)
    local f = frame or self.frame
    local db = Settings()
    if not f or not db then return end

    local S = NS.Styling
    local style = BarStyle(db)
    local A, G = S.ACCENT, S.ACCENT_GLOW

    if style == "line" then
        f.ground:Hide()
    else
        f.ground:Show()
        if style == "track" then
            f.ground:SetGradientAlpha("VERTICAL", 0.016, 0.018, 0.026, 0.92, 0.030, 0.034, 0.046, 0.92)
        elseif style == "neon" then
            f.ground:SetGradientAlpha("VERTICAL", 0.010, 0.010, 0.016, 0.88, 0.010, 0.010, 0.016, 0.88)
        elseif style == "pixel" then
            f.ground:SetGradientAlpha("VERTICAL", 0.07, 0.07, 0.075, 0.95, 0.07, 0.07, 0.075, 0.95)
        elseif style == "glass" then
            f.ground:SetGradientAlpha("VERTICAL", 0.04, 0.06, 0.10, 0.55, 0.08, 0.10, 0.16, 0.55)
        elseif style == "dark" then
            f.ground:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.8, 0, 0, 0, 0.8)
        else
            f.ground:SetGradientAlpha("VERTICAL", 0.016, 0.018, 0.026, 0.80, 0.016, 0.018, 0.026, 0.30)
        end
    end

    for _, line in ipairs(f.edges) do
        line:SetShown(style == "track" or style == "neon" or style == "pixel" or style == "glass")
        if style == "neon" then
            line:SetVertexColor(A[1] * 0.6, A[2] * 0.6, A[3] * 0.6, 0.9)
        elseif style == "pixel" and not NS.Look:Color("cooldowns", "border") then
            line:SetVertexColor(0, 0, 0, 1)
        elseif style == "glass" and not NS.Look:Color("cooldowns", "border") then
            line:SetVertexColor(A[1] * 0.8, A[2] * 0.8, A[3] * 0.8, 0.9)
        else
            line:SetVertexColor(NS.Look:Border("cooldowns", 0.9))
        end
    end
    local gr, gg, gb = NS.Look:Color("cooldowns", "bg")
    if gr then f.ground:SetGradientAlpha("VERTICAL", gr, gg, gb, 0.85, gr, gg, gb, 0.85) end

    local railOn = style == "line" or db.rail == true
    f.rail:SetShown(railOn and style ~= "zones" and style ~= "track")
    if style == "neon" then
        f.rail:SetHeight(2)
        f.rail:SetGradientAlpha("HORIZONTAL", G[1], G[2], G[3], 1, A[1], A[2], A[3], 0.55)
        f.halo:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.35, A[1], A[2], A[3], 0.08)
    elseif style == "line" then
        f.rail:SetHeight(1)
        f.rail:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.9, A[1], A[2], A[3], 0.25)
    else
        f.rail:SetHeight(1)
        f.rail:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.55, A[1], A[2], A[3], 0.08)
    end
    f.halo:SetShown(style == "neon" and railOn)

    for _, zone in ipairs(f.zones) do zone:SetShown(style == "zones") end

    for _, mark in ipairs(f.marks) do
        if style == "track" then
            mark.tick:SetVertexColor(1, 1, 1, 0.12)
        else
            mark.tick:SetVertexColor(G[1], G[2], G[3], 0.45)
        end
    end

    for _, icon in ipairs(list or icons) do
        icon.neon = style == "neon"
        IconEdge(icon, false)
    end

    if frame then
        self:Layout(frame)
        return
    end
    self:Layout()
    self.idle = nil
    self:Refresh()
end

local SAMPLE_COOLDOWNS = {
    { "Interface\\Icons\\Spell_Holy_PowerWordShield", 4.3 },
    { "Interface\\Icons\\Spell_Nature_Lightning", 26 },
    { "Interface\\Icons\\Ability_Warrior_BattleShout", 95 },
}

function Bar:CreateSample(parent)
    local f = CreateFrame("Frame", nil, parent)
    BuildFrame(f)
    f.sampleIcons = {}
    for index, data in ipairs(SAMPLE_COOLDOWNS) do
        local icon = self:CreateIcon(f)
        icon.texture:SetTexture(data[1])
        f.sampleIcons[index] = icon
    end
    return f
end

function Bar:PaintSample(f)
    local db = Settings()
    if not db or not f then return end
    self:ApplyStyle(f, f.sampleIcons)
    f:SetScale(math.min(1, 300 / math.max(db.width, 1)))
    for index, icon in ipairs(f.sampleIcons) do
        local remaining = SAMPLE_COOLDOWNS[index][2]
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", f, "LEFT", Position(remaining, db) * (db.width - db.height), 0)
        icon:SetSize(db.height - 6, db.height - 6)
        icon.label:SetText(TimeText(remaining))
        icon:Show()
    end
    for _, mark in ipairs(f.marks) do
        mark.text:SetAlpha(1)
        mark.tick:SetAlpha(1)
    end
    f:SetAlpha(1)
end

function Bar:SetOption(field, value)
    local db = Settings()
    if not db then return end
    db[field] = value
    self:ApplyStyle()
    if field:find("^src") or field == "minDuration" then self:Scan() end
end

function Bar:Scan()
    if not Enabled() then return end

    self:Collect()

    local now = GetTime()
    for _, entry in pairs(tracked) do
        entry.stamp = now
        entry.finish = now + entry.remaining
    end

    self:Refresh()

    if self.ticker then
        if next(tracked) then self.ticker:Show() else self.ticker:Hide() end
    end
end

function Bar:QueueScan()
    if self.scanQueued or not NS.After then return end

    self.scanQueued = true

    NS.After(SCAN_DELAY, function()
        Bar.scanQueued = nil
        Bar:Scan()
    end)
end

function Bar:Show()
    if not self.frame then self:Create() end
    if not self.frame then return end

    self.frame:Show()
    self:Scan()
end

function Bar:Hide()
    if self.frame then self.frame:Hide() end
end

function Bar:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Show()
        NS.Print("шкала кулдаунов включена")
    else
        self:Hide()
        NS.Print("шкала кулдаунов выключена")
    end
end

function Bar:Lock()
    if NS.Movers then NS.Movers:Toggle("cooldown") end
end

function Bar:SetMax(value)
    local db = Settings()
    local seconds = tonumber(value)
    if not db or not seconds or seconds < 10 then
        NS.Print("укажите длину шкалы в секундах, например /narci cd max 180")
        return
    end

    db.maxTime = seconds
    self:Layout()
    self:Refresh()
    NS.Print("длина шкалы: " .. seconds .. " сек")
end

function Bar:SetCompression(value)
    local db = Settings()
    local number = tonumber(value)
    if not db or not number then return end
    db.compression = math.max(0.1, math.min(1, number))
    if self.frame then
        self:Layout()
        self:Refresh()
    end
end

function Bar:ResetPosition()
    local db = Settings()
    if not db then return end

    db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil

    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 210)
    end

    NS.Print("шкала кулдаунов возвращена на место")
end

function Bar:SetWidth(value)
    local db = Settings()
    local width = tonumber(value)
    if not db or not width or width < 120 then
        NS.Print("укажите ширину, например /narci cd width 460")
        return
    end

    db.width = width
    self:Layout()
    self:Refresh()
    NS.Print("ширина шкалы: " .. width)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("SPELL_UPDATE_COOLDOWN")
driver:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
driver:RegisterEvent("BAG_UPDATE_COOLDOWN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
driver:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
driver:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
driver:RegisterEvent("SPELLS_CHANGED")
driver:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
driver:RegisterEvent("UNIT_PET")

driver:SetScript("OnEvent", function(self, event)
    if not Enabled() then
        Bar:Hide()
        return
    end

    if event == "SPELLS_CHANGED" or event == "UNIT_PET" then
        Bar.spells = nil
        Bar:QueueScan()
        return
    end

    if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED"
        or event == "UPDATE_BONUS_ACTIONBAR" then
        occupied = nil
        Bar:QueueScan()
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        occupied = nil
        if NS.After then
            NS.After(2, function() Bar:Show() end)
        end
        return
    end

    Bar:QueueScan()
end)

local ticker = CreateFrame("Frame")
ticker:Hide()

ticker:SetScript("OnUpdate", function(self, step)
    elapsed = elapsed + step
    if elapsed < THROTTLE then return end
    elapsed = 0

    if not next(tracked) then
        self:Hide()
        Bar:Idle(true)
        return
    end

    if Bar.frame and Bar.frame:IsShown() then Bar:Refresh() end
end)

Bar.ticker = ticker
