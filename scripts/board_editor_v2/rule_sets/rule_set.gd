class_name RuleSet
extends Resource

@export var rules: Array[BoardRule] = []


func validate_rules(coord: Vector2i,number: int, tile: TerrainTypes.Type,tile_map: Dictionary ,number_map: Dictionary) -> bool:
	for rule in rules:
		if not rule.validate(coord, tile, number, tile_map, number_map):
			return false
	return true
