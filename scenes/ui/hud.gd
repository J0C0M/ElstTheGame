extends Control
## Player HUD: health and stamina bars, and short messages for a parry and for
## dying. It listens to the EventBus, so it does not need the player.

const FLASH_COLOR: Color = Color(1.0, 0.4, 0.35)

var _health_tween: Tween
var _flash_tween: Tween
var _parry_tween: Tween
var _message_tween: Tween

@onready var _health_bar: ProgressBar = $Bars/HealthBar
@onready var _stamina_bar: ProgressBar = $Bars/StaminaBar
@onready var _parry_label: Label = $ParryLabel
@onready var _death_label: Label = $DeathLabel
@onready var _prompt_label: Label = $PromptLabel
@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.player_stamina_insufficient.connect(_on_stamina_insufficient)
	EventBus.player_parried.connect(_on_parried)
	EventBus.player_died.connect(_on_died)
	EventBus.player_respawned.connect(_on_respawned)
	EventBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	EventBus.message_requested.connect(_on_message_requested)
	_parry_label.modulate.a = 0.0
	_death_label.visible = false
	_prompt_label.visible = false
	_message_label.modulate.a = 0.0


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	if _health_tween != null:
		_health_tween.kill()
	_health_tween = create_tween()
	_health_tween.tween_property(_health_bar, "value", float(current), 0.2)


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current


func _on_stamina_insufficient() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_stamina_bar.modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_stamina_bar, "modulate", Color.WHITE, 0.4)


func _on_parried() -> void:
	if _parry_tween != null:
		_parry_tween.kill()
	_parry_label.modulate.a = 1.0
	_parry_tween = create_tween()
	_parry_tween.tween_interval(0.4)
	_parry_tween.tween_property(_parry_label, "modulate:a", 0.0, 0.4)


func _on_died() -> void:
	_death_label.visible = true


func _on_respawned() -> void:
	_death_label.visible = false


func _on_interaction_prompt_changed(prompt: String) -> void:
	_prompt_label.text = "[E] " + prompt
	_prompt_label.visible = not prompt.is_empty()


func _on_message_requested(text: String) -> void:
	_message_label.text = text
	if _message_tween != null:
		_message_tween.kill()
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.5)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.6)
