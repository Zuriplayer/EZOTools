-- Utilidades compartidas entre módulos de EZOTools.
-- Funciones que se necesitan en más de un módulo y no pertenecen a ninguno en particular.

-- ============================================================
-- AsegurarDefectos
-- Garantiza que los valores de mantenimiento existen en sv.
-- Usada por menu.lua y gamepad_settings.lua.
-- ============================================================
function EZOTools_AsegurarDefectos()
    local sv = EZOTools and EZOTools.sv
    if not sv then return end
    sv.general = sv.general or {}
    if type(sv.general.repairThreshold) ~= "number" then
        sv.general.repairThreshold = 40
    end
    if type(sv.general.rechargeThreshold) ~= "number" then
        sv.general.rechargeThreshold = 50
    end
end

-- ============================================================
-- ExtraerCallback
-- Extrae el callback ejecutable de un dato de entrada de lista gamepad.
-- Soporta múltiples formatos de ZO_GamepadEntryData y userdata.
-- Usada por gamepad_dialog.lua y gamepad_settings.lua.
-- ============================================================
function EZOTools_ExtraerCallback(data)
    local t = type(data)
    if t == "function" then return data end

    -- Userdata con GetDataSource (scroll lists de ESO)
    if t == "userdata" then
        local ok, ds = pcall(function()
            if data and data.GetDataSource then return data:GetDataSource() end
            return nil
        end)
        if ok and ds ~= nil then return EZOTools_ExtraerCallback(ds) end
        return nil
    end

    if t ~= "table" then return nil end

    -- Callback directo
    if type(data.callback) == "function" then return data.callback end

    -- Wrappers comunes de ZO_GamepadEntryData (profundidad 1)
    local candidatos = {
        data.entryData, data.data, data.dataSource,
        data.m_data, data.source, data.value
    }
    for _, c in ipairs(candidatos) do
        if type(c) == "table" then
            if type(c.callback) == "function" then return c.callback end
            if type(c.entryData) == "table" and type(c.entryData.callback) == "function" then
                return c.entryData.callback
            end
            if type(c.data) == "table" and type(c.data.callback) == "function" then
                return c.data.callback
            end
        elseif type(c) == "userdata" or type(c) == "function" then
            local cb = EZOTools_ExtraerCallback(c)
            if cb then return cb end
        end
    end

    return nil
end
