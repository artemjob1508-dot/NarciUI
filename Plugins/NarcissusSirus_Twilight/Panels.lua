local addonName, ns = ...
ns.Twilight = ns.Twilight or {}
local T = ns.Twilight

local API = T.API
if not API then return end

local L = function(text) return API:L(text) end
local WHITE = T.WHITE

local built = {}
local tickers = {}

local function Every(interval, fn)
    tickers[#tickers + 1] = { interval = interval, left = 0, fn = fn }
end

local clock = CreateFrame("Frame")
clock:SetScript("OnUpdate", function(_, elapsed)
    for _, ticker in ipairs(tickers) do
        ticker.left = ticker.left - elapsed
        if ticker.left <= 0 then
            ticker.left = ticker.interval
            pcall(ticker.fn)
        end
    end
end)

local function LabelColor()
    if T.db and T.db.classText == false then return 0.85, 0.85, 0.85 end
    return T.ClassColor()
end

local function Tooltip(owner, title, lines)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP", 0, 4)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(title, 1, 1, 1)
    for _, line in ipairs(lines or {}) do
        if type(line) == "table" then
            GameTooltip:AddDoubleLine(line[1], line[2], 0.8, 0.8, 0.8, 1, 1, 1)
        else
            GameTooltip:AddLine(line, 0.8, 0.8, 0.8, true)
        end
    end
    GameTooltip:Show()
end

local function IconButton(parent, texture, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture(texture)
    button.icon = icon
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(self) self.icon:SetVertexColor(1, 1, 1) end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.tint then self.icon:SetVertexColor(self.tint[1], self.tint[2], self.tint[3]) end
    end)
    return button
end

local function TextCell(parent, width, justify)
    local cell = CreateFrame("Button", nil, parent)
    cell:SetSize(width, 18)
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell.text = T.Text(cell, 12, justify or "CENTER")
    cell.text:SetAllPoints(cell)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cell
end

local function DrawIcon(tint)
    return function(button)
        button.tint = tint
        button.icon:SetVertexColor(tint[1], tint[2], tint[3])
    end
end

local function BuildBars()
    if built.bars then return true end
    local bar1, bar2 = _G.NarciSirus_bar1, _G.NarciSirus_bar2
    if not bar1 or not bar2 then return false end
    built.bars = true

    local center = T.Panel("NarciTwilight_BarCenter")
    center:SetFrameStrata("BACKGROUND")
    center:SetFrameLevel(1)
    center:SetPoint("TOPLEFT", bar1, "TOPLEFT", -6, 13)
    center:SetPoint("BOTTOMRIGHT", bar2, "BOTTOMRIGHT", 6, -4)
    center:SetScript("OnUpdate", nil)
    T.centerPanel = center

    local xp = CreateFrame("StatusBar", nil, center)
    xp:SetPoint("TOPLEFT", center, "TOPLEFT", 1, -1)
    xp:SetPoint("TOPRIGHT", center, "TOPRIGHT", -1, -1)
    xp:SetHeight(5)
    xp:SetStatusBarTexture(WHITE)
    xp:GetStatusBarTexture():SetGradientAlpha("VERTICAL",
        T.STRIPE_BOTTOM[1], T.STRIPE_BOTTOM[2], T.STRIPE_BOTTOM[3], 1,
        T.STRIPE_TOP[1], T.STRIPE_TOP[2], T.STRIPE_TOP[3], 1)
    xp:SetMinMaxValues(0, 1)

    local track = xp:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(xp)
    track:SetTexture(WHITE)
    track:SetVertexColor(0.14, 0.13, 0.25, 1)

    local rested = CreateFrame("StatusBar", nil, center)
    rested:SetAllPoints(xp)
    rested:SetFrameLevel(xp:GetFrameLevel())
    rested:SetStatusBarTexture(WHITE)
    rested:SetStatusBarColor(0.25, 0.4, 0.8, 0.45)
    rested:SetMinMaxValues(0, 1)
    xp:SetFrameLevel(rested:GetFrameLevel() + 1)

    local under = center:CreateTexture(nil, "ARTWORK")
    under:SetTexture(WHITE)
    under:SetVertexColor(0, 0, 0, 1)
    under:SetPoint("TOPLEFT", xp, "BOTTOMLEFT", 0, 0)
    under:SetPoint("TOPRIGHT", xp, "BOTTOMRIGHT", 0, 0)
    under:SetHeight(1)

    local ticks = {}
    for index = 1, 9 do
        local tick = xp:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(WHITE)
        tick:SetVertexColor(0, 0, 0, 0.55)
        tick:SetSize(1, 5)
        ticks[index] = tick
    end

    local overlay = CreateFrame("Frame", nil, center)
    overlay:SetAllPoints(xp)
    overlay:SetFrameLevel(xp:GetFrameLevel() + 2)
    local label = T.Text(overlay, 11, "CENTER")
    label:SetPoint("CENTER", xp, "CENTER", 0, 0)

    local function Ticks()
        local width = xp:GetWidth()
        if not width or width <= 0 then return end
        for index, tick in ipairs(ticks) do
            tick:ClearAllPoints()
            tick:SetPoint("LEFT", xp, "LEFT", math.floor(width * index / 10 + 0.5), 0)
        end
    end
    xp:SetScript("OnSizeChanged", Ticks)

    local function Update()
        local maxLevel = (MAX_PLAYER_LEVEL_TABLE and MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()]) or 80
        local level = UnitLevel("player")
        local shown = T.db.xpBar ~= false and level < maxLevel
        if not shown then
            xp:SetValue(1)
            rested:SetValue(0)
            label:SetText("")
            for _, tick in ipairs(ticks) do tick:Hide() end
            return
        end
        local current, total = UnitXP("player"), UnitXPMax("player")
        if not total or total <= 0 then total = 1 end
        local exhaustion = GetXPExhaustion() or 0
        xp:SetValue(current / total)
        rested:SetValue(math.min(1, (current + exhaustion) / total))
        for _, tick in ipairs(ticks) do tick:Show() end
        label:SetText(string.format("%s %d : %s - %.2f%%", L("Уровень"), level, T.Short(current), current / total * 100))
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_XP_UPDATE")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:RegisterEvent("UPDATE_EXHAUSTION")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", Update)
    T.UpdateXP = Update
    Ticks()
    Update()

    local function Side(holder, name)
        if not holder then return end
        local side = T.Panel(name)
        side:SetFrameStrata("BACKGROUND")
        side:SetFrameLevel(1)
        side:SetPoint("TOPLEFT", holder, "TOPLEFT", -6, 11)
        side:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 6, -4)
        T.Stripe(side)
        return side
    end
    Side(_G.NarciSirus_bar3, "NarciTwilight_BarLeft")
    Side(_G.NarciSirus_bar4, "NarciTwilight_BarRight")

    local bar5 = _G.NarciSirus_bar5
    if bar5 then
        local rep = CreateFrame("StatusBar", "NarciTwilight_RepBar", UIParent)
        rep:SetFrameStrata("BACKGROUND")
        rep:SetPoint("BOTTOMLEFT", bar5, "TOPLEFT", -1, 3)
        rep:SetPoint("BOTTOMRIGHT", bar5, "TOPRIGHT", -24, 3)
        rep:SetHeight(3)
        rep:SetStatusBarTexture(WHITE)
        rep:GetStatusBarTexture():SetGradientAlpha("VERTICAL",
            T.STRIPE_BOTTOM[1], T.STRIPE_BOTTOM[2], T.STRIPE_BOTTOM[3], 1,
            T.STRIPE_TOP[1], T.STRIPE_TOP[2], T.STRIPE_TOP[3], 1)
        rep:SetMinMaxValues(0, 1)
        local repTrack = rep:CreateTexture(nil, "BACKGROUND")
        repTrack:SetPoint("TOPLEFT", rep, "TOPLEFT", -1, 1)
        repTrack:SetPoint("BOTTOMRIGHT", rep, "BOTTOMRIGHT", 1, -1)
        repTrack:SetTexture(WHITE)
        repTrack:SetVertexColor(0, 0, 0, 1)
        local fill = rep:CreateTexture(nil, "BORDER")
        fill:SetAllPoints(rep)
        fill:SetTexture(WHITE)
        fill:SetVertexColor(T.STRIPE_BOTTOM[1], T.STRIPE_BOTTOM[2], T.STRIPE_BOTTOM[3], 1)

        local percent = T.Text(rep, 12, "RIGHT")
        percent:SetPoint("LEFT", rep, "RIGHT", -18, 1)
        local arrow = T.Text(rep, 13, "LEFT")
        arrow:SetPoint("LEFT", percent, "RIGHT", 2, 0)
        arrow:SetText(">")

        local function Rep()
            local name, standing, low, high, value = GetWatchedFactionInfo()
            if name and high and high > low then
                local share = (value - low) / (high - low)
                rep:SetValue(1)
                percent:SetText(string.format("%d%%", share * 100))
            else
                rep:SetValue(1)
                percent:SetText("0%")
            end
        end
        local repEvents = CreateFrame("Frame")
        repEvents:RegisterEvent("UPDATE_FACTION")
        repEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
        repEvents:SetScript("OnEvent", Rep)
        Rep()
    end

    return true
end

local function StripSection(strip, cells)
    local count = #cells
    local width = strip:GetWidth()
    for index, cell in ipairs(cells) do
        cell:ClearAllPoints()
        cell:SetPoint("CENTER", strip, "LEFT", width * (index - 0.5) / count, 0)
    end
end

local function BuildChat()
    if built.chat then return true end
    local chat = _G.ChatFrame1
    if not chat then return false end
    built.chat = true

    local panel = T.Panel("NarciTwilight_ChatPanel")
    panel:SetFrameStrata("BACKGROUND")
    panel:SetFrameLevel(0)
    panel:SetPoint("TOPLEFT", chat, "TOPLEFT", -8, 27)
    panel:SetPoint("BOTTOMRIGHT", chat, "BOTTOMRIGHT", 7, -22)
    T.Stripe(panel)
    T.chatPanel = panel

    local sound = CreateFrame("Button", nil, panel)
    sound:SetSize(13, 13)
    sound:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -9)
    sound:SetFrameLevel(panel:GetFrameLevel() + 3)
    sound:EnableMouseWheel(true)
    sound.icon = sound:CreateTexture(nil, "ARTWORK")
    sound.icon:SetAllPoints(sound)
    sound.icon:SetVertexColor(0.85, 0.85, 0.85)
    local function PaintSound()
        local muted = GetCVar("Sound_EnableAllSound") == "0"
        sound.icon:SetTexture(T.MEDIA .. (muted and "chat-mute.tga" or "chat-sound.tga"))
    end
    sound:SetScript("OnClick", function()
        SetCVar("Sound_EnableAllSound", GetCVar("Sound_EnableAllSound") == "0" and 1 or 0)
        PaintSound()
        if T.UpdateData then T.UpdateData() end
    end)
    sound:SetScript("OnMouseWheel", function(_, delta)
        local volume = tonumber(GetCVar("Sound_MasterVolume")) or 1
        SetCVar("Sound_MasterVolume", math.max(0, math.min(1, volume + delta * 0.05)))
        if T.UpdateData then T.UpdateData() end
    end)
    sound:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 1, 1)
        Tooltip(self, L("Громкость"), { L("Колёсико - громкость, клик - звук вкл/выкл") })
    end)
    sound:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.85, 0.85, 0.85)
        GameTooltip:Hide()
    end)
    Every(1, PaintSound)
    PaintSound()

    local strip = T.Panel("NarciTwilight_ChatStrip", panel, true)
    strip:SetFrameLevel(panel:GetFrameLevel() + 1)
    strip:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 2, 2)
    strip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    strip:SetHeight(20)

    local menu = IconButton(strip, T.MEDIA .. "chat-plus.tga", 15, function()
        if _G.ChatFrameMenuButton then _G.ChatFrameMenuButton:Click() end
    end)
    menu:SetPoint("LEFT", strip, "LEFT", 3, 0)
    DrawIcon(T.ICON)(menu)

    local eye = IconButton(strip, T.MEDIA .. "chat-eye.tga", 17, function()
        T.chatHidden = not T.chatHidden
        for index = 1, NUM_CHAT_WINDOWS or 10 do
            local frame = _G["ChatFrame" .. index]
            if frame and frame.isDocked or index == 1 then
                if frame then frame:SetAlpha(T.chatHidden and 0 or 1) end
            end
        end
    end)
    eye:SetPoint("RIGHT", strip, "RIGHT", -3, 0)
    DrawIcon(T.ICON)(eye)

    local holder = CreateFrame("Frame", nil, strip)
    holder:SetPoint("TOPLEFT", menu, "TOPRIGHT", 2, 2)
    holder:SetPoint("BOTTOMRIGHT", eye, "BOTTOMLEFT", -2, -2)

    local quests = TextCell(holder, 100)
    quests:SetScript("OnClick", function() ToggleFrame(QuestLogFrame) end)
    quests:SetScript("OnEnter", function(self)
        local count = select(2, GetNumQuestLogEntries()) or 0
        Tooltip(self, L("Задания"), { { L("Задания"), count .. "/" .. (MAX_QUESTLOG_QUESTS or 25) } })
    end)

    local mail = TextCell(holder, 100)
    mail:SetScript("OnEnter", function(self)
        local lines = {}
        if HasNewMail() and GetLatestThreeSenders then
            for _, sender in ipairs({ GetLatestThreeSenders() }) do lines[#lines + 1] = sender end
        end
        Tooltip(self, HasNewMail() and L("Есть почта") or L("Нет почты"), lines)
    end)

    local time = TextCell(holder, 100)
    time:SetScript("OnClick", function()
        if type(_G.ToggleTimeManager) == "function" then _G.ToggleTimeManager() end
    end)
    time:SetScript("OnEnter", function(self)
        local hour, minute = GetGameTime()
        Tooltip(self, date("%d.%m.%Y"), { { TIMEMANAGER_TOOLTIP_REALMTIME or "Realm", string.format("%02d:%02d", hour, minute) },
            { TIMEMANAGER_TOOLTIP_LOCALTIME or "Local", date("%H:%M") } })
    end)

    local cells = { quests, mail, time }
    holder:SetScript("OnSizeChanged", function() StripSection(holder, cells) end)
    StripSection(holder, cells)

    local function Update()
        local r, g, b = LabelColor()
        quests.text:SetTextColor(r, g, b)
        mail.text:SetTextColor(r, g, b)
        time.text:SetTextColor(r, g, b)
        quests.text:SetText(L("Задания"))
        mail.text:SetText(HasNewMail() and L("Есть почта") or L("Нет почты"))
        time.text:SetText(date("%H:%M"))
    end
    Every(1, Update)
    Update()

    return true
end

local function BuildRight()
    if built.right then return end
    built.right = true

    local panel = T.Panel("NarciTwilight_RightPanel")
    panel:SetFrameStrata("BACKGROUND")
    panel:SetFrameLevel(0)
    panel:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 2)
    panel:SetSize(370, 160)
    T.Stripe(panel)
    T.rightPanel = panel

    local strip = T.Panel("NarciTwilight_RightStrip", panel, true)
    strip:SetFrameLevel(panel:GetFrameLevel() + 1)
    strip:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 2, 2)
    strip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    strip:SetHeight(20)
    T.rightStrip = strip

    local menu = IconButton(strip, "Interface\\Buttons\\WHITE8x8", 12, function(self) T.MicroMenu(self) end)
    menu.icon:SetTexture(nil)
    for index = 1, 3 do
        local line = menu:CreateTexture(nil, "ARTWORK")
        line:SetTexture(WHITE)
        line:SetVertexColor(T.ICON[1], T.ICON[2], T.ICON[3])
        line:SetSize(12, 2)
        line:SetPoint("TOP", menu, "TOP", 0, -1 - (index - 1) * 4)
    end
    menu:SetPoint("LEFT", strip, "LEFT", 5, 0)

    local gear = IconButton(strip, "Interface\\Buttons\\UI-OptionsButton", 14, function() API:OpenSettings() end)
    gear:SetPoint("RIGHT", strip, "RIGHT", -3, 0)
    DrawIcon(T.ICON)(gear)

    local spec = TextCell(strip, 120, "LEFT")
    spec:SetPoint("LEFT", menu, "RIGHT", 22, 0)
    local specIcon = spec:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(16, 16)
    specIcon:SetPoint("RIGHT", spec, "LEFT", -3, 0)
    specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    spec:SetScript("OnClick", function()
        if type(_G.ToggleTalentFrame) == "function" then _G.ToggleTalentFrame() end
    end)
    spec:SetScript("OnEnter", function(self)
        local lines = {}
        for tab = 1, GetNumTalentTabs() or 0 do
            local name, _, points = GetTalentTabInfo(tab)
            if name then lines[#lines + 1] = { name, points or 0 } end
        end
        Tooltip(self, TALENTS or "Talents", lines)
    end)

    local perf = TextCell(strip, 110)
    perf:SetPoint("CENTER", strip, "CENTER", 15, 0)

    local money = TextCell(strip, 140, "RIGHT")
    money:SetPoint("RIGHT", gear, "LEFT", -3, 0)
    money:SetScript("OnClick", function() OpenAllBags() end)

    local function Coin(texture)
        return "|T" .. texture .. ":14:14:1:0|t"
    end

    local function Update()
        local r, g, b = LabelColor()
        local hex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)

        local tab = (C_Talent and C_Talent.GetCurrentSpecTabIndex and C_Talent.GetCurrentSpecTabIndex()) or 1
        local name, icon = GetTalentTabInfo(tab)
        spec.text:SetTextColor(r, g, b)
        spec.text:SetText(T.Truncate(name or "", 14))
        specIcon:SetTexture(icon)

        local _, _, latency = GetNetStats()
        perf.text:SetText(string.format("%sFPS:|r %s%d|r %sMS:|r %s%d|r", hex, T.Hex(T.GOOD), math.floor(GetFramerate() + 0.5),
            hex, T.Hex(T.GOOD), latency or 0))

        local copper = GetMoney() or 0
        local gold = math.floor(copper / 10000)
        local silver = math.floor(copper / 100) % 100
        copper = copper % 100
        money.text:SetText(string.format("%s%d|r%s %s%d|r%s %s%d|r%s", hex, gold, Coin("Interface\\MoneyFrame\\UI-GoldIcon"),
            hex, silver, Coin("Interface\\MoneyFrame\\UI-SilverIcon"), hex, copper, Coin("Interface\\MoneyFrame\\UI-CopperIcon")))
    end
    Every(1, Update)
    Update()
end

local MICRO = {
    { "CharacterMicroButton" }, { "SpellbookMicroButton" }, { "TalentMicroButton" },
    { "AchievementMicroButton" }, { "QuestLogMicroButton" }, { "SocialsMicroButton" },
    { "GuildMicroButton" }, { "LFDMicroButton" }, { "CollectionsMicroButton" },
    { "EncounterJournalMicroButton" }, { "StoreMicroButton" }, { "MainMenuMicroButton" },
}

function T.MicroMenu(anchor)
    if not T.menuFrame then
        T.menuFrame = CreateFrame("Frame", "NarciTwilight_MenuDropDown", UIParent, "UIDropDownMenuTemplate")
    end
    local list = {}
    for _, entry in ipairs(MICRO) do
        local button = _G[entry[1]]
        if button then
            local title = button.tooltipText or entry[1]:gsub("MicroButton", "")
            list[#list + 1] = { text = title, notCheckable = true, func = function() button:Click() end }
        end
    end
    EasyMenu(list, T.menuFrame, anchor, 0, 0, "MENU")
end

local function BuildMinimap()
    if built.minimap then return true end
    local map = _G.Minimap
    if not map then return false end
    built.minimap = true

    local panel = T.Panel("NarciTwilight_MinimapPanel")
    panel:SetFrameStrata("BACKGROUND")
    panel:SetFrameLevel(0)
    panel:SetPoint("TOPLEFT", map, "TOPLEFT", -2, 5)
    panel:SetPoint("TOPRIGHT", map, "TOPRIGHT", 2, 5)
    panel:SetPoint("BOTTOM", map, "BOTTOM", 0, -22)
    T.Stripe(panel)

    local strip = T.Panel(nil, panel, true)
    strip:SetFrameLevel(panel:GetFrameLevel() + 1)
    strip:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 2, 2)
    strip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    strip:SetHeight(18)

    local guild = TextCell(strip, 64)
    guild:SetPoint("RIGHT", strip, "CENTER", -2, 0)
    guild:SetScript("OnClick", function()
        if type(_G.ToggleGuildFrame) == "function" then _G.ToggleGuildFrame() else ToggleFriendsFrame(3) end
    end)
    local friends = TextCell(strip, 64)
    friends:SetPoint("LEFT", strip, "CENTER", 2, 0)
    friends:SetScript("OnClick", function() ToggleFriendsFrame(1) end)

    local function Online()
        local guildOnline = 0
        if IsInGuild() then
            for index = 1, GetNumGuildMembers() do
                local _, _, _, _, _, _, _, _, online = GetGuildRosterInfo(index)
                if online then guildOnline = guildOnline + 1 end
            end
        end
        local friendsOnline = 0
        for index = 1, GetNumFriends() do
            local _, _, _, _, connected = GetFriendInfo(index)
            if connected then friendsOnline = friendsOnline + 1 end
        end
        return guildOnline, friendsOnline
    end

    local function Update()
        local r, g, b = LabelColor()
        local hex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
        local guildOnline, friendsOnline = Online()
        guild.text:SetText(string.format("%s%s:|r %s%d|r", hex, L("Гильдия"), T.Hex(T.VALUE), guildOnline))
        friends.text:SetText(string.format("%s%s:|r %s%d|r", hex, L("Друзья"), T.Hex(T.VALUE), friendsOnline))
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("GUILD_ROSTER_UPDATE")
    events:RegisterEvent("FRIENDLIST_UPDATE")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", Update)
    if IsInGuild() then GuildRoster() end
    Update()
    return true
end

local DATA_ROWS = {
    { key = "fps", label = "FPS", max = 200 },
    { key = "ms", label = "MS (Мир)", max = 200 },
    { key = "durability", label = "Прочность", max = 100 },
    { key = "bags", label = "Сумки" },
    { key = "volume", label = "Громкость", max = 100 },
}

local function Durability()
    local lowest = 100
    for slot = 1, 18 do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            lowest = math.min(lowest, current / maximum * 100)
        end
    end
    return lowest
end

local function BagSpace()
    local free, total = 0, 0
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag) or 0
        local freeSlots, family = GetContainerNumFreeSlots(bag)
        if slots > 0 and (family == 0 or family == nil) then
            total = total + slots
            free = free + (freeSlots or 0)
        end
    end
    return total - free, total
end

local function BuildDataPanel()
    if built.data then return end
    built.data = true

    local panel = T.Panel("NarciTwilight_DataPanel")
    T.bgFrames[panel] = nil
    function T.SetDataAlpha(percent)
        panel:SetBackdropColor(T.BG[1], T.BG[2], T.BG[3], math.max(0, math.min(100, percent or 60)) / 100)
    end
    T.SetDataAlpha(T.db.dataOpacity or 60)
    panel:SetFrameStrata("BACKGROUND")
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 3, -2)
    panel:SetSize(136, 105)
    T.Stripe(panel)
    T.dataPanel = panel

    local rows = {}
    for index, info in ipairs(DATA_ROWS) do
        local row = CreateFrame("Button", nil, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -6 - (index - 1) * 19)
        row:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -6 - (index - 1) * 19)
        row:SetHeight(19)
        row:EnableMouseWheel(info.key == "volume")
        row:RegisterForClicks("LeftButtonUp")

        local text = T.Text(row, 12, "LEFT")
        text:SetPoint("LEFT", row, "LEFT", 3, 3)

        local track = row:CreateTexture(nil, "ARTWORK")
        track:SetTexture(WHITE)
        track:SetVertexColor(0.55, 0.55, 0.55, 0.35)
        track:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1)
        track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
        track:SetHeight(1)

        local fill = CreateFrame("StatusBar", nil, row)
        fill:SetStatusBarTexture(WHITE)
        fill:SetMinMaxValues(0, 1)
        fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1)
        fill:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
        fill:SetHeight(2)

        local spark = fill:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetSize(10, 10)
        spark:SetPoint("CENTER", fill:GetStatusBarTexture(), "RIGHT", 0, 0)

        if info.key == "volume" then
            local speaker = row:CreateTexture(nil, "OVERLAY")
            speaker:SetSize(12, 12)
            speaker:SetPoint("RIGHT", row, "RIGHT", -6, 3)
            speaker:SetTexture("Interface\\Common\\VoiceChat-Speaker")
            speaker:SetDesaturated(true)
            speaker:SetVertexColor(0.65, 0.65, 0.65)
            row.speaker = speaker
            row:SetScript("OnMouseWheel", function(_, delta)
                local volume = tonumber(GetCVar("Sound_MasterVolume")) or 1
                volume = math.max(0, math.min(1, volume + delta * 0.05))
                SetCVar("Sound_MasterVolume", volume)
                T.UpdateData()
            end)
            row:SetScript("OnClick", function()
                local enabled = GetCVar("Sound_EnableAllSound") ~= "0"
                SetCVar("Sound_EnableAllSound", enabled and 0 or 1)
                T.UpdateData()
            end)
            row:SetScript("OnEnter", function(self) Tooltip(self, L("Громкость"), { L("Колёсико - громкость, клик - звук вкл/выкл") }) end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        elseif info.key == "bags" then
            row:SetScript("OnClick", function() OpenAllBags() end)
        elseif info.key == "durability" then
            row:SetScript("OnClick", function() ToggleCharacter("PaperDollFrame") end)
        end

        row.text, row.track, row.fill, row.spark, row.info = text, track, fill, spark, info
        rows[index] = row
    end

    local function Paint(row, value, ratio, color)
        row.text:SetText(string.format("|cffffffff%s:|r %s%s|r", L(row.info.label), T.Hex(color), value))
        ratio = math.max(0.01, math.min(1, ratio or 0))
        row.fill:SetValue(ratio)
        row.fill:SetStatusBarColor(color[1], color[2], color[3], 1)
        row.spark:SetVertexColor(color[1], color[2], color[3])
    end

    function T.UpdateData()
        local fps = GetFramerate() or 0
        Paint(rows[1], math.floor(fps + 0.5), fps / 200, fps >= 50 and T.GOOD or fps >= 25 and T.WARN or T.BAD)

        local _, _, latency = GetNetStats()
        latency = latency or 0
        Paint(rows[2], latency, latency / 200, latency < 150 and T.WARN or T.BAD)

        local durability = Durability()
        Paint(rows[3], math.floor(durability + 0.5) .. "%", durability / 100,
            durability >= 50 and T.GOOD or durability >= 20 and T.WARN or T.BAD)

        local used, total = BagSpace()
        local share = total > 0 and used / total or 0
        Paint(rows[4], used .. "/" .. total, share, share < 0.8 and T.GOOD or share < 0.95 and T.WARN or T.BAD)

        local volume = (tonumber(GetCVar("Sound_MasterVolume")) or 0) * 100
        local muted = GetCVar("Sound_EnableAllSound") == "0"
        Paint(rows[5], math.floor(volume + 0.5) .. "%", volume / 100, T.VALUE)
        rows[5].speaker:SetTexture(muted and "Interface\\Common\\VoiceChat-Muted" or "Interface\\Common\\VoiceChat-Speaker")
        rows[5].speaker:SetDesaturated(true)
    end

    Every(1, T.UpdateData)
    T.UpdateData()
end

local function BuildLocation()
    if built.location then return end
    built.location = true

    local zone = T.Panel("NarciTwilight_Location")
    zone:SetFrameStrata("BACKGROUND")
    zone:SetPoint("TOP", UIParent, "TOP", 0, -1)
    zone:SetSize(176, 17)
    local zoneText = T.Text(zone, 12, "CENTER")
    zoneText:SetPoint("LEFT", zone, "LEFT", 3, 0)
    zoneText:SetPoint("RIGHT", zone, "RIGHT", -3, 0)

    local function Box(point, x)
        local box = T.Panel(nil)
        box:SetFrameStrata("BACKGROUND")
        box:SetSize(40, 17)
        box:SetPoint(point, zone, point == "RIGHT" and "LEFT" or "RIGHT", x, 0)
        box.text = T.Text(box, 12, "CENTER")
        box.text:SetAllPoints(box)
        return box
    end
    local xBox = Box("RIGHT", -4)
    local yBox = Box("LEFT", 4)

    T.location = { zone, xBox, yBox }

    local ZONE_COLORS = {
        sanctuary = { 0.41, 0.8, 0.94 },
        arena = { 1, 0.1, 0.1 },
        friendly = { 0.1, 1, 0.1 },
        hostile = { 1, 0.1, 0.1 },
        contested = { 0.95, 0.94, 0.55 },
        combat = { 1, 0.1, 0.1 },
    }

    local function Update()
        local text = GetZoneText() or ""
        local sub = GetSubZoneText()
        if sub and sub ~= "" and sub ~= text then text = text .. ": " .. sub end
        zoneText:SetText(text)
        local color = ZONE_COLORS[GetZonePVPInfo() or ""] or { 0.95, 0.94, 0.55 }
        zoneText:SetTextColor(color[1], color[2], color[3])

        local mapShown = WorldMapFrame and WorldMapFrame:IsShown()
        local x, y = 0, 0
        if not mapShown then
            x, y = GetPlayerMapPosition("player")
        end
        if x and x > 0 then
            xBox.text:SetText(string.format("%.2f", x * 100))
            yBox.text:SetText(string.format("%.2f", y * 100))
        elseif not mapShown then
            xBox.text:SetText("--")
            yBox.text:SetText("--")
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("ZONE_CHANGED")
    events:RegisterEvent("ZONE_CHANGED_INDOORS")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event)
        if event ~= "ZONE_CHANGED" and not (WorldMapFrame and WorldMapFrame:IsShown()) then
            SetMapToCurrentZone()
        end
        Update()
    end)
    Every(0.2, Update)
    Update()
end

local function BuildRaidControl()
    if built.raid then return end
    built.raid = true

    local button = CreateFrame("Button", "NarciTwilight_RaidControl", UIParent)
    button:SetFrameStrata("LOW")
    button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    T.PaintBg(button)
    button:SetBackdropBorderColor(0, 0, 0, 1)
    button:SetSize(120, 17)
    button:SetPoint("TOP", UIParent, "TOP", -360, -1)
    local text = T.Text(button, 12, "CENTER")
    text:SetAllPoints(button)
    text:SetText(L("Управление рейдом"))
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(T.STRIPE_TOP[1], T.STRIPE_TOP[2], T.STRIPE_TOP[3], 1) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)

    local menuFrame = CreateFrame("Frame", "NarciTwilight_RaidDropDown", UIParent, "UIDropDownMenuTemplate")
    button:SetScript("OnClick", function(self)
        local inRaid = GetNumRaidMembers() > 0
        local list = {
            { text = L("Управление рейдом"), isTitle = true, notCheckable = true },
            { text = L("Проверка готовности"), notCheckable = true, func = function() DoReadyCheck() end },
        }
        if type(_G.InitiateRolePoll) == "function" then
            list[#list + 1] = { text = L("Проверка ролей"), notCheckable = true, func = function() _G.InitiateRolePoll() end }
        end
        if inRaid then
            if type(_G.ConvertToParty) == "function" then
                list[#list + 1] = { text = L("Превратить в группу"), notCheckable = true, func = function() _G.ConvertToParty() end }
            end
        elseif GetNumPartyMembers() > 0 then
            list[#list + 1] = { text = L("Превратить в рейд"), notCheckable = true, func = function() ConvertToRaid() end }
        end
        list[#list + 1] = { text = L("Снять метки"), notCheckable = true, func = function()
            for index = 8, 0, -1 do SetRaidTarget("player", index) end
            SetRaidTarget("player", 0)
        end }
        list[#list + 1] = { text = L("Окно рейда"), notCheckable = true, func = function() ToggleFriendsFrame(5) end }
        EasyMenu(list, menuFrame, self, 0, 0, "MENU")
    end)

    local function Update()
        if InCombatLockdown() then return end
        local inGroup = GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
        local lead = IsRaidLeader() or IsRaidOfficer() or IsPartyLeader()
        button:SetShown(T.db.raidControl ~= false and inGroup and lead and true or false)
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("RAID_ROSTER_UPDATE")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:RegisterEvent("PARTY_LEADER_CHANGED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", Update)
    T.UpdateRaidControl = Update
    Update()
end

local function SkinTabs()
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local tab = _G["ChatFrame" .. index .. "Tab"]
        local text = _G["ChatFrame" .. index .. "TabText"]
        if tab and text then
            text:SetFont(T.FONT, 12, "OUTLINE")
            text:SetShadowOffset(0, 0)
            local active = _G.SELECTED_CHAT_FRAME == _G["ChatFrame" .. index]
            if active then
                text:SetTextColor(1, 1, 1)
            else
                text:SetTextColor(T.TAB[1], T.TAB[2], T.TAB[3])
            end
            if tab.narciUnder then tab.narciUnder:Hide() end
        end
    end
end

local function ChatFonts()
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then
            local _, size = frame:GetFont()
            frame:SetFont(T.FONT, size or 11, "")
            frame:SetShadowOffset(1, -1)
        end
    end
end

local function Hooks()
    API:Hook("chattab", function() SkinTabs() end, T.NAME)
    API:Hook("chattabs", function() SkinTabs() end, T.NAME)
    API:Hook("chatapplied", function() ChatFonts(); SkinTabs() end, T.NAME)
    if _G.FCF_Tab_OnClick then hooksecurefunc("FCF_Tab_OnClick", function() SkinTabs() end) end
    ChatFonts()
    SkinTabs()
end

function T.Refresh()
    if T.dataPanel then T.dataPanel:SetShown(T.db.dataPanel ~= false) end
    if T.location then
        for _, box in ipairs(T.location) do box:SetShown(T.db.location ~= false) end
    end
    if T.UpdateRaidControl then T.UpdateRaidControl() end
    if T.UpdateXP then T.UpdateXP() end
    if T.UpdateData then T.UpdateData() end
end

function T.Build()
    BuildDataPanel()
    BuildLocation()
    BuildRaidControl()
    BuildRight()
    Hooks()
    if T.BuildMeter then T.BuildMeter() end
    if T.BuildUnitFrames then T.BuildUnitFrames() end
    if T.BuildExtras then T.BuildExtras() end

    local tries = 0
    local waiter = CreateFrame("Frame")
    waiter:SetScript("OnUpdate", function(self, elapsed)
        self.wait = (self.wait or 0) - elapsed
        if self.wait > 0 then return end
        self.wait = 0.5
        tries = tries + 1
        local done = BuildBars() and BuildChat() and BuildMinimap()
        if done or tries > 40 then self:SetScript("OnUpdate", nil) end
    end)

    T.Refresh()
end
