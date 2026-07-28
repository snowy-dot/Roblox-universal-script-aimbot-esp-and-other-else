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
    
    -- ═══════════════════════════════════════════
    -- ACCURATE BOX SIZING — screen-space from body parts
    -- ═══════════════════════════════════════════
    
    -- Get screen positions of key body parts
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head and head.Position or hrp.Position)
    
    -- Find the lowest point on the character for box bottom
    local lowestY = headPos.Y
    local lowestPart = nil
    
    -- Check legs (R15)
    local leftFoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
    local rightFoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")
    local leftLowerLeg = char:FindFirstChild("LeftLowerLeg")
    local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
    
    -- Check foot positions
    for _, partName in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg", "LeftLowerLeg", "RightLowerLeg"}) do
        local part = char:FindFirstChild(partName)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and screenPos.Y > lowestY then
                lowestY = screenPos.Y
            end
        end
    end
    
    -- Fallback: use HRP position offset downward
    local hrpScreenPos, hrpOnScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not hrpOnScreen then
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
    
    -- If we couldn't find a lower point, estimate from HRP
    if lowestY <= headPos.Y then
        -- Estimate: HRP is roughly at torso center, character is ~5 studs tall
        -- Project a point 3 studs below HRP
        local bottomWorld = hrp.Position - Vector3.new(0, 3, 0)
        local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomWorld)
        if bottomOnScreen then
            lowestY = bottomScreen.Y
        else
            lowestY = hrpScreenPos.Y + (hrpScreenPos.Y - headPos.Y) * 2
        end
    end
    
    -- Calculate shoulder width for box width
    local leftShoulder, rightShoulder
    local humRig = hum.RigType
    
    if humRig == Enum.HumanoidRigType.R15 then
        leftShoulder = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        rightShoulder = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    else
        leftShoulder = char:FindFirstChild("Left Arm")
        rightShoulder = char:FindFirstChild("Right Arm")
    end
    
    local leftX, rightX
    if leftShoulder then
        local pos, onScreen = Camera:WorldToViewportPoint(leftShoulder.Position)
        if onScreen then leftX = pos.X end
    end
    if rightShoulder then
        local pos, onScreen = Camera:WorldToViewportPoint(rightShoulder.Position)
        if onScreen then rightX = pos.X end
    end
    
    local width, height
    local centerX, topY
    
    if leftX and rightX then
        -- Width from actual shoulder positions
        width = math.abs(rightX - leftX)
        -- Add padding so the box isn't tight on the body
        width = width * 1.15
        centerX = (leftX + rightX) / 2
    else
        -- Fallback: calculate width from height ratio
        height = math.abs(lowestY - headPos.Y)
        width = height * 0.5
        centerX = headPos.X
    end
    
    -- Height from head to lowest foot point
    height = math.abs(lowestY - headPos.Y)
    
    -- Dynamic mode: if enabled, use GetExtentsSize as a modifier but not the primary source
    if Config.ESP.Dynamic then
        -- Get the character's actual size for sanity checking
        local extents = char:GetExtentsSize()
        -- Only use extents if our calculated height seems wrong (too small)
        local expectedHeight = math.clamp(extents.Y * 200 / math.max(dist3D, 1), 20, 500)
        if height < expectedHeight * 0.5 then
            height = expectedHeight
        end
    end
    
    -- Minimum size clamps
    if height < 15 then height = 15 end
    if width < 8 then width = 8 end
    
    -- Box position: centered horizontally on character, top at head
    topY = headPos.Y - (height * 0.1) -- slight offset above head for cleaner look
    local boxX = centerX - (width / 2)
    
    -- Recalculate center for other elements
    local boxCenterY = topY + (height / 2)
    
    -- Colors
    local boxColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.BoxColor
    local nameColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.NameColor
    local tracerColor = Config.ESP.UseTeamColors and GetTeamColor(player) or Config.ESP.TracerColor
    
    -- ═══════════════════════════════════════════
    -- DRAW BOX
    -- ═══════════════════════════════════════════
    
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
    
    -- ═══════════════════════════════════════════
    -- NAME
    -- ═══════════════════════════════════════════
    
    if Config.ESP.Names then
        obj.Name.Visible = true
        obj.Name.Text = tostring(player.DisplayName)
        obj.Name.Position = Vector2.new(centerX, topY - 16)
        obj.Name.Color = nameColor
        obj.Name.Size = Config.ESP.NameSize
    else
        obj.Name.Visible = false
    end
    
    -- ═══════════════════════════════════════════
    -- DISTANCE
    -- ═══════════════════════════════════════════
    
    if Config.ESP.Distance then
        obj.Distance.Visible = true
        obj.Distance.Text = tostring(math.floor(dist3D)) .. " studs"
        obj.Distance.Position = Vector2.new(centerX, lowestY + 5)
        obj.Distance.Color = Config.ESP.DistanceColor
        obj.Distance.Size = Config.ESP.DistanceSize
    else
        obj.Distance.Visible = false
    end
    
    -- ═══════════════════════════════════════════
    -- HEALTH BAR
    -- ═══════════════════════════════════════════
    
    if Config.ESP.HealthBars then
        local healthPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barHeight = height
        local barWidth = 3
        local barX = boxX - 6
        
        -- Background
        obj.HealthBarBg.Visible = true
        obj.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
        obj.HealthBarBg.Position = Vector2.new(barX, topY)
        obj.HealthBarBg.Color = Config.ESP.HealthBarBg
        obj.HealthBarBg.Filled = true
        
        -- Fill (grows from bottom)
        obj.HealthBar.Visible = true
        obj.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPct)
        obj.HealthBar.Position = Vector2.new(barX, topY + (barHeight * (1 - healthPct)))
        
        -- Health color: green -> yellow -> red
        local r = math.floor((1 - healthPct) * 255)
        local g = math.floor(healthPct * 255)
        local b = 0
        if healthPct > 0.5 then
            -- green to yellow
            r = math.floor((1 - (healthPct - 0.5) * 2) * 255)
            g = 255
        else
            -- yellow to red
            r = 255
            g = math.floor(healthPct * 2 * 255)
        end
        obj.HealthBar.Color = Color3.fromRGB(r, g, b)
        obj.HealthBar.Filled = true
    else
        obj.HealthBar.Visible = false
        obj.HealthBarBg.Visible = false
        obj.HealthText.Visible = false
    end
    
    -- ═══════════════════════════════════════════
    -- TRACERS
    -- ═══════════════════════════════════════════
    
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
        -- Tracer goes to character center (torso area)
        obj.Tracer.From = origin
        obj.Tracer.To = Vector2.new(centerX, boxCenterY)
        obj.Tracer.Color = tracerColor
        obj.Tracer.Thickness = Config.ESP.TracerThickness
    else
        obj.Tracer.Visible = false
    end
    
    -- ═══════════════════════════════════════════
    -- CHAMS
    -- ═══════════════════════════════════════════
    
    if Config.ESP.Cham then
        UpdateChams(player)
    elseif State.ChamsObjects[player] then
        SafeCall(function() State.ChamsObjects[player]:Destroy() end)
        State.ChamsObjects[player] = nil
    end
    
    -- ═══════════════════════════════════════════
    -- SKELETON
    -- ═══════════════════════════════════════════
    
    UpdateSkeleton(player, char)
end
