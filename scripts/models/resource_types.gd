class_name ResourceTypes

enum Type {
	UNKNOWN,
	WOOD,
	BRICK,
	SHEEP,
	WHEAT,
	ROCK,
	CLOTH,
	COIN,
	PAPER,
	FISH,
}


static var tile_type_to_str = { 
	Type.WOOD: "Wood",
	Type.BRICK: "Brick",
	Type.SHEEP: "Sheep",
	Type.WHEAT: "Wheat",
	Type.ROCK: "Rock",
	Type.CLOTH: "Cloth",
	Type.COIN: "Coin",
	Type.PAPER: "Paper",
	Type.FISH: "Fish",
}


static func type_to_str(resource_type: Type) -> String:
	return tile_type_to_str.get(resource_type, Type.UNKNOWN)


const DISPLAY_ORDER: Array[Type] = [
	Type.WOOD,
	Type.BRICK,
	Type.SHEEP,
	Type.WHEAT,
	Type.ROCK,
]


static func compare_display_order(a: Type, b: Type) -> bool:
	return DISPLAY_ORDER.find(a) < DISPLAY_ORDER.find(b)


static func counts_toward_robber(type: Type) -> bool:
	return type in [
		Type.WOOD, Type.BRICK, Type.SHEEP,
		Type.WHEAT, Type.ROCK, Type.CLOTH,
		Type.COIN, Type.PAPER,
	]


static func max_in_hand(type: Type) -> int:
	match type:
		Type.FISH: return 7
		_: return -1
