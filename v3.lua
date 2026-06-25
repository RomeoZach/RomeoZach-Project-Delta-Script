--[[
    ================================================================================
    --|                                                                            |--
    --|      PROJECT DELTA V8.8 ULTIMATE - STABLE & REFINED EDITION                |--
    --|                          Author  : RomeoZach                               |--
    --|                                                                            |--
    ================================================================================
    -- Changelog V8.8 (Gemini Refinement):
    -- 1. [STABILITY] Mengembalikan arsitektur rendering ke metode "clear-and-redraw"
    --    yang terbukti stabil dari V8.7 untuk menghilangkan bug ESP hilang total.
    -- 2. [AIMLOCK FIX] Menambahkan "Sanity Check" pada kecepatan target untuk
    --    sepenuhnya menghilangkan bug AimLock 'flick' ke tanah.
    -- 3. [CORPSE ESP FIX] Logika IsValidEntity dan render loop diperbaiki untuk
    --    memastikan ESP mayat (ungu) tampil secara konsisten dalam jarak deteksi.
    -- 4. [PERFORMANCE] Fitur PerformanceMode disederhanakan agar tidak menyebabkan
    --    lag saat diaktifkan/dinonaktifkan.
--]]

-- Filter Log Error yang tidak relevan
local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        return
    end
end)

local success, err = pcall(function()

    -- [[ MODULE 1: CORE CONFIG & UI SETUP ]]
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
        FovRadius = 300,
        
        Smoothing = 0.45, 
        VelocityMultiplier = 1.35,
        ThreatWeights = { DistanceWeight = 0.3, ScreenWeight = 0.7 }
    }
    
    local COLOR_VISIBLE = ESP_Config.Color
    local COLOR_BLOCKED = Color3.fromRGB(160, 160, 165)
    local COLOR_DEAD = Color3.fromRGB(221, 160, 221)
    local COLOR_TEAM_VISIBLE = Color3.fromRGB(50, 255, 50)
    local COLOR_TEAM_BLOCKED = Color3.fromRGB(0, 150, 0)
    
    local IsAiming = false
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
    Header.Text = "Project Delta V8.8 - Stable & Refined" 
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
            TweenService:Create(Track, TweenInfo.new(0.2), {BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = isActive and knobActivePos or knobInactivePos}):Play()
            if configKey == "Crosshair" then for _, line in ipairs(CrosshairLines) do line.Visible = ESP_Config.Crosshair end end
        end)
        return Frame
    end
    
    CreateToggle("ESP - Players & AI", "ESP_Players") 
    CreateToggle("ESP - Corpses", "ESP_Corpses")
    CreateToggle("Enable AimLock", "AimLock") 
    CreateToggle("ESP Wall Check", "VisCheck")
    CreateToggle("Yellow Bullet Tracers", "BulletTracers") 
    CreateToggle("Tiny Center Crosshair", "Crosshair")
    CreateToggle("No Recoil & No Spread", "GunMods") 
    CreateToggle("Performance Mode", "PerformanceMode")

    -- [[ MODULE 2: INPUT, UTILITIES & OBJECT POOLING ]]
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
            for _, desc in ipairs(tool:GetDescendants()) do
                if desc:IsA("ModuleScript") then
                    local s, data = pcall(require, desc)
                    if s and type(data) == "table" then
                        local dynamicSpeed = data.MuzzleVelocity or data.BulletSpeed or data.Velocity or data.Speed
                        if dynamicSpeed and type(dynamicSpeed) == "number" then 
                            return dynamicSpeed 
                        end
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
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
            return true 
        end
        if char:IsA("Model") and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") == nil then 
            return true 
        end
        return false
    end

    local function IsTeammate(char)
        if not char or not char.Parent then return false end
        
        local targetPlayer = Players:GetPlayerFromCharacter(char)
    
        if targetPlayer then
            if targetPlayer == LocalPlayer then return true end
            if targetPlayer.Team and LocalPlayer.Team and targetPlayer.Team == LocalPlayer.Team then return true end
        end
    
        local rsPlayers = ReplicatedStorage:FindFirstChild("Players")
        if rsPlayers then
            local lpData = rsPlayers:FindFirstChild(LocalPlayer.Name)
            local targetData = targetPlayer and rsPlayers:FindFirstChild(targetPlayer.Name) or rsPlayers:FindFirstChild(char.Name)
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
                            if lpClan and targetClan and lpClan ~= "" and lpClan ~= "nil" and lpClan == targetClan then return true end
                        end
                    end
                end
            end
        end
    
        local names = {"Squad", "Group", "Party", "Faction"}
        for _, name in ipairs(names) do
            local vMine = (targetPlayer and targetPlayer:FindFirstChild(name)) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))
            local vTarget = (targetPlayer and targetPlayer:FindFirstChild(name)) or char:FindFirstChild(name)
            if vTarget and vMine and vTarget:IsA("StringValue") and vMine:IsA("StringValue") and vTarget.Value ~= "" and vTarget.Value == vMine.Value then return true end
        end
    
        return false
    end

    local VisualPool = {}
    local MAX_POOL = 150
    for i = 1, MAX_POOL do
        local hl = Instance.new("Highlight")
        hl.Enabled = false 
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
        hl.Parent = RomeoZachGui
        
        local bb = Instance.new("BillboardGui")
        bb.Enabled = false 
        bb.Size = UDim2.new(4, 0, 5.5, 0) 
        bb.AlwaysOnTop = true 
        bb.LightInfluence = 0 
        bb.Parent = RomeoZachGui
        
        local distTxt = Instance.new("TextLabel", bb)
        distTxt.Size = UDim2.new(1, 0, 1, 0) 
        distTxt.Position = UDim2.new(0, 0, 0, 0)
        distTxt.BackgroundTransparency = 1 
        distTxt.TextSize = 13 
        distTxt.Font = ESP_Config.Font 
        distTxt.TextStrokeTransparency = 0 
        distTxt.TextYAlignment = Enum.TextYAlignment.Top
        
        local uiStroke = Instance.new("UIStroke", distTxt) 
        uiStroke.Thickness = 1.5
        
        local boxBb = Instance.new("BillboardGui")
        boxBb.Enabled = false
        boxBb.Size = UDim2.new(1.5, 0, 2.5, 0)
        boxBb.AlwaysOnTop = true
        boxBb.LightInfluence = 0
        boxBb.Parent = RomeoZachGui

        local boxFrame = Instance.new("Frame", boxBb)
        boxFrame.BackgroundTransparency = 1
        boxFrame.Size = UDim2.new(1, 0, 1, 0)

        local boxStroke = Instance.new("UIStroke", boxFrame)
        boxStroke.Thickness = 1.5
        boxStroke.LineJoinMode = Enum.LineJoinMode.Miter
        
        table.insert(VisualPool, {
            Highlight = hl, 
            Billboard = bb, 
            Text = distTxt, 
            BoxBillboard = boxBb,
            BoxStroke = boxStroke,
            IsActive = false
        })
    end

    -- [[ MODULE 3: STATE CACHE & DYNAMIC THREAT WEIGHT ]]
    local TrackedEntities = {} 
    local StateCache = {} 
    local AimDataCache = {Active = false, TargetPos = nil}
    
    local sharedRaycastParams = RaycastParams.new()
    sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    sharedRaycastParams.IgnoreWater = true
    local ignoreList = {}
    
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)
        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        
        if direction.Magnitude < 7 then return true end
        if not ESP_Config.VisCheck then return true end
        
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then return false end
        
        table.insert(ignoreList, lpChar) 
        table.insert(ignoreList, Camera)
        
        local extractionFolder = workspace:FindFirstChild("NoCollision") and workspace.NoCollision:FindFirstChild("ExitLocations")
        if extractionFolder then
            table.insert(ignoreList, extractionFolder)
        end
        
        local ignoreFolder = workspace:FindFirstChild("Ignore") 
        if ignoreFolder then table.insert(ignoreList, ignoreFolder) end
        if targetChar then table.insert(ignoreList, targetChar) end
        
        local loopCounter = 0
        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 4 then return false end 
            
            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)
            if not raycastResult then return true end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return false end
            if hitInstance:IsDescendantOf(targetChar) then return true end
            
            local parentModel = hitInstance:FindFirstAncestorOfClass("Model")
            local isWallbangMat = WallbangableMaterials[raycastResult.Material]
            local nameLow = hitInstance.Name:lower()
            local parentNameLow = parentModel and parentModel.Name:lower() or ""
            
            local isWallbangName = (nameLow:find("wood") or nameLow:find("plank") or nameLow:find("glass") or 
                    nameLow:find("door") or nameLow:find("window") or nameLow:find("fence") or 
                    parentNameLow:find("house") or parentNameLow:find("hut") or parentNameLow:find("shack") or 
                    parentNameLow:find("cabin") or parentNameLow:find("building"))
            
            if isWallbangMat or isWallbangName or hitInstance.Transparency > 0.5 then
                table.insert(ignoreList, parentModel or hitInstance)
            else
                return false
            end
        end
    end

    -- THREAD 1: HEARTBEAT
    local lastHeartbeat = 0
    local heartbeatInterval = 1/20 -- [PERFORMANCE FIX] Mengurangi frekuensi kalkulasi berat untuk menghilangkan freeze.

    RunService.Heartbeat:Connect(function(step)
        local now = tick()
        if now - lastHeartbeat < heartbeatInterval then return end
        lastHeartbeat = now

        task.defer(function()
            local lpChar = LocalPlayer.Character
            if not lpChar then return end
            
            local camPos = Camera.CFrame.Position
            local centerPos = Camera.ViewportSize / 2
            
            local lowestThreatScore = math.huge
            local bestAimTargetPos = nil
            local newStateCache = {}
            
            for entity, isPlayer in pairs(TrackedEntities) do
                if not entity or typeof(entity) ~= "Instance" or not entity.Parent then 
                    TrackedEntities[entity] = nil 
                    continue 
                end
                
                local char = (isPlayer and entity:IsA("Player") and entity.Character) or entity
                if not char or not char.Parent or char == lpChar then continue end
                
                local isDead = IsEntityDead(char)
                
                if ESP_Config.PerformanceMode and isDead then continue end
                if not isDead and not ESP_Config.ESP_Players then continue end
                if isDead and not ESP_Config.ESP_Corpses then continue end
                
                local head = char:FindFirstChild("Head") or char:FindFirstChild("head")
                local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or head
                if not rootPart or not head then continue end
                local rootPos = rootPart.Position
                local studsDist = (rootPos - camPos).Magnitude
                
                -- [CORPSE ESP FIX] Jarak deteksi mayat dikembalikan ke 100m (357 studs).
                if (isDead and studsDist > 357) or (not isDead and studsDist > 5357.1429) then
                    continue
                end
                
                local isTeam = IsTeammate(char)
                
                -- [CORPSE ESP FIX] Logika untuk memastikan mayat pemain tetap teridentifikasi sebagai pemain.
                local isActuallyPlayer = isPlayer
                if not isActuallyPlayer and isDead then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if char.Name:lower():find(p.Name:lower()) then isActuallyPlayer = true; break end
                    end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local isVisible = false
                
                local targetPart = head 
                
                if not isDead then
                    isVisible = checkTargetVisibility(targetPart, char)
                    
                    if isVisible and not isTeam and ESP_Config.AimLock and IsAiming then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        
                        if screenDist <= ESP_Config.FovRadius then
                            local normScreen = screenDist / ESP_Config.FovRadius
                            local normDist = math.clamp(studsDist / 5357.1429, 0, 1)
                            local threatScore = (normDist * ESP_Config.ThreatWeights.DistanceWeight) + (normScreen * ESP_Config.ThreatWeights.ScreenWeight)
                            
                            if threatScore < lowestThreatScore then
                                lowestThreatScore = threatScore
                                
                                local currentBulletSpeed = GetBulletSpeed()
                                local bulletSpeedStuds = (currentBulletSpeed > 0 and currentBulletSpeed or 800) * 3.5714285714
                                local realTime = studsDist / bulletSpeedStuds
                                local dropComp = 0
                                
                                if studsDist >= 150 and not ESP_Config.GunMods then 
                                    local dragFactor = 1 + (studsDist / 6000)
                                    realTime = realTime * dragFactor
                                    dropComp = 0.5 * workspace.Gravity * (realTime * realTime)
                                else
                                    dropComp = 0
                                end
                                
                                local targetRoot = char:FindFirstChild("HumanoidRootPart")
                                local currentVelocity = (targetRoot and targetRoot.AssemblyLinearVelocity) or Vector3.new(0,0,0)
                                if not (currentVelocity.X == currentVelocity.X and currentVelocity.Y == currentVelocity.Y and currentVelocity.Z == currentVelocity.Z) then currentVelocity = Vector3.new(0,0,0) end
                                if currentVelocity.Magnitude > 200 then currentVelocity = Vector3.new(0,0,0) end
                                
                                local velocityMultiplier = (studsDist < 100) and 1.0 or ESP_Config.VelocityMultiplier
                                local leadComp = currentVelocity * realTime * velocityMultiplier
                                
                                bestAimTargetPos = targetPart.Position + leadComp + Vector3.new(0, dropComp, 0)
                            end
                        end
                    end
                end
                
                newStateCache[entity] = {
                    Char = char, IsPlayer = isActuallyPlayer, IsDead = isDead, IsTeam = isTeam,
                    RootPart = rootPart, Dist = studsDist, IsVisible = isVisible, OnScreen = onScreen
                }
            end
            
            StateCache = newStateCache
            AimDataCache.Active = (bestAimTargetPos ~= nil)
            AimDataCache.TargetPos = bestAimTargetPos 
        end)
    end)

    -- [[ MODULE 4: ENTITY SCANNER LOOP ]]
    local function IsValidEntity(obj)
        if not obj:IsA("Model") then return false end
        if obj.Name == LocalPlayer.Name or (LocalPlayer.Character and obj == LocalPlayer.Character) then return false end
        if obj:IsDescendantOf(Camera) then return false end
        
        local nameLower = string.lower(obj.Name)
        if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or nameLower:find("bag") or 
            nameLower:find("satchel") or nameLower:find("register") or nameLower:find("safe") or nameLower:find("vault") or 
            nameLower:find("desk") or nameLower:find("boulder") or nameLower:find("mesh") then return false end
        if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") then 
            return false end
        
        -- [FIX] Menghapus filter baju/celana yang salah
        -- if not obj:FindFirstChildOfClass("Shirt") and not obj:FindFirstChildOfClass("Pants") then
        --     if not (nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll")) then return false end
        -- end

        local npcKeywords = {"dozer", "anton", "guard", "bandit", "rat", "sniper", "marksman", "highway", "tunnel", "occupant", 
                            "survey", "team", "member", "soldier", "whisper", "scav", "king", "uno", "peace", "keeper", "death"}
        for _, kw in ipairs(npcKeywords) do if nameLower:find(kw) then return true end end
        if obj:FindFirstChildOfClass("Tool") or obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or 
            obj:FindFirstChild("UpperTorso")) then return true end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or 
            nameLower:find("body") then return true end
        return false
    end

    local isEntityScanning = false
    task.spawn(function()
        while task.wait(1.0) do 
            if isEntityScanning then continue end
            isEntityScanning = true
            
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and TrackedEntities[p] == nil then TrackedEntities[p] = true end
            end
            
            local function ScanEntity(obj)
                if not obj or not obj:IsA("Model") then return end
                local nameLow = obj.Name:lower()
                if nameLow:find("effect") or nameLow:find("bullet") or nameLow:find("tracer") or nameLow:find("poster") or 
                    nameLow:find("decal") or nameLow:find("sign") or nameLow:find("prop") or nameLow:find("static") or 
                    nameLow:find("building") or nameLow:find("foliage") then return end
                
                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil
                if not isPlayerChar and TrackedEntities[obj] == nil and IsValidEntity(obj) then
                    TrackedEntities[obj] = false 
                end
                
                local targetPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local distToTarget = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    if distToTarget > 1600 and distToTarget <= 5357 then
                        task.spawn(function()
                            pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, targetPart.Position)
                        end)
                    end
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
                    
                    if folder.Name == "AiZones" and child:IsA("Folder") then
                        for _, bot in ipairs(child:GetChildren()) do ScanEntity(bot) end
                    end
                end
            end
            isEntityScanning = false
        end
    end)
    
    Players.PlayerRemoving:Connect(function(p) TrackedEntities[p] = nil end)

    -- [[ MODULE 5: MISCELLANEOUS & PERFORMANCE SCANNER ]]
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
            local nameLow = obj.Name:lower()
            if nameLow:find("rain") then
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then pcall(function() obj.Enabled = false end)
                elseif obj:IsA("Sound") then pcall(function() obj.Volume = 0; obj:Stop() end) end
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
                            AmmoBackups[ammo] = { Recoil = ammo:GetAttribute("RecoilStrength"), Spread = ammo:GetAttribute("AccuracyDeviation"), Drop = ammo:GetAttribute("ProjectileDrop") } 
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
                    Lighting.GlobalShadows = false
                    Lighting.Brightness = LightingBackups.Brightness + 0.3
                else
                    Lighting.GlobalShadows = LightingBackups.GlobalShadows
                    Lighting.Brightness = LightingBackups.Brightness
                end
            end
        end
    end)

    -- [[ MODULE 6: ZERO-LAG RENDER LOOP ]]
    RunService:BindToRenderStep("RomeoZach_Render", 2005, function()
        local poolIndex = 1
        local camPos = Camera.CFrame.Position
        
        for i, ui in ipairs(VisualPool) do
            if ui.IsActive then
                ui.IsActive = false
                ui.Highlight.Enabled = false
                ui.Billboard.Enabled = false
                ui.BoxBillboard.Enabled = false
            end
        end
        
        for entity, data in pairs(StateCache) do
            if poolIndex > MAX_POOL then break end
            
            local ui = VisualPool[poolIndex]
            ui.IsActive = true
            
            local distMeter = math.floor(data.Dist / 3.5714285714)
            
            local finalColor
            if data.IsDead then
                finalColor = COLOR_DEAD
            elseif data.IsTeam then
                finalColor = data.IsVisible and COLOR_TEAM_VISIBLE or COLOR_TEAM_BLOCKED
            else
                finalColor = data.IsVisible and COLOR_VISIBLE or COLOR_BLOCKED
            end

            -- [CORPSE ESP FIX] Kondisi diubah agar hanya menggambar kotak untuk mayat PEMAIN.
            if data.IsDead and data.IsPlayer then
                ui.BoxBillboard.Enabled = true
                ui.BoxBillboard.Adornee = data.RootPart
                ui.BoxStroke.Color = COLOR_DEAD
            else
                -- [OPTIMISASI] Jika rekan tim, matikan Chams/Box dan hanya tampilkan teks jarak.
                if data.IsTeam then
                    ui.Highlight.Enabled = false
                    ui.BoxBillboard.Enabled = false
                elseif data.IsPlayer then -- Musuh Player
                    ui.Highlight.Enabled = true
                    ui.Highlight.Adornee = data.Char
                    ui.Highlight.FillColor = finalColor
                    ui.Highlight.OutlineColor = finalColor
                else -- Musuh AI
                    ui.BoxBillboard.Enabled = true
                    ui.BoxBillboard.Adornee = data.RootPart
                    ui.BoxStroke.Color = finalColor
                end

                ui.Billboard.Enabled = true
                ui.Billboard.Adornee = data.RootPart
                ui.Text.Text = string.format("[%d m]", distMeter)
                ui.Text.TextColor3 = finalColor
            end
            
            poolIndex = poolIndex + 1
        end
        
        if ESP_Config.AimLock and IsAiming and AimDataCache.Active then
            local targetCFrame = CFrame.lookAt(camPos, AimDataCache.TargetPos)
            local newCFrame = Camera.CFrame:Lerp(targetCFrame, ESP_Config.Smoothing)
            Camera.CFrame = newCFrame
        end
    end)

end)

if not success then
    warn("[Project Delta V8.8 Error]: " .. tostring(err))
end
