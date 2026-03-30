class_name GameSelect
extends CanvasLayer

const BOARDS_DIR : String = "res://boards"
const EXPANSION : String = "expansion"
const HOUSE_RULE : String = "house_rule"
const BOARD : String = "board"

@onready var board_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BoardPanel/BoardScroll/BoardList
@onready var expansions_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/ExpansionList
@onready var house_rules_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/HouseRuleList
@onready var victory_points_spinbox: SpinBox = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/VictoryPointsRow/VictoryPointsSpinBox
@onready var start_button: Button = $MarginContainer/VBoxContainer/Body/PlayerPanel/StartGameButton
@onready var player_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/PlayerPanel/PlayerList

class PlayerRow:
	var color_buttons: Dictionary  # PlayerColor -> Button

var selected_board: SerializedBoard = null
var players: Array[Player] = []
var player_rows: Array[PlayerRow] = []
var local_player_index: int = 0


func _ready() -> void:
	_generate_board_previews()
	_generate_expansions()
	_generate_house_rules()
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
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

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

	vbox.add_child(hbox)

	# color picker — local player only
	if is_local:
		var color_row := HBoxContainer.new()
		color_row.add_theme_constant_override("separation", 4)
		for color_key: int in Player.PALETTE:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(28, 28)
			btn.tooltip_text = Player.PALETTE[color_key].get_name()
			btn.pressed.connect(func() -> void: _on_color_selected(player, color_key))
			row.color_buttons[color_key] = btn
			color_row.add_child(btn)
		vbox.add_child(color_row)

	player_rows.append(row)
	player_list.add_child(vbox)
	_refresh_color_buttons()


func _on_color_selected(player: Player, color_key: int) -> void:
	player.player_color = color_key as Player.PlayerColor
	_refresh_color_buttons()


func _refresh_color_buttons() -> void:
	var used_colors := players.map(func(p: Player) -> int: return p.player_color)
	var local_color: int = players[local_player_index].player_color
	var row := player_rows[local_player_index]
	for color_key: int in row.color_buttons:
		var is_selected := color_key == local_color
		var is_taken := color_key in used_colors and not is_selected
		var c: Color = Player.PALETTE[color_key].get_color()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(c.r, c.g, c.b, 0.3 if is_taken else 1.0)
		if is_selected:
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = Color.WHITE
		var btn: Button = row.color_buttons[color_key]
		btn.disabled = is_taken
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("disabled", style)


#############################################
### CONFIG UPDATES
#############################################
func _generate_game_config() -> GameConfig:
	var game_config : GameConfig = GameConfig.new()
	
	# board
	game_config.board = selected_board
	
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


#############################################
### SIGNALS
#############################################
func _on_board_selected(button: BaseButton) -> void:
	selected_board = button.get_meta(BOARD)
	if selected_board:
		start_button.disabled = false


func _on_back_button_pressed() -> void:
	GlobalSignals.go_back_to_menu()


func _on_start_game_button_pressed() -> void:
	var config = _generate_game_config()
	GameSelectState.start_game(config)
	visible = false
