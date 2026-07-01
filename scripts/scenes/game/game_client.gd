class_name GameClient
extends Node


#############################################
### EXPORTS
#############################################

# Rendering databases
@export var number_database: NumberDatabaseResource
@export var piece_database: PieceDatabaseResource
@export var port_deck: PortDeck
@export var terrain_database: TerrainDatabaseResource

# Scenes
@export var port_scene: PackedScene

# Rendering config
@export var number_offset: Vector2 = Vector2(-25, -25)
@export var number_scale: float = 1.6
@export var robber_offset: Vector2 = Vector2(-40, 0)


#############################################
### NODES
#############################################

# Board
@onready var board_tile_map: TileMapLayer = $"../BoardView/BoardTileMap"
@onready var board_view: Node2D = $"../BoardView"

# HUD
@onready var debug_label: Label = $"../UI/DebugLabel"
@onready var hand_manager: HandManager = $"../UI/HandManager"
@onready var player_hud: PlayerHUD = $"../UI/PlayerHUD"

# Game menu
@onready var action_panel: ActionPanel = $"../UI/GameMenu/ActionPanel"
@onready var bank_trade_button: Button = $"../UI/GameMenu/TradePanel/BankTradeButton"
@onready var dice_roller: DiceRoller = $"../UI/GameMenu/DiceRoller"
@onready var end_turn_button: Button = $"../UI/GameMenu/EndTurnButton"
@onready var player_trade_button: Button = $"../UI/GameMenu/TradePanel/PlayerTradeButton"
@onready var trade_panel: VBoxContainer = $"../UI/GameMenu/TradePanel"

# Menu buttons
@onready var activity_log_button: TextureButton = $"../UI/MenuHbox/ActivityLogButton"
@onready var settings_button: TextureButton = $"../UI/MenuHbox/SettingsButton"
@onready var stats_button: TextureButton = $"../UI/MenuHbox/StatsButton"

# Popups
@onready var activity_log_popup: ActivityLogPopup = $"../UI/ActivityLogPopup"
@onready var bank_trade_popup: BankTradePopup = $"../UI/BankTradePopup"
@onready var discard_popup: DiscardPopup = $"../UI/DiscardPopup"
@onready var game_over_popup: GameOverPopup = $"../UI/GameOverPopup"
@onready var selection_popup: SelectionPopup = $"../UI/SelectionPopup"
@onready var settings_popup: SettingsPopup = $"../UI/SettingsPopup"
@onready var stats_popup: StatsPopup = $"../UI/StatsPopup"


#############################################
### STATE
#############################################

var activity_log: ActivityLog = ActivityLog.new()
var board: SerializedBoard
var board_renderer: BoardRenderer
var current_phase: GamePhase.Phase
var current_player_index: int
var game_stats: GameStats = GameStats.new()
var local_player_index: int
var player_states: Array[PlayerState] = []
var popup_manager: PopupManager
var tile_coords: Array[Vector2i] = []


#############################################
### INIT
#############################################

func init(game_config: GameConfig, p_player_states: Array[PlayerState]) -> void:
	player_states = p_player_states
	board = game_config.board
	board_renderer = BoardRenderer.new(board_view, board_tile_map)
	render_board()
	if game_config.has_robber():
		place_robber_on_desert()
	_init_players(game_config)
	_init_popup_manager()
	_register_signals()


func _init_players(game_config: GameConfig) -> void:
	game_stats.player_game_stats.register_players(game_config.players)
	player_hud.init(player_states)
	player_hud.set_harbormaster_enabled(game_config.has_harbormaster())
	hand_manager.set_hand(player_states[local_player_index].hand)


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
### PIECE RENDERING
#############################################

func render_piece(player_index: int, piece_type: PieceTypes.Type, world_pos: Vector2, rotation: float) -> void:
	if piece_type == PieceTypes.Type.CITY:
		board_renderer.remove_piece_at(world_pos)
	var color := player_states[player_index].get_color()
	board_renderer.place_piece(piece_database.get_texture(piece_type), world_pos, color, rotation)


func snap_to_nearest(mouse_pos: Vector2, placement: PlacementType.Type) -> Dictionary:
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


#############################################
### ROBBER RENDERING
#############################################

func place_robber_on_desert() -> void:
	for tile: TileEntry in board.tiles:
		if tile.type == TerrainTypes.Type.DESERT:
			var coord := Vector2i(tile.x, tile.y)
			var world_pos: Vector2 = board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
			board_renderer.place_robber(piece_database.get_texture(PieceTypes.Type.ROBBER), world_pos, robber_offset)
			return


func render_robber_move(coord: Vector2i) -> void:
	var world_pos: Vector2 = board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
	board_renderer.move_robber_to(world_pos, robber_offset)


#############################################
### HUD
#############################################

func refresh_hud() -> void:
	dice_roller.set_roll_enabled(current_phase == GamePhase.Phase.ROLL)
	end_turn_button.disabled = (current_phase != GamePhase.Phase.ACTION)
	action_panel.visible = (current_phase != GamePhase.Phase.SETUP)
	trade_panel.visible = (current_phase != GamePhase.Phase.SETUP)
	bank_trade_button.disabled = (current_phase != GamePhase.Phase.ACTION)
	player_trade_button.disabled = (current_phase != GamePhase.Phase.ACTION)
	action_panel.refresh(player_states[local_player_index].hand)
	update_debug_label()


func update_debug_label() -> void:
	var phase_name: String = GamePhase.Phase.keys()[current_phase]
	var player_name: String = player_states[current_player_index].get_name()
	debug_label.text = "Player: %s | Phase: %s" % [player_name, phase_name]


#############################################
### POPUPS
#############################################

func _init_popup_manager() -> void:
	var config := PopupManager.PopupManagerConfig.new()
	config.selection_popup = selection_popup
	config.activity_log_popup = activity_log_popup
	config.stats_popup = stats_popup
	config.settings_popup = settings_popup
	config.bank_trade_popup = bank_trade_popup
	config.discard_popup = discard_popup
	config.game_over_popup = game_over_popup
	config.resource_definitions = hand_manager.get_sorted_resource_definitions()
	popup_manager = PopupManager.new()
	popup_manager.init(config)


func show_game_over(winner_index: int, standings: Array[PlayerState]) -> void:
	popup_manager.show_game_over(player_states[winner_index], standings, _on_game_over_exit)


func show_discard(discard_count: int) -> void:
	hand_manager.disable_hover()
	popup_manager.show_discard(player_states[local_player_index].hand, discard_count, _on_discard_confirmed)


func show_bank_trade(trade_rates: Dictionary) -> void:
	hand_manager.disable_hover()
	popup_manager.show_bank_trade(player_states[local_player_index].hand, trade_rates, _on_bank_trade_confirmed)


func show_player_select(stealable_players: Array[int]) -> void:
	hand_manager.disable_hover()
	popup_manager.show_player_select(stealable_players, player_states, _on_robber_target_selected)


func show_resource_select(callback: Callable, count: int = 1) -> void:
	hand_manager.disable_hover()
	popup_manager.show_resource_select(callback, count)


#############################################
### SERVER UPDATES
#############################################

func notify_game_start(p_player_states: Array[PlayerState], p_board: SerializedBoard) -> void:
	player_states = p_player_states
	board = p_board


func notify_turn_changed(new_player_index: int, phase: GamePhase.Phase) -> void:
	current_player_index = new_player_index
	current_phase = phase
	player_hud.set_active_player(current_player_index)
	hand_manager.set_hand(player_states[local_player_index].hand)
	refresh_hud()


func notify_dice_rolled(player_index: int, d1: DiceFaces.Type, d2: DiceFaces.Type) -> void:
	GameSignals.emit_player_rolled(player_states[player_index].player, d1)
	dice_roller.show_result(d1, d2)


func notify_settlement_placed(player_index: int, world_pos: Vector2, rotation: float) -> void:
	render_piece(player_index, PieceTypes.Type.SETTLEMENT, world_pos, rotation)
	GameSignals.emit_piece_placed(player_states[player_index].player, PieceTypes.Type.SETTLEMENT, world_pos)


func notify_road_placed(player_index: int, world_pos: Vector2, rotation: float) -> void:
	render_piece(player_index, PieceTypes.Type.ROAD, world_pos, rotation)
	GameSignals.emit_piece_placed(player_states[player_index].player, PieceTypes.Type.ROAD, world_pos)


func notify_city_placed(player_index: int, world_pos: Vector2, rotation: float) -> void:
	render_piece(player_index, PieceTypes.Type.CITY, world_pos, rotation)
	GameSignals.emit_piece_placed(player_states[player_index].player, PieceTypes.Type.CITY, world_pos)


func notify_robber_moved(coord: Vector2i, stealable_players: Array[int]) -> void:
	render_robber_move(coord)
	if not stealable_players.is_empty():
		show_player_select(stealable_players)


func notify_hand_updated(hand_dict: Dictionary) -> void:
	player_states[local_player_index].hand.resource_counts = hand_dict
	hand_manager.set_hand(player_states[local_player_index].hand)
	GameSignals.emit_hand_changed()


func notify_dev_card_bought(player_index: int) -> void:
	GameSignals.emit_development_card_bought(player_states[player_index].player)


func notify_dev_card_drawn(card: CardDefinition) -> void:
	player_states[local_player_index].hand.add_card(card)
	GameSignals.emit_hand_changed()


func notify_dev_card_played(player_index: int, card_type: CardTypes.Type) -> void:
	GameSignals.emit_dev_card_played(player_states[player_index].player, card_type)


func notify_player_stats_changed(player_index: int, road_length: int, army_size: int, harbormaster_count: int) -> void:
	player_hud.update_player_stats(player_index, road_length, army_size, harbormaster_count)


func notify_resource_count_changed(player_index: int, count: int) -> void:
	player_hud.update_resource_count(player_index, count)


func notify_discard_required(discard_count: int) -> void:
	show_discard(discard_count)


func notify_bank_trade_requested(trade_rates: Dictionary) -> void:
	show_bank_trade(trade_rates)


func notify_game_over(winner_index: int, standings: Array[PlayerState]) -> void:
	show_game_over(winner_index, standings)


#############################################
### SIGNALS
#############################################

func _register_signals() -> void:
	GameSignals.phase_changed.connect(_on_phase_changed)
	GameSignals.player_changed.connect(_on_player_changed)
	GameSignals.hand_changed.connect(_on_hand_changed)
	GameSignals.card_clicked.connect(_on_card_clicked)
	GameSignals.action_button_pressed.connect(_on_action_button_pressed)
	GameSignals.dice_rolled.connect(_on_dice_rolled)
	GameSignals.setup_phase_ended_for_player.connect(_on_setup_phase_ended_for_player)
	activity_log_button.pressed.connect(_on_activity_log_button_pressed)
	bank_trade_button.pressed.connect(_on_bank_trade_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	stats_button.pressed.connect(_on_stats_button_pressed)


func _on_phase_changed(phase: GamePhase.Phase) -> void:
	current_phase = phase
	refresh_hud()


func _on_player_changed(player_index: int) -> void:
	current_player_index = player_index
	player_hud.set_active_player(player_index)
	hand_manager.set_hand(player_states[local_player_index].hand)
	action_panel.refresh(player_states[local_player_index].hand)
	update_debug_label()


func _on_hand_changed() -> void:
	action_panel.refresh(player_states[local_player_index].hand)


func _on_card_clicked(_card: CardDefinition) -> void:
	pass # request_play_dev_card RPC — wired in Task 14


func _on_action_button_pressed(_action_type: ActionTypes.Type) -> void:
	pass # request action selection — wired in Task 14


func _on_dice_rolled(_d1: DiceFaces.Type, _d2: DiceFaces.Type, _dice_total: int) -> void:
	pass # notify_dice_rolled handles display — wired in Task 14


func _on_setup_phase_ended_for_player(_player_index: int, _settlement_pos: Vector2) -> void:
	pass # request_collect_setup_resources RPC — wired in Task 14


func _on_activity_log_button_pressed() -> void:
	var anchor := Vector2(activity_log_button.global_position.x, activity_log_button.global_position.y + activity_log_button.size.y)
	popup_manager.show_activity_log(activity_log, anchor)


func _on_bank_trade_button_pressed() -> void:
	pass # request_bank_trade_rates RPC — wired in Task 14


func _on_settings_button_pressed() -> void:
	popup_manager.show_settings()


func _on_stats_button_pressed() -> void:
	popup_manager.show_stats(game_stats)


func _on_robber_target_selected(_target_index: int) -> void:
	pass # request_steal_resource RPC — wired in Task 14


func _on_discard_confirmed(_resources_after_discard: Array[ResourceTypes.Type]) -> void:
	pass # request_discard RPC — wired in Task 14


func _on_bank_trade_confirmed(_traded: Array[ResourceTypes.Type], _received: Array[ResourceTypes.Type]) -> void:
	pass # request_bank_trade RPC — wired in Task 14


func _on_game_over_exit() -> void:
	GlobalSignals.go_back_to_menu()


func _on_popup_closed() -> void:
	hand_manager.enable_hover()


#############################################
### INPUT
#############################################

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := board_view.get_local_mouse_position()
			match current_phase:
				GamePhase.Phase.ROBBER:
					_on_robber_board_click(mouse_pos)
				GamePhase.Phase.ACTION, GamePhase.Phase.PLAYING_CARD, GamePhase.Phase.SETUP:
					_on_action_board_click(mouse_pos)


func _on_robber_board_click(_mouse_pos: Vector2) -> void:
	pass # request_place_robber RPC — wired in Task 14


func _on_action_board_click(_mouse_pos: Vector2) -> void:
	pass # request_place_piece RPC — wired in Task 14
