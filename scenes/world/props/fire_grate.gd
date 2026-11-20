class_name FireGrate
extends Node3D
## A grate in the floor that spits fire in a steady rhythm: a quiet spell, a
## flicker that warns, then flames that hurt. Time your run between them.

@export var damage: int = 10
@export var quiet_time: float = 2.2
@export var warn_time: float = 0.8
@export var fire_time: float = 1.4
## Seconds into the cycle at the start, so grates in a row take turns.
@export var offset: float = 0.0

const HIT_EVERY: float = 0.5

var _time: float = 0.0
var _hit_wait: float = 0.0

@onready var _flames: Node3D = $Flames
@onready var _glow: Node3D = $Glow
@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	_time = offset
	_flames.visible = false


## True while the flames burn.
func is_burning() -> bool:
	return fmod(_time, quiet_time + warn_time + fire_time) >= quiet_time + warn_time


func _physics_process(delta: float) -> void:
	_time += delta
	var phase: float = fmod(_time, quiet_time + warn_time + fire_time)
	var warning: bool = phase >= quiet_time and phase < quiet_time + warn_time
	_glow.visible = is_burning() or (warning and fmod(phase * 8.0, 1.0) < 0.5)
	_flames.visible = is_burning()
	if is_burning():
		_flames.scale.y = 0.8 + 0.3 * sin(_time * 25.0)
		_hit_wait -= delta
		if _hit_wait <= 0.0:
			_hit_wait = HIT_EVERY
			_hitbox.activate(damage)
	elif _hitbox.is_active():
		_hitbox.deactivate()
		_hit_wait = 0.0
