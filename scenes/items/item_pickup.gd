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
	($Visual/Potion as Node3D).visible = not item.is_gear() and item.type != ItemData.ItemType.AMMO
	if item.type == ItemData.ItemType.AMMO:
		$Visual.add_child(_make_bolts())
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
		var what: String = "pijlen" if item.type == ItemData.ItemType.AMMO else "drankjes"
		EventBus.message_requested.emit("Je kunt niet meer %s meenemen." % what)
		return false
	count -= taken
	if item.type == ItemData.ItemType.AMMO:
		EventBus.loot_collected.emit("+%d pijlen" % taken)
	else:
		EventBus.loot_collected.emit("%s opgepakt" % item.display_name)
	return count <= 0


## A small bundle of arrows: shafts with iron tips.
func _make_bolts() -> Node3D:
	var bundle: Node3D = Node3D.new()
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = item.model_color
	var iron: StandardMaterial3D = StandardMaterial3D.new()
	iron.albedo_color = Color(0.75, 0.75, 0.8)
	iron.emission_enabled = true
	iron.emission = Color(0.3, 0.3, 0.32)
	for n: int in 3:
		var shaft: MeshInstance3D = MeshInstance3D.new()
		var shaft_mesh: BoxMesh = BoxMesh.new()
		shaft_mesh.size = Vector3(0.04, 0.04, 0.55)
		shaft_mesh.material = wood
		shaft.mesh = shaft_mesh
		shaft.position = Vector3((n - 1) * 0.07, 0.2, 0)
		var tip: MeshInstance3D = MeshInstance3D.new()
		var tip_mesh: BoxMesh = BoxMesh.new()
		tip_mesh.size = Vector3(0.07, 0.07, 0.08)
		tip_mesh.material = iron
		tip.mesh = tip_mesh
		tip.position = Vector3(0, 0, -0.3)
		shaft.add_child(tip)
		bundle.add_child(shaft)
	return bundle
