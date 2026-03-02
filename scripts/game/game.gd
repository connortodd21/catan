extends Node2D

signal back_requested

@export var terrain_database: TerrainDatabaseResource
@export var numbers_database: NumberDatabaseResource

const WATER_SOURCE_ID := 0
const WATER_ATLAS_COORDS := Vector2i(4, 0)

@onready var terrain_tile_map: TileMapLayer = $BoardView/TerrainTileMap
@onready var numbers_tile_map: TileMapLayer = $BoardView/NumbersTileMap

var board_path: String = ""
var hex_graph: HexGraph


func _ready() -> void:
	if board_path != "":
		_load_board(board_path)


func _load_board(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Game: could not open board file: " + path)
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Game: failed to parse JSON from: " + path)
		return

	var board := SerializedBoard.new().from_dict(data)

	var land_coords: Array[Vector2i] = []
	for t in board.tiles:
		land_coords.append(Vector2i(t.x, t.y))

	var water_coords := WaterBorderGenerator.generate(land_coords)

	_render_board(board, water_coords)
	hex_graph = HexGraph.build(board, water_coords)
	print("HexGraph built — vertices: %d, edges: %d" % [hex_graph.vertices.size(), hex_graph.edges.size()])


func _render_board(board: SerializedBoard, water_coords: Array[Vector2i]) -> void:
	var terrain_keys := terrain_database.get_keys()
	var number_keys := numbers_database.get_keys()

	for coord in water_coords:
		var offset := HexUtils.axial_to_offset(coord)
		terrain_tile_map.set_cell(offset, WATER_SOURCE_ID, WATER_ATLAS_COORDS)

	for tile_entry in board.tiles:
		if tile_entry.type not in terrain_keys:
			continue
		var axial := Vector2i(tile_entry.x, tile_entry.y)
		var offset := HexUtils.axial_to_offset(axial)
		terrain_tile_map.set_cell(
			offset,
			terrain_database.get_source_id(tile_entry.type),
			terrain_database.get_atlas_coords(tile_entry.type)
		)

	for num_entry in board.numbers:
		if num_entry.value.is_empty() or num_entry.value[0] not in number_keys:
			continue
		var axial := Vector2i(num_entry.x, num_entry.y)
		var offset := HexUtils.axial_to_offset(axial)
		var number_cell := TileMapUtils.convert_hex_coords_to_number_coords(
			offset, terrain_tile_map, numbers_tile_map
		)
		numbers_tile_map.set_cell(
			number_cell,
			numbers_database.get_source_id(num_entry.value[0]),
			numbers_database.get_atlas_coords(num_entry.value[0])
		)


func _on_back_button_pressed() -> void:
	back_requested.emit()
