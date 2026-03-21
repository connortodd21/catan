class_name HandManager
extends PanelContainer

@export var resource_definitions: Array[ResourceDefinition] = []
@export var card_minimum_size: Vector2 = Vector2(80, 80)

@onready var resources_container: HBoxContainer = %ResourcesContainer
@onready var cards_container: HBoxContainer = %CardsContainer

var hand: Hand


func _ready() -> void:
	hand = Hand.new()
	hand.hand_changed.connect(_onhand_changed)


#############################################
### RESOURCES
#############################################
func add_resource(type: ResourceTypes.Type) -> void:
	hand.add_resource(type)


func remove_resource(type: ResourceTypes.Type) -> bool:
	return hand.remove_resource(type)


func resource_count(type: ResourceTypes.Type) -> int:
	return hand.resource_count(type)


func robber_count() -> int:
	return hand.robber_count()


func is_over_resource_limit(type: ResourceTypes.Type) -> bool:
	return hand.is_over_resource_limit(type)


#############################################
### CARDS
#############################################
func add_card(definition: CardDefinition) -> void:
	hand.add_card(definition)


func remove_card(definition: CardDefinition) -> bool:
	return hand.remove_card(definition)


func card_count(definition: CardDefinition) -> int:
	return hand.card_count(definition)


#############################################
### DISPLAY
#############################################
func _onhand_changed() -> void:
	_refresh()


func _refresh() -> void:
	_refresh_resources()
	_refresh_cards()


func _refresh_resources() -> void:
	for child in resources_container.get_children():
		child.queue_free()

	for def in resource_definitions:
		var n := hand.resource_count(def.resource_type)
		if n == 0:
			continue
		resources_container.add_child(_make_slot(def.texture, n))


func _refresh_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	var seen: Array[CardDefinition] = []
	for def in hand.get_cards():
		if def in seen:
			continue
		seen.append(def)
		cards_container.add_child(_make_slot(def.texture, hand.card_count(def)))


func _make_slot(texture: Texture2D, count: int) -> VBoxContainer:
	var slot := VBoxContainer.new()

	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = card_minimum_size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)

	var label := Label.new()
	label.text = str(count)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_child(label)

	return slot
