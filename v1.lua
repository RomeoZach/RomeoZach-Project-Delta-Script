local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        return
    end
end)

--[[
    ================================================================================
    --|                                                                            |--
    --|    PROJECT DELTA V8.2 ULTIMATE - PURE COMBAT (ANTI-FREEZE BYPASS)          |--
    --|                 Author  : RomeoZach                                        |--
    --|                                                                            |--
    ================================================================================
]]

local success, err = pcall(function()

    --[[ MODULE 1: CORE CONFIG & UI SETUP ]]
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    local ESP_Config = {
        AimLock = false, ESP_Players = true, ESP_Corpses = false,
        BulletTracers = false, Crosshair = false, VisCheck = true,
        GunMods = false, PerformanceMode = false,
        Color = Color3.fromRGB(255, 255, 255), TextSize = 13,
        Font = Enum.Font.GothamBold, FovRadius = 300
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
        GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness, FogColor = Lighting.FogColor
    }

    local WallbangableMaterials = {
        [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true,
        [Enum.Material.Fabric] = true, [Enum.Material.Plastic] = true,
        [Enum.Material.Glass] = true, [Enum.Material.Cardboard] = true,
        [Enum.Material.Sand] = true
    }

    local sharedRaycastParams = RaycastParams.new()
    sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    sharedRaycastParams.IgnoreWater = true
    local ignoreList = {}

    local getHuiFunc = gethui
    local targetGui = nil
    if getHuiFunc then targetGui = getHuiFunc() else targetGui = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui", 15) end
    
    local oldUi = targetGui:FindFirstChild("RomeoZach_Ui")
    if oldUi then pcall(function() oldUi:Destroy() end) task.wait(0.2) end

    local RomeoZachGui = Instance.new("ScreenGui")
    RomeoZachGui.Name = "RomeoZach_Ui" RomeoZachGui.ResetOnSpawn = false RomeoZachGui.DisplayOrder = 999999 RomeoZachGui.IgnoreGuiInset = true RomeoZachGui.Parent = targetGui

    local chX = Instance.new("Frame", RomeoZachGui)
    chX.Size = UDim2.new(0, 14, 0, 2) chX.Position = UDim2.new(0.5, -7, 0.5, -1) chX.BackgroundColor3 = ESP_Config.Color chX.BorderSizePixel = 0 chX.Visible = ESP_Config.Crosshair
    local strokeX = Instance.new("UIStroke", chX) strokeX.Thickness = 1 table.insert(CrosshairLines, chX)

    local chY = Instance.new("Frame", RomeoZachGui)
    chY.Size = UDim2.new(0, 2, 0, 14) chY.Position = UDim2.new(0.5, -1, 0.5, -7) chY.BackgroundColor3 = ESP_Config.Color chY.BorderSizePixel = 0 chY.Visible = ESP_Config.Crosshair
    local strokeY = Instance.new("UIStroke", chY) strokeY.Thickness = 1 table.insert(CrosshairLines, chY)

    local MainFrame = Instance.new("Frame", RomeoZachGui)
    MainFrame.Name = "MainFrame" MainFrame.Size = UDim2.new(0, 480, 0, 250) 
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -125) MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18) MainFrame.BackgroundTransparency = 0.15 MainFrame.BorderSizePixel = 0 MainFrame.Active = true MainFrame.Draggable = true

    local cornerMain = Instance.new("UICorner", MainFrame) cornerMain.CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", MainFrame) MainStroke.Thickness = 1 MainStroke.Color = Color3.fromRGB(45, 48, 53) MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Header = Instance.new("TextLabel", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 40) Header.BackgroundTransparency = 1 Header.Text = "Project Delta V8.2 - Pure Combat Edition" Header.TextColor3 = Color3.fromRGB(240, 240, 245) Header.TextSize = 14 Header.Font = Enum.Font.GothamBold Header.TextXAlignment = Enum.TextXAlignment.Center

    local ContainerUI = Instance.new("Frame", MainFrame)
    ContainerUI.Size = UDim2.new(1, -20, 1, -45) ContainerUI.Position = UDim2.new(0, 10, 0, 35) ContainerUI.BackgroundTransparency = 1

    local UIGridLayout = Instance.new("UIGridLayout", ContainerUI)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10) UIGridLayout.CellSize = UDim2.new(0.5, -5, 0, 40)

    local function CreateToggle(labelText, configKey)
        local Frame = Instance.new("Frame", ContainerUI) Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27) Frame.BorderSizePixel = 0
        local cornerFrame = Instance.new("UICorner", Frame) cornerFrame.CornerRadius = UDim.new(0, 6)

        local Label = Instance.new("TextLabel", Frame) Label.Size = UDim2.new(0.65, 0, 1, 0) Label.Position = UDim2.new(0, 10, 0, 0) Label.BackgroundTransparency = 1 Label.Text = labelText Label.TextColor3 = Color3.fromRGB(200, 200, 205) Label.TextSize = 12 Label.Font = Enum.Font.Gotham Label.TextXAlignment = Enum.TextXAlignment.Left

        local Track = Instance.new("Frame", Frame) Track.Size = UDim2.new(0, 40, 0, 20) Track.Position = UDim2.new(1, -50, 0.5, -10) Track.BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
        local cornerTrack = Instance.new("UICorner", Track) cornerTrack.CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame", Track) Knob.Size = UDim2.new(0, 16, 0, 16) local knobActivePos = UDim2.new(1, -18, 0.5, -8) local knobInactivePos = UDim2.new(0, 2, 0.5, -8) Knob.Position = ESP_Config[configKey] and knobActivePos or knobInactivePos Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        local cornerKnob = Instance.new("UICorner", Knob) cornerKnob.CornerRadius = UDim.new(1, 0)

        local Btn = Instance.new("TextButton", Track) Btn.Size = UDim2.new(1, 0, 1, 0) Btn.BackgroundTransparency = 1 Btn.Text = ""

        Btn.MouseButton1Click:Connect(function()
            ESP_Config[configKey] = not ESP_Config[configKey]
            local isActive = ESP_Config[configKey]
            TweenService:Create(Track, TweenInfo.new(0.2), {BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = isActive and knobActivePos or knobInactivePos}):Play()
            if configKey == "AimLock" and not ESP_Config.AimLock then CurrentTargetChar = nil end
            if configKey == "Crosshair" then for _, line in ipairs(CrosshairLines) do line.Visible = ESP_Config.Crosshair end end
        end)
        return Frame
    end

    CreateToggle("ESP - Players & AI", "ESP_Players") CreateToggle("ESP - Corpses", "ESP_Corpses")
    CreateToggle("Enable AimLock", "AimLock") CreateToggle("ESP Wall Check", "VisCheck")
    CreateToggle("Yellow Bullet Tracers", "BulletTracers") CreateToggle("Tiny Center Crosshair", "Crosshair")
    CreateToggle("No Recoil & No Spread", "GunMods") CreateToggle("Performance Mode", "PerformanceMode")

--[[ MODULE 2: INPUT & UTILITIES ]]
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.RightShift and not gp then MainFrame.Visible = not MainFrame.Visible end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end
    end)

    local function GetBulletSpeed()
        local defaultSpeed = 800
        local char = LocalPlayer.Character
        if not char then return defaultSpeed end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            for _, desc in ipairs(tool:GetDescendants()) do
                if desc:IsA("ModuleScript") then
                    local s, data = pcall(require, desc)
                    if s and type(data) == "table" then
                        local dynamicSpeed = data.MuzzleVelocity or data.BulletSpeed or data.Velocity or data.Speed
                        if dynamicSpeed and type(dynamicSpeed) == "number" then return dynamicSpeed end
                    end
                end
            end
        end
        return defaultSpeed
    end

    local function IsEntityDead(char)
        if not char or typeof(char) ~= "Instance" or not char.Parent then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return true end
            return false
        end
        local nameLower = string.lower(char.Name)
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
        if char:IsA("Model") and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") == nil then return true end
        return false
    end

    local function IsTeammate(char)
        if not char then return false end
        local targetPlayer = Players:GetPlayerFromCharacter(char)
        
        if targetPlayer then
            if targetPlayer == LocalPlayer then return true end
            
            -- 1. Cek Tim Resmi Roblox
            if targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team == LocalPlayer.Team then return true end
            
            -- 2. Cek Sistem Squad Khusus (Filter Sangat Ketat)
            local names = {"Squad", "Group", "Party", "Faction"}
            for _, name in ipairs(names) do
                local vTarget = targetPlayer:FindFirstChild(name) or char:FindFirstChild(name)
                local vMine = LocalPlayer:FindFirstChild(name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))
                
                if vTarget and vMine and vTarget:IsA("StringValue") and vMine:IsA("StringValue") then
                    local sTarget, sMine = tostring(vTarget.Value), tostring(vMine.Value)
                    
                    -- HANYA anggap tim JIKA nama squad sama, TIDAK KOSONG, dan hurufnya lebih dari 2
                    if sTarget == sMine and #sTarget > 2 and sTarget:lower() ~= "none" and sTarget:lower() ~= "neutral" then
                        return true
                    end
                end
            end
        end
        return false
    end

    --[[ MODULE 3: OPTIMIZED VISIBILITY ENGINE (ANTI-LAG) ]]
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)
        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        
        if direction.Magnitude < 7 then return "Visible", true end
        if not ESP_Config.VisCheck then return "Visible", true end
        
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", false end
        
        table.insert(ignoreList, lpChar) table.insert(ignoreList, Camera)
        local ignoreFolder = workspace:FindFirstChild("Ignore") if ignoreFolder then table.insert(ignoreList, ignoreFolder) end
        if targetChar then table.insert(ignoreList, targetChar) end
        
        local loopCounter = 0
        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 4 then return "Blocked", false end

            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

            if not raycastResult then return "Visible", true end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", false end
            if hitInstance:IsDescendantOf(targetChar) then return "Visible", true end

            local parentModel = hitInstance:FindFirstAncestorOfClass("Model")
            local isWallbangMat = WallbangableMaterials[raycastResult.Material]
            local nameLow = hitInstance.Name:lower()
            local parentNameLow = parentModel and parentModel.Name:lower() or ""

            local isWallbangName = (nameLow:find("wood") or nameLow:find("plank") or nameLow:find("glass") or nameLow:find("door") or nameLow:find("window") or nameLow:find("fence") or parentNameLow:find("house") or parentNameLow:find("hut") or parentNameLow:find("shack") or parentNameLow:find("cabin") or parentNameLow:find("building"))

            if isWallbangMat or isWallbangName or hitInstance.Transparency > 0 then
                table.insert(ignoreList, parentModel or hitInstance)
            else
                return "Blocked", false
            end
        end
    end

    local function GetBestTargetInFOV()
        local bestEntity, bestChar = nil, nil
        local shortestPixelDist = ESP_Config.FovRadius
        local centerPos = Camera.ViewportSize / 2
        local origin = Camera.CFrame.Position
        
        for entity, box in pairs(ESP_Objects) do
            local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            if char and char ~= LocalPlayer.Character and char.Parent then
                if IsTeammate(char) then continue end
                
                local head = char:FindFirstChild("Head") or char:FindFirstChild("head")
                if not head then continue end
                
                if not IsEntityDead(char) then
                    local studsDist = (origin - head.Position).Magnitude
                    if box.IsPlayer and studsDist > 5357.1429 then continue end
                    if not box.IsPlayer and studsDist > 2321.4286 then continue end

                    -- OPTIMALISASI 1: Cek posisi layar DULU. Jangan buang CPU untuk target di belakang kamera.
                    local predictedPos = head.Position
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        -- OPTIMALISASI 2: HANYA lakukan Raycast (Wallbang check) jika musuh ini lebih dekat ke crosshair!
                        if screenDist < shortestPixelDist then
                            local visStatus, canLock = checkTargetVisibility(head, char)
                            if canLock then
                                shortestPixelDist = screenDist; bestEntity = entity; bestChar = char
                            end
                        end
                    end
                end
            end
        end
        return bestEntity, bestChar
    end

    --[[ MODULE 4: ESP MANAGER ]]
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
            Highlight = nil, DistBillboard = nil, DistLabel = nil,
            BoxFrame = nil, BoxStroke = nil, Connection = nil,
            CanBeAimlocked = false, IsPlayer = isPlayer
        }
        
        local function ApplyVisuals(char)
            if not char then return end
            if not isPlayer then task.wait(0.2) if not char or not char.Parent then return end end

            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end

            box.Character = char
            
            if isPlayer then
                local hl = Instance.new("Highlight")
                hl.FillColor = COLOR_BLOCKED hl.OutlineColor = COLOR_BLOCKED
                hl.FillTransparency = 0.5 hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = char hl.Parent = char
                box.Highlight = hl
            end
            
            local distBb = Instance.new("BillboardGui")
            distBb.Name = "RomeoZach_DistBillboard" distBb.Size = UDim2.new(4, 0, 5.5, 0)
            distBb.AlwaysOnTop = true distBb.LightInfluence = 0
            distBb.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart", true)
            distBb.Parent = char box.DistBillboard = distBb
            
            local boxFrame = Instance.new("Frame", distBb)
            boxFrame.Size = UDim2.new(1, 0, 1, -20) boxFrame.BackgroundTransparency = 1 boxFrame.Visible = false
            local boxStroke = Instance.new("UIStroke", boxFrame)
            boxStroke.Thickness = 1.5 boxStroke.Color = COLOR_DEAD
            box.BoxFrame = boxFrame box.BoxStroke = boxStroke

            local distTxt = Instance.new("TextLabel", distBb)
            distTxt.Size = UDim2.new(1, 0, 0, 20) distTxt.Position = UDim2.new(0, 0, 1, -20)
            distTxt.BackgroundTransparency = 1 distTxt.Text = "" distTxt.TextColor3 = COLOR_BLOCKED
            distTxt.TextSize = 13 distTxt.Font = ESP_Config.Font distTxt.TextStrokeTransparency = 0
            distTxt.TextYAlignment = Enum.TextYAlignment.Top
            local uiStroke = Instance.new("UIStroke", distTxt) uiStroke.Thickness = 1.5
            box.DistLabel = distTxt
        end
        
        if isPlayer then if entity.Character then ApplyVisuals(entity.Character) end box.Connection = entity.CharacterAdded:Connect(ApplyVisuals) 
        else ApplyVisuals(entity) end
        ESP_Objects[entity] = box
    end

    --[[ MODULE 5: SCANNER UTILITIES ]]
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

        if obj:FindFirstChildOfClass("Tool") or obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then return true end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
        return false
    end

    --[[ MODULE 6: TARGETED ENTITY SCANNER ]]
    local isEntityScanning = false
    task.spawn(function()
        while task.wait(1.5) do 
            if not ESP_Config.ESP_Players and not ESP_Config.ESP_Corpses then continue end
            if isEntityScanning then continue end
            isEntityScanning = true
            
            local lpChar = LocalPlayer.Character
            if not lpChar then isEntityScanning = false; continue end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
            end

            local function ScanEntity(obj)
                if not obj:IsA("Model") then return end
                local nameLower = obj.Name:lower()
                if nameLower:find("effect") or nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("poster") or nameLower:find("decal") or nameLower:find("sign") or nameLower:find("prop") or nameLower:find("static") or nameLower:find("building") or nameLower:find("foliage") then return end

                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil
                if not isPlayerChar and not ESP_Objects[obj] then
                    if IsValidEntity(obj) then CreateESP(obj, false) end
                end
            end

            local foldersToScan = {workspace}
            if workspace:FindFirstChild("AiZones") then table.insert(foldersToScan, workspace.AiZones) end
            if workspace:FindFirstChild("Ignore") then table.insert(foldersToScan, workspace.Ignore) end
            
            local loopCount = 0
            for _, folder in ipairs(foldersToScan) do
                for _, child in ipairs(folder:GetChildren()) do
                    loopCount = loopCount + 1
                    if loopCount % 40 == 0 then task.wait(0.01) end
                    ScanEntity(child)
                    if folder.Name == "AiZones" then
                        for _, bot in ipairs(child:GetChildren()) do ScanEntity(bot) end
                    end
                end
            end
            isEntityScanning = false
        end
    end)

    --[[ MODULE 8: MISCELLANEOUS SCANNER ]]
    local function InitialPerformanceBoost()
        pcall(function() Lighting.FogEnd = 999999 Lighting.FogStart = 999999 end)
        for _, obj in ipairs(Lighting:GetDescendants()) do
            pcall(function()
                if obj:IsA("Atmosphere") then obj.Density = 0 elseif obj:IsA("Clouds") then obj.Enabled = false end
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
                        if not AmmoBackups[ammo] then AmmoBackups[ammo] = { Recoil = ammo:GetAttribute("RecoilStrength"), Spread = ammo:GetAttribute("AccuracyDeviation"), Drop = ammo:GetAttribute("ProjectileDrop") } end
                        ammo:SetAttribute("RecoilStrength", 0) ammo:SetAttribute("AccuracyDeviation", 0) ammo:SetAttribute("ProjectileDrop", 0)
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
                    Lighting.FogEnd = LightingBackups.FogEnd Lighting.FogStart = LightingBackups.FogStart
                    for obj, _ in pairs(DisabledEffects) do
                        if obj and obj.Parent then pcall(function() obj.Enabled = true end) end
                    end
                    table.clear(DisabledEffects)
                end
            end
            
            if ESP_Config.PerformanceMode then
                Lighting.GlobalShadows = false Lighting.FogEnd = 999999 Lighting.FogStart = 999999 Lighting.Brightness = 2.5
                Lighting.Ambient = Color3.fromRGB(140, 145, 155) Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155)
                
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

    --[[ MODULE 9: RENDER LOOP & AIMLOCK (ANTI-FREEZE BYPASS) ]]
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

            local rootPart = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
            if not rootPart then HideVisuals(); continue end

            if box.DistBillboard and (not box.DistBillboard.Adornee or not box.DistBillboard.Adornee.Parent) then box.DistBillboard.Adornee = rootPart end

            local rootPos = rootPart.Position
            local studsDist = (rootPos - cameraPos).Magnitude
            local distMeter = math.floor(studsDist / 3.5714285714)
            local isCloseRange = (studsDist <= 3.5714285714)

            local shouldRender = false
            if isDead then
                shouldRender = (studsDist <= 357.1429)
            else
                if box.IsPlayer then shouldRender = (studsDist <= 5357.1429) else shouldRender = (studsDist <= 2321.4286) end
            end

            if not shouldRender then HideVisuals(); continue end

            if isDead then
                box.CanBeAimlocked = false
                if box.Highlight then box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1 end
                
                if box.DistBillboard then
                    box.DistBillboard.Enabled = true
                    if box.BoxFrame then box.BoxFrame.Visible = true box.BoxStroke.Color = COLOR_DEAD end
                    if box.DistLabel then
                        box.DistLabel.Text = string.format("[ %d m ]", distMeter)
                        box.DistLabel.TextColor3 = COLOR_DEAD
                    end
                end
            else
                local targetPart = char:FindFirstChild("Head") or rootPart
                local isTeam = IsTeammate(char)
                
                -- OPTIMALISASI RENDER: Bypass Raycast jika musuh di luar jangkauan pandang monitor (Off-Screen)
                local _, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local canLock = false
                
                if onScreen then
                    local visStatus, cL = checkTargetVisibility(targetPart, char)
                    canLock = cL
                end
                
                local finalColor = canLock and COLOR_VISIBLE or COLOR_BLOCKED
                if isTeam then finalColor = canLock and COLOR_TEAM_VISIBLE or COLOR_TEAM_BLOCKED end
                box.CanBeAimlocked = (canLock and not isTeam)

                if box.IsPlayer then
                    if box.BoxFrame then box.BoxFrame.Visible = false end
                    if box.Highlight then
                        if isCloseRange then
                            box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1
                        else
                            box.Highlight.FillTransparency = 0.5 box.Highlight.OutlineTransparency = 0
                            box.Highlight.FillColor = finalColor box.Highlight.OutlineColor = finalColor
                        end
                    end
                else
                    if box.Highlight then box.Highlight.FillTransparency = 1 box.Highlight.OutlineTransparency = 1 end
                    if box.BoxFrame then box.BoxFrame.Visible = true box.BoxStroke.Color = finalColor end
                end

                if box.DistBillboard then
                    box.DistBillboard.Enabled = true
                    if box.DistLabel then box.DistLabel.Text = string.format("[%d m]", distMeter) box.DistLabel.TextColor3 = finalColor end
                end
            end
        end 

        if ESP_Config.AimLock and IsAiming then
            local potentialTargetEntity, potentialTargetChar = GetBestTargetInFOV()
            
            if potentialTargetChar then
                local rawHead = potentialTargetChar:FindFirstChild("Head") or potentialTargetChar:FindFirstChild("head")
                
                if rawHead then
                    local visStatus, canLock = checkTargetVisibility(rawHead, potentialTargetChar)
                    local isDead = IsEntityDead(potentialTargetChar)
                    local isTeammate = IsTeammate(potentialTargetChar)
                    
                    if canLock and not isDead and not isTeammate then
                        CurrentTargetEntity = potentialTargetEntity
                        CurrentTargetChar = potentialTargetChar
                        
                        local targetPos = rawHead.Position + Vector3.new(0, 0.15, 0)
                        local studsDist = (targetPos - cameraPos).Magnitude
                        
                        local bulletSpeedMS = GetBulletSpeed()
                        if bulletSpeedMS <= 0 then bulletSpeedMS = 800 end
                        local bulletSpeedStuds = bulletSpeedMS * 3.5714285714
                        
                        local dragFactor = 1 + (studsDist / 1200)
                        local realTime = (studsDist / bulletSpeedStuds) * dragFactor
                        
                        local targetRoot = potentialTargetChar:FindFirstChild("HumanoidRootPart")
                        local currentVelocity = targetRoot and targetRoot.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                        if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0, 0, 0) end
                        
                        local leadCompensation = currentVelocity * realTime
                        local dropCompensation = 0
                        if not ESP_Config.GunMods then dropCompensation = (0.5 * workspace.Gravity * (realTime * realTime)) end
                        
                        local finalAimPos = targetPos + leadCompensation + Vector3.new(0, dropCompensation, 0)
                        local _, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                        
                        if onScreenAim then
                            Camera.CFrame = CFrame.lookAt(cameraPos, finalAimPos)
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

    --[[ MODULE 10: INITIAL CONNECTIONS & PURGE ]]
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

if not success then warn("[Project Delta V8.2 Error]: " .. tostring(err)) end
