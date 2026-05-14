-- Sistema de internacionalización de EZOTools.
-- Aplica las cadenas del idioma elegido usando ZO_CreateStringId / SafeAddString.
-- Se llama desde EZOTools:Initialize() y desde el setter del dropdown de idioma en LAM.
EZO_Lang = EZO_Lang or {}

local function AplicarCadena(id, val, version)
    local gid = _G[id]
    -- Si la constante SI_* todavía no existe en el juego, la creamos
    if gid == nil then
        ZO_CreateStringId(id, val)
        gid = _G[id]
    end

    if gid ~= nil then
        -- SafeAddString solo reemplaza si la versión sube. Usar una versión
        -- fija puede mezclar idiomas al cambiar la opción sin /reloadui.
        SafeAddString(gid, val, version)
    end
end

function EZO_Lang.Apply(lang)
    local mode = lang
    local resolved = lang
    if EZOTools and type(EZOTools.ResolveLanguage) == "function" then
        mode, resolved = EZOTools.ResolveLanguage(lang)
    else
        resolved = (lang == "es") and "es" or "en"
        mode = resolved
    end

    local src = (resolved == "es" and EZO_STRINGS_ES) or EZO_STRINGS_EN
    if not src then return end
    EZO_Lang._stringVersion = (tonumber(EZO_Lang._stringVersion) or 0) + 1
    for k, v in pairs(src) do
        AplicarCadena(k, v, EZO_Lang._stringVersion)
    end
    EZO_Lang.mode = tostring(mode or "auto")
    EZO_Lang.current = (resolved == "es") and "es" or "en"
end
