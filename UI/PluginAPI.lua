local addonName, NS = ...
local L = NS.L

local API = {}
local Plugins = {}
NS.Plugins = Plugins
NS.PluginAPI = API

API.VERSION = 5
API.ADDON_VERSION = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "?"

local registry = {}
local order = {}
local listeners = {}
local ready = false

Plugins.EVENTS = {
    READY = true,
    CHARACTER_SHOWN = true,
    CHARACTER_HIDDEN = true,
    LAYOUT_APPLIED = true,
    LOOK_APPLIED = true,
    SETTINGS_SHOWN = true,
}

local function Report(owner, where, err)
    local text = "|cffff6060" .. tostring(owner or "?") .. "|r - " .. tostring(where) .. ": " .. tostring(err)
    local plugin = registry[owner]
    if plugin then
        plugin.errors = (plugin.errors or 0) + 1
        plugin.lastError = tostring(err)
    end
    if NS.Print then NS.Print(text) else print(text) end
end

local function Call(owner, where, fn, ...)
    if type(fn) ~= "function" then return true end
    local ok, err = pcall(fn, ...)
    if not ok then Report(owner, where, err) end
    return ok
end

local function Fill(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Fill(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function PluginDB(plugin)
    if not NS.db then return end
    if type(NS.db.plugins) ~= "table" then NS.db.plugins = {} end
    if type(NS.db.plugins[plugin.name]) ~= "table" then NS.db.plugins[plugin.name] = {} end
    local db = NS.db.plugins[plugin.name]
    if type(plugin.defaults) == "table" then Fill(db, plugin.defaults) end
    return db
end

function Plugins:Enabled(name)
    local flags = NS.db and NS.db.pluginsEnabled
    return not (type(flags) == "table" and flags[name] == false)
end

function Plugins:List()
    return order
end

function Plugins:Get(name)
    return registry[name]
end

function Plugins:Load(plugin)
    if plugin.status ~= "waiting" then return end
    if not self:Enabled(plugin.name) then
        plugin.status = "disabled"
        return
    end
    plugin.db = PluginDB(plugin)
    if Call(plugin.name, "onLoad", plugin.onLoad, API, plugin.db, plugin) then
        plugin.status = "loaded"
    else
        plugin.status = "error"
    end
end

function Plugins:LoadAll()
    ready = true
    for _, plugin in ipairs(order) do self:Load(plugin) end
    self:Fire("READY")
end

function Plugins:Fire(event, ...)
    local list = listeners[event]
    if not list then return end
    for _, entry in ipairs(list) do
        if entry.owner == nil or not registry[entry.owner] or registry[entry.owner].status == "loaded" then
            Call(entry.owner or "?", event, entry.fn, event, ...)
        end
    end
end

function API:RegisterPlugin(name, info)
    if type(name) ~= "string" or name == "" then
        error("NarciUI_API:RegisterPlugin(name, info): name must be a non-empty string", 2)
    end
    if registry[name] then
        error("NarciUI_API: plugin '" .. name .. "' is already registered", 2)
    end
    info = type(info) == "table" and info or {}

    local plugin = {
        name = name,
        title = info.title or name,
        version = tostring(info.version or "?"),
        author = info.author,
        description = info.description,
        apiVersion = tonumber(info.apiVersion) or 1,
        defaults = info.defaults,
        onLoad = info.onLoad,
        settings = info.settings,
        status = "waiting",
    }
    if plugin.apiVersion > API.VERSION then plugin.status = "outdated" end

    registry[name] = plugin
    order[#order + 1] = plugin

    if ready then Plugins:Load(plugin) end
    return plugin
end

function API:GetPlugin(name)
    return registry[name]
end

function API:GetDB(name)
    local plugin = registry[name]
    if not plugin then return end
    plugin.db = plugin.db or PluginDB(plugin)
    return plugin.db
end

function API:IsPluginEnabled(name)
    return Plugins:Enabled(name)
end

function API:On(event, fn, owner)
    if not Plugins.EVENTS[event] then
        error("NarciUI_API:On: unknown event '" .. tostring(event) .. "'", 2)
    end
    if type(fn) ~= "function" then
        error("NarciUI_API:On(event, fn, owner): fn must be a function", 2)
    end
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], { fn = fn, owner = owner })
end

function API:Off(event, owner)
    local list = listeners[event]
    if not list then return end
    for index = #list, 1, -1 do
        if list[index].owner == owner then table.remove(list, index) end
    end
end

function API:After(delay, fn)
    if NS.After then NS.After(delay, fn) end
end

function API:Print(message)
    if NS.Print then NS.Print(message) end
end

function API:L(text)
    return NS.L[text]
end

function API:AddTranslations(locale, map)
    if locale ~= "enUS" or type(map) ~= "table" then return false end
    local translations = NS.LocaleTranslations
    if not translations then return false end
    translations.enUS = translations.enUS or {}
    for key, value in pairs(map) do
        if translations.enUS[key] == nil then translations.enUS[key] = value end
    end
    return true
end

function API:Styling()
    return NS.Styling
end

function API:Widgets()
    return NS.Widgets
end

function API:Font(element, size, flags)
    if element and NS.LFont then return NS.LFont(element, size, flags) end
    return NS.FONT, size, flags or ""
end

function API:FontSize(size)
    return NS.FS and NS.FS(size) or size
end

function API:RegisterMover(frame, label, save)
    if not NS.Movers or not frame then return end
    return NS.Movers:Register(frame, label, save, "plugins")
end

function API:AddNameplateStyle(row)
    return NS.Nameplates and NS.Nameplates.AddStyle and NS.Nameplates:AddStyle(row) or false
end

function API:AddBagStyle(row)
    return NS.Bags and NS.Bags.AddStyle and NS.Bags:AddStyle(row) or false
end

function API:AddBarTexture(key, name, path)
    return NS.Look and NS.Look:AddTexture(key, name, path) or false
end

function API:AddFont(key, label, path)
    return NS.Look and NS.Look:AddFont(key, label, path) or false
end

function API:AddLook(preset)
    return NS.Look and NS.Look:AddPreset(preset) or false
end

function API:AddDataText(block)
    return NS.DataTexts and NS.DataTexts.AddBlock and NS.DataTexts:AddBlock(block) or false
end

function API:AddSlotShape(key, art)
    return NS.NarciUI and NS.NarciUI.AddSlotShape and NS.NarciUI:AddSlotShape(key, art) or false
end

function API:AddBacklight(key, label, style)
    return NS.NarciUI and NS.NarciUI.AddBacklight and NS.NarciUI:AddBacklight(key, label, style) or false
end

function API:AddFloor(key, label, path, opts)
    return NS.NarciUI and NS.NarciUI.AddFloor and NS.NarciUI:AddFloor(key, label, path, opts) or false
end

function API:AddWindowPattern(key, label, path)
    return NS.Styling and NS.Styling.AddDecor("patterns", key, label, path) or false
end

function API:AddCornerStyle(key, label, path)
    return NS.Styling and NS.Styling.AddDecor("corners", key, label, path) or false
end

function API:AddDividerStyle(key, label, path)
    return NS.Styling and NS.Styling.AddDecor("dividers", key, label, path) or false
end

function API:AddMicroIcons(key, label, paths)
    return NS.ActionBars and NS.ActionBars.AddMicroIcons and NS.ActionBars:AddMicroIcons(key, label, paths) or false
end

local function SplitPath(path)
    if type(path) == "table" then return path end
    local parts = {}
    for part in string.gmatch(tostring(path), "[^%.]+") do
        parts[#parts + 1] = tonumber(part) or part
    end
    return parts
end

function API:GetSetting(path)
    local node = NS.db
    for _, key in ipairs(SplitPath(path)) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function API:SetSetting(path, value)
    if not NS.db then return false end
    local parts = SplitPath(path)
    if #parts == 0 or parts[1] == "plugins" or parts[1] == "pluginsEnabled" then return false end
    local node = NS.db
    for index = 1, #parts - 1 do
        local key = parts[index]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[parts[#parts]] = value
    return true
end

function API:ApplySettings(map)
    if type(map) ~= "table" then return false end
    for path, value in pairs(map) do self:SetSetting(path, value) end
    return true
end

function API:Elements()
    local list = {}
    if not NS.Movers or not NS.Movers.Entries then return list end
    for _, entry in ipairs(NS.Movers:Entries()) do
        list[#list + 1] = { id = entry.id, label = entry.label, frame = entry.frame, name = entry.frame:GetName() }
    end
    return list
end

function API:PlaceElement(key, point, relativePoint, x, y)
    if not NS.Movers or not NS.Movers.Entries or InCombatLockdown() then return false end
    for _, entry in ipairs(NS.Movers:Entries()) do
        local frame = entry.frame
        if entry.id == key or frame:GetName() == key or entry.label == key then
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, relativePoint or point, x or 0, y or 0)
            if entry.save then pcall(entry.save, point, relativePoint or point, x or 0, y or 0) end
            return true
        end
    end
    return false
end

local HOOKS = {
    actionbutton = { "ActionBars", "StyleButton" },
    actionedges = { "ActionBars", "PaintEdges" },
    actionbar = { "ActionBars", "LayoutBar" },
    unitframe = { "PlayerUI", "Relayout" },
    unitbars = { "PlayerUI", "UpdateBars" },
    raidbutton = { "RaidFrames", "Layout" },
    raidborder = { "RaidFrames", "UpdateBorder" },
    raidhealth = { "RaidFrames", "UpdateHealth" },
    aura = { "AuraSkin", "SkinButton" },
    auratint = { "AuraSkin", "Tint" },
    auraduration = { "AuraSkin", "Duration" },
    aurasapplied = { "AuraSkin", "Layout" },
    chatpanel = { "ChatSkin", "StylePanel" },
    chattab = { "ChatSkin", "SkinTab" },
    chattabs = { "ChatSkin", "UpdateTabs" },
    chatapplied = { "ChatSkin", "Apply" },
    minimap = { "MinimapSkin", "StyleFrame" },
    minimapapplied = { "MinimapSkin", "Apply" },
    datatexts = { "DataTexts", "Restyle" },
    castbar = { "CastBar", "Style" },
    nameplate = { "Nameplates", "ApplyStyle" },
    tooltip = { "TooltipSkin", "Paint" },
    tracker = { "TrackerSkin", "SkinContainer" },
    queueicon = { "QueueEye", "Paint" },
    coords = { "MinimapSkin", "UpdateCoords" },
    raidrole = { "RaidFrames", "UpdateRole" },
    raidrank = { "RaidFrames", "UpdateRank" },
    window = { "Movers", "SkinWindow" },
    dialogue = { "Dialogue", "ApplyLook" },
    afk = { "AFKScreen", "Paint" },
    messenger = { "Messenger", "ApplyStyle" },
    bagwindow = { "Bags", "ApplyWindowStyle" },
    threat = { "ThreatMeter", "ApplyStyle" },
    cooldowns = { "CooldownBar", "ApplyStyle" },
    xpbar = { "ActionBars", "UpdateXPBar" },
    classpower = { "PlayerUI", "UpdateClassPower" },
    look = { "Look", "Refresh" },
}
API.HOOKS = HOOKS

function API:Hook(element, fn, owner)
    local target = HOOKS[element]
    local module = target and NS[target[1]]
    if not module or type(module[target[2]]) ~= "function" or type(fn) ~= "function" then return false end
    hooksecurefunc(module, target[2], function(_, ...)
        if owner and registry[owner] and registry[owner].status ~= "loaded" then return end
        Call(owner or "?", element, fn, ...)
    end)
    return true
end

function API:Module(name)
    for _, target in pairs(HOOKS) do
        if target[1] == name then return NS[name] end
    end
end

local function Pack(...)
    return { n = select("#", ...), ... }
end

local LOCKED = { Plugins = true, PluginAPI = true, db = true, L = true, LSpec = true }

function API:GetModule(name)
    if type(name) ~= "string" or LOCKED[name] then return nil end
    local module = NS[name]
    return type(module) == "table" and module or nil
end

function API:Override(moduleName, method, fn, owner)
    local module = API:GetModule(moduleName)
    local original = module and module[method]
    if type(original) ~= "function" or type(fn) ~= "function" then return false end
    module[method] = function(...)
        if owner and registry[owner] and registry[owner].status ~= "loaded" then return original(...) end
        local result = Pack(pcall(fn, original, ...))
        if result[1] then return unpack(result, 2, result.n) end
        Report(owner or "?", moduleName .. ":" .. tostring(method), result[2])
        return original(...)
    end
    return true
end

function API:HookAny(moduleName, method, fn, owner)
    local module = API:GetModule(moduleName)
    if not module or type(module[method]) ~= "function" or type(fn) ~= "function" then return false end
    hooksecurefunc(module, method, function(...)
        if owner and registry[owner] and registry[owner].status ~= "loaded" then return end
        Call(owner or "?", moduleName .. ":" .. tostring(method), fn, ...)
    end)
    return true
end

function API:ReplaceTexture(name, path)
    return NS.Styling and NS.Styling.ReplaceTexture(name, path) or false
end

function API:AddAccent(key, name, r, g, b)
    return NS.Styling and NS.Styling.AddAccent(key, name, r, g, b) or false
end

function API:AddBackgroundTone(key, name, r, g, b)
    return NS.Styling and NS.Styling.AddBackgroundTone(key, name, r, g, b) or false
end

function API:AddSettings(pageKey, builder, owner)
    return NS.Settings and NS.Settings.Extend and NS.Settings:Extend(pageKey, builder, owner) or false
end

NS.PluginTabs = NS.PluginTabs or {}
NS.EXTRA_PANELS = NS.EXTRA_PANELS or {}

function API:AddTab(def, owner)
    if type(def) ~= "table" or type(def.key) ~= "string" or type(def.build) ~= "function" then return false end
    local name = "PluginTab_" .. def.key:gsub("[^%w_]", "")
    if NS[name] then return false end

    local tab = {}

    function tab:Create()
        if self.frame then return end
        local S = NS.Styling
        local parent = NS.NarciUI and NS.NarciUI.mainFrame
        if not parent then return end

        local f = CreateFrame("Frame", "NarcissusSirus_" .. name, parent)
        f:SetWidth(S.PANEL_WIDTH)
        f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
        f:SetHeight(S.PANEL_HEIGHT)
        f:SetFrameLevel(parent:GetFrameLevel() + 5)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.Bg(S.BG_DARK_A))
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
        S.CreateShadow(f, 5, 0.4)
        S.ApplyTabChrome(f)
        S.CreateGradientTopBorder(f)

        local title = f:CreateFontString(nil, "OVERLAY")
        title:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
        title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        title:SetPoint("TOP", f, "TOP", 0, -12)
        title:SetText(def.title or def.label or def.key)
        f.title = title
        if NS.TabStyle then
            NS.TabStyle.Header(f, { art = def.banner, badge = def.badge })
        end
        S.CreateAnimatedSeparator(f, -50)

        local content = CreateFrame("Frame", nil, f)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -58)
        content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
        f.content = content

        self.frame = f
        f:Hide()
        Call(owner or def.key, "build", def.build, content, f)
    end

    function tab:Update()
        if self.frame and def.update then Call(owner or def.key, "update", def.update, self.frame.content, self.frame) end
    end

    function tab:Toggle()
        if not self.frame then self:Create() end
        if not self.frame then return end
        if self.frame:IsShown() then
            NS.Styling.PanelOut(self.frame)
        else
            self:Update()
            NS.Styling.PanelIn(self.frame)
        end
    end

    function tab:Hide()
        if self.frame then NS.Styling.PanelHideNow(self.frame) end
    end

    NS[name] = tab
    table.insert(NS.EXTRA_PANELS, name)
    table.insert(NS.PluginTabs, { label = def.label or def.key, panel = name, icon = def.icon or "ToolSettings" })
    return true
end

local function AddRow(rows, orderList, labels, key, row, label)
    if type(rows) ~= "table" or type(orderList) ~= "table" then return false end
    if type(key) ~= "string" or key == "" or key == "theme" or key == "all" or type(row) ~= "table" or rows[key] then return false end
    local base = type(row.base) == "string" and rows[row.base]
    if type(base) == "table" then
        for field, value in pairs(base) do
            if row[field] == nil then row[field] = value end
        end
    end
    rows[key] = row
    table.insert(orderList, key)
    if labels then labels[key] = label or key end
    return true
end

local function Owned(owner, fn)
    return function(...)
        if owner and registry[owner] and registry[owner].status ~= "loaded" then return end
        return fn(...)
    end
end

function API:AddQueueIcon(key, label, row)
    return NS.QueueEye and NS.QueueEye:AddStyle(key, label, row) or false
end

function API:AddTrackerStyle(key, label, row)
    return NS.TrackerSkin and NS.TrackerSkin:AddStyle(key, label, row) or false
end

function API:AddCoordStyle(key, label, row)
    return NS.MinimapSkin and NS.MinimapSkin.AddCoordStyle and NS.MinimapSkin:AddCoordStyle(key, label, row) or false
end

function API:AddBoxStyle(key, label, row)
    return NS.Styling and NS.Styling.AddBox(key, label, row) or false
end

function API:AddSceneArt(key, path, aspect, anchor)
    return NS.Styling and NS.Styling.AddSceneArt(key, path, aspect, anchor) or false
end

function API:AddWindowStyle(key, label, row)
    local M = NS.Movers
    return M and AddRow(M.WINDOW_STYLES, M.WINDOW_STYLE_ORDER, M.WINDOW_STYLE_LABELS, key, row, label) or false
end

function API:AddDialogueStyle(key, label, row)
    local D = NS.Dialogue
    return D and AddRow(D.STYLES, D.STYLE_ORDER, D.STYLE_LABELS, key, row, label) or false
end

function API:AddAFKStyle(key, label, row)
    local A = NS.AFKScreen
    return A and AddRow(A.PANEL_STYLES, A.PANEL_STYLE_ORDER, A.PANEL_STYLE_LABELS, key, row, label) or false
end

function API:AddMessengerStyle(key, label, row)
    local M = NS.Messenger
    if not M or type(row) ~= "table" then return false end
    row.label = label or row.label or key
    return AddRow(M.STYLES, M.STYLE_ORDER, nil, key, row, label)
end

function API:AddRaidStyle(key, label, row)
    return NS.RaidFrames and NS.RaidFrames:AddStyle(key, label, row) or false
end

function API:AddUnitFrameStyle(key, label, row)
    return NS.PlayerUI and NS.PlayerUI:AddStyle(key, label, row) or false
end

function API:AddLookElement(def)
    return NS.Look and NS.Look:AddElement(def) or false
end

function API:AddWindow(def)
    return NS.Movers and NS.Movers.AddWindow and NS.Movers:AddWindow(def) or false
end

function API:AddSettingsCategory(def, owner)
    return NS.Settings and NS.Settings.AddExtraCategory and NS.Settings:AddExtraCategory(def, owner) or false
end

function API:AddMicroButton(def, owner)
    if type(def) ~= "table" or not NS.ActionBars or not NS.ActionBars.AddMicroButton then return false end
    local copy = {}
    for field, value in pairs(def) do copy[field] = value end
    if type(def.onClick) == "function" then copy.onClick = Owned(owner, def.onClick) end
    return NS.ActionBars:AddMicroButton(copy)
end

function API:AddTag(key, fn, owner)
    if type(fn) ~= "function" then return false end
    return NS.PlayerUI and NS.PlayerUI.AddTag and NS.PlayerUI:AddTag(key, Owned(owner, fn)) or false
end

function API:AddPlateCondition(def, owner)
    if type(def) ~= "table" or type(def.test) ~= "function" or not NS.Nameplates then return false end
    local test = def.test
    local copy = { key = def.key, label = def.label, options = def.options }
    copy.test = function(unit, value)
        if owner and registry[owner] and registry[owner].status ~= "loaded" then return true end
        return test(unit, value)
    end
    return NS.Nameplates:AddCondition(copy)
end

function API:AddTooltipLines(kind, fn, owner)
    local list = NS.TOOLTIP_LINES and NS.TOOLTIP_LINES[kind]
    if not list or type(fn) ~= "function" then return false end
    table.insert(list, { fn = Owned(owner, fn), owner = owner })
    return true
end

function API:RefreshLook(element)
    if NS.Look and NS.Look.Refresh then NS.Look:Refresh(element) end
end

function API:Reload()
    ReloadUI()
end

function API:OpenSettings(name)
    if not NS.Settings then return end
    NS.Settings:Create()
    if NS.settingsFrame then NS.settingsFrame:Show() end
    local key = name and ("plugin_" .. name) or "plugins"
    pcall(NS.Settings.Select, NS.Settings, key)
end

_G.NarciUI_API = API

local function HookEvents()
    local ui = NS.NarciUI
    if ui and type(ui.Show) == "function" then
        hooksecurefunc(ui, "Show", function() Plugins:Fire("CHARACTER_SHOWN") end)
    end
    if ui and type(ui.Hide) == "function" then
        hooksecurefunc(ui, "Hide", function() Plugins:Fire("CHARACTER_HIDDEN") end)
    end
    if NS.Movers and type(NS.Movers.LoadLayout) == "function" then
        hooksecurefunc(NS.Movers, "LoadLayout", function(_, slot) Plugins:Fire("LAYOUT_APPLIED", slot) end)
    end
    if NS.Look and type(NS.Look.ApplyPreset) == "function" then
        hooksecurefunc(NS.Look, "ApplyPreset", function(_, key) Plugins:Fire("LOOK_APPLIED", key) end)
    end
    if NS.Settings and type(NS.Settings.Create) == "function" then
        hooksecurefunc(NS.Settings, "Create", function()
            local frame = NS.settingsFrame
            if frame and not frame.narciPluginHook then
                frame.narciPluginHook = true
                frame:HookScript("OnShow", function() Plugins:Fire("SETTINGS_SHOWN") end)
            end
        end)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    HookEvents()
    if NS.After then
        NS.After(0, function() Plugins:LoadAll() end)
    else
        Plugins:LoadAll()
    end
end)
