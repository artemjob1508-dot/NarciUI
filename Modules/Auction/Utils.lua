local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc
local L = NS.L

local queue = {}
local driver

local function RunQueue()
    local now = GetTime()
    local i = 1
    while i <= #queue do
        local task = queue[i]
        if now >= task.at then
            table.remove(queue, i)
            local ok, err = pcall(task.fn)
            if not ok and geterrorhandler then
                geterrorhandler()(err)
            end
        else
            i = i + 1
        end
    end
    if #queue == 0 and driver then
        driver:Hide()
    end
end

function NS.After(delay, fn)
    if type(fn) ~= "function" then return end
    if not driver then
        driver = CreateFrame("Frame")
        driver:SetScript("OnUpdate", RunQueue)
    end
    queue[#queue + 1] = { at = GetTime() + (tonumber(delay) or 0), fn = fn }
    driver:Show()
end

function NS.Print(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring((select(i, ...)))
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff66c2a5AucBourse|r " .. table.concat(parts, " "))
end

function NS.Money(copper)
    if not copper or copper <= 0 then
        return L["нет данных"]
    end
    return GetMoneyString(copper)
end

local GOLD_CODE = "|cffffd700"
local SILVER_CODE = "|cffc7c7cf"
local COPPER_CODE = "|cffeda55f"

function NS.MoneyText(copper)
    if not copper or copper <= 0 then
        return "-"
    end

    local english = NS.localeKey ~= "ruRU"
    local goldMark = english and "g" or "з"
    local silverMark = english and "s" or "с"
    local copperMark = english and "c" or "м"

    copper = floor(copper)
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)
    local rest = copper % 100

    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = GOLD_CODE .. gold .. goldMark .. "|r"
    end
    if silver > 0 then
        parts[#parts + 1] = SILVER_CODE .. silver .. silverMark .. "|r"
    end
    if rest > 0 or #parts == 0 then
        parts[#parts + 1] = COPPER_CODE .. rest .. copperMark .. "|r"
    end

    return table.concat(parts, " ")
end

function NS.MoneyShort(copper)
    if not copper or copper <= 0 then
        return "-"
    end

    local english = NS.localeKey ~= "ruRU"
    local goldMark = english and "g" or "з"
    local silverMark = english and "s" or "с"
    local copperMark = english and "c" or "м"

    copper = floor(copper)
    local gold = floor(copper / 10000)
    local silver = floor((copper % 10000) / 100)

    if gold >= 100 then
        return gold .. goldMark
    elseif gold > 0 then
        return format("%d.%02d%s", gold, silver, goldMark)
    elseif silver > 0 then
        return silver .. silverMark
    end
    return (copper % 100) .. copperMark
end

function NS.DayStart(stamp)
    stamp = stamp or time()
    local parts = date("*t", stamp)
    return stamp - (parts.hour * 3600 + parts.min * 60 + parts.sec)
end

function NS.TimeAgo(stamp)
    if not stamp then
        return L["никогда"]
    end
    local diff = time() - stamp
    if diff < 90 then
        return L["только что"]
    elseif diff < 3600 then
        return format(L["%d мин назад"], floor(diff / 60))
    elseif diff < 86400 then
        return format(L["%d ч назад"], floor(diff / 3600))
    end
    return format(L["%d дн назад"], floor(diff / 86400))
end

function NS.Plural(count, one, few, many)
    local hundreds = count % 100
    if hundreds >= 11 and hundreds <= 14 then
        return many
    end
    local units = count % 10
    if units == 1 then
        return one
    elseif units >= 2 and units <= 4 then
        return few
    end
    return many
end

function NS.PhraseScans(count)
    if NS.localeKey == "ruRU" then
        return format("за %d %s", count, NS.Plural(count, "скан", "скана", "сканов"))
    end
    return format("over %d scan%s", count, count == 1 and "" or "s")
end

function NS.PhraseItems(count)
    if NS.localeKey == "ruRU" then
        return format("%d %s", count, NS.Plural(count, "предмет", "предмета", "предметов"))
    end
    return format("%d item%s", count, count == 1 and "" or "s")
end

function NS.ItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    local id = link:match("|Hitem:(%d+)")
    if not id then
        id = link:match("^item:(%d+)")
    end
    return tonumber(id)
end

NS.GEAR_ITEM_LEVEL_THRESHOLD = 168

function NS.KeysFromItem(link)
    local itemID = NS.ItemIDFromLink(link)
    if not itemID then return nil end
    local plain = tostring(itemID)
    local _, _, _, itemLevel, _, itemType = GetItemInfo(link)
    local isGear = (ITEM_CLASS_2 and itemType == ITEM_CLASS_2)
                or (ITEM_CLASS_4 and itemType == ITEM_CLASS_4)
    if isGear and itemLevel and itemLevel >= NS.GEAR_ITEM_LEVEL_THRESHOLD then
        return "g:" .. itemID .. ":" .. itemLevel, plain
    end
    return plain
end

function NS.KeysFromItemKey(itemKey)
    if not itemKey or not itemKey.itemID then return nil end
    local plain = tostring(itemKey.itemID)
    local itemLevel = itemKey.itemLevel or 0
    if itemLevel >= NS.GEAR_ITEM_LEVEL_THRESHOLD then
        return "g:" .. itemKey.itemID .. ":" .. itemLevel, plain
    end
    return plain
end
