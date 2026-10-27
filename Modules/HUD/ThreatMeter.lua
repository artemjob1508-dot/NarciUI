local addonName, NS = ...
local L = NS.L

local Threat = {}
NS.ThreatMeter = Threat

local WHITE = "Interface\\Buttons\\WHITE8x8"
local SHADED = "Interface\\TargetingFrame\\UI-StatusBar"
local FLASH = "Interface\\FullScreenTextures\\LowHealth"

local CLASSIC_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local FLAT_BACKDROP = {
    bgFile = WHITE,
    edgeFile = WHITE,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local THICK_BACKDROP = {
    bgFile = WHITE,
    edgeFile = WHITE,
    edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local STYLES = { modern = true, classic = true, pixel = true, glass = true, neon = true, minimal = true, thick = true }

local CLASSES = {
    "DEATHKNIGHT", "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST",
    "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR", "PET", "NOTINPARTY",
}
Threat.CLASSES = CLASSES

Threat.SOUNDS = {
    { key = "felnova",   label = "Кольцо скверны", path = "Sound\\Spells\\SeepingGaseous_Fel_Nova.wav" },
    { key = "felportal", label = "Портал скверны", path = "Sound\\Spells\\Sunwell_Fel_PortalStand.wav" },
    { key = "explosion", label = "Взрыв",          path = "Sound\\Doodad\\Hellfire_Raid_FX_Explosion05.wav" },
    { key = "drums",     label = "Барабаны",       path = "Sound\\Event Sounds\\Event_wardrum_ogre.wav" },
    { key = "shing",     label = "Решётка",        path = "Sound\\Doodad\\PortcullisActive_Closed.wav" },
    { key = "wham",      label = "Ворота",         path = "Sound\\Doodad\\PVP_Lordaeron_Door_Open.wav" },
    { key = "chime",     label = "Колокольчик",    path = "Sound\\Doodad\\SimonGame_LargeBlueTree.wav" },
    { key = "humm",      label = "Гул",            path = "Sound\\Spells\\SimonGame_Visual_GameStart.wav" },
    { key = "circuit",   label = "Замыкание",      path = "Sound\\Spells\\SimonGame_Visual_BadPress.wav" },
    { key = "ducky",     label = "Утёнок",         path = "Sound\\Doodad\\Goblin_Lottery_Open01.wav" },
    { key = "cheer",     label = "Ликование",      path = "Sound\\Event Sounds\\OgreEventCheerUnique.wav" },
    { key = "cthun",     label = "Ты умрёшь!",     path = "Sound\\Creature\\CThun\\CThunYouWillDIe.wav" },
}

local DEFAULTS = {
    enabled = true,
    style = "modern",
    locked = false,
    width = 220,
    height = 140,
    scale = 100,
    alpha = 85,
    barHeight = 14,
    barSpacing = 1,
    fontSize = 10,
    numBars = 10,
    autoCollapse = false,
    collapseHide = false,
    showTitle = true,
    showHeadings = true,
    showTPS = true,
    tpsWindow = 10,
    showValue = true,
    showPercent = true,
    shortNumbers = true,
    classColors = true,
    animate = true,
    alwaysShowSelf = true,
    showAggroBar = true,
    useFocus = false,
    ignorePets = true,
    myColor = false,
    tankColor = false,
    clickThrough = false,
    show = {
        pet = true,
        alone = false,
        party = true,
        raid = true,
        hideResting = true,
        hidePvP = true,
        hideOOC = false,
    },
    warn = {
        sound = true,
        flash = true,
        shake = false,
        message = false,
        threshold = 90,
        soundKey = "felnova",
        notTanking = true,
    },
    classes = {
        DEATHKNIGHT = true, DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true,
        ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true, PET = true, NOTINPARTY = true,
    },
}

local function Fill(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Fill(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local filledFor

local function Settings()
    if not NS.db then return end
    if type(NS.db.threat) ~= "table" then NS.db.threat = {} end
    local db = NS.db.threat
    if db ~= filledFor then
        Fill(db, DEFAULTS)
        filledFor = db
    end
    return db
end
Threat.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

function Threat:OmenLoaded()
    return IsAddOnLoaded and IsAddOnLoaded("Omen") and true or false
end

local function StyleKey()
    local db = Settings()
    return db and STYLES[db.style] and db.style or "modern"
end

local function ClassColor(class)
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    return class and colors and colors[class]
end

local names = setmetatable({}, { __index = function() return L["<неизвестно>"] end })
local classes = {}
local bars = {}
local inParty, inRaid = false, false
local testMode = false
local manualToggle = false

local mdActors = {}
local mdActive = {}
local tempThreat = {}
local tempExpire = {}
local fadeThreat = {}

local threatTable
local sortTable = {}
local tankGUID
local topThreat
local lastWarn = { percent = 0 }
local threatStore = {}
local threatStoreTime = {}

local pID, ptID, ppID, pptID = {}, {}, {}, {}
local rID, rtID, rpID, rptID = {}, {}, {}, {}
for i = 1, 4 do
    pID[i] = "party" .. i
    ptID[i] = "party" .. i .. "target"
    ppID[i] = "partypet" .. i
    pptID[i] = "partypet" .. i .. "target"
end
for i = 1, 40 do
    rID[i] = "raid" .. i
    rtID[i] = "raid" .. i .. "target"
    rpID[i] = "raidpet" .. i
    rptID[i] = "raidpet" .. i .. "target"
end

local function Short(value)
    local db = Settings()
    if db.shortNumbers and value >= 100000 then
        return string.format("%.1fk", value / 100000)
    end
    return string.format("%d", value / 100)
end

function Threat:UpdatePartyGUIDs()
    wipe(classes)

    local me = UnitGUID("player")
    if me then
        names[me] = UnitName("player")
        classes[me] = select(2, UnitClass("player"))
    elseif NS.After then
        NS.After(0.5, function() Threat:UpdatePartyGUIDs() end)
    end

    if UnitExists("pet") then
        local pet = UnitGUID("pet")
        classes[pet] = "PET"
        names[pet] = UnitName("pet")
    end

    if inParty or inRaid then
        local players = inRaid and rID or pID
        local pets = inRaid and rpID or ppID
        local count = inRaid and GetNumRaidMembers() or GetNumPartyMembers()

        for i = 1, count do
            local guid = UnitGUID(players[i])
            if guid then
                names[guid] = UnitName(players[i])
                classes[guid] = select(2, UnitClass(players[i]))

                local petGUID = UnitGUID(pets[i])
                if petGUID then
                    names[petGUID] = UnitName(pets[i])
                    classes[petGUID] = "PET"
                end
            end
        end
    end

    names.AGGRO = L["> Срыв агро <"]
    classes.AGGRO = "AGGRO"
end

function Threat:GROUP_CHANGED()
    local oldParty, oldRaid = inParty, inRaid
    inParty = GetNumPartyMembers() > 0
    inRaid = GetNumRaidMembers() > 0
    if oldParty ~= inParty or oldRaid ~= inRaid then manualToggle = false end

    self:UpdatePartyGUIDs()
    self:UpdateVisible()
end

local function ThreatExpire(source)
    for mob, receivers in pairs(tempThreat) do
        for receiver, sources in pairs(receivers) do
            if sources[source] then
                sources.total = sources.total - sources[source]
                sources[source] = nil
                if sources.total < 1 then receivers[receiver] = nil end
            end
        end
        if next(receivers) == nil then tempThreat[mob] = nil end
    end

    tempExpire[source] = nil
    mdActors[source] = nil
    mdActive[source] = nil
end

local function FadeExpire(source)
    fadeThreat[source] = nil
    tempExpire[source] = nil
end

local function RecordOne(unit, mob, source)
    if UnitCanAttack(unit, mob) then
        local value = select(5, UnitDetailedThreatSituation(unit, mob))
        local mobGUID = UnitGUID(mob)
        if mobGUID and fadeThreat[source] then fadeThreat[source][mobGUID] = value end
    end
end

local function RecordThreat(source)
    local unit
    if UnitGUID("player") == source then unit = "player" end

    if not unit and inRaid then
        for i = 1, GetNumRaidMembers() do
            if UnitGUID(rID[i]) == source then unit = rID[i] break end
        end
    end

    if not unit and inParty then
        for i = 1, GetNumPartyMembers() do
            if UnitGUID(pID[i]) == source then unit = pID[i] break end
        end
    end

    if not unit then return end

    if inRaid then
        for i = 1, GetNumRaidMembers() do
            RecordOne(unit, rID[i], source)
            RecordOne(unit, rpID[i], source)
            RecordOne(unit, rtID[i], source)
            RecordOne(unit, rptID[i], source)
        end
    elseif inParty then
        for i = 1, GetNumPartyMembers() do
            RecordOne(unit, pID[i], source)
            RecordOne(unit, ppID[i], source)
            RecordOne(unit, ptID[i], source)
            RecordOne(unit, pptID[i], source)
        end
    end

    if not inRaid then
        RecordOne(unit, "player", source)
        RecordOne(unit, "pet", source)
        RecordOne(unit, "pettarget", source)
    end

    for _, other in ipairs({ "target", "targettarget", "focus", "focustarget", "mouseover", "mouseovertarget" }) do
        RecordOne(unit, other, source)
    end
end

local FADE_SPELLS = {
    [55342] = 30,
    [586] = 10,
    [316254] = false,
    [316255] = 3,
}

local function DamageOf(event, ...)
    if event == "SPELL_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
        return select(4, ...)
    elseif event == "SWING_DAMAGE" then
        return (...)
    end
end

function Threat:COMBAT_LOG_EVENT_UNFILTERED(_, event, source, _, _, target, _, _, ...)
    if event == "SPELL_CAST_SUCCESS" then
        local spellID = ...
        if spellID == 34477 or spellID == 57934 then mdActors[source] = target end

    elseif event == "SPELL_AURA_APPLIED" then
        local spellID = ...
        local mdTarget = mdActors[source]

        if mdTarget and not mdActive[source] and (spellID == 35079 or spellID == 59628) then
            mdActive[source] = mdTarget
            tempExpire[source] = GetTime() + 30
            NS.After(30, function() ThreatExpire(source) end)

        elseif FADE_SPELLS[spellID] ~= nil then
            fadeThreat[target] = { display = true }
            local duration = FADE_SPELLS[spellID]
            if duration then
                tempExpire[target] = GetTime() + duration
                NS.After(duration, function() FadeExpire(target) end)
            else
                tempExpire[target] = nil
            end
            RecordThreat(target)

        elseif spellID == 32612 and fadeThreat[source] then
            fadeThreat[source] = {}
        end

    elseif event == "SPELL_AURA_REMOVED" then
        local spellID = ...
        if spellID == 35079 or spellID == 59628 then
            mdActors[target] = nil
            mdActive[target] = nil
        elseif FADE_SPELLS[spellID] ~= nil then
            FadeExpire(target)
        end

    else
        local mdTarget = mdActors[source]
        if mdTarget then
            local damage = DamageOf(event, ...)
            if damage then
                if not mdActive[source] then
                    mdActive[source] = mdTarget
                    tempExpire[source] = GetTime() + 30
                    NS.After(30, function() ThreatExpire(source) end)
                end
                if damage < 1 then return end

                tempThreat[target] = tempThreat[target] or {}
                local receivers = tempThreat[target]
                receivers[mdTarget] = receivers[mdTarget] or {}
                local sources = receivers[mdTarget]
                sources[source] = (sources[source] or 0) + damage
                sources.total = (sources.total or 0) + damage
            end

        elseif fadeThreat[source] then
            local damage = DamageOf(event, ...)
            if damage then
                fadeThreat[source][target] = (fadeThreat[source][target] or 0) + damage * 10
            end
        end
    end
end

local function UpdateOne(unit, mob)
    local guid = UnitGUID(unit)
    if not guid or threatTable[guid] then return end

    local isTanking, _, _, _, value = UnitDetailedThreatSituation(unit, mob)
    if value then
        if value <= 0 and fadeThreat[guid] then
            value = fadeThreat[guid][UnitGUID(mob)] or 0
            if value > 0 then fadeThreat[guid].display = true end
        end
        if value > topThreat then topThreat = value end
        if isTanking then tankGUID = guid end
        threatTable[guid] = value
    else
        threatTable[guid] = -1
    end
end

function Threat:FindMob()
    local db = Settings()
    local list = db.useFocus and { "focus", "focustarget", "target", "targettarget" } or { "target", "targettarget" }
    local first

    for _, unit in ipairs(list) do
        if UnitExists(unit) then
            local name = UnitName(unit)
            names[UnitGUID(unit)] = name
            first = first or name

            if not UnitIsPlayer(unit) and UnitCanAttack("player", unit) and UnitHealth(unit) > 0 then
                if not db.ignorePets or not UnitPlayerControlled(unit) then
                    self:SetTitle(name)
                    self.mob = unit
                    self.mobGUID = UnitGUID(unit)
                    return unit
                end
            end
        end
    end

    self:SetTitle(first)
    self.mob = nil
    self.mobGUID = nil
end

function Threat:SetTitle(text)
    if self.titleText then self.titleText:SetText(text or L["Угроза"]) end
end

local function IsTanking()
    local _, class = UnitClass("player")
    if class == "WARRIOR" then return GetBonusBarOffset() == 2 end
    if class == "DRUID" then return GetBonusBarOffset() == 3 end
    if class == "PALADIN" then
        local fury = GetSpellInfo(25780)
        return fury and UnitAura("player", fury) and true or false
    end
    if class == "DEATHKNIGHT" then
        local form = GetShapeshiftForm()
        if form and form ~= 0 then
            local icon = GetShapeshiftFormInfo(form)
            return icon == "Interface\\Icons\\Spell_Deathknight_FrostPresence"
        end
    end
    return false
end

local function BarColor(guid, class)
    local db = Settings()
    local S = NS.Styling

    if fadeThreat[guid] and fadeThreat[guid].display then return 0.5, 0.5, 0.5 end
    if guid == UnitGUID("player") and db.myColor then return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3] end
    if guid == tankGUID and db.tankColor then return 0.85, 0.28, 0.25 end
    if guid == "AGGRO" then return 0.9, 0.15, 0.15 end

    if db.classColors then
        if class == "PET" then return 0.77, 0, 1 end
        local color = ClassColor(class)
        if color then return color.r, color.g, color.b end
    end

    return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3]
end

local function NameText(guid, mobGUID)
    if fadeThreat[guid] and fadeThreat[guid].display then
        if tempExpire[guid] then
            return string.format("%s [%.0f]", names[guid], math.max(0, tempExpire[guid] - GetTime())), true
        end
        return names[guid], false
    end

    local temp = mobGUID and tempThreat[mobGUID] and tempThreat[mobGUID][guid]
    if temp then
        local left = 30
        for source in pairs(temp) do
            if source ~= "total" and tempExpire[source] then
                local expire = tempExpire[source] - GetTime()
                if expire > 0 and expire < left then left = expire end
            end
        end
        return string.format("%s [%.0f]", names[guid], left), true
    end

    return names[guid], false
end

function Threat:Warn(text)
    local db = Settings()
    local warn = db.warn

    if warn.sound then
        for _, sound in ipairs(self.SOUNDS) do
            if sound.key == warn.soundKey then PlaySoundFile(sound.path) end
        end
    end
    if warn.flash then self:Flash() end
    if warn.shake then self:Shake() end
    if warn.message and RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, text, { r = 1, g = 0.25, b = 0.25 })
    end
end

function Threat:Flash()
    local flasher = self.flasher
    if not flasher then
        flasher = CreateFrame("Frame", nil, UIParent)
        flasher:SetFrameStrata("FULLSCREEN_DIALOG")
        flasher:SetAllPoints(UIParent)
        flasher:EnableMouse(false)
        flasher:Hide()

        local texture = flasher:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture(FLASH)
        texture:SetAllPoints(flasher)
        texture:SetBlendMode("ADD")

        flasher:SetScript("OnShow", function(f)
            f.elapsed = 0
            f:SetAlpha(0)
        end)
        flasher:SetScript("OnUpdate", function(f, elapsed)
            f.elapsed = f.elapsed + elapsed
            if f.elapsed >= 2.6 then
                f:Hide()
                return
            end
            local phase = f.elapsed % 1.3
            if phase < 0.15 then
                f:SetAlpha(phase / 0.15)
            elseif phase < 0.9 then
                f:SetAlpha(1 - (phase - 0.15) / 0.75)
            else
                f:SetAlpha(0)
            end
        end)
        self.flasher = flasher
    end

    flasher:Hide()
    flasher:Show()
end

function Threat:Shake()
    local shaker = self.shaker
    if not shaker then
        shaker = CreateFrame("Frame")
        shaker:Hide()
        shaker:SetScript("OnShow", function(f)
            if not f.points then
                f.points = {}
                for i = 1, WorldFrame:GetNumPoints() do f.points[i] = { WorldFrame:GetPoint(i) } end
            end
            f.elapsed = 0
        end)
        shaker:SetScript("OnUpdate", function(f, elapsed)
            f.elapsed = f.elapsed + elapsed
            local x, y = 0, 0
            if f.elapsed >= 0.8 then
                f:Hide()
            else
                x, y = math.random(-8, 8), math.random(-8, 8)
            end

            if WorldFrame:IsProtected() and InCombatLockdown() then
                f:Hide()
                return
            end

            WorldFrame:ClearAllPoints()
            for _, point in ipairs(f.points) do
                WorldFrame:SetPoint(point[1], point[2], point[3], point[4] + x, point[5] + y)
            end
        end)
        self.shaker = shaker
    end

    if WorldFrame:IsProtected() and InCombatLockdown() then return end
    shaker:Show()
end

local function Animate(bar, elapsed)
    bar.animTime = bar.animTime + elapsed
    local t = math.min(1, bar.animTime / 0.25)
    bar.fill:SetWidth(bar.fromW + (bar.toW - bar.fromW) * t)
    bar.temp:SetWidth(bar.fromT + (bar.toT - bar.fromT) * t)
    if t >= 1 then bar:SetScript("OnUpdate", nil) end
end

local function SetWidths(bar, width, temp, animate)
    if width < 1 then width = 1 end
    if temp < 1 then temp = 1 end

    if not animate then
        bar:SetScript("OnUpdate", nil)
        bar.fill:SetWidth(width)
        bar.temp:SetWidth(temp)
        return
    end

    if bar.toW == width and bar.toT == temp and bar:GetScript("OnUpdate") then return end
    bar.fromW, bar.toW = bar.fill:GetWidth(), width
    bar.fromT, bar.toT = bar.temp:GetWidth(), temp
    bar.animTime = 0
    bar:SetScript("OnUpdate", Animate)
end

function Threat:ClearAll()
    for index = 0, #bars do
        if bars[index] then bars[index]:Hide() end
    end
    self:SetTitle(nil)

    local db = Settings()
    if db and db.autoCollapse and self.frame then
        self.frame:SetHeight(self:TitleHeight() + 2)
        if db.collapseHide and not manualToggle and not self.moving then self.frame:Hide() end
    end

    self.barsShown = 0
    lastWarn.mob, lastWarn.tank, lastWarn.percent = nil, nil, 0
    threatStore = {}
    wipe(threatStoreTime)
    threatTable = nil
end

local TEST_ORDER = { "WARRIOR", "PALADIN", "DEATHKNIGHT", "DRUID", "ROGUE", "HUNTER", "MAGE", "WARLOCK", "PRIEST", "SHAMAN", "PET" }

function Threat:UpdateReal()
    local f = self.frame
    if not f then return end

    local db = Settings()
    if db.autoCollapse and db.collapseHide then
        self.barsShown = 1
        self:UpdateVisible()
    end
    if not f:IsShown() then
        self.barsShown = 0
        return
    end

    local myGUID = UnitGUID("player")
    local mob, mobGUID, mobTargetGUID
    topThreat = -1
    tankGUID = nil

    if testMode then
        threatTable = {}
        for i = 1, 25 do
            if i == 22 and myGUID then
                threatTable[myGUID] = i * 5000
            else
                local class = TEST_ORDER[(i - 1) % #TEST_ORDER + 1]
                threatTable[i] = i * 5000
                names[i] = class == "PET" and L["Питомец"] or (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or class
                classes[i] = class
            end
        end
        tankGUID = 25
        topThreat = 25 * 5000
        self:SetTitle(L["Тестовый режим"])
    else
        mob = self:FindMob()
        if not mob then
            self:ClearAll()
            return
        end
        mobGUID = UnitGUID(mob)

        local mobTarget = mob .. "target"
        mobTargetGUID = UnitGUID(mobTarget)
        if mobTargetGUID then names[mobTargetGUID] = UnitName(mobTarget) end

        threatTable = {}
        threatTable[mobGUID] = -1

        if inRaid then
            for i = 1, GetNumRaidMembers() do
                UpdateOne(rID[i], mob)
                UpdateOne(rpID[i], mob)
                UpdateOne(rtID[i], mob)
                UpdateOne(rptID[i], mob)
            end
        elseif inParty then
            for i = 1, GetNumPartyMembers() do
                UpdateOne(pID[i], mob)
                UpdateOne(ppID[i], mob)
                UpdateOne(ptID[i], mob)
                UpdateOne(pptID[i], mob)
            end
        end

        if not inRaid then
            UpdateOne("player", mob)
            UpdateOne("pet", mob)
            UpdateOne("pettarget", mob)
        end
        for _, unit in ipairs({ "target", "targettarget", "focus", "focustarget", mobTarget, "mouseover", "mouseovertarget" }) do
            UpdateOne(unit, mob)
        end
    end

    local tankThreat = (tankGUID and threatTable[tankGUID]) or (mobTargetGUID and threatTable[mobTargetGUID]) or topThreat
    if not tankThreat or tankThreat < 0 then tankThreat = 0 end

    if db.showAggroBar and tankThreat > 0 then
        local close
        if mob and GetItemInfo(37727) then
            close = IsItemInRange(37727, mob) == 1
        elseif mob then
            close = CheckInteractDistance(mob, 3) and true or false
            if not self.queriedAcorn and not ItemRefTooltip:IsVisible() then
                ItemRefTooltip:SetHyperlink("item:37727")
                ItemRefTooltip:Hide()
                self.queriedAcorn = true
            end
        else
            close = true
        end
        threatTable.AGGRO = tankThreat * (close and 1.1 or 1.3)
    end

    local count = 0
    for key, value in pairs(threatTable) do
        if value ~= -1 then
            count = count + 1
            sortTable[count] = key
        end
    end
    for index = count + 1, #sortTable do sortTable[index] = nil end

    if count == 0 then
        self:ClearAll()
        self:SetTitle(mobGUID and names[mobGUID])
        return
    end

    table.sort(sortTable, function(a, b) return threatTable[a] > threatTable[b] end)

    local width = self:BarWidth()
    topThreat = threatTable[sortTable[1]]
    if topThreat == 0 then topThreat = 1 end

    local selfShown = true
    if db.alwaysShowSelf then
        for index = 1, count do
            if sortTable[index] == myGUID then selfShown = false break end
        end
    end

    local slots = self:BarSlots()
    local row = 1

    if db.showHeadings then
        local heading = self:Bar(0)
        heading:Show()
        row = 2
    elseif bars[0] then
        bars[0]:Hide()
    end

    local barIndex = 1
    local anyCountdown = false

    for index = 1, count do
        if row > slots then break end
        local guid = sortTable[index]
        local class = classes[guid]
        local show
        if class == nil then
            show = db.classes.NOTINPARTY
        elseif class == "AGGRO" then
            show = db.showAggroBar
        else
            show = db.classes[class] ~= false
        end

        if db.alwaysShowSelf and row == slots and not selfShown and guid ~= myGUID then show = false end
        if db.alwaysShowSelf and guid == myGUID then
            show = true
            selfShown = true
        end

        if show then
            local bar = self:Bar(barIndex)
            local value = threatTable[guid]

            local text, countdown = NameText(guid, mobGUID)
            bar.name:SetText(text)
            if countdown then anyCountdown = true end

            local percent = tankThreat == 0 and 0 or value / tankThreat * 100
            if db.showValue and db.showPercent then
                bar.value:SetText(string.format("%s [%d%%]", Short(value), percent))
            elseif db.showValue then
                bar.value:SetText(Short(value))
            else
                bar.value:SetText(string.format("%d%%", percent))
            end

            local r, g, b = BarColor(guid, class)
            bar.fill:SetVertexColor(r, g, b, 1)

            local temp = 0
            if mobGUID and tempThreat[mobGUID] and tempThreat[mobGUID][guid] then
                temp = math.min(tempThreat[mobGUID][guid].total or 0, value)
            end

            local main = width * ((value - temp) / topThreat)
            local extra = width * (temp / topThreat)
            bar.temp:SetShown(extra >= 1)
            SetWidths(bar, main, extra, db.animate and NS.Styling.AnimationsEnabled() and not self.sizing)

            bar.guid = guid
            bar:Show()
            barIndex = barIndex + 1
            row = row + 1
        end
    end

    for index = barIndex, #bars do bars[index]:Hide() end

    self.countdowns = anyCountdown
    self.barsShown = barIndex - 1

    if db.autoCollapse then
        local rows = row - 1
        f:SetHeight(self:TitleHeight() + 6 + rows * db.barHeight + math.max(0, rows - 1) * db.barSpacing)
    end

    if testMode then
        threatTable = nil
        return
    end

    if myGUID and threatTable[myGUID] and threatTable[myGUID] >= 0 then
        local percent = tankThreat == 0 and 0 or threatTable[myGUID] / tankThreat * 100
        local warn = db.warn

        if lastWarn.mob == mobGUID and percent >= warn.threshold and warn.threshold > lastWarn.percent then
            if not warn.notTanking or not IsTanking() then
                self:Warn(string.format(L["Больше %d%% угрозы %s!"], warn.threshold, names[lastWarn.tank]))
            end
        end

        if lastWarn.mob ~= mobGUID then
            threatStore = {}
            wipe(threatStoreTime)
        end
        threatStore[#threatStore + 1] = threatTable
        threatStoreTime[#threatStoreTime + 1] = GetTime()

        local tank = tankGUID or mobTargetGUID or (db.showAggroBar and sortTable[2] or sortTable[1])
        if tank ~= "AGGRO" then
            lastWarn.mob = mobGUID
            lastWarn.tank = tank
            lastWarn.percent = percent
        end
    end

    threatTable = nil
end

function Threat:UpdateCountdowns()
    for index = 1, #bars do
        local bar = bars[index]
        if bar:IsShown() and bar.guid then
            bar.name:SetText((NameText(bar.guid, self.mobGUID)))
        end
    end
end

function Threat:UpdateTPS()
    local db = Settings()
    if not db.showTPS then return end

    if testMode then
        for index = 1, #bars do
            local bar = bars[index]
            bar.tps:SetText(bar.guid == "AGGRO" and "--" or tostring(1300 - 50 * index))
        end
        return
    end

    local window = db.tpsWindow
    local start = GetTime() - window

    while threatStoreTime[2] and start > threatStoreTime[2] do
        table.remove(threatStore, 1)
        table.remove(threatStoreTime, 1)
    end

    local size = #threatStoreTime
    if size == 0 or start <= threatStoreTime[1] then
        for index = 1, #bars do bars[index].tps:SetText("??") end
        return
    end

    if size == 1 then
        for index = 1, #bars do bars[index].tps:SetText("0") end
        return
    end

    for index = 1, #bars do
        local bar = bars[index]
        if not bar:IsShown() then return end
        local guid = bar.guid

        if guid == "AGGRO" then
            bar.tps:SetText("--")
        else
            local base, second, final = threatStore[1][guid], threatStore[2][guid], threatStore[size][guid]
            if base and second and final and base >= 0 and second >= 0 and final >= 0 then
                local ratio = (start - threatStoreTime[1]) / (threatStoreTime[2] - threatStoreTime[1])
                local startThreat = (second - base) * ratio + base
                bar.tps:SetText(string.format("%d", (final - startThreat) / window / 100))
            else
                bar.tps:SetText("??")
            end
        end
    end
end

function Threat:Update()
    self.dirty = true
end

function Threat:TitleHeight()
    local db = Settings()
    if not db.showTitle then return 0 end
    return math.max(16, math.floor(NS.FS(db.fontSize) + 8))
end

function Threat:BarWidth()
    local f = self.frame
    return math.max(10, (f and f:GetWidth() or 200) - 6)
end

function Threat:BarSlots()
    local db = Settings()
    if db.autoCollapse then return db.numBars + (db.showHeadings and 1 or 0) end
    local height = (self.frame and self.frame:GetHeight() or 100) - self:TitleHeight() - 6
    return math.max(1, math.floor((height + db.barSpacing) / (db.barHeight + db.barSpacing)))
end

function Threat:LayoutBar(bar, index)
    local db = Settings()
    local S = NS.Styling
    local style = StyleKey()
    local size = NS.FS(db.fontSize)
    local texture = NS.Look:BarTexture("threat", (style == "classic" or style == "pixel") and SHADED or WHITE)

    local slot = db.showHeadings and index or math.max(0, index - 1)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", self.list, "TOPLEFT", 3, -3 - slot * (db.barHeight + db.barSpacing))
    bar:SetPoint("RIGHT", self.list, "RIGHT", -3, 0)
    bar:SetHeight(db.barHeight)

    bar.fill:SetTexture(texture)
    bar.temp:SetTexture(texture)
    bar.ground:SetShown(style ~= "classic")
    bar.sheen:SetShown(style ~= "classic" and style ~= "pixel")

    for _, text in ipairs({ bar.name, bar.value, bar.tps }) do
        NS.LSetFont(text, "threat", size, "OUTLINE")
        text:SetShadowOffset(0, 0)
        local tr, tg, tb = NS.Look:Color("threat", "text")
        text:SetTextColor(tr or 1, tg or 1, tb or 1)
    end

    local valueWidth = db.showValue and db.showPercent and 78 or 48
    local tpsWidth = db.showTPS and 40 or 0

    bar.value:ClearAllPoints()
    bar.value:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    bar.value:SetWidth(valueWidth)

    bar.tps:ClearAllPoints()
    bar.tps:SetPoint("RIGHT", bar.value, "LEFT", -2, 0)
    bar.tps:SetWidth(tpsWidth)
    bar.tps:SetShown(db.showTPS)

    bar.name:ClearAllPoints()
    bar.name:SetPoint("LEFT", bar, "LEFT", 4, 0)
    bar.name:SetPoint("RIGHT", db.showTPS and bar.tps or bar.value, "LEFT", -4, 0)

    if index == 0 then
        bar.name:SetText(L["Имя"])
        bar.value:SetText(db.showValue and db.showPercent and L["Угроза [%]"] or L["Угроза"])
        bar.tps:SetText(L["УВС"])
        bar.fill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
        bar.fill:SetWidth(self:BarWidth())
        bar.temp:Hide()
        bar.sheen:Hide()
        for _, text in ipairs({ bar.name, bar.value, bar.tps }) do
            text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        end
    end
end

local function NewBar(parent)
    local bar = CreateFrame("Frame", nil, parent)

    bar.ground = bar:CreateTexture(nil, "BACKGROUND")
    bar.ground:SetAllPoints(bar)
    bar.ground:SetTexture(WHITE)
    bar.ground:SetVertexColor(NS.Styling.Tint(0.05, 0.055, 0.075, 0.6))

    bar.fill = bar:CreateTexture(nil, "BORDER")
    bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    bar.fill:SetWidth(1)

    bar.temp = bar:CreateTexture(nil, "BORDER")
    bar.temp:SetPoint("TOPLEFT", bar.fill, "TOPRIGHT", 0, 0)
    bar.temp:SetPoint("BOTTOMLEFT", bar.fill, "BOTTOMRIGHT", 0, 0)
    bar.temp:SetWidth(1)
    bar.temp:SetVertexColor(0.5, 0.5, 0.5, 1)
    bar.temp:Hide()

    bar.sheen = bar:CreateTexture(nil, "ARTWORK")
    bar.sheen:SetPoint("TOPLEFT", bar.fill, "TOPLEFT", 0, 0)
    bar.sheen:SetPoint("BOTTOMRIGHT", bar.fill, "RIGHT", 0, 0)
    bar.sheen:SetTexture(WHITE)
    bar.sheen:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.10)

    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetJustifyH("LEFT")
    bar.value = bar:CreateFontString(nil, "OVERLAY")
    bar.value:SetJustifyH("RIGHT")
    bar.tps = bar:CreateFontString(nil, "OVERLAY")
    bar.tps:SetJustifyH("RIGHT")

    for _, text in ipairs({ bar.name, bar.value, bar.tps }) do
        NS.LSetFont(text, "threat", NS.FS(10), "OUTLINE")
        text:SetHeight(14)
        text:SetNonSpaceWrap(false)
    end

    bar.animTime, bar.fromW, bar.toW, bar.fromT, bar.toT = 0, 1, 1, 1, 1
    bar:Hide()

    return bar
end

function Threat:Bar(index)
    local bar = bars[index]
    if bar then return bar end

    bar = NewBar(self.list)
    bars[index] = bar

    self:LayoutBar(bar, index)
    return bar
end

function Threat:ApplyStyle()
    local f = self.frame
    if not f then return end

    local db = Settings()
    local S = NS.Styling
    local style = StyleKey()
    local alpha = db.alpha / 100
    local backdrop = FLAT_BACKDROP
    if style == "classic" then backdrop = CLASSIC_BACKDROP elseif style == "thick" then backdrop = THICK_BACKDROP end

    local r, g, b = S.Tint(0.020, 0.023, 0.032)
    local er, eg, eb, ea = S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9
    if style == "classic" then
        r, g, b = 0.06, 0.06, 0.10
        er, eg, eb, ea = 0.6, 0.6, 0.65, 1
    elseif style == "pixel" then
        r, g, b = 0.07, 0.07, 0.075
        er, eg, eb, ea = 0, 0, 0, 1
    elseif style == "glass" then
        r, g, b = S.Tint(0.05, 0.07, 0.11)
        alpha = alpha * 0.7
        er, eg, eb, ea = S.ACCENT[1] * 0.8, S.ACCENT[2] * 0.8, S.ACCENT[3] * 0.8, 0.95
    elseif style == "neon" then
        r, g, b = 0, 0, 0
        er, eg, eb, ea = S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1
    elseif style == "minimal" then
        r, g, b = 0, 0, 0
        alpha = alpha * 0.45
        ea = 0
    elseif style == "thick" then
        er, eg, eb, ea = S.BORDER[1] * 1.3, S.BORDER[2] * 1.3, S.BORDER[3] * 1.3, 1
    end

    local lr, lg, lb = NS.Look:Color("threat", "bg")
    if lr then r, g, b = lr, lg, lb end
    local br, bg_, bb = NS.Look:Color("threat", "border")
    if br then er, eg, eb, ea = br, bg_, bb, 1 end

    self.title:SetBackdrop(backdrop)
    self.title:SetBackdropColor(r, g, b, math.min(1, alpha + 0.15))
    self.title:SetBackdropBorderColor(er, eg, eb, ea)

    self.list:SetBackdrop(backdrop)
    self.list:SetBackdropColor(r, g, b, alpha)
    self.list:SetBackdropBorderColor(er, eg, eb, ea)

    self.accent:SetShown(style == "modern" or style == "glass" or style == "neon")
    if self.shadow then self.shadow:SetShown(style ~= "classic" and style ~= "minimal") end

    NS.LSetFont(self.titleText, "threat", NS.FS(db.fontSize + 1), "")
    self.titleText:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
end

function Threat:Layout()
    local f = self.frame
    if not f then return end

    local db = Settings()
    f:SetScale(db.scale / 100)
    f:SetSize(db.width, db.autoCollapse and f:GetHeight() or db.height)

    local titleHeight = self:TitleHeight()
    self.title:SetHeight(math.max(titleHeight, 1))
    self.title:SetShown(db.showTitle)

    self.list:ClearAllPoints()
    if db.showTitle then
        self.list:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, 1)
    else
        self.list:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    end
    self.list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

    self.grip:SetShown(not db.locked)
    self.title:EnableMouse(not db.clickThrough or not db.locked)
    self.list:EnableMouse(not db.clickThrough)

    self:ApplyStyle()

    for index = 0, #bars do
        if bars[index] then self:LayoutBar(bars[index], index) end
    end

    self:Update()
end

local SAMPLE_THREAT = {
    { "Торвальд", "PALADIN", 1, "52.4k", "100%" },
    { nil, nil, 0.84, "44.0k", "84%" },
    { "Шейд", "ROGUE", 0.61, "31.9k", "61%" },
    { "Мирра", "DRUID", 0.35, "18.3k", "35%" },
}

function Threat:CreateSample(parent)
    local S = NS.Styling
    local obj = setmetatable({}, { __index = Threat })
    local f = CreateFrame("Frame", nil, parent)
    f.narciNoRound = true
    obj.frame = f
    local title = CreateFrame("Frame", nil, f)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    obj.title = title
    local titleText = title:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("LEFT", title, "LEFT", 6, 0)
    titleText:SetJustifyH("LEFT")
    NS.LSetFont(titleText, "threat", NS.FS(12), "")
    titleText:SetText(L["Угроза"] .. ": " .. L["Ледяной змей"])
    obj.titleText = titleText
    local accent = title:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", 1, 0)
    accent:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -1, 0)
    accent:SetHeight(1)
    accent:SetTexture(WHITE)
    accent:SetGradientAlpha("HORIZONTAL", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)
    obj.accent = accent
    obj.list = CreateFrame("Frame", nil, f)
    if S.CreateShadow then obj.shadow = S.CreateShadow(f, 5, 0.4) end
    obj.sampleBars = {}
    for index = 0, #SAMPLE_THREAT do obj.sampleBars[index] = NewBar(obj.list) end
    f.obj = obj
    return f
end

function Threat:PaintSample(f)
    local db = Settings()
    if not db or not f or not f.obj then return end
    local obj = f.obj
    local rows = #SAMPLE_THREAT + (db.showHeadings and 1 or 0)
    local titleHeight = obj:TitleHeight()
    f:SetSize(math.max(160, db.width or 200), titleHeight + 6 + rows * (db.barHeight + db.barSpacing))
    obj.title:SetHeight(math.max(titleHeight, 1))
    obj.title:SetShown(db.showTitle)
    obj.list:ClearAllPoints()
    if db.showTitle then
        obj.list:SetPoint("TOPLEFT", obj.title, "BOTTOMLEFT", 0, 1)
    else
        obj.list:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    end
    obj.list:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    obj:ApplyStyle()
    local width = obj:BarWidth()
    for index = 0, #SAMPLE_THREAT do
        local bar = obj.sampleBars[index]
        obj:LayoutBar(bar, index)
        if index == 0 then
            bar:SetShown(db.showHeadings and true or false)
        else
            local data = SAMPLE_THREAT[index]
            local name, class = data[1], data[2]
            if not name then
                name = UnitName("player")
                class = select(2, UnitClass("player"))
            end
            local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or { r = 0.6, g = 0.6, b = 0.6 }
            bar.fill:SetVertexColor(c.r, c.g, c.b, 1)
            bar.fill:SetWidth(math.max(1, width * data[3]))
            bar.name:SetText(name)
            local value = (db.showValue and data[4] or "") .. ((db.showValue and db.showPercent) and " " or "") .. (db.showPercent and data[5] or "")
            bar.value:SetText(value)
            bar.tps:SetText("1.2k")
            bar:Show()
        end
    end
    f:SetScale(math.min(1, 300 / math.max(f:GetWidth(), 1), 200 / math.max(f:GetHeight(), 1)))
end

function Threat:SavePosition()
    local f = self.frame
    local db = Settings()
    if not f or not db then return end

    local point, _, relativePoint, x, y = f:GetPoint(1)
    db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y
    db.width = math.floor(f:GetWidth() + 0.5)
    if not db.autoCollapse then db.height = math.floor(f:GetHeight() + 0.5) end
end

function Threat:Place()
    local f = self.frame
    local db = Settings()
    f:ClearAllPoints()
    if db.point then
        f:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -260, 220)
    end
end

function Threat:QuickMenu(anchor)
    local db = Settings()
    if not self.menuFrame then
        self.menuFrame = CreateFrame("Frame", "NarciSirus_ThreatMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = {
        { text = L["Угроза"], isTitle = true, notCheckable = true },
        { text = L["Закрепить окно"], checked = db.locked, func = function()
            db.locked = not db.locked
            Threat:Layout()
        end },
        { text = L["Сначала фокус"], checked = db.useFocus, func = function()
            db.useFocus = not db.useFocus
            Threat:Update()
        end },
        { text = L["Тестовый режим"], checked = testMode, func = function() Threat:SetTestMode(not testMode) end },
        { text = L["Настройки"], notCheckable = true, func = function()
            if NS.Settings then
                NS.Settings:Create()
                NS.settingsFrame:Show()
                NS.Settings:Select("threat")
            end
        end },
        { text = L["Скрыть"], notCheckable = true, func = function() Threat:Toggle(false) end },
        { text = CLOSE or L["Закрыть"], notCheckable = true, func = function() CloseDropDownMenus() end },
    }

    EasyMenu(menu, self.menuFrame, anchor or "cursor", 0, 0, "MENU")
end

function Threat:Create()
    if self.frame then return self.frame end
    local db = Settings()
    if not db then return end

    local S = NS.Styling

    local f = CreateFrame("Frame", "NarciSirus_Threat", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetMinResize(120, 30)
    f:SetMaxResize(600, 800)
    f:SetClampedToScreen(true)
    f:SetSize(db.width, db.height)
    self.frame = f
    self:Place()
    if NS.Movers then
        NS.Movers:Register(f, L["Угроза"], function() Threat:SavePosition() end, "threat")
    end

    local title = CreateFrame("Button", nil, f)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    title:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    title:SetHeight(18)
    title:RegisterForClicks("RightButtonUp")
    title:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not Settings().locked then
            Threat.moving = true
            f:StartMoving()
        end
    end)
    title:SetScript("OnMouseUp", function()
        if Threat.moving then
            f:StopMovingOrSizing()
            Threat.moving = nil
            Threat:SavePosition()
        end
    end)
    title:SetScript("OnClick", function(self, button)
        if button == "RightButton" then Threat:QuickMenu("cursor") end
    end)
    title:SetScript("OnHide", function()
        if Threat.moving then
            f:StopMovingOrSizing()
            Threat.moving = nil
        end
    end)
    self.title = title

    local titleText = title:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("LEFT", title, "LEFT", 6, 0)
    titleText:SetPoint("RIGHT", title, "RIGHT", -6, 0)
    titleText:SetJustifyH("LEFT")
    self.titleText = titleText

    local accent = title:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT", 1, 0)
    accent:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -1, 0)
    accent:SetHeight(1)
    accent:SetTexture(WHITE)
    accent:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.1)
    self.accent = accent

    local list = CreateFrame("Frame", nil, f)
    list:SetScript("OnMouseDown", title:GetScript("OnMouseDown"))
    list:SetScript("OnMouseUp", title:GetScript("OnMouseUp"))
    self.list = list

    f.narciNoRound = true
    if S.CreateShadow then self.shadow = S.CreateShadow(f, 5, 0.4) end

    local grip = CreateFrame("Button", nil, list)
    grip:SetSize(12, 12)
    grip:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(list:GetFrameLevel() + 5)
    local gripTexture = grip:CreateTexture(nil, "OVERLAY")
    gripTexture:SetAllPoints(grip)
    gripTexture:SetTexture(WHITE)
    gripTexture:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.6)
    grip:SetScript("OnMouseDown", function()
        if Settings().locked then return end
        Threat.sizing = true
        f:StartSizing("BOTTOMRIGHT")
        f:SetScript("OnSizeChanged", function()
            for index = 0, #bars do
                if bars[index] then bars[index].fill:SetWidth(1) end
            end
            Threat:Update()
        end)
    end)
    grip:SetScript("OnMouseUp", function()
        if not Threat.sizing then return end
        f:StopMovingOrSizing()
        f:SetScript("OnSizeChanged", nil)
        Threat.sizing = nil
        Threat:SavePosition()
        Threat:Layout()
    end)
    grip:SetScript("OnHide", grip:GetScript("OnMouseUp"))
    self.grip = grip

    f:SetScript("OnShow", function() Threat:Update() end)

    self:Layout()
    self:ClearAll()
    f:Hide()

    return f
end

function Threat:SetTestMode(value)
    testMode = value and true or false
    if testMode then
        self:Create()
        self:Toggle(true)
    else
        manualToggle = false
        self:UpdateVisible()
    end
    self:Update()
end

function Threat:IsTestMode()
    return testMode
end

function Threat:Toggle(value)
    local f = self:Create()
    if not f then return end

    local db = Settings()
    if not (db.autoCollapse and db.collapseHide) then manualToggle = true end

    if value == nil then value = not f:IsShown() end
    f:SetShown(value)
    if value then self:Update() end
end

function Threat:UpdateVisible(event)
    local f = self.frame
    if not f or manualToggle or testMode then return end

    local db = Settings()
    if not Enabled() or self:OmenLoaded() then
        f:Hide()
        return
    end

    local rules = db.show

    if rules.hideOOC and not InCombatLockdown() and event ~= "PLAYER_REGEN_DISABLED" then
        f:Hide()
        return
    end

    local hasPet = UnitExists("pet")
    local show = (rules.pet and hasPet) or (rules.party and inParty) or (rules.raid and inRaid)
        or (rules.alone and not inParty and not inRaid and not hasPet)

    local _, instanceType = IsInInstance()
    if (rules.hideResting and IsResting()) or (rules.hidePvP and (instanceType == "pvp" or instanceType == "arena")) then
        show = false
    end

    if db.autoCollapse and db.collapseHide and (self.barsShown or 0) == 0 then show = false end

    f:SetShown(show and true or false)
end

function Threat:Apply()
    if not Enabled() then
        if self.frame then self.frame:Hide() end
        return
    end
    if self:OmenLoaded() then
        if not self.warnedOmen then
            self.warnedOmen = true
            NS.Print(L["Включён аддон Omen, встроенный измеритель угрозы ждёт. Отключить Omen можно в настройках, страница Угроза."])
        end
        return
    end

    self:Create()
    self:GROUP_CHANGED()
    self:Layout()
    self:UpdateVisible()
    self:Update()
end

function Threat:ResetPosition()
    local db = Settings()
    db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil
    db.width, db.height = DEFAULTS.width, DEFAULTS.height
    if self.frame then
        self.frame:SetSize(db.width, db.height)
        self:Place()
        self:Layout()
    end
end

local driver = CreateFrame("Frame")
local refresh, tpsWait, countdownWait = 0, 0, 0

driver:SetScript("OnUpdate", function(_, elapsed)
    local f = Threat.frame
    if not f or not f:IsShown() then return end

    refresh = refresh + elapsed
    if refresh >= 0.5 and (testMode or Threat.mob) then
        refresh = 0
        Threat.dirty = true
    end

    if Threat.dirty then
        Threat.dirty = nil
        local ok, err = pcall(Threat.UpdateReal, Threat)
        if not ok then
            threatTable = nil
            if not Threat.reported then
                Threat.reported = true
                NS.Print("threat: " .. tostring(err))
            end
        end
    end

    tpsWait = tpsWait + elapsed
    if tpsWait >= 0.25 then
        tpsWait = 0
        pcall(Threat.UpdateTPS, Threat)
    end

    if Threat.countdowns then
        countdownWait = countdownWait + elapsed
        if countdownWait >= 0.25 then
            countdownWait = 0
            Threat:UpdateCountdowns()
        end
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_TARGET")
events:RegisterEvent("PARTY_MEMBERS_CHANGED")
events:RegisterEvent("RAID_ROSTER_UPDATE")
events:RegisterEvent("UNIT_PET")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function WatchCombatLog()
    if Enabled() and not Threat:OmenLoaded() then
        events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

hooksecurefunc(Threat, "Apply", WatchCombatLog)

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if NS.After then NS.After(2, function() Threat:Apply() end) end
        return
    end

    if not Threat.frame or not Enabled() or Threat:OmenLoaded() then return end

    if event == "PLAYER_ENTERING_WORLD" then
        manualToggle = false
        wipe(mdActors)
        wipe(mdActive)
        wipe(tempExpire)
        wipe(fadeThreat)
        wipe(tempThreat)
        for key in pairs(names) do names[key] = nil end
        Threat:GROUP_CHANGED()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        Threat:COMBAT_LOG_EVENT_UNFILTERED(...)
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "UNIT_PET" or event == "UNIT_NAME_UPDATE" then
        Threat:GROUP_CHANGED()
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if unit == "focus" or unit == "target" then Threat:Update() end
    elseif event == "PLAYER_UPDATE_RESTING" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "ZONE_CHANGED_NEW_AREA" then
        Threat:UpdateVisible(event)
        Threat:Update()
    else
        Threat:Update()
    end
end)
