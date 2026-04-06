class_name CardManager
extends Node

var _handlers: Dictionary[CardTypes.Type, Callable] = {}


func register_handler(type: CardTypes.Type, handler: Callable) -> void:
	_handlers[type] = handler


func play_card(card: CardDefinition, player_state: PlayerState) -> void:
	player_state.hand.remove_card(card)
	if card.card_type in _handlers:
		_handlers[card.card_type].call()
