extends Control

onready var Game = get_node("/root/Game")

func _on_Back_button_up():
	Game.env = Game.Env.NONE
	Game.set_screen("TitleScreen.tscn")


func _on_Create_button_up():
	var port = int($VBoxContainer/Port.text)
	var max_players = int($VBoxContainer/Players/HScrollBar.value)
	Game.create_network(port, max_players)
	Game.close_current_screen()
	Game.set_map("Dungeon_Lobby.tscn")
