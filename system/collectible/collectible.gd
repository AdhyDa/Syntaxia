@icon("../collectible/icon_collectible.png")
extends Area2D
class_name Collectible


## Data item: id, nama tampilan, ikon.
@export var resource: ResourceCollectible

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	# Layer 5 = Player (sesuai project.godot layer_names)
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(5, true)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Hanya proses jika body adalah player
	if not body.is_in_group("player"):
		return
	# Validasi resource ada
	if not resource or resource.item_id.is_empty():
		push_warning("Collectible: resource atau item_id kosong!")
		return
	# Coba tambahkan ke inventory.
	# Jika sudah ada (max stack 1), item dilewati begitu saja.
	if not PlayerInventory.add_item(resource.item_id):
		return
	_collect_fx()


func _collect_fx() -> void:
	# Nonaktifkan collision segera agar tidak bisa di-pick up dobel
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	# Efek scale pop lalu menyusut ke nol
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished
	queue_free()
