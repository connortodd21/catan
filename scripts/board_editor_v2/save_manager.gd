class_name SaveManager extends Node

var _pending_json: Dictionary
var _pending_board: SerializedBoard
var _mode: String = ""

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
	match _mode:
		"json":
			_save_json(path)
		"tres":
			_save_tres(path)
	
	_mode = ""


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


#############################################
### EXTERNAL SAVE METHODS
#############################################
func save_json_with_picker(json_data: Dictionary) -> void:
	_mode = "json"
	_pending_json = json_data
	file_dialog.clear_filters()
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.current_file = "board.json"
	file_dialog.popup_centered()


func save_tres_with_picker(board: SerializedBoard) -> void:
	_mode = "tres"
	_pending_board = board
	file_dialog.clear_filters()
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.current_file = "board.tres"
	file_dialog.popup_centered() 
