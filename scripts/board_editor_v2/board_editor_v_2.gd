extends Node2D

@export var terrain_database : TerrainDatabaseResource
@export var numbers_database : NumberDatabaseResource


@onready var board_tile_map: TileMapLayer = $editor/BoardTileMap
@onready var numbers_tile_map: TileMapLayer = $editor/NumbersTileMap
@onready var camera_2d: Camera2D = $editor/Camera2D
@onready var save_manager: SaveManager = $editor/SaveManager

var tileset_source_id = 0
var default_tile_atlas_coords : Vector2i = Vector2i(4,0)
var border_tile_atlas_coords : Vector2i = Vector2i(5,0)
@export var board_width := 9
@export var board_height := 9 

var tile_metadata_cache : TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, TileMetadata)
var number_metadata_cache : TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, NumberMetadata)

func _ready() -> void:
	print("BoardEditor ready")
	print(global_position)
	print("Camera current:", camera_2d.is_current())
	connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var editor_state = EditorState.get_editor_state()
		if event.button_index == MOUSE_BUTTON_LEFT:
			match editor_state:
				EditorState.SelectionType.TERRAIN:
					place_tile_at_mouse()
				EditorState.SelectionType.NUMBER:
					place_number_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			match editor_state:
				EditorState.SelectionType.TERRAIN:
					remove_tile_at_mouse()
				EditorState.SelectionType.NUMBER:
					remove_number_at_mouse()


#############################################
### SIGNALS
#############################################
func connect_signals() -> void:
	EditorState.board_cleared.connect(_on_board_cleared)
	EditorState.board_saved.connect(_on_board_saved)
	EditorState.board_load.connect(_on_board_load)

func _on_board_cleared() -> void:
	clear_board()


func _on_board_saved() -> void:
	var serializer = BoardSerializer.new()
	var serialized_data = serializer.serialize_to_json(tile_metadata_cache, number_metadata_cache)
	save_manager.save_json_with_picker(serialized_data)


func _on_board_load() -> void:
	save_manager.load_json_file_with_picker(Callable(self, "_on_json_loaded"))

#############################################
### TILE MAPS
#############################################
func is_cell_editable(cell: Vector2i) -> bool:
	return board_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords

func clear_board() -> void:
	clear_tiles()
	clear_numbers()

func clear_tiles() -> void:
	var used_cells = board_tile_map.get_used_cells()
	for cell in used_cells:
		if board_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords:
			board_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
	tile_metadata_cache.clear_cache()

func clear_numbers() -> void:
	var used_cells = numbers_tile_map.get_used_cells()
	for cell in used_cells:
		numbers_tile_map.erase_cell(cell)
	number_metadata_cache.clear_cache()

func set_board(board: SerializedBoard) -> void:
	clear_board()
	for tile_entry in board.tiles:
		place_tile(Vector2i(tile_entry.x, tile_entry.y), tile_entry.type)
	for number_entry in board.numbers:
		place_number(Vector2i(number_entry.x, number_entry.y), number_entry.value[0])


func place_tile(cell: Vector2i, tile: TerrainTypes.Type) -> void:
	board_tile_map.erase_cell(cell)
	board_tile_map.set_cell(cell, terrain_database.get_source_id(tile), terrain_database.get_atlas_coords(tile))
	tile_metadata_cache.set_val(cell, create_tile_metadata(tile))


func remove_tile(cell: Vector2i) -> void:
	if is_cell_editable(cell):
		board_tile_map.erase_cell(cell)
		# reset to defalt
		board_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
		tile_metadata_cache.evict(cell)


func place_number(hex_cell: Vector2i, number: int) -> void:
	if not NumberUtils.is_valid_number(number):
		return

	var tile_metadata : TileMetadata = tile_metadata_cache.get_val(hex_cell)
	# can only place numbers if a tile is already present
	if tile_metadata == null:
		return
	
	var metadata: NumberMetadata = number_metadata_cache.get_val(hex_cell)
	if metadata == null:
		metadata = create_number_metadata([])
	
	metadata.add_number(number, tile_metadata.get_terrain_type())
	number_metadata_cache.set_val(hex_cell, metadata)

	var number_cell = TileMapUtils.convert_hex_coords_to_number_coords(hex_cell, board_tile_map, numbers_tile_map)
	numbers_tile_map.set_cell(number_cell,numbers_database.get_source_id(number),numbers_database.get_atlas_coords(number))


func remove_number(hex_cell: Vector2i, number: int) -> void:
	var metadata: NumberMetadata = number_metadata_cache.get_val(hex_cell)
	if metadata == null:
		return
	metadata.remove_number(number)
	if metadata.is_empty():
		number_metadata_cache.evict(hex_cell)
	else:
		number_metadata_cache.set_val(hex_cell, metadata)

	var number_cell = TileMapUtils.convert_hex_coords_to_number_coords(hex_cell, board_tile_map, numbers_tile_map)
	numbers_tile_map.erase_cell(number_cell)

#############################################
### INPUT HANDLING
#############################################
func place_tile_at_mouse() -> void:
	var cell = board_tile_map.local_to_map(get_local_mouse_position())
	var tile = EditorState.get_selected_tile()
	if is_cell_editable(cell) and tile != TerrainTypes.Type.UNKNOWN:
		place_tile(cell, tile)

func remove_tile_at_mouse() -> void:
	var cell = board_tile_map.local_to_map(get_global_mouse_position())
	remove_tile(cell)

func place_number_at_mouse() -> void:
	var cell = board_tile_map.local_to_map(get_local_mouse_position())
	var number = EditorState.get_selected_number()
	if NumberUtils.is_valid_number(number):
		place_number(cell, number)

func remove_number_at_mouse():
	var cell = board_tile_map.local_to_map(get_local_mouse_position())
	var number = EditorState.get_selected_number()
	remove_number(cell, number)

#############################################
### METADATA
#############################################
func create_tile_metadata(tile: TerrainTypes.Type,) -> TileMetadata:
	return TileMetadata.new(tile)

func create_number_metadata(numbers: Array[int]) -> NumberMetadata:
	return NumberMetadata.new(numbers)
#############################################
### FILE LOAD CALLBACKS
#############################################
func _on_json_loaded(data: Dictionary) -> void:
	if data.is_empty():
		return
	# Convert JSON dictionary back to SerializedBoard
	var board = SerializedBoard.new().from_dict(data)
	set_board(board)

func _on_board_loaded_tres(board: SerializedBoard) -> void:
	if board == null:
		return
	set_board(board)
