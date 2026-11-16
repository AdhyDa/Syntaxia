@tool
extends McpTestSuite

func suite_name() -> String:
	return "quest_system"

var qm_instance: Node = null
var inv_instance: Node = null


func setup() -> void:
	# Jika Autoload belum ada di tree (misal saat dijalankan dari editor via test_run),
	# buat instance lokal dan pasang static reference jika diperlukan
	if QuestManager == null or not is_instance_valid(QuestManager):
		var qm_script = load("res://system/quest/quest_manager.gd")
		qm_instance = track(qm_script.new())
	if PlayerInventory == null or not is_instance_valid(PlayerInventory):
		var inv_script = load("res://system/inventory/player_inventory.gd")
		inv_instance = track(inv_script.new())


func test_quest_database_integrity() -> void:
	var qm = QuestManager if (QuestManager != null and is_instance_valid(QuestManager)) else qm_instance
	assert_true(qm != null, "QuestManager harus valid")
	
	# Verifikasi database quest memiliki Quest 1, 2, 3
	var q1 = qm.get_quest_data(1)
	assert_false(q1.is_empty(), "Quest 1 harus ada di database")
	assert_eq(q1.get("title"), "Quest 1: Pesanan Sang Pemula", "Judul Quest 1 harus cocok")
	assert_eq(q1.get("reward_gold"), 10, "Reward gold Quest 1 harus 10")
	assert_eq(q1.get("reward_exp"), 100, "Reward exp Quest 1 harus 100")
	
	var q2 = qm.get_quest_data(2)
	assert_false(q2.is_empty(), "Quest 2 harus ada di database")
	assert_eq(q2.get("short_name"), "Beras Kencur", "Short name Quest 2 harus Beras Kencur")
	
	var q3 = qm.get_quest_data(3)
	assert_false(q3.is_empty(), "Quest 3 harus ada di database")
	assert_eq(q3.get("short_name"), "Gepyokan", "Short name Quest 3 harus Gepyokan")


func test_item_display_names() -> void:
	var qm = QuestManager if (QuestManager != null and is_instance_valid(QuestManager)) else qm_instance
	assert_eq(qm.get_item_display_name("jahe"), "Jahe", "jahe -> Jahe")
	assert_eq(qm.get_item_display_name("serai"), "Sereh", "serai -> Sereh")
	assert_eq(qm.get_item_display_name("sereh"), "Sereh", "sereh -> Sereh")
	assert_eq(qm.get_item_display_name("air"), "Air", "air -> Air")
	assert_eq(qm.get_item_display_name("kencur"), "Kencur", "kencur -> Kencur")
	assert_eq(qm.get_item_display_name("gulamerah"), "Gula Merah", "gulamerah -> Gula Merah")
	assert_eq(qm.get_item_display_name("asamjawa"), "Asam Jawa", "asamjawa -> Asam Jawa")


func test_exp_and_level_up_math() -> void:
	var qm = QuestManager if (QuestManager != null and is_instance_valid(QuestManager)) else qm_instance
	# Rumus: Level 1 -> 100, Level 2 -> 120, Level 3 -> 140
	assert_eq(qm.get_max_exp_for_level(1), 100, "Max exp level 1 harus 100")
	assert_eq(qm.get_max_exp_for_level(2), 120, "Max exp level 2 harus 120")
	assert_eq(qm.get_max_exp_for_level(3), 140, "Max exp level 3 harus 140")
	assert_eq(qm.get_max_exp_for_level(4), 160, "Max exp level 4 harus 160")
	
	qm.current_exp = 0
	qm.current_level = 1
	qm.add_exp(100) # Naik ke level 2 dengan 0 sisa
	assert_eq(qm.current_level, 2, "Harus naik ke level 2")
	assert_eq(qm.current_exp, 0, "Sisa exp harus 0")
	
	qm.add_exp(130) # Butuh 120 untuk naik ke level 3, sisa 10
	assert_eq(qm.current_level, 3, "Harus naik ke level 3")
	assert_eq(qm.current_exp, 10, "Sisa exp harus 10")


func test_recipe_parser_quest_lock_and_validation() -> void:
	# Quest lock: quest id 0 atau bukan 1 harus ditolak
	var res0 = RecipeParser.validate_and_brew("code", 0)
	assert_false(res0.success, "Quest id 0 harus ditolak")
	
	# Kode kosong
	var res_empty = RecipeParser.validate_and_brew("", 1)
	assert_false(res_empty.success, "Kode kosong harus ditolak")
	
	# Bahan terlarang (misal beras di level 1)
	var res_forbidden = RecipeParser.validate_and_brew("FUNGSI Ekstrak_Panas(Jahe, Beras)", 1)
	assert_false(res_forbidden.success, "Bahan terlarang harus ditolak")
	
	# Valid code template
	var qm = QuestManager if (QuestManager != null and is_instance_valid(QuestManager)) else qm_instance
	var q1 = qm.get_quest_data(1)
	var valid_code = q1["ghost_template"]
	
	# Validasi struktur sintaks
	var res_valid = RecipeParser._validate_level_1(valid_code)
	# Jika bahan di inventory kurang (misal di test env), pesan harus menyebutkan bahan kurang (bukan syntax error)
	if not res_valid.success:
		assert_true("Bahan di tas kurang" in res_valid.message, "Harus gagal karena bahan tas kurang, bukan syntax error: " + res_valid.message)
	else:
		assert_true(res_valid.success, "Sintaks template quest 1 valid")
