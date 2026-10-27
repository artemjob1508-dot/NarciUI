local addonName, NS = ...
local L = NS.L

local EPGP = {}
NS.EPGP = EPGP

local DEFAULTS = {
    decay_p = 0,
    extras_p = 100,
    min_ep = 0,
    base_gp = 1,
}

local PATTERNS = {
    decay_p = "@DECAY_P:(%d+)",
    extras_p = "@EXTRAS_P:(%d+)",
    min_ep = "@MIN_EP:(%d+)",
    base_gp = "@BASE_GP:(%d+)",
}

local SLOT_HIGH = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 0.5,
    INVTYPE_SHOULDER = 0.75,
    INVTYPE_CHEST = 1,
    INVTYPE_ROBE = 1,
    INVTYPE_WAIST = 0.75,
    INVTYPE_LEGS = 1,
    INVTYPE_FEET = 0.75,
    INVTYPE_WRIST = 0.5,
    INVTYPE_HAND = 0.75,
    INVTYPE_FINGER = 0.5,
    INVTYPE_TRINKET = 0.75,
    INVTYPE_CLOAK = 0.5,
    INVTYPE_WEAPON = 1.5,
    INVTYPE_SHIELD = 1.5,
    INVTYPE_2HWEAPON = 2,
    INVTYPE_WEAPONMAINHAND = 1.5,
    INVTYPE_WEAPONOFFHAND = 0.5,
    INVTYPE_HOLDABLE = 0.5,
    INVTYPE_RANGED = 1.5,
    INVTYPE_RANGEDRIGHT = 1.5,
    INVTYPE_THROWN = 0.5,
    INVTYPE_RELIC = 0.5,
}

local SLOT_LOW = {
    INVTYPE_WEAPON = 0.5,
    INVTYPE_SHIELD = 0.5,
    INVTYPE_2HWEAPON = 1,
    INVTYPE_RANGED = 0.5,
    INVTYPE_RANGEDRIGHT = 0.5,
}

EPGP.config = {}
for key, value in pairs(DEFAULTS) do EPGP.config[key] = value end

function EPGP:ParseConfig()
    local config = self.config
    for key, value in pairs(DEFAULTS) do config[key] = value end

    local info = GetGuildInfoText and GetGuildInfoText() or ""
    if not info or info == "" then return config end

    local inBlock = false

    for line in string.gmatch(info, "[^\n]+") do
        if string.find(line, "^%-EPGP%-") then
            inBlock = not inBlock
        elseif inBlock then
            for key, pattern in pairs(PATTERNS) do
                local value = string.match(line, pattern)
                if value then config[key] = tonumber(value) end
            end
        end
    end

    return config
end

local function DecodeNote(note)
    if not note then return nil end
    if note == "" then return 0, 0 end

    local ep, gp = string.match(note, "^(%d+),(%d+)$")
    if ep then return tonumber(ep), tonumber(gp) end
    return nil
end

function EPGP:Scan()
    local roster = {}
    local order = {}

    if not IsInGuild or not IsInGuild() then
        self.roster, self.order = roster, order
        return roster, order
    end

    self:ParseConfig()

    local reader = GetGuildRosterInfoEx or GetGuildRosterInfo
    local total = GetNumGuildMembers and GetNumGuildMembers() or 0

    for index = 1, total do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, baseIndex = reader(index)
        if name then
            roster[name] = {
                name = name,
                rank = rank,
                rankIndex = rankIndex or 0,
                level = level or 0,
                class = class,
                online = online and true or false,
                officerNote = officerNote or "",
                baseIndex = baseIndex or index,
            }
            order[#order + 1] = name
        end
    end

    local base = self.config.base_gp

    for _, name in ipairs(order) do
        local member = roster[name]
        local ep, gp = DecodeNote(member.officerNote)

        if ep then
            member.ep = ep
            member.gp = gp + base
        else
            member.mainName = member.officerNote ~= "" and member.officerNote or nil
        end
    end

    for _, name in ipairs(order) do
        local member = roster[name]
        local main = member.mainName and roster[member.mainName]

        if member.mainName and (not main or not main.ep) then
            member.mainName = nil
            member.ignored = true
        elseif main then
            main.alts = main.alts or {}
            main.alts[#main.alts + 1] = name
        end
    end

    self.roster, self.order = roster, order
    return roster, order
end

function EPGP:Member(name)
    if not self.roster then self:Scan() end
    return self.roster and self.roster[name]
end

function EPGP:MainOf(name)
    local member = self:Member(name)
    if not member then return nil end
    if member.mainName then return self:Member(member.mainName) end
    if member.ep then return member end
    return nil
end

function EPGP:GetEPGP(name)
    local main = self:MainOf(name)
    if not main then return nil end
    return main.ep or 0, main.gp or self.config.base_gp, main.name
end

function EPGP:PR(ep, gp)
    if not ep or not gp or gp <= 0 then return 0 end
    return ep / gp
end

function EPGP:Standings()
    self:Scan()

    local standings = {}
    for _, name in ipairs(self.order or {}) do
        local member = self.roster[name]
        if member.ep then
            member.pr = self:PR(member.ep, member.gp)
            member.qualified = member.ep >= (self.config.min_ep or 0)
            standings[#standings + 1] = member
        end
    end

    table.sort(standings, function(left, right)
        if left.pr == right.pr then return left.name < right.name end
        return left.pr > right.pr
    end)

    return standings
end

function EPGP:CanWrite()
    return CanEditOfficerNote and CanEditOfficerNote() and true or false
end

function EPGP:WriteNote(member, ep, gp)
    if not member or not member.baseIndex then return false end
    if not self:CanWrite() then
        NS.Print(L["нет права редактировать заметки офицера"])
        return false
    end
    if InCombatLockdown() then
        NS.Print(L["в бою заметки не меняются"])
        return false
    end

    local stored = math.max(gp - self.config.base_gp, 0)
    local note = string.format("%d,%d", math.max(ep, 0), stored)

    local ok = pcall(GuildRosterSetOfficerNote, member.baseIndex, note)
    if not ok then
        NS.Print(L["не удалось записать заметку офицера"])
        return false
    end

    member.ep = math.max(ep, 0)
    member.gp = stored + self.config.base_gp
    member.officerNote = note

    return true
end

function EPGP:Log()
    NS.db.epgpLog = NS.db.epgpLog or {}
    return NS.db.epgpLog
end

function EPGP:Record(entries, reason)
    if #entries == 0 then return end

    local log = self:Log()
    log[#log + 1] = { reason = reason, time = time(), entries = entries }

    while #log > 50 do table.remove(log, 1) end
end

function EPGP:AddEPGP(name, epDelta, gpDelta)
    local main = self:MainOf(name)
    if not main then return nil end

    local ep = (main.ep or 0) + (epDelta or 0)
    local gp = (main.gp or self.config.base_gp) + (gpDelta or 0)

    if ep < 0 then
        epDelta = -(main.ep or 0)
        ep = 0
    end
    if gp < self.config.base_gp then
        gpDelta = self.config.base_gp - (main.gp or self.config.base_gp)
        gp = self.config.base_gp
    end

    if not self:WriteNote(main, ep, gp) then return nil end
    return main.name, epDelta, gpDelta
end

function EPGP:IncEPBy(name, amount, reason, batch)
    local target, ep = self:AddEPGP(name, amount, 0)
    if not target then return false end

    local entry = { name = target, ep = ep or amount, gp = 0 }
    if batch then
        batch[#batch + 1] = entry
    else
        self:Record({ entry }, reason or L["Начисление EP"])
    end

    return true
end

function EPGP:IncGPBy(name, amount, reason, batch)
    local target, _, gp = self:AddEPGP(name, 0, amount)
    if not target then return false end

    local entry = { name = target, ep = 0, gp = gp or amount }
    if batch then
        batch[#batch + 1] = entry
    else
        self:Record({ entry }, reason or L["Начисление GP"])
    end

    return true
end

function EPGP:RaidNames()
    local names = {}
    local raid = GetNumRaidMembers and GetNumRaidMembers() or 0

    if raid > 0 then
        for index = 1, raid do
            local name = GetRaidRosterInfo(index)
            if name then names[#names + 1] = name end
        end
        return names
    end

    local party = GetNumPartyMembers and GetNumPartyMembers() or 0
    names[#names + 1] = UnitName("player")
    for index = 1, party do
        local name = UnitName("party" .. index)
        if name then names[#names + 1] = name end
    end

    return names
end

function EPGP:MassEP(amount, reason)
    self:Scan()

    local batch = {}
    local awarded = 0

    for _, name in ipairs(self:RaidNames()) do
        if self:MainOf(name) then
            if self:IncEPBy(name, amount, reason, batch) then
                awarded = awarded + 1
            end
        end
    end

    self:Record(batch, reason or L["Начисление EP рейду"])
    return awarded
end

function EPGP:Decay()
    self:Scan()

    local percent = self.config.decay_p or 0
    if percent <= 0 then
        NS.Print(L["процент спада не задан в информации гильдии"])
        return 0
    end

    local factor = 1 - percent * 0.01
    local batch = {}
    local changed = 0

    for _, member in ipairs(self:Standings()) do
        local ep = math.floor((member.ep or 0) * factor)
        local gp = math.floor((member.gp or self.config.base_gp) * factor)
        if gp < self.config.base_gp then gp = self.config.base_gp end

        local epDelta = ep - (member.ep or 0)
        local gpDelta = gp - (member.gp or self.config.base_gp)

        if (epDelta ~= 0 or gpDelta ~= 0) and self:WriteNote(member, ep, gp) then
            batch[#batch + 1] = { name = member.name, ep = epDelta, gp = gpDelta }
            changed = changed + 1
        end
    end

    self:Record(batch, string.format(L["Спад %d%%"], percent))
    return changed
end

function EPGP:CutEP(percent)
    self:Scan()

    if not percent or percent <= 0 or percent > 100 then
        NS.Print(L["процент среза должен быть от 1 до 100"])
        return 0
    end

    local factor = 1 - percent * 0.01
    local batch = {}
    local changed = 0

    for _, member in ipairs(self:Standings()) do
        local ep = math.floor((member.ep or 0) * factor)
        local delta = ep - (member.ep or 0)

        if delta ~= 0 and self:WriteNote(member, ep, member.gp or self.config.base_gp) then
            batch[#batch + 1] = { name = member.name, ep = delta, gp = 0 }
            changed = changed + 1
        end
    end

    self:Record(batch, string.format(L["Срез EP %d%%"], percent))
    return changed
end

function EPGP:Undo()
    local log = self:Log()
    local last = log[#log]

    if not last then
        NS.Print(L["нечего отменять"])
        return false
    end

    self:Scan()

    for _, entry in ipairs(last.entries) do
        self:AddEPGP(entry.name, -(entry.ep or 0), -(entry.gp or 0))
    end

    table.remove(log, #log)
    NS.Print(string.format(L["отменено: %s"], last.reason or "?"))
    return true
end

function EPGP:GearPoints(itemLink)
    if not itemLink then return nil end

    local _, link, rarity, level, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    if not link or not rarity or not level then return nil end
    if rarity < 3 then return nil end

    local high = SLOT_HIGH[equipSlot]
    if not high then return nil end

    local base = 0.483 * 2 ^ (level / 26 + (rarity - 4))
    local low = SLOT_LOW[equipSlot]

    return math.floor(base * high), low and math.floor(base * low) or nil, level, rarity
end
