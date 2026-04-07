class_name CardManager
extends RefCounted

var action_manager: ActionManager
var turn_manager: TurnManager

var _handlers: Dictionary[CardTypes.Type, Callable] = {}
var _roads_remaining: int = 0


func init() -> void:
	GameSignals.action_executed.connect(_on_action_executed)


#############################################
### REGISTRATION
#############################################
func register_handler(type: CardTypes.Type, handler: Callable) -> void:
	_handlers[type] = handler


#############################################
### CARD PLAY
#############################################
func play_card(card: CardDefinition, player_state: PlayerState) -> void:
	player_state.hand.remove_card(card)
	if card.card_type in _handlers:
		_handlers[card.card_type].call()


#############################################
### CARD EFFECTS
#############################################
func begin_road_building() -> void:
	_roads_remaining = 2
	turn_manager.enter_card_play_phase()
	action_manager.force_action(ActionTypes.Type.BUILD_ROAD)


#############################################
### SIGNALS
#############################################
func _on_action_executed(action_type: ActionTypes.Type, _position: Vector2) -> void:
	if turn_manager.current_phase != GamePhase.Phase.PLAYING_CARD:
		return
	if action_type == ActionTypes.Type.BUILD_ROAD:
		_roads_remaining -= 1
		if _roads_remaining > 0:
			action_manager.force_action(ActionTypes.Type.BUILD_ROAD)
		else:
			turn_manager.advance_from_card_play()
