class_name BoardState
extends RefCounted

var coord_to_terrain: Dictionary[Vector2i, TerrainTypes.Type] = {}
var number_to_coords: Dictionary = {}  # int -> Array[Vector2i]
var vertex_ownership: Dictionary[Vector2i, Dictionary] = {}
var edge_ownership: Dictionary[Vector2i, Dictionary] = {}


func build(board: SerializedBoard) -> void:
	for tile: TileEntry in board.tiles:
		coord_to_terrain[Vector2i(tile.x, tile.y)] = tile.type

	for entry: NumberEntry in board.numbers:
		if entry.value.is_empty():
			continue
		var number: int = entry.value[0]
		var coord := Vector2i(entry.x, entry.y)
		if number not in number_to_coords:
			number_to_coords[number] = []
		number_to_coords[number].append(coord)


func has_number(number: int) -> bool:
	return number in number_to_coords


func get_coords_for_number(number: int) -> Array[Vector2i]:
	if number not in number_to_coords:
		return []
	var coords: Array[Vector2i] = []
	coords.assign(number_to_coords.get(number))
	return coords


func get_terrain(coord: Vector2i) -> TerrainTypes.Type:
	return coord_to_terrain.get(coord, TerrainTypes.Type.UNKNOWN)


func record_placement(piece_type: PieceTypes.Type, world_pos: Vector2, player_index: int) -> void:
	var key := _to_key(world_pos)
	var entry := {player_index = player_index, piece_type = piece_type}
	if piece_type == PieceTypes.Type.ROAD:
		edge_ownership[key] = entry
	else:
		vertex_ownership[key] = entry


func get_vertex_owner(world_pos: Vector2) -> Dictionary:
	return vertex_ownership.get(_to_key(world_pos), {})


func get_edge_owner(world_pos: Vector2) -> Dictionary:
	return edge_ownership.get(_to_key(world_pos), {})


func _to_key(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x), roundi(world_pos.y))
