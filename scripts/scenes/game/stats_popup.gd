class_name StatsPopup
extends PopupPanel

const DICE_BAR_COLOR: Color = Color.STEEL_BLUE
const RESOURCE_COLORS: Dictionary = {
	ResourceTypes.Type.WOOD: Color(0.13, 0.55, 0.13),
	ResourceTypes.Type.BRICK: Color(0.70, 0.20, 0.10),
	ResourceTypes.Type.WHEAT: Color(0.96, 0.76, 0.05),
	ResourceTypes.Type.SHEEP: Color(0.56, 0.74, 0.56),
	ResourceTypes.Type.ROCK: Color(0.50, 0.50, 0.50),
}

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _dice_chart_container: HBoxContainer = $VBoxContainer/DiceStatsContainer/ChartContainer
@onready var _resource_chart_container: HBoxContainer = $VBoxContainer/ResourceStatsContainer/ResourceChartContainer
@onready var _player_resource_table_container: HBoxContainer = $VBoxContainer/PlayerResourcesContainer/PlayerResourcesTableContainer


func _ready() -> void:
	_header.set_close_callback(hide)
	_header.set_title("Stats")
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	add_theme_stylebox_override("panel", bg)


func _on_popup_hide() -> void:
	for child in _dice_chart_container.get_children():
		child.queue_free()
	for child in _resource_chart_container.get_children():
		child.queue_free()
	for child in _player_resource_table_container.get_children():
		child.queue_free()


func show_stats(stats: GameStats) -> void:
	_build_dice_chart(stats.dice)
	_build_resource_chart(stats.resources)
	_build_player_resource_table(stats.player_resources)
	popup_centered()
	reset_size.call_deferred()


func _build_dice_chart(dice_stats: DiceStats) -> void:
	var entries: Array[BarChart.Entry] = []
	for roll_total in range(2, 13):
		entries.append(BarChart.Entry.new(str(roll_total), dice_stats.get_roll_count(roll_total), DICE_BAR_COLOR))
	var chart := BarChart.new()
	chart.set_data(entries)
	_dice_chart_container.add_child(chart)


func _build_player_resource_table(player_resource_stats: PlayerResourceStats) -> void:
	var headers: Array[String] = []
	for resource in ResourceTypes.DISPLAY_ORDER:
		headers.append(ResourceTypes.type_to_str(resource))
	var rows: Array[Table.Row] = []
	for player: Player in player_resource_stats.get_players():
		var values: Array[int] = []
		for resource in ResourceTypes.DISPLAY_ORDER:
			values.append(player_resource_stats.get_resource_count(player, resource))
		rows.append(Table.Row.new(player.player_name, player.get_color(), values))
	var table := Table.new()
	table.set_data(headers, rows)
	_player_resource_table_container.add_child(table)


func _build_resource_chart(resource_stats: ResourceStats) -> void:
	var entries: Array[BarChart.Entry] = []
	for resource_type in ResourceTypes.DISPLAY_ORDER:
		entries.append(BarChart.Entry.new(
			ResourceTypes.type_to_str(resource_type),
			resource_stats.get_resource_count(resource_type),
			RESOURCE_COLORS.get(resource_type, Color.WHITE)
		))
	var chart := BarChart.new()
	chart.set_data(entries)
	_resource_chart_container.add_child(chart)
