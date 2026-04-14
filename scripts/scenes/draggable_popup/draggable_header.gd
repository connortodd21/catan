class_name DraggableHeader
extends PanelContainer

@onready var _title_label: Label = $VBoxContainer/DragHandle/TitleLabel

var _dragging: bool = false
var _drag_start_pos: Vector2i = Vector2i.ZERO
var _drag_start_mouse: Vector2i = Vector2i.ZERO


func set_title(title_text: String) -> void:
	_title_label.text = title_text


#############################################
### SIGNALS
#############################################
func _on_drag_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_drag_start_pos = get_window().position
			_drag_start_mouse = DisplayServer.mouse_get_position()
	elif event is InputEventMouseMotion and _dragging:
		get_window().position = _drag_start_pos + (DisplayServer.mouse_get_position() - _drag_start_mouse)
