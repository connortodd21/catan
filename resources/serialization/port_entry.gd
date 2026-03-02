extends Resource
class_name PortEntry

# axial q of the water tile the port sits on
@export var x: int
# axial r
@export var y: int
@export var type: PortTypes.Type
# 0-5 index into HEX_DIRECTIONS; direction FROM water tile TOWARD land tile
@export var direction: int


func _init(_x: int = 0, _y: int = 0, _type: PortTypes.Type = PortTypes.Type.UNKNOWN, _direction: int = 0) -> void:
	x = _x
	y = _y
	type = _type
	direction = _direction


func to_dict() -> Dictionary:
	return {"x": x, "y": y, "type": type, "direction": direction}
