class_name TerrainDatabaseResource
extends Resource

@export var terrain_textures: Array[TerrainDataResource]

var terrains := {}

func _init():
	build_terrains()


func build_terrains():
	terrains.clear()

	for terrain in terrain_textures:
		terrains[terrain.type] = terrain.texture


func get_texture(type: TerrainTypes.Type) -> Texture2D:
	if terrains.is_empty():
		build_terrains()
	
	return terrains.get(type)


func get_keys() -> Array:
	if terrains.is_empty():
		build_terrains()

	return terrains.keys()
