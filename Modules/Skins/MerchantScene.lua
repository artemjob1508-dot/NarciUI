local addonName, NS = ...
local L = NS.L

local Scene = {}
NS.MerchantScene = Scene

local WHITE = "Interface\\Buttons\\WHITE8x8"

local PANEL_W = 660
local TILE_W = 322
local TILE_H = 54
local TILE_GAP = 8
local COLUMNS = 2
local FILTER_USABLE = 0
local FILTER_ALL = 1

local function Style()
    return NS.Styling
end

local function Enabled()
    return NS.db and NS.db.merchantStyle == "scene"
end

local function Coins(money)
    if not money or money <= 0 then return "" end

    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    local parts = {}

    if gold > 0 then
        parts[#parts + 1] = gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    end
    if silver > 0 then
        parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    end
    if copper > 0 then
        parts[#parts + 1] = copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end

    return table.concat(parts, " ")
end

local function Icon(texture, value)
    return value .. "|T" .. texture .. ":0:0:2:0|t"
end

local function CostText(index, price, extendedCost)
    local parts = {}

    if price and price > 0 then parts[#parts + 1] = Coins(price) end

    if extendedCost and GetMerchantItemCostInfo then
        local honor, arena, count = GetMerchantItemCostInfo(index)
        local faction = UnitFactionGroup("player") or "Alliance"

        if honor and honor > 0 then
            parts[#parts + 1] = Icon("Interface\\PVPFrame\\PVPCurrency-Honor1-" .. faction, honor)
        end

        if arena and arena > 0 then
            parts[#parts + 1] = Icon("Interface\\PVPFrame\\PVPCurrency-Conquest1-" .. faction, arena)
        end

        for slot = 1, (count or 0) do
            local texture, value = GetMerchantItemCostItem(index, slot)
            if texture and value then parts[#parts + 1] = Icon(texture, value) end
        end
    end

    return table.concat(parts, "   ")
end

local function MerchantLink(index)
    local link = GetMerchantItemLink(index)
    if link then return link end

    local itemID = GetMerchantItemID and GetMerchantItemID(index)
    if itemID and C_Item and C_Item.GetItemLinkCache then
        return C_Item.GetItemLinkCache(itemID)
    end
end

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local scanner

local function RequestItem(link)
    if not link then return end
    if not scanner then
        scanner = CreateFrame("GameTooltip", "NarciSirus_MerchantScan", UIParent, "GameTooltipTemplate")
        scanner:SetOwner(UIParent, "ANCHOR_NONE")
    end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    pcall(scanner.SetHyperlink, scanner, link:match("(item:[%-%d:]+)") or link)
    scanner:Hide()
end

local function Candidates(texture, link)
    local list = {}

    if type(texture) == "string" and texture ~= "" then
        list[#list + 1] = texture
        if not texture:find("[/\\]") then
            list[#list + 1] = "Interface" .. "\\" .. "Icons" .. "\\" .. texture
        end
    end

    if link then
        local cached = select(10, GetItemInfo(link))
        if cached then list[#list + 1] = cached end

        local itemID = tonumber(link:match("item:(%d+)"))
        if itemID and GetItemIcon then
            local icon = GetItemIcon(itemID)
            if icon then list[#list + 1] = icon end
        end
    end

    return list
end

local function SetIcon(texture, path, link)
    for _, candidate in ipairs(Candidates(path, link)) do
        if texture:SetTexture(candidate) then return true end
    end

    texture:SetTexture(QUESTION)
    RequestItem(link)
    return false
end

local function QualityColor(link)
    local quality = link and select(3, GetItemInfo(link))
    if quality and GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        return r, g, b, quality
    end
    return 0.92, 0.92, 0.92, 1
end

local function TextButton(parent, text, width)
    local S = Style()

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 120, 26)

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Panel(0.035, 0.040, 0.058, 0.9))

    S.CreateEdges(button, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button)
    hover:SetTexture(WHITE)
    hover:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(12), "")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetTextColor(0.92, 0.93, 0.95)
    label:SetText(text)
    NS.Styling.GlyphIcon(label)

    button.label = label

    function button:SetUsable(usable)
        self:EnableMouse(usable and true or false)
        self:SetAlpha(usable and 1 or 0.4)
    end

    return button
end

local function HideInterface()
    local dialogueDb = NS.db and NS.db.dialogue
    return not dialogueDb or dialogueDb.hideInterface ~= false
end

local function Silence(on)
    local frame = MerchantFrame
    if not frame then return end

    if on then
        frame:SetAlpha(0)
        frame:SetScale(0.001)
        frame.narciSilenced = true
    elseif frame.narciSilenced then
        frame.narciSilenced = nil
        frame:SetScale(1)
        frame:SetAlpha(1)
    end
end

function Scene:BuildDim()
    local dim = CreateFrame("Frame", "NarciSirus_MerchantDim", UIParent)
    dim:SetAllPoints(UIParent)
    dim:SetFrameStrata("BACKGROUND")
    dim:SetFrameLevel(1)
    dim:Hide()

    local flat = dim:CreateTexture(nil, "BACKGROUND")
    flat:SetAllPoints(dim)
    flat:SetTexture(WHITE)
    flat:SetVertexColor(0, 0, 0, 0.6)

    local left = dim:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", dim, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", dim, "BOTTOMLEFT", 0, 0)
    left:SetWidth(860)
    left:SetTexture(WHITE)
    left:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.7, 0, 0, 0, 0)

    local bottom = dim:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", dim, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", dim, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(260)
    bottom:SetTexture(WHITE)
    bottom:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.6, 0, 0, 0, 0)

    self.dim = dim
end

function Scene:BuildStage()
    local screen = UIParent:GetHeight() or 768

    local stage = CreateFrame("Frame", "NarciSirus_MerchantStage", UIParent)
    stage:SetFrameStrata("BACKGROUND")
    stage:SetFrameLevel(10)
    stage:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -math.floor(screen * 0.05), -math.floor(screen * 0.08))
    stage:SetSize(math.floor(screen * 0.70), math.floor(screen * 1.67))
    stage:Hide()

    local model = CreateFrame("PlayerModel", nil, stage)
    model:SetAllPoints(stage)
    model:SetFrameLevel(stage:GetFrameLevel() + 2)

    stage.model = model
    self.stage = stage
end

function Scene:BuildTile(index)
    local S = Style()

    local tile = CreateFrame("Button", "NarciSirus_MerchantTile" .. index, self.grid)
    tile:SetSize(TILE_W, TILE_H)
    tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tile:RegisterForDrag("LeftButton")

    local ground = tile:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(tile)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(NS.Styling.Tint(0.030, 0.034, 0.050, 0.85))

    local hover = tile:CreateTexture(nil, "BORDER")
    hover:SetAllPoints(tile)
    hover:SetTexture(WHITE)
    hover:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.04)
    hover:Hide()

    local edge = tile:CreateTexture(nil, "ARTWORK")
    edge:SetWidth(2)
    edge:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    edge:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 0, 0)
    edge:SetTexture(WHITE)

    local frame = tile:CreateTexture(nil, "ARTWORK")
    frame:SetSize(42, 42)
    frame:SetPoint("LEFT", tile, "LEFT", 9, 0)
    frame:SetTexture(WHITE)

    local holder = CreateFrame("Frame", nil, tile)
    holder:SetAllPoints(tile)
    holder:SetFrameLevel(tile:GetFrameLevel() + 1)

    local icon = holder:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local count = holder:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    count:SetTextColor(1, 1, 1)

    local name = tile:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(13), "")
    name:SetShadowOffset(1, -1)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
    name:SetPoint("RIGHT", tile, "RIGHT", -8, 0)
    name:SetHeight(28)
    name:SetJustifyH("LEFT")
    name:SetJustifyV("TOP")

    local price = tile:CreateFontString(nil, "OVERLAY")
    price:SetFont(NS.FONT, NS.FS(12), "")
    price:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 10, 1)
    price:SetPoint("RIGHT", tile, "RIGHT", -8, 0)
    price:SetJustifyH("LEFT")
    price:SetTextColor(0.85, 0.86, 0.88)

    tile.hover = hover
    tile.edge = edge
    tile.frame = frame
    tile.icon = icon
    tile.countText = count
    tile.nameText = name
    tile.priceText = price

    tile.SplitStack = function(button, split)
        if button.extendedCost then
            MerchantFrame_ConfirmExtendedItemCost(button, split)
        elseif split > 0 then
            BuyMerchantItem(button:GetID(), split)
        end
    end

    tile.UpdateTooltip = function(button)
        if button.hasItem then MerchantItemButton_OnEnter(button) end
    end

    tile:SetScript("OnClick", function(self, button)
        if not self.hasItem then return end

        if IsModifiedClick() then
            MerchantItemButton_OnModifiedClick(self, button)
        else
            MerchantItemButton_OnClick(self, button)
        end
    end)

    tile:SetScript("OnDragStart", function(self)
        if self.hasItem then MerchantItemButton_OnClick(self, "LeftButton") end
    end)

    tile:SetScript("OnEnter", function(self)
        self.hover:Show()
        if self.hasItem then MerchantItemButton_OnEnter(self) end
    end)

    tile:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
        ResetCursor()
        if MerchantFrame then MerchantFrame.itemHover = nil end
    end)

    tile:SetScript("OnHide", function(self)
        if self.hasStackSplit == 1 and StackSplitFrame then StackSplitFrame:Hide() end
    end)

    tile:SetScript("OnMouseWheel", function(_, delta) Scene:Scroll(delta) end)
    tile:EnableMouseWheel(true)

    self.tiles[index] = tile
    return tile
end

function Scene:BuildTab(text, id)
    local S = Style()

    local tab = CreateFrame("Button", nil, self.panel)
    tab:SetHeight(26)

    local label = tab:CreateFontString(nil, "OVERLAY")
    label:SetFont(NS.FONT, NS.FS(16), "")
    label:SetPoint("LEFT", tab, "LEFT", 0, 0)
    label:SetText(text)
    tab:SetWidth(label:GetStringWidth() + 4)

    local line = tab:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2)
    line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, -2)
    line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, -2)
    line:SetTexture(WHITE)
    line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)

    tab.label = label
    tab.line = line
    tab.id = id

    tab:SetScript("OnClick", function() Scene:SelectTab(id) end)

    return tab
end

function Scene:BuildPanel()
    local S = Style()
    local screen = UIParent:GetHeight() or 768

    local panel = CreateFrame("Frame", "NarciSirus_MerchantPanel", UIParent)
    panel:SetFrameStrata("HIGH")
    panel:SetSize(PANEL_W, math.max(420, screen - 200))
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 90, -100)
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta) Scene:Scroll(delta) end)
    panel:Hide()
    self.panel = panel

    local name = panel:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(28), "")
    name:SetShadowOffset(1, -1)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    name:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    local rule = panel:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
    rule:SetWidth(PANEL_W * 0.75)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "")
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 1)
    title:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -8)
    title:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    title:SetText(_G.MERCHANT or L["Торговец"])

    local goods = self:BuildTab(L["Товары"], 1)
    goods:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)

    local buyback = self:BuildTab(_G.BUYBACK or L["Выкуп"], 2)
    buyback:SetPoint("LEFT", goods, "RIGHT", 24, 0)

    self.tabs = { goods, buyback }

    local filter = TextButton(panel, "", 150)
    filter:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -82)
    filter:SetScript("OnClick", function()
        if not GetMerchantFilter or not MerchantFrame_SetFilter then return end
        local current = GetMerchantFilter()
        MerchantFrame_SetFilter(nil, current == FILTER_USABLE and FILTER_ALL or FILTER_USABLE)
        Scene.page = 1
        Scene:Refresh()
    end)
    if not GetMerchantFilter then filter:Hide() end
    self.filter = filter

    local search = CreateFrame("EditBox", nil, panel)
    search:SetSize(170, 26)
    search:SetPoint("RIGHT", filter, "LEFT", -8, 0)
    search:SetAutoFocus(false)
    search:SetFont(NS.FONT, NS.FS(12), "")
    search:SetTextInsets(8, 8, 0, 0)
    search:SetTextColor(0.95, 0.95, 0.95)

    local searchGround = search:CreateTexture(nil, "BACKGROUND")
    searchGround:SetAllPoints(search)
    searchGround:SetTexture(WHITE)
    searchGround:SetVertexColor(NS.Styling.Tint(0.02, 0.022, 0.032, 0.92))
    S.CreateEdges(search, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local hint = search:CreateFontString(nil, "OVERLAY")
    hint:SetFont(NS.FONT, NS.FS(12), "")
    hint:SetPoint("LEFT", search, "LEFT", 8, 0)
    hint:SetTextColor(0.5, 0.52, 0.56)
    hint:SetText(L["Поиск"])
    search.hint = hint

    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    search:SetScript("OnTextChanged", function(self, user)
        local text = self:GetText() or ""
        self.hint:SetShown(text == "")
        if not user then return end
        if C_MerchantFrame and C_MerchantFrame.SetTextFilter then
            C_MerchantFrame.SetTextFilter(text)
            if MerchantFrame then MerchantFrame.page = 1 end
            Scene.page = 1
            if MerchantFrame_Update then MerchantFrame_Update() end
            Scene:Refresh()
        end
    end)
    if not (C_MerchantFrame and C_MerchantFrame.SetTextFilter) then search:Hide() end
    self.search = search

    local footer = CreateFrame("Frame", nil, panel)
    footer:SetHeight(64)
    footer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    self.footer = footer

    local grid = CreateFrame("Frame", nil, panel)
    grid:SetPoint("TOPLEFT", goods, "BOTTOMLEFT", 0, -16)
    grid:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 8)
    self.grid = grid

    local prev = TextButton(footer, "<", 30)
    prev:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, -4)
    prev:SetScript("OnClick", function() Scene:Scroll(1) end)

    local pageText = footer:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(NS.FONT, NS.FS(12), "")
    pageText:SetPoint("LEFT", prev, "RIGHT", 10, 0)
    pageText:SetTextColor(0.75, 0.77, 0.80)

    local nextButton = TextButton(footer, ">", 30)
    nextButton:SetPoint("LEFT", pageText, "RIGHT", 10, 0)
    nextButton:SetScript("OnClick", function() Scene:Scroll(-1) end)

    self.prev = prev
    self.next = nextButton
    self.pageText = pageText

    local money = footer:CreateFontString(nil, "OVERLAY")
    money:SetFont(NS.FONT, NS.FS(14), "")
    money:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, -8)
    money:SetTextColor(1, 1, 1)
    self.money = money

    local empty = grid:CreateFontString(nil, "OVERLAY")
    empty:SetFont(NS.FONT, NS.FS(15), "")
    empty:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -10)
    empty:SetWidth(PANEL_W - 20)
    empty:SetJustifyH("LEFT")
    empty:SetTextColor(0.75, 0.77, 0.80)
    empty:Hide()
    self.empty = empty

    local close = TextButton(footer, L["Закрыть"], 110)
    close:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", 0, 0)
    close:SetScript("OnClick", function()
        if MerchantFrame then HideUIPanel(MerchantFrame) end
    end)

    local repairAll = TextButton(footer, "", 230)
    repairAll:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", 0, 0)
    repairAll:SetScript("OnClick", function()
        if MerchantRepairAllButton then MerchantRepairAllButton:Click() end
        Scene:Refresh()
    end)

    local repairOne = TextButton(footer, _G.REPAIR_AN_ITEM or L["Починить предмет"], 150)
    repairOne:SetPoint("LEFT", repairAll, "RIGHT", 6, 0)
    repairOne:SetScript("OnClick", function()
        if MerchantRepairItemButton then MerchantRepairItemButton:Click() end
    end)

    local repairGuild = TextButton(footer, L["За счёт гильдии"], 130)
    repairGuild:SetPoint("LEFT", repairOne, "RIGHT", 6, 0)
    repairGuild:SetScript("OnClick", function()
        if MerchantGuildBankRepairButton then MerchantGuildBankRepairButton:Click() end
        Scene:Refresh()
    end)

    self.repairAll = repairAll
    self.repairOne = repairOne
    self.repairGuild = repairGuild

    local tip = panel:CreateFontString(nil, "OVERLAY")
    tip:SetFont(NS.FONT, NS.FS(11), "")
    tip:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -10)
    tip:SetTextColor(0.55, 0.57, 0.62)
    tip:SetText(L["ПКМ - купить, Shift+ПКМ - выбрать количество. Продажа: ПКМ по предмету в сумках."])

    panel.name = name
    panel.title = title

    self.tiles = {}
end

function Scene:Build()
    if self.panel then return end
    self:BuildDim()
    self:BuildStage()
    self:BuildPanel()
end

function Scene:PerPage()
    local height = self.grid:GetHeight() or 0
    local rows = math.max(1, math.floor((height + TILE_GAP) / (TILE_H + TILE_GAP)))
    return rows * COLUMNS
end

function Scene:Scroll(delta)
    if not self.active then return end
    self.page = (self.page or 1) + (delta > 0 and -1 or 1)
    self:Refresh()
end

function Scene:SelectTab(id)
    if not MerchantFrame then return end
    PanelTemplates_SetTab(MerchantFrame, id)
    self.page = 1
    if MerchantFrame_Update then MerchantFrame_Update() end
    self:Refresh()
end

function Scene:FillGoods(tile, index)
    local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index)
    local canUse, canPurchase, known = true, true, false

    if GetMerchantItemInfoEx then
        canUse, canPurchase, known = GetMerchantItemInfoEx(index)
    end

    local link = MerchantLink(index)
    local r, g, b = QualityColor(link)

    tile:SetID(index)
    tile.hasItem = true
    tile.link = link
    tile.texture = texture
    tile.count = quantity
    tile.extendedCost = extendedCost and true or nil
    tile.price = (price and price > 0) and price or nil

    if not SetIcon(tile.icon, texture, link) then self.missing = true end
    tile.icon:SetDesaturated(known and true or false)

    local usable = isUsable and canUse ~= false
    if usable then
        tile.icon:SetVertexColor(1, 1, 1)
    else
        tile.icon:SetVertexColor(0.9, 0.25, 0.25)
    end

    tile.countText:SetText((quantity and quantity > 1) and quantity or "")

    local label = name or ""
    if known then label = label .. "  |cff6fdc6f" .. L["изучено"] .. "|r" end
    tile.nameText:SetText(label)
    tile.nameText:SetTextColor(r, g, b)

    local cost = CostText(index, price, extendedCost)
    if numAvailable and numAvailable >= 0 then
        cost = cost .. "   |cff9a9ca3" .. L["осталось"] .. " " .. numAvailable .. "|r"
    end
    tile.priceText:SetText(cost)

    tile.frame:SetVertexColor(r * 0.7, g * 0.7, b * 0.7, 1)
    tile.edge:SetVertexColor(r, g, b, 0.9)
    tile:SetAlpha(numAvailable == 0 and 0.5 or 1)
end

function Scene:FillBuyback(tile, index)
    local name, texture, price, quantity = GetBuybackItemInfo(index)
    local link = GetBuybackItemLink and GetBuybackItemLink(index)
    local r, g, b = QualityColor(link)

    tile:SetID(index)
    tile.hasItem = true
    tile.link = link
    tile.texture = texture
    tile.count = quantity
    tile.extendedCost = nil
    tile.price = price

    if not SetIcon(tile.icon, texture, link) then self.missing = true end
    tile.icon:SetDesaturated(false)
    tile.icon:SetVertexColor(1, 1, 1)
    tile.countText:SetText((quantity and quantity > 1) and quantity or "")
    tile.nameText:SetText(name or "")
    tile.nameText:SetTextColor(r, g, b)
    tile.priceText:SetText(Coins(price))
    tile.frame:SetVertexColor(r * 0.7, g * 0.7, b * 0.7, 1)
    tile.edge:SetVertexColor(r, g, b, 0.9)
    tile:SetAlpha(1)
end

function Scene:RefreshFooter()
    self.money:SetText(Coins(GetMoney()))

    local canRepair = CanMerchantRepair and CanMerchantRepair()

    if canRepair then
        local cost, possible = GetRepairAllCost()
        local text = _G.REPAIR_ALL_ITEMS or L["Починить всё"]
        if cost and cost > 0 then text = L["Починить всё"] .. "  " .. Coins(cost) end

        self.repairAll.label:SetText(text)
        self.repairAll:Show()
        self.repairAll:SetUsable(possible and cost and cost > 0)
        self.repairOne:Show()

        local guild = CanGuildBankRepair and CanGuildBankRepair()
        self.repairGuild:SetShown(guild and true or false)
        if guild then self.repairGuild:SetUsable(possible and cost and cost > 0) end
    else
        self.repairAll:Hide()
        self.repairOne:Hide()
        self.repairGuild:Hide()
    end

    if GetMerchantFilter then
        local usable = GetMerchantFilter() == FILTER_USABLE
        self.filter.label:SetText(usable and L["Показать все товары"] or L["Только подходящие"])
    end
end

function Scene:Refresh()
    if not self.active or not self.panel then return end

    local panel = self.panel
    local selected = MerchantFrame and MerchantFrame.selectedTab or 1
    local buyback = selected == 2
    local S = Style()

    panel.name:SetText(UnitName("npc") or "")

    for _, tab in ipairs(self.tabs) do
        local on = tab.id == selected
        tab.line:SetShown(on)
        if on then
            tab.label:SetTextColor(1, 1, 1)
        else
            tab.label:SetTextColor(0.6, 0.62, 0.66)
        end
    end

    self.filter:SetShown(not buyback and GetMerchantFilter ~= nil)
    self.search:SetShown(not buyback and C_MerchantFrame ~= nil and C_MerchantFrame.SetTextFilter ~= nil)

    local total = buyback and (GetNumBuybackItems() or 0) or (GetMerchantNumItems() or 0)
    local perPage = self:PerPage()
    local pages = math.max(1, math.ceil(total / perPage))

    self.page = math.max(1, math.min(pages, self.page or 1))
    self.missing = nil

    for slot = 1, perPage do
        local tile = self.tiles[slot] or self:BuildTile(slot)
        local index = (self.page - 1) * perPage + slot
        local column = (slot - 1) % COLUMNS
        local row = math.floor((slot - 1) / COLUMNS)

        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", self.grid, "TOPLEFT", column * (TILE_W + TILE_GAP), -row * (TILE_H + TILE_GAP))

        if index <= total then
            if buyback then
                self:FillBuyback(tile, index)
            else
                self:FillGoods(tile, index)
            end
            tile:Show()

            if tile:IsMouseOver() and GameTooltip:IsOwned(tile) then
                MerchantItemButton_OnEnter(tile)
            end
        else
            tile.hasItem = nil
            tile.price = nil
            tile.link = nil
            tile:Hide()
        end
    end

    for slot = perPage + 1, #self.tiles do
        self.tiles[slot].hasItem = nil
        self.tiles[slot]:Hide()
    end

    self.pageText:SetText(self.page .. " / " .. pages)
    self.prev:SetUsable(self.page > 1)
    self.next:SetUsable(self.page < pages)

    if total == 0 then
        local text
        if buyback then
            text = L["Нечего выкупать"]
        elseif GetMerchantFilter and GetMerchantFilter() == FILTER_USABLE then
            text = L["Нет товаров, подходящих вашему классу. Нажмите «Показать все товары»."]
        else
            text = L["Ничего не найдено"]
        end
        self.empty:SetText(text)
        self.empty:Show()
        self.pageText:SetText("")
    else
        self.empty:Hide()
    end

    self:RefreshFooter()

    if self.missing and NS.After and (self.retries or 0) < 12 then
        self.retries = (self.retries or 0) + 1
        NS.After(0.6, function() Scene:Refresh() end)
    end
end

function Scene:Open()
    if not Enabled() then return end

    self:Build()

    self.active = true
    self.page = 1
    self.retries = 0

    if GetMerchantFilter and MerchantFrame_SetFilter and GetMerchantFilter() == FILTER_USABLE then
        MerchantFrame_SetFilter(nil, FILTER_ALL)
    end

    Silence(true)
    self:HideHUD()

    local model = self.stage.model
    model:ClearModel()
    if UnitExists("npc") then
        model:SetUnit("npc")
        model:SetFacing(-0.55)
        self.stage:Show()
    else
        self.stage:Hide()
    end

    local S = Style()
    S.FadeIn(self.dim, 0.3)
    S.FadeIn(self.panel, 0.2)

    if self.search then
        local text = C_MerchantFrame and C_MerchantFrame.GetTextFilter and C_MerchantFrame.GetTextFilter() or ""
        self.search:SetText(text or "")
    end

    self:Refresh()

    if NS.After then
        NS.After(0.4, function() Scene:Refresh() end)
    end
end

function Scene:Close()
    if not self.active then return end
    self.active = nil

    if self.search then self.search:ClearFocus() end
    if self.dim then self.dim:Hide() end
    if self.stage then
        self.stage:Hide()
        self.stage.model:ClearModel()
    end
    if self.panel then self.panel:Hide() end

    if StackSplitFrame and StackSplitFrame:IsShown() then StackSplitFrame:Hide() end

    Silence(false)
    self:RestoreHUD()
end

function Scene:HideHUD()
    local dialogue = NS.Dialogue
    if dialogue and dialogue.hidHUD then
        dialogue.hidHUD = nil
        self.hidHUD = true
        self.hiddenMap = dialogue.hiddenMap
        dialogue.hiddenMap = nil
        return
    end

    if self.hidHUD or not HideInterface() or InCombatLockdown() then return end

    local ui = NS.NarciUI
    if not ui or ui.isShown or not ui.HideOtherAddons then return end

    self.hidHUD = true
    pcall(ui.HideOtherAddons, ui)

    self.hiddenMap = {}
    for _, name in ipairs({ "MinimapCluster", "Minimap", "NarciSirus_MinimapFrame" }) do
        local frame = _G[name]
        if frame and frame:IsShown() then
            frame:Hide()
            self.hiddenMap[#self.hiddenMap + 1] = frame
        end
    end
end

function Scene:RestoreHUD()
    if not self.hidHUD then return end
    self.hidHUD = nil

    local ui = NS.NarciUI
    if ui and not ui.isShown and ui.RestoreOtherAddons then
        pcall(ui.RestoreOtherAddons, ui)
    end

    for _, frame in ipairs(self.hiddenMap or {}) do frame:Show() end
    self.hiddenMap = nil
end

function Scene:Hook()
    if self.hooked or not MerchantFrame then return end
    self.hooked = true

    MerchantFrame:HookScript("OnShow", function()
        if Enabled() then
            Scene:Open()
        else
            Silence(false)
        end
    end)

    MerchantFrame:HookScript("OnHide", function()
        Scene:Close()
    end)

    if type(_G.MerchantFrame_Update) == "function" then
        hooksecurefunc("MerchantFrame_Update", function()
            if Scene.active then Scene:Refresh() end
        end)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_MONEY")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")

driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Scene:Hook()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        Scene:RestoreHUD()
        return
    end

    if Scene.active then Scene:Refresh() end
end)
