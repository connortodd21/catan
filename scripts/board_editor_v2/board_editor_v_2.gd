extends Node2D


@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera_2d: Camera2D = $Camera2D

var tileset_source_id = 0
var default_tile_atlas_coords : Vector2i = Vector2i(4,0)
var border_tile_atlas_coords : Vector2i = Vector2i(5,0)
@export var board_width := 9
@export var board_height := 9


func _ready() -> void:
	pass


#############################################
### CAMERA
#############################################


#############################################
### TILE MAP
#############################################
func is_cell_editable(cell: Vector2i) -> bool:
	return tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords

#############################################
### INPUT HANDLING
#############################################
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tile_at_mouse()


func place_tile_at_mouse():
	var cell = tile_map.local_to_map(get_local_mouse_position())
	if is_cell_editable(cell):
		tile_map.erase_cell(cell)
		tile_map.set_cell(cell, tileset_source_id, Vector2i(0,0))


func remove_tile_at_mouse():
	var cell = tile_map.local_to_map(get_global_mouse_position())
	if is_cell_editable(cell):
		tile_map.erase_cell(cell)
		# reset to defalt
		tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
