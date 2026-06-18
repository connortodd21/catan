class_name Table
extends GridContainer

class Row:
	var label: String
	var color: Color
	var values: Array[int]

	func _init(_label: String, _color: Color, _values: Array[int]) -> void:
		label = _label
		color = _color
		values = _values


@export var column_spacing: int = 16
@export var row_spacing: int = 4


func _ready() -> void:
	add_theme_constant_override("h_separation", column_spacing)
	add_theme_constant_override("v_separation", row_spacing)


func set_data(headers: Array[String], rows: Array[Row]) -> void:
	for child in get_children():
		child.free()

	columns = 1 + headers.size()

	var empty := Label.new()
	add_child(empty)
	for header in headers:
		var label := Label.new()
		label.text = header
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)

	for row in rows:
		var name_label := Label.new()
		name_label.text = row.label
		name_label.add_theme_color_override("font_color", row.color)
		add_child(name_label)

		for value in row.values:
			var cell := Label.new()
			cell.text = str(value)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(cell)
