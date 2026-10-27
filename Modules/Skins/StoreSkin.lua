local addonName, NS = ...

local StoreSkin = {}
NS.StoreSkin = StoreSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local CHROME_KEYS = {
    "Left", "Center", "Right",
    "LeftHighlight", "CenterHighlight", "RightHighlight",
    "BackgroundLeft", "BackgroundCenter", "BackgroundRight",
    "NineSlice", "NineSliceInset", "NineSliceBorder", "NineSliceGlow",
    "NineSliceSelection", "NineSliceHighlight",
    "Background", "BackgroundBottom", "TopTileStreaks",
    "ShadowTop", "ShadowBottom", "ShadowLeft", "ShadowRight",
    "ShadowTopLeft", "ShadowTopRight", "ShadowBottomLeft", "ShadowBottomRight",
    "ShadowBackground", "ShadowOverlay",
    "DecorTop", "DecorBottom", "DecorFooter", "DecorOverlay",
    "VignetteBottomLeft", "VignetteBottomRight",
}

local STATE_TEXTURES = {
    "SetNormalTexture", "SetHighlightTexture", "SetPushedTexture",
    "SetDisabledTexture", "SetCheckedTexture", "SetDisabledCheckedTexture",
}

local STATE_ATLASES = {
    "SetThreeSliceAtlas", "SetNormalAtlas", "SetHighlightAtlas", "SetPushedAtlas",
    "SetCheckedAtlas", "SetDisabledAtlas", "UpdateButton",
}

local INTERVAL = 0.35
local SCREEN_SHARE = 0.62
local SWEEP_DEPTH = 10
local SWEEP_NODES = 4000

local lastError
local hooked = false

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinStore ~= false
end

local function IsObject(value)
    return type(value) == "table" and type(value.GetObjectType) == "function"
end

local function Chrome(frame)
    if not IsObject(frame) then return end

    for _, key in ipairs(CHROME_KEYS) do
        local region = frame[key]
        if IsObject(region) then
            if region.SetAlpha then region:SetAlpha(0) end
            if region.GetObjectType and region:GetObjectType() == "Frame" then region:Hide() end
        end
    end

    if NS.SkinKit then NS.SkinKit.ClearStates(frame) end
end

local function KeepChromeClear(frame)
    if frame.narciChromeHook then return end
    frame.narciChromeHook = true

    for _, method in ipairs(STATE_ATLASES) do
        if frame[method] then
            hooksecurefunc(frame, method, function(self) Chrome(self) end)
        end
    end

    if frame.HookScript then
        frame:HookScript("OnShow", function(self) Chrome(self) end)
    end
end

local function Ground(frame)
    if frame.narciGround then return frame.narciGround end

    local base = frame:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints(frame)
    base:SetTexture(WHITE)
    base:SetGradientAlpha("VERTICAL",
        0.016, 0.018, 0.026, 0.97,
        0.045, 0.050, 0.068, 0.97)

    frame.narciGround = base
    return base
end

local function Panel(frame, alpha)
    if frame.narciPanel then return frame.narciPanel end
    alpha = (alpha or 0.55) * 0.35

    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetAllPoints(frame)
    fill:SetTexture(WHITE)
    fill:SetGradientAlpha("VERTICAL",
        0.000, 0.000, 0.000, alpha,
        0.030, 0.034, 0.046, 0)

    frame.narciPanel = fill
    return fill
end

local function FadeLine(frame, edge, inset)
    local S = Style()
    inset = inset or 12

    local first = frame:CreateTexture(nil, "ARTWORK")
    local second = frame:CreateTexture(nil, "ARTWORK")

    first:SetTexture(WHITE)
    second:SetTexture(WHITE)

    if edge == "RIGHT" then
        first:SetWidth(1)
        second:SetWidth(1)
        first:SetPoint("TOP", frame, "TOPRIGHT", 0, -inset)
        first:SetPoint("BOTTOM", frame, "RIGHT", 0, 0)
        second:SetPoint("TOP", frame, "RIGHT", 0, 0)
        second:SetPoint("BOTTOM", frame, "BOTTOMRIGHT", 0, inset)
        first:SetGradientAlpha("VERTICAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.32,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
        second:SetGradientAlpha("VERTICAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.32)
    else
        first:SetHeight(1)
        second:SetHeight(1)
        first:SetPoint("LEFT", frame, "BOTTOMLEFT", inset, 0)
        first:SetPoint("RIGHT", frame, "BOTTOM", 0, 0)
        second:SetPoint("LEFT", frame, "BOTTOM", 0, 0)
        second:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -inset, 0)
        first:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.03,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)
        second:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.03)
    end
end

local function CardFace(frame)
    if frame.narciCard then return end
    frame.narciCard = true

    local S = Style()

    local overlay = frame.Overlay
    if IsObject(overlay) then
        Chrome(overlay)
        if IsObject(overlay.Border) then overlay.Border:SetAlpha(0) end
        if IsObject(overlay.Shadow) then overlay.Shadow:SetAlpha(0) end
    end

    local halo = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    halo:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    halo:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    halo:SetTexture(WHITE)
    halo:SetGradientAlpha("VERTICAL",
        0.00, 0.00, 0.00, 0.00,
        S.ACCENT[1] * 0.35, S.ACCENT[2] * 0.35, S.ACCENT[3] * 0.35, 0.16)

    local base = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
    base:SetHeight(1)
    base:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 8)
    base:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 8)
    base:SetTexture(WHITE)
    base:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.04,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30)

    if frame.SetHighlightTexture then
        frame:SetHighlightTexture(WHITE)
        local highlight = frame:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.07)
            highlight:ClearAllPoints()
            highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
            highlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
        end
    end
end

local function ButtonFace(button, plain)
    if button.narciButton then return end
    button.narciButton = true

    local S = Style()

    if not plain then
        local under = button:CreateTexture(nil, "BORDER")
        under:SetHeight(1)
        under:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6, 3)
        under:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 3)
        under:SetTexture(WHITE)
        under:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.75)
    end

    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE)
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
            highlight:ClearAllPoints()
            highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        end
    end
end

local function IsThreeSlice(frame)
    return IsObject(frame.Left) and IsObject(frame.Center) and IsObject(frame.Right)
        and frame.Left.SetTexture ~= nil
end

local function SkinPrice(frame)
    local price = frame.Price
    if not IsObject(price) or price.narciPrice then return end
    price.narciPrice = true

    local S = Style()

    if price.Value then
        price.Value:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    end

    if price.ValueOriginal then
        price.ValueOriginal:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if IsObject(price.StrikeThrough) then
        price.StrikeThrough:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end
end

local function PricePlate(button)
    if button.narciPlate then return end
    button.narciPlate = true

    local S = Style()

    local height = button:GetHeight() or 26
    local inset = math.max(3, (height - 26) / 2)

    local fill = button:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -inset)
    fill:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, inset)
    fill:SetTexture(WHITE)
    fill:SetGradientAlpha("VERTICAL",
        0.020, 0.023, 0.032, 0.95,
        0.055, 0.062, 0.082, 0.95)

    local edges = {}

    for index = 1, 4 do
        local line = button:CreateTexture(nil, "BORDER")
        line:SetTexture(WHITE)
        line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("BOTTOMLEFT", fill, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("BOTTOMRIGHT", fill, "TOPRIGHT", 0, 0)

    edges[2]:SetHeight(1)
    edges[2]:SetPoint("TOPLEFT", fill, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("TOPRIGHT", fill, "BOTTOMRIGHT", 0, 0)

    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPRIGHT", fill, "TOPLEFT", 0, 1)
    edges[3]:SetPoint("BOTTOMRIGHT", fill, "BOTTOMLEFT", 0, -1)

    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 1)
    edges[4]:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, -1)

    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE)
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.14)
            highlight:ClearAllPoints()
            highlight:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
            highlight:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
        end
    end

    button:HookScript("OnEnter", function()
        for _, line in ipairs(edges) do
            line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        end
    end)

    button:HookScript("OnLeave", function()
        for _, line in ipairs(edges) do
            line:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)
        end
    end)
end

local function SkinButton(button)
    if not IsObject(button) then return end

    local priced = IsObject(button.Price)

    Chrome(button)
    ButtonFace(button, priced)
    KeepChromeClear(button)
    SkinPrice(button)

    if priced then PricePlate(button) end

    local text = button.GetFontString and button:GetFontString()
    if text and not button.narciText then
        button.narciText = true
        local S = Style()
        text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end
end

local function Sweep(frame, depth, count)
    if count > SWEEP_NODES then return count end

    if IsThreeSlice(frame) then SkinButton(frame) end
    if IsObject(frame.Price) then SkinPrice(frame) end

    count = count + 1
    if depth >= SWEEP_DEPTH then return count end

    for _, child in ipairs({ frame:GetChildren() }) do
        if IsObject(child) and child.GetChildren then
            count = Sweep(child, depth + 1, count)
        end
    end

    return count
end

local function Share()
    local value = NS.db and tonumber(NS.db.storeScale)
    if value and value >= 0.35 and value <= 1 then return value end
    return SCREEN_SHARE
end

local function FitScale(frame)
    local width, height = frame:GetWidth(), frame:GetHeight()
    if not width or not height or width < 1 or height < 1 then return end

    local share = Share()
    local scale = math.min(1,
        GetScreenWidth() * share / width,
        GetScreenHeight() * share / height)

    if scale < 0.5 then scale = 0.5 end
    if math.abs((frame:GetScale() or 1) - scale) > 0.005 then
        frame:SetScale(scale)
    end
end

local function RowFace(button, width)
    if button.narciRow then return end
    button.narciRow = true

    local S = Style()

    local mark = button:CreateTexture(nil, "BORDER")
    mark:SetWidth(width or 3)
    mark:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -3)
    mark:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 3)
    mark:SetTexture(WHITE)
    mark:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    mark:Hide()

    local glow = button:CreateTexture(nil, "BACKGROUND", nil, 3)
    glow:SetAllPoints(button)
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.00)
    glow:Hide()

    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE)
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.08)
            highlight:ClearAllPoints()
            highlight:SetAllPoints(button)
        end
    end

    button.narciMark = mark
    button.narciGlow = glow
end

local function UpdateRowState(button)
    if not IsObject(button) or not button.narciMark then return end

    local checked = false
    if type(button.GetChecked) == "function" then
        local ok, value = pcall(button.GetChecked, button)
        checked = ok and value and true or false
    end

    button.narciMark:SetShown(checked)
    button.narciGlow:SetShown(checked)
end

local function SkinCategory(button, width)
    if not IsObject(button) then return end

    Chrome(button)
    RowFace(button, width)
    KeepChromeClear(button)
    UpdateRowState(button)
end

local function SkinTab(button)
    if not IsObject(button) then return end

    Chrome(button)

    if not button.narciTab then
        button.narciTab = true

        local S = Style()

        local under = button:CreateTexture(nil, "BORDER")
        under:SetHeight(2)
        under:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6, 2)
        under:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 2)
        under:SetTexture(WHITE)
        under:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
        under:Hide()

        if button.SetHighlightTexture then
            button:SetHighlightTexture(WHITE)
            local highlight = button:GetHighlightTexture()
            if highlight then
                highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.10)
                highlight:ClearAllPoints()
                highlight:SetAllPoints(button)
            end
        end

        button.narciTabLine = under
        KeepChromeClear(button)
    end

    if type(button.GetChecked) == "function" then
        local ok, checked = pcall(button.GetChecked, button)
        button.narciTabLine:SetShown(ok and checked and true or false)
    end
end

local function SkinScrollBar(bar)
    if not IsObject(bar) or bar.narciScroll then return end
    bar.narciScroll = true

    local S = Style()

    Chrome(bar)

    for _, key in ipairs({ "Track", "Top", "Bottom", "Middle" }) do
        local piece = bar[key]
        if IsObject(piece) and piece.SetAlpha then piece:SetAlpha(0) end
    end

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, 0)
    track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)
    track:SetTexture(WHITE)
    track:SetVertexColor(0.05, 0.055, 0.075, 0.7)

    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture(WHITE)
        thumb:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.95)
    end
end

local function SkinEditBox(box)
    if not IsObject(box) or box.narciEdit then return end
    box.narciEdit = true

    local S = Style()

    Chrome(box)

    local fill = box:CreateTexture(nil, "BACKGROUND", nil, 2)
    fill:SetAllPoints(box)
    fill:SetTexture(WHITE)
    fill:SetVertexColor(NS.Styling.Tint(0.030, 0.034, 0.046, 0.92))

    local under = box:CreateTexture(nil, "BORDER")
    under:SetHeight(1)
    under:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 2, 1)
    under:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2, 1)
    under:SetTexture(WHITE)
    under:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.9)
end

local function SkinHeader(panel, anchor)
    if not IsObject(panel) or panel.narciHeader then return end
    panel.narciHeader = true

    local S = Style()

    if anchor and anchor.SetTextColor then
        anchor:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end

    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetWidth(240)
    line:SetTexture(WHITE)

    if anchor and anchor.GetObjectType then
        line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    else
        line:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 6)
    end

    line:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
end

local function SkinDialog(dialog)
    if not IsObject(dialog) or dialog.narciDialog then return end
    dialog.narciDialog = true

    Chrome(dialog)
    Ground(dialog)
    Style().CreateShadow(dialog, 5, 0.5)
    Style().CreateGradientTopBorder(dialog, 2)

    for _, child in ipairs({ dialog:GetChildren() }) do
        if IsObject(child) and child.IsObjectType and child:IsObjectType("Button") then
            SkinButton(child)
        end
    end
end

local function SkinTopPanel(frame)
    local top = frame.TopPanel
    if not IsObject(top) then return end

    if not top.narciTop then
        top.narciTop = true
        Chrome(top)
        Panel(top, 0.5)
        FadeLine(top, "BOTTOM", 24)
    end

    for _, key in ipairs({ "BalancePanel", "VotePanel", "LoyalityPanel", "ReferralPanel" }) do
        local panel = top[key]
        if IsObject(panel) then
            if IsObject(panel.Divider) then panel.Divider:SetAlpha(0) end
            if IsObject(panel.Button) then SkinButton(panel.Button) end
            if IsObject(panel.AddButton) then SkinButton(panel.AddButton) end

            local bar = panel.StatusBar
            if IsObject(bar) and not bar.narciBar then
                bar.narciBar = true
                local S = Style()
                local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
                if texture then
                    texture:SetTexture(WHITE)
                    texture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
                end
            end
        end
    end
end

local function SkinCategories(frame)
    for _, button in ipairs(frame.categoryButtons or {}) do
        SkinCategory(button, 3)

        local menu = button.SubCategoryMenu
        if IsObject(menu) then
            if not menu.narciMenu then
                menu.narciMenu = true
                Chrome(menu)
                Panel(menu, 0.45)
            end

            for _, sub in ipairs(menu.subCategoryButtons or {}) do
                SkinCategory(sub, 2)
            end
        end
    end
end

local function SkinLeftPanel(frame)
    local left = frame.LeftPanel
    if not IsObject(left) then return end

    local nav = left.NavPanel
    if IsObject(nav) and not nav.narciNav then
        nav.narciNav = true
        Chrome(nav)
        Panel(nav, 0.65)
        FadeLine(nav, "RIGHT", 20)
    end

    local premium = left.PremiumPanel
    if IsObject(premium) then
        if not premium.narciPremium then
            premium.narciPremium = true
            Chrome(premium)
            Panel(premium, 0.55)
        end
        if IsObject(premium.Purchase) then SkinButton(premium.Purchase) end
    end

    local tracker = left.SubscriptionTracker
    if IsObject(tracker) then
        if not tracker.narciTracker then
            tracker.narciTracker = true
            Chrome(tracker)
            Panel(tracker, 0.55)
        end
        if IsObject(tracker.ActionButton) then SkinButton(tracker.ActionButton) end
    end

    SkinCategories(frame)
end

local function SkinPaginator(paginator)
    if not IsObject(paginator) then return end

    if IsObject(paginator.Background) then paginator.Background:SetAlpha(0) end

    for _, child in ipairs({ paginator:GetChildren() }) do
        if IsObject(child) and child.Background then
            Chrome(child)
            CardFace(child)
            if IsObject(child.PurchaseButton) then SkinButton(child.PurchaseButton) end
            if IsObject(child.DetailsButton) then SkinButton(child.DetailsButton) end
            if IsObject(child.ActionButton) then SkinButton(child.ActionButton) end
        end
    end
end

local function SkinContent(frame)
    local content = frame.Content
    if not IsObject(content) then return end

    if not content.narciContent then
        content.narciContent = true
        Chrome(content)
    end

    local main = content.PageMain
    if IsObject(main) then
        local special = main.SpecialPanel
        local banner = IsObject(special) and special.Banner

        if IsObject(banner) then
            if not banner.narciBanner then
                banner.narciBanner = true
                Chrome(banner)
                CardFace(banner)
            end

            local offer = banner.Offer
            if IsObject(offer) then
                if IsObject(offer.ShadowBackground) then offer.ShadowBackground:SetAlpha(0) end
                if IsObject(offer.ActionButton) then SkinButton(offer.ActionButton) end
                if IsObject(offer.PurchaseButton) then SkinButton(offer.PurchaseButton) end
                if IsObject(offer.DetailsButton) then SkinButton(offer.DetailsButton) end
            end
        end

        local panel = main.RecommendationPanel
        if IsObject(panel) then
            SkinHeader(panel, panel.Header)
            SkinPaginator(panel.Paginator)
        end
    end

    for _, key in ipairs({ "PageCollections", "PageSubscriptions", "PageServices",
        "PageEquipment", "PageTransmogrification", "PageLoyality", "PageReferral",
        "PageVote", "RefundView" }) do
        local page = content[key]

        if IsObject(page) then
            local header = IsObject(page.PageHeader) and page.PageHeader
                or (IsObject(page.List) and IsObject(page.List.PageHeader) and page.List.PageHeader)

            if IsObject(header) then
                Chrome(header)
                SkinHeader(header, header.Text)
            end

            for _, name in ipairs({ "RefreshButton", "RefundButton", "BrowseAll", "Refund" }) do
                if IsObject(page[name]) then SkinButton(page[name]) end
            end

            for _, name in ipairs({ "Scroll", "ListScrollFrame" }) do
                local scroll = page[name]
                if IsObject(scroll) and IsObject(scroll.ScrollBar) then
                    SkinScrollBar(scroll.ScrollBar)
                end
            end

            for _, tab in pairs(page.tabButtons or {}) do
                SkinTab(tab)
            end

            SkinPaginator(page.Paginator)
        end
    end
end

local function SkinListView(frame)
    local view = frame.ItemListView
    if not IsObject(view) then return end

    if not view.narciList then
        view.narciList = true
        Chrome(view)
    end

    if IsObject(view.ScrollBar) then SkinScrollBar(view.ScrollBar) end
    if IsObject(view.Scroll) and IsObject(view.Scroll.ScrollBar) then
        SkinScrollBar(view.Scroll.ScrollBar)
    end

    local rows = view.buttons
    if not rows and IsObject(view.Scroll) then rows = view.Scroll.buttons end

    for _, row in ipairs(rows or {}) do
        if IsObject(row) then
            Chrome(row)
            RowFace(row, 2)
        end
    end

    for _, header in ipairs(view.headerButtons or {}) do
        if IsObject(header) then
            Chrome(header)
            KeepChromeClear(header)
        end
    end

    local filters = view.FilterHolder or view.Filters
    if IsObject(filters) then
        if not filters.narciFilters then
            filters.narciFilters = true
            Chrome(filters)
            Panel(filters, 0.5)
        end

        for _, child in ipairs({ filters:GetChildren() }) do
            if IsObject(child) and child.IsObjectType then
                if child:IsObjectType("EditBox") then
                    SkinEditBox(child)
                elseif child:IsObjectType("Button") then
                    SkinButton(child)
                end
            end
        end
    end
end

local function SkinPromo()
    local promo = _G.PromoCodeFrame
    if not IsObject(promo) or promo.narciPromo then return end
    promo.narciPromo = true

    Chrome(promo)
    Ground(promo)
    Style().CreateShadow(promo, 5, 0.5)
    Style().CreateGradientTopBorder(promo, 2)

    local content = promo.Content
    if IsObject(content) then
        if IsObject(content.ActionButton) then SkinButton(content.ActionButton) end
        if IsObject(content.Code) and IsObject(content.Code.EditBox) then
            SkinEditBox(content.Code.EditBox)
        end
        if IsObject(content.Scroll) and IsObject(content.Scroll.ScrollBar) then
            SkinScrollBar(content.Scroll.ScrollBar)
        end
    end
end

local function SkinFrame(frame)
    if frame.narciStoreFrame then return end
    frame.narciStoreFrame = true

    local S = Style()

    Chrome(frame)
    Ground(frame)
    S.CreateShadow(frame, 6, 0.5)
    S.CreateGradientTopBorder(frame, 2)

    local title = frame.TitleContainer
    if IsObject(title) then
        Chrome(title)
        if title.TitleText then
            title.TitleText:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        end
    end
end

local function InstallHooks(frame)
    if hooked then return end
    hooked = true

    if frame.UpdateCategoryButtons then
        hooksecurefunc(frame, "UpdateCategoryButtons", function(self)
            for _, button in ipairs(self.categoryButtons or {}) do
                SkinCategory(button, 3)
            end
        end)
    end

    if _G.StoreCategorySubMenuMixin then
        hooksecurefunc(_G.StoreCategorySubMenuMixin, "UpdateSubCategories", function(self)
            for _, button in ipairs(self.subCategoryButtons or {}) do
                SkinCategory(button, 2)
            end
        end)
    end

    if _G.StoreRecommendationMixin then
        hooksecurefunc(_G.StoreRecommendationMixin, "OnShow", function(self)
            Chrome(self)
            CardFace(self)
            if IsObject(self.PurchaseButton) then SkinButton(self.PurchaseButton) end
            if IsObject(self.DetailsButton) then SkinButton(self.DetailsButton) end
        end)
    end

    local view = frame.ItemListView
    if IsObject(view) then
        for _, method in ipairs({ "UpdateViewTable", "OnItemScrollUpdate", "OnShow", "UpdateFilters" }) do
            if view[method] then
                hooksecurefunc(view, method, function() SkinListView(frame) end)
            end
        end
    end

    local collections = IsObject(frame.Content) and frame.Content.PageCollections
    if IsObject(collections) and collections.UpdateTabs then
        hooksecurefunc(collections, "UpdateTabs", function(self)
            for _, tab in pairs(self.tabButtons or {}) do
                SkinTab(tab)
            end
        end)
    end

    if frame.ShowDialogWidget then
        hooksecurefunc(frame, "ShowDialogWidget", function(self, widgetType)
            local dialog = self.GetDialogWidget and self:GetDialogWidget(widgetType)
            if dialog then SkinDialog(dialog) end
        end)
    end
end

local function ChromeTree(frame, depth)
    if not IsObject(frame) or depth > 6 or frame.narciOwn then return end
    for _, key in ipairs(CHROME_KEYS) do
        local region = frame[key]
        if IsObject(region) then
            if region.SetAlpha then region:SetAlpha(0) end
            if region:GetObjectType() == "Frame" then region:Hide() end
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        ChromeTree(child, depth + 1)
    end
end

function StoreSkin.Generic(frame)
    if not IsObject(frame) then return end
    if not frame.narciGeneric then
        frame.narciGeneric = true
        SkinFrame(frame)
        KeepChromeClear(frame)
        Style().Decorate(frame, true)
        if IsObject(frame.CloseButton) and NS.SkinKit then NS.SkinKit.Close(frame.CloseButton) end
    end
    ChromeTree(frame, 0)
    Sweep(frame, 0, 0)
end

function StoreSkin:Apply()
    local frame = _G.StoreFrame
    if not frame or not Enabled() then return end

    SkinFrame(frame)
    SkinTopPanel(frame)
    SkinLeftPanel(frame)
    SkinContent(frame)
    SkinListView(frame)
    SkinPromo()
    InstallHooks(frame)
    FitScale(frame)

    pcall(Sweep, frame, 0, 0)

    for _, key in ipairs({ "LinkDialog", "AgreementDialog", "ReferralInviteDialog",
        "PremiumPurchaseDialog", "ProductPurchaseDialog", "ProductPurchaseDialogSecondary" }) do
        SkinDialog(frame[key])
    end

    for _, button in ipairs(frame.categoryButtons or {}) do
        UpdateRowState(button)

        local menu = button.SubCategoryMenu
        if IsObject(menu) then
            for _, sub in ipairs(menu.subCategoryButtons or {}) do
                UpdateRowState(sub)
            end
        end
    end
end

function StoreSkin:SetShare(value)
    value = tonumber(value)

    if not value or value < 0.35 or value > 1 then
        NS.Print("укажите долю экрана от 0.35 до 1, например /narci store scale 0.6")
        return
    end

    NS.db.storeScale = value

    local frame = _G.StoreFrame
    if frame then FitScale(frame) end

    NS.Print("размер окна магазина: " .. value)
end

function StoreSkin:Status()
    local frame = _G.StoreFrame

    NS.Print("skinStore: " .. tostring(Enabled()))
    NS.Print("StoreFrame: " .. tostring(frame ~= nil)
        .. ", применён: " .. tostring(frame ~= nil and frame.narciStoreFrame == true))
    NS.Print("категорий: " .. tostring(frame and #(frame.categoryButtons or {}) or 0)
        .. ", хуки: " .. tostring(hooked))
    NS.Print("ошибка: " .. tostring(lastError))
end

function StoreSkin:Redo()
    local frame = _G.StoreFrame
    if not frame then return end

    lastError = nil

    local ok, err = pcall(function() self:Apply() end)
    if not ok then lastError = tostring(err) end

    self:Status()
end

local driver = CreateFrame("Frame")
driver.elapsed = 0
driver:Hide()

driver:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < INTERVAL then return end
    self.elapsed = 0

    local frame = _G.StoreFrame
    if not frame or not frame:IsShown() then
        self:Hide()
        return
    end

    local ok, err = pcall(function() StoreSkin:Apply() end)
    if not ok then lastError = tostring(err) end
end)

function StoreSkin:Start()
    if not Enabled() then return end

    local ok, err = pcall(function() self:Apply() end)
    if not ok then
        lastError = tostring(err)
        NS.Print("скин магазина: " .. tostring(err))
    end

    driver.elapsed = 0
    driver:Show()
end

function StoreSkin:Hook()
    local frame = _G.StoreFrame
    if not frame or frame.narciStoreHook then return end
    frame.narciStoreHook = true

    frame:HookScript("OnShow", function() StoreSkin:Start() end)
    frame:HookScript("OnHide", function() driver:Hide() end)

    if frame:IsShown() then self:Start() end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event)
    StoreSkin:Hook()
end)
