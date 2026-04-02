class_name ActionTypes

enum Type {
	# Base game
	BUILD_ROAD,
	BUILD_SETTLEMENT,
	BUILD_CITY,
	BUY_DEV_CARD,
	TRADE,

	# Cities & Knights
	BUILD_KNIGHT,
	ACTIVATE_KNIGHT,
	MOVE_KNIGHT,
	CHASE_ROBBER,
	BUILD_CITY_WALL,
	ADVANCE_COMMODITY_TRACK,

	# Seafarers
	BUILD_SHIP,
	MOVE_SHIP,

	# Fishermen
	TRADE_FISH,
}

static var _labels: Dictionary[Type, String] = {
	Type.BUILD_ROAD: "Build Road",
	Type.BUILD_SETTLEMENT: "Build Settlement",
	Type.BUILD_CITY: "Build City",
	Type.BUY_DEV_CARD: "Buy Development Card",
	Type.TRADE: "Trade",
	Type.BUILD_KNIGHT: "Build Knight",
	Type.ACTIVATE_KNIGHT: "Activate Knight",
	Type.MOVE_KNIGHT: "Move Knight",
	Type.CHASE_ROBBER: "Chase Robber",
	Type.BUILD_CITY_WALL: "Build City Wall",
	Type.ADVANCE_COMMODITY_TRACK: "Advance Commodity Track",
	Type.BUILD_SHIP: "Build Ship",
	Type.MOVE_SHIP: "Move Ship",
	Type.TRADE_FISH: "Trade Fish",
}

static func type_to_label(type: Type) -> String:
	return _labels.get(type, "")
