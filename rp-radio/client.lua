local Radio = {
    Has = false,
    Open = false,
    On = false,
    Enabled = true,
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
        Activator = {
            Name = "INPUT_REPLAY_START_STOP_RECORDING_SECONDARY", -- Control name
            Key = 289, -- F2
        },
        Secondary = {
            Name = "INPUT_SPRINT",
            Key = 21, -- Left Shift
            Enabled = true, -- Require secondary to be pressed to open radio with Activator
        },
        Toggle = {
            Name = "INPUT_CONTEXT", -- Control name
            Key = 51, -- E
        },
        Increase = {
            Name = "INPUT_CELLPHONE_Right", -- Control name
            Key = 175, -- Right Arrow
            Pressed = false,
        },
        Decrease = {
            Name = "INPUT_CELLPHONE_LEFT", -- Control name
            Key = 174, -- Left Arrow
            Pressed = false,
        },
        Input = {
            Name = "INPUT_FRONTEND_ACCEPT", -- Control name
            Key = 201, -- Enter
            Pressed = false,
        },
        Broadcast = {
            Name = "INPUT_VEH_PUSHBIKE_SPRINT", -- Control name
            Key = 137, -- Caps Lock
        },
    },
    Frequency = {
        Private = 4, -- Number of private frequencies for emergency services
        Current = 1,
        Min = 0,
        Max = 800, -- Number of freqencies
        Emergency = false,
    },
}
Radio.Labels = {        
    { "FRZL_RADIO_HELP", "~s~Press " .. (Radio.Controls.Secondary.Enabled and "~" .. Radio.Controls.Secondary.Name .. "~ + ~" .. Radio.Controls.Activator.Name .. "~" or "~" .. Radio.Controls.Activator.Name .. "~") .. " to hide.~n~Press ~" .. Radio.Controls.Toggle.Name .. "~ to turn radio ~g~on~s~.~n~Press ~" .. Radio.Controls.Decrease.Name .. "~ or ~" .. Radio.Controls.Increase.Name .. "~ to switch frequency~n~Press ~" .. Radio.Controls.Input.Name .. "~ to choose frequency~n~Frequency: ~1~ MHz" },
    { "FRZL_RADIO_HELP2", "~s~Press " .. (Radio.Controls.Secondary.Enabled and "~" .. Radio.Controls.Secondary.Name .. "~ + ~" .. Radio.Controls.Activator.Name .. "~" or "~" .. Radio.Controls.Activator.Name .. "~") .. " to hide.~n~Press ~" .. Radio.Controls.Toggle.Name .. "~ to turn radio ~r~off~s~.~n~Press ~" .. Radio.Controls.Broadcast.Name .. "~ to broadcast.~n~Frequency: ~1~ MHz" },
    { "FRZL_RADIO_INPUT", "Enter Frequency" },
}
Radio.Commands = {
    {
        Enabled = true, -- Add a command to be able to open/close the radio
        Name = "radio", -- Command name
        Help = "Toggle hand radio", -- Command help shown in chatbox when typing the command
        Params = {},
        Handler = function(src, args, raw)
            local playerPed = PlayerPedId()
            local isFalling = IsPedFalling(playerPed)
            local isDead = IsEntityDead(playerPed)

            if not isFalling and Radio.Enabled and Radio.Has and not isDead then
                Radio:Toggle(not Radio.Open)
            elseif (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
                Radio:Toggle(false)
                Radio.On = false
                Radio:Remove(Radio.Frequency.Current)
                exports["tokovoip_script"]:SetTokoProperty("radioEnabled", false)
            elseif Radio.Open and isFalling then
                Radio:Toggle(false)
            end            
        end,
    },
    {
        Enabled = true, -- Add a command to choose radio frequency
        Name = "frequency", -- Command name
        Help = "Change radio frequency", -- Command help shown in chatbox when typing the command
        Params = {
            {name = "number", "Enter frequency"}
        },
        Handler = function(src, args, raw)
            if Radio.Has then
                if args[1] then
                    if tonumber(args[1]) then
                        local minFrequency = Radio.Frequency.Min + (Radio.Frequency.Emergency and 1 or (Radio.Frequency.Private + 1))
                        if args[1] >= minFrequency and args[1] <= Radio.Frequency.Max and args[1] == math.floor(input) then
                            if Radio.Enabled then
                                Radio:Remove(Radio.Frequency.Current)
                            end
                            Radio.Frequency.Current = args[1]
                            Radio:Add(Radio.Frequency.Current)     
                        end
                    end
                end                    
            end
        end,
    },
}

-- Setup each radio command if enabled
for i = 1, #Radio.Commands do
    if Radio.Commands[i].Enabled then
        RegisterCommand(Radio.Commands[i].Name, Radio.Commands[i].Handler, false)
        TriggerEvent("chat:addSuggestion", "/" .. Radio.Commands[i].Name, Radio.Commands[i].Help, Radio.Commands[i].Params)
    end
end

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

    if self.On and not self.Frequency.Emergency then
        exports["tokovoip_script"]:SetTokoProperty("radioEnabled", toggle)
    end

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

-- Check if radio is switched on
function IsRadioOn()
    return Radio.On
end

-- Check if player has radio
function IsRadioAvailable()
    return Radio.Has
end

-- Check if radio is enabled or not
function IsRadioEnabled()
    return not Radio.Enabled
end

-- Check if radio can be used
function CanRadioBeUsed()
    return Radio.Has and Radio.On
end

-- Set if the radio is enabled or not
function SetRadioEnabled(value)
    Radio.Enabled = value
end

-- Set if player has access to emergency frequencies
function SetEmergency(value)
    Radio.Frequency.Emergency = value

    if Radio.On and not Radio.Open and Radio.Frequency.Emergency then
        exports["tokovoip_script"]:SetTokoProperty("radioEnabled", true)
    end
end

-- Check if player has access to emergency frequencies
function IsEmergency()
    return Radio.Frequency.Emergency
end

-- Define exports
exports("IsRadioOpen", IsRadioOpen)
exports("IsRadioOn", IsRadioOn)
exports("IsRadioAvailable", IsRadioAvailable)
exports("IsRadioEnabled", IsRadioEnabled)
exports("CanRadioBeUsed", CanRadioBeUsed)
exports("SetRadioEnabled", SetRadioEnabled)
exports("SetEmergency", SetEmergency)
exports("IsEmergency", IsEmergency)

Citizen.CreateThread(function()
    -- Add Labels
    for i = 1, #Radio.Labels do
        AddTextEntry(Radio.Labels[i][1], Radio.Labels[i][2])
    end

    while true do
        Citizen.Wait(0)
        -- Init local vars
        local playerPed = PlayerPedId()
        local isActivatorPressed = IsControlJustPressed(0, Radio.Controls.Activator.Key)
        local isSecondaryPressed = (Radio.Controls.Secondary.Enabled and IsControlPressed(0, Radio.Controls.Secondary.Key) or true)
        local isFalling = IsPedFalling(playerPed)
        local isDead = IsEntityDead(playerPed)
        local minFrequency = Radio.Frequency.Min + (Radio.Frequency.Emergency and 1 or (Radio.Frequency.Private + 1))
        local broadcastType = 3 + (Radio.Frequency.Emergency and 1 or 0) + ((Radio.Open and Radio.Frequency.Emergency) and -1 or 0) 
        local broadcastDictionary = Radio.Dictionary[broadcastType]
        local broadcastAnimation = Radio.Animation[broadcastType]
        local isBroadcasting = IsControlPressed(0, Radio.Controls.Broadcast.Key)
        local isPlayingBroadcastAnim = IsEntityPlayingAnim(playerPed, broadcastDictionary, broadcastAnimation, 3)

        -- Open radio settings
        if isActivatorPressed and isSecondaryPressed and not isFalling and Radio.Enabled and Radio.Has and not isDead then
            Radio:Toggle(not Radio.Open)
        elseif (Radio.Open or Radio.On) and ((not Radio.Enabled) or (not Radio.Has) or isDead) then
            Radio:Toggle(false)
            Radio.On = false
            Radio:Remove(Radio.Frequency.Current)
            exports["tokovoip_script"]:SetTokoProperty("radioEnabled", false)
        elseif Radio.Open and isFalling then
            Radio:Toggle(false)
        end

        -- Remove player from emergency services comms if not part of the emergency services
        if not Radio.Frequency.Emergency and Radio.Frequency.Current <= Radio.Frequency.Private and Radio.On then
            Radio:Remove(Radio.Frequency.Current)
            Radio.Frequency.Current = minFrequency
            Radio:Add(Radio.Frequency.Current)
        elseif not Radio.Frequency.Emergency and Radio.Frequency.Current <= Radio.Frequency.Private and not Radio.On then
            Radio.Frequency.Current = minFrequency
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
            BeginTextCommandDisplayHelp(Radio.Labels[Radio.On and 2 or 1][1])
            AddTextComponentInteger(Radio.Frequency.Current)
            EndTextCommandDisplayHelp(false, false, false, -1)

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
            if IsControlJustPressed(0, Radio.Controls.Toggle.Key) then
                Radio.On = not Radio.On

                exports["tokovoip_script"]:SetTokoProperty("radioEnabled", Radio.On)

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
            if Radio.Frequency.Emergency then
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

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if NetworkIsSessionStarted() then
            exports["tokovoip_script"]:SetTokoProperty("radioClickMaxChannel", Radio.Frequency.Max) -- Set radio clicks enabled for all radio frequencies
            exports["tokovoip_script"]:SetTokoProperty("radioAnim", false) -- Disable built-in toko radio animation
            exports["tokovoip_script"]:SetTokoProperty("radioEnabled", false) -- Disable radio control
			return
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
    Radio.Has = value
end)