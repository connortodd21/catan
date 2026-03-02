class_name PortTypes


enum Type { GENERIC_3_1, WOOD_2_1, BRICK_2_1, SHEEP_2_1, WHEAT_2_1, ROCK_2_1, UNKNOWN }


static var port_type_to_str = {
	Type.GENERIC_3_1: "Generic_3_1",
	Type.WOOD_2_1: "Wood_2_1",
	Type.BRICK_2_1: "Brick_2_1",
	Type.SHEEP_2_1: "Sheep_2_1",
	Type.WHEAT_2_1: "Wheat_2_1",
	Type.ROCK_2_1: "Rock_2_1",
	Type.UNKNOWN: "Unknown",
}


static var str_to_port_type = DictUtils.invert_dictionary(port_type_to_str)


static func str_to_type(s: String) -> Type:
	if s in str_to_port_type:
		return str_to_port_type[s]
	return Type.UNKNOWN


static func type_to_str(t: Type) -> String:
	if t in port_type_to_str:
		return port_type_to_str[t]
	return ""
