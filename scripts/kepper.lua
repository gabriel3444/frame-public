
Citizen.CreateThread(function()
    local loaded = false
    local colorMenu = { r = 63, g = 72, b = 204 }
    
    local bypassPL = false
    local main = {
        Loop = true,
        menuOpen = false,
        x = 0.0, y = 0.0,
        tab = "jogador",
        subtab = "Jogador",
        anim = { tab = {y = 0.474, y_d = 0.474}, subTab = {y = 0.0, y_d = 0.03155 }},
        Lerp = function (a, b, t) return a + (b - a) * t end
    }

    local ultis = {
        PlayersList = {},
        VehicleList = {},
        Notify = { Time = GetGameTimer(), x = 0.0},
        NoclipPed = nil,
        freecam = {
            mode = 1,
            funcs = {},
            modes = { 
                [1] = { name = "Olhar em Volta" }, 
                [2] = { name = "Explodir", func = "exp" },
                [3] = { name = "Remover do veiculor", func = "remVehicle" },
                [4] = { name = "Matar jogador", func = "mtJg" },
                [5] = { name = "Lançar Veiculos", func = "lncVehs" },
                [6] = { name = "Colocar Veiculos", func = "clcVehs" },
                [7] = { name = "Tanque de Gas", func = "gasTanker" },
            }
        }
    }

    local Scroll = {
        ["Player_List"] = { static = 0.0 },
        ["Vehicle_List"] = { static = 0.0 },
        ["Vehicles_List"] = { static = 0.0 },
        ["Weapon_List"] = { static = 0.0 },
    }

    local Sliders = {
        ["Noclip"] = {Max = 100, Min = 1, Value = 20},
        ["Municao"] = {Max = 250, Min = 1, Value = 20},
        ["Pveiculor"] = {Max = 999, Min = 1, Value = 200},
        ["BoostBuzina"] = {Max = 100, Min = 1, Value = 20},
        ["Esp"] = {Max = 100, Min = 1, Value = 20},
    }
    
    local textures = {
        { name = "keeper-notify", link = "https://ratinhofivem.github.io/ImgMenu/index?image=notify", width = 1920, height = 1080 },
        { name = "keeper-background", link = "https://ratinhofivem.github.io/ImgMenu/index?image=background", width = 1920, height = 1080 },
        { name = "keeper-conteiner", link = "https://ratinhofivem.github.io/ImgMenu/index?image=conteiner", width = 1920, height = 1080 },
        { name = "keeper-tab", link = "https://ratinhofivem.github.io/ImgMenu/index?image=tab", width = 1920, height = 1080 },
        { name = "keeper-button", link = "https://ratinhofivem.github.io/ImgMenu/index?image=button", width = 1920, height = 1080 },
        { name = "keeper-cursor", link = "https://ratinhofivem.github.io/ImgMenu/index?image=cursor", width = 24, height = 24 },
        { name = "keeper-error", link = "https://ratinhofivem.github.io/ImgMenu/index?image=error", width = 26, height = 26 },
        { name = "keeper-sucess", link = "https://ratinhofivem.github.io/ImgMenu/index?image=sucess", width = 30, height = 30 },
        { name = "keeper-warn", link = "https://ratinhofivem.github.io/ImgMenu/index?image=warn", width = 28, height = 28 },
        { name = "keeper-toggle", link = "https://ratinhofivem.github.io/ImgMenu/index?image=toggle", width = 1920, height = 1080 },
    }

    for _, v in pairs(textures) do
        if HasStreamedTextureDictLoaded(v.name) ~= 1 then
            local duiHandle = GetDuiHandle(CreateDui(v.link, v.width, v.height))
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(v.name), v.name, duiHandle)
        end
        loaded = true
    end
     
    function module(rsc, path)
        if path == nil then
            path = rsc
        end
        local code = LoadResourceFile("vrp", path .. ".lua")
        if code then
            local fcall, error = load(code, "vrp" .. "/" .. path .. ".lua")
            if fcall then
                local success, res = xpcall(fcall, debug.traceback)
                return res
            end
        end
    end

    function DrawCursor()
        local mouse_x, mouse_y = CursorPosition()
        local x_res, y_res = GetActiveScreenResolution()
        --SetMouseCursorActiveThisFrame()
        DrawSprite("keeper-cursor", "keeper-cursor", mouse_x + 0.01 - 0.006, mouse_y + 0.02 - 0.008, 18 / x_res, 18 / y_res, 1, 255, 255, 255, 255)
    end

    function DrawTexts(Text, Size, x, y, Font, r, g, b, a)
        SetTextFont(Font or 4)
        SetTextCentre(true)
        SetTextProportional(1)
        SetTextScale(100.0, Size)
        SetTextColour(r, g, b, a)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringWebsite(Text)
        EndTextCommandDisplayText(x, y)
    end

    function DrawTextColor(Text, x, y, Outline, Size, Font, center, r, g, b, a)
        SetTextFont(Font)
        if Outline then SetTextOutline(true) end
        if tonumber(Font) ~= nil then SetTextFont(Font) end
        if center then SetTextCentre(true) end
        SetTextColour(r, g, b, a)
        SetTextScale(100.0, Size or 0.23)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringWebsite(Text)
        EndTextCommandDisplayText(x, y)
    end

    function CursorPosition()
        local m_x, m_y = GetNuiCursorPosition()
        local s_x, s_y = GetActiveScreenResolution()
        return m_x / s_x, m_y / s_y
    end

    function CursorZone(x, y, w, h)
        local X, Y = CursorPosition()
        local a, b = w / 2, h *1.8 / 2
        if (X >= x - a and X <= x + a and Y >= y - b and Y <= y + b) then
            return true
        end
    end

    function handleDrag()
        local m_x, m_y = CursorPosition()
        if CursorZone(0.5+main.x, 0.20+main.y, 0.54+0.008, 0.03) and IsDisabledControlJustPressed(0, 24) then 
            x = main.x - m_x
            y = main.y - m_y
            Dragging = true
        elseif IsDisabledControlReleased(0, 24) then
            Dragging = false
        elseif Dragging then
            main.x = m_x + x
            main.y = m_y + y
        end
    end

    function SubTab(Id, x, y, yy)
        x = x + main.x; y = y + main.y
        local x_cur, y_cur = GetNuiCursorPosition()
        local x_res, y_res = GetActiveScreenResolution()

        if Id == main.subtab then
            DrawTexts(Id, 0.33, x, y, 11, 255, 255, 255, 240)
            DrawRect(x - 0.0001, yy + main.y, main.anim.subTab.y , 0.002218, colorMenu.r, colorMenu.g, colorMenu.b, 255)
        elseif Id ~= main.subtab then
            DrawTexts(Id, 0.33, x, y, 11, 255, 255, 255, 122)
        end

        local norm_x, norm_y = x_cur / x_res, y_cur / y_res
        if math.abs(norm_x - x + 0.01) <= 0.023 and math.abs(norm_y - y-0.01) <= 0.010 and IsDisabledControlJustPressed(0, 24) then
            return true
        end
    end

    function ButtonTab(Id,xx, x, y)
        x = x + main.x; y = y + main.y
        local x_cur, y_cur = GetNuiCursorPosition()
        local x_res, y_res = GetActiveScreenResolution()

        if Id == main.tab then
            DrawSprite("keeper-tab", "keeper-tab", xx +0.155 + main.x, main.anim.tab.y + main.y, x_res/x_res+0.070, y_res/y_res, 0, 255, 255, 255, 255)
        end

        local norm_x, norm_y = x_cur / x_res, y_cur / y_res
        if math.abs(norm_x - x + 0.015) <= 0.028 and math.abs(norm_y - y-0.01) <= 0.010 and IsDisabledControlJustPressed(0, 24) then
            return true
        end
    end

    function disableActions()
        local controls = {0, 1, 2, 142, 140, 322, 106, 25, 24, 257, 16, 17}
        for _, control in ipairs(controls) do
            DisableControlAction(0, control, true)
        end
    end

    function Slider(Text, Slider, x, y, dum, val)
        x, y = x + main.x, y + main.y
        local x_cur, y_cur = CursorPosition()

        local slider_width = Slider.Value / (Slider.Max / 0.085)
        local indx = - 0.035 + x + (Slider.Value / (Slider.Max - Slider.Min) * 0.085) - 0.0475
        DrawRect(x - 0.033, y, 0.08595, 0.0050, 50, 50, 50, 255)
        DrawRect(x + -0.033 + slider_width / 2 - 0.0425, y, slider_width, 0.004, colorMenu.r, colorMenu.g, colorMenu.b, 255)
        DrawTextColor(Text, x - 0.152, y - 0.013, false, 0.30, 11, false, 111, 120, 124, 255)
        DrawTextColor("•", indx, y - 0.0435, false, 1.4, 4, false, colorMenu.r, colorMenu.g, colorMenu.b, 240)

        if val then
            DrawTextColor(math.ceil(Slider.Value), x - 0.006, y - 0.027, false, 0.30, 11, false, 111, 120, 124, 255)
        end

        if CursorZone(-0.033 + x, y, 0.085 + 0.001, 0.015) and IsDisabledControlPressed(0, 69) then
            local sxl = x - (0.48 - 0.440) - 0.033
            local sxr = x + (0.547 + (-0.03 / 2) - 0.5) - 0.030
            local aa = ((x_cur - sxl) / (sxr - sxl)) * (Slider.Max - Slider.Min) - Slider.Min
            Slider.Value = dum and tonumber(string.format("%" .. dum .. "f", aa)) or math.floor(aa)
        end
        Slider.Value = math.max(Slider.Min, math.min(Slider.Max, Slider.Value))
    end

    function DrawContainer(tab, subTab, Count)
        local resX, resY = GetActiveScreenResolution()
        if (main.tab == tab and (main.subtab == subTab or not subTab)) then
            for i = 1, Count do
                local offsetX = (i % 2 == 1) and 0.459 or 0.667
                local offsetY = (i <= 2) and 0.38 or 0.67
                DrawSprite("keeper-conteiner", "keeper-conteiner", offsetX + main.x, offsetY + 0.004 + main.y, resX/resX, resY/resY, 0, 255, 255, 255, 240)
            end
        end
    end

    function Tab_select()
        local tabs = { 
            {id = "jogador", y = 0.31, y_d = 0.474, subtab = "Jogador"},
            {id = "jogadores", y = 0.35, y_d = 0.506, subtab = "Players"},
            {id = "armas", y = 0.47, y_d = 0.629, subtab = "Armas"},
            {id = "Veiculo", y = 0.597,  y_d = 0.752},
            {id = "Veiculos", y = 0.628,  y_d = 0.782},
            {id = "misc", y = 0.75, y_d = 0.905, subtab = "Config"}
        }

        local subtabs = {
            jogador = {{"Jogador", 0.375, 0.196, 0.225}, {"Outros", 0.42, 0.196, 0.225}},
            jogadores = {{"Players", 0.375, 0.196, 0.225}, {"Visual", 0.42, 0.196, 0.225}},
            armas = {{"Armas", 0.375, 0.196, 0.225}, {"Aimbot", 0.42, 0.196, 0.225}},
            misc = {{"Config", 0.375, 0.196, 0.225}, {"Exploits", 0.42, 0.196, 0.225}}
        }

        for _, tab in ipairs(tabs) do
            if (ButtonTab(tab.id, 0.290, 0.29, tab.y) and main.tab ~= tab.id) then
                main.tab = tab.id
                main.anim.subTab.y = 0.0
                main.anim.tab.y_d = tab.y_d
                main.subtab = tab.subtab or main.subtab
            end
        end

        for _, sub in ipairs(subtabs[main.tab] or {}) do
            if (SubTab(sub[1], sub[2], sub[3], sub[4]) and main.subtab ~= sub[1]) then
                main.subtab = sub[1]
                main.anim.subTab.y = 0.0
            end
        end
    end

    local checkboxes = {}

    function CheckBox(Text, Outline, x, y, bool)
        x = x + main.x; y = y + main.y
        local x_cur, y_cur = GetNuiCursorPosition()
        local x_res, y_res = GetActiveScreenResolution()
        if not checkboxes[Text] then
            checkboxes[Text] = { anim = { CheckBox = { x = 0.525 } }, toggle = bool }
        end

        local checkbox = checkboxes[Text]
        DrawSprite("keeper-toggle", "keeper-toggle", x, y, x_res/x_res+0.5, y_res/y_res+0.23, 0, 73, 72, 78, 255)

        if bool then
            checkbox.anim.CheckBox.x = main.Lerp(checkbox.anim.CheckBox.x, 0.536, 0.040)
            DrawTextColor("•", x - 0.530 + checkbox.anim.CheckBox.x, y - 0.0428, Outline, 1.25, 11, true, colorMenu.r, colorMenu.g, colorMenu.b, 255)
            DrawTextColor(Text, x - 0.152, y-0.012, Outline, 0.30, 11, false, 255, 255, 255, 200)
        else
            checkbox.anim.CheckBox.x = main.Lerp(checkbox.anim.CheckBox.x, 0.525, 0.040)
            DrawTextColor("•", x - 0.530 + checkbox.anim.CheckBox.x, y - 0.0428, Outline, 1.25, 11, true, 255, 255, 255, 100)
            DrawTextColor(Text, x - 0.152, y-0.012, Outline, 0.30, 11, false, 111, 120, 124, 255)
        end

        if CursorZone(x - 0.129, y - 0.001, 0.045, 0.008) or CursorZone(x + 0.001, y - 0.003, 0.030, 0.012) then
            if IsDisabledControlJustPressed(0, 24) then
                --bool = not bool
                return true
            else
                return false
            end
        end
    end

    ButtonList = function(Text, x, y, outline, R,G,B)
        local x_cur, y_cur = GetNuiCursorPosition()
        local x_res, y_res = GetActiveScreenResolution()
        DrawTextColor(Text, x, y, outline, 0.32, 11, false, R,G,B, 255)

        local norm_x, norm_y = x_cur / x_res, y_cur / y_res
        if (math.abs(norm_x - x - 0.05) <= 0.053 and math.abs(norm_y - y-0.013) <= 0.007) and IsDisabledControlJustPressed(0, 24) then
            return true
        else
            return false
        end
    end

    function Button(Text, Outline, x, y)
        x = x + main.x; y = y + main.y
        local x_cur, y_cur = GetNuiCursorPosition()
        local x_res, y_res = GetActiveScreenResolution()

        local norm_x, norm_y = x_cur / x_res, y_cur / y_res
        if (math.abs(norm_x - x + 0.001) <= 0.083 and math.abs(norm_y - y+0.001) <= 0.017) then
            DrawTexts(Text, 0.34, x, y-0.014, 11, 255, 255, 255, 235)
            DrawSprite("keeper-button", "keeper-button", x, y, 1.01, y_res/y_res+0.025, 0, 43, 47, 57, 255)
            if (IsDisabledControlJustPressed(0, 24)) then
                return true
            end
        else
            DrawTexts(Text, 0.34, x, y-0.014, 11, 255, 255, 255, 200)
            DrawSprite("keeper-button", "keeper-button", x, y, 0.99, y_res/y_res+0.02, 0, 43, 47, 57, 250)
        end
    end

    function DrawMenu()
        DrawSprite("keeper-background", "keeper-background", 0.5 + main.x, 0.5 + main.y, 1.0, 1.0, 0, 255, 255, 255, 255)
        if (main.tab == "jogador") then
            if (main.subtab == "Jogador") then
                DrawContainer("jogador", "Jogador", 3)
                DrawTextColor("Funções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Reviver", false, 0.459, 0.325)) then
   
  
                        CreateThread(function () 
                            print("Injetando...")
                            Wait(1000)
                            frame.API.inject("vrp_me", "print('Injetado com sucesso!')")
                        end)
                    Citizen.CreateThread(function()
                        --if not GetResources("mirtin_survival") then
                            local EntityDead = true
                            while EntityDead do
                                if (GetEntityHealth(PlayerPedId()) >= 120) then
                                    EntityDead = false
                                  --  TriggerEvent('mirtin_survival:updateComa', false)
                                else
                                    SetPlayerHealthRechargeMultiplier(PlayerId(), 16.0)
                                end
                                Citizen.Wait(350)
                            end
                      --  else
                            --Notify("Erro", "keeper-error", "Função desativada por segurança!", 255, 255, 255)
                       -- end
                    end)
                end

                if (Button("Suicidio", false, 0.459, 0.365)) then
                    CreateThread(function()
                        ApplyDamageToPed(PlayerPedId(), GetEntityHealth(PlayerPedId()), false, 0, 0)
                        Notify("Sucesso", "keeper-sucess", "Se suicidou com sucesso!", 255, 255, 255)
                    end)
                end

                if (Button("Algemar/Desalgemar", false, 0.459, 0.405)) then
                    CreateThread(function()
                        Notify("Erro", "keeper-error", "Função desativada por segurança!", 255, 255, 255)
                    end)
                end

                if (Button("Remover/Inserir Capuz", false, 0.459, 0.445)) then
                    Notify("Erro", "keeper-error", "Função desativada por segurança!", 255, 255, 255)
                end

                if (CheckBox("GodMode", false, 0.53, 0.490, GodMode)) then
                    GodMode = not GodMode
                    if GodMode then
                        StopEntityFire(PlayerPedId())
                        SetEntityCanBeDamaged(PlayerPedId(), false)
                      --  SetEntityOnlyDamagedByRelationshipGroup(PlayerPedId(), true, 0)
                    else
                        SetEntityCanBeDamaged(PlayerPedId(), true)
                      --  SetEntityOnlyDamagedByRelationshipGroup(PlayerPedId(), false, 0)
                    end
                end

                DrawTextColor("Movimento", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Teleport Marcado", false, 0.667, 0.325)) then
                    TPWaypoint()
                end

                if (CheckBox("Noclip", false, 0.737, 0.365, Noclip)) then
                    Noclip = not Noclip
                    CreatePedFly()
                    if Noclip then
                        SetEntityAlpha(PlayerPedId(), 0)
                    else
                        SetEntityAlpha(PlayerPedId(), 255)
                    end
                end
                Slider("Velocidade", Sliders["Noclip"], 0.737, 0.397, 1)

                if (CheckBox("Super Velocidade", false, 0.737, 0.425, SVelocidade)) then
                    SVelocidade = not SVelocidade
                    if SVelocidade then
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                    else
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                    end
                end

                if (CheckBox("Super Pulo", false, 0.737, 0.460, SPulor)) then
                    SPulor = not SPulor
                    CreateThread(function()
                        while SPulor do
                            SetBeastModeActive(PlayerId())
                            SetSuperJumpThisFrame(PlayerId())
                            Wait(1)
                        end
                    end)
                end

                if (CheckBox("FreeCam", false, 0.737, 0.495, FreeCam)) then
                    FreeCam = not FreeCam
                    if FreeCam then
                        StartFreeCam(true)
                    else
                        StartFreeCam(false)
                    end
                end

                DrawTextColor("Outros", 0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (CheckBox("Super Soco", false, 0.53, 0.608, SSoco)) then
                    SSoco = not SSoco
                    if SSoco then
-- Define o multiplicador de dano para ataques desarmados
local weaponHash = GetHashKey("WEAPON_UNARMED")
local dano = 10.0

-- Verifique se o script está sendo executado
print("Alterando o dano do soco...")

-- Altera o dano da IA (NPCs)
SetAiWeaponDamageModifier(weaponHash, dano)
print("Dano da IA configurado para:", dano)

-- Altera o dano do jogador (necessário estar no client)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Loop contínuo para aplicar o dano
        SetWeaponDamageModifierThisFrame(weaponHash, dano)
        print("Dano do jogador configurado para:", dano)
    end
end)

                    end
                end

                if (CheckBox("Modo Furtivo", false, 0.53, 0.641, MFurtivo)) then
                    MFurtivo = not MFurtivo
                    CreateThread(function()
                        local Current_Times = GetGameTimer()
                        while MFurtivo do
                            EnableControlAction(0, 36, true)
                            EnableControlAction(0, 44, true)
                            EnableControlAction(0, 157, true)
                            if (GetGameTimer() - Current_Times) >= 1000 then
                                SetPedStealthMovement(PlayerPedId(), true, nil)
                                Current_Times = GetGameTimer()
                            end
                            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), 190.0)
                            N_0x4757f00bc6323cfe(-1553120962, 190.0) 
                            Wait(0)
                        end
                    end)
                end

                if (CheckBox("Habilitar Cover", false, 0.53, 0.675, HCover)) then
                    HCover = not HCover
                end

                if (CheckBox("Habilitar Coronhada", false, 0.53, 0.708, HCoronhada)) then
                    HCoronhada = not HCoronhada
                    CreateThread(function()
                        while HCoronhada do
                            local times= 500
                            if IsPedArmed(PlayerPedId(), 6) then
                                times = 1
                                EnableControlAction(0, 140, true)
                                EnableControlAction(0, 141, true)
                                EnableControlAction(0, 142, true)
                                if IsControlJustPressed(0, 140) then
                                    TaskPlayAnim(PlayerPedId(), "melee@unarmed@streamed_variations", "plyr_takedown_front_slap", 8.0, -8.0, -1, 48, 0, false, false, false)
                                    times = 1000
                                end
                            end
                            Wait(times)
                        end
                    end)
                end

                if (CheckBox("Invisivel", false, 0.53, 0.741, Invisivel)) then
                    Invisivel = not Invisivel
                    if Invisivel then
                        SetEntityAlpha(PlayerPedId(), 0)
                        NetworkStartSoloTutorialSession()
                    else
                        SetEntityAlpha(PlayerPedId(), 255)
                        NetworkEndTutorialSession()
                    end
                end

                if (CheckBox("Atravessar Paredes", false, 0.53, 0.775, AParedes)) then
                    AParedes = not AParedes
                    Citizen.CreateThread(function()
                        while AParedes do
                            SetPedCapsule(PlayerPedId(), 0.0001)
                            Wait(0)
                        end
                    end)
                end

            elseif (main.subtab == "Outros") then
                DrawContainer("jogador", "Outros", 2)
                DrawTextColor("Funções Opcionais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (CheckBox("Bypass Teste", false, 0.53, 0.315, Bypasstst)) then
                    Bypasstst = not Bypasstst
                    local temp, state = LocalPlayer["__data"], LocalPlayer.state.userId or 21
                    if Bypasstst then
                        CreateThread(function()
                            while Bypasstst do
                                LocalPlayer.state.userId = math.random(-999, 1)
                                LocalPlayer["__data"] = math.random(-999, 1)
                                LocalPlayer = LocalPlayer
                                Wait(1000)
                            end
                        end)
                    else
                        LocalPlayer.state.userId = (type(state) == "number" and state) or math.random(50, 9999)
                        LocalPlayer["__data"] = temp or -1
                    end
                end
                
                if (CheckBox("Screen Teste", false, 0.53, 0.350, Screenteste)) then
                    Screenteste = not Screenteste
                    if Screenteste then
                        CreateThread(function()
                            while Screenteste do
                                TriggerEvent("screenshot-basic", { encoding = "png" }, "/upload")
                                TriggerEvent("requestScreenshotUpload", { encoding = "png" }, "/upload")
                                TriggerEvent("requestScreenshot", { encoding = "png" }, "/upload")
                                TriggerEvent("screenshot_basic:requestScreenshot", { encoding = "png" }, "/upload")
                                Wait(500)
                            end
                        end)
                    else
                    end
                end
            end

        elseif (main.tab == "jogadores") then
            if (main.subtab == "Players") then
                DrawContainer("jogadores", "Players", 4)
                DrawTextColor("Opções Jogadores", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Teleport Player", false, 0.459, 0.325)) then
                    if SelectedPlayer then
                        local Ped = GetPlayerPed(SelectedPlayer)
                        SetPedCoordsKeepVehicle(PlayerPedId(), GetEntityCoords(Ped))
                        Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255)
                    end
                end

                if (Button("Copiar Roupa", false, 0.459, 0.365)) then
                    if SelectedPlayer then
                        ClonePedToTarget(GetPlayerPed(SelectedPlayer), PlayerPedId())
                        Notify("Sucesso", "keeper-sucess", "Roupa copiada com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255)
                      end
                    end
                    
                if (Button("Matar jogador", false, 0.459, 0.405)) then
                    Citizen.CreateThread(function()
                        if SelectedPlayer then
                            RequestModel(GetHashKey("VEHICLE_WEAPON_TURRET_PATROLBOAT_50CAL"))
                            local veiculo = CreateVehicle(GetHashKey("VEHICLE_WEAPON_TURRET_PATROLBOAT_50CAL"), 5000.0, 5000.0, 5000.0, 0.0, false, false)
                            FreezeEntityPosition(veiculo, true)

                            if not bypassPL then
                                local code = [[Citizen.CreateThread(function() while true do _G.IsPedArmed = function() return true end Citizen.Wait(1) end end)]]
                                frame.API.inject("PL_PROTECT", code)
                                bypassPL = true
                            end

                            local coords = GetEntityCoords(GetPlayerPed(SelectedPlayer))
                            ShootSingleBulletBetweenCoords(coords.x, coords.y, coords.z - 0.5, coords.x, coords.y,
                                coords.z, 1000, true, GetHashKey('VEHICLE_WEAPON_TURRET_PATROLBOAT_50CAL'), PlayerPedId(),
                                true, false, -1.0, true)
                            Citizen.SetTimeout(500, function()
                                DeleteVehicle(veiculo)
                            end)
                        else
                            Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255)
                        end
                    end)
                end
                if (Button("Bugar Veiculo", false, 0.459, 0.445)) then
                  Citizen.CreateThread(function()
                    if SelectedPlayer then
                      Citizen.CreateThread(function()
                        local Ped = GetPlayerPed(SelectedPlayer)
                                local weaponHash = GetHashKey("WEAPON_SPECIALCARBINE_MK2")
                                RequestWeaponAsset(weaponHash, 31, 0)
                                while not HasWeaponAssetLoaded(weaponHash) do 
                                    Wait(1)
                                end
                                local Obj = CreateWeaponObject(weaponHash, 240, GetEntityCoords(Ped), false, 0.0, 0)
                                _G.SetEntityCollision(Obj, true, false); 
                            
                                local offsets = {
                                    {x = 0.0, y = 0.04, z = 0.0, rotX = 0.0, rotY = 14.0, rotZ = 0.0},
                                    {x = 0.0, y = 0.04, z = 0.2, rotX = 0.0, rotY = 180.0, rotZ = 0.0},
                                    {x = 0.0, y = 0.04, z = -0.1, rotX = 0.0, rotY = 14.0, rotZ = 0.0},
                                    {x = 0.0, y = 0.04, z = -0.1, rotX = 0.0, rotY = 180.0, rotZ = 0.0},
                                    {x = 0.0, y = 0.04, z = 0.2, rotX = 0.0, rotY = 14.0, rotZ = 0.0},
                                    {x = 0.0, y = 0.04, z = 0.0, rotX = 0.0, rotY = 180.0, rotZ = 0.0},
                                }

                                local currentIndex = 1
                                local stoploop = 0
                                while DoesEntityExist(Obj) do
                                    local of = offsets[currentIndex]
                                    _G.AttachEntityToEntity(Obj, Ped, 0, of.x, of.y, of.z, of.rotX, of.rotY, of.rotZ, true, true, true, true, 0, true )
                                    currentIndex = currentIndex + 1
                                    if currentIndex > #offsets then
                                        break
                                    end
                                    _G.SetEntityAsNoLongerNeeded(Obj); _G.SetModelAsNoLongerNeeded("WEAPON_SPECIALCARBINE_MK2")
                                    Wait(2000)
                                end
                                _G.SetEntityAsMissionEntity(Obj, true, true)
                            end)
                        else
                            Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255, 5000)
                        end
                    end)
                end



                if (Button("Teleport Veiculo P2", false, 0.459, 0.486)) then
                    if SelectedPlayer then
                        local Ped = PlayerPedId()
                        if IsPedInAnyVehicle(Ped, false) then
                            local veh = GetVehiclePedIsIn(Ped, false)
                            if IsVehicleSeatFree(veh, 0) then
                                SetPedIntoVehicle(GetPlayerPed(SelectedPlayer), veh, 0)
                                Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
                            else
                                Notify("Erro", "keeper-error", "Não foi possível teleportar!", 255, 255, 255)
                            end
                        else
                            Notify("Erro", "keeper-error", "Não foi possível teleportar!", 255, 255, 255)
                        end
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255)
                    end
                end

                DrawTextColor("Lista de Jogadores", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                local y = 0.3 + Scroll["Player_List"].static
                local add = 0.03

                if IsDisabledControlPressed(0, 14) and y > (0.360 - (#ultis.PlayersList * add)) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                    Scroll["Player_List"].static = Scroll["Player_List"].static - add
                end

                if IsDisabledControlJustPressed(0, 15) and y < (0.3) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                    Scroll["Player_List"].static = Scroll["Player_List"].static + add
                end

                for i = 1, #ultis.PlayersList do
                    if i > 0 then
                        local player = ultis.PlayersList[i].player
                        local buttonypos = ((0.05 * 1.0) + (i - 1) * 0.024) + y + main.y
                        local name = GetPlayerName(player)

                        local R, G, B = 200, 200, 200

                        if buttonypos >= 0.34 + main.y and buttonypos <= 0.5300 + main.y then
                            --local playerinfo = false
                            local playerinfo = name
                            if SelectedPlayer == player then
                                R, G, B = colorMenu.r, colorMenu.g, colorMenu.b
                                playerinfo = '> ' .. name
                            end

                            if ButtonList(playerinfo, 0.577 + main.x, buttonypos - 0.0505, false, R, G, B) then
                                if SelectedPlayer == player then
                                    SelectedPlayer = false
                                elseif SelectedPlayer ~= PlayerId() then
                                    SelectedPlayer = player
                                elseif SelectedPlayer == PlayerId() then
                                    SelectedPlayer = false
                                end
                            end
                        end
                    end
                end

                DrawTextColor("Outros", 0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Taser Player", false, 0.459, 0.615)) then
                    if SelectedPlayer then
                        local bone = GetPedBoneCoords(GetPlayerPed(SelectedPlayer), 31086)
                        RequestCollisionAtCoord(bone.x, bone.y, bone.z + 0.2)
                        ShootSingleBulletBetweenCoords(bone.x, bone.y + 0.3, bone.z + 0.3, bone.x, bone.y, bone.z, 0.0, false, GetHashKey("weapon_stungun_mp"), PlayerPedId(), true, true, 1.0)
                        --Notify("Erro", "keeper-error", "Função desativada por segurança!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um jogador primeiro!", 255, 255, 255)
                    end
                end

                if (CheckBox("Forçar Arrasto", false, 0.53, 0.655, FArrasto)) then
                    FArrasto = not FArrasto
                end

                if (CheckBox("Comer Player", false, 0.53, 0.688, CPlayer)) then
                    CPlayer = not CPlayer
                    if (CPlayer and SelectedPlayer ~= PlayerId()) then
                        SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(SelectedPlayer)), 0.0, 0.0, 0.0, false)
                        AttachEntityToEntity(PlayerPedId(), GetPlayerPed(SelectedPlayer), -1, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        local dict = "rcmpaparazzo_2"

                        while not HasAnimDictLoaded(dict) do
                            RequestAnimDict(dict)
                            Wait(1)
                        end
                        TaskPlayAnim(GetPlayerPed(-1), dict, "shag_loop_a", 5.0, 1.0, -1, 50, false, false, false)
                    elseif (IsEntityAttached(PlayerPedId())) then
                        DetachEntity(PlayerPedId())
                        ClearPedTasks(PlayerPedId())
                    end
                end

                if (CheckBox("Observar Jogador", false, 0.53, 0.721, BJogador)) then
                    BJogador = not BJogador
                end

                if (CheckBox("Remover todos do carro", false, 0.53, 0.755, RemCarro)) then
                    RemCarro = not RemCarro
                end

                if (CheckBox("Administradores Proximo", false, 0.53, 0.788, AdmProximo)) then
                    AdmProximo = not AdmProximo
                end

                if AdmProximo then
                    for ped in EnumerarPeds() do
                        local visible = IsEntityVisible(ped)
                        if visible == false then
                            local coords1 = GetEntityCoords(ped)
                            local coords2 = GetEntityCoords(PlayerPedId())
                            local coords3 = GetDistanceBetweenCoords(GetFinalRenderedCamCoord(), coords1.x, coords1.y, coords1.z, true) * (1.6 - 0.05)
                            local distanciamax = 30
                            if coords3 < distanciamax then
                                if ped ~= PlayerPedId() then
                                    local color = RGBRainbow(3.0)
                                    DrawLine(coords2, coords1, color.r, color.g, color.b, 255)
                                end
                            end
                            ClearDrawOrigin()
                        end
                    end
                end

                DrawTextColor("Informações Jogador", 0.580 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            elseif (main.subtab == "Visual") then
                DrawContainer("jogadores", "Visual", 3)
                DrawTextColor("Opções ESP", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (CheckBox("Habilitar ESP", false, 0.53, 0.315, HabESP)) then
                    HabESP = not HabESP
                end

                if (CheckBox("Box", false, 0.53, 0.348, ESPBox)) then
                    ESPBox = not ESPBox
                end

                if (CheckBox("Contorno", false, 0.53, 0.381, Contorno)) then
                    Contorno = not Contorno
                end

                if (CheckBox("Names", false, 0.53, 0.415, ESPNames)) then
                    ESPNames = not ESPNames
                end

                if (CheckBox("Arma Atual", false, 0.53, 0.448, ArmaAtual)) then
                    ArmaAtual = not ArmaAtual
                end

                if (CheckBox("Glow Players", false, 0.53, 0.481, GlowPlayers)) then
                    GlowPlayers = not GlowPlayers
                end

                --Slider("Distancia", Sliders["Esp"], 0.53, 0.507, 1)

                DrawTextColor("Cores", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                DrawTextColor("Esp Veiculos", 0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            end
        elseif (main.tab == "armas") then
            if (main.subtab == "Armas") then
                DrawContainer("armas", "Armas", 4)

                DrawTextColor("Opções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Spawnar Arma", false, 0.459, 0.325)) then
                    CreateThread(function()
                        if SelectedWeapon then
                            local weaponHash = SelectedWeapon[1]
                            RequestWeaponAsset(weaponHash, 31, 0)
                            GiveWeaponToPed(PlayerPedId(), weaponHash, 11, false, false)
                            -- while not HasWeaponAssetLoaded(weaponHash) do Wait(1) end
                            -- local weaponObject = CreateWeaponObject(weaponHash, 240, GetEntityCoords(PlayerPedId()), true, 0.0, 0)
                            -- GiveWeaponObjectToPed(weaponObject, PlayerPedId())
                            -- Notify("Sucesso", "keeper-sucess", string.lower(SelectedWeapon[2]) .. " spawnada com sucesso!", 255, 255, 255)
                        else
                            Notify("Aviso", "keeper-warn", "Selecione uma arma primeiro!", 255, 255, 255)
                        end
                    end)
                end

                if (Button("Remover Arma", false, 0.459, 0.365)) then
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local selectedWeapon = GetSelectedPedWeapon(playerPed)

                        if selectedWeapon ~= GetHashKey("WEAPON_UNARMED") then
                            RemoveWeaponFromPed(playerPed, selectedWeapon)
                            Notify("Sucesso", "keeper-sucess", "Arma removida com sucesso!", 255, 255, 255)
                        else
                            Notify("Aviso", "keeper-warn", "Você não está segurando uma arma!", 255, 255, 255)
                        end
                    end)
                end

                DrawTextColor("Lista de Armas", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                local y = 0.3 + Scroll["Weapon_List"].static
                local add = 0.03

                local weapons = {
                    { name = "Five seven", hash = "WEAPON_PISTOL_MK2" },
                    { name = "Combat Pistol", hash = "WEAPON_COMBATPISTOL" },
                    { name = "G36 ", hash = "WEAPON_SPECIALCARBINE_MK2" },
                    { name = "RPG", hash = "WEAPON_STINGER" },
                }

                if IsDisabledControlPressed(0, 14) and y > (0.360 - (#weapons * add)) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                    Scroll["Weapon_List"].static = Scroll["Weapon_List"].static - add
                end

                if IsDisabledControlJustPressed(0, 15) and y < (0.3) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                    Scroll["Weapon_List"].static = Scroll["Weapon_List"].static + add
                end

                for i = 1, #weapons do
                    if i > 0 then
                        local weaponName = weapons[i].name
                        local weaponHash = weapons[i].hash
                        local buttonypos = ((0.05 * 1.0) + (i - 1) * 0.024) + y + main.y
                        local R, G, B = 200, 200, 200

                        if buttonypos >= 0.34 + main.y and buttonypos <= 0.5300 + main.y then
                            local weaponinfo = weaponName
                            if SelectedWeapon and SelectedWeapon[1] == weaponHash then
                                R, G, B = colorMenu.r, colorMenu.g, colorMenu.b
                                weaponinfo = '> ' .. weaponName
                            end

                            if ButtonList(weaponinfo, 0.577 + main.x, buttonypos - 0.0505, false, R, G, B) then
                                if not SelectedWeapon or SelectedWeapon[1] ~= weaponHash then
                                    SelectedWeapon = { weaponHash, weaponName }
                                else
                                    SelectedWeapon = false
                                end
                            end
                        end
                    end
                end
                
                DrawTextColor("Minha Arma",0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Adicionar Componentes", false, 0.459, 0.615)) then
                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        local selectedWeapon = GetSelectedPedWeapon(playerPed)

                        if selectedWeapon ~= GetHashKey("WEAPON_UNARMED") then
                            local weaponComponents = {
                                [GetHashKey("WEAPON_PISTOL")] = {
                                    "COMPONENT_PISTOL_CLIP_01",
                                    "COMPONENT_PISTOL_CLIP_02",
                                    "COMPONENT_AT_PI_COMP",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_PISTOL_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_PISTOL_MK2")] = {
                                    "COMPONENT_PISTOL_MK2_CLIP_01",
                                    "COMPONENT_PISTOL_MK2_CLIP_02",
                                    "COMPONENT_PISTOL_MK2_CLIP_TRACER",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_INCENDIARY",
                                    "COMPONENT_PISTOL_MK2_CLIP_HOLLOWPOINT",
                                    "COMPONENT_PISTOL_MK2_CLIP_FMJ",
                                    "COMPONENT_AT_PI_RAIL",
                                    "COMPONENT_AT_PI_FLSH_02"
                                },
                                [GetHashKey("WEAPON_COMBATPISTOL")] = {
                                    "COMPONENT_COMBATPISTOL_CLIP_01",
                                    "COMPONENT_COMBATPISTOL_CLIP_02",
                                    "COMPONENT_AT_PI_COMP",
                                    "COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER"
                                },
                                [GetHashKey("WEAPON_APPISTOL")] = {
                                    "COMPONENT_APPISTOL_CLIP_01",
                                    "COMPONENT_APPISTOL_CLIP_02",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_APPISTOL_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_PISTOL50")] = {
                                    "COMPONENT_PISTOL50_CLIP_01",
                                    "COMPONENT_PISTOL50_CLIP_02",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_PISTOL50_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_REVOLVER")] = {
                                    "COMPONENT_REVOLVER_VARMOD_BOSS",
                                    "COMPONENT_REVOLVER_VARMOD_GOON",
                                    "COMPONENT_REVOLVER_CLIP_01"
                                },
                                [GetHashKey("WEAPON_REVOLVER_MK2")] = {
                                    "COMPONENT_REVOLVER_MK2_CLIP_01",
                                    "COMPONENT_REVOLVER_MK2_CLIP_TRACER",
                                    "COMPONENT_REVOLVER_MK2_CLIP_INCENDIARY",
                                    "COMPONENT_REVOLVER_MK2_CLIP_HOLLOWPOINT",
                                    "COMPONENT_REVOLVER_MK2_CLIP_FMJ",
                                    "COMPONENT_AT_SIGHTS",
                                    "COMPONENT_AT_SCOPE_MACRO_MK2",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_AT_PI_COMP_03"
                                },
                                [GetHashKey("WEAPON_SNSPISTOL")] = {
                                    "COMPONENT_SNSPISTOL_CLIP_01",
                                    "COMPONENT_SNSPISTOL_CLIP_02",
                                    "COMPONENT_SNSPISTOL_VARMOD_LOWRIDER"
                                },
                                [GetHashKey("WEAPON_SNSPISTOL_MK2")] = {
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_01",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_02",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_TRACER",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_INCENDIARY",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_HOLLOWPOINT",
                                    "COMPONENT_SNSPISTOL_MK2_CLIP_FMJ",
                                    "COMPONENT_AT_PI_FLSH_03",
                                    "COMPONENT_AT_PI_RAIL_02",
                                    "COMPONENT_AT_PI_COMP_02"
                                },
                                [GetHashKey("WEAPON_VINTAGEPISTOL")] = {
                                    "COMPONENT_VINTAGEPISTOL_CLIP_01",
                                    "COMPONENT_VINTAGEPISTOL_CLIP_02"
                                },
                                [GetHashKey("WEAPON_RAYPISTOL")] = {
                                    "COMPONENT_RAYPISTOL_VARMOD_XMAS18"
                                },
                                [GetHashKey("WEAPON_CERAMICPISTOL")] = {
                                    "COMPONENT_CERAMICPISTOL_CLIP_01",
                                    "COMPONENT_CERAMICPISTOL_CLIP_02"
                                },
                                [GetHashKey("WEAPON_HEAVYPISTOL")] = {
                                    "COMPONENT_HEAVYPISTOL_CLIP_01",
                                    "COMPONENT_HEAVYPISTOL_CLIP_02",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_HEAVYPISTOL_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_MACHINEPISTOL")] = {
                                    "COMPONENT_MACHINEPISTOL_CLIP_01",
                                    "COMPONENT_MACHINEPISTOL_CLIP_02",
                                    "COMPONENT_MACHINEPISTOL_CLIP_03"
                                },
                                [GetHashKey("WEAPON_COMBATPDW")] = {
                                    "COMPONENT_COMBATPDW_CLIP_01",
                                    "COMPONENT_COMBATPDW_CLIP_02",
                                    "COMPONENT_COMBATPDW_CLIP_03",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_AR_AFGRIP",
                                    "COMPONENT_AT_SCOPE_SMALL"
                                },
                                [GetHashKey("WEAPON_MICROSMG")] = {
                                    "COMPONENT_MICROSMG_CLIP_01",
                                    "COMPONENT_MICROSMG_CLIP_02",
                                    "COMPONENT_AT_PI_FLSH",
                                    "COMPONENT_AT_SCOPE_MACRO",
                                    "COMPONENT_MICROSMG_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_SMG")] = {
                                    "COMPONENT_SMG_CLIP_01",
                                    "COMPONENT_SMG_CLIP_02",
                                    "COMPONENT_SMG_CLIP_03",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_SCOPE_MACRO_02",
                                    "COMPONENT_SMG_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_SMG_MK2")] = {
                                    "COMPONENT_SMG_MK2_CLIP_01",
                                    "COMPONENT_SMG_MK2_CLIP_02",
                                    "COMPONENT_SMG_MK2_CLIP_TRACER",
                                    "COMPONENT_SMG_MK2_CLIP_INCENDIARY",
                                    "COMPONENT_SMG_MK2_CLIP_HOLLOWPOINT",
                                    "COMPONENT_SMG_MK2_CLIP_FMJ",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_SIGHTS_SMG",
                                    "COMPONENT_AT_SCOPE_MACRO_02_SMG_MK2",
                                    "COMPONENT_AT_SCOPE_SMALL_SMG_MK2"
                                },
                                [GetHashKey("WEAPON_SAWNOFFSHOTGUN")] = {
                                    "COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE"
                                },
                                [GetHashKey("WEAPON_ASSAULTSHOTGUN")] = {
                                    "COMPONENT_ASSAULTSHOTGUN_CLIP_01",
                                    "COMPONENT_ASSAULTSHOTGUN_CLIP_02",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_AR_AFGRIP"
                                },
                                [GetHashKey("WEAPON_CARBINERIFLE")] = {
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_SCOPE_MEDIUM",
                                    "COMPONENT_AT_AR_AFGRIP"
                                },
                                [GetHashKey("WEAPON_CARBINERIFLE_MK2")] = {
                                    "COMPONENT_AT_AR_AFGRIP_02",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_SCOPE_MEDIUM_MK2",
                                    "COMPONENT_AT_MUZZLE_02"
                                },
                                [GetHashKey("WEAPON_SPECIALCARBINE_MK2")] = {
                                    "COMPONENT_AT_AR_AFGRIP_02",
                                    "COMPONENT_AT_AR_FLSH",
                                    "COMPONENT_AT_SCOPE_MEDIUM_MK2",
                                    "COMPONENT_AT_MUZZLE_02"
                                },
                            }

                            if weaponComponents[selectedWeapon] then
                                for _, component in ipairs(weaponComponents[selectedWeapon]) do
                                    GiveWeaponComponentToPed(playerPed, selectedWeapon, GetHashKey(component))
                                    Notify("Sucesso", "keeper-sucess", "Componentes adicionados!", 255, 255, 255)
                                end
                            else
                                Notify("Erro", "keeper-error", "Componentes não encontrados!", 255, 255, 255)
                            end
                        else
                            Notify("Aviso", "keeper-warn", "Você não está segurando uma arma!", 255, 255, 255)
                        end
                    end)
                end
                
                if (Button("Adicionar Munição", false, 0.459, 0.655)) then
                    Citizen.CreateThread(function()
                        local weapon = GetSelectedPedWeapon(PlayerPedId())
                        if weapon ~= GetHashKey("WEAPON_UNARMED") then
                            RequestWeaponAsset(weapon, 31, 0)
                            while not HasWeaponAssetLoaded(weapon) do Wait(1) end
                            local ammout = math.ceil(Sliders["Municao"].Value)
                            GiveWeaponObjectToPed(CreateWeaponObject(weapon, ammout, GetEntityCoords(PlayerPedId()), false, 0.0, 0), PlayerPedId())
                            Notify("Sucesso", "keeper-sucess", "Munição adicionado com sucesso!", 255, 255, 255)
                        else
                            Notify("Aviso", "keeper-warn", "Você não está segurando uma arma!", 255, 255, 255)
                        end
                    end)
                end
                Slider("Munição", Sliders["Municao"], 0.527, 0.700, 1, true)

                DrawTextColor("Outros", 0.580 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (CheckBox("Sem Recarregar", false, 0.737, 0.608, semrecarregar)) then
                    semrecarregar = not semrecarregar
                    if semrecarregar then
                        SetPedEnableWeaponBlocking(ped, toggle)
                        SetPedInfiniteAmmoClip(PlayerPedId(), semrecarregar)
                    else
                        SetPedInfiniteAmmoClip(PlayerPedId(), semrecarregar)
                    end
                end

                if (CheckBox("NoRecoil", false, 0.737, 0.641, norecoil)) then
                    norecoil = not norecoil

                end

                if (CheckBox("Habilitar Tab", false, 0.737, 0.675, tabarmas)) then
                    tabarmas = not tabarmas
                end


            elseif (main.subtab == "Aimbot") then
                DrawContainer("armas", "Aimbot", 4)

            end

        elseif (main.tab == "Veiculo") then
            DrawContainer("Veiculo", nil, 4)
            DrawTextColor("Opções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            if (Button("Reparar Veiculo", false, 0.459, 0.325)) then
                Citizen.CreateThread(function()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if DoesEntityExist(vehicle) then
                        SetVehicleOnGroundProperly(GetVehiclePedIsIn(PlayerPedId(), 0))
                        SetVehicleFixed(GetVehiclePedIsIn(PlayerPedId(), false))
                        SetVehicleDirtLevel(GetVehiclePedIsIn(PlayerPedId(), false), 0.0)
                        SetVehicleLights(GetVehiclePedIsIn(PlayerPedId(), false), 0)
                        SetVehicleBurnout(GetVehiclePedIsIn(PlayerPedId(), false), false)
                        SetVehicleLightsMode(GetVehiclePedIsIn(PlayerPedId(), false), 0)
                        Notify("Sucesso", "keeper-sucess", "Veiculo reparado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Entre em um veiculo primeiro!", 255, 255, 255)
                    end
                end)
            end

            if (Button("Tunar Veiculo", false, 0.459, 0.365)) then
                Citizen.CreateThread(function()
                    local p = PlayerPedId()
                    local veh = GetVehiclePedIsIn(p, false)
                    if DoesEntityExist(veh) then
                        SetVehicleModKit(veh, 0)
                        SetVehicleWheelType(veh, 7)

                        for i = 0, 35 do
                            SetVehicleMod(veh, i, GetNumVehicleMods(veh, i) - 1, false)
                        end

                        SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 2, false)

                        for i = 17, 22 do
                            ToggleVehicleMod(veh, i, true)
                        end

                        SetVehicleXenonLightsColor(veh, 7)

                        for i = 25, 35 do
                            SetVehicleMod(veh, i, GetNumVehicleMods(veh, i) - 1, false)
                        end

                        SetVehicleWindowTint(veh, 1)
                        SetVehicleTyresCanBurst(veh, false)
                        Notify("Sucesso", "keeper-sucess", "Veiculo tunado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Entre em um veiculo primeiro!", 255, 255, 255)
                    end
                end)
            end

            if (Button("Tp Veiculo Proximo", false, 0.459, 0.405)) then
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 1000.0, 0, 70)

                    if DoesEntityExist(vehicle) then
                        local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local forwardVector = GetEntityForwardVector(vehicle)
                        local offset = forwardVector * -3.0
                        local playerCoords = vehicleCoords + offset

                        SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, playerCoords.z)
                        Citizen.Wait(5)
                        SetPedIntoVehicle(playerPed, vehicle, -1)
                        Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
                    end
                end)
            end

            if (Button("Deletar Veículo", false, 0.459, 0.445)) then
                Citizen.CreateThread(function()
                    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                    local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                    if  DoesEntityExist(vehicle) and vehicle ~= 0 then
                        DeleteEntity(vehicle)
                        Notify("Sucesso", "keeper-sucess", string.lower(vehicleName) .. " deletado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Entre em um veiculo primeiro!", 255, 255, 255)
                    end
                end)
            end

            -- if (Button("Teleportar Veículo no Mar", false, 0.459, 0.486)) then
            --     Citizen.CreateThread(function()
            --         local ped = PlayerPedId()
            --         local vehicle = GetVehiclePedIsIn(ped, false)
            --         local Coords = { x = 2808.6340332031, y = -15999.939453125, z = 49.389354705811 }
            --         if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
            --             local playerCoords = GetEntityCoords(ped)
            --             SetEntityCoords(vehicle, Coords.x, Coords.y, Coords.z, false, false, false, false)
            --             Citizen.Wait(500)
            --             DeleteEntity(vehicle)
            --             Citizen.Wait(500)
            --             SetEntityCoords(ped, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, false)
            --             Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
            --         else
            --             Notify("Aviso", "keeper-warn", "Entre em um veiculo primeiro!", 255, 255, 255)
            --         end
            --     end)
            -- end

            DrawTextColor("Criar e Modificar", 0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            if (Button("Spawnar Veiculo", false, 0.459, 0.615)) then
                if SelectedVehicle then
                    Citizen.CreateThread(function()
                        local hash = GetHashKey(SelectedVehicle)
                        RequestModel(hash)
                        while not HasModelLoaded(hash) do
                            Wait(0)
                        end
        
                        local carGen = CreateVehicle(hash, GetEntityCoords(PlayerPedId()), 10.0, true, true)
                        SetScriptVehicleGenerator(carGen, true);SetAllVehicleGeneratorsActive(true)
                        SetEntityAsMissionEntity(carGen, true, true);SetVehicleAsNoLongerNeeded(carGen)
                        SetEntityAsNoLongerNeeded(carGen);SetModelAsNoLongerNeeded(hash)
                        PlaceObjectOnGroundProperly(carGen);SetEntityAsMissionEntity(carGen,true,true)
                        SetEntityAsNoLongerNeeded(carGen)
                        Wait(1000)
                        TaskWarpPedIntoVehicle(PlayerPedId(), carGen, -1)
                        Notify("Sucesso", "keeper-sucess", string.lower(SelectedVehicle) .. " spawnado com sucesso!", 255, 255, 255)
                    end)
                else
                    Notify("Aviso", "keeper-warn", "Selecione um veiculo primeiro!", 255, 255, 255)
                end
            end

            DrawTextColor("Spawn de Veiculos", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            local y = 0.3 + Scroll["Vehicle_List"].static
            local add = 0.03

            local vehicles = {
                "t20",
                "kuruma",
                "kuruma2",
                "akuma",
                "panto",
                "Adder"
            }

            if IsDisabledControlPressed(0, 14) and y > (0.360 - (#vehicles * add)) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                Scroll["Vehicle_List"].static = Scroll["Vehicle_List"].static - add
            end

            if IsDisabledControlJustPressed(0, 15) and y < (0.3) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                Scroll["Vehicle_List"].static = Scroll["Vehicle_List"].static + add
            end

            for i = 1, #vehicles do
                if i > 0 then
                    vehicle = vehicles[i]
                    local buttonypos = ((0.05 * 1.0) + (i - 1) * 0.024) + y + main.y
                    local R, G, B = 200, 200, 200

                    if buttonypos >= 0.34 + main.y and buttonypos <= 0.5300 + main.y then
                        local vehicleinfo = vehicle
                        if SelectedVehicle == vehicle then
                            R, G, B = colorMenu.r, colorMenu.g, colorMenu.b
                            vehicleinfo = '> ' .. vehicle
                        end

                        if ButtonList(vehicleinfo, 0.577 + main.x, buttonypos - 0.0505, false, R, G, B) then
                            if SelectedVehicle ~= vehicle then
                                SelectedVehicle = vehicle
                            else
                                SelectedVehicle = false
                            end
                        end
                    end
                end
            end

            DrawTextColor("Outros", 0.580 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            if (CheckBox("No Ragdoll", false, 0.737, 0.608, noragdoll)) then
                noragdoll = not noragdoll

            end

            if (CheckBox("Freio de Avião", false, 0.737, 0.641, freiodeaviao)) then
                freiodeaviao = not freiodeaviao
                Citizen.CreateThread(function()
                    while freiodeaviao do
                        if IsControlPressed(1, 22) then
                            if IsPedInAnyVehicle(PlayerPedId(-1), true) then
                                Citizen.InvokeNative(0xAB54A438726D25D5, GetVehiclePedIsUsing(PlayerPedId(-1)), 0.0)
                            end
                        end
                        Wait(0)
                    end
                end)
            end

            if (CheckBox("Boost Buzina", false, 0.737, 0.675, boostbuzina)) then
                boostbuzina = not boostbuzina
                Citizen.CreateThread(function()
                    while boostbuzina do
                        if IsControlPressed(1, 38) then
                            if IsPedInAnyVehicle(PlayerPedId(-1), true) then
                                Citizen.InvokeNative(0xAB54A438726D25D5, GetVehiclePedIsUsing(PlayerPedId(-1)), Sliders["BoostBuzina"].Value + 0.0)
                            end
                        end
                        Wait(0)
                    end
                end)
            end

            Slider("Força Boost", Sliders["BoostBuzina"], 0.737, 0.705, 1)

            if (CheckBox("Grudar no Chão", false, 0.737, 0.734, grudarnochao)) then
                grudarnochao = not grudarnochao

            end

        elseif (main.tab == "Veiculos") then
            DrawContainer("Veiculos", nil, 4)

            DrawTextColor("Opções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            if (Button("Puxar Veículo", false, 0.459, 0.325)) then
                Citizen.CreateThread(function()
                    if SelectedVehicles then
                        local playerPed = PlayerPedId()
                        local veh = SelectedVehicles
                        local playerCoords = GetEntityCoords(playerPed)
                        local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                        local vehicleCoords = GetEntityCoords(veh)
                        SetVehicleOnGroundProperly(veh)
                        SetEntityCoordsNoOffset(playerPed, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
                        NetworkRequestControlOfEntity(veh)
                        SetEntityCollision(veh, false)
                        Citizen.Wait(500)
                        TaskWarpPedIntoVehicle(playerPed, veh, -1)
                        Citizen.Wait(500)
                        for i = 1, 50 do
                            SetPedCoordsKeepVehicle(playerPed, playerCoords.x, playerCoords.y, playerCoords.z + 0.5)
                            Wait(1)
                        end
                        SetEntityCollision(veh, true)
                        Notify("Sucesso", "keeper-sucess", string.lower(vehicleName) .. " puxado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um veículo primeiro!", 255, 255, 255)
                    end
                end)
            end

            if (Button("Deletar Veículo", false, 0.459, 0.365)) then
                Citizen.CreateThread(function()
                    if SelectedVehicles then
                        local playerPed = PlayerPedId()
                        local vehicle = SelectedVehicles
                        local vehicleModel = GetEntityModel(vehicle)
                        local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                        local driverPed = GetPedInVehicleSeat(vehicle, -1)
                        if driverPed ~= 0 then
                            Notify("Erro", "keeper-error", "Não foi possível deletar!", 255, 255, 255)
                            return
                        end
                        local playerOriginalCoords = GetEntityCoords(playerPed)
                        Citizen.Wait(0)
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local forwardVector = GetEntityForwardVector(vehicle)
                        local offset = forwardVector * -3.0
                        local playerCoords = vehicleCoords + offset
                        SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, playerCoords.z)
                        Citizen.Wait(50)
                        SetPedIntoVehicle(playerPed, vehicle, -1)
                        DeleteEntity(vehicle)
                        SelectedVehicles = false
                        Citizen.Wait(50)
                        SetEntityCoords(playerPed, playerOriginalCoords.x, playerOriginalCoords.y, playerOriginalCoords.z)
                        Notify("Sucesso", "keeper-sucess", string.lower(vehicleName) .. " deletado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um veículo primeiro!", 255, 255, 255)
                    end
                end)
            end

            DrawTextColor("Outros", 0.372 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            if (CheckBox("Trancar Veiculos", false, 0.53, 0.608, Trancarvehs)) then
                Trancarvehs = not Trancarvehs
            end

            if Trancarvehs then
                local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 25.0, 0, 70)
                if DoesEntityExist(vehicle) then
                    SetVehicleDoorsLocked(vehicle, 1)
                    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
                    SetVehicleDoorsLockedForAllPlayers(vehicle, true)
                end
            end

            if (CheckBox("Destrancar Veiculos", false, 0.53, 0.641, Destrancarvehs)) then
                Destrancarvehs = not Destrancarvehs
            end

            if Destrancarvehs then
                local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 8.0, 0, 70)
                if DoesEntityExist(vehicle) then
                    SetVehicleDoorsLocked(vehicle, 1)
                    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
                    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                end
            end

            if (Button("Teleportar no Veiculo", false, 0.459, 0.405)) then
                Citizen.CreateThread(function()
                    if SelectedVehicles then
                        local playerPed = PlayerPedId()
                        local vehicle = SelectedVehicles
                        local driverPed = GetPedInVehicleSeat(vehicle, -1)
                        if driverPed ~= 0 then
                            Notify("Erro", "keeper-error", "Não foi possível teleportar!", 255, 255, 255)
                            return
                        end
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local forwardVector = GetEntityForwardVector(vehicle)
                        local offset = forwardVector * -3.0
                        local playerCoords = vehicleCoords + offset
                        SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, playerCoords.z)
                        Citizen.Wait(5)
                        SetPedIntoVehicle(playerPed, vehicle, -1)
                        Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um veículo primeiro!", 255, 255, 255)
                    end
                end)
            end

            if (Button("Deletar Veiculo", false, 0.459, 0.445)) then
                Citizen.CreateThread(function()
                    if SelectedVehicles then
                        local veh = SelectedVehicles
                        if DoesEntityExist(veh) then
                            if veh ~= GetVehiclePedIsIn(PlayerPedId()) then
                                TriggerServerEvent("bm_module:deleteVehicles", VehToNet(veh))
                            else
                                Notify("Aviso", "keeper-warn", "Você esta dentro do veículo!", 255, 255, 255)
                            end
                        end
                    else
                        Notify("Aviso", "keeper-warn", "Selecione um veículo primeiro!", 255, 255, 255)
                    end
                end)
            end

            DrawTextColor("Lista de Veiculos", 0.580 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

            local y = 0.3 + Scroll["Vehicles_List"].static
            local add = 0.03

            if IsDisabledControlPressed(0, 14) and y > (0.360 - (#ultis.VehicleList * add)) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                Scroll["Vehicles_List"].static = Scroll["Vehicles_List"].static - add
            end

            if IsDisabledControlJustPressed(0, 15) and y < (0.3) and CursorZone(0.665 + main.x, 0.405 + main.y, 0.185, 0.126) then
                Scroll["Vehicles_List"].static = Scroll["Vehicles_List"].static + add
            end

            for i = 1, #ultis.VehicleList do
                if i > 0 then
                    local vehicles = ultis.VehicleList[i].vehicle
                    local buttonypos = ((0.05 * 1.0) + (i - 1) * 0.024) + y + main.y
                    local name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicles))

                    local R, G, B = 200, 200, 200

                    local playerInsideVehicle = false
                    for j = -1, GetVehicleMaxNumberOfPassengers(vehicles) do
                        local ped = GetPedInVehicleSeat(vehicles, j)
                        if ped and ped ~= 0 then
                            playerInsideVehicle = true
                            break
                        end
                    end
            
                    if playerInsideVehicle then
                        R, G, B = 255, 0, 0
                    end
            
                    if buttonypos >= 0.34 + main.y and buttonypos <= 0.5300 + main.y then
                        local vehiclesinfo = string.lower(name)
                        if IsEntityDead(vehicles) then
                            R, G, B = 255, 34, 0
                            vehiclesinfo = string.lower(name) .. " | car off"
                        end
                        
                        if SelectedVehicles == vehicles then
                            R, G, B = colorMenu.r, colorMenu.g, colorMenu.b
                            if IsEntityDead(vehicles) then
                                vehiclesinfo = string.lower(name) .. " | car off"
                            else
                                vehiclesinfo = '> ' .. string.lower(name)
                            end
                        end

                        if ButtonList(vehiclesinfo, 0.577 + main.x, buttonypos - 0.0505, false, R, G, B) then
                            if SelectedVehicles ~= vehicles then
                                SelectedVehicles = vehicles
                            else
                                SelectedVehicles = false
                            end
                        end
                    end
                end
            end

            DrawTextColor("Informações Veiculo", 0.580 + main.x, 0.553 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

        elseif (main.tab == "misc") then
            if (main.subtab == "Config") then
                DrawContainer("misc", nil, 1)

                DrawTextColor("Funções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (Button("Desinjetar", false, 0.459, 0.325)) then
                    main.Loop = false
                end

                if (Button("Resetar Binds", false, 0.459, 0.365)) then

                end

            elseif (main.subtab == "Exploits") then
                DrawContainer("misc", "Exploits", 1)
                DrawTextColor("Funções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                if (CheckBox("Pegar Veiculo", false, 0.53, 0.315, Pveiculo)) then
                    Pveiculo = not Pveiculo
                end
                Slider("Forçar", Sliders["Pveiculor"], 0.53, 0.360, 1, true)

                if GetResources("mirtin_craft_v2") then
                    DrawTextColor("Opções Principais", 0.372 + main.x, 0.260 + main.y, false, 0.32, 11, false, 173, 182, 187, 255)

                    if (CheckBox("Auto Farm", false, 0.53, 0.320, AutoFarm)) then
                        AutoFarm = not AutoFarm
                        if AutoFarm then
                            StartTeleportSequence()
                        end
                    end
                end
            end
        end
    end

    local Notifys = {}
    local maxNotifs = 5
    local baseTime = 4000
    local delayIncrement = 1000

    function Notify(Tipo, Type, Text, r, g, b)
        local x_res, y_res = GetActiveScreenResolution()
        local startTime = GetGameTimer()
        for _, notify in ipairs(Notifys) do
            if notify.Text == Text and notify.Type == Type and not notify.isFadingOut then
                return
            end
        end
        if #Notifys >= maxNotifs then
            Citizen.CreateThread(function()
                while #Notifys >= maxNotifs do
                    Citizen.Wait(100)
                end
            end)
        end
        local notifyOrder = #Notifys + 1
        local adjustedTime = baseTime + (notifyOrder - 1) * delayIncrement
        local offset = (notifyOrder - 1) * 0.09
        local adjustedY = 0.09 + offset
        local Notify = {
            Text = Text,
            Type = Type,
            anim = { Notify = { x = -0.1, alpha = 255 } },
            startTime = startTime,
            originalY = adjustedY,
            isFadingOut = false,
            Time = adjustedTime
        }
        table.insert(Notifys, Notify)
        Citizen.CreateThread(function()
            while true do
                local currentTime = GetGameTimer()
                if not Notify.isFadingOut then
                    Notify.anim.Notify.x = main.Lerp(Notify.anim.Notify.x, 0.120, 0.05)
                end
                if Notify.isFadingOut then
                    Notify.anim.Notify.alpha = math.max(Notify.anim.Notify.alpha - 5, 0)
                    Notify.anim.Notify.x = main.Lerp(Notify.anim.Notify.x, -0.3, 0.05)
                end

                DrawTextColor(Tipo, Notify.anim.Notify.x - 0.0750, Notify.originalY - 0.037, false, 0.36, 11, false, 250, 250, 250, Notify.anim.Notify.alpha)
                DrawTextColor(Text, Notify.anim.Notify.x - 0.0750, Notify.originalY - 0.012, false, 0.30, 11, false, 200, 200, 200, Notify.anim.Notify.alpha)
                DrawSprite("keeper-notify", "keeper-notify", Notify.anim.Notify.x, Notify.originalY, x_res / x_res, y_res / y_res - 0.140, 0, 255, 255, 255, Notify.anim.Notify.alpha)
                DrawSprite(Type, Type, Notify.anim.Notify.x - 0.085, Notify.originalY - 0.024, 18 / x_res, 18 / y_res, 0, r, g, b, Notify.anim.Notify.alpha)
                if (currentTime - Notify.startTime) > Notify.Time and not Notify.isFadingOut then
                    Notify.isFadingOut = true
                end
                if Notify.anim.Notify.alpha <= 0 then
                    for i, n in ipairs(Notifys) do
                        if n == Notify then
                            table.remove(Notifys, i)
                            break
                        end
                    end
                    for i, n in ipairs(Notifys) do
                        n.originalY = 0.07 + ((i - 1) * 0.09)
                    end
                    break
                end
                Citizen.Wait(0)
            end
        end)
    end

    if loaded then
        Wait(200)
        Notify("Sucesso", "keeper-sucess", "Menu iniciado com sucesso!", 255, 255, 255)
        Citizen.CreateThread(function()
            if GetResources("mirtin_craft_v2") then
                Citizen.Wait(1500)
                Notify("Sucesso", "keeper-sucess", "Exploit carregado com sucesso!", 255, 255, 255)
            else
                Citizen.Wait(1500)
                Notify("Aviso", "keeper-warn", "Não foi encontrado nenhum exploit!", 255, 255, 255)
            end
        end)
    end

    function DrawText3D(x, y, z, text)
        local onScreen, _x, _y = World3dToScreen2d(x, y, z)
        local scale = (1 / GetDistanceBetweenCoords(GetGameplayCamCoords(), x, y, z, 1)) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov

        if onScreen then
            SetTextScale(0.0 * scale, 0.35 * scale)
            SetTextFont(0)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 215)
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(_x, _y)
        end
    end

    function Animations()
        main.anim.tab.y = main.Lerp(main.anim.tab.y, main.anim.tab.y_d, 0.060)
        main.anim.subTab.y = main.Lerp(main.anim.subTab.y, main.anim.subTab.y_d, 0.050)
    end

    function RGBRainbow(frequency)
        local result = {}
        local curtime = GetGameTimer() / 1000

        result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
        result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
        result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)

        return result
    end

    function EnumerarEntidades(initFunc, moveFunc, disposeFunc)
        return coroutine.wrap(function()
            local iter, id = initFunc()
            if not id or id == 0 then
                disposeFunc(iter)
                return
            end

            local enum = {handle = iter, destructor = disposeFunc}
            setmetatable(enum, entityEnumerator)

            local next = true
            repeat
                coroutine.yield(id)
                next, id = moveFunc(iter)
            until not next

            enum.destructor, enum.handle = nil, nil
            disposeFunc(iter)
        end)
    end

    function EnumerarPeds()
        return EnumerarEntidades(FindFirstPed, FindNextPed, EndFindPed)
    end

    local milicia = {
        -- ["SUL"] = {
        --     { ['x'] = -364.05737304688, ['y'] = -1873.8819580078, ['z'] = 20.527826309204 },
        --     { ['x'] = -60.263641357422, ['y'] = -1749.1865234375, ['z'] = 29.323892593384 },
        --     { ['x'] = 234.18333435059,  ['y'] = -1946.4475097656, ['z'] = 22.963087081909 },
        --     { ['x'] = 446.73193359375,  ['y'] = -2047.1622314453, ['z'] = 23.751689910889 },
        --     { ['x'] = 829.826171875,    ['y'] = -1916.6561279297, ['z'] = 29.390361785889 },
        --     { ['x'] = 862.62506103516,  ['y'] = -1585.1462402344, ['z'] = 31.396532058716 },
        --     { ['x'] = 765.3857421875,   ['y'] = -1225.1103515625, ['z'] = 25.213331222534 },
        --     { ['x'] = 806.7392578125,   ['y'] = -810.32678222656, ['z'] = 26.203187942505 },
        --     { ['x'] = 755.71057128906,  ['y'] = -557.93249511719, ['z'] = 33.64270401001 },
        --     { ['x'] = 461.23333740234,  ['y'] = -276.70663452148, ['z'] = 48.717029571533 },
        --     { ['x'] = 109.19496154785,  ['y'] = -153.14697265625, ['z'] = 54.763656616211 },
        --     { ['x'] = -307.94500732422, ['y'] = -164.65635681152, ['z'] = 40.422550201416 },
        --     { ['x'] = -197.68168640137, ['y'] = -571.59112548828, ['z'] = 34.630405426025 },
        --     { ['x'] = -290.61306762695, ['y'] = -819.01483154297, ['z'] = 32.44261932373 },
        --     { ['x'] = -332.97515869141, ['y'] = -1067.0220947266, ['z'] = 23.025810241699 },
        --     { ['x'] = -471.6774597168,  ['y'] = -865.74932861328, ['z'] = 23.964038848877 },
        --     { ['x'] = -702.68548583984, ['y'] = -917.03680419922, ['z'] = 19.212812423706 },
        --     { ['x'] = -819.71124267578, ['y'] = -1104.4938964844, ['z'] = 11.163955688477 },
        --     { ['x'] = -644.77044677734, ['y'] = -1662.3376464844, ['z'] = 25.376707077026 },
        -- },
        ["NORTE"] = {
            { ['x'] = -142.41192626953, ['y'] = -1994.3231201172, ['z'] = 22.825813293457 },
            { ['x'] = 853.69372558594,  ['y'] = -2097.4995117188, ['z'] = 30.290037155151 },
            { ['x'] = 1255.6645507812,  ['y'] = -1964.4588623047, ['z'] = 43.263854980469 },
            { ['x'] = 1566.8142089844,  ['y'] = -1007.4136962891, ['z'] = 58.991374969482 },
            { ['x'] = 2139.6608886719,  ['y'] = -591.29431152344, ['z'] = 95.384994506836 },
            { ['x'] = 2551.2443847656,  ['y'] = 348.45736694336,  ['z'] = 108.62020111084 },
            { ['x'] = 2462.4523925781,  ['y'] = 986.31451416016,  ['z'] = 85.808143615723 },
            { ['x'] = 1926.4548339844,  ['y'] = 1794.0939941406,  ['z'] = 64.213157653809 },
            { ['x'] = 2039.9748535156,  ['y'] = 2561.1198730469,  ['z'] = 54.722469329834 },
            { ['x'] = 2483.5903320312,  ['y'] = 2843.0375976562,  ['z'] = 46.997547149658 },
            { ['x'] = 2011.8889160156,  ['y'] = 2628.1384277344,  ['z'] = 53.481452941895 },
            { ['x'] = 1641.7147216797,  ['y'] = 1323.5079345703,  ['z'] = 88.275726318359 },
            { ['x'] = 1307.568359375,   ['y'] = 624.25042724609,  ['z'] = 80.146614074707 },
            { ['x'] = 911.40899658203,  ['y'] = 225.21726989746,  ['z'] = 78.262161254883 },
            { ['x'] = 1036.9840087891,  ['y'] = -1111.4267578125, ['z'] = 25.740266799927 },
            { ['x'] = 1155.6264648438,  ['y'] = -2066.4265136719, ['z'] = 42.131156921387 },
            { ['x'] = 396.06832885742,  ['y'] = -1935.2209472656, ['z'] = 24.573490142822 },
            { ['x'] = -41.001857757568, ['y'] = -1675.5518798828, ['z'] = 29.433610916138 },
            { ['x'] = -644.86242675781, ['y'] = -1662.1719970703, ['z'] = 25.384187698364 },
        }
    }

    function TeleportToCoords(coords)
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    end

    function CollectAfterTeleport()
        Citizen.Wait(12000)
        SetControlNormal(0, 38, 1.0)
        --SetControlNormal(0, 23, 1.0)
        --Notify("Sucesso", "keeper-sucess", "Blip coletado com sucesso!", 255, 255, 255)
    end

    function StartTeleportSequence()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                if AutoFarm then
                    for region, coordsList in pairs(milicia) do
                        for _, coords in ipairs(coordsList) do
                            TeleportToCoords(coords)
                            CollectAfterTeleport()
                            Citizen.Wait(2000)
                            if not AutoFarm then
                                break
                            end
                        end
                    end
                end
            end
        end)
    end

    function RegisterEntityForNetWork(entity)
        NetworkSetThisScriptIsNetworkScript(32, true, 0)
        local timeout = 2000
        while timeout > 0 and not NetworkHasControlOfEntity(entity) do
            NetworkRegisterEntityAsNetworked(entity)
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
            NetworkRequestControlOfEntity(entity);NetworkHasControlOfEntity(entity)
            Wait(0)
            timeout = timeout - 1
        end
    end
    
    function GetResources(R_Name)
        local Inf_Res = GetResourceState(R_Name or string.lower(R_Name))
        if Inf_Res == "started" then
            return true
        else
            return false
        end
    end

    function TPWaypoint(Blips, Color)
        Citizen.CreateThread(function()
            local BlipId = GetFirstBlipInfoId(Blips or 8)
            local distancia = #(GetEntityCoords(PlayerPedId()) - GetBlipInfoIdCoord(BlipId))
            if DoesBlipExist(BlipId) then
                if distancia >= 2.0 then
                    local BlipColor = GetBlipColour(BlipId)
                    if BlipColor == Color or Color == nil then
                        local Player = PlayerPedId()
                        local Vehicle = GetVehiclePedIsUsing(Player)
                        Player = IsPedInAnyVehicle(Player) and Vehicle or Player
                        local PedCoords = GetEntityCoords(Player)
                        local x, y, z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, BlipId, Citizen.ResultAsVector()))

                        DeleteWaypoint()
                        Citizen.Wait(500)
                        SetEntityCoordsNoOffset(Player, x, y, z)
                        Citizen.Wait(12)
                        SetEntityCoordsNoOffset(Player, PedCoords.x, PedCoords.y, PedCoords.z, 0, 0, 1)
                        Citizen.Wait(500)

                        local ground
                        for Height = 0, 1100.0, 50.0 do
                            SetEntityCoordsNoOffset(Player, x, y, Height or -Height, 0, 0, 1)
                            RequestCollisionAtCoord(x, y, z)
                            Citizen.Wait(20)
                            ground, z = GetGroundZFor_3dCoord(x, y, Height or -Height)
                            if ground then
                                z = z + 1.0
                                break;
                            end
                        end
                        Notify("Sucesso", "keeper-sucess", "Teleportado com sucesso!", 255, 255, 255)
                        SetEntityCoordsNoOffset(Player, x, y, z, 0, 0, 1)
                    end
                end
            else
                Notify("Aviso", "keeper-warn", "Marque um local no mapa!", 255, 255, 255)
            end
        end)
    end

    function CreatePedFly()
        Citizen.CreateThread(function()
            if Noclip and not IsPedInAnyVehicle(PlayerPedId()) then
                local pedModel = "mp_m_freemode_01"
                RequestModel(GetHashKey(pedModel))
                RequestModel(pedModel)
                while not HasModelLoaded(GetHashKey(pedModel)) do
                    RequestModel(pedModel)
                    Wait(1)
                end
                local coords = GetEntityCoords(PlayerPedId())
                ultis.NoclipPed = CreatePed(4, GetHashKey(pedModel), coords, GetEntityHeading(PlayerPedId()), false, false)
                SetEntityCoordsNoOffset(ultis.NoclipPed, coords)
                SetEntityCollision(ultis.NoclipPed, false, true)
                SetEntityVisible(ultis.NoclipPed, false)
                SetBlockingOfNonTemporaryEvents(ultis.NoclipPed, true)
                ClearPedTasksImmediately(ultis.NoclipPed)
                SetEntityCanBeDamaged(ultis.NoclipPed, false)
                AttachEntityToEntity(PlayerPedId(), ultis.NoclipPed, 11816, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            elseif ultis.NoclipPed ~= nil then
                DetachEntity(PlayerPedId(), true ,true)
                DetachEntity(ultis.NoclipPed, true ,true)
                DeleteEntity(ultis.NoclipPed)
                DeletePed(ultis.NoclipPed)
                ultis.NoclipPed = nil
            end
        end)
    end

    function UpdateNoclip()
        if Noclip then
            local key = { 32, 33, 30, 34, 22, 36, 129, 130, 133, 134, 75, 69 }

            for _, index in pairs(key) do
                DisableControlAction(0, index, true)
            end

            local speed = 0.1 * Sliders["Noclip"].Value
            local entity = ultis.NoclipPed or GetVehiclePedIsIn(PlayerPedId(), false)

            local vehicle = GetVehiclePedIsIn(entity, false)
            if (vehicle and GetPedInVehicleSeat(vehicle, -1) == entity) then
                entity = vehicle
                SetEntityRotation(entity, GetFinalRenderedCamRot(2), 2)
            else
                SetEntityHeading(entity, GetGameplayCamRelativeHeading() + GetEntityHeading(entity))
            end
            local coords = GetEntityCoords(entity)
            local forward, right = rotateToQuat(GetFinalRenderedCamRot(0)) * vector3(0.0, 1.0, 0.0), rotateToQuat(GetFinalRenderedCamRot(0)) * vector3(1.0, 0.0, 0.0)
            if (IsDisabledControlPressed(0, 21)) then
                speed = speed * 3
            end
            if (IsDisabledControlPressed(0, 32)) then
                coords = coords + forward * speed
            end
            if (IsDisabledControlPressed(0, 33)) then
                coords = coords + forward * -speed
            end
            if (IsDisabledControlPressed(0, 30)) then
                coords = coords + right * speed
            end
            if (IsDisabledControlPressed(0, 34)) then
                coords = coords + right * -speed
            end
            if (IsDisabledControlPressed(0, 22)) then
                coords = vector3(coords.x, coords.y, coords.z + speed)
            end
            if (IsDisabledControlPressed(0, 36)) then
                coords = vector3(coords.x, coords.y, coords.z - speed)
            end
            
            SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, true)
            SetEntityCollision(entity, false, false)
            FreezeEntityPosition(entity, false)
        else
            SetEntityCollision(PlayerPedId(), true, true)
            SetEntityCollision(IsPedInAnyVehicle(PlayerPedId(), false) and GetVehiclePedIsIn(PlayerPedId(), true), true, true)
        end
    end

    function rotateToQuat(rotate)
        local pitch, roll, yaw = math.rad(rotate.x), math.rad(rotate.y), math.rad(rotate.z)
        local cy, sy, cr, sr, cp, sp = math.cos(yaw * 0.5), math.sin(yaw * 0.5), math.cos(roll * 0.5), math.sin(roll * 0.5), math.cos(pitch * 0.5), math.sin(pitch * 0.5)
        return quat(cy * cr * cp + sy * sr * sp, cy * sp * cr - sy * cp * sr, cy * cp * sr + sy * sp * cr, sy * cr * cp - cy * sr * sp)
    end

    local function RotationToDirection(rotation)
        local retz = math.rad(rotation.z)
        local retx = math.rad(rotation.x)
        local absx = math.abs(math.cos(retx))
        return vector3(-math.sin(retz) * absx, math.cos(retz) * absx, math.sin(retx))
    end
    
    function blockInputs()
        local keys = { 1, 2, 142, 322, 106, 32, 31, 30, 34, 23, 22, 16, 17 }
        for _, key in ipairs(keys) do
            DisableControlAction(0, key, true)
        end
    end

    local function drawTextOutline(text, x, y, scale, font, outline, center, r, g, b)
        SetTextScale(0.0, scale)
        SetTextFont(10)
        if outline then
            SetTextOutline(outline)
        else
        end
        SetTextCentre(center)
        SetTextColour(colorMenu.r, colorMenu.g, colorMenu.b, 255)
        SetTextFont(10)
        BeginTextCommandDisplayText('TWOSTRINGS')
        AddTextComponentString(text)
        EndTextCommandDisplayText(x, y - 0.011)
    end

    local function getWidth(str, font, scale)
        BeginTextCommandWidth("STRING")
        AddTextComponentString(str)
        SetTextFont(4)
        SetTextScale(scale or 0.35, scale or 0.35)
        local length = EndTextCommandGetWidth(1)
        return length
    end

    local Free_Cam = nil
    function StartFreeCam(bool)
        if Free_Cam == nil then
            Free_Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
            local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
            SetCamActive(Free_Cam, true)
            SetCamCoord(Free_Cam, px+2.0, py- 3.0, pz+3.0)
            RenderScriptCams(true, false, 0, true, true)
        elseif Free_Cam ~= nil then
            DestroyCam(Free_Cam, false)
            ClearTimecycleModifier()
            RenderScriptCams(false, false, 0, true, false)
            SetFocusEntity(PlayerPedId())
            Free_Cam = nil
        end
    end

    local offsetRotX = 0.0
    local offsetRotY = 0.0
    local offsetRotZ = 0.0

    function UpdateFreeCam()
        if Free_Cam and DoesCamExist(Free_Cam) then
            blockInputs()

            local screenX, screenY = 0.5, 0.5
            DrawRect(0.5, 0.5, 0.01, 0.0015, 255, 255, 255, 200)
            DrawRect(0.5, 0.5, 0.0015, 0.015, 255, 255, 255, 200)
            local currentmode = ultis.freecam.modes[ultis.freecam.mode]
            offsetRotX = offsetRotX - (GetDisabledControlNormal(1, 2) * 8.0)
            offsetRotZ = offsetRotZ - (GetDisabledControlNormal(1, 1) * 8.0)

            if (offsetRotX > 90.0) then
                offsetRotX = 90.0
            elseif (offsetRotX < -90.0) then
                offsetRotX = -90.0
            end

            if (offsetRotY > 90.0) then
                offsetRotY = 90.0
            elseif (offsetRotY < -90.0) then
                offsetRotY = -90.0
            end


            if (offsetRotZ > 360.0) then
                offsetRotZ = offsetRotZ - 360.0
            elseif (offsetRotZ < -360.0) then
                offsetRotZ = offsetRotZ + 360.0
            end

            local Speed = 0.5
            local coords = GetCamCoord(Free_Cam)
            local forward, right = rotateToQuat(GetFinalRenderedCamRot(0)) * vector3(0.0, 1.0, 0.0), rotateToQuat(GetFinalRenderedCamRot(0)) * vector3(1.0, 0.0, 0.0)
            if IsDisabledControlPressed(0, 21) then Speed = Speed * 2 end
            if IsDisabledControlPressed(0, 32) then coords = coords + forward * Speed end
            if IsDisabledControlPressed(0, 33) then coords = coords + forward * -Speed end
            if IsDisabledControlPressed(0, 30) then coords = coords + right * Speed end
            if IsDisabledControlPressed(0, 34) then coords = coords + right * -Speed end
            if IsDisabledControlPressed(0, 22) then coords = vector3(coords.x, coords.y, coords.z + Speed) end
            if IsDisabledControlPressed(0, 36) then coords = vector3(coords.x, coords.y, coords.z - Speed) end
            
            local distance = 5000.0

            local adjustedRotation = { x = (math.pi / 180) * GetCamRot(Free_Cam, 0).x, y = (math.pi / 180) * GetCamRot(Free_Cam, 0).y, z = (math.pi / 180) * GetCamRot(Free_Cam, 0).z }
            local direction = { x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), z = math.sin(adjustedRotation.x)  }
            local destination = { x = coords.x + direction.x * distance, y = coords.y + direction.y * distance, z = coords.z + direction.z * distance }
            local a, b, coords2, d, entity = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, -1, -1, 1))
            if coords2 ~= vector3(0, 0, 0) and not main.menuOpen then
                if IsDisabledControlJustPressed(0, 69) then
                    if ultis.freecam.funcs[currentmode.func] then
                        ultis.freecam.funcs[currentmode.func](coords2, entity)
                    end
                end
            end

            drawTextOutline("~w~[~s~Keeper Menu~w~] ~n~~s~Freecam Mode: ~w~" .. currentmode.name, 0.5, 0.95, 0.27, 4, true, true, 255, 255, 255)
            if IsDisabledControlJustPressed(1, 14) then
                ultis.freecam.mode = ultis.freecam.mode + 1
                if ultis.freecam.mode > #ultis.freecam.modes then
                    ultis.freecam.mode = 1
                end
            elseif IsDisabledControlJustPressed(1, 15) then
                ultis.freecam.mode = ultis.freecam.mode - 1
                if ultis.freecam.mode < 1 then
                    ultis.freecam.mode = #ultis.freecam.modes
                end
            end
            SetCamCoord(Free_Cam, coords)
            DisablePlayerFiring(PlayerId(), true)
            SetFocusArea(GetCamCoord(Free_Cam), 0.0, 0.0, 0.0)
            SetCamRot(Free_Cam, offsetRotX, offsetRotY, offsetRotZ, 2)
        end
    end

    function ReleaseTab()
        if tabarmas and not main.menuOpen then
            SetPedEnableWeaponBlocking(PlayerPedId(), true)
            EnableAllControlActions(0)
            NetworkSetFriendlyFireOption(true)
            SetCanAttackFriendly(PlayerPedId(), true, true)
        end
    end

    local Current_Time = GetGameTimer()
    local Current_Times = GetGameTimer()
    function UpdateLists()
        if (GetGameTimer() - Current_Time) >= 900 then
            Citizen.CreateThread(function()
                ultis.PlayersList = {}
                for _, Player in ipairs(GetActivePlayers()) do
                    local Coords = GetEntityCoords(PlayerPedId())
                    local distance = GetDistanceBetweenCoords(Coords, GetEntityCoords(GetPlayerPed(Player)), true)
                    if distance <= 1000 then
                        table.insert(ultis.PlayersList, { player = Player, distance = distance })
                    end
                end

                table.sort(ultis.PlayersList, function(a, b)
                    return a.distance < b.distance
                end)
            end)
            Current_Time = GetGameTimer()
        end

        if (GetGameTimer() - Current_Times) >= 1000 then
            Citizen.CreateThread(function()
                ultis.VehicleList = {}
                for _, vehicle in pairs(GetGamePool("CVehicle")) do
                    if GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) ~= "FREIGHT" or "CARNOTFOUND" then
                        local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(vehicle), true)
                        if distance <= 1000 then
                            table.insert(ultis.VehicleList, { vehicle = vehicle, distance = distance })
                        end
                    end
                end

                table.sort(ultis.VehicleList, function(a, b)
                    return a.distance < b.distance
                end)
                Current_Times = GetGameTimer()
            end)
        end
    end
 
    function FunctionsLoop()
        if SSoco then
            local camPos = GetGameplayCamCoord()
            local direction = RotationToDirection(GetGameplayCamRot(2))
            local dest = vec3(camPos.x + direction.x * 5.0, camPos.y + direction.y * 10.0, camPos.z + direction.z * 10.0)
            local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
            local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
            
            if hit == 1 then
                EnType = GetEntityType(entityHit)
                if EnType == 2 then
                    if IsControlJustReleased(0, 24) then
                        local forceMultiplier = Sliders["Pveiculor"].Value
                        RegisterEntityForNetWork(entityHit)
                        ApplyForceToEntity(entityHit, 1, direction.x * (forceMultiplier), direction.y * (forceMultiplier), direction.z * (forceMultiplier), 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    end
                end
            end
        end

        if Pveiculo and not carregarvehsload then
            carregarvehsload = true
            local hEntity, hCarEntity = false, false
            local hlEntity, EnType = nil, nil

            Citizen.CreateThread(function()
                while Pveiculo do
                    Citizen.Wait(0)
                    if hEntity and hlEntity then
                        local headPos = GetPedBoneCoords(PlayerPedId(), 0x796e, 0.0, 0.0, 0.0)
                        DrawText3D(headPos.x, headPos.y, headPos.z + 0.5, "Para jogar o veiculo Aperte [Y]")
                        if hCarEntity and not IsEntityPlayingAnim(PlayerPedId(), 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 3) then
                            RequestAnimDict('anim@mp_rollarcoaster')
                            while not HasAnimDictLoaded('anim@mp_rollarcoaster') do
                                Citizen.Wait(100)
                            end
                            TaskPlayAnim(PlayerPedId(), 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
                        elseif not IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) and not hCarEntity then
                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Citizen.Wait(100)
                            end
                            TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
                        end
    
                        if not IsEntityAttached(hlEntity) then
                            hEntity, hCarEntity = false, false
                            ClearPedTasks(PlayerPedId())
                            hlEntity = nil
                        end
                    end
                end
            end)
    
            Citizen.CreateThread(function()
                while Pveiculo do
                    Citizen.Wait(0)
                    local camPos = GetGameplayCamCoord()
                    local direction = RotationToDirection(GetGameplayCamRot(2))
                    local dest = vec3(camPos.x + direction.x * 10.0, camPos.y + direction.y * 10.0, camPos.z + direction.z * 10.0)
                    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
                    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
                    local validTarget = false
    
                    if hit == 1 then
                        EnType = GetEntityType(entityHit)
                        if EnType == 2 and not hCarEntity then
                            validTarget = true
                            local headPos = GetPedBoneCoords(PlayerPedId(), 0x796e, 0.0, 0.0, 0.0)
                            DrawText3D(headPos.x, headPos.y, headPos.z + 0.5, "Apete [Y] Pra pegar o Carro")
                        end
                    end
    
                    if IsControlJustReleased(0, 246) then
                        if validTarget then
                            if not hEntity and entityHit and EnType == 2 then
                                hEntity, hCarEntity = true, true
                                hlEntity = entityHit
                                main["plate"] = GetVehicleNumberPlateText(hlEntity)
                                RequestAnimDict('anim@mp_rollarcoaster')
                                while not HasAnimDictLoaded('anim@mp_rollarcoaster') do
                                    Citizen.Wait(100)
                                end
                                
                                if not IsEntityPlayingAnim(PlayerPedId(), "anim@mp_rollarcoaster", "hands_up_idle_a_player_one", 3) then
                                    TaskPlayAnim(PlayerPedId(), 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
                                end
                                RegisterEntityForNetWork(hlEntity)
                                AttachEntityToEntity(hlEntity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                            end
                        else
                            local forceMultiplier = Sliders["Pveiculor"].Value
                            if hEntity and hCarEntity then
                                hEntity, hCarEntity = false, false
                                ClearPedTasks(PlayerPedId())
                                DetachEntity(hlEntity, true, true)
                                ApplyForceToEntity(hlEntity, 1, direction.x * (forceMultiplier), direction.y * (forceMultiplier), direction.z * (forceMultiplier), 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                            elseif hEntity then
                                hEntity = false
                                ClearPedTasks(PlayerPedId())
                                DetachEntity(hlEntity, true, true)
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                SetEntityCoords(hlEntity, playerCoords.x, playerCoords.y, playerCoords.z - 1, false, false, false, false)
                                SetEntityHeading(hlEntity, GetEntityHeading(PlayerPedId()))
                            end
                        end
                    end
                end
            end)
        elseif not Pveiculo then
            local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 4.0, 0, 70)
            if DoesEntityExist(vehicle) and main["plate"] == GetVehicleNumberPlateText(vehicle) then
                ClearPedTasks(PlayerPedId())
                DetachEntity(vehicle, true, true)
                local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
                SetEntityCoords(PlayerPedId(),  x, y-2, z)
                main["plate"] = nil
            end
            carregarvehsload = false
        end
    end

    ultis.freecam.funcs["exp"] = function(coords)
        AddExplosion(coords.x, coords.y, coords.z, 70, 100.0, true, false, 0.0)
    end

    ultis.freecam.funcs["remVehicle"] = function(_C, entity)
        if DoesEntityExist(entity) then
            Citizen.CreateThread(function()
                local ped = PlayerPedId()
                print("dishjkdhjsd")
                local driver = GetPedInVehicleSeat(entity, -1)
                if driver ~= ped then
                    print(driver)
                    local playerselped = GetPlayerPed(driver)
                    if playerselped == PlayerPedId() then
                        return
                    end

                    local vehicle = GetVehiclePedIsIn(playerselped, false)
                    if not vehicle or vehicle == 0 then
                        return
                    end
                    SetVehicleExclusiveDriver(vehicle, playerselped, 1)
                end
            end)
      end
    end

    

    ultis.freecam.funcs["mtJg"] = function(_C, entity)
        if DoesEntityExist(entity) and IsEntityAPed(entity) then
            local playerPed = PlayerPedId()
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                if targetPed ~= GetPlayerPed(entity) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(targetCoords - _C)
                    if distance < 1000.0 then
                        playerPed = targetPed
                    end
                end
            end

            ShootSingleBulletBetweenCoords(_C.x, _C.y, _C.z - 1, _C.x, _C.y, _C.z, 200, true, GetHashKey("VEHICLE_WEAPON_GRANGER2_MG"), playerPed, true, false, -1.0, true)
        end
    end

    function RunFunctionsLoop()
        UpdateFreeCam()
        UpdateNoclip()
        ReleaseTab()
    end

    function LoadLoop()
        DrawMenu()
        UpdateLists()
        Tab_select()
        DrawCursor()
        Animations()
        disableActions()
    end

    CreateThread(function()
        while main.Loop do
            Wait(0)
            if IsControlJustPressed(0, 121) then
                main.menuOpen = not main.menuOpen
                main.anim.subTab.y = 0.0
            elseif main.menuOpen then
                handleDrag()
                LoadLoop()
            end
            if Noclip or tabarmas or Free_Cam then
                RunFunctionsLoop()
            end
            FunctionsLoop()
        end
    end)
end)
