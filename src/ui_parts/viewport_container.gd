extends SubViewportContainer

var last_pos: Vector2
var wrapped: bool

func wrap_mouse(already_moved: bool) -> Vector2:
	if not already_moved:
		last_pos = DisplayServer.mouse_get_position()
	var view_rect := get_global_rect()
	view_rect.position += Vector2(get_window().get_position())
	print(view_rect)
	var mouse_pos: Vector2 = DisplayServer.mouse_get_position()
	if not view_rect.has_point(mouse_pos):
		if mouse_pos.x < view_rect.position.x:
			print("too left")
			mouse_pos.x = view_rect.position.x + view_rect.size.x
		if mouse_pos.x > (view_rect.position.x + view_rect.size.x):
			print("too right")
			mouse_pos.x = view_rect.position.x
		if mouse_pos.y < view_rect.position.y:
			print("too up")
			mouse_pos.y = view_rect.position.y + view_rect.size.y
		if mouse_pos.y >  view_rect.position.y + view_rect.size.y:
			print("too down")
			mouse_pos.y = view_rect.position.y
		wrapped = true
	var win_pos: Vector2 = get_window().get_position() # probably the global cords window position
	DisplayServer.warp_mouse(mouse_pos - win_pos) # adds window position by default
	var relative: Vector2 = mouse_pos - last_pos
	last_pos = DisplayServer.mouse_get_position()
	if not wrapped:
		return relative
	else:
		wrapped = false
		return Vector2(0,0)
