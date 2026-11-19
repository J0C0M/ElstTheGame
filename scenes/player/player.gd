class_name Player
extends CharacterBody3D
## The player. The states under StateMachine decide what happens each physics
## frame; this script holds the stats and shared helpers, applies gravity and
## moves the body.

## Move actions that dodge when tapped twice, with their direction relative
## to the camera.
## Speed an unblocked hit pushes the player back with.
const KNOCKBACK_SPEED: float = 3.0
## Seconds to load the next bolt.
const RELOAD_TIME: float = 0.9
## Camera field of view while aiming the crossbow.
const AIM_FOV: float = 48.0
## How far the crossbow aims.
const AIM_RANGE: float = 80.0

const TAP_DIRECTIONS: Dictionary = {
	&"move_forward": Vector3(0, 0, -1), &"move_back": Vector3(0, 0, 1),
	&"move_left": Vector3(-1, 0, 0), &"move_right": Vector3(1, 0, 0),
}

@export var stats: PlayerStats
## Armour worn when GameState has none.
@export var armor: ItemData
## Bolt the crossbow shoots.
@export var bolt_scene: PackedScene

## The sword in hand, or null: a new game starts without one.
var sword: ItemData
var crossbow: ItemData
## Weapon in hand: &"sword" or &"crossbow" (keys 1 and 2).
var weapon: StringName = &"sword"
## True while the right mouse button aims the crossbow.
var aiming: bool = false
var _reload_left: float = 0.0
var _normal_fov: float = 75.0
var _crossbow_node: Node3D

## True while sprinting. Set by the move state, read by the model.
var is_sprinting: bool = false
## True during the first part of a dodge roll.
var is_invulnerable: bool = false
## True while the block state is active.
var is_blocking: bool = false
## Clock time the current block was pressed, for the parry window.
var block_started_at: float = -INF
## Seconds of physics time since the player spawned. Used for input timing,
## so it follows the game clock rather than the wall clock.
var clock: float = 0.0

var _gravity: float = 0.0
var _last_tap_time: Dictionary[StringName, float] = {}
var _interactables: Array[Interactable] = []
## Outside push for this physics frame, such as the tornado's wind.
var _wind_velocity: Vector3 = Vector3.ZERO
var _no_sword_message_wait: float = 0.0
var _focused_interactable: Interactable

@onready var model: HumanoidModel = $Model
@onready var camera: PlayerCamera = $Camera
@onready var health: HealthComponent = $Health
@onready var stamina: StaminaComponent = $Stamina
@onready var sword_hitbox: Hitbox = $SwordHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _interaction_area: Area3D = $InteractionArea
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity")) * stats.gravity_multiplier
	health.health_changed.connect(EventBus.player_health_changed.emit)
	stamina.stamina_changed.connect(EventBus.player_stamina_changed.emit)
	stamina.insufficient.connect(EventBus.player_stamina_insufficient.emit)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	_interaction_area.area_entered.connect(_on_interaction_area_entered)
	_interaction_area.area_exited.connect(_on_interaction_area_exited)
	EventBus.interaction_prompt_changed.emit("")
	_normal_fov = camera.camera.fov
	_crossbow_node = _build_crossbow()
	EventBus.equipment_changed.connect(_apply_gear)
	_apply_gear()
	health.reset(stats.max_health)
	stamina.reset(stats.max_stamina, stats.stamina_regen_per_second, stats.stamina_regen_delay)


func _physics_process(delta: float) -> void:
	clock += delta
	_reload_left = maxf(_reload_left - delta, 0.0)
	camera.camera.fov = lerpf(camera.camera.fov, AIM_FOV if aiming else _normal_fov, minf(10.0 * delta, 1.0))
	_no_sword_message_wait = maxf(_no_sword_message_wait - delta, 0.0)
	state_machine.physics_update(delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	# The wind moves the body but is not kept in the velocity, so it stops
	# as soon as nothing pushes any more.
	velocity += _wind_velocity
	move_and_slide()
	velocity -= _wind_velocity
	_wind_velocity = Vector3.ZERO
	model.set_locomotion(Vector2(velocity.x, velocity.z).length(), is_sprinting, is_on_floor())
	_update_interaction_focus()


## Move input turned to match the camera, on the ground plane. Length 0 to 1.
func get_move_direction() -> Vector3:
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	return camera.get_yaw_basis() * Vector3(input.x, 0.0, input.y)


## Accelerates the horizontal velocity towards [param direction] times [param speed].
func move_horizontally(direction: Vector3, speed: float, acceleration: float, delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Turns smoothly to face [param direction] on the ground plane.
func turn_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-stats.turn_speed * delta))


## Faces [param direction] straight away.
func face_direction_now(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	rotation.y = atan2(-direction.x, -direction.z)


func has_sword() -> bool:
	return sword != null


## True when the player can fight; otherwise says why, now and then.
func check_sword() -> bool:
	if has_sword():
		return true
	if _no_sword_message_wait <= 0.0:
		_no_sword_message_wait = 2.0
		EventBus.message_requested.emit("Je hebt nog geen zwaard. Praat eerst met Klaas.")
	return false


## Starts drinking the potion that suits the missing health best.
func try_drink() -> void:
	var potion: ItemData = _choose_potion()
	if potion == null:
		EventBus.message_requested.emit("Je hebt geen drankjes.")
		return
	state_machine.transition_to(&"Drink", {"potion": potion})


## Faces where the camera looks, straight away. Used for attacks and blocking.
func face_camera_direction() -> void:
	rotation.y = camera.yaw


## Damage of one sword hit with the equipped sword.
func get_sword_damage(multiplier: float) -> int:
	return roundi(sword.damage * multiplier)


## Starts a dodge roll if the player stands on the ground and has the stamina.
## Without a direction the player rolls backwards.
func try_dodge(direction: Vector3) -> bool:
	if not is_on_floor() or not stamina.try_spend(stats.dodge_stamina_cost):
		return false
	var backwards: bool = direction.length_squared() < 0.01
	if backwards:
		direction = -get_forward()
	state_machine.transition_to(&"Dodge", {"direction": direction.normalized(), "backwards": backwards})
	EventBus.player_action.emit(&"dodge")
	return true


## Registers a press on a move action. Returns true on the second press of a
## double tap.
func register_direction_tap(action: StringName) -> bool:
	var previous: float = _last_tap_time.get(action, -INF)
	if clock - previous <= stats.double_tap_window:
		_last_tap_time[action] = -INF
		return true
	_last_tap_time[action] = clock
	return false


## Direction of a tapped move action, turned to match the camera.
func get_tap_direction(action: StringName) -> Vector3:
	var local_direction: Vector3 = TAP_DIRECTIONS[action]
	return camera.get_yaw_basis() * local_direction


func get_forward() -> Vector3:
	return -global_basis.z


## Uses the interactable closest to the player, if there is one.
func interact() -> void:
	if _focused_interactable != null:
		_focused_interactable.interact(self)


## True when [param point] lies within the block angle in front of the player.
func is_facing_point(point: Vector3) -> bool:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	if to_point.length_squared() < 0.0001:
		return true
	return get_forward().angle_to(to_point.normalized()) <= deg_to_rad(stats.block_angle_degrees)


## Pushes the player with [param wind_velocity] (metres per second) during
## this physics frame. Call it every frame the push should last.
func apply_wind(wind_velocity: Vector3) -> void:
	_wind_velocity = wind_velocity


## Moves the player to [param at] at once, without sliding there.
func teleport(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	camera.snap_behind_target()
	reset_physics_interpolation()


## Brings the player back to life at [param at], with full health and stamina.
func respawn(at: Transform3D) -> void:
	teleport(at)
	is_invulnerable = false
	health.reset(stats.max_health)
	stamina.refill()
	model.reset_pose()
	state_machine.transition_to(&"Move")
	EventBus.player_respawned.emit()


## Health and stamina, which carry over when the player changes world.
func get_vitals() -> Dictionary:
	return {"health": health.current_health, "stamina": stamina.current_stamina}


func set_vitals(data: Dictionary) -> void:
	health.set_health(int(data.get("health", health.current_health)))
	stamina.set_stamina(float(data.get("stamina", stamina.current_stamina)))


## Everything a save file keeps about the player (persist group).
func save_data() -> Dictionary:
	var data: Dictionary = get_vitals()
	data["position"] = [global_position.x, global_position.y, global_position.z]
	data["rotation_y"] = rotation.y
	data["camera_yaw"] = camera.yaw
	data["camera_pitch"] = camera.pitch
	return data


func load_data(data: Dictionary) -> void:
	var position_data: Array = data.get("position", [])
	if position_data.size() == 3:
		var saved_position: Vector3 = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
		teleport(Transform3D(Basis(Vector3.UP, float(data.get("rotation_y", 0.0))), saved_position))
		camera.yaw = float(data.get("camera_yaw", camera.yaw))
		camera.pitch = float(data.get("camera_pitch", camera.pitch))
	set_vitals(data)


func _on_hit_received(hit: HitData) -> void:
	if health.is_dead() or is_invulnerable:
		return
	var damage: float = hit.damage
	var guarded: bool = false
	var guard_broken: bool = false
	if is_blocking and is_facing_point(hit.source.global_position):
		if clock - block_started_at <= stats.parry_window:
			hit.hitbox.parried.emit()
			model.play_action(&"parry", 0.3)
			EventBus.player_parried.emit()
			EventBus.player_action.emit(&"block")
			EventBus.player_action.emit(&"parry")
			return
		if stamina.try_spend(stats.block_stamina_cost):
			guarded = true
			damage *= 1.0 - stats.block_damage_reduction
			model.play_action(&"block_impact", 0.25)
			EventBus.player_action.emit(&"block")
		else:
			guard_broken = true
	damage *= 1.0 - armor.damage_reduction
	health.take_damage(maxi(roundi(damage), 1))
	if health.is_dead() or guarded:
		return
	var away: Vector3 = global_position - hit.source.global_position
	away.y = 0.0
	velocity += away.normalized() * KNOCKBACK_SPEED
	var duration: float = stats.guard_break_duration if guard_broken else stats.hurt_duration
	state_machine.transition_to(&"Hurt", {"duration": duration})


## The smallest potion that heals all missing health, or else the biggest one.
func _choose_potion() -> ItemData:
	var missing: int = health.max_health - health.current_health
	var best: ItemData = null
	for id: StringName in GameState.inventory:
		var item: ItemData = ItemCatalog.get_item(id)
		if item == null or item.type != ItemData.ItemType.CONSUMABLE:
			continue
		if best == null:
			best = item
		elif best.heal_amount < missing:
			if item.heal_amount > best.heal_amount:
				best = item
		elif item.heal_amount >= missing and item.heal_amount < best.heal_amount:
			best = item
	return best


## Takes the worn gear from GameState and shows it on the model.
## Takes the sword (1) or the crossbow (2) in hand.
func select_weapon(new_weapon: StringName) -> void:
	if new_weapon == &"crossbow" and crossbow == null:
		EventBus.message_requested.emit("Je hebt nog geen kruisboog.")
		return
	weapon = new_weapon
	if weapon != &"crossbow":
		set_aiming(false)
	_update_weapon_visuals()


func set_aiming(on: bool) -> void:
	if on == aiming:
		return
	aiming = on
	EventBus.crosshair_changed.emit(on)


## Shoots a bolt at whatever the crosshair points to, if one is loaded.
func try_shoot() -> void:
	if crossbow == null or _reload_left > 0.0:
		return
	_reload_left = RELOAD_TIME
	face_camera_direction()
	var eye: Camera3D = camera.camera
	var from: Vector3 = eye.global_position
	var to: Vector3 = from - eye.global_basis.z * AIM_RANGE
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.WORLD | PhysicsLayers.ENEMY, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit.get("position", to)
	var origin: Vector3 = global_position + Vector3.UP * 1.4 + get_forward() * 0.6
	var bolt: Node3D = bolt_scene.instantiate() as Node3D
	get_parent().add_child(bolt)
	bolt.call(&"launch", origin, target - origin, crossbow.damage, self)
	EventBus.player_action.emit(&"shoot")


func _update_weapon_visuals() -> void:
	model.get_node("Body/Hips/Torso/ArmR/Hand/Sword").visible = sword != null and weapon == &"sword"
	_crossbow_node.visible = weapon == &"crossbow"


## A simple crossbow in the right hand: a stock and a bow.
func _build_crossbow() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Crossbow"
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.28, 0.16)
	for part: Array in [[Vector3(0.08, 0.08, 0.55), Vector3(0, -0.05, -0.22)], [Vector3(0.62, 0.04, 0.05), Vector3(0, -0.05, -0.44)]]:
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = part[0]
		mesh.material = wood
		var piece: MeshInstance3D = MeshInstance3D.new()
		piece.mesh = mesh
		piece.position = part[1]
		root.add_child(piece)
	root.visible = false
	model.get_node("Body/Hips/Torso/ArmR/Hand").add_child(root)
	return root


func _apply_gear() -> void:
	sword = GameState.get_equipped(&"sword")
	crossbow = GameState.get_equipped(&"crossbow")
	if crossbow == null and weapon == &"crossbow":
		weapon = &"sword"
	var worn_armor: ItemData = GameState.get_equipped(&"armor")
	if worn_armor != null:
		armor = worn_armor
	var sword_node: Node3D = model.get_node("Body/Hips/Torso/ArmR/Hand/Sword")
	sword_node.visible = sword != null
	if sword != null:
		var blade: MeshInstance3D = sword_node.get_node("Blade")
		var blade_mesh: BoxMesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.035, 0.08, sword.blade_length)
		blade.mesh = blade_mesh
		blade.position.z = -0.125 - sword.blade_length * 0.5
		blade.material_override = _gear_material(sword.model_color, true)
	_update_weapon_visuals()
	var armor_material: StandardMaterial3D = _gear_material(armor.model_color, armor.armor_tier >= 2)
	var pieces: Dictionary[String, int] = {
		"Body/Hips/Torso/ArmorChest": 1,
		"Body/Hips/Torso/ArmL/Pauldron": 2,
		"Body/Hips/Torso/ArmR/Pauldron": 2,
		"Body/Hips/Torso/Head/Helmet": 3,
	}
	for path: String in pieces:
		var piece: MeshInstance3D = model.get_node(path)
		piece.visible = armor.armor_tier >= pieces[path]
		piece.material_override = armor_material


func _gear_material(color: Color, metal: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.45 if metal else 0.0
	material.roughness = 0.45 if metal else 1.0
	return material


func _update_interaction_focus() -> void:
	var best: Interactable = null
	if not health.is_dead():
		var best_distance: float = INF
		for interactable: Interactable in _interactables:
			if not is_instance_valid(interactable) or not interactable.enabled:
				continue
			var distance: float = global_position.distance_squared_to(interactable.global_position)
			if distance < best_distance:
				best = interactable
				best_distance = distance
	if best != _focused_interactable:
		_focused_interactable = best
		EventBus.interaction_prompt_changed.emit(best.prompt if best != null else "")


func _on_interaction_area_entered(area: Area3D) -> void:
	var interactable: Interactable = area as Interactable
	if interactable != null and interactable not in _interactables:
		_interactables.append(interactable)


func _on_interaction_area_exited(area: Area3D) -> void:
	var interactable: Interactable = area as Interactable
	if interactable != null:
		_interactables.erase(interactable)


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
	EventBus.player_died.emit()
