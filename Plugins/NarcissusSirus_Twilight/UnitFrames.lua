local addonName, ns = ...
ns.Twilight = ns.Twilight or {}
local T = ns.Twilight

local API = T.API
if not API then return end

local L = function(text) return API:L(text) end
local WHITE = T.WHITE

local buttons = {}
local auraFrames = {}

local HEALTH_TEXT = { 0.47, 0.53, 0.48 }
local POWER_COLORS = {
    [0] = { 0.35, 0.67, 0.75 },
    [1] = { 0.78, 0.25, 0.25 },
    [2] = { 0.75, 0.55, 0.25 },
    [3] = { 0.90, 0.82, 0.35 },
    [6] = { 0.35, 0.65, 0.80 },
}
local POWER_BAR = {
    [0] = { 0.13, 0.42, 0.75 },
    [1] = { 0.70, 0.18, 0.18 },
    [2] = { 0.70, 0.50, 0.20 },
    [3] = { 0.85, 0.75, 0.25 },
    [6] = { 0.30, 0.60, 0.78 },
}
local DEBUFF_COLORS = {
    Magic = { 0.20, 0.60, 1.00 },
    Curse = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison = { 0.00, 0.60, 0.00 },
    none = { 0.80, 0.00, 0.00 },
}

local function Hidden()
    if not T.hiddenParent then
        T.hiddenParent = CreateFrame("Frame")
        T.hiddenParent:Hide()
    end
    return T.hiddenParent
end

local function Kill(frame)
    if type(frame) == "string" then frame = _G[frame] end
    if not frame then return end
    frame:UnregisterAllEvents()
    frame:Hide()
    frame:SetParent(Hidden())
end

local function UnitOf(button)
    return button:GetAttribute("unit") or button.unit
end

local function Group(value)
    local text = tostring(math.floor(value + 0.5))
    return text
end

local specRoles = {}
local inspectQueue = {}
local inspecting

local function AssignedRole(unit)
    if not UnitGroupRolesAssigned then return end
    local a, b, c = UnitGroupRolesAssigned(unit)
    if type(a) == "string" then
        if a == "TANK" or a == "HEALER" or a == "DAMAGER" then return a end
        return
    end
    if a then return "TANK" elseif b then return "HEALER" elseif c then return "DAMAGER" end
end

local function PickRole(...)
    local tank, healer
    for index = 1, select("#", ...) do
        local role = select(index, ...)
        if role == "HEALER" then healer = true elseif role == "TANK" then tank = true end
    end
    if healer then return "HEALER" end
    if tank and select("#", ...) == 1 then return "TANK" end
    return "DAMAGER"
end

local function Role(unit)
    local assigned = AssignedRole(unit)
    if assigned then return assigned end

    if UnitIsUnit(unit, "player") then
        if C_Talent and C_Talent.GetCurrentSpecRole then return C_Talent.GetCurrentSpecRole() end
        return
    end

    local guid = UnitGUID(unit)
    if not guid or not UnitIsPlayer(unit) then return end
    if specRoles[guid] then return specRoles[guid] end
    if not inspectQueue[guid] then inspectQueue[guid] = { unit = unit, tries = 0 } end
end

local function InspectBusy()
    if InCombatLockdown() then return true end
    if _G.InspectFrame and _G.InspectFrame:IsShown() then return true end
    return false
end

local function ReadSpec()
    local entry = inspecting
    inspecting = nil
    if not entry then return end
    local unit = entry.unit
    if not UnitExists(unit) or UnitGUID(unit) ~= entry.guid then return end

    local group = GetActiveTalentGroup and GetActiveTalentGroup(true) or 1
    local best, bestPoints = nil, -1
    for tab = 1, GetNumTalentTabs(true) or 3 do
        local _, _, points = GetTalentTabInfo(tab, true, false, group)
        if points and points > bestPoints then best, bestPoints = tab, points end
    end
    local _, class = UnitClass(unit)
    if best and bestPoints > 0 and class and C_Talent and C_Talent.GetClassSpecRole then
        local ok, role = pcall(function() return PickRole(C_Talent.GetClassSpecRole(class, best)) end)
        if ok and role then
            specRoles[entry.guid] = role
            inspectQueue[entry.guid] = nil
        end
    end
    if not (_G.InspectFrame and _G.InspectFrame:IsShown()) and ClearInspectPlayer then ClearInspectPlayer() end
    if T.UpdateRoles then T.UpdateRoles() end
end

local inspector = CreateFrame("Frame")
inspector:RegisterEvent("INSPECT_TALENT_READY")
inspector:SetScript("OnEvent", function() if inspecting then ReadSpec() end end)
inspector:SetScript("OnUpdate", function(self, elapsed)
    self.wait = (self.wait or 0) - elapsed
    if self.wait > 0 then return end
    self.wait = 1.5

    if inspecting then
        if GetTime() - inspecting.started > 5 then inspecting = nil end
        return
    end
    if InspectBusy() then return end

    for guid, entry in pairs(inspectQueue) do
        local unit = entry.unit
        if not UnitExists(unit) or UnitGUID(unit) ~= guid or entry.tries >= 3 then
            inspectQueue[guid] = nil
        elseif UnitIsConnected(unit) and CanInspect(unit) then
            entry.tries = entry.tries + 1
            inspecting = { unit = unit, guid = guid, started = GetTime() }
            NotifyInspect(unit)
            return
        end
    end
end)

local ROLE_TEXTURES = {
    TANK = "svui-tank.tga",
    HEALER = "svui-healer.tga",
    DAMAGER = "svui-dps.tga",
}

local function Decorate(button, kind)
    if button.twilight then return end
    button.twilight = kind
    button:RegisterForClicks("AnyUp")

    button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    T.PaintBg(button)
    button:SetBackdropBorderColor(0, 0, 0, 1)

    local big = kind == "big"

    if big then
        local model = CreateFrame("PlayerModel", nil, button)
        model:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        model:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        model:SetFrameLevel(button:GetFrameLevel() + 1)
        model:SetAlpha(0.75)
        button.model = model
    end

    local health = CreateFrame("StatusBar", nil, button)
    health:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    health:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    health:SetFrameLevel(button:GetFrameLevel() + 2)
    health:SetStatusBarTexture(WHITE)
    health:SetStatusBarColor(0.1, 0.1, 0.12, big and 0.15 or 0.35)
    health:SetMinMaxValues(0, 1)
    button.health = health

    local deficit = health:CreateTexture(nil, "ARTWORK")
    deficit:SetTexture(WHITE)
    deficit:SetVertexColor(0, 0, 0, 0.55)
    deficit:SetPoint("TOPLEFT", health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
    deficit:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
    button.deficit = deficit

    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 4)
    button.overlay = overlay

    local power = CreateFrame("StatusBar", nil, button)
    power:SetFrameLevel(button:GetFrameLevel() + 5)
    power:SetStatusBarTexture(WHITE)
    power:SetMinMaxValues(0, 1)
    power:SetHeight(big and 4 or 3)
    power:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", big and -4 or -4, big and -2 or -2)
    power:SetPoint("BOTTOMLEFT", button, "BOTTOM", big and 2 or 2, big and -2 or -2)
    local powerBg = power:CreateTexture(nil, "BACKGROUND")
    powerBg:SetPoint("TOPLEFT", power, "TOPLEFT", -1, 1)
    powerBg:SetPoint("BOTTOMRIGHT", power, "BOTTOMRIGHT", 1, -1)
    powerBg:SetTexture(WHITE)
    powerBg:SetVertexColor(0, 0, 0, 1)
    button.power = power

    if big then
        local hp = T.Text(overlay, 12, "LEFT")
        hp:SetPoint("LEFT", button, "LEFT", 6, 0)
        hp:SetTextColor(HEALTH_TEXT[1], HEALTH_TEXT[2], HEALTH_TEXT[3])
        button.hpText = hp

        local pp = T.Text(overlay, 12, "RIGHT")
        pp:SetPoint("RIGHT", button, "RIGHT", -6, 0)
        button.ppText = pp

        local name = T.Text(overlay, 12, "CENTER")
        name:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.nameText = name
    else
        local hp = T.Text(overlay, 11, "CENTER")
        hp:SetPoint("TOP", button, "TOP", 0, -3)
        hp:SetTextColor(1, 1, 1)
        button.hpText = hp

        local name = T.Text(overlay, 11, "LEFT")
        name:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -1)
        name:SetPoint("RIGHT", button, "RIGHT", -16, 0)
        button.nameText = name

        local role = overlay:CreateTexture(nil, "OVERLAY")
        role:SetSize(12, 12)
        role:SetPoint("RIGHT", button, "RIGHT", -3, -3)
        button.role = role
    end

    local leader = overlay:CreateTexture(nil, "OVERLAY")
    leader:SetSize(11, 11)
    leader:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 4, -5)
    leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    leader:Hide()
    button.leader = leader

    local mark = overlay:CreateTexture(nil, "OVERLAY")
    mark:SetSize(14, 14)
    mark:SetPoint("CENTER", button, "TOP", 0, 0)
    mark:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    mark:Hide()
    button.mark = mark

    button:HookScript("OnEnter", function(self)
        local unit = UnitOf(self)
        if unit and UnitExists(unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(unit)
        end
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
    button:HookScript("OnShow", function(self) T.UpdateUnitButton(self, true) end)

    buttons[#buttons + 1] = button
end

function T.UpdateUnitButton(button, full)
    local unit = UnitOf(button)
    if not unit or not UnitExists(unit) or not button:IsVisible() then return end

    local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
    if not maximum or maximum <= 0 then maximum = 1 end
    button.health:SetValue(current / maximum)

    local dead = UnitIsDeadOrGhost(unit)
    local offline = not UnitIsConnected(unit)
    local percent = current / maximum * 100

    if button.twilight == "big" then
        if dead then
            button.hpText:SetText(DEAD or "Dead")
        elseif offline then
            button.hpText:SetText(PLAYER_OFFLINE or "Offline")
        else
            button.hpText:SetText(string.format("%s - %.2f%%", T.Short(current), percent))
        end
    else
        if dead then
            button.hpText:SetText(DEAD or "Dead")
        elseif offline then
            button.hpText:SetText(PLAYER_OFFLINE or "Offline")
        else
            button.hpText:SetText(string.format("%s - %.2f%%", Group(current), percent))
        end
    end

    local powerType = UnitPowerType(unit) or 0
    local power, powerMax = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
    if powerMax and powerMax > 0 then
        button.power:SetValue(power / powerMax)
        button.power:Show()
    else
        button.power:Hide()
    end
    local barColor = POWER_BAR[powerType] or POWER_BAR[0]
    button.power:SetStatusBarColor(barColor[1], barColor[2], barColor[3])

    if button.ppText then
        local textColor = POWER_COLORS[powerType] or POWER_COLORS[0]
        button.ppText:SetTextColor(textColor[1], textColor[2], textColor[3])
        button.ppText:SetText(powerMax and powerMax > 0 and tostring(power) or "")
    end

    local name = UnitName(unit) or ""
    if button.twilight == "big" then
        button.nameText:SetText(unit == "player" and "" or name)
        local r, g, b = 1, 1, 1
        if UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local color = class and RAID_CLASS_COLORS[class]
            if color then r, g, b = color.r, color.g, color.b end
        end
        button.nameText:SetTextColor(r, g, b)
    else
        local level = UnitLevel(unit)
        local suffix = ""
        if level and level ~= UnitLevel("player") then
            local color = GetQuestDifficultyColor(level > 0 and level or 99)
            suffix = string.format(" |cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, level > 0 and level or "??")
        end
        button.nameText:SetText(name .. suffix)
        button.nameText:SetTextColor(1, 1, 1)

        local role = Role(unit)
        if role and button.role then
            button.role:SetTexture(T.MEDIA .. ROLE_TEXTURES[role])
            button.role:Show()
        elseif button.role then
            button.role:Hide()
        end
    end

    local isLeader = (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) and UnitIsPartyLeader and UnitIsPartyLeader(unit)
    button.leader:SetShown(isLeader and true or false)

    local index = GetRaidTargetIndex(unit)
    if index then
        SetRaidTargetIconTexture(button.mark, index)
        button.mark:Show()
    else
        button.mark:Hide()
    end

    if button.twilight == "tile" and unit ~= "player" and UnitInRange then
        local inRange = UnitInRange(unit)
        button:SetAlpha((inRange or UnitIsUnit(unit, "player")) and 1 or 0.45)
    end

    if full and button.model then
        if UnitIsVisible(unit) then
            button.model:SetUnit(unit)
            button.model:SetCamera(0)
            button.model:Show()
        else
            button.model:Hide()
        end
    end
end

function T.UpdateRoles()
    for _, button in ipairs(buttons) do
        if button.role and button:IsVisible() then T.UpdateUnitButton(button, false) end
    end
end

local function UpdateAll(full)
    for _, button in ipairs(buttons) do
        if button:IsVisible() then T.UpdateUnitButton(button, full) end
    end
end

local function UpdateUnit(unit, full)
    for _, button in ipairs(buttons) do
        if UnitOf(button) == unit and button:IsVisible() then T.UpdateUnitButton(button, full) end
    end
end

local function SavedPoint(key, point, relativePoint, x, y)
    local saved = T.db.pos and T.db.pos[key]
    if saved then return saved[1], saved[2], saved[3], saved[4] end
    return point, relativePoint, x, y
end

local function Movable(frame, key, label)
    API:RegisterMover(frame, label, function(point, relativePoint, x, y)
        T.db.pos = T.db.pos or {}
        T.db.pos[key] = { point, relativePoint, x, y }
    end)
end

local function Place(frame, key, point, relativePoint, x, y)
    local p, r, px, py = SavedPoint(key, point, relativePoint, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(p, UIParent, r, px, py)
end

local function SingleFrame(name, unit, kind, width, height)
    local button = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
    button:SetAttribute("unit", unit)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button.unit = unit
    button:SetSize(width, height)
    button:SetFrameStrata("LOW")
    Decorate(button, kind)
    if unit ~= "player" then RegisterUnitWatch(button) end
    return button
end

local function AuraTime(seconds)
    if seconds >= 3600 then return math.floor(seconds / 3600 + 0.5) .. L("ч") end
    if seconds >= 60 then return math.floor(seconds / 60 + 0.5) .. L("м") end
    return tostring(math.floor(seconds + 0.5))
end

local function AuraIcon(parent, size)
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(size, size)
    icon:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    icon:SetBackdropColor(0, 0, 0, 1)
    icon:SetBackdropBorderColor(0, 0, 0, 1)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.texture)
    icon.cooldown:SetReverse(true)
    icon.cooldown.noCooldownCount = true
    if icon.cooldown.SetDrawEdge then icon.cooldown:SetDrawEdge(false) end
    local holder = CreateFrame("Frame", nil, icon)
    holder:SetAllPoints(icon)
    holder:SetFrameLevel(icon.cooldown:GetFrameLevel() + 2)
    icon.time = T.Text(holder, 14, "CENTER")
    icon.time:SetPoint("CENTER", icon, "CENTER", 0, 1)
    icon.count = T.Text(holder, 10, "RIGHT")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, 0)
    icon:RegisterForClicks("RightButtonUp")
    icon:SetScript("OnEnter", function(self)
        if not self.unit then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetUnitAura(self.unit, self.index, self.filter)
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    icon:SetScript("OnClick", function(self)
        if self.unit == "player" and self.filter == "HELPFUL" and not InCombatLockdown() then
            CancelUnitBuff("player", self.index, self.filter)
        end
    end)
    icon:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 0.2
        if not self.expires or self.expires <= 0 then
            self.time:SetText("")
            return
        end
        local left = self.expires - GetTime()
        if left <= 0 then self.time:SetText("") return end
        self.time:SetText(AuraTime(left))
        if left <= 5 then
            self.time:SetTextColor(0.95, 0.1, 0.1)
        elseif left < 60 then
            self.time:SetTextColor(1, 0.95, 0.2)
        else
            self.time:SetTextColor(1, 1, 1)
        end
    end)
    return icon
end

local function AuraRow(owner, unit, filter, size, max, onlyTimed)
    local row = CreateFrame("Frame", nil, owner)
    row:SetSize(size, size)
    row.icons = {}
    row.unit, row.filter, row.size, row.max, row.onlyTimed = unit, filter, size, max, onlyTimed

    function row:Update()
        local shown = 0
        for index = 1, 40 do
            local name, _, texture, count, debuffType, duration, expires = UnitAura(self.unit, index, self.filter)
            if not name then break end
            if not self.onlyTimed or (duration and duration > 0) then
                shown = shown + 1
                if shown > self.max then break end
                local icon = self.icons[shown]
                if not icon then
                    icon = AuraIcon(self, self.size)
                    icon:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", (shown - 1) * (self.size + 2), 0)
                    self.icons[shown] = icon
                end
                icon.unit, icon.index, icon.filter = self.unit, index, self.filter
                icon.texture:SetTexture(texture)
                icon.count:SetText(count and count > 1 and count or "")
                icon.expires = expires
                icon.wait = 0
                if duration and duration > 0 and expires then
                    icon.cooldown:SetCooldown(expires - duration, duration)
                    icon.cooldown:Show()
                else
                    icon.cooldown:Hide()
                end
                if self.filter == "HARMFUL" then
                    local color = DEBUFF_COLORS[debuffType or "none"] or DEBUFF_COLORS.none
                    icon:SetBackdropBorderColor(color[1], color[2], color[3], 1)
                else
                    icon:SetBackdropBorderColor(0, 0, 0, 1)
                end
                icon:Show()
            end
        end
        for index = math.max(1, shown + 1), #self.icons do
            if index > shown then self.icons[index]:Hide() end
        end
        self.count = math.min(shown, self.max)
        return self.count
    end

    auraFrames[#auraFrames + 1] = row
    return row
end

local function Auras(frame, unit)
    local buffs = AuraRow(frame, unit, "HELPFUL", 26, 9, unit == "player")
    buffs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 6)
    local debuffs = AuraRow(frame, unit, "HARMFUL", 26, 9, false)
    debuffs:SetPoint("BOTTOMLEFT", buffs, "TOPLEFT", 0, 4)
    frame.buffs, frame.debuffs = buffs, debuffs
end

local function UpdateAuras(unit)
    for _, row in ipairs(auraFrames) do
        if row.unit == unit and row:IsVisible() then row:Update() end
    end
end

local function BuildRaid()
    local header = CreateFrame("Frame", "NarciTwilight_Raid", UIParent, "SecureGroupHeaderTemplate")
    header:SetFrameStrata("LOW")
    header:SetAttribute("template", "SecureUnitButtonTemplate")
    header:SetAttribute("showPlayer", true)
    header:SetAttribute("showParty", true)
    header:SetAttribute("showRaid", true)
    header:SetAttribute("showSolo", false)
    header:SetAttribute("point", "LEFT")
    header:SetAttribute("xOffset", 6)
    header:SetAttribute("yOffset", 0)
    header:SetAttribute("unitsPerColumn", 5)
    header:SetAttribute("maxColumns", 8)
    header:SetAttribute("columnSpacing", 6)
    header:SetAttribute("columnAnchorPoint", "BOTTOMLEFT")
    header:SetAttribute("groupBy", "GROUP")
    header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
    header:SetAttribute("sortMethod", "INDEX")
    header.initialConfigFunction = function(button)
        button:SetAttribute("initial-width", 85)
        button:SetAttribute("initial-height", 30)
        button:SetAttribute("*type1", "target")
        button:SetAttribute("*type2", "togglemenu")
        Decorate(button, "tile")
    end
    header:SetSize(85, 30)
    Place(header, "raid", "BOTTOMLEFT", "BOTTOM", -217, 230)
    header:Show()
    Movable(header, "raid", L("Рейд-фреймы"))
    T.raidHeader = header
end

local BLIZZARD = {
    "PlayerFrame", "TargetFrame", "TargetFrameToT", "ComboFrame", "PetFrame",
    "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
    "PartyMemberBackground", "CompactPartyFrame", "CompactRaidFrameManager", "CompactRaidFrameContainer",
}

function T.BuildUnitFrames()
    if T.unitFramesBuilt or T.db.unitFrames == false then return end
    if InCombatLockdown() then
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            T.BuildUnitFrames()
        end)
        return
    end
    T.unitFramesBuilt = true

    for _, name in ipairs(BLIZZARD) do Kill(name) end
    if type(_G.HidePartyFrame) == "function" then pcall(_G.HidePartyFrame) end

    local player = SingleFrame("NarciTwilight_Player", "player", "big", 267, 43)
    Place(player, "player", "BOTTOMLEFT", "BOTTOM", -449, 165)
    Movable(player, "player", L("Игрок"))
    Auras(player, "player")

    local target = SingleFrame("NarciTwilight_Target", "target", "big", 267, 43)
    Place(target, "target", "BOTTOMRIGHT", "BOTTOM", 449, 165)
    Movable(target, "target", L("Цель"))
    Auras(target, "target")

    local tot = SingleFrame("NarciTwilight_TargetTarget", "targettarget", "tile", 85, 30)
    Place(tot, "tot", "BOTTOMLEFT", "BOTTOM", 455, 165)
    Movable(tot, "tot", L("Цель цели"))

    local pet = SingleFrame("NarciTwilight_Pet", "pet", "tile", 85, 30)
    Place(pet, "pet", "BOTTOMRIGHT", "BOTTOM", -455, 165)
    Movable(pet, "pet", L("Питомец"))

    BuildRaid()

    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER",
        "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXENERGY", "UNIT_MAXFOCUS", "UNIT_MAXRUNIC_POWER", "UNIT_DISPLAYPOWER",
        "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_AURA", "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE",
        "PLAYER_TARGET_CHANGED", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "PARTY_LEADER_CHANGED",
        "RAID_TARGET_UPDATE", "UNIT_PET", "PLAYER_ENTERING_WORLD",
    }) do events:RegisterEvent(event) end

    events:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" then
            UpdateAuras(unit)
            return
        end
        if event == "PLAYER_TARGET_CHANGED" then
            UpdateUnit("target", true)
            UpdateUnit("targettarget", true)
            UpdateAuras("target")
            return
        end
        if event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
            UpdateUnit(unit, true)
            return
        end
        if unit and event:find("^UNIT_") then
            UpdateUnit(unit, false)
            if unit == "target" then UpdateUnit("targettarget", false) end
            return
        end
        UpdateAll(true)
        UpdateAuras("player")
        UpdateAuras("target")
    end)

    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 0.25
        UpdateAll(false)
    end)

    UpdateAll(true)
    UpdateAuras("player")
end

API:AddTranslations("enUS", {
    ["Игрок"] = "Player",
    ["Цель"] = "Target",
    ["Цель цели"] = "Target of target",
    ["Питомец"] = "Pet",
    ["Рейд-фреймы"] = "Raid frames",
    ["Рамки игрока, цели и группы"] = "Player, target and group frames",
})
