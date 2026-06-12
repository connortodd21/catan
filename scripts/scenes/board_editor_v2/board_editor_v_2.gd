extends Node2D

@export var terrain_database : TerrainDatabaseResource
@export var numbers_database : NumberDatabaseResource
@export var port_deck: PortDeck
@export var port_scene: PackedScene

@onready var board_tile_map: TileMapLayer = $editor/BoardView/BoardTileMap
@onready var board_view: Node2D = $editor/BoardView
@onready var camera_2d: Camera2D = $editor/BoardView/Camera2D
@onready var save_manager: SaveManager = $editor/SaveManager

var tileset_source_id = 0
var default_tile_atlas_coords : Vector2i = Vector2i(4,0)
var border_tile_atlas_coords : Vector2i = Vector2i(5,0)
var water_tile_atlas_coords : Vector2i = Vector2i(6,0)

@export var board_width := 9
@export var board_height := 9

@export var number_scale: float = 1.0
@export var number_offset: Vector2 = Vector2.ZERO

var tile_metadata_cache : TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, TileMetadata)
var number_metadata_cache : TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, NumberMetadata)
var port_metadata_cache : TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, PortMetadata)
var number_sprites: Dictionary = {}

func _ready() -> void:
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
				EditorState.SelectionType.PORT:
					place_port_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			match editor_state:
				EditorState.SelectionType.TERRAIN:
					remove_tile_at_mouse()
				EditorState.SelectionType.NUMBER:
					remove_number_at_mouse()
				EditorState.SelectionType.PORT:
					remove_port_at_mouse()


#############################################
### SIGNALS
#############################################
func connect_signals() -> void:
	EditorState.board_cleared.connect(_on_board_cleared)
	EditorState.board_saved.connect(_on_board_saved)
	EditorState.board_load.connect(_on_board_load)
	EditorState.board_generate_requested.connect(_on_board_generate)


func _on_board_cleared() -> void:
	clear_board()


func _on_board_saved() -> void:
	var serializer = BoardSerializer.new()
	var serialized_data = serializer.serialize_to_json(tile_metadata_cache, number_metadata_cache)
	save_manager.save_json_with_picker(serialized_data)


func _on_board_load() -> void:
	save_manager.load_json_file_with_picker(Callable(self, "_on_json_loaded"))


func _on_board_generate(config: GenerationConfig) -> void:
	var board : SerializedBoard = BoardGenerator.generate(config)
	clear_board()
	set_board(board)

#############################################
### TILE MAPS
#############################################
func is_cell_editable(cell: Vector2i) -> bool:
	return board_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords


func clear_board() -> void:
	clear_tiles()
	clear_numbers()
	clear_ports()


func clear_tiles() -> void:
	var used_cells = board_tile_map.get_used_cells()
	for cell in used_cells:
		if board_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords:
			board_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
	tile_metadata_cache.clear_cache()


func clear_numbers() -> void:
	for sprite: Sprite2D in number_sprites.values():
		sprite.queue_free()
	number_sprites.clear()
	number_metadata_cache.clear_cache()


func set_board(board: SerializedBoard) -> void:
	clear_board()
	for tile_entry in board.tiles:
		place_tile(Vector2i(tile_entry.x, tile_entry.y), tile_entry.type)
	for number_entry in board.numbers:
		place_number(Vector2i(number_entry.x, number_entry.y), number_entry.value[0])


func place_tile(axial: Vector2i, tile: TerrainTypes.Type) -> void:
	var offset = HexUtils.axial_to_offset(axial)
	board_tile_map.erase_cell(offset)
	board_tile_map.set_cell(offset,terrain_database.get_source_id(tile),terrain_database.get_atlas_coords(tile))
	tile_metadata_cache.set_val(axial, create_tile_metadata(tile))


func remove_tile(axial: Vector2i) -> void:
	var offset = HexUtils.axial_to_offset(axial)
	if is_cell_editable(offset):
		board_tile_map.erase_cell(offset)
		board_tile_map.set_cell(offset, tileset_source_id, default_tile_atlas_coords)
		tile_metadata_cache.evict(axial)


func place_number(hex_cell: Vector2i, number: int) -> void:
	if not NumberUtils.is_valid_number(number):
		return

	var tile_metadata : TileMetadata = tile_metadata_cache.get_val(hex_cell)
	if tile_metadata == null:
		return

	var number_metadata: NumberMetadata = number_metadata_cache.get_val(hex_cell)
	if number_metadata == null:
		number_metadata = create_number_metadata([])

	number_metadata.add_number(number, tile_metadata.get_terrain_type())
	number_metadata_cache.set_val(hex_cell, number_metadata)

	if number_sprites.has(hex_cell):
		number_sprites[hex_cell].queue_free()

	var sprite := Sprite2D.new()
	sprite.texture = numbers_database.get_texture(number)
	sprite.scale = Vector2(number_scale, number_scale)
	sprite.position = board_tile_map.map_to_local(HexUtils.axial_to_offset(hex_cell)) + number_offset
	sprite.z_index = 1
	board_view.add_child(sprite)
	number_sprites[hex_cell] = sprite


func remove_number(hex_cell: Vector2i, number: int) -> void:
	var metadata: NumberMetadata = number_metadata_cache.get_val(hex_cell)
	if metadata == null:
		return
	metadata.remove_number(number)
	if metadata.is_empty():
		number_metadata_cache.evict(hex_cell)
	else:
		number_metadata_cache.set_val(hex_cell, metadata)

	if number_sprites.has(hex_cell):
		number_sprites[hex_cell].queue_free()
		number_sprites.erase(hex_cell)

#############################################
### INPUT HANDLING
#############################################
func place_tile_at_mouse() -> void:
	var offset = board_tile_map.local_to_map(get_local_mouse_position())
	var axial = HexUtils.offset_to_axial(offset)
	var tile = EditorState.get_selected_tile()
	if is_cell_editable(offset) and tile != TerrainTypes.Type.UNKNOWN:
		place_tile(axial, tile)


func remove_tile_at_mouse() -> void:
	var offset = board_tile_map.local_to_map(get_global_mouse_position())
	var axial = HexUtils.offset_to_axial(offset)
	remove_tile(axial)


func place_number_at_mouse() -> void:
	var offset = board_tile_map.local_to_map(get_local_mouse_position())
	var axial = HexUtils.offset_to_axial(offset)

	var number = EditorState.get_selected_number()
	if NumberUtils.is_valid_number(number):
		place_number(axial, number)


func remove_number_at_mouse():
	var offset = board_tile_map.local_to_map(get_local_mouse_position())
	var axial = HexUtils.offset_to_axial(offset)

	var number = EditorState.get_selected_number()
	remove_number(axial, number)


func _is_water_cell(axial: Vector2i) -> bool:
	return board_tile_map.get_cell_atlas_coords(HexUtils.axial_to_offset(axial)) == water_tile_atlas_coords


func place_port_at_mouse() -> void:
	var port_type = EditorState.get_selected_port()
	if port_type == PortTypes.Type.UNKNOWN:
		return

	var mouse_local = get_local_mouse_position()
	var best_water_axial := Vector2i.ZERO
	var best_land_dir := -1
	var best_dist := INF

	for land_axial in tile_metadata_cache.get_keys():
		for d in range(6):
			var neighbor_axial = land_axial + HexUtils.HEX_DIRECTIONS[d]
			if _is_water_cell(neighbor_axial):
				var dir_water_to_land = (d + 3) % 6
				var water_center = board_tile_map.map_to_local(HexUtils.axial_to_offset(neighbor_axial))
				var edge_pos = water_center + HexUtils.EDGE_MIDPOINTS[(dir_water_to_land + 1) % 6]
				var dist = mouse_local.distance_to(edge_pos)
				if dist < best_dist:
					best_dist = dist
					best_water_axial = neighbor_axial
					best_land_dir = dir_water_to_land

	if best_land_dir == -1:
		return

	var port_def = _get_port_def(port_type)
	if port_def == null:
		return

	remove_port(best_water_axial)

	var port_node: Node2D = port_scene.instantiate()
	port_node.scale = Vector2.ONE * 0.5
	var water_center = board_tile_map.map_to_local(HexUtils.axial_to_offset(best_water_axial))
	var edge_mid = HexUtils.EDGE_MIDPOINTS[(best_land_dir + 1) % 6]
	port_node.position = water_center + edge_mid
	board_view.add_child(port_node)
	var edge_rotation = rad_to_deg(edge_mid.angle()) - 90.0
	port_node.setup(port_def.trade_rate, port_def.texture, edge_rotation)

	port_metadata_cache.set_val(best_water_axial, PortMetadata.new(port_type, best_land_dir, edge_rotation, port_node))


func remove_port_at_mouse() -> void:
	var mouse_local = get_local_mouse_position()
	var best_axial: Variant = null
	var best_dist := INF

	for axial in port_metadata_cache.get_keys():
		var metadata: PortMetadata = port_metadata_cache.get_val(axial)
		var water_center = board_tile_map.map_to_local(HexUtils.axial_to_offset(axial))
		var edge_pos = water_center + HexUtils.EDGE_MIDPOINTS[(metadata.direction + 1) % 6]
		var dist = mouse_local.distance_to(edge_pos)
		if dist < best_dist:
			best_dist = dist
			best_axial = axial

	if best_axial != null:
		remove_port(best_axial)


func remove_port(axial: Vector2i) -> void:
	var metadata: PortMetadata = port_metadata_cache.get_val(axial)
	if metadata == null:
		return
	metadata.node.queue_free()
	port_metadata_cache.evict(axial)


func clear_ports() -> void:
	for axial in port_metadata_cache.get_keys():
		var metadata: PortMetadata = port_metadata_cache.get_val(axial)
		if metadata != null:
			metadata.node.queue_free()
	port_metadata_cache.clear_cache()


func _get_port_def(port_type: PortTypes.Type) -> PortIconDefinition:
	for port_def in port_deck.ports:
		if port_def.resource_type == port_type:
			return port_def
	return null

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
	var board = SerializedBoard.new().from_dict(data)
	set_board(board)


func _on_board_loaded_tres(board: SerializedBoard) -> void:
	if board == null:
		return
	set_board(board)
