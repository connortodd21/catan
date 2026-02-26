class_name GenerationConfig

var radius: int = 3
var seed_value: int = 0
var allowed_tiles: Array[TerrainTypes.Type] = []
@export var shape : Shapes.Type = Shapes.Type.CIRCLE
@export var rule_set: RuleSet


func add_tile(tile: TerrainTypes.Type) -> void:
	allowed_tiles.append(tile)
