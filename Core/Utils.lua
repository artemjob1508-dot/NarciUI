local addonName, NS = ...

local floor = math.floor
local tonumber = tonumber
local ipairs = ipairs

local afterTimerFrame = CreateFrame("Frame")
local afterTimers = {}

afterTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local i = 1
    while i <= #afterTimers do
        local t = afterTimers[i]
        if now >= t.endTime then
            tremove(afterTimers, i)
            local ok, err = pcall(t.callback)
            if not ok and NS.Print then
                NS.Print("|cffff4444Timer error:|r " .. tostring(err))
            end
        else
            i = i + 1
        end
    end
    if #afterTimers == 0 then
        self:Hide()
    end
end)

function NS.After(delay, callback)
    tinsert(afterTimers, { endTime = GetTime() + delay, callback = callback })
    afterTimerFrame:Show()
end

function NS.ParseItemLink(link)
    if not link then return nil end
    local color, itemString, name = link:match("|cff(%x+)|H(item:[^|]+)|h%[([^%]]+)%]|h|r")
    if not itemString then return nil end

    local fields = {strsplit(":", itemString)}

    return {
        color = color,
        itemString = itemString,
        name = name,
        itemId = tonumber(fields[2]) or 0,
        enchantId = tonumber(fields[3]) or 0,
        gem1 = tonumber(fields[4]) or 0,
        gem2 = tonumber(fields[5]) or 0,
        gem3 = tonumber(fields[6]) or 0,
        gem4 = tonumber(fields[7]) or 0,
        suffixId = tonumber(fields[8]) or 0,
        uniqueId = tonumber(fields[9]) or 0,
        level = tonumber(fields[10]) or 0,
        link = link,
    }
end

function NS.GetItemLevel(link)
    if not link then return 0 end
    local _, _, _, itemLevel = GetItemInfo(link)
    return itemLevel or 0
end

function NS.GetAverageItemLevel()
    if GetAverageItemLevel then
        return GetAverageItemLevel()
    end
    local totalLevel = 0
    local count = 0
    local slots = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
    for _, slotID in ipairs(slots) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local level = NS.GetItemLevel(link)
            if level > 0 then
                totalLevel = totalLevel + level
                count = count + 1
            end
        end
    end
    if count > 0 then
        return floor(totalLevel / count * 100 + 0.5) / 100
    end
    return 0
end

function NS.GetEnchantInfo(link)
    local parsed = NS.ParseItemLink(link)
    if not parsed then return nil end
    if parsed.enchantId > 0 then
        return NS.ENCHANT_DATA[parsed.enchantId] or { name = "Enchant #" .. parsed.enchantId, id = parsed.enchantId }
    end
    return nil
end

function NS.GetGemInfo(link)
    local gems = {}
    for i = 1, 4 do
        local gemName, gemLink = GetItemGem(link, i)
        if gemLink then
            local _, _, _, _, _, _, _, _, _, gemTexture = GetItemInfo(gemLink)
            gems[i] = {
                name = gemName,
                link = gemLink,
                texture = gemTexture,
            }
        end
    end
    return gems
end

function NS.TruncateText(text, maxChars)
    if not text or maxChars < 1 then return text or "" end
    local chars = 0
    for i = 1, #text do
        local b = text:byte(i)
        if b < 128 or b >= 192 then
            chars = chars + 1
            if chars > maxChars then
                return (text:sub(1, i - 1):gsub("%s+$", "")) .. "..."
            end
        end
    end
    return text
end

function NS.GetQualityColor(quality)
    if quality and ITEM_QUALITY_COLORS then
        local c = ITEM_QUALITY_COLORS[quality]
        if c then return c.r, c.g, c.b end
    end
    return 1, 1, 1
end

function NS.CreateBackdrop(frame, inset, r, g, b, a)
    inset = inset or 2
    r = r or 0
    g = g or 0
    b = b or 0
    a = a or 0.85

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        })
        frame:SetBackdropColor(r, g, b, a)
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end
end

function NS.Lower(text)
    text = tostring(text or ""):gsub("[A-Z]", function(c) return string.char(c:byte() + 32) end)
    text = text:gsub("\208\129", "\209\145")
    text = text:gsub("\208([\144-\175])", function(c)
        local b = c:byte()
        if b < 160 then return "\208" .. string.char(b + 32) end
        return "\209" .. string.char(b - 32)
    end)
    return text
end

function NS.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffNarciUI|r: " .. msg)
end

local function FramePath(frame)
    local parts = {}
    local current = frame

    while current and #parts < 4 do
        local name = current.GetName and current:GetName()
        parts[#parts + 1] = name or ("<" .. current:GetObjectType() .. ">")
        if name then break end
        current = current.GetParent and current:GetParent()
    end

    return table.concat(parts, " < ")
end

function NS.WhatIsUnderCursor()
    local found = {}
    local seen = {}
    local frame = EnumerateFrames()

    while frame do
        if frame:IsVisible() and frame:GetAlpha() > 0 and frame ~= WorldFrame and frame ~= UIParent
            and MouseIsOver(frame) then
            local width, height = frame:GetWidth(), frame:GetHeight()

            if width > 0 and height > 0 and width < 300 and height < 300 then
                local path = FramePath(frame)
                if not seen[path] then
                    seen[path] = true
                    found[#found + 1] = { path = path, area = width * height }
                end
            end
        end

        frame = EnumerateFrames(frame)
    end

    if #found == 0 then
        NS.Print(NS.L["Под курсором нет рамок"])
        return
    end

    table.sort(found, function(a, b) return a.area < b.area end)

    for index = 1, math.min(#found, 6) do
        NS.Print(found[index].path)
    end
end

local social = { friends = 0, friendsTotal = 0, guild = 0, guildTotal = 0 }

local function CountSocial()
    local total, online = 0, 0
    if GetNumFriends then
        total, online = GetNumFriends()
        total = total or 0
        if not online then
            online = 0
            for index = 1, total do
                if select(5, GetFriendInfo(index)) then online = online + 1 end
            end
        end
    end
    social.friends, social.friendsTotal = online or 0, total

    social.guild, social.guildTotal = 0, 0
    if IsInGuild and IsInGuild() and GetNumGuildMembers then
        local count = GetNumGuildMembers(true) or 0
        local seen = 0
        for index = 1, count do
            local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(index)
            if name then
                seen = seen + 1
                if isOnline then social.guild = social.guild + 1 end
            end
        end
        social.guildTotal = math.max(seen, count)
    end
end

function NS.SocialCounts()
    return social
end

local socialWatch = CreateFrame("Frame")
socialWatch:RegisterEvent("PLAYER_LOGIN")
socialWatch:RegisterEvent("FRIENDLIST_UPDATE")
socialWatch:RegisterEvent("GUILD_ROSTER_UPDATE")
socialWatch:RegisterEvent("PLAYER_GUILD_UPDATE")
socialWatch:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if ShowFriends then pcall(ShowFriends) end
        if IsInGuild and IsInGuild() and GuildRoster then pcall(GuildRoster) end
    end
    CountSocial()
end)
local socialTick = 0
socialWatch:SetScript("OnUpdate", function(_, elapsed)
    socialTick = socialTick + elapsed
    if socialTick < 60 then return end
    socialTick = 0
    if IsInGuild and IsInGuild() and GuildRoster then pcall(GuildRoster) end
    if ShowFriends then pcall(ShowFriends) end
end)

NS.COORD_FORMATS = { "xy", "comma", "brackets", "spaced" }

function NS.FormatCoords(x, y, digits, format, r, g, b)
    local pattern = "%." .. (digits or 1) .. "f"
    local vx, vy = string.format(pattern, x * 100), string.format(pattern, y * 100)
    if format == "comma" then return vx .. ", " .. vy end
    if format == "brackets" then return "[ " .. vx .. " , " .. vy .. " ]" end
    if format == "spaced" then return vx .. "   " .. vy end
    local A = NS.Styling.ACCENT_GLOW
    local tag = string.format("|cff%02x%02x%02x", math.floor((r or A[1]) * 255), math.floor((g or A[2]) * 255), math.floor((b or A[3]) * 255))
    return tag .. "X|r " .. vx .. "   " .. tag .. "Y|r " .. vy
end

function NS.OpenFriendsList()
    local panel = NS.SocialPanel
    if panel and not (NS.db and NS.db.replaceSocial == false) and not InCombatLockdown() then
        if panel.frame and panel.frame:IsShown() and panel.tab == 1 and not panel.ignoreView then
            panel:Hide()
            return
        end
        panel.tab, panel.ignoreView, panel.offset = 1, nil, 0
        panel:Show()
        return
    end
    if ToggleFriendsFrame then ToggleFriendsFrame(1) end
end

function NS.OpenGuildList()
    if not (IsInGuild and IsInGuild()) then
        NS.Print(NS.L["Вы не состоите в гильдии"])
        return
    end
    local panel = NS.GuildPanel
    if panel and not (NS.db and NS.db.replaceGuild == false) and not InCombatLockdown() then
        if panel.frame and panel.frame:IsShown() and panel.view == "roster" then
            panel:Hide()
            return
        end
        panel.view = "roster"
        panel:Show()
        return
    end
    if ToggleGuildFrame then ToggleGuildFrame() elseif ToggleFriendsFrame then ToggleFriendsFrame(3) end
end

local lockoutAsked = 0

local function LockoutTime(seconds)
    if SecondsToTime then return SecondsToTime(seconds, true, nil, 2) end
    local days = math.floor(seconds / 86400)
    local hours = math.floor(seconds % 86400 / 3600)
    if days > 0 then return days .. NS.L["д"] .. " " .. hours .. NS.L["ч"] end
    return hours .. NS.L["ч"] .. " " .. math.floor(seconds % 3600 / 60) .. NS.L["м"]
end

function NS.Lockouts()
    if RequestRaidInfo and GetTime() - lockoutAsked > 30 then
        lockoutAsked = GetTime()
        RequestRaidInfo()
    end
    local list = {}
    for index = 1, (GetNumSavedInstances and GetNumSavedInstances() or 0) do
        local name, _, reset, _, locked, extended, _, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(index)
        if name and (locked or extended) and (reset or 0) > 0 then
            list[#list + 1] = {
                name = name, reset = reset, raid = isRaid and true or false, extended = extended,
                difficulty = difficultyName or (maxPlayers and (maxPlayers .. "")) or "",
            }
        end
    end
    table.sort(list, function(a, b)
        if a.raid ~= b.raid then return a.raid end
        if a.name ~= b.name then return a.name < b.name end
        return a.reset < b.reset
    end)
    return list
end

function NS.AddLockouts(tooltip)
    local S = NS.Styling
    local L = NS.L
    local list = NS.Lockouts()
    tooltip:AddLine(" ")
    tooltip:AddLine(L["Сохранённые подземелья и рейды"], S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    if #list == 0 then
        tooltip:AddLine(L["Нет сохранений"], S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        return
    end
    local raidShown, dungeonShown
    for _, entry in ipairs(list) do
        if entry.raid and not raidShown then
            raidShown = true
            tooltip:AddLine(L["Рейды"], S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        elseif not entry.raid and not dungeonShown then
            dungeonShown = true
            tooltip:AddLine(L["Подземелья"], S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
        local left = entry.name
        if entry.difficulty ~= "" then left = left .. " |cff9a9aa4(" .. entry.difficulty .. ")|r" end
        local right = LockoutTime(entry.reset)
        if entry.extended then right = right .. " |cff9a9aa4" .. L["продлено"] .. "|r" end
        local r, g, b = 0.92, 0.92, 0.95
        if entry.raid then r, g, b = 1, 0.82, 0.4 end
        tooltip:AddDoubleLine(left, right, r, g, b, 0.85, 0.85, 0.9)
    end
end

NS.TOOLTIP_LINES = { clock = {}, money = {} }

function NS.AddTooltipLines(kind, tooltip)
    for _, entry in ipairs(NS.TOOLTIP_LINES[kind] or {}) do
        local ok, err = pcall(entry.fn, tooltip)
        if not ok and NS.Print then NS.Print(tostring(entry.owner or "?") .. " - " .. kind .. ": " .. tostring(err)) end
    end
end

local clockHooked
local function HookClockTooltip()
    if clockHooked or type(_G.TimeManagerClockButton_UpdateTooltip) ~= "function" then return end
    clockHooked = true
    hooksecurefunc("TimeManagerClockButton_UpdateTooltip", function()
        if TimeManagerClockButton and TimeManagerClockButton.alarmFiring then return end
        local lockouts = not (NS.db and NS.db.clockLockouts == false)
        if lockouts then pcall(NS.AddLockouts, GameTooltip) end
        if not lockouts and #NS.TOOLTIP_LINES.clock == 0 then return end
        NS.AddTooltipLines("clock", GameTooltip)
        GameTooltip:Show()
    end)
end

local clockWatch = CreateFrame("Frame")
clockWatch:RegisterEvent("PLAYER_LOGIN")
clockWatch:RegisterEvent("ADDON_LOADED")
clockWatch:SetScript("OnEvent", function()
    HookClockTooltip()
    if clockHooked then clockWatch:UnregisterAllEvents() end
end)
