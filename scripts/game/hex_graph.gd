class_name HexGraph


class VertexData:
	var id: String = ""
	var adjacent_hexes: Array[Vector2i] = []
	var adjacent_vertex_ids: Array[String] = []
	var adjacent_edge_ids: Array[String] = []


class EdgeData:
	var id: String = ""
	var vertex_ids: Array[String] = []
	var adjacent_hex_coords: Array[Vector2i] = []


var vertices: Dictionary = {}           # vertex_id → VertexData
var edges: Dictionary = {}              # edge_id → EdgeData
var hex_to_vertex_ids: Dictionary = {}  # Vector2i → Array[String] (6 vertex ids, in direction order)
var land_hexes: Dictionary = {}         # Vector2i → TerrainTypes.Type


static func build(board: SerializedBoard, water_coords: Array[Vector2i]) -> HexGraph:
	var graph := HexGraph.new()

	for tile_entry in board.tiles:
		graph.land_hexes[Vector2i(tile_entry.x, tile_entry.y)] = tile_entry.type

	var all_coords: Array[Vector2i] = []
	for tile_entry in board.tiles:
		all_coords.append(Vector2i(tile_entry.x, tile_entry.y))
	for coord in water_coords:
		all_coords.append(coord)

	# Pass 1: create all vertices and map each hex to its 6 vertex ids
	for h in all_coords:
		var vertex_ids_for_hex: Array[String] = []
		for v in range(6):
			var vkey = _vertex_key(h, h + HexConstants.HEX_DIRECTIONS[v], h + HexConstants.HEX_DIRECTIONS[(v + 1) % 6])
			if not graph.vertices.has(vkey):
				var vdata := VertexData.new()
				vdata.id = vkey
				graph.vertices[vkey] = vdata
			var vdata: VertexData = graph.vertices[vkey]
			if not h in vdata.adjacent_hexes:
				vdata.adjacent_hexes.append(h)
			vertex_ids_for_hex.append(vkey)
		graph.hex_to_vertex_ids[h] = vertex_ids_for_hex

	# Pass 2: create edges between adjacent vertices of each hex
	for h in all_coords:
		var v_ids: Array = graph.hex_to_vertex_ids[h]
		for v in range(6):
			var vid0: String = v_ids[v]
			var vid1: String = v_ids[(v + 1) % 6]
			var ekey := _edge_key(vid0, vid1)

			if not graph.edges.has(ekey):
				var edata := EdgeData.new()
				edata.id = ekey
				edata.vertex_ids.assign([vid0, vid1])
				graph.edges[ekey] = edata

			var edata: EdgeData = graph.edges[ekey]
			if not h in edata.adjacent_hex_coords:
				edata.adjacent_hex_coords.append(h)

			var vdata0: VertexData = graph.vertices[vid0]
			var vdata1: VertexData = graph.vertices[vid1]
			if not vid1 in vdata0.adjacent_vertex_ids:
				vdata0.adjacent_vertex_ids.append(vid1)
			if not vid0 in vdata1.adjacent_vertex_ids:
				vdata1.adjacent_vertex_ids.append(vid0)
			if not ekey in vdata0.adjacent_edge_ids:
				vdata0.adjacent_edge_ids.append(ekey)
			if not ekey in vdata1.adjacent_edge_ids:
				vdata1.adjacent_edge_ids.append(ekey)

	return graph


static func _vertex_key(a: Vector2i, b: Vector2i, c: Vector2i) -> String:
	var coords := [a, b, c]
	coords.sort_custom(func(x: Vector2i, y: Vector2i) -> bool:
		return x.x < y.x or (x.x == y.x and x.y < y.y)
	)
	return "%d,%d|%d,%d|%d,%d" % [
		coords[0].x, coords[0].y,
		coords[1].x, coords[1].y,
		coords[2].x, coords[2].y,
	]


static func _edge_key(v1: String, v2: String) -> String:
	if v1 < v2:
		return v1 + "||" + v2
	return v2 + "||" + v1
