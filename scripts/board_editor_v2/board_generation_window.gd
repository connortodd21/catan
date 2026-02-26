extends Window

@export var terrain_database: TerrainDatabaseResource

@onready var rule_container: VBoxContainer = $BoardConfigWindow/RuleContainer
@onready var allowed_tiles_hbox: HBoxContainer = $BoardConfigWindow/AllowedTilesHbox

var tile_checkbox_map := {}
var rule_checkbox_map := {}
var rule_registry : RuleRegistry = RuleRegistry.new()


var DEFAULT_TERRAIN_TYPES : Array[TerrainTypes.Type] = [
	TerrainTypes.Type.WOOD, TerrainTypes.Type.BRICK, TerrainTypes.Type.SHEEP, 
	TerrainTypes.Type.WHEAT, TerrainTypes.Type.ROCK, TerrainTypes.Type.DESERT
]


func _ready():
	_build_rule_list()
	_build_allowed_tiles_checkboxes()


#############################################
### UI ELEMENT GENERATION
#############################################
func _build_rule_list():
	for child in rule_container.get_children():
		child.queue_free()
	rule_checkbox_map.clear()

	var available_rules = rule_registry.get_all_rules()
	for rule in available_rules:
		var checkbox := CheckBox.new()
		checkbox.text = rule.get_rule_name()
		checkbox.button_pressed = true
		rule_container.add_child(checkbox)
		rule_checkbox_map[checkbox] = rule


func _build_allowed_tiles_checkboxes():
	var children = allowed_tiles_hbox.get_children()
	for child in children:
		allowed_tiles_hbox.remove_child(child)
		child.queue_free()
	tile_checkbox_map.clear()

	for terrain in terrain_database.get_keys():
		var vbox = VBoxContainer.new()
		allowed_tiles_hbox.add_child(vbox)

		var checkbox = CheckBox.new()
		checkbox.text = TerrainTypes.type_to_str(terrain) 
		checkbox.button_pressed = terrain in DEFAULT_TERRAIN_TYPES
		vbox.add_child(checkbox)
		tile_checkbox_map[checkbox] = terrain

		# Hover preview
		var tex_preview = TextureRect.new()
		tex_preview.texture = terrain_database.get_texture(terrain)
		tex_preview.custom_minimum_size = Vector2(64, 64) # or whatever size you want
		tex_preview.visible = false
		tex_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(tex_preview)
		checkbox.connect("mouse_entered", Callable(self, "_on_tile_hover_entered").bind(tex_preview))
		checkbox.connect("mouse_exited", Callable(self, "_on_tile_hover_exited").bind(tex_preview))


#############################################
### SIGNAL HANDLING
#############################################
func _on_tile_hover_entered(tex_preview: TextureRect):
	tex_preview.visible = true

func _on_tile_hover_exited(tex_preview: TextureRect):
	tex_preview.visible = false


func _on_close_requested() -> void:
	hide()


func _on_generate_button_pressed() -> void:
	var config := GenerationConfig.new()
	var rule_set = RuleSet.new()

	for checkbox in rule_checkbox_map:
		if checkbox.button_pressed:
			rule_set.add_rule(rule_checkbox_map[checkbox])
	config.rule_set = rule_set
	
	for checkbox in tile_checkbox_map:
		if checkbox.pressed:
			config.add_tile(tile_checkbox_map[checkbox])

	EditorState.generate_board(config)
	hide()
