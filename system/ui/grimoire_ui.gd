extends Control

## GrimoireUI
## UI Meja Racik / Buku Mantra Kuali Lapangan dengan Dual-Layered Permanent Ghost-Text

signal brewing_finished(success: bool)

@onready var title_label: Label = %QuestTitleLabel
@onready var ghost_code_edit: CodeEdit = %GhostCodeEdit
@onready var player_code_edit: CodeEdit = %PlayerCodeEdit
@onready var status_label: Label = %StatusLabel
@onready var brew_button: Button = %BrewButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	# Hubungkan sinyal tombol
	brew_button.pressed.connect(_on_brew_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Siapkan template quest saat ini
	setup_quest_template()
	
	# Matikan nomor baris di GhostCodeEdit agar tidak duplikat dengan PlayerCodeEdit
	ghost_code_edit.gutters_draw_line_numbers = false
	# GhostCodeEdit tidak punya gutter → teks dimulai dari x=0,
	# sedangkan PlayerCodeEdit punya gutter nomor baris.
	# Offset GhostCodeEdit ke kanan sebesar lebar gutter PlayerCodeEdit
	# agar kolom teks keduanya rata.
	await get_tree().process_frame
	# Hitung lebar gutter nomor baris PlayerCodeEdit (umumnya ~40-50px pada font 26)
	# dan atur posisi GhostCodeEdit supaya rata
	var gutter_width: float = player_code_edit.get_total_gutter_width()
	ghost_code_edit.position.x = gutter_width
	ghost_code_edit.size.x = player_code_edit.size.x - gutter_width
	
	# Reset status
	status_label.text = "Salin mantra di atas lalu tekan Racik."
	status_label.modulate = Color(0.2, 0.2, 0.2, 1.0)
	
	# Fokuskan cursor pemain
	player_code_edit.grab_focus()
	
	# Freeze player: cari HumanController dan nonaktifkan
	_freeze_player(true)


func _freeze_player(freeze: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if "move_vector" in node:
			node.move_vector = Vector2.ZERO
		if "velocity" in node:
			node.velocity = Vector2.ZERO
		for child in node.get_children():
			if child is HumanController or child.name == "HumanController":
				child.active = not freeze


func _process(_delta: float) -> void:
	# Sinkronisasi scroll permanen antara ghost-text dan player-text
	if is_instance_valid(ghost_code_edit) and is_instance_valid(player_code_edit):
		ghost_code_edit.scroll_vertical = player_code_edit.scroll_vertical
		# GhostCodeEdit tidak punya gutter nomor baris → posisi horizontal sama persis
		ghost_code_edit.scroll_horizontal = player_code_edit.scroll_horizontal


func setup_quest_template() -> void:
	var q_id: int = QuestManager.active_quest_id if is_instance_valid(QuestManager) else 0
	var quest_data: Dictionary = QuestManager.get_quest_data(q_id) if is_instance_valid(QuestManager) else {}
	
	if not quest_data.is_empty():
		title_label.text = "[ " + quest_data.get("title", "").to_upper() + " ]"
		ghost_code_edit.text = quest_data.get("ghost_template", "")
	else:
		title_label.text = "[ BUKU RESEP TERKUNCI ]"
		ghost_code_edit.text = "# Belum ada quest aktif yang dapat diracik."


func _on_brew_button_pressed() -> void:
	var q_id: int = QuestManager.active_quest_id if is_instance_valid(QuestManager) else 0
	var quest_data: Dictionary = QuestManager.get_quest_data(q_id) if is_instance_valid(QuestManager) else {}
	var result = RecipeParser.validate_and_brew(player_code_edit.text, q_id)
	
	if result.success:
		# Potong bahan dari tas sesuai database quest
		if is_instance_valid(PlayerInventory) and not quest_data.is_empty():
			var req_items: Dictionary = quest_data.get("required_items", {})
			for item_id in req_items:
				var amount = req_items[item_id]
				PlayerInventory.remove_item(item_id, amount)
			# Tambahkan item jamu jadi ke tas
			var res_item = quest_data.get("result_item", "")
			if not res_item.is_empty():
				PlayerInventory.add_item(res_item, 1)
		
		# Update status quest ke READY_TO_DELIVER
		if is_instance_valid(QuestManager):
			QuestManager.set_quest_status(q_id, QuestManager.QuestStatus.READY_TO_DELIVER)
		
		status_label.text = result.message
		status_label.modulate = Color(0.1, 0.7, 0.2, 1.0)
		brewing_finished.emit(true)
		
		# Nonaktifkan tombol sebentar lalu tutup atau beri waktu pemain melihat hasil
		brew_button.disabled = true
		get_tree().create_timer(1.2).timeout.connect(func():
			if is_instance_valid(self):
				close_grimoire()
		)
	else:
		# Gagal / Mana Glitch: Stok tas tidak berkurang
		status_label.text = result.message
		status_label.modulate = Color(0.9, 0.2, 0.2, 1.0)
		brewing_finished.emit(false)


func _on_close_button_pressed() -> void:
	close_grimoire()


func close_grimoire() -> void:
	# Unfreeze player sebelum menutup
	_freeze_player(false)
	# Mengembalikan kontrol / menutup modal
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_grimoire()
		get_viewport().set_input_as_handled()
