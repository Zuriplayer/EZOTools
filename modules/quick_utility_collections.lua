-- Helpers comunes para abrir colecciones desde utilidades rapidas.
-- Centraliza rutas delicadas compartidas por aliados, casas y futuros proveedores.
EZOTools_QuickUtilityCollections = EZOTools_QuickUtilityCollections or {}

local MOD = EZOTools_QuickUtilityCollections
local EZO = EZOTools

if EZO then
    EZO.QuickUtilityCollections = MOD
end

-- Versión única en shared_utils.lua
local EsModoGamepadPreferido = EZOTools_EsModoGamepadPreferido

local function ExisteEscena(sceneName)
    if type(sceneName) ~= "string" or sceneName == "" then
        return false
    end
    if SCENE_MANAGER and type(SCENE_MANAGER.GetScene) == "function" then
        return SCENE_MANAGER:GetScene(sceneName) ~= nil
    end
    return true
end

local function MostrarEscena(sceneName)
    if type(sceneName) ~= "string" or sceneName == "" then
        return false
    end
    if SCENE_MANAGER and type(SCENE_MANAGER.Show) == "function" and ExisteEscena(sceneName) then
        SCENE_MANAGER:Show(sceneName)
        return true
    end
    return false
end

local function MostrarEscenaGamepadColecciones()
    if SCENE_MANAGER and type(SCENE_MANAGER.CreateStackFromScratch) == "function" and ExisteEscena("gamepadCollectionsBook") then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadCollectionsBook")
        return true
    end
    return MostrarEscena("gamepadCollectionsBook")
end

local function MostrarEscenaMenuKeyboard(sceneName)
    if type(sceneName) ~= "string" or sceneName == "" then
        return false
    end
    if MAIN_MENU_KEYBOARD and type(MAIN_MENU_KEYBOARD.ShowScene) == "function" and ExisteEscena(sceneName) then
        MAIN_MENU_KEYBOARD:ShowScene(sceneName)
        return true
    end
    return MostrarEscena(sceneName)
end

local function DebeAlternarGrupoEscena(options)
    return type(options) == "table" and options.keyboardToggleSceneGroup == true
end

function MOD.GetFirstCollectibleByCategory(categoryType)
    if categoryType == nil or type(GetTotalCollectiblesByCategoryType) ~= "function"
        or type(GetCollectibleIdFromType) ~= "function" then
        return 0
    end
    local total = tonumber(GetTotalCollectiblesByCategoryType(categoryType)) or 0
    for index = 1, total do
        local collectibleId = tonumber(GetCollectibleIdFromType(categoryType, index)) or 0
        if collectibleId > 0 then
            return collectibleId
        end
    end
    return 0
end

function MOD.GetRootCategoryByType(categoryType)
    if categoryType == nil or not ZO_COLLECTIBLE_DATA_MANAGER or type(ZO_COLLECTIBLE_DATA_MANAGER.CategoryIterator) ~= "function" then
        return nil
    end

    local filtros = nil
    if ZO_CollectibleCategoryData and type(ZO_CollectibleCategoryData.HasShownCollectiblesInCollection) == "function" then
        filtros = { ZO_CollectibleCategoryData.HasShownCollectiblesInCollection }
    end

    for _, categoryData in ZO_COLLECTIBLE_DATA_MANAGER:CategoryIterator(filtros) do
        if categoryData and type(categoryData.IsTopLevelCategory) == "function" and categoryData:IsTopLevelCategory() then
            if type(categoryData.GetCollectibleCategoryTypesInCategory) == "function" then
                local categoryTypes = categoryData:GetCollectibleCategoryTypesInCategory()
                if categoryTypes and categoryTypes[categoryType] == true then
                    return categoryData
                end
            end
        end
    end

    return nil
end

function MOD.OpenBook(options)
    if EsModoGamepadPreferido() then
        return MostrarEscenaGamepadColecciones()
    end
    if DebeAlternarGrupoEscena(options)
        and MAIN_MENU_KEYBOARD
        and type(MAIN_MENU_KEYBOARD.ToggleSceneGroup) == "function" then
        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "collectionsBook")
        return true
    end
    return MostrarEscenaMenuKeyboard("collectionsBook")
end

function MOD.OpenByCollectible(collectibleId, options)
    local finalId = tonumber(collectibleId) or 0
    if finalId > 0 and COLLECTIONS_BOOK_SINGLETON and type(COLLECTIONS_BOOK_SINGLETON.BrowseToCollectible) == "function" then
        COLLECTIONS_BOOK_SINGLETON:BrowseToCollectible(finalId)
        return true
    end
    return MOD.OpenBook(options)
end

local function SeleccionarCategoriaRaizColeccionesKeyboard(categoryData, options)
    if not categoryData or not COLLECTIONS_BOOK then
        return false
    end
    if type(COLLECTIONS_BOOK.PerformDeferredInitialize) == "function" then
        COLLECTIONS_BOOK:PerformDeferredInitialize()
    end
    if COLLECTIONS_BOOK.refreshGroups and type(COLLECTIONS_BOOK.refreshGroups.UpdateRefreshGroups) == "function" then
        COLLECTIONS_BOOK.refreshGroups:UpdateRefreshGroups()
    end

    local categoryId = type(categoryData.GetId) == "function" and categoryData:GetId() or nil
    local categoryNode = categoryId and COLLECTIONS_BOOK.categoryNodeLookupData and COLLECTIONS_BOOK.categoryNodeLookupData[categoryId] or nil
    if categoryNode and COLLECTIONS_BOOK.categoryTree then
        if type(categoryNode.IsLeaf) == "function" and categoryNode:IsLeaf() and type(COLLECTIONS_BOOK.categoryTree.SelectNode) == "function" then
            COLLECTIONS_BOOK.categoryTree:SelectNode(categoryNode)
        elseif type(COLLECTIONS_BOOK.categoryTree.SetNodeOpen) == "function" then
            COLLECTIONS_BOOK.categoryTree:SetNodeOpen(categoryNode, true)
        else
            return false
        end
    else
        return false
    end

    if DebeAlternarGrupoEscena(options)
        and MAIN_MENU_KEYBOARD
        and type(MAIN_MENU_KEYBOARD.ToggleSceneGroup) == "function" then
        MAIN_MENU_KEYBOARD:ToggleSceneGroup("collectionsSceneGroup", "collectionsBook")
        return true
    end
    return MostrarEscenaMenuKeyboard("collectionsBook")
end

local function SeleccionarCategoriaRaizColeccionesGamepad(categoryType, options)
    if categoryType == nil then
        return false
    end
    if not MOD.OpenBook(options) then
        return false
    end

    local function seleccionarCategoria()
        local categoryData = MOD.GetRootCategoryByType(categoryType)
        if GAMEPAD_COLLECTIONS_BOOK and type(GAMEPAD_COLLECTIONS_BOOK.ViewCategory) == "function" then
            pcall(function()
                if categoryData then
                    GAMEPAD_COLLECTIONS_BOOK:ViewCategory(categoryData)
                end
            end)
        end
    end

    local scene = SCENE_MANAGER and type(SCENE_MANAGER.GetScene) == "function" and SCENE_MANAGER:GetScene("gamepadCollectionsBook") or nil
    if scene and type(scene.GetState) == "function" and scene:GetState() == SCENE_SHOWN then
        seleccionarCategoria()
    elseif scene and type(scene.RegisterCallback) == "function" and type(scene.UnregisterCallback) == "function" then
        local callback
        callback = function(_, newState)
            if newState == SCENE_SHOWN then
                scene:UnregisterCallback("StateChange", callback)
                seleccionarCategoria()
            end
        end
        scene:RegisterCallback("StateChange", callback)
    elseif type(zo_callLater) == "function" then
        zo_callLater(seleccionarCategoria, 100)
    else
        seleccionarCategoria()
    end
    return true
end

function MOD.OpenRootByCategoryType(categoryType, options)
    if EsModoGamepadPreferido() then
        if SeleccionarCategoriaRaizColeccionesGamepad(categoryType, options) then
            return true
        end
    else
        local categoryData = MOD.GetRootCategoryByType(categoryType)
        if categoryData and SeleccionarCategoriaRaizColeccionesKeyboard(categoryData, options) then
            return true
        end
    end

    return MOD.OpenByCollectible(MOD.GetFirstCollectibleByCategory(categoryType), options)
end

function MOD.OpenFirstByCategoryType(categoryType, options)
    return MOD.OpenByCollectible(MOD.GetFirstCollectibleByCategory(categoryType), options)
end
