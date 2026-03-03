class_name BoardRule
extends Resource

const HEX_DIRECTIONS = [
	Vector2i(1,0), Vector2i(1,-1), Vector2i(0,-1),
	Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,1)
]


func get_rule_name() -> String:
	return ""


func validate(coord: Vector2i,number: int,tile: TerrainTypes.Type,tile_map: Dictionary,number_map: Dictionary) -> bool:
	return true
