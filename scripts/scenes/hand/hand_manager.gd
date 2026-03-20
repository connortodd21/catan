class_name HandDisplay
extends PanelContainer

@export var definitions: Array[CardDefinition] = []
@export var card_minimum_size : Vector2 = Vector2(80,80)

@onready var cards_container: HBoxContainer = %CardsContainer

var hand: Hand


func _ready() -> void:
	hand = Hand.new()
	hand.hand_changed.connect(_on_hand_changed)


func add_card(type: CardTypes.Type) -> void:
	hand.add(type)


func remove_card(type: CardTypes.Type) -> void:
	hand.remove(type)


func count(type: CardTypes.Type) -> int:
	return hand.count(type)


func robber_count() -> int:
	return hand.robber_count()


func is_over_limit(type: CardTypes.Type) -> bool:
	return hand.is_over_limit(type)


func discard_count(type: CardTypes.Type) -> int:
	return hand.discard_count(type)


func _on_hand_changed() -> void:
	_refresh()


func _refresh() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for def in definitions:
		var number_of_cards := hand.count(def.card_type)
		if number_of_cards == 0:
			continue

		var slot := VBoxContainer.new()

		var icon := TextureRect.new()
		icon.texture = def.texture
		icon.custom_minimum_size = card_minimum_size
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)

		var label := Label.new()
		label.text = str(number_of_cards)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(label)

		cards_container.add_child(slot)
