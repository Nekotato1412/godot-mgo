extends KinematicBody2D

const speed : int = 32
var velocity : Vector2
var magnitude: Vector2
var direction = Vector2.DOWN

onready var sprite = $Sprite
onready var Game = get_node("/root/Game")

func set_sprite(to: String):
	var new_sprite = load(Game.SPRITE_PATH + to)
	sprite.set_sprite_frames(new_sprite)

func _physics_process(_delta):
	velocity = Vector2.ZERO
	
	# Horizonal Movement
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	# Vertical Movement
	var v_input = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	magnitude = Vector2(h_input, v_input)
	velocity = magnitude.normalized() * speed
	sprite.speed_scale = velocity.length() / 2
	
	if magnitude.length() > 0:
		direction = magnitude
	
	if velocity.length() > 0:
		sprite.play("walk_" + Game.direction_strings[direction])
		if Game.env == Game.Env.HOST:
			Game.rpc_unreliable("guest_update_puppet_anim", get_tree().get_network_unique_id(), "walk_" + Game.direction_strings[direction], sprite.speed_scale)
		else:
			Game.rpc_unreliable_id(1, "player_anim_updated", "walk_" + Game.direction_strings[direction], sprite.speed_scale)
	else:
		sprite.play("look_" + Game.direction_strings[direction])
		if Game.env == Game.Env.HOST:
			Game.rpc_unreliable("guest_update_puppet_anim", get_tree().get_network_unique_id(), "look_" + Game.direction_strings[direction], sprite.speed_scale)
		else:
			Game.rpc_unreliable_id(1, "player_anim_updated", "look_" + Game.direction_strings[direction], sprite.speed_scale)

	# warning-ignore:return_value_discarded
	move_and_slide(velocity)

	if Game.env == Game.Env.HOST:
		Game.rpc_unreliable("guest_update_puppet_pos", get_tree().get_network_unique_id(), self.global_position)
	else:
		Game.rpc_unreliable_id(1, "player_pos_updated", self.global_position)

# TODO: Network Animation Syncing
