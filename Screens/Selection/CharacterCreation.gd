extends Control

export var sprite_options : PoolStringArray = ["", "", "", ""]
export var sprite_names : PoolStringArray = ["", "", "", ""]
export var current_selection = 0
const SPRITE_PATH = "res://assets/sprites/"

onready var left_field = $VBoxContainer/HBoxContainer/Options/field_left
onready var current = $VBoxContainer/HBoxContainer/Options/current
onready var right_field = $VBoxContainer/HBoxContainer/Options/field_right
onready var sprite_name = $VBoxContainer/sprite_name

var entered_name : String = ""
var chosen_sprite_name : String = ""

func _ready():
	# Init
	cycle_selection(0)

func cycle_selection(by: int):
	var new_selection = current_selection + by
	
	# Bounds checking and selection wrap
	if new_selection < 0:
		new_selection = sprite_options.size() - 1
	elif new_selection >= sprite_options.size():
		new_selection = 0
	
	var left = new_selection - 1
	if left < 0:
		left = sprite_options.size() - 1
	elif left >= sprite_options.size():
		left = 0
	
	var right = new_selection + 1
	if right < 0:
		right = sprite_options.size() - 1
	elif right >= sprite_options.size():
		right = 0

	var selection_tex : StreamTexture = load(SPRITE_PATH + sprite_options[new_selection])
	var left_tex : StreamTexture = load(SPRITE_PATH + sprite_options[left])
	var right_tex : StreamTexture = load(SPRITE_PATH + sprite_options[right])
	
	current.texture = selection_tex
	left_field.texture = left_tex
	right_field.texture = right_tex
	
	sprite_name.text = sprite_names[new_selection]
	
	current_selection = new_selection


func _on_Left_button_up():
	cycle_selection(-1)

func _on_Right_button_up():
	cycle_selection(1)


func _on_Use_button_up():
	# TODO: Networking Code & Handling Rejection
	chosen_sprite_name = sprite_names[current_selection]


func _on_Name_text_entered(new_text):
	# TODO: Networking code & Handling Rejection
	entered_name = new_text
