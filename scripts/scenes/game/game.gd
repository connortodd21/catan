class_name Game
extends Node2D

@export var terrain_database: TerrainDatabaseResource
@export var number_database: NumberDatabaseResource
@export var piece_database: PieceDatabaseResource
@export var action_database: ActionDatabaseResource
@export var decks: Array[CardDeck] = []

@export var number_scale: float = 1.0
@export var number_offset: Vector2 = Vector2.ZERO
@export var robber_offset: Vector2 = Vector2(-40, 0)

@export var game_config: GameConfig = null
@export var min_longest_road: int = 5
@export var min_largest_army: int = 3
@export var min_harbormaster: int = 3
@export var robber_discard_hand_threshold : int = 7

@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap
@onready var board_view: Node2D = $BoardView
@onready var hand_manager: HandManager = $UI/HandManager
@onready var player_hud: PlayerHUD = $UI/PlayerHUD
@onready var dice_roller: DiceRoller = $UI/DiceRoller
@onready var debug_label: Label = $UI/DebugLabel
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var action_manager: ActionManager = $ActionManager
@onready var card_manager: CardManager = $CardManager
@onready var action_panel: ActionPanel = $UI/ActionPanel

var tile_coords: Array[Vector2i] = []
var player_states: Array[PlayerState] = []
var local_player: PlayerState = null
var turn_manager: TurnManager
var board_state: BoardState
var board: SerializedBoard

var board_renderer: BoardRenderer

var _draw_piles: Dictionary = {}

var _longest_road_holder: PlayerState = null
var _largest_army_holder: PlayerState = null
var _harbormaster_holder: PlayerState = null
var _robber_coord: Vector2i = Vector2i(-999, -999)


func _ready() -> void:
	if game_config:
		board = game_config.board
		board_renderer = BoardRenderer.new(board_view, board_tile_map)
		render_board()
		
		board_state = BoardState.new()
		board_state.build(board, board_tile_map)
		
		if game_config.has_robber():
			place_robber_on_desert()
		
		_init_players()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if turn_manager.current_phase != GamePhase.Phase.PLAYING_CARD:
				action_manager.cancel()
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := board_view.get_local_mouse_position()
			match turn_manager.current_phase:
				GamePhase.Phase.ROBBER:
					_handle_robber_placement(mouse_pos)
				GamePhase.Phase.ACTION, GamePhase.Phase.PLAYING_CARD:
					action_manager.handle_board_click(mouse_pos)


func _init_players() -> void:
	for player in game_config.players:
		player_states.append(PlayerState.new(player))
		player_hud.init(player_states)
	
	local_player = player_states[0]
	hand_manager.set_hand(local_player.hand)

	local_player.hand.add_resource(ResourceTypes.Type.WOOD)
	local_player.hand.add_resource(ResourceTypes.Type.BRICK)
	local_player.hand.add_resource(ResourceTypes.Type.SHEEP)
	local_player.hand.add_resource(ResourceTypes.Type.SHEEP)
	local_player.hand.add_resource(ResourceTypes.Type.WHEAT)
	local_player.hand.add_resource(ResourceTypes.Type.WHEAT)
	local_player.hand.add_resource(ResourceTypes.Type.ROCK)

	_load_dev_decks()

	turn_manager = TurnManager.new()

	for action in action_database.actions:
		action_manager.register_action(action)
	_register_action_validators()
	action_panel.init(action_manager)
	action_panel.build_buttons()

	card_manager.action_manager = action_manager
	card_manager.turn_manager = turn_manager

	_register_card_handlers()

	_register_signals()

	turn_manager.start_game(player_states.size())
	


#############################################
### DEV DECK
#############################################
func _load_dev_decks() -> void:
	for deck: CardDeck in decks:
		var pile: Array[CardDefinition] = deck.deck.duplicate()
		pile.shuffle()
		_draw_piles[deck.deck_type] = pile


func _draw_dev_card(deck_type: Deck.Type) -> void:
	var pile: Array[CardDefinition] = _draw_piles.get(deck_type, [])
	if pile.is_empty():
		return
	var card: CardDefinition = pile.pop_back()
	while card.card_type != CardTypes.Type.ROAD_BUILDING:
		card = pile.pop_back()
	player_states[turn_manager.current_player_index].hand.add_card(card)


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
	for coord in coords:
		var resource = TerrainTypes.to_resource(board_state.get_terrain(coord))
		if resource == null:
			continue
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		for snap in snap_points:
			var vertex_owner := board_state.get_vertex_owner(hex_center + snap)
			if vertex_owner.is_empty():
				continue
			var resource_amount : int = 2 if vertex_owner.piece_type == PieceTypes.Type.CITY else 1
			player_states[vertex_owner.player_index].hand.add_resource(resource, resource_amount)
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
	add_border(coord_to_tile)


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

	var stealable_players: Array[int] = board_state.get_stealable_players(coord, turn_manager.current_player_index, board_tile_map)
	if not stealable_players.is_empty():
		var target_index: int = stealable_players[randi() % stealable_players.size()]
		# TODO: let player choose target when multiple opponents are present
		_steal_resource(target_index)

	turn_manager.advance_from_robber()


func _steal_resource(_target_index: int) -> void:
	pass # TODO: implement steal logic


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
	pass # TODO: choose 2 resources


func _on_play_monopoly() -> void:
	pass # TODO: choose resource type, take all from opponents


#############################################
### ACTION VALIDATORS
#############################################
func _register_action_validators() -> void:
	action_manager.register_validator(ActionTypes.Type.BUILD_SETTLEMENT, _can_perform_settlement)
	action_manager.register_validator(ActionTypes.Type.BUILD_ROAD, _can_perform_road)
	action_manager.register_validator(ActionTypes.Type.BUILD_CITY, _can_perform_city)
	action_manager.register_validator(ActionTypes.Type.BUY_DEV_CARD, _can_perform_buy_dev_card)
	action_manager.register_validator(ActionTypes.Type.TRADE, _can_perform_trade)


func _can_perform_settlement() -> bool:
	return board_state.has_valid_settlement_placement(turn_manager.current_player_index)


func _can_perform_road() -> bool:
	return board_state.has_valid_road_placement(turn_manager.current_player_index)


func _can_perform_city() -> bool:
	return board_state.has_valid_city_placement(turn_manager.current_player_index)


func _can_perform_buy_dev_card() -> bool:
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
		if action == ActionTypes.Type.BUY_DEV_CARD:
			_draw_dev_card(Deck.Type.STANDARD)
		return

	var piece_type: PieceTypes.Type = _action_to_piece.get(action, PieceTypes.Type.UNKNOWN)
	if piece_type == PieceTypes.Type.UNKNOWN:
		return

	var snap := _snap_to_nearest(action_position, definition.placement)
	if snap.is_empty():
		return

	if not _can_place(action, snap.pos):
		return

	_place_piece_at(piece_type, snap)
	if turn_manager.current_phase != GamePhase.Phase.PLAYING_CARD:
		_deduct_cost(definition)
	_update_score(action, turn_manager.current_player_index)
	_check_titles(action, turn_manager.current_player_index)


func _can_place(action: ActionTypes.Type, snapped_pos: Vector2) -> bool:
	var player_index := turn_manager.current_player_index
	match action:
		ActionTypes.Type.BUILD_SETTLEMENT:
			return board_state.can_place_settlement(snapped_pos, player_index)
		ActionTypes.Type.BUILD_ROAD:
			return board_state.can_place_road(snapped_pos, player_index)
		ActionTypes.Type.BUILD_CITY:
			return board_state.can_place_city(snapped_pos, player_index)
	return true


func _update_score(action: ActionTypes.Type, player_index: int) -> void:
	var victory_points_delta : int = GameUtils.action_to_victory_points(action)
	player_states[player_index].score += victory_points_delta
	GameSignals.emit_score_changed(player_index, player_states[player_index].score)


#############################################
### TITLE CHECKS
#############################################
func _check_titles(action: ActionTypes.Type, player_index: int) -> void:
	match action:
		ActionTypes.Type.BUILD_ROAD:
			_check_longest_road(player_index)


func _check_longest_road(player_index: int) -> void:
	var player_longest_road : int = board_state.calculate_longest_road(player_index)
	player_states[player_index].longest_road_length = player_longest_road
	GameSignals.emit_player_stats_changed(player_index)
	
	var longest_road : int = _longest_road_holder.longest_road_length if _longest_road_holder else 0
	if player_longest_road < min_longest_road or player_longest_road <= longest_road:
		return
	
	var player : PlayerState = player_states[player_index]
	if player != _longest_road_holder:
		_award_title(_longest_road_holder, player, player_index)
		_longest_road_holder = player
		GameSignals.emit_longest_road_holder_changed(player_index)


func _check_largest_army(player_index: int) -> void:
	var player_army_size : int = player_states[player_index].army_size
	GameSignals.emit_player_stats_changed(player_index)

	var largest_army : int = _largest_army_holder.army_size if _largest_army_holder else 0
	if player_army_size < min_largest_army or player_army_size <= largest_army:
		return

	var player : PlayerState = player_states[player_index]
	if player != _largest_army_holder:
		_award_title(_largest_army_holder, player, player_index)
		_largest_army_holder = player
		GameSignals.emit_largest_army_holder_changed(player_index)


func _check_harbormaster(player_index: int) -> void:
	var player_harbor_count : int = board_state.calculate_harbormaster_count(player_index)
	player_states[player_index].harbormaster_count = player_harbor_count
	GameSignals.emit_player_stats_changed(player_index)

	var harbormaster_count : int = _harbormaster_holder.harbormaster_count if _harbormaster_holder else 0
	if player_harbor_count < min_harbormaster or player_harbor_count <= harbormaster_count:
		return

	var player : PlayerState = player_states[player_index]
	if player != _harbormaster_holder:
		_award_title(_harbormaster_holder, player, player_index)
		_harbormaster_holder = player
		GameSignals.emit_harbormaster_holder_changed(player_index)


func _award_title(old_holder: PlayerState, new_holder: PlayerState, new_index: int) -> void:
	if old_holder != null:
		var old_index := player_states.find(old_holder)
		old_holder.score -= 2
		GameSignals.emit_score_changed(old_index, old_holder.score)
	new_holder.score += 2
	GameSignals.emit_score_changed(new_index, new_holder.score)


func _deduct_cost(definition: ActionDefinition) -> void:
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
### SIGNALS
#############################################
func _register_signals() -> void:
	GameSignals.player_changed.connect(_on_player_changed)
	GameSignals.phase_changed.connect(_on_phase_changed)
	GameSignals.dice_rolled.connect(_on_dice_rolled)
	GameSignals.action_button_pressed.connect(_on_action_button_pressed)
	GameSignals.action_executed.connect(_on_action_executed)
	GameSignals.hand_changed.connect(_on_hand_changed)
	GameSignals.card_clicked.connect(_on_card_clicked)
	end_turn_button.pressed.connect(turn_manager.end_turn)


func _on_card_clicked(card: CardDefinition) -> void:
	card_manager.play_card(card, player_states[turn_manager.current_player_index])


func _on_player_changed(index: int) -> void:
	local_player = player_states[index]
	hand_manager.set_hand(local_player.hand)
	player_hud.set_active_player(index)
	action_panel.refresh(local_player.hand)
	_update_debug_label()


func _on_phase_changed(phase: GamePhase.Phase) -> void:
	dice_roller.set_roll_enabled(phase == GamePhase.Phase.ROLL)
	end_turn_button.disabled = (phase != GamePhase.Phase.ACTION)
	action_panel.refresh(local_player.hand)
	_update_debug_label()


func _update_debug_label() -> void:
	debug_label.text = "Player: %s | Phase: %s" % [local_player.get_name(), turn_manager.phase_name()]


func _on_action_button_pressed(action_type: ActionTypes.Type) -> void:
	action_manager.select_action(action_type, local_player.hand)


func _on_hand_changed() -> void:
	action_panel.refresh(local_player.hand)


func _on_dice_rolled(_d1: DiceFaces.Type, _d2: DiceFaces.Type, dice_total: int) -> void:
	turn_manager.advance_from_roll()
	if game_config.has_robber() and dice_total == 7:
		# TODO: handle discard for players over robber_discard_hand_threshold
		turn_manager.enter_robber_phase()
		return
	_distribute_resources(dice_total)
