class_name TileMetadataCache

# coords to TileMetadata
var cache : Dictionary = {}


func clear_cache() -> void:
	cache = {}


func get_metadata(coords_key: Vector2i) -> TileMetadata:
	if coords_key in cache:
		return cache[coords_key]
	return null


func add_to_cache(coords: Vector2i, tile_metadata: TileMetadata) -> void:
	cache[coords] = tile_metadata


func evict(coords_key: Vector2i) -> void:
	cache.erase(coords_key)


func _debug_print() -> void:
	for key in cache:
		print("Key: %s | Value: %s" % [str(key), cache[key]])
