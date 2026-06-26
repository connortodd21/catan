extends Node

#############################################
### GAME SELECT SIGNALS
#############################################
signal game_config_changed()
func emit_game_config_changed() -> void:
	game_config_changed.emit()

signal game_started(config: GameConfig)
func start_game(config: GameConfig) -> void:
	game_started.emit(config)
