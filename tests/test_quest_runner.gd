extends Node

## Test Runner Otomatis di Runtime Game
## Menguji alur quest dan fitur Akordeon (Expand & Shrink) pada List Quest

func _ready() -> void:
	print("[TEST_RUNNER] Memulai pengujian otomatis sistem quest & akordeon...")
	await get_tree().create_timer(0.2).timeout
	run_tests()


func run_tests() -> void:
	var passed = 0
	var failed = 0
	
	# Test 1: Kondisi Awal (Belum ada quest)
	print("[TEST 1] Menguji kondisi awal (belum ada quest)...")
	QuestManager.active_quest_id = 0
	QuestManager.quest_statuses.clear()
	QuestManager.current_gold = 0
	QuestManager.current_exp = 0
	QuestManager.current_level = 1
	
	var popup = load("res://system/quest/quest_detail_popup.tscn").instantiate()
	add_child(popup)
	popup.refresh_details()
	
	if popup.title_label.text == "DAFTAR PESANAN" and "Belum ada quest" in popup.empty_state_label.text and not "-" in popup.empty_state_label.text and not popup.scroll_container.visible:
		print("  [PASS] QuestDetailPopup kondisi awal bersih & ramah tanpa tanda '-'.")
		passed += 1
	else:
		push_error("  [FAIL] QuestDetailPopup kondisi awal salah.")
		failed += 1
	popup.close_popup()
	
	# Test 2: Kondisi Hanya Menerima Quest 1
	print("[TEST 2] Menguji kondisi saat hanya Quest 1 yang aktif...")
	QuestManager.start_quest(1)
	
	var popup1 = load("res://system/quest/quest_detail_popup.tscn").instantiate()
	add_child(popup1)
	popup1.refresh_details()
	
	var cards1 = popup1.quest_list_container.get_children()
	if cards1.size() == 1:
		print("  [PASS] Ditemukan tepat 1 kartu quest di dalam list.")
		passed += 1
	else:
		push_error("  [FAIL] Jumlah kartu quest salah: %d" % cards1.size())
		failed += 1
		
	var card_q1 = cards1[0]
	var card_vbox = card_q1.get_child(0)
	var header_btn = card_vbox.get_child(0)
	var details_margin = card_vbox.get_child(1)
	var arrow_lbl = header_btn.find_child("ArrowLabel", true, false)
	
	# Verifikasi kondisi awal kartu adalah SHRINK
	if not details_margin.visible and arrow_lbl.text == "[ ▶ ]":
		print("  [PASS] Quest 1 secara default dalam kondisi SHRINK (rincian tertutup).")
		passed += 1
	else:
		push_error("  [FAIL] Quest 1 tidak default shrink.")
		failed += 1
		
	# Simulasikan klik untuk EXPAND
	header_btn.pressed.emit()
	if details_margin.visible and arrow_lbl.text == "[ ▼ ]":
		print("  [PASS] Quest 1 berhasil di-EXPAND (rincian terbuka, panah berubah).")
		passed += 1
	else:
		push_error("  [FAIL] Gagal expand Quest 1.")
		failed += 1
		
	# Simulasikan klik lagi untuk SHRINK
	header_btn.pressed.emit()
	if not details_margin.visible and arrow_lbl.text == "[ ▶ ]":
		print("  [PASS] Quest 1 berhasil di-SHRINK kembali.")
		passed += 1
	else:
		push_error("  [FAIL] Gagal shrink kembali Quest 1.")
		failed += 1
		
	popup1.close_popup()
	
	# Test 3: Selesaikan Quest 1 dan Terima Quest 2
	print("[TEST 3] Menguji kondisi Quest 1 selesai dan Quest 2 aktif...")
	PlayerInventory.add_item("jahe", 1)
	PlayerInventory.add_item("serai", 1)
	PlayerInventory.add_item("air", 1)
	
	var grimoire = load("res://system/ui/grimoire_ui.tscn").instantiate()
	add_child(grimoire)
	grimoire.player_code_edit.text = grimoire.ghost_code_edit.text
	grimoire._on_brew_button_pressed()
	grimoire.close_grimoire()
	
	PlayerInventory.remove_item("wedangjahesereh", 1)
	QuestManager.complete_quest(1)
	assert(QuestManager.get_quest_status(1) == QuestManager.QuestStatus.COMPLETED)
	
	# Terima Quest 2
	QuestManager.start_quest(2)
	assert(QuestManager.active_quest_id == 2)
	
	var popup2 = load("res://system/quest/quest_detail_popup.tscn").instantiate()
	add_child(popup2)
	popup2.refresh_details()
	
	var cards2 = popup2.quest_list_container.get_children()
	if cards2.size() == 2:
		print("  [PASS] Kedua quest (Quest 1 Selesai & Quest 2 Aktif) muncul bersamaan di list.")
		passed += 1
	else:
		push_error("  [FAIL] Jumlah kartu salah: %d (diharapkan 2)" % cards2.size())
		failed += 1
		
	# Periksa Kartu Quest 1 (Selesai)
	var q1_card = cards2[0]
	var q1_vbox = q1_card.get_child(0)
	var q1_header = q1_vbox.get_child(0)
	var q1_details = q1_vbox.get_child(1)
	
	# Cari label status singkat di header Quest 1
	var q1_labels = q1_header.find_children("", "Label", true, false)
	var q1_has_completed_text = false
	for lbl in q1_labels:
		if "telah diselesaikan" in lbl.text.to_lower():
			q1_has_completed_text = true
			break
			
	if q1_has_completed_text and not q1_details.visible:
		print("  [PASS] Quest 1 menampilkan keterangan telah diselesaikan dan default SHRINK.")
		passed += 1
	else:
		push_error("  [FAIL] Keterangan selesai Quest 1 tidak sesuai.")
		failed += 1
		
	# Periksa Kartu Quest 2 (Aktif)
	var q2_card = cards2[1]
	var q2_vbox = q2_card.get_child(0)
	var q2_header = q2_vbox.get_child(0)
	var q2_details = q2_vbox.get_child(1)
	
	var q2_labels = q2_header.find_children("", "Label", true, false)
	var q2_has_progress_text = false
	for lbl in q2_labels:
		if "belum selesai" in lbl.text.to_lower():
			q2_has_progress_text = true
			break
			
	if q2_has_progress_text and not q2_details.visible:
		print("  [PASS] Quest 2 menampilkan keterangan belum selesai dan default SHRINK.")
		passed += 1
	else:
		push_error("  [FAIL] Keterangan belum selesai Quest 2 tidak sesuai.")
		failed += 1
		
	# Buka rincian Quest 1 untuk memastikan riwayat detailnya tetap bisa dilihat
	q1_header.pressed.emit()
	if q1_details.visible:
		print("  [PASS] Rincian Quest 1 yang telah selesai tetap dapat di-EXPAND dan dibaca.")
		passed += 1
	else:
		push_error("  [FAIL] Rincian Quest 1 gagal di-expand.")
		failed += 1
		
	popup2.close_popup()
	
	# Test 4: Verifikasi RecentQuest tetap selaras
	print("[TEST 4] Menguji RecentQuest HUD...")
	var recent = load("res://recent_quest.tscn").instantiate()
	add_child(recent)
	recent.update_quest_display()
	
	if recent.label_title.text == "[ BERAS KENCUR ]":
		print("  [PASS] RecentQuest HUD menampilkan quest aktif terbaru (Quest 2).")
		passed += 1
	else:
		push_error("  [FAIL] RecentQuest HUD tidak sinkron.")
		failed += 1
		
	recent.queue_free()
	
	# Summary
	print("\n==========================================")
	print("HASIL PENGUJIAN: %d PASSED, %d FAILED" % [passed, failed])
	print("==========================================")
	
	if failed == 0:
		print("[TEST_RUNNER_SUCCESS] SELURUH FITUR LIST QUEST & AKORDEON BERHASIL 100%!")
	else:
		push_error("[TEST_RUNNER_FAILURE] Terdapat pengujian yang gagal.")
