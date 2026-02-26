class_name NoTwoTwelveTouchingRule
extends BoardRule

func get_rule_name() -> String:
	return "No 2 adjacent to 12"


func validate(coord: Vector2i,number: int, tile: TerrainTypes.Type,tile_map: Dictionary ,number_map: Dictionary) -> bool:
	if number != 2 and number != 12:
		return true

	for dir in HEX_DIRECTIONS:
		var neighbor = coord + dir
		if number_map.has(neighbor):
			var neighbor_num = number_map[neighbor]
			if neighbor_num == 2 or neighbor_num == 12:
				return false

	return true
