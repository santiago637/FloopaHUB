-- Floopa Hub Pro - Hub mejorado sin integrar módulos internos
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- Estado global y protección contra re-ejecución
local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}
if gv.FloopaHub.HubButtonLoaded then
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Floopa Hub", Text="HubButton ya estaba cargado", Duration=3})
    end)
    return
end
gv.FloopaHub.HubButtonLoaded = true
gv.FloopaHub.Version = "2.3"

local function notifySafe(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title or "Info", Text=text or "", Duration=duration or 3})
    end)
end

-- Espera juego (Delta-friendly)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Detección móvil robusta
local function detectMobile()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then return true end
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.X < 900 then return true end
    return UserInputService.TouchEnabled
end
local isMobile = detectMobile()

-- ScreenGui singleton
local gui = playerGui:FindFirstChild("FloopaHubGUI")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "FloopaHubGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = playerGui
end

-- Carga externa robusta
local function safeHttpGet(url)
    -- Intento directo
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 then return res end

    -- Adaptadores comunes
    local function tryReq(fn)
        local ok2, r = pcall(fn, {Url = url, Method = "GET"})
        if ok2 and r then
            local body = r.Body or r.body
            if type(body) == "string" and #body > 0 then return body end
        end
    end

    if syn and syn.request then
        local body = tryReq(syn.request)
        if body then return body end
    end
    if http_request then
        local body = tryReq(http_request)
        if body then return body end
    end
    if request then
        local body = tryReq(request)
        if body then return body end
    end
    return nil
end

local function safeLoad(url)
    local res = safeHttpGet(url)
    if type(res) ~= "string" or #res < 50 then
        notifySafe("Floopa Hub", "No se pudo cargar: "..url, 3)
        return function() end
    end
    local okFn, fn = pcall(loadstring, res)
    if not okFn or type(fn) ~= "function" then
        notifySafe("Floopa Hub", "Código inválido: "..url, 3)
        return function() end
    end
    return function()
        local okRun, err = pcall(fn)
        if not okRun then
            notifySafe("Floopa Hub", "Error al ejecutar: "..tostring(err), 3)
        end
    end
end

-- Botón de apertura con debounce
local openButton = gui:FindFirstChild("HubButton") or Instance.new("TextButton")
openButton.Name = "HubButton"
openButton.Size = isMobile and UDim2.new(0,120,0,50) or UDim2.new(0,100,0,40)
openButton.Position = isMobile and UDim2.new(1,-130,0,10) or UDim2.new(1,-110,0,10)
openButton.AnchorPoint = Vector2.new(1,0)
openButton.BackgroundColor3 = Color3.fromRGB(35,35,45)
openButton.Text = "Hub"
openButton.TextColor3 = Color3.fromRGB(255,255,255)
openButton.Font = Enum.Font.GothamBold
openButton.TextScaled = true
openButton.Parent = gui
if not openButton:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", openButton).CornerRadius = UDim.new(0,12)
end

-- Menú principal
local menuFrame = gui:FindFirstChild("MainMenu") or Instance.new("Frame")
menuFrame.Name = "MainMenu"
menuFrame.Size = isMobile and UDim2.new(0,420,0,420) or UDim2.new(0,380,0,380)
menuFrame.Position = UDim2.new(0.5,0,0.5,0)
menuFrame.AnchorPoint = Vector2.new(0.5,0.5)
menuFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
menuFrame.Visible = false
menuFrame.Parent = gui
if not menuFrame:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0,14)
end
if not menuFrame:FindFirstChildOfClass("UIStroke") then
    local stroke = Instance.new("UIStroke", menuFrame)
    stroke.Color = Color3.fromRGB(60,60,90)
    stroke.Thickness = 1
end

-- Header
local header = menuFrame:FindFirstChild("Header") or Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1,0,0,50)
header.BackgroundColor3 = Color3.fromRGB(0,90,180)
header.Parent = menuFrame
if not header:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)
end
if not header:FindFirstChildOfClass("UIStroke") then
    local hStroke = Instance.new("UIStroke", header)
    hStroke.Color = Color3.fromRGB(40,120,220)
    hStroke.Thickness = 1
end

local logo = header:FindFirstChild("Logo") or Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0,36,0,36)
logo.Position = UDim2.new(0,10,0.5,-18)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://117990734815106"
logo.Parent = header

local title = header:FindFirstChild("Title") or Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1,-60,1,0)
title.Position = UDim2.new(0,50,0,0)
title.BackgroundTransparency = 1
title.Text = "Floopa Hub • "..gv.FloopaHub.Version
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Sidebar singleton
local sidebar = menuFrame:FindFirstChild("Sidebar")
if not sidebar then
    sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0,100,1,-50)
    sidebar.Position = UDim2.new(0,0,0,50)
    sidebar.BackgroundColor3 = Color3.fromRGB(30,30,45)
    sidebar.Parent = menuFrame
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,12)
    local sStroke = Instance.new("UIStroke", sidebar)
    sStroke.Color = Color3.fromRGB(55,55,80)
    sStroke.Thickness = 1
end

-- Secciones
local sections = {}
local function createSection(name)
    local f = menuFrame:FindFirstChild(name) or Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(1,-100,1,-50)
    f.Position = UDim2.new(0,100,0,50)
    f.BackgroundColor3 = Color3.fromRGB(25,25,35)
    f.Visible = false
    f.Parent = menuFrame
    if not f:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)
    end
    if not f:FindFirstChildOfClass("UIStroke") then
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = Color3.fromRGB(55,55,85)
        stroke.Thickness = 1
    end
    sections[name] = f
    return f
end

local tpPanelSection = createSection("TPPanel")
local executorSection = createSection("Executor")
local settingsSection = createSection("Settings")

-- Navegación
local function createNavButton(text, sectionName, posY)
    local b = sidebar:FindFirstChild(sectionName.."_Nav") or Instance.new("TextButton")
    b.Name = sectionName.."_Nav"
    b.Size = UDim2.new(1,0,0,40)
    b.Position = UDim2.new(0,0,0,posY)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(45,45,65)
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Parent = sidebar
    if not b:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    end
    if not b:FindFirstChildOfClass("UIStroke") then
        local stroke = Instance.new("UIStroke", b)
        stroke.Color = Color3.fromRGB(70,70,95)
        stroke.Thickness = 1
    end
    b.MouseButton1Click:Connect(function()
        for _,sec in pairs(sections) do sec.Visible = false end
        sections[sectionName].Visible = true
        gv.FloopaHub.LastSection = sectionName
    end)
end

createNavButton("TP Panel","TPPanel",20)
createNavButton("Executor","Executor",70)
createNavButton("Settings","Settings",120)

-- Toggle/carga externa con persistencia real
-- Convención: los scripts externos deben crear/registrar sus frames en gv.FloopaHub[frameKey]
-- Ejemplo dentro del módulo externo:
--    local f = Instance.new("Frame", playerGui:FindFirstChild("FloopaHubGUI"))
--    getgenv().FloopaHub.TPPanelFrame = f
local function toggleOrLoad(frameKey, url)
    local guiRef = playerGui:FindFirstChild("FloopaHubGUI")
    local frame = gv.FloopaHub[frameKey]
    if frame and frame.Parent == guiRef then
        frame.Visible = not frame.Visible
        gv.FloopaHub[frameKey.."Visible"] = frame.Visible
        return
    end
    -- Si no existe, cargar externo
    local run = safeLoad(url)
    run()
    -- Intentar recuperar el frame que el módulo debió registrar
    frame = gv.FloopaHub[frameKey]
    if frame and frame.Parent == guiRef then
        frame.Visible = true
        gv.FloopaHub[frameKey.."Visible"] = true
    else
        notifySafe("Floopa Hub", "No se encontró el frame: "..frameKey, 2)
    end
end

-- Botones internos (uniforme con UIStroke)
local function ensureSectionButton(section, name, text, callback)
    local b = section:FindFirstChild(name) or Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0,220,0,44)
    b.Position = UDim2.new(0,20,0,20)
    b.BackgroundColor3 = Color3.fromRGB(35,35,55)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Parent = section
    if not b:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    end
    if not b:FindFirstChildOfClass("UIStroke") then
        local stroke = Instance.new("UIStroke", b)
        stroke.Color = Color3.fromRGB(70,70,95)
        stroke.Thickness = 1
    end
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then notifySafe("Floopa Hub", "Error: "..tostring(err), 3) end
    end)
end

ensureSectionButton(tpPanelSection, "OpenTPPanelBtn", "Abrir/Toggle TP Panel", function()
    toggleOrLoad("TPPanelFrame", "https://raw.githubusercontent.com/santiago637/Scripts/main/TPPanel.lua")
end)

ensureSectionButton(executorSection, "OpenExecutorBtn", "Abrir/Toggle Executor", function()
    toggleOrLoad("ExecutorFrame", "https://raw.githubusercontent.com/santiago637/Scripts/main/CommandsExecutor.lua")
end)

ensureSectionButton(settingsSection, "OpenSettingsBtn", "Abrir/Toggle Settings", function()
    toggleOrLoad("SettingsFrame", "https://raw.githubusercontent.com/santiago637/Scripts/main/Settings.lua")
end)

-- Apertura/cierre con animación y persistencia real
local lastClick = 0
local openSize = isMobile and UDim2.new(0,420,0,420) or UDim2.new(0,380,0,380)

local function openMenu()
    menuFrame.Visible = true
    menuFrame.Size = UDim2.new(0,0,0,0)
    TweenService:Create(menuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = openSize}):Play()
    local last = gv.FloopaHub.LastSection
    for _,sec in pairs(sections) do sec.Visible = false end
    if last and sections[last] then
        sections[last].Visible = true
    else
        sections.Executor.Visible = true
        gv.FloopaHub.LastSection = "Executor"
    end
end

local function closeMenu()
    local tween = TweenService:Create(menuFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0,0,0,0)})
    tween:Play()
    tween.Completed:Connect(function()
        menuFrame.Visible = false
        -- No limpiar LastSection; mantener persistencia real
    end)
end

openButton.MouseButton1Click:Connect(function()
    local now = tick()
    if now - lastClick < 0.25 then return end
    lastClick = now
    if not menuFrame.Visible then openMenu() else closeMenu() end
end)

-- Protección ante respawn (restaura GUI, botón, menú y sección activa)
localPlayer.CharacterAdded:Connect(function()
    task.delay(0.5, function()
        if not playerGui:FindFirstChild("FloopaHubGUI") then gui.Parent = playerGui end
        if not gui:FindFirstChild("HubButton") then openButton.Parent = gui end
        if not gui:FindFirstChild("MainMenu") then menuFrame.Parent = gui end
        -- Restaurar sección activa si el menú está visible
        if menuFrame.Visible then
            for _,sec in pairs(sections) do sec.Visible = false end
            local last = gv.FloopaHub.LastSection
            if last and sections[last] then
                sections[last].Visible = true
            else
                sections.Executor.Visible = true
                gv.FloopaHub.LastSection = "Executor"
            end
        end
        -- Restaurar visibilidad de frames externos si estaban activos
        local guiRef = playerGui:FindFirstChild("FloopaHubGUI")
        local keys = {"TPPanelFrame","ExecutorFrame","SettingsFrame"}
        for _,k in ipairs(keys) do
            local fr = gv.FloopaHub[k]
            local vis = gv.FloopaHub[k.."Visible"]
            if fr and guiRef and fr.Parent ~= guiRef then
                -- Si el módulo los parentó fuera, reparentar al gui
                fr.Parent = guiRef
            end
            if fr then
                fr.Visible = not not vis
            end
        end
    end)
end)

notifySafe("Floopa Hub", "HubButton cargado (v"..gv.FloopaHub.Version..")", 2)