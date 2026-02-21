class_name HexOutline extends Node2D

signal clicked(slot)


var coord : HexAxial
@export var radius := 60.0
@export var border_width := 3.0

var occupied := false

func _ready():
	# optionally highlight when hovered
	set_process_input(true)


func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not occupied:
			occupied = true
			emit_signal("clicked", self)


func _draw():
	var points = []

	for i in 6:
		var angle = deg_to_rad(60 * i - 30) # pointy-top
		points.append(Vector2(
			radius * cos(angle),
			radius * sin(angle)
		))

	draw_polyline(points + [points[0]], Color.WHITE, border_width)


func set_coord(_coord: HexAxial) -> void:
	coord = _coord


func set_radius(_radius: float) -> void:
	radius = _radius
