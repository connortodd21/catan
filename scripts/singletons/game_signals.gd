extends Node

#############################################
### TURN SIGNALS
#############################################
signal player_changed(index: int)
func emit_player_changed(index: int) -> void:
	player_changed.emit(index)


signal phase_changed(phase: GamePhase.Phase)
func emit_phase_changed(phase: GamePhase.Phase) -> void:
	phase_changed.emit(phase)


signal setup_phase_ended_for_player(player_index: int, settlement_pos: Vector2)
func emit_setup_phase_ended_for_player(player_index: int, settlement_pos: Vector2) -> void:
	setup_phase_ended_for_player.emit(player_index, settlement_pos)


#############################################
### SCORE SIGNALS
#############################################
signal score_changed(player_index: int, score: int)
func emit_score_changed(player_index: int, score: int) -> void:
	score_changed.emit(player_index, score)


#############################################
### STAT SIGNALS
#############################################
signal player_stats_changed(player_index: int)
func emit_player_stats_changed(player_index: int) -> void:
	player_stats_changed.emit(player_index)


signal longest_road_holder_changed(player_index: int)
func emit_longest_road_holder_changed(player_index: int) -> void:
	longest_road_holder_changed.emit(player_index)


signal largest_army_holder_changed(player_index: int)
func emit_largest_army_holder_changed(player_index: int) -> void:
	largest_army_holder_changed.emit(player_index)


signal harbormaster_holder_changed(player_index: int)
func emit_harbormaster_holder_changed(player_index: int) -> void:
	harbormaster_holder_changed.emit(player_index)


#############################################
### TITLE SIGNALS
#############################################
signal title_holder_changed(title: TitleTypes.Type, new_holder: Player, previous_holder: Player)
func emit_title_holder_changed(title: TitleTypes.Type, new_holder: Player, previous_holder: Player) -> void:
	title_holder_changed.emit(title, new_holder, previous_holder)


#############################################
### HAND SIGNALS
#############################################
signal hand_changed()
func emit_hand_changed() -> void:
	hand_changed.emit()


signal hand_add_remove()
func emit_hand_add_remove() -> void:
	hand_add_remove.emit()


signal piece_placed(player: Player, piece_type: PieceTypes.Type, world_pos: Vector2)
func emit_piece_placed(player: Player, piece_type: PieceTypes.Type, world_pos: Vector2) -> void:
	piece_placed.emit(player, piece_type, world_pos)


signal card_clicked(card: CardDefinition)
func emit_card_clicked(card: CardDefinition) -> void:
	card_clicked.emit(card)


#############################################
### ACTION SIGNALS
#############################################
signal action_button_pressed(type: ActionTypes.Type)
func emit_action_button_pressed(type: ActionTypes.Type) -> void:
	action_button_pressed.emit(type)



signal action_mode_entered(type: ActionTypes.Type)
func emit_action_mode_entered(type: ActionTypes.Type) -> void:
	action_mode_entered.emit(type)


signal action_cancelled()
func emit_action_cancelled() -> void:
	action_cancelled.emit()


signal action_executed(type: ActionTypes.Type, position: Vector2)
func emit_action_executed(type: ActionTypes.Type, position: Vector2) -> void:
	action_executed.emit(type, position)


#############################################
### DICE SIGNALS
#############################################
signal dice_rolled(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int)
func roll_dice(die1: DiceFaces.Type, die2: DiceFaces.Type, total: int) -> void:
	dice_rolled.emit(die1, die2, total)

signal player_rolled(player: Player, total: int)
func emit_player_rolled(player: Player, total: int) -> void:
	player_rolled.emit(player, total)


#############################################
### RESOURCE SIGNALS
#############################################
signal resource_collected(player: Player, resource: ResourceTypes.Type, amount: int)
func emit_resource_collected(player: Player, resource: ResourceTypes.Type, amount: int = 1) -> void:
	resource_collected.emit(player, resource, amount)

signal resources_distributed(player: Player, resources: PlayerResources)
func emit_resources_distributed(player: Player, resources: PlayerResources) -> void:
	resources_distributed.emit(player, resources)


#############################################
### TRADE SIGNALS
#############################################
signal bank_trade_completed(player: Player, traded: Array[ResourceTypes.Type], received: Array[ResourceTypes.Type])
func emit_bank_trade_completed(player: Player, traded: Array[ResourceTypes.Type], received: Array[ResourceTypes.Type]) -> void:
	bank_trade_completed.emit(player, traded, received)


#############################################
### ROBBER SIGNALS
#############################################
signal resource_stolen(thief: Player, victim: Player, resource: ResourceTypes.Type)
func emit_resource_stolen(thief: Player, victim: Player, resource: ResourceTypes.Type) -> void:
	resource_stolen.emit(thief, victim, resource)


#############################################
### CARD SIGNALS
#############################################
signal development_card_bought(player: Player)
func emit_development_card_bought(player: Player) -> void:
	development_card_bought.emit(player)

signal development_card_played(player: Player, card_type: CardTypes.Type)
func emit_development_card_played(player: Player, card_type: CardTypes.Type) -> void:
	development_card_played.emit(player, card_type)
