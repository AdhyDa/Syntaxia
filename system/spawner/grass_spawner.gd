extends Node2D
class_name GrassSpawner


## Scene rumput yang akan di-spawn
@export var grass_scene: PackedScene = preload("res://content/collectible/bahan/grass.tscn")

## Durasi cooldown sebelum memunculkan rumput baru (detik)
@export var cooldown_seconds: float = 15.0

## Rasio jumlah rumput aktif terhadap total Marker2D (default: 0.8 = 80%)
@export_range(0.1, 1.0) var spawn_ratio: float = 0.5

## Peluang respawn di titik Marker2D yang sama persis (default: 0.1 = 10%)
@export_range(0.0, 1.0) var same_spot_chance: float = 0.1

## Margin tambahan (pixel) di luar layar kamera untuk memastikan titik benar-benar tak terlihat
@export var screen_margin_buffer: float = 40.0

## Kumpulan semua Marker2D titik spawn
var markers: Array[Marker2D] = []

## Menyimpan rumput yang sedang aktif per Marker2D: { marker: grass_instance }
var active_grass_map: Dictionary = {}

var target_grass_count: int = 0


func _ready() -> void:
	# Jalankan setelah seluruh node di scene tree siap
	call_deferred("_initialize_spawner")


func _initialize_spawner() -> void:
	_collect_markers()
	
	if markers.is_empty():
		push_warning("GrassSpawner: Tidak ada Marker2D yang ditemukan di bawah GrassSpawner!")
		return
		
	# Hitung 80% dari total Marker2D yang ada
	target_grass_count = clampi(roundi(markers.size() * spawn_ratio), 1, markers.size())
	
	# Acak urutan marker untuk spawn awal
	var shuffled_markers = markers.duplicate()
	shuffled_markers.shuffle()
	
	# Spawn rumput awal sejumlah target 80%
	for i in range(target_grass_count):
		_spawn_grass_at_marker(shuffled_markers[i])


## Mengumpulkan semua node Marker2D yang ada di dalam spawner
func _collect_markers() -> void:
	markers.clear()
	for child in get_children():
		if child is Marker2D:
			markers.append(child)
		elif child.name == "Markers" or child is Node2D:
			for sub_child in child.get_children():
				if sub_child is Marker2D:
					markers.append(sub_child)


## Memunculkan 1 instance rumput pada Marker2D tertentu
func _spawn_grass_at_marker(marker: Marker2D) -> void:
	if not marker or not is_instance_valid(marker):
		return
	if _is_marker_occupied(marker):
		return
		
	var grass = grass_scene.instantiate() as Grass
	grass.origin_marker = marker
	grass.spawner = self
	
	# Bersihkan mapping saat rumput dihapus dari scene tree
	grass.tree_exited.connect(func():
		if active_grass_map.get(marker) == grass:
			active_grass_map.erase(marker)
	)
	
	active_grass_map[marker] = grass
	add_child(grass)
	grass.global_position = marker.global_position


## Dipanggil saat siklus item rumput selesai (baik diambil player atau waktu 30s habis)
func on_grass_cycle_completed(origin_marker: Marker2D) -> void:
	# Cooldown 15 detik sebelum memunculkan rumput pengganti
	await get_tree().create_timer(cooldown_seconds).timeout
	_respawn_one_grass(origin_marker)


## Logika pemilihan titik respawn rumput baru
func _respawn_one_grass(origin_marker: Marker2D) -> void:
	# Pastikan tidak melebihi kuota 80%
	if get_active_count() >= target_grass_count:
		return
		
	# Cek peluang 10% untuk respawn di titik yang sama
	if origin_marker and is_instance_valid(origin_marker):
		if randf() <= same_spot_chance:
			# Syarat: Titik harus di luar pandangan kamera dan sedang kosong
			if not _is_position_visible_by_camera(origin_marker.global_position) and not _is_marker_occupied(origin_marker):
				_spawn_grass_at_marker(origin_marker)
				return
				
	# Jika tidak lolos 10% atau titik asal sedang terlihat kamera,
	# cari semua Marker2D kosong yang berada DI LUAR pandangan kamera
	var candidates: Array[Marker2D] = []
	for m in markers:
		if not _is_marker_occupied(m) and not _is_position_visible_by_camera(m.global_position):
			candidates.append(m)
			
	if not candidates.is_empty():
		var chosen = candidates.pick_random()
		_spawn_grass_at_marker(chosen)
	else:
		# Jika seluruh kandidat sedang terlihat kamera (player melihat semua area),
		# tunda 2 detik lalu coba lagi secara rekursif sampai pemain bergerak
		await get_tree().create_timer(2.0).timeout
		_respawn_one_grass(origin_marker)


## Mengecek apakah sebuah Marker2D sedang ditempati rumput aktif
func _is_marker_occupied(marker: Marker2D) -> bool:
	return active_grass_map.has(marker) and is_instance_valid(active_grass_map[marker])


## Mengambil jumlah rumput aktif saat ini
func get_active_count() -> int:
	var count = 0
	for m in active_grass_map:
		if is_instance_valid(active_grass_map[m]):
			count += 1
	return count


## Mengecek apakah suatu posisi di dunia sedang terlihat di layar kamera pemain
func _is_position_visible_by_camera(world_pos: Vector2) -> bool:
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.is_empty():
		return false
		
	var cam = cameras[0] as Camera2D
	if not cam or not is_instance_valid(cam):
		return false
		
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	if "grid_size" in cam:
		view_size = cam.grid_size
	elif cam.zoom != Vector2.ZERO:
		view_size = view_size / cam.zoom
		
	var cam_center: Vector2 = cam.global_position
	var half_size: Vector2 = (view_size / 2.0) + Vector2(screen_margin_buffer, screen_margin_buffer)
	var screen_rect = Rect2(cam_center - half_size, half_size * 2.0)
	
	return screen_rect.has_point(world_pos)
