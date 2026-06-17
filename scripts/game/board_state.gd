class_name BoardState
extends RefCounted

var coord_to_terrain: Dictionary[Vector2i, TerrainTypes.Type] = {}
var number_to_coords: Dictionary = {}  # int -> Array[Vector2i]
var vertex_ownership: Dictionary[Vector2i, Dictionary] = {}
var edge_ownership: Dictionary[Vector2i, Dictionary] = {}

## Maps each vertex key to its directly adjacent vertex keys (shares an edge).
## Used for the distance rule: no two settlements can be on adjacent vertices.
var _vertex_adjacency: Dictionary[Vector2i, Array] = {}

## Maps each vertex key to the edge keys that connect to it.
## Used to check road connectivity when placing settlements.
var _vertex_to_edges: Dictionary[Vector2i, Array] = {}

## Maps each edge key to its two endpoint vertex keys.
## Used to check what vertices a road connects.
var _edge_to_vertices: Dictionary[Vector2i, Array] = {}

## Maps each vertex key to the axial coords of tiles that share it.
## Used to look up terrain types when collecting initial resources.
var _vertex_to_coords: Dictionary[Vector2i, Array] = {}

## Maps each port-adjacent vertex key to its port type.
## Used for trade rates and harbormaster.
var _vertex_to_port: Dictionary[Vector2i, PortTypes.Type] = {}


func build(board: SerializedBoard, board_tile_map: TileMapLayer) -> void:
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

	_build_graph(board, board_tile_map)
	_build_ports(board, board_tile_map)


func _build_graph(board: SerializedBoard, board_tile_map: TileMapLayer) -> void:
	for tile: TileEntry in board.tiles:
		var coord := Vector2i(tile.x, tile.y)

		# 1. Compute hex center and derive vertex/edge world position keys
		var hex_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))

		# 2. Compute the 6 vertex keys and 6 edge midpoint keys for this hex
		var vertex_keys: Array[Vector2i] = []
		for offset in HexUtils.VERTEX_OFFSETS:
			vertex_keys.append(_to_key(hex_center + offset))

		for vertex_key in vertex_keys:
			if vertex_key not in _vertex_to_coords:
				_vertex_to_coords[vertex_key] = []
			_vertex_to_coords[vertex_key].append(coord)

		var edge_keys: Array[Vector2i] = []
		for midpoint in HexUtils.EDGE_MIDPOINTS:
			edge_keys.append(_to_key(hex_center + midpoint))

		# 3. Edge i connects vertex[i] and vertex[(i+1)%6] — populate all three graph structures
		for i in 6:
			var left_vertex := vertex_keys[i]
			var right_vertex := vertex_keys[(i + 1) % 6]
			var edge := edge_keys[i]

			if left_vertex not in _vertex_adjacency:
				_vertex_adjacency[left_vertex] = []
			if right_vertex not in _vertex_adjacency[left_vertex]:
				_vertex_adjacency[left_vertex].append(right_vertex)

			if right_vertex not in _vertex_adjacency:
				_vertex_adjacency[right_vertex] = []
			if left_vertex not in _vertex_adjacency[right_vertex]:
				_vertex_adjacency[right_vertex].append(left_vertex)

			if left_vertex not in _vertex_to_edges:
				_vertex_to_edges[left_vertex] = []
			if edge not in _vertex_to_edges[left_vertex]:
				_vertex_to_edges[left_vertex].append(edge)

			if right_vertex not in _vertex_to_edges:
				_vertex_to_edges[right_vertex] = []
			if edge not in _vertex_to_edges[right_vertex]:
				_vertex_to_edges[right_vertex].append(edge)

			if edge not in _edge_to_vertices:
				_edge_to_vertices[edge] = [left_vertex, right_vertex]


func _build_ports(board: SerializedBoard, board_tile_map: TileMapLayer) -> void:
	for port: PortEntry in board.ports:
		var water_center := board_tile_map.map_to_local(HexUtils.axial_to_offset(Vector2i(port.x, port.y)))
		var vertex1 := _to_key(water_center + HexUtils.VERTEX_OFFSETS[(port.direction + 1) % 6])
		var vertex2 := _to_key(water_center + HexUtils.VERTEX_OFFSETS[(port.direction + 2) % 6])
		_vertex_to_port[vertex1] = port.type
		_vertex_to_port[vertex2] = port.type


#############################################
### QUERIES
#############################################
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


func get_terrain_at_vertex(world_pos: Vector2) -> Array[TerrainTypes.Type]:
	var result: Array[TerrainTypes.Type] = []
	for coord: Vector2i in _vertex_to_coords.get(_to_key(world_pos), []):
		result.append(coord_to_terrain.get(coord, TerrainTypes.Type.UNKNOWN))
	return result


func is_edge_adjacent_to_vertex(edge_pos: Vector2, vertex_pos: Vector2) -> bool:
	var edge_key := _to_key(edge_pos)
	var vertex_key := _to_key(vertex_pos)
	return vertex_key in _edge_to_vertices.get(edge_key, [])


func get_vertex_owner(world_pos: Vector2) -> Dictionary:
	return vertex_ownership.get(_to_key(world_pos), {})


func get_edge_owner(world_pos: Vector2) -> Dictionary:
	return edge_ownership.get(_to_key(world_pos), {})


#############################################
### ROBBER
#############################################
func get_players_on_hex_vertex(coord: Vector2i, current_player_index: int) -> Array[int]:
	var indices: Array[int] = []
	for vertex_key: Vector2i in vertex_ownership:
		if coord not in _vertex_to_coords.get(vertex_key, []):
			continue
		var owner: Dictionary = vertex_ownership[vertex_key]
		if owner.player_index != current_player_index and owner.player_index not in indices:
			indices.append(owner.player_index)
	return indices


#############################################
### PLACEMENT
#############################################
func record_placement(piece_type: PieceTypes.Type, world_pos: Vector2, player_index: int) -> void:
	var key := _to_key(world_pos)
	var entry := {player_index = player_index, piece_type = piece_type}
	if piece_type == PieceTypes.Type.ROAD:
		edge_ownership[key] = entry
	else:
		vertex_ownership[key] = entry


#############################################
### PLACEMENT AVAILABILITY
#############################################
func player_has_valid_settlement_placement(_player_index: int, require_road_connection: bool = false) -> bool:
	for vertex_key in _vertex_adjacency:
		if can_place_settlement(Vector2(vertex_key), _player_index, require_road_connection):
			return true
	return false


func has_valid_road_placement(player_index: int) -> bool:
	for edge_key in _edge_to_vertices:
		if can_place_road(Vector2(edge_key), player_index):
			return true
	return false


func has_valid_city_placement(player_index: int) -> bool:
	for vertex_key in vertex_ownership:
		var owner: Dictionary = vertex_ownership[vertex_key]
		if owner.player_index == player_index and owner.piece_type == PieceTypes.Type.SETTLEMENT:
			return true
	return false


func can_place_settlement(world_pos: Vector2, player_index: int, require_road_connection: bool = false) -> bool:
	var key := _to_key(world_pos)
	if key in vertex_ownership:
		return false
	for adj in _vertex_adjacency.get(key, []):
		if adj in vertex_ownership:
			return false
	if require_road_connection and not _has_adjacent_road(key, player_index):
		return false
	return true


func _has_adjacent_road(vertex_key: Vector2i, player_index: int) -> bool:
	for edge in _vertex_to_edges.get(vertex_key, []):
		var owner: Dictionary = edge_ownership.get(edge, {})
		if not owner.is_empty() and owner.player_index == player_index:
			return true
	return false


func can_place_road(world_pos: Vector2, player_index: int) -> bool:
	var key := _to_key(world_pos)
	if key in edge_ownership:
		return false
	for vertex_key in _edge_to_vertices.get(key, []):
		var vertex_owner: Dictionary = vertex_ownership.get(vertex_key, {})
		if not vertex_owner.is_empty() and vertex_owner.player_index == player_index:
			return true
		if not vertex_owner.is_empty() and vertex_owner.player_index != player_index:
			continue
		for adj_edge in _vertex_to_edges.get(vertex_key, []):
			if adj_edge == key:
				continue
			var edge_owner: Dictionary = edge_ownership.get(adj_edge, {})
			if not edge_owner.is_empty() and edge_owner.player_index == player_index:
				return true
	return false


func can_place_city(world_pos: Vector2, player_index: int) -> bool:
	var key := _to_key(world_pos)
	var owner: Dictionary = vertex_ownership.get(key, {})
	return not owner.is_empty() and owner.player_index == player_index and owner.piece_type == PieceTypes.Type.SETTLEMENT


#############################################
### SPECIAL TITLE CHECKS
### TODO: optimize with DP and early exits
#############################################
func calculate_longest_road(player_index: int) -> int:
	var max_length := 0
	for vertex: Vector2i in _vertex_to_edges:
		var has_player_road := false
		for edge: Vector2i in _vertex_to_edges[vertex]:
			var owner: Dictionary = edge_ownership.get(edge, {})
			if not owner.is_empty() and owner.player_index == player_index:
				has_player_road = true
				break
		if not has_player_road:
			continue
		max_length = max(max_length, _dfs_road(vertex, {}, player_index))
	return max_length


func calculate_harbormaster_count(_player_index: int) -> int:
	return 0 # TODO: implement when port tracking is added


func _dfs_road(vertex: Vector2i, visited: Dictionary, player_index: int) -> int:
	# Opponent's settlement or city on this vertex breaks road continuity
	var vertex_owner: Dictionary = vertex_ownership.get(vertex, {})
	if not vertex_owner.is_empty() and vertex_owner.player_index != player_index:
		return 0
	var best := 0
	for edge: Vector2i in _vertex_to_edges.get(vertex, []):
		if edge in visited:
			continue
		var edge_owner: Dictionary = edge_ownership.get(edge, {})
		if edge_owner.is_empty() or edge_owner.player_index != player_index:
			continue
		var endpoints: Array = _edge_to_vertices[edge]
		var next: Vector2i = endpoints[0] if endpoints[1] == vertex else endpoints[1]
		visited[edge] = true
		best = max(best, 1 + _dfs_road(next, visited, player_index))
		visited.erase(edge)
	return best


func _get_all_road_player_indices() -> Array[int]:
	var indices: Array[int] = []
	for entry: Dictionary in edge_ownership.values():
		if entry.player_index not in indices:
			indices.append(entry.player_index)
	return indices


#############################################
### HARBORS
#############################################
func get_bank_trade_rates_for_player(player_index: int) -> Dictionary[ResourceTypes.Type, int]:
	var rates: Dictionary[ResourceTypes.Type, int] = {}
	for resource_type: ResourceTypes.Type in ResourceTypes.DISPLAY_ORDER:
		rates[resource_type] = 4

	for vertex_key: Vector2i in vertex_ownership:
		var owner: Dictionary = vertex_ownership[vertex_key]
		if owner.player_index == player_index and vertex_key in _vertex_to_port:
			var port_type: PortTypes.Type = _vertex_to_port[vertex_key]
			var port_rate: int = PortTypes.get_trade_rate(port_type)
			# Generic ports lower the rate for all resources; specific ports lower only their resource
			if port_type == PortTypes.Type.GENERIC:
				for resource_type: ResourceTypes.Type in rates:
					rates[resource_type] = min(rates[resource_type], port_rate)
			else:
				var resource := PortTypes.to_resource(port_type)
				if resource != ResourceTypes.Type.UNKNOWN:
					rates[resource] = min(rates[resource], port_rate)

	return rates


#############################################
### INTERNAL
#############################################
func _to_key(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x), roundi(world_pos.y))
