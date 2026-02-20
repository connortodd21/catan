extends Node2D

@export var hex_scene: PackedScene

const HEX_SIZE := 60.0
const TERRAIN_COUNT := 11

func _ready():
	var hex = hex_scene.instantiate()
	hex.position = Vector2.ZERO
	add_child(hex)
	
	randomize()
	generate_board(1)


func spawn_hex(coord: Vector3i):
	var hex = hex_scene.instantiate()

	var terrain = hex.get_supported_terrain_types().pick_random()
	var number = 0

	hex.initialize(coord, terrain, number)
	hex.position = HexUtils.pointy_hex_to_pixel(coord, HEX_SIZE)

	add_child(hex)


func generate_board(radius: int):
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var z = -x - y
			if abs(z) <= radius:
				spawn_hex(Vector3i(x, y, z))
