class_name SetupManager
extends RefCounted

var action_manager: ActionManager
var turn_manager: TurnManager
var board_state: BoardState

var _setup_order: Array[int] = []
var _setup_index: int = 0
var _rounds: int = 0
var _awaiting_road: bool = false
var _last_settlement_pos: Vector2 = Vector2.ZERO


func init(_action_manager: ActionManager, _turn_manager: TurnManager, _board_state: BoardState) -> void:
	action_manager = _action_manager
	turn_manager = _turn_manager
	board_state = _board_state
	GameSignals.piece_placed.connect(_on_piece_placed)


#############################################
### SETUP
#############################################
func begin(player_count: int, rounds: int = 2) -> void:
	_rounds = rounds
	_setup_order = _build_setup_order(player_count)
	_setup_index = 0
	_awaiting_road = false
	turn_manager.enter_setup_phase()
	_set_player(_setup_order[0])
	action_manager.force_action(ActionTypes.Type.BUILD_SETTLEMENT)


func record_last_settlement(pos: Vector2) -> void:
	_last_settlement_pos = pos


func is_last_round() -> bool:
	@warning_ignore("integer_division")
	var player_count : int = _setup_order.size() / _rounds
	return _setup_index >= (_rounds - 1) * player_count


func is_setup_road_valid(snapped_pos: Vector2) -> bool:
	return board_state.is_edge_adjacent_to_vertex(snapped_pos, _last_settlement_pos) \
		and board_state.get_edge_owner(snapped_pos).is_empty()


func _set_player(player_index: int) -> void:
	turn_manager.current_player_index = player_index
	GameSignals.emit_player_changed(player_index)


func _build_setup_order(player_count: int) -> Array[int]:
	var order: Array[int] = []
	for i in player_count:
		order.append(i)
	for i in range(player_count - 1, -1, -1):
		order.append(i)
	return order


#############################################
### SIGNALS
#############################################
func _on_piece_placed(piece_type: PieceTypes.Type, _world_pos: Vector2) -> void:
	if turn_manager.current_phase != GamePhase.Phase.SETUP:
		return

	if piece_type == PieceTypes.Type.SETTLEMENT:
		_awaiting_road = true
	elif piece_type == PieceTypes.Type.ROAD:
		_awaiting_road = false
		var was_last_round := is_last_round()
		_setup_index += 1
		if was_last_round:
			GameSignals.emit_setup_phase_ended_for_player(turn_manager.current_player_index, _last_settlement_pos)

	if _awaiting_road:
		action_manager.force_action(ActionTypes.Type.BUILD_ROAD)
	elif _setup_index < _setup_order.size():
		_set_player(_setup_order[_setup_index])
		action_manager.force_action(ActionTypes.Type.BUILD_SETTLEMENT)
	else:
		@warning_ignore("integer_division")
		turn_manager.start_game.call_deferred(_setup_order.size() / _rounds)
