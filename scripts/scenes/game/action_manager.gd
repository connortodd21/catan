class_name ActionManager
extends Node

var _actions: Dictionary[ActionTypes.Type, ActionDefinition] = {}
var _validators: Dictionary[ActionTypes.Type, Callable] = {}
var _active_action: ActionDefinition = null
var _current_phase: GamePhase.Phase = GamePhase.Phase.ROLL


func _ready() -> void:
	GameSignals.phase_changed.connect(_on_phase_changed)


func register_action(definition: ActionDefinition) -> void:
	_actions[definition.id] = definition


func register_validator(type: ActionTypes.Type, validator: Callable) -> void:
	_validators[type] = validator


func get_registered_actions() -> Array[ActionDefinition]:
	return _actions.values()


func get_action(type: ActionTypes.Type) -> ActionDefinition:
	return _actions.get(type, null)


func can_afford(type: ActionTypes.Type, hand: Hand) -> bool:
	if type not in _actions:
		return false
	var cost : Dictionary[ResourceTypes.Type, int] = _actions[type].base_cost
	for resource_type in cost:
		if hand.resource_count(resource_type) < cost[resource_type]:
			return false
	return true


func is_in_phase(type: ActionTypes.Type) -> bool:
	if type not in _actions:
		return false
	return _current_phase in _actions[type].phases


func can_perform_action(type: ActionTypes.Type, hand: Hand) -> bool:
	if type in _validators and is_in_phase(type) and can_afford(type, hand):
		return _validators[type].call()
	return false


func select_action(type: ActionTypes.Type, hand: Hand) -> void:
	if not can_perform_action(type, hand):
		return
	if _active_action != null:
		cancel()
	var action_definition : ActionDefinition = _actions[type]
	if action_definition.placement == PlacementType.Type.NONE:
		GameSignals.emit_action_executed(type, Vector2.ZERO)
		return
	_active_action = action_definition
	GameSignals.emit_action_mode_entered(type)


func cancel() -> void:
	if _active_action == null:
		return
	_active_action = null
	GameSignals.emit_action_cancelled()


func handle_board_click(position: Vector2) -> void:
	if _active_action == null:
		return
	GameSignals.emit_action_executed(_active_action.id, position)
	_active_action = null


func _on_phase_changed(phase: GamePhase.Phase) -> void:
	_current_phase = phase
	if _active_action != null and not is_in_phase(_active_action.id):
		cancel()
