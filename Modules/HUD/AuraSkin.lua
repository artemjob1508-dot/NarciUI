local addonName, NS = ...
local L = NS.L

local AuraSkin = {}
NS.AuraSkin = AuraSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local MAX_BUFFS = 40
local MAX_DEBUFFS = 16
local MAX_ENCHANTS = 3

local BUFF_NAMES, DEBUFF_NAMES = {}, {}
for index = 1, MAX_BUFFS do BUFF_NAMES[index] = "BuffButton" .. index end
for index = 1, MAX_DEBUFFS do DEBUFF_NAMES[index] = "DebuffButton" .. index end

local function ButtonCount()
    local count = 0
    for index = 1, MAX_BUFFS do
        if _G[BUFF_NAMES[index]] then count = count + 1 end
    end
    for index = 1, MAX_DEBUFFS do
        if _G[DEBUFF_NAMES[index]] then count = count + 100 end
    end
    return count
end

local function FillSettings()
    if not NS.db then return end

    if not NS.db.auras then NS.db.auras = {} end

    local db = NS.db.auras
    if db.enabled == nil then db.enabled = false end
    if db.showTimers == nil then db.showTimers = true end
    db.size = db.size or 30
    db.debuffSize = db.debuffSize or db.size
    db.perRow = db.perRow or 8
    db.grow = db.grow or "left"
    db.timerSize = db.timerSize or 10
    if db.hideLongTimers == nil then db.hideLongTimers = false end
    db.style = db.style or "square"

    if not db.defaultOnV2 then
        db.defaultOnV2 = true
        db.enabled = true
    end

    return db
end

local filledSettings

local function Settings()
    local db = NS.db and NS.db.auras
    if db and db == filledSettings then return db end
    filledSettings = FillSettings()
    return filledSettings
end

local function Enabled()
    local db = Settings()
    return db and db.enabled == true
end

local STYLES = {
    square = true, classic = true, thick = true, glow = true, bar = true, minimal = true,
    pixel = true, neon = true, underline = true,
}
local INSIDE_TIMER = { thick = true, minimal = true }
local GLOW_SIZE = 5

local function AuraStyle()
    local db = Settings()
    return db and STYLES[db.style] and db.style or "square"
end

local function TimerInside(style, db)
    local position = db and db.timerPos or "style"
    if position == "inside" then return true end
    if position == "below" then return false end
    return INSIDE_TIMER[style] and true or false
end

local function CreateGlow(button)
    return NS.Styling.GlowPieces(button, GLOW_SIZE, "BACKGROUND", "ADD", true)
end

local function PaintGlow(glow, r, g, b, a)
    for _, texture in ipairs(glow) do
        texture:SetVertexColor(r, g, b, a)
    end
end

local function Holder()
    if AuraSkin.holder then return AuraSkin.holder end

    local holder = CreateFrame("Frame", "NarciSirus_AuraHolder", UIParent)
    holder:SetFrameStrata("LOW")
    holder:SetSize(300, 70)
    holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -13)
    AuraSkin.holder = holder

    if NS.Movers then
        NS.Movers:Register(holder, L["Бафы"], function(point, relativePoint, x, y)
            local db = Settings()
            if not db then return end
            db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y
        end, "auras")
    end

    return holder
end

local function Attach()
    local anchor = _G.ConsolidatedBuffs
    if not anchor or not AuraSkin.holder then return end

    local db = Settings()
    local corner = (Enabled() and db and db.grow == "right") and "TOPLEFT" or "TOPRIGHT"

    AuraSkin.attaching = true
    anchor:ClearAllPoints()
    anchor:SetPoint(corner, AuraSkin.holder, corner, 0, 0)
    AuraSkin.attaching = nil
end

local GAP = 5

local function PlaceButton(button, slot, size, rowStep, top, db)
    local column = (slot - 1) % db.perRow
    local row = math.floor((slot - 1) / db.perRow)
    local x = column * (size + (db.spacing or GAP))
    local y = -(top + row * rowStep)

    button:ClearAllPoints()
    if db.grow == "right" then
        button:SetPoint("TOPLEFT", AuraSkin.holder, "TOPLEFT", x, y)
    else
        button:SetPoint("TOPRIGHT", AuraSkin.holder, "TOPRIGHT", -x, y)
    end
end

local function FitDF(button, size)
    if not NS.DFUI or not button.narciAura then return end
    button:SetScale(1)
    button:SetSize(size, size)
    AuraSkin:Look(button)
end

function AuraSkin:Layout()
    if not Enabled() or not self.holder or self.laying then return end
    self.laying = true

    local db = Settings()
    local size = db.size
    local style = AuraStyle()
    local timer = (db.showTimers ~= false and not TimerInside(style, db)) and (db.timerSize + 4) or 2
    if style == "bar" then timer = timer + 5 end
    timer = timer + math.max(0, (db.spacing or GAP) - GAP)
    local rowStep = size + timer
    local slot = 0

    local consolidated = _G.ConsolidatedBuffs
    if consolidated and consolidated:IsShown() then slot = slot + 1 end

    for index = 1, MAX_ENCHANTS do
        local button = _G["TempEnchant" .. index]
        if button and button:IsShown() then
            slot = slot + 1
            FitDF(button, size)
            PlaceButton(button, slot, size, rowStep, 0, db)
        end
    end

    for index = 1, MAX_BUFFS do
        local button = _G["BuffButton" .. index]
        if button and button:IsShown() and not button.consolidated then
            slot = slot + 1
            FitDF(button, size)
            PlaceButton(button, slot, size, rowStep, 0, db)
        end
    end

    local rows = math.max(1, math.ceil(slot / db.perRow))
    local top = rows * rowStep + 6
    local debuffSize = db.debuffSize
    local debuffStep = debuffSize + timer
    local debuffs = 0

    for index = 1, MAX_DEBUFFS do
        local button = _G["DebuffButton" .. index]
        if button and button:IsShown() then
            debuffs = debuffs + 1
            FitDF(button, debuffSize)
            PlaceButton(button, debuffs, debuffSize, debuffStep, top, db)
        end
    end

    local width = db.perRow * (math.max(size, debuffSize) + (db.spacing or GAP))
    local height = top + math.max(1, math.ceil(debuffs / db.perRow)) * debuffStep
    self.holder:SetSize(width, height)

    self.laying = nil
end

function AuraSkin:Place()
    local db = Settings()
    if not db or not _G.ConsolidatedBuffs then return end

    local holder = Holder()
    local size = db.size or 30
    local perRow = db.perRow or _G.BUFFS_PER_ROW or 8
    holder:SetSize(perRow * (size + 5), size * 2 + 24)

    holder:ClearAllPoints()
    if db.point then
        holder:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
    else
        holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -13)
    end

    Attach()
    self:Layout()

    if not self.anchorHooked then
        self.anchorHooked = true
        hooksecurefunc(ConsolidatedBuffs, "SetPoint", function()
            if not AuraSkin.attaching then Attach() end
        end)
    end
end

function AuraSkin:ResetPosition()
    local db = Settings()
    if not db then return end

    db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil
    self:Place()
end

function AuraSkin:Move()
    if NS.Movers then NS.Movers:Toggle() end
end

function AuraSkin:PrepareMove()
    if Enabled() then pcall(self.Place, self) end
end

function AuraSkin:SkinButton(button, debuff)
    if not button or button.narciAura then return end
    button.narciAura = true

    local S = NS.Styling
    local name = button:GetName()

    local icon = name and _G[name .. "Icon"]
    local border = name and _G[name .. "Border"]
    if NS.DFUI then
        border = nil
        for _, region in ipairs({ button.DebuffBorder, button.TempEnchantBorder }) do
            region:Hide()
            hooksecurefunc(region, "Show", region.Hide)
        end
    end
    local count = name and _G[name .. "Count"]
    local duration = name and _G[name .. "Duration"]

    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDrawLayer("BORDER")
    end

    if count then count:SetDrawLayer("ARTWORK") end
    if duration then duration:SetDrawLayer("ARTWORK") end

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.02, 0.022, 0.03, 1)

    local edges = S.CreateEdges(button, "OVERLAY", 0, 0, 0, 1)
    button.narciEdges = edges

    if S.CreateSoftShadow then button.narciShadow = S.CreateSoftShadow(button, 3, 0.5) end

    button.narciGround = ground
    button.narciIcon = icon
    button.narciDebuff = debuff and true or false
    button.narciGlow = CreateGlow(button)

    local bar = CreateFrame("StatusBar", nil, button)
    NS.Look:SetBar(bar, "auras", WHITE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetHeight(3)
    bar:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    bar:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -2)
    local barBack = bar:CreateTexture(nil, "BACKGROUND")
    barBack:SetAllPoints(bar)
    barBack:SetTexture(WHITE)
    barBack:SetVertexColor(0, 0, 0, 0.75)
    bar:Hide()
    button.narciBar = bar

    if border then
        border:SetTexture(WHITE)
        border:ClearAllPoints()
        border:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        border:SetHeight(2)
        button.narciBorder = border
    end

    for _, line in ipairs(edges) do
        if debuff then
            line:SetVertexColor(0.70, 0.25, 0.25, 0.95)
        else
            line:SetVertexColor(NS.Look:Border("auras", 0.95))
        end
    end

    if count then
        NS.LSetFont(count, "auras", NS.FS(11), "OUTLINE")
        count:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    end

    if duration then
        NS.LSetFont(duration, "auras", NS.FS(10), "OUTLINE")
        duration:SetTextColor(NS.Look:Text("auras", S.TEXT_BRIGHT))
        duration:ClearAllPoints()
        duration:SetPoint("TOP", button, "BOTTOM", 0, -1)
        button.narciDurationText = duration
    end

    self:Look(button)
end

function AuraSkin:Look(button)
    if not button or not button.narciAura then return end

    local style = AuraStyle()
    local icon = button.narciIcon

    if icon then
        local inset = style == "thick" and 2 or (style == "square" or style == "bar" or style == "pixel" or style == "neon") and 1 or 0
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
        if style == "classic" then
            icon:SetTexCoord(0, 1, 0, 1)
        else
            local zoom = (Settings().iconZoom or 8) / 100
            icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
        end
    end

    button.narciGround:SetShown(style == "square" or style == "thick" or style == "bar" or style == "pixel")
    if button.narciShadow then
        button.narciShadow:SetShown(style == "square" or style == "bar" or style == "thick" or style == "neon")
    end
    if button.narciBorder then button.narciBorder:SetAlpha(style == "square" and 1 or 0) end
    button.narciBar:SetShown(style == "bar")
    for _, texture in ipairs(button.narciGlow) do texture:SetShown(style == "glow" or style == "neon") end

    local edges = button.narciEdges
    local width = (style == "thick" or style == "underline") and 2 or 1
    edges[1]:SetHeight(width)
    edges[2]:SetHeight(width)
    edges[3]:SetWidth(width)
    edges[4]:SetWidth(width)

    local duration = button.narciDurationText
    if duration then
        duration:ClearAllPoints()
        if TimerInside(style, Settings()) then
            duration:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        elseif style == "bar" then
            duration:SetPoint("TOP", button, "BOTTOM", 0, -6)
        else
            duration:SetPoint("TOP", button, "BOTTOM", 0, -1)
        end
    end

    self:Tint(button)
end

function AuraSkin:Apply()
    if not Enabled() then return end

    self.appliedCount = ButtonCount()

    local db = Settings()

    for index = 1, MAX_BUFFS do
        local button = _G["BuffButton" .. index]
        if button then
            self:SkinButton(button, false)
            self:Look(button)
            button:SetSize(db.size, db.size)
        end
    end

    for index = 1, MAX_DEBUFFS do
        local button = _G["DebuffButton" .. index]
        if button then
            self:SkinButton(button, true)
            self:Look(button)
            button:SetSize(db.debuffSize, db.debuffSize)
        end
    end

    for _, prefix in ipairs({ "BuffButton", "DebuffButton", "TempEnchant" }) do
        local count = prefix == "DebuffButton" and MAX_DEBUFFS or (prefix == "TempEnchant" and MAX_ENCHANTS or MAX_BUFFS)
        for index = 1, count do
            local duration = _G[prefix .. index .. "Duration"]
            if duration then
                NS.LSetFont(duration, "auras", db.timerSize, "OUTLINE")
                duration:SetAlpha(db.showTimers ~= false and 1 or 0)
            end
            local count = db.countSize and _G[prefix .. index .. "Count"]
            if count then NS.LSetFont(count, "auras", db.countSize, "OUTLINE") end
        end
    end

    for index = 1, MAX_ENCHANTS do
        local button = _G["TempEnchant" .. index]
        if button then
            self:SkinButton(button, false)
            self:Look(button)
            button:SetSize(db.size, db.size)
        end
    end

    local collapse = _G.CollapseAndExpandButton
    if collapse then collapse:SetAlpha(0.4) end

    if not self.hooked then
        self.hooked = true

        if type(_G.AuraButton_Update) == "function" then
            hooksecurefunc("AuraButton_Update", function(buttonName, index)
                local button = _G[buttonName .. index]
                if button then
                    AuraSkin:SkinButton(button, buttonName == "DebuffButton")
                    AuraSkin:Tint(button)
                end
            end)
        end

        for _, name in ipairs({ "BuffFrame_UpdateAllBuffAnchors", "DebuffButton_UpdateAnchors" }) do
            if type(_G[name]) == "function" then
                hooksecurefunc(name, function() AuraSkin:Layout() end)
            end
        end

        if type(_G.AuraButton_UpdateDuration) == "function" then
            hooksecurefunc("AuraButton_UpdateDuration", function(button, timeLeft)
                AuraSkin:Duration(button, timeLeft)
            end)
        end

        if NS.DFUI then self:HookDF() end
    end
end

function AuraSkin:HookDF()
    for _, frameName in ipairs({ "BuffFrame", "DebuffFrame" }) do
        local frame = _G[frameName]
        if frame then
            for _, method in ipairs({ "UpdateAuraButtons", "UpdateGridLayout" }) do
                if type(frame[method]) == "function" then
                    hooksecurefunc(frame, method, function() AuraSkin:Layout() end)
                end
            end
        end
    end

    for _, prefix in ipairs({ "BuffButton", "DebuffButton", "TempEnchant" }) do
        local count = prefix == "DebuffButton" and MAX_DEBUFFS or (prefix == "TempEnchant" and MAX_ENCHANTS or MAX_BUFFS)
        for index = 1, count do
            local button = _G[prefix .. index]
            if button and not button.narciDFHooked then
                button.narciDFHooked = true
                if type(button.Update) == "function" then
                    hooksecurefunc(button, "Update", function(self) AuraSkin:Tint(self) end)
                end
                if type(button.UpdateDuration) == "function" then
                    hooksecurefunc(button, "UpdateDuration", function(self, timeLeft) AuraSkin:Duration(self, timeLeft) end)
                end
                button:HookScript("OnShow", function() AuraSkin:Layout() end)
                button:HookScript("OnHide", function() AuraSkin:Layout() end)
            end
        end
    end

    self:Layout()
end

function AuraSkin:Tint(button)
    local border = button.narciBorder
    local edges = button.narciEdges
    if not edges then return end

    local S = NS.Styling
    local style = AuraStyle()

    local r, g, b
    if border and border:IsShown() then
        r, g, b = border:GetVertexColor()
    elseif NS.DFUI and button.auraType == "Debuff" and _G.DebuffTypeColor then
        local info = button.buttonInfo
        local color = DebuffTypeColor[info and info.debuffType or "none"] or DebuffTypeColor.none
        if color then r, g, b = color.r, color.g, color.b end
    end

    local framed = style == "square" or style == "thick" or style == "bar" or style == "pixel" or style == "neon"
        or (style == "classic" and r ~= nil)
    for index, line in ipairs(edges) do line:SetShown(framed or (style == "underline" and index == 2)) end

    if r then
        for _, line in ipairs(edges) do line:SetVertexColor(r, g, b, 1) end
    elseif style == "thick" or style == "pixel" then
        for _, line in ipairs(edges) do line:SetVertexColor(0, 0, 0, 1) end
    elseif (style == "neon" or style == "underline") and not NS.Look:Color("auras", "border") then
        for _, line in ipairs(edges) do line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1) end
    elseif style == "thick" then
        for _, line in ipairs(edges) do line:SetVertexColor(0, 0, 0, 1) end
    else
        for _, line in ipairs(edges) do line:SetVertexColor(NS.Look:Border("auras", 0.95)) end
    end

    if (style == "glow" or style == "neon") and button.narciGlow then
        if r then
            PaintGlow(button.narciGlow, r, g, b, 0.75)
        else
            PaintGlow(button.narciGlow, S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.45)
        end
    end

    if style == "bar" and button.narciBar then
        if r then
            button.narciBar:SetStatusBarColor(r, g, b, 1)
        else
            button.narciBar:SetStatusBarColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        end
    end
end

function AuraSkin:Duration(button, timeLeft)
    if not button or not button.narciAura or (not button.narciSample and not Enabled()) then return end

    local duration = button.narciDuration
    if duration == nil then
        local name = button:GetName()
        duration = button.duration or (name and _G[name .. "Duration"]) or false
        button.narciDuration = duration
        button.narciIsDebuff = name and name:find("^DebuffButton") and true or false
    end
    local bar = button.narciBar
    if bar and bar:IsShown() then
        if not timeLeft or timeLeft <= 0 then
            button.narciMax = nil
            bar:SetValue(1)
        else
            if not button.narciMax or timeLeft > button.narciMax + 0.5 then button.narciMax = timeLeft end
            bar:SetValue(timeLeft / button.narciMax)
        end
    end

    if not duration or not timeLeft then return end

    local db = Settings()

    if db.hideLongTimers and timeLeft >= (db.longAt or 10) * 60 and not button.narciIsDebuff then
        duration:SetText("")
        return
    end

    local key
    if timeLeft >= 3600 then
        key = 3000000 + math.floor(timeLeft / 3600 + 0.5)
    elseif timeLeft >= 60 then
        key = 2000000 + math.floor(timeLeft / 60 + 0.5)
    elseif timeLeft >= 10 then
        key = 1000000 + math.floor(timeLeft)
    else
        key = math.floor(timeLeft * 10 + 0.5)
    end

    if key ~= button.narciTimeKey then
        button.narciTimeKey = key

        if timeLeft >= 3600 then
            button.narciTimeText = math.floor(timeLeft / 3600 + 0.5) .. L["ч"]
        elseif timeLeft >= 60 then
            button.narciTimeText = math.floor(timeLeft / 60 + 0.5) .. L["м"]
        elseif timeLeft >= 10 then
            button.narciTimeText = tostring(math.floor(timeLeft))
        else
            button.narciTimeText = string.format("%.1f", timeLeft)
        end
    end

    duration:SetText(button.narciTimeText)

    if timeLeft <= (db.warnAt or 5) then
        duration:SetTextColor(0.95, 0.35, 0.35)
    elseif AuraStyle() == "classic" then
        duration:SetTextColor(1, 0.82, 0)
    else
        local S = NS.Styling
        duration:SetTextColor(NS.Look:Text("auras", S.TEXT_BRIGHT))
    end
end

local SAMPLE_AURAS = {
    { "Interface\\Icons\\Spell_Holy_WordFortitude", 1500 },
    { "Interface\\Icons\\Spell_Holy_MagicalSentry", 640 },
    { "Interface\\Icons\\Spell_Nature_Regeneration", 95 },
    { "Interface\\Icons\\Spell_Holy_Renew", 4.2, 3 },
    { "Interface\\Icons\\Spell_Shadow_ShadowWordPain", 12, nil, true },
}

function AuraSkin:CreateSample(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(260, 90)
    holder.buttons = {}
    for index, data in ipairs(SAMPLE_AURAS) do
        local name = "NarciSirus_AuraSample" .. index
        local button = CreateFrame("Button", name, holder)
        local icon = button:CreateTexture(name .. "Icon", "ARTWORK")
        icon:SetAllPoints(button)
        icon:SetTexture(data[1])
        local count = button:CreateFontString(name .. "Count", "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        if data[3] then count:SetText(data[3]) end
        local duration = button:CreateFontString(name .. "Duration", "OVERLAY", "GameFontNormalSmall")
        if data[4] then
            local border = button:CreateTexture(name .. "Border", "OVERLAY")
            border:SetAllPoints(button)
        end
        button.narciSample = true
        self:SkinButton(button, data[4])
        if button.narciBorder then button.narciBorder:SetVertexColor(0.8, 0.1, 0.1) end
        holder.buttons[index] = button
    end
    return holder
end

function AuraSkin:PaintSample(holder)
    local db = Settings()
    if not db or not holder then return end
    local style = AuraStyle()
    local timer = (db.showTimers ~= false and not TimerInside(style, db)) and (db.timerSize + 4) or 2
    if style == "bar" then timer = timer + 5 end
    local size = math.min(db.size or 30, 40)
    local x = 0
    for index, button in ipairs(holder.buttons) do
        local data = SAMPLE_AURAS[index]
        local s = data[4] and math.min(db.debuffSize or size, 40) or size
        button:SetSize(s, s)
        button:ClearAllPoints()
        if db.grow == "right" then
            button:SetPoint("TOPLEFT", holder, "TOPLEFT", data[4] and 0 or x, data[4] and -(size + timer + 6) or 0)
        else
            button:SetPoint("TOPRIGHT", holder, "TOPRIGHT", data[4] and 0 or -x, data[4] and -(size + timer + 6) or 0)
        end
        if not data[4] then x = x + s + (db.spacing or GAP) end
        self:Look(button)
        local duration = button.narciDurationText
        if duration then
            NS.LSetFont(duration, "auras", db.timerSize or 10, "OUTLINE")
            duration:SetShown(db.showTimers ~= false)
        end
        button.narciTimeKey = nil
        button.narciMax = nil
        self:Duration(button, data[2])
        if button.narciBar then button.narciBar:SetValue(index / 5) end
    end
    holder:SetSize(math.max(x, 1), size * 2 + timer * 2 + 6)
end

function AuraSkin:Toggle()
    local db = Settings()
    if not db then return end

    db.enabled = not Enabled()

    if db.enabled then
        self:Apply()
        NS.Print("бафы в стиле аддона")
    else
        NS.Print("бафы вернутся к клиентским после /reload")
    end
end

function AuraSkin:SetOption(field, value)
    local db = Settings()
    if not db then return end

    db[field] = value
    self:Apply()
    self:Place()
    self:Layout()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("UNIT_AURA")

driver:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        AuraSkin:Place()
        if NS.After then
            NS.After(2, function()
                AuraSkin:Apply()
                AuraSkin:Place()
            end)
        end
        return
    end

    if not Enabled() then return end

    if unit == "player" and ButtonCount() ~= AuraSkin.appliedCount then AuraSkin:Apply() end
end)
