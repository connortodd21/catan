class_name Shapes

enum Type {
	CIRCLE,
	SQUARE,
	RECTANGLE,
	OVAL,
	UNKNOWN
}


static var shape_type_to_str = { 
	Type.CIRCLE: "Circle",
	Type.SQUARE: "Square",
	Type.RECTANGLE: "Rectangle",
	Type.OVAL: "Oval"
}


static var str_to_shape_type = DictUtils.invert_dictionary(shape_type_to_str)


static func get_shape_from_string(shape: String) -> Shapes.Type:
	if shape in shape_type_to_str:
		return str_to_shape_type[shape]
	return Type.UNKNOWN
