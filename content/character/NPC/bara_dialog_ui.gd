extends Control

## NarjiDialogUI
## UI Dialog Interaktif dengan NPC Narji untuk Quest 2

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
	# Cek apakah Quest 1 sudah diselesaikan terlebih dahulu
	var q1_status = QuestManager.get_quest_status(1) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	if q1_status != QuestManager.QuestStatus.COMPLETED:
		speaker_name_label.text = "BARA (Calon Ksatria Syntaxia)"
		dialog_text_label.text = "Di desa ini, semuanya bersenang-senang selain aku, HUSS HUSS HUSS.\n\nHei tuan, namamu siapa? Jangan lupa pakai busana, kudengar Nara si penyihir pemula di dekat sana sedang menggigil hebat karena sihir es. Tolong bantu buatkan dia ramuan hangat dulu sebelum bicara denganku ya!"
		btn_option_1.text = "Baiklah, aku akan temui Nara dulu"
		btn_option_2.visible = false
		return

	var q_status = QuestManager.get_quest_status(2) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek apakah pemain sedang in progress tapi sudah memegang beras kencur di tas
	if q_status == QuestManager.QuestStatus.IN_PROGRESS:
		if is_instance_valid(PlayerInventory) and PlayerInventory.has_item("beraskencur"):
			q_status = QuestManager.QuestStatus.READY_TO_DELIVER
			QuestManager.set_quest_status(2, q_status)
			
	speaker_name_label.text = "BARA (Calon Ksatria Syntaxia)"
	btn_option_2.visible = false
	
	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			dialog_text_label.text = "Hosh... Hosh... Nafasku mau habis! Latihan pedang seharian benar-benar menguras seluruh energiku.\n\nBisakah kamu membuatkanku Ramuan Beras Kencur di Kuali? Ekstrak Kencur dan Beras dengan Fungsi, lalu racik dengan Prosedur untuk memulihkan tenagaku!"
			btn_option_1.text = "Terima Quest"
			btn_option_2.text = "Nanti Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.IN_PROGRESS:
			var c_kencur = PlayerInventory.get_item_count("kencur") if is_instance_valid(PlayerInventory) else 0
			var c_beras = PlayerInventory.get_item_count("beras") if is_instance_valid(PlayerInventory) else 0
			var c_air = PlayerInventory.get_item_count("air") if is_instance_valid(PlayerInventory) else 0
			
			dialog_text_label.text = "Aduh... Otot-ototku masih terasa kaku dan lemas.\nBahanmu saat ini:\n- Kencur: %d/2\n- Beras: %d/2\n- Air: %d/3\n\nJika bahan sudah lengkap, gunakan Teleporter ke Ruang Racik dan seduh di Kuali ya!" % [c_kencur, c_beras, c_air]
			btn_option_1.text = "Saya sedang mengumpulkannya!"
			btn_option_2.visible = false
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			dialog_text_label.text = "Hhh... Wangi kencur yang khas! Kamu berhasil meracik [Beras Kencur] di kuali! Bolehkah kuminum sekarang?"
			btn_option_1.text = "Serahkan Beras Kencur"
			btn_option_2.text = "Simpan Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.COMPLETED:
			dialog_text_label.text = "Terima kasih banyak! Berkat Beras Kencur buatanmu, staminaku langsung pulih penuh. Sekarang aku tidak perlu lepas busana dan siap lanjut latihan tempur!"
			btn_option_1.text = "Tetap semangat, Bara!"
			btn_option_2.visible = false


func _on_btn_option_1_pressed() -> void:
	# Jika Quest 1 belum selesai, tombol hanya berfungsi untuk menutup dialog
	var q1_status = QuestManager.get_quest_status(1) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	if q1_status != QuestManager.QuestStatus.COMPLETED:
		close_dialog()
		return

	var q_status = QuestManager.get_quest_status(2) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek lagi jika sedang in progress tapi jamu sudah ada
	if q_status == QuestManager.QuestStatus.IN_PROGRESS and is_instance_valid(PlayerInventory) and PlayerInventory.has_item("beraskencur"):
		q_status = QuestManager.QuestStatus.READY_TO_DELIVER
		QuestManager.set_quest_status(2, q_status)

	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			if is_instance_valid(QuestManager):
				QuestManager.start_quest(2)
			close_dialog()
			
		QuestManager.QuestStatus.IN_PROGRESS:
			close_dialog()
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			# Serahkan jamu dan selesaikan quest 2
			if is_instance_valid(PlayerInventory):
				PlayerInventory.remove_item("beraskencur", 1)
			if is_instance_valid(QuestManager):
				QuestManager.complete_quest(2)
				
			dialog_text_label.text = "Teguk... Teguk... Segar sekali! Rasa lelah di sekujur tubuhku langsung hilang seketika!\n\nIni 20 Koin dan 120 EXP untukmu sebagai tanda terima kasihku!"
			btn_option_1.text = "Sama-sama, Bara!"
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
