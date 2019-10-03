local Radio = {
    Has = false,
    Open = false,
    On = false,
    Handle = nil,
    Prop = `prop_cs_hand_radio`,
    Bone = 28422,
    Offset = vector3(0.0, 0.0, 0.0),
    Rotation = vector3(0.0, 0.0, 0.0),
    Dictionary = {
        "cellphone@",
        "cellphone@in_car@ds",
        "cellphone@str",    
        "random@arrests",  
    },
    Animation = {
        "cellphone_text_in",
        "cellphone_text_out",
        "cellphone_call_listen_a",
        "generic_radio_chatter",
    },
    Controls = {
        Activator = 289,
        Secondary = 21,
        Toggle = 51,
        Increase = {
            Key = 175,
            Pressed = false,
        },
        Decrease = {
            Key = 174,
            Pressed = false,
        },
        Input = {
            Key = 201,
            Pressed = false,
        },
        Broadcast = 137,
    },
    Labels = {        
        { "FRZL_RADIO_HELP", "~s~Press ~INPUT_SPRINT~ + ~INPUT_REPLAY_START_STOP_RECORDING_SECONDARY~ to hide.~n~Press ~INPUT_CONTEXT~ to turn radio ~g~on~s~.~n~Frequency ← ~1~ MHz →~n~Press ~INPUT_FRONTEND_ACCEPT~ to choose frequency" },
        { "FRZL_RADIO_HELP2", "~s~Press ~INPUT_SPRINT~ + ~INPUT_REPLAY_START_STOP_RECORDING_SECONDARY~ to hide.~n~Press ~INPUT_CONTEXT~ to turn radio ~r~off~s~.~n~Press ~INPUT_VEH_PUSHBIKE_SPRINT~ to broadcast." },
        { "FRZL_RADIO_INPUT", "Enter Frequency"},
    },
    Frequency = {
        Current = 5,
        Min = 0,
        Max = 800,
    }
}
local isPrisoner = false
local isCuffed = false
local isEmergency = false

-- Create/Destroy handheld radio object
function Radio:Toggle(toggle)
    local playerPed = PlayerPedId()
    local count = 0

    if not self.Has or IsEntityDead(playerPed) then
        self.Open = false

        NetworkRequestControlOfEntity(self.Handle)

		while not NetworkHasControlOfEntity(self.Handle) and count < 5000 do
            Citizen.Wait(0)
            count = count + 1
        end
        
        DetachEntity(self.Handle, true, false)
        DeleteEntity(self.Handle)
        
        return
    end

    if self.Open == toggle then
        return
    end

    self.Open = toggle

    local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
    local animationType = 1 + (self.Open and 0 or 1)
    local dictionary = self.Dictionary[dictionaryType]
    local animation = self.Animation[animationType]

    RequestAnimDict(dictionary)

    while not HasAnimDictLoaded(dictionary) do
        Citizen.Wait(150)
    end

    if self.Open then
        RequestModel(self.Prop)

        while not HasModelLoaded(self.Prop) do
            Citizen.Wait(150)
        end

        self.Handle = CreateObject(self.Prop, 0.0, 0.0, 0.0, true, true, false)

        local bone = GetPedBoneIndex(playerPed, self.Bone)

        SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
        AttachEntityToEntity(self.Handle, playerPed, bone, self.Offset.x, self.Offset.y, self.Offset.z, self.Rotation.x, self.Rotation.y, self.Rotation.z, true, false, false, false, 2, true)

        SetModelAsNoLongerNeeded(self.Handle)

        TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)
    else
        TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)

        Citizen.Wait(700)

        StopAnimTask(playerPed, dictionary, animation, 1.0)

        NetworkRequestControlOfEntity(self.Handle)

		while not NetworkHasControlOfEntity(self.Handle) and count < 5000 do
            Citizen.Wait(0)
            count = count + 1
        end
        
        DetachEntity(self.Handle, true, false)
        DeleteEntity(self.Handle)
    end
end

-- Add player to radio channel
function Radio:Add(id)
    exports["tokovoip_script"]:addPlayerToRadio(id)
end

-- Remove player from radio channel
function Radio:Remove(id)
    exports["tokovoip_script"]:removePlayerFromRadio(id)
end

-- Increase radio frequency
function Radio:Decrease(min)
    if self.On then
        if self.Frequency.Current - 1 < min then
            self:Remove(self.Frequency.Current)
            self.Frequency.Current = self.Frequency.Max
            self:Add(self.Frequency.Current)        
        else
            self:Remove(self.Frequency.Current)
            self.Frequency.Current = self.Frequency.Current - 1
            self:Add(self.Frequency.Current)
        end
    else
        if self.Frequency.Current - 1 < min then
            self.Frequency.Current = self.Frequency.Max
        else
            self.Frequency.Current = self.Frequency.Current - 1
        end
    end
end

-- Decrease radio frequency
function Radio:Increase(min)
    if self.On then
        if self.Frequency.Current + 1 > self.Frequency.Max then
            self:Remove(self.Frequency.Current)
            self.Frequency.Current = min
            self:Add(min)
        else
            self:Remove(self.Frequency.Current)
            self.Frequency.Current = self.Frequency.Current + 1
            self:Add(self.Frequency.Current)
        end
    else
        if self.Frequency.Current + 1 > self.Frequency.Max then
            self.Frequency.Current = min
        else
            self.Frequency.Current = self.Frequency.Current + 1
        end
    end
end

-- Check if radio is open
function IsRadioOpen()
    return Radio.Open
end

function IsRadioOn()
    return Radio.On
end

function IsRadioAvailable()
    return Radio.Has
end

function CanRadioBeUsed()
    return Radio.Has and Radio.On
end

exports("IsRadioOpen", IsRadioOpen)
exports("IsRadioOn", IsRadioOn)
exports("IsRadioAvailable", IsRadioAvailable)
exports("CanRadioBeUsed", CanRadioBeUsed)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)        
        isPrisoner = exports["core_modules"]:IsInJail()
        isCuffed = exports["policejob"]:getIsCuffed() or exports["core_modules"]:isCuffed()
        isEmergency = exports["policejob"]:getIsInService() or exports["emsjob"]:getIsInService()
    end
end)

Citizen.CreateThread(function()
    -- Add Labels
    for i = 1, #Radio.Labels do
        AddTextEntry(Radio.Labels[i][1], Radio.Labels[i][2])
    end

    while true do
        Citizen.Wait(0)
        -- Init local vars
        local playerPed = PlayerPedId()
        local isActivatorPressed = IsControlJustPressed(0, Radio.Controls.Activator)
        local isSecondaryPressed = IsControlPressed(0, 21)
        local isKeyboard = IsInputDisabled(2)
        local isFalling = IsPedFalling(playerPed)
        local isDead = IsEntityDead(playerPed)
        local minFrequency = Radio.Frequency.Min + (isEmergency and 1 or 5)
        local broadcastType = 3 + (isEmergency and 1 or 0) + ((Radio.Open and isEmergency) and -1 or 0) 
        local broadcastDictionary = Radio.Dictionary[broadcastType]
        local broadcastAnimation = Radio.Animation[broadcastType]
        local isBroadcasting = IsControlPressed(0, Radio.Controls.Broadcast)
        local isPlayingBroadcastAnim = IsEntityPlayingAnim(playerPed, broadcastDictionary, broadcastAnimation, 3)

        -- Open radio settings
        if isActivatorPressed and isSecondaryPressed and isKeyboard and not isFalling and not isPrisoner and not isCuffed and Radio.Has and not isDead then
            Radio:Toggle(not Radio.Open)
        elseif (Radio.Open or Radio.On) and (isPrisoner or isCuffed or (not Radio.Has) or isDead) then
            Radio:Toggle(false)
            Radio.On = false
            Radio:Remove(Radio.Frequency.Current)
        elseif Radio.Open and isFalling then
            Radio:Toggle(false)
        end

        -- Remove player from emergency services comms if not part of the emergency services
        if not isEmergency and Radio.Frequency.Current < 5 and Radio.On then
            Radio:Remove(Radio.Frequency.Current)
            Radio.Frequency.Current = 5
            Radio:Add(Radio.Frequency.Current)
        elseif not isEmergency and Radio.Frequency.Current < 5 and not Radio.On then
            Radio.Frequency.Current = 5
        end

        -- Check if player is holding radio
        if Radio.Open then
            local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
            local openDictionary = Radio.Dictionary[dictionaryType]
            local openAnimation = Radio.Animation[1]
            local isPlayingOpenAnim = IsEntityPlayingAnim(playerPed, openDictionary, openAnimation, 3)
            local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, 1)

            -- Remove weapon in hand as we are using the radio
            if currentWeapon ~= `weapon_unarmed` then
                SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
            end

            -- Display help text
            if Radio.On then
                BeginTextCommandDisplayHelp(Radio.Labels[2][1])
                EndTextCommandDisplayHelp(false, false, false, -1)
            else
                BeginTextCommandDisplayHelp(Radio.Labels[1][1])
                AddTextComponentInteger(Radio.Frequency.Current)
                EndTextCommandDisplayHelp(false, false, false, -1)
            end

            -- Play animation if player is broadcasting to radio
            if Radio.On then
                if isBroadcasting and not isPlayingBroadcastAnim then
                    RequestAnimDict(broadcastDictionary)
        
                    while not HasAnimDictLoaded(broadcastDictionary) do
                        Citizen.Wait(150)
                    end
        
                    TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, -8, -1, 49, 0, 0, 0, 0)
                elseif not isBroadcasting and isPlayingBroadcastAnim then
                    StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
                end
            end

            -- Play default animation if not broadcasting
            if not isBroadcasting and not isPlayingOpenAnim then
                RequestAnimDict(openDictionary)
    
                while not HasAnimDictLoaded(openDictionary) do
                    Citizen.Wait(150)
                end

                TaskPlayAnim(playerPed, openDictionary, openAnimation, 4.0, -1, -1, 50, 0, false, false, false)
            end

            -- Turn radio on/off
            if IsControlJustPressed(0, Radio.Controls.Toggle) then
                Radio.On = not Radio.On

                if Radio.On then
                    SendNUIMessage({ sound = "audio_on", volume = 0.3})
                    Radio:Add(Radio.Frequency.Current)
                else
                    SendNUIMessage({ sound = "audio_off", volume = 0.5})
                    Radio:Remove(Radio.Frequency.Current)
                end
            end

            -- Change radio frequency
            if not Radio.On then
                if not Radio.Controls.Decrease.Pressed then
                    if IsControlJustPressed(0, Radio.Controls.Decrease.Key) then
                        Radio.Controls.Decrease.Pressed = true
                        Citizen.CreateThread(function()
                            while IsControlPressed(0, Radio.Controls.Decrease.Key) do
                                Radio:Decrease(minFrequency)
                                Citizen.Wait(125)
                            end

                            Radio.Controls.Decrease.Pressed = false
                        end)
                    end
                end

                if not Radio.Controls.Increase.Pressed then
                    if IsControlJustPressed(0, Radio.Controls.Increase.Key) then
                        Radio.Controls.Increase.Pressed = true
                        Citizen.CreateThread(function()
                            while IsControlPressed(0, Radio.Controls.Increase.Key) do
                                Radio:Increase(minFrequency)
                                Citizen.Wait(125)
                            end

                            Radio.Controls.Increase.Pressed = false
                        end)
                    end
                end

                if not Radio.Controls.Input.Pressed then
                    if IsControlJustPressed(0, Radio.Controls.Input.Key) then
                        Radio.Controls.Input.Pressed = true
                        Citizen.CreateThread(function()
                            DisplayOnscreenKeyboard(1, Radio.Labels[3][1], "", Radio.Frequency.Current, "", "", "", 3)

                            while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
                                Citizen.Wait(150)
                            end

                            local input = nil

                            if UpdateOnscreenKeyboard() ~= 2 then
                                input = GetOnscreenKeyboardResult()
                            end

                            Citizen.Wait(500)
                            
                            if input ~= nil then
                                input = tonumber(input)
                                if input >= minFrequency and input <= Radio.Frequency.Max and input == math.floor(input) then
                                    Radio.Frequency.Current = input
                                end
                            end
                            
                            Radio.Controls.Input.Pressed = false
                        end)
                    end
                end
            end
        else
            -- Play emergency services radio animation
            if isEmergency then
                if Radio.Has and Radio.On and isBroadcasting and not isPlayingBroadcastAnim then
                    RequestAnimDict(broadcastDictionary)
    
                    while not HasAnimDictLoaded(broadcastDictionary) do
                        Citizen.Wait(150)
                    end
        
                    TaskPlayAnim(playerPed, broadcastDictionary, broadcastAnimation, 8.0, 0.0, -1, 49, 0, 0, 0, 0)                    
                elseif not isBroadcasting and isPlayingBroadcastAnim then
                    StopAnimTask(playerPed, broadcastDictionary, broadcastAnimation, -4.0)
                end
            end
        end
    end
end)

RegisterNetEvent("Radio.Toggle")
AddEventHandler("Radio.Toggle", function()
    local playerPed = PlayerPedId()
    local isFalling = IsPedFalling(playerPed)
    local isDead = IsEntityDead(playerPed)
    
    if not isFalling and not isDead then
        Radio:Toggle(not Radio.Open)
    end
end)

RegisterNetEvent("Radio.Set")
AddEventHandler("Radio.Set", function(value)
    Radio.Has = (value == 1 or value == true or value == "true") and true or false
end)