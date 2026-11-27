extends Node


const COLLISION_MASK_PLAYER = 5

func _ready() -> void:
	# Make character playable
	var player:CharacterBody2D = get_parent()
	player.add_to_group("player")
	var human_controller = HumanController.new()
	human_controller.name = "HumanController"
	human_controller.add_to_group("player_controller")
	player.call_deferred("add_child",human_controller)
	player.set_collision_layer_value(COLLISION_MASK_PLAYER,true)
	
	# Assign player to camera
	for camera in get_tree().get_nodes_in_group("camera"):
		camera.target = player
	queue_free()
