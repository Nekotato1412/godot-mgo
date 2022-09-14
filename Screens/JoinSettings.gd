extends Control


onready var Game = get_node("/root/Game")

func _on_Back_button_up():
	Game.env = Game.Env.NONE
	Game.set_screen("TitleScreen.tscn")

func _on_Connect_button_up():
	var port = int($VBoxContainer/Port.text)
	var ip = $VBoxContainer/IP.text
	Game.join_network(ip, port)
	Game.set_screen("Network/ConnectingStatus.tscn")
