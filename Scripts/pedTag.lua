--[[
  * Created by MiiMii1205
  * license MIT
--]]

-- Constants --
BLIP_RAGDOLL_ID = 480
RAGDOLL_SHOW_BLIPS = false;

if RAGDOLL_SHOW_BLIPS then

    AddEventHandler('startRagdoll', function(id)
        local blip = AddBlipForEntity(id)
        SetBlipSprite(blip, BLIP_RAGDOLL_ID);

        AddEventHandler('stopRagdoll', function(ped)
            RemoveBlip(blip);
        end)

    end)

end