class_name Hex extends Node2D

signal tile_clicked(tile)

var axial_coord: HexAxial

@export var terrain_database: TerrainDatabaseResource
@export var number: int


@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area := $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

var terrain_texture : Texture2D


func initialize(coord: HexAxial, terrain: TerrainTypes.Type, _number: int) -> void:
	axial_coord = coord
	number = _number
	terrain_texture = terrain_database.get_texture(terrain)


func _ready() -> void:
	create_hex_shape(HexConstants.HEX_RADIUS)
	if sprite_2d and terrain_texture:
		sprite_2d.texture = terrain_texture


func create_hex_shape(radius: float):
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


func get_supported_terrain_types() -> Array:
	return terrain_database.get_keys()
