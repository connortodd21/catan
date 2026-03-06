extends Node

#############################################
### GAME SELECT SIGNALS
#############################################
signal game_started(config: GameConfig)
func start_game(config: GameConfig) -> void:
	config._debug_print()
	game_started.emit(config)
