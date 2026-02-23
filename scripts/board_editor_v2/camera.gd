extends Camera2D

@export var scroll_speed := 1.1
@export var min_zoom := 1.0
@export var max_zoom := 1.5

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if  Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position -= event.relative * zoom * scroll_speed
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			zoom -= Vector2(0.1, 0.1)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			zoom += Vector2(0.1, 0.1)
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
