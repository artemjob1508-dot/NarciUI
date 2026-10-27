local addonName, NS = ...
local L = NS.L

local Look = {}
NS.Look = Look

local WHITE = "Interface\\Buttons\\WHITE8x8"

Look.TEXTURES = {
    { key = "default",    name = "как в стиле" },
    { key = "flat",       name = "Гладкая",        path = WHITE },
    { key = "shaded",     name = "Затенённая",     path = "Interface\\TargetingFrame\\UI-StatusBar" },
    { key = "smooth", name = "Мягкая", path = "BarSoft" },
    { key = "raid", name = "Глянец", path = "BarGloss" },
    { key = "target", name = "Объёмная", path = "BarBevel" },
    { key = "skills", name = "Матовая", path = "BarMatte" },
    { key = "reputation", name = "Стекло", path = "BarGlass" },
    { key = "arena", name = "Металл", path = "BarMetal" },
    { key = "battlepass", name = "Неоновая", path = "BarNeon" },
    { key = "striped", name = "Полосатая", path = "BarStripes" },
    { key = "hatched", name = "Штриховка", path = "BarHatch" },
}

local TEXTURE_BY_KEY = {}
for _, texture in ipairs(Look.TEXTURES) do TEXTURE_BY_KEY[texture.key] = texture end

Look.OUTLINES = {
    { key = "default", name = "как в стиле" },
    { key = "none",    name = "без обводки",     flags = "" },
    { key = "outline", name = "обводка",         flags = "OUTLINE" },
    { key = "thick",   name = "толстая обводка", flags = "THICKOUTLINE" },
    { key = "mono",    name = "пиксельная",      flags = "MONOCHROME,OUTLINE" },
}

local OUTLINE_BY_KEY = {}
for _, outline in ipairs(Look.OUTLINES) do OUTLINE_BY_KEY[outline.key] = outline end

Look.COLOR_SLOTS = {
    bar    = "Цвет полосы",
    power  = "Цвет полосы ресурса",
    bg     = "Фон",
    border = "Рамка",
    text   = "Текст",
}

Look.ELEMENTS = {
    { key = "unitframes", name = "Рамки юнитов",      bars = true, colors = { "bar", "power", "bg", "border", "text" } },
    { key = "raid",       name = "Рейд-фреймы",       bars = true, colors = { "bar", "power", "bg", "border", "text" } },
    { key = "nameplates", name = "Неймплейты",        bars = true, colors = { "bar", "bg", "border", "text" } },
    { key = "castbar",    name = "Полоса заклинания", bars = true, colors = { "bar", "bg", "border", "text" } },
    { key = "threat",     name = "Угроза",            bars = true, colors = { "bg", "border", "text" } },
    { key = "tooltip",    name = "Подсказки",         bars = true, colors = { "bar", "bg", "border" } },
    { key = "auras",      name = "Бафы",              bars = true, colors = { "border", "text" } },
    { key = "actionbars", name = "Панели команд",     colors = { "border", "text" } },
    { key = "cooldowns",  name = "Восстановление",    colors = { "bg", "border", "text" } },
    { key = "chat",       name = "Чат",               colors = { "bg", "border" } },
    { key = "minimap",    name = "Миникарта",         colors = { "border", "text" } },
    { key = "datatexts",  name = "Показатели",        colors = { "bg", "border", "text" } },
    { key = "bags",       name = "Сумки",             colors = { "bg", "border", "text" } },
}

local ELEMENT_BY_KEY = {}
for _, element in ipairs(Look.ELEMENTS) do ELEMENT_BY_KEY[element.key] = element end
Look.ELEMENT_BY_KEY = ELEMENT_BY_KEY

Look.GLOBAL = "global"

Look.GLOBAL_SLOTS = {
    border = "Цвет рамки",
    bg     = "Цвет фона",
    fade   = "Фон панелей",
    value  = "Цвет значений",
}

local PANEL_ELEMENTS = { chat = true, datatexts = true, bags = true, tooltip = true, threat = true, cooldowns = true }

function Look:Settings()
    if not NS.db then return end
    if type(NS.db.elementLook) ~= "table" then NS.db.elementLook = {} end
    local db = NS.db.elementLook
    if type(db.elements) ~= "table" then db.elements = {} end
    db.texture = db.texture or "default"
    db.font = db.font or "default"
    db.outline = db.outline or "default"
    db.fontScale = db.fontScale or 100
    return db
end

function Look:Element(key)
    local db = self:Settings()
    if not db or not key then return {} end
    if type(db.elements[key]) ~= "table" then db.elements[key] = {} end
    local element = db.elements[key]
    if type(element.colors) ~= "table" then element.colors = {} end
    return element
end

function Look:BarTexture(key, fallback)
    local db = self:Settings()
    if not db then return fallback or WHITE end
    local element = key and db.elements[key]
    local choice = element and element.texture
    if not choice or choice == "default" then choice = db.texture end
    local texture = TEXTURE_BY_KEY[choice]
    if texture and texture.path then return NS.Styling.Media(texture.path) end
    return fallback or WHITE
end

local fontPaths
local fontWorks = {}

local function FontPath(key)
    if not key or key == "default" then return nil end
    if not fontPaths then
        fontPaths = {}
        for _, option in ipairs(NS.FontOptions()) do fontPaths[option.key] = option.path end
    end
    local path = fontPaths[key]
    if not path then return nil end
    if fontWorks[path] == nil then fontWorks[path] = NS.FontWorks(path) and true or false end
    return fontWorks[path] and path or nil
end

function Look:Font(key, size, flags)
    local db = self:Settings()
    if not db then return NS.FONT, size, flags end
    local element = key and db.elements[key] or {}

    local path = FontPath(element.font) or FontPath(db.font) or NS.FONT

    local scale = (db.fontScale or 100) / 100
    if element.fontScale then scale = scale * element.fontScale / 100 end
    size = math.max(6, math.floor((size or 12) * scale + 0.5))

    local outline = element.outline
    if not outline or outline == "default" then outline = db.outline end
    local entry = OUTLINE_BY_KEY[outline]
    if entry and entry.flags then flags = entry.flags end

    return path, size, flags or ""
end

function NS.LFont(key, size, flags)
    return Look:Font(key, size, flags)
end

local trackedFonts = setmetatable({}, { __mode = "k" })
local trackedBars = setmetatable({}, { __mode = "k" })

function NS.LSetFont(text, key, size, flags)
    local entry = trackedFonts[text]
    if not entry then
        entry = {}
        trackedFonts[text] = entry
    end
    entry.key, entry.size, entry.flags = key, size, flags
    return text:SetFont(Look:Font(key, size, flags))
end

function Look:SetBar(bar, key, fallback)
    local entry = trackedBars[bar]
    if not entry then
        entry = {}
        trackedBars[bar] = entry
    end
    entry.key, entry.fallback = key, fallback
    bar:SetStatusBarTexture(self:BarTexture(key, fallback))
end

local function Module(name)
    return NS[name]
end

local REFRESH = {
    unitframes = function()
        local m, db = Module("PlayerUI"), NS.db.playerUI
        if m and db then m:SetLook("frameStyle", db.frameStyle) end
    end,
    raid = function()
        local m = Module("RaidFrames")
        if m then m:ApplyLayout(); m:UpdateAll() end
    end,
    nameplates = function()
        local m = Module("Nameplates")
        if m then m:Refresh() end
    end,
    castbar = function()
        local m = Module("CastBar")
        if m then m:Restyle() end
    end,
    threat = function()
        local m = Module("ThreatMeter")
        if m and m.frame then m:Layout(); m:Update() end
    end,
    tooltip = function()
        local m, db = Module("TooltipSkin"), NS.db.tooltip
        if m and db then m:SetOption("style", db.style) end
    end,
    auras = function()
        local m = Module("AuraSkin")
        if not m then return end
        m:Apply()
        if m.holder then m:Place(); m:Layout() end
    end,
    actionbars = function()
        local m = Module("ActionBars")
        if not m then return end
        if m.skinned then m:RestyleAll() end
        if m.microHolder then m:LayoutMicro(); m:StyleMicro() end
    end,
    cooldowns = function()
        local m = Module("CooldownBar")
        if m then m:ApplyStyle() end
    end,
    chat = function()
        local m = Module("ChatSkin")
        if m then m:Apply() end
    end,
    minimap = function()
        local m = Module("MinimapSkin")
        if m then m:Apply() end
    end,
    datatexts = function()
        local m = Module("DataTexts")
        if m then m:Restyle() end
    end,
    bags = function()
        local m = Module("Bags")
        if not m then return end
        if m.bagWindow then m.bagWindow.styleKey = nil end
        if m.bankWindow then m.bankWindow.styleKey = nil end
        m:Refresh()
    end,
}
Look.REFRESH = REFRESH

local pending = {}
local scheduled = false
local combatWaiter = CreateFrame("Frame")

function Look:Refresh(key)
    if key == Look.GLOBAL then key = nil end
    if key then
        pending[key] = true
    else
        for _, element in ipairs(self.ELEMENTS) do pending[element.key] = true end
    end
    if scheduled then return end
    scheduled = true
    NS.After(0.1, function() Look:Flush() end)
end

function Look:Flush()
    scheduled = false
    if InCombatLockdown() then
        combatWaiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    combatWaiter:UnregisterEvent("PLAYER_REGEN_ENABLED")

    local keys = pending
    pending = {}
    if not next(keys) then return end

    for text, entry in pairs(trackedFonts) do
        if keys[entry.key] then text:SetFont(self:Font(entry.key, entry.size, entry.flags)) end
    end
    for bar, entry in pairs(trackedBars) do
        if keys[entry.key] then bar:SetStatusBarTexture(self:BarTexture(entry.key, entry.fallback)) end
    end
    for key in pairs(keys) do
        local refresh = REFRESH[key]
        if refresh then
            local ok, err = pcall(refresh)
            if not ok and NS.Print then NS.Print("Look " .. key .. ": " .. tostring(err)) end
        end
    end
end

combatWaiter:SetScript("OnEvent", function() Look:Flush() end)

local function Stored(db, key, slot)
    local element = db and key and db.elements[key]
    local color = element and element.colors and element.colors[slot]
    if type(color) == "table" and color[1] then return color end
end

function Look:Color(key, slot)
    local db = self:Settings()
    local color = Stored(db, key, slot)
    if not color and key ~= Look.GLOBAL then
        if slot == "border" then
            color = Stored(db, Look.GLOBAL, "border")
        elseif slot == "bg" then
            color = Stored(db, Look.GLOBAL, PANEL_ELEMENTS[key] and "fade" or "bg")
                or Stored(db, Look.GLOBAL, "bg")
        end
    end
    if color then return color[1], color[2], color[3], color[4] end
end

function Look:OwnColor(key, slot)
    local color = Stored(self:Settings(), key, slot)
    if color then return color[1], color[2], color[3] end
end

function Look:Value()
    local db = self:Settings()
    if db and db.valueClass then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end
    local color = Stored(db, Look.GLOBAL, "value")
    if color then return color[1], color[2], color[3] end
end

function Look:Border(key, alpha)
    local r, g, b = self:Color(key, "border")
    if r then return r, g, b, 1 end
    local B = NS.Styling.BORDER
    return B[1], B[2], B[3], alpha or B[4]
end

function Look:Text(key, fallback)
    local r, g, b = self:Color(key, "text")
    if r then return r, g, b end
    return fallback[1], fallback[2], fallback[3]
end

function Look:HasColor(key, slot)
    return self:Color(key, slot) ~= nil
end

function Look:SetColor(key, slot, r, g, b)
    local element = self:Element(key)
    if r then
        element.colors[slot] = { r, g, b }
    else
        element.colors[slot] = nil
    end
end

local function Preset(key, name, styles, look)
    return { key = key, name = name, styles = styles, look = look }
end

Look.PRESETS = {
    Preset("obsidian", "Обсидиан", {
        frame = "classic", buttons = "flat", micro = "tiles", cast = "line", tooltip = "modern", chat = "panel",
        minimap = "frame", raid = "blocks", auras = "square", data = "panel", cooldown = "rail", threat = "modern",
        plates = "obsidian", bags = "obsidian",
    }, { texture = "default", outline = "default" }),
    Preset("blizzard", "Классика Blizzard", {
        frame = "classic", buttons = "classic", micro = "tiles", cast = "classic", tooltip = "classic", chat = "dialog",
        minimap = "classic", raid = "blocks", auras = "classic", data = "panel", cooldown = "track", threat = "classic",
        plates = "classic", bags = "classic",
    }, { texture = "shaded", outline = "outline" }),
    Preset("minimal", "Минимал", {
        frame = "slim", buttons = "flat", micro = "strip", cast = "thin", tooltip = "minimal", chat = "bare",
        minimap = "round", raid = "minimal", auras = "minimal", data = "fade", cooldown = "line", threat = "modern",
        plates = "minimal", bags = "minimal",
    }, { texture = "flat", outline = "outline" }),
    Preset("neon", "Неон", {
        frame = "neon", buttons = "glow", micro = "glow", cast = "neon", tooltip = "modern", chat = "terminal",
        minimap = "neon", raid = "glow", auras = "glow", data = "glass", cooldown = "neon", threat = "glass",
        plates = "neon", bags = "neon",
    }, { texture = "smooth", outline = "outline" }),
    Preset("pixel", "Пиксель", {
        frame = "plates", buttons = "pixel", micro = "flat", cast = "pixel", tooltip = "pixel", chat = "pixel",
        minimap = "pixel", raid = "outline", auras = "thick", data = "pixel", cooldown = "track", threat = "pixel",
        plates = "pixel", bags = "pixel",
    }, { texture = "flat", outline = "mono" }),
    Preset("glass", "Стекло", {
        frame = "glass", buttons = "flat", micro = "dock", cast = "line", tooltip = "glass", chat = "glass",
        minimap = "frame", raid = "glass", auras = "square", data = "glass", cooldown = "rail", threat = "glass",
        plates = "glass", bags = "glass",
    }, { texture = "smooth", outline = "default" }),
    Preset("cards", "Карточки", {
        frame = "float", buttons = "bevel", micro = "tiles", cast = "line", tooltip = "modern", chat = "card",
        minimap = "photo", raid = "cards", auras = "bar", data = "pills", cooldown = "zones", threat = "modern",
        plates = "plates", bags = "thick",
    }, { texture = "skills", outline = "default" }),
}

local PRESET_PATHS = {
    frame    = { "playerUI", "frameStyle" },
    buttons  = { "actionBars", "look", "style" },
    micro    = { "actionBars", "micro", "style" },
    cast     = { "castBar", "style" },
    tooltip  = { "tooltip", "style" },
    chat     = { "chat", "style" },
    minimap  = { "minimap", "style" },
    raid     = { "raidFrames", "style" },
    auras    = { "auras", "style" },
    data     = { "dataTexts", "style" },
    cooldown = { "cooldownBar", "style" },
    threat   = { "threat", "style" },
    plates   = { "nameplates", "style" },
    bags     = { "bags", "style" },
}

local function SetPath(root, path, value)
    local node = root
    for index = 1, #path - 1 do
        local key = path[index]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[path[#path]] = value
end

function Look:ApplyPreset(key)
    if not NS.db then return end
    local preset
    for _, entry in ipairs(self.PRESETS) do
        if entry.key == key then preset = entry end
    end
    if not preset then return end

    for part, value in pairs(preset.styles) do
        local path = PRESET_PATHS[part]
        if path then SetPath(NS.db, path, value) end
    end

    local db = self:Settings()
    for field, value in pairs(preset.look or {}) do db[field] = value end
    db.preset = key
end

function Look:PresetTable(key)
    local preset
    for _, entry in ipairs(self.PRESETS) do
        if entry.key == key then preset = entry end
    end
    if not preset then return end

    local data = {}
    for part, value in pairs(preset.styles) do
        local path = PRESET_PATHS[part]
        if path then SetPath(data, path, value) end
    end
    for field, value in pairs(preset.look or {}) do SetPath(data, { "elementLook", field }, value) end
    SetPath(data, { "elementLook", "preset" }, key)
    return data
end

function Look:AddTexture(key, name, path)
    if type(key) ~= "string" or type(path) ~= "string" or TEXTURE_BY_KEY[key] then return false end
    local entry = { key = key, name = name or key, path = path }
    self.TEXTURES[#self.TEXTURES + 1] = entry
    TEXTURE_BY_KEY[key] = entry
    return true
end

function Look:AddElement(def)
    if type(def) ~= "table" or type(def.key) ~= "string" or def.key == "" or ELEMENT_BY_KEY[def.key] or def.key == Look.GLOBAL then return false end
    local colors = {}
    for _, slot in ipairs(type(def.colors) == "table" and def.colors or {}) do
        if Look.COLOR_SLOTS[slot] then colors[#colors + 1] = slot end
    end
    local element = { key = def.key, name = def.name or def.key, bars = def.bars and true or nil, colors = colors, extra = true }
    table.insert(self.ELEMENTS, element)
    ELEMENT_BY_KEY[def.key] = element
    if type(def.refresh) == "function" then REFRESH[def.key] = def.refresh end
    return true
end

function Look:AddFont(key, label, path)
    if type(key) ~= "string" or type(path) ~= "string" then return false end
    for _, option in ipairs(NS.FontOptions()) do
        if option.key == key then return false end
    end
    NS.EXTRA_FONTS[#NS.EXTRA_FONTS + 1] = { key = key, label = label or key, path = path }
    fontPaths = nil
    if NS.db and NS.db.font == key and NS.ApplyFont then NS.ApplyFont() end
    return true
end

function Look:AddPreset(preset)
    if type(preset) ~= "table" or type(preset.key) ~= "string" or type(preset.styles) ~= "table" then return false end
    for _, entry in ipairs(self.PRESETS) do
        if entry.key == preset.key then return false end
    end
    self.PRESETS[#self.PRESETS + 1] = { key = preset.key, name = preset.name or preset.key, styles = preset.styles, look = preset.look }
    return true
end

function Look:Reset(key)
    local db = self:Settings()
    if db and key then db.elements[key] = nil end
end

function Look:ResetAll()
    if NS.db then NS.db.elementLook = nil end
end
