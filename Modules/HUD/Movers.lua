local addonName, NS = ...
local L = NS.L

local Movers = {}
NS.Movers = Movers

local WHITE = "Interface\\Buttons\\WHITE8x8"

local registry = {}
local active = false
local hint

Movers.finish = {}

local function Style()
    return NS.Styling
end

local function BuildHint()
    if hint then return hint end

    local S = Style()

    local f = CreateFrame("Frame", "NarciSirus_MoverHint", UIParent)
    f:SetSize(460, 78)
    f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(2)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()

    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.022, 0.025, 0.034, 0.96)

    local top = f:CreateTexture(nil, "BORDER")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 10, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, 0)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.50)

    local bottom = f:CreateTexture(nil, "BORDER")
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 0)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 0)
    bottom:SetTexture(WHITE)
    bottom:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.50,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetFont(NS.FONT, NS.FS(12), "")
    text:SetPoint("TOP", f, "TOP", 0, -10)
    text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    text:SetText(L["Тяните подсвеченные блоки левой кнопкой"])

    local keys = f:CreateFontString(nil, "OVERLAY")
    keys:SetFont(NS.FONT, NS.FS(10), "")
    keys:SetPoint("TOP", text, "BOTTOM", 0, -4)
    keys:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    keys:SetText(L["Клик и стрелки двигают по пикселю, Shift - по десять, края прилипают"])

    local back = f:CreateFontString(nil, "OVERLAY")
    back:SetFont(NS.FONT, NS.FS(10), "")
    back:SetPoint("TOP", keys, "BOTTOM", 0, -2)
    back:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    back:SetText(L["Правый клик убирает блок под остальные, если он закрывает другой. Эту панель тоже можно перетащить"])
    f:SetSize(520, 92)

    local done = NS.Widgets.CreateThemedButton(f, L["Готово"], 110, 22, function()
        Movers:Stop()
    end)
    done:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)

    hint = f
    return f
end

function Movers:Register(frame, label, save, group)
    if not frame or frame.narciMoverOverlay then return end

    local S = Style()

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:Hide()

    local wash = overlay:CreateTexture(nil, "BACKGROUND")
    wash:SetAllPoints(overlay)
    wash:SetTexture(WHITE)
    wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)

    local edges = {}

    for index = 1, 4 do
        local line = overlay:CreateTexture(nil, "BORDER")
        line:SetTexture(WHITE)
        line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)

    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)

    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)

    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)

    local tag = overlay:CreateFontString(nil, "OVERLAY")
    tag:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    tag:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    tag:SetTextColor(1, 1, 1)
    tag:SetText(label)

    overlay:SetScript("OnDragStart", function()
        if InCombatLockdown() then
            NS.Print(L["В бою двигать нельзя"])
            return
        end
        frame:StartMoving()
    end)

    local function Store()
        local point, _, relativePoint, x, y = frame:GetPoint()
        if save then pcall(save, point, relativePoint, x, y) end
    end

    local function Snap()
        local point, parent, relativePoint, x, y = frame:GetPoint()
        if not point then return end

        local width = UIParent:GetWidth()
        local height = UIParent:GetHeight()
        local snapped = false

        if math.abs(x) <= 12 then x, snapped = 0, true end
        if math.abs(y) <= 12 then y, snapped = 0, true end

        if math.abs(math.abs(x) - width / 2) <= 12 then
            x = (x < 0 and -1 or 1) * math.floor(width / 2)
            snapped = true
        end

        if math.abs(math.abs(y) - height / 2) <= 12 then
            y = (y < 0 and -1 or 1) * math.floor(height / 2)
            snapped = true
        end

        if snapped then
            frame:ClearAllPoints()
            frame:SetPoint(point, parent or UIParent, relativePoint, x, y)
        end
    end

    overlay:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        Snap()
        Store()
    end)

    overlay:EnableKeyboard(false)

    overlay:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            Movers:SendBack(self)
            return
        end
        Movers.selected = self
        self:EnableKeyboard(true)
    end)

    overlay:SetScript("OnKeyDown", function(self, key)
        local step = IsShiftKeyDown() and 10 or 1
        local point, parent, relativePoint, x, y = frame:GetPoint()
        if not point then return end

        if key == "LEFT" then
            x = x - step
        elseif key == "RIGHT" then
            x = x + step
        elseif key == "UP" then
            y = y + step
        elseif key == "DOWN" then
            y = y - step
        elseif key == "ESCAPE" then
            self:EnableKeyboard(false)
            Movers:Stop()
            return
        else
            self:EnableKeyboard(false)
            return
        end

        frame:ClearAllPoints()
        frame:SetPoint(point, parent or UIParent, relativePoint, x, y)
        Store()
    end)

    overlay:SetScript("OnEnter", function(self)
        wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.40)
    end)

    overlay:SetScript("OnLeave", function(self)
        wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
    end)

    frame.narciMoverOverlay = overlay

    registry[#registry + 1] = { frame = frame, overlay = overlay, label = label, group = group or "all", save = save,
        id = (group or "all") .. ":" .. (frame:GetName() or label or tostring(#registry + 1)) }

    if active then overlay:Show() end

    return overlay
end

local STACK_BASE = 40
local backLevel = STACK_BASE

function Movers:SendBack(overlay)
    backLevel = math.max(4, backLevel - 1)
    overlay:EnableKeyboard(false)
    overlay:SetFrameLevel(backLevel)
end

function Movers:Stack()
    local shown = {}
    for _, entry in ipairs(registry) do
        if entry.overlay:IsShown() then
            local width, height = entry.frame:GetWidth() or 0, entry.frame:GetHeight() or 0
            entry.area = width * height
            shown[#shown + 1] = entry
        end
    end
    table.sort(shown, function(a, b) return a.area > b.area end)
    for index, entry in ipairs(shown) do
        entry.overlay:SetFrameLevel(STACK_BASE + index)
    end
    backLevel = STACK_BASE
end

function Movers:Prepare()
    for key, module in pairs(NS) do
        if type(module) == "table" and key ~= "Movers" and type(rawget(module, "PrepareMove")) == "function" then
            local ok, err = pcall(module.PrepareMove, module)
            if not ok and NS.Print then NS.Print(tostring(key) .. ": " .. tostring(err)) end
        end
    end
end

function Movers:Start()
    if InCombatLockdown() then
        NS.Print(L["В бою двигать нельзя"])
        return
    end
    local group
    active = true
    Movers.group = nil
    self:Prepare()

    BuildHint():Show()

    local shown = 0

    for _, entry in ipairs(registry) do
        local wanted = not group or group == "all" or entry.group == group

        if wanted and entry.frame.narciForceShow and not entry.frame:IsShown()
            and not InCombatLockdown() then
            entry.frame:Show()
        end

        if wanted and entry.frame:IsShown() then
            entry.overlay:Show()
            shown = shown + 1
        else
            entry.overlay:Hide()
        end
    end

    self:Stack()

    if shown == 0 then
        NS.Print(L["Нечего расставлять: включите рамки, панели или шкалу кулдаунов"])
    end
end

function Movers:Stop()
    if not active then return end
    active = false

    if hint then hint:Hide() end

    for _, entry in ipairs(registry) do
        entry.overlay:Hide()
    end

    for _, callback in ipairs(Movers.finish) do
        pcall(callback)
    end
end

function Movers:Toggle()
    if active then
        self:Stop()
    else
        self:Start()
    end
end

local anchors = {}

function Movers:Settings()
    if not NS.db then return {} end
    if type(NS.db.moverExtras) ~= "table" then NS.db.moverExtras = {} end
    return NS.db.moverExtras
end

function Movers:Adopt(key, frame, label, defaultPoint)
    if not frame or anchors[key] then return end
    anchors[key] = frame
    local db = self:Settings()
    local saved = db[key]
    if saved and saved.point then
        frame:ClearAllPoints()
        frame:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
        if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
    elseif defaultPoint then
        frame:ClearAllPoints()
        frame:SetPoint(unpack(defaultPoint))
    end
    self:Register(frame, label, function(point, relativePoint, x, y)
        db[key] = { point = point, relativePoint = relativePoint, x = x, y = y }
        if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
    end, "extras")
end

function Movers:AdoptTracker()
    local tracker = _G.ObjectiveTrackerFrame or _G.WatchFrame
    if not tracker or anchors.tracker or InCombatLockdown() then return end
    if tracker:IsProtected() then return end
    if tracker:GetParent() ~= UIParent and tracker:GetParent() ~= nil then return end
    self:Adopt("tracker", tracker, L["Трекер заданий"])
end

function Movers:TooltipAnchor()
    if anchors.tooltip then return anchors.tooltip end
    local f = CreateFrame("Frame", "NarciSirus_TooltipAnchor", UIParent)
    f:SetSize(220, 60)
    f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 120)
    f.narciForceShow = true
    self:Adopt("tooltip", f, L["Подсказки"])
    f:Hide()
    table.insert(Movers.finish, function() f:Hide() end)
    return f
end

function Movers:HasTooltipAnchor()
    local db = self:Settings()
    return db.tooltip and db.tooltip.point and true or false
end

local extrasLoader = CreateFrame("Frame")
extrasLoader:RegisterEvent("PLAYER_LOGIN")
extrasLoader:SetScript("OnEvent", function()
    NS.After(4, function()
        Movers:AdoptTracker()
        Movers:TooltipAnchor()
    end)
end)

function Movers:Entries()
    return registry
end

function Movers:Snapshot()
    local snapshot = {}
    for _, entry in ipairs(registry) do
        local point, _, relativePoint, x, y = entry.frame:GetPoint()
        if point and entry.id then
            snapshot[entry.id] = { point, relativePoint or point, math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10 }
        end
    end
    return snapshot
end

function Movers:ApplySnapshot(snapshot)
    if type(snapshot) ~= "table" then return false end
    if InCombatLockdown() then
        NS.Print(L["В бою двигать нельзя"])
        return false
    end

    for _, entry in ipairs(registry) do
        local position = entry.id and snapshot[entry.id]
        if position and entry.save then
            entry.frame:ClearAllPoints()
            entry.frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
            pcall(entry.save, position[1], position[2], position[3], position[4])
        end
    end

    for _, callback in ipairs(Movers.finish) do
        pcall(callback)
    end
    return true
end

Movers.LAYOUT_SLOTS = {
    { key = "tank",    name = "Танк" },
    { key = "healer",  name = "Лекарь" },
    { key = "damage",  name = "Боец" },
    { key = "custom1", name = "Своя 1" },
    { key = "custom2", name = "Своя 2" },
}

function Movers:Layouts()
    if not NS.db then return end
    if type(NS.db.layouts) ~= "table" then NS.db.layouts = {} end
    local db = NS.db.layouts
    if type(db.saved) ~= "table" then db.saved = {} end
    if type(db.bySpec) ~= "table" then db.bySpec = {} end
    return db
end

function Movers:SaveLayout(slot)
    local db = self:Layouts()
    if not db or not slot then return end
    db.saved[slot] = { positions = self:Snapshot(), time = time() }
    NS.Print(string.format(L["Раскладка сохранена: %s"], L[self:SlotName(slot)]))
end

function Movers:SlotName(slot)
    for _, entry in ipairs(self.LAYOUT_SLOTS) do
        if entry.key == slot then return entry.name end
    end
    return slot
end

function Movers:LoadLayout(slot, quiet)
    local db = self:Layouts()
    local saved = db and db.saved[slot]
    if not saved then
        if not quiet then NS.Print(L["Эта раскладка ещё не сохранена"]) end
        return false
    end
    if self:ApplySnapshot(saved.positions) then
        db.current = slot
        if not quiet then NS.Print(string.format(L["Раскладка применена: %s"], L[self:SlotName(slot)])) end
        return true
    end
    db.pending = slot
    return false
end

local function CurrentSpec()
    if C_Talent and C_Talent.GetCurrentSpecTabIndex then
        local ok, index = pcall(C_Talent.GetCurrentSpecTabIndex)
        if ok and index and index > 0 then return index end
    end
    local best, points = 1, -1
    for tab = 1, GetNumTalentTabs and GetNumTalentTabs() or 0 do
        local _, _, spent = GetTalentTabInfo(tab)
        if (spent or 0) > points then best, points = tab, spent or 0 end
    end
    return best
end
Movers.CurrentSpec = CurrentSpec

function Movers:CheckSpec()
    local db = self:Layouts()
    if not db or not db.auto then return end
    local spec = CurrentSpec()
    local slot = db.bySpec[spec]
    if not slot or slot == "none" or slot == db.current or not db.saved[slot] then return end
    self:LoadLayout(slot, false)
end

local specWatcher = CreateFrame("Frame")
specWatcher:RegisterEvent("PLAYER_LOGIN")
specWatcher:RegisterEvent("PLAYER_TALENT_UPDATE")
specWatcher:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
specWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
if specWatcher.RegisterCustomEvent then
    pcall(specWatcher.RegisterCustomEvent, specWatcher, "PLAYER_TALENT_UPDATE_EX")
end
specWatcher:SetScript("OnEvent", function(_, event)
    if not NS.After then return end
    if event == "PLAYER_REGEN_ENABLED" then
        local db = Movers:Layouts()
        if db and db.pending then
            local slot = db.pending
            db.pending = nil
            Movers:LoadLayout(slot, false)
        end
        return
    end
    NS.After(event == "PLAYER_LOGIN" and 4 or 1, function() Movers:CheckSpec() end)
end)

function Movers:IsActive()
    return active
end

function Movers:Refresh()
    if not active then return end

    for _, entry in ipairs(registry) do
        entry.overlay:SetShown(entry.frame:IsShown())
    end
end

Movers.WINDOWS = {
    { name = "NarcissusSirus_GroupFinder",  label = "Поиск группы", module = "GroupFinderPanel", density = true,
      tabs = { { key = "lfg", label = "Подземелья и рейды" }, { key = "pvp", label = "PvP" },
               { key = "mythic", label = "Эпохальные+" }, { key = "ladder", label = "Ладдер" } } },
    { name = "NarcissusSirus_Adventure",    label = "Приключения", module = "AdventurePanel" },
    { name = "NarcissusSirus_Achievements", label = "Достижения", module = "AchievementsPanel", density = true,
      filters = { { key = "all", label = "все" }, { key = "complete", label = "полученные" }, { key = "incomplete", label = "не полученные" } } },
    { name = "NarcissusSirus_Challenges",   label = "Испытания", module = "ChallengePanel", density = true },
    { name = "NarcissusSirus_HeadHunting",  label = "Охота за головами", module = "HeadHuntingPanel", density = true,
      tabs = { { key = 1, label = "Главная" }, { key = 2, label = "Цели" }, { key = 3, label = "Ваши цели" } } },
    { name = "NarcissusSirus_Social",       label = "Общение", module = "SocialPanel", density = true,
      tabs = { { key = 1, label = "Друзья" }, { key = 2, label = "Кто" }, { key = 3, label = "Каналы" }, { key = 4, label = "Рейд" } } },
    { name = "NarcissusSirus_GuildPanel",   label = "Гильдия", module = "GuildPanel", density = true },
    { name = "NarcissusSirus_Collections",  label = "Коллекции", module = "CollectionsPanel", density = true,
      tabs = { { key = "mounts", label = "Транспорт" }, { key = "pets", label = "Питомцы" }, { key = "wardrobe", label = "Модели" },
               { key = "toys", label = "Игрушки" }, { key = "heirlooms", label = "Наследство" } } },
    { name = "NarcissusSirus_SpellBook",    label = "Книга заклинаний", module = "SpellBookPanel" },
    { name = "NarcissusSirus_QuestLog",     label = "Журнал заданий", module = "QuestLog", density = true },
    { name = "NarcissusSirus_AddonList",    label = "Список аддонов", module = "AddonListPanel" },
}

function Movers:WindowPrefs()
    if not NS.db then return {} end
    if type(NS.db.windows) ~= "table" then NS.db.windows = {} end
    local db = NS.db.windows
    if db.remember == nil then db.remember = true end
    db.scale = db.scale or 100
    if type(db.each) ~= "table" then db.each = {} end
    return db
end

local function WindowStore(name)
    local db = Movers:WindowPrefs()
    if type(db.each[name]) ~= "table" then db.each[name] = {} end
    return db.each[name]
end

local function Blocked(frame)
    if not InCombatLockdown() then return false end
    local _, explicit = frame:IsProtected()
    return explicit or frame:IsProtected()
end

local function EntryFor(name)
    for _, entry in ipairs(Movers.WINDOWS) do
        if entry.name == name then return entry end
    end
end

function Movers:StartState(entry)
    local module = entry.module and NS[entry.module]
    if not module then return end
    local store = WindowStore(entry.name)
    if entry.tabs and store.tab ~= nil and store.tab ~= "last" then module.tab = store.tab end
    if entry.filters and store.filter and store.filter ~= "last" then module.filter = store.filter end
end

function Movers:Background(frame)
    local store = WindowStore(frame:GetName())
    if not frame.GetBackdropColor or not frame.SetBackdropColor then return end
    if not frame.narciBaseBg then
        local r, g, b, a = frame:GetBackdropColor()
        if not r then return end
        frame.narciBaseBg = { r, g, b, a or 1 }
    end
    local base = frame.narciBaseBg
    pcall(frame.SetBackdropColor, frame, base[1], base[2], base[3], base[4] * (store.bg or 100) / 100)
end

Movers.WINDOW_STYLES = {
    glass = { bg = { 0.05, 0.06, 0.09, 0.62 }, box = "glass" },
    classic = { bg = { 0.03, 0.03, 0.04, 0.96 }, box = "gold" },
    night = { scene = "night", box = "flat", tint = { 0.42, 0.46, 0.85 } },
    dawn = { scene = "dawn", box = "flat", tint = { 0.9, 0.6, 0.5 } },
    parchment = { scene = "parchment", box = "gold" },
    arcane = { bg = { 0.05, 0.02, 0.09, 0.96 }, box = "neon", tint = { 0.62, 0.4, 1 }, mark = true },
}
Movers.WINDOW_STYLE_ORDER = { "theme", "glass", "classic", "night", "dawn", "parchment", "arcane" }
Movers.WINDOW_STYLE_LABELS = {
    theme = "как окна аддона", glass = "Стекло", classic = "Золото", night = "Ночное небо",
    dawn = "Рассвет", parchment = "Пергамент", arcane = "Аркана",
}

function Movers:WindowStyle(name)
    local db = self:WindowPrefs()
    local store = WindowStore(name)
    local key = store.style
    if not key or key == "all" then key = db.style or "theme" end
    return key, self.WINDOW_STYLES[key], store
end

function Movers:SkinWindow(frame)
    local S = NS.Styling
    local key, style, store = self:WindowStyle(frame:GetName())
    if not style and not frame.narciWinSkin then return end
    if frame.GetBackdropColor and not frame.narciBaseBg then
        local r, g, b, a = frame:GetBackdropColor()
        if r then frame.narciBaseBg = { r, g, b, a or 1 } end
    end
    if frame.GetBackdropBorderColor and not frame.narciBaseEdge then
        local r, g, b, a = frame:GetBackdropBorderColor()
        if r then frame.narciBaseEdge = { r, g, b, a or 1 } end
    end

    local skin = frame.narciWinSkin
    if not skin then
        skin = CreateFrame("Frame", nil, frame)
        skin:SetAllPoints(frame)
        skin:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
        skin.bg = skin:CreateTexture(nil, "BACKGROUND")
        skin.bg:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
        skin.bg:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
        skin.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        skin.art = skin:CreateTexture(nil, "BORDER")
        skin.art:SetPoint("TOPLEFT", skin, "TOPLEFT", 1, -1)
        skin.art:SetPoint("BOTTOMRIGHT", skin, "BOTTOMRIGHT", -1, 1)
        skin.shade = skin:CreateTexture(nil, "ARTWORK")
        skin.shade:SetAllPoints(skin.art)
        skin.shade:SetTexture("Interface\\Buttons\\WHITE8x8")
        skin.mark = skin:CreateTexture(nil, "ARTWORK")
        skin.mark:SetPoint("CENTER", skin, "CENTER", 0, 0)
        skin.mark:SetBlendMode("ADD")
        frame.narciWinSkin = skin
    end

    if not style then
        skin:Hide()
        skin:SetScript("OnUpdate", nil)
        S.FadeChrome(frame, true)
        local edge = frame.narciBaseEdge
        if edge and frame.SetBackdropBorderColor then pcall(frame.SetBackdropBorderColor, frame, edge[1], edge[2], edge[3], edge[4]) end
        self:Background(frame)
        return
    end

    S.FadeChrome(frame, false)
    if frame.SetBackdropColor then pcall(frame.SetBackdropColor, frame, 0, 0, 0, 0) end
    if frame.SetBackdropBorderColor then pcall(frame.SetBackdropBorderColor, frame, 0, 0, 0, 0) end
    skin:Show()
    local alpha = (store.bg or 100) / 100
    if style.bg then
        local c = style.bg
        skin.bg:SetVertexColor(c[1], c[2], c[3], c[4] * alpha)
        skin.bg:Show()
    else
        skin.bg:Hide()
    end
    local scene = style.scene and S.SceneArt(skin.art, style.scene)
    if scene then
        skin.art:SetVertexColor(1, 1, 1, alpha)
        skin.art:Show()
        skin.shade:SetVertexColor(0, 0, 0, (store.shade or 35) / 100)
        skin.shade:Show()
    else
        skin.art:Hide()
        skin.shade:Hide()
    end
    S.SkinBox(skin, style.box or "none", {
        alpha = alpha, noGround = (style.bg or scene) and true or false,
        edgeSize = 16, glowSize = 10, shadowSize = 12, tint = style.tint, borderLevel = 30,
    })
    if style.mark then
        local size = math.min(frame:GetWidth() or 300, frame:GetHeight() or 300) * 0.85
        skin.mark:SetTexture(S.Media("MessengerRunes"))
        skin.mark:SetSize(size, size)
        skin.mark:SetVertexColor(0.7, 0.5, 1, 0.16)
        skin.mark:Show()
        if skin.mark.SetRotation then
            local angle = 0
            skin:SetScript("OnUpdate", function(_, elapsed)
                angle = (angle + elapsed * 0.03) % (math.pi * 2)
                skin.mark:SetRotation(angle)
            end)
        end
    else
        skin.mark:Hide()
        skin:SetScript("OnUpdate", nil)
    end
end

function Movers:ApplyWindow(frame)
    if not frame or Blocked(frame) then return end
    local db = self:WindowPrefs()
    local store = WindowStore(frame:GetName())
    if store.bg and store.bg ~= 100 or frame.narciBaseBg then self:Background(frame) end
    self:SkinWindow(frame)
    local scale = (db.scale or 100) / 100 * (store.scale or 100) / 100
    if math.abs((frame:GetScale() or 1) - scale) > 0.001 then pcall(frame.SetScale, frame, scale) end
    if db.remember and store.point then
        frame:ClearAllPoints()
        pcall(frame.SetPoint, frame, store.point, UIParent, store.relativePoint or store.point, store.x or 0, store.y or 0)
    end
end

local function WindowRect(frame)
    local left, top, right, bottom = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom()
    if not left or not top or not right or not bottom then return end
    local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return { left = left * k, top = top * k, right = right * k, bottom = bottom * k }
end

local function Overlap(a, b)
    local w = math.min(a.right, b.right) - math.max(a.left, b.left)
    local h = math.min(a.top, b.top) - math.max(a.bottom, b.bottom)
    if w <= 0 or h <= 0 then return 0 end
    local area = math.min((a.right - a.left) * (a.top - a.bottom), (b.right - b.left) * (b.top - b.bottom))
    return area > 0 and w * h / area or 0
end

function Movers:Arrange(frame)
    local db = self:WindowPrefs()
    if db.arrange == false or Blocked(frame) then return end
    local rect = WindowRect(frame)
    if not rect then return end
    local others = {}
    local hit
    for _, entry in ipairs(self.WINDOWS) do
        local other = entry.name ~= frame:GetName() and _G[entry.name]
        local otherRect = other and other:IsShown() and WindowRect(other)
        if otherRect then
            others[#others + 1] = otherRect
            if Overlap(rect, otherRect) > 0.25 then hit = otherRect end
        end
    end
    if not hit then return end
    local width, height = rect.right - rect.left, rect.top - rect.bottom
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    local function Free(left, top)
        if left < 0 or left + width > screenW or top > screenH or top - height < 0 then return false end
        local test = { left = left, top = top, right = left + width, bottom = top - height }
        for _, other in ipairs(others) do
            if Overlap(test, other) > 0.1 then return false end
        end
        return true
    end
    local top = math.min(hit.top, screenH)
    local left
    if Free(hit.right + 8, top) then
        left = hit.right + 8
    elseif Free(hit.left - 8 - width, top) then
        left = hit.left - 8 - width
    else
        left, top = rect.left, rect.top
        for _ = 1, 8 do
            left, top = left + 30, top - 30
            if left + width > screenW or top - height < 0 then left, top = 30, screenH - 60 end
            local clear = true
            for _, other in ipairs(others) do
                if math.abs(other.left - left) < 10 and math.abs(other.top - top) < 10 then clear = false end
            end
            if clear then break end
        end
    end
    local k = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    frame:ClearAllPoints()
    pcall(frame.SetPoint, frame, "TOPLEFT", UIParent, "BOTTOMLEFT", left * k, top * k)
end

function Movers:ResetWindow(name)
    local store = WindowStore(name)
    store.point, store.relativePoint, store.x, store.y = nil, nil, nil, nil
    local frame = _G[name]
    if frame and not Blocked(frame) then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    end
end

function Movers:ApplyAllWindows()
    for _, entry in ipairs(self.WINDOWS) do
        local frame = _G[entry.name]
        if frame and frame:IsShown() then self:ApplyWindow(frame) end
    end
end

Movers.POPUPS = {
    "LFGListInviteDialog", "LFGListApplicationDialog", "LFGListRaidRulesDialog", "LFDRoleCheckPopup",
    "LFDDungeonReadyPopup", "MiniGameReadyPopup", "ReadyCheckFrame", "ReadyCheckListenerFrame",
    "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4", "GuildInviteFrame",
    "BNConversationInviteDialog", "PetRenamePopup",
}

local function LiftPopup(frame)
    if not frame or (InCombatLockdown() and frame:IsProtected()) then return end
    if frame:GetFrameStrata() ~= "FULLSCREEN_DIALOG" then pcall(frame.SetFrameStrata, frame, "FULLSCREEN_DIALOG") end
end

function Movers:LiftPopups()
    self.liftedPopups = self.liftedPopups or {}
    for _, name in ipairs(self.POPUPS) do
        local frame = _G[name]
        if frame and not self.liftedPopups[name] and frame.HookScript then
            self.liftedPopups[name] = true
            frame:HookScript("OnShow", LiftPopup)
            if frame:IsShown() then LiftPopup(frame) end
        end
    end
end

local windowEvents = CreateFrame("Frame")
windowEvents:RegisterEvent("PLAYER_LOGIN")
windowEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
windowEvents:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        for _, entry in ipairs(Movers.WINDOWS) do Movers:StartState(entry) end
        Movers:LiftPopups()
        return
    end
    if not Movers:WindowPrefs().closeInCombat then return end
    for _, entry in ipairs(Movers.WINDOWS) do
        local frame = _G[entry.name]
        local module = entry.module and NS[entry.module]
        if frame and frame:IsShown() then if module and module.Hide then pcall(module.Hide, module) else frame:Hide() end end
    end
end)

local windowWatch = CreateFrame("Frame")
local windowTick = 0
local hookedWindows = {}
windowWatch:SetScript("OnUpdate", function(self, elapsed)
    windowTick = windowTick + elapsed
    if windowTick < 1 then return end
    windowTick = 0
    local pending = false
    for _, entry in ipairs(Movers.WINDOWS) do
        local frame = not hookedWindows[entry.name] and _G[entry.name]
        if frame then
            hookedWindows[entry.name] = true
            frame:HookScript("OnShow", function(f)
                Movers:ApplyWindow(f)
                if Movers:WindowPrefs().single and not InCombatLockdown() then
                    for _, other in ipairs(Movers.WINDOWS) do
                        local otherFrame = other.name ~= f:GetName() and _G[other.name]
                        local module = other.module and NS[other.module]
                        if otherFrame and otherFrame:IsShown() then if module and module.Hide then pcall(module.Hide, module) else otherFrame:Hide() end end
                    end
                end
                if not Blocked(f) then pcall(f.Raise, f) end
                Movers:Arrange(f)
            end)
            frame:HookScript("OnHide", function(f)
                local entry = EntryFor(f:GetName())
                if entry then Movers:StartState(entry) end
            end)
            hooksecurefunc(frame, "StopMovingOrSizing", function(f)
                local point, _, relativePoint, x, y = f:GetPoint()
                if not point then return end
                local store = WindowStore(f:GetName())
                store.point, store.relativePoint, store.x, store.y = point, relativePoint, x, y
            end)
            if frame:IsShown() then Movers:ApplyWindow(frame) end
        elseif not hookedWindows[entry.name] then
            pending = true
        end
    end
    if not pending then self:Hide() end
end)

function Movers:AddWindow(def)
    if type(def) ~= "table" or type(def.name) ~= "string" or EntryFor(def.name) then return false end
    table.insert(self.WINDOWS, {
        name = def.name, label = def.label or def.name, module = def.module,
        density = def.density, tabs = def.tabs, filters = def.filters,
    })
    windowWatch:Show()
    return true
end
