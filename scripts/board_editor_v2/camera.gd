extends Camera2D


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if  Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position -= event.relative * zoom
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			zoom -= Vector2(0.1, 0.1)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			zoom += Vector2(0.1, 0.1)
		zoom = zoom.clamp(Vector2(0.5, 0.5), Vector2(2.0, 2.0))
