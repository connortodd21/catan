extends CanvasLayer

@export var terrain_database: TerrainDatabaseResource

@onready var tile_grid_container: GridContainer = $PanelContainer/MainVbox/TabContainer/Tiles/VBoxContainer/GridContainer
@onready var number_grid_container: GridContainer = $PanelContainer/MainVbox/TabContainer/Numbers/VBoxContainer/GridContainer

var selected_value : TerrainTypes.Type
var selected_button : TextureButton
const TERRAIN_KEY := "terrain_key"


func _ready() -> void:
	generate_button_tiles()
	generate_number_buttons()


#############################################
### UI ELEMENT GENERATION
#############################################
func generate_number_buttons():
	number_grid_container.columns = 4
	for i in range(2, 13):
		var button = Button.new()
		button.text = str(i)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(80, 60)
		button.set_meta("value", i)
		button.pressed.connect(_on_selection_button_pressed.bind(button))
		number_grid_container.add_child(button)


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
		texture_button.pressed.connect(_on_selection_button_pressed.bind(texture_button))
		tile_grid_container.add_child(texture_button)


#############################################
### SIGNAL HANDLING
#############################################
func _on_selection_button_pressed(button: TextureButton) -> void:
	var new_value = button.get_meta(TERRAIN_KEY)
	selected_value = new_value
	EditorState.select_tile(selected_value)
	
	# Unpress the previously selected button
	if selected_button and selected_button != button:
		selected_button.button_pressed = false
		selected_button.modulate = Color(1,1,1)
		selected_button.scale = Vector2.ONE
	
	# Press the new button
	selected_button = button
	selected_button.button_pressed = true
	selected_button.modulate = Color(0.75, 0.75, 0.75)
	selected_button.scale = Vector2(0.95, 0.95)


func _on_clear_button_pressed() -> void:
	EditorState.clear_board()
	EditorState.clear_selected_tile()
	
	selected_button.button_pressed = false
	selected_button.modulate = Color(1,1,1)
	selected_button.scale = Vector2.ONE
	selected_button = null
