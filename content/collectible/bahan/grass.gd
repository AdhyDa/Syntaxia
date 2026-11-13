@tool
@icon("res://system/destroyable/icon_destroyable.png")
extends Destroyable
class_name Grass


## ====================================================================
## PENGATURAN TINGKAT KELANGKAAN (DROP RATE)
## Kamu bisa mengubah angka bobot (weight / persentase) di bawah ini
## langsung di script ini atau melalui panel Inspector Godot.
## Semakin besar angkanya, semakin tinggi peluang drop item tersebut.
## Total bobot saat ini = 100.0 (25 + 25 + 15 + 15 + 10 + 5 + 5).
## ====================================================================
@export var drop_rates: Dictionary = {
	"air": 25.0,        # Common (25%)
	"beras": 25.0,      # Common (25%)
	"serai": 15.0,      # Uncommon (15%)
	"gulamerah": 15.0,  # Uncommon (15%)
	"jahe": 10.0,       # Rare (10%)
	"asamjawa": 5.0,    # Very Rare (5%)
	"kencur": 5.0       # Epic / Sangat Langka (5%)
}

## Daftar scene prefab untuk masing-masing bahan
@export var drop_scenes: Dictionary = {
	"air": preload("res://content/collectible/bahan/airbahan.tscn"),
	"beras": preload("res://content/collectible/bahan/berasbahan.tscn"),
	"serai": preload("res://content/collectible/bahan/seraibahan.tscn"),
	"gulamerah": preload("res://content/collectible/bahan/gulamerahbahan.tscn"),
	"jahe": preload("res://content/collectible/bahan/jahebahan.tscn"),
	"asamjawa": preload("res://content/collectible/bahan/asamjawabahan.tscn"),
	"kencur": preload("res://content/collectible/bahan/kencurbahan.tscn"),
}

## Referensi ke Marker2D tempat rumput ini di-spawn
var origin_marker: Marker2D = null

## Referensi ke GrassSpawner pengelola
var spawner: Node = null

var _is_destroyed: bool = false


func _ready() -> void:
	super._ready()
	
	if Engine.is_editor_hint():
		return
		
	# POIN 1: Nonaktifkan damage dari serangan senjata
	# Rumput hanya bisa hancur ketika tubuh player menyentuh collision rumput
	if hitbox:
		hitbox.monitorable = false
		
	_setup_player_touch_detection()


## Menyiapkan area deteksi sentuhan langsung tubuh Player (Layer 5)
func _setup_player_touch_detection() -> void:
	var touch_area = Area2D.new()
	touch_area.name = "PlayerTouchArea"
	touch_area.collision_layer = 0
	touch_area.collision_mask = 0
	# Layer 5 = Player
	touch_area.set_collision_mask_value(5, true)
	
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	col_shape.shape = circle
	touch_area.add_child(col_shape)
	
	add_child(touch_area)
	touch_area.body_entered.connect(_on_player_touched)


func _on_player_touched(body: Node2D) -> void:
	if _is_destroyed:
		return
	if body.is_in_group("player"):
		_is_destroyed = true
		destroy()


## Override take_damage agar senjata TIDAK BISA merusak rumput ini
func take_damage(damage: ResourceDamage, damage_pos = Vector2.ZERO) -> void:
	# Mengabaikan serangan senjata sesuai permintaan Poin 1
	pass


## Menghitung dan memilih 1 item acak berdasarkan Weighted Drop Rate
func get_random_drop_scene() -> PackedScene:
	var total_weight: float = 0.0
	for key in drop_rates:
		total_weight += float(drop_rates[key])
		
	if total_weight <= 0.0:
		return null
		
	var roll: float = randf_range(0.0, total_weight)
	var current_sum: float = 0.0
	
	for key in drop_rates:
		current_sum += float(drop_rates[key])
		if roll <= current_sum:
			return drop_scenes.get(key)
			
	return null


## Memunculkan item drop saat rumput hancur
func spawn_drop() -> void:
	var scene_to_spawn = get_random_drop_scene()
	if not scene_to_spawn:
		# Jika tidak ada item yang di-drop, langsung kabari spawner
		if spawner and spawner.has_method("on_grass_cycle_completed"):
			spawner.on_grass_cycle_completed(origin_marker)
		return
		
	var item = scene_to_spawn.instantiate()
	if item is Collectible:
		item.origin_marker = origin_marker
		# Hubungkan sinyal selesai (baik saat diambil player maupun expired 30s)
		# untuk memicu cooldown 15 detik respawn di spawner
		if spawner and spawner.has_method("on_grass_cycle_completed"):
			item.finished.connect(func(_success: bool):
				spawner.on_grass_cycle_completed(origin_marker)
			)
			
	get_parent().call_deferred("add_child", item)
	item.global_position = global_position
