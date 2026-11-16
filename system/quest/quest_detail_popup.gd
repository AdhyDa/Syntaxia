extends Control

## QuestDetailPopup
## Menampilkan daftar pesanan jamu (Quest List) dengan sistem Akordeon (Expand & Shrink).
## Mendukung riwayat quest yang telah diselesaikan maupun quest yang sedang aktif.

const UI_FONT: Font = preload("res://content/menu/aset_menu/ThaleahFat.ttf")

@onready var title_label: Label = %TitleLabel
@onready var empty_state_label: Label = %EmptyStateLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var quest_list_container: VBoxContainer = %QuestListContainer
@onready var close_x_btn: Button = %CloseXBtn

## Properti alias untuk kompatibilitas pengujian
var story_label: Label:
	get:
		return empty_state_label
var client_label: Label = null
var ingredients_label: Label = null
var status_quest_label: Label = null
var reward_label: Label = null


func _ready() -> void:
	if close_x_btn:
		close_x_btn.pressed.connect(close_popup)
		
	_freeze_player(true)
	refresh_details()


func _freeze_player(freeze: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if "move_vector" in node:
			node.move_vector = Vector2.ZERO
		if "velocity" in node:
			node.velocity = Vector2.ZERO
		for child in node.get_children():
			if child is HumanController or child.name == "HumanController":
				child.active = not freeze


func refresh_details() -> void:
	# Bersihkan daftar quest sebelumnya secara instan
	for child in quest_list_container.get_children():
		quest_list_container.remove_child(child)
		child.queue_free()
		
	var tracked_ids: Array[int] = []
	if is_instance_valid(QuestManager):
		tracked_ids = QuestManager.get_tracked_quest_ids()
		
	if tracked_ids.is_empty():
		# Kondisi belum ada quest: Tampilkan pesan ramah tanpa tanda "-"
		title_label.text = "DAFTAR PESANAN"
		empty_state_label.visible = true
		empty_state_label.text = "Belum ada quest yang diambil.\n\nSilakan temui warga desa untuk menerima pesanan ramuan jamu!"
		scroll_container.visible = false
	else:
		title_label.text = "DAFTAR PESANAN"
		empty_state_label.visible = false
		scroll_container.visible = true
		
		# Bangun kartu akordeon untuk setiap quest yang terlacak
		for q_id in tracked_ids:
			var card = _create_quest_card(q_id)
			quest_list_container.add_child(card)


func _create_quest_card(q_id: int) -> Control:
	var data: Dictionary = QuestManager.get_quest_data(q_id) if is_instance_valid(QuestManager) else {}
	var q_status: int = QuestManager.get_quest_status(q_id) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	var is_ready: bool = QuestManager.is_delivery_ready(q_id) if is_instance_valid(QuestManager) else false
	
	# Container Utama Kartu Quest
	var card_panel = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.95, 0.9, 0.82, 0.45)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.48, 0.32, 0.18, 0.7)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.content_margin_left = 8
	card_style.content_margin_top = 6
	card_style.content_margin_right = 8
	card_style.content_margin_bottom = 6
	card_panel.add_theme_stylebox_override("panel", card_style)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_panel.add_child(card_vbox)
	
	# ─────────────────────────────────────────────
	# BILAH HEADER (Clickable Accordion Header)
	# ─────────────────────────────────────────────
	var header_btn = Button.new()
	header_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.38, 0.24, 0.14, 0.12)
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.content_margin_left = 8
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_right = 8
	btn_normal.content_margin_bottom = 6
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.48, 0.32, 0.18, 0.25)
	
	header_btn.add_theme_stylebox_override("normal", btn_normal)
	header_btn.add_theme_stylebox_override("hover", btn_hover)
	header_btn.add_theme_stylebox_override("pressed", btn_hover)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_theme_constant_override("separation", 10)
	header_btn.add_child(header_hbox)
	
	# Ikon Panah Indikator (Expand / Shrink)
	var arrow_lbl = Label.new()
	arrow_lbl.name = "ArrowLabel"
	arrow_lbl.text = "[ ▶ ]" # Default: Shrink
	arrow_lbl.add_theme_font_override("font", UI_FONT)
	arrow_lbl.add_theme_font_size_override("font_size", 18)
	arrow_lbl.add_theme_color_override("font_color", Color(0.42, 0.26, 0.14, 1.0))
	header_hbox.add_child(arrow_lbl)
	
	# Info Judul & Status Singkat
	var title_info_vbox = VBoxContainer.new()
	title_info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_info_vbox)
	
	var quest_title_lbl = Label.new()
	quest_title_lbl.text = data.get("title", "Quest %d" % q_id)
	quest_title_lbl.add_theme_font_override("font", UI_FONT)
	quest_title_lbl.add_theme_font_size_override("font_size", 20)
	quest_title_lbl.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1.0))
	title_info_vbox.add_child(quest_title_lbl)
	
	var status_brief_lbl = Label.new()
	status_brief_lbl.add_theme_font_override("font", UI_FONT)
	status_brief_lbl.add_theme_font_size_override("font_size", 16)
	
	# Penentuan teks status singkat di header
	if q_status == QuestManager.QuestStatus.COMPLETED:
		status_brief_lbl.text = "Status: Quest %d telah diselesaikan" % q_id
		status_brief_lbl.add_theme_color_override("font_color", Color(0.12, 0.5, 0.16, 1.0))
	elif q_status == QuestManager.QuestStatus.READY_TO_DELIVER or is_ready:
		status_brief_lbl.text = "Status: Jamu telah siap! (Bawa ke %s)" % data.get("client_short", "Klien")
		status_brief_lbl.add_theme_color_override("font_color", Color(0.15, 0.52, 0.2, 1.0))
	elif q_status == QuestManager.QuestStatus.IN_PROGRESS:
		status_brief_lbl.text = "Status: Belum selesai (Sedang Berjalan)"
		status_brief_lbl.add_theme_color_override("font_color", Color(0.6, 0.32, 0.06, 1.0))
	else:
		status_brief_lbl.text = "Status: Belum selesai"
		status_brief_lbl.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 1.0))
		
	title_info_vbox.add_child(status_brief_lbl)
	card_vbox.add_child(header_btn)
	
	# ─────────────────────────────────────────────
	# PANEL RINCIAN (Details Container - Default: Shrink/Hidden)
	# ─────────────────────────────────────────────
	var details_margin = MarginContainer.new()
	details_margin.visible = false # Default: SHRINK
	details_margin.add_theme_constant_override("margin_left", 14)
	details_margin.add_theme_constant_override("margin_top", 4)
	details_margin.add_theme_constant_override("margin_right", 8)
	details_margin.add_theme_constant_override("margin_bottom", 6)
	
	var details_vbox = VBoxContainer.new()
	details_vbox.add_theme_constant_override("separation", 6)
	details_margin.add_child(details_vbox)
	
	# Klien
	var c_lbl = Label.new()
	c_lbl.text = "Klien: " + data.get("client", "Warga Desa")
	c_lbl.add_theme_font_override("font", UI_FONT)
	c_lbl.add_theme_font_size_override("font_size", 18)
	c_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12, 1.0))
	c_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_vbox.add_child(c_lbl)
	
	# Cerita / Deskripsi
	var s_lbl = Label.new()
	s_lbl.text = data.get("story", "")
	s_lbl.add_theme_font_override("font", UI_FONT)
	s_lbl.add_theme_font_size_override("font_size", 16)
	s_lbl.add_theme_color_override("font_color", Color(0.2, 0.13, 0.07, 1.0))
	s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_vbox.add_child(s_lbl)
	
	# Bahan-Bahan
	var ing_lbl = Label.new()
	ing_lbl.add_theme_font_override("font", UI_FONT)
	ing_lbl.add_theme_font_size_override("font_size", 17)
	ing_lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.09, 1.0))
	ing_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var req_items: Dictionary = data.get("required_items", {})
	var ing_lines: Array[String] = ["Bahan yang Dibutuhkan:"]
	
	if q_status == QuestManager.QuestStatus.COMPLETED:
		for item_id in req_items:
			var item_name = QuestManager.get_item_display_name(item_id) if is_instance_valid(QuestManager) else item_id.capitalize()
			ing_lines.append("✓ %s: Terpenuhi" % item_name)
	else:
		for item_id in req_items:
			var req_amount = req_items[item_id]
			var cur_amount = PlayerInventory.get_item_count(item_id) if is_instance_valid(PlayerInventory) else 0
			var item_name = QuestManager.get_item_display_name(item_id) if is_instance_valid(QuestManager) else item_id.capitalize()
			ing_lines.append("- %s: %d/%d" % [item_name, cur_amount, req_amount])
			
	ing_lbl.text = "\n".join(ing_lines)
	details_vbox.add_child(ing_lbl)
	
	# Status Terperinci
	var st_lbl = Label.new()
	st_lbl.add_theme_font_override("font", UI_FONT)
	st_lbl.add_theme_font_size_override("font_size", 17)
	st_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if q_status == QuestManager.QuestStatus.COMPLETED:
		st_lbl.text = "Status: Quest telah selesai dan imbalan telah diterima."
		st_lbl.add_theme_color_override("font_color", Color(0.12, 0.5, 0.16, 1.0))
	elif q_status == QuestManager.QuestStatus.READY_TO_DELIVER or is_ready:
		st_lbl.text = "Status: Jamu sudah jadi! Serahkan kepada %s di desa." % data.get("client_short", "klien")
		st_lbl.add_theme_color_override("font_color", Color(0.15, 0.52, 0.2, 1.0))
	elif q_status == QuestManager.QuestStatus.IN_PROGRESS:
		st_lbl.text = "Status: Kumpulkan bahan & racik di Kuali Ruang Racik."
		st_lbl.add_theme_color_override("font_color", Color(0.6, 0.32, 0.06, 1.0))
	else:
		st_lbl.text = "Status: Belum dimulai."
		st_lbl.add_theme_color_override("font_color", Color(0.45, 0.28, 0.12, 1.0))
		
	details_vbox.add_child(st_lbl)
	
	# Imbalan
	var rew_lbl = Label.new()
	rew_lbl.text = "Imbalan: %d Koin Perak, %d EXP" % [data.get("reward_gold", 0), data.get("reward_exp", 0)]
	rew_lbl.add_theme_font_override("font", UI_FONT)
	rew_lbl.add_theme_font_size_override("font_size", 17)
	rew_lbl.add_theme_color_override("font_color", Color(0.3, 0.2, 0.05, 1.0))
	details_vbox.add_child(rew_lbl)
	
	card_vbox.add_child(details_margin)
	
	# Hubungkan aksi klik untuk Expand & Shrink
	header_btn.pressed.connect(func():
		var is_expanded = not details_margin.visible
		details_margin.visible = is_expanded
		arrow_lbl.text = "[ ▼ ]" if is_expanded else "[ ▶ ]"
	)
	
	# Simpan referensi ke variabel instance jika ini quest pertama (untuk kompatibilitas test)
	if client_label == null:
		client_label = c_lbl
		ingredients_label = ing_lbl
		status_quest_label = st_lbl
		reward_label = rew_lbl
		
	return card_panel


func close_popup() -> void:
	_freeze_player(false)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_popup()
		get_viewport().set_input_as_handled()
