local addonName, NS = ...
local L = NS.L

local CharFrame = {}

local format = string.format

function CharFrame:Init()
    if self.initialized or self._initializing then return end
    self._initializing = true

    if CharacterFrame and not CharacterFrame:IsShown() then
        CharacterFrame:Show()
        CharacterFrame:Hide()
    end

    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", function()
            self:OnShow()
        end)
        CharacterFrame:HookScript("OnHide", function()
            self:OnHide()
        end)
    end

    self:CreateInfoPanel()

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function()
        if not self._closePending then return end
        self._closePending = nil
        if CharacterFrame and CharacterFrame:IsShown() and NS.NarciUI and NS.NarciUI.isShown then
            self._suppressHide = true
            HideUIPanel(CharacterFrame)
            self._suppressHide = nil
            NS.NarciUI:HideOtherAddons()
        end
    end)
    self.watcher = watcher

    self._initializing = nil
    self.initialized = true
end

function CharFrame:CreateInfoPanel()
    local panel = CreateFrame("Frame", "NarcissusSirus_CharInfoPanel", CharacterFrame)
    panel:SetHeight(50)
    panel:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT", 8, 8)
    panel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -8, 8)
    panel:SetFrameLevel(CharacterFrame:GetFrameLevel() + 3)

    NS.CreateBackdrop(panel, 2, 0.05, 0.05, 0.1, 0.8)

    local iLvlText = panel:CreateFontString(nil, "OVERLAY")
    iLvlText:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    iLvlText:SetTextColor(0, 1, 0.5)
    iLvlText:SetPoint("LEFT", panel, "LEFT", 10, 8)
    iLvlText:SetText(L["Ур.предм.: 0"])
    panel.iLvlText = iLvlText

    local nameText = panel:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    nameText:SetPoint("LEFT", panel, "LEFT", 10, -8)
    nameText:SetText("")
    panel.nameText = nameText

    local enchantText = panel:CreateFontString(nil, "OVERLAY")
    enchantText:SetFont(NS.FONT, NS.FS(10), "")
    enchantText:SetTextColor(1, 0.82, 0)
    enchantText:SetPoint("RIGHT", panel, "RIGHT", -10, 8)
    enchantText:SetText("")
    panel.enchantText = enchantText

    local gemText = panel:CreateFontString(nil, "OVERLAY")
    gemText:SetFont(NS.FONT, NS.FS(10), "")
    gemText:SetTextColor(0.6, 0.8, 1)
    gemText:SetPoint("RIGHT", panel, "RIGHT", -10, -8)
    gemText:SetText("")
    panel.gemText = gemText

    self.infoPanel = panel
end

function CharFrame:UpdateInfoPanel()
    if not self.infoPanel then return end

    local avgILvl = NS.GetAverageItemLevel()
    self.infoPanel.iLvlText:SetText(format(L["Ур.предм.: %.1f"], avgILvl))

    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        self.infoPanel.nameText:SetText(format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))
    else
        self.infoPanel.nameText:SetText(name)
    end

    local missingEnchants = 0
    local ENCHANT_SLOTS = {1, 3, 5, 7, 8, 9, 10, 15, 16}
    for _, slotID in ipairs(ENCHANT_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local enchant = NS.GetEnchantInfo(link)
            if not enchant then
                missingEnchants = missingEnchants + 1
            end
        end
    end

    if missingEnchants > 0 then
        self.infoPanel.enchantText:SetText(format(L["|cffff4444Без чар: %d|r"], missingEnchants))
    else
        self.infoPanel.enchantText:SetText(L["|cff44ff44Все чары на месте|r"])
    end

    local emptyGems = 0
    local GEM_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 15, 16, 17}
    for _, slotID in ipairs(GEM_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link and NS.TooltipScanner then
            local empty = NS.TooltipScanner:GetEmptySocketCount(link)
            emptyGems = emptyGems + empty
        end
    end

    if emptyGems > 0 then
        self.infoPanel.gemText:SetText(format(L["|cffff8800Пустых разъёмов: %d|r"], emptyGems))
    else
        self.infoPanel.gemText:SetText(L["|cff44ff44Все разъёмы заполнены|r"])
    end
end

function CharFrame:OnShow()
    if not self.initialized then self:Init() end

    local replace = not (NS.db and NS.db.replaceCharacter == false)

    if self.infoPanel then self.infoPanel:SetShown(replace) end

    if NS.NarciUI and replace then
        if InCombatLockdown() and not (NS.db and NS.db.showInCombat) then
            NS.Print(L["в бою открывается штатное окно персонажа"])
            return
        end
        NS.After(0, function()
            if InCombatLockdown() then
                self._closePending = true
            else
                self._suppressHide = true
                HideUIPanel(CharacterFrame)
                self._suppressHide = nil
            end

            if NS.NarciUI.isShown then
                NS.NarciUI:Hide()
            else
                NS.NarciUI:Show()
            end
        end)
        return
    end

    self:UpdateInfoPanel()

    if NS.ItemLevel then
        NS.ItemLevel:Update()
    end

    if NS.EnchantInfo then
        NS.EnchantInfo:Update()
    end
end

function CharFrame:OnHide()
    if self._suppressHide then return end
    if NS.EnchantInfo then
        NS.EnchantInfo:Hide()
    end
    if NS.NarciUI and NS.NarciUI.isShown then
        NS.After(0, function()
            if NS.NarciUI.isShown then NS.NarciUI:Hide() end
        end)
    end
end

NS.CharFrame = CharFrame
