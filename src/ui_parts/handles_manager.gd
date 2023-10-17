extends TextureRect

const selection_color_string = "#46f"
const hover_color_string = "#999"
const default_color_string = "#000"

var zoom := 1.0:
	set(new_value):
		zoom = new_value
		queue_update_texture()
		queue_redraw()

var snap_enabled := false
var snap_size := Vector2(0.1, 0.1)

var texture_update_pending := false
var handles_update_pending := false

var handles: Array[Handle]

func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(queue_full_update)
	SVG.root_tag.child_tag_attribute_changed.connect(queue_update_texture)
	SVG.root_tag.child_tag_attribute_changed.connect(sync_handles)
	SVG.root_tag.tag_added.connect(queue_full_update)
	SVG.root_tag.tag_deleted.connect(queue_full_update.unbind(1))
	SVG.root_tag.tag_moved.connect(queue_full_update.unbind(2))
	SVG.root_tag.changed_unknown.connect(queue_full_update)
	Interactions.selection_changed.connect(queue_redraw)
	Interactions.selection_changed.connect(update_texture)
	Interactions.hover_changed.connect(queue_redraw)
	Interactions.hover_changed.connect(update_texture)
	queue_full_update()


func queue_full_update() -> void:
	queue_update_texture()
	queue_update_handles()

func queue_update_texture() -> void:
	texture_update_pending = true

func queue_update_handles() -> void:
	handles_update_pending = true

func _process(_delta: float) -> void:
	if texture_update_pending:
		update_texture()
		texture_update_pending = false
	if handles_update_pending:
		update_handles()
		handles_update_pending = false


func update_texture() -> void:
	# Draw a SVG out of the shapes.
	var w: float = SVG.root_tag.attributes.width.value
	var h: float = SVG.root_tag.attributes.height.value
	var viewbox: Rect2 = SVG.root_tag.attributes.viewBox.value
	var svg := '<svg width="%f" height="%f" viewBox="%s"' % [w, h,
			AttributeRect.rect_to_string(viewbox)]
	svg += ' xmlns="http://www.w3.org/2000/svg">'
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var attribs := tag.attributes
		match tag.title:
			"circle": svg += '<circle cx="%f" cy="%f" r="%f"' % [attribs.cx.value,
					attribs.cy.value, attribs.r.value]
			"ellipse": svg += '<ellipse cx="%f" cy="%f" rx="%f" ry="%f"' % [attribs.cx.value,
					attribs.cy.value, attribs.rx.value, attribs.ry.value]
			"rect": svg += '<rect x="%f" y="%f" width="%f" height="%f" rx="%f" ry="%f"' %\
					[attribs.x.value, attribs.y.value, attribs.width.value,
					attribs.height.value, attribs.rx.value, attribs.ry.value]
			"path": svg += '<path d="%s"' % [attribs.d.value]
			"line": svg += '<line x1="%f" y1="%f" x2="%f" y2="%f"' % [attribs.x1.value,
					attribs.y1.value, attribs.x2.value, attribs.y2.value]
		svg += ' fill="none" stroke="%s" stroke-width="%f"/>' % [selection_color_string\
				if tag_idx in Interactions.selected_tags else hover_color_string if\
				tag_idx == Interactions.hovered_tag else default_color_string,
				2.0 / zoom / get_viewbox_zoom()]
	svg += "</svg>"
	# Store the SVG string.
	var img := Image.new()
	img.load_svg_from_string(svg, 4.0 * zoom)
	# Update the display.
	var image_texture := ImageTexture.create_from_image(img)
	texture = image_texture

func update_handles() -> void:
	handles.clear()
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var new_handles: Array[Handle] = []
		if tag is TagCircle:
			new_handles.append(XYHandle.new(tag.attributes.cx, tag.attributes.cy))
		if tag is TagEllipse:
			new_handles.append(XYHandle.new(tag.attributes.cx, tag.attributes.cy))
		if tag is TagRect:
			new_handles.append(XYHandle.new(tag.attributes.x, tag.attributes.y))
		if tag is TagLine:
			new_handles.append(XYHandle.new(tag.attributes.x1, tag.attributes.y1))
			new_handles.append(XYHandle.new(tag.attributes.x2, tag.attributes.y2))
		if tag is TagPath:
			var path_attribute: AttributePath = tag.attributes.d
			for idx in path_attribute.get_command_count():
				if not path_attribute.get_command(idx) is PathCommand.CloseCommand:
					new_handles.append(PathHandle.new(path_attribute, idx))
		for handle in new_handles:
			handle.tag = tag
			handle.tag_index = tag_idx
		handles += new_handles

func sync_handles() -> void:
	# For XYHandles, sync them. For path handles, sync all but the one being dragged.
	for handle_idx in range(handles.size() - 1, -1, -1):
		var handle := handles[handle_idx]
		if handle is XYHandle:
			handle.sync()
		elif handle is PathHandle and dragged_handle != handle:
			handles.remove_at(handle_idx)
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		if tag is TagPath:
			var path_attribute: AttributePath = tag.attributes.d
			for idx in path_attribute.get_command_count():
				if not path_attribute.get_command(idx) is PathCommand.CloseCommand:
					var handle := PathHandle.new(path_attribute, idx)
					handle.tag_index = tag_idx
					handles.append(handle)
	queue_redraw()

func _draw() -> void:
	for handle in handles:
		var outer_circle_color: Color
		if handle.tag_index in Interactions.selected_tags:
			outer_circle_color = Color.from_string(selection_color_string, Color(0, 0, 0))
		elif Interactions.hovered_tag == handle.tag_index:
			outer_circle_color = Color.from_string(hover_color_string, Color(0, 0, 0))
		else:
			outer_circle_color = Color.from_string(default_color_string, Color(0, 0, 0))
		draw_circle(coords_to_canvas(handle.pos), 4 / zoom, outer_circle_color)
		draw_circle(coords_to_canvas(handle.pos), 2.25 / zoom, Color.WHITE)


func get_viewbox_zoom() -> float:
	var width: float = SVG.root_tag.attributes.width.value
	var height: float = SVG.root_tag.attributes.height.value
	var viewbox_size: Vector2 = SVG.root_tag.attributes.viewBox.value.size
	return minf(width / viewbox_size.x, height / viewbox_size.y)

func coords_to_canvas(pos: Vector2) -> Vector2:
	var width: float = SVG.root_tag.attributes.width.value
	var height: float = SVG.root_tag.attributes.height.value
	var viewbox: Rect2 = SVG.root_tag.attributes.viewBox.value
	
	pos = (size / Vector2(width, height) * pos - viewbox.position) * get_viewbox_zoom()
	if viewbox.size.x / viewbox.size.y >= width / height:
		return pos + Vector2(0, (height - width * viewbox.size.y / viewbox.size.x) / 2)
	else:
		return pos + Vector2((width - height * viewbox.size.x / viewbox.size.y) / 2, 0)

func canvas_to_coords(pos: Vector2) -> Vector2:
	var width: float = SVG.root_tag.attributes.width.value
	var height: float = SVG.root_tag.attributes.height.value
	var viewbox: Rect2 = SVG.root_tag.attributes.viewBox.value
	
	if viewbox.size.x / viewbox.size.y >= width / height:
		pos.y -= (height - width * viewbox.size.y / viewbox.size.x) / 2
	else:
		pos.x -= (width - height * viewbox.size.x / viewbox.size.y) / 2
	return (pos / get_viewbox_zoom() + viewbox.position) * Vector2(width, height) / size


var dragged_handle: Handle = null
var hovered_handle: Handle = null
var was_handle_moved := false

func _unhandled_input(event: InputEvent) -> void:
	var max_grab_dist := 9 / zoom
	if event is InputEventMouseMotion:
		var event_pos: Vector2 = event.position - global_position
		
		if dragged_handle != null:
			# Move the handle that's being dragged.
			var new_pos := canvas_to_coords(event_pos)
			if snap_enabled:
				new_pos = new_pos.snapped(snap_size)
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			accept_event()
		else:
			# Find the closest handle.
			var nearest_handle: Handle = null
			var nearest_dist := max_grab_dist
			for handle in handles:
				var dist_to_handle := event_pos.distance_to(coords_to_canvas(handle.pos))
				if dist_to_handle < nearest_dist:
					nearest_dist = dist_to_handle
					nearest_handle = handle
			if nearest_handle != null:
				hovered_handle = nearest_handle
				Interactions.set_hovered(hovered_handle.tag_index)
			else:
				hovered_handle = null
				Interactions.clear_hovered()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var event_pos: Vector2 = event.position - global_position
		# React to LMB actions.
		if hovered_handle != null and event.is_pressed():
			dragged_handle = hovered_handle
			Interactions.set_selection(dragged_handle.tag_index)
		elif dragged_handle != null and event.is_released():
			if was_handle_moved:
				var new_pos := canvas_to_coords(event_pos)
				if snap_enabled:
					new_pos = new_pos.snapped(snap_size)
				dragged_handle.set_pos(new_pos)
				was_handle_moved = false
			dragged_handle = null
		elif hovered_handle == null and event.is_pressed():
			dragged_handle = null
			Interactions.clear_selection()


func _on_snapper_value_changed(new_value: float) -> void:
	snap_size = Vector2(new_value, new_value)

func _on_snap_button_toggled(toggled_on: bool) -> void:
	snap_enabled = toggled_on
