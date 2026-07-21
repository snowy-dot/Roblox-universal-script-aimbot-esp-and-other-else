--!nocheck
-- SIMPLE ESP TEST

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

-- ESP GUI Setup
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "SimpleESP"
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

local espObjects = {}
local espEnabled = false

local function createESP(player)
    if espObjects[player] then
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

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.Parent = frame

    espObjects[player] = {Frame = frame, Box = box, Name = nameLbl}
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].Frame:Destroy()
        espObjects[player] = nil
    end
end

Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not espEnabled then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            if not espObjects[player] then
                createESP(player)
            end

            local obj = espObjects[player]
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

                        obj.Box.Position = UDim2.fromOffset(headScreen.X - width/2, headScreen.Y)
                        obj.Box.Size = UDim2.fromOffset(width, height)
                        obj.Box.Visible = true

                        obj.Name.Position = UDim2.fromOffset(headScreen.X, headScreen.Y - 15)
                        obj.Name.Text = player.Name
                        obj.Name.Visible = true
                    else
                        obj.Box.Visible = false
                        obj.Name.Visible = false
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                end
            else
                obj.Box.Visible = false
                obj.Name.Visible = false
            end
        end
    end
end)

-- UI Setup
local WindowConfig = {
    Name = "Simple ESP",
    LoadingTitle = "ESP Test",
    LoadingSubtitle = "by Rayfield",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
}
local Window = Rayfield:CreateWindow(WindowConfig)

local Tab = Window:CreateTab("Main", 4483362458)

local ToggleConfig = {
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            for player, obj in pairs(espObjects) do
                obj.Box.Visible = false
                obj.Name.Visible = false
            end
        end
    end
}
Tab:CreateToggle(ToggleConfig)

local NotifyConfig = {
    Title = "Simple ESP",
    Content = "Loaded! Press RightCtrl to toggle UI.",
    Duration = 3
}
Rayfield:Notify(NotifyConfig)
