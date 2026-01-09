-- Floopa Hub - Settings integrado en HubButton
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Fallback seguro para getgenv / shared
local gv = (type(getgenv) == "function" and getgenv()) or shared or {}
gv.FloopaHub = gv.FloopaHub or {}
gv.FloopaHub.Settings = gv.FloopaHub.Settings or {
    Notifications = true,
    ThemeColor = Color3.fromRGB(20, 20, 30),
    HeaderColor = Color3.fromRGB(0, 90, 180),
    AccentColor = Color3.fromRGB(35, 35, 55),
    StrokeColor = Color3.fromRGB(60, 60, 90),
    Transparency = 0,
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontSizeScale = 1.0, -- Escala global con UIScale
    Layout = "BottomRight", -- Informativo
    ButtonSize = UDim2.new(0, 120, 0, 40),
    InfoText = "Floopa Hub • Settings",
    Presets = {}, -- temas guardados
}

-- Evitar doble carga
if gv.FloopaHub.SettingsLoaded then
    gv.FloopaHub.ShowSettings = function()
        local pl = Players.LocalPlayer
        if not pl then return end
        local pg = pl:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild("FloopaHubGUI") then
            local gui = pg.FloopaHubGUI
            if gui and gui:FindFirstChild("SettingsFrame") then
                gui.SettingsFrame.Visible = true
            end
        end
    end
    return
end
gv.FloopaHub.SettingsLoaded = true

-- =========================
-- Utilidades generales
-- =========================
local function safeNotify(title, text, duration)
    if not gv.FloopaHub.Settings.Notifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Info",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

local function applyCorner(inst, radius)
    if inst and inst:IsA("GuiObject") then
        local c = inst:FindFirstChildOfClass("UICorner")
        if not c then
            c = Instance.new("UICorner")
            c.Parent = inst
        end
        c.CornerRadius = radius or UDim.new(0, 10)
    end
end

local function applyStroke(inst, color, thickness, transparency)
    if inst and inst:IsA("GuiObject") then
        local s = inst:FindFirstChildOfClass("UIStroke")
        if not s then
            s = Instance.new("UIStroke")
            s.Parent = inst
        end
        s.Color = color or gv.FloopaHub.Settings.StrokeColor
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
    end
end

local function styleLabel(label, bold)
    if not label or not label:IsA("TextLabel") then return end
    label.Font = bold and gv.FloopaHub.Settings.FontBold or gv.FloopaHub.Settings.Font
    label.TextScaled = true
    label.TextColor3 = label.TextColor3 or Color3.fromRGB(255,255,255)
    label.BackgroundTransparency = label.BackgroundTransparency or 1
end

-- Cache de botones resizables para evitar recorrer todo el árbol
local resizableButtons = {}

local function registerResizable(btn)
    if not btn or not btn:IsA("TextButton") then return end
    if btn:GetAttribute("Resizable") == true then
        table.insert(resizableButtons, btn)
        -- aplicar tamaño inicial
        local bs = gv.FloopaHub.Settings.ButtonSize
        if bs and bs.X and bs.Y then
            btn.Size = UDim2.new(0, bs.X.Offset, 0, bs.Y.Offset)
        end
    end
end

local function updateButtonSizes()
    local bs = gv.FloopaHub.Settings.ButtonSize
    if not bs then return end
    local w = bs.X.Offset
    local h = bs.Y.Offset
    for i = #resizableButtons, 1, -1 do
        local obj = resizableButtons[i]
        if obj and obj.Parent then
            obj.Size = UDim2.new(0, w, 0, h)
        else
            table.remove(resizableButtons, i)
        end
    end
end

local function styleButton(btn)
    if not btn or not btn:IsA("TextButton") then return end
    btn.Font = gv.FloopaHub.Settings.FontBold
    btn.TextScaled = true
    btn.BackgroundColor3 = gv.FloopaHub.Settings.AccentColor
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    -- aplicar tamaño si es resizable
    if btn:GetAttribute("Resizable") == true then
        registerResizable(btn)
    end
end

local function randomThemeColor()
    return Color3.fromRGB(math.random(40, 180), math.random(40, 180), math.random(40, 180))
end

-- Debounce wrapper simple
local function withDebounce(fn, delay)
    delay = delay or 0.12
    local busy = false
    return function(...)
        if busy then return end
        busy = true
        local ok, err = pcall(fn, ...)
        task.delay(delay, function() busy = false end)
        if not ok then
            warn("Debounced function error:", err)
        end
    end
end

-- table.clear fallback
local function clearTable(t)
    if type(t) ~= "table" then return end
    if table.clear then
        table.clear(t)
        return
    end
    for i = #t, 1, -1 do
        table.remove(t, i)
    end
end

-- =========================
-- Crear GUI principal (cliente)
-- =========================
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then
    error("PlayerGui no disponible. Asegúrate de ejecutar esto como LocalScript en cliente.")
end

local gui = playerGui:FindFirstChild("FloopaHubGUI")
if not gui then
    gui = Instance.new("ScreenGui")
    gui.Name = "FloopaHubGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 1000
    gui.Parent = playerGui
end

-- =========================
-- Frame principal Settings
-- =========================
local frame = gui:FindFirstChild("SettingsFrame") or Instance.new("Frame")
frame.Name = "SettingsFrame"
frame.Size = UDim2.new(0, 360, 0, 520)
frame.Position = UDim2.new(0.5, -180, 0.5, -260)
frame.BackgroundColor3 = gv.FloopaHub.Settings.ThemeColor
frame.BackgroundTransparency = gv.FloopaHub.Settings.Transparency
frame.Visible = false
frame.ZIndex = 100
frame.Parent = gui
applyCorner(frame, UDim.new(0, 14))
applyStroke(frame, gv.FloopaHub.Settings.StrokeColor, 1, 0)

-- UIScale global
local uiScale = frame:FindFirstChildOfClass("UIScale")
if not uiScale then
    uiScale = Instance.new("UIScale")
    uiScale.Parent = frame
end
uiScale.Scale = gv.FloopaHub.Settings.FontSizeScale

-- Header
local header = frame:FindFirstChild("Header") or Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = gv.FloopaHub.Settings.HeaderColor
header.Parent = frame
applyCorner(header, UDim.new(0, 14))
applyStroke(header, Color3.fromRGB(40, 120, 220), 1, 0)

local title = header:FindFirstChild("Title") or Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = gv.FloopaHub.Settings.InfoText
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = header
styleLabel(title, true)

local closeBtn = header:FindFirstChild("Close") or Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = header
styleButton(closeBtn)
applyCorner(closeBtn, UDim.new(0, 8))
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

-- Tabs bar
local tabsBar = frame:FindFirstChild("TabsBar") or Instance.new("Frame")
tabsBar.Name = "TabsBar"
tabsBar.Size = UDim2.new(1, -20, 0, 40)
tabsBar.Position = UDim2.new(0, 10, 0, 60)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = frame

local tabsLayout = tabsBar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.Parent = tabsBar

local function newTabButton(name, text)
    local b = tabsBar:FindFirstChild(name) or Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, 100, 1, 0)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Parent = tabsBar
    b:SetAttribute("Resizable", false) -- tabs no son resizables por ButtonSize
    styleButton(b)
    applyCorner(b, UDim.new(0, 8))
    return b
end

local tabGeneral = newTabButton("TabGeneral", "General")
local tabTheme   = newTabButton("TabTheme", "Tema")
local tabUI      = newTabButton("TabUI", "Interfaz")
local tabAdvanced= newTabButton("TabAdvanced", "Avanzado")
local tabAbout   = newTabButton("TabAbout", "Acerca de")

-- Pages container
local pages = frame:FindFirstChild("Pages") or Instance.new("Frame")
pages.Name = "Pages"
pages.Size = UDim2.new(1, -20, 1, -120)
pages.Position = UDim2.new(0, 10, 0, 110)
pages.BackgroundTransparency = 1
pages.Parent = frame

local function newPage(name)
    local p = pages:FindFirstChild(name) or Instance.new("Frame")
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = pages
    return p
end

local pageGeneral = newPage("PageGeneral")
local pageTheme   = newPage("PageTheme")
local pageUI      = newPage("PageUI")
local pageAdvanced= newPage("PageAdvanced")
local pageAbout   = newPage("PageAbout")

local function showPage(target)
    for _, child in ipairs(pages:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = (child == target)
        end
    end
end

-- Default page
showPage(pageGeneral)

-- Tab bindings
tabGeneral.MouseButton1Click:Connect(function() showPage(pageGeneral) end)
tabTheme.MouseButton1Click:Connect(function() showPage(pageTheme) end)
tabUI.MouseButton1Click:Connect(function() showPage(pageUI) end)
tabAdvanced.MouseButton1Click:Connect(function() showPage(pageAdvanced) end)
tabAbout.MouseButton1Click:Connect(function() showPage(pageAbout) end)

-- Utilidad: detectar botones de contenido (no tabs/close)
local function isContentButton(obj)
    return obj:IsA("TextButton") and (not obj:IsDescendantOf(header)) and (not obj:IsDescendantOf(tabsBar))
end

-- =========================
-- Página: General
-- =========================
do
    local y = 0

    -- Notificaciones ON/OFF
    local notifBtn = pageGeneral:FindFirstChild("NotifBtn") or Instance.new("TextButton")
    notifBtn.Name = "NotifBtn"
    notifBtn.Size = UDim2.new(1, -20, 0, 40)
    notifBtn.Position = UDim2.new(0, 10, 0, y)
    notifBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifBtn.Parent = pageGeneral
    notifBtn:SetAttribute("Resizable", true)
    styleButton(notifBtn); applyCorner(notifBtn, UDim.new(0, 10))
    local function refreshNotifText()
        notifBtn.Text = gv.FloopaHub.Settings.Notifications and "Notificaciones: ON" or "Notificaciones: OFF"
    end
    refreshNotifText()
    notifBtn.MouseButton1Click:Connect(withDebounce(function()
        gv.FloopaHub.Settings.Notifications = not gv.FloopaHub.Settings.Notifications
        refreshNotifText()
    end))
    y = y + 50

    -- Transparencia + / -
    local transpInfo = pageGeneral:FindFirstChild("TranspInfo") or Instance.new("TextLabel")
    transpInfo.Name = "TranspInfo"
    transpInfo.Size = UDim2.new(1, -20, 0, 28)
    transpInfo.Position = UDim2.new(0, 10, 0, y)
    transpInfo.BackgroundTransparency = 1
    transpInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    transpInfo.TextXAlignment = Enum.TextXAlignment.Left
    transpInfo.Parent = pageGeneral
    styleLabel(transpInfo, false)
    local function refreshTranspInfo()
        local pct = math.floor(math.clamp(gv.FloopaHub.Settings.Transparency, 0, 1) * 100)
        transpInfo.Text = string.format("Transparencia: %d%%", pct)
    end
    refreshTranspInfo()
    y = y + 32

    local transpRow = pageGeneral:FindFirstChild("TranspRow") or Instance.new("Frame")
    transpRow.Name = "TranspRow"
    transpRow.Size = UDim2.new(1, -20, 0, 40)
    transpRow.Position = UDim2.new(0, 10, 0, y)
    transpRow.BackgroundTransparency = 1
    transpRow.Parent = pageGeneral

    local minusBtn = transpRow:FindFirstChild("Minus") or Instance.new("TextButton")
    minusBtn.Name = "Minus"
    minusBtn.Size = UDim2.new(0, 120, 1, 0)
    minusBtn.Position = UDim2.new(0, 0, 0, 0)
    minusBtn.Text = "- Transparencia"
    minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minusBtn.Parent = transpRow
    minusBtn:SetAttribute("Resizable", true)
    styleButton(minusBtn); applyCorner(minusBtn, UDim.new(0, 10))

    local plusBtn = transpRow:FindFirstChild("Plus") or Instance.new("TextButton")
    plusBtn.Name = "Plus"
    plusBtn.Size = UDim2.new(0, 120, 1, 0)
    plusBtn.Position = UDim2.new(0, 130, 0, 0)
    plusBtn.Text = "+ Transparencia"
    plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    plusBtn.Parent = transpRow
    plusBtn:SetAttribute("Resizable", true)
    styleButton(plusBtn); applyCorner(plusBtn, UDim.new(0, 10))

    minusBtn.MouseButton1Click:Connect(withDebounce(function()
        gv.FloopaHub.Settings.Transparency = math.clamp(gv.FloopaHub.Settings.Transparency - 0.1, 0, 1)
        frame.BackgroundTransparency = gv.FloopaHub.Settings.Transparency
        refreshTranspInfo()
    end))
    plusBtn.MouseButton1Click:Connect(withDebounce(function()
        gv.FloopaHub.Settings.Transparency = math.clamp(gv.FloopaHub.Settings.Transparency + 0.1, 0, 1)
        frame.BackgroundTransparency = gv.FloopaHub.Settings.Transparency
        refreshTranspInfo()
    end))
    y = y + 50

    -- Escala global (UIScale)
    local fontRow = pageGeneral:FindFirstChild("FontRow") or Instance.new("Frame")
    fontRow.Name = "FontRow"
    fontRow.Size = UDim2.new(1, -20, 0, 40)
    fontRow.Position = UDim2.new(0, 10, 0, y)
    fontRow.BackgroundTransparency = 1
    fontRow.Parent = pageGeneral

    local fontDec = fontRow:FindFirstChild("FontDec") or Instance.new("TextButton")
    fontDec.Name = "FontDec"
    fontDec.Size = UDim2.new(0, 120, 1, 0)
    fontDec.Position = UDim2.new(0, 0, 0, 0)
    fontDec.Text = "Escala -"
    fontDec.TextColor3 = Color3.fromRGB(255, 255, 255)
    fontDec.Parent = fontRow
    fontDec:SetAttribute("Resizable", true)
    styleButton(fontDec); applyCorner(fontDec, UDim.new(0, 10))

    local fontInc = fontRow:FindFirstChild("FontInc") or Instance.new("TextButton")
    fontInc.Name = "FontInc"
    fontInc.Size = UDim2.new(0, 120, 1, 0)
    fontInc.Position = UDim2.new(0, 130, 0, 0)
    fontInc.Text = "Escala +"
    fontInc.TextColor3 = Color3.fromRGB(255, 255, 255)
    fontInc.Parent = fontRow
    fontInc:SetAttribute("Resizable", true)
    styleButton(fontInc); applyCorner(fontInc, UDim.new(0, 10))

    local fontInfo = pageGeneral:FindFirstChild("FontInfo") or Instance.new("TextLabel")
    fontInfo.Name = "FontInfo"
    fontInfo.Size = UDim2.new(1, -20, 0, 26)
    fontInfo.Position = UDim2.new(0, 10, 0, y + 42)
    fontInfo.BackgroundTransparency = 1
    fontInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    fontInfo.TextXAlignment = Enum.TextXAlignment.Left
    fontInfo.Parent = pageGeneral
    styleLabel(fontInfo, false)
    local function refreshFontInfo()
        fontInfo.Text = string.format("Escala global: %.2f", gv.FloopaHub.Settings.FontSizeScale)
    end
    refreshFontInfo()

    fontDec.MouseButton1Click:Connect(withDebounce(function()
        gv.FloopaHub.Settings.FontSizeScale = math.max(0.8, gv.FloopaHub.Settings.FontSizeScale - 0.1)
        uiScale.Scale = gv.FloopaHub.Settings.FontSizeScale
        refreshFontInfo()
    end))
    fontInc.MouseButton1Click:Connect(withDebounce(function()
        gv.FloopaHub.Settings.FontSizeScale = math.min(1.4, gv.FloopaHub.Settings.FontSizeScale + 0.1)
        uiScale.Scale = gv.FloopaHub.Settings.FontSizeScale
        refreshFontInfo()
    end))
end

-- =========================
-- Página: Tema
-- =========================
do
    local y = 0

    local themeInfo = pageTheme:FindFirstChild("ThemeInfo") or Instance.new("TextLabel")
    themeInfo.Name = "ThemeInfo"
    themeInfo.Size = UDim2.new(1, -20, 0, 26)
    themeInfo.Position = UDim2.new(0, 10, 0, y)
    themeInfo.BackgroundTransparency = 1
    themeInfo.Text = "Colores del Hub (no afecta otros paneles)"
    themeInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    themeInfo.TextXAlignment = Enum.TextXAlignment.Left
    themeInfo.Parent = pageTheme
    styleLabel(themeInfo, false)
    y = y + 36

    -- Cambiar color tema
    local colorBtn = pageTheme:FindFirstChild("ColorBtn") or Instance.new("TextButton")
    colorBtn.Name = "ColorBtn"
    colorBtn.Size = UDim2.new(1, -20, 0, 40)
    colorBtn.Position = UDim2.new(0, 10, 0, y)
    colorBtn.Text = "Cambiar color del panel"
    colorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorBtn.Parent = pageTheme
    colorBtn:SetAttribute("Resizable", true)
    styleButton(colorBtn); applyCorner(colorBtn, UDim.new(0, 10))
    colorBtn.MouseButton1Click:Connect(withDebounce(function()
        local newColor = randomThemeColor()
        gv.FloopaHub.Settings.ThemeColor = newColor
        frame.BackgroundColor3 = newColor
    end))
    y = y + 50

    -- Cambiar color header
    local headerBtn = pageTheme:FindFirstChild("HeaderBtn") or Instance.new("TextButton")
    headerBtn.Name = "HeaderBtn"
    headerBtn.Size = UDim2.new(1, -20, 0, 40)
    headerBtn.Position = UDim2.new(0, 10, 0, y)
    headerBtn.Text = "Cambiar color del header"
    headerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerBtn.Parent = pageTheme
    headerBtn:SetAttribute("Resizable", true)
    styleButton(headerBtn); applyCorner(headerBtn, UDim.new(0, 10))
    headerBtn.MouseButton1Click:Connect(withDebounce(function()
        local newColor = randomThemeColor()
        gv.FloopaHub.Settings.HeaderColor = newColor
        header.BackgroundColor3 = newColor
    end))
    y = y + 50

    -- Cambiar color del acento
    local accentBtn = pageTheme:FindFirstChild("AccentBtn") or Instance.new("TextButton")
    accentBtn.Name = "AccentBtn"
    accentBtn.Size = UDim2.new(1, -20, 0, 40)
    accentBtn.Position = UDim2.new(0, 10, 0, y)
    accentBtn.Text = "Cambiar color de acento"
    accentBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    accentBtn.Parent = pageTheme
    accentBtn:SetAttribute("Resizable", true)
    styleButton(accentBtn); applyCorner(accentBtn, UDim.new(0, 10))
    accentBtn.MouseButton1Click:Connect(withDebounce(function()
        local newColor = randomThemeColor()
        gv.FloopaHub.Settings.AccentColor = newColor
        -- aplicar a botones de contenido cacheados
        for _, obj in ipairs(resizableButtons) do
            if obj and obj.Parent then
                obj.BackgroundColor3 = newColor
            end
        end
    end))
    y = y + 50

    -- Preset rápido (guardar)
    local savePresetBtn = pageTheme:FindFirstChild("SavePresetBtn") or Instance.new("TextButton")
    savePresetBtn.Name = "SavePresetBtn"
    savePresetBtn.Size = UDim2.new(1, -20, 0, 40)
    savePresetBtn.Position = UDim2.new(0, 10, 0, y)
    savePresetBtn.Text = "Guardar preset tema actual"
    savePresetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    savePresetBtn.Parent = pageTheme
    savePresetBtn:SetAttribute("Resizable", true)
    styleButton(savePresetBtn); applyCorner(savePresetBtn, UDim.new(0, 10))

    savePresetBtn.MouseButton1Click:Connect(withDebounce(function()
        local preset = {
            ThemeColor = gv.FloopaHub.Settings.ThemeColor,
            HeaderColor = gv.FloopaHub.Settings.HeaderColor,
            AccentColor = gv.FloopaHub.Settings.AccentColor,
        }
        table.insert(gv.FloopaHub.Settings.Presets, preset)
        safeNotify("Floopa Hub", "Preset guardado", 2)
    end))
    y = y + 50

    -- Aplicar primer preset guardado
    local applyPresetBtn = pageTheme:FindFirstChild("ApplyPresetBtn") or Instance.new("TextButton")
    applyPresetBtn.Name = "ApplyPresetBtn"
    applyPresetBtn.Size = UDim2.new(1, -20, 0, 40)
    applyPresetBtn.Position = UDim2.new(0, 10, 0, y)
    applyPresetBtn.Text = "Aplicar primer preset guardado"
    applyPresetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyPresetBtn.Parent = pageTheme
    applyPresetBtn:SetAttribute("Resizable", true)
    styleButton(applyPresetBtn); applyCorner(applyPresetBtn, UDim.new(0, 10))

    applyPresetBtn.MouseButton1Click:Connect(withDebounce(function()
        local preset = gv.FloopaHub.Settings.Presets and gv.FloopaHub.Settings.Presets[1]
        if preset then
            gv.FloopaHub.Settings.ThemeColor = preset.ThemeColor or gv.FloopaHub.Settings.ThemeColor
            gv.FloopaHub.Settings.HeaderColor = preset.HeaderColor or gv.FloopaHub.Settings.HeaderColor
            gv.FloopaHub.Settings.AccentColor = preset.AccentColor or gv.FloopaHub.Settings.AccentColor
            frame.BackgroundColor3 = gv.FloopaHub.Settings.ThemeColor
            header.BackgroundColor3 = gv.FloopaHub.Settings.HeaderColor
            for _, obj in ipairs(resizableButtons) do
                if obj and obj.Parent then obj.BackgroundColor3 = gv.FloopaHub.Settings.AccentColor end
            end
        else
            safeNotify("Floopa Hub", "No hay presets guardados", 2)
        end
    end))
end

-- =========================
-- Página: Interfaz
-- =========================
do
    local y = 0

    local uiInfo = pageUI:FindFirstChild("UIInfo") or Instance.new("TextLabel")
    uiInfo.Name = "UIInfo"
    uiInfo.Size = UDim2.new(1, -20, 0, 26)
    uiInfo.Position = UDim2.new(0, 10, 0, y)
    uiInfo.BackgroundTransparency = 1
    uiInfo.Text = "Preferencias del panel de configuración"
    uiInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    uiInfo.TextXAlignment = Enum.TextXAlignment.Left
    uiInfo.Parent = pageUI
    styleLabel(uiInfo, false)
    y = y + 36

    -- Layout preferido (informativo)
    local layoutBtn = pageUI:FindFirstChild("LayoutBtn") or Instance.new("TextButton")
    layoutBtn.Name = "LayoutBtn"
    layoutBtn.Size = UDim2.new(1, -20, 0, 40)
    layoutBtn.Position = UDim2.new(0, 10, 0, y)
    layoutBtn.Text = "Layout preferido: "..tostring(gv.FloopaHub.Settings.Layout)
    layoutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    layoutBtn.Parent = pageUI
    layoutBtn:SetAttribute("Resizable", true)
    styleButton(layoutBtn); applyCorner(layoutBtn, UDim.new(0, 10))
    layoutBtn.MouseButton1Click:Connect(withDebounce(function()
        local options = {"BottomRight", "TopRight", "TopLeft", "BottomLeft", "Center"}
        local idx = table.find(options, gv.FloopaHub.Settings.Layout) or 1
        idx = idx % #options + 1
        gv.FloopaHub.Settings.Layout = options[idx]
        layoutBtn.Text = "Layout preferido: "..tostring(gv.FloopaHub.Settings.Layout)
    end))
    y = y + 50

    -- Tamaño del panel Settings
    local sizeRow = pageUI:FindFirstChild("SizeRow") or Instance.new("Frame")
    sizeRow.Name = "SizeRow"
    sizeRow.Size = UDim2.new(1, -20, 0, 40)
    sizeRow.Position = UDim2.new(0, 10, 0, y)
    sizeRow.BackgroundTransparency = 1
    sizeRow.Parent = pageUI

    local sizeDec = sizeRow:FindFirstChild("SizeDec") or Instance.new("TextButton")
    sizeDec.Name = "SizeDec"
    sizeDec.Size = UDim2.new(0, 140, 1, 0)
    sizeDec.Position = UDim2.new(0, 0, 0, 0)
    sizeDec.Text = "Panel -"
    sizeDec.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeDec.Parent = sizeRow
    sizeDec:SetAttribute("Resizable", true)
    styleButton(sizeDec); applyCorner(sizeDec, UDim.new(0, 10))

    local sizeInc = sizeRow:FindFirstChild("SizeInc") or Instance.new("TextButton")
    sizeInc.Name = "SizeInc"
    sizeInc.Size = UDim2.new(0, 140, 1, 0)
    sizeInc.Position = UDim2.new(0, 150, 0, 0)
    sizeInc.Text = "Panel +"
    sizeInc.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeInc.Parent = sizeRow
    sizeInc:SetAttribute("Resizable", true)
    styleButton(sizeInc); applyCorner(sizeInc, UDim.new(0, 10))

    local function clampSize(w, h)
        return math.clamp(w, 280, 520), math.clamp(h, 420, 700)
    end

    sizeDec.MouseButton1Click:Connect(withDebounce(function()
        local w = frame.Size.X.Offset - 20
        local h = frame.Size.Y.Offset - 20
        w, h = clampSize(w, h)
        frame.Size = UDim2.new(0, w, 0, h)
    end))
    sizeInc.MouseButton1Click:Connect(withDebounce(function()
        local w = frame.Size.X.Offset + 20
        local h = frame.Size.Y.Offset + 20
        w, h = clampSize(w, h)
        frame.Size = UDim2.new(0, w, 0, h)
    end))
    y = y + 60

    -- Tamaño de botones (solo dentro del Settings, excluye tabs/close)
    local btnSizeRow = pageUI:FindFirstChild("BtnSizeRow") or Instance.new("Frame")
    btnSizeRow.Name = "BtnSizeRow"
    btnSizeRow.Size = UDim2.new(1, -20, 0, 40)
    btnSizeRow.Position = UDim2.new(0, 10, 0, y)
    btnSizeRow.BackgroundTransparency = 1
    btnSizeRow.Parent = pageUI

    local btnDec = btnSizeRow:FindFirstChild("BtnDec") or Instance.new("TextButton")
    btnDec.Name = "BtnDec"
    btnDec.Size = UDim2.new(0, 140, 1, 0)
    btnDec.Position = UDim2.new(0, 0, 0, 0)
    btnDec.Text = "Botones -"
    btnDec.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnDec.Parent = btnSizeRow
    btnDec:SetAttribute("Resizable", true)
    styleButton(btnDec); applyCorner(btnDec, UDim.new(0, 10))

    local btnInc = btnSizeRow:FindFirstChild("BtnInc") or Instance.new("TextButton")
    btnInc.Name = "BtnInc"
    btnInc.Size = UDim2.new(0, 140, 1, 0)
    btnInc.Position = UDim2.new(0, 150, 0, 0)
    btnInc.Text = "Botones +"
    btnInc.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnInc.Parent = btnSizeRow
    btnInc:SetAttribute("Resizable", true)
    styleButton(btnInc); applyCorner(btnInc, UDim.new(0, 10))

    btnDec.MouseButton1Click:Connect(withDebounce(function()
        local bw = math.max(80, gv.FloopaHub.Settings.ButtonSize.X.Offset - 10)
        local bh = math.max(32, gv.FloopaHub.Settings.ButtonSize.Y.Offset - 4)
        gv.FloopaHub.Settings.ButtonSize = UDim2.new(0, bw, 0, bh)
        updateButtonSizes()
    end))
    btnInc.MouseButton1Click:Connect(withDebounce(function()
        local bw = math.min(220, gv.FloopaHub.Settings.ButtonSize.X.Offset + 10)
        local bh = math.min(80, gv.FloopaHub.Settings.ButtonSize.Y.Offset + 4)
        gv.FloopaHub.Settings.ButtonSize = UDim2.new(0, bw, 0, bh)
        updateButtonSizes()
    end))

    -- Aplicar tamaño inicial a botones de contenido (por si hay botones ya creados)
    updateButtonSizes()
end

-- =========================
-- Página: Avanzado
-- =========================
do
    local y = 0

    local advInfo = pageAdvanced:FindFirstChild("AdvInfo") or Instance.new("TextLabel")
    advInfo.Name = "AdvInfo"
    advInfo.Size = UDim2.new(1, -20, 0, 26)
    advInfo.Position = UDim2.new(0, 10, 0, y)
    advInfo.BackgroundTransparency = 1
    advInfo.Text = "Herramientas avanzadas de configuración"
    advInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    advInfo.TextXAlignment = Enum.TextXAlignment.Left
    advInfo.Parent = pageAdvanced
    styleLabel(advInfo, false)
    y = y + 36

    -- Reset a valores por defecto (sin reemplazar la tabla Settings)
    local resetBtn = pageAdvanced:FindFirstChild("ResetBtn") or Instance.new("TextButton")
    resetBtn.Name = "ResetBtn"
    resetBtn.Size = UDim2.new(1, -20, 0, 40)
    resetBtn.Position = UDim2.new(0, 10, 0, y)
    resetBtn.Text = "Restaurar valores por defecto"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Parent = pageAdvanced
    styleButton(resetBtn)
    resetBtn.BackgroundColor3 = Color3.fromRGB(55, 35, 35)
    applyCorner(resetBtn, UDim.new(0, 10))
    resetBtn:SetAttribute("Resizable", true)

    local defaults = {
        Notifications = true,
        ThemeColor = Color3.fromRGB(20, 20, 30),
        HeaderColor = Color3.fromRGB(0, 90, 180),
        AccentColor = Color3.fromRGB(35, 35, 55),
        StrokeColor = Color3.fromRGB(60, 60, 90),
        Transparency = 0,
        Font = Enum.Font.Gotham,
        FontBold = Enum.Font.GothamBold,
        FontSizeScale = 1.0,
        Layout = "BottomRight",
        ButtonSize = UDim2.new(0, 120, 0, 40),
        InfoText = "Floopa Hub • Settings",
    }

    resetBtn.MouseButton1Click:Connect(withDebounce(function()
        for k, v in pairs(defaults) do
            gv.FloopaHub.Settings[k] = v
        end
        -- Limpiar presets con fallback
        clearTable(gv.FloopaHub.Settings.Presets)

        -- Reaplicar visual
        frame.BackgroundColor3 = gv.FloopaHub.Settings.ThemeColor
        header.BackgroundColor3 = gv.FloopaHub.Settings.HeaderColor
        frame.BackgroundTransparency = gv.FloopaHub.Settings.Transparency
        uiScale.Scale = gv.FloopaHub.Settings.FontSizeScale

        -- Reaplicar estilos a elementos cacheados
        for _, obj in ipairs(resizableButtons) do
            if obj and obj.Parent then
                obj.BackgroundColor3 = gv.FloopaHub.Settings.AccentColor
                obj.Font = gv.FloopaHub.Settings.FontBold
            end
        end

        -- Reaplicar fuentes a labels
        for _, obj in ipairs(frame:GetDescendants()) do
            if obj:IsA("TextLabel") then obj.Font = gv.FloopaHub.Settings.Font end
            if obj:IsA("TextButton") and obj:GetAttribute("Resizable") ~= true then obj.Font = gv.FloopaHub.Settings.FontBold end
        end

        safeNotify("Floopa Hub", "Preferencias restauradas", 2)
    end))
end

-- =========================
-- Página: Acerca de
-- =========================
do
    local aboutText = pageAbout:FindFirstChild("AboutText") or Instance.new("TextLabel")
    aboutText.Name = "AboutText"
    aboutText.Size = UDim2.new(1, -20, 0, 100)
    aboutText.Position = UDim2.new(0, 10, 0, 0)
    aboutText.BackgroundTransparency = 1
    aboutText.TextColor3 = Color3.fromRGB(255, 255, 255)
    aboutText.TextWrapped = true
    aboutText.TextXAlignment = Enum.TextXAlignment.Left
    aboutText.TextYAlignment = Enum.TextYAlignment.Top
    aboutText.Parent = pageAbout
    styleLabel(aboutText, false)
    aboutText.Text = "Floopa Hub Settings v5.1.1\n" ..
        "- Panel global de configuración del Hub.\n" ..
        "- No interfiere con otros paneles (ESP, XRay, etc.).\n" ..
        "- Ajusta tema, transparencia, tipografías y preferencias visuales.\n" ..
        "- Reset seguro de valores.\n\n" ..
        "Santiago (Floopa_077) • Legend Status."

    local tipText = pageAbout:FindFirstChild("TipText") or Instance.new("TextLabel")
    tipText.Name = "TipText"
    tipText.Size = UDim2.new(1, -20, 0, 60)
    tipText.Position = UDim2.new(0, 10, 0, 120)
    tipText.BackgroundTransparency = 1
    tipText.TextColor3 = Color3.fromRGB(200, 200, 220)
    tipText.TextWrapped = true
    tipText.TextXAlignment = Enum.TextXAlignment.Left
    tipText.TextYAlignment = Enum.TextYAlignment.Top
    tipText.Parent = pageAbout
    styleLabel(tipText, false)
    tipText.Text = "Nota: las preferencias de layout son informativas. El posicionamiento real de otros paneles se maneja en sus propios scripts."
end

-- =========================
-- Exponer funciones para HubButton u otros scripts
-- =========================
gv.FloopaHub.SettingsFrame = frame

gv.FloopaHub.ShowSettings = function()
    frame.Visible = true
end

gv.FloopaHub.ToggleSettings = function()
    frame.Visible = not frame.Visible
end

-- =========================
-- Inicialización visual mínima
-- =========================
do
    frame.BackgroundColor3 = gv.FloopaHub.Settings.ThemeColor
    header.BackgroundColor3 = gv.FloopaHub.Settings.HeaderColor
    frame.BackgroundTransparency = gv.FloopaHub.Settings.Transparency
    uiScale.Scale = gv.FloopaHub.Settings.FontSizeScale

    -- Aplicar color de acento a botones ya creados (cacheados)
    for _, obj in ipairs(resizableButtons) do
        if obj and obj.Parent then
            obj.BackgroundColor3 = gv.FloopaHub.Settings.AccentColor
        end
    end

    -- Asegurar que los botones creados dinámicamente se registren
    for _, obj in ipairs(frame:GetDescendants()) do
        if isContentButton(obj) and obj:GetAttribute("Resizable") == true then
            registerResizable(obj)
        end
    end
end