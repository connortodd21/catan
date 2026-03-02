class_name WaterBorderGenerator


static func generate(land_coords: Array[Vector2i]) -> Array[Vector2i]:
	var land_set := {}
	for c in land_coords:
		land_set[c] = true

	var water := {}
	for c in land_coords:
		for d in HexConstants.HEX_DIRECTIONS:
			var n: Vector2i = c + d
			if not land_set.has(n):
				water[n] = true

	var result: Array[Vector2i] = []
	for k in water:
		result.append(k)
	return result
