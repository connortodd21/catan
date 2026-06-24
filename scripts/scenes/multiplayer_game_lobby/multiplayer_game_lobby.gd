class_name MultiplayerGameLobby
extends CanvasLayer

@onready var lobby_label: Label = $MarginContainer/VBoxContainer/Header/LobbyLabel
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList
@onready var color_picker_popup: PopupPanel = $MarginContainer/VBoxContainer/Body/PlayerPanel/ColorPickerPopup
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton
@onready var config_panel: GameConfigPanel = $MarginContainer/VBoxContainer/Body/GameConfigPanel

var _is_lobby_host: bool = false
var _lobby_manager: LobbyManager


func init(lobby_manager: LobbyManager) -> void:
	_lobby_manager = lobby_manager
	lobby_label.text = "Lobby Code: " + _lobby_manager.get_lobby_code()
	start_button.disabled = true
	_build_player_list()
	NetworkSignals.lobby_member_joined.connect(_on_lobby_member_joined)
	NetworkSignals.lobby_member_left.connect(_on_lobby_member_left)
	NetworkSignals.lobby_destroyed.connect(_on_lobby_destroyed)


#############################################
### PLAYER LIST
#############################################
func _build_player_list() -> void:
	for player_steam_id in _lobby_manager.get_members_in_lobby():
		_add_player_row(player_steam_id)


func _add_player_row(player_steam_id: int) -> void:
	var is_local := player_steam_id == NetworkManager.local_steam_id
	var hbox := HBoxContainer.new()
	hbox.name = str(player_steam_id)
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = _lobby_manager.get_player_name(player_steam_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(28, 28)
	color_rect.color = Player.PALETTE[_lobby_manager.get_player_color(player_steam_id)].get_color() if _lobby_manager.get_player_color(player_steam_id) != -1 else Color.WHITE
	hbox.add_child(color_rect)

	player_list.add_child(hbox)


func _remove_player_row(player_steam_id: int) -> void:
	var row := player_list.get_node_or_null(str(player_steam_id))
	if row:
		row.queue_free()


#############################################
### SETUP
#############################################
func setup_as_host() -> void:
	_is_lobby_host = true
	config_panel.interactive = true


func setup_as_client() -> void:
	_is_lobby_host = false
	config_panel.interactive = false


#############################################
### SIGNALS
#############################################
func _on_lobby_member_joined(player_steam_id: int) -> void:
	_add_player_row(player_steam_id)


func _on_lobby_member_left(player_steam_id: int) -> void:
	_remove_player_row(player_steam_id)


func _on_lobby_destroyed() -> void:
	GlobalSignals.go_back_to_menu()
