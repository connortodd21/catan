class_name HandManager
extends Control

const RESOURCE_ORDER: Array[ResourceTypes.Type] = [
	ResourceTypes.Type.WOOD,
	ResourceTypes.Type.BRICK,
	ResourceTypes.Type.SHEEP,
	ResourceTypes.Type.WHEAT,
	ResourceTypes.Type.ROCK,
]

@export var resource_definitions: Array[ResourceDefinition] = []
@export var card_size: Vector2 = Vector2(120, 178)
@export var card_step: float = 50.0
@export var hover_raise: float = 40.0

@onready var fan_container: Control = $FanContainer

var hand: Hand
var _cards: Array[TextureRect] = []
var _hovered_card: TextureRect = null


func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _hovered_card != null and _hovered_card.has_meta(HandUtils.CARD_DEF_META):
				GameSignals.emit_card_clicked(_hovered_card.get_meta(HandUtils.CARD_DEF_META))


func _process(_delta: float) -> void:
	if _cards.is_empty():
		return
	var card_under_mouse := get_card_at_position(fan_container.get_local_mouse_position())
	if card_under_mouse == _hovered_card:
		return
	if _hovered_card:
		_unhover(_hovered_card)
	_hovered_card = card_under_mouse
	if _hovered_card:
		_hover(_hovered_card)


func get_card_at_position(pos: Vector2) -> TextureRect:
	for i in range(_cards.size() - 1, -1, -1):
		var rect := Rect2(Vector2(i * card_step, 0.0), card_size + Vector2(0.0, hover_raise))
		if rect.has_point(pos):
			return _cards[i]
	return null


func _hover(card: TextureRect) -> void:
	card.position.y = 0.0
	card.z_index = _cards.size()


func _unhover(card: TextureRect) -> void:
	var index := _cards.find(card)
	card.position.y = hover_raise
	card.z_index = _cards.size() - 1 - index


func set_hand(new_hand: Hand) -> void:
	if hand:
		hand.hand_add_remove.disconnect(_on_hand_add_remove)
	hand = new_hand
	hand.hand_add_remove.connect(_on_hand_add_remove)
	_rebuild_fan()


#############################################
### DISPLAY
#############################################
func _on_hand_add_remove() -> void:
	_rebuild_fan()


func _rebuild_fan() -> void:
	_hovered_card = null
	_cards.clear()
	for child in fan_container.get_children():
		child.free()

	var entries := _get_all_card_entries()
	var n := entries.size()
	for i in n:
		var entry: Dictionary = entries[i]
		var card := _create_card(entry[HandUtils.TEXTURE_KEY], i, entry.get(HandUtils.CARD_DEF_META))
		card.z_index = n - 1 - i
		_cards.append(card)

	var total_width := (n - 1) * card_step + card_size.x if n > 0 else card_size.x
	var total_height := card_size.y + hover_raise
	fan_container.size = Vector2(total_width, total_height)
	offset_right = offset_left + total_width
	offset_top = offset_bottom - total_height


func _get_all_card_entries() -> Array:
	var entries: Array = []
	var sorted_resource_definitions : Array[ResourceDefinition] = get_sorted_resource_definitions()
	for resource_definition in sorted_resource_definitions:
		var hand_resource_count : int = hand.resource_count(resource_definition.resource_type)
		for _j in hand_resource_count:
			entries.append({HandUtils.TEXTURE_KEY: resource_definition.texture})
	for card_def in hand.get_cards():
		entries.append({HandUtils.TEXTURE_KEY: card_def.texture, HandUtils.CARD_DEF_META: card_def})
	return entries


func get_sorted_resource_definitions() -> Array[ResourceDefinition]:
	var sorted: Array[ResourceDefinition] = []
	for type in RESOURCE_ORDER:
		for def in resource_definitions:
			if def.resource_type == type:
				sorted.append(def)
				break
	return sorted


func _create_card(texture: Texture2D, index: int, card_def: CardDefinition = null) -> TextureRect:
	var card := TextureRect.new()
	card.texture = texture
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_SCALE
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	if card_def != null:
		card.set_meta(HandUtils.CARD_DEF_META, card_def)

	fan_container.add_child(card)

	card.size = card_size
	card.position = Vector2(index * card_step, hover_raise)

	return card
