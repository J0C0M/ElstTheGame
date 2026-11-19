class_name Generator
extends StaticBody3D
## A generator in a dungeon that the player smashes with the sword. Once
## broken it stays broken: a GameState flag remembers it across saves. A
## broken generator goes dark, leans over and gives off a puff of smoke.

## Emitted once when the generator breaks, not when it loads broken.
signal broken

## Health and name of the generator.
@export var data: EnemyData
## GameState flag that remembers this generator is broken.
@export var flag: StringName
## Target id for the quest compass while the generator still runs.
@export var marker_id: StringName = &"generator"

const BROKEN_COLOR: Color = Color(0.12, 0.11, 0.1)

var _shake: float = 0.0

@onready var _health: HealthComponent = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _health_bar: HealthBar3D = $HealthBar
@onready var _model: Node3D = $Model
@onready var _core: MeshInstance3D = $Model/Core
@onready var _light: OmniLight3D = $Light
@onready var _marker: QuestMarker = $QuestMarker
@onready var _smoke: CPUParticles3D = $Smoke


func _ready() -> void:
	_marker.ids = [marker_id] as Array[StringName]
	_health.reset(data.get_max_health())
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_health_bar.visible = false
	if is_broken():
		_set_broken()


func is_broken() -> bool:
	return GameState.has_flag(flag)


func _physics_process(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake = maxf(_shake - delta * 4.0, 0.0)
	_model.position.x = sin(_shake * 50.0) * 0.06 * _shake


func _on_hit_received(hit: HitData) -> void:
	if is_broken():
		return
	_health.take_damage(hit.damage)
	_shake = 1.0


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.visible = current < maximum and current > 0
	_health_bar.set_ratio(float(current) / maximum)


func _on_died() -> void:
	GameState.set_flag(flag)
	_set_broken()
	_smoke.emitting = true
	broken.emit()


func _set_broken() -> void:
	_health_bar.visible = false
	_hurtbox.set_deferred(&"monitorable", false)
	_light.visible = false
	var dark: StandardMaterial3D = StandardMaterial3D.new()
	dark.albedo_color = BROKEN_COLOR
	_core.material_override = dark
	_model.position.x = 0.0
	_model.rotation = Vector3(0.0, 0.0, 0.14)
	if _marker != null:
		_marker.queue_free()
		_marker = null
