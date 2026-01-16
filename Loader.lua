local G=getgenv()
G.FloopaHub=G.FloopaHub or{}
G.FloopaHub.Version="3.7"

local H=game:GetService("HttpService")
local P=game:GetService("Players")
local S=game:GetService("StarterGui")
local L=P.LocalPlayer
local PG=L:WaitForChild("PlayerGui")

local function N(m)
    pcall(function()
        S:SetCore("SendNotification",{Title="Floopa Hub",Text=m,Duration=3})
    end)
end

local function R(o)
    if syn and syn.request then return syn.request(o) end
    if http_request then return http_request(o) end
    if request then return request(o) end
end

local function Copy(t)
    local ok=false
    if setclipboard then ok=pcall(function()setclipboard(t)end)
    elseif syn and syn.write_clipboard then ok=pcall(function()syn.write_clipboard(t)end)
    end
    if ok then N("Copied to clipboard.") else N("Copy manually: "..t) end
    return ok
end

local UI=Instance.new("ScreenGui",PG)
UI.Name="FHLoader"

local Main=Instance.new("Frame",UI)
Main.Size=UDim2.new(0,380,0,260)
Main.Position=UDim2.new(0.5,-190,0.5,-130)
Main.BackgroundColor3=Color3.fromRGB(18,18,22)
Main.BorderSizePixel=0
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)

local Top=Instance.new("Frame",Main)
Top.Size=UDim2.new(1,0,0,40)
Top.BackgroundColor3=Color3.fromRGB(25,25,30)
Top.BorderSizePixel=0
Instance.new("UICorner",Top).CornerRadius=UDim.new(0,12)

local Title=Instance.new("TextLabel",Top)
Title.Size=UDim2.new(1,-40,1,0)
Title.Position=UDim2.new(0,10,0,0)
Title.Text="Floopa Hub • Key System"
Title.TextColor3=Color3.fromRGB(255,255,255)
Title.Font=Enum.Font.GothamBold
Title.TextScaled=true
Title.BackgroundTransparency=1

local Close=Instance.new("TextButton",Top)
Close.Size=UDim2.new(0,40,1,0)
Close.Position=UDim2.new(1,-40,0,0)
Close.Text="X"
Close.TextColor3=Color3.fromRGB(255,80,80)
Close.Font=Enum.Font.GothamBold
Close.TextScaled=true
Close.BackgroundTransparency=1

local Box=Instance.new("TextBox",Main)
Box.Size=UDim2.new(1,-20,0,45)
Box.Position=UDim2.new(0,10,0,60)
Box.PlaceholderText="Enter your key"
Box.TextColor3=Color3.fromRGB(220,220,220)
Box.BackgroundColor3=Color3.fromRGB(30,30,40)
Box.BorderSizePixel=0
Box.ClearTextOnFocus=false
Instance.new("UICorner",Box).CornerRadius=UDim.new(0,8)

local GetKey=Instance.new("TextButton",Main)
GetKey.Size=UDim2.new(0.5,-15,0,45)
GetKey.Position=UDim2.new(0,10,0,120)
GetKey.Text="Get Key"
GetKey.TextColor3=Color3.fromRGB(255,255,255)
GetKey.Font=Enum.Font.GothamBold
GetKey.TextScaled=true
GetKey.BackgroundColor3=Color3.fromRGB(40,40,55)
GetKey.BorderSizePixel=0
Instance.new("UICorner",GetKey).CornerRadius=UDim.new(0,8)

local Validate=Instance.new("TextButton",Main)
Validate.Size=UDim2.new(0.5,-15,0,45)
Validate.Position=UDim2.new(0.5,5,0,120)
Validate.Text="Validate Key"
Validate.TextColor3=Color3.fromRGB(255,255,255)
Validate.Font=Enum.Font.GothamBold
Validate.TextScaled=true
Validate.BackgroundColor3=Color3.fromRGB(0,120,200)
Validate.BorderSizePixel=0
Instance.new("UICorner",Validate).CornerRadius=UDim.new(0,8)

local Discord=Instance.new("TextButton",Main)
Discord.Size=UDim2.new(1,-20,0,35)
Discord.Position=UDim2.new(0,10,0,180)
Discord.Text="Discord Support"
Discord.TextColor3=Color3.fromRGB(255,255,255)
Discord.Font=Enum.Font.GothamBold
Discord.TextScaled=true
Discord.BackgroundColor3=Color3.fromRGB(30,30,40)
Discord.BorderSizePixel=0
Instance.new("UICorner",Discord).CornerRadius=UDim.new(0,8)

Close.MouseButton1Click:Connect(function()
    UI:Destroy()
end)

GetKey.MouseButton1Click:Connect(function()
    if Copy("https://loot-link.com/s?bwxRK29Q") then
        N("Link copied.")
    end
end)

Discord.MouseButton1Click:Connect(function()
    if Copy("https://discord.gg/SmRdT9TM") then
        N("Discord link copied.")
    end
end)

Validate.MouseButton1Click:Connect(function()
    local key=Box.Text
    if key=="" then return N("Enter a key.") end

    local u=H:UrlEncode(L.Name)
    local v=R({
        Url="https://scripts-m6a8.onrender.com/auth/validate?key="..key.."&user="..u,
        Method="POST",
        Headers={["Content-Type"]="application/json"},
        Body="{}"
    })

    if not v or not v.Body then return N("Connection error.") end

    local ok,data=pcall(function()return H:JSONDecode(v.Body)end)
    if not ok or not data or not data.ok then return N("Invalid key.") end

    local ex=R({
        Url="https://scripts-m6a8.onrender.com/src/exploit/get",
        Method="GET",
        Headers={["Authorization"]="Bearer "..tostring(data.token)}
    })

    if ex and ex.StatusCode==200 and type(ex.Body)=="string" and #ex.Body>0 then
        local ok2,fn=pcall(loadstring,ex.Body)
        if ok2 and type(fn)=="function" then
            fn()
            N("Key valid. Hub loaded.")
            UI:Destroy()
        else
            N("Execution error.")
        end
    else
        N("Exploit fetch error.")
    end
end)
