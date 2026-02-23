extends CanvasLayer

signal selection_changed(value: TerrainTypes.Type)

@export var terrain_database: TerrainDatabaseResource

@onready var tile_grid_container: GridContainer = $PanelContainer/MainVbox/TabContainer/Tiles/VBoxContainer/GridContainer


var selected_value : TerrainTypes.Type
var selected_button : TextureButton
const TERRAIN_KEY := "terrain_key"


func _ready() -> void:
	generate_button_tiles()


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


func _on_selection_button_pressed(button: TextureButton) -> void:
	selected_value = button.get_meta(TERRAIN_KEY)
	selection_changed.emit(selected_value)
	
	# clear press effect
	if selected_button and selected_button == button:
		selected_button.button_pressed = false
		selected_button.modulate = Color(1,1,1)
		selected_button.scale = Vector2.ONE
	# add press effect
	else:
		selected_button = button
		selected_button.button_pressed = true
		selected_button.modulate = Color(0.75, 0.75, 0.75)
		selected_button.scale = Vector2(0.95, 0.95)
