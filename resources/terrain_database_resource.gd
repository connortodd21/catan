class_name TerrainDatabaseResource
extends Resource

@export var terrain_data: Array[TerrainDataResource]

var terrains := {}

func _init():
	build_terrains_if_empty()


func build_terrains_if_empty():
	if terrains.is_empty():
		terrains.clear()
		for terrain in terrain_data:
			terrains[terrain.type] = terrain


func get_keys() -> Array:
	build_terrains_if_empty()
	return terrains.keys()


func get_texture(type: TerrainTypes.Type) -> Texture2D:
	build_terrains_if_empty()
	return terrains.get(type).texture


func get_atlas_coords(type: TerrainTypes.Type) -> Vector2i:
	build_terrains_if_empty()
	return terrains.get(type).atlas_coords


func get_source_id(type: TerrainTypes.Type) -> int:
	build_terrains_if_empty()
	return terrains.get(type).source_id


func get_key_from_atlas_coords(atlas_coords: Vector2i) -> TerrainTypes.Type:
	build_terrains_if_empty()
	for terrain in terrains:
		if terrains[terrain].atlas_coords == atlas_coords:
			return terrain
	return TerrainTypes.Type.UNKNOWN
