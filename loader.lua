--!nocheck
-- ═══════════════════════════════════════════════════════════
-- UNIVERSAL AIMBOT & ESP HUB — FIXED UI EDITION
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
-- LOAD RAYFIELD UI FIRST — with fallbacks
-- ═══════════════════════════════════════════════════════════

local Rayfield = nil

local rayfieldUrls = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/master/source.lua",
}

for _, url in ipairs(rayfieldUrls) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        Rayfield = result
        break
    end
    warn("[Hub] Rayfield load failed from: " .. url)
end

if not Rayfield then
    warn("[Hub] All Rayfield URLs failed. Using fallback notifications.")
end

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════

local Config = {
    Aimbot = {
        Enabled = false,
        TeamCheck = false,
        WallCheck = false,
        AliveCheck = true,
        NPCCheck = true,
        AimPart = "Head",
        FallbackPart = "HumanoidRootPart",
        Smoothness = 0.2,
        FOV = 100,
        MaxDistance = 1000,
        Keybind = "MouseButton2",
        MouseAim = true,
        Prediction = 0,
        TriggerBot = false,
        TriggerDelay = 0.05,
        RageMode = false,
        TargetLock = true,
        LockBreakDistance = 200,
        SortMethod = "Crosshair",
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
        FOVThickness = 1.5,
        FOVFilled = false,
        FOVTransparency = 0.5,
        FOVNumSides = 60,
    },
    SilentAim = {
        Enabled = false,
        HitChance = 100,
        TargetPart = "Head",
        FOV = 80,
        TeamCheck = true,
        WallCheck = false,
    },
    ESP = {
        Enabled = false,
        TeamCheck = false,
        MaxDistance = 1000,
        Boxes = true,
        BoxColor = Color3.fromRGB(255, 0, 0),
        BoxThickness = 1,
        BoxFilled = false,
        BoxFillTransparency = 0.7,
        BoxOutline = true,
        Names = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 13,
        Distance = true,
        DistanceColor = Color3.fromRGB(200, 200, 200),
        DistanceSize = 13,
        HealthBars = true,
        HealthBarColor = Color3.fromRGB(0, 255, 0),
        HealthBarBg = Color3.fromRGB(60, 60, 60),
        Tracers = false,
        TracerColor = Color3.fromRGB(255, 0, 0),
        TracerThickness = 1,
        TracerOrigin = "Bottom",
        Chams = false,
        ChamsColor = Color3.fromRGB(255, 0, 0),
        ChamsTransparency = 0.5,
        ChamsOutlineColor = Color3.fromRGB(0, 0, 0),
        UseTeamColors = false,
        Skeleton = false,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        SkeletonThickness = 1,
        Dynamic = true,
    },
    Crosshair = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Thickness = 1,
        Size = 10,
        Gap = 2,
        Dot = false,
        DotSize = 2,
        Outline = true,
    },
    UI = {
        ToggleKey = Enum.KeyCode.RightControl,
        Watermark = true,
        Notifications = true,
    },
}

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════

local State = {
    CurrentTarget = nil,
    LastTrigger = 0,
    FOVCircle = nil,
    CrosshairLines = {},
    CrosshairDot = nil,
    EspObjects = {},
    ChamsObjects = {},
    SkeletonObjects = {},
    Connections = {},
    Loaded = false,
}

-- ═══════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════

local function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[Hub] Error: " .. tostring(result))
    end
    return success, result
end

local function Notify(title, text, duration)
    if not Config.UI.Notifications then return end
    SafeCall(function()
        if Rayfield then
            Rayfield:Notify(title, text, duration or 3)
        else
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = duration or 3,
            })
        end
    end)
end

local function GetCharacter(player)
    if not player then return nil end
    return player.Character
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function GetTargetPart(player, partName, fallbackName)
    local char = GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild(fallbackName or "HumanoidRootPart")
end

local function IsAlive(player)
    if not Config.Aimbot.AliveCheck then return true end
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

local function IsTeammate(player)
    if not Config.Aimbot.TeamCheck then return false end
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function IsNPC(player)
    if not Config.Aimbot.NPCCheck then return false end
    return not Players:FindFirstChild(player.Name)
end

local function GetDistance(part)
    return (Camera.CFrame.Position - part.Position).Magnitude
end

local function GetScreenDistance(part)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
end

local function IsVisible(targetPart, player)
    if not Config.Aimbot.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    if player.Character then
        table.insert(ignoreList, player.Character)
    end
    params.FilterDescendantsInstances = ignoreList
    local result = Workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        if not result.Instance:IsDescendantOf(player.Character) then
            return false
        end
    end
    return true
end

local function IsInFOV(part, fovRadius)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= fovRadius
end

local keyMap = {
    ["MouseButton2"] = Enum.UserInputType.MouseButton2,
    ["MouseButton1"] = Enum.UserInputType.MouseButton1,
    ["LeftShift"] = Enum.KeyCode.LeftShift,
    ["LeftAlt"] = Enum.KeyCode.LeftAlt,
    ["RightShift"] = Enum.KeyCode.RightShift,
    ["LeftControl"] = Enum.KeyCode.LeftControl,
    ["CapsLock"] = Enum.KeyCode.CapsLock,
}

local function IsKeyActivated()
    local key = keyMap[Config.Aimbot.Keybind]
    if not key then return true end
    if key.EnumType == Enum.UserInputType then
        return UserInputService:IsMouseButtonPressed(key)
    else
        return UserInputService:IsKeyDown(key)
    end
end

local function GetTeamColor(player)
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

-- ═══════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════════════

local function SetupFOV()
    if State.FOVCircle then State.FOVCircle:Remove() end
    State.FOVCircle = Drawing.new("Circle")
    State.FOVCircle.Thickness = Config.Aimbot.FOVThickness
    State.FOVCircle.Radius = Config.Aimbot.FOV
    State.FOVCircle.Color = Config.Aimbot.FOVColor
    State.FOVCircle.Filled = Config.Aimbot.FOVFilled
    State.FOVCircle.Transparency = Config.Aimbot.FOVTransparency
    State.FOVCircle.NumSides = Config.Aimbot.FOVNumSides
    State.FOVCircle.Visible = false
end

local function UpdateFOV()
    if not State.FOVCircle then return end
    State.FOVCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
    State.FOVCircle.Radius = Config.Aimbot.FOV
    State.FOVCircle.Color = Config.Aimbot.FOVColor
    State.FOVCircle.Thickness = Config.Aimbot.FOVThickness
    State.FOVCircle.Filled = Config.Aimbot.FOVFilled
    State.FOVCircle.Transparency = Config.Aimbot.FOVTransparency
    State.FOVCircle.NumSides = Config.Aimbot.FOVNumSides
    local mousePos = UserInputService:GetMouseLocation()
    State.FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
end

-- ═══════════════════════════════════════════════════════════
-- CROSSHAIR
-- ═══════════════════════════════════════════════════════════

local function SetupCrosshair()
    for i = 1, 4 do
        if State.CrosshairLines[i] then State.CrosshairLines[i]:Remove() end
        State.CrosshairLines[i] = Drawing.new("Line")
        State.CrosshairLines[i].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[i].Color = Config.Crosshair.Color
        State.CrosshairLines[i].Visible = false
    end
    if Config.Crosshair.Dot then
        if State.CrosshairDot then State.CrosshairDot:Remove() end
        State.CrosshairDot = Drawing.new("Circle")
        State.CrosshairDot.Radius = Config.Crosshair.DotSize
        State.CrosshairDot.Color = Config.Crosshair.Color
        State.CrosshairDot.Filled = true
        State.CrosshairDot.Visible = false
    end
end

local function UpdateCrosshair()
    if not Config.Crosshair.Enabled then
        for _, line in ipairs(State.CrosshairLines) do
            if line then line.Visible = false end
        end
        if State.CrosshairDot then State.CrosshairDot.Visible = false end
        return
    end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    local size = Config.Crosshair.Size
    local gap = Config.Crosshair.Gap
    
    if State.CrosshairLines[1] then
        State.CrosshairLines[1].From = Vector2.new(centerX, centerY - gap - size)
        State.CrosshairLines[1].To = Vector2.new(centerX, centerY - gap)
        State.CrosshairLines[1].Color = Config.Crosshair.Color
        State.CrosshairLines[1].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[1].Visible = true
    end
    if State.CrosshairLines[2] then
        State.CrosshairLines[2].From = Vector2.new(centerX, centerY + gap)
        State.CrosshairLines[2].To = Vector2.new(centerX, centerY + gap + size)
        State.CrosshairLines[2].Color = Config.Crosshair.Color
        State.CrosshairLines[2].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[2].Visible = true
    end
    if State.CrosshairLines[3] then
        State.CrosshairLines[3].From = Vector2.new(centerX - gap - size, centerY)
        State.CrosshairLines[3].To = Vector2.new(centerX - gap, centerY)
        State.CrosshairLines[3].Color = Config.Crosshair.Color
        State.CrosshairLines[3].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[3].Visible = true
    end
    if State.CrosshairLines[4] then
        State.CrosshairLines[4].From = Vector2.new(centerX + gap, centerY)
        State.CrosshairLines[4].To = Vector2.new(centerX + gap + size, centerY)
        State.CrosshairLines[4].Color = Config.Crosshair.Color
        State.CrosshairLines[4].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[4].Visible = true
    end
    
    if State.CrosshairDot then
        State.CrosshairDot.Position = Vector2.new(centerX, centerY)
        State.CrosshairDot.Radius = Config.Crosshair.DotSize
        State.CrosshairDot.Color = Config.Crosshair.Color
        State.CrosshairDot.Visible = Config.Crosshair.Dot
    end
end

-- ═══════════════════════════════════════════════════════════
-- AIMBOT LOGIC
-- ═══════════════════════════════════════════════════════════

local function GetValidTargets()
    local valid = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsNPC(player) then
            if IsAlive(player) and not IsTeammate(player) then
                local part = GetTargetPart(player, Config.Aimbot.AimPart, Config.Aimbot.FallbackPart)
                if part then
                    local dist3D = GetDistance(part)
                    if dist3D <= Config.Aimbot.MaxDistance then
                        if IsInFOV(part, Config.Aimbot.FOV) then
                            if not Config.Aimbot.WallCheck or IsVisible(part, player) then
                                table.insert(valid, {
                                    Player = player,
                                    Part = part,
                                    Distance3D = dist3D,
                                    ScreenDistance = GetScreenDistance(part),
                                    Position = part.Position,
                                    Velocity = part.AssemblyLinearVelocity,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return valid
end

local function FindBestTarget()
    if Config.Aimbot.TargetLock and State.CurrentTarget then
        local t = State.CurrentTarget
        if t and t.Player and t.Player.Parent and IsAlive(t.Player) and not IsTeammate(t.Player) then
            local part = GetTargetPart(t.Player, Config.Aimbot.AimPart, Config.Aimbot.FallbackPart)
            if part and IsInFOV(part, Config.Aimbot.FOV) then
                local dist3D = GetDistance(part)
                if dist3D <= Config.Aimbot.MaxDistance then
                    if not Config.Aimbot.WallCheck or IsVisible(part, t.Player) then
                        if Config.Aimbot.LockBreakDistance <= 0 or dist3D <= Config.Aimbot.LockBreakDistance then
                            t.Part = part
                            t.Position = part.Position
                            t.Velocity = part.AssemblyLinearVelocity
                            t.Distance3D = dist3D
                            t.ScreenDistance = GetScreenDistance(part)
                            return t
                        end
                    end
                end
            end
        end
        State.CurrentTarget = nil
    end
    
    local valid = GetValidTargets()
    if #valid == 0 then return nil end
    
    if Config.Aimbot.SortMethod == "Distance" then
        table.sort(valid, function(a, b) return a.Distance3D < b.Distance3D end)
    else
        table.sort(valid, function(a, b) return a.ScreenDistance < b.ScreenDistance end)
    end
    
    State.CurrentTarget = valid[1]
    return valid[1]
end

local function AimAtTarget(target)
    if not target or not target.Part then return end
    local aimPos = target.Position
    if Config.Aimbot.Prediction > 0 then
        aimPos = aimPos + (target.Velocity * Config.Aimbot.Prediction)
    end
    local currentPos = Camera.CFrame.Position
    local aimCFrame = CFrame.lookAt(currentPos, aimPos)
    
    if Config.Aimbot.RageMode then
        Camera.CFrame = aimCFrame
    elseif Config.Aimbot.MouseAim and mousemoverel then
        local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
        if onScreen then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local delta = Vector2.new(screenPos.X - center.X, screenPos.Y - center.Y)
            local smooth = Config.Aimbot.Smoothness
            if smooth <= 0 then smooth = 1 end
            mousemoverel(delta.X * smooth, delta.Y * smooth)
        end
    else
        if Config.Aimbot.Smoothness > 0 and Config.Aimbot.Smoothness < 1 then
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Config.Aimbot.Smoothness)
        else
            Camera.CFrame = aimCFrame
        end
    end
end

local function TriggerFire()
    if not Config.Aimbot.TriggerBot then return end
    if tick() - State.LastTrigger < Config.Aimbot.TriggerDelay then return end
    State.LastTrigger = tick()
    SafeCall(function()
        if mouse1click then mouse1click() end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- SILENT AIM
-- ═══════════════════════════════════════════════════════════

local SilentAimTarget = nil

local function GetSilentAimTarget()
    if not Config.SilentAim.Enabled then return nil end
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsNPC(player) and IsAlive(player) then
            local isTeam = false
            if Config.SilentAim.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                isTeam = true
            end
            if not isTeam then
                local part = GetTargetPart(player, Config.SilentAim.TargetPart, "HumanoidRootPart")
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist <= Config.SilentAim.FOV and dist < shortest then
                            if not Config.SilentAim.WallCheck or IsVisible(part, player) then
                                if Config.SilentAim.HitChance >= 100 or math.random(1, 100) <= Config.SilentAim.HitChance then
                                    shortest = dist
                                    closest = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local oldNamecall
SafeCall(function()
    if type(debug) == "table" and debug.getmetatable and hookmetamethod then
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Config.SilentAim.Enabled and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay") then
                local target = SilentAimTarget
                if target then
                    local args = {...}
                    if type(args[1]) == "Ray" then
                        local origin = args[1].Origin
                        local newDir = (target.Position - origin)
                        args[1] = Ray.new(origin, newDir)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════════

local function ClearESP(player)
    if State.EspObjects[player] then
        for _, obj in pairs(State.EspObjects[player]) do
            SafeCall(function() obj:Remove() end)
        end
        State.EspObjects[player] = nil
    end
    if State.ChamsObjects[player] then
        SafeCall(function() State.ChamsObjects[player]:Destroy() end)
        State.ChamsObjects[player] = nil
    end
    if State.SkeletonObjects[player] then
        for _, line in pairs(State.SkeletonObjects[player]) do
            SafeCall(function() line:Remove() end)
        end
        State.SkeletonObjects[player] = nil
    end
end

local function CreateESP(player)
    ClearESP(player)
    State.EspObjects[player] = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarBg = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
    }
    local obj = State.EspObjects[player]
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
    obj.HealthBar.Thickness = 1
    obj.HealthBar.Filled = true
    obj.HealthBarBg.Thickness = 1
    obj.HealthBarBg.Filled = true
    obj.HealthBarBg.Color = Color3.fromRGB(60, 60, 60)
    obj.Tracer.Thickness = 1
end

local function CreateChams(player)
    local char = GetCharacter(player)
    if not char then return end
    if State.ChamsObjects[player] then
        SafeCall(function() State.ChamsObjects[player]:Destroy() end)
    end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Config.ESP.ChamColor
    highlight.FillTransparency = Config.ESP.ChamTransparency
    highlight.OutlineColor = Config.ESP.ChamOutlineColor
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    State.ChamsObjects[player] = highlight
end

local SkeletonBones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local SkeletonBonesR6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function UpdateSkeleton(player, char)
    if not Config.ESP.Skeleton then
        if State.SkeletonObjects[player] then
            for _, line in pairs(State.SkeletonObjects[player]) do
                line.Visible = false
            end
        end
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rigType = hum and hum.RigType or Enum.HumanoidRigType.R15
    local bones = rigType == Enum.HumanoidRigType.R6 and SkeletonBonesR6 or SkeletonBones
    if not State.SkeletonObjects[player] then
        State.SkeletonObjects[player] = {}
        for i = 1, #bones do
            State.SkeletonObjects[player][i] = Drawing.new("Line")
            State.SkeletonObjects[player][i].Thickness = Config.ESP.SkeletonThickness
            State.SkeletonObjects[player][i].Color = Config.ESP.SkeletonColor
        end
    end
    local color = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.SkeletonColor
    for i, bone in ipairs(bones) do
        local line = State.SkeletonObjects[player][i]
        if line then
            local p1 = char:FindFirstChild(bone[1])
            local p2 = char:FindFirstChild(bone[2])
            if p1 and p2 then
                local s1, on1 = Camera:WorldToViewportPoint(p1.Position)
                local s2, on2 = Camera:WorldToViewportPoint(p2.Position)
                if on1 and on2 then
                    line.From = Vector2.new(s1.X, s1.Y)
                    line.To = Vector2.new(s2.X, s2.Y)
                    line.Color = color
                    line.Thickness = Config.ESP.SkeletonThickness
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

local function UpdateESP(player)
    if not Config.ESP.Enabled then
        local obj = State.EspObjects[player]
        if obj then
            obj.Box.Visible = false
            obj.BoxOutline.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
            obj.HealthBar.Visible = false
            obj.HealthBarBg.Visible = false
            obj.Tracer.Visible = false
        end
        if State.SkeletonObjects[player] then
            for _, line in pairs(State.SkeletonObjects[player]) do
                line.Visible = false
            end
        end
        return
    end
    
    local char = GetCharacter(player)
    if not char or player == LocalPlayer then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then
        local obj = State.EspObjects[player]
        if obj then
            obj.Box.Visible = false
            obj.BoxOutline.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
            obj.HealthBar.Visible = false
            obj.HealthBarBg.Visible = false
            obj.Tracer.Visible = false
        end
        return
    end
    
    local dist3D = GetDistance(hrp)
    if dist3D > Config.ESP.MaxDistance then
        local obj = State.EspObjects[player]
        if obj then
            obj.Box.Visible = false
            obj.BoxOutline.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
            obj.HealthBar.Visible = false
            obj.HealthBarBg.Visible = false
            obj.Tracer.Visible = false
        end
        return
    end
    
    local isTeam = false
    if Config.ESP.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        isTeam = true
    end
    if isTeam then
        local obj = State.EspObjects[player]
        if obj then
            obj.Box.Visible = false
            obj.BoxOutline.Visible = false
            obj.Name.Visible = false
            obj.Distance.Visible = false
            obj.HealthBar.Visible = false
            obj.HealthBarBg.Visible = false
            obj.Tracer.Visible = false
        end
        return
    end
    
    local obj = State.EspObjects[player]
    if not obj then return end
    
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head and head.Position or hrp.Position)
    local hrpScreenPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position)
    
    if not headOnScreen and not hrpOnScreen then
        obj.Box.Visible = false
        obj.BoxOutline.Visible = false
        obj.Name.Visible = false
        obj.Distance.Visible = false
        obj.HealthBar.Visible = false
        obj.HealthBarBg.Visible = false
        obj.Tracer.Visible = false
        return
    end
    
    -- ACCURATE BOX SIZING
    local lowestY = headPos.Y
    for _, partName in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg", "LeftLowerLeg", "RightLowerLeg"}) do
        local part = char:FindFirstChild(partName)
        if part then
            local sp, onS = Camera:WorldToViewportPoint(part.Position)
            if onS and sp.Y > lowestY then
                lowestY = sp.Y
            end
        end
    end
    
    if lowestY <= headPos.Y then
        local bottomWorld = hrp.Position - Vector3.new(0, 3, 0)
        local bs, bo = Camera:WorldToViewportPoint(bottomWorld)
        if bo then
            lowestY = bs.Y
        else
            lowestY = hrpScreenPos.Y + (hrpScreenPos.Y - headPos.Y) * 2
        end
    end
    
    local leftShoulder = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local rightShoulder = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local leftX, rightX
    if leftShoulder then
        local sp, onS = Camera:WorldToViewportPoint(leftShoulder.Position)
        if onS then leftX = sp.X end
    end
    if rightShoulder then
        local sp, onS = Camera:WorldToViewportPoint(rightShoulder.Position)
        if onS then rightX = sp.X end
    end
    
    local width, height, centerX, topY
    if leftX and rightX then
        width = math.abs(rightX - leftX) * 1.15
        centerX = (leftX + rightX) / 2
    else
        height = math.abs(lowestY - headPos.Y)
        width = height * 0.5
        centerX = headPos.X
    end
    height = math.abs(lowestY - headPos.Y)
    
    if Config.ESP.Dynamic then
        local extents = char:GetExtentsSize()
        local expectedHeight = math.clamp(extents.Y * 200 / math.max(dist3D, 1), 20, 500)
        if height < expectedHeight * 0.5 then
            height = expectedHeight
        end
    end
    
    if height < 15 then height = 15 end
    if width < 8 then width = 8 end
    topY = headPos.Y - (height * 0.1)
    local boxX = centerX - (width / 2)
    local boxCenterY = topY + (height / 2)
    
    local boxColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.BoxColor
    local nameColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.NameColor
    local tracerColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.TracerColor
    
    if Config.ESP.Boxes then
        obj.Box.Visible = true
        obj.BoxOutline.Visible = Config.ESP.BoxOutline
        obj.Box.Size = Vector2.new(width, height)
        obj.Box.Position = Vector2.new(boxX, topY)
        obj.Box.Color = boxColor
        obj.Box.Thickness = Config.ESP.BoxThickness
        obj.Box.Filled = Config.ESP.BoxFilled
        obj.Box.Transparency = Config.ESP.BoxFillTransparency
        obj.BoxOutline.Size = obj.Box.Size
        obj.BoxOutline.Position = obj.Box.Position
    else
        obj.Box.Visible = false
        obj.BoxOutline.Visible = false
    end
    
    if Config.ESP.Names then
        obj.Name.Visible = true
        obj.Name.Text = tostring(player.DisplayName)
        obj.Name.Position = Vector2.new(centerX, topY - 16)
        obj.Name.Color = nameColor
        obj.Name.Size = Config.ESP.NameSize
    else
        obj.Name.Visible = false
    end
    
    if Config.ESP.Distance then
        obj.Distance.Visible = true
        obj.Distance.Text = tostring(math.floor(dist3D)) .. " studs"
        obj.Distance.Position = Vector2.new(centerX, lowestY + 5)
        obj.Distance.Color = Config.ESP.DistanceColor
        obj.Distance.Size = Config.ESP.DistanceSize
    else
        obj.Distance.Visible = false
    end
    
    if Config.ESP.HealthBars then
        local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barHeight = height
        local barWidth = 3
        local barX = boxX - 6
        obj.HealthBarBg.Visible = true
        obj.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
        obj.HealthBarBg.Position = Vector2.new(barX, topY)
        obj.HealthBarBg.Color = Config.ESP.HealthBarBg
        obj.HealthBarBg.Filled = true
        obj.HealthBar.Visible = true
        obj.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPct)
        obj.HealthBar.Position = Vector2.new(barX, topY + (barHeight * (1 - healthPct)))
        local r, g
        if healthPct > 0.5 then
            r = math.floor((1 - (healthPct - 0.5) * 2) * 255)
            g = 255
        else
            r = 255
            g = math.floor(healthPct * 2 * 255)
        end
        obj.HealthBar.Color = Color3.fromRGB(r, g, 0)
        obj.HealthBar.Filled = true
    else
        obj.HealthBar.Visible = false
        obj.HealthBarBg.Visible = false
    end
    
    if Config.ESP.Tracers then
        obj.Tracer.Visible = true
        local origin
        if Config.ESP.TracerOrigin == "Bottom" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif Config.ESP.TracerOrigin == "Center" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else
            local m = UserInputService:GetMouseLocation()
            origin = Vector2.new(m.X, m.Y)
        end
        obj.Tracer.From = origin
        obj.Tracer.To = Vector2.new(centerX, boxCenterY)
        obj.Tracer.Color = tracerColor
        obj.Tracer.Thickness = Config.ESP.TracerThickness
    else
        obj.Tracer.Visible = false
    end
    
    if Config.ESP.Cham then
        CreateChams(player)
        local hl = State.ChamsObjects[player]
        if hl then
            hl.FillColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.ChamColor
            hl.FillTransparency = Config.ESP.ChamTransparency
            hl.OutlineColor = Config.ESP.ChamOutlineColor
            hl.Parent = char
        end
    elseif State.ChamsObjects[player] then
        SafeCall(function() State.ChamsObjects[player]:Destroy() end)
        State.ChamsObjects[player] = nil
    end
    
    UpdateSkeleton(player, char)
end

-- ═══════════════════════════════════════════════════════════
-- PLAYER MANAGEMENT
-- ═══════════════════════════════════════════════════════════

local function OnPlayerAdded(player)
    CreateESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        CreateESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

table.insert(State.Connections, Players.PlayerAdded:Connect(OnPlayerAdded))
table.insert(State.Connections, Players.PlayerRemoving:Connect(function(p) ClearESP(p) end))

-- ═══════════════════════════════════════════════════════════
-- BUILD UI (before main loop starts)
-- ═══════════════════════════════════════════════════════════

local Window = nil

if Rayfield then
    Window = Rayfield:CreateWindow({
        Name = "Universal Hub — Custom Edition",
        LoadingTitle = "Loading Hub...",
        LoadingSubtitle = "Deep Customization Build",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local TabAimbot = Window:CreateTab("Aimbot", 4483362458)
    local TabSilent = Window:CreateTab("Silent Aim", 4483362458)
    local TabESP = Window:CreateTab("Visuals / ESP", 4483362458)
    local TabCrosshair = Window:CreateTab("Crosshair", 4483362458)
    local TabSettings = Window:CreateTab("Settings", 4483362458)

    -- AIMBOT TAB
    TabAimbot:CreateToggle({Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) Config.Aimbot.Enabled = v end})
    TabAimbot:CreateToggle({Name = "Rage Mode (Instant Snap)", CurrentValue = false, Callback = function(v) Config.Aimbot.RageMode = v end})
    TabAimbot:CreateToggle({Name = "Stealth Mode (Mouse Aim)", CurrentValue = true, Callback = function(v) Config.Aimbot.MouseAim = v end})
    TabAimbot:CreateDropdown({Name = "Activation Key", Options = {"MouseButton2", "MouseButton1", "LeftShift", "LeftAlt", "RightShift", "LeftControl", "CapsLock"}, CurrentValue = "MouseButton2", Callback = function(v) Config.Aimbot.Keybind = v end})
    TabAimbot:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}, CurrentValue = "Head", Callback = function(v) Config.Aimbot.AimPart = v end})
    TabAimbot:CreateDropdown({Name = "Sort Method", Options = {"Crosshair", "Distance"}, CurrentValue = "Crosshair", Callback = function(v) Config.Aimbot.SortMethod = v end})
    TabAimbot:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) Config.Aimbot.TeamCheck = v end})
    TabAimbot:CreateToggle({Name = "Wall Check", CurrentValue = false, Callback = function(v) Config.Aimbot.WallCheck = v end})
    TabAimbot:CreateToggle({Name = "Alive Check", CurrentValue = true, Callback = function(v) Config.Aimbot.AliveCheck = v end})
    TabAimbot:CreateToggle({Name = "NPC Check", CurrentValue = true, Callback = function(v) Config.Aimbot.NPCCheck = v end})
    TabAimbot:CreateToggle({Name = "Target Lock", CurrentValue = true, Callback = function(v) Config.Aimbot.TargetLock = v end})
    TabAimbot:CreateSlider({Name = "Lock Break Distance", Range = {50, 1000}, Increment = 10, CurrentValue = 200, Callback = function(v) Config.Aimbot.LockBreakDistance = v end})
    TabAimbot:CreateSlider({Name = "FOV", Range = {10, 500}, Increment = 1, CurrentValue = 100, Callback = function(v) Config.Aimbot.FOV = v end})
    TabAimbot:CreateSlider({Name = "Smoothness", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.2, Callback = function(v) Config.Aimbot.Smoothness = v end})
    TabAimbot:CreateSlider({Name = "Prediction", Range = {0, 0.5}, Increment = 0.01, CurrentValue = 0, Callback = function(v) Config.Aimbot.Prediction = v end})
    TabAimbot:CreateSlider({Name = "Max Distance", Range = {50, 5000}, Increment = 10, CurrentValue = 1000, Callback = function(v) Config.Aimbot.MaxDistance = v end})
    TabAimbot:CreateToggle({Name = "TriggerBot", CurrentValue = false, Callback = function(v) Config.Aimbot.TriggerBot = v end})
    TabAimbot:CreateSlider({Name = "TriggerBot Delay", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.05, Callback = function(v) Config.Aimbot.TriggerDelay = v end})
    TabAimbot:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) Config.Aimbot.ShowFOV = v end})
    TabAimbot:CreateColorPicker({Name = "FOV Circle Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Config.Aimbot.FOVColor = v end})
    TabAimbot:CreateSlider({Name = "FOV Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1.5, Callback = function(v) Config.Aimbot.FOVThickness = v end})
    TabAimbot:CreateToggle({Name = "Fill FOV Circle", CurrentValue = false, Callback = function(v) Config.Aimbot.FOVFilled = v end})
    TabAimbot:CreateSlider({Name = "FOV Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Callback = function(v) Config.Aimbot.FOVTransparency = v end})
    TabAimbot:CreateSlider({Name = "FOV Sides", Range = {3, 100}, Increment = 1, CurrentValue = 60, Callback = function(v) Config.Aimbot.FOVNumSides = v end})

    -- SILENT AIM TAB
    TabSilent:CreateToggle({Name = "Enable Silent Aim", CurrentValue = false, Callback = function(v) Config.SilentAim.Enabled = v end})
    TabSilent:CreateDropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}, CurrentValue = "Head", Callback = function(v) Config.SilentAim.TargetPart = v end})
    TabSilent:CreateSlider({Name = "FOV", Range = {10, 500}, Increment = 1, CurrentValue = 80, Callback = function(v) Config.SilentAim.FOV = v end})
    TabSilent:CreateSlider({Name = "Hit Chance (%)", Range = {1, 100}, Increment = 1, CurrentValue = 100, Callback = function(v) Config.SilentAim.HitChance = v end})
    TabSilent:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Config.SilentAim.TeamCheck = v end})
    TabSilent:CreateToggle({Name = "Wall Check", CurrentValue = false, Callback = function(v) Config.SilentAim.WallCheck = v end})

    -- ESP TAB
    TabESP:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(v) Config.ESP.Enabled = v end})
    TabESP:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) Config.ESP.TeamCheck = v end})
    TabESP:CreateToggle({Name = "Use Team Colors", CurrentValue = false, Callback = function(v) Config.ESP.UseTeamColors = v end})
    TabESP:CreateToggle({Name = "Dynamic ESP", CurrentValue = true, Callback = function(v) Config.ESP.Dynamic = v end})
    TabESP:CreateSlider({Name = "Max Distance", Range = {50, 5000}, Increment = 10, CurrentValue = 1000, Callback = function(v) Config.ESP.MaxDistance = v end})
    TabESP:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Config.ESP.Boxes = v end})
    TabESP:CreateToggle({Name = "Box Outline", CurrentValue = true, Callback = function(v) Config.ESP.BoxOutline = v end})
    TabESP:CreateToggle({Name = "Box Fill", CurrentValue = false, Callback = function(v) Config.ESP.BoxFilled = v end})
    TabESP:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.BoxColor = v end})
    TabESP:CreateSlider({Name = "Box Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.BoxThickness = v end})
    TabESP:CreateSlider({Name = "Box Fill Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.7, Callback = function(v) Config.ESP.BoxFillTransparency = v end})
    TabESP:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) Config.ESP.Names = v end})
    TabESP:CreateColorPicker({Name = "Name Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Config.ESP.NameColor = v end})
    TabESP:CreateSlider({Name = "Name Size", Range = {8, 24}, Increment = 1, CurrentValue = 13, Callback = function(v) Config.ESP.NameSize = v end})
    TabESP:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Config.ESP.Distance = v end})
    TabESP:CreateColorPicker({Name = "Distance Color", Color = Color3.fromRGB(200, 200, 200), Callback = function(v) Config.ESP.DistanceColor = v end})
    TabESP:CreateSlider({Name = "Distance Size", Range = {8, 24}, Increment = 1, CurrentValue = 13, Callback = function(v) Config.ESP.DistanceSize = v end})
    TabESP:CreateToggle({Name = "Health Bars", CurrentValue = true, Callback = function(v) Config.ESP.HealthBars = v end})
    TabESP:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) Config.ESP.Tracers = v end})
    TabESP:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.TracerColor = v end})
    TabESP:CreateSlider({Name = "Tracer Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.TracerThickness = v end})
    TabESP:CreateDropdown({Name = "Tracer Origin", Options = {"Bottom", "Center", "Mouse"}, CurrentValue = "Bottom", Callback = function(v) Config.ESP.TracerOrigin = v end})
    TabESP:CreateToggle({Name = "Chams", CurrentValue = false, Callback = function(v) Config.ESP.Cham = v end})
    TabESP:CreateColorPicker({Name = "Chams Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.ChamColor = v end})
    TabESP:CreateSlider({Name = "Chams Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Callback = function(v) Config.ESP.ChamTransparency = v end})
    TabESP:CreateColorPicker({Name = "Chams Outline Color", Color = Color3.fromRGB(0, 0, 0), Callback = function(v) Config.ESP.ChamOutlineColor = v end})
    TabESP:CreateToggle({Name = "Skeleton ESP", CurrentValue = false, Callback = function(v) Config.ESP.Skeleton = v end})
    TabESP:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Config.ESP.SkeletonColor = v end})
    TabESP:CreateSlider({Name = "Skeleton Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.SkeletonThickness = v end})

    -- CROSSHAIR TAB
    TabCrosshair:CreateToggle({Name = "Enable Crosshair", CurrentValue = false, Callback = function(v) Config.Crosshair.Enabled = v end})
    TabCrosshair:CreateColorPicker({Name = "Crosshair Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(v) Config.Crosshair.Color = v end})
    TabCrosshair:CreateSlider({Name = "Size", Range = {2, 30}, Increment = 1, CurrentValue = 10, Callback = function(v) Config.Crosshair.Size = v end})
    TabCrosshair:CreateSlider({Name = "Gap", Range = {0, 20}, Increment = 1, CurrentValue = 2, Callback = function(v) Config.Crosshair.Gap = v end})
    TabCrosshair:CreateSlider({Name = "Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.Crosshair.Thickness = v end})
    TabCrosshair:CreateToggle({Name = "Center Dot", CurrentValue = false, Callback = function(v) Config.Crosshair.Dot = v end})
    TabCrosshair:CreateSlider({Name = "Dot Size", Range = {1, 10}, Increment = 1, CurrentValue = 2, Callback = function(v) Config.Crosshair.DotSize = v end})
    TabCrosshair:CreateToggle({Name = "Outline", CurrentValue = true, Callback = function(v) Config.Crosshair.Outline = v end})

    -- SETTINGS TAB
    TabSettings:CreateToggle({Name = "Notifications", CurrentValue = true, Callback = function(v) Config.UI.Notifications = v end})
    TabSettings:CreateButton({Name = "Unload Script", Callback = function()
        for player, _ in pairs(State.EspObjects) do ClearESP(player) end
        if State.FOVCircle then State.FOVCircle:Remove() State.FOVCircle = nil end
        for _, line in ipairs(State.CrosshairLines) do if line then line:Remove() end end
        if State.CrosshairDot then State.CrosshairDot:Remove() end
        for _, conn in ipairs(State.Connections) do SafeCall(function() conn:Disconnect() end) end
        RunService:UnbindFromRenderStep("HubUpdate")
        if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
        if Rayfield then Rayfield:Destroy() end
    end})
    TabSettings:CreateButton({Name = "Reset All ESP", Callback = function()
        for player, _ in pairs(State.EspObjects) do ClearESP(player) CreateESP(player) end
        Notify("ESP", "All ESP objects reset", 3)
    end})
    TabSettings:CreateButton({Name = "Force Refresh Targets", Callback = function()
        State.CurrentTarget = nil
        Notify("Aimbot", "Target cache cleared", 3)
    end})

    print("[Hub] UI built successfully.")
else
    warn("[Hub] UI failed to load. Script running in headless mode.")
    warn("[Hub] Toggle features by editing the Config table in the script.")
end

-- ═══════════════════════════════════════════════════════════
-- MAIN LOOP (starts AFTER UI is built)
-- ═══════════════════════════════════════════════════════════

SetupFOV()
SetupCrosshair()

local renderConn = RunService:BindToRenderStep("HubUpdate", Enum.RenderPriority.Camera.Value + 2, function()
    SafeCall(function()
        UpdateFOV()
        UpdateCrosshair()
        
        for player, _ in pairs(State.EspObjects) do
            UpdateESP(player)
        end
        
        if Config.Aimbot.Enabled then
            if IsKeyActivated() then
                local target = FindBestTarget()
                if target then
                    AimAtTarget(target)
                    if Config.Aimbot.TriggerBot then
                        TriggerFire()
                    end
                end
            else
                State.CurrentTarget = nil
            end
        end
        
        if Config.SilentAim.Enabled then
            SilentAimTarget = GetSilentAimTarget()
        else
            SilentAimTarget = nil
        end
    end)
end)
table.insert(State.Connections, renderConn)

-- UI toggle keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.UI.ToggleKey then
        if Rayfield then
            Rayfield:Toggle()
        end
    end
end)

State.Loaded = true
Notify("Universal Hub", "Loaded successfully! Press RightControl to toggle UI.", 5)
print("[Hub] Loaded. Press RightControl to toggle UI.")
