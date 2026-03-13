class_name Game
extends Node2D

@export var terrain_database: TerrainDatabaseResource
@export var number_database: NumberDatabaseResource
@export var piece_database: PieceDatabaseResource
@export var number_scale: float = 1.0
@export var number_offset: Vector2 = Vector2.ZERO
@export var game_config: GameConfig = null

@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap
@onready var board_view: Node2D = $BoardView

var tile_coords: Array[Vector2i] = []


func _ready() -> void:
	if game_config:
		render_board(game_config.board)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			place_piece_at_mouse(PieceTypes.Type.ROAD)
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_piece_at_mouse(PieceTypes.Type.SETTLEMENT)


#############################################
### BOARD RENDERING
#############################################
func render_board(board: SerializedBoard) -> void:
	var coord_to_tile: Dictionary = {}
	for tile: TileEntry in board.tiles:
		var coord := Vector2i(tile.x, tile.y)
		board_tile_map.set_cell(
			HexUtils.axial_to_offset(coord),
			terrain_database.get_source_id(tile.type),
			terrain_database.get_atlas_coords(tile.type)
		)
		coord_to_tile[coord] = true
		tile_coords.append(coord)
	render_numbers(board)
	add_border(coord_to_tile)


func render_numbers(board: SerializedBoard) -> void:
	for entry: NumberEntry in board.numbers:
		if entry.value.is_empty():
			continue
		var number := entry.value[0]
		if not number in number_database.get_keys():
			continue
		var offset := HexUtils.axial_to_offset(Vector2i(entry.x, entry.y))
		var sprite := Sprite2D.new()
		sprite.texture = number_database.get_texture(number)
		sprite.scale = Vector2(number_scale, number_scale)
		sprite.position = board_tile_map.map_to_local(offset) + number_offset
		sprite.z_index = 1
		board_view.add_child(sprite)


#############################################
### PIECE PLACEMENT
#############################################
func place_piece_at_mouse(type: PieceTypes.Type) -> void:
	var mouse_pos : Vector2 = board_view.get_local_mouse_position()
	var nearest_pos : Vector2 = Vector2.ZERO
	var nearest_dist : float = INF
	var nearest_rotation : float = 0.0

	var placement : PlacementType.Type = piece_database.get_placement(type)
	var snap_points : Array[Vector2] = PlacementType.get_snap_points(placement)
	var rotations : Array[float] = PlacementType.get_rotations(placement)

	for coord: Vector2i in tile_coords:
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		for i in snap_points.size():
			var pos := hex_center + snap_points[i]
			var dist := mouse_pos.distance_to(pos)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_pos = pos
				nearest_rotation = rotations[i] if not rotations.is_empty() else 0.0

	if nearest_dist > 40.0:
		return

	var sprite := Sprite2D.new()
	sprite.texture = piece_database.get_texture(type)
	sprite.rotation_degrees = nearest_rotation
	sprite.position = nearest_pos
	sprite.z_index = 2
	board_view.add_child(sprite)


func add_border(coord_to_tile: Dictionary) -> void:
	var water_source := terrain_database.get_source_id(TerrainTypes.Type.DESERT)
	var water_atlas := terrain_database.get_atlas_coords(TerrainTypes.Type.DESERT)
	var border: Dictionary = {}
	for axial: Vector2i in coord_to_tile:
		for dir: Vector2i in HexUtils.HEX_DIRECTIONS:
			var neighbor := axial + dir
			if not coord_to_tile.has(neighbor) and not border.has(neighbor):
				border[neighbor] = true
	for axial: Vector2i in border:
		board_tile_map.set_cell(HexUtils.axial_to_offset(axial), water_source, water_atlas)
