class_name HexConstants

const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

const HEX_RADIUS = 60.0

# horizontal spacing between centers
const HEX_WIDTH = sqrt(3) * HEX_RADIUS  # ≈ 103.92 for 60 radius

# vertical spacing between centers
const HEX_HEIGHT = 2 * HEX_RADIUS       # 120 for 60 radius
const HEX_VERTICAL_SPACING = HEX_RADIUS * 1.5  # 90 for 60 radius
