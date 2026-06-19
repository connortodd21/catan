class_name PieceTypes

enum Type {
	UNKNOWN,
	SETTLEMENT,
	ROAD,
	CITY,
	CITY_WALL,
	KNIGHT_1,
	KNIGHT_2,
	KNIGHT_3,
	METROPOLIS,
	BOAT,
	BRIDGE,
	MERCHANT,
	ROBBER
}

static var _display_names: Dictionary = {
	Type.SETTLEMENT: "Settlement",
	Type.CITY: "City",
	Type.ROAD: "Road",
}

static func type_to_str(type: Type) -> String:
	return _display_names.get(type, "Piece")
