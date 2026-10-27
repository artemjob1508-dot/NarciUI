local addonName, NS = ...
local L = NS.L

local Util = {}
NS.Utilities = Util

local function Settings()
    if not NS.db then return end
    if type(NS.db.utilities) ~= "table" then NS.db.utilities = {} end
    local db = NS.db.utilities
    db.repair = db.repair or "off"
    if db.repairReport == nil then db.repairReport = true end
    if db.sellJunk == nil then db.sellJunk = false end
    db.errors = db.errors or "show"
    db.interrupt = db.interrupt or "off"
    db.interruptText = db.interruptText or ""
    if db.interruptPet == nil then db.interruptPet = true end
    if db.autoRelease == nil then db.autoRelease = false end
    if db.screenshotAchievement == nil then db.screenshotAchievement = false end
    return db
end

Util.Settings = Settings

local function Money(copper)
    if GetMoneyString then return GetMoneyString(copper) end
    return tostring(math.floor(copper / 10000)) .. L["з"]
end

function Util:Repair()
    local db = Settings()
    if not db or db.repair == "off" or not CanMerchantRepair or not CanMerchantRepair() then return end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then return end

    if db.repair == "guild" and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
        local limit = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
        local bank = GetGuildBankMoney and GetGuildBankMoney() or 0
        if (limit == -1 or limit >= cost) and (bank == 0 or bank >= cost) then
            RepairAllItems(1)
            NS.After(0.5, function()
                local left = GetRepairAllCost()
                if left and left > 0 then
                    if GetMoney() >= left then
                        RepairAllItems()
                        if db.repairReport then NS.Print(L["Ремонт за свой счёт"] .. ": " .. Money(left)) end
                    end
                elseif db.repairReport then
                    NS.Print(L["Ремонт за счёт гильдии"] .. ": " .. Money(cost))
                end
            end)
            return
        end
    end

    if GetMoney() >= cost then
        RepairAllItems()
        if db.repairReport then NS.Print(L["Ремонт за свой счёт"] .. ": " .. Money(cost)) end
    elseif db.repairReport then
        NS.Print(L["Не хватает денег на ремонт"] .. ": " .. Money(cost))
    end
end

local SPAM_ERRORS = {
    "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN", "ERR_ITEM_COOLDOWN", "ERR_OUT_OF_RAGE", "ERR_OUT_OF_ENERGY",
    "ERR_OUT_OF_FOCUS", "ERR_OUT_OF_RUNIC_POWER", "ERR_OUT_OF_MANA", "ERR_NO_ATTACK_TARGET", "SPELL_FAILED_NO_COMBO_POINTS",
    "ERR_GENERIC_NO_TARGET", "SPELL_FAILED_TARGETS_DEAD", "SPELL_FAILED_SPELL_IN_PROGRESS", "ERR_OUT_OF_RANGE",
    "SPELL_FAILED_UNIT_NOT_INFRONT", "ERR_BADATTACKFACING", "ERR_BADATTACKPOS", "SPELL_FAILED_MOVING",
    "SPELL_FAILED_NOT_READY", "ERR_SPELL_OUT_OF_RANGE", "SPELL_FAILED_OUT_OF_RANGE", "SPELL_FAILED_LINE_OF_SIGHT",
}

local spamSet

local function IsSpam(message)
    if not spamSet then
        spamSet = {}
        for _, key in ipairs(SPAM_ERRORS) do
            local text = _G[key]
            if type(text) == "string" then spamSet[text] = true end
        end
    end
    return spamSet[message]
end

local errorGate = CreateFrame("Frame")

errorGate:SetScript("OnEvent", function(_, event, ...)
    local db = Settings()
    local frame = _G.UIErrorsFrame
    if not frame or not db then return end
    local mode = db.errors
    local message
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "string" then message = value break end
    end
    if mode == "combat" and InCombatLockdown() then return end
    if mode == "spam" and message and IsSpam(message) then return end
    if mode == "spamcombat" and InCombatLockdown() and message and IsSpam(message) then return end
    if mode == "all" then return end
    local handler = frame:GetScript("OnEvent")
    if handler then pcall(handler, frame, event, ...) end
end)

function Util:ApplyErrors()
    local db = Settings()
    local frame = _G.UIErrorsFrame
    if not frame or not db then return end
    if db.errors == "show" then
        errorGate:UnregisterEvent("UI_ERROR_MESSAGE")
        frame:RegisterEvent("UI_ERROR_MESSAGE")
    else
        frame:UnregisterEvent("UI_ERROR_MESSAGE")
        errorGate:RegisterEvent("UI_ERROR_MESSAGE")
    end
end

local function InterruptChannel(mode)
    if mode == "say" then return "SAY" end
    if mode == "yell" then return "YELL" end
    if mode == "auto" or mode == "group" then
        if GetNumRaidMembers and GetNumRaidMembers() > 0 then
            local _, kind = IsInInstance()
            if kind == "pvp" then return "BATTLEGROUND" end
            return "RAID"
        end
        if GetNumPartyMembers and GetNumPartyMembers() > 0 then return "PARTY" end
        if mode == "auto" then return "SAY" end
        return
    end
    return
end

function Util:Interrupt(target, spell, link)
    local db = Settings()
    if not db or db.interrupt == "off" then return end
    local template = db.interruptText ~= "" and db.interruptText or L["Прервано: {spell} ({target})"]
    local text = template:gsub("{spell}", function() return link or spell or "?" end)
    text = text:gsub("{target}", function() return target or "?" end)
    if db.interrupt == "self" then
        NS.Print(text)
        return
    end
    local channel = InterruptChannel(db.interrupt)
    if channel then SendChatMessage(text, channel) end
end

local combat = CreateFrame("Frame")
combat:SetScript("OnEvent", function(_, _, _, subEvent, sourceGUID, _, _, _, destName, _, _, _, _, extraID, extraName)
    if subEvent ~= "SPELL_INTERRUPT" then return end
    local db = Settings()
    if not db or db.interrupt == "off" then return end
    local mine = sourceGUID == UnitGUID("player") or (db.interruptPet and sourceGUID == UnitGUID("pet"))
    if not mine then return end
    local link = extraID and GetSpellLink and GetSpellLink(extraID)
    Util:Interrupt(destName, extraName, link)
end)

function Util:ApplyInterrupt()
    local db = Settings()
    if db and db.interrupt ~= "off" then
        combat:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        combat:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function Util:Apply()
    self:ApplyErrors()
    self:ApplyInterrupt()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("MERCHANT_SHOW")
driver:RegisterEvent("PLAYER_DEAD")
driver:RegisterEvent("ACHIEVEMENT_EARNED")
driver:SetScript("OnEvent", function(_, event)
    local db = Settings()
    if not db then return end
    if event == "PLAYER_LOGIN" then
        Util:Apply()
    elseif event == "MERCHANT_SHOW" then
        Util:Repair()
        local bags = NS.Bags
        if db.sellJunk and bags and bags.SellJunk and not bags.running then
            NS.After(0.4, function() bags:SellJunk(false) end)
        end
    elseif event == "PLAYER_DEAD" then
        if db.autoRelease then
            local _, kind = IsInInstance()
            if kind == "pvp" or (GetZonePVPInfo and select(1, GetZonePVPInfo()) == "combat") then
                NS.After(0.5, function()
                    if HasSoulstone and HasSoulstone() then return end
                    if UnitIsDead("player") and not UnitIsGhost("player") and RepopMe then RepopMe() end
                end)
            end
        end
    elseif event == "ACHIEVEMENT_EARNED" then
        if db.screenshotAchievement and Screenshot then
            NS.After(1, function() Screenshot() end)
        end
    end
end)
