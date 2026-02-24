extends Node2D

@export var terrain_database : TerrainDatabaseResource

@onready var board_editor_tile_map: TileMapLayer = $BoardEditorTileMap
@onready var camera_2d: Camera2D = $Camera2D
@onready var save_manager: Node2D = $SaveManager

var tileset_source_id = 0
var default_tile_atlas_coords : Vector2i = Vector2i(4,0)
var border_tile_atlas_coords : Vector2i = Vector2i(5,0)
@export var board_width := 9
@export var board_height := 9 

var tile_metadata_cache : TileMetadataCache = TileMetadataCache.new()

func _ready() -> void:
	connect_signals()


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
	var serialized_data = serializer.serialize_to_json(board_editor_tile_map, tile_metadata_cache)
	save_manager.save_json_with_picker(serialized_data)


func _on_board_load() -> void:
	save_manager.load_json_file_with_picker(Callable(self, "_on_json_loaded"))

#############################################
### TILE MAP
#############################################
func is_cell_editable(cell: Vector2i) -> bool:
	return board_editor_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords

func clear_board() -> void:
	var used_cells = board_editor_tile_map.get_used_cells()
	for cell in used_cells:
		if board_editor_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords:
			board_editor_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
	tile_metadata_cache.clear_cache()

func set_board(board: SerializedBoard) -> void:
	clear_board()
	print(board)
	for tile_entry in board.tiles:
		place_tile(Vector2i(tile_entry.x, tile_entry.y), tile_entry.type)


func place_tile(cell: Vector2i, tile: TerrainTypes.Type) -> void:
	board_editor_tile_map.erase_cell(cell)
	board_editor_tile_map.set_cell(cell, terrain_database.get_source_id(tile), terrain_database.get_atlas_coords(tile))
	tile_metadata_cache.add_to_cache(cell, create_tile_metadata(tile, []))
#############################################
### INPUT HANDLING
#############################################
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tile_at_mouse()


func place_tile_at_mouse():
	var cell = board_editor_tile_map.local_to_map(get_local_mouse_position())
	var tile = EditorState.get_selected_tile()
	if is_cell_editable(cell) and tile != TerrainTypes.Type.UNKNOWN:
		place_tile(cell, tile)

func remove_tile_at_mouse():
	var cell = board_editor_tile_map.local_to_map(get_global_mouse_position())
	if is_cell_editable(cell):
		board_editor_tile_map.erase_cell(cell)
		# reset to defalt
		board_editor_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
		tile_metadata_cache.evict(cell)

#############################################
### TileMetadata
#############################################
func create_tile_metadata(tile: TerrainTypes.Type, numbers: Array[int]) -> TileMetadata:
	return TileMetadata.new(numbers, tile)


#############################################
### LOAD CALLBACKS
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
