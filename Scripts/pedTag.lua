--[[
  * Created by MiiMii1205
  * license MIT
--]]

-- Constants --
BLIP_RAGDOLL_ID = 480           -- Blimp id to use
RAGDOLL_SHOW_BLIPS = false;     -- Enables map blimp support for ragdolling peds

if RAGDOLL_SHOW_BLIPS then
    AddEventHandler('startRagdoll', function(id)
        local blip = AddBlipForEntity(id)
        SetBlipSprite(blip, BLIP_RAGDOLL_ID);

        local ragStop = AddEventHandler('stopRagdoll', function(ped)
            if ped == id then
                RemoveBlip(blip);
                RemoveEventHandler(ragStop);
            end
        end)
    end)
end