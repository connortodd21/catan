class_name PortTypes


enum Type {
	GENERIC,
	WOOD,
	BRICK,
	SHEEP,
	WHEAT,
	ROCK,
	UNKNOWN
}


static var type_to_str_map: Dictionary = {
	Type.GENERIC: "Generic",
	Type.WOOD: "Wood",
	Type.BRICK: "Brick",
	Type.SHEEP: "Sheep",
	Type.WHEAT: "Wheat",
	Type.ROCK: "Rock",
}

static var str_to_type_map: Dictionary = {
	"Generic": Type.GENERIC,
	"Wood": Type.WOOD,
	"Brick": Type.BRICK,
	"Sheep": Type.SHEEP,
	"Wheat": Type.WHEAT,
	"Rock": Type.ROCK,
}


static func type_to_str(type: Type) -> String:
	return type_to_str_map.get(type, "Generic")


static func str_to_type(s: String) -> Type:
	return str_to_type_map.get(s, Type.GENERIC)


static func get_trade_rate(type: Type) -> int:
	if type == Type.GENERIC:
		return 3
	return 2
