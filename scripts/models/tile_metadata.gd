class_name TileMetadata

var terrain_type : TerrainTypes.Type


func _init(_terrain_type: TerrainTypes.Type) -> void:
	terrain_type = _terrain_type


func get_terrain_type() -> TerrainTypes.Type:
	return terrain_type


func _to_string() -> String:
	return "terrain_type %d" % [terrain_type]
