extends Node


# Menyimpan bahan yang sudah dikumpulkan.
# Format: { item_id: true }
# Max stack = 1 per item_id.
var items: Dictionary = {}

signal item_added(item_id: String)
signal item_removed(item_id: String)


## Menambahkan item ke inventory.
## Return true jika berhasil (item belum ada).
## Return false jika item sudah ada (stack penuh, max 1).
func add_item(item_id: String) -> bool:
	if has_item(item_id):
		return false
	items[item_id] = true
	item_added.emit(item_id)
	return true


## Mengecek apakah item sudah ada di inventory.
func has_item(item_id: String) -> bool:
	return items.has(item_id)


## Menghapus item dari inventory.
## Digunakan untuk crafting, pembelian, atau pengeluaran item.
func remove_item(item_id: String) -> void:
	if not has_item(item_id):
		return
	items.erase(item_id)
	item_removed.emit(item_id)


## Mengambil semua item_id yang ada di inventory.
func get_all_items() -> Array:
	return items.keys()


## Mengosongkan seluruh inventory.
func clear() -> void:
	items.clear()
