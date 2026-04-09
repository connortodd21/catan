class_name CostUtils

## Actions that are free to execute during the PLAYING_CARD phase.
## Actions not listed here may still have costs during card play.
static var _free_card_actions: Array[ActionTypes.Type] = [
	ActionTypes.Type.BUILD_ROAD,
]


static func is_free(action: ActionTypes.Type, phase: GamePhase.Phase) -> bool:
	if phase == GamePhase.Phase.SETUP:
		return true
	if phase == GamePhase.Phase.PLAYING_CARD:
		return action in _free_card_actions
	return false
