class_name NoAdjacentSameNumberRule
extends BoardRule


func get_rule_name() -> String:
	return "No adjacent tiles with the same number"


func validate(coord: Vector2i,number: int, tile: TerrainTypes.Type,tile_map: Dictionary ,number_map: Dictionary) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if number_map.has(neighbor):
			if number_map[neighbor] == number:
				return false
	return true
