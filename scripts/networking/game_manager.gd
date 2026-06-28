class_name GameManager
extends Node

var local_player_index: int = 0

var _steam_id_to_player_index: Dictionary[int, int] = {}

var _game_start_steam_ids: Array[int] = []
var _game_start_config_dict: Dictionary = {}
var _expected_peer_count: int = 0
var _connected_peer_count: int = 0


func _ready() -> void:
	NetworkSignals.session_created.connect(_on_session_created)


func _on_session_created(host_steam_id: int) -> void:
	if host_steam_id != NetworkManager.local_steam_id:
		join_multiplayer_session(host_steam_id)


func set_player_mapping(steam_ids: Array[int]) -> void:
	for i: int in steam_ids.size():
		_steam_id_to_player_index[steam_ids[i]] = i


func get_player_index(steam_id: int) -> int:
	return _steam_id_to_player_index.get(steam_id, -1)


@rpc("authority", "reliable", "call_local")
func notify_game_start(steam_ids: Array[int], game_config_dict: Dictionary) -> void:
	set_player_mapping(steam_ids)
	local_player_index = get_player_index(NetworkManager.local_steam_id)
	var game_config := GameConfig.new()
	game_config.from_dict(game_config_dict)
	NetworkSignals.emit_game_starting(game_config)


func start_multiplayer_session(steam_ids: Array[int], game_config_dict: Dictionary) -> void:
	_game_start_steam_ids = steam_ids
	_game_start_config_dict = game_config_dict
	_expected_peer_count = steam_ids.size() - 1
	_connected_peer_count = 0
	var peer := SteamMultiplayerPeer.new()
	peer.create_host()
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)


func _on_peer_connected(_peer_id: int) -> void:
	_connected_peer_count += 1
	if _connected_peer_count == _expected_peer_count:
		multiplayer.peer_connected.disconnect(_on_peer_connected)
		notify_game_start.rpc(_game_start_steam_ids, _game_start_config_dict)


func join_multiplayer_session(host_steam_id: int) -> void:
	var peer := SteamMultiplayerPeer.new()
	peer.create_client(host_steam_id)
	multiplayer.multiplayer_peer = peer
