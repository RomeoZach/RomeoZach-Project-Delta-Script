local LogService = game:GetService("LogService")
LogService.MessageOut:Connect(function(message, messageType)
    if message:find("TimeLabel") or message:find("GameplayVariables") or message:find("TargetAttachment") then
        -- Paksa hapus dan bungkam pesan dari antrean console agar CPU tidak lag
        return
    end
end)

--[[
    ================================================================================
    --|                                                                            |--
    --|           PROJECT DELTA V8 ULTIMATE - REBUILT & MODULARIZED                |--
    --|                             Author  : RomeoZach                            |--
    --|                                                                            |--
    ================================================================================
]]

pcall(function()

    --[[
        ================================================
        --        MODULE 1: CORE CONFIG & UI SETUP        --
        ================================================
    ]]
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
        AimLock = false,
        ESP_Players = true,
        ESP_Corpses = false,
        ESP_Loot = false,
        ESP_Containers = false,
        BulletTracers = false,
        Crosshair = false,
        VisCheck = true,
        GunMods = false, -- No Recoil & No Spread
        FindWeapons = false, -- Item Finder for Guns
        FindValuables = false, -- Item Finder for Valuables
        FindKeys = false,
        FindAttachments = false,
        PerformanceMode = false,
        -- UI & Visual Settings
        Color = Color3.fromRGB(255, 255, 255),
        WeaponColor = Color3.fromRGB(255, 255, 0),
        BulletColor = Color3.fromRGB(255, 255, 0),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        FovRadius = 300
    }

    -- // ESP Theme Colors
    local COLOR_VISIBLE = ESP_Config.Color
    local COLOR_BLOCKED = Color3.fromRGB(160, 160, 165) -- Gray
    local COLOR_DEAD    = Color3.fromRGB(221, 160, 221) -- Ungu Plum

    -- // Runtime Tables
    local ESP_Objects = {}
    local IsAiming = false
    local CurrentTargetEntity = nil
    local CurrentTargetChar = nil
    local WeaponConnections = {}
    local ActiveBulletTracers = {}
    local CrosshairLines = {}
    local AmmoBackups = {} -- For Gun Mods
    local TextureBackups = {}
    local LightingBackups = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        Decoration = workspace.Terrain.Decoration,
        FogColor = Lighting.FogColor
    }
    local DisabledEffects = {}
    local LastPerformanceState = false

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

    -- // UI Framework (Rebuilt - 2 Column Layout)
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
    local oldUi = PlayerGui:FindFirstChild("RomeoZach_Ui")
    if oldUi then
        pcall(function() oldUi:Destroy() end)
        task.wait(0.2)
    end

    local RomeoZachGui = Instance.new("ScreenGui")
    RomeoZachGui.Name = "RomeoZach_Ui"
    RomeoZachGui.ResetOnSpawn = false
    RomeoZachGui.DisplayOrder = 999999
    RomeoZachGui.IgnoreGuiInset = true
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

    -- // Main UI Frame
    local MainFrame = Instance.new("Frame", RomeoZachGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 480, 0, 260) 
    MainFrame.Position = UDim2.new(0.5, -240, 0.5, -150)
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

    -- // Header 
    local Header = Instance.new("TextLabel", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundTransparency = 1
    Header.Text = "Project Delta V5 - Final"
    Header.TextColor3 = Color3.fromRGB(240, 240, 245)
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold
    Header.TextXAlignment = Enum.TextXAlignment.Center

    -- // Container & Padding
    local Container = Instance.new("Frame", MainFrame)
    Container.Size = UDim2.new(1, -20, 1, -45)
    Container.Position = UDim2.new(0, 10, 0, 35)
    Container.BackgroundTransparency = 1

    -- // UIGridLayout
    local UIGridLayout = Instance.new("UIGridLayout", Container)
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    UIGridLayout.CellSize = UDim2.new(0.5, -5, 0, 40)

    local function CreateToggle(labelText, configKey)
        local Frame = Instance.new("Frame", Container)
        Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 27)
        Frame.BorderSizePixel = 0
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

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
        Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame", Track)
        Knob.Size = UDim2.new(0, 16, 0, 16)
        Knob.Position = ESP_Config[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local Btn = Instance.new("TextButton", Track)
        Btn.Size = UDim2.new(1, 0, 1, 0)
        Btn.BackgroundTransparency = 1
        Btn.Text = ""

        Btn.MouseButton1Click:Connect(function()
            ESP_Config[configKey] = not ESP_Config[configKey]
            local isActive = ESP_Config[configKey]
            TweenService:Create(Track, TweenInfo.new(0.2), { BackgroundColor3 = isActive and ESP_Config.Color or Color3.fromRGB(40, 43, 48) }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = isActive and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()

            if configKey == "AimLock" and not ESP_Config.AimLock then CurrentTargetChar = nil end
            
            if configKey == "Crosshair" then
                for _, line in ipairs(CrosshairLines) do
                    line.Visible = ESP_Config.Crosshair
                end
            end
        end)
        
        return Frame
    end

    -- // UI Elements
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
        --          MODULE 2: INPUT & UTILITIES           --
    ]]
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

    --[[
        ================================================
        --         MODULE 3: VISIBILITY ENGINE          --
        ================================================
    ]]
    -- // Core Systems
    local function checkTargetVisibility(targetPart, targetChar)
        table.clear(ignoreList)

        local origin = Camera.CFrame.Position
        local targetPos = targetPart.Position
        local direction = targetPos - origin
        
        if direction.Magnitude < 7 then
            return "Visible", ESP_Config.Color, true
        end

        if not ESP_Config.VisCheck then return "Visible", ESP_Config.Color, false end
        local lpChar = LocalPlayer.Character
        if not lpChar or not lpChar:FindFirstChild("Head") then return "Blocked", COLOR_BLOCKED, false end
        
        table.insert(ignoreList, lpChar)
        table.insert(ignoreList, Camera)
        if targetChar then table.insert(ignoreList, targetChar) end
        
        local loopCounter = 0
        while true do
            loopCounter = loopCounter + 1
            if loopCounter >= 30 then return "Blocked", COLOR_BLOCKED, false end

            sharedRaycastParams.FilterDescendantsInstances = ignoreList
            local raycastResult = workspace:Raycast(origin, direction, sharedRaycastParams)

            if not raycastResult then return "Visible", ESP_Config.Color, false end
            
            local hitInstance = raycastResult.Instance
            if hitInstance:IsA("Terrain") or hitInstance.Name == "Terrain" then return "Blocked", COLOR_BLOCKED, false end
            if hitInstance:IsDescendantOf(targetPart.Parent) then return "Visible", ESP_Config.Color, false end

            local mat = raycastResult.Material
            local isWallbangable = WallbangableMaterials[mat] or hitInstance.Transparency >= 0.8 or hitInstance.Name:lower():find("grass") or hitInstance.Name:lower():find("glass") or hitInstance.Name:lower():find("ignore")
            
            if isWallbangable then
                table.insert(ignoreList, hitInstance)
            else
                return "Blocked", COLOR_BLOCKED, false
            end
        end
    end

    local function GetBestTargetInFOV()
        local bestEntity, bestChar = nil, nil
        local shortestPixelDist = 300
        local centerPos = Camera.ViewportSize / 2
        local origin = Camera.CFrame.Position
        
        for entity, box in pairs(ESP_Objects) do
            -- [REVISI] Menghapus 'if not box.CanBeAimlocked then continue end' untuk mencegah Aimlock macet.

            local char = (typeof(entity) == "Instance" and entity:IsA("Player") and entity.Character) or entity
            if char and char ~= LocalPlayer.Character and char.Parent then
                -- [REVISI] Memaksa pencarian part ke kepala
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head and not IsEntityDead(char) then
                    -- [REVISI] Pengecekan visibilitas langsung di dalam fungsi
                    local visStatus, _, _ = checkTargetVisibility(head, char)
                    if visStatus ~= "Visible" then continue end

                    local studsDist = (origin - head.Position).Magnitude
                    
                    local isPlayer = (typeof(entity) == "Instance" and entity:IsA("Player")) or Players:GetPlayerFromCharacter(char) ~= nil
                    if isPlayer and studsDist > 3150 then continue end
                    if not isPlayer and studsDist > 1575 then continue end
                    
                    -- [KALIBRASI] Formula disamakan persis dengan Aimlock Logic di Render Loop
                    local bulletSpeed = GetBulletSpeed()
                    if bulletSpeed <= 0 then bulletSpeed = 1500 end
                    local timeToTarget = studsDist / bulletSpeed
                    
                    local currentVelocity = head.AssemblyLinearVelocity
                    if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0, 0, 0) end
                    
                    local dropCompensation = ESP_Config.GunMods and 0 or (workspace.Gravity * timeToTarget * timeToTarget) / 2
                    local predictedPos = head.Position + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                    
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

    --[[
        ================================================
        --      MODULE 4: ESP MANAGER (REVISED)           --
        ================================================
    ]]
    -- // ESP Creation & Management using a Single, Reliable Highlight
    local function RemoveESP(entity)
        if ESP_Objects[entity] then
            local box = ESP_Objects[entity]
            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end
            if box.Highlight_Item then box.Highlight_Item:Destroy() end
            if box.Billboard_Item then box.Billboard_Item:Destroy() end
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
            CanBeAimlocked = false,
            IsHelicopter = false,
        }
        
        local function ApplyVisuals(char)
            if not char then return end
            
            -- [REVISI] Tambahkan delay untuk menangani re-streaming AI
            if not isPlayer then
                task.wait(0.5)
                if not char or not char.Parent then return end -- Verifikasi ulang setelah delay
            end

            if box.Highlight then box.Highlight:Destroy() end
            if box.DistBillboard then box.DistBillboard:Destroy() end

            box.Character = char
            
            local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart", true)
            local initialVisStatus, initialVisColor = "Blocked", COLOR_BLOCKED
            if rootPart then
                initialVisStatus, initialVisColor = checkTargetVisibility(rootPart, char)
            end

            -- [REVISI] Hanya menggunakan SATU highlight yang menempel pada seluruh model
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
            distTxt.Size = UDim2.new(1, 0, 1, 0); distTxt.BackgroundTransparency = 1
            distTxt.Text = ""; distTxt.TextColor3 = initialVisColor; distTxt.TextSize = 13; distTxt.Font = ESP_Config.Font; distTxt.TextStrokeTransparency = 0
            distTxt.TextYAlignment = Enum.TextYAlignment.Top
            Instance.new("UIStroke", distTxt).Thickness = 1.5
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
        --         MODULE 5: SCANNER UTILITIES          --
        ================================================
    ]]
    -- // Entity Scanner (Player, AI, Items)
    local function IsValidEntity(obj)
        if not obj:IsA("Model") then return false end
        if obj.Name == LocalPlayer.Name or (LocalPlayer.Character and obj == LocalPlayer.Character) then return false end
        if obj:IsDescendantOf(Camera) then return false end
        
        local nameLower = string.lower(obj.Name)
        
        if nameLower:find("crate") or nameLower:find("box") or nameLower:find("cache") or nameLower:find("bag") or nameLower:find("satchel") or nameLower:find("register") or nameLower:find("safe") or nameLower:find("vault") or nameLower:find("desk") or nameLower:find("boulder") or nameLower:find("mesh") then
            return false
        end
        
        if nameLower:find("bullet") or nameLower:find("tracer") or nameLower:find("blood") or nameLower:find("effect") then return false end

        -- [PERBAIKAN KRITIS] Mengadopsi filter super ketat dari V1 yang terbukti stabil.
        -- Ini adalah kunci utama untuk mencegah crash saat kompilasi/eksekusi.
        if not obj:FindFirstChildOfClass("Shirt") and not obj:FindFirstChildOfClass("Pants") then
            -- Pengecualian hanya diberikan untuk mayat/ragdoll, yang akan divalidasi lebih lanjut oleh IsEntityDead.
            -- Jika tidak punya baju DAN bukan mayat, ini 100% objek map dan harus diblokir.
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
            local attachmentKeywords = {
                "lpvo", "rifle scope", "reap-ir", "reapir", "holographic", "acog", 
                "laser pointer", "peq-15", "peq15", "socom556", "rc2", 
                "muzzle brake", "pbs-1", "pbs1"
            }
            for _, kw in ipairs(attachmentKeywords) do 
                local escapedKw = kw:gsub("%-", "%%-")
                if nLower == kw or nLower:match("%f[%w]"..escapedKw.."%f[%W]") then return true, desc.Name end
            end
        end
        if ESP_Config.FindEquipment then
            local equipKeywords = {
                "juggernaut", "hspv", "tactical", "6b45", "kulon", "concealed", 
                "attak", "tortilla", "titan", "low cut", "fast mt", "quad", 
                "altyn helmet", "maska", "tor-s", "zsh", "crown", "atlyn", "mount", "headset"
            }
            
            for _, kw in ipairs(equipKeywords) do 
                local escapedKw = kw:gsub("%-", "%%-")
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
            local isContainerPart = desc.Name:lower():find("mount") or desc.Name:lower():find("keypad") or desc.Name:lower():find("hinge") or desc.Name:lower():find("door") or desc.Name:lower():find("lock") or desc.Name:lower():find("frame") or desc.Name:lower():find("drawer")
            if not isContainerPart then
                local isMatch, matchName = GetValuableMatch(desc)
                if isMatch then return true, matchName end
            end
            if desc:IsA("StringValue") and desc.Value and desc.Value ~= "" then
                local isValueMatch, _ = GetValuableMatch({Name = desc.Value})
                if isValueMatch then return true, desc.Value end
            end
        end
        return false, ""
    end

    --[[
        ================================================
        --       MODULE 6: ENTITY SCANNER THREAD        --
        ================================================
    ]]
    local isEntityScanning = false

    task.spawn(function()
        while task.wait(2) do
            if not ESP_Config.ESP_Players and not ESP_Config.ESP_Corpses then continue end

            if isEntityScanning then continue end
            isEntityScanning = true
            local lpChar = LocalPlayer.Character
            if not lpChar then isEntityScanning = false; continue end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then CreateESP(p, true) end
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
        --         MODULE 7: ITEM SCANNER THREAD        --
        ================================================
    ]]
    local isItemScanning = false

    task.spawn(function()
        while task.wait(2) do
            if isItemScanning then continue end
            isItemScanning = true
            if not ESP_Config.ESP_Loot and not ESP_Config.ESP_Containers then isItemScanning = false; continue end

            local containersFolder = workspace:FindFirstChild("Containers")
            if containersFolder and ESP_Config.ESP_Containers then
                for _, obj in ipairs(containersFolder:GetChildren()) do
                    local nameLower = obj.Name:lower()
                    local isContainer = false
                    local containerKeywords = {
                        "pc", "safe", "satchel", "box", "cache", "register", "drop", "cabinet", "filing", "kgb", "abpopa", 
                        "vault", "islootable", "crate", "sport", "airdrop", "bag", "drawer", "jacket", "case"
                    }
                    
                    for _, c in ipairs(containerKeywords) do
                        if nameLower:find(c) and not nameLower:find("skybox") and not nameLower:find("hitbox") and not nameLower:find("bhitbox") then
                            isContainer = true; break
                        end
                    end

                    if isContainer and obj:IsA("Folder") then isContainer = false end

                    if isContainer then
                        local hasLoot, matchName = checkContainerLoot(obj)

                        if not ESP_Objects[obj] then
                            local adorneePart = (obj:IsA("BasePart") and obj) or obj:FindFirstChildWhichIsA("BasePart", true)
                            if adorneePart then
                                local bb = Instance.new("BillboardGui")
                                bb.Size = UDim2.new(0, 250, 0, 30); bb.AlwaysOnTop = true
                                bb.Adornee = adorneePart; bb.Parent = adorneePart
                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Text = ""
                                txt.TextColor3 = Color3.fromRGB(255, 215, 0); txt.TextStrokeTransparency = 0; txt.Font = ESP_Config.Font; txt.TextSize = 13
                                Instance.new("UIStroke", txt).Thickness = 2
                                
                                local hl = Instance.new("Highlight")
                                hl.Name = "LootHighlight"
                                hl.FillColor = Color3.fromRGB(212, 175, 55); hl.OutlineColor = Color3.fromRGB(212, 175, 55)
                                hl.FillTransparency = 0.7; hl.OutlineTransparency = 0.5; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee = adorneePart; hl.Parent = adorneePart
                                
                                bb.Enabled = false; hl.Enabled = false
                                
                                ESP_Objects[obj] = {Billboard_Item = bb, Highlight_Item = hl, IsContainer = true, HasLoot = hasLoot, TargetAdornee = adorneePart}
                            end
                        else
                            ESP_Objects[obj].HasLoot = hasLoot
                        end
                    end
                end
            end
            task.wait()

            local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
            if droppedItemsFolder and ESP_Config.ESP_Loot then
                for _, obj in ipairs(droppedItemsFolder:GetChildren()) do
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
                            
                            ESP_Objects[obj] = {Billboard_Item = bb, Highlight_Item = hl, TargetAdornee = adorneePart, IsLooseItem = true, ItemName = matchName}
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
        --       MODULE 8: MISCELLANEOUS SCANNER THREAD     --
        ================================================
    ]]
    task.spawn(function()
        while task.wait(3) do
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
            
            if ESP_Config.PerformanceMode ~= LastPerformanceState then
                LastPerformanceState = ESP_Config.PerformanceMode
                InitialPerformanceBoost() -- Panggil lagi untuk memastikan semua bersih
                
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
                    -- Mengembalikan ke pengaturan semula
                    Lighting.FogEnd = LightingBackups.FogEnd
                    Lighting.FogStart = LightingBackups.FogStart
                    workspace.Terrain.Decoration = LightingBackups.Decoration
                    
                    for obj, _ in pairs(DisabledEffects) do
                        if obj and obj.Parent then pcall(function() obj.Enabled = true end) end
                    end
                    table.clear(DisabledEffects)
                end
            end
            
            if ESP_Config.PerformanceMode then
                Lighting.GlobalShadows = false; Lighting.FogEnd = 999999; Lighting.FogStart = 0; Lighting.Brightness = 2.0
                Lighting.Ambient = Color3.fromRGB(85, 85, 95); Lighting.OutdoorAmbient = Color3.fromRGB(85, 85, 95)
            end
        end
    end)

    local function InitialPerformanceBoost()
        -- NONAKTIFKAN KABUT & AWAN SECARA AMAN
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

        -- NONAKTIFKAN HUJAN & SUARA SECARA AMAN
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("rain") then
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") then
                    pcall(function() obj.Enabled = false end)
                elseif obj:IsA("Sound") then
                    pcall(function() obj.Volume = 0 end)
                end
            end
        end

        -- NONAKTIFKAN RUMPUT 3D
        pcall(function()
            workspace.Terrain.Decoration = false
            LightingBackups.Decoration = false
        end)
    end

    InitialPerformanceBoost()

    --[[
        ================================================
        --         MODULE 9: RENDER LOOP & AIMLOCK        --
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
                -- BLOK KHUSUS ENTITAS KARAKTER (PLAYER/AI/MAYAT)
                local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                if isDead and not rootPart then rootPart = char:FindFirstChildWhichIsA("BasePart", true) end

                if not rootPart then
                    HideVisuals()
                    continue
                end

                local rootPos = rootPart.Position
                local studsDist = (cameraPos - rootPos).Magnitude
                local distMeter = math.floor(studsDist / 3.571428)

                local shouldRender = false
                if isDead then
                    shouldRender = (studsDist <= 357)
                else
                    local isPlayerChar = Players:GetPlayerFromCharacter(char) ~= nil
                    shouldRender = (isPlayerChar and studsDist <= 3150) or (not isPlayerChar and studsDist <= 1575)
                end

                if not shouldRender then
                    HideVisuals()
                    continue
                end

                local finalColor
                if isDead then
                    finalColor = COLOR_DEAD
                    box.CanBeAimlocked = false
                else
                    -- [REVISI] Logika visibilitas berbasis kepala
                    local targetPart = char:FindFirstChild("Head") or rootPart
                    local visStatus, visColor, _ = checkTargetVisibility(targetPart, char)
                    finalColor = visColor
                    box.CanBeAimlocked = (visStatus == "Visible")
                end

                if box.Highlight then
                    -- [REVISI] Highlight untuk karakter SELALU AKTIF di semua jarak
                    box.Highlight.Enabled = true
                    box.Highlight.FillColor = finalColor
                    box.Highlight.OutlineColor = finalColor

                    -- [REVISI] Solusi Anti-Overlapping Jarak Dekat
                    if studsDist < 7 then
                        box.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        if box.Highlight.Adornee ~= char then
                            box.Highlight.Adornee = char
                        end
                        box.Highlight.OutlineTransparency = 1
                        box.Highlight.FillTransparency = 0.4
                    else
                        -- Kembalikan ke setelan normal jika jarak menjauh
                        box.Highlight.OutlineTransparency = 0
                        box.Highlight.FillTransparency = 0.5
                    end
                end

                if box.DistBillboard then
                    box.DistBillboard.Enabled = not isDead
                    if box.DistBillboard.Enabled and box.DistLabel then
                        box.DistLabel.Text = string.format("[%d m]", distMeter)
                        box.DistLabel.TextColor3 = finalColor
                    end
                end
            else 
                -- BLOK KHUSUS LOOT (ITEM/KONTAINER)
                local itemPos = (box.TargetAdornee and box.TargetAdornee:IsA("BasePart") and box.TargetAdornee.Position) or (entity:IsA("BasePart") and entity.Position)
                if not itemPos then HideVisuals(); continue end
                
                local studsDist = (cameraPos - itemPos).Magnitude
                local inRange = (studsDist <= 87.5)
                
                if box.Highlight_Item then 
                    box.Highlight_Item.Enabled = inRange and (not box.IsContainer or box.HasLoot)
                end
                -- [REVISI] Logika jarak dekat HANYA untuk loot
                if inRange and box.IsContainer and box.HasLoot and studsDist < 7 then
                    box.Highlight_Item.Enabled = false
                end
                if box.Billboard_Item then box.Billboard_Item.Enabled = inRange and box.IsLooseItem end
            end
        end -- Akhir dari loop 'for entity, box in pairs(ESP_Objects) do'

        -- // Aimlock Logic
        if ESP_Config.AimLock and IsAiming then
            local potentialTargetEntity, potentialTargetChar = GetBestTargetInFOV()
            if potentialTargetChar then
                local tHead = potentialTargetChar:FindFirstChild("Head") or potentialTargetChar:FindFirstChild("HumanoidRootPart")
                if tHead then
                    local visStatus, _ = checkTargetVisibility(tHead, potentialTargetChar)
                    if visStatus == "Visible" and not IsEntityDead(potentialTargetChar) then
                        CurrentTargetEntity = potentialTargetEntity; CurrentTargetChar = potentialTargetChar
                        local studsDist = (cameraPos - tHead.Position).Magnitude
                        
                        -- [KALIBRASI]
                        local bulletSpeed = GetBulletSpeed()
                        if bulletSpeed <= 0 then bulletSpeed = 1500 end
                        local timeToTarget = studsDist / bulletSpeed
                        local currentVelocity = tHead.AssemblyLinearVelocity
                        if currentVelocity.X ~= currentVelocity.X then currentVelocity = Vector3.new(0,0,0) end
                        
                        local dropCompensation = ESP_Config.GunMods and 0 or (workspace.Gravity * timeToTarget * timeToTarget) / 2
                        local finalAimPos = tHead.Position + (currentVelocity * timeToTarget) + Vector3.new(0, dropCompensation, 0)
                        
                        local _, onScreenAim = Camera:WorldToViewportPoint(finalAimPos)
                        if onScreenAim then
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(cameraPos, finalAimPos), 0.6)
                        end
                    else
                        CurrentTargetEntity = nil; CurrentTargetChar = nil
                    end
                else
                    CurrentTargetEntity = nil; CurrentTargetChar = nil
                end
            end
        else
            CurrentTargetEntity = nil; CurrentTargetChar = nil
        end -- Akhir dari blok 'if ESP_Config.AimLock and IsAiming then'
    end) -- Akhir dari fungsi 'RunService:BindToRenderStep'

    --[[
        ================================================
        --       MODULE 10: INITIAL CONNECTIONS & MEMORY PURGE      --
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
        for entity, box in pairs(ESP_Objects) do
            RemoveESP(entity)
        end
        table.clear(ESP_Objects)
        table.clear(ignoreList)
        table.clear(CrosshairLines)
        CurrentTargetEntity = nil
        CurrentTargetChar = nil
        if PlayerGui:FindFirstChild("RomeoZach_Ui") then 
            pcall(function() PlayerGui.RomeoZach_Ui:Destroy() end)
        end
        setmetatable(ESP_Objects, nil)
        collectgarbage("collect")
    end

    Players.PlayerRemoving:Connect(RemoveESP)
    game:BindToClose(PurgeAllGarbageMemory)

end) -- Pasangan kurung penutup untuk pcall(function() di baris pertama script
