local addonName, NS = ...
local L = NS.L

local Auto = {}
NS.AutoAccept = Auto

local function Settings()
    if not NS.db then return end
    if type(NS.db.autoAccept) ~= "table" then NS.db.autoAccept = {} end
    local db = NS.db.autoAccept
    if db.invite == nil then db.invite = false end
    if db.friends == nil then db.friends = true end
    if db.guild == nil then db.guild = true end
    if db.notQueued == nil then db.notQueued = true end
    if db.summon == nil then db.summon = false end
    if db.summonFrom == nil then db.summonFrom = "group" end
    db.summonDelay = db.summonDelay or 0
    if db.announce == nil then db.announce = true end
    return db
end

Auto.Settings = Settings

local function Bare(name)
    if type(name) ~= "string" then return end
    return (name:gsub("%-.*$", ""))
end

local function IsFriend(name)
    for index = 1, (GetNumFriends and GetNumFriends() or 0) do
        if Bare(GetFriendInfo(index)) == name then return true end
    end
    return false
end

local function IsGuildmate(name)
    if not IsInGuild or not IsInGuild() then return false end
    for index = 1, (GetNumGuildMembers and GetNumGuildMembers(true) or 0) do
        if Bare(GetGuildRosterInfo(index)) == name then return true end
    end
    return false
end

local function IsGroupMember(name)
    for index = 1, (GetNumRaidMembers and GetNumRaidMembers() or 0) do
        if Bare(UnitName("raid" .. index)) == name then return true end
    end
    for index = 1, (GetNumPartyMembers and GetNumPartyMembers() or 0) do
        if Bare(UnitName("party" .. index)) == name then return true end
    end
    return false
end

local function Queued()
    if GetLFGMode then
        local ok, mode = pcall(GetLFGMode)
        if ok and mode then return true end
    end
    if GetBattlefieldStatus and MAX_BATTLEFIELD_QUEUES then
        for index = 1, MAX_BATTLEFIELD_QUEUES do
            local status = GetBattlefieldStatus(index)
            if status == "queued" or status == "confirm" then return true end
        end
    end
    return false
end

local function Say(text)
    local db = Settings()
    if db and db.announce then NS.Print(text) end
end

function Auto:Invite(inviter)
    local db = Settings()
    if not db or not db.invite then return end
    local name = Bare(inviter)
    if not name then return end
    if db.notQueued and Queued() then return end

    local known = (db.friends and IsFriend(name)) or (db.guild and IsGuildmate(name))
    if not known then return end

    NS.After(0.1, function()
        if AcceptGroup then AcceptGroup() end
        local dialog = StaticPopup_FindVisible and StaticPopup_FindVisible("PARTY_INVITE")
        if dialog then dialog.inviteAccepted = 1 end
        if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end
        Say(L["Приглашение принято автоматически"] .. ": " .. name)
    end)
end

local summonWatch = CreateFrame("Frame")
summonWatch:Hide()

function Auto:CanTakeSummon()
    if UnitAffectingCombat("player") then return false end
    if PlayerCanTeleport and not PlayerCanTeleport() then return false end
    return true
end

function Auto:Summon()
    local db = Settings()
    if not db or not db.summon then return end
    local summoner = Bare(GetSummonConfirmSummoner and GetSummonConfirmSummoner())
    if not summoner then return end

    local allowed = IsGroupMember(summoner)
    if not allowed and db.summonFrom == "known" then
        allowed = IsFriend(summoner) or IsGuildmate(summoner)
    end
    if not allowed then return end

    summonWatch.summoner = summoner
    summonWatch.area = GetSummonConfirmAreaName and GetSummonConfirmAreaName()
    summonWatch.wait = db.summonDelay or 0
    summonWatch:Show()
end

summonWatch:SetScript("OnUpdate", function(self, elapsed)
    self.wait = (self.wait or 0) - elapsed
    if self.wait > 0 then return end
    self.wait = 0.5

    local left = GetSummonConfirmTimeLeft and GetSummonConfirmTimeLeft() or 0
    if left <= 0 then
        self:Hide()
        return
    end
    if not Auto:CanTakeSummon() then return end

    self:Hide()
    if ConfirmSummon then ConfirmSummon() end
    if StaticPopup_Hide then StaticPopup_Hide("CONFIRM_SUMMON") end
    Say(L["Призыв принят автоматически"] .. ": " .. tostring(self.summoner) .. (self.area and (" - " .. self.area) or ""))
end)

local driver = CreateFrame("Frame")
driver:RegisterEvent("PARTY_INVITE_REQUEST")
driver:RegisterEvent("CONFIRM_SUMMON")
driver:RegisterEvent("CANCEL_SUMMON")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "PARTY_INVITE_REQUEST" then
        Auto:Invite(arg1)
    elseif event == "CONFIRM_SUMMON" then
        Auto:Summon()
    elseif event == "CANCEL_SUMMON" then
        summonWatch:Hide()
    elseif event == "PLAYER_LOGIN" then
        local db = Settings()
        if db and db.invite and db.guild and IsInGuild and IsInGuild() and GuildRoster then
            NS.After(5, function() GuildRoster() end)
        end
    end
end)
