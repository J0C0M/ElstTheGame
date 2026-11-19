extends PlayerState
## Drinking a healing potion: a short moment of walking slowly. The potion
## is only used up if the drinking is not cut short by a hit.

var _potion: ItemData
var _time: float = 0.0
var _healed: bool = false


func enter(data: Dictionary) -> void:
	_potion = data["potion"]
	_time = 0.0
	_healed = false
	player.model.play_action(&"drink", player.stats.potion_drink_time)


func physics_update(delta: float) -> void:
	var stats: PlayerStats = player.stats
	player.move_horizontally(player.get_move_direction(), stats.potion_move_speed, stats.acceleration, delta)
	_time += delta
	if not _healed and _time >= stats.potion_drink_time * 0.75:
		_healed = true
		if GameState.remove_item(_potion.id):
			player.health.heal(_potion.heal_amount)
			EventBus.loot_collected.emit("+%d HP" % _potion.heal_amount)
			EventBus.player_action.emit(&"drink")
	if _time >= stats.potion_drink_time:
		state_machine.transition_to(&"Move")
