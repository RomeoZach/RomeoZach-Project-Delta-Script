--[[
    ================================================================================
    --|                                                                            |--
    --|      PROJECT DELTA V8.9 ULTIMATE - PERFORMANCE & PRECISION REVISION        |--
    --|                          Author  : RomeoZach                               |--
    --|                                                                            |--
    ================================================================================
    -- Changelog V8.9 (Gemini Refinement):
    -- 1. [LAG & FREEZE FIX] Merombak total fungsi `IsValidEntity` menjadi super ketat
    --    untuk mencegah "keracunan informasi" dari objek sampah (partikel, debris).
    --    Ini secara drastis mengurangi beban CPU dan menghilangkan lag berat.
    -- 2. [PERFORMANCE MODE FIX] Logika "Bright Night" dipindahkan ke RenderStep untuk
    --    secara konstan memaksa tingkat kecerahan, mengatasi masalah malam yang kembali gelap.
    -- 3. [AIMLOCK PRECISION FIX] Memperbaiki operator matematika pada kompensasi gravitasi.
    --    AimLock sekarang akan secara akurat mengarah lebih tinggi untuk target jarak jauh,
    --    memastikan tembakan tepat di kepala.
    -- 4. [STABILITY] Menambahkan validasi `RootPart.Parent` sebelum rendering untuk
    --    sepenuhnya menghilangkan bug "bintik-bintik putih" yang jatuh.
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
        
        Smoothing_Close = 0.7,
        Smoothing_Mid = 0.45,
        Smoothing_Far = 0.2,

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
    local targetGui = getHuiFunc and getHuiFunc() or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui", 15)
    
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
    chX.Size = UDim2.new(0, 14, 0, 2); chX.Position = UDim2.new(0.5, -7, 0.5, -1); chX.BackgroundColor3 = ESP_Config.Color; chX.BorderSizePixel = 0; chX.Visible = ESP_Config.Crosshair
    Instance.new("UIStroke", chX).Thickness = 1; table.insert(CrosshairLines, chX)
    
    local chY = Instance.new("Frame", RomeoZachGui)
    chY.Size = UDim2.new(0, 2, 0, 14); chY.Position = UDim2.new(0.5, -1, 0.5, -7); chY.BackgroundColor3 = ESP_Config.Color; chY.BorderSizePixel = 0; chY.Visible = ESP_Config.Crosshair
    Instance.new("UIStroke", chY).Thickness = 1; table.insert(CrosshairLines, chY)
    
    local MainFrame = Instance.new("Frame", RomeoZachGui)
    MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 480, 0, 250); MainFrame.Position = UDim2.new(0.5, -240, 0.5, -125); MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18) 
    MainFrame.BackgroundTransparency = 0.15; MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.Draggable = true
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Thickness = 1; MainStroke.Color = Color3.fromRGB(45, 48, 53); MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local Header = Instance.new("TextLabel", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundTransparency = 1; Header.Text = "Project Delta V8.9 - Performance & Precision"; Header.TextColor3 = Color3.fromRGB(240, 240, 245) 
    Header.TextSize = 14; Header.Font = Enum.Font.GothamBold; Header.TextXAlignment = Enum.TextXAlignment.Center
    
    local ContainerUI = Instance.new("Frame", MainFrame)
    ContainerUI.Size = UDim2.new(1, -20, 1, -45); ContainerUI.Position = UDim2.new(0, 10, 0, 35); ContainerUI.BackgroundTransparency = 1
    
    local UIGridLayout = Instance.new("UIGridLayout", ContainerUI)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10); UIGridLayout.CellSize = UDim2.new(0.5, -5, 0, 40)
    
    local function CreateToggle(labelText, configKey)
        local Frame = Instance.new("Frame", ContainerUI); Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27); Frame.BorderSizePixel = 0
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
        
        local Label = Instance.new("TextLabel", Frame); Label.Size = UDim2.new(0.65, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1 
        Label.Text = labelText; Label.TextColor3 = Color3.fromRGB(200, 200, 205); Label.TextSize = 12; Label.Font = Enum.Font.Gotham; Label.TextXAlignment = Enum.TextXAlignment.Left
        
        local Track = Instance.new("Frame", Frame); Track.Size = UDim2.new(0, 40, 0, 20); Track.Position = UDim2.new(1, -50, 0.5, -10) 
        Track.BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
        Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
        
        local Knob = Instance.new("Frame", Track); Knob.Size = UDim2.new(0, 16, 0, 16) 
        local knobActivePos = UDim2.new(1, -18, 0.5, -8); local knobInactivePos = UDim2.new(0, 2, 0.5, -8) 
        Knob.Position = ESP_Config[configKey] and knobActivePos or knobInactivePos; Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
        
        local Btn = Instance.new("TextButton", Track); Btn.Size = UDim2.new(1, 0, 1, 0); Btn.BackgroundTransparency = 1; Btn.Text = ""
        
        Btn.MouseButton1Click:Connect(function()
            ESP_Config[configKey] = not ESP_Config[configKey]
            local isActive = ESP_Config[configKey]
            TweenService:Create(Track, TweenInfo.new(0.2), {BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = isActive and knobActivePos or knobInactivePos}):Play()
            if configKey == "Crosshair" then for _, line in ipairs(CrosshairLines) do line.Visible = ESP_Config.Crosshair end end
        end)
        return Frame
    end
    
    CreateToggle("ESP - Players & AI", "ESP_Players"); CreateToggle("ESP - Corpses", "ESP_Corpses"); CreateToggle("Enable AimLock", "AimLock"); CreateToggle("ESP Wall Check", "VisCheck")
    CreateToggle("Yellow Bullet Tracers", "BulletTracers"); CreateToggle("Tiny Center Crosshair", "Crosshair"); CreateToggle("No Recoil & No Spread", "GunMods"); CreateToggle("Performance Mode", "PerformanceMode")

    -- [[ MODULE 2: INPUT, UTILITIES & OBJECT POOLING ]]
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.RightShift and not gp then MainFrame.Visible = not MainFrame.Visible end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end
    end)
    
    local function GetBulletSpeed()
        local defaultSpeed = 800; local char = LocalPlayer.Character; if not char then return defaultSpeed end
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
        if hum then return hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead end
        local nameLower = string.lower(char.Name)
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then return true end
        if char:IsA("Model") and char:FindFirstChild("Head") and not char:FindFirstChild("HumanoidRootPart") then return true end
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
                local lpStatus = lpData:FindFirstChild("Status"); local targetStatus = targetData:FindFirstChild("Status")
                if lpStatus and targetStatus then
                    local lpJourney = lpStatus:FindFirstChild("Journey"); local targetJourney = targetStatus:FindFirstChild("Journey")
                    if lpJourney and targetJourney then
                        local lpClanFolder = lpJourney:FindFirstChild("Clan"); local targetClanFolder = targetJourney:FindFirstChild("Clan")
                        if lpClanFolder and targetClanFolder then
                            local lpClan = lpClanFolder:GetAttribute("CurrentClan"); local targetClan = targetClanFolder:GetAttribute("CurrentClan")
                            if lpClan and targetClan and lpClan ~= "" and lpClan ~= "nil" and lpClan == targetClan then return true end
                        end
                    end
                end
            end
        end
        return false
    end

    local VisualPool = {}
    for i = 1, 150 do
        local hl = Instance.new("Highlight"); hl.Enabled = false; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = RomeoZachGui
        local bb = Instance.new("BillboardGui"); bb.Enabled = false; bb.Size = UDim2.new(4, 0, 5.5, 0); bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.Parent = RomeoZachGui
        local distTxt = Instance.new("TextLabel", bb); distTxt.Size = UDim2.new(1, 0, 1, 0); distTxt.Position = UDim2.new(0, 0, 0, 0); distTxt.BackgroundTransparency = 1 
        distTxt.TextSize = 13; distTxt.Font = ESP_Config.Font; distTxt.TextStrokeTransparency = 0; distTxt.TextYAlignment = Enum.TextYAlignment.Top
        Instance.new("UIStroke", distTxt).Thickness = 1.5
        local boxBb = Instance.new("BillboardGui"); boxBb.Enabled = false; boxBb.Size = UDim2.new(1.5, 0, 2.5, 0); boxBb.AlwaysOnTop = true; boxBb.LightInfluence = 0; boxBb.Parent = RomeoZachGui
        local boxFrame = Instance.new("Frame", boxBb); boxFrame.BackgroundTransparency = 1; boxFrame.Size = UDim2.new(1, 0, 1, 0)
        local boxStroke = Instance.new("UIStroke", boxFrame); boxStroke.Thickness = 1.5; boxStroke.LineJoinMode = Enum.LineJoinMode.Miter
        table.insert(VisualPool, {Highlight = hl, Billboard = bb, Text = distTxt, BoxBillboard = boxBb, BoxStroke = boxStroke, IsActive = false})
    end

    -- [[ MODULE 3: STATE CACHE & VISIBILITY ENGINE ]]
    local TrackedEntities = {} 
    local StateCache = {} 
    local AimDataCache = {Active = false, TargetPos = nil, TargetDist = 0}
    local GraveyardCache = {}; local RecentlyDeceased = {}
    
    local sharedRaycastParams = RaycastParams.new(); sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude; sharedRaycastParams.IgnoreWater = true
    local ignoreList = {}
    
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList); local origin = Camera.CFrame.Position; local targetPos = targetPart.Position; local direction = targetPos - origin
        if direction.Magnitude < 7 or not ESP_Config.VisCheck then return true end
        local lpChar = LocalPlayer.Character; if not lpChar or not lpChar:FindFirstChild("Head") then return false end
        table.insert(ignoreList, lpChar); table.insert(ignoreList, Camera)
        local extractionFolder = workspace:FindFirstChild("NoCollision") and workspace.NoCollision:FindFirstChild("ExitLocations"); if extractionFolder then table.insert(ignoreList, extractionFolder) end
        local ignoreFolder = workspace:FindFirstChild("Ignore"); if ignoreFolder then table.insert(ignoreList, ignoreFolder) end
        if targetChar then table.insert(ignoreList, targetChar) end
        
        for i = 1, 4 do
            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)
            if not raycastResult then return true end
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return false end
            if hitInstance:IsDescendantOf(targetChar) then return true end
            local parentModel = hitInstance:FindFirstAncestorOfClass("Model")
            if WallbangableMaterials[raycastResult.Material] or hitInstance.Transparency > 0.5 then
                table.insert(ignoreList, parentModel or hitInstance)
            else
                return false
            end
        end
        return false
    end

    -- THREAD 1: HEARTBEAT (MAIN LOGIC)
    RunService.Heartbeat:Connect(function(step)
        local now = tick()
        local lpChar = LocalPlayer.Character; if not lpChar then return end
        local camPos = Camera.CFrame.Position; local centerPos = Camera.ViewportSize / 2
        
        if now - (lastHeartbeat or 0) > 1/20 then
            lastHeartbeat = now
            for _, player in ipairs(Players:GetPlayers()) do
                local pChar = player.Character
                if pChar and pChar:FindFirstChild("HumanoidRootPart") and pChar:FindFirstChildOfClass("Humanoid") then
                    if pChar.Humanoid.Health <= 0 then
                        if not RecentlyDeceased[player] then
                            table.insert(GraveyardCache, { pos = pChar.HumanoidRootPart.Position, time = now }); RecentlyDeceased[player] = true
                        end
                    else RecentlyDeceased[player] = nil end
                else RecentlyDeceased[player] = nil end
            end
            for i = #GraveyardCache, 1, -1 do if now - GraveyardCache[i].time > 10 then table.remove(GraveyardCache, i) end end

            local lowestThreatScore = math.huge; local bestAimTargetPos = nil; local bestAimTargetDist = 0; local newStateCache = {}
            
            for entity, isPlayer in pairs(TrackedEntities) do
                if not entity or typeof(entity) ~= "Instance" or not entity.Parent then TrackedEntities[entity] = nil; continue end
                local char = (isPlayer and entity:IsA("Player") and entity.Character) or entity
                if not char or not char.Parent or char == lpChar then continue end
                local isDead = IsEntityDead(char)
                if (ESP_Config.PerformanceMode and isDead) or (not isDead and not ESP_Config.ESP_Players) or (isDead and not ESP_Config.ESP_Corpses) then continue end
                local head = char:FindFirstChild("Head") or char:FindFirstChild("head"); local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or head
                if not rootPart or not head then continue end
                local rootPos = rootPart.Position; local studsDist = (rootPos - camPos).Magnitude
                if (isDead and studsDist > 357) or (not isDead and studsDist > 5357) then continue end
                
                local isTeam = IsTeammate(char)
                local isActuallyPlayer = isPlayer
                if not isActuallyPlayer and isDead then
                    for _, p in ipairs(Players:GetPlayers()) do if char.Name:lower():find(p.Name:lower()) then isActuallyPlayer = true; break end end
                    if not isActuallyPlayer then
                        for i = #GraveyardCache, 1, -1 do
                            local entry = GraveyardCache[i]
                            if (rootPos - entry.pos).Magnitude < 2 then isActuallyPlayer = true; table.remove(GraveyardCache, i); break end
                        end
                    end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local priority = "Low"
                if onScreen and studsDist < 2857 then
                    priority = ((Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude < ESP_Config.FovRadius * 1.5) and "High" or "Medium"
                end

                local isVisible = false; local targetPart = head 
                if not isDead then
                    if priority == "High" then
                        isVisible = checkTargetVisibility(targetPart, char)
                        if isVisible and not isTeam and ESP_Config.AimLock and IsAiming then
                            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                            if screenDist <= ESP_Config.FovRadius and targetPart.Position.Magnitude > 25 then
                                local threatScore = (math.clamp(studsDist / 5357, 0, 1) * 0.3) + ((screenDist / ESP_Config.FovRadius) * 0.7)
                                if threatScore < lowestThreatScore then
                                    lowestThreatScore = threatScore
                                    local currentBulletSpeed = GetBulletSpeed(); local bulletSpeedStuds = (currentBulletSpeed > 0 and currentBulletSpeed or 800) * 3.57
                                    local realTime = studsDist / bulletSpeedStuds; local dropComp = 0
                                    if studsDist >= 150 and not ESP_Config.GunMods then 
                                        dropComp = 0.5 * workspace.Gravity * (realTime * realTime) -- [AIMLOCK PRECISION FIX] Menghapus 'dragFactor' yang menyebabkan kompensasi berlebihan.
                                    end
                                    local targetRoot = char:FindFirstChild("HumanoidRootPart"); local currentVelocity = (targetRoot and targetRoot.AssemblyLinearVelocity) or Vector3.new(0,0,0)
                                    if not (currentVelocity.X == currentVelocity.X) or currentVelocity.Magnitude > 200 then currentVelocity = Vector3.new(0,0,0) end
                                    local leadComp = currentVelocity * realTime * ((studsDist < 100) and 1.0 or ESP_Config.VelocityMultiplier)
                                    -- [AIMLOCK PRECISION FIX] Operator matematika dibalik untuk mengkompensasi gravitasi ke atas.
                                    local calculatedPos = targetPart.Position + leadComp + Vector3.new(0, dropComp, 0)
                                    if (calculatedPos.X == calculatedPos.X) then bestAimTargetPos = calculatedPos; bestAimTargetDist = studsDist end
                                end
                            end
                        end
                    elseif priority == "Medium" then isVisible = true end
                end
                newStateCache[entity] = {Char = char, IsPlayer = isActuallyPlayer, IsDead = isDead, IsTeam = isTeam, RootPart = rootPart, Dist = studsDist, IsVisible = isVisible, OnScreen = onScreen}
            end
            StateCache = newStateCache; AimDataCache.Active = (bestAimTargetPos ~= nil); AimDataCache.TargetPos = bestAimTargetPos; AimDataCache.TargetDist = bestAimTargetDist
        end
    end)

    -- [[ MODULE 4: ENTITY SCANNER LOOP ]]
    -- [LAG FIX] Fungsi IsValidEntity dibuat super ketat untuk memfilter "sampah".
    local function IsValidEntity(obj)
        if not obj:IsA("Model") or obj:IsDescendantOf(Camera) or (LocalPlayer.Character and obj == LocalPlayer.Character) then return false end
        local nameLower = obj.Name:lower()
        if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or nameLower:find("bag") or nameLower:find("satchel") or nameLower:find("register") or nameLower:find("safe") or nameLower:find("vault") or nameLower:find("desk") or nameLower:find("boulder") or nameLower:find("mesh") or nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") or nameLower:find("debris") or nameLower:find("foliage") then return false end
        if obj:FindFirstChildOfClass("Humanoid") then return true end
        if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")) then return true end
        if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") then return true end
        return false
    end

    task.spawn(function()
        while task.wait(1.5) do -- Frekuensi scan dipercepat sedikit
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and not TrackedEntities[p] then TrackedEntities[p] = true end end
                for _, child in ipairs(workspace:GetChildren()) do
                    if child:IsA("Model") and not TrackedEntities[child] and IsValidEntity(child) then TrackedEntities[child] = false end
                end
                local aiZones = workspace:FindFirstChild("AiZones")
                if aiZones then
                    for _, bot in ipairs(aiZones:GetDescendants()) do
                        if bot:IsA("Model") and not TrackedEntities[bot] and IsValidEntity(bot) then TrackedEntities[bot] = false end
                    end
                end
            end)
        end
    end)
    Players.PlayerRemoving:Connect(function(p) TrackedEntities[p] = nil end)

    -- [[ MODULE 5: MISCELLANEOUS & PERFORMANCE SCANNER ]]
    task.spawn(function()
        while task.wait(3) do
            pcall(function()
                local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
                if ammoTypes then
                    for _, ammo in pairs(ammoTypes:GetChildren()) do
                        if ESP_Config.GunMods then
                            if not AmmoBackups[ammo] then AmmoBackups[ammo] = { Recoil = ammo:GetAttribute("RecoilStrength"), Spread = ammo:GetAttribute("AccuracyDeviation"), Drop = ammo:GetAttribute("ProjectileDrop") } end
                            ammo:SetAttribute("RecoilStrength", 0); ammo:SetAttribute("AccuracyDeviation", 0); ammo:SetAttribute("ProjectileDrop", 0)
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
            end)
        end
    end)

    -- [[ MODULE 6: ZERO-LAG RENDER LOOP ]]
    RunService:BindToRenderStep("RomeoZach_Render", 2005, function()
        -- [PERFORMANCE MODE FIX] Logika Bright Night dipindahkan ke sini agar konstan.
        if ESP_Config.PerformanceMode then -- Menggunakan nilai dari referensi V8.2 untuk kenyamanan visual.
            Lighting.Brightness = 2.5; Lighting.Ambient = Color3.fromRGB(140, 145, 155); Lighting.OutdoorAmbient = Color3.fromRGB(140, 145, 155); Lighting.GlobalShadows = false
            if not LastPerformanceState then LastPerformanceState = true end
        elseif LastPerformanceState then
            Lighting.Brightness = LightingBackups.Brightness; Lighting.Ambient = LightingBackups.Ambient; Lighting.OutdoorAmbient = LightingBackups.OutdoorAmbient; Lighting.GlobalShadows = LightingBackups.GlobalShadows
            LastPerformanceState = false
        end

        local poolIndex = 1; local camPos = Camera.CFrame.Position
        for i, ui in ipairs(VisualPool) do if ui.IsActive then ui.IsActive = false; ui.Highlight.Enabled = false; ui.Billboard.Enabled = false; ui.BoxBillboard.Enabled = false end end
        
        for entity, data in pairs(StateCache) do
            if poolIndex > 150 then break end
            -- [STABILITY FIX] Validasi RootPart sebelum render untuk mencegah error "bintik putih".
            if not data.RootPart or not data.RootPart.Parent then continue end

            local ui = VisualPool[poolIndex]; ui.IsActive = true
            local finalColor
            if data.IsDead then finalColor = COLOR_DEAD
            elseif data.IsTeam then finalColor = data.IsVisible and COLOR_TEAM_VISIBLE or COLOR_TEAM_BLOCKED
            else finalColor = data.IsVisible and COLOR_VISIBLE or COLOR_BLOCKED end

            if data.IsDead and data.IsPlayer then
                ui.BoxBillboard.Enabled = true; ui.BoxBillboard.Adornee = data.RootPart; ui.BoxStroke.Color = COLOR_DEAD
            else
                if data.IsTeam then
                    ui.Highlight.Enabled = false; ui.BoxBillboard.Enabled = false
                elseif data.IsPlayer then
                    ui.Highlight.Enabled = true; ui.Highlight.Adornee = data.Char; ui.Highlight.FillColor = finalColor; ui.Highlight.OutlineColor = finalColor
                else 
                    ui.BoxBillboard.Enabled = true; ui.BoxBillboard.Adornee = data.RootPart; ui.BoxStroke.Color = finalColor
                end
                ui.Billboard.Enabled = true; ui.Billboard.Adornee = data.RootPart
                ui.Text.Text = string.format("[%d m]", math.floor(data.Dist / 3.57)); ui.Text.TextColor3 = finalColor
            end
            poolIndex = poolIndex + 1
        end
        
        if ESP_Config.AimLock and IsAiming and AimDataCache.Active then
            local targetCFrame = CFrame.lookAt(camPos, AimDataCache.TargetPos)
            local dynamicSmoothing
            local distInStuds = AimDataCache.TargetDist
            if distInStuds < 178 then dynamicSmoothing = ESP_Config.Smoothing_Close
            elseif distInStuds < 714 then dynamicSmoothing = ESP_Config.Smoothing_Mid
            else dynamicSmoothing = ESP_Config.Smoothing_Far end
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, dynamicSmoothing)
        end
    end)

end)

if not success then
    warn("[Project Delta V8.9 Error]: " .. tostring(err))
end
