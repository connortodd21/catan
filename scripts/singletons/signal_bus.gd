extends Node

#############################################
### GAME SELECT SIGNALS
#############################################
signal game_started(config: GameConfig)
func start_game(config: GameConfig) -> void:
	game_started.emit(config)

signal back_to_menu
func go_back_to_menu() -> void:
	back_to_menu.emit()
