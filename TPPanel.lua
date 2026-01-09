-- Floopa Hub - TPPanel.lua (Delta-ready)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}

if gv.FloopaHub.TPPanelLoaded then
    return
end
gv.FloopaHub.TPPanelLoaded = true

gv.FloopaHub.TPPanel = gv.FloopaHub.TPPanel or {
    Favorites = {},
    Export = {},
}

local function notifySafe(title, text, duration)
    if gv.FloopaHub.Settings and gv.FloopaHub.Settings.Notifications == false then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title or "Info", Text = text or "", Duration = duration or 3 })
    end)
end

do
    gv.FloopaHub.__bypass = gv.FloopaHub.__bypass or {}
    local state = gv.FloopaHub.__bypass
    state.remoteGuard = false
    state.logCount = 0
    state.logMax = 25
    state.lastLogReset = tick()

    local function logWarn(msg)
        local now = tick()
        if now - state.lastLogReset > 5 then
            state.logCount = 0
            state.lastLogReset = now
        end
        if state.logCount < state.logMax then
            warn("[FloopaHub][Bypass] " .. tostring(msg))
            state.logCount = state.logCount + 1
        end
    end

    local function logInfo(msg)
        local now = tick()
        if now - state.lastLogReset > 5 then
            state.logCount = 0
            state.lastLogReset = now
        end
        if state.logCount < state.logMax then
            print("[FloopaHub][Bypass] " .. tostring(msg))
            state.logCount = state.logCount + 1
        end
    end

    local suspiciousTokens = { "ban","report","anti","log","cheat","exploit","detect","blacklist","flag","kick","moderation" }
    local whitelistTokens = { "antique","reportcard","loggerframe","catalog" }

    local function isSuspicious(nameLower)
        for _, t in ipairs(suspiciousTokens) do
            if string.find(nameLower, t, 1, true) then return true end
        end
        return false
    end

    local function isWhitelisted(nameLower)
        for _, t in ipairs(whitelistTokens) do
            if string.find(nameLower, t, 1, true) then return true end
        end
        return false
    end

    gv.FloopaHub.EnableRemoteGuard = function() state.remoteGuard = true end
    gv.FloopaHub.DisableRemoteGuard = function() state.remoteGuard = false end

    local mt = getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }
            if method == "Kick" then
                logWarn("Kick bloqueado.")
                return nil
            end
            if state.remoteGuard and (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local nameLower = (self.Name or ""):lower()
                if isSuspicious(nameLower) and not isWhitelisted(nameLower) then
                    logWarn(("Remote bloqueado (%s): %s"):format(method, self.Name))
                    return nil
                end
            end
            return oldNamecall(self, table.unpack(args))
        end)
        setreadonly(mt, true)
        gv.FloopaHub.RestoreMetatable = function()
            local mt2 = getrawmetatable(game)
            setreadonly(mt2, false)
            mt2.__namecall = oldNamecall
            setreadonly(mt2, true)
            logInfo("Metatable restaurado.")
        end
        logInfo("Bypass PRO activado.")
    else
        logWarn("Metatable no disponible.")
    end
end

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local gui = playerGui:FindFirstChild("FloopaHubGUI")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "FloopaHubGUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
end

local function applyCorner(inst, radius)
    if inst and inst:IsA("GuiObject") then
        local c = inst:FindFirstChildOfClass("UICorner")
        if not c then c = Instance.new("UICorner", inst) end
        c.CornerRadius = radius or UDim.new(0, 10)
    end
end

local function setButtonStyle(btn)
    if not btn or not btn:IsA("TextButton") then return end
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local frame = gui:FindFirstChild("TPPanelFrame") or Instance.new("Frame")
frame.Name = "TPPanelFrame"
frame.Size = UDim2.new(0, 380, 0, 560)
frame.Position = UDim2.new(0.5, -190, 0.5, -280)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.Visible = false
frame.Parent = gui
applyCorner(frame, UDim.new(0, 14))

local header = frame:FindFirstChild("Header") or Instance.new("Frame", frame)
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(0, 90, 180)
applyCorner(header, UDim.new(0, 14))

local title = header:FindFirstChild("Title") or Instance.new("TextLabel", header)
title.Name = "Title"
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "TP Panel Avanzado"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

local closeBtn = header:FindFirstChild("Close") or Instance.new("TextButton", header)
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
closeBtn.Text = "X"
setButtonStyle(closeBtn)
applyCorner(closeBtn, UDim.new(0, 8))
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    gv.FloopaHub.DisableRemoteGuard()
end)

local tabsBar = frame:FindFirstChild("TabsBar") or Instance.new("Frame", frame)
tabsBar.Name = "TabsBar"
tabsBar.Size = UDim2.new(1, -20, 0, 40)
tabsBar.Position = UDim2.new(0, 10, 0, 60)
tabsBar.BackgroundTransparency = 1

local tabsLayout = tabsBar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", tabsBar)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 8)

local function newTab(name, text)
    local b = tabsBar:FindFirstChild(name) or Instance.new("TextButton", tabsBar)
    b.Name = name
    b.Size = UDim2.new(0, 110, 1, 0)
    b.Text = text
    setButtonStyle(b)
    applyCorner(b, UDim.new(0, 8))
    return b
end

local tabPlayers = newTab("TabPlayers", "Jugadores")
local tabFavorites = newTab("TabFavorites", "Favoritos")
local tabRandom = newTab("TabRandom", "Random")
local tabAdvanced = newTab("TabAdvanced", "Avanzado")

local pages = frame:FindFirstChild("Pages") or Instance.new("Frame", frame)
pages.Name = "Pages"
pages.Size = UDim2.new(1, -20, 1, -120)
pages.Position = UDim2.new(0, 10, 0, 110)
pages.BackgroundTransparency = 1

local function newPage(name)
    local p = pages:FindFirstChild(name) or Instance.new("Frame", pages)
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    return p
end

local pagePlayers = newPage("PagePlayers")
local pageFavorites = newPage("PageFavorites")
local pageRandom = newPage("PageRandom")
local pageAdvanced = newPage("PageAdvanced")

local function showPage(target)
    for _, child in ipairs(pages:GetChildren()) do
        if child:IsA("Frame") then child.Visible = (child == target) end
    end
end

showPage(pagePlayers)

tabPlayers.MouseButton1Click:Connect(function() showPage(pagePlayers) end)
tabFavorites.MouseButton1Click:Connect(function() showPage(pageFavorites) end)
tabRandom.MouseButton1Click:Connect(function() showPage(pageRandom) end)
tabAdvanced.MouseButton1Click:Connect(function() showPage(pageAdvanced) end)

local searchBox = pagePlayers:FindFirstChild("SearchBox") or Instance.new("TextBox", pagePlayers)
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 36)
searchBox.Position = UDim2.new(0, 10, 0, 10)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextScaled = true
searchBox.PlaceholderText = "Buscar jugador..."
applyCorner(searchBox, UDim.new(0, 10))

local scroll = pagePlayers:FindFirstChild("PlayersScroll") or Instance.new("ScrollingFrame", pagePlayers)
scroll.Name = "PlayersScroll"
scroll.Size = UDim2.new(1, -20, 1, -66)
scroll.Position = UDim2.new(0, 10, 0, 56)
scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
scroll.ScrollBarThickness = 8
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
applyCorner(scroll, UDim.new(0, 10))

local function createPlayerButton(plr, y)
    local b = Instance.new("TextButton")
    b.Name = "TP_" .. plr.UserId
    b.Size = UDim2.new(1, 0, 0, 56)
    b.Position = UDim2.new(0, 0, 0, y)
    setButtonStyle(b)
    b.Text = ""
    b.Parent = scroll
    applyCorner(b, UDim.new(0, 8))

    local avatar = Instance.new("ImageLabel", b)
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.Position = UDim2.new(0, 6, 0.5, -22)
    avatar.BackgroundTransparency = 1
    local thumb, isReady = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    if isReady then avatar.Image = thumb end

    local nameLabel = Instance.new("TextLabel", b)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -110, 1, 0)
    nameLabel.Position = UDim2.new(0, 56, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local favBtn = Instance.new("TextButton", b)
    favBtn.Name = "FavBtn"
    favBtn.Size = UDim2.new(0, 44, 0, 44)
    favBtn.Position = UDim2.new(1, -50, 0.5, -22)
    favBtn.Text = "★"
    setButtonStyle(favBtn)
    applyCorner(favBtn, UDim.new(0, 8))

    favBtn.MouseButton1Click:Connect(function()
        local id = plr.UserId
        if not table.find(gv.FloopaHub.TPPanel.Favorites, id) then
            table.insert(gv.FloopaHub.TPPanel.Favorites, id)
            notifySafe("Floopa Hub", "Añadido a favoritos: " .. plr.Name, 2)
        end
    end)

    b.MouseButton1Click:Connect(function()
        gv.FloopaHub.EnableRemoteGuard()
        local myChar = localPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local tChar = plr.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(2, 0, 0)
            notifySafe("Floopa Hub", "TP hacia " .. plr.Name, 2)
        else
            notifySafe("Floopa Hub", "No se puede TP: personaje/root no disponibles", 2)
        end
        gv.FloopaHub.DisableRemoteGuard()
    end)
end

local function rebuildList()
    gv.FloopaHub.EnableRemoteGuard()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local y = 0
    local query = string.lower(searchBox.Text or "")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            if query == "" or string.find(string.lower(plr.Name), query, 1, true) then
                createPlayerButton(plr, y)
                y = y + 60
            end
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y)
    gv.FloopaHub.DisableRemoteGuard()
end

rebuildList()
searchBox.FocusLost:Connect(function() rebuildList() end)
searchBox:GetPropertyChangedSignal("Text"):Connect(function() rebuildList() end)

Players.PlayerAdded:Connect(function() rebuildList() end)
Players.PlayerRemoving:Connect(function() rebuildList() end)

local favScroll = pageFavorites:FindFirstChild("FavScroll") or Instance.new("ScrollingFrame", pageFavorites)
favScroll.Name = "FavScroll"
favScroll.Size = UDim2.new(1, -20, 1, -20)
favScroll.Position = UDim2.new(0, 10, 0, 10)
favScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
favScroll.ScrollBarThickness = 8
favScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
applyCorner(favScroll, UDim.new(0, 10))

local function createFavoriteButton(userId, y)
    local b = Instance.new("TextButton")
    b.Name = "Fav_" .. userId
    b.Size = UDim2.new(1, 0, 0, 56)
    b.Position = UDim2.new(0, 0, 0, y)
    setButtonStyle(b)
    b.Text = ""
    b.Parent = favScroll
    applyCorner(b, UDim.new(0, 8))

    local avatar = Instance.new("ImageLabel", b)
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.Position = UDim2.new(0, 6, 0.5, -22)
    avatar.BackgroundTransparency = 1
    local thumb, isReady = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    if isReady then avatar.Image = thumb end

    local foundName = tostring(userId)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.UserId == userId then foundName = pl.Name break end
    end

    local nameLabel = Instance.new("TextLabel", b)
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -110, 1, 0)
    nameLabel.Position = UDim2.new(0, 56, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = foundName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local delBtn = Instance.new("TextButton", b)
    delBtn.Name = "DelBtn"
    delBtn.Size = UDim2.new(0, 44, 0, 44)
    delBtn.Position = UDim2.new(1, -50, 0.5, -22)
    delBtn.Text = "−"
    setButtonStyle(delBtn)
    applyCorner(delBtn, UDim.new(0, 8))

    delBtn.MouseButton1Click:Connect(function()
        for i, id in ipairs(gv.FloopaHub.TPPanel.Favorites) do
            if id == userId then
                table.remove(gv.FloopaHub.TPPanel.Favorites, i)
                break
            end
        end
        notifySafe("Floopa Hub", "Eliminado de favoritos: " .. foundName, 2)
        rebuildFavorites()
    end)

    b.MouseButton1Click:Connect(function()
        gv.FloopaHub.EnableRemoteGuard()
        local myChar = localPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetPlr
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.UserId == userId then targetPlr = pl break end
        end
        local tChar = targetPlr and targetPlr.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(2, 0, 0)
            notifySafe("Floopa Hub", "TP hacia " .. (targetPlr and targetPlr.Name or foundName), 2)
        else
            notifySafe("Floopa Hub", "No se puede TP: personaje/root no disponibles", 2)
        end
        gv.FloopaHub.DisableRemoteGuard()
    end)
end

function rebuildFavorites()
    gv.FloopaHub.EnableRemoteGuard()
    for _, child in ipairs(favScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local y = 0
    for _, id in ipairs(gv.FloopaHub.TPPanel.Favorites) do
        createFavoriteButton(id, y)
        y = y + 60
    end
    favScroll.CanvasSize = UDim2.new(0, 0, 0, y)
    gv.FloopaHub.DisableRemoteGuard()
end

rebuildFavorites()

local randInfo = pageRandom:FindFirstChild("RandInfo") or Instance.new("TextLabel", pageRandom)
randInfo.Name = "RandInfo"
randInfo.Size = UDim2.new(1, -20, 0, 28)
randInfo.Position = UDim2.new(0, 10, 0, 10)
randInfo.BackgroundTransparency = 1
randInfo.Text = "TP a partes ancladas visibles del mapa"
randInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
randInfo.Font = Enum.Font.Gotham
randInfo.TextScaled = true
randInfo.TextXAlignment = Enum.TextXAlignment.Left

local tpRandom = pageRandom:FindFirstChild("TPRandom") or Instance.new("TextButton", pageRandom)
tpRandom.Name = "TPRandom"
tpRandom.Size = UDim2.new(1, -20, 0, 44)
tpRandom.Position = UDim2.new(0, 10, 0, 48)
tpRandom.Text = "TP Random"
setButtonStyle(tpRandom)
applyCorner(tpRandom, UDim.new(0, 10))

local lastTP = 0
tpRandom.MouseButton1Click:Connect(function()
    local now = tick()
    if now - lastTP < 0.25 then return end
    lastTP = now
    gv.FloopaHub.EnableRemoteGuard()
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        notifySafe("Floopa Hub", "No se puede TP: HumanoidRootPart no disponible", 2)
        gv.FloopaHub.DisableRemoteGuard()
        return
    end
    local candidates = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Anchored and obj.Transparency < 1 and not obj:IsDescendantOf(myChar) then
            table.insert(candidates, obj)
            if #candidates >= 500 then break end
        end
    end
    if #candidates > 0 then
        local rand = candidates[math.random(1, #candidates)]
        myRoot.CFrame = rand.CFrame + Vector3.new(0, 5, 0)
        notifySafe("Floopa Hub", "TP Random hecho", 2)
    else
        notifySafe("Floopa Hub", "No hay candidatos para TP random", 2)
    end
    gv.FloopaHub.DisableRemoteGuard()
end)

local advInfo = pageAdvanced:FindFirstChild("AdvInfo") or Instance.new("TextLabel", pageAdvanced)
advInfo.Name = "AdvInfo"
advInfo.Size = UDim2.new(1, -20, 0, 28)
advInfo.Position = UDim2.new(0, 10, 0, 10)
advInfo.BackgroundTransparency = 1
advInfo.Text = "Herramientas avanzadas del TPPanel"
advInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
advInfo.Font = Enum.Font.Gotham
advInfo.TextScaled = true
advInfo.TextXAlignment = Enum.TextXAlignment.Left

local exportBtn = pageAdvanced:FindFirstChild("ExportBtn") or Instance.new("TextButton", pageAdvanced)
exportBtn.Name = "ExportBtn"
exportBtn.Size = UDim2.new(1, -20, 0, 44)
exportBtn.Position = UDim2.new(0, 10, 0, 48)
exportBtn.Text = "Exportar favoritos (interno)"
setButtonStyle(exportBtn)
applyCorner(exportBtn, UDim.new(0, 10))

exportBtn.MouseButton1Click:Connect(function()
    gv.FloopaHub.TPPanel.Export = {
        Favorites = table.clone(gv.FloopaHub.TPPanel.Favorites)
    }
    notifySafe("Floopa Hub", "Favoritos exportados", 2)
end)

local importBtn = pageAdvanced:FindFirstChild("ImportBtn") or Instance.new("TextButton", pageAdvanced)
importBtn.Name = "ImportBtn"
importBtn.Size = UDim2.new(1, -20, 0, 44)
importBtn.Position = UDim2.new(0, 10, 0, 98)
importBtn.Text = "Importar favoritos (interno)"
setButtonStyle(importBtn)
applyCorner(importBtn, UDim.New(0, 10))

importBtn.MouseButton1Click:Connect(function()
    local data = gv.FloopaHub.TPPanel.Export
    if type(data) == "table" and type(data.Favorites) == "table" then
        gv.FloopaHub.TPPanel.Favorites = table.clone(data.Favorites)
        rebuildFavorites()
        notifySafe("Floopa Hub", "Favoritos importados", 2)
    else
        notifySafe("Floopa Hub", "No hay datos exportados", 2)
    end
end)

local resetBtn = pageAdvanced:FindFirstChild("ResetBtn") or Instance.new("TextButton", pageAdvanced)
resetBtn.Name = "ResetBtn"
resetBtn.Size = UDim2.new(1, -20, 0, 44)
resetBtn.Position = UDim2.new(0, 10, 0, 148)
resetBtn.Text = "Resetear favoritos"
setButtonStyle(resetBtn)
resetBtn.BackgroundColor3 = Color3.fromRGB(55, 35, 35)
applyCorner(resetBtn, UDim2.new(0, 10))

resetBtn.MouseButton1Click:Connect(function()
    gv.FloopaHub.TPPanel.Favorites = {}
    rebuildFavorites()
    notifySafe("Floopa Hub", "Favoritos reseteados", 2)
end)

local openBtn = gui:FindFirstChild("TPPanelOpenButton") or Instance.new("TextButton", gui)
openBtn.Name = "TPPanelOpenButton"
openBtn.Size = UDim2.new(0, 160, 0, 44)
openBtn.Position = UDim2.new(0, 20, 0, 120)
openBtn.Text = "Abrir TP Panel"
setButtonStyle(openBtn)
applyCorner(openBtn, UDim.new(0, 10))
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    gv.FloopaHub.EnableRemoteGuard()
    task.delay(1.5, function()
        if not frame.Visible then return end
        gv.FloopaHub.DisableRemoteGuard()
    end)
end)

gv.FloopaHub.TPPanelFrame = frame
gv.FloopaHub.ShowTPPanel = function()
    frame.Visible = true
    gv.FloopaHub.EnableRemoteGuard()
    task.delay(1.5, function()
        if not frame.Visible then return end
        gv.FloopaHub.DisableRemoteGuard()
    end)
end
gv.FloopaHub.ToggleTPPanel = function()
    frame.Visible = not frame.Visible
    if frame.Visible then
        gv.FloopaHub.EnableRemoteGuard()
        task.delay(1.5, function()
            if not frame.Visible then return end
            gv.FloopaHub.DisableRemoteGuard()
        end)
    else
        gv.FloopaHub.DisableRemoteGuard()
    end
end

notifySafe("Floopa Hub", "TP Panel listo", 2)