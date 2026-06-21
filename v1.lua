local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        return
    end
end)

--[[
    ================================================================================
    --|                                                                            |--
    --|       PROJECT DELTA V8 ULTIMATE - PURE COMBAT (OPTIMIZED VERSION)           |--
    --|                 Author  : RomeoZach                                        |--
    --|                                                                            |--
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

    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local ESP_Config = {
        AimLock = false,
        ESP_Players = true,
        ESP_Corpses = false,
        BulletTracers = false,
        Crosshair = false,
        VisCheck = true,
        GunMods = false, 
        PerformanceMode = false,
        Color = Color3.fromRGB(255, 255, 255),
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

    local getHuiFunc = gethui
    local targetGui = nil
    if getHuiFunc then
        targetGui = getHuiFunc()
    else
        targetGui = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui", 15)
    end
    
    local oldUi = targetGui:FindFirstChild("RomeoZach_Ui")
    if oldUi then
        pcall(function() oldUi:Destroy() end)
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
    MainFrame.Size = UDim2.new(0, 480, 0, 250) 
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -125)
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
    Header.Text = "Project Delta V8 - Pure Combat Edition"
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
        local knobActivePos = UDim2.new(1, -18, 0.5, -8)
        local knobInactivePos = UDim2.new(0, 2, 0.5, -8)
        Knob.Position = ESP_Config[configKey] and knobActivePos or knobInactivePos
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
            TweenService:Create(Track, trackTweenInfo, {BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}):Play()
            
            local knobTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(Knob, knobTweenInfo, {Position = isActive and knobActivePos or knobInactivePos}):Play()

            if configKey == "AimLock" and not ESP_Config.AimLock then
                CurrentTargetChar = nil
            end
            
            if configKey == "Crosshair" then
                for _, line in ipairs(CrosshairLines) do line.Visible = ESP_Config.Crosshair end
            end
        end)
        
        return Frame
    end

    local PlayerESPBtn = CreateToggle("ESP - Players & AI", "ESP_Players")
    local CorpseESPBtn = CreateToggle("ESP - Corpses", "ESP_Corpses")
    local LockBtn = CreateToggle("Enable AimLock", "AimLock")
    local VisCheckBtn = CreateToggle("ESP Wall Check", "VisCheck")
    local BulletTracersBtn = CreateToggle("Yellow Bullet Tracers", "BulletTracers")
    local CrosshairBtn = CreateToggle("Tiny Center Crosshair", "Crosshair")
    local GunModsBtn = CreateToggle("No Recoil & No Spread", "GunMods")
    local PerformanceBtn = CreateToggle("Performance Mode", "PerformanceMode")

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
        local defaultSpeed = 800
        local char = LocalPlayer.Character
        if not char then return defaultSpeed end
        
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local toolName = tool.Name:lower()
            local pdWeapons = {
                ["mosin"] = 885, ["svd"] = 830, ["r700"] = 800, ["remington"] = 800,
                ["fal"] = 840, ["m4a1"] = 850, ["akmn"] = 715, ["akm"] = 715,
                ["ak-74"] = 900, ["sks"] = 735, ["pkm"] = 825, ["as val"] = 295,
                ["vss"] = 292, ["mp5"] = 400, ["ump"] = 285, ["vector"] = 320,
                ["mac"] = 355, ["glock"] = 375, ["m9"] = 380, ["saiga"] = 400
            }
            for key, vel in pairs(pdWeapons) do
                if toolName:find(key) then
                    defaultSpeed = vel
                    break
                end
            end

            local settingsModule = tool:FindFirstChild("Setting") or tool:FindFirstChild("WeaponSettings") or tool:FindFirstChild("Stats")
            if settingsModule and settingsModule:IsA("ModuleScript") then
                local s, data = pcall(require, settingsModule)
                if s and type(data) == "table" then
                    return data.MuzzleVelocity or data.BulletSpeed or defaultSpeed
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
                if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
                return false
            end
            return false
        end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
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
        if targetPlayer and targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team == LocalPlayer.Team then return true end
        return false
    end

    --[[
        ================================================
        --   MODULE 3: OPTIMIZED VISIBILITY ENGINE    --
        ================================================
    ]]
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)

        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        
        if direction.Magnitude < 7 then return "Visible", true end
        if not ESP_Config.VisCheck then return "Visible", true end
        
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", false end
        
        table.insert(ignoreList, lpChar)
        table.insert(ignoreList, Camera)
        
        local ignoreFolder = workspace:FindFirstChild("Ignore")
        if ignoreFolder then table.insert(ignoreList, ignoreFolder) end
        if targetChar then table.insert(ignoreList, targetChar) end
        
        local loopCounter = 0

        -- FIX ANTI-LAG: Single Raycast Throttling untuk menghindari Infinite Loop maut
        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 12 then return "Blocked", false end -- Batasi kedalaman penetrasi

            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

            if not raycastResult then return "Visible", true end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", false end
            if hitInstance:IsDescendantOf(targetChar) then return "Visible", true end

            local mat = raycastResult.Material
            local nameLow = hitInstance.Name:lower()
            
            local isNonSolid = hitInstance.Transparency >= 0.8 or hitInstance.CanCollide == false
            local isWallbangMat = WallbangableMaterials[mat]
            
            local isWallbangName = false
            if not isWallbangMat and not isNonSolid then
                isWallbangName = nameLow:find("wood") or nameLow:find("plank") or nameLow:find("fabric") or nameLow:find("tent") or nameLow:find("glass") or nameLow:find("fence") or nameLow:find("wall") or nameLow:find("door") or nameLow:find("window") or nameLow:find("cover") or nameLow:find("barrier") or nameLow:find("concrete") or nameLow:find("prop")
            end
            
            if isWallbangMat or isNonSolid or isWallbangName then
                table.insert(ignoreList, hitInstance)
            else
                return "Blocked", false
            end
        end
    end

    local function GetBestTargetInFOV()
        local bestEntity = nil
        local bestChar = nil
        local shortestPixelDist = ESP_Config.FovRadius
        local centerPos = Camera.ViewportSize / 2
        local origin = Camera.CFrame.Position
        
        for entity, box in pairs(ESP_Objects) do
            local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            if char and char ~= LocalPlayer.Character and char.Parent then
                if IsTeammate(char) then continue end

                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                
                if head and not IsEntityDead(char) then
                    local visStatus, canLock = checkTargetVisibility(head, char)
                    if not canLock then continue end

                    local studsDist = (origin - head.Position).Magnitude
                    local isPlayer = (typeof(entity) == "Instance" and entity:IsA("Player")) or Players:GetPlayerFromCharacter(char) ~= nil
                    
                    if isPlayer and studsDist > 3571.4 then continue end
                    if not isPlayer and studsDist > 1607.1 then continue end

                    local predictedPos = head.Position
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
        --      MODULE 4: ESP MANAGER (CHAMS 3D)      --
        ================================================
    ]]
    local function RemoveESP(entity)
        if ESP_Objects[entity] then
            local box = ESP_Objects[entity]
            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end
            if box.Connection then box.Connection:Disconnect() end
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
            BoxFrame = nil, 
            BoxStroke = nil,
            Connection = nil,
            CanBeAimlocked = false
        }
        
        local function ApplyVisuals(char)
            if not char then return end
            if not isPlayer then
                task.wait(0.2)
                if not char or not char.Parent then return end 
            end

            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end

            box.Character = char
            
            local hl = Instance.new("Highlight")
            hl.FillColor = COLOR_BLOCKED
            hl.OutlineColor = COLOR_BLOCKED
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = char
            hl.Parent = char
            box.Highlight = hl
            
            local distBb = Instance.new("BillboardGui")
            distBb.Name = "RomeoZach_DistBillboard"
            distBb.Size = UDim2.new(4, 0, 5.5, 0)
            distBb.AlwaysOnTop = true
            distBb.LightInfluence = 0
            distBb.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart", true)
            distBb.Parent = char
            box.DistBillboard = distBb
            
            -- Kotak 2D Plum Khusus Mayat
            local boxFrame = Instance.new("Frame", distBb)
            boxFrame.Size = UDim2.new(1, 0, 1, -20)
            boxFrame.BackgroundTransparency = 1
            boxFrame.Visible = false
            local boxStroke = Instance.new("UIStroke", boxFrame)
            boxStroke.Thickness = 1.5
            boxStroke.Color = COLOR_DEAD
            box.BoxFrame = boxFrame
            box.BoxStroke = boxStroke

            local distTxt = Instance.new("TextLabel", distBb)
            distTxt.Size = UDim2.new(1, 0, 0, 20)
            distTxt.Position = UDim2.new(0, 0, 1, -20)
            distTxt.BackgroundTransparency = 1
            distTxt.Text = ""
            distTxt.TextColor3 = COLOR_BLOCKED
            distTxt.TextSize = 13
            distTxt.Font = ESP_Config.Font
            distTxt.TextStrokeTransparency = 0
            distTxt.TextYAlignment = Enum.TextYAlignment.Top
            local uiStroke = Instance.new("UIStroke", distTxt)
            uiStroke.Thickness = 1.5
            box.DistLabel = distTxt
        end
        
        if isPlayer then 
            if entity.Character then ApplyVisuals(entity.Character) end
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
        if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or nameLower:find("bag") or nameLower:find("satchel") or nameLower:find("register") or nameLower:find("safe") or nameLower:find("vault") or nameLower:find("desk") or nameLower:find("boulder") or nameLower:find("mesh") then return false end
        if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") then return false end

        if not obj:FindFirstChildOfClass("Shirt") and not obj:FindFirstChildOfClass("Pants") then
            if not (nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll")) then return false end
        end

        local npcKeywords = {"dozer", "anton", "guard", "bandit", "rat", "sniper", "marksman", "highway", "tunnel", "occupant", "survey", "team", "member", "soldier", "whisper", "scav", "king", "uno", "peace", "keeper", "death"}
        for _, kw in ipairs(npcKeywords) do if nameLower:find(kw) then return true end end

        if obj:FindFirstChildOfClass("Tool") then return true end
        if obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then return true end
        
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
        return false
    end

    --[[
        ================================================
        --  MODULE 6: THROTTLED ENTITY SCANNER THREAD --
        ================================================
    ]]
    local isEntityScanning = false

    task.spawn(function()
        while task.wait(1.5) do -- Jeda scanner dinaikkan untuk stabilitas FPS
            if not ESP_Config.ESP_Players and not ESP_Config.ESP_Corpses then continue end
            if isEntityScanning then continue end
            isEntityScanning = true
            
            local lpChar = LocalPlayer.Character
            if not lpChar then isEntityScanning = false; continue end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
            end

            local function ScanEntity(obj)
                local nameLower = obj.Name:lower()
                if nameLower:find("effect") or nameLower:find("bullet") or nameLower:find("tracer") then return end
                if nameLower:find("poster") or nameLower:find("decal") or nameLower:find("sign") or nameLower:find("prop") or nameLower:find("static") or nameLower:find("building") or nameLower:find("foliage") then return end

                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil
                if not isPlayerChar and not ESP_Objects[obj] then
                    local isDead = IsEntityDead(obj)
                    if (isDead and ESP_Config.ESP_Corpses) or (not isDead and ESP_Config.ESP_Players) then
                        if IsValidEntity(obj) then CreateESP(obj, false) end
                    end
                end
            end

            -- FIX ANTI-LAG: Menambahkan yield mini di setiap batch scan agar tidak micro-stutter
            local loopCount = 0
            for _, child in ipairs(workspace:GetChildren()) do
                loopCount = loopCount + 1
                if loopCount % 20 == 0 then task.wait(0.01) end
                if child:IsA("Model") and child.Name ~= "DroppedItems" and child.Name ~= "Containers" and child.Name ~= "Terrain" and child.Name ~= "Camera" then
                    ScanEntity(child)
                end
            end

            local aiZonesFolder = workspace:FindFirstChild("AiZones")
            if aiZonesFolder then
                for _, zone in ipairs(aiZonesFolder:GetChildren()) do
                    for _, bot in ipairs(zone:GetChildren()) do
                        loopCount = loopCount + 1
                        if loopCount % 20 == 0 then task.wait(0.01) end
                        if bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then ScanEntity(bot) end
                    end
                end
            end

            isEntityScanning = false
        end
    end)

--[[
        ================================================
        --     MODULE 8: MISCELLANEOUS SCANNER        --
        ================================================
    ]]
    local function InitialPerformanceBoost()
        pcall(function() Lighting.FogEnd = 999999 Lighting.FogStart = 999999 end)
        for _, obj in ipairs(Lighting:GetDescendants()) do
            pcall(function()
                if obj:IsA("Atmosphere") then obj.Density = 0
                elseif obj:IsA("Clouds") then obj.Enabled = false end
            end)
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local nameLow = obj.Name:lower()
            if nameLow:find("rain") then
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then pcall(function() obj.Enabled = false end)
                elseif obj:IsA("Sound") then pcall(function() obj.Volume = 0 obj:Stop() end) end
            end
        end
    end

    InitialPerformanceBoost()

    task.spawn(function()
        while task.wait(3) do
            -- [1] MODIFIKASI RECOIL & AMMO
            local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
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
                        local backup = AmmoBackups[ammo]
                        if backup then
                            if backup.Recoil ~= nil then ammo:SetAttribute("RecoilStrength", backup.Recoil) end
                            if backup.Spread ~= nil then ammo:SetAttribute("AccuracyDeviation", backup.Spread) end
                            if backup.Drop ~= nil then ammo:SetAttribute("ProjectileDrop", backup.Drop) end
                            AmmoBackups[ammo] = nil
                        end
                    end
                end
            end
            
            -- [2] TOGGLE PERFORMANCE MODE AWAL
            if ESP_Config.PerformanceMode ~= LastPerformanceState then
                LastPerformanceState = ESP_Config.PerformanceMode
                InitialPerformanceBoost()
                
                if ESP_Config.PerformanceMode then
                    -- Eksekusi mati semua efek di Lighting & Kamera saat pertama kali dinyalakan
                    local targetFolders = {Lighting, Camera}
                    for _, folder in ipairs(targetFolders) do
                        for _, obj in pairs(folder:GetDescendants()) do
                            if obj:IsA("PostEffect") or obj:IsA("Clouds") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
                                if obj.Enabled then DisabledEffects[obj] = true; obj.Enabled = false end
                                if obj:IsA("BlurEffect") then obj.Size = 0 end
                            elseif obj:IsA("Atmosphere") then
                                if not TextureBackups[obj] then TextureBackups[obj] = {Density = obj.Density} end
                                obj.Density = 0
                            end
                        end
                    end
                else
                    -- Kembalikan normal saat dimatikan
                    Lighting.FogEnd = LightingBackups.FogEnd 
                    Lighting.FogStart = LightingBackups.FogStart
                    for obj, _ in pairs(DisabledEffects) do
                        if obj and obj.Parent then pcall(function() obj.Enabled = true end) end
                    end
                    table.clear(DisabledEffects)
                end
            end
            
            -- [3] PENJAGAAN KETAT PERFORMANCE MODE TIAP 3 DETIK
            if ESP_Config.PerformanceMode then
                Lighting.GlobalShadows = false 
                Lighting.FogEnd = 999999 
                Lighting.FogStart = 999999 
                Lighting.Brightness = 2.5
                Lighting.Ambient = Color3.fromRGB(140, 145, 155) 
                Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155)
                
                -- Sapu bersih paksa (anti-blur saat bidik/kena tembak/low stamina)
                local targetFolders = {Lighting, Camera}
                for _, folder in ipairs(targetFolders) do
                    for _, obj in pairs(folder:GetDescendants()) do
                        if obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
                            obj.Enabled = false
                            if obj:IsA("BlurEffect") then obj.Size = 0 end
                        end
                    end
                end
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
        if not lpChar then return end
        
        local lpHead = lpChar:FindFirstChild("Head")
        if not lpHead then return end
        
        local cameraPos = Camera.CFrame.Position

        for entity, box in pairs(ESP_Objects) do
            if typeof(entity) == "Instance" and not entity.Parent then RemoveESP(entity); continue end
            
            local char = box.Character or (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            
            local function HideVisuals()
                box.CanBeAimlocked = false
                if box.Highlight then box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1 end
                if box.DistBillboard then box.DistBillboard.Enabled = false end
                if box.BoxFrame then box.BoxFrame.Visible = false end
            end

            if not char or not char.Parent or char == lpChar then HideVisuals(); continue end

            local isDead = IsEntityDead(char)
            local shouldProcess = false
            
            if not isDead and ESP_Config.ESP_Players then shouldProcess = true
            elseif isDead and ESP_Config.ESP_Corpses then shouldProcess = true end

            if not shouldProcess then HideVisuals(); continue end

            local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart", true)
            if not rootPart then HideVisuals(); continue end

            if box.DistBillboard and (not box.DistBillboard.Adornee or not box.DistBillboard.Adornee.Parent) then
                box.DistBillboard.Adornee = rootPart
            end

            local rootPos = rootPart.Position
            local studsDist = (rootPos - cameraPos).Magnitude
            local distMeter = math.floor(studsDist / 3.5714285714)
            local isCloseRange = (studsDist <= 3.5714285714)

            local shouldRender = false
            if isDead then
                shouldRender = (studsDist <= 267.8571428571) -- 75m Jangkauan Radar Mayat
            else
                local isPlayerChar = Players:GetPlayerFromCharacter(char) ~= nil
                if isPlayerChar then shouldRender = (studsDist <= 3571.4285714286) else shouldRender = (studsDist <= 1607.1428571429) end
            end

            if not shouldRender then HideVisuals(); continue end

            local finalColor = COLOR_BLOCKED
            local textColor = COLOR_BLOCKED
            local isTeam = false
            
            -- FIX PERSISTENT ESP MAYAT: Tidak ada :Destroy() sewaktu didekati
            if isDead then
                box.CanBeAimlocked = false
                if box.Highlight then box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1 end -- Chams dimatikan agar hemat FPS
                
                if box.DistBillboard then
                    box.DistBillboard.Enabled = true
                    if box.BoxFrame then box.BoxFrame.Visible = true end
                    if box.DistLabel then
                        box.DistLabel.Text = string.format("[ Corpse: %d m ]", distMeter)
                        box.DistLabel.TextColor3 = COLOR_DEAD
                    end
                end
            else
                local targetPart = char:FindFirstChild("Head") or rootPart
                local visStatus, canLock = checkTargetVisibility(targetPart, char)
                isTeam = IsTeammate(char)
                
                if isTeam then
                    finalColor = ESP_Config.Color
                    textColor = (visStatus == "Blocked") and COLOR_TEAM_BLOCKED or COLOR_TEAM_VISIBLE
                    box.CanBeAimlocked = false
                else
                    if canLock then finalColor = COLOR_VISIBLE textColor = COLOR_VISIBLE else finalColor = COLOR_BLOCKED textColor = COLOR_BLOCKED end
                    box.CanBeAimlocked = canLock
                end

                if box.BoxFrame then box.BoxFrame.Visible = false end

                if box.Highlight then
                    if isCloseRange then
                        box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1
                    else
                        box.Highlight.FillTransparency = 0.5 box.Highlight.OutlineTransparency = 0
                        box.Highlight.FillColor = finalColor box.Highlight.OutlineColor = finalColor
                    end
                end

                if box.DistBillboard then
                    box.DistBillboard.Enabled = true
                    if box.DistLabel then box.DistLabel.Text = string.format("[%d m]", distMeter) box.DistLabel.TextColor3 = textColor end
                end
            end
        end 

        -- // Aimlock Logic
        if ESP_Config.AimLock and IsAiming then
            local potentialTargetEntity, potentialTargetChar = GetBestTargetInFOV()
            
            if potentialTargetChar then
                local tHead = potentialTargetChar:FindFirstChild("Head")
                if tHead then
                    -- METODE TARGET GANDA: Raycast visibility memakai Kepala (Agar Peek Jendela langsung Putih!)
                    local visStatus, canLock = checkTargetVisibility(tHead, potentialTargetChar)
                    local isDead = IsEntityDead(potentialTargetChar)
                    local isTeammate = IsTeammate(potentialTargetChar)
                    
                    if canLock and not isDead and not isTeammate then
                        CurrentTargetEntity = potentialTargetEntity
                        CurrentTargetChar = potentialTargetChar
                        
                        local targetPos = tHead.Position
                        local studsDist = (targetPos - cameraPos).Magnitude
                        
                        local bulletSpeedMS = GetBulletSpeed()
                        if bulletSpeedMS <= 0 then bulletSpeedMS = 800 end
                        local bulletSpeedStuds = bulletSpeedMS * 3.5714285714
                        
                        -- KALIBRASI DRAG SVD (1200): Menjamin dongakan akurat di 400m+
                        local dragFactor = 1 + (studsDist / 1200)
                        local realTime = (studsDist / bulletSpeedStuds) * dragFactor
                        
                        -- METODE TARGET GANDA: Ambil kecepatan prediksi lari dari BADAN (HumanoidRootPart) agar stabil tanpa getar!
                        local targetRoot = potentialTargetChar:FindFirstChild("HumanoidRootPart")
                        local currentVelocity = targetRoot and targetRoot.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                        if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0, 0, 0) end
                        
                        local leadCompensation = currentVelocity * realTime
                        local dropCompensation = 0
                        if not ESP_Config.GunMods then
                            dropCompensation = (0.5 * workspace.Gravity * (realTime * realTime))
                        end
                        
                        -- Kamera mengunci KEPALA, disinkronkan dengan lari BADAN dan jatuhnya peluru
                        local finalAimPos = targetPos + leadCompensation + Vector3.new(0, dropCompensation, 0)
                        local _, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                        
                        if onScreenAim then
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(cameraPos, finalAimPos), 0.6)
                        end
                    else
                        CurrentTargetEntity = nil CurrentTargetChar = nil
                    end
                else
                    CurrentTargetEntity = nil CurrentTargetChar = nil
                end
            end
        else
            CurrentTargetEntity = nil CurrentTargetChar = nil
        end
    end)

    --[[
        ================================================
        -- MODULE 10: INITIAL CONNECTIONS & PURGE     --
        ================================================
    ]]
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p, true) end end
    Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p, true) end end)

    local function PurgeAllGarbageMemory()
        RunService:UnbindFromRenderStep("RomeoZach_Render")
        for entity, box in pairs(ESP_Objects) do RemoveESP(entity) end
        table.clear(ESP_Objects) table.clear(ignoreList) table.clear(CrosshairLines)
        CurrentTargetEntity = nil CurrentTargetChar = nil
        if targetGui:FindFirstChild("RomeoZach_Ui") then pcall(function() local ui = targetGui:FindFirstChild("RomeoZach_Ui") if ui then ui:Destroy() end end) end
        setmetatable(ESP_Objects, nil) collectgarbage("collect")
    end

    Players.PlayerRemoving:Connect(RemoveESP)
    game:BindToClose(PurgeAllGarbageMemory)

end)

if not success then warn("[Project Delta V8 Error]: " .. tostring(err)) end
