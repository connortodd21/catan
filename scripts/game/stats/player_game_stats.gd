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


func get_players() -> Array[Player]:
	return _players


func get_headers() -> Array[String]:
	return ["Knights"]


func get_values(player: Player) -> Array[int]:
	return [knights.get_count(player)]


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
