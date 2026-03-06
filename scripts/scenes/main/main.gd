extends Node

@export var board_editor_scene: PackedScene
@export var game_select_scene: PackedScene

@onready var ui_container: Control = $UIContainer
@onready var scene_container: Node2D = $SceneContainer
@onready var main_menu: Control = $MainMenu
@onready var v_box_container: VBoxContainer = $MainMenu/CenterContainer/VBoxContainer

var active_scene: Node = null
var active_ui: Control = null


func _ready() -> void:
	_setup_signals()


func _setup_signals() -> void:
	SignalBus.back_to_menu.connect(_on_back_to_menu)


func _show_container(container: Control) -> void:
	main_menu.visible = false
	ui_container.visible = false
	container.visible = true


func _cleanup_active() -> void:
	if active_scene:
		active_scene.queue_free()
		active_scene = null
	if active_ui:
		active_ui.queue_free()
		active_ui = null


#############################################
### SIGNALS
#############################################
func _on_back_to_menu() -> void:
	_cleanup_active()
	_show_container(main_menu)


func _on_create_room_button_pressed() -> void:
	print("Create Room clicked")


func _on_join_room_button_pressed() -> void:
	print("Join Room clicked")


func _on_local_game_button_pressed() -> void:
	active_ui = game_select_scene.instantiate()
	ui_container.add_child(active_ui)
	_show_container(ui_container)


func _on_board_editor_button_pressed() -> void:
	active_scene = board_editor_scene.instantiate()
	scene_container.add_child(active_scene)

	active_ui = active_scene.get_node("UI")
	active_scene.remove_child(active_ui)
	ui_container.add_child(active_ui)

	_show_container(ui_container)
