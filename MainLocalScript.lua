-- Floopa Hub - MainLocalScript
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}
if gv.FloopaHub.MainLocalLoaded then
    return gv.FloopaHub.MainLocal
end
gv.FloopaHub.MainLocalLoaded = true

-- Notificación segura
local function notifySafe(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Info",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

-- HTTP seguro (con múltiples backends)
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
        local body = tryReq(syn.request); if body then return body end
    end
    if http_request then
        local body = tryReq(http_request); if body then return body end
    end
    if request then
        local body = tryReq(request); if body then return body end
    end
    return nil
end

-- loadstring seguro
local function safeLoad(url)
    local res = safeHttpGet(url)
    if type(res) ~= "string" or #res == 0 then
        notifySafe("Floopa Hub", "No se pudo cargar: "..tostring(url), 3)
        return {}
    end
    local fOk, loader = pcall(loadstring, res)
    if not fOk or typeof(loader) ~= "function" then
        notifySafe("Floopa Hub", "Script inválido en: "..tostring(url), 3)
        return {}
    end
    local rOk, result = pcall(loader)
    if not rOk then
        notifySafe("Floopa Hub", "Error ejecutando script: "..tostring(result), 3)
        return {}
    end
    return result
end

-- Bypass integrado de respaldo (por si el externo falla o el juego intenta bloquearlo)
local function ensureLocalBypass()
    gv.FloopaHub.__BypassReady = gv.FloopaHub.__BypassReady or false
    gv.FloopaHub.__BypassActive = gv.FloopaHub.__BypassActive or {}
    gv.FloopaHub.__Original = gv.FloopaHub.__Original or nil

    if gv.FloopaHub.__BypassReady then return true end

    local mt = getrawmetatable(game)
    if not mt then
        warn("[FloopaHub] Metatable no disponible para bypass local.")
        return false
    end
    local original = { __namecall = mt.__namecall }
    setreadonly(mt, false)

    local blacklist = {"ban","report","anti","log","kick","fly","speed","noclip"}
    local whitelist = {"antique","reportcard"}

    local function shouldBlock(nameLower)
        for _, allow in ipairs(whitelist) do
            if nameLower:find(allow) then return false end
        end
        for _, bad in ipairs(blacklist) do
            if nameLower:find(bad) then return true end
        end
        return false
    end

    local function clampArg(a)
        if typeof(a) == "number" then
            return math.clamp(a, -5000, 5000)
        elseif typeof(a) == "Vector3" then
            return Vector3.new(
                math.clamp(a.X, -220, 220),
                math.clamp(a.Y, -220, 220),
                math.clamp(a.Z, -220, 220)
            )
        elseif typeof(a) == "table" then
            local copy = {}
            for k,v in pairs(a) do
                local kl = tostring(k):lower()
                if kl:find("fly") or kl:find("noclip") or kl:find("speed") then
                    copy[k] = false
                else
                    copy[k] = clampArg(v)
                end
            end
            return copy
        end
        return a
    end

    local function hooked(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        local nameLower = (typeof(self)=="Instance" and (self.Name or "")):lower()

        -- Respeta activación bajo demanda: si no hay comandos activos, deja pasar
        local anyActive = false
        for _, v in pairs(gv.FloopaHub.__BypassActive) do
            if v then anyActive = true break end
        end

        -- Bloqueo Kick siempre
        if method == "Kick" then
            warn("[FloopaHub] Kick bloqueado.")
            return nil
        end

        if (method=="FireServer" or method=="InvokeServer") and typeof(self)=="Instance" then
            if anyActive and shouldBlock(nameLower) then
                warn("[FloopaHub] Remote sospechoso bloqueado: "..self.Name)
                return nil
            end
            if anyActive then
                for i=1,#args do
                    args[i] = clampArg(args[i])
                end
            end
        end

        return original.__namecall(self, unpack(args))
    end

    mt.__namecall = newcclosure(hooked)
    setreadonly(mt, true)

    -- API pública del bypass local
    gv.FloopaHub.__Original = original
    gv.FloopaHub.__HookFn = hooked
    gv.FloopaHub.__BypassReady = true

    function gv.FloopaHub.EnableBypass(cmdName)
        gv.FloopaHub.__BypassActive[cmdName or "Generic"] = true
    end
    function gv.FloopaHub.DisableBypass(cmdName)
        gv.FloopaHub.__BypassActive[cmdName or "Generic"] = nil
    end
    function gv.FloopaHub.RestoreBypass()
        local mt2 = getrawmetatable(game)
        setreadonly(mt2, false)
        mt2.__namecall = gv.FloopaHub.__Original and gv.FloopaHub.__Original.__namecall or mt2.__namecall
        setreadonly(mt2, true)
        gv.FloopaHub.__BypassReady = false
    end

    -- Watchdog ligero (reaplica si lo quitan)
    task.spawn(function()
        while true do
            task.wait(8)
            local mtCheck = getrawmetatable(game)
            if gv.FloopaHub.__HookFn and mtCheck.__namecall ~= gv.FloopaHub.__HookFn then
                setreadonly(mtCheck, false)
                mtCheck.__namecall = newcclosure(gv.FloopaHub.__HookFn)
                setreadonly(mtCheck, true)
                warn("[FloopaHub] Bypass local reaplicado.")
            end
        end
    end)

    return true
end

-- 1) Cargar bypass externo (si falla, usamos el local integrado)
local function loadExternalBypass()
    local ok = false
    local result = safeLoad("https://raw.githubusercontent.com/santiago637/Scripts/main/Bypass.lua")
    if type(result) == "table" or next(gv.FloopaHub) ~= nil then
        -- suponer que el externo definió EnableBypass/DisableBypass
        ok = (type(gv.FloopaHub.EnableBypass) == "function" and type(gv.FloopaHub.DisableBypass) == "function")
    end
    return ok
end

local bypassOk = loadExternalBypass()
if not bypassOk then
    notifySafe("Floopa Hub", "Bypass externo no disponible, usando respaldo local", 3)
    ensureLocalBypass()
end
-- doble garantía: si no existen, proveer alias a respaldo local
if type(gv.FloopaHub.EnableBypass) ~= "function" or type(gv.FloopaHub.DisableBypass) ~= "function" then
    ensureLocalBypass()
end

-- 2) Cargar comandos
local Commands = safeLoad("https://raw.githubusercontent.com/santiago637/Scripts/main/ModuleScriptContainer.lua")

-- safeCall protegido: activa bypass temporalmente y captura errores
local function safeCall(func, cmdName, ...)
    if typeof(func) ~= "function" then
        notifySafe("Floopa Hub", "Comando no implementado", 2)
        return false
    end

    -- Activa bypass para la ventana de ejecución (si el juego intenta bloquear exec)
    local tag = cmdName or "SafeCall"
    local prev = gv.FloopaHub.__BypassActive[tag]
    gv.FloopaHub.EnableBypass(tag)

    local ok, res = pcall(func, ...)
    if not ok then
        warn("[FloopaHub] Error ejecutando comando:", res)
        notifySafe("Floopa Hub", "Error: "..tostring(res), 2)
        gv.FloopaHub.__BypassActive[tag] = prev -- restaurar estado previo
        gv.FloopaHub.DisableBypass(tag)
        return false
    end

    -- Restaurar estado
    gv.FloopaHub.__BypassActive[tag] = prev
    gv.FloopaHub.DisableBypass(tag)
    return res ~= false
end

-- Aliases
local aliases = {
    ["fly"]="fly", ["unfly"]="unfly",
    ["noclip"]="noclip", ["unnoclip"]="unnoclip",
    ["walkspeed"]="walkspeed", ["speed"]="walkspeed", ["ws"]="walkspeed",
    ["unwalkspeed"]="unwalkspeed",
    ["jumppower"]="jumppower", ["jp"]="jumppower", ["unjumppower"]="unjumppower",
    ["esp"]="esp", ["unesp"]="unesp",
    ["xray"]="xray", ["unxray"]="unxray",
    ["killaura"]="killaura", ["ka"]="killaura", ["unkillaura"]="unkillaura",
    ["handlekill"]="handlekill", ["hkill"]="handlekill", ["unhandlekill"]="unhandlekill",
    ["aimbot"]="aimbot", ["aim"]="aimbot", ["unaimbot"]="unaimbot",
    ["infinitejump"]="infinitejump", ["infjump"]="infinitejump", ["uninfinitejump"]="uninfinitejump"
}

-- Dispatcher con integración fuerte de bypass
local function executeCommand(text)
    if typeof(text) ~= "string" or text == "" then
        notifySafe("Floopa Hub", "Comando vacío", 2)
        return false
    end

    local args = string.split(text, " ")
    local rawCmd = args[1] and args[1]:lower()
    local cmd = aliases[rawCmd] or rawCmd
    local arg = args[2]

    if cmd == "fly" then
        gv.FloopaHub.EnableBypass("Fly")
        return safeCall(Commands.Fly, "Fly", arg, false)
    elseif cmd == "unfly" then
        local r = safeCall(Commands.Fly, "Fly", nil, true)
        gv.FloopaHub.DisableBypass("Fly")
        return r

    elseif cmd == "noclip" then
        gv.FloopaHub.EnableBypass("Noclip")
        return safeCall(Commands.Noclip, "Noclip", false)
    elseif cmd == "unnoclip" then
        local r = safeCall(Commands.Noclip, "Noclip", true)
        gv.FloopaHub.DisableBypass("Noclip")
        return r

    elseif cmd == "walkspeed" then
        return safeCall(Commands.WalkSpeed, "WalkSpeed", arg)
    elseif cmd == "unwalkspeed" then
        return safeCall(Commands.WalkSpeed, "WalkSpeed", 16)

    elseif cmd == "jumppower" then
        return safeCall(Commands.JumpPower, "JumpPower", arg, false)
    elseif cmd == "unjumppower" then
        return safeCall(Commands.JumpPower, "JumpPower", nil, true)

    elseif cmd == "esp" then
        return safeCall(Commands.ESP, "ESP", false)
    elseif cmd == "unesp" then
        return safeCall(Commands.ESP, "ESP", true)

    elseif cmd == "xray" then
        return safeCall(Commands.XRay, "XRay", arg, false)
    elseif cmd == "unxray" then
        return safeCall(Commands.XRay, "XRay", nil, true)

    elseif cmd == "killaura" then
        gv.FloopaHub.EnableBypass("Killaura")
        return safeCall(Commands.Killaura, "Killaura", arg, false)
    elseif cmd == "unkillaura" then
        local r = safeCall(Commands.Killaura, "Killaura", nil, true)
        gv.FloopaHub.DisableBypass("Killaura")
        return r

    elseif cmd == "handlekill" then
        gv.FloopaHub.EnableBypass("HandleKill")
        return safeCall(Commands.HandleKill, "HandleKill", arg, false)
    elseif cmd == "unhandlekill" then
        local r = safeCall(Commands.HandleKill, "HandleKill", nil, true)
        gv.FloopaHub.DisableBypass("HandleKill")
        return r

    elseif cmd == "aimbot" then
        gv.FloopaHub.EnableBypass("Aimbot")
        return safeCall(Commands.Aimbot, "Aimbot", arg, false)
    elseif cmd == "unaimbot" then
        local r = safeCall(Commands.Aimbot, "Aimbot", nil, true)
        gv.FloopaHub.DisableBypass("Aimbot")
        return r

    elseif cmd == "infinitejump" then
        return safeCall(Commands.InfiniteJump, "InfiniteJump", true)
    elseif cmd == "uninfinitejump" then
        return safeCall(Commands.InfiniteJump, "InfiniteJump", false)

    else
        warn("[FloopaHub] Comando no reconocido:", text)
        notifySafe("Floopa Hub", "Comando desconocido: "..tostring(text), 2)
        return false
    end
end

local export = { ExecuteCommand = executeCommand }
gv.FloopaHub.MainLocal = export
return export