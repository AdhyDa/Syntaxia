extends Control

# Panggil node teks resep dan judulnya
# Pastikan path ini sesuai dengan struktur node kamu, atau gunakan %IngredientsList jika pakai Unique Name
@onready var ingredients_list: RichTextLabel = %IngredientsList
@onready var recipe_name: Label = %RecipeName

func _ready():
	# Ini hanya contoh pemanggilan saat UI pertama kali muncul
	update_recipe_display()

func update_recipe_display():
	# 1. Ubah judul resep
	recipe_name.text = "RAMUAN STAMINA"
	
	# 2. Siapkan path gambar item (PASTIKAN PATH INI SESUAI DENGAN FOLDERMU)
	var leaf_icon = "res://content/items/lumina_leaf.png"
	var crystal_icon = "res://content/items/dew_crystal.png"
	
	# 3. Susun teks BBCode-nya
	var recipe_text = "[img width=24 height=24]%s[/img]  [color=#60311f]Lumina Leaves: 3[/color]\n\n" % leaf_icon
	recipe_text += "[img width=24 height=24]%s[/img]  [color=#60311f]Dew Crystals: 1[/color]" % crystal_icon
	
	# 4. Terapkan teks ke dalam node RichTextLabel
	ingredients_list.text = recipe_text
