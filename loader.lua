--!nocheck
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Linoria UI & Managers
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Source/main/linoria/Libraries/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Source/main/linoria/Libraries/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Source/main/linoria/Libraries/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Universal ESP",
    Footer = "Linoria Edition",
    NotifySide = "Right",
    ShowCustomCursor = true
})

local Tabs = {
    Visuals = Window:CreateTab("Visuals", 1),
    Settings = Window:CreateTab("Settings", 2)
}

-- ============================================
-- ESP SETTINGS
-- ============================================
local Settings = {
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

local VisualsGroup = Tabs.Visuals:CreateLeftGroupbox("Player ESP")
local WorldGroup = Tabs.Visuals:CreateRightGroupbox("World Visuals")

VisualsGroup:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Enable",
    Callback = function(Value) Settings.Enabled = Value end
})

VisualsGroup:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "ESP_TeamCheck",
    Callback = function(Value) Settings.TeamCheck = Value end
})

VisualsGroup:CreateToggle({
    Name = "Boxes",
    CurrentValue = true,
    Flag = "ESP_Boxes",
    Callback = function(Value) Settings.Boxes = Value end
})

VisualsGroup:CreateToggle({
    Name = "Names",
    CurrentValue = true,
    Flag = "ESP_Names",
    Callback = function(Value) Settings.Names = Value end
})

VisualsGroup:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "ESP_Distance",
    Callback = function(Value) Settings.Distance = Value end
})

VisualsGroup:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "ESP_Tracers",
    Callback = function(Value) Settings.Tracers = Value end
})

VisualsGroup:CreateColorPicker({
    Name = "Box Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) Settings.BoxColor = Value end
})

VisualsGroup:CreateColorPicker({
    Name = "Text Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value) Settings.TextColor = Value end
})

VisualsGroup:CreateSlider({
    Name = "Text Size",
    Range = {8, 20},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 13,
    Callback = function(Value) Settings.TextSize = Value end
})

WorldGroup:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "World_Fullbright",
    Callback = function(Value)
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
        end
    end
})

WorldGroup:CreateSlider({
    Name = "Camera FOV",
    Range = {40, 120},
    Increment = 1,
    Suffix = "FOV",
    CurrentValue = 70,
    Callback = function(Value)
        Camera.FieldOfView = Value
    end
})

-- ============================================
-- ESP LOGIC (Drawing API)
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
    if Settings.Enabled then
        for player, obj in pairs(EspObjects) do
            local char = player.Character
            if char and player ~= LocalPlayer then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChild("Humanoid")
                if hrp and head and hum and hum.Health > 0 then
                    local isTeammate = false
                    if Settings.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then isTeammate = true end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen and not isTeammate then
                        local headPos = Camera:WorldToViewportPoint(head.Position)
                        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 2
                        
                        if Settings.Boxes then
                            obj.Box.Visible = true
                            obj.BoxOutline.Visible = true
                            obj.Box.Size = Vector2.new(width, height)
                            obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                            obj.Box.Color = Settings.BoxColor
                            obj.BoxOutline.Size = obj.Box.Size
                            obj.BoxOutline.Position = obj.Box.Position
                        else
                            obj.Box.Visible = false
                            obj.BoxOutline.Visible = false
                        end
                        
                        if Settings.Names then
                            obj.Name.Visible = true
                            obj.Name.Text = player.DisplayName
                            obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 16)
                            obj.Name.Color = Settings.TextColor
                            obj.Name.Size = Settings.TextSize
                        else
                            obj.Name.Visible = false
                        end
                        
                        if Settings.Distance then
                            obj.Distance.Visible = true
                            local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                            obj.Distance.Text = tostring(dist) .. " studs"
                            obj.Distance.Position = Vector2.new(headPos.X, legPos.Y)
                            obj.Distance.Color = Settings.TextColor
                            obj.Distance.Size = Settings.TextSize
                        else
                            obj.Distance.Visible = false
                        end
                        
                        if Settings.Tracers then
                            obj.Tracer.Visible = true
                            obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            obj.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                            obj.Tracer.Color = Settings.TracerColor
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
-- SETTINGS TAB SETUP (Matches your image)
-- ============================================
local SettingsGroup = Tabs.Settings:CreateLeftGroupbox("Config")
local ThemeGroup = Tabs.Settings:CreateRightGroupbox("Custom Theme")

-- Config Manager
SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(SettingsGroup)

-- Theme Manager
ThemeManager:SetLibrary(Library)
ThemeManager:BuildThemeSection(ThemeGroup)

-- Load saved settings
SaveManager:LoadAutoloadConfig()
