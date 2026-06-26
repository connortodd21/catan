class_name GameConfigPanel
extends HSplitContainer

const BOARDS_DIR: String = "res://boards"
const EXPANSION: String = "expansion"
const HOUSE_RULE: String = "house_rule"
const BOARD: String = "board"

@onready var board_list: VBoxContainer = $BoardPanel/BoardScroll/BoardList
@onready var expansions_list: VBoxContainer = $OptionsScroll/OptionsPanel/ExpansionList
@onready var house_rules_list: VBoxContainer = $OptionsScroll/OptionsPanel/HouseRuleList
@onready var victory_points_spinbox: SpinBox = $OptionsScroll/OptionsPanel/VictoryPointsRow/VictoryPointsSpinBox

signal board_changed(board: SerializedBoard)

var selected_board: SerializedBoard = null

var interactive: bool = true:
	set(value):
		interactive = value
		_set_controls_interactive(value)


func _ready() -> void:
	_generate_board_previews()
	_generate_expansions()
	_generate_house_rules()
	victory_points_spinbox.value_changed.connect(_on_victory_points_changed)


#############################################
### INTERACTIVE
#############################################
func _set_controls_interactive(value: bool) -> void:
	for button: BaseButton in board_list.get_children():
		button.disabled = not value
	for checkbox: CheckBox in expansions_list.get_children():
		checkbox.disabled = not value
	for checkbox: CheckBox in house_rules_list.get_children():
		checkbox.disabled = not value
	victory_points_spinbox.editable = value


#############################################
### CONFIG
#############################################
func load_from_config(config: GameConfig) -> void:
	for button: BaseButton in board_list.get_children():
		var board: SerializedBoard = button.get_meta(BOARD)
		var is_selected_board := config.board != null and board.equals(config.board)
		button.set_pressed_no_signal(is_selected_board)
		if is_selected_board:
			selected_board = board
	for checkbox: CheckBox in expansions_list.get_children():
		checkbox.set_pressed_no_signal(checkbox.get_meta(EXPANSION) in config.expansions)
	for checkbox: CheckBox in house_rules_list.get_children():
		checkbox.set_pressed_no_signal(checkbox.get_meta(HOUSE_RULE) in config.house_rules)
	victory_points_spinbox.value = config.victory_points


func apply_to_config(config: GameConfig) -> void:
	config.board = selected_board
	_set_selected_expansions(config)
	_set_selected_house_rules(config)
	config.victory_points = int(victory_points_spinbox.value)


func _set_selected_expansions(config: GameConfig) -> void:
	for checkbox: CheckBox in expansions_list.get_children():
		if checkbox.button_pressed:
			config.add_expansion(checkbox.get_meta(EXPANSION))


func _set_selected_house_rules(config: GameConfig) -> void:
	for checkbox: CheckBox in house_rules_list.get_children():
		if checkbox.button_pressed:
			config.add_house_rule(checkbox.get_meta(HOUSE_RULE))


#############################################
### UI GENERATION
#############################################
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
	var board: SerializedBoard = FileUtils.load_json(BOARDS_DIR + "/" + path, SerializedBoard)

	var button := Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 110)
	button.set_meta(BOARD, board)
	board_list.add_child(button)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	button.add_child(hbox)

	var preview := BoardPreview.new()
	preview.custom_minimum_size = Vector2(130, 90)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_board(board)
	hbox.add_child(preview)

	var label := Label.new()
	label.text = path.get_basename().to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)


func _generate_expansions() -> void:
	for expansion in ExpansionTypes.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = ExpansionTypes.DISPLAY_NAMES[expansion]
		checkbox.set_meta(EXPANSION, expansion)
		checkbox.button_pressed = false
		checkbox.toggled.connect(_on_option_toggled)
		expansions_list.add_child(checkbox)


func _generate_house_rules() -> void:
	for house_rule in HouseRules.DISPLAY_NAMES:
		var checkbox := CheckBox.new()
		checkbox.text = HouseRules.DISPLAY_NAMES[house_rule]
		checkbox.set_meta(HOUSE_RULE, house_rule)
		checkbox.button_pressed = false
		checkbox.toggled.connect(_on_option_toggled)
		house_rules_list.add_child(checkbox)


#############################################
### SIGNALS
#############################################
func _on_board_selected(button: BaseButton) -> void:
	selected_board = button.get_meta(BOARD)
	board_changed.emit(selected_board)
	GameSelectSignals.emit_game_config_changed()


func _on_option_toggled(_pressed: bool) -> void:
	GameSelectSignals.emit_game_config_changed()


func _on_victory_points_changed(_value: float) -> void:
	GameSelectSignals.emit_game_config_changed()
