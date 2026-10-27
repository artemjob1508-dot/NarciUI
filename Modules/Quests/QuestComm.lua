local addonName, NS = ...

local Comm = {}
NS.QuestComm = Comm

local PREFIX = "QSHARE"
local FIELD = "\t"
local OBJ = "\029"
local SUB = "\031"
local SEND_INTERVAL = 0.35
local MAX_LENGTH = 240
local MAX_OBJECTIVES = 4
local NAME_LIMIT = 22
local PEER_TTL = 900

Comm.peers = {}

local queue = {}
local sending = false

local function Encode(text)
    text = tostring(text or "")
    text = text:gsub(FIELD, " "):gsub(OBJ, " "):gsub(SUB, " ")
    return text
end

local function Channels()
    local list = {}
    local db = NS.questDB
    if not db then return list end
    local group = NS.GroupChannel()
    if group == "RAID" and db.channels.raid then
        list[#list + 1] = "RAID"
    elseif group == "PARTY" and db.channels.party then
        list[#list + 1] = "PARTY"
    end
    if db.channels.guild and IsInGuild() then
        list[#list + 1] = "GUILD"
    end
    return list
end

local function Pump()
    if #queue == 0 then
        sending = false
        return
    end
    sending = true
    local item = table.remove(queue, 1)
    if item.target then
        SendAddonMessage(PREFIX, item.message, "WHISPER", item.target)
    else
        for _, channel in ipairs(item.channels) do
            SendAddonMessage(PREFIX, item.message, channel)
        end
    end
    NS.After(SEND_INTERVAL, Pump)
end

function Comm:Send(message, channels)
    channels = channels or Channels()
    local usable = {}
    for _, channel in ipairs(channels) do
        if channel ~= "WHISPER" then usable[#usable + 1] = channel end
    end
    channels = usable
    if #channels == 0 then return end
    if #message > MAX_LENGTH then
        message = NS.Cut(message, MAX_LENGTH)
    end
    queue[#queue + 1] = { message = message, channels = channels }
    if #queue > 60 then
        table.remove(queue, 1)
    end
    if not sending then Pump() end
end

function Comm:Whisper(message, target)
    if not target then return end
    queue[#queue + 1] = { message = message, channels = { "WHISPER" }, target = target }
    if not sending then Pump() end
end

local function QuestFlags(quest)
    local flags = 0
    if quest.complete or NS.QuestData:AllComplete(quest) then flags = flags + 1 end
    if quest.failed then flags = flags + 2 end
    if quest.daily then flags = flags + 4 end
    return flags
end

function Comm:EncodeQuest(quest)
    local parts = {}
    local count = 0
    for _, objective in ipairs(quest.objectives) do
        count = count + 1
        if count > MAX_OBJECTIVES then break end
        local name = NS.Cut(Encode(objective.name), NAME_LIMIT)
        parts[#parts + 1] = table.concat({
            name,
            objective.have,
            objective.need,
            objective.finished and 1 or 0,
        }, SUB)
    end

    local message = table.concat({
        "Q",
        quest.id,
        Encode(quest.title),
        QuestFlags(quest),
        quest.level or 0,
        table.concat(parts, OBJ),
    }, FIELD)

    if #message > MAX_LENGTH then
        for index = 1, #parts do
            local trimmed = parts[index]:gsub("^[^" .. SUB .. "]*", "")
            parts[index] = trimmed
        end
        message = table.concat({
            "Q", quest.id, Encode(quest.title), QuestFlags(quest), quest.level or 0,
            table.concat(parts, OBJ),
        }, FIELD)
    end

    return message
end

function Comm:SendQuest(quest, channels)
    self:Send(self:EncodeQuest(quest), channels)
end

function Comm:SendFullState(channels)
    local sent = 0
    for _, quest in pairs(NS.QuestData.own) do
        self:SendQuest(quest, channels)
        sent = sent + 1
        if sent >= 40 then break end
    end
end

function Comm:SendEvent(event)
    local quest = event.quest
    local objIndex = event.objIndex
    local objective = objIndex and quest.objectives[objIndex]
    local message = table.concat({
        "E",
        event.type,
        quest.id,
        Encode(quest.title),
        objective and Encode(objective.name) or "",
        objective and objective.have or 0,
        objective and objective.need or 0,
    }, FIELD)
    self:Send(message)
    if event.type == "turnin" or event.type == "abandon" then
        self:Send(table.concat({ "X", quest.id }, FIELD))
    else
        self:SendQuest(quest)
    end
end

function Comm:Peer(name, create)
    local peer = self.peers[name]
    if not peer and create then
        peer = { name = name, quests = {}, lastSeen = GetTime() }
        self.peers[name] = peer
    end
    if peer then peer.lastSeen = GetTime() end
    return peer
end

function Comm:Prune()
    local now = GetTime()
    for name, peer in pairs(self.peers) do
        if name ~= NS.PlayerName() and now - (peer.lastSeen or 0) > PEER_TTL then
            self.peers[name] = nil
        end
    end
end

local function DecodeQuest(peer, id, title, flags, level, objectiveBlob)
    id = tonumber(id)
    flags = tonumber(flags) or 0
    if not id then return nil end

    local quest = {
        id = id,
        title = title or ("#" .. id),
        level = tonumber(level) or 0,
        complete = math.fmod(flags, 2) >= 1,
        failed = math.fmod(math.floor(flags / 2), 2) >= 1,
        daily = math.fmod(math.floor(flags / 4), 2) >= 1,
        objectives = {},
    }

    if objectiveBlob and objectiveBlob ~= "" then
        for chunk in string.gmatch(objectiveBlob, "[^" .. OBJ .. "]+") do
            local name, have, need, finished = string.match(chunk,
                "([^" .. SUB .. "]*)" .. SUB .. "(%d+)" .. SUB .. "(%d+)" .. SUB .. "(%d+)")
            if have then
                quest.objectives[#quest.objectives + 1] = {
                    name = name or "",
                    have = tonumber(have),
                    need = tonumber(need),
                    finished = finished == "1",
                }
            end
        end
    end

    peer.quests[id] = quest
    return quest
end

function Comm:OnMessage(message, channel, sender)
    if sender == NS.PlayerName() then return end

    local parts = {}
    for chunk in string.gmatch(message .. FIELD, "([^" .. FIELD .. "]*)" .. FIELD) do
        parts[#parts + 1] = chunk
    end

    local kind = parts[1]
    if not kind then return end

    local peer = self:Peer(sender, true)

    if kind == "Q" then
        DecodeQuest(peer, parts[2], parts[3], parts[4], parts[5], parts[6])
        if NS.QuestLog then NS.QuestLog:Refresh() end

    elseif kind == "X" then
        local id = tonumber(parts[2])
        if id then peer.quests[id] = nil end
        if NS.QuestLog then NS.QuestLog:Refresh() end

    elseif kind == "E" then
        local event = {
            type = parts[2],
            id = tonumber(parts[3]),
            title = parts[4],
            objective = parts[5],
            have = tonumber(parts[6]) or 0,
            need = tonumber(parts[7]) or 0,
            sender = sender,
            channel = channel,
        }
        if NS.QuestBanner then NS.QuestBanner:Show(event) end
        if NS.QuestLog then NS.QuestLog:Refresh() end

    elseif kind == "H" then
        peer.version = parts[2]
        self:Send(table.concat({ "R" }, FIELD), { channel })

    elseif kind == "R" then
        NS.After(math.random() * 2, function()
            Comm:SendFullState({ channel })
        end)
    end
end

function Comm:Hello()
    self:Send(table.concat({ "H", NS.VERSION }, FIELD))
end

function Comm:Init()
    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
        if prefix ~= PREFIX then return end
        Comm:OnMessage(message, channel, sender)
    end)
    self.listener = listener
end
