class_name GameSelect
extends Control

const BOARDS_DIR : String = "res://boards"

@onready var board_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BoardPanel/BoardScroll/BoardList
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartGameButton

var selected_board : SerializedBoard = null


func _ready() -> void:
	_generate_board_previews()


#############################################
### GAME CONFIG
#############################################
func _generate_game_config() -> GameConfig:
	var game_config : GameConfig = GameConfig.new()
	# board
	game_config.board = selected_board
	
	# expansions
	
	# house rules
	
	# victory points
	return game_config

#############################################
### EXPANSIONS
#############################################

#############################################
### HOUSE RULES
#############################################

#############################################
### BOARD PREVIEWS
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
	var board : SerializedBoard = FileUtils.load_json(BOARDS_DIR + "/" + path, SerializedBoard)

	var button : Button = Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 110)
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
	# TODO: fix this
	selected_board = button.get_child(0).get_child(0).get_board()
	start_button.disabled = selected_board.is_empty()


func _on_back_button_pressed() -> void:
	SignalBus.go_back_to_menu()


func _on_start_game_button_pressed() -> void:
	pass
