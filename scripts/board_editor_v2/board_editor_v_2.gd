extends Node2D

@export var terrain_database : TerrainDatabaseResource

@onready var board_editor_tile_map: TileMapLayer = $BoardEditorTileMap
@onready var camera_2d: Camera2D = $Camera2D

var tileset_source_id = 0
var default_tile_atlas_coords : Vector2i = Vector2i(4,0)
var border_tile_atlas_coords : Vector2i = Vector2i(5,0)
@export var board_width := 9
@export var board_height := 9


func _ready() -> void:
	connect_signals()


#############################################
### SIGNALS
#############################################
func connect_signals() -> void:
	EditorState.board_cleared.connect(_on_board_cleared)

func _on_board_cleared() -> void:
	var used_cells = board_editor_tile_map.get_used_cells()
	for cell in used_cells:
		if board_editor_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords:
			board_editor_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)

#############################################
### CAMERA
#############################################


#############################################
### TILE MAP
#############################################
func is_cell_editable(cell: Vector2i) -> bool:
	return board_editor_tile_map.get_cell_atlas_coords(cell) != border_tile_atlas_coords


#############################################
### INPUT HANDLING
#############################################
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tile_at_mouse()


func place_tile_at_mouse():
	var cell = board_editor_tile_map.local_to_map(get_local_mouse_position())
	var tile = EditorState.get_selected_tile()
	if is_cell_editable(cell) and tile != TerrainTypes.Type.UNKNOWN:
		board_editor_tile_map.erase_cell(cell)
		board_editor_tile_map.set_cell(cell, terrain_database.get_source_id(tile), terrain_database.get_atlas_coords(tile))


func remove_tile_at_mouse():
	var cell = board_editor_tile_map.local_to_map(get_global_mouse_position())
	if is_cell_editable(cell):
		board_editor_tile_map.erase_cell(cell)
		# reset to defalt
		board_editor_tile_map.set_cell(cell, tileset_source_id, default_tile_atlas_coords)
