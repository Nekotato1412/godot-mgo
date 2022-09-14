extends Control

onready var Game = get_node("/root/Game")

func _input(event):
	if event.is_action_released("ui_cancel"):
		Game.quit_game()

func _on_Host_button_up():
	Game.env = Game.Env.HOST
	Game.set_screen("GameSettings.tscn")


func _on_Join_button_up():
	Game.env = Game.Env.GUEST
	Game.set_screen("JoinSettings.tscn")
