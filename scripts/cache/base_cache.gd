class_name BaseCache

var cache : Dictionary = {}


func clear_cache() -> void:
	cache = {}


func get_metadata(key: Variant) -> Variant:
	if key in cache:
		return cache[key]
	return null


func add_to_cache(key: Variant, value: Variant) -> void:
	cache[key] = value


func evict(key: Variant) -> void:
	cache.erase(key)


func get_keys() -> Array[Variant]:
	return cache.keys()


func _debug_print() -> void:
	for key in cache:
		print("Key: %s | Value: %s" % [str(key), cache[key]])
