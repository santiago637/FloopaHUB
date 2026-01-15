-- Floopa Hub Loader (v3.5 Obfuscated Extended, fixed clipboard flow)
local G=getgenv()
G.FloopaHub=G.FloopaHub or {}
G.FloopaHub.Version="3.5"

local H=game:GetService("HttpService")
local P=game:GetService("Players")
local S=game:GetService("StarterGui")
local L=P.LocalPlayer
local PG=L:WaitForChild("PlayerGui")

-- Notificación segura
local function N(msg)
    pcall(function()
        S:SetCore("SendNotification",{Title="Floopa Hub",Text=msg,Duration=3})
    end)
end

-- Request universal (Synapse, Delta, Fluxus)
local function R(opt)
    if syn and syn.request then return syn.request(opt) end
    if http_request then return http_request(opt) end
    if request then return request(opt) end
    return nil
end

-- Copiado universal al portapapeles
local function Copy(text)
    local ok=false
    if setclipboard then
        local sOk=pcall(function() setclipboard(text) end)
        ok = sOk and true or false
    elseif syn and syn.write_clipboard then
        local sOk=pcall(function() syn.write_clipboard(text) end)
        ok = sOk and true or false
    end
    if ok then
        N("Copiado al portapapeles.")
    else
        N("No se pudo copiar automáticamente. Copia manualmente: "..tostring(text))
    end
    return ok
end

-- GUI principal
local G0=Instance.new("ScreenGui",PG)
G0.Name="FHLoader"
local F0=Instance.new("Frame",G0)
F0.Size=UDim2.new(0,360,0,240)
F0.Position=UDim2.new(0.5,-180,0.5,-120)
F0.BackgroundColor3=Color3.fromRGB(20,20,30)
Instance.new("UICorner",F0).CornerRadius=UDim.new(0,12)

-- Título
local T0=Instance.new("TextLabel",F0)
T0.Size=UDim2.new(1,0,0,40)
T0.Text="Floopa Hub • Key System"
T0.TextColor3=Color3.fromRGB(255,255,255)
T0.Font=Enum.Font.GothamBold
T0.TextScaled=true
T0.BackgroundTransparency=1

-- Caja de texto
local B0=Instance.new("TextBox",F0)
B0.Size=UDim2.new(1,-20,0,40)
B0.Position=UDim2.new(0,10,0,60)
B0.PlaceholderText="Introduce tu key aquí"
B0.TextColor3=Color3.fromRGB(200,200,200)
B0.BackgroundColor3=Color3.fromRGB(35,35,55)
B0.ClearTextOnFocus=false
Instance.new("UICorner",B0).CornerRadius=UDim.new(0,8)

-- Botones
local K0=Instance.new("TextButton",F0)
K0.Size=UDim2.new(0.5,-15,0,40)
K0.Position=UDim2.new(0,10,0,120)
K0.Text="Obtener Key"
K0.BackgroundColor3=Color3.fromRGB(45,45,65)
K0.TextColor3=Color3.fromRGB(255,255,255)
Instance.new("UICorner",K0).CornerRadius=UDim.new(0,8)

local V0=Instance.new("TextButton",F0)
V0.Size=UDim2.new(0.5,-15,0,40)
V0.Position=UDim2.new(0.5,5,0,120)
V0.Text="Validar Key"
V0.BackgroundColor3=Color3.fromRGB(0,120,200)
V0.TextColor3=Color3.fromRGB(255,255,255)
Instance.new("UICorner",V0).CornerRadius=UDim.new(0,8)

local D0=Instance.new("TextButton",F0)
D0.Size=UDim2.new(1,-20,0,30)
D0.Position=UDim2.new(0,10,0,170)
D0.Text="Soporte Discord"
D0.BackgroundColor3=Color3.fromRGB(35,35,55)
D0.TextColor3=Color3.fromRGB(255,255,255)
Instance.new("UICorner",D0).CornerRadius=UDim.new(0,8)

-- Eventos: flujo de portapapeles y validación
K0.MouseButton1Click:Connect(function()
    local ok=Copy("https://loot-link.com/s?bwxRK29Q")
    if ok then
        N("Link copiado. Ábrelo en tu navegador para obtener la key.")
    end
end)

D0.MouseButton1Click:Connect(function()
    local ok=Copy("https://discord.gg/SmRdT9TM")
    if ok then
        N("Link de soporte copiado. Únete a nuestro Discord.")
    end
end)

V0.MouseButton1Click:Connect(function()
    local key=B0.Text
    if key=="" then return N("Introduce una key primero.") end

    -- Validación
    local validate=R({
        Url="https://scripts-m6a8.onrender.com/auth/validate",
        Method="POST",
        Headers={["Content-Type"]="application/json"},
        Body=H:JSONEncode({key=key,user=L.Name})
    })
    if not validate or not validate.Body then return N("Error de conexión.") end

    local ok,data=pcall(function()return H:JSONDecode(validate.Body)end)
    if not ok or not data or not data.success then
        return N("Key inválida o acceso denegado.")
    end

    -- Obtener exploit
    local exploitRes=R({
        Url="https://scripts-m6a8.onrender.com/src/exploit/get",
        Method="GET",
        Headers={["Authorization"]="Bearer "..tostring(data.token)}
    })
    if exploitRes and exploitRes.StatusCode==200 and type(exploitRes.Body)=="string" and #exploitRes.Body>0 then
        local ok2,fn=pcall(loadstring,exploitRes.Body)
        if ok2 and type(fn)=="function" then
            fn()
            N("Key válida. HUB cargado.")
            G0:Destroy() -- oculta Loader y deja el HUB activo
        else
            N("Error al ejecutar exploit.")
        end
    else
        N("Error al obtener exploit.")
    end
end)
