-- Floopa Hub - CommandsExecutor (GUI compacta inferior derecha)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

-- Estado global y protección contra re-ejecución
local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}
if gv.FloopaHub.CommandsExecutorLoaded then
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Floopa Hub", Text="CommandsExecutor ya cargado", Duration=3})
    end)
    return
end
gv.FloopaHub.CommandsExecutorLoaded = true

local function notifySafe(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title or "Info", Text=text or "", Duration=duration or 3})
    end)
end

-- Red robusta con fallbacks
local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 then return res end

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
    if type(res) ~= "string" or #res == 0 then
        notifySafe("Floopa Hub", "No se pudo cargar: "..url, 3)
        return { ExecuteCommand = function() return false end }
    end
    local fOk, fn = pcall(loadstring, res)
    if not fOk or type(fn) ~= "function" then
        notifySafe("Floopa Hub", "Código inválido: "..url, 3)
        return { ExecuteCommand = function() return false end }
    end
    local ok, mod = pcall(fn)
    if not ok or type(mod) ~= "table" or type(mod.ExecuteCommand) ~= "function" then
        notifySafe("Floopa Hub", "Módulo sin ExecuteCommand válido", 3)
        return { ExecuteCommand = function() return false end }
    end
    return mod
end

-- Carga del módulo principal de comandos (dispatcher)
local Main = safeLoad("https://raw.githubusercontent.com/santiago637/Scripts/main/MainLocalScript.lua")

-- Contexto GUI
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ScreenGui singleton
local gui = playerGui:FindFirstChild("FloopaHubGUI")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "FloopaHubGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = playerGui
end

-- Frame principal
local frame = gui:FindFirstChild("MainFrame") or Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = isMobile and UDim2.new(0,300,0,360) or UDim2.new(0,280,0,320)
frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = gui
if not frame:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)
end
if not frame:FindFirstChildOfClass("UIStroke") then
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(60,60,90)
    stroke.Thickness = 1
end

-- Registrar en getgenv para toggle desde el Hub
gv.FloopaHub.ExecutorFrame = frame
gv.FloopaHub.ExecutorVisible = true

-- Posicionar en esquina inferior derecha
local function placeBottomRight(margin)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vs = cam.ViewportSize
    local fs = frame.AbsoluteSize
    frame.Position = UDim2.fromOffset(vs.X - fs.X - margin, vs.Y - fs.Y - margin)
end
placeBottomRight(10)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if frame.Visible then placeBottomRight(10) end
end)

-- Header
local header = frame:FindFirstChild("Header") or Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1,0,0,45)
header.BackgroundColor3 = Color3.fromRGB(0,90,180)
header.Parent = frame
if not header:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)
end
if not header:FindFirstChildOfClass("UIStroke") then
    local stroke = Instance.new("UIStroke", header)
    stroke.Color = Color3.fromRGB(40,120,220)
    stroke.Thickness = 1
end

local logo = header:FindFirstChild("LogoImage") or Instance.new("ImageLabel")
logo.Name = "LogoImage"
logo.Size = UDim2.new(0,32,0,32)
logo.Position = UDim2.new(0,8,0.5,-16)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://117990734815106"
logo.Parent = header

local title = header:FindFirstChild("TitleLabel") or Instance.new("TextLabel")
title.Name = "TitleLabel"
title.Size = UDim2.new(1,-90,1,0)
title.Position = UDim2.new(0,45,0,0)
title.BackgroundTransparency = 1
title.Text = "Floopa Hub • CommandsExecutor"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Botón cerrar
local closeBtn = header:FindFirstChild("CloseButton") or Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0.5,-15)
closeBtn.BackgroundColor3 = Color3.fromRGB(35,35,55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.Parent = header
if not closeBtn:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
end

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55,55,75)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35,35,55)}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    gv.FloopaHub.ExecutorVisible = false
    notifySafe("Floopa Hub","CommandsExecutor oculto",2)
end)

-- Notificaciones locales con limitador
local activeNotifs = 0
local function showNotification(msg)
    if activeNotifs >= 3 then return end
    activeNotifs += 1
    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Size = UDim2.new(0,260,0,50)
    notif.Position = UDim2.new(1,-270,1,-120)
    notif.BackgroundColor3 = Color3.fromRGB(30,30,50)
    notif.BackgroundTransparency = 1
    notif.Parent = gui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", notif)
    stroke.Color = Color3.fromRGB(70,70,100)
    stroke.Thickness = 1

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,-30,1,0)
    txt.Position = UDim2.new(0,10,0,0)
    txt.BackgroundTransparency = 1
    txt.Text = tostring(msg)
    txt.TextColor3 = Color3.fromRGB(255,255,255)
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    task.delay(3, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.wait(0.45)
            if notif and notif.Parent then notif:Destroy() end
        end
        activeNotifs -= 1
    end)
end

-- TextBox de comandos con foco animado
local commandBox = frame:FindFirstChild("CommandBox") or Instance.new("TextBox")
commandBox.Name = "CommandBox"
commandBox.Size = UDim2.new(1,-20,0,40)
commandBox.Position = UDim2.new(0,10,0,55)
commandBox.BackgroundColor3 = Color3.fromRGB(25,25,40)
commandBox.Text = ""
commandBox.PlaceholderText = "Pon tu comando aquí"
commandBox.TextColor3 = Color3.fromRGB(180,180,200)
commandBox.PlaceholderColor3 = Color3.fromRGB(140,140,170)
commandBox.Font = Enum.Font.Gotham
commandBox.TextScaled = true
commandBox.ClearTextOnFocus = true
commandBox.Parent = frame
if not commandBox:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", commandBox).CornerRadius = UDim.new(0,10)
end
if not commandBox:FindFirstChildOfClass("UIStroke") then
    local stroke = Instance.new("UIStroke", commandBox)
    stroke.Color = Color3.fromRGB(70,70,90)
    stroke.Thickness = 1
end

commandBox.Focused:Connect(function()
    TweenService:Create(commandBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,40,60)}):Play()
end)
commandBox.FocusLost:Connect(function()
    TweenService:Create(commandBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25,25,40)}):Play()
end)

-- Lista de comandos mostrados
local commandsInfo = {
    fly = "Permite volar.",
    unfly = "Desactiva el vuelo.",
    noclip = "Atravesar paredes.",
    unnoclip = "Desactiva noclip.",
    walkspeed = "Cambia velocidad.",
    unwalkspeed = "Velocidad normal.",
    jumppower = "Cambia potencia de salto",
    unjumppower = "Potencia de salto normal",
    esp = "Resalta jugadores.",
    unesp = "Desactiva ESP.",
    xray = "Transparencia paredes.",
    unxray = "Desactiva XRay.",
    infinitejump = "Salto infinito.",
    uninfinitejump = "Desactiva salto infinito.",
    killaura = "Ataca automáticamente.",
    unkillaura = "Desactiva Killaura.",
    handlekill = "Ataca con arma.",
    unhandlekill = "Desactiva HandleKill.",
    aimbot = "Apunta automático.",
    unaimbot = "Desactiva Aimbot.",
}

-- ScrollingFrame con UIListLayout
local scrollFrame = frame:FindFirstChild("CommandsScroll") or Instance.new("ScrollingFrame")
scrollFrame.Name = "CommandsScroll"
scrollFrame.Size = UDim2.new(1,-20,1,-110)
scrollFrame.Position = UDim2.new(0,10,0,100)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
scrollFrame.ScrollBarThickness = isMobile and 12 or 8
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.Parent = frame
if not scrollFrame:FindFirstChildOfClass("UICorner") then
    Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0,10)
end
if not scrollFrame:FindFirstChildOfClass("UIStroke") then
    local stroke = Instance.new("UIStroke", scrollFrame)
    stroke.Color = Color3.fromRGB(60,60,90)
    stroke.Thickness = 1
end

local layout = scrollFrame:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", scrollFrame)
layout.Padding = UDim.new(0,6)

-- Crear botones ordenados alfabéticamente
local keys = {}
for cmd,_ in pairs(commandsInfo) do table.insert(keys, cmd) end
table.sort(keys)

for _,cmd in ipairs(keys) do
    local b = scrollFrame:FindFirstChild(cmd.."Button") or Instance.new("TextButton")
    b.Name = cmd.."Button"
    b.Size = UDim2.new(1,0,0,32)
    b.BackgroundColor3 = Color3.fromRGB(35,35,55)
    b.Text = cmd
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Parent = scrollFrame
    if not b:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    end
    if not b:FindFirstChildOfClass("UIStroke") then
        local stroke = Instance.new("UIStroke", b)
        stroke.Color = Color3.fromRGB(70,70,95)
        stroke.Thickness = 1
    end

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55,55,85)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35,35,55)}):Play()
    end)

    b.MouseButton1Click:Connect(function()
        local ok = false
        if Main and type(Main.ExecuteCommand) == "function" then
            local success, res = pcall(Main.ExecuteCommand, cmd)
            ok = success and (res == true or res == nil)
        end
        if ok then
            showNotification("Comando ejecutado: "..cmd)
        else
            showNotification("Error al ejecutar: "..cmd)
        end
    end)
end

-- Comandos manuales (Enter para ejecutar)
commandBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and commandBox.Text ~= "" then
        local text = commandBox.Text
        local ok = false
        if Main and type(Main.ExecuteCommand) == "function" then
            local success, res = pcall(Main.ExecuteCommand, text)
            ok = success and (res == true or res == nil)
        end
        if ok then
            showNotification("Comando ejecutado: "..text)
        else
            showNotification("Error al ejecutar: "..text)
        end
        commandBox.Text = ""
    end
end)

-- Arrastre del frame (PC y móvil) con suavizado al soltar
local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = frame.AbsolutePosition
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = frame.Position}):Play()
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - dragStart
        local newX = startPos.X + delta.X
        local newY = startPos.Y + delta.Y

        local vs = workspace.CurrentCamera.ViewportSize
        local fs = frame.AbsoluteSize
        local margin = 20

        newX = math.clamp(newX, margin, vs.X - fs.X - margin)
        newY = math.clamp(newY, margin, vs.Y - fs.Y - margin)

        frame.Position = UDim2.fromOffset(newX, newY)
    end
end)

notifySafe("Floopa Hub", "CommandsExecutor listo", 2)