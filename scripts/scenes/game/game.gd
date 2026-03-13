class_name Game
extends Node2D

@export var terrain_database: TerrainDatabaseResource
@export var number_database: NumberDatabaseResource
@export var game_config: GameConfig = null

@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap
@onready var numbers_tile_map: TileMapLayer = $BoardView/NumbersTileMap


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
	_render_numbers(board)
	_add_border(coord_to_tile)


func _render_numbers(board: SerializedBoard) -> void:
	for entry: NumberEntry in board.numbers:
		if entry.value.is_empty():
			continue
		var number := entry.value[0]
		if not number in number_database.get_keys():
			continue
		var offset := HexUtils.axial_to_offset(Vector2i(entry.x, entry.y))
		var number_cell := TileMapUtils.convert_hex_coords_to_number_coords(offset, board_tile_map, numbers_tile_map)
		numbers_tile_map.set_cell(
			number_cell,
			number_database.get_source_id(number),
			number_database.get_atlas_coords(number)
		)


func _add_border(coord_to_tile: Dictionary) -> void:
	var water_source := terrain_database.get_source_id(TerrainTypes.Type.DESERT)
	var water_atlas := terrain_database.get_atlas_coords(TerrainTypes.Type.DESERT)
	var border: Dictionary = {}
	for axial: Vector2i in coord_to_tile:
		for dir: Vector2i in HexUtils.HEX_DIRECTIONS:
			var neighbor := axial + dir
			if not coord_to_tile.has(neighbor) and not border.has(neighbor):
				border[neighbor] = true
	for axial: Vector2i in border:
		board_tile_map.set_cell(HexUtils.axial_to_offset(axial), water_source, water_atlas)
