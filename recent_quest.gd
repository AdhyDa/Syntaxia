extends Control

@onready var label_title: Label = %LabelTitle
@onready var label_objectives: Label = %LabelObjective

func _ready() -> void:
	set_quest("Recent Quest", "- Jahe: 0/1\n- Gula Merah: 0/1")
	start_sway_animation()

func set_quest(title_text: String, objectives_text: String) -> void:
	label_title.text = "[ " + title_text.to_upper() + " ]"
	label_objectives.text = objectives_text

# Animasi ayunan lembut untuk papan gantung
func start_sway_animation() -> void:
	# Atur pivot ke tengah atas (posisi rantai gantung)
	pivot_offset = Vector2(size.x / 2, 0)
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Berayun ke kanan 1.5 derajat, lalu ke kiri -1.5 derajat secara berulang
	tween.tween_property(self, "rotation_degrees", 1.5, 2.0)
	tween.tween_property(self, "rotation_degrees", -1.5, 2.0)
