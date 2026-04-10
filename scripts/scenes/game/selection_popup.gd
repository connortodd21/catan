class_name SelectionPopup
extends PopupPanel

var _title_label: Label
var _options_container: VBoxContainer
var _on_selected_callback: Callable
var _remaining: int = 0
var _base_title: String = ""


func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	_title_label = Label.new()
	vbox.add_child(_title_label)

	_options_container = VBoxContainer.new()
	_options_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_options_container)


#############################################
### DISPLAY
#############################################
func show_selection(base_title: String, options: Array[Dictionary], callback: Callable, required_count: int = 1) -> void:
	_on_selected_callback = callback
	_remaining = required_count
	_base_title = base_title
	_refresh_title()
	_build_options(options)
	popup_centered()


func _build_options(options: Array[Dictionary]) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	for option in options:
		_options_container.add_child(_build_option_button(option))


func _build_option_button(option: Dictionary) -> Button:
	var button := Button.new()
	button.text = option.get("label", "")
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if option.has("texture"):
		button.icon = option.texture
	elif option.has("color"):
		var style := StyleBoxFlat.new()
		style.bg_color = option.color
		button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(_on_option_pressed.bind(option))
	return button


func _refresh_title() -> void:
	if _remaining > 1:
		_title_label.text = "%s (%d remaining)" % [_base_title, _remaining]
	else:
		_title_label.text = _base_title


#############################################
### SIGNALS
#############################################
func _on_option_pressed(option: Dictionary) -> void:
	_on_selected_callback.call(option.value)
	_remaining -= 1
	if _remaining <= 0:
		hide()
	else:
		_refresh_title()
