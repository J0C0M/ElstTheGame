class_name ItemPickup
extends Pickup
## An item on the ground: a healing potion, or a sword or armour from loot.
## Gear that beats what the player wears goes on at once.

@export var item: ItemData
@export var count: int = 1


func _ready() -> void:
	super()
	var gear_visual: Node3D = $Visual/Gear
	gear_visual.visible = item.is_gear()
	($Visual/Potion as Node3D).visible = not item.is_gear()
	if item.is_gear():
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = item.model_color
		material.metallic = 0.4
		material.emission_enabled = true
		material.emission = item.model_color * 0.4
		for mesh: Node in gear_visual.get_children():
			(mesh as MeshInstance3D).material_override = material


func _collect(_player: Player) -> bool:
	if item.is_gear():
		if not GameState.add_gear(item):
			EventBus.message_requested.emit("Een %s heb je al." % item.display_name.to_lower())
		EventBus.loot_collected.emit("%s gevonden" % item.display_name)
		return true
	var taken: int = GameState.add_item(item, count)
	if taken <= 0:
		EventBus.message_requested.emit("Je kunt niet meer drankjes meenemen.")
		return false
	count -= taken
	EventBus.loot_collected.emit("%s opgepakt" % item.display_name)
	return count <= 0
