local MenuLib = {}
local IS_MENU_OPEN = false
local IN_SUB_MENU = false
local SELECTED_INDEX = 1
local SUB_MENU_INDEX = 1
local MAX_VISIBLE_ITEMS = 7
local LAST_NAV_TIME = 0
local LAST_HORIZONTAL_NAV_TIME = 0
local NAV_REPEAT = 150
local HORIZONTAL_NAV_REPEAT = 50
local OPEN_KEY = 288

local MENU_CONFIG = {
    title = "Menu",
    mainTitle = "Menu",
    color = { 51, 51, 255, 255 },
    x = 0.86,
    y = 0.09,
    width = 0.2,
    titleHeight = 0.065,
    itemHeight = 0.04,
    soundEnabled = true
}

local MENU_ITEMS = {}

local function draw_textured_rect(x, y, width, height, bg_color, text_color, text, font, scale, center)
    DrawRect(x, y, width, height, bg_color[1], bg_color[2], bg_color[3], bg_color[4])
    SetTextFont(font or 0)
    SetTextScale(scale or 0.3, scale or 0.3)
    SetTextColour(text_color[1], text_color[2], text_color[3], text_color[4])
    SetTextCentre(center or false)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if center then
        DrawText(x, y - height / 3)
    else
        DrawText(x - 0.09, y - height / 3)
    end
end

local function draw_menu_title(x, y, width, height, title)
    DrawRect(x, y, width, height, MENU_CONFIG.color[1], MENU_CONFIG.color[2], MENU_CONFIG.color[3], MENU_CONFIG.color[4])
    SetTextFont(1)
    SetTextScale(0.65, 0.65)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(title)
    DrawText(x, y - height / 3)
end

local function get_visible_range(total_items, current_index)
    if total_items <= MAX_VISIBLE_ITEMS then
        return 1, total_items
    else
        local first_index = math.max(1, current_index - MAX_VISIBLE_ITEMS + 1)
        local last_index = math.min(total_items, first_index + MAX_VISIBLE_ITEMS - 1)
        return first_index, last_index
    end
end

local function draw_main_menu(x, y, width, title_height, item_height)
    local total_items = #MENU_ITEMS
    local first_index, last_index = get_visible_range(total_items, SELECTED_INDEX)
    local last_y = y + title_height
    for i = first_index, last_index do
        local item = MENU_ITEMS[i]
        local y_pos = y + ((i - first_index + 0.5) * item_height) + title_height / 2
        last_y = y_pos + item_height / 2
        local is_selected = i == SELECTED_INDEX
        local bg_color = is_selected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local text_color = is_selected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        local display_name = type(item.name) == "function" and item.name() or item.name
        draw_textured_rect(x, y_pos, width, item_height, bg_color, text_color, display_name)
    end
    return last_y
end

local function draw_generic_sub_menu(x, y, width, title_height, item_height)
    local current_item = MENU_ITEMS[SELECTED_INDEX]
    local sub_menu = type(current_item.subMenu) == "function" and current_item.subMenu() or current_item.subMenu
    local total_items = #sub_menu
    local first_index, last_index = get_visible_range(total_items, SUB_MENU_INDEX)
    local last_y = y + title_height
    for i = first_index, last_index do
        local item = sub_menu[i]
        local y_pos = y + ((i - first_index + 0.5) * item_height) + title_height / 2
        last_y = y_pos + item_height / 2
        local is_selected = i == SUB_MENU_INDEX
        local bg_color = is_selected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local text_color = is_selected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        local display_text = type(item) == "table" and (type(item.name) == "function" and item.name() or item.name) or item
        draw_textured_rect(x, y_pos, width, item_height, bg_color, text_color, display_text)
    end
    return last_y
end

local function draw_menu()
    if not IS_MENU_OPEN then
        return
    end
    draw_menu_title(MENU_CONFIG.x, MENU_CONFIG.y, MENU_CONFIG.width, MENU_CONFIG.titleHeight, MENU_CONFIG.title)
    if IN_SUB_MENU then
        draw_generic_sub_menu(MENU_CONFIG.x, MENU_CONFIG.y, MENU_CONFIG.width, MENU_CONFIG.titleHeight, MENU_CONFIG.itemHeight)
    else
        draw_main_menu(MENU_CONFIG.x, MENU_CONFIG.y, MENU_CONFIG.width, MENU_CONFIG.titleHeight, MENU_CONFIG.itemHeight)
    end
end

local function wrap_index(index, max)
    return ((index - 1) % max) + 1
end

local function navigate_menu(direction)
    if direction == "up" then
        if IN_SUB_MENU then
            local current_item = MENU_ITEMS[SELECTED_INDEX]
            local sub_menu = type(current_item.subMenu) == "function" and current_item.subMenu() or current_item.subMenu
            SUB_MENU_INDEX = wrap_index(SUB_MENU_INDEX - 1, #sub_menu)
        else
            SELECTED_INDEX = wrap_index(SELECTED_INDEX - 1, #MENU_ITEMS)
        end
    elseif direction == "down" then
        if IN_SUB_MENU then
            local current_item = MENU_ITEMS[SELECTED_INDEX]
            local sub_menu = type(current_item.subMenu) == "function" and current_item.subMenu() or current_item.subMenu
            SUB_MENU_INDEX = wrap_index(SUB_MENU_INDEX + 1, #sub_menu)
        else
            SELECTED_INDEX = wrap_index(SELECTED_INDEX + 1, #MENU_ITEMS)
        end
    end
    if MENU_CONFIG.soundEnabled then
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function confirm_selection()
    if not IN_SUB_MENU then
        local item = MENU_ITEMS[SELECTED_INDEX]
        if item.subMenu then
            IN_SUB_MENU = true
            SUB_MENU_INDEX = 1
            if item.subMenuTitle then
                MENU_CONFIG.title = item.subMenuTitle
            else
                local itemName = type(item.name) == "function" and item.name() or item.name
                MENU_CONFIG.title = itemName
            end
        elseif item.onSelect then
            item.onSelect()
        end
    else
        local current_item = MENU_ITEMS[SELECTED_INDEX]
        local sub_menu = type(current_item.subMenu) == "function" and current_item.subMenu() or current_item.subMenu
        local selected_sub_item = sub_menu[SUB_MENU_INDEX]
        if type(selected_sub_item) == "table" and selected_sub_item.onSelect then
            selected_sub_item.onSelect()
        end
    end
    if MENU_CONFIG.soundEnabled then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function go_back()
    if IN_SUB_MENU then
        IN_SUB_MENU = false
        SUB_MENU_INDEX = 1
        MENU_CONFIG.title = MENU_CONFIG.mainTitle
    else
        IS_MENU_OPEN = false
        IN_SUB_MENU = false
    end
    if MENU_CONFIG.soundEnabled then
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function process_controls()
    if not IS_MENU_OPEN then
        return
    end
    local now = GetGameTimer()
    if IsControlPressed(0, 172) and now - LAST_NAV_TIME > NAV_REPEAT then
        navigate_menu("up")
        LAST_NAV_TIME = now
    end
    if IsControlPressed(0, 173) and now - LAST_NAV_TIME > NAV_REPEAT then
        navigate_menu("down")
        LAST_NAV_TIME = now
    end
    if IsControlPressed(0, 246) and now - LAST_NAV_TIME > NAV_REPEAT then
        navigate_menu("up")
        LAST_NAV_TIME = now
    end
    if IsControlPressed(0, 74) and now - LAST_NAV_TIME > NAV_REPEAT then
        navigate_menu("down")
        LAST_NAV_TIME = now
    end
    if IN_SUB_MENU then
        local current_item = MENU_ITEMS[SELECTED_INDEX]
        local sub_menu = type(current_item.subMenu) == "function" and current_item.subMenu() or current_item.subMenu
        local selected_sub_item = sub_menu[SUB_MENU_INDEX]
        if type(selected_sub_item) == "table" then
            if (IsControlPressed(0, 175) or IsControlPressed(0, 96)) and now - LAST_HORIZONTAL_NAV_TIME > HORIZONTAL_NAV_REPEAT then
                if selected_sub_item.onRight then
                    selected_sub_item.onRight()
                    LAST_HORIZONTAL_NAV_TIME = now
                    if MENU_CONFIG.soundEnabled then
                        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                end
            end
            if (IsControlPressed(0, 174) or IsControlPressed(0, 97)) and now - LAST_HORIZONTAL_NAV_TIME > HORIZONTAL_NAV_REPEAT then
                if selected_sub_item.onLeft then
                    selected_sub_item.onLeft()
                    LAST_HORIZONTAL_NAV_TIME = now
                    if MENU_CONFIG.soundEnabled then
                        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    end
                end
            end
        end
    end
    if IsControlJustReleased(0, 201) then
        confirm_selection()
    end
    if IsControlJustReleased(0, 194) then
        go_back()
    end
end

function MenuLib.CreateMenu(title, subtitle, x, y, color)
    MENU_CONFIG.title = title or "Menu"
    MENU_CONFIG.mainTitle = title or "Menu"
    if color then
        MENU_CONFIG.color = color
    end
    if x then
        MENU_CONFIG.x = x
    end
    if y then
        MENU_CONFIG.y = y
    end
    return MenuLib
end

function MenuLib.AddButton(name, callback)
    table.insert(MENU_ITEMS, {
        name = name,
        onSelect = callback
    })
    return MenuLib
end

function MenuLib.AddSubMenu(name, subMenuTitle)
    local subMenuItems = {}
    local subMenu = {
        name = name,
        subMenuTitle = subMenuTitle or name,
        subMenu = function()
            return subMenuItems
        end,
        _items = subMenuItems
    }
    table.insert(MENU_ITEMS, subMenu)
    return {
        AddButton = function(btnName, callback)
            table.insert(subMenuItems, {
                name = btnName,
                onSelect = callback
            })
            return subMenu
        end,
        AddList = function(listName, items, defaultIndex, onChange)
            local currentIndex = defaultIndex or 1
            table.insert(subMenuItems, {
                name = function()
                    return listName .. ": " .. items[currentIndex]
                end,
                onSelect = function()
                    currentIndex = currentIndex % #items + 1
                    if onChange then
                        onChange(currentIndex, items[currentIndex])
                    end
                end
            })
            return subMenu
        end,
        AddSlider = function(sliderName, min, max, step, defaultValue, onChange)
            local currentValue = defaultValue or min
            table.insert(subMenuItems, {
                name = function()
                    return sliderName .. ": " .. currentValue .. " [+/-]"
                end,
                onRight = function()
                    currentValue = math.min(currentValue + step, max)
                    if onChange then
                        onChange(currentValue)
                    end
                end,
                onLeft = function()
                    currentValue = math.max(currentValue - step, min)
                    if onChange then
                        onChange(currentValue)
                    end
                end
            })
            return subMenu
        end,
        AddCheckbox = function(checkboxName, defaultState, onChange)
            local isChecked = defaultState or false
            table.insert(subMenuItems, {
                name = function()
                    return checkboxName .. ": " .. (isChecked and "ON" or "OFF")
                end,
                onSelect = function()
                    isChecked = not isChecked
                    if onChange then
                        onChange(isChecked)
                    end
                end
            })
            return subMenu
        end,
        AddDynamicButton = function(nameFunc, callback)
            table.insert(subMenuItems, {
                name = nameFunc,
                onSelect = callback
            })
            return subMenu
        end,
        Back = function()
            return MenuLib
        end
    }
end

function MenuLib.AddList(name, items, defaultIndex, onChange)
    local currentIndex = defaultIndex or 1
    table.insert(MENU_ITEMS, {
        name = function()
            return name .. ": " .. items[currentIndex]
        end,
        onSelect = function()
            currentIndex = currentIndex % #items + 1
            if onChange then
                onChange(currentIndex, items[currentIndex])
            end
        end
    })
    return MenuLib
end

function MenuLib.AddSlider(name, min, max, step, defaultValue, onChange)
    local currentValue = defaultValue or min
    table.insert(MENU_ITEMS, {
        name = function()
            return name .. ": " .. currentValue .. " [+/-]"
        end,
        onRight = function()
            currentValue = math.min(currentValue + step, max)
            if onChange then
                onChange(currentValue)
            end
        end,
        onLeft = function()
            currentValue = math.max(currentValue - step, min)
            if onChange then
                onChange(currentValue)
            end
        end
    })
    return MenuLib
end

function MenuLib.AddCheckbox(name, defaultState, onChange)
    local isChecked = defaultState or false
    table.insert(MENU_ITEMS, {
        name = function()
            return name .. ": " .. (isChecked and "ON" or "OFF")
        end,
        onSelect = function()
            isChecked = not isChecked
            if onChange then
                onChange(isChecked)
            end
        end
    })
    return MenuLib
end

function MenuLib.AddDynamicButton(nameFunc, callback)
    table.insert(MENU_ITEMS, {
        name = nameFunc,
        onSelect = callback
    })
    return MenuLib
end

function MenuLib.SetTitle(title)
    MENU_CONFIG.title = title
    MENU_CONFIG.mainTitle = title
    return MenuLib
end

function MenuLib.SetColor(r, g, b, a)
    MENU_CONFIG.color = { r, g, b, a or 255 }
    return MenuLib
end

function MenuLib.Clear()
    MENU_ITEMS = {}
    return MenuLib
end

function MenuLib.RegisterKey(key)
    OPEN_KEY = key or 288
    return MenuLib
end

local function toggle_menu()
    IS_MENU_OPEN = not IS_MENU_OPEN
    if not IS_MENU_OPEN then
        IN_SUB_MENU = false
    end
end

function MenuLib.Start()
    CreateThread(function()
        while true do
            Wait(IS_MENU_OPEN and 0 or 5)
            if IsControlJustPressed(0, OPEN_KEY) then
                toggle_menu()
            end
            if IS_MENU_OPEN then
                process_controls()
                draw_menu()
            end
        end
    end)
    return MenuLib
end

function MenuLib.Open()
    IS_MENU_OPEN = true
    return MenuLib
end

function MenuLib.Close()
    IS_MENU_OPEN = false
    IN_SUB_MENU = false
    return MenuLib
end

function MenuLib.IsOpen()
    return IS_MENU_OPEN
end

function MenuLib.SetSoundEnabled(enabled)
    MENU_CONFIG.soundEnabled = enabled
    return MenuLib
end

function MenuLib.IsSoundEnabled()
    return MENU_CONFIG.soundEnabled
end

local DEBUG_MODE = "PED"
local DEBUG_MODES = { "PED", "VEHICLE", "OBJECT" }
local DEBUG_MODE_INDEX = 1
local DEBUG_MIN_DISTANCE = 100

local WALL_ENABLED = false
local WALL_DISTANCE = 50
local WALL_LINES_ENABLED = true
local WALL_HEALTH_ENABLED = true
local WALL_ARMOUR_ENABLED = true

local selectedEntity = nil
local selectedEntityData = nil
local isDrawingEntity = false
local foundEntities = {}
local currentEntityIndex = 0

local function draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y + 0.025)
    end
end

local function debug_find_player()
    local entityType = DEBUG_MODE:lower() .. "s"
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    TriggerServerEvent("AdminMenu:FindNearby", entityType, pedCoords, DEBUG_MIN_DISTANCE)
end

local function debug_delete()
    if selectedEntityData and selectedEntityData.netid then
        local entityType = DEBUG_MODE:lower() .. "s"
        TriggerServerEvent("AdminMenu:Handle", "deleteOne", entityType, selectedEntityData.netid)
        print(string.format("[Debug] Deleted %s (NetID: %s)", DEBUG_MODE, selectedEntityData.netid))
        selectedEntity = nil
        selectedEntityData = nil
        isDrawingEntity = false
        currentEntityIndex = 0
        foundEntities = {}
    else
        print(string.format("[Debug] No %s selected. Use 'Find Player %s' first", DEBUG_MODE, DEBUG_MODE))
    end
end

local function debug_delete_all()
    if selectedEntityData and selectedEntityData.owner and selectedEntityData.owner ~= "N/A" then
        local entityType = DEBUG_MODE:lower() .. "s"
        TriggerServerEvent("AdminMenu:Handle", "deleteByOwner", entityType, 0, selectedEntityData.owner)
        print(string.format("[Debug] Deleted all %sS from owner %s", DEBUG_MODE, selectedEntityData.owner))
        selectedEntity = nil
        selectedEntityData = nil
        isDrawingEntity = false
        currentEntityIndex = 0
        foundEntities = {}
    else
        print(string.format("[Debug] No owner found. Use 'Find Player %s' first", DEBUG_MODE))
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if isDrawingEntity and selectedEntity and DoesEntityExist(selectedEntity) and NetworkGetEntityIsNetworked(selectedEntity) and selectedEntityData then
            sleep = 0
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local entCoords = GetEntityCoords(selectedEntity)
            DrawLine(pedCoords.x, pedCoords.y, pedCoords.z, entCoords.x, entCoords.y, entCoords.z, 0, 255, 0, 255)
            draw3DText(entCoords.x, entCoords.y, entCoords.z + 0.5, string.format("Player Entity - Hash: %s - Owner: %s", selectedEntityData.hash, selectedEntityData.owner))
        else
            if isDrawingEntity then
                isDrawingEntity = false
                selectedEntity = nil
                selectedEntityData = nil
            end
        end
        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent("AdminMenu:NearbyResult", function(entitiesInRange)
    if #entitiesInRange == 0 then
        selectedEntity = nil
        selectedEntityData = nil
        isDrawingEntity = false
        currentEntityIndex = 0
        foundEntities = {}
        print(string.format("[Debug] No %s found within %.2fm", DEBUG_MODE, DEBUG_MIN_DISTANCE))
        return
    end
    local networkedEntities = {}
    for _, data in ipairs(entitiesInRange) do
        local entity = NetworkGetEntityFromNetworkId(data.netid)
        if DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity) then
            table.insert(networkedEntities, data)
        end
    end
    if #networkedEntities == 0 then
        selectedEntity = nil
        selectedEntityData = nil
        isDrawingEntity = false
        currentEntityIndex = 0
        foundEntities = {}
        print(string.format("[Debug] No networked %s found within %.2fm", DEBUG_MODE, DEBUG_MIN_DISTANCE))
        return
    end
    foundEntities = networkedEntities
    if selectedEntity and DoesEntityExist(selectedEntity) and NetworkGetEntityIsNetworked(selectedEntity) then
        local currentNetId = NetworkGetNetworkIdFromEntity(selectedEntity)
        local foundCurrentIndex = 0
        for i, data in ipairs(foundEntities) do
            if data.netid == currentNetId then
                foundCurrentIndex = i
                break
            end
        end
        if foundCurrentIndex > 0 then
            currentEntityIndex = (foundCurrentIndex % #foundEntities) + 1
        else
            currentEntityIndex = 1
        end
    else
        currentEntityIndex = 1
    end
    local entityData = foundEntities[currentEntityIndex]
    selectedEntity = NetworkGetEntityFromNetworkId(entityData.netid)
    if not NetworkGetEntityIsNetworked(selectedEntity) then
        selectedEntity = nil
        selectedEntityData = nil
        isDrawingEntity = false
        print(string.format("[Debug] Selected entity is not networked"))
        return
    end
    selectedEntityData = entityData
    isDrawingEntity = true
    print(string.format("[Debug] Selected %s at %.2fm (%d/%d)", DEBUG_MODE, entityData.distance, currentEntityIndex, #foundEntities))
end)

MenuLib.CreateMenu("Admin Menu", nil, nil, nil, { 51, 51, 255, 255 })

local debugMenu = MenuLib.AddSubMenu("Debug", "Debug Tools")

debugMenu.AddList("Mode", DEBUG_MODES, 1, function(index, value)
    DEBUG_MODE_INDEX = index
    DEBUG_MODE = value
    selectedEntity = nil
    selectedEntityData = nil
    isDrawingEntity = false
    currentEntityIndex = 0
    foundEntities = {}
end)

debugMenu.AddSlider("Minimum Distance", 5, 500, 5, 100, function(value)
    DEBUG_MIN_DISTANCE = value
end)

debugMenu.AddDynamicButton(function()
    return "Find Player " .. DEBUG_MODE .. " [INS]"
end, debug_find_player)

debugMenu.AddDynamicButton(function()
    return "Delete " .. DEBUG_MODE .. " [DEL]"
end, debug_delete)

debugMenu.AddDynamicButton(function()
    return "Delete All Player " .. DEBUG_MODE .. "S"
end, debug_delete_all)

local wallMenu = MenuLib.AddSubMenu("Wall", "Wall Options")

wallMenu.AddCheckbox("Lines", true, function(isChecked)
    WALL_LINES_ENABLED = isChecked
    print("[Wall] Lines " .. (isChecked and "enabled" or "disabled"))
end)

wallMenu.AddSlider("Minimum Distance", 10, 500, 5, 50, function(value)
    WALL_DISTANCE = value
    print("[Wall] Distance set to: " .. value)
end)

wallMenu.AddCheckbox("Health", true, function(isChecked)
    WALL_HEALTH_ENABLED = isChecked
    print("[Wall] Health display " .. (isChecked and "enabled" or "disabled"))
end)

wallMenu.AddCheckbox("Armour", true, function(isChecked)
    WALL_ARMOUR_ENABLED = isChecked
    print("[Wall] Armour display " .. (isChecked and "enabled" or "disabled"))
end)

local configMenu = MenuLib.AddSubMenu("Config", "Settings")

configMenu.AddCheckbox("Navigation Sounds", true, function(isChecked)
    MenuLib.SetSoundEnabled(isChecked)
    print("[Config] Navigation sounds " .. (isChecked and "enabled" or "disabled"))
end)

MenuLib.RegisterKey(288).Start()