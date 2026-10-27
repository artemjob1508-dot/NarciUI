local addonName, NS = ...

local MenuSkins = {}
NS.MenuSkins = MenuSkins

local Kit = NS.SkinKit

local applied = {}
local lastError

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinMenus ~= false
end

local function IsObject(value)
    return Kit and Kit.IsObject(value)
end

local function FirstFontString(frame)
    if not IsObject(frame) or not frame.GetRegions then return end

    for _, region in ipairs({ frame:GetRegions() }) do
        if IsObject(region) and region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function Accent(fontString, tone)
    if not IsObject(fontString) or not fontString.SetTextColor then return end

    local S = Style()
    tone = tone or S.ACCENT_GLOW
    fontString:SetTextColor(tone[1], tone[2], tone[3])
end

local function Header(frame, fontString)
    if not IsObject(frame) or frame.narciMenuHeader then return end
    frame.narciMenuHeader = true

    Accent(fontString)

    if IsObject(fontString) then
        Kit.Rule(frame, 200, "TOP", fontString, "BOTTOM", 0, -6)
    end
end

local function Inset(frame, depth, alpha)
    if not IsObject(frame) then return end

    Kit.Strip(frame, depth or 3)
    Kit.Inset(frame, alpha or 0.25)
end

local function Shell(frame, inset)
    Kit.Window(frame, { inset = inset or 18, depth = 2 })
end

local function HelpSidebarButton(button, index, frame)
    if not IsObject(button) then return end

    if not button.narciHelpButton then
        button.narciHelpButton = true
        button.narciSkipAuto = true
        button.narciButton = true

        local S = Style()

        Kit.StripOne(button)
        Kit.Dim(button.Highlight)
        Kit.Dim(button.selected)
        Kit.Dim(button.NormalTexture)
        Kit.Dim(button.PushedTexture)
        Kit.Dim(button.DisabledTexture)

        Kit.KeepVisible(button.icon, 1, S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])

        local wash = button:CreateTexture(nil, "BACKGROUND")
        wash:SetAllPoints(button)
        wash:SetTexture(Kit.WHITE)
        wash:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.20,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.01)
        wash:Hide()

        local bar = button:CreateTexture(nil, "BORDER")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -4)
        bar:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 4)
        bar:SetTexture(Kit.WHITE)
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
        bar:Hide()

        local rule = button:CreateTexture(nil, "ARTWORK")
        rule:SetHeight(1)
        rule:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 10, -5)
        rule:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, -5)
        rule:SetTexture(Kit.WHITE)
        rule:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.01)

        button.narciWash = wash
        button.narciBar = bar

        button:HookScript("OnEnter", function(self)
            self.narciWash:Show()
            self.narciBar:Show()
        end)

        button:HookScript("OnLeave", function(self)
            if self.narciSelected then return end
            self.narciWash:Hide()
            self.narciBar:Hide()
        end)

        local text = button.GetFontString and button:GetFontString()
        if text then text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]) end
    end

    Kit.Dim(button.selected)
    Kit.KeepVisible(button.icon, 1)
end

local HELP_BUTTONS = { "button1", "button2", "button16", "button4", "button3", "button5", "button6" }

local function HelpSelection(selected)
    local frame = _G.HelpFrame
    if not frame then return end

    for _, key in ipairs(HELP_BUTTONS) do
        local button = frame[key]
        if IsObject(button) and button.narciWash then
            local S = Style()
            local active = button == selected

            button.narciSelected = active
            button.narciWash:SetShown(active)
            button.narciBar:SetShown(active)

            if IsObject(button.icon) then
                if active then
                    button.icon:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
                else
                    button.icon:SetVertexColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                end
            end
        end
    end
end

local function SkinHelp(frame)
    Shell(frame)

    if IsObject(frame.header) then
        Kit.Strip(frame.header, 2)
        Header(frame.header, FirstFontString(frame.header))
    end

    Inset(frame.leftInset, 3, 0.22)
    Inset(frame.mainInset, 3, 0.22)

    for index, key in ipairs(HELP_BUTTONS) do
        HelpSidebarButton(frame[key], index, frame)
    end

    Kit.Auto(frame, 8)

    for _, key in ipairs(HELP_BUTTONS) do
        local button = frame[key]
        if IsObject(button) then Kit.KeepVisible(button.icon, 1) end
    end

    HelpSelection(frame.disabledButton)

    if not frame.narciHelpHook then
        frame.narciHelpHook = true

        if type(_G.HelpFrame_SetSelectedButton) == "function" then
            hooksecurefunc("HelpFrame_SetSelectedButton", function(button)
                HelpSelection(button)
            end)
        end
    end
end

local function SkinFeed(feed)
    if not IsObject(feed) then return end

    Kit.Strip(feed, 8)

    if not feed.narciFeed then
        feed.narciFeed = true

        Kit.Inset(feed, 0.30)
        Kit.Edges(feed, 22, 0.30)

        local scroll = feed.ScrollFrame
        if IsObject(scroll) then
            scroll:ClearAllPoints()
            scroll:SetPoint("TOPLEFT", feed, "TOPLEFT", 18, -52)
            scroll:SetPoint("BOTTOMRIGHT", feed, "BOTTOMRIGHT", -30, 16)
        end
    end

    if IsObject(feed.Title) then
        Kit.Strip(feed.Title, 2)

        local text = feed.Title.Text or FirstFontString(feed.Title)
        Accent(text)

        if not feed.narciFeedRule then
            feed.narciFeedRule = true

            feed.Title:ClearAllPoints()
            feed.Title:SetPoint("TOP", feed, "TOP", 0, -20)

            Kit.Rule(feed, 160, "TOP", feed, "TOP", 0, -44)
        end
    end

    Kit.Walk(feed, 8, function(node)
        local kind = node:GetObjectType()

        if kind == "SimpleHTML" then
            Kit.Html(node)
        elseif kind == "Slider" and Kit.NameHas(node, "ScrollBar") then
            Kit.ScrollBar(node)
        elseif kind == "Button" and Kit.NameHas(node, "CloseButton") then
            Kit.Close(node)
        end
    end)
end

local function SkinNews(frame)
    Shell(frame)

    SkinFeed(frame.ServerAnnounces)
    SkinFeed(frame.ServerChanges)

    Kit.Walk(frame, 3, function(node)
        if node:GetObjectType() == "Button" and Kit.NameHas(node, "CloseButton") then
            Kit.Close(node)
        end
    end)
end

local function SkinNewsPanel(frame)
    Shell(frame, 14)
    SkinFeed(frame.DataFeed or frame)
end

local function SkinTabs(frame, name)
    local count = frame.numTabs or 4

    for index = 1, count do
        local tab = _G[name .. "Tab" .. index]
        if IsObject(tab) then
            tab.narciSkipAuto = true
            Kit.Tab(tab, frame.selectedTab == index)
        end
    end
end

local function SkinOptions(frame)
    Shell(frame)

    local name = frame:GetName()
    Header(frame, _G[name .. "HeaderText"])
    SkinTabs(frame, name)

    local category = frame.categoryFrame or _G[name .. "CategoryFrame"]
    if IsObject(category) then Inset(category, 4, 0.22) end

    local container = frame.panelContainer or _G[name .. "PanelContainer"]
    if IsObject(container) then Inset(container, 2, 0.18) end

    Kit.Auto(frame, 8)
end

local function SkinBindings(frame)
    Shell(frame)

    Header(frame, _G.KeyBindingFrameHeaderText)

    local S = Style()

    for index = 1, 32 do
        local row = _G["KeyBindingFrameBinding" .. index]
        if not IsObject(row) then break end

        Kit.Field(_G["KeyBindingFrameBinding" .. index .. "Key1Button"])
        Kit.Field(_G["KeyBindingFrameBinding" .. index .. "Key2Button"])

        local description = _G["KeyBindingFrameBinding" .. index .. "Description"]
        if IsObject(description) then
            description:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        end

        Accent(_G["KeyBindingFrameBinding" .. index .. "Header"])
    end

    for _, key in ipairs({ "CommandLabel", "Key1Label", "Key2Label" }) do
        Accent(_G["KeyBindingFrame" .. key], S.TEXT_NORMAL)
    end

    Kit.Auto(frame, 8)
end

local function SkinMacro(frame)
    Shell(frame)

    local name = frame.GetName and frame:GetName()
    if name then SkinTabs(frame, name) end

    Kit.Auto(frame, 8)

    local grid = _G.MacroButtonScrollFrame
    if IsObject(grid) and not grid.narciGrid then
        grid.narciGrid = true
        Kit.Inset(grid, 0.30)
        Kit.Edges(grid, 18, 0.26)
    end

    Kit.Dim(_G.MacroHorizontalBarLeft)
    Kit.Dim(_G.MacroHorizontalBarRight)
end

local function SkinPlain(frame)
    Shell(frame)

    local name = frame.GetName and frame:GetName()
    if name then SkinTabs(frame, name) end

    Kit.Auto(frame, 8)
end

local promoPending
local promoWatcher

local function SendPromo(opcode, code)
    if type(_G.SendServerMessage) ~= "function" then
        NS.Print("промокод: SendServerMessage недоступен")
        return false
    end

    local ok, err = pcall(_G.SendServerMessage, opcode, code)
    if not ok then NS.Print("промокод: " .. tostring(err)) end

    return ok
end

local function WatchPromo()
    if promoWatcher then return end

    promoWatcher = CreateFrame("Frame")
    promoWatcher:RegisterEvent("STORE_PROMOCODE_ITEMLIST")
    promoWatcher:RegisterEvent("STORE_PROMOCODE_ERROR")
    promoWatcher:RegisterEvent("STORE_PROMOCODE_REWARD_CLAIMED")

    promoWatcher:SetScript("OnEvent", function(self, event, first, second)
        if not promoPending then return end

        if event == "STORE_PROMOCODE_ERROR" then
            NS.Print("промокод: " .. tostring(first))
            promoPending = nil
        elseif event == "STORE_PROMOCODE_ITEMLIST" then
            NS.Print("промокод принят, забираю награду")
            SendPromo("ACMSG_PROMOCODE_SUBMIT", promoPending)
        elseif event == "STORE_PROMOCODE_REWARD_CLAIMED" then
            NS.Print("награда получена" .. (second and (": " .. tostring(second)) or ""))
            promoPending = nil

            local input = _G.NarcissusSirus_PromoInput
            if input then input:SetText("") end
        end
    end)
end

local function ActivatePromo()
    local input = _G.NarcissusSirus_PromoInput
    local code = input and input:GetText() or ""

    if code == "" then
        NS.Print("промокод: введите код")
        return
    end

    WatchPromo()
    promoPending = code

    if SendPromo("ACMSG_PROMOCODE_REWARD", code) then
        NS.Print("промокод отправлен: " .. code)
    end
end

local function SkinAction(action)
    if not IsObject(action) or action.narciAction then return end
    action.narciAction = true

    local S = Style()

    Kit.Field(action)

    local text = action.GetFontString and action:GetFontString()
    if text then
        text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        text:SetFont(NS.FONT, NS.FS(15), "")
    end

    action:HookScript("OnEnter", function()
        if text then text:SetTextColor(1, 1, 1) end
    end)

    action:HookScript("OnLeave", function()
        if text then text:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]) end
    end)
end

local function SkinPromo(frame)
    local action = _G.PromoCodeFrameContentActionButton
    if IsObject(action) then action.narciSkipAuto = true end

    SkinPlain(frame)
    SkinAction(action)

    local content = _G.PromoCodeFrameContent or frame.Content
    local code = _G.PromoCodeFrameContentCode or (IsObject(content) and content.Code)
    local box = _G.PromoCodeFrameContentCodeEditBox or (IsObject(code) and code.EditBox)

    if IsObject(code) then
        Kit.Strip(code, 2)

        for _, key in ipairs({ "Background", "DividerTop", "DividerBottom",
            "VignetteTopLeft", "VignetteTopRight", "VignetteBottomLeft", "VignetteBottomRight",
            "ShadowTop", "ShadowBottom", "ShadowLeft", "ShadowRight" }) do
            Kit.Dim(code[key])
        end

        code:SetAlpha(1)
        code:Show()
    end

    if IsObject(box) then
        for _, key in ipairs({ "Background", "DecorTop", "DecorBottom", "DecorLeft", "DecorRight" }) do
            Kit.Dim(box[key])
        end

        if (box:GetHeight() or 0) < 16 then box:SetHeight(44) end
        if (box:GetWidth() or 0) < 40 then box:SetWidth(380) end

        box:SetAlpha(1)
        box:Show()
        box:Enable()
        Kit.EditBox(box)

        if not box.narciCodePlate then
            box.narciCodePlate = true
            Kit.PlateBox(box, box:GetWidth(), box:GetHeight(), 0, 0)
        end
    end

    if not frame.narciPromoInput then
        frame.narciPromoInput = true

        local S = Style()

        Kit.PlateBox(frame, 380, 44, 0, 0)

        local input = CreateFrame("EditBox", "NarcissusSirus_PromoInput", frame)
        input:SetSize(370, 40)
        input:SetPoint("CENTER", frame, "CENTER", 0, 0)
        input:SetAutoFocus(false)
        input:SetMaxLetters(24)
        input:SetTextInsets(10, 10, 0, 0)
        input:SetJustifyH("CENTER")
        input:SetFont(NS.FONT, NS.FS(20), "")
        input:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
        input:SetFrameLevel(frame:GetFrameLevel() + 10)

        input:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        input:SetScript("OnTextChanged", function(self, userInput)
            if not userInput then return end

            local text = self:GetText():upper():gsub("[^A-Z0-9]+", "")
            if text ~= self:GetText() then
                self:SetText(text)
                return
            end

            local target = _G.PromoCodeFrameContentCodeEditBox
            if target then pcall(target.SetText, target, text) end
        end)

        input:SetScript("OnEnterPressed", function()
            ActivatePromo()
        end)

        frame:HookScript("OnShow", function()
            input:SetText("")
        end)

        frame.narciInput = input

        if IsObject(action) then
            action:SetScript("OnClick", function()
                ActivatePromo()
            end)
            action:Enable()
        end
    end

    if IsObject(box) then box:SetAlpha(0) end

    if not frame.narciPromoReport then
        frame.narciPromoReport = true

        NS.Print("промокод: content=" .. tostring(IsObject(content))
            .. " code=" .. tostring(IsObject(code))
            .. " box=" .. tostring(IsObject(box))
            .. (IsObject(box) and (" " .. string.format("%.0fx%.0f", box:GetWidth() or 0, box:GetHeight() or 0)
                .. " виден=" .. tostring(box:IsShown())
                .. " альфа=" .. string.format("%.2f", box:GetAlpha() or 0)) or ""))
    end
end

local function DropDownHighlights(frame)
    local name = frame:GetName()
    if not name then return end
    local S = NS.Styling
    local index = 1
    while true do
        local button = _G[name .. "Button" .. index]
        if not button then break end
        local highlight = button.Highlight or _G[name .. "Button" .. index .. "Highlight"]
        if IsObject(highlight) then
            if not highlight.narciKeepVisible then
                highlight.narciKeepVisible = true
                highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                highlight:SetBlendMode("ADD")
            end
            highlight:SetVertexColor(S.ACCENT[1] * 0.45, S.ACCENT[2] * 0.45, S.ACCENT[3] * 0.45, 1)
        end
        index = index + 1
    end
end

local function SkinDropDownList(frame)
    DropDownHighlights(frame)
    if not frame.narciList then
        frame.narciList = true

        Kit.Strip(frame, 2)
        Kit.Ground(frame)
        Kit.Edges(frame, 10, 0.28)
    end

    Kit.Strip(frame, 3)
end

local TARGETS = {
    { name = "HelpFrame", apply = SkinHelp },
    { name = "PromoCodeFrame", apply = SkinPromo },
    { name = "ServerNewsFrame", apply = SkinNews },
    { name = "GameMenuFrameServerAnnounces", apply = SkinNewsPanel },
    { name = "GameMenuFrameServerChanges", apply = SkinNewsPanel },
    { name = "VideoOptionsFrame", apply = SkinOptions },
    { name = "AudioOptionsFrame", apply = SkinOptions },
    { name = "InterfaceOptionsFrame", apply = SkinOptions },
    { name = "KeyBindingFrame", apply = SkinBindings },
    { name = "MacroFrame", apply = SkinMacro },
    { name = "AddonList", apply = SkinPlain },
    { name = "DropDownList1", apply = SkinDropDownList },
    { name = "DropDownList2", apply = SkinDropDownList },
}

local function Run(name, apply, frame)
    local ok, err = pcall(apply, frame)
    pcall(Kit.Ensure, frame)
    if ok then return end

    lastError = name .. ": " .. tostring(err)
    if NS.Print then NS.Print("скин меню " .. lastError) end
end

local function Install(entry)
    if applied[entry.name] then return true end

    local frame = _G[entry.name]
    if not IsObject(frame) then return false end

    applied[entry.name] = true

    if frame.HookScript then
        frame:HookScript("OnShow", function(self)
            if not Enabled() then return end
            Run(entry.name, entry.apply, self)
        end)
    end

    if Enabled() then Run(entry.name, entry.apply, frame) end

    return true
end

local function HookTabs()
    if MenuSkins.tabHook or type(_G.PanelTemplates_SetTab) ~= "function" then return end
    MenuSkins.tabHook = true

    hooksecurefunc("PanelTemplates_SetTab", function(frame, id)
        if not IsObject(frame) or not frame.GetName then return end

        local name = frame:GetName()
        if not name then return end

        for index = 1, (frame.numTabs or 4) do
            local tab = _G[name .. "Tab" .. index]
            if IsObject(tab) and tab.narciTab then Kit.Tab(tab, index == id) end
        end
    end)
end

function MenuSkins:Scan()
    if not Kit then return end

    HookTabs()

    for _, entry in ipairs(TARGETS) do
        Install(entry)
    end
end

function MenuSkins:Redo()
    for _, entry in ipairs(TARGETS) do
        local frame = _G[entry.name]
        if IsObject(frame) then Run(entry.name, entry.apply, frame) end
    end

    if NS.Print then NS.Print("окна меню перерисованы") end
end

function MenuSkins:Status()
    local done, missing = {}, {}

    for _, entry in ipairs(TARGETS) do
        if applied[entry.name] then
            done[#done + 1] = entry.name
        else
            missing[#missing + 1] = entry.name
        end
    end

    NS.Print("скин меню: " .. (Enabled() and "вкл" or "выкл"))
    NS.Print("готово: " .. (#done > 0 and table.concat(done, ", ") or "нет"))
    NS.Print("не найдено: " .. (#missing > 0 and table.concat(missing, ", ") or "нет"))
    if lastError then NS.Print("последняя ошибка окна: " .. lastError) end

    if Kit.lastError then
        NS.Print("ошибок виджетов: " .. tostring(Kit.errors or 0)
            .. ", последняя на " .. tostring(Kit.lastErrorFrame) .. ": " .. Kit.lastError)
    end
end

function MenuSkins:Debug()
    for _, entry in ipairs(TARGETS) do
        local frame = _G[entry.name]

        if not IsObject(frame) then
            NS.Print(entry.name .. ": нет фрейма")
        else
            local ground = frame.narciGround

            NS.Print(entry.name
                .. " окно=" .. tostring(frame.narciWindow and true or false)
                .. " фон=" .. tostring(ground and true or false)
                .. " альфа=" .. tostring(ground and ground:GetAlpha())
                .. " бэкдроп=" .. tostring(frame.GetBackdrop and frame:GetBackdrop() and true or false))
        end
    end
end

local function Mark(node)
    local marks = ""

    for _, key in ipairs({ "narciEdit", "narciButton", "narciRow", "narciField", "narciCheck", "narciTab" }) do
        if node[key] then marks = marks .. key:sub(6) .. " " end
    end

    return marks ~= "" and marks or "-"
end

function MenuSkins:Dump(name, depth)
    local root = _G[name]
    if not IsObject(root) then
        NS.Print("нет фрейма " .. tostring(name))
        return
    end

    depth = tonumber(depth) or 4
    local lines = 0

    Kit.Walk(root, depth, function(node)
        if lines >= 40 then return end
        lines = lines + 1

        local label = (node.GetName and node:GetName()) or "(без имени)"
        local width = node.GetWidth and node:GetWidth() or 0
        local height = node.GetHeight and node:GetHeight() or 0

        NS.Print(node:GetObjectType() .. " " .. label
            .. " " .. string.format("%.0fx%.0f", width, height)
            .. " виден=" .. tostring(node.IsShown and node:IsShown())
            .. " альфа=" .. string.format("%.2f", node.GetAlpha and node:GetAlpha() or 0)
            .. " [" .. Mark(node) .. "]")
    end)
end

function MenuSkins:Toggle()
    if not NS.db then return end

    NS.db.skinMenus = not Enabled()
    NS.Print("скин окон меню: " .. (NS.db.skinMenus and "вкл" or "выкл") .. ", нужен /reload")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function()
    MenuSkins:Scan()

    if NS.After then
        NS.After(2, function() MenuSkins:Scan() end)
    end
end)
