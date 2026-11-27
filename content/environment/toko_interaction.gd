extends Sprite2D

## TokoInteraction
## Mengelola interaksi belanja dengan Toko Mpok Sintaks

const SHOP_UI_SCENE: PackedScene = preload("res://system/ui/shop_ui.tscn")
const UI_FONT: Font = preload("res://content/menu/aset_menu/ThaleahFat.ttf")

var player_in_range: bool = false
var prompt_label: Label = null
var active_shop: Control = null


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
	# 1. Buat Area2D pendeteksi player di sekitar toko
	var area: Area2D = Area2D.new()
	area.name = "TokoInteractionArea"
	area.collision_layer = 0
	area.collision_mask = 0
	area.set_collision_mask_value(2, true)
	area.set_collision_mask_value(5, true)
	
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	# Ukuran proporsional dengan skala Toko (scale = ~0.534, offset = (0, -75))
	shape.size = Vector2(210.0, 190.0)
	col.shape = shape
	col.position = Vector2(0, -35)
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	# 2. Buat Prompt Label melayang di atas Toko
	prompt_label = Label.new()
	prompt_label.text = "[E] Toko Mpok Sintaks"
	prompt_label.add_theme_font_override("font", UI_FONT)

	#Gunakan ukuran font kelipatan pixel-art (misal 16 atau 24) agar huruf tidak gepeng
	prompt_label.add_theme_font_size_override("font_size", 16) 

	#Warna teks & outline yang proporsional
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prompt_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 1))
	prompt_label.add_theme_constant_override("outline_size", 3)

	#Kecilkan skala node jika ukuran 16 terasa terlalu besar di dunia game
	prompt_label.scale = Vector2(0.5, 0.5)

	#Pastikan filter tekstur font tajam (Nearest) & berada di layer paling atas
	prompt_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prompt_label.z_index = 10

	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Kompensasi skala Toko agar teks label tampil proporsional dan tajam
	var inv_sx = 1.0 / scale.x if scale.x != 0 else 1.0
	var inv_sy = 1.0 / scale.y if scale.y != 0 else 1.0
	prompt_label.scale = Vector2(inv_sx, inv_sy)
	prompt_label.size = Vector2(160, 24)
	prompt_label.position = Vector2(-80 * inv_sx, -180)
	prompt_label.visible = false
	prompt_label.z_index = 10
	add_child(prompt_label)


func _is_player(body: Node2D) -> bool:
	if body.name.to_lower().contains("book") or body.name.to_lower().contains("robot"):
		return false
	return body.is_in_group("player") or body.name.to_lower().contains("ninja") or body.name.to_lower().contains("player") or (body is CharacterBody2D and not body.name.to_lower().contains("npc"))


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
		if active_shop and is_instance_valid(active_shop):
			return
			
		open_shop()
		get_viewport().set_input_as_handled()


func open_shop() -> void:
	# Freeze player
	_freeze_player(true)
	
	var hud_layer = get_tree().get_first_node_in_group("hud")
	if not hud_layer:
		hud_layer = get_tree().current_scene.find_child("Hud", true, false)
		
	active_shop = SHOP_UI_SCENE.instantiate()
	active_shop.shop_closed.connect(_on_shop_closed)
	
	if hud_layer:
		hud_layer.add_child(active_shop)
	else:
		get_tree().current_scene.add_child(active_shop)


func _on_shop_closed() -> void:
	_freeze_player(false)
	active_shop = null
