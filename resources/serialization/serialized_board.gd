extends Resource
class_name SerializedBoard

# width/height of the playable board rectangle. We use this as the board is normalized at (0,0)
@export var size: Vector2i = Vector2i.ZERO 


var tiles: Array[TileEntry] = []
var numbers: Array[NumberEntry] = []
var metadata: Dictionary = {
	"version": 1
}


func add_tile_vector2(coords: Vector2i, tile: TerrainTypes.Type) -> void:
	add_tile(coords.x, coords.y, tile)


func add_tile(x: int, y: int, tile: TerrainTypes.Type) -> void:
	tiles.append(TileEntry.new(x, y, tile))


func add_numbers_vector2(coords: Vector2i, value: Array[int]) -> void:
	add_numbers(coords.x, coords.y, value)


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


func from_dict(dict: Dictionary) -> SerializedBoard:
	size = Vector2i(dict.size.width, dict.size.height)
	for t in dict.tiles:
		add_tile(t.x, t.y, t.type)
	for n in dict.numbers:
		var nums_array: Array[int] = []
		for v in n["value"]:
			nums_array.append(int(v))
		add_numbers(n.x, n.y, nums_array)
	metadata = dict.metadata
	return self
