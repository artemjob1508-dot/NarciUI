local addonName, ns = ...
ns.Twilight = ns.Twilight or {}
local T = ns.Twilight

local API = T.API
if not API then return end

API:AddNameplateStyle({
    key = "twilight", name = "Сумерки",
    width = 107, height = 6, texture = "flat", border = "pixel",
    nameAt = "above", nameAlign = "LEFT", hpAt = "outside", level = "header",
    nameSize = 9, nameColor = "grey",
})

local function PlateText(p)
    if not p or not p.hp or not p.health then return end
    local db = API:GetSetting("nameplates")
    if not db or db.style ~= "twilight" then return end
    p.hp:ClearAllPoints()
    p.hp:SetPoint("TOPLEFT", p.health, "BOTTOMRIGHT", 5, 3)
    p.hp:SetJustifyH("LEFT")
    p.hp:SetFont(T.FONT, 9, "OUTLINE")
    if p.name then p.name:SetFont(T.FONT, 9, "OUTLINE") end
    if p.level then p.level:SetFont(T.FONT, 9, "OUTLINE") end
end

local AURA_COLORS = {
    days = { 0.4, 0.4, 1 },
    hours = { 0.4, 1, 1 },
    minutes = { 1, 1, 1 },
    seconds = { 1, 1, 0 },
    expiring = { 1, 0, 0 },
}

local function AuraDuration(button, timeLeft)
    local duration = button and button.narciDuration
    if not duration or not timeLeft or timeLeft <= 0 then return end
    local text, color
    if timeLeft >= 86400 then
        text, color = math.floor(timeLeft / 86400 + 0.5) .. "d", AURA_COLORS.days
    elseif timeLeft >= 3600 then
        text, color = math.floor(timeLeft / 3600 + 0.5) .. "h", AURA_COLORS.hours
    elseif timeLeft >= 60 then
        text, color = math.floor(timeLeft / 60 + 0.5) .. "m", AURA_COLORS.minutes
    elseif timeLeft > 4 then
        text, color = math.floor(timeLeft + 0.5) .. "s", AURA_COLORS.seconds
    else
        text, color = string.format("%.1fs", timeLeft), AURA_COLORS.expiring
    end
    duration:SetFont(T.FONT, 12, "OUTLINE")
    duration:SetText(text)
    duration:SetTextColor(color[1], color[2], color[3])
end

local function Tracker()
    local frame = _G.ObjectiveTrackerFrame
    if not frame or T.trackerDone then return end
    T.trackerDone = true

    for size = 12, 22 do
        local font = _G["ObjectiveTrackerFont" .. size]
        if font and font.SetFont then font:SetFont(T.FONT, size - 1, "OUTLINE") end
    end
    for _, name in ipairs({ "ObjectiveTrackerLineFont", "ObjectiveTrackerHeaderFont" }) do
        local font = _G[name]
        if font and font.SetShadowOffset then font:SetShadowOffset(0, 0) end
    end

    local manager = _G.ObjectiveTrackerManager
    if manager then
        if manager.SetOpacity then pcall(manager.SetOpacity, manager, 0) end
        if manager.SetHeaderAlpha then pcall(manager.SetHeaderAlpha, manager, 0) end
        if manager.UpdateAll then pcall(manager.UpdateAll, manager) end
    end

    if InCombatLockdown() then return end
    frame:SetMovable(true)
    frame:SetUserPlaced(true)
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -8, -250)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 180)
end

local function DetailsInstances()
    local details = _G._detalhes
    if type(details) ~= "table" or type(details.tabela_instancias) ~= "table" then return end
    return details.tabela_instancias
end

function T.HideDetails()
    local restore = T.db.hideDetails ~= true
    if restore and type(T.db.detailsClosed) ~= "table" then return end
    local tries = 0
    local waiter = CreateFrame("Frame")
    waiter:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 1
        tries = tries + 1
        local list = DetailsInstances()
        if list and #list > 0 and restore then
            T.RestoreDetails()
            self:SetScript("OnUpdate", nil)
        elseif list and #list > 0 then
            T.db.detailsClosed = T.db.detailsClosed or {}
            for index, instance in ipairs(list) do
                if instance.baseframe and instance.IsEnabled and instance:IsEnabled() then
                    T.db.detailsClosed[index] = true
                    pcall(instance.ShutDown, instance)
                end
            end
            if tries >= 5 then self:SetScript("OnUpdate", nil) end
        elseif tries > 30 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end

function T.RestoreDetails()
    local list = DetailsInstances()
    if not list or type(T.db.detailsClosed) ~= "table" then return end
    for index in pairs(T.db.detailsClosed) do
        local instance = list[index]
        if instance and instance.EnableInstance then pcall(instance.EnableInstance, instance) end
    end
    T.db.detailsClosed = nil
end

local FOREIGN = { "TomTomBlock" }

function T.HideForeign()
    local tries = 0
    local waiter = CreateFrame("Frame")
    waiter:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 1
        tries = tries + 1
        for _, name in ipairs(FOREIGN) do
            local frame = _G[name]
            if frame and not frame.narciTwilightHidden then
                frame.narciTwilightHidden = true
                frame:HookScript("OnShow", function(shown) shown:Hide() end)
                frame:Hide()
            end
        end
        if tries > 30 then self:SetScript("OnUpdate", nil) end
    end)
end

function T.BuildExtras()
    T.HideDetails()
    T.HideForeign()
    API:Hook("nameplate", PlateText, T.NAME)
    API:Hook("auraduration", AuraDuration, T.NAME)
    API:RefreshLook("nameplates")
    if T.db.tracker ~= false then
        API:After(2, Tracker)
    end
end

API:AddTranslations("enUS", {
    ["Сумерки"] = "Twilight",
    ["Трекер заданий справа"] = "Objective tracker on the right",
})
