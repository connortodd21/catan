class_name NoAdjacentSameTileRule
extends BoardRule


func get_rule_name() -> String:
	return "No adjacent tiles with the same resource"


func validate(coord: Vector2i,number: int,tile: TerrainTypes.Type,tile_map: Dictionary,number_map: Dictionary) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if tile_map.has(neighbor):
			if tile_map[neighbor] == tile:
				return false
	return true
