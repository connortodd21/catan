class_name DiscardPanel
extends PopupPanel

@onready var _hand_container: HBoxContainer = $VBoxContainer/HandContainer
@onready var _discard_label: Label = $VBoxContainer/DiscardLabel
@onready var _discard_container: HBoxContainer = $VBoxContainer/DiscardContainer
@onready var _discard_button: Button = $VBoxContainer/DiscardButton

@export var card_size: Vector2 = Vector2(60, 89)
@export var card_separation: int = 2

var _resource_definitions: Array[ResourceDefinition] = []
var _hand_resources: Array[ResourceTypes.Type] = []
var _discarded: Array[ResourceTypes.Type] = []
var _required_count: int = 0
var _on_confirmed_callback: Callable


func init(player_hand: Hand, resource_definitions: Array[ResourceDefinition], required_count: int, callback: Callable) -> void:
	_on_confirmed_callback = callback
	_resource_definitions = resource_definitions
	_required_count = required_count
	_hand_resources.clear()
	_discarded.clear()
	for resource_def in _resource_definitions:
		for _i in player_hand.resource_count(resource_def.resource_type):
			_hand_resources.append(resource_def.resource_type)
	_refresh_discard_label()
	_rebuild_hand()
	_rebuild_discard()
	reset_size()
	popup_centered()


#############################################
### DISPLAY
#############################################
func _refresh_discard_label() -> void:
	_discard_label.text = "Discard (%d / %d)" % [_discarded.size(), _required_count]


func _refresh_confirm() -> void:
	_discard_button.disabled = _discarded.size() != _required_count


func _rebuild_hand() -> void:
	_rebuild_container(_hand_container, _hand_resources, true)


func _rebuild_discard() -> void:
	_rebuild_container(_discard_container, _discarded, false)


func _rebuild_container(container: HBoxContainer, resources: Array[ResourceTypes.Type], in_hand: bool) -> void:
	for child in container.get_children():
		child.free()
	for resource_type in resources:
		var resource_def := _get_resource_def(resource_type)
		if resource_def == null:
			continue
		var callback := _on_card_pressed.bind(resource_type, in_hand)
		var card := _make_card(resource_def.texture, callback)
		container.add_child(card)
	container.add_theme_constant_override("h_separation", card_separation)


func _make_card(texture: Texture2D, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = texture
	button.add_theme_constant_override("icon_max_width", int(card_size.x))
	button.custom_minimum_size = card_size
	button.pressed.connect(callback)
	return button


func _get_resource_def(resource_type: ResourceTypes.Type) -> ResourceDefinition:
	for def in _resource_definitions:
		if def.resource_type == resource_type:
			return def
	return null


#############################################
### SIGNALS
#############################################
func _on_discard_button_pressed() -> void:
	hide()
	_on_confirmed_callback.call(_hand_resources)


func _on_card_pressed(resource_type: ResourceTypes.Type, from_hand: bool) -> void:
	if from_hand and _discarded.size() >= _required_count:
		return
	if from_hand:
		_hand_resources.erase(resource_type)
		_discarded.append(resource_type)
	else:
		_discarded.erase(resource_type)
		_hand_resources.append(resource_type)
	_hand_resources.sort_custom(ResourceTypes.compare_display_order)
	_discarded.sort_custom(ResourceTypes.compare_display_order)
	_refresh_discard_label()
	_refresh_confirm()
	_rebuild_hand.call_deferred()
	_rebuild_discard.call_deferred()
