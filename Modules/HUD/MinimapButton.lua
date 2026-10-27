local addonName, NS = ...
local L = NS.L

local MinimapButton = {}

local floor = math.floor
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin

local ORBIT_RADIUS = 80

local BUTTON_SIZE = 31

function MinimapButton:Create()
    if self.button then return end

    local btn = CreateFrame("Button", "NarcissusSirus_MinimapButton", Minimap)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)

    btn.narciNoSquare = true

    local halo = CreateFrame("Frame", nil, btn)
    halo:SetAllPoints(btn)
    halo:SetFrameLevel(btn:GetFrameLevel())
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    btn.icon = icon

    local glow = halo:CreateTexture(nil, "BACKGROUND")
    glow:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    glow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    glow:SetBlendMode("ADD")
    btn.glow = glow

    local function Paint()
        NS.Styling.PaintEmblem(icon, glow, btn.hover and 0.8 or 0.35, true)
        if btn.pressed then icon:SetAlpha(0.7) end
    end
    btn.Paint = Paint
    Paint()
    if NS.Styling.WatchBrand then NS.Styling.WatchBrand(Paint) end

    btn:SetScript("OnMouseDown", function() btn.pressed = true Paint() end)
    btn:SetScript("OnMouseUp", function() btn.pressed = nil Paint() end)

    self.button = btn

    local angle = (NS.db and NS.db.minimapAngle) or math.rad(220)
    if angle > 6.2832 then angle = math.rad(angle) end
    self:UpdatePosition(angle)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            NS:ToggleCharacterUI()
        elseif button == "RightButton" then
            NS:ToggleSettings()
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx then return end
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not scale or scale == 0 then return end
            cx, cy = cx / scale, cy / scale
            MinimapButton:UpdatePosition(atan2(cy - my, cx - mx))
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(self)
        self.hover = true
        self.Paint()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(NS.Styling.BrandName and NS.Styling.BrandName() or "NarciUI", NS.Styling.ACCENT_GLOW[1], NS.Styling.ACCENT_GLOW[2], NS.Styling.ACCENT_GLOW[3])
        GameTooltip:AddLine(L["ЛКМ: открыть окно персонажа"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["ПКМ: настройки"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["Перетащить: передвинуть по краю миникарты"], 0.5, 0.5, 0.55)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self.hover = nil
        self.Paint()
        GameTooltip:Hide()
    end)
end

function MinimapButton:UpdatePosition(angle)
    if not angle or not self.button then return end

    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER",
        cos(angle) * ORBIT_RADIUS, sin(angle) * ORBIT_RADIUS)

    if NS.db then
        NS.db.minimapAngle = floor(angle * 100 + 0.5) / 100
    end
end

function MinimapButton:Show()
    if not self.button then self:Create() end
    self.button:Show()
end

function MinimapButton:Hide()
    if self.button then
        self.button:Hide()
    end
end

function MinimapButton:Toggle()
    if not self.button then self:Create() end
    if self.button:IsShown() then
        self:Hide()
        if NS.db then NS.db.minimapButton = false end
    else
        self:Show()
        if NS.db then NS.db.minimapButton = true end
    end
end

NS.MinimapButton = MinimapButton
