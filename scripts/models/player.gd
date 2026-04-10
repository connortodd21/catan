class_name Player
extends Resource

@export var player_name: String = ""
@export var player_color: PlayerColor = PlayerColor.RED

enum PlayerColor { RED, BLUE, YELLOW, GREEN, ORANGE, PURPLE, WHITE }

static var PALETTE: Dictionary = {
	PlayerColor.RED:    Palette.new("Red",    Color(0.80, 0.15, 0.15)),
	PlayerColor.BLUE:   Palette.new("Blue",   Color(0.15, 0.35, 0.90)),
	PlayerColor.YELLOW: Palette.new("Yellow", Color(0.92, 0.82, 0.10)),
	PlayerColor.GREEN:  Palette.new("Green",  Color(0.15, 0.60, 0.20)),
	PlayerColor.ORANGE: Palette.new("Orange", Color(0.92, 0.50, 0.10)),
	PlayerColor.PURPLE: Palette.new("Purple", Color(0.52, 0.12, 0.82)),
	PlayerColor.WHITE:  Palette.new("White",  Color(0.95, 0.95, 0.95)),
}

class Palette:
	var _name: String
	var _color: Color

	func _init(p_name: String, p_color: Color) -> void:
		_name = p_name
		_color = p_color

	func get_name() -> String:
		return _name

	func get_color() -> Color:
		return _color


func get_color() -> Color:
	return PALETTE[player_color].get_color()


func get_player_name() -> String:
	return player_name
