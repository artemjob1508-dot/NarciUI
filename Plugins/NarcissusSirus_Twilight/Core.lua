local addonName, ns = ...
ns.Twilight = ns.Twilight or {}
local T = ns.Twilight

local API = NarciUI_API
if not API or (API.VERSION or 1) < 2 then return end
if API:GetPlugin("NarcissusSirus_Twilight") then return end

local folder = addonName ~= "NarcissusSirus_Twilight" and "Interface\\AddOns\\" .. addonName .. "\\Plugins\\NarcissusSirus_Twilight\\"
    or "Interface\\AddOns\\" .. addonName .. "\\"

T.API = API
T.NAME = "NarcissusSirus_Twilight"
T.WHITE = "Interface\\Buttons\\WHITE8x8"
T.MEDIA = folder .. "Media\\"
T.FONT = T.MEDIA .. "PTSansNarrow.ttf"

T.BG = { 0.06, 0.06, 0.06, 0.85 }
T.BG_SOLID = { 0.06, 0.06, 0.06, 1 }
T.BORDER = { 0, 0, 0, 1 }
T.STRIPE_TOP = { 0.36, 0.33, 0.64 }
T.STRIPE_BOTTOM = { 0.32, 0.31, 0.54 }
T.TAB = { 0.72, 0.47, 0.27 }
T.VALUE = { 0.88, 0.57, 0.31 }
T.GOOD = { 0.36, 0.70, 0.34 }
T.WARN = { 0.95, 0.85, 0.25 }
T.BAD = { 0.90, 0.25, 0.20 }
T.ICON = { 0.95, 0.55, 0.15 }

function T.ClassColor()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.16, 0.45, 0.80
end

function T.ClassHex()
    local r, g, b = T.ClassColor()
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function T.Hex(color)
    return string.format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
end

T.bgFrames = {}

function T.PaintBg(f)
    f:SetBackdropColor(T.BG[1], T.BG[2], T.BG[3], T.BG[4])
    T.bgFrames[f] = true
end

function T.SetPanelAlpha(percent)
    T.BG[4] = math.max(0, math.min(100, percent or 70)) / 100
    for frame in pairs(T.bgFrames) do
        frame:SetBackdropColor(T.BG[1], T.BG[2], T.BG[3], T.BG[4])
    end
end

function T.Panel(name, parent, solid)
    local f = CreateFrame("Frame", name, parent or UIParent)
    f:SetBackdrop({ bgFile = T.WHITE, edgeFile = T.WHITE, edgeSize = 1 })
    if solid then
        f:SetBackdropColor(T.BG_SOLID[1], T.BG_SOLID[2], T.BG_SOLID[3], T.BG_SOLID[4])
    else
        T.PaintBg(f)
    end
    f:SetBackdropBorderColor(0, 0, 0, 1)
    return f
end

function T.Stripe(f, height)
    local stripe = f:CreateTexture(nil, "ARTWORK")
    stripe:SetTexture(T.WHITE)
    stripe:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    stripe:SetHeight(height or 3)
    stripe:SetGradientAlpha("VERTICAL",
        T.STRIPE_BOTTOM[1], T.STRIPE_BOTTOM[2], T.STRIPE_BOTTOM[3], 1,
        T.STRIPE_TOP[1], T.STRIPE_TOP[2], T.STRIPE_TOP[3], 1)

    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetTexture(T.WHITE)
    line:SetVertexColor(0, 0, 0, 1)
    line:SetPoint("TOPLEFT", stripe, "BOTTOMLEFT", 0, 0)
    line:SetPoint("TOPRIGHT", stripe, "BOTTOMRIGHT", 0, 0)
    line:SetHeight(1)

    f.stripe, f.stripeLine = stripe, line
    return stripe
end

function T.Text(parent, size, justify, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFont(T.FONT, size or 11, "OUTLINE")
    text:SetShadowOffset(0, 0)
    text:SetJustifyH(justify or "LEFT")
    return text
end

function T.Truncate(text, limit)
    local count, cut = 0, nil
    for start in string.gmatch(text or "", "()[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count == limit + 1 then cut = start break end
    end
    if not cut then return text end
    return string.sub(text, 1, cut - 1) .. "..."
end

function T.Short(value)
    value = value or 0
    if value >= 1e6 then return string.format("%.2fM", value / 1e6) end
    if value >= 1e3 then return string.format("%.2fK", value / 1e3) end
    return tostring(math.floor(value + 0.5))
end

T.SETTINGS = {
    ["uiScale.enabled"] = true,
    ["uiScale.auto"] = true,

    ["font"] = "twilight",
    ["elementLook.font"] = "twilight",
    ["elementLook.outline"] = "outline",
    ["elementLook.texture"] = "flat",
    ["elementLook.fontScale"] = 100,

    ["actionBars.enabled"] = true,
    ["actionBars.panel"] = false,
    ["actionBars.hideMicro"] = true,
    ["actionBars.hideEmpty"] = false,
    ["actionBars.showMacroName"] = false,
    ["actionBars.look.style"] = "flat",
    ["actionBars.look.border"] = "thin",
    ["actionBars.look.borderColor"] = "dark",
    ["actionBars.look.zoom"] = true,
    ["actionBars.look.gloss"] = false,
    ["actionBars.look.ratio"] = 1,
    ["actionBars.look.hotkeySize"] = 11,
    ["actionBars.look.hotkeyPos"] = "TOPRIGHT",
    ["actionBars.look.hotkeyColor"] = "white",
    ["actionBars.look.countSize"] = 12,
    ["actionBars.look.groundAlpha"] = 0.85,

    ["chat.enabled"] = true,
    ["chat.style"] = "bare",
    ["chat.panel"] = false,
    ["chat.font"] = "pt",
    ["chat.fontSize"] = 11,
    ["chat.outline"] = false,
    ["chat.plainTabs"] = true,
    ["chat.hideButtons"] = true,
    ["chat.editPos"] = "bottom",

    ["minimap.enabled"] = true,
    ["minimap.square"] = true,
    ["minimap.style"] = "bare",
    ["minimap.scale"] = 0.95,
    ["minimap.hideZoneText"] = true,
    ["minimap.hideClock"] = true,
    ["minimap.coords"] = false,
    ["minimap.infoCoords"] = false,
    ["minimap.infoPanel"] = false,
    ["minimap.point"] = "TOPRIGHT",
    ["minimap.relativePoint"] = "TOPRIGHT",
    ["minimap.x"] = -6,
    ["minimap.y"] = -7,

    ["auras.enabled"] = true,
    ["auras.style"] = "square",
    ["auras.size"] = 26,
    ["auras.debuffSize"] = 26,
    ["auras.perRow"] = 16,
    ["auras.grow"] = "left",
    ["auras.timerSize"] = 12,
    ["auras.showTimers"] = true,

    ["dataTexts.enabled"] = false,

    ["playerUI.enabled"] = false,
    ["raidFrames.enabled"] = false,

    ["nameplates.style"] = "twilight",
    ["nameplates.showLevel"] = true,
    ["nameplates.hpText"] = "style",

    ["cooldownBar.enabled"] = false,
    ["threat.enabled"] = false,
    ["minimapButton"] = false,
    ["minimap.collect"] = true,
    ["minimap.tracking"] = "click",
    ["minimap.bagOpen"] = "always",
    ["minimap.bagPoint"] = "TOPRIGHT",
    ["minimap.bagRelativePoint"] = "TOPRIGHT",
    ["minimap.bagX"] = -5,
    ["minimap.bagY"] = -164,
    ["minimap.bagPerRow"] = 5,
    ["minimap.bagSize"] = 22,
    ["minimap.bagSpacing"] = 3,
    ["minimap.bagDirection"] = "left",
    ["actionBars.bars.stance.enabled"] = false,
    ["actionBars.bars.bar6.enabled"] = false,
    ["actionBars.bars.bar7.enabled"] = false,
    ["actionBars.bars.bar8.enabled"] = false,
    ["actionBars.bars.bar9.enabled"] = false,
}

T.BARS = {
    bar1 = { point = "BOTTOM", x = 4,    y = 38, perRow = 12, buttons = 12, size = 29, spacing = 4 },
    bar2 = { point = "BOTTOM", x = 4,    y = 5,  perRow = 12, buttons = 12, size = 29, spacing = 4 },
    bar3 = { point = "BOTTOM", x = -266, y = 5,  perRow = 4,  buttons = 8,  size = 27, spacing = 4 },
    bar4 = { point = "BOTTOM", x = 274,  y = 5,  perRow = 4,  buttons = 8,  size = 27, spacing = 4 },
    bar5 = { point = "BOTTOM", x = 458,  y = 3,  perRow = 12, buttons = 12, size = 17, spacing = 2 },
}

T.PLACES = {
    { "NarciSirus_AuraHolder", "TOPRIGHT", "TOPRIGHT", -166, -4 },
}

local function Changes()
    local list = {}
    for path, value in pairs(T.SETTINGS) do list[path] = value end
    for key, bar in pairs(T.BARS) do
        local prefix = "actionBars.bars." .. key .. "."
        list[prefix .. "enabled"] = true
        list[prefix .. "growth"] = "RIGHT"
        list[prefix .. "mouseover"] = false
        list[prefix .. "combatOnly"] = false
        list[prefix .. "hideEmpty"] = false
        list[prefix .. "alpha"] = 1
        for field, value in pairs(bar) do list[prefix .. field] = value end
    end
    return list
end

function T.Install()
    if InCombatLockdown() then
        API:Print("Twilight: " .. API:L("В бою установить нельзя"))
        return
    end

    local changes = Changes()
    if not T.db.installed then
        local backup = {}
        for path in pairs(changes) do backup[path] = { value = API:GetSetting(path) } end
        backup["@chat"] = T.ChatPosition and T.ChatPosition() or nil
        T.db.backup = backup
    end
    API:ApplySettings(changes)

    T.db.settingsVersion = T.SETTINGS_VERSION
    T.db.installed = true
    T.db.placePending = true
    API:Reload()
end

T.SETTINGS_VERSION = 2

function T.Upgrade()
    if (T.db.settingsVersion or 1) >= T.SETTINGS_VERSION or InCombatLockdown() then return false end
    local changes = Changes()
    T.db.backup = T.db.backup or {}
    local changed = false
    for path, value in pairs(changes) do
        if T.db.backup[path] == nil then
            T.db.backup[path] = { value = API:GetSetting(path) }
        end
        if API:GetSetting(path) ~= value then
            API:SetSetting(path, value)
            changed = true
        end
    end
    T.db.settingsVersion = T.SETTINGS_VERSION
    if changed then
        API:After(1, function()
            local widgets = API:Widgets()
            if widgets and widgets.ShowConfirm then
                widgets.ShowConfirm(API:L("Сумерки обновились: часть новых настроек применится после перезагрузки интерфейса."),
                    API:L("Перезагрузить"), function() ReloadUI() end)
            else
                API:Print(API:L("Сумерки обновились: часть новых настроек применится после перезагрузки интерфейса."))
            end
        end)
    end
    return changed
end

function T.ChatPosition()
    local point, x, y = GetChatWindowSavedPosition(1)
    local width, height = GetChatWindowSavedDimensions(1)
    return { client = true, point = point, x = x, y = y, width = width, height = height }
end

function T.RestoreChat()
    local saved = T.db.chatRestore
    if not saved or InCombatLockdown() then return end
    T.db.chatRestore = nil
    local chat = _G.ChatFrame1
    if not chat then return end
    if saved.client and saved.point then
        if saved.width and saved.height then SetChatWindowSavedDimensions(1, saved.width, saved.height) end
        SetChatWindowSavedPosition(1, saved.point, saved.x, saved.y)
        if type(_G.FCF_RestorePositionAndDimensions) == "function" then
            pcall(_G.FCF_RestorePositionAndDimensions, chat)
        end
    elseif API:Module("ChatSkin") and API:Module("ChatSkin").ResetPosition then
        API:Module("ChatSkin"):ResetPosition()
    end
end

function T.Uninstall()
    if InCombatLockdown() then
        API:Print("Twilight: " .. API:L("В бою установить нельзя"))
        return
    end
    local backup = T.db.backup or {}
    for path, saved in pairs(backup) do
        if path ~= "@chat" and type(saved) == "table" then API:SetSetting(path, saved.value) end
    end
    local position = backup["@chat"]
    T.db.chatRestore = type(position) == "table" and position.client and position or { default = true }
    if T.RestoreDetails then T.RestoreDetails() end
    T.db.installed = false
    T.db.backup = nil
    T.db.placePending = nil
    API:Reload()
end

function T.PlacePending()
    if not T.db.placePending or InCombatLockdown() then return end
    T.db.placePending = nil
    for _, place in ipairs(T.PLACES) do
        API:PlaceElement(place[1], place[2], place[3], place[4], place[5])
    end
    local chat = _G.ChatFrame1
    if chat then
        chat:ClearAllPoints()
        chat:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 26)
        chat:SetSize(355, 148)
        if type(_G.FCF_SavePositionAndDimensions) == "function" then
            pcall(_G.FCF_SavePositionAndDimensions, chat)
        end
    end
end

API:AddFont("twilight", "PT Sans Narrow (Twilight)", T.FONT)

API:AddTranslations("enUS", {
    ["Сумерки"] = "Twilight",
    ["В бою установить нельзя"] = "Cannot install in combat",
    ["Готовый интерфейс: тёмные полупрозрачные панели с сиреневой полосой, панели команд по центру снизу, чат слева, окно урона справа, миникарта и показатели по углам."] = "A ready-made interface: dark translucent panels with a lavender stripe, action bars at the bottom centre, chat on the left, the damage window on the right, the minimap and stats in the corners.",
    ["Установить интерфейс"] = "Install interface",
    ["Установка меняет настройки панелей команд, чата, миникарты, бафов, масштаба и шрифта в текущем профиле аддона и перезагружает интерфейс. Сохраните профиль заранее, если хотите вернуться."] = "Installing changes the action bar, chat, minimap, aura, scale and font settings in the current addon profile and reloads the interface. Save the profile first if you want to go back.",
    ["Установить интерфейс Сумерки? Настройки текущего профиля поменяются, интерфейс перезагрузится."] = "Install the Twilight interface? The current profile's settings will change and the interface will reload.",
    ["Установить"] = "Install",
    ["Вернуть как было"] = "Restore previous",
    ["Вернуть"] = "Restore",
    ["Непрозрачность панелей"] = "Panel opacity",
    ["Непрозрачность верхней левой панели"] = "Top left panel opacity",
    ["Сумерки обновились: часть новых настроек применится после перезагрузки интерфейса."] = "Twilight was updated: some new settings apply after an interface reload.",
    ["Перезагрузить"] = "Reload",
    ["Скрывать окна Details"] = "Hide Details windows",
    ["Выключить интерфейс Сумерки и вернуть настройки, которые были до установки?"] = "Turn off the Twilight interface and restore the settings from before the install?",
    ["Интерфейс установлен."] = "The interface is installed.",
    ["Интерфейс не установлен: плагин ничего не меняет, пока вы не нажмёте Установить."] = "The interface is not installed: the plugin changes nothing until you press Install.",
    ["Панели"] = "Panels",
    ["Верхняя левая панель показателей"] = "Top left stats panel",
    ["Строка локации сверху"] = "Location bar at the top",
    ["Кнопка управления рейдом"] = "Raid control button",
    ["Полоса опыта над панелями"] = "Experience bar above the bars",
    ["Цвет текста - цвет класса"] = "Text in class colour",
    ["Управление рейдом"] = "Raid control",
    ["Проверка готовности"] = "Ready check",
    ["Проверка ролей"] = "Role check",
    ["Превратить в рейд"] = "Convert to raid",
    ["Превратить в группу"] = "Convert to party",
    ["Снять метки"] = "Clear marks",
    ["Окно рейда"] = "Raid window",
    ["Громкость"] = "Volume",
    ["Прочность"] = "Durability",
    ["Сумки"] = "Bags",
    ["MS (Мир)"] = "MS (World)",
    ["Уровень"] = "Level",
    ["Гильдия"] = "Guild",
    ["Друзья"] = "Friends",
    ["Задания"] = "Quests",
    ["Нет почты"] = "No mail",
    ["Есть почта"] = "New mail",
    ["Колёсико - громкость, клик - звук вкл/выкл"] = "Wheel - volume, click - sound on/off",
    ["Три последних пункта применяются после перезагрузки интерфейса."] = "The last three options apply after an interface reload.",
})

API:RegisterPlugin(T.NAME, {
    title = "Сумерки",
    version = "1.0",
    author = "NarciUI",
    description = "Готовый интерфейс: тёмные полупрозрачные панели с сиреневой полосой, панели команд по центру снизу, чат слева, окно урона справа, миникарта и показатели по углам.",
    apiVersion = 2,
    defaults = {
        installed = false,
        dataPanel = true,
        location = true,
        raidControl = true,
        xpBar = true,
        classText = true,
        unitFrames = true,
        meter = true,
        tracker = true,
        hideDetails = false,
        panelOpacity = 85,
        dataOpacity = 60,
    },

    onLoad = function(api, db)
        T.db = db
        if not db.detailsOptIn then
            db.detailsOptIn = true
            db.hideDetails = false
        end
        T.BG[4] = (db.panelOpacity or 85) / 100
        if db.chatRestore then api:After(3, T.RestoreChat) end
        if not db.installed then return end
        T.Upgrade()
        if T.Build then T.Build() end
        api:After(3, T.PlacePending)
    end,

    settings = function(page, ui, db, api)
        ui.Section(page, api:L("Сумерки"))
        ui.Note(page, api:L("Установка меняет настройки панелей команд, чата, миникарты, бафов, масштаба и шрифта в текущем профиле аддона и перезагружает интерфейс. Сохраните профиль заранее, если хотите вернуться."))
        ui.Buttons(page, {
            { label = api:L("Установить интерфейс"), width = 200, action = function()
                local widgets = api:Widgets()
                widgets.ShowConfirm(api:L("Установить интерфейс Сумерки? Настройки текущего профиля поменяются, интерфейс перезагрузится."), api:L("Установить"), T.Install)
            end },
            { label = api:L("Вернуть как было"), width = 170, action = function()
                if not db.installed then return end
                local widgets = api:Widgets()
                widgets.ShowConfirm(api:L("Выключить интерфейс Сумерки и вернуть настройки, которые были до установки?"), api:L("Вернуть"), T.Uninstall)
            end },
        })
        ui.Note(page, db.installed and api:L("Интерфейс установлен.") or api:L("Интерфейс не установлен: плагин ничего не меняет, пока вы не нажмёте Установить."))

        ui.Section(page, api:L("Панели"))
        ui.Slider(page, api:L("Непрозрачность панелей"), 0, 100, 5, db.panelOpacity or 85, function(value)
            db.panelOpacity = value
            T.SetPanelAlpha(value)
        end, "%")
        ui.Slider(page, api:L("Непрозрачность верхней левой панели"), 0, 100, 5, db.dataOpacity or 60, function(value)
            db.dataOpacity = value
            if T.SetDataAlpha then T.SetDataAlpha(value) end
        end, "%")
        ui.Check(page, api:L("Верхняя левая панель показателей"), db.dataPanel, function(value) db.dataPanel = value; T.Refresh() end)
        ui.Check(page, api:L("Строка локации сверху"), db.location, function(value) db.location = value; T.Refresh() end)
        ui.Check(page, api:L("Кнопка управления рейдом"), db.raidControl, function(value) db.raidControl = value; T.Refresh() end)
        ui.Check(page, api:L("Полоса опыта над панелями"), db.xpBar, function(value) db.xpBar = value; T.Refresh() end)
        ui.Check(page, api:L("Цвет текста - цвет класса"), db.classText, function(value) db.classText = value; T.Refresh() end)
        ui.Check(page, api:L("Рамки игрока, цели и группы"), db.unitFrames, function(value) db.unitFrames = value end)
        ui.Check(page, api:L("Окно урона и исцеления"), db.meter, function(value) db.meter = value end)
        ui.Check(page, api:L("Трекер заданий справа"), db.tracker, function(value) db.tracker = value end)
        ui.Check(page, api:L("Скрывать окна Details"), db.hideDetails, function(value)
            db.hideDetails = value
            if not value and T.RestoreDetails then T.RestoreDetails() end
        end)
        ui.Note(page, api:L("Три последних пункта применяются после перезагрузки интерфейса."))
    end,
})
