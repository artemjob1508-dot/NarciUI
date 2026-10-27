local addonName, NS = ...

local HP = {}
NS.HealPrediction = HP

local WHITE = "Interface\\Buttons\\WHITE8x8"
local BAND = 3

local DEFAULTS = {
    hots = true,
    absorbs = true,
    healAbsorbs = true,
    myColor = { 0.30, 0.95, 0.45, 0.55 },
    otherColor = { 0.20, 0.75, 0.35, 0.45 },
    absorbColor = { 0.80, 0.92, 1.00, 0.45 },
    healAbsorbColor = { 0.85, 0.15, 0.15, 0.60 },
}

HP.DEFAULTS = DEFAULTS

local lib
local watchers = {}

function HP:Settings()
    if not NS.db then return DEFAULTS end
    if type(NS.db.healPredict) ~= "table" then NS.db.healPredict = {} end
    local db = NS.db.healPredict
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = { value[1], value[2], value[3], value[4] }
            else
                db[key] = value
            end
        end
    end
    return db
end

local function Lib()
    if lib == nil then
        lib = (LibStub and LibStub("LibHealComm-4.0", true)) or false
    end
    return lib or nil
end

function HP:Available()
    return Lib() ~= nil
end

function HP:Incoming(unit)
    local comm = Lib()
    if not comm or not unit then return 0, 0 end
    local guid = UnitGUID(unit)
    if not guid then return 0, 0 end

    local db = self:Settings()
    local flag = db.hots and comm.ALL_HEALS or comm.CASTED_HEALS
    local band = GetTime() + BAND
    local modifier = comm:GetHealModifier(guid) or 1
    local all = (comm:GetHealAmount(guid, flag, band) or 0) * modifier
    local mine = (comm:GetHealAmount(guid, flag, band, UnitGUID("player")) or 0) * modifier
    if mine > all then mine = all end
    return mine, all - mine
end

function HP:Absorbs(unit)
    local db = self:Settings()
    local absorb, healAbsorb = 0, 0
    if db.absorbs and type(UnitGetTotalAbsorbs) == "function" then
        local ok, value = pcall(UnitGetTotalAbsorbs, unit)
        absorb = ok and tonumber(value) or 0
    end
    if db.healAbsorbs and type(UnitGetTotalHealAbsorbs) == "function" then
        local ok, value = pcall(UnitGetTotalHealAbsorbs, unit)
        healAbsorb = ok and tonumber(value) or 0
    end
    return absorb, healAbsorb
end

local function Piece(bar, sublevel)
    local texture = bar:CreateTexture(nil, "ARTWORK")
    texture:SetDrawLayer("ARTWORK", sublevel)
    texture:SetTexture(WHITE)
    texture:Hide()
    return texture
end

function HP:Attach(bar)
    local set = {
        bar = bar,
        mine = Piece(bar, 1),
        other = Piece(bar, 1),
        absorb = Piece(bar, 2),
        healAbsorb = Piece(bar, 3),
    }

    local over = bar:CreateTexture(nil, "OVERLAY")
    over:SetTexture(WHITE)
    over:SetBlendMode("ADD")
    over:Hide()
    set.over = over

    return set
end

local function Place(texture, fill, offset, size, vertical, backward)
    if size < 1 then
        texture:Hide()
        return
    end
    texture:ClearAllPoints()
    if vertical then
        if backward then
            texture:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
            texture:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
        else
            texture:SetPoint("BOTTOMLEFT", fill, "TOPLEFT", 0, offset)
            texture:SetPoint("BOTTOMRIGHT", fill, "TOPRIGHT", 0, offset)
        end
        texture:SetHeight(size)
    else
        if backward then
            texture:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
            texture:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
        else
            texture:SetPoint("TOPLEFT", fill, "TOPRIGHT", offset, 0)
            texture:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", offset, 0)
        end
        texture:SetWidth(size)
    end
    texture:Show()
end

local function Tint(texture, color)
    texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
end

function HP:Clear(set)
    if not set then return end
    set.mine:Hide()
    set.other:Hide()
    set.absorb:Hide()
    set.healAbsorb:Hide()
    set.over:Hide()
end

function HP:Paint(set, unit, health, maxHealth, vertical, heals)
    if not set then return end
    if not unit or not maxHealth or maxHealth <= 0 or UnitIsDeadOrGhost(unit) then
        self:Clear(set)
        return
    end

    local db = self:Settings()
    local bar = set.bar
    local fill = bar:GetStatusBarTexture()
    local length = (vertical and bar:GetHeight() or bar:GetWidth()) or 0
    if length <= 0 then
        self:Clear(set)
        return
    end

    local mine, other = 0, 0
    if heals ~= false then mine, other = self:Incoming(unit) end
    local absorb, healAbsorb = self:Absorbs(unit)

    health = math.min(health or 0, maxHealth)
    local room = maxHealth - health
    local scale = length / maxHealth

    mine = math.min(mine, room)
    other = math.min(other, room - mine)
    local left = room - mine - other
    local shownAbsorb = math.min(absorb, left)

    Tint(set.mine, db.myColor)
    Tint(set.other, db.otherColor)
    Tint(set.absorb, db.absorbColor)
    Tint(set.healAbsorb, db.healAbsorbColor)

    local mineSize = mine * scale
    local otherSize = other * scale
    Place(set.mine, fill, 0, mineSize, vertical)
    Place(set.other, fill, mineSize, otherSize, vertical)
    Place(set.absorb, fill, mineSize + otherSize, shownAbsorb * scale, vertical)
    Place(set.healAbsorb, fill, 0, math.min(healAbsorb, health) * scale, vertical, true)

    if absorb > left and absorb > 0 then
        local color = db.absorbColor
        set.over:ClearAllPoints()
        if vertical then
            set.over:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
            set.over:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
            set.over:SetHeight(2)
        else
            set.over:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
            set.over:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
            set.over:SetWidth(2)
        end
        set.over:SetVertexColor(color[1], color[2], color[3], 0.9)
        set.over:Show()
    else
        set.over:Hide()
    end
end

function HP:Watch(fn)
    watchers[#watchers + 1] = fn
end

local function Fire(guids)
    for _, fn in ipairs(watchers) do
        pcall(fn, guids)
    end
end

local pending = {}
local flushing = false
local flusher = CreateFrame("Frame")
flusher:Hide()
flusher:SetScript("OnUpdate", function(self)
    self:Hide()
    flushing = false
    local guids = pending
    pending = {}
    Fire(guids)
end)

local function Queue(guid)
    if not guid then return end
    pending[guid] = true
    if not flushing then
        flushing = true
        flusher:Show()
    end
end

local function OnHeal(_, _, _, _, _, ...)
    for index = 1, select("#", ...) do
        Queue((select(index, ...)))
    end
end

local function OnModifier(_, guid)
    Queue(guid)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
pcall(events.RegisterEvent, events, "UNIT_ABSORB_AMOUNT_CHANGED")
pcall(events.RegisterEvent, events, "UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        HP:Settings()
        local comm = Lib()
        if comm and comm.RegisterCallback then
            comm.RegisterCallback(HP, "HealComm_HealStarted", OnHeal)
            comm.RegisterCallback(HP, "HealComm_HealUpdated", OnHeal)
            comm.RegisterCallback(HP, "HealComm_HealDelayed", OnHeal)
            comm.RegisterCallback(HP, "HealComm_HealStopped", OnHeal)
            comm.RegisterCallback(HP, "HealComm_ModifierChanged", OnModifier)
            comm.RegisterCallback(HP, "HealComm_GUIDDisappeared", OnModifier)
        end
        return
    end
    if unit then Queue(UnitGUID(unit)) end
end)
