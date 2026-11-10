@tool
extends Resource
class_name ResourceCollectible


## ID unik item. Digunakan sebagai key di PlayerInventory.
## Contoh: "grass", "herbal", "pot_shard"
@export var item_id: String = ""

## Nama tampilan item (untuk UI, tooltip, dsb.)
@export var display_name: String = ""

## Ikon item untuk ditampilkan di inventory atau HUD.
@export var icon: Texture2D
