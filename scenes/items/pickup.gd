class_name Pickup
extends Area3D
## Something on the ground that the player picks up by walking into it. It
## pops out with launch(), bobs and spins, and drifts to the player when they
## come close. Subclasses decide what collecting does.

const GRAVITY: float = 14.0
const MAGNET_RANGE: float = 3.0
const MAGNET_SPEED: float = 9.0
## Seconds before a pickup that did not fit is tried again.
const RETRY_WAIT: float = 4.0

var _velocity: Vector3 = Vector3.ZERO
var _rest_height: float = 0.0
var _landed: bool = true
var _time: float = 0.0
var _retry_wait: float = 0.0

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitorable = false
	_rest_height = global_position.y
	_time = randf() * TAU
	body_entered.connect(_try_collect)


## Throws the pickup up and out. It lands back at the height it starts at.
func launch(launch_velocity: Vector3) -> void:
	_velocity = launch_velocity
	_rest_height = global_position.y
	_landed = false


func _physics_process(delta: float) -> void:
	_time += delta
	_retry_wait = maxf(_retry_wait - delta, 0.0)
	if not _landed:
		_velocity.y -= GRAVITY * delta
		global_position += _velocity * delta
		if global_position.y <= _rest_height and _velocity.y < 0.0:
			global_position.y = _rest_height
			_landed = true
	elif _retry_wait <= 0.0:
		var player: Player = get_tree().get_first_node_in_group(&"player") as Player
		if player != null and not player.health.is_dead():
			var to_player: Vector3 = player.global_position + Vector3.UP * 0.9 - global_position
			if to_player.length() < MAGNET_RANGE:
				global_position += to_player.normalized() * minf(MAGNET_SPEED * delta, to_player.length())
			if overlaps_body(player):
				_try_collect(player)
	_visual.rotation.y = _time * 2.5
	_visual.position.y = 0.25 + sin(_time * 3.0) * 0.08


func _try_collect(body: Node3D) -> void:
	var player: Player = body as Player
	if player == null or _retry_wait > 0.0 or is_queued_for_deletion():
		return
	if _collect(player):
		queue_free()
	else:
		_retry_wait = RETRY_WAIT


## Override: does the pickup's work and returns true when it was taken.
func _collect(_player: Player) -> bool:
	return true
