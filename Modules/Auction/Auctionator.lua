local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc

local Bridge = {}

function Bridge:IsAvailable()
    return type(AUCTIONATOR_PRICE_DATABASE) == "table"
end

function Bridge:Stats(key)
    if not key or not self:IsAvailable() then return nil end

    local entry = AUCTIONATOR_PRICE_DATABASE[key]
    if type(entry) ~= "table" or type(entry.h) ~= "table" then return nil end

    local minPrice, maxPrice
    local oldestDay, newestDay

    for day, high in pairs(entry.h) do
        local low = (entry.l and entry.l[day]) or high
        if not minPrice or low < minPrice then minPrice = low end
        if not maxPrice or high > maxPrice then maxPrice = high end
        if not oldestDay or day < oldestDay then oldestDay = day end
        if not newestDay or day > newestDay then newestDay = day end
    end

    if not minPrice then return nil end

    return {
        span = (newestDay - oldestDay) + 1,
        min = minPrice,
        max = maxPrice,
    }
end

NS.AuctionatorBridge = Bridge
