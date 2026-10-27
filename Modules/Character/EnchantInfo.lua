local addonName, NS = ...

local EnchantInfo = {}

local format = string.format
local pairs = pairs
local ipairs = ipairs

local ENCHANT_SLOTS = {
    [1] = { name = "Head",     button = "CharacterHeadSlot" },
    [3] = { name = "Shoulder", button = "CharacterShoulderSlot" },
    [5] = { name = "Chest",    button = "CharacterChestSlot" },
    [7] = { name = "Legs",     button = "CharacterLegsSlot" },
    [8] = { name = "Feet",     button = "CharacterFeetSlot" },
    [9] = { name = "Wrist",    button = "CharacterWristSlot" },
    [10]= { name = "Hands",    button = "CharacterHandsSlot" },
    [15]= { name = "Back",     button = "CharacterBackSlot" },
    [16]= { name = "Main Hand",button = "CharacterMainHandSlot" },
}

local GEM_SLOTS = {
    [1] = "CharacterHeadSlot",
    [2] = "CharacterNeckSlot",
    [3] = "CharacterShoulderSlot",
    [5] = "CharacterChestSlot",
    [6] = "CharacterWaistSlot",
    [7] = "CharacterLegsSlot",
    [8] = "CharacterFeetSlot",
    [9] = "CharacterWristSlot",
    [10]= "CharacterHandsSlot",
    [11]= "CharacterFinger0Slot",
    [12]= "CharacterFinger1Slot",
    [15]= "CharacterBackSlot",
    [16]= "CharacterMainHandSlot",
    [17]= "CharacterSecondaryHandSlot",
}

function EnchantInfo:Init()
    self.frame = CreateFrame("Frame", "NarcissusSirus_EnchantFrame", CharacterFrame)
    self.frame:SetAllPoints()
    self.frame:SetFrameLevel(CharacterFrame:GetFrameLevel() + 6)

    self.gemIcons = {}
    self.warningIcons = {}

    self.initialized = true
end

local function CreateWarningIcon(parent)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetSize(12, 12)
    icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    icon:SetVertexColor(1, 0.3, 0.3)
    return icon
end

function EnchantInfo:Update()
    if not self.initialized then self:Init() end
    if not NS.db then return end

    for _, icon in pairs(self.warningIcons) do icon:Hide() end

    if NS.db.showEnchantInfo then
        for slotID, info in pairs(ENCHANT_SLOTS) do
            local button = _G[info.button]
            if button then
                local link = GetInventoryItemLink("player", slotID)
                if link then
                    local enchant = NS.GetEnchantInfo(link)
                    if not enchant then
                        if not self.warningIcons[slotID] then
                            self.warningIcons[slotID] = CreateWarningIcon(button)
                            self.warningIcons[slotID]:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, 2)
                        end
                        self.warningIcons[slotID]:Show()
                    else
                        if self.warningIcons[slotID] then
                            self.warningIcons[slotID]:Hide()
                        end
                    end
                end
            end
        end
    end

    if NS.db.showGemInfo then
        for slotID, buttonName in pairs(GEM_SLOTS) do
            local button = _G[buttonName]
            if button then
                local link = GetInventoryItemLink("player", slotID)
                if link then
                    local gems = NS.GetGemInfo(link)
                    local numGems = 0
                    for i, gem in pairs(gems) do
                        numGems = numGems + 1
                    end

                    if numGems > 0 then
                        if not self.gemIcons[slotID] then
                            self.gemIcons[slotID] = button:CreateFontString(nil, "OVERLAY")
                            self.gemIcons[slotID]:SetFont(NS.FONT, NS.FS(9), "OUTLINE")
                            self.gemIcons[slotID]:SetPoint("TOPLEFT", button, "TOPLEFT", -2, -2)
                        end
                        local gemText = ""
                        for i = 1, numGems do
                            if gems[i] then
                                gemText = gemText .. "|TInterface\\Icons\\INV_Misc_Gem_01:10:10:0:0:64:64:4:60:4:60|t"
                            end
                        end
                        self.gemIcons[slotID]:SetText(gemText)
                        self.gemIcons[slotID]:Show()
                    else
                        if self.gemIcons[slotID] then
                            self.gemIcons[slotID]:Hide()
                        end
                    end
                end
            end
        end
    end
end

function EnchantInfo:Hide()
    if not self.initialized then return end
    for _, icon in pairs(self.warningIcons) do icon:Hide() end
    for _, icon in pairs(self.gemIcons) do if icon.Hide then icon:Hide() end end
end

NS.EnchantInfo = EnchantInfo
