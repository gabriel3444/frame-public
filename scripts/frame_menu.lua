local MenuUi = {}

local instanceIndex = 0

local function resolveLabel(instance, labelValue, tag)
    local valueType = type(labelValue)
    if valueType == "string" then
        return labelValue
    end

    if valueType == "function" then
        return tostring(labelValue())
    end

    return tostring(labelValue)
end

local function resolveSubMenu(instance, item)
    if type(item) ~= "table" then
        return nil
    end

    local subMenuValue = item.subMenu
    local valueType = type(subMenuValue)
    if valueType == "table" then
        return subMenuValue
    end
    if valueType == "function" then
        local result = subMenuValue()
        if type(result) ~= "table" then
            return nil
        end
        return result
    end
    return nil
end

local function drawTexturedRect(x, y, width, height, bgColor, textColor, text, font, scale, centerText)
    DrawRect(x, y, width, height, bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    SetTextFont(font or 0)
    SetTextScale(scale or 0.3, scale or 0.3)
    SetTextColour(textColor[1], textColor[2], textColor[3], textColor[4])
    SetTextCentre(centerText or false)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if centerText then
        DrawText(x, y - height / 3)
    else
        DrawText(x - 0.09, y - height / 3)
    end
end

local function wrapIndex(index, max)
    if max <= 0 then
        return 1
    end
    return ((index - 1) % max) + 1
end

local function ensureMenuStack(instance)
    if type(instance.menuStack) == "table" and #instance.menuStack > 0 then
        return
    end

    instance.menuStack = {
        {
            items = instance.menuItems or {},
            index = type(instance.selectedIndex) == "number" and instance.selectedIndex or 1,
            title = instance.menuConfig and instance.menuConfig.mainTitle or "Menu"
        }
    }
end

local function getCurrentContext(instance)
    ensureMenuStack(instance)
    return instance.menuStack[#instance.menuStack]
end

local function getContextItems(instance, ctx)
    if type(ctx.getItems) == "function" then
        local items = ctx.getItems()
        if type(items) == "table" then
            return items
        end
        return {}
    end
    if type(ctx.items) == "table" then
        return ctx.items
    end
    return {}
end

local function syncLegacyState(instance)
    ensureMenuStack(instance)

    local depth = #instance.menuStack
    instance.isInSubMenu = depth > 1

    local root = instance.menuStack[1]
    instance.selectedIndex = root and root.index or 1

    local current = instance.menuStack[depth]
    instance.subMenuIndex = current and current.index or 1

    if instance.menuConfig and current and current.title ~= nil then
        instance.menuConfig.title = current.title
    elseif instance.menuConfig then
        instance.menuConfig.title = instance.menuConfig.mainTitle
    end
end

local function resetToRoot(instance)
    instance.menuStack = {
        {
            items = instance.menuItems or {},
            index = type(instance.selectedIndex) == "number" and instance.selectedIndex or 1,
            title = instance.menuConfig and instance.menuConfig.mainTitle or "Menu"
        }
    }
    syncLegacyState(instance)
end

local function pushSubMenuContext(instance, item, title)
    ensureMenuStack(instance)
    table.insert(instance.menuStack, {
        getItems = function()
            return resolveSubMenu(instance, item)
        end,
        index = 1,
        title = title
    })
    syncLegacyState(instance)
end

local function popMenuContext(instance)
    ensureMenuStack(instance)
    if #instance.menuStack <= 1 then
        return
    end
    table.remove(instance.menuStack)
    syncLegacyState(instance)
end

local function normalizeCreateMenuArgs(title, subTitle, x, y, color)
    if type(subTitle) == "number" then
        return title, nil, subTitle, x, y
    end
    return title, subTitle, x, y, color
end

local function getVisibleRange(instance, totalItems, currentIndex)
    if totalItems <= instance.maxVisibleItems then
        return 1, totalItems
    end
    local firstIndex = math.max(1, currentIndex - instance.maxVisibleItems + 1)
    local lastIndex = math.min(totalItems, firstIndex + instance.maxVisibleItems - 1)
    return firstIndex, lastIndex
end

local function playSound(instance, name)
    if not instance.menuConfig.soundEnabled then
        return
    end
    PlaySoundFrontend(-1, name, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

local function drawMenuTitle(instance)
    local config = instance.menuConfig
    DrawRect(config.x, config.y, config.width, config.titleHeight, config.color[1], config.color[2], config.color[3], config.color[4])
    SetTextFont(1)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(config.title)
    if type(config.subTitle) == "string" and config.subTitle ~= "" then
        SetTextScale(0.55, 0.55)
        DrawText(config.x, config.y - config.titleHeight * 0.35)
        SetTextScale(0.35, 0.35)
        SetTextEntry("STRING")
        AddTextComponentString(config.subTitle)
        DrawText(config.x, config.y + config.titleHeight * 0.05)
    else
        SetTextScale(0.65, 0.65)
        DrawText(config.x, config.y - config.titleHeight / 3)
    end
end

local function drawMainMenu(instance)
    local ctx = getCurrentContext(instance)
    local items = getContextItems(instance, ctx)

    local config = instance.menuConfig
    local totalItems = #items
    if totalItems == 0 then
        local yPos = config.y + (config.titleHeight / 2) + (config.itemHeight / 2)
        drawTexturedRect(config.x, yPos, config.width, config.itemHeight, { 0, 0, 0, 205 }, { 255, 255, 255, 255 }, "No options")
        return
    end

    if type(ctx.index) ~= "number" or ctx.index < 1 or ctx.index > totalItems then
        ctx.index = wrapIndex(tonumber(ctx.index) or 1, totalItems)
        syncLegacyState(instance)
    end

    local firstIndex, lastIndex = getVisibleRange(instance, totalItems, ctx.index)
    for i = firstIndex, lastIndex do
        local item = items[i]
        local yPos = config.y + ((i - firstIndex + 0.5) * config.itemHeight) + config.titleHeight / 2
        local isSelected = i == ctx.index
        local bgColor = isSelected and { 255, 255, 255, 255 } or { 0, 0, 0, 205 }
        local textColor = isSelected and { 0, 0, 0, 255 } or { 255, 255, 255, 255 }

        local text
        if type(item) == "table" then
            text = resolveLabel(instance, item.name, "menuItem:" .. tostring(i))
        else
            text = tostring(item)
        end

        drawTexturedRect(config.x, yPos, config.width, config.itemHeight, bgColor, textColor, text)
    end
end

local function drawSubMenu(instance)
    drawMainMenu(instance)
end

local function navigateMenu(instance, direction)
    if direction ~= "up" and direction ~= "down" then
        return
    end

    local ctx = getCurrentContext(instance)
    local items = getContextItems(instance, ctx)
    if #items == 0 then
        return
    end

    if direction == "up" then
        ctx.index = wrapIndex(ctx.index - 1, #items)
    else
        ctx.index = wrapIndex(ctx.index + 1, #items)
    end
    syncLegacyState(instance)

    playSound(instance, "NAV_UP_DOWN")
end

local function confirmSelection(instance)
    local ctx = getCurrentContext(instance)
    local items = getContextItems(instance, ctx)
    if #items == 0 then
        return
    end

    local item = items[ctx.index]
    if type(item) ~= "table" then
        return
    end

    if item.subMenu ~= nil then
        local subMenu = resolveSubMenu(instance, item)
        if type(subMenu) == "table" then
            local title
            if item.subMenuTitle ~= nil then
                title = resolveLabel(instance, item.subMenuTitle, "menuItemSubTitle:" .. tostring(ctx.index))
            else
                title = resolveLabel(instance, item.name, "menuItemTitle:" .. tostring(ctx.index))
            end
            pushSubMenuContext(instance, item, title)
        end
    elseif type(item.onSelect) == "function" then
        item.onSelect()
    end

    playSound(instance, "SELECT")
end

local function goBack(instance)
    ensureMenuStack(instance)
    if #instance.menuStack > 1 then
        popMenuContext(instance)
    else
        instance.isMenuOpen = false
        resetToRoot(instance)
    end
    playSound(instance, "BACK")
end

local function processControls(instance)
    if not instance.isMenuOpen then
        return
    end

    local now = GetGameTimer()
    if IsControlPressed(0, 172) and now - instance.lastNavTime > instance.navRepeatMs then
        navigateMenu(instance, "up")
        instance.lastNavTime = now
    end
    if IsControlPressed(0, 173) and now - instance.lastNavTime > instance.navRepeatMs then
        navigateMenu(instance, "down")
        instance.lastNavTime = now
    end
    if IsControlPressed(0, 246) and now - instance.lastNavTime > instance.navRepeatMs then
        navigateMenu(instance, "up")
        instance.lastNavTime = now
    end
    if IsControlPressed(0, 74) and now - instance.lastNavTime > instance.navRepeatMs then
        navigateMenu(instance, "down")
        instance.lastNavTime = now
    end
    local ctx = getCurrentContext(instance)
    local items = getContextItems(instance, ctx)
    local currentItem = items[ctx.index]
    if type(currentItem) == "table" then
        if (IsControlPressed(0, 175) or IsControlPressed(0, 96)) and now - instance.lastHorizontalNavTime > instance.horizontalNavRepeatMs then
            if type(currentItem.onRight) == "function" then
                currentItem.onRight()
                instance.lastHorizontalNavTime = now
                playSound(instance, "NAV_UP_DOWN")
            end
        end
        if (IsControlPressed(0, 174) or IsControlPressed(0, 97)) and now - instance.lastHorizontalNavTime > instance.horizontalNavRepeatMs then
            if type(currentItem.onLeft) == "function" then
                currentItem.onLeft()
                instance.lastHorizontalNavTime = now
                playSound(instance, "NAV_UP_DOWN")
            end
        end
    end

    if IsControlJustReleased(0, 201) then
        confirmSelection(instance)
    end
    if IsControlJustReleased(0, 194) then
        goBack(instance)
    end
end

local function drawMenu(instance)
    if not instance.isMenuOpen then
        return
    end
    drawMenuTitle(instance)
    drawMainMenu(instance)
end

local function addListItem(instance, targetItems, name, items, defaultIndex, onChange)
    if type(items) ~= "table" or #items == 0 then
        return
    end

    local index = 1
    if type(defaultIndex) == "number" and defaultIndex == math.floor(defaultIndex) then
        index = defaultIndex
    end
    if index < 1 or index > #items then
        index = 1
    end

    table.insert(targetItems, {
        name = function()
            return resolveLabel(instance, name, "listName") .. ": " .. resolveLabel(instance, items[index], "listValue")
        end,
        onSelect = function()
            index = (index % #items) + 1
            if type(onChange) == "function" then
                onChange(index, items[index])
            end
        end
    })
end

local function addSliderItem(instance, targetItems, name, minValue, maxValue, step, defaultValue, onChange)
    if type(minValue) ~= "number" or type(maxValue) ~= "number" then
        return
    end

    local finalStep = type(step) == "number" and step or 1
    if finalStep <= 0 then
        finalStep = 1
    end
    if minValue > maxValue then
        minValue, maxValue = maxValue, minValue
    end

    local currentValue = defaultValue
    if type(currentValue) ~= "number" then
        currentValue = minValue
    end
    if currentValue < minValue or currentValue > maxValue then
        currentValue = math.min(math.max(currentValue, minValue), maxValue)
    end

    table.insert(targetItems, {
        name = function()
            return resolveLabel(instance, name, "sliderName") .. ": " .. tostring(currentValue) .. " [+/-]"
        end,
        onRight = function()
            currentValue = math.min(currentValue + finalStep, maxValue)
            if type(onChange) == "function" then
                onChange(currentValue)
            end
        end,
        onLeft = function()
            currentValue = math.max(currentValue - finalStep, minValue)
            if type(onChange) == "function" then
                onChange(currentValue)
            end
        end
    })
end

local function addCheckboxItem(instance, targetItems, name, defaultState, onChange)
    local isChecked = type(defaultState) == "boolean" and defaultState or false
    table.insert(targetItems, {
        name = function()
            return resolveLabel(instance, name, "checkboxName") .. ": " .. (isChecked and "ON" or "OFF")
        end,
        onSelect = function()
            isChecked = not isChecked
            if type(onChange) == "function" then
                onChange(isChecked)
            end
        end
    })
end

local instanceMethods = {}
instanceMethods.__index = instanceMethods

function MenuUi.New()
    instanceIndex = instanceIndex + 1
    local instance = setmetatable({}, instanceMethods)

    instance.instanceId = instanceIndex
    instance.isMenuOpen = false
    instance.isInSubMenu = false
    instance.selectedIndex = 1
    instance.subMenuIndex = 1
    instance.maxVisibleItems = 7
    instance.lastNavTime = 0
    instance.lastHorizontalNavTime = 0
    instance.navRepeatMs = 150
    instance.horizontalNavRepeatMs = 50
    instance.openKey = nil
    instance.isStarted = false

    instance.menuItems = {}
    instance.menuConfig = {
        title = "Menu",
        mainTitle = "Menu",
        subTitle = nil,
        color = { 51, 51, 255, 255 },
        x = 0.86,
        y = 0.09,
        width = 0.2,
        titleHeight = 0.065,
        itemHeight = 0.04,
        soundEnabled = true
    }

    resetToRoot(instance)
    return instance
end

local function toggleMenu(instance)
    instance.isMenuOpen = not instance.isMenuOpen
    resetToRoot(instance)
end

function instanceMethods:CreateMenu(title, subTitle, x, y, color)
    title, subTitle, x, y, color = normalizeCreateMenuArgs(title, subTitle, x, y, color)

    local finalTitle = type(title) == "string" and title or "Menu"
    self.menuConfig.title = finalTitle
    self.menuConfig.mainTitle = finalTitle
    self.menuConfig.subTitle = type(subTitle) == "string" and subTitle or nil

    ensureMenuStack(self)
    if self.menuStack[1] then
        self.menuStack[1].title = finalTitle
    end
    if #self.menuStack == 1 then
        self.menuConfig.title = finalTitle
    end

    if type(color) == "table" and type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number" then
        self.menuConfig.color = { color[1], color[2], color[3], type(color[4]) == "number" and color[4] or 255 }
    end
    if type(x) == "number" then
        self.menuConfig.x = x
    end
    if type(y) == "number" then
        self.menuConfig.y = y
    end

    return self
end

function instanceMethods:AddButton(name, callback)
    table.insert(self.menuItems, { name = name, onSelect = callback })
    return self
end

function instanceMethods:AddList(name, items, defaultIndex, onChange)
    addListItem(self, self.menuItems, name, items, defaultIndex, onChange)
    return self
end

function instanceMethods:AddSlider(name, minValue, maxValue, step, defaultValue, onChange)
    addSliderItem(self, self.menuItems, name, minValue, maxValue, step, defaultValue, onChange)
    return self
end

function instanceMethods:AddCheckbox(name, defaultState, onChange)
    addCheckboxItem(self, self.menuItems, name, defaultState, onChange)
    return self
end

function instanceMethods:AddDynamicButton(nameFunc, callback)
    table.insert(self.menuItems, { name = nameFunc, onSelect = callback })
    return self
end

function instanceMethods:AddSubMenu(name, subMenuTitle)
    local subMenuItems = {}
    local subMenu = {
        name = name,
        subMenuTitle = subMenuTitle ~= nil and subMenuTitle or name,
        subMenu = function()
            return subMenuItems
        end
    }
    table.insert(self.menuItems, subMenu)

    local instance = self
    local builder = {}

    local function createSubMenuBuilder(targetItems, parentBuilder)
        local b = {}

        function b.AddButton(buttonName, callback)
            table.insert(targetItems, { name = buttonName, onSelect = callback })
            return b
        end

        function b.AddList(listName, items, defaultIndex, onChange)
            addListItem(instance, targetItems, listName, items, defaultIndex, onChange)
            return b
        end

        function b.AddSlider(sliderName, minValue, maxValue, step, defaultValue, onChange)
            addSliderItem(instance, targetItems, sliderName, minValue, maxValue, step, defaultValue, onChange)
            return b
        end

        function b.AddCheckbox(checkboxName, defaultState, onChange)
            addCheckboxItem(instance, targetItems, checkboxName, defaultState, onChange)
            return b
        end

        function b.AddDynamicButton(nameFunc, callback)
            table.insert(targetItems, { name = nameFunc, onSelect = callback })
            return b
        end

        function b.AddSubMenu(childName, childSubMenuTitle)
            local childItems = {}
            local childMenu = {
                name = childName,
                subMenuTitle = childSubMenuTitle ~= nil and childSubMenuTitle or childName,
                subMenu = function()
                    return childItems
                end
            }
            table.insert(targetItems, childMenu)
            return createSubMenuBuilder(childItems, b)
        end

        function b.Back()
            return parentBuilder
        end

        return b
    end

    function builder.AddButton(buttonName, callback)
        table.insert(subMenuItems, { name = buttonName, onSelect = callback })
        return builder
    end

    function builder.AddList(listName, items, defaultIndex, onChange)
        addListItem(instance, subMenuItems, listName, items, defaultIndex, onChange)
        return builder
    end

    function builder.AddSlider(sliderName, minValue, maxValue, step, defaultValue, onChange)
        addSliderItem(instance, subMenuItems, sliderName, minValue, maxValue, step, defaultValue, onChange)
        return builder
    end

    function builder.AddCheckbox(checkboxName, defaultState, onChange)
        addCheckboxItem(instance, subMenuItems, checkboxName, defaultState, onChange)
        return builder
    end

    function builder.AddDynamicButton(nameFunc, callback)
        table.insert(subMenuItems, { name = nameFunc, onSelect = callback })
        return builder
    end

    function builder.AddSubMenu(childName, childSubMenuTitle)
        local childItems = {}
        local childMenu = {
            name = childName,
            subMenuTitle = childSubMenuTitle ~= nil and childSubMenuTitle or childName,
            subMenu = function()
                return childItems
            end
        }
        table.insert(subMenuItems, childMenu)
        return createSubMenuBuilder(childItems, builder)
    end

    function builder.Back()
        return instance
    end

    return builder
end

function instanceMethods:SetTitle(title)
    local finalTitle = type(title) == "string" and title or tostring(title)
    self.menuConfig.mainTitle = finalTitle
    ensureMenuStack(self)
    if self.menuStack[1] then
        self.menuStack[1].title = finalTitle
    end
    if #self.menuStack == 1 then
        self.menuConfig.title = finalTitle
    end
    return self
end

function instanceMethods:SetColor(r, g, b, a)
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then
        self.menuConfig.color = { r, g, b, type(a) == "number" and a or 255 }
    end
    return self
end

function instanceMethods:Clear()
    self.menuItems = {}
    self.selectedIndex = 1
    resetToRoot(self)
    return self
end

function instanceMethods:RegisterKey(key)
    if key == nil then
        self.openKey = nil
        return self
    end

    if type(key) == "number" and key == math.floor(key) then
        self.openKey = key
    end
    return self
end

function instanceMethods:Start()
    if self.isStarted then
        return self
    end
    self.isStarted = true

    local instance = self
    CreateThread(function()
        while true do
            Wait(instance.isMenuOpen and 0 or 5)

            if instance.openKey and IsControlJustPressed(0, instance.openKey) then
                toggleMenu(instance)
            end

            if instance.isMenuOpen then
                processControls(instance)
                drawMenu(instance)
            end
        end
    end)

    return self
end

function instanceMethods:Open()
    self.isMenuOpen = true
    resetToRoot(self)
    return self
end

function instanceMethods:Close()
    self.isMenuOpen = false
    resetToRoot(self)
    return self
end

function instanceMethods:IsOpen()
    return self.isMenuOpen
end

function instanceMethods:SetSoundEnabled(enabled)
    if type(enabled) == "boolean" then
        self.menuConfig.soundEnabled = enabled
    end
    return self
end

function instanceMethods:IsSoundEnabled()
    return self.menuConfig.soundEnabled
end

local menu = MenuUi.New()

local forcedTime = nil
local forcedWeather = nil

local timesOfDay = {
    { name = "Padrão", h = nil, m = nil, s = nil },
    { name = "Manhã", h = 9, m = 0, s = 0 },
    { name = "Tarde", h = 15, m = 0, s = 0 },
    { name = "Pôr do sol", h = 19, m = 30, s = 0 },
    { name = "Noite", h = 23, m = 0, s = 0 },
    { name = "Madrugada", h = 3, m = 0, s = 0 }
}

local seasons = {
    { name = "Padrão", weather = nil },
    { name = "Verão (sol)", weather = "EXTRASUNNY" },
    { name = "Primavera (nublado)", weather = "CLOUDS" },
    { name = "Outono (neblina)", weather = "FOGGY" },
    { name = "Inverno (neve)", weather = "XMAS" },
    { name = "Chuva", weather = "RAIN" },
    { name = "Tempestade", weather = "THUNDER" }
}

local titleColors = {
    { name = "Azul", rgb = { 51, 51, 255 } },
    { name = "Vermelho", rgb = { 255, 60, 60 } },
    { name = "Verde", rgb = { 60, 255, 120 } },
    { name = "Roxo", rgb = { 170, 80, 255 } },
    { name = "Laranja", rgb = { 255, 160, 60 } },
    { name = "Preto", rgb = { 0, 0, 0 } }
}

local timeNames = {}
for i = 1, #timesOfDay do
    timeNames[i] = timesOfDay[i].name
end

local seasonNames = {}
for i = 1, #seasons do
    seasonNames[i] = seasons[i].name
end

local titleColorNames = {}
for i = 1, #titleColors do
    titleColorNames[i] = titleColors[i].name
end

local kvpPrefix = "frame_menu:"
local kvpPresetsIndexKey = kvpPrefix .. "presets"
local kvpNextPresetIdKey = kvpPrefix .. "nextPresetId"

local function loadJsonKvp(key)
    local raw = GetResourceKvpString(key)
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok then
        return nil
    end
    return decoded
end

local function saveJsonKvp(key, value)
    SetResourceKvp(key, json.encode(value))
end

local function presetDataKey(presetId)
    return kvpPrefix .. "preset:" .. tostring(presetId)
end

local function loadPresetsIndex()
    local value = loadJsonKvp(kvpPresetsIndexKey)
    if type(value) ~= "table" then
        return {}
    end
    return value
end

local function savePresetsIndex(index)
    saveJsonKvp(kvpPresetsIndexKey, index)
end

local function nextPresetId()
    local id = GetResourceKvpInt(kvpNextPresetIdKey)
    if type(id) ~= "number" or id <= 0 then
        id = 1
    end
    SetResourceKvpInt(kvpNextPresetIdKey, id + 1)
    return tostring(id)
end

local function loadPreset(presetId)
    local data = loadJsonKvp(presetDataKey(presetId))
    if type(data) ~= "table" then
        return nil
    end
    return data
end

local function savePreset(presetId, data)
    saveJsonKvp(presetDataKey(presetId), data)
end

local function deletePreset(presetId)
    DeleteResourceKvp(presetDataKey(presetId))
end

local function coerceSettings(value)
    if type(value) ~= "table" then
        return nil
    end
    local soundEnabled = true
    if type(value.soundEnabled) == "boolean" then
        soundEnabled = value.soundEnabled
    end
    return {
        soundEnabled = soundEnabled,
        titleColorIndex = type(value.titleColorIndex) == "number" and math.floor(value.titleColorIndex) or 1,
        timeIndex = type(value.timeIndex) == "number" and math.floor(value.timeIndex) or 1,
        weatherIndex = type(value.weatherIndex) == "number" and math.floor(value.weatherIndex) or 1
    }
end

local function clampIndex(index, max)
    if type(index) ~= "number" then
        return 1
    end
    index = math.floor(index)
    if index < 1 then
        return 1
    end
    if index > max then
        return max
    end
    return index
end

local function cloneSettings(source)
    return {
        soundEnabled = source.soundEnabled,
        titleColorIndex = source.titleColorIndex,
        timeIndex = source.timeIndex,
        weatherIndex = source.weatherIndex
    }
end

local defaultSettings = {
    soundEnabled = true,
    titleColorIndex = 1,
    timeIndex = 1,
    weatherIndex = 1
}

local selectedPresetIndex = 1

local settings = cloneSettings(defaultSettings)

local function applySettings()
    settings.titleColorIndex = clampIndex(settings.titleColorIndex, #titleColors)
    settings.timeIndex = clampIndex(settings.timeIndex, #timesOfDay)
    settings.weatherIndex = clampIndex(settings.weatherIndex, #seasons)

    menu:SetSoundEnabled(settings.soundEnabled)

    local c = titleColors[settings.titleColorIndex]
    if c and c.rgb then
        menu:SetColor(c.rgb[1], c.rgb[2], c.rgb[3], 255)
    end

    local t = timesOfDay[settings.timeIndex]
    forcedTime = (t and t.h ~= nil) and t or nil

    local w = seasons[settings.weatherIndex]
    forcedWeather = (w and w.weather ~= nil) and w.weather or nil
end

local function findPresetByName(presets, name)
    for i = 1, #presets do
        if presets[i] and presets[i].name == name then
            return i
        end
    end
    return nil
end

local function makeUniquePresetName(presets, baseName)
    local name = baseName
    local suffix = 2
    while findPresetByName(presets, name) do
        name = baseName .. " (" .. tostring(suffix) .. ")"
        suffix = suffix + 1
    end
    return name
end

local playersOnlineEntries = {
    { name = "Carregando..." }
}

local function copyOutfitFromPlayer(targetPlayer)
    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then
        return
    end
    local myPed = PlayerPedId()
    for component = 0, 11 do
        SetPedComponentVariation(myPed, component, GetPedDrawableVariation(targetPed, component), GetPedTextureVariation(targetPed, component), GetPedPaletteVariation(targetPed, component))
    end
    for prop = 0, 7 do
        local propIndex = GetPedPropIndex(targetPed, prop)
        if propIndex == -1 then
            ClearPedProp(myPed, prop)
        else
            SetPedPropIndex(myPed, prop, propIndex, GetPedPropTextureIndex(targetPed, prop), true)
        end
    end
end

local function rebuildPlayersOnlineEntries()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local nearby = {}
    local activePlayers = GetActivePlayers()
    for i = 1, #activePlayers do
        local player = activePlayers[i]
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local dist = Vdist(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z)
                if dist <= 500.0 then
                    table.insert(nearby, { player = player, dist = dist })
                end
            end
        end
    end
    table.sort(nearby, function(a, b)
        return a.dist < b.dist
    end)
    if #nearby == 0 then
        playersOnlineEntries = { { name = "Nenhum jogador por perto" } }
        return
    end
    local entries = {}
    for i = 1, #nearby do
        local player = nearby[i].player
        local serverId = GetPlayerServerId(player)
        local playerName = GetPlayerName(player) or "Desconhecido"
        local label = "[" .. tostring(serverId) .. "] " .. tostring(playerName)
        local p = player
        table.insert(entries, {
            name = label,
            subMenuTitle = label,
            subMenu = function()
                return {
                    {
                        name = "Copiar a roupa",
                        onSelect = function()
                            copyOutfitFromPlayer(p)
                        end
                    }
                }
            end
        })
    end
    playersOnlineEntries = entries
end

CreateThread(function()
    while true do
        Wait(500)
        rebuildPlayersOnlineEntries()
    end
end)

local function buildMenu()
    menu:Clear()
    local initialColorIndex = clampIndex(settings.titleColorIndex, #titleColors)
    local initialColor = titleColors[initialColorIndex]
    local initialColorRgba = initialColor and initialColor.rgb and { initialColor.rgb[1], initialColor.rgb[2], initialColor.rgb[3], 255 } or { 51, 51, 255, 255 }
    menu:CreateMenu("Frame Menu", 0.86, 0.09, initialColorRgba)

    local playerMenu = menu:AddSubMenu("Jogador", "Jogador")
    playerMenu.Back()

    table.insert(menu.menuItems, {
        name = "Jogadores Online",
        subMenuTitle = "Jogadores Online",
        subMenu = function()
            return playersOnlineEntries
        end
    })

    local weaponsMenu = menu:AddSubMenu("Armas", "Armas")
    weaponsMenu.Back()

    local vehiclesMenu = menu:AddSubMenu("Veículos", "Veículos")
    vehiclesMenu.Back()

    local configMenu = menu:AddSubMenu("Configurações", "Configurações")

    local mundoMenu = configMenu.AddSubMenu("Mundo", "Mundo")

    mundoMenu.AddList("Hora do dia", timeNames, settings.timeIndex, function(index)
        settings.timeIndex = index
        local t = timesOfDay[index]
        forcedTime = (t and t.h ~= nil) and t or nil
    end)

    mundoMenu.AddList("Estação / Clima", seasonNames, settings.weatherIndex, function(index)
        settings.weatherIndex = index
        local w = seasons[index]
        forcedWeather = (w and w.weather ~= nil) and w.weather or nil
    end)

    mundoMenu.Back()

    local sistemaMenu = configMenu.AddSubMenu("Sistema", "Sistema")

    sistemaMenu.AddCheckbox("Sons de navegação", settings.soundEnabled, function(enabled)
        settings.soundEnabled = enabled
        menu:SetSoundEnabled(enabled)
    end)

    sistemaMenu.AddList("Cor do título", titleColorNames, settings.titleColorIndex, function(index)
        settings.titleColorIndex = index
        local c = titleColors[index]
        if c and c.rgb then
            menu:SetColor(c.rgb[1], c.rgb[2], c.rgb[3], 255)
        end
    end)

    sistemaMenu.Back()

    local cloudMenu = configMenu.AddSubMenu("Cloud", "Cloud")

    local presets = loadPresetsIndex()
    local presetNames = {}
    for i = 1, #presets do
        presetNames[i] = presets[i].name
    end
    if #presetNames == 0 then
        presetNames[1] = "Nenhum"
        selectedPresetIndex = 1
    else
        selectedPresetIndex = clampIndex(selectedPresetIndex, #presetNames)
    end

    cloudMenu.AddList("Presets salvos", presetNames, selectedPresetIndex, function(index)
        selectedPresetIndex = index
    end)

    cloudMenu.AddButton("Carregar preset selecionado", function()
        local preset = presets[selectedPresetIndex]
        if not preset or not preset.id then
            return
        end
        local loaded = coerceSettings(loadPreset(preset.id))
        if not loaded then
            return
        end
        settings = loaded
        buildMenu()
        applySettings()
        menu:Open()
    end)

    cloudMenu.AddButton("Salvar como novo preset", function()
        local presetsNow = loadPresetsIndex()
        local name = makeUniquePresetName(presetsNow, "Preset " .. tostring(#presetsNow + 1))
        local id = nextPresetId()
        table.insert(presetsNow, { id = id, name = name })
        savePresetsIndex(presetsNow)
        savePreset(id, settings)
        selectedPresetIndex = #presetsNow
        buildMenu()
        applySettings()
        menu:Open()
    end)

    cloudMenu.AddButton("Sobrescrever preset selecionado", function()
        local preset = presets[selectedPresetIndex]
        if not preset or not preset.id then
            return
        end
        savePreset(preset.id, settings)
    end)

    cloudMenu.AddButton("Deletar preset selecionado", function()
        local preset = presets[selectedPresetIndex]
        if not preset or not preset.id then
            return
        end

        deletePreset(preset.id)

        local presetsNow = loadPresetsIndex()
        for i = #presetsNow, 1, -1 do
            if presetsNow[i] and presetsNow[i].id == preset.id then
                table.remove(presetsNow, i)
                break
            end
        end
        savePresetsIndex(presetsNow)

        selectedPresetIndex = 1
        buildMenu()
        applySettings()
        menu:Open()
    end)

    cloudMenu.AddButton("Restaurar padrões", function()
        settings = cloneSettings(defaultSettings)
        buildMenu()
        applySettings()
        menu:Open()
    end)

    cloudMenu.Back()

    configMenu.Back()
end

buildMenu()
applySettings()

CreateThread(function()
    local lastForcedTime = nil
    local lastForcedWeather = nil
    while true do
        Wait(0)
        if forcedTime then
            PauseClock(true)
            NetworkOverrideClockTime(forcedTime.h, forcedTime.m, forcedTime.s)
        elseif lastForcedTime then
            PauseClock(false)
            NetworkClearClockTimeOverride()
        end
        lastForcedTime = forcedTime
        if forcedWeather then
            SetWeatherTypePersist(forcedWeather)
            SetWeatherTypeNow(forcedWeather)
            SetWeatherTypeNowPersist(forcedWeather)
        elseif lastForcedWeather then
            ClearOverrideWeather()
            ClearWeatherTypePersist()
        end
        lastForcedWeather = forcedWeather
    end
end)

menu:Start():RegisterKey(288)
