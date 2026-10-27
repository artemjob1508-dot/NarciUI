local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc
local L = NS.L

local DEFAULTS = {
    locale = "auto",
    keep = 10,
    pruneDays = 30,
    tooltip = true,
    showQuantity = true,
    showAuctionator = true,
    autoScan = true,
    autoScanInterval = 30,
    window = true,
    range = "day",
}

local function InitDB()
    if not NarcissusSirusAucDB then
        NarcissusSirusAucDB = type(_G.AucBourseDB) == "table" and _G.AucBourseDB or {}
    end
    for k, v in pairs(DEFAULTS) do
        if NarcissusSirusAucDB[k] == nil then
            NarcissusSirusAucDB[k] = v
        end
    end
end

local function StandaloneLoaded()
    return IsAddOnLoaded and IsAddOnLoaded("AucBourse") and true or false
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        NS.db = NarcissusSirusAucDB
        NS.ApplyLocale(NarcissusSirusAucDB.locale)
        NS.standalone = StandaloneLoaded()
        NS.initialized = not NS.standalone and NarcissusSirusAucDB.enabled ~= false
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if NS.initialized then
            NS:OnPlayerLogin()
        elseif NS.standalone then
            NS.Print(L["AucBourse теперь встроен в NarciUI. История перенесена, отключите отдельный AucBourse в списке модификаций и перезапустите клиент."])
        end
    end
end)

SLASH_AUCBOURSE1 = "/auc"
SLASH_AUCBOURSE2 = "/aucbourse"
SlashCmdList["AUCBOURSE"] = function(msg)
    msg = strtrim(msg or ""):lower()
    local command, argument = msg:match("^(%S*)%s*(.-)$")

    if not NS.initialized then
        NS.Print(L["AucBourse теперь встроен в NarciUI. История перенесена, отключите отдельный AucBourse в списке модификаций и перезапустите клиент."])
        return
    end

    if not NS.History then
        NS.Print(L["модуль истории не загрузился, проверьте ошибки Lua"])
        return
    end

    if command == "scan" then
        if NS.Scanner then NS.Scanner:Start() end
    elseif command == "debug" then
        if NS.Scanner then NS.Scanner:Debug() end
    elseif command == "keep" then
        local n = tonumber(argument)
        if n and n >= 2 and n <= 30 then
            NS.History:Resize(floor(n))
            NS.db.keep = floor(n)
            NS.Print(format(L["Глубина истории: %d сканов"], floor(n)))
        else
            NS.Print(L["Укажите число от 2 до 30"])
        end
    elseif command == "days" then
        local n = tonumber(argument)
        if n and n >= 1 and n <= 365 then
            NS.db.pruneDays = floor(n)
            local removed = NS.History:Prune()
            NS.Print(format(L["Срок хранения: %d дней"], floor(n)))
            NS.Print(format(L["Удалено предметов: %d"], removed))
        else
            NS.Print(L["Укажите число от 1 до 365"])
        end
    elseif command == "tooltip" then
        NS.db.tooltip = not NS.db.tooltip
        NS.Print(NS.db.tooltip and L["Подсказки включены"] or L["Подсказки выключены"])
    elseif command == "window" then
        NS.db.window = not NS.db.window
        NS.Print(NS.db.window and L["Окно включено"] or L["Окно выключено"])
        if NS.Window then
            if NS.db.window then NS.Window:Show() else NS.Window:Hide() end
        end
    elseif command == "auto" then
        NS.db.autoScan = not NS.db.autoScan
        NS.Print(NS.db.autoScan and L["Автоскан включён"] or L["Автоскан выключен"])
    elseif command == "clear" then
        NS.History:Clear()
        NS.Print(L["История очищена"])
    elseif command == "help" then
        NS.Print(L["Команды:"])
        NS.Print(L["/auc — состояние"])
        NS.Print(L["/auc scan — полный скан аукциона"])
        NS.Print(L["/auc keep <n> — сколько сканов хранить"])
        NS.Print(L["/auc days <n> — через сколько дней забывать предмет"])
        NS.Print(L["/auc window — окно у аукциона вкл/выкл"])
        NS.Print(L["/auc tooltip — подсказки вкл/выкл"])
        NS.Print(L["/auc auto — автоскан вкл/выкл"])
        NS.Print(L["/auc clear — стереть историю"])
    else
        local scans, items, last = NS.History:Summary()
        NS.Print(format(L["сканов: %d, предметов: %d, последний скан: %s"],
            scans, items, NS.TimeAgo(last)))
    end
end
