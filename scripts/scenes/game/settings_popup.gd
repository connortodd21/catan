class_name SettingsPopup
extends PopupPanel

@onready var _header: DraggableHeader = $VBoxContainer/DraggableHeader
@onready var _confirmation: ConfirmationDialog = $VBoxContainer/ConfirmationDialog


func _ready() -> void:
	_header.set_close_callback(hide)
	_header.set_title("Settings")
	_confirmation.confirmed.connect(_on_exit_confirmed)


func _on_quit_button_pressed() -> void:
	_confirmation.popup_centered()


func _on_exit_confirmed() -> void:
	GlobalSignals.go_back_to_menu()


func _on_exit_button_pressed() -> void:
	_confirmation.popup_centered()
