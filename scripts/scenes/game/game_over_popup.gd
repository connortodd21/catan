class_name GameOverPopup
extends PopupPanel

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _winner_label: Label = $VBoxContainer/WinnerLabel
@onready var _standings_container: VBoxContainer = $VBoxContainer/StandingsContainer

var _exit_callback: Callable


func init(winner: PlayerState, standings: Array[PlayerState], exit_callback: Callable) -> void:
	_exit_callback = exit_callback
	_show_winner(winner)
	_build_standings(winner, standings)
	popup_centered()


#############################################
### DISPLAY
#############################################
func _show_winner(winner: PlayerState) -> void:
	_header.set_title("Game Over")
	_winner_label.text = "%s wins!" % winner.get_name()


func _build_standings(winner: PlayerState, standings: Array[PlayerState]) -> void:
	for child in _standings_container.get_children():
		child.queue_free()
	for player_state in standings:
		var panel := PanelContainer.new()
		if player_state == winner:
			var style := StyleBoxFlat.new()
			style.bg_color = Color.GOLD
			panel.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = player_state.get_name()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var score_label := Label.new()
		score_label.text = "%d VP" % player_state.score
		row.add_child(name_label)
		row.add_child(score_label)
		panel.add_child(row)
		_standings_container.add_child(panel)


#############################################
### SIGNALS
#############################################
func _on_exit_button_pressed() -> void:
	_exit_callback.call()
