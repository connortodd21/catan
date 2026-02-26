class_name NoSixEightTouchingRule
extends BoardRule

func get_rule_name() -> String:
	return "No 6 adjacent to 8"


func validate(coord: Vector2i,number: int, tile: TerrainTypes.Type,tile_map: Dictionary, number_map: Dictionary) -> bool:
	if number != 6 and number != 8:
		return true

	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if number_map.has(neighbor):
			var neighbor_num = number_map[neighbor]
			if neighbor_num == 6 or neighbor_num == 8:
				return false

	return true
