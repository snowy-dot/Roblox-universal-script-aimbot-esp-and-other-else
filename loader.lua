--!nocheck
-- ============================================
-- UNIVERSAL HUB V50 — NOCHECK & EXPANDED
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer

if not LP then
    return
end

local Cam = workspace.CurrentCamera

-- Diagnostic Label
local DiagGui = Instance.new("ScreenGui")
DiagGui.Name = "Diag"
local DiagLabel = Instance.new("TextLabel")
DiagLabel.Size = UDim2.new(0, 200, 0, 50)
DiagLabel.Position = UDim2.new(0, 10, 0, 10)
DiagLabel.Text = "Script Running..."
DiagLabel.Visible = true
DiagLabel.BackgroundTransparency = 0
DiagLabel.BackgroundColor3 = Color3.new(0, 0, 0)
DiagLabel.TextColor3 = Color3.new(1, 1, 1)
DiagLabel.Parent = DiagGui

pcall(function()
    DiagGui.Parent = gethui()
end)
if not DiagGui.Parent then
    pcall(function()
        DiagGui.Parent = CoreGui
    end)
end
if not DiagGui.Parent then
    DiagGui.Parent = LP:WaitForChild("PlayerGui")
end

-- State
local State = {}
State.Fly = false
State.FlySpeed = 100
State.Speed = false
State.SpeedAmt = 100
State.InfJump = false
State.HighJump = false
State.JumpAmt = 150
State.NoClip = false
State.SpinBot = false
State.SpinSpeed = 20
State.AntiRagdoll = false
State.AntiFling = false
State.ESP_Enabled = false
State.ESP_Tracers = false
State.ESP_Box = false
State.ESP_Name = true
State.ESP_Head = false
State.ESP_Distance = true
State.ESP_Health = false
State.ESP_TeamCheck = true
State.ESP_Objects = {}
State.FOV = false
State.FOVAmt = 90
State.AimbotMode = "Off"
State.AimbotToggleActive = false
State.AimbotFOV = 120
State.AimbotSmooth = 5
State.AimbotWallcheck = true
State.AimbotTeamcheck = true
State.AimbotShowFOV = true
State.SilentAim = false
State.HitboxExpander = false
State.HitboxSize = 10
State.RainbowFOV = false
State.FOVColor = Color3.fromRGB(255, 255, 255)
State.ContactFling = false
State.FlingPower = 5000
State.FlingRadius = 30
State.ClickTP = false
State.AntiAFK = false
State.Invisible = false
State.GodMode = false
State.NoGravity = false
State.BTools = false
State.ChatSpam = false
State.SpamMsg = "Get flung lol"
State.SpamRate = 1
State.Freeze = false
State.FrozenPos = nil
State.Fullbright = false
State.DiscoMode = false
State.PlayerScale = 1
State.Headless = false
State.RemoveTerrain = false
State.Connections = {}

-- ============================================
-- LOAD ORION UI
-- ============================================
local OrionLib = nil
pcall(function()
    local response = game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source')
    local func = loadstring(response)
    if func then
        OrionLib = func()
    end
end)

if not OrionLib then
    DiagLabel.Text = "Orion UI failed to load. Check HTTP."
    return
end

DiagLabel.Text = "Orion UI Loaded! Building menu..."

local WindowConfig = {
    Name = "Universal Hub V50",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "UniversalHub"
}
local Window = OrionLib:MakeWindow(WindowConfig)

local TabLocalConfig = {
    Name = "Local",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabLocal = Window:MakeTab(TabLocalConfig)

local TabCombatConfig = {
    Name = "Combat",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabCombat = Window:MakeTab(TabCombatConfig)

local TabESPConfig = {
    Name = "ESP",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabESP = Window:MakeTab(TabESPConfig)

local TabGoofyConfig = {
    Name = "Goofy",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabGoofy = Window:MakeTab(TabGoofyConfig)

local TabServerConfig = {
    Name = "Server",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabServer = Window:MakeTab(TabServerConfig)

local TabMiscConfig = {
    Name = "Misc",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
}
local TabMisc = Window:MakeTab(TabMiscConfig)

local ESPGui
local AimbotFOVCircle
local FOVStroke
local FlingVisual
local StopFly
local StartFly

local function UnloadScript()
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    State.Connections = {}
    
    pcall(function()
        RunService:UnbindFromRenderStep("HubMainLoop")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("FlyLoop")
    end)
    
    for _, obj in pairs(State.ESP_Objects) do
        if obj.Container then
            obj.Container:Destroy()
        end
    end
    State.ESP_Objects = {}
    
    if FlingVisual then
        FlingVisual:Destroy()
    end
    if AimbotFOVCircle then
        AimbotFOVCircle:Destroy()
    end
    if ESPGui then
        ESPGui:Destroy()
    end
    if DiagGui then
        DiagGui:Destroy()
    end
    
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
    
    OrionLib:Destroy()
end

-- Visuals Setup
pcall(function()
    local parent = CoreGui
    if gethui then
        parent = gethui()
    end
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "ESP_Gui"
    ESPGui.ResetOnSpawn = false
    ESPGui.IgnoreGuiInset = true
    ESPGui.Parent = parent
end)

if not ESPGui then
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "ESP_Gui"
    ESPGui.ResetOnSpawn = false
    ESPGui.IgnoreGuiInset = true
    ESPGui.Parent = LP:WaitForChild("PlayerGui")
end

AimbotFOVCircle = Instance.new("Frame")
AimbotFOVCircle.Name = "AimbotFOV"
AimbotFOVCircle.Size = UDim2.new(0, 240, 0, 240)
AimbotFOVCircle.Position = UDim2.new(0.5, -120, 0.5, -120)
AimbotFOVCircle.BackgroundTransparency = 1
AimbotFOVCircle.BorderSizePixel = 0
AimbotFOVCircle.Parent = ESPGui

FOVStroke = Instance.new("UIStroke")
FOVStroke.Parent = AimbotFOVCircle
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.5

local corner = Instance.new("UICorner")
corner.Parent = AimbotFOVCircle
corner.CornerRadius = UDim.new(0, 120)
AimbotFOVCircle.Visible = false

FlingVisual = Instance.new("Part")
FlingVisual.Shape = Enum.PartType.Ball
FlingVisual.Material = Enum.Material.ForceField
FlingVisual.Color = Color3.fromRGB(255, 0, 0)
FlingVisual.Transparency = 0.8
FlingVisual.CanCollide = false
FlingVisual.Anchored = true
FlingVisual.CastShadow = false
FlingVisual.Size = Vector3.new(State.FlingRadius * 2, State.FlingRadius * 2, State.FlingRadius * 2)
FlingVisual.Parent = nil

local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local closestDist = State.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                local isTeam = false
                if State.AimbotTeamcheck then
                    if player.Team == LP.Team then
                        isTeam = true
                    end
                end
                
                if not isTeam then
                    local head = player.Character:FindFirstChild("Head")
                    local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if head and targetHrp then
                        local screenPos, onScreen = Cam:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist < closestDist then
                                local visible = true
                                if State.AimbotWallcheck then
                                    local myHrp = nil
                                    if LP.Character then
                                        myHrp = LP.Character:FindFirstChild("HumanoidRootPart")
                                    end
                                    if myHrp then
                                        local rayParams = RaycastParams.new()
                                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                        rayParams.FilterDescendantsInstances = {LP.Character, player.Character}
                                        local result = workspace:Raycast(myHrp.Position, (head.Position - myHrp.Position).Unit * (head.Position - myHrp.Position).Magnitude, rayParams)
                                        if result then
                                            visible = false
                                        end
                                    end
                                end
                                if visible then
                                    closestDist = dist
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

StopFly = function()
    State.Fly = false
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end
    pcall(function()
        RunService:UnbindFromRenderStep("FlyLoop")
    end)
end

StartFly = function()
    local hrp = nil
    local hum = nil
    if LP.Character then
        hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        hum = LP.Character:FindFirstChildOfClass("Humanoid")
    end
    
    if not hrp or not hum then
        return
    end
    
    StopFly()
    State.Fly = true
    hum.PlatformStand = true
    
    RunService:BindToRenderStep("FlyLoop", Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Fly then
            StopFly()
            return
        end
        if not LP.Character then
            StopFly()
            return
        end
        
        local charHrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local charHum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not charHrp or not charHum then
            return
        end
        
        charHum.PlatformStand = true
        local d = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            d = d + Cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            d = d - Cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            d = d - Cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            d = d + Cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            d = d + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            d = d - Vector3.new(0, 1, 0)
        end
        
        if d.Magnitude > 0 then
            local targetVel = d.Unit * State.FlySpeed
            charHrp.AssemblyLinearVelocity = charHrp.AssemblyLinearVelocity:Lerp(targetVel, 0.5)
        else
            charHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function CreateESPForPlayer(player)
    if State.ESP_Objects[player] then
        return State.ESP_Objects[player]
    end
    
    local container = Instance.new("Frame")
    container.Parent = ESPGui
    container.Name = "ESP_" .. player.Name
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    
    local box = Instance.new("Frame")
    box.Parent = container
    box.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Parent = box
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Thickness = 1.5
    
    local tracer = Instance.new("Frame")
    tracer.Parent = container
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 1, 0, 1)
    tracer.Visible = false
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Parent = container
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.AnchorPoint = Vector2.new(0.5, 1)
    nameLbl.Visible = false
    
    local distLbl = Instance.new("TextLabel")
    distLbl.Parent = container
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.AnchorPoint = Vector2.new(0.5, 1)
    distLbl.Visible = false
    
    local healthLbl = Instance.new("TextLabel")
    healthLbl.Parent = container
    healthLbl.BackgroundTransparency = 1
    healthLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    healthLbl.Font = Enum.Font.Gotham
    healthLbl.TextSize = 10
    healthLbl.AnchorPoint = Vector2.new(0.5, 1)
    healthLbl.Visible = false
    
    local headDot = Instance.new("Frame")
    headDot.Parent = container
    headDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    headDot.Size = UDim2.fromOffset(8, 8)
    headDot.BorderSizePixel = 0
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Visible = false
    
    local hc = Instance.new("UICorner")
    hc.Parent = headDot
    hc.CornerRadius = UDim.new(0, 4)
    
    local obj = {
        Container = container,
        Box = box,
        Tracer = tracer,
        Name = nameLbl,
        Dist = distLbl,
        Health = healthLbl,
        HeadDot = headDot,
        BoxStroke = boxStroke
    }
    State.ESP_Objects[player] = obj
    return obj
end

local function RenderESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            if State.ESP_Enabled then
                if player.Character then
                    local isTeam = false
                    if State.ESP_TeamCheck then
                        if player.Team == LP.Team then
                            isTeam = true
                        end
                    end
                    
                    if not isTeam then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local head = player.Character:FindFirstChild("Head")
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        
                        if hrp and head then
                            local headScreen = Cam:WorldToViewportPoint(head.Position)
                            if headScreen.Z > 0 then
                                local esp = CreateESPForPlayer(player)
                                if esp then
                                    esp.Container.Visible = true
                                    if State.ESP_Box then
                                        local legPos = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                                        local height = math.abs(headScreen.Y - legPos.Y)
                                        local width = height / 2
                                        esp.Box.Position = UDim2.fromOffset(headScreen.X - width/2, headScreen.Y)
                                        esp.Box.Size = UDim2.fromOffset(width, height)
                                        esp.Box.Visible = true
                                    else
                                        esp.Box.Visible = false
                                    end
                                    if State.ESP_Tracers then
                                        local p1 = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                                        local p2 = Vector2.new(headScreen.X, headScreen.Y)
                                        local dist = (p2 - p1).Magnitude
                                        local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
                                        esp.Tracer.Position = UDim2.fromOffset((p1.X + p2.X)/2, (p1.Y + p2.Y)/2)
                                        esp.Tracer.Size = UDim2.fromOffset(dist, 1)
                                        esp.Tracer.Rotation = math.deg(angle)
                                        esp.Tracer.Visible = true
                                    else
                                        esp.Tracer.Visible = false
                                    end
                                    esp.HeadDot.Visible = State.ESP_Head
                                    if State.ESP_Head then
                                        esp.HeadDot.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
                                    end
                                    
                                    local textY = headScreen.Y - 5
                                    if State.ESP_Name then
                                        esp.Name.Position = UDim2.fromOffset(headScreen.X, textY)
                                        esp.Name.Text = player.Name
                                        esp.Name.Visible = true
                                        textY = textY - 16
                                    else
                                        esp.Name.Visible = false
                                    end
                                    if State.ESP_Distance then
                                        local myHrp = nil
                                        if LP.Character then
                                            myHrp = LP.Character:FindFirstChild("HumanoidRootPart")
                                        end
                                        local dist = 0
                                        if myHrp then
                                            dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
                                        end
                                        esp.Dist.Position = UDim2.fromOffset(headScreen.X, textY)
                                        esp.Dist.Text = dist .. "m"
                                        esp.Dist.Visible = true
                                        textY = textY - 14
                                    else
                                        esp.Dist.Visible = false
                                    end
                                    if State.ESP_Health then
                                        if hum then
                                            esp.Health.Position = UDim2.fromOffset(headScreen.X, textY)
                                            esp.Health.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                                            esp.Health.Visible = true
                                        else
                                            esp.Health.Visible = false
                                        end
                                    else
                                        esp.Health.Visible = false
                                    end
                                end
                            elseif State.ESP_Objects[player] then
                                State.ESP_Objects[player].Container.Visible = false
                            end
                        elseif State.ESP_Objects[player] then
                            State.ESP_Objects[player].Container.Visible = false
                        end
                    else
                        if State.ESP_Objects[player] then
                            State.ESP_Objects[player].Container.Visible = false
                        end
                    end
                end
            end
        elseif State.ESP_Objects[player] then
            State.ESP_Objects[player].Container.Visible = false
        end
    end
end

-- ============================================
-- BUILD UI ELEMENTS (ORION EXPANDED)
-- ============================================
TabLocal:AddSection("Movement")

local FlyToggleConfig = {
    Name = "Fly",
    Default = false,
    Callback = function(v)
        if v then
            StartFly()
        else
            StopFly()
        end
    end
}
TabLocal:AddToggle(FlyToggleConfig)

local FlySpeedConfig = {
    Name = "Fly Speed",
    Min = 1,
    Max = 500,
    Default = 100,
    Increment = 1,
    Callback = function(v)
        State.FlySpeed = v
    end
}
TabLocal:AddSlider(FlySpeedConfig)

local SpeedToggleConfig = {
    Name = "Speed",
    Default = false,
    Callback = function(v)
        State.Speed = v
    end
}
TabLocal:AddToggle(SpeedToggleConfig)

local SpeedAmtConfig = {
    Name = "Speed Amount",
    Min = 16,
    Max = 500,
    Default = 100,
    Increment = 1,
    Callback = function(v)
        State.SpeedAmt = v
    end
}
TabLocal:AddSlider(SpeedAmtConfig)

local InfJumpConfig = {
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v)
        State.InfJump = v
    end
}
TabLocal:AddToggle(InfJumpConfig)

local HighJumpConfig = {
    Name = "High Jump",
    Default = false,
    Callback = function(v)
        State.HighJump = v
    end
}
TabLocal:AddToggle(HighJumpConfig)

local JumpPowConfig = {
    Name = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 150,
    Increment = 1,
    Callback = function(v)
        State.JumpAmt = v
    end
}
TabLocal:AddSlider(JumpPowConfig)

local NoClipConfig = {
    Name = "NoClip",
    Default = false,
    Callback = function(v)
        State.NoClip = v
    end
}
TabLocal:AddToggle(NoClipConfig)

local SpinBotConfig = {
    Name = "Spin Bot",
    Default = false,
    Callback = function(v)
        State.SpinBot = v
    end
}
TabLocal:AddToggle(SpinBotConfig)

local SpinSpeedConfig = {
    Name = "Spin Speed",
    Min = 1,
    Max = 100,
    Default = 20,
    Increment = 1,
    Callback = function(v)
        State.SpinSpeed = v
    end
}
TabLocal:AddSlider(SpinSpeedConfig)

TabLocal:AddSection("Character & Protection")

local AntiRagdollConfig = {
    Name = "Anti Ragdoll",
    Default = false,
    Callback = function(v)
        State.AntiRagdoll = v
    end
}
TabLocal:AddToggle(AntiRagdollConfig)

local AntiFlingConfig = {
    Name = "Advanced Anti Fling",
    Default = false,
    Callback = function(v)
        State.AntiFling = v
    end
}
TabLocal:AddToggle(AntiFlingConfig)

local GhostInvisConfig = {
    Name = "Ghost Invisible",
    Default = false,
    Callback = function(v)
        State.Invisible = v
    end
}
TabLocal:AddToggle(GhostInvisConfig)

local GodModeConfig = {
    Name = "God Mode",
    Default = false,
    Callback = function(v)
        State.GodMode = v
        if v then
            if LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.MaxHealth = 999999
                    hum.Health = 999999
                end
            end
        end
    end
}
TabLocal:AddToggle(GodModeConfig)

local NoGravConfig = {
    Name = "No Gravity",
    Default = false,
    Callback = function(v)
        State.NoGravity = v
    end
}
TabLocal:AddToggle(NoGravConfig)

local FreezeConfig = {
    Name = "Freeze Position",
    Default = false,
    Callback = function(v)
        State.Freeze = v
    end
}
TabLocal:AddToggle(FreezeConfig)

TabCombat:AddSection("Aimbot & Silent Aim")

local AimbotModeConfig = {
    Name = "Aimbot Mode",
    Default = "Off",
    Options = {"Off", "Always", "Hold (Right Mouse)", "Toggle (Left Mouse)"},
    Callback = function(Option)
        State.AimbotMode = Option
    end
}
TabCombat:AddDropdown(AimbotModeConfig)

local SilentAimConfig = {
    Name = "Silent Aim (Hit Hack)",
    Default = false,
    Callback = function(v)
        State.SilentAim = v
    end
}
TabCombat:AddToggle(SilentAimConfig)

local AimbotFOVConfig = {
    Name = "Aimbot FOV",
    Min = 10,
    Max = 360,
    Default = 120,
    Increment = 1,
    Callback = function(v)
        State.AimbotFOV = v
    end
}
TabCombat:AddSlider(AimbotFOVConfig)

local AimbotSmoothConfig = {
    Name = "Aimbot Smooth (1 = Fast)",
    Min = 1,
    Max = 20,
    Default = 5,
    Increment = 1,
    Callback = function(v)
        State.AimbotSmooth = v
    end
}
TabCombat:AddSlider(AimbotSmoothConfig)

local WallCheckConfig = {
    Name = "Wall Check",
    Default = true,
    Callback = function(v)
        State.AimbotWallcheck = v
    end
}
TabCombat:AddToggle(WallCheckConfig)

local TeamCheckConfig = {
    Name = "Team Check",
    Default = true,
    Callback = function(v)
        State.AimbotTeamcheck = v
    end
}
TabCombat:AddToggle(TeamCheckConfig)

TabCombat:AddSection("Visuals & Hitboxes")

local ShowFOVConfig = {
    Name = "Show FOV Circle",
    Default = true,
    Callback = function(v)
        State.AimbotShowFOV = v
    end
}
TabCombat:AddToggle(ShowFOVConfig)

local RainbowFOVConfig = {
    Name = "Rainbow FOV",
    Default = false,
    Callback = function(v)
        State.RainbowFOV = v
    end
}
TabCombat:AddToggle(RainbowFOVConfig)

local FOVColorConfig = {
    Name = "Aimbot FOV Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        State.FOVColor = color
    end
}
TabCombat:AddColorpicker(FOVColorConfig)

local HitboxExpConfig = {
    Name = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        State.HitboxExpander = v
    end
}
TabCombat:AddToggle(HitboxExpConfig)

local HitboxSizeConfig = {
    Name = "Hitbox Size",
    Min = 1,
    Max = 50,
    Default = 10,
    Increment = 1,
    Callback = function(v)
        State.HitboxSize = v
    end
}
TabCombat:AddSlider(HitboxSizeConfig)

TabCombat:AddSection("Fling")

local ContactFlingConfig = {
    Name = "Contact Fling",
    Default = false,
    Callback = function(v)
        State.ContactFling = v
    end
}
TabCombat:AddToggle(ContactFlingConfig)

local ShowFlingConfig = {
    Name = "Show Fling Radius",
    Default = false,
    Callback = function(v)
        if v then
            FlingVisual.Parent = workspace
        else
            FlingVisual.Parent = nil
        end
    end
}
TabCombat:AddToggle(ShowFlingConfig)

local FlingPowerConfig = {
    Name = "Fling Power",
    Min = 100,
    Max = 50000,
    Default = 5000,
    Increment = 100,
    Callback = function(v)
        State.FlingPower = v
    end
}
TabCombat:AddSlider(FlingPowerConfig)

local FlingRadiusConfig = {
    Name = "Fling Radius",
    Min = 5,
    Max = 100,
    Default = 30,
    Increment = 1,
    Callback = function(v)
        State.FlingRadius = v
        FlingVisual.Size = Vector3.new(v * 2, v * 2, v * 2)
    end
}
TabCombat:AddSlider(FlingRadiusConfig)

TabESP:AddSection("ESP Options")

local ESPEnableConfig = {
    Name = "Enabled",
    Default = false,
    Callback = function(v)
        State.ESP_Enabled = v
    end
}
TabESP:AddToggle(ESPEnableConfig)

local ESPBoxConfig = {
    Name = "Box ESP",
    Default = false,
    Callback = function(v)
        State.ESP_Box = v
    end
}
TabESP:AddToggle(ESPBoxConfig)

local ESPTracerConfig = {
    Name = "Tracers",
    Default = false,
    Callback = function(v)
        State.ESP_Tracers = v
    end
}
TabESP:AddToggle(ESPTracerConfig)

local ESPHeadConfig = {
    Name = "Head Dot",
    Default = false,
    Callback = function(v)
        State.ESP_Head = v
    end
}
TabESP:AddToggle(ESPHeadConfig)

local ESPNameConfig = {
    Name = "Name",
    Default = true,
    Callback = function(v)
        State.ESP_Name = v
    end
}
TabESP:AddToggle(ESPNameConfig)

local ESPDistConfig = {
    Name = "Distance",
    Default = true,
    Callback = function(v)
        State.ESP_Distance = v
    end
}
TabESP:AddToggle(ESPDistConfig)

local ESPHealthConfig = {
    Name = "Health",
    Default = false,
    Callback = function(v)
        State.ESP_Health = v
    end
}
TabESP:AddToggle(ESPHealthConfig)

local ESPTeamConfig = {
    Name = "Team Check",
    Default = true,
    Callback = function(v)
        State.ESP_TeamCheck = v
    end
}
TabESP:AddToggle(ESPTeamConfig)

TabESP:AddSection("ESP Colors")

local BoxColorConfig = {
    Name = "Box Color",
    Default = Color3.fromRGB(255, 50, 50),
    Callback = function(color)
        for _, obj in pairs(State.ESP_Objects) do
            obj.BoxStroke.Color = color
        end
    end
}
TabESP:AddColorpicker(BoxColorConfig)

local TracerColorConfig = {
    Name = "Tracer Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        for _, obj in pairs(State.ESP_Objects) do
            obj.Tracer.BackgroundColor3 = color
        end
    end
}
TabESP:AddColorpicker(TracerColorConfig)

local TextColorConfig = {
    Name = "Text Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        for _, obj in pairs(State.ESP_Objects) do
            obj.Name.TextColor3 = color
        end
    end
}
TabESP:AddColorpicker(TextColorConfig)

TabGoofy:AddSection("Chaos")

local DiscoConfig = {
    Name = "Disco Mode",
    Default = false,
    Callback = function(v)
        State.DiscoMode = v
    end
}
TabGoofy:AddToggle(DiscoConfig)

local HeadlessConfig = {
    Name = "Headless (Local)",
    Default = false,
    Callback = function(v)
        State.Headless = v
    end
}
TabGoofy:AddToggle(HeadlessConfig)

local RemoveTerrConfig = {
    Name = "Remove Terrain",
    Default = false,
    Callback = function(v)
        State.RemoveTerrain = v
        if v then
            pcall(function()
                workspace:FindFirstChildOfClass("Terrain"):Clear()
            end)
        end
    end
}
TabGoofy:AddToggle(RemoveTerrConfig)

local FlingAllConfig = {
    Name = "Fling Everyone Nearby",
    Callback = function()
        if not LP.Character then
            return
        end
        local myHrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            return
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if p.Character then
                    local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if tHrp then
                        if (tHrp.Position - myHrp.Position).Magnitude < 50 then
                            pcall(function()
                                tHrp.AssemblyLinearVelocity = (tHrp.Position - myHrp.Position).Unit * 9999 + Vector3.new(0, 5000, 0)
                            end)
                        end
                    end
                end
            end
        end
    end
}
TabGoofy:AddButton(FlingAllConfig)

TabGoofy:AddSection("Size Modifier")

local ScaleConfig = {
    Name = "Player Scale (1 = Normal)",
    Min = 0.1,
    Max = 10,
    Default = 1,
    Increment = 0.1,
    Callback = function(val)
        State.PlayerScale = val
    end
}
TabGoofy:AddSlider(ScaleConfig)

TabServer:AddSection("Server Utilities")

local RejoinConfig = {
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end
}
TabServer:AddButton(RejoinConfig)

local HopConfig = {
    Name = "Server Hop (New Server)",
    Callback = function()
        local baseUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(baseUrl))
        end)
        if success then
            if response then
                if response.data then
                    for _, server in pairs(response.data) do
                        if server.playing < server.maxPlayers then
                            if server.id ~= game.JobId then
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
}
TabServer:AddButton(HopConfig)

TabMisc:AddSection("Utility")

local AntiAFKConfig = {
    Name = "Anti AFK",
    Default = false,
    Callback = function(v)
        State.AntiAFK = v
    end
}
TabMisc:AddToggle(AntiAFKConfig)

local BToolsConfig = {
    Name = "BTools",
    Default = false,
    Callback = function(v)
        State.BTools = v
    end
}
TabMisc:AddToggle(BToolsConfig)

local ChatSpamConfig = {
    Name = "Chat Spam",
    Default = false,
    Callback = function(v)
        State.ChatSpam = v
    end
}
TabMisc:AddToggle(ChatSpamConfig)

local SpamMsgConfig = {
    Name = "Spam Msg",
    Default = "Get flung lol",
    TextDisappear = false,
    Callback = function(v)
        State.SpamMsg = v
    end
}
TabMisc:AddTextbox(SpamMsgConfig)

local SpamRateConfig = {
    Name = "Spam Rate",
    Min = 1,
    Max = 10,
    Default = 1,
    Increment = 1,
    Callback = function(v)
        State.SpamRate = v
    end
}
TabMisc:AddSlider(SpamRateConfig)

TabMisc:AddSection("Danger Zone")

local KillSwitchConfig = {
    Name = "Kill Switch / Unload Script",
    Callback = function()
        UnloadScript()
    end
}
TabMisc:AddButton(KillSwitchConfig)

-- Safe Hooks
pcall(function()
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local isCaller = false
        if checkcaller then
            isCaller = checkcaller()
        end
        
        if not isCaller then
            if State.GodMode then
                if self then
                    if self:IsA("Humanoid") then
                        if LP.Character then
                            if self == LP.Character:FindFirstChildOfClass("Humanoid") then
                                if method == "TakeDamage" then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if not isCaller then
            if State.SilentAim then
                if self == workspace then
                    if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
                        local target = GetClosestPlayerToMouse()
                        if target then
                            if target.Character then
                                if target.Character:FindFirstChild("Head") then
                                    local args = {...}
                                    local origin = args[1].Origin
                                    local direction = (target.Character.Head.Position - origin)
                                    args[1] = Ray.new(origin, direction)
                                    return OldNamecall(self, unpack(args))
                                end
                            end
                        end
                    elseif method == "Raycast" then
                        local target = GetClosestPlayerToMouse()
                        if target then
                            if target.Character then
                                if target.Character:FindFirstChild("Head") then
                                    local args = {...}
                                    local origin = args[1]
                                    local direction = (target.Character.Head.Position - origin)
                                    args[2] = direction
                                    return OldNamecall(self, unpack(args))
                                end
                            end
                        end
                    end
                end
            end
        end
        return OldNamecall(self, ...)
    end)
end)

-- Main Loops
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if State.ClickTP then
            if not gpe then
                local hrp = nil
                if LP.Character then
                    hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                end
                if hrp then
                    local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
                    local ray = Cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {LP.Character}
                    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                    if result then
                        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end
    
    if State.AimbotMode == "Toggle (Left Mouse)" then
        if not gpe then
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                State.AimbotToggleActive = not State.AimbotToggleActive
            end
        end
    end
end))

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end))

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            if State.Speed then
                pcall(function()
                    hum.WalkSpeed = State.SpeedAmt
                end)
            else
                pcall(function()
                    hum.WalkSpeed = 16
                end)
            end
            if State.HighJump then
                pcall(function()
                    hum.JumpPower = State.JumpAmt
                end)
            else
                pcall(function()
                    hum.JumpPower = 50
                end)
            end
            if State.GodMode then
                pcall(function()
                    if hum.MaxHealth < 999999 then
                        hum.MaxHealth = 999999
                    end
                    if hum.Health < 999999 then
                        hum.Health = 999999
                    end
                end)
            end
            if State.AntiRagdoll then
                if hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
        if State.NoClip then
            for _, part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                local isMalicious = false
                if v:IsA("BodyVelocity") then
                    isMalicious = true
                end
                if v:IsA("BodyAngularVelocity") then
                    isMalicious = true
                end
                if v:IsA("BodyForce") then
                    isMalicious = true
                end
                if v:IsA("BodyThrust") then
                    isMalicious = true
                end
                if v:IsA("RocketPropulsion") then
                    isMalicious = true
                end
                
                if isMalicious then
                    if v.Name ~= "NoGrav_BV" then
                        if v.Name ~= "FlyBV" then
                            v:Destroy()
                        end
                    end
                end
            end
            if State.AntiFling then
                if hrp.AssemblyLinearVelocity.Magnitude > 1000 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                end
                if hrp.AssemblyAngularVelocity.Magnitude > 1000 then
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end
            end
            if State.ContactFling then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP then
                        if player.Character then
                            local tHrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if tHrp then
                                if tHrp:IsA("BasePart") then
                                    local dist = (tHrp.Position - hrp.Position).Magnitude
                                    if dist < State.FlingRadius then
                                        pcall(function()
                                            tHrp.AssemblyLinearVelocity = (tHrp.Position - hrp.Position).Unit * State.FlingPower + Vector3.new(0, State.FlingPower * 0.5, 0)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if State.Invisible then
                for _, part in pairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Name ~= "HumanoidRootPart" then
                            part.LocalTransparencyModifier = 1
                            part.Transparency = 1
                        end
                    elseif part:IsA("Decal") then
                        part.Transparency = 1
                    end
                end
            else
                for _, part in pairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Name ~= "HumanoidRootPart" then
                            part.LocalTransparencyModifier = 0
                            if part.Name ~= "Head" then
                                part.Transparency = 0
                            end
                        end
                    elseif part:IsA("Decal") then
                        part.Transparency = 0
                    end
                end
            end
            local targetScale = State.PlayerScale
            for _, v in pairs(LP.Character:GetDescendants()) do
                local isScale = false
                if v:IsA("BodyBackScale") then
                    isScale = true
                end
                if v:IsA("BodyDepthScale") then
                    isScale = true
                end
                if v:IsA("BodyHeightScale") then
                    isScale = true
                end
                if v:IsA("BodyWidthScale") then
                    isScale = true
                end
                if v:IsA("HeadScale") then
                    isScale = true
                end
                
                if isScale then
                    pcall(function()
                        if v.Value ~= targetScale then
                            v.Value = targetScale
                        end
                    end)
                end
            end
        end
    end
end))

RunService:BindToRenderStep("HubMainLoop", Enum.RenderPriority.Camera.Value + 1, function()
    if not LP.Character then
        return
    end
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        local existing = hrp:FindFirstChild("NoGrav_BV")
        if State.NoGravity then
            if not existing then
                local bv = Instance.new("BodyVelocity")
                bv.Parent = hrp
                bv.Name = "NoGrav_BV"
                bv.MaxForce = Vector3.new(0, math.huge, 0)
                bv.Velocity = Vector3.new(0, 0, 0)
            end
        else
            if existing then
                existing:Destroy()
            end
        end
        if State.SpinBot then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0)
        end
        if State.Freeze then
            if not State.FrozenPos then
                State.FrozenPos = hrp.Position
            end
            hrp.CFrame = CFrame.new(State.FrozenPos)
        else
            State.FrozenPos = nil
        end
        if State.Headless then
            local head = LP.Character:FindFirstChild("Head")
            if head then
                for _, mesh in pairs(head:GetDescendants()) do
                    local isMesh = false
                    if mesh:IsA("SpecialMesh") then
                        isMesh = true
                    end
                    if mesh:IsA("Decal") then
                        isMesh = true
                    end
                    if isMesh then
                        mesh.Transparency = 1
                    end
                end
                head.Transparency = 1
            end
        end
    end
    if State.FOV then
        Cam.FieldOfView = State.FOVAmt
    end
    if State.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end
    if State.DiscoMode then
        Lighting.Ambient = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        Lighting.OutdoorAmbient = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            if player.Character then
                local tHrp = player.Character:FindFirstChild("HumanoidRootPart")
                if tHrp then
                    if State.HitboxExpander then
                        tHrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                        tHrp.Transparency = 0.5
                        tHrp.CanCollide = false
                        tHrp.BrickColor = BrickColor.new("Bright red")
                    else
                        if tHrp.Size.X > 2 then
                            tHrp.Size = Vector3.new(2, 2, 1)
                            tHrp.Transparency = 1
                        end
                    end
                end
            end
        end
    end
    RenderESP()
    if AimbotFOVCircle then
        if State.AimbotMode ~= "Off" or State.SilentAim then
            if State.AimbotShowFOV then
                AimbotFOVCircle.Visible = true
                local size = State.AimbotFOV * 2
                AimbotFOVCircle.Size = UDim2.fromOffset(size, size)
                AimbotFOVCircle.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
                if State.RainbowFOV then
                    local hue = tick() % 5 / 5
                    FOVStroke.Color = Color3.fromHSV(hue, 1, 1)
                else
                    FOVStroke.Color = State.FOVColor
                end
            else
                AimbotFOVCircle.Visible = false
            end
        else
            AimbotFOVCircle.Visible = false
        end
    end
    if FlingVisual then
        if FlingVisual.Parent then
            if hrp then
                FlingVisual.Position = hrp.Position
            end
        end
    end
    local aimbotActive = false
    if State.AimbotMode == "Always" then
        aimbotActive = true
    elseif State.AimbotMode == "Hold (Right Mouse)" then
        aimbotActive = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif State.AimbotMode == "Toggle (Left Mouse)" then
        aimbotActive = State.AimbotToggleActive
    end
    if aimbotActive then
        local target = GetClosestPlayerToMouse()
        if target then
            if target.Character then
                if target.Character:FindFirstChild("Head") then
                    local targetHead = target.Character.Head
                    local smoothFactor = 1 / State.AimbotSmooth
                    local targetCFrame = CFrame.lookAt(Cam.CFrame.Position, targetHead.Position)
                    Cam.CFrame = Cam.CFrame:Lerp(targetCFrame, smoothFactor)
                end
            end
        end
    end
end)

-- Background Loops
task.spawn(function()
    while task.wait(60) do
        if State.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

task.spawn(function()
    while task.wait(State.SpamRate) do
        if State.ChatSpam then
            pcall(function()
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(State.SpamMsg, "All")
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if State.BTools then
            if LP.Character then
                local backpack = LP:FindFirstChild("Backpack")
                if backpack then
                    if not backpack:FindFirstChild("BTools_Hammer") then
                        pcall(function()
                            local hammer = Instance.new("HopperBin")
                            hammer.BinType = Enum.BinType.Hammer
                            hammer.Name = "BTools_Hammer"
                            hammer.Parent = backpack
                        end)
                    end
                end
            end
        end
    end
end)

OrionLib:Init()
DiagLabel.Text = "Universal Hub V50 Loaded!"
task.wait(3)
DiagGui:Destroy()
