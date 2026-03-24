-- Registro de secciones para el panel LibAddonMenu de EZOTools.
-- Los módulos llaman a RegisterSection() para añadir sus opciones.
-- menu.lua las recoge y construye el panel LAM completo.

EZOTools_LAM = EZOTools_LAM or {}
local REG = EZOTools_LAM
REG._sections = REG._sections or {}

-- Registra una sección de opciones.
-- name:     identificador único de la sección
-- order:    número de orden (menor = antes)
-- provider: función que devuelve la tabla de opciones LAM
function REG.RegisterSection(name, order, provider)
    REG._sections[name] = { order = order or 100, provider = provider }
end

-- Devuelve todas las opciones de todas las secciones ordenadas por 'order'
function REG.GetSortedOptions()
    local lista = {}
    for k, v in pairs(REG._sections) do
        lista[#lista + 1] = { name = k, order = v.order, provider = v.provider }
    end
    table.sort(lista, function(a, b) return a.order < b.order end)

    local opciones = {}
    for _, s in ipairs(lista) do
        local ok, contenido = pcall(s.provider)
        if ok and type(contenido) == "table" then
            for _, x in ipairs(contenido) do
                opciones[#opciones + 1] = x
            end
        end
    end
    return opciones
end
