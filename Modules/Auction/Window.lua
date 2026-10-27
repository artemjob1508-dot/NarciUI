local addonName, Root = ...
Root.Auc = Root.Auc or {}
local NS = Root.Auc
local L = NS.L
local S = NS.Styling

local Window = {}

local WIDTH, HEIGHT = 620, 580
local PAD = 14
local ROW_HEIGHT = 22
local VISIBLE_ROWS = 13
local GRAPH_HEIGHT = 164
local MAX_POINTS = 31

local COL_ICON = 18
local COL_NAME = 260
local COL_PRICE = 120
local COL_AVERAGE = 104
local COL_QUANTITY = 46

local PLOT_LEFT = 12
local PLOT_GUTTER = 84
local PLOT_BOTTOM = 30
local PLOT_TOP = 46

local PLOT_WIDTH = WIDTH - 2 * PAD - PLOT_LEFT - PLOT_GUTTER
local PLOT_HEIGHT = GRAPH_HEIGHT - PLOT_BOTTOM - PLOT_TOP

local list = {}
local searchTimer = 0

local function Deviation(brief)
    if not brief.average or brief.average <= 0 or (brief.last or 0) <= 0 then
        return nil
    end
    return (brief.last - brief.average) / brief.average * 100
end

local function SortList(mode, descending)
    local compare
    if mode == "name" then
        compare = function(a, b) return a.name < b.name end
    elseif mode == "average" then
        compare = function(a, b) return (a.brief.average or 0) < (b.brief.average or 0) end
    elseif mode == "quantity" then
        compare = function(a, b) return (a.brief.lastQuantity or 0) < (b.brief.lastQuantity or 0) end
    else
        compare = function(a, b) return (a.brief.last or 0) < (b.brief.last or 0) end
    end

    table.sort(list, function(a, b)
        if descending then
            return compare(b, a)
        end
        return compare(a, b)
    end)
end

function Window:Rebuild()
    wipe(list)

    local filter = Root.Lower(self.search or "")
    local names = NS.db.names or {}

    for key in pairs(NS.History:Keys()) do
        if strsub(key, 1, 2) ~= "g:" then
            local itemID = tonumber(key)
            if itemID then
                local name = names[itemID] or GetItemInfo(itemID)
                if name and (filter == "" or Root.Lower(name):find(filter, 1, true)) then
                    local brief = NS.History:Brief(key)
                    if brief and (brief.last or 0) > 0 then
                        list[#list + 1] = {
                            key = key,
                            id = itemID,
                            name = name,
                            brief = brief,
                        }
                    end
                end
            end
        end
    end

    SortList(self.sortMode, self.sortDescending)

    local maxOffset = math.max(0, #list - VISIBLE_ROWS)
    if self.offset > maxOffset then
        self.offset = maxOffset
    end

    self:UpdateRows()
    self:UpdateStatus()
end

function Window:UpdateStatus()
    local scans, items, last = NS.History:Summary()
    self.status:SetText(format(L["сканов: %d, предметов: %d, последний скан: %s"],
        scans, items, NS.TimeAgo(last)))
    self.count:SetText(format(L["в списке: %d"], #list))
end

function Window:SetProgress(text)
    if self.status and self.frame and self.frame:IsShown() then
        self.status:SetText(text)
    end
end

function Window:UpdateScrollBar()
    local total = #list
    if total <= VISIBLE_ROWS then
        self.scrollThumb:Hide()
        return
    end

    local trackHeight = VISIBLE_ROWS * ROW_HEIGHT
    local thumbHeight = math.max(20, trackHeight * VISIBLE_ROWS / total)
    local maxOffset = total - VISIBLE_ROWS
    local travel = trackHeight - thumbHeight

    self.scrollThumb:SetHeight(thumbHeight)
    self.scrollThumb:ClearAllPoints()
    self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0,
        -(travel * (self.offset / maxOffset)))
    self.scrollThumb:Show()
end

function Window:UpdateRows()
    if self.settings and self.settings:IsShown() then return end

    for index = 1, VISIBLE_ROWS do
        local row = self.rows[index]
        local entry = list[self.offset + index]

        if entry then
            local brief = entry.brief
            row.key = entry.key
            row.id = entry.id
            row.name:SetText(entry.name)
            row.icon:SetTexture(GetItemIcon(entry.id))
            row.price:SetText(NS.MoneyText(brief.last))
            row.quantity:SetText(brief.lastQuantity or 0)

            local deviation = Deviation(brief)
            if deviation and abs(deviation) >= 5 then
                local color = deviation > 0 and "|cffe57373" or "|cff59d98c"
                row.average:SetText(format("%s%+d%%|r  %s",
                    color, deviation, NS.MoneyShort(brief.average)))
            else
                row.average:SetText(NS.MoneyText(brief.average))
            end

            if entry.key == self.selected then
                row.mark:Show()
                row.stripe:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
                row.stripe:Show()
            else
                row.mark:Hide()
                if index % 2 == 0 then
                    row.stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.35)
                    row.stripe:Show()
                else
                    row.stripe:Hide()
                end
            end

            row:Show()
        else
            row.key = nil
            row:Hide()
        end
    end

    self:UpdateScrollBar()
end

function Window:Scroll(delta)
    local maxOffset = math.max(0, #list - VISIBLE_ROWS)
    self.offset = math.max(0, math.min(maxOffset, self.offset - delta * 3))
    self:UpdateRows()
end

function Window:Select(key, name)
    self.selected = key
    self.graphTitle:SetText(name or L["выберите предмет"])
    if key then
        self.graphTitle:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    else
        self.graphTitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end
    self:DrawGraph()
    self:UpdateRows()
end

function Window:ClearGraph()
    for index = 1, MAX_POINTS do
        self.dots[index]:Hide()
        self.labels[index]:SetText("")
        self.gaps[index]:Hide()
        self.hovers[index]:Hide()
    end
    S.HidePolylineTail(self.segments, 0)
end

function Window:BuildSeries()
    if not self.selected then return nil end

    if self.range == "day" then
        local stats = NS.History:Stats(self.selected)
        if not stats then return nil end

        local dayStart = NS.DayStart()
        local series = {}
        for _, point in ipairs(stats.points) do
            if point.t and point.t >= dayStart then
                local listed = point.p and point.p > 0
                series[#series + 1] = {
                    t = point.t,
                    p = listed and point.p or nil,
                    q = point.q,
                    gap = not listed,
                    label = date("%H:%M", point.t),
                }
            end
        end
        return series
    end

    local days = (self.range == "week") and 7 or 30
    local series = NS.History:Daily(self.selected, days)
    if not series then return nil end

    for _, point in ipairs(series) do
        point.label = date("%d.%m", point.t)
    end
    return series
end

function Window:DrawGraph()
    self:ClearGraph()

    local series = self:BuildSeries()
    local count = series and math.min(#series, MAX_POINTS) or 0
    local first = series and (#series - count + 1) or 1

    local low, high, priced = nil, nil, 0
    for index = first, first + count - 1 do
        local value = series[index].p
        if value then
            if not low or value < low then low = value end
            if not high or value > high then high = value end
            priced = priced + 1
        end
    end

    if priced == 0 then
        self.averageLine:Hide()
        self.graphAverage:Hide()
        self.axisLine:Hide()
        self.graphHigh:SetText("")
        self.graphLow:SetText("")
        self.graphInfo:SetText(self.selected and L["нет данных за этот период"] or "")
        return
    end

    local minPrice, maxPrice = low, high
    if high <= low then
        low = low * 0.94
        high = high * 1.06 + 1
    end

    local graph = self.graph
    local plotWidth, plotHeight = PLOT_WIDTH, PLOT_HEIGHT

    local xs, ys = {}, {}
    for index = 1, count do
        local point = series[first + index - 1]
        local x = PLOT_LEFT + plotWidth / 2
        if count > 1 then
            x = PLOT_LEFT + plotWidth * (index - 1) / (count - 1)
        end

        xs[index] = x
        if point.p then
            ys[index] = PLOT_BOTTOM + plotHeight * (point.p - low) / (high - low)
        else
            ys[index] = nil
        end
    end

    local color = { S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1 }
    local runX, runY = {}, {}
    local drawn = 0

    for index = 1, count do
        local point = series[first + index - 1]
        if ys[index] then
            runX[#runX + 1] = xs[index]
            runY[#runY + 1] = ys[index]
        elseif point.gap then
            if #runX > 1 then
                drawn = S.DrawPolyline(self.segments, graph, runX, runY, 3, color, drawn)
            end
            wipe(runX)
            wipe(runY)
        end
    end

    if #runX > 1 then
        drawn = S.DrawPolyline(self.segments, graph, runX, runY, 3, color, drawn)
    end

    S.HidePolylineTail(self.segments, drawn)

    local labelStep = 1
    if self.range == "month" then
        labelStep = 5
    elseif count > 12 then
        labelStep = math.ceil(count / 10)
    end

    local total, sum = 0, 0
    for index = 1, count do
        local point = series[first + index - 1]
        local dot = self.dots[index]
        local label = self.labels[index]
        local hover = self.hovers[index]

        hover.point = point
        hover.range = self.range
        hover.name = self.graphTitle:GetText()
        hover:ClearAllPoints()
        hover:SetPoint("CENTER", graph, "BOTTOMLEFT", xs[index], ys[index] or (PLOT_BOTTOM - 4))
        hover:Show()

        if ys[index] then
            sum = sum + point.p
            total = total + 1

            dot:ClearAllPoints()
            dot:SetPoint("CENTER", graph, "BOTTOMLEFT", xs[index], ys[index])
            if index == count then
                dot:SetWidth(7)
                dot:SetHeight(7)
                dot:SetVertexColor(1, 1, 1, 0.95)
            else
                dot:SetWidth(5)
                dot:SetHeight(5)
                dot:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
            end
            dot:Show()
        elseif point.gap then
            local gap = self.gaps[index]
            gap:ClearAllPoints()
            gap:SetPoint("BOTTOM", graph, "BOTTOMLEFT", xs[index], PLOT_BOTTOM - 4)
            gap:Show()
        end

        label:ClearAllPoints()
        label:SetPoint("TOP", graph, "BOTTOMLEFT", xs[index], PLOT_BOTTOM - 8)
        if index == count or index == 1 or (index - 1) % labelStep == 0 then
            label:SetText(point.label or "")
        else
            label:SetText("")
        end
    end

    local average = total > 0 and (sum / total) or nil
    local axisX = PLOT_LEFT + plotWidth + 10

    self.graphHigh:ClearAllPoints()
    self.graphHigh:SetPoint("LEFT", graph, "BOTTOMLEFT", axisX, PLOT_BOTTOM + plotHeight)
    self.graphHigh:SetText(NS.MoneyText(maxPrice))

    self.graphLow:ClearAllPoints()
    self.graphLow:SetPoint("LEFT", graph, "BOTTOMLEFT", axisX, PLOT_BOTTOM)
    self.graphLow:SetText(NS.MoneyText(minPrice))

    if average then
        local y = PLOT_BOTTOM + plotHeight * (average - low) / (high - low)
        self.averageLine:ClearAllPoints()
        self.averageLine:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", PLOT_LEFT, y)
        self.averageLine:SetPoint("BOTTOMRIGHT", graph, "BOTTOMLEFT", PLOT_LEFT + plotWidth, y)
        self.averageLine:Show()

        self.graphAverage:ClearAllPoints()
        self.graphAverage:SetPoint("LEFT", graph, "BOTTOMLEFT", axisX, y)
        self.graphAverage:SetText(NS.MoneyText(average))
        self.graphAverage:Show()
    else
        self.averageLine:Hide()
        self.graphAverage:Hide()
    end

    self.axisLine:Show()

    if self.range == "day" then
        self.graphInfo:SetText(NS.PhraseScans(priced))
    else
        self.graphInfo:SetText(format(L["дней с данными: %d"], priced))
    end
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)

    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetTexture(S.WHITE)
    row.stripe:Hide()

    row.mark = row:CreateTexture(nil, "ARTWORK")
    row.mark:SetWidth(2)
    row.mark:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    row.mark:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 2)
    row.mark:SetTexture(S.WHITE)
    row.mark:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
    row.mark:Hide()

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(S.WHITE)
    row.highlight:SetVertexColor(1, 1, 1, 0.06)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(COL_ICON)
    row.icon:SetHeight(COL_ICON)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetWidth(COL_NAME)
    row.name:SetHeight(ROW_HEIGHT)
    row.name:SetJustifyH("LEFT")
    pcall(row.name.SetWordWrap, row.name, false)

    row.price = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.price:SetPoint("LEFT", row.name, "RIGHT", 2, 0)
    row.price:SetWidth(COL_PRICE)
    row.price:SetJustifyH("RIGHT")

    row.average = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.average:SetPoint("LEFT", row.price, "RIGHT", 4, 0)
    row.average:SetWidth(COL_AVERAGE)
    row.average:SetJustifyH("RIGHT")

    row.quantity = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.quantity:SetPoint("LEFT", row.average, "RIGHT", 4, 0)
    row.quantity:SetWidth(COL_QUANTITY)
    row.quantity:SetJustifyH("RIGHT")

    row:SetScript("OnClick", function(self)
        if self.key then
            Window:Select(self.key, self.name:GetText())
        end
    end)

    row:SetScript("OnEnter", function(self)
        if not self.id then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetHyperlink("item:" .. self.id)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return row
end

local function CreateHeader(parent, text, width, anchorTo, mode)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(14)
    if anchorTo then
        button:SetPoint("LEFT", anchorTo, "RIGHT", anchorTo.gap or 4, 0)
    else
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", COL_ICON + 11, 0)
    end

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetAllPoints()
    button.label:SetJustifyH(anchorTo and "RIGHT" or "LEFT")
    button.text = text
    button.mode = mode

    button:SetScript("OnClick", function(self)
        if Window.sortMode == self.mode then
            Window.sortDescending = not Window.sortDescending
        else
            Window.sortMode = self.mode
            Window.sortDescending = true
        end
        Window.offset = 0
        Window:Rebuild()
        Window:UpdateHeaders()
    end)

    button:SetScript("OnEnter", function(self)
        self.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end)

    button:SetScript("OnLeave", function()
        Window:UpdateHeaders()
    end)

    return button
end

function Window:UpdateTabs()
    if not self.tabs then return end
    for _, tab in ipairs(self.tabs) do
        if tab.range == self.range then
            tab:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            tab:SetBackdropColor(0.06, 0.14, 0.12, 0.95)
            tab.label:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            tab:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
            tab:SetBackdropColor(0.08, 0.09, 0.13, 0.95)
            tab.label:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
    end
end

function Window:UpdateHeaders()
    for _, header in ipairs(self.headers) do
        if header.mode == self.sortMode then
            header.label:SetText(header.text .. (self.sortDescending and " v" or " ^"))
            header.label:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
        else
            header.label:SetText(header.text)
            header.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
end

function Window:CreateSettings(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel:Hide()

    local tooltip = S.CreateCheck(panel, L["Показывать историю в подсказках"])
    tooltip:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -6)
    tooltip:SetChecked(NS.db.tooltip)
    tooltip.onToggle = function(value) NS.db.tooltip = value end

    local auto = S.CreateCheck(panel, L["Сканировать автоматически"])
    auto:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, -12)
    auto:SetChecked(NS.db.autoScan)
    auto.onToggle = function(value) NS.db.autoScan = value end

    local quantity = S.CreateCheck(panel, L["Показывать количество лотов"])
    quantity:SetPoint("TOPLEFT", auto, "BOTTOMLEFT", 0, -12)
    quantity:SetChecked(NS.db.showQuantity)
    quantity.onToggle = function(value) NS.db.showQuantity = value end

    local auctionator = S.CreateCheck(panel, L["Учитывать данные Auctionator"])
    auctionator:SetPoint("TOPLEFT", quantity, "BOTTOMLEFT", 0, -12)
    auctionator:SetChecked(NS.db.showAuctionator)
    auctionator.onToggle = function(value) NS.db.showAuctionator = value end

    local keep = S.CreateSlider(panel, 2, 30, 1, WIDTH - 2 * PAD - 40)
    keep:SetPoint("TOPLEFT", auctionator, "BOTTOMLEFT", 2, -30)
    keep:SetValue(NS.db.keep or 10)
    keep.label:SetText(format(L["Хранить сканов: %d"], NS.db.keep or 10))
    keep:SetScript("OnValueChanged", function(self, value)
        value = floor(value + 0.5)
        self.label:SetText(format(L["Хранить сканов: %d"], value))
        if value ~= NS.db.keep then
            NS.db.keep = value
            NS.History:Resize(value)
        end
    end)

    local days = S.CreateSlider(panel, 1, 120, 1, WIDTH - 2 * PAD - 40)
    days:SetPoint("TOPLEFT", keep, "BOTTOMLEFT", 0, -28)
    days:SetValue(NS.db.pruneDays or 30)
    days.label:SetText(format(L["Забывать предмет через %d дн"], NS.db.pruneDays or 30))
    days:SetScript("OnValueChanged", function(self, value)
        value = floor(value + 0.5)
        self.label:SetText(format(L["Забывать предмет через %d дн"], value))
        NS.db.pruneDays = value
    end)

    local interval = S.CreateSlider(panel, 5, 120, 5, WIDTH - 2 * PAD - 40)
    interval:SetPoint("TOPLEFT", days, "BOTTOMLEFT", 0, -28)
    interval:SetValue(NS.db.autoScanInterval or 30)
    interval.label:SetText(format(L["Автоскан не чаще раза в %d мин"], NS.db.autoScanInterval or 30))
    interval:SetScript("OnValueChanged", function(self, value)
        value = floor(value + 0.5)
        self.label:SetText(format(L["Автоскан не чаще раза в %d мин"], value))
        NS.db.autoScanInterval = value
    end)

    local clear = S.CreateButton(panel, L["Стереть историю"], 140, 22)
    clear:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", -2, -26)
    clear:SetScript("OnClick", function()
        NS.History:Clear()
        Window.offset = 0
        Window:Rebuild()
        Window:Select(nil, nil)
    end)

    return panel
end

function Window:Create()
    if self.frame then return end

    self.sortMode = "price"
    self.sortDescending = true
    self.offset = 0
    self.range = NS.db.range or "day"

    local frame = S.CreatePanel("AucBourseFrame", UIParent, WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Window.moved = true
    end)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -14)
    title:SetText("AucBourse")
    title:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])

    local close = S.CreateCloseButton(frame)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -10)
    close:SetScript("OnClick", function() Window:Hide() end)

    local scan = S.CreateButton(frame, L["Сканировать"], 100, 22)
    scan:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -38)
    scan:SetScript("OnClick", function() NS.Scanner:Start() end)

    local settingsButton = S.CreateButton(frame, L["Настройки"], 90, 22)
    settingsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -38)

    local search = S.CreateEditBox(frame, WIDTH - 2 * PAD - 100 - 90 - 16, 22)
    search:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    search.placeholder:SetText(L["Поиск"])
    search:SetScript("OnTextChanged", function(self)
        self:UpdatePlaceholder()
        Window.search = self:GetText()
        searchTimer = GetTime() + 0.3
        NS.After(0.35, function()
            if GetTime() >= searchTimer then
                Window.offset = 0
                Window:Rebuild()
            end
        end)
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    search:UpdatePlaceholder()

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    status:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -68)
    status:SetJustifyH("LEFT")
    self.status = status

    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    count:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -68)
    count:SetJustifyH("RIGHT")
    self.count = count

    local rule = S.CreateRule(frame, WIDTH - 2 * PAD)
    rule:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -84)

    local headers = CreateFrame("Frame", nil, frame)
    headers:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -92)
    headers:SetWidth(WIDTH - 2 * PAD - 6)
    headers:SetHeight(14)

    local nameHeader = CreateHeader(headers, L["Предмет"], COL_NAME, nil, "name")
    nameHeader.gap = 2
    local priceHeader = CreateHeader(headers, L["Цена"], COL_PRICE, nameHeader, "price")
    local averageHeader = CreateHeader(headers, L["Среднее"], COL_AVERAGE, priceHeader, "average")
    local quantityHeader = CreateHeader(headers, L["Лотов"], COL_QUANTITY, averageHeader, "quantity")
    self.headers = { nameHeader, priceHeader, averageHeader, quantityHeader }

    local listArea = CreateFrame("Frame", nil, frame)
    listArea:SetPoint("TOPLEFT", headers, "BOTTOMLEFT", 0, -4)
    listArea:SetWidth(WIDTH - 2 * PAD - 6)
    listArea:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
    listArea:EnableMouseWheel(true)
    listArea:SetScript("OnMouseWheel", function(_, delta) Window:Scroll(delta) end)

    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(3)
    track:SetPoint("TOPRIGHT", listArea, "TOPRIGHT", 6, 0)
    track:SetPoint("BOTTOMRIGHT", listArea, "BOTTOMRIGHT", 6, 0)
    track:SetTexture(S.WHITE)
    track:SetVertexColor(1, 1, 1, 0.05)
    self.scrollTrack = track

    local thumb = frame:CreateTexture(nil, "ARTWORK")
    thumb:SetWidth(3)
    thumb:SetTexture(S.WHITE)
    thumb:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.7)
    thumb:Hide()
    self.scrollThumb = thumb

    self.rows = {}
    for index = 1, VISIBLE_ROWS do
        self.rows[index] = CreateRow(listArea, index)
    end

    local graph = CreateFrame("Frame", nil, frame)
    graph:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    graph:SetWidth(WIDTH - 2 * PAD)
    graph:SetHeight(GRAPH_HEIGHT)
    self.graph = graph

    local graphBackground = graph:CreateTexture(nil, "BACKGROUND")
    graphBackground:SetAllPoints()
    graphBackground:SetTexture(S.WHITE)
    graphBackground:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.7)

    local axis = graph:CreateTexture(nil, "ARTWORK")
    axis:SetHeight(1)
    axis:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", PLOT_LEFT - 4, PLOT_BOTTOM - 6)
    axis:SetPoint("BOTTOMRIGHT", graph, "BOTTOMLEFT", PLOT_LEFT + PLOT_WIDTH + 4, PLOT_BOTTOM - 6)
    axis:SetTexture(S.WHITE)
    axis:SetVertexColor(1, 1, 1, 0.08)

    local axisLine = graph:CreateTexture(nil, "ARTWORK")
    axisLine:SetWidth(1)
    axisLine:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", PLOT_LEFT + PLOT_WIDTH + 4, PLOT_BOTTOM - 6)
    axisLine:SetPoint("TOPLEFT", graph, "BOTTOMLEFT", PLOT_LEFT + PLOT_WIDTH + 4, PLOT_BOTTOM + PLOT_HEIGHT + 12)
    axisLine:SetTexture(S.WHITE)
    axisLine:SetVertexColor(1, 1, 1, 0.10)
    axisLine:Hide()
    self.axisLine = axisLine

    local graphTitle = graph:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    graphTitle:SetPoint("TOPLEFT", graph, "TOPLEFT", 8, -7)
    graphTitle:SetWidth(PLOT_WIDTH - 200)
    graphTitle:SetJustifyH("LEFT")
    graphTitle:SetText(L["выберите предмет"])
    graphTitle:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    pcall(graphTitle.SetWordWrap, graphTitle, false)
    self.graphTitle = graphTitle

    local graphHigh = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    graphHigh:SetPoint("LEFT", graph, "BOTTOMLEFT", PLOT_LEFT + PLOT_WIDTH + 10, PLOT_BOTTOM + PLOT_HEIGHT)
    graphHigh:SetJustifyH("LEFT")
    self.graphHigh = graphHigh

    local graphLow = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    graphLow:SetPoint("LEFT", graph, "BOTTOMLEFT", PLOT_LEFT + PLOT_WIDTH + 10, PLOT_BOTTOM)
    graphLow:SetJustifyH("LEFT")
    self.graphLow = graphLow

    local graphAverage = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    graphAverage:SetJustifyH("LEFT")
    graphAverage:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    graphAverage:Hide()
    self.graphAverage = graphAverage

    local graphInfo = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    graphInfo:SetPoint("TOPLEFT", graph, "TOPLEFT", 8, -22)
    self.graphInfo = graphInfo

    local averageLine = graph:CreateTexture(nil, "BACKGROUND")
    averageLine:SetHeight(1)
    averageLine:SetTexture(S.WHITE)
    averageLine:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
    averageLine:Hide()
    self.averageLine = averageLine

    local ranges = {
        { key = "day", text = L["День"] },
        { key = "week", text = L["Неделя"] },
        { key = "month", text = L["Месяц"] },
    }

    self.tabs = {}
    local previous
    for index = #ranges, 1, -1 do
        local info = ranges[index]
        local tab = S.CreateButton(graph, info.text, 58, 18)
        if previous then
            tab:SetPoint("RIGHT", previous, "LEFT", -4, 0)
        else
            tab:SetPoint("TOPRIGHT", graph, "TOPRIGHT", -6, -5)
        end
        tab.range = info.key
        tab:SetScript("OnClick", function(self)
            Window.range = self.range
            NS.db.range = self.range
            Window:UpdateTabs()
            Window:DrawGraph()
        end)
        tab:SetScript("OnLeave", function()
            Window:UpdateTabs()
        end)
        previous = tab
        self.tabs[index] = tab
    end

    self.segments = {}
    self.dots = {}
    self.gaps = {}
    self.labels = {}
    self.hovers = {}

    for index = 1, MAX_POINTS do
        local hover = CreateFrame("Button", nil, graph)
        hover:SetWidth(18)
        hover:SetHeight(18)
        hover:Hide()
        hover:SetScript("OnEnter", function(self)
            local point = self.point
            if not point then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.name or "", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])

            if self.range == "day" then
                GameTooltip:AddDoubleLine(
                    date("%d.%m %H:%M", point.t),
                    point.p and NS.MoneyText(point.p) or L["не было в продаже"],
                    S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 1, 1, 1)
                GameTooltip:AddDoubleLine(L["Лотов"], tostring(point.q or 0),
                    S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 1, 1, 1)
            else
                GameTooltip:AddDoubleLine(
                    date("%d.%m.%Y", point.t),
                    point.p and NS.MoneyText(point.p) or L["сканов не было"],
                    S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 1, 1, 1)
                if point.p then
                    GameTooltip:AddDoubleLine(L["цена последнего скана дня, всего сканов:"],
                        tostring(point.n or 0),
                        S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 1, 1, 1)
                end
            end
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        self.hovers[index] = hover
    end

    for index = 1, MAX_POINTS do
        local dot = graph:CreateTexture(nil, "OVERLAY")
        dot:SetTexture(S.WHITE)
        dot:Hide()
        self.dots[index] = dot

        local gap = graph:CreateTexture(nil, "ARTWORK")
        gap:SetWidth(3)
        gap:SetHeight(3)
        gap:SetTexture(S.WHITE)
        gap:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 0.7)
        gap:Hide()
        self.gaps[index] = gap

        local label = graph:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        label:SetWidth(44)
        label:SetJustifyH("CENTER")
        self.labels[index] = label
    end

    local settings = self:CreateSettings(listArea)
    self.settings = settings

    settingsButton:SetScript("OnClick", function(self)
        if settings:IsShown() then
            settings:Hide()
            headers:Show()
            Window:UpdateRows()
            self:SetLabel(L["Настройки"])
        else
            settings:Show()
            headers:Hide()
            for _, row in ipairs(Window.rows) do
                row:Hide()
            end
            Window.scrollThumb:Hide()
            self:SetLabel(L["Список"])
        end
    end)

    frame:SetScript("OnShow", function()
        Window:Rebuild()
        Window:DrawGraph()
    end)

    self:UpdateHeaders()
    self:UpdateTabs()
    self.frame = frame
    self:Anchor()
end

function Window:Anchor()
    if not self.frame then return end
    if self.moved then return end

    self.frame:ClearAllPoints()
    if AuctionHouseFrame then
        self.frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 6, 0)
        self.frame:SetFrameLevel(AuctionHouseFrame:GetFrameLevel() + 5)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function Window:Show()
    if not self.frame then self:Create() end
    self:Anchor()
    self.frame:Show()
end

function Window:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Window:Refresh()
    if self.frame and self.frame:IsShown() then
        self:Rebuild()
        self:DrawGraph()
    end
end

NS.Window = Window
