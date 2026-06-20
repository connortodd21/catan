class_name ActivityLog
extends RefCounted

var entries: Array[ActivityEntry] = []


func _init() -> void:
	GameSignals.player_changed.connect(_on_player_changed)
	GameSignals.player_rolled.connect(_on_player_rolled)
	GameSignals.resources_distributed.connect(_on_resources_distributed)
	GameSignals.piece_placed.connect(_on_piece_placed)
	GameSignals.development_card_bought.connect(_on_development_card_bought)
	GameSignals.development_card_played.connect(_on_development_card_played)
	GameSignals.bank_trade_completed.connect(_on_bank_trade_completed)
	GameSignals.resource_stolen.connect(_on_resource_stolen)
	GameSignals.title_holder_changed.connect(_on_title_holder_changed)


func _append(player: Player, event_type: ActivityEvent.Type, activity_metadata: Dictionary = {}) -> void:
	entries.append(ActivityEntry.new(player, event_type, activity_metadata))


func _on_player_changed(_index: int) -> void:
	if entries.is_empty():
		return
	_append(null, ActivityEvent.Type.TURN_CHANGE)


func _on_player_rolled(player: Player, total: int) -> void:
	_append(player, ActivityEvent.Type.DICE_ROLLED, { ActivityEntry.KEY_TOTAL: total })


func _on_resources_distributed(player: Player, resources: PlayerResources) -> void:
	_append(player, ActivityEvent.Type.RESOURCES_DISTRIBUTED, { ActivityEntry.KEY_RESOURCES: resources })


func _on_piece_placed(player: Player, piece_type: PieceTypes.Type, _world_pos: Vector2) -> void:
	_append(player, ActivityEvent.Type.PIECE_PLACED, { ActivityEntry.KEY_PIECE_TYPE: piece_type })
	if piece_type == PieceTypes.Type.SETTLEMENT or piece_type == PieceTypes.Type.CITY:
		_append(player, ActivityEvent.Type.VP_CHANGED, { ActivityEntry.KEY_AMOUNT: 1 })


func _on_development_card_bought(player: Player) -> void:
	_append(player, ActivityEvent.Type.DEVELOPMENT_CARD_BOUGHT)


func _on_development_card_played(player: Player, card_type: CardTypes.Type) -> void:
	_append(player, ActivityEvent.Type.DEVELOPMENT_CARD_PLAYED, { ActivityEntry.KEY_CARD_TYPE: card_type })


func _on_bank_trade_completed(player: Player, traded: Array[ResourceTypes.Type], received: Array[ResourceTypes.Type]) -> void:
	_append(player, ActivityEvent.Type.BANK_TRADE, { ActivityEntry.KEY_TRADED: traded, ActivityEntry.KEY_RECEIVED: received })


func _on_resource_stolen(thief: Player, victim: Player, resource: ResourceTypes.Type) -> void:
	_append(thief, ActivityEvent.Type.RESOURCE_STOLEN, { ActivityEntry.KEY_VICTIM: victim, ActivityEntry.KEY_RESOURCE: resource })


func _on_title_holder_changed(title: TitleTypes.Type, new_holder: Player, previous_holder: Player) -> void:
	if new_holder:
		_append(new_holder, ActivityEvent.Type.TITLE_CHANGED, { ActivityEntry.KEY_TITLE: title, ActivityEntry.KEY_PREVIOUS_HOLDER: previous_holder })
		_append(new_holder, ActivityEvent.Type.VP_CHANGED, { ActivityEntry.KEY_AMOUNT: 2 })
	else:
		_append(previous_holder, ActivityEvent.Type.TITLE_LOST, { ActivityEntry.KEY_TITLE: title })
	if previous_holder:
		_append(previous_holder, ActivityEvent.Type.VP_CHANGED, { ActivityEntry.KEY_AMOUNT: -2 })
