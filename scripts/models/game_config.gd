class_name GameConfig
extends Resource

@export var board : SerializedBoard = null
@export var players: Array[Player] = []
@export var expansions: Array[ExpansionTypes.Expansion] = []
@export var victory_points: int = 10
@export var house_rules: Array[HouseRules.RULE_NAMES] = []


func add_player(player: Player) -> void:
	players.append(player)


func add_house_rule(house_rule: HouseRules.RULE_NAMES) -> void:
	house_rules.append(house_rule)


func add_expansion(expansion: ExpansionTypes.Expansion) -> void:
	expansions.append(expansion)


func _debug_print() -> void:
	print("=== GameConfig ===")
	print("  board: ", board.size if board else Vector2i.ZERO)
	print("  victory_points: ", victory_points)
	var expansion_names := expansions.map(func(e): return ExpansionTypes.DISPLAY_NAMES[e])
	print("  expansions: ", expansion_names)
	var rule_names := house_rules.map(func(r): return HouseRules.DISPLAY_NAMES[r])
	print("  house_rules: ", rule_names)
	print("==================")
