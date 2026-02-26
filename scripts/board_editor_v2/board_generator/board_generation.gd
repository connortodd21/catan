class_name BoardGenerator

const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

const DEFAULT_NUMBER_POOL := [
	2, 3, 3, 4, 4, 5, 5,
	6, 6, 8, 8,
	9, 9, 10, 10, 11, 11, 12
]


static func generate(config: GenerationConfig) -> SerializedBoard:
	var rng := RandomNumberGenerator.new()
	if config.seed_value != 0:
		rng.seed = config.seed_value
	else:
		rng.randomize()

	var coords := _generate_coords(config.radius)

	# generate tiles
	var tile_map := {}
	for attempt in 20:
		tile_map = _assign_tiles(coords, config, rng)
		if not tile_map.is_empty():
			break

	if tile_map.is_empty():
		return null

	# generate numbers
	var number_map := {}
	for attempt in 20:
		number_map = _assign_numbers(tile_map, coords, config, rng)
		if not number_map.is_empty():
			break

	if number_map.is_empty():
		return null

	# convert to serialized board
	var board := SerializedBoard.new()
	for coord in tile_map.keys():
		board.add_tile_vector2(coord, tile_map[coord])
	for coord in number_map.keys():
		board.add_numbers_vector2(coord, [number_map[coord]])
	return board


#############################################
### COORDS
#############################################
static func _generate_coords(radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []

	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coords.append(Vector2i(q, r))

	return coords


#############################################
### BOARD ASSIGNMENT
#############################################
static func _assign_tiles(coords: Array[Vector2i], config: GenerationConfig, rng: RandomNumberGenerator) -> Dictionary:
	if config.allowed_tiles.is_empty():
		return {}

	var tile_pool: Array = []
	var needed := coords.size()

	while tile_pool.size() < needed:
		tile_pool.append_array(config.allowed_tiles)

	_shuffle_with_rng(tile_pool, rng)

	var coords_to_tile := {}

	for coord in coords:
		var placed := false
		tile_pool.shuffle()

		for tile in tile_pool:
			if config.rule_set.validate_rules(coord, -1, tile, coords_to_tile, {}):
				coords_to_tile[coord] = tile
				tile_pool.erase(tile)
				placed = true
				break

		if not placed:
			return {}

	return coords_to_tile

static func _assign_numbers(tile_map: Dictionary, coords: Array, config: GenerationConfig, rng: RandomNumberGenerator) -> Dictionary:
	var number_pool := DEFAULT_NUMBER_POOL.duplicate()
	_shuffle_with_rng(number_pool, rng)

	var valid_coords: Array[Vector2i] = []

	for coord in coords:
		if tile_map.has(coord):
			if not TileUtils.is_desert(tile_map[coord]):
				valid_coords.append(coord)

	if number_pool.size() < valid_coords.size():
		return {}

	var coords_to_numbers := {}

	for coord in valid_coords:
		var placed := false
		number_pool.shuffle()

		for number in number_pool:
			var tile = tile_map[coord]

			if config.rule_set.validate_rules(coord, number, tile, tile_map, coords_to_numbers):
				coords_to_numbers[coord] = number
				number_pool.erase(number)
				placed = true
				break

		if not placed:
			return {}

	return coords_to_numbers



#############################################
### RULES
#############################################
static func _has_adjacent_same_tile(tile_map: Dictionary, coord: Vector2i, tile: int) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor := coord + dir
		if tile_map.has(neighbor):
			if tile_map[neighbor] == tile:
				return true
	return false


static func _has_adjacent_same_number(number_map: Dictionary, coord: Vector2i, number: int) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor := coord + dir
		if number_map.has(neighbor):
			if number_map[neighbor] == number:
				return true
	return false


static func _has_adjacent_six_or_eight(number_map: Dictionary, coord: Vector2i) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor := coord + dir
		if number_map.has(neighbor):
			var n = number_map[neighbor]
			if n == 6 or n == 8:
				return true
	return false


static func _has_adjacent_two_or_twelve(number_map: Dictionary, coord: Vector2i) -> bool:
	for dir in HEX_DIRECTIONS:
		var neighbor := coord + dir
		if number_map.has(neighbor):
			var n = number_map[neighbor]
			if n == 2 or n == 12:
				return true
	return false

#############################################
### RANDOMNESS
#############################################
static func _shuffle_with_rng(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
