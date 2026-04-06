class_name BoardRenderer
extends RefCounted

var _board_view: Node2D
var _board_tile_map: TileMapLayer
var _piece_sprites: Dictionary[Vector2i, Sprite2D] = {}
var _robber_sprite: Sprite2D = null


func _init(board_view: Node2D, board_tile_map: TileMapLayer) -> void:
	_board_view = board_view
	_board_tile_map = board_tile_map


func place_piece(texture: Texture2D, pos: Vector2, color: Color, rotation_deg: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.rotation_degrees = rotation_deg
	sprite.position = pos
	sprite.modulate = color
	sprite.z_index = 2
	_board_view.add_child(sprite)
	_piece_sprites[_to_key(pos)] = sprite


func remove_piece_at(pos: Vector2) -> void:
	var key := _to_key(pos)
	if key in _piece_sprites:
		_piece_sprites[key].queue_free()
		_piece_sprites.erase(key)


func place_robber(texture: Texture2D, pos: Vector2, offset: Vector2) -> void:
	_robber_sprite = Sprite2D.new()
	_robber_sprite.texture = texture
	_robber_sprite.position = pos + offset
	_robber_sprite.modulate = Color.BLACK
	_robber_sprite.z_index = 2
	_board_view.add_child(_robber_sprite)


func move_robber_to(pos: Vector2, offset: Vector2) -> void:
	if _robber_sprite:
		_robber_sprite.position = pos + offset


func get_nearest_hex_coord(mouse_pos: Vector2, tile_coords: Array[Vector2i]) -> Vector2i:
	var nearest_coord := Vector2i(-999, -999)
	var nearest_dist := INF
	for coord: Vector2i in tile_coords:
		var hex_center := _board_tile_map.map_to_local(HexUtils.axial_to_offset(coord))
		var dist := mouse_pos.distance_to(hex_center)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_coord = coord
	return nearest_coord


func _to_key(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x), roundi(pos.y))
