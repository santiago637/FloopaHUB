-- Floopa Hub Loader (v3.5)
local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}
gv.FloopaHub.Version = "3.5"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Notificación segura
local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Floopa Hub", Text=msg, Duration=3})
    end)
end

-- GUI principal
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "FloopaHubLoader"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 220)
frame.Position = UDim2.new(0.5, -170, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.Text = "Floopa Hub • Key System"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.BackgroundTransparency = 1

-- Caja de texto para key
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-20,0,40)
box.Position = UDim2.new(0,10,0,60)
box.PlaceholderText = "Introduce tu key aquí"
box.TextColor3 = Color3.fromRGB(200,200,200)
box.BackgroundColor3 = Color3.fromRGB(35,35,55)
Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)

-- Botón obtener key
local btnGetKey = Instance.new("TextButton", frame)
btnGetKey.Size = UDim2.new(0.5,-15,0,40)
btnGetKey.Position = UDim2.new(0,10,0,120)
btnGetKey.Text = "Obtener Key"
btnGetKey.BackgroundColor3 = Color3.fromRGB(45,45,65)
btnGetKey.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", btnGetKey).CornerRadius = UDim.new(0,8)

-- Botón validar key
local btnSubmit = Instance.new("TextButton", frame)
btnSubmit.Size = UDim2.new(0.5,-15,0,40)
btnSubmit.Position = UDim2.new(0.5,5,0,120)
btnSubmit.Text = "Validar Key"
btnSubmit.BackgroundColor3 = Color3.fromRGB(0,120,200)
btnSubmit.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", btnSubmit).CornerRadius = UDim.new(0,8)

-- Botón soporte
local btnSupport = Instance.new("TextButton", frame)
btnSupport.Size = UDim2.new(1,-20,0,30)
btnSupport.Position = UDim2.new(0,10,0,170)
btnSupport.Text = "Soporte Discord"
btnSupport.BackgroundColor3 = Color3.fromRGB(35,35,55)
btnSupport.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", btnSupport).CornerRadius = UDim.new(0,8)

-- Eventos
btnGetKey.MouseButton1Click:Connect(function()
    setclipboard("https://loot-link.com/s?bwxRK29Q") -- tu página oficial con LootLabs
    notify("Link copiado. Ábrelo en tu navegador para obtener la key.")
end)

btnSupport.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/SmRdT9TM") -- tu Discord oficial
    notify("Link de soporte copiado. Únete a nuestro Discord.")
end)

btnSubmit.MouseButton1Click:Connect(function()
    local key = box.Text
    if key == "" then return notify("Introduce una key primero.") end

    -- Paso 1: Validar key o usuario VIP
    local validate = syn.request({
        Url = "https://scripts-m6a8.onrender.com/auth/validate",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({ key = key, user = player.Name })
    })

    local data = HttpService:JSONDecode(validate.Body)
    if not data.success then
        return notify("Key inválida o acceso denegado.")
    end

    -- Paso 2: Obtener exploit con token
    local exploitRes = syn.request({
        Url = "https://scripts-m6a8.onrender.com/exploit/get",
        Method = "GET",
        Headers = {["Authorization"] = "Bearer " .. data.token}
    })

    if exploitRes.StatusCode == 200 then
        local ok, fn = pcall(loadstring, exploitRes.Body)
        if ok and type(fn) == "function" then
            fn()
            notify("Key válida. HUB cargado.")
            gui:Destroy()
        else
            notify("Error al ejecutar exploit.")
        end
    else
        notify("Error al obtener exploit.")
    end
end)
