extends Resource
class_name PortEntry

@export var x: int
@export var y: int
@export var type: PortTypes.Type
@export var direction: int

func _init(_x: int, _y: int, _type: PortTypes.Type, _direction: int) -> void:
	x = _x
	y = _y
	type = _type
	direction = _direction

func to_dict() -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}
