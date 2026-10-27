local addonName, NS = ...
local L = NS.L

local Installer = {}
NS.Installer = Installer

local WHITE = "Interface\\Buttons\\WHITE8x8"
local W, H = 680, 470
local SIDE = 190
local FOOT = 46
local PAD = 22

local PARTS = {
    { path = { "playerUI", "enabled" },    default = false, label = "Рамки игрока и цели" },
    { path = { "actionBars", "enabled" },  default = false, label = "Панели команд" },
    { path = { "castBar", "enabled" },     default = false, label = "Полоса заклинания" },
    { path = { "auras", "enabled" },       default = true,  label = "Бафы" },
    { path = { "minimap", "enabled" },     default = true,  label = "Миникарта" },
    { path = { "chat", "enabled" },        default = false, label = "Чат" },
    { path = { "tooltip", "enabled" },     default = false, label = "Подсказки" },
    { path = { "dataTexts", "enabled" },   default = false, label = "Показатели" },
    { path = { "raidFrames", "enabled" },  default = true,  label = "Рейд-фреймы" },
    { path = { "nameplates", "enabled" },  default = true,  label = "Неймплейты" },
    { path = { "bags", "enabled" },        default = true,  label = "Сумки и банк" },
    { path = { "cooldownBar", "enabled" }, default = true,  label = "Полоса восстановления" },
    { path = { "threat", "enabled" },      default = true,  label = "Измеритель угрозы" },
}

local STEPS = {
    { key = "welcome", title = "Добро пожаловать" },
    { key = "profile", title = "Профиль" },
    { key = "theme",   title = "Цвет и окна" },
    { key = "look",    title = "Вид элементов" },
    { key = "parts",   title = "Части интерфейса" },
    { key = "scale",   title = "Масштаб" },
    { key = "finish",  title = "Готово" },
}

local plan

local function Root()
    if type(NarcissusSirusDB) ~= "table" then NarcissusSirusDB = {} end
    local root = NarcissusSirusDB
    if type(root.installed) ~= "table" then root.installed = {} end
    if type(root.profiles) ~= "table" then root.profiles = {} end
    if type(root.chars) ~= "table" then root.chars = {} end
    return root
end

local function CharKey()
    return NS.Profiles and NS.Profiles.CharKey and NS.Profiles.CharKey() or ((UnitName("player") or "?") .. " - " .. (GetRealmName() or "?"))
end

local function GetPath(tbl, path)
    for _, key in ipairs(path) do
        if type(tbl) ~= "table" then return end
        tbl = tbl[key]
    end
    return tbl
end

local function SetPath(tbl, path, value)
    for index = 1, #path - 1 do
        local key = path[index]
        if type(tbl[key]) ~= "table" then tbl[key] = {} end
        tbl = tbl[key]
    end
    tbl[path[#path]] = value
end

local function Merge(into, from)
    for key, value in pairs(from) do
        if type(value) == "table" then
            if type(into[key]) ~= "table" then into[key] = {} end
            Merge(into[key], value)
        else
            into[key] = value
        end
    end
    return into
end

local function ReadyList()
    return NS.Settings and NS.Settings.READY_PROFILES or {}
end

local function ReadyEntry(key)
    for _, entry in ipairs(ReadyList()) do
        if entry.key == key then return entry end
    end
end

local function NewPlan()
    return { profile = "current", ready = ReadyList()[1] and ReadyList()[1].key, values = {} }
end

local function Base()
    if plan.profile == "own" then
        return Root().profiles[CharKey()] or {}
    elseif plan.profile == "ready" then
        local entry = ReadyEntry(plan.ready)
        if not entry then return {} end
        local existing = Root().profiles[L[entry.name]]
        if existing then return existing end
        if not plan.readyData or plan.readyKey ~= plan.ready then
            plan.readyKey = plan.ready
            plan.readyData = NS.Settings.ReadyProfileData(entry)
        end
        return plan.readyData
    end
    return NS.db or {}
end

local function Value(path, default)
    local value = GetPath(plan.values, path)
    if value == nil and plan.look and NS.Look and NS.Look.PresetTable then
        value = GetPath(NS.Look:PresetTable(plan.look) or {}, path)
    end
    if value == nil then value = GetPath(Base(), path) end
    if value == nil then return default end
    return value
end

local function Set(path, value)
    SetPath(plan.values, path, value)
end

local function PartOn(part)
    local value = Value(part.path)
    if value == nil then return part.default end
    if part.default then return value ~= false end
    return value == true
end

local PART_SAMPLES = {
    playerUI = { "PlayerUI", "playerUI" },
    actionBars = { "ActionBars", "actionBars" },
    castBar = { "CastBar", "castBar" },
    auras = { "AuraSkin", "auras" },
    minimap = { "MinimapSkin", "minimap" },
    chat = { "ChatSkin", "chat" },
    tooltip = { "TooltipSkin", "tooltip", { field = "style" } },
    dataTexts = { "DataTexts", "dataTexts" },
    raidFrames = { "RaidFrames", "raidFrames", { styleSizes = true } },
    nameplates = { "Nameplates", "nameplates" },
    bags = { "Bags", "bags" },
    cooldownBar = { "CooldownBar", "cooldownBar" },
    threat = { "ThreatMeter", "threat" },
}

local function Preview()
    return NS.SettingsPreview
end

local function PlanOverlay(withLook)
    local data = {}
    if plan.profile ~= "current" then Merge(data, Base()) end
    if withLook ~= false and plan.look and NS.Look and NS.Look.PresetTable then
        Merge(data, NS.Look:PresetTable(plan.look) or {})
    end
    return Merge(data, plan.values)
end

local function Previewed(fn)
    return function(view, key)
        local P = Preview()
        if P and P.Overlay then P.Overlay(PlanOverlay(), fn, view, key) end
    end
end

local function Sized(renderer, w, h)
    local P = Preview()
    if P and P.SIZE then P.SIZE[renderer] = { w, h } end
    return renderer
end

local function ProfileRenderer(data)
    return function(view)
        local P = Preview()
        if P and P.Overlay and P.Profile then P.Overlay(data(), P.Profile, view) end
    end
end

local function Attach(widget, renderer)
    local P = Preview()
    if P and P.Attach and renderer then P:Attach(widget, renderer) end
end

local function TargetName()
    if plan.profile == "own" then return CharKey() end
    if plan.profile == "ready" then
        local entry = ReadyEntry(plan.ready)
        return entry and L[entry.name] or "?"
    end
    return NS.Profiles and NS.Profiles:Current() or "?"
end

function Installer:IsFirstRun()
    local root = Root()
    local key = CharKey()
    if root.installed[key] then return false end
    local name = UnitName("player")
    local realm = GetRealmName()
    local inventory = type(root.inventory) == "table" and realm and root.inventory[realm]
    local known = (type(inventory) == "table" and name and inventory[name])
        or root.chars[key]
        or (type(root.specProfiles) == "table" and root.specProfiles[key])
    if known then
        root.installed[key] = true
        return false
    end
    return true
end

function Installer:MarkDone()
    Root().installed[CharKey()] = true
end

function Installer:Finish()
    local root = Root()
    local name = TargetName()
    local target
    if plan.profile == "current" then
        target = NS.db
    else
        target = root.profiles[name]
        if type(target) ~= "table" then
            target = plan.profile == "ready" and Merge({}, Base()) or {}
        end
        root.profiles[name] = target
        root.chars[CharKey()] = name
    end
    if plan.look and NS.Look and NS.Look.PresetTable then
        Merge(target, NS.Look:PresetTable(plan.look) or {})
    end
    Merge(target, plan.values)
    self:MarkDone()
    ReloadUI()
end

local function Font(fs, size, flags)
    fs:SetFont(NS.FONT, NS.FS(size), flags or "")
    return fs
end

local function Text(parent, size, color, width)
    local S = NS.Styling
    local fs = Font(parent:CreateFontString(nil, "OVERLAY"), size)
    local c = color or S.TEXT_NORMAL
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if width then fs:SetWidth(width) end
    return fs
end

local Builders = {}

local function Flow(page)
    local y = 0
    local flow = {}
    function flow:Add(region, height, gap)
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y)
        y = y + (height or region:GetHeight()) + (gap or 10)
    end
    function flow:Text(text, size, color, gap)
        local fs = Text(page, size or 12, color, page:GetWidth())
        fs:SetText(text)
        self:Add(fs, fs:GetStringHeight(), gap)
        return fs
    end
    function flow:Label(text)
        local S = NS.Styling
        return self:Text(text, 12, S.TEXT_BRIGHT, 6)
    end
    function flow:Picker(options, current, onPick, renderer)
        local picker
        picker = NS.Widgets.CreateOptionPicker(page, options, current, function(key)
            picker:Refresh(key)
            onPick(key)
        end, page:GetWidth())
        Attach(picker, renderer)
        self:Add(picker, picker:GetHeight(), 14)
        return picker
    end
    function flow:Space(h) y = y + h end
    function flow:Y() return y end
    return flow
end

Builders.welcome = function(page)
    local S = NS.Styling
    local glow = page:CreateTexture(nil, "BORDER")
    glow:SetSize(170, 170)
    glow:SetPoint("TOP", page, "TOP", 0, 6)
    glow:SetBlendMode("ADD")
    local emblem = page:CreateTexture(nil, "ARTWORK")
    emblem:SetSize(124, 124)
    emblem:SetPoint("CENTER", glow, "CENTER", 0, 0)
    if S.PaintEmblem then S.PaintEmblem(emblem, glow, 0.35) end

    local body = Text(page, 13, S.TEXT_NORMAL, page:GetWidth())
    body:SetPoint("TOP", glow, "BOTTOM", 0, 2)
    body:SetJustifyH("CENTER")
    body:SetText(L["Это первый запуск NarciUI на этом персонаже. Мастер поможет за минуту выбрать профиль, цвет, вид интерфейса и то, какие его части заменит аддон."]
        .. "\n\n" .. L["Ничего не применяется, пока вы не нажмёте «Готово» на последнем шаге: тогда интерфейс перезагрузится с выбранными настройками. Всё можно поменять позже в настройках."])

    local hint = Text(page, 11, S.TEXT_DIM, page:GetWidth())
    hint:SetPoint("TOP", body, "BOTTOM", 0, -14)
    hint:SetJustifyH("CENTER")
    hint:SetText(L["Открыть мастер снова: настройки, страница «Профили», или /narci install."])
end

local function ProfileCard(page, title, onClick)
    local S = NS.Styling
    local card = CreateFrame("Button", nil, page)
    card:SetSize(page:GetWidth(), 50)
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(WHITE)
    local border = CreateFrame("Frame", nil, card)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:EnableMouse(false)
    local name = Text(card, 13, S.TEXT_BRIGHT)
    name:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -9)
    name:SetText(title)
    local desc = Text(card, 11, S.TEXT_DIM, page:GetWidth() - 24)
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    card.desc = desc
    card:SetHighlightTexture(WHITE, "ADD")
    card:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.08)
    card:SetScript("OnClick", onClick)
    function card:SetActive(active)
        if active then
            bg:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.16)
            border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
            name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            bg:SetVertexColor(S.Tint(0.10, 0.11, 0.14, 0.7))
            border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            name:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end
    S.RoundWidget(card, bg, border)
    return card
end

Builders.profile = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Профиль хранит все настройки аддона. Выберите, куда записать то, что вы выберете в мастере."], 12, S.TEXT_NORMAL, 14)

    local cards = {}
    local readyPicker, about
    local function Refresh()
        for key, card in pairs(cards) do card:SetActive(plan.profile == key) end
        local entry = ReadyEntry(plan.ready)
        if about then about:SetText(entry and L[entry.about] or "") end
        if readyPicker then readyPicker:SetAlpha(plan.profile == "ready" and 1 or 0.45) end
    end
    local function Pick(key)
        plan.profile = key
        Refresh()
    end

    local current = NS.Profiles and NS.Profiles:Current() or "?"
    cards.current = ProfileCard(page, L["Текущий профиль"] .. ": " .. current, function() Pick("current") end)
    cards.current.desc:SetText(current == (NS.Profiles and NS.Profiles.DEFAULT)
        and L["Общий профиль: изменения увидят все персонажи, которые им пользуются."]
        or L["Изменения запишутся в этот профиль."])
    flow:Add(cards.current, 50, 8)

    cards.own = ProfileCard(page, L["Свой профиль для персонажа"], function() Pick("own") end)
    cards.own.desc:SetText(Root().profiles[CharKey()]
        and L["Профиль этого персонажа уже есть: изменения запишутся в него."]
        or L["Новый профиль с именем персонажа и настройками по умолчанию."])
    flow:Add(cards.own, 50, 8)

    cards.ready = ProfileCard(page, L["Готовый профиль"], function() Pick("ready") end)
    cards.ready.desc:SetText(L["Набор настроек под стиль игры. Следующие шаги начнутся с его значений."])
    flow:Add(cards.ready, 50, 10)

    local options = {}
    for _, entry in ipairs(ReadyList()) do
        options[#options + 1] = { key = entry.key, label = (L[entry.name]:gsub("^NarciUI %- ", "")) }
    end
    readyPicker = flow:Picker(options, plan.ready, function(key)
        plan.ready = key
        plan.profile = "ready"
        Refresh()
    end, Sized(function(view, key)
        local P, entry = Preview(), ReadyEntry(key)
        if not (P and entry and P.Profile) then return end
        P.Overlay(NS.Settings.ReadyProfileData(entry), P.Profile, view)
    end, 400, 400))

    local P = Preview()
    if P and P.Profile then
        local hovers = {
            current = Sized(ProfileRenderer(function() return {} end), 400, 400),
            ready = Sized(ProfileRenderer(function()
                local entry = ReadyEntry(plan.ready)
                return entry and NS.Settings.ReadyProfileData(entry) or {}
            end), 400, 400),
        }
        for key, renderer in pairs(hovers) do
            local card = cards[key]
            card:HookScript("OnEnter", function(self)
                local title = key == "current" and (NS.Profiles and NS.Profiles:Current()) or (ReadyEntry(plan.ready) and L[ReadyEntry(plan.ready).name])
                P:Show(renderer, nil, title or "", self)
            end)
            card:HookScript("OnLeave", function() P:Leave() end)
        end
    end
    about = flow:Text("", 11, S.TEXT_DIM, 0)
    about:SetHeight(32)
    page.refresh = Refresh
    Refresh()
end

Builders.theme = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Цвет темы окрашивает рамки, заголовки и выделения во всех окнах аддона."], 12, S.TEXT_NORMAL, 14)

    flow:Label(L["Цвет темы"])
    local accent = NS.Widgets.CreateAccentPicker(page, Value({ "accentColor" }, "emerald"), function(key)
        if key == "custom" and not (NS.db and NS.db.accentCustom) then return end
        Set({ "accentColor" }, key)
        if page.accent then page.accent.Refresh(key) end
    end)
    page.accent = accent
    Attach(accent, Previewed(function(view, key)
        local keep = NS.db.accentColor
        NS.db.accentColor = key
        local ok, err = pcall(Preview().ThemeLook, view)
        NS.db.accentColor = keep
        if not ok then Preview():Fail(err) end
    end))
    flow:Add(accent, 20, 16)

    flow:Label(L["Тон фона окон"])
    local tones = {}
    for _, tone in ipairs(S.BG_TONES) do tones[#tones + 1] = { key = tone.key, label = tone.name } end
    page.tone = flow:Picker(tones, Value({ "theme", "bgTone" }, "obsidian"), function(key) Set({ "theme", "bgTone" }, key) end,
        Previewed(function(view, key)
            local P = Preview()
            local keep = NS.db.theme.bgTone
            NS.db.theme.bgTone = key
            local ok, err = pcall(P.ThemeLook, view)
            NS.db.theme.bgTone = keep
            if not ok then P:Fail(err) end
        end))

    flow:Label(L["Вид окон"])
    page.decor = flow:Picker({
        { key = "styled",  label = "стилизованный" },
        { key = "classic", label = "обычный" },
    }, Value({ "theme", "decor" }, "styled"), function(key) Set({ "theme", "decor" }, key) end,
        Previewed(function(view, key) Preview().Decor(view, key) end))
    flow:Text(L["Стилизованный: картинки в шапках, узорные уголки, блики и орнамент. Обычный: прежний плоский вид."], 11, S.TEXT_DIM)

    page.refresh = function()
        accent.Refresh(Value({ "accentColor" }, "emerald"))
        page.tone:Refresh(Value({ "theme", "bgTone" }, "obsidian"))
        page.decor:Refresh(Value({ "theme", "decor" }, "styled"))
    end
end

Builders.look = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Готовый вид всех элементов на экране сразу: рамок, панелей команд, полосы заклинаний, подсказок, чата, миникарты и остального. Каждый элемент потом настраивается отдельно на странице «Вид элементов»."], 12, S.TEXT_NORMAL, 14)
    local options = { { key = "keep", label = "не менять" } }
    for _, preset in ipairs(NS.Look and NS.Look.PRESETS or {}) do
        options[#options + 1] = { key = preset.key, label = preset.name }
    end
    page.picker = flow:Picker(options, plan.look or "keep", function(key)
        plan.look = key ~= "keep" and key or nil
    end, function(view, key)
        local P = Preview()
        if not (P and P.LookPreset) then return end
        P.Overlay(PlanOverlay(false), P.LookPreset, view, key ~= "keep" and key or nil)
    end)
    flow:Text(L["«Не менять» оставляет вид, который уже задан в выбранном профиле."], 11, S.TEXT_DIM)
    page.refresh = function() page.picker:Refresh(plan.look or "keep") end
end

Builders.parts = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Какие части интерфейса на экране заменит аддон. Остальные останутся стандартными. Окна аддона (персонаж, поиск группы, коллекции) работают в любом случае."], 12, S.TEXT_NORMAL, 12)

    local top = flow:Y()
    local checks = {}
    local half = math.ceil(#PARTS / 2)
    local colW = page:GetWidth() / 2
    for index, part in ipairs(PARTS) do
        local box = NS.Widgets.CreateThemedCheckbox(page, L[part.label], PartOn(part), function(on)
            Set(part.path, on and true or false)
        end)
        local col = index > half and 1 or 0
        local row = col == 1 and index - half - 1 or index - 1
        box:SetPoint("TOPLEFT", page, "TOPLEFT", col * colW, -(top + row * 24))
        checks[index] = box
        local spec = PART_SAMPLES[part.path[1]]
        local P = Preview()
        if spec and P and P.Sample then
            local renderer = Previewed(P.Sample(spec[1], spec[2], nil, spec[3]))
            box:HookScript("OnEnter", function(self) P:Show(renderer, nil, part.label, self) end)
            box:HookScript("OnLeave", function() P:Leave() end)
        end
    end
    flow:Space(half * 24 + 8)

    local function SetAll(on)
        for index, part in ipairs(PARTS) do
            Set(part.path, on)
            checks[index]:SetChecked(on)
        end
    end
    local all = NS.Widgets.CreateThemedButton(page, L["Всё от NarciUI"], 150, 22, function() SetAll(true) end)
    local none = NS.Widgets.CreateThemedButton(page, L["Всё стандартное"], 150, 22, function() SetAll(false) end)
    flow:Add(all, 22, 0)
    none:SetPoint("LEFT", all, "RIGHT", 10, 0)

    page.refresh = function()
        for index, part in ipairs(PARTS) do checks[index]:SetChecked(PartOn(part)) end
    end
end

Builders.scale = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Аддон может уменьшить весь интерфейс, чтобы окна и панели занимали меньше места. Подбор под разрешение делает элементы чёткими, пиксель в пиксель."], 12, S.TEXT_NORMAL, 14)

    local best = NS.UIScale and NS.UIScale:Best() or 1
    local function Mode()
        if not Value({ "uiScale", "enabled" }, false) then return "off" end
        return Value({ "uiScale", "auto" }, true) ~= false and "auto" or "custom"
    end

    local slider
    page.mode = flow:Picker({
        { key = "off",    label = "как в клиенте" },
        { key = "auto",   label = "под разрешение" },
        { key = "custom", label = "свой" },
    }, Mode(), function(key)
        Set({ "uiScale", "enabled" }, key ~= "off")
        Set({ "uiScale", "auto" }, key == "auto")
        if key == "auto" then Set({ "uiScale", "value" }, best) end
        if slider then slider:SetAlpha(key == "custom" and 1 or 0.4) end
    end)

    local start = math.floor((Value({ "uiScale", "value" }, best) or best) * 100 + 0.5)
    slider = NS.Widgets.CreateThemedSlider(page, L["Масштаб"], 40, 115, 1, start, function(val)
        if Mode() ~= "custom" then return end
        Set({ "uiScale", "value" }, val / 100)
    end, "%")
    flow:Add(slider, 40, 12)
    flow:Text(string.format(L["Для вашего разрешения подходит %d%%."], math.floor(best * 100 + 0.5)), 11, S.TEXT_DIM)

    page.refresh = function()
        page.mode:Refresh(Mode())
        slider:SetAlpha(Mode() == "custom" and 1 or 0.4)
    end
end

Builders.finish = function(page)
    local S = NS.Styling
    local flow = Flow(page)
    flow:Text(L["Всё готово. Проверьте выбор и нажмите «Готово»: настройки запишутся, и интерфейс перезагрузится."], 12, S.TEXT_NORMAL, 16)
    local summary = flow:Text("", 12, S.TEXT_BRIGHT, 16)
    local hint = Text(page, 11, S.TEXT_DIM, page:GetWidth())
    hint:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -18)
    hint:SetText(L["После перезагрузки элементы стоят на местах по умолчанию. Передвинуть их можно кнопкой «Расставить интерфейс» в шапке настроек."])

    page.refresh = function()
        local accentKey = Value({ "accentColor" }, "emerald")
        local accentName = accentKey == "class" and L["цвет класса"] or accentKey == "custom" and L["свои цвета"] or accentKey
        for _, preset in ipairs(S.ACCENT_PRESETS) do
            if preset.key == accentKey then accentName = L[preset.name] end
        end
        local lookName = L["не менять"]
        for _, preset in ipairs(NS.Look and NS.Look.PRESETS or {}) do
            if preset.key == plan.look then lookName = L[preset.name] end
        end
        local on = 0
        for _, part in ipairs(PARTS) do if PartOn(part) then on = on + 1 end end
        local mode = not Value({ "uiScale", "enabled" }, false) and L["как в клиенте"]
            or (Value({ "uiScale", "auto" }, true) ~= false and L["под разрешение"])
            or (math.floor((Value({ "uiScale", "value" }, 1) or 1) * 100 + 0.5) .. "%")
        local function Line(label, value)
            local A = S.ACCENT_GLOW
            return string.format("%s:  |cff%02x%02x%02x%s|r", label, A[1] * 255, A[2] * 255, A[3] * 255, value)
        end
        summary:SetText(table.concat({
            Line(L["Профиль"], TargetName()),
            Line(L["Цвет темы"], accentName),
            Line(L["Вид окон"], Value({ "theme", "decor" }, "styled") == "classic" and L["обычный"] or L["стилизованный"]),
            Line(L["Вид элементов"], lookName),
            Line(L["Части интерфейса"], on .. " / " .. #PARTS),
            Line(L["Масштаб"], mode),
        }, "\n\n"))
        summary:SetHeight(summary:GetStringHeight())
    end
end

function Installer:Create()
    if self.frame then return self.frame end
    local S = NS.Styling

    local f = CreateFrame("Frame", "NarciSirus_Installer", UIParent)
    f:SetSize(W, H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(250)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "NarciSirus_Installer")
    S.ApplyPanelStyle(f, W, H)
    S.WindowSounds(f, "igMainMenuOpen", "igMainMenuClose")
    f:HookScript("OnHide", function()
        local P = Preview()
        if not P then return end
        if P.host == f then P.host = nil end
        if P.frame then P.frame:Hide() end
    end)
    self.frame = f

    local side = f:CreateTexture(nil, "BORDER")
    side:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
    side:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
    side:SetWidth(SIDE - 4)
    side:SetTexture(WHITE)
    side:SetVertexColor(S.Tint(0, 0, 0, 0.25))

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE, -16)
    divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDE, 16)
    divider:SetTexture(WHITE)
    divider:SetGradientAlpha("VERTICAL", S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)

    local emblem = f:CreateTexture(nil, "OVERLAY")
    emblem:SetSize(34, 34)
    emblem:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
    if S.PaintEmblem then S.PaintEmblem(emblem, nil, nil, true) end
    local brand = Text(f, 16, S.ACCENT_GLOW)
    brand:SetPoint("LEFT", emblem, "RIGHT", 8, 0)
    brand:SetText((S.BrandName and S.BrandName()) or "NarciUI")
    local sub = Text(f, 10, S.TEXT_DIM)
    sub:SetPoint("TOPLEFT", emblem, "BOTTOMLEFT", 2, -4)
    sub:SetText(L["первоначальная настройка"])

    f.stepRows = {}
    for index, step in ipairs(STEPS) do
        local row = CreateFrame("Button", nil, f)
        row:SetSize(SIDE - 24, 26)
        row:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -82 - (index - 1) * 30)
        local mark = row:CreateTexture(nil, "ARTWORK")
        mark:SetSize(3, 18)
        mark:SetPoint("LEFT", row, "LEFT", 0, 0)
        mark:SetTexture(WHITE)
        mark:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        local num = Text(row, 11, S.TEXT_DIM)
        num:SetPoint("LEFT", row, "LEFT", 10, 0)
        num:SetText(index .. ".")
        local label = Text(row, 12, S.TEXT_NORMAL)
        label:SetPoint("LEFT", row, "LEFT", 28, 0)
        label:SetText(L[step.title])
        row.mark, row.num, row.label = mark, num, label
        row:SetScript("OnClick", function() Installer:Go(index) end)
        f.stepRows[index] = row
    end

    local title = Text(f, 18, S.ACCENT_GLOW)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE + PAD, -20)
    f.title = title

    local close = NS.Widgets.CreateCloseButton(f, 22, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", SIDE + PAD, -56)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, FOOT + 8)
    f.content:SetSize(W - SIDE - PAD * 2, H - 56 - FOOT - 8)
    f.pages = {}

    local footLine = f:CreateTexture(nil, "ARTWORK")
    footLine:SetHeight(1)
    footLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDE + 1, FOOT)
    footLine:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, FOOT)
    footLine:SetTexture(WHITE)
    footLine:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)

    f.nextButton = NS.Widgets.CreateThemedButton(f, L["Далее"], 120, 24, function() Installer:Next() end, S.ACCENT_GLOW)
    f.nextButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 12)
    f.backButton = NS.Widgets.CreateThemedButton(f, L["Назад"], 100, 24, function() Installer:Go(Installer.step - 1) end, S.TEXT_DIM)
    f.backButton:SetPoint("RIGHT", f.nextButton, "LEFT", -8, 0)
    f.skipButton = NS.Widgets.CreateThemedButton(f, L["Пропустить"], 120, 24, function()
        Installer:MarkDone()
        f:Hide()
        NS.Print(L["мастер пропущен, открыть снова: /narci install"])
    end, S.TEXT_DIM)
    f.skipButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", SIDE + PAD, 12)

    return f
end

function Installer:Page(index)
    local f = self.frame
    if f.pages[index] then return f.pages[index] end
    local page = CreateFrame("Frame", nil, f.content)
    page:SetAllPoints(f.content)
    page:SetSize(f.content:GetWidth(), f.content:GetHeight())
    local build = Builders[STEPS[index].key]
    if build then
        local ok, err = pcall(build, page)
        if not ok then
            local fs = Text(page, 11, { 1, 0.4, 0.4 }, page:GetWidth())
            fs:SetPoint("TOPLEFT")
            fs:SetText(tostring(err))
        end
    end
    f.pages[index] = page
    return page
end

function Installer:Go(index)
    local f = self.frame
    if not f or index < 1 or index > #STEPS then return end
    self.step = index
    for i, page in pairs(f.pages) do page:SetShown(i == index) end
    local page = self:Page(index)
    page:Show()
    if page.refresh then pcall(page.refresh) end

    local S = NS.Styling
    f.title:SetText(L[STEPS[index].title])
    for i, row in ipairs(f.stepRows) do
        local active = i == index
        row.mark:SetShown(active)
        local c = active and S.ACCENT_GLOW or (i < index and S.TEXT_NORMAL or S.TEXT_DIM)
        row.label:SetTextColor(c[1], c[2], c[3])
    end
    f.backButton:SetShown(index > 1)
    f.nextButton:SetText(index == #STEPS and L["Готово"] or (index == 1 and L["Начать"] or L["Далее"]))
end

function Installer:Next()
    if self.step >= #STEPS then
        self:Finish()
    else
        self:Go(self.step + 1)
    end
end

function Installer:Show()
    plan = NewPlan()
    local f = self:Create()
    for _, page in pairs(f.pages) do page:Hide() end
    for index in pairs(f.pages) do f.pages[index] = nil end
    if NS.settingsFrame and NS.settingsFrame:IsShown() then NS.settingsFrame:Hide() end
    f:Show()
    if Preview() then Preview().host = f end
    self:Go(1)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function()
    if not NS.firstRun then return end
    NS.After(4, function()
        if InCombatLockdown() then
            driver:RegisterEvent("PLAYER_REGEN_ENABLED")
            driver:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                Installer:Show()
            end)
            return
        end
        Installer:Show()
    end)
end)
