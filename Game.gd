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
var current_map_string : String
var env
var connected_players : Array = []

func set_screen(screen: String):
	close_current_screen()
	var n = load(SCREEN_PATH + screen).instance()
	add_child(n)
	self.current_screen = n

func close_current_screen():
	if is_instance_valid(current_screen):
		self.current_screen.hide()
		self.current_screen.queue_free()

func set_map(map: String):
	free_current_map()
	var n = load(MAP_PATH + map).instance()
	add_child(n)
	self.current_map = n
	self.current_map_string = map

func free_current_map():
	if is_instance_valid(current_map):
		self.current_map.hide()
		self.current_map.queue_free()

remote func set_guest_map(map: String):
	if get_tree().get_rpc_sender_id() == 1:
		set_map(map)

remote func close_guest_screen():
	if get_tree().get_rpc_sender_id() == 1:
		close_current_screen()

remote func register_connected_players(network_list):
	if get_tree().get_rpc_sender_id() != 1: return
	for peer in network_list:
		connected_players.append(peer)
		print(connected_players)

remote func register_player(player):
	# If the player is not me
	if player != get_tree().get_network_unique_id():
		connected_players.append(player)
		print(connected_players)

remote func deregister_guest_player(player):
	if get_tree().get_rpc_sender_id() == 1:
		deregister_player(player)

func deregister_player(player):
	print(str(player) + " disconnected.")
	connected_players.erase(player)

func spawn_self():
	var player = preload("res://Movement/Player.tscn").instance()
	var spawnpoint = Vector2.ZERO
	for child in current_map.get_children():
		if child.is_in_group("spawn"):
			spawnpoint = child.global_position
	player.global_position = spawnpoint
	current_map.add_child(player)

remote func spawn_guest_player():
	if get_tree().get_rpc_sender_id() == 1:
		spawn_self()

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
	rpc_id(peer, "close_guest_screen")
	rpc_id(peer, "set_guest_map", current_map_string)
	var netlist = []
	for player in get_tree().get_network_connected_peers():
		if player != peer:
			netlist.append(player)
	# Register Host to Guest
	netlist.append(get_tree().get_network_unique_id())
	# Register other players
	rpc_id(peer, "register_connected_players", netlist)
	
	# Let other players know of new player
	rpc("register_player", peer)
	# Make other players spawn the new player
	rpc("guest_spawn_puppet", peer, str(peer)) # TODO: Add Names
	# Register Guest to Host
	connected_players.append(peer)
	# Make Guest spawn their controllable player
	rpc_id(peer, "spawn_guest_player")
	# Make Guest spawn other players as puppets
	rpc_id(peer, "guest_spawn_puppets")
	# Spawn Player as Puppet
	spawn_puppet(peer, str(peer)) # TODO: Add Names

func spawn_puppet(id, name):
	var new_puppet = preload("res://Movement/PlayerOther.tscn").instance()
	new_puppet.set_displayname(name)
	new_puppet.set_name(str(id))
	# Position shouldn't matter
	current_map.add_child(new_puppet)

func spawn_puppets():
	for member in connected_players:
		spawn_puppet(member, str(member)) # TODO: Name Data

remote func guest_spawn_puppet(id, name):
	spawn_puppet(id, name)

remote func guest_spawn_puppets():
	spawn_puppets()

func destroy_puppet(id: int):
	for child in current_map.get_children():
		if child.name == str(id):
			child.free()

remote func guest_destroy_puppet(id: int):
	destroy_puppet(id)

func update_puppet_pos(id: int, pos: Vector2):
	for child in current_map.get_children():
		if child.name == str(id):
			child.global_position = pos

func update_puppet_anim(id: int, anim: String, speed):
	for child in current_map.get_children():
		if child.name == str(id):
			var sprite = child.get_node("Sprite")
			sprite.speed_scale = speed
			sprite.play(anim)
remote func guest_update_puppet_anim(id: int, anim: String, speed):
	update_puppet_anim(id, anim, speed)

master func player_anim_updated(anim: String, speed):
	var player_id = get_tree().get_rpc_sender_id()
	for player in get_tree().get_network_connected_peers():
		if player != player_id:
			rpc_id(player, "guest_update_puppet_anim", player_id, anim, speed)
	update_puppet_anim(player_id, anim, speed)

master func player_pos_updated(pos: Vector2):
	var puppet_id = get_tree().get_rpc_sender_id()
	for player in get_tree().get_network_connected_peers():
		if player != puppet_id:
			rpc_id(player, "guest_update_puppet_pos", puppet_id, pos)
	update_puppet_pos(puppet_id, pos)

remote func guest_update_puppet_pos(id: int, pos: Vector2):
	update_puppet_pos(id, pos)

func _on_peer_disconnected(peer):
	print(str(peer) + " disconnected.")
	rpc("deregister_guest_player", peer)
	rpc("guest_destroy_puppet", peer)
	deregister_player(peer)
	destroy_puppet(peer)

func _on_connected_to_server():
	self.set_screen("Network/ConnectionSucceeded.tscn")

func _on_connection_failed():
	self.set_screen("Network/ConnectionFailed.tscn")

func _on_server_disconnected():
	for child in current_map.get_children():
		if child.is_in_group("puppet") or child.is_in_group("player"):
			child.queue_free()
	self.free_current_map()
	self.set_screen("Network/TimedOut.tscn")
