class_name Cutscene
extends Node3D
## A short scene in prototype quality: a camera of its own, lines at the
## bottom of the screen and waits, while the player cannot move or save. Make
## one with Cutscene.begin(), call the steps with await, and end with
## finish(). Prototype 2 will remake the scenes after the graphics overhaul.

const SAVE_BLOCK: StringName = &"scene"
## How far the camera stays in front of a wall or pillar it would be behind.
const WALL_GAP: float = 1.6

var _camera: Camera3D
var _player: Player


## Starts a scene in [param world]: the player stands still and saving waits.
static func begin(world: Node3D) -> Cutscene:
	var scene: Cutscene = Cutscene.new()
	scene.name = "Cutscene"
	world.add_child(scene)
	scene._start()
	return scene


func _start() -> void:
	GameState.block_saving(SAVE_BLOCK)
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.velocity = Vector3.ZERO
		_player.process_mode = Node.PROCESS_MODE_DISABLED
	_camera = Camera3D.new()
	_camera.fov = 60.0
	add_child(_camera)
	_camera.make_current()


## Puts the camera at [param from], looking at [param at]. A wall or pillar
## in between pulls the camera in front of it, so the shot is never blocked.
func look(from: Vector3, at: Vector3) -> void:
	_camera.global_position = _clear_spot(from, at)
	_camera.look_at(at)


## Glides the camera to [param from] over [param seconds], looking at [param at].
func glide(from: Vector3, at: Vector3, seconds: float) -> void:
	var start: Vector3 = _camera.global_position
	var time: float = 0.0
	while time < seconds:
		time += get_physics_process_delta_time()
		_camera.global_position = _clear_spot(start.lerp(from, smoothstep(0.0, 1.0, time / seconds)), at)
		_camera.look_at(at)
		await get_tree().physics_frame


## Shows a line from [param speaker] and waits until it was read.
func say(speaker: String, text: String, seconds: float = 2.6) -> void:
	EventBus.subtitle_requested.emit(speaker, text, seconds)
	await wait(seconds)


## [param from], or the nearest spot towards [param at] that is in front of
## any world geometry between the two.
func _clear_spot(from: Vector3, at: Vector3) -> Vector3:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(at, from, PhysicsLayers.WORLD)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return from
	var spot: Vector3 = hit["position"] as Vector3
	return spot + (at - spot).normalized() * WALL_GAP


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Gives the camera back to the player and lets them move and save again.
func finish() -> void:
	if _player != null:
		_player.process_mode = Node.PROCESS_MODE_INHERIT
		_player.camera.camera.make_current()
	GameState.unblock_saving(SAVE_BLOCK)
	queue_free()
