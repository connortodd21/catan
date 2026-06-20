class_name Game
extends Node2D

const NEWLY_BOUGHT_CARD_META = "newly_bought"


#############################################
### EXPORTS
#############################################

# Resources
@export var action_database: ActionDatabaseResource
@export var decks: Array[CardDeck] = []
@export var piece_database: PieceDatabaseResource
@export var port_deck: PortDeck
@export var number_database: NumberDatabaseResource
@export var terrain_database: TerrainDatabaseResource

# Scenes
@export var port_scene: PackedScene

# Game config
@export var game_config: GameConfig = null
@export var min_harbormaster: int = 3
@export var min_longest_road: int = 5
@export var min_largest_army: int = 3
@export var robber_discard_hand_threshold : int = 7

# UI
@export var number_scale: float = 1.0
@export var number_offset: Vector2 = Vector2.ZERO
@export var robber_offset: Vector2 = Vector2(-40, 0)


#############################################
### Nodes
#############################################

@onready var activity_log_popup: ActivityLogPopup = $UI/ActivityLogPopup
@onready var activity_log_button: TextureButton = $UI/MenuHbox/ActivityLogButton
@onready var action_panel: ActionPanel = $UI/GameMenu/ActionPanel
@onready var bank_trade_button: Button = $UI/GameMenu/TradePanel/BankTradeButton
@onready var bank_trade_popup: BankTradePopup = $UI/BankTradePopup
@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap
@onready var board_view: Node2D = $BoardView
@onready var dice_roller: DiceRoller = $UI/GameMenu/DiceRoller
@onready var debug_label: Label = $UI/DebugLabel
@onready var discard_popup: DiscardPopup = $UI/DiscardPopup
@onready var end_turn_button: Button = $UI/GameMenu/EndTurnButton
@onready var game_over_popup: GameOverPopup = $UI/GameOverPopup
@onready var hand_manager: HandManager = $UI/HandManager
@onready var player_hud: PlayerHUD = $UI/PlayerHUD
@onready var player_trade_button: Button = $UI/GameMenu/TradePanel/PlayerTradeButton
@onready var selection_popup: SelectionPopup = $UI/SelectionPopup
@onready var settings_button: TextureButton = $UI/MenuHbox/SettingsButton
@onready var settings_popup: SettingsPopup = $UI/SettingsPopup
@onready var stats_button: TextureButton = $UI/MenuHbox/StatsButton
@onready var stats_popup: StatsPopup = $UI/StatsPopup
@onready var trade_panel: VBoxContainer = $UI/GameMenu/TradePanel


#############################################
### Globals
#############################################

# Managers/Singletons
var action_manager: ActionManager
var activity_log: ActivityLog = ActivityLog.new()
var board: SerializedBoard
var board_renderer: BoardRenderer
var board_state: BoardState
var card_manager: CardManager
var game_stats: GameStats = GameStats.new()
var local_player: PlayerState = null
var popup_manager: PopupManager
var setup_manager: SetupManager
var turn_manager: TurnManager

# Game states
var _draw_piles: Dictionary = {}
var _harbormaster_holder: PlayerState = null
var _largest_army_holder: PlayerState = null
var _longest_road_holder: PlayerState = null
var player_states: Array[PlayerState] = []
var _robber_coord: Vector2i = Vector2i(-999, -999)
var target_vp: int = 10
var tile_coords: Array[Vector2i] = []


#############################################
### Game loop and setup
#############################################
func _ready() -> void:
	if game_config:
		target_vp = game_config.victory_points
		board = game_config.board
		board_renderer = BoardRenderer.new(board_view, board_tile_map)
		render_board()
		
		board_state = BoardState.new()
		board_state.build(board, board_tile_map)
		
		if game_config.has_robber():
			place_robber_on_desert()
		
		_init_players()
		start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := board_view.get_local_mouse_position()
			match turn_manager.current_phase:
				GamePhase.Phase.ROBBER:
					_handle_robber_placement(mouse_pos)
				GamePhase.Phase.ACTION, GamePhase.Phase.PLAYING_CARD, GamePhase.Phase.SETUP:
					action_manager.handle_board_click(mouse_pos)


func _init_players() -> void:
	for player in game_config.players:
		player_states.append(PlayerState.new(player))
	player_hud.init(player_states)
	game_stats.player_game_stats.register_players(game_config.players)
	
	player_hud.set_harbormaster_enabled(game_config.has_harbormaster())
	local_player = player_states[0]
	hand_manager.set_hand(local_player.hand)

	_load_dev_decks()

	turn_manager = TurnManager.new()

	action_manager = ActionManager.new()
	action_manager.init()

	for action in action_database.actions:
		action_manager.register_action(action)
	_register_action_validators()
	action_panel.init(action_manager)
	action_panel.build_buttons()

	card_manager = CardManager.new()
	card_manager.init(action_manager, turn_manager)

	setup_manager = SetupManager.new()
	setup_manager.init(action_manager, turn_manager, board_state)

	popup_manager = PopupManager.new()
	popup_manager.init(selection_popup, hand_manager.get_sorted_resource_definitions())

	_register_card_handlers()

	_register_signals()


func start_game() -> void:
	setup_manager.begin(player_states.size())
	


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
	if not pile.is_empty():
		var card: CardDefinition = pile.pop_back().duplicate()
		card.set_meta(NEWLY_BOUGHT_CARD_META, true)
		var player_state := player_states[turn_manager.current_player_index]
		player_state.hand.add_card(card)
		GameSignals.emit_development_card_bought(player_state.player)


func _clear_newly_bought_cards(player_index: int) -> void:
	for card in player_states[player_index].hand.get_cards():
		card.set_meta(NEWLY_BOUGHT_CARD_META, false)


#############################################
### GAME LOGIC
#############################################
func _distribute_resources(dice_total: int) -> void:
	if game_config.has_robber() and dice_total == 7:
		return
	if not board_state.has_number(dice_total):
		return
	var snap_points := PlacementType.get_snap_points(PlacementType.Type.HEX_VERTEX)
	var coords : Array[Vector2i] = board_state.get_coords_for_number(dice_total)
	var player_resources_to_distribute: Dictionary = {}
	# Accumulate resources per player across all tiles and vertices
	for coord in coords:
		if game_config.has_robber() and coord == _robber_coord:
			continue
		var resource = TerrainTypes.to_resource(board_state.get_terrain(coord))
		if resource == null:
			continue
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		for snap in snap_points:
			var vertex_owner := board_state.get_vertex_owner(hex_center + snap)
			if vertex_owner.is_empty():
				continue
			var resource_amount : int = 2 if vertex_owner.piece_type == PieceTypes.Type.CITY else 1
			if not player_resources_to_distribute.has(vertex_owner.player_index):
				player_resources_to_distribute[vertex_owner.player_index] = PlayerResources.new()
			player_resources_to_distribute[vertex_owner.player_index].add(resource, resource_amount)
	# Hand out accumulated resources and emit signals once per player
	for player_index: int in player_resources_to_distribute:
		var ps := player_states[player_index]
		var resources: PlayerResources = player_resources_to_distribute[player_index]
		for resource in resources.counts:
			ps.hand.add_resource(resource, resources.get_count(resource))
			GameSignals.emit_resource_collected(ps.player, resource, resources.get_count(resource))
		GameSignals.emit_resources_distributed(ps.player, resources)
	GameSignals.emit_hand_changed()


func _collect_resources_at_vertex(player_index: int, world_pos: Vector2) -> void:
	var ps := player_states[player_index]
	var terrain_types := board_state.get_terrain_at_vertex(world_pos)
	# Accumulate resources from all adjacent terrain types
	var resources := PlayerResources.new()
	for terrain in terrain_types:
		var resource: ResourceTypes.Type = TerrainTypes.to_resource(terrain)
		if resource != ResourceTypes.Type.UNKNOWN:
			resources.add(resource)
	# Add to hand and emit signals once per player
	for resource in resources.counts:
		ps.hand.add_resource(resource, resources.get_count(resource))
		GameSignals.emit_resource_collected(ps.player, resource, resources.get_count(resource))
	if not resources.is_empty():
		GameSignals.emit_resources_distributed(ps.player, resources)
	GameSignals.emit_hand_changed()


func _on_score_changed(player_index: int, score: int) -> void:
	if score >= target_vp:
		_game_over(player_index)


func _game_over(winner_index: int) -> void:
	var standings := player_states.duplicate()
	standings.sort_custom(func(a, b): return a.score > b.score)
	game_over_popup.init(player_states[winner_index], standings, _on_game_over_exit)


func _on_game_over_exit() -> void:
	GlobalSignals.go_back_to_menu()


func _on_discard_confirmed(resources_after_discard: Array[ResourceTypes.Type]) -> void:
	var new_counts: Dictionary = {}
	for resource in resources_after_discard:
		new_counts[resource] = new_counts.get(resource, 0) + 1
	local_player.hand.resource_counts = new_counts
	GameSignals.emit_hand_add_remove()
	GameSignals.emit_hand_changed()


#############################################
### BOARD RENDERING
#############################################
func render_board() -> void:
	var coord_to_tile: Dictionary = {}
	for tile: TileEntry in board.tiles:
		var coord := Vector2i(tile.x, tile.y)
		board_tile_map.set_cell(
			HexUtils.axial_to_offset(coord),
			terrain_database.get_source_id(tile.type),
			terrain_database.get_atlas_coords(tile.type)
		)
		coord_to_tile[coord] = true
		tile_coords.append(coord)
	render_numbers()
	render_ports()
	add_border(coord_to_tile)


func render_ports() -> void:
	for port_entry: PortEntry in board.ports:
		var port_def := port_deck.get_def(port_entry.type)
		if port_def == null:
			continue
		var water_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(Vector2i(port_entry.x, port_entry.y)))
		var edge_mid := HexUtils.EDGE_MIDPOINTS[(port_entry.direction + 1) % 6]
		var port_node: Node2D = port_scene.instantiate()
		port_node.scale = Vector2.ONE * 0.5
		port_node.position = water_center + edge_mid
		board_view.add_child(port_node)
		var edge_rotation := rad_to_deg(edge_mid.angle()) - 90.0
		port_node.setup(port_def.trade_rate, port_def.texture, edge_rotation)


func render_numbers() -> void:
	for entry: NumberEntry in board.numbers:
		if entry.value.is_empty():
			continue
		var number := entry.value[0]
		if not number in number_database.get_keys():
			continue
		var offset := HexUtils.axial_to_offset(Vector2i(entry.x, entry.y))
		var sprite := Sprite2D.new()
		sprite.texture = number_database.get_texture(number)
		sprite.scale = Vector2(number_scale, number_scale)
		sprite.position = board_tile_map.map_to_local(offset) + number_offset
		sprite.z_index = 1
		board_view.add_child(sprite)


#############################################
### ROBBER
#############################################
func place_robber_on_desert() -> void:
	for tile: TileEntry in board.tiles:
		if tile.type == TerrainTypes.Type.DESERT:
			var coord := Vector2i(tile.x, tile.y)
			var world_pos: Vector2 = board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
			_robber_coord = coord
			board_renderer.place_robber(piece_database.get_texture(PieceTypes.Type.ROBBER), world_pos, robber_offset)
			return


func _handle_robber_placement(mouse_pos: Vector2) -> void:
	var coord: Vector2i = board_renderer.get_nearest_hex_coord(mouse_pos, tile_coords)
	if coord == _robber_coord:
		return
	_robber_coord = coord
	var world_pos: Vector2 = board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
	board_renderer.move_robber_to(world_pos, robber_offset)

	var stealable_players: Array[int] = board_state.get_players_on_hex_vertex(coord, turn_manager.current_player_index)
	stealable_players.assign(stealable_players.filter(func(i: int) -> bool: return player_states[i].hand.total_resource_count() > 0))
	if not stealable_players.is_empty():
		hand_manager.disable_hover()
		popup_manager.show_player_select(stealable_players, player_states, _on_robber_target_selected)
	else:
		_finish_robber_phase()


func _finish_robber_phase() -> void:
	turn_manager.advance_from_robber()


func _on_robber_target_selected(target_index: int) -> void:
	_steal_resource(target_index)
	_finish_robber_phase()


func _steal_resource(target_index: int) -> void:
	var target := player_states[target_index]
	var thief := player_states[turn_manager.current_player_index]
	var available_resources : Array[ResourceTypes.Type] = []
	for resource_type: ResourceTypes.Type in target.hand.resource_counts:
		for _i in target.hand.resource_count(resource_type):
			available_resources.append(resource_type)
	if not available_resources.is_empty():
		var stolen_resource : ResourceTypes.Type = ArrayUtils.get_random_item(available_resources)
		target.hand.remove_resource(stolen_resource)
		thief.hand.add_resource(stolen_resource)
		GameSignals.emit_resource_stolen(thief.player, target.player, stolen_resource)
		GameSignals.emit_hand_changed()


#############################################
### CARD HANDLERS
#############################################
func _register_card_handlers() -> void:
	card_manager.register_handler(CardTypes.Type.VICTORY_POINT, _on_play_victory_point)
	card_manager.register_handler(CardTypes.Type.KNIGHT, _on_play_knight)
	card_manager.register_handler(CardTypes.Type.ROAD_BUILDING, _on_play_road_building)
	card_manager.register_handler(CardTypes.Type.YEAR_OF_PLENTY, _on_play_year_of_plenty)
	card_manager.register_handler(CardTypes.Type.MONOPOLY, _on_play_monopoly)


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
	hand_manager.disable_hover()
	popup_manager.show_resource_select(_on_year_of_plenty_resource_selected, 2)


func _on_year_of_plenty_resource_selected(resource: ResourceTypes.Type) -> void:
	player_states[turn_manager.current_player_index].hand.add_resource(resource)
	GameSignals.emit_hand_changed()


func _on_play_monopoly() -> void:
	hand_manager.disable_hover()
	popup_manager.show_resource_select(_on_monopoly_resource_selected)


func _on_monopoly_resource_selected(resource: ResourceTypes.Type) -> void:
	var player_index := turn_manager.current_player_index
	for i in player_states.size():
		if i != player_index:
			var count := player_states[i].hand.resource_count(resource)
			if count > 0:
				player_states[i].hand.remove_resource(resource, count)
				player_states[player_index].hand.add_resource(resource, count)
	GameSignals.emit_hand_changed()


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
### ACTION EXECUTION
#############################################
static var _action_to_piece: Dictionary = {
	ActionTypes.Type.BUILD_ROAD: PieceTypes.Type.ROAD,
	ActionTypes.Type.BUILD_SETTLEMENT: PieceTypes.Type.SETTLEMENT,
	ActionTypes.Type.BUILD_CITY: PieceTypes.Type.CITY,
}


func _on_action_executed(action: ActionTypes.Type, action_position: Vector2) -> void:
	var definition := action_manager.get_action(action)
	if definition == null:
		return

	if definition.placement == PlacementType.Type.NONE:
		_deduct_cost(definition)
		if action == ActionTypes.Type.BUY_DEVELOPMENT_CARD:
			_draw_development_card(Deck.Type.STANDARD)
		return

	var piece_type: PieceTypes.Type = _action_to_piece.get(action, PieceTypes.Type.UNKNOWN)
	if piece_type == PieceTypes.Type.UNKNOWN:
		return

	var snap := _snap_to_nearest(action_position, definition.placement)
	if snap.is_empty():
		return

	if not _can_place(action, snap.pos):
		return

	action_manager.clear_active_action()
	_place_piece_at(piece_type, snap)
	if action == ActionTypes.Type.BUILD_SETTLEMENT and turn_manager.current_phase == GamePhase.Phase.SETUP:
		setup_manager.record_last_settlement(snap.pos)
	var current_player := turn_manager.current_player_index
	GameSignals.emit_piece_placed(player_states[current_player].player, piece_type, snap.pos)
	_deduct_cost(definition)
	_update_score(action, current_player)
	_check_titles(action, current_player)


func _can_place(action: ActionTypes.Type, snapped_pos: Vector2) -> bool:
	var player_index := turn_manager.current_player_index
	match action:
		ActionTypes.Type.BUILD_SETTLEMENT:
			var require_road := turn_manager.current_phase != GamePhase.Phase.SETUP
			return board_state.can_place_settlement(snapped_pos, player_index, require_road)
		ActionTypes.Type.BUILD_ROAD:
			if turn_manager.current_phase == GamePhase.Phase.SETUP:
				return setup_manager.is_setup_road_valid(snapped_pos)
			return board_state.can_place_road(snapped_pos, player_index)
		ActionTypes.Type.BUILD_CITY:
			return board_state.can_place_city(snapped_pos, player_index)
	return true


func _update_score(action: ActionTypes.Type, player_index: int) -> void:
	var victory_points_delta : int = GameUtils.action_to_victory_points(action)
	player_states[player_index].score += victory_points_delta
	GameSignals.emit_score_changed(player_index, player_states[player_index].score)


func _recalculate_score(player_index: int) -> int:
	var player_state := player_states[player_index]
	var total_score := 0
	# Calculate placed piece score
	for entry in board_state.vertex_ownership.values():
		if entry.player_index != player_index:
			continue
		match entry.piece_type:
			PieceTypes.Type.SETTLEMENT: total_score += 1
			PieceTypes.Type.CITY: total_score += 2
	# Calculate title scores
	if _longest_road_holder == player_state: total_score += 2
	if _largest_army_holder == player_state: total_score += 2
	if _harbormaster_holder == player_state: total_score += 2
	# Calculate VP card score
	total_score += player_state.vp_cards_played
	return total_score


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


func _check_longest_road(player_index: int) -> void:
	var player_longest_road := board_state.calculate_longest_road(player_index)
	player_states[player_index].longest_road_length = player_longest_road
	GameSignals.emit_player_stats_changed(player_index)
	var current_best := _longest_road_holder.longest_road_length if _longest_road_holder else 0
	if player_longest_road < min_longest_road or player_longest_road <= current_best:
		return
	var previous_holder_index := player_states.find(_longest_road_holder) if _longest_road_holder else -1
	_update_longest_road_holder(previous_holder_index, player_index)


func _check_largest_army(player_index: int) -> void:
	var player_army_size : int = player_states[player_index].army_size
	GameSignals.emit_player_stats_changed(player_index)

	var largest_army : int = _largest_army_holder.army_size if _largest_army_holder else 0
	if player_army_size < min_largest_army or player_army_size <= largest_army:
		return

	var player : PlayerState = player_states[player_index]
	if player != _largest_army_holder:
		var previous_holder := _largest_army_holder
		_award_title(previous_holder, player, player_index)
		_largest_army_holder = player
		GameSignals.emit_largest_army_holder_changed(player_index)
		GameSignals.emit_title_holder_changed(TitleTypes.Type.LARGEST_ARMY, player.player, previous_holder.player if previous_holder else null)


func _check_harbormaster(player_index: int) -> void:
	if not game_config.has_harbormaster():
		return
	var player_harbor_count : int = board_state.calculate_harbormaster_count(player_index)
	player_states[player_index].harbormaster_count = player_harbor_count
	GameSignals.emit_player_stats_changed(player_index)

	var harbormaster_count : int = _harbormaster_holder.harbormaster_count if _harbormaster_holder else 0
	if player_harbor_count < min_harbormaster or player_harbor_count <= harbormaster_count:
		return

	var player : PlayerState = player_states[player_index]
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


func _deduct_cost(definition: ActionDefinition) -> void:
	if CostUtils.is_free(definition.id, turn_manager.current_phase):
		return
	for resource_type: ResourceTypes.Type in definition.base_cost:
		for i in definition.base_cost[resource_type]:
			local_player.hand.remove_resource(resource_type)
	GameSignals.emit_hand_changed()


#############################################
### PIECE PLACEMENT
#############################################
func _snap_to_nearest(mouse_pos: Vector2, placement: PlacementType.Type) -> Dictionary:
	var snap_points := PlacementType.get_snap_points(placement)
	var rotations := PlacementType.get_rotations(placement)
	var nearest_pos := Vector2.ZERO
	var nearest_dist := INF
	var nearest_rotation := 0.0

	for coord: Vector2i in tile_coords:
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		for i in snap_points.size():
			var pos := hex_center + snap_points[i]
			var dist := mouse_pos.distance_to(pos)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_pos = pos
				nearest_rotation = rotations[i] if not rotations.is_empty() else 0.0

	if nearest_dist > 40.0:
		return {}
	return { "pos": nearest_pos, "rotation": nearest_rotation }


func _place_piece_at(piece: PieceTypes.Type, snap: Dictionary) -> void:
	board_state.record_placement(piece, snap.pos, turn_manager.current_player_index)
	if piece == PieceTypes.Type.CITY:
		board_renderer.remove_piece_at(snap.pos)
	board_renderer.place_piece(piece_database.get_texture(piece), snap.pos, local_player.get_color(), snap.rotation)


func add_border(coord_to_tile: Dictionary) -> void:
	var water_source := terrain_database.get_source_id(TerrainTypes.Type.DESERT)
	var water_atlas := terrain_database.get_atlas_coords(TerrainTypes.Type.DESERT)
	var border: Dictionary = {}
	for axial: Vector2i in coord_to_tile:
		for dir: Vector2i in HexUtils.HEX_DIRECTIONS:
			var neighbor := axial + dir
			if not coord_to_tile.has(neighbor) and not border.has(neighbor):
				border[neighbor] = true
	for axial: Vector2i in border:
		board_tile_map.set_cell(HexUtils.axial_to_offset(axial), water_source, water_atlas)


#############################################
### HUD RENDERING
#############################################
func _refresh_hud() -> void:
	var phase := turn_manager.current_phase
	dice_roller.set_roll_enabled(phase == GamePhase.Phase.ROLL)
	end_turn_button.disabled = (phase != GamePhase.Phase.ACTION)
	action_panel.visible = (phase != GamePhase.Phase.SETUP)
	trade_panel.visible = (phase != GamePhase.Phase.SETUP)
	bank_trade_button.disabled = (phase != GamePhase.Phase.ACTION)
	player_trade_button.disabled = (phase != GamePhase.Phase.ACTION)
	action_panel.refresh(local_player.hand)
	_update_debug_label()


#############################################
### SIGNALS
#############################################
func _register_signals() -> void:
	GameSignals.player_changed.connect(_on_player_changed)
	GameSignals.phase_changed.connect(_on_phase_changed)
	GameSignals.score_changed.connect(_on_score_changed)
	GameSignals.dice_rolled.connect(_on_dice_rolled)
	GameSignals.action_button_pressed.connect(_on_action_button_pressed)
	GameSignals.action_executed.connect(_on_action_executed)
	GameSignals.hand_changed.connect(_on_hand_changed)
	GameSignals.card_clicked.connect(_on_card_clicked)
	GameSignals.setup_phase_ended_for_player.connect(_on_setup_phase_ended_for_player)
	end_turn_button.pressed.connect(turn_manager.end_turn)


func _on_activity_log_button_pressed() -> void:
	var anchor := Vector2(activity_log_button.global_position.x, activity_log_button.global_position.y + activity_log_button.size.y)
	activity_log_popup.show_log(activity_log, anchor)


func _on_stats_button_pressed() -> void:
	stats_popup.show_stats(game_stats)


func _on_settings_button_pressed() -> void:
	settings_popup.popup_centered()


func _on_setup_phase_ended_for_player(player_index: int, settlement_pos: Vector2) -> void:
	_collect_resources_at_vertex(player_index, settlement_pos)


func _on_card_clicked(card: CardDefinition) -> void:
	if card.get_meta(NEWLY_BOUGHT_CARD_META, false):
		return
	card_manager.play_card(card, player_states[turn_manager.current_player_index])


func _on_player_changed(index: int) -> void:
	_clear_newly_bought_cards(index)
	_audit_scores()
	local_player = player_states[index]
	hand_manager.set_hand(local_player.hand)
	player_hud.set_active_player(index)
	action_panel.refresh(local_player.hand)
	_update_debug_label()


func _audit_scores() -> void:
	for i in player_states.size():
		var expected := _recalculate_score(i)
		var actual := player_states[i].score
		if expected != actual:
			push_warning("Score drift detected for %s: expected %d, got %d" % [player_states[i].player.player_name, expected, actual])
			player_states[i].score = expected


func _on_phase_changed(_phase: GamePhase.Phase) -> void:
	_refresh_hud()


func _update_debug_label() -> void:
	debug_label.text = "Player: %s | Phase: %s" % [local_player.get_name(), turn_manager.phase_name()]


func _on_action_button_pressed(action_type: ActionTypes.Type) -> void:
	action_manager.select_action(action_type, local_player.hand)


func _on_hand_changed() -> void:
	action_panel.refresh(local_player.hand)


func _on_dice_rolled(_d1: DiceFaces.Type, _d2: DiceFaces.Type, dice_total: int) -> void:
	GameSignals.emit_player_rolled(local_player.player, dice_total)
	turn_manager.advance_from_roll()
	if game_config.has_robber() and dice_total == 7:
		var hand_size := local_player.hand.total_resource_count()
		if hand_size > robber_discard_hand_threshold:
			hand_manager.disable_hover()
			discard_popup.init(local_player.hand, hand_manager.get_sorted_resource_definitions(), floor(hand_size / 2.0), _on_discard_confirmed)
		turn_manager.enter_robber_phase()
		return
	_distribute_resources(dice_total)


func _on_bank_trade_button_pressed() -> void:
	hand_manager.disable_hover()
	var trade_rates := board_state.get_bank_trade_rates_for_player(turn_manager.current_player_index)
	bank_trade_popup.init(local_player.hand, hand_manager.get_sorted_resource_definitions(), trade_rates, _on_bank_trade_confirmed)


func _on_popup_closed() -> void:
	hand_manager.enable_hover()


func _on_bank_trade_confirmed(traded: Array[ResourceTypes.Type], received: Array[ResourceTypes.Type]) -> void:
	for resource in traded:
		local_player.hand.remove_resource(resource)
	for resource in received:
		local_player.hand.add_resource(resource)
	GameSignals.emit_bank_trade_completed(local_player.player, traded, received)
	GameSignals.emit_hand_changed()


func _on_player_trade_button_pressed() -> void:
	pass
