class_name GameSelect
extends CanvasLayer

@export var min_players: int = 3
@export var max_players: int = 4

@onready var config_panel: GameConfigPanel = $MarginContainer/VBoxContainer/Body/GameConfigPanel
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton
@onready var add_player_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/AddPlayerButton
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList
@onready var color_picker_popup: PopupPanel = $MarginContainer/VBoxContainer/Body/PlayerPanel/ColorPickerPopup

class PlayerRow:
	var color_rect: ColorRect

var players: Array[Player] = []
var player_rows: Array[PlayerRow] = []
var local_player_index: int = 0

var _popup_swatches: Dictionary = {}
var _picker_player: Player


func _ready() -> void:
	_build_color_picker_popup()
	_init_players()
	config_panel.board_changed.connect(_on_board_changed)


#############################################
### PLAYERS
#############################################
func _init_players() -> void:
	var local_player := Player.new()
	local_player.player_name = "Player 1"
	local_player.player_color = Player.PlayerColor.RED
	players.append(local_player)
	_add_player_row(local_player, true)


func _add_player_row(player: Player, is_local: bool) -> void:
	var row := PlayerRow.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	if is_local:
		var name_edit := LineEdit.new()
		name_edit.text = player.player_name
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.text_changed.connect(func(t: String) -> void: player.player_name = t)
		hbox.add_child(name_edit)
	else:
		var name_label := Label.new()
		name_label.text = player.player_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(28, 28)
	color_rect.color = player.get_color()
	row.color_rect = color_rect
	hbox.add_child(color_rect)

	if is_local:
		color_rect.gui_input.connect(_on_color_rect_input.bind(player, color_rect))

	player_rows.append(row)
	player_list.add_child(hbox)
	_update_start_button()


func _build_color_picker_popup() -> void:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	color_picker_popup.add_child(flow)
	for color_key: int in Player.PALETTE:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.tooltip_text = Player.PALETTE[color_key].get_name()
		swatch.pressed.connect(_on_swatch_pressed.bind(color_key))
		_popup_swatches[color_key] = swatch
		flow.add_child(swatch)


func _on_color_rect_input(event: InputEvent, player: Player, color_rect: ColorRect) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_picker_player = player
		_refresh_popup_swatches()
		color_picker_popup.popup(Rect2(color_rect.get_global_rect().position, Vector2.ZERO))


func _on_swatch_pressed(color_key: int) -> void:
	_picker_player.player_color = color_key as Player.PlayerColor
	color_picker_popup.hide()
	_refresh_color_rects()


func _refresh_color_rects() -> void:
	for i in players.size():
		player_rows[i].color_rect.color = players[i].get_color()


func _refresh_popup_swatches() -> void:
	var used_colors := players.map(func(p: Player) -> int: return p.player_color)
	for color_key: int in _popup_swatches:
		var swatch: Button = _popup_swatches[color_key]
		var c: Color = Player.PALETTE[color_key].get_color()
		var is_taken := color_key in used_colors and color_key != _picker_player.player_color
		swatch.visible = not is_taken
		var style := StyleBoxFlat.new()
		style.bg_color = c
		swatch.add_theme_stylebox_override("normal", style)
		swatch.add_theme_stylebox_override("hover", style)
		swatch.add_theme_stylebox_override("pressed", style)


#############################################
### CONFIG UPDATES
#############################################
func _generate_game_config() -> GameConfig:
	var config := GameConfig.new()
	config_panel.apply_to_config(config)
	for player in players:
		config.add_player(player)
	return config


func _update_start_button() -> void:
	var enough_players : bool = (players.size() >= min_players) and (players.size() <= max_players)
	enough_players = true
	var board_selected : bool = config_panel.selected_board != null
	start_button.disabled = (not enough_players) or (not board_selected)
	add_player_button.disabled = players.size() >= max_players
	if not enough_players:
		start_button.tooltip_text = "Must have either 3 or 4 players to start a game"
	elif not board_selected:
		start_button.tooltip_text = "Please select a board"

#############################################
### SIGNALS
#############################################

func _on_board_changed(_board: SerializedBoard) -> void:
	_update_start_button()


func _on_back_button_pressed() -> void:
	GlobalSignals.go_back_to_menu()


func _on_add_player_button_pressed() -> void:
	var used_colors := players.map(func(p: Player) -> int: return p.player_color)
	var next_color := Player.PlayerColor.RED
	for color_key: int in Player.PALETTE:
		if color_key not in used_colors:
			next_color = color_key as Player.PlayerColor
			break
	var player := Player.new()
	player.player_name = "Player %d" % (players.size() + 1)
	player.player_color = next_color
	players.append(player)
	_add_player_row(player, false)


func _on_start_game_button_pressed() -> void:
	var config = _generate_game_config()
	GameSelectState.start_game(config)
	visible = false
