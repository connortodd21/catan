extends Node

#############################################
### BOARD GENERATION SIGNALS
#############################################
signal board_generate_requested(config: GenerationConfig)
func generate_board(config: GenerationConfig):
	board_generate_requested.emit(config)

#############################################
### BOARD EDITOR SIGNALS
#############################################
signal board_cleared
func clear_board() -> void:
	board_cleared.emit()

signal board_saved
func save_board() -> void:
	board_saved.emit()

signal board_load
func load_board() -> void:
	board_load.emit()


#############################################
### BOARD EDITOR STATE
#############################################
enum SelectionType {
	NONE,
	TERRAIN,
	NUMBER
}

var editor_state : SelectionType = SelectionType.NONE

func set_editor_state_to_terrain() -> void:
	editor_state = SelectionType.TERRAIN

func set_editor_state_to_number() -> void:
	editor_state = SelectionType.NUMBER

func get_editor_state() -> SelectionType:
	return editor_state

#############################################
### BOARD EDITOR TILE SELECTION
#############################################
signal tile_selected(tile_id:TerrainTypes.Type )

var selected_tile_id : TerrainTypes.Type = TerrainTypes.Type.UNKNOWN

func clear_selected_tile() -> void:
	selected_tile_id = TerrainTypes.Type.UNKNOWN


func select_tile(tile_id: TerrainTypes.Type) -> void:
	if tile_id == selected_tile_id:
		selected_tile_id = TerrainTypes.Type.UNKNOWN
		return

	selected_tile_id = tile_id
	tile_selected.emit(tile_id)


func get_selected_tile() -> TerrainTypes.Type:
	return selected_tile_id


#############################################
### BOARD EDITOR NUMBER SELECTION
#############################################
signal number_selected(number: int)

var selected_number : int = -1

func clear_selected_number() -> void:
	selected_number = -1


func select_number(number: int) -> void:
	if number == selected_number:
		selected_number = -1
		return

	selected_number = number
	number_selected.emit(selected_number)


func get_selected_number() -> int:
	return selected_number
