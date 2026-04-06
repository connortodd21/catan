class_name GameUtils


static func action_to_victory_points(action: ActionTypes.Type) -> int:
	match action:
		ActionTypes.Type.BUILD_SETTLEMENT, ActionTypes.Type.BUILD_CITY:
			return 1
		_:
			return 0
