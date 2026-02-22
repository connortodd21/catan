class_name HexAxial

var coords : Vector2

func _init(q: float, r: float) -> void:
	coords = Vector2(q,r)


func get_q() -> float:
	return coords.x


func get_r() -> float:
	return coords.y


func get_s() -> float:
	return - get_q() -get_r()


func _to_cube() -> HexCube:
	return HexCube.new(get_q(), get_r(), get_s())


func _to_vector2() -> Vector2:
	return coords


func _to_polygon2d() -> Polygon2D:
	var center = pointy_hex_to_pixel(HexConstants.HEX_RADIUS)
	var polygon = Polygon2D.new()
	var polygon_points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60 * i - 30
		var angle_rad = deg_to_rad(angle_deg)
		polygon_points.append(center + Vector2(HexConstants.HEX_RADIUS * cos(angle_rad), HexConstants.HEX_RADIUS * sin(angle_rad)))
	polygon.polygon = polygon_points
	return polygon


func pointy_hex_to_pixel(hex_size: float) -> Vector2:
	var q = get_q()
	var r = get_r()
	var x = (sqrt(3) * q + sqrt(3)/2 *r) * hex_size
	var y = (3.0/2.0 * r) * hex_size
	return Vector2(x, y)


func flat_hex_to_pixel(hex_size: float) -> Vector2:
	var q = get_q()
	var r = get_r()
	var x = (3.0 / 2.0 * q) * hex_size
	var y = (sqrt(3)/2 * q  +  sqrt(3) * r) * hex_size
	return Vector2(x, y)
