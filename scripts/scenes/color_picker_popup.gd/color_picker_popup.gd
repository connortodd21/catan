class_name ColorPickerPopup
extends PopupPanel

@onready var flow_container: FlowContainer = $MarginContainer/FlowContainer

class ColorSwatchData:
	var key: int
	var color: Color
	var name: String

	func _init(p_key: int, p_color: Color, p_name: String) -> void:
		key = p_key
		color = p_color
		name = p_name


func open(popup_position: Vector2, swatches: Array[ColorSwatchData]) -> void:
	for child in flow_container.get_children():
		child.queue_free()
	for entry in swatches:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(40, 40)
		swatch.tooltip_text = entry.name
		var style := StyleBoxFlat.new()
		style.bg_color = entry.color
		swatch.add_theme_stylebox_override("normal", style)
		swatch.pressed.connect(_on_swatch_pressed.bind(entry.key))
		flow_container.add_child(swatch)
	popup(Rect2(popup_position, Vector2.ZERO))


func _on_swatch_pressed(color_key: int) -> void:
	UISignals.emit_color_selected_from_color_picker(color_key)
	hide()
