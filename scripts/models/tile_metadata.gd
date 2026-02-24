class_name TileMetadata

var numbers : Array[int]
var terrain_type : TerrainTypes.Type


func _init(_numbers: Array[int], _terrain_type: TerrainTypes.Type) -> void:
	numbers = _numbers
	terrain_type = _terrain_type


func get_numbers() -> Array[int]:
	return numbers


func get_terrain_type() -> TerrainTypes.Type:
	return terrain_type


func _to_string() -> String:
	return "Numbers: %s | terrain_type %d" % [str(numbers), terrain_type]
