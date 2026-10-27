local addonName, NS = ...

local TooltipScanner = {}

local match = string.match
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs

local scanTooltip = CreateFrame("GameTooltip", "NarcissusSirus_ScanTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local STAT_PATTERNS = {
    { pattern = "%+(%d+) Agility",      key = "agility" },
    { pattern = "%+(%d+) Strength",     key = "strength" },
    { pattern = "%+(%d+) Stamina",      key = "stamina" },
    { pattern = "%+(%d+) Intellect",    key = "intellect" },
    { pattern = "%+(%d+) Spirit",       key = "spirit" },
    { pattern = "%+(%d+) Hit Rating",   key = "hit" },
    { pattern = "%+(%d+) Crit Rating",  key = "crit" },
    { pattern = "%+(%d+) Haste Rating", key = "haste" },
    { pattern = "%+(%d+) Expertise Rating", key = "expertise" },
    { pattern = "%+(%d+) Attack Power", key = "attackPower" },
    { pattern = "%+(%d+) Spell Power",  key = "spellPower" },
    { pattern = "%+(%d+) Defense Rating", key = "defense" },
    { pattern = "%+(%d+) Dodge Rating",  key = "dodge" },
    { pattern = "%+(%d+) Parry Rating",  key = "parry" },
    { pattern = "%+(%d+) Resilience",    key = "resilience" },
    { pattern = "%+(%d+) Armor Penetration", key = "armorPen" },
    { pattern = "(%d+) Armor",          key = "armor" },
}

local statsCache = {}
local statsCacheCount = 0
local STATS_CACHE_LIMIT = 400

local STAT_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "strength",
    ITEM_MOD_AGILITY_SHORT = "agility",
    ITEM_MOD_STAMINA_SHORT = "stamina",
    ITEM_MOD_INTELLECT_SHORT = "intellect",
    ITEM_MOD_SPIRIT_SHORT = "spirit",
    ITEM_MOD_HIT_RATING_SHORT = "hit",
    ITEM_MOD_CRIT_RATING_SHORT = "crit",
    ITEM_MOD_HASTE_RATING_SHORT = "haste",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "expertise",
    ITEM_MOD_ATTACK_POWER_SHORT = "attackPower",
    ITEM_MOD_SPELL_POWER_SHORT = "spellPower",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "defense",
    ITEM_MOD_DODGE_RATING_SHORT = "dodge",
    ITEM_MOD_PARRY_RATING_SHORT = "parry",
    ITEM_MOD_RESILIENCE_RATING_SHORT = "resilience",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "armorPen",
    RESISTANCE0_NAME = "armor",
}

local function ClientStats(link)
    if type(GetItemStats) ~= "function" then return end
    local ok, raw = pcall(GetItemStats, link)
    if not ok or type(raw) ~= "table" or not next(raw) then return end
    local stats = {}
    for key, value in pairs(raw) do
        local name = STAT_KEYS[key]
        if name and tonumber(value) then stats[name] = (stats[name] or 0) + tonumber(value) end
    end
    return stats
end

function TooltipScanner:GetItemStats(link)
    if not link then return {} end

    local cached = statsCache[link]
    if cached then return cached end

    local client = ClientStats(link)
    if client then
        if statsCacheCount >= STATS_CACHE_LIMIT then
            statsCache = {}
            statsCacheCount = 0
        end
        statsCache[link] = client
        statsCacheCount = statsCacheCount + 1
        return client
    end

    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(link)
    if scanTooltip:NumLines() == 0 then return {} end

    local stats = {}
    for i = 2, scanTooltip:NumLines() do
        local line = _G["NarcissusSirus_ScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                for _, sp in ipairs(STAT_PATTERNS) do
                    local val = match(text, sp.pattern)
                    if val then
                        stats[sp.key] = (stats[sp.key] or 0) + tonumber(val)
                    end
                end
            end
        end
    end

    if statsCacheCount >= STATS_CACHE_LIMIT then
        statsCache = {}
        statsCacheCount = 0
    end
    statsCache[link] = stats
    statsCacheCount = statsCacheCount + 1

    return stats
end

local socketTooltip
local socketTextures = {}
do
    local tipName = "NarcissusSirus_SocketTip_" .. math.random(100000, 9999999)
    socketTooltip = CreateFrame("GameTooltip", tipName, UIParent, "GameTooltipTemplate")
    socketTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    for i = 1, 10 do
        socketTextures[i] = _G[tipName .. "Texture" .. i]
    end
end

local socketCache = {}
local socketCacheCount = 0
local SOCKET_CACHE_LIMIT = 400

local function ScanSockets(link)
    local cached = socketCache[link]
    if cached then return cached end

    socketTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    socketTooltip:ClearLines()
    socketTooltip:SetHyperlink(link)

    local data = { count = 0, textures = {} }
    if socketTooltip:NumLines() == 0 then return data end
    for i = 1, 10 do
        local tex = socketTextures[i]
        if tex and tex:IsShown() then
            data.count = data.count + 1
            data.textures[data.count] = tex:GetTexture()
        end
    end
    if socketCacheCount >= SOCKET_CACHE_LIMIT then
        socketCache = {}
        socketCacheCount = 0
    end
    socketCache[link] = data
    socketCacheCount = socketCacheCount + 1
    return data
end

function TooltipScanner:GetSocketCountFromTextures(link)
    if not link then return 0 end
    return ScanSockets(link).count
end

function TooltipScanner:GetSocketTexture(link, index)
    if not link then return nil end
    return ScanSockets(link).textures[index]
end

function TooltipScanner:GetEmptySocketCount(link)
    if not link then return 0 end
    local total = ScanSockets(link).count
    if total == 0 then return 0 end
    local gems = NS.GetGemInfo(link)
    local filled = 0
    for _ in pairs(gems) do filled = filled + 1 end
    return total - filled
end

NS.TooltipScanner = TooltipScanner
