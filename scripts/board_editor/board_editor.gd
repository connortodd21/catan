extends Node2D

@export var hex_scene: PackedScene

@onready var ghost_tile: Hex = $ghost_tile
@onready var tile_container: Node2D = $tile_container

var tiles := {} # cube_coord → HexTile

var board_origin: Vector2

func _ready():
	board_origin = get_viewport_rect().size / 2

func _process(_delta: float) -> void:
	pass

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tile_at_mouse()

#############################################
### INPUT HANDLING
#############################################

func place_tile_at_mouse():
	var coord = mouse_to_hex()
	
	if tiles.has(coord):
		return

	var hex = hex_scene.instantiate()
	var selected_terrain = get_supported_terrain_types(hex).pick_random()
	if selected_terrain:
		hex.initialize(coord, selected_terrain, 0)

		hex.position = hex_to_world(coord)

		tiles[coord] = hex
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
