class_name GameSelect
extends Control

const BOARDS_DIR : String = "res://boards"
const EXPANSION : String = "expansion"
const HOUSE_RULE : String = "house_rule"
const BOARD : String = "board"

@onready var board_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BoardPanel/BoardScroll/BoardList
@onready var expansions_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/ExpansionList
@onready var house_rules_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/HouseRuleList
@onready var victory_points_spinbox: SpinBox = $MarginContainer/VBoxContainer/Body/OptionsScroll/OptionsPanel/VictoryPointsRow/VictoryPointsSpinBox
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartGameButton

var selected_board: SerializedBoard = null


func _ready() -> void:
	_generate_board_previews()
	_generate_expansions()
	_generate_house_rules()


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
		if checkbox.pressed:
			game_config.add_expansion(checkbox.get_meta(EXPANSION))


func _set_selected_house_rules(game_config: GameConfig) -> void:
	for checkbox : CheckBox in house_rules_list.get_children():
		if checkbox.pressed:
			game_config.add_house_rule(checkbox.get_meta(HOUSE_RULE))

#############################################
### UI ELEMENT GENERATION
#############################################
func _generate_expansions() -> void:
	for expansion in ExpansionTypes.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = ExpansionTypes.DISPLAY_NAMES[expansion]
		checkbox.set_meta(EXPANSION, expansion)
		expansions_list.add_child(checkbox)


func _generate_house_rules() -> void:
	for house_rule in HouseRules.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = HouseRules.DISPLAY_NAMES[house_rule]
		checkbox.set_meta(HOUSE_RULE, house_rule)
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
	hide()
