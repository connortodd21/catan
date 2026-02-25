class_name NumberMetadata

var numbers : Array[int] = []


func _init(_numbers: Array[int]) -> void:
	numbers = _numbers


#############################################
### INTERNAL METHODS
#############################################
func _set_to_single_number(number: int) -> void:
	numbers = [number]


#############################################
### PUBLIC METHODS
#############################################
func add_number(number: int, terrain_type: TerrainTypes.Type) -> void:
	if TileUtils.tile_supports_multiple_numbers(terrain_type):
		numbers.append(number)
	else:
		_set_to_single_number(number)


func remove_number(number: int) -> void:
	numbers.erase(number)


func get_numbers() -> Array[int]:
	return numbers


func is_empty() -> bool:
	return numbers.is_empty()


func _to_string() -> String:
	return "numbers %s" % [str(numbers)]
