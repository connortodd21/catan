class_name ActivityLogPopup
extends PopupPanel

const POPUP_SIZE := Vector2i(480, 350)

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _rich_text: RichTextLabel = $VBoxContainer/RichTextLabel


func _ready() -> void:
	_header.set_close_callback(hide)
	_header.set_title("Activity Log")
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	add_theme_stylebox_override("panel", bg)


func show_log(activity_log: ActivityLog, anchor: Vector2) -> void:
	_rich_text.clear()
	for entry: ActivityEntry in activity_log.entries:
		_rich_text.append_text(entry.to_bbcode())
	popup(Rect2i(Vector2i(anchor), POPUP_SIZE))
