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
		"ghost_template": "FUNGSI Ekstrak_Panas(Jahe, Sereh)\n    KEMBALIKAN Esensi_Hangat\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Wedang_Jahe()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Panas(Jahe, Sereh)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
	},
	2: {
		"id": 2,
		"title": "Quest 2: Pemulih Tenaga Bara",
		"short_name": "Beras Kencur",
		"client": "Bara (Pejuang yang Kelelahan)",
		"client_short": "Bara",
		"story": "Bara kelelahan setelah latihan tempur seharian. Racikkan Beras Kencur agar tenaganya pulih kembali!",
		"required_items": {"kencur": 1, "beras": 1, "air": 1},
		"result_item": "beraskencur",
		"result_item_name": "Beras Kencur",
		"reward_gold": 20,
		"reward_exp": 120,
		"ghost_template": "FUNGSI Ekstrak_Stamina(Kencur, Beras)\n    KEMBALIKAN Esensi_Vitalitas\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Beras_Kencur()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Stamina(Kencur, Beras)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
	},
	3: {
		"id": 3,
		"title": "Quest 3: Tolak Bala Mbah Node",
		"short_name": "Gepyokan",
		"client": "Mbah Node (Sesepuh Desa)",
		"client_short": "Mbah Node",
		"story": "Mbah Node membutuhkan ramuan Gepyokan untuk ritual tolak bala desa. Racikkan segera sebelum matahari terbenam!",
		"required_items": {"gulamerah": 1, "asamjawa": 1, "air": 1},
		"result_item": "gepyokan",
		"result_item_name": "Gepyokan",
		"reward_gold": 30,
		"reward_exp": 140,
		"ghost_template": "FUNGSI Ekstrak_Pelindung(GulaMerah, AsamJawa)\n    KEMBALIKAN Esensi_Tolak_Bala\nAKHIR_FUNGSI\n\nPROSEDUR Buat_Gepyokan()\n    Siapkan_Gelas()\n    Seduh_Air()\n    esensi = Ekstrak_Pelindung(GulaMerah, AsamJawa)\n    Campurkan(esensi)\nAKHIR_PROSEDUR"
	}
}

var active_quest_id: int = 0
## quest_statuses diinisialisasi kosong; entri ditambah dinamis via set_quest_status/start_quest
var quest_statuses: Dictionary = {}

var current_gold: int = 0
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

## Memulai quest tertentu
func start_quest(quest_id: int) -> void:
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
