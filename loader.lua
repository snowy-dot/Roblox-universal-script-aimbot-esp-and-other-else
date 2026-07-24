--!nocheck
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then return end

local Window = Rayfield:CreateWindow({
   Name = "Universal Aimbot & ESP",
   LoadingTitle = "Loading Hub...",
   LoadingSubtitle = "Advanced Edition",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabAimbot = Window:CreateTab("Aimbot", 4483362458)
local TabVisuals = Window:CreateTab("Visuals", 4483362458)
local TabSettings = Window:CreateTab("Settings", 4483362458)

-- ============================================
-- SETTINGS
-- ============================================
local Settings = {
    Aimbot = {
        Enabled = false,
        TeamCheck = false,
        AimPart = "Head",
        Smoothness = 0.2,
        FOV = 100,
        CameraLock = false -- This is the bypass that stops the game from fighting the aimbot
    },
    ESP = {
        Enabled = false,
        TeamCheck = false,
        Boxes = true,
        Names = true,
        Distance = true,
        Tracers = false,
        BoxColor = Color3.fromRGB(255, 0, 0),
        TextColor = Color3.fromRGB(255, 255, 255),
        TracerColor = Color3.fromRGB(255, 0, 0),
        TextSize = 13
    }
}

-- ============================================
-- AIMBOT LOGIC
-- ============================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Radius = 100
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Visible = false

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local isTeammate = false
            if Settings.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then isTeammate = true end

            if not isTeammate then
                local targetPart = player.Character:FindFirstChild(Settings.Aimbot.AimPart)
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                        if distance < Settings.Aimbot.FOV and distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Bind to RenderStep with High Priority to override game camera scripts
RunService:BindToRenderStep("AimbotUpdate", Enum.RenderPriority.Camera.Value + 1, function()
    -- Camera Lock Bypass: Forces the game to release camera control
    if Settings.Aimbot.CameraLock then
        if Camera.CameraType ~= Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Scriptable
        end
    else
        if Camera.CameraType ~= Enum.CameraType.Custom then
            Camera.CameraType = Enum.CameraType.Custom
        end
    end

    if Settings.Aimbot.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Radius = Settings.Aimbot.FOV
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        
        -- Check if Right Mouse Button is held
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetClosestPlayer()
            if target then
                local targetPart = target.Character:FindFirstChild(Settings.Aimbot.AimPart)
                if targetPart then
                    local targetPos = targetPart.Position
                    local aimCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                    
                    if Settings.Aimbot.Smoothness > 0 and Settings.Aimbot.Smoothness < 1 then
                        Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Settings.Aimbot.Smoothness)
                    else
                        Camera.CFrame = aimCFrame
                    end
                end
            end
        end
    else
        FOVCircle.Visible = false
    end
end)

-- ============================================
-- ESP LOGIC
-- ============================================
local EspObjects = {}

local function ClearEsp(player)
    if EspObjects[player] then
        for _, drawing in pairs(EspObjects[player]) do
            drawing:Remove()
        end
        EspObjects[player] = nil
    end
end

local function CreateEsp(player)
    ClearEsp(player)
    EspObjects[player] = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    local obj = EspObjects[player]
    obj.Box.Thickness = 1
    obj.Box.Filled = false
    obj.BoxOutline.Thickness = 3
    obj.BoxOutline.Filled = false
    obj.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    obj.Name.Size = 13
    obj.Name.Center = true
    obj.Name.Outline = true
    obj.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    obj.Distance.Size = 13
    obj.Distance.Center = true
    obj.Distance.Outline = true
    obj.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    obj.Tracer.Thickness = 1
end

Players.PlayerAdded:Connect(function(p) CreateEsp(p) end)
Players.PlayerRemoving:Connect(function(p) ClearEsp(p) end)
for _, p in ipairs(Players:GetPlayers()) do CreateEsp(p) end

RunService.RenderStepped:Connect(function()
    if Settings.ESP.Enabled then
        for player, obj in pairs(EspObjects) do
            local char = player.Character
            if char and player ~= LocalPlayer then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChild("Humanoid")
                if hrp and head and hum and hum.Health > 0 then
                    local isTeammate = false
                    if Settings.ESP.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then isTeammate = true end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen and not isTeammate then
                        local headPos = Camera:WorldToViewportPoint(head.Position)
                        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 2
                        
                        if Settings.ESP.Boxes then
                            obj.Box.Visible = true
                            obj.BoxOutline.Visible = true
                            obj.Box.Size = Vector2.new(width, height)
                            obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                            obj.Box.Color = Settings.ESP.BoxColor
                            obj.BoxOutline.Size = obj.Box.Size
                            obj.BoxOutline.Position = obj.Box.Position
                        else
                            obj.Box.Visible = false
                            obj.BoxOutline.Visible = false
                        end
                        
                        if Settings.ESP.Names then
                            obj.Name.Visible = true
                            obj.Name.Text = tostring(player.DisplayName)
                            obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 16)
                            obj.Name.Color = Settings.ESP.TextColor
                            obj.Name.Size = Settings.ESP.TextSize
                        else
                            obj.Name.Visible = false
                        end
                        
                        if Settings.ESP.Distance then
                            obj.Distance.Visible = true
                            local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                            obj.Distance.Text = tostring(dist) .. " studs"
                            obj.Distance.Position = Vector2.new(headPos.X, legPos.Y)
                            obj.Distance.Color = Settings.ESP.TextColor
                            obj.Distance.Size = Settings.ESP.TextSize
                        else
                            obj.Distance.Visible = false
                        end
                        
                        if Settings.ESP.Tracers then
                            obj.Tracer.Visible = true
                            obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            obj.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                            obj.Tracer.Color = Settings.ESP.TracerColor
                        else
                            obj.Tracer.Visible = false
                        end
                    else
                        obj.Box.Visible = false
                        obj.BoxOutline.Visible = false
                        obj.Name.Visible = false
                        obj.Distance.Visible = false
                        obj.Tracer.Visible = false
                    end
                else
                    if obj then
                        obj.Box.Visible = false
                        obj.BoxOutline.Visible = false
                        obj.Name.Visible = false
                        obj.Distance.Visible = false
                        obj.Tracer.Visible = false
                    end
                end
            else
                if obj then
                    obj.Box.Visible = false
                    obj.BoxOutline.Visible = false
                    obj.Name.Visible = false
                    obj.Distance.Visible = false
                    obj.Tracer.Visible = false
                end
            end
        end
    else
        for _, obj in pairs(EspObjects) do
            obj.Box.Visible = false
            obj.BoxOutline.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
            obj.Tracer.Visible = false
        end
    end
end)

-- ============================================
-- UI SETUP
-- ============================================

-- Aimbot Tab
TabAimbot:CreateToggle({Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) Settings.Aimbot.Enabled = v end})
TabAimbot:CreateToggle({Name = "Camera Lock Bypass", CurrentValue = false, Callback = function(v) Settings.Aimbot.CameraLock = v end})
TabAimbot:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) Settings.Aimbot.TeamCheck = v end})
TabAimbot:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart", "Torso"}, CurrentValue = "Head", Callback = function(v) Settings.Aimbot.AimPart = v end})
TabAimbot:CreateSlider({Name = "FOV", Range = {10, 500}, Increment = 1, CurrentValue = 100, Callback = function(v) Settings.Aimbot.FOV = v end})
TabAimbot:CreateSlider({Name = "Smoothness", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.2, Callback = function(v) Settings.Aimbot.Smoothness = v end})
TabAimbot:CreateLabel("Enable 'Camera Lock Bypass' if the aimbot isn't locking.")

-- Visuals Tab
TabVisuals:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(v) Settings.ESP.Enabled = v end})
TabVisuals:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) Settings.ESP.TeamCheck = v end})
TabVisuals:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Settings.ESP.Boxes = v end})
TabVisuals:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) Settings.ESP.Names = v end})
TabVisuals:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Settings.ESP.Distance = v end})
TabVisuals:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) Settings.ESP.Tracers = v end})
TabVisuals:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Settings.ESP.BoxColor = v end})
TabVisuals:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Settings.ESP.TextColor = v end})
TabVisuals:CreateSlider({Name = "Text Size", Range = {8, 20}, Increment = 1, CurrentValue = 13, Callback = function(v) Settings.ESP.TextSize = v end})

-- Settings Tab
TabSettings:CreateButton({Name = "Unload Script", Callback = function()
    for player, _ in pairs(EspObjects) do ClearEsp(player) end
    FOVCircle:Remove()
    RunService:UnbindFromRenderStep("AimbotUpdate")
    if Settings.Aimbot.CameraLock then
        Camera.CameraType = Enum.CameraType.Custom
    end
    Rayfield:Destroy()
end})

Rayfield:Notify("Universal Hub", "Aimbot & ESP loaded successfully!", 5)
