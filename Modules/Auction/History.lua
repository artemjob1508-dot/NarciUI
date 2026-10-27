local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc

local History = {}

local DEFAULT_KEEP = 10

local function Root()
    local db = NS.db
    if not db.hist then
        db.hist = { keep = db.keep or DEFAULT_KEEP, head = 0, slots = {}, items = {} }
    end
    local hist = db.hist
    if not hist.keep or hist.keep < 2 then
        hist.keep = DEFAULT_KEEP
    end
    return hist
end

local orderScratch = {}

local function SlotOrder(hist)
    local order = orderScratch
    for index = #order, 1, -1 do
        order[index] = nil
    end
    local keep, head = hist.keep, hist.head
    if head == 0 then return order end
    for i = 1, keep do
        local index = ((head + i - 1) % keep) + 1
        if hist.slots[index] then
            order[#order + 1] = index
        end
    end
    return order
end

function History:BeginScan()
    local hist = Root()
    hist.head = (hist.head % hist.keep) + 1
    hist.slots[hist.head] = time()
    local head = hist.head
    for _, entry in pairs(hist.items) do
        entry.p[head] = 0
        entry.q[head] = 0
    end
    self.activeSlot = head
    return head
end

function History:Record(key, price, quantity)
    local slot = self.activeSlot
    if not slot or not key then return end
    local hist = Root()
    local entry = hist.items[key]
    if not entry then
        entry = { p = {}, q = {} }
        hist.items[key] = entry
    end
    entry.p[slot] = price or 0
    entry.q[slot] = quantity or 0
    entry.m = price or 0
    entry.t = time()

    if price and price > 0 then
        local day = NS.DayStart()
        entry.dl = entry.dl or {}
        entry.dn = entry.dn or {}
        entry.dl[day] = price
        entry.dn[day] = (entry.dn[day] or 0) + 1
    end
end

function History:Daily(key, days)
    local hist = Root()
    local entry = hist.items[key]
    if not entry then return nil end

    local today = NS.DayStart()
    local series = {}

    for offset = days - 1, 0, -1 do
        local day = today - offset * 86400
        series[#series + 1] = {
            t = day,
            p = entry.dl and entry.dl[day] or nil,
            n = (entry.dn and entry.dn[day]) or 0,
        }
    end

    return series
end

function History:CommitScan()
    self.activeSlot = nil
    self:Prune()
end

function History:TouchLast(key, price, quantity)
    if not key then return end
    local hist = Root()
    local entry = hist.items[key]
    if not entry then
        entry = { p = {}, q = {} }
        hist.items[key] = entry
    end
    entry.m = price or 0
    entry.mq = quantity or 0
    entry.t = time()
end

function History:Stats(key)
    if not key then return nil end
    local hist = Root()
    local entry = hist.items[key]
    if not entry then return nil end

    local points = {}
    local minPrice, maxPrice, sum, priced = nil, nil, 0, 0
    local quantitySum, quantityCount = 0, 0

    for _, index in ipairs(SlotOrder(hist)) do
        local price = entry.p[index]
        if price ~= nil then
            local quantity = entry.q[index] or 0
            points[#points + 1] = { t = hist.slots[index], p = price, q = quantity }
            if price > 0 then
                if not minPrice or price < minPrice then minPrice = price end
                if not maxPrice or price > maxPrice then maxPrice = price end
                sum = sum + price
                priced = priced + 1
            end
            quantitySum = quantitySum + quantity
            quantityCount = quantityCount + 1
        end
    end

    local newest = points[#points]

    return {
        points = points,
        scans = #points,
        priced = priced,
        min = minPrice,
        max = maxPrice,
        average = priced > 0 and (sum / priced) or nil,
        last = entry.m or (newest and newest.p) or 0,
        lastQuantity = (newest and newest.q) or entry.mq or 0,
        lastSeen = entry.t,
        averageQuantity = quantityCount > 0 and (quantitySum / quantityCount) or nil,
    }
end

function History:Brief(key)
    if not key then return nil end
    local hist = Root()
    local entry = hist.items[key]
    if not entry then return nil end

    local minPrice, maxPrice, sum, priced = nil, nil, 0, 0
    local quantitySum, quantityCount = 0, 0
    local newestPrice, newestQuantity

    for _, index in ipairs(SlotOrder(hist)) do
        local price = entry.p[index]
        if price ~= nil then
            local quantity = entry.q[index] or 0
            if price > 0 then
                if not minPrice or price < minPrice then minPrice = price end
                if not maxPrice or price > maxPrice then maxPrice = price end
                sum = sum + price
                priced = priced + 1
            end
            quantitySum = quantitySum + quantity
            quantityCount = quantityCount + 1
            newestPrice, newestQuantity = price, quantity
        end
    end

    return {
        min = minPrice,
        max = maxPrice,
        average = priced > 0 and (sum / priced) or nil,
        priced = priced,
        scans = quantityCount,
        last = entry.m or newestPrice or 0,
        lastQuantity = newestQuantity or entry.mq or 0,
        averageQuantity = quantityCount > 0 and (quantitySum / quantityCount) or nil,
        lastSeen = entry.t,
    }
end

function History:Keys()
    return Root().items
end

function History:Summary()
    local hist = Root()
    local scans = 0
    local newest
    for i = 1, hist.keep do
        local stamp = hist.slots[i]
        if stamp then
            scans = scans + 1
            if not newest or stamp > newest then newest = stamp end
        end
    end
    local items = 0
    for _ in pairs(hist.items) do
        items = items + 1
    end
    return scans, items, newest
end

local DAILY_KEEP_DAYS = 35

function History:Prune()
    local hist = Root()
    local days = NS.db.pruneDays or 30
    local cutoff = time() - days * 86400
    local dailyCutoff = NS.DayStart() - DAILY_KEEP_DAYS * 86400
    local removed = 0

    for key, entry in pairs(hist.items) do
        if (entry.t or 0) < cutoff then
            hist.items[key] = nil
            removed = removed + 1
        else
            entry.ds = nil
            if entry.dl then
                for day in pairs(entry.dl) do
                    if day < dailyCutoff then
                        entry.dl[day] = nil
                        if entry.dn then entry.dn[day] = nil end
                    end
                end
            end
        end
    end

    return removed
end

function History:Resize(newKeep)
    local hist = Root()
    if newKeep == hist.keep then return end

    local order = SlotOrder(hist)
    local slots = {}
    local kept = {}

    local first = math.max(1, #order - newKeep + 1)
    for position = first, #order do
        local index = order[position]
        slots[#slots + 1] = hist.slots[index]
        kept[#kept + 1] = index
    end

    for _, entry in pairs(hist.items) do
        local prices, quantities = {}, {}
        for newIndex, oldIndex in ipairs(kept) do
            prices[newIndex] = entry.p[oldIndex]
            quantities[newIndex] = entry.q[oldIndex]
        end
        entry.p = prices
        entry.q = quantities
    end

    hist.slots = slots
    hist.keep = newKeep
    hist.head = #slots
end

function History:Clear()
    NS.db.hist = nil
    self.activeSlot = nil
    Root()
end

NS.History = History
