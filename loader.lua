--!nocheck
-- ═══════════════════════════════════════════════════════════
-- UNIVERSAL AIMBOT & ESP HUB — DEEPLY CUSTOMIZABLE EDITION
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
-- CONFIGURATION
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
        -- Advanced
        Prediction = 0,
        TriggerBot = false,
        TriggerDelay = 0.05,
        RageMode = false,
        TargetLock = true,
        LockBreakDistance = 200,
        HitboxExpand = 0,
        SortMethod = "Crosshair", -- "Crosshair" or "Distance"
        VisibleOnly = false,
        -- FOV Visual
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
        -- Boxes
        Boxes = true,
        BoxColor = Color3.fromRGB(255, 0, 0),
        BoxThickness = 1,
        BoxFilled = false,
        BoxFillTransparency = 0.7,
        BoxOutline = true,
        -- Names
        Names = true,
        NameColor = Color3.fromRGB(255, 255, 255),
        NameSize = 13,
        -- Distance
        Distance = true,
        DistanceColor = Color3.fromRGB(200, 200, 200),
        DistanceSize = 13,
        -- Health
        HealthBars = true,
        HealthBarColor = Color3.fromRGB(0, 255, 0),
        HealthBarBg = Color3.fromRGB(60, 60, 60),
        -- Tracers
        Tracers = false,
        TracerColor = Color3.fromRGB(255, 0, 0),
        TracerThickness = 1,
        TracerOrigin = "Bottom", -- "Bottom", "Center", "Mouse"
        -- Chams
        Chams = false,
        ChamsColor = Color3.fromRGB(255, 0, 0),
        ChamsTransparency = 0.5,
        ChamsOutlineColor = Color3.fromRGB(0, 0, 0),
        -- Team
        UseTeamColors = false,
        -- Skeleton
        Skeleton = false,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        SkeletonThickness = 1,
        -- Dynamic
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
    FOVCircleFilled = nil,
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

local function IsKeyActivated()
    local keyMap = {
        ["MouseButton2"] = Enum.UserInputType.MouseButton2,
        ["MouseButton1"] = Enum.UserInputType.MouseButton1,
        ["LeftShift"] = Enum.KeyCode.LeftShift,
        ["LeftAlt"] = Enum.KeyCode.LeftAlt,
        ["RightShift"] = Enum.KeyCode.RightShift,
        ["LeftControl"] = Enum.KeyCode.LeftControl,
        ["CapsLock"] = Enum.KeyCode.CapsLock,
        ["None"] = nil,
    }
    local key = keyMap[Config.Aimbot.Keybind]
    if not key then return true end -- "None" = always active
    if key.EnumType == Enum.UserInputType then
        return UserInputService:IsMouseButtonPressed(key)
    else
        return UserInputService:IsKeyDown(key)
    end
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════════════

local function SetupFOV()
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
    -- 4 lines: top, bottom, left, right
    for i = 1, 4 do
        State.CrosshairLines[i] = Drawing.new("Line")
        State.CrosshairLines[i].Thickness = Config.Crosshair.Thickness
        State.CrosshairLines[i].Color = Config.Crosshair.Color
        State.CrosshairLines[i].Visible = false
    end
    if Config.Crosshair.Dot then
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
            line.Visible = false
        end
        if State.CrosshairDot then State.CrosshairDot.Visible = false end
        return
    end
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    local size = Config.Crosshair.Size
    local gap = Config.Crosshair.Gap
    local thickness = Config.Crosshair.Thickness
    local color = Config.Crosshair.Color
    
    -- outline color (black for visibility)
    local outlineColor = Config.Crosshair.Outline and Color3.fromRGB(0, 0, 0) or color
    
    -- Top
    State.CrosshairLines[1].From = Vector2.new(centerX, centerY - gap - size)
    State.CrosshairLines[1].To = Vector2.new(centerX, centerY - gap)
    State.CrosshairLines[1].Color = color
    State.CrosshairLines[1].Thickness = thickness
    State.CrosshairLines[1].Visible = true
    
    -- Bottom
    State.CrosshairLines[2].From = Vector2.new(centerX, centerY + gap)
    State.CrosshairLines[2].To = Vector2.new(centerX, centerY + gap + size)
    State.CrosshairLines[2].Color = color
    State.CrosshairLines[2].Thickness = thickness
    State.CrosshairLines[2].Visible = true
    
    -- Left
    State.CrosshairLines[3].From = Vector2.new(centerX - gap - size, centerY)
    State.CrosshairLines[3].To = Vector2.new(centerX - gap, centerY)
    State.CrosshairLines[3].Color = color
    State.CrosshairLines[3].Thickness = thickness
    State.CrosshairLines[3].Visible = true
    
    -- Right
    State.CrosshairLines[4].From = Vector2.new(centerX + gap, centerY)
    State.CrosshairLines[4].To = Vector2.new(centerX + gap + size, centerY)
    State.CrosshairLines[4].Color = color
    State.CrosshairLines[4].Thickness = thickness
    State.CrosshairLines[4].Visible = true
    
    -- Dot
    if State.CrosshairDot then
        State.CrosshairDot.Position = Vector2.new(centerX, centerY)
        State.CrosshairDot.Radius = Config.Crosshair.DotSize
        State.CrosshairDot.Color = color
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
                                local screenDist = GetScreenDistance(part)
                                table.insert(valid, {
                                    Player = player,
                                    Part = part,
                                    Distance3D = dist3D,
                                    ScreenDistance = screenDist,
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
    -- Target lock: keep current target if still valid
    if Config.Aimbot.TargetLock and State.CurrentTarget then
        local t = State.CurrentTarget
        if t and t.Player and t.Player.Parent and IsAlive(t.Player) and not IsTeammate(t.Player) then
            local part = GetTargetPart(t.Player, Config.Aimbot.AimPart, Config.Aimbot.FallbackPart)
            if part and IsInFOV(part, Config.Aimbot.FOV) then
                local dist3D = GetDistance(part)
                if dist3D <= Config.Aimbot.MaxDistance then
                    if not Config.Aimbot.WallCheck or IsVisible(part, t.Player) then
                        if Config.Aimbot.LockBreakDistance > 0 and dist3D > Config.Aimbot.LockBreakDistance then
                            -- too far, break lock
                        else
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
    
    -- Find new target
    local valid = GetValidTargets()
    if #valid == 0 then return nil end
    
    -- Sort
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
        -- Instant snap
        Camera.CFrame = aimCFrame
    elseif Config.Aimbot.MouseAim and mousemoverel then
        -- Mouse movement (stealth)
        local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
        if onScreen then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local delta = Vector2.new(screenPos.X - center.X, screenPos.Y - center.Y)
            local smooth = Config.Aimbot.Smoothness
            if smooth <= 0 then smooth = 1 end
            mousemoverel(delta.X * smooth, delta.Y * smooth)
        end
    else
        -- Camera lerp
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
        if mouse1click then
            mouse1click()
        elseif fireclickdetector then
            -- fallback
        end
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
                                -- hit chance
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

-- Hook __namecall for silent aim
local oldNamecall
if type(debug) == "table" and debug.getmetatable then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if Config.SilentAim.Enabled and method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
            local target = SilentAimTarget
            if target then
                -- redirect ray to hit target
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

-- ═══════════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════════

local function GetTeamColor(player)
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

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
        HealthText = Drawing.new("Text"),
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
    
    obj.HealthText.Size = 11
    obj.HealthText.Center = true
    obj.HealthText.Outline = true
    obj.HealthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
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

local function UpdateChams(player)
    if not Config.ESP.Cham then return end
    local char = GetCharacter(player)
    if not char then return end
    
    if not State.ChamsObjects[player] or not State.ChamsObjects[player]:FindFirstAncestor() then
        CreateChams(player)
    end
    
    local highlight = State.ChamsObjects[player]
    if highlight then
        local color = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.ChamColor
        highlight.FillColor = color
        highlight.FillTransparency = Config.ESP.ChamTransparency
        highlight.OutlineColor = Config.ESP.ChamOutlineColor
        highlight.Parent = char
    end
end

-- Skeleton ESP definitions
local SkeletonBones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

-- Fallback for R6
local SkeletonBonesR6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local function GetBoneCFrame(char, boneName)
    local part = char:FindFirstChild(boneName)
    if not part then return nil end
    return part.Position
end

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
            local pos1 = GetBoneCFrame(char, bone[1])
            local pos2 = GetBoneCFrame(char, bone[2])
            if pos1 and pos2 then
                local screen1, onScreen1 = Camera:WorldToViewportPoint(pos1)
                local screen2, onScreen2 = Camera:WorldToViewportPoint(pos2)
                if onScreen1 and onScreen2 then
                    line.From = Vector2.new(screen1.X, screen1.Y)
                    line.To = Vector2.new(screen2.X, screen2.Y)
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
            obj.HealthText.Visible = false
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
            obj.HealthText.Visible = false
            obj.Tracer.Visible = false
        end
        if State.SkeletonObjects[player] then
            for _, line in pairs(State.SkeletonObjects[player]) do
                line.Visible = false
            end
        end
        return
    end
    
    -- Distance check
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
            obj.HealthText.Visible = false
            obj.Tracer.Visible = false
        end
        return
    end
    
    -- Team check
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
            obj.HealthText.Visible = false
            obj.Tracer.Visible = false
        end
        return
    end
    
    local obj = State.EspObjects[player]
    if not obj then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        obj.Box.Visible = false
        obj.BoxOutline.Visible = false
        obj.Name.Visible = false
        obj.Distance.Visible = false
        obj.HealthBar.Visible = false
        obj.HealthBarBg.Visible = false
        obj.HealthText.Visible = false
        obj.Tracer.Visible = false
        return
    end
    
    local headPos = Camera:WorldToViewportPoint(head and head.Position or hrp.Position)
    
    -- Dynamic box sizing
    local height, width
    if Config.ESP.Dynamic then
        local size = char:GetExtentsSize()
        height = math.clamp(size.Y * 3, 20, 500)
        width = math.clamp(size.X * 2, 10, 300)
    else
        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        height = math.abs(headPos.Y - legPos.Y)
        width = height / 2
    end
    if height < 15 then height = 15 end
    if width < 5 then width = 5 end
    
    -- Colors
    local boxColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.BoxColor
    local nameColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.NameColor
    local tracerColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.TracerColor
    
    -- Box
    if Config.ESP.Boxes then
        obj.Box.Visible = true
        obj.BoxOutline.Visible = Config.ESP.BoxOutline
        obj.Box.Size = Vector2.new(width, height)
        obj.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
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
    
    -- Name
    if Config.ESP.Names then
        obj.Name.Visible = true
        obj.Name.Text = tostring(player.DisplayName)
        obj.Name.Position = Vector2.new(headPos.X, headPos.Y - 16)
        obj.Name.Color = nameColor
        obj.Name.Size = Config.ESP.NameSize
    else
        obj.Name.Visible = false
    end
    
    -- Distance
    if Config.ESP.Distance then
        obj.Distance.Visible = true
        obj.Distance.Text = tostring(math.floor(dist3D)) .. " studs"
        obj.Distance.Position = Vector2.new(headPos.X, headPos.Y + (height / 2) + 5)
        obj.Distance.Color = Config.ESP.DistanceColor
        obj.Distance.Size = Config.ESP.DistanceSize
    else
        obj.Distance.Visible = false
    end
    
    -- Health Bar
    if Config.ESP.HealthBars then
        local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barHeight = height
        local barWidth = 3
        local barX = (headPos.X - width / 2) - 6
        
        -- Background
        obj.HealthBarBg.Visible = true
        obj.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
        obj.HealthBarBg.Position = Vector2.new(barX, headPos.Y)
        obj.HealthBarBg.Color = Config.ESP.HealthBarBg
        obj.HealthBarBg.Filled = true
        
        -- Fill
        obj.HealthBar.Visible = true
        obj.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPct)
        obj.HealthBar.Position = Vector2.new(barX, headPos.Y + (barHeight * (1 - healthPct)))
        
        -- Color based on health
        local r = math.floor((1 - healthPct) * 255)
        local g = math.floor(healthPct * 255)
        obj.HealthBar.Color = Config.ESP.HealthBarColor or Color3.fromRGB(r, g, 0)
        obj.HealthBar.Filled = true
    else
        obj.HealthBar.Visible = false
        obj.HealthBarBg.Visible = false
        obj.HealthText.Visible = false
    end
    
    -- Tracers
    if Config.ESP.Tracers then
        obj.Tracer.Visible = true
        local origin
        if Config.ESP.TracerOrigin == "Bottom" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif Config.ESP.TracerOrigin == "Center" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else -- Mouse
            local m = UserInputService:GetMouseLocation()
            origin = Vector2.new(m.X, m.Y)
        end
        obj.Tracer.From = origin
        obj.Tracer.To = Vector2.new(headPos.X, headPos.Y)
        obj.Tracer.Color = tracerColor
        obj.Tracer.Thickness = Config.ESP.TracerThickness
    else
        obj.Tracer.Visible = false
    end
    
    -- Chams
    if Config.ESP.Cham then
        UpdateChams(player)
    elseif State.ChamsObjects[player] then
        SafeCall(function() State.ChamsObjects[player]:Destroy() end)
        State.ChamsObjects[player] = nil
    end
    
    -- Skeleton
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

local function OnPlayerRemoving(player)
    ClearESP(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

local conn1 = Players.PlayerAdded:Connect(OnPlayerAdded)
local conn2 = Players.PlayerRemoving:Connect(OnPlayerRemoving)
table.insert(State.Connections, conn1)
table.insert(State.Connections, conn2)

-- ═══════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════

SetupFOV()
SetupCrosshair()

local renderConn = RunService:BindToRenderStep("HubUpdate", Enum.RenderPriority.Camera.Value + 2, function()
    SafeCall(function()
        -- FOV
        UpdateFOV()
        
        -- Crosshair
        UpdateCrosshair()
        
        -- ESP
        for player, _ in pairs(State.EspObjects) do
            UpdateESP(player)
        end
        
        -- Aimbot
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
        
        -- Silent Aim
        if Config.SilentAim.Enabled then
            SilentAimTarget = GetSilentAimTarget()
        else
            SilentAimTarget = nil
        end
    end)
end)
table.insert(State.Connections, renderConn)

-- ═══════════════════════════════════════════════════════════
-- UI SETUP
-- ═══════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then
    warn("[Hub] Failed to load Rayfield UI")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Universal Hub — Custom Edition",
    LoadingTitle = "Loading Hub...",
    LoadingSubtitle = "Deep Customization Build",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ─── AIMBOT TAB ───
local TabAimbot = Window:CreateTab("Aimbot", 4483362458)

TabAimbot:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.Enabled = v end
})

TabAimbot:CreateToggle({
    Name = "Rage Mode (Instant Snap)",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.RageMode = v end
})

TabAimbot:CreateToggle({
    Name = "Stealth Mode (Mouse Aim)",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.MouseAim = v end
})

TabAimbot:CreateDropdown({
    Name = "Activation Key",
    Options = {"MouseButton2", "MouseButton1", "LeftShift", "LeftAlt", "RightShift", "LeftControl", "CapsLock", "None"},
    CurrentValue = "MouseButton2",
    Callback = function(v) Config.Aimbot.Keybind = v end
})

TabAimbot:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    CurrentValue = "Head",
    Callback = function(v) Config.Aimbot.AimPart = v end
})

TabAimbot:CreateDropdown({
    Name = "Sort Method",
    Options = {"Crosshair", "Distance"},
    CurrentValue = "Crosshair",
    Callback = function(v) Config.Aimbot.SortMethod = v end
})

TabAimbot:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.TeamCheck = v end
})

TabAimbot:CreateToggle({
    Name = "Wall Check (Visible Only)",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.WallCheck = v end
})

TabAimbot:CreateToggle({
    Name = "Alive Check",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.AliveCheck = v end
})

TabAimbot:CreateToggle({
    Name = "NPC Check",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.NPCCheck = v end
})

TabAimbot:CreateToggle({
    Name = "Target Lock",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.TargetLock = v end
})

TabAimbot:CreateSlider({
    Name = "Lock Break Distance",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(v) Config.Aimbot.LockBreakDistance = v end
})

TabAimbot:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v) Config.Aimbot.FOV = v end
})

TabAimbot:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.01,
    CurrentValue = 0.2,
    Callback = function(v) Config.Aimbot.Smoothness = v end
})

TabAimbot:CreateSlider({
    Name = "Prediction (seconds)",
    Range = {0, 0.5},
    Increment = 0.01,
    CurrentValue = 0,
    Callback = function(v) Config.Aimbot.Prediction = v end
})

TabAimbot:CreateSlider({
    Name = "Max Distance",
    Range = {50, 5000},
    Increment = 10,
    CurrentValue = 1000,
    Callback = function(v) Config.Aimbot.MaxDistance = v end
})

TabAimbot:CreateToggle({
    Name = "TriggerBot (Auto-Fire)",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.TriggerBot = v end
})

TabAimbot:CreateSlider({
    Name = "TriggerBot Delay",
    Range = {0, 1},
    Increment = 0.01,
    CurrentValue = 0.05,
    Callback = function(v) Config.Aimbot.TriggerDelay = v end
})

-- FOV Visual settings
TabAimbot:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Callback = function(v) Config.Aimbot.ShowFOV = v end
})

TabAimbot:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(v) Config.Aimbot.FOVColor = v end
})

TabAimbot:CreateSlider({
    Name = "FOV Circle Thickness",
    Range = {0.5, 5},
    Increment = 0.1,
    CurrentValue = 1.5,
    Callback = function(v) Config.Aimbot.FOVThickness = v end
})

TabAimbot:CreateToggle({
    Name = "Fill FOV Circle",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot.FOVFilled = v end
})

TabAimbot:CreateSlider({
    Name = "FOV Circle Transparency",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.5,
    Callback = function(v) Config.Aimbot.FOVTransparency = v end
})

TabAimbot:CreateSlider({
    Name = "FOV Circle Sides",
    Range = {3, 100},
    Increment = 1,
    CurrentValue = 60,
    Callback = function(v) Config.Aimbot.FOVNumSides = v end
})

-- ─── SILENT AIM TAB ───
local TabSilent = Window:CreateTab("Silent Aim", 4483362458)

TabSilent:CreateToggle({
    Name = "Enable Silent Aim",
    CurrentValue = false,
    Callback = function(v) Config.SilentAim.Enabled = v end
})

TabSilent:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
    CurrentValue = "Head",
    Callback = function(v) Config.SilentAim.TargetPart = v end
})

TabSilent:CreateSlider({
    Name = "FOV",
    Range = {10, 500},
    Increment = 1,
    CurrentValue = 80,
    Callback = function(v) Config.SilentAim.FOV = v end
})

TabSilent:CreateSlider({
    Name = "Hit Chance (%)",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v) Config.SilentAim.HitChance = v end
})

TabSilent:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.SilentAim.TeamCheck = v end
})

TabSilent:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(v) Config.SilentAim.WallCheck = v end
})

-- ─── ESP TAB ───
local TabESP = Window:CreateTab("Visuals / ESP", 4483362458)

TabESP:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(v) Config.ESP.Enabled = v end
})

TabESP:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(v) Config.ESP.TeamCheck = v end
})

TabESP:CreateToggle({
    Name = "Use Team Colors",
    CurrentValue = false,
    Callback = function(v) Config.ESP.UseTeamColors = v end
})

TabESP:CreateToggle({
    Name = "Dynamic ESP (Creatures/Monsters)",
    CurrentValue = true,
    Callback = function(v) Config.ESP.Dynamic = v end
})

TabESP:CreateSlider({
    Name = "Max Distance",
    Range = {50, 5000},
    Increment = 10,
    CurrentValue = 1000,
    Callback = function(v) Config.ESP.MaxDistance = v end
})

-- Boxes
TabESP:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Config.ESP.Boxes = v end})
TabESP:CreateToggle({Name = "Box Outline", CurrentValue = true, Callback = function(v) Config.ESP.BoxOutline = v end})
TabESP:CreateToggle({Name = "Box Fill", CurrentValue = false, Callback = function(v) Config.ESP.BoxFilled = v end})
TabESP:CreateColorPicker({Name = "Box Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.BoxColor = v end})
TabESP:CreateSlider({Name = "Box Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.BoxThickness = v end})
TabESP:CreateSlider({Name = "Box Fill Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.7, Callback = function(v) Config.ESP.BoxFillTransparency = v end})

-- Names
TabESP:CreateToggle({Name = "Names", CurrentValue = true, Callback = function(v) Config.ESP.Names = v end})
TabESP:CreateColorPicker({Name = "Name Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Config.ESP.NameColor = v end})
TabESP:CreateSlider({Name = "Name Size", Range = {8, 24}, Increment = 1, CurrentValue = 13, Callback = function(v) Config.ESP.NameSize = v end})

-- Distance
TabESP:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Config.ESP.Distance = v end})
TabESP:CreateColorPicker({Name = "Distance Color", Color = Color3.fromRGB(200, 200, 200), Callback = function(v) Config.ESP.DistanceColor = v end})
TabESP:CreateSlider({Name = "Distance Size", Range = {8, 24}, Increment = 1, CurrentValue = 13, Callback = function(v) Config.ESP.DistanceSize = v end})

-- Health
TabESP:CreateToggle({Name = "Health Bars", CurrentValue = true, Callback = function(v) Config.ESP.HealthBars = v end})
TabESP:CreateColorPicker({Name = "Health Bar Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(v) Config.ESP.HealthBarColor = v end})

-- Tracers
TabESP:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) Config.ESP.Tracers = v end})
TabESP:CreateColorPicker({Name = "Tracer Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.TracerColor = v end})
TabESP:CreateSlider({Name = "Tracer Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.TracerThickness = v end})
TabESP:CreateDropdown({Name = "Tracer Origin", Options = {"Bottom", "Center", "Mouse"}, CurrentValue = "Bottom", Callback = function(v) Config.ESP.TracerOrigin = v end})

-- Chams
TabESP:CreateToggle({Name = "Chams (Highlight)", CurrentValue = false, Callback = function(v) Config.ESP.Cham = v end})
TabESP:CreateColorPicker({Name = "Chams Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) Config.ESP.ChamColor = v end})
TabESP:CreateSlider({Name = "Chams Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Callback = function(v) Config.ESP.ChamTransparency = v end})
TabESP:CreateColorPicker({Name = "Chams Outline Color", Color = Color3.fromRGB(0, 0, 0), Callback = function(v) Config.ESP.ChamOutlineColor = v end})

-- Skeleton
TabESP:CreateToggle({Name = "Skeleton ESP", CurrentValue = false, Callback = function(v) Config.ESP.Skeleton = v end})
TabESP:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) Config.ESP.SkeletonColor = v end})
TabESP:CreateSlider({Name = "Skeleton Thickness", Range = {0.5, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) Config.ESP.SkeletonThickness = v end})

-- ─── CROSSHAIR TAB ───
local TabCrosshair = Window:CreateTab("Crosshair", 4483362458)

TabCrosshair:CreateToggle({
    Name = "Enable Custom Crosshair",
    CurrentValue = false,
    Callback = function(v) Config.Crosshair.Enabled = v end
})

TabCrosshair:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(v) Config.Crosshair.Color = v end
})

TabCrosshair:CreateSlider({
    Name = "Size",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v) Config.Crosshair.Size = v end
})

TabCrosshair:CreateSlider({
    Name = "Gap",
    Range = {0, 20},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v) Config.Crosshair.Gap = v end
})

TabCrosshair:CreateSlider({
    Name = "Thickness",
    Range = {0.5, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(v) Config.Crosshair.Thickness = v end
})

TabCrosshair:CreateToggle({
    Name = "Center Dot",
    CurrentValue = false,
    Callback = function(v) Config.Crosshair.Dot = v end
})

TabCrosshair:CreateSlider({
    Name = "Dot Size",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v) Config.Crosshair.DotSize = v end
})

TabCrosshair:CreateToggle({
    Name = "Outline",
    CurrentValue = true,
    Callback = function(v) Config.Crosshair.Outline = v end
})

-- ─── SETTINGS TAB ───
local TabSettings = Window:CreateTab("Settings", 4483362458)

TabSettings:CreateToggle({
    Name = "Notifications",
    CurrentValue = true,
    Callback = function(v) Config.UI.Notifications = v end
})

TabSettings:CreateToggle({
    Name = "Watermark",
    CurrentValue = true,
    Callback = function(v) Config.UI.Watermark = v end
})

TabSettings:CreateButton({
    Name = "Unload Script",
    Callback = function()
        -- Clean up ESP
        for player, _ in pairs(State.EspObjects) do
            ClearESP(player)
        end
        
        -- Clean up FOV
        if State.FOVCircle then
            State.FOVCircle:Remove()
            State.FOVCircle = nil
        end
        
        -- Clean up crosshair
        for _, line in ipairs(State.CrosshairLines) do
            line:Remove()
        end
        if State.CrosshairDot then
            State.CrosshairDot:Remove()
        end
        
        -- Disconnect
        for _, conn in ipairs(State.Connections) do
            SafeCall(function() conn:Disconnect() end)
        end
        
        RunService:UnbindFromRenderStep("HubUpdate")
        
        -- Restore namecall
        if oldNamecall then
            hookmetamethod(game, "__namecall", oldNamecall)
        end
        
        Rayfield:Destroy()
    end
})

TabSettings:CreateButton({
    Name = "Copy Config to Clipboard",
    Callback = function()
        Notify("Config", "Config export feature - check console output", 3)
        print("=== CONFIG EXPORT ===")
        for section, values in pairs(Config) do
            print("[" .. section .. "]")
            for key, value in pairs(values) do
                print("  " .. key .. " = " .. tostring(value))
            end
        end
        print("=== END EXPORT ===")
    end
})

TabSettings:CreateButton({
    Name = "Reset All ESP",
    Callback = function()
        for player, _ in pairs(State.EspObjects) do
            ClearESP(player)
            CreateESP(player)
        end
        Notify("ESP", "All ESP objects reset", 3)
    end
})

TabSettings:CreateButton({
    Name = "Force Refresh Targets",
    Callback = function()
        State.CurrentTarget = nil
        Notify("Aimbot", "Target cache cleared", 3)
    end
})

-- ═══════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════

State.Loaded = true

Notify("Universal Hub", "Loaded successfully! All features ready.", 5)
print("[Hub] Universal Aimbot & ESP Hub — Deep Customization Edition loaded.")
print("[Hub] Features: Aimbot, Silent Aim, ESP, Chams, Skeleton, Crosshair, TriggerBot")
print("[Hub] Press RightControl to toggle UI")

-- UI Toggle keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.UI.ToggleKey then
        Rayfield:Toggle()
    end
end)
