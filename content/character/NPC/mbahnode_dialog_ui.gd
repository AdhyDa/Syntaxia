extends Control

## SpiritDialogUI
## UI Dialog Interaktif dengan NPC Spirit Leluhur Peracik untuk Quest 3

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
	# Cek apakah Quest 2 sudah diselesaikan terlebih dahulu
	var q2_status = QuestManager.get_quest_status(2) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	if q2_status != QuestManager.QuestStatus.COMPLETED:
		speaker_name_label.text = "MBAH NODE (Penjaga Resep Kuno)"
		dialog_text_label.text = "Wahai pengelana muda... Jiwamu belum selaras dengan energi kuno tanah Syntaxia ini.\n\nKudengar Bara di desa masih kelelahan dan membutuhkan bantuanmu. Selesaikanlah tugasmu membantunya terlebih dahulu sebelum kamu siap menerima rahasia peracikan leluhur!"
		btn_option_1.text = "Baiklah, aku akan bantu Bara dulu"
		btn_option_2.visible = false
		return

	var q_status = QuestManager.get_quest_status(3) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek apakah pemain sedang in progress tapi sudah memegang gepyokan di tas
	if q_status == QuestManager.QuestStatus.IN_PROGRESS:
		if is_instance_valid(PlayerInventory) and PlayerInventory.has_item("gepyokan"):
			q_status = QuestManager.QuestStatus.READY_TO_DELIVER
			QuestManager.set_quest_status(3, q_status)
			
	speaker_name_label.text = "MBAH NODE (Penjaga Resep Kuno)"
	btn_option_2.visible = false
	
	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			dialog_text_label.text = "Salam, peracik muda berjiwa luhur. Aku adalah penjaga resep rahasia kuno yang diwariskan turun-temurun.\n\nAura tolak bala pelindung desa mulai redup. Bantulah aku meracik ramuan sakral [Gepyokan] di Kuali!\n\nRitual ini memerlukan dekomposisi logika ganda: buatlah FUNGSI Ekstrak_Manis(GulaMerah) dan FUNGSI Ekstrak_Pelindung(AsamJawa), lalu gabungkan keduanya pada PROSEDUR Buat_Gepyokan()!"
			btn_option_1.text = "Terima Quest"
			btn_option_2.text = "Nanti Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.IN_PROGRESS:
			var c_gula = PlayerInventory.get_item_count("gulamerah") if is_instance_valid(PlayerInventory) else 0
			var c_asam = PlayerInventory.get_item_count("asamjawa") if is_instance_valid(PlayerInventory) else 0
			var c_air = PlayerInventory.get_item_count("air") if is_instance_valid(PlayerInventory) else 0
			
			dialog_text_label.text = "Aura kegelapan mendekat... Apakah bahan-bahan sakral sudah kau himpun?\n\nBahanmu saat ini:\n- Gula Merah: %d/3\n- Asam Jawa: %d/3\n- Air: %d/4\n\nJika bahan telah lengkap, masuklah ke Ruang Racik dan susun mantra fungsi ganda di Kuali!" % [c_gula, c_asam, c_air]
			btn_option_1.text = "Aku sedang mengumpulkannya!"
			btn_option_2.visible = false
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			dialog_text_label.text = "Aroma keharmonisan kuno menguar... Luar biasa! Kau telah berhasil meracik [Gepyokan] dengan susunan logika mantra fungsi yang sempurna!\n\nBolehkah kuterima untuk memulai ritual penguatan batas desa?"
			btn_option_1.text = "Serahkan Gepyokan"
			btn_option_2.text = "Simpan Dulu"
			btn_option_2.visible = true
			
		QuestManager.QuestStatus.COMPLETED:
			dialog_text_label.text = "Aura tolak bala desa kini bersinar terang berkatmu. Pemahamanmu tentang abstraksi mantra dan dekomposisi fungsi telah terbukti melampaui peracik biasa. Semoga berkah leluhur selalu menuntun langkahmu!"
			btn_option_1.text = "Terima kasih, Mbah Node!"
			btn_option_2.visible = false


func _on_btn_option_1_pressed() -> void:
	# Jika Quest 2 belum selesai, tombol hanya berfungsi untuk menutup dialog
	var q2_status = QuestManager.get_quest_status(2) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	if q2_status != QuestManager.QuestStatus.COMPLETED:
		close_dialog()
		return

	var q_status = QuestManager.get_quest_status(3) if is_instance_valid(QuestManager) else QuestManager.QuestStatus.NOT_STARTED
	
	# Cek lagi jika sedang in progress tapi jamu sudah ada
	if q_status == QuestManager.QuestStatus.IN_PROGRESS and is_instance_valid(PlayerInventory) and PlayerInventory.has_item("gepyokan"):
		q_status = QuestManager.QuestStatus.READY_TO_DELIVER
		QuestManager.set_quest_status(3, q_status)

	match q_status:
		QuestManager.QuestStatus.NOT_STARTED:
			if is_instance_valid(QuestManager):
				QuestManager.start_quest(3)
			close_dialog()
			
		QuestManager.QuestStatus.IN_PROGRESS:
			close_dialog()
			
		QuestManager.QuestStatus.READY_TO_DELIVER:
			# Serahkan jamu dan selesaikan quest 3
			if is_instance_valid(PlayerInventory):
				PlayerInventory.remove_item("gepyokan", 1)
			if is_instance_valid(QuestManager):
				QuestManager.complete_quest(3)
				
			dialog_text_label.text = "Ritual berhasil! Selubung sakral telah terpasang membentengi seluruh desa Syntaxia!\n\nSebagai tanda penghormatan kami, terimalah 50 Koin Emas dan 200 EXP dari pusaka leluhur ini!"
			btn_option_1.text = "Terima kasih, Mbah Node!"
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
