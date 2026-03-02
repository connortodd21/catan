class_name GenerationConfig

var radius: int = 3
var seed_value: int = 0
var allowed_tiles: Array[TerrainTypes.Type] = []
@export var shape : Shapes.Type = Shapes.Type.CIRCLE
@export var rule_set: RuleSet
var rect_width: int = 6
var rect_height: int = 4
var oval_width: int = 6
var oval_height: int = 4


func add_tile(tile: TerrainTypes.Type) -> void:
	allowed_tiles.append(tile)


func _debug_print() -> void:
	print("\n========== GenerationConfig ==========")

	print("Shape: ", Shapes.Type.keys()[shape])
	print("Seed Value: ", seed_value)

	print("\n--- Size Settings ---")
	print("Radius: ", radius)
	print("Rectangle Width: ", rect_width)
	print("Rectangle Height: ", rect_height)
	print("Oval Width: ", oval_width)
	print("Oval Height: ", oval_height)

	print("\n--- Allowed Tiles ---")
	if allowed_tiles.is_empty():
		print("None")
	else:
		for tile in allowed_tiles:
			print("- ", TerrainTypes.type_to_str(tile))

	print("\n--- Rules ---")
	if rule_set == null:
		print("No RuleSet assigned")
	else:
		var rules = rule_set.get_rules() if rule_set.has_method("get_rules") else []
		if rules.is_empty():
			print("No rules enabled")
		else:
			for rule in rules:
				print("- ", rule.get_rule_name())

	print("======================================\n")
