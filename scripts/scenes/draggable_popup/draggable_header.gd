class_name DraggableHeader
extends PanelContainer

@onready var _title_label: Label = $VBoxContainer/DragHandle/HBoxContainer/TitleLabel
@onready var _close_button: Button = $VBoxContainer/DragHandle/HBoxContainer/CloseButton

var _dragging: bool = false
var _drag_start_pos: Vector2i = Vector2i.ZERO
var _drag_start_mouse: Vector2i = Vector2i.ZERO
var _close_callback: Callable = Callable()


func set_title(title_text: String) -> void:
	_title_label.text = title_text


func set_close_callback(callback: Callable) -> void:
	_close_callback = callback
	_close_button.visible = true


func _on_close_button_pressed() -> void:
	if _close_callback.is_valid():
		_close_callback.call()


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
