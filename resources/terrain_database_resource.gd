class_name TerrainDatabaseResource
extends Resource

@export var terrain_data: Array[TerrainDataResource]

var terrains := {}

func _init():
	build_terrains()


func build_terrains():
	terrains.clear()

	for terrain in terrain_data:
		terrains[terrain.type] = terrain


func get_texture(type: TerrainTypes.Type) -> Texture2D:
	if terrains.is_empty():
		build_terrains()
	
	return terrains.get(type).texture


func get_keys() -> Array:
	if terrains.is_empty():
		build_terrains()

	return terrains.keys()


func get_atlas_coords(type: TerrainTypes.Type) -> Vector2i:
	if terrains.is_empty():
		build_terrains()
	
	return terrains.get(type).atlas_coords


func get_source_id(type: TerrainTypes.Type) -> int:
	if terrains.is_empty():
		build_terrains()
	
	return terrains.get(type).source_id
