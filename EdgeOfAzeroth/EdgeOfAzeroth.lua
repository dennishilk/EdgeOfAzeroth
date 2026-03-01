local addonName = ...

local EdgeOfAzeroth = {
    navigationActive = false,
    selectedDestinationIndex = nil,
    activeDestination = nil,
    updateInterval = 0.10,
    elapsedSinceUpdate = 0,
    previousDistanceYards = nil,
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
    { name = "The Tirisfal Clearing", mapID = 1420, x = 0.517, y = 0.559, description = "A quiet clearing in Tirisfal where reports suggest rare phenomena may appear at certain in-game times, though nothing is guaranteed." },
    { name = "The Scarlet Watchtower Rear Grounds", mapID = 1420, x = 0.777, y = 0.558, description = "Behind the old tower, the land falls into a strip of trampled grass and abandoned supply pits no patrol ever really watches. Wind threads between weathered stakes and torn pennants, carrying the faint creak of wood from the structure above. It feels like a place built for urgency and then forgotten in silence. Even in daylight, the rear grounds keep the uneasy stillness of a battlefield after the march has passed." },
    { name = "Hidden Coastline North of Deathknell", mapID = 1420, x = 0.312, y = 0.255, description = "North of Deathknell, the land drops into a lonely coast where gray water beats against black stone in relentless rhythm. Sea mist curls through the trees and blurs the horizon until sky and ocean become one slate-colored wall. Few travelers come this far, leaving only gull cries and the scrape of pebbles beneath your boots. It is a stark edge of Lordaeron where the world feels unfinished and beautifully empty." },

    { name = "Karazhan Back Ridge", mapID = 1430, x = 0.478, y = 0.811, description = "Behind Karazhan, a high ridge rises above the dead grasslands like a balcony facing a haunted kingdom. From here, the tower's silhouette looms at an angle most never see, all broken spires and cold geometry. The wind rushes up the stone face in long, low moans that never seem to end. It is a vantage of awe and dread, where every shadow suggests an old secret watching back." },
    { name = "Southern Unused Ravine", mapID = 1430, x = 0.615, y = 0.853, description = "Far to the south, a cut in the earth forms a ravine that seems bypassed by roads, camps, and history itself. Sparse grass clings to cracked soil while jagged outcrops cast thin, sharp shadows across the floor below. The area holds an abandoned quality, as if caravans once planned to pass through and changed course forever. In the hush between wind gusts, the ravine feels like a forgotten draft of the world." },

    { name = "Frostwhisper Gorge Edge", mapID = 1452, x = 0.593, y = 0.224, description = "At the gorge edge, Winterspring opens into a sudden drop where blue-white ice disappears into a dim, frozen throat. Snow sweeps across the lip in ribbons, occasionally revealing old stone and claw marks beneath. The cold is absolute here, biting through armor and silence alike. Looking down feels like staring into an ancient wound the mountain never healed." },
    { name = "Unused Northern Snow Shelf", mapID = 1452, x = 0.482, y = 0.063, description = "Near the northern limit, a broad snow shelf stretches toward nowhere, untouched by beasts or banners. The horizon is a pale blur, and drifting powder erases your tracks almost as quickly as they appear. There are no fires, no voices, only the faint crack of distant ice under deep frost. It is the kind of place that makes Azeroth feel vast, indifferent, and strangely peaceful." },

    { name = "Bay of Storms Cliff Edge", mapID = 1447, x = 0.731, y = 0.196, description = "The cliff edge above the Bay of Storms drops hard into churning black water lit by cold flashes of sea-light. Salt wind tears across the rock shelf and carries the roar of waves up in uneven bursts. Ruined stonework nearby hints at lives and empires that once looked out over this same violent coast. Standing here feels like balancing between beauty and ruin at the very rim of Kalimdor." },
    { name = "Abandoned Highborne Ruin Platform", mapID = 1447, x = 0.602, y = 0.313, description = "A raised platform of cracked Highborne stone sits half-swallowed by weeds, overlooking broken terraces and distant surf. Faded arcane motifs still trace the floor, worn smooth by time and weather rather than footsteps. The silence is deep enough that the smallest movement echoes against the old masonry. It is a suspended fragment of a fallen age, waiting without expectation for anyone to remember it." },

    { name = "Far Northern Farmland", mapID = 1422, x = 0.449, y = 0.071, description = "In the far north of Western Plaguelands, the fields thin into bleak rows of dead crops and collapsed fencing. The soil is pale and dry, and every gust stirs dust where grain once grew in abundance. No lanterns burn here now, only crows circling low over the empty lots. The farmland is quiet in a way that speaks of loss more than decay." },
    { name = "Caer Darrow Outer Lake Margin", mapID = 1422, x = 0.715, y = 0.841, description = "Beyond Caer Darrow's familiar approach, the outer lake margin curves into reeds and half-flooded stone. Ripples lap against broken steps that descend into dark water, reflecting the island in warped fragments. The academy's shadow stretches long across the shoreline, turning evening into something heavier. It is a solemn border where still water and old sorcery meet." },

    { name = "Western Outer Dunes Beyond Hive Patrols", mapID = 1451, x = 0.246, y = 0.566, description = "West of the known patrol paths, the dunes roll in long ridges that hide you from nearly every sign of civilization. Sand hisses across buried chitin and ancient rock, drawing shifting lines that vanish by the next minute. The sky feels enormous here, and the sun turns every crest into burning gold by day and ash-gray by dusk. It is a desert margin where even the hives seem to lose interest in pursuit." },

    { name = "Root Descent Cliffs Below Rut'theran", mapID = 1438, x = 0.589, y = 0.962, description = "Below Rut'theran, the giant roots descend into steep cliffs laced with mist and spray from the sea below. Bark and stone fuse together in impossible angles, forming narrow ledges above a sheer drop. Looking up, Teldrassil's canopy blots out much of the sky, turning daylight into a muted emerald glow. It feels like standing between world-tree myth and open ocean, with no clear path back." },

    { name = "Seradane Outer Treeline", mapID = 1425, x = 0.651, y = 0.211, description = "At Seradane's outer treeline, ancient trunks gather into a dim border where the wind barely reaches the ground. Moss-covered roots knot over old stone and form natural thresholds into deeper forest. The air carries a soft, constant rustle, as though unseen wings pass overhead and vanish. It is a tranquil but watchful edge, where the wild feels old enough to remember everything." },

    { name = "Irontree Northern Charred Ridge", mapID = 1448, x = 0.564, y = 0.138, description = "North of Irontree, a charred ridge rises above Felwood in blackened layers of ash, bark, and exposed rock. Burnt trunks stand like spears against a bruised sky while faint green haze drifts through the hollows below. Every step crunches with brittle remnants of a forest that never truly recovered. The ridge is grim and unforgettable, a stark line between survival and corruption." },
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
    self.previousDistanceYards = nil

    if self.ui and self.ui.arrowFrame then
        self.ui.arrowFrame:Hide()
    end

    if self.ui and self.ui.arrowTexture then
        self.ui.arrowTexture:SetRotation(0)
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
    self.previousDistanceYards = nil

    if self.ui and self.ui.arrowFrame then
        self.ui.arrowFrame:Show()
    end

    if self.ui and self.ui.arrowTexture then
        self.ui.arrowTexture:SetAlpha(1)
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

        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage("You have reached the edge of Azeroth.", 1.0, 0.8, 0.2, 3)
        end

        if UIFrameFadeOut and self.ui and self.ui.arrowFrame then
            UIFrameFadeOut(self.ui.arrowFrame, 1, 1, 0)
        end

        if PlaySound then
            if SOUNDKIT and SOUNDKIT.UI_QUEST_COMPLETE then
                PlaySound(SOUNDKIT.UI_QUEST_COMPLETE, "Master")
            else
                PlaySound(12889, "Master")
            end
        end

        return
    end

    local smoothedDistance = distanceYards
    if type(self.previousDistanceYards) == "number" then
        smoothedDistance = self.previousDistanceYards + ((distanceYards - self.previousDistanceYards) * 0.25)
    end
    self.previousDistanceYards = smoothedDistance

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText(string.format("Distance (approx): %d yards", math.floor(smoothedDistance + 0.5)))
    end

    local travelSeconds = self:GetTravelTimeSeconds(distanceYards)
    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time (rough): " .. FormatTime(travelSeconds or 0))
    end

    self:UpdateArrowRotation(playerX, playerY, destination)
end

function EdgeOfAzeroth:CreateArrowFrame()
    local frame = CreateFrame("Frame", addonName .. "ArrowFrame", UIParent)
    frame:SetSize(120, 120)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -40)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(200)
    frame:SetToplevel(true)
    frame:Hide()

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\Minimap\\MinimapArrow")
    texture:SetAlpha(1)

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
    local frame = CreateFrame("Frame", addonName .. "MainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(470, 340)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    if frame.CloseButton then
        frame.CloseButton:ClearAllPoints()
        frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("Edge Of Azeroth")

    local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -44)
    dropdownLabel:SetText("Destination")

    local dropdown = CreateFrame("Frame", addonName .. "DestinationDropdown", frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -16, -6)

    local descriptionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    descriptionLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 20, -8)
    descriptionLabel:SetText("Description")

    local descriptionScrollFrame = CreateFrame("ScrollFrame", addonName .. "DescriptionScrollFrame", frame, "UIPanelScrollFrameTemplate")
    descriptionScrollFrame:SetPoint("TOPLEFT", descriptionLabel, "BOTTOMLEFT", 4, -8)
    descriptionScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 66)

    local descriptionContent = CreateFrame("Frame", nil, descriptionScrollFrame)
    descriptionContent:SetSize(410, 1)

    local descriptionText = descriptionContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", descriptionContent, "TOPLEFT", 0, 0)
    descriptionText:SetPoint("TOPRIGHT", descriptionContent, "TOPRIGHT", 0, 0)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetJustifyV("TOP")
    descriptionText:SetNonSpaceWrap(true)
    descriptionText:SetText("Select a destination to begin navigation.")

    descriptionScrollFrame:SetScrollChild(descriptionContent)

    local function UpdateDescriptionHeight()
        local textHeight = descriptionText:GetStringHeight() or 0
        descriptionContent:SetHeight(math.max(180, math.ceil(textHeight) + 8))
    end

    descriptionScrollFrame:HookScript("OnMouseWheel", function(scrollSelf, delta)
        local scrollBar = scrollSelf and scrollSelf.ScrollBar
        if not scrollBar or not scrollBar.GetMinMaxValues or not scrollBar.GetValue or not scrollBar.SetValue then
            return
        end

        local minVal, maxVal = scrollBar:GetMinMaxValues()
        if maxVal and maxVal > 0 then
            local current = scrollBar:GetValue() or 0
            scrollBar:SetValue(math.max(minVal or 0, math.min(maxVal, current - (delta * 20))))
        end
    end)
    descriptionScrollFrame:EnableMouseWheel(true)

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
        UpdateDescriptionHeight()
        descriptionScrollFrame:SetVerticalScroll(0)
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
    UpdateDescriptionHeight()

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
    if self.initialized then
        return
    end

    self.initialized = true

    self:CreateMainWindow()
    self:CreateArrowFrame()

    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(_, elapsed)
        EdgeOfAzeroth:UpdateNavigation(elapsed)
    end)

    self.ui.updateFrame = updateFrame

    SLASH_EDGEOFAZEROTH1 = "/eoa"
    SlashCmdList["EDGEOFAZEROTH"] = function()
        EdgeOfAzeroth:ToggleMainWindow()
    end
end

EdgeOfAzeroth:Initialize()
