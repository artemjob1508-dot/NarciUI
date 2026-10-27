local addonName, NS = ...
local L = NS.L

local ActionBars = {}
NS.ActionBars = ActionBars

local WHITE = "Interface\\Buttons\\WHITE8x8"

local BARS = {
    { key = "bar1", slot = 0, prefix = "ActionButton",             count = 12, label = "Панель 1",
      point = "BOTTOM", x = 0, y = 30, perRow = 12 },
    { key = "bar2", page = 6, slot = 1, prefix = "MultiBarBottomLeftButton", count = 12, label = "Панель 2",
      point = "BOTTOM", x = 0, y = 72, perRow = 12 },
    { key = "bar3", page = 5, slot = 2, prefix = "MultiBarBottomRightButton", count = 12, label = "Панель 3",
      point = "BOTTOM", x = 0, y = 114, perRow = 12 },
    { key = "bar4", page = 3, slot = 0, prefix = "MultiBarRightButton",      count = 12, label = "Панель 4",
      point = "RIGHT", x = -6, y = 0, perRow = 1 },
    { key = "bar5", page = 4, slot = 1, prefix = "MultiBarLeftButton",       count = 12, label = "Панель 5",
      point = "RIGHT", x = -48, y = 0, perRow = 1 },
    { key = "bar6", slot = 4, prefix = "NarciSirus_Bar6Button", count = 12, label = "Панель 6",
      point = "BOTTOM", x = 0, y = 156, perRow = 12, custom = true, firstSlot = 73, off = true },
    { key = "bar7", slot = 5, prefix = "NarciSirus_Bar7Button", count = 12, label = "Панель 7",
      point = "BOTTOM", x = 0, y = 198, perRow = 12, custom = true, firstSlot = 85, off = true },
    { key = "stance", slot = 3, prefix = "ShapeshiftButton", count = 10, label = "Панель форм",
      point = "BOTTOM", x = 0, y = 156, perRow = 10, stance = true, special = true },
    { key = "pet", slot = 4, prefix = "PetActionButton", count = 10, label = "Панель питомца",
      point = "BOTTOM", x = 0, y = 174, perRow = 10, pet = true, special = true },
    { key = "bar8", slot = 0, prefix = "NarciSirus_Bar8Button", count = 12, label = "Панель 8",
      point = "LEFT", x = 6, y = 0, perRow = 1, custom = true, firstSlot = 97, off = true },
    { key = "bar9", slot = 1, prefix = "NarciSirus_Bar9Button", count = 12, label = "Панель 9",
      point = "LEFT", x = 48, y = 0, perRow = 1, custom = true, firstSlot = 109, off = true },
}

local BLIZZARD_ART = {
    "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
    "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",
    "MainMenuMaxLevelBar0", "MainMenuMaxLevelBar1", "MainMenuMaxLevelBar2", "MainMenuMaxLevelBar3",
    "SlidingActionBarTexture0", "SlidingActionBarTexture1",
    "BonusActionBarTexture0", "BonusActionBarTexture1",
    "MainMenuXPBarTextureLeftCap", "MainMenuXPBarTextureRightCap",
    "MainMenuXPBarTextureMid", "MainMenuXPBarTextureBackground",
    "ReputationWatchBarTexture0", "ReputationWatchBarTexture1",
    "ReputationWatchBarTexture2", "ReputationWatchBarTexture3",
    "ReputationXPBarTexture0", "ReputationXPBarTexture1",
    "ReputationXPBarTexture2", "ReputationXPBarTexture3",
}

local MICRO_BUTTONS = {
    "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
    "AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
    "GuildMicroButton", "LFDMicroButton", "CollectionsMicroButton",
    "EncounterJournalMicroButton", "StoreMicroButton", "MainMenuMicroButton",
}

local BAG_BUTTONS = {
    "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
    "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton",
}

local holders = {}
local moving = false

local function BlankRange(button)
    local hotkey = button and button.narciHotkey
    if hotkey and hotkey:GetText() == RANGE_INDICATOR then hotkey:SetText("") end
end

local function Style()
    return NS.Styling
end

local function FillSettings()
    if not NS.db then return end

    if not NS.db.actionBars then NS.db.actionBars = {} end

    local db = NS.db.actionBars
    if db.enabled == nil then db.enabled = false end
    if db.showHotKey == nil then db.showHotKey = true end
    if db.showMacroName == nil then db.showMacroName = false end
    if db.stateColors == nil then db.stateColors = true end
    if db.hideBlizzard == nil then db.hideBlizzard = true end
    if db.hideMicro == nil then db.hideMicro = false end
    if db.hideEmpty == nil then db.hideEmpty = false end

    if not db.emptyDefaultChanged then
        db.emptyDefaultChanged = true
        db.hideEmpty = false
    end
    if db.panel == nil then db.panel = true end

    if not db.panelOffDefault then
        db.panelOffDefault = true
        db.panel = false
    end

    if not db.fadeCombatOffDefault then
        db.fadeCombatOffDefault = true
        db.fadeCombat = false
    end
    if db.cooldownText == nil then db.cooldownText = true end

    db.look = db.look or {}
    local look = db.look
    look.border = look.border or "thin"
    look.borderColor = look.borderColor or "dark"
    look.ratio = look.ratio or 1
    if look.zoom == nil then look.zoom = false end
    if look.gloss == nil then look.gloss = true end
    look.hotkeySize = look.hotkeySize or 10
    look.hotkeyPos = look.hotkeyPos or "TOPRIGHT"
    look.countSize = look.countSize or 11
    look.groundAlpha = look.groundAlpha or 1
    look.style = look.style or "flat"
    look.cdSize = look.cdSize or 0
    if look.cdColors == nil then look.cdColors = true end
    look.hotkeyColor = look.hotkeyColor or "white"
    look.cdDim = look.cdDim or 100

    db.micro = db.micro or {}
    if db.micro.enabled == nil then db.micro.enabled = true end
    if db.micro.bags == nil then db.micro.bags = false end

    if not db.micro.bagsDefaultChanged then
        db.micro.bagsDefaultChanged = true
        db.micro.bags = false
    end
    db.micro.size = db.micro.size or 22
    db.micro.perRow = db.micro.perRow or 6
    if db.micro.dock == nil then db.micro.dock = "chat" end

    if not db.micro.dockChatDefault then
        db.micro.dockChatDefault = true
        db.micro.dock = "chat"
    end
    db.micro.spacing = db.micro.spacing or 2
    db.micro.borderColor = db.micro.borderColor or "dark"
    if db.micro.panel == nil then db.micro.panel = false end
    if db.micro.mouseover == nil then db.micro.mouseover = false end
    db.micro.alpha = db.micro.alpha or 1
    db.micro.style = db.micro.style or "tiles"
    db.micro.point = db.micro.point or "BOTTOMLEFT"
    db.micro.x = db.micro.x or 12
    db.micro.y = db.micro.y or 12
    db.size = db.size or 32
    db.spacing = db.spacing or 4
    db.bars = db.bars or {}

    for _, preset in ipairs(BARS) do
        local store = db.bars[preset.key] or {}
        if store.enabled == nil then store.enabled = not preset.off end
        store.point = store.point or preset.point
        store.x = store.x or preset.x
        store.y = store.y or preset.y
        store.perRow = store.perRow or preset.perRow
        store.buttons = store.buttons or preset.count
        store.growth = store.growth or "RIGHT"
        store.alpha = store.alpha or 1

        if not store.sideEmptyDefault then
            store.sideEmptyDefault = true
            store.hideEmpty = preset.point == "RIGHT" or preset.point == "LEFT"
        end

        if not store.sideEmptyRestored then
            store.sideEmptyRestored = true
            store.hideEmpty = false
        end

        if store.mouseover == nil then store.mouseover = false end
        if store.combatOnly == nil then store.combatOnly = false end
        store.size = store.size or 0
        store.spacing = store.spacing or -1

        db.bars[preset.key] = store
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.actionBars
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local HOTKEY_POINTS = {
    TOPRIGHT = { "TOPRIGHT", -2, -2, "RIGHT" },
    TOPLEFT = { "TOPLEFT", 2, -2, "LEFT" },
    BOTTOMLEFT = { "BOTTOMLEFT", 2, 2, "LEFT" },
}

local function Look()
    local db = Settings()
    return db and db.look
end

local KEY_SHORT = {
    { "Средняя кнопка мыши", "M3" }, { "Middle Mouse", "M3" },
    { "Кнопка мыши (%d+)", "M%1" }, { "Mouse Button (%d+)", "M%1" },
    { "Прокрутка вверх", "WU" }, { "Mouse Wheel Up", "WU" },
    { "Прокрутка вниз", "WD" }, { "Mouse Wheel Down", "WD" },
    { "([^%s%-]+) %(цифр%. кл%.%)", "N%1" }, { "Num Pad ([^%s%-]+)", "N%1" },
    { "Пробел", "Sp" }, { "Spacebar", "Sp" },
    { "Page Up", "PU" }, { "Page Down", "PD" },
    { "Insert", "Ins" }, { "Delete", "Del" }, { "Home", "Hm" },
    { "SHIFT%-", "S" }, { "CTRL%-", "C" }, { "ALT%-", "A" },
}

local function BarOf(button)
    local name = button and button:GetName()
    if not name then return end
    for _, preset in ipairs(BARS) do
        if name:sub(1, #preset.prefix) == preset.prefix and name:sub(#preset.prefix + 1):match("^%d+$") then
            return preset
        end
    end
end

local function ShortKey(button)
    local hotkey = button and button.narciHotkey
    local db = Settings()
    if not hotkey or not db then return end
    local text = hotkey:GetText()
    if text and text ~= "" and text ~= RANGE_INDICATOR then
        if db.look.hotkeyShort then
            if text ~= button.narciKeyShort then
                local short = text
                for _, rule in ipairs(KEY_SHORT) do short = short:gsub(rule[1], rule[2]) end
                short = short:gsub("([sSaAcC])%-", string.upper)
                button.narciKeyFull, button.narciKeyShort = text, short
                if short ~= text then hotkey:SetText(short) end
            end
        elseif text == button.narciKeyShort and button.narciKeyFull then
            hotkey:SetText(button.narciKeyFull)
            button.narciKeyShort = nil
        end
    end
    local preset = BarOf(button)
    local store = preset and db.bars and db.bars[preset.key]
    if not db.showHotKey or (store and store.hideKeys) then hotkey:Hide() end
end

local BUTTON_STYLES = { flat = true, classic = true, glow = true, bevel = true, pixel = true, neon = true, shadow = true, dark = true }
local QUICKSLOT = "Interface\\Buttons\\UI-Quickslot2"

local function ButtonStyle()
    local look = Look()
    return look and BUTTON_STYLES[look.style] and look.style or "flat"
end

local function ButtonGlow(button)
    if button.narciHalo then return button.narciHalo end
    button.narciHalo = NS.Styling.GlowPieces(button, 5, "BACKGROUND", "ADD")
    return button.narciHalo
end

local function PaintHalo(halo, r, g, b, a)
    for _, texture in ipairs(halo) do
        texture:SetVertexColor(r, g, b, a)
    end
end

function ActionBars:PaintEdges(button, hover)
    local edges = button.narciEdges
    if not edges then return end

    local S = Style()
    local style = ButtonStyle()

    if hover then
        for _, line in ipairs(edges) do
            line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        end
    elseif style == "bevel" then
        edges[1]:SetVertexColor(1, 1, 1, 0.28)
        edges[3]:SetVertexColor(1, 1, 1, 0.28)
        edges[2]:SetVertexColor(0, 0, 0, 0.95)
        edges[4]:SetVertexColor(0, 0, 0, 0.95)
    elseif style == "pixel" or style == "dark" then
        for _, line in ipairs(edges) do line:SetVertexColor(0, 0, 0, 1) end
    elseif style == "neon" and not NS.Look:Color("actionbars", "border") then
        for _, line in ipairs(edges) do line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1) end
    else
        local r, g, b, a = self:EdgeColor()
        for _, line in ipairs(edges) do line:SetVertexColor(r, g, b, a) end
    end

    if button.narciHalo then
        local S2 = Style()
        PaintHalo(button.narciHalo, S2.ACCENT[1], S2.ACCENT[2], S2.ACCENT[3], hover and 0.75 or 0.3)
    end
end

function ActionBars:EdgeColor()
    local look = Look()
    local S = Style()

    local lr, lg, lb = NS.Look:Color("actionbars", "border")
    if lr then return lr, lg, lb, 1 end

    if look.borderColor == "accent" then
        return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9
    end

    if look.borderColor == "class" then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b, 0.9 end
    end

    return S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95
end

function ActionBars:StyleButton(button)
    if not button or not button.narciBar then return end

    local db = Settings()
    local look = db.look
    local r, g, b, a = self:EdgeColor()

    local style = ButtonStyle()
    local thick = (look.border == "thick" or style == "bevel" or style == "dark") and 2 or 1
    local hidden = look.border == "none" or style == "classic" or style == "glow" or style == "shadow"
    local edges = button.narciEdges

    for _, line in ipairs(edges) do
        line:SetVertexColor(r, g, b, a)
        line:SetShown(not hidden)
    end
    self:PaintEdges(button, false)

    local halo = ButtonGlow(button)
    for _, texture in ipairs(halo) do texture:SetShown(style == "glow" or style == "neon") end

    if style == "shadow" and not button.narciSoftShadow then
        button.narciSoftShadow = NS.Styling.CreateSoftShadow(button, 5, 0.75)
    end
    if button.narciSoftShadow then button.narciSoftShadow:SetShown(style == "shadow") end

    if not button.narciQuickslot then
        local slot = button:CreateTexture(nil, "OVERLAY")
        slot:SetTexture(QUICKSLOT)
        button.narciQuickslot = slot
    end
    local width = button:GetWidth() or 36
    local frameSize = width * 66 / 36
    button.narciQuickslot:ClearAllPoints()
    button.narciQuickslot:SetSize(frameSize, frameSize * (button:GetHeight() or width) / width)
    button.narciQuickslot:SetPoint("CENTER", button, "CENTER", 0, -width / 36)
    button.narciQuickslot:SetShown(style == "classic")

    if button.narciInner == nil then
        local inner = CreateFrame("Frame", nil, button)
        inner:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        inner:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        inner:SetFrameLevel(button:GetFrameLevel() + 1)
        button.narciInner = NS.Styling.CreateEdges(inner, "OVERLAY", 0.32, 0.33, 0.36, 1)
    end
    for _, line in ipairs(button.narciInner) do line:SetShown(style == "pixel") end

    edges[1]:SetHeight(thick)
    edges[2]:SetHeight(thick)
    edges[3]:SetWidth(thick)
    edges[4]:SetWidth(thick)

    local icon = button.narciIcon

    if icon then
        local inset = hidden and 0 or thick
        if style == "pixel" then inset = 2 end
        local half = style == "classic" and 0.5 or look.zoom and 0.34 or 0.42
        local ratio = look.ratio or 1

        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
        icon:SetTexCoord(0.5 - half, 0.5 + half, 0.5 - half * ratio, 0.5 + half * ratio)
    end

    if button.narciGloss then
        local height = button:GetHeight() or 32
        button.narciGloss:SetHeight(math.max(height * 0.5, 8))
        button.narciShade:SetHeight(math.max(height * 0.4, 6))
        button.narciGloss:SetShown(look.gloss and style ~= "classic")
        button.narciShade:SetShown((look.gloss or style == "bevel") and style ~= "classic")
    end

    if button.narciGround then
        button.narciGround:SetVertexColor(0.02, 0.022, 0.03, style == "classic" and 0 or look.groundAlpha)
    end

    local hotkey = button.narciHotkey

    if hotkey then
        local place = HOTKEY_POINTS[look.hotkeyPos] or HOTKEY_POINTS.TOPRIGHT

        hotkey:ClearAllPoints()
        hotkey:SetPoint(place[1], button, place[1], place[2], place[3])
        hotkey:SetJustifyH(place[4])
        NS.LSetFont(hotkey, "actionbars", look.hotkeySize, "OUTLINE")
        BlankRange(button)
        hotkey:SetShown(db.showHotKey)
        ShortKey(button)

        local S = Style()
        local tr, tg, tb = NS.Look:Color("actionbars", "text")
        if tr then
            hotkey:SetTextColor(tr, tg, tb)
        elseif look.hotkeyColor == "accent" then
            hotkey:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        elseif look.hotkeyColor == "gray" then
            hotkey:SetTextColor(0.62, 0.64, 0.68)
        elseif look.hotkeyColor == "gold" then
            hotkey:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        else
            hotkey:SetTextColor(0.95, 0.95, 0.97)
        end
        button.narciHotkeyColored = true
    end

    local cooldown = button.cooldown or _G[(button:GetName() or "") .. "Cooldown"]
    if cooldown then cooldown:SetAlpha((look.cdDim or 100) / 100) end

    if button.narciCount then
        NS.LSetFont(button.narciCount, "actionbars", look.countSize, "OUTLINE")
        local S = Style()
        local mode = look.countColor or "gold"
        if mode == "white" then
            button.narciCount:SetTextColor(0.95, 0.95, 0.97)
        elseif mode == "accent" then
            button.narciCount:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            button.narciCount:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        end
    end

    if button.narciMacro then
        button.narciMacro:SetShown(db.showMacroName)
        if look.macroSize then NS.LSetFont(button.narciMacro, "actionbars", look.macroSize, "OUTLINE") end
    end

    local highlight = look.hoverAlpha and button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then
        local S = Style()
        highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], look.hoverAlpha / 100)
    end
end

function ActionBars:RestyleAll()
    for _, button in ipairs(self.skinned or {}) do
        self:StyleButton(button)
    end
end

function ActionBars:SetLook(field, value)
    local db = Settings()
    if not db then return end

    db.look[field] = value

    if field == "ratio" then
        self:Apply()
    end

    self:RestyleAll()
end

function ActionBars:SkinButton(name)
    local button = _G[name]
    if not button or button.narciBar then return end
    button.narciBar = true

    if not self.rangeHooked and type(_G.ActionButton_UpdateHotkeys) == "function" then
        self.rangeHooked = true
        hooksecurefunc("ActionButton_UpdateHotkeys", function(button)
            BlankRange(button)
            ShortKey(button)
        end)
    end

    local S = Style()

    local icon = _G[name .. "Icon"]
    local normal = _G[name .. "NormalTexture"] or (button.GetNormalTexture and button:GetNormalTexture())
    local hotkey = _G[name .. "HotKey"]
    local count = _G[name .. "Count"]
    local macro = _G[name .. "Name"]
    local border = _G[name .. "Border"]
    local flash = _G[name .. "Flash"]
    local cooldown = _G[name .. "Cooldown"]

    if normal then normal:SetAlpha(0) end

    if button.SetNormalTexture then
        hooksecurefunc(button, "SetNormalTexture", function(self)
            local region = self:GetNormalTexture()
            if region then region:SetAlpha(0) end
        end)
    end

    if icon then icon:SetDrawLayer("BORDER") end

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)

    local gloss = button:CreateTexture(nil, "ARTWORK")
    gloss:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    gloss:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    gloss:SetHeight(math.max(button:GetHeight() * 0.5, 8))
    gloss:SetTexture(WHITE)
    gloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.16)

    local shade = button:CreateTexture(nil, "ARTWORK")
    shade:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
    shade:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    shade:SetHeight(math.max(button:GetHeight() * 0.4, 6))
    shade:SetTexture(WHITE)
    shade:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.35, 0, 0, 0, 0)

    button.narciEdges = S.CreateEdges(button, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
    button.narciGround = ground
    button.narciGloss = gloss
    button.narciShade = shade
    button.narciIcon = icon
    button.narciHotkey = hotkey
    button.narciCount = count
    button.narciMacro = macro

    if button.SetHighlightTexture then
        button:SetHighlightTexture(WHITE)
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetAlpha(1)
            highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.25)
        end
    end

    if button.SetCheckedTexture then
        button:SetCheckedTexture(WHITE)
        local checked = button:GetCheckedTexture()
        if checked then
            checked:SetAlpha(1)
            checked:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.35)
        end
    end

    if border then border:SetAlpha(0) end
    if flash then flash:SetTexture(WHITE) end

    if NS.DFUI then
        border = border or button.Border
        if border then
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            border:SetTexCoord(0, 1, 0, 1)
            border:SetBlendMode("ADD")
            border:ClearAllPoints()
            border:SetPoint("TOPLEFT", button, "TOPLEFT", -13, 13)
            border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 13, -13)
        end
        for _, key in ipairs({ "Flash", "NewActionTexture", "SpellHighlightTexture", "QuickKeybindHighlightTexture" }) do
            local region = button[key]
            if region then
                region:ClearAllPoints()
                region:SetAllPoints(button)
            end
        end
        for _, key in ipairs({ "SlotBackground", "SlotArt" }) do
            local region = button[key]
            if region then region:SetAlpha(0) end
        end
        for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetCheckedTexture" }) do
            local region = button[getter] and button[getter](button)
            if region then
                region:ClearAllPoints()
                region:SetAllPoints(button)
            end
        end
        local function Pushed(self)
            local region = self:GetPushedTexture()
            if not region then return end
            region:SetTexture(WHITE)
            region:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)
            region:ClearAllPoints()
            region:SetAllPoints(self)
        end
        Pushed(button)
        if button.SetPushedAtlas then hooksecurefunc(button, "SetPushedAtlas", Pushed) end
        if button.SetNormalAtlas then
            hooksecurefunc(button, "SetNormalAtlas", function(self)
                local region = self:GetNormalTexture()
                if region then region:SetAlpha(0) end
            end)
        end
    end

    if hotkey then
        hotkey:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        BlankRange(button)
    end

    if count then
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        count:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    end

    if macro then
        NS.LSetFont(macro, "actionbars", NS.FS(9), "OUTLINE")
        macro:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if cooldown then
        cooldown:SetAllPoints(button)
    end

    button:HookScript("OnEnter", function(self) ActionBars:PaintEdges(self, true) end)
    button:HookScript("OnLeave", function(self) ActionBars:PaintEdges(self, false) end)

    self.skinned = self.skinned or {}
    if not button.narciSample then self.skinned[#self.skinned + 1] = button end

    self:StyleButton(button)
end

local RANGE_COLOR = { 0.85, 0.30, 0.30 }
local POWER_COLOR = { 0.35, 0.45, 0.95 }
local UNUSABLE_COLOR = { 0.35, 0.35, 0.35 }

ActionBars.STATE_COLORS = { rangeColor = RANGE_COLOR, powerColor = POWER_COLOR, unusableColor = UNUSABLE_COLOR }

local function ActionSlot(button)
    if button.action then return button.action end

    if type(_G.ActionButton_CalculateAction) == "function" then
        local ok, slot = pcall(_G.ActionButton_CalculateAction, button)
        if ok then return slot end
    end
end

function ActionBars:PaintEmpty(button)
    if not button then return end

    local db = Settings()

    if not db or not db.hideEmpty then
        button:SetAlpha(1)
        if button.narciBlank then
            button.narciBlank = nil
            if not InCombatLockdown() then button:EnableMouse(true) end
        end
        return
    end

    local slot = ActionSlot(button)
    local blank = not (slot and HasAction(slot))

    if blank == button.narciBlank then return end
    button.narciBlank = blank

    button:SetAlpha(blank and 0 or 1)
    if not InCombatLockdown() then button:EnableMouse(not blank) end
end

function ActionBars:PaintState(button)
    if not button or not button.action then return end

    local db = Settings()
    if not db or not db.stateColors then return end

    local icon = button.narciIcon
    if not icon then
        local name = button:GetName()
        icon = name and _G[name .. "Icon"]
    end
    if not icon then return end

    local usable, noPower = IsUsableAction(button.action)
    local inRange = IsActionInRange(button.action)

    local color
    if inRange == false then
        color = db.rangeColor or RANGE_COLOR
    elseif noPower then
        color = db.powerColor or POWER_COLOR
    elseif not usable then
        color = db.unusableColor or UNUSABLE_COLOR
    end
    if color then
        icon:SetVertexColor(color[1], color[2], color[3])
    else
        icon:SetVertexColor(1, 1, 1)
    end
end

function ActionBars:HookState()
    if self.stateHooked then return end
    self.stateHooked = true

    if type(_G.ActionButton_UpdateUsable) == "function" then
        hooksecurefunc("ActionButton_UpdateUsable", function(button)
            ActionBars:PaintState(button)
        end)
    end

    local ticker = CreateFrame("Frame")
    local elapsed = 0

    ticker:SetScript("OnUpdate", function(self, step)
        elapsed = elapsed + step
        if elapsed < 0.2 then return end
        elapsed = 0

        if not Enabled() then return end

        local db = Settings()
        if not db.stateColors and not db.hideEmpty then return end

        local live = ActionBars.live
        if not live then return end

        local state, empty = db.stateColors, db.hideEmpty

        for index = 1, #live do
            local button = live[index]
            if button:IsVisible() then
                if state then ActionBars:PaintState(button) end
                if empty then ActionBars:PaintEmpty(button) end
            end
        end
    end)
end

function ActionBars:KeybindMode()
    if InCombatLockdown() then
        NS.Print("в бою привязки не меняются")
        return
    end

    if self.binding then
        self:StopKeybind()
        return
    end

    self.binding = true
    self.bindOverlays = self.bindOverlays or {}

    local S = Style()

    for _, preset in ipairs(BARS) do
        for index = 1, preset.count do
            local name = preset.prefix .. index
            local button = _G[name]

            if button and button:IsShown() then
                local overlay = self.bindOverlays[name]

                if not overlay then
                    overlay = CreateFrame("Button", nil, button)
                    overlay:SetAllPoints(button)
                    overlay:SetFrameStrata("DIALOG")
                    overlay:EnableKeyboard(false)
                    overlay:EnableMouse(true)
                    overlay:SetScript("OnEnter", function(self) self:EnableKeyboard(true) end)
                    overlay:SetScript("OnLeave", function(self) self:EnableKeyboard(false) end)
                    overlay:RegisterForClicks("AnyDown")

                    local wash = overlay:CreateTexture(nil, "BACKGROUND")
                    wash:SetAllPoints(overlay)
                    wash:SetTexture(WHITE)
                    wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35)

                    overlay.target = name

                    overlay:SetScript("OnKeyDown", function(self, key)
                        ActionBars:Bind(self.target, key)
                    end)

                    overlay:SetScript("OnClick", function(self, button)
                        local key = button == "LeftButton" and "BUTTON1"
                            or button == "RightButton" and "BUTTON2"
                            or button == "MiddleButton" and "BUTTON3"
                            or button:upper()
                        ActionBars:Bind(self.target, key)
                    end)

                    self.bindOverlays[name] = overlay
                end

                overlay:Show()
            end
        end
    end

    NS.Print("режим привязок: наведите на кнопку и нажмите клавишу, ESC чтобы выйти")
end

function ActionBars:Bind(target, key)
    if key == "ESCAPE" then
        self:StopKeybind()
        return
    end

    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
        or key == "LALT" or key == "RALT" or key == "UNKNOWN" then
        return
    end

    local prefix = ""
    if IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    if IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsAltKeyDown() then prefix = prefix .. "ALT-" end

    local combo = prefix .. key

    if InCombatLockdown() then
        NS.Print("в бою привязки не меняются")
        return
    end

    SetBinding(combo, "CLICK " .. target .. ":LeftButton")
    SaveBindings(GetCurrentBindingSet())

    NS.Print(combo .. " -> " .. target)
end

function ActionBars:StopKeybind()
    self.binding = nil

    for _, overlay in pairs(self.bindOverlays or {}) do
        overlay:Hide()
    end

    NS.Print("режим привязок выключен")
end

function ActionBars:HideBlizzardArt()
    for _, name in ipairs(BLIZZARD_ART) do
        local region = _G[name]
        if region and region.SetAlpha then region:SetAlpha(0) end
    end

    local page = _G.MainMenuBarPageNumber
    if page then
        NS.LSetFont(page, "actionbars", NS.FS(10), "OUTLINE")
        page:SetTextColor(Style().TEXT_DIM[1], Style().TEXT_DIM[2], Style().TEXT_DIM[3])
    end

    for _, name in ipairs({ "ActionBarUpButton", "ActionBarDownButton" }) do
        local button = _G[name]
        if button then
            button:SetAlpha(0.35)
            button:SetSize(18, 18)
        end
    end

    if _G.MainMenuBar then _G.MainMenuBar:EnableMouse(false) end

    local db = Settings()

    if db.hideBlizzard then
        local silence = { "MainMenuBarArtFrame", "MainMenuExpBar",
            "ReputationWatchBar", "MainMenuBarMaxLevelBar", "MainMenuBarPerformanceBarFrame",
            "MainMenuBarVehicleLeaveButton", "ShapeshiftBarFrame" }
        if NS.DFUI then
            for _, name in ipairs({ "MainMenuBar", "StatusTrackingBarManager", "BagsBar",
                "MicroButtonAndBagsBar", "MicroMenuContainer" }) do
                silence[#silence + 1] = name
            end
        end
        for _, name in ipairs(silence) do
            local frame = _G[name]

            if frame and not frame.narciSilenced then
                frame.narciSilenced = true
                frame:SetAlpha(0)
                if frame.EnableMouse then frame:EnableMouse(false) end
            end
        end
    end

    self:LayoutMicro()
end

local MICRO_CROP = { 0.17, 0.87, 0.5, 0.908 }

local MICRO_ICONS = {
    CharacterMicroButton = { "MicroCharacter", "FullCharacter" },
    SpellbookMicroButton = { "ToolSpells", "FullSpellbook" },
    TalentMicroButton = { "ToolTalents", "FullTalents" },
    AchievementMicroButton = { "MicroAchievement", "FullAchievement" },
    QuestLogMicroButton = { "MicroQuest", "FullQuest" },
    SocialsMicroButton = { "MicroSocial", "FullSocial" },
    GuildMicroButton = { "MicroGuild", "FullGuild" },
    LFDMicroButton = { "MicroLFD", "FullLFD" },
    CollectionsMicroButton = { "MicroCollections", "FullCollections" },
    EncounterJournalMicroButton = { "MicroJournal", "FullJournal" },
    StoreMicroButton = { "MicroStore", "FullStore" },
    MainMenuMicroButton = { "MicroMenu", "FullMenu" },
}

local MICRO_SETS = {}
local MICRO_SET_LIST = {}
local MICRO_BUILTIN = { neon = "Neon", gilded = "Gilded", gem = "Gem", stone = "Stone", pixel = "Pixel" }
ActionBars.MICRO_BUILTIN_ORDER = { "neon", "gilded", "gem", "stone", "pixel" }
ActionBars.MICRO_BUILTIN_LABELS = { neon = "неон", gilded = "золото", gem = "самоцветы", stone = "камень", pixel = "пиксель-арт" }

function ActionBars:AddMicroIcons(key, label, paths)
    if type(key) ~= "string" or key == "minimal" or key == "full" or MICRO_BUILTIN[key] or MICRO_SETS[key] or type(paths) ~= "table" then return false end
    local set = {}
    for name, path in pairs(paths) do
        local button = type(name) == "string" and (name:find("MicroButton$") and name or name .. "MicroButton")
        if button and MICRO_ICONS[button] and type(path) == "string" then set[button] = path end
    end
    if not next(set) then return false end
    MICRO_SETS[key] = set
    table.insert(MICRO_SET_LIST, { key = key, label = label or key })
    return true
end

ActionBars.MICRO_ORDER = {
    "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "AchievementMicroButton",
    "QuestLogMicroButton", "SocialsMicroButton", "GuildMicroButton", "LFDMicroButton",
    "CollectionsMicroButton", "EncounterJournalMicroButton", "StoreMicroButton", "MainMenuMicroButton",
}
ActionBars.MICRO_EXTRA = {}

function ActionBars:AddMicroButton(def)
    if type(def) ~= "table" or type(def.key) ~= "string" or type(def.icon) ~= "string" then return false end
    local name = "NarciSirus_Micro" .. (def.key:gsub("[^%w_]", ""))
    if _G[name] or MICRO_ICONS[name] then return false end
    local button = CreateFrame("Button", name, UIParent)
    button:SetSize(28, 28)
    button:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
    button:GetNormalTexture():SetAlpha(0)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", function(self, mouse)
        if type(def.onClick) ~= "function" then return end
        local ok, err = pcall(def.onClick, self, mouse)
        if not ok and NS.Print then NS.Print(tostring(def.label or def.key) .. ": " .. tostring(err)) end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(def.label or def.key, 1, 1, 1)
        if def.tooltip then GameTooltip:AddLine(def.tooltip, 0.8, 0.8, 0.85, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MICRO_ICONS[name] = { def.icon, def.full or def.icon, plugin = true }
    table.insert(MICRO_BUTTONS, name)
    table.insert(self.MICRO_ORDER, name)
    table.insert(self.MICRO_EXTRA, { name = name, label = def.label or def.key })
    return true
end

function ActionBars:MicroIconPath(setKey, buttonName)
    local icons = MICRO_ICONS[buttonName]
    if not icons then return end
    local set = MICRO_SETS[setKey or ""]
    if set and set[buttonName] then return set[buttonName], true end
    local builtin = MICRO_BUILTIN[setKey or ""]
    if builtin then return Style().Media(icons.plugin and icons[2] or builtin .. icons[2]:sub(5)), true end
    if setKey == "full" then return Style().Media(icons[2]), true end
    return Style().Media(icons[1]), false
end

function ActionBars:MicroIconSets()
    return MICRO_SET_LIST
end

local function FullMicroIcons()
    local db = Settings()
    return db and db.micro and db.micro.icons == "full"
end

local MICRO_TINTS = {
    white = { 1, 1, 1 },
    gold = { 1, 0.82, 0.35 },
    silver = { 0.78, 0.82, 0.9 },
}

local function MicroOption(key, fallback)
    local db = Settings()
    local micro = db and db.micro
    local value = micro and micro[key]
    if value == nil then return fallback end
    return value
end

local function MicroTint()
    local key = MicroOption("iconColor", "theme")
    if key == "class" then
        local _, class = UnitClass("player")
        local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then return c.r, c.g, c.b end
    end
    local c = MICRO_TINTS[key]
    if c then return c[1], c[2], c[3] end
    local S = Style()
    return S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3]
end

local function PlaceMicroIcon(button, pushed)
    local icon = button.narciIcon
    local base = button.narciIconFull and 2 or 4
    local w = button:GetWidth() or 28
    local scale = MicroOption("iconScale", 100) / 100
    local inset = math.floor(base + (w - 2 * base) * (1 - scale) / 2 + 0.5)
    local shift = pushed and 1 or 0
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset + shift, -inset - shift)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset + shift, inset - shift)
end

local function PaintMicroIcon(button)
    local icon = button.narciIcon
    if not icon then return end
    local S = Style()
    local enabled = not button.IsEnabled or button:IsEnabled()
    if button.narciIconFull then
        if icon.SetDesaturated then icon:SetDesaturated(not enabled) end
        icon:SetVertexColor(1, 1, 1, not enabled and 0.5 or (button.narciOver and 1 or 0.92))
    elseif not enabled then
        icon:SetVertexColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3], 0.5)
    elseif button.narciOver and MicroOption("hoverAccent", true) then
        icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    else
        local r, g, b = MicroTint()
        icon:SetVertexColor(r, g, b, button.narciOver and 1 or 0.9)
    end
end

function ActionBars:SkinMicro(button)
    if button.narciMicro then return end
    button.narciMicro = true

    local S = Style()

    button:SetHitRectInsets(0, 0, 0, 0)

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.02, 0.022, 0.03, 1)

    local edges = {}

    for index = 1, 4 do
        local line = button:CreateTexture(nil, "OVERLAY")
        line:SetTexture(WHITE)
        line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
        edges[index] = line
    end

    edges[1]:SetHeight(1)
    edges[1]:SetPoint("TOPLEFT", button, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    edges[2]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
    edges[2]:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
    edges[3]:SetWidth(1)
    edges[3]:SetPoint("TOPLEFT", button, "TOPLEFT")
    edges[3]:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
    edges[4]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    edges[4]:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")

    button.narciEdges = edges
    button.narciGround = ground

    local under = button:CreateTexture(nil, "OVERLAY")
    under:SetTexture(WHITE)
    under:SetHeight(2)
    under:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 1)
    under:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 1)
    under:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    under:Hide()
    button.narciUnder = under

    local wash = button:CreateTexture(nil, "OVERLAY")
    wash:SetTexture(WHITE)
    wash:SetBlendMode("ADD")
    wash:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    wash:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    wash:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28)
    wash:Hide()
    button.narciWash = wash

    if button.Flash then button.Flash:SetTexture(nil) end


    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then highlight:SetTexture(nil) end

    button:HookScript("OnEnter", function(self)
        self.narciOver = true
        ActionBars:MicroLook(self)
        if MicroOption("noTooltip", false) and GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)

    button:HookScript("OnLeave", function(self)
        self.narciOver = nil
        ActionBars:MicroLook(self)
    end)

    self:CropMicro(button)
end

local MICRO_STYLES = { tiles = true, flat = true, strip = true, glow = true, dock = true }

function ActionBars:MicroStyle()
    local db = Settings()
    local style = db and db.micro.style
    return MICRO_STYLES[style] and style or "tiles"
end

function ActionBars:MicroLook(button)
    if not button.narciEdges then return end

    local S = Style()
    local style = self:MicroStyle()
    local over = button.narciOver
    local r, g, b, a = self:MicroEdgeColor()
    local strip = style == "strip"
    local framed = style == "tiles" or strip

    for index, line in ipairs(button.narciEdges) do
        line:SetShown(framed and (not strip or index == 4))
        if over and style == "tiles" then
            line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        else
            line:SetVertexColor(r, g, b, strip and 0.55 or a)
        end
    end

    button.narciGround:SetShown(framed or style == "glow")
    button.narciGround:SetVertexColor(0.02, 0.022, 0.03, MicroOption("groundAlpha", 100) / 100)
    button.narciUnder:SetShown(style == "glow" or (style == "flat" and over))
    button.narciUnder:SetAlpha((style == "glow" and not over) and 0.35 or 1)
    button.narciWash:SetShown(over and (strip or style == "glow" or style == "flat") and true or false)
    PaintMicroIcon(button)
end

local function DockTick(holder, step)
    local list = holder.narciButtons
    if not list then return end

    local perRow = holder.narciPerRow or 1
    local zoom = MicroOption("dockZoom", 135) / 100
    local near = 1 + (zoom - 1) * 0.43
    local hovered
    for index, button in ipairs(list) do
        if button.narciOver then hovered = index end
    end

    for index, button in ipairs(list) do
        local target = 1
        if hovered then
            local sameRow = math.floor((index - 1) / perRow) == math.floor((hovered - 1) / perRow)
            local distance = math.abs(index - hovered)
            if distance == 0 then
                target = zoom
            elseif distance == 1 and sameRow then
                target = near
            end
        end

        local scale = button.narciScale or 1
        if math.abs(scale - target) > 0.004 then
            scale = scale + (target - scale) * math.min(1, step * 14)
            if math.abs(scale - target) <= 0.004 then scale = target end
            button.narciScale = scale
            button:SetScale(scale)
            button:ClearAllPoints()
            button:SetPoint("CENTER", holder, "TOPLEFT", button.narciCX / scale, button.narciCY / scale)
        end
    end
end

function ActionBars:MicroEdgeColor()
    local db = Settings()
    local choice = db and db.micro.borderColor
    local S = Style()

    if choice == "accent" then
        return S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9
    end

    if choice == "class" then
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b, 0.9 end
    end

    return S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95
end

function ActionBars:BuildMicroPanel(holder)
    if holder.narciPanel then return holder.narciPanel end

    local S = Style()

    local panel = CreateFrame("Frame", nil, holder)
    panel:SetPoint("TOPLEFT", holder, "TOPLEFT", -5, 5)
    panel:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 5, -5)
    panel:SetFrameLevel(math.max(holder:GetFrameLevel() - 1, 0))

    local ground = panel:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(panel)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL", 0.012, 0.014, 0.020, 0.92, 0.034, 0.038, 0.052, 0.92)

    S.CreateEdges(panel, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.85)
    S.CreateSoftShadow(panel, 6, 0.45)

    local glow = panel:CreateTexture(nil, "ARTWORK")
    glow:SetHeight(1)
    glow:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    glow:SetTexture(WHITE)
    glow:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.85,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    holder.narciPanel = panel
    return panel
end

function ActionBars:StyleMicro()
    local db = Settings()
    if not db then return end

    local names = {}

    for _, name in ipairs(MICRO_BUTTONS) do names[#names + 1] = name end
    for _, name in ipairs(BAG_BUTTONS) do names[#names + 1] = name end

    for _, name in ipairs(names) do
        local button = _G[name]
        if button then self:MicroLook(button) end
    end

    local holder = self.microHolder
    if not holder then return end

    if db.micro.panel or self:MicroStyle() == "strip" then
        self:BuildMicroPanel(holder):Show()
    elseif holder.narciPanel then
        holder.narciPanel:Hide()
    end

    if not db.micro.mouseover then
        holder:SetAlpha(db.micro.alpha or 1)
        holder.narciAlpha = nil
    end
end

local function SilenceDFMicro(button)
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        local texture = button[getter] and button[getter](button)
        if texture then texture:SetAlpha(0) end
    end
    for _, key in ipairs({ "Background", "PushedBackground", "PushedShadow", "Portrait" }) do
        local region = button[key]
        if region and region.SetAlpha then region:SetAlpha(0) end
    end
end

function ActionBars:CropMicro(button)
    local microKey = button.narciMicroKey or button:GetName() or ""
    local icons = MICRO_ICONS[microKey]
    if icons then
        for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
            local texture = button[getter] and button[getter](button)
            if texture then texture:SetAlpha(0) end
        end
        if NS.DFUI then
            SilenceDFMicro(button)
            if not button.narciDFMicro then
                button.narciDFMicro = true
                for _, script in ipairs({ "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnEnable", "OnDisable" }) do
                    button:HookScript(script, SilenceDFMicro)
                end
                for _, method in ipairs({ "SetNormal", "SetPushed" }) do
                    if type(button[method]) == "function" then hooksecurefunc(button, method, SilenceDFMicro) end
                end
            end
        end
        if button:GetName() == "CharacterMicroButton" and _G.MicroButtonPortrait then _G.MicroButtonPortrait:SetAlpha(0) end
        if button:GetName() == "GuildMicroButton" and _G.GuildMicroButtonTabard then _G.GuildMicroButtonTabard:SetAlpha(0) end

        if not button.narciIcon then
            button.narciIcon = button:CreateTexture(nil, "OVERLAY")
            button:HookScript("OnMouseDown", function(self) PlaceMicroIcon(self, true) end)
            button:HookScript("OnMouseUp", function(self) PlaceMicroIcon(self, false) end)
        end
        local db = Settings()
        local set = db and db.micro and MICRO_SETS[db.micro.icons or ""]
        local custom = set and set[microKey]
        local builtin = db and db.micro and MICRO_BUILTIN[db.micro.icons or ""]
        if not custom and builtin then custom = Style().Media(icons.plugin and icons[2] or builtin .. icons[2]:sub(5)) end
        local full = (custom or FullMicroIcons()) and true or false
        button.narciIconFull = full
        button.narciIcon:SetTexture(custom or Style().Media(icons[full and 2 or 1]))
        PlaceMicroIcon(button, false)
        PaintMicroIcon(button)
        return
    end

    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local texture = button[getter] and button[getter](button)

        if texture then
            texture:SetTexCoord(MICRO_CROP[1], MICRO_CROP[2], MICRO_CROP[3], MICRO_CROP[4])
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        end
    end

    local name = button:GetName()

    if name == "CharacterMicroButton" then
        if _G.MicroButtonPortrait then _G.MicroButtonPortrait:SetAlpha(0) end

        if not button.narciFace then
            local face = button:CreateTexture(nil, "OVERLAY")
            face:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            face:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
            face:SetTexCoord(0.15, 0.85, 0.15, 0.85)
            button.narciFace = face
        end

        if type(SetPortraitTexture) == "function" then
            pcall(SetPortraitTexture, button.narciFace, "player")
        end
    end

    if name == "GuildMicroButton" then
        local tabard = _G.GuildMicroButtonTabard

        if tabard then
            if tabard.background then tabard.background:SetAlpha(0) end

            if tabard.emblem then
                tabard.emblem:ClearAllPoints()
                tabard.emblem:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
                tabard.emblem:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            end

            tabard:SetFrameLevel(button:GetFrameLevel() + 2)
        end
    end
end

function ActionBars:RefreshMicroIcons()
    for _, name in ipairs(MICRO_BUTTONS) do
        local button = _G[name]
        if button and button.narciMicro then self:CropMicro(button) end
    end
end

function ActionBars:HookMicro()
    if self.microHooked then return end
    self.microHooked = true

    if type(_G.UpdateMicroButtons) ~= "function" then return end

    local faceEvents = CreateFrame("Frame")
    faceEvents:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    faceEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    faceEvents:RegisterEvent("UNIT_MODEL_CHANGED")
    faceEvents:RegisterEvent("GUILD_EMBLEM_UPDATE")
    faceEvents:RegisterEvent("PLAYER_GUILD_UPDATE")

    local function RefreshFaces()
        for _, key in ipairs({ "CharacterMicroButton", "GuildMicroButton" }) do
            local button = _G[key]
            if button and button.narciMicro then ActionBars:CropMicro(button) end
        end
    end

    faceEvents:RegisterEvent("UNIT_AURA")

    faceEvents:SetScript("OnEvent", function(_, event, unit)
        if unit and unit ~= "player" then return end

        if event == "UNIT_AURA" then
            local mounted = IsMounted() and true or false
            if mounted == ActionBars.faceMounted then return end
            ActionBars.faceMounted = mounted
        end

        RefreshFaces()

        if NS.After and not ActionBars.faceQueued then
            ActionBars.faceQueued = true
            NS.After(0.6, function()
                ActionBars.faceQueued = nil
                RefreshFaces()
            end)
        end
    end)

    local function TakeMicroBack()
        if not Enabled() or not ActionBars.microHolder then return end
        if not InCombatLockdown() then
            ActionBars:LayoutMicro()
            return
        end
        if ActionBars.microWaiter then return end
        local waiter = CreateFrame("Frame")
        ActionBars.microWaiter = waiter
        waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
        waiter:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            ActionBars.microWaiter = nil
            ActionBars:LayoutMicro()
        end)
    end

    for _, name in ipairs({ "OverrideMicroMenuPosition", "ResetMicroMenuPosition", "MoveMicroButtons" }) do
        if type(_G[name]) == "function" then hooksecurefunc(name, TakeMicroBack) end
    end

    hooksecurefunc("UpdateMicroButtons", function()
        if not Enabled() then return end

        for _, name in ipairs(MICRO_BUTTONS) do
            local button = _G[name]
            if button and button.narciMicro then ActionBars:CropMicro(button) end
        end


    end)
end

function ActionBars:BuildMicroHolder()
    if self.microHolder then return self.microHolder end

    local db = Settings()
    local store = db.micro

    local holder = CreateFrame("Frame", "NarciSirus_MicroBar", UIParent)
    holder:SetPoint(store.point, UIParent, store.point, store.x, store.y)
    holder:EnableMouse(false)

    if NS.Movers then
        NS.Movers:Register(holder, L["Микро-меню"], function(point, _, x, y)
            local settings = Settings()
            settings.micro.point, settings.micro.x, settings.micro.y = point, x, y
            settings.micro.dock = "free"
        end, "bars")
    end

    self.microHolder = holder
    return holder
end

function ActionBars:LayoutMicro()
    if InCombatLockdown() then return end

    local db = Settings()
    local store = db.micro
    local holder = self:BuildMicroHolder()

    local list = {}

    for _, name in ipairs(MICRO_BUTTONS) do
        local button = _G[name]
        if button then list[#list + 1] = button end
    end

    if store.bags then
        for _, name in ipairs(BAG_BUTTONS) do
            local button = _G[name]
            if button then list[#list + 1] = button end
        end
    elseif db.hideBlizzard then
        for _, name in ipairs({ "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot",
            "CharacterBag3Slot", "KeyRingButton", "BagBarExpandToggle", "CharacterReagentBag0Slot" }) do
            local button = _G[name]
            if button then
                button:SetAlpha(0)
                button:EnableMouse(false)
            end
        end
    end

    if db.hideMicro or not store.enabled then
        holder:Hide()

        for _, button in ipairs(list) do
            button:SetAlpha(0)
            button:EnableMouse(false)
        end

        return
    end

    holder:Show()

    local hidden = type(store.hidden) == "table" and store.hidden or {}
    local shown = {}
    for _, button in ipairs(list) do
        if hidden[button:GetName() or ""] then
            button:SetAlpha(0)
            button:EnableMouse(false)
        else
            shown[#shown + 1] = button
        end
    end
    if store.reverse then
        for index = 1, math.floor(#shown / 2) do
            shown[index], shown[#shown + 1 - index] = shown[#shown + 1 - index], shown[index]
        end
    end

    local size = store.size
    local style = self:MicroStyle()
    local gap = style == "strip" and 0 or style == "dock" and math.max(store.spacing, 4) or store.spacing
    local placed = 0
    local placedButtons = {}

    self:HookMicro()

    local perRow = store.perRow
    if perRow < 1 then perRow = 1 end

    for _, button in ipairs(shown) do
        if button.GetNormalTexture then self:SkinMicro(button) end

        local column = placed % perRow
        local row = math.floor(placed / perRow)
        if store.vertical then column, row = row, column end

        button.narciCX = column * (size + gap) + size / 2
        button.narciCY = -(row * (size + gap) + size / 2)
        button.narciScale = 1

        button:SetParent(holder)
        button:SetScale(1)
        button:ClearAllPoints()
        button:SetSize(size, size)
        button:SetPoint("CENTER", holder, "TOPLEFT", button.narciCX, button.narciCY)
        button:SetAlpha(1)
        placedButtons[#placedButtons + 1] = button
        button:EnableMouse(true)
        button:Show()

        placed = placed + 1
    end

    if placed == 0 then
        holder:Hide()
        return
    end

    holder.narciButtons = placedButtons
    holder.narciPerRow = perRow
    holder:SetScript("OnUpdate", style == "dock" and DockTick or nil)

    local columns = placed < perRow and placed or perRow
    local rows = math.ceil(placed / perRow)
    if store.vertical then columns, rows = rows, columns end

    holder:SetSize(columns * size + (columns - 1) * gap,
        rows * size + (rows - 1) * gap)

    self:AnchorMicro()
    self:StyleMicro()
end

function ActionBars:AnchorMicro()
    local holder = self.microHolder
    if not holder or InCombatLockdown() then return end

    local db = Settings()
    local store = db.micro

    local chat = _G.ChatFrame1

    holder:ClearAllPoints()

    if store.dock == "chat" and chat and not store.freedFromChat then
        local left, bottom = chat:GetLeft(), chat:GetBottom()

        if left and bottom then
            store.freedFromChat = true
            store.dock = "free"
            store.point = "BOTTOMLEFT"
            store.x = math.floor(left - 6 + 0.5)
            store.y = math.max(8, math.floor(bottom - 12 - holder:GetHeight() + 0.5))
        end
    end

    if store.dock == "chat" and chat then
        self:RoomUnderChat(chat, holder)
        holder:SetPoint("TOPLEFT", chat, "BOTTOMLEFT", -6, -12)
    elseif store.dock == "bars" and self.panel and self.panel:IsShown() then
        holder:SetPoint("BOTTOMRIGHT", self.panel, "BOTTOMLEFT", -8, 0)
    else
        holder:SetPoint(store.point, UIParent, store.point, store.x, store.y)
    end
end

function ActionBars:RoomUnderChat(chat, holder)
    if InCombatLockdown() then return end

    local bottom, left = chat:GetBottom(), chat:GetLeft()
    if not bottom or not left then return end

    local need = math.floor(holder:GetHeight() + 12 + 10 + 0.5)
    if bottom >= need then return end

    chat:ClearAllPoints()
    chat:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, need)

    if type(_G.FCF_SavePositionAndDimensions) == "function" then
        pcall(_G.FCF_SavePositionAndDimensions, chat)
    end
end

function ActionBars:BuildPanel()
    if self.panel then return self.panel end

    local S = Style()

    local p = CreateFrame("Frame", "NarciSirus_BarPanel", UIParent)
    p:SetFrameStrata("BACKGROUND")

    local fill = p:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints(p)
    fill:SetTexture(WHITE)
    fill:SetGradientAlpha("VERTICAL",
        0.012, 0.014, 0.020, 0.82,
        S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], 0.50)

    local wash = p:CreateTexture(nil, "BORDER")
    wash:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    wash:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, 0)
    wash:SetHeight(18)
    wash:SetTexture(WHITE)
    wash:SetGradientAlpha("VERTICAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.07)

    local glowLeft = p:CreateTexture(nil, "ARTWORK")
    glowLeft:SetHeight(1)
    glowLeft:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    glowLeft:SetPoint("TOPRIGHT", p, "TOP", 0, 0)
    glowLeft:SetTexture(WHITE)
    glowLeft:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0,
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)

    local glowRight = p:CreateTexture(nil, "ARTWORK")
    glowRight:SetHeight(1)
    glowRight:SetPoint("TOPLEFT", p, "TOP", 0, 0)
    glowRight:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, 0)
    glowRight:SetTexture(WHITE)
    glowRight:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

    local sideLeft = p:CreateTexture(nil, "ARTWORK")
    sideLeft:SetWidth(1)
    sideLeft:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    sideLeft:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
    sideLeft:SetTexture(WHITE)
    sideLeft:SetGradientAlpha("VERTICAL",
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0,
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)

    local sideRight = p:CreateTexture(nil, "ARTWORK")
    sideRight:SetWidth(1)
    sideRight:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, 0)
    sideRight:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
    sideRight:SetTexture(WHITE)
    sideRight:SetGradientAlpha("VERTICAL",
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0,
        S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.8)

    S.CreateSoftShadow(p, 8, 0.35)

    self.panel = p
    return p
end

function ActionBars:LayoutPanel()
    local db = Settings()
    if not db then return end

    local p = self:BuildPanel()

    local left, right, top, bottom

    for _, preset in ipairs(BARS) do
        local store = db.bars[preset.key]
        local holder = holders[preset.key]

        if store and store.enabled and preset.point == "BOTTOM" and holder and holder:IsShown() then
            local l, r, tt, b = holder:GetLeft(), holder:GetRight(), holder:GetTop(), holder:GetBottom()

            if l and r and tt and b then
                if not left or l < left then left = l end
                if not right or r > right then right = r end
                if not top or tt > top then top = tt end
                if not bottom or b < bottom then bottom = b end
            end
        end
    end

    if not left then
        p:Hide()
        return
    end

    local pad = 8

    if db.panel then
        p:ClearAllPoints()
        p:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - pad, bottom - pad)
        p:SetSize(right - left + pad * 2, top - bottom + pad * 2)
        p:Show()
    else
        p:Hide()
        pad = 2
    end

    if NS.CooldownBar and NS.CooldownBar.SnapTo then
        NS.CooldownBar:SnapTo(left - pad, right + pad, top + pad)
    end

    self:AnchorMicro()
end

function ActionBars:BuildHolder(preset)
    if holders[preset.key] then return holders[preset.key] end

    local db = Settings()
    local store = db.bars[preset.key]
    local S = Style()

    local holder = CreateFrame("Frame", "NarciSirus_" .. preset.key, UIParent)
    holder:SetPoint(store.point, UIParent, store.point, store.x, store.y)

    if preset.page then holder:SetAttribute("actionpage", preset.page) end
    holder:SetMovable(true)
    holder:RegisterForDrag("LeftButton")
    holder:EnableMouse(false)
    holder.key = preset.key

    local grip = holder:CreateTexture(nil, "BACKGROUND")
    grip:SetAllPoints(holder)
    grip:SetTexture(WHITE)
    grip:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
    grip:Hide()

    local tag = holder:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(tag, "actionbars", NS.FS(12), "OUTLINE")
    tag:SetPoint("CENTER", holder, "CENTER", 0, 0)
    tag:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    tag:SetText(L[preset.label])
    tag:Hide()

    holder.grip = grip
    holder.tag = tag

    holder:SetScript("OnDragStart", function(self)
        if not moving then return end
        self:StartMoving()
    end)

    holder:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, _, x, y = self:GetPoint()
        local settings = Settings()
        local barStore = settings.bars[self.key]
        barStore.point, barStore.x, barStore.y = point, x, y
    end)

    if NS.Movers then
        NS.Movers:Register(holder, L[preset.label], function(point, _, x, y)
            local settings = Settings()
            local barStore = settings.bars[preset.key]
            barStore.point, barStore.x, barStore.y = point, x, y
        end, "bars")
    end

    holders[preset.key] = holder
    return holder
end

function ActionBars:EnsureCustom(preset)
    if not preset.custom or InCombatLockdown() then return end

    local holder = self:BuildHolder(preset)

    for index = 1, preset.count do
        local name = preset.prefix .. index

        if not _G[name] then
            local button = CreateFrame("CheckButton", name, holder, "ActionBarButtonTemplate")
            local slot = preset.firstSlot + index - 1

            button:SetAttribute("_ignore", true)
            button:SetAttribute("useparent-actionpage", nil)
            button:SetAttribute("action", slot)
            button:SetAttribute("_ignore", nil)
            button.action = slot

            if type(_G.ActionButton_UpdateAction) == "function" then
                pcall(_G.ActionButton_UpdateAction, button)
            end
        end
    end
end

function ActionBars:LayoutBar(preset)
    if InCombatLockdown() then return end

    local db = Settings()
    local store = db.bars[preset.key]
    local holder = self:BuildHolder(preset)

    if preset.page and holder:GetAttribute("actionpage") ~= preset.page then
        holder:SetAttribute("actionpage", preset.page)
    end

    if store.enabled and preset.custom then self:EnsureCustom(preset) end

    if not store.enabled then
        if holder.narciDriver then
            UnregisterStateDriver(holder, "visibility")
            holder.narciDriver = nil
        end
        holder:Hide()
        return
    end

    if preset.pet then
        if not holder.narciDriver then
            holder.narciDriver = "[pet,novehicleui] show; hide"
            RegisterStateDriver(holder, "visibility", holder.narciDriver)
        end
    elseif (preset.key == "bar1" or preset.key == "stance") and NS.db.skinVehicle ~= false then
        if not holder.narciDriver then
            holder.narciDriver = "[vehicleui] hide; show"
            RegisterStateDriver(holder, "visibility", holder.narciDriver)
        end
    else
        holder:Show()
    end

    local size = (store.size and store.size > 0) and store.size or db.size
    local height = math.floor(size * (db.look.ratio or 1) + 0.5)
    local gap = (store.spacing and store.spacing >= 0) and store.spacing or db.spacing
    local perRow = store.perRow
    if perRow < 1 then perRow = 1 end

    local total = store.buttons or preset.count
    if total > preset.count then total = preset.count end

    if preset.stance then
        total = GetNumShapeshiftForms() or 0
        self.stanceForms = total
    end

    local horizontal = store.growth ~= "UP" and store.growth ~= "DOWN"
    local flipX = store.growth == "LEFT"
    local flipY = store.growth == "UP"

    if not store.mouseover and not store.combatOnly then
        holder:SetAlpha(store.alpha or 1)
        holder.narciAlpha = nil
    end

    local placed = 0

    for index = 1, preset.count do
        local name = preset.prefix .. index
        local button = _G[name]

        if button and index <= total then
            self:SkinButton(name)

            local first = placed % perRow
            local second = math.floor(placed / perRow)
            local column = horizontal and first or second
            local row = horizontal and second or first

            if flipX then column = -column end
            if flipY then row = -row end

            button:SetParent(holder)
            button:ClearAllPoints()
            button:SetSize(size, height)

            local hideEmpty = db.hideEmpty or store.hideEmpty

            if not preset.special then
                button:SetAttribute("showgrid", hideEmpty and 0 or 1)
            end
            button:SetPoint("TOPLEFT", holder, "TOPLEFT",
                column * (size + gap), -row * (height + gap))
            button:Show()

            if store.hideEmpty and not db.hideEmpty and not preset.special then
                local slot = ActionSlot(button)
                if not (slot and HasAction(slot)) then button:Hide() end
            end

            if preset.key == "bar1" then
                self:PlaceBonus(index, holder, size, height, gap, column, row)
            end

            if not preset.custom and not preset.special
                and type(_G.ActionButton_UpdateAction) == "function" then
                pcall(_G.ActionButton_UpdateAction, button)
            end

            if not preset.special then self:PaintEmpty(button) end

            placed = placed + 1
        elseif button then
            button:Hide()
        end
    end

    if placed == 0 then
        if not holder.narciDriver then holder:Hide() end
        return
    end

    local along = placed < perRow and placed or perRow
    local across = math.ceil(placed / perRow)

    local columns = horizontal and along or across
    local rows = horizontal and across or along

    holder:SetSize(columns * size + (columns - 1) * gap,
        rows * height + (rows - 1) * gap)
end

function ActionBars:PlaceBonus(index, holder, size, height, gap, column, row)
    local button = _G["BonusActionButton" .. index]
    if not button then return end

    self:SkinButton("BonusActionButton" .. index)

    button:ClearAllPoints()
    button:SetSize(size, height)
    button:SetPoint("TOPLEFT", holder, "TOPLEFT",
        column * (size + gap), -row * (height + gap))

    if type(_G.ActionButton_UpdateAction) == "function" then
        pcall(_G.ActionButton_UpdateAction, button)
    end
end

function ActionBars:RefreshBonus()
    if type(_G.ActionButton_UpdateAction) ~= "function" then return end

    for index = 1, 12 do
        local button = _G["BonusActionButton" .. index]
        if button then pcall(_G.ActionButton_UpdateAction, button) end
    end
end

function ActionBars:RefreshActions()
    if type(_G.ActionButton_UpdateAction) ~= "function" then return end

    local live = self.live
    if not live then return end

    for index = 1, #live do
        local button = live[index]
        if button.action then pcall(_G.ActionButton_UpdateAction, button) end
    end
end

function ActionBars:SetBarOption(key, field, value)
    local db = Settings()
    local store = db and db.bars[key]
    if not store then return end

    store[field] = value
    self:Apply()
end

function ActionBars:Apply()
    if not Enabled() or InCombatLockdown() then return end

    local db = Settings()

    self:HideBlizzardArt()
    self:HookState()
    self:HookStance()
    self:SkinTotems()
    self:BuildExtras()

    local live = {}

    for _, preset in ipairs(BARS) do
        self:LayoutBar(preset)

        local store = db.bars[preset.key]

        if store and store.enabled and not preset.special then
            for index = 1, preset.count do
                local button = _G[preset.prefix .. index]
                if button then live[#live + 1] = button end
            end
        end
    end

    self.live = live

    self:StartFader()
    self:HookCooldownText()
    self:RestyleAll()

    if self.suspended then self:SuspendHolders() end

    SetCVar("alwaysShowActionBars", db.hideEmpty and "0" or "1")

    if NS.After then
        NS.After(0, function() ActionBars:LayoutPanel() end)
    else
        self:LayoutPanel()
    end
end

local function CooldownLeft(seconds)
    if seconds >= 3600 then return math.floor(seconds / 3600 + 0.5) .. L["ч"] end
    if seconds >= 60 then return math.floor(seconds / 60 + 0.5) .. L["м"] end
    if seconds >= 3 then return tostring(math.floor(seconds + 0.5)) end
    return string.format("%.1f", seconds)
end

local function CooldownKey(seconds)
    if seconds >= 3600 then return 2000000 + math.floor(seconds / 3600 + 0.5) end
    if seconds >= 60 then return 1000000 + math.floor(seconds / 60 + 0.5) end
    if seconds >= 3 then return math.floor(seconds + 0.5) end
    return nil
end

function ActionBars:HookCooldownText()
    if self.cooldownHooked or type(_G.CooldownFrame_SetTimer) ~= "function" then return end
    self.cooldownHooked = true

    local active = {}
    local ticker = CreateFrame("Frame")
    local elapsed = 0
    ticker:Hide()

    ticker:SetScript("OnUpdate", function(self, step)
        elapsed = elapsed + step
        if elapsed < 0.1 then return end
        elapsed = 0

        local now = GetTime()
        local any = false

        for cooldown, finish in pairs(active) do
            local left = finish - now
            local text = cooldown.narciText

            if left <= 0 or not cooldown:IsVisible() then
                text:SetText("")
                cooldown.narciKey = nil
                active[cooldown] = nil
            else
                any = true

                local look = Look()
                local plain = look and not look.cdColors or false
                local key = CooldownKey(left)

                if not key or key ~= cooldown.narciKey or plain ~= cooldown.narciPlain then
                    cooldown.narciKey, cooldown.narciPlain = key, plain
                    text:SetText(CooldownLeft(left))

                    if plain then
                        text:SetTextColor(0.95, 0.95, 0.97)
                    elseif left < 3 then
                        text:SetTextColor(1, 0.30, 0.30)
                    elseif left < 60 then
                        text:SetTextColor(1, 0.92, 0.55)
                    else
                        text:SetTextColor(0.85, 0.85, 0.90)
                    end
                end
            end
        end

        if not any then self:Hide() end
    end)

    hooksecurefunc("CooldownFrame_SetTimer", function(cooldown, start, duration, enable)
        local button = cooldown and cooldown:GetParent()
        if not button or not button.narciBar then return end

        local db = Settings()

        if type(enable) == "boolean" then enable = enable and 1 or 0 end

        local running = db and db.enabled and db.cooldownText
            and start and start > 0 and duration and duration >= (db.cdMin or 2) and enable and enable > 0

        if not running then
            if cooldown.narciText then cooldown.narciText:SetText("") end
            cooldown.narciKey = nil
            active[cooldown] = nil
            return
        end

        if not cooldown.narciText then
            local layer = CreateFrame("Frame", nil, button)
            layer:SetAllPoints(button)
            layer:SetFrameLevel(cooldown:GetFrameLevel() + 3)

            local text = layer:CreateFontString(nil, "OVERLAY")
            text:SetPoint("CENTER", button, "CENTER", 0, 0)
            cooldown.narciText = text
        end

        local look = Look()
        local size = look and look.cdSize or 0

        if size <= 0 then
            size = math.floor((button:GetWidth() or 32) * 0.42)
            if size < 10 then size = 10 end
            if size > 18 then size = 18 end
        end
        if cooldown.narciSize ~= size then
            cooldown.narciSize = size
            NS.LSetFont(cooldown.narciText, "actionbars", size, "OUTLINE")
        end

        cooldown.narciKey = nil
        active[cooldown] = start + duration
        ticker:Show()
    end)
end

local FADE_IN = 6
local FADE_OUT = 2.5

function ActionBars:BarVisible(holder, db)
    if NS.Movers and NS.Movers:IsActive() then return true end
    if self.binding then return true end
    if GetCursorInfo() then return true end
    if db.fadeCombat and InCombatLockdown() then return true end
    if SpellBookFrame and SpellBookFrame:IsShown() then return true end
    return MouseIsOver(holder) and true or false
end

function ActionBars:SetBarAlpha(preset, holder, alpha)
    holder:SetAlpha(alpha)
    holder.narciAlpha = alpha

    if preset.key == "bar1" then
        self.bonusFaded = alpha < 1 or nil

        for index = 1, 12 do
            local button = _G["BonusActionButton" .. index]
            if button then button:SetAlpha(alpha) end
        end
    end
end

function ActionBars:SetBonusAlpha(alpha)
    for index = 1, 12 do
        local button = _G["BonusActionButton" .. index]
        if button then button:SetAlpha(alpha) end
    end
end

function ActionBars:SuspendHolders()
    local combat = InCombatLockdown()

    for _, holder in pairs(holders) do
        holder:SetAlpha(0)
        if not combat and holder:IsShown() then
            holder.narciSuspended = true
            holder:Hide()
        end
    end

    self:SetBonusAlpha(0)
    if self.microHolder then self.microHolder:Hide() end
end

function ActionBars:Suspend()
    if self.suspended then return end
    self.suspended = true
    self:SuspendHolders()
end

function ActionBars:Resume()
    if not self.suspended then return end
    self.suspended = nil

    local db = Settings()
    if not db then return end

    for _, preset in ipairs(BARS) do
        local holder = holders[preset.key]
        local store = db.bars[preset.key]

        if holder then
            holder.narciAlpha = nil
            holder:SetAlpha((store.mouseover or store.combatOnly) and 0 or (store.alpha or 1))

            if holder.narciSuspended and not InCombatLockdown() then
                holder.narciSuspended = nil
                if store.enabled and holder.narciDriver then
                    if SecureCmdOptionParse(holder.narciDriver) == "show" then holder:Show() end
                elseif store.enabled then
                    holder:Show()
                end
            end
        end
    end

    local bar1 = db.bars.bar1
    self:SetBonusAlpha(bar1 and bar1.mouseover and 0 or 1)

    if InCombatLockdown() then
        self.applyPending = true
        return
    end

    self:Apply()
end

function ActionBars:StepFader(step)
    local db = Settings()
    if not db or self.suspended then return end

    local micro = self.microHolder
    local speed = (db.fadeSpeed or 100) / 100
    local rest = (db.fadeAlpha or 0) / 100

    if micro and (db.micro.mouseover or db.micro.combatHide) and micro:IsShown() then
        local full = db.micro.alpha or 1
        local target
        if db.micro.combatHide and InCombatLockdown() and not (NS.Movers and NS.Movers:IsActive()) then
            target = 0
        elseif db.micro.mouseover then
            target = self:BarVisible(micro, db) and full or full * rest
        else
            target = full
        end
        local current = micro.narciAlpha or micro:GetAlpha()

        if math.abs(current - target) > 0.005 then
            if current < target then
                current = math.min(target, current + FADE_IN * speed * step)
            else
                current = math.max(target, current - FADE_OUT * speed * step)
            end

            micro:SetAlpha(current)
            micro.narciAlpha = current
        end
    end

    for _, preset in ipairs(BARS) do
        local store = db.bars[preset.key]
        local holder = holders[preset.key]

        if store and store.enabled and (store.mouseover or store.combatOnly) and holder and holder:IsShown() then
            local full = store.alpha or 1
            local visible

            if store.combatOnly and InCombatLockdown() then
                visible = true
            elseif store.mouseover then
                visible = self:BarVisible(holder, db)
            else
                visible = (NS.Movers and NS.Movers:IsActive()) or self.binding or (GetCursorInfo() and true) or false
            end

            local target = visible and full or full * rest
            local current = holder.narciAlpha or holder:GetAlpha()

            if math.abs(current - target) > 0.005 then
                if current < target then
                    current = math.min(target, current + FADE_IN * speed * step)
                else
                    current = math.max(target, current - FADE_OUT * speed * step)
                end

                self:SetBarAlpha(preset, holder, current)
            end
        end
    end
end

function ActionBars:StartFader()
    local db = Settings()
    if not db then return end

    local any, bar1 = (db.micro.mouseover or db.micro.combatHide) and true or false, false

    for _, preset in ipairs(BARS) do
        local store = db.bars[preset.key]
        if store and store.enabled and (store.mouseover or store.combatOnly) then
            any = true
            if preset.key == "bar1" then bar1 = true end
        end
    end

    if not bar1 and self.bonusFaded then
        self.bonusFaded = nil

        for index = 1, 12 do
            local button = _G["BonusActionButton" .. index]
            if button then button:SetAlpha(1) end
        end
    end

    if not self.fader then
        local fader = CreateFrame("Frame")
        local elapsed = 0

        fader:SetScript("OnUpdate", function(_, step)
            elapsed = elapsed + step
            if elapsed < 0.03 then return end
            ActionBars:StepFader(elapsed)
            elapsed = 0
        end)

        self.fader = fader
    end

    self.fader:SetShown(any)
end

local function XPStatus()
    local maxLevel = _G.MAX_PLAYER_LEVEL or 80
    if UnitLevel("player") < maxLevel then
        local value, maxValue = UnitXP("player") or 0, UnitXPMax("player") or 1
        return "xp", value, math.max(1, maxValue), GetXPExhaustion and GetXPExhaustion() or nil
    end
    local name, reaction, low, high, value = GetWatchedFactionInfo()
    if name then return "rep", value - low, math.max(1, high - low), nil, name, reaction end
end

local XP_TICKS = 10

local function XPColor(db, field, default)
    local c = db[field]
    if type(c) == "table" then return c[1], c[2], c[3] end
    return default[1], default[2], default[3]
end

local function ShortNumber(value)
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 10000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end

function ActionBars:XPText(f)
    local db = Settings()
    local mode = db.xpText or "none"
    if mode == "none" or not f.kind then return "" end
    if db.xpTextHover and not f.hover then return "" end
    local percent = string.format("%.1f%%", f.value / f.maxValue * 100)
    local amount = ShortNumber(f.value) .. " / " .. ShortNumber(f.maxValue)
    local text
    if mode == "percent" then
        text = percent
    elseif mode == "value" then
        text = amount
    elseif mode == "left" then
        text = ShortNumber(f.maxValue - f.value)
    else
        text = amount .. "  " .. percent
    end
    if f.kind == "rep" and db.xpTextName ~= false and f.name then text = f.name .. ": " .. text end
    if f.kind == "xp" and f.restedValue and f.restedValue > 0 and db.xpTextRested ~= false then
        text = text .. "  (+" .. ShortNumber(f.restedValue) .. ")"
    end
    return text
end

function ActionBars:ApplyXPLook(frame)
    local f = frame or self.xpBar
    if not f then return end
    local db = Settings()
    local S = Style()

    f:SetSize(db.xpWidth or 420, db.xpHeight or 8)
    f.ground:SetVertexColor(0.016, 0.018, 0.026, (db.xpBgAlpha or 90) / 100)

    local style = db.xpStyle or "flat"
    S.SkinBox(f, style == "flat" and "none" or style, { alpha = (db.xpBgAlpha or 90) / 100 })
    f.ground:SetShown(style == "flat")

    local border = db.xpBorder or "thin"
    for _, line in ipairs(f.edges) do
        line:SetShown(border ~= "none" and style == "flat")
        if border == "accent" then
            line:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
        elseif border == "black" then
            line:SetVertexColor(0, 0, 0, 1)
        else
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
        end
    end

    local ticks = db.xpTicks
    for index = 1, XP_TICKS - 1 do
        local tick = f.ticks[index]
        tick:ClearAllPoints()
        tick:SetPoint("TOP", f, "TOPLEFT", (db.xpWidth or 420) * index / XP_TICKS, -1)
        tick:SetPoint("BOTTOM", f, "BOTTOMLEFT", (db.xpWidth or 420) * index / XP_TICKS, 1)
        tick:SetShown(ticks and true or false)
    end

    NS.LSetFont(f.text, "actionbars", db.xpTextSize or 10, "OUTLINE")
    f.text:ClearAllPoints()
    local place = db.xpTextPlace or "inside"
    if place == "above" then
        f.text:SetPoint("BOTTOM", f, "TOP", 0, 2)
    elseif place == "below" then
        f.text:SetPoint("TOP", f, "BOTTOM", 0, -2)
    else
        f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    end

    f.spark:SetSize(12, (db.xpHeight or 8) * 2.4)
    f.spark:SetShown(db.xpSpark and true or false)
    self:UpdateXPBar(frame)
end

function ActionBars:UpdateXPBar(frame)
    local f = frame or self.xpBar
    if not f then return end
    local db = Settings()
    local kind, value, maxValue, rested, name, reaction = XPStatus()
    if frame and (not kind or (kind == "rep" and db.xpRep == false)) then
        kind, value, maxValue, rested, name, reaction = "xp", 61800, 100000, 22000, nil, nil
    end
    if not frame and (db.xpBar == false or not kind or (kind == "rep" and db.xpRep == false)
        or (db.xpCombatHide and InCombatLockdown())) then
        f:Hide()
        return
    end
    f:Show()
    f.bar:SetMinMaxValues(0, maxValue)
    f.bar:SetValue(value)
    if kind == "xp" then
        f.bar:SetStatusBarColor(XPColor(db, "xpColor", { 0.58, 0.30, 0.85 }))
        local rr, rg, rb = XPColor(db, "xpRestedColor", { 0.25, 0.45, 0.90 })
        f.rested:SetStatusBarColor(rr, rg, rb, 0.45)
        f.rested:SetMinMaxValues(0, maxValue)
        f.rested:SetValue(math.min(maxValue, value + (rested or 0)))
        f.rested:SetShown(db.xpShowRested ~= false)
    else
        local mode = db.xpRepColor or "reaction"
        if mode == "theme" then
            local A = Style().ACCENT
            f.bar:SetStatusBarColor(A[1], A[2], A[3])
        elseif mode == "custom" then
            f.bar:SetStatusBarColor(XPColor(db, "xpRepCustom", { 0.3, 0.7, 0.3 }))
        else
            local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] or { r = 0.3, g = 0.7, b = 0.3 }
            f.bar:SetStatusBarColor(color.r, color.g, color.b)
        end
        f.rested:Hide()
    end
    f.kind, f.value, f.maxValue, f.restedValue, f.name = kind, value, maxValue, rested, name

    local width = f.bar:GetWidth() or 0
    f.spark:ClearAllPoints()
    f.spark:SetPoint("CENTER", f.bar, "LEFT", width * value / maxValue, 0)
    f.text:SetText(self:XPText(f))
end

local function XPBody(f)
    local db = Settings()
    local S = Style()
    local ground = f:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(f)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.9)
    f.ground = ground
    f.edges = S.CreateEdges(f, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    local rested = CreateFrame("StatusBar", nil, f)
    rested:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    rested:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    if NS.Look and NS.Look.SetBar then NS.Look:SetBar(rested, "actionbars") else rested:SetStatusBarTexture(WHITE) end
    rested:SetStatusBarColor(0.25, 0.45, 0.90, 0.45)
    f.rested = rested

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetAllPoints(rested)
    bar:SetFrameLevel(rested:GetFrameLevel() + 1)
    if NS.Look and NS.Look.SetBar then NS.Look:SetBar(bar, "actionbars") else bar:SetStatusBarTexture(WHITE) end
    f.bar = bar

    local over = CreateFrame("Frame", nil, f)
    over:SetAllPoints(f)
    over:SetFrameLevel(bar:GetFrameLevel() + 2)

    f.ticks = {}
    for index = 1, XP_TICKS - 1 do
        local tick = over:CreateTexture(nil, "ARTWORK")
        tick:SetWidth(1)
        tick:SetTexture(WHITE)
        tick:SetVertexColor(0, 0, 0, 0.55)
        tick:Hide()
        f.ticks[index] = tick
    end

    local spark = over:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetSize(12, (db.xpHeight or 8) * 2.4)
    spark:Hide()
    f.spark = spark

    local text = over:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(text, "actionbars", db.xpTextSize or 10, "OUTLINE")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1)
    f.text = text

end

function ActionBars:BuildXPBar()
    local db = Settings()
    if self.xpBar or db.xpBar == false then return end
    local S = Style()
    local f = CreateFrame("Frame", "NarciSirus_XPBar", UIParent)
    f:SetSize(db.xpWidth or 420, db.xpHeight or 8)
    f:SetPoint(db.xpPoint or "BOTTOM", UIParent, db.xpPoint or "BOTTOM", db.xpX or 0, db.xpY or 8)
    f:SetFrameStrata("LOW")
    f:EnableMouse(true)

    XPBody(f)

    f:SetScript("OnEnter", function(self)
        self.hover = true
        self.text:SetText(ActionBars:XPText(self))
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if self.kind == "xp" then
            GameTooltip:AddLine(L["Опыт"], 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Получено"], string.format("%d / %d (%.1f%%)", self.value, self.maxValue, self.value / self.maxValue * 100), 0.7, 0.7, 0.75, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["До уровня"], tostring(self.maxValue - self.value), 0.7, 0.7, 0.75, 1, 1, 1)
            if self.restedValue then
                GameTooltip:AddDoubleLine(L["Отдых"], tostring(self.restedValue), 0.7, 0.7, 0.75, 0.4, 0.6, 1)
            end
        elseif self.kind == "rep" then
            GameTooltip:AddLine(self.name or "", 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Репутация"], string.format("%d / %d", self.value, self.maxValue), 0.7, 0.7, 0.75, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(self)
        self.hover = nil
        self.text:SetText(ActionBars:XPText(self))
        GameTooltip:Hide()
    end)

    local driver = CreateFrame("Frame", nil, UIParent)
    driver:SetScript("OnEvent", function() ActionBars:UpdateXPBar() end)
    driver:RegisterEvent("PLAYER_REGEN_DISABLED")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    f.driver = driver

    f:SetScript("OnEvent", function() ActionBars:UpdateXPBar() end)
    for _, event in ipairs({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP", "UPDATE_FACTION", "PLAYER_ENTERING_WORLD" }) do
        f:RegisterEvent(event)
    end

    if NS.Movers then
        NS.Movers:Register(f, L["Полоса опыта"], function(point, _, x, y)
            local settings = Settings()
            settings.xpPoint, settings.xpX, settings.xpY = point, x, y
        end, "bars")
    end

    self.xpBar = f
    self:ApplyXPLook()
end

function ActionBars:CreateXPSample(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(260, 10)
    XPBody(f)
    return f
end

function ActionBars:PaintXPSample(f)
    local db = Settings()
    if not db or not f then return end
    f:SetScale(math.min(1, 280 / math.max(db.xpWidth or 420, 1)))
    f.hover = nil
    self:ApplyXPLook(f)
    f:Show()
end

function ActionBars:BuildLeaveButton()
    local db = Settings()
    if self.leaveButton then return end
    local S = Style()
    local button = CreateFrame("Button", "NarciSirus_LeaveVehicle", UIParent)
    button:SetSize(32, 32)
    button:SetPoint(db.leavePoint or "BOTTOM", UIParent, db.leavePoint or "BOTTOM", db.leaveX or 260, db.leaveY or 30)
    button:SetFrameStrata("MEDIUM")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    icon:SetTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    icon:SetTexCoord(0.14, 0.86, 0.14, 0.86)
    button:SetHighlightTexture(WHITE, "ADD")
    button:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 0.18)
    button:SetScript("OnClick", function()
        if type(_G.MainMenuBarVehicleLeaveButton_OnClicked) == "function" then
            pcall(_G.MainMenuBarVehicleLeaveButton_OnClicked)
        elseif UnitOnTaxi("player") and TaxiRequestEarlyLanding then
            pcall(TaxiRequestEarlyLanding)
        else
            pcall(VehicleExit)
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(_G.LEAVE_VEHICLE or L["Покинуть транспорт"], 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function Update()
        local can = (CanExitVehicle and CanExitVehicle()) or UnitOnTaxi("player")
        if can then button:Show() else button:Hide() end
    end
    button:SetScript("OnEvent", Update)
    for _, event in ipairs({ "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "PLAYER_ENTERING_WORLD", "UPDATE_BONUS_ACTIONBAR", "VEHICLE_UPDATE", "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED" }) do
        pcall(button.RegisterEvent, button, event)
    end
    if NS.Movers then
        NS.Movers:Register(button, L["Выход из транспорта"], function(point, _, x, y)
            local settings = Settings()
            settings.leavePoint, settings.leaveX, settings.leaveY = point, x, y
        end, "bars")
    end
    self.leaveButton = button
    self:ApplyLeaveLook()
    Update()
end

function ActionBars:ApplyLeaveLook()
    local button = self.leaveButton
    if not button then return end
    local db = Settings()
    local size = db.leaveSize or 32
    button:SetSize(size, size)
    Style().SkinBox(button, db.leaveStyle or "flat", { tint = { 0.85, 0.3, 0.3 }, edgeLayer = "OVERLAY" })
end

function ActionBars:BuildExtras()
    local db = Settings()
    if not db.hideBlizzard then return end
    self:BuildXPBar()
    self:BuildLeaveButton()
end

local SAMPLE_ACTIONS = {
    { "Interface\\Icons\\Spell_Fire_FlameBolt", "1" },
    { "Interface\\Icons\\Spell_Frost_FrostBolt02", "2", 3 },
    { "Interface\\Icons\\Spell_Holy_FlashHeal", "S-3", nil, "Хил" },
    { "Interface\\Icons\\Ability_Warrior_Charge", "C-4", nil, nil, true },
    { "Interface\\Icons\\INV_Potion_54", "5", 12 },
}

local SAMPLE_MICRO = {
    "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
    "QuestLogMicroButton", "LFDMicroButton", "MainMenuMicroButton",
}

function ActionBars:CreateSample(parent, opts)
    if opts and opts.kind == "xp" then return self:CreateXPSample(parent) end
    local holder = CreateFrame("Frame", nil, parent)
    holder.buttons = {}
    if opts and opts.kind == "micro" then
        for index, key in ipairs(SAMPLE_MICRO) do
            local button = CreateFrame("Button", nil, holder)
            button:SetSize(24, 24)
            button.narciMicroKey = key
            button.narciSample = true
            self:SkinMicro(button)
            holder.buttons[index] = button
        end
        holder.buttons[2].narciOver = true
        return holder
    end
    self.sampleSerial = (self.sampleSerial or 0) + 1
    for index, data in ipairs(SAMPLE_ACTIONS) do
        local name = "NarciSirus_ButtonSample" .. self.sampleSerial .. "_" .. index
        local button = CreateFrame("CheckButton", name, holder, "ActionButtonTemplate")
        button:EnableMouse(false)
        _G[name .. "Icon"]:SetTexture(data[1])
        _G[name .. "HotKey"]:SetText(data[2])
        if data[3] then _G[name .. "Count"]:SetText(data[3]) end
        if data[4] then _G[name .. "Name"]:SetText(data[4]) end
        button.narciSample = true
        self:SkinButton(name)
        if data[5] and CooldownFrame_SetTimer then
            CooldownFrame_SetTimer(_G[name .. "Cooldown"], GetTime() - 4, 3600, 1)
        end
        holder.buttons[index] = button
    end
    return holder
end

function ActionBars:PaintSample(holder, opts)
    local db = Settings()
    if not db or not holder then return end
    if opts and opts.kind == "xp" then return self:PaintXPSample(holder) end
    if opts and opts.kind == "micro" then
        local micro = db.micro or {}
        local size = micro.size or 22
        local gap = micro.spacing or 2
        for index, button in ipairs(holder.buttons) do
            button:SetSize(size, size)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", holder, "TOPLEFT", (index - 1) * (size + gap), 0)
            self:CropMicro(button)
            self:MicroLook(button)
            button:Show()
        end
        holder:SetSize(#holder.buttons * (size + gap) - gap, size)
        if micro.panel or self:MicroStyle() == "strip" then
            self:BuildMicroPanel(holder):Show()
        elseif holder.narciPanel then
            holder.narciPanel:Hide()
        end
        holder:SetScale(math.min(2, 280 / math.max(holder:GetWidth(), 1)))
        return
    end
    local size = 40
    local gap = 4
    for index, button in ipairs(holder.buttons) do
        button:SetSize(size, size)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", holder, "TOPLEFT", (index - 1) * (size + gap), 0)
        local hotkey = _G[button:GetName() .. "HotKey"]
        if hotkey then
            hotkey:SetText(SAMPLE_ACTIONS[index][2])
            hotkey:SetShown(db.showHotKey and true or false)
        end
        self:StyleButton(button)
        ShortKey(button)
        self:PaintEdges(button, index == 2)
        button:Show()
    end
    holder:SetSize(#holder.buttons * (size + gap) - gap, size)
end

function ActionBars:SkinTotems()
    if select(2, UnitClass("player")) ~= "SHAMAN" then return end
    for index = 1, 12 do
        if _G["MultiCastActionButton" .. index] then self:SkinButton("MultiCastActionButton" .. index) end
    end
    for _, name in ipairs({ "MultiCastSummonSpellButton", "MultiCastRecallSpellButton" }) do
        if _G[name] then self:SkinButton(name) end
    end
end

function ActionBars:HookStance()
    if self.stanceHooked then return end
    self.stanceHooked = true

    if type(_G.ShapeshiftBar_Update) ~= "function" then return end

    hooksecurefunc("ShapeshiftBar_Update", function()
        if not Enabled() or InCombatLockdown() or not NS.After then return end

        local forms = GetNumShapeshiftForms() or 0
        if ActionBars.stanceForms == forms or ActionBars.stanceQueued then return end

        ActionBars.stanceQueued = true

        NS.After(0, function()
            ActionBars.stanceQueued = nil
            ActionBars.stanceForms = GetNumShapeshiftForms() or 0

            for _, preset in ipairs(BARS) do
                if preset.stance then ActionBars:LayoutBar(preset) end
            end

            ActionBars:LayoutPanel()
        end)
    end)
end

function ActionBars:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Apply()
        NS.Print("панели команд в стиле аддона")
    else
        NS.Print("панели команд вернутся к клиентским после /reload")
    end
end

function ActionBars:Move()
    if NS.Movers then NS.Movers:Toggle("bars") end
end

function ActionBars:SetSize(value)
    local db = Settings()
    local size = tonumber(value)

    if not db or not size or size < 18 or size > 64 then
        NS.Print("размер кнопки от 18 до 64, например /narci bars size 32")
        return
    end

    db.size = size
    self:Apply()
    NS.Print("размер кнопок: " .. size)
end

function ActionBars:SetSpacing(value)
    local db = Settings()
    local gap = tonumber(value)

    if not db or not gap or gap < 0 or gap > 20 then
        NS.Print("отступ от 0 до 20, например /narci bars gap 4")
        return
    end

    db.spacing = gap
    self:Apply()
    NS.Print("отступ между кнопками: " .. gap)
end

function ActionBars:SetPerRow(key, value)
    local db = Settings()
    local store = db and db.bars[key]
    local perRow = tonumber(value)

    if not store or not perRow or perRow < 1 or perRow > 12 then
        NS.Print("кнопок в ряд от 1 до 12, например /narci bars row bar2 6")
        return
    end

    store.perRow = perRow
    self:Apply()
    NS.Print(key .. ": " .. perRow .. " в ряд")
end

function ActionBars:SetBarEnabled(key, value)
    local db = Settings()
    local store = db and db.bars[key]
    if not store then return end

    store.enabled = value and true or false

    local db = Settings()
    if value and not db.enabled then
        db.enabled = true
        NS.Print("панели команд включены")
    end

    self:Apply()

    local holder = holders[key]
    if holder and not store.enabled then holder:Hide() end
end

function ActionBars:ResetPositions()
    local db = Settings()
    if not db then return end

    local step = db.size + db.spacing

    for _, preset in ipairs(BARS) do
        local store = db.bars[preset.key]
        local slot = preset.slot or 0

        store.point = preset.point
        store.perRow = preset.perRow

        if preset.point == "BOTTOM" then
            store.x, store.y = 0, 30 + slot * step
        elseif preset.point == "RIGHT" then
            store.x, store.y = -(6 + slot * step), 0
        elseif preset.point == "LEFT" then
            store.x, store.y = 6 + slot * step, 0
        else
            store.x, store.y = preset.x, preset.y
        end

        local holder = holders[preset.key]
        if holder then
            holder:ClearAllPoints()
            holder:SetPoint(store.point, UIParent, store.point, store.x, store.y)
        end
    end

    self:Apply()
    NS.Print("расположение панелей сброшено")
end

function ActionBars:ToggleHotKeys()
    local db = Settings()
    if not db then return end

    db.showHotKey = not db.showHotKey

    for _, preset in ipairs(BARS) do
        for index = 1, preset.count do
            local hotkey = _G[preset.prefix .. index .. "HotKey"]
            if hotkey then hotkey:SetShown(db.showHotKey) end
        end
    end

    NS.Print(db.showHotKey and "привязки показаны" or "привязки скрыты")
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
driver:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
driver:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
driver:RegisterEvent("PLAYER_TALENT_UPDATE")

local LIVE_EVENTS = {
    ACTIONBAR_PAGE_CHANGED = true,
    UPDATE_BONUS_ACTIONBAR = true,
    UPDATE_SHAPESHIFT_FORM = true,
    ACTIVE_TALENT_GROUP_CHANGED = true,
    PLAYER_TALENT_UPDATE = true,
}

driver:SetScript("OnEvent", function(self, event)
    if not Enabled() then return end

    if event == "PLAYER_LOGIN" then
        if NS.After then NS.After(3, function() ActionBars:Apply() end) end
        return
    end

    if LIVE_EVENTS[event] then
        if not InCombatLockdown() and NS.After then
            NS.After(0, function()
                if InCombatLockdown() then return end
                ActionBars:RefreshActions()
                ActionBars:RefreshBonus()
            end)
        end

        if InCombatLockdown() then
            ActionBars.applyPending = true
            return
        end
    end

    if event == "PLAYER_REGEN_ENABLED" and not ActionBars.applyPending then
        ActionBars:RefreshActions()
        return
    end

    ActionBars.applyPending = nil
    ActionBars:Apply()
end)
