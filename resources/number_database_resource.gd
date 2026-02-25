class_name NumberDatabaseResource
extends Resource

@export var number_data: Array[NumberDataResource]

var numbers := {}

func _init():
	build_numbers_if_empty()


func build_numbers_if_empty():
	if numbers.is_empty():
		numbers.clear()
		for number in number_data:
			numbers[number.value] = number


func get_keys() -> Array:
	build_numbers_if_empty()
	return numbers.keys()


func get_texture(key: int) -> Texture2D:
	build_numbers_if_empty()
	return numbers.get(key).texture


func get_atlas_coords(key: int) -> Vector2i:
	build_numbers_if_empty()
	return numbers.get(key).atlas_coords


func get_source_id(key: int) -> int:
	build_numbers_if_empty()
	return numbers.get(key).source_id


func get_value(key: int) -> int:
	build_numbers_if_empty()
	return numbers.get(key).value


func get_key_from_atlas_coords(atlas_coords: Vector2i) -> int:
	build_numbers_if_empty()
	for number in numbers:
		if numbers[number].atlas_coords == atlas_coords:
			return number
	return -1
