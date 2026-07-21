-- ============================================
-- UNIVERSAL HUB V52 — RAYFIELD (CLEAN BUILD)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

if not LP then return end
local Cam = workspace.CurrentCamera

-- ============================================
-- LOAD RAYFIELD UI
-- ============================================
local Rayfield = nil
pcall(function() Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)
if not Rayfield then
    pcall(function() Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))() end)
end

if not Rayfield then
    local g = Instance.new("ScreenGui")
    local f = Instance.new("Frame", g)
    f.Size = UDim2.new(0, 300, 0, 100)
    f.Position = UDim2.new(0.5, -150, 0.5, -50)
    f.BackgroundColor3 = Color3.new(0,0,0)
    f.BackgroundTransparency = 0.2
    
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,0,1,0)
    t.Text = "Rayfield UI failed to load.\nCheck your internet or executor."
    t.TextColor3 = Color3.new(1,1,1)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    
    pcall(function() g.Parent = gethui() end)
    if not g.Parent then pcall(function() g.Parent = CoreGui end) end
    if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
    return
end

-- ============================================
-- STATE
-- ============================================
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
-- UI SETUP
-- ============================================
local WindowConfig = {
    Name = "Universal Hub V52",
    LoadingTitle = "Universal Hub",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
}
local Window = Rayfield:CreateWindow(WindowConfig)

local TabLocal = Window:CreateTab("Local", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabESP = Window:CreateTab("ESP", 4483362458)
local TabGoofy = Window:CreateTab("Goofy", 4483362458)
local TabServer = Window:CreateTab("Server", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

local ESPGui
local AimbotFOVCircle
local FOVStroke
local FlingVisual
local StopFly
local StartFly

local function UnloadScript()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    
    pcall(function() RunService:UnbindFromRenderStep("HubMainLoop") end)
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
    
    for _, obj in pairs(State.ESP_Objects) do
        if obj.Container then obj.Container:Destroy() end
    end
    State.ESP_Objects = {}
    
    if FlingVisual then FlingVisual:Destroy() end
    if AimbotFOVCircle then AimbotFOVCircle:Destroy() end
    if ESPGui then ESPGui:Destroy() end
    
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
    Rayfield:Destroy()
end

-- Visuals Setup
pcall(function()
    local parent = CoreGui
    if gethui then parent = gethui() end
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

FOVStroke = Instance.new("UIStroke", AimbotFOVCircle)
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.5

local corner = Instance.new("UICorner", AimbotFOVCircle)
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

-- ============================================
-- LOGIC & FUNCTIONS
-- ============================================
local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local closestDist = State.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local isTeam = State.AimbotTeamcheck and player.Team == LP.Team
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
                                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if myHrp then
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    rayParams.FilterDescendantsInstances = {LP.Character, player.Character}
                                    local result = workspace:Raycast(myHrp.Position, (head.Position - myHrp.Position).Unit * (head.Position - myHrp.Position).Magnitude, rayParams)
                                    if result then visible = false end
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
    return closestPlayer
end

StopFly = function()
    State.Fly = false
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    pcall(function() RunService:UnbindFromRenderStep("FlyLoop") end)
end

StartFly = function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    StopFly()
    State.Fly = true
    hum.PlatformStand = true
    
    RunService:BindToRenderStep("FlyLoop", Enum.RenderPriority.Camera.Value + 1, function()
        if not State.Fly or not LP.Character then
            StopFly()
            return
        end
        local charHrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local charHum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not charHrp or not charHum then return end
        
        charHum.PlatformStand = true
        local d = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
        
        if d.Magnitude > 0 then
            charHrp.AssemblyLinearVelocity = d.Unit * State.FlySpeed
        else
            charHrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function CreateESPForPlayer(player)
    if State.ESP_Objects[player] then return State.ESP_Objects[player] end
    local container = Instance.new("Frame", ESPGui)
    container.Name = "ESP_" .. player.Name
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    
    local box = Instance.new("Frame", container)
    box.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = Color3.fromRGB(255, 50, 50)
    boxStroke.Thickness = 1.5
    
    local tracer = Instance.new("Frame", container)
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.Size = UDim2.new(0, 1, 0, 1)
    tracer.Visible = false
    
    local nameLbl = Instance.new("TextLabel", container)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.AnchorPoint = Vector2.new(0.5, 1)
    nameLbl.Visible = false
    
    local distLbl = Instance.new("TextLabel", container)
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.AnchorPoint = Vector2.new(0.5, 1)
    distLbl.Visible = false
    
    local healthLbl = Instance.new("TextLabel", container)
    healthLbl.BackgroundTransparency = 1
    healthLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    healthLbl.Font = Enum.Font.Gotham
    healthLbl.TextSize = 10
    healthLbl.AnchorPoint = Vector2.new(0.5, 1)
    healthLbl.Visible = false
    
    local headDot = Instance.new("Frame", container)
    headDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    headDot.Size = UDim2.fromOffset(8, 8)
    headDot.BorderSizePixel = 0
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Visible = false
    local hc = Instance.new("UICorner", headDot); hc.CornerRadius = UDim.new(0, 4)
    
    local obj = {Container = container, Box = box, Tracer = tracer, Name = nameLbl, Dist = distLbl, Health = healthLbl, HeadDot = headDot, BoxStroke = boxStroke}
    State.ESP_Objects[player] = obj
    return obj
end

local function RenderESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and State.ESP_Enabled and player.Character then
            local isTeam = State.ESP_TeamCheck and player.Team == LP.Team
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
                                if height < 10 then height = 10 end
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
                            if State.ESP_Head then esp.HeadDot.Position = UDim2.fromOffset(headScreen.X, headScreen.Y) end
                            
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
                                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                                esp.Dist.Position = UDim2.fromOffset(headScreen.X, textY)
                                esp.Dist.Text = dist .. "m"
                                esp.Dist.Visible = true
                                textY = textY - 14
                            else
                                esp.Dist.Visible = false
                            end
                            if State.ESP_Health and hum then
                                esp.Health.Position = UDim2.fromOffset(headScreen.X, textY)
                                esp.Health.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                                esp.Health.Visible = true
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
                if State.ESP_Objects[player] then State.ESP_Objects[player].Container.Visible = false end
            end
        elseif State.ESP_Objects[player] then
            State.ESP_Objects[player].Container.Visible = false
        end
    end
end

-- ============================================
-- BUILD UI ELEMENTS
-- ============================================
TabLocal:CreateSection("Movement")
TabLocal:CreateToggle({Name = "Fly", CurrentValue = false, Callback = function(v) if v then StartFly() else StopFly() end end})
TabLocal:CreateSlider({Name = "Fly Speed", Range = {1, 500}, Increment = 1, CurrentValue = 100, Callback = function(v) State.FlySpeed = v end})
TabLocal:CreateToggle({Name = "Speed", CurrentValue = false, Callback = function(v) State.Speed = v end})
TabLocal:CreateSlider({Name = "Speed Amount", Range = {16, 500}, Increment = 1, CurrentValue = 100, Callback = function(v) State.SpeedAmt = v end})
TabLocal:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Callback = function(v) State.InfJump = v end})
TabLocal:CreateToggle({Name = "High Jump", CurrentValue = false, Callback = function(v) State.HighJump = v end})
TabLocal:CreateSlider({Name = "Jump Power", Range = {50, 500}, Increment = 1, CurrentValue = 150, Callback = function(v) State.JumpAmt = v end})
TabLocal:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) State.NoClip = v end})
TabLocal:CreateToggle({Name = "Spin Bot", CurrentValue = false, Callback = function(v) State.SpinBot = v end})
TabLocal:CreateSlider({Name = "Spin Speed", Range = {1, 100}, Increment = 1, CurrentValue = 20, Callback = function(v) State.SpinSpeed = v end})

TabLocal:CreateSection("Character & Protection")
TabLocal:CreateToggle({Name = "Anti Ragdoll", CurrentValue = false, Callback = function(v) State.AntiRagdoll = v end})
TabLocal:CreateToggle({Name = "Advanced Anti Fling", CurrentValue = false, Callback = function(v) State.AntiFling = v end})
TabLocal:CreateToggle({Name = "Ghost Invisible", CurrentValue = false, Callback = function(v) State.Invisible = v end})
TabLocal:CreateToggle({Name = "God Mode", CurrentValue = false, Callback = function(v) 
    State.GodMode = v 
    if v and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 999999; hum.Health = 999999 end
    end
end})
TabLocal:CreateToggle({Name = "No Gravity", CurrentValue = false, Callback = function(v) State.NoGravity = v end})
TabLocal:CreateToggle({Name = "Freeze Position", CurrentValue = false, Callback = function(v) State.Freeze = v end})

TabCombat:CreateSection("Aimbot & Silent Aim")
TabCombat:CreateDropdown({Name = "Aimbot Mode", Options = {"Off", "Always", "Hold (Right Mouse)", "Toggle (Left Mouse)"}, CurrentOption = "Off", Callback = function(Option) State.AimbotMode = Option end})
TabCombat:CreateToggle({Name = "Silent Aim (Hit Hack)", CurrentValue = false, Callback = function(v) State.SilentAim = v end})
TabCombat:CreateSlider({Name = "Aimbot FOV", Range = {10, 360}, Increment = 1, CurrentValue = 120, Callback = function(v) State.AimbotFOV = v end})
TabCombat:CreateSlider({Name = "Aimbot Smooth (1 = Fast)", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) State.AimbotSmooth = v end})
TabCombat:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) State.AimbotWallcheck = v end})
TabCombat:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) State.AimbotTeamcheck = v end})

TabCombat:CreateSection("Visuals & Hitboxes")
TabCombat:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) State.AimbotShowFOV = v end})
TabCombat:CreateToggle({Name = "Rainbow FOV", CurrentValue = false, Callback = function(v) State.RainbowFOV = v end})
TabCombat:CreateColorPicker({Name = "Aimbot FOV Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(color) State.FOVColor = color end})
TabCombat:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) State.HitboxExpander = v end})
TabCombat:CreateSlider({Name = "Hitbox Size", Range = {1, 50}, Increment = 1, CurrentValue = 10, Callback = function(v) State.HitboxSize = v end})

TabCombat:CreateSection("Fling")
TabCombat:CreateToggle({Name = "Contact Fling", CurrentValue = false, Callback = function(v) State.ContactFling = v end})
TabCombat:CreateToggle({Name = "Show Fling Radius", CurrentValue = false, Callback = function(v) if v then FlingVisual.Parent = workspace else FlingVisual.Parent = nil end end})
TabCombat:CreateSlider({Name = "Fling Power", Range = {100, 50000}, Increment = 100, CurrentValue = 5000, Callback = function(v) State.FlingPower = v end})
TabCombat:CreateSlider({Name = "Fling Radius", Range = {5, 100}, Increment = 1, CurrentValue = 30, Callback = function(v) 
    State.FlingRadius = v 
    FlingVisual.Size = Vector3.new(v * 2, v * 2, v * 2)
end})

TabESP:CreateSection("ESP Options")
TabESP:CreateToggle({Name = "Enabled", CurrentValue = false, Callback = function(v) State.ESP_Enabled = v end})
TabESP:CreateToggle({Name = "Box ESP", CurrentValue = false, Callback = function(v) State.ESP_Box = v end})
TabESP:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) State.ESP_Tracers = v end})
TabESP:CreateToggle({Name = "Head Dot", CurrentValue = false, Callback = function(v) State.ESP_Head = v end})
TabESP:CreateToggle({Name = "Name", CurrentValue = true, Callback = function(v) State.ESP_Name = v end})
TabESP:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) State.ESP_Distance = v end})
TabESP:CreateToggle({Name = "Health", CurrentValue = false, Callback = function(v) State.ESP_Health = v end})
TabESP:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) State.ESP_TeamCheck = v end})

TabESP:CreateSection("ESP Colors")
TabESP:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 50, 50), Callback = function(color) 
    for _, obj in pairs(State.ESP_Objects) do obj.BoxStroke.Color = color end
end})
TabESP:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(color) 
    for _, obj in pairs(State.ESP_Objects) do obj.Tracer.BackgroundColor3 = color end
end})
TabESP:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(color) 
    for _, obj in pairs(State.ESP_Objects) do obj.Name.TextColor3 = color end
end})

TabGoofy:CreateSection("Chaos")
TabGoofy:CreateToggle({Name = "Disco Mode", CurrentValue = false, Callback = function(v) State.DiscoMode = v end})
TabGoofy:CreateToggle({Name = "Headless (Local)", CurrentValue = false, Callback = function(v) State.Headless = v end})
TabGoofy:CreateToggle({Name = "Remove Terrain", CurrentValue = false, Callback = function(v) 
    State.RemoveTerrain = v
    if v then pcall(function() workspace:FindFirstChildOfClass("Terrain"):Clear() end) end
end})
TabGoofy:CreateButton({Name = "Fling Everyone Nearby", Callback = function()
    if not LP.Character then return end
    local myHrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if tHrp and (tHrp.Position - myHrp.Position).Magnitude < 50 then
                pcall(function() tHrp.AssemblyLinearVelocity = (tHrp.Position - myHrp.Position).Unit * 9999 + Vector3.new(0, 5000, 0) end)
            end
        end
    end
end})
TabGoofy:CreateSection("Size Modifier")
TabGoofy:CreateSlider({Name = "Player Scale (1 = Normal)", Range = {0.1, 10}, Increment = 0.1, CurrentValue = 1, Callback = function(val) State.PlayerScale = val end})

TabServer:CreateSection("Server Utilities")
TabServer:CreateButton({Name = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end})
TabServer:CreateButton({Name = "Server Hop (New Server)", Callback = function()
    local baseUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(function() return HttpService:JSONDecode(game:HttpGet(baseUrl)) end)
    if success and response and response.data then
        for _, server in pairs(response.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                break
            end
        end
    end
end})

TabMisc:CreateSection("Utility")
TabMisc:CreateToggle({Name = "Anti AFK", CurrentValue = false, Callback = function(v) State.AntiAFK = v end})
TabMisc:CreateToggle({Name = "BTools", CurrentValue = false, Callback = function(v) State.BTools = v end})
TabMisc:CreateToggle({Name = "Chat Spam", CurrentValue = false, Callback = function(v) State.ChatSpam = v end})
TabMisc:CreateInput({Name = "Spam Msg", PlaceholderText = "Get flung lol", RemoveTextAfterFocusLost = false, Callback = function(v) State.SpamMsg = v end})
TabMisc:CreateSlider({Name = "Spam Rate", Range = {1, 10}, Increment = 1, CurrentValue = 1, Callback = function(v) State.SpamRate = v end})
TabMisc:CreateSection("Danger Zone")
TabMisc:CreateButton({Name = "Kill Switch / Unload Script", Callback = function() UnloadScript() end})

-- ============================================
-- SAFE HOOKS & MAIN LOOPS
-- ============================================
pcall(function()
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local isCaller = (checkcaller and checkcaller()) or false
        
        if not isCaller and State.GodMode and self and self:IsA("Humanoid") and LP.Character and self == LP.Character:FindFirstChildOfClass("Humanoid") then
            if method == "TakeDamage" then return end
        end
        
        if not isCaller and State.SilentAim and self == workspace then
            if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
                local target = GetClosestPlayerToMouse()
                if target and target.Character and target.Character:FindFirstChild("Head") then
                    local args = {...}
                    local origin = args[1].Origin
                    local direction = (target.Character.Head.Position - origin)
                    args[1] = Ray.new(origin, direction)
                    return OldNamecall(self, unpack(args))
                end
            elseif method == "Raycast" then
                local target = GetClosestPlayerToMouse()
                if target and target.Character and target.Character:FindFirstChild("Head") then
                    local args = {...}
                    local origin = args[1]
                    local direction = (target.Character.Head.Position - origin)
                    args[2] = direction
                    return OldNamecall(self, unpack(args))
                end
            end
        end
        return OldNamecall(self, ...)
    end)
end)

table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.ClickTP and not gpe then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
            local ray = Cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LP.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
        end
    end
    if State.AimbotMode == "Toggle (Left Mouse)" and not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.AimbotToggleActive = not State.AimbotToggleActive
    end
end))

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            if State.Speed then pcall(function() hum.WalkSpeed = State.SpeedAmt end) else pcall(function() hum.WalkSpeed = 16 end) end
            if State.HighJump then pcall(function() hum.JumpPower = State.JumpAmt end) else pcall(function() hum.JumpPower = 50 end) end
            if State.GodMode then pcall(function() if hum.MaxHealth < 999999 then hum.MaxHealth = 999999 end if hum.Health < 999999 then hum.Health = 999999 end end) end
            if State.AntiRagdoll and hum:GetState() == Enum.HumanoidStateType.Ragdoll then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        if State.NoClip then
            for _, part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity") or v:IsA("BodyForce") or v:IsA("BodyThrust") or v:IsA("RocketPropulsion") then
                    if v.Name ~= "NoGrav_BV" and v.Name ~= "FlyBV" then v:Destroy() end
                end
            end
            if State.AntiFling then
                if hrp.AssemblyLinearVelocity.Magnitude > 1000 then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
                if hrp.AssemblyAngularVelocity.Magnitude > 1000 then hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end
            end
            if State.ContactFling then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP and player.Character then
                        local tHrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp and tHrp:IsA("BasePart") then
                            local dist = (tHrp.Position - hrp.Position).Magnitude
                            if dist < State.FlingRadius then
                                pcall(function() tHrp.AssemblyLinearVelocity = (tHrp.Position - hrp.Position).Unit * State.FlingPower + Vector3.new(0, State.FlingPower * 0.5, 0) end)
                            end
                        end
                    end
                end
            end
            if State.Invisible then
                for _, part in pairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.LocalTransparencyModifier = 1
                        part.Transparency = 1
                    elseif part:IsA("Decal") then
                        part.Transparency = 1
                    end
                end
            else
                for _, part in pairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.LocalTransparencyModifier = 0
                        if part.Name ~= "Head" then part.Transparency = 0 end
                    elseif part:IsA("Decal") then
                        part.Transparency = 0
                    end
                end
            end
            local targetScale = State.PlayerScale
            for _, v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BodyBackScale") or v:IsA("BodyDepthScale") or v:IsA("BodyHeightScale") or v:IsA("BodyWidthScale") or v:IsA("HeadScale") then
                    pcall(function() if v.Value ~= targetScale then v.Value = targetScale end end)
                end
            end
        end
    end
end))

RunService:BindToRenderStep("HubMainLoop", Enum.RenderPriority.Camera.Value + 1, function()
    if not LP.Character then return end
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        local existing = hrp:FindFirstChild("NoGrav_BV")
        if State.NoGravity and not existing then
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name = "NoGrav_BV"
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 0, 0)
        elseif not State.NoGravity and existing then
            existing:Destroy()
        end
        if State.SpinBot then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0) end
        if State.Freeze then
            if not State.FrozenPos then State.FrozenPos = hrp.Position end
            hrp.CFrame = CFrame.new(State.FrozenPos)
        else
            State.FrozenPos = nil
        end
        if State.Headless then
            local head = LP.Character:FindFirstChild("Head")
            if head then
                for _, mesh in pairs(head:GetDescendants()) do
                    if mesh:IsA("SpecialMesh") or mesh:IsA("Decal") then mesh.Transparency = 1 end
                end
                head.Transparency = 1
            end
        end
    end
    if State.FOV then Cam.FieldOfView = State.FOVAmt end
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
        if player ~= LP and player.Character then
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
    RenderESP()
    if AimbotFOVCircle then
        if (State.AimbotMode ~= "Off" or State.SilentAim) and State.AimbotShowFOV then
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
    end
    if FlingVisual and FlingVisual.Parent and hrp then FlingVisual.Position = hrp.Position end
    
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
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetHead = target.Character.Head
            local smoothFactor = 1 / State.AimbotSmooth
            local targetCFrame = CFrame.lookAt(Cam.CFrame.Position, targetHead.Position)
            Cam.CFrame = Cam.CFrame:Lerp(targetCFrame, smoothFactor)
        end
    end
end))

-- Background Loops
spawn(function()
    while wait(60) do
        if State.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

spawn(function()
    while wait(State.SpamRate) do
        if State.ChatSpam then
            pcall(function() game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(State.SpamMsg, "All") end)
        end
    end
end)

spawn(function()
    while wait(1) do
        if State.BTools and LP.Character then
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
end)

Rayfield:Notify({Title = "Universal Hub V52", Content = "Loaded successfully! Press RightCtrl to toggle.", Duration = 3})
