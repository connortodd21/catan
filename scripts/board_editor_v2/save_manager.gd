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
				_save_json(path)
			TRES_FILE_TYPE:
				_save_tres(path)
		save_mode = ""
	
	if _load_mode:
		match _load_mode:
			JSON_FILE_TYPE:
				var json_data = _load_json(path)
				if _load_callback:
					_load_callback.call(json_data)
			TRES_FILE_TYPE:
				var board = _load_tres(path)
				if _load_callback:
					_load_callback.call(board)
		_load_mode = ""


func _save_json(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_pending_json, "\t"))
		file.close()
	else:
		push_error("Failed to save JSON.")


func _save_tres(path: String) -> void:
	var err = ResourceSaver.save(_pending_board, path)
	if err != OK:
		push_error("Failed to save TRES: %s" % err)


func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if not data:
		return {}
	return data

func _load_tres(path: String) -> SerializedBoard:
	var board = ResourceLoader.load(path)
	if board is SerializedBoard:
		return board
	push_error("Failed to load TRES as SerializedBoard: %s" % path)
	return null

#############################################
### EXTERNAL SAVE FUNCTIONS
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
### EXTERNAL LOAD FUNCTIONS
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
