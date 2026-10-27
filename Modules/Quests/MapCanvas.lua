local addonName, NS = ...

local MapCanvas = {}
NS.MapCanvas = MapCanvas

local TILE_SIZE = 256
local IMAGE_WIDTH = 1002
local IMAGE_HEIGHT = 668
local TILE_COLS = 4
local TILE_ROWS = 3
local NUM_TILES = 12
local MAX_OVERLAY_PIECES = 400

local discovered = {}

local function S()
    return NS.QuestStyle
end

local function DrawOverlay(canvas, used, unitX, unitY, textureName, textureWidth, textureHeight, offsetX, offsetY, explored)
    if not textureWidth or not textureHeight then return used end
    if textureWidth <= 0 or textureHeight <= 0 then return used end
    if textureWidth > IMAGE_WIDTH or textureHeight > IMAGE_HEIGHT then return used end
    if (offsetX or 0) < 0 or (offsetY or 0) < 0 then return used end
    if (offsetX or 0) > IMAGE_WIDTH or (offsetY or 0) > IMAGE_HEIGHT then return used end

    local wide = math.ceil(textureWidth / TILE_SIZE)
    local tall = math.ceil(textureHeight / TILE_SIZE)
    if used + wide * tall > MAX_OVERLAY_PIECES then return used end

    for row = 1, tall do
        local pixelHeight, fileHeight
        if row < tall then
            pixelHeight, fileHeight = TILE_SIZE, TILE_SIZE
        else
            pixelHeight = math.fmod(textureHeight, TILE_SIZE)
            if pixelHeight == 0 then pixelHeight = TILE_SIZE end
            fileHeight = 16
            while fileHeight < pixelHeight do fileHeight = fileHeight * 2 end
        end

        for column = 1, wide do
            local pixelWidth, fileWidth
            if column < wide then
                pixelWidth, fileWidth = TILE_SIZE, TILE_SIZE
            else
                pixelWidth = math.fmod(textureWidth, TILE_SIZE)
                if pixelWidth == 0 then pixelWidth = TILE_SIZE end
                fileWidth = 16
                while fileWidth < pixelWidth do fileWidth = fileWidth * 2 end
            end

            used = used + 1
            local texture = canvas.overlays[used]
            if not texture then
                texture = canvas:CreateTexture(nil, "BORDER")
                canvas.overlays[used] = texture
            end

            texture:SetTexture(textureName .. (((row - 1) * wide) + column))
            texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
            texture:SetWidth(pixelWidth * unitX)
            texture:SetHeight(pixelHeight * unitY)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", canvas, "TOPLEFT",
                (offsetX + TILE_SIZE * (column - 1)) * unitX,
                -(offsetY + TILE_SIZE * (row - 1)) * unitY)

            if explored then
                texture:SetDrawLayer("ARTWORK")
                texture:SetVertexColor(1, 1, 1, 1)
            else
                texture:SetDrawLayer("BORDER")
                texture:SetVertexColor(0.62, 0.62, 0.70, 0.85)
            end

            texture:Show()
        end
    end

    return used
end

local function UpdateTiles(canvas)
    local fileName = GetMapInfo()
    local dungeonLevel = GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
    local cosmic = false

    if not fileName then
        if GetCurrentMapContinent and GetCurrentMapContinent() == (WORLDMAP_COSMIC_ID or -1) then
            fileName = "Cosmic"
            cosmic = true
        else
            fileName = "World"
        end
    end

    canvas.isCosmic = cosmic

    if DungeonUsesTerrainMap and DungeonUsesTerrainMap() then
        dungeonLevel = dungeonLevel - 1
    end

    local complete = fileName
    if dungeonLevel > 0 then complete = fileName .. dungeonLevel .. "_" end

    for index = 1, NUM_TILES do
        canvas.tiles[index]:SetTexture("Interface\\WorldMap\\" .. fileName .. "\\" .. complete .. index)
        canvas.tiles[index]:Show()
    end
    canvas.empty:Hide()
    return true
end

local function UpdateOverlays(canvas)
    if not GetNumMapOverlays or not GetMapOverlayInfo then return end

    local fileName = GetMapInfo()
    if not fileName then
        for index = 1, #canvas.overlays do canvas.overlays[index]:Hide() end
        return
    end

    local unitX = canvas:GetWidth() / IMAGE_WIDTH
    local unitY = canvas:GetHeight() / IMAGE_HEIGHT
    local prefix = "Interface\\WorldMap\\" .. fileName .. "\\"
    local prefixLength = string.len(prefix) + 1
    local used = 0

    for key in pairs(discovered) do discovered[key] = nil end

    for index = 1, GetNumMapOverlays() do
        local textureName, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(index)
        if textureName and textureName ~= "" then
            local shortName = string.sub(textureName, prefixLength)
            if string.lower(shortName) ~= "pixelfix" then
                discovered[shortName] = true
                used = DrawOverlay(canvas, used, unitX, unitY, textureName,
                    textureWidth, textureHeight, offsetX, offsetY, true)
            end
        end
    end

    local reveal = not NS.questDB or NS.questDB.revealMap ~= false
    local known = reveal and NS.MAP_OVERLAYS and NS.MAP_OVERLAYS[fileName]
    if known then
        for shortName, packed in pairs(known) do
            if not discovered[shortName] then
                local textureWidth = math.fmod(packed, 1024)
                local textureHeight = math.fmod(math.floor(packed / 1024), 1024)
                local offsetX = math.fmod(math.floor(packed / 1048576), 1024)
                local offsetY = math.floor(packed / 1073741824)
                used = DrawOverlay(canvas, used, unitX, unitY, prefix .. shortName,
                    textureWidth, textureHeight, offsetX, offsetY, false)
            end
        end
    end

    for index = used + 1, #canvas.overlays do
        canvas.overlays[index]:Hide()
    end
end

local function GetLandmark(canvas, index)
    local poi = canvas.landmarks[index]
    if poi then return poi end

    poi = CreateFrame("Button", nil, canvas.pinHolder)
    poi:SetWidth(14)
    poi:SetHeight(14)
    poi.texture = poi:CreateTexture(nil, "OVERLAY")
    poi.texture:SetAllPoints()
    poi.texture:SetTexture("Interface\\Minimap\\POIIcons")

    poi:SetScript("OnEnter", function(self)
        if not self.landmarkName then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.landmarkName, 1, 1, 1)
        if self.landmarkDescription and self.landmarkDescription ~= "" then
            GameTooltip:AddLine(self.landmarkDescription, 0.7, 0.7, 0.75, true)
        end
        GameTooltip:Show()
    end)
    poi:SetScript("OnLeave", function() GameTooltip:Hide() end)

    canvas.landmarks[index] = poi
    return poi
end

local function UpdateLandmarks(canvas)
    local count = GetNumMapLandmarks and GetNumMapLandmarks() or 0
    local width, height = canvas:GetWidth(), canvas:GetHeight()

    for index = 1, count do
        local name, description, textureIndex, x, y = GetMapLandmarkInfo(index)
        local poi = GetLandmark(canvas, index)
        if name and x and y and x > 0 and y > 0 then
            if WorldMap_GetPOITextureCoords and textureIndex then
                local x1, x2, y1, y2 = WorldMap_GetPOITextureCoords(textureIndex)
                if x1 then poi.texture:SetTexCoord(x1, x2, y1, y2) end
            end
            poi.landmarkName = name
            poi.landmarkDescription = description
            poi:ClearAllPoints()
            poi:SetPoint("CENTER", canvas, "TOPLEFT", x * width, -y * height)
            poi:Show()
        else
            poi:Hide()
        end
    end

    for index = count + 1, #canvas.landmarks do
        canvas.landmarks[index]:Hide()
    end
end

local function ObjectiveTextFor(logIndex, objectiveIndex)
    if not logIndex or logIndex <= 0 then return nil end
    local count = GetNumQuestLeaderBoards(logIndex) or 0
    if objectiveIndex and objectiveIndex > 0 and objectiveIndex <= count then
        local text = GetQuestLogLeaderBoard(objectiveIndex, logIndex)
        if text then return text end
    end

    local parts = {}
    for index = 1, count do
        local text, _, finished = GetQuestLogLeaderBoard(index, logIndex)
        if text and not finished then parts[#parts + 1] = text end
    end
    if #parts > 0 then return table.concat(parts, ", ") end

    SelectQuestLogEntry(logIndex)
    local _, objectives = GetQuestLogQuestText()
    return objectives
end

local function GetQuestPin(canvas, index)
    local pin = canvas.pins[index]
    if pin then return pin end
    local st = S()

    pin = CreateFrame("Button", nil, canvas.pinHolder)
    pin:SetWidth(22)
    pin:SetHeight(22)

    pin.halo = pin:CreateTexture(nil, "BACKGROUND")
    pin.halo:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.halo:SetTexture(st.WHITE)
    pin.halo:Hide()

    pin.shadow = pin:CreateTexture(nil, "BACKGROUND")
    pin.shadow:SetPoint("CENTER", pin, "CENTER", 0, -1)
    pin.shadow:SetTexture(NS.Styling.GLOW)
    pin.shadow:SetVertexColor(0, 0, 0, 0.8)

    pin.plate = pin:CreateTexture(nil, "ARTWORK")
    pin.plate:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.plate:SetTexture(st.WHITE)
    pin.plate:SetVertexColor(st.BG[1], st.BG[2], st.BG[3], 0.95)

    pin.border = CreateFrame("Frame", nil, pin)
    pin.border:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.border:SetBackdrop({ edgeFile = st.WHITE, edgeSize = 1 })
    pin.border:EnableMouse(false)

    pin.dot = pin:CreateTexture(nil, "OVERLAY")
    pin.dot:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.dot:SetTexture(st.WHITE)

    pin:SetScript("OnEnter", function(self)
        canvas.caption:ShowFor(self)
    end)
    pin:SetScript("OnLeave", function()
        canvas.caption:Hide()
    end)
    pin:SetScript("OnClick", function(self)
        if canvas.onQuestClick and self.questID then
            canvas.onQuestClick(self.questID)
        end
    end)

    canvas.pins[index] = pin
    return pin
end

local function UpdateQuestPins(canvas)
    if not QuestPOIGetQuestIDByVisibleIndex then return end

    local numEntries = QuestMapUpdateAllQuests and QuestMapUpdateAllQuests() or 0
    if QuestPOIUpdateIcons then QuestPOIUpdateIcons() end

    local st = S()
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local shown = 0

    for index = 1, numEntries do
        local questID, logIndex = QuestPOIGetQuestIDByVisibleIndex(index)
        if questID and logIndex and logIndex > 0 then
            local _, posX, posY, objectiveIndex = QuestPOIGetIconInfo(questID)
            if posX and posY and posX > 0 and posY > 0 then
                local title, _, _, _, _, _, isComplete = GetQuestLogTitle(logIndex)
                shown = shown + 1

                local pin = GetQuestPin(canvas, shown)
                pin.questID = questID
                pin.questLogIndex = logIndex
                pin.questTitle = title
                pin.objectiveIndex = objectiveIndex
                pin.mapX = posX
                pin.mapY = posY

                local function dress(size, r, g, b, halo)
                    pin:SetWidth(size + 8)
                    pin:SetHeight(size + 8)
                    pin.plate:SetWidth(size)
                    pin.plate:SetHeight(size)
                    pin.shadow:SetWidth(size + 14)
                    pin.shadow:SetHeight(size + 14)
                    pin.border:SetWidth(size)
                    pin.border:SetHeight(size)
                    pin.border:SetBackdropBorderColor(r, g, b, 0.95)
                    pin.dot:SetWidth(math.max(3, size - 8))
                    pin.dot:SetHeight(math.max(3, size - 8))
                    pin.dot:SetVertexColor(r, g, b, 1)
                    if halo then
                        pin.halo:SetWidth(size + 10)
                        pin.halo:SetHeight(size + 10)
                        pin.halo:SetVertexColor(r, g, b, 0.16)
                        pin.halo:Show()
                    else
                        pin.halo:Hide()
                    end
                end

                if questID == canvas.selectedQuest then
                    dress(15, st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3], true)
                    pin:SetFrameLevel(canvas.pinHolder:GetFrameLevel() + 2)
                elseif isComplete == 1 then
                    dress(11, st.GOLD[1], st.GOLD[2], st.GOLD[3], false)
                    pin:SetFrameLevel(canvas.pinHolder:GetFrameLevel() + 1)
                else
                    dress(11, 0.55, 0.58, 0.66, false)
                    pin:SetFrameLevel(canvas.pinHolder:GetFrameLevel() + 1)
                end

                pin:ClearAllPoints()
                pin:SetPoint("CENTER", canvas, "TOPLEFT", posX * width, -posY * height)
                pin:Show()
            end
        end
    end

    for index = shown + 1, #canvas.pins do
        canvas.pins[index]:Hide()
    end

    canvas.pinCount = shown
end

local function GetPartyDot(canvas, index)
    local dot = canvas.partyDots[index]
    if dot then return dot end

    dot = CreateFrame("Button", nil, canvas.pinHolder)
    dot:SetWidth(12)
    dot:SetHeight(12)

    dot.fill = dot:CreateTexture(nil, "OVERLAY")
    dot.fill:SetAllPoints()
    dot.fill:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon")

    dot:SetScript("OnEnter", function(self)
        if not self.memberName then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.memberName, 1, 1, 1)
        GameTooltip:Show()
    end)
    dot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    canvas.partyDots[index] = dot
    return dot
end

local function UpdatePartyDots(canvas)
    if not canvas.showsPlayerZone then
        for index = 1, #canvas.partyDots do canvas.partyDots[index]:Hide() end
        return
    end

    local count = GetNumPartyMembers() or 0
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local shown = 0

    for index = 1, count do
        local unit = "party" .. index
        local x, y = GetPlayerMapPosition(unit)
        if x and y and x > 0 and y > 0 then
            shown = shown + 1
            local dot = GetPartyDot(canvas, shown)
            dot.memberName = UnitName(unit)
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", canvas, "TOPLEFT", x * width, -y * height)
            dot:Show()
        end
    end

    for index = shown + 1, #canvas.partyDots do
        canvas.partyDots[index]:Hide()
    end
end

local function PlacePlayer(canvas)
    if not canvas.showsPlayerZone then
        canvas.player:Hide()
        canvas.playerCoords = nil
        if canvas.onCoords then canvas.onCoords(nil, nil) end
        return false
    end

    local x, y = GetPlayerMapPosition("player")
    if x and y and x > 0 and y > 0 then
        canvas.player:ClearAllPoints()
        canvas.player:SetPoint("CENTER", canvas, "TOPLEFT", x * canvas:GetWidth(), -y * canvas:GetHeight())
        canvas.player.coords = string.format("%.1f, %.1f", x * 100, y * 100)
        canvas.player:Show()
        canvas.playerCoords = canvas.player.coords
        if canvas.onCoords then canvas.onCoords(x, y) end
        return true
    end

    canvas.player:Hide()
    canvas.playerCoords = nil
    if canvas.onCoords then canvas.onCoords(nil, nil) end
    return false
end

function MapCanvas:Create(parent, name)
    local st = S()

    local canvas = CreateFrame("Frame", name, parent)
    canvas.tiles = {}
    canvas.overlays = {}
    canvas.landmarks = {}
    canvas.pins = {}
    canvas.partyDots = {}
    canvas.restoreArea = true

    for index = 1, NUM_TILES do
        local tile = canvas:CreateTexture(nil, "BACKGROUND")
        tile.column = math.fmod(index - 1, TILE_COLS)
        tile.row = math.floor((index - 1) / TILE_COLS)
        tile.imageX = tile.column * TILE_SIZE
        tile.imageY = tile.row * TILE_SIZE
        tile.imageWidth = math.min(TILE_SIZE, IMAGE_WIDTH - tile.imageX)
        tile.imageHeight = math.min(TILE_SIZE, IMAGE_HEIGHT - tile.imageY)
        tile:SetTexCoord(0, tile.imageWidth / TILE_SIZE, 0, tile.imageHeight / TILE_SIZE)
        canvas.tiles[index] = tile
    end

    canvas.pinHolder = CreateFrame("Frame", nil, canvas)
    canvas.pinHolder:SetAllPoints(canvas)
    canvas.pinHolder:SetFrameLevel(canvas:GetFrameLevel() + 4)

    local player = CreateFrame("Button", nil, canvas)
    player:SetWidth(22)
    player:SetHeight(22)
    player:SetFrameLevel(canvas:GetFrameLevel() + 8)
    player.icon = player:CreateTexture(nil, "OVERLAY")
    player.icon:SetAllPoints()
    player.icon:SetTexture("Interface\\Minimap\\MinimapArrow")
    player:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Вы", 1, 1, 1)
        if self.coords then GameTooltip:AddLine(self.coords, 0.7, 0.7, 0.75) end
        GameTooltip:Show()
    end)
    player:SetScript("OnLeave", function() GameTooltip:Hide() end)
    player:Hide()
    canvas.player = player

    local caption = CreateFrame("Frame", nil, canvas)
    caption:SetWidth(240)
    caption:SetHeight(44)
    caption:SetFrameLevel(canvas:GetFrameLevel() + 20)
    caption:SetBackdrop({ bgFile = st.WHITE, edgeFile = st.WHITE, edgeSize = 1 })
    caption:SetBackdropColor(0, 0, 0, 0.78)
    caption:SetBackdropBorderColor(st.GOLD[1], st.GOLD[2], st.GOLD[3], 0.7)

    caption.title = st.Label(caption, 11, "OUTLINE")
    caption.title:SetPoint("TOPLEFT", caption, "TOPLEFT", 6, -5)
    caption.title:SetPoint("TOPRIGHT", caption, "TOPRIGHT", -6, -5)
    caption.title:SetTextColor(st.GOLD[1], st.GOLD[2], st.GOLD[3])

    caption.objective = st.Label(caption, 10)
    caption.objective:SetPoint("TOPLEFT", caption.title, "BOTTOMLEFT", 0, -3)
    caption.objective:SetPoint("TOPRIGHT", caption.title, "BOTTOMRIGHT", 0, -3)
    caption.objective:SetTextColor(0.92, 0.92, 0.95)
    caption:Hide()

    function caption:ShowFor(pin)
        self.title:SetText(pin.questTitle or "")
        self.objective:SetText(ObjectiveTextFor(pin.questLogIndex, pin.objectiveIndex) or "")
        local height = 14 + (self.title:GetStringHeight() or 10) + (self.objective:GetStringHeight() or 10)
        self:SetHeight(math.max(height, 32))
        self:ClearAllPoints()

        local toLeft = pin.mapX and pin.mapX > 0.55
        local toTop = pin.mapY and pin.mapY > 0.75

        if toLeft then
            if toTop then
                self:SetPoint("BOTTOMRIGHT", pin, "TOPLEFT", -6, 6)
            else
                self:SetPoint("TOPRIGHT", pin, "BOTTOMLEFT", -6, -6)
            end
        else
            if toTop then
                self:SetPoint("BOTTOMLEFT", pin, "TOPRIGHT", 6, 6)
            else
                self:SetPoint("TOPLEFT", pin, "BOTTOMRIGHT", 6, -6)
            end
        end

        self:Show()
    end

    canvas.caption = caption

    canvas.overlayFrame = CreateFrame("Frame", nil, canvas)
    canvas.overlayFrame:SetAllPoints(canvas)
    canvas.overlayFrame:SetFrameLevel(canvas:GetFrameLevel() + 15)

    canvas.empty = st.Label(canvas, 12)
    canvas.empty:SetPoint("CENTER")
    canvas.empty:SetJustifyH("CENTER")
    canvas.empty:SetText("карта этой зоны недоступна")
    canvas.empty:SetTextColor(st.TEXT_DIM[1], st.TEXT_DIM[2], st.TEXT_DIM[3])
    canvas.empty:Hide()

    local function CosmicButton(caption, imageX, imageY, imageSize, zoomTarget)
        local button = CreateFrame("Button", nil, canvas)
        button:SetFrameLevel(canvas:GetFrameLevel() + 6)

        button.plate = button:CreateTexture(nil, "OVERLAY")
        button.plate:SetAllPoints()
        button.plate:SetTexture(st.WHITE)
        button.plate:SetVertexColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3], 0)

        button.label = st.Label(button, 16, "OUTLINE")
        button.label:SetPoint("CENTER")
        button.label:SetJustifyH("CENTER")
        button.label:SetText(caption)
        button.label:SetTextColor(1, 1, 1)

        button.imageX, button.imageY, button.imageSize = imageX, imageY, imageSize

        button:SetScript("OnEnter", function(self)
            self.plate:SetVertexColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3], 0.12)
            self.label:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
        end)
        button:SetScript("OnLeave", function(self)
            self.plate:SetVertexColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3], 0)
            self.label:SetTextColor(1, 1, 1)
        end)
        button:SetScript("OnClick", function()
            SetMapZoom(zoomTarget)
            canvas:Redraw()
            if canvas.onAreaChanged then canvas.onAreaChanged() end
        end)

        button:Hide()
        return button
    end

    canvas.cosmicButtons = {
        CosmicButton("Запределье", 115, 90, 320, 3),
        CosmicButton("Азерот", 593, 255, 366, WORLDMAP_WORLD_ID or 0),
    }

    canvas.highlight = canvas:CreateTexture(nil, "ARTWORK")
    canvas.highlight:SetBlendMode("ADD")
    canvas.highlight:SetAlpha(0.35)
    canvas.highlight:Hide()

    canvas.border = CreateFrame("Frame", nil, canvas)
    canvas.border:SetPoint("TOPLEFT", canvas, "TOPLEFT", -1, 1)
    canvas.border:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", 1, -1)
    canvas.border:SetBackdrop({ edgeFile = st.WHITE, edgeSize = 1 })
    canvas.border:SetBackdropBorderColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], st.BORDER[4])
    canvas.border:EnableMouse(false)

    canvas:EnableMouse(true)
    canvas:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            if self.zoneClicks then
                self:ZoomOut()
            end
            return
        end
        if self.zoneClicks then
            if self.stockHitTest and WorldMapButton and WorldMapButton_OnClick then
                WorldMapButton_OnClick(WorldMapButton, "LeftButton")
            elseif ProcessMapClick then
                local x, y = self:CursorPosition()
                if not x then return end
                ProcessMapClick(x, y)
            end
            self.highlight:Hide()
            self:Redraw()
            if self.onAreaChanged then self.onAreaChanged() end
            return
        end
        if self.onClick then self.onClick(self) end
    end)

    canvas:SetScript("OnSizeChanged", function(self)
        local unitX = self:GetWidth() / IMAGE_WIDTH
        local unitY = self:GetHeight() / IMAGE_HEIGHT

        for index = 1, #self.cosmicButtons do
            local button = self.cosmicButtons[index]
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self, "TOPLEFT", button.imageX * unitX, -button.imageY * unitY)
            button:SetWidth(button.imageSize * unitX)
            button:SetHeight(button.imageSize * unitY)
        end
        for index = 1, NUM_TILES do
            local tile = self.tiles[index]
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", self, "TOPLEFT", tile.imageX * unitX, -tile.imageY * unitY)
            tile:SetWidth(tile.imageWidth * unitX)
            tile:SetHeight(tile.imageHeight * unitY)
        end
    end)

    canvas:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.2 then return end
        self.elapsed = 0

        PlacePlayer(self)

        self.partyElapsed = (self.partyElapsed or 0) + 0.2
        if self.partyElapsed >= 1 then
            self.partyElapsed = 0
            UpdatePartyDots(self)
        end

        if self.zoneClicks then
            if self.onCursor then
                local x, y = self:CursorPosition()
                self.onCursor(x, y)
            end
            self:UpdateHighlight()
        end
    end)

    function canvas:CursorPosition()
        local cursorX, cursorY = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        cursorX, cursorY = cursorX / scale, cursorY / scale

        local left, top = self:GetLeft(), self:GetTop()
        if not left or not top then return nil end

        local x = (cursorX - left) / self:GetWidth()
        local y = (top - cursorY) / self:GetHeight()
        if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
        return x, y
    end

    function canvas:SetAspectWidth(width)
        self:SetWidth(width)
        self:SetHeight(width * IMAGE_HEIGHT / IMAGE_WIDTH)
    end

    function canvas:SelectQuest(questID)
        self.selectedQuest = questID
    end

    function canvas:Draw()
        UpdateTiles(self)
        UpdateOverlays(self)
        UpdateLandmarks(self)
        UpdateQuestPins(self)

        for index = 1, #self.cosmicButtons do
            if self.isCosmic then
                self.cosmicButtons[index]:Show()
            else
                self.cosmicButtons[index]:Hide()
            end
        end

        self.continent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
        self.zone = GetCurrentMapZone and GetCurrentMapZone() or 0
        self.level = GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
        self.areaName = self:AreaTitle()
    end

    function canvas:AreaTitle()
        local continents = { GetMapContinents() }
        local continent = self.continent or 0
        local zone = self.zone or 0

        if zone > 0 and continent > 0 then
            local zones = { GetMapZones(continent) }
            if zones[zone] then return zones[zone] end
        end
        if continent > 0 and continents[continent] then return continents[continent] end
        if self.isCosmic then return "Азерот и Запределье" end
        return "Весь мир"
    end

    function canvas:CapturePlayerArea()
        SetMapToCurrentZone()
        self.playerContinent = GetCurrentMapContinent and GetCurrentMapContinent() or 0
        self.playerZone = GetCurrentMapZone and GetCurrentMapZone() or 0
        self.playerLevel = GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() or 0
    end

    function canvas:MarkPlayerZone()
        self.showsPlayerZone = self.playerContinent ~= nil
            and self.continent == self.playerContinent
            and self.zone == self.playerZone
            and self.level == self.playerLevel

        PlacePlayer(self)
        UpdatePartyDots(self)
    end

    function canvas:ShowQuest(questID)
        self.caption:Hide()
        self.selectedQuest = questID
        self.restoreArea = true

        self:CapturePlayerArea()

        local mapID, floor = 0, 0
        if questID and GetQuestWorldMapAreaID then
            mapID, floor = GetQuestWorldMapAreaID(questID)
        end

        if mapID and mapID ~= 0 then
            SetMapByID(mapID)
            if floor and floor ~= 0 and SetDungeonMapLevel then SetDungeonMapLevel(floor) end
        end

        self:Draw()
        self:MarkPlayerZone()

        if self.playerContinent then
            SetMapZoom(self.playerContinent, self.playerZone)
        end
    end

    function canvas:Redraw()
        self.caption:Hide()
        self:Draw()
        self:MarkPlayerZone()
    end

    function canvas:ShowCurrentZone()
        self:CapturePlayerArea()
        self:Redraw()
    end

    function canvas:ZoomOut()
        local world = WORLDMAP_WORLD_ID or 0
        local cosmic = WORLDMAP_COSMIC_ID or -1
        local outland = WORLDMAP_OUTLAND_ID or 3

        if GetCurrentMapZone() ~= world then
            SetMapZoom(GetCurrentMapContinent())
        elseif GetCurrentMapContinent() == world then
            SetMapZoom(cosmic)
        elseif GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() > 0 then
            if ZoomOut then ZoomOut() end
        elseif GetCurrentMapContinent() == cosmic then
            if ZoomOut then ZoomOut() end
        elseif GetCurrentMapContinent() == outland then
            SetMapZoom(cosmic)
        else
            SetMapZoom(world)
        end

        self:Redraw()
        if self.onAreaChanged then self.onAreaChanged() end
    end

    function canvas:UpdateHighlight()
        if not self.zoneClicks then return end

        if self.stockHitTest then
            local text = WorldMapFrameAreaLabel and WorldMapFrameAreaLabel:GetText()
            if self:IsMouseOver() and text and text ~= "" then
                if self.onZoneHover then self.onZoneHover(text) end
            elseif self.onZoneHover then
                self.onZoneHover(nil)
            end
            return
        end

        if not UpdateMapHighlight then return end

        local x, y = self:CursorPosition()
        if not x or not self:IsMouseOver() then
            self.highlight:Hide()
            if self.onZoneHover then self.onZoneHover(nil) end
            return
        end

        local name, fileName, texPercentageX, texPercentageY, textureX, textureY,
              scrollChildX, scrollChildY, minLevel, maxLevel = UpdateMapHighlight(x, y)

        if fileName and textureX and textureY and textureX > 0 and textureY > 0 then
            self.highlight:SetTexture("Interface\\WorldMap\\" .. fileName .. "\\" .. fileName .. "Highlight")
            self.highlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
            self.highlight:SetWidth(textureX * self:GetWidth())
            self.highlight:SetHeight(textureY * self:GetHeight())
            self.highlight:ClearAllPoints()
            self.highlight:SetPoint("TOPLEFT", self, "TOPLEFT",
                scrollChildX * self:GetWidth(), -scrollChildY * self:GetHeight())
            self.highlight:Show()
        else
            self.highlight:Hide()
        end

        if self.onZoneHover then
            self.onZoneHover(name, minLevel, maxLevel)
        end
    end

    canvas:Hide()
    return canvas
end
