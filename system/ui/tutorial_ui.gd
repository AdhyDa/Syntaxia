extends Control

## TutorialUI
## Mengelola popup tutorial multi-halaman (6 slide) berbasis carousel.

@export var custom_slide_images: Array[Texture2D] = []

@onready var title_label: Label = $TutorialPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var tutorial_image: TextureRect = $TutorialPanel/MarginContainer/VBoxContainer/TextureRect
@onready var description_label: Label = $TutorialPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var btn_prev: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonRow/BtnPrev
@onready var btn_close: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonRow/BtnClose
@onready var btn_next: Button = $TutorialPanel/MarginContainer/VBoxContainer/ButtonRow/BtnNext

const SLIDES: Array[Dictionary] = [
	{
		"title": "1. Kontrol Dasar",
		"description": "Gunakan tombol WASD atau Panah untuk bergerak mengelilingi desa. Tekan [E] untuk berinteraksi dengan NPC dan objek, serta tekan [ESC] untuk membuka Menu Jeda.",
		"image": null,
		"placeholder_colors": [Color(0.18, 0.32, 0.58), Color(0.10, 0.18, 0.35)]
	},
	{
		"title": "2. Mengambil Quest",
		"description": "Dekati warga desa seperti Nara, Narji, atau Spirit Leluhur, lalu tekan [E] untuk berbicara, menerima misi, dan melihat daftar ramuan yang dibutuhkan.",
		"image": null,
		"placeholder_colors": [Color(0.22, 0.48, 0.36), Color(0.12, 0.28, 0.20)]
	},
	{
		"title": "3. Mengumpulkan Bahan",
		"description": "Bahan-bahan dasar racikan hanya bisa didapatkan dengan cara menghancurkan atau memotong rumput liar (grass) yang tersebar di sekitar desa untuk menjatuhkan item secara acak.",
		"image": null,
		"placeholder_colors": [Color(0.36, 0.52, 0.18), Color(0.20, 0.32, 0.08)]
	},
	{
		"title": "4. Toko Mpok Sintaks",
		"description": "Kunjungi Toko Mpok Sintaks untuk menjual bahan berlebih demi mendapatkan koin, serta membeli bahan langka atau katalis khusus yang tidak bisa didapat dari rumput liar.",
		"image": null,
		"placeholder_colors": [Color(0.62, 0.42, 0.16), Color(0.38, 0.22, 0.08)]
	},
	{
		"title": "5. Rumah & Meja Racik",
		"description": "Masuklah ke dalam rumah MC (ruang meracik), lalu dekati meja racik atau kuali dan tekan [E] untuk menyusun kode serta menggabungkan bahan sesuai resep.",
		"image": null,
		"placeholder_colors": [Color(0.45, 0.22, 0.54), Color(0.24, 0.10, 0.32)]
	},
	{
		"title": "6. Menyelesaikan Quest",
		"description": "Setelah ramuan berhasil diracik dan masuk ke tas, kembali temui pemberi quest lalu tekan [E] untuk menyerahkan ramuan dan menuntaskan misi!",
		"image": null,
		"placeholder_colors": [Color(0.65, 0.24, 0.28), Color(0.38, 0.12, 0.14)]
	}
]

var current_index: int = 0
var _dummy_textures: Array[Texture2D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_generate_dummy_textures()
	
	btn_prev.pressed.connect(_on_prev_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	btn_next.pressed.connect(_on_next_pressed)


func _generate_dummy_textures() -> void:
	_dummy_textures.clear()
	for slide in SLIDES:
		var grad := Gradient.new()
		var colors: Array = slide.get("placeholder_colors", [Color(0.2, 0.2, 0.3), Color(0.1, 0.1, 0.15)])
		grad.set_color(0, colors[0])
		grad.set_color(1, colors[1])
		
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 640
		tex.height = 300
		tex.fill = GradientTexture2D.FILL_LINEAR
		tex.fill_from = Vector2(0.0, 0.0)
		tex.fill_to = Vector2(1.0, 1.0)
		_dummy_textures.append(tex)


func open_tutorial() -> void:
	current_index = 0
	_update_slide()
	visible = true
	get_tree().paused = true


func close_tutorial() -> void:
	visible = false
	# Unpause hanya jika PauseOverlay tidak sedang aktif terbuka
	var pause_overlay = get_parent().get_node_or_null("PauseMenuUI/PauseOverlay")
	if pause_overlay == null or not pause_overlay.visible:
		get_tree().paused = false


func _update_slide() -> void:
	if SLIDES.is_empty():
		return
		
	var slide: Dictionary = SLIDES[current_index]
	title_label.text = "%s (%d/%d)" % [slide["title"], current_index + 1, SLIDES.size()]
	description_label.text = slide["description"]
	
	# Prioritas gambar: custom_slide_images (Inspector) -> slide["image"] -> dummy GradientTexture2D
	var tex: Texture2D = null
	if current_index < custom_slide_images.size() and custom_slide_images[current_index] != null:
		tex = custom_slide_images[current_index]
	elif slide.get("image") is Texture2D:
		tex = slide["image"]
	elif current_index < _dummy_textures.size():
		tex = _dummy_textures[current_index]
		
	tutorial_image.texture = tex
	
	btn_prev.disabled = (current_index == 0)
	if current_index >= SLIDES.size() - 1:
		btn_next.text = "Selesai"
	else:
		btn_next.text = "Next >"


func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		_update_slide()


func _on_next_pressed() -> void:
	if current_index < SLIDES.size() - 1:
		current_index += 1
		_update_slide()
	else:
		close_tutorial()


func _on_close_pressed() -> void:
	close_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_tutorial()
		get_viewport().set_input_as_handled()
