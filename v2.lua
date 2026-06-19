local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        return
    end
end)

--[[
    ================================================================================
    --|                                                                          |--
    --|           PROJECT DELTA V8 ULTIMATE - REBUILT & MODULARIZED              |--
    --|                             Author  : RomeoZach                          |--
    --|                                                                          |--
    ================================================================================
]]

local success, err = pcall(function()

    --[[
        ================================================
        --        MODULE 1: CORE CONFIG & UI SETUP    --
        ================================================
    ]]
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Stats = game:GetService("Stats")
    local GuiService = game:GetService("GuiService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local ESP_Config = {
        AimLock = false,
        ESP_Players = true,
        ESP_Corpses = false,
        ESP_Loot = false,
        ESP_Containers = false,
        BulletTracers = false,
        Crosshair = false,
        VisCheck = true,
        GunMods = false, 
        FindWeapons = true, 
        FindValuables = true, 
        FindKeys = true,
        FindAttachments = true,
        PerformanceMode = false,
        Color = Color3.fromRGB(255, 255, 255),
        WeaponColor = Color3.fromRGB(255, 255, 0),
        BulletColor = Color3.fromRGB(255, 255, 0),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        FovRadius = 300
    }

    local COLOR_VISIBLE = ESP_Config.Color
    local COLOR_BLOCKED = Color3.fromRGB(160, 160, 165)
    local COLOR_DEAD    = Color3.fromRGB(221, 160, 221)
    local COLOR_TEAM_VISIBLE = Color3.fromRGB(50, 255, 50)
    local COLOR_TEAM_BLOCKED = Color3.fromRGB(0, 150, 0)

    local ESP_Objects = {}
    local IsAiming = false
    local CurrentTargetEntity = nil
    local CurrentTargetChar = nil
    local CrosshairLines = {}
    local AmmoBackups = {} 
    local TextureBackups = {}
    local DisabledEffects = {}
    local LastPerformanceState = false

    local LightingBackups = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        FogColor = Lighting.FogColor
    }

    local WallbangableMaterials = {
        [Enum.Material.Wood] = true,
        [Enum.Material.WoodPlanks] = true,
        [Enum.Material.Fabric] = true,
        [Enum.Material.Plastic] = true,
        [Enum.Material.Glass] = true,
        [Enum.Material.Cardboard] = true,
        [Enum.Material.Sand] = true
    }

    local sharedRaycastParams = RaycastParams.new()
    sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    sharedRaycastParams.IgnoreWater = true
    local ignoreList = {}

    local targetGui = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui", 15)
    
    local oldUi = targetGui:FindFirstChild("RomeoZach_Ui")
    if oldUi then
        pcall(function()
            oldUi:Destroy()
        end)
        task.wait(0.2)
    end

    local RomeoZachGui = Instance.new("ScreenGui")
    RomeoZachGui.Name = "RomeoZach_Ui"
    RomeoZachGui.ResetOnSpawn = false
    RomeoZachGui.DisplayOrder = 999999
    RomeoZachGui.IgnoreGuiInset = true
    RomeoZachGui.Parent = targetGui

    local chX = Instance.new("Frame", RomeoZachGui)
    chX.Size = UDim2.new(0, 14, 0, 2)
    chX.Position = UDim2.new(0.5, -7, 0.5, -1)
    chX.BackgroundColor3 = ESP_Config.Color
    chX.BorderSizePixel = 0
    chX.Visible = ESP_Config.Crosshair
    local strokeX = Instance.new("UIStroke", chX)
    strokeX.Thickness = 1
    table.insert(CrosshairLines, chX)

    local chY = Instance.new("Frame", RomeoZachGui)
    chY.Size = UDim2.new(0, 2, 0, 14)
    chY.Position = UDim2.new(0.5, -1, 0.5, -7)
    chY.BackgroundColor3 = ESP_Config.Color
    chY.BorderSizePixel = 0
    chY.Visible = ESP_Config.Crosshair
    local strokeY = Instance.new("UIStroke", chY)
    strokeY.Thickness = 1
    table.insert(CrosshairLines, chY)

    local MainFrame = Instance.new("Frame", RomeoZachGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 480, 0, 260) 
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true

    local cornerMain = Instance.new("UICorner", MainFrame)
    cornerMain.CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1
    MainStroke.Color = Color3.fromRGB(45, 48, 53)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Header = Instance.new("TextLabel", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundTransparency = 1
    Header.Text = "Project Delta V8 - Ultimate"
    Header.TextColor3 = Color3.fromRGB(240, 240, 245)
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.TextXAlignment = Enum.TextXAlignment.Center

    local ContainerUI = Instance.new("Frame", MainFrame)
    ContainerUI.Size = UDim2.new(1, -20, 1, -45)
    ContainerUI.Position = UDim2.new(0, 10, 0, 35)
    ContainerUI.BackgroundTransparency = 1

    local UIGridLayout = Instance.new("UIGridLayout", ContainerUI)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    UIGridLayout.CellSize = UDim2.new(0.5, -5, 0, 40)

    local function CreateToggle(labelText, configKey)
        local Frame = Instance.new("Frame", ContainerUI)
        Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27)
        Frame.BorderSizePixel = 0
        local cornerFrame = Instance.new("UICorner", Frame)
        cornerFrame.CornerRadius = UDim.new(0, 6)

        local Label = Instance.new("TextLabel", Frame)
        Label.Size = UDim2.new(0.65, 0, 1, 0)
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = labelText
        Label.TextColor3 = Color3.fromRGB(200, 200, 205)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local Track = Instance.new("Frame", Frame)
        Track.Size = UDim2.new(0, 40, 0, 20)
        Track.Position = UDim2.new(1, -50, 0.5, -10)
        Track.BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
        local cornerTrack = Instance.new("UICorner", Track)
        cornerTrack.CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame", Track)
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = ESP_Config[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        local cornerKnob = Instance.new("UICorner", Knob)
        cornerKnob.CornerRadius = UDim.new(1, 0)

        local Btn = Instance.new("TextButton", Track)
        Btn.Size = UDim2.new(1, 0, 1, 0)
        Btn.BackgroundTransparency = 1
        Btn.Text = ""

        Btn.MouseButton1Click:Connect(function()
            ESP_Config[configKey] = not ESP_Config[configKey]
            local isActive = ESP_Config[configKey]
            
            local trackTweenInfo = TweenInfo.new(0.2)
            local trackProp = {BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}
            TweenService:Create(Track, trackTweenInfo, trackProp):Play()
            
            local knobTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local knobProp = {Position = isActive and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}
            TweenService:Create(Knob, knobTweenInfo, knobProp):Play()

            if configKey == "AimLock" and not ESP_Config.AimLock then
                CurrentTargetChar = nil
            end
            
            if configKey == "Crosshair" then
                for _, line in ipairs(CrosshairLines) do
                    line.Visible = ESP_Config.Crosshair
                end
            end
        end)
        
        return Frame
    end

    local PlayerESPBtn = CreateToggle("ESP - Players & AI", "ESP_Players")
    local CorpseESPBtn = CreateToggle("ESP - Corpses", "ESP_Corpses")
    local LootESPBtn = CreateToggle("ESP - Loose Loot", "ESP_Loot")
    local ContainerESPBtn = CreateToggle("ESP - Valuable Containers", "ESP_Containers")
    local LockBtn = CreateToggle("Enable AimLock", "AimLock")
    local BulletTracersBtn = CreateToggle("Yellow Bullet Tracers", "BulletTracers")
    local CrosshairBtn = CreateToggle("Tiny Center Crosshair", "Crosshair")
    local GunModsBtn = CreateToggle("No Recoil & No Spread", "GunMods")
    local PerformanceBtn = CreateToggle("Performance Mode", "PerformanceMode")
    local VisCheckBtn = CreateToggle("ESP Wall Check", "VisCheck")

    --[[
        ================================================
        --        MODULE 2: INPUT & UTILITIES         --
        ================================================
    ]]
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.RightShift and not gp then
            MainFrame.Visible = not MainFrame.Visible
        end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            IsAiming = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            IsAiming = false
        end
    end)

    local function GetBulletSpeed()
        local defaultSpeed = 1500
        local char = LocalPlayer.Character
        if not char then return defaultSpeed end
        
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local settingsModule = tool:FindFirstChild("Setting") or tool:FindFirstChild("WeaponSettings")
            if settingsModule and settingsModule:IsA("ModuleScript") then
                local s, data = pcall(require, settingsModule)
                if s and type(data) == "table" then
                    return data.BulletSpeed or data.MuzzleVelocity or defaultSpeed
                end
            end
        end
        return defaultSpeed
    end

    local function IsEntityDead(char)
        if not char or typeof(char) ~= "Instance" or not char.Parent then return false end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.Health <= 0 or hum.Health ~= hum.Health then return true end
            if hum:GetState() == Enum.HumanoidStateType.Dead then return true end
            return false
        end
        
        local nameLower = string.lower(char.Name)
        if char:IsA("Model") then
            if char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") then
                if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
                    return true 
                end
                return false
            end
            return false
        end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
            return true 
        end
        
        return false
    end

    local function IsTeammate(char)
        if not char then return false end
        local lpName = LocalPlayer.Name
        local targetName = char.Name
        local rsPlayers = ReplicatedStorage:FindFirstChild("Players")
        if rsPlayers then
            local lpData = rsPlayers:FindFirstChild(lpName)
            local targetData = rsPlayers:FindFirstChild(targetName)
            if lpData and targetData then
                local lpStatus = lpData:FindFirstChild("Status")
                local targetStatus = targetData:FindFirstChild("Status")
                if lpStatus and targetStatus then
                    local lpJourney = lpStatus:FindFirstChild("Journey")
                    local targetJourney = targetStatus:FindFirstChild("Journey")
                    if lpJourney and targetJourney then
                        local lpClanFolder = lpJourney:FindFirstChild("Clan")
                        local targetClanFolder = targetJourney:FindFirstChild("Clan")
                        if lpClanFolder and targetClanFolder then
                            local lpClan = lpClanFolder:GetAttribute("CurrentClan")
                            local targetClan = targetClanFolder:GetAttribute("CurrentClan")
                            if lpClan and targetClan and lpClan ~= "" and lpClan ~= "nil" and lpClan == targetClan then
                                return true
                            end
                        end
                    end
                end
            end
        end
        
        local targetPlayer = Players:GetPlayerFromCharacter(char)
        if targetPlayer and targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team == LocalPlayer.Team then
            return true
        end
        return false
    end

    --[[
        ================================================
        --        MODULE 3: VISIBILITY ENGINE         --
        ================================================
    ]]
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)

        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        local distance = direction.Magnitude
        
        if distance < 7 then
            return "Visible", true
        end

        if not ESP_Config.VisCheck then
            return "Visible", true
        end
        
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then
            return "Blocked", false
        end
        
        table.insert(ignoreList, lpChar)
        table.insert(ignoreList, Camera)
        if targetChar then
            table.insert(ignoreList, targetChar)
        end
        
        local loopCounter = 0
        local isWallbangable = false

        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 30 then
                if isWallbangable then
                    return "Wallbangable", true
                else
                    return "Blocked", false
                end
            end

            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

            if not raycastResult then
                if isWallbangable then
                    return "Wallbangable", true
                else
                    return "Visible", true
                end
            end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then
                if isWallbangable then
                    return "Wallbangable", true
                else
                    return "Blocked", false
                end
            end
            
            if hitInstance:IsDescendantOf(targetChar) then
                if isWallbangable then
                    return "Wallbangable", true
                else
                    return "Visible", true
                end
            end

            local mat = raycastResult.Material
            local nameLow = hitInstance.Name:lower()
            local wallbang = WallbangableMaterials[mat] or hitInstance.Transparency >= 0.8 or nameLow:find("grass") or nameLow:find("glass") or nameLow:find("ignore") or hitInstance.CanCollide == false
            
            if wallbang then
                isWallbangable = true
                table.insert(ignoreList, hitInstance)
            else
                return "Blocked", false
            end
        end
    end

    local function GetBestTargetInFOV()
        local bestEntity = nil
        local bestChar = nil
        local shortestPixelDist = 300
        local centerPos = Camera.ViewportSize / 2
        local origin = Camera.CFrame.Position
        
        for entity, box in pairs(ESP_Objects) do
            local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            if char and char ~= LocalPlayer.Character and char.Parent then
                if IsTeammate(char) then
                    continue
                end

                local head = char:FindFirstChild("Head")
                if not head then
                    head = char:FindFirstChild("HumanoidRootPart")
                end
                
                if head and not IsEntityDead(char) then
                    local visStatus, canLock = checkTargetVisibility(head, char)
                    if not canLock then
                        continue
                    end

                    local studsDist = (origin - head.Position).Magnitude
                    local isPlayer = (typeof(entity) == "Instance" and entity:IsA("Player")) or Players:GetPlayerFromCharacter(char) ~= nil
                    
                    if isPlayer and studsDist > 3571.4 then continue end
                    if not isPlayer and studsDist > 1607.1 then continue end

                    local bulletSpeed = GetBulletSpeed()
                    if bulletSpeed <= 0 then
                        bulletSpeed = 1500
                    end
                    local timeToTarget = studsDist / bulletSpeed
                    
                    local currentVelocity = head.AssemblyLinearVelocity
                    if currentVelocity.X ~= currentVelocity.X then
                        currentVelocity = Vector3.new(0, 0, 0)
                    end
                    
                    local dropCompensation = 0
                    if not ESP_Config.GunMods then
                        dropCompensation = (0.5 * workspace.Gravity * (timeToTarget * timeToTarget))
                    end
                    
                    local predictedPos = head.Position + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        if screenDist < shortestPixelDist then
                            shortestPixelDist = screenDist
                            bestEntity = entity
                            bestChar = char
                        end
                    end
                end
            end
        end
        return bestEntity, bestChar
    end

    --[[
        ================================================
        --      MODULE 4: ESP MANAGER (REVISED)       --
        ================================================
    ]]
    local function RemoveESP(entity)
        if ESP_Objects[entity] then
            local box = ESP_Objects[entity]
            if box.Highlight then
                box.Highlight:Destroy()
            end
            if box.DistBillboard then
                box.DistBillboard:Destroy()
            end
            if box.Highlight_Item then
                box.Highlight_Item:Destroy()
            end
            if box.Billboard_Item then
                box.Billboard_Item:Destroy()
            end
            if box.Connection then
                box.Connection:Disconnect()
            end
            ESP_Objects[entity] = nil
        end
    end

    local function CreateESP(entity, isPlayer)
        if isPlayer and entity == LocalPlayer then return end
        if ESP_Objects[entity] then return end

        local box = {
            Highlight = nil,
            DistBillboard = nil,
            DistLabel = nil,
            Connection = nil,
            CanBeAimlocked = false,
            IsHelicopter = false
        }
        
        local function ApplyVisuals(char)
            if not char then return end
            
            if not isPlayer then
                task.wait(0.5)
                if not char or not char.Parent then return end 
            end

            if box.Highlight then
                box.Highlight:Destroy()
            end
            if box.DistBillboard then
                box.DistBillboard:Destroy()
            end

            box.Character = char
            
            local rootPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
            local initialVisColor = COLOR_BLOCKED
            
            if rootPart then
                local visStatus, canLock = checkTargetVisibility(rootPart, char)
                if canLock then
                    initialVisColor = ESP_Config.Color
                end
            end

            local hl = Instance.new("Highlight", char)
            hl.FillColor = initialVisColor
            hl.OutlineColor = initialVisColor
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            box.Highlight = hl
            
            local distBb = Instance.new("BillboardGui", char)
            distBb.Name = "RomeoZach_DistBillboard"
            distBb.Size = UDim2.new(0, 200, 0, 50)
            distBb.AlwaysOnTop = true
            distBb.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LeftFoot")
            distBb.StudsOffset = Vector3.new(0, -4.5, 0)
            box.DistBillboard = distBb
            
            local distTxt = Instance.new("TextLabel", distBb)
            distTxt.Size = UDim2.new(1, 0, 1, 0)
            distTxt.BackgroundTransparency = 1
            distTxt.Text = ""
            distTxt.TextColor3 = initialVisColor
            distTxt.TextSize = 13
            distTxt.Font = ESP_Config.Font
            distTxt.TextStrokeTransparency = 0
            distTxt.TextYAlignment = Enum.TextYAlignment.Top
            local uiStroke = Instance.new("UIStroke", distTxt)
            uiStroke.Thickness = 1.5
            box.DistLabel = distTxt
        end
        
        if isPlayer then 
            if entity.Character then
                ApplyVisuals(entity.Character)
            end
            box.Connection = entity.CharacterAdded:Connect(ApplyVisuals) 
        else 
            ApplyVisuals(entity) 
        end
        ESP_Objects[entity] = box
    end

    --[[
        ================================================
        --        MODULE 5: SCANNER UTILITIES         --
        ================================================
    ]]
    local function IsValidEntity(obj)
        if not obj:IsA("Model") then return false end
        if obj.Name == LocalPlayer.Name or (LocalPlayer.Character and obj == LocalPlayer.Character) then return false end
        if obj:IsDescendantOf(Camera) then return false end
        
        local nameLower = string.lower(obj.Name)
        
        if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or nameLower:find("bag") or nameLower:find("satchel") or nameLower:find("register") or nameLower:find("safe") or nameLower:find("vault") or nameLower:find("desk") or nameLower:find("boulder") or nameLower:find("mesh") then
            return false
        end
        
        if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") then return false end

        if not obj:FindFirstChildOfClass("Shirt") and not obj:FindFirstChildOfClass("Pants") then
            if not (nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll")) then
                return false
            end
        end

        local npcKeywords = {"dozer", "anton", "guard", "bandit", "rat", "sniper", "marksman", "highway", "tunnel", "occupant", "survey", "team", "member", "soldier", "whisper", "scav", "king", "uno", "peace", "keeper", "death"}
        for _, kw in ipairs(npcKeywords) do
            if nameLower:find(kw) then return true end
        end

        if obj:FindFirstChildOfClass("Tool") then return true end
        if obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then return true end
        
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
            return true 
        end
        
        return false
    end

    local function GetValuableMatch(desc)
        local nLower = string.lower(desc.Name)

        if nLower:find("cashierdesk") or nLower:find("desk") or nLower:find("boulder") or nLower:find("mesh") then return false, nil end

        local blacklistKeywords = {"cashierdesk", "cashier_desk", "desk", "boulder", "mesh", "wall", "floor", "terrain", "stair", "door", "window", "roof", "building", "fence", "glass", "medium"}
        for _, kw in ipairs(blacklistKeywords) do
            if nLower:find(kw) then return false, nil end
        end

        if ESP_Config.FindWeapons then
            local weaponKeywords = {
                "golden", "mp5sd", "val", "asval", "m4a1", "m4", "fn-fal", "fal", 
                "svd", "pkm", "r700", "remington", "tfz", "mod-98", "mod98", "rpg-7", "rpg7", 
                "akmn", "saiga", "flare", "flaregun", "spsh-44", "spsh44"
            }
            for _, kw in ipairs(weaponKeywords) do
                local escapedKw = kw:gsub("%-", "%%-")
                if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then 
                    return true, desc.Name 
                end
            end
        end
        if ESP_Config.FindValuables then
            if nLower:find("mount") or nLower:find("helmet") or nLower:find("headset") then
                local highValueOptics = {"nvg", "goggles", "reap-ir", "reapir", "thermal", "onv-9", "onv9", "quadnvg", "quad"}
                for _, optic_kw in ipairs(highValueOptics) do
                    if nLower:find(optic_kw) then
                        return true, "HIGH-VALUE NIGHT VISION MOUNT"
                    end
                end
            end

            local valuableKeywords = {
                "solter", "gold", "sps", "watch", "tix", "ticket", 
                "cpu", "ram", "ssd", "gpu", "smartphone", "phone",
                "ruble", "rubles", "cash", "money",
                "nvg", "goggles", "reap-ir", "reapir", "thermal", "onv-9", "onv9", "quadnvg", "quad"
            }
            for _, kw in ipairs(valuableKeywords) do 
                local escapedKw = kw:gsub("%-", "%%-")
                if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then
                    return true, desc.Name
                end
            end
        end
        if ESP_Config.FindKeys then
            local keyKeywords = {
                "key", "keycard", "card", "access", "secure", "dorm", "marked", "factory", "resort", "lab", 
                "sanitar", "manager", "kiba", "bunker", "garage", "airfield", "village", "fueling", 
                "atc", "crane", "b-05", "frigate", "evac", "villa", "hydropower", "power", "apartment", "pool"
            }
            for _, kw in ipairs(keyKeywords) do 
                local escapedKw = kw:gsub("%-", "%%-")
                if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then
                    return true, desc.Name
                end
            end
        end
        return false, nil
    end

    local function checkContainerLoot(container)
        if not (ESP_Config.FindWeapons or ESP_Config.FindValuables or ESP_Config.FindKeys or ESP_Config.FindAttachments) then return false, "" end
        for _, desc in ipairs(container:GetDescendants()) do
            local nameLow = desc.Name:lower()
            local isContainerPart = nameLow:find("mount") or nameLow:find("keypad") or nameLow:find("hinge") or nameLow:find("door") or nameLow:find("lock") or nameLow:find("frame") or nameLow:find("drawer")
            if not isContainerPart then
                local isMatch, matchName = GetValuableMatch(desc)
                if isMatch then
                    return true, matchName
                end
            end
            if desc:IsA("StringValue") and desc.Value and desc.Value ~= "" then
                local isValueMatch, _ = GetValuableMatch({Name = desc.Value})
                if isValueMatch then
                    return true, desc.Value
                end
            end
        end
        return false, ""
    end

    --[[
        ================================================
        --       MODULE 6: ENTITY SCANNER THREAD      --
        ================================================
    ]]
    local isEntityScanning = false

    task.spawn(function()
        while task.wait(2) do
            if not ESP_Config.ESP_Players and not ESP_Config.ESP_Corpses then
                continue
            end
            if isEntityScanning then
                continue
            end
            isEntityScanning = true
            
            local lpChar = LocalPlayer.Character
            if not lpChar then
                isEntityScanning = false
                continue
            end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then
                    CreateESP(p, true)
                end
            end
            task.wait()

            local function ScanEntity(obj)
                local nameLower = obj.Name:lower()
                if nameLower:find("effect") or nameLower:find("bullet") or nameLower:find("tracer") then return end
                if nameLower:find("poster") or nameLower:find("decal") or nameLower:find("sign") or nameLower:find("prop") or nameLower:find("static") or nameLower:find("building") or nameLower:find("foliage") then return end
                if nameLower:find("textlabel") or nameLower:find("uipadding") then return end

                local anatomyBlacklist = {
                    "rightupperarm", "rightlowerarm", "leftupperarm", "leftlowerarm", "rightupperleg", "rightlowerleg", "leftupperleg", "leftlowerleg", 
                    "uppertorso", "lowertorso", "head", "torso", "humanoidrootpart", "rootpart", "left arm", "right arm", "left leg", "right leg",
                    "left foot", "right foot", "left hand", "right hand", "leftleg", "rightleg", "leftfoot", "rightfoot", "lefthand", "righthand",
                    "leg", "foot", "hand", "joint"
                }
                for _, kw in ipairs(anatomyBlacklist) do
                    if nameLower == kw or nameLower:match("%f[%w]"..kw.."%f[%W]") then return end
                end
                
                if LocalPlayer.Character and obj == LocalPlayer.Character then return end

                local isHeli = nameLower:find("heli") or nameLower:find("mi%-24") or nameLower:find("mi24") or nameLower:find("gunship") or nameLower:find("helicopter")
                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil

                if not isPlayerChar then
                    if isHeli then
                        if not ESP_Objects[obj] then
                            local isDescendant = false
                            for parentObj, boxData in pairs(ESP_Objects) do
                                if boxData.IsHelicopter and obj:IsDescendantOf(parentObj) then
                                    isDescendant = true
                                    break
                                end
                            end
                            if isDescendant then return end
                        end
                    end

                    if not ESP_Objects[obj] then
                        local isDead = IsEntityDead(obj)
                        if (isDead and ESP_Config.ESP_Corpses) or (not isDead and ESP_Config.ESP_Players) then
                            if IsValidEntity(obj) or isHeli then
                                CreateESP(obj, false)
                                if ESP_Objects[obj] then 
                                    if isHeli then ESP_Objects[obj].IsHelicopter = true end 
                                end
                            end
                        end
                    end
                end
            end

            for _, child in ipairs(workspace:GetChildren()) do
                if child:IsA("Model") and child.Name ~= "DroppedItems" and child.Name ~= "Containers" and child.Name ~= "Terrain" and child.Name ~= "Camera" then
                    ScanEntity(child)
                end
            end
            task.wait()

            local aiZonesFolder = workspace:FindFirstChild("AiZones")
            if aiZonesFolder then
                for _, bot in ipairs(aiZonesFolder:GetDescendants()) do
                    if bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then
                        ScanEntity(bot)
                    end
                end
            end
            task.wait()

            isEntityScanning = false
        end
    end)

    --[[
        ================================================
        --        MODULE 7: ITEM SCANNER THREAD       --
        ================================================
    ]]
    local isItemScanning = false

    task.spawn(function()
        while task.wait(2) do
            if isItemScanning then
                continue
            end
            isItemScanning = true
            
            if not ESP_Config.ESP_Loot and not ESP_Config.ESP_Containers then
                isItemScanning = false
                continue
            end

            local containersFolder = workspace:FindFirstChild("Containers")
            if containersFolder and ESP_Config.ESP_Containers then
                local loopCount = 0
                for _, obj in ipairs(containersFolder:GetChildren()) do
                    loopCount = loopCount + 1
                    if loopCount % 10 == 0 then task.wait() end

                    local nameLower = obj.Name:lower()
                    local isContainer = false
                    local containerKeywords = {
                        "pc", "safe", "satchel", "box", "cache", "register", "drop", "cabinet", "filing", "kgb", "abpopa", 
                        "vault", "islootable", "crate", "sport", "airdrop", "bag", "drawer", "jacket", "case"
                    }
                    
                    for _, c in ipairs(containerKeywords) do
                        if nameLower:find(c) and not nameLower:find("skybox") and not nameLower:find("hitbox") and not nameLower:find("bhitbox") then
                            isContainer = true
                            break
                        end
                    end

                    if isContainer and obj:IsA("Folder") then
                        isContainer = false
                    end

                    if isContainer then
                        if not ESP_Objects[obj] then
                            local hasLoot, matchName = checkContainerLoot(obj)
                            local adorneePart = (obj:IsA("BasePart") and obj) or obj:FindFirstChildWhichIsA("BasePart", true)
                            if adorneePart then
                                local bb = Instance.new("BillboardGui")
                                bb.Size = UDim2.new(0, 250, 0, 30)
                                bb.AlwaysOnTop = true
                                bb.Adornee = adorneePart
                                bb.Parent = adorneePart
                                
                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1,0,1,0)
                                txt.BackgroundTransparency = 1
                                txt.Text = ""
                                txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                                txt.TextStrokeTransparency = 0
                                txt.Font = ESP_Config.Font
                                txt.TextSize = 13
                                local uiStrokeItem = Instance.new("UIStroke", txt)
                                uiStrokeItem.Thickness = 2
                                
                                local hl = Instance.new("Highlight")
                                hl.Name = "LootHighlight"
                                hl.FillColor = Color3.fromRGB(212, 175, 55)
                                hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                                hl.FillTransparency = 0.7
                                hl.OutlineTransparency = 0.5
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = adorneePart
                                hl.Parent = adorneePart
                                
                                bb.Enabled = false
                                hl.Enabled = false
                                
                                ESP_Objects[obj] = {
                                    Billboard_Item = bb, 
                                    Highlight_Item = hl, 
                                    IsContainer = true, 
                                    HasLoot = hasLoot, 
                                    ItemName = matchName,
                                    TargetAdornee = adorneePart
                                }
                            end
                        else
                            local hasLoot, matchName = checkContainerLoot(obj)
                            ESP_Objects[obj].HasLoot = hasLoot
                            ESP_Objects[obj].ItemName = matchName
                        end
                    end
                end
            end
            task.wait()

            local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
            if droppedItemsFolder and ESP_Config.ESP_Loot then
                local dropLoop = 0
                for _, obj in ipairs(droppedItemsFolder:GetChildren()) do
                    dropLoop = dropLoop + 1
                    if dropLoop % 10 == 0 then task.wait() end

                    if not ESP_Objects[obj] and (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Model") or obj:IsA("Tool")) then
                        local isMatch, matchName = GetValuableMatch(obj)
                        
                        if not isMatch then
                            for _, desc in ipairs(obj:GetDescendants()) do
                                if desc:IsA("StringValue") and desc.Value and desc.Value ~= "" then
                                    local isValMatch, _ = GetValuableMatch({Name = desc.Value})
                                    if isValMatch then
                                        isMatch = true
                                        matchName = desc.Value
                                        break
                                    end
                                end
                            end
                        end
                        
                        if isMatch then
                            local adorneePart = (obj:IsA("BasePart") and obj) or obj:FindFirstChildWhichIsA("BasePart", true) or obj
                            local bb = Instance.new("BillboardGui")
                            bb.Size = UDim2.new(0, 250, 0, 30)
                            bb.AlwaysOnTop = true
                            bb.Adornee = adorneePart
                            bb.Parent = adorneePart
                            
                            local txt = Instance.new("TextLabel", bb)
                            txt.Size = UDim2.new(1,0,1,0)
                            txt.BackgroundTransparency = 1
                            txt.Text = "[ " .. matchName .. " ]"
                            txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                            txt.TextStrokeTransparency = 0
                            txt.Font = ESP_Config.Font
                            txt.TextSize = 13
                            local dropStroke = Instance.new("UIStroke", txt)
                            dropStroke.Thickness = 2
                            
                            local hl = Instance.new("Highlight")
                            hl.Name = "LootHighlight"
                            hl.FillColor = Color3.fromRGB(212, 175, 55)
                            hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                            hl.FillTransparency = 0.7
                            hl.OutlineTransparency = 0.5
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = adorneePart
                            hl.Parent = adorneePart
                            
                            ESP_Objects[obj] = {
                                Billboard_Item = bb, 
                                Highlight_Item = hl, 
                                TargetAdornee = adorneePart, 
                                IsLooseItem = true, 
                                ItemName = matchName
                            }
                        end
                    end
                end
            end
            task.wait()

            isItemScanning = false
        end
    end)

    --[[
        ================================================
        --     MODULE 8: MISCELLANEOUS SCANNER        --
        ================================================
    ]]
    local function InitialPerformanceBoost()
        pcall(function()
            Lighting.FogEnd = 999999
            Lighting.FogStart = 999999
        end)
        
        for _, obj in ipairs(Lighting:GetDescendants()) do
            pcall(function()
                if obj:IsA("Atmosphere") then
                    obj.Density = 0
                elseif obj:IsA("Clouds") then
                    obj.Enabled = false
                end
            end)
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("rain") then
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
                    pcall(function()
                        obj.Enabled = false
                    end)
                elseif obj:IsA("Sound") then
                    pcall(function()
                        obj.Volume = 0
                        obj:Stop()
                    end)
                end
            end
        end
    end

    InitialPerformanceBoost()

    task.spawn(function()
        while task.wait(3) do
            local ammoTypes = game.ReplicatedStorage:FindFirstChild("AmmoTypes")
            if ammoTypes then
                for _, ammo in pairs(ammoTypes:GetChildren()) do
                    if ESP_Config.GunMods then
                        if not AmmoBackups[ammo] then
                            AmmoBackups[ammo] = {
                                Recoil = ammo:GetAttribute("RecoilStrength"),
                                Spread = ammo:GetAttribute("AccuracyDeviation"),
                                Drop = ammo:GetAttribute("ProjectileDrop")
                            }
                        end
                        ammo:SetAttribute("RecoilStrength", 0)
                        ammo:SetAttribute("AccuracyDeviation", 0)
                        ammo:SetAttribute("ProjectileDrop", 0)
                    else
                        if AmmoBackups[ammo] then
                            if AmmoBackups[ammo].Recoil ~= nil then
                                ammo:SetAttribute("RecoilStrength", AmmoBackups[ammo].Recoil)
                            end
                            if AmmoBackups[ammo].Spread ~= nil then
                                ammo:SetAttribute("AccuracyDeviation", AmmoBackups[ammo].Spread)
                            end
                            if AmmoBackups[ammo].Drop ~= nil then
                                ammo:SetAttribute("ProjectileDrop", AmmoBackups[ammo].Drop)
                            end
                            AmmoBackups[ammo] = nil
                        end
                    end
                end
            end
            
            if ESP_Config.PerformanceMode ~= LastPerformanceState then
                LastPerformanceState = ESP_Config.PerformanceMode
                InitialPerformanceBoost()
                
                if ESP_Config.PerformanceMode then
                    for _, obj in pairs(Lighting:GetDescendants()) do
                        if obj:IsA("PostEffect") or obj:IsA("Clouds") then
                            if obj.Enabled then
                                DisabledEffects[obj] = true
                                obj.Enabled = false
                            end
                        elseif obj:IsA("Atmosphere") then
                            if not TextureBackups[obj] then
                                TextureBackups[obj] = {Density = obj.Density}
                            end
                            obj.Density = 0
                        end
                    end
                else
                    Lighting.FogEnd = LightingBackups.FogEnd
                    Lighting.FogStart = LightingBackups.FogStart
                    
                    for obj, _ in pairs(DisabledEffects) do
                        if obj and obj.Parent then
                            pcall(function()
                                obj.Enabled = true
                            end)
                        end
                    end
                    table.clear(DisabledEffects)
                end
            end
            
            if ESP_Config.PerformanceMode then
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 999999
                Lighting.FogStart = 999999
                Lighting.Brightness = 2.5
                Lighting.Ambient = Color3.fromRGB(140, 145, 155)
                Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155)
            end
        end
    end)

    --[[
        ================================================
        --      MODULE 9: RENDER LOOP & AIMLOCK       --
        ================================================
    ]]
    RunService:BindToRenderStep("RomeoZach_Render", 2005, function(deltaTime)
        local lpChar = LocalPlayer.Character
        local lpHead = lpChar and lpChar:FindFirstChild("Head")
        if not lpHead then return end
        local cameraPos = Camera.CFrame.Position

        for entity, box in pairs(ESP_Objects) do
            if typeof(entity) == "Instance" and not entity.Parent then
                RemoveESP(entity)
                continue
            end
            
            local char = box.Character or (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            
            local function HideVisuals()
                box.CanBeAimlocked = false
                if box.Highlight then box.Highlight.Enabled = false end
                if box.DistBillboard then box.DistBillboard.Enabled = false end
                if box.Highlight_Item then box.Highlight_Item.Enabled = false end
                if box.Billboard_Item then box.Billboard_Item.Enabled = false end
            end

            if not char or not char.Parent or char == lpChar then
                HideVisuals()
                continue
            end

            local isDead = IsEntityDead(char)
            local isItem = box.IsContainer or box.IsLooseItem
            if isDead then isItem = false end
            
            local shouldProcess = (not isItem and not isDead and ESP_Config.ESP_Players) or (isDead and ESP_Config.ESP_Corpses) or (isItem and (ESP_Config.ESP_Loot or ESP_Config.ESP_Containers))

            if not shouldProcess then
                HideVisuals()
                continue
            end

            if not isItem then
                local rootPart = char:FindFirstChild("Head")
                if isDead and not rootPart then
                    rootPart = char:FindFirstChildWhichIsA("BasePart", true)
                end

                if not rootPart then
                    HideVisuals()
                    continue
                end

                local rootPos = rootPart.Position
                local studsDist = (cameraPos - rootPos).Magnitude
                local distMeter = math.floor(studsDist / 3.571428)

                if studsDist <= 3.57 then
                    HideVisuals()
                    continue
                end

                local shouldRender = false
                if isDead then
                    shouldRender = (studsDist <= 357.14)
                else
                    local isPlayerChar = Players:GetPlayerFromCharacter(char) ~= nil
                    shouldRender = (isPlayerChar and studsDist <= 3571.4) or (not isPlayerChar and studsDist <= 1607.1)
                end

                if not shouldRender then
                    HideVisuals()
                    continue
                end

                local finalColor = COLOR_BLOCKED
                local textColor = COLOR_BLOCKED
                
                if isDead then
                    finalColor = COLOR_DEAD
                    box.CanBeAimlocked = false
                else
                    local targetPart = char:FindFirstChild("Head") or rootPart
                    local visStatus, canLock = checkTargetVisibility(targetPart, char)
                    
                    local isTeam = IsTeammate(char)
                    
                    if isTeam then
                        finalColor = COLOR_TEAM_VISIBLE
                        if visStatus == "Blocked" then
                            textColor = COLOR_TEAM_BLOCKED
                        else
                            textColor = COLOR_TEAM_VISIBLE
                        end
                        box.CanBeAimlocked = false
                    else
                        if canLock then
                            finalColor = COLOR_VISIBLE
                            textColor = COLOR_VISIBLE
                        else
                            finalColor = COLOR_BLOCKED
                            textColor = COLOR_BLOCKED
                        end
                        box.CanBeAimlocked = canLock
                    end
                end

                if box.Highlight then
                    box.Highlight.Enabled = true
                    box.Highlight.FillColor = finalColor
                    box.Highlight.OutlineColor = finalColor
                    box.Highlight.OutlineTransparency = 0
                    box.Highlight.FillTransparency = 0.5
                end

                if box.DistBillboard then
                    if isDead then
                        box.DistBillboard.Enabled = false
                    else
                        box.DistBillboard.Enabled = true
                        if box.DistLabel then
                            box.DistLabel.Text = string.format("[%d m]", distMeter)
                            box.DistLabel.TextColor3 = textColor
                        end
                    end
                end
            else 
                local itemPos = (box.TargetAdornee and box.TargetAdornee:IsA("BasePart") and box.TargetAdornee.Position) or (entity:IsA("BasePart") and entity.Position)
                if not itemPos then
                    HideVisuals()
                    continue
                end
                
                local studsDist = (cameraPos - itemPos).Magnitude
                local inRange = (studsDist <= 87.5)
                
                if studsDist <= 3.57 then
                    HideVisuals()
                    continue
                end

                if box.Highlight_Item then 
                    box.Highlight_Item.Enabled = inRange and (not box.IsContainer or box.HasLoot)
                end
                
                if box.Billboard_Item then
                    box.Billboard_Item.Enabled = inRange and (box.IsLooseItem or (box.IsContainer and box.HasLoot))
                    if box.Billboard_Item.Enabled then
                        local txt = box.Billboard_Item:FindFirstChildWhichIsA("TextLabel")
                        if txt then
                            local dynSize = math.clamp(math.floor(250 / studsDist), 8, 14)
                            if box.IsContainer then
                                txt.Text = "[ " .. (box.ItemName or "Loot") .. " ]"
                            end
                            txt.TextSize = dynSize
                        end
                    end
                end
            end
        end 

        -- // Aimlock Logic
        if ESP_Config.AimLock and IsAiming then
            local potentialTargetEntity, potentialTargetChar = GetBestTargetInFOV()
            if potentialTargetChar then
                local tHead = potentialTargetChar:FindFirstChild("Head")
                if not tHead then
                    tHead = potentialTargetChar:FindFirstChild("HumanoidRootPart")
                end
                
                if tHead then
                    local visStatus, canLock = checkTargetVisibility(tHead, potentialTargetChar)
                    if canLock and not IsEntityDead(potentialTargetChar) and not IsTeammate(potentialTargetChar) then
                        CurrentTargetEntity = potentialTargetEntity
                        CurrentTargetChar = potentialTargetChar
                        local studsDist = (cameraPos - tHead.Position).Magnitude
                        
                        local bulletSpeed = GetBulletSpeed()
                        if bulletSpeed <= 0 then
                            bulletSpeed = 1500
                        end
                        
                        local timeToTarget = studsDist / bulletSpeed
                        local currentVelocity = tHead.AssemblyLinearVelocity
                        if currentVelocity.X ~= currentVelocity.X then
                            currentVelocity = Vector3.new(0,0,0)
                        end
                        
                        local dropCompensation = 0
                        if not ESP_Config.GunMods then
                            dropCompensation = (0.5 * workspace.Gravity * (timeToTarget * timeToTarget))
                        end
                        
                        local finalAimPos = tHead.Position + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                        
                        local _, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                        if onScreenAim then
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(cameraPos, finalAimPos), 0.6)
                        end
                    else
                        CurrentTargetEntity = nil
                        CurrentTargetChar = nil
                    end
                else
                    CurrentTargetEntity = nil
                    CurrentTargetChar = nil
                end
            end
        else
            CurrentTargetEntity = nil
            CurrentTargetChar = nil
        end
    end)

    --[[
        ================================================
        -- MODULE 10: INITIAL CONNECTIONS & PURGE     --
        ================================================
    ]]

    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then
            CreateESP(p, true)
        end
    end

    Players.PlayerAdded:Connect(function(p) 
        if p ~= LocalPlayer then
            CreateESP(p, true)
        end
    end)

    local function PurgeAllGarbageMemory()
        RunService:UnbindFromRenderStep("RomeoZach_Render")
        for entity, box in pairs(ESP_Objects) do
            RemoveESP(entity)
        end
        table.clear(ESP_Objects)
        table.clear(ignoreList)
        table.clear(CrosshairLines)
        CurrentTargetEntity = nil
        CurrentTargetChar = nil
        if targetGui:FindFirstChild("RomeoZach_Ui") then 
            pcall(function()
                targetGui.RomeoZach_Ui:Destroy()
            end)
        end
        setmetatable(ESP_Objects, nil)
        collectgarbage("collect")
    end

    Players.PlayerRemoving:Connect(RemoveESP)
    game:BindToClose(PurgeAllGarbageMemory)

end)

if not success then
    warn("[Project Delta V8 Error]: " .. tostring(err))
end
