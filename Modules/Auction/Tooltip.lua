local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc
local L = NS.L

local Tooltip = {}

local S = NS.Styling

local ACCENT = S.ACCENT_GLOW
local VALUE = S.TEXT_BRIGHT
local DIM = S.TEXT_DIM
local UP = S.UP
local DOWN = S.DOWN

local function Stats(link)
    local specific, plain = NS.KeysFromItem(link)
    if not specific then return nil, nil end

    local stats = NS.History:Brief(specific)
    local key = specific
    if not stats and plain then
        stats = NS.History:Brief(plain)
        key = plain
    end
    return stats, key
end

local function AddPriceLine(tip, stats)
    if stats.last and stats.last > 0 then
        tip:AddDoubleLine(L["Сейчас"], NS.Money(stats.last),
            ACCENT[1], ACCENT[2], ACCENT[3], VALUE[1], VALUE[2], VALUE[3])
    else
        tip:AddDoubleLine(L["Сейчас"], L["не было в продаже"],
            ACCENT[1], ACCENT[2], ACCENT[3], DIM[1], DIM[2], DIM[3])
    end
end

local function AddRangeLine(tip, stats)
    if not stats.min or stats.priced < 2 then return end
    if stats.min == stats.max then return end
    tip:AddDoubleLine(
        NS.PhraseScans(stats.priced),
        NS.Money(stats.min) .. "  -  " .. NS.Money(stats.max),
        DIM[1], DIM[2], DIM[3], VALUE[1], VALUE[2], VALUE[3])
end

local function AddTrendLine(tip, stats)
    if not stats.average or stats.priced < 3 or not stats.last or stats.last <= 0 then
        return
    end

    local deviation = (stats.last - stats.average) / stats.average * 100
    local text, r, g, b

    if deviation >= 5 then
        text = format(L["дороже среднего на %d%%"], floor(deviation + 0.5))
        r, g, b = UP[1], UP[2], UP[3]
    elseif deviation <= -5 then
        text = format(L["дешевле среднего на %d%%"], floor(-deviation + 0.5))
        r, g, b = DOWN[1], DOWN[2], DOWN[3]
    else
        text = L["на уровне среднего"]
        r, g, b = DIM[1], DIM[2], DIM[3]
    end

    tip:AddDoubleLine(L["Среднее"], NS.Money(stats.average),
        DIM[1], DIM[2], DIM[3], VALUE[1], VALUE[2], VALUE[3])
    tip:AddDoubleLine(" ", text, 0, 0, 0, r, g, b)
end

local function AddQuantityLine(tip, stats)
    if not NS.db.showQuantity or not stats.averageQuantity then return end
    tip:AddDoubleLine(L["Лотов"],
        format("%d  (" .. L["в среднем %d"] .. ")",
            stats.lastQuantity or 0, floor(stats.averageQuantity + 0.5)),
        DIM[1], DIM[2], DIM[3], VALUE[1], VALUE[2], VALUE[3])
end

local function AddScanLine(tip, stats)
    if not stats.lastSeen then return end
    if time() - stats.lastSeen < 3600 then return end
    tip:AddDoubleLine(L["Скан"], NS.TimeAgo(stats.lastSeen),
        DIM[1], DIM[2], DIM[3], DIM[1], DIM[2], DIM[3])
end

local function AddAuctionatorLine(tip, key)
    if not NS.db.showAuctionator then return end
    local extra = NS.AuctionatorBridge:Stats(key)
    if not extra or not extra.min then return end
    tip:AddDoubleLine(
        format(L["за %d дн (Auctionator)"], extra.span),
        NS.Money(extra.min) .. "  -  " .. NS.Money(extra.max),
        DIM[1], DIM[2], DIM[3], DIM[1], DIM[2], DIM[3])
end

function Tooltip:Render(tip, link)
    if not NS.db or not NS.db.tooltip then return end

    local stats, key = Stats(link)
    if not stats then return end
    if stats.scans == 0 and (stats.last or 0) == 0 then return end

    AddPriceLine(tip, stats)
    AddRangeLine(tip, stats)
    AddTrendLine(tip, stats)
    AddQuantityLine(tip, stats)
    AddScanLine(tip, stats)
    AddAuctionatorLine(tip, key)

    tip:Show()
end

local function OnTooltipSetItem(tip)
    if tip.aucBourseFilled then return end
    local _, link = tip:GetItem()
    if not link then return end
    tip.aucBourseFilled = true
    Tooltip:Render(tip, link)
end

local function OnClear(tip)
    tip.aucBourseFilled = nil
end

function Tooltip:Create()
    if self.hooked then return end

    local targets = {
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
    }

    for _, tip in ipairs(targets) do
        if tip then
            tip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
            tip:HookScript("OnTooltipCleared", OnClear)
            tip:HookScript("OnHide", OnClear)
        end
    end

    self.hooked = true
end

NS.Tooltip = Tooltip
