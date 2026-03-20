class_name Die
extends TextureRect

@export var dice: Dice


func _ready() -> void:
	if dice:
		modulate = dice.color
		if not dice.sides.is_empty():
			show_face(0)


func show_face(index: int) -> void:
	if dice and index < dice.sides.size():
		texture = dice.sides[index].texture


func show_random_face() -> void:
	if dice and not dice.sides.is_empty():
		show_face(randi() % dice.sides.size())
