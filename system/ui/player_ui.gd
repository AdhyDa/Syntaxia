extends Control


const ITEM_TEXTURES: Dictionary = {
	"air": preload("res://content/collectible/bahan/air.png"),
	"beras": preload("res://content/collectible/bahan/beras.png"),
	"serai": preload("res://content/collectible/bahan/serai.png"),
	"gulamerah": preload("res://content/collectible/bahan/gula_merah.png"),
	"gula_merah": preload("res://content/collectible/bahan/gula_merah.png"),
	"jahe": preload("res://content/collectible/bahan/jahe.png"),
	"asamjawa": preload("res://content/collectible/bahan/asam_jawa.png"),
	"asam_jawa": preload("res://content/collectible/bahan/asam_jawa.png"),
	"kencur": preload("res://content/collectible/bahan/kencur.png"),
	"grass": preload("res://content/collectible/bahan/grass.png"),
	"wedangjahesereh": preload("res://content/potion/FireResistance.png"),
	"beraskencur": preload("res://content/potion/InfiniteStamina.png"),
	"gepyokan": preload("res://content/potion/GepyokanMahadaya.png"),
}

const UI_FONT = preload("res://content/menu/aset_menu/ThaleahFat.ttf")

@onready var gold_label: Label = %GoldLabel
@onready var exp_bar: TextureProgressBar = %ExpBar
@onready var exp_label: Label = %ExpLabel
@onready var collectible_container: HFlowContainer = %CollectibleContainer


func _ready() -> void:
	# Set nilai awal saat game dimulai dari QuestManager
	if is_instance_valid(QuestManager):
		update_gold(QuestManager.current_gold)
		update_exp(QuestManager.current_exp, QuestManager.get_max_exp_for_level(QuestManager.current_level), QuestManager.current_level)
		QuestManager.gold_changed.connect(update_gold)
		QuestManager.exp_changed.connect(update_exp)
	else:
		update_gold(0)
		update_exp(0, 100, 1)
	
	# Hubungkan sinyal dari backend PlayerInventory
	PlayerInventory.item_added.connect(_on_inventory_changed)
	PlayerInventory.item_removed.connect(_on_inventory_changed)
	PlayerInventory.inventory_loaded.connect(update_collectible_ui)
	
	update_collectible_ui()


func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	update_collectible_ui()


# Fungsi untuk mengubah angka Gold
func update_gold(amount: int) -> void:
	gold_label.text = str(amount)


# Fungsi untuk mengubah Bar EXP dan Level
func update_exp(current_exp: int, max_exp: int, level: int = 1) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = current_exp
	exp_label.text = "LV. %d" % level


## Memperbarui tampilan item collectible yang telah dikumpulkan
func update_collectible_ui() -> void:
	if not collectible_container:
		return
		
	# Hapus tampilan slot sebelumnya
	for child in collectible_container.get_children():
		child.queue_free()
		
	var all_items: Dictionary = PlayerInventory.get_all_items()
	
	for item_id in all_items:
		var count: int = int(all_items[item_id])
		if count <= 0:
			continue
			
		var slot = HBoxContainer.new()
		slot.add_theme_constant_override("separation", 2)
		
		# Icon bahan
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(14, 14)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ITEM_TEXTURES.has(item_id):
			icon_rect.texture = ITEM_TEXTURES[item_id]
		slot.add_child(icon_rect)
		
		# Label jumlah (misal: "x3" atau "3/5")
		var count_lbl = Label.new()
		count_lbl.text = "x%d" % count
		count_lbl.add_theme_font_override("font", UI_FONT)
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		count_lbl.add_theme_constant_override("outline_size", 3)
		slot.add_child(count_lbl)
		
		collectible_container.add_child(slot)
