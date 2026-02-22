class_name HexCube

var coords : Vector3

func _init(q: float, r: float, s: float) -> void:
	coords = Vector3(q,r,s)


func get_q() -> float:
	return coords.x


func get_r() -> float:
	return coords.y


func get_s() -> float:
	return coords.z


func _to_axial() -> HexAxial:
	return HexAxial.new(get_q(), get_r())
