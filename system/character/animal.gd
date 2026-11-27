@icon("../character/icon_character.png")
@tool
extends CharacterBody2D


signal teleported

enum Anim {IDLE,MOVING}

const IMAGE_SPEED := 6
const ANIMATION_DATA := {
	Anim.IDLE:[0],
	Anim.MOVING:[0,1],
}

@export var speed := 30.0
@export var acceleration := 600.0
@export var deceleration := 400.0

var anim:Anim = Anim.IDLE:
	set(v):
		if anim == v:
			return
		anim = v
		current_image = 0
		image_list = ANIMATION_DATA[anim]
		update_animation()
var direction := Vector2.DOWN:
	set(v):
		direction = v
		update_animation()
var image_list:PackedInt32Array = [0]:
	set(v):
		image_list = v
var current_image:= 0.0:
	set(v):
		current_image =  wrap(v,0,image_list.size())
		update_animation()
var move_vector:Vector2


@onready var sprite: Sprite2D = $Sprite


func update_animation():
	if sprite:
		sprite.frame_coords.x = current_image


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	current_image += IMAGE_SPEED*delta
	if move_vector.length():
		if move_vector.x != 0:
			sprite.flip_h = sign(move_vector.x) != -1
		velocity = velocity.move_toward(move_vector*speed,acceleration*delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO,deceleration*delta)
	if velocity.length() > 1.0:
		anim = Anim.MOVING
	else:
		anim = Anim.IDLE
	move_and_slide()
