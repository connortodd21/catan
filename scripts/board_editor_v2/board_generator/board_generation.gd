class_name BoardGenerator

const center : Vector2i = Vector2i(6,4)

const HEX_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

const DEFAULT_COUNTS := {
	2: 1,
	3: 2,
	4: 2,
	5: 2,
	6: 2,
	8: 2,
	9: 2,
	10: 2,
	#11: 2,
	#12: 1
}

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
			coords.append(Vector2i(q, r) + center)

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
	var valid_coords: Array[Vector2i] = []

	for coord in coords:
		if tile_map.has(coord):
			if not TileUtils.is_desert(tile_map[coord]):
				valid_coords.append(coord)

	var number_pool = build_number_pool(valid_coords.size(), rng)
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
### HELPERS
#############################################
static func build_number_pool(tile_count: int, rng: RandomNumberGenerator) -> Array:
	# 1. Total numbers in standard Catan
	var total_standard := 18  # sum of all counts in DEFAULT_COUNTS
	var pool := []

	for number in DEFAULT_COUNTS.keys():
		var proportion := float(DEFAULT_COUNTS[number]) / total_standard
		var scaled_count = round(proportion * tile_count)
		for i in range(scaled_count):
			pool.append(number)

	# Fix rounding: add/remove numbers to match tile_count exactly
	while pool.size() < tile_count:
		# pick a number randomly weighted by original distribution
		var weights := []
		for n in DEFAULT_COUNTS.keys():
			weights.append(DEFAULT_COUNTS[n])
		var r := randi() % int(ArrayUtils.sum_array(weights))
		var cum := 0
		for idx in range(weights.size()):
			cum += weights[idx]
			if r < cum:
				pool.append(DEFAULT_COUNTS.keys()[idx])
				break

	while pool.size() > tile_count:
		pool.pop_back()

	_shuffle_with_rng(pool, rng)
	return pool

#############################################
### RANDOMNESS
#############################################
static func _shuffle_with_rng(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
