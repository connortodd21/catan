extends Node

@export var board_editor_scene: PackedScene
@export var board_select_scene: PackedScene
@export var game_scene: PackedScene


@onready var ui_container: Control = $UIContainer
@onready var scene_container: Node2D = $SceneContainer
@onready var main_menu: Control = $MainMenu
@onready var v_box_container: VBoxContainer = $MainMenu/CenterContainer/VBoxContainer

var _board_select_instance: Node = null
var _game_instance: Node = null


func _show_container(container: Control):
	# Hide all top-level containers
	main_menu.visible = false
	ui_container.visible = false

	# Show only the requested container
	container.visible = true


#############################################
### SIGNALS
#############################################
func _on_back_to_menu() -> void:
	if _board_select_instance:
		_board_select_instance.queue_free()
		_board_select_instance = null
	main_menu.visible = true


func _on_back_from_game() -> void:
	if _game_instance:
		_game_instance.queue_free()
		_game_instance = null
	main_menu.visible = true


func _on_create_room_button_pressed() -> void:
	print("Create Room clicked")


func _on_join_room_button_pressed() -> void:
	print("Join Room clicked")


func _on_local_game_button_pressed() -> void:
	_board_select_instance = board_select_scene.instantiate()
	add_child(_board_select_instance)
	_board_select_instance.board_selected.connect(_on_board_selected)
	_board_select_instance.back_requested.connect(_on_back_to_menu)
	main_menu.visible = false


func _on_board_selected(path: String) -> void:
	if _board_select_instance:
		_board_select_instance.queue_free()
		_board_select_instance = null

	_game_instance = game_scene.instantiate()
	_game_instance.board_path = path
	scene_container.add_child(_game_instance)
	_game_instance.back_requested.connect(_on_back_from_game)


func _on_board_editor_button_pressed() -> void:
	var editor_instance = board_editor_scene.instantiate()
	scene_container.add_child(editor_instance)

	var ui_node = editor_instance.get_node("UI")
	editor_instance.remove_child(ui_node)
	ui_container.add_child(ui_node)

	_show_container(ui_container)
