local gv = getgenv()
gv.FloopaHub = gv.FloopaHub or {}

-- Estado
local active = {}
local installed = false
local original = nil
local hookFn = nil
local stopWatchdog = false

-- Config
local BLACKLIST = {"ban","report","anti","log","kick","fly","speed","noclip"}
local WHITELIST = {"antique","reportcard"} 
local WATCHDOG_INTERVAL = 8 
local LOG = false 

local function logWarn(...)
    if LOG then warn(...) end
end

-- Utils
local function lower(s)
    local ok, r = pcall(function() return string.lower(tostring(s)) end)
    return ok and r or ""
end

local function safeClass(inst)
    local ok, r = pcall(function() return inst.ClassName end)
    return ok and r or ""
end

local function pathSignature(inst)
    -- Firma ligera del contexto: nombre + clase padre inmediata
    local ok, parent = pcall(function() return inst.Parent end)
    local name = lower(inst and inst.Name or "")
    local pclass = lower(parent and parent.ClassName or "")
    return name .. "|" .. pclass
end

local function shouldBlock(inst)
    if typeof(inst) ~= "Instance" then return false end
    local nameLower = lower(inst.Name)
    for _, allow in ipairs(WHITELIST) do
        if string.find(nameLower, allow, 1, true) then
            return false
        end
    end
    for _, bad in ipairs(BLACKLIST) do
        if string.find(nameLower, bad, 1, true) then
            return true
        end
    end
    -- Heurística adicional por firma de ruta
    local sig = pathSignature(inst)
    if string.find(sig, "kick", 1, true) or string.find(sig, "ban", 1, true) then
        return true
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
    elseif typeof(a) == "CFrame" then
        local p = a.Position
        local nx = math.clamp(p.X, -220, 220)
        local ny = math.clamp(p.Y, -220, 220)
        local nz = math.clamp(p.Z, -220, 220)
        return CFrame.new(nx, ny, nz)
    elseif typeof(a) == "string" then
        local s = lower(a)
        -- Sanitizar cadenas sospechosas en modo activo
        for _, bad in ipairs(BLACKLIST) do
            if string.find(s, bad, 1, true) then
                return ""
            end
        end
        return a
    elseif typeof(a) == "table" then
        local copy = {}
        for k, v in pairs(a) do
            local kl = lower(k)
            if string.find(kl, "fly", 1, true) or string.find(kl, "noclip", 1, true) or string.find(kl, "speed", 1, true) then
                copy[k] = false
            else
                copy[k] = clampArg(v)
            end
        end
        return copy
    end
    return a
end

local function anyActive()
    for _, v in pairs(active) do
        if v then return true end
    end
    return false
end

local function installHook()
    if installed then return true end
    local mt = getrawmetatable(game)
    if not mt then return false end

    original = { __namecall = mt.__namecall }
    setreadonly(mt, false)

    hookFn = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Bloquear Kick siempre
        if method == "Kick" then
            logWarn("[FloopaHub] Kick bloqueado.")
            return nil
        end

        -- Solo procesar si hay comandos activos
        if anyActive() and typeof(self) == "Instance" then
            local cls = safeClass(self)
            if (method == "FireServer" or method == "InvokeServer") then
                if shouldBlock(self) then
                    logWarn("[FloopaHub] Remote bloqueado: " .. tostring(self.Name))
                    return nil
                end
                -- Sanitización de argumentos
                for i = 1, #args do
                    args[i] = clampArg(args[i])
                end
            end
        end

        return original.__namecall(self, table.unpack(args))
    end)

    mt.__namecall = hookFn
    setreadonly(mt, true)
    installed = true
    stopWatchdog = false

    -- Watchdog inteligente (solo cuando hook está instalado)
    task.spawn(function()
        while installed and not stopWatchdog do
            task.wait(WATCHDOG_INTERVAL)
            local mtCheck = getrawmetatable(game)
            if mtCheck and mtCheck.__namecall ~= hookFn then
                setreadonly(mtCheck, false)
                mtCheck.__namecall = hookFn
                setreadonly(mtCheck, true)
                logWarn("[FloopaHub] Hook reaplicado por watchdog.")
            end
        end
    end)

    return true
end

local function removeHookIfIdle()
    -- if not anyActive() and installed then
    --     local mt = getrawmetatable(game)
    --     setreadonly(mt, false)
    --     mt.__namecall = original and original.__namecall or mt.__namecall
    --     setreadonly(mt, true)
    --     installed = false
    --     stopWatchdog = true
    --     original = nil
    --     hookFn = nil
    -- end
end

-- API pública
function gv.FloopaHub.EnableBypass(cmdName)
    active[cmdName or "Generic"] = true
    installHook()
end

function gv.FloopaHub.DisableBypass(cmdName)
    active[cmdName or "Generic"] = nil
    removeHookIfIdle()
end

-- Opcional: reset manual completo
function gv.FloopaHub.RestoreBypass()
    local mt = getrawmetatable(game)
    if mt and original then
        setreadonly(mt, false)
        mt.__namecall = original.__namecall
        setreadonly(mt, true)
    end
    installed = false
    stopWatchdog = true
    original = nil
    hookFn = nil
    active = {}
end
