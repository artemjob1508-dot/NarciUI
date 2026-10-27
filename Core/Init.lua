local addonName, NS = ...
local L = NS.L

NS.VERSION = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "1.5.0"

NS.FONT = "Fonts\\FRIZQT__.TTF"
NS.FONT_SCALE = 1
NS.DFUI = (_G.EditModeManagerFrame ~= nil) or (type(_G.C_EditMode) == "table")

function NS.FS(size)
    return size * NS.FONT_SCALE
end

local OWN_FONTS = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\"

NS.MEDIA_OVERRIDES = NS.MEDIA_OVERRIDES or {}

function NS.OwnFont(file)
    return NS.MEDIA_OVERRIDES[file] or (OWN_FONTS .. file)
end

NS.EXTRA_FONTS = {}

NS.DENSITY_HOOKS = {}

function NS.Densify(window, fn)
    NS.DENSITY_HOOKS[#NS.DENSITY_HOOKS + 1] = { window = window, fn = fn }
end

function NS.DensityFactor(window)
    local windows = NS.db and NS.db.windows
    if type(windows) ~= "table" then return 1 end
    local each = type(windows.each) == "table" and windows.each[window]
    local own = type(each) == "table" and each.density or 100
    return (windows.density or 100) / 100 * own / 100
end

function NS.DensityRows(height, rows, factor)
    local size = math.max(12, math.floor(height * factor + 0.5))
    return size, math.max(1, math.floor(height * rows / size))
end

function NS.ApplyDensity()
    for _, hook in ipairs(NS.DENSITY_HOOKS) do
        pcall(hook.fn, NS.DensityFactor(hook.window))
    end
end

function NS.FontOptions()
    local list = {
        { key = "default",  label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
        { key = "arial",    label = "Arial Narrow",  path = "Fonts\\ARIALN.TTF" },
        { key = "morpheus", label = "Morpheus",      path = "Fonts\\MORPHEUS.ttf" },
        { key = "skurri",   label = "Skurri",        path = "Fonts\\skurri.ttf" },
        { key = "friends",  label = "Friends",       path = "Fonts\\FRIENDS.TTF" },
    }

    list[#list + 1] = { key = "ptsans",     label = "PT Sans Narrow", path = NS.OwnFont("PTSansNarrow.ttf") }
    list[#list + 1] = { key = "magistral",  label = "Magistral",      path = NS.OwnFont("Magistral.ttf") }
    list[#list + 1] = { key = "expressway", label = "Expressway",     path = NS.OwnFont("Expressway.ttf") }
    list[#list + 1] = { key = "continuum",  label = "Continuum",      path = NS.OwnFont("ContinuumMedium.ttf") }
    list[#list + 1] = { key = "actionman",  label = "Action Man",     path = NS.OwnFont("ActionMan.ttf") }
    list[#list + 1] = { key = "homespun",   label = "Homespun",       path = NS.OwnFont("Homespun.ttf") }
    list[#list + 1] = { key = "diediedie",  label = "Die Die Die",    path = NS.OwnFont("DieDieDie.ttf") }

    for _, extra in ipairs(NS.EXTRA_FONTS) do list[#list + 1] = extra end

    return list
end

function NS.FontWorks(path)
    if not path or not UIParent then return false end
    local probe = UIParent:CreateFontString(nil, "OVERLAY")
    probe:SetFont(path, 12, "")
    local loaded = probe:GetFont()
    probe:Hide()
    return loaded ~= nil
end

function NS.ApplyFont()
    local key = NS.db and NS.db.font or "default"

    for _, option in ipairs(NS.FontOptions()) do
        if option.key == key and NS.FontWorks(option.path) then
            NS.FONT = option.path
        end
    end

    local theme = NS.db and NS.db.theme
    NS.FONT_SCALE = math.max(0.8, math.min(1.3, ((theme and theme.fontScale) or 100) / 100))

    if NS.QuestStyle then NS.QuestStyle.FONT = NS.FONT end
end

local DEFAULTS = {
    minimapButton = true,
    minimapAngle = 3.84,
    showItemLevel = true,
    showEnchantInfo = true,
    showGemInfo = true,
    showStatsPanel = true,
    showComparison = true,
    screenshotQuality = 3,
    scaleOverride = nil,
    worldDim = 55,
    accentColor = "emerald",
    showItemNames = true,
    modelBacklight = true,
    animations = true,
    hideEmptySlots = false,
    nameLength = 24,
    locale = "auto",
    hideBlizzardUI = true,
    showStatCaps = true,
    openPanel = nil,
    rememberModelView = false,
    showInCombat = false,
    replaceTalents = true,
    replaceSpellbook = true,
    replaceGuild = true,
    replaceGroupFinder = true,
    replaceCollections = true,
    replaceAchievements = true,
    replaceAdventure = true,
    replaceChallenges = true,
    replaceHeadHunting = true,
    replaceSocial = true,
    skinStore = true,
    skinMenus = true,
    replaceGameMenu = true,
    mountFavorites = {},
    epgpLog = {},
    guildAdmin = {
        muteRank = 4,
        useOfficerNotes = true,
        notify = true,
        cleanupDays = 30,
        cleanupLevel = 80,
        excludePublicNote = false,
        excludeOfficerNote = false,
        mutes = {},
    },
    slotFlyout = true,
    replaceCharacter = true,
    theme = {
        bgTone = "obsidian",
        bgDensity = 100,
        border = "thin",
        shadow = "normal",
        corners = "medium",
        decor = "styled",
        textTone = "neutral",
        contrast = "normal",
        fontScale = 100,
        animSpeed = "normal",
        motion = "slide",
        sounds = false,
    },
    quests = {
        channels = { party = true, raid = true, guild = false },
        banners = true,
        chatOutput = false,
        ownBanners = false,
        announce = false,
        everyoneNotice = true,
        events = {},
        replaceLog = true,
        skinWorldMap = true,
        revealMap = true,
    },
}

local function FillDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            FillDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local DEFAULT_PROFILE = "Общий"

local function CharKey()
    local name = UnitName("player") or GetUnitName("player") or "?"
    local realm = GetRealmName() or "?"
    return name .. " - " .. realm
end

local function Root()
    if not NarcissusSirusDB then NarcissusSirusDB = {} end
    local root = NarcissusSirusDB

    if not root.profiles then
        local legacy = {}

        for key, value in pairs(root) do
            legacy[key] = value
            root[key] = nil
        end

        root.profiles = { [DEFAULT_PROFILE] = legacy }
        root.chars = {}
    end

    root.chars = root.chars or {}
    root.profiles = root.profiles or {}

    return root
end

local function ResolveProfile(root)
    local own = root.chars[CharKey()]
    if own and own ~= DEFAULT_PROFILE and type(root.profiles[own]) == "table" then return own end
    local _, class = UnitClass("player")
    local rule = class and type(root.byClass) == "table" and root.byClass[class]
    if rule and type(root.profiles[rule]) == "table" then return rule end
    return DEFAULT_PROFILE
end

local function InitDB()
    local root = Root()
    local name = ResolveProfile(root)

    if type(root.profiles[name]) ~= "table" then root.profiles[name] = {} end

    local profile = root.profiles[name]
    FillDefaults(profile, DEFAULTS)

    if profile.openPanel == nil then
        profile.openPanel = profile.showStatsPanel and "StatsPanel" or "none"
    end

    NS.profileName = name
    NS.db = profile

    return profile
end

local Profiles = {}
NS.Profiles = Profiles

function Profiles:Current()
    return NS.profileName or DEFAULT_PROFILE
end

Profiles.DEFAULT = DEFAULT_PROFILE
Profiles.CharKey = CharKey

function Profiles:Own()
    return Root().chars[CharKey()] or DEFAULT_PROFILE
end

function Profiles:Resolve()
    return ResolveProfile(Root())
end

function Profiles:ClassRules()
    local root = Root()
    if type(root.byClass) ~= "table" then root.byClass = {} end
    return root.byClass
end

function Profiles:SpecRules()
    local root = Root()
    if type(root.specProfiles) ~= "table" then root.specProfiles = {} end
    local key = CharKey()
    if type(root.specProfiles[key]) ~= "table" then root.specProfiles[key] = {} end
    return root.specProfiles[key]
end

function Profiles:Characters()
    local list = {}
    for key, name in pairs(Root().chars) do
        list[#list + 1] = { key = key, profile = name }
    end
    table.sort(list, function(a, b) return a.key < b.key end)
    return list
end

function Profiles:CheckSpec()
    local spec = NS.Movers and NS.Movers.CurrentSpec and NS.Movers.CurrentSpec()
    if not spec or spec == self.lastSpec then return end
    if InCombatLockdown() then return end
    self.lastSpec = spec
    local target = self:SpecRules()[spec]
    if not target or target == self:Current() or type(Root().profiles[target]) ~= "table" then return end
    if not NS.Widgets or not NS.Widgets.ShowConfirm then return end
    local L = NS.L
    NS.Widgets.ShowConfirm(
        string.format(L["Специализация сменилась. Переключить профиль на «%s»? Интерфейс будет перезагружен."], target),
        L["Переключить"],
        function() Profiles:Use(target) end)
end

local specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("PLAYER_LOGIN")
specFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
specFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
specFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if specFrame.RegisterCustomEvent then
    pcall(specFrame.RegisterCustomEvent, specFrame, "PLAYER_TALENT_UPDATE_EX")
end
specFrame:SetScript("OnEvent", function(_, event)
    if not NS.After then return end
    if specFrame.pending then return end
    specFrame.pending = true
    NS.After(event == "PLAYER_LOGIN" and 4 or 1, function()
        specFrame.pending = nil
        Profiles:CheckSpec()
    end)
end)

function Profiles:List()
    local root = Root()
    local list = {}

    for name in pairs(root.profiles) do
        list[#list + 1] = name
    end

    table.sort(list)
    return list
end

function Profiles:Use(name)
    local root = Root()
    if type(name) ~= "string" or name == "" then return end

    if type(root.profiles[name]) ~= "table" then root.profiles[name] = {} end
    root.chars[CharKey()] = name

    NS.Print("профиль: " .. name .. ", интерфейс будет перезагружен")
    ReloadUI()
end

function Profiles:Create(name, copyFrom)
    local root = Root()
    if type(name) ~= "string" or name == "" then return end

    if root.profiles[name] then
        NS.Print("профиль " .. name .. " уже есть")
        return
    end

    local source = copyFrom and root.profiles[copyFrom]
    local created = {}

    if type(source) == "table" then
        local function Copy(from, to)
            for key, value in pairs(from) do
                if type(value) == "table" then
                    to[key] = {}
                    Copy(value, to[key])
                else
                    to[key] = value
                end
            end
        end

        Copy(source, created)
    end

    root.profiles[name] = created
    self:Use(name)
end

function Profiles:CleanName(name)
    if type(name) ~= "string" then return end
    name = name:gsub("|", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    return name
end

function Profiles:Rename(old, new)
    local root = Root()
    new = self:CleanName(new)
    if not new or not root.profiles[old] then return false end
    if old == DEFAULT_PROFILE then
        NS.Print("общий профиль переименовать нельзя")
        return false
    end
    if new == old then return false end
    if root.profiles[new] then
        NS.Print("профиль " .. new .. " уже есть")
        return false
    end

    root.profiles[new] = root.profiles[old]
    root.profiles[old] = nil

    for key, value in pairs(root.chars) do
        if value == old then root.chars[key] = new end
    end
    for class, value in pairs(root.byClass or {}) do
        if value == old then root.byClass[class] = new end
    end
    for _, rules in pairs(root.specProfiles or {}) do
        for spec, value in pairs(rules) do
            if value == old then rules[spec] = new end
        end
    end

    NS.Print("профиль " .. old .. " теперь называется " .. new)
    ReloadUI()
    return true
end

function Profiles:CreateFromTemplate(name, data)
    local root = Root()
    if type(name) ~= "string" or name == "" or type(data) ~= "table" then return end
    if root.profiles[name] then return false end

    local function Copy(from)
        local to = {}
        for key, value in pairs(from) do
            to[key] = type(value) == "table" and Copy(value) or value
        end
        return to
    end

    root.profiles[name] = Copy(data)
    self:Use(name)
    return true
end

function Profiles:Delete(name)
    local root = Root()
    if name == DEFAULT_PROFILE then
        NS.Print("общий профиль удалить нельзя")
        return
    end

    if not root.profiles[name] then return end

    root.profiles[name] = nil

    for key, value in pairs(root.chars) do
        if value == name then root.chars[key] = DEFAULT_PROFILE end
    end
    for class, value in pairs(root.byClass or {}) do
        if value == name then root.byClass[class] = nil end
    end
    for _, rules in pairs(root.specProfiles or {}) do
        for spec, value in pairs(rules) do
            if value == name then rules[spec] = nil end
        end
    end

    NS.Print("профиль " .. name .. " удалён")

    if self:Current() == name then
        self:Use(DEFAULT_PROFILE)
    end
end

function Profiles:Reset()
    local root = Root()
    local name = self:Current()

    root.profiles[name] = {}
    NS.Print("профиль " .. name .. " сброшен, интерфейс будет перезагружен")
    ReloadUI()
end

local EXPORT_PREFIX = "NARCI1!"

local EXPORT_SKIP = {
    epgpLog = true,
    guildAdmin = true,
    mountFavorites = true,
    savedNameCVars = true,
    nameCVarsRepaired = true,
    tierOverride = true,
}

local function EncodeString(text)
    return (text:gsub("[^%w_%.%-]", function(char)
        return string.format("%%%02X", char:byte())
    end))
end

local function DecodeString(text)
    return (text:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function Encode(value, out, depth)
    local kind = type(value)

    if kind == "string" then
        out[#out + 1] = "S" .. EncodeString(value) .. "~"
    elseif kind == "number" then
        out[#out + 1] = "N" .. EncodeString(tostring(value)) .. "~"
    elseif kind == "boolean" then
        out[#out + 1] = value and "B1" or "B0"
    elseif kind == "table" then
        if depth > 20 then return false end
        out[#out + 1] = "T"
        for key, item in pairs(value) do
            local keyKind, itemKind = type(key), type(item)
            local skip = depth == 0 and EXPORT_SKIP[key]
            if not skip and (keyKind == "string" or keyKind == "number")
                and (itemKind == "string" or itemKind == "number" or itemKind == "boolean" or itemKind == "table") then
                Encode(key, out, depth + 1)
                if Encode(item, out, depth + 1) == false then return false end
            end
        end
        out[#out + 1] = "E"
    end

    return true
end

local function Decode(text, position, depth)
    local tag = text:sub(position, position)

    if tag == "S" or tag == "N" then
        local finish = text:find("~", position + 1, true)
        if not finish then return nil end
        local raw = DecodeString(text:sub(position + 1, finish - 1))
        if tag == "N" then
            local number = tonumber(raw)
            if not number then return nil end
            return number, finish + 1
        end
        return raw, finish + 1
    elseif tag == "B" then
        local flag = text:sub(position + 1, position + 1)
        if flag ~= "0" and flag ~= "1" then return nil end
        return flag == "1", position + 2
    elseif tag == "T" then
        if depth > 20 then return nil end
        local result = {}
        position = position + 1
        while true do
            if text:sub(position, position) == "E" then return result, position + 1 end
            local key, item
            key, position = Decode(text, position, depth + 1)
            if key == nil or type(key) == "table" or type(key) == "boolean" then return nil end
            item, position = Decode(text, position, depth + 1)
            if item == nil then return nil end
            result[key] = item
        end
    end

    return nil
end

function Profiles:Export()
    local out = {}
    if not Encode(NS.db or {}, out, 0) then return end
    return EXPORT_PREFIX .. table.concat(out)
end

function Profiles:Decode(text)
    if type(text) ~= "string" then return end
    text = text:gsub("%s", "")
    if text:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then return end

    local body = text:sub(#EXPORT_PREFIX + 1)
    local ok, result, finish = pcall(Decode, body, 1, 0)
    if not ok or type(result) ~= "table" or finish ~= #body + 1 then return end

    return result
end

function Profiles:Import(text)
    local data = self:Decode(text)
    if not data then return false end

    local root = Root()
    local name = self:Current()
    local old = root.profiles[name] or {}

    for key in pairs(EXPORT_SKIP) do
        data[key] = old[key]
    end

    root.profiles[name] = data
    ReloadUI()
    return true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        if NS.ApplyLocale then NS.ApplyLocale(NS.db.locale) end
        NS.ApplyFont()
        NS.ApplyDensity()
        NS.initialized = true
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if NS.initialized then
            local before = NS.profileName
            InitDB()
            if NS.profileName ~= before and NS.ApplyLocale then NS.ApplyLocale(NS.db.locale) end
            NS.ApplyFont()
            NS.ApplyDensity()
            NS.firstRun = NS.Installer and NS.Installer:IsFirstRun() or false
            NS:OnPlayerLogin()
        end
    end
end)

SLASH_NARCISSUS1 = "/narci"
SLASH_NARCISSUS2 = "/narcissus"
SlashCmdList["NARCISSUS"] = function(msg)
    local raw = strtrim(msg)
    msg = NS.Lower and NS.Lower(raw) or raw:lower()
    if msg == "config" or msg == "settings" then
        NS:ToggleSettings()
    elseif msg == "quests" or msg == "quest" or msg == "задания" then
        NS:ToggleQuestLog()
    elseif msg:sub(1, 6) == "quests" then
        NS:QuestCommand(msg:sub(8))
    elseif msg == "talents grid" then
        if NS.TalentPanel and NS.TalentPanel.Diagnose then
            NS.TalentPanel:Diagnose()
        end
    elseif msg == "guild" or msg == "гильдия" then
        if NS.GuildPanel then
            local ok, err = pcall(function() NS.GuildPanel:Toggle() end)
            if not ok then NS.Print("окно гильдии: " .. tostring(err)) end
        else
            NS.Print("панель гильдии не загружена")
        end
    elseif msg == "install" or msg == "мастер" then
        if NS.Installer then NS.Installer:Show() end
    elseif msg == "lfg" or msg == "группа" then
        if NS.GroupFinderPanel then
            local ok, err = pcall(function() NS.GroupFinderPanel:Toggle() end)
            if not ok then NS.Print("поиск группы: " .. tostring(err)) end
        else
            NS.Print("панель поиска группы не загружена, перезапустите клиент")
        end
    elseif msg == "collections" or msg == "коллекция" then
        if NS.CollectionsPanel then
            local ok, err = pcall(function() NS.CollectionsPanel:Toggle() end)
            if not ok then NS.Print("коллекция: " .. tostring(err)) end
        else
            NS.Print("панель коллекции не загружена, перезапустите клиент")
        end
    elseif msg == "achievements" or msg == "достижения" then
        if NS.AchievementsPanel then
            local ok, err = pcall(function() NS.AchievementsPanel:Toggle() end)
            if not ok then NS.Print("достижения: " .. tostring(err)) end
        else
            NS.Print("панель достижений не загружена, перезапустите клиент")
        end
    elseif msg == "adventure" or msg == "приключения" then
        if NS.AdventurePanel then
            local ok, err = pcall(function() NS.AdventurePanel:Toggle() end)
            if not ok then NS.Print("приключения: " .. tostring(err)) end
        else
            NS.Print("панель приключений не загружена, перезапустите клиент")
        end
    elseif msg == "challenges" or msg == "испытания" then
        if NS.ChallengePanel then
            local ok, err = pcall(function() NS.ChallengePanel:Toggle() end)
            if not ok then NS.Print("испытания: " .. tostring(err)) end
        else
            NS.Print("панель испытаний не загружена, перезапустите клиент")
        end
    elseif msg == "headhunting" or msg == "охота" then
        if NS.HeadHuntingPanel then
            local ok, err = pcall(function() NS.HeadHuntingPanel:Toggle() end)
            if not ok then NS.Print("охота за головами: " .. tostring(err)) end
        else
            NS.Print("панель охоты за головами не загружена, перезапустите клиент")
        end
    elseif msg == "social" or msg == "общение" then
        if NS.SocialPanel then
            local ok, err = pcall(function() NS.SocialPanel:Toggle() end)
            if not ok then NS.Print("общение: " .. tostring(err)) end
        else
            NS.Print("панель общения не загружена, перезапустите клиент")
        end
    elseif msg == "addons" or msg == "модификации" then
        if NS.AddonListPanel then NS.AddonListPanel:Toggle() end
    elseif msg == "what" or msg == "что" then
        NS.WhatIsUnderCursor()
    elseif msg == "move" or msg == "расставить" then
        if NS.Movers then NS.Movers:Toggle() end
    elseif msg == "esc" then
        NS.db.replaceGameMenu = not (NS.db.replaceGameMenu ~= false)
        NS.Print(NS.db.replaceGameMenu and "меню Esc в стиле аддона"
            or "меню Esc обычное, нужен /reload")
    elseif msg:match("^bars size ") then
        if NS.ActionBars then NS.ActionBars:SetSize(msg:match("^bars size (%S+)$")) end
    elseif msg:match("^bars gap ") then
        if NS.ActionBars then NS.ActionBars:SetSpacing(msg:match("^bars gap (%S+)$")) end
    elseif msg:match("^bars row ") then
        if NS.ActionBars then
            local key, value = msg:match("^bars row (%S+) (%S+)$")
            NS.ActionBars:SetPerRow(key, value)
        end
    elseif msg == "bars keys" then
        if NS.ActionBars then NS.ActionBars:ToggleHotKeys() end
    elseif msg == "bars move" then
        if NS.ActionBars then NS.ActionBars:Move() end
    elseif msg == "bars" then
        if NS.ActionBars then NS.ActionBars:Toggle() end
    elseif msg:match("^ui scale ") then
        if NS.PlayerUI then NS.PlayerUI:SetScale(msg:match("^ui scale (%S+)$")) end
    elseif msg == "ui move" then
        if NS.PlayerUI then NS.PlayerUI:Move() end
        if NS.ActionBars then NS.ActionBars:Move() end
    elseif msg == "ui power" then
        if NS.PlayerUI then NS.PlayerUI:TogglePower() end
    elseif msg == "ui" then
        if NS.PlayerUI then NS.PlayerUI:Toggle() end
    elseif msg:match("^cd max ") then
        if NS.CooldownBar then NS.CooldownBar:SetMax(msg:match("^cd max (%S+)$")) end
    elseif msg:match("^cd width ") then
        if NS.CooldownBar then NS.CooldownBar:SetWidth(msg:match("^cd width (%S+)$")) end
    elseif msg == "cd lock" then
        if NS.CooldownBar then NS.CooldownBar:Lock() end
    elseif msg == "cd" or msg == "кулдауны" then
        if NS.CooldownBar then NS.CooldownBar:Toggle() end
    elseif msg:match("^menu dump") then
        if NS.MenuSkins then
            local name, depth = raw:match("^[Mm]enu [Dd]ump (%S+)%s*(%d*)$")
            NS.MenuSkins:Dump(name or "PromoCodeFrame", depth)
        end
    elseif msg == "menu debug" then
        if NS.MenuSkins then NS.MenuSkins:Debug() end
    elseif msg == "menu status" then
        if NS.MenuSkins then NS.MenuSkins:Status() end
    elseif msg == "menu redo" then
        if NS.MenuSkins then NS.MenuSkins:Redo() end
    elseif msg == "menu" or msg == "окна" then
        if NS.MenuSkins then NS.MenuSkins:Toggle() end
    elseif msg:match("^store scale ") then
        if NS.StoreSkin then NS.StoreSkin:SetShare(msg:match("^store scale (.+)$")) end
    elseif msg == "store status" then
        if NS.StoreSkin then NS.StoreSkin:Status() end
    elseif msg == "store redo" then
        if NS.StoreSkin then NS.StoreSkin:Redo() end
    elseif msg == "store" or msg == "магазин" then
        NS.db.skinStore = not (NS.db.skinStore ~= false)
        NS.Print(NS.db.skinStore and "скин магазина включён, нужен /reload"
            or "скин магазина выключен, нужен /reload")
    elseif msg == "social stock" then
        NS.db.replaceSocial = not (NS.db.replaceSocial ~= false)
        NS.Print(NS.db.replaceSocial and "общение открывает панель аддона"
            or "общение открывает окно клиента")
    elseif msg == "headhunting stock" then
        NS.db.replaceHeadHunting = not (NS.db.replaceHeadHunting ~= false)
        NS.Print(NS.db.replaceHeadHunting and "охота за головами открывает панель аддона"
            or "охота за головами открывает окно клиента")
    elseif msg == "challenges stock" then
        NS.db.replaceChallenges = not (NS.db.replaceChallenges ~= false)
        NS.Print(NS.db.replaceChallenges and "испытания открывают панель аддона"
            or "испытания открывают окно клиента")
    elseif msg == "adventure stock" then
        NS.db.replaceAdventure = not (NS.db.replaceAdventure ~= false)
        NS.Print(NS.db.replaceAdventure and "приключения открывают панель аддона"
            or "приключения открывают окно клиента")
    elseif msg == "achievements stock" then
        NS.db.replaceAchievements = not (NS.db.replaceAchievements ~= false)
        NS.Print(NS.db.replaceAchievements and "достижения открывают панель аддона"
            or "достижения открывают окно клиента")
    elseif msg == "collections stock" then
        NS.db.replaceCollections = not (NS.db.replaceCollections ~= false)
        NS.Print(NS.db.replaceCollections and "коллекция открывает панель аддона"
            or "коллекция открывает окно клиента")
    elseif msg == "lfg stock" then
        NS.db.replaceGroupFinder = not (NS.db.replaceGroupFinder ~= false)
        NS.Print(NS.db.replaceGroupFinder and "поиск группы открывает панель аддона"
            or "поиск группы открывает окно клиента")
    elseif msg == "guild files" then
        NS.Print(string.format("GuildPanel %s, GuildAdmin %s, GuildAdminView %s, GuildMemberCard %s",
            NS.GuildPanel and "+" or "-",
            NS.GuildAdmin and "+" or "-",
            NS.GuildAdminView and "+" or "-",
            NS.GuildMemberCard and "+" or "-"))
    elseif msg == "guild stock" then
        NS.db.replaceGuild = not (NS.db.replaceGuild ~= false)
        NS.Print(NS.db.replaceGuild and "окно гильдии открывает панель аддона"
            or "окно гильдии открывает окно клиента")
    elseif msg == "spells" or msg == "заклинания" then
        NS.db.replaceSpellbook = not (NS.db.replaceSpellbook ~= false)
        NS.Print(NS.db.replaceSpellbook and "клавиша книги заклинаний открывает панель аддона"
            or "клавиша книги заклинаний открывает окно клиента")
    elseif msg == "talents" or msg == "таланты" then
        NS.db.replaceTalents = not (NS.db.replaceTalents ~= false)
        NS.Print(NS.db.replaceTalents and "клавиша талантов открывает панель аддона"
            or "клавиша талантов открывает окно клиента")
    elseif msg == "threat" or msg == "угроза" then
        if NS.ThreatMeter then NS.ThreatMeter:Toggle() end
    elseif msg == "copy" then
        if NS.ChatExtras then NS.ChatExtras:Copy() end
    elseif msg == "focus" then
        NS.Print("наведите курсор на нужное место, через 4 секунды будет ответ")
        NS.After(4, function()
            local focus = GetMouseFocus()
            local depth = 0
            while focus and depth < 6 do
                NS.Print(string.format("%d: %s [%s] strata=%s level=%s mouse=%s shown=%s alpha=%.2f", depth,
                    tostring(focus.GetName and focus:GetName()), tostring(focus.GetObjectType and focus:GetObjectType()),
                    tostring(focus.GetFrameStrata and focus:GetFrameStrata()), tostring(focus.GetFrameLevel and focus:GetFrameLevel()),
                    tostring(focus.IsMouseEnabled and focus:IsMouseEnabled()), tostring(focus.IsShown and focus:IsShown()),
                    focus.GetEffectiveAlpha and focus:GetEffectiveAlpha() or -1))
                focus = focus.GetParent and focus:GetParent()
                depth = depth + 1
            end
            local menu = _G.NarcissusSirus_GameMenu
            if menu then
                NS.Print(string.format("menu: strata=%s level=%s shown=%s", menu:GetFrameStrata(), menu:GetFrameLevel(), tostring(menu:IsShown())))
                local row = NS.GameMenuPanel and NS.GameMenuPanel.frame and NS.GameMenuPanel.frame.rows[1]
                if row then
                    NS.Print(string.format("row1: level=%s mouse=%s over=%s", row:GetFrameLevel(), tostring(row:IsMouseEnabled()), tostring(MouseIsOver(row))))
                end
            end
        end)
    elseif msg == "roles" then
        if NS.RaidFrames and NS.RaidFrames.DiagnoseRoles then NS.RaidFrames:DiagnoseRoles() end
    elseif msg == "debuffs" then
        if NS.RaidFrames and NS.RaidFrames.DiagnoseDebuffs then NS.RaidFrames:DiagnoseDebuffs() end
    elseif msg == "vehicle" then
        if NS.WindowSkins and NS.WindowSkins.DiagnoseVehicle then NS.WindowSkins:DiagnoseVehicle() end
    elseif msg == "portrait" then
        if NS.PlayerUI and NS.PlayerUI.DiagnosePortraits then NS.PlayerUI:DiagnosePortraits() end
    elseif msg:match("^portrait %d+$") or msg == "portrait test" then
        if NS.PlayerUI and NS.PlayerUI.TestPortrait then
            NS.PlayerUI:TestPortrait(tonumber(msg:match("%d+")))
        end
    elseif msg == "stats" then
        NS:ToggleStatsPanel()
    elseif msg == "title" then
        NS:ToggleTitleManager()
    elseif msg == "preview" then
        NS:ToggleCharPreview()
    elseif msg == "outfit" or msg == "outfits" then
        NS:ToggleOutfitManager()
    elseif msg == "screenshot" then
        NS:TakeScreenshot()
    elseif msg:sub(1, 5) == "save " then
        local name = raw:sub(6)
        if NS.OutfitManager then NS.OutfitManager:CaptureCurrent(name) end
    elseif msg:sub(1, 5) == "load " then
        local name = raw:sub(6)
        if NS.OutfitManager and not NS.OutfitManager:EquipOutfit(name) then
            NS.Print(L["набор не найден: "] .. name)
        end
    elseif msg:sub(1, 7) == "delete " then
        local name = raw:sub(8)
        if NS.OutfitManager then NS.OutfitManager:DeleteOutfit(name) end
    elseif msg == "list" then
        local outfits = NarcissusSirusDB and NarcissusSirusDB.outfits or {}
        if #outfits == 0 then
            NS.Print(L["сохранённых наборов нет"])
        else
            for _, outfit in ipairs(outfits) do NS.Print("  " .. tostring(outfit.name)) end
        end
    elseif msg == "prio" or msg:sub(1, 5) == "prio " then
        local arg = strtrim(msg:sub(6))
        if not NS.StatPriority then
            NS.Print(L["модуль приоритета характеристик не загружен"])
        elseif arg == "" then
            NS.StatPriority:Print()
        elseif arg == "auto" or arg == "off" then
            NS.StatPriority:SetTierOverride(nil)
        else
            local n = tonumber(arg:match("(%d+)"))
            if n and n >= 1 and n <= 10 then
                NS.StatPriority:SetTierOverride(n)
            else
                NS.Print(L["укажите номер набора от 1 до 10, либо auto"])
            end
        end
    elseif msg == "dim" or msg:sub(1, 4) == "dim " then
        local arg = strtrim(msg:sub(5))
        local n = tonumber(arg:match("(%d+)"))
        if arg == "" then
            NS.Print(L["затемнение мира: "] .. tostring(NS.db and NS.db.worldDim) ..
                     L[" (задать: /narci dim 0..100)"])
        elseif n and n >= 0 and n <= 100 then
            NS.db.worldDim = n
            if NS.NarciUI then NS.NarciUI:ApplyWorldDim() end
            NS.Print(L["затемнение мира: "] .. n)
        else
            NS.Print(L["укажите значение от 0 до 100"])
        end
    elseif msg == "scale" or msg:sub(1, 6) == "scale " then
        local arg = strtrim(msg:sub(7))
        local ui = NS.NarciUI
        if not ui then
            NS.Print(L["окно персонажа ещё не создано"])
        elseif arg == "" then
            NS.Print(format(L["масштаб: %.2f (расчётный %.2f%s)"],
                ui._appliedScale or 1, ui:GetAutoScale(),
                NS.db.scaleOverride and L[", закреплён вручную"] or ""))
        elseif arg == "auto" or arg == "off" then
            NS.db.scaleOverride = nil
            ui:ApplyScale()
            NS.Print(format(L["масштаб: автоподбор, %.2f"], ui._appliedScale or 1))
        else
            local n = tonumber((arg:gsub(",", ".")))
            if n and n >= 0.4 and n <= 1.5 then
                NS.db.scaleOverride = n
                ui:ApplyScale()
                NS.Print(format(L["масштаб закреплён: %.2f"], n))
            else
                NS.Print(L["укажите значение от 0.4 до 1.5, либо auto"])
            end
        end
    elseif msg == "bags" then
        if NS.NarciUI then NS.NarciUI:PrintBagDiagnostics() end
    else
        NS:ToggleCharacterUI()
    end
end
