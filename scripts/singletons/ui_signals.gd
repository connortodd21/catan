extends Node

signal color_selected_from_color_picker(color_key: int)
func emit_color_selected_from_color_picker(color_key: int) -> void:
	color_selected_from_color_picker.emit(color_key)
