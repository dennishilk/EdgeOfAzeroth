EdgeOfAzeroth = EdgeOfAzeroth or {}
local EOA = EdgeOfAzeroth

EOA.initialized = false
EOA.navigationActive = false
EOA.activeEntry = nil
EOA.filteredEntries = {}
EOA.selectedEntryID = nil
EOA.currentMode = "ALL"
EOA.currentZone = "ALL"
EOA.smoothDistance = nil
EOA.updateAccumulator = 0
EOA.updateRate = 0.10
EOA.defaultYardsPerUnit = 10000

local MODE_OPTIONS = {
    { value = "ALL", text = "All" },
    { value = "SCENIC", text = "Scenic" },
    { value = "DUNGEON", text = "Dungeons" },
    { value = "FARM", text = "Farming" },
    { value = "FAVORITES", text = "Favorites" },
}

local TYPE_LABELS = {
    SCENIC = "Scenic",
    DUNGEON = "Dungeon",
    FARM = "Farm",
}

local function GetMapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if info and info.name then
        return info.name
    end
    return string.format("Map %d", tonumber(mapID) or 0)
end

EOA.AtlasData = {
    { id = "scenic_darkshore_cliffs", name = "Cliffs of Auberdine", mapID = 1439, x = 0.386, y = 0.438, type = "SCENIC", zoneGroup = "Kalimdor", tags = { "coast", "sunset", "elven" }, description = "The high cliffs above Auberdine look out over a restless sea and moonlit stone arches. The route is straightforward from the road and safe for low-level travelers if they avoid hostile wildlife. Visibility is excellent, making it a favorite place to pause and orient by landmarks. At dusk, the surf and sky create a dramatic horizon that feels unmistakably classic." },
    { id = "scenic_azshara_bay", name = "Bay of Storms Overlook", mapID = 1447, x = 0.778, y = 0.196, type = "SCENIC", zoneGroup = "Kalimdor", tags = { "azshara", "cliff", "ocean" }, description = "This overlook sits above Azshara's fractured coast where waves strike black rock in rhythmic bursts. The path is accessible by ground travel and requires no exploits or unusual movement. Ruined Highborne structures nearby provide clear visual anchors for navigation and screenshots. The location captures the wild, unfinished grandeur that defines old Azeroth's shorelines." },
    { id = "scenic_winterspring_frostsaber", name = "Frostsaber Ridge", mapID = 1452, x = 0.494, y = 0.159, type = "SCENIC", zoneGroup = "Kalimdor", tags = { "snow", "ridge", "winter" }, description = "Frostsaber Ridge rises above the snowfields with long sightlines across northern Winterspring. Reaching it is reliable by the established mountain routes and does not require out-of-bounds travel. The open white terrain makes map-based calibration simple and repeatable for testing. In clear weather, the area feels vast and quiet, with only wind and distant creature calls." },
    { id = "scenic_tanaris_dunes", name = "Tanaris Singing Dunes", mapID = 1446, x = 0.557, y = 0.296, type = "SCENIC", zoneGroup = "Kalimdor", tags = { "desert", "dunes", "sunrise" }, description = "The dunes east of Gadgetzan form layered sand ridges that are easy to approach by road and open terrain. The broad landscape helps validate arrow direction at long ranges without dense obstacle clutter. Creature density is moderate, so short stops are usually safe with normal awareness. The warm light and sweeping sand patterns make this one of Kalimdor's most cinematic plains." },
    { id = "scenic_ungoro_rim", name = "Un'Goro Crater Rim", mapID = 1449, x = 0.468, y = 0.138, type = "SCENIC", zoneGroup = "Kalimdor", tags = { "volcanic", "jungle", "vista" }, description = "From the crater rim, the basin opens below in a wide green bowl framed by volcanic stone. The route is established and reachable on foot using normal zone pathways. Elevation changes here are useful for testing map pin updates while preserving stable coordinates. The contrast between jungle canopy and dark rock gives the spot a striking prehistoric atmosphere." },
    { id = "scenic_hinterlands_peak", name = "Aerie Peak Skyview", mapID = 1425, x = 0.142, y = 0.461, type = "SCENIC", zoneGroup = "Eastern Kingdoms", tags = { "mountain", "hinterlands", "highlands" }, description = "Near Aerie Peak, the highland routes provide broad visibility over valleys and rivers below. The terrain is traversable through normal paths and flight points, with no gimmicks required. It is a practical place to compare map and minimap awareness while navigating uneven contours. Clear weather turns the region into a layered panorama of pine, stone, and distant coast." },
    { id = "scenic_swamp_ruins", name = "Sunken Ruins Causeway", mapID = 1435, x = 0.695, y = 0.532, type = "SCENIC", zoneGroup = "Eastern Kingdoms", tags = { "swamp", "ruins", "mist" }, description = "The old causeway through the swamp passes weathered masonry and shallow flooded ground. Access is uncomplicated by road, making it dependable for repeat visits during testing sessions. The area offers strong ambient visuals with fog, water reflections, and ruined silhouettes. It feels ancient and quiet, with a persistent sense of forgotten history." },
    { id = "scenic_plaguelands_lake", name = "Caer Darrow Shoreline", mapID = 1422, x = 0.701, y = 0.734, type = "SCENIC", zoneGroup = "Eastern Kingdoms", tags = { "lake", "scholomance", "somber" }, description = "The lake around Caer Darrow provides a stark, memorable setting with dark water and cold stone. The shoreline can be reached by standard routes and supports precise coordinate checks near clear landmarks. It is useful for validating map pin placement because the water edge creates obvious positional references. The scene carries a grim stillness that fits the surrounding plague-scarred lands." },
    { id = "scenic_deadwind_pass", name = "Deadwind Southern Ridge", mapID = 1430, x = 0.536, y = 0.780, type = "SCENIC", zoneGroup = "Eastern Kingdoms", tags = { "karazhan", "ridge", "twilight" }, description = "South of Karazhan, a barren ridge overlooks the broken roads and dead grass of Deadwind Pass. The area is reachable by normal travel and is often quiet enough for uninterrupted testing. Sparse terrain features make orientation straightforward when calibrating target points. The atmosphere is bleak and dramatic, especially when the tower silhouette dominates the horizon." },
    { id = "scenic_dunmorogh_lake", name = "Gol'Bolar Icewater", mapID = 1426, x = 0.339, y = 0.399, type = "SCENIC", zoneGroup = "Eastern Kingdoms", tags = { "snow", "dwarf", "lake" }, description = "The frozen waters near Gol'Bolar Quarry offer a calm northern scene framed by dwarf stonework and pines. Paths are straightforward from Kharanos, so this point is ideal for early-level atlas checks. Open ice and shoreline geometry create easy visual cues for map marker verification. The region feels resilient and lived-in, with a classic dwarven frontier character." },

    { id = "dungeon_deadmines", name = "The Deadmines Entrance", mapID = 1436, x = 0.420, y = 0.715, type = "DUNGEON", zoneGroup = "Eastern Kingdoms", tags = { "dm", "westfall", "instance" }, description = "The Deadmines entrance is tucked in Moonbrook's mine network and remains one of Classic's most recognizable dungeon starts. Approach is consistent along Westfall roads with familiar hostile patrols nearby. This location is practical for party rendezvous and directional arrow checks in compact terrain. The surrounding ruins reinforce the narrative of a workers' revolt turned entrenched threat." },
    { id = "dungeon_shadowfang", name = "Shadowfang Keep Entrance", mapID = 1421, x = 0.458, y = 0.684, type = "DUNGEON", zoneGroup = "Eastern Kingdoms", tags = { "sfk", "silverpine", "instance" }, description = "Shadowfang Keep stands above Pyrewood as a clear landmark visible from much of the zone. The approach road is direct and easy to follow for repeated navigation tests. Elevation changes near the keep are useful for validating smooth distance behavior. Its gothic architecture and persistent fog make the final approach especially atmospheric." },
    { id = "dungeon_scarlet_monastery", name = "Scarlet Monastery Entrance", mapID = 1420, x = 0.852, y = 0.322, type = "DUNGEON", zoneGroup = "Eastern Kingdoms", tags = { "sm", "tirisfal", "instance" }, description = "The Scarlet Monastery gates are located in northeastern Tirisfal and are easy to identify from the surrounding road network. Travel paths are well known, making this a stable benchmark for destination selection and pin updates. The exterior courtyard provides enough space for group assembly and coordinate calibration. It remains a high-traffic classic hub for multiple wings and level brackets." },
    { id = "dungeon_blackrock_depths", name = "Blackrock Depths Entrance", mapID = 1435, x = 0.341, y = 0.846, type = "DUNGEON", zoneGroup = "Eastern Kingdoms", tags = { "brd", "blackrock", "instance" }, description = "Blackrock Depths is reached through Blackrock Mountain, with interior chains and platforms leading toward the instance portal. The route requires care but follows standard geometry and established travel patterns. This destination is excellent for testing precision around vertical spaces and confined approach lines. The volcanic setting gives the area a distinct industrial and militarized tone." },
    { id = "dungeon_zulfarrak", name = "Zul'Farrak Entrance", mapID = 1446, x = 0.395, y = 0.213, type = "DUNGEON", zoneGroup = "Kalimdor", tags = { "zf", "tanaris", "instance" }, description = "Zul'Farrak rises from northern Tanaris as a broad troll city with a clear entrance approach. Open desert terrain allows clean long-distance arrow tracking before final convergence. It is straightforward to reach by mount and works well for mid-level route planning tests. The stepped sandstone architecture makes the complex visible from afar." },
    { id = "dungeon_maraudon", name = "Maraudon Entrance", mapID = 1443, x = 0.292, y = 0.623, type = "DUNGEON", zoneGroup = "Kalimdor", tags = { "mara", "desolace", "instance" }, description = "Maraudon lies in the orange canyons of Desolace and is accessed through winding valley paths. The terrain is traversable without special movement, though nearby centaur can pressure slower groups. This point is useful for testing route persistence through curved approaches and mixed elevation. The area blends harsh stone with surprisingly vivid natural color around the caverns." },

    { id = "farm_eastern_plaguebats", name = "Plaguebat Circuit", mapID = 1415, x = 0.777, y = 0.552, type = "FARM", zoneGroup = "Eastern Kingdoms", tags = { "runecloth", "bats", "vendor" }, description = "The eastern ridges host plaguebats with a practical loop for steady cloth and vendor trash farming. Pathing is simple enough to maintain momentum while avoiding unnecessary backtracking. It is suitable for solo sessions with consistent pull spacing and quick resets. The route rewards awareness but remains manageable with standard consumables and gear." },
    { id = "farm_felwood_satyrs", name = "Felwood Satyr Camp", mapID = 1448, x = 0.375, y = 0.673, type = "FARM", zoneGroup = "Kalimdor", tags = { "felcloth", "satyr", "demons" }, description = "Felwood satyr camps are a classic destination for players seeking demonic loot tables and repeatable grinding. The area supports circular pulls with minimal dead travel between packs. Hostiles can pressure cloth classes, but terrain remains readable and practical for controlled farming. The corrupted forest visuals make long sessions feel distinct and immersive." },
    { id = "farm_winterfall_furbolgs", name = "Winterfall Furbolg Grounds", mapID = 1452, x = 0.659, y = 0.408, type = "FARM", zoneGroup = "Kalimdor", tags = { "reputation", "furbolg", "winterspring" }, description = "Winterfall camps provide a compact grind route with clear spawn clusters in snowy terrain. Movement between targets is efficient and supports both reputation and material goals. The zone's visibility helps maintain pace and quickly identify respawn timings. This is a stable option for players who prefer structured loops over broad roaming." },
    { id = "farm_silithus_twilight", name = "Twilight Base Camp", mapID = 1451, x = 0.483, y = 0.371, type = "FARM", zoneGroup = "Kalimdor", tags = { "twilight", "texts", "silithus" }, description = "Twilight camps in Silithus are favored for repeatable kill loops and faction-related materials. The camp layout supports route planning with clear tent clusters and short transitions. Enemy density is high enough to keep combat continuous during active periods. Sandstorm ambience and cult encampments create a harsh but focused farming environment." },
}

EOA.ZoneFilterOptions = {}

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

local function MergeAllEntries()
    local merged = {}
    for _, entry in ipairs(EOA.AtlasData) do
        merged[#merged + 1] = entry
    end

    for _, custom in ipairs(EdgeOfAzerothDB.customSpots) do
        merged[#merged + 1] = custom
    end

    return merged
end

function EOA:RebuildZoneFilterOptions()
    local seen = {}
    local zones = {}

    for _, entry in ipairs(MergeAllEntries()) do
        if entry.mapID and not seen[entry.mapID] then
            seen[entry.mapID] = true
            zones[#zones + 1] = {
                mapID = entry.mapID,
                name = GetMapName(entry.mapID),
            }
        end
    end

    table.sort(zones, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    self.ZoneFilterOptions = zones
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

local function EntryMatchesFilters(entry, mode, zoneMapID, search)
    if mode == "SCENIC" and entry.type ~= "SCENIC" then
        return false
    elseif mode == "DUNGEON" and entry.type ~= "DUNGEON" then
        return false
    elseif mode == "FARM" and entry.type ~= "FARM" then
        return false
    elseif mode == "FAVORITES" and not EdgeOfAzerothDB.favorites[entry.id] then
        return false
    end

    if zoneMapID ~= "ALL" and entry.mapID ~= zoneMapID then
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
        if EntryMatchesFilters(entry, self.currentMode, self.currentZone, search) then
            self.filteredEntries[#self.filteredEntries + 1] = entry
        end
    end

    table.sort(self.filteredEntries, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

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

    self:RefreshResultsDropdown()
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
        self.ui.descriptionText:SetText("No matching results.")
        self:UpdateDescriptionHeight()
        self:UpdateWorldMapPin(nil)
        self.ui.favoriteButton:SetText("Favorite")
        return
    end

    local zoneName = GetMapName(entry.mapID)
    self.ui.descriptionText:SetText((entry.description or "") .. "\n\nZone: " .. zoneName .. "\nGroup: " .. (entry.zoneGroup or "-"))
    self:UpdateDescriptionHeight()

    local favored = EdgeOfAzerothDB.favorites[entry.id]
    if favored then
        self.ui.favoriteButton:SetText("Unfavorite")
    else
        self.ui.favoriteButton:SetText("Favorite")
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

function EOA:RefreshZoneDropdown()
    self:RebuildZoneFilterOptions()

    UIDropDownMenu_Initialize(self.ui.zoneDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        local allInfo = UIDropDownMenu_CreateInfo()
        allInfo.text = "All Zones"
        allInfo.checked = (self.currentZone == "ALL")
        allInfo.func = function()
            self.currentZone = "ALL"
            UIDropDownMenu_SetText(self.ui.zoneDropdown, "All Zones")
            self:RefreshFilteredEntries()
        end
        UIDropDownMenu_AddButton(allInfo, level)

        for _, zone in ipairs(self.ZoneFilterOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = zone.name
            info.checked = (self.currentZone == zone.mapID)
            info.func = function()
                self.currentZone = zone.mapID
                UIDropDownMenu_SetText(self.ui.zoneDropdown, zone.name)
                self:RefreshFilteredEntries()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    if self.currentZone == "ALL" then
        UIDropDownMenu_SetText(self.ui.zoneDropdown, "All Zones")
    else
        UIDropDownMenu_SetText(self.ui.zoneDropdown, GetMapName(self.currentZone))
    end
end

function EOA:RefreshResultsDropdown()
    UIDropDownMenu_Initialize(self.ui.resultsDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for _, entry in ipairs(self.filteredEntries) do
            local suffix = TYPE_LABELS[entry.type] or entry.type or "Spot"
            local info = UIDropDownMenu_CreateInfo()
            info.text = string.format("%s [%s]", entry.name or "Unknown", suffix)
            info.checked = (self.selectedEntryID == entry.id)
            info.func = function()
                self.selectedEntryID = entry.id
                UIDropDownMenu_SetText(self.ui.resultsDropdown, info.text)
                self:UpdateSelectionUI()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local selected = self:GetSelectedEntry()
    if selected then
        UIDropDownMenu_SetText(self.ui.resultsDropdown, string.format("%s [%s]", selected.name or "Unknown", TYPE_LABELS[selected.type] or selected.type or "Spot"))
    else
        UIDropDownMenu_SetText(self.ui.resultsDropdown, "No results")
    end
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
    self:RefreshZoneDropdown()
    self:RefreshFilteredEntries()

    self.selectedEntryID = id
    self:RefreshResultsDropdown()
    self:UpdateSelectionUI()

    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD54F[Edge Of Azeroth]|r Saved custom spot: " .. customEntry.name)
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
    frame.title:SetText("Edge Of Azeroth")

    frame.CloseButton:ClearAllPoints()
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)

    local bottomPadding = 22
    local leftPadding = 40
    local spacing = 10
    local buttonWidth = 160
    local buttonHeight = 24

    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
    modeLabel:SetText("Mode")

    local modeDropdown = CreateFrame("Frame", "EdgeOfAzerothModeDropdown", frame, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(modeDropdown, 150)

    local zoneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 196, -36)
    zoneLabel:SetText("Zone")

    local zoneDropdown = CreateFrame("Frame", "EdgeOfAzerothZoneDropdown", frame, "UIDropDownMenuTemplate")
    zoneDropdown:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(zoneDropdown, 150)

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 376, -36)
    searchLabel:SetText("Search")

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
    resultsLabel:SetText("Results")

    local resultsDropdown = CreateFrame("Frame", "EdgeOfAzerothResultsDropdown", frame, "UIDropDownMenuTemplate")
    resultsDropdown:SetPoint("TOPLEFT", resultsLabel, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(resultsDropdown, 510)

    local scrollFrame = CreateFrame("ScrollFrame", "EdgeOfAzerothDescriptionScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -155)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 100)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 180)
    scrollFrame:SetScrollChild(scrollChild)

    local descriptionText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetJustifyV("TOP")
    descriptionText:SetWidth(490)
    descriptionText:SetText("Select a destination to view details.")

    local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    startButton:SetSize(buttonWidth, buttonHeight)
    startButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", leftPadding, bottomPadding + buttonHeight + spacing)
    startButton:SetText("Start Navigation")
    startButton:SetScript("OnClick", function()
        EOA:StartNavigation()
    end)

    local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    stopButton:SetSize(buttonWidth, buttonHeight)
    stopButton:SetPoint("LEFT", startButton, "RIGHT", spacing, 0)
    stopButton:SetText("Stop Navigation")
    stopButton:SetScript("OnClick", function()
        EOA:StopNavigation(false)
    end)

    local calibrateButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    calibrateButton:SetSize(buttonWidth, buttonHeight)
    calibrateButton:SetPoint("LEFT", stopButton, "RIGHT", spacing, 0)
    calibrateButton:SetText("Set Target to My Position")
    calibrateButton:SetScript("OnClick", function()
        EOA:CalibrateSelectedToPlayerPosition()
    end)

    local saveCustomButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveCustomButton:SetSize(200, 24)
    saveCustomButton:ClearAllPoints()
    saveCustomButton:SetPoint("TOPLEFT", startButton, "BOTTOMLEFT", 0, -8)
    saveCustomButton:SetText("Save My Position as Custom Spot")
    saveCustomButton:SetScript("OnClick", function()
        EOA:SaveCustomSpotFromPlayerPosition()
    end)

    local favoriteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    favoriteButton:ClearAllPoints()
    favoriteButton:SetPoint("LEFT", saveCustomButton, "RIGHT", 10, 0)
    favoriteButton:SetSize(140, 24)
    favoriteButton.fitTextWidthPadding = 40
    favoriteButton:SetText("Favorite")
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
        zoneDropdown = zoneDropdown,
        searchBox = searchBox,
        resultsDropdown = resultsDropdown,
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
    self:RefreshZoneDropdown()
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
SlashCmdList["EDGEOFAZEROTH"] = function()
    if EdgeOfAzeroth and EdgeOfAzeroth.ToggleMainFrame then
        EdgeOfAzeroth:ToggleMainFrame()
    end
end

if EdgeOfAzeroth and EdgeOfAzeroth.Initialize then
    EdgeOfAzeroth:Initialize()
end
