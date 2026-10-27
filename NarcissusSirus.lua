local addonName, NS = ...
local L = NS.L


local function IsOpen(module)
    return module and module.frame and module.frame:IsShown() and true or false
end

function NS:OnPlayerLogin()
    if NS.Styling and NS.Styling.ApplyAccent and NS.db then
        NS.Styling.ApplyAccent(NS.db.accentColor or "emerald")
        NS.Styling.ApplyTheme(NS.db.theme)
    end

    if NS.GuildAdmin then
        NS.After(5, function() NS.GuildAdmin:Restore() end)
    end

    if NS.NarciUI and NS.NarciUI.RepairNames then NS.NarciUI:RepairNames() end

    if PlayerTalentFrame and not PlayerTalentFrame._narciGlyphHook then
        PlayerTalentFrame._narciGlyphHook = true
        PlayerTalentFrame:HookScript("OnShow", function(self)
            if InCombatLockdown() then return end
            if NS.NarciUI and NS.NarciUI.isShown then
                NS.After(0, function()
                    if InCombatLockdown() then return end
                    if PlayerTalentFrame:IsShown() then HideUIPanel(PlayerTalentFrame) end
                    NS:OpenTalentPanel()
                end)
                return
            end

            if NS.db and NS.db.replaceTalents == false then return end

            NS.After(0, function()
                if InCombatLockdown() then return end
                if PlayerTalentFrame:IsShown() then HideUIPanel(PlayerTalentFrame) end
                NS:OpenTalentPanel()
            end)
        end)
    end

    if SpellBookFrame and not SpellBookFrame._narciHook then
        SpellBookFrame._narciHook = true
        SpellBookFrame:HookScript("OnShow", function(self)
            if InCombatLockdown() then return end
            if NS.NarciUI and NS.NarciUI.isShown then
                NS.After(0, function()
                    if InCombatLockdown() then return end
                    if SpellBookFrame:IsShown() then HideUIPanel(SpellBookFrame) end
                    NS:OpenSpellBookPanel()
                end)
                return
            end

            if NS.db and NS.db.replaceSpellbook == false then return end

            NS.After(0, function()
                if InCombatLockdown() then return end
                if SpellBookFrame:IsShown() then HideUIPanel(SpellBookFrame) end
                NS:OpenSpellBookPanel()
            end)
        end)
    end

    local function OpenGuildPanel()
        if NS.db and NS.db.replaceGuild == false then return end
        if InCombatLockdown() then return end
        if not NS.GuildPanel then return end

        local wasOpen = IsOpen(NS.GuildPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if GuildFrame and GuildFrame:IsShown() then HideUIPanel(GuildFrame) end

            if wasOpen then
                NS.GuildPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.GuildPanel:Show() end)
            if not ok then
                NS.Print("окно гильдии: " .. tostring(err))
            end
        end)
    end

    NS.OpenGuildPanel = OpenGuildPanel

    local function HookGuildFrame()
        if not GuildFrame or GuildFrame._narciHook then return end
        GuildFrame._narciHook = true
        GuildFrame:HookScript("OnShow", OpenGuildPanel)
    end

    HookGuildFrame()

    if ToggleGuildFrame then
        hooksecurefunc("ToggleGuildFrame", function()
            HookGuildFrame()
            if not GuildFrame or not GuildFrame:IsShown() then
                if IsInGuild and IsInGuild() then OpenGuildPanel() end
            end
        end)
    end

    local guildLoader = CreateFrame("Frame")
    guildLoader:RegisterEvent("ADDON_LOADED")
    guildLoader:SetScript("OnEvent", function() HookGuildFrame() end)

    local function OpenGroupFinder()
        if NS.db and NS.db.replaceGroupFinder == false then return end
        if InCombatLockdown() then return end
        if not NS.GroupFinderPanel then return end

        local wasOpen = IsOpen(NS.GroupFinderPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if LFDParentFrame and LFDParentFrame:IsShown() then HideUIPanel(LFDParentFrame) end

            if wasOpen then
                NS.GroupFinderPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.GroupFinderPanel:Show() end)
            if not ok then NS.Print("поиск группы: " .. tostring(err)) end
        end)
    end

    NS.OpenGroupFinder = OpenGroupFinder

    local function OpenGroupFinderTab(tab, clientFrame)
        if NS.db and NS.db.replaceGroupFinder == false then return end
        if InCombatLockdown() then return end
        local panel = NS.GroupFinderPanel
        if not panel then return end

        local wasOpen = IsOpen(panel) and panel.tab == tab

        NS.After(0, function()
            if InCombatLockdown() then return end
            if clientFrame and clientFrame:IsShown() then HideUIPanel(clientFrame) end
            if LFDParentFrame and LFDParentFrame:IsShown() then HideUIPanel(LFDParentFrame) end

            if wasOpen then
                panel:Hide()
                return
            end

            panel.tab = tab
            local ok, err = pcall(function()
                if IsOpen(panel) then panel:Update() else panel:Show() end
            end)
            if not ok then NS.Print("поиск группы: " .. tostring(err)) end
        end)
    end

    NS.OpenGroupFinderTab = OpenGroupFinderTab

    local function OpenCollections()
        if NS.db and NS.db.replaceCollections == false then return end
        if InCombatLockdown() then return end
        if not NS.CollectionsPanel then return end

        local wasOpen = IsOpen(NS.CollectionsPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if CollectionsJournal and CollectionsJournal:IsShown() then HideUIPanel(CollectionsJournal) end

            if wasOpen then
                NS.CollectionsPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.CollectionsPanel:Show() end)
            if not ok then NS.Print("коллекция: " .. tostring(err)) end
        end)
    end

    NS.OpenCollections = OpenCollections

    local function OpenAchievements()
        if NS.db and NS.db.replaceAchievements == false then return end
        if InCombatLockdown() then return end
        if not NS.AchievementsPanel then return end

        local wasOpen = IsOpen(NS.AchievementsPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if AchievementFrame and AchievementFrame:IsShown() then HideUIPanel(AchievementFrame) end

            if wasOpen then
                NS.AchievementsPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.AchievementsPanel:Show() end)
            if not ok then NS.Print("достижения: " .. tostring(err)) end
        end)
    end

    NS.OpenAchievements = OpenAchievements

    local function OpenAdventure()
        if NS.db and NS.db.replaceAdventure == false then return end
        if InCombatLockdown() then return end
        if not NS.AdventurePanel then return end

        local wasOpen = IsOpen(NS.AdventurePanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if EncounterJournal and EncounterJournal:IsShown() then HideUIPanel(EncounterJournal) end

            if wasOpen then
                NS.AdventurePanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.AdventurePanel:Show() end)
            if not ok then NS.Print("приключения: " .. tostring(err)) end
        end)
    end

    NS.OpenAdventure = OpenAdventure

    local function OpenChallenges()
        if NS.db and NS.db.replaceChallenges == false then return end
        if InCombatLockdown() then return end
        if not NS.ChallengePanel then return end

        local wasOpen = IsOpen(NS.ChallengePanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if HardcoreFrame and HardcoreFrame:IsShown() then HideUIPanel(HardcoreFrame) end

            if wasOpen then
                NS.ChallengePanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.ChallengePanel:Show() end)
            if not ok then NS.Print("испытания: " .. tostring(err)) end
        end)
    end

    NS.OpenChallenges = OpenChallenges

    local function OpenHeadHunting()
        if NS.db and NS.db.replaceHeadHunting == false then return end
        if InCombatLockdown() then return end
        if not NS.HeadHuntingPanel then return end

        local wasOpen = IsOpen(NS.HeadHuntingPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if HeadHuntingFrame and HeadHuntingFrame:IsShown() then HideUIPanel(HeadHuntingFrame) end

            if wasOpen then
                NS.HeadHuntingPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.HeadHuntingPanel:Show() end)
            if not ok then NS.Print("охота за головами: " .. tostring(err)) end
        end)
    end

    NS.OpenHeadHunting = OpenHeadHunting

    local function OpenSocial()
        if NS.db and NS.db.replaceSocial == false then return end
        if InCombatLockdown() then return end
        if not NS.SocialPanel then return end

        local wasOpen = IsOpen(NS.SocialPanel)

        NS.After(0, function()
            if InCombatLockdown() then return end
            if FriendsFrame and FriendsFrame:IsShown() then HideUIPanel(FriendsFrame) end

            if wasOpen then
                NS.SocialPanel:Hide()
                return
            end

            local ok, err = pcall(function() NS.SocialPanel:Show() end)
            if not ok then NS.Print("общение: " .. tostring(err)) end
        end)
    end

    NS.OpenSocial = OpenSocial

    if FriendsFrame and not FriendsFrame._narciHook then
        FriendsFrame._narciHook = true
        FriendsFrame:HookScript("OnShow", OpenSocial)
    end

    local function HookHeadHuntingFrame()
        if HeadHuntingFrame and not HeadHuntingFrame._narciHook then
            HeadHuntingFrame._narciHook = true
            HeadHuntingFrame:HookScript("OnShow", OpenHeadHunting)
        end
    end

    HookHeadHuntingFrame()

    local function HookChallengeFrame()
        if HardcoreFrame and not HardcoreFrame._narciHook then
            HardcoreFrame._narciHook = true
            HardcoreFrame:HookScript("OnShow", OpenChallenges)
        end
    end

    HookChallengeFrame()

    local function HookAdventureFrame()
        if EncounterJournal and not EncounterJournal._narciHook then
            EncounterJournal._narciHook = true
            EncounterJournal:HookScript("OnShow", OpenAdventure)
        end
    end

    HookAdventureFrame()

    local function HookAchievementFrame()
        if AchievementFrame and not AchievementFrame._narciHook then
            AchievementFrame._narciHook = true
            AchievementFrame:HookScript("OnShow", OpenAchievements)
        end
    end

    HookAchievementFrame()

    local achievementLoader = CreateFrame("Frame")
    achievementLoader:RegisterEvent("ADDON_LOADED")
    achievementLoader:SetScript("OnEvent", function()
        HookAchievementFrame()
        HookAdventureFrame()
        HookChallengeFrame()
        HookHeadHuntingFrame()
    end)

    if CollectionsJournal and not CollectionsJournal._narciHook then
        CollectionsJournal._narciHook = true
        CollectionsJournal:HookScript("OnShow", OpenCollections)
    end

    if LFDParentFrame and not LFDParentFrame._narciHook then
        LFDParentFrame._narciHook = true
        LFDParentFrame:HookScript("OnShow", OpenGroupFinder)
    end

    for frameName, tab in pairs({ PVPUIFrame = "pvp", ChallengesFrame = "mythic", LadderFrame = "ladder" }) do
        local frame = _G[frameName]
        if frame and not frame._narciHook then
            frame._narciHook = true
            frame:HookScript("OnShow", function(self) OpenGroupFinderTab(tab, self) end)
        end
    end

    if type(_G.LFGListFrame_BeginFindAppID) == "function" and not NS.premadeLinkHooked then
        NS.premadeLinkHooked = true
        hooksecurefunc("LFGListFrame_BeginFindAppID", function(_, appID, activityID, categoryID)
            if NS.db and NS.db.replaceGroupFinder == false then return end
            if not appID or not NS.GroupFinderPanel or not NS.PremadeGroupsPage then return end
            if activityID and C_LFGList and C_LFGList.GetActivityInfoTable then
                local info = C_LFGList.GetActivityInfoTable(activityID)
                if info then categoryID = info.categoryID end
            end
            if not categoryID then return end
            NS.After(0, function()
                if InCombatLockdown() then return end
                if LFDParentFrame and LFDParentFrame:IsShown() then HideUIPanel(LFDParentFrame) end
                local panel, page = NS.GroupFinderPanel, NS.PremadeGroupsPage
                panel.tab = "lfg"
                panel.category = "premade"
                page.categoryID = categoryID
                page.groupID = 0
                page.activityID = nil
                page.mode = "browse"
                page.searched = true
                local ok, err = pcall(function()
                    panel:Show()
                    if page.frame then
                        if page.frame.search then page.frame.search:SetText("") end
                        page.selectedResult = nil
                        page.searching = true
                        page:Update()
                        NS.After(1.5, function()
                            page.searching = false
                            if page.frame and page.frame:IsShown() then page:Update() end
                        end)
                        NS.After(3, function()
                            if not (page.frame and page.frame:IsShown()) then return end
                            if page.mode ~= "own" and page.categoryID == categoryID and #page:Results() == 0 then
                                page:Search()
                            end
                        end)
                    end
                end)
                if not ok then NS.Print("поиск группы: " .. tostring(err)) end
            end)
        end)
    end

    if NS.CharFrame then
        NS.CharFrame:Init()
    end

    if NS.ItemComparison and NS.db.showComparison then
        NS.ItemComparison:Enable()
    end

    if NS.SlotFlyout then
        NS.SlotFlyout:Create()
    end

    NS.After(3, function()
        if InCombatLockdown() then return end
        if NS.NarciUI and not NS.NarciUI.mainFrame then
            NS.NarciUI:Create()
        end
        if NS.ProfessionsPanel and not NS.ProfessionsPanel.frame then
            NS.ProfessionsPanel:Create()
            NS.ProfessionsPanel:Update()
            NS.ProfessionsPanel:Hide()
        end
        if NS.SpellBookPanel and not NS.SpellBookPanel.frame then
            NS.SpellBookPanel:Create()
            NS.SpellBookPanel:Hide()
        end
    end)

    if NS.db.minimapButton and NS.MinimapButton then
        NS.MinimapButton:Show()
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("COMBAT_RATING_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    eventFrame:RegisterEvent("GLYPH_UPDATED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("PLAYER_MONEY")

    local slotsPending, statsPending, modelPending = false, false, false

    local function RefreshEquipment()
        slotsPending = false
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:UpdateSlots()
            NS.NarciUI:UpdatePlayerInfo()
        end
        if CharacterFrame and CharacterFrame:IsShown() then
            if NS.CharFrame then NS.CharFrame:UpdateInfoPanel() end
            if NS.ItemLevel then NS.ItemLevel:Update() end
            if NS.EnchantInfo then NS.EnchantInfo:Update() end
        end
    end

    local function RefreshStats()
        statsPending = false
        if NS.StatsPanel and NS.StatsPanel.frame and NS.StatsPanel.frame:IsShown() then
            NS.StatsPanel:Update()
        end
        if NS.TalentPanel and NS.TalentPanel.frame and NS.TalentPanel.frame:IsShown() then
            NS.TalentPanel:Update()
        end
    end

    local function RefreshModel()
        modelPending = false
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:RefreshModel()
        end
    end

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED")
           and arg1 ~= "player" then
            return
        end

        local equipmentChanged = event == "PLAYER_EQUIPMENT_CHANGED"
                              or event == "UNIT_INVENTORY_CHANGED"

        if equipmentChanged then
            if not slotsPending then
                slotsPending = true
                NS.After(0.1, RefreshEquipment)
            end
        end

        if equipmentChanged
           or event == "UNIT_MODEL_CHANGED"
           or event == "UPDATE_SHAPESHIFT_FORM" then
            if not modelPending then
                modelPending = true
                NS.After(0.1, RefreshModel)
            end
        end

        if not statsPending then
            statsPending = true
            NS.After(0.1, RefreshStats)
        end
    end)

    NS.Print(L["Загружен! Введите |cff00ccff/narci|r для списка команд."])
end

function NS:ToggleCharacterUI()
    if NS.NarciUI then
        NS.NarciUI:Toggle()
    else
        if CharacterFrame then
            if CharacterFrame:IsShown() then
                HideUIPanel(CharacterFrame)
            else
                ShowUIPanel(CharacterFrame)
            end
        end
    end
end

function NS:ToggleSettings()
    if NS.Settings then
        NS.Settings:Toggle()
    else
        NS.Print(L["Настройки не загружены, перезапустите клиент"])
    end
end

local EXCLUSIVE_PANELS = { "StatsPanel", "Enhancements", "TalentPanel", "ProfessionsPanel",
                           "TitleManager", "OutfitManager", "ReputationPanel", "CurrencyPanel" }

NS.EXTRA_PANELS = NS.EXTRA_PANELS or {}

local function EachPanel()
    local list = {}
    for _, name in ipairs(EXCLUSIVE_PANELS) do list[#list + 1] = name end
    for _, name in ipairs(NS.EXTRA_PANELS) do list[#list + 1] = name end
    return ipairs(list)
end

function NS:HideAllPanels()
    for _, name in EachPanel() do
        local panel = NS[name]
        if panel and panel.Hide then panel:Hide() end
    end
    if NS.NarciUI and NS.NarciUI.UpdateToolbarState then
        NS.NarciUI:UpdateToolbarState()
    end
end

local function TogglePanel(name)
    local panel = NS[name]
    if not panel then
        NS.Print(L["Модуль не загружен: "] .. name)
        return
    end
    local opening = not (panel.frame and panel.frame:IsShown())

    for _, other in EachPanel() do
        if other ~= name then
            local p = NS[other]
            if p and p.frame and p.frame:IsShown() then
                NS.Styling.PanelOut(p.frame)
            end
        end
    end

    panel:Toggle()
    NS.Styling.Sound("igCharacterInfoTab")
    if NS.NarciUI and NS.NarciUI.UpdateToolbarState then
        NS.NarciUI:UpdateToolbarState(opening and name or nil)
    end
end

function NS:TogglePanelByName(name) TogglePanel(name) end

function NS:OpenSpellBookPanel()
    if not NS.SpellBookPanel then return end

    if IsOpen(NS.SpellBookPanel) then
        NS.SpellBookPanel:Hide()
    else
        NS.SpellBookPanel:Show()
    end
end

function NS:OpenTalentPanel()
    local ui = NS.NarciUI
    if not ui then return end

    if not ui.isShown then
        ui:Show("TalentPanel")
        return
    end

    local panel = NS.TalentPanel
    if IsOpen(panel) then
        ui:Hide()
    elseif panel then
        TogglePanel("TalentPanel")
    end
end

function NS:ToggleStatsPanel()    TogglePanel("StatsPanel")    end
function NS:ToggleEnhancements()  TogglePanel("Enhancements")  end
function NS:ToggleTalentPanel()   TogglePanel("TalentPanel")   end
function NS:ToggleProfessions()   TogglePanel("ProfessionsPanel") end
function NS:ToggleGuildPanel()
    if NS.GuildPanel then NS.GuildPanel:Toggle() end
end

function NS:ToggleSpellBook()
    if NS.SpellBookPanel then NS.SpellBookPanel:Toggle() end
end
function NS:ToggleTitleManager()  TogglePanel("TitleManager")  end
function NS:ToggleOutfitManager() TogglePanel("OutfitManager") end
function NS:ToggleReputation()    TogglePanel("ReputationPanel") end
function NS:ToggleCurrency()      TogglePanel("CurrencyPanel")   end

function NS:ToggleCharPreview()
    if NS.CharPreview then
        NS.CharPreview:Toggle()
    end
end

function NS:TakeScreenshot()
    if NS.ScreenshotTool then
        NS.ScreenshotTool:Take(not (NS.db and NS.db.shotHideUI == false))
    end
end
