-- [[ ROMEOZACH SC - Project Delta v7 (Kinematics & Dual-Scan Optimization) ]]
-- Author: RomeoZach (Fixed Syntax & Integrated Ballistic UI)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Configuration State
local ESP_Config = {
    Enabled = true,
    VisCheck = true,
    AimLock = false, 
    NoRecoil = true, 
    Tracers = true,
    WeaponChams = true, 
    BulletTracers = true, 
    Crosshair = true, 
    PerformanceMode = false, 
    Color = Color3.fromRGB(0, 180, 255), 
    WeaponColor = Color3.fromRGB(255, 255, 0), 
    BulletColor = Color3.fromRGB(255, 255, 0), 
    TextSize = 13,
    Font = Enum.Font.Code,
    FovRadius = 150 
}

local ESP_Objects = {}
local IsAiming = false
local CurrentTargetChar = nil
local WeaponConnections = {}
local ActiveBulletTracers = {}
local CrosshairLines = {}
local TextureBackups = {}
local LightingBackups = {
    GlobalShadows = Lighting.GlobalShadows,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
}

-- // Environmental Analytics Setup
local WallbangableMaterials = {
    [Enum.Material.Wood] = true, [Enum.Material.WoodPlanks] = true,
    [Enum.Material.Fabric] = true, [Enum.Material.Plastic] = true,
    [Enum.Material.Glass] = true, [Enum.Material.Cardboard] = true,
    [Enum.Material.Sand] = true
}

local visCheckParams = RaycastParams.new()
visCheckParams.FilterType = Enum.RaycastFilterType.Exclude
visCheckParams.IgnoreWater = true

-- // UTAS 1: Ambil Kecepatan Peluru Dinamis
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

-- // UTAS 2: Fungsi Vis-Check Perbaikan Skema Warna
local function checkTargetVisibility(targetPart)
    if not ESP_Config.VisCheck then return "Visible", Color3.fromRGB(255, 255, 255) end
    local lpChar = LocalPlayer.Character
    if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", Color3.fromRGB(80, 80, 80) end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    visCheckParams.FilterDescendantsInstances = {lpChar, Camera}
    local raycastResult = workspace:Raycast(origin, direction, visCheckParams)

    if not raycastResult or raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
        return "Visible", Color3.fromRGB(255, 255, 255)
    end
    if WallbangableMaterials[raycastResult.Material] or raycastResult.Instance.Transparency > 0.5 or not raycastResult.Instance.CanCollide then
        return "Wallbang", Color3.fromRGB(255, 255, 255)
    else
        return "Blocked", Color3.fromRGB(80, 80, 80)
    end
end

-- // UTAS 3: Seleksi Target Prioritas Kursor Layar 2D
local function GetBestTargetInFOV()
    local bestChar, shortestPixelDist = nil, ESP_Config.FovRadius
    local mousePos = UserInputService:GetMouseLocation()
    local lpChar = LocalPlayer.Character

    for entity, _ in pairs(ESP_Objects) do
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        if char and char ~= lpChar and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(char.Head.Position)
            if onScreen then
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if screenDist < shortestPixelDist then
                    local visStatus, _ = checkTargetVisibility(char.Head)
                    if visStatus == "Visible" or visStatus == "Wallbang" then
                        shortestPixelDist = screenDist; bestChar = char
                    end
                end
            end
        end
    end
    return bestChar
end

-- // UI Creation
if CoreGui:FindFirstChild("RomeoZach_Ui") then CoreGui.RomeoZach_Ui:Destroy() end
local RomeoZachUI = Instance.new("ScreenGui", CoreGui)
RomeoZachUI.Name = "RomeoZach_Ui"; RomeoZachUI.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(RomeoZachUI) end

local MainFrame = Instance.new("Frame", RomeoZachUI)
MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 320, 0, 610)
MainFrame.Position = UDim2.new(0.5, -160, 0.4, -305); MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18)
MainFrame.BackgroundTransparency = 0.15; MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1; MainStroke.Color = Color3.fromRGB(45, 48, 53); MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Header = Instance.new("TextLabel", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35); Header.BackgroundTransparency = 1; Header.Text = "  RomeoZach SC v7"
Header.TextColor3 = Color3.fromRGB(240, 240, 245); Header.TextSize = 14; Header.Font = Enum.Font.GothamBold; Header.TextXAlignment = Enum.TextXAlignment.Left

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -45); Container.Position = UDim2.new(0, 10, 0, 35); Container.BackgroundTransparency = 1
local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 10)

local function CreateToggle(labelText, configKey)
    local Frame = Instance.new("Frame", Container)
    Frame.Size = UDim2.new(1, 0, 0, 40); Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27); Frame.BorderSizePixel = 0
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.7, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.BackgroundTransparency = 1
    Label.Text = labelText; Label.TextColor3 = Color3.fromRGB(200, 200, 205); Label.TextSize = 13; Label.Font = Enum.Font.Gotham; Label.TextXAlignment = Enum.TextXAlignment.Left
    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(0, 45, 0, 22); Btn.Position = UDim2.new(1, -55, 0.5, -11); Btn.BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)
    Btn.Text = ""; Btn.AutoButtonColor = false; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    Btn.MouseButton1Click:Connect(function()
        ESP_Config[configKey] = not ESP_Config[configKey]
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = ESP_Config[configKey] and ESP_Config.Color or Color3.fromRGB(40, 43, 48)}):Play()
        if configKey == "AimLock" and not ESP_Config.AimLock then CurrentTargetChar = nil end
    end)
    return Btn
end

local ToggleBtn = CreateToggle("Enable Visuals", "Enabled")
local LockBtn = CreateToggle("Enable AimLock", "AimLock")
local NoRecoilBtn = CreateToggle("100% No Recoil Camera", "NoRecoil") 
local TracersBtn = CreateToggle("Enable Tracers", "Tracers")
local ChamsBtn = CreateToggle("Weapon Chams", "WeaponChams")
local BulletTracersBtn = CreateToggle("Yellow Bullet Tracers", "BulletTracers")
local CrosshairBtn = CreateToggle("Tiny Center Crosshair", "Crosshair")
local VisCheckBtn = CreateToggle("Wallbang Target Analytics", "VisCheck")
local PerformanceBtn = CreateToggle("Performance Mode", "PerformanceMode")

PerformanceBtn.MouseButton1Click:Connect(function()
    if ESP_Config.PerformanceMode then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then TextureBackups[obj] = obj.Texture; obj.Texture = ""
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then TextureBackups[obj] = obj.Enabled; obj.Enabled = false
            elseif obj:IsA("BasePart") and not obj:IsA("MeshPart") then TextureBackups[obj] = obj.Material; obj.Material = Enum.Material.SmoothPlastic end
        end
        Lighting.GlobalShadows = false; Lighting.EnvironmentSpecularScale = 0; Lighting.EnvironmentDiffuseScale = 0
    else
        for obj, val in pairs(TextureBackups) do
            if obj and obj.Parent then
                if obj:IsA("Texture") or obj:IsA("Decal") then obj.Texture = val
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = val
                elseif obj:IsA("BasePart") then obj.Material = val end
            end
        end
        table.clear(TextureBackups); Lighting.GlobalShadows = LightingBackups.GlobalShadows
        Lighting.EnvironmentSpecularScale = LightingBackups.EnvironmentSpecularScale; Lighting.EnvironmentDiffuseScale = LightingBackups.EnvironmentDiffuseScale
    end
end)

local ColorFrame = Instance.new("Frame", Container)
ColorFrame.Size = UDim2.new(1, 0, 0, 65); ColorFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 27); ColorFrame.BorderSizePixel = 0
Instance.new("UICorner", ColorFrame).CornerRadius = UDim.new(0, 6)
local ColorLabel = Instance.new("TextLabel", ColorFrame)
ColorLabel.Size = UDim2.new(1, 0, 0, 25); ColorLabel.Position = UDim2.new(0, 10, 0, 0); ColorLabel.BackgroundTransparency = 1
ColorLabel.Text = "Visual Color Theme"; ColorLabel.TextColor3 = Color3.fromRGB(200, 200, 205); ColorLabel.TextSize = 13; ColorLabel.Font = Enum.Font.Gotham; ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
local GridContainer = Instance.new("Frame", ColorFrame)
GridContainer.Size = UDim2.new(1, -20, 0, 30); GridContainer.Position = UDim2.new(0, 10, 0, 28); GridContainer.BackgroundTransparency = 1
local UIGridLayout = Instance.new("UIGridLayout", GridContainer)
UIGridLayout.CellSize = UDim2.new(0, 24, 0, 24); UIGridLayout.CellPadding = UDim2.new(0, 8, 0, 0)

local Presets = {Color3.fromRGB(0, 180, 255), Color3.fromRGB(180, 70, 255), Color3.fromRGB(255, 60, 60), Color3.fromRGB(40, 255, 140), Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 255, 255)}
for _, color in ipairs(Presets) do
    local ColorBtn = Instance.new("TextButton", GridContainer)
    ColorBtn.Text = ""; ColorBtn.BackgroundColor3 = color; ColorBtn.BorderSizePixel = 0
    Instance.new("UICorner", ColorBtn).CornerRadius = UDim.new(0, 4)
    ColorBtn.MouseButton1Click:Connect(function() 
        local oldColor = ESP_Config.Color; ESP_Config.Color = color
        local btns = {ToggleBtn, LockBtn, NoRecoilBtn, TracersBtn, ChamsBtn, BulletTracersBtn, CrosshairBtn, VisCheckBtn, PerformanceBtn}
        for _, btn in pairs(btns) do if btn.BackgroundColor3 == oldColor or btn.BackgroundColor3 ~= Color3.fromRGB(40, 43, 48) then btn.BackgroundColor3 = color end end
    end)
end

local HudFrame = Instance.new("Frame", RomeoZachUI)
HudFrame.Name = "PerformanceHUD"; HudFrame.Size = UDim2.new(0, 140, 0, 75); HudFrame.Position = UDim2.new(0, 20, 0.4, 0); HudFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 18); HudFrame.BackgroundTransparency = 0.2; HudFrame.BorderSizePixel = 0; HudFrame.Active = true; HudFrame.Draggable = true
Instance.new("UICorner", HudFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", HudFrame).Color = Color3.fromRGB(45, 48, 53)
local HudList = Instance.new("UIListLayout", HudFrame)
HudList.Padding = UDim.new(0, 2); HudList.HorizontalAlignment = Enum.HorizontalAlignment.Center; HudList.VerticalAlignment = Enum.VerticalAlignment.Center

local function CreateHudLabel(name)
    local Label = Instance.new("TextLabel", HudFrame)
    Label.Size = UDim2.new(1, -16, 0, 18); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(230, 230, 235)
    Label.TextSize = 12; Label.Font = Enum.Font.Code; Label.TextXAlignment = Enum.TextXAlignment.Left
    return Label
end
local FpsLabel = CreateHudLabel("FPS"); local PingLabel = CreateHudLabel("Ping"); local TimeLabel = CreateHudLabel("Time")
local fpsCount = 0
task.spawn(function() while task.wait(1) do FpsLabel.Text = string.format("FPS: %d", fpsCount); fpsCount = 0 end end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.M then MainFrame.Visible = not MainFrame.Visible end
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false; CurrentTargetChar = nil end end)

local function ApplyWeaponCham(part)
    if part:IsA("BasePart") and not part:FindFirstChild("Cham_Adornment") then
        local adorn = Instance.new("BoxHandleAdornment", part)
        adorn.Name = "Cham_Adornment"; adorn.Size = part.Size + Vector3.new(0.02, 0.02, 0.02); adorn.Color3 = ESP_Config.WeaponColor
        adorn.AlwaysOnTop = true; adorn.ZIndex = 5; adorn.Transparency = 0.4; adorn.Adornee = part
        table.insert(WeaponConnections, {Adornment = adorn, Part = part, OrigMat = part.Material}); part.Material = Enum.Material.Neon
    end
end

local function CreateCrosshair()
    if not Drawing then return end
    CrosshairLines = {Horizontal = Drawing.new("Line"), Vertical = Drawing.new("Line")}
    for _, line in pairs(CrosshairLines) do line.Thickness = 1.5; line.Color = Color3.fromRGB(255, 255, 255); line.Transparency = 1; line.Visible = false end
end

local function CreateBulletTracer(startPos, endPos)
    if not Drawing or not ESP_Config.Enabled or not ESP_Config.BulletTracers then return end
    local tracer = Drawing.new("Line")
    tracer.Thickness = 2; tracer.Color = ESP_Config.BulletColor; tracer.Transparency = 1; tracer.Visible = false
    table.insert(ActiveBulletTracers, {Tracer = tracer, StartPos = startPos, EndPos = endPos, LifeTime = 0.4, SpawnTime = tick()})
end

local function ChamWeapon(tool)
    if not tool:IsA("Tool") then return end
    for _, child in ipairs(tool:GetDescendants()) do ApplyWeaponCham(child) end
    table.insert(WeaponConnections, {Connection = tool.DescendantAdded:Connect(ApplyWeaponCham)})
    local fireConnection = tool.Activated:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
            local origin = LocalPlayer.Character.Head.Position
            local mousePos = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local rp = RaycastParams.new()
            rp.FilterPlayers = {LocalPlayer}; rp.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rp)
            CreateBulletTracer(origin, result and result.Position or (unitRay.Origin + unitRay.Direction * 1000))
        end
    end)
    table.insert(WeaponConnections, {Connection = fireConnection})
end
local function ClearWeaponChams()
    for _, item in ipairs(WeaponConnections) do
        if item.Connection then item.Connection:Disconnect() end
        if item.Adornment then item.Adornment:Destroy() end
        if item.Part and item.OrigMat then item.Part.Material = item.OrigMat end
    end
    table.clear(WeaponConnections)
end

local function MonitorCharacter(char)
    if not char then return end
    char.ChildAdded:Connect(function(child) if ESP_Config.WeaponChams or ESP_Config.BulletTracers then ChamWeapon(child) end end)
    for _, child in ipairs(char:GetChildren()) do if child:IsA("Tool") and (ESP_Config.WeaponChams or ESP_Config.BulletTracers) then ChamWeapon(child) end end
end

if LocalPlayer.Character then MonitorCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(MonitorCharacter); CreateCrosshair()

local function RemoveESP(entity)
    if ESP_Objects[entity] then
        local box = ESP_Objects[entity]
        if box.Highlight then box.Highlight:Destroy() end
        if box.Billboard then box.Billboard:Destroy() end
        if box.TracerLine then box.TracerLine:Remove() end
        if box.Connection then box.Connection:Disconnect() end
        ESP_Objects[entity] = nil
    end
end

local function CreateESP(entity, isPlayer)
    if isPlayer and entity == LocalPlayer then return end
    if ESP_Objects[entity] then return end
    local box = {Highlight = nil, Billboard = nil, NameLabel = nil, DistLabel = nil, TracerLine = nil, Connection = nil}
    
    local function ApplyVisuals(char)
        if not char then return end
        local hl = char:FindFirstChildOfClass("Highlight") or Instance.new("Highlight", char)
        hl.FillColor = ESP_Config.Color; hl.FillTransparency = 0.6; hl.OutlineColor = ESP_Config.Color; hl.OutlineTransparency = 0; hl.Adornee = char; box.Highlight = hl
        
        local bb = Instance.new("BillboardGui", char)
        bb.Name = "RomeoZach_Billboard"; bb.Size = UDim2.new(0, 200, 0, 50); bb.AlwaysOnTop = true; bb.Adornee = char:WaitForChild("Head", 5) or char:FindFirstChildOfClass("Part"); box.Billboard = bb
        
        local nameTxt = Instance.new("TextLabel", bb)
        nameTxt.Size = UDim2.new(1, 0, 0, 20); nameTxt.Position = UDim2.new(0, 0, 0, -25); nameTxt.BackgroundTransparency = 1
        nameTxt.Text = isPlayer and (entity.DisplayName or entity.Name) or entity.Name
        nameTxt.TextColor3 = ESP_Config.Color; nameTxt.TextSize = ESP_Config.TextSize; nameTxt.Font = ESP_Config.Font; nameTxt.TextStrokeTransparency = 0.2; box.NameLabel = nameTxt
        
        local distTxt = Instance.new("TextLabel", bb)
        distTxt.Size = UDim2.new(1, 0, 0, 20); distTxt.Position = UDim2.new(0, 0, 0, 35); distTxt.BackgroundTransparency = 1
        distTxt.Text = "0 studs"; distTxt.TextColor3 = ESP_Config.Color; distTxt.TextSize = ESP_Config.TextSize; distTxt.Font = ESP_Config.Font; distTxt.TextStrokeTransparency = 0.2; box.DistLabel = distTxt
        
        if Drawing then
            box.TracerLine = Drawing.new("Line"); box.TracerLine.Thickness = 1.5; box.TracerLine.Transparency = 0.8; box.TracerLine.Color = ESP_Config.Color
        end
    end
    if isPlayer then if entity.Character then ApplyVisuals(entity.Character) end; box.Connection = entity.CharacterAdded:Connect(ApplyVisuals) else ApplyVisuals(entity) end
    ESP_Objects[entity] = box
end

task.spawn(function()
    while task.wait(2) do
        local lpChar = LocalPlayer.Character
        local lpHead = lpChar and lpChar:FindFirstChild("Head")
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then if not ESP_Objects[p] then CreateESP(p, true) end end end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
                if not Players:GetPlayerFromCharacter(obj) and obj ~= lpChar then
                    local dist = lpHead and (lpHead.Position - obj.Head.Position).Magnitude or math.huge
                    if (obj.Humanoid.Health > 0 and dist <= 893) or (obj.Humanoid.Health <= 0 and dist <= 250) then
                        if not ESP_Objects[obj] then CreateESP(obj, false) end
                    else if ESP_Objects[obj] then RemoveESP(obj) end end
                end
            end
        end
    end
end)
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    PingLabel.Text = string.format("Ping: %d ms", math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()))
    TimeLabel.Text = string.format("Time: %s", os.date("%X"))
    local lpChar = LocalPlayer.Character
    local lpHead = lpChar and lpChar:FindFirstChild("Head")
    if not lpHead then return end
    local myPos = Camera.CFrame.Position

    for entity, box in pairs(ESP_Objects) do
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        if ESP_Config.Enabled and char then
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if head and hum then
                local isDead = hum.Health  0 then ClearWeaponChams()
    elseif (ESP_Config.WeaponChams or ESP_Config.BulletTracers) and #WeaponConnections == 0 and LocalPlayer.Character then
        local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if currentTool then ChamWeapon(currentTool) end
    end

    for i = #ActiveBulletTracers, 1, -1 do
        local trace = ActiveBulletTracers[i]; local age = tick() - trace.SpawnTime
        if age >= trace.LifeTime or not ESP_Config.Enabled or not ESP_Config.BulletTracers then trace.Tracer:Remove(); table.remove(ActiveBulletTracers, i)
        else
            local sScreen, sVis = Camera:WorldToViewportPoint(trace.StartPos); local eScreen, eVis = Camera:WorldToViewportPoint(trace.EndPos)
            if sVis and eVis then trace.Tracer.From = Vector2.new(sScreen.X, sScreen.Y); trace.Tracer.To = Vector2.new(eScreen.X, eScreen.Y); trace.Tracer.Transparency = 1 - (age / trace.LifeTime); trace.Tracer.Visible = true
            else trace.Tracer.Visible = false end
        end
    end

    if CrosshairLines.Horizontal and CrosshairLines.Vertical then
        if ESP_Config.Enabled and ESP_Config.Crosshair then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            CrosshairLines.Horizontal.From = Vector2.new(center.X - 5, center.Y); CrosshairLines.Horizontal.To = Vector2.new(center.X + 5, center.Y)
            CrosshairLines.Vertical.From = Vector2.new(center.X, center.Y - 5); CrosshairLines.Vertical.To = Vector2.new(center.X, center.Y + 5)
            CrosshairLines.Horizontal.Visible = true; CrosshairLines.Vertical.Visible = true
        else CrosshairLines.Horizontal.Visible = false; CrosshairLines.Vertical.Visible = false end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p, true) end
Players.PlayerAdded:Connect(function(p) CreateESP(p, true) end); Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)
