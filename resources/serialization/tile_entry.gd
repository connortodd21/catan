extends Resource
class_name TileEntry

@export var x: int
@export var y: int
@export var type: TerrainTypes.Type

func _init(_x: int, _y: int, _type: TerrainTypes.Type) -> void:
	x = _x
	y = _y
	type = _type

func to_dict() -> Dictionary:
	return {"x": x,"y": y,"type": type}
