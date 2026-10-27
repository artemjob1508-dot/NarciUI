local API = NarciUI_API
if not API then return end

local NAME = "NarcissusSirus_Example"
local WHITE = "Interface\\Buttons\\WHITE8x8"

API:AddTranslations("enUS", {
    ["Пример плагина"] = "Example plugin",
    ["Сессия"] = "Session",
    ["Пример: жирные"] = "Example: bold",
    ["Пример: тёмное дерево"] = "Example: dark wood",
    ["Пример: блик"] = "Example: highlight",
    ["Пример: тёмный"] = "Example: dark",
    ["Окно персонажа открыто"] = "Character window opened",
    ["Значок плагина можно двигать вместе с остальными элементами, а его вид меняется здесь."] = "The plugin badge moves together with the other elements; its look is changed here.",
    ["Писать в чат при открытии окна персонажа"] = "Print to chat when the character window opens",
    ["Масштаб значка"] = "Badge scale",
    ["Цвет текста"] = "Text colour",
})

API:AddNameplateStyle({
    key = "example_bold", name = "Пример: жирные",
    width = 130, height = 14, texture = "shaded", border = "thick",
    nameAt = "above", nameAlign = "CENTER", hpAt = "center", level = "none",
})

API:AddBagStyle({
    key = "example_wood", name = "Пример: тёмное дерево",
    frame = "tooltip", pad = 10, bg = { 0.12, 0.08, 0.05, 0.95 }, border = { 0.55, 0.4, 0.2, 1 },
    title = "gold", cell = "edges", cellBorder = { 0.3, 0.2, 0.1, 1 },
})

API:AddBarTexture("example_highlight", "Пример: блик", "Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar-Highlight")

local sessionStart = time()

API:AddDataText({
    key = "example_session",
    label = "Сессия",
    value = function()
        local seconds = time() - sessionStart
        return string.format("%d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
    end,
})

API:AddLook({
    key = "example_dark", name = "Пример: тёмный",
    styles = {
        frame = "dark", buttons = "dark", cast = "shadow", tooltip = "stripe", chat = "pixel", minimap = "thick",
        raid = "minimal", auras = "pixel", data = "dark", cooldown = "dark", threat = "minimal",
        plates = "example_bold", bags = "example_wood",
    },
    look = { texture = "example_highlight", outline = "outline" },
})

local badge

local function Apply(db)
    if not badge then return end
    badge:SetScale((db.scale or 100) / 100)
    badge.text:SetTextColor(db.color[1], db.color[2], db.color[3])
end

API:RegisterPlugin(NAME, {
    title = "Пример плагина",
    version = "1.0",
    author = "NarciUI",
    description = "Показывает возможности API: своя страница настроек, стиль неймплейтов и сумок, текстура полос, блок показателей, готовый образ и значок, который двигается вместе с остальными элементами.",
    apiVersion = 1,
    defaults = { greet = true, scale = 100, color = { 0.4, 0.8, 1 } },

    onLoad = function(api, db)
        local S = api:Styling()

        badge = CreateFrame("Frame", "NarcissusSirus_ExampleBadge", UIParent)
        badge:SetSize(130, 24)
        badge:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 220)

        local ground = badge:CreateTexture(nil, "BACKGROUND")
        ground:SetAllPoints()
        ground:SetTexture(WHITE)
        ground:SetVertexColor(S.Bg())
        S.CreateEdges(badge, "BORDER", S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

        local text = badge:CreateFontString(nil, "OVERLAY")
        text:SetFont(api:Font(nil, api:FontSize(11), "OUTLINE"))
        text:SetPoint("CENTER")
        text:SetText(api:L("Пример плагина"))
        badge.text = text

        api:RegisterMover(badge, api:L("Пример плагина"), function(point, _, x, y)
            db.point, db.x, db.y = point, x, y
        end)

        api:On("CHARACTER_SHOWN", function()
            if db.greet then api:Print(api:L("Окно персонажа открыто")) end
        end, NAME)

        Apply(db)
    end,

    settings = function(page, ui, db, api)
        ui.Section(page, api:L("Пример плагина"))
        ui.Note(page, api:L("Значок плагина можно двигать вместе с остальными элементами, а его вид меняется здесь."))
        ui.Check(page, api:L("Писать в чат при открытии окна персонажа"), db.greet, function(value)
            db.greet = value
        end)
        ui.Slider(page, api:L("Масштаб значка"), 50, 200, 10, db.scale, function(value)
            db.scale = value
            Apply(db)
        end, "%")
        ui.Color(page, api:L("Цвет текста"), function()
            return db.color[1], db.color[2], db.color[3]
        end, function(r, g, b)
            db.color = { r, g, b }
            Apply(db)
        end)
    end,
})
