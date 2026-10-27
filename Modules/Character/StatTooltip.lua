local addonName, NS = ...
local L = NS.L
local StatTooltip = {}
local format = string.format
local floor = math.floor

local HIGHLIGHT = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff"
local CLOSE = FONT_COLOR_CODE_CLOSE or "|r"

local proxy

local function Proxy()
    if proxy then return proxy end
    local f = CreateFrame("Frame", "NarcissusSirus_StatProxy", UIParent)
    f:SetWidth(1)
    f:SetHeight(1)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    f:CreateFontString("NarcissusSirus_StatProxyLabel", "BACKGROUND", "GameFontNormal")
    f:CreateFontString("NarcissusSirus_StatProxyStatText", "BACKGROUND", "GameFontNormal")
    f:Hide()
    proxy = f
    return f
end

local function FromPaperDoll(fn, arg)
    if type(fn) ~= "function" then return nil end
    local f = Proxy()
    f.tooltip, f.tooltip2 = nil, nil
    local ok = pcall(fn, f, arg)
    f:Hide()
    if not ok then return nil end
    return f.tooltip, f.tooltip2
end

local function Titled(name, value)
    return HIGHLIGHT .. name .. " " .. tostring(value) .. CLOSE
end

local function ManaRegenBody()
    if not UnitHasMana("player") then return nil end
    local base, casting = GetManaRegen()
    return format(MANA_REGEN_TOOLTIP, floor((base or 0) * 5), floor((casting or 0) * 5))
end

local BUILDERS = {}

local function PaperDollBuilder(id, fnName, arg)
    BUILDERS[id] = function()
        return FromPaperDoll(_G[fnName], arg)
    end
end

PaperDollBuilder("STR", "PaperDollFrame_SetStat", 1)
PaperDollBuilder("AGI", "PaperDollFrame_SetStat", 2)
PaperDollBuilder("STA", "PaperDollFrame_SetStat", 3)
PaperDollBuilder("INT", "PaperDollFrame_SetStat", 4)
PaperDollBuilder("SPI", "PaperDollFrame_SetStat", 5)
PaperDollBuilder("ARMOR", "PaperDollFrame_SetArmor")
PaperDollBuilder("ATTACKSPEED", "PaperDollFrame_SetAttackSpeed")
PaperDollBuilder("DODGE", "PaperDollFrame_SetDodge")
PaperDollBuilder("PARRY", "PaperDollFrame_SetParry")
PaperDollBuilder("BLOCK", "PaperDollFrame_SetBlock")
PaperDollBuilder("AP", "PaperDollFrame_SetAttackPower")
PaperDollBuilder("CRIT", "PaperDollFrame_SetMeleeCritChance")
PaperDollBuilder("HIT", "PaperDollFrame_SetRating", CR_HIT_MELEE)
PaperDollBuilder("EXP", "PaperDollFrame_SetExpertise")
PaperDollBuilder("DEF", "PaperDollFrame_SetDefense")
PaperDollBuilder("RESIL", "PaperDollFrame_SetResilience")
PaperDollBuilder("SPELLHASTE", "PaperDollFrame_SetSpellHaste")
PaperDollBuilder("HEAL", "PaperDollFrame_SetSpellBonusHealing")

BUILDERS.HEALTH = function()
    local cur = UnitHealth("player") or 0
    local maxHealth = UnitHealthMax("player") or 0
    return Titled(HEALTH, maxHealth), format(L["Сейчас: %d. Восполнение вне боя: %d в секунду."],
        cur, GetUnitHealthRegenRateFromSpirit and floor(GetUnitHealthRegenRateFromSpirit("player") or 0) or 0)
end

BUILDERS.POWER = function()
    local _, token = UnitPowerType("player")
    local name = (token and _G[token]) or MANA
    local title = Titled(name, UnitPowerMax("player") or 0)
    return title, ManaRegenBody() or L["Основной ресурс класса."]
end

BUILDERS.MANAREGEN = function()
    if not UnitHasMana("player") then
        return Titled(MANA_REGEN, NOT_APPLICABLE or "-"), nil
    end
    local base = select(1, GetManaRegen()) or 0
    return Titled(MANA_REGEN, floor(base * 5)), ManaRegenBody()
end

BUILDERS.MANAREGENCASTING = function()
    if not UnitHasMana("player") then
        return Titled(L["Восп. маны в бою"], NOT_APPLICABLE or "-"), nil
    end
    local casting = select(2, GetManaRegen()) or 0
    return Titled(L["Восп. маны в бою"], floor(casting * 5)), ManaRegenBody()
end

BUILDERS.ARP = function()
    local percent = GetArmorPenetration() or 0
    return Titled(L["Пробивание брони"], format("%.2f%%", percent)),
        format(L["Рейтинг: %d. Атаки игнорируют %.2f%% брони цели."],
            GetCombatRating(CR_ARMOR_PENETRATION) or 0, percent)
end

BUILDERS.ARPRATING = function()
    local percent = GetArmorPenetration() or 0
    return Titled(L["Рейтинг пробивания брони"], GetCombatRating(CR_ARMOR_PENETRATION) or 0),
        format(L["Атаки игнорируют %.2f%% брони цели."], percent)
end

BUILDERS.SPELLCRIT = function()
    local lines = {}
    for i = 2, MAX_SPELL_SCHOOLS do
        lines[#lines + 1] = { _G["DAMAGE_SCHOOL" .. i], format("%.2f%%", GetSpellCritChance(i) or 0) }
    end
    local title = Titled(COMBAT_RATING_NAME11 or SPELL_CRIT_CHANCE, GetCombatRating(CR_CRIT_SPELL) or 0)
    return title, nil, lines
end

BUILDERS.SP = function()
    local lines = {}
    for i = 2, MAX_SPELL_SCHOOLS do
        lines[#lines + 1] = { _G["DAMAGE_SCHOOL" .. i], GetSpellBonusDamage(i) or 0 }
    end
    local maxDamage = 0
    for i = 1, #lines do
        if lines[i][2] > maxDamage then maxDamage = lines[i][2] end
    end
    return Titled(BONUS_DAMAGE, maxDamage), nil, lines
end

function StatTooltip:Show(owner, id)
    if not owner or not id then return end
    if NS.db and NS.db.statTips == false then return end
    local builder = BUILDERS[id]
    if not builder then return end
    local ok, title, body, lines = pcall(builder)
    if not ok or not title then return end

    local anchor = NS.db and NS.db.statTipAnchor
    GameTooltip:SetOwner(owner, anchor == "right" and "ANCHOR_RIGHT" or (anchor == "cursor" and "ANCHOR_CURSOR" or "ANCHOR_LEFT"))
    GameTooltip:SetText(title)
    local c = NORMAL_FONT_COLOR
    if body then
        GameTooltip:AddLine(body, c.r, c.g, c.b, 1)
    end
    if lines then
        for i = 1, #lines do
            GameTooltip:AddDoubleLine(lines[i][1], lines[i][2], c.r, c.g, c.b, c.r, c.g, c.b)
        end
    end
    GameTooltip:Show()
end

function StatTooltip:Hide()
    GameTooltip:Hide()
end

NS.StatTooltip = StatTooltip
