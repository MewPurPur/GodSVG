extends TextureRect

signal color_picked(color: Color)

const grid_color = Color(0.5, 0.5, 0.5, 0.35)

var color: Color
var ci := get_canvas_item()

func _enter_tree() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	await RenderingServer.frame_post_draw
	texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())


func _exit_tree() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			color_picked.emit(color)
			queue_free()

func _draw() -> void:
	if texture == null:
		return
	
	var pos := get_global_mouse_position()
	var viewport_width := texture.get_width()
	var viewport_height := texture.get_height()
	
	if pos.x < 0 or pos.x >= viewport_width or pos.y < 0 or pos.y >= viewport_height:
		return
	
	# Yes, draw it pixel by pixel.
	var texture_image := texture.get_image()
	for x in range(-7, 8):
		for y in range(-7, 8):
			if Vector2(x, y).length_squared() < 58 and pos.x + x >= 0 and\
			pos.x + x < viewport_width and pos.y + y >= 0 and pos.y + y < viewport_height:
				draw_rect(Rect2(pos + Vector2(x, y) * 7 - Vector2(3, 3), Vector2(7, 7)),
						texture_image.get_pixelv(pos + Vector2(x, y)))
	
	var theme_color := Color(0.9, 0.9, 0.9)
	
	for i in range(-45, 50, 7):
		var offset := sqrt(2604 - i * i)
		draw_line(pos + Vector2(i, -offset), pos + Vector2(i, offset), grid_color)
		draw_line(pos + Vector2(-offset, i), pos + Vector2(offset, i), grid_color)
	draw_circle(pos, 52, theme_color, false, 6.0, true)
	draw_rect(Rect2(pos - Vector2(3, 3), Vector2(7, 7)), Color.WHITE, false, 1.0)
	draw_rect(Rect2(pos - Vector2(4, 4), Vector2(9, 9)), Color.BLACK, false, 1.0)
	
	var stylebox_corner := Vector2(clampf(pos.x - 51, 0.0, viewport_width - 103),
			pos.y + (50 if (pos.y + 75 <= viewport_height) else -75))
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.bg_color = theme_color
	stylebox.draw(ci, Rect2(stylebox_corner, Vector2(103, 25)))
	
	color = texture_image.get_pixelv(pos)
	Configs.savedata.theme_config.mono_font.draw_string(ci,
			stylebox_corner + Vector2(26, 19), "#" + color.to_html(false),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)
	draw_rect(Rect2(stylebox_corner + Vector2(5, 5), Vector2(15, 15)), color)
	var border := Color.WHITE
	if color.get_luminance() > 0.455:
		border = Color.BLACK
	draw_rect(Rect2(stylebox_corner + Vector2(5, 5), Vector2(16, 16)), border, false, 1.0)
