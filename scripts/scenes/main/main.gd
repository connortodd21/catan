extends Node

@export var board_editor_scene: PackedScene
@export var game_scene: PackedScene
@export var game_select_scene: PackedScene
@export var multiplayer_game_lobby_scene: PackedScene

@onready var game_manager: GameManager = $Networking/GameManager
@onready var join_button: Button = $MainMenu/JoinGamePopup/VBoxContainer/HBoxContainer/JoinButton
@onready var join_game_popup: PopupPanel = $MainMenu/JoinGamePopup
@onready var lobby_manager: LobbyManager = $Networking/LobbyManager
@onready var main_menu: Control = $MainMenu
@onready var room_code_line_edit: LineEdit = $MainMenu/JoinGamePopup/VBoxContainer/RoomCodeLineEdit
@onready var scene_container: Node2D = $SceneContainer


const JOIN_BUTTON_DEFAULT_TEXT = "JOIN"
const JOIN_BUTTON_CONNECTING_TEXT = "Connecting..."

var active_scene: Node = null
var active_ui: Node = null


func _ready() -> void:
	_setup_signals()


func _setup_signals() -> void:
	GlobalSignals.back_to_menu.connect(_on_back_to_menu)
	GameSelectSignals.game_started.connect(_on_game_start)
	NetworkSignals.lobby_created.connect(_on_lobby_created)
	NetworkSignals.lobby_joined.connect(_on_lobby_joined)
	NetworkSignals.lobby_join_failed.connect(_on_lobby_join_failed)


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
	lobby_manager.create_lobby()


func _on_lobby_created(_lobby_id: int, _room_code: String) -> void:
	main_menu.visible = false
	active_ui = multiplayer_game_lobby_scene.instantiate()
	add_child(active_ui)
	active_ui.init(lobby_manager, game_manager)
	active_ui.setup_as_host()


func _on_join_game_button_pressed() -> void:
	room_code_line_edit.clear()
	join_button.disabled = false
	join_button.text = JOIN_BUTTON_DEFAULT_TEXT
	join_game_popup.popup_centered()


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


func _on_join_game_cancel_button_pressed() -> void:
	join_game_popup.hide()


func _on_join_game_join_button_pressed() -> void:
	var room_code := room_code_line_edit.text.strip_edges()
	if not room_code.is_empty():
		join_button.disabled = true
		join_button.text = JOIN_BUTTON_CONNECTING_TEXT
		lobby_manager.join_lobby(room_code)


func _on_lobby_joined(_lobby_id: int) -> void:
	join_game_popup.hide()
	join_button.disabled = false
	main_menu.visible = false
	active_ui = multiplayer_game_lobby_scene.instantiate()
	add_child(active_ui)
	active_ui.init(lobby_manager, game_manager)
	active_ui.setup_as_client()


func _on_lobby_join_failed(_reason: String) -> void:
	join_button.disabled = false
	join_button.text = JOIN_BUTTON_DEFAULT_TEXT
