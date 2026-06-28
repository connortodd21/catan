extends Node

#############################################
### LOBBY SIGNALS
#############################################
signal lobby_created(lobby_id: int, room_code: String)
func emit_lobby_created(lobby_id: int, room_code: String) -> void:
	lobby_created.emit(lobby_id, room_code)


signal lobby_create_failed()
func emit_lobby_create_failed() -> void:
	lobby_create_failed.emit()


signal lobby_joined(lobby_id: int)
func emit_lobby_joined(lobby_id: int) -> void:
	lobby_joined.emit(lobby_id)


signal lobby_join_failed(reason: String)
func emit_lobby_join_failed(reason: String) -> void:
	lobby_join_failed.emit(reason)


signal lobby_member_joined(player_steam_id: int)
func emit_lobby_member_joined(player_steam_id: int) -> void:
	lobby_member_joined.emit(player_steam_id)


signal lobby_member_left(player_steam_id: int)
func emit_lobby_member_left(player_steam_id: int) -> void:
	lobby_member_left.emit(player_steam_id)


signal lobby_destroyed()
func emit_lobby_destroyed() -> void:
	lobby_destroyed.emit()


signal lobby_player_updated(player_steam_id: int)
func emit_lobby_player_updated(player_steam_id: int) -> void:
	lobby_player_updated.emit(player_steam_id)


signal lobby_config_updated(game_config: GameConfig)
func emit_lobby_config_updated(game_config: GameConfig) -> void:
	lobby_config_updated.emit(game_config)


#############################################
### GAME SIGNALS
#############################################
signal session_created(host_steam_id: int)
func emit_session_created(host_steam_id: int) -> void:
	session_created.emit(host_steam_id)


signal game_starting(game_config: GameConfig)
func emit_game_starting(game_config: GameConfig) -> void:
	game_starting.emit(game_config)
