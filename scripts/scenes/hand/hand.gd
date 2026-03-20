class_name Hand
extends Resource

signal hand_changed

var card_type_to_count: Dictionary = {}


func add(type: CardTypes.Type) -> void:
	if type not in card_type_to_count:
		card_type_to_count[type] = 0
	card_type_to_count[type] += 1
	hand_changed.emit()


func remove(type: CardTypes.Type) -> void:
	if type in card_type_to_count:
		if card_type_to_count.get(type) > 0:
			card_type_to_count[type] -= 1
			hand_changed.emit()


func count(type: CardTypes.Type) -> int:
	if type not in card_type_to_count:
		return 0
	return card_type_to_count[type]


func robber_count() -> int:
	var total := 0
	for type: CardTypes.Type in card_type_to_count:
		if CardTypes.counts_toward_robber(type):
			total += card_type_to_count[type]
	return total


func is_over_limit(type: CardTypes.Type) -> bool:
	var max_count := CardTypes.max_in_hand(type)
	if max_count == -1:
		return false
	return count(type) > max_count
