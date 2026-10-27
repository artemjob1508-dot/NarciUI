local addonName, NS = ...
local L = NS.L

local SlotFlyout = {}

local BUTTON_SIZE = 32
local GAP = 4
local PER_ROW = 6
local PADDING = 6

local host
local buttons = {}
local currentSlot
local itemScratch = {}

local function ItemLevel(link)
    if not link then return 0 end
    local _, _, _, level = GetItemInfo(link)
    return level or 0
end

local function CollectItems(slotId, out)
    for i = #out, 1, -1 do out[i] = nil end
    if type(GetInventoryItemsForSlot) ~= "function" then return out end
    if type(EquipmentManager_UnpackLocation) ~= "function" then return out end

    local found = {}
    local ok = pcall(GetInventoryItemsForSlot, slotId, found)
    if not ok then return out end

    for location in pairs(found) do
        local player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(location)
        if bags and bag and slot then
            local link = GetContainerItemLink(bag, slot)
            if link then
                local texture = GetContainerItemInfo(bag, slot)
                out[#out + 1] = {
                    bag = bag,
                    slot = slot,
                    link = link,
                    texture = texture,
                    level = ItemLevel(link),
                }
            end
        end
    end

    table.sort(out, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return (a.link or "") < (b.link or "")
    end)

    return out
end

local function EnsureHost()
    if host then return host end
    local S = NS.Styling

    host = CreateFrame("Frame", "NarcissusSirus_SlotFlyout", UIParent)
    host:SetFrameStrata("FULLSCREEN_DIALOG")
    host:SetFrameLevel(260)
    host:EnableMouse(true)
    host:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    host:SetBackdropColor(S.Bg(0.95))
    host:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.6)
    S.CreateShadow(host, 5, 0.4)
    host:Hide()

    host:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.15 then return end
        self.elapsed = 0
        if not IsModifiedClick("SHOWITEMFLYOUT") then
            SlotFlyout:Hide()
            return
        end
        if not self:IsMouseOver() and not (currentSlot and currentSlot:IsMouseOver()) then
            SlotFlyout:Hide()
        end
    end)

    return host
end

local function GetButton(index)
    if buttons[index] then return buttons[index] end
    local S = NS.Styling

    local b = CreateFrame("Button", "NarcissusSirus_SlotFlyoutItem" .. index, host, "SecureActionButtonTemplate")
    b:SetWidth(BUTTON_SIZE)
    b:SetHeight(BUTTON_SIZE)
    b:RegisterForClicks("LeftButtonUp")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.9)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon = icon

    local border = CreateFrame("Frame", nil, b)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    b.border = border

    local level = b:CreateFontString(nil, "OVERLAY")
    level:SetFont(NS.FONT, NS.FS(10), "OUTLINE")
    level:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    level:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    b.level = level

    local highlight = b:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.2)

    b:SetScript("OnEnter", function(self)
        if not self.bagID or not self.slotID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(self.bagID, self.slotID)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    buttons[index] = b
    return b
end

local function Layout(count, slotFrame)
    local rows = math.ceil(count / PER_ROW)
    local perRow = math.min(count, PER_ROW)
    local width = perRow * BUTTON_SIZE + (perRow - 1) * GAP + PADDING * 2
    local height = rows * BUTTON_SIZE + (rows - 1) * GAP + PADDING * 2

    host:SetWidth(width)
    host:SetHeight(height)
    host:ClearAllPoints()

    if slotFrame.slotSide == "BOTTOM" then
        host:SetPoint("BOTTOM", slotFrame, "TOP", 0, 24)
    else
        host:SetPoint("TOP", slotFrame, "BOTTOM", 0, -8)
    end

    for index = 1, count do
        local row = math.floor((index - 1) / PER_ROW)
        local column = (index - 1) % PER_ROW
        local b = buttons[index]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", host, "TOPLEFT",
            PADDING + column * (BUTTON_SIZE + GAP),
            -(PADDING + row * (BUTTON_SIZE + GAP)))
    end
end

function SlotFlyout:Show(slotFrame)
    if not slotFrame or not slotFrame.slotId then return end
    if not NS.db or NS.db.slotFlyout == false then return end
    if InCombatLockdown() then return end

    EnsureHost()

    local items = CollectItems(slotFrame.slotId, itemScratch)
    if #items == 0 then
        self:Hide()
        return
    end

    for index = 1, #items do
        local item = items[index]
        local b = GetButton(index)
        b.bagID = item.bag
        b.slotID = item.slot
        b:SetAttribute("type", "item")
        b:SetAttribute("bag", item.bag)
        b:SetAttribute("slot", item.slot)
        b.icon:SetTexture(item.texture)
        b.level:SetText(item.level > 0 and item.level or "")
        b:Show()
    end

    for index = #items + 1, #buttons do
        buttons[index]:Hide()
    end

    currentSlot = slotFrame
    Layout(#items, slotFrame)
    host:SetAlpha(1)
    host:Show()
end

function SlotFlyout:Hide()
    if host and host:IsShown() then
        if InCombatLockdown() and host:IsProtected() then
            host:SetAlpha(0)
            self._hidePending = true
        else
            host:SetAlpha(1)
            host:Hide()
        end
    end
    currentSlot = nil
    GameTooltip:Hide()
end

function SlotFlyout:Refresh()
    if host and host:IsShown() and currentSlot then
        self:Show(currentSlot)
    end
end

function SlotFlyout:OnSlotEnter(slotFrame)
    if IsModifiedClick("SHOWITEMFLYOUT") then
        self:Show(slotFrame)
    end
end

local function HoveredSlot()
    local ui = NS.NarciUI
    if not ui or not ui.isShown or not ui.mainFrame or not ui.mainFrame.slotFrames then return nil end
    for _, slotFrame in pairs(ui.mainFrame.slotFrames) do
        if slotFrame:IsShown() and slotFrame:IsMouseOver() then return slotFrame end
    end
    return nil
end

function SlotFlyout:Create()
    if self.watcher then return end
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("MODIFIER_STATE_CHANGED")
    watcher:RegisterEvent("BAG_UPDATE_DELAYED")
    watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(_, event)
        if event == "MODIFIER_STATE_CHANGED" then
            if IsModifiedClick("SHOWITEMFLYOUT") then
                local slotFrame = HoveredSlot()
                if slotFrame then SlotFlyout:Show(slotFrame) end
            else
                SlotFlyout:Hide()
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            SlotFlyout:Hide()
        elseif event == "PLAYER_REGEN_ENABLED" then
            if SlotFlyout._hidePending then
                SlotFlyout._hidePending = nil
                if host then
                    host:Hide()
                    host:SetAlpha(1)
                end
            end
        else
            SlotFlyout:Refresh()
        end
    end)
    self.watcher = watcher
end

NS.SlotFlyout = SlotFlyout
