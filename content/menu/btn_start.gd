extends Button

# Memunculkan kolom di Inspector untuk mengisi jalur scene tujuan
@export_file("*.tscn") var main_scene_path: String
# Memunculkan kolom di Inspector untuk memasukkan node ColorRect
@export var transition_overlay: ColorRect

func _ready() -> void:
	# Mengatur pivot ke tengah untuk animasi hover (opsional, jika masih pakai)
	pivot_offset = size / 2
	
	# Menghubungkan sinyal klik tombol ke fungsi
	pressed.connect(_on_play_pressed)
	
	# (Boleh tambahkan sinyal hover/mouse_entered di sini jika kamu masih memakainya)

func _on_play_pressed() -> void:
	# 1. Cek apakah ColorRect dan scene tujuan sudah diisi di Inspector
	if not transition_overlay or main_scene_path == "":
		print("Peringatan: Transisi atau Scene tujuan belum diatur di Inspector!")
		return
		
	# 2. Buat Tween untuk menganimasikan warna ColorRect
	var tween = create_tween()
	
	# Menganimasikan warna menjadi hitam pekat (Alpha 1.0) selama 0.5 detik
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1.0), 0.5)
	
	# 3. Hentikan eksekusi kode SEJENAK sampai animasi tween di atas selesai
	await tween.finished
	
	# 4. Setelah layar hitam sepenuhnya, pindah scene
	get_tree().change_scene_to_file("res://main.tscn")
