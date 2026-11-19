class_name StaminaComponent
extends Node
## Stamina that drains on use and refills after a short pause.

signal stamina_changed(current: float, maximum: float)
## Emitted when something needed more stamina than there was.
signal insufficient

@export var max_stamina: float = 100.0
@export var regen_per_second: float = 30.0
## Seconds after the last use before stamina starts to refill.
@export var regen_delay: float = 1.0

var current_stamina: float = 0.0

var _regen_wait: float = 0.0


func _ready() -> void:
	current_stamina = max_stamina


func _physics_process(delta: float) -> void:
	if _regen_wait > 0.0:
		_regen_wait -= delta
		return
	if current_stamina < max_stamina:
		current_stamina = minf(current_stamina + regen_per_second * delta, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)


## Spends [param amount] if there is enough. Otherwise emits insufficient.
func try_spend(amount: float) -> bool:
	if current_stamina < amount:
		insufficient.emit()
		return false
	_use(amount)
	return true


## Drains stamina for something continuous, such as sprinting.
func drain(amount: float) -> void:
	_use(minf(amount, current_stamina))


func is_empty() -> bool:
	return current_stamina <= 0.0


## Applies new values and fills up.
func reset(new_max: float, new_regen_per_second: float, new_regen_delay: float) -> void:
	max_stamina = new_max
	regen_per_second = new_regen_per_second
	regen_delay = new_regen_delay
	refill()


func refill() -> void:
	current_stamina = max_stamina
	_regen_wait = 0.0
	stamina_changed.emit(current_stamina, max_stamina)


func _use(amount: float) -> void:
	current_stamina -= amount
	_regen_wait = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)
