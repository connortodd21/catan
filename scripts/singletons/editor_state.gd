extends Node

#############################################
### BOARD EDITOR SIGNALS
#############################################
signal board_cleared
func clear_board():
	board_cleared.emit()

signal board_saved
func save_board():
	board_saved.emit()
#############################################
### BOARD EDITOR TILE SELECTION
#############################################
signal tile_selected(tile_id)

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
