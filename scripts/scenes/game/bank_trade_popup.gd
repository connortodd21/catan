class_name BankTradePopup
extends PopupPanel

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _hand_container: HBoxContainer = $VBoxContainer/HandContainer
@onready var _trade_container: HBoxContainer = $VBoxContainer/TradeContainer
@onready var _receive_container: HBoxContainer = $VBoxContainer/ReceiveContainer
@onready var _bank_container: HBoxContainer = $VBoxContainer/BankContainer
@onready var _trade_button: Button = $VBoxContainer/ButtonContainer/TradeButton

const ON_CLICK_CALLBACK_KEY: String = "on_click_callback"
const DEFAULT_TRADE_RATE: int = 4

@export var card_size: Vector2 = Vector2(60, 89)
@export var card_separation: int = 1

var _resource_definitions: Array[ResourceDefinition] = []
var _trade_rates: Dictionary[ResourceTypes.Type, int] = {}
var _hand_resources: Array[ResourceTypes.Type] = []
var _traded: Array[ResourceTypes.Type] = []
var _received: Array[ResourceTypes.Type] = []
var _on_confirmed_callback: Callable


func _ready() -> void:
	_hand_container.set_meta(ON_CLICK_CALLBACK_KEY, _on_hand_card_pressed)
	_trade_container.set_meta(ON_CLICK_CALLBACK_KEY, _on_trade_card_pressed)
	_receive_container.set_meta(ON_CLICK_CALLBACK_KEY, _on_receive_card_pressed)
	_trade_button.pressed.connect(_on_trade_button_pressed)


func init(hand: Hand, resource_definitions: Array[ResourceDefinition], trade_rates: Dictionary[ResourceTypes.Type, int], callback: Callable) -> void:
	_header.set_title("Bank Trade")
	_on_confirmed_callback = callback
	_resource_definitions = resource_definitions
	_trade_rates = trade_rates
	_hand_resources.clear()
	_traded.clear()
	_received.clear()
	for resource_def in _resource_definitions:
		for _i in hand.resource_count(resource_def.resource_type):
			_hand_resources.append(resource_def.resource_type)
	_rebuild_all()
	_build_bank()
	_refresh_trade_button()
	reset_size()
	popup_centered()


#############################################
### DISPLAY
#############################################
func _rebuild_all() -> void:
	_rebuild_hand()
	_rebuild_traded()
	_rebuild_receive()


func _rebuild_hand() -> void:
	_rebuild_container(_hand_container, _hand_resources)


func _rebuild_traded() -> void:
	_rebuild_container(_trade_container, _traded)


func _rebuild_receive() -> void:
	_rebuild_container(_receive_container, _received)


func _rebuild_container(container: HBoxContainer, resources: Array[ResourceTypes.Type]) -> void:
	for child in container.get_children():
		child.free()
	var on_click: Callable = container.get_meta(ON_CLICK_CALLBACK_KEY)
	for resource_type in resources:
		var resource_def := _get_resource_def(resource_type)
		if resource_def == null:
			continue
		var card := _make_card_with_callback(resource_def.texture, on_click.bind(resource_type))
		container.add_child(card)
	container.add_theme_constant_override("h_separation", card_separation)


func _build_bank() -> void:
	for child in _bank_container.get_children():
		child.free()
	for resource_def in _resource_definitions:
		var trade_rate: int = _trade_rates.get(resource_def.resource_type, DEFAULT_TRADE_RATE)
		var bank_resource_vbox := VBoxContainer.new()
		var card := _make_card_with_callback(resource_def.texture, _on_bank_card_pressed.bind(resource_def.resource_type))
		var trade_rate_label := Label.new()
		trade_rate_label.text = "%d:1" % trade_rate
		trade_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bank_resource_vbox.add_child(card)
		bank_resource_vbox.add_child(trade_rate_label)
		_bank_container.add_child(bank_resource_vbox)
	_bank_container.add_theme_constant_override("h_separation", card_separation)


func _refresh_trade_button() -> void:
	_trade_button.disabled = not _is_valid_trade()


func _is_valid_trade() -> bool:
	if _traded.is_empty() or _received.is_empty():
		return false
	var traded_counts: Dictionary = {}
	for resource_type: ResourceTypes.Type in _traded:
		traded_counts[resource_type] = traded_counts.get(resource_type, 0) + 1
	var valid_exchanges: int = 0
	for resource_type: ResourceTypes.Type in traded_counts:
		var trade_rate: int = _trade_rates.get(resource_type, DEFAULT_TRADE_RATE)
		if traded_counts[resource_type] % trade_rate != 0:
			return false
		valid_exchanges += traded_counts[resource_type] / trade_rate
	return _received.size() == valid_exchanges


func _make_card(texture: Texture2D) -> Button:
	var button := Button.new()
	button.icon = texture
	button.add_theme_constant_override("icon_max_width", int(card_size.x))
	button.custom_minimum_size = card_size
	return button


func _make_card_with_callback(texture: Texture2D, callback: Callable) -> Button:
	var button := _make_card(texture)
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
func _on_trade_button_pressed() -> void:
	var traded: Array[ResourceTypes.Type] = _traded.duplicate()
	var received: Array[ResourceTypes.Type] = _received.duplicate()
	_hand_resources.clear()
	_traded.clear()
	_received.clear()
	hide()
	_on_confirmed_callback.call(traded, received)


func _on_cancel_button_pressed() -> void:
	_hand_resources.clear()
	_traded.clear()
	_received.clear()
	hide()


func _on_clear_button_pressed() -> void:
	_hand_resources.append_array(_traded)
	_hand_resources.sort_custom(ResourceTypes.compare_display_order)
	_traded.clear()
	_received.clear()
	_rebuild_all()
	_refresh_trade_button()


func _on_hand_card_pressed(resource_type: ResourceTypes.Type) -> void:
	_hand_resources.erase(resource_type)
	_traded.append(resource_type)
	_hand_resources.sort_custom(ResourceTypes.compare_display_order)
	_traded.sort_custom(ResourceTypes.compare_display_order)
	_refresh_trade_button()
	_rebuild_hand.call_deferred()
	_rebuild_traded.call_deferred()


func _on_trade_card_pressed(resource_type: ResourceTypes.Type) -> void:
	_traded.erase(resource_type)
	_hand_resources.append(resource_type)
	_hand_resources.sort_custom(ResourceTypes.compare_display_order)
	_traded.sort_custom(ResourceTypes.compare_display_order)
	_refresh_trade_button()
	_rebuild_hand.call_deferred()
	_rebuild_traded.call_deferred()


func _on_bank_card_pressed(resource_type: ResourceTypes.Type) -> void:
	_received.append(resource_type)
	_received.sort_custom(ResourceTypes.compare_display_order)
	_refresh_trade_button()
	_rebuild_receive.call_deferred()


func _on_receive_card_pressed(resource_type: ResourceTypes.Type) -> void:
	_received.erase(resource_type)
	_refresh_trade_button()
	_rebuild_receive.call_deferred()
