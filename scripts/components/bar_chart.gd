class_name BarChart
extends HBoxContainer

class Entry:
	var label: String
	var count: int
	var color: Color

	func _init(_label: String, _count: int, _color: Color) -> void:
		label = _label
		count = _count
		color = _color


@export var max_bar_height: int = 120
@export var bar_width: int = 30
@export var bar_spacing: int = 15


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_theme_constant_override("separation", bar_spacing)


func set_data(entries: Array[Entry]) -> void:
	for child in get_children():
		child.queue_free()

	var max_count := 0
	for entry in entries:
		max_count = max(max_count, entry.count)

	for entry in entries:
		var bar_height := int(entry.count / float(max_count) * max_bar_height) if max_count > 0 else 0
		add_child(_build_column(entry.label, entry.count, bar_height, entry.color))


func _build_column(label: String, count: int, bar_height: int, color: Color) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(bar_width, bar_height)
	bar.color = color

	var name_label := Label.new()
	name_label.text = label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	column.add_child(count_label)
	column.add_child(bar)
	column.add_child(name_label)

	return column
