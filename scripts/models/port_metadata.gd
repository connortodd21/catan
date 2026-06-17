class_name PortMetadata

var port_type: PortTypes.Type
var direction: int
var rotation_deg: float
var node: Node2D


func _init(_port_type: PortTypes.Type, _direction: int, _rotation_deg: float, _node: Node2D) -> void:
	port_type = _port_type
	direction = _direction
	rotation_deg = _rotation_deg
	node = _node


func _to_string() -> String:
	return "port_type %d direction %d" % [port_type, direction]
