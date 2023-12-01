extends SubViewportContainer

var last_pos: Vector2
var wrapped: bool

func wrap_mouse(already_moved: bool) -> Vector2:
	if not already_moved:
		last_pos = DisplayServer.mouse_get_position()
	
	var view_rect := get_global_rect()
	var mouse_pos: Vector2 = DisplayServer.mouse_get_position()
	view_rect.position += Vector2(get_window().get_position())
	if not view_rect.has_point(mouse_pos):
		mouse_pos.x = fposmod(mouse_pos.x - view_rect.position.x, view_rect.size.x) + view_rect.position.x
		mouse_pos.y = fposmod(mouse_pos.y - view_rect.position.y, view_rect.size.y) + view_rect.position.y
		wrapped = true
	var win_pos: Vector2 = get_window().get_position()
	DisplayServer.warp_mouse(mouse_pos - win_pos)
	
	var relative: Vector2 = mouse_pos - last_pos
	last_pos = DisplayServer.mouse_get_position()
	
	if not wrapped:
		return relative
	else:
		wrapped = false
		return mouse_pos - last_pos
