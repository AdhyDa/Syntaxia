extends Node

## Test Runner Otomatis Sistem Toko "Mpok Sintaks"
## Menguji ekonomi QuestManager, UI ShopUI 2 Arah (Beli & Jual), validasi stok/koin, dan interaksi Toko

func _ready() -> void:
	print("[TEST_SHOP_RUNNER] Memulai pengujian otomatis sistem toko...")
	await get_tree().create_timer(0.2).timeout
	run_tests()


func run_tests() -> void:
	var passed = 0
	var failed = 0
	
	# ==========================================
	# 1. UJI EKONOMI & HELPER QUESTMANAGER
	# ==========================================
	print("\n--- [TEST 1] Menguji Data Ekonomi QuestManager ---")
	var shop_ids = QuestManager.get_shop_item_ids()
	var expected_ids = ["air", "beras", "serai", "gulamerah", "jahe", "asamjawa", "kencur"]
	
	if shop_ids == expected_ids:
		print("  [PASS] Daftar item toko tepat 7 bahan herbal terdaftar.")
		passed += 1
	else:
		push_error("  [FAIL] Daftar item toko tidak cocok: %s" % str(shop_ids))
		failed += 1
		
	# Pastikan item jamu jadi tidak bisa diperjualbelikan di toko
	var forbidden_items = ["wedangjahesereh", "beraskencur", "gepyokan"]
	var forbidden_found = false
	for it in forbidden_items:
		if it in shop_ids or QuestManager.get_item_buy_price(it) > 0 or QuestManager.get_item_sell_price(it) > 0:
			forbidden_found = true
			break
			
	if not forbidden_found:
		print("  [PASS] Item jamu jadi tidak terdaftar di sistem toko.")
		passed += 1
	else:
		push_error("  [FAIL] Ditemukan jamu jadi di daftar toko!")
		failed += 1
		
	# Uji harga beli dan jual
	var price_table = {
		"air": [6, 1],
		"beras": [6, 1],
		"serai": [9, 1],
		"gulamerah": [9, 1],
		"jahe": [12, 2],
		"asamjawa": [18, 3],
		"kencur": [18, 3]
	}
	var prices_correct = true
	for item_id in price_table:
		var expected_buy = price_table[item_id][0]
		var expected_sell = price_table[item_id][1]
		var actual_buy = QuestManager.get_item_buy_price(item_id)
		var actual_sell = QuestManager.get_item_sell_price(item_id)
		if actual_buy != expected_buy or actual_sell != expected_sell:
			prices_correct = false
			push_error("  [FAIL] Harga tidak cocok untuk %s: Buy %d (exp %d), Sell %d (exp %d)" % [item_id, actual_buy, expected_buy, actual_sell, expected_sell])
			
	if prices_correct:
		print("  [PASS] Seluruh harga Beli dan Jual 7 bahan herbal 100% akurat.")
		passed += 1
	else:
		failed += 1
		
	# Uji spend_gold dan add_gold
	QuestManager.current_gold = 10
	var spend_fail = QuestManager.spend_gold(15) # Saldo tidak cukup
	if not spend_fail and QuestManager.current_gold == 10:
		print("  [PASS] spend_gold menolak transaksi jika koin kurang.")
		passed += 1
	else:
		push_error("  [FAIL] spend_gold seharusnya gagal ketika koin kurang.")
		failed += 1
		
	var spend_success = QuestManager.spend_gold(6)
	if spend_success and QuestManager.current_gold == 4:
		print("  [PASS] spend_gold berhasil memotong koin saat saldo cukup.")
		passed += 1
	else:
		push_error("  [FAIL] spend_gold gagal memotong koin dengan benar.")
		failed += 1
		
	QuestManager.add_gold(10)
	if QuestManager.current_gold == 14:
		print("  [PASS] add_gold berhasil menambah koin.")
		passed += 1
	else:
		push_error("  [FAIL] add_gold tidak menambahkan koin.")
		failed += 1

	# ==========================================
	# 2. UJI ANTARMUKA SHOPUI
	# ==========================================
	print("\n--- [TEST 2] Menguji Antarmuka & Logika ShopUI ---")
	# Reset inventory & koin untuk pengujian UI
	PlayerInventory.items.clear()
	QuestManager.current_gold = 20
	
	var shop_scene = load("res://system/ui/shop_ui.tscn")
	var shop_ui = shop_scene.instantiate()
	add_child(shop_ui)
	
	# Verifikasi default state
	if shop_ui.current_mode == shop_ui.ShopMode.BUY and shop_ui.selected_item_id == "air":
		print("  [PASS] Default state ShopUI: Mode BUY aktif dan item 'air' terpilih.")
		passed += 1
	else:
		push_error("  [FAIL] Default state ShopUI salah.")
		failed += 1
		
	# Cek jumlah kartu di grid
	var cards = shop_ui.item_grid_container.get_children()
	if cards.size() == 7:
		print("  [PASS] GridContainer menampilkan tepat 7 kartu item bahan herbal.")
		passed += 1
	else:
		push_error("  [FAIL] Jumlah kartu di grid salah: %d" % cards.size())
		failed += 1
		
	# Cek tombol aksi BUY aktif karena koin 20 >= 6 (air) dan stok 0 < 5
	if not shop_ui.btn_action.disabled and shop_ui.action_label.text == "BUY":
		print("  [PASS] Tombol BUY aktif saat koin cukup dan tas belum penuh.")
		passed += 1
	else:
		push_error("  [FAIL] Tombol BUY harusnya aktif.")
		failed += 1
		
	# Lakukan pembelian 1 air (harga 6 koin)
	shop_ui._process_buy()
	if QuestManager.current_gold == 14 and PlayerInventory.get_item_count("air") == 1:
		print("  [PASS] Pembelian berhasil: Koin 20 -> 14, Stok Air 0 -> 1.")
		passed += 1
	else:
		push_error("  [FAIL] Transaksi BUY gagal memperbarui saldo atau inventory.")
		failed += 1
		
	# Penuhi stok air hingga 5 (MAX_STACK)
	PlayerInventory.items["air"] = 5
	shop_ui.refresh_ui()
	if shop_ui.btn_action.disabled:
		print("  [PASS] Tombol BUY otomatis disabled ketika stok tas sudah penuh 5/5.")
		passed += 1
	else:
		push_error("  [FAIL] Tombol BUY seharusnya disabled saat stok 5/5.")
		failed += 1
		
	# Pindah ke tab SELL
	print("\n--- [TEST 3] Menguji Mode SELL & Penguncian Slot Kosong ---")
	shop_ui._on_tab_sell_pressed()
	if shop_ui.current_mode == shop_ui.ShopMode.SELL and shop_ui.action_label.text == "SELL":
		print("  [PASS] Pindah ke tab SELL berhasil.")
		passed += 1
	else:
		push_error("  [FAIL] Gagal beralih ke tab SELL.")
		failed += 1
		
	# Item air memiliki stok 5 -> Tombol SELL harus enabled
	if not shop_ui.btn_action.disabled:
		print("  [PASS] Tombol SELL aktif untuk item 'air' dengan stok > 0.")
		passed += 1
	else:
		push_error("  [FAIL] Tombol SELL harusnya aktif untuk item berstok.")
		failed += 1
		
	# Pilih item 'kencur' yang stoknya 0 di tas
	shop_ui.select_item("kencur")
	if shop_ui.btn_action.disabled:
		print("  [PASS] Tombol SELL otomatis disabled saat stok item 0.")
		passed += 1
	else:
		push_error("  [FAIL] Tombol SELL harusnya disabled saat stok item 0.")
		failed += 1
		
	# Periksa bingkai preview detail panel kanan menggunakan slot_empty_locked
	if shop_ui.detail_slot_frame.texture == shop_ui.TEX_SLOT_EMPTY_LOCKED:
		print("  [PASS] Detail panel kanan menggunakan tekstur slot_empty_locked saat stok 0 di mode SELL.")
		passed += 1
	else:
		push_error("  [FAIL] Tekstur detail_slot_frame bukan slot_empty_locked.")
		failed += 1
		
	# Lakukan penjualan 1 air (pilih air kembali)
	shop_ui.select_item("air")
	var gold_before_sell = QuestManager.current_gold
	shop_ui._process_sell()
	var sell_price_air = QuestManager.get_item_sell_price("air")
	if QuestManager.current_gold == gold_before_sell + sell_price_air and PlayerInventory.get_item_count("air") == 4:
		print("  [PASS] Penjualan berhasil: Koin bertambah +%d, Stok Air berkurang 5 -> 4." % sell_price_air)
		passed += 1
	else:
		push_error("  [FAIL] Transaksi SELL gagal.")
		failed += 1
		
	# Uji penutupan toko
	var closed_emitted = [false]
	shop_ui.shop_closed.connect(func(): closed_emitted[0] = true)
	shop_ui.close_shop()
	if closed_emitted[0]:
		print("  [PASS] Sinyal shop_closed terpancar saat toko ditutup.")
		passed += 1
	else:
		push_error("  [FAIL] Sinyal shop_closed tidak terpancar.")
		failed += 1

	# ==========================================
	# 3. UJI NODE TOKO DI MAP_VILLAGE.TSCN
	# ==========================================
	print("\n--- [TEST 4] Menguji Node Toko di map_village.tscn ---")
	var map_village_scene = load("res://content/map/map_village.tscn")
	if map_village_scene != null:
		var map_inst = map_village_scene.instantiate()
		add_child(map_inst)
		
		var toko_node = map_inst.find_child("Toko", true, false)
		if toko_node != null:
			print("  [PASS] Node Toko ditemukan di dalam map_village.")
			passed += 1
			
			var script_path = toko_node.get_script().resource_path if toko_node.get_script() else ""
			if "toko_interaction.gd" in script_path:
				print("  [PASS] Script toko_interaction.gd berhasil terpasang pada node Toko.")
				passed += 1
			else:
				push_error("  [FAIL] Script pada node Toko bukan toko_interaction.gd: %s" % script_path)
				failed += 1
				
			var interaction_area = toko_node.find_child("TokoInteractionArea", true, false)
			if interaction_area != null:
				print("  [PASS] TokoInteractionArea berhasil diinstansiasi secara dinamis.")
				passed += 1
				if interaction_area.get_collision_mask_value(2) and interaction_area.get_collision_mask_value(5):
					print("  [PASS] Collision mask TokoInteractionArea mencakup layer 2 dan 5 (player).")
					passed += 1
				else:
					push_error("  [FAIL] Collision mask TokoInteractionArea tidak mencakup player.")
					failed += 1
			else:
				push_error("  [FAIL] TokoInteractionArea tidak ditemukan di node Toko.")
				failed += 1
				
			var prompt = toko_node.find_child("@Label@*", true, false)
			if not prompt:
				for c in toko_node.get_children():
					if c is Label:
						prompt = c
						break
			if prompt and prompt.text == "[E] Toko Mpok Sintaks":
				print("  [PASS] Prompt label mengambang '[E] Toko Mpok Sintaks' berhasil dibuat.")
				passed += 1
			else:
				push_error("  [FAIL] Prompt label pada Toko tidak ditemukan atau teks tidak cocok.")
				failed += 1
		else:
			push_error("  [FAIL] Node Toko tidak ditemukan di map_village.")
			failed += 1
			
		map_inst.queue_free()
	else:
		push_error("  [FAIL] Gagal memuat scene map_village.tscn.")
		failed += 1

	# ==========================================
	# HASIL AKHIR
	# ==========================================
	print("\n==========================================")
	print("RINGKASAN HASIL TEST TOKO MPOK SINTAKS:")
	print("  TOTAL PASSED : %d" % passed)
	print("  TOTAL FAILED : %d" % failed)
	print("==========================================\n")
	
	if failed == 0:
		print(">>> SEMUA TEST TOKO 'MPOK SINTAKS' BERHASIL 100%! <<<")
	else:
		push_error(">>> TERDAPAT TEST YANG GAGAL! <<<")
	
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0 if failed == 0 else 1)
