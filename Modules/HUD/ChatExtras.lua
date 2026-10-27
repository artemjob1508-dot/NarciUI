local addonName, NS = ...
local L = NS.L

local Extras = {}
NS.ChatExtras = Extras

local EVENTS = {
    CHAT_MSG_SAY = "say", CHAT_MSG_YELL = "say",
    CHAT_MSG_GUILD = "guild", CHAT_MSG_OFFICER = "guild",
    CHAT_MSG_PARTY = "party", CHAT_MSG_PARTY_LEADER = "party",
    CHAT_MSG_RAID = "raid", CHAT_MSG_RAID_LEADER = "raid", CHAT_MSG_RAID_WARNING = "raid",
    CHAT_MSG_BATTLEGROUND = "raid", CHAT_MSG_BATTLEGROUND_LEADER = "raid",
    CHAT_MSG_CHANNEL = "channel",
    CHAT_MSG_WHISPER = "whisper", CHAT_MSG_WHISPER_INFORM = "whisper",
}

local function Settings()
    if not NS.db then return end
    if type(NS.db.chatExtras) ~= "table" then NS.db.chatExtras = {} end
    local db = NS.db.chatExtras
    if db.copyButton == nil then db.copyButton = false end
    if db.highlight == nil then db.highlight = false end
    db.keywords = db.keywords or ""
    if db.ownName == nil then db.ownName = true end
    db.highlightColor = db.highlightColor or "accent"
    if db.keywordSound == nil then db.keywordSound = false end
    if db.spam == nil then db.spam = false end
    db.spamWindow = db.spamWindow or 30
    db.blockWords = db.blockWords or ""
    if db.history == nil then db.history = false end
    db.historySize = db.historySize or 100
    if type(db.historyTypes) ~= "table" then
        db.historyTypes = { say = true, guild = true, party = true, raid = true, channel = false, whisper = false }
    end
    return db
end

Extras.Settings = Settings

local function Lower(text)
    return NS.Lower(text)
end

Extras.Lower = Lower

local function SplitList(text)
    local list = {}
    for part in (text or ""):gmatch("[^,;\n]+") do
        local word = part:gsub("^%s+", ""):gsub("%s+$", "")
        if word ~= "" then list[#list + 1] = Lower(word) end
    end
    return list
end

local keywordCache, keywordSource
local blockCache, blockSource

local function Keywords(db)
    local source = db.keywords .. "|" .. tostring(db.ownName)
    if source ~= keywordSource then
        keywordSource = source
        keywordCache = SplitList(db.keywords)
        if db.ownName then
            local name = UnitName("player")
            if name then keywordCache[#keywordCache + 1] = Lower(name) end
        end
    end
    return keywordCache
end

local function BlockWords(db)
    if db.blockWords ~= blockSource then
        blockSource = db.blockWords
        blockCache = SplitList(db.blockWords)
    end
    return blockCache
end

local function HighlightCode(db)
    local S = NS.Styling
    local c = S.ACCENT_GLOW
    if db.highlightColor == "gold" then c = S.GOLD
    elseif db.highlightColor == "red" then c = { 1, 0.35, 0.35 }
    elseif db.highlightColor == "white" then c = { 1, 1, 1 } end
    return string.format("|cff%02x%02x%02x", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255))
end

local function Mark(segment, words, code)
    local lowered = Lower(segment)
    local hits = {}
    for _, word in ipairs(words) do
        local from = 1
        while true do
            local s, e = lowered:find(word, from, true)
            if not s then break end
            hits[#hits + 1] = { s, e }
            from = e + 1
        end
    end
    if #hits == 0 then return segment, false end
    table.sort(hits, function(a, b) return a[1] < b[1] end)
    local out, last = {}, 0
    for _, hit in ipairs(hits) do
        if hit[1] > last then
            out[#out + 1] = segment:sub(last + 1, hit[1] - 1)
            out[#out + 1] = code .. segment:sub(hit[1], hit[2]) .. "|r"
            last = hit[2]
        end
    end
    out[#out + 1] = segment:sub(last + 1)
    return table.concat(out), true
end

local function Highlight(message, db)
    local words = Keywords(db)
    if #words == 0 then return message, false end
    local code = HighlightCode(db)
    local out, found, position = {}, false, 1
    while true do
        local s, e = message:find("|c%x+|H.-|h.-|h|r", position)
        local plain = message:sub(position, (s or 0) - 1)
        if not s then plain = message:sub(position) end
        local marked, hit = Mark(plain, words, code)
        out[#out + 1] = marked
        found = found or hit
        if not s then break end
        out[#out + 1] = message:sub(s, e)
        position = e + 1
    end
    return table.concat(out), found
end

local recent = {}
local lastSound = 0

local function Filter(frame, event, message, sender, ...)
    local db = Settings()
    if not db or type(message) ~= "string" then return false end
    local me = UnitName("player")

    if db.spam and sender ~= me and event ~= "CHAT_MSG_WHISPER_INFORM" then
        local lowered = Lower(message)
        for _, word in ipairs(BlockWords(db)) do
            if lowered:find(word, 1, true) then return true end
        end
        if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" then
            local key = (sender or "") .. "\1" .. lowered
            local line = select(9, ...)
            local now = GetTime()
            local seen = recent[key]
            if seen and line and seen.line == line then
                if seen.blocked then return true end
            elseif seen and now - seen.time < (db.spamWindow or 30) then
                seen.line, seen.blocked = line, true
                return true
            else
                recent[key] = { time = now, line = line, blocked = false }
            end
        end
    end

    if db.highlight and sender ~= me and event ~= "CHAT_MSG_WHISPER_INFORM" then
        local marked, found = Highlight(message, db)
        if found then
            if db.keywordSound and GetTime() - lastSound > 5 then
                lastSound = GetTime()
                PlaySound("TellMessage")
            end
            return false, marked, sender, ...
        end
    end
    return false
end

local cleanup = 0
local sweeper = CreateFrame("Frame")
sweeper:SetScript("OnUpdate", function(_, elapsed)
    cleanup = cleanup + elapsed
    if cleanup < 60 then return end
    cleanup = 0
    local now = GetTime()
    local window = (Settings() or {}).spamWindow or 30
    for key, seen in pairs(recent) do
        if now - seen.time > window then recent[key] = nil end
    end
end)

local function HistoryStore()
    if not NarcissusSirusDB then return end
    if type(NarcissusSirusDB.chatHistory) ~= "table" then NarcissusSirusDB.chatHistory = {} end
    local key = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
    if type(NarcissusSirusDB.chatHistory[key]) ~= "table" then NarcissusSirusDB.chatHistory[key] = {} end
    return NarcissusSirusDB.chatHistory[key]
end

local replaying = false

local function Record(event, ...)
    if replaying then return end
    local db = Settings()
    if not db or not db.history then return end
    local kind = EVENTS[event]
    if not kind or not db.historyTypes[kind] then return end
    local store = HistoryStore()
    if not store then return end
    store[#store + 1] = { event, time(), ... }
    local limit = db.historySize or 100
    while #store > limit do table.remove(store, 1) end
end

function Extras:Replay()
    local db = Settings()
    if not db or not db.history or self.replayed then return end
    self.replayed = true
    local store = HistoryStore()
    if not store or #store == 0 then return end
    if type(ChatFrame_MessageEventHandler) ~= "function" then return end

    local S = NS.Styling
    local code = string.format("|cff%02x%02x%02x", math.floor(S.ACCENT_GLOW[1] * 255), math.floor(S.ACCENT_GLOW[2] * 255), math.floor(S.ACCENT_GLOW[3] * 255))
    replaying = true
    for index = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. index]
        if frame then
            local any = false
            for _, entry in ipairs(store) do
                local event = entry[1]
                local ok, registered = pcall(frame.IsEventRegistered, frame, event)
                if ok and registered and db.historyTypes[EVENTS[event] or ""] then
                    if not any then
                        any = true
                        frame:AddMessage(code .. "--- " .. L["история чата"] .. " ---|r")
                    end
                    pcall(ChatFrame_MessageEventHandler, frame, event, select(3, unpack(entry, 1, 15)))
                end
            end
            if any then frame:AddMessage(code .. "--- " .. L["конец истории"] .. " ---|r") end
        end
    end
    replaying = false
end

function Extras:Clear()
    local store = HistoryStore()
    if store then for index = #store, 1, -1 do store[index] = nil end end
end

function Extras:ApplyCopy()
    local db = Settings()
    if not db or not SetCVarBitfield then return end
    for index = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. index]
        if frame and frame.CopyChatButton then
            pcall(SetCVarBitfield, "copyChat", index, db.copyButton and true or false)
            frame.CopyChatButton:SetShown(db.copyButton and true or false)
        end
    end
end

function Extras:Copy()
    if not ChatCopyFrame or not ChatCopyFrame.CopyChat then return end
    pcall(ChatCopyFrame.CopyChat, ChatCopyFrame, SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME, true)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
for event in pairs(EVENTS) do driver:RegisterEvent(event) end
driver:SetScript("OnEvent", function(_, event, ...)
    if EVENTS[event] then
        Record(event, ...)
        return
    end
    if event == "PLAYER_LOGIN" then
        for name in pairs(EVENTS) do
            if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter(name, Filter) end
        end
        Extras:ApplyCopy()
    elseif event == "PLAYER_ENTERING_WORLD" then
        NS.After(1.5, function() Extras:Replay() end)
    end
end)
