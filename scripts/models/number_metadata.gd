class_name NumberMetadata

var numbers : Array[int] = []


func _init(_numbers: Array[int]) -> void:
	numbers = _numbers


func add_number(number: int) -> void:
	numbers.append(number)


func remove_number(number: int) -> void:
	numbers.erase(number)


func get_numbers() -> Array[int]:
	return numbers


func is_empty() -> bool:
	return numbers.is_empty()


func _to_string() -> String:
	return "numbers %s" % [str(numbers)]
