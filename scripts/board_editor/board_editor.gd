extends Node2D

@export var hex_scene: PackedScene
@export var hex_outline_scene: PackedScene

@export var board_radius: int = 20
@export var board_size: Vector2i = Vector2i(1200, 1000)
var board_rect : Rect2

@onready var ghost_tile: Hex = $ghost_tile
@onready var tile_container: Node2D = $tile_container
@onready var grid_container: Node2D = $grid_container

var tiles := {} # HexAxial : HexTile
var grid_slots := {} # HexAxial : HexOutline

var board_center: Vector2

func _ready():
	var viewport_center = get_viewport_rect().size / 2
	board_rect = Rect2(viewport_center - board_size / 2.0, board_size)
	board_center = board_rect.position + board_rect.size / 2
	fill_editor_rect()
	draw_rect(board_rect, Color(0.6, 0, 0.8, 1), false, 4)


func _process(_delta: float) -> void:
	pass


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tile_at_mouse()


func _draw():
	draw_rect(board_rect, Color(0.6, 0, 0.8, 1), false, 4)


#############################################
### INPUT HANDLING
#############################################
func place_tile_at_mouse():
	var coord = mouse_to_hex()
	
	if tiles.has(coord):
		return

	var hex = hex_scene.instantiate()
	var selected_terrain = get_supported_terrain_types(hex).pick_random()
	hex.initialize(coord, selected_terrain, 0)

	hex.position = hex_to_world(coord)

	
	tile_container.add_child(hex)

func remove_tile_at_mouse():
	var coord = mouse_to_hex()

	if tiles.has(coord):
		tiles[coord].queue_free()
		tiles.erase(coord)

#############################################
### COORDINATE HELPERS
#############################################
func mouse_to_hex() -> HexAxial:
	var mouse_local = tile_container.to_local(get_global_mouse_position())
	return HexUtils.pixel_to_pointy_hex(mouse_local, HexConstants.HEX_RADIUS)

func hex_to_world(hex: HexAxial) -> Vector2:
	return HexUtils.pointy_hex_to_pixel(hex, HexConstants.HEX_RADIUS)

#############################################
### HEX METHODS
#############################################
func get_supported_terrain_types(hex: Hex) -> Array:
	return hex.get_supported_terrain_types()


func spawn_hex(hex_coord: HexAxial, terrain_type: TerrainTypes.Type, number:int = 0):
	var hex = hex_scene.instantiate()
	hex.initialize(hex_coord, terrain_type, number)
	tiles[hex_coord] = hex
	tile_container.add_child(hex)


#############################################
### GRID METHODS
#############################################
func fill_editor_rect() -> void:
	var hex_width = sqrt(3) * HexConstants.HEX_RADIUS
	var v_step = 1.5 * HexConstants.HEX_RADIUS
	
	var r_min = floor(board_rect.position.y / v_step) - 2
	var r_max = ceil(board_rect.end.y / v_step) + 2
	
	for r in range(r_min, r_max):
		var row_offset = HexConstants.HEX_WIDTH * (r * 0.5)
		var q_min = floor((board_rect.position.x - row_offset) / hex_width) - 2
		var q_max = ceil((board_rect.end.x - row_offset) / hex_width) + 2
		for q in range(q_min, q_max):
			var hex_axial = HexAxial.new(q, r)
			if can_draw_hex(hex_axial):
				var hex_outline = hex_outline_scene.instantiate()
				hex_outline.set_coord(hex_axial)
				hex_outline.position = hex_axial.pointy_hex_to_pixel(HexConstants.HEX_RADIUS) + board_rect.position
				hex_outline.connect("clicked", Callable(self, "_on_slot_clicked"))
				grid_container.add_child(hex_outline)
				grid_slots[hex_axial] = hex_outline


func can_draw_hex(hex_axial: HexAxial) -> bool:
	var polygon = hex_axial._to_polygon2d()
	var rect_polygon = board_rect_to_polygon()
	for poly_point in polygon.polygon:
		var poly_point_with_offset = poly_point + board_rect.position
		if Geometry2D.is_point_in_polygon(poly_point_with_offset, rect_polygon.polygon):
			return true
	return false


func _on_slot_clicked(slot: HexOutline):
	if tiles.has(slot.coord) or slot.occupied:
		return

	var hex = hex_scene.instantiate()
	var selected_terrain = hex.get_supported_terrain_types().pick_random()
	if selected_terrain:
		hex.initialize(slot.coord, selected_terrain, 0)

	hex.position = slot.position
	tile_container.add_child(hex)
	tiles[slot.coord] = hex


#############################################
### BOARD RECT METHODS
#############################################
func board_rect_to_polygon() -> Polygon2D:
	var points = PackedVector2Array()
	points.append(board_rect.position)
	points.append(board_rect.position + Vector2(board_rect.size.x, 0))
	points.append(board_rect.position + board_rect.size)
	points.append(board_rect.position + Vector2(0, board_rect.size.y))
	var polygon = Polygon2D.new()
	polygon.polygon = points
	return polygon
