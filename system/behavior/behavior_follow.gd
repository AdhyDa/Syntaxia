@icon("../behavior/icon_behavior_follow.png")
extends Node2D
class_name BehaviorFollow


## A behavior node which can be add to a character so that it follows 
## a target, with minimum and maximum distance parameters.


@export var active := true:
	set(v):
		active = v
		if Engine.is_editor_hint():
			return
		update_process()
@export var target:Node2D:
	set(v):
		if target and is_instance_valid(target) and target.has_signal("teleported"):
			if target.teleported.is_connected(on_target_teleported):
				target.teleported.disconnect(on_target_teleported)
		target = v
		if !target:
			target_pos = start_pos
		else:
			if target.has_signal("teleported") and not target.teleported.is_connected(on_target_teleported):
				target.teleported.connect(on_target_teleported)
		update_process()
@export var min_dist := 8
@export var max_dist := 24
@export var pathfind_dist := 72.0
@export var catch_up_dist := 110.0
@export var catch_up_speed_multiplier := 1.45
@export var teleport_dist := 450.0
@export var repath_interval := 0.25

var start_pos := Vector2.ZERO
var parent:Node2D
var target_pos
var _base_speed := -1.0
var _map: Map
var _path := PackedVector2Array()
var _path_index := 0
var _repath_timer := 0.0
var _stuck_timer := 0.0
var _last_pos := Vector2.ZERO


func _ready() -> void:
	parent = get_parent()
	start_pos = global_position
	_last_pos = global_position
	if parent and "speed" in parent:
		_base_speed = float(parent.speed)
	_find_map()
	if not target and is_inside_tree():
		var pl = get_tree().get_first_node_in_group("player")
		if pl and pl is Node2D:
			target = pl
	update_process()


func _find_map() -> void:
	var n: Node = parent
	while n:
		if n is Map:
			_map = n
			return
		n = n.get_parent()


func on_target_teleported():
	if parent and target and is_instance_valid(target):
		parent.global_position = _get_teleport_pos(target.global_position)
		_reset_navigation()
		if parent.has_signal("teleported"):
			parent.teleported.emit()


func _get_teleport_pos(goal_pos: Vector2) -> Vector2:
	if _map and is_instance_valid(_map):
		return _map.get_safe_point_near(goal_pos)
	return goal_pos


func _reset_navigation() -> void:
	_path.clear()
	_path_index = 0
	_repath_timer = 0.0
	_stuck_timer = 0.0


func _update_speed(dist: float) -> void:
	if _base_speed <= 0.0 or not parent or not ("speed" in parent):
		return
	if dist > catch_up_dist:
		parent.speed = _base_speed * catch_up_speed_multiplier
	else:
		parent.speed = _base_speed


func _process(delta: float) -> void:
	if target:
		go_to_pos(target.global_position, delta)
	elif target_pos:
		go_to_pos(target_pos, delta)
	else:
		update_process()


func go_to_pos(pos: Vector2, delta: float = 0.0) -> void:
	var dist := global_position.distance_to(pos)
	_update_speed(dist)

	# Safety teleport fallback when extremely far away
	if dist > teleport_dist and parent:
		parent.global_position = _get_teleport_pos(pos)
		if "velocity" in parent:
			parent.velocity = Vector2.ZERO
		parent.move_vector = Vector2.ZERO
		_reset_navigation()
		_last_pos = global_position
		if parent.has_signal("teleported"):
			parent.teleported.emit()
		return

	if dist < min_dist:
		_reset_navigation()
		parent.move_vector = -global_position.direction_to(pos)
		_last_pos = global_position
		return

	if dist <= max_dist:
		target_pos = null
		_reset_navigation()
		parent.move_vector = Vector2.ZERO
		_last_pos = global_position
		return

	# Detect if stuck against an obstacle while trying to move
	if parent.move_vector.length_squared() > 0.01 and global_position.distance_squared_to(_last_pos) < 0.5:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	_last_pos = global_position

	var need_pathfind := (dist > pathfind_dist or _stuck_timer >= 0.25) and _map != null and _map.path_grid != null
	if need_pathfind:
		_repath_timer -= delta
		if _repath_timer <= 0.0 or _path.is_empty():
			_repath_timer = repath_interval
			_path = _map.find_path(global_position, pos)
			_path_index = 0
			# Skip the starting cell center if we are already very close to it
			while _path_index < _path.size() - 1 and global_position.distance_to(_path[_path_index]) < 10.0:
				_path_index += 1

		if _path_index < _path.size():
			var waypoint := _path[_path_index]
			if global_position.distance_to(waypoint) <= 8.0:
				_path_index += 1
			if _path_index < _path.size():
				parent.move_vector = global_position.direction_to(_path[_path_index])
				return

	parent.move_vector = global_position.direction_to(pos)


func update_process():
	if not parent and is_inside_tree():
		parent = get_parent()
	if active and (target != null or target_pos != null):
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_reset_navigation()
		if _base_speed > 0.0 and parent and "speed" in parent:
			parent.speed = _base_speed
		if parent and "move_vector" in parent:
			parent.move_vector = Vector2.ZERO
		process_mode = Node.PROCESS_MODE_DISABLED
