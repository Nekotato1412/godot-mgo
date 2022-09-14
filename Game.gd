extends Node
# Handles Data, Netcode, and State management.
# Includes functions

# TODO: Host to Guest Syncing
# TODO: Guest to Host Syncing
# TODO: Error handling/Panic Messages
# TODO: Host Environment Data saving & loading
# TODO: UUID Generation

const SPRITE_PATH = "res://resources/sprite/"
const SCREEN_PATH = "res://Screens/"
const MAP_PATH = "res://Maps/"

enum Env {
	HOST,
	GUEST,
	NONE
}

var direction_strings = {
	Vector2.LEFT: "left",
	# Diagonal Left Up
	Vector2(-1, -1): "left",
	Vector2.RIGHT: "right",
	# Diagonal Right Up
	Vector2(1, -1): "right",
	Vector2.DOWN: "down",
	# Diagonal Right Down
	Vector2(1, 1): "down",
	Vector2.UP: "up",
	# Diagonal Left Down
	Vector2(-1, 1): "down"
}
var current_screen
var current_map
var env

func set_screen(screen: String):
	if self.current_screen:
		self.current_screen.hide()
		self.current_screen.queue_free()

	var n = load(SCREEN_PATH + screen).instance()
	add_child(n)
	self.current_screen = n

func close_current_screen():
	if self.current_screen:
		self.current_screen.hide()
		self.current_screen.queue_free()

func set_map(map: String):
	if self.current_map:
		self.current_map.hide()
		self.current_map.queue_free()
	var n = load(MAP_PATH + map).instance()
	add_child(n)
	self.current_map = n

func _ready():
	# When the game first starts
	# Warning: Game Class MUST BE ALWAYS LOADED. Do not use change_scene
	env = Env.NONE
	set_screen("TitleScreen.tscn")

func quit_game():
	get_tree().quit(0)

func create_network(port: int, maxPlayers: int):
	if env == Env.HOST:
		var host_peer = NetworkedMultiplayerENet.new()
		host_peer.create_server(port, maxPlayers - 1)
		get_tree().network_peer = host_peer
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_connected", self, "_on_peer_connected")
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	else:
		print("Dirty hacker.")

func join_network(ip, port: int):
	if env == Env.GUEST:
		var guest_peer = NetworkedMultiplayerENet.new()
		guest_peer.create_client(ip, port)
		get_tree().network_peer = guest_peer
# warning-ignore:return_value_discarded
		get_tree().connect("connected_to_server", self, "_on_connected_to_server")
# warning-ignore:return_value_discarded
		get_tree().connect("connection_failed", self, "_on_connection_failed")
# warning-ignore:return_value_discarded
		get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	else:
		print("Wut?")

func close_network():
	if env == Env.HOST:
		for peer in get_tree().get_network_connected_peers():
			rpc_unreliable_id(peer, "server_closed")
		get_tree().network_peer = null
	else:
		print("You can't do that.")

func destroy_network():
	get_tree().network_peer = null

func _on_peer_connected(peer):
	print(str(peer) + " connected.")

func _on_peer_disconnected(peer):
	print(str(peer) + " disconnected.")

func _on_connected_to_server():
	self.set_screen("Network/ConnectionSucceeded.tscn")

func _on_connection_failed():
	self.set_screen("Network/ConnectionFailed.tscn")

func _on_server_disconnected():
	self.set_screen("Network/TimedOut.tscn")
