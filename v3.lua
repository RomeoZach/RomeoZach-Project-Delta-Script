local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        return
    end
end)

--[[
    ================================================================================
    --|                                                                            |--
    --|           PROJECT DELTA V8 ULTIMATE - PURE COMBAT EDITION                  |--
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
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

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
    Header.Text = "Project Delta V8 - Pure Combat"
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
            local targetBgColor = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
            TweenService:Create(Track, trackTweenInfo, {BackgroundColor3 = targetBgColor}):Play()
            
            local knobTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local targetKnobPos = isActive and knobActivePos or knobInactivePos
            TweenService:Create(Knob, knobTweenInfo, {Position = targetKnobPos}):Play()

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
        --        MODULE 3: VISIBILITY ENGINE         --
        ================================================
    ]]
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)
        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        local distance = direction.Magnitude
        
        if distance < 7 then return "Visible", true end
        if not ESP_Config.VisCheck then return "Visible", true end
        
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", false end
        
        table.insert(ignoreList, lpChar)
        table.insert(ignoreList, Camera)
        if targetChar then table.insert(ignoreList, targetChar) end
        
        local loopCounter = 0

        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 50 then return "Blocked", false end

            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

            if not raycastResult then return "Visible", true end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", false end
            if hitInstance:IsDescendantOf(targetChar) then return "Visible", true end

            local isNonSolid = hitInstance.Transparency >= 0.8 or hitInstance.CanCollide == false
            local mat = raycastResult.Material
            local nameLow = hitInstance.Name:lower()
            local parentNameLow = hitInstance.Parent and hitInstance.Parent.Name:lower() or ""
            
            -- FIX TENDA & KAIN: Tambahan kata kunci penembus dinding
            local isFoliage = nameLow:find("grass") or nameLow:find("glass") or nameLow:find("ignore") or nameLow:find("tent") or nameLow:find("fabric") or nameLow:find("canvas") or nameLow:find("cloth") or nameLow:find("net") or nameLow:find("camo") or nameLow:find("bush") or nameLow:find("leaf")
            local isParentFoliage = parentNameLow:find("tent") or parentNameLow:find("fabric") or parentNameLow:find("canvas") or parentNameLow:find("cloth") or parentNameLow:find("net") or parentNameLow:find("camo")
            
            local wallbang = WallbangableMaterials[mat] or isNonSolid or isFoliage or isParentFoliage
            
            if wallbang then
                table.insert(ignoreList, hitInstance)
            else
                return "Blocked", false
            end
        end
    end

    --[[
        ================================================
        -- MODULE 3.5: BACKGROUND VISIBILITY THREAD   --
        ================================================
        Thread ini MENCEGAH LAG dengan melakukan raycast di luar Render Loop!
    ]]
    task.spawn(function()
        while task.wait(0.15) do
            if not ESP_Config.VisCheck then continue end
            for entity, box in pairs(ESP_Objects) do
                local char = box.Character
                if char and char.Parent and not IsEntityDead(char) and not IsTeammate(char) then
                    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                    if head then
                        local visStatus, _ = checkTargetVisibility(head, char)
                        box.VisStatus = visStatus
                    end
                end
            end
        end
    end)

    local function GetBestTargetInFOV()
        local shortestPixelDist = ESP_Config.FovRadius
        local centerPos = Camera.ViewportSize / 2
        local origin = Camera.CFrame.Position
        
        local closestEntity = nil
        local closestChar = nil
        local closestHead = nil
        
        -- Tahap 1: Seleksi FOV Screen (Tanpa Raycast untuk menghindari lag)
        for entity, box in pairs(ESP_Objects) do
            local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            if char and char ~= LocalPlayer.Character and char.Parent then
                if IsTeammate(char) or IsEntityDead(char) then continue end

                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head then
                    local predictedPos = head.Position
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        if screenDist < shortestPixelDist then
                            shortestPixelDist = screenDist
                            closestEntity = entity
                            closestChar = char
                            closestHead = head
                        end
                    end
                end
            end
        end

        -- Tahap 2: Lakukan HANYA 1 Raycast untuk target terdekat
        if closestChar and closestHead then
            local _, canLock = checkTargetVisibility(closestHead, closestChar)
            if canLock then
                return closestEntity, closestChar
            end
        end

        return nil, nil
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
            Connection = nil,
            IsHelicopter = false,
            VisStatus = "Visible" -- Default status
        }
        
        local function ApplyVisuals(char)
            if not char then return end
            if not isPlayer then
                task.wait(0.5)
                if not char or not char.Parent then return end 
            end

            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end

            box.Character = char
            local initialVisColor = COLOR_VISIBLE

            local hl = Instance.new("Highlight")
            hl.FillColor = initialVisColor
            hl.OutlineColor = initialVisColor
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = char
            hl.Parent = char
            box.Highlight = hl
            
            local distBb = Instance.new("BillboardGui")
            distBb.Name = "RomeoZach_DistBillboard"
            distBb.Size = UDim2.new(0, 200, 0, 50)
            distBb.AlwaysOnTop = true
            distBb.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LeftFoot") or char:FindFirstChildWhichIsA("BasePart", true)
            distBb.StudsOffset = Vector3.new(0, -4.5, 0)
            distBb.Parent = char
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
        for _, kw in ipairs(npcKeywords) do
            if nameLower:find(kw) then return true end
        end

        if obj:FindFirstChildOfClass("Tool") then return true end
        if obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then return true end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
        
        return false
    end

--[[
        ================================================
        --       MODULE 6: ENTITY SCANNER THREAD      --
        ================================================
    ]]
    local isEntityScanning = false

    task.spawn(function()
        while task.wait(2) do
            if not ESP_Config.ESP_Players and not ESP_Config.ESP_Corpses then continue end
            if isEntityScanning then continue end
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
                
                if LocalPlayer.Character and obj == LocalPlayer.Character then return end
                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil

                if not isPlayerChar then
                    if not ESP_Objects[obj] then
                        local isDead = IsEntityDead(obj)
                        if (isDead and ESP_Config.ESP_Corpses) or (not isDead and ESP_Config.ESP_Players) then
                            if IsValidEntity(obj) then
                                CreateESP(obj, false)
                            end
                        end
                    end
                end
            end

            local function ScanFolder(parentFolder)
                if not parentFolder then return end
                local loopCount = 0
                for _, child in ipairs(parentFolder:GetChildren()) do
                    loopCount = loopCount + 1
                    if loopCount % 25 == 0 then task.wait(0.01) end
                    if child:IsA("Model") and child.Name ~= "DroppedItems" and child.Name ~= "Containers" and child.Name ~= "Camera" then
                        ScanEntity(child)
                    end
                end
            end

            -- PERBAIKAN: Ekspansi Radar Mayat ke Folder Tersembunyi
            ScanFolder(workspace)
            ScanFolder(workspace:FindFirstChild("Ignore"))
            ScanFolder(workspace:FindFirstChild("Ragdolls"))
            ScanFolder(workspace:FindFirstChild("DeadBodies"))
            ScanFolder(workspace:FindFirstChild("Corpses"))
            task.wait()

            local aiZonesFolder = workspace:FindFirstChild("AiZones")
            if aiZonesFolder then
                local loopCount2 = 0
                for _, zone in ipairs(aiZonesFolder:GetChildren()) do
                    for _, bot in ipairs(zone:GetChildren()) do
                        loopCount2 = loopCount2 + 1
                        if loopCount2 % 25 == 0 then task.wait(0.01) end
                        if bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then
                            ScanEntity(bot)
                        end
                    end
                end
            end
            task.wait()
            isEntityScanning = false
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
                            if not TextureBackups[obj] then TextureBackups[obj] = {Density = obj.Density} end
                            obj.Density = 0
                        end
                    end
                else
                    Lighting.FogEnd = LightingBackups.FogEnd
                    Lighting.FogStart = LightingBackups.FogStart
                    for obj, _ in pairs(DisabledEffects) do
                        if obj and obj.Parent then pcall(function() obj.Enabled = true end) end
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
        if not lpChar then return end
        
        local cameraPos = Camera.CFrame.Position

        for entity, box in pairs(ESP_Objects) do
            if typeof(entity) == "Instance" and not entity.Parent then
                RemoveESP(entity)
                continue
            end
            
            local char = box.Character or (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            
            local function HideVisuals()
                -- 1000% HANYA TRANSPARANSI. TIDAK ADA LAGI ENABLED = FALSE UNTUK HIGHLIGHT!
                if box.Highlight then 
                    box.Highlight.FillTransparency = 1
                    box.Highlight.OutlineTransparency = 1
                end
                if box.DistBillboard and box.DistBillboard.Enabled then 
                    box.DistBillboard.Enabled = false 
                end
            end

            if not char or not char.Parent or char == lpChar then
                HideVisuals()
                continue
            end

            local isDead = IsEntityDead(char)
            local shouldProcess = false
            
            if not isDead and ESP_Config.ESP_Players then
                shouldProcess = true
            elseif isDead and ESP_Config.ESP_Corpses then
                shouldProcess = true
            end

            if not shouldProcess then
                HideVisuals()
                continue
            end

            local rootPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)

            if not rootPart then
                HideVisuals()
                continue
            end

            local rootPos = rootPart.Position
            local directionToTarget = rootPos - cameraPos
            local studsDist = directionToTarget.Magnitude
            local distMeter = math.floor(studsDist / 3.571428)
            local isCloseRange = (studsDist <= 3.57)

            -- FIX RENTANG JARAK MUTLAK
            local shouldRender = false
            if isDead then
                shouldRender = (studsDist <= 357.14) -- Mayat: 100m
            else
                local isPlayerChar = Players:GetPlayerFromCharacter(char) ~= nil
                if isPlayerChar then
                    shouldRender = (studsDist <= 3571.4) -- Player: 1000m
                else
                    shouldRender = (studsDist <= 1607.1) -- AI: 450m
                end
            end

            if not shouldRender then
                HideVisuals()
                continue
            end

            local finalColor = COLOR_BLOCKED
            local textColor = COLOR_BLOCKED
            local isTeam = false
            
            if isDead then
                finalColor = COLOR_DEAD
                if box.DistBillboard and box.DistBillboard.Enabled then 
                    box.DistBillboard.Enabled = false 
                end
            else
                isTeam = IsTeammate(char)
                if isTeam then
                    finalColor = ESP_Config.Color
                    textColor = (box.VisStatus == "Blocked") and COLOR_TEAM_BLOCKED or COLOR_TEAM_VISIBLE
                else
                    finalColor = (box.VisStatus == "Visible") and COLOR_VISIBLE or COLOR_BLOCKED
                    textColor = finalColor
                end

                if box.DistBillboard then
                    if not box.DistBillboard.Enabled then box.DistBillboard.Enabled = true end
                    if box.DistLabel then
                        box.DistLabel.Text = string.format("[%d m]", distMeter)
                        box.DistLabel.TextColor3 = textColor
                    end
                end
            end

            -- REBUILD ESP ANTI-GLITCH
            if box.Highlight then
                if isCloseRange then
                    box.Highlight.FillTransparency = 1
                    box.Highlight.OutlineTransparency = 1
                else
                    -- Selalu tembakkan properti ke 0.5 jika berada di luar batas dekat
                    box.Highlight.FillTransparency = 0.5
                    box.Highlight.OutlineTransparency = 0
                    box.Highlight.FillColor = finalColor
                    box.Highlight.OutlineColor = finalColor
                end
            end
        end 

        -- // Aimlock Logic (Sangat Cepat & Tanpa Lag)
        if ESP_Config.AimLock and IsAiming then
            local potentialTargetEntity, potentialTargetChar = GetBestTargetInFOV()
            if potentialTargetChar then
                local tHead = potentialTargetChar:FindFirstChild("Head") or potentialTargetChar:FindFirstChild("HumanoidRootPart")
                if tHead then
                    CurrentTargetEntity = potentialTargetEntity
                    CurrentTargetChar = potentialTargetChar
                    
                    local targetPos = tHead.Position
                    local dirToTarget = targetPos - cameraPos
                    local studsDist = dirToTarget.Magnitude
                    
                    local bulletSpeed = GetBulletSpeed()
                    if bulletSpeed <= 0 then bulletSpeed = 800 end 
                    
                    -- Konversi Meter/Detik ke Studs/Detik
                    local bulletSpeedStuds = bulletSpeed * 3.571428
                    local timeToTarget = studsDist / bulletSpeedStuds
                    
                    local currentVelocity = tHead.AssemblyLinearVelocity
                    if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0, 0, 0) end
                    
                    local dropCompensation = 0
                    if not ESP_Config.GunMods then
                        -- FIX FISIKA: Menggunakan gravitasi riil (35 studs/s^2), BUKAN gravitasi Roblox (196.2)!
                        dropCompensation = (0.5 * 35 * (timeToTarget * timeToTarget))
                    end
                    
                    local finalAimPos = targetPos + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                    local screenAimPos, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                    
                    if onScreenAim then
                        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(cameraPos, finalAimPos), 0.6)
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
        if p ~= LocalPlayer then CreateESP(p, true) end
    end

    Players.PlayerAdded:Connect(function(p) 
        if p ~= LocalPlayer then CreateESP(p, true) end
    end)

    local function PurgeAllGarbageMemory()
        RunService:UnbindFromRenderStep("RomeoZach_Render")
        for entity, box in pairs(ESP_Objects) do RemoveESP(entity) end
        table.clear(ESP_Objects)
        table.clear(ignoreList)
        table.clear(CrosshairLines)
        CurrentTargetEntity = nil
        CurrentTargetChar = nil
        
        if targetGui:FindFirstChild("RomeoZach_Ui") then 
            pcall(function() targetGui.RomeoZach_Ui:Destroy() end)
        end
        setmetatable(ESP_Objects, nil)
        collectgarbage("collect")
    end

    Players.PlayerRemoving:Connect(RemoveESP)
    game:BindToClose(PurgeAllGarbageMemory)

end)

if not success then warn("[Project Delta V8 Error]: " .. tostring(err)) end
