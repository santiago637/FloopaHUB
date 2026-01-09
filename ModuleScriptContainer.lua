-- Floopa Hub - Librería de comandos (Hub principal)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- Espera robusta por LocalPlayer y cámara
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local currentCamera = Workspace.CurrentCamera
if not currentCamera then
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
    currentCamera = Workspace.CurrentCamera
end

-- Protección singleton
local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}
if gv.FloopaHub.ModuleContainer then
    return gv.FloopaHub.ModuleContainer
end

-- Estado base
local module = {
    Movement = {},
    Visual = {},
    Utility = {},
    Combat = {},
    _Internal = {}
}

-- Contexto compartido
local context = {
    LocalPlayer = localPlayer,
    Camera = currentCamera,
    Connections = {},
    Flags = {
        Flying = false,
        InfiniteJump = false,
        Noclip = false,
        ESPEnabled = false,
        XRayEnabled = false,
        Killaura = false,
        HandleKill = false,
        Aimbot = false
    },
    _LastESPUpdate = 0,
    _Default = {
        WalkSpeed = 16,
        JumpPower = 50,
        HipHeight = 2
    }
}
module._Internal.Context = context

-- Settings
module.Settings = {
    Movement = {
        DefaultWalkSpeed = 16,
        FlySpeedBase = 60,
        FlySpeedMin = 20,
        FlySpeedMax = 250
    },
    Visual = {
        ESPUpdateDelay = 0.35,
        XRayUpdateDelay = 0.6,
        XRayDefaultTransparency = 0.7
    },
    Utility = {
        LogPrefix = "[FloopaHub] "
    },
    Combat = {
        TeamSafe = true,       -- evita atacar a compañeros
        NeutralSafe = false    -- opcional: evita neutrales si el juego los usa
    }
}

-- Hook optimizado: protege Kick y remotes, sin tocar Humanoid
do 
    local mt = getrawmetatable(game) 
    if not mt then 
        module.Utility.Warn("Metatable no disponible, hook no aplicado.") 
        return 
    end 
    local original = { __namecall = mt.__namecall } 
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        local nameLower = (typeof(self) == "Instance" and (self.Name or "")):lower()

        -- Bloquear Kick directo
        if method == "Kick" then
            warn("[FloopaHub] Kick bloqueado.")
            return nil
        end

        -- Filtrar remotes sospechosos
        if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
            local bad = nameLower:find("ban") or nameLower:find("report") or nameLower:find("anti") or nameLower:find("log")
            local whitelist = nameLower:find("antique") or nameLower:find("reportcard")
            if bad and not whitelist then
                warn("[FloopaHub] Remote bloqueado: " .. self.Name)
                return nil
            end
        end

        return original.__namecall(self, unpack(args))
    end)

    setreadonly(mt, true)

    -- Función para restaurar el metatable si lo necesitas
    module._Internal.RestoreMetatable = function()
        local mt2 = getrawmetatable(game)
        setreadonly(mt2, false)
        mt2.__namecall = original.__namecall
        setreadonly(mt2, true)
    end
end

-- Inicializaciones seguras
module._Internal.Performance = { LastXRay = 0 }
local espConnection = nil
local xrayCache = {}
local noclipCache = {}

-- Utilidad
function module.Utility.Log(msg) print(module.Settings.Utility.LogPrefix..tostring(msg)) end
function module.Utility.Warn(msg) warn(module.Settings.Utility.LogPrefix..tostring(msg)) end
function module.Utility.Notify(title,text,duration)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title or "Info",Text=text or "",Duration=duration or 3})
    end)
end

-- Helpers
function module.Utility.Dist(a, b)
    if not a or not b or not a.Position or not b.Position then
        return math.huge
    end
    return (a.Position - b.Position).Magnitude
end

function module.Utility.GetTeamColor(player)
    if player and player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

function module.Utility.SameTeam(p1, p2)
    if not module.Settings.Combat.TeamSafe then return false end
    if p1 and p2 and p1.Team and p2.Team then
        return p1.Team == p2.Team
    end
    if module.Settings.Combat.NeutralSafe then
        -- algunos juegos usan Team == nil para neutral
        return (p1 and not p1.Team) or (p2 and not p2.Team)
    end
    return false
end

function module.Utility.GetCharacterRoot(plr)
    plr = plr or context.LocalPlayer
    if not plr then return nil, nil end
    local char = plr.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, root
end

function module.Utility.GetHumanoid(plr)
    plr = plr or context.LocalPlayer
    local char = plr and plr.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function module.Utility.GetNearbyPlayers(maxDistance)
    local _, myRoot = module.Utility.GetCharacterRoot(context.LocalPlayer)
    if not myRoot then return {} end
    local nearby = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= context.LocalPlayer and p.Character then
            if not module.Utility.SameTeam(context.LocalPlayer, p) then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local d = (myRoot.Position - root.Position).Magnitude
                    if d <= (tonumber(maxDistance) or 15) then
                        table.insert(nearby, {player=p, root=root, humanoid=hum, distance=d})
                    end
                end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    return nearby
end

-- Conexiones seguras
function module._Internal.AddConnection(name,conn)
    if not conn or typeof(conn)~="RBXScriptConnection" then return end
    if context.Connections[name] then pcall(function() context.Connections[name]:Disconnect() end) end
    context.Connections[name]=conn
end

function module._Internal.Disconnect(name)
    local conn=context.Connections[name]
    if conn then pcall(function() conn:Disconnect() end) context.Connections[name]=nil end
end

-- Mantener cámara actualizada
module._Internal.AddConnection("CameraChange", Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    context.Camera = Workspace.CurrentCamera or context.Camera
end))

-- AntiLag
module._Internal.AntiLag = { CleanupInterval=25, MaxPlayersBatch=20, MaxPartsBatch=250 }

task.spawn(function()
    while true do
        task.wait(module._Internal.AntiLag.CleanupInterval)
        -- conexiones huérfanas
        for n,c in pairs(context.Connections) do
            if c and not c.Connected then context.Connections[n]=nil end
        end
        -- cache de XRay
        for part,_ in pairs(xrayCache) do
            if not part or not part.Parent then xrayCache[part]=nil end
        end
    end
end)

-- Hook único y reversible

---------------------------------------------------------------------
-- Movement
---------------------------------------------------------------------

local flySpeed = module.Settings.Movement.FlySpeedBase
local moveVec = Vector3.new(0,0,0)

function module.Movement.Fly(arg, disable)
    local char, root = module.Utility.GetCharacterRoot(context.LocalPlayer)
    if not char or not root then
        module.Utility.Warn("Fly: Character o HumanoidRootPart no disponibles.")
        return
    end
    local hum = module.Utility.GetHumanoid(context.LocalPlayer)

    if disable then
        context.Flags.Flying = false
        if hum then hum.PlatformStand = false end
        module._Internal.Disconnect("Fly_InputBegan")
        module._Internal.Disconnect("Fly_InputEnded")
        module._Internal.Disconnect("Fly_Touch")
        return
    end

    local num = tonumber(arg)
    if num then
        flySpeed = math.clamp(num * 10, module.Settings.Movement.FlySpeedMin, module.Settings.Movement.FlySpeedMax)
    else
        flySpeed = module.Settings.Movement.FlySpeedBase
    end

    context.Flags.Flying = true
    if hum then hum.PlatformStand = true end

    -- Inputs PC
    local connBegan = UserInputService.InputBegan:Connect(function(input,gpe)
        if gpe then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.W then moveVec = moveVec + Vector3.new(0,0,-1)
        elseif kc == Enum.KeyCode.S then moveVec = moveVec + Vector3.new(0,0,1)
        elseif kc == Enum.KeyCode.A then moveVec = moveVec + Vector3.new(-1,0,0)
        elseif kc == Enum.KeyCode.D then moveVec = moveVec + Vector3.new(1,0,0)
        elseif kc == Enum.KeyCode.Space or kc == Enum.KeyCode.E then moveVec = moveVec + Vector3.new(0,1,0)
        elseif kc == Enum.KeyCode.LeftShift or kc == Enum.KeyCode.Q then moveVec = moveVec + Vector3.new(0,-1,0)
        end
    end)

    local connEnded = UserInputService.InputEnded:Connect(function(input,gpe)
        if gpe then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.W then moveVec = moveVec - Vector3.new(0,0,-1)
        elseif kc == Enum.KeyCode.S then moveVec = moveVec - Vector3.new(0,0,1)
        elseif kc == Enum.KeyCode.A then moveVec = moveVec - Vector3.new(-1,0,0)
        elseif kc == Enum.KeyCode.D then moveVec = moveVec - Vector3.new(1,0,0)
        elseif kc == Enum.KeyCode.Space or kc == Enum.KeyCode.E then moveVec = moveVec - Vector3.new(0,1,0)
        elseif kc == Enum.KeyCode.LeftShift or kc == Enum.KeyCode.Q then moveVec = moveVec - Vector3.new(0,-1,0)
        end
    end)

    -- Inputs móviles (Touch → deslizar)
    local connTouch = UserInputService.TouchMoved:Connect(function(touch,gpe)
        if gpe then return end
        local delta = touch.Delta
        if delta.Magnitude > 0 then
            moveVec = Vector3.new(delta.X, delta.Y, 0).Unit
        end
    end)

    module._Internal.AddConnection("Fly_InputBegan", connBegan)
    module._Internal.AddConnection("Fly_InputEnded", connEnded)
    module._Internal.AddConnection("Fly_Touch", connTouch)

    -- Loop principal con triple fallback
    task.spawn(function()
        while context.Flags.Flying do
            char, root = module.Utility.GetCharacterRoot(context.LocalPlayer)
            hum = module.Utility.GetHumanoid(context.LocalPlayer)
            if not char or not root or not hum then break end

            local dir = moveVec
            if dir.Magnitude > 0 then
                local success = pcall(function()
                    root.Velocity = dir.Unit * flySpeed
                end)
                if not success then
                    local success2 = pcall(function()
                        root.AssemblyLinearVelocity = dir.Unit * flySpeed
                    end)
                    if not success2 then
                        root.CFrame = root.CFrame + (dir.Unit * (flySpeed/60))
                    end
                end
            else
                root.Velocity = Vector3.new(0,0,0)
            end

            RunService.Heartbeat:Wait()
        end
        if hum then hum.PlatformStand = false end
        module._Internal.Disconnect("Fly_InputBegan")
        module._Internal.Disconnect("Fly_InputEnded")
        module._Internal.Disconnect("Fly_Touch")
    end)
end

local infiniteJumpConnection = nil
function module.Movement.InfiniteJump(enable)
    if enable then
        if context.Flags.InfiniteJump then return end
        context.Flags.InfiniteJump = true

        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not context.Flags.InfiniteJump then return end
            local hum = module.Utility.GetHumanoid(context.LocalPlayer)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)

        module._Internal.AddConnection("InfiniteJump", infiniteJumpConnection)
        module.Utility.Log("InfiniteJump activado.")
    else
        context.Flags.InfiniteJump = false
        module._Internal.Disconnect("InfiniteJump")
        infiniteJumpConnection = nil
        module.Utility.Log("InfiniteJump desactivado.")
    end
end

function module.Movement.WalkSpeed(value)
    local hum = module.Utility.GetHumanoid(context.LocalPlayer)
    if not hum then
        module.Utility.Warn("WalkSpeed: Humanoid no encontrado.")
        return
    end
    local num = tonumber(value)
    if not num then
        hum.WalkSpeed = module.Settings.Movement.DefaultWalkSpeed
        module.Utility.Notify("WalkSpeed", "Valor inválido, usando 16", 2)
        return
    end
    hum.WalkSpeed = math.clamp(num, 4, 200)
end

local noclipLoopRunning=false
function module.Movement.Noclip(disable)
    local char=context.LocalPlayer and context.LocalPlayer.Character
    if not char then
        module.Utility.Warn("Noclip: Character no disponible.")
        return
    end

    if disable then
        context.Flags.Noclip=false; noclipLoopRunning=false
        for part,orig in pairs(noclipCache) do
            if part and part.Parent then part.CanCollide=orig end
        end
        table.clear(noclipCache)
        return
    end

    context.Flags.Noclip=true
    if noclipLoopRunning then return end
    noclipLoopRunning=true

    task.spawn(function()
        while context.Flags.Noclip do
            char=context.LocalPlayer and context.LocalPlayer.Character
            if not char or not char.Parent then break end
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    if noclipCache[part]==nil then noclipCache[part]=part.CanCollide end
                    part.CanCollide=false
                end
            end
            RunService.Heartbeat:Wait()
        end
        pcall(function()
            for part,orig in pairs(noclipCache) do
                if part and part.Parent then part.CanCollide=orig end
            end
            table.clear(noclipCache)
        end)

        table.clear(noclipCache)
        noclipLoopRunning=false
    end)
end

function module.Movement.JumpPower(value, disable)
    local hum = module.Utility.GetHumanoid(context.LocalPlayer)
    local root = context.LocalPlayer and context.LocalPlayer.Character and context.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then
        module.Utility.Warn("JumpPower: Humanoid o Root no disponibles.")
        return
    end

    if disable then
        context.Flags.JumpPower = false
        module._Internal.Disconnect("JumpPower_Input")
        module._Internal.Disconnect("JumpPower_Loop")
        module.Utility.Log("JumpPower desactivado.")
        return
    end

    context.Flags.JumpPower = true
    local strength = tonumber(value) or 100
    strength = math.clamp(strength, 30, 300) -- límites seguros

    -- Cooldown anti‑spam
    local lastJump = 0
    local cooldown = 0.4

    -- Input principal
    local conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not context.Flags.JumpPower then return end
        if input.KeyCode == Enum.KeyCode.Space then
            local now = tick()
            if now - lastJump < cooldown then return end
            lastJump = now

            -- Dirección dinámica: respeta MoveDirection
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                root.Velocity = Vector3.new(dir.X * 0.5, strength, dir.Z * 0.5)
            else
                root.Velocity = Vector3.new(root.Velocity.X, strength, root.Velocity.Z)
            end

            module.Utility.Log("JumpPower ejecutado con fuerza "..tostring(strength))
        end
    end)
    module._Internal.AddConnection("JumpPower_Input", conn)

    -- Loop de seguridad: limpia estado si el humanoid muere o respawnea
    local loop = RunService.Heartbeat:Connect(function()
        if not context.Flags.JumpPower then module._Internal.Disconnect("JumpPower_Loop") return end
        local humCheck = module.Utility.GetHumanoid(context.LocalPlayer)
        if not humCheck or humCheck.Health <= 0 then
            context.Flags.JumpPower = false
            module._Internal.Disconnect("JumpPower_Input")
            module._Internal.Disconnect("JumpPower_Loop")
            module.Utility.Warn("JumpPower desactivado por muerte/respawn.")
        end
    end)
    module._Internal.AddConnection("JumpPower_Loop", loop)
end

---------------------------------------------------------------------
-- Visual
---------------------------------------------------------------------

-- ESP
local function ensureHighlight(player)
    if not player.Character then return end
    local hl = player.Character:FindFirstChild("ESPHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "ESPHighlight"
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0.1
        hl.Parent = player.Character
    end
    local color = module.Utility.GetTeamColor(player)
    if hl.FillColor ~= color then
        hl.FillColor = color
    end
end

function module.Visual.ESP(disable)
    if disable then
        context.Flags.ESPEnabled = false
        module._Internal.Disconnect("ESP_Heartbeat")
        for name,_ in pairs(context.Connections) do
            if string.find(name, "^ESP_CharAdded_") then
                module._Internal.Disconnect(name)
            end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= context.LocalPlayer and p.Character then
                local hl = p.Character:FindFirstChild("ESPHighlight")
                if hl then hl:Destroy() end
            end
        end
        module.Utility.Log("ESP desactivado.")
        return
    end

    if context.Flags.ESPEnabled then return end
    context.Flags.ESPEnabled = true

    local function onCharacterAdded(char)
        if not context.Flags.ESPEnabled then return end
        local player = Players:GetPlayerFromCharacter(char)
        if player and player ~= context.LocalPlayer then
            ensureHighlight(player)
        end
    end

    espConnection = RunService.Heartbeat:Connect(function()
        if not context.Flags.ESPEnabled then return end
        local now = tick()
        if (context._LastESPUpdate or 0) + module.Settings.Visual.ESPUpdateDelay > now then return end
        context._LastESPUpdate = now
        local processed = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= context.LocalPlayer and p.Character then
                ensureHighlight(p)
                processed = processed + 1
                if processed >= module._Internal.AntiLag.MaxPlayersBatch then break end
            end
        end
    end)
    module._Internal.AddConnection("ESP_Heartbeat", espConnection)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= context.LocalPlayer then
            local conn = p.CharacterAdded:Connect(onCharacterAdded)
            module._Internal.AddConnection("ESP_CharAdded_"..p.UserId, conn)
            if p.Character then ensureHighlight(p) end
        end
    end

    module.Utility.Log("ESP activado.")
end

-- XRay con un solo bucle y cache estable
function module.Visual.XRay(value, disable)
    if disable then
        context.Flags.XRayEnabled = false
        for part, data in pairs(xrayCache) do
            if part and part.Parent then
                part.Transparency = data.Transparency
                part.Material = data.Material
                part.Color = data.Color
            end
        end
        table.clear(xrayCache)
        module.Utility.Log("XRay desactivado y restaurado.")
        return
    end

    local transparency = module.Settings.Visual.XRayDefaultTransparency
    local n = tonumber(value)
    if n and n >= 1 and n <= 10 then
        transparency = n / 10
    end

    context.Flags.XRayEnabled = true

    task.spawn(function()
        while context.Flags.XRayEnabled do
            local char = context.LocalPlayer and context.LocalPlayer.Character
            local processed = 0
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart")
                    and part.Transparency < 1
                    and not (char and part:IsDescendantOf(char))
                then
                    local cache = xrayCache[part]
                    if not cache then
                    cache = { 
                        Transparency = part.Transparency, 
                        Material = part.Material, 
                        Color = part.Color, 
                        Reflectance = part.Reflectance, 
                        CastShadow = part.CastShadow 
                    }
                        xrayCache[part] = cache
                    end
                    part.Transparency = transparency
                    if part.Material == Enum.Material.Neon and not cache.NeonAdjusted then
                        part.Color = part.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
                        cache.NeonAdjusted = true
                    end
                    processed = processed + 1
                    if processed >= module._Internal.AntiLag.MaxPartsBatch then break end
                end
            end
            task.wait(module.Settings.Visual.XRayUpdateDelay or 0.6)
        end
    end)

    module.Utility.Log("XRay activado.")
end

---------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------

local killauraEnabled = false
local handleKillEnabled = false
local aimbotEnabled = false

module.Combat.Killaura = function(range, disable)
    local function removeCircle()
        local char = localPlayer.Character
        if char then
            local old = char:FindFirstChild("KillauraCircle")
            if old then old:Destroy() end
        end
    end

    if disable then
        killauraEnabled = false
        context.Flags.Killaura = false
        removeCircle()
        module._Internal.Disconnect("Killaura_Loop")
        return
    end

    local radius = tonumber(range) or 15
    if radius > 50 then radius = 50 end
    killauraEnabled = true
    context.Flags.Killaura = true

    removeCircle()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    -- Esfera visual (client side, no replicada)
    if root then
        local sphere = Instance.new("Part")
        sphere.Name = "KillauraCircle"
        sphere.Shape = Enum.PartType.Ball
        sphere.Anchored = true
        sphere.CanCollide = false
        sphere.Transparency = 0.6
        sphere.Color = Color3.fromHSV(tick() % 1, 1, 1)
        sphere.Size = Vector3.new(radius*2, radius*2, radius*2)
        sphere.Material = Enum.Material.ForceField
        sphere.CastShadow = false
        sphere.CFrame = root.CFrame
        sphere.Parent = char
    end

    -- Loop principal
    module._Internal.AddConnection("Killaura_Loop", RunService.Heartbeat:Connect(function()
        if not killauraEnabled then module._Internal.Disconnect("Killaura_Loop") return end
        local myChar = localPlayer.Character
        local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local tool = myChar and myChar:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChildWhichIsA("BasePart")

        -- Actualizar esfera
        local sphere = myChar and myChar:FindFirstChild("KillauraCircle")
        if sphere and root then
            sphere.Size = Vector3.new(radius*2, radius*2, radius*2)
            sphere.CFrame = root.CFrame
            sphere.Color = Color3.fromHSV(tick() % 1, 1, 1)
        end

        if tool and root then
            local targets = module.Utility.GetNearbyPlayers(radius)
            for _, info in ipairs(targets) do
                local hrp = info.root
                local hum = info.humanoid
                if hrp and hum and (hrp.Position - root.Position).Magnitude <= radius then
                    local success = false

                    -- 1. Intentar activar el Tool
                    success = pcall(function() tool:Activate() end)
                    if success then continue end

                    -- 2. Intentar firetouchinterest con el Handle
                    if handle then
                        success = pcall(function()
                            firetouchinterest(hrp, handle, 0)
                            firetouchinterest(hrp, handle, 1)
                        end)
                        if success then continue end
                    end

                    -- 3. Fallback: daño directo al Humanoid
                    if hum and hum.Health > 0 then
                        success = pcall(function() hum:TakeDamage(10) end)
                        if success then continue end
                    end

                    -- 4. Si algún método falla, se ignora sin romper el loop
                end
            end
        end
    end))
end

module.Combat.HandleKill = function(range, disable)
    if disable then
        handleKillEnabled = false
        context.Flags.HandleKill = false
        module._Internal.Disconnect("HandleKill_Loop")
        return
    end

    local radius = tonumber(range) or 15
    handleKillEnabled = true
    context.Flags.HandleKill = true

    module._Internal.AddConnection("HandleKill_Loop", RunService.Heartbeat:Connect(function()
        if not handleKillEnabled then module._Internal.Disconnect("HandleKill_Loop") return end
        local myChar = localPlayer.Character
        local tool = myChar and myChar:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            local targets = module.Utility.GetNearbyPlayers(radius)
            for _, info in ipairs(targets) do
                pcall(function() tool:Activate() end)
            end
        end
    end))
end

module.Combat.Aimbot = function(range, disable)
    if disable then
        aimbotEnabled = false
        context.Flags.Aimbot = false
        module._Internal.Disconnect("Aimbot_Loop")
        return
    end

    local radius = tonumber(range) or 150
    aimbotEnabled = true
    context.Flags.Aimbot = true

    module._Internal.AddConnection("Aimbot_Loop", RunService.RenderStepped:Connect(function(dt)
        if not aimbotEnabled then module._Internal.Disconnect("Aimbot_Loop") return end
        local camera = context.Camera
        local myChar = localPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myChar and myRoot and camera then
            local nearestRoot
            local nearestDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer and p.Character and not module.Utility.SameTeam(localPlayer, p) then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    local head = p.Character:FindFirstChild("Head")
                    if hum and root and hum.Health > 0 then
                        local d = module.Utility.Dist(myRoot, root)
                        if d < nearestDist and d <= radius then
                            nearestDist = d
                            nearestRoot = head or root
                        end
                    end
                end
            end
            if nearestRoot then
                local camPos = camera.CFrame.Position
                local look = CFrame.new(camPos, nearestRoot.Position)
                local factor = math.clamp(0.15 + (dt or 0)*0.5, 0.15, 0.35)
                camera.CFrame = camera.CFrame:Lerp(look, factor)
            end
        end
    end))
end

---------------------------------------------------------------------
-- Aliases planos
---------------------------------------------------------------------
function module.Fly(arg, disable) return module.Movement.Fly(arg, disable) end
function module.Noclip(disable) return module.Movement.Noclip(disable) end
function module.WalkSpeed(value) return module.Movement.WalkSpeed(value) end
function module.InfiniteJump(enable) return module.Movement.InfiniteJump(enable) end
function module.JumpPower(value, disable) return module.Movement.JumpPower(value, disable) end
function module.ESP(disable) return module.Visual.ESP(disable) end
function module.XRay(value, disable) return module.Visual.XRay(value, disable) end
function module.Killaura(...) if module.Combat.Killaura then return module.Combat.Killaura(...) else module.Utility.Warn("Killaura no implementada") end end
function module.HandleKill(...) if module.Combat.HandleKill then return module.Combat.HandleKill(...) else module.Utility.Warn("HandleKill no implementada") end end
function module.Aimbot(...) if module.Combat.Aimbot then return module.Combat.Aimbot(...) else module.Utility.Warn("Aimbot no implementada") end end

---------------------------------------------------------------------
-- Limpieza total y watchdog
---------------------------------------------------------------------
function module._Internal.CleanupAll()
    -- flags
    for k in pairs(context.Flags) do context.Flags[k] = false end

    -- conexiones
    for name, conn in pairs(context.Connections) do
        pcall(function() conn:Disconnect() end)
        context.Connections[name] = nil
    end

    -- restaura XRay
    for part, data in pairs(xrayCache) do
        if part and part.Parent then
            part.Transparency = data.Transparency
            part.Material = data.Material
            part.Color = data.Color
            part.Reflectance = data.Reflectance
            part.CastShadow = data.CastShadow
        end
    end
    table.clear(xrayCache)

    -- visual Killaura
    if context.Camera then
        local oldUI = context.Camera:FindFirstChild("KillauraCircleGui")
        if oldUI then oldUI:Destroy() end
    end

    -- Humanoid defaults
    local hum = module.Utility.GetHumanoid(context.LocalPlayer)
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.WalkSpeed = module.Settings.Movement.DefaultWalkSpeed
            hum.JumpPower = context._Default.JumpPower
            hum.HipHeight = context._Default.HipHeight
        end)
    end

    -- restaura metatable
    if module._Internal.RestoreMetatable then
        pcall(module._Internal.RestoreMetatable)
    end

    module.Utility.Log("CleanupAll ejecutado.")
end

-- Watchdog de integridad básica
task.spawn(function()
    while true do
        task.wait(5)
        if gv.FloopaHub.ModuleContainer ~= module then
            gv.FloopaHub.ModuleContainer = module
            module.Utility.Warn("Watchdog: módulo restaurado en getgenv.")
        end
    end
end)

gv.FloopaHub.ModuleContainer = module
return module