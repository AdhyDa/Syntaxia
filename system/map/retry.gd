extends Control

func retry_game() -> void:
	# Memuat ulang scene yang sedang aktif
	get_tree().reload_current_scene()
