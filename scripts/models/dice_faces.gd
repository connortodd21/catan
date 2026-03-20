class_name DiceFaces

enum Type {
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	BARBARIAN,
	TRADE,
	POLITICS,
	SCIENCE
}


# returns -1 for non-numeric faces
static func type_to_int(face: DiceFaces.Type) -> int:
	match face:
		DiceFaces.Type.ONE: return 1
		DiceFaces.Type.TWO: return 2
		DiceFaces.Type.THREE: return 3
		DiceFaces.Type.FOUR: return 4
		DiceFaces.Type.FIVE: return 5
		DiceFaces.Type.SIX: return 6
		_: return -1
