@icon("../map/icon_map.png")
extends Node2D
class_name Map

@onready var screen_grid_ref: TextureRect = $ScreenGridRef
@onready var environment_area: EnvironmentArea = %EnvironmentArea
@onready var tilemap: TileMap = $Tilemap

var path_grid: AStarGrid2D


func _ready() -> void:
	screen_grid_ref.visible = false
	_build_path_grid()


func _build_path_grid() -> void:
	if not tilemap or not tilemap.tile_set:
		return
	var used_rect := tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	path_grid = AStarGrid2D.new()
	path_grid.region = used_rect
	path_grid.cell_size = Vector2(tilemap.tile_set.tile_size)
	path_grid.offset = path_grid.cell_size * 0.5
	path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	path_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	path_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	path_grid.update()

	# Mark tilemap collision cells (Wall & Wall2 layers) as solid
	for layer_idx in [0, 1]:
		if layer_idx >= tilemap.get_layers_count():
			continue
		for cell in tilemap.get_used_cells(layer_idx):
			if not used_rect.has_point(cell):
				continue
			var tile_data := tilemap.get_cell_tile_data(layer_idx, cell)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				path_grid.set_point_solid(cell, true)

	# Mark StaticBody2D obstacles under Tilemap (e.g. Toko) as solid
	for child in tilemap.get_children():
		_mark_static_obstacles(child, used_rect)


func _mark_static_obstacles(node: Node, used_rect: Rect2i) -> void:
	if node is StaticBody2D and (node.collision_layer & 1) != 0:
		for sub in node.get_children():
			if sub is CollisionShape2D and not sub.disabled and sub.shape is RectangleShape2D:
				var rect_shape := sub.shape as RectangleShape2D
				var half := rect_shape.size * 0.5
				var tl := tilemap.local_to_map(tilemap.to_local(sub.to_global(-half)))
				var br := tilemap.local_to_map(tilemap.to_local(sub.to_global(half)))
				for x in range(mini(tl.x, br.x), maxi(tl.x, br.x) + 1):
					for y in range(mini(tl.y, br.y), maxi(tl.y, br.y) + 1):
						var c := Vector2i(x, y)
						if used_rect.has_point(c):
							path_grid.set_point_solid(c, true)
		return
	for sub in node.get_children():
		if not (sub is CharacterBody2D):
			_mark_static_obstacles(sub, used_rect)


func _clamp_to_region(cell: Vector2i) -> Vector2i:
	var r := path_grid.region
	return Vector2i(
		clampi(cell.x, r.position.x, r.end.x - 1),
		clampi(cell.y, r.position.y, r.end.y - 1)
	)


func _nearest_walkable_cell(cell: Vector2i, max_radius: int = 4) -> Vector2i:
	var clamped := _clamp_to_region(cell)
	if not path_grid.is_point_solid(clamped):
		return clamped
	for radius in range(1, max_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := clamped + Vector2i(dx, dy)
				if path_grid.region.has_point(candidate) and not path_grid.is_point_solid(candidate):
					return candidate
	return clamped


func find_path(from_global: Vector2, to_global: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not path_grid or not tilemap:
		return result
	var from_cell := _nearest_walkable_cell(tilemap.local_to_map(tilemap.to_local(from_global)))
	var to_cell := _nearest_walkable_cell(tilemap.local_to_map(tilemap.to_local(to_global)))
	var local_path := path_grid.get_point_path(from_cell, to_cell)
	for pt in local_path:
		result.append(tilemap.to_global(pt))
	return result


func get_safe_point_near(target_global: Vector2, min_radius_cells: int = 1, max_radius_cells: int = 3) -> Vector2:
	if not path_grid or not tilemap:
		return target_global
	var center := _clamp_to_region(tilemap.local_to_map(tilemap.to_local(target_global)))
	for radius in range(min_radius_cells, max_radius_cells + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := center + Vector2i(dx, dy)
				if path_grid.region.has_point(candidate) and not path_grid.is_point_solid(candidate):
					var local_pt := tilemap.map_to_local(candidate)
					return tilemap.to_global(local_pt)
	return tilemap.to_global(tilemap.map_to_local(_nearest_walkable_cell(center)))
