--[[
  * Created by MiiMii1205
  * license MIT
--]]

-- Constants --
RAGDOLL_KEY = 19                -- LEFT ALT	/ D-PAD DOWN
RAGDOLL_DISABLE_ALL_KEY = 101   -- H / D-PAD RIGHT
ENABLE_AIM_RAGDOLL = true       -- Disables / Enables the main loop
GIVE_ALL_PLAYERS_WEAPONS = true -- Makes every player get an empty pistol at start
ENABLE_RAGDOLL_PLAYER = false   -- Enable the resource to ragdolls player peds
LAUNCH_FORCE = 5                -- In meters / seconds
ENABLE_RAG_SOUND = true         -- Enables sound support
INSTRUCTOR_ENABLED = true       -- Enables Instructor support
RESOURCE_NAME = GetCurrentResourceName()

-- Caching is nice --
VECTOR_ZERO = vec(0, 0, 0)
STARTUP_STRING = ('%s v%s initialized'):format(RESOURCE_NAME, GetResourceMetadata(RESOURCE_NAME, 'version', 0))
STARTUP_HTML_STRING = (':standing_person: %s <small>v%s</small> initialized'):format(RESOURCE_NAME, GetResourceMetadata(RESOURCE_NAME, 'version', 0))

-- Variables --
local ragdolledPedList = {}     -- List of ped ids that were ragdolled
local playerPed = PlayerPedId()
local playerId = PlayerId()
local isDisableAllInstructionActive = false;
local isPedAimingInstructionActive = false;

-- Functions --
function GivePlayerAnEmptyPistol()
    if ENABLE_AIM_RAGDOLL and GIVE_ALL_PLAYERS_WEAPONS then
        return GiveWeaponToPed(playerPed, 'WEAPON_PISTOL', 0, false, true);
    end
end

function IndexOf(a, id)
    for i, v in pairs(a) do
        if (v == id) then return i end
    end
    return -1
end

---Ragdolls a ped
---@param ped number The id of the ped to ragdoll
function EnableRagdoll(ped) return EnableRagdollWithForce(ped, VECTOR_ZERO) end

--- Disables all registered ragdolls
function DisableAllRagdoll() return TriggerEvent('stopAllRagdoll') end

--- Disables the ragdoll of a specific ped
---@param ped number The id of the ped to disable
function DisableRagdoll(ped) return TriggerEvent('stopSpecificRagdoll', ped) end

---UpdatePedAimingInstruction Toggles the "entity aiming" instruction for the instructor
---@param isEnabled boolean should the instruction be shown?
function UpdatePedAimingInstruction(isEnable)
    if isPedAimingInstructionActive ~= isEnable then
        isPedAimingInstructionActive = isEnable;
        if isPedAimingInstructionActive then
            return TriggerEvent('instructor:show-instruction', RAGDOLL_KEY, RESOURCE_NAME)
        else
            return TriggerEvent('instructor:hide-instruction', RAGDOLL_KEY, RESOURCE_NAME)
        end
    end
end

---UpdateDisableAllInstruction Toggles the "disable all" instruction for the instructor
---@param isEnabled boolean should the instruction be shown?
function UpdateDisableAllInstruction(isEnabled)
    if isDisableAllInstructionActive ~= isEnabled then
        isDisableAllInstructionActive = isEnabled

        if isDisableAllInstructionActive then
            return TriggerEvent('instructor:show-instruction', RAGDOLL_DISABLE_ALL_KEY, RESOURCE_NAME)
        else
            return TriggerEvent('instructor:hide-instruction', RAGDOLL_DISABLE_ALL_KEY, RESOURCE_NAME)
        end
    end
end

---Ragdolls a ped while applying force
---@param ped number The id of the ped to ragdoll
---@param force table the force to apply
function EnableRagdollWithForce(ped, force)

    if (IsEntityAPed(ped)) and (ENABLE_RAGDOLL_PLAYER or not IsPedAPlayer(ped)) then

        -- Ragdolling thread --
        Citizen.CreateThread(function()

            local pedId = ped;
            local pedRow = table.insert(ragdolledPedList, pedId)
            UpdateDisableAllInstruction(true);

            -- Makes this thread main loop stop --
            local needToBreak = false

            -- Stops the thread's main loop --
            local stopRagdoll = AddEventHandler('stopAllRagdoll', function() needToBreak = true end)
            local stopSpecificRagdoll = AddEventHandler('stopSpecificRagdoll', function(id) needToBreak = (id == pedId) or needToBreak; end)

            SetEntityVelocity(pedId, table.unpack(force))
            SetPedToRagdoll(pedId, 1000, 1000, 0, 0, 0, 0)
            SetEntityVelocity(pedId, table.unpack(force))

            TriggerEvent('startRagdoll', pedId);
            SetPedRagdollOnCollision(pedId, true)
            PlayAmbientSpeech1(ped, "GENERIC_HI", "SPEECH_PARAMS_INTERRUPT")

            -- Main loop --
            while not needToBreak and DoesEntityExist(pedId) do

                Citizen.Wait(0)
                SetPedToRagdoll(pedId, 1000, 1000, 0, 0, 0, 0)
                ResetPedRagdollTimer(pedId)

            end

            TriggerEvent('stopRagdoll', pedId);

            -- Ragdolling is done --
            SetPedRagdollOnCollision(pedId, false)
            table.remove(ragdolledPedList, pedRow);
            PlayAmbientSpeech1(ped, "GENERIC_BYE", "SPEECH_PARAMS_INTERRUPT")

            local isListEmpty = next(ragdolledPedList) == nil
            UpdateDisableAllInstruction(not isListEmpty);

            RemoveEventHandler(stopRagdoll)
            return RemoveEventHandler(stopSpecificRagdoll)

        end)

    end

end

---Empties the curent aimed vehicle and ragdolls all it's passengers
---@param vehicle number the vehicle ID to use
function EmptyOutVehicle(vehicle)

    -- Caching ---
    local vehiclePos = GetEntityCoords(vehicle);
    local vehicleVelocity = GetEntityVelocity(vehicle);
    local maxNumberOfPassagers = GetVehicleMaxNumberOfPassengers(vehicle);

    for i = -1, maxNumberOfPassagers do

        local ped = GetPedInVehicleSeat(vehicle, i);

        if DoesEntityExist(ped) then

            ClearPedTasksImmediately(ped)

            -- Pretty sure that peds in vehicles aren't ragdolling... But we'll check it anyway --
            if (IndexOf(ragdolledPedList, ped) == -1) then
                EnableRagdollWithForce(ped, (norm(GetEntityCoords(ped) - vehiclePos) * LAUNCH_FORCE) + vehicleVelocity)
            else
                DisableRagdoll(ped)
            end

        end

    end

end

---CheckRagdoller Managed the ragdolling
function CheckRagdoller()

    -- Weird if but it's slightly more optimal, as we are doing 2 native call except of 3
    if IsControlJustPressed(1, RAGDOLL_KEY) and IsPlayerFreeAiming(playerId) then

        local isAimingAtEntity, entity = GetEntityPlayerIsFreeAimingAt(playerId)

        if isAimingAtEntity then

            if IsEntityAPed(entity) then

                if not IsPedInAnyVehicle(entity) then

                    if (IndexOf(ragdolledPedList, entity) == -1) then
                        return EnableRagdoll(entity)
                    else
                        return DisableRagdoll(entity)
                    end

                else
                    return EmptyOutVehicle(GetVehiclePedIsUsing(entity))
                end

            elseif IsEntityAVehicle(entity) then
                return EmptyOutVehicle(entity)
            end

        end

    elseif IsControlJustPressed(1, RAGDOLL_DISABLE_ALL_KEY) and IsPlayerFreeAiming(playerId) then
        return DisableAllRagdoll()
    end

end

local currentInstructionText = "Toggle Ragdolling";

function UpdateInstructionText(newText)
    if currentInstructionText ~= newText then
        currentInstructionText = newText
        TriggerEvent('instructor:update-instruction', RAGDOLL_KEY, currentInstructionText, RESOURCE_NAME)
    end
end

VEH_RAGDOLL_INSTRUCTION_TEXT = "Toggle Ragdoll on every passagers";
PED_RAGDOLL_INSTRUCTION_TEXT = "Toggle Ragdolling";

---ManageInstructor Manages the Instructor
function ManageInstructor()

    local shouldAimingInstructionBeVisible = false;

    if IsPlayerFreeAiming(playerId) then

        local isAimingAtEntity, entity = GetEntityPlayerIsFreeAimingAt(playerId)

        if isAimingAtEntity then

            shouldAimingInstructionBeVisible = true;

            if IsEntityAPed(entity) then
                UpdateInstructionText(((IsPedInAnyVehicle(entity) and VEH_RAGDOLL_INSTRUCTION_TEXT) or PED_RAGDOLL_INSTRUCTION_TEXT))
            elseif IsEntityAVehicle(entity) then
                UpdateInstructionText(VEH_RAGDOLL_INSTRUCTION_TEXT)
            else
                shouldAimingInstructionBeVisible = false
            end

        end

    end

    UpdatePedAimingInstruction(shouldAimingInstructionBeVisible);

end

-- Reset globals once the player spawn (or in our case, respawn) --
AddEventHandler('playerSpawned', function()

    DisableAllRagdoll()

    playerId = PlayerId()
    playerPed = PlayerPedId()

    return GivePlayerAnEmptyPistol()

end)

AddEventHandler('RCC:newPed', function()
    playerPed = PlayerPedId()
    playerId = PlayerId()
    return GivePlayerAnEmptyPistol()
end)

GivePlayerAnEmptyPistol()

AddEventHandler('startRagdoll', function(id)

    TriggerEvent('msgprinter:addMessage', (":woozy_face: Ped **<samp>#%s</samp>** is ragdolling"):format(id), RESOURCE_NAME);

end)

AddEventHandler('stopRagdoll', function(id)

    TriggerEvent('msgprinter:addMessage', (":grinning: Ped **<samp>#%s</samp>** stopped ragdolling"):format(id), RESOURCE_NAME);

end)

AddEventHandler('startRagdoll', function(ped)

    if ENABLE_RAG_SOUND then
        PlaySoundFromEntity(-1, "SELECT", ped, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
    end

end)

AddEventHandler('stopRagdoll', function(ped)

    if ENABLE_RAG_SOUND then
        PlaySoundFromEntity(-1, "CANCEL", ped, "HUD_LIQUOR_STORE_SOUNDSET", 0, 0)
    end

end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESSOURCE_NAME then
        DisableAllRagdoll();
    end
end)

-- Main thread --
Citizen.CreateThread(function()

    print(STARTUP_STRING)
    TriggerEvent('msgprinter:addMessage', STARTUP_HTML_STRING, RESOURCE_NAME);

    if INSTRUCTOR_ENABLED then

        TriggerEvent('instructor:add-instruction', RAGDOLL_KEY, "Toggle Ragdolling", RESOURCE_NAME, isPedAimingInstructionActive);
        TriggerEvent('instructor:add-instruction', RAGDOLL_DISABLE_ALL_KEY, "Clear all ragdoll", RESOURCE_NAME, isDisableAllInstructionActive);

        -- Main Loop --
        while ENABLE_AIM_RAGDOLL do
            Citizen.Wait(0)
            ManageInstructor()
            CheckRagdoller()
        end

        TriggerEvent('instructor:flush', RESOURCE_NAME);
    else
        -- Main Loop --
        while ENABLE_AIM_RAGDOLL do
            Citizen.Wait(0)
            CheckRagdoller()
        end
    end

end)