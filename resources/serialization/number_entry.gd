extends Resource
class_name NumberEntry

@export var x: int
@export var y: int
@export var value: Array[int] = []

func _init(_x: int, _y: int, _value: Array[int]) -> void:
	x = _x
	y = _y
	value = _value

func to_dict() -> Dictionary:
	return {"x": x,"y": y,"value": value}
