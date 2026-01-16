-- Loader.lua (corregido)
local G = getgenv()
G.FloopaHub = G.FloopaHub or {}
G.FloopaHub.Version = "4.0"

local H = game:GetService("HttpService")
local P = game:GetService("Players")
local S = game:GetService("StarterGui")
local TS = game:GetService("TweenService")
local L = P.LocalPlayer
local PG = L:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")

local function N(m)
    pcall(function()
        S:SetCore("SendNotification", { Title = "Floopa Hub", Text = m, Duration = 3 })
    end)
end

local function R(o)
    if syn and syn.request then return syn.request(o) end
    if http_request then return http_request(o) end
    if request then return request(o) end
    return nil
end

local function Copy(t)
    local ok = false
    if setclipboard then ok = pcall(function() setclipboard(t) end)
    elseif syn and syn.write_clipboard then ok = pcall(function() syn.write_clipboard(t) end)
    end
    if ok then N("Copied to clipboard.") else N("Copy manually: " .. t) end
    return ok
end

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting
TS:Create(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 12 }):Play()

local UI = Instance.new("ScreenGui")
UI.Name = "FHLoader"
UI.ResetOnSpawn = false
UI.Parent = PG

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 400, 0, 270)
Main.Position = UDim2.new(0.5, -200, 0.5, -135)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = UI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 1.2
Stroke.Color = Color3.fromRGB(60, 120, 255)
Stroke.Transparency = 0.4

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 42)
Top.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Top.BorderSizePixel = 0
Top.Parent = Main
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Text = "Floopa Hub • Key System"
Title.TextColor3 = Color3.fromRGB(235, 240, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.BackgroundTransparency = 1
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 40, 1, 0)
Close.Position = UDim2.new(1, -40, 0, 0)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 90, 110)
Close.Font = Enum.Font.GothamBold
Close.TextScaled = true
Close.BackgroundTransparency = 1
Close.Parent = Top

local Glow = Instance.new("ImageLabel")
Glow.Size = UDim2.new(1.4, 0, 0, 80)
Glow.Position = UDim2.new(-0.2, 0, 0, 38)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Color3.fromRGB(60, 120, 255)
Glow.ImageTransparency = 0.4
Glow.Parent = Main

local Box = Instance.new("TextBox")
Box.Size = UDim2.new(1, -30, 0, 46)
Box.Position = UDim2.new(0, 15, 0, 70)
Box.PlaceholderText = "Enter your key"
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(230, 230, 240)
Box.Font = Enum.Font.Gotham
Box.TextSize = 16
Box.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Box.BorderSizePixel = 0
Box.ClearTextOnFocus = false
Box.Parent = Main
Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 10)

local BoxStroke = Instance.new("UIStroke", Box)
BoxStroke.Thickness = 1
BoxStroke.Color = Color3.fromRGB(80, 90, 120)
BoxStroke.Transparency = 0.3

local GetKey = Instance.new("TextButton")
GetKey.Size = UDim2.new(0.5, -20, 0, 44)
GetKey.Position = UDim2.new(0, 15, 0, 135)
GetKey.Text = "Get Key"
GetKey.TextColor3 = Color3.fromRGB(240, 240, 255)
GetKey.Font = Enum.Font.GothamBold
GetKey.TextSize = 16
GetKey.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
GetKey.BorderSizePixel = 0
GetKey.Parent = Main
Instance.new("UICorner", GetKey).CornerRadius = UDim.new(0, 10)

local Validate = Instance.new("TextButton")
Validate.Size = UDim2.new(0.5, -20, 0, 44)
Validate.Position = UDim2.new(0.5, 5, 0, 135)
Validate.Text = "Validate Key"
Validate.TextColor3 = Color3.fromRGB(245, 245, 255)
Validate.Font = Enum.Font.GothamBold
Validate.TextSize = 16
Validate.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
Validate.BorderSizePixel = 0
Validate.Parent = Main
Instance.new("UICorner", Validate).CornerRadius = UDim.new(0, 10)

local Discord = Instance.new("TextButton")
Discord.Size = UDim2.new(1, -30, 0, 36)
Discord.Position = UDim2.new(0, 15, 0, 190)
Discord.Text = "Discord Support"
Discord.TextColor3 = Color3.fromRGB(220, 225, 255)
Discord.Font = Enum.Font.GothamBold
Discord.TextSize = 15
Discord.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
Discord.BorderSizePixel = 0
Discord.Parent = Main
Instance.new("UICorner", Discord).CornerRadius = UDim.new(0, 10)

local function Hover(btn, base, hover)
    btn.MouseEnter:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = hover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = base }):Play()
    end)
end

Hover(GetKey, Color3.fromRGB(26, 26, 40), Color3.fromRGB(40, 40, 60))
Hover(Validate, Color3.fromRGB(40, 120, 255), Color3.fromRGB(60, 140, 255))
Hover(Discord, Color3.fromRGB(20, 20, 32), Color3.fromRGB(30, 30, 45))

local dragging, dragStart, startPos
Top.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = Main.Position
    end
end)
Top.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Main.Size = UDim2.new(0, 0, 0, 0)
TS:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 400, 0, 270) }):Play()

local closing = false
local function CloseUI()
    if closing then return end
    closing = true
    TS:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) }):Play()
    TS:Create(blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = 0 }):Play()
    task.delay(0.22, function()
        blur:Destroy()
        UI:Destroy()
    end)
end

Close.MouseButton1Click:Connect(CloseUI)

GetKey.MouseButton1Click:Connect(function()
    if Copy("https://floopahub.pages.dev/") then
        N("Link copied.")
    end
end)

Discord.MouseButton1Click:Connect(function()
    if Copy("https://discord.gg/SmRdT9TM") then
        N("Discord link copied.")
    end
end)

Validate.MouseButton1Click:Connect(function()
    local key = Box.Text
    if key == "" then return N("Enter a key.") end

    local u = H:UrlEncode(L.Name)

    -- Validate using GET (server expects GET in current deploy)
    local v = R({
        Url = "https://scripts-m6a8.onrender.com/auth/validate?key=" .. key .. "&user=" .. u
    })

    if not v or not v.Body then return N("Connection error.") end

    local ok, data = pcall(function() return H:JSONDecode(v.Body) end)
    if not ok or not data or not data.data or not data.data.ok then
        return N("Invalid key.")
    end

    local token = tostring(data.data.token or "")
    token = token:gsub('^"', ''):gsub('"$', '') -- si quieres, incluso esto puedes quitarlo

    local ex = R({
        Url = "https://scripts-m6a8.onrender.com/exploit/get?name=Main&token=" .. token,
        Method = "GET"
    })


    if ex and (ex.StatusCode == 200 or ex.status == 200) and type(ex.Body) == "string" and #ex.Body > 0 then
        local ok2, fn = pcall(loadstring, ex.Body)
        if ok2 and type(fn) == "function" then
            fn()
            N("Key valid. Hub loaded.")
            CloseUI()
        else
            N("Execution error.")
        end
    else
        N("Exploit fetch error.")
    end
end)
