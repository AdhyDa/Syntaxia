extends Control

@onready var gold_label: Label = %GoldLabel
@onready var exp_bar: TextureProgressBar = %ExpBar
@onready var exp_label: Label = %ExpLabel

func _ready() -> void:
	# Set nilai awal saat game dimulai
	update_gold(0)
	update_exp(0, 100, 1)

# Fungsi untuk mengubah angka Gold
func update_gold(amount: int) -> void:
	gold_label.text = str(amount)

# Fungsi untuk mengubah Bar EXP dan Level
func update_exp(current_exp: int, max_exp: int, level: int = 1) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = current_exp
	exp_label.text = "LV. %d" % level
