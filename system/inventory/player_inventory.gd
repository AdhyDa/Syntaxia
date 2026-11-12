extends Node


## Path file penyimpanan persisten backend/database lokal pemain
const SAVE_PATH: String = "user://player_inventory.json"

## Maksimal stack per item collectible
const MAX_STACK: int = 5

## Menyimpan bahan yang sudah dikumpulkan.
## Format: { "item_id": int_jumlah }
var items: Dictionary = {}

signal item_added(item_id: String, new_amount: int)
signal item_removed(item_id: String, new_amount: int)
signal inventory_loaded()


func _ready() -> void:
	# Memastikan setiap sesi baru selalu bersih (data terhapus saat game ditutup/dibuka kembali)
	clear_saved_data()
	items.clear()
	inventory_loaded.emit()


func _notification(what: int) -> void:
	# Saat player menutup game (close window/exit), hapus seluruh data inventory
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		clear_saved_data()
		items.clear()


## Menambahkan item ke inventory.
## Return true jika berhasil ditambahkan (jumlah masih di bawah MAX_STACK).
## Return false jika sudah mencapai MAX_STACK (stack penuh: 5 buah).
func add_item(item_id: String, amount: int = 1) -> bool:
	var current: int = get_item_count(item_id)
	if current >= MAX_STACK:
		return false
	
	var to_add: int = min(amount, MAX_STACK - current)
	items[item_id] = current + to_add
	save_data()
	item_added.emit(item_id, items[item_id])
	return true


## Mengecek apakah item ada di inventory (jumlah > 0)
func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0


## Mengambil jumlah item saat ini
func get_item_count(item_id: String) -> int:
	if items.has(item_id):
		return int(items[item_id])
	return 0


## Mengecek apakah stack item sudah penuh (5 buah)
func is_stack_full(item_id: String) -> bool:
	return get_item_count(item_id) >= MAX_STACK


## Menghapus/mengurangi item dari inventory
func remove_item(item_id: String, amount: int = 1) -> bool:
	var current: int = get_item_count(item_id)
	if current < amount:
		return false
	
	var new_amount: int = current - amount
	if new_amount <= 0:
		items.erase(item_id)
		new_amount = 0
	else:
		items[item_id] = new_amount
		
	save_data()
	item_removed.emit(item_id, new_amount)
	return true


## Mengambil semua item yang ada di inventory beserta jumlahnya
func get_all_items() -> Dictionary:
	return items.duplicate()


## Mengosongkan seluruh inventory
func clear() -> void:
	items.clear()
	save_data()


## ====================================================================
## BACKEND / DATABASE PERSISTENCE (PENYIMPANAN DATA LOKAL)
## ====================================================================

## Menghapus file penyimpanan persisten dari disk (saat game ditutup)
func clear_saved_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Menyimpan data inventory ke disk
func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(items, "\t")
		file.store_string(json_string)
		file.close()
	else:
		push_error("Gagal menyimpan inventory ke: " + SAVE_PATH)


## Membaca data inventory dari disk saat game dimulai
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var content = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		items.clear()
		for key in parsed:
			var val = parsed[key]
			if val is bool:
				items[str(key)] = 1 if val else 0
			else:
				items[str(key)] = int(val)
		inventory_loaded.emit()
