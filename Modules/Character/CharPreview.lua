local addonName, NS = ...
local L = NS.L

local CharPreview = {}

local format = string.format

local PREVIEW_WIDTH = 260
local PREVIEW_HEIGHT = 340

function CharPreview:Create()
    if self.frame then return end

    local f = CreateFrame("Frame", "NarcissusSirus_CharPreview", UIParent)
    f:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
    f:SetPoint("LEFT", CharacterFrame, "RIGHT", 6, 0)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    NS.Styling.ApplyPanelStyle(f, PREVIEW_WIDTH, PREVIEW_HEIGHT)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    title:SetTextColor(NS.Styling.ACCENT_GLOW[1], NS.Styling.ACCENT_GLOW[2], NS.Styling.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText(L["Предпросмотр персонажа"])
    f.title = title

    local closeBtn = NS.Widgets.CreateCloseButton(f, 20, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local model = CreateFrame("PlayerModel", "NarcissusSirus_PreviewModel", f)
    model:SetSize(PREVIEW_WIDTH - 20, PREVIEW_HEIGHT - 100)
    model:SetPoint("TOP", f, "TOP", 0, -35)
    model:SetUnit("player")
    model:SetRotation(0)
    model:SetFacing(0.5)
    model:SetPortraitZoom(0.8)
    f.model = model

    local modelBorder = CreateFrame("Frame", nil, f)
    modelBorder:SetPoint("TOPLEFT", model, "TOPLEFT", -2, 2)
    modelBorder:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 2, -2)
    modelBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    modelBorder:SetBackdropBorderColor(0.2, 0.5, 0.4, 0.6)
    modelBorder:SetFrameLevel(model:GetFrameLevel() + 1)

    local rotateLeft = CreateFrame("Button", nil, f)
    rotateLeft:SetSize(28, 28)
    rotateLeft:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 4, 4)
    rotateLeft:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    rotateLeft:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    rotateLeft:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    rotateLeft:SetScript("OnMouseDown", function()
        f.rotating = true
        f.rotateDir = -1
    end)
    rotateLeft:SetScript("OnMouseUp", function()
        f.rotating = false
    end)

    local rotateRight = CreateFrame("Button", nil, f)
    rotateRight:SetSize(28, 28)
    rotateRight:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", -4, 4)
    rotateRight:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    rotateRight:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    rotateRight:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    rotateRight:SetScript("OnMouseDown", function()
        f.rotating = true
        f.rotateDir = 1
    end)
    rotateRight:SetScript("OnMouseUp", function()
        f.rotating = false
    end)

    f:SetScript("OnUpdate", function(self, elapsed)
        if self.rotating and self.model then
            local facing = self.model:GetFacing() + (self.rotateDir * elapsed * 2)
            self.model:SetFacing(facing)
        end
    end)

    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        local zoom = self:GetModelScale() or 1
        if delta > 0 then
            zoom = zoom * 1.05
        else
            zoom = zoom * 0.95
        end
        self:SetModelScale(zoom)
    end)

    local infoFrame = CreateFrame("Frame", nil, f)
    infoFrame:SetHeight(50)
    infoFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
    infoFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

    local nameLabel = infoFrame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    nameLabel:SetPoint("TOP", infoFrame, "TOP", 0, -2)
    f.nameLabel = nameLabel

    local detailLabel = infoFrame:CreateFontString(nil, "OVERLAY")
    detailLabel:SetFont(NS.FONT, NS.FS(10), "")
    detailLabel:SetTextColor(0.7, 0.7, 0.7)
    detailLabel:SetPoint("TOP", infoFrame, "TOP", 0, -18)
    f.detailLabel = detailLabel

    local iLvlLabel = infoFrame:CreateFontString(nil, "OVERLAY")
    iLvlLabel:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    iLvlLabel:SetTextColor(0, 1, 0.5)
    iLvlLabel:SetPoint("TOP", infoFrame, "TOP", 0, -32)
    f.iLvlLabel = iLvlLabel

    self.frame = f
    f:Hide()
end

function CharPreview:Update()
    if not self.frame then self:Create() end
    local f = self.frame

    if f.model then
        f.model:SetUnit("player")
        f.model:SetFacing(0.5)
        pcall(f.model.RefreshUnit, f.model)
    end

    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        f.nameLabel:SetText(format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))
    else
        f.nameLabel:SetText(name)
    end

    local level = UnitLevel("player")
    local race = UnitRace("player")
    local localizedClass = UnitClass("player")
    f.detailLabel:SetText(format(L["Уровень %d %s %s"], level, race, localizedClass))

    local avgILvl = NS.GetAverageItemLevel()
    f.iLvlLabel:SetText(format(L["Уровень предметов: %.1f"], avgILvl))
end

function CharPreview:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Update()
        self.frame:Show()
    end
end

NS.CharPreview = CharPreview
