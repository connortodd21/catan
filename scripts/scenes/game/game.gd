class_name Game
extends Node2D

@export var terrain_database: TerrainDatabaseResource
@export var game_config: GameConfig = null

@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap


func _ready() -> void:
	if game_config:
		_render_board(game_config.board)


#############################################
### BOARD RENDERING
#############################################
func _render_board(board: SerializedBoard) -> void:
	var coord_to_tile: Dictionary = {}
	for tile: TileEntry in board.tiles:
		var axial := Vector2i(tile.x, tile.y)
		board_tile_map.set_cell(
			HexUtils.axial_to_offset(axial),
			terrain_database.get_source_id(tile.type),
			terrain_database.get_atlas_coords(tile.type)
		)
		coord_to_tile[axial] = true
	_add_border(coord_to_tile)


func _add_border(coord_to_tile: Dictionary) -> void:
	var water_source := terrain_database.get_source_id(TerrainTypes.Type.WATER)
	var water_atlas := terrain_database.get_atlas_coords(TerrainTypes.Type.WATER)
	var border: Dictionary = {}
	for axial: Vector2i in coord_to_tile:
		for dir: Vector2i in HexUtils.HEX_DIRECTIONS:
			var neighbor := axial + dir
			if not coord_to_tile.has(neighbor) and not border.has(neighbor):
				border[neighbor] = true
	for axial: Vector2i in border:
		board_tile_map.set_cell(HexUtils.axial_to_offset(axial), water_source, water_atlas)
