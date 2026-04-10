class_name PopupManager
extends RefCounted

var _popup: SelectionPopup
var _resource_definitions: Array[ResourceDefinition]


func init(p_popup: SelectionPopup, p_resource_definitions: Array[ResourceDefinition]) -> void:
	_popup = p_popup
	_resource_definitions = p_resource_definitions


#############################################
### PLAYER SELECT
#############################################
func show_player_select(player_indices: Array[int], player_states: Array[PlayerState], callback: Callable) -> void:
	var options: Array[Dictionary] = []
	for index in player_indices:
		options.append({
			"label": player_states[index].get_name(),
			"color": player_states[index].get_color(),
			"value": index,
		})
	_popup.show_selection("Choose a player to steal from", options, callback)


#############################################
### RESOURCE SELECT
#############################################
func show_resource_select(callback: Callable, count: int = 1) -> void:
	var options: Array[Dictionary] = []
	for resource_def in _resource_definitions:
		if resource_def.resource_type == ResourceTypes.Type.UNKNOWN:
			continue
		options.append({
			"label": ResourceTypes.type_to_str(resource_def.resource_type),
			"texture": resource_def.texture,
			"value": resource_def.resource_type,
		})
	_popup.show_selection("Choose a resource", options, callback, count)
