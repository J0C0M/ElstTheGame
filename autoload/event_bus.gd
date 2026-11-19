extends Node
## Global signal hub. Systems talk to each other through these signals instead
## of holding references to each other. Add a signal here when a system needs one.

# The signals are emitted by other scripts, so they are never "used" in here.
@warning_ignore_start("unused_signal")

## Emitted by Settings after a setting changed and was written to disk.
signal settings_changed

## Player health after every change.
signal player_health_changed(current: int, maximum: int)
## Player stamina after every change.
signal player_stamina_changed(current: float, maximum: float)
## The player tried something without enough stamina.
signal player_stamina_insufficient
## The player parried an attack.
signal player_parried
signal player_died
signal player_respawned

## Prompt of the interactable the player faces, or "" when there is none.
signal interaction_prompt_changed(prompt: String)
## Short message on screen, such as a locked door.
signal message_requested(text: String)
## The player arrived in a named place: a world, a dungeon or a part of Elst.
signal location_entered(display_name: String)
## Asks Main to switch to another world scene and put the player at a spawn point.
signal world_change_requested(scene_path: String, spawn_id: StringName)
## The list of save files changed: a save was written or deleted.
signal saves_changed
## SaveManager read a save; Main switches to its world and restores it.
signal save_load_requested(data: Dictionary)
## The player's gold changed; [param total] is the new amount.
signal gold_changed(total: int)
## Items were added to or removed from the inventory.
signal inventory_changed
## The player picked something up, for a short line on the HUD.
signal loot_collected(text: String)
## An enemy died. [param enemy_id] is the id from its EnemyData.
signal enemy_killed(enemy_id: StringName)
## The player put on other gear.
signal equipment_changed
## Inwijding (the bond with Klaas) changed to [param level].
signal inwijding_changed(level: int)
