class_name SaveManager extends Node

const JSON_FILE_TYPE = "json"
const TRES_FILE_TYPE = "tres"

var _pending_json: Dictionary
var _pending_board: SerializedBoard
var save_mode: String = ""

var _load_callback: Callable
var _load_mode: String = ""

@onready var file_dialog: FileDialog = FileDialog.new()


#############################################
### FILE PICKER [INTERNAL]
#############################################
func _ready():
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(_on_file_selected)


func _on_file_selected(path: String) -> void:
	if save_mode:
		match save_mode:
			JSON_FILE_TYPE:
				FileUtils.save_json(path, _pending_json)
			TRES_FILE_TYPE:
				FileUtils.save_tres(path, _pending_board)
		save_mode = ""
	
	if _load_mode:
		match _load_mode:
			JSON_FILE_TYPE:
				var json_data = FileUtils.load_json_as_dict(path)
				if _load_callback:
					_load_callback.call(json_data)
			TRES_FILE_TYPE:
				var board = FileUtils.load_tres(path)
				if _load_callback:
					_load_callback.call(board)
		_load_mode = ""


#############################################
### SAVE WITH PICKER
#############################################
func save_json_with_picker(json_data: Dictionary) -> void:
	save_mode = JSON_FILE_TYPE
	_pending_json = json_data
	file_dialog.clear_filters()
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.current_file = "board.json"
	file_dialog.popup_centered()


func save_tres_with_picker(board: SerializedBoard) -> void:
	save_mode = TRES_FILE_TYPE
	_pending_board = board
	file_dialog.clear_filters()
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.current_file = "board.tres"
	file_dialog.popup_centered() 


#############################################
### LOAD WITH PICKER
#############################################
func load_json_file_with_picker(callback: Callable) -> void:
	_load_mode = JSON_FILE_TYPE
	_load_callback = callback
	file_dialog.clear_filters()
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func load_tres_file_with_picker(callback: Callable) -> void:
	_load_mode = TRES_FILE_TYPE
	_load_callback = callback
	file_dialog.clear_filters()
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()
