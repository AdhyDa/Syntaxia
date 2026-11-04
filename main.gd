extends Node


enum StartingScene {TITLE_SCREEN,GAME}

@export var starting_menu:StartingScene = StartingScene.TITLE_SCREEN

var current_scene:Node


func _ready() -> void:
	match starting_menu:
		StartingScene.TITLE_SCREEN:
			launch_scene(load("res://content/menu/title_screen.tscn"))
		StartingScene.GAME:
			launch_scene(load("res://world.tscn"))
		


func launch_scene(packed_scene:PackedScene):
	if current_scene:
		current_scene.queue_free()
	current_scene = packed_scene.instantiate()
	add_child(current_scene)

func play_fade_in_transition() -> void:
	# Membuat CanvasLayer dan ColorRect secara dinamis lewat kode
	var canvas_layer = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	
	fade_rect.color = Color(0, 0, 0, 1.0) # Mulai dari hitam pekat
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Memenuhi layar
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Agar bisa diklik
	
	# Memasukkan kotak hitam ke dalam canvas, lalu ke layar utama
	canvas_layer.add_child(fade_rect)
	add_child(canvas_layer)
	
	# Membuat animasi memudarkan warna hitam selama 0.5 detik
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0.0), 0.5)
	
	# Menghapus lapisan transisi dari memori setelah animasi selesai
	tween.finished.connect(func(): canvas_layer.queue_free())
