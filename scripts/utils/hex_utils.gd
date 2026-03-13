class_name HexUtils

const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]


#############################################
### HEX DISTANCES
#############################################
static func axial_to_oddr(hex: Vector2i) -> Vector2i:
	var col = int(hex.x + (hex.y - (hex.y & 1)) / 2.0)
	var row = hex.y
	return Vector2i(col, row)


static func oddr_to_axial(offset: Vector2i) -> Vector2i:
	var q = int(offset.x - (offset.y - (offset.y & 1)) / 2.0)
	var r = offset.y
	return Vector2i(q, r)


static func axial_to_offset(axial: Vector2i) -> Vector2i:
	var col = int(axial.x + (axial.y - (axial.y & 1)) / 2.0)
	var row = axial.y
	return Vector2i(col, row)


static func offset_to_axial(offset: Vector2i) -> Vector2i:
	var q = int(offset.x - (offset.y - (offset.y & 1)) / 2.0)
	var r = offset.y
	return Vector2i(q, r)
