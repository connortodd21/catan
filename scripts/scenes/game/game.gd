class_name Game
extends Node2D

@export var terrain_database: TerrainDatabaseResource
@export var number_database: NumberDatabaseResource
@export var piece_database: PieceDatabaseResource
@export var action_database: ActionDatabaseResource
@export var number_scale: float = 1.0
@export var number_offset: Vector2 = Vector2.ZERO
@export var robber_offset: Vector2 = Vector2(-40, 0)
@export var game_config: GameConfig = null

@onready var board_tile_map: TileMapLayer = $BoardView/BoardTileMap
@onready var board_view: Node2D = $BoardView
@onready var hand_manager: HandManager = $UI/HandManager
@onready var player_hud: PlayerHUD = $UI/PlayerHUD
@onready var dice_roller: DiceRoller = $UI/DiceRoller
@onready var debug_label: Label = $UI/DebugLabel
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var action_manager: ActionManager = $ActionManager
@onready var action_panel: ActionPanel = $UI/ActionPanel

var tile_coords: Array[Vector2i] = []
var player_states: Array[PlayerState] = []
var local_player: PlayerState = null
var turn_manager: TurnManager
var board_state: BoardState
var board: SerializedBoard


func _ready() -> void:
	if game_config:
		board = game_config.board
		board_state = BoardState.new()
		render_board()
		board_state.build(board, board_tile_map)
		if not HouseRules.RULE_NAMES.NO_ROBBER in game_config.house_rules:
			place_robber_on_desert()
		_init_players()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			action_manager.cancel()
		if event.button_index == MOUSE_BUTTON_LEFT:
			action_manager.on_board_click(board_view.get_local_mouse_position())


func _init_players() -> void:
	for player in game_config.players:
		player_states.append(PlayerState.new(player))
	local_player = player_states[0]
	hand_manager.set_hand(local_player.hand)
	player_hud.init(player_states)

	for type in [ResourceTypes.Type.WOOD, ResourceTypes.Type.BRICK, ResourceTypes.Type.SHEEP, ResourceTypes.Type.WHEAT, ResourceTypes.Type.ROCK]:
		local_player.hand.add_resource(type)
		local_player.hand.add_resource(type)
		local_player.hand.add_resource(type)

	turn_manager = TurnManager.new()
	GameSignals.player_changed.connect(_on_player_changed)
	GameSignals.phase_changed.connect(_on_phase_changed)
	GameSignals.dice_rolled.connect(_on_dice_rolled)
	GameSignals.action_button_pressed.connect(_on_action_button_pressed)
	GameSignals.action_executed.connect(_on_action_executed)
	GameSignals.hand_changed.connect(_on_hand_changed)
	end_turn_button.pressed.connect(turn_manager.end_turn)

	for action in action_database.actions:
		action_manager.register_action(action)
	_register_validators()
	action_panel.init(action_manager)
	action_panel.build_buttons()

	turn_manager.start_game(player_states.size())


#############################################
### GAME LOGIC
#############################################
func _distribute_resources(total: int) -> void:
	if total == 7:
		return
	if not board_state.has_number(total):
		return
	var snap_points := PlacementType.get_snap_points(PlacementType.Type.HEX_VERTEX)
	var coords : Array[Vector2i] = board_state.get_coords_for_number(total)
	for coord in coords:
		var resource = TerrainTypes.to_resource(board_state.get_terrain(coord))
		if resource == null:
			continue
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		for snap in snap_points:
			var vertex_owner := board_state.get_vertex_owner(hex_center + snap)
			if vertex_owner.is_empty():
				continue
			var amount := 2 if vertex_owner.piece_type == PieceTypes.Type.CITY else 1
			for i in amount:
				player_states[vertex_owner.player_index].hand.add_resource(resource)
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
			var offset := HexUtils.axial_to_offset(Vector2i(tile.x, tile.y))
			var sprite := Sprite2D.new()
			sprite.texture = piece_database.get_texture(PieceTypes.Type.ROBBER)
			sprite.position = board_tile_map.map_to_local(offset) + robber_offset
			sprite.modulate = Color.BLACK
			sprite.z_index = 2
			board_view.add_child(sprite)
			return


#############################################
### ACTION VALIDATORS
#############################################
func _register_validators() -> void:
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
	return true


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

func _on_action_executed(type: ActionTypes.Type, action_position: Vector2) -> void:
	var definition := action_manager.get_action(type)
	if definition == null:
		return

	if definition.placement == PlacementType.Type.NONE:
		_deduct_cost(definition)
		return

	var piece_type: PieceTypes.Type = _action_to_piece.get(type, PieceTypes.Type.UNKNOWN)
	if piece_type == PieceTypes.Type.UNKNOWN:
		return

	var snap := _snap_to_nearest(action_position, definition.placement)
	if snap.is_empty():
		return

	if not _can_place(type, snap.pos):
		return

	_place_piece_at(piece_type, snap)
	_deduct_cost(definition)


func _can_place(type: ActionTypes.Type, snapped_pos: Vector2) -> bool:
	var player_index := turn_manager.current_player_index
	match type:
		ActionTypes.Type.BUILD_SETTLEMENT:
			return board_state.can_place_settlement(snapped_pos, player_index)
		ActionTypes.Type.BUILD_ROAD:
			return board_state.can_place_road(snapped_pos, player_index)
		ActionTypes.Type.BUILD_CITY:
			return board_state.can_place_city(snapped_pos, player_index)
	return true


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


func _place_piece_at(type: PieceTypes.Type, snap: Dictionary) -> void:
	board_state.record_placement(type, snap.pos, turn_manager.current_player_index)
	var sprite := Sprite2D.new()
	sprite.texture = piece_database.get_texture(type)
	sprite.rotation_degrees = snap.rotation
	sprite.position = snap.pos
	sprite.modulate = local_player.get_color()
	sprite.z_index = 2
	board_view.add_child(sprite)


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


func _on_action_button_pressed(type: ActionTypes.Type) -> void:
	action_manager.select_action(type, local_player.hand)


func _on_hand_changed() -> void:
	action_panel.refresh(local_player.hand)


func _on_dice_rolled(_d1: DiceFaces.Type, _d2: DiceFaces.Type, total: int) -> void:
	turn_manager.on_dice_rolled()
	_distribute_resources(total)
