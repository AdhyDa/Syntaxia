extends Area2D

## Kuali Meja Racik Jamu
## Membuka GrimoireUI saat pemain berinteraksi dengan tombol E

const GRIMOIRE_UI_SCENE = preload("res://system/ui/grimoire_ui.tscn")

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var active_grimoire_instance: Control = null


func _ready() -> void:
	# Pastikan layer deteksi mencakup player
	set_collision_mask_value(2, true)
	set_collision_mask_value(5, true)
	
	# Animasi default
	if anim_sprite:
		anim_sprite.play("kuali_idle")
	
	if prompt_label:
		prompt_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	# Cek apakah body adalah Character/Player
	if body.is_in_group("player") or body is CharacterBody2D or body.name.to_lower().contains("ninja") or body.name.to_lower().contains("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D or body.name.to_lower().contains("ninja") or body.name.to_lower().contains("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		# Jangan buka dobel jika grimoire sudah aktif
		if active_grimoire_instance and is_instance_valid(active_grimoire_instance):
			return
			
		open_grimoire()
		get_viewport().set_input_as_handled()


func open_grimoire() -> void:
	# Cari CanvasLayer HUD di tree atau tempelkan ke root viewport
	var hud_layer = get_tree().get_first_node_in_group("hud")
	if not hud_layer:
		# Cari node bernama "Hud"
		hud_layer = get_tree().current_scene.find_child("Hud", true, false)
	
	active_grimoire_instance = GRIMOIRE_UI_SCENE.instantiate()
	active_grimoire_instance.brewing_finished.connect(_on_brewing_finished)
	
	if hud_layer:
		hud_layer.add_child(active_grimoire_instance)
	else:
		get_tree().current_scene.add_child(active_grimoire_instance)


func _on_brewing_finished(success: bool) -> void:
	if success and anim_sprite:
		anim_sprite.play("kuali_proses")
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(anim_sprite):
				anim_sprite.play("kuali_idle")
		)
