extends TextureRect

signal color_picked(color: Color)

const GRID_COLOR = Color(0.5, 0.5, 0.5, 0.35)
const PIXEL_SIZE = 7
const FRAME_RADIUS = 50
const FRAME_WIDTH = 5
const KEYBOARD_DELAY_DURATION = 0.5

var color: Color
var ci := get_canvas_item()
var keyboard_offset := Vector2.ZERO
var keyboard_scrolled_time := -1.0


func pick_color() -> void:
	color_picked.emit(color)
	queue_free()


func _enter_tree() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	await RenderingServer.frame_post_draw
	texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	size = get_window().get_visible_rect().size
	
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_accept", pick_color)
	HandlerGUI.register_shortcuts(self, shortcuts)

func _exit_tree() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		keyboard_offset = Vector2.ZERO
		keyboard_scrolled_time = -1.0
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			pick_color()
	elif event is InputEventKey:
		for action_name in ["ui_left", "ui_right", "ui_up", "ui_down"]:
			if event.is_action_pressed(action_name, true, true):
				accept_event()

func _process(delta: float) -> void:
	var vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").round()
	if not vector.is_zero_approx():
		var offset_change := 0
		if keyboard_scrolled_time < 0:
			keyboard_scrolled_time = 0.0
			offset_change = 1
		elif keyboard_scrolled_time <= KEYBOARD_DELAY_DURATION:
			var new_move := false
			if Input.is_action_just_pressed("ui_left"):
				vector = Vector2.LEFT
				new_move = true
			elif Input.is_action_just_pressed("ui_right"):
				vector = Vector2.RIGHT
				new_move = true
			elif Input.is_action_just_pressed("ui_up"):
				vector = Vector2.UP
				new_move = true
			elif Input.is_action_just_pressed("ui_down"):
				vector = Vector2.DOWN
				new_move = true
			
			if new_move:
				keyboard_scrolled_time = 0.0
				offset_change = 1
		else:
			offset_change = clampi(roundi(keyboard_scrolled_time * delta * 200.0), 1, 10)
		keyboard_scrolled_time += delta
		keyboard_offset = (keyboard_offset + vector * offset_change).round()
		var mouse_pos := get_global_mouse_position()
		keyboard_offset = keyboard_offset.clamp(-mouse_pos, size - mouse_pos - Vector2(1, 1))
		queue_redraw()
	elif keyboard_scrolled_time >= 0:
		keyboard_scrolled_time = -1.0

func _draw() -> void:
	if not is_instance_valid(texture):
		return
	
	var pos := get_global_mouse_position() + keyboard_offset
	var texture_pos := pos * get_window().get_final_transform()
	
	if pos.x < 0 or pos.x >= size.x or pos.y < 0 or pos.y >= size.y:
		return
	
	# Yes, draw it pixel by pixel.
	var texture_image := texture.get_image()
	var frsq := FRAME_RADIUS * FRAME_RADIUS
	for x in range(ceili(-FRAME_RADIUS / 7.0), ceili(FRAME_RADIUS / 7.0)):
		for y in range(ceili(-FRAME_RADIUS / 7.0), ceili(FRAME_RADIUS / 7.0)):
			if texture_pos.x + x < 0 or texture_pos.x + x >= texture.get_width() or texture_pos.y + y < 0 or texture_pos.y + y >= texture.get_height():
				continue
			
			var l := (x - 0.5) * PIXEL_SIZE - 0.5
			var r := l + PIXEL_SIZE
			var t := (y - 0.5) * PIXEL_SIZE - 0.5
			var b := t + PIXEL_SIZE
			
			var max_horizontal := maxf(sqrt(frsq - t * t), sqrt(frsq - b * b))
			var max_vertical := maxf(sqrt(frsq - l * l), sqrt(frsq - r * r))
			if is_nan(max_horizontal) and is_nan(max_vertical):
				continue
			
			var left := clampf(pos.x + l, pos.x - max_horizontal, pos.x + max_horizontal)
			var right := clampf(pos.x + r, pos.x - max_horizontal, pos.x + max_horizontal)
			var top := clampf(pos.y + t, pos.y - max_vertical, pos.y + max_vertical)
			var bottom := clampf(pos.y + b, pos.y - max_vertical, pos.y + max_vertical)
			
			if left < right and top < bottom:
				draw_rect(Rect2(Vector2(left, top), Vector2(right - left, bottom - top)), texture_image.get_pixelv(texture_pos + Vector2(x, y)))
	
	var grid_points := PackedVector2Array()
	for i in range(ceili(-FRAME_RADIUS / 7.0), ceili(FRAME_RADIUS / 7.0)):
		var grid_coord := (i - 0.5) * PIXEL_SIZE - 0.5
		var offset := sqrt((FRAME_RADIUS + 1) ** 2 - grid_coord * grid_coord)
		grid_points.append(pos + Vector2(grid_coord, -offset))
		grid_points.append(pos + Vector2(grid_coord, offset))
		grid_points.append(pos + Vector2(-offset, grid_coord))
		grid_points.append(pos + Vector2(offset, grid_coord))
	draw_multiline(grid_points, GRID_COLOR)
	
	var theme_color := Color(0.9, 0.9, 0.9)
	
	draw_circle(pos, FRAME_RADIUS + FRAME_WIDTH / 2.0, theme_color, false, FRAME_WIDTH, true)
	draw_rect(Rect2(pos - Vector2(1, 1) * (PIXEL_SIZE / 2.0 + 0.5), Vector2(1, 1) * PIXEL_SIZE), Color.WHITE, false, 1.0)
	draw_rect(Rect2(pos - Vector2(1, 1) * (PIXEL_SIZE / 2.0 + 1.5), Vector2(1, 1) * (PIXEL_SIZE + 2)), Color.BLACK, false, 1.0)
	
	var stylebox_width := FRAME_RADIUS * 2
	var stylebox_height := 25
	var stylebox_vertical_offset := FRAME_RADIUS
	var stylebox_corner := Vector2(clampf(pos.x - FRAME_RADIUS, 0.0, size.x - stylebox_width), pos.y + (stylebox_vertical_offset if\
			(pos.y + stylebox_vertical_offset + stylebox_height <= size.y) else -stylebox_vertical_offset - stylebox_height))
	
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.bg_color = theme_color
	stylebox.draw(ci, Rect2(stylebox_corner, Vector2(stylebox_width, stylebox_height)))
	
	color = texture_image.get_pixelv(texture_pos)
	ThemeUtils.mono_font.draw_string(ci, stylebox_corner + Vector2(26, 19), "#" + color.to_html(false), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)
	draw_rect(Rect2(stylebox_corner + Vector2(5, 5), Vector2(15, 15)), color)
	var border := Color.WHITE
	if color.get_luminance() > 0.455:
		border = Color.BLACK
	draw_rect(Rect2(stylebox_corner + Vector2(5, 5), Vector2(16, 16)), border, false, 1.0)
