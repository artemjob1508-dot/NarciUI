local addonName, NS = ...
local L = NS.L
local LSpec = NS.LSpec

local StatPriority = {}

local SPEC_BY_TAB = {
    WARRIOR     = { "ARMS",    "FURY",   "PROT"   },
    PALADIN     = { "HOLY",    "PROT",   "RET"    },
    HUNTER      = { "BM",      "MM",     "SURV"   },
    ROGUE       = { "ASSA",    "COMBAT", "SUB"    },
    PRIEST      = { "DISC",    "HOLY",   "SHADOW" },
    DEATHKNIGHT = { "BLOOD",   "FROST",  "UNHOLY" },
    SHAMAN      = { "ELEM",    "ENH",    "RESTO"  },
    MAGE        = { "ARCANE",  "FIRE",   "FROST"  },
    WARLOCK     = { "AFFLI",   "DEMO",   "DESTRO" },
    DRUID       = { "BALANCE", "FERAL",  "RESTO"  },
    DEMONHUNTER = { "HAVOC",   "VENGE",  "POSSESS"},
}

local TANK_VARIANT = {
    DEATHKNIGHT = { BLOOD = "BLOOD_TANK", FROST = "FROST_TANK", UNHOLY = "UNHOLY_TANK" },
    DRUID       = { FERAL = "GUARDIAN" },
}

local SPEC_NAME = {
    ARMS = "Оружие", FURY = "Неистовство", PROT = "Защита",
    HOLY = "Свет", RET = "Воздаяние",
    BM = "Повелитель зверей", MM = "Стрельба", SURV = "Выживание",
    ASSA = "Ликвидация", COMBAT = "Бой", SUB = "Скрытность",
    DISC = "Послушание", SHADOW = "Тьма",
    BLOOD = "Кровь", FROST = "Лёд", UNHOLY = "Нечестивость",
    BLOOD_TANK = "Кровь, танк", FROST_TANK = "Лёд, танк", UNHOLY_TANK = "Нечестивость, танк",
    ELEM = "Стихии", ENH = "Совершенствование", RESTO = "Восстановление",
    ARCANE = "Тайная магия", FIRE = "Огонь",
    AFFLI = "Колдовство", DEMO = "Демонология", DESTRO = "Разрушение",
    BALANCE = "Баланс", FERAL = "Кот", GUARDIAN = "Страж",
    HAVOC = "Хаос", VENGE = "Месть", POSSESS = "Одержимость",
}

local ROLE_NAME = {
    MELEE       = "мили ДД",
    MELEE_MAGIC = "мили ДД, урон магией",
    RANGED      = "РДД, физический урон",
    CASTER      = "РДД-кастер",
    HEALER      = "хил",
    TANK        = "танк",
}

local ROLE_CAPS = {
    MELEE       = { "HIT", "EXP", "ARP", "CRIT", "STR", "AGI", "AP" },
    MELEE_MAGIC = { "HIT", "EXP", "ARP", "CRIT", "STR", "AP" },
    RANGED      = { "HIT", "ARP", "CRIT", "AGI", "AP" },
    CASTER      = { "HIT", "SPELLHASTE", "SP", "SPELLCRIT" },
    HEALER      = { "INT", "SPELLHASTE", "HEAL", "SPELLCRIT", "SPI", "MP5" },
    TANK        = { "DEF", "HIT", "EXP", "STA", "ARMOR" },
}

local ROLE_OF = {
    WARRIOR     = { ARMS = "MELEE", FURY = "MELEE", PROT = "TANK" },
    PALADIN     = { HOLY = "HEALER", PROT = "TANK", RET = "MELEE" },
    HUNTER      = { BM = "RANGED", MM = "RANGED", SURV = "RANGED" },
    ROGUE       = { ASSA = "MELEE", COMBAT = "MELEE", SUB = "MELEE" },
    PRIEST      = { DISC = "HEALER", HOLY = "HEALER", SHADOW = "CASTER" },
    DEATHKNIGHT = {
        BLOOD = "MELEE_MAGIC", FROST = "MELEE_MAGIC", UNHOLY = "MELEE_MAGIC",
        BLOOD_TANK = "TANK", FROST_TANK = "TANK", UNHOLY_TANK = "TANK",
    },
    SHAMAN      = { ELEM = "CASTER", ENH = "MELEE_MAGIC", RESTO = "HEALER" },
    MAGE        = { ARCANE = "CASTER", FIRE = "CASTER", FROST = "CASTER" },
    WARLOCK     = { AFFLI = "CASTER", DEMO = "CASTER", DESTRO = "CASTER" },
    DRUID       = { BALANCE = "CASTER", FERAL = "MELEE", GUARDIAN = "TANK", RESTO = "HEALER" },
    DEMONHUNTER = { HAVOC = "MELEE", VENGE = "TANK", POSSESS = "MELEE" },
}

local CAPS = {
    WARRIOR = {
        ARMS = {
            [4] = { "HIT", "EXP", "CRIT", "ARP" },
            [5] = { "HIT", "EXP", "ARP", "CRIT", "STR" },
            [6] = { "HIT", "EXP", "ARP", "CRIT", "STR" },
        },
        FURY = {
            [5] = { "HIT", "HASTE" },
            [6] = { "HIT", "EXP", "ARP", "CRIT", "STR" },
        },
        PROT = {
            [5] = { "DEF", "HIT", "EXP", "BLOCK", "ARMOR" },
        },
    },

    DEATHKNIGHT = {
        BLOOD = {
            [4] = { "HIT", "EXP", "STR" },
            [5] = { "EXP", "HIT", "CRIT" },
            [6] = { "EXP", "HIT", "CRIT", "STR" },
        },
        FROST = {
            [4] = { "HIT", "EXP", "STR", "ARP" },
            [5] = { "HIT", "EXP", "ARP", "HASTE", "STR" },
        },
        UNHOLY = {
            [4] = { "HIT", "EXP", "HASTE", "STR" },
            [5] = { "HIT", "CRIT", "STR" },
            [6] = { "HIT", "EXP", "CRIT", "HASTE" },
            [7] = { "HIT", "EXP", "STR" },
        },
        BLOOD_TANK = {
            [4] = { "DEF", "HIT", "EXP", "STA" },
            [7] = { "DEF", "HIT", "EXP" },
            [8] = { "DEF", "HIT", "EXP" },
            [9] = { "DEF", "HIT", "EXP" },
        },
        FROST_TANK = {
            [4] = { "DEF", "HIT", "EXP", "STA" },
            [5] = { "DEF", "HIT", "EXP", "STA" },
            [6] = { "DEF", "HIT", "EXP", "STA" },
            [7] = { "DEF", "HIT", "EXP" },
            [8] = { "DEF", "HIT", "EXP" },
            [9] = { "DEF", "HIT", "EXP" },
        },
        UNHOLY_TANK = {
            [4] = { "DEF", "HIT", "EXP", "STA" },
            [7] = { "DEF", "HIT", "EXP" },
            [8] = { "DEF", "HIT", "EXP" },
            [9] = { "DEF", "HIT", "EXP" },
        },
    },

    DRUID = {
        FERAL = {
            [4] = { "HIT", "EXP", "CRIT", "ARP" },
            [5] = { "HIT", "EXP", "CRIT", "ARP", "STR" },
        },
        GUARDIAN = {
            [5] = { "HIT", "EXP", "STA", "ARMOR" },
            [6] = { "HIT", "EXP", "STA", "ARMOR" },
        },
        BALANCE = {
            [4] = { "HIT", "SPELLHASTE", "SP" },
            [5] = { "HIT", "SPELLCRIT", "SP" },
            [6] = { "HIT", "SPELLCRIT", "SP", "SPI" },
        },
        RESTO = {
            [5] = { "SPELLHASTE", "HEAL", "SPI" },
            [6] = { "SPELLHASTE", "SPELLCRIT", "HEAL" },
        },
    },

    PALADIN = {
        PROT = {
            [4] = { "DEF", "STA", "HIT", "EXP" },
        },
        RET = {
            [4] = { "HIT", "EXP", "STR", "CRIT" },
            [5] = { "HIT", "EXP", "STR", "CRIT" },
            [6] = { "HIT", "EXP", "STR", "CRIT" },
            [9] = { "HIT", "EXP", "HASTE", "STR" },
        },
        HOLY = {
            [6] = { "INT", "SPELLCRIT", "SPELLHASTE", "HEAL" },
            [8] = { "INT", "SPELLHASTE" },
            [9] = { "INT", "SPELLHASTE" },
        },
    },

    PRIEST = {
        SHADOW = {
            [4] = { "HIT", "SP", "SPELLCRIT", "SPELLHASTE" },
            [5] = { "HIT", "SPELLHASTE", "SP" },
            [6] = { "HIT", "SPELLHASTE", "SP", "SPI" },
        },
        HOLY = {
            [4] = { "SPELLHASTE", "SPI", "INT" },
        },
        DISC = {
            [4] = { "SPELLHASTE", "INT", "HEAL" },
            [5] = { "INT", "HEAL", "SPELLHASTE" },
            [6] = { "INT", "HEAL", "SPELLHASTE" },
        },
    },

    SHAMAN = {
        ELEM = {
            [5] = { "HIT", "SP", "SPELLHASTE", "SPELLCRIT" },
            [6] = { "HIT", "SP", "SPELLHASTE" },
        },
        ENH = {
            [4] = { "HIT", "EXP", "AP" },
            [5] = { "EXP", "HIT", "AP", "HASTE" },
            [6] = { "EXP", "HIT", "AP", "HASTE" },
        },
    },

    MAGE = {
        ARCANE = {
            [4] = { "HIT", "SPELLHASTE", "SP", "INT" },
            [5] = { "HIT", "SPELLHASTE", "SP", "SPELLCRIT" },
            [6] = { "HIT", "SPELLHASTE", "INT", "SP" },
        },
        FIRE = {
            [4] = { "HIT", "SPELLCRIT", "SPELLHASTE", "SP" },
            [5] = { "HIT", "SPELLCRIT", "SPELLHASTE", "SP", "SPI" },
            [6] = { "HIT", "SPI", "SPELLCRIT", "SPELLHASTE" },
        },
        FROST = {
            [4] = { "HIT", "SPELLHASTE", "SP" },
            [5] = { "HIT", "SPELLHASTE", "SP", "SPELLCRIT" },
            [6] = { "HIT", "SPELLHASTE", "SPI", "SP" },
        },
    },

    WARLOCK = {
        DEMO = {
            [4] = { "HIT", "SPELLHASTE", "SP" },
            [5] = { "HIT", "SPELLHASTE", "SP" },
            [6] = { "HIT", "SPELLHASTE", "SP", "SPI" },
        },
        AFFLI = {
            [4] = { "HIT", "SP" },
            [5] = { "HIT", "SP" },
            [6] = { "HIT", "SP" },
        },
        DESTRO = {
            [4] = { "HIT", "SP" },
            [5] = { "HIT", "SPELLHASTE", "SPELLCRIT", "SP" },
            [6] = { "HIT", "SPELLHASTE", "SPI" },
            [9] = { "HIT", "SP" },
            [10] = { "HIT", "SP" },
        },
    },

    ROGUE = {
        ASSA = {
            [4] = { "EXP", "HIT" },
            [6] = { "EXP", "HIT", "AP", "CRIT", "HASTE" },
        },
        COMBAT = {
            [4] = { "HIT", "EXP", "AGI", "HASTE", "CRIT" },
            [6] = { "EXP", "HIT", "ARP", "CRIT", "AP" },
        },
        SUB = {
            [4] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [5] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [6] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [7] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [8] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [9] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
            [10] = { "HIT", "EXP", "AGI", "STR", "AP", "ARP" },
        },
    },

    HUNTER = {
        MM = {
            [4] = { "HIT", "ARP", "CRIT" },
            [5] = { "HIT", "ARP", "CRIT", "AP" },
        },
        SURV = {
            [5] = { "HIT", "CRIT", "HASTE" },
            [6] = { "HIT", "AGI", "CRIT", "AP", "ARP" },
        },
        BM = {
            [5] = { "HIT", "ARP", "HASTE", "AP" },
            [6] = { "HIT", "ARP", "HASTE", "AP" },
        },
    },
}

local tierByItem

local function BuildTierIndex()
    if tierByItem then return tierByItem end
    tierByItem = {}
    local data = _G.EJ_ITEMSET_DATA
    if type(data) ~= "table" then return tierByItem end
    for _, set in pairs(data) do
        if type(set) == "table" then
            local tierName, isPVP, itemList = set[3], set[7], set[8]
            if type(tierName) == "string" and type(itemList) == "table"
               and (not isPVP or isPVP == 0) then
                local n = tonumber(tierName:match("^Т(%d+)"))
                if n then
                    for i = 1, #itemList do
                        tierByItem[itemList[i]] = n
                    end
                end
            end
        end
    end
    return tierByItem
end

local TIER_SLOTS = { 1, 3, 5, 7, 10 }

function StatPriority:DetectTier()
    local override = NS.db and NS.db.tierOverride
    if override then return override, nil end

    local index = BuildTierIndex()
    local counts = {}
    local best, bestCount

    for i = 1, #TIER_SLOTS do
        local link = GetInventoryItemLink("player", TIER_SLOTS[i])
        if link then
            local itemId = tonumber(link:match("item:(%d+)"))
            local tier = itemId and index[itemId]
            if tier then
                counts[tier] = (counts[tier] or 0) + 1
                if not bestCount or counts[tier] > bestCount
                   or (counts[tier] == bestCount and tier > best) then
                    best, bestCount = tier, counts[tier]
                end
            end
        end
    end

    if bestCount and bestCount >= 2 then return best, bestCount end
    return nil, 0
end

local function IsTankBuild()
    if GetCombatRating and CR_DEFENSE_SKILL then
        local ok, rating = pcall(GetCombatRating, CR_DEFENSE_SKILL)
        if ok and (rating or 0) >= 100 then return true end
    end
    if GetNumShapeshiftForms and GetShapeshiftFormInfo then
        local ok, num = pcall(GetNumShapeshiftForms)
        if ok and num then
            for i = 1, num do
                local texture, _, isActive = GetShapeshiftFormInfo(i)
                if isActive and texture and texture:lower():find("bearform") then
                    return true
                end
            end
        end
    end
    return false
end

function StatPriority:DetectSpec()
    local _, class = UnitClass("player")
    local specs = class and SPEC_BY_TAB[class]
    if not specs then return nil, nil, class end

    local tab
    if C_Talent and C_Talent.GetCurrentSpecTabIndex then
        local ok, idx = pcall(C_Talent.GetCurrentSpecTabIndex)
        if ok and type(idx) == "number" and idx >= 1 and idx <= 3 then
            tab = idx
        end
    end
    if not tab then
        local best = -1
        for i = 1, (GetNumTalentTabs and GetNumTalentTabs() or 3) do
            local _, _, points = GetTalentTabInfo(i)
            if points and points > best then best, tab = points, i end
        end
    end
    if not tab then return nil, nil, class end

    local spec = specs[tab]
    local variants = TANK_VARIANT[class]
    if spec and variants and variants[spec] and IsTankBuild() then
        spec = variants[spec]
    end
    return spec, tab, class
end

function StatPriority:Get()
    local spec, tab, class = self:DetectSpec()
    local tier, pieces = self:DetectTier()

    local info = {
        class = class,
        spec = spec,
        tier = tier,
        pieces = pieces,
        specName = spec and LSpec[SPEC_NAME[spec]],
        tab = tab,
        source = "role",
    }

    if not info.specName and tab then
        local ok, name = pcall(GetTalentTabInfo, tab)
        if ok and name then info.specName = name end
    end

    local role = class and ROLE_OF[class] and ROLE_OF[class][spec]
    info.role = role
    info.roleName = role and LSpec[ROLE_NAME[role]]

    local list
    if class and spec and tier and CAPS[class] and CAPS[class][spec] then
        list = CAPS[class][spec][tier]
        if list then info.source = "guide" end
    end
    if not list then
        list = role and ROLE_CAPS[role]
    end

    local set = {}
    if list then
        for i = 1, #list do set[list[i]] = true end
    end
    return set, info
end

local function Resolved(self, info)
    if info then return info end
    local _, detected = self:Get()
    return detected
end

function StatPriority:GetTierLabel(info)
    info = Resolved(self, info)
    if not info.tier then return L["нет"] end
    local text = L["Т"] .. info.tier
    if not (NS.db and NS.db.tierOverride) and info.pieces and info.pieces > 0 then
        text = text .. " x" .. info.pieces
    end
    return text
end

function StatPriority:GetSourceLabel(info)
    info = Resolved(self, info)
    local text
    if info.source == "guide" then
        text = L["капы по гайду"]
    elseif info.roleName then
        text = L["базовые капы роли: "] .. info.roleName
    else
        text = L["капы не определены"]
    end
    if NS.db and NS.db.tierOverride then
        text = text .. L[", набор задан вручную"]
    end
    return text
end

function StatPriority:Print()
    local set, info = self:Get()
    NS.Print(L["приоритет характеристик"])
    NS.Print(L["  класс: "] .. tostring(info.class) ..
             L[", спек: "] .. tostring(info.spec) .. " (" .. tostring(info.specName) .. ")" ..
             L[", роль: "] .. tostring(info.roleName))
    NS.Print(L["  набор: "] .. (info.tier and (L["Т"] .. info.tier) or L["не определён"]) ..
             (info.pieces and info.pieces > 0 and (L[", кусков: "] .. info.pieces) or "") ..
             (NS.db and NS.db.tierOverride and L[" (задан вручную)"] or ""))
    NS.Print(L["  источник: "] .. (info.source == "guide" and L["гайд"] or L["базовые капы роли"]))
    local keys = {}
    for k in pairs(set) do keys[#keys + 1] = k end
    table.sort(keys)
    NS.Print(L["  помечено: "] .. (#keys > 0 and table.concat(keys, ", ") or L["ничего"]))
    local n = 0
    for _ in pairs(BuildTierIndex()) do n = n + 1 end
    NS.Print(L["  предметов в справочнике комплектов: "] .. n)
end

function StatPriority:Tiers()
    local seen, list = {}, {}
    for _, tier in pairs(BuildTierIndex()) do
        if not seen[tier] then
            seen[tier] = true
            list[#list + 1] = tier
        end
    end
    table.sort(list)
    return list
end

function StatPriority:SetTierOverride(value)
    if not NS.db then return end
    if value then
        NS.db.tierOverride = value
        NS.Print(L["набор зафиксирован: Т"] .. value)
    else
        NS.db.tierOverride = nil
        NS.Print(L["набор снова определяется автоматически"])
    end
    if NS.StatsPanel and NS.StatsPanel.frame and NS.StatsPanel.frame:IsShown() then
        NS.StatsPanel:Update()
    end
end

NS.StatPriority = StatPriority
