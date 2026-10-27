local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc
local L = NS.L

local Scanner = {}

local FULL_SCAN_MIN_ITEMS = 500
local POLL_INTERVAL = 1.5
local STALL_POLLS = 6
local PROGRESS_STEP = 2000

local session, sessionCount = {}, 0
local ingested = 0
local stalled = 0
local pollToken = 0
local observeToken = 0
local reported = 0

local function ResetSession()
    wipe(session)
    sessionCount = 0
    ingested = 0
    stalled = 0
    reported = 0
end

local function RememberName(itemID)
    if not itemID then return end
    local names = NS.db.names
    if not names then
        names = {}
        NS.db.names = names
    end
    if names[itemID] then return end
    local name = GetItemInfo(itemID)
    if name then
        names[itemID] = name
    end
end

local function AddToSession(key, price, quantity)
    if not key then return end

    local bucket = session[key]
    if not bucket then
        session[key] = { p = price, q = quantity }
        sessionCount = sessionCount + 1
    else
        if price < bucket.p then bucket.p = price end
        bucket.q = bucket.q + quantity
    end
end

local function AddResult(result)
    local price = result.minPrice or 0
    local quantity = result.totalQuantity or 0
    if price <= 0 or quantity <= 0 then return end

    if result.itemKey then
        RememberName(result.itemKey.itemID)
    end

    local specific, plain = NS.KeysFromItemKey(result.itemKey)
    AddToSession(specific, price, quantity)
    AddToSession(plain, price, quantity)
end

local function AddResults(results, from)
    if type(results) ~= "table" then return 0 end
    local added = 0
    for index = (from or 0) + 1, #results do
        local result = results[index]
        if type(result) == "table" then
            AddResult(result)
            added = added + 1
        end
    end
    return added
end

function Scanner:IsAtAuctionHouse()
    if self.atAuctionHouse then return true end
    if AuctionHouseFrame and AuctionHouseFrame:IsShown() then return true end
    return false
end

function Scanner:Finalize()
    pollToken = pollToken + 1

    if sessionCount == 0 then
        self.running = false
        return
    end

    if sessionCount >= FULL_SCAN_MIN_ITEMS then
        NS.History:BeginScan()
        for key, bucket in pairs(session) do
            NS.History:Record(key, bucket.p, bucket.q)
        end
        NS.History:CommitScan()
        NS.db.lastScan = time()
        NS.Print(L["Скан завершён:"], NS.PhraseItems(sessionCount))
    else
        for key, bucket in pairs(session) do
            NS.History:TouchLast(key, bucket.p, bucket.q)
        end
        NS.Print(L["Частичный просмотр учтён:"], NS.PhraseItems(sessionCount))
    end

    ResetSession()
    self.running = false

    if NS.Window then
        NS.Window:Refresh()
    end
end

function Scanner:Poll(token)
    if token ~= pollToken then return end
    if not self.running then return end

    if not self:IsAtAuctionHouse() then
        self:Finalize()
        return
    end

    local results = C_AuctionHouse.GetBrowseResults()
    local total = type(results) == "table" and #results or 0

    if total > ingested then
        AddResults(results, ingested)
        ingested = total
        stalled = 0
        if ingested - reported >= PROGRESS_STEP then
            reported = ingested
            NS.Print(format(L["Собрано лотов: %d"], ingested))
        end
        if NS.Window then
            NS.Window:SetProgress(format(L["Собрано лотов: %d"], ingested))
        end
    else
        stalled = stalled + 1
    end

    local complete = C_AuctionHouse.HasFullBrowseResults
        and C_AuctionHouse.HasFullBrowseResults()

    if complete and stalled >= 2 then
        self:Finalize()
        return
    end

    if stalled >= STALL_POLLS then
        self:Finalize()
        return
    end

    if not complete and C_AuctionHouse.RequestMoreBrowseResults then
        C_AuctionHouse.RequestMoreBrowseResults()
    end

    NS.After(POLL_INTERVAL, function() Scanner:Poll(token) end)
end

function Scanner:Start()
    if not self:IsAtAuctionHouse() then
        NS.Print(L["Откройте окно аукциона"])
        return
    end
    if self.running then
        NS.Print(L["Скан уже идёт"])
        return
    end

    ResetSession()
    self.running = true

    C_AuctionHouse.SendBrowseQuery({
        searchString = "",
        sorts = {},
        filters = {},
        itemClassFilters = {},
    })

    NS.Print(L["Скан начат, не закрывайте окно аукциона"])

    pollToken = pollToken + 1
    local token = pollToken
    NS.After(POLL_INTERVAL, function() Scanner:Poll(token) end)
end

function Scanner:Stop()
    if not self.running then return end
    self:Finalize()
end

function Scanner:ScheduleAutoScan()
    if not NS.db.autoScan then return end

    local interval = (NS.db.autoScanInterval or 30) * 60
    if time() - (NS.db.lastScan or 0) < interval then return end

    observeToken = observeToken + 1
    local token = observeToken
    local delay = (NS.AuctionatorBridge and NS.AuctionatorBridge:IsAvailable()) and 20 or 5

    NS.After(delay, function()
        if token ~= observeToken then return end
        if not Scanner:IsAtAuctionHouse() then return end
        if Scanner.running then return end
        if time() - (NS.db.lastScan or 0) < interval then return end
        Scanner:Start()
    end)
end

function Scanner:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        self.atAuctionHouse = true
        self:ScheduleAutoScan()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        self.atAuctionHouse = false
        observeToken = observeToken + 1
        self:Stop()
    end
end

local AUCTION_EVENTS = {
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
}

function Scanner:Subscribe(frame)
    local registered = false

    if type(frame.RegisterCustomEvent) == "function" then
        registered = true
        for _, event in ipairs(AUCTION_EVENTS) do
            registered = registered and pcall(frame.RegisterCustomEvent, frame, event)
        end
    end

    if not registered and type(_G.RegisterCustomEvent) == "function" then
        registered = true
        for _, event in ipairs(AUCTION_EVENTS) do
            registered = registered and pcall(_G.RegisterCustomEvent, frame, event)
        end
    end

    if not registered and FrameUtil
       and type(FrameUtil.RegisterFrameForCustomEvents) == "function" then
        registered = pcall(FrameUtil.RegisterFrameForCustomEvents, frame, AUCTION_EVENTS)
    end

    for _, event in ipairs(AUCTION_EVENTS) do
        pcall(frame.RegisterEvent, frame, event)
    end

    self.subscribed = registered
end

function Scanner:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, ...)
        Scanner:OnEvent(event, ...)
    end)

    self:Subscribe(frame)
    self.frame = frame

    if AuctionHouseFrame then
        AuctionHouseFrame:HookScript("OnShow", function()
            Scanner.atAuctionHouse = true
            Scanner:ScheduleAutoScan()
            if NS.db.window and NS.Window then
                NS.Window:Show()
            end
        end)
        AuctionHouseFrame:HookScript("OnHide", function()
            Scanner.atAuctionHouse = false
            Scanner:Stop()
            if NS.Window then
                NS.Window:Hide()
            end
        end)
        self.hookedFrame = true
    end
end

function Scanner:Debug()
    NS.Print("подписка:", tostring(self.subscribed),
        "| хук окна:", tostring(self.hookedFrame),
        "| аукцион открыт:", tostring(self:IsAtAuctionHouse()),
        "| скан идёт:", tostring(self.running))

    local results = C_AuctionHouse.GetBrowseResults()
    local total = type(results) == "table" and #results or -1
    local full = C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults()
    NS.Print("GetBrowseResults:", total,
        "| полный список:", tostring(full),
        "| взято:", ingested,
        "| ключей:", sessionCount)
end

NS.Scanner = Scanner
