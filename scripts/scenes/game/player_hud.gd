class_name PlayerHUD
extends Control

class HUDRow:
	var container: PanelContainer
	var score_label: Label
	var resource_label: Label

@onready var player_list: VBoxContainer = $MarginContainer/PlayerList

var player_states: Array[PlayerState] = []
var _rows: Array[HUDRow] = []
var _active_index: int = 0


func init(_player_states: Array[PlayerState]) -> void:
	player_states = _player_states
	for i in player_states.size():
		var row := _add_row(player_states[i])
		_rows.append(row)
		player_states[i].hand.hand_add_remove.connect(func() -> void: _update_row(i))
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


func _refresh_highlights() -> void:
	for i in _rows.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.35, 0.25, 1.0) if i == _active_index else Color(0.15, 0.15, 0.15, 1.0)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		_rows[i].container.add_theme_stylebox_override("panel", style)
