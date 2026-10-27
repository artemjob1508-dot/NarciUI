local addonName, NS = ...
local L = NS.L

local NarciUI = {}
NS.NarciUI = NarciUI

local format = string.format
local max = math.max
local min = math.min

local SLOT_SIZE = 48
local SLOT_NAME_MAX_CHARS = 24
local MODEL_WIDTH = 440
local MODEL_HEIGHT = 480
local BOTTOM_Y = -252
local SLOT_GAP = 70

local TOOLBAR_INDICATOR_Y = 4

local ARC_CURVE = 90
local ARC_BASE_LEFT = -580
local ARC_BASE_RIGHT = 200
local ARC_TOP_Y = 230
local NUM_SIDE_SLOTS = 8
local MODEL_X = (ARC_BASE_LEFT + ARC_BASE_RIGHT) / 2

local function getArcX(baseX, slotIndex, isRight)
    local t = (slotIndex - 1) / (NUM_SIDE_SLOTS - 1)
    local curve = 1 - (2 * t - 1) ^ 2
    local dir = isRight and 1 or -1
    return baseX + dir * ARC_CURVE * curve
end

local SLOT_LAYOUT = {}
local leftIds = { 1, 2, 3, 15, 5, 4, 19, 9 }
local leftNames = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
for i = 1, NUM_SIDE_SLOTS do
    SLOT_LAYOUT[i] = {
        id = leftIds[i], name = leftNames[i],
        x = getArcX(ARC_BASE_LEFT, i, false),
        y = ARC_TOP_Y - (i - 1) * SLOT_GAP,
        side = "LEFT",
    }
end
local rightIds = { 10, 6, 7, 8, 11, 12, 13, 14 }
local rightNames = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
for i = 1, NUM_SIDE_SLOTS do
    SLOT_LAYOUT[NUM_SIDE_SLOTS + i] = {
        id = rightIds[i], name = rightNames[i],
        x = getArcX(ARC_BASE_RIGHT, i, true),
        y = ARC_TOP_Y - (i - 1) * SLOT_GAP,
        side = "RIGHT",
    }
end
local arcMidX = (ARC_BASE_LEFT + ARC_BASE_RIGHT) / 2
tinsert(SLOT_LAYOUT, { id = 16, name = "MainHandSlot",     x = arcMidX - 90, y = BOTTOM_Y + 15, side = "BOTTOM" })
tinsert(SLOT_LAYOUT, { id = 17, name = "SecondaryHandSlot",x = arcMidX,      y = BOTTOM_Y - 10, side = "BOTTOM" })
tinsert(SLOT_LAYOUT, { id = 18, name = "RangedSlot",       x = arcMidX + 90, y = BOTTOM_Y + 15, side = "BOTTOM" })

NarciUI.SLOT_LAYOUT = SLOT_LAYOUT
NarciUI.MODEL_X = MODEL_X

local MAX_BASE_DIM = 0.72

local LABEL_PAD      = 26
local LABEL_PER_CHAR = 6.5
local TOP_BAR_HEIGHT = 82
local TOOLBAR_TOP    = 98
local BOTTOM_LABEL   = 28
local SCENE_MARGIN   = 8
local MIN_AUTO_SCALE = 0.55

function NarciUI:GetAutoScale()
    local w = UIParent:GetWidth() or 1024
    local h = UIParent:GetHeight() or 768
    local half = SLOT_SIZE / 2
    local chars = (NS.db and NS.db.nameLength) or SLOT_NAME_MAX_CHARS
    local labelSpan = LABEL_PAD + chars * LABEL_PER_CHAR
    if NS.db and NS.db.showItemNames == false then labelSpan = 0 end

    local leftExtent = -ARC_BASE_LEFT + ARC_CURVE + half + labelSpan
    local rightExtent = ARC_BASE_RIGHT + ARC_CURVE + half + labelSpan
    local S = NS.Styling
    local panelColumn = (S and S.PANEL_WIDTH or 440)
                        - (S and S.PANEL_X or -8) + 16

    local needWidth = 2 * max(leftExtent, rightExtent + panelColumn)
    local needHeight = 2 * max(
        ARC_TOP_Y + half + TOP_BAR_HEIGHT + SCENE_MARGIN,
        -BOTTOM_Y + 10 + half + BOTTOM_LABEL + TOOLBAR_TOP + SCENE_MARGIN)

    local scale = min(1, w / needWidth, h / needHeight)
    return max(MIN_AUTO_SCALE, scale)
end

local protectedCache = {}
local cachedInCombat = false

local function SubtreeProtected(frame, depth)
    if not frame or not frame.IsProtected then return false end
    local _, explicit = frame:IsProtected()
    if explicit then return true end
    if depth >= 4 then return false end

    local kids = { frame:GetChildren() }
    for i = 1, #kids do
        if SubtreeProtected(kids[i], depth + 1) then return true end
    end
    return false
end

local function CanTouchSecure()
    return not InCombatLockdown()
end

local function CanTouchProtected(frame)
    local combat = InCombatLockdown()
    if combat ~= cachedInCombat then
        cachedInCombat = combat
        for key in pairs(protectedCache) do protectedCache[key] = nil end
    end
    if not combat then return true end
    if not frame or not frame.IsProtected then return true end

    local cached = protectedCache[frame]
    if cached == nil then
        cached = SubtreeProtected(frame, 0)
        protectedCache[frame] = cached
    end
    return not cached
end

function NarciUI:ApplyScale()
    local mf = self.mainFrame
    if not mf then return end
    if InCombatLockdown() then
        self._scalePending = true
        return
    end
    self._scalePending = nil

    local scale = NS.db and NS.db.scaleOverride
    if not scale or scale <= 0 then scale = self:GetAutoScale() end
    self._appliedScale = scale

    mf:SetScale(scale)
    if mf.slotFrames then
        for _, sf in pairs(mf.slotFrames) do sf:SetScale(scale) end
    end
end

function NarciUI:ApplyWorldDim()
    local ov = self.edgeVignette
    if not ov or not ov.baseDim then return end
    local amount = (NS.db and NS.db.worldDim) or 0
    amount = max(0, min(100, amount)) / 100
    ov.baseDim:SetVertexColor(0.015, 0.015, 0.03, MAX_BASE_DIM * amount)
end

function NarciUI:SetSceneVisible(show)
    local mf = self.mainFrame
    self.sceneHidden = (not show) or nil
    if not mf then return end

    if mf.model then
        if show then mf.model:Show() else mf.model:Hide() end
    end

    if mf.backlight then
        if show then
            self:ApplyBacklight()
        else
            for i = 1, #mf.backlight do mf.backlight[i]:Hide() end
            if mf.modelFloor then mf.modelFloor:Hide() end
            if mf.spinner then mf.spinner:Hide() end
            if mf.sceneFog then mf.sceneFog:Hide() end
            if mf.sceneMotes then mf.sceneMotes:Hide() end
        end
    end

    if mf.slotFrames then
        for _, sf in pairs(mf.slotFrames) do
            if show then
                if not sf._hiddenEmpty then
                    sf:Show()
                    if sf.visual then
                        sf.visual:SetAlpha(1)
                        sf.visual:Show()
                    end
                end
            else
                sf:Hide()
                if sf.visual then sf.visual:Hide() end
            end
        end
    end

    if NS.EquipInfo then
        if show then NS.EquipInfo:Show() else NS.EquipInfo:Hide() end
    end
end

local BACKLIGHT_STYLES = {
    glow = { w = 620, h = 720, alpha = 0.2 },
    rays = { path = "BacklightRays", w = 760, h = 760, alpha = 0.32, spin = true },
    halo = { path = "BacklightHalo", w = 640, h = 640, alpha = 0.26 },
}

local FLOORS = {
    runes = { path = "FloorRunes", alpha = 0.55, spin = true },
    glow = { alpha = 0.35 },
}

NarciUI.BACKLIGHT_STYLES = BACKLIGHT_STYLES
NarciUI.FLOORS = FLOORS

local EXTRAS = { shapes = {}, backlights = {}, floors = {} }

function NarciUI:Extras(kind)
    return EXTRAS[kind] or {}
end

function NarciUI:AddBacklight(key, label, style)
    if type(key) ~= "string" or BACKLIGHT_STYLES[key] or type(style) ~= "table" or type(style.path) ~= "string" then return false end
    BACKLIGHT_STYLES[key] = {
        path = style.path, w = tonumber(style.width) or 640, h = tonumber(style.height) or 640,
        alpha = tonumber(style.alpha) or 0.25, spin = style.spin and true or false,
    }
    table.insert(EXTRAS.backlights, { key = key, label = label or key })
    return true
end

function NarciUI:AddFloor(key, label, path, opts)
    if type(key) ~= "string" or key == "none" or FLOORS[key] or type(path) ~= "string" then return false end
    opts = type(opts) == "table" and opts or {}
    FLOORS[key] = { path = path, alpha = tonumber(opts.alpha) or 0.5, spin = opts.spin and true or false }
    table.insert(EXTRAS.floors, { key = key, label = label or key })
    return true
end

function NarciUI:ApplyBacklight(frame)
    local mf = frame or self.mainFrame
    local parts = mf and mf.backlight
    if not parts then return end
    local db = NS.db or {}
    local S = NS.Styling
    local on = db.modelBacklight ~= false
    local r, g, b = NarciUI:BacklightColor()
    local power = (db.backlightPower or 100) / 100
    local style = BACKLIGHT_STYLES[db.backlightStyle or "glow"] or BACKLIGHT_STYLES.glow
    for i = 1, #parts do
        parts[i]:SetTexture(style.path and S.Media(style.path) or S.GLOW)
        parts[i]:SetSize(style.w, style.h)
        parts[i]:SetVertexColor(r, g, b, style.alpha * power)
        if parts[i].SetRotation then pcall(parts[i].SetRotation, parts[i], 0) end
        if on and power > 0 then parts[i]:Show() else parts[i]:Hide() end
    end

    local floor = mf.modelFloor
    if not floor then
        floor = mf:CreateTexture(nil, "BACKGROUND", nil, 1)
        floor:SetBlendMode("ADD")
        mf.modelFloor = floor
    end
    local floorKind = db.modelFloor or "none"
    local floorArt = FLOORS[floorKind]
    if not floorArt then
        floor:Hide()
    else
        floor:SetTexture(floorArt.path and S.Media(floorArt.path) or S.GLOW)
        local size = db.floorSize or 360
        floor:SetSize(size, size * 0.32)
        floor:ClearAllPoints()
        floor:SetPoint("CENTER", mf, "CENTER", MODEL_X, db.floorY or -205)
        floor:SetVertexColor(r, g, b, floorArt.alpha * math.max(0.3, power))
        floor:Show()
    end

    local spin = db.modelSpin ~= false
    if not mf.spinner then
        local spinner = CreateFrame("Frame", nil, mf)
        spinner.angle = 0
        spinner:SetScript("OnUpdate", function(self, elapsed)
            self.angle = (self.angle + elapsed * 0.12) % (math.pi * 2)
            if self.floor and self.floor:IsShown() and self.floor.SetRotation then
                pcall(self.floor.SetRotation, self.floor, self.angle)
            end
            if self.rays and self.rays:IsShown() and self.rays.SetRotation then
                pcall(self.rays.SetRotation, self.rays, -self.angle * 0.5)
            end
        end)
        mf.spinner = spinner
    end
    mf.spinner.floor = floorArt and floorArt.spin and floor or nil
    mf.spinner.rays = style.spin and parts[1] or nil
    mf.spinner:SetShown(spin and (mf.spinner.floor ~= nil or mf.spinner.rays ~= nil))

    self:ApplyScene(mf)
end

local SCENE_BACKDROPS = {
    dusk   = { 0.10, 0.12, 0.24, 0.01, 0.01, 0.03 },
    abyss  = { 0.03, 0.03, 0.05, 0, 0, 0 },
    ember  = { 0.26, 0.09, 0.04, 0.03, 0.01, 0.01 },
    forest = { 0.05, 0.16, 0.11, 0.01, 0.03, 0.02 },
    frost  = { 0.14, 0.22, 0.32, 0.02, 0.04, 0.07 },
    violet = { 0.18, 0.07, 0.25, 0.03, 0.01, 0.05 },
}

local POSE_ANIMS = {
    stand = 0, ready = 26, dance = 69, wave = 67, cheer = 68, bow = 66, salute = 113,
    flex = 82, roar = 74, laugh = 70, kneel = 75, applaud = 80, sit = 97,
}

NarciUI.POSE_ANIMS = POSE_ANIMS
NarciUI.SCENE_BACKDROPS = SCENE_BACKDROPS

local MOTE_SPAN = 330

local function ClassRGB()
    local _, class = UnitClass("player")
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function ResetMote(t, anywhere)
    t.x = MODEL_X + (math.random() * 2 - 1) * 300
    t.y = anywhere and (math.random() * 2 - 1) * MOTE_SPAN or -MOTE_SPAN
    t.speed = 14 + math.random() * 26
    t.phase = math.random() * 6.28
    t.life = 0
    local size = 9 + math.random() * 21
    t:SetSize(size, size)
end

local function MoteUpdate(self, elapsed)
    for i = 1, self.count or 0 do
        local t = self.list[i]
        t.y = t.y + t.speed * elapsed
        t.life = t.life + elapsed
        if t.y > MOTE_SPAN then ResetMote(t) end
        local fade = min(1, (t.y + MOTE_SPAN) / 120, (MOTE_SPAN - t.y) / 120)
        local twinkle = 0.6 + 0.4 * math.sin(t.life * 2 + t.phase)
        t:ClearAllPoints()
        t:SetPoint("CENTER", self, "CENTER", t.x + math.sin(t.life * 0.8 + t.phase) * 18, t.y)
        t:SetVertexColor(self.r, self.g, self.b, 0.55 * max(0, fade) * twinkle)
    end
end

function NarciUI:ApplyScene(frame)
    local mf = frame or self.mainFrame
    local ov = self.edgeVignette
    if not mf or not ov then return end
    local db = NS.db or {}
    local S = NS.Styling
    local r, g, b = self:BacklightColor()

    local back = ov.sceneBack
    if not back then
        back = ov:CreateTexture(nil, "BACKGROUND", nil, -1)
        back:SetAllPoints(mf)
        back:SetTexture("Interface\\Buttons\\WHITE8x8")
        ov.sceneBack = back
    end
    local kind = db.sceneBackdrop or "none"
    local alpha = (db.sceneAlpha or 85) / 100
    local c = SCENE_BACKDROPS[kind]
    if kind == "accent" or kind == "class" then
        local cr, cg, cb = S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
        if kind == "class" then cr, cg, cb = ClassRGB() end
        c = { cr * 0.32, cg * 0.32, cb * 0.32, cr * 0.03, cg * 0.03, cb * 0.03 }
    end
    if c and alpha > 0 then
        back:SetGradientAlpha("VERTICAL", c[4], c[5], c[6], alpha, c[1], c[2], c[3], alpha)
        back:Show()
    else
        back:Hide()
    end

    local fog = mf.sceneFog
    if not fog then
        fog = mf:CreateTexture(nil, "BACKGROUND", nil, 0)
        fog:SetTexture(S.GLOW)
        fog:SetBlendMode("ADD")
        mf.sceneFog = fog
    end
    local fogPower = (db.sceneFog or 0) / 100
    if fogPower > 0 and not self.sceneHidden then
        fog:SetSize(1100, 300)
        fog:ClearAllPoints()
        fog:SetPoint("CENTER", mf, "CENTER", MODEL_X, (db.floorY or -205) - 10)
        fog:SetVertexColor(r * 0.6 + 0.25, g * 0.6 + 0.25, b * 0.6 + 0.25, 0.45 * fogPower)
        fog:Show()
    else
        fog:Hide()
    end

    local count = (not self.sceneHidden) and (db.sceneMotes or 0) or 0
    local motes = mf.sceneMotes
    if count > 0 and not motes then
        motes = CreateFrame("Frame", nil, mf)
        motes:SetAllPoints(mf)
        motes:SetFrameLevel(mf:GetFrameLevel())
        motes.list = {}
        motes:SetScript("OnUpdate", MoteUpdate)
        mf.sceneMotes = motes
    end
    if motes then
        for i = #motes.list + 1, count do
            local t = motes:CreateTexture(nil, "ARTWORK")
            t:SetTexture(S.GLOW)
            t:SetBlendMode("ADD")
            motes.list[i] = t
            ResetMote(t, true)
        end
        for i, t in ipairs(motes.list) do
            if i <= count then t:Show() else t:Hide() end
        end
        motes.count = count
        motes.r, motes.g, motes.b = min(1, r * 0.7 + 0.35), min(1, g * 0.7 + 0.35), min(1, b * 0.7 + 0.35)
        if count > 0 then motes:Show() else motes:Hide() end
    end
end

function NarciUI:ApplyPose()
    local model = self.mainFrame and self.mainFrame.model
    if not model then return end
    local key = NS.db and NS.db.modelPose or "stand"
    if key == "random" then
        local keys = {}
        for k in pairs(POSE_ANIMS) do
            if k ~= "stand" then keys[#keys + 1] = k end
        end
        table.sort(keys)
        key = keys[math.random(#keys)]
    end
    local anim = POSE_ANIMS[key]
    model.poseAnim = (anim and anim > 0) and anim or nil
    model.poseTime = 0
    if not model.poseAnim then pcall(model.SetSequence, model, 0) end
end

function NarciUI:PlaceModel()
    local model = self.mainFrame and self.mainFrame.model
    if not model then return end
    pcall(model.SetPosition, model, 0, model.panY or 0, model.panZ or 0)
end

function NarciUI:ResetModelView()
    local model = self.mainFrame and self.mainFrame.model
    if NS.db then
        NS.db.modelFacing, NS.db.modelScale, NS.db.modelPanY, NS.db.modelPanZ = nil, nil, nil, nil
    end
    if not model then return end
    model.panY, model.panZ = 0, 0
    model:SetFacing(0.4)
    pcall(model.SetModelScale, model, 1)
    self:PlaceModel()
end

local BACKLIGHT_COLORS = {
    cool = { 0.34, 0.44, 0.62 },
    warm = { 0.70, 0.50, 0.30 },
    white = { 0.62, 0.62, 0.66 },
    rose = { 0.66, 0.36, 0.52 },
}

function NarciUI:BacklightColor()
    local key = NS.db and NS.db.backlightColor or "cool"
    if key == "accent" then
        local A = NS.Styling.ACCENT
        return A[1], A[2], A[3]
    elseif key == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then return c.r, c.g, c.b end
    end
    local c = BACKLIGHT_COLORS[key] or BACKLIGHT_COLORS.cool
    return c[1], c[2], c[3]
end

function NarciUI:Create()
    if self.mainFrame then return end
    local mf = CreateFrame("Frame", "NarcissusSirus_MainFrame", UIParent)
    mf:SetAllPoints(UIParent)
    mf:SetFrameStrata("FULLSCREEN_DIALOG")
    mf:SetFrameLevel(200)
    mf:Hide()

    local slotAnchor = CreateFrame("Frame", "NarciSirus_SlotAnchor", UIParent)
    slotAnchor:SetAllPoints(UIParent)
    self.slotAnchor = slotAnchor
    mf.slotAnchor = slotAnchor

    tinsert(UISpecialFrames, "NarcissusSirus_MainFrame")
    mf:SetScript("OnHide", function()
        if NarciUI.isShown then NarciUI:Hide() end
    end)

    local NUM_STRIPS = 30
    local STRIP_SIZE = 8
    local MAX_ALPHA = 0.85
    local tex = "Interface\\Buttons\\WHITE8x8"
    local ov = CreateFrame("Frame", nil, mf)
    ov:SetAllPoints(mf)
    ov:SetFrameStrata("BACKGROUND")
    ov:SetFrameLevel(0)

    local baseDim = ov:CreateTexture(nil, "BACKGROUND", nil, -2)
    baseDim:SetAllPoints(mf)
    baseDim:SetTexture(tex)
    baseDim:SetVertexColor(0.015, 0.015, 0.03, 0)
    ov.baseDim = baseDim

    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, -(i - 1) * STRIP_SIZE)
        t:SetPoint("TOPRIGHT", mf, "TOPRIGHT", 0, -(i - 1) * STRIP_SIZE)
        t:SetHeight(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("BOTTOMLEFT", mf, "BOTTOMLEFT", 0, (i - 1) * STRIP_SIZE)
        t:SetPoint("BOTTOMRIGHT", mf, "BOTTOMRIGHT", 0, (i - 1) * STRIP_SIZE)
        t:SetHeight(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPLEFT", mf, "TOPLEFT", (i - 1) * STRIP_SIZE, 0)
        t:SetPoint("BOTTOMLEFT", mf, "BOTTOMLEFT", (i - 1) * STRIP_SIZE, 0)
        t:SetWidth(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -(i - 1) * STRIP_SIZE, 0)
        t:SetPoint("BOTTOMRIGHT", mf, "BOTTOMRIGHT", -(i - 1) * STRIP_SIZE, 0)
        t:SetWidth(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    self.edgeVignette = ov
    self:ApplyWorldDim()

    local glow = mf:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(NS.Styling.GLOW)
    glow:SetBlendMode("ADD")
    glow:SetSize(620, 720)
    glow:SetPoint("CENTER", mf, "CENTER", MODEL_X, 0)
    glow:SetVertexColor(0.34, 0.44, 0.62, 0.2)
    mf.backlight = { glow }
    self:ApplyBacklight(mf)

    local model = CreateFrame("PlayerModel", "NarcissusSirus_MainModel", mf)
    model:SetSize(MODEL_WIDTH, MODEL_HEIGHT)
    model:SetPoint("CENTER", mf, "CENTER", MODEL_X, 0)
    model:SetUnit("player")
    model:SetFacing(0.4)
    pcall(model.SetPortraitZoom, model, 0.85)
    pcall(model.SetCamDistanceScale, model, 0.9)
    pcall(model.SetPosition, model, 0, 0, 0)
    model:SetFrameLevel(mf:GetFrameLevel() + 1)
    mf.model = model

    mf.slotFrames = {}
    self._slotLayout = SLOT_LAYOUT
    self:BuildSlotFrames(mf)

    local topBar = CreateFrame("Frame", nil, mf)
    topBar:SetHeight(82)
    topBar:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", mf, "TOPRIGHT", 0, 0)

    local playerName = topBar:CreateFontString(nil, "OVERLAY")
    playerName:SetFont(NS.FONT, NS.FS(22), "OUTLINE")
    playerName:SetPoint("TOP", topBar, "TOP", 0, -12)
    mf.playerName = playerName

    local classIcon = topBar:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("RIGHT", playerName, "LEFT", -8, 0)
    mf.classIcon = classIcon

    local playerDetails = topBar:CreateFontString(nil, "OVERLAY")
    playerDetails:SetFont(NS.FONT, NS.FS(12), "")
    playerDetails:SetTextColor(0.55, 0.55, 0.60)
    playerDetails:SetPoint("TOP", playerName, "BOTTOM", 0, -4)
    mf.playerDetails = playerDetails

    local function HeaderRule(left)
        local t = topBar:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        local A = NS.Styling.ACCENT
        if left then
            t:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 60, 0)
            t:SetPoint("BOTTOMRIGHT", topBar, "BOTTOM", 0, 0)
            t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0, A[1], A[2], A[3], 0.45)
        else
            t:SetPoint("BOTTOMLEFT", topBar, "BOTTOM", 0, 0)
            t:SetPoint("BOTTOMRIGHT", topBar, "BOTTOMRIGHT", -60, 0)
            t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0.45, A[1], A[2], A[3], 0)
        end
    end
    HeaderRule(true)
    HeaderRule(false)

    local sweep = CreateFrame("Frame", nil, mf)
    sweep:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 0, 0)
    sweep:SetPoint("BOTTOMRIGHT", topBar, "BOTTOMRIGHT", 0, 0)
    sweep:SetHeight(2)
    sweep:Hide()
    local G = NS.Styling.ACCENT_GLOW
    local function SweepHalf(toLeft)
        local t = sweep:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetBlendMode("ADD")
        t:SetHeight(2)
        t:SetWidth(1)
        if toLeft then
            t:SetPoint("RIGHT", sweep, "CENTER", 0, 0)
            t:SetGradientAlpha("Horizontal", G[1], G[2], G[3], 0, G[1], G[2], G[3], 0.9)
        else
            t:SetPoint("LEFT", sweep, "CENTER", 0, 0)
            t:SetGradientAlpha("Horizontal", G[1], G[2], G[3], 0.9, G[1], G[2], G[3], 0)
        end
        return t
    end
    sweep.left = SweepHalf(true)
    sweep.right = SweepHalf(false)
    mf.introSweep = sweep

    local specLine = topBar:CreateFontString(nil, "OVERLAY")
    specLine:SetFont(NS.FONT, NS.FS(12), "")
    specLine:SetPoint("TOP", playerDetails, "BOTTOM", 0, -3)
    mf.specLine = specLine

    local motto = mf:CreateFontString(nil, "OVERLAY")
    motto:SetFont(NS.FONT, NS.FS(12), "")
    motto:SetShadowColor(0, 0, 0, 1)
    motto:SetShadowOffset(1, -1)
    motto:SetPoint("TOP", topBar, "BOTTOM", 0, -8)
    mf.motto = motto
    NS.Styling.WatchBrand(function() NarciUI:UpdateMotto() end)

    local iLvlDisplay = CreateFrame("Frame", nil, topBar)
    iLvlDisplay:SetSize(120, 40)
    iLvlDisplay:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", -60, -10)
    local iLvlLabel = iLvlDisplay:CreateFontString(nil, "OVERLAY")
    iLvlLabel:SetFont(NS.FONT, NS.FS(9), "")
    iLvlLabel:SetTextColor(0.40, 0.42, 0.50)
    iLvlLabel:SetPoint("TOP", iLvlDisplay, "TOP", 0, -2)
    iLvlLabel:SetText(L["УРОВЕНЬ ПРЕДМЕТОВ"])
    local iLvlValue = iLvlDisplay:CreateFontString(nil, "OVERLAY")
    iLvlValue:SetFont(NS.FONT, NS.FS(20), "OUTLINE")
    iLvlValue:SetTextColor(NS.Styling.GOLD[1], NS.Styling.GOLD[2], NS.Styling.GOLD[3])
    iLvlValue:SetPoint("TOP", iLvlLabel, "BOTTOM", 0, -2)
    mf.iLvlValue = iLvlValue

    local closeBtn = CreateFrame("Button", nil, mf)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -16, -10)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    closeBg:SetVertexColor(0.12, 0.12, 0.18, 0.85)
    local closeBorder = CreateFrame("Frame", nil, closeBtn)
    closeBorder:SetPoint("TOPLEFT", -1, 1)
    closeBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    closeBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    closeBorder:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    closeBorder:EnableMouse(false)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(NS.FONT, NS.FS(16), "OUTLINE")
    closeText:SetTextColor(0.9, 0.3, 0.3)
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    NS.Styling.GlyphIcon(closeText)
    closeBtn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    closeBtn:GetHighlightTexture():SetVertexColor(0.5, 0.1, 0.1, 0.3)
    closeBtn:SetScript("OnClick", function() NarciUI:Hide() end)
    closeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["Закрыть (C / Esc)"], 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local toolbar = CreateFrame("Frame", nil, mf)
    toolbar:SetHeight(52)
    toolbar:SetPoint("BOTTOM", mf, "BOTTOM", 0, 46)
    mf.toolbar = toolbar

    local toolbarButtons = {
        { label = L["Статы"],      panel = "StatsPanel",      tool = "ToolStats",       func = function() NS:ToggleStatsPanel() end },
        { label = L["Усиления"],   panel = "Enhancements",    tool = "ToolEnhance",     func = function() NS:ToggleEnhancements() end },
        { label = L["Таланты"],    panel = "TalentPanel",     tool = "ToolTalents",     func = function() NS:ToggleTalentPanel() end },
        { label = L["Титулы"],     panel = "TitleManager",    tool = "ToolTitles",      func = function() NS:ToggleTitleManager() end },
        { label = L["Быстрые наборы"], panel = "OutfitManager", tool = "ToolOutfits",   func = function() NS:ToggleOutfitManager() end },
        { label = L["Репутация"],  panel = "ReputationPanel", tool = "ToolReputation",  func = function() NS:ToggleReputation() end },
        { label = L["Валюта"],     panel = "CurrencyPanel",   tool = "ToolCurrency",    func = function() NS:ToggleCurrency() end },
        { label = L["Заклинания"],                            tool = "ToolSpells",      func = function() NS:ToggleSpellBook() end },
        { label = L["Профессии"],  panel = "ProfessionsPanel", tool = "ToolProfessions", func = function() NS:ToggleProfessions() end },
    }
    local hiddenTools = NS.db and NS.db.toolbarHidden
    if type(hiddenTools) == "table" then
        for index = #toolbarButtons, 1, -1 do
            if hiddenTools[toolbarButtons[index].tool] then table.remove(toolbarButtons, index) end
        end
    end
    for _, tab in ipairs(NS.PluginTabs or {}) do
        toolbarButtons[#toolbarButtons + 1] = { label = tab.label, panel = tab.panel, tool = tab.icon,
            func = function() NS:TogglePanelByName(tab.panel) end }
    end
    toolbarButtons[#toolbarButtons + 1] = { label = L["Настройки"], tool = "ToolSettings", func = function() NS:ToggleSettings() end }
    mf.toolbarButtons = {}
    local numBtns = #toolbarButtons
    local btnSpacing = 52
    local S = NS.Styling

    toolbar:SetWidth(numBtns * btnSpacing + 18)
    toolbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    toolbar:SetBackdropColor(S.Bg(0.85))
    toolbar:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(toolbar, 4, 0.35)
    S.ApplyTabChrome(toolbar)

    local toolbarCaption = mf:CreateFontString(nil, "OVERLAY")
    toolbarCaption:SetFont(NS.FONT, NS.FS(11), "")
    toolbarCaption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    toolbarCaption:SetPoint("BOTTOM", toolbar, "TOP", 0, 7)
    mf.toolbarCaption = toolbarCaption

    for i, btnInfo in ipairs(toolbarButtons) do
        local btn = CreateFrame("Button", nil, toolbar)
        btn:SetSize(40, 40)
        btn:SetPoint("CENTER", toolbar, "CENTER", (i - (numBtns + 1) / 2) * btnSpacing, 3)

        local shape = S.ORN.toolbar
        local styled = shape == "hex" or (shape ~= "square" and S.DECOR)
        local A, G = S.ACCENT, S.ACCENT_GLOW

        local activeGlow = btn:CreateTexture(nil, "BACKGROUND")
        activeGlow:SetPoint("CENTER")
        activeGlow:SetBlendMode("ADD")
        activeGlow:Hide()
        btn.activeGlow = activeGlow

        if styled then
            local face = btn:CreateTexture(nil, "BORDER")
            face:SetSize(44, 44)
            face:SetPoint("CENTER")
            face:SetTexture(S.Media("HexFill"))
            face:SetVertexColor(S.Tint(0.05, 0.05, 0.09, 0.95))

            local inner = btn:CreateTexture(nil, "BORDER")
            inner:SetAllPoints(face)
            inner:SetTexture(S.Media("HexInner"))
            inner:SetVertexColor(A[1], A[2], A[3], 0.22)

            local ring = btn:CreateTexture(nil, "OVERLAY")
            ring:SetAllPoints(face)
            ring:SetTexture(S.Media("HexRing"))
            ring:SetVertexColor(A[1], A[2], A[3], 0.55)
            btn.ring = ring

            activeGlow:SetSize(62, 62)
            activeGlow:SetTexture(S.Media("HexGlow"))
            activeGlow:SetVertexColor(A[1], A[2], A[3], 0.55)

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(face)
            highlight:SetTexture(S.Media("HexInner"))
            highlight:SetBlendMode("ADD")
            highlight:SetVertexColor(G[1], G[2], G[3], 0.35)
        else
            local btnBg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
            btnBg:SetAllPoints()
            btnBg:SetTexture("Interface\\Buttons\\WHITE8x8")
            btnBg:SetVertexColor(0.06, 0.07, 0.12, 0.85)
            S.RoundTexture(btnBg, 6)

            activeGlow:SetSize(56, 56)
            activeGlow:SetTexture(S.GLOW)
            activeGlow:SetVertexColor(A[1], A[2], A[3], 0.45)

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
            highlight:SetVertexColor(G[1], G[2], G[3], 0.12)
            S.RoundTexture(highlight, 6)

            S.CreateRingBorder(btn)
        end

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(styled and 22 or 24, styled and 22 or 24)
        icon:SetPoint("CENTER")
        icon:SetTexture(S.Media(btnInfo.tool))

        btn.panelName = btnInfo.panel
        btn.label = btnInfo.label
        btn.icon = icon
        btn.toolbarX = (i - (numBtns + 1) / 2) * btnSpacing

        btn:SetScript("OnEnter", function()
            if mf.toolbarCaption then
                mf.toolbarCaption:SetText(btnInfo.label)
                mf.toolbarCaption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            end
        end)
        btn:SetScript("OnLeave", function()
            NarciUI:UpdateToolbarState()
        end)
        btn:SetScript("OnClick", btnInfo.func)
        mf.toolbarButtons[i] = btn
    end

    local indicator = CreateFrame("Frame", nil, toolbar)
    indicator:SetSize(40, 2)
    indicator:SetPoint("BOTTOM", toolbar, "BOTTOM", 0, TOOLBAR_INDICATOR_Y)
    local indicatorTex = indicator:CreateTexture(nil, "OVERLAY")
    indicatorTex:SetAllPoints()
    indicatorTex:SetTexture("Interface\\Buttons\\WHITE8x8")
    indicatorTex:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    indicator:Hide()
    mf.toolbarIndicator = indicator

    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.dragging = true
            self.startX = GetCursorPosition()
        elseif button == "RightButton" then
            self.panning = true
            self.startPX, self.startPY = GetCursorPosition()
        end
    end)
    model:SetScript("OnMouseUp", function(self)
        self.dragging = false
        self.panning = false
    end)
    model:SetScript("OnUpdate", function(self, e)
        if self.poseAnim then
            self.poseTime = (self.poseTime or 0) + (e or 0) * 1000
            pcall(self.SetSequenceTime, self, self.poseAnim, self.poseTime)
        end
        if self.dragging then
            local x = GetCursorPosition()
            local delta = (x - (self.startX or x)) * 0.01
            self:SetFacing(self:GetFacing() + delta)
            self.startX = x
            self.intro = nil
        elseif self.panning then
            local x, y = GetCursorPosition()
            local k = 0.0035 / (self:GetEffectiveScale() or 1)
            self.panY = max(-2, min(2, (self.panY or 0) + (x - (self.startPX or x)) * k))
            self.panZ = max(-2, min(2, (self.panZ or 0) + (y - (self.startPY or y)) * k))
            self.startPX, self.startPY = x, y
            NarciUI:PlaceModel()
        elseif self.intro then
            local a = self.intro
            a.elapsed = a.elapsed + (e or 0)
            local t = a.elapsed / a.duration
            if t >= 1 then
                self:SetFacing(a.toFacing)
                self:SetModelScale(a.toScale)
                self.intro = nil
            else
                local k = 1 - (1 - t) ^ 3
                self:SetFacing(a.fromFacing + (a.toFacing - a.fromFacing) * k)
                self:SetModelScale(a.fromScale + (a.toScale - a.fromScale) * k)
            end
        end
    end)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        local scale = self:GetModelScale() or 1
        if delta > 0 then scale = min(scale * 1.05, 2.0) else scale = max(scale * 0.95, 0.5) end
        self:SetModelScale(scale)
    end)

    NS.Styling.WindowSounds(mf)
    self.mainFrame = mf
end

function NarciUI:BuildSlotFrames(frame)
    local mf = frame or self.mainFrame
    if not mf or not mf.slotFrames then return end
    if InCombatLockdown() then
        self._slotsDeferred = true
        return
    end
    self._slotsDeferred = nil

    for _, slotInfo in ipairs(SLOT_LAYOUT) do
        if not mf.slotFrames[slotInfo.id] then
            local slotFrame = self:CreateSlotFrame(mf, slotInfo)
            slotFrame._origX = slotInfo.x
            slotFrame._origY = slotInfo.y
            mf.slotFrames[slotInfo.id] = slotFrame
            if not self.isShown then
                slotFrame:Hide()
                if slotFrame.visual then slotFrame.visual:Hide() end
            end
        end
    end
end

function NarciUI:CreateSlotFrame(parent, slotInfo)
    local slotName = "Character" .. slotInfo.name
    local originalButton = _G[slotName]
    local S = NS.Styling

    local f = CreateFrame("Button", "NarciSirus_Slot_" .. slotInfo.id, UIParent, "SecureActionButtonTemplate")
    f:SetSize(SLOT_SIZE, SLOT_SIZE)
    f:SetPoint("CENTER", self.slotAnchor or parent, "CENTER", slotInfo.x, slotInfo.y)
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:SetFrameStrata(parent:GetFrameStrata())
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    f:SetID(slotInfo.id)

    if originalButton then
        f:SetAttribute("type", "click")
        f:SetAttribute("type1", "click")
        f:SetAttribute("type2", "click")
        f:SetAttribute("clickbutton", originalButton)
    end

    f:SetAttribute("target-slot", slotInfo.id)

    local v = CreateFrame("Frame", nil, parent)
    v:SetSize(SLOT_SIZE, SLOT_SIZE)
    v:SetPoint("CENTER", parent, "CENTER", slotInfo.x, slotInfo.y)
    v:SetFrameLevel(parent:GetFrameLevel() + 4)
    v:EnableMouse(true)
    f.visual = v

    local bg = v:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)

    local border = CreateFrame("Frame", nil, v)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    border:EnableMouse(false)

    local strip = v:CreateTexture(nil, "OVERLAY")
    strip:SetSize(2, SLOT_SIZE - 4)
    strip:SetTexture("Interface\\Buttons\\WHITE8x8")
    if slotInfo.side == "LEFT" then
        strip:SetPoint("LEFT", v, "LEFT", 0, 0)
    elseif slotInfo.side == "RIGHT" then
        strip:SetPoint("RIGHT", v, "RIGHT", 0, 0)
    else
        strip:SetPoint("LEFT", v, "LEFT", 0, 0)
    end
    strip:SetVertexColor(0.3, 0.3, 0.3, 0.6)
    f.qualityStrip = strip

    local slotBevel = v:CreateTexture(nil, "BORDER")
    slotBevel:SetHeight(1)
    slotBevel:SetPoint("TOPLEFT", v, "TOPLEFT", 1, -1)
    slotBevel:SetPoint("TOPRIGHT", v, "TOPRIGHT", -1, -1)
    slotBevel:SetTexture("Interface\\Buttons\\WHITE8x8")
    slotBevel:SetVertexColor(0.55, 0.60, 0.72, 0.28)

    f.bevel = slotBevel
    f.shadow = S.CreateSoftShadow(v, 4, 0.45)

    local icon = v:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local iLvlBg = v:CreateTexture(nil, "OVERLAY", nil, -1)
    iLvlBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    iLvlBg:SetVertexColor(0, 0, 0, 0.6)
    iLvlBg:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 2, 2)
    iLvlBg:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -2, 2)
    iLvlBg:SetHeight(14)
    iLvlBg:Hide()

    local iLvl = v:CreateFontString(nil, "OVERLAY")
    iLvl:SetFont(NS.FONT, NS.FS(12), "OUTLINE")
    iLvl:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    iLvl:SetPoint("BOTTOM", v, "BOTTOM", 0, 2)

    local enchantDot = S.CreateEnchantDot(v, slotInfo.side)

    local gemIcons = {}
    for i = 1, 4 do
        local btn = CreateFrame("Button", nil, v)
        btn:SetSize(14, 14)
        btn:SetFrameLevel(v:GetFrameLevel() + 2)
        btn:EnableMouse(false)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.texture = tex
        btn.gemLink = nil
        if slotInfo.side == "LEFT" then
            btn:SetPoint("TOPLEFT", v, "TOPRIGHT", 3, -2 - (i - 1) * 15)
        elseif slotInfo.side == "RIGHT" then
            btn:SetPoint("TOPRIGHT", v, "TOPLEFT", -3, -2 - (i - 1) * 15)
        else
            btn:SetPoint("BOTTOMLEFT", v, "TOPLEFT", 1 + (i - 1) * 15, 3)
        end
        tex:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        btn:Hide()
        btn:SetScript("OnEnter", function(self)
            if self.gemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.gemLink)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        gemIcons[i] = btn
    end

    local nameLabel = v:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(NS.FONT, NS.FS(13), "OUTLINE")
    nameLabel:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    if slotInfo.side == "LEFT" then
        nameLabel:SetPoint("RIGHT", v, "LEFT", -10, 0)
        nameLabel:SetJustifyH("RIGHT")
    elseif slotInfo.side == "RIGHT" then
        nameLabel:SetPoint("LEFT", v, "RIGHT", 10, 0)
        nameLabel:SetJustifyH("LEFT")
    else
        nameLabel:SetPoint("TOP", v, "BOTTOM", 0, -14)
        nameLabel:SetJustifyH("CENTER")
    end

    local namePlate = v:CreateTexture(nil, "BACKGROUND", nil, -2)
    namePlate:SetTexture(S.Media("Pill"))
    namePlate:SetPoint("TOPLEFT", nameLabel, "TOPLEFT", -22, 7)
    namePlate:SetPoint("BOTTOMRIGHT", nameLabel, "BOTTOMRIGHT", 22, -7)
    namePlate:SetVertexColor(0, 0, 0, 0.75)
    namePlate:Hide()
    f.namePlate = { namePlate }

    local okSlot, _, emptyTexture = pcall(GetInventorySlotInfo, slotInfo.name)
    f.emptyTexture = (okSlot and emptyTexture) or "Interface\\Icons\\INV_Misc_QuestionMark"

    local qualityGlow = v:CreateTexture(nil, "BACKGROUND", nil, -1)
    if slotInfo.side == "LEFT" then
        qualityGlow:SetTexture(S.Media("Fade"))
        qualityGlow:SetTexCoord(1, 0, 0, 1)
        qualityGlow:SetPoint("TOPRIGHT", v, "TOPLEFT", 0, 8)
        qualityGlow:SetPoint("BOTTOMRIGHT", v, "BOTTOMLEFT", 0, -8)
        qualityGlow:SetWidth(90)
    elseif slotInfo.side == "RIGHT" then
        qualityGlow:SetTexture(S.Media("Fade"))
        qualityGlow:SetPoint("TOPLEFT", v, "TOPRIGHT", 0, 8)
        qualityGlow:SetPoint("BOTTOMLEFT", v, "BOTTOMRIGHT", 0, -8)
        qualityGlow:SetWidth(90)
    else
        qualityGlow:SetTexture(S.Media("FadeV"))
        qualityGlow:SetPoint("TOPLEFT", v, "BOTTOMLEFT", -14, 0)
        qualityGlow:SetPoint("TOPRIGHT", v, "BOTTOMRIGHT", 14, 0)
        qualityGlow:SetHeight(64)
    end
    qualityGlow:SetVertexColor(1, 1, 1, 0.4)
    qualityGlow:Hide()
    f.qualityGlow = qualityGlow

    local highlight = f:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.15)
    f.highlight = highlight

    f.hoverGlow = S.AddHoverGlow(f)

    local function OnSlotEnter(self)
        local link = GetInventoryItemLink("player", slotInfo.id)
        if link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetInventoryItem("player", slotInfo.id); GameTooltip:Show() end
        if f.nameLabel then f.nameLabel:SetTextColor(1, 1, 1) end
        if NS.SlotFlyout then NS.SlotFlyout:OnSlotEnter(f) end
    end

    local function OnSlotLeave()
        GameTooltip:Hide()
        local c = f.nameColor
        if f.nameLabel and c then f.nameLabel:SetTextColor(c[1], c[2], c[3]) end
    end

    f:SetScript("OnEnter", OnSlotEnter)
    f:SetScript("OnLeave", OnSlotLeave)
    v:SetScript("OnEnter", OnSlotEnter)
    v:SetScript("OnLeave", OnSlotLeave)

    f.icon = icon; f.border = border; f.bg = bg; f.iLvlText = iLvl; f.iLvlBg = iLvlBg
    f.enchantDot = enchantDot
    f.gemIcons = gemIcons; f.nameLabel = nameLabel; f.slotId = slotInfo.id; f.slotSide = slotInfo.side
    return f
end

local SHAPE_ART = {
    circle  = { fill = "RoundFill", ring = "PortraitRing", size = 48, ringSize = 54, icon = 42 },
    hex     = { fill = "HexFill", inner = "HexInner", ring = "HexRing", size = 58, icon = 40 },
    diamond = { fill = "ShapeDiamondFill", inner = "ShapeDiamondInner", ring = "ShapeDiamondRing", size = 66, icon = 34 },
    octa    = { fill = "ShapeOctaFill", inner = "ShapeOctaInner", ring = "ShapeOctaRing", size = 56, icon = 42 },
    shield  = { fill = "ShapeShieldFill", inner = "ShapeShieldInner", ring = "ShapeShieldRing", size = 58, icon = 38, iconY = 3 },
    ornate  = { fill = "ShapeOrnateFill", inner = "ShapeOrnateInner", ring = "ShapeOrnateRing", size = 62, icon = 44 },
}

NarciUI.SHAPE_ART = SHAPE_ART

local SLOT_SHAPES = { square = true, classic = true }
for key in pairs(SHAPE_ART) do SLOT_SHAPES[key] = true end

function NarciUI:SlotShape()
    local shape = NS.db and NS.db.slotShape
    return SLOT_SHAPES[shape] and shape or "square"
end

function NarciUI:AddSlotShape(key, art)
    if type(key) ~= "string" or SLOT_SHAPES[key] or type(art) ~= "table" then return false end
    if type(art.fill) ~= "string" or type(art.ring) ~= "string" then return false end
    local size = tonumber(art.size) or 58
    SHAPE_ART[key] = {
        fill = art.fill, ring = art.ring, inner = type(art.inner) == "string" and art.inner or nil,
        size = size, ringSize = tonumber(art.ringSize), icon = tonumber(art.icon) or math.floor(size * 0.7),
        iconY = tonumber(art.iconY),
    }
    SLOT_SHAPES[key] = true
    table.insert(EXTRAS.shapes, { key = key, label = art.label or key })
    return true
end

function NarciUI:RoundShape(shape)
    return SHAPE_ART[shape or ""] ~= nil
end

local function PlaceTrail(f, round)
    local glow, v = f.qualityGlow, f.visual
    if not glow or not v then return end
    local S = NS.Styling
    glow:ClearAllPoints()
    if round then
        glow:SetTexture(S.GLOW)
        if f.slotSide == "LEFT" then
            glow:SetTexCoord(0, 0.5, 0, 1)
            glow:SetSize(190, 84)
            glow:SetPoint("RIGHT", v, "CENTER", 0, 0)
        elseif f.slotSide == "RIGHT" then
            glow:SetTexCoord(0.5, 1, 0, 1)
            glow:SetSize(190, 84)
            glow:SetPoint("LEFT", v, "CENTER", 0, 0)
        else
            glow:SetTexCoord(0, 1, 0.5, 1)
            glow:SetSize(88, 130)
            glow:SetPoint("TOP", v, "CENTER", 0, 0)
        end
        return
    end
    if f.slotSide == "LEFT" then
        glow:SetTexture(S.Media("Fade"))
        glow:SetTexCoord(1, 0, 0, 1)
        glow:SetPoint("TOPRIGHT", v, "TOPLEFT", 0, 8)
        glow:SetPoint("BOTTOMRIGHT", v, "BOTTOMLEFT", 0, -8)
        glow:SetWidth(90)
    elseif f.slotSide == "RIGHT" then
        glow:SetTexture(S.Media("Fade"))
        glow:SetTexCoord(0, 1, 0, 1)
        glow:SetPoint("TOPLEFT", v, "TOPRIGHT", 0, 8)
        glow:SetPoint("BOTTOMLEFT", v, "BOTTOMRIGHT", 0, -8)
        glow:SetWidth(90)
    else
        glow:SetTexture(S.Media("FadeV"))
        glow:SetTexCoord(0, 1, 0, 1)
        glow:SetPoint("TOPLEFT", v, "BOTTOMLEFT", -14, 0)
        glow:SetPoint("TOPRIGHT", v, "BOTTOMRIGHT", 14, 0)
        glow:SetHeight(64)
    end
end

local function ShapeTexture(v, layer, sub, size, path, blend)
    local t = v:CreateTexture(nil, layer, nil, sub)
    t:SetSize(size, size)
    t:SetPoint("CENTER", v, "CENTER", 0, 0)
    t:SetTexture(path)
    if blend then t:SetBlendMode(blend) end
    t:Hide()
    return t
end

function NarciUI:ShapeSlot(f)
    local shape = self:SlotShape()
    if f.shapeKey == shape or not f.visual then return end
    f.shapeKey = shape
    f.shapePath = nil

    local S = NS.Styling
    local v = f.visual
    local square = shape == "square"
    local art = SHAPE_ART[shape]

    if not f.shape then
        f.shape = {
            discShadow = ShapeTexture(v, "BACKGROUND", -3, 66, S.Media("SoftDisc")),
            fill = ShapeTexture(v, "BACKGROUND", 0, 58),
            inner = ShapeTexture(v, "BORDER", 0, 58),
            ring = ShapeTexture(v, "OVERLAY", -2, 58),
            roundIcon = ShapeTexture(v, "ARTWORK", 0, 42),
            classicFrame = ShapeTexture(v, "OVERLAY", -2, 88, "Interface\\Buttons\\UI-Quickslot2"),
            classicQuality = ShapeTexture(v, "OVERLAY", -1, 86, "Interface\\Buttons\\UI-ActionButton-Border", "ADD"),
        }
        f.shape.discShadow:SetVertexColor(0, 0, 0, 0.6)
    end
    local p = f.shape

    for _, part in ipairs({ f.border, f.shadow, f.hoverGlow }) do
        if part then part:SetAlpha(square and 1 or 0) end
    end
    for _, part in ipairs({ f.bg, f.qualityStrip, f.bevel }) do
        if part then part:SetShown(square) end
    end
    if art then
        f.icon:Hide()
        if f.iLvlBg then f.iLvlBg:Hide() end
    end

    p.discShadow:SetShown(art ~= nil)
    p.fill:SetShown(art ~= nil)
    p.ring:SetShown(art ~= nil)
    p.roundIcon:SetShown(art ~= nil)
    p.inner:SetShown(art ~= nil and art.inner ~= nil)
    if art then
        p.fill:SetTexture(S.Media(art.fill))
        p.fill:SetSize(art.size, art.size)
        p.ring:SetTexture(S.Media(art.ring))
        p.ring:SetSize(art.ringSize or art.size, art.ringSize or art.size)
        if art.inner then
            p.inner:SetTexture(S.Media(art.inner))
            p.inner:SetSize(art.size, art.size)
            p.inner:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
        end
        p.roundIcon:SetSize(art.icon, art.icon)
        p.roundIcon:ClearAllPoints()
        p.roundIcon:SetPoint("CENTER", v, "CENTER", 0, art.iconY or 0)
    end
    p.classicFrame:SetShown(shape == "classic")
    p.classicQuality:Hide()
    PlaceTrail(f, art ~= nil)

    local h = f.highlight
    if h then
        h:ClearAllPoints()
        h:SetPoint("CENTER", f, "CENTER", 0, 0)
        h:SetBlendMode(square and "BLEND" or "ADD")
        if art then
            h:SetSize(art.size, art.size)
            h:SetTexture(S.Media(art.inner or art.fill))
            h:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], art.inner and 0.5 or 0.2)
        elseif shape == "classic" then
            h:SetSize(48, 48)
            h:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            h:SetVertexColor(1, 1, 1, 1)
        else
            h:SetSize(SLOT_SIZE, SLOT_SIZE)
            h:SetTexture("Interface\\Buttons\\WHITE8x8")
            h:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.15)
        end
    end
end

function NarciUI:PaintSlotShape(f, path, alpha, r, g, b)
    local p = f.shape
    if not p or f.shapeKey == "square" then return end
    local S = NS.Styling
    local shape = f.shapeKey
    local art = SHAPE_ART[shape]

    f.bg:Hide()
    f.qualityStrip:Hide()
    if f.bevel then f.bevel:Hide() end

    if r and NS.db and NS.db.slotRingColor == "accent" then
        r, g, b = S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
    end

    if art then
        f.icon:Hide()
        if f.iLvlBg then f.iLvlBg:Hide() end
        if path ~= f.shapePath then
            f.shapePath = path
            if path then
                SetPortraitToTexture(p.roundIcon, path)
            else
                p.roundIcon:SetTexture(nil)
            end
        end
        p.roundIcon:SetVertexColor(1, 1, 1, alpha)
        p.fill:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.95)
        if r then
            p.ring:SetVertexColor(r, g, b, 1)
        else
            p.ring:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.7)
        end
    elseif shape == "classic" then
        if r then
            p.classicQuality:SetVertexColor(r, g, b, 0.75)
            p.classicQuality:Show()
        else
            p.classicQuality:Hide()
        end
    end
end

local function RiseIn(frame, dy, duration)
    if not frame then return end
    if not frame._riseAnchor then
        local p, r, rp, ax, ay = frame:GetPoint(1)
        if not p then
            frame:SetAlpha(1)
            return
        end
        frame._riseAnchor = { p, r, rp, ax, ay }
    end
    local point, rel, relPoint, x, y =
        frame._riseAnchor[1], frame._riseAnchor[2], frame._riseAnchor[3],
        frame._riseAnchor[4], frame._riseAnchor[5]
    duration = duration or 0.25

    local elapsed = 0
    frame:SetAlpha(0)
    frame:ClearAllPoints()
    frame:SetPoint(point, rel, relPoint, x, y - dy)

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            self:SetAlpha(1)
            self:ClearAllPoints()
            self:SetPoint(point, rel, relPoint, x, y)
        else
            local ease = 1 - (1 - t) ^ 3
            self:SetAlpha(ease)
            self:ClearAllPoints()
            self:SetPoint(point, rel, relPoint, x, y - dy * (1 - ease))
        end
    end)
end

local INDICATOR_ANIM = 0.20

local function MoveIndicator(indicator, targetX)
    local startX = indicator._x
    if not indicator:IsShown() or not startX then startX = targetX end
    indicator._x = targetX

    local parent = indicator:GetParent()
    local elapsed = 0
    indicator:Show()

    if not NS.Styling.AnimationsEnabled() then
        indicator:SetScript("OnUpdate", nil)
        indicator:ClearAllPoints()
        indicator:SetPoint("BOTTOM", parent, "BOTTOM", targetX, TOOLBAR_INDICATOR_Y)
        indicator:SetAlpha(1)
        return
    end

    indicator:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / INDICATOR_ANIM
        if t >= 1 then
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", parent, "BOTTOM", targetX, TOOLBAR_INDICATOR_Y)
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        else
            local ease = 1 - (1 - t) ^ 3
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", parent, "BOTTOM", startX + (targetX - startX) * ease, TOOLBAR_INDICATOR_Y)
            self:SetAlpha(0.35 + 0.65 * ease)
        end
    end)
end

local function FadeOutIndicator(indicator)
    if not indicator:IsShown() then return end
    local startAlpha = indicator:GetAlpha()
    local elapsed = 0
    indicator:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / (INDICATOR_ANIM * 0.7)
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetAlpha(1)
            self._x = nil
        else
            self:SetAlpha(startAlpha * (1 - t))
        end
    end)
end

function NarciUI:UpdateToolbarState(activeName)
    local mf = self.mainFrame
    if not mf or not mf.toolbarButtons then return end

    local activeX, activeLabel
    for _, btn in ipairs(mf.toolbarButtons) do
        local active
        if activeName then
            active = (btn.panelName == activeName)
        else
            local panel = btn.panelName and NS[btn.panelName]
            active = panel and panel.frame and panel.frame:IsShown()
        end
        local S = NS.Styling
        if active then
            activeX = btn.toolbarX
            activeLabel = btn.label
            btn.activeGlow:Show()
            btn.icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
            if btn.ring then btn.ring:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1) end
        else
            btn.activeGlow:Hide()
            btn.icon:SetVertexColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 0.85)
            if btn.ring then btn.ring:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55) end
        end
    end

    if mf.toolbarCaption then
        local S = NS.Styling
        mf.toolbarCaption:SetText(activeLabel or "")
        mf.toolbarCaption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if mf.toolbarIndicator then
        if activeX then
            MoveIndicator(mf.toolbarIndicator, activeX)
        else
            FadeOutIndicator(mf.toolbarIndicator)
        end
    end
end

function NarciUI:UpdateSlots()
    if not self.mainFrame then return end
    local S = NS.Styling

    local db = NS.db or {}
    local showILvl = db.showItemLevel ~= false
    local showEnchant = db.showEnchantInfo ~= false
    local showGems = db.showGemInfo ~= false
    local showNames = db.showItemNames ~= false
    local hideEmpty = db.hideEmptySlots == true
    local nameLength = db.nameLength or SLOT_NAME_MAX_CHARS
    local plateOn = db.slotNamePlate ~= false
    local plateAlpha = (db.slotPlateAlpha or 75) / 100
    local trailOn = db.slotTrail ~= false
    local trailAlpha = (db.slotTrailAlpha or 40) / 100
    local emptyAlpha = (db.emptySlotAlpha or 75) / 100
    local nameSize = db.slotNameSize or 13

    for slotId, slotFrame in pairs(self.mainFrame.slotFrames) do
        local link = GetInventoryItemLink("player", slotId)
        self:ShapeSlot(slotFrame)

        slotFrame._hiddenEmpty = (hideEmpty and not link) or nil
        local wantShown = not (slotFrame._hiddenEmpty or self.sceneHidden)
        local visual = slotFrame.visual
        if visual then
            if wantShown then visual:Show() else visual:Hide() end
        end
        if wantShown ~= slotFrame:IsShown() then
            if CanTouchSecure() then
                if wantShown then slotFrame:Show() else slotFrame:Hide() end
            else
                self._slotsPending = true
            end
        end

        if link then
            local name, _, quality, itemLevel, _, _, _, _, _, texture = GetItemInfo(link)
            local r, g, b = NS.GetQualityColor(quality)
            slotFrame.icon:SetTexture(texture)
            slotFrame.icon:SetVertexColor(1, 1, 1, 1)
            slotFrame.icon:Show()
            slotFrame.border:SetBackdropBorderColor(r, g, b, 0.9)
            slotFrame.qualityStrip:SetVertexColor(r, g, b, 0.85)
            if slotFrame.qualityGlow then
                slotFrame.qualityGlow:SetShown(trailOn and trailAlpha > 0)
                local shapeKey = slotFrame.shapeKey
                local boost = self:RoundShape(shapeKey) and 1.35 or 1
                slotFrame.qualityGlow:SetVertexColor(r, g, b, math.min(1, trailAlpha * boost))
            end
            if showILvl and itemLevel and itemLevel > 0 then
                slotFrame.iLvlText:SetText(itemLevel)
                local ilR, ilG, ilB = S.GetILvlColor(itemLevel)
                slotFrame.iLvlText:SetTextColor(ilR, ilG, ilB)
                slotFrame.iLvlText:Show()
                slotFrame.iLvlBg:Show()
            else
                slotFrame.iLvlText:Hide()
                slotFrame.iLvlBg:Hide()
            end
            if slotFrame.nameLabel then
                if slotFrame.nameSize ~= nameSize then
                    slotFrame.nameSize = nameSize
                    slotFrame.nameLabel:SetFont(NS.FONT, NS.FS(nameSize), "OUTLINE")
                end
                if showNames and name then
                    slotFrame.nameLabel:SetText(NS.TruncateText(name, nameLength))
                    slotFrame.nameLabel:SetTextColor(r, g, b)
                    slotFrame.nameColor = { r, g, b }
                else
                    slotFrame.nameLabel:SetText("")
                end
                if slotFrame.namePlate then
                    for i = 1, #slotFrame.namePlate do
                        slotFrame.namePlate[i]:SetVertexColor(0, 0, 0, plateAlpha)
                        if showNames and name and plateOn and plateAlpha > 0 then
                            slotFrame.namePlate[i]:Show()
                        else
                            slotFrame.namePlate[i]:Hide()
                        end
                    end
                end
            end
            if not showEnchant then
                S.SetEnchantDotStatus(slotFrame.enchantDot, "none")
            elseif NS.ENCHANTABLE_SLOTS and NS.ENCHANTABLE_SLOTS[slotId] then
                S.SetEnchantDotStatus(slotFrame.enchantDot,
                    NS.GetEnchantInfo(link) and "enchanted" or "missing")
            else
                S.SetEnchantDotStatus(slotFrame.enchantDot, "none")
            end
            local totalSockets = 0
            if showGems and NS.TooltipScanner then
                totalSockets = NS.TooltipScanner:GetSocketCountFromTextures(link)
            end
            local gems = totalSockets > 0 and NS.GetGemInfo(link) or nil
            for i = 1, 4 do
                if i <= totalSockets and slotFrame.gemIcons[i] then
                    local btn = slotFrame.gemIcons[i]
                    btn:Show()
                    btn:EnableMouse(true)
                    if gems[i] and gems[i].texture then
                        btn.texture:SetTexture(gems[i].texture)
                        btn.texture:SetVertexColor(1, 1, 1, 1)
                        btn.gemLink = gems[i].link
                    else
                        local socketTex = NS.TooltipScanner
                            and NS.TooltipScanner:GetSocketTexture(link, i)
                        btn.texture:SetTexture(socketTex or "Interface\\ItemSocketingFrame\\UI-EmptySocket")
                        btn.texture:SetVertexColor(1, 1, 1, 0.95)
                        btn.gemLink = nil
                    end
                elseif slotFrame.gemIcons[i] then
                    slotFrame.gemIcons[i]:Hide()
                    slotFrame.gemIcons[i]:EnableMouse(false)
                    slotFrame.gemIcons[i].gemLink = nil
                end
            end
            slotFrame.bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.75)
            self:PaintSlotShape(slotFrame, texture or GetInventoryItemTexture("player", slotId), 1, r, g, b)
        else
            if slotFrame.emptyTexture then
                slotFrame.icon:SetTexture(slotFrame.emptyTexture)
                slotFrame.icon:SetVertexColor(1, 1, 1, emptyAlpha)
                slotFrame.icon:Show()
            else
                slotFrame.icon:SetTexture(nil)
            end
            slotFrame.iLvlText:Hide(); slotFrame.iLvlBg:Hide()
            if slotFrame.nameLabel then slotFrame.nameLabel:SetText("") end
            if slotFrame.namePlate then
                for i = 1, #slotFrame.namePlate do slotFrame.namePlate[i]:Hide() end
            end
            if slotFrame.qualityGlow then slotFrame.qualityGlow:Hide() end
            for i = 1, 4 do if slotFrame.gemIcons[i] then slotFrame.gemIcons[i]:Hide(); slotFrame.gemIcons[i]:EnableMouse(false); slotFrame.gemIcons[i].gemLink = nil end end
            slotFrame.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.4)
            slotFrame.qualityStrip:SetVertexColor(0.2, 0.2, 0.25, 0.3)
            slotFrame.bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)
            self:PaintSlotShape(slotFrame, slotFrame.emptyTexture, emptyAlpha)
        end
    end
end

function NarciUI:UpdateMotto()
    local mf = self.mainFrame
    if not mf or not mf.motto then return end
    local S = NS.Styling
    local text = S.BrandMotto()
    if text and S.Brand().mottoChar ~= false then
        local _, _, _, r, g, b = S.BrandColor()
        mf.motto:SetText("\"" .. text .. "\"")
        mf.motto:SetTextColor(r, g, b, 0.9)
        mf.motto:Show()
    else
        mf.motto:Hide()
    end
end

function NarciUI:UpdatePlayerInfo()
    if not self.mainFrame then return end
    self:UpdateMotto()
    local mf = self.mainFrame
    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        mf.playerName:SetText(format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name))
    else
        mf.playerName:SetText(name or "")
    end
    NS.Styling.SetClassIcon(mf.classIcon, class)
    local level = UnitLevel("player")
    local race = UnitRace("player")
    local _, localizedClass = UnitClass("player")
    mf.playerDetails:SetText(format("%s |cff00ccff%d|r %s %s", "", level, race, localizedClass))
    local avg = NS.GetAverageItemLevel()
    mf.iLvlValue:SetText(format("%.1f", avg))
    mf.iLvlValue:SetTextColor(NS.Styling.GetILvlColor(avg))

    if mf.specLine then
        local text = ""
        if NS.StatPriority then
            local ok, _, info = pcall(NS.StatPriority.Get, NS.StatPriority)
            if ok and info then
                local A = NS.Styling.ACCENT_GLOW
                local G = NS.Styling.GOLD_DIM
                if info.specName then
                    text = format("|cff%02x%02x%02x%s|r",
                        A[1] * 255, A[2] * 255, A[3] * 255, info.specName)
                end
                if info.tier then
                    local okt, tierText = pcall(NS.StatPriority.GetTierLabel, NS.StatPriority, info)
                    if okt then
                        if text ~= "" then text = text .. "   " end
                        text = text .. format(L["|cff%02x%02x%02xнабор %s|r"],
                            G[1] * 255, G[2] * 255, G[3] * 255, tierText)
                    end
                end
            end
        end
        mf.specLine:SetText(text)
    end
end

function NarciUI:RefreshModel()
    local mf = self.mainFrame
    local model = mf and mf.model
    if not model then return end

    local facing = model:GetFacing()
    local scale = model:GetModelScale()

    model:SetUnit("player")
    pcall(model.RefreshUnit, model)
    pcall(model.SetPortraitZoom, model, 0.85)
    pcall(model.SetCamDistanceScale, model, 0.9)
    self:PlaceModel()

    if facing then model:SetFacing(facing) end
    if scale and scale > 0 then model:SetModelScale(scale) end
end

function NarciUI:PlayIntroSweep()
    local sweep = self.mainFrame and self.mainFrame.introSweep
    if not sweep then return end
    sweep:SetScript("OnUpdate", nil)
    if not NS.Styling.AnimationsEnabled() then
        sweep:Hide()
        return
    end

    local half = (sweep:GetWidth() or 1920) / 2 - 40
    if half < 10 then half = 10 end
    local grow, fade = 0.26, 0.30
    local elapsed = 0

    sweep.left:SetWidth(1)
    sweep.right:SetWidth(1)
    sweep:SetAlpha(1)
    sweep:Show()
    sweep:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + (e or 0)
        if elapsed <= grow then
            local w = max(1, half * (1 - (1 - elapsed / grow) ^ 3))
            self.left:SetWidth(w)
            self.right:SetWidth(w)
        elseif elapsed <= grow + fade then
            self.left:SetWidth(half)
            self.right:SetWidth(half)
            self:SetAlpha(1 - (elapsed - grow) / fade)
        else
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
end

function NarciUI:PlayModelIntro()
    local model = self.mainFrame and self.mainFrame.model
    if not model then return end
    if not NS.Styling.AnimationsEnabled() then
        model.intro = nil
        return
    end

    local toScale = model:GetModelScale() or 1
    if not toScale or toScale <= 0 then toScale = 1 end
    local toFacing = model:GetFacing() or 0.4

    model.intro = {
        elapsed = 0, duration = 0.55,
        fromFacing = toFacing + 0.6, toFacing = toFacing,
        fromScale = toScale * 0.90,  toScale = toScale,
    }
    model:SetFacing(model.intro.fromFacing)
    model:SetModelScale(model.intro.fromScale)
end

function NarciUI:Show(requestedPanel)
    local combat = InCombatLockdown()
    if combat and not (NS.db and NS.db.showInCombat) then
        NS.Print(L["в бою окно не открывается, это включается в настройках"])
        return
    end
    if not self.mainFrame then self:Create() end
    self.sceneHidden = nil
    self:ApplyScale()
    self:UpdateSlots(); self:UpdatePlayerInfo()
    self.mainFrame.model:SetUnit("player")
    local remember = NS.db and NS.db.rememberModelView
    self.mainFrame.model:SetFacing(remember and NS.db.modelFacing or 0.4)
    if remember and NS.db.modelScale and NS.db.modelScale > 0 then
        pcall(self.mainFrame.model.SetModelScale, self.mainFrame.model, NS.db.modelScale)
    end
    self.mainFrame.model.panY = remember and NS.db.modelPanY or 0
    self.mainFrame.model.panZ = remember and NS.db.modelPanZ or 0
    pcall(function() self.mainFrame.model:RefreshUnit() end)
    self:PlaceModel()
    self:ApplyPose()
    self:ApplyScene()
    local mf = self.mainFrame
    if combat and not CanTouchProtected(mf) then
        NS.Print(L["в бою это окно открыть нельзя"])
        return
    end
    local animate = NS.Styling.AnimationsEnabled() and not combat
    if combat then self._slotsPending = true end

    self._showToken = (self._showToken or 0) + 1
    local token = self._showToken

    mf:SetAlpha(0)
    if not mf:IsShown() then
        mf:Show()
        if not mf:IsShown() then
            NS.Print(L["в бою это окно открыть нельзя"])
            return
        end
    end
    self._hiddenInCombat = nil
    NS.Styling.FadeIn(mf, 0.35)
    self:PlayIntroSweep()
    self:PlayModelIntro()

    if self.edgeVignette then
        if animate then
            NS.Styling.FadeIn(self.edgeVignette, 0.3)
        else
            self.edgeVignette:SetAlpha(1)
            self.edgeVignette:Show()
        end
    end

    local order = self._slotLayout or {}
    for i = 1, #order do
        local info = order[i]
        local slotFrame = mf.slotFrames[info.id]
        if slotFrame and not slotFrame._hiddenEmpty then
            local visual = slotFrame.visual
            if animate and visual then
                local row = (info.side == "BOTTOM") and (NUM_SIDE_SLOTS + 1)
                            or ((i - 1) % NUM_SIDE_SLOTS) + 1
                visual:SetAlpha(0)
                NS.After(0.14 + (row - 1) * 0.035, function()
                    if self._showToken ~= token then return end
                    if not slotFrame._hiddenEmpty and not self.sceneHidden then
                        NS.Styling.FadeIn(visual, 0.25)
                    end
                end)
            elseif visual and not self.sceneHidden then
                visual:SetAlpha(1)
                visual:Show()
            end

            if CanTouchSecure() then
                slotFrame:SetAlpha(1)
                slotFrame:Show()
            else
                self._slotsPending = true
            end
        end
    end

    if mf.toolbar then
        mf.toolbar:Show()
        if animate then
            mf.toolbar:SetAlpha(0)
            NS.After(0.30, function()
                if self._showToken ~= token then return end
                RiseIn(mf.toolbar, 20, 0.28)
            end)
        else
            mf.toolbar:SetAlpha(1)
        end
    end
    self.isShown = true
    self:UpdateToolbarState()
    if NS.EquipInfo then NS.EquipInfo:Show() end

    local openPanel = requestedPanel or (NS.db and NS.db.openPanel)
    if openPanel and openPanel ~= "none" then
        local panel = NS[openPanel]
        if panel and not (panel.frame and panel.frame:IsShown()) then
            NS:TogglePanelByName(openPanel)
        end
    end
    self:RaiseBags()
    if self._bagWatcher then self._bagWatcher:Show() end
    self:HideOtherAddons()

    NS.After(0.3, function()
        if NarciUI.isShown then NarciUI:HideOtherAddons() end
    end)
    NS.After(1, function()
        if NarciUI.isShown then NarciUI:HideOtherAddons() end
    end)
end

local function Unpack(out, ...)
    local n = select("#", ...)
    for i = 1, n do out[i] = select(i, ...) end
    for i = n + 1, #out do out[i] = nil end
    return n
end

local childScratch = {}
local kidScratch = {}

local function HasAdiBagsChild(frame)
    local n = Unpack(kidScratch, frame:GetChildren())
    for i = 1, n do
        local kid = kidScratch[i]
        local name = kid and kid:GetName()
        if name and name:find("AdiBags") then return true end
    end
    return false
end

local BAG_TARGET_LEVEL = 300
local BAG_TARGET_STRATA = "FULLSCREEN_DIALOG"

local TOP_FRAME_NAMES = { "TradeSkillFrame", "CraftFrame" }

local RAISE_FRAME_NAMES = { "ItemSocketingFrame", "GearManagerDialog", "GearManagerDialogPopup" }

local BAG_NAME_PATTERNS = {
    "^ContainerFrame%d", "^NarciSirus_BagWindow$", "^NarciSirus_BankWindow$", "AdiBags", "Bagnon", "ArkInventory",
    "Baggins", "OneBag", "Combuctor",
}

local function IsBagFrame(frame)
    local name = frame:GetName()
    if name then
        for _, p in ipairs(BAG_NAME_PATTERNS) do
            if name:find(p) then return true end
        end
        return false
    end
    return HasAdiBagsChild(frame)
end

local function RaiseTree(frame, strata, delta, store, depth)
    if not frame or not frame.GetFrameLevel or depth > 6 then return end
    local saved = store[frame]
    if not saved then
        saved = { frame:GetFrameStrata(), frame:GetFrameLevel() }
        store[frame] = saved
    end
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(saved[2] + delta)
    local kids = { frame:GetChildren() }
    for i = 1, #kids do
        RaiseTree(kids[i], strata, delta, store, depth + 1)
    end
end

local CRAFT_GAP     = 16
local CRAFT_TOP_GAP = 8

local function CraftParkY(frame, scale)
    local weaponTop = (BOTTOM_Y + 15 + SLOT_SIZE / 2) * scale
    local height = frame:GetHeight() or 496
    local y = weaponTop + CRAFT_GAP + height / 2

    local maxY = (UIParent:GetHeight() or 768) / 2
                 - TOP_BAR_HEIGHT * scale - CRAFT_TOP_GAP - height / 2
    if y > maxY then y = maxY end
    return y
end

function NarciUI:ParkTopFrame(frame)
    if not frame or not frame.ClearAllPoints then return end

    local moved = self._movedFrames
    if not moved then
        moved = {}
        self._movedFrames = moved
    end
    if moved[frame] == nil then
        local point, rel, relPoint, x, y = frame:GetPoint(1)
        moved[frame] = point and { point, rel, relPoint, x, y } or false
    end

    local scale = self._appliedScale or 1
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", MODEL_X * scale, CraftParkY(frame, scale))
end

function NarciUI:KeepTopFramesParked()
    if not self.isShown then return end
    local scale = self._appliedScale or 1
    local wantX = MODEL_X * scale
    for i = 1, #TOP_FRAME_NAMES do
        local frame = _G[TOP_FRAME_NAMES[i]]
        if frame and frame.IsShown and frame:IsShown() then
            local point, _, _, x, y = frame:GetPoint(1)
            if point ~= "CENTER" or x ~= wantX or y ~= CraftParkY(frame, scale) then
                self:ParkTopFrame(frame)
            end
        end
    end
end

local hookedBags = {}

local function HookBagFrame(frame)
    if hookedBags[frame] or not frame.HookScript then return end
    hookedBags[frame] = true
    frame:HookScript("OnShow", function()
        if not NarciUI.isShown then return end
        NS.After(0, function() NarciUI:RaiseBags() end)
    end)
end

local function Raise(frame, raised)
    if not frame or not frame.GetFrameLevel then return end
    HookBagFrame(frame)
    local saved = raised[frame]
    if saved and frame:GetFrameStrata() == BAG_TARGET_STRATA
       and frame:GetFrameLevel() == BAG_TARGET_LEVEL then
        return
    end
    local base = saved and saved[2] or frame:GetFrameLevel()
    RaiseTree(frame, BAG_TARGET_STRATA, BAG_TARGET_LEVEL - base, raised, 1)
end

local CONTAINER_NAMES = {}
for i = 1, 13 do CONTAINER_NAMES[i] = "ContainerFrame" .. i end

function NarciUI:RaiseBags()
    if not self.isShown then return end
    local raised = self._raisedBags
    if not raised then
        raised = {}
        self._raisedBags = raised
    end

    for i = 1, 13 do
        local cf = _G[CONTAINER_NAMES[i]]
        if cf and cf:IsShown() then Raise(cf, raised) end
    end

    for i = 1, #TOP_FRAME_NAMES do
        local frame = _G[TOP_FRAME_NAMES[i]]
        if frame and frame.IsShown and frame:IsShown() then Raise(frame, raised) end
    end
    for i = 1, #RAISE_FRAME_NAMES do
        local frame = _G[RAISE_FRAME_NAMES[i]]
        if frame and frame.IsShown and frame:IsShown() then Raise(frame, raised) end
    end
    self:KeepTopFramesParked()

    local n = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, n do
        local child = childScratch[i]
        if child and child:IsShown() and IsBagFrame(child) then
            Raise(child, raised)
        end
    end
end

local BAG_WATCH_INTERVAL = 0.3
do
    local bagWatcher = CreateFrame("Frame")
    bagWatcher:Hide()
    local elapsed = 0
    bagWatcher:SetScript("OnUpdate", function(self, e)
        NarciUI:KeepTopFramesParked()

        elapsed = elapsed + e
        if elapsed < BAG_WATCH_INTERVAL then return end
        elapsed = 0
        NarciUI:RaiseBags()
    end)
    NarciUI._bagWatcher = bagWatcher
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("UI_SCALE_CHANGED")
    watcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if NarciUI._scalePending then NarciUI:ApplyScale() end
            if NarciUI._hidePending then
                NarciUI._hidePending = nil
                NarciUI:Hide()
            end
            if NarciUI._hiddenInCombat and not NarciUI.isShown then
                NarciUI._hiddenInCombat = nil
                if NarciUI.mainFrame then NarciUI.mainFrame:Hide() end
            end
            if NarciUI._hidePassPending then
                NarciUI._hidePassPending = nil
                NarciUI:RestoreFadedFrames()
                if NarciUI.isShown then NarciUI:HideOtherAddons() end
            end
            if NarciUI._slotsDeferred then
                NarciUI:BuildSlotFrames()
                NarciUI:ApplyScale()
                NarciUI._slotsPending = true
            end
            if NarciUI._slotsPending then
                NarciUI._slotsPending = nil
                if NarciUI.isShown then
                    NarciUI:UpdateSlots()
                elseif NarciUI.mainFrame and NarciUI.mainFrame.slotFrames then
                    for _, sf in pairs(NarciUI.mainFrame.slotFrames) do sf:Hide() end
                end
            end
            if NarciUI._hiddenFrames and not NarciUI.isShown then
                NarciUI:RestoreOtherAddons()
            end
        elseif NarciUI.mainFrame then
            NarciUI:ApplyScale()
        end
    end)
end

function NarciUI:PrintBagDiagnostics()
    NS.Print(L["окно открыто: "] .. tostring(self.isShown and true or false))
    local n = 0
    local count = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, count do
        local child = childScratch[i]
        if child and child:IsShown() and IsBagFrame(child) then
            n = n + 1
            NS.Print(format("  %s | %s | %d%s",
                child:GetName() or L["<без имени>"],
                child:GetFrameStrata(), child:GetFrameLevel(),
                (self._raisedBags and self._raisedBags[child]) and L[" | поднят"] or ""))
        end
    end
    if n == 0 then NS.Print(L["  видимых фреймов сумок не найдено"]) end

    for i = 1, #RAISE_FRAME_NAMES do
        local frame = _G[RAISE_FRAME_NAMES[i]]
        if frame and frame.GetFrameStrata then
            NS.Print(format("  %s | %s | %d | %s",
                RAISE_FRAME_NAMES[i], frame:GetFrameStrata(), frame:GetFrameLevel(),
                frame:IsShown() and L["открыт"] or L["закрыт"]))
        end
    end
end

function NarciUI:RestoreBags()
    if not self._raisedBags then return end
    for frame, saved in pairs(self._raisedBags) do
        if frame and frame.SetFrameStrata then
            frame:SetFrameStrata(saved[1])
            frame:SetFrameLevel(saved[2])
        end
    end
    self._raisedBags = nil

    if self._movedFrames then
        for frame, saved in pairs(self._movedFrames) do
            if saved and frame and frame.ClearAllPoints then
                frame:ClearAllPoints()
                frame:SetPoint(saved[1], saved[2] or frame:GetParent() or UIParent,
                               saved[3], saved[4], saved[5])
            end
        end
        self._movedFrames = nil
    end
end

if type(ShowUIPanel) == "function" then
    hooksecurefunc("ShowUIPanel", function(frame)
        if not NarciUI.isShown or not frame or not frame.GetName then return end
        local name = frame:GetName()
        if not name then return end
        for i = 1, #TOP_FRAME_NAMES do
            if name == TOP_FRAME_NAMES[i] then
                NS.After(0, function() NarciUI:RaiseBags() end)
                return
            end
        end
        for i = 1, #RAISE_FRAME_NAMES do
            if name == RAISE_FRAME_NAMES[i] then
                NS.After(0, function() NarciUI:RaiseBags() end)
                return
            end
        end
    end)
end

do
    local panelWatcher = CreateFrame("Frame")
    panelWatcher:RegisterEvent("SOCKET_INFO_UPDATE")
    panelWatcher:SetScript("OnEvent", function()
        if not NarciUI.isShown then return end
        NarciUI:RaiseBags()
        NS.After(0.1, function() NarciUI:RaiseBags() end)
    end)

    for i = 1, #RAISE_FRAME_NAMES do
        local frame = _G[RAISE_FRAME_NAMES[i]]
        if frame and frame.HookScript then
            frame:HookScript("OnShow", function()
                if not NarciUI.isShown then return end
                NarciUI:RaiseBags()
                NS.After(0.1, function() NarciUI:RaiseBags() end)
            end)
        end
    end
end

for _, fname in ipairs({ "ToggleBackpack", "OpenBackpack", "ToggleBag", "OpenBag", "OpenAllBags" }) do
    if type(_G[fname]) == "function" then
        hooksecurefunc(fname, function()
            if not NarciUI.isShown then return end
            NS.After(0, function() NarciUI:RaiseBags() end)
        end)
    end
end

local HIDE_WHITELIST = {
    "^NarcissusSirus", "^NarciSirus",
    "^MiniMap", "^Minimap",
    "^UIParent", "^WorldFrame",
    "^StaticPopup", "^GameTooltip",
    "^TokenFrame", "^FriendsFrame",
    "^GossipFrame", "^QuestFrame",
    "^MerchantFrame", "^TradeFrame",
    "^TradeSkillFrame", "^CraftFrame",
    "^BankFrame", "^Backpack",
    "^ContainerFrame", "^MailFrame",
    "^CharacterFrame", "^InspectFrame",
    "^PVPFrame", "^LootFrame",
    "^TicketStatus",
    "^MinimapCluster", "^GameTimeFrame",
    "^MiniMapBattlefield", "^MiniMapWorldMap",
    "^MiniMapMailFrame", "^MiniMapLFG",
    "^MiniMapMeetingStone", "^MiniMapBGFrame",
    "^MiniMapInstance", "^QueueStatus",
    "^HelpFrame", "^ScreenshotOption",
    "^ItemSocketing", "^GearManager",
    "^TalentFrame", "^SpellBook",
    "^SkillFrame", "^PVPReady",
    "^WorldStateScore", "^ArenaEnemy",
    "^CompactRaidFrame", "^RaidWarningFrame",
    "^BossEmote", "^ErrorsFrame",
    "^UIErrorsFrame", "^Sound",
    "^KeyBinding", "^MacroFrame",
    "^VideoOptions", "^InterfaceOptions",
    "^StoreFrame", "^HelpOpen",
    "^AutoComplete", "^DropDownList",
    "^ColorPicker", "^OpenMail", "^SendMail",
    "AdiBags", "^Bagnon", "^StackSplitFrame",
}

local STOCK_UI_WHITELIST = {
    "^ChatFrame", "^MainMenuBar", "^MultiBar",
    "^PetAction", "^Possess", "^Vehicle",
    "^CastingBar", "^BuffFrame", "^TemporaryEnchant",
    "^WatchFrame", "^ObjectiveTracker",
    "^DurabilityFrame", "^DPMInfo", "^Damage",
}

local HUD_FRAMES = {
    "^NarciSirus_DataTexts", "^NarciSirus_CooldownBar", "^NarciSirus_MicroBar",
    "^NarciSirus_Cast_", "^NarciSirus_ChatInput", "^NarciSirus_BarPanel",
    "^NarciSirus_RaidHolder",
}

local MINIMAP_FRAMES = { "^NarciSirus_Minimap" }

local DETACHED_FRAMES = { "ObjectiveTrackerFrame", "WatchFrame" }

local function ShouldHideFrame(name)
    for _, pattern in ipairs(MINIMAP_FRAMES) do
        if name:find(pattern) then return true end
    end
    for _, pattern in ipairs(HUD_FRAMES) do
        if name:find(pattern) then return NS.db and NS.db.hideBlizzardUI and true or false end
    end
    for _, pattern in ipairs(HIDE_WHITELIST) do
        if name:find(pattern) then return false end
    end
    if not (NS.db and NS.db.hideBlizzardUI) then
        for _, pattern in ipairs(STOCK_UI_WHITELIST) do
            if name:find(pattern) then return false end
        end
    end
    return true
end

local NAME_CVARS = {
    "UnitNameOwn", "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName",
    "UnitNameFriendlyPetName", "UnitNameEnemyPetName",
}

local function SaveNames()
    if not NS.db or NS.db.savedNameCVars then return end
    local saved = {}
    for _, cvar in ipairs(NAME_CVARS) do saved[cvar] = GetCVar(cvar) or "1" end
    NS.db.savedNameCVars = saved
end

local function RestoreNames()
    local saved = NS.db and NS.db.savedNameCVars
    for _, cvar in ipairs(NAME_CVARS) do
        SetCVar(cvar, saved and saved[cvar] or "1")
    end
    if NS.db then NS.db.savedNameCVars = nil end
end

function NarciUI:RepairNames()
    if not NS.db then return end

    if NS.db.savedNameCVars then
        RestoreNames()
    elseif not NS.db.nameCVarsRepaired then
        local allOff = true
        for _, cvar in ipairs(NAME_CVARS) do
            if GetCVar(cvar) ~= "0" then allOff = false end
        end
        if allOff then RestoreNames() end
    end

    NS.db.nameCVarsRepaired = true
end

function NarciUI:ReapplyHidden()
    local mf = self.mainFrame
    if not self._hideActive or not mf or not mf:IsShown() or not self._hiddenFrames then return end
    for frame in pairs(self._hiddenFrames) do
        if frame and frame.IsShown and frame:IsShown() and CanTouchProtected(frame) then
            frame:Hide()
        end
    end
end

function NarciUI:HideOtherAddons()
    if not self._hiddenFrames then self._hiddenFrames = {} end
    if not self._dockHooked and type(_G.FCF_DockUpdate) == "function" then
        self._dockHooked = true
        hooksecurefunc("FCF_DockUpdate", function()
            NarciUI:ReapplyHidden()
            if NS.After then NS.After(0, function() NarciUI:ReapplyHidden() end) end
        end)
    end
    if NS.db and NS.db.hideBlizzardUI then
        if NS.PlayerUI and NS.PlayerUI.Suspend then NS.PlayerUI:Suspend() end
        if NS.ActionBars and NS.ActionBars.Suspend then NS.ActionBars:Suspend() end
    end
    local mf = self.mainFrame
    local n = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, n do
        local child = childScratch[i]
        if child and child ~= mf and child:IsShown() then
            local name = child:GetName()
            if name == "" then name = nil end
            local hide = name and ShouldHideFrame(name) or (not name and not HasAdiBagsChild(child))
            if hide and not CanTouchProtected(child) then
                hide = false
                self._hidePassPending = true
                self._fadedFrames = self._fadedFrames or {}
                if self._fadedFrames[child] == nil then
                    self._fadedFrames[child] = child:GetAlpha() or 1
                end
                child:SetAlpha(0)
            end
            if hide then
                self._hiddenFrames[child] = true
                child:Hide()
            end
        end
    end
    for _, name in ipairs(DETACHED_FRAMES) do
        local frame = _G[name]
        if frame and frame.IsShown and frame:IsShown() and frame:GetParent() ~= UIParent
            and ShouldHideFrame(name) and CanTouchProtected(frame) then
            self._hiddenFrames[frame] = true
            frame:Hide()
        end
    end
    if CharacterFrame and CharacterFrame:IsShown() and not CanTouchProtected(CharacterFrame) then
        self._fadedFrames = self._fadedFrames or {}
        if self._fadedFrames[CharacterFrame] == nil then
            self._fadedFrames[CharacterFrame] = CharacterFrame:GetAlpha() or 1
        end
        CharacterFrame:SetAlpha(0)
        self._hidePassPending = true
    end

    if Minimap then
        if CanTouchProtected(Minimap) then Minimap:Hide() else Minimap:SetAlpha(0) end
    end
    if MinimapCluster then
        if CanTouchProtected(MinimapCluster) then MinimapCluster:Hide() else MinimapCluster:SetAlpha(0) end
    end
    SaveNames()
    for _, cvar in ipairs(NAME_CVARS) do SetCVar(cvar, "0") end
    self._hideActive = true
end

function NarciUI:RestoreFadedFrames()
    if not self._fadedFrames then return end
    for frame, alpha in pairs(self._fadedFrames) do
        if frame and frame.SetAlpha then frame:SetAlpha(alpha) end
    end
    self._fadedFrames = nil
    if Minimap then Minimap:SetAlpha(1) end
    if MinimapCluster then MinimapCluster:SetAlpha(1) end
end

function NarciUI:RestoreOtherAddons()
    self._hideActive = false
    self:RestoreFadedFrames()
    if NS.PlayerUI and NS.PlayerUI.Resume then NS.PlayerUI:Resume() end
    if NS.ActionBars and NS.ActionBars.Resume then NS.ActionBars:Resume() end
    if self._hiddenFrames then
        local pending
        for frame in pairs(self._hiddenFrames) do
            if frame and frame.Show then
                if not CanTouchProtected(frame) then
                    pending = pending or {}
                    pending[frame] = true
                else
                    frame:Show()
                end
            end
        end
        self._hiddenFrames = pending
    end
    if Minimap then Minimap:Show() end
    if MinimapCluster then MinimapCluster:Show() end
    RestoreNames()
end

function NarciUI:StopIntro()
    local mf = self.mainFrame
    if not mf then return end

    if mf.introSweep then
        mf.introSweep:SetScript("OnUpdate", nil)
        mf.introSweep:Hide()
    end

    if mf.model then
        local a = mf.model.intro
        if a then
            mf.model.intro = nil
            mf.model:SetFacing(a.toFacing)
            mf.model:SetModelScale(a.toScale)
        end
    end

    local tb = mf.toolbar
    if tb then
        tb:SetScript("OnUpdate", nil)
        local a = tb._riseAnchor
        if a then
            tb:ClearAllPoints()
            tb:SetPoint(a[1], a[2], a[3], a[4], a[5])
        end
        tb:SetAlpha(1)
    end
end

function NarciUI:Hide()
    if not self.mainFrame then return end
    if not CanTouchProtected(self.mainFrame) then
        self._hidePending = true
        return
    end
    self._hidePending = nil
    self.isShown = false

    if NS.db and NS.db.rememberModelView and self.mainFrame.model then
        local m = self.mainFrame.model
        NS.db.modelFacing = m:GetFacing()
        local ok, scale = pcall(m.GetModelScale, m)
        if ok and scale and scale > 0 then NS.db.modelScale = scale end
        NS.db.modelPanY, NS.db.modelPanZ = m.panY, m.panZ
    end

    self._showToken = (self._showToken or 0) + 1
    self:StopIntro()
    NS:HideAllPanels()
    if NS.SlotFlyout then NS.SlotFlyout:Hide() end
    if self.mainFrame.toolbar then self.mainFrame.toolbar:Hide() end
    if self.edgeVignette then self.edgeVignette:Hide() end
    if self.mainFrame and self.mainFrame.slotFrames then
        for _, sf in pairs(self.mainFrame.slotFrames) do
            sf:SetScript("OnUpdate", nil)
            if sf.visual then
                sf.visual:SetScript("OnUpdate", nil)
                sf.visual:Hide()
            end
            if CanTouchSecure() then
                sf:Hide()
            else
                self._slotsPending = true
            end
        end
    end
    if NS.EquipInfo then NS.EquipInfo:Hide() end
    if self._bagWatcher then self._bagWatcher:Hide() end
    self:RestoreBags()
    self:RestoreOtherAddons()
    if InCombatLockdown() then
        self.mainFrame:SetAlpha(0)
        self._hiddenInCombat = true
    else
        NS.Styling.FadeOut(self.mainFrame, 0.25, true)
    end
    self.isShown = false
end

function NarciUI:Toggle() if self.isShown then self:Hide() else self:Show() end end
