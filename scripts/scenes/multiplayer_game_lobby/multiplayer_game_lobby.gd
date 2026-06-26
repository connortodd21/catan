class_name MultiplayerGameLobby
extends CanvasLayer

@onready var back_button: Button = $MarginContainer/VBoxContainer/Header/BackButton
@onready var color_picker_popup: ColorPickerPopup = $MarginContainer/VBoxContainer/Body/PlayerPanel/ColorPickerPopup
@onready var config_panel: GameConfigPanel = $MarginContainer/VBoxContainer/Body/GameConfigPanel
@onready var lobby_label: Label = $MarginContainer/VBoxContainer/Header/LobbyLabel
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton

const NAME_DISPLAY = "NameDisplay"
const COLOR_DISPLAY = "ColorDisplay"

var _is_lobby_host: bool = false
var _lobby_manager: LobbyManager


func _ready() -> void:
	UISignals.color_selected_from_color_picker.connect(_on_color_selected_from_color_picker)


func init(lobby_manager: LobbyManager) -> void:
	_lobby_manager = lobby_manager
	lobby_label.text = "Lobby Code: " + _lobby_manager.get_lobby_code()
	start_button.disabled = true
	_build_player_list()
	NetworkSignals.lobby_member_joined.connect(_on_lobby_member_joined)
	NetworkSignals.lobby_member_left.connect(_on_lobby_member_left)
	NetworkSignals.lobby_destroyed.connect(_on_lobby_destroyed)
	NetworkSignals.lobby_player_updated.connect(_on_lobby_player_updated)
	NetworkSignals.lobby_config_updated.connect(_on_lobby_config_updated)


#############################################
### PLAYER LIST
#############################################
func _build_player_list() -> void:
	for player_steam_id: int in _lobby_manager.get_members_in_lobby():
		if player_steam_id == NetworkManager.local_steam_id:
			_add_player_row(player_steam_id)
		else:
			_add_opponent_row(player_steam_id)


func _add_player_row(player_steam_id: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.name = str(player_steam_id)
	hbox.add_theme_constant_override("separation", 8)

	var name_edit := LineEdit.new()
	name_edit.name = NAME_DISPLAY
	name_edit.text = _lobby_manager.get_player_name(player_steam_id)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(_on_player_name_changed)
	hbox.add_child(name_edit)

	var player_color_index := _lobby_manager.get_player_color(player_steam_id)
	var color_button := Button.new()
	color_button.name = COLOR_DISPLAY
	color_button.custom_minimum_size = Vector2(28, 28)
	var style := StyleBoxFlat.new()
	style.bg_color = Player.PALETTE[player_color_index].get_color() if player_color_index != -1 else Color.WHITE
	color_button.add_theme_stylebox_override("normal", style)
	color_button.pressed.connect(_on_color_button_pressed)
	hbox.add_child(color_button)

	player_list.add_child(hbox)


func _add_opponent_row(player_steam_id: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.name = str(player_steam_id)
	hbox.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.name = NAME_DISPLAY
	name_label.text = _lobby_manager.get_player_name(player_steam_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)

	var player_color_index := _lobby_manager.get_player_color(player_steam_id)
	var color_rect := ColorRect.new()
	color_rect.name = COLOR_DISPLAY
	color_rect.custom_minimum_size = Vector2(28, 28)
	color_rect.color = Player.PALETTE[player_color_index].get_color() if player_color_index != -1 else Color.WHITE
	hbox.add_child(color_rect)

	player_list.add_child(hbox)


func _update_player_row(player_steam_id: int) -> void:
	var row := player_list.get_node_or_null(str(player_steam_id))
	if not row:
		return
	var player_color_index := _lobby_manager.get_player_color(player_steam_id)
	var display_color : Color = Player.PALETTE[player_color_index].get_color() if player_color_index != -1 else Color.WHITE

	var name_display := row.get_node(NAME_DISPLAY)
	name_display.text = _lobby_manager.get_player_name(player_steam_id)

	# own player row uses a Button for color (clickable), opponents use ColorRect
	var color_display := row.get_node(COLOR_DISPLAY)
	if color_display is ColorRect:
		color_display.color = display_color
	elif color_display is Button:
		var style := StyleBoxFlat.new()
		style.bg_color = display_color
		color_display.add_theme_stylebox_override("normal", style)


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
	GameSelectSignals.game_config_changed.connect(_on_game_config_changed)


func setup_as_client() -> void:
	_is_lobby_host = false
	config_panel.interactive = false


#############################################
### SIGNALS
#############################################
func _on_color_button_pressed() -> void:
	var player_id := NetworkManager.local_steam_id
	var taken_colors: Array[int] = []
	for member_id: int in _lobby_manager.get_members_in_lobby():
		if member_id != player_id:
			var color := _lobby_manager.get_player_color(member_id)
			if color != -1:
				taken_colors.append(color)
	var swatches: Array[ColorPickerPopup.ColorSwatchData] = []
	for color_key: int in Player.PALETTE:
		if color_key not in taken_colors:
			swatches.append(ColorPickerPopup.ColorSwatchData.new(
				color_key,
				Player.PALETTE[color_key].get_color(),
				Player.PALETTE[color_key].get_name()
			))
	var player_row := player_list.get_node(str(player_id))
	var color_button := player_row.get_node(COLOR_DISPLAY)
	color_picker_popup.open(color_button.get_global_rect().position, swatches)


func _on_color_selected_from_color_picker(color_key: int) -> void:
	_lobby_manager.set_player_color(NetworkManager.local_steam_id, color_key)


func _on_player_name_changed(new_name: String) -> void:
	if new_name.is_empty():
		return
	# check if name is already taken
	for member_id: int in _lobby_manager.get_members_in_lobby():
		if member_id != NetworkManager.local_steam_id and _lobby_manager.get_player_name(member_id) == new_name:
			return
	_lobby_manager.set_player_name(NetworkManager.local_steam_id, new_name)


func _on_game_config_changed() -> void:
	var game_config := GameConfig.new()
	config_panel.apply_to_config(game_config)
	_lobby_manager.set_config(game_config)


func _on_lobby_config_updated(game_config: GameConfig) -> void:
	config_panel.load_from_config(game_config)


func _on_lobby_player_updated(player_steam_id: int) -> void:
	_update_player_row(player_steam_id)


func _on_lobby_member_joined(player_steam_id: int) -> void:
	_add_opponent_row(player_steam_id)


func _on_lobby_member_left(player_steam_id: int) -> void:
	_remove_player_row(player_steam_id)


func _on_lobby_destroyed() -> void:
	GlobalSignals.go_back_to_menu()


func _on_back_button_pressed() -> void:
	_lobby_manager.leave_lobby()
	GlobalSignals.go_back_to_menu()
