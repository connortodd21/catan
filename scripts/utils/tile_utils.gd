class_name TileUtils

# custom data layer types
const TERRAIN_TYPE = "TERRAIN_TYPE"
const NUMBER_VALUE = "NUMBER_VALUE"

static func is_user_changed_tile(tile_type: TerrainTypes.Type) -> bool:
	return tile_type != TerrainTypes.Type.UNKNOWN and tile_type != TerrainTypes.Type.BORDER


static func tile_supports_multiple_numbers(tile_type: TerrainTypes.Type) -> bool:
	return tile_type == TerrainTypes.Type.FISH_2_3_11_12 or tile_type == TerrainTypes.Type.FISH_4_10


static func is_desert(tile_type: TerrainTypes.Type) -> bool:
	return tile_type == TerrainTypes.Type.DESERT
