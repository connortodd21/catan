# TypedCacheWrapper.gd
class_name TypedCache

var cache: BaseCache
var key_type: int
var value_type: Variant


func _init(_key_type: int, _value_type: Variant):
	cache = BaseCache.new()
	key_type = _key_type
	value_type = _value_type


func get_val(key: Variant) -> Variant:
	if typeof(key) != key_type:
		return null
	
	var val = cache.get_metadata(key)
	if is_instance_of(val, value_type):
		return val
	return null


func set_val(key: Variant, value: Variant) -> void:
	if typeof(key) == key_type and is_instance_of(value, value_type):
		cache.add_to_cache(key, value)
	else:
		push_error("Cache Error: Type mismatch for Key or Value")


func evict(key: Variant) -> void:
	if typeof(key) == key_type:
		cache.evict(key)
	else:
		push_error("Cache Error: Type mismatch for Key or Value")


func clear_cache() -> void:
	cache.clear_cache()


func get_keys() -> Array[Variant]:
	return cache.get_keys()
