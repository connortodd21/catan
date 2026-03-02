extends Control

signal board_selected(path: String)
signal back_requested

const BOARDS_DIR := "res://boards/"

@onready var board_list: VBoxContainer = $VBoxContainer/ScrollContainer/BoardList


func _ready() -> void:
	_populate_board_list()


func _populate_board_list() -> void:
	var files := DirAccess.get_files_at(BOARDS_DIR)
	for file_name in files:
		if not file_name.ends_with(".json"):
			continue
		var button := Button.new()
		button.text = file_name.get_basename()
		var path := BOARDS_DIR + file_name
		button.pressed.connect(func(): board_selected.emit(path))
		board_list.add_child(button)


func _on_back_button_pressed() -> void:
	back_requested.emit()
