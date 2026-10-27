local addonName, NS = ...

local WorldMapWindow = {}
NS.WorldMapWindow = WorldMapWindow

local PADDING = 14
local TOP = 62
local BOTTOM = 44
local MIN_WIDTH = 700
local MAX_WIDTH = 1180

local frame

local function S()
    return NS.QuestStyle
end

local parkedPoint

local parkedScale

local function ParkStockMap()
    if parkedPoint or not WorldMapFrame then return end
    parkedPoint = { WorldMapFrame:GetPoint(1) }
    parkedScale = WorldMapFrame:GetScale()
    WorldMapFrame:SetAlpha(0)
    WorldMapFrame:EnableMouse(false)
end

local function UnparkStockMap()
    if not parkedPoint or not WorldMapFrame then return end
    WorldMapFrame:SetScale(parkedScale or 1)
    WorldMapFrame:ClearAllPoints()
    if parkedPoint[1] then
        WorldMapFrame:SetPoint(parkedPoint[1], parkedPoint[2] or UIParent,
            parkedPoint[3] or parkedPoint[1], parkedPoint[4] or 0, parkedPoint[5] or 0)
    else
        WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    WorldMapFrame:SetAlpha(1)
    WorldMapFrame:EnableMouse(true)
    parkedPoint = nil
    parkedScale = nil
end

local function AlignStockMap(canvas)
    if not parkedPoint or not WorldMapFrame or not WorldMapDetailFrame or not canvas then return end
    if not canvas:GetLeft() or not WorldMapDetailFrame:GetLeft() then return end

    local detailWidth = WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetEffectiveScale()
    local canvasWidth = canvas:GetWidth() * canvas:GetEffectiveScale()
    if detailWidth <= 0 or canvasWidth <= 0 then return end

    WorldMapFrame:SetScale(WorldMapFrame:GetScale() * canvasWidth / detailWidth)

    local parentScale = (WorldMapFrame:GetParent() or UIParent):GetEffectiveScale()
    local detailLeft = WorldMapDetailFrame:GetLeft() * WorldMapDetailFrame:GetEffectiveScale()
    local detailTop = WorldMapDetailFrame:GetTop() * WorldMapDetailFrame:GetEffectiveScale()
    local canvasLeft = canvas:GetLeft() * canvas:GetEffectiveScale()
    local canvasTop = canvas:GetTop() * canvas:GetEffectiveScale()

    local point, relativeTo, relativePoint, x, y = WorldMapFrame:GetPoint(1)
    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint(point or "CENTER", relativeTo or UIParent, relativePoint or "CENTER",
        (x or 0) + (canvasLeft - detailLeft) / parentScale,
        (y or 0) + (canvasTop - detailTop) / parentScale)
end

function WorldMapWindow:UpdateControls()
    if not frame then return end

    local continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
    local zone = GetCurrentMapZone and GetCurrentMapZone() or 0

    local continents = { GetMapContinents() }
    frame.continentButton.label:SetText(continents[continent] or "Весь мир")

    local zones = ZoneNames(continent)
    frame.zoneButton.label:SetText(zones[zone] or "Вся территория")

    frame.title:SetText(frame.canvas.areaName or "Карта")
end

function WorldMapWindow:Refresh()
    if not frame or not frame:IsShown() then return end
    frame.canvas:Redraw()
    self:UpdateControls()
end

function WorldMapWindow:Create()
    if frame then return frame end
    local st = S()

    local width = math.min(math.max(UIParent:GetWidth() * 0.62, MIN_WIDTH), MAX_WIDTH)
    local canvasWidth = width - PADDING * 2
    local height = canvasWidth * 668 / 1002 + TOP + BOTTOM

    frame = CreateFrame("Frame", "NarcissusSirus_WorldMap", UIParent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        AlignStockMap(self.canvas)
    end)
    st.Backdrop(frame, st.BG[1], st.BG[2], st.BG[3], st.BG[4])
    NS.Styling.RoundCorners(frame)
    tinsert(UISpecialFrames, "NarcissusSirus_WorldMap")

    local title = st.Label(frame, 15, "OUTLINE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -12)
    title:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
    frame.title = title

    local close = st.Button(frame, "X", 22, 20)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -10)
    close:SetScript("OnClick", function() frame:Hide() end)

    local canvas = NS.MapCanvas:Create(frame, "NarcissusSirus_WorldMapCanvas")
    canvas:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -TOP)
    canvas:SetAspectWidth(canvasWidth)
    canvas.zoneClicks = true
    canvas.restoreArea = false
    canvas.stockHitTest = true
    canvas:Show()
    frame.canvas = canvas

    canvas.onQuestClick = function(questID)
        if NS.QuestLog then
            NS.QuestLog:Show()
            NS.QuestLog:Select(questID)
        end
    end

    canvas.onAreaChanged = function()
        WorldMapWindow:UpdateControls()
    end

    local zoomOut = st.Button(frame, "Отдалить", 100, 22)
    zoomOut:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, -TOP + 26)
    zoomOut:SetScript("OnClick", function()
        canvas:ZoomOut()
        AlignStockMap(canvas)
    end)

    local continentButton = Dropdown(frame, 150, "Континент")
    continentButton:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -TOP + 26)
    continentButton:SetScript("OnClick", function(self)
        local menu = BuildMenu(self, { GetMapContinents() },
            GetCurrentMapContinent and GetCurrentMapContinent() or 0,
            function(index)
                SetMapZoom(index)
                canvas:Redraw()
                WorldMapWindow:UpdateControls()
            end)
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)
    frame.continentButton = continentButton

    local zoneButton = Dropdown(frame, 190, "Зона")
    zoneButton:SetPoint("LEFT", continentButton, "RIGHT", 8, 0)
    zoneButton:SetScript("OnClick", function(self)
        local continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
        local zones = ZoneNames(continent)
        local menu = BuildMenu(self, zones, GetCurrentMapZone and GetCurrentMapZone() or 0,
            function(index)
                SetMapZoom(continent, index)
                canvas:Redraw()
                WorldMapWindow:UpdateControls()
            end)
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)
    frame.zoneButton = zoneButton

    local hereButton = st.Button(frame, "Где я", 90, 22)
    hereButton:SetPoint("RIGHT", zoomOut, "LEFT", -8, 0)
    hereButton:SetScript("OnClick", function()
        canvas:ShowCurrentZone()
        WorldMapWindow:UpdateControls()
    end)

    local playerCaption = st.Label(frame, 10)
    playerCaption:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING, 14)
    playerCaption:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    playerCaption:SetText("игрок")

    local cursorCaption = st.Label(frame, 10)
    cursorCaption:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    cursorCaption:SetText("курсор")

    local playerCoords = st.Label(frame, 11)
    playerCoords:SetPoint("LEFT", playerCaption, "RIGHT", 6, 0)
    playerCoords:SetTextColor(st.TEXT[1], st.TEXT[2], st.TEXT[3])
    frame.playerCoords = playerCoords

    local cursorCoords = st.Label(frame, 11)
    cursorCaption:SetPoint("LEFT", playerCoords, "RIGHT", 20, 0)
    cursorCoords:SetPoint("LEFT", cursorCaption, "RIGHT", 6, 0)
    cursorCoords:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    frame.cursorCoords = cursorCoords

    local zoneLabel = st.Label(canvas.overlayFrame, 16, "OUTLINE")
    zoneLabel:SetPoint("TOP", canvas.overlayFrame, "TOP", 0, -10)
    zoneLabel:SetJustifyH("CENTER")
    zoneLabel:SetTextColor(1, 1, 1)
    frame.zoneLabel = zoneLabel

    canvas.onCoords = function(x, y)
        if x and y then
            frame.playerCoords:SetText(string.format("%.1f, %.1f", x * 100, y * 100))
        else
            frame.playerCoords:SetText("")
        end
    end

    canvas.onZoneHover = function(name, minLevel, maxLevel)
        if not name or name == "" then
            frame.zoneLabel:SetText("")
            return
        end

        if minLevel and maxLevel and minLevel > 0 and maxLevel > 0 then
            local playerLevel = UnitLevel("player")
            local color
            if playerLevel < minLevel then
                color = GetQuestDifficultyColor(minLevel)
            elseif playerLevel > maxLevel then
                color = GetQuestDifficultyColor(math.max(maxLevel - 2, 1))
            else
                color = QuestDifficultyColors and QuestDifficultyColors["difficult"]
            end
            local r = color and color.r or 1
            local g = color and color.g or 0.82
            local b = color and color.b or 0

            if minLevel ~= maxLevel then
                frame.zoneLabel:SetFormattedText("%s |cff%02x%02x%02x(%d-%d)|r", name,
                    r * 255, g * 255, b * 255, minLevel, maxLevel)
            else
                frame.zoneLabel:SetFormattedText("%s |cff%02x%02x%02x(%d)|r", name,
                    r * 255, g * 255, b * 255, maxLevel)
            end
        else
            frame.zoneLabel:SetText(name)
        end
    end

    canvas.onCursor = function(x, y)
        if x and y then
            frame.cursorCoords:SetText(string.format("%.1f, %.1f", x * 100, y * 100))
        else
            frame.cursorCoords:SetText("")
        end
    end

    frame:SetScript("OnShow", function()
        frame.zoneLabel:SetText("")
        canvas:ShowCurrentZone()
        WorldMapWindow:UpdateControls()
        NS.After(0, function() AlignStockMap(canvas) end)
    end)

    frame:SetScript("OnHide", function()
        frame.zoneLabel:SetText("")
        canvas.highlight:Hide()
        UnparkStockMap()
        if WorldMapFrame and WorldMapFrame:IsShown() and not InCombatLockdown() then
            HideUIPanel(WorldMapFrame)
        end
    end)

    frame:Hide()
    return frame
end

function WorldMapWindow:Show()
    self:Create()
    frame:Show()
end

function WorldMapWindow:HideWindow()
    if frame then frame:Hide() end
end

function WorldMapWindow:IsShown()
    return frame and frame:IsShown()
end

function WorldMapWindow:Toggle()
    self:Create()
    self:ToggleThroughStock()
end

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function()
    if not WorldMapFrame or WorldMapFrame._narciMapHooked then return end
    WorldMapFrame._narciMapHooked = true

    WorldMapFrame:HookScript("OnHide", function()
        UnparkStockMap()
        if WorldMapWindow:IsShown() then
            WorldMapWindow:HideWindow()
        end
    end)

    WorldMapFrame:HookScript("OnShow", function()
        if not NS.questDB or not NS.questDB.replaceWorldMap then return end
        if InCombatLockdown() then return end
        NS.After(0, function()
            if not WorldMapFrame:IsShown() then return end
            ParkStockMap()
            WorldMapWindow:Show()
            NS.After(0, function()
                local window = WorldMapWindow:Create()
                AlignStockMap(window.canvas)
            end)
        end)
    end)
end)

function WorldMapWindow:ToggleThroughStock()
    if self:IsShown() then
        self:HideWindow()
        return
    end
    if WorldMapFrame and not InCombatLockdown() then
        ShowUIPanel(WorldMapFrame)
    else
        self:Show()
    end
end
