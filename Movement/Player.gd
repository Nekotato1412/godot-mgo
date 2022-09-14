extends KinematicBody2D

const speed : int = 32
var velocity : Vector2
var magnitude: Vector2
var direction = Vector2.DOWN

onready var sprite = $Sprite
onready var Game = get_node("/root/Game")

# TODO: Host-sided Movement Code
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
	else:
		sprite.play("look_" + Game.direction_strings[direction])

	move_and_slide(velocity)
# TODO: Network-sided Movement Code

# TODO: Network Animation Syncing
