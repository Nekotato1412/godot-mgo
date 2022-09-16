extends KinematicBody2D

onready var Game = get_node("/root/Game")

func set_sprite(to: String):
	var new_sprite = load(Game.SPRITE_PATH + "to")
	$Sprite.set_sprite_frames(new_sprite)

func set_displayname(to: String):
	$name.text = to
