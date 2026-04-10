class_name GameSelect
extends CanvasLayer

const BOARDS_DIR : String = "res://boards"
const EXPANSION : String = "expansion"
const HOUSE_RULE : String = "house_rule"
const BOARD : String = "board"

@export var min_players: int = 3
@export var max_players: int = 4

@onready var board_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BoardPanel/BoardScroll/BoardList
@onready var expansions_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/ExpansionList
@onready var house_rules_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/HouseRuleList
@onready var victory_points_spinbox: SpinBox = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/VictoryPointsRow/VictoryPointsSpinBox
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton
@onready var add_player_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/AddPlayerButton
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList
@onready var color_picker_popup: PopupPanel = $MarginContainer/VBoxContainer/Body/PlayerPanel/ColorPickerPopup

class PlayerRow:
	var color_rect: ColorRect

var selected_board: SerializedBoard = null
var players: Array[Player] = []
var player_rows: Array[PlayerRow] = []
var local_player_index: int = 0

var _popup_swatches: Dictionary = {}
var _picker_player: Player


func _ready() -> void:
	_generate_board_previews()
	_generate_expansions()
	_generate_house_rules()
	_build_color_picker_popup()
	_init_players()


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
	var game_config : GameConfig = GameConfig.new()
	
	# board
	game_config.board = selected_board

	# players
	for player in players:
		game_config.add_player(player)

	# expansions
	_set_selected_expansions(game_config)

	# house rules
	_set_selected_house_rules(game_config)
	
	# victory points
	game_config.victory_points = int(victory_points_spinbox.value)
	
	return game_config


func _set_selected_expansions(game_config: GameConfig) -> void:
	for checkbox : CheckBox in expansions_list.get_children():
		if checkbox.button_pressed:
			game_config.add_expansion(checkbox.get_meta(EXPANSION))


func _set_selected_house_rules(game_config: GameConfig) -> void:
	for checkbox : CheckBox in house_rules_list.get_children():
		if checkbox.button_pressed:
			game_config.add_house_rule(checkbox.get_meta(HOUSE_RULE))

#############################################
### UI ELEMENT GENERATION
#############################################
func _generate_expansions() -> void:
	for expansion in ExpansionTypes.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = ExpansionTypes.DISPLAY_NAMES[expansion]
		checkbox.set_meta(EXPANSION, expansion)
		checkbox.button_pressed = false
		expansions_list.add_child(checkbox)


func _generate_house_rules() -> void:
	for house_rule in HouseRules.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = HouseRules.DISPLAY_NAMES[house_rule]
		checkbox.set_meta(HOUSE_RULE, house_rule)
		checkbox.button_pressed = false
		house_rules_list.add_child(checkbox)


func _generate_board_previews() -> void:
	var button_group := ButtonGroup.new()
	button_group.pressed.connect(_on_board_selected)

	var dir := DirAccess.open(BOARDS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name:
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				_create_board_preview(file_name, button_group)
			file_name = dir.get_next()
		dir.list_dir_end()


func _create_board_preview(path: String, button_group: ButtonGroup) -> void:
	var board : SerializedBoard = FileUtils.load_json(BOARDS_DIR + "/" + path, SerializedBoard)

	var button : Button = Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 110)
	button.set_meta(BOARD, board)
	board_list.add_child(button)

	var hbox : HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	button.add_child(hbox)

	var preview : BoardPreview = BoardPreview.new()
	preview.custom_minimum_size = Vector2(130, 90)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_board(board)
	hbox.add_child(preview)

	var label : Label = Label.new()
	label.text = path.get_basename().to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)


func _update_start_button() -> void:
	var enough_players : bool = (players.size() >= min_players) and (players.size() <= max_players)
	enough_players = true
	var board_selected : bool = selected_board != null
	start_button.disabled = (not enough_players) or (not board_selected)
	add_player_button.disabled = players.size() >= max_players
	if not enough_players:
		start_button.tooltip_text = "Must have either 3 or 4 players to start a game"
	elif not board_selected:
		start_button.tooltip_text = "Please select a board"

#############################################
### SIGNALS
#############################################

func _on_board_selected(button: BaseButton) -> void:
	selected_board = button.get_meta(BOARD)
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
