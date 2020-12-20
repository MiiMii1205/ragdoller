-- Constants --
RAGDOLL_KEY = 19                -- LEFT ALT	/ D-PAD DOWN
RAGDOLL_DISABLE_ALL_KEY = 101   -- H / D-PAD RIGHT

-- Settings --
ENABLE_AIM_RAGDOLL = true       -- Disables / Enables the main loop
GIVE_ALL_PLAYERS_WEAPONS = true -- Makes every player get an empty pistol at start
ENABLE_RAGDOLL_PLAYER = false   -- Enable the resource to ragdolls player peds

LAUNCH_FORCE = 5                -- In meters / seconds
VECTOR_ZERO = vec(0, 0, 0)      -- Caching is nice

-- Variables --
local ragdolledPedList = {}     -- List of ped ids that were ragdolled
local playerPed = PlayerPedId()
local playerId = PlayerId()

function GivePlayerAnEmptyWeapon()
    if ENABLE_AIM_RAGDOLL and GIVE_ALL_PLAYERS_WEAPONS then
        return GiveWeaponToPed(playerPed, 'WEAPON_PISTOL', 0, false, true);
    end
end

GivePlayerAnEmptyWeapon()

function IndexOf(a, id)

    for i, v in pairs(a) do
        if v == id then
            return i
        end
    end

    return -1

end

---Ragdolls a ped
---@param ped number The id of the ped to ragdoll
function EnableRagdoll(ped)
    return EnableRagdollWithForce(ped, VECTOR_ZERO)
end

---Ragdolls a ped while applying force
---@param ped number The id of the ped to ragdoll
---@param force table the force to apply
function EnableRagdollWithForce(ped, force)

    if (IsEntityAPed(ped)) and (ENABLE_RAGDOLL_PLAYER or not IsPedAPlayer(ped)) then

        -- Ragdolling thread --
        Citizen.CreateThread(function()

            local pedId = ped;
            local needToBreak = false
            local pedRow = table.insert(ragdolledPedList, pedId)

            local stopRagdoll = AddEventHandler('stopAllRagdoll', function()
                -- Stops the thread's main loop --
                needToBreak = true
            end)

            local stopSpecificRagdoll = AddEventHandler('stopSpecificRagdoll', function(id)
                if id == pedId then
                    -- Stops the thread's main loop --
                    needToBreak = true
                end
            end)

            SetEntityVelocity(pedId, table.unpack(force))
            SetPedToRagdoll(pedId, 1000, 1000, 0, 0, 0, 0)
            SetEntityVelocity(pedId, table.unpack(force))

            TriggerEvent('startRagdoll', pedId);
            SetPedRagdollOnCollision(pedId, true)

            -- When the 'stopSpecificRagdoll' or 'stopAllRagdoll' is triggered this while will evaluate to false, thus ending the thread --
            while not needToBreak and DoesEntityExist(pedId) do
                Citizen.Wait(0)
                SetPedToRagdoll(pedId, 1000, 1000, 0, 0, 0, 0)
                ResetPedRagdollTimer(pedId)
            end

            -- Ragdolling is done --
            SetPedRagdollOnCollision(pedId, false)
            table.remove(ragdolledPedList, pedRow);

            RemoveEventHandler(stopRagdoll)
            return RemoveEventHandler(stopSpecificRagdoll)

        end)

    end

end

--- Disables all registered ragdolls
function DisableAllRagdoll()
    return TriggerEvent('stopAllRagdoll')
end

--- Disables the ragdoll of a specific ped
---@param ped number The id of the ped to disable
function DisableRagdoll(ped)
    return TriggerEvent('stopSpecificRagdoll', ped)
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


-- Reset globals once the player spawn (or in our case, respawn) --
AddEventHandler('playerSpawned', function()

    DisableAllRagdoll()

    playerId = PlayerId()
    playerPed = PlayerPedId()

    return GivePlayerAnEmptyWeapon()

end)

---Managed the ragdolling
function CheckRagdoller()

    -- Weird if but it's slightly more optimal, as we are doing 2 native call except of 3
    if IsControlJustPressed(1, RAGDOLL_KEY) and IsPlayerFreeAiming(playerId) then

        local isAimingAtEntity, entity = GetEntityPlayerIsFreeAimingAt(playerId)

        if isAimingAtEntity then

            if IsEntityAPed(entity) then

                if not IsPedInAnyVehicle(entity) then

                    if (IndexOf(ragdolledPedList, ped) == -1) then
                        -- No peds were found in our list :( --
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

-- Main thread --
Citizen.CreateThread(function()

    print(('%s v%s initialized'):format(GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'version', 0)))

    -- Main Loop --
    while true do

        Citizen.Wait(0)

        if ENABLE_AIM_RAGDOLL then

            CheckRagdoller()

        end

    end

end)