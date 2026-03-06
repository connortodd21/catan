class_name BoardPreview
extends Control

const SQRT3 := sqrt(3.0)

const TERRAIN_COLORS := {
	TerrainTypes.Type.WOOD: Color(0.18, 0.50, 0.18),
	TerrainTypes.Type.BRICK: Color(0.72, 0.28, 0.12),
	TerrainTypes.Type.SHEEP: Color(0.55, 0.80, 0.30),
	TerrainTypes.Type.WHEAT: Color(0.90, 0.78, 0.20),
	TerrainTypes.Type.ROCK: Color(0.50, 0.50, 0.52),
	TerrainTypes.Type.DESERT: Color(0.87, 0.78, 0.50),
	TerrainTypes.Type.WATER: Color(0.18, 0.42, 0.72),
	TerrainTypes.Type.FISH_2_3_11_12: Color(0.40, 0.72, 0.82),
	TerrainTypes.Type.FISH_4_10: Color(0.30, 0.65, 0.78),
	TerrainTypes.Type.GOLD: Color(0.90, 0.75, 0.10),
	TerrainTypes.Type.FOG: Color(0.35, 0.35, 0.38),
}

var board : SerializedBoard = null

var tiles: Array[TileEntry] = []


func get_board() -> SerializedBoard:
	return board


func set_board(_board: SerializedBoard) -> void:
	board = _board
	if board.tiles:
		for tile in board.tiles:
			if tile.type != TerrainTypes.Type.UNKNOWN and tile.type != TerrainTypes.Type.BORDER:
				tiles.append(tile)
	queue_redraw()


func _draw() -> void:
	if tiles.is_empty():
		return

	# Compute normalized hex centers (hex_r=1, pointy-top, odd-r offset)
	var positions: Array[Vector2] = []
	var min_px := INF
	var max_px := -INF
	var min_py := INF
	var max_py := -INF

	for tile: TileEntry in tiles:
		var cx: float = float(tile.x) * SQRT3 + float(tile.y) * SQRT3 * 0.5
		var cy: float = float(tile.y) * 1.5
		positions.append(Vector2(cx, cy))
		min_px = min(min_px, cx)
		max_px = max(max_px, cx)
		min_py = min(min_py, cy)
		max_py = max(max_py, cy)

	# Full extent including hex radius on each edge
	var board_w: float = max_px - min_px + SQRT3
	var board_h: float = max_py - min_py + 2.0

	var hex_r: float = min(size.x / board_w, size.y / board_h) * 0.92

	var draw_offset := Vector2(
		(size.x - board_w * hex_r) * 0.5 + (SQRT3 * 0.5 - min_px) * hex_r,
		(size.y - board_h * hex_r) * 0.5 + (1.0 - min_py) * hex_r
	)

	for i: int in tiles.size():
		var color: Color = TERRAIN_COLORS.get(tiles[i].type, Color.GRAY)
		_draw_hex(positions[i] * hex_r + draw_offset, hex_r * 0.93, color)


func _draw_hex(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 6:
		var angle: float = PI / 6.0 + i * PI / 3.0  # pointy-top
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.3), 1.0)
