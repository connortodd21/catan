class_name GameConfig
extends Resource

@export var board : SerializedBoard = null
@export var expansions: Array[ExpansionTypes.Expansion] = []
@export var victory_points: int = 10
@export var house_rules: HouseRules = null


func add_expansion(expansion: ExpansionTypes.Expansion) -> void:
	expansions.append(expansion)
