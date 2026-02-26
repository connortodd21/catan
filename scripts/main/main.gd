extends Node

@export var board_editor_scene: PackedScene


@onready var ui_container: Control = $UIContainer
@onready var scene_container: Node2D = $SceneContainer
@onready var main_menu: Control = $MainMenu
@onready var v_box_container: VBoxContainer = $MainMenu/CenterContainer/VBoxContainer


func _show_container(container: Control):
	# Hide all top-level containers
	main_menu.visible = false
	ui_container.visible = false

	# Show only the requested container
	container.visible = true

#############################################
### SIGNALS
#############################################
func _on_back_to_menu():
	_show_container(main_menu)


func _on_create_room_button_pressed() -> void:
	print("Create Room clicked")


func _on_join_room_button_pressed() -> void:
	print("Join Room clicked")


func _on_local_game_button_pressed() -> void:
	print("Local Game clicked")


func _on_board_editor_button_pressed() -> void:
	var editor_instance = board_editor_scene.instantiate()
	scene_container.add_child(editor_instance) 

	var ui_node = editor_instance.get_node("UI")
	editor_instance.remove_child(ui_node)
	ui_container.add_child(ui_node)

	_show_container(ui_container)
