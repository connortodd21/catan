class_name BoardSerializer


const empty_board : Rect2i = Rect2i(0, 0, 0, 0)


func serialize_to_resource(board: TileMapLayer, tile_metadata_cache: TileMetadataCache) -> SerializedBoard:
	return build_serialized_board(board, tile_metadata_cache)


func serialize_to_json(board: TileMapLayer, tile_metadata_cache: TileMetadataCache) -> Dictionary:
	return build_serialized_board(board, tile_metadata_cache).to_dict()


# convert board data to SerializedBoard
func build_serialized_board(board: TileMapLayer, tile_metadata_cache: TileMetadataCache) -> SerializedBoard:
	var bounds = get_board_bounds(board, tile_metadata_cache)
	if bounds == empty_board:
		return null
	
	var serialized_board := SerializedBoard.new()
	serialized_board.size = bounds.size
	
	for cell in board.get_used_cells():
		if not bounds.has_point(cell):
			continue
		
		var x = cell.x
		var y = cell.y 
		var tile_metadata = tile_metadata_cache.get_metadata(cell)
		if tile_metadata:
			var terrain_type : TerrainTypes.Type = tile_metadata.get_terrain_type()
			if terrain_type and TileUtils.is_user_changed_tile(terrain_type):
				serialized_board.add_tile(x,y,terrain_type)
			
			var numbers : Array[int] = tile_metadata.get_numbers()
			if numbers != null:
				serialized_board.add_numbers(x,y,numbers)
	
	return serialized_board


# Find minimum rect which contains all user changes
func get_board_bounds(board: TileMapLayer, tile_metadata_cache: TileMetadataCache) -> Rect2i:
	var min_q = INF
	var max_q = -INF
	var min_r = INF
	var max_r = -INF
	
	for cell in board.get_used_cells():
		var tile_metadata = tile_metadata_cache.get_metadata(cell)
		if tile_metadata:
			var terrain_type = tile_metadata.get_terrain_type()
			if TileUtils.is_user_changed_tile(terrain_type):
				min_q = min(min_q, cell.x)
				max_q = max(max_q, cell.x)
				min_r = min(min_r, cell.y)
				max_r = max(max_r, cell.y)
	
	if min_q == INF:
		# No active tiles placed
		return empty_board
	
	return Rect2i(min_q, min_r, max_q - min_q + 1, max_r - min_r + 1)
