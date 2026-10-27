local addonName, NS = ...

local MailSkin = {}
NS.MailSkin = MailSkin

local WHITE = "Interface\\Buttons\\WHITE8x8"

local DIM_PATHS = {
    "ui%-character%-scrollbar",
    "ui%-classtrainer%-horizontalbar",
    "ui%-classtrainer%-scrollbar",
    "common%-input%-border",
    "collectionsbackgroundtile",
    "ui%-slot%-background",
    "ui%-emptyslot",
    "mail%-icon",
    "mailpopup%-",
}

local OWN_FRAMES = {
    "SendMailCostMoneyFrame", "SendMailMoneyFrame", "SendMailMoney",
    "OpenMailTransactionAmountMoneyFrame", "OpenMailDepositMoneyFrame",
    "OpenMailHouseCutMoneyFrame", "OpenMailSalePriceMoneyFrame",
}

local function Kit()
    return NS.SkinKit
end

local function Style()
    return NS.Styling
end

local function Enabled()
    return not NS.db or NS.db.skinMail ~= false
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
    Kit().Walk(frame, depth or 6, DimByPath)
end

local function Hide(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

local function Slot(button, keepNormal)
    if not button or button.narciMailSlot then return end
    button.narciMailSlot = true
    button.narciOwn = true

    local S = Style()
    local name = button:GetName()

    Kit().StripOne(button)
    DimByPath(button)

    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal and not keepNormal then normal:SetAlpha(0) end
    button.narciKeepNormal = keepNormal

    local ground = button:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(button)
    ground:SetTexture(WHITE)
    ground:SetGradientAlpha("VERTICAL", 0.012, 0.014, 0.020, 1, 0.040, 0.044, 0.060, 1)
    ground.narciKeepVisible = true

    button.narciEdges = S.CreateEdges(button, "OVERLAY", S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)

    local icon = (name and _G[name .. "IconTexture"]) or button.icon or button.Icon
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDrawLayer("BORDER")
    end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(WHITE)
        highlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.22)
        highlight:SetAllPoints(button)
    end
end

local function PaintSlotQuality(button)
    if not button or not button.narciEdges then return end

    local S = Style()
    local r, g, b = S.BORDER[1], S.BORDER[2], S.BORDER[3]

    local name = button:GetName()
    local border = button.IconBorder or (name and _G[name .. "IconBorder"])

    if border and border:IsShown() then
        if not (NS.db and NS.db.mailQuality == false) then r, g, b = border:GetVertexColor() end
        border:SetAlpha(0)
    end

    for _, line in ipairs(button.narciEdges) do
        line:SetVertexColor(r, g, b, 0.95)
    end
end

local function MailRow(item)
    if not item or item.narciMailRow then return end
    item.narciMailRow = true
    item.narciOwn = true

    local S = Style()

    Hide(item.Background)

    local card = item:CreateTexture(nil, "BACKGROUND")
    card:SetPoint("TOPLEFT", item, "TOPLEFT", -4, 3)
    card:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 2, -3)
    card:SetTexture(WHITE)
    card:SetGradientAlpha("HORIZONTAL", 0.040, 0.046, 0.064, 0.95, 0.018, 0.020, 0.028, 0.80)

    local rule = item:CreateTexture(nil, "BORDER")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 0)
    rule:SetTexture(WHITE)
    rule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.35,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.02)

    local bar = item:CreateTexture(nil, "BORDER")
    bar:SetWidth(2)
    bar:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    bar:SetTexture(WHITE)
    bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)

    if item.BackgroundOverlay then
        item.BackgroundOverlay:SetTexture(WHITE)
        item.BackgroundOverlay:ClearAllPoints()
        item.BackgroundOverlay:SetAllPoints(card)
        item.BackgroundOverlay:SetVertexColor(0, 0, 0, 1)
        item.BackgroundOverlay:SetAlpha(0.40)
    end

    if item.BackgroundHighlight then
        item.BackgroundHighlight:SetTexture(WHITE)
        item.BackgroundHighlight:ClearAllPoints()
        item.BackgroundHighlight:SetAllPoints(card)
        item.BackgroundHighlight:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
        item.BackgroundHighlight:SetAlpha(0.14)
    end

    if item.Sender then item.Sender:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3]) end

    item.narciBar = bar

    local button = item.Button
    if button then
        Slot(button)

        local checked = button.GetCheckedTexture and button:GetCheckedTexture()
        if checked then
            checked:SetTexture(WHITE)
            checked:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.30)
            checked:SetAllPoints(button)
        end
    end
end

local function PaintRows()
    local S = Style()

    for index = 1, 12 do
        local item = _G["MailItem" .. index]

        if item and item.narciMailRow then
            Hide(item.Background)

            local read = item.BackgroundOverlay and item.BackgroundOverlay:IsShown()
            item.narciBar:SetShown(not read and not (NS.db and NS.db.mailUnreadMark == false))
            if item.BackgroundOverlay then item.BackgroundOverlay:SetAlpha(((NS.db and NS.db.mailReadDim) or 40) / 100) end

            if item.Sender then
                local tone = read and S.TEXT_NORMAL or S.TEXT_BRIGHT
                item.Sender:SetTextColor(tone[1], tone[2], tone[3])
            end

            if item.Subject then
                local tone = read and S.TEXT_DIM or S.TEXT_NORMAL
                item.Subject:SetTextColor(tone[1], tone[2], tone[3])
            end

            PaintSlotQuality(item.Button)
        end
    end
end

local function Container(frame)
    if not frame or frame.narciMailBox then return end
    frame.narciMailBox = true

    Kit().Strip(frame, 2)
    DimByPath(frame)
    Hide(frame.BackgroundTile)
    Hide(frame.ShadowOverlay)
    Hide(frame.NineSlice)

    Kit().Inset(frame, 0.32)
    Kit().Edges(frame, 18, 0.30)

    if frame.ClassLogo then frame.ClassLogo:SetAlpha(0.10) end
    if frame.FactionLogo then frame.FactionLogo:SetAlpha(0.10) end
end

local function Letter(scroll, left, right)
    if not scroll or scroll.narciLetter then return end
    scroll.narciLetter = true

    Hide(left)
    Hide(right)
    DimTree(scroll, 3)

    local paper = scroll:CreateTexture(nil, "BACKGROUND")
    paper:SetPoint("TOPLEFT", scroll, "TOPLEFT", -4, 4)
    paper:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 24, -4)
    paper:SetTexture(WHITE)
    paper:SetGradientAlpha("VERTICAL", 0.010, 0.012, 0.018, 0.85, 0.030, 0.034, 0.048, 0.85)

    Kit().Edges(scroll, 18, 0.28)
end

local function Window(frame)
    local K = Kit()

    K.Window(frame, { inset = 20, depth = 2 })
    K.StripKeys(frame)
    DimByPath(frame)

    if frame.portrait then frame.portrait:SetAlpha(0) end
    if frame.Inset then
        K.Strip(frame.Inset, 1)
        Hide(frame.Inset.NineSlice)
        Hide(frame.Inset.Bg)
    end

    local S = Style()
    local name = frame:GetName()
    local title = frame.TitleText or (name and _G[name .. "TitleText"])
    if title then title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3]) end

    local close = frame.CloseButton or (name and _G[name .. "CloseButton"])
    if close then
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    end

    for _, key in ipairs(OWN_FRAMES) do
        local own = _G[key]
        if own then own.narciOwn = true end
    end
end

local function MoneyInput()
    local S = Style()

    for _, suffix in ipairs({ "Gold", "Silver", "Copper" }) do
        local box = _G["SendMailMoney" .. suffix]

        if box and not box.narciMoney then
            box.narciMoney = true

            for _, part in ipairs({ "Left", "Middle", "Right" }) do
                Hide(_G["SendMailMoney" .. suffix .. part])
            end
            DimByPath(box)

            local ground = box:CreateTexture(nil, "BACKGROUND")
            ground:SetPoint("TOPLEFT", box, "TOPLEFT", -4, 1)
            ground:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -2, -1)
            ground:SetTexture(WHITE)
            ground:SetVertexColor(NS.Styling.Tint(0.010, 0.012, 0.018, 0.9))

            local line = box:CreateTexture(nil, "BORDER")
            line:SetHeight(1)
            line:SetPoint("BOTTOMLEFT", ground, "BOTTOMLEFT", 0, 0)
            line:SetPoint("BOTTOMRIGHT", ground, "BOTTOMRIGHT", 0, 0)
            line:SetTexture(WHITE)
            line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)

            box:HookScript("OnEditFocusGained", function()
                line:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
            end)

            box:HookScript("OnEditFocusLost", function()
                line:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 1)
            end)
        end
    end
end

local function BodyText()
    local S = Style()

    if _G.SendMailBodyEditBox then
        _G.SendMailBodyEditBox:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end

    if _G.OpenMailBodyText then
        _G.OpenMailBodyText:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end

    for _, key in ipairs({ "OpenMailSenderLabel", "OpenMailSubjectLabel", "OpenMailAttachmentText" }) do
        local label = _G[key]
        if label then label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3]) end
    end

    if _G.OpenMailSender then
        _G.OpenMailSender:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    end

    if _G.OpenMailSubject then
        _G.OpenMailSubject:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    end
end

function MailSkin:SkinInbox()
    local frame = _G.MailFrame
    if not frame or frame.narciMail then return end
    frame.narciMail = true

    local K = Kit()

    Window(frame)

    for index = 1, 12 do MailRow(_G["MailItem" .. index]) end

    local inbox = _G.InboxFrame
    if inbox then
        Container(inbox.LeftContainer or _G.InboxFrameLeftContainer)
        Container(inbox.RightContainer or _G.InboxFrameRightContainer)
    end

    for index = 1, 16 do Slot(_G["SendMailAttachment" .. index], true) end

    Letter(_G.SendMailScrollFrame, _G.SendStationeryBackgroundLeft, _G.SendStationeryBackgroundRight)

    for _, key in ipairs({ "SendMailHorizontalBarLeft", "SendMailHorizontalBarRight",
        "SendMailHorizontalBarLeft2", "SendMailHorizontalBarRight2" }) do
        Hide(_G[key])
    end

    for _, key in ipairs({ "SendMailMoneyInset", "SendMailMoneyBg" }) do
        local box = _G[key]
        if box then
            K.Strip(box, 2)
            Hide(box.NineSlice)
            K.Inset(box, 0.30)
        end
    end

    if _G.SendMailBodyEditBox then _G.SendMailBodyEditBox.narciEdit = true end

    K.Auto(frame, 8)
    DimTree(frame, 8)
    MoneyInput()

    for index = 1, 2 do
        local tab = _G["MailFrameTab" .. index]
        if tab then K.Tab(tab, (frame.selectedTab or 1) == index) end
    end

    BodyText()
    PaintRows()
    MailSkin:PaintSendMail()
end

function MailSkin:SkinOpenMail()
    local frame = _G.OpenMailFrame
    if not frame or frame.narciMail then return end
    frame.narciMail = true

    Window(frame)

    for index = 1, 16 do Slot(_G["OpenMailAttachmentButton" .. index]) end
    Slot(_G.OpenMailLetterButton)
    Slot(_G.OpenMailMoneyButton)

    Letter(_G.OpenMailScrollFrame, _G.OpenStationeryBackgroundLeft, _G.OpenStationeryBackgroundRight)

    Hide(_G.OpenMailHorizontalBarLeft)
    Hide(_G.OpenMailHorizontalBarRight)

    Kit().Auto(frame, 8)
    DimTree(frame, 8)

    BodyText()
end

function MailSkin:PaintOpenMail()
    for index = 1, 16 do PaintSlotQuality(_G["OpenMailAttachmentButton" .. index]) end
    PaintSlotQuality(_G.OpenMailLetterButton)
    PaintSlotQuality(_G.OpenMailMoneyButton)
    BodyText()
end

function MailSkin:PaintSendMail()
    for index = 1, 16 do
        local button = _G["SendMailAttachment" .. index]
        local icon = button and button:GetNormalTexture()

        if icon then
            icon:SetAlpha(1)
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        PaintSlotQuality(button)
    end
    BodyText()
end

function MailSkin:Hook()
    if self.hooked then return end
    self.hooked = true

    if type(_G.InboxFrame_Update) == "function" then
        hooksecurefunc("InboxFrame_Update", function()
            if Enabled() and _G.MailFrame and _G.MailFrame.narciMail then PaintRows() end
        end)
    end

    if type(_G.OpenMail_Update) == "function" then
        hooksecurefunc("OpenMail_Update", function()
            if Enabled() and _G.OpenMailFrame and _G.OpenMailFrame.narciMail then MailSkin:PaintOpenMail() end
        end)
    end

    if type(_G.SendMailFrame_Update) == "function" then
        hooksecurefunc("SendMailFrame_Update", function()
            if Enabled() and _G.MailFrame and _G.MailFrame.narciMail then MailSkin:PaintSendMail() end
        end)
    end

    if type(_G.SendMailFrame_UpdateStationery) == "function" then
        hooksecurefunc("SendMailFrame_UpdateStationery", function()
            Hide(_G.SendStationeryBackgroundLeft)
            Hide(_G.SendStationeryBackgroundRight)
        end)
    end
end

function MailSkin:Apply()
    if not Enabled() or not Kit() then return end

    self:Hook()

    local ok, err = pcall(function()
        MailSkin:SkinInbox()
        MailSkin:SkinOpenMail()
    end)

    if not ok and NS.Print then NS.Print("почта: " .. tostring(err)) end
end

local function PaintSlotColor(button, r, g, b)
    if not button or not button.narciEdges then return end

    if not r then
        local S = Style()
        r, g, b = S.BORDER[1], S.BORDER[2], S.BORDER[3]
    end

    for _, line in ipairs(button.narciEdges) do
        line:SetVertexColor(r, g, b, 0.95)
    end
end

MailSkin.Slot = Slot
MailSkin.PaintSlotColor = PaintSlotColor
MailSkin.DimByPath = DimByPath
MailSkin.Window = Window
MailSkin.Hide = Hide

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("MAIL_SHOW")

driver:SetScript("OnEvent", function()
    MailSkin:Apply()
end)
