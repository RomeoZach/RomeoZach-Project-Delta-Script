-- [[ ROMEOZACH SC - Project Delta v8 Ultimate (Rebuilt from Scratch) ]]
-- Author: RomeoZach & Gemini Code Assist (Unified Entity System & Advanced Features)

-- // Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

-- // Core Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Master Configuration State
local ESP_Config = {
    Enabled = true,
    AimLock = true,
    WeaponChams = true,
    BulletTracers = true,
    Crosshair = true,
    VisCheck = true,
    GunMods = false, -- No Recoil & No Spread
    FindWeapons = false, -- Item Finder for Guns
    FindValuables = false, -- Item Finder for Valuables
    PerformanceMode = false,
    -- UI & Visual Settings
    Color = Color3.fromRGB(0, 180, 255),
    WeaponColor = Color3.fromRGB(255, 255, 0),
    BulletColor = Color3.fromRGB(255, 255, 0),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    FovRadius = 999999
}

-- // ESP Theme Colors
local COLOR_VISIBLE = Color3.fromRGB(255, 255, 255) -- White
local COLOR_BLOCKED = Color3.fromRGB(160, 160, 165) -- Gray
local COLOR_DEAD    = Color3.fromRGB(150, 90, 220)  -- Purple (Corpse ESP)

-- // Runtime Tables
local ESP_Objects = {}
local IsAiming = false
local CurrentTargetChar = nil
local WeaponConnections = {}
local ActiveBulletTracers = {}
local CrosshairLines = {}
local AmmoBackups = {} -- For Gun Mods
local TextureBackups = {}
local LightingBackups = {
    GlobalShadows = Lighting.GlobalShadows,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime
}

-- // Game-Specific Data
local WallbangableMaterials = {
    [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true,
    [Enum.Material.Fabric] = true, [Enum.Material.Plastic] = true,
    [Enum.Material.Glass] = true, [Enum.Material.Cardboard] = true,
    [Enum.Material.Sand] = true
}

-- // Raycast Parameters (Zero-Allocation)
local sharedRaycastParams = RaycastParams.new()
sharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
sharedRaycastParams.IgnoreWater = true
local ignoreList = {}

-- // UI Framework
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
if PlayerGui:FindFirstChild("RomeoZach_Ui") then 
    pcall(function() PlayerGui.RomeoZach_Ui:Destroy() end)
end

local SmokeW99D = Instance.new("ScreenGui")
SmokeW99D.Name = "RomeoZach_Ui"
SmokeW99D.ResetOnSpawn = false
SmokeW99D.DisplayOrder = 999999
SmokeW99D.Parent = PlayerGui

local MainFrame = Instance.new("Frame", SmokeW99D)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 600) -- Increased height for new toggles
MainFrame.Position = UDim2.new(0.5, -160, 0.4, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(45, 48, 53)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Header = Instance.new("TextLabel", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundTransparency = 1
Header.Text = "  Project Delta SC - Rebuilt"
Header.TextColor3 = Color3.fromRGB(240, 240, 245)
Header.TextSize = 14
Header.Font = Enum.Font.GothamBold
Header.TextXAlignment = Enum.TextXAlignment.Left

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 35)
Container.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)

local function CreateToggle(labelText, configKey)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27)
    Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(200, 200, 205)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(0, 45, 0, 22)
    Btn.Position = UDim2.new(1, -55, 0.5, -11)
    Btn.BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

    Btn.MouseButton1Click:Connect(function()
        ESP_Config[configKey] = not ESP_Config[configKey]
        TweenService:Create(Btn, TweenInfo.new(0.2), {
            BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
        }):Play()
        if configKey == "AimLock" and not ESP_Config.AimLock then CurrentTargetChar = nil end
    end)
    return Btn
end

-- // UI Elements
local ToggleBtn = CreateToggle("Enable Visuals", "Enabled")
local LockBtn = CreateToggle("Enable AimLock", "AimLock")
local ChamsBtn = CreateToggle("Weapon Chams", "WeaponChams")
local BulletTracersBtn = CreateToggle("Yellow Bullet Tracers", "BulletTracers")
local CrosshairBtn = CreateToggle("Tiny Center Crosshair", "Crosshair")
local GunModsBtn = CreateToggle("No Recoil & No Spread", "GunMods")
local FindWeaponsBtn = CreateToggle("Find Guns (M4, Val, SPSh..)", "FindWeapons")
local FindValuablesBtn = CreateToggle("Find Valuables (Gold, Key..)", "FindValuables")
local PerformanceBtn = CreateToggle("Performance Mode", "PerformanceMode")

-- // Performance Mode Logic & HUD
PerformanceBtn.MouseButton1Click:Connect(function()
    if ESP_Config.PerformanceMode then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Terrain") or obj.Name == "Terrain" then continue end
            
            if obj:IsA("ParticleEmitter") and (obj.Name:lower():find("rain") or obj.Name:lower():find("storm")) then
                TextureBackups[obj] = obj.Enabled; obj.Enabled = false
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                TextureBackups[obj] = obj.Texture; obj.Texture = ""
            elseif obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                TextureBackups[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogStart = 999999
        Lighting.FogEnd = 999999
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
        Lighting.ClockTime = 12 -- Force bright daytime
    else
        for obj, val in pairs(TextureBackups) do
            if obj and obj.Parent then
                if obj:IsA("Texture") or obj:IsA("Decal") then obj.Texture = val
                elseif obj:IsA("BasePart") then obj.Material = val
                elseif obj:IsA("ParticleEmitter") then obj.Enabled = val end
            end
        end
        table.clear(TextureBackups)
        Lighting.GlobalShadows = LightingBackups.GlobalShadows
        Lighting.FogStart = LightingBackups.FogStart
        Lighting.FogEnd = LightingBackups.FogEnd
        Lighting.Ambient = LightingBackups.Ambient
        Lighting.OutdoorAmbient = LightingBackups.OutdoorAmbient
        Lighting.Brightness = LightingBackups.Brightness
        Lighting.ClockTime = LightingBackups.ClockTime or 14
    end
end)

local HudFrame = Instance.new("Frame", SmokeW99D)
HudFrame.Name = "PerformanceHUD"
HudFrame.Size = UDim2.new(0, 140, 0, 75)
HudFrame.Position = UDim2.new(0, 20, 0.4, 0)
HudFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18)
HudFrame.BackgroundTransparency = 0.2
HudFrame.BorderSizePixel = 0
HudFrame.Active = true; HudFrame.Draggable = true
Instance.new("UICorner", HudFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", HudFrame).Color = Color3.fromRGB(45, 48, 53)

local HudList = Instance.new("UIListLayout", HudFrame)
HudList.Padding = UDim.new(0, 2)
HudList.HorizontalAlignment = Enum.HorizontalAlignment.Center
HudList.VerticalAlignment = Enum.VerticalAlignment.Center

local function CreateHudLabel(name)
    local Label = Instance.new("TextLabel", HudFrame)
    Label.Size = UDim2.new(1, -16, 0, 18)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(230, 230, 235)
    Label.TextSize = 12
    Label.Font = Enum.Font.Code
    Label.TextXAlignment = Enum.TextXAlignment.Left
    return Label
end

local FpsLabel = CreateHudLabel("FPS")
local PingLabel = CreateHudLabel("Ping")
local TimeLabel = CreateHudLabel("Time")

local fpsCount = 0
RunService.RenderStepped:Connect(function() fpsCount = fpsCount + 1 end)
task.spawn(function()
    while task.wait(1) do 
        FpsLabel.Text = string.format("FPS: %d", fpsCount)
        fpsCount = 0
        pcall(function() PingLabel.Text = string.format("Ping: %d ms", math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end)
        TimeLabel.Text = os.date("%X")
    end
end)

-- // Input Handling
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift and not gp then
        MainFrame.Visible = not MainFrame.Visible
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end
end)

-- // Utility Functions
local function GetBulletSpeed()
    local defaultSpeed = 1500
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        local settingsModule = tool:FindFirstChild("Setting") or tool:FindFirstChild("WeaponSettings")
        if settingsModule and settingsModule:IsA("ModuleScript") then
            local success, data = pcall(require, settingsModule)
            if success and type(data) == "table" then
                return data.BulletSpeed or data.MuzzleVelocity or defaultSpeed
            end
        end
    end
    return defaultSpeed
end

local function IsEntityDead(char)
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    if hum == nil and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")) then return true end
    local nameLower = char.Name:lower()
    if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") then return true end
    return false
end

-- // Core Systems
local function checkTargetVisibility(targetPart, targetChar)
    if not ESP_Config.VisCheck then return "Visible", COLOR_VISIBLE end
    local lpChar = LocalPlayer.Character
    if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", COLOR_BLOCKED end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    table.clear(ignoreList)
    table.insert(ignoreList, lpChar)
    table.insert(ignoreList, Camera)
    if targetChar then table.insert(ignoreList, targetChar) end
    
    local loopCounter = 0
    while true do
        loopCounter += 1
        if loopCounter >= 15 then return "Blocked", COLOR_BLOCKED end

        sharedRaycastParams.FilterDescendantsInstances = ignoreList
        local direction = targetPos - origin
        local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

        if not raycastResult then return "Visible", COLOR_VISIBLE end
        
        local hitInstance = raycastResult.Instance
        if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", COLOR_BLOCKED end
        if hitInstance:IsDescendantOf(targetPart.Parent) then return "Visible", COLOR_VISIBLE end

        local mat = raycastResult.Material
        local isWallbangable = WallbangableMaterials[mat] or hitInstance.Transparency > 0.5 or not hitInstance.CanCollide or hitInstance.Name:lower():find("grass")
        
        if isWallbangable then
            table.insert(ignoreList, hitInstance)
            origin = raycastResult.Position
        else
            return "Blocked", COLOR_BLOCKED
        end
    end
end

local function GetBestTargetInFOV()
    local bestChar, shortestPixelDist = nil, ESP_Config.FovRadius
    local mousePos = UserInputService:GetMouseLocation()
    
    for entity, _ in pairs(ESP_Objects) do
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        if char and char ~= LocalPlayer.Character and char.Parent then
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if head and not IsEntityDead(char) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if screenDist < shortestPixelDist then
                        local visStatus, _ = checkTargetVisibility(head, char)
                        if visStatus == "Visible" then
                            shortestPixelDist = screenDist; bestChar = char
                        end
                    end
                end
            end
        end
    end
    return bestChar
end

-- // ESP Creation & Management
local function RemoveESP(entity)
    if ESP_Objects[entity] then
        local box = ESP_Objects[entity]
        if box.Highlight then box.Highlight:Destroy() end
        if box.Billboard then box.Billboard:Destroy() end
        if box.DistBillboard then box.DistBillboard:Destroy() end
        if box.Connection then box.Connection:Disconnect() end
        ESP_Objects[entity] = nil
    end
end

local function CreateESP(entity, isPlayer)
    if isPlayer and entity == LocalPlayer then return end
    if ESP_Objects[entity] then return end
    local box = {Highlight = nil, Billboard = nil, DistBillboard = nil, NameLabel = nil, DistLabel = nil, HpLabel = nil, Connection = nil}
    
    local function ApplyVisuals(char)
        if not char then return end
        local hl = char:FindFirstChildOfClass("Highlight") or Instance.new("Highlight", char)
        hl.FillColor = COLOR_VISIBLE; hl.FillTransparency = 0.6; hl.OutlineColor = COLOR_VISIBLE; hl.OutlineTransparency = 0; hl.Adornee = char; box.Highlight = hl
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local bb = Instance.new("BillboardGui", char)
        bb.Name = "RomeoZach_Billboard"; bb.Size = UDim2.new(0, 200, 0, 50); bb.AlwaysOnTop = true
        bb.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        box.Billboard = bb
        
        local nameTxt = Instance.new("TextLabel", bb)
        nameTxt.Size = UDim2.new(1, 0, 0, 20); nameTxt.Position = UDim2.new(0, 0, 0, -25); nameTxt.BackgroundTransparency = 1
        nameTxt.Text = isPlayer and (entity.DisplayName or entity.Name) or entity.Name
        nameTxt.TextColor3 = COLOR_VISIBLE; nameTxt.TextSize = 14; nameTxt.Font = ESP_Config.Font; nameTxt.TextStrokeTransparency = 0; box.NameLabel = nameTxt
        Instance.new("UIStroke", nameTxt).Thickness = 2
        
        local distBb = Instance.new("BillboardGui", char)
        distBb.Name = "RomeoZach_DistBillboard"; distBb.Size = UDim2.new(0, 200, 0, 50); distBb.AlwaysOnTop = true
        distBb.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LeftFoot")
        distBb.StudsOffset = Vector3.new(0, -3.5, 0)
        box.DistBillboard = distBb
        
        local distTxt = Instance.new("TextLabel", distBb)
        distTxt.Size = UDim2.new(1, 0, 1, 0); distTxt.BackgroundTransparency = 1
        distTxt.Text = ""; distTxt.TextColor3 = COLOR_VISIBLE; distTxt.TextSize = 14; distTxt.Font = ESP_Config.Font; distTxt.TextStrokeTransparency = 0; box.DistLabel = distTxt
        Instance.new("UIStroke", distTxt).Thickness = 2
    end
    
    if isPlayer then 
        if entity.Character then ApplyVisuals(entity.Character) end
        box.Connection = entity.CharacterAdded:Connect(ApplyVisuals) 
    else 
        ApplyVisuals(entity) 
    end
    ESP_Objects[entity] = box
end

-- // Entity Scanner (Player, AI, Items)
local function IsValidEntity(obj)
    if not obj:IsA("Model") then return false end
    if obj.Name == LocalPlayer.Name or (LocalPlayer.Character and obj == LocalPlayer.Character) then return false end
    if obj:IsDescendantOf(Camera) then return false end
    
    local nameLower = obj.Name:lower()
    if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") then return false end

    if obj:FindFirstChildOfClass("Humanoid") then return true end
    if obj:FindFirstChild("Head") and obj:FindFirstChild("HumanoidRootPart") then return true end
    if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") then return true end
    
    return false
end

task.spawn(function()
    while task.wait(2) do
        local lpChar = LocalPlayer.Character
        if not lpChar then continue end

        -- 1. Player Scan
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
        end

        -- 2. AI & General Corpse Scan (Workspace level support for Dead Players/Ragdolls)
        local function ScanForEntities(folder)
            if not folder then return end
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") and IsValidEntity(obj) and not ESP_Objects[obj] then
                    CreateESP(obj, false)
                end
            end
        end
        
        local aiZones = workspace:FindFirstChild("AiZones")
        if aiZones then
            for _, zone in ipairs(aiZones:GetChildren()) do ScanForEntities(zone) end
        end
        ScanForEntities(workspace) -- Force scan for loose corpses/ragdolls globally
        
        -- 3. Item Finder
        local droppedItems = workspace:FindFirstChild("DroppedItems")
        if droppedItems then
            for _, item in pairs(droppedItems:GetChildren()) do
                local name = item.Name:lower()
                local shouldEsp = false
                
                if ESP_Config.FindWeapons and (name:find("m4") or name:find("val") or name:find("spsh") or name:find("r700") or name:find("tfz") or name:find("pkm")) then
                    shouldEsp = true
                elseif ESP_Config.FindValuables and (name:find("gold") or name:find("key") or name:find("watch") or name:find("repair")) then
                    shouldEsp = true
                end
                
                if shouldEsp and not ESP_Objects[item] then
                    local bb = Instance.new("BillboardGui", item)
                    bb.Size = UDim2.new(0, 150, 0, 20); bb.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel", bb)
                    txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
                    txt.Text = item.Name; txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                    txt.TextStrokeTransparency = 0; txt.Font = ESP_Config.Font; txt.TextSize = 13
                    Instance.new("UIStroke", txt).Thickness = 2
                    ESP_Objects[item] = {Billboard = bb, IsItem = true}
                elseif not shouldEsp and ESP_Objects[item] and not item:FindFirstChildOfClass("Humanoid") then
                    RemoveESP(item)
                end
            end
        end
        
        -- 4. Gun Mods
        local ammoTypes = game.ReplicatedStorage:FindFirstChild("AmmoTypes")
        if ammoTypes then
            for _, ammo in pairs(ammoTypes:GetChildren()) do
                if ESP_Config.GunMods then
                    if not AmmoBackups[ammo] then AmmoBackups[ammo] = {Recoil = ammo:GetAttribute("RecoilStrength"), Spread = ammo:GetAttribute("AccuracyDeviation"), Drop = ammo:GetAttribute("ProjectileDrop")} end
                    ammo:SetAttribute("RecoilStrength", 0); ammo:SetAttribute("AccuracyDeviation", 0); ammo:SetAttribute("ProjectileDrop", 0)
                else
                    if AmmoBackups[ammo] then
                        if AmmoBackups[ammo].Recoil ~= nil then ammo:SetAttribute("RecoilStrength", AmmoBackups[ammo].Recoil) end
                        if AmmoBackups[ammo].Spread ~= nil then ammo:SetAttribute("AccuracyDeviation", AmmoBackups[ammo].Spread) end
                        if AmmoBackups[ammo].Drop ~= nil then ammo:SetAttribute("ProjectileDrop", AmmoBackups[ammo].Drop) end
                        AmmoBackups[ammo] = nil
                    end
                end
            end
        end

        -- Enforce Performance Mode lighting lock against game overrides
        if ESP_Config.PerformanceMode then
            Lighting.GlobalShadows = false
            Lighting.FogStart = 999999
            Lighting.FogEnd = 999999
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 3
            Lighting.ClockTime = 12
        end
    end
end)

-- // Main Render Loop
RunService:BindToRenderStep("RomeoZach_Render", 2005, function(deltaTime)
    local lpChar = LocalPlayer.Character
    local lpHead = lpChar and lpChar:FindFirstChild("Head")
    if not lpHead then return end

    if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
        for _, box in pairs(ESP_Objects) do
            if box.Highlight then box.Highlight.Enabled = false end
            if box.Billboard then box.Billboard.Enabled = false end
            if box.DistBillboard then box.DistBillboard.Enabled = false end
        end
        return 
    end

    for entity, box in pairs(ESP_Objects) do
        if typeof(entity) == "Instance" and not entity.Parent then
            RemoveESP(entity)
            continue
        end
        
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        local isItem = box.IsItem
        
        if ESP_Config.Enabled and isItem then
            local itemPos = (char:IsA("Model") and char.PrimaryPart and char.PrimaryPart.Position) or (char:IsA("Model") and char:GetPivot().Position) or (char:IsA("BasePart") and char.Position)
            local showItem = false
            if itemPos then
                local dist = (lpHead.Position - itemPos).Magnitude
                if dist <= 357 then -- Exactly 100 meters restriction
                    showItem = true
                end
            end
            if box.Billboard then box.Billboard.Enabled = showItem end
        elseif ESP_Config.Enabled and not isItem and char and char ~= lpChar then
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
            if not head then 
                if box.Highlight then box.Highlight.Enabled = false end
                if box.Billboard then box.Billboard.Enabled = false end
                if box.DistBillboard then box.DistBillboard.Enabled = false end
                continue
            end
            
            local isDead = IsEntityDead(char)
            local studsDist = (lpHead.Position - head.Position).Magnitude
            local distMeter = math.floor(studsDist / 3.57) -- Accurate 1 meter = 3.57 studs ratio
            
            local shouldRender = not isDead or (isDead and studsDist <= 714) -- 200 Meters rendering limit for Corpses
            local finalColor = COLOR_VISIBLE
            
            if isDead then
                finalColor = COLOR_DEAD
            else
                local _, visColor = checkTargetVisibility(head, char)
                finalColor = visColor
            end
            
            if shouldRender then
                if box.Highlight then box.Highlight.FillColor = finalColor; box.Highlight.OutlineColor = finalColor end
                if box.NameLabel then box.NameLabel.TextColor3 = finalColor end
                if box.DistLabel then box.DistLabel.Text = string.format("[%d m]", distMeter); box.DistLabel.TextColor3 = finalColor end
            end
            
            if box.Highlight then box.Highlight.Enabled = shouldRender end
            if box.Billboard then box.Billboard.Enabled = shouldRender end
            if box.DistBillboard then box.DistBillboard.Enabled = shouldRender end
        else
            if box.Highlight then box.Highlight.Enabled = false end
            if box.Billboard then box.Billboard.Enabled = false end
            if box.DistBillboard then box.DistBillboard.Enabled = false end
        end
    end

    -- // Aimlock Logic
    if ESP_Config.AimLock and IsAiming then
        if not CurrentTargetChar or not CurrentTargetChar.Parent or IsEntityDead(CurrentTargetChar) then
            CurrentTargetChar = GetBestTargetInFOV()
        end
        
        if CurrentTargetChar then
            local tHead = CurrentTargetChar:FindFirstChild("Head") or CurrentTargetChar:FindFirstChild("HumanoidRootPart")
            if tHead then
                local studsDist = (lpHead.Position - tHead.Position).Magnitude
                local bulletSpeed = GetBulletSpeed()
                if bulletSpeed <= 0 then bulletSpeed = 1500 end
                
                local t = studsDist / bulletSpeed
                local currentVelocity = tHead.AssemblyLinearVelocity
                if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0,0,0) end
                
                local futurePos = tHead.Position + (currentVelocity * t)
                
                -- If Gun Mods are on, bullet drop is zero.
                local dropCompensation = ESP_Config.GunMods and 0 or (workspace.Gravity * t * t) / 2
                local finalAimPos = futurePos + Vector3.new(0, dropCompensation, 0)
                
                local _, onScreen = Camera:WorldToViewportPoint(finalAimPos)
                if onScreen then
                    local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, finalAimPos)
                    pcall(function() Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.6) end)
                end
            else
                CurrentTargetChar = nil
            end
        end
    else
        CurrentTargetChar = nil
    end
end)

-- // Initial Player Scan
for _, p in ipairs(Players:GetPlayers()) do 
    if p ~= LocalPlayer then CreateESP(p, true) end
end

Players.PlayerAdded:Connect(function(p) 
    if p ~= LocalPlayer then CreateESP(p, true) end
end)

Players.PlayerRemoving:Connect(RemoveESP)
