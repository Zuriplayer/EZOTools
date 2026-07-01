-- Configuración de luacheck para EZOTools (addon de ESO).
-- El entorno Lua de ESO expone miles de globals (API, ZO_*, eventos, constantes),
-- así que no se valida la existencia de globals leídos: la referencia real es UESP.
-- luacheck aquí sirve para: errores de sintaxis, variables no usadas, shadowing
-- y escrituras accidentales a globals.

std = "lua51"

-- No avisar por leer globals desconocidos (API de ESO) ni por el namespace propio.
ignore = {
    "113",        -- accessing undefined global (toda la API de ESO)
    "111/EZO.*",  -- setting globals del namespace del addon (EZOTools_*, EZO_*)
    "112/EZO.*",  -- mutating globals del namespace del addon
    "211/_.*",    -- unused variable con prefijo _
}

-- Tablas de ESO que los addons mutan legítimamente.
globals = {
    "SLASH_COMMANDS",
}

-- Ficheros generados o de terceros.
exclude_files = {
    "dist/**",
    "libs/**",
}

max_line_length = false
