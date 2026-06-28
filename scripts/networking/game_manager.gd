class_name GameManager
extends Node

var local_player_index: int = 0

var _steam_id_to_player_index: Dictionary[int, int] = {}


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


func start_multiplayer_session() -> void:
	var peer := SteamMultiplayerPeer.new()
	peer.create_host()
	multiplayer.multiplayer_peer = peer


func join_multiplayer_session(host_steam_id: int) -> void:
	var peer := SteamMultiplayerPeer.new()
	peer.create_client(host_steam_id)
	multiplayer.multiplayer_peer = peer
