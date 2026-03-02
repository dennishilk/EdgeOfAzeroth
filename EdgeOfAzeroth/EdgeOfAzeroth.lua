EOA_DATA = EOA_DATA or {}

EdgeOfAzeroth = EdgeOfAzeroth or {}
local EOA = EdgeOfAzeroth

EOA.locale = "EN"

function EOA:T(key)
    local L = {
        EN = {
            MODE = "Mode",
            SEARCH = "Search",
            RESULTS = "Results",
            START_NAV = "Start Navigation",
            STOP_NAV = "Stop Navigation",
            SET_TARGET_TO_MY_POSITION = "Set Target to My Position",
            SAVE_CUSTOM_SPOT = "Save Custom Spot",
            FAVORITE = "Favorite",
            UNFAVORITE = "Unfavorite",
            EXPLORER_MODE = "Explorer Mode",
            RECORD_CURRENT_SPOT = "Record Current Spot",
            SELECT_A_DESTINATION = "Select a destination to view details.",
            NO_MATCHING_RESULTS = "No matching results.",
            NO_RESULTS = "No results",
            ZONE = "Zone",
            ON = "ON",
            OFF = "OFF",
        }
    }

    local localeTable = L[self.locale] or L.EN
    return localeTable[key] or key
end

EOA.initialized = false
EOA.navigationActive = false
EOA.activeEntry = nil
EOA.filteredEntries = {}
EOA.selectedEntryID = nil
EOA.currentMode = "ALL"
EOA.currentFarmCategory = "ALL"
EOA.smoothDistance = nil
EOA.updateAccumulator = 0
EOA.updateRate = 0.10
EOA.defaultYardsPerUnit = 10000
EOA.explorerModeEnabled = false
EOA.explorerUpdateAccumulator = 0

local FIELD_RESEARCH_CATEGORIES = {
    { value = "DUNGEON", text = "DUNGEON" },
    { value = "CLOTH", text = "CLOTH" },
    { value = "MINING", text = "MINING" },
    { value = "HERBS", text = "HERBS" },
    { value = "GRIND", text = "GRIND" },
}

local DENSITY_OPTIONS = {
    { value = 1, text = "1" },
    { value = 2, text = "2" },
    { value = 3, text = "3" },
    { value = 4, text = "4" },
    { value = 5, text = "5" },
}

local MODE_OPTIONS = {
    { value = "ALL", text = "All" },
    { value = "SCENIC", text = "Screenshots" },
    { value = "DUNGEON", text = "Dungeons" },
    { value = "RAID", text = "Raids" },
    { value = "FARM", text = "Farming" },
    { value = "FAVORITES", text = "Favorites" },
}

local FARM_CATEGORY_OPTIONS = {
    { value = "ALL", text = "ALL" },
    { value = "XP", text = "XP" },
    { value = "CLOTH", text = "CLOTH" },
    { value = "HERBS", text = "HERBS" },
    { value = "MINING", text = "MINING" },
    { value = "REPUTATION", text = "REPUTATION" },
    { value = "TREASURE", text = "TREASURE" },
}

local TYPE_LABELS = {
    SCENIC = "Screenshots",
    DUNGEON = "Dungeon",
    RAID = "Raid",
    FARM = "Farm",
}

local function GetMapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if info and info.name then
        return info.name
    end
    return string.format("Map %d", tonumber(mapID) or 0)
end

local function GetProfessionSkillByName(skillName)
    if not GetProfessions or not GetProfessionInfo then
        return nil
    end

    local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
    local professions = { prof1, prof2, archaeology, fishing, cooking, firstAid }
    for _, prof in ipairs(professions) do
        if prof then
            local name, _, rank = GetProfessionInfo(prof)
            if name == skillName then
                return rank
            end
        end
    end

    return nil
end

local function GetPlayerTargetSnapshot()
    local mapID, x, y = EOA:GetPlayerMapPosition()
    local zoneName = mapID and GetMapName(mapID) or "Unknown"
    local targetName = UnitExists("target") and UnitName("target") or nil
    local targetLevel = UnitExists("target") and UnitLevel("target") or nil

    return {
        mapID = mapID,
        x = x,
        y = y,
        zoneName = zoneName,
        targetName = targetName,
        targetLevel = targetLevel,
        playerLevel = UnitLevel("player") or 0,
        miningLevel = GetProfessionSkillByName("Mining"),
        herbalismLevel = GetProfessionSkillByName("Herbalism"),
    }
end

local function EnsureDB()
    EdgeOfAzerothDB = EdgeOfAzerothDB or {}
    EdgeOfAzerothDB.customSpots = EdgeOfAzerothDB.customSpots or {}
    EdgeOfAzerothDB.calibrated = EdgeOfAzerothDB.calibrated or {}
    EdgeOfAzerothDB.favorites = EdgeOfAzerothDB.favorites or {}
end

local function GetEntryCoords(entry)
    if not entry then
        return nil, nil, nil
    end

    local cal = EdgeOfAzerothDB and EdgeOfAzerothDB.calibrated and EdgeOfAzerothDB.calibrated[entry.id]
    if cal and cal.mapID and cal.x and cal.y then
        return cal.mapID, cal.x, cal.y
    end

    return entry.mapID, entry.x, entry.y
end

local function MergeStaticDataEntries()
    local merged = {}

    if type(EOA_DATA) == "table" then
        for _, categoryTable in pairs(EOA_DATA) do
            if type(categoryTable) == "table" then
                for _, entry in ipairs(categoryTable) do
                    merged[#merged + 1] = entry
                end
            end
        end
    end

    return merged
end

local function MergeAllEntries()
    local merged = MergeStaticDataEntries()

    for _, custom in ipairs(EdgeOfAzerothDB.customSpots) do
        merged[#merged + 1] = custom
    end

    for _, entry in ipairs(merged) do
        if entry.type == "FARM" then
            if entry.category == "XP" or entry.category == "CLOTH" or entry.category == "REPUTATION" or entry.category == "TREASURE" then
                entry.levelRecommended = entry.levelRecommended or entry.levelMin or 0
            elseif entry.category == "HERBS" or entry.category == "MINING" then
                entry.skillRequired = entry.skillRequired or 0
            end
        end
    end

    return merged
end

function EOA:GetEntryByID(id)
    if not id then
        return nil
    end

    for _, entry in ipairs(MergeAllEntries()) do
        if entry.id == id then
            return entry
        end
    end

    return nil
end

local function EntryMatchesSearch(entry, search)
    if not search or search == "" then
        return true
    end

    local needle = string.lower(search)
    local haystack = string.lower(entry.name or "") .. "\n" .. string.lower(entry.description or "")

    if string.find(haystack, needle, 1, true) then
        return true
    end

    if entry.tags then
        for _, tag in ipairs(entry.tags) do
            if string.find(string.lower(tag), needle, 1, true) then
                return true
            end
        end
    end

    return false
end

local function EntryMatchesFilters(entry, mode, search)
    if mode == "SCENIC" and entry.type ~= "SCENIC" then
        return false
    elseif mode == "DUNGEON" and entry.type ~= "DUNGEON" then
        return false
    elseif mode == "RAID" and entry.type ~= "RAID" then
        return false
    elseif mode == "FARM" then
        if entry.type ~= "FARM" then
            return false
        end

        if EOA.currentFarmCategory ~= "ALL" and entry.category ~= EOA.currentFarmCategory then
            return false
        end
    elseif mode == "FAVORITES" and not EdgeOfAzerothDB.favorites[entry.id] then
        return false
    end

    return EntryMatchesSearch(entry, search)
end

function EOA:GetPlayerMapPosition()
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    if not position or not position.x or not position.y then
        return nil
    end

    return mapID, position.x, position.y
end

function EOA:RefreshFilteredEntries()
    if not self.ui or not self.ui.searchBox then
        return
    end

    local search = self.ui.searchBox:GetText() or ""
    self.filteredEntries = {}

    for _, entry in ipairs(MergeAllEntries()) do
        if EntryMatchesFilters(entry, self.currentMode, search) then
            self.filteredEntries[#self.filteredEntries + 1] = entry
        end
    end

    if self.currentMode == "DUNGEON" then
        table.sort(self.filteredEntries, function(a, b)
            if a.levelMin ~= b.levelMin then
                return (a.levelMin or 0) < (b.levelMin or 0)
            end

            if a.levelMax ~= b.levelMax then
                return (a.levelMax or 0) < (b.levelMax or 0)
            end

            return (a.name or "") < (b.name or "")
        end)
    elseif self.currentMode == "RAID" then
        table.sort(self.filteredEntries, function(a, b)
            return (a.levelMin or 0) < (b.levelMin or 0)
        end)
    elseif self.currentMode == "FARM" then
        table.sort(self.filteredEntries, function(a, b)
            local cat = self.currentFarmCategory

            if cat == "XP" or cat == "CLOTH" then
                local function getLevel(entry)
                    return entry.levelRecommended
                        or 0
                end

                return getLevel(a) < getLevel(b)
            elseif cat == "HERBS" or cat == "MINING" then
                local aSkill = a.skillRequired or 0
                local bSkill = b.skillRequired or 0
                if aSkill ~= bSkill then
                    return aSkill < bSkill
                end
            elseif cat == "REPUTATION" or cat == "TREASURE" then
                local aRec = a.levelRecommended or 0
                local bRec = b.levelRecommended or 0
                if aRec ~= bRec then
                    return aRec < bRec
                end
            else
                local function getProgressionValue(entry)
                    if entry.category == "HERBS" or entry.category == "MINING" then
                        return entry.skillRequired or 0
                    end

                    return entry.levelRecommended or 0
                end

                local aProgression = getProgressionValue(a)
                local bProgression = getProgressionValue(b)
                if aProgression ~= bProgression then
                    return aProgression < bProgression
                end
            end

            return (a.name or "") < (b.name or "")
        end)
    end

    local selectedStillVisible = false
    for _, entry in ipairs(self.filteredEntries) do
        if entry.id == self.selectedEntryID then
            selectedStillVisible = true
            break
        end
    end

    if not selectedStillVisible then
        self.selectedEntryID = self.filteredEntries[1] and self.filteredEntries[1].id or nil
    end

    self:RefreshResultsList()
    self:UpdateSelectionUI()
end

function EOA:GetSelectedEntry()
    return self:GetEntryByID(self.selectedEntryID)
end

function EOA:UpdateDescriptionHeight()
    local text = self.ui.descriptionText
    local scrollChild = self.ui.descriptionScrollChild
    local width = self.ui.descriptionScrollFrame:GetWidth() - 24
    if width < 20 then
        width = 20
    end

    text:SetWidth(width)
    local textHeight = text:GetStringHeight() + 16
    if textHeight < 180 then
        textHeight = 180
    end
    scrollChild:SetHeight(textHeight)
end

function EOA:UpdateSelectionUI()
    local entry = self:GetSelectedEntry()
    if not entry then
        self.ui.descriptionText:SetText(self:T("NO_MATCHING_RESULTS"))
        self:UpdateDescriptionHeight()
        self:UpdateWorldMapPin(nil)
        self.ui.favoriteButton:SetText(self:T("FAVORITE"))
        return
    end

    local zoneName = GetMapName(entry.mapID)
    self.ui.descriptionText:SetText(
        (entry.description or "") ..
        "\n\n" .. self:T("ZONE") .. ": " .. zoneName
    )
    self:UpdateDescriptionHeight()

    local favored = EdgeOfAzerothDB.favorites[entry.id]
    if favored then
        self.ui.favoriteButton:SetText(self:T("UNFAVORITE"))
    else
        self.ui.favoriteButton:SetText(self:T("FAVORITE"))
    end

    self:UpdateWorldMapPin(entry)
end

function EOA:RefreshModeDropdown()
    UIDropDownMenu_Initialize(self.ui.modeDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for _, mode in ipairs(MODE_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = mode.text
            info.checked = (self.currentMode == mode.value)
            info.func = function()
                self.currentMode = mode.value
                UIDropDownMenu_SetText(self.ui.modeDropdown, mode.text)
                self:UpdateFarmCategoryVisibility()
                self:RefreshFilteredEntries()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local currentText = "All"
    for _, mode in ipairs(MODE_OPTIONS) do
        if mode.value == self.currentMode then
            currentText = mode.text
            break
        end
    end
    UIDropDownMenu_SetText(self.ui.modeDropdown, currentText)
end

function EOA:RefreshFarmCategoryDropdown()
    UIDropDownMenu_Initialize(self.ui.farmCategoryDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for _, category in ipairs(FARM_CATEGORY_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = category.text
            info.checked = (self.currentFarmCategory == category.value)
            info.func = function()
                self.currentFarmCategory = category.value
                UIDropDownMenu_SetText(self.ui.farmCategoryDropdown, category.text)
                self:RefreshFilteredEntries()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(self.ui.farmCategoryDropdown, self.currentFarmCategory)
end

function EOA:UpdateFarmCategoryVisibility()
    if not self.ui or not self.ui.farmCategoryDropdown then
        return
    end

    local show = (self.currentMode == "FARM")
    if show then
        self.ui.farmCategoryLabel:Show()
        self.ui.farmCategoryDropdown:Show()
        self.ui.resultsLabel:ClearAllPoints()
        self.ui.resultsLabel:SetPoint("TOPLEFT", self.ui.farmCategoryDropdown, "BOTTOMLEFT", 16, -8)
    else
        self.ui.farmCategoryLabel:Hide()
        self.ui.farmCategoryDropdown:Hide()
        self.ui.resultsLabel:ClearAllPoints()
        self.ui.resultsLabel:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 16, -96)
    end
end

local function GetEntryDisplayText(entry)
    local displayText = entry.name or "Unknown"
    if entry.category == "HERBS" or entry.category == "MINING" then
        displayText = displayText .. " [Skill " .. (entry.skillRequired or 0) .. "]"
    elseif entry.category == "XP" or entry.category == "CLOTH" then
        local level = entry.levelRecommended
            or 0

        displayText = displayText .. " [" .. level .. "+]"
    elseif entry.category == "REPUTATION" or entry.category == "TREASURE" then
        displayText = displayText .. " [" .. (entry.levelRecommended or 0) .. "+]"
    elseif entry.levelMin and entry.levelMax then
        displayText = displayText .. " [" .. entry.levelMin .. "–" .. entry.levelMax .. "]"
    elseif entry.levelMin then
        displayText = displayText .. " [" .. entry.levelMin .. "]"
    end
    return displayText
end

local function EntryMeetsProgressionRequirement(entry)
    local playerLevel = UnitLevel("player") or 0

    if entry.category == "HERBS" then
        local herbalismSkill = GetProfessionSkillByName("Herbalism") or 0
        return (entry.skillRequired or 0) <= herbalismSkill
    elseif entry.category == "MINING" then
        local miningSkill = GetProfessionSkillByName("Mining") or 0
        return (entry.skillRequired or 0) <= miningSkill
    end

    return (entry.levelRecommended or 0) <= playerLevel
end

function EOA:RefreshResultsList()
    local rows = self.ui.resultRows
    local rowHeight = 22
    local listWidth = math.max((self.ui.resultsScrollFrame:GetWidth() or 0) - 4, 1)

    local function EnsureResultRow(index)
        local row = rows[index]
        if row then
            row:SetWidth(listWidth)
            return row
        end

        row = CreateFrame("Button", nil, self.ui.resultsScrollChild)
        row:SetHeight(rowHeight)
        row:SetWidth(listWidth)

        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
        row.background:SetColorTexture(0, 0, 0, 0.25)

        row.highlightTexture = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlightTexture:SetAllPoints()
        row.highlightTexture:SetColorTexture(1, 1, 1, 0.08)

        row.selectedTexture = row:CreateTexture(nil, "ARTWORK")
        row.selectedTexture:SetAllPoints()
        row.selectedTexture:SetColorTexture(1, 0.8, 0, 0.15)
        row.selectedTexture:Hide()

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.text:SetJustifyH("LEFT")

        row:SetScript("OnClick", function(button)
            EOA.selectedEntryID = button.entryID
            EOA:RefreshResultsList()
            EOA:UpdateSelectionUI()
        end)

        rows[index] = row
        return row
    end

    if #self.filteredEntries == 0 then
        local row = EnsureResultRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.ui.resultsScrollChild, "TOPLEFT", 0, 0)
        row:SetPoint("TOPRIGHT", self.ui.resultsScrollChild, "TOPRIGHT", 0, 0)
        row:Show()
        row:Disable()
        row.entryID = nil
        row.text:SetText(self:T("NO_RESULTS"))
        if row.selectedTexture then
            row.selectedTexture:Hide()
        end

        for i = 2, #rows do
            rows[i]:Hide()
        end

        self.ui.resultsScrollChild:SetHeight(rowHeight)
        self.ui.resultsScrollFrame:SetVerticalScroll(0)
        return
    end

    for index, entry in ipairs(self.filteredEntries) do
        local row = EnsureResultRow(index)

        row:Enable()
        row.entryID = entry.id
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.ui.resultsScrollChild, "TOPLEFT", 0, -((index - 1) * rowHeight))
        row:SetPoint("TOPRIGHT", self.ui.resultsScrollChild, "TOPRIGHT", 0, -((index - 1) * rowHeight))
        local meetsRequirement = EntryMeetsProgressionRequirement(entry)
        local displayText = GetEntryDisplayText(entry)
        if not meetsRequirement then
            displayText = displayText .. " (Locked)"
        end

        row.text:SetText(displayText)
        if meetsRequirement then
            row.text:SetTextColor(1, 0.82, 0, 1)
        else
            row.text:SetTextColor(1, 0.2, 0.2, 1)
        end
        if row.selectedTexture then
            if self.selectedEntryID == entry.id then
                row.selectedTexture:Show()
            else
                row.selectedTexture:Hide()
            end
        end
        row:Show()
    end

    for i = #self.filteredEntries + 1, #rows do
        rows[i]:Hide()
    end

    self.ui.resultsScrollChild:SetHeight(math.max(#self.filteredEntries * rowHeight, rowHeight))
end

function EOA:UpdateWorldMapPin(entry)
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer then
        return
    end

    if not self.ui.worldMapPin then
        local pin = WorldMapFrame.ScrollContainer:CreateTexture(nil, "OVERLAY")
        pin:SetTexture("Interface\\WorldMap\\Skull_64")
        pin:SetSize(18, 18)
        pin:Hide()
        self.ui.worldMapPin = pin
    end

    local pin = self.ui.worldMapPin
    if not entry then
        pin:Hide()
        return
    end

    local _, x, y = GetEntryCoords(entry)
    if not x or not y then
        pin:Hide()
        return
    end

    local width = WorldMapFrame.ScrollContainer:GetWidth() or 0
    local height = WorldMapFrame.ScrollContainer:GetHeight() or 0

    pin:ClearAllPoints()
    pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer, "TOPLEFT", x * width, -y * height)

    if WorldMapFrame:IsShown() then
        pin:Show()
    else
        pin:Hide()
    end
end

function EOA:NotifyArrival()
    local text = "You have reached the edge of Azeroth."

    local sent = false
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        local ok1 = pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1.0, 0.82, 0.0, 3.0)
        if ok1 then
            sent = true
        else
            local ok2 = pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text)
            if ok2 then
                sent = true
            end
        end
    end

    if not sent then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r " .. text)
    end

    pcall(function()
        local soundKit = SOUNDKIT and SOUNDKIT.UI_QUEST_COMPLETE or 12889
        PlaySound(soundKit)
    end)
end

function EOA:StopNavigation(silent)
    self.navigationActive = false
    self.activeEntry = nil
    self.smoothDistance = nil

    self.ui.arrowFrame:Hide()
    self.ui.arrowTexture:SetRotation(0)
    self.ui.distanceText:SetText("Distance (approx): --")
    self.ui.timeText:SetText("Estimated Time (rough): --")
    self.ui.travelText:SetText("Travel to: --")

    if not silent then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Navigation stopped.")
    end
end

function EOA:StartNavigation()
    local entry = self:GetSelectedEntry()
    if not entry then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Select a destination first.")
        return
    end

    self.activeEntry = entry
    self.navigationActive = true
    self.smoothDistance = nil
    self.ui.arrowFrame:Show()
    self:UpdateWorldMapPin(entry)

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Navigation started: " .. (entry.name or "Unknown"))
end

function EOA:GetEstimatedTravelSeconds(distanceYards)
    if not distanceYards then
        return nil
    end

    local speed = (IsMounted and IsMounted()) and 14 or 7
    return distanceYards / speed
end

local function FormatTime(seconds)
    if not seconds or seconds < 0 then
        return "0m 0s"
    end

    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%dm %ds", mins, secs)
end

function EOA:OnUpdate(elapsed)
    if self.explorerModeEnabled then
        self.explorerUpdateAccumulator = self.explorerUpdateAccumulator + elapsed
        if self.explorerUpdateAccumulator >= 0.2 then
            self.explorerUpdateAccumulator = 0
            self:UpdateExplorerOverlay()
        end
    end

    self.updateAccumulator = self.updateAccumulator + elapsed
    if self.updateAccumulator < self.updateRate then
        return
    end
    self.updateAccumulator = 0

    if self.ui.worldMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
        self.ui.worldMapPin:Show()
    elseif self.ui.worldMapPin then
        self.ui.worldMapPin:Hide()
    end

    if not self.navigationActive or not self.activeEntry then
        return
    end

    local playerMapID, playerX, playerY = self:GetPlayerMapPosition()
    if not playerMapID then
        self.ui.travelText:SetText("Travel to: " .. GetMapName((GetEntryCoords(self.activeEntry))))
        return
    end

    local targetMapID, tx, ty = GetEntryCoords(self.activeEntry)
    if playerMapID ~= targetMapID then
        self.ui.travelText:SetText("Travel to: " .. GetMapName(targetMapID))
        self.ui.distanceText:SetText("Distance (approx): --")
        self.ui.timeText:SetText("Estimated Time (rough): --")
        return
    end

    local dx = tx - playerX
    local dy = ty - playerY
    local units = math.sqrt((dx * dx) + (dy * dy))
    local currentDistance = units * self.defaultYardsPerUnit

    if not self.smoothDistance then
        self.smoothDistance = currentDistance
    else
        self.smoothDistance = self.smoothDistance + (currentDistance - self.smoothDistance) * 0.25
    end

    local facing = GetPlayerFacing() or 0
    local targetBearing = math.atan2(dx, -dy)
    local relativeRotation = targetBearing - facing
    self.ui.arrowTexture:SetRotation(relativeRotation)

    self.ui.distanceText:SetText(string.format("Distance (approx): %d yards", math.max(0, math.floor(self.smoothDistance))))
    local eta = self:GetEstimatedTravelSeconds(self.smoothDistance)
    self.ui.timeText:SetText("Estimated Time (rough): " .. FormatTime(eta))
    self.ui.travelText:SetText("Travel to: " .. GetMapName(targetMapID))

    if currentDistance < 10 then
        self:StopNavigation(true)
        self:NotifyArrival()
    end
end

function EOA:CalibrateSelectedToPlayerPosition()
    local entry = self:GetSelectedEntry()
    if not entry then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r No selected entry to calibrate.")
        return
    end

    local mapID, x, y = self:GetPlayerMapPosition()
    if not mapID then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Unable to read your current map position.")
        return
    end

    EdgeOfAzerothDB.calibrated[entry.id] = {
        mapID = mapID,
        x = x,
        y = y,
    }

    self:UpdateWorldMapPin(entry)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Calibrated: " .. (entry.name or "Unknown"))
end

function EOA:SaveCustomSpotFromPlayerPosition()
    local mapID, x, y = self:GetPlayerMapPosition()
    if not mapID then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Unable to save custom spot at this location.")
        return
    end

    local count = #EdgeOfAzerothDB.customSpots + 1
    local id = "custom_" .. time() .. "_" .. count

    local customEntry = {
        id = id,
        name = "Custom Spot " .. count,
        mapID = mapID,
        x = x,
        y = y,
        type = "SCENIC",
        zoneGroup = "Custom",
        tags = { "custom", "player" },
        description = "Player-saved location for personal routing and atlas notes. This point uses your exact map position at save time. You can recalibrate it anytime from the main window. Useful for gathering loops, landmarks, or group meeting points.",
    }

    table.insert(EdgeOfAzerothDB.customSpots, customEntry)
    self:RefreshFilteredEntries()

    self.selectedEntryID = id
    self:RefreshResultsList()
    self:UpdateSelectionUI()

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Saved custom spot: " .. customEntry.name)
end


function EOA:CreateExplorerOverlay()
    if self.ui and self.ui.explorerOverlay then
        return
    end

    local overlay = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    overlay:SetSize(250, 140)
    overlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
    overlay:SetMovable(true)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)
    overlay:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
    end)
    overlay:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    overlay:SetBackdropColor(0, 0, 0, 0.8)
    overlay:SetFrameStrata("HIGH")
    overlay:Hide()

    local title = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", overlay, "TOPLEFT", 10, -10)
    title:SetText("Explorer Mode")

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    text:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -10, 10)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("")

    self.ui.explorerOverlay = overlay
    self.ui.explorerOverlayText = text
end

function EOA:UpdateExplorerOverlay()
    if not self.explorerModeEnabled or not self.ui or not self.ui.explorerOverlayText then
        return
    end

    local snapshot = GetPlayerTargetSnapshot()
    local xText = snapshot.x and string.format("%.3f", snapshot.x) or "---"
    local yText = snapshot.y and string.format("%.3f", snapshot.y) or "---"
    local targetLevel = snapshot.targetLevel and snapshot.targetLevel >= 0 and tostring(snapshot.targetLevel) or "?"
    local mining = snapshot.miningLevel and tostring(snapshot.miningLevel) or "-"
    local herbs = snapshot.herbalismLevel and tostring(snapshot.herbalismLevel) or "-"

    self.ui.explorerOverlayText:SetText(
        "Zone: " .. (snapshot.zoneName or "Unknown") .. "\n" ..
        "MapID: " .. (snapshot.mapID or "N/A") .. "\n" ..
        "X/Y: " .. xText .. " / " .. yText .. "\n" ..
        "Player Level: " .. (snapshot.playerLevel or 0) .. "\n" ..
        "Target: " .. (snapshot.targetName or "-") .. "\n" ..
        "Target Level: " .. targetLevel .. "\n" ..
        "Mining: " .. mining .. "  Herbalism: " .. herbs
    )
end

function EOA:SetExplorerMode(enabled)
    self.explorerModeEnabled = enabled and true or false
    self.explorerUpdateAccumulator = 0

    if self.ui and self.ui.explorerToggleButton then
        if self.explorerModeEnabled then
            self.ui.explorerToggleButton:SetText(self:T("EXPLORER_MODE") .. ": " .. self:T("ON"))
        else
            self.ui.explorerToggleButton:SetText(self:T("EXPLORER_MODE") .. ": " .. self:T("OFF"))
        end
    end

    if self.ui and self.ui.explorerOverlay then
        if self.explorerModeEnabled then
            self.ui.explorerOverlay:Show()
            self:UpdateExplorerOverlay()
        else
            self.ui.explorerOverlay:Hide()
        end
    end
end

function EOA:ToggleExplorerMode()
    self:SetExplorerMode(not self.explorerModeEnabled)
end

function EOA:CreateRecordPopup()
    if self.ui and self.ui.recordPopup then
        return
    end

    local popup = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    popup:SetSize(430, 500)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    popup:SetFrameStrata("DIALOG")
    popup:Hide()

    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    popup.title:SetPoint("TOP", popup, "TOP", 0, -6)
    popup.title:SetText("Field Research Record")

    local y = -34
    local left = 18

    local function CreateLabel(text)
        local label = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", popup, "TOPLEFT", left, y)
        label:SetText(text)
        y = y - 20
        return label
    end

    local function CreateEditBox(width, height, multiline)
        local box = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        box:SetSize(width, height or 20)
        box:SetPoint("TOPLEFT", popup, "TOPLEFT", left, y)
        box:SetAutoFocus(false)
        if multiline then
            box:SetMultiLine(true)
            box:SetFontObject(ChatFontNormal)
        end
        y = y - ((height or 20) + 10)
        return box
    end

    CreateLabel("Category")
    local categoryDropdown = CreateFrame("Frame", "EdgeOfAzerothRecordCategoryDropdown", popup, "UIDropDownMenuTemplate")
    categoryDropdown:SetPoint("TOPLEFT", popup, "TOPLEFT", left - 16, y + 8)
    UIDropDownMenu_SetWidth(categoryDropdown, 160)
    y = y - 36

    CreateLabel("Name")
    local nameBox = CreateEditBox(380, 20, false)

    CreateLabel("Level Recommended")
    local levelRecommendedBox = CreateEditBox(80, 20, false)

    CreateLabel("Mob Level Min")
    local mobMinBox = CreateEditBox(80, 20, false)

    CreateLabel("Mob Level Max")
    local mobMaxBox = CreateEditBox(80, 20, false)

    CreateLabel("Skill Required")
    local skillRequiredBox = CreateEditBox(80, 20, false)

    CreateLabel("Resource")
    local resourceBox = CreateEditBox(180, 20, false)

    CreateLabel("Density")
    local densityDropdown = CreateFrame("Frame", "EdgeOfAzerothRecordDensityDropdown", popup, "UIDropDownMenuTemplate")
    densityDropdown:SetPoint("TOPLEFT", popup, "TOPLEFT", left - 16, y + 8)
    UIDropDownMenu_SetWidth(densityDropdown, 80)
    y = y - 36

    CreateLabel("Danger")
    local dangerDropdown = CreateFrame("Frame", "EdgeOfAzerothRecordDangerDropdown", popup, "UIDropDownMenuTemplate")
    dangerDropdown:SetPoint("TOPLEFT", popup, "TOPLEFT", left - 16, y + 8)
    UIDropDownMenu_SetWidth(dangerDropdown, 80)
    y = y - 36

    CreateLabel("Notes")
    local notesBg = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    notesBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    notesBg:SetBackdropColor(0, 0, 0, 0.45)
    notesBg:SetSize(385, 80)
    notesBg:SetPoint("TOPLEFT", popup, "TOPLEFT", left - 2, y + 2)

    local notesBox = CreateFrame("EditBox", nil, notesBg)
    notesBox:SetSize(370, 68)
    notesBox:SetPoint("TOPLEFT", notesBg, "TOPLEFT", 6, -6)
    notesBox:SetMultiLine(true)
    notesBox:SetAutoFocus(false)
    notesBox:SetFontObject(ChatFontNormal)
    y = y - 94

    local errorText = popup:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    errorText:SetPoint("TOPLEFT", popup, "TOPLEFT", left, y)
    errorText:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -18, y)
    errorText:SetJustifyH("LEFT")
    errorText:SetText("")

    local saveButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 24)
    saveButton:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", left, 14)
    saveButton:SetText("Save")

    local cancelButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancelButton:SetSize(120, 24)
    cancelButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        popup:Hide()
    end)

    self.ui.recordPopup = popup
    self.ui.recordCategoryDropdown = categoryDropdown
    self.ui.recordNameBox = nameBox
    self.ui.recordLevelRecommendedBox = levelRecommendedBox
    self.ui.recordMobMinBox = mobMinBox
    self.ui.recordMobMaxBox = mobMaxBox
    self.ui.recordSkillRequiredBox = skillRequiredBox
    self.ui.recordResourceBox = resourceBox
    self.ui.recordDensityDropdown = densityDropdown
    self.ui.recordDangerDropdown = dangerDropdown
    self.ui.recordNotesBox = notesBox
    self.ui.recordErrorText = errorText
    self.ui.recordSaveButton = saveButton

    UIDropDownMenu_Initialize(categoryDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for _, category in ipairs(FIELD_RESEARCH_CATEGORIES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = category.text
            info.checked = (popup.selectedCategory == category.value)
            info.func = function()
                popup.selectedCategory = category.value
                UIDropDownMenu_SetText(categoryDropdown, category.text)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local function InitNumberDropdown(dropdown, valueField)
        UIDropDownMenu_Initialize(dropdown, function(_, level)
            if level ~= 1 then
                return
            end

            for _, option in ipairs(DENSITY_OPTIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option.text
                info.checked = (popup[valueField] == option.value)
                info.func = function()
                    popup[valueField] = option.value
                    UIDropDownMenu_SetText(dropdown, option.text)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end

    InitNumberDropdown(densityDropdown, "selectedDensity")
    InitNumberDropdown(dangerDropdown, "selectedDanger")

    saveButton:SetScript("OnClick", function()
        EOA:SaveRecordPopupEntry()
    end)
end

function EOA:OpenRecordPopup(preselectedCategory)
    self:CreateRecordPopup()

    local popup = self.ui.recordPopup
    local snapshot = GetPlayerTargetSnapshot()

    popup.snapshot = snapshot
    popup.selectedCategory = preselectedCategory
    popup.selectedDensity = nil
    popup.selectedDanger = nil

    self.ui.recordErrorText:SetText("")
    self.ui.recordNameBox:SetText(snapshot.targetName or snapshot.zoneName or "")
    self.ui.recordLevelRecommendedBox:SetText(snapshot.playerLevel or "")
    self.ui.recordMobMinBox:SetText(snapshot.targetLevel and snapshot.targetLevel > 0 and snapshot.targetLevel or "")
    self.ui.recordMobMaxBox:SetText(snapshot.targetLevel and snapshot.targetLevel > 0 and snapshot.targetLevel or "")
    self.ui.recordSkillRequiredBox:SetText("")
    self.ui.recordResourceBox:SetText("")
    self.ui.recordNotesBox:SetText("")

    if preselectedCategory then
        UIDropDownMenu_SetText(self.ui.recordCategoryDropdown, preselectedCategory)
    else
        UIDropDownMenu_SetText(self.ui.recordCategoryDropdown, "Select")
    end
    UIDropDownMenu_SetText(self.ui.recordDensityDropdown, "Select")
    UIDropDownMenu_SetText(self.ui.recordDangerDropdown, "Select")

    popup:Show()
end

function EOA:ValidateRecordNumericField(rawValue, label)
    if rawValue == nil or rawValue == "" then
        return nil
    end

    local numberValue = tonumber(rawValue)
    if not numberValue then
        return nil, label .. " must be a number."
    end

    return numberValue
end

function EOA:SaveRecordPopupEntry()
    local popup = self.ui and self.ui.recordPopup
    if not popup or not popup.snapshot then
        return
    end

    local snapshot = popup.snapshot
    if not snapshot.mapID or not snapshot.x or not snapshot.y then
        self.ui.recordErrorText:SetText("Invalid position data (mapID/x/y missing).")
        return
    end

    local category = popup.selectedCategory
    if not category or category == "" then
        self.ui.recordErrorText:SetText("Category is required.")
        return
    end

    local levelRecommended, levelErr = self:ValidateRecordNumericField(self.ui.recordLevelRecommendedBox:GetText(), "Level Recommended")
    if levelErr then
        self.ui.recordErrorText:SetText(levelErr)
        return
    end

    local mobLevelMin, minErr = self:ValidateRecordNumericField(self.ui.recordMobMinBox:GetText(), "Mob Level Min")
    if minErr then
        self.ui.recordErrorText:SetText(minErr)
        return
    end

    local mobLevelMax, maxErr = self:ValidateRecordNumericField(self.ui.recordMobMaxBox:GetText(), "Mob Level Max")
    if maxErr then
        self.ui.recordErrorText:SetText(maxErr)
        return
    end

    local skillRequired, skillErr = self:ValidateRecordNumericField(self.ui.recordSkillRequiredBox:GetText(), "Skill Required")
    if skillErr then
        self.ui.recordErrorText:SetText(skillErr)
        return
    end

    local timestamp = time()
    local id = "custom_" .. timestamp
    local name = self.ui.recordNameBox:GetText()
    if not name or name == "" then
        name = snapshot.targetName or snapshot.zoneName or "Custom Spot"
    end

    local description = self.ui.recordNotesBox:GetText() or ""
    local resource = self.ui.recordResourceBox:GetText() or ""

    local customEntry = {
        id = id,
        name = name,
        mapID = snapshot.mapID,
        x = snapshot.x,
        y = snapshot.y,
        type = category,
        zoneGroup = "Custom",
        tags = { "custom", "field-research" },
        description = description,
        levelRecommended = levelRecommended,
        mobLevelMin = mobLevelMin,
        mobLevelMax = mobLevelMax,
        skillRequired = skillRequired,
        resource = resource,
        density = popup.selectedDensity,
        danger = popup.selectedDanger,
        targetName = snapshot.targetName,
        targetLevel = snapshot.targetLevel,
        zoneName = snapshot.zoneName,
        playerLevel = snapshot.playerLevel,
    }

    table.insert(EdgeOfAzerothDB.customSpots, customEntry)
    self:RefreshFilteredEntries()

    self.selectedEntryID = id
    self:RefreshResultsList()
    self:UpdateSelectionUI()

    self.ui.recordErrorText:SetText("")
    popup:Hide()

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Field Research saved: " .. (name or "Custom Spot"))
end

function EOA:QuickRecordSpot(entryType)
    local snapshot = GetPlayerTargetSnapshot()
    if not snapshot.mapID or not snapshot.x or not snapshot.y then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Unable to record spot at this location.")
        return
    end

    local timestamp = time()
    local id = "custom_" .. timestamp
    local name = snapshot.targetName or snapshot.zoneName or "Custom Spot"

    local customEntry = {
        id = id,
        name = name,
        mapID = snapshot.mapID,
        x = snapshot.x,
        y = snapshot.y,
        type = entryType,
        zoneGroup = "Custom",
        tags = { "custom", "quick-record" },
        description = "Quick field research entry.",
        levelRecommended = snapshot.playerLevel,
        targetName = snapshot.targetName,
        targetLevel = snapshot.targetLevel,
    }

    table.insert(EdgeOfAzerothDB.customSpots, customEntry)
    self:RefreshFilteredEntries()

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Quick record saved: " .. name .. " [" .. entryType .. "]")
end
function EOA:ToggleFavoriteForSelected()
    local entry = self:GetSelectedEntry()
    if not entry then
        return
    end

    local current = EdgeOfAzerothDB.favorites[entry.id]
    EdgeOfAzerothDB.favorites[entry.id] = not current
    self:UpdateSelectionUI()

    if self.currentMode == "FAVORITES" then
        self:RefreshFilteredEntries()
    end
end

function EOA:CreateUI()
    if self.ui then
        return
    end

    local frame = CreateFrame("Frame", "EdgeOfAzerothFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 420)
    frame:SetPoint("CENTER")
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:ClearAllPoints()
    frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
    frame.title:SetText("Edge Of Azeroth  |cff888888by Dennis Hilk|r")

    frame.CloseButton:ClearAllPoints()
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)

    local bottomPadding = 22
    local leftPadding = 40
    local spacing = 10
    local buttonWidth = 160
    local buttonHeight = 24

    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
    modeLabel:SetText(self:T("MODE"))

    local modeDropdown = CreateFrame("Frame", "EdgeOfAzerothModeDropdown", frame, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(modeDropdown, 150)

    local farmCategoryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    farmCategoryLabel:SetPoint("TOPLEFT", modeDropdown, "BOTTOMLEFT", 16, -8)
    farmCategoryLabel:SetText("Farming Type")

    local farmCategoryDropdown = CreateFrame("Frame", "EdgeOfAzerothFarmCategoryDropdown", frame, "UIDropDownMenuTemplate")
    farmCategoryDropdown:SetPoint("TOPLEFT", farmCategoryLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(farmCategoryDropdown, 150)

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 196, -36)
    searchLabel:SetText(self:T("SEARCH"))

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(135, 24)
    searchBox:ClearAllPoints()
    searchBox:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -4)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEscapePressed", searchBox.ClearFocus)
    searchBox:SetMaxLetters(40)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetWidth(120)
    placeholder:SetWordWrap(false)
    placeholder:SetText("Search (e.g. runecloth, BRD, Desolace)")

    searchBox:SetScript("OnTextChanged", function(selfBox)
        if selfBox:GetText() == "" then
            placeholder:Show()
        else
            placeholder:Hide()
        end
        EOA:RefreshFilteredEntries()
    end)

    searchBox:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
    end)

    searchBox:SetScript("OnEditFocusLost", function(selfBox)
        if selfBox:GetText() == "" then
            placeholder:Show()
        end
    end)

    local resultsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resultsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -96)
    resultsLabel:SetText(self:T("RESULTS"))

    local resultsScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    resultsScrollFrame:SetPoint("TOPLEFT", resultsLabel, "BOTTOMLEFT", 0, -6)
    resultsScrollFrame:SetSize(510, 88)
    resultsScrollFrame:EnableMouseWheel(true)

    local resultsScrollChild = CreateFrame("Frame", nil, resultsScrollFrame)
    resultsScrollChild:SetSize(510, 88)
    resultsScrollFrame:SetScrollChild(resultsScrollChild)

    resultsScrollFrame:SetScript("OnMouseWheel", function(selfFrame, delta)
        local current = selfFrame:GetVerticalScroll()
        local step = 22
        local maxScroll = math.max(0, (resultsScrollChild:GetHeight() or 0) - selfFrame:GetHeight())
        local newValue = math.max(0, math.min(maxScroll, current - (delta * step)))
        selfFrame:SetVerticalScroll(newValue)
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "EdgeOfAzerothDescriptionScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", resultsScrollFrame, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 100)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 180)
    scrollFrame:SetScrollChild(scrollChild)

    local descriptionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetJustifyV("TOP")
    descriptionText:SetWidth(490)
    descriptionText:SetText(self:T("SELECT_A_DESTINATION"))

    local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    startButton:SetSize(buttonWidth, buttonHeight)
    startButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", leftPadding, bottomPadding + buttonHeight + spacing)
    startButton:SetText(self:T("START_NAV"))
    startButton:SetScript("OnClick", function()
        EOA:StartNavigation()
    end)

    local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    stopButton:SetSize(buttonWidth, buttonHeight)
    stopButton:SetPoint("LEFT", startButton, "RIGHT", spacing, 0)
    stopButton:SetText(self:T("STOP_NAV"))
    stopButton:SetScript("OnClick", function()
        EOA:StopNavigation(false)
    end)

    local calibrateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    calibrateButton:SetSize(buttonWidth, buttonHeight)
    calibrateButton:SetPoint("LEFT", stopButton, "RIGHT", spacing, 0)
    calibrateButton:SetText(self:T("SET_TARGET_TO_MY_POSITION"))
    calibrateButton:SetScript("OnClick", function()
        EOA:CalibrateSelectedToPlayerPosition()
    end)

    local saveCustomButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveCustomButton:ClearAllPoints()
    saveCustomButton:SetPoint("TOPLEFT", startButton, "BOTTOMLEFT", 6, -8)
    saveCustomButton:SetSize(200, 24)
    saveCustomButton:SetText(self:T("SAVE_CUSTOM_SPOT"))
    saveCustomButton:SetScript("OnClick", function()
        EOA:SaveCustomSpotFromPlayerPosition()
    end)

    local favoriteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    favoriteButton:ClearAllPoints()
    favoriteButton:SetPoint("LEFT", saveCustomButton, "RIGHT", 10, 0)
    favoriteButton:SetSize(140, 24)
    favoriteButton.fitTextWidthPadding = 40
    favoriteButton:SetText(self:T("FAVORITE"))
    favoriteButton:SetScript("OnClick", function()
        EOA:ToggleFavoriteForSelected()
    end)

    local arrowFrame = CreateFrame("Frame", "EdgeOfAzerothArrowFrame", UIParent)
    arrowFrame:SetSize(120, 120)
    arrowFrame:SetPoint("TOP", UIParent, "TOP", 0, -40)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:Hide()

    local arrowTexture = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrowTexture:SetAllPoints()
    arrowTexture:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrowTexture:SetVertexColor(1, 0.8, 0.2, 1)
    arrowTexture:SetAlpha(1)

    local distanceText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    distanceText:SetPoint("TOP", arrowFrame, "BOTTOM", 0, -2)
    distanceText:SetText("Distance (approx): --")

    local timeText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeText:SetPoint("TOP", distanceText, "BOTTOM", 0, -2)
    timeText:SetText("Estimated Time (rough): --")

    local travelText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    travelText:SetPoint("TOP", timeText, "BOTTOM", 0, -2)
    travelText:SetText("Travel to: --")

    frame:SetScript("OnHide", function()
        searchBox:ClearFocus()
    end)

    self.ui = {
        frame = frame,
        modeDropdown = modeDropdown,
        farmCategoryLabel = farmCategoryLabel,
        farmCategoryDropdown = farmCategoryDropdown,
        resultsLabel = resultsLabel,
        searchBox = searchBox,
        resultsScrollFrame = resultsScrollFrame,
        resultsScrollChild = resultsScrollChild,
        resultRows = {},
        descriptionScrollFrame = scrollFrame,
        descriptionScrollChild = scrollChild,
        descriptionText = descriptionText,
        favoriteButton = favoriteButton,
        arrowFrame = arrowFrame,
        arrowTexture = arrowTexture,
        distanceText = distanceText,
        timeText = timeText,
        travelText = travelText,
    }

    self:CreateExplorerOverlay()
    self:CreateRecordPopup()
end

function EOA:ToggleMainFrame()
    if not self.ui or not self.ui.frame then
        return
    end

    if self.ui.frame:IsShown() then
        self.ui.frame:Hide()
    else
        self.ui.frame:Show()
    end
end

function EOA:OpenAdminTools()
    self:CreateExplorerOverlay()
    self:SetExplorerMode(true)

    if self.ui and self.ui.recordPopup then
        self:OpenRecordPopup()
    end
end

function EOA:Initialize()
    if self.initialized then
        return
    end
    self.initialized = true

    EnsureDB()
    self:CreateUI()

    if not self.ui or not self.ui.frame then
        print("EdgeOfAzeroth: UI failed to initialize.")
        return
    end

    self:RefreshModeDropdown()
    self:RefreshFarmCategoryDropdown()
    self:UpdateFarmCategoryVisibility()
    self:RefreshFilteredEntries()

    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function(_, elapsed)
        EOA:OnUpdate(elapsed)
    end)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
    eventFrame:SetScript("OnEvent", function()
        EOA:UpdateWorldMapPin(EOA:GetSelectedEntry())
    end)
end

SLASH_EDGEOFAZEROTH1 = "/eoa"
SlashCmdList["EDGEOFAZEROTH"] = function(msg)
    if not EdgeOfAzeroth then
        return
    end

    local command = msg and string.lower((msg:gsub("^%s+", ""):gsub("%s+$", ""))) or ""

    if command == "admin" then
        EdgeOfAzeroth:OpenAdminTools()
        return
    end

    EdgeOfAzeroth:ToggleMainFrame()
end

if EdgeOfAzeroth and EdgeOfAzeroth.Initialize then
    EdgeOfAzeroth:Initialize()
end
