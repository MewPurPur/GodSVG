extends TextureRect

signal dropped_handle

var handles: Array[Handle]

func update_handles() -> void:
	handles.clear()
	for tag_idx in SVG.data.tags.size():
		var tag := SVG.data.tags[tag_idx]
		if tag is SVGTagCircle:
			var handle := Handle.new(Vector2(tag.attributes.cx.value, tag.attributes.cy.value),
					tag, pos_to_cx_and_cy)
			handles.append(handle)
			var tag_editor: Control = SVG.interface.shapes.get_child(tag_idx)
			var input_fields: Array[Node] = tag_editor.shape_container.get_children()
			for input_field in input_fields:
				if input_field.attribute_name == "cx":
					input_field.associated_handle = handle
					input_field.bind_to_handle_x()
				if input_field.attribute_name == "cy":
					input_field.associated_handle = handle
					input_field.bind_to_handle_x()
		if tag is SVGTagEllipse:
			var handle := Handle.new(Vector2(tag.attributes.cx.value, tag.attributes.cy.value),
					tag, pos_to_cx_and_cy)
			handles.append(handle)
			var tag_editor: Control = SVG.interface.shapes.get_child(tag_idx)
			var input_fields: Array[Node] = tag_editor.shape_container.get_children()
			for input_field in input_fields:
				if input_field.attribute_name == "cx":
					input_field.associated_handle = handle
					input_field.bind_to_handle_x()
				if input_field.attribute_name == "cy":
					input_field.associated_handle = handle
					input_field.bind_to_handle_x()

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
					dropped_handle.emit()

func pos_to_cx_and_cy(pos: Vector2, tag: SVGTag) -> void:
	tag.attributes.cx.value = pos.x
	tag.attributes.cy.value = pos.y
