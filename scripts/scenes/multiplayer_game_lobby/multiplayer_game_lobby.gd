class_name MultiplayerGameLobby
extends CanvasLayer

@onready var lobby_label: Label = $MarginContainer/VBoxContainer/Header/LobbyLabel
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList
@onready var color_picker_popup: PopupPanel = $MarginContainer/VBoxContainer/Body/PlayerPanel/ColorPickerPopup
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton
@onready var config_panel: GameConfigPanel = $MarginContainer/VBoxContainer/Body/GameConfigPanel

var _is_lobby_host: bool = false


func init_as_host(lobby_code: String) -> void:
	_is_lobby_host = true
	_set_lobby_code(lobby_code)
	config_panel.interactive = true
	start_button.disabled = true


func init_as_client(lobby_code: String) -> void:
	_is_lobby_host = false
	_set_lobby_code(lobby_code)
	config_panel.interactive = false
	start_button.disabled = true


func _set_lobby_code(lobby_code: String) -> void:
	lobby_label.text = "Lobby Code: " + lobby_code
