extends Node

#############################################
### NAVIGATION SIGNALS
#############################################
signal back_to_menu
func go_back_to_menu() -> void:
	back_to_menu.emit()
