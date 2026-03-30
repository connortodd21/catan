class_name PlayerState
extends RefCounted

var player: Player
var hand: Hand = Hand.new()

var score: int = 0
var has_longest_road: bool = false
var has_largest_army: bool = false


func _init(p: Player) -> void:
	player = p


func get_color() -> Color:
	return player.get_color()


func get_name() -> String:
	return player.player_name
