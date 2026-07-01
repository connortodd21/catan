extends Node2D

@export var game_config: GameConfig = null

@onready var game_client: GameClient = $GameClient
@onready var game_server: GameServer = $GameServer


func _ready() -> void:
	if not game_config:
		return
	game_server.init(game_config, game_client.board_tile_map)
	game_client.init(game_config, game_server.player_states)
	game_server.start_game()
