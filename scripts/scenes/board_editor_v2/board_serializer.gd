class_name BoardSerializer


const empty_board : Rect2i = Rect2i(0, 0, 0, 0)


func serialize_to_resource(board_cache: BoardCache) -> SerializedBoard:
	return build_serialized_board(board_cache)


func serialize_to_json(board_cache: BoardCache) -> Dictionary:
	return build_serialized_board(board_cache).to_dict()


# convert board data to SerializedBoard
func build_serialized_board(board_cache: BoardCache) -> SerializedBoard:

	var bounds = get_board_bounds(board_cache.tiles)
	if bounds == empty_board:
		return null

	var serialized_board := SerializedBoard.new()
	serialized_board.size = bounds.size

	for cell in board_cache.tiles.get_keys():
		if not bounds.has_point(cell):
			continue

		var tile_metadata: TileMetadata = board_cache.tiles.get_val(cell)
		if tile_metadata != null:
			var terrain_type: TerrainTypes.Type = tile_metadata.get_terrain_type()
			if terrain_type != null and TileUtils.is_user_changed_tile(terrain_type):
				serialized_board.add_tile(cell.x, cell.y, terrain_type)

	for cell in board_cache.numbers.get_keys():
		if not bounds.has_point(cell):
			continue

		var numbers_metadata: NumberMetadata = board_cache.numbers.get_val(cell)
		if numbers_metadata != null:
			var numbers = numbers_metadata.get_numbers()
			if numbers:
				serialized_board.add_numbers(cell.x, cell.y, numbers_metadata.get_numbers())

	for cell in board_cache.ports.get_keys():
		var port_metadata: PortMetadata = board_cache.ports.get_val(cell)
		if port_metadata != null:
			serialized_board.add_port(cell.x, cell.y, port_metadata.port_type, port_metadata.direction)

	return serialized_board


# Find minimum rect which contains all user changes
func get_board_bounds(tile_metadata_cache: TypedCache) -> Rect2i:
	var min_q = INF
	var max_q = -INF
	var min_r = INF
	var max_r = -INF

	for cell in tile_metadata_cache.get_keys():
		var tile_metadata = tile_metadata_cache.get_val(cell)
		if tile_metadata:
			var terrain_type = tile_metadata.get_terrain_type()
			if TileUtils.is_user_changed_tile(terrain_type):
				min_q = min(min_q, cell.x)
				max_q = max(max_q, cell.x)
				min_r = min(min_r, cell.y)
				max_r = max(max_r, cell.y)

	if min_q == INF:
		return empty_board

	return Rect2i(min_q, min_r, max_q - min_q + 1, max_r - min_r + 1)
