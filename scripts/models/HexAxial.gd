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
