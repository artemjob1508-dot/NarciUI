local addonName, NS = ...

local MerchantSkin = {}
NS.MerchantSkin = MerchantSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local SLOTS = 12

local OWN_FRAMES = { "MerchantMoneyFrame", "MerchantBuyBackItemMoneyFrame" }

local function Kit()
    return NS.SkinKit
end

local function Mail()
    return NS.MailSkin
end

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinMerchant ~= false
end

local function Card(item)
    if not item or item.narciCard then return end
    item.narciCard = true
    item.narciOwn = true

    local S = Style()
    local name = item:GetName()
    local M = Mail()

    M.Hide(_G[name .. "SlotTexture"])

    M.Hide(_G[name .. "NameFrame"])

    local card = item:CreateTexture(nil, "BACKGROUND")
    card:SetPoint("TOPLEFT", item, "TOPLEFT", -2, 2)
    card:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 2, -2)
    card:SetTexture(WHITE)
    card:SetGradientAlpha("HORIZONTAL", 0.040, 0.046, 0.064, 0.92, 0.016, 0.018, 0.026, 0.55)

    local tint = item:CreateTexture(nil, "BORDER")
    tint:SetAllPoints(card)
    tint:SetTexture(WHITE)
    tint:SetAlpha(0.10)
    tint:SetVertexColor(0.5, 0.5, 0.5)
    item.narciTint = tint

    local rule = item:CreateTexture(nil, "BORDER")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 0)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)

    local button = _G[name .. "ItemButton"]
    if button then
        M.Slot(button)
        button:SetFrameLevel(item:GetFrameLevel() + 2)
    end

    local text = _G[name .. "Name"]
    if text and button then
        text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        text:ClearAllPoints()
        text:SetPoint("TOPLEFT", button, "TOPRIGHT", 6, 1)
        text:SetPoint("RIGHT", item, "RIGHT", -2, 0)
        text:SetHeight(24)
        text:SetJustifyV("TOP")
    end

    item.narciButton = button
end

local function PlacePrice(item)
    local button = item and item.narciButton
    if not button then return end

    local name = item:GetName()
    local money = _G[name .. "MoneyFrame"]
    local alt = _G[name .. "AltCurrencyFrame"]

    if money then
        money:ClearAllPoints()
        money:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 4, -1)
    end

    if alt and alt:IsShown() and not (money and money:IsShown()) then
        alt:ClearAllPoints()
        alt:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 4, -1)
    end
end

local function QualityColor(link)
    if not link then return end

    local _, _, quality = GetItemInfo(link)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if color and quality > 1 then return color.r, color.g, color.b end
end

local function Dress(item, r, g, b)
    local db = NS.db or {}
    local S = Style()
    local tint = item.narciTint
    local strength = db.merchantTint or 0
    if tint then
        if strength > 0 and r then
            tint:SetVertexColor(r, g, b)
            tint:SetAlpha(strength / 100)
        else
            tint:SetVertexColor(0.5, 0.5, 0.5)
            tint:SetAlpha(0.10)
        end
    end
    local text = _G[item:GetName() .. "Name"]
    if text then
        if db.merchantQualityNames and r then
            text:SetTextColor(r, g, b)
        else
            text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end
end

function MerchantSkin:Paint()
    local frame = _G.MerchantFrame
    if not frame or not frame.narciMerchant then return end

    local M = Mail()
    local buyback = frame.selectedTab == 2

    for index = 1, SLOTS do
        local item = _G["MerchantItem" .. index]
        local button = item and item.narciButton

        if button and item:IsShown() then
            PlacePrice(item)

            local id = button:GetID()
            local link

            if buyback then
                link = GetBuybackItemLink and GetBuybackItemLink(id)
            else
                link = GetMerchantItemLink and GetMerchantItemLink(id)
            end

            M.PaintSlotColor(button, QualityColor(link))
            Dress(item, QualityColor(link))
        end
    end

    local back = _G.MerchantBuyBackItem
    if back and back.narciButton then
        PlacePrice(back)

        local count = GetNumBuybackItems and GetNumBuybackItems() or 0
        local link = count > 0 and GetBuybackItemLink and GetBuybackItemLink(count)
        M.PaintSlotColor(back.narciButton, QualityColor(link))
        Dress(back, QualityColor(link))
    end
end

function MerchantSkin:Skin()
    local frame = _G.MerchantFrame
    if not frame or frame.narciMerchant then return end
    frame.narciMerchant = true

    local K = Kit()
    local M = Mail()
    local S = Style()

    for _, key in ipairs(OWN_FRAMES) do
        local own = _G[key]
        if own then own.narciOwn = true end
    end

    M.Window(frame)

    for index = 1, SLOTS do Card(_G["MerchantItem" .. index]) end
    Card(_G.MerchantBuyBackItem)

    M.Hide(_G.MerchantFrameBottomLeftBorder)
    M.Hide(_G.MerchantFrameBottomRightBorder)
    M.Hide(_G.MerchantFramePortrait)

    if _G.BuybackBG then
        _G.BuybackBG:SetTexture(WHITE)
        _G.BuybackBG:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)
    end

    for _, key in ipairs({ "MerchantExtraCurrencyInset", "MerchantMoneyInset",
        "MerchantExtraCurrencyBg", "MerchantMoneyBg" }) do
        local box = _G[key]
        if box then
            K.Strip(box, 2)
            M.Hide(box.NineSlice)
            M.Hide(box.Bg)
            M.DimByPath(box)
            if key:find("Inset") then K.Inset(box, 0.30) end
        end
    end

    if frame.lootFilter then
        frame.lootFilter.narciOwn = nil
        pcall(K.Dropdown, frame.lootFilter)
    end

    K.Auto(frame, 8)

    for index = 1, 2 do
        local tab = _G["MerchantFrameTab" .. index]
        if tab then K.Tab(tab, (frame.selectedTab or 1) == index) end
    end

    local title = _G.MerchantNameText
    if title then title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]) end

    local page = _G.MerchantPageText
    if page then page:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]) end

    local repair = _G.MerchantRepairText
    if repair then repair:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3]) end

    self:Paint()
end

function MerchantSkin:Hook()
    if self.hooked then return end
    self.hooked = true

    if type(_G.SetItemButtonNameFrameVertexColor) == "function" then
        hooksecurefunc("SetItemButtonNameFrameVertexColor", function(button, r, g, b)
            local tint = button and button.narciTint
            if tint then tint:SetVertexColor(r, g, b) end
        end)
    end

    for _, name in ipairs({ "MerchantFrame_UpdateMerchantInfo", "MerchantFrame_UpdateBuybackInfo" }) do
        if type(_G[name]) == "function" then
            hooksecurefunc(name, function()
                if Enabled() then MerchantSkin:Paint() end
            end)
        end
    end
end

function MerchantSkin:Apply()
    if not Enabled() or not Kit() or not Mail() or not Mail().Slot then return end

    self:Hook()

    local ok, err = pcall(function() MerchantSkin:Skin() end)
    if not ok and NS.Print then NS.Print("торговец: " .. tostring(err)) end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("MERCHANT_SHOW")

driver:SetScript("OnEvent", function()
    MerchantSkin:Apply()
end)
