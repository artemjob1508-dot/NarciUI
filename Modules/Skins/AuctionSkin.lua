local addonName, NS = ...

local AuctionSkin = {}
NS.AuctionSkin = AuctionSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local ATLAS_FILE = "auctionframe[/\\]auctionhouse"

local ATLAS_STYLE = {
    ["auctionhouse-nav-button"] = "card",
    ["auctionhouse-nav-button-secondary"] = "card",
    ["auctionhouse-nav-button-highlight"] = "hover",
    ["auctionhouse-nav-button-secondary-highlight"] = "hover",
    ["auctionhouse-nav-button-select"] = "select",
    ["auctionhouse-nav-button-secondary-select"] = "select",
    ["auctionhouse-nav-button-tertiary-filterline"] = "hide",
    ["auctionhouse-ui-row-highlight"] = "hover",
    ["auctionhouse-ui-row-select"] = "select",
    ["auctionhouse-rowstripe-1"] = "hide",
    ["auctionhouse-rowstripe-2"] = "hide",
    ["auctionhouse-background-categories"] = "hide",
    ["auctionhouse-itemheaderframe"] = "hide",
    ["auctionhouse-selltab-left"] = "hide",
    ["auctionhouse-selltab-middle"] = "hide",
    ["auctionhouse-selltab-right"] = "hide",
    ["auctionhouse-ui-inputfield-left"] = "hide",
    ["auctionhouse-ui-inputfield-middle"] = "hide",
    ["auctionhouse-ui-inputfield-right"] = "hide",
    ["auctionhouse-itemicon-empty"] = "hide",
}

local PANELS = {
    "AuctionHouseFrameCategoriesList",
    "AuctionHouseFrameBrowseResultsFrameItemList",
    "AuctionHouseFrameItemBuyFrameItemList",
    "AuctionHouseFrameItemBuyFrameItemDisplay",
    "AuctionHouseFrameCommoditiesBuyFrameItemList",
    "AuctionHouseFrameCommoditiesBuyFrameBuyDisplay",
    "AuctionHouseFrameItemSellList",
    "AuctionHouseFrameCommoditiesSellList",
    "AuctionHouseFrameItemSellFrame",
    "AuctionHouseFrameCommoditiesSellFrame",
    "AuctionHouseFrameAuctionsFrameSummaryList",
    "AuctionHouseFrameAuctionsFrameAllAuctionsList",
    "AuctionHouseFrameAuctionsFrameBidsList",
    "AuctionHouseFrameAuctionsFrameItemList",
    "AuctionHouseFrameAuctionsFrameCommoditiesList",
}

local DIALOGS = {
    "AuctionHouseFrameBuyDialog",
    "AuctionHouseMultisellProgressFrame",
}

local DIM_PATHS = {
    "auctionpost",
    "ui%-character%-scrollbar",
    "ui%-background%-marble",
    "framegeneral[/\\]",
    "common[/\\]whiteiconframe",
}

local TAB_PARTS = {
    "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
    "LeftDisabled", "MiddleDisabled", "RightDisabled",
    "HighlightLeft", "HighlightMiddle", "HighlightRight",
}

local function Kit()
    return NS.SkinKit
end

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinAuction ~= false
end

local function Paint(texture, style)
    local S = Style()

    if style == "hide" then
        texture:SetTexture(nil)
    elseif style == "card" then
        texture:SetTexture(WHITE)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertexColor(0.045, 0.050, 0.070, 0.92)
    elseif style == "hover" then
        texture:SetTexture(WHITE)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetBlendMode("BLEND")
        texture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.12)
    elseif style == "select" then
        texture:SetTexture(WHITE)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetBlendMode("BLEND")
        texture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
    end
end

local function Near(a, b)
    return a and b and math.abs(a - b) < 0.0005
end

local function IdentifyAtlas(texture)
    local storage = _G.S_ATLAS_STORAGE
    if type(storage) ~= "table" then return end

    local ok, path = pcall(texture.GetTexture, texture)
    path = ok and type(path) == "string" and path:lower()
    if not path or not path:find(ATLAS_FILE) then return end

    local left, top, _, bottom, right = texture:GetTexCoord()

    for name, style in pairs(ATLAS_STYLE) do
        local atlas = storage[name]
        if atlas and Near(atlas[3], left) and Near(atlas[4], right)
            and Near(atlas[5], top) and Near(atlas[6], bottom) then
            return style
        end
    end
end

local function SweepTextures(frame)
    if not frame or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" and not region.narciKeepVisible then
            local style = IdentifyAtlas(region)

            if style then
                Paint(region, style)
            else
                local ok, path = pcall(region.GetTexture, region)
                path = ok and type(path) == "string" and path:lower()

                if path then
                    for _, pattern in ipairs(DIM_PATHS) do
                        if path:find(pattern) then
                            region:SetAlpha(0)
                            break
                        end
                    end
                end
            end
        end
    end
end

function AuctionSkin:HookAtlas()
    if self.atlasHooked then return end

    local probe = UIParent:CreateTexture()
    local meta = getmetatable(probe)
    local methods = meta and meta.__index
    probe:Hide()

    if type(methods) ~= "table" or type(methods.SetAtlas) ~= "function" then return end
    self.atlasHooked = true

    hooksecurefunc(methods, "SetAtlas", function(texture, name)
        local style = ATLAS_STYLE[name]
        if style and AuctionSkin.active then Paint(texture, style) end
    end)
end

local function Panel(frame)
    if not frame or frame.narciAuctionPanel then return end
    frame.narciAuctionPanel = true

    local K = Kit()

    K.Strip(frame, 2)
    if frame.NineSlice then frame.NineSlice:SetAlpha(0) end
    if frame.Background then frame.Background:SetAlpha(0) end

    local name = frame:GetName()
    local nine = name and _G[name .. "NineSlice"]
    if nine then nine:SetAlpha(0) end

    K.Inset(frame, 0.30)
    K.Edges(frame, 18, 0.28)
end

function AuctionSkin:Sweep()
    local frame = _G.AuctionHouseFrame
    if not frame then return end

    Kit().Walk(frame, 12, SweepTextures)
    Kit().Auto(frame, 12)
end

function AuctionSkin:PaintTabs(selected)
    local frame = _G.AuctionHouseFrame
    if not frame or not frame.Tabs then return end

    selected = selected or frame.selectedTab or 1

    for index, tab in ipairs(frame.Tabs) do
        for _, key in ipairs(TAB_PARTS) do
            local part = tab[key]
            if part and part.SetAlpha then part:SetAlpha(0) end
        end

        Kit().Tab(tab, index == selected)
    end
end

function AuctionSkin:Skin()
    local frame = _G.AuctionHouseFrame
    if not frame or frame.narciAuction then return end
    frame.narciAuction = true

    local S = Style()
    local Mail = NS.MailSkin

    if Mail and Mail.Window then
        Mail.Window(frame)
    else
        Kit().Window(frame, { inset = 20, depth = 2 })
    end

    if _G.AuctionHouseFramePortrait then _G.AuctionHouseFramePortrait:SetAlpha(0) end

    local money = _G.AuctionHouseFrameMoneyFrame
    if money then
        money.narciOwn = true
        local border = _G.AuctionHouseFrameMoneyFrameBorder
        if border then
            SweepTextures(border)
            Kit().StripOne(border)
            Kit().Inset(border, 0.30)
        end
    end

    for _, name in ipairs(PANELS) do Panel(_G[name]) end

    for _, name in ipairs(DIALOGS) do
        local dialog = _G[name]
        if dialog then
            Kit().Window(dialog, { inset = 14, depth = 2 })
            if dialog.NineSlice then dialog.NineSlice:SetAlpha(0) end
            local border = _G[name .. "Border"]
            if border then border:SetAlpha(0) end
        end
    end

    self:Sweep()
    self:PaintTabs()

    frame:HookScript("OnShow", function()
        if not Enabled() then return end
        AuctionSkin.active = true
        AuctionSkin:Sweep()
        AuctionSkin:PaintTabs()
        if NS.After then NS.After(0.3, function() AuctionSkin:Sweep() end) end
    end)

    frame:HookScript("OnHide", function()
        AuctionSkin.active = nil
    end)

    if type(frame.SetDisplayMode) == "function" then
        hooksecurefunc(frame, "SetDisplayMode", function()
            if not Enabled() then return end
            AuctionSkin:PaintTabs()
            if NS.After then NS.After(0.1, function() AuctionSkin:Sweep() end) end
        end)
    end

    local title = frame.TitleText or _G.AuctionHouseFrameTitleText
    if title then title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]) end
end

function AuctionSkin:Hook()
    if self.hooked then return end
    self.hooked = true

    self:HookAtlas()

    if type(_G.PanelTemplates_SetTab) == "function" then
        hooksecurefunc("PanelTemplates_SetTab", function(frame, id)
            if frame == _G.AuctionHouseFrame and frame.narciAuction and Enabled() then
                AuctionSkin:PaintTabs(id)
            end
        end)
    end
end

function AuctionSkin:Apply()
    if not Enabled() or not Kit() then return end
    if not _G.AuctionHouseFrame then return end

    self:Hook()
    self.active = _G.AuctionHouseFrame:IsShown() or nil

    local ok, err = pcall(function() AuctionSkin:Skin() end)
    if not ok and NS.Print then NS.Print("аукцион: " .. tostring(err)) end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("AUCTION_HOUSE_SHOW")

driver:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionSkin.active = true
        if NS.After then NS.After(0, function() AuctionSkin:Apply() end) end
        return
    end

    AuctionSkin:Apply()
end)
