-- Módulo enrutador de entrada de EZOTools.
-- Recibe llamadas de diferentes orígenes (ratón, gamepad, keybind) y las dirige
-- al ejecutor centralizado de acciones.

EZOTools_InputRouter = EZOTools_InputRouter or {}
local R = EZOTools_InputRouter

-- Dispara una acción por ID desde un origen dado.
-- source: "MENU", "KEYBIND", "MOUSE", etc.
-- actionId: ID de la acción registrada en EZOTools_ActionExec
-- ctx: tabla de contexto adicional (opcional)
function R.Trigger(source, actionId, ctx)
    ctx = ctx or {}
    ctx.source = source or "UNKNOWN"
    if _G.EZOTools_ActionExec and type(_G.EZOTools_ActionExec.Execute) == "function" then
        return _G.EZOTools_ActionExec.Execute(actionId, ctx)
    end
    return false
end
