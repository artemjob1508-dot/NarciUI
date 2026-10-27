local addonName, NS = ...

local L = NS.L
local ItemLevel = {}

local floor = math.floor
local format = string.format

function ItemLevel:Init()
    self.labels = {}
    self.frame = CreateFrame("Frame", "NarcissusSirus_ItemLevelFrame", CharacterFrame)
    self.frame:SetAllPoints()
    self.frame:SetFrameLevel(CharacterFrame:GetFrameLevel() + 5)

    local slotNames = {
        [1] = "CharacterHeadSlot",
        [2] = "CharacterNeckSlot",
        [3] = "CharacterShoulderSlot",
        [5] = "CharacterChestSlot",
        [6] = "CharacterWaistSlot",
        [7] = "CharacterLegsSlot",
        [8] = "CharacterFeetSlot",
        [9] = "CharacterWristSlot",
        [10] = "CharacterHandsSlot",
        [11] = "CharacterFinger0Slot",
        [12] = "CharacterFinger1Slot",
        [13] = "CharacterTrinket0Slot",
        [14] = "CharacterTrinket1Slot",
        [15] = "CharacterBackSlot",
        [16] = "CharacterMainHandSlot",
        [17] = "CharacterSecondaryHandSlot",
        [18] = "CharacterRangedSlot",
    }

    for slotID, buttonName in pairs(slotNames) do
        local button = _G[buttonName]
        if button then
            local label = self.frame:CreateFontString(nil, "OVERLAY")
            label:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
            label:SetTextColor(1, 0.82, 0)
            label:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
            label:SetDrawLayer("OVERLAY", 7)
            label:Hide()
            self.labels[slotID] = label
        end
    end

    self.avgLabel = self.frame:CreateFontString(nil, "OVERLAY")
    self.avgLabel:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    self.avgLabel:SetTextColor(0, 1, 0.5)
    self.avgLabel:SetPoint("TOP", CharacterFrame, "TOP", 0, -28)
    self.avgLabel:SetDrawLayer("OVERLAY", 7)
    self.avgLabel:Hide()

    self.initialized = true
end

function ItemLevel:Update()
    if not self.initialized then self:Init() end
    if not NS.db or not NS.db.showItemLevel then
        self:Hide()
        return
    end

    local totalLevel = 0
    local count = 0

    for slotID, label in pairs(self.labels) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local level = NS.GetItemLevel(link)
            if level > 0 then
                label:SetText(level)
                local quality = select(3, GetItemInfo(link))
                if quality then
                    local r, g, b = NS.GetQualityColor(quality)
                    label:SetTextColor(r, g, b)
                end
                label:Show()
                totalLevel = totalLevel + level
                count = count + 1
            else
                label:Hide()
            end
        else
            label:Hide()
        end
    end

    if count > 0 then
        local avg = floor(totalLevel / count * 100 + 0.5) / 100
        self.avgLabel:SetText(format(L["Уровень предметов: %.1f"], avg))
        self.avgLabel:Show()
    else
        self.avgLabel:Hide()
    end
end

function ItemLevel:Hide()
    if not self.initialized then return end
    for _, label in pairs(self.labels) do
        label:Hide()
    end
    if self.avgLabel then
        self.avgLabel:Hide()
    end
end

function ItemLevel:Show()
    self:Update()
end

NS.ItemLevel = ItemLevel
