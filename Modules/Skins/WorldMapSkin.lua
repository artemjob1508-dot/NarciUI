local addonName, NS = ...
local L = NS.L

local WorldMapSkin = {}
NS.WorldMapSkin = WorldMapSkin

local TILE_SIZE = 256
local IMAGE_WIDTH = 1002
local IMAGE_HEIGHT = 668
local MAX_PIECES = 400

local DROPDOWNS = {
    "WorldMapContinentDropDown",
    "WorldMapZoneDropDown",
    "WorldMapZoneMinimapDropDown",
    "WorldMapLevelDropDown",
}

local WINDOW_W = 593
local WINDOW_H = 437
local FRAME_TEXTURES = 18

local BUTTONS = {
    "WorldMapZoomOutButton",
    "Gatherer_WorldMapDisplay",
}

local CHECKS = {
    "WorldMapQuestShowObjectives",
    "WorldMapTrackQuest",
}

local WINDOW_ART = {
    "WorldMapFrameMiniBorderLeft",
    "WorldMapFrameMiniBorderRight",
}

local ROW = {
    { name = "WorldMapContinentDropDown" },
    { name = "WorldMapZoneDropDown" },
    { name = "WorldMapZoomOutButton", plain = true },
    { name = "WorldMapLevelDropDown", optional = true },
    { name = "WorldMapZoneMinimapDropDown" },
}

local discovered = {}
local overlays = {}
local applied = false

local function S()
    return NS.QuestStyle
end

local function Enabled()
    return NS.questDB and NS.questDB.skinWorldMap ~= false
end

local function StyleDropDown(name)
    local frame = _G[name]
    if not frame then return end
    local st = S()

    for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
        local texture = _G[name .. suffix]
        if texture then texture:SetAlpha(0) end
    end

    if not frame.narciBackdrop then
        local backdrop = CreateFrame("Frame", nil, frame)
        backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -6)
        backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 8)
        backdrop:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 1))
        st.Backdrop(backdrop, 0.05, 0.06, 0.09, 0.95)
        frame.narciBackdrop = backdrop
    end
    frame.narciBackdrop:Show()

    local text = _G[name .. "Text"]
    if text then text:SetTextColor(st.TEXT[1], st.TEXT[2], st.TEXT[3]) end

    local button = _G[name .. "Button"]
    if button then
        local normal = button:GetNormalTexture()
        if normal then normal:SetVertexColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3]) end
    end
end

local function RestoreDropDown(name)
    local frame = _G[name]
    if not frame then return end

    for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
        local texture = _G[name .. suffix]
        if texture then texture:SetAlpha(1) end
    end

    if frame.narciBackdrop then frame.narciBackdrop:Hide() end

    local button = _G[name .. "Button"]
    if button then
        local normal = button:GetNormalTexture()
        if normal then normal:SetVertexColor(1, 1, 1) end
    end
end

local function StyleCheck(name)
    local button = _G[name]
    if not button then return end
    local st = S()

    button:SetNormalTexture(nil)
    button:SetPushedTexture(nil)
    button:SetHighlightTexture(nil)

    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetTexture(st.WHITE)
        checked:SetVertexColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3], 1)
        checked:ClearAllPoints()
        checked:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -8)
        checked:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 8)
    end

    if not button.narciBackdrop then
        local backdrop = CreateFrame("Frame", nil, button)
        backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
        backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
        backdrop:SetFrameLevel(math.max(button:GetFrameLevel() - 1, 1))
        st.Backdrop(backdrop, 0.06, 0.07, 0.10, 0.95)
        button.narciBackdrop = backdrop
    end
    button.narciBackdrop:Show()
end

local function RestoreCheck(name)
    local button = _G[name]
    if not button then return end

    button:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetBlendMode("ADD") end

    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checked:SetVertexColor(1, 1, 1, 1)
        checked:ClearAllPoints()
        checked:SetAllPoints(button)
    end

    if button.narciBackdrop then button.narciBackdrop:Hide() end
end

local function ButtonArt(button)
    return { button.Left, button.Middle, button.Right, button:GetHighlightTexture() }
end

local function StyleButton(name)
    local button = _G[name]
    if not button then return end
    local st = S()

    for _, texture in ipairs(ButtonArt(button)) do
        if texture then texture:SetAlpha(0) end
    end

    if not button.narciBackdrop then
        local backdrop = CreateFrame("Frame", nil, button)
        backdrop:SetAllPoints(button)
        backdrop:SetFrameLevel(math.max(button:GetFrameLevel() - 1, 1))
        st.Backdrop(backdrop, 0.08, 0.09, 0.13, 0.95)

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(st.WHITE)
        highlight:SetVertexColor(1, 1, 1, 1)

        button.narciBackdrop = backdrop
        button.narciHighlight = highlight
    end
    button.narciBackdrop:Show()
    button.narciHighlight:SetAlpha(0.08)

    local text = button:GetFontString()
    if text then text:SetTextColor(st.TEXT[1], st.TEXT[2], st.TEXT[3]) end
end

local function RestoreButton(name)
    local button = _G[name]
    if not button then return end

    for _, texture in ipairs(ButtonArt(button)) do
        if texture then texture:SetAlpha(1) end
    end

    if button.narciBackdrop then button.narciBackdrop:Hide() end
    if button.narciHighlight then button.narciHighlight:SetAlpha(0) end

    local text = button:GetFontString()
    if text then text:SetTextColor(1, 0.82, 0) end
end

local function RestoreRow()
    if not WorldMapPositioningGuide then return end

    if WorldMapZoneMinimapDropDown then
        WorldMapZoneMinimapDropDown:ClearAllPoints()
        WorldMapZoneMinimapDropDown:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 20, -35)
    end

    if WorldMapContinentDropDown then
        WorldMapContinentDropDown:ClearAllPoints()
        WorldMapContinentDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOP", -50, -35)
    end

    if WorldMapZoneDropDown then
        WorldMapZoneDropDown:ClearAllPoints()
        WorldMapZoneDropDown:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -70, -35)
    end

    if WorldMapZoomOutButton and WorldMapZoneDropDown then
        WorldMapZoomOutButton:ClearAllPoints()
        WorldMapZoomOutButton:SetPoint("LEFT", WorldMapZoneDropDown, "RIGHT", -10, 3)
    end

    if WorldMapLevelDropDown then
        WorldMapLevelDropDown:ClearAllPoints()
        if WORLDMAP_SETTINGS and WORLDMAP_WINDOWED_SIZE
            and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE then
            WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -421, -21)
        else
            WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -50, -35)
        end
    end
end

local function RaiseMap()
    if not WorldMapFrame then return end
    if not WorldMapSkin.stockStrata then
        WorldMapSkin.stockStrata = WorldMapFrame:GetFrameStrata()
    end
    WorldMapFrame:SetFrameStrata("DIALOG")
end

local function LowerMap()
    if not WorldMapFrame or not WorldMapSkin.stockStrata then return end
    WorldMapFrame:SetFrameStrata(WorldMapSkin.stockStrata)
end

local function HideArt()
    for _, name in ipairs(WINDOW_ART) do
        local texture = _G[name]
        if texture then texture:SetAlpha(0) end
    end

    for _, name in ipairs(DROPDOWNS) do StyleDropDown(name) end
    for _, name in ipairs(BUTTONS) do StyleButton(name) end
    for _, name in ipairs(CHECKS) do StyleCheck(name) end
end

local function ShowArt()
    for _, name in ipairs(WINDOW_ART) do
        local texture = _G[name]
        if texture then texture:SetAlpha(1) end
    end

    for _, name in ipairs(DROPDOWNS) do RestoreDropDown(name) end
    for _, name in ipairs(BUTTONS) do RestoreButton(name) end
    for _, name in ipairs(CHECKS) do RestoreCheck(name) end
end

local function BigView()
    return WORLDMAP_SETTINGS ~= nil and WORLDMAP_WINDOWED_SIZE ~= nil
        and WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE
end

local function Compact()
    return Enabled() and NS.questDB.compactMap ~= false
end

local function MapScale()
    local scale = NS.questDB and NS.questDB.mapScale
    if type(scale) ~= "number" or scale < 0.5 or scale > 2 then return 1.2 end
    return scale
end

local function FrameTextures(alpha)
    for index = 1, FRAME_TEXTURES do
        local texture = _G["WorldMapFrameTexture" .. index]
        if texture then texture:SetAlpha(alpha) end
    end
end

local function Foreign(alpha)
    if WorldMapFrameTitle then WorldMapFrameTitle:SetAlpha(alpha) end
    local tomtom = _G.TomTomWorldFrame
    if tomtom and tomtom.SetAlpha then tomtom:SetAlpha(alpha) end
end

local function Percent(value)
    local digits = NS.questDB and NS.questDB.mapCoordDigits or 1
    return string.format(digits == 0 and "%.0f" or (digits == 2 and "%.2f" or "%.1f"), value * 100)
end

local function UpdateCoords(window, elapsed)
    window.elapsed = (window.elapsed or 0) + elapsed
    if window.elapsed < 0.05 then return end
    window.elapsed = 0

    if NS.questDB and NS.questDB.mapCoords == false then
        if window.coords:GetText() ~= "" then window.coords:SetText("") end
        return
    end

    local text
    local x, y = GetPlayerMapPosition("player")

    if x and y and (x > 0 or y > 0) then
        text = L["Вы"] .. "  " .. Percent(x) .. ", " .. Percent(y)
    else
        text = L["Вы"] .. "  -"
    end

    local detail = WorldMapDetailFrame
    if detail:IsMouseOver() and detail:GetLeft() then
        local cursorX, cursorY = GetCursorPosition()
        local scale = detail:GetEffectiveScale()
        local width, height = detail:GetWidth(), detail:GetHeight()
        local mapX = (cursorX / scale - detail:GetLeft()) / width
        local mapY = (detail:GetTop() - cursorY / scale) / height

        if mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
            text = text .. "      " .. L["Курсор"] .. "  " .. Percent(mapX) .. ", " .. Percent(mapY)
        end
    end

    window.coords:SetText(text)
end

local function CreateChrome()
    if WorldMapSkin.chrome or not WorldMapFrame then return WorldMapSkin.chrome end
    local st = S()

    local chrome = CreateFrame("Frame", "NarcissusSirus_WorldMapChrome", WorldMapFrame)
    chrome:SetFrameLevel(1)

    chrome.panel = CreateFrame("Frame", nil, chrome)
    chrome.panel:SetFrameLevel(chrome:GetFrameLevel())
    chrome.panel:EnableMouse(false)
    st.Backdrop(chrome.panel, st.BG[1], st.BG[2], st.BG[3], 0.96)

    chrome.bar = CreateFrame("Frame", nil, chrome)
    chrome.bar:SetHeight(50)
    chrome.bar:SetFrameLevel(chrome:GetFrameLevel())
    chrome.bar:EnableMouse(false)
    st.Backdrop(chrome.bar, st.BG[1], st.BG[2], st.BG[3], 0.96)

    chrome.bar.title = chrome.bar:CreateFontString(nil, "OVERLAY")
    chrome.bar.title:SetFont(st.FONT, NS.FS(15), "")
    chrome.bar.title:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
    chrome.bar.title:SetPoint("LEFT", chrome.bar, "LEFT", 14, 0)

    chrome.bar.divider = chrome.bar:CreateTexture(nil, "ARTWORK")
    chrome.bar.divider:SetWidth(1)
    chrome.bar.divider:SetTexture(st.WHITE)
    chrome.bar.divider:SetVertexColor(st.ACCENT[1], st.ACCENT[2], st.ACCENT[3], 0.5)
    chrome.bar.divider:SetPoint("TOP", chrome.bar, "TOP", 0, -8)
    chrome.bar.divider:SetPoint("BOTTOM", chrome.bar, "BOTTOM", 0, 8)

    chrome.bar:Hide()

    chrome.window = CreateFrame("Frame", nil, chrome)
    chrome.window:SetFrameLevel(chrome:GetFrameLevel())
    chrome.window:EnableMouse(false)
    if NS.SkinKit then
        NS.SkinKit.Window(chrome.window, { inset = 14, depth = 1 })
    else
        st.Backdrop(chrome.window, st.BG[1], st.BG[2], st.BG[3], 0.96)
    end

    chrome.window.rule = chrome.window:CreateTexture(nil, "ARTWORK")
    chrome.window.rule:SetHeight(1)
    chrome.window.rule:SetTexture(st.WHITE)
    chrome.window.rule:SetVertexColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], 0.9)

    chrome.window.coords = chrome.window:CreateFontString(nil, "OVERLAY")
    chrome.window.coords:SetFont(st.FONT, NS.FS(11), "")
    chrome.window.coords:SetTextColor(st.TEXT[1], st.TEXT[2], st.TEXT[3])
    chrome.window.coords:SetPoint("BOTTOM", chrome.window, "BOTTOM", 0, 10)

    chrome.window:SetScript("OnUpdate", UpdateCoords)
    chrome.window:Hide()

    chrome.mapBorder = CreateFrame("Frame", nil, chrome)
    chrome.mapBorder:SetBackdrop({ edgeFile = st.WHITE, edgeSize = 1 })
    chrome.mapBorder:SetBackdropBorderColor(st.BORDER[1], st.BORDER[2], st.BORDER[3], st.BORDER[4])
    chrome.mapBorder:EnableMouse(false)
    chrome.mapBorder:SetFrameLevel(chrome:GetFrameLevel())

    WorldMapSkin.chrome = chrome
    return chrome
end

local function DropDownText(frame)
    if not frame or not UIDropDownMenu_GetText then return nil end
    local text = UIDropDownMenu_GetText(frame)
    if text and text ~= "" then return text end
    return nil
end

local function BarTitle()
    local continentId = GetCurrentMapContinent and GetCurrentMapContinent()

    if continentId == WORLDMAP_COSMIC_ID then
        return WORLD_MAP or ""
    end

    if continentId == WORLDMAP_WORLD_ID then
        return AZEROTH or WORLD_MAP or ""
    end

    local zoneId = WorldMapZoneDropDown and UIDropDownMenu_GetSelectedID(WorldMapZoneDropDown)
    if zoneId and zoneId > 0 then
        local zone = DropDownText(WorldMapZoneDropDown)
        if zone then return zone end
    end

    local continent = DropDownText(WorldMapContinentDropDown)
    if continent then return continent end

    return WORLD_MAP or ""
end

local function LayoutBar(chrome)
    local bar = chrome.bar
    local title = bar.title

    title:SetText(BarTitle())

    local x = 14 + math.max(title:GetStringWidth(), 60) + 16
    bar.divider:ClearAllPoints()
    bar.divider:SetPoint("TOPLEFT", bar, "TOPLEFT", x - 8, -8)
    bar.divider:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x - 8, 8)

    for _, entry in ipairs(ROW) do
        local frame = _G[entry.name]
        local visible = frame and frame:IsShown()
        if visible and entry.optional then
            visible = DropDownText(frame) ~= nil
        end

        if visible then
            frame:ClearAllPoints()
            if entry.plain then
                frame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x, 13)
                x = x + frame:GetWidth() + 8
            else
                frame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", x - 18, 4)
                x = x + (frame:GetWidth() - 34) + 8
            end
        end
    end

    if WorldMapFrameTitle then WorldMapFrameTitle:Hide() end

    bar:SetWidth(x + 12)
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", WorldMapDetailFrame, "TOP", 0, 10)
    bar:Show()
end

local function LayoutBare(chrome)
    chrome.panel:Hide()
    chrome.window:Hide()
    FrameTextures(1)
    Foreign(1)
    chrome:ClearAllPoints()
    chrome:SetAllPoints(WorldMapFrame)
    LayoutBar(chrome)
end

local TOOLBAR = {
    { name = "WorldMapContinentDropDown", width = 110 },
    { name = "WorldMapZoneDropDown", width = 130 },
    { name = "WorldMapZoomOutButton", plain = true },
    { name = "WorldMapLevelDropDown", width = 110, optional = true },
}

local function SavePosition()
    local frame = WorldMapFrame
    if not frame or not frame:GetLeft() or not NS.questDB then return end

    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    NS.questDB.mapX = math.floor(frame:GetLeft() * ratio + 0.5)
    NS.questDB.mapY = math.floor(frame:GetTop() * ratio - UIParent:GetHeight() + 0.5)
end

function WorldMapSkin:ApplyPosition()
    if not WorldMapFrame or not WorldMapScreenAnchor or BigView() or not Compact() then return end
    if InCombatLockdown() then return end

    local x, y = NS.questDB.mapX, NS.questDB.mapY
    if type(x) ~= "number" or type(y) ~= "number" then return end

    local ratio = UIParent:GetEffectiveScale() / WorldMapScreenAnchor:GetEffectiveScale()

    self.placing = true
    WorldMapScreenAnchor:ClearAllPoints()
    WorldMapScreenAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x * ratio, y * ratio)
    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor, "TOPLEFT", 0, 0)
    self.placing = nil
end

local function CenterPanel()
    local frame = WorldMapFrame
    if not frame:GetAttribute("UIPanelLayout-defined") then
        frame:SetAttribute("UIPanelLayout-defined", true)
        frame:SetAttribute("UIPanelLayout-pushable", 0)
        frame:SetAttribute("UIPanelLayout-whileDead", 1)
        frame:SetAttribute("UIPanelLayout-enabled", true)
    end
    frame:SetAttribute("UIPanelLayout-area", "center")
    frame:SetAttribute("UIPanelLayout-allowOtherPanels", true)
end

local function EnsureAdvanced()
    if not WorldMapFrame or not Compact() or BigView() or InCombatLockdown() then return end

    local shown = WorldMapFrame:IsShown()
    if not shown then CenterPanel() end

    if WORLDMAP_SETTINGS.advanced and WorldMapFrame:GetAttribute("UIPanelLayout-area") == "center" then return end

    SetCVar("advancedWorldMap", "1")
    WORLDMAP_SETTINGS.advanced = true
    if not shown then CenterPanel() end
    if WorldMapFrame_SetMiniMode then WorldMapFrame_SetMiniMode() end
end

WorldMapSkin.EnsureAdvanced = EnsureAdvanced

function WorldMapSkin:HookPosition()
    if self.positionHooked or not WorldMapFrame then return end
    self.positionHooked = true

    hooksecurefunc(WorldMapFrame, "SetPoint", function()
        if WorldMapSkin.placing or WorldMapSkin.dragging then return end
        if not Compact() or BigView() or InCombatLockdown() then return end
        if type(NS.questDB.mapX) ~= "number" then return end
        WorldMapSkin:ApplyPosition()
    end)
end

local function StartDrag()
    if InCombatLockdown() then
        NS.Print(L["В бою двигать нельзя"])
        return
    end

    EnsureAdvanced()
    WorldMapSkin.dragging = true
    WorldMapFrame:SetMovable(true)
    WorldMapFrame:StartMoving()
end

local function StopDrag()
    if not WorldMapSkin.dragging then return end
    WorldMapSkin.dragging = nil

    WorldMapFrame:StopMovingOrSizing()
    SavePosition()
    WorldMapSkin:ApplyPosition()

    if WorldMapBlobFrame_CalculateHitTranslations then
        pcall(WorldMapBlobFrame_CalculateHitTranslations)
    end
end

local function BuildHandle(window)
    if window.handle then return window.handle end

    local handle = CreateFrame("Button", nil, window)
    handle:SetHeight(28)
    handle:SetPoint("TOPLEFT", window, "TOPLEFT", 0, 0)
    handle:SetPoint("TOPRIGHT", window, "TOPRIGHT", -30, 0)
    handle:RegisterForDrag("LeftButton")
    handle:RegisterForClicks("RightButtonUp")
    handle:SetScript("OnDragStart", StartDrag)
    handle:SetScript("OnDragStop", StopDrag)
    handle:SetScript("OnHide", StopDrag)
    handle:EnableMouseWheel(true)
    handle:SetScript("OnMouseWheel", function(_, delta)
        if not IsControlKeyDown() then return end
        WorldMapSkin:SetScale(MapScale() + (delta > 0 and 0.05 or -0.05))
    end)
    handle:SetScript("OnClick", function()
        if WorldMapTitleDropDown and ToggleDropDownMenu then
            ToggleDropDownMenu(1, nil, WorldMapTitleDropDown, "cursor", 0, 0)
        end
    end)

    local st = S()
    handle.title = handle:CreateFontString(nil, "OVERLAY")
    handle.title:SetFont(st.FONT, NS.FS(13), "")
    handle.title:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
    handle.title:SetPoint("LEFT", handle, "LEFT", 12, 0)

    handle.hint = handle:CreateFontString(nil, "OVERLAY")
    handle.hint:SetFont(st.FONT, NS.FS(10), "")
    handle.hint:SetTextColor(st.TEXT_DIM and st.TEXT_DIM[1] or 0.5, st.TEXT_DIM and st.TEXT_DIM[2] or 0.5, st.TEXT_DIM and st.TEXT_DIM[3] or 0.5)
    handle.hint:SetPoint("RIGHT", handle, "RIGHT", -6, 0)
    handle.hint:SetText(L["перетащите за заголовок"])

    window.handle = handle
    return handle
end

local function HideHeaders(frame)
    local text = _G[frame:GetName() .. "Text"]
    for _, region in ipairs({ frame:GetRegions() }) do
        if region ~= text and region:GetObjectType() == "FontString" then
            region:SetAlpha(0)
        end
    end
end

local function LayoutToolbar(window)
    local x = 8
    local top = -30

    for _, entry in ipairs(TOOLBAR) do
        local frame = _G[entry.name]
        local visible = frame ~= nil

        if visible and entry.optional then
            visible = frame:IsShown() and DropDownText(frame) ~= nil
        end

        if frame then
            if visible then
                if not entry.optional then frame:Show() end
                if not entry.plain then HideHeaders(frame) end
                if entry.width and UIDropDownMenu_SetWidth and not frame.narciWidth then
                    frame.narciWidth = true
                    UIDropDownMenu_SetWidth(frame, entry.width)
                end

                frame:ClearAllPoints()
                if entry.plain then
                    frame:SetPoint("TOPLEFT", window, "TOPLEFT", x, top - 5)
                    x = x + frame:GetWidth() + 8
                else
                    frame:SetPoint("TOPLEFT", window, "TOPLEFT", x - 16, top + 1)
                    x = x + (frame:GetWidth() - 34) + 8
                end
            elseif entry.optional then
                frame:Hide()
            end
        end
    end

    if WorldMapZoneMinimapDropDown then WorldMapZoneMinimapDropDown:Hide() end
    if WorldMapLevelUpButton then WorldMapLevelUpButton:Hide() end
    if WorldMapLevelDownButton then WorldMapLevelDownButton:Hide() end
end

local function LayoutWindow(chrome)
    local window = chrome.window
    local compact = Compact()

    chrome.bar:Hide()
    chrome.panel:Hide()
    chrome:ClearAllPoints()
    chrome:SetAllPoints(WorldMapFrame)

    FrameTextures(0)
    Foreign(0)
    EnsureAdvanced()

    local header = compact and 62 or 34

    window:ClearAllPoints()
    window:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -8, header)
    window:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", 8, -30)
    window:Show()

    window.rule:ClearAllPoints()
    window.rule:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -28)
    window.rule:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, -28)

    local handle = BuildHandle(window)
    handle:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 30)
    handle.title:SetText(BarTitle())
    handle:Show()

    if WorldMapTitleButton then WorldMapTitleButton:Hide() end

    local close = WorldMapFrameCloseButton
    if close then
        if NS.SkinKit then NS.SkinKit.Close(close) end
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -3)
        close:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 31)
    end

    if compact then
        LayoutToolbar(window)
        if WorldMapFrameSizeUpButton then WorldMapFrameSizeUpButton:Hide() end
        if WorldMapFrameSizeDownButton then WorldMapFrameSizeDownButton:Hide() end
    elseif WorldMapLevelDropDown then
        WorldMapLevelDropDown:ClearAllPoints()
        WorldMapLevelDropDown:SetPoint("TOPLEFT", window, "TOPLEFT", -10, -28)
    end
end

function WorldMapSkin:ApplyScale()
    if not WorldMapFrame or BigView() or not Compact() or InCombatLockdown() then return end

    local scale = MapScale()
    if math.abs(WorldMapFrame:GetScale() - scale) < 0.001 then return end

    WorldMapFrame:SetScale(scale)

    if WorldMapBlobFrame_CalculateHitTranslations then
        pcall(WorldMapBlobFrame_CalculateHitTranslations)
    end
end

function WorldMapSkin:SetScale(scale)
    if not NS.questDB then return end

    scale = math.floor(math.max(0.6, math.min(2, scale)) * 20 + 0.5) / 20
    NS.questDB.mapScale = scale

    if InCombatLockdown() then
        NS.Print(L["Масштаб карты изменится после боя"])
        return
    end

    if WorldMapFrame and WorldMapFrame:IsShown() then
        self:Apply()
    end
end

function WorldMapSkin:CenterWindow()
    if not WorldMapScreenAnchor or InCombatLockdown() then return end

    local scale = MapScale()
    local x = math.floor((UIParent:GetWidth() - WINDOW_W * scale) / 2)
    local y = math.floor((UIParent:GetHeight() - WINDOW_H * scale) / 2)

    NS.questDB.mapX, NS.questDB.mapY = x, -y
    self:ApplyPosition()
end

function WorldMapSkin:MakeCompact()
    if not Compact() or not BigView() or self.converting or InCombatLockdown() then return end
    if not WorldMapFrame:IsShown() then return end
    if type(WorldMapFrame_ToggleWindowSize) ~= "function" then return end

    self.converting = true

    SetCVar("advancedWorldMap", "1")
    SetCVar("miniWorldMap", "1")
    WORLDMAP_SETTINGS.advanced = true

    local firstTime = not NS.questDB.compactPlaced
    NS.questDB.compactPlaced = true

    NS.After(0, function()
        if not InCombatLockdown() and BigView() and WorldMapFrame:IsShown() then
            WorldMapFrame_ToggleWindowSize()
        end

        if firstTime then WorldMapSkin:CenterWindow() end
        WorldMapSkin.converting = nil
        if not BigView() then WorldMapSkin:Apply() end
    end)
end

local function FitChrome()
    local chrome = WorldMapSkin.chrome
    if not chrome or not WorldMapDetailFrame or not WorldMapDetailFrame:GetLeft() then return end

    if BigView() then
        LayoutBare(chrome)
    else
        LayoutWindow(chrome)
    end

    chrome.mapBorder:ClearAllPoints()
    chrome.mapBorder:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -2, 2)
    chrome.mapBorder:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", 2, -2)
end

local function StyleTitle()
    if WorldMapFrameTitle then
        local st = S()
        WorldMapFrameTitle:SetTextColor(st.ACCENT_GLOW[1], st.ACCENT_GLOW[2], st.ACCENT_GLOW[3])
    end
end

local function DrawOverlay(parent, used, unitX, unitY, textureName, textureWidth, textureHeight, offsetX, offsetY)
    if not textureWidth or not textureHeight then return used end
    if textureWidth <= 0 or textureHeight <= 0 then return used end
    if textureWidth > IMAGE_WIDTH or textureHeight > IMAGE_HEIGHT then return used end
    if (offsetX or 0) < 0 or (offsetY or 0) < 0 then return used end

    local wide = math.ceil(textureWidth / TILE_SIZE)
    local tall = math.ceil(textureHeight / TILE_SIZE)
    if used + wide * tall > MAX_PIECES then return used end

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
            local texture = overlays[used]
            if not texture then
                texture = parent:CreateTexture(nil, "BORDER")
                overlays[used] = texture
            end

            texture:SetTexture(textureName .. (((row - 1) * wide) + column))
            texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
            texture:SetWidth(pixelWidth * unitX)
            texture:SetHeight(pixelHeight * unitY)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", parent, "TOPLEFT",
                (offsetX + TILE_SIZE * (column - 1)) * unitX,
                -(offsetY + TILE_SIZE * (row - 1)) * unitY)
            texture:SetVertexColor(WorldMapSkin.fogR, WorldMapSkin.fogG, WorldMapSkin.fogB, WorldMapSkin.fogA)
            texture:Show()
        end
    end

    return used
end

local FOG_COLORS = {
    grey   = { 0.62, 0.62, 0.70 },
    bright = { 1.00, 1.00, 1.00 },
    dark   = { 0.30, 0.30, 0.36 },
    sepia  = { 0.80, 0.66, 0.46 },
}

function WorldMapSkin:FogColor()
    local db = NS.questDB or {}
    local key = db.fogColor or "grey"
    local r, g, b
    if key == "theme" then
        local A = NS.Styling.ACCENT
        r, g, b = A[1], A[2], A[3]
    else
        local c = FOG_COLORS[key] or FOG_COLORS.grey
        r, g, b = c[1], c[2], c[3]
    end
    self.fogR, self.fogG, self.fogB = r, g, b
    self.fogA = (db.fogAlpha or 85) / 100
end

function WorldMapSkin:WatchMovement()
    if self.mover or not WorldMapFrame then return end
    local watcher = CreateFrame("Frame", nil, WorldMapFrame)
    local current = 1
    watcher:SetScript("OnUpdate", function(_, elapsed)
        local db = NS.questDB
        local target = 1
        if Enabled() and db and (db.mapMoveAlpha or 100) < 100 then
            local speed = GetUnitSpeed and GetUnitSpeed("player") or 0
            if speed > 0 and not MouseIsOver(WorldMapFrame) then
                target = db.mapMoveAlpha / 100
            end
        elseif current == 1 then
            return
        end
        if math.abs(current - target) < 0.01 then
            if current ~= target then
                current = target
                WorldMapFrame:SetAlpha(current)
            end
            return
        end
        local step = math.min(1, elapsed * 6)
        current = current + (target - current) * step
        WorldMapFrame:SetAlpha(current)
    end)
    watcher:SetScript("OnHide", function()
        current = 1
        WorldMapFrame:SetAlpha(1)
    end)
    self.mover = watcher
end

function WorldMapSkin:RevealFog()
    if not WorldMapDetailFrame then return end

    if not Enabled() or not NS.questDB or NS.questDB.revealMap == false then
        for index = 1, #overlays do overlays[index]:Hide() end
        return
    end

    local fileName = GetMapInfo()
    if not fileName or not NS.MAP_OVERLAYS or not NS.MAP_OVERLAYS[fileName] then
        for index = 1, #overlays do overlays[index]:Hide() end
        return
    end

    self:FogColor()
    local unitX = WorldMapDetailFrame:GetWidth() / IMAGE_WIDTH
    local unitY = WorldMapDetailFrame:GetHeight() / IMAGE_HEIGHT
    local prefix = "Interface\\WorldMap\\" .. fileName .. "\\"
    local prefixLength = string.len(prefix) + 1
    local used = 0

    for key in pairs(discovered) do discovered[key] = nil end

    for index = 1, (GetNumMapOverlays() or 0) do
        local textureName = GetMapOverlayInfo(index)
        if textureName and textureName ~= "" then
            discovered[string.sub(textureName, prefixLength)] = true
        end
    end

    for shortName, packed in pairs(NS.MAP_OVERLAYS[fileName]) do
        if not discovered[shortName] then
            local textureWidth = math.fmod(packed, 1024)
            local textureHeight = math.fmod(math.floor(packed / 1024), 1024)
            local offsetX = math.fmod(math.floor(packed / 1048576), 1024)
            local offsetY = math.floor(packed / 1073741824)
            used = DrawOverlay(WorldMapDetailFrame, used, unitX, unitY, prefix .. shortName,
                textureWidth, textureHeight, offsetX, offsetY)
        end
    end

    for index = used + 1, #overlays do
        overlays[index]:Hide()
    end
end

function WorldMapSkin:Apply()
    if not WorldMapFrame or not Enabled() then return end
    RaiseMap()
    HideArt()
    CreateChrome()
    StyleTitle()
    self:MakeCompact()
    self:ApplyScale()
    self:ApplyPosition()
    if self.chrome then
        self.chrome:Show()
        FitChrome()
        NS.After(0, FitChrome)
    end
    applied = true
end

function WorldMapSkin:Remove()
    LowerMap()
    ShowArt()
    RestoreRow()
    if WorldMapFrameTitle then WorldMapFrameTitle:Show() end
    if self.chrome then self.chrome.bar:Hide() end
    if self.chrome then self.chrome:Hide() end
    FrameTextures(1)
    Foreign(1)
    for index = 1, #overlays do overlays[index]:Hide() end
    applied = false
end

function WorldMapSkin:Toggle()
    if not NS.questDB then return end
    NS.questDB.skinWorldMap = not Enabled()
    if Enabled() then
        self:Apply()
        self:RevealFog()
    else
        self:Remove()
    end
    return Enabled()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function()
    if not WorldMapFrame then return end

    WorldMapSkin:HookPosition()
    WorldMapSkin:WatchMovement()

    NS.After(1, function()
        if Enabled() then EnsureAdvanced() end
    end)

    WorldMapFrame:HookScript("OnHide", function()
        if not Enabled() then return end
        NS.After(0, function()
            EnsureAdvanced()
            WorldMapSkin:ApplyPosition()
        end)
    end)

    WorldMapFrame:HookScript("OnShow", function()
        if not Enabled() then return end
        WorldMapSkin:Apply()
        WorldMapSkin:RevealFog()
    end)

    for _, name in ipairs({ "WorldMap_ToggleSizeUp", "WorldMap_ToggleSizeDown",
        "WorldMapFrame_SetFullMapView", "WorldMapFrame_SetQuestMapView",
        "WorldMapFrame_SetMiniMode" }) do
        if _G[name] then
            hooksecurefunc(name, function()
                if not Enabled() then return end
                WorldMapSkin:Apply()
                NS.After(0, function()
                    WorldMapSkin:Apply()
                    WorldMapSkin:RevealFog()
                end)
            end)
        end
    end

    if WorldMapFrame_Update then
        hooksecurefunc("WorldMapFrame_Update", function()
            if not Enabled() then return end
            if not applied then WorldMapSkin:Apply() end
            FitChrome()
            WorldMapSkin:RevealFog()
        end)
    end
end)
