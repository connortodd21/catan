class_name Hand
extends Resource

signal hand_changed

var resource_counts: Dictionary = {}
var cards: Array[CardDefinition] = []


#############################################
### RESOURCES
#############################################
func add_resource(type: ResourceTypes.Type) -> void:
	resource_counts[type] = resource_counts.get(type, 0) + 1
	hand_changed.emit()


func remove_resource(type: ResourceTypes.Type) -> bool:
	if resource_counts.get(type, 0) == 0:
		return false
	resource_counts[type] -= 1
	hand_changed.emit()
	return true


func resource_count(type: ResourceTypes.Type) -> int:
	return resource_counts.get(type, 0)


func robber_count() -> int:
	var total := 0
	for type: ResourceTypes.Type in resource_counts:
		if ResourceTypes.counts_toward_robber(type):
			total += resource_counts[type]
	return total


func is_over_resource_limit(type: ResourceTypes.Type) -> bool:
	var max_count := ResourceTypes.max_in_hand(type)
	if max_count == -1:
		return false
	return resource_count(type) > max_count


#############################################
### CARDS
#############################################
func add_card(definition: CardDefinition) -> void:
	cards.append(definition)
	hand_changed.emit()


func remove_card(definition: CardDefinition) -> bool:
	var idx := cards.find(definition)
	if idx == -1:
		return false
	cards.remove_at(idx)
	hand_changed.emit()
	return true


func card_count(definition: CardDefinition) -> int:
	var total := 0
	for card in cards:
		if card == definition:
			total += 1
	return total


func get_cards() -> Array[CardDefinition]:
	return cards.duplicate()


func is_over_card_limit(definition: CardDefinition) -> bool:
	return card_count(definition) > CardTypes.max_in_hand(definition.card_type)
