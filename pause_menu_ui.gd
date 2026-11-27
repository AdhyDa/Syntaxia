extends Control

# 1. Tambahkan referensi tombol pembuka menu & tutorial di HUD
@onready var btn_menu_toggle: Button = $BtnMenuToggle
@onready var btn_tutorial: BaseButton = $"../BtnTutorial"
@onready var tutorial_ui: Control = $"../TutorialUI"

# Referensi overlay dan tombol internal pause
@onready var pause_overlay: ColorRect = $PauseOverlay # Atau NinePatchRect jika menggunakan tekstur
@onready var btn_resume: Button = $PauseOverlay/PausePanel/MarginContainer/VBoxContainer/BtnResume
@onready var btn_restart: Button = $PauseOverlay/PausePanel/MarginContainer/VBoxContainer/BtnRetry
@onready var btn_exit: Button = $PauseOverlay/PausePanel/MarginContainer/VBoxContainer/BtnExit

func _ready() -> void:
	pause_overlay.hide()
	
	# Connect tombol MENU & TUTORIAL yang ada di HUD
	btn_menu_toggle.pressed.connect(_on_btn_menu_toggle_pressed)
	if btn_tutorial:
		btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	
	# Connect tombol-tombol di dalam pop-up pause
	btn_resume.pressed.connect(_on_btn_resume_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)

# Membuka/menutup pause via tombol keyboard ESC
func _unhandled_input(event: InputEvent) -> void:
	if tutorial_ui and tutorial_ui.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

# --- FUNGSI UTAMA ---
func _pause_game() -> void:
	pause_overlay.show()
	get_tree().paused = true

func _resume_game() -> void:
	pause_overlay.hide()
	get_tree().paused = false

# --- AKSI TOMBOL ---
# Dipanggil saat tombol MENU di HUD diklik
func _on_btn_menu_toggle_pressed() -> void:
	_pause_game()

func _on_btn_tutorial_pressed() -> void:
	if tutorial_ui and tutorial_ui.has_method("open_tutorial"):
		tutorial_ui.open_tutorial()

func _on_btn_resume_pressed() -> void:
	_resume_game()

func _on_btn_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://content/menu/title_screen.tscn")
