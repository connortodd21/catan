extends Node

@export var board_editor_scene: PackedScene
@export var game_select_scene: PackedScene
@export var game_scene: PackedScene

@onready var scene_container: Node2D = $SceneContainer
@onready var main_menu: Control = $MainMenu


var active_scene: Node = null
var active_ui: Node = null


func _ready() -> void:
	_setup_signals()


func _setup_signals() -> void:
	GlobalSignals.back_to_menu.connect(_on_back_to_menu)
	GameSelectState.game_started.connect(_on_game_start)


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
	main_menu.visible = true


func _on_host_game_button_pressed() -> void:
	print("Create Room clicked")


func _on_join_game_button_pressed() -> void:
	print("Join Room clicked")


func _on_local_game_button_pressed() -> void:
	main_menu.visible = false
	active_ui = game_select_scene.instantiate()
	add_child(active_ui)


func _on_board_editor_button_pressed() -> void:
	main_menu.visible = false
	active_scene = board_editor_scene.instantiate()
	scene_container.add_child(active_scene)

	active_ui = active_scene.get_node("UI")
	active_scene.remove_child(active_ui)
	add_child(active_ui)


func _on_game_start(game_config: GameConfig) -> void:
	if active_ui:
		active_ui.queue_free()
		active_ui = null
	active_scene = game_scene.instantiate()
	active_scene.game_config = game_config
	scene_container.add_child(active_scene)
