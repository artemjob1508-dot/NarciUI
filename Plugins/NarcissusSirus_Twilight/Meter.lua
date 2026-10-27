local addonName, ns = ...
ns.Twilight = ns.Twilight or {}
local T = ns.Twilight

local API = T.API
if not API then return end

local L = function(text) return API:L(text) end
local WHITE = T.WHITE

local AFFILIATION_MINE = 0x00000001
local AFFILIATION_PARTY = 0x00000002
local AFFILIATION_RAID = 0x00000004
local TYPE_PLAYER = 0x00000400
local TYPE_PET = 0x00001000
local TYPE_GUARDIAN = 0x00002000

local GROUP_MASK = AFFILIATION_MINE + AFFILIATION_PARTY + AFFILIATION_RAID

local DAMAGE = {
    SWING_DAMAGE = 9, RANGE_DAMAGE = 12, SPELL_DAMAGE = 12, SPELL_PERIODIC_DAMAGE = 12,
    DAMAGE_SHIELD = 12, DAMAGE_SPLIT = 12, SPELL_BUILDING_DAMAGE = 12,
}
local HEAL = { SPELL_HEAL = 12, SPELL_PERIODIC_HEAL = 12 }

local owners = {}
local current, overall
local mode = "current"
local inCombat = false

local function NewSegment()
    return { damage = {}, heal = {}, start = nil, finish = nil }
end

current = NewSegment()
overall = NewSegment()

local function MapPets()
    owners = {}
    local function Add(unit, owner)
        local guid = UnitGUID(unit)
        if guid then owners[guid] = UnitGUID(owner) end
    end
    Add("pet", "player")
    for index = 1, GetNumPartyMembers() do Add("partypet" .. index, "party" .. index) end
    for index = 1, GetNumRaidMembers() do Add("raidpet" .. index, "raid" .. index) end
end

local classByGUID = {}
local nameByGUID = {}

local function Remember(guid, name)
    if classByGUID[guid] then return end
    nameByGUID[guid] = name
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        if UnitGUID(unit) == guid then
            classByGUID[guid] = select(2, UnitClass(unit))
            return
        end
    end
    for index = 1, GetNumRaidMembers() do
        local unit = "raid" .. index
        if UnitGUID(unit) == guid then
            classByGUID[guid] = select(2, UnitClass(unit))
            return
        end
    end
end

local function Actor(sourceGUID, sourceName, sourceFlags)
    if bit.band(sourceFlags, GROUP_MASK) == 0 then return end
    if bit.band(sourceFlags, TYPE_PLAYER) ~= 0 then
        Remember(sourceGUID, sourceName)
        return sourceGUID
    end
    if bit.band(sourceFlags, TYPE_PET + TYPE_GUARDIAN) ~= 0 then
        local owner = owners[sourceGUID]
        if not owner and bit.band(sourceFlags, AFFILIATION_MINE) ~= 0 then owner = UnitGUID("player") end
        if owner then
            Remember(owner, nameByGUID[owner] or UnitName("player"))
            return owner
        end
    end
end

local function Add(segment, kind, guid, amount)
    local list = segment[kind]
    list[guid] = (list[guid] or 0) + amount
    local now = GetTime()
    segment.start = segment.start or now
    segment.finish = now
end

local function Duration(segment)
    if not segment.start then return 1 end
    local finish = (inCombat and segment == current) and GetTime() or segment.finish or segment.start
    return math.max(1, finish - segment.start)
end

local panel, columns
local dirty = true

local function Sorted(list)
    local rows, total = {}, 0
    for guid, amount in pairs(list) do
        rows[#rows + 1] = { guid = guid, amount = amount }
        total = total + amount
    end
    table.sort(rows, function(a, b) return a.amount > b.amount end)
    return rows, total
end

local function ClassColor(guid)
    local class = classByGUID[guid]
    local color = class and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.6, 0.6, 0.6
end

local function Short(value)
    value = value or 0
    if value >= 1e6 then return string.format("%.2fM", value / 1e6) end
    if value >= 1e5 then return string.format("%.0fK", value / 1e3) end
    if value >= 1e3 then return string.format("%.1fK", value / 1e3) end
    return tostring(math.floor(value + 0.5))
end

local function Row(column, index)
    local row = column.rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, column)
    row:SetHeight(16)
    row:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -20 - (index - 1) * 18)
    row:SetPoint("TOPRIGHT", column, "TOPRIGHT", 0, -20 - (index - 1) * 18)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")

    row.name = T.Text(row, 11, "LEFT")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 3, 0)
    row.name:SetHeight(14)

    row.value = T.Text(row, 11, "RIGHT")
    row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.value:SetSize(108, 14)
    row.name:SetPoint("RIGHT", row.value, "LEFT", -3, 0)

    row.line = row:CreateTexture(nil, "ARTWORK")
    row.line:SetTexture(WHITE)
    row.line:SetHeight(2)
    row.line:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 19, 0)

    column.rows[index] = row
    return row
end

local function Fill(column, list, kind, segment)
    local rows, total = Sorted(list)
    local duration = Duration(segment)
    local top = rows[1] and rows[1].amount or 1
    local width = column:GetWidth() - 19
    local room = math.max(1, math.floor((column:GetHeight() - 20) / 18))

    for index = 1, math.max(room, #column.rows) do
        local entry = rows[index]
        if entry and index <= room then
            local row = Row(column, index)
            local r, g, b = ClassColor(entry.guid)
            local class = classByGUID[entry.guid]
            local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
            if coords then
                row.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                row.icon:Show()
            else
                row.icon:Hide()
            end
            row.name:SetText(index .. ". " .. (nameByGUID[entry.guid] or "?"))
            row.name:SetTextColor(r, g, b)
            local share = total > 0 and entry.amount / total * 100 or 0
            local perSecond = entry.amount / duration
            if kind == "damage" then
                row.value:SetText(string.format("%s (%s, %.1f%%)", Short(entry.amount), Short(perSecond), share))
            else
                row.value:SetText(string.format("%s   %s   %.1f%%", Short(entry.amount), Short(perSecond), share))
            end
            row.line:SetVertexColor(r, g, b, 1)
            row.line:SetWidth(math.max(1, width * entry.amount / top))
            row:Show()
        elseif column.rows[index] then
            column.rows[index]:Hide()
        end
    end
end

local function Render()
    if not panel or not panel:IsVisible() then return end
    dirty = false
    local segment = mode == "overall" and overall or current
    Fill(columns[1], segment.damage, "damage", segment)
    Fill(columns[2], segment.heal, "heal", segment)
end

local function Column(parent, title, icon)
    local column = CreateFrame("Button", nil, parent)
    column.rows = {}
    column:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local head = column:CreateTexture(nil, "ARTWORK")
    head:SetSize(16, 16)
    head:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -1)
    head:SetTexture(icon)
    head:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local text = T.Text(column, 13, "LEFT")
    text:SetPoint("LEFT", head, "RIGHT", 6, 0)
    text:SetTextColor(0.85, 0.85, 0.85)
    text:SetText(title)
    column.title = text

    column:SetScript("OnClick", function(_, button)
        if button == "RightButton" and IsShiftKeyDown() then
            current, overall = NewSegment(), NewSegment()
            dirty = true
            Render()
            return
        end
        mode = mode == "current" and "overall" or "current"
        dirty = true
        Render()
    end)
    column:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(mode == "current" and L("Текущий бой") or L("Всё время"), 1, 1, 1)
        GameTooltip:AddLine(L("Клик - текущий бой / всё время, Shift+правый клик - сброс"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    column:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return column
end

function T.BuildMeter()
    if panel or not T.rightPanel then return end
    if T.db.meter == false then return end

    panel = CreateFrame("Frame", "NarciTwilight_Meter", T.rightPanel)
    panel:SetPoint("TOPLEFT", T.rightPanel, "TOPLEFT", 4, -7)
    panel:SetPoint("BOTTOMRIGHT", T.rightStrip, "TOPRIGHT", -2, 3)
    panel:SetFrameLevel(T.rightPanel:GetFrameLevel() + 2)

    local left = Column(panel, L("Нанесённый урон"), "Interface\\Icons\\Spell_Fire_FireBolt02")
    left:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", -2, 0)
    local right = Column(panel, L("Исцеление"), "Interface\\Icons\\Spell_Nature_HealingTouch")
    right:SetPoint("TOPLEFT", panel, "TOP", 2, 0)
    right:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    columns = { left, right }

    local events = CreateFrame("Frame")
    events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:RegisterEvent("RAID_ROSTER_UPDATE")
    events:RegisterEvent("UNIT_PET")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, sourceGUID, sourceName, sourceFlags = ...
            local index = DAMAGE[subEvent]
            local kind = "damage"
            if not index then
                index = HEAL[subEvent]
                kind = "heal"
            end
            if not index or not sourceGUID then return end
            local guid = Actor(sourceGUID, sourceName, sourceFlags or 0)
            if not guid then return end
            local amount = select(index, ...) or 0
            if kind == "heal" then
                local overheal = select(index + 1, ...) or 0
                amount = amount - overheal
            end
            if amount <= 0 then return end
            Add(current, kind, guid, amount)
            Add(overall, kind, guid, amount)
            dirty = true
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true
            current = NewSegment()
            dirty = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false
            dirty = true
        else
            MapPets()
        end
    end)

    local ticker = CreateFrame("Frame", nil, panel)
    ticker:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 0.5
        if dirty or inCombat then Render() end
    end)

    MapPets()
    Render()
end

API:AddTranslations("enUS", {
    ["Нанесённый урон"] = "Damage done",
    ["Исцеление"] = "Healing",
    ["Текущий бой"] = "Current fight",
    ["Всё время"] = "Overall",
    ["Клик - текущий бой / всё время, Shift+правый клик - сброс"] = "Click - current fight / overall, Shift+right click - reset",
    ["Окно урона и исцеления"] = "Damage and healing window",
})
