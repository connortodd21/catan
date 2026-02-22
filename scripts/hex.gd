class_name Hex extends Node2D

signal tile_clicked(tile)

var coord: HexAxial
@export var radius := HexConstants.HEX_RADIUS
@export var border_width := 3.0

@export var terrain_database: TerrainDatabaseResource
@export var number: int

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area := $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

var terrain_texture : Texture2D
@onready var shader_material := sprite_2d.material as ShaderMaterial


func initialize(_coord: HexAxial, terrain: TerrainTypes.Type, _number: int) -> void:
	coord = _coord
	number = _number
	terrain_texture = terrain_database.get_texture(terrain)


func _ready() -> void:
	create_hex_shape()

	if sprite_2d and terrain_texture:
		sprite_2d.texture = terrain_texture
		set_shader()

		var tex_size = sprite_2d.texture.get_size()

		# Define ideal hex width/height from your grid radius
		var ideal_width = sqrt(3) * radius
		var ideal_height = 2.0 * radius

		# Scale the sprite to fit inside the ideal hex
		var scale_x = ideal_width / tex_size.x
		var scale_y = ideal_height / tex_size.y

		# Pick the smaller scale to ensure it never overlaps
		var final_scale = min(scale_x, scale_y)
		sprite_2d.scale = Vector2(final_scale, final_scale)


#############################################
### SPRITE/COLLISION
#############################################
func create_hex_shape():
	var points := PackedVector2Array()

	for i in range(6):
		var angle = deg_to_rad(60 * i - 30) # pointy-top hex
		var point = Vector2(
			cos(angle) * radius,
			sin(angle) * radius
		)
		points.append(point)

	var shape = ConvexPolygonShape2D.new()
	shape.points = points

	collision_shape_2d.shape = shape


func get_hex_dimensions() -> Vector2:
	return terrain_database.get_texture(TerrainTypes.Type.WATER).get_size()


#############################################
### CLASS FUNCTIONS
#############################################
func get_supported_terrain_types() -> Array:
	return terrain_database.get_keys()


func set_coord(_coord: HexAxial) -> void:
	coord = _coord


func set_radius(_radius: float) -> void:
	radius = _radius


#############################################
### SHADER
#############################################
func set_shader():
	shader_material.set_shader_parameter("outline_color", Color.TRANSPARENT)
	shader_material.set_shader_parameter("outline_size", 2.0)
