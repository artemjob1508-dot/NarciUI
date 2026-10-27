local addonName, NS = ...
local L = NS.L

local Dialogue = {}
NS.Dialogue = Dialogue

local WHITE = "Interface\\Buttons\\WHITE8x8"

local MAX_OPTIONS = 12
local KEYED_OPTIONS = 9
local REVEAL_SPEED = 70
local GRADIENT = 18
local PANEL_W = 600
local OPTION_W = 640
local OPTION_H = 34
local TILE_W = 290
local TILE_H = 44

local GOSSIP_ICON = "Interface\\GossipFrame\\"

local function Settings()
    if not NS.db then return end

    if not NS.db.dialogue then NS.db.dialogue = {} end

    local db = NS.db.dialogue
    if db.enabled == nil then db.enabled = true end
    if db.hideInterface == nil then db.hideInterface = true end
    if db.typewriter == nil then db.typewriter = true end
    if db.keys == nil then db.keys = true end
    db.dim = db.dim or 75
    db.bodySize = db.bodySize or 17
    db.nameSize = db.nameSize or 28
    db.revealSpeed = db.revealSpeed or 100
    db.textColor = db.textColor or "white"
    if db.showModel == nil then db.showModel = true end
    if db.modelLight == nil then db.modelLight = true end

    if not db.dimDefaultV2 then
        db.dimDefaultV2 = true
        if db.dim == 55 then db.dim = 75 end
    end

    return db
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local function Style()
    return NS.Styling
end

local function Coins(money)
    if not money or money <= 0 then return "" end

    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    local parts = {}

    if gold > 0 then
        parts[#parts + 1] = gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    end
    if silver > 0 then
        parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    end
    if copper > 0 then
        parts[#parts + 1] = copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end

    return table.concat(parts, " ")
end

local function Fader(frame)
    frame.narciFade = { from = 0, to = 0, time = 0, length = 0.25 }

    frame:HookScript("OnUpdate", function(self, step)
        local fade = self.narciFade
        if fade.time >= fade.length then return end

        fade.time = math.min(fade.length, fade.time + step)
        local alpha = fade.from + (fade.to - fade.from) * (fade.time / fade.length)
        self:SetAlpha(alpha)

        if fade.time >= fade.length and fade.to == 0 then self:Hide() end
    end)
end

local function FadeTo(frame, target, length)
    local fade = frame.narciFade
    fade.from = frame:IsShown() and frame:GetAlpha() or 0
    fade.to = target
    fade.time = 0
    fade.length = length or 0.25

    if target > 0 then
        if not frame:IsShown() then frame:SetAlpha(0) end
        frame:Show()
    end
end

function Dialogue:BuildDim()
    local db = Settings()

    local dim = CreateFrame("Frame", "NarciSirus_DialogueDim", UIParent)
    dim:SetAllPoints(UIParent)
    dim:SetFrameStrata("BACKGROUND")
    dim:SetFrameLevel(1)
    dim:Hide()

    local flat = dim:CreateTexture(nil, "BACKGROUND")
    flat:SetAllPoints(dim)
    flat:SetTexture(WHITE)

    local bottom = dim:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", dim, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", dim, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(320)
    bottom:SetTexture(WHITE)
    bottom:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.75, 0, 0, 0, 0)

    local left = dim:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", dim, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", dim, "BOTTOMLEFT", 0, 0)
    left:SetWidth(760)
    left:SetTexture(WHITE)
    left:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.65, 0, 0, 0, 0)

    local top = dim:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", dim, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", dim, "TOPRIGHT", 0, 0)
    top:SetHeight(140)
    top:SetTexture(WHITE)
    top:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0.55)

    dim.flat = flat
    Fader(dim)

    self.dim = dim
    self:ApplyDim()

    return dim
end

function Dialogue:ApplyDim()
    local db = Settings()
    if not self.dim or not db then return end
    self.dim.flat:SetVertexColor(0, 0, 0, (db.dim or 75) / 100 * 0.9)
end

local TEXT_COLORS = {
    white     = { 0.94, 0.93, 0.90 },
    parchment = { 0.96, 0.88, 0.70 },
    silver    = { 0.80, 0.84, 0.90 },
}

local DIALOGUE_STYLES = {
    narci = {},
    glass = { card = { box = "glass" }, option = "glass" },
    classic = {
        card = { box = "gold", bg = { 0.02, 0.02, 0.03 } }, option = "classic",
        name = { 1, 0.82, 0 }, rule = { 1, 0.82, 0 },
    },
    scroll = {
        card = { scene = "parchment", box = "gold", seal = true }, option = "gold",
        name = { 1, 0.86, 0.6 }, rule = { 0.95, 0.75, 0.4 }, title = { 1, 0.92, 0.75 },
    },
    night = {
        card = { scene = "night", box = "flat", tint = { 0.42, 0.46, 0.85 } }, option = "glass",
        name = { 0.8, 0.84, 1 }, rule = { 0.6, 0.65, 1 },
    },
    dawn = {
        card = { scene = "dawn", box = "flat", tint = { 0.9, 0.6, 0.5 } }, option = "glass",
        name = { 1, 0.85, 0.7 }, rule = { 1, 0.7, 0.5 },
    },
    arcane = {
        card = { bg = { 0.05, 0.02, 0.09 }, box = "neon", tint = { 0.62, 0.4, 1 }, mark = true },
        option = "neon", optionTint = { 0.62, 0.4, 1 },
        name = { 0.86, 0.72, 1 }, rule = { 0.7, 0.5, 1 },
    },
}
Dialogue.STYLE_ORDER = { "narci", "glass", "classic", "scroll", "night", "dawn", "arcane" }
Dialogue.STYLES = DIALOGUE_STYLES
Dialogue.STYLE_LABELS = {
    narci = "NarciUI", glass = "Стекло", classic = "Клиент", scroll = "Свиток",
    night = "Ночное небо", dawn = "Рассвет", arcane = "Аркана",
}

function Dialogue:ApplyStyle()
    local db = Settings()
    if not db or not self.panel then return end
    local S = Style()
    local style = DIALOGUE_STYLES[db.style or "narci"] or DIALOGUE_STYLES.narci
    local card = self.panel.card
    local c = style.card
    local alpha = (db.cardAlpha or 92) / 100

    if not c then
        card:Hide()
        card:SetScript("OnUpdate", nil)
    else
        card:Show()
        if c.bg then
            card.bg:SetVertexColor(c.bg[1], c.bg[2], c.bg[3], alpha)
            card.bg:Show()
        else
            card.bg:Hide()
        end
        local scene = c.scene and S.SceneArt(card.art, c.scene)
        if scene then
            card.art:SetVertexColor(1, 1, 1, alpha)
            card.art:Show()
        else
            card.art:Hide()
        end
        S.SkinBox(card, c.box or "none", {
            alpha = alpha, noGround = (c.bg or scene) and true or false,
            edgeSize = 16, glowSize = 10, shadowSize = 14, tint = c.tint,
        })
        if c.seal then
            card.seal:SetTexture(S.Media("MessengerSeal"))
            card.seal:SetSize(70, 70)
            card.seal:ClearAllPoints()
            card.seal:SetPoint("CENTER", card, "TOPRIGHT", -18, -18)
            card.seal:Show()
        else
            card.seal:Hide()
        end
        if c.mark then
            local size = math.min(card:GetWidth() or 400, card:GetHeight() or 400) * 0.9
            card.mark:SetTexture(S.Media("MessengerRunes"))
            card.mark:SetSize(size, size)
            card.mark:SetVertexColor(0.7, 0.5, 1, 0.18)
            card.mark:Show()
            if card.mark.SetRotation then
                local angle = 0
                card:SetScript("OnUpdate", function(_, elapsed)
                    angle = (angle + elapsed * 0.04) % (math.pi * 2)
                    card.mark:SetRotation(angle)
                end)
            end
        else
            card.mark:Hide()
            card:SetScript("OnUpdate", nil)
        end
    end

    local name = style.name or S.ACCENT_GLOW
    self.panel.name:SetTextColor(name[1], name[2], name[3])
    local rule = style.rule
    if rule then
        self.panel.rule:SetGradientAlpha("HORIZONTAL", rule[1], rule[2], rule[3], 0.9, rule[1], rule[2], rule[3], 0)
    else
        self.panel.rule:SetGradientAlpha("HORIZONTAL",
            S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)
    end
    local title = style.title or S.GOLD
    self.panel.title:SetTextColor(title[1], title[2], title[3])

    for _, button in ipairs(self.buttons or {}) do
        local option = style.option
        button.ground:SetShown(not option)
        button.line:SetShown(not option)
        S.SkinBox(button, option or "none", { alpha = 0.88, tint = style.optionTint })
        local keyColor = style.rule or S.ACCENT_GLOW
        button.key:SetTextColor(keyColor[1], keyColor[2], keyColor[3])
    end
end

function Dialogue:ApplyLook()
    local db = Settings()
    if not db then return end
    local S = Style()
    self:ApplyStyle()
    if self.body then
        self.body:SetFont(NS.FONT, NS.FS(db.bodySize or 17), "")
        local c = TEXT_COLORS[db.textColor]
        if db.textColor == "theme" then
            self.body:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        elseif c then
            self.body:SetTextColor(c[1], c[2], c[3])
        end
    end
    if self.panel and self.panel.name then
        self.panel.name:SetFont(NS.FONT, NS.FS(db.nameSize or 28), "")
    end
    if self.stage then
        if self.stage.glow then self.stage.glow:SetShown(db.modelLight ~= false) end
        if db.showModel == false then
            self.stage:SetAlpha(0)
            self.stage:Hide()
        end
    end
end

function Dialogue:BuildStage()
    local S = Style()

    local screen = UIParent:GetHeight() or 768
    local width = math.floor(screen * 0.70)
    local height = math.floor(screen * 1.67)

    local stage = CreateFrame("Frame", "NarciSirus_DialogueStage", UIParent)
    stage:SetFrameStrata("BACKGROUND")
    stage:SetFrameLevel(10)
    stage:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, -math.floor(screen * 0.08))
    stage:SetSize(width, height)
    stage:Hide()

    local light = CreateFrame("Frame", nil, stage)
    light:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMRIGHT", -width, 0)
    light:SetSize(width, screen)

    local glow = light:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(S.GLOW)
    glow:SetBlendMode("ADD")
    glow:SetAllPoints(light)
    glow:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    stage.glow = glow

    local model = CreateFrame("PlayerModel", nil, stage)
    model:SetAllPoints(stage)
    model:SetFrameLevel(stage:GetFrameLevel() + 2)

    stage.model = model
    Fader(stage)

    self.stage = stage
    return stage
end

function Dialogue:BuildTile(index)
    local S = Style()
    local content = self.content

    local tile = CreateFrame("Button", nil, content)
    tile:SetSize(TILE_W, TILE_H)
    tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local ground = tile:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(tile)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("HORIZONTAL", 0.040, 0.046, 0.064, 0.90, 0.018, 0.020, 0.028, 0.35)

    local wash = tile:CreateTexture(nil, "BORDER")
    wash:SetAllPoints(tile)
    wash:SetTexture(WHITE)
    wash:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
    wash:Hide()

    local bar = tile:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 0, 0)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    bar:Hide()

    local slot = CreateFrame("Frame", nil, tile)
    slot:SetSize(TILE_H - 6, TILE_H - 6)
    slot:SetPoint("LEFT", tile, "LEFT", 4, 0)

    local slotGround = slot:CreateTexture(nil, "BACKGROUND")
    slotGround:SetAllPoints(slot)
    slotGround:SetTexture(WHITE)
    slotGround:SetVertexColor(NS.Styling.Tint(0.01, 0.012, 0.018, 1))

    local icon = slot:CreateTexture(nil, "BORDER")
    icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local edges = S.CreateEdges(slot, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

    local count = slot:CreateFontString(nil, "OVERLAY")
    count:SetFont(NS.FONT, NS.FS(11), "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
    count:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])

    local name = tile:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(14), "")
    name:SetPoint("LEFT", slot, "RIGHT", 8, 0)
    name:SetPoint("RIGHT", tile, "RIGHT", -4, 0)
    name:SetJustifyH("LEFT")
    name:SetHeight(TILE_H - 4)

    tile.wash = wash
    tile.bar = bar
    tile.icon = icon
    tile.edges = edges
    tile.count = count
    tile.name = name

    tile:SetScript("OnEnter", function(self)
        self.wash:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        if self.logIndex then
            Dialogue:WithLogEntry(self.logIndex, function()
                if self.kind == "spell" then
                    pcall(GameTooltip.SetQuestLogRewardSpell, GameTooltip)
                else
                    GameTooltip:SetQuestLogItem(self.kind, self.index)
                end
            end)
        elseif self.kind == "spell" then
            if GameTooltip.SetQuestRewardSpell then pcall(GameTooltip.SetQuestRewardSpell, GameTooltip) end
        elseif self.kind then
            GameTooltip:SetQuestItem(self.kind, self.index)
        end

        GameTooltip:Show()
    end)

    tile:SetScript("OnLeave", function(self)
        if not self.selected then self.wash:Hide() end
        GameTooltip:Hide()
    end)

    tile:SetScript("OnClick", function(self)
        if self.kind == "choice" or self.kind == "reward" or self.kind == "required" then
            local link

            if self.logIndex then
                Dialogue:WithLogEntry(self.logIndex, function()
                    link = GetQuestLogItemLink(self.kind, self.index)
                end)
            elseif GetQuestItemLink then
                link = GetQuestItemLink(self.kind, self.index)
            end

            if link and HandleModifiedItemClick and HandleModifiedItemClick(link) then return end
        end

        if self.kind == "choice" and not self.logIndex then Dialogue:Choose(self.index) end
    end)

    self.tiles[index] = tile
    return tile
end

function Dialogue:BuildPanel()
    local S = Style()

    local panel = CreateFrame("Frame", "NarciSirus_DialoguePanel", UIParent)
    panel:SetFrameStrata("HIGH")
    panel:SetSize(PANEL_W, 360)
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 90, -120)
    panel:EnableMouse(true)
    panel:SetFrameLevel(6)
    panel:Hide()

    local card = CreateFrame("Frame", nil, panel)
    card:SetPoint("TOPLEFT", panel, "TOPLEFT", -30, 26)
    card:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 30, -26)
    card:SetFrameLevel(panel:GetFrameLevel() - 1)
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card.bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card.bg:SetTexture(WHITE)
    card.art = card:CreateTexture(nil, "BORDER")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card.mark = card:CreateTexture(nil, "ARTWORK")
    card.mark:SetPoint("CENTER", card, "CENTER", 0, 0)
    card.mark:SetBlendMode("ADD")
    card.seal = card:CreateTexture(nil, "OVERLAY")
    card:Hide()

    local name = panel:CreateFontString(nil, "OVERLAY")
    name:SetFont(NS.FONT, NS.FS(28), "")
    name:SetShadowOffset(1, -1)
    name:SetShadowColor(0, 0, 0, 1)
    name:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    name:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    local rule = panel:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
    rule:SetWidth(PANEL_W * 0.75)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(NS.FONT, NS.FS(18), "")
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 1)
    title:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -8)
    title:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(PANEL_W, 10)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, "OVERLAY")
    body:SetFont(NS.FONT, NS.FS(17), "")
    body:SetShadowOffset(1, -1)
    body:SetShadowColor(0, 0, 0, 1)
    body:SetSpacing(4)
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    body:SetWidth(PANEL_W - 10)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetTextColor(0.94, 0.93, 0.90)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, content:GetHeight() - self:GetHeight())
        local value = math.max(0, math.min(range, self:GetVerticalScroll() - delta * 40))
        self:SetVerticalScroll(value)
    end)

    panel:SetScript("OnMouseUp", function()
        Dialogue:FinishReveal()
    end)

    panel:SetScript("OnUpdate", function(self, step)
        Dialogue:StepReveal(step)
    end)

    panel.name = name
    panel.card = card
    panel.title = title
    panel.scroll = scroll
    panel.rule = rule

    self.panel = panel
    self.content = content
    self.body = body
    self.extras = {}
    self.tiles = {}

    Fader(panel)

    return panel
end

function Dialogue:BuildOptions()
    local S = Style()

    local holder = CreateFrame("Frame", "NarciSirus_DialogueOptions", UIParent)
    holder:SetFrameStrata("HIGH")
    holder:SetSize(OPTION_W, OPTION_H)
    holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 70)
    holder:Hide()

    self.options = holder
    self.buttons = {}

    for index = 1, MAX_OPTIONS do
        local button = CreateFrame("Button", "NarciSirus_DialogueOption" .. index, holder)
        button:SetSize(OPTION_W, OPTION_H)
        button:SetPoint("TOP", holder, "TOP", 0, -(index - 1) * (OPTION_H + 4))

        local ground = button:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints(button)
        ground:SetTexture(WHITE)
        ground:SetGradientAlpha("HORIZONTAL", 0.030, 0.034, 0.048, 0.92, 0.016, 0.018, 0.026, 0.55)

        local wash = button:CreateTexture(nil, "BORDER")
        wash:SetAllPoints(button)
        wash:SetTexture(WHITE)
        wash:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.28,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)
        wash:Hide()

        local bar = button:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        bar:SetTexture(WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        bar:Hide()

        local line = button:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        line:SetTexture(WHITE)
        line:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0)

        local key = button:CreateFontString(nil, "OVERLAY")
        key:SetFont(NS.FONT, NS.FS(13), "")
        key:SetPoint("LEFT", button, "LEFT", 10, 0)
        key:SetWidth(14)
        key:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", key, "RIGHT", 6, 0)

        local text = button:CreateFontString(nil, "OVERLAY")
        text:SetFont(NS.FONT, NS.FS(15), "")
        text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        text:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        text:SetJustifyH("LEFT")
        text:SetHeight(OPTION_H)

        button.wash = wash
        button.ground = ground
        button.line = line
        button.bar = bar
        button.key = key
        button.icon = icon
        button.text = text

        button:SetScript("OnEnter", function(self)
            if not self.enabled then return end
            self.wash:Show()
            self.bar:Show()
        end)

        button:SetScript("OnLeave", function(self)
            self.wash:Hide()
            self.bar:Hide()
        end)

        button:SetScript("OnClick", function(self)
            if not self.enabled or not self.action then return end
            Dialogue:FinishReveal()
            self.action()
        end)

        button:Hide()
        self.buttons[index] = button
    end

    local primary = CreateFrame("Button", "NarciSirus_DialoguePrimary", UIParent)
    primary:SetSize(1, 1)
    primary:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
    primary:SetScript("OnClick", function()
        Dialogue:Primary()
    end)

    self.primary = primary
    Fader(holder)

    return holder
end

function Dialogue:Build()
    if self.built then return end
    self.built = true

    self:BuildDim()
    self:BuildStage()
    self:BuildPanel()
    self:ApplyLook()
    self:BuildOptions()
    self:ApplyStyle()

    self.keyOwner = CreateFrame("Frame")
end

function Dialogue:SetOptions(list)
    local S = Style()
    local count = math.min(#list, MAX_OPTIONS)

    for index = 1, MAX_OPTIONS do
        local button = self.buttons[index]
        local entry = list[index]

        if entry and index <= count then
            button.action = entry.action
            button.enabled = entry.enabled ~= false
            button.key:SetText(index <= KEYED_OPTIONS and tostring(index) or "")
            button.text:SetText(entry.text or "")

            local tone = entry.dim and S.TEXT_DIM or S.TEXT_BRIGHT
            if not button.enabled then tone = S.TEXT_DIM end
            button.text:SetTextColor(tone[1], tone[2], tone[3])

            if entry.icon then
                button.icon:SetTexture(entry.icon)
                button.icon:SetVertexColor(entry.dim and 0.5 or 1, entry.dim and 0.5 or 1, entry.dim and 0.5 or 1)
                button.icon:Show()
            else
                button.icon:SetTexture(nil)
                button.icon:Hide()
            end

            button.wash:Hide()
            button.bar:Hide()
            button:Show()
        else
            button.action = nil
            button:Hide()
        end
    end

    self.options:SetHeight(math.max(1, count * (OPTION_H + 4)))
    self.optionCount = count

    local room = (UIParent:GetHeight() or 768) - 110 - 70 - count * (OPTION_H + 4) - 30
    self.panel:SetHeight(math.max(160, math.min(420, room)))
end

function Dialogue:ClearExtras()
    for _, region in ipairs(self.extras) do region:Hide() end
    for _, tile in ipairs(self.tiles) do
        tile:Hide()
        tile.kind = nil
        tile.selected = nil
    end

    self.extraIndex = 0
    self.tileIndex = 0
end

function Dialogue:Extra(text, size, r, g, b, gap)
    self.extraIndex = self.extraIndex + 1

    local label = self.extras[self.extraIndex]
    if not label then
        label = self.content:CreateFontString(nil, "OVERLAY")
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 1)
        label:SetJustifyH("LEFT")
        label:SetJustifyV("TOP")
        label:SetSpacing(3)
        label:SetWidth(PANEL_W - 10)
        self.extras[self.extraIndex] = label
    end

    label:SetFont(NS.FONT, NS.FS((size or 13) + 2), "")
    label:SetTextColor(r or 0.9, g or 0.9, b or 0.9)
    label:SetText(text)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(self.cursor + (gap or 10)))
    label:Show()

    self.cursor = self.cursor + (gap or 10) + label:GetStringHeight()
    return label
end

function Dialogue:Header(text)
    local S = Style()
    self:Extra(text, 15, S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 16)
end

function Dialogue:Tiles(entries)
    if #entries == 0 then return end

    local top = self.cursor + 6
    local S = Style()

    for position, entry in ipairs(entries) do
        self.tileIndex = self.tileIndex + 1

        local tile = self.tiles[self.tileIndex] or self:BuildTile(self.tileIndex)
        local column = (position - 1) % 2
        local row = math.floor((position - 1) / 2)

        tile:ClearAllPoints()
        tile:SetPoint("TOPLEFT", self.content, "TOPLEFT", column * (TILE_W + 8), -(top + row * (TILE_H + 4)))

        tile.kind = entry.kind
        tile.index = entry.index
        tile.logIndex = entry.logIndex
        tile.selected = nil
        tile.icon:SetTexture(entry.texture)
        tile.icon:SetVertexColor(entry.usable == false and 0.9 or 1, entry.usable == false and 0.2 or 1, entry.usable == false and 0.2 or 1)
        tile.count:SetText(entry.count and entry.count > 1 and entry.count or "")
        tile.name:SetText(entry.name or "")

        local r, g, b = S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]
        if entry.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[entry.quality] then
            local color = ITEM_QUALITY_COLORS[entry.quality]
            r, g, b = color.r, color.g, color.b
        end

        tile.name:SetTextColor(r, g, b)
        for _, line in ipairs(tile.edges) do line:SetVertexColor(r * 0.7, g * 0.7, b * 0.7, 1) end

        tile.wash:Hide()
        tile.bar:Hide()
        tile:Show()
    end

    local rows = math.ceil(#entries / 2)
    self.cursor = top + rows * (TILE_H + 4)
end

local function QuestItems(kind, count, logIndex)
    local list = {}

    for index = 1, count do
        local name, texture, number, quality, usable

        if logIndex and kind == "choice" then
            name, texture, number, quality, usable = GetQuestLogChoiceInfo(index)
        elseif logIndex then
            name, texture, number, quality, usable = GetQuestLogRewardInfo(index)
        else
            name, texture, number, quality, usable = GetQuestItemInfo(kind, index)
        end

        if name then
            list[#list + 1] = {
                kind = kind, index = index, name = name, texture = texture,
                count = number, quality = quality, usable = usable, logIndex = logIndex,
            }
        end
    end

    return list
end

function Dialogue:FindLogEntry(title)
    if not title or title == "" then return end

    for index = 1, GetNumQuestLogEntries() or 0 do
        local logTitle, _, _, _, isHeader = GetQuestLogTitle(index)
        if not isHeader and logTitle == title then return index end
    end
end

function Dialogue:WithLogEntry(index, fn)
    local previous = GetQuestLogSelection and GetQuestLogSelection() or 0

    SelectQuestLogEntry(index)
    local ok, err = pcall(fn)
    SelectQuestLogEntry(previous)

    if not ok and NS.Print then NS.Print("диалог: " .. tostring(err)) end
end

local function RewardData(logIndex)
    local data = {}

    if logIndex then
        data.choices = GetNumQuestLogChoices() or 0
        data.rewards = GetNumQuestLogRewards() or 0
        data.money = GetQuestLogRewardMoney() or 0
        data.xp = GetQuestLogRewardXP and GetQuestLogRewardXP() or 0
        data.honor = GetQuestLogRewardHonor and GetQuestLogRewardHonor() or 0
        data.arena = GetQuestLogRewardArenaPoints and GetQuestLogRewardArenaPoints() or 0
        data.talents = GetQuestLogRewardTalents and GetQuestLogRewardTalents() or 0
        data.title = GetQuestLogRewardTitle and GetQuestLogRewardTitle()
        data.spellTexture, data.spellName = GetQuestLogRewardSpell()
    else
        data.choices = GetNumQuestChoices() or 0
        data.rewards = GetNumQuestRewards() or 0
        data.money = GetRewardMoney() or 0
        data.xp = GetRewardXP and GetRewardXP() or 0
        data.honor = GetRewardHonor and GetRewardHonor() or 0
        data.arena = GetRewardArenaPoints and GetRewardArenaPoints() or 0
        data.talents = GetRewardTalents and GetRewardTalents() or 0
        data.title = GetRewardTitle and GetRewardTitle()
        data.spellTexture, data.spellName = GetRewardSpell()
    end

    if logIndex then
        data.choiceItems = QuestItems("choice", data.choices, logIndex)
        data.rewardItems = QuestItems("reward", data.rewards, logIndex)
    else
        data.choiceItems = QuestItems("choice", data.choices)
        data.rewardItems = QuestItems("reward", data.rewards)
    end

    return data
end

function Dialogue:LogRewards()
    local index = self:FindLogEntry(GetTitleText())
    if not index then return end

    local data
    self:WithLogEntry(index, function() data = RewardData(index) end)

    if data then self:Rewards(data, L["Награда за сдачу"], index) end
end

function Dialogue:Rewards(data, heading, logIndex)
    local S = Style()

    data = data or RewardData()

    local choices = data.choices
    local rewards = data.rewards
    local money = data.money
    local xp = data.xp
    local honor = data.honor
    local arena = data.arena
    local talents = data.talents
    local title = data.title
    local spellTexture, spellName = data.spellTexture, data.spellName

    if choices + rewards == 0 and not spellName and money == 0 and xp == 0
        and honor == 0 and arena == 0 and talents == 0 and not title then
        return
    end

    self:Header(heading or L["Награда"])

    if choices > 0 then
        self:Extra(choices > 1 and L["Выберите одну из наград:"] or L["Вы получите:"], 12,
            S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 6)
        self:Tiles(data.choiceItems)
    end

    local fixed = data.rewardItems

    if spellName then
        fixed[#fixed + 1] = { kind = "spell", index = 1, name = spellName, texture = spellTexture, logIndex = logIndex }
    end

    if #fixed > 0 then
        if choices > 0 then
            self:Extra(L["А также:"], 12, S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 8)
        end
        self:Tiles(fixed)
    end

    local lines = {}
    if money > 0 then lines[#lines + 1] = Coins(money) end
    if xp > 0 then lines[#lines + 1] = xp .. " " .. L["опыта"] end
    if honor > 0 then lines[#lines + 1] = honor .. " " .. L["чести"] end
    if arena > 0 then lines[#lines + 1] = arena .. " " .. L["очков арены"] end
    if talents > 0 then lines[#lines + 1] = talents .. " " .. L["очков талантов"] end
    if title then lines[#lines + 1] = L["Звание"] .. ": " .. title end

    if #lines > 0 then
        self:Extra(table.concat(lines, "     "), 13, S.GOLD[1], S.GOLD[2], S.GOLD[3], 8)
    end
end

function Dialogue:Required()
    local S = Style()
    local count = GetNumQuestItems() or 0
    local money = GetQuestMoneyToGet and GetQuestMoneyToGet() or 0

    if count == 0 and money == 0 then return end

    self:Header(L["Требуется"])

    if money > 0 then
        local tone = money > GetMoney() and { 0.95, 0.35, 0.35 } or S.GOLD
        self:Extra(Coins(money), 13, tone[1], tone[2], tone[3], 6)
    end

    self:Tiles(QuestItems("required", count))
end

function Dialogue:Choose(index)
    self.choice = index

    for _, tile in ipairs(self.tiles) do
        if tile:IsShown() and tile.kind == "choice" then
            tile.selected = tile.index == index or nil
            tile.wash:SetShown(tile.selected and true or false)
            tile.bar:SetShown(tile.selected and true or false)
        end
    end

    if self.mode == "reward" then self:RewardOptions() end
end

function Dialogue:FinishContent()
    self.content:SetHeight(math.max(10, self.cursor + 10))
    self.panel.scroll:SetVerticalScroll(0)
end

function Dialogue:SetBody(text, keepReveal)
    local body = self.body
    text = text or ""

    if keepReveal and self.bodyText == text then
        self.cursor = body:GetStringHeight()
        return
    end

    self.bodyText = text

    body:SetText(text)
    self.cursor = body:GetStringHeight()

    local db = Settings()

    if db.typewriter and text ~= "" then
        self.reveal = 0
        body:SetAlphaGradient(0, GRADIENT)
    else
        self.reveal = nil
        body:SetAlphaGradient(0, 0)
        body:SetAlpha(1)
    end
end

function Dialogue:StepReveal(step)
    if not self.reveal then return end

    self.reveal = self.reveal + REVEAL_SPEED * ((Settings().revealSpeed or 100) / 100) * step

    if not self.body:SetAlphaGradient(self.reveal, GRADIENT) then
        self:FinishReveal()
    end
end

function Dialogue:FinishReveal()
    if not self.reveal then return false end

    self.reveal = nil
    self.body:SetAlphaGradient(0, 0)
    return true
end

function Dialogue:Primary()
    if self:FinishReveal() then return end

    local first = self.buttons and self.buttons[1]
    if first and first:IsShown() and first.enabled and first.action then first.action() end
end

function Dialogue:SetSpeaker(unit, title)
    local panel = self.panel
    local model = self.stage.model

    panel.name:SetText(UnitName(unit) or "")
    panel.title:SetText(title or "")

    if UnitExists(unit) and not UnitIsUnit(unit, "player") then
        local guid = UnitGUID(unit)

        if model.guid ~= guid then
            model.guid = guid
            model:ClearModel()
            model:SetUnit(unit)
            model:SetFacing(-0.55)
        end

        if Settings().showModel ~= false then
            FadeTo(self.stage, 1, 0.35)
        else
            FadeTo(self.stage, 0, 0.2)
        end
    else
        model.guid = nil
        FadeTo(self.stage, 0, 0.2)
    end
end

function Dialogue:BindKeys()
    local db = Settings()
    if not db.keys or self.keysBound or InCombatLockdown() then return end

    self.keysBound = true

    for index = 1, KEYED_OPTIONS do
        SetOverrideBindingClick(self.keyOwner, true, tostring(index), "NarciSirus_DialogueOption" .. index)
    end

    SetOverrideBindingClick(self.keyOwner, true, "SPACE", "NarciSirus_DialoguePrimary")
end

function Dialogue:UnbindKeys()
    if not self.keysBound then return end

    if InCombatLockdown() then
        self.unbindPending = true
        return
    end

    self.keysBound = nil
    ClearOverrideBindings(self.keyOwner)
end

function Dialogue:Open(mode)
    if not Enabled() then return end

    self:Build()

    local opening = not self.active
    self.active = true
    self.mode = mode
    self.closing = nil
    self.choice = nil

    if opening then
        local db = Settings()

        if db.hideInterface and NS.NarciUI and not NS.NarciUI.isShown and NS.NarciUI.HideOtherAddons then
            self.hidHUD = true
            pcall(NS.NarciUI.HideOtherAddons, NS.NarciUI)
            self:HideMinimap()
        end

        self:ApplyDim()
        FadeTo(self.dim, 1, 0.35)
        self:BindKeys()
    end

    FadeTo(self.panel, 1, 0.2)
    FadeTo(self.options, 1, 0.2)

    self:Render(mode)
end

function Dialogue:Render(mode, keepReveal)
    self:ClearExtras()

    if mode ~= "reward" then self.choice = nil end

    if mode == "gossip" then
        self:RenderGossip(keepReveal)
    elseif mode == "greeting" then
        self:RenderGreeting(keepReveal)
    elseif mode == "detail" then
        self:RenderDetail(keepReveal)
    elseif mode == "progress" then
        self:RenderProgress(keepReveal)
    elseif mode == "reward" then
        self:RenderReward(keepReveal)
    end

    self:FinishContent()
end

function Dialogue:RenderGossip(keepReveal)
    self:SetSpeaker("npc")
    self:SetBody(GetGossipText(), keepReveal)

    local list = {}

    local available = { GetGossipAvailableQuests() }
    for index = 1, #available, 5 do
        local title, _, trivial, daily, repeatable = available[index], available[index + 1],
            available[index + 2], available[index + 3], available[index + 4]
        local id = (index - 1) / 5 + 1
        local icon = daily and "DailyQuestIcon" or repeatable and "DailyActiveQuestIcon" or "AvailableQuestIcon"

        list[#list + 1] = {
            text = title, icon = GOSSIP_ICON .. icon, dim = trivial,
            action = function() SelectGossipAvailableQuest(id) end,
        }
    end

    local active = { GetGossipActiveQuests() }
    for index = 1, #active, 4 do
        local title, _, trivial, complete = active[index], active[index + 1], active[index + 2], active[index + 3]
        local id = (index - 1) / 4 + 1

        list[#list + 1] = {
            text = title, icon = GOSSIP_ICON .. (complete and "ActiveQuestIcon" or "IncompleteQuestIcon"),
            dim = trivial,
            action = function() SelectGossipActiveQuest(id) end,
        }
    end

    local options = { GetGossipOptions() }
    for index = 1, #options, 2 do
        local text, kind = options[index], options[index + 1]
        local id = (index - 1) / 2 + 1

        list[#list + 1] = {
            text = text, icon = GOSSIP_ICON .. (kind or "gossip") .. "GossipIcon",
            action = function() SelectGossipOption(id) end,
        }
    end

    list[#list + 1] = { text = L["До свидания"], action = function() CloseGossip() end }

    self:SetOptions(list)
end

function Dialogue:RenderGreeting(keepReveal)
    self:SetSpeaker("questnpc")
    self:SetBody(GetGreetingText(), keepReveal)

    local list = {}
    local numActive = GetNumActiveQuests() or 0
    local numAvailable = GetNumAvailableQuests() or 0

    for index = 1, numActive do
        local title, complete = GetActiveTitle(index)
        list[#list + 1] = {
            text = title, dim = IsActiveQuestTrivial and IsActiveQuestTrivial(index),
            icon = GOSSIP_ICON .. (complete and "ActiveQuestIcon" or "IncompleteQuestIcon"),
            action = function() SelectActiveQuest(index) end,
        }
    end

    for index = 1, numAvailable do
        local trivial, daily, repeatable = GetAvailableQuestInfo(index)
        local icon = daily and "DailyQuestIcon" or repeatable and "DailyActiveQuestIcon" or "AvailableQuestIcon"
        list[#list + 1] = {
            text = GetAvailableTitle(index), dim = trivial, icon = GOSSIP_ICON .. icon,
            action = function() SelectAvailableQuest(index) end,
        }
    end

    list[#list + 1] = { text = L["До свидания"], action = function() QuestGoodbyeButton_OnClick() end }

    self:SetOptions(list)
end

function Dialogue:RenderDetail(keepReveal)
    local S = Style()

    self:SetSpeaker("questnpc", GetTitleText())
    self:SetBody(GetQuestText(), keepReveal)

    local objective = GetObjectiveText()
    if objective and objective ~= "" then
        self:Header(L["Задача"])
        self:Extra(objective, 13, S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3], 4)
    end

    local group = GetSuggestedGroupNum and GetSuggestedGroupNum() or 0
    if group and group > 0 then
        self:Extra(string.format(L["Рекомендуется группа: %d"], group), 12, 0.95, 0.55, 0.35, 8)
    end

    self:Rewards()

    local auto = QuestGetAutoAccept and QuestGetAutoAccept()
    local list = {
        { text = auto and L["Понятно"] or L["Принять задание"], action = function() QuestDetailAcceptButton_OnClick() end },
    }

    if not auto then
        list[#list + 1] = { text = L["Отказаться"], action = function() QuestDetailDeclineButton_OnClick() end }
    end

    self:SetOptions(list)
end

function Dialogue:RenderProgress(keepReveal)
    self:SetSpeaker("questnpc", GetTitleText())
    self:SetBody(GetProgressText(), keepReveal)

    self:Required()
    self:LogRewards()

    local completable = IsQuestCompletable()

    self:SetOptions({
        { text = L["Продолжить"], enabled = completable and true or false,
          action = function() QuestProgressCompleteButton_OnClick() end },
        { text = L["До свидания"], action = function() QuestGoodbyeButton_OnClick() end },
    })
end

function Dialogue:RenderReward(keepReveal)
    self:SetSpeaker("questnpc", GetTitleText())
    self:SetBody(GetRewardText(), keepReveal)

    self:Rewards()

    if self.choice then self:Choose(self.choice) end

    self:RewardOptions()
end

function Dialogue:RewardOptions()
    local choices = GetNumQuestChoices() or 0
    local ready = choices == 0 or (self.choice and self.choice > 0)

    self:SetOptions({
        { text = ready and L["Завершить задание"] or L["Выберите награду"], enabled = ready and true or false,
          action = function()
              if QuestInfoFrame then QuestInfoFrame.itemChoice = Dialogue.choice or 0 end
              QuestRewardCompleteButton_OnClick()
          end },
        { text = L["Позже"], action = function() QuestRewardCancelButton_OnClick() end },
    })
end

function Dialogue:Refresh()
    if not self.active or not self.mode then return end
    self:Render(self.mode, true)
end

function Dialogue:HideMinimap()
    self.hiddenMap = {}

    for _, name in ipairs({ "MinimapCluster", "Minimap", "NarciSirus_MinimapFrame" }) do
        local frame = _G[name]
        if frame and frame:IsShown() then
            frame:Hide()
            self.hiddenMap[#self.hiddenMap + 1] = frame
        end
    end
end

function Dialogue:ShowMinimap()
    for _, frame in ipairs(self.hiddenMap or {}) do frame:Show() end
    self.hiddenMap = nil
end

function Dialogue:Close()
    if not self.active then return end

    self.active = nil
    self.mode = nil
    self.choice = nil
    self.bodyText = nil
    self.reveal = nil

    FadeTo(self.dim, 0, 0.3)
    FadeTo(self.stage, 0, 0.25)
    FadeTo(self.panel, 0, 0.2)
    FadeTo(self.options, 0, 0.2)

    if self.stage then self.stage.model.guid = nil end

    self:UnbindKeys()

    if self.hidHUD then
        self.hidHUD = nil
        if NS.NarciUI and not NS.NarciUI.isShown and NS.NarciUI.RestoreOtherAddons then
            pcall(NS.NarciUI.RestoreOtherAddons, NS.NarciUI)
        end

        self:ShowMinimap()
    end
end

function Dialogue:MaybeClose()
    if not self.active or self.closing or not NS.After then return end

    self.closing = true

    NS.After(0.35, function()
        Dialogue.closing = nil

        local gossip = GossipFrame and GossipFrame:IsShown()
        local quest = QuestFrame and QuestFrame:IsShown()

        if not gossip and not quest then Dialogue:Close() end
    end)
end

local function Usable()
    return Enabled() and not InCombatLockdown()
end

local function Silence(frame)
    if not frame then return end

    if Usable() then
        frame:SetAlpha(0)
        frame:SetScale(0.001)
        frame.narciSilenced = true
    elseif frame.narciSilenced then
        frame.narciSilenced = nil
        frame:SetScale(1)
        frame:SetAlpha(1)
    end
end

function Dialogue:Hook()
    if self.hooked then return end
    self.hooked = true

    if GossipFrame then
        GossipFrame:HookScript("OnShow", Silence)
        GossipFrame:HookScript("OnHide", function() Dialogue:MaybeClose() end)
    end

    if QuestFrame then
        QuestFrame:HookScript("OnShow", Silence)
        QuestFrame:HookScript("OnHide", function() Dialogue:MaybeClose() end)
    end

    if type(_G.GossipFrameUpdate) == "function" then
        hooksecurefunc("GossipFrameUpdate", function()
            if not Enabled() then return end
            if Dialogue.active and Dialogue.mode == "gossip" then
                Dialogue:Refresh()
            elseif Usable() then
                Dialogue:Open("gossip")
            end
        end)
    end

    local panels = {
        QuestFrameGreetingPanel = "greeting",
        QuestFrameDetailPanel = "detail",
        QuestFrameProgressPanel = "progress",
        QuestFrameRewardPanel = "reward",
    }

    for name, mode in pairs(panels) do
        local panel = _G[name]
        if panel then
            panel:HookScript("OnShow", function()
                if Usable() then Dialogue:Open(mode) end
            end)
        end
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("QUEST_ITEM_UPDATE")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")

driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Dialogue:Hook()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        Dialogue:UnbindKeys()
        if Dialogue.active then
            Dialogue:Close()
            for _, frame in ipairs({ GossipFrame, QuestFrame }) do
                if frame and frame.narciSilenced then
                    frame.narciSilenced = nil
                    frame:SetScale(1)
                    frame:SetAlpha(1)
                end
            end
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if Dialogue.unbindPending then
            Dialogue.unbindPending = nil
            Dialogue:UnbindKeys()
        end
        if Dialogue.active then Dialogue:BindKeys() end
        return
    end

    if event == "QUEST_ITEM_UPDATE" and Dialogue.active and Dialogue.mode ~= "gossip" then
        Dialogue:Refresh()
    end
end)
