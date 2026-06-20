class_name PlayerResourceStats
extends PlayerStatsInterface

# Player -> resource_type -> count
var _data: Dictionary[Player, Dictionary] = {}


func _init() -> void:
	GameSignals.resource_collected.connect(_on_resource_collected)


func _on_resource_collected(player: Player, resource: ResourceTypes.Type, amount: int) -> void:
	if not _data.has(player):
		_data[player] = {}
	var player_data: Dictionary = _data[player]
	player_data[resource] = player_data.get(resource, 0) + amount


func get_resource_count(player: Player, resource: ResourceTypes.Type) -> int:
	if not _data.has(player):
		return 0
	return _data[player].get(resource, 0)


func get_players() -> Array[Player]:
	return _data.keys()


func get_headers() -> Array[String]:
	var headers: Array[String] = []
	for resource in ResourceTypes.DISPLAY_ORDER:
		headers.append(ResourceTypes.type_to_str(resource))
	return headers


func get_values(player: Player) -> Array[int]:
	var values: Array[int] = []
	for resource in ResourceTypes.DISPLAY_ORDER:
		values.append(get_resource_count(player, resource))
	return values
