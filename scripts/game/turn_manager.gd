class_name TurnManager
extends RefCounted



var current_player_index: int = 0
var current_phase: GamePhase.Phase = GamePhase.Phase.ROLL
var _player_count: int = 0


func start_game(player_count: int) -> void:
	_player_count = player_count
	current_player_index = 0
	_set_phase(GamePhase.Phase.ROLL)
	GameSignals.emit_player_changed(current_player_index)


func enter_setup_phase() -> void:
	_set_phase(GamePhase.Phase.SETUP)


func advance_from_roll() -> void:
	if current_phase != GamePhase.Phase.ROLL:
		return
	_set_phase(GamePhase.Phase.ACTION)


func enter_robber_phase() -> void:
	_set_phase(GamePhase.Phase.ROBBER)


func advance_from_robber() -> void:
	if current_phase != GamePhase.Phase.ROBBER:
		return
	_set_phase(GamePhase.Phase.ACTION)


func enter_card_play_phase() -> void:
	_set_phase(GamePhase.Phase.PLAYING_CARD)


func advance_from_card_play() -> void:
	if current_phase != GamePhase.Phase.PLAYING_CARD:
		return
	_set_phase(GamePhase.Phase.ACTION)


func end_turn() -> void:
	if current_phase != GamePhase.Phase.ACTION:
		return
	current_player_index = (current_player_index + 1) % _player_count
	GameSignals.emit_player_changed(current_player_index)
	_set_phase(GamePhase.Phase.ROLL)


func phase_name() -> String:
	return GamePhase.phase_to_string(current_phase)


func _set_phase(phase: GamePhase.Phase) -> void:
	current_phase = phase
	GameSignals.emit_phase_changed(phase)
