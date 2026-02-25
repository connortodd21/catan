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


func get_texture(value: int) -> Texture2D:
	build_numbers_if_empty()
	return numbers.get(value).texture


func get_atlas_coords(value: int) -> Vector2i:
	build_numbers_if_empty()
	return numbers.get(value).atlas_coords


func get_source_id(value: int) -> int:
	build_numbers_if_empty()
	return numbers.get(value).source_id


func get_key_from_atlas_coords(atlas_coords: Vector2i) -> int:
	build_numbers_if_empty()
	for number in numbers:
		if numbers[number].atlas_coords == atlas_coords:
			return number
	return -1
