class_name LobbyManager
extends Node

const MAX_PLAYERS: int = 4
const LOBBY_CODE_PERMITTED_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const LOBBY_CODE_LENGTH: int = 6

const LOBBY_CODE = "lobby_code"
const LOBBY_CONFIG = "lobby_config"
const PLAYER_COLOR = "player_color"
const PLAYER_NAME = "player_name"

var _lobby_id: int = 0
var _lobby_code: String = ""


func _ready() -> void:
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_created.connect(_on_lobby_created)


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func create_lobby() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)


func join_lobby(lobby_code: String) -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list, CONNECT_ONE_SHOT)
	Steam.addRequestLobbyListStringFilter(LOBBY_CODE, lobby_code, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()


func leave_lobby() -> void:
	if _lobby_id != 0:
		Steam.leaveLobby(_lobby_id)
		_lobby_id = 0
		_lobby_code = ""


func get_lobby_code() -> String:
	return Steam.getLobbyData(_lobby_id, LOBBY_CODE)


func get_members_in_lobby() -> Array[int]:
	var members: Array[int] = []
	var num_members_in_lobby := Steam.getNumLobbyMembers(_lobby_id)
	for i in num_members_in_lobby:
		members.append(Steam.getLobbyMemberByIndex(_lobby_id, i))
	return members


func get_available_colors() -> Array[int]:
	var taken_colors: Array[int] = []
	for member_id: int in get_members_in_lobby():
		var player_color := get_player_color(member_id)
		if player_color != -1:
			taken_colors.append(player_color)
	var available_colors: Array[int] = []
	for color_index: int in Player.PlayerColor.values():
		if color_index not in taken_colors:
			available_colors.append(color_index)
	return available_colors


func set_config(game_config: GameConfig) -> void:
	Steam.setLobbyData(_lobby_id, LOBBY_CONFIG, JSON.stringify(game_config.to_dict()))


func set_player_name(player_steam_id: int, player_name: String) -> void:
	Steam.setLobbyMemberData(_lobby_id, PLAYER_NAME, player_name)
	NetworkSignals.emit_lobby_player_updated(player_steam_id)


func set_player_color(player_steam_id: int, color: int) -> void:
	Steam.setLobbyMemberData(_lobby_id, PLAYER_COLOR, str(color))
	NetworkSignals.emit_lobby_player_updated(player_steam_id)


func get_player_name(player_steam_id: int) -> String:
	return Steam.getLobbyMemberData(_lobby_id, player_steam_id, PLAYER_NAME)


func get_player_color(player_steam_id: int) -> int:
	var raw := Steam.getLobbyMemberData(_lobby_id, player_steam_id, PLAYER_COLOR)
	return int(raw) if raw != "" else -1


func _auto_assign_player_defaults() -> void:
	var my_id := NetworkManager.local_steam_id
	set_player_name(my_id, Steam.getPersonaName())
	var available_colors := get_available_colors()
	if not available_colors.is_empty():
		set_player_color(my_id, available_colors[0])


func _generate_lobby_code() -> String:
	var lobby_code := ""
	for i in LOBBY_CODE_LENGTH:
		lobby_code += LOBBY_CODE_PERMITTED_CHARS[randi() % LOBBY_CODE_PERMITTED_CHARS.length()]
	return lobby_code


#############################################
### SIGNALS
#############################################
func _on_lobby_match_list(lobbies: Array) -> void:
	if lobbies.is_empty():
		NetworkSignals.emit_lobby_join_failed("No lobby found with that code")
		return
	Steam.lobby_joined.connect(_on_steam_lobby_joined, CONNECT_ONE_SHOT)
	Steam.joinLobby(lobbies[0])


func _on_steam_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		NetworkSignals.emit_lobby_join_failed("Failed to join lobby")
		return
	_lobby_id = lobby_id
	_auto_assign_player_defaults()
	NetworkSignals.emit_lobby_joined(_lobby_id)


func _on_lobby_chat_update(lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int) -> void:
	if lobby_id != _lobby_id:
		return
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		NetworkSignals.emit_lobby_member_joined(changed_id)
	elif chat_state in [Steam.CHAT_MEMBER_STATE_CHANGE_LEFT, Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED]:
		NetworkSignals.emit_lobby_member_left(changed_id)
		if changed_id == Steam.getLobbyOwner(_lobby_id):
			NetworkSignals.emit_lobby_destroyed()


func _on_lobby_data_update(success: bool, lobby_id: int, member_id: int) -> void:
	if not success or lobby_id != _lobby_id or member_id != 0:
		return
	var config_json_string := Steam.getLobbyData(_lobby_id, LOBBY_CONFIG)
	if config_json_string.is_empty():
		return
	var game_config_dict = JSON.parse_string(config_json_string)
	if game_config_dict:
		var game_config := GameConfig.new()
		game_config.from_dict(game_config_dict)
		NetworkSignals.emit_lobby_config_updated(game_config)


func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != Steam.RESULT_OK:
		NetworkSignals.emit_lobby_create_failed()
		return
	_lobby_id = lobby_id
	_lobby_code = _generate_lobby_code()
	Steam.setLobbyData(_lobby_id, LOBBY_CODE, _lobby_code)
	_auto_assign_player_defaults()
	NetworkSignals.emit_lobby_created(_lobby_id, _lobby_code)
