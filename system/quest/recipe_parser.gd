class_name RecipeParser
extends RefCounted

## RecipeParser
## Memvalidasi mantra kode di Grimoire UI sesuai aturan level pembelajaran & inventory.

static func validate_and_brew(code: String, quest_id: int) -> Dictionary:
	# 1. Quest Lock: Izinkan Level 1, Level 2, dan Level 3
	if quest_id == 1:
		return _validate_level_1(code)
	elif quest_id == 2:
		return _validate_level_2(code)
	elif quest_id == 3:
		return _validate_level_3(code)
	
	return {
		"success": false,
		"message": "Mana Glitch: Kuali tidak merespon. Resep ini bukan untuk tingkatan quest aktifmu!"
	}


static func _validate_level_1(code: String) -> Dictionary:
	var clean_code = code.strip_edges()
	if clean_code.is_empty():
		return {
			"success": false,
			"message": "Kuali masih kosong. Tuliskan mantra resep sebelum meracik!"
		}
	
	var lines: Array[String] = []
	for l in clean_code.split("\n"):
		var trimmed = l.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	
	# Cek bahan terlarang / level lain (misal kencur, beras, gulamerah, asamjawa)
	var lower_all = clean_code.to_lower()
	var forbidden_keywords = ["kencur", "beras", "gulamerah", "gula_merah", "asamjawa", "asam_jawa", "ekstrak_stamina", "gepyokan"]
	for kw in forbidden_keywords:
		if kw in lower_all:
			return {
				"success": false,
				"message": "Mana Glitch: Terdeteksi bahan/mantra asing '%s' yang bukan bagian dari resep Wedang Jahe Sereh!" % kw
			}
	
	# Ekstraksi Blok FUNGSI dan PROSEDUR
	var fungsi_lines: Array[String] = []
	var prosedur_lines: Array[String] = []
	var in_fungsi = false
	var in_prosedur = false
	var found_fungsi_decl = false
	var found_prosedur_decl = false
	var fungsi_header = ""
	var prosedur_header = ""
	
	for line in lines:
		var u_line = line.to_upper()
		if u_line.begins_with("FUNGSI "):
			in_fungsi = true
			found_fungsi_decl = true
			fungsi_header = line
			continue
		elif u_line.begins_with("AKHIR_FUNGSI"):
			in_fungsi = false
			continue
		elif u_line.begins_with("PROSEDUR "):
			in_prosedur = true
			found_prosedur_decl = true
			prosedur_header = line
			continue
		elif u_line.begins_with("AKHIR_PROSEDUR"):
			in_prosedur = false
			continue
			
		if in_fungsi:
			fungsi_lines.append(line)
		elif in_prosedur:
			prosedur_lines.append(line)

	# 2. Validasi Deklarasi FUNGSI
	if not found_fungsi_decl:
		return {
			"success": false,
			"message": "Mana Glitch: Fungsi ekstraksi panas tidak ditemukan! Gunakan: FUNGSI Ekstrak_Panas(Jahe, Sereh)"
		}
	
	# Validasi nama fungsi Ekstrak_Panas
	var regex_fn = RegEx.new()
	regex_fn.compile("(?i)FUNGSI\\s+Ekstrak_Panas\\s*\\(([^)]*)\\)")
	var match_fn = regex_fn.search(fungsi_header)
	if not match_fn:
		return {
			"success": false,
			"message": "Mana Glitch: Format fungsi salah! Gunakan: FUNGSI Ekstrak_Panas(Jahe, Sereh)"
		}
	
	# Validasi parameter bahan fungsi (harus memuat jahe dan sereh/serai)
	var params = match_fn.get_string(1).to_lower()
	if not ("jahe" in params and ("sereh" in params or "serai" in params)):
		return {
			"success": false,
			"message": "Mana Glitch: Parameter bahan fungsi salah! Ekstrak_Panas membutuhkan parameter Jahe dan Sereh."
		}
	
	# Validasi Return Value (KEMBALIKAN) di dalam fungsi
	var has_return = false
	for fl in fungsi_lines:
		if fl.to_upper().begins_with("KEMBALIKAN"):
			has_return = true
			break
	if not has_return:
		return {
			"success": false,
			"message": "Mana Glitch: FUNGSI Ekstrak_Panas wajib memiliki nilai balik! Gunakan kata kunci: KEMBALIKAN Esensi_Hangat"
		}
	
	# 3. Validasi PROSEDUR
	if not found_prosedur_decl:
		return {
			"success": false,
			"message": "Mana Glitch: Prosedur penyeduhan tidak ditemukan! Gunakan: PROSEDUR Buat_Wedang_Jahe()"
		}
	
	var regex_proc = RegEx.new()
	regex_proc.compile("(?i)PROSEDUR\\s+Buat_Wedang_Jahe\\s*\\(\\s*\\)")
	if not regex_proc.search(prosedur_header):
		return {
			"success": false,
			"message": "Mana Glitch: Format prosedur salah! Gunakan: PROSEDUR Buat_Wedang_Jahe()"
		}
	
	# Prosedur TIDAK BOLEH mengandung KEMBALIKAN
	for pl in prosedur_lines:
		if pl.to_upper().begins_with("KEMBALIKAN"):
			return {
				"success": false,
				"message": "Mana Glitch: PROSEDUR Buat_Wedang_Jahe adalah aksi penyeduhan (void) dan dilarang menggunakan KEMBALIKAN!"
			}
	
	# Validasi pemanggilan fungsi di dalam prosedur harus ditampung dalam variabel (ada tanda '=' )
	var has_assignment_call = false
	var has_naked_call = false
	var regex_call = RegEx.new()
	regex_call.compile("(?i)Ekstrak_Panas\\s*\\(")
	
	for pl in prosedur_lines:
		if regex_call.search(pl):
			if "=" in pl:
				has_assignment_call = true
			else:
				has_naked_call = true
	
	if has_naked_call and not has_assignment_call:
		return {
			"success": false,
			"message": "Mana Glitch: Pemanggilan Ekstrak_Panas menghasilkan nilai balik, wajib ditampung ke dalam variabel (contoh: esensi = Ekstrak_Panas(Jahe, Sereh))!"
		}
	
	if not has_assignment_call:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu belum memanggil fungsi Ekstrak_Panas ke dalam variabel pada prosedur!"
		}
	
	# Validasi urutan aksi: Siapkan_Gelas(), Seduh_Air(), Campurkan(...)
	var proc_body = " ".join(prosedur_lines).to_lower()
	if not "siapkan_gelas" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Siapkan_Gelas() di dalam prosedur!"
		}
	if not "seduh_air" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Seduh_Air() di dalam prosedur!"
		}
	if not "campurkan" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Campurkan(esensi) di dalam prosedur!"
		}
	
	# 4. Validasi Ketersediaan Stok Nyata di PlayerInventory
	if is_instance_valid(PlayerInventory):
		var count_jahe = PlayerInventory.get_item_count("jahe")
		var count_serai = PlayerInventory.get_item_count("serai")
		var count_air = PlayerInventory.get_item_count("air")
		
		if count_jahe < 1 or count_serai < 1 or count_air < 1:
			var missing: Array[String] = []
			if count_jahe < 1:
				missing.append("Jahe (0/1)")
			if count_serai < 1:
				missing.append("Sereh (0/1)")
			if count_air < 1:
				missing.append("Air (0/1)")
			return {
				"success": false,
				"message": "Bahan di tas kurang: %s. Kumpulkan terlebih dahulu!" % ", ".join(missing)
			}
	
	# 5. Semua Validasi Sukses
	return {
		"success": true,
		"message": "Racikan berhasil diseduh! Wedang Jahe Sereh tercipta."
	}


static func _validate_level_2(code: String) -> Dictionary:
	var clean_code = code.strip_edges()
	if clean_code.is_empty():
		return {
			"success": false,
			"message": "Kuali masih kosong. Tuliskan mantra resep sebelum meracik!"
		}
	
	var lines: Array[String] = []
	for l in clean_code.split("\n"):
		var trimmed = l.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	
	# Cek bahan terlarang / level lain (misal jahe, serai, gulamerah, asamjawa)
	var lower_all = clean_code.to_lower()
	var forbidden_keywords = ["jahe", "serai", "sereh", "gulamerah", "gula_merah", "asamjawa", "asam_jawa", "ekstrak_panas", "ekstrak_pelindung", "gepyokan"]
	for kw in forbidden_keywords:
		if kw in lower_all:
			return {
				"success": false,
				"message": "Mana Glitch: Terdeteksi bahan/mantra asing '%s' yang bukan bagian dari resep Beras Kencur!" % kw
			}
	
	# Ekstraksi Blok FUNGSI dan PROSEDUR
	var fungsi_lines: Array[String] = []
	var prosedur_lines: Array[String] = []
	var in_fungsi = false
	var in_prosedur = false
	var found_fungsi_decl = false
	var found_prosedur_decl = false
	var fungsi_header = ""
	var prosedur_header = ""
	
	for line in lines:
		var u_line = line.to_upper()
		if u_line.begins_with("FUNGSI "):
			in_fungsi = true
			found_fungsi_decl = true
			fungsi_header = line
			continue
		elif u_line.begins_with("AKHIR_FUNGSI"):
			in_fungsi = false
			continue
		elif u_line.begins_with("PROSEDUR "):
			in_prosedur = true
			found_prosedur_decl = true
			prosedur_header = line
			continue
		elif u_line.begins_with("AKHIR_PROSEDUR"):
			in_prosedur = false
			continue
			
		if in_fungsi:
			fungsi_lines.append(line)
		elif in_prosedur:
			prosedur_lines.append(line)

	# 2. Validasi Deklarasi FUNGSI
	if not found_fungsi_decl:
		return {
			"success": false,
			"message": "Mana Glitch: Fungsi ekstraksi stamina tidak ditemukan! Gunakan: FUNGSI Ekstrak_Stamina(Kencur, Beras)"
		}
	
	# Validasi nama fungsi Ekstrak_Stamina
	var regex_fn = RegEx.new()
	regex_fn.compile("(?i)FUNGSI\\s+Ekstrak_Stamina\\s*\\(([^)]*)\\)")
	var match_fn = regex_fn.search(fungsi_header)
	if not match_fn:
		return {
			"success": false,
			"message": "Mana Glitch: Format fungsi salah! Gunakan: FUNGSI Ekstrak_Stamina(Kencur, Beras)"
		}
	
	# Validasi parameter bahan fungsi (harus memuat kencur dan beras)
	var params = match_fn.get_string(1).to_lower()
	if not ("kencur" in params and "beras" in params):
		return {
			"success": false,
			"message": "Mana Glitch: Parameter bahan fungsi salah! Ekstrak_Stamina membutuhkan parameter Kencur dan Beras."
		}
	
	# Validasi Return Value (KEMBALIKAN) di dalam fungsi
	var has_return = false
	for fl in fungsi_lines:
		if fl.to_upper().begins_with("KEMBALIKAN"):
			has_return = true
			break
	if not has_return:
		return {
			"success": false,
			"message": "Mana Glitch: FUNGSI Ekstrak_Stamina wajib memiliki nilai balik! Gunakan kata kunci: KEMBALIKAN Esensi_Vitalitas"
		}
	
	# 3. Validasi PROSEDUR
	if not found_prosedur_decl:
		return {
			"success": false,
			"message": "Mana Glitch: Prosedur penyeduhan tidak ditemukan! Gunakan: PROSEDUR Buat_Beras_Kencur()"
		}
	
	var regex_proc = RegEx.new()
	regex_proc.compile("(?i)PROSEDUR\\s+Buat_Beras_Kencur\\s*\\(\\s*\\)")
	if not regex_proc.search(prosedur_header):
		return {
			"success": false,
			"message": "Mana Glitch: Format prosedur salah! Gunakan: PROSEDUR Buat_Beras_Kencur()"
		}
	
	# Prosedur TIDAK BOLEH mengandung KEMBALIKAN
	for pl in prosedur_lines:
		if pl.to_upper().begins_with("KEMBALIKAN"):
			return {
				"success": false,
				"message": "Mana Glitch: PROSEDUR Buat_Beras_Kencur adalah aksi penyeduhan (void) dan dilarang menggunakan KEMBALIKAN!"
			}
	
	# Validasi pemanggilan fungsi di dalam prosedur harus ditampung dalam variabel
	var has_assignment_call = false
	var has_naked_call = false
	var regex_call = RegEx.new()
	regex_call.compile("(?i)Ekstrak_Stamina\\s*\\(")
	
	for pl in prosedur_lines:
		if regex_call.search(pl):
			if "=" in pl:
				has_assignment_call = true
			else:
				has_naked_call = true
	
	if has_naked_call and not has_assignment_call:
		return {
			"success": false,
			"message": "Mana Glitch: Pemanggilan Ekstrak_Stamina menghasilkan nilai balik, wajib ditampung ke dalam variabel (contoh: esensi = Ekstrak_Stamina(Kencur, Beras))!"
		}
	
	if not has_assignment_call:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu belum memanggil fungsi Ekstrak_Stamina ke dalam variabel pada prosedur!"
		}
	
	# Validasi urutan aksi: Siapkan_Gelas(), Seduh_Air(), Campurkan(...)
	var proc_body = " ".join(prosedur_lines).to_lower()
	if not "siapkan_gelas" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Siapkan_Gelas() di dalam prosedur!"
		}
	if not "seduh_air" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Seduh_Air() di dalam prosedur!"
		}
	if not "campurkan" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Campurkan(esensi) di dalam prosedur!"
		}
	
	# 4. Validasi Ketersediaan Stok Nyata di PlayerInventory
	if is_instance_valid(PlayerInventory):
		var count_kencur = PlayerInventory.get_item_count("kencur")
		var count_beras = PlayerInventory.get_item_count("beras")
		var count_air = PlayerInventory.get_item_count("air")
		
		if count_kencur < 2 or count_beras < 2 or count_air < 3:
			var missing: Array[String] = []
			if count_kencur < 2:
				missing.append("Kencur (%d/2)" % count_kencur)
			if count_beras < 2:
				missing.append("Beras (%d/2)" % count_beras)
			if count_air < 3:
				missing.append("Air (%d/3)" % count_air)
			return {
				"success": false,
				"message": "Bahan di tas kurang: %s. Kumpulkan terlebih dahulu!" % ", ".join(missing)
			}
	
	# 5. Semua Validasi Sukses
	return {
		"success": true,
		"message": "Racikan berhasil diseduh! Beras Kencur tercipta."
	}


static func _validate_level_3(code: String) -> Dictionary:
	var clean_code = code.strip_edges()
	if clean_code.is_empty():
		return {
			"success": false,
			"message": "Kuali masih kosong. Tuliskan mantra resep sebelum meracik!"
		}
	
	var lines: Array[String] = []
	for l in clean_code.split("\n"):
		var trimmed = l.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	
	# Cek bahan terlarang / level lain (misal jahe, serai, kencur, beras)
	var lower_all = clean_code.to_lower()
	var forbidden_keywords = ["jahe", "serai", "sereh", "kencur", "beras", "ekstrak_panas", "ekstrak_stamina"]
	for kw in forbidden_keywords:
		if kw in lower_all:
			return {
				"success": false,
				"message": "Mana Glitch: Terdeteksi bahan/mantra asing '%s' yang bukan bagian dari resep Gepyokan!" % kw
			}
	
	# Ekstraksi Blok FUNGSI-FUNGSI dan PROSEDUR (Multi-function decomposition)
	var fungsi_blocks: Array[Dictionary] = []
	var current_fn: Dictionary = {}
	var in_fungsi = false
	
	var prosedur_lines: Array[String] = []
	var found_prosedur_decl = false
	var prosedur_header = ""
	var in_prosedur = false
	
	for line in lines:
		var u_line = line.to_upper()
		if u_line.begins_with("FUNGSI "):
			in_fungsi = true
			current_fn = {"header": line, "lines": []}
			continue
		elif u_line.begins_with("AKHIR_FUNGSI"):
			in_fungsi = false
			if not current_fn.is_empty():
				fungsi_blocks.append(current_fn)
				current_fn = {}
			continue
		elif u_line.begins_with("PROSEDUR "):
			in_prosedur = true
			found_prosedur_decl = true
			prosedur_header = line
			continue
		elif u_line.begins_with("AKHIR_PROSEDUR"):
			in_prosedur = false
			continue
			
		if in_fungsi and not current_fn.is_empty():
			current_fn["lines"].append(line)
		elif in_prosedur:
			prosedur_lines.append(line)

	# 2. Validasi Deklarasi FUNGSI Ganda (Ekstrak_Manis dan Ekstrak_Pelindung)
	var fn_manis: Dictionary = {}
	var fn_pelindung: Dictionary = {}
	
	var regex_manis = RegEx.new()
	regex_manis.compile("(?i)FUNGSI\\s+Ekstrak_Manis\\s*\\(([^)]*)\\)")
	var regex_pelindung = RegEx.new()
	regex_pelindung.compile("(?i)FUNGSI\\s+Ekstrak_Pelindung\\s*\\(([^)]*)\\)")
	
	for fn in fungsi_blocks:
		if regex_manis.search(fn["header"]):
			fn_manis = fn
		elif regex_pelindung.search(fn["header"]):
			fn_pelindung = fn
	
	if fn_manis.is_empty():
		return {
			"success": false,
			"message": "Mana Glitch: Fungsi ekstraksi manis tidak ditemukan! Gunakan: FUNGSI Ekstrak_Manis(GulaMerah)"
		}
	
	if fn_pelindung.is_empty():
		return {
			"success": false,
			"message": "Mana Glitch: Fungsi ekstraksi pelindung tidak ditemukan! Gunakan: FUNGSI Ekstrak_Pelindung(AsamJawa)"
		}
	
	# Validasi parameter Ekstrak_Manis
	var match_manis = regex_manis.search(fn_manis["header"])
	var params_manis = match_manis.get_string(1).to_lower()
	if not ("gulamerah" in params_manis or "gula_merah" in params_manis or "gula" in params_manis):
		return {
			"success": false,
			"message": "Mana Glitch: Parameter fungsi Ekstrak_Manis salah! Butuh parameter GulaMerah."
		}
	
	# Validasi Return Value Ekstrak_Manis
	var manis_has_return = false
	for fl in fn_manis["lines"]:
		if fl.to_upper().begins_with("KEMBALIKAN"):
			manis_has_return = true
			break
	if not manis_has_return:
		return {
			"success": false,
			"message": "Mana Glitch: FUNGSI Ekstrak_Manis wajib memiliki nilai balik! Gunakan: KEMBALIKAN Esensi_Manis"
		}
	
	# Validasi parameter Ekstrak_Pelindung
	var match_pelindung = regex_pelindung.search(fn_pelindung["header"])
	var params_pelindung = match_pelindung.get_string(1).to_lower()
	if not ("asamjawa" in params_pelindung or "asam_jawa" in params_pelindung or "asam" in params_pelindung):
		return {
			"success": false,
			"message": "Mana Glitch: Parameter fungsi Ekstrak_Pelindung salah! Butuh parameter AsamJawa."
		}
	
	# Validasi Return Value Ekstrak_Pelindung
	var pelindung_has_return = false
	for fl in fn_pelindung["lines"]:
		if fl.to_upper().begins_with("KEMBALIKAN"):
			pelindung_has_return = true
			break
	if not pelindung_has_return:
		return {
			"success": false,
			"message": "Mana Glitch: FUNGSI Ekstrak_Pelindung wajib memiliki nilai balik! Gunakan: KEMBALIKAN Esensi_Tolak_Bala"
		}
	
	# 3. Validasi PROSEDUR Buat_Gepyokan
	if not found_prosedur_decl:
		return {
			"success": false,
			"message": "Mana Glitch: Prosedur penyeduhan tidak ditemukan! Gunakan: PROSEDUR Buat_Gepyokan()"
		}
	
	var regex_proc = RegEx.new()
	regex_proc.compile("(?i)PROSEDUR\\s+Buat_Gepyokan\\s*\\(\\s*\\)")
	if not regex_proc.search(prosedur_header):
		return {
			"success": false,
			"message": "Mana Glitch: Format prosedur salah! Gunakan: PROSEDUR Buat_Gepyokan()"
		}
	
	# Prosedur TIDAK BOLEH mengandung KEMBALIKAN
	for pl in prosedur_lines:
		if pl.to_upper().begins_with("KEMBALIKAN"):
			return {
				"success": false,
				"message": "Mana Glitch: PROSEDUR Buat_Gepyokan adalah aksi penyeduhan (void) dan dilarang menggunakan KEMBALIKAN!"
			}
	
	# Validasi pemanggilan kedua fungsi di dalam prosedur harus ditampung dalam variabel
	var call_manis_assigned = false
	var call_manis_naked = false
	var call_pelindung_assigned = false
	var call_pelindung_naked = false
	
	var regex_call_manis = RegEx.new()
	regex_call_manis.compile("(?i)Ekstrak_Manis\\s*\\(")
	var regex_call_pelindung = RegEx.new()
	regex_call_pelindung.compile("(?i)Ekstrak_Pelindung\\s*\\(")
	
	for pl in prosedur_lines:
		if regex_call_manis.search(pl):
			if "=" in pl:
				call_manis_assigned = true
			else:
				call_manis_naked = true
		if regex_call_pelindung.search(pl):
			if "=" in pl:
				call_pelindung_assigned = true
			else:
				call_pelindung_naked = true
	
	if call_manis_naked or not call_manis_assigned:
		return {
			"success": false,
			"message": "Mana Glitch: Pemanggilan Ekstrak_Manis menghasilkan nilai balik, wajib ditampung ke dalam variabel (contoh: esensi_manis = Ekstrak_Manis(GulaMerah))!"
		}
	
	if call_pelindung_naked or not call_pelindung_assigned:
		return {
			"success": false,
			"message": "Mana Glitch: Pemanggilan Ekstrak_Pelindung menghasilkan nilai balik, wajib ditampung ke dalam variabel (contoh: esensi_pelindung = Ekstrak_Pelindung(AsamJawa))!"
		}
	
	# Validasi urutan aksi: Siapkan_Gelas(), Seduh_Air(), Campurkan(...)
	var proc_body = " ".join(prosedur_lines).to_lower()
	if not "siapkan_gelas" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Siapkan_Gelas() di dalam prosedur!"
		}
	if not "seduh_air" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Seduh_Air() di dalam prosedur!"
		}
	if not "campurkan" in proc_body:
		return {
			"success": false,
			"message": "Mana Glitch: Kamu melewatkan aksi Campurkan(...) di dalam prosedur!"
		}
	
	# 4. Validasi Ketersediaan Stok Nyata di PlayerInventory (3 Gula Merah, 3 Asam Jawa, 4 Air)
	if is_instance_valid(PlayerInventory):
		var count_gula = PlayerInventory.get_item_count("gulamerah")
		var count_asam = PlayerInventory.get_item_count("asamjawa")
		var count_air = PlayerInventory.get_item_count("air")
		
		if count_gula < 3 or count_asam < 3 or count_air < 4:
			var missing: Array[String] = []
			if count_gula < 3:
				missing.append("Gula Merah (%d/3)" % count_gula)
			if count_asam < 3:
				missing.append("Asam Jawa (%d/3)" % count_asam)
			if count_air < 4:
				missing.append("Air (%d/4)" % count_air)
			return {
				"success": false,
				"message": "Bahan di tas kurang: %s. Kumpulkan terlebih dahulu!" % ", ".join(missing)
			}
	
	# 5. Semua Validasi Sukses
	return {
		"success": true,
		"message": "Racikan sakral berhasil diseduh! Gepyokan tercipta."
	}
