class_name ActivityEntry
extends RefCounted

const KEY_TOTAL = "total"
const KEY_RESOURCES = "resources"
const KEY_PIECE_TYPE = "piece_type"
const KEY_CARD_TYPE = "card_type"
const KEY_TRADED = "traded"
const KEY_RECEIVED = "received"
const KEY_VICTIM = "victim"
const KEY_RESOURCE = "resource"
const KEY_TITLE = "title"
const KEY_PREVIOUS_HOLDER = "previous_holder"
const KEY_AMOUNT = "amount"

var player: Player
var event_type: ActivityEvent.Type
var activity_metadata: Dictionary


func _init(_player: Player, _event_type: ActivityEvent.Type, _activity_metadata: Dictionary = {}) -> void:
	player = _player
	event_type = _event_type
	activity_metadata = _activity_metadata


func to_bbcode() -> String:
	match event_type:
		ActivityEvent.Type.TURN_CHANGE:
			return "[color=#555555]─────────────────────────[/color]\n"
		ActivityEvent.Type.DICE_ROLLED:
			return "%s rolled a [b]%d[/b]\n" % [_player_tag(player), activity_metadata[KEY_TOTAL]]
		ActivityEvent.Type.RESOURCES_DISTRIBUTED:
			return "%s collected %s\n" % [_player_tag(player), _player_resources_to_str(activity_metadata[KEY_RESOURCES])]
		ActivityEvent.Type.PIECE_PLACED:
			return "%s built a %s\n" % [_player_tag(player), PieceTypes.type_to_str(activity_metadata[KEY_PIECE_TYPE])]
		ActivityEvent.Type.DEVELOPMENT_CARD_BOUGHT:
			return "%s bought a Development Card\n" % _player_tag(player)
		ActivityEvent.Type.DEVELOPMENT_CARD_PLAYED:
			return "%s played %s\n" % [_player_tag(player), CardTypes.type_to_str(activity_metadata[KEY_CARD_TYPE])]
		ActivityEvent.Type.BANK_TRADE:
			return "%s traded %s for %s\n" % [_player_tag(player), _resource_array_to_str(activity_metadata[KEY_TRADED]), _resource_array_to_str(activity_metadata[KEY_RECEIVED])]
		ActivityEvent.Type.RESOURCE_STOLEN:
			return "%s stole %s from %s\n" % [_player_tag(player), ResourceTypes.type_to_str(activity_metadata[KEY_RESOURCE]), _player_tag(activity_metadata[KEY_VICTIM])]
		ActivityEvent.Type.TITLE_CHANGED:
			var title_str := TitleTypes.type_to_str(activity_metadata[KEY_TITLE])
			var previous: Player = activity_metadata[KEY_PREVIOUS_HOLDER]
			if previous:
				return "%s took [b]%s[/b] from %s\n" % [_player_tag(player), title_str, _player_tag(previous)]
			return "%s claimed [b]%s[/b]\n" % [_player_tag(player), title_str]
		ActivityEvent.Type.TITLE_LOST:
			var title_str := TitleTypes.type_to_str(activity_metadata[KEY_TITLE])
			return "%s lost [b]%s[/b]\n" % [_player_tag(player), title_str]
		ActivityEvent.Type.VP_CHANGED:
			var amount: int = activity_metadata[KEY_AMOUNT]
			var sign := "+" if amount > 0 else ""
			var label := "Victory Point" if absi(amount) == 1 else "Victory Points"
			return "[indent]%s [b]%s%d[/b] %s[/indent]\n" % [_player_tag(player), sign, amount, label]
	return ""


func _player_tag(p: Player) -> String:
	return "[color=#%s]%s[/color]" % [p.get_color().to_html(false), p.player_name]


func _player_resources_to_str(resources: PlayerResources) -> String:
	var parts: Array[String] = []
	for resource in ResourceTypes.DISPLAY_ORDER:
		var count := resources.get_count(resource)
		if count > 0:
			parts.append("%d %s" % [count, ResourceTypes.type_to_str(resource)])
	return ", ".join(parts)


func _resource_array_to_str(resources: Array[ResourceTypes.Type]) -> String:
	var counts: Dictionary = {}
	for resource in resources:
		counts[resource] = counts.get(resource, 0) + 1
	var parts: Array[String] = []
	for resource in ResourceTypes.DISPLAY_ORDER:
		if counts.has(resource):
			parts.append("%d %s" % [counts[resource], ResourceTypes.type_to_str(resource)])
	return ", ".join(parts)
