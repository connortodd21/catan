class_name ActionPanel
extends PanelContainer

var _action_manager: ActionManager
var _buttons: Dictionary[ActionTypes.Type, Button] = {}
var _active_type: Variant = null


func init(action_manager: ActionManager) -> void:
	_action_manager = action_manager
	GameSignals.action_mode_entered.connect(_on_action_mode_entered)
	GameSignals.action_cancelled.connect(_on_action_deactivated)
	GameSignals.action_executed.connect(func(_t, _p): _on_action_deactivated())


func build_buttons() -> void:
	var group := ButtonGroup.new()
	group.allow_unpress = true
	var vbox := VBoxContainer.new()
	add_child(vbox)
	for definition in _action_manager.get_registered_actions():
		var button := Button.new()
		button.text = ActionTypes.type_to_label(definition.id)
		button.toggle_mode = true
		button.button_group = group
		button.disabled = true
		button.pressed.connect(func(): GameSignals.emit_action_button_pressed(definition.id))
		vbox.add_child(button)
		_buttons[definition.id] = button


func refresh(hand: Hand) -> void:
	for type in _buttons:
		_buttons[type].disabled = not _action_manager.can_perform_action(type, hand)


func _on_action_mode_entered(action_type: ActionTypes.Type) -> void:
	_active_type = action_type
	if action_type in _buttons:
		_buttons[action_type].button_pressed = true


func _on_action_deactivated() -> void:
	if _active_type != null and _active_type in _buttons:
		_buttons[_active_type].button_pressed = false
	_active_type = null
