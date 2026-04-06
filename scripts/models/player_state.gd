class_name PlayerState
extends RefCounted

var player: Player
var hand: Hand = Hand.new()

var score: int = 0
var longest_road_length: int = 0
var army_size: int = 0
var harbormaster_count: int = 0


func _init(p: Player) -> void:
	player = p


func get_color() -> Color:
	return player.get_color()


func get_name() -> String:
	return player.player_name
