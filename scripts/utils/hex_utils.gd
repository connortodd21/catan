class_name HexUtils


const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]

# Vertex offsets from hex center for a pointy-top hex (tile_size 120x140)
const VERTEX_OFFSETS: Array[Vector2] = [
	Vector2(0, -70),   # top
	Vector2(60, -35),  # top-right
	Vector2(60, 35),   # bottom-right
	Vector2(0, 70),    # bottom
	Vector2(-60, 35),  # bottom-left
	Vector2(-60, -35), # top-left
]

# Edge midpoint offsets from hex center (midpoint of each side)
const EDGE_MIDPOINTS: Array[Vector2] = [
	Vector2(30, -52),  # top-right edge
	Vector2(60, 0),    # right edge
	Vector2(30, 52),   # bottom-right edge
	Vector2(-30, 52),  # bottom-left edge
	Vector2(-60, 0),   # left edge
	Vector2(-30, -52), # top-left edge
]

# Rotation in degrees for a piece placed on each edge (aligns with edge direction)
const EDGE_ROTATIONS: Array[float] = [
	30.0,   # top-right edge
	90.0,   # right edge
	-30.0,  # bottom-right edge
	30.0,   # bottom-left edge
	90.0,   # left edge
	-30.0,  # top-left edge
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
