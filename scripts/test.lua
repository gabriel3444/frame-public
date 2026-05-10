local newMenu = {}
local isMenuOpen = false
local inSubMenu = false
local inPlayerSubMenu = false

local selectedIndex = 1
local subMenuIndex = 1
local playerSubMenuIndex = 1
local selectedPlayerID = nil

local maxVisibleItems = 7
local lastNavTime = 0
local navRepeat = 150
local menuTitle = "New Menu v1"
local menuColor = { 51, 51, 255, 255 }

local menuItems = {
    { name = "Jogadores Online", subMenu = {}, actions = { "Copiar Roupa" } },
    { name = "Desenvolvendo1", subMenu = { "Em breve1" }, actions = {} },
    { name = "Desenvolvendo2", subMenu = { "Em breve2" }, actions = {} },
    { name = "Desenvolvendo3", subMenu = { "Em breve3" }, actions = {} },
    { name = "Desenvolvendo4", subMenu = { "Em breve4" }, actions = {} },
}

-- ========================================
-- Funções auxiliares de desenho
-- ========================================

function newMenu.drawTexturedRect(x, y, width, height, bgColor, textColor, text, font, scale, center)
    DrawRect(x, y, width, height, bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    SetTextFont(font or 0)
    SetTextScale(scale or 0.3, scale or 0.3)
    SetTextColour(textColor[1], textColor[2], textColor[3], textColor[4])
    SetTextCentre(center or false)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if center then
        DrawText(x, y - height / 3)
    else
        DrawText(x - 0.09, y - height / 3)
    end
end

function newMenu.getVisibleRange(totalItems, currentIndex)
    if totalItems <= maxVisibleItems then
        return 1, totalItems
    else
        local firstIndex = math.max(1, currentIndex - maxVisibleItems + 1)
        local lastIndex = math.min(totalItems, firstIndex + maxVisibleItems - 1)
        return firstIndex, lastIndex
    end
end

-- ========================================
-- Funções de desenho do menu
-- ========================================

function newMenu.drawMenu()
    if not isMenuOpen then
        return
    end
    local menuX, menuY = 0.86, 0.09
    local menuWidth = 0.2
    local titleHeight, itemHeight = 0.05, 0.04
    local lastY = menuY + titleHeight
    newMenu.drawTexturedRect(menuX, menuY, menuWidth, titleHeight, menuColor, { 255, 255, 255, 255 }, menuTitle, 6, 0.5, true)
    if inSubMenu then
        if selectedIndex == 1 then
            if inPlayerSubMenu then
                lastY = newMenu.drawPlayerActionsSubMenu(menuX, menuY, menuWidth, titleHeight, itemHeight)
            else
                lastY = newMenu.drawPlayersSubMenu(menuX, menuY, menuWidth, titleHeight, itemHeight)
            end
        else
            lastY = newMenu.drawGenericSubMenu(menuX, menuY, menuWidth, titleHeight, itemHeight)
        end
    else
        lastY = newMenu.drawMainMenu(menuX, menuY, menuWidth, titleHeight, itemHeight)
    end
end

function newMenu.drawMainMenu(x, y, width, titleHeight, itemHeight)
    local totalItems = #menuItems
    local firstIndex, lastIndex = newMenu.getVisibleRange(totalItems, selectedIndex)
    local lastY = y + titleHeight
    for i = firstIndex, lastIndex do
        local item = menuItems[i]
        local yPos = y + ((i - firstIndex + 0.5) * itemHeight) + titleHeight / 2
        lastY = yPos + itemHeight / 2
        local isSelected = i == selectedIndex
        local bgColor = isSelected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local textColor = isSelected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        newMenu.drawTexturedRect(x, yPos, width, itemHeight, bgColor, textColor, item.name)
    end
    return lastY
end

function newMenu.drawGenericSubMenu(x, y, width, titleHeight, itemHeight)
    local subMenu = menuItems[selectedIndex].subMenu
    local totalItems = #subMenu
    local firstIndex, lastIndex = newMenu.getVisibleRange(totalItems, subMenuIndex)
    local lastY = y + titleHeight
    for i = firstIndex, lastIndex do
        local item = subMenu[i]
        local yPos = y + ((i - firstIndex + 0.5) * itemHeight) + titleHeight / 2
        lastY = yPos + itemHeight / 2
        local isSelected = i == subMenuIndex
        local bgColor = isSelected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local textColor = isSelected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        newMenu.drawTexturedRect(x, yPos, width, itemHeight, bgColor, textColor, item)
    end
    return lastY
end

function newMenu.drawPlayersSubMenu(x, y, width, titleHeight, itemHeight)
    local players = menuItems[1].subMenu
    local totalPlayers = #players
    local firstIndex, lastIndex = newMenu.getVisibleRange(totalPlayers, subMenuIndex)
    local lastY = y + titleHeight
    for i = firstIndex, lastIndex do
        local player = players[i]
        local yPos = y + ((i - firstIndex + 0.5) * itemHeight) + titleHeight / 2
        lastY = yPos + itemHeight / 2
        local isSelected = i == subMenuIndex
        local bgColor = isSelected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local textColor = isSelected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        newMenu.drawTexturedRect(x, yPos, width, itemHeight, bgColor, textColor, "ID: [" .. player.id .. "] " .. player.name)
    end
    return lastY
end

function newMenu.drawPlayerActionsSubMenu(x, y, width, titleHeight, itemHeight)
    local actions = menuItems[1].actions
    local lastY = y + titleHeight
    for i, action in ipairs(actions) do
        local yPos = y + (i - 0.5) * itemHeight + titleHeight / 2
        lastY = yPos + itemHeight / 2
        local isSelected = i == playerSubMenuIndex
        local bgColor = isSelected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local textColor = isSelected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }
        newMenu.drawTexturedRect(x, yPos, width, itemHeight, bgColor, textColor, action)
    end
    return lastY
end

-- ========================================
-- Funções de navegação
-- ========================================

function newMenu.navigateMenu(direction)
    local function wrapIndex(index, max)
        return ((index - 1) % max) + 1
    end
    if direction == "up" then
        if inPlayerSubMenu then
            playerSubMenuIndex = wrapIndex(playerSubMenuIndex - 1, #menuItems[1].actions)
        elseif inSubMenu then
            subMenuIndex = wrapIndex(subMenuIndex - 1, #menuItems[selectedIndex].subMenu)
        else
            selectedIndex = wrapIndex(selectedIndex - 1, #menuItems)
        end
    elseif direction == "down" then
        if inPlayerSubMenu then
            playerSubMenuIndex = wrapIndex(playerSubMenuIndex + 1, #menuItems[1].actions)
        elseif inSubMenu then
            subMenuIndex = wrapIndex(subMenuIndex + 1, #menuItems[selectedIndex].subMenu)
        else
            selectedIndex = wrapIndex(selectedIndex + 1, #menuItems)
        end
    end
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

function newMenu.confirmSelection()
    if inPlayerSubMenu then
        local action = menuItems[1].actions[playerSubMenuIndex]
        if action == "Copiar Roupa" and selectedPlayerID then
            newMenu.copyPlayerOutfit(selectedPlayerID)
        end
    elseif inSubMenu then
        if selectedIndex == 1 then
            local player = menuItems[1].subMenu[subMenuIndex]
            if player then
                selectedPlayerID = player.id
                inPlayerSubMenu = true
                playerSubMenuIndex = 1
            end
        end
    else
        if menuItems[selectedIndex].subMenu then
            inSubMenu = true
            subMenuIndex = 1
        end
    end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

function newMenu.copyPlayerOutfit(playerID)
    ClonePedToTarget(GetPlayerPed(playerID), PlayerPedId())
    print("Roupa do jogador " .. playerID .. " copiada.")
end

function newMenu.goBack()
    if inPlayerSubMenu then
        inPlayerSubMenu = false
        playerSubMenuIndex = 1
    elseif inSubMenu then
        inSubMenu = false
        subMenuIndex = 1
    else
        isMenuOpen = false
        inSubMenu, inPlayerSubMenu = false, false
    end
    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

function newMenu.processControls()
    if not isMenuOpen then
        return
    end
    local now = GetGameTimer()
    if IsControlPressed(0, 172) and now - lastNavTime > navRepeat then
        newMenu.navigateMenu("up")
        lastNavTime = now
    end
    if IsControlPressed(0, 173) and now - lastNavTime > navRepeat then
        newMenu.navigateMenu("down")
        lastNavTime = now
    end
    if IsControlJustReleased(0, 201) then
        newMenu.confirmSelection()
    end
    if IsControlJustReleased(0, 194) then
        newMenu.goBack()
    end
end

function newMenu.updatePlayerListSubMenu()
    menuItems[1].subMenu = {}
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        local name = GetPlayerName(playerId)
        local serverId = GetPlayerServerId(playerId)
        table.insert(menuItems[1].subMenu, { id = serverId, name = name })
    end
end

-- ========================================
-- Thread principal do menu
-- ========================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 38) then
            isMenuOpen = not isMenuOpen
            if not isMenuOpen then
                inSubMenu, inPlayerSubMenu = false, false
            end
        end
        if selectedIndex == 1 and not inSubMenu then
            newMenu.updatePlayerListSubMenu()
        end
        newMenu.processControls()
        newMenu.drawMenu()
    end
end)