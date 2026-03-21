class_name CardTypes

enum Type {
	# Base game development cards
	KNIGHT,
	VICTORY_POINT,
	ROAD_BUILDING,
	YEAR_OF_PLENTY,
	MONOPOLY,

	# Cities and Knights progress cards (Trade)
	COMMERCIAL_HARBOR,
	MASTER_MERCHANT,
	MERCHANT,
	MERCHANT_FLEET,
	RESOURCE_MONOPOLY,
	TRADE_MONOPOLY,

	# Cities and Knights progress cards (Politics)
	BISHOP,
	CONSTITUTION,
	DESERTER,
	DIPLOMAT,
	INTRIGUE,
	SABOTEUR,
	SPY,
	WARLORD,

	# Cities and Knights progress cards (Science)
	ALCHEMIST,
	CRANE,
	ENGINEER,
	INVENTOR,
	IRRIGATION,
	MEDICINE,
	MINING,
	PRINTER,
	SCIENCE_ROAD_BUILDING,
	SMITH,
}

static var dev_deck : Array[Type] = [
	Type.KNIGHT,
	Type.VICTORY_POINT,
	Type.ROAD_BUILDING,
	Type.YEAR_OF_PLENTY,
	Type.MONOPOLY,
]

static var progress_trade_deck : Array[Type] = [
	Type.COMMERCIAL_HARBOR,
	Type.MASTER_MERCHANT,
	Type.MERCHANT,
	Type.MERCHANT_FLEET,
	Type.RESOURCE_MONOPOLY,
	Type.TRADE_MONOPOLY,
]

static var progress_science_deck : Array[Type] = [
	Type.ALCHEMIST,
	Type.CRANE,
	Type.ENGINEER,
	Type.INVENTOR,
	Type.IRRIGATION,
	Type.MEDICINE,
	Type.MINING,
	Type.PRINTER,
	Type.SCIENCE_ROAD_BUILDING,
	Type.SMITH,
]


static var progress_politics_deck : Array[Type] = [
	Type.BISHOP,
	Type.CONSTITUTION,
	Type.DESERTER,
	Type.DIPLOMAT,
	Type.INTRIGUE,
	Type.SABOTEUR,
	Type.SPY,
	Type.WARLORD,
]

static func get_dev_deck() -> Array[Type]:
	return dev_deck


static func get_progress_trade_deck() -> Array[Type]:
	return progress_trade_deck


static func get_progress_politics_deck() -> Array[Type]:
	return progress_politics_deck


static func get_progress_science_deck() -> Array[Type]:
	return progress_science_deck


static func max_in_hand(type: Type) -> int:
	if type in progress_trade_deck or type in progress_politics_deck or type in progress_science_deck:
		return 5
	return -1
