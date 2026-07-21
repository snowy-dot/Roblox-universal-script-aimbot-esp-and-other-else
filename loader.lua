--!nocheck
-- UNIVERSAL HUB: ESP & AIMBOT EDITION

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- Load Rayfield
local Rayfield = nil
pcall(function()
    local response = game:HttpGet('https://sirius.menu/rayfield')
    local func = loadstring(response)
    if func then
        Rayfield = func()
    end
end)

if not Rayfield then
    pcall(function()
        local response = game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua')
        local func = loadstring(response)
        if func then
            Rayfield = func()
        end
    end)
end

if not Rayfield then
    print("Rayfield failed to load")
    return
end

-- State
local State = {}
State.ESP_Enabled = false
State.ESP_Box = true
State.ESP_Name = true
State.ESP_Distance = true
State.ESP_Tracers = false
State.ESP_Objects = {}

State.Aimbot_Enabled = false
State.Aimbot_FOV = 120
State.Aimbot_Smooth = 5
State.Aimbot_WallCheck = true
State.Aimbot_TeamCheck = true
State.Aimbot_ShowFOV = true

-- Visuals Setup
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "UniversalVisuals"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true

pcall(function()
    ESPGui.Parent = gethui()
end)
if not ESPGui.Parent then
    pcall(function()
        ESPGui.Parent = CoreGui
    end)
end
if not ESPGui.Parent then
    ESPGui.Parent = LP:WaitForChild("PlayerGui")
end

-- FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(0, 240, 0, 240)
FOVCircle.Position = UDim2.new(0.5, -120, 0.5, -120)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = ESPGui
FOVCircle.Visible = false

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.5
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(0, 120)
FOVCorner.Parent = FOVCircle

-- ESP Functions
local function createESP(player)
    if State.ESP_Objects[player] then
        return
    end
    
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Parent = ESPGui

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = box

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 1, 0, 1)
    tracer.Visible = false
    tracer.Parent = frame

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.Visible = false
    nameLbl.Parent = frame

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
    distLbl.TextStrokeTransparency = 0.5
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.Visible = false
    distLbl.Parent = frame

    State.ESP_Objects[player] = {
        Frame = frame, 
        Box = box, 
        Tracer = tracer, 
        Name = nameLbl, 
        Dist = distLbl
    }
end

local function removeESP(player)
    if State.ESP_Objects[player] then
        State.ESP_Objects[player].Frame:Destroy()
        State.ESP_Objects[player] = nil
    end
end

Players.PlayerRemoving:Connect(removeESP)

-- Aimbot Logic
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDist = State.Aimbot_FOV
    local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local isTeam = false
            if State.Aimbot_TeamCheck and player.Team == LP.Team then
                isTeam = true
            end

            if not isTeam then
                local head = player.Character:FindFirstChild("Head")
                local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

                if head and targetHrp and myHrp then
                    local screenPos, onScreen = Cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDist then
                            local visible = true
                            if State.Aimbot_WallCheck then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                rayParams.FilterDescendantsInstances = {LP.Character, player.Character}
                                local result = workspace:Raycast(myHrp.Position, (head.Position - myHrp.Position).Unit * (head.Position - myHrp.Position).Magnitude, rayParams)
                                if result then
                                    visible = false
                                end
                            end
                            
                            if visible then
                                shortestDist = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    -- FOV Circle Update
    if State.Aimbot_ShowFOV and State.Aimbot_Enabled then
        FOVCircle.Visible = true
        local size = State.Aimbot_FOV * 2
        FOVCircle.Size = UDim2.fromOffset(size, size)
        FOVCircle.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
    else
        FOVCircle.Visible = false
    end

    -- Aimbot Update
    if State.Aimbot_Enabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetHead = target.Character:FindFirstChild("Head")
            if targetHead then
                -- 10 = Fast, 1 = Sticky. So alpha = Smoothness / 10
                local alpha = State.Aimbot_Smooth / 10
                local targetCFrame = CFrame.lookAt(Cam.CFrame.Position, targetHead.Position)
                Cam.CFrame = Cam.CFrame:Lerp(targetCFrame, alpha)
            end
        end
    end

    -- ESP Update
    if not State.ESP_Enabled then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            if not State.ESP_Objects[player] then
                createESP(player)
            end

            local obj = State.ESP_Objects[player]
            if player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local head = player.Character:FindFirstChild("Head")
                
                if hrp and head then
                    local headScreen, onScreen = Cam:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local legScreen = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headScreen.Y - legScreen.Y)
                        if height < 10 then
                            height = 10
                        end
                        local width = height / 2

                        -- Box
                        obj.Box.Position = UDim2.fromOffset(headScreen.X - width/2, headScreen.Y)
                        obj.Box.Size = UDim2.fromOffset(width, height)
                        obj.Box.Visible = State.ESP_Box

                        -- Name
                        if State.ESP_Name then
                            obj.Name.Position = UDim2.fromOffset(headScreen.X, headScreen.Y - 15)
                            obj.Name.Text = player.Name
                            obj.Name.Visible = true
                        else
                            obj.Name.Visible = false
                        end

                        -- Distance
                        if State.ESP_Distance then
                            local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local dist = 0
                            if myHrp then
                                dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
                            end
                            obj.Dist.Position = UDim2.fromOffset(headScreen.X, headScreen.Y - 30)
                            obj.Dist.Text = dist .. "m"
                            obj.Dist.Visible = true
                        else
                            obj.Dist.Visible = false
                        end

                        -- Tracers
                        if State.ESP_Tracers then
                            local p1 = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                            local p2 = Vector2.new(headScreen.X, headScreen.Y)
                            local dist = (p2 - p1).Magnitude
                            local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
                            
                            obj.Tracer.Position = UDim2.fromOffset((p1.X + p2.X)/2, (p1.Y + p2.Y)/2)
                            obj.Tracer.Size = UDim2.fromOffset(dist, 1)
                            obj.Tracer.Rotation = math.deg(angle)
                            obj.Tracer.Visible = true
                        else
                            obj.Tracer.Visible = false
                        end
                    else
                        obj.Box.Visible = false
                        obj.Name.Visible = false
                        obj.Dist.Visible = false
                        obj.Tracer.Visible = false
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                    obj.Dist.Visible = false
                    obj.Tracer.Visible = false
                end
            else
                obj.Box.Visible = false
                obj.Name.Visible = false
                obj.Dist.Visible = false
                obj.Tracer.Visible = false
            end
        end
    end
end)

-- ============================================
-- UI SETUP
-- ============================================
local WindowConfig = {
    Name = "Universal Hub",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "ESP & Aimbot",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
}
local Window = Rayfield:CreateWindow(WindowConfig)

local TabESP = Window:CreateTab("ESP", 4483362458)
local TabAimbot = Window:CreateTab("Aimbot", 4483362458)

-- ESP Tab
local ESPEnableConfig = {
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        State.ESP_Enabled = Value
    end
}
TabESP:CreateToggle(ESPEnableConfig)

local ESPBoxConfig = {
    Name = "Box ESP",
    CurrentValue = true,
    Callback = function(Value)
        State.ESP_Box = Value
    end
}
TabESP:CreateToggle(ESPBoxConfig)

local ESPNameConfig = {
    Name = "Name ESP",
    CurrentValue = true,
    Callback = function(Value)
        State.ESP_Name = Value
    end
}
TabESP:CreateToggle(ESPNameConfig)

local ESPDistConfig = {
    Name = "Distance ESP",
    CurrentValue = true,
    Callback = function(Value)
        State.ESP_Distance = Value
    end
}
TabESP:CreateToggle(ESPDistConfig)

local ESPTracerConfig = {
    Name = "Tracers",
    CurrentValue = false,
    Callback = function(Value)
        State.ESP_Tracers = Value
    end
}
TabESP:CreateToggle(ESPTracerConfig)

-- Aimbot Tab
local AimbotEnableConfig = {
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        State.Aimbot_Enabled = Value
    end
}
TabAimbot:CreateToggle(AimbotEnableConfig)

local AimbotFOVConfig = {
    Name = "Aimbot FOV",
    Range = {10, 500},
    Increment = 1,
    CurrentValue = 120,
    Callback = function(Value)
        State.Aimbot_FOV = Value
    end
}
TabAimbot:CreateSlider(AimbotFOVConfig)

local AimbotSmoothConfig = {
    Name = "Smoothness (10 = Fast, 1 = Sticky)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        State.Aimbot_Smooth = Value
    end
}
TabAimbot:CreateSlider(AimbotSmoothConfig)

local AimbotWallConfig = {
    Name = "Wall Check",
    CurrentValue = true,
    Callback = function(Value)
        State.Aimbot_WallCheck = Value
    end
}
TabAimbot:CreateToggle(AimbotWallConfig)

local AimbotTeamConfig = {
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(Value)
        State.Aimbot_TeamCheck = Value
    end
}
TabAimbot:CreateToggle(AimbotTeamConfig)

local AimbotShowFOVConfig = {
    Name = "Show FOV Circle",
    CurrentValue = true,
    Callback = function(Value)
        State.Aimbot_ShowFOV = Value
    end
}
TabAimbot:CreateToggle(AimbotShowFOVConfig)

local NotifyConfig = {
    Title = "Universal Hub",
    Content = "Loaded successfully! Press RightCtrl to toggle UI.",
    Duration = 3
}
Rayfield:Notify(NotifyConfig)
