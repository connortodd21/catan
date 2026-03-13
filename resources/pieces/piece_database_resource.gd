class_name PieceDatabaseResource
extends Resource

@export var piece_data: Array[PieceDataResource]

var _pieces := {}


func _build_if_empty() -> void:
	if _pieces.is_empty():
		for piece in piece_data:
			_pieces[piece.type] = piece


func get_data(type: PieceTypes.Type) -> PieceDataResource:
	_build_if_empty()
	return _pieces[type]


func get_texture(type: PieceTypes.Type) -> Texture2D:
	return get_data(type).texture


func get_placement(type: PieceTypes.Type) -> PlacementType.Type:
	return get_data(type).placement


func get_keys() -> Array:
	_build_if_empty()
	return _pieces.keys()
