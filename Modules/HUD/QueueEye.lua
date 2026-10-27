local addonName, NS = ...
local L = NS.L

local Eye = {}
NS.QueueEye = Eye

Eye.STYLES = {
    "arcane", "crystal", "portal", "astrolabe", "goldcompass", "flame",
    "eye", "radar", "compass", "orbit", "sonar", "hourglass", "magnifier", "rune",
}
Eye.FILES = {
    eye = "QueueEye", radar = "QueueRadar", compass = "QueueCompass", orbit = "QueueOrbit",
    sonar = "QueueSonar", hourglass = "QueueHourglass", magnifier = "QueueMagnifier", rune = "QueueRune",
    arcane = "QueueArcane", crystal = "QueueCrystal", portal = "QueuePortal", astrolabe = "QueueAstrolabe",
    goldcompass = "QueueGoldCompass", flame = "QueueFlame",
}
Eye.FULL = {
    arcane = { 0.65, 0.35, 1 }, crystal = { 0.35, 0.7, 1 }, portal = { 0.7, 0.35, 1 },
    astrolabe = { 1, 0.75, 0.3 }, goldcompass = { 1, 0.8, 0.35 }, flame = { 0.3, 0.75, 1 },
}
Eye.FOUND_GLOW = {
    arcane = { 0.45, 1, 0.55 }, crystal = { 1, 0.85, 0.4 }, portal = { 1, 0.85, 0.5 },
    astrolabe = { 0.45, 1, 0.55 }, goldcompass = { 0.45, 1, 0.55 }, flame = { 0.45, 1, 0.5 },
}
Eye.LABELS = {
    eye = "глаз", radar = "радар", compass = "компас", orbit = "орбита",
    sonar = "сонар", hourglass = "песочные часы", magnifier = "лупа", rune = "руна",
    arcane = "тайный глаз", crystal = "хрустальный шар", portal = "портал", astrolabe = "астролябия",
    goldcompass = "золотой компас", flame = "призрачное пламя",
}
Eye.PLATES = { "disc", "ring", "none" }
Eye.INGAME_ORDER = { "auto", "autorich", "podium", "swords", "gate", "banner", "shield", "crown", "goldswords", "portal", "bannerrich", "trophy" }
Eye.INGAME = {
    podium = { file = "QueueInGame" }, swords = { file = "QueueInGameSwords" }, gate = { file = "QueueInGameGate" },
    banner = { file = "QueueInGameBanner" }, shield = { file = "QueueInGameShield" }, crown = { file = "QueueInGameCrown" },
    goldswords = { file = "QueueInGameGoldSwords", full = true, glow = { 1, 0.8, 0.4 } },
    portal = { file = "QueueInGamePortal", full = true, glow = { 0.7, 0.4, 1 } },
    bannerrich = { file = "QueueInGameBannerRich", full = true, glow = { 1, 0.45, 0.35 } },
    trophy = { file = "QueueInGameTrophy", full = true, glow = { 1, 0.82, 0.35 } },
}
Eye.INGAME_LABELS = {
    auto = "по месту: контурные", autorich = "по месту: цветные", podium = "пьедестал", swords = "скрещённые мечи",
    gate = "врата подземелья", banner = "знамя", shield = "щит со звездой", crown = "корона",
    goldswords = "золотые мечи", portal = "врата с порталом", bannerrich = "алое знамя", trophy = "кубок",
}
Eye.INGAME_AUTO = {
    auto = { dungeon = "gate", battle = "swords", minigame = "podium" },
    autorich = { dungeon = "portal", battle = "goldswords", minigame = "trophy" },
}
Eye.FOUND_FILES = {}

function Eye:AddStyle(key, label, row)
    if type(key) ~= "string" or key == "" or Eye.FILES[key] or type(row) ~= "table" or type(row.file) ~= "string" then return false end
    Eye.FILES[key] = row.file
    Eye.FOUND_FILES[key] = row.found or row.file
    if row.full then
        Eye.FULL[key] = row.glow or { 1, 1, 1 }
        Eye.FOUND_GLOW[key] = row.foundGlow or { 0.45, 1, 0.55 }
    end
    Eye.LABELS[key] = label or key
    table.insert(Eye.STYLES, key)
    return true
end

local FRAMES = 16

local function Settings()
    if not NS.db then return end
    if type(NS.db.queueEye) ~= "table" then NS.db.queueEye = {} end
    local db = NS.db.queueEye
    if db.enabled == nil then db.enabled = true end
    if not Eye.FILES[db.style] then db.style = "arcane" end
    db.color = db.color or "accent"
    db.plate = db.plate or "disc"
    db.speed = db.speed or 12
    db.size = db.size or 100
    db.foundColor = db.foundColor or "green"
    if db.ingame ~= "auto" and db.ingame ~= "autorich" and not Eye.INGAME[db.ingame] then db.ingame = "auto" end
    return db
end
Eye.Settings = Settings

local function Enabled()
    local db = Settings()
    return db and db.enabled ~= false
end

local function Color(o)
    local db = o and o.look or Settings()
    local S = NS.Styling
    local full = Eye.FULL[db.style]
    if full then return full[1], full[2], full[3] end
    if db.color == "class" then
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2, UnitClass("player"))]
        if c then return c.r, c.g, c.b end
    elseif db.color == "gold" then
        return 1, 0.82, 0.3
    elseif db.color == "green" then
        return 0.35, 1, 0.45
    elseif db.color == "white" then
        return 0.95, 0.95, 0.97
    end
    return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
end

local function FoundColor(o)
    local db = o and o.look or Settings()
    local glow = Eye.FULL[db.style] and Eye.FOUND_GLOW[db.style]
    if glow then return glow[1], glow[2], glow[3] end
    if db.foundColor == "gold" then return 1, 0.82, 0.3 end
    if db.foundColor == "white" then return 1, 1, 1 end
    if db.foundColor == "accent" then
        local S = NS.Styling
        return S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]
    end
    return 0.4, 1, 0.5
end

local function SetFrame(texture, index)
    local column = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    texture:SetTexCoord(column / 4, (column + 1) / 4, row / 4, (row + 1) / 4)
end

function Eye:Build(owner, onOwner)
    local S = NS.Styling
    local o = CreateFrame("Frame", nil, owner)
    o:SetPoint("CENTER", owner, "CENTER", 0, 0)
    o:SetSize(32, 32)
    local host = onOwner and owner or o

    o.glow = host:CreateTexture(nil, "BACKGROUND")
    o.glow:SetPoint("CENTER", o, "CENTER", 0, 0)
    o.glow:SetTexture(S.Media("Glow"))
    o.glow:SetBlendMode("ADD")

    o.plate = host:CreateTexture(nil, "BACKGROUND", nil, 1)
    o.plate:SetPoint("CENTER", o, "CENTER", 0, 0)
    o.plate:SetTexture(S.Media("SoftDisc"))

    o.ring = host:CreateTexture(nil, "BORDER")
    o.ring:SetPoint("CENTER", o, "CENTER", 0, 0)
    o.ring:SetTexture(S.Media("PortraitRing"))

    o.icon = host:CreateTexture(nil, "ARTWORK")
    o.icon:SetPoint("CENTER", o, "CENTER", 0, 0)

    o.frame, o.clock, o.pulse = 1, 0, 0
    return o
end

function Eye:Paint(o, size)
    local db = Settings()
    local S = NS.Styling
    o.look = {
        style = db.style, color = db.color, foundColor = db.foundColor, speed = db.speed, ingame = db.ingame,
    }
    local r, g, b = Color(o)
    size = size * (db.size or 100) / 100
    o:SetSize(size, size)
    o.sheet = nil
    o.baseSize = size
    self:Sheet(o, o.found, o.ingame)
    if not o.ingame then SetFrame(o.icon, o.frame or 1) end
    o.plate:SetSize(size * 1.25, size * 1.25)
    o.plate:SetVertexColor(0.02, 0.022, 0.03, 0.92)
    o.plate:SetShown(db.plate == "disc")
    o.ring:SetSize(size * 1.12, size * 1.12)
    o.ring:SetShown(db.plate ~= "none")
    o.glow:SetSize(size * 1.9, size * 1.9)
    o.glow:SetVertexColor(r, g, b, 0)
end

local function InGameRow(o)
    local db = o.look or Settings()
    local key = db.ingame or "auto"
    local auto = Eye.INGAME_AUTO[key]
    if auto then key = auto[o.kind or Eye.ingameKind or "dungeon"] or auto.dungeon end
    return Eye.INGAME[key] or Eye.INGAME.podium
end
Eye.InGameRow = InGameRow

function Eye:Sheet(o, found, ingame)
    local db = o.look or Settings()
    local key = db.style .. (ingame and (":ingame:" .. InGameRow(o).file) or found and ":found" or "")
    if o.sheet == key then return end
    o.sheet = key
    o.found = found
    o.ingame = ingame
    local base = o.baseSize or 32
    local row = ingame and InGameRow(o)
    local scale = ingame and (row.full and 0.82 or 0.7) or (Eye.FULL[db.style] and 1.05 or 0.78)
    o.icon:SetSize(base * scale, base * scale)
    if ingame then
        o.icon:SetTexture(NS.Styling.Media(row.file))
        o.icon:SetTexCoord(0, 1, 0, 1)
        local r, g, b = Color(o)
        if row.full then
            o.icon:SetVertexColor(1, 1, 1, 1)
            r, g, b = row.glow[1], row.glow[2], row.glow[3]
        else
            o.icon:SetVertexColor(r, g, b, 1)
        end
        o.ring:SetVertexColor(r * 0.8, g * 0.8, b * 0.8, 0.95)
        return
    end
    local file = Eye.FILES[db.style]
    if found then file = Eye.FOUND_FILES[db.style] or (file .. "Found") end
    o.icon:SetTexture(NS.Styling.Media(file))
    local r, g, b
    if Eye.FULL[db.style] then
        r, g, b = 1, 1, 1
    elseif found then
        r, g, b = FoundColor(o)
    else
        r, g, b = Color(o)
    end
    o.icon:SetVertexColor(r, g, b, 1)
    local rr, rg, rb = Color(o)
    if found then rr, rg, rb = FoundColor(o) end
    o.ring:SetVertexColor(rr * 0.8, rg * 0.8, rb * 0.8, 0.95)
    o.frame = 1
    SetFrame(o.icon, 1)
end

function Eye:Animate(o, elapsed, state)
    local db = o.look or Settings()
    self:Sheet(o, state == "found", state == "ingame")
    local r, g, b = Color(o)
    if state == "found" then r, g, b = FoundColor(o) end
    if state == "ingame" then
        local row = InGameRow(o)
        if row.full then r, g, b = row.glow[1], row.glow[2], row.glow[3] end
        o.pulse = (o.pulse or 0) + elapsed * 0.9
        local glow = 0.1 + 0.12 * (0.5 + 0.5 * math.sin(o.pulse))
        o.glow:SetVertexColor(r, g, b, o.hover and 0.45 or glow)
        return
    end
    if state == "idle" then
        if o.frame ~= 1 then
            o.frame = 1
            SetFrame(o.icon, 1)
        end
        o.glow:SetVertexColor(r, g, b, o.hover and 0.35 or 0)
        return
    end
    local fps = (db.speed or 12) * (state == "found" and 1.25 or 1)
    o.clock = (o.clock or 0) + elapsed
    local step = 1 / math.max(fps, 1)
    if o.clock >= step then
        local advance = math.floor(o.clock / step)
        o.clock = o.clock - advance * step
        o.frame = ((o.frame or 1) - 1 + advance) % FRAMES + 1
        SetFrame(o.icon, o.frame)
    end
    o.pulse = (o.pulse or 0) + elapsed * (state == "found" and 4 or 1.6)
    local wave = 0.5 + 0.5 * math.sin(o.pulse)
    local glow = state == "found" and (0.35 + 0.5 * wave) or (0.12 + 0.18 * wave)
    if o.hover then glow = math.max(glow, 0.45) end
    o.glow:SetVertexColor(r, g, b, glow)
end

local foundCache, foundAt = false, 0

local function Found()
    local now = GetTime()
    if now - foundAt < 0.25 then return foundCache end
    foundAt = now
    local found = false
    if GetLFGMode then
        local ok, mode = pcall(GetLFGMode)
        if ok and mode == "proposal" then found = true end
    end
    if not found and GetBattlefieldStatus then
        for index = 1, (MAX_BATTLEFIELD_QUEUES or 3) do
            local ok, status = pcall(GetBattlefieldStatus, index)
            if ok and status == "confirm" then found = true break end
        end
    end
    if not found then
        for _, name in ipairs({ "LFGListInviteDialog", "LFDDungeonReadyPopup", "MiniGameReadyPopup" }) do
            local frame = _G[name]
            if frame and frame:IsShown() then found = true break end
        end
    end
    foundCache = found
    return found
end

local inGameCache, inGameAt = false, 0

local function CheckInGame()
    if GetLFGMode then
        local ok, mode = pcall(GetLFGMode)
        if ok and (mode == "lfgparty" or mode == "abandonedInDungeon") then return "dungeon" end
    end
    if type(QueueStatus_InActiveMiniGame) == "function" then
        local ok, active = pcall(QueueStatus_InActiveMiniGame)
        if ok and active then return "minigame" end
    end
    if type(QueueStatus_InActiveBattlefield) == "function" then
        local ok, active, scoreboard = pcall(QueueStatus_InActiveBattlefield)
        if ok and active and scoreboard then return "battle" end
    end
    return false
end

local function InGame()
    local now = GetTime()
    if now - inGameAt < 0.25 then return inGameCache end
    inGameAt = now
    inGameCache = CheckInGame()
    if inGameCache then Eye.ingameKind = inGameCache end
    return inGameCache
end

local function State(button)
    local eye = button and button.Eye
    if Found() then return "found" end
    if InGame() then return "ingame" end
    if not eye then return "idle" end
    local anim = eye.currAnim
    if type(anim) == "string" then
        if anim:find("FOUND") then return "found" end
        if anim == "NONE" or anim == "" then return "idle" end
        return "search"
    end
    if eye.GetScript and eye:GetScript("OnUpdate") then return "search" end
    return "idle"
end

function Eye:Apply()
    local button = _G.QueueStatusMinimapButton
    if not button or not Enabled() then return end
    if not self.overlay then
        self.overlay = self:Build(button, true)
        self.overlay:SetScript("OnUpdate", function(o, elapsed)
            Eye:Animate(o, elapsed, State(button))
        end)
        button:HookScript("OnEnter", function() Eye.overlay.hover = true end)
        button:HookScript("OnLeave", function() Eye.overlay.hover = nil end)
    end
    if button.Eye then button.Eye:SetAlpha(0) end
    local border = button.Border or _G.QueueStatusMinimapButtonBorder
    if border then border:SetAlpha(0) end
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
    self:Paint(self.overlay, math.min(button:GetWidth() or 33, button:GetHeight() or 33) * 0.95)
    self.overlay:Show()
end

function Eye:SetOption(field, value)
    local db = Settings()
    if not db then return end
    db[field] = value
    self:Apply()
end

local SAMPLE_STATES = {
    { state = "idle", label = "в очереди" }, { state = "search", label = "поиск" },
    { state = "found", label = "группа найдена" }, { state = "ingame", label = "в игре", kind = "dungeon" },
}
local SAMPLE_INGAME = {
    { state = "ingame", label = "подземелье", kind = "dungeon" }, { state = "ingame", label = "поле боя", kind = "battle" },
    { state = "ingame", label = "мини-игра", kind = "minigame" },
}

function Eye:CreateSample(parent, opts)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(300, 120)
    holder.items = {}
    local list = opts and opts.ingame and SAMPLE_INGAME or SAMPLE_STATES
    local step = 300 / #list
    for index, spec in ipairs(list) do
        local o = self:Build(holder)
        o:ClearAllPoints()
        o:SetPoint("CENTER", holder, "LEFT", step * (index - 0.5), 6)
        o.state, o.kind = spec.state, spec.kind
        local label = holder:CreateFontString(nil, "OVERLAY")
        label:SetFont(NS.FONT, NS.FS(10), "")
        label:SetPoint("TOP", o, "BOTTOM", 0, -14)
        label:SetTextColor(0.75, 0.76, 0.8)
        label:SetText(L[spec.label])
        holder.items[index] = o
    end
    holder:SetScript("OnUpdate", function(self, elapsed)
        for _, o in ipairs(self.items) do Eye:Animate(o, elapsed, o.state) end
    end)
    return holder
end

function Eye:PaintSample(holder)
    if not holder then return end
    for _, o in ipairs(holder.items) do
        o.frame = o.state == "idle" and 1 or o.frame
        self:Paint(o, 44)
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function()
    if not Enabled() then return end
    if NS.After then
        NS.After(1, function() Eye:Apply() end)
    else
        Eye:Apply()
    end
end)
