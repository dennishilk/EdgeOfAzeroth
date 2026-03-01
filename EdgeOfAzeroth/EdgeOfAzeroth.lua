local addonName = ...

local EdgeOfAzeroth = {
    activeDestination = nil,
    navigationActive = false,
    yardsPerMapUnit = 10000,
    updateInterval = 0.05,
    elapsed = 0,
}

local Destinations = {
    {
        name = "Quel'Thalas Border (Eastern Plaguelands side)",
        mapID = 1423,
        x = 0.829,
        y = 0.086,
        description = "A remote northern border zone where old paths fade into forgotten lands.",
    },
    {
        name = "Winterspring Hidden Troll Ruins",
        mapID = 1452,
        x = 0.347,
        y = 0.526,
        description = "Deep in Winterspring, these neglected ruins feel cut off from the world.",
    },
    {
        name = "Azshara Forgotten Coast",
        mapID = 1447,
        x = 0.816,
        y = 0.284,
        description = "A lonely coastline where broken cliffs and silence mark Azeroth's outer edge.",
    },
}

local function FormatTime(seconds)
    if not seconds or seconds < 0 then
        return "0m 0s"
    end

    local minutes = math.floor(seconds / 60)
    local remainderSeconds = math.floor(seconds % 60)
    return string.format("%dm %ds", minutes, remainderSeconds)
end

local function GetPlayerMapData()
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not position then
        return nil
    end

    return playerMapID, position.x, position.y
end

function EdgeOfAzeroth:CalculateDistanceYards(fromX, fromY, toX, toY)
    if not fromX or not fromY or not toX or not toY then
        return nil
    end

    local dx = toX - fromX
    local dy = toY - fromY
    local distance = math.sqrt((dx * dx) + (dy * dy))
    return distance * self.yardsPerMapUnit
end

function EdgeOfAzeroth:StopNavigation(silent)
    self.navigationActive = false
    self.activeDestination = nil

    if self.arrowFrame then
        self.arrowFrame:Hide()
    end

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText("Distance: --")
    end

    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time: --")
    end

    if not silent then
        DEFAULT_CHAT_FRAME:AddMessage("Edge Of Azeroth: Navigation stopped.")
    end
end

function EdgeOfAzeroth:StartNavigation(destination)
    if not destination then
        DEFAULT_CHAT_FRAME:AddMessage("Edge Of Azeroth: Please select a destination first.")
        return
    end

    self.activeDestination = destination
    self.navigationActive = true

    if self.arrowFrame then
        self.arrowFrame:Show()
    end

    DEFAULT_CHAT_FRAME:AddMessage("Edge Of Azeroth: Navigation started to " .. destination.name .. ".")
end

function EdgeOfAzeroth:UpdateNavigation(elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < self.updateInterval then
        return
    end
    self.elapsed = 0

    if not self.navigationActive or not self.activeDestination then
        return
    end

    local playerMapID, playerX, playerY = GetPlayerMapData()
    if not playerMapID or not playerX or not playerY then
        return
    end

    local destination = self.activeDestination

    if playerMapID ~= destination.mapID then
        if self.ui and self.ui.distanceText then
            self.ui.distanceText:SetText("Distance: Different zone")
        end

        if self.ui and self.ui.timeText then
            self.ui.timeText:SetText("Estimated Time: --")
        end
        return
    end

    local distanceYards = self:CalculateDistanceYards(playerX, playerY, destination.x, destination.y)
    if not distanceYards then
        return
    end

    if self.ui and self.ui.distanceText then
        self.ui.distanceText:SetText(string.format("Distance: %d yards", math.floor(distanceYards + 0.5)))
    end

    local speed = IsMounted() and 14 or 7
    local estimatedSeconds = distanceYards / speed

    if self.ui and self.ui.timeText then
        self.ui.timeText:SetText("Estimated Time: " .. FormatTime(estimatedSeconds))
    end

    if distanceYards < 10 then
        DEFAULT_CHAT_FRAME:AddMessage("You have reached the edge of Azeroth.")
        self:StopNavigation(true)
        return
    end

    if self.arrowFrame and self.arrowFrame.texture then
        local dx = destination.x - playerX
        local dy = destination.y - playerY

        local angleToDestination = math.atan2(-dy, dx)
        local playerFacing = GetPlayerFacing() or 0
        local rotation = angleToDestination - playerFacing

        self.arrowFrame.texture:SetRotation(rotation)
    end
end

function EdgeOfAzeroth:CreateArrowFrame()
    local frame = CreateFrame("Frame", addonName .. "ArrowFrame", UIParent)
    frame:SetSize(96, 96)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -80)
    frame:Hide()

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints(true)
    texture:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAP-ARROW")

    frame.texture = texture

    local distanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    distanceText:SetPoint("TOP", frame, "BOTTOM", 0, -6)
    distanceText:SetText("Distance: --")

    local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOP", distanceText, "BOTTOM", 0, -4)
    timeText:SetText("Estimated Time: --")

    self.arrowFrame = frame
    self.ui.distanceText = distanceText
    self.ui.timeText = timeText
end

function EdgeOfAzeroth:CreateMainWindow()
    local frame = CreateFrame("Frame", addonName .. "MainFrame", UIParent, "UIPanelDialogTemplate")
    frame:SetSize(420, 250)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -16)
    title:SetText("Edge Of Azeroth")

    local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -42)
    dropdownLabel:SetText("Destination")

    local dropdown = CreateFrame("Frame", addonName .. "DestinationDropdown", frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -16, -6)

    local descriptionText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descriptionText:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 20, -10)
    descriptionText:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    descriptionText:SetJustifyH("LEFT")
    descriptionText:SetJustifyV("TOP")
    descriptionText:SetText("Select a destination to begin navigation.")

    local startButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    startButton:SetSize(140, 26)
    startButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    startButton:SetText("Start Navigation")

    local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    stopButton:SetSize(140, 26)
    stopButton:SetPoint("LEFT", startButton, "RIGHT", 12, 0)
    stopButton:SetText("Stop Navigation")

    local function OnDestinationSelected(_, selectedDestination)
        EdgeOfAzeroth.activeDestination = selectedDestination
        UIDropDownMenu_SetText(dropdown, selectedDestination.name)
        descriptionText:SetText(selectedDestination.description)
    end

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for _, destination in ipairs(Destinations) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = destination.name
            info.func = OnDestinationSelected
            info.arg1 = destination
            info.checked = EdgeOfAzeroth.activeDestination == destination
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetWidth(dropdown, 300)
    UIDropDownMenu_SetText(dropdown, "Choose a destination")

    startButton:SetScript("OnClick", function()
        EdgeOfAzeroth:StartNavigation(EdgeOfAzeroth.activeDestination)
    end)

    stopButton:SetScript("OnClick", function()
        EdgeOfAzeroth:StopNavigation()
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
    self.ui = {}

    self:CreateMainWindow()
    self:CreateArrowFrame()

    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(_, elapsed)
        EdgeOfAzeroth:UpdateNavigation(elapsed)
    end)

    self.updateFrame = updateFrame

    SLASH_EDGEOFAZEROTH1 = "/eoa"
    SlashCmdList.EDGEOFAZEROTH = function()
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
