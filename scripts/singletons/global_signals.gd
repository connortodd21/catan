extends Node

#############################################
### NAVIGATION SIGNALS
#############################################
signal back_to_menu
func go_back_to_menu() -> void:
	back_to_menu.emit()


#############################################
### GAME SIGNALS
#############################################
signal dice_rolled(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int)
func roll_dice(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int) -> void:
	dice_rolled.emit(die1, die2, total)
