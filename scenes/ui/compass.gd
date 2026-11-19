class_name Compass
extends Control
## Compass strip at the top of the screen. Shows the directions around where
## the camera looks, and a gold marker with the distance to the target of the
## tracked quest. North is -Z in the world.

## Degrees of heading the strip shows from edge to edge.
const VIEW_DEGREES: float = 180.0
const POINTS: Dictionary = {0: "N", 45: "NO", 90: "O", 135: "ZO", 180: "Z", 225: "ZW", 270: "W", 315: "NW"}
const MARKER_COLOR: Color = Color(1, 0.78, 0.3)
const TEXT_COLOR: Color = Color(0.96, 0.9, 0.78)

var _heading: float = 0.0
var _has_target: bool = false
var _target_heading: float = 0.0
var _target_distance: float = 0.0


func _process(_delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player") as Player
	visible = player != null
	if player == null:
		return
	_heading = wrapf(-rad_to_deg(player.camera.yaw), 0.0, 360.0)
	var target: Node3D = _find_target(player)
	_has_target = target != null
	if _has_target:
		var offset: Vector3 = target.global_position - player.global_position
		_target_heading = wrapf(rad_to_deg(atan2(offset.x, -offset.z)), 0.0, 360.0)
		_target_distance = Vector2(offset.x, offset.z).length()
	queue_redraw()


## True when the compass shows a quest marker, for tests.
func has_target() -> bool:
	return _has_target


func _find_target(player: Player) -> Node3D:
	var quest: QuestData = QuestManager.get_tracked_quest()
	if quest == null:
		return null
	var step: QuestStep = QuestManager.get_current_step(quest.id)
	if step == null or step.target.is_empty():
		return null
	var node: Node = player.get_parent()
	while node != null and not node is GameWorld:
		node = node.get_parent()
	return (node as GameWorld).find_quest_marker(step.target) if node != null else null


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.05, 0.04, 0.06, 0.6))
	draw_rect(rect, Color(0.72, 0.45, 0.18, 0.9), false, 2.0)
	var font: Font = get_theme_default_font()
	for degrees: int in range(0, 360, 15):
		var x: float = _x_for(degrees)
		if x < 4.0 or x > size.x - 4.0:
			continue
		if POINTS.has(degrees):
			var text: String = POINTS[degrees]
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			draw_string(font, Vector2(x - width * 0.5, size.y * 0.5 + 7.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, TEXT_COLOR)
		else:
			draw_line(Vector2(x, size.y * 0.35), Vector2(x, size.y * 0.65), Color(TEXT_COLOR, 0.5), 1.0)
	draw_line(Vector2(size.x * 0.5, 0.0), Vector2(size.x * 0.5, 6.0), MARKER_COLOR, 2.0)
	if _has_target:
		var x: float = clampf(_x_for(_target_heading), 10.0, size.x - 10.0)
		var y: float = size.y - 6.0
		var diamond: PackedVector2Array = [Vector2(x, y - 9.0), Vector2(x + 7.0, y - 2.0), Vector2(x, y + 5.0), Vector2(x - 7.0, y - 2.0)]
		draw_colored_polygon(diamond, MARKER_COLOR)
		var label: String = "%d m" % roundi(_target_distance)
		var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(x - width * 0.5, size.y + 16.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MARKER_COLOR)


func _x_for(degrees: float) -> float:
	var relative: float = wrapf(degrees - _heading, -180.0, 180.0)
	return size.x * 0.5 + relative / (VIEW_DEGREES * 0.5) * size.x * 0.5
