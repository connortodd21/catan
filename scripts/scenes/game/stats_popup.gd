class_name StatsPopup
extends PopupPanel

const MAX_BAR_HEIGHT: int = 120
const BAR_WIDTH: int = 30
const BAR_COLOR: Color = Color.STEEL_BLUE

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _chart_container: HBoxContainer = $VBoxContainer/DiceStatsContainer/ChartContainer


func _ready() -> void:
	_header.set_close_callback(hide)
	_header.set_title("Stats")
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	add_theme_stylebox_override("panel", bg)


func show_stats(stats: GameStats) -> void:
	_build_dice_chart(stats.dice)
	popup_centered()
	reset_size.call_deferred()


func _build_dice_chart(dice_stats: DiceStats) -> void:
	for child in _chart_container.get_children():
		child.queue_free()

	var max_count := dice_stats.get_max_roll_count()

	for roll_total in range(2, 13):
		var count := dice_stats.get_roll_count(roll_total)
		var bar_height := int(count / float(max_count) * MAX_BAR_HEIGHT) if max_count > 0 else 0
		_chart_container.add_child(_build_column(roll_total, count, bar_height))


func _build_column(roll_total: int, count: int, bar_height: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(BAR_WIDTH, bar_height)
	bar.color = BAR_COLOR

	var number_label := Label.new()
	number_label.text = str(roll_total)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	column.add_child(count_label)
	column.add_child(bar)
	column.add_child(number_label)

	return column
