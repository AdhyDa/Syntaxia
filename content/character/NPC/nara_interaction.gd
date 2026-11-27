extends Node2D

## NaraInteraction
## Mengelola interaksi berbicara dengan NPC Nara

const NARA_DIALOG_SCENE = preload("res://content/character/NPC/nara_dialog_ui.tscn")
const UI_FONT = preload("res://content/menu/aset_menu/ThaleahFat.ttf")

@onready var parent_npc: CharacterBody2D = get_parent() as CharacterBody2D

var player_in_range: bool = false
var prompt_label: Label = null
var active_dialog: Control = null
var original_speed: float = 50.0
var _player_controller: HumanController = null


func _freeze_player(freeze: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if "move_vector" in node:
			node.move_vector = Vector2.ZERO
		if "velocity" in node:
			node.velocity = Vector2.ZERO
		for child in node.get_children():
			if child is HumanController or child.name == "HumanController":
				child.active = not freeze


func _ready() -> void:
	# Buat Area2D pendeteksi player
	var area = Area2D.new()
	area.name = "NaraInteractionArea"
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(2, true)
	area.set_collision_mask_value(5, true)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 35.0
	col.shape = shape
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# Buat Prompt Label melayang
	prompt_label = Label.new()
	prompt_label.text = "[E] Nara"
	prompt_label.add_theme_font_override("font", UI_FONT)
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.position = Vector2(-25, -35)
	prompt_label.visible = false
	prompt_label.z_index = 10
	add_child(prompt_label)
	
	if parent_npc and "speed" in parent_npc:
		original_speed = parent_npc.speed


func _is_player(body: Node2D) -> bool:
	# Eksklusi NPC, companion, dan diri sendiri agar tidak memicu deteksi palsu
	var lower_name: String = body.name.to_lower()
	if lower_name.contains("npc") or lower_name.contains("nara") \
	or lower_name.contains("book") or lower_name.contains("robot"):
		return false
	return body.is_in_group("player") \
		or lower_name.contains("ninja") \
		or lower_name.contains("player")


func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if active_dialog and is_instance_valid(active_dialog):
			return
			
		open_nara_dialog()
		get_viewport().set_input_as_handled()


func open_nara_dialog() -> void:
	# Hentikan NPC saat berbicara
	if parent_npc and "speed" in parent_npc:
		original_speed = parent_npc.speed
		parent_npc.speed = 0.0
	
	# Freeze player agar tidak bisa bergerak selama dialog
	_freeze_player(true)
		
	var hud_layer = get_tree().get_first_node_in_group("hud")
	if not hud_layer:
		hud_layer = get_tree().current_scene.find_child("Hud", true, false)
		
	active_dialog = NARA_DIALOG_SCENE.instantiate()
	active_dialog.dialog_closed.connect(_on_dialog_closed)
	
	if hud_layer:
		hud_layer.add_child(active_dialog)
	else:
		get_tree().current_scene.add_child(active_dialog)


func _on_dialog_closed() -> void:
	# Lanjutkan pergerakan NPC setelah dialog ditutup
	if parent_npc and "speed" in parent_npc:
		parent_npc.speed = original_speed
	# Unfreeze player
	_freeze_player(false)
