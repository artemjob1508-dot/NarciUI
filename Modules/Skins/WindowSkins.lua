local addonName, NS = ...

local WindowSkins = {}
NS.WindowSkins = WindowSkins

local WHITE = "Interface\\Buttons\\WHITE8x8"

local DIM_PATHS = {
    "ui%-readycheckframe",
    "ui%-tradeframe%-top",
    "ui%-tradeframe%-bot",
    "ui%-questitemnameframe",
    "ui%-character%-skills%-barborder",
    "ui%-character%-scrollbar",
    "tradeskillframe[/\\]tradeskills",
    "ui%-emptyslot",
    "ui%-questlogsorttab",
    "ui%-classtrainer%-expandtab",
    "lich_king",
    "ui%-tooltip%-border",
}

local function Kit()
    return NS.SkinKit
end

local function Mail()
    return NS.MailSkin
end

local function Style()
    return NS.Styling
end

local function Flag(key)
    return not NS.db or NS.db[key] ~= false
end

local function DimByPath(frame)
    if not frame or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" and not region.narciKeepVisible then
            local ok, path = pcall(region.GetTexture, region)
            path = ok and type(path) == "string" and path:lower()

            if path then
                for _, pattern in ipairs(DIM_PATHS) do
                    if path:find(pattern) then
                        region:SetAlpha(0)
                        break
                    end
                end
            end
        end
    end
end

local function DimTree(frame, depth)
    Kit().Walk(frame, depth or 4, DimByPath)
end

local function Shell(frame, left, top, right, bottom)
    if frame.narciShell then return frame.narciShell end

    local shell = CreateFrame("Frame", nil, frame)
    shell:SetPoint("TOPLEFT", frame, "TOPLEFT", left, top)
    shell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", right, bottom)
    shell:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
    shell:EnableMouse(false)

    Kit().Window(shell, { inset = 16, depth = 0 })
    shell.narciOwn = true

    frame.narciShell = shell
    return shell
end

local function Ring(texture, parent, size)
    if not texture or texture.narciRing then return end

    local S = Style()
    local ring = parent:CreateTexture(nil, "OVERLAY")
    ring:SetPoint("CENTER", texture, "CENTER", 0, 0)
    ring:SetSize(size, size)
    ring:SetTexture(S.Media("PortraitRing"))
    ring:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    texture.narciRing = ring
end

local function Bright(fontString)
    if not fontString then return end
    local S = Style()
    fontString:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
end

local function Plate(parent, left, right)
    local S = Style()
    local plate = parent:CreateTexture(nil, "BACKGROUND")
    plate:SetPoint("TOPLEFT", left, "TOPRIGHT", 4, 0)
    plate:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", 0, 0)
    plate:SetTexture(WHITE)
    plate:SetGradientAlpha("HORIZONTAL", 0.06, 0.065, 0.09, 0.85, 0.03, 0.033, 0.045, 0.35)
    plate.narciKeepVisible = true
    return plate
end

local function QualityEdges(button, link)
    if not button or not button.narciEdges then return end

    local quality = link and select(3, GetItemInfo(link))
    if quality and quality > 1 then
        Mail().PaintSlotColor(button, GetItemQualityColor(quality))
    else
        Mail().PaintSlotColor(button)
    end
end

local function SkinReadyCheck()
    local frame = _G.ReadyCheckListenerFrame
    if not frame then return end

    if not frame.narciDone then
        frame.narciDone = true

        DimByPath(frame)
        Shell(frame, 0, 0, 0, 0)
        Ring(_G.ReadyCheckPortrait, frame, 64)

        Kit().Button(_G.ReadyCheckFrameYesButton)
        Kit().Button(_G.ReadyCheckFrameNoButton)
    end

    Bright(_G.ReadyCheckFrameText)
end

local function SkinTrade()
    local frame = _G.TradeFrame
    if not frame then return end

    if not frame.narciDone then
        frame.narciDone = true

        DimTree(frame, 3)
        local shell = Shell(frame, 2, -2, -34, 46)
        Ring(_G.TradeFramePlayerPortrait, frame, 76)
        Ring(_G.TradeFrameRecipientPortrait, frame, 76)

        for i = 1, (_G.MAX_TRADE_ITEMS or 7) do
            for _, side in ipairs({ "TradePlayerItem", "TradeRecipientItem" }) do
                local holder = _G[side .. i]
                local button = _G[side .. i .. "ItemButton"]
                local nameFrame = _G[side .. i .. "NameFrame"]

                if button then Mail().Slot(button) end
                if nameFrame then nameFrame:SetAlpha(0) end
                if holder and button and nameFrame then
                    local plate = Plate(holder, button, nameFrame)
                    plate:ClearAllPoints()
                    plate:SetPoint("TOPLEFT", button, "TOPRIGHT", 4, 0)
                    plate:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 4, 0)
                    plate:SetWidth(108)
                end
            end
        end

        local close = _G.TradeFrameCloseButton
        if close then
            Kit().Close(close)
            close:ClearAllPoints()
            close:SetPoint("TOPRIGHT", shell, "TOPRIGHT", -4, -4)
        end

        Kit().Button(_G.TradeFrameTradeButton)
        Kit().Button(_G.TradeFrameCancelButton)

        for _, key in ipairs({ "Gold", "Silver", "Copper" }) do
            Kit().EditBox(_G["TradePlayerInputMoneyFrame" .. key])
        end

        if type(_G.TradeFrame_UpdatePlayerItem) == "function" then
            hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
                QualityEdges(_G["TradePlayerItem" .. id .. "ItemButton"], GetTradePlayerItemLink(id))
            end)
        end
        if type(_G.TradeFrame_UpdateTargetItem) == "function" then
            hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
                QualityEdges(_G["TradeRecipientItem" .. id .. "ItemButton"], GetTradeTargetItemLink(id))
            end)
        end
    end

    Bright(_G.TradeFramePlayerNameText)
    Bright(_G.TradeFrameRecipientNameText)
end

local function SkinTradeSkill()
    local frame = _G.TradeSkillFrame
    if not frame then return end

    if not frame.narciDone then
        frame.narciDone = true

        Mail().Window(frame)

        for _, inset in ipairs({ frame.RecipeInset, frame.DetailsInset }) do
            if inset then
                Kit().Strip(inset, 1)
                Mail().Hide(inset.NineSlice)
                Mail().Hide(inset.Bg)
                Kit().Inset(inset, 0.3)
                Kit().Edges(inset, 16, 0.28)
            end
        end

        local icon = _G.TradeSkillSkillIcon
        if icon then Mail().Slot(icon, true) end

        for i = 1, 8 do
            local reagent = _G["TradeSkillReagent" .. i]
            local nameFrame = _G["TradeSkillReagent" .. i .. "NameFrame"]
            local reagentIcon = _G["TradeSkillReagent" .. i .. "IconTexture"]
            if reagent and not reagent.narciReagent then
                reagent.narciReagent = true
                reagent.narciOwn = true
                if nameFrame then nameFrame:SetAlpha(0) end
                local S = Style()
                local plate = reagent:CreateTexture(nil, "BACKGROUND")
                plate:SetAllPoints(reagent)
                plate:SetTexture(WHITE)
                plate:SetVertexColor(0.05, 0.055, 0.075, 0.7)
                S.RoundTexture(plate, 4)
                if reagentIcon then
                    reagentIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    local holder = CreateFrame("Frame", nil, reagent)
                    holder:SetAllPoints(reagentIcon)
                    reagent.narciEdges = S.CreateEdges(holder, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
                end
            end
        end

        if type(_G.TradeSkillFrame_SetSelection) == "function" then
            hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
                if not frame.narciDone then return end
                QualityEdges(_G.TradeSkillSkillIcon, GetTradeSkillItemLink(id))
                for i = 1, (GetTradeSkillNumReagents(id) or 0) do
                    QualityEdges(_G["TradeSkillReagent" .. i], GetTradeSkillReagentItemLink(id, i))
                end
            end)
        end
    end

    DimTree(frame, 8)
    Kit().Auto(frame, 8)
end

local function SkinLootTracker()
    local frame = _G.RR_LOOT_FRAME
    if not frame then return end

    if not frame.narciDone then
        frame.narciDone = true

        local S = Style()
        for i = 1, 4 do
            local button = _G["RR_LootIcon" .. i]
            if button then
                button.narciOwn = true
                S.CreateEdges(button, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
            end
        end

        Kit().Window(frame, { inset = 16, depth = 3 })
        if _G.Close_Button then Kit().Close(_G.Close_Button) end
    end

    DimTree(frame, 3)
    Kit().Auto(frame, 3)
end

local CORNER_SUFFIXES = { "%-topleft$", "%-topright$", "%-botleft$", "%-botright$", "%-bottomleft$", "%-bottomright$" }

local function HideArt(frame, patterns)
    if not frame or not frame.GetRegions then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" and not region.narciKeepVisible then
            local ok, path = pcall(region.GetTexture, region)
            path = ok and type(path) == "string" and path:lower():gsub("/", "\\")
            if path then
                local hit
                for _, suffix in ipairs(CORNER_SUFFIXES) do
                    if path:find(suffix) then hit = true break end
                end
                if not hit then
                    for _, pattern in ipairs(patterns or {}) do
                        if path:find(pattern) then hit = true break end
                    end
                end
                if hit then region:SetAlpha(0) end
            end
        end
    end
end

local function DarkText(frame, depth)
    local S = Style()
    Kit().Walk(frame, depth or 3, function(node)
        if not node.GetRegions then return end
        for _, region in ipairs({ node:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                local r, g, b = region:GetTextColor()
                if r and (r + g + b) < 0.9 then
                    region:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
                end
            end
        end
    end)
end

local function IsTemplated(frame)
    return frame.NineSlice or frame.TopTileStreaks or frame.Inset or frame.PortraitContainer or frame.portrait
end

local function TitleOf(frame)
    local name = frame:GetName()
    return frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText) or (name and _G[name .. "TitleText"])
end

local function CloseOf(frame)
    local name = frame:GetName()
    return frame.CloseButton or (name and (_G[name .. "CloseButton"] or _G[name .. "Close"]))
end

local function Modern(frame)
    Mail().Window(frame)
    Mail().Hide(frame.PortraitOverlay)
    if frame.PortraitContainer then frame.PortraitContainer:SetAlpha(0) end
    if frame.TitleContainer then Kit().Strip(frame.TitleContainer, 1) end
    return frame
end

local function Legacy(frame, spec)
    HideArt(frame, spec.art)
    local left, right, top, bottom = 0, 0, 0, 0
    if frame.GetHitRectInsets then left, right, top, bottom = frame:GetHitRectInsets() end
    local box = spec.box or { 11 + left, -12 - top, -2 - right, 4 + bottom }
    local shell = Shell(frame, box[1], box[2], box[3], box[4])
    if spec.portrait ~= false then
        local name = frame:GetName()
        local portrait = spec.portrait or (name and _G[name .. "Portrait"])
        if portrait then Ring(portrait, frame, 70) end
    end
    return shell
end

local function Panel(frame, spec)
    if not frame then return end
    spec = spec or {}
    if not frame.narciDone then
        frame.narciDone = true
        for _, own in ipairs(spec.own or {}) do
            local region = type(own) == "string" and _G[own] or own
            if region then region.narciOwn = true end
        end
        if spec.before then spec.before(frame) end
        local body
        if spec.art then HideArt(frame, spec.art) end
        if not spec.legacy and IsTemplated(frame) then
            body = Modern(frame)
        else
            body = Legacy(frame, spec)
        end
        frame.narciBody = body
        local close = spec.close or CloseOf(frame)
        if close then
            Kit().Close(close)
            if body ~= frame then
                close:ClearAllPoints()
                close:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4, -4)
            end
        end
        if spec.after then spec.after(frame, body) end
    end
    local title = TitleOf(frame)
    if title then
        local S = Style()
        title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end
    DimTree(frame, spec.dimDepth or 4)
    Kit().Auto(frame, spec.depth or 5)
    if spec.darkText then DarkText(frame, spec.textDepth or 4) end
    if spec.each then spec.each(frame) end
end

local function SlotList(prefix, count, quality)
    for i = 1, count do
        local button = _G[prefix .. i]
        if button and not button.narciMailSlot then
            Mail().Slot(button)
            local nameFrame = _G[prefix .. i .. "NameFrame"]
            if nameFrame then nameFrame:SetAlpha(0) end
        end
    end
end

local function PaintLoot()
    for i = 1, (_G.LOOTFRAME_NUMBUTTONS or 4) do
        local button = _G["LootButton" .. i]
        if button and button.narciEdges then
            local quality = button.quality
            if not quality and button.slot and GetLootSlotInfo then
                quality = select(4, GetLootSlotInfo(button.slot))
            end
            if quality and quality > 1 then
                Mail().PaintSlotColor(button, GetItemQualityColor(quality))
            else
                Mail().PaintSlotColor(button)
            end
        end
    end
end

local function SkinLoot()
    Panel(_G.LootFrame, {
        art = { "ui%-lootpanel", "targetdead" },
        box = { 12, -14, -72, 10 },
        portrait = false,
        close = _G.LootCloseButton,
        before = function()
            SlotList("LootButton", _G.LOOTFRAME_NUMBUTTONS or 4)
            Mail().Hide(_G.LootFramePortraitOverlay)
        end,
        after = function()
            for _, fn in ipairs({ "LootFrame_Update", "LootFrame_UpdateButton" }) do
                if type(_G[fn]) == "function" then hooksecurefunc(fn, PaintLoot) end
            end
        end,
        each = PaintLoot,
    })
end

local function SkinDressUp()
    Panel(_G.DressUpFrame, {
        own = { "DressUpModel" },
        depth = 4,
        before = function(frame)
            if frame.ModelScene then frame.ModelScene.narciOwn = true end
        end,
    })
end

local function PaintItemText()
    local S = Style()
    local text = _G.ItemTextPageText
    if text then
        pcall(text.SetTextColor, text, S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        for _, element in ipairs({ "p", "h1", "h2", "h3" }) do
            pcall(text.SetTextColor, text, element, S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end
    end
    for _, key in ipairs({ "ItemTextMaterialTopLeft", "ItemTextMaterialTopRight", "ItemTextMaterialBotLeft", "ItemTextMaterialBotRight", "ItemTextFramePageBg" }) do
        Mail().Hide(_G[key])
    end
end

local function SkinItemText()
    Panel(_G.ItemTextFrame, {
        art = { "ui%-itemtext%-", "spellbook%-icon", "ui%-spellbookpanel%-" },
        portrait = false,
        after = function()
            if type(_G.ItemTextFrame_OnEvent) == "function" then
                hooksecurefunc("ItemTextFrame_OnEvent", PaintItemText)
            end
        end,
        each = PaintItemText,
    })
end

local function SkinTaxi()
    Panel(_G.TaxiFrame, { own = { "TaxiRouteMap", "TaxiMap" }, depth = 3 })
end

local function SkinTabard()
    Panel(_G.TabardFrame, {
        art = { "ui%-character%-general", "ui%-classtrainer%-bot" },
        own = { "TabardModel" },
        darkText = true,
    })
end

local function QuestLike(name)
    return function()
        Panel(_G[name], {
            art = { "ui%-questgreeting%-" },
            legacy = true,
            darkText = true,
        })
    end
end

local function SkinPetStable()
    Panel(_G.PetStableFrame, {
        own = { "PetStableModel" },
        before = function()
            for i = 1, 20 do
                local button = _G["PetStableStabledPet" .. i]
                if button then Mail().Slot(button, true) end
            end
            if _G.PetStableCurrentPet then Mail().Slot(_G.PetStableCurrentPet, true) end
        end,
    })
end

local function SkinSocketing()
    Panel(_G.ItemSocketingFrame, {
        art = { "ui%-itemsocketingframe" },
        box = { 11, -12, -2, 2 },
        legacy = true,
        own = { "ItemSocketingSocket1", "ItemSocketingSocket2", "ItemSocketingSocket3", "ItemSocketingDescription" },
        darkText = true,
    })
end

local function SkinGuildBank()
    Panel(_G.GuildBankFrame, {
        art = { "ui%-guildbankframe%-left", "ui%-guildbankframe%-right", "ui%-guildbankframe%-emblemborder", "ui%-tabnameborder" },
        box = { 2, -2, -2, 2 },
        legacy = true,
        before = function()
            for column = 1, 7 do
                local holder = _G["GuildBankColumn" .. column]
                if holder then
                    HideArt(holder, { "ui%-guildbankframe%-slots" })
                    SlotList("GuildBankColumn" .. column .. "Button", 14)
                end
            end
            for tab = 1, 8 do
                local side = _G["GuildBankTab" .. tab]
                if side then
                    HideArt(side, { "ui%-guildbankframe%-tab" })
                    local button = _G["GuildBankTab" .. tab .. "Button"]
                    if button then Mail().Slot(button, true) end
                end
            end
        end,
    })
end

local function SkinScore()
    Panel(_G.WorldStateScoreFrame, {
        art = { "ui%-background%-rock", "shadowoverlay" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
    })
end

local function SkinMiniGameScore()
    Panel(_G.MiniGameScoreFrame)
end

local function SkinTimeManager()
    Panel(_G.TimeManagerFrame, {
        art = { "ui%-character%-general" },
        box = { 7, -8, -38, -23 },
        legacy = true,
        portrait = _G.TimeManagerGlobe,
    })
end

local function SkinStopwatch()
    Panel(_G.StopwatchFrame, {
        art = { "timerbackground" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
        close = _G.StopwatchCloseButton,
        before = function()
            local tab = _G.StopwatchTabFrame
            if tab then HideArt(tab, { "timerbackground", "chatframetab" }) end
        end,
    })
end

local function SkinCalendar()
    Panel(_G.CalendarFrame, {
        art = { "calendarframe_" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
        depth = 2,
        before = function()
            for i = 1, 42 do
                local day = _G["CalendarDayButton" .. i]
                if day then day.narciOwn = true end
            end
        end,
    })
end

local function SkinDeathRecap()
    Panel(_G.DeathRecapFrame, {
        art = { "raidborder", "durability\\deathrecap" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
    })
end

local function SkinItemUpgrade()
    Panel(_G.ItemUpgradeFrame, { own = { "ItemUpgradeFrameItemButton" } })
end

local function SkinChatConfig()
    local frame = _G.ChatConfigFrame
    if not frame then return end
    if not frame.narciDone then
        frame.narciDone = true
        Mail().Hide(_G.ChatConfigFrameHeader)
        Kit().Window(frame, { inset = 18, depth = 3 })
        local title = _G.ChatConfigFrameHeaderText
        if title then
            local S = Style()
            title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        end
    end
    Kit().Auto(frame, 6)
end

local function SkinBattlefieldMinimap()
    local frame = _G.BattlefieldMinimap
    if not frame then return end
    if not frame.narciDone then
        frame.narciDone = true
        Mail().Hide(_G.BattlefieldMinimapCorner)
        Mail().Hide(_G.BattlefieldMinimapBackground)
        local S = Style()
        local edges = CreateFrame("Frame", nil, frame)
        edges:SetPoint("TOPLEFT", _G.BattlefieldMinimap1 or frame, "TOPLEFT", -1, 1)
        edges:SetPoint("BOTTOMRIGHT", _G.BattlefieldMinimap12 or frame, "BOTTOMRIGHT", 1, -1)
        S.CreateEdges(edges, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
        S.CreateSoftShadow(edges, 6, 0.6)
        if _G.BattlefieldMinimapCloseButton then Kit().Close(_G.BattlefieldMinimapCloseButton) end
        local tab = _G.BattlefieldMinimapTab
        if tab then
            HideArt(tab, { "chatframetab" })
            for _, key in ipairs({ "BattlefieldMinimapTabLeft", "BattlefieldMinimapTabMiddle", "BattlefieldMinimapTabRight" }) do
                Mail().Hide(_G[key])
            end
            local plate = tab:CreateTexture(nil, "BACKGROUND")
            plate:SetAllPoints(tab)
            plate:SetTexture(WHITE)
            plate:SetVertexColor(S.Tint(0.03, 0.03, 0.05, 0.85))
            S.RoundTexture(plate, 4)
        end
    end
end

WindowSkins.EXTRA = {
    { flag = "skinLootWindow",   label = "Окно добычи" },
    { flag = "skinDressUp",      label = "Примерочная" },
    { flag = "skinItemText",     label = "Книги и письма" },
    { flag = "skinTaxi",         label = "Карта полётов" },
    { flag = "skinTabard",       label = "Гербы гильдии" },
    { flag = "skinCharters",     label = "Хартии и регистраторы" },
    { flag = "skinPetStable",    label = "Стойла питомцев" },
    { flag = "skinSocketing",    label = "Вставка камней" },
    { flag = "skinGuildBank",    label = "Гильдейский банк" },
    { flag = "skinScore",        label = "Таблица поля боя и мини-игр" },
    { flag = "skinTimeManager",  label = "Часы и секундомер" },
    { flag = "skinCalendar",     label = "Календарь" },
    { flag = "skinDeathRecap",   label = "Отчёт о смерти" },
    { flag = "skinItemUpgrade",  label = "Улучшение предметов" },
    { flag = "skinChatConfig",   label = "Настройки чата" },
    { flag = "skinBattleMap",    label = "Карта поля боя" },
}

local function SkinPKBT(name)
    return function()
        local frame = _G[name]
        if frame and NS.StoreSkin and NS.StoreSkin.Generic then NS.StoreSkin.Generic(frame) end
    end
end

local function SkinAlliedRaces()
    Panel(_G.AlliedRacesFrame, { own = { "AlliedRacesFrameModelScene" }, depth = 4 })
end

local function SkinLootCase()
    Panel(_G.LootCasePreviewFrame, { depth = 5 })
end

local function SkinBlackMarket()
    Panel(_G.BlackMarketFrame, {
        art = { "blackmarket\\blackmarketbackground", "woodframe" },
        depth = 6,
        before = function(frame)
            if frame.art then Mail().Hide(frame.art) end
        end,
    })
end

local function SkinChooseItem()
    Panel(_G.ChooseItemFrame, {
        art = { "questionframe\\", "questchoice" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
        close = _G.ChooseItemFrame and (_G.ChooseItemFrame.CloseButton or _G.CloseButton),
        before = function(frame)
            for _, key in ipairs({ "BG", "LeftHide", "LeftHide2", "RightHide", "RightHide2", "BottomHide", "BottomHide2", "TopBorder", "BottomBorder", "LeftBorder", "RightBorder" }) do
                Mail().Hide(frame[key])
            end
        end,
        darkText = true,
    })
end

local function SkinArtWindow(name, hide)
    return function()
        local frame = _G[name]
        if not frame then return end
        if not frame.narciDone then
            frame.narciDone = true
            for _, key in ipairs(hide or {}) do
                Mail().Hide(frame[key] or _G[name .. key])
            end
            Kit().Window(frame, { inset = 18, depth = 0 })
            local close = CloseOf(frame)
            if close then Kit().Close(close) end
        end
    end
end

local function SkinPVPBanner()
    Panel(_G.PVPBannerFrame, {
        art = { "ui%-character%-general", "ui%-classtrainer%-bot" },
        own = { "PVPBannerFrameStandardBanner" },
        legacy = true,
        darkText = true,
    })
end

local function SkinHelpLike(name)
    return function()
        Panel(_G[name], {
            art = { "helpframe\\" },
            box = { 4, -4, -46, 17 },
            legacy = true,
            portrait = false,
        })
    end
end

for _, entry in ipairs({
    { flag = "skinSirusWindows", label = "Окна Sirus: боевой пропуск, рулетка, чёрный рынок и другие" },
    { flag = "skinSupport",      label = "Опрос и база знаний поддержки" },
}) do
    WindowSkins.EXTRA[#WindowSkins.EXTRA + 1] = entry
end

local function Toast(frame, inset, art)
    if not frame or frame.narciToast then return end
    frame.narciToast = true
    if art then HideArt(frame, art) end
    local plate = CreateFrame("Frame", nil, frame)
    plate:SetPoint("TOPLEFT", frame, "TOPLEFT", inset[1], inset[2])
    plate:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset[3], inset[4])
    plate:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
    plate:EnableMouse(false)
    Kit().Window(plate, { inset = 10, depth = 0 })
    plate.narciOwn = true
    frame.narciPlate = plate
end

local function SkinAchievementAlerts()
    for index = 1, 4 do
        local frame = _G["AchievementAlertFrame" .. index]
        if frame then
            Mail().Hide(_G["AchievementAlertFrame" .. index .. "Background"])
            Toast(frame, { 22, -8, -8, 8 })
        end
    end
end

local function SkinDungeonAlert()
    local frame = _G.DungeonCompletionAlertFrame1
    if frame then Toast(frame, { 10, -10, -10, 10 }, { "ui%-lfg%-dungeontoast" }) end
end

local function SkinLootAlert(frame)
    if not frame then return end
    if frame.Background then frame.Background:SetAlpha(0) end
    Toast(frame, { 10, -12, -10, 12 })
end

local function SkinSocialToast(_, toast)
    if not toast or toast.narciToast then return end
    if toast.SetBackdrop then pcall(toast.SetBackdrop, toast, nil) end
    Toast(toast, { 0, 0, 0, 0 })
    if toast.CloseButton then Kit().Close(toast.CloseButton) end
end

local function SkinMirrorTimers()
    local S = Style()
    for index = 1, (_G.MIRRORTIMER_NUMTIMERS or 3) do
        local frame = _G["MirrorTimer" .. index]
        local bar = _G["MirrorTimer" .. index .. "StatusBar"]
        if frame and bar and not frame.narciMirror then
            frame.narciMirror = true
            Mail().Hide(_G["MirrorTimer" .. index .. "Border"])
            HideArt(frame, { "ui%-castingbar%-border" })
            if NS.Look and NS.Look.SetBar then NS.Look:SetBar(bar, "castbar") end
            local holder = CreateFrame("Frame", nil, frame)
            holder:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
            holder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
            holder:SetFrameLevel(math.max(bar:GetFrameLevel() - 1, 0))
            local ground = holder:CreateTexture(nil, "BACKGROUND")
            ground:SetAllPoints(holder)
            ground:SetTexture(WHITE)
            ground:SetVertexColor(0.016, 0.018, 0.026, 0.92)
            S.CreateEdges(holder, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            S.CreateSoftShadow(holder, 5, 0.5)
            local text = _G["MirrorTimer" .. index .. "Text"]
            if text then
                text:ClearAllPoints()
                text:SetPoint("CENTER", bar, "CENTER", 0, 0)
                NS.LSetFont(text, "castbar", NS.FS(10), "OUTLINE")
            end
        end
    end
end

local function SkinExtraAction()
    local bars = NS.ActionBars
    for _, name in ipairs({ "ExtraActionBarFrameButton1", "ExtraActionBarFrameButton2", "ExtraActionButton1" }) do
        local button = _G[name]
        if button and not button.narciExtra then
            button.narciExtra = true
            if button.style then button.style:SetAlpha(0) end
            local barsOn = NS.db and NS.db.actionBars and NS.db.actionBars.enabled
            if barsOn and bars and bars.SkinButton then pcall(bars.SkinButton, bars, name) end
        end
    end
    local frame = _G.ExtraActionBarFrame
    if frame and frame.Background then frame.Background:SetAlpha(0) end
end

local VEHICLE_ART = { "_BG", "EndCapL", "EndCapR", "_Border", "Divider1", "Divider2", "Divider3", "ExitBG",
    "MicroBGL", "MicroBGR", "_MicroBGMid", "ButtonBGL", "ButtonBGR", "_ButtonBGMid", "PitchOverlay",
    "PitchButtonBG", "PitchBG", "PitchMarker", "HealthBarBG", "HealthBarOverlay", "PowerBarBG", "PowerBarOverlay" }

local function InBotva()
    local games = _G.C_MiniGames
    local enum = _G.Enum and _G.Enum.MiniGames and _G.Enum.MiniGames.GameType
    if not games or not games.GetGameType or not enum then return false end
    local ok, kind = pcall(games.GetGameType)
    return ok and kind ~= nil and kind == enum.Botva
end

local function InMiniGame()
    if type(_G.QueueStatus_InActiveMiniGame) == "function" then
        local ok, active = pcall(_G.QueueStatus_InActiveMiniGame)
        if ok and active then return true end
    end
    return InBotva()
end

local function Short(value)
    if value >= 10000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end

local function PaintVehicleText()
    local frame = _G.VehicleMenuBar
    local own = frame and frame.narciVehicle
    if not own or not own.healthFill then return end
    local health, maxHealth = UnitHealth("vehicle") or 0, UnitHealthMax("vehicle") or 0
    own.healthFill:SetMinMaxValues(0, math.max(maxHealth, 1))
    own.healthFill:SetValue(health)
    own.healthText:SetText(maxHealth > 0 and string.format("%d%%", math.floor(health / maxHealth * 100 + 0.5)) or "")
    local power, maxPower = UnitPower("vehicle") or 0, UnitPowerMax("vehicle") or 0
    own.powerFill:SetMinMaxValues(0, math.max(maxPower, 1))
    own.powerFill:SetValue(power)
    for _, pair in ipairs({ { own.healthFill, _G.VehicleMenuBarHealthBar }, { own.powerFill, _G.VehicleMenuBarPowerBar } }) do
        local source = pair[2]
        if source then
            local r, g, b = source:GetStatusBarColor()
            if r then pair[1]:SetStatusBarColor(r, g, b) end
        end
    end
    if maxPower > 0 then
        local value = Short(power) .. " / " .. Short(maxPower)
        own.powerText:SetText(InBotva() and NS.L["Солнце"] .. ": " .. value or value)
        own.power:Show()
    else
        own.powerText:SetText("")
        own.power:Hide()
    end
end

local function LiftVehicleKeys()
    local frame = _G.VehicleMenuBar
    local own = frame and frame.narciVehicle
    if not own or not own.covers then return end
    for index, cover in pairs(own.covers) do
        local button = _G["VehicleMenuBarActionButton" .. index]
        if button then
            cover:SetFrameStrata(button:GetFrameStrata())
            cover:SetFrameLevel(button:GetFrameLevel() + 5)
        end
    end
end

local function PaintVehicleKeys()
    local frame = _G.VehicleMenuBar
    local own = frame and frame.narciVehicle
    if not own or not own.keys then return end
    for index, label in pairs(own.keys) do
        local key = GetBindingKey("ACTIONBUTTON" .. index)
        local text = key and GetBindingText(key, "KEY_", 1) or ""
        text = text:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A")
        label:SetText(text)
    end
end

local function VehicleBar(bar, parent)
    local S = Style()
    local back = CreateFrame("Frame", nil, parent)
    back:SetFrameLevel(parent:GetFrameLevel() + 3)
    back.narciOwn = true
    local ground = back:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(back)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.92)
    S.CreateEdges(back, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    local fill = CreateFrame("StatusBar", nil, back)
    fill:SetPoint("TOPLEFT", back, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", back, "BOTTOMRIGHT", -1, 1)
    if NS.Look and NS.Look.SetBar then NS.Look:SetBar(fill, "actionbars") else fill:SetStatusBarTexture(WHITE) end
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(0)
    local label = fill:CreateFontString(nil, "OVERLAY")
    NS.LSetFont(label, "actionbars", NS.FS(10), "OUTLINE")
    label:SetPoint("CENTER", back, "CENTER", 0, 0)
    label:SetTextColor(1, 1, 1)
    if bar then
        bar:SetAlpha(0)
        if bar.EnableMouse then bar:EnableMouse(false) end
        bar:HookScript("OnValueChanged", PaintVehicleText)
        bar:HookScript("OnMinMaxChanged", PaintVehicleText)
    end
    return back, label, fill
end

local function IsVehicleArt(region)
    if region:GetObjectType() ~= "Texture" then return false end
    local ok, path = pcall(region.GetTexture, region)
    if not ok or type(path) ~= "string" then return false end
    path = path:lower()
    return path:find("playeractionbaralt", 1, true) ~= nil or path:find("vehicles\\ui-vehicle", 1, true) ~= nil
end

local function WalkVehicle(frame, fn, depth)
    for _, region in ipairs({ frame:GetRegions() }) do fn(region) end
    if depth <= 0 then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        local kind = child:GetObjectType()
        if kind ~= "Button" and kind ~= "CheckButton" and not child.narciOwn then
            WalkVehicle(child, fn, depth - 1)
        end
    end
end

local function HideVehicleArt(frame)
    for _, key in ipairs(VEHICLE_ART) do
        local texture = frame[key] or _G["VehicleMenuBar" .. key]
        if texture and texture.Hide and not key:find("^Leave") then texture:Hide() end
    end
    WalkVehicle(frame, function(region)
        if IsVehicleArt(region) then region:Hide() end
    end, 4)
end

local function PlaceVehicle()
    local frame = _G.VehicleMenuBar
    local own = frame and frame.narciVehicle
    if not own then return end
    HideVehicleArt(frame)
    local first, last = _G.VehicleMenuBarActionButton1, _G.VehicleMenuBarActionButton6
    own.health:ClearAllPoints()
    own.health:SetPoint("BOTTOMLEFT", first, "TOPLEFT", -1, 7)
    own.health:SetPoint("BOTTOMRIGHT", _G.VehicleMenuBarActionButton3, "TOPRIGHT", 1, 7)
    own.health:SetHeight(16)
    own.power:ClearAllPoints()
    own.power:SetPoint("BOTTOMLEFT", _G.VehicleMenuBarActionButton4, "TOPLEFT", -1, 7)
    own.power:SetPoint("BOTTOMRIGHT", last, "TOPRIGHT", 1, 7)
    own.power:SetHeight(16)
    local leave = _G.VehicleMenuBarLeaveButton
    if leave then
        leave:SetAlpha(0)
        leave:EnableMouse(false)
    end
    local up, down = _G.VehicleMenuBarPitchUpButton, _G.VehicleMenuBarPitchDownButton
    if up and down then
        up:ClearAllPoints()
        up:SetPoint("BOTTOMRIGHT", first, "LEFT", -14, 1)
        down:ClearAllPoints()
        down:SetPoint("TOPRIGHT", first, "LEFT", -14, -1)
        up:SetSize(26, 26)
        down:SetSize(26, 26)
    end
    if own.quit then
        own.quit:ClearAllPoints()
        own.quit:SetPoint("LEFT", last, "RIGHT", 14, 0)
        local canLeave = InMiniGame() or (CanExitVehicle and CanExitVehicle()) or UnitOnTaxi("player")
        if canLeave then own.quit:Show() else own.quit:Hide() end
    end
    local edge = own.quit and own.quit:IsShown() and own.quit or last
    own.plate:ClearAllPoints()
    own.plate:SetPoint("TOPLEFT", first, "TOPLEFT", -8, 30)
    own.plate:SetPoint("RIGHT", edge, "RIGHT", 8, 0)
    own.plate:SetPoint("BOTTOM", last, "BOTTOM", 0, -8)
    PaintVehicleText()
    LiftVehicleKeys()
end

local function SkinVehicle()
    local frame = _G.VehicleMenuBar
    if not frame or frame.narciVehicle or not _G.VehicleMenuBarActionButton1 then return end
    local S = Style()
    local own = {}
    frame.narciVehicle = own
    local plate = CreateFrame("Frame", nil, frame)
    plate.narciOwn = true
    plate:SetFrameLevel(math.max(_G.VehicleMenuBarActionButton1:GetFrameLevel() - 2, 0))
    local ground = plate:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(plate)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(S.Bg(0.88))
    S.CreateEdges(plate, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    S.CreateSoftShadow(plate, 6, 0.5)
    if S.CreateGradientTopBorder then pcall(S.CreateGradientTopBorder, plate) end
    own.plate = plate
    for index = 1, (_G.VEHICLE_MAX_ACTIONBUTTONS or 6) do
        local button = _G["VehicleMenuBarActionButton" .. index]
        if button then
            local slot = plate:CreateTexture(nil, "ARTWORK")
            slot:SetAllPoints(button)
            slot:SetTexture(WHITE)
            slot:SetVertexColor(1, 1, 1, 0.05)
            local edge = CreateFrame("Frame", nil, plate)
            edge:SetAllPoints(button)
            S.CreateEdges(edge, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)
        end
    end
    own.keys = {}
    own.covers = {}
    for index = 1, (_G.VEHICLE_MAX_ACTIONBUTTONS or 6) do
        local name = "VehicleMenuBarActionButton" .. index
        local button = _G[name]
        if button then
            button:HookScript("OnShow", LiftVehicleKeys)
            button:HookScript("OnClick", LiftVehicleKeys)
            local cover = CreateFrame("Frame", nil, frame)
            cover:SetAllPoints(button)
            cover.narciOwn = true
            own.covers[index] = cover
            local label = cover:CreateFontString(nil, "OVERLAY")
            NS.LSetFont(label, "actionbars", NS.FS(11), "OUTLINE")
            label:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -3)
            label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            own.keys[index] = label
            local hotkey = _G[name .. "HotKey"]
            if hotkey then
                hotkey:Hide()
                hooksecurefunc(hotkey, "Show", hotkey.Hide)
            end
        end
    end
    local quit = CreateFrame("Button", nil, frame)
    quit:SetSize(38, 38)
    quit:SetFrameLevel(_G.VehicleMenuBarActionButton1:GetFrameLevel())
    local quitGround = quit:CreateTexture(nil, "BACKGROUND")
    quitGround:SetAllPoints(quit)
    quitGround:SetTexture(WHITE)
    quitGround:SetVertexColor(1, 1, 1, 0.05)
    S.CreateEdges(quit, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)
    local quitIcon = quit:CreateTexture(nil, "ARTWORK")
    quitIcon:SetPoint("TOPLEFT", quit, "TOPLEFT", 3, -3)
    quitIcon:SetPoint("BOTTOMRIGHT", quit, "BOTTOMRIGHT", -3, 3)
    quitIcon:SetTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
    local quitLight = quit:CreateTexture(nil, "HIGHLIGHT")
    quitLight:SetAllPoints(quit)
    quitLight:SetTexture(WHITE)
    quitLight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.2)
    quit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local text = InMiniGame() and (_G.MINIGAME_LEAVE or NS.L["Покинуть мини-игру"])
            or UnitOnTaxi("player") and (_G.TAXI_CANCEL or NS.L["Покинуть транспорт"])
            or _G.LEAVE_VEHICLE or NS.L["Покинуть транспорт"]
        GameTooltip:SetText(text, 1, 1, 1)
        GameTooltip:Show()
    end)
    quit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    quit:SetScript("OnClick", function()
        if InMiniGame() then
            NS.Widgets.ShowConfirm(NS.L["Покинуть мини-игру?"], NS.L["Покинуть"], function()
                if _G.C_MiniGames and _G.C_MiniGames.Leave then _G.C_MiniGames.Leave() end
            end)
        elseif UnitOnTaxi("player") then
            if TaxiRequestEarlyLanding then TaxiRequestEarlyLanding() end
        elseif VehicleExit then
            VehicleExit()
        end
    end)
    quit:Hide()
    own.quit = quit
    local leaveButton = _G.VehicleMenuBarLeaveButton
    if leaveButton then
        leaveButton:HookScript("OnShow", PlaceVehicle)
        leaveButton:HookScript("OnHide", PlaceVehicle)
        hooksecurefunc(leaveButton, "Enable", PlaceVehicle)
        hooksecurefunc(leaveButton, "Disable", PlaceVehicle)
    end
    own.health, own.healthText, own.healthFill = VehicleBar(_G.VehicleMenuBarHealthBar, frame)
    own.power, own.powerText, own.powerFill = VehicleBar(_G.VehicleMenuBarPowerBar, frame)
    local bars = NS.ActionBars
    local barsOn = NS.db and NS.db.actionBars and NS.db.actionBars.enabled
    for index = 1, (_G.VEHICLE_MAX_ACTIONBUTTONS or 6) do
        local name = "VehicleMenuBarActionButton" .. index
        if barsOn and bars and bars.SkinButton then
            pcall(bars.SkinButton, bars, name)
        else
            local icon = _G[name .. "Icon"]
            if icon then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        end
    end
    if type(_G.VehicleMenuBar_SetSkin) == "function" then hooksecurefunc("VehicleMenuBar_SetSkin", PlaceVehicle) end
    frame:HookScript("OnShow", PlaceVehicle)
    local events = CreateFrame("Frame", nil, frame)
    events:RegisterEvent("UNIT_ENTERED_VEHICLE")
    events:RegisterEvent("UNIT_POWER")
    events:RegisterEvent("UNIT_MAXPOWER")
    events:RegisterEvent("UPDATE_BINDINGS")
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "UPDATE_BINDINGS" then
            PaintVehicleKeys()
        elseif event == "UNIT_ENTERED_VEHICLE" then
            if unit == "player" then PlaceVehicle() end
        elseif unit == "vehicle" then
            PaintVehicleText()
        end
    end)
    PlaceVehicle()
    PaintVehicleKeys()
    LiftVehicleKeys()
end

local function SkinTimerBar(timer)
    local bar = timer and timer.bar
    if not bar or bar.narciTimer then return end
    bar.narciTimer = true
    local S = Style()
    local fill = bar:GetStatusBarTexture()
    for _, region in ipairs({ bar:GetRegions() }) do
        if region ~= fill and region:GetObjectType() == "Texture" then region:Hide() end
    end
    local back = CreateFrame("Frame", nil, bar)
    back:SetFrameLevel(math.max(bar:GetFrameLevel() - 1, 0))
    back:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    back:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    local ground = back:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(back)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(0.016, 0.018, 0.026, 0.92)
    S.CreateEdges(back, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    S.CreateSoftShadow(back, 5, 0.5)
    if NS.Look and NS.Look.SetBar then NS.Look:SetBar(bar, "castbar") end
    bar:SetStatusBarColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    if bar.timeText then
        NS.LSetFont(bar.timeText, "castbar", NS.FS(10), "OUTLINE")
        bar.timeText:SetTextColor(1, 1, 1)
    end
end

local function SkinTimerBars()
    local tracker = _G.TimerTracker
    for _, timer in ipairs(tracker and tracker.timerList or {}) do SkinTimerBar(timer) end
end

local function SkinReadyButton()
    local button = _G.TimerTracker_ReadyStatusButton
    if not button or button.narciReady then return end
    button.narciReady = true
    local S = Style()
    if button.Background then button.Background:Hide() end
    if button.Glow then button.Glow:Hide() end
    local ground = button:CreateTexture(nil, "BACKGROUND", nil, -1)
    ground:SetPoint("TOPLEFT", button, "TOPLEFT", 6, -6)
    ground:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)
    ground:SetTexture(WHITE)
    ground:SetVertexColor(S.Bg(0.92))
    local edge = CreateFrame("Frame", nil, button)
    edge:SetAllPoints(ground)
    edge:SetFrameLevel(button:GetFrameLevel())
    S.CreateEdges(edge, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    S.CreateSoftShadow(edge, 6, 0.5)
    if S.CreateGradientTopBorder then pcall(S.CreateGradientTopBorder, edge, 2) end
    for _, key in ipairs({ "HighlightTexture", "Selection" }) do
        local texture = button[key]
        if texture then
            texture:SetTexture(WHITE)
            texture:ClearAllPoints()
            texture:SetAllPoints(ground)
        end
    end
    if button.HighlightTexture then button.HighlightTexture:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18) end
    if button.Selection then button.Selection:SetVertexColor(0.3, 0.9, 0.45, 0.2) end
    if button.ReadyText then
        button.ReadyText:SetFont(NS.FONT, NS.FS(18), "OUTLINE")
        button.ReadyText:SetTextColor(1, 1, 1)
    end
    if button.ReadyTextDescription then
        button.ReadyTextDescription:SetFont(NS.FONT, NS.FS(10), "")
        button.ReadyTextDescription:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end
end

local function SkinTimers()
    SkinReadyButton()
    SkinTimerBars()
    local tracker = _G.TimerTracker
    if tracker and not tracker.narciHooked then
        tracker.narciHooked = true
        tracker:HookScript("OnEvent", SkinTimerBars)
        local button = _G.TimerTracker_ReadyStatusButton
        if button then button:HookScript("OnShow", SkinTimerBars) end
    end
end

local function Rect(frame)
    if not frame then return "nil" end
    local left, bottom, width, height = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
    return string.format("%s %s,%s %dx%d a=%.2f s=%.2f", frame:IsShown() and "shown" or "hidden",
        left and math.floor(left) or "-", bottom and math.floor(bottom) or "-", math.floor(width or 0), math.floor(height or 0),
        frame:GetAlpha() or 0, frame:GetEffectiveScale() or 0)
end

function WindowSkins:DiagnoseVehicle()
    local P = NS.Print
    if _G.ChatFrame1 and not _G.ChatFrame1:IsShown() then
        _G.ChatFrame1:Show()
        if _G.GeneralDockManager then _G.GeneralDockManager:Show() end
    end
    local frame = _G.VehicleMenuBar
    P("VehicleMenuBar: " .. Rect(frame) .. " minigame=" .. tostring(InBotva()))
    P("under cursor:")
    local count = 0
    local scan = EnumerateFrames()
    while scan and count < 15 do
        if scan:IsVisible() and MouseIsOver(scan) and (scan:GetWidth() or 0) < 900 then
            local regions = 0
            for _, region in ipairs({ scan:GetRegions() }) do
                if region:GetObjectType() == "Texture" and region:IsVisible() then regions = regions + 1 end
            end
            if regions > 0 then
                count = count + 1
                local parent = scan:GetParent()
                P(string.format("  %s (parent %s) %s [%s %d] tex=%d %s", scan:GetName() or "?",
                    parent and (parent:GetName() or "?") or "-", scan:GetObjectType(), scan:GetFrameStrata(),
                    scan:GetFrameLevel(), regions, Rect(scan)))
            end
        end
        scan = EnumerateFrames(scan)
    end
    P("Health: " .. Rect(_G.VehicleMenuBarHealthBar))
    P("Power: " .. Rect(_G.VehicleMenuBarPowerBar))
    local own = frame and frame.narciVehicle
    if own then P("Backs: " .. Rect(own.health) .. " / " .. Rect(own.power)) end
end

local function SkinLossOfControl()
    local frame = _G.LossOfControlFrame
    if not frame or frame.narciDone then return end
    frame.narciDone = true
    local S = Style()
    for _, key in ipairs({ "blackBg", "RedLineTop", "RedLineBottom" }) do
        if frame[key] then frame[key]:SetAlpha(0) end
    end
    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", -40, 6)
    left:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", 0, -6)
    left:SetTexture(WHITE)
    left:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0.02, 0.02, 0.03, 0.75)
    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetPoint("TOPLEFT", frame, "TOP", 0, 6)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 40, -6)
    right:SetTexture(WHITE)
    right:SetGradientAlpha("HORIZONTAL", 0.02, 0.02, 0.03, 0.75, 0, 0, 0, 0)
    for _, edge in ipairs({ "TOP", "BOTTOM" }) do
        local y = edge == "TOP" and 6 or -6
        local a = frame:CreateTexture(nil, "BORDER")
        a:SetHeight(1)
        a:SetPoint(edge .. "LEFT", frame, edge .. "LEFT", -40, y)
        a:SetPoint(edge .. "RIGHT", frame, edge, 0, y)
        a:SetTexture(WHITE)
        a:SetGradientAlpha("HORIZONTAL", 0.9, 0.2, 0.2, 0, 0.9, 0.2, 0.2, 0.8)
        local b = frame:CreateTexture(nil, "BORDER")
        b:SetHeight(1)
        b:SetPoint(edge .. "LEFT", frame, edge, 0, y)
        b:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT", 40, y)
        b:SetTexture(WHITE)
        b:SetGradientAlpha("HORIZONTAL", 0.9, 0.2, 0.2, 0.8, 0.9, 0.2, 0.2, 0)
    end
    if frame.Icon then frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
end

local function SkinQuestTimer()
    local frame = _G.QuestTimerFrame
    if not frame or frame.narciDone then return end
    frame.narciDone = true
    Mail().Hide(_G.QuestTimerHeader)
    Kit().Window(frame, { inset = 14, depth = 1 })
end

local function SkinGuildInvite()
    Panel(_G.GuildInviteFrame, {
        art = { "guildframe\\guildextra" },
        box = { 0, 0, 0, 0 },
        legacy = true,
        portrait = false,
        depth = 2,
    })
end

local function SkinAlerts()
    SkinAchievementAlerts()
    SkinDungeonAlert()
    for index = 1, 4 do
        local button = _G["LootAlertButton" .. index]
        if button and not button.narciHooked then
            button.narciHooked = true
            button:HookScript("OnShow", SkinLootAlert)
            if button:IsShown() then SkinLootAlert(button) end
        end
    end
    local toasts = _G.SocialToastAnchorFrame
    if toasts and toasts.ShowToast and not toasts.narciHooked then
        toasts.narciHooked = true
        hooksecurefunc(toasts, "ShowToast", SkinSocialToast)
    end
    if _G.BNToastFrame and not _G.BNToastFrame.narciDone then
        _G.BNToastFrame.narciDone = true
        Kit().Window(_G.BNToastFrame, { inset = 10, depth = 1 })
    end
    for _, fn in ipairs({ "AchievementAlertFrame_ShowAlert", "AchievementAlertFrame_GetAlertFrame" }) do
        if type(_G[fn]) == "function" and not WindowSkins["hooked" .. fn] then
            WindowSkins["hooked" .. fn] = true
            hooksecurefunc(fn, SkinAchievementAlerts)
        end
    end
end

local function SkinHud()
    if Flag("skinAlerts") then pcall(SkinAlerts) end
    if Flag("skinMirrorTimers") then pcall(SkinMirrorTimers) end
    if Flag("skinExtraAction") then pcall(SkinExtraAction) end
    if Flag("skinVehicle") then pcall(SkinVehicle) end
    if Flag("skinTimer") then pcall(SkinTimers) end
    if Flag("skinLossOfControl") then pcall(SkinLossOfControl) end
    if Flag("skinQuestTimer") then pcall(SkinQuestTimer) end
end

for _, entry in ipairs({
    { flag = "skinAlerts",        label = "Уведомления: достижения, добыча, подземелья, друзья" },
    { flag = "skinMirrorTimers",  label = "Полосы дыхания и усталости" },
    { flag = "skinExtraAction",   label = "Кнопка особого действия" },
    { flag = "skinVehicle",       label = "Панель транспорта и мини-игры «Ботва»" },
    { flag = "skinTimer",         label = "Таймер начала и кнопка «Готов»" },
    { flag = "skinLossOfControl", label = "Потеря контроля" },
    { flag = "skinQuestTimer",    label = "Таймер заданий" },
    { flag = "skinGuildInvite",   label = "Приглашение в гильдию" },
}) do
    WindowSkins.EXTRA[#WindowSkins.EXTRA + 1] = entry
end

local TARGETS = {
    { frame = "ReadyCheckListenerFrame", flag = "skinReadyCheck", apply = SkinReadyCheck },
    { frame = "GuildInviteFrame", flag = "skinGuildInvite", apply = SkinGuildInvite },
    { frame = "BattlePassFrame", flag = "skinSirusWindows", apply = SkinPKBT("BattlePassFrame") },
    { frame = "RealmShoutFrame", flag = "skinSirusWindows", apply = SkinPKBT("RealmShoutFrame") },
    { frame = "AlliedRacesFrame", flag = "skinSirusWindows", apply = SkinAlliedRaces },
    { frame = "LootCasePreviewFrame", flag = "skinSirusWindows", apply = SkinLootCase },
    { frame = "BlackMarketFrame", flag = "skinSirusWindows", apply = SkinBlackMarket },
    { frame = "ChooseItemFrame", flag = "skinSirusWindows", apply = SkinChooseItem },
    { frame = "Custom_RouletteFrame", flag = "skinSirusWindows", apply = SkinArtWindow("Custom_RouletteFrame", { "NineSliceInset" }) },
    { frame = "MountChestFrame", flag = "skinSirusWindows", apply = SkinArtWindow("MountChestFrame") },
    { frame = "PVPBannerFrame", flag = "skinSirusWindows", apply = SkinPVPBanner },
    { frame = "GMSurveyFrame", flag = "skinSupport", apply = SkinHelpLike("GMSurveyFrame") },
    { frame = "KnowledgeBaseFrame", flag = "skinSupport", apply = SkinHelpLike("KnowledgeBaseFrame") },
    { frame = "LootFrame", flag = "skinLootWindow", apply = SkinLoot },
    { frame = "DressUpFrame", flag = "skinDressUp", apply = SkinDressUp },
    { frame = "ItemTextFrame", flag = "skinItemText", apply = SkinItemText },
    { frame = "TaxiFrame", flag = "skinTaxi", apply = SkinTaxi },
    { frame = "TabardFrame", flag = "skinTabard", apply = SkinTabard },
    { frame = "PetitionFrame", flag = "skinCharters", apply = QuestLike("PetitionFrame") },
    { frame = "GuildRegistrarFrame", flag = "skinCharters", apply = QuestLike("GuildRegistrarFrame") },
    { frame = "ArenaRegistrarFrame", flag = "skinCharters", apply = QuestLike("ArenaRegistrarFrame") },
    { frame = "PetStableFrame", flag = "skinPetStable", apply = SkinPetStable },
    { frame = "ItemSocketingFrame", flag = "skinSocketing", apply = SkinSocketing },
    { frame = "GuildBankFrame", flag = "skinGuildBank", apply = SkinGuildBank },
    { frame = "WorldStateScoreFrame", flag = "skinScore", apply = SkinScore },
    { frame = "MiniGameScoreFrame", flag = "skinScore", apply = SkinMiniGameScore },
    { frame = "TimeManagerFrame", flag = "skinTimeManager", apply = SkinTimeManager },
    { frame = "StopwatchFrame", flag = "skinTimeManager", apply = SkinStopwatch },
    { frame = "CalendarFrame", flag = "skinCalendar", apply = SkinCalendar },
    { frame = "DeathRecapFrame", flag = "skinDeathRecap", apply = SkinDeathRecap },
    { frame = "ItemUpgradeFrame", flag = "skinItemUpgrade", apply = SkinItemUpgrade },
    { frame = "ChatConfigFrame", flag = "skinChatConfig", apply = SkinChatConfig },
    { frame = "BattlefieldMinimap", flag = "skinBattleMap", apply = SkinBattlefieldMinimap },
    { frame = "TradeFrame", flag = "skinTrade", apply = SkinTrade },
    { frame = "TradeSkillFrame", flag = "skinTradeSkill", apply = SkinTradeSkill },
    { frame = "RR_LOOT_FRAME", flag = "skinLootTracker", apply = SkinLootTracker },
}

local installed = {}

local function Run(entry)
    if not Kit() or not Mail() then return end
    local ok, err = pcall(entry.apply)
    if not ok and NS.Print then NS.Print(entry.frame .. ": " .. tostring(err)) end
end

function WindowSkins:Scan()
    for _, entry in ipairs(TARGETS) do
        local frame = _G[entry.frame]
        if not installed[entry.frame] and frame and frame.HookScript
            and Flag(entry.flag) then
            installed[entry.frame] = true
            frame:HookScript("OnShow", function() Run(entry) end)
            if frame:IsShown() then Run(entry) end
        end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
    WindowSkins:Scan()
    if Kit() and Mail() then SkinHud() end
end)

local MiniGame = {}
NS.MiniGameHUD = MiniGame

MiniGame.GROUPS = {
    { key = "units",    label = "Рамки игрока, цели, питомца и другие" },
    { key = "raid",     label = "Рейд-фреймы и главные танки" },
    { key = "bars",     label = "Панели команд и полоса опыта" },
    { key = "cast",     label = "Полосы заклинаний" },
    { key = "auras",    label = "Бафы и дебафы" },
    { key = "cooldown", label = "Шкала кулдаунов" },
    { key = "threat",   label = "Угроза" },
    { key = "chat",     label = "Строка ввода и кнопка сообщений" },
    { key = "data",     label = "Панель показателей" },
    { key = "minimap",  label = "Миникарта и координаты" },
    { key = "extras",   label = "Трекер заданий" },
    { key = "plugins",  label = "Элементы плагинов" },
}

local HIDE_DEFAULT = { units = true, raid = true, bars = true, cast = true, auras = true, cooldown = true,
    threat = true, chat = true, data = false, minimap = false, extras = true, plugins = true }

local hidden = {}
local pending

function MiniGame.Settings()
    if type(NS.db.miniGame) ~= "table" then NS.db.miniGame = {} end
    local db = NS.db.miniGame
    if db.enabled == nil then db.enabled = true end
    if type(db.hide) ~= "table" then db.hide = {} end
    for key, value in pairs(HIDE_DEFAULT) do
        if db.hide[key] == nil then db.hide[key] = value end
    end
    return db
end

local function Spared(frame)
    if frame == _G.ChatFrame1 or frame == _G.NarciSirus_LeaveVehicle then return true end
    local bars = NS.ActionBars
    return bars and frame == bars.microHolder
end

local function KeepHidden(frame)
    if MiniGame.active and hidden[frame] and not InCombatLockdown() then frame:Hide() end
end

function MiniGame:Enter()
    local db = self.Settings()
    if not db.enabled then return end
    self.active = true
    if InCombatLockdown() then
        pending = "enter"
        return
    end
    pending = nil
    for _, entry in ipairs(NS.Movers and NS.Movers:Entries() or {}) do
        local frame = entry.frame
        if db.hide[entry.group] and frame and frame:IsShown() and not hidden[frame] and not Spared(frame) then
            local record = {}
            if type(UnitWatchRegistered) == "function" and UnitWatchRegistered(frame) then
                UnregisterUnitWatch(frame)
                record.watch = true
            end
            if frame.narciDriver then
                UnregisterStateDriver(frame, "visibility")
                record.driver = frame.narciDriver
            end
            hidden[frame] = record
            if not frame.narciMiniGameHook then
                frame.narciMiniGameHook = true
                hooksecurefunc(frame, "Show", KeepHidden)
            end
            frame:Hide()
        end
    end
end

function MiniGame:Leave()
    self.active = nil
    if InCombatLockdown() then
        pending = "leave"
        return
    end
    pending = nil
    for frame, record in pairs(hidden) do
        hidden[frame] = nil
        if record.watch then
            RegisterUnitWatch(frame)
        elseif record.driver then
            RegisterStateDriver(frame, "visibility", record.driver)
        else
            frame:Show()
        end
    end
end

function MiniGame:Refresh()
    if not self.active then return end
    self:Leave()
    if InBotva() then self:Enter() end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if pending == "enter" then MiniGame:Enter() elseif pending == "leave" then MiniGame:Leave() end
        return
    end
    if not MiniGame.registered and _G.EventRegistry and _G.EventRegistry.RegisterFrameEventAndCallback then
        MiniGame.registered = true
        local kinds = _G.Enum and _G.Enum.MiniGames and _G.Enum.MiniGames.GameType
        _G.EventRegistry:RegisterFrameEventAndCallback("MINI_GAME_ENTERED", function(_, kind)
            if kinds and kind == kinds.Botva then NS.After(0.5, function() MiniGame:Enter() end) end
            NS.After(0.6, function() pcall(PlaceVehicle) end)
        end, MiniGame)
        _G.EventRegistry:RegisterFrameEventAndCallback("MINI_GAME_EXITED", function()
            if MiniGame.active then MiniGame:Leave() end
            NS.After(0.6, function() pcall(PlaceVehicle) end)
        end, MiniGame)
    end
    NS.After(2, function()
        if InBotva() then
            MiniGame:Enter()
        elseif MiniGame.active then
            MiniGame:Leave()
        end
    end)
end)
