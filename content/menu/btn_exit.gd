extends Button # Ubah menjadi 'extends TextureButton' jika kamu memakai gambar custom

func _ready() -> void:
	# Menyambungkan sinyal 'pressed' secara otomatis melalui kode
	# (Jadi kamu tidak perlu repot menyambungkannya manual di panel tab Node)
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Perintah bawaan Godot untuk menutup aplikasi/game
	get_tree().quit()
