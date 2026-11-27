extends Button # Ubah ke TextureButton jika menggunakan gambar

func _ready() -> void:
	# Menghubungkan klik tombol ke fungsi secara otomatis lewat kode
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Memanggil AboutPanel menggunakan % dan menampilkannya
	get_node("%AboutPanel").show()
