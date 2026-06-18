class_name DiceStats
extends RefCounted

var roll_counts: Dictionary[int, int] = {}


func record_roll(roll_total: int) -> void:
	roll_counts[roll_total] = roll_counts.get(roll_total, 0) + 1


func get_roll_count(roll_total: int) -> int:
	return roll_counts.get(roll_total, 0)


func get_max_roll_count() -> int:
	var max_count := 0
	for count in roll_counts.values():
		max_count = max(max_count, count)
	return max_count
