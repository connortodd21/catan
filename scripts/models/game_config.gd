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


func has_robber() -> bool:
	return not HouseRules.RULE_NAMES.NO_ROBBER in house_rules


func has_harbormaster() -> bool:
	return ExpansionTypes.Expansion.HARBORMASTER in expansions


func to_dict() -> Dictionary:
	return {
		"board": board.to_dict() if board else {},
		"players": players.map(func(p: Player) -> Dictionary: return p.to_dict()),
		"expansions": expansions.map(func(e: ExpansionTypes.Expansion) -> int: return int(e)),
		"house_rules": house_rules.map(func(r: HouseRules.RULE_NAMES) -> int: return int(r)),
		"victory_points": victory_points
	}


func from_dict(dict: Dictionary) -> void:
	if dict.board != null:
		board = SerializedBoard.new().from_dict(dict.board)
	for p in dict.players:
		add_player(Player.new().from_dict(p))
	for e in dict.expansions:
		add_expansion(e as ExpansionTypes.Expansion)
	for r in dict.house_rules:
		add_house_rule(r as HouseRules.RULE_NAMES)
	victory_points = dict.victory_points


func _debug_print() -> void:
	print("=== GameConfig ===")
	print("  board: ", board.size if board else Vector2i.ZERO)
	print("  victory_points: ", victory_points)
	var expansion_names := expansions.map(func(e): return ExpansionTypes.DISPLAY_NAMES[e])
	print("  expansions: ", expansion_names)
	var rule_names := house_rules.map(func(r): return HouseRules.DISPLAY_NAMES[r])
	print("  house_rules: ", rule_names)
	print("==================")
