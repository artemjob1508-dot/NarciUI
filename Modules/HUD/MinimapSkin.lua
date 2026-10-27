local addonName, NS = ...
local L = NS.L

local MinimapSkin = {}
NS.MinimapSkin = MinimapSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local HIDE = {
    "MinimapBorder", "MinimapBorderTop", "MinimapNorthTag",
    "MinimapZoomIn", "MinimapZoomOut", "MiniMapWorldMapButton",
    "MiniMapMailBorder", "MiniMapTrackingBorder", "MiniMapTrackingButtonBorder",
    "MiniMapLFGFrameBorder", "MiniMapBattlefieldBorder", "MiniMapVoiceChatFrame",
    "GameTimeFrame",
}

local function FillSettings()
    if not NS.db then return end

    if not NS.db.minimap then NS.db.minimap = {} end

    local db = NS.db.minimap
    if db.enabled == nil then db.enabled = false end
    if db.square == nil then db.square = true end
    if db.hideZoneText == nil then db.hideZoneText = false end
    if db.hideClock == nil then db.hideClock = false end
    if db.coords == nil then db.coords = false end
    if db.infoPanel == nil then db.infoPanel = true end
    if db.infoCoords == nil then db.infoCoords = true end
    if db.infoFps == nil then db.infoFps = true end
    if db.infoPing == nil then db.infoPing = true end
    if db.infoFriends == nil then db.infoFriends = true end
    db.coordStyle = db.coordStyle or "plate"
    db.coordFormat = db.coordFormat or "xy"
    db.coordPos = db.coordPos or "bottom"
    db.coordScale = db.coordScale or 100
    if db.infoGuild == nil then db.infoGuild = true end
    if db.collect == nil then db.collect = false end
    db.scale = db.scale or 1
    db.style = db.style or "frame"

    if not db.defaultOnV2 then
        db.defaultOnV2 = true
        db.enabled = true
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.minimap
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local STYLES = {
    frame = true, classic = true, round = true, pixel = true, neon = true, photo = true, vignette = true,
    thick = true, glass = true, bare = true,
}
local ROUND_MASK = "Textures\\MinimapMask"
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local function MapStyle()
    local db = Settings()
    return db and STYLES[db.style] and db.style or "frame"
end

local function Holder()
    if MinimapSkin.holder then return MinimapSkin.holder end

    local holder = CreateFrame("Frame", "NarciSirus_MinimapHolder", UIParent)
    holder:SetFrameStrata("BACKGROUND")
    holder:SetSize(140, 140)
    holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -17, -22)
    MinimapSkin.holder = holder

    if NS.Movers then
        NS.Movers:Register(holder, L["Миникарта"], function(point, relativePoint, x, y)
            local db = Settings()
            if not db then return end
            db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y
        end, "minimap")
    end

    return holder
end

function MinimapSkin:Place()
    local db = Settings()
    if not db or not _G.Minimap then return end

    local holder = Holder()
    local ratio = Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale()
    holder:SetSize(Minimap:GetWidth() * ratio, Minimap:GetHeight() * ratio)

    holder:ClearAllPoints()
    if db.point then
        holder:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -17, -22)
    end

    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", holder, "CENTER", 0, 0)

    if _G.MinimapCluster then MinimapCluster:EnableMouse(false) end
end

local BLIZZARD_BUTTONS = {
    "^MiniMap", "^Minimap", "^GameTimeFrame", "^TimeManager", "^QueueStatus",
    "^NarciSirus_", "^MBB_", "^ElvConfigToggle", "MiniPanel$", "^MMHolder",
}

local NOT_BUTTONS = {
    "Note", "Pin", "Node", "GatherNote", "GatherMiniNote", "GatherMate", "POI", "Arrow", "Blip", "Ping",
    "TrackMenu", "TrackingIcon", "TrackButton", "DA_Minimap", "QuestieFrame",
}

local EXTRA_BUTTONS = { "WIM_IconFrame", "WIM3MinimapButton", "CTMod2_MinimapButton", "PoisonerMinimapButton" }

local RING_TEXTURES = { "TrackingBorder", "UI%-Minimap%-Background", "MinimapButton%-Border", "MiniMap%-TrackingBorder" }

local DIRECTIONS = {
    left = { "TOPRIGHT", "TOPLEFT", -4, 0 },
    right = { "TOPLEFT", "TOPRIGHT", 4, 0 },
    up = { "BOTTOMRIGHT", "TOPRIGHT", 0, 4 },
    down = { "TOPRIGHT", "BOTTOMRIGHT", 0, -4 },
}

local SCAN_INTERVAL = 3

local function BagSettings()
    local db = Settings()
    if not db then return end
    db.bagExclude = db.bagExclude or {}
    db.bagPerRow = db.bagPerRow or 5
    db.bagSize = db.bagSize or 28
    db.bagSpacing = db.bagSpacing or 4
    db.bagDirection = DIRECTIONS[db.bagDirection] and db.bagDirection or "left"
    db.bagOpen = (db.bagOpen == "hover" or db.bagOpen == "always") and db.bagOpen or "click"
    db.bagCollapse = db.bagCollapse or 2
    if db.bagSquare == nil then db.bagSquare = true end
    return db
end

local function HasClick(frame)
    if not frame or not frame.HasScript then return false end
    if frame:IsObjectType("Button") then return true end
    for _, script in ipairs({ "OnClick", "OnMouseUp", "OnMouseDown" }) do
        if frame:HasScript(script) and frame:GetScript(script) then return true end
    end
    return false
end

local function Clickable(frame)
    if HasClick(frame) then return true end
    if not frame or not frame.GetChildren then return false end

    for _, child in ipairs({ frame:GetChildren() }) do
        local width, height = child:GetWidth() or 0, child:GetHeight() or 0
        if HasClick(child) and width >= 14 and width <= 48 and height >= 14 and height <= 48 then
            frame.narciInnerButton = child
            return true
        end
    end
    return false
end

local function IsAddonButton(frame)
    if not frame or not frame.GetName or not frame.IsObjectType then return false end
    if frame.narciBagged then return true end

    local name = frame:GetName()
    if not name then return false end

    for _, pattern in ipairs(BLIZZARD_BUTTONS) do
        if name:find(pattern) then return false end
    end

    if name:find("^LibDBIcon") then return true end

    for _, word in ipairs(NOT_BUTTONS) do
        if name:find(word) then return false end
    end

    if not Clickable(frame) then return false end

    local width, height = frame:GetWidth() or 0, frame:GetHeight() or 0
    return width >= 14 and width <= 48 and height >= 14 and height <= 48
end

function MinimapSkin:KnownButtons()
    self.known = self.known or {}
    return self.known
end

function MinimapSkin:Candidates()
    local list = {}
    local seen = {}

    local function Add(frame)
        if frame and not seen[frame] and IsAddonButton(frame) then
            seen[frame] = true
            list[#list + 1] = frame
        end
    end

    for _, child in ipairs({ Minimap:GetChildren() }) do Add(child) end
    if _G.MinimapBackdrop then
        for _, child in ipairs({ MinimapBackdrop:GetChildren() }) do Add(child) end
    end
    if _G.MinimapCluster then
        for _, child in ipairs({ MinimapCluster:GetChildren() }) do Add(child) end
    end
    for _, name in ipairs(EXTRA_BUTTONS) do Add(_G[name]) end

    if self.bag then
        for _, button in ipairs(self.bag.buttons) do Add(button) end
    end

    local known = self:KnownButtons()
    for _, frame in ipairs(list) do known[frame:GetName()] = true end

    return list
end

function MinimapSkin:BuildBag()
    if self.bag then return self.bag end

    local S = NS.Styling

    local toggle = CreateFrame("Button", "NarciSirus_MinimapBagButton", UIParent)
    toggle:SetSize(20, 20)
    toggle:SetFrameStrata("MEDIUM")
    toggle:SetFrameLevel(20)
    toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local ground = toggle:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(toggle)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL",
        S.ACCENT[1] * 0.6, S.ACCENT[2] * 0.6, S.ACCENT[3] * 0.6, 0.95,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)

    S.CreateEdges(toggle, "BORDER", S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    if S.CreateSoftShadow then S.CreateSoftShadow(toggle, 5, 0.5) end

    local glow = toggle:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints(toggle)
    glow:SetTexture(WHITE)
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 1, 1, 0.18)

    local mark = toggle:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(mark, "minimap", NS.FS(16), "OUTLINE")
    mark:SetPoint("CENTER", toggle, "CENTER", 1, 0)
    mark:SetText("+")
    mark:SetTextColor(1, 1, 1)
    NS.Styling.GlyphIcon(mark)
    toggle.mark = mark

    local bag = CreateFrame("Frame", "NarciSirus_MinimapBag", UIParent)
    bag:SetFrameStrata("DIALOG")
    bag:SetSize(40, 40)
    bag:EnableMouse(true)
    bag:SetClampedToScreen(true)
    bag:Hide()

    local back = bag:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints(bag)
    back:SetTexture(WHITE)
    back:SetVertexColor(0.02, 0.022, 0.032, 0.95)
    S.CreateEdges(bag, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
    if S.CreateSoftShadow then S.CreateSoftShadow(bag, 6, 0.5) end

    local top = bag:CreateTexture(nil, "ARTWORK")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", bag, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", bag, "TOPRIGHT", 0, 0)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)

    local empty = bag:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(empty, "minimap", NS.FS(10), "")
    empty:SetPoint("CENTER", bag, "CENTER", 0, 0)
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetText(L["Нет кнопок"])
    bag.empty = empty

    local function Open(show)
        if show then
            MinimapSkin:Collect()
            bag.idle = 0
        end
        bag:SetShown(show)
        mark:SetText(show and "-" or "+")
    end
    bag.Open = Open

    toggle:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            if NS.Settings then
                NS.Settings:Create()
                if NS.settingsFrame then NS.settingsFrame:Show() end
                NS.Settings:Select("minibag")
            end
            return
        end
        Open(not bag:IsShown())
    end)

    bag:SetScript("OnHide", function() mark:SetText("+") end)

    toggle:SetScript("OnEnter", function(self)
        local store = BagSettings()
        if store and store.bagOpen == "hover" and not bag:IsShown() then Open(true) end
        bag.idle = 0

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Кнопки аддонов"])
        GameTooltip:AddLine(string.format(L["Собрано: %d"], #bag.buttons), 0.8, 0.82, 0.86)
        GameTooltip:AddLine(L["Левый клик - открыть, правый - настройки"], 0.6, 0.62, 0.66)
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    bag:SetScript("OnUpdate", function(self, elapsed)
        self.tick = (self.tick or 0) + elapsed
        if self.tick < 0.1 then return end
        elapsed, self.tick = self.tick, 0
        local store = BagSettings()
        if store and store.bagOpen == "always" then return end
        local timeout = store and store.bagCollapse or 0
        if timeout <= 0 then return end

        if self:IsMouseOver() or toggle:IsMouseOver() then
            self.idle = 0
            return
        end

        self.idle = (self.idle or 0) + elapsed
        if self.idle >= timeout then Open(false) end
    end)

    bag.toggle = toggle
    bag.buttons = {}
    bag.slots = {}
    self.bag = bag

    if NS.Movers then
        NS.Movers:Register(toggle, L["Кнопка аддонов"], function(point, relativePoint, x, y)
            local store = Settings()
            if not store then return end
            store.bagPoint, store.bagRelativePoint, store.bagX, store.bagY = point, relativePoint, x, y
        end, "minimap")
    end

    local scanner = CreateFrame("Frame")
    local waited = 0
    scanner:SetScript("OnUpdate", function(_, elapsed)
        waited = waited + elapsed
        if waited < SCAN_INTERVAL then return end
        waited = 0
        local store = Settings()
        if store and store.collect then MinimapSkin:Collect() end
    end)
    self.scanner = scanner

    self:PlaceToggle()

    return bag
end

function MinimapSkin:PlaceToggle()
    local bag = self.bag
    if not bag then return end

    local db = BagSettings()
    local toggle = bag.toggle
    toggle:ClearAllPoints()

    if db and db.bagOpen == "always" then
        toggle:Hide()
        bag:ClearAllPoints()
        if db.bagPoint then
            bag:SetPoint(db.bagPoint, UIParent, db.bagRelativePoint or db.bagPoint, db.bagX or 0, db.bagY or 0)
        else
            bag:SetPoint("TOPRIGHT", self.frame or Minimap, "BOTTOMRIGHT", 0, -3)
        end
        bag:SetFrameStrata("MEDIUM")
        bag:SetShown(#bag.buttons > 0)
        return
    end
    bag:SetFrameStrata("DIALOG")

    if db and db.bagPoint then
        toggle:SetParent(UIParent)
        toggle:SetPoint(db.bagPoint, UIParent, db.bagRelativePoint or db.bagPoint, db.bagX or 0, db.bagY or 0)
    elseif self.info and self.info:IsShown() then
        toggle:SetParent(self.info)
        toggle:SetPoint("RIGHT", self.info, "LEFT", -3, 0)
    else
        toggle:SetParent(self.frame or UIParent)
        toggle:SetPoint("TOPLEFT", self.frame or Minimap, "BOTTOMLEFT", 0, -3)
    end

    toggle:SetFrameStrata("MEDIUM")
    toggle:SetFrameLevel(20)

    local direction = DIRECTIONS[db and db.bagDirection or "left"]
    bag:ClearAllPoints()
    bag:SetPoint(direction[1], toggle, direction[2], direction[3], direction[4])
end

local function Squarify(button, on)
    if on then
        if button.narciSquare or button.narciNoSquare then return end
        button.narciSquare = { hidden = {} }

        local icon, best = nil, 0
        for _, region in ipairs({ button:GetRegions() }) do
            if region:GetObjectType() == "Texture" then
                local path = region:GetTexture()
                local ring = false
                if type(path) == "string" then
                    for _, pattern in ipairs(RING_TEXTURES) do
                        if path:find(pattern) then ring = true end
                    end
                end

                if ring then
                    button.narciSquare.hidden[#button.narciSquare.hidden + 1] = { region, region:GetAlpha() }
                    region:SetAlpha(0)
                elseif region ~= (button.GetHighlightTexture and button:GetHighlightTexture())
                    and region:GetDrawLayer() ~= "HIGHLIGHT" and region:IsShown() then
                    local area = (region:GetWidth() or 0) * (region:GetHeight() or 0)
                    if area > best then icon, best = region, area end
                end
            end
        end

        if icon then
            local saved = { region = icon, points = {}, coords = { icon:GetTexCoord() } }
            for index = 1, icon:GetNumPoints() do saved.points[index] = { icon:GetPoint(index) } end
            button.narciSquare.icon = saved
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        return
    end

    local state = button.narciSquare
    if not state then return end
    button.narciSquare = nil

    for _, entry in ipairs(state.hidden) do entry[1]:SetAlpha(entry[2] or 1) end

    local saved = state.icon
    if saved then
        saved.region:ClearAllPoints()
        for _, point in ipairs(saved.points) do pcall(saved.region.SetPoint, saved.region, unpack(point)) end
        pcall(saved.region.SetTexCoord, saved.region, unpack(saved.coords))
    end
end

function MinimapSkin:Take(button)
    local bag = self.bag

    local inner = button.narciInnerButton
    if inner then
        inner.narciHome = { points = {}, width = inner:GetWidth(), height = inner:GetHeight() }
        for index = 1, inner:GetNumPoints() do inner.narciHome.points[index] = { inner:GetPoint(index) } end
        if inner.RegisterForDrag then inner:RegisterForDrag() end
        if not inner.narciBagHooked then
            inner.narciBagHooked = true
            inner:HookScript("OnEnter", function()
                if MinimapSkin.bag then MinimapSkin.bag.idle = 0 end
            end)
        end
    end

    button.narciBagged = true
    button.narciHome = {
        parent = button:GetParent(),
        points = {},
        width = button:GetWidth(),
        height = button:GetHeight(),
        strata = button:GetFrameStrata(),
    }

    for index = 1, button:GetNumPoints() do
        button.narciHome.points[index] = { button:GetPoint(index) }
    end

    self.placing = true
    button:SetParent(bag)
    self.placing = nil
    if button.RegisterForDrag then button:RegisterForDrag() end
    bag.buttons[#bag.buttons + 1] = button

    if not button.narciBagHooked then
        button.narciBagHooked = true
        hooksecurefunc(button, "SetPoint", function(self)
            if self.narciBagged and not MinimapSkin.placing then MinimapSkin:LayoutBag() end
        end)
        hooksecurefunc(button, "SetParent", function(self, parent)
            if self.narciBagged and parent ~= MinimapSkin.bag and not MinimapSkin.placing then
                MinimapSkin.placing = true
                self:SetParent(MinimapSkin.bag)
                MinimapSkin.placing = nil
                MinimapSkin:LayoutBag()
            end
        end)
        hooksecurefunc(button, "Show", function(self)
            if self.narciBagged then MinimapSkin:LayoutBag() end
        end)
        hooksecurefunc(button, "Hide", function(self)
            if self.narciBagged then MinimapSkin:LayoutBag() end
        end)
        button:HookScript("OnEnter", function(self)
            if self.narciBagged and MinimapSkin.bag then MinimapSkin.bag.idle = 0 end
        end)
    end
end

function MinimapSkin:Give(button)
    local home = button.narciHome
    button.narciBagged = nil
    Squarify(button.narciInnerButton or button, false)

    local inner = button.narciInnerButton
    if inner and inner.narciHome then
        inner:ClearAllPoints()
        for _, point in ipairs(inner.narciHome.points) do pcall(inner.SetPoint, inner, unpack(point)) end
        if inner.narciHome.width then inner:SetSize(inner.narciHome.width, inner.narciHome.height) end
        if inner.RegisterForDrag then inner:RegisterForDrag("LeftButton") end
    end

    self.placing = true
    if home then
        button:SetParent(home.parent or Minimap)
        button:ClearAllPoints()
        for _, point in ipairs(home.points) do pcall(button.SetPoint, button, unpack(point)) end
        if home.width and home.height then button:SetSize(home.width, home.height) end
        if home.strata then button:SetFrameStrata(home.strata) end
    end
    self.placing = nil

    if button.RegisterForDrag then button:RegisterForDrag("LeftButton") end
end

function MinimapSkin:BagBlocked()
    return IsAddOnLoaded and IsAddOnLoaded("MBB")
end

function MinimapSkin:Collect()
    local db = BagSettings()
    if not db or not db.collect or not _G.Minimap then return end
    if self:BagBlocked() then
        if not self.warnedMBB then
            self.warnedMBB = true
            NS.Print(L["Включён аддон MBB, кнопки аддонов собирает он. Отключить его можно в настройках, страница Кнопки аддонов."])
        end
        return
    end

    local bag = self:BuildBag()
    if db.bagOpen == "always" then
        if not bag.alwaysPlaced then
            bag.alwaysPlaced = true
            self:PlaceToggle()
        end
    elseif not bag.toggle:IsShown() then
        bag.alwaysPlaced = nil
        bag.toggle:Show()
        self:PlaceToggle()
    end

    if not db.bagImported and type(_G.MBB_Exclude) == "table" then
        db.bagImported = true
        for _, name in ipairs(_G.MBB_Exclude) do db.bagExclude[name] = true end
    end

    local changed = false

    for _, button in ipairs(self:Candidates()) do
        local name = button:GetName()
        local excluded = db.bagExclude[name]

        if not button.narciBagged and not excluded then
            self:Take(button)
            changed = true
        elseif button.narciBagged and excluded then
            for index, entry in ipairs(bag.buttons) do
                if entry == button then table.remove(bag.buttons, index) break end
            end
            self:Give(button)
            changed = true
        end
    end

    if changed or self.bagDirty then
        self.bagDirty = nil
        self:LayoutBag()
    end
end

function MinimapSkin:LayoutBag()
    local bag = self.bag
    if not bag or self.placing then return end
    self.placing = true

    local db = BagSettings()
    local perRow = math.max(1, db.bagPerRow)
    local size = db.bagSize
    local gap = db.bagSpacing
    local step = size + gap
    local pad = 6

    local shown = {}
    for _, button in ipairs(bag.buttons) do
        if button:IsShown() then shown[#shown + 1] = button end
    end

    table.sort(shown, function(a, b) return (a:GetName() or "") < (b:GetName() or "") end)

    for index, button in ipairs(shown) do
        local column = (index - 1) % perRow
        local row = math.floor((index - 1) / perRow)
        local x, y = pad + column * step, -pad - row * step

        local slot = bag.slots[index]
        if not slot then
            slot = bag:CreateTexture(nil, "BORDER")
            slot:SetTexture(WHITE)
            slot:SetVertexColor(0.06, 0.065, 0.085, 0.9)
            bag.slots[index] = slot
        end
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", bag, "TOPLEFT", x, y)
        slot:SetSize(size, size)
        slot:Show()

        local inner = button.narciInnerButton
        Squarify(inner or button, db.bagSquare)
        button:SetSize(size, size)
        if inner then
            inner:ClearAllPoints()
            inner:SetAllPoints(button)
            inner:SetFrameLevel(bag:GetFrameLevel() + 3)
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", bag, "TOPLEFT", x, y)
        button:SetFrameStrata(bag:GetFrameStrata())
        button:SetFrameLevel(bag:GetFrameLevel() + 2)
    end

    for index = #shown + 1, #bag.slots do bag.slots[index]:Hide() end

    local count = math.max(1, #shown)
    local columns = math.min(perRow, count)
    local rows = math.ceil(count / perRow)
    bag:SetSize(pad * 2 + columns * step - gap, pad * 2 + rows * step - gap)
    bag.empty:SetShown(#shown == 0)
    if db.bagOpen == "always" then bag:SetShown(#shown > 0) end

    self.placing = nil
end

function MinimapSkin:ApplyBag()
    if not self.bag then return end
    for _, button in ipairs(self.bag.buttons) do
        local target = button.narciInnerButton or button
        if target.narciSquare and not BagSettings().bagSquare then Squarify(target, false) end
    end
    self:PlaceToggle()
    self:LayoutBag()
end

function MinimapSkin:Release()
    local bag = self.bag
    if not bag then return end

    for _, button in ipairs(bag.buttons) do self:Give(button) end

    bag.buttons = {}
    bag:Hide()
    bag.toggle:Hide()
    self:PlaceToggle()
end

local function Memory(kb)
    if kb >= 1024 then return string.format("%.2f MB", kb / 1024) end
    return string.format("%.0f KB", kb)
end

local function MemoryColor(kb)
    if kb >= 10240 then return 0.95, 0.35, 0.30 end
    if kb >= 3072 then return 0.95, 0.80, 0.30 end
    return 0.55, 0.85, 0.55
end

local function InfoText(parent, point)
    local text = parent:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(text, "minimap", NS.FS(10), "")
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetPoint(point, parent, point, point == "LEFT" and 6 or (point == "RIGHT" and -6 or 0), 0)
    text:SetTextColor(0.90, 0.91, 0.94)
    return text
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

function MinimapSkin:BuildInfo()
    if self.info or not self.frame then return self.info end

    local S = NS.Styling

    local info = CreateFrame("Frame", "NarciSirus_MinimapInfo", self.frame)
    info:SetHeight(20)
    info:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, -3)
    info:SetPoint("TOPRIGHT", self.frame, "BOTTOMRIGHT", 0, -3)

    local ground = info:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(info)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.95)

    S.CreateEdges(info, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
    if S.CreateSoftShadow then S.CreateSoftShadow(info, 6, 0.45) end

    info:EnableMouse(true)
    info:SetScript("OnEnter", function(self)
        self.hovered = true
        MinimapSkin:ShowUsage(self)
    end)
    info:SetScript("OnLeave", function(self)
        self.hovered = nil
        GameTooltip:Hide()
    end)
    info:SetScript("OnMouseUp", function(self)
        local before = collectgarbage("count")
        collectgarbage("collect")
        local freed = before - collectgarbage("count")
        NS.Print(L["Освобождено памяти"] .. ": " .. Memory(math.max(0, freed)))
        if self.hovered then MinimapSkin:ShowUsage(self) end
    end)

    info.ping = InfoText(info, "RIGHT")
    info.fps = InfoText(info, "RIGHT")
    info.friends = InfoText(info, "RIGHT")
    info.guild = InfoText(info, "RIGHT")
    for _, key in ipairs({ "friends", "guild" }) do
        local icon = info:CreateTexture(nil, "OVERLAY")
        icon:SetSize(12, 12)
        icon:SetTexture(S.Media(key == "friends" and "MicroSocial" or "MicroGuild"))
        icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        icon:SetPoint("RIGHT", info[key], "LEFT", -2, 0)
        info[key].icon = icon
        local hit = CreateFrame("Button", nil, info)
        hit:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 4)
        hit:SetPoint("BOTTOMRIGHT", info[key], "BOTTOMRIGHT", 3, -4)
        hit:SetFrameLevel(info:GetFrameLevel() + 2)
        hit:RegisterForClicks("LeftButtonUp")
        hit:SetScript("OnClick", function()
            if key == "friends" then NS.OpenFriendsList() else NS.OpenGuildList() end
        end)
        hit:SetScript("OnEnter", function(self)
            info[key]:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            local counts = NS.SocialCounts and NS.SocialCounts()
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            if key == "friends" then
                GameTooltip:AddLine(L["Друзья в сети"], 1, 1, 1)
                if counts then GameTooltip:AddLine(counts.friends .. " / " .. counts.friendsTotal, 0.8, 0.8, 0.85) end
                GameTooltip:AddLine(L["Клик - список друзей"], 0.6, 0.6, 0.65)
            else
                GameTooltip:AddLine(L["Гильдия в сети"], 1, 1, 1)
                if counts then GameTooltip:AddLine(counts.guild .. " / " .. counts.guildTotal, 0.8, 0.8, 0.85) end
                GameTooltip:AddLine(L["Клик - список гильдии"], 0.6, 0.6, 0.65)
            end
            GameTooltip:Show()
        end)
        hit:SetScript("OnLeave", function()
            info[key]:SetTextColor(0.90, 0.91, 0.94)
            GameTooltip:Hide()
        end)
        info[key].hit = hit
    end

    info:SetScript("OnUpdate", function(frame, elapsed)
        frame.fast = (frame.fast or 0) + elapsed
        frame.slow = (frame.slow or 1) + elapsed

        if frame.slow >= 1 then
            frame.slow = 0
            frame.usage = (frame.usage or 0) + 1
            if frame.hovered and frame.usage >= 3 then
                frame.usage = 0
                MinimapSkin:ShowUsage(frame)
            end
            local accent = Hex(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            frame.fps:SetText(math.floor(GetFramerate() + 0.5) .. accent .. " fps|r")
            local _, _, latency = GetNetStats()
            frame.ping:SetText((latency or 0) .. accent .. " ms|r")
            local counts = NS.SocialCounts and NS.SocialCounts()
            if counts then
                frame.friends:SetText(counts.friends)
                frame.guild:SetText((IsInGuild and IsInGuild()) and counts.guild or "-")
            end
            MinimapSkin:LayoutInfo()
        end
    end)

    self.info = info
    return info
end

function MinimapSkin:LayoutInfo()
    local info = self.info
    local db = Settings()
    if not info or not db then return end
    local guildShown = db.infoGuild and IsInGuild and IsInGuild() and true or false
    if info.guild:IsShown() ~= guildShown then
        info.guild:SetShown(guildShown)
        info.guild.icon:SetShown(guildShown)
        info.guild.hit:SetShown(guildShown)
    end
    local items, total = {}, 0
    for _, key in ipairs({ "fps", "ping", "friends", "guild" }) do
        local text = info[key]
        if text:IsShown() then
            local width = text:GetStringWidth() + (text.icon and 14 or 0)
            items[#items + 1] = { text = text, width = width }
            total = total + width
        end
    end
    if #items == 0 then return end
    local gap = math.max(4, ((info:GetWidth() or 140) - total) / (#items + 1))
    local x = gap
    for _, item in ipairs(items) do
        item.text:ClearAllPoints()
        item.text:SetPoint("RIGHT", info, "LEFT", x + item.width, 0)
        x = x + item.width + gap
    end
end

function MinimapSkin:ShowUsage(owner)
    if not UpdateAddOnMemoryUsage or not GetAddOnMemoryUsage then return end

    local S = NS.Styling
    UpdateAddOnMemoryUsage()

    local cpu = GetCVar("scriptProfile") == "1" and UpdateAddOnCPUUsage and GetAddOnCPUUsage
    if cpu then UpdateAddOnCPUUsage() end

    local list, total = {}, 0

    for index = 1, GetNumAddOns() do
        if IsAddOnLoaded(index) then
            local kb = GetAddOnMemoryUsage(index) or 0
            total = total + kb
            list[#list + 1] = {
                name = (select(2, GetAddOnInfo(index))) or GetAddOnInfo(index),
                kb = kb,
                cpu = cpu and GetAddOnCPUUsage(index) or nil,
            }
        end
    end

    table.sort(list, function(a, b) return a.kb > b.kb end)

    GameTooltip:SetOwner(owner, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)
    GameTooltip:AddLine(L["Нагрузка аддонов"], S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    local _, _, latency = GetNetStats()
    GameTooltip:AddDoubleLine(L["Кадры в секунду"], tostring(math.floor(GetFramerate() + 0.5)), 0.75, 0.77, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Пинг"], (latency or 0) .. " ms", 0.75, 0.77, 0.8, 1, 1, 1)
    GameTooltip:AddLine(" ")

    for index = 1, math.min(#list, 30) do
        local entry = list[index]
        local r, g, b = MemoryColor(entry.kb)
        local value = Memory(entry.kb)
        if entry.cpu then value = value .. string.format("  |cff9a9ca3%.0f ms|r", entry.cpu) end
        GameTooltip:AddDoubleLine(entry.name, value, 0.9, 0.91, 0.94, r, g, b)
    end

    if #list > 30 then
        GameTooltip:AddLine(string.format(L["и ещё %d"], #list - 30), 0.6, 0.62, 0.66)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["Всего"], Memory(total), 1, 1, 1, 1, 0.82, 0.2)
    GameTooltip:AddLine(L["Клик - очистить память"], 0.6, 0.62, 0.66)
    GameTooltip:Show()
end

function MinimapSkin:UpdateInfo()
    local db = Settings()
    if not db then return end

    if not db.infoPanel then
        if self.info then self.info:Hide() end
        return
    end

    local info = self:BuildInfo()
    if not info then return end

    info.fps:SetShown(db.infoFps)
    info.ping:SetShown(db.infoPing)
    info.friends:SetShown(db.infoFriends)
    info.friends.icon:SetShown(db.infoFriends)
    info.friends.hit:SetShown(db.infoFriends)
    info.guild:SetShown(db.infoGuild and IsInGuild and IsInGuild() and true or false)
    info.guild.icon:SetShown(info.guild:IsShown())
    info.guild.hit:SetShown(info.guild:IsShown())
    self:LayoutInfo()

    info:Show()
    self:PlaceToggle()
end

MinimapSkin.COORD_STYLES = { "plate", "clean", "accent", "flat", "pixel", "glass", "neon", "gold", "classic" }
MinimapSkin.COORD_STYLE_LABELS = {
    plate = "плашка", clean = "только текст", accent = "цвет темы", flat = "рамка", pixel = "пиксель",
    glass = "стекло", neon = "неон", gold = "золото", classic = "клиент",
}
local COORD_BOX = { flat = "flat", pixel = "pixel", glass = "glass", neon = "neon", gold = "gold", classic = "classic" }
MinimapSkin.COORD_EXTRA = {}

function MinimapSkin:AddCoordStyle(key, label, row)
    if type(key) ~= "string" or key == "" or self.COORD_STYLE_LABELS[key] or type(row) ~= "table" then return false end
    self.COORD_EXTRA[key] = row
    COORD_BOX[key] = row.box
    self.COORD_STYLE_LABELS[key] = label or key
    table.insert(self.COORD_STYLES, key)
    return true
end

local function BuildCoordPill(parent, name)
    local S = NS.Styling
    local pill = CreateFrame("Frame", name, parent)
    pill:SetHeight(18)

    local ground = pill:CreateTexture(nil, "BACKGROUND")
    ground:SetPoint("TOPLEFT", pill, "TOPLEFT", -10, 4)
    ground:SetPoint("BOTTOMRIGHT", pill, "BOTTOMRIGHT", 10, -4)
    ground:SetTexture(S.Media("Pill"))
    pill.ground = ground

    local left = pill:CreateTexture(nil, "BORDER")
    left:SetHeight(1)
    left:SetPoint("BOTTOMLEFT", pill, "BOTTOMLEFT", 6, 1)
    left:SetPoint("BOTTOMRIGHT", pill, "BOTTOM", 0, 1)
    left:SetTexture(WHITE)
    local right = pill:CreateTexture(nil, "BORDER")
    right:SetHeight(1)
    right:SetPoint("BOTTOMLEFT", pill, "BOTTOM", 0, 1)
    right:SetPoint("BOTTOMRIGHT", pill, "BOTTOMRIGHT", -6, 1)
    right:SetTexture(WHITE)
    pill.lines = { left, right }

    local text = pill:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(text, "minimap", NS.FS(11), "")
    text:SetPoint("CENTER", pill, "CENTER", 0, 0)
    pill.text = text
    return pill
end

local function PaintCoordPill(pill, style)
    local S = NS.Styling
    local A, G = S.ACCENT, S.ACCENT_GLOW
    pill.style = style
    local extra = MinimapSkin.COORD_EXTRA[style]
    pill.ground:SetShown(style == "plate" or style == "accent" or (extra ~= nil and extra.plate == true))
    if style == "accent" then
        pill.ground:SetVertexColor(A[1] * 0.55, A[2] * 0.55, A[3] * 0.55, 0.9)
    else
        pill.ground:SetVertexColor(0, 0, 0, 0.85)
    end
    pill.lines[1]:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0, A[1], A[2], A[3], 0.9)
    pill.lines[2]:SetGradientAlpha("HORIZONTAL", A[1], A[2], A[3], 0.9, A[1], A[2], A[3], 0)
    for _, line in ipairs(pill.lines) do line:SetShown(style == "plate") end
    S.SkinBox(pill, COORD_BOX[style] or "none", { alpha = 0.85, glowSize = 5, shadowSize = 6, edgeSize = 10, borderLevel = 2 })
    NS.LSetFont(pill.text, "minimap", NS.FS(11), (style == "clean" or (extra and extra.outline)) and "OUTLINE" or "")
    pill.text:SetShadowOffset(1, -1)
    pill.text:SetShadowColor(0, 0, 0, 1)
    if style == "neon" then
        pill.text:SetTextColor(G[1], G[2], G[3])
    elseif style == "gold" or style == "classic" then
        pill.text:SetTextColor(1, 0.86, 0.45)
    elseif extra and extra.text then
        pill.text:SetTextColor(extra.text[1], extra.text[2], extra.text[3])
    else
        pill.text:SetTextColor(0.95, 0.96, 0.98)
    end
    pill.pad = COORD_BOX[style] and 12 or 16
    pill:SetHeight(COORD_BOX[style] and 16 or 18)
    if extra and type(extra.paint) == "function" then pcall(extra.paint, pill) end
end

local function CoordText(pill, x, y)
    local db = Settings()
    local r, g, b
    if pill.style == "accent" then r, g, b = 1, 1, 1 end
    if pill.style == "gold" or pill.style == "classic" then r, g, b = 1, 0.95, 0.8 end
    pill.text:SetText(NS.FormatCoords(x, y, 1, db.coordFormat or "xy", r, g, b))
    pill:SetWidth(math.max(40, pill.text:GetStringWidth() + (pill.pad or 14)))
end

local function PlaceCoordPill(pill, map, zone, clock, live)
    local db = Settings()
    pill:ClearAllPoints()
    local free = db.coordFree
    if live and db.coordPos == "free" and free and free.point then
        pill:SetPoint(free.point, UIParent, free.relativePoint or free.point, free.x or 0, free.y or 0)
    elseif db.coordPos == "top" then
        pill:SetPoint("TOP", map, "TOP", 0, (zone and zone:IsShown()) and -20 or -5)
    elseif db.coordPos == "edge" then
        pill:SetPoint("CENTER", map, "BOTTOM", 0, 2)
    elseif clock and clock:IsShown() and clock:GetTop() and map:GetBottom() and clock:GetTop() > map:GetBottom() then
        pill:SetPoint("BOTTOM", clock, "TOP", 0, 2)
    else
        pill:SetPoint("BOTTOM", map, "BOTTOM", 0, 6)
    end
end

function MinimapSkin:UpdateCoords()
    local db = Settings()
    if not db or not _G.Minimap then return end

    if not db.infoCoords then
        if self.coordPill then self.coordPill:Hide() end
        return
    end

    local pill = self.coordPill

    if not pill then
        pill = BuildCoordPill(UIParent, "NarciSirus_MinimapCoords")
        pill:SetFrameStrata("LOW")
        pill:SetFrameLevel(10)
        pill:SetScript("OnUpdate", function(frame, elapsed)
            frame.elapsed = (frame.elapsed or 1) + elapsed
            if frame.elapsed < 0.2 then return end
            frame.elapsed = 0

            local x, y = GetPlayerMapPosition("player")
            if x and x == frame.lastX and y == frame.lastY and not frame.dirty then return end
            frame.lastX, frame.lastY, frame.dirty = x, y, nil

            if x and y and (x > 0 or y > 0) then
                CoordText(frame, x, y)
            else
                frame.text:SetText("-")
                frame:SetWidth(40)
            end
        end)
        self.coordPill = pill
    end

    PaintCoordPill(pill, db.coordStyle or "plate")
    pill.dirty = true
    pill:SetScale((db.coordScale or 100) / 100)
    local zone = _G.MinimapZoneText
    local clock = _G.TimeManagerClockButton
    PlaceCoordPill(pill, Minimap, zone, not db.hideClock and clock or nil, true)
    if not pill.narciMoverOverlay and NS.Movers then
        NS.Movers:Register(pill, L["Координаты"], function(point, relativePoint, x, y)
            local store = Settings()
            store.coordPos = "free"
            store.coordFree = { point = point, relativePoint = relativePoint, x = x, y = y }
        end)
    end
    pill:Show()
end

function MinimapSkin:UpdateExtras()
    local db = Settings()
    if not db or not _G.Minimap then return end

    local clock = _G.TimeManagerClockButton
    if clock then
        if db.hideClock then clock:Hide() else clock:Show() end
    end

    self:UpdateInfo()
    self:UpdateCoords()

    if db.collect then
        self:Collect()
    else
        self:Release()
    end
end

function MinimapSkin:ResetPosition()
    local db = Settings()
    if not db then return end

    db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil
    if Enabled() then self:Place() end
end

function MinimapSkin:Move()
    if not Enabled() then
        NS.Print(L["Сначала включите миникарту в стиле аддона"])
        return
    end

    if NS.Movers then NS.Movers:Toggle() end
end

function MinimapSkin:PrepareMove()
    if Enabled() then self:Place() end
end

local function BuildMapFrame(f)
    local S = NS.Styling
    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.95)

    if S.CreateSoftShadow then f.softShadow = S.CreateSoftShadow(f, 8, 0.5) end

    f.ground = ground

    local glow = f:CreateTexture(nil, "ARTWORK")
    glow:SetHeight(1)
    glow:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)

    f.glowLine = glow
    f.lines = {}

    for index = 1, 4 do
        local line = f:CreateTexture(nil, "BORDER")
        f.lines[index] = line
        line:SetTexture(WHITE)
        line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)

        if index == 1 then
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            line:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        elseif index == 2 then
            line:SetHeight(1)
            line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
            line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        elseif index == 3 then
            line:SetWidth(1)
            line:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        else
            line:SetWidth(1)
            line:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
            line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        end
    end

end

function MinimapSkin:Apply()
    if not Enabled() or not _G.Minimap then return end

    local db = Settings()
    local S = NS.Styling

    local hide = HIDE
    if NS.DFUI then
        hide = {}
        for _, name in ipairs(HIDE) do hide[#hide + 1] = name end
        hide[#hide + 1] = "MinimapCompassTexture"
    end

    for _, name in ipairs(hide) do
        local region = _G[name]
        if region then
            if region.SetAlpha then region:SetAlpha(0) end
            if region.Hide and region.EnableMouse then
                region:EnableMouse(false)
                region:Hide()
            end
        end
    end

    local style = MapStyle()
    local round = style == "classic" or style == "round" or not db.square
    Minimap:SetMaskTexture(round and ROUND_MASK or WHITE)

    if NS.DFUI then Minimap:SetSize(140, 140) end
    Minimap:SetScale(db.scale)
    self:Place()

    if not self.frame then
        local f = CreateFrame("Frame", "NarciSirus_MinimapFrame", UIParent)
        f:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, 3)
        f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3, -3)
        f:SetFrameStrata("BACKGROUND")

        BuildMapFrame(f)
        self.frame = f
    end

    local zone = _G.MinimapZoneTextButton
    local zoneText = _G.MinimapZoneText

    if zone then
        zone:ClearAllPoints()
        zone:SetPoint("TOP", Minimap, "TOP", 0, -4)
        zone:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        zone:SetShown(not db.hideZoneText)
    end

    if zoneText then
        NS.LSetFont(zoneText, "minimap", NS.FS(11), "OUTLINE")
        zoneText:SetTextColor(NS.Look:Text("minimap", S.TEXT_BRIGHT))
    end

    local clock = _G.TimeManagerClockTicker
    if clock then
        NS.LSetFont(clock, "minimap", NS.FS(11), "OUTLINE")
        clock:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end

    local clockButton = _G.TimeManagerClockButton
    if clockButton then
        clockButton:ClearAllPoints()
        clockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -2)
        for _, region in ipairs({ clockButton:GetRegions() }) do
            if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
        end
    end

    self:StyleFrame()
    self:UpdateExtras()

    if not Minimap.narciWheel then
        Minimap.narciWheel = true
        Minimap:EnableMouseWheel(true)
        Minimap:SetScript("OnMouseWheel", function(self, delta)
            if delta > 0 then
                Minimap_ZoomIn()
            else
                Minimap_ZoomOut()
            end
        end)
    end
end

function MinimapSkin:BuildLooks(frame, map)
    local f = frame or self.frame
    map = map or Minimap
    if f.looks then return f.looks end

    local S = NS.Styling
    local looks = {}

    looks.shadow = f:CreateTexture(nil, "BACKGROUND")
    looks.shadow:SetTexture(S.Media("SoftDisc"))
    looks.shadow:SetPoint("TOPLEFT", map, "TOPLEFT", -26, 26)
    looks.shadow:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 26, -26)
    looks.shadow:SetVertexColor(0, 0, 0, 0.7)

    looks.ring = f:CreateTexture(nil, "BORDER")
    looks.ring:SetTexture(DISC)
    looks.ring:SetPoint("TOPLEFT", map, "TOPLEFT", -3, 3)
    looks.ring:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 3, -3)
    looks.ring:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)

    looks.glow = S.GlowPieces(f, 9, "BACKGROUND", "ADD")
    for _, texture in ipairs(looks.glow) do
        texture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)
    end

    local shade = CreateFrame("Frame", nil, map)
    shade:SetAllPoints(map)
    shade:SetFrameLevel(map:GetFrameLevel() + 2)
    shade:EnableMouse(false)
    looks.shade = shade

    local inner = shade:CreateTexture(nil, "OVERLAY")
    inner:SetTexture(S.Media("InnerShade"))
    inner:SetAllPoints(map)
    inner:SetVertexColor(0, 0, 0, 0.8)

    f.looks = looks
    return looks
end

function MinimapSkin:StyleFrame(frame, map)
    local f = frame or self.frame
    local sample = frame ~= nil
    map = map or Minimap
    if not f or not f.lines then return end

    local S = NS.Styling
    local style = MapStyle()
    local looks = self:BuildLooks(f, map)
    local roundLook = style == "classic" or style == "round"

    f:ClearAllPoints()
    if style == "photo" then
        f:SetPoint("TOPLEFT", map, "TOPLEFT", -7, 7)
        f:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 7, -20)
    elseif style == "pixel" then
        f:SetPoint("TOPLEFT", map, "TOPLEFT", -2, 2)
        f:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 2, -2)
    elseif style == "thick" then
        f:SetPoint("TOPLEFT", map, "TOPLEFT", -5, 5)
        f:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 5, -5)
    else
        f:SetPoint("TOPLEFT", map, "TOPLEFT", -3, 3)
        f:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 3, -3)
    end

    f.ground:SetShown(not roundLook and style ~= "vignette" and style ~= "bare")
    if style == "photo" then
        f.ground:SetVertexColor(0.93, 0.91, 0.86, 1)
    elseif style == "pixel" then
        f.ground:SetVertexColor(0.24, 0.24, 0.25, 1)
    elseif style == "glass" then
        f.ground:SetVertexColor(0.05, 0.07, 0.11, 0.55)
    else
        f.ground:SetVertexColor(0.016, 0.018, 0.026, 0.95)
    end

    f.glowLine:SetShown(style == "frame" or style == "glass")

    local lineSize = style == "thick" and 2 or 1
    f.lines[1]:SetHeight(lineSize)
    f.lines[2]:SetHeight(lineSize)
    f.lines[3]:SetWidth(lineSize)
    f.lines[4]:SetWidth(lineSize)

    for _, line in ipairs(f.lines) do
        line:SetShown(style == "frame" or style == "pixel" or style == "neon" or style == "thick" or style == "glass")
        if style == "pixel" then
            line:SetVertexColor(0, 0, 0, 1)
        elseif style == "glass" then
            line:SetVertexColor(S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.95)
        elseif style == "thick" then
            line:SetVertexColor(math.min(1, S.BORDER[1] * 1.6), math.min(1, S.BORDER[2] * 1.6), math.min(1, S.BORDER[3] * 1.6), 1)
        elseif style == "neon" then
            line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        else
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
        end
    end
    local er, eg, eb = NS.Look:Color("minimap", "border")
    if er then
        for _, line in ipairs(f.lines) do line:SetVertexColor(er, eg, eb, 1) end
    end

    for _, texture in ipairs(looks.glow) do texture:SetShown(style == "neon") end
    looks.ring:SetShown(style == "round")
    looks.shadow:SetShown(style == "round")
    looks.shade:SetShown(style == "vignette")
    if f.softShadow then f.softShadow:SetShown(not roundLook and style ~= "vignette" and style ~= "bare") end

    if sample then return end

    local border = _G.MinimapBorder
    local backdrop = _G.MinimapBackdrop
    if border then border:SetAlpha(style == "classic" and 1 or 0) end
    if backdrop and style == "classic" then
        backdrop:ClearAllPoints()
        backdrop:SetPoint("CENTER", map, "CENTER", -9, -24)
        backdrop:Show()
    end

    local clock = _G.TimeManagerClockTicker
    if clock then
        if style == "photo" then
            clock:SetTextColor(0.20, 0.18, 0.16)
        else
            clock:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        end
    end

    local clockButton = _G.TimeManagerClockButton
    if clockButton then
        clockButton:ClearAllPoints()
        if style == "photo" then
            clockButton:SetPoint("TOP", map, "BOTTOM", 0, 1)
        else
            clockButton:SetPoint("BOTTOM", map, "BOTTOM", 0, -2)
        end
    end
end

function MinimapSkin:CreateSample(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(170, 170)
    local map = CreateFrame("Frame", nil, holder)
    map:SetSize(140, 140)
    map:SetPoint("CENTER", holder, "CENTER", 0, 4)
    map:SetFrameLevel(holder:GetFrameLevel() + 3)
    map.image = map:CreateTexture(nil, "ARTWORK")
    map.image:SetAllPoints(map)
    local f = CreateFrame("Frame", nil, holder)
    f:SetFrameLevel(holder:GetFrameLevel() + 1)
    BuildMapFrame(f)
    local zone = map:CreateFontString(nil, "OVERLAY")
    zone:SetPoint("TOP", map, "TOP", 0, -4)
    NS.LSetFont(zone, "minimap", NS.FS(11), "OUTLINE")
    zone:SetText(GetMinimapZoneText and GetMinimapZoneText() or "")
    local clock = map:CreateFontString(nil, "OVERLAY")
    clock:SetPoint("BOTTOM", map, "BOTTOM", 0, 4)
    NS.LSetFont(clock, "minimap", NS.FS(11), "OUTLINE")
    local top = CreateFrame("Frame", nil, holder)
    top:SetAllPoints(holder)
    top:SetFrameLevel(map:GetFrameLevel() + 3)
    local border = top:CreateTexture(nil, "ARTWORK")
    border:SetSize(192, 192)
    border:SetPoint("CENTER", map, "CENTER", -9, -24)
    border:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
    border:SetTexCoord(0.25, 1, 0.125, 0.875)
    holder.map, holder.frame, holder.zone, holder.clock, holder.border = map, f, zone, clock, border
    holder.coords = BuildCoordPill(top)
    return holder
end

function MinimapSkin:PaintSample(holder)
    local db = Settings()
    if not db or not holder then return end
    local S = NS.Styling
    local style = MapStyle()
    local round = style == "classic" or style == "round" or not db.square
    holder.map.image:SetTexture(S.Media(round and "SampleMapRound" or "SampleMap"))
    self:StyleFrame(holder.frame, holder.map)
    holder.border:SetShown(style == "classic")
    NS.LSetFont(holder.zone, "minimap", NS.FS(11), "OUTLINE")
    holder.zone:SetTextColor(NS.Look:Text("minimap", S.TEXT_BRIGHT))
    holder.zone:SetShown(not db.hideZoneText)
    NS.LSetFont(holder.clock, "minimap", NS.FS(11), "OUTLINE")
    holder.clock:SetText(date("%H:%M"))
    if style == "photo" then
        holder.clock:SetTextColor(0.20, 0.18, 0.16)
        holder.clock:ClearAllPoints()
        holder.clock:SetPoint("TOP", holder.map, "BOTTOM", 0, -3)
    else
        holder.clock:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        holder.clock:ClearAllPoints()
        holder.clock:SetPoint("BOTTOM", holder.map, "BOTTOM", 0, 4)
    end
    holder.coords:SetShown(db.infoCoords ~= false)
    PaintCoordPill(holder.coords, db.coordStyle or "plate")
    CoordText(holder.coords, 0.465, 0.351)
    PlaceCoordPill(holder.coords, holder.map, holder.zone, holder.clock)
end

function MinimapSkin:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Apply()
        NS.Print("миникарта в стиле аддона")
    else
        NS.Print("миникарта вернётся к клиентской после /reload")
    end
end

function MinimapSkin:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value

    if field == "infoCoords" or field:sub(1, 5) == "coord" then
        self:UpdateCoords()
        return
    end

    if field == "tracking" then
        self:ApplyTracking()
        return
    end

    if field == "collect" and not Enabled() then
        if value then self:Collect() else self:Release() end
        return
    end

    self:Apply()
end

local function TrackingMode()
    local db = Settings()
    return db and db.tracking or "button"
end

function MinimapSkin:WrapMinimapClick()
    local map = _G.Minimap
    if not map then return end

    local current = map:GetScript("OnMouseUp")
    if self.clickWrapper and current == self.clickWrapper then return end

    local original = current
    self.clickWrapper = function(frame, button, ...)
        if button == "RightButton" and not IsShiftKeyDown() and TrackingMode() ~= "button"
            and _G.MiniMapTrackingDropDown then
            ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, "cursor")
            return
        end

        if original then return original(frame, button, ...) end
    end

    map:SetScript("OnMouseUp", self.clickWrapper)
end

function MinimapSkin:ApplyTracking()
    local mode = TrackingMode()
    local tracking = _G.MiniMapTracking

    if tracking then
        if not tracking.narciHook then
            tracking.narciHook = true
            tracking:HookScript("OnShow", function(self)
                if TrackingMode() == "click" then self:Hide() end
            end)
        end

        if mode == "click" then
            tracking:Hide()
        elseif not tracking:IsShown() and self.trackingHidden then
            tracking:Show()
        end
        self.trackingHidden = mode == "click"
    end

    if mode ~= "button" then
        self:WrapMinimapClick()

        if not self.clickWatch then
            local watch = CreateFrame("Frame")
            local waited = 0
            watch:SetScript("OnUpdate", function(_, elapsed)
                waited = waited + elapsed
                if waited < 2 then return end
                waited = 0
                if TrackingMode() ~= "button" then MinimapSkin:WrapMinimapClick() end
            end)
            self.clickWatch = watch
        end
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function()
    if not NS.After then return end

    NS.After(2, function() MinimapSkin:ApplyTracking() end)
    NS.After(6, function() MinimapSkin:UpdateCoords() end)

    if not Enabled() then
        local db = Settings()
        if db and db.collect then
            NS.After(3, function() MinimapSkin:Collect() end)
        end
        return
    end

    NS.After(2, function() MinimapSkin:Apply() end)
    NS.After(6, function() MinimapSkin:UpdateExtras() end)
end)

local behaviour = CreateFrame("Frame")
local zoomSeen, zoomAt, alphaNow = 0, 0, 1
local sinceTick = 0

local function MapFrames()
    local list = { _G.MinimapCluster or Minimap }
    if MinimapSkin.frame then list[#list + 1] = MinimapSkin.frame end
    if MinimapSkin.info then list[#list + 1] = MinimapSkin.info end
    return list
end

function MinimapSkin:BehaviourAlpha()
    local db = NS.db and NS.db.minimap or {}
    local alpha = (db.mapAlpha or 100) / 100
    if InCombatLockdown() and (db.combatAlpha or 100) < 100 then alpha = db.combatAlpha / 100 end
    if alpha < 1 and Minimap:IsShown() and MouseIsOver(Minimap) then alpha = 1 end
    return alpha
end

behaviour:SetScript("OnUpdate", function(_, elapsed)
    sinceTick = sinceTick + elapsed
    if sinceTick < 0.2 then return end
    sinceTick = 0
    local db = NS.db and NS.db.minimap
    if not db then return end

    local delay = db.autoZoom or 0
    local zoom = Minimap:GetZoom() or 0
    if zoom ~= zoomSeen then
        zoomSeen = zoom
        zoomAt = GetTime()
    end
    if delay > 0 and zoom > 0 and GetTime() - zoomAt >= delay then
        Minimap:SetZoom(0)
        zoomSeen = 0
        if _G.MinimapZoomIn then MinimapZoomIn:Enable() end
        if _G.MinimapZoomOut then MinimapZoomOut:Disable() end
    end

    local alpha = MinimapSkin:BehaviourAlpha()
    if alpha ~= alphaNow then
        alphaNow = alpha
        for _, frame in ipairs(MapFrames()) do frame:SetAlpha(alpha) end
    end
end)
