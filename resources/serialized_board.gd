extends Resource
class_name SerializedBoard

# width/height of the playable board rectangle. We use this as the board is normalized at (0,0)
@export var size: Vector2i = Vector2i.ZERO 


var tiles: Array[TileEntry] = []
var numbers: Array[NumberEntry] = []
var metadata: Dictionary = {
	"version": 1
}

func add_tile(x: int, y: int, tile: TerrainTypes.Type) -> void:
	numbers.append(TileEntry.new(x, y, tile))


func add_numbers(x: int, y: int, value: Array[int]) -> void:
	numbers.append(NumberEntry.new(x, y, value))


func to_dict() -> Dictionary:
	return {
		"size": {
			"width": size.x,
			"height": size.y
		},
		"tiles": tiles.map(func(tile): return tile.to_dict()),
		"numbers": numbers.map(func(num): return num.to_dict()),
		"metadata": metadata
	}


class TileEntry:
	var x: int
	var y: int
	var type: TerrainTypes.Type
	
	func _init(_x: int, _y: int, _type: TerrainTypes.Type) -> void:
		x = _x
		y = _y
		type = _type
	
	func to_dict() -> Dictionary:
		return {"x": x,"y": y,"type": type}


class NumberEntry:
	var x: int
	var y: int
	var value: Array[int]
	
	func _init(_x: int, _y: int, _value: Array[int]) -> void:
		x = _x
		y = _y
		value = _value
	
	func to_dict() -> Dictionary:
		return {"x": x,"y": y,"value": value}
