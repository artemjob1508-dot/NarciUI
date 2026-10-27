local addonName, NS = ...
local L = NS.L

local GuildAdmin = {}
NS.GuildAdmin = GuildAdmin

local CHECK_INTERVAL = 5
local RANK_STEP_DELAY = 1

local function Settings()
    NS.db.guildAdmin = NS.db.guildAdmin or {}
    local settings = NS.db.guildAdmin
    settings.mutes = settings.mutes or {}
    return settings
end

function GuildAdmin:Settings()
    return Settings()
end

function GuildAdmin:Notify(message)
    local settings = Settings()
    if settings.notify and UIErrorsFrame then
        UIErrorsFrame:AddMessage(message, 1, 0.6, 0.2, 1)
    end
    NS.Print(message)
end

function GuildAdmin:Ranks()
    local ranks = {}
    if not GuildControlGetNumRanks or not IsInGuild or not IsInGuild() then
        return ranks, 0
    end

    local num = GuildControlGetNumRanks() or 0
    for index = 0, num - 1 do
        ranks[index] = GuildControlGetRankName(index + 1) or ("#" .. index)
    end

    return ranks, num
end

local function PlainName(name)
    if not name then return nil end
    return (string.gsub(name, "%-.*", ""))
end

function GuildAdmin:Members()
    local members = {}
    if not IsInGuild or not IsInGuild() then return members end

    local reader = GetGuildRosterInfoEx or GetGuildRosterInfo
    local total = GetNumGuildMembers and GetNumGuildMembers() or 0

    for index = 1, total do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, baseIndex = reader(index)
        if name then
            members[#members + 1] = {
                fullName = name,
                name = PlainName(name),
                rank = rank,
                rankIndex = rankIndex or 0,
                level = level or 0,
                class = class,
                zone = zone,
                note = note or "",
                officerNote = officerNote or "",
                online = online and true or false,
                index = (type(baseIndex) == "number" and baseIndex) or index,
            }
        end
    end

    return members
end

function GuildAdmin:Find(name)
    if not name or name == "" then return nil end
    local wanted = NS.Lower(PlainName(name))

    for _, member in ipairs(self:Members()) do
        if NS.Lower(member.name) == wanted then return member end
    end

    return nil
end

function GuildAdmin:CanManage()
    if not IsInGuild or not IsInGuild() then return false end
    return CanEditOfficerNote and CanEditOfficerNote() and true or false
end

function GuildAdmin:SetNote(name, text, officer)
    local member = self:Find(name)
    if not member then
        self:Notify(L["Игрок не найден в гильдии"])
        return false
    end

    if officer then
        if not (CanEditOfficerNote and CanEditOfficerNote()) then
            self:Notify(L["нет права редактировать заметки офицера"])
            return false
        end
    elseif CanEditPublicNote and not CanEditPublicNote() then
        self:Notify(L["нет права редактировать публичные заметки"])
        return false
    end

    if SetGuildRosterSelection then pcall(SetGuildRosterSelection, member.index) end

    local setter = officer and GuildRosterSetOfficerNote or GuildRosterSetPublicNote
    if not setter then return false end

    local ok = pcall(setter, member.index, text or "")
    if not ok then
        self:Notify(L["не удалось записать заметку"])
        return false
    end

    if GuildRoster then GuildRoster() end
    return true
end

function GuildAdmin:ChangeRank(name, targetRankIndex)
    local member = self:Find(name)
    if not member then
        self:Notify(L["Игрок не найден в гильдии"])
        return false
    end

    if not targetRankIndex or member.rankIndex == targetRankIndex then return false end

    local steps = targetRankIndex - member.rankIndex
    local promote = steps < 0
    local count = math.abs(steps)

    if promote and CanGuildPromote and not CanGuildPromote() then
        self:Notify(L["нет права повышать в гильдии"])
        return false
    end

    if not promote and CanGuildDemote and not CanGuildDemote() then
        self:Notify(L["нет права понижать в гильдии"])
        return false
    end

    for step = 1, count do
        NS.After(step * RANK_STEP_DELAY, function()
            if promote then
                if GuildPromote then GuildPromote(member.fullName) end
            else
                if GuildDemote then GuildDemote(member.fullName) end
            end
        end)
    end

    NS.After((count + 1) * RANK_STEP_DELAY, function()
        if GuildRoster then GuildRoster() end
        if NS.GuildPanel and NS.GuildPanel.frame and NS.GuildPanel.frame:IsShown() then
            NS.GuildPanel:Update()
        end
    end)

    return true
end

function GuildAdmin:Kick(name)
    local member = self:Find(name)
    if not member then
        self:Notify(L["Игрок не найден в гильдии"])
        return false
    end

    if member.name == PlainName(UnitName("player")) then
        self:Notify(L["нельзя исключить себя"])
        return false
    end

    if CanGuildRemove and not CanGuildRemove() then
        self:Notify(L["нет права исключать из гильдии"])
        return false
    end

    if not GuildUninvite then return false end

    GuildUninvite(member.fullName)
    self:Notify(string.format(L["исключен: %s"], member.name))

    NS.After(2, function()
        if GuildRoster then GuildRoster() end
    end)

    return true
end

function GuildAdmin:MuteRecord(mutedBy, minutes, reason)
    local record = string.format("%s %s %dm", date("%d.%m %H:%M"), string.sub(mutedBy or "?", 1, 3), minutes)

    if reason and reason ~= "" then
        local word = string.match(reason, "(%S+)") or ""
        if word ~= "" and #record + #word + 1 <= 31 then
            record = record .. " " .. word
        end
    end

    return string.sub(record, 1, 31)
end

function GuildAdmin:Mute(name, minutes, reason)
    local settings = Settings()

    if not self:CanManage() then
        self:Notify(L["нет права редактировать заметки офицера"])
        return false
    end

    local member = self:Find(name)
    if not member then
        self:Notify(L["Игрок не найден в гильдии"])
        return false
    end

    local me = self:Find(UnitName("player"))
    if me and member.fullName == me.fullName then
        self:Notify(L["нельзя замутить себя"])
        return false
    end

    if me and member.rankIndex < me.rankIndex then
        self:Notify(L["нельзя замутить игрока с высшим рангом"])
        return false
    end

    if settings.mutes[member.name] then
        self:Notify(L["игрок уже замучен"])
        return false
    end

    if member.rankIndex == settings.muteRank then
        self:Notify(L["игрок уже имеет ранг мута"])
        return false
    end

    if not minutes or minutes <= 0 then
        self:Notify(L["укажите время в минутах"])
        return false
    end

    local mutedBy = PlainName(UnitName("player"))

    settings.mutes[member.name] = {
        fullName = member.fullName,
        originalRank = member.rankIndex,
        originalNote = member.officerNote or "",
        startTime = time(),
        expireTime = time() + minutes * 60,
        reason = reason or "",
        mutedBy = mutedBy,
        guild = GetGuildInfo and GetGuildInfo("player") or nil,
    }

    if not self:ChangeRank(member.name, settings.muteRank) then
        settings.mutes[member.name] = nil
        return false
    end

    if settings.useOfficerNotes then
        local record = self:MuteRecord(mutedBy, minutes, reason)
        NS.After(3, function() GuildAdmin:SetNote(member.name, record, true) end)
    end

    self:Notify(string.format(L["%s замучен на %d мин., размут в %s"],
        member.name, minutes, date("%H:%M:%S", time() + minutes * 60)))

    self:StartTicker()
    return true
end

function GuildAdmin:Unmute(name)
    local settings = Settings()
    local key = PlainName(name)
    local mute = settings.mutes[key]

    if not mute then
        self:Notify(L["игрок не замучен"])
        return false
    end

    settings.mutes[key] = nil

    self:ChangeRank(key, mute.originalRank)

    if settings.useOfficerNotes then
        local note = mute.originalNote or ""
        NS.After(3, function() GuildAdmin:SetNote(key, note, true) end)
    end

    self:Notify(string.format(L["%s размучен"], key))
    return true
end

function GuildAdmin:MuteOf(name)
    return Settings().mutes[PlainName(name)]
end

function GuildAdmin:ActiveMutes()
    local settings = Settings()
    local list = {}

    for name, mute in pairs(settings.mutes) do
        list[#list + 1] = {
            name = name,
            reason = mute.reason,
            mutedBy = mute.mutedBy,
            expireTime = mute.expireTime,
            startTime = mute.startTime,
            remaining = math.max(0, (mute.expireTime or 0) - time()),
        }
    end

    table.sort(list, function(left, right) return left.remaining < right.remaining end)
    return list
end

function GuildAdmin:CountMutes()
    local count = 0
    for _ in pairs(Settings().mutes) do count = count + 1 end
    return count
end

function GuildAdmin:StartTicker()
    if self.ticker then return end

    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, delta)
        self.elapsed = self.elapsed + delta
        if self.elapsed < CHECK_INTERVAL then return end
        self.elapsed = 0
        GuildAdmin:CheckExpired()
    end)

    self.ticker = frame
end

function GuildAdmin:CheckExpired()
    local settings = Settings()
    local now = time()
    local expired = {}

    if not self:CanManage() then return end
    local guild = GetGuildInfo and GetGuildInfo("player")

    for name, mute in pairs(settings.mutes) do
        local mine = (not mute.guild or mute.guild == guild) and self:Find(name)
        if mine and (mute.expireTime or 0) <= now then expired[#expired + 1] = name end
    end

    for _, name in ipairs(expired) do
        self:Unmute(name)
    end

    if #expired > 0 and NS.GuildPanel and NS.GuildPanel.frame and NS.GuildPanel.frame:IsShown() then
        NS.GuildPanel:Update()
    end
end

function GuildAdmin:Restore()
    local restored = self:CountMutes()

    if restored > 0 then
        NS.Print(string.format(L["восстановлено активных мутов: %d"], restored))
    end

    self:StartTicker()
end

function GuildAdmin:DaysOffline(index, online)
    if online then return 0 end
    if not GetGuildRosterLastOnline then return 0 end

    local years, months, days = GetGuildRosterLastOnline(index)
    return (years or 0) * 365 + (months or 0) * 30 + (days or 0)
end

function GuildAdmin:FindInactive(days, maxLevel, ranks, excludePublic, excludeOfficer)
    local candidates = {}
    if not IsInGuild or not IsInGuild() then return candidates end

    local allowed = {}
    local anyRank = true
    for _, rank in ipairs(ranks or {}) do
        allowed[rank] = true
        anyRank = false
    end

    for _, member in ipairs(self:Members()) do
        local rankPass = anyRank or allowed[member.rankIndex]
        local levelPass = member.level <= (maxLevel or 80)
        local notePass = not (excludePublic and member.note ~= "")
            and not (excludeOfficer and member.officerNote ~= "")

        if rankPass and levelPass and notePass and not member.online then
            local offline = self:DaysOffline(member.index, member.online)
            if offline >= (days or 30) then
                member.daysOffline = offline
                candidates[#candidates + 1] = member
            end
        end
    end

    table.sort(candidates, function(left, right)
        if left.daysOffline == right.daysOffline then return left.name < right.name end
        return left.daysOffline > right.daysOffline
    end)

    return candidates
end

function GuildAdmin:RemoveBatch(names, onStep, onDone)
    local removed, skipped = 0, 0

    local function step(index)
        if index > #names then
            if GuildRoster then GuildRoster() end
            if onDone then onDone(removed, skipped) end
            return
        end

        local member = self:Find(names[index])
        if member and member.rankIndex > 0 then
            if GuildUninvite then GuildUninvite(member.fullName) end
            removed = removed + 1
            NS.Print(string.format(L["удален: %s (%d дн. оффлайн)"],
                member.name, self:DaysOffline(member.index, member.online)))
        else
            skipped = skipped + 1
        end

        if onStep then onStep(index, #names) end
        NS.After(1, function() step(index + 1) end)
    end

    step(1)
end

NS.GuildAdmin = GuildAdmin
