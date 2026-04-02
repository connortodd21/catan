class_name PlacementType

enum Type {
	NONE,
	HEX_VERTEX,
	HEX_EDGE,
	HEX_INSIDE,
}


static func get_snap_points(placement: PlacementType.Type) -> Array[Vector2]:
	match placement:
		PlacementType.Type.HEX_VERTEX:
			return HexUtils.VERTEX_OFFSETS
		PlacementType.Type.HEX_EDGE:
			return HexUtils.EDGE_MIDPOINTS
		PlacementType.Type.HEX_INSIDE:
			return [Vector2.ZERO]
		_:
			return [Vector2.ZERO]


static func get_rotations(placement: PlacementType.Type) -> Array[float]:
	match placement:
		PlacementType.Type.HEX_VERTEX:
			return []
		PlacementType.Type.HEX_EDGE:
			return HexUtils.EDGE_ROTATIONS
		PlacementType.Type.HEX_INSIDE:
			return []
		_:
			return []
