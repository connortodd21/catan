class_name ResourceStats
extends RefCounted

var resource_counts: Dictionary[ResourceTypes.Type, int] = {}


func _init() -> void:
	GameSignals.resource_collected.connect(_on_resource_collected)


func _on_resource_collected(_player: Player, resource: ResourceTypes.Type, amount: int) -> void:
	record_resource(resource, amount)


func record_resource(resource: ResourceTypes.Type, amount: int = 1) -> void:
	resource_counts[resource] = resource_counts.get(resource, 0) + amount


func get_resource_count(resource: ResourceTypes.Type) -> int:
	return resource_counts.get(resource, 0)


func get_max_resource_count() -> int:
	var max_count := 0
	for count in resource_counts.values():
		max_count = max(max_count, count)
	return max_count
