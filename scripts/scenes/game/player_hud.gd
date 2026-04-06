class_name PlayerHUD
extends Control

class HUDRow:
	var container: PanelContainer
	var score_label: Label
	var resource_label: Label
	var road_label: Label
	var army_label: Label
	var harbor_label: Label

@onready var player_list: VBoxContainer = $MarginContainer/PlayerList

var player_states: Array[PlayerState] = []
var _rows: Array[HUDRow] = []
var _active_index: int = 0
var _longest_road_holder_index: int = -1
var _largest_army_holder_index: int = -1
var _harbormaster_holder_index: int = -1


func init(_player_states: Array[PlayerState]) -> void:
	player_states = _player_states
	for i in player_states.size():
		var row := _add_row(player_states[i])
		_rows.append(row)
		player_states[i].hand.hand_add_remove.connect(func() -> void: _update_row(i))
	_register_signals()
	_refresh_highlights()


func set_active_player(index: int) -> void:
	_active_index = index
	_refresh_highlights()


func _add_row(state: PlayerState) -> HUDRow:
	var row := HUDRow.new()

	row.container = PanelContainer.new()
	row.container.name = "Row_%s" % state.get_name()
	var container := row.container

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.text = state.get_name()
	vbox.add_child(name_label)

	row.score_label = Label.new()
	row.score_label.text = "VP: 0"
	vbox.add_child(row.score_label)

	row.road_label = Label.new()
	row.road_label.text = "Road: 0"
	vbox.add_child(row.road_label)

	row.army_label = Label.new()
	row.army_label.text = "Army: 0"
	vbox.add_child(row.army_label)

	row.harbor_label = Label.new()
	row.harbor_label.text = "Harbor: 0"
	vbox.add_child(row.harbor_label)

	row.resource_label = Label.new()
	row.resource_label.text = "Resources: 0"
	vbox.add_child(row.resource_label)

	player_list.add_child(container)
	return row


func _update_row(index: int) -> void:
	var state := player_states[index]
	var row := _rows[index]
	row.score_label.text = "VP: %d" % state.score
	row.resource_label.text = "Resources: %d" % state.hand.robber_count()
	row.road_label.text = "Road: %d" % state.longest_road_length
	row.army_label.text = "Army: %d" % state.army_size
	row.harbor_label.text = "Harbor: %d" % state.harbormaster_count
	_refresh_title_highlights(index)


func _refresh_highlights() -> void:
	for i in _rows.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.35, 0.25, 1.0) if i == _active_index else Color(0.15, 0.15, 0.15, 1.0)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		_rows[i].container.add_theme_stylebox_override("panel", style)


func _refresh_title_highlights(index: int) -> void:
	var row := _rows[index]
	row.road_label.modulate = Color.YELLOW if index == _longest_road_holder_index else Color.WHITE
	row.army_label.modulate = Color.YELLOW if index == _largest_army_holder_index else Color.WHITE
	row.harbor_label.modulate = Color.YELLOW if index == _harbormaster_holder_index else Color.WHITE


#############################################
### SIGNALS
#############################################
func _register_signals() -> void:
	GameSignals.score_changed.connect(_on_score_changed)
	GameSignals.player_stats_changed.connect(_on_player_stats_changed)
	GameSignals.longest_road_holder_changed.connect(_on_longest_road_holder_changed)
	GameSignals.largest_army_holder_changed.connect(_on_largest_army_holder_changed)
	GameSignals.harbormaster_holder_changed.connect(_on_harbormaster_holder_changed)


func _on_score_changed(player_index: int, score: int) -> void:
	_rows[player_index].score_label.text = "VP: %d" % score


func _on_player_stats_changed(player_index: int) -> void:
	_update_row(player_index)


func _on_longest_road_holder_changed(player_index: int) -> void:
	var previous_holder : int = _longest_road_holder_index
	_longest_road_holder_index = player_index
	if previous_holder != -1:
		_refresh_title_highlights(previous_holder)
	_refresh_title_highlights(player_index)


func _on_largest_army_holder_changed(player_index: int) -> void:
	var previous_holder := _largest_army_holder_index
	_largest_army_holder_index = player_index
	if previous_holder != -1:
		_refresh_title_highlights(previous_holder)
	_refresh_title_highlights(player_index)


func _on_harbormaster_holder_changed(player_index: int) -> void:
	var previous_holder := _harbormaster_holder_index
	_harbormaster_holder_index = player_index
	if previous_holder != -1:
		_refresh_title_highlights(previous_holder)
	_refresh_title_highlights(player_index)
