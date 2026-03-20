class_name CardTypes

enum Type {
	WOOD,
	BRICK,
	SHEEP,
	WHEAT,
	ROCK,
	CLOTH,
	COIN,
	PAPER,
	PROGRESS_TRADE,
	PROGRESS_POLITICS,
	PROGRESS_SCIENCE,
	FISH,
}


static func counts_toward_robber(type: Type) -> bool:
	return type in [
		Type.WOOD, Type.BRICK, Type.SHEEP,
		Type.WHEAT, Type.ROCK, Type.CLOTH,
		Type.COIN, Type.PAPER,
	]


static func max_in_hand(type: Type) -> int:
	match type:
		Type.PROGRESS_TRADE, Type.PROGRESS_POLITICS, Type.PROGRESS_SCIENCE:
			return 5
		Type.FISH:
			return 7
		_:
			return -1
