class_name PopupManager
extends RefCounted


class PopupManagerConfig:
	var selection_popup: SelectionPopup
	var activity_log_popup: ActivityLogPopup
	var stats_popup: StatsPopup
	var settings_popup: SettingsPopup
	var bank_trade_popup: BankTradePopup
	var discard_popup: DiscardPopup
	var game_over_popup: GameOverPopup
	var resource_definitions: Array[ResourceDefinition]


var _selection_popup: SelectionPopup
var _activity_log_popup: ActivityLogPopup
var _stats_popup: StatsPopup
var _settings_popup: SettingsPopup
var _bank_trade_popup: BankTradePopup
var _discard_popup: DiscardPopup
var _game_over_popup: GameOverPopup
var _resource_definitions: Array[ResourceDefinition]


func init(config: PopupManagerConfig) -> void:
	_selection_popup = config.selection_popup
	_activity_log_popup = config.activity_log_popup
	_stats_popup = config.stats_popup
	_settings_popup = config.settings_popup
	_bank_trade_popup = config.bank_trade_popup
	_discard_popup = config.discard_popup
	_game_over_popup = config.game_over_popup
	_resource_definitions = config.resource_definitions


#############################################
### PLAYER SELECT
#############################################
func show_player_select(player_indices: Array[int], player_states: Array[PlayerState], callback: Callable) -> void:
	var options: Array[SelectionPopup.SelectionOption] = []
	for index in player_indices:
		options.append(SelectionPopup.SelectionOption.new(
			player_states[index].get_name(),
			index,
			player_states[index].get_color(),
		))
	_selection_popup.show_selection("Choose a player to steal from", options, callback)


#############################################
### RESOURCE SELECT
#############################################
func show_resource_select(callback: Callable, count: int = 1) -> void:
	var options: Array[SelectionPopup.SelectionOption] = []
	for resource_def in _resource_definitions:
		options.append(SelectionPopup.SelectionOption.new(
			ResourceTypes.type_to_str(resource_def.resource_type),
			resource_def.resource_type,
			Color.BLACK,
			resource_def.texture,
		))
	_selection_popup.show_selection("Choose a resource", options, callback, count)


#############################################
### ACTIVITY LOG
#############################################
func show_activity_log(activity_log: ActivityLog, anchor: Vector2) -> void:
	_activity_log_popup.show_log(activity_log, anchor)


#############################################
### STATS
#############################################
func show_stats(game_stats: GameStats) -> void:
	_stats_popup.show_stats(game_stats)


#############################################
### SETTINGS
#############################################
func show_settings() -> void:
	_settings_popup.popup_centered()


#############################################
### BANK TRADE
#############################################
func show_bank_trade(hand: Hand, trade_rates: Dictionary, callback: Callable) -> void:
	_bank_trade_popup.init(hand, _resource_definitions, trade_rates, callback)


#############################################
### DISCARD
#############################################
func show_discard(hand: Hand, discard_count: int, callback: Callable) -> void:
	_discard_popup.init(hand, _resource_definitions, discard_count, callback)


#############################################
### GAME OVER
#############################################
func show_game_over(winner_state: PlayerState, standings: Array, callback: Callable) -> void:
	_game_over_popup.init(winner_state, standings, callback)
