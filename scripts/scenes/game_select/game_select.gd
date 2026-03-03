class_name GameSelect
extends Control

const BOARDS_DIR : String = "res://boards"

@onready var board_list: VBoxContainer = $MarginContainer/VBoxContainer/Body/BoardPanel/BoardScroll/BoardList
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartGameButton

var selected_board_path: String = ""


func _ready() -> void:
	_generate_boards()


#############################################
### BOARDS
#############################################
func _generate_boards() -> void:
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

	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_group = button_group
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 110)
	btn.set_meta("path", path)
	board_list.add_child(btn)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	btn.add_child(hbox)

	var preview := BoardPreview.new()
	preview.custom_minimum_size = Vector2(130, 90)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_tiles(board)
	hbox.add_child(preview)

	var label := Label.new()
	label.text = path.get_basename().to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)


#############################################
### SIGNALS
#############################################
func _on_board_selected(btn: BaseButton) -> void:
	selected_board_path = btn.get_meta("path", "")
	start_button.disabled = selected_board_path.is_empty()


func _on_back_button_pressed() -> void:
	SignalBus.go_back_to_menu()


func _on_start_game_button_pressed() -> void:
	pass
