class_name TileMapUtils

static func convert_hex_coords_to_number_coords(hex_coords: Vector2i, board_map: TileMapLayer, numbers_map: TileMapLayer) -> Vector2i:
	# Convert hex cell → world position (center of hex)
	var world_pos = board_map.to_global(board_map.map_to_local(hex_coords))

	# Convert world → numbers tilemap local → square cell
	return numbers_map.local_to_map(numbers_map.to_local(world_pos))
