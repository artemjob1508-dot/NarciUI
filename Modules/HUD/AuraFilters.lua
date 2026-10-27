local addonName, NS = ...

local Filters = {}
NS.AuraFilters = Filters

Filters.RAID_DEBUFF_IDS = {
    28169, 55593, 27808, 27819, 28410, 28622,
    63024, 63018, 62438, 62717, 62166, 63830, 63802, 63276, 61903, 61888,
    66197, 66237, 66334, 66869, 66823, 66013,
    69065, 69146, 71289, 69279, 69240, 72219, 69291, 69674, 70447, 70672, 70911, 70953,
    71340, 70867, 70877, 72293, 72385, 72410, 70126, 69762, 69766, 70128, 70157,
    70337, 70541, 69409, 68980,
    74562, 74792,
}

Filters.CLASS_INDICATORS = {
    PRIEST = {
        { id = 139,   color = { 0.35, 1.00, 0.45 } },
        { id = 17,    color = { 1.00, 0.95, 0.55 } },
        { id = 41635, color = { 0.95, 0.55, 0.95 } },
        { id = 47788, color = { 1.00, 0.85, 0.30 } },
    },
    DRUID = {
        { id = 774,   color = { 0.85, 0.35, 0.95 } },
        { id = 8936,  color = { 0.35, 0.95, 0.40 } },
        { id = 33763, color = { 0.55, 1.00, 0.55 } },
        { id = 48438, color = { 0.40, 0.80, 1.00 } },
    },
    PALADIN = {
        { id = 53563, color = { 1.00, 0.90, 0.40 } },
        { id = 53601, color = { 1.00, 0.65, 0.25 } },
        { id = 6940,  color = { 0.95, 0.35, 0.35 } },
        { id = 1022,  color = { 0.55, 0.75, 1.00 } },
    },
    SHAMAN = {
        { id = 61295, color = { 0.30, 0.75, 1.00 } },
        { id = 974,   color = { 0.65, 0.50, 0.25 } },
    },
}

local DISPELS = {
    PRIEST  = { Magic = true, Disease = true },
    PALADIN = { Magic = true, Disease = true, Poison = true },
    SHAMAN  = { Disease = true, Poison = true, Curse = true },
    DRUID   = { Curse = true, Poison = true },
    MAGE    = { Curse = true },
}

local nameCache = {}

local function SpellName(id)
    local cached = nameCache[id]
    if cached ~= nil then return cached or nil end
    local name = GetSpellInfo and GetSpellInfo(id)
    nameCache[id] = name or false
    return name
end

Filters.SpellName = SpellName

local listCache = {}
local EMPTY = {}

function Filters.ParseList(text)
    if type(text) ~= "string" or text == "" then return EMPTY end
    local cached = listCache[text]
    if cached then return cached end
    local set = {}
    for part in text:gmatch("[^,;\n]+") do
        local name = part:gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" then
            local id = tonumber(name)
            if id then name = SpellName(id) or name end
            set[name] = true
        end
    end
    listCache[text] = set
    return set
end

local raidSet

function Filters.RaidDebuffs(extra, builtin)
    if builtin ~= false and not raidSet then
        raidSet = {}
        for _, id in ipairs(Filters.RAID_DEBUFF_IDS) do
            local name = SpellName(id)
            if name then raidSet[name] = true end
        end
    end
    return builtin ~= false and raidSet or EMPTY, Filters.ParseList(extra)
end

function Filters.IsRaidDebuff(name, extra, builtin)
    local base, custom = Filters.RaidDebuffs(extra, builtin)
    return base[name] or custom[name] or false
end

function Filters.CanDispel(debuffType)
    local _, class = UnitClass("player")
    local list = class and DISPELS[class]
    return list and debuffType and list[debuffType] or false
end

local indicatorCache

function Filters.Reset()
    indicatorCache = nil
end

function Filters.Indicators(off, extra)
    if indicatorCache and indicatorCache.extra == extra then return indicatorCache.list end
    local _, class = UnitClass("player")
    local list = {}
    for _, entry in ipairs(Filters.CLASS_INDICATORS[class or ""] or {}) do
        local name = SpellName(entry.id)
        if name and not (type(off) == "table" and off[entry.id]) then
            list[#list + 1] = { name = name, color = entry.color, id = entry.id }
        end
    end
    for name in pairs(Filters.ParseList(extra)) do
        list[#list + 1] = { name = name, color = { 0.9, 0.9, 0.9 } }
    end
    if class then indicatorCache = { extra = extra, list = list } end
    return list
end

local filterKeys = {}

local function FilterKeys(prefix)
    local keys = filterKeys[prefix]
    if not keys then
        keys = { prefix .. "Blacklist", prefix .. "Whitelist", prefix .. "Mine" }
        filterKeys[prefix] = keys
    end
    return keys
end

function Filters.Allowed(name, caster, db, prefix)
    if not name then return false end
    local keys = FilterKeys(prefix)
    local black = Filters.ParseList(db[keys[1]])
    if black[name] then return false end
    local whiteText = db[keys[2]]
    if type(whiteText) == "string" and whiteText ~= "" then
        if not Filters.ParseList(whiteText)[name] then return false end
    end
    if db[keys[3]] and caster ~= "player" and caster ~= "pet" and caster ~= "vehicle" then return false end
    return true
end
