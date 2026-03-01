local addonName = ...

local EdgeOfAzeroth = {
    navigationActive = false,
    selectedDestinationIndex = nil,
    activeDestination = nil,
    updateInterval = 0.10,
    elapsedSinceUpdate = 0,
    defaultYardsPerMapUnit = 10000,
    mapYardsPerUnit = {
        [1415] = 10300, -- Eastern Plaguelands
        [1422] = 10300, -- Western Plaguelands
        [1452] = 11150, -- Winterspring
        [1447] = 10400, -- Azshara
        [1451] = 10050, -- Silithus
        [1430] = 8900,  -- Deadwind Pass
        [1446] = 11600, -- Tanaris
        [1425] = 10900, -- The Hinterlands
        [1442] = 9300,  -- Stonetalon Mountains
        [1426] = 8500,  -- Dun Morogh
        [1438] = 7800,  -- Teldrassil
        [1448] = 10200, -- Felwood
        [1443] = 11200, -- Desolace
        [1419] = 9700,  -- Blasted Lands
        [1435] = 9800,  -- Swamp of Sorrows
    },
    ui = {},
}

local Destinations = {
    { name = "Quel'Lithien Northern Wall", mapID = 1415, x = 0.862, y = 0.182, description = "Collapsed elven stonework overlooking the cold northern frontier." },
    { name = "Tyr's Hand Outer Orchards", mapID = 1415, x = 0.774, y = 0.747, description = "Abandoned fields where faded banners still move in the wind." },
    { name = "Marris Stead Backroad", mapID = 1415, x = 0.309, y = 0.795, description = "A forgotten cart route swallowed by weeds and plague-scarred mud." },

    { name = "Caer Darrow Shoreline", mapID = 1422, x = 0.686, y = 0.777, description = "A silent lakeside edge beneath the shadow of old scholomantic stone." },
    { name = "Sorrow Hill Grave Margin", mapID = 1422, x = 0.467, y = 0.503, description = "Uneven graves and dead trees mark a haunting western boundary." },

    { name = "Frostwhisper Gorge", mapID = 1452, x = 0.607, y = 0.204, description = "A narrow frozen cleft where the wind drowns out every sound." },
    { name = "Mazthoril Ice Shelf", mapID = 1452, x = 0.502, y = 0.416, description = "Blue ice cliffs and ancient carvings hidden above deep snow." },

    { name = "Bay of Storms Cliffline", mapID = 1447, x = 0.706, y = 0.184, description = "Jagged cliffs over dark waters far from Azeroth's busy ports." },
    { name = "Hetaera's Clutch Back Ridge", mapID = 1447, x = 0.167, y = 0.722, description = "A secluded ridge where dragons circle above abandoned ruins." },

    { name = "Southwind Break Dunes", mapID = 1451, x = 0.427, y = 0.846, description = "Scoured dunes and buried stone paths at the edge of the hives." },
    { name = "Twilight Base Camp Ruins", mapID = 1451, x = 0.289, y = 0.366, description = "Tattered camps and ritual remains scattered across dry rock." },

    { name = "Karazhan Service Gate", mapID = 1430, x = 0.406, y = 0.777, description = "A hidden approach to the tower where few travelers ever stop." },
    { name = "Dreadmaul Ravine Overlook", mapID = 1430, x = 0.636, y = 0.711, description = "A high overlook above broken roads and old ogre territory." },

    { name = "Abyssal Sands Edge", mapID = 1446, x = 0.565, y = 0.821, description = "A lonely desert margin where sandstorms erase every footprint." },
    { name = "Steamwheedle Back Docks", mapID = 1446, x = 0.684, y = 0.286, description = "Remote goblin piers facing endless sea and rusted machinery." },

    { name = "Seradane Treeline", mapID = 1425, x = 0.624, y = 0.246, description = "Ancient boughs and misted trails near the quiet northern woods." },
    { name = "Overlook Cliffs", mapID = 1425, x = 0.722, y = 0.635, description = "Steep cliffs above distant valleys and isolated gryphon winds." },

    { name = "Windshear Crag West Face", mapID = 1442, x = 0.597, y = 0.545, description = "Sheer rock walls and scattered lumber camps far from main roads." },

    { name = "Helm's Bed Lake Shelf", mapID = 1426, x = 0.827, y = 0.507, description = "A quiet lakeside shelf tucked beneath snowy granite peaks." },

    { name = "Rut'theran Outer Roots", mapID = 1438, x = 0.566, y = 0.935, description = "Massive roots descending into mist where ships rarely linger." },

    { name = "Irontree Northern Ridge", mapID = 1448, x = 0.573, y = 0.163, description = "Charred forest ridges overlooking the corrupted northern canopy." },

    { name = "Mannoroc Upper Shelf", mapID = 1443, x = 0.548, y = 0.756, description = "A cracked plateau above demonic scars and shattered stone." },

    { name = "Dreadmaul Post Outer Wastes", mapID = 1419, x = 0.511, y = 0.843, description = "Parched red earth fading into distant blackened hills." },

    { name = "Misty Reed Far Bank", mapID = 1435, x = 0.787, y = 0.345, description = "Still marsh water and thick reeds beyond the usual patrol paths." },
}

local function ChatMessage(message)
    if DEFAULT_CHAT_FRAME and message then
        DEFAULT_CHAT_FRAME:AddMessage("Edge Of Azeroth: " .. message)
    end
end

local function FormatTime(seconds)
    if type(seconds) ~= "number" or seconds < 0 then
        return "0m 0s"
    end

    local minutes = math.floor(seconds / 60)
    local remainder = math.floor(seconds % 60)
    return string.format("%dm %ds", minutes, remainder)
end

local function GetPlayerMapPosition()
    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not playerMapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not position or not position.x or not position.y then
        return nil
    end

    return playerMapID, position.x, position.y
end

function EdgeOfAzeroth:GetMapYardsPerUnit(mapID)
    if not mapID then
        return self.defaultYardsPerMapUnit
    end

    return self.mapYardsPerUnit[mapID] or self.defaultYardsPerMapUnit
end

function EdgeOfAzeroth:CalculateDistanceYards(mapID, fromX, fromY, toX, toY)
    if type(fromX) ~= "number" or type(fromY) ~= "number" or type(toX) ~= "number" or type(toY) ~= "number" then
        return nil
    end

    local dx = toX - fromX
    local dy = toY - fromY
    local distanceUnits = math.sqrt((dx * dx) + (dy * dy))
    return distanceUnits * self:GetMapYardsPerUnit(mapID)
end

function EdgeOfAzeroth:StopNavigation(silent)
    self.navigationActive = false
    self.activeDestination = nil

    if self.ui and self.ui.arrowFrame then
        self.ui.arrowFrame:Hide()
    end

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText("Distance (approx): --")
    end

    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time (rough): --")
    end

    if not silent then
        ChatMessage("Navigation stopped.")
    end
end

function EdgeOfAzeroth:StartNavigation()
    if not self.selectedDestinationIndex or not Destinations[self.selectedDestinationIndex] then
        ChatMessage("Please select a destination first.")
        return
    end

    self.activeDestination = Destinations[self.selectedDestinationIndex]
    self.navigationActive = true

    if self.ui and self.ui.arrowFrame then
        self.ui.arrowFrame:Show()
    end

    ChatMessage("Navigation started to " .. self.activeDestination.name .. ".")
end

function EdgeOfAzeroth:GetTravelTimeSeconds(distanceYards)
    if type(distanceYards) ~= "number" or distanceYards < 0 then
        return nil
    end

    local speedYardsPerSecond = IsMounted and IsMounted() and 14 or 7
    return distanceYards / speedYardsPerSecond
end

function EdgeOfAzeroth:UpdateArrowRotation(playerX, playerY, destination)
    if not self.ui or not self.ui.arrowTexture then
        return
    end

    if type(playerX) ~= "number" or type(playerY) ~= "number" then
        return
    end

    if type(destination) ~= "table" or type(destination.x) ~= "number" or type(destination.y) ~= "number" then
        return
    end

    local playerFacing = GetPlayerFacing and GetPlayerFacing()
    if type(playerFacing) ~= "number" then
        return
    end

    local dx = destination.x - playerX
    local dy = destination.y - playerY

    if dx == 0 and dy == 0 then
        return
    end

    -- Map coordinates use Y-positive downward; invert Y to produce north-positive math.
    local targetBearing = math.atan2(dx, -dy)
    local relativeRotation = targetBearing - playerFacing

    self.ui.arrowTexture:SetRotation(relativeRotation)
end

function EdgeOfAzeroth:UpdateZoneStatus(destination)
    if not destination or type(destination.mapID) ~= "number" then
        return
    end

    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(destination.mapID)
    local zoneName = mapInfo and mapInfo.name or "Unknown Zone"

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText("Travel to: " .. zoneName)
    end

    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time (rough): --")
    end
end

function EdgeOfAzeroth:UpdateNavigation(elapsed)
    if type(elapsed) ~= "number" then
        return
    end

    self.elapsedSinceUpdate = self.elapsedSinceUpdate + elapsed
    if self.elapsedSinceUpdate < self.updateInterval then
        return
    end
    self.elapsedSinceUpdate = 0

    if not self.navigationActive or not self.activeDestination then
        return
    end

    local playerMapID, playerX, playerY = GetPlayerMapPosition()
    if not playerMapID or not playerX or not playerY then
        return
    end

    local destination = self.activeDestination
    if playerMapID ~= destination.mapID then
        self:UpdateZoneStatus(destination)
        return
    end

    local distanceYards = self:CalculateDistanceYards(playerMapID, playerX, playerY, destination.x, destination.y)
    if not distanceYards then
        return
    end

    if distanceYards < 10 then
        self:StopNavigation(true)
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("You have reached the edge of Azeroth.")
        end
        return
    end

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText(string.format("Distance (approx): %d yards", math.floor(distanceYards + 0.5)))
    end

    local travelSeconds = self:GetTravelTimeSeconds(distanceYards)
    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time (rough): " .. FormatTime(travelSeconds or 0))
    end

    self:UpdateArrowRotation(playerX, playerY, destination)
end

function EdgeOfAzeroth:CreateArrowFrame()
    local frame = CreateFrame("Frame", addonName .. "ArrowFrame", UIParent)
    frame:SetSize(96, 96)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -70)
    frame:Hide()

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAP-ARROW")

    local distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    distanceText:SetPoint("TOP", frame, "BOTTOM", 0, -6)
    distanceText:SetText("Distance (approx): --")

    local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOP", distanceText, "BOTTOM", 0, -4)
    timeText:SetText("Estimated Time (rough): --")

    self.ui.arrowFrame = frame
    self.ui.arrowTexture = texture
    self.ui.distanceText = distanceText
    self.ui.timeText = timeText
end

function EdgeOfAzeroth:CreateMainWindow()
    local frame = CreateFrame("Frame", addonName .. "MainFrame", UIParent, "UIPanelDialogTemplate")
    frame:SetSize(470, 340)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText("Edge Of Azeroth")

    local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -42)
    dropdownLabel:SetText("Destination")

    local dropdown = CreateFrame("Frame", addonName .. "DestinationDropdown", frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -16, -6)

    local descriptionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descriptionLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 20, -8)
    descriptionLabel:SetText("Description")

    local descriptionScrollFrame = CreateFrame("ScrollFrame", addonName .. "DescriptionScrollFrame", frame, "UIPanelScrollFrameTemplate")
    descriptionScrollFrame:SetPoint("TOPLEFT", descriptionLabel, "BOTTOMLEFT", 0, -6)
    descriptionScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 64)

    local descriptionContent = CreateFrame("Frame", nil, descriptionScrollFrame)
    descriptionContent:SetSize(390, 180)

    local descriptionText = descriptionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", descriptionContent, "TOPLEFT", 0, 0)
    descriptionText:SetPoint("RIGHT", descriptionContent, "RIGHT", 0, 0)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetJustifyV("TOP")
    descriptionText:SetText("Select a destination to begin navigation.")

    descriptionScrollFrame:SetScrollChild(descriptionContent)

    local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    startButton:SetSize(180, 28)
    startButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 20)
    startButton:SetText("Start Navigation")

    local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    stopButton:SetSize(180, 28)
    stopButton:SetPoint("LEFT", startButton, "RIGHT", 12, 0)
    stopButton:SetText("Stop Navigation")

    local function OnDestinationSelected(_, destinationIndex)
        local destination = Destinations[destinationIndex]
        if not destination then
            return
        end

        EdgeOfAzeroth.selectedDestinationIndex = destinationIndex
        UIDropDownMenu_SetText(dropdown, destination.name)
        descriptionText:SetText(destination.description)
    end

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for index, destination in ipairs(Destinations) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = destination.name
            info.func = OnDestinationSelected
            info.arg1 = index
            info.checked = (EdgeOfAzeroth.selectedDestinationIndex == index)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(dropdown, 345)
    UIDropDownMenu_SetText(dropdown, "Choose a destination")
    UIDropDownMenu_SetMaxButtons(18)

    startButton:SetScript("OnClick", function()
        EdgeOfAzeroth:StartNavigation()
    end)

    stopButton:SetScript("OnClick", function()
        EdgeOfAzeroth:StopNavigation(false)
    end)

    self.ui.mainFrame = frame
end

function EdgeOfAzeroth:ToggleMainWindow()
    if not self.ui or not self.ui.mainFrame then
        return
    end

    if self.ui.mainFrame:IsShown() then
        self.ui.mainFrame:Hide()
    else
        self.ui.mainFrame:Show()
    end
end

function EdgeOfAzeroth:Initialize()
    self:CreateMainWindow()
    self:CreateArrowFrame()

    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(_, elapsed)
        EdgeOfAzeroth:UpdateNavigation(elapsed)
    end)

    self.ui.updateFrame = updateFrame

    _G.SLASH_EOA1 = "/eoa"
    SlashCmdList.EOA = function()
        EdgeOfAzeroth:ToggleMainWindow()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        EdgeOfAzeroth:Initialize()
    end
end)
