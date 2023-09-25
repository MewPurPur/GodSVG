extends TextureRect

var handles: Array[Handle]

func _ready() -> void:
	SVG.data.resized.connect(full_update)
	SVG.data.attribute_changed.connect(sync_handles)
	SVG.data.tag_added.connect(full_update)
	SVG.data.tag_deleted.connect(full_update)
	SVG.data.changed_unknown.connect(full_update)

func full_update() -> void:
	# Draw a SVG out of the shapes
	var w := SVG.data.w
	var h := SVG.data.h
	var svg := '<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}"'.format(
			{"w": w, "h": h})
	svg += ' xmlns="http://www.w3.org/2000/svg">'
	for tag in SVG.data.tags:
		if tag is SVGTagPath:
			svg += '<path d="{d}" fill="none" stroke="gray" stroke-width=".1"/>'.format(
					{"d": tag.attributes.d.value})
	svg += "</svg>"
	# Store the SVG string.
	var img := Image.new()
	img.load_svg_from_string(svg, 128.0)
	# Update the display.
	var image_texture := ImageTexture.create_from_image(img)
	texture = image_texture
	update_handles()

func update_handles() -> void:
	handles.clear()
	for tag in SVG.data.tags:
		if tag is SVGTagCircle:
			var handle := Handle.new(tag.attributes.cx, tag.attributes.cy)
			handles.append(handle)
		if tag is SVGTagEllipse:
			var handle := Handle.new(tag.attributes.cx, tag.attributes.cy)
			handles.append(handle)
		if tag is SVGTagRect:
			var handle := Handle.new(tag.attributes.x, tag.attributes.y)
			handles.append(handle)

func sync_handles():
	for handle in handles:
		handle.sync()
		queue_redraw()

func _draw() -> void:
	for handle in handles:
		if handle.dragged:
			draw_circle(coords_to_canvas(handle.pos), 3, Color(0.55, 0.55, 1.0))
		elif handle.hovered:
			draw_circle(coords_to_canvas(handle.pos), 3, Color(0.7, 0.7, 0.7))
		else:
			draw_circle(coords_to_canvas(handle.pos), 3, Color(0.45, 0.45, 0.45))

func coords_to_canvas(pos: Vector2) -> Vector2:
	return size / 16 * pos

func canvas_to_coords(pos: Vector2) -> Vector2:
	return pos * 16 / size


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		for handle in handles:
			if handle.dragged:
				var old_pos := handle.pos
				handle.set_pos(canvas_to_coords(event.position))
				if old_pos.x != handle.pos.x:
					handle.moved_x.emit(handle.pos.x)
				if old_pos.y != handle.pos.y:
					handle.moved_y.emit(handle.pos.y)
				accept_event()
		var picked_hover := false
		for handle in handles:
			if not picked_hover and event.position.distance_squared_to(
			coords_to_canvas(handle.pos)) < 25:
				handle.hovered = true
				picked_hover = true
			if picked_hover and handle.hovered:
				handle.hovered = false
			if handle.hovered != (event.position.distance_squared_to(
			coords_to_canvas(handle.pos)) < 25):
				handle.hovered = not handle.hovered
			queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			for handle in handles:
				if handle.hovered:
					handle.dragged = true
					queue_redraw()
		else:
			for handle in handles:
				if handle.dragged:
					handle.dragged = false
					queue_redraw()

func pos_to_cx_and_cy(pos: Vector2, tag: SVGTag) -> void:
	tag.attributes.cx.value = pos.x
	tag.attributes.cy.value = pos.y
