extends CanvasLayer

@export var terrain_database: TerrainDatabaseResource
@export var numbers_database: NumberDatabaseResource


@onready var tab_container: TabContainer = $PanelContainer/MainVbox/TabContainer
@onready var tile_grid_container: GridContainer = $PanelContainer/MainVbox/TabContainer/Tiles/VBoxContainer/GridContainer
@onready var number_grid_container: GridContainer = $PanelContainer/MainVbox/TabContainer/Numbers/VBoxContainer/GridContainer

const TERRAIN_KEY := "terrain_key"
const NUMBER_KEY := "number_value"

var selected_terrain: TerrainTypes.Type
var selected_number: int
var selected_button: TextureButton


func _ready() -> void:
	generate_button_tiles()
	generate_number_buttons()


#############################################
### UI ELEMENT GENERATION
#############################################
func generate_number_buttons():
	for number_key in numbers_database.get_keys():
		var number = numbers_database.get_value(number_key)
		var texture = numbers_database.get_texture(number_key)
		var texture_button := TextureButton.new()
		texture_button.texture_normal = texture
		texture_button.texture_hover = texture
		texture_button.texture_pressed = texture
		texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		texture_button.toggle_mode = true
		texture_button.set_meta(NUMBER_KEY, number)
		texture_button.pressed.connect(_on_number_button_pressed.bind(texture_button))
		number_grid_container.add_child(texture_button)


func generate_button_tiles() -> void:
	for terrain_key in terrain_database.get_keys():
		var texture = terrain_database.get_texture(terrain_key)
		var texture_button := TextureButton.new()
		texture_button.texture_normal = texture
		texture_button.texture_hover = texture
		texture_button.texture_pressed = texture
		texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		texture_button.toggle_mode = true
		texture_button.set_meta(TERRAIN_KEY, terrain_key)
		texture_button.pressed.connect(_on_terrain_button_pressed.bind(texture_button))
		tile_grid_container.add_child(texture_button)


#############################################
### SIGNAL HANDLING
#############################################
func _on_terrain_button_pressed(button: TextureButton) -> void:
	var new_value = button.get_meta(TERRAIN_KEY)
	selected_terrain = new_value
	EditorState.set_editor_state_to_terrain()
	EditorState.select_tile(selected_terrain)
	EditorState.clear_selected_number()
	_update_button_visual(button)


func _on_number_button_pressed(button: TextureButton) -> void:
	var value = button.get_meta(NUMBER_KEY)
	EditorState.set_editor_state_to_number()
	selected_number = value
	EditorState.select_number(selected_number)
	EditorState.clear_selected_tile()
	_update_button_visual(button)


func _on_clear_button_pressed() -> void:
	EditorState.clear_board()
	EditorState.clear_selected_tile()
	
	selected_button.button_pressed = false
	selected_button.modulate = Color(1,1,1)
	selected_button.scale = Vector2.ONE
	selected_button = null


func _on_save_button_pressed() -> void:
	EditorState.save_board()


func _on_load_button_pressed() -> void:
	EditorState.load_board()


func _on_tab_container_tab_changed(tab_index: int) -> void:
	match tab_index:
		0: # Tiles tab
			EditorState.set_editor_state_to_terrain()
		1: # Numbers tab
			EditorState.set_editor_state_to_number()


#############################################
### BUTTON VISUALS
#############################################
func _update_button_visual(button: TextureButton) -> void:
	# Unpress previously selected
	if selected_button and selected_button != button:
		selected_button.button_pressed = false
		selected_button.modulate = Color(1, 1, 1)
		selected_button.scale = Vector2.ONE
	
	# Press new button
	selected_button = button
	selected_button.button_pressed = true
	selected_button.modulate = Color(0.75, 0.75, 0.75)
	selected_button.scale = Vector2(0.95, 0.95)
