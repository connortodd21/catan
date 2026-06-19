class_name PlayerResources
extends RefCounted

var counts: Dictionary[ResourceTypes.Type, int] = {}


func add(resource: ResourceTypes.Type, amount: int = 1) -> void:
	counts[resource] = counts.get(resource, 0) + amount


func get_count(resource: ResourceTypes.Type) -> int:
	return counts.get(resource, 0)


func is_empty() -> bool:
	return counts.is_empty()
