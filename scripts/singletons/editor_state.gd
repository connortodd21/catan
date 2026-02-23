extends Node

#############################################
### BOARD EDITOR TILE SELECTION
#############################################
signal tile_selected(tile_id)


var selected_tile_id : TerrainTypes.Type = TerrainTypes.Type.UNKNOWN


func select_tile(tile_id: TerrainTypes.Type) -> void:
	if tile_id == selected_tile_id:
		selected_tile_id = TerrainTypes.Type.UNKNOWN
		return

	selected_tile_id = tile_id
	tile_selected.emit(tile_id)



func get_selected_tile() -> TerrainTypes.Type:
	return selected_tile_id
