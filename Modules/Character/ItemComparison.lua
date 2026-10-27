local addonName, NS = ...
local L = NS.L

local ItemComparison = {}

local format = string.format
local abs = math.abs
local pairs = pairs
local ipairs = ipairs

local COMPARE_STATS = {
    { key = "strength",  label = "STR", color = "|cffff4444" },
    { key = "agility",   label = "AGI", color = "|cff44ff44" },
    { key = "stamina",   label = "STA", color = "|cffffff44" },
    { key = "intellect", label = "INT", color = "|cff4488ff" },
    { key = "spirit",    label = "SPI", color = "|cffff88ff" },
    { key = "hit",       label = "Hit", color = "|cffffffff" },
    { key = "crit",      label = "Crit", color = "|cffff8800" },
    { key = "haste",     label = "Haste", color = "|cffff4444" },
    { key = "attackPower", label = "AP", color = "|cffffcc00" },
    { key = "spellPower", label = "SP", color = "|cff8844ff" },
    { key = "defense",   label = "Def", color = "|cff888888" },
    { key = "dodge",     label = "Dodge", color = "|cff44ffcc" },
    { key = "parry",     label = "Parry", color = "|cff44ccff" },
    { key = "armor",     label = "Armor", color = "|cffcccccc" },
}

local SLOT_NAME_TO_ID = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_NECK"] = 2,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HAND"] = 10,
    ["INVTYPE_FINGER"] = {11, 12},
    ["INVTYPE_TRINKET"] = {13, 14},
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_WEAPON"] = {16, 17},
    ["INVTYPE_2HWEAPON"] = 16,
    ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17,
    ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_THROWN"] = 18,
}

function ItemComparison:Init()
    if self.initialized then return end

    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        self:OnTooltipSetItem(tooltip)
    end)

    self.initialized = true
end

local function Options()
    if not NS.db then return {} end
    if type(NS.db.compare) ~= "table" then NS.db.compare = {} end
    return NS.db.compare
end

function ItemComparison:OnTooltipSetItem(tooltip)
    if not self.enabled then return end
    local opts = Options()
    if opts.shift and not IsShiftKeyDown() then return end

    local name, link = tooltip:GetItem()
    if not link then return end

    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
    if not equipLoc or equipLoc == "" then return end

    local slotId = SLOT_NAME_TO_ID[equipLoc]
    if not slotId then return end

    local newStats = NS.TooltipScanner:GetItemStats(link)

    local slots = type(slotId) == "table" and slotId or {slotId}
    for _, slot in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slot)
        if equippedLink and equippedLink ~= link then
            local equippedStats = NS.TooltipScanner:GetItemStats(equippedLink)

            local diffs = {}
            local hasDiff = false
            for _, stat in ipairs(COMPARE_STATS) do
                local oldVal = equippedStats[stat.key] or 0
                local newVal = newStats[stat.key] or 0
                local diff = newVal - oldVal
                if diff ~= 0 then
                    hasDiff = true
                    table.insert(diffs, {
                        label = stat.label,
                        diff = diff,
                        color = stat.color,
                    })
                end
            end

            if hasDiff then
                tooltip:AddLine(" ")
                local equippedName = GetItemInfo(equippedLink) or "Equipped"
                tooltip:AddLine(L["В сравнении с: "] .. equippedName, 0.6, 0.6, 0.8)

                for _, d in ipairs(diffs) do
                    local sign = d.diff > 0 and "+" or ""
                    local colorStr
                    if d.diff > 0 then
                        colorStr = "|cff44ff44"
                    else
                        colorStr = "|cffff4444"
                    end
                    tooltip:AddLine(format("  %s%s%s%s: %s%d|r", opts.plainNames and "" or d.color, d.label, opts.plainNames and " " or "|r ", colorStr, sign, d.diff))
                end

                local newEnchant = opts.enchants ~= false and NS.GetEnchantInfo(link)
                local equippedEnchant = opts.enchants ~= false and NS.GetEnchantInfo(equippedLink)
                if newEnchant or equippedEnchant then
                    tooltip:AddLine(" ")
                    if newEnchant and not equippedEnchant then
                        tooltip:AddLine(L["  |cff44ff44Есть чары:|r "] .. newEnchant.name)
                    elseif not newEnchant and equippedEnchant then
                        tooltip:AddLine(L["  |cffff4444Без чар|r (у надетого: "] .. equippedEnchant.name .. ")")
                    end
                end

                local newEmpty = opts.sockets ~= false and NS.TooltipScanner:GetEmptySocketCount(link) or 0
                if newEmpty > 0 then
                    tooltip:AddLine(format(L["  |cffff8800Пустых разъёмов: %d|r"], newEmpty))
                end

                tooltip:Show()
            end
            if not opts.both then break end
        end
    end
end

function ItemComparison:Enable()
    if not self.initialized then self:Init() end
    self.enabled = true
end

function ItemComparison:Disable()
    self.enabled = false
end

NS.ItemComparison = ItemComparison
