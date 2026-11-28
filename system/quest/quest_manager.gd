@tool
extends Node

## Singleton QuestManager
## Mengelola siklus hidup quest, level, exp, dan koin pemain.

static var instance: QuestManager = null

enum QuestStatus {
	NOT_STARTED = 0,
	IN_PROGRESS = 1,
	READY_TO_DELIVER = 2,
	COMPLETED = 3
}

func _init() -> void:
	instance = self

signal quest_state_changed(quest_id: int, new_status: int)
signal gold_changed(total_gold: int)
signal exp_changed(current_exp: int, max_exp: int, current_level: int)
signal level_up(new_level: int)

## ─────────────────────────────────────────────
## DATABASE QUEST — tambahkan quest baru di sini
## ─────────────────────────────────────────────
const ITEM_NAMES: Dictionary = {
	"jahe": "Jahe",
	"serai": "Sereh",
	"sereh": "Sereh",
	"air": "Air",
	"kencur": "Kencur",
	"beras": "Beras",
	"gulamerah": "Gula Merah",
	"asamjawa": "Asam Jawa",
	"grass": "Rumput",
	"wedangjahesereh": "Wedang Jahe Sereh",
	"beraskencur": "Beras Kencur",
	"gepyokan": "Gepyokan"
}

const ITEM_ICONS: Dictionary = {
	"jahe": "res://content/collectible/bahan/jahe.png",
	"serai": "res://content/collectible/bahan/serai.png",
	"sereh": "res://content/collectible/bahan/serai.png",
	"air": "res://content/collectible/bahan/air.png",
	"kencur": "res://content/collectible/bahan/kencur.png",
	"beras": "res://content/collectible/bahan/beras.png",
	"gulamerah": "res://content/collectible/bahan/gula_merah.png",
	"gula_merah": "res://content/collectible/bahan/gula_merah.png",
	"asamjawa": "res://content/collectible/bahan/asam_jawa.png",
	"asam_jawa": "res://content/collectible/bahan/asam_jawa.png"
}

## Data ekonomi Hardcore untuk 7 bahan herbal di Toko Mpok Sintaks
const ITEM_PRICES: Dictionary = {
	"air": {"buy": 6, "sell": 1},
	"beras": {"buy": 6, "sell": 1},
	"serai": {"buy": 9, "sell": 1},
	"gulamerah": {"buy": 9, "sell": 1},
	"jahe": {"buy": 12, "sell": 2},
	"asamjawa": {"buy": 18, "sell": 3},
	"kencur": {"buy": 18, "sell": 3}
}

const QUEST_DATABASE: Dictionary = {
	1: {
		"id": 1,
		"title": "Quest 1: Pesanan Sang Pemula",
		"short_name": "Wedang Jahe",
		"client": "Nara (Penyihir Pemula yang Kedinginan)",
		"client_short": "Nara",
		"story": "Nara menggigil kedinginan akibat sihir es yang lepas kendali. Bantulah membuatkan ramuan Wedang Jahe Sereh di Kuali Ruang Racik untuk menghangatkan tubuhnya!",
		"required_items": {"jahe": 1, "serai": 1, "air": 1},
		"result_item": "wedangjahesereh",
		"result_item_name": "Wedang Jahe Sereh",
		"reward_gold": 10,
		"reward_exp": 100,
		"hint": "Cari NPC bernama Nara\ndi area perumahan",
		"ghost_template": "FUNGSI Ekstrak_Panas(Jahe, Sereh)\n    KEMBALIKAN Esensi_Hangat\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Wedang_Jahe()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Panas(Jahe, Sereh)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
	},
	2: {
		"id": 2,
		"title": "Quest 2: Pemulih Tenaga Bara",
		"short_name": "Beras Kencur",
		"client": "Bara (Calon Ksatria Syntaxia)",
		"client_short": "Bara",
		"story": "Bara kelelahan setelah latihan tempur seharian. Racikkan Beras Kencur agar tenaganya pulih kembali!",
		"required_items": {"kencur": 2, "beras": 2, "air": 3},
		"result_item": "beraskencur",
		"result_item_name": "Beras Kencur",
		"reward_gold": 25,
		"reward_exp": 100,
		"hint": "Cari NPC bernama Bara\ndi area latihan tempur",
		"ghost_template": "FUNGSI Ekstrak_Stamina(Kencur, Beras)\n    KEMBALIKAN Esensi_Vitalitas\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Beras_Kencur()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Stamina(Kencur, Beras)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
	},
	3: {
		"id": 3,
		"title": "Quest 3: Berkah Mbah Node",
		"short_name": "Gepyokan",
		"client": "Mbah Node (Penjaga Resep Kuno)",
		"client_short": "Mbah Node",
		"story": "Mbah Node meminta ramuan sakral Gepyokan untuk memperkuat proteksi kuno desa. Ekstrak esensi manis dan pelindung dengan fungsi terpisah sebelum menyeduhnya di kuali!",
		"required_items": {"gulamerah": 3, "asamjawa": 3, "air": 4},
		"result_item": "gepyokan",
		"result_item_name": "Gepyokan",
		"reward_gold": 50,
		"reward_exp": 200,
		"hint": "Cari NPC bernama Mbah Node\ndi kuburan kuno desa",
		"ghost_template": "FUNGSI Ekstrak_Manis(GulaMerah)\n    KEMBALIKAN Esensi_Manis\nAKHIR_FUNGSI\n\nFUNGSI Ekstrak_Pelindung(AsamJawa)\n    KEMBALIKAN Esensi_Tolak_Bala\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Gepyokan()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi_manis = Ekstrak_Manis(GulaMerah)\n    esensi_pelindung = Ekstrak_Pelindung(AsamJawa)\n    Campurkan(esensi_manis)\n    Campurkan(esensi_pelindung)\nAKHIR_PROSEDUR"
	}
}

var active_quest_id: int = 0
## quest_statuses diinisialisasi kosong; entri ditambah dinamis via set_quest_status/start_quest
var quest_statuses: Dictionary = {}

var current_gold: int = 0
var gold: int:
	get:
		return current_gold
	set(v):
		current_gold = v
var current_exp: int = 0
var current_level: int = 1


func _ready() -> void:
	pass


## ─────────────────────────────────────────────
## HELPER FUNCTIONS — akses data quest
## ─────────────────────────────────────────────

## Mengambil nama ramah pengguna dari ID item/bahan.
func get_item_display_name(item_id: String) -> String:
	var lower = item_id.to_lower()
	if ITEM_NAMES.has(lower):
		return ITEM_NAMES[lower]
	return item_id.capitalize()


## Mengambil path tekstur ikon dari ID item/bahan.
func get_item_icon_path(item_id: String) -> String:
	var lower = item_id.to_lower()
	return ITEM_ICONS.get(lower, "")


## Ambil data quest dari database berdasarkan ID.
## Mengembalikan Dictionary kosong jika tidak ditemukan.
func get_quest_data(quest_id: int) -> Dictionary:
	return QUEST_DATABASE.get(quest_id, {})


## Ambil data quest yang sedang aktif.
## Mengembalikan Dictionary kosong jika belum ada quest aktif.
func get_active_quest_data() -> Dictionary:
	return get_quest_data(active_quest_id)


## Mengambil daftar seluruh ID quest yang pernah diambil/dikerjakan pemain (urut ID).
func get_tracked_quest_ids() -> Array[int]:
	var list: Array[int] = []
	for q_id in QUEST_DATABASE.keys():
		var st = get_quest_status(q_id)
		if st != QuestStatus.NOT_STARTED or (active_quest_id > 0 and q_id == active_quest_id):
			if q_id > 0 and not list.has(q_id):
				list.append(q_id)
	list.sort()
	return list


## Cek apakah item hasil jamu quest tertentu sudah ada di tas (siap diserahkan).
func is_delivery_ready(quest_id: int) -> bool:
	var data: Dictionary = get_quest_data(quest_id)
	if data.is_empty():
		return false
	if not is_instance_valid(PlayerInventory):
		return false
	return PlayerInventory.has_item(data["result_item"])


## Mendapatkan ID quest berikutnya yang harus diambil pemain (1, 2, 3, atau 0 jika semua selesai)
func get_next_available_quest_id() -> int:
	var keys: Array = QUEST_DATABASE.keys()
	keys.sort()
	for q_id in keys:
		var st = get_quest_status(q_id)
		if st != QuestStatus.COMPLETED:
			return q_id
	return 0


## Mendapatkan petunjuk arah pencarian NPC untuk quest berikutnya
func get_current_guide() -> Dictionary:
	var next_id = get_next_available_quest_id()
	if next_id == 0:
		return {
			"title": "Selesai",
			"hint": "Semua pesanan selesai!\nDesa Syntaxia aman."
		}
	var data = get_quest_data(next_id)
	return {
		"title": "Petunjuk",
		"hint": data.get("hint", "Temui warga desa untuk menerima pesanan.")
	}


## ─────────────────────────────────────────────
## TOKO MPOK SINTAKS — HELPER EKONOMI
## ─────────────────────────────────────────────

## Mengambil daftar ID bahan yang diperdagangkan di toko (7 bahan herbal)
func get_shop_item_ids() -> Array[String]:
	return ["air", "beras", "serai", "gulamerah", "jahe", "asamjawa", "kencur"]


## Mengambil harga beli bahan (koin yang harus dibayar pemain)
func get_item_buy_price(item_id: String) -> int:
	var id = item_id.to_lower()
	if ITEM_PRICES.has(id):
		return ITEM_PRICES[id].get("buy", 0)
	return 0


## Mengambil harga jual bahan (koin yang didapat pemain saat menjual)
func get_item_sell_price(item_id: String) -> int:
	var id = item_id.to_lower()
	if ITEM_PRICES.has(id):
		return ITEM_PRICES[id].get("sell", 0)
	return 0


## ─────────────────────────────────────────────
## EXP & GOLD
## ─────────────────────────────────────────────

## Menghitung Max EXP untuk level tertentu:
## Level 1 → 100 EXP (naik ke level 2)
## Level 2 → 120 EXP (naik ke level 3)
## +20 per level
func get_max_exp_for_level(lvl: int) -> int:
	return 100 + (lvl - 1) * 20


## Menambahkan koin/gold ke pemain
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	current_gold += amount
	gold_changed.emit(current_gold)


## Mengurangi koin/gold jika cukup. Kembalikan true jika berhasil, false jika koin kurang.
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_gold < amount:
		return false
	current_gold -= amount
	gold_changed.emit(current_gold)
	return true


## Menambahkan exp ke pemain dan menangani kenaikan level dinamis
func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	current_exp += amount
	var max_exp: int = get_max_exp_for_level(current_level)

	while current_exp >= max_exp:
		current_exp -= max_exp
		current_level += 1
		max_exp = get_max_exp_for_level(current_level)
		level_up.emit(current_level)

	exp_changed.emit(current_exp, max_exp, current_level)


## ─────────────────────────────────────────────
## QUEST LIFECYCLE
## ─────────────────────────────────────────────

## Cek apakah quest boleh diambil (Quest berurutan: N butuh N-1 COMPLETED)
func can_start_quest(quest_id: int) -> bool:
	if quest_id <= 1:
		return true
	return get_quest_status(quest_id - 1) == QuestStatus.COMPLETED


## Memulai quest tertentu
func start_quest(quest_id: int) -> void:
	if not can_start_quest(quest_id):
		push_warning("Quest %d belum dapat diambil! Selesaikan Quest %d terlebih dahulu." % [quest_id, quest_id - 1])
		return
	active_quest_id = quest_id
	set_quest_status(quest_id, QuestStatus.IN_PROGRESS)


## Mengubah status quest dan memancarkan sinyal
func set_quest_status(quest_id: int, status: int) -> void:
	quest_statuses[quest_id] = status
	quest_state_changed.emit(quest_id, status)


## Mengambil status quest
func get_quest_status(quest_id: int) -> int:
	if quest_statuses.has(quest_id):
		return quest_statuses[quest_id]
	return QuestStatus.NOT_STARTED


## Menyelesaikan quest dan memberikan imbalan dari database
func complete_quest(quest_id: int) -> void:
	var data: Dictionary = get_quest_data(quest_id)
	set_quest_status(quest_id, QuestStatus.COMPLETED)
	if not data.is_empty():
		add_gold(data["reward_gold"])
		add_exp(data["reward_exp"])
