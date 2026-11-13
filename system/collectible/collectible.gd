extends Area2D
class_name Collectible


## Data item: id, nama tampilan, ikon.
@export var resource: ResourceCollectible

## Durasi item bertahan di tanah sebelum menghilang (detik)
@export var lifetime: float = 30.0

## Waktu sebelum hilang untuk memulai efek berkedip (detik)
@export var blink_duration: float = 5.0

## Referensi Marker2D asal spawn (digunakan oleh spawner untuk respawn)
var origin_marker: Marker2D = null

## Sinyal selesai siklus: success = true (diambil player), success = false (waktu habis/despawn)
signal finished(success: bool)

@onready var sprite: Sprite2D = $Sprite

var is_collected: bool = false
var is_expired: bool = false
var can_be_collected: bool = false
var _blink_tween: Tween


func _ready() -> void:
	# Layer 5 = Player
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(5, true)
	body_entered.connect(_on_body_entered)
	
	# Efek melompat/terlempar keluar dan membal jatuh ke tanah
	_spawn_scatter_and_bounce_fx()
	
	# Memulai siklus waktu hidup 30 detik
	_start_lifetime_timer()


## Efek lemparan arc dan bounce saat item jatuh ke tanah (agar tidak langsung terambil)
func _spawn_scatter_and_bounce_fx() -> void:
	can_be_collected = false
	
	# Tentukan titik pendaratan acak di sekitar posisi spawn (jarak 16 - 24 pixel)
	var random_angle: float = randf_range(0.0, TAU)
	var scatter_dist: float = randf_range(16.0, 24.0)
	var target_pos: Vector2 = global_position + Vector2(cos(random_angle), sin(random_angle)) * scatter_dist
	
	# Gerak horizontal ke titik target
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:x", target_pos.x, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Gerak vertikal parabola: melompat ke atas lalu membal jatuh ke tanah
	var vert_tween = create_tween()
	vert_tween.tween_property(self, "global_position:y", target_pos.y - 12.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	vert_tween.tween_property(self, "global_position:y", target_pos.y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await vert_tween.finished
	
	# Setelah mendarat di tanah, item baru aktif bisa diambil
	can_be_collected = true
	
	# Pengecekan jika pemain kebetulan sudah berada di titik pendaratan
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_try_collect(body)
			break


func _start_lifetime_timer() -> void:
	var solid_time = max(0.0, lifetime - blink_duration)
	
	# Fase 1: Diam/menunggu normal selama 25 detik
	await get_tree().create_timer(solid_time).timeout
	if is_collected or is_expired or not is_inside_tree():
		return
	
	# Fase 2: 5 detik terakhir berkedip (peringatan item akan hilang)
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.25)
	_blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.25)
	
	await get_tree().create_timer(blink_duration).timeout
	if is_collected or is_expired or not is_inside_tree():
		return
		
	# Fase 3: Waktu 30 detik habis tanpa diambil -> Despawn perlahan
	_expire_and_despawn()


func _on_body_entered(body: Node2D) -> void:
	if not can_be_collected:
		return
	_try_collect(body)


func _try_collect(body: Node2D) -> void:
	if is_collected or is_expired:
		return
		
	# Hanya proses jika body adalah player
	if not body.is_in_group("player"):
		return
		
	if not resource or resource.item_id.is_empty():
		push_warning("Collectible: resource atau item_id kosong!")
		return
		
	# Coba tambahkan ke backend inventory pemain (maksimal 5 buah)
	# Jika inventory sudah penuh (5 buah), add_item me-return false
	# dan item TIDAK diambil (pemain hanya melewatinya)
	if not PlayerInventory.add_item(resource.item_id):
		return
		
	_collect_fx()


func _collect_fx() -> void:
	is_collected = true
	if _blink_tween:
		_blink_tween.kill()
		
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	
	finished.emit(true)
	
	# Efek pop scale lalu menyusut
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	queue_free()


func _expire_and_despawn() -> void:
	is_expired = true
	if _blink_tween:
		_blink_tween.kill()
		
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	
	finished.emit(false)
	
	# Fade out perlahan
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()
