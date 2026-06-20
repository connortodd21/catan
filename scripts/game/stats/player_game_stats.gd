class_name PlayerGameStats
extends PlayerStatsInterface


#############################################
### REGISTRATION
#############################################
var _players: Array[Player] = []


func register_players(players: Array[Player]) -> void:
	_players = players


#############################################
### STATS
#############################################
var knights := KnightPlayerStats.new()
var robbers := RobberPlayerStats.new()
var stolen := ResourcesStolenPlayerStats.new()
var lost_from_robbing := ResourcesLostFromRobbingPlayerStats.new()

var _columns: Dictionary[String, Callable] = {}


func _init() -> void:
	_columns["Knights"] = knights.get_count
	_columns["Robbers Placed"] = robbers.get_count
	_columns["Resources Stolen"] = stolen.get_count
	_columns["Resources Lost from Robbing"] = lost_from_robbing.get_count


func get_players() -> Array[Player]:
	return _players


func get_headers() -> Array[String]:
	return _columns.keys()


func get_values(player: Player) -> Array[int]:
	var values: Array[int] = []
	for col in _columns.values():
		values.append(col.call(player))
	return values


#############################################
### KNIGHTS
#############################################
class KnightPlayerStats:
	var _counts: Dictionary[Player, int] = {}

	func _init() -> void:
		GameSignals.development_card_played.connect(_on_development_card_played)

	func _on_development_card_played(player: Player, card_type: CardTypes.Type) -> void:
		if card_type == CardTypes.Type.KNIGHT:
			_counts[player] = _counts.get(player, 0) + 1

	func get_count(player: Player) -> int:
		return _counts.get(player, 0)


#############################################
### ROBBERS
#############################################
class RobberPlayerStats:
	var _counts: Dictionary[Player, int] = {}

	func _init() -> void:
		GameSignals.development_card_played.connect(_on_development_card_played)
		GameSignals.player_rolled.connect(_on_player_rolled)

	func _on_development_card_played(player: Player, card_type: CardTypes.Type) -> void:
		if card_type == CardTypes.Type.KNIGHT:
			_counts[player] = _counts.get(player, 0) + 1

	func _on_player_rolled(player: Player, total: int) -> void:
		if total == 7:
			_counts[player] = _counts.get(player, 0) + 1

	func get_count(player: Player) -> int:
		return _counts.get(player, 0)


#############################################
### RESOURCES STOLEN
#############################################
class ResourcesStolenPlayerStats:
	var _counts: Dictionary[Player, int] = {}

	func _init() -> void:
		GameSignals.resource_stolen.connect(_on_resource_stolen)

	func _on_resource_stolen(thief: Player, _victim: Player, _resource: ResourceTypes.Type) -> void:
		_counts[thief] = _counts.get(thief, 0) + 1

	func get_count(player: Player) -> int:
		return _counts.get(player, 0)


#############################################
### RESOURCES LOST
#############################################
class ResourcesLostFromRobbingPlayerStats:
	var _counts: Dictionary[Player, int] = {}

	func _init() -> void:
		GameSignals.resource_stolen.connect(_on_resource_stolen)

	func _on_resource_stolen(_thief: Player, victim: Player, _resource: ResourceTypes.Type) -> void:
		_counts[victim] = _counts.get(victim, 0) + 1

	func get_count(player: Player) -> int:
		return _counts.get(player, 0)
