extends Window

@export var terrain_database: TerrainDatabaseResource

@onready var board_radius_hbox: HBoxContainer = $BoardConfigWindow/BoardRadiusSizeHbox
@onready var board_rect_vbox: VBoxContainer = $BoardConfigWindow/BoardRectSizeVbox
@onready var board_oval_vbox: VBoxContainer = $BoardConfigWindow/BoardOvalSizeVbox
@onready var rule_container: VBoxContainer = $BoardConfigWindow/RuleContainer
@onready var board_radius_spinbox: SpinBox = $BoardConfigWindow/BoardRadiusSizeHbox/BoardRadiusSpinbox
@onready var allowed_tiles_hbox: HBoxContainer = $BoardConfigWindow/AllowedTilesHbox
@onready var shape_option_button: OptionButton = $BoardConfigWindow/BoardShapeHbox/OptionButton
@onready var board_rect_width_spinbox: SpinBox = $BoardConfigWindow/BoardRectSizeVbox/BoardRectWidthHbox/BoardRectWidthSpinbox
@onready var board_rect_height_spinbox: SpinBox = $BoardConfigWindow/BoardRectSizeVbox/BoardRectHeightHbox/BoardRectHeightSpinbox
@onready var board_oval_width_spinbox: SpinBox = $BoardConfigWindow/BoardOvalSizeVbox/BoardOvalWidthHbox/BoardOvalWidthSpinbox
@onready var board_oval_height_spinbox: SpinBox = $BoardConfigWindow/BoardOvalSizeVbox/BoardOvalHeightHbox/BoardOvalHeightSpinbox


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
	_setup_shape_selector()

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


func _setup_shape_selector() -> void:
	shape_option_button.clear()
	shape_option_button.add_item("Circle", Shapes.Type.CIRCLE)
	shape_option_button.add_item("Square", Shapes.Type.SQUARE)
	shape_option_button.add_item("Rectangle", Shapes.Type.RECTANGLE)
	shape_option_button.add_item("Oval", Shapes.Type.OVAL)
	shape_option_button.item_selected.connect(_on_shape_selected)


#############################################
### CONFIG UPDATES
#############################################
func generate_config() -> GenerationConfig:
	var config := GenerationConfig.new()
	
	# rules
	var rule_set = RuleSet.new()
	for checkbox in rule_checkbox_map:
		if checkbox.button_pressed:
			rule_set.add_rule(rule_checkbox_map[checkbox])
	config.rule_set = rule_set
	
	# supported tiles
	for checkbox in tile_checkbox_map:
		if checkbox.button_pressed:
			config.add_tile(tile_checkbox_map[checkbox])
	
	# shape
	var shape : Shapes.Type = shape_option_button.get_selected_id() as Shapes.Type
	config.shape = shape
	handle_shape_configs(shape, config)
	
	return config


func handle_shape_configs(shape: Shapes.Type, config: GenerationConfig) -> void:
	match shape:
		Shapes.Type.CIRCLE:
			config.radius = int(board_radius_spinbox.value)
		Shapes.Type.SQUARE:
			config.radius = int(board_radius_spinbox.value)
		Shapes.Type.OVAL:
			config.oval_height = int(board_oval_height_spinbox.value)
			config.oval_width = int(board_oval_height_spinbox.value)
		Shapes.Type.RECTANGLE:
			config.rect_height = int(board_rect_height_spinbox.value)
			config.rect_width = int(board_rect_width_spinbox.value)

#############################################
### SIGNAL HANDLING
#############################################
func _on_tile_hover_entered(tex_preview: TextureRect):
	tex_preview.visible = true

func _on_tile_hover_exited(tex_preview: TextureRect):
	tex_preview.visible = false


func _on_close_requested() -> void:
	hide()


func _on_shape_selected(_index: int) -> void:
	var shape_id = shape_option_button.get_selected_id()
	board_radius_hbox.visible = false
	board_rect_vbox.visible = false
	board_oval_vbox.visible = false

	match shape_id:
		Shapes.Type.CIRCLE, Shapes.Type.SQUARE:
			board_radius_hbox.visible = true
		Shapes.Type.RECTANGLE:
			board_rect_vbox.visible = true
		Shapes.Type.OVAL:
			board_oval_vbox.visible = true


func _on_generate_button_pressed() -> void:
	var config = generate_config()
	EditorState.generate_board(config)
	hide()
