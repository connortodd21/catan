class_name RuleRegistry extends Node

enum Rules {
	NO_2_12_TOUCHING,
	NO_6_8_TOUCHING,
	NO_ADJACENT_SAME_TILES,
	NO_ADJACENT_SAME_NUMBERS,
}

var RULE_REGISTRY := {
	Rules.NO_2_12_TOUCHING: NoTwoTwelveTouchingRule,
	Rules.NO_6_8_TOUCHING: NoSixEightTouchingRule,
	Rules.NO_ADJACENT_SAME_TILES: NoAdjacentSameTileRule,
	Rules.NO_ADJACENT_SAME_NUMBERS: NoAdjacentSameNumberRule
}

func get_all_rules() -> Array[BoardRule]:
	var arr : Array[BoardRule] = []
	for key in RULE_REGISTRY.keys():
		arr.append(RULE_REGISTRY[key].new())
	return arr

func get_rule(key: Rules) -> BoardRule:
	if RULE_REGISTRY.has(key):
		return RULE_REGISTRY[key].new()
	return null
