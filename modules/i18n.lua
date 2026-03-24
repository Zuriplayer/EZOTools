-- Sistema de internacionalización de EZOTools.
-- Aplica las cadenas del idioma elegido usando ZO_CreateStringId / SafeAddString.
-- Se llama desde EZOTools:Initialize() y desde el setter del dropdown de idioma en LAM.
EZO_Lang = EZO_Lang or {}

local function AplicarCadena(id, val)
    local gid = _G[id]
    -- Si la constante SI_* todavía no existe en el juego, la creamos
    if gid == nil then
        ZO_CreateStringId(id, val)
    else
        -- Si ya existe (keybind nativo, string del juego) la sobreescribimos con prioridad 1
        SafeAddString(gid, val, 1)
    end
end

function EZO_Lang.Apply(lang)
    local src = (lang == "es" and EZO_STRINGS_ES) or EZO_STRINGS_EN
    if not src then return end
    for k, v in pairs(src) do
        AplicarCadena(k, v)
    end
    EZO_Lang.current = (lang == "es") and "es" or "en"
end
