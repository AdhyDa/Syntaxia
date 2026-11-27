extends Control

## NaraDialogUI
## UI Dialog Interaktif dengan NPC Nara untuk Quest 1

signal dialog_closed()

@onready var speaker_name_label: Label = %SpeakerNameLabel
@onready var dialog_text_label: Label = %DialogTextLabel
@onready var btn_option_1: Button = %BtnOption1
@onready var btn_option_2: Button = %BtnOption2


func _ready() -> void:
	btn_option_1.pressed.connect(_on_btn_option_1_pressed)
	btn_option_2.pressed.connect(_on_btn_option_2_pressed)
	refresh_dialog()


func refresh_dialog() -> void:
	var q_status = QuestManager.get_quest_status(1) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek apakah pemain sedang in progress tapi sudah memegang jamu di tas
	if q_status == QuestManager.QuestStatus.IN_PROGRESS:
		if is_instance_valid(PlayerInventory) and PlayerInventory.has_item("wedangjahesereh"):
			q_status = QuestManager.QuestStatus.READY_TO_DELIVER
			QuestManager.set_quest_status(1, q_status)
			
	speaker_name_label.text = "NARA (Penyihir Pemula)"
	btn_option_2.visible = false
	
	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			dialog_text_label.text = "Brrr... Dingin sekali! Sihir es-ku tadi lepas kendali dan badanku sekarang menggigil hebat...\n\nBisakah kamu membuatkanku Ramuan Wedang Jahe Sereh? Kamu butuh mengekstrak Jahe dan Sereh dengan Fungsi, lalu menyeduhnya dengan Prosedur!"
			btn_option_1.text = "Terima Quest"
			btn_option_2.text = "Nanti Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.IN_PROGRESS:
			var c_jahe = PlayerInventory.get_item_count("jahe") if is_instance_valid(PlayerInventory) else 0
			var c_serai = PlayerInventory.get_item_count("serai") if is_instance_valid(PlayerInventory) else 0
			var c_air = PlayerInventory.get_item_count("air") if is_instance_valid(PlayerInventory) else 0
			
			dialog_text_label.text = "Brrr... Gigiku sampai bergemeletuk kedinginan.\nBahanmu saat ini:\n- Jahe: %d/1\n- Sereh: %d/1\n- Air: %d/1\n\nJika bahan sudah lengkap, gunakan Teleporter ke Ruang Racik dan racik di Kuali ya!" % [c_jahe, c_serai, c_air]
			btn_option_1.text = "Saya sedang mengumpulkannya!"
			btn_option_2.visible = false
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			dialog_text_label.text = "Wah! Aroma hangat dan harum sereh ini... Kamu berhasil meracik [Wedang Jahe Sereh] di kuali! Boleh kuminum sekarang?"
			btn_option_1.text = "Serahkan Wedang Jahe Sereh"
			btn_option_2.text = "Simpan Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.COMPLETED:
			dialog_text_label.text = "Terima kasih banyak atas bantuanmu sebelumnya! Tubuhku sekarang sudah hangat dan segar bugar. Sihir es-ku pun sudah terkendali lagi."
			btn_option_1.text = "Senang bisa membantu!"
			btn_option_2.visible = false


func _on_btn_option_1_pressed() -> void:
	var q_status = QuestManager.get_quest_status(1) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek lagi jika sedang in progress tapi jamu sudah ada
	if q_status == QuestManager.QuestStatus.IN_PROGRESS and is_instance_valid(PlayerInventory) and PlayerInventory.has_item("wedangjahesereh"):
		q_status = QuestManager.QuestStatus.READY_TO_DELIVER
		QuestManager.set_quest_status(1, q_status)

	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			if is_instance_valid(QuestManager):
				QuestManager.start_quest(1)
			close_dialog()
			
		QuestManager.QuestStatus.IN_PROGRESS:
			close_dialog()
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			# Serahkan jamu dan selesaikan quest
			if is_instance_valid(PlayerInventory):
				PlayerInventory.remove_item("wedangjahesereh", 1)
			if is_instance_valid(QuestManager):
				QuestManager.complete_quest(1)
				
			dialog_text_label.text = "Glek... Glek... Aahh... Hangat sekali! Rasa beku di dadaku langsung mencair!\n\nIni 10 Koin dan 100 EXP untukmu sebagai ucapan terima kasihku!"
			btn_option_1.text = "Sama-sama, Nara!"
			btn_option_2.visible = false
			# Ubah koneksi tombol agar saat ditekan langsung tutup
			btn_option_1.pressed.disconnect(_on_btn_option_1_pressed)
			btn_option_1.pressed.connect(close_dialog)
			
		QuestManager.QuestStatus.COMPLETED:
			close_dialog()


func _on_btn_option_2_pressed() -> void:
	close_dialog()


func close_dialog() -> void:
	dialog_closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_dialog()
		get_viewport().set_input_as_handled()
