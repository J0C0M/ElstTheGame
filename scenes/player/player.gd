class_name Player
extends CharacterBody3D
## The player. The states under StateMachine decide what happens each physics
## frame; this script holds the stats and shared helpers, applies gravity and
## moves the body.

@export var stats: PlayerStats
@export var sword: ItemData
@export var armor: ItemData

## True while sprinting. Set by the move state, read by the model.
var is_sprinting: bool = false

var _gravity: float = 0.0

@onready var model: PlayerModel = $Model
@onready var camera: PlayerCamera = $Camera
@onready var health: HealthComponent = $Health
@onready var stamina: StaminaComponent = $Stamina
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity")) * stats.gravity_multiplier
	health.health_changed.connect(EventBus.player_health_changed.emit)
	stamina.stamina_changed.connect(EventBus.player_stamina_changed.emit)
	stamina.insufficient.connect(EventBus.player_stamina_insufficient.emit)
	health.reset(stats.max_health)
	stamina.reset(stats.max_stamina, stats.stamina_regen_per_second, stats.stamina_regen_delay)


func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
	model.set_locomotion(Vector2(velocity.x, velocity.z).length(), is_sprinting, is_on_floor())


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


func get_forward() -> Vector3:
	return -global_basis.z
