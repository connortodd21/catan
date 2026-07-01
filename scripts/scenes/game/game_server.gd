class_name GameServer
extends Node

const NEWLY_BOUGHT_CARD_META = "newly_bought"

# Databases
@export var action_database: ActionDatabaseResource
@export var decks: Array[CardDeck] = []

# Titles
@export var min_harbormaster: int = 3
@export var min_largest_army: int = 3
@export var min_longest_road: int = 5

# Config
var game_config: GameConfig

# Managers
var action_manager: ActionManager
var activity_log: ActivityLog = ActivityLog.new()
var board_state: BoardState
var card_manager: CardManager
var game_stats: GameStats = GameStats.new()
var setup_manager: SetupManager
var turn_manager: TurnManager

# Players
var player_states: Array[PlayerState] = []


# Game state
var _draw_piles: Dictionary = {}
var _harbormaster_holder: PlayerState = null
var _largest_army_holder: PlayerState = null
var _longest_road_holder: PlayerState = null
var _robber_coord: Vector2i = Vector2i(-999, -999)
var target_vp: int = 10


#############################################
### INIT
#############################################
func init(p_game_config: GameConfig, board_tile_map: TileMapLayer) -> void:
	if not multiplayer.is_server():
		return
	game_config = p_game_config
	target_vp = game_config.victory_points
	_init_board(board_tile_map)
	_init_players()
	_init_managers()


func _init_board(board_tile_map: TileMapLayer) -> void:
	board_state = BoardState.new()
	board_state.build(game_config.board, board_tile_map)
	if game_config.has_robber():
		_place_robber_on_desert()


func start_game() -> void:
	if not multiplayer.is_server():
		return
	setup_manager.begin(player_states.size())


func _place_robber_on_desert() -> void:
	for tile: TileEntry in game_config.board.tiles:
		if tile.type == TerrainTypes.Type.DESERT:
			_robber_coord = Vector2i(tile.x, tile.y)
			return


func _init_players() -> void:
	for player: Player in game_config.players:
		player_states.append(PlayerState.new(player))
	game_stats.player_game_stats.register_players(game_config.players)


func _init_managers() -> void:
	turn_manager = TurnManager.new()

	action_manager = ActionManager.new()
	action_manager.init()
	for action in action_database.actions:
		action_manager.register_action(action)
	_register_action_validators()

	card_manager = CardManager.new()
	card_manager.init(action_manager, turn_manager)
	_register_card_handlers()

	setup_manager = SetupManager.new()
	setup_manager.init(action_manager, turn_manager, board_state)
	_load_dev_decks()


#############################################
### ACTION VALIDATORS
#############################################
func _register_action_validators() -> void:
	action_manager.register_validator(ActionTypes.Type.BUILD_SETTLEMENT, _can_perform_settlement)
	action_manager.register_validator(ActionTypes.Type.BUILD_ROAD, _can_perform_road)
	action_manager.register_validator(ActionTypes.Type.BUILD_CITY, _can_perform_city)
	action_manager.register_validator(ActionTypes.Type.BUY_DEVELOPMENT_CARD, _can_perform_buy_development_card)
	action_manager.register_validator(ActionTypes.Type.TRADE, _can_perform_trade)


func _can_perform_settlement() -> bool:
	var require_road := turn_manager.current_phase != GamePhase.Phase.SETUP
	return board_state.player_has_valid_settlement_placement(turn_manager.current_player_index, require_road)


func _can_perform_road() -> bool:
	return board_state.has_valid_road_placement(turn_manager.current_player_index)


func _can_perform_city() -> bool:
	return board_state.has_valid_city_placement(turn_manager.current_player_index)


func _can_perform_buy_development_card() -> bool:
	return not _draw_piles.get(Deck.Type.STANDARD, []).is_empty()


func _can_perform_trade() -> bool:
	return true


#############################################
### CARD HANDLERS
#############################################
func _register_card_handlers() -> void:
	card_manager.register_handler(CardTypes.Type.VICTORY_POINT, _on_play_victory_point)
	card_manager.register_handler(CardTypes.Type.KNIGHT, _on_play_knight)
	card_manager.register_handler(CardTypes.Type.ROAD_BUILDING, _on_play_road_building)
	card_manager.register_handler(CardTypes.Type.YEAR_OF_PLENTY, _on_play_year_of_plenty)
	card_manager.register_handler(CardTypes.Type.MONOPOLY, _on_play_monopoly)
	# TODO: YEAR_OF_PLENTY and MONOPOLY require UI interaction — handle via GameSignals


func _on_play_victory_point() -> void:
	var player_index := turn_manager.current_player_index
	player_states[player_index].vp_cards_played += 1
	player_states[player_index].score += 1
	GameSignals.emit_score_changed(player_index, player_states[player_index].score)


func _on_play_knight() -> void:
	var player_index := turn_manager.current_player_index
	player_states[player_index].army_size += 1
	_check_largest_army(player_index)
	turn_manager.enter_robber_phase()


func _on_play_road_building() -> void:
	card_manager.begin_road_building()


func _on_play_year_of_plenty() -> void:
	pass # TODO: request resource selection from current player via RPC


func _on_play_monopoly() -> void:
	pass # TODO: request resource selection from current player via RPC


#############################################
### DEV DECK
#############################################
func _load_dev_decks() -> void:
	for deck: CardDeck in decks:
		var pile: Array[CardDefinition] = deck.deck.duplicate()
		pile.shuffle()
		_draw_piles[deck.deck_type] = pile


func _draw_development_card(deck_type: Deck.Type) -> void:
	var pile: Array[CardDefinition] = _draw_piles.get(deck_type, [])
	if pile.is_empty():
		return
	var card: CardDefinition = pile.pop_back().duplicate()
	card.set_meta(NEWLY_BOUGHT_CARD_META, true)
	var player_state := player_states[turn_manager.current_player_index]
	player_state.hand.add_card(card)
	GameSignals.emit_development_card_bought(player_state.player)


func _clear_newly_bought_cards(player_index: int) -> void:
	for card in player_states[player_index].hand.get_cards():
		card.set_meta(NEWLY_BOUGHT_CARD_META, false)


#############################################
### PIECE PLACEMENT
#############################################
func _can_place(action: ActionTypes.Type, world_pos: Vector2) -> bool:
	var player_index := turn_manager.current_player_index
	match action:
		ActionTypes.Type.BUILD_SETTLEMENT:
			var require_road := turn_manager.current_phase != GamePhase.Phase.SETUP
			return board_state.can_place_settlement(world_pos, player_index, require_road)
		ActionTypes.Type.BUILD_ROAD:
			if turn_manager.current_phase == GamePhase.Phase.SETUP:
				return setup_manager.is_setup_road_valid(world_pos)
			return board_state.can_place_road(world_pos, player_index)
		ActionTypes.Type.BUILD_CITY:
			return board_state.can_place_city(world_pos, player_index)
	return true


func _place_piece_at(piece_type: PieceTypes.Type, world_pos: Vector2) -> void:
	board_state.record_placement(piece_type, world_pos, turn_manager.current_player_index)


func _update_score(action: ActionTypes.Type, player_index: int) -> void:
	var delta: int = GameUtils.action_to_victory_points(action)
	player_states[player_index].score += delta
	GameSignals.emit_score_changed(player_index, player_states[player_index].score)


func _recalculate_score(player_index: int) -> int:
	var player_state := player_states[player_index]
	var total := 0

	for entry in board_state.vertex_ownership.values():
		if entry.player_index != player_index:
			continue
		match entry.piece_type:
			PieceTypes.Type.SETTLEMENT: total += 1
			PieceTypes.Type.CITY: total += 2

	if _longest_road_holder == player_state: total += 2
	if _largest_army_holder == player_state: total += 2
	if _harbormaster_holder == player_state: total += 2
	total += player_state.vp_cards_played

	return total


func _deduct_cost(definition: ActionDefinition) -> void:
	if CostUtils.is_free(definition.id, turn_manager.current_phase):
		return
	var hand := player_states[turn_manager.current_player_index].hand
	for resource_type: ResourceTypes.Type in definition.base_cost:
		for i in definition.base_cost[resource_type]:
			hand.remove_resource(resource_type)
	GameSignals.emit_hand_changed()


#############################################
### TITLE CHECKS
#############################################
func _check_titles(action: ActionTypes.Type, player_index: int) -> void:
	match action:
		ActionTypes.Type.BUILD_ROAD:
			_check_longest_road(player_index)
		ActionTypes.Type.BUILD_SETTLEMENT:
			_check_harbormaster(player_index)
			_recheck_longest_road_on_settlement(player_index)
		ActionTypes.Type.BUILD_CITY:
			_check_harbormaster(player_index)


func _check_longest_road(player_index: int) -> void:
	var player_longest_road := board_state.calculate_longest_road(player_index)
	player_states[player_index].longest_road_length = player_longest_road
	GameSignals.emit_player_stats_changed(player_index)

	var current_best := _longest_road_holder.longest_road_length if _longest_road_holder else 0
	if player_longest_road < min_longest_road or player_longest_road <= current_best:
		return

	var previous_holder_index := player_states.find(_longest_road_holder) if _longest_road_holder else -1
	_update_longest_road_holder(previous_holder_index, player_index)


func _recheck_longest_road_on_settlement(player_index: int) -> void:
	if _longest_road_holder == null:
		return
	var holder_index := player_states.find(_longest_road_holder)
	if holder_index == player_index:
		return
	_recalculate_road_lengths_excluding(player_index)
	var new_leader := _find_longest_road_holder()
	if new_leader == holder_index:
		return
	_update_longest_road_holder(holder_index, new_leader)


func _recalculate_road_lengths_excluding(player_to_exclude_idx: int) -> void:
	for i in player_states.size():
		if i == player_to_exclude_idx:
			continue
		player_states[i].longest_road_length = board_state.calculate_longest_road(i)
		GameSignals.emit_player_stats_changed(i)


func _find_longest_road_holder() -> int:
	var best_length := 0
	var best_index := -1

	for i in player_states.size():
		var length := player_states[i].longest_road_length
		if length > best_length:
			best_length = length
			best_index = i
		elif length == best_length:
			best_index = -1

	return best_index if best_length >= min_longest_road else -1


func _update_longest_road_holder(previous_holder_index: int, new_holder_index: int) -> void:
	var previous_player: Player = null

	if previous_holder_index != -1:
		player_states[previous_holder_index].score -= 2
		GameSignals.emit_score_changed(previous_holder_index, player_states[previous_holder_index].score)
		previous_player = player_states[previous_holder_index].player

	_longest_road_holder = null

	if new_holder_index == -1:
		GameSignals.emit_longest_road_holder_changed(-1)
		GameSignals.emit_title_holder_changed(TitleTypes.Type.LONGEST_ROAD, null, previous_player)
	else:
		player_states[new_holder_index].score += 2
		GameSignals.emit_score_changed(new_holder_index, player_states[new_holder_index].score)
		_longest_road_holder = player_states[new_holder_index]
		GameSignals.emit_longest_road_holder_changed(new_holder_index)
		GameSignals.emit_title_holder_changed(TitleTypes.Type.LONGEST_ROAD, player_states[new_holder_index].player, previous_player)


func _check_largest_army(player_index: int) -> void:
	var player_army_size: int = player_states[player_index].army_size
	GameSignals.emit_player_stats_changed(player_index)

	var largest_army: int = _largest_army_holder.army_size if _largest_army_holder else 0
	if player_army_size < min_largest_army or player_army_size <= largest_army:
		return

	var player: PlayerState = player_states[player_index]
	if player != _largest_army_holder:
		var previous_holder := _largest_army_holder
		_award_title(previous_holder, player, player_index)
		_largest_army_holder = player
		GameSignals.emit_largest_army_holder_changed(player_index)
		GameSignals.emit_title_holder_changed(TitleTypes.Type.LARGEST_ARMY, player.player, previous_holder.player if previous_holder else null)


func _check_harbormaster(player_index: int) -> void:
	if not game_config.has_harbormaster():
		return

	var player_harbor_count: int = board_state.calculate_harbormaster_count(player_index)
	player_states[player_index].harbormaster_count = player_harbor_count
	GameSignals.emit_player_stats_changed(player_index)

	var harbormaster_count: int = _harbormaster_holder.harbormaster_count if _harbormaster_holder else 0
	if player_harbor_count < min_harbormaster or player_harbor_count <= harbormaster_count:
		return

	var player: PlayerState = player_states[player_index]
	if player != _harbormaster_holder:
		var previous_holder := _harbormaster_holder
		_award_title(previous_holder, player, player_index)
		_harbormaster_holder = player
		GameSignals.emit_harbormaster_holder_changed(player_index)
		GameSignals.emit_title_holder_changed(TitleTypes.Type.HARBORMASTER, player.player, previous_holder.player if previous_holder else null)


func _award_title(old_holder: PlayerState, new_holder: PlayerState, new_holder_index: int) -> void:
	if old_holder != null:
		var previous_holder_index := player_states.find(old_holder)
		old_holder.score -= 2
		GameSignals.emit_score_changed(previous_holder_index, old_holder.score)
	new_holder.score += 2
	GameSignals.emit_score_changed(new_holder_index, new_holder.score)


#############################################
### ROBBER
#############################################
func _steal_resource(target_index: int) -> void:
	var target := player_states[target_index]
	var thief := player_states[turn_manager.current_player_index]
	var available_resources: Array[ResourceTypes.Type] = []

	for resource_type: ResourceTypes.Type in target.hand.resource_counts:
		for _i in target.hand.resource_count(resource_type):
			available_resources.append(resource_type)

	if available_resources.is_empty():
		return

	var stolen_resource: ResourceTypes.Type = ArrayUtils.get_random_item(available_resources)
	target.hand.remove_resource(stolen_resource)
	thief.hand.add_resource(stolen_resource)
	GameSignals.emit_resource_stolen(thief.player, target.player, stolen_resource)
	GameSignals.emit_hand_changed()


func _finish_robber_phase() -> void:
	turn_manager.advance_from_robber()


#############################################
### BANK TRADE
#############################################
func _execute_bank_trade(traded: Array[ResourceTypes.Type], received: Array[ResourceTypes.Type]) -> void:
	var player_state := player_states[turn_manager.current_player_index]
	for resource in traded:
		player_state.hand.remove_resource(resource)
	for resource in received:
		player_state.hand.add_resource(resource)
	GameSignals.emit_bank_trade_completed(player_state.player, traded, received)
	GameSignals.emit_hand_changed()


#############################################
### GAME OVER
#############################################
func _check_game_over(player_index: int, score: int) -> void:
	if score >= target_vp:
		_game_over(player_index)


func _game_over(_winner_index: int) -> void:
	var standings := player_states.duplicate()
	standings.sort_custom(func(a: PlayerState, b: PlayerState) -> bool: return a.score > b.score)
	pass # TODO: notify all clients via RPC with winner_index and standings


func _audit_scores() -> void:
	for i in player_states.size():
		var expected := _recalculate_score(i)
		var actual := player_states[i].score
		if expected != actual:
			push_warning("Score drift detected for %s: expected %d, got %d" % [player_states[i].player.player_name, expected, actual])
			player_states[i].score = expected


#############################################
### RESOURCE DISTRIBUTION
#############################################
func _distribute_resources(dice_total: int) -> void:
	if game_config.has_robber() and dice_total == 7:
		return
	if not board_state.has_number(dice_total):
		return

	var coords: Array[Vector2i] = board_state.get_coords_for_number(dice_total)
	var player_resources: Dictionary = {}

	for coord in coords:
		if game_config.has_robber() and coord == _robber_coord:
			continue

		var resource = TerrainTypes.to_resource(board_state.get_terrain(coord))
		if resource == null:
			continue

		for vertex_key: Vector2i in board_state.coord_to_vertex_keys.get(coord, []):
			var vertex_owner := board_state.get_vertex_owner(Vector2(vertex_key))
			if vertex_owner.is_empty():
				continue
			var amount: int = 2 if vertex_owner.piece_type == PieceTypes.Type.CITY else 1
			if not player_resources.has(vertex_owner.player_index):
				player_resources[vertex_owner.player_index] = PlayerResources.new()
			player_resources[vertex_owner.player_index].add(resource, amount)

	for player_index: int in player_resources:
		var ps := player_states[player_index]
		var resources: PlayerResources = player_resources[player_index]

		for resource in resources.counts:
			ps.hand.add_resource(resource, resources.get_count(resource))
			GameSignals.emit_resource_collected(ps.player, resource, resources.get_count(resource))

		GameSignals.emit_resources_distributed(ps.player, resources)

	GameSignals.emit_hand_changed()


func _collect_resources_at_vertex(player_index: int, world_pos: Vector2) -> void:
	var ps := player_states[player_index]
	var terrain_types := board_state.get_terrain_at_vertex(world_pos)
	var resources := PlayerResources.new()

	for terrain in terrain_types:
		var resource: ResourceTypes.Type = TerrainTypes.to_resource(terrain)
		if resource != ResourceTypes.Type.UNKNOWN:
			resources.add(resource)

	for resource in resources.counts:
		ps.hand.add_resource(resource, resources.get_count(resource))
		GameSignals.emit_resource_collected(ps.player, resource, resources.get_count(resource))

	if not resources.is_empty():
		GameSignals.emit_resources_distributed(ps.player, resources)

	GameSignals.emit_hand_changed()
