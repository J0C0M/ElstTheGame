class_name CrossbowBolt
extends Node3D
## A crossbow bolt in flight. It flies straight to where the crosshair
## pointed, nose first, with a faint streak behind it. Each physics frame a
## ray checks the stretch it covers, so a fast bolt cannot pass through a
## thin wall or an enemy. It sticks where it lands: in a wall or the floor
## for a while, or in the enemy it hit (and goes with it).

## Metres per second.
@export var speed: float = 48.0
## Seconds before a bolt that hit nothing is gone.
@export var travel_time: float = 1.8
## Seconds a bolt stays stuck in a wall or an enemy.
@export var stick_time: float = 4.0

## How far the head sinks into what it hits.
const SINK: float = 0.12
const FADE_TIME: float = 0.5

var _direction: Vector3 = Vector3.FORWARD
var _damage: int = 0
var _source: Node3D
var _time: float = 0.0
var _stuck_at: float = -1.0
var _excluded: Array[RID] = []

@onready var _hitbox: Hitbox = $Hitbox
@onready var _visual: Node3D = $Visual
@onready var _streak: MeshInstance3D = $Visual/Streak


## Sends the bolt from [param origin] along [param direction] for [param damage].
func launch(origin: Vector3, direction: Vector3, damage: int, source: Node3D) -> void:
	_direction = direction.normalized()
	_damage = damage
	_source = source
	_hitbox.source = source
	if source is CollisionObject3D:
		_excluded = [(source as CollisionObject3D).get_rid()]
	global_position = origin
	if absf(_direction.dot(Vector3.UP)) < 0.99:
		look_at(origin + _direction, Vector3.UP)
	reset_physics_interpolation()


## True once the bolt has hit something and sticks in it.
func is_stuck() -> bool:
	return _stuck_at >= 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	if is_stuck():
		var left: float = stick_time - (_time - _stuck_at)
		if left < FADE_TIME:
			_visual.scale = Vector3.ONE * maxf(left / FADE_TIME, 0.01)
		if left <= 0.0:
			queue_free()
		return
	_streak.visible = _time > 0.03
	var from: Vector3 = global_position
	var to: Vector3 = from + _direction * speed * delta
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	# Enemies first: their hurtboxes are areas.
	var enemy_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.ENEMY, _excluded)
	enemy_query.collide_with_areas = true
	enemy_query.collide_with_bodies = false
	var enemy_hit: Dictionary = space.intersect_ray(enemy_query)
	var world_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.WORLD, _excluded))
	var hurtbox: Hurtbox = enemy_hit.get("collider") as Hurtbox
	if hurtbox != null and hurtbox.monitorable and (world_hit.is_empty() or
			from.distance_to(enemy_hit["position"] as Vector3) < from.distance_to(world_hit["position"] as Vector3)):
		_stick(enemy_hit["position"] as Vector3, hurtbox.get_parent() as Node3D)
		hurtbox.receive_hit(HitData.new(_damage, _source, _hitbox))
		return
	if not world_hit.is_empty():
		_stick(world_hit["position"] as Vector3, null)
		return
	global_position = to
	if _time >= travel_time:
		queue_free()


## Stops at [param point], the head sunk in a little; inside [param holder]
## when that is an enemy, so it moves along with it.
func _stick(point: Vector3, holder: Node3D) -> void:
	_stuck_at = _time
	_streak.visible = false
	global_position = point + _direction * SINK
	reset_physics_interpolation()
	if holder != null and is_instance_valid(holder):
		stick_time = minf(stick_time, 2.5)
		# Not during this physics step: the bolt keeps its place in the world.
		reparent.call_deferred(holder)
