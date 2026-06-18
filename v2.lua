-- [[ ROMEOZACH SC - Project Delta v8 Ultimate (Rebuilt from Scratch) ]]
-- Author: RomeoZach (Unified Entity System & Advanced Features)

-- // Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_Config = {
    Enabled = true,
    AimLock = true,
    WeaponChams = true,
    BulletTracers = true,
    Crosshair = true,
    VisCheck = true,
    GunMods = false,
    PerformanceMode = false,
    Color = Color3.fromRGB(255, 75, 75),
    WeaponColor = Color3.fromRGB(255, 255, 0),
    BulletColor = Color3.fromRGB(255, 255, 0),
    TextSize = 10,
    Font = Enum.Font.SourceSansBold, -- Menggunakan font standar agar anti-crash
    FovRadius = 120
}

-- // ESP Theme Colors
local COLOR_VISIBLE = ESP_Config.Color
local COLOR_BLOCKED = Color3.fromRGB(160, 160, 165)
local COLOR_DEAD = Color3.fromRGB(221, 160, 221) -- Ungu Plum Mutlak

local ESP_Objects = {}
local IsAiming = false
local CurrentTargetEntity = nil
local CurrentTargetChar = nil
local CrosshairLines = {}
local AmmoBackups = {}
local TextureBackups = {}
local LightingBackups = {
    GlobalShadows = Lighting.GlobalShadows,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness
}

local DisabledEffects = {}
local LastPerformanceState = false

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

local RomeoZachGui = Instance.new("ScreenGui")
RomeoZachGui.Name = "RomeoZach_Ui"
RomeoZachGui.ResetOnSpawn = false
RomeoZachGui.DisplayOrder = 999999
RomeoZachGui.IgnoreGuiInset = true -- Sangat penting agar Crosshair berada tepat di titik nol (tengah) dan tidak tergeser oleh Topbar Roblox
RomeoZachGui.Parent = PlayerGui

-- // Crosshair Framework
local chX = Instance.new("Frame", RomeoZachGui)
chX.Size = UDim2.new(0, 14, 0, 2)
chX.Position = UDim2.new(0.5, -7, 0.5, -1)
chX.BackgroundColor3 = ESP_Config.Color
chX.BorderSizePixel = 0
chX.Visible = ESP_Config.Crosshair
Instance.new("UIStroke", chX).Thickness = 1
table.insert(CrosshairLines, chX)

local chY = Instance.new("Frame", RomeoZachGui)
chY.Size = UDim2.new(0, 2, 0, 14)
chY.Position = UDim2.new(0.5, -1, 0.5, -7)
chY.BackgroundColor3 = ESP_Config.Color
chY.BorderSizePixel = 0
chY.Visible = ESP_Config.Crosshair
Instance.new("UIStroke", chY).Thickness = 1
table.insert(CrosshairLines, chY)

local MainFrame = Instance.new("Frame", RomeoZachGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 760) -- Adjusted height after removing empty container toggle
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
        
        -- Update Crosshair secara efisien hanya saat tombol diklik (tidak perlu masuk Render Loop)
        if configKey == "Crosshair" then
            for _, line in ipairs(CrosshairLines) do
                line.Visible = ESP_Config.Crosshair
            end
        end
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
local FindKeysBtn = CreateToggle("Find Keys & Keycards", "FindKeys")
local FindAttachmentsBtn = CreateToggle("Find Attachments (Scopes, Mags..)", "FindAttachments")
local FindEquipmentBtn = CreateToggle("Find Equipments (Armor, Helmets..)", "FindEquipment")
local PerformanceBtn = CreateToggle("Performance Mode", "PerformanceMode")
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
    -- Jika parent nil atau objek tidak valid, kembalikan false mutlak agar tidak terdeteksi sebagai mayat hantu.
    if not char or typeof(char) ~= "Instance" or not char.Parent then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 or hum.Health ~= hum.Health then return true end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return true end
        return false -- Jika punya humanoid tapi tidak mati, pasti masih hidup
    end
    
    local nameLower = string.lower(char.Name)
    
    if char:IsA("Model") then
        -- Validasi ketat: HANYA dievaluasi jika Model memiliki sisa anatomi manusia/ragdoll
        if char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") then
            -- Pindahkan pengecekan filter string ke DALAM blok ini agar objek map tidak ikut dievaluasi
            if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
                return true 
            end
            return false -- Punya tubuh tapi tidak teridentifikasi mati (bukan mayat)
        end
        return false -- MUTLAK BUKAN MAYAT! Objek ini hanya kotak/kontainer/map biasa. (Memecahkan masalah Crate & Bag)
    end
    
    -- Filter string murni untuk objek tunggal yang BUKAN berbentuk Model (Part/Mesh individu)
    if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or nameLower:find("wreck") or nameLower:find("body") then 
        return true 
    end
    
    return false
end
-- // Core Systems
local function checkTargetVisibility(targetPart, targetChar)
    table.clear(ignoreList) -- [PERBAIKAN 1] Pembersihan Buffer Mutlak di baris paling pertama untuk mencegah memory leak

    if not ESP_Config.VisCheck then return "Visible", ESP_Config.Color end
    local lpChar = LocalPlayer.Character
    if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", COLOR_BLOCKED end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    -- [PERBAIKAN] Kalkulasi vektor arah dan jarak HANYA SATU KALI agar tidak overshoot
    local direction = targetPos - origin
    
    table.insert(ignoreList, lpChar)
    table.insert(ignoreList, Camera)
    if targetChar then table.insert(ignoreList, targetChar) end
    
    local loopCounter = 0
    while true do
        loopCounter = loopCounter + 1
        -- [PERBAIKAN] Limit iterasi dinaikkan menjadi 40 agar tidak macet di dedaunan / semak tebal
        if loopCounter >= 40 then return "Blocked", COLOR_BLOCKED end

        sharedRaycastParams.FilterDescendantsInstances = ignoreList
        local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

        if not raycastResult then return "Visible", ESP_Config.Color end
        
        local hitInstance = raycastResult.Instance
        if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", COLOR_BLOCKED end
        if hitInstance:IsDescendantOf(targetPart.Parent) then return "Visible", ESP_Config.Color end

        local mat = raycastResult.Material
        -- [FIX] Jangan abaikan objek Non-Collide karena beton visual seringkali tembus fisik tapi menghalangi pandangan. Abaikan hanya benda transparan (Hitbox invisible).
        local isWallbangable = WallbangableMaterials[mat] or hitInstance.Transparency >= 0.8 or hitInstance.Name:lower():find("grass") or hitInstance.Name:lower():find("glass") or hitInstance.Name:lower():find("ignore")
        
        if isWallbangable then
            table.insert(ignoreList, hitInstance)
            -- [PERBAIKAN FATAL] origin TIDAK BOLEH digeser ke raycastResult.Position! Biarkan raycast menembus dari awal.
        else
            return "Blocked", COLOR_BLOCKED
        end
    end
end

local function GetBestTargetInFOV()
    local bestEntity, bestChar = nil, nil
    -- [PERBAIKAN 2] Lingkaran FOV Tersembunyi: Radius 120 piksel untuk mencegah sentakan kasar (swing cepat)
    local shortestPixelDist = 120 
    local centerPos = Camera.ViewportSize / 2
    local origin = Camera.CFrame.Position
    
    for entity, box in pairs(ESP_Objects) do
        if not box.CanBeAimlocked then continue end -- Saklar pengaman dari Render Loop
        
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        if char and char ~= LocalPlayer.Character and char.Parent then
            -- [FIX] Pastikan pendeteksi target mencari anatomi paling valid
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
            if head and not IsEntityDead(char) then
                local studsDist = (origin - head.Position).Magnitude
                
                -- [PERBAIKAN 4] Integrasi Batas Jarak Deteksi
                local isPlayer = (typeof(entity) == "Instance" and entity:IsA("Player")) or Players:GetPlayerFromCharacter(char) ~= nil
                if isPlayer and studsDist > 3150 then continue end
                if not isPlayer and studsDist > 1575 then continue end
                
                -- [PERBAIKAN 3] Rumus Prediksi Peluru (Velocity Target + Kompensasi Gravitasi)
                local bulletSpeed = GetBulletSpeed()
                if bulletSpeed <= 0 then bulletSpeed = 1500 end
                local timeToTarget = studsDist / bulletSpeed
                
                local currentVelocity = head.AssemblyLinearVelocity
                if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0, 0, 0) end
                
                local dropCompensation = ESP_Config.GunMods and 0 or (workspace.Gravity * timeToTarget * timeToTarget) / 2
                local predictedPos = head.Position + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                
                -- Hitung jarak titik bidik FOV berdasarkan *Posisi Masa Depan* target
                local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                if onScreen then
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                    if screenDist < shortestPixelDist then
                        shortestPixelDist = screenDist; bestEntity = entity; bestChar = char
                    end
                end
            end
        end
    end
    return bestEntity, bestChar
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
    
    local box = {Highlight = nil, Billboard = nil, DistBillboard = nil, DistLabel = nil, NameLabel = nil, Connection = nil}
    
    local function ApplyVisuals(char)
        if not char then return end
        
        if box.Highlight then box.Highlight:Destroy(); box.Highlight = nil end
        if box.Billboard then box.Billboard:Destroy(); box.Billboard = nil end
        if box.DistBillboard then box.DistBillboard:Destroy(); box.DistBillboard = nil end
        
        box.IsDeadCache = false 
        box.TargetAdornee = char 
        
        local hl = char:FindFirstChildOfClass("Highlight") or Instance.new("Highlight", char)
        hl.FillColor = COLOR_VISIBLE; hl.FillTransparency = 0.5; hl.OutlineColor = COLOR_VISIBLE; 
        hl.OutlineTransparency = 0; hl.Adornee = char; box.Highlight = hl
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local distBb = Instance.new("BillboardGui", char)
        distBb.Name = "RomeoZach_DistBillboard"; distBb.Size = UDim2.new(0, 100, 0, 25); distBb.AlwaysOnTop = true
        distBb.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        distBb.StudsOffset = Vector3.new(0, 1.8, 0)
        box.DistBillboard = distBb
        
        local distTxt = Instance.new("TextLabel", distBb)
        distTxt.Size = UDim2.new(1, 0, 1, 0)
        distTxt.BackgroundTransparency = 1
        distTxt.Text = "" 
        distTxt.TextColor3 = COLOR_VISIBLE; distTxt.TextSize = 10; distTxt.Font = ESP_Config.Font; 
        distTxt.TextStrokeTransparency = 0; box.DistLabel = distTxt
        
        local nameTxt = Instance.new("TextLabel", distBb)
        nameTxt.Visible = false
        nameTxt.Text = ""
        box.NameLabel = nameTxt
        
        local stroke = Instance.new("UIStroke", distTxt)
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(0, 0, 0)
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
    
    local nameLower = string.lower(obj.Name)
    
    -- [KUNCI FIX MAYAT] Jika terindikasi mayat/ragdoll, langsung loloskan tanpa cek baju!
    if nameLower:find("dead") or nameLower:find("corpse") or nameLower:find("ragdoll") or
        nameLower:find("wreck") or nameLower:find("body") or obj:GetAttribute("IsDead") then
        return true
    end
    
    -- Blacklist total properti map statis agar tidak mengacaukan radar
    if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or
        nameLower:find("bag") or nameLower:find("satchel") or nameLower:find("register") or
        nameLower:find("safe") or nameLower:find("vault") or nameLower:find("desk") or
        nameLower:find("boulder") or nameLower:find("mesh") then
        return false
    end
    
    if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or
    nameLower:find("effect") then return false end
    
    -- SENSOR ENTITAS HIDUP (Hanya berlaku untuk player/AI yang masih bernyawa)
    if not obj:FindFirstChildOfClass("Shirt") and not obj:FindFirstChildOfClass("Pants") then
        return false
    end
    
    -- Database bot mutlak Project Delta
    local npcKeywords = {"dozer", "anton", "guard", "bandit", "rat", "sniper", "marksman", 
                        "highway", "tunnel", "occupant", "survey", "team", "member", "soldier", "whisper", "scav", "king", 
                        "uno", "peace", "keeper", "death"}
    for _, kw in ipairs(npcKeywords) do
        if nameLower:find(kw) then return true end
    end
    
    if obj:FindFirstChildOfClass("Tool") then return true end
    if obj:FindFirstChildOfClass("Humanoid") then return true end
    
    if obj:FindFirstChild("Head") and (obj:FindFirstChild("HumanoidRootPart") or
        obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")) then return true end
    
    return false
end


local function GetValuableMatch(desc)
    local nLower = string.lower(desc.Name)

    if nLower:find("cashierdesk") or nLower:find("desk") or nLower:find("boulder") or nLower:find("mesh") then return false, nil end

    -- [FIX] STRIKTISASI BLACKLIST: Menyaring geometri map dan batu agar tak menyala emas
    local blacklistKeywords = {"cashierdesk", "cashier_desk", "desk", "boulder", "mesh", "wall", "floor", "terrain", "stair", "door", "window", "roof", "building", "fence", "glass", "medium"}
    for _, kw in ipairs(blacklistKeywords) do
        if nLower:find(kw) then return false, nil end
    end

    if ESP_Config.FindWeapons then
        -- Database senjata berharga tinggi hasil riset Project Delta Wiki (Huruf kecil semua, tanpa tanda %)
        local weaponKeywords = {
            "golden", "mp5sd", "val", "asval", "m4a1", "m4", "fn-fal", "fal", 
            "svd", "pkm", "r700", "remington", "tfz", "mod-98", "mod98", "rpg-7", "rpg7", 
            "akmn", "saiga", "flare", "flaregun", "spsh-44", "spsh44"
        }
        
        for _, kw in ipairs(weaponKeywords) do
            -- SINKRONISASI OTOMATIS: Mengubah tanda minus (-) menjadi %%- secara dinamis agar aman dibaca Lua Match
            local escapedKw = kw:gsub("%-", "%%-")
            
            -- Deteksi presisi menggunakan word boundary %f[%W] agar tidak terjadi salah deteksi parsial
            if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then 
                return true, desc.Name 
            end
        end
    end
    if ESP_Config.FindValuables then
        -- LOGIKA DETEKSI COMPONENT BERLAPIS (NVG/Thermal pada Mount/Helmet)
        if nLower:find("mount") or nLower:find("helmet") or nLower:find("headset") then
            local highValueOptics = {"nvg", "goggles", "reap-ir", "reapir", "thermal", "onv-9", "onv9", "quadnvg", "quad"}
            for _, optic_kw in ipairs(highValueOptics) do
                if nLower:find(optic_kw) then
                    return true, "HIGH-VALUE NIGHT VISION MOUNT"
                end
            end
        end

        -- Database barang berharga (Valuables) kasta tertinggi hasil riset Project Delta Wiki
        local valuableKeywords = {
            "solter", "gold", "sps", "watch", "tix", "ticket", 
            "cpu", "ram", "ssd", "gpu", "smartphone", "phone",
            "ruble", "rubles", "cash", "money",
            -- Mempertahankan NVG/Thermal karena terikat dengan logika Component Berlapis di atasnya
            "nvg", "goggles", "reap-ir", "reapir", "thermal", "onv-9", "onv9", "quadnvg", "quad"
        }
        
        for _, kw in ipairs(valuableKeywords) do 
            local escapedKw = kw:gsub("%-", "%%-")
            if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then return true, desc.Name end
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
            if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then return true, desc.Name end
        end
    end
    if ESP_Config.FindAttachments then
        -- Database aksesoris senjata kasta tertinggi hasil riset Project Delta Wiki
        local attachmentKeywords = {
            "lpvo", "rifle scope", "reap-ir", "reapir", "holographic", "acog", 
            "laser pointer", "peq-15", "peq15", "socom556", "rc2", 
            "muzzle brake", "pbs-1", "pbs1"
        }
        for _, kw in ipairs(attachmentKeywords) do 
            -- SINKRONISASI OTOMATIS: Mengubah tanda minus (-) menjadi %%- secara dinamis agar aman dibaca Lua Match
            local escapedKw = kw:gsub("%-", "%%-")
            if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then return true, desc.Name end
        end
    end
    if ESP_Config.FindEquipment then
        -- Database armor, tas, dan visor kasta tertinggi hasil riset ingame (Huruf kecil semua, tanpa tanda %)
        local equipKeywords = {
            "juggernaut", "hspv", "tactical", "6b45", "kulon", "concealed", 
            "attak", "tortilla", "titan", "low cut", "fast mt", "quad", 
            "altyn helmet", "maska", "tor-s", "zsh", "crown", "atlyn", "mount", "headset"
        }
        
        for _, kw in ipairs(equipKeywords) do 
            -- SINKRONISASI OTOMATIS: Mengubah tanda minus (-) menjadi %%- secara dinamis agar aman dibaca Lua Match
            local escapedKw = kw:gsub("%-", "%%-")
            
            -- Deteksi presisi menggunakan kata utuh %f[%W] agar tidak terjadi salah deteksi parsial
            if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then 
                return true, desc.Name 
            end
        end
    end
    return false, nil
end

local function checkContainerLoot(container)
    if not (ESP_Config.FindWeapons or ESP_Config.FindValuables or ESP_Config.FindKeys or ESP_Config.FindAttachments or ESP_Config.FindEquipment) then return false, "" end
    for _, desc in ipairs(container:GetDescendants()) do
        -- [FIX FATAL] Evaluasi BasePart TAPI block nama part bawaan container (engsel, keypad) agar senjata/GPU 3D tetap terbaca
        local isContainerPart = desc.Name:lower():find("mount") or desc.Name:lower():find("keypad") or desc.Name:lower():find("hinge") or desc.Name:lower():find("door") or desc.Name:lower():find("lock") or desc.Name:lower():find("frame") or desc.Name:lower():find("drawer")
        if not isContainerPart then
            local isMatch, matchName = GetValuableMatch(desc)
            if isMatch then return true, matchName end
        end
        
        -- [PERBAIKAN] Project Delta sering menyembunyikan mata uang & loot di dalam memori StringValue (Contoh: Name="Slot1", Value="Rubles")
        if desc:IsA("StringValue") and desc.Value and desc.Value ~= "" then
            local isValueMatch, _ = GetValuableMatch({Name = desc.Value})
            if isValueMatch then return true, desc.Value end
        end
    end
    return false, ""
end

local isScanningMaster = false

task.spawn(function()
    task.wait(5)
    while task.wait(2) do
        if isScanningMaster then continue end
        isScanningMaster = true
        
        local lpChar = LocalPlayer.Character
        if not lpChar then isScanningMaster = false; continue end

        -- 1. Player Scan
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
        end

        -- 2. Master Entity & Item Scanner (Zero Lag, Optimized Target Folders)
        local scanCounter = 0
        local function ScanObject(obj, scanCategory)
            scanCounter = scanCounter + 1
            if scanCounter % 150 == 0 then task.wait() end
            
            local nameLower = obj.Name:lower()
            
            -- [FIX] BLACKLIST TOTAL TEKS SAMPAH DAN POTONGAN ANATOMI TERPISAH
            if nameLower:find("effect") or nameLower:find("bullet") or nameLower:find("tracer") then return end
            if nameLower:find("poster") or nameLower:find("decal") or nameLower:find("sign") or nameLower:find("prop") or nameLower:find("static") or nameLower:find("building") or nameLower:find("foliage") then
                return
            end

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

            if scanCategory == "Entity" then
                local isHeli = nameLower:find("heli") or nameLower:find("mi%-24") or nameLower:find("mi24") or nameLower:find("gunship") or nameLower:find("helicopter")
                
                local isPlayerChar = Players:GetPlayerFromCharacter(obj) ~= nil
                if not isPlayerChar then
                    -- 2. KUNCI DUPLIKASI HELIKOPTER
                    if isHeli then
                        if not ESP_Objects[obj] then
                            local isDescendant = false
                            for parentObj, boxData in pairs(ESP_Objects) do
                                if boxData.IsHelicopter and obj:IsDescendantOf(parentObj) then
                                    isDescendant = true
                                    break
                                end
                            end
                            if isDescendant then return end -- Abaikan part anak helikopter agar teks tidak duplikat
                        end
                    end

                    local isDead = IsEntityDead(obj)

                    if ESP_Objects[obj] then
                        -- Jika sudah ada di memori (Re-Scan Status)
                        if not ESP_Objects[obj].IsContainer and not ESP_Objects[obj].IsLooseItem then
                            -- OVERWRITE INSTAN: Musuh yang tadinya hidup, detik ini terdeteksi mati
                            -- OVERWRITE INSTAN: Musuh hidup yang baru saja Anda tembak mati
                            if isDead and not ESP_Objects[obj].IsDeadCache then
                            RemoveESP(obj) -- Hapus kotak putih lamanya
                            ESP_Objects[obj] = nil
                
                        -- Deteksi ulang sebagai entitas mayat baru
                        task.defer(function()
                            CreateESP(obj, false)
                            if ESP_Objects[obj] then
                                ESP_Objects[obj].IsDeadCache = true
                            end
                        end)
                    end

                            -- LOGIKA RESPAWN: Musuh yang tadinya mati, detik ini terdeteksi hidup kembali (recycle model)
                            elseif not isDead and ESP_Objects[obj].IsDeadCache then
                                RemoveESP(obj)          -- Hancurkan sisa visual mayat lama di layar
                                CreateESP(obj, false)   -- Bangun boks visual yang baru dan segar untuk musuh hidup
                                if ESP_Objects[obj] then
                                    ESP_Objects[obj].IsDeadCache = false -- Paksa ubah status memori agar sistem Aimlock aktif kembali
                                    if isHeli then ESP_Objects[obj].IsHelicopter = true end
                                end
                            end
                        end
                    else
                        -- Jika belum ada di memori (Scan Musuh Baru)
                        if IsValidEntity(obj) or isHeli then
                            CreateESP(obj, false)
                            if ESP_Objects[obj] then 
                                ESP_Objects[obj].IsDeadCache = isDead 
                                if isHeli then ESP_Objects[obj].IsHelicopter = true end
                                if isDead then
                                    pcall(function()
                                        if ESP_Objects[obj].DistBillboard then 
                                            ESP_Objects[obj].DistBillboard:Destroy()
                                            ESP_Objects[obj].DistBillboard = nil
                                            ESP_Objects[obj].DistLabel = nil
                                        end
                                    end)
                                end
                            end
                        elseif isDead then
                            CreateESP(obj, false)
                            if ESP_Objects[obj] then 
                                ESP_Objects[obj].IsDeadCache = true 
                                if isHeli then ESP_Objects[obj].IsHelicopter = true end
                                pcall(function()
                                    if ESP_Objects[obj].DistBillboard then 
                                        ESP_Objects[obj].DistBillboard:Destroy()
                                        ESP_Objects[obj].DistBillboard = nil
                                        ESP_Objects[obj].DistLabel = nil
                                    end
                                end)
                            end
                        end
                    end
                end

            elseif scanCategory == "Container" then
                if not (ESP_Config.FindWeapons or ESP_Config.FindValuables or ESP_Config.FindKeys or ESP_Config.FindAttachments or ESP_Config.FindEquipment) then return end
                
                local isContainer = false
                -- [FIX] Database Lootable Container disesuaikan spesifik dengan Project Delta Wiki
                local containerKeywords = {
                    "pc", "safe", "satchel", "box", "cache", "register", "drop", "cabinet", "filing", "kgb", "abpopa", 
                    "vault", "islootable", "crate", "sport", "airdrop", "bag", "drawer", "jacket", "case", "stim"
                }
                
                for _, c in ipairs(containerKeywords) do
                    if nameLower:find(c) and not nameLower:find("skybox") and not nameLower:find("hitbox") and not nameLower:find("bhitbox") then
                        isContainer = true; break
                    end
                end

                if isContainer and obj:IsA("Folder") then isContainer = false end

                if isContainer then
                    local hasLoot, matchName = checkContainerLoot(obj)

                    -- [OPTIMISASI MEMORI] Hanya daftarkan dan buat objek visual jika kontainer terbukti berisi loot berharga
                    if hasLoot then
                        if not ESP_Objects[obj] then
                            local adorneePart = (obj:IsA("BasePart") and obj) or obj:FindFirstChildWhichIsA("BasePart", true)
                            if adorneePart then
                                local bb = Instance.new("BillboardGui")
                                bb.Size = UDim2.new(0, 250, 0, 30); bb.AlwaysOnTop = true
                                bb.Adornee = adorneePart; bb.Parent = adorneePart
                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
                                txt.Text = ""
                                txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                                txt.TextStrokeTransparency = 0; txt.Font = ESP_Config.Font; txt.TextSize = 13
                                Instance.new("UIStroke", txt).Thickness = 2
                                
                                local hl = Instance.new("Highlight")
                                hl.Name = "LootHighlight"
                                hl.FillColor = Color3.fromRGB(212, 175, 55); hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                                hl.FillTransparency = 0.7; hl.OutlineTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = adorneePart; hl.Parent = adorneePart
                                
                                bb.Enabled = false
                                hl.Enabled = false
                                
                                ESP_Objects[obj] = {Billboard = bb, Highlight = hl, IsContainer = true, HasLoot = true, TargetAdornee = adorneePart}
                            end
                        else
                            ESP_Objects[obj].HasLoot = true
                        end
                    else
                        -- [PEMBERSIHAN] Jika kontainer yang sebelumnya tersimpan (Emas) kini sudah kosong (lootnya diambil), bersihkan total memorinya!
                        if ESP_Objects[obj] then
                            RemoveESP(obj)
                        end
                    end
                end

            elseif scanCategory == "LooseItem" then
                if not (ESP_Config.FindWeapons or ESP_Config.FindValuables or ESP_Config.FindKeys or ESP_Config.FindAttachments or ESP_Config.FindEquipment) then return end
                
                if not ESP_Objects[obj] and (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Model") or obj:IsA("Tool")) then
                    local isMatch, matchName = GetValuableMatch(obj)
                    
                    -- BONGKAR LOGIKA DROPPED ITEMS SULTAN
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
                        bb.Size = UDim2.new(0, 250, 0, 30); bb.AlwaysOnTop = true
                        bb.Adornee = adorneePart; bb.Parent = adorneePart
                        
                        local txt = Instance.new("TextLabel", bb)
                        txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
                        txt.Text = "[ " .. matchName .. " ]"
                        txt.TextColor3 = Color3.fromRGB(255, 215, 0)
                        txt.TextStrokeTransparency = 0; txt.Font = ESP_Config.Font; txt.TextSize = 13
                        Instance.new("UIStroke", txt).Thickness = 2
                        
                        local hl = Instance.new("Highlight")
                        hl.Name = "LootHighlight"
                        hl.FillColor = Color3.fromRGB(212, 175, 55); hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                        hl.FillTransparency = 0.7; hl.OutlineTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee = adorneePart; hl.Parent = adorneePart
                        
                        ESP_Objects[obj] = {Billboard = bb, Highlight = hl, TargetAdornee = adorneePart, IsLooseItem = true, ItemName = matchName}
                    end
                end
            end
        end
        
        -- A. Player Scan (Real Players)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
        end
        task.wait()

        -- B. AI Bot, NPC, Helicopter & Mayat Scan (Hanya root Workspace)
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "DroppedItems" and child.Name ~= "Containers" and child.Name ~= "Terrain" and child.Name ~= "Camera" then
                ScanObject(child, "Entity")
            end
        end
        task.wait()

        -- B.2. AI Bot Scan Spesifik (Membongkar markas persembunyian NPC di Project Delta)
        local aiZonesFolder = workspace:FindFirstChild("AiZones")
        if aiZonesFolder then
            -- [FIX] Mengadopsi rekursi GetDescendants dari Reference.lua agar Sniper terdalam tertangkap Radar!
            for _, bot in ipairs(aiZonesFolder:GetDescendants()) do
                if bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then
                    ScanObject(bot, "Entity")
                end
            end
        end
        task.wait()

        -- C. Containers Scan (Hanya di folder Containers)
        local containersFolder = workspace:FindFirstChild("Containers")
        if containersFolder then
            for _, child in ipairs(containersFolder:GetChildren()) do
                ScanObject(child, "Container")
            end
        end
        task.wait()

        -- D. Loose Items Scan (Hanya di folder DroppedItems)
        local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
        if droppedItemsFolder then
            for _, child in ipairs(droppedItemsFolder:GetChildren()) do
                ScanObject(child, "LooseItem")
            end
        end
        task.wait()
        
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
        
        -- 5. Performance Mode & Weather Control
        if ESP_Config.PerformanceMode ~= LastPerformanceState then
            LastPerformanceState = ESP_Config.PerformanceMode
            
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
                
                task.spawn(function()
                    local cnt = 0
                    local function ScanPerformance(obj)
                        cnt = cnt + 1
                        if cnt % 25 == 0 then task.wait() end
                        
                        if not obj or obj == workspace.Terrain then return end
                        
                        local nameLower = obj.Name:lower()
                        if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("debris") or nameLower:find("effect") or nameLower == "camera" then return end

                        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
                            if nameLower:find("rain") or nameLower:find("snow") or nameLower:find("weather") or nameLower:find("fog") or nameLower:find("storm") or nameLower:find("drop") then
                                if obj.Enabled then DisabledEffects[obj] = true; obj.Enabled = false end
                                if obj:IsA("ParticleEmitter") then obj:Clear() end
                            end
                        elseif obj:IsA("Sound") then
                            if nameLower:find("rain") or nameLower:find("storm") or nameLower:find("weather") or nameLower:find("thunder") then
                                if not TextureBackups[obj] then TextureBackups[obj] = {Volume = obj.Volume} end
                                obj.Volume = 0
                            end
                        elseif obj:IsA("BasePart") then
                            if not TextureBackups[obj] then TextureBackups[obj] = {Material = obj.Material, CastShadow = obj.CastShadow} end
                            obj.Material = Enum.Material.SmoothPlastic
                            obj.CastShadow = false
                        elseif (obj:IsA("Texture") or obj:IsA("Decal")) and obj.Transparency < 1 then
                            if not TextureBackups[obj] then TextureBackups[obj] = {Transparency = obj.Transparency} end
                            obj.Transparency = 1
                        end

                        for _, child in ipairs(obj:GetChildren()) do
                            ScanPerformance(child)
                        end
                    end
                    for _, child in ipairs(workspace:GetChildren()) do ScanPerformance(child) end
                    pcall(function() workspace.Terrain.Decoration = false end)
                end)
            else
                for obj, _ in pairs(DisabledEffects) do
                    if obj and obj.Parent then pcall(function() obj.Enabled = true end) end
                end
                table.clear(DisabledEffects)
                pcall(function() workspace.Terrain.Decoration = true end)
                
                task.spawn(function()
                    local cnt = 0
                    for obj, data in pairs(TextureBackups) do
                        cnt = cnt + 1
                        if cnt % 25 == 0 then task.wait() end
                        if obj and obj.Parent then
                            if obj:IsA("BasePart") then
                                if data.Material then obj.Material = data.Material end
                                if data.CastShadow ~= nil then obj.CastShadow = data.CastShadow end
                            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                                if data.Transparency then obj.Transparency = data.Transparency end
                            elseif obj:IsA("Sound") then
                                if data.Volume then obj.Volume = data.Volume end
                            elseif obj:IsA("Atmosphere") then
                                if data.Density then obj.Density = data.Density end
                            end
                        end
                    end
                    table.clear(TextureBackups)
                end)
                
                Lighting.GlobalShadows = LightingBackups.GlobalShadows
                Lighting.FogEnd = LightingBackups.FogEnd
                Lighting.FogStart = LightingBackups.FogStart
                Lighting.Brightness = LightingBackups.Brightness
                Lighting.Ambient = LightingBackups.Ambient
                Lighting.OutdoorAmbient = LightingBackups.OutdoorAmbient
            end
        end
        
        if ESP_Config.PerformanceMode then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 999999
            Lighting.FogStart = 0
            Lighting.Brightness = 2.0
            Lighting.Ambient = Color3.fromRGB(85, 85, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(85, 85, 95)
            
            for _, effect in ipairs(Lighting:GetDescendants()) do
                if effect:IsA("Atmosphere") then
                    if not TextureBackups[effect] then TextureBackups[effect] = {Density = effect.Density} end
                    effect.Density = 0
                elseif effect:IsA("Clouds") or effect:IsA("PostEffect") then
                    if effect.Enabled then
                        if not DisabledEffects[effect] then DisabledEffects[effect] = true end
                        effect.Enabled = false
                    end
                end
            end
        end
        
        isScanningMaster = false
    end
end)

-- // Main Render Loop (Fixed Geometrical Hierarchy & Anti-Lag Edition)
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
        
        local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
        
        local isDead = IsEntityDead(char)
        if box.IsDeadCache == true then isDead = true end 
        
        local isItem = false
        if box.IsContainer or box.IsLooseItem then
            isItem = true
        end
        if isDead then
            isItem = false 
        end
        
        -- =======================================================
        -- A. RENDERING UNTUK ENTITAS HIDUP DAN MAYAT (PLAYER / BOT)
        -- =======================================================
        if ESP_Config.Enabled and char and not isItem and char ~= lpChar then
            local rootPart = nil
            if char:IsA("BasePart") then
                rootPart = char
            else
                rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or
                           char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or
                           char:FindFirstChildWhichIsA("BasePart", true)
            end
            
            if isDead and not rootPart and char then
                rootPart = char:FindFirstChildWhichIsA("BasePart", true) or char
            end
            
            if rootPart then
                local rootPos = rootPart:IsA("BasePart") and rootPart.Position or rootPart:GetPivot().Position
                local studsDist = (cameraPos - rootPos).Magnitude
                local distMeter = math.floor(studsDist / 3.571428)
                
                local shouldRender = false
                if isDead then
                    shouldRender = (studsDist <= 350)
                else
                    local isPlayerChar = (typeof(entity) == "Instance" and entity:IsA("Player")) or Players:GetPlayerFromCharacter(char) ~= nil
                    if isPlayerChar then
                        shouldRender = (studsDist <= 3150)
                    else
                        shouldRender = (studsDist <= 1575)
                    end
                end
                
                local dynamicTextSize = math.clamp(10 - math.floor(studsDist / 200), 8, 10)
                
                if shouldRender then
                    local finalColor
                    if isDead then
                        finalColor = COLOR_DEAD
                        box.CanBeAimlocked = false
                        if box.DistBillboard then box.DistBillboard.Enabled = false end
                        if box.DistLabel then box.DistLabel.Text = "" end
                        if box.Billboard then box.Billboard.Enabled = false end
                    else
                        local visStatus, visColor = checkTargetVisibility(rootPart, char)
                        finalColor = visColor
                        
                        if visStatus == "Visible" then
                            box.CanBeAimlocked = true
                        else
                            box.CanBeAimlocked = false
                        end
                    end
                    
                    if box.Highlight then 
                        box.Highlight.Enabled = true
                        box.Highlight.FillColor = finalColor
                        box.Highlight.OutlineColor = finalColor 
                        if box.Highlight.Parent ~= box.TargetAdornee then box.Highlight.Parent = box.TargetAdornee end
                    end
                    
                    if box.IsHelicopter then
                        if box.DistBillboard then box.DistBillboard.Enabled = false end
                        if box.DistLabel then box.DistLabel.Text = "" end
                        if box.Billboard then box.Billboard.Enabled = false end
                    else
                        if box.NameLabel then 
                            box.NameLabel.Text = ""
                            box.NameLabel.Visible = false
                        end
                        if box.DistLabel and not isDead then 
                            box.DistLabel.Text = string.format("[%d m]", distMeter)
                            box.DistLabel.TextColor3 = finalColor
                            box.DistLabel.TextSize = dynamicTextSize
                            if box.DistBillboard and box.DistBillboard.Adornee ~= rootPart then 
                                box.DistBillboard.Adornee = rootPart 
                            end 
                            box.DistBillboard.Enabled = true
                        end
                    end
                else
                    box.CanBeAimlocked = false
                    if box.Highlight then box.Highlight.Enabled = false end
                    if box.Billboard then box.Billboard.Enabled = false end
                    if box.DistBillboard then box.DistBillboard.Enabled = false end
                end
            end
        -- =======================================================
        -- B. RENDERING UNTUK ITEM DAN LOOT CONTAINER
        -- =======================================================
        elseif ESP_Config.Enabled and isItem then
            box.CanBeAimlocked = false
            local itemPos = nil
            if box.TargetAdornee and box.TargetAdornee:IsA("BasePart") then
                itemPos = box.TargetAdornee.Position
            elseif entity:IsA("BasePart") then
                itemPos = entity.Position
            end

                if itemPos then
                    local studsDist = (cameraPos - itemPos).Magnitude
                local inRange = (studsDist <= 87.5)

                if inRange then
                    if box.IsContainer then
                        if box.HasLoot and studsDist > 4 then
                            if box.Highlight then 
                                box.Highlight.Enabled = true
                                box.Highlight.FillColor = Color3.fromRGB(255, 215, 0) 
                                box.Highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
                                if box.Highlight.Parent ~= box.TargetAdornee then box.Highlight.Parent = box.TargetAdornee end
                            end
                            if box.DistLabel then box.DistLabel.Text = "" end
                            if box.Billboard then box.Billboard.Enabled = false end
                            if box.DistBillboard then box.DistBillboard.Enabled = false end
                        else
                            if box.Highlight then box.Highlight.Enabled = false end
                            if box.Billboard then box.Billboard.Enabled = false end
                            if box.DistBillboard then box.DistBillboard.Enabled = false end
                            if box.DistLabel then box.DistLabel.Text = "" end
                        end
                    elseif box.IsLooseItem then
                        if box.Billboard then box.Billboard.Enabled = true end
                        if box.Highlight then 
                            box.Highlight.Enabled = true
                            box.Highlight.FillColor = Color3.fromRGB(212, 175, 55)
                            box.Highlight.OutlineColor = Color3.fromRGB(212, 175, 55)
                            if box.Highlight.Parent ~= box.TargetAdornee then box.Highlight.Parent = box.TargetAdornee end
                        end
                    end
                else
                    if box.Billboard then box.Billboard.Enabled = false end
                    if box.Highlight then box.Highlight.Enabled = false end
                    if box.DistBillboard then box.DistBillboard.Enabled = false end
                end
            else
                if box.Billboard then box.Billboard.Enabled = false end
                if box.Highlight then box.Highlight.Enabled = false end
                if box.DistBillboard then box.DistBillboard.Enabled = false end
            end
        else
            box.CanBeAimlocked = false
            if box.Highlight then box.Highlight.Enabled = false end
            if box.Billboard then box.Billboard.Enabled = false end
            if box.DistBillboard then box.DistBillboard.Enabled = false end
        end
    end


    -- // Aimlock Logic
    if ESP_Config.AimLock and IsAiming then
        -- Validasi target saat ini: Harus ada, hidup, dan masih valid untuk aimlock (Visible)
        -- [FIX] Memastikan Aimlock akan langsung lepas dan mencari target baru jika musuh bersembunyi di balik tembok
        if CurrentTargetEntity and CurrentTargetChar and ESP_Objects[CurrentTargetEntity] then
            if not ESP_Objects[CurrentTargetEntity].CanBeAimlocked or IsEntityDead(CurrentTargetChar) then
                CurrentTargetEntity = nil; CurrentTargetChar = nil
            end
        else
            CurrentTargetEntity = nil; CurrentTargetChar = nil
        end
        
        if not CurrentTargetChar then
            CurrentTargetEntity, CurrentTargetChar = GetBestTargetInFOV()
        end
        
        if CurrentTargetChar then
            local tHead = CurrentTargetChar:FindFirstChild("Head") or CurrentTargetChar:FindFirstChild("HumanoidRootPart") or CurrentTargetChar:FindFirstChildWhichIsA("BasePart", true)
            if tHead then
                local studsDist = (cameraPos - tHead.Position).Magnitude
                local bulletSpeed = GetBulletSpeed()
                if bulletSpeed <= 0 then bulletSpeed = 1500 end
                
                local t = studsDist / bulletSpeed
                local currentVelocity = tHead.AssemblyLinearVelocity
                if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0,0,0) end
                
                local futurePos = tHead.Position + (currentVelocity * t)
                
                -- If Gun Mods are on, bullet drop is zero.
                local dropCompensation = ESP_Config.GunMods and 0 or (workspace.Gravity * t * t) / 2
                local finalAimPos = futurePos + Vector3.new(0, dropCompensation, 0)
                
                local screenPosAim, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                if onScreenAim then
                    local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, finalAimPos)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.6)
                end
            else
                CurrentTargetEntity = nil; CurrentTargetChar = nil
            end
        end
    else
        CurrentTargetEntity = nil; CurrentTargetChar = nil
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

-- [[ SYSTEM RECONGITION & MEMORY PURGE EXTENSION ]]
-- Memastikan skrip melakukan pembersihan total saat Anda extract / kembali ke lobby

local function PurgeAllGarbageMemory()
    -- Mematikan semua visual yang masih menempel di layar sebelum dibersihkan
    for entity, box in pairs(ESP_Objects) do
        pcall(function()
            if box.Highlight then box.Highlight:Destroy() end
            if box.Billboard then box.Billboard:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end
            if box.Connection then box.Connection:Disconnect() end
        end)
    end
    
    -- Mengosongkan seluruh tabel runtime agar RAM komputer/HP kembali lega
    table.clear(ESP_Objects)
    table.clear(ignoreList)
    table.clear(CrosshairLines)
    CurrentTargetEntity = nil
    CurrentTargetChar = nil
    
    -- Memaksa Lua Garbage Collector membersihkan sisa data
    setmetatable(ESP_Objects, nil)
    collectgarbage("collect")
end

-- [[ KONEKSI EVENT UTAMA DI BARIS AKHIR ]]
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        PurgeAllGarbageMemory()
        pcall(function() RunService:UnbindFromRenderStep("RomeoZach_Render") end)
    else
        if ESP_Objects[player] then
            pcall(function()
                local box = ESP_Objects[player]
                if box.Highlight then box.Highlight:Destroy() end
                if box.Billboard then box.Billboard:Destroy() end
                if box.Connection then box.Connection:Disconnect() end
            end)
            ESP_Objects[player] = nil
        end
    end
end)

print("[ROMEOZACH SC]: Skrip berhasil dikompilasi utuh 100%. Menu Visual Clean UI Aktif!")
