# Ragdoller #

A simple [FiveM](https://fivem.net) script for enabling/disabling ragdolls on any aimed ped.

## Setup ##

Just clone this repo to your ressource folder of your [FiveM](https://fivem.net) server. You might also need to edit your `server.cfg` to auto load the resource.

Also, remember that this script won't make Ragdoller-affected ped invincible. Use it wisely, especially while toggling Ragdoller on players.

### Permissions ###

Remember that Ragdoller **doesn't** do any permission management. Therefore, it allows **EVERY** players to activate Ragdoller on any peds.

To prevent this, you can set the `ENABLE_AIM_RAGDOLL` value in the `Scripts/rag.lua` file. Then, you can use the exported `CheckRagdoller` function to your liking.

This will effectively makes Ragdoller act more like a library than a standalone ressource.

### Player Aiming Weapon ###

By default, the scrip will automatically give any player an empty pistol to enable then to aim at any peds.

To change this, you can set the `GIVE_ALL_PLAYERS_WEAPONS`  value in the `Scripts/rag.lua` file. Disabling `ENABLE_AIM_RAGDOLL` wil also prevent players to get pistols too.

### Player Ragdoller ###

By default, the script won't let players toggle Ragdoller on any other players.

To change this, set the `ENABLE_RAGDOLL_PLAYER` value in the `Scripts/rag.lua` file.

### Blips ###

Ragdoller can also add useful blips to every Ragdoller-affected ped.

This is turned off by default, but to enable these, set the `RAGDOLL_SHOW_BLIPS` value to `true` in the `Scripts/pedTag.lua` script

### Sounds ###

Ragdoller plays, by default, different sound while toggling Ragdoller on peds.

To mute Ragdoller, jus set the `ENABLE_RAG_SOUND` value to `false`

## Controls ##

| Input                                                                     | Controls                                              |
|---------------------------------------------------------------------------|-------------------------------------------------------|
| <kbd>LEFT ALT</kbd> <small>(while aiming at ped or vehicles)</small>      |  Toggles Ragdoller on aimed ped                       |
| <kbd>H</kbd> <small>(while aiming)</small>                                |  Disables Ragdoller for all Ragdoller-enabled ped     |

If you aim at any occupied vehicle, you can forcibly eject and toggle Ragdoller on all its passagers.

## Exports ##

The resource also exports a `CheckRagdoller` function that can be called to manage Ragdoller for one frame.

You can repeately call `CheckRagdoller` every frame and disable/enable it to your liking in any other resources. 