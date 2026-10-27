local addonName, NS = ...
local L = NS.L

local M = {}
NS.Messenger = M

local DEFAULTS = {
    enabled = true,
    hideInChat = true,
    intercept = true,
    popup = "incoming",
    strangers = "popup",
    combatPopup = false,
    focusOnPopup = false,
    sound = true,
    timestamps = true,
    keepDays = 30,
    keepCount = 300,
    fontSize = 12,
    alpha = 95,
    width = 600,
    height = 380,
    showButton = true,
    blockWords = "",
    style = "narci",
    artAlpha = 100,
    buttonStyle = "flat",
    buttonSize = 34,
}

M.DEFAULTS = DEFAULTS

local SPLIT_AT = 250

function M:Settings()
    if not NS.db then return DEFAULTS end
    if type(NS.db.messenger) ~= "table" then NS.db.messenger = {} end
    local db = NS.db.messenger
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    return db
end

function M:OtherAddon()
    if not IsAddOnLoaded then return false end
    return (IsAddOnLoaded("WIM") or IsAddOnLoaded("Wim")) and true or false
end

function M:Enabled()
    local db = self:Settings()
    return db.enabled ~= false and not self:OtherAddon()
end

local function Lower(text)
    if NS.Lower then return NS.Lower(text) end
    return tostring(text or ""):lower()
end

local function Key(name)
    if type(name) ~= "string" or name == "" then return end
    return Lower(name)
end

local store

function M:Store()
    if store then return store end
    NarcissusSirusDB = NarcissusSirusDB or {}
    local root = NarcissusSirusDB
    root.messenger = root.messenger or {}
    local realm = GetRealmName() or "?"
    local me = UnitName("player") or "?"
    root.messenger[realm] = root.messenger[realm] or {}
    local mine = root.messenger[realm][me]
    if type(mine) ~= "table" then
        mine = {}
        root.messenger[realm][me] = mine
    end
    mine.contacts = mine.contacts or {}
    store = mine
    return store
end

function M:Contacts()
    return self:Store().contacts
end

function M:Contact(name, create)
    local key = Key(name)
    if not key then return end
    local contacts = self:Contacts()
    local contact = contacts[key]
    if not contact and create then
        contact = { name = name, messages = {}, unread = 0, last = time() }
        contacts[key] = contact
    end
    return contact, key
end

function M:Remove(name)
    local key = Key(name)
    if key then self:Contacts()[key] = nil end
    if self.active == key then self.active = nil end
    self:Changed()
end

function M:Prune()
    local db = self:Settings()
    local limit = time() - (db.keepDays or 30) * 86400
    local count = db.keepCount or 300
    for key, contact in pairs(self:Contacts()) do
        local messages = contact.messages or {}
        local kept = {}
        for _, entry in ipairs(messages) do
            if (entry[1] or 0) >= limit then kept[#kept + 1] = entry end
        end
        while #kept > count do table.remove(kept, 1) end
        contact.messages = kept
        if #kept == 0 and (contact.unread or 0) == 0 then self:Contacts()[key] = nil end
    end
end

local function Pattern(format)
    if type(format) ~= "string" then return end
    local pattern = format:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = pattern:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

local SYSTEM

local function SystemPatterns()
    if SYSTEM then return SYSTEM end
    SYSTEM = {}
    local function Add(format, kind)
        local pattern = Pattern(format)
        if pattern then SYSTEM[#SYSTEM + 1] = { pattern = pattern, kind = kind } end
    end
    Add(ERR_CHAT_PLAYER_NOT_FOUND_S, "offline")
    Add(CHAT_IGNORED, "ignored")
    Add(ERR_FRIEND_ONLINE_SS, "online")
    Add(ERR_FRIEND_OFFLINE_S, "offline")
    return SYSTEM
end

function M:IsSpam(text, flag)
    if flag == "GM" then return false end
    local db = self:Settings()
    local words = db.blockWords
    if type(words) ~= "string" or words == "" then return false end
    local lowered = Lower(text)
    for part in words:gmatch("[^,;\n]+") do
        local word = Lower(part:gsub("^%s+", ""):gsub("%s+$", ""))
        if word ~= "" and lowered:find(word, 1, true) then return true end
    end
    return false
end

local CLASS_TOKENS

local function ClassToken(localized)
    if not localized then return end
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[localized] then return localized end
    if not CLASS_TOKENS then
        CLASS_TOKENS = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do CLASS_TOKENS[name] = token end
        for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do CLASS_TOKENS[name] = token end
    end
    return CLASS_TOKENS[localized]
end

function M:Learn(name, info)
    local contact = self:Contact(name)
    if not contact or type(info) ~= "table" then return end
    for field, value in pairs(info) do
        if value ~= nil and value ~= "" then contact[field] = value end
    end
end

function M:LearnGUID(name, guid)
    if not guid or guid == "" or type(GetPlayerInfoByGUID) ~= "function" then return end
    local ok, _, class, race = pcall(GetPlayerInfoByGUID, guid)
    if ok and class then self:Learn(name, { class = class, race = race }) end
end

function M:LearnUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local name = UnitName(unit)
    if not self:Contact(name) then return end
    local _, class = UnitClass(unit)
    local level = UnitLevel(unit)
    self:Learn(name, {
        class = class,
        race = UnitRace(unit),
        level = (level and level > 0) and level or nil,
        guild = GetGuildInfo(unit) or nil,
    })
end

function M:LearnRosters()
    for index = 1, (GetNumFriends and GetNumFriends() or 0) do
        local name, level, class, area, connected = GetFriendInfo(index)
        if name and self:Contact(name) then
            self:Learn(name, { level = level, class = ClassToken(class), zone = area, online = connected and true or false, friend = true })
        end
    end
    if IsInGuild and IsInGuild() then
        local guild = GetGuildInfo("player")
        for index = 1, (GetNumGuildMembers and GetNumGuildMembers(true) or 0) do
            local name, _, _, level, class, zone, _, _, online = GetGuildRosterInfo(index)
            if name and self:Contact(name) then
                self:Learn(name, { level = level, class = ClassToken(class), zone = zone, online = online and true or false, guild = guild })
            end
        end
    end
end

function M:Known(name)
    local bare = Key(name)
    if not bare then return false end
    for index = 1, (GetNumFriends and GetNumFriends() or 0) do
        if Key(GetFriendInfo(index)) == bare then return true end
    end
    if IsInGuild and IsInGuild() then
        for index = 1, (GetNumGuildMembers and GetNumGuildMembers(true) or 0) do
            if Key(GetGuildRosterInfo(index)) == bare then return true end
        end
    end
    for index = 1, (GetNumRaidMembers and GetNumRaidMembers() or 0) do
        if Key(UnitName("raid" .. index)) == bare then return true end
    end
    for index = 1, (GetNumPartyMembers and GetNumPartyMembers() or 0) do
        if Key(UnitName("party" .. index)) == bare then return true end
    end
    return false
end

function M:Add(contact, kind, text, stamp)
    local entry = { stamp or time(), kind, text }
    local messages = contact.messages
    messages[#messages + 1] = entry
    local limit = self:Settings().keepCount or 300
    while #messages > limit do table.remove(messages, 1) end
    contact.last = entry[1]
    return entry
end

function M:Changed(contact, entry)
    if self.OnChanged then self:OnChanged(contact, entry) end
end

local function PlayIncoming()
    if M:Settings().sound and PlaySound then PlaySound("TellMessage") end
end

function M:ShouldPopup(name, kind)
    local db = self:Settings()
    if InCombatLockdown() and not db.combatPopup then return false end
    if kind == "out" then return db.popup ~= "never" end
    if db.popup ~= "incoming" then return false end
    if db.strangers == "quiet" and not self:Known(name) then return false end
    return true
end

function M:Receive(kind, text, name, guid, flag)
    if not self:Enabled() or not name or name == "" then return end
    if (kind == "in" or kind == "gm") and self:IsSpam(text, flag) then return end

    local contact = self:Contact(name, true)
    contact.name = name
    if flag == "GM" then
        contact.gm = true
        kind = "gm"
    end
    self:LearnGUID(name, guid)
    local entry = self:Add(contact, kind, text)

    local key = Key(name)
    local open = self:IsOpen() and self.active == key
    if kind == "in" or kind == "gm" then
        if self:Settings().hideInChat then PlayIncoming() end
        if not open then contact.unread = (contact.unread or 0) + 1 end
        contact.online = true
        if not self:IsOpen() and self:ShouldPopup(name, kind) then
            self:Open(name, self:Settings().focusOnPopup)
        end
    elseif kind == "out" then
        contact.online = true
    end

    self:Changed(contact, entry)
end

function M:System(text)
    if not self:Enabled() or type(text) ~= "string" then return end
    for _, rule in ipairs(SystemPatterns()) do
        local name = text:match(rule.pattern)
        if name then
            name = name:match("|Hplayer:([^:|]+)") or name
            local contact = self:Contact(name)
            if contact then
                if rule.kind == "online" then contact.online = true end
                if rule.kind == "offline" or rule.kind == "ignored" then contact.online = false end
                local entry = self:Add(contact, "sys", text)
                self:Changed(contact, entry)
            end
            return
        end
    end
end

local function Chunks(text)
    if #text <= 255 then return { text } end
    local chunks, current = {}, ""
    for word in text:gmatch("%S+") do
        if current == "" then
            current = word
        elseif #current + 1 + #word <= SPLIT_AT then
            current = current .. " " .. word
        else
            chunks[#chunks + 1] = current
            current = word
        end
        while #current > SPLIT_AT do
            local cut = SPLIT_AT
            while cut > 1 do
                local byte = current:byte(cut + 1)
                if not byte or byte < 128 or byte >= 192 then break end
                cut = cut - 1
            end
            chunks[#chunks + 1] = current:sub(1, cut)
            current = current:sub(cut + 1)
        end
    end
    if current ~= "" then chunks[#chunks + 1] = current end
    return chunks
end

function M:Send(name, text)
    if not name or type(text) ~= "string" then return end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end
    for _, chunk in ipairs(Chunks(text)) do
        SendChatMessage(chunk, "WHISPER", nil, name)
    end
end

function M:IsOpen()
    return self.frame and self.frame:IsShown() or false
end

function M:Unread()
    local total = 0
    for _, contact in pairs(self:Contacts()) do total = total + (contact.unread or 0) end
    return total
end

function M:Open(name, focus)
    if not self:Enabled() then return end
    if self.Show then self:Show(name, focus) end
end

local function ChatFilter(_, event, text, sender, _, _, _, flag)
    if not M:Enabled() then return false end
    if event == "CHAT_MSG_WHISPER" and M:IsSpam(text, flag) then return true end
    if (event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND") and not M:Contact(sender) then return false end
    return M:Settings().hideInChat and true or false
end

local function TakeOver(target)
    if not M:Enabled() or not M:Settings().intercept then return end
    if type(target) ~= "string" or target == "" then return end
    NS.After(0, function()
        local box = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        local carried
        if box and box:GetAttribute("chatType") == "WHISPER" then
            carried = box:GetText()
            ChatEdit_OnEscapePressed(box)
        end
        M:Open(target, true)
        if carried and carried ~= "" and M.SetInput then M:SetInput(carried) end
    end)
end

function M:InstallHooks()
    if self.hooked then return end
    self.hooked = true

    for _, event in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_AFK", "CHAT_MSG_DND" }) do
        ChatFrame_AddMessageEventFilter(event, ChatFilter)
    end

    hooksecurefunc("ChatFrame_ReplyTell", function()
        local target = ChatEdit_GetLastTellTarget and ChatEdit_GetLastTellTarget()
        TakeOver(target)
    end)
    hooksecurefunc("ChatFrame_ReplyTell2", function()
        local target = ChatEdit_GetLastToldTarget and ChatEdit_GetLastToldTarget()
        TakeOver(target)
    end)
    hooksecurefunc("ChatEdit_ExtractTellTarget", function(box)
        if not box or box:GetAttribute("chatType") ~= "WHISPER" then return end
        local text = box:GetText() or ""
        if text:sub(1, 1) == "/" then return end
        TakeOver(box:GetAttribute("tellTarget"))
    end)
    hooksecurefunc("ChatEdit_InsertLink", function(text)
        local input = M.input
        if text and input and input:IsShown() and input:HasFocus() then input:Insert(text) end
    end)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not M:Enabled() then return end
        M:Store()
        M:Prune()
        M:InstallHooks()
        for _, name in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_AFK", "CHAT_MSG_DND",
            "CHAT_MSG_SYSTEM", "FRIENDLIST_UPDATE", "GUILD_ROSTER_UPDATE", "UPDATE_MOUSEOVER_UNIT",
            "PLAYER_TARGET_CHANGED" }) do
            self:RegisterEvent(name)
        end
        if M.BuildButton then M:BuildButton() end
        return
    end

    if event == "CHAT_MSG_WHISPER" then
        local text, sender, _, _, _, flag, _, _, _, _, _, guid = ...
        M:Receive("in", text, sender, guid, flag)
        if M:Settings().hideInChat and ChatEdit_SetLastTellTarget then ChatEdit_SetLastTellTarget(sender) end
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local text, target, _, _, _, _, _, _, _, _, _, guid = ...
        M:Receive("out", text, target, guid)
    elseif event == "CHAT_MSG_AFK" or event == "CHAT_MSG_DND" then
        local text, sender = ...
        if M:Contact(sender) then M:Receive(event == "CHAT_MSG_AFK" and "afk" or "dnd", text, sender) end
    elseif event == "CHAT_MSG_SYSTEM" then
        M:System((...))
    elseif event == "FRIENDLIST_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        M:LearnRosters()
        M:Changed()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        M:LearnUnit("mouseover")
    elseif event == "PLAYER_TARGET_CHANGED" then
        M:LearnUnit("target")
    end
end)
