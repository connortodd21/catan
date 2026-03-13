class_name BoardRule
extends Resource

const HEX_DIRECTIONS = HexUtils.HEX_DIRECTIONS


func get_rule_name() -> String:
	return ""


func validate(coord: Vector2i,number: int,tile: TerrainTypes.Type,tile_map: Dictionary,number_map: Dictionary) -> bool:
	return true
