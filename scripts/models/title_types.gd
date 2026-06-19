class_name TitleTypes

enum Type {
	LONGEST_ROAD,
	LARGEST_ARMY,
	HARBORMASTER,
}

static var _display_names: Dictionary = {
	Type.LONGEST_ROAD: "Longest Road",
	Type.LARGEST_ARMY: "Largest Army",
	Type.HARBORMASTER: "Harbormaster",
}

static func type_to_str(type: Type) -> String:
	return _display_names.get(type, "Title")
