class_name HexUtils
# algorithms taken directly from https://www.redblobgames.com/grids/hexagons

const CUBE_DIRECTIONS = [
	Vector3i(1, -1, 0), Vector3i(-1, 1, 0),
	Vector3i(1, 0, -1), Vector3i(-1, 0, 1),
	Vector3i(0, 1, -1), Vector3i(0, -1, 1),
]

#############################################
### AXIAL HEX TO PIXEL CONVERSIONS
#############################################
static func pointy_hex_to_pixel(hex: HexAxial, hex_size: float) -> Vector2:
	var q = hex.get_q()
	var r = hex.get_r()
	
	var x = (sqrt(3) * q + sqrt(3)/2 *r)
	var y = (3.0/2.0 * r)
	
	x = x * hex_size
	y = y * hex_size
	return Vector2(x, y)

static func flat_hex_to_pixel(hex: HexAxial, hex_size: float) -> Vector2:
	var q = hex.get_q()
	var r = hex.get_r()
	var x = (3.0 / 2.0 * q)
	var y = (sqrt(3)/2 * q  +  sqrt(3) * r)
	
	x = x * hex_size
	y = y * hex_size
	return Vector2(x, y)


#############################################
### AXIAL PIXEL TO HEX CONVERSIONS
#############################################
static func pixel_to_pointy_hex(point: Vector2, hex_size: float) -> HexAxial:
	var x = point.x / hex_size
	var y = point.y / hex_size
	var q = (sqrt(3)/3 * x - 1.0/3.0 * y)
	var r = (2.0/3.0 * y)
	return axial_round(HexAxial.new(q, r))


static func pixel_to_flat_hex(point: Vector2, hex_size: float) -> HexAxial:
	var x = point.x / hex_size
	var y = point.y / hex_size
	var q = ( 2./3 * x )
	var r = (-1.0/3.0 * x + sqrt(3)/3 * y)
	return axial_round(HexAxial.new(q, r))


#############################################
### AXIAL HEX ROUNDING
#############################################
static func cube_round(cube: HexCube) -> HexCube:
	var q = round(cube.get_q())
	var r = round(cube.get_r())
	var s = round(cube.get_s())

	var q_diff = abs(q - cube.get_q())
	var r_diff = abs(r - cube.get_r())
	var s_diff = abs(s - cube.get_s())

	if q_diff > r_diff and q_diff > s_diff:
		q = -r-s
	elif r_diff > s_diff:
		r = -q-s
	else:
		s = -q-r

	return HexCube.new(q, r, s)


static func axial_round(hex: HexAxial) -> HexAxial:
	return cube_round(hex._to_cube())._to_axial()


#############################################
### HEX DISTANCES
#############################################
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq = a.x - b.x
	var dr = a.y - b.y
	return int((abs(dq) + abs(dq + dr) + abs(dr)) / 2)


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
