extends Control

const QUEST_DETAIL_POPUP_SCENE = preload("res://system/quest/quest_detail_popup.tscn")

@onready var label_title: Label = %LabelTitle
@onready var label_objectives: RichTextLabel = %LabelObjective
@onready var btn_quest_detail: Button = %BtnQuestDetail


func _ready() -> void:
	if btn_quest_detail:
		btn_quest_detail.pressed.connect(_on_btn_quest_detail_pressed)
		
	# Hubungkan sinyal dari QuestManager dan PlayerInventory
	if is_instance_valid(QuestManager):
		QuestManager.quest_state_changed.connect(_on_quest_state_changed)
	if is_instance_valid(PlayerInventory):
		PlayerInventory.item_added.connect(_on_inventory_changed)
		PlayerInventory.item_removed.connect(_on_inventory_changed)
		
	update_quest_display()
	start_sway_animation()


func _on_quest_state_changed(_quest_id: int, _new_status: int) -> void:
	update_quest_display()


func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	update_quest_display()


func update_quest_display() -> void:
	var q_id = QuestManager.active_quest_id if is_instance_valid(QuestManager) else 0
	var q_status = QuestManager.get_quest_status(q_id) if (is_instance_valid(QuestManager) and q_id > 0) else QuestManager.QuestStatus.NOT_STARTED
	var quest_data: Dictionary = QuestManager.get_quest_data(q_id) if is_instance_valid(QuestManager) else {}

	# Jika tidak ada quest yang sedang in progress atau ready to deliver, tampilkan petunjuk mencari NPC berikutnya
	if q_id == 0 or quest_data.is_empty() or q_status == QuestManager.QuestStatus.NOT_STARTED or q_status == QuestManager.QuestStatus.COMPLETED:
		if is_instance_valid(QuestManager):
			var guide = QuestManager.get_current_guide()
			set_quest(guide["title"], guide["hint"])
		else:
			set_quest("Petunjuk", "Cari NPC bernama Nara\ndi area perumahan")
		return

	var short_name: String = quest_data.get("short_name", "Pesanan")
	var client_short: String = quest_data.get("client_short", "NPC")

	match q_status:
		QuestManager.QuestStatus.IN_PROGRESS:
			if QuestManager.is_delivery_ready(q_id):
				set_quest(short_name, "- Jamu siap!\n- Bawa ke " + client_short)
			else:
				var lines: Array[String] = []
				var req_items: Dictionary = quest_data.get("required_items", {})
				for item_id in req_items:
					var req_amount = req_items[item_id]
					var cur_amount = PlayerInventory.get_item_count(item_id) if is_instance_valid(PlayerInventory) else 0
					var item_name = QuestManager.get_item_display_name(item_id)
					var icon_path = QuestManager.get_item_icon_path(item_id) if is_instance_valid(QuestManager) else ""
					if not icon_path.is_empty():
						lines.append("[img=18x18]%s[/img] %s: %d/%d" % [icon_path, item_name, cur_amount, req_amount])
					else:
						lines.append("- %s: %d/%d" % [item_name, cur_amount, req_amount])
				set_quest(short_name, "\n".join(lines))
		QuestManager.QuestStatus.READY_TO_DELIVER:
			set_quest(short_name, "- Jamu siap!\n- Serahkan ke " + client_short)


func set_quest(title_text: String, objectives_text: String) -> void:
	label_title.text = "[ " + title_text.to_upper() + " ]"
	label_objectives.text = objectives_text


func _on_btn_quest_detail_pressed() -> void:
	var hud_layer = get_tree().get_first_node_in_group("hud")
	if not hud_layer:
		hud_layer = get_tree().current_scene.find_child("Hud", true, false)
		
	var popup = QUEST_DETAIL_POPUP_SCENE.instantiate()
	if hud_layer:
		hud_layer.add_child(popup)
	else:
		get_tree().current_scene.add_child(popup)


# Animasi ayunan lembut untuk papan gantung
func start_sway_animation() -> void:
	# Atur pivot ke tengah atas (posisi rantai gantung)
	pivot_offset = Vector2(size.x / 2, 0)
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Berayun ke kanan 1.5 derajat, lalu ke kiri -1.5 derajat secara berulang
	tween.tween_property(self, "rotation_degrees", 1.5, 2.0)
	tween.tween_property(self, "rotation_degrees", -1.5, 2.0)
