class_name SelectionPopup
extends PopupPanel


class SelectionOption:
	var label: String
	var value: Variant
	var color: Color
	var texture: Texture2D

	func _init(p_label: String, p_value: Variant, p_color: Color = Color.BLACK, p_texture: Texture2D = null) -> void:
		label = p_label
		value = p_value
		color = p_color
		texture = p_texture


@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _options_container: HBoxContainer = $VBoxContainer/OptionsContainer

@export var icon_max_width: int = 60

var _on_selected_callback: Callable
var _remaining: int = 0
var _base_title: String = ""


#############################################
### DISPLAY
#############################################
func show_selection(base_title: String, options: Array[SelectionOption], callback: Callable, required_count: int = 1) -> void:
	_on_selected_callback = callback
	_remaining = required_count
	_base_title = base_title
	_refresh_title()
	_build_options(options)
	popup_centered()


func _build_options(options: Array[SelectionOption]) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	for option in options:
		_options_container.add_child(_build_option_button(option))


func _build_option_button(option: SelectionOption) -> Button:
	var button := Button.new()
	button.tooltip_text = option.label
	if option.texture != null:
		button.icon = option.texture
		button.add_theme_constant_override("icon_max_width", icon_max_width)
	elif option.color != Color.BLACK:
		var style := StyleBoxFlat.new()
		style.bg_color = option.color
		button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(_on_option_pressed.bind(option))
	return button


func _refresh_title() -> void:
	if _remaining > 1:
		_header.set_title("%s (%d remaining)" % [_base_title, _remaining])
	else:
		_header.set_title(_base_title)


#############################################
### SIGNALS
#############################################
func _on_option_pressed(option: SelectionOption) -> void:
	_on_selected_callback.call(option.value)
	_remaining -= 1
	if _remaining <= 0:
		hide()
	else:
		_refresh_title()
