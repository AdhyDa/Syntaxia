extends Control

## ShopUI — Toko "Mpok Sintaks"
## Sistem Belanja 2 Arah (Beli & Jual Bahan Herbal)

signal shop_closed()

enum ShopMode { BUY, SELL }

const UI_FONT: Font = preload("res://content/menu/aset_menu/ThaleahFat.ttf")

const TEX_SLOT_NORMAL: Texture2D = preload("res://content/ui/shop_ui/slot_normal.png")
const TEX_SLOT_SELECTED: Texture2D = preload("res://content/ui/shop_ui/slot_selected.png")
const TEX_SLOT_EMPTY_LOCKED: Texture2D = preload("res://content/ui/shop_ui/slot_empty_locked.png")

const TEX_SHOP_CARD: Texture2D = preload("res://content/ui/shop_ui/shop_item_card.png")
const TEX_COIN: Texture2D = preload("res://content/collectible/coin/Coin2.png")

const TEX_TAB_NORMAL: Texture2D = preload("res://content/ui/shop_ui/tab_normal.png")
const TEX_TAB_HOVER: Texture2D = preload("res://content/ui/shop_ui/tab_hover.png")
const TEX_TAB_PRESSED: Texture2D = preload("res://content/ui/shop_ui/tab_pressed.png")

const TEX_BTN_NORMAL: Texture2D = preload("res://content/ui/shop_ui/button_normal.png")
const TEX_BTN_HOVER: Texture2D = preload("res://content/ui/shop_ui/button_hover.png")
const TEX_BTN_PRESSED: Texture2D = preload("res://content/ui/shop_ui/button_pressed.png")

@onready var btn_tab_buy: TextureButton = %BtnTabBuy
@onready var btn_tab_sell: TextureButton = %BtnTabSell
@onready var coin_label: Label = %CoinLabel

@onready var item_grid_container: GridContainer = %ItemGridContainer

@onready var selected_item_header_label: Label = %SelectedItemHeaderLabel
@onready var detail_slot_frame: TextureRect = %DetailSlotFrame
@onready var detail_item_icon: TextureRect = %DetailItemIcon
@onready var detail_price_label: Label = %DetailPriceLabel

@onready var btn_action: TextureButton = %BtnAction
@onready var action_label: Label = %ActionLabel
@onready var btn_back: TextureButton = %BtnBack

var current_mode: ShopMode = ShopMode.BUY
var selected_item_id: String = "air"

# HBox harga di panel kanan (angka + ikon koin), dibuat dinamis di _ready()
var _detail_price_hbox: HBoxContainer = null
var _detail_price_number_lbl: Label = null


func _ready() -> void:
	# Hubungkan tombol tab
	if btn_tab_buy:
		btn_tab_buy.pressed.connect(_on_tab_buy_pressed)
	if btn_tab_sell:
		btn_tab_sell.pressed.connect(_on_tab_sell_pressed)
		
	# Hubungkan tombol aksi & keluar
	if btn_action:
		btn_action.pressed.connect(_on_btn_action_pressed)
	if btn_back:
		btn_back.pressed.connect(_on_btn_back_pressed)
		
	# Hubungkan sinyal koin & tas
	if is_instance_valid(QuestManager):
		QuestManager.gold_changed.connect(_on_gold_changed)
	if is_instance_valid(PlayerInventory):
		PlayerInventory.item_added.connect(_on_inventory_changed)
		PlayerInventory.item_removed.connect(_on_inventory_changed)
	
	# Sembunyikan DetailPriceLabel tscn dan ganti dengan HBox (angka + ikon koin)
	if detail_price_label:
		detail_price_label.visible = false
		var parent_node := detail_price_label.get_parent()
		
		_detail_price_hbox = HBoxContainer.new()
		_detail_price_hbox.layout_mode = 0
		_detail_price_hbox.position = detail_price_label.position
		_detail_price_hbox.size = detail_price_label.size
		_detail_price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		_detail_price_number_lbl = Label.new()
		_detail_price_number_lbl.add_theme_font_override("font", UI_FONT)
		_detail_price_number_lbl.add_theme_font_size_override("font_size", 42)
		_detail_price_number_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_detail_price_number_lbl.text = "0"
		_detail_price_hbox.add_child(_detail_price_number_lbl)
		
		var coin_icon := _make_coin_icon(42.0)
		_detail_price_hbox.add_child(coin_icon)
		
		parent_node.add_child(_detail_price_hbox)
		
	# Bekukan kontrol pemain saat berbelanja
	_freeze_player(true)
	
	# Default state: Tab BUY aktif dan item pertama "air" terpilih
	current_mode = ShopMode.BUY
	selected_item_id = "air"
	refresh_ui()


func _freeze_player(freeze: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if "move_vector" in node:
			node.move_vector = Vector2.ZERO
		if "velocity" in node:
			node.velocity = Vector2.ZERO
		for child in node.get_children():
			if child is HumanController or child.name == "HumanController":
				child.active = not freeze


func _on_gold_changed(_total_gold: int) -> void:
	refresh_ui()


func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	refresh_ui()


func _on_tab_buy_pressed() -> void:
	if current_mode != ShopMode.BUY:
		current_mode = ShopMode.BUY
		refresh_ui()


func _on_tab_sell_pressed() -> void:
	if current_mode != ShopMode.SELL:
		current_mode = ShopMode.SELL
		refresh_ui()


func _on_btn_action_pressed() -> void:
	if current_mode == ShopMode.BUY:
		_process_buy()
	else:
		_process_sell()


func _process_buy() -> void:
	if not is_instance_valid(QuestManager) or not is_instance_valid(PlayerInventory):
		return
		
	var buy_price = QuestManager.get_item_buy_price(selected_item_id)
	var current_stock = PlayerInventory.get_item_count(selected_item_id)
	
	# Validasi saldo koin & kapasitas tas
	if QuestManager.current_gold >= buy_price and current_stock < PlayerInventory.MAX_STACK:
		if QuestManager.spend_gold(buy_price):
			PlayerInventory.add_item(selected_item_id, 1)
			refresh_ui()


func _process_sell() -> void:
	if not is_instance_valid(QuestManager) or not is_instance_valid(PlayerInventory):
		return
		
	var sell_price = QuestManager.get_item_sell_price(selected_item_id)
	var current_stock = PlayerInventory.get_item_count(selected_item_id)
	
	# Validasi ketersediaan stok di tas
	if current_stock > 0:
		if PlayerInventory.remove_item(selected_item_id, 1):
			QuestManager.add_gold(sell_price)
			refresh_ui()


func _on_btn_back_pressed() -> void:
	close_shop()


func close_shop() -> void:
	_freeze_player(false)
	shop_closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()


func select_item(item_id: String) -> void:
	selected_item_id = item_id
	refresh_ui()


func get_item_icon(item_id: String) -> Texture2D:
	var tres_path = "res://content/collectible/bahan/%s.tres" % item_id.to_lower()
	if ResourceLoader.exists(tres_path):
		var res = load(tres_path)
		if res and "icon" in res and res.icon != null:
			return res.icon
			
	var png_path = "res://content/collectible/bahan/%s.png" % item_id.to_lower()
	if ResourceLoader.exists(png_path):
		return load(png_path)
		
	return null


func refresh_ui() -> void:
	# 1. Update Tampilan Koin
	var gold_val: int = QuestManager.current_gold if is_instance_valid(QuestManager) else 0
	if coin_label:
		coin_label.text = "%d G" % gold_val
		
	# 2. Update Status Visual Tab BUY & SELL
	if btn_tab_buy and btn_tab_sell:
		if current_mode == ShopMode.BUY:
			btn_tab_buy.texture_normal = TEX_TAB_PRESSED
			btn_tab_sell.texture_normal = TEX_TAB_NORMAL
		else:
			btn_tab_buy.texture_normal = TEX_TAB_NORMAL
			btn_tab_sell.texture_normal = TEX_TAB_PRESSED
			
	# 3. Render Kartu Item di Panel Kiri
	_render_item_cards()
	
	# 4. Render Rincian di Panel Kanan
	_render_right_detail_panel()


## Membuat TextureRect ikon koin dari sprite sheet Coin2.png (frame pertama 10×10)
func _make_coin_icon(size: float = 20.0) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = TEX_COIN
	atlas.region = Rect2(0, 0, 10, 10)
	var tex_rect := TextureRect.new()
	tex_rect.texture = atlas
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.custom_minimum_size = Vector2(size, size)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex_rect


## Membuat HBoxContainer berisi [angka] [ikon koin]
func _make_price_hbox(amount: int, font_size: int, font_color: Color, hbox_size: Vector2, pos: Vector2 = Vector2.ZERO) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.position = pos
	hbox.size = hbox_size
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := Label.new()
	lbl.text = "%d" % amount
	lbl.add_theme_font_override("font", UI_FONT)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)

	var icon := _make_coin_icon(font_size * 1.1)
	hbox.add_child(icon)

	return hbox


func _render_item_cards() -> void:
	if not item_grid_container:
		return
		
	# Pembersihan instan untuk menghindari duplikasi di frame yang sama
	for child in item_grid_container.get_children():
		item_grid_container.remove_child(child)
		child.queue_free()
		
	var item_ids: Array[String] = []
	if is_instance_valid(QuestManager):
		item_ids = QuestManager.get_shop_item_ids()
	else:
		item_ids = ["air", "beras", "serai", "gulamerah", "jahe", "asamjawa", "kencur"]
		
	for it_id in item_ids:
		var card = _create_card_node(it_id)
		item_grid_container.add_child(card)


func _create_card_node(it_id: String) -> Control:
	var current_stock: int = PlayerInventory.get_item_count(it_id) if is_instance_valid(PlayerInventory) else 0
	var is_selected: bool = (it_id == selected_item_id)
	
	# Root Card Container
	var card_btn = Button.new()
	card_btn.custom_minimum_size = Vector2(240, 260)
	card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Style transparan untuk Button agar aset TextureRect di dalamnya yang tampil
	var empty_sb = StyleBoxEmpty.new()
	card_btn.add_theme_stylebox_override("normal", empty_sb)
	card_btn.add_theme_stylebox_override("hover", empty_sb)
	card_btn.add_theme_stylebox_override("pressed", empty_sb)
	card_btn.add_theme_stylebox_override("focus", empty_sb)
	
	# Background Card Frame
	var bg_tex = TextureRect.new()
	bg_tex.texture = TEX_SHOP_CARD
	bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_btn.add_child(bg_tex)
	
	# Top Slot Frame
	var slot_frame = TextureRect.new()
	slot_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot_frame.custom_minimum_size = Vector2(100, 100)
	slot_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_frame.position = Vector2(70, 24)
	slot_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Penentuan Texture Slot
	if current_mode == ShopMode.SELL and current_stock == 0:
		slot_frame.texture = TEX_SLOT_EMPTY_LOCKED
	elif is_selected:
		slot_frame.texture = TEX_SLOT_SELECTED
	else:
		slot_frame.texture = TEX_SLOT_NORMAL
		
	card_btn.add_child(slot_frame)
	
	# Ikon Bahan Herbal di Tengah Slot
	var icon_tex = TextureRect.new()
	icon_tex.texture = get_item_icon(it_id)
	icon_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_tex.custom_minimum_size = Vector2(56, 56)
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.position = Vector2(22, 22)
	icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if current_mode == ShopMode.SELL and current_stock == 0:
		icon_tex.modulate = Color(0.5, 0.5, 0.5, 0.45) # Efek terkunci/pudar
	else:
		icon_tex.modulate = Color(1, 1, 1, 1)
		
	slot_frame.add_child(icon_tex)
	
	# HBox Harga (angka + ikon koin) di Bagian Bawah Kartu
	var price_val: int = 0
	if is_instance_valid(QuestManager):
		if current_mode == ShopMode.BUY:
			price_val = QuestManager.get_item_buy_price(it_id)
		else:
			price_val = QuestManager.get_item_sell_price(it_id)
			
	var price_color := Color(0.24, 0.14, 0.08, 1)
	var price_hbox := _make_price_hbox(price_val, 24, price_color, Vector2(220, 45), Vector2(10, 165))
	card_btn.add_child(price_hbox)
	
	# Connect Klik Kartu
	card_btn.pressed.connect(func():
		select_item(it_id)
	)
	
	return card_btn


func _render_right_detail_panel() -> void:
	if not selected_item_header_label or not detail_slot_frame or not detail_item_icon:
		return
		
	var item_name: String = QuestManager.get_item_display_name(selected_item_id) if is_instance_valid(QuestManager) else selected_item_id.capitalize()
	var current_stock: int = PlayerInventory.get_item_count(selected_item_id) if is_instance_valid(PlayerInventory) else 0
	var player_gold: int = QuestManager.current_gold if is_instance_valid(QuestManager) else 0
	
	var buy_price: int = QuestManager.get_item_buy_price(selected_item_id) if is_instance_valid(QuestManager) else 0
	var sell_price: int = QuestManager.get_item_sell_price(selected_item_id) if is_instance_valid(QuestManager) else 0
	
	# Plakat Header Atas
	selected_item_header_label.text = item_name
	
	# Preview Slot & Ikon
	detail_item_icon.texture = get_item_icon(selected_item_id)
	
	if current_mode == ShopMode.SELL and current_stock == 0:
		detail_slot_frame.texture = TEX_SLOT_EMPTY_LOCKED
		detail_item_icon.modulate = Color(0.5, 0.5, 0.5, 0.45)
	else:
		detail_slot_frame.texture = TEX_SLOT_SELECTED
		detail_item_icon.modulate = Color(1, 1, 1, 1)
	
	# Info Harga & Tombol Aksi
	if current_mode == ShopMode.BUY:
		# Update HBox harga: angka hijau + ikon koin
		if _detail_price_number_lbl:
			_detail_price_number_lbl.text = "%d" % buy_price
			_detail_price_number_lbl.add_theme_color_override("font_color", Color(0.18, 0.45, 0.14, 1))
		action_label.text = "BUY"
		
		# Validasi Tombol BUY: Disabled jika koin kurang ATAU stok tas sudah penuh 5/5
		var can_buy: bool = (player_gold >= buy_price and current_stock < (PlayerInventory.MAX_STACK if is_instance_valid(PlayerInventory) else 5))
		btn_action.disabled = not can_buy
		btn_action.modulate = Color(1, 1, 1, 1) if can_buy else Color(0.65, 0.65, 0.65, 0.7)
		btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_buy else Control.CURSOR_ARROW
	else:
		# Update HBox harga: angka coklat + ikon koin
		if _detail_price_number_lbl:
			_detail_price_number_lbl.text = "%d" % sell_price
			_detail_price_number_lbl.add_theme_color_override("font_color", Color(0.55, 0.3, 0.05, 1))
		action_label.text = "SELL"
		
		# Validasi Tombol SELL: Disabled jika stok di tas 0
		var can_sell: bool = (current_stock > 0)
		btn_action.disabled = not can_sell
		btn_action.modulate = Color(1, 1, 1, 1) if can_sell else Color(0.65, 0.65, 0.65, 0.7)
		btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_sell else Control.CURSOR_ARROW
