extends Node
## Music per situation and one-shot sound effects. All sounds are our own
## (tools/audio/gen_audio.py).
##
## Music, checked twice a second, crossfading between tracks:
## - a boss fight: boss;
## - the credits, and the party on the church square once Elst is saved: ending;
## - inside a dungeon: dungeon;
## - in Elst inside a location that is still occupied (the station before its
##   generators, a faction before its boss, the church before Amber): occupied;
## - everywhere else, and in the main menu: village.
## Near the tornado its wind blows, louder closer to the ring.
##
## Sounds: play_sfx() for a sound everywhere (the player, the menus),
## play_sfx_at() for a sound at a place in the world (it fades with distance).

const MUSIC_DIR: String = "res://assets/audio/music/"
const SFX_DIR: String = "res://assets/audio/sfx/"
const FADE_TIME: float = 1.6
const CHECK_INTERVAL: float = 0.5
const VOICES: int = 12
## Music volume in dB, below the effects.
const MUSIC_DB: float = -9.0
## Location id and the flag that frees it, for the occupied music.
const FREED_BY: Dictionary = {
	&"station": &"station_cleared", &"westeraam": &"boss_vape_koning", &"obc_fort": &"boss_fatbike_kindje",
	&"bingo_club": &"boss_grumpy_oma", &"kerk": &"boss_amber",
}
## Wind of the tornado: from this distance to the middle of Elst it starts.
const WIND_FROM: float = 150.0
const WIND_TO: float = 225.0

## The track playing now, for tests.
var current_track: StringName = &""
var _music: Array[AudioStreamPlayer] = []
var _active: int = 0
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _streams: Dictionary = {}
var _wind: AudioStreamPlayer
var _boss: bool = false
var _credits: bool = false
var _check_wait: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = -80.0
		add_child(player)
		_music.append(player)
	for i: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		_voices.append(voice)
	_wind = AudioStreamPlayer.new()
	_wind.bus = &"SFX"
	_wind.volume_db = -80.0
	add_child(_wind)
	EventBus.boss_started.connect(func(_name: String, _health: int) -> void: _boss = true)
	EventBus.boss_ended.connect(func() -> void: _boss = false)
	EventBus.credits_requested.connect(func() -> void: _credits = true)
	EventBus.player_died.connect(play_sfx.bind(&"player_death"))
	EventBus.player_parried.connect(play_sfx.bind(&"parry"))
	EventBus.quest_completed.connect(func(_id: StringName) -> void: play_sfx(&"quest_done"))
	EventBus.loot_collected.connect(_on_loot_collected)


## Plays the sound [param sound_name] everywhere (not at a place).
## [param pitch] shifts the whole sound, such as the voice of a speaker.
func play_sfx(sound_name: StringName, volume_db: float = 0.0, pitch_spread: float = 0.08, pitch: float = 1.0) -> void:
	var stream: AudioStream = _sfx(sound_name)
	if stream == null:
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch * randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	voice.play()


## Plays the sound [param sound_name] at [param position] in the world of
## [param near]: it is quieter further away from the camera.
func play_sfx_at(sound_name: StringName, position: Vector3, near: Node, volume_db: float = 0.0, pitch_spread: float = 0.08) -> void:
	var stream: AudioStream = _sfx(sound_name)
	if stream == null or near == null or not near.is_inside_tree():
		return
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.unit_size = 10.0
	player.max_distance = 80.0
	player.pitch_scale = randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	player.finished.connect(player.queue_free)
	# Into the world itself, where the listener (the camera) is.
	var world: GameWorld = _current_world()
	(world if world != null else near).add_child(player)
	player.global_position = position
	player.play()


## Switches the music to [param track] with a crossfade.
func play_music(track: StringName) -> void:
	if track == current_track:
		return
	current_track = track
	var stream: AudioStream = load(MUSIC_DIR + String(track) + ".ogg") as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var old: AudioStreamPlayer = _music[_active]
	_active = 1 - _active
	var new: AudioStreamPlayer = _music[_active]
	new.stream = stream
	new.volume_db = -40.0
	new.play()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(new, "volume_db", MUSIC_DB, FADE_TIME)
	tween.tween_property(old, "volume_db", -80.0, FADE_TIME)
	tween.chain().tween_callback(old.stop)


func _process(delta: float) -> void:
	_check_wait -= delta
	if _check_wait > 0.0:
		return
	_check_wait = CHECK_INTERVAL
	if _credits and not get_tree().paused:
		_credits = false
	play_music(_pick_track())
	_update_wind()


func _pick_track() -> StringName:
	if _boss:
		return &"boss"
	if _credits:
		return &"ending"
	var world: GameWorld = _current_world()
	if world == null:
		return &"village"
	if world.autosave_on_enter:
		return &"dungeon"
	if not GameState.current_location.is_empty():
		var area: Area3D = _area_at_player(world)
		if area != null:
			var id: StringName = area.get(&"id")
			if id == &"kerk" and GameState.has_flag(&"elst_saved"):
				return &"ending"
			if FREED_BY.has(id) and not GameState.has_flag(FREED_BY[id]):
				return &"occupied"
	return &"village"


## The LocationArea the player stands in, or null.
func _area_at_player(world: GameWorld) -> Area3D:
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null:
		return null
	for area: Node in world.find_children("LocationArea", "Area3D", true, false):
		if (area as Area3D).overlaps_body(player):
			return area as Area3D
	return null


func _update_wind() -> void:
	var world: GameWorld = _current_world()
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	var loud: float = 0.0
	if world != null and player != null and not GameState.has_flag(&"tornado_gone") and world.find_child("Tornado", false, false) != null:
		var distance: float = Vector2(player.global_position.x, player.global_position.z).length()
		loud = clampf(inverse_lerp(WIND_FROM, WIND_TO, distance), 0.0, 1.0)
	if loud > 0.0 and not _wind.playing:
		var stream: AudioStream = _sfx(&"tornado_wind")
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_wind.stream = stream
		_wind.play()
	_wind.volume_db = lerpf(-40.0, -4.0, loud) if loud > 0.0 else -80.0
	if loud <= 0.0 and _wind.playing:
		_wind.stop()


func _current_world() -> GameWorld:
	var main: Node = get_tree().root.get_node_or_null(^"Main")
	if main == null or not main.has_method(&"get_world"):
		return null
	return main.call(&"get_world") as GameWorld


func _sfx(sound_name: StringName) -> AudioStream:
	if not _streams.has(sound_name):
		var path: String = SFX_DIR + String(sound_name) + ".ogg"
		_streams[sound_name] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[sound_name] as AudioStream


## Lets go of every sound when the game closes.
func _exit_tree() -> void:
	for player: AudioStreamPlayer in _music + _voices + [_wind]:
		player.stop()
		player.stream = null
	_streams.clear()


func _on_loot_collected(text: String) -> void:
	play_sfx(&"coin" if text.contains("goud") else &"pickup", -3.0)
