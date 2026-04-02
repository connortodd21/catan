extends Node

#############################################
### TURN SIGNALS
#############################################
signal player_changed(index: int)
func emit_player_changed(index: int) -> void:
	player_changed.emit(index)


signal phase_changed(phase: GamePhase.Phase)
func emit_phase_changed(phase: GamePhase.Phase) -> void:
	phase_changed.emit(phase)


#############################################
### HAND SIGNALS
#############################################
signal hand_changed()
func emit_hand_changed() -> void:
	hand_changed.emit()


#############################################
### ACTION SIGNALS
#############################################
signal action_button_pressed(type: ActionTypes.Type)
func emit_action_button_pressed(type: ActionTypes.Type) -> void:
	action_button_pressed.emit(type)



signal action_mode_entered(type: ActionTypes.Type)
func emit_action_mode_entered(type: ActionTypes.Type) -> void:
	action_mode_entered.emit(type)


signal action_cancelled()
func emit_action_cancelled() -> void:
	action_cancelled.emit()


signal action_executed(type: ActionTypes.Type, position: Vector2)
func emit_action_executed(type: ActionTypes.Type, position: Vector2) -> void:
	action_executed.emit(type, position)


#############################################
### DICE SIGNALS
#############################################
signal dice_rolled(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int)
func roll_dice(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int) -> void:
	dice_rolled.emit(die1, die2, total)
