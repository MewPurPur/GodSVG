extends Control

const selection_color_string = "#46f"
const hover_color_string = "#999"
const default_color_string = "#000"
const selection_color = Color(selection_color_string)
const hover_color = Color(hover_color_string)
const default_color = Color(default_color_string)

var zoom := 1.0:
	set(new_value):
		zoom = new_value
		queue_update_texture()
		queue_redraw()

var snap_enabled := false
var snap_size := Vector2(0.5, 0.5)

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
	queue_redraw()

func update_handles() -> void:
	handles.clear()
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var new_handles: Array[Handle] = []
		match tag.title:
			"circle":
				new_handles.append(XYHandle.new(tag.attributes.cx, tag.attributes.cy))
			"ellipse":
				new_handles.append(XYHandle.new(tag.attributes.cx, tag.attributes.cy))
			"rect":
				new_handles.append(XYHandle.new(tag.attributes.x, tag.attributes.y))
			"line":
				new_handles.append(XYHandle.new(tag.attributes.x1, tag.attributes.y1))
				new_handles.append(XYHandle.new(tag.attributes.x2, tag.attributes.y2))
			"path":
				new_handles += generate_path_handles(tag.attributes.d)
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
		if tag.title == "path":
			handles += generate_path_handles(tag.attributes.d)
	queue_redraw()

func generate_path_handles(path_attribute: AttributePath) -> Array[Handle]:
	var path_handles: Array[Handle] = []
	for idx in path_attribute.get_command_count():
		var path_command := path_attribute.get_command(idx)
		if path_command.command_char.to_upper() != "Z":
			path_handles.append(PathHandle.new(path_attribute, idx))
			if path_command.command_char.to_upper() in ["C", "Q"]:
				var new_path_handle := PathHandle.new(path_attribute, idx, &"x1", &"y1")
				new_path_handle.display_mode = Handle.DisplayMode.SMALL
				path_handles.append(new_path_handle)
			if path_command.command_char.to_upper() in ["C", "S"]:
				var new_path_handle := PathHandle.new(path_attribute, idx, &"x2", &"y2")
				new_path_handle.display_mode = Handle.DisplayMode.SMALL
				path_handles.append(new_path_handle)
	return path_handles


func _draw() -> void:
	var thickness := 0.8 / zoom
	var tangent_thickness := 0.55 / zoom
	var tangent_alpha := 0.8
	
	var viewbox_zoom := get_viewbox_zoom()
	# Draw the contours of shapes, and also tangents of bezier curves in paths.
	var normal_polylines: Array[PackedVector2Array] = []
	var selected_polylines: Array[PackedVector2Array] = []
	var hovered_polylines: Array[PackedVector2Array] = []
	
	for tag_idx in SVG.root_tag.get_child_count():
		var tag := SVG.root_tag.child_tags[tag_idx]
		var attribs := tag.attributes
		
		match tag.title:
			"circle":
				var c := Vector2(attribs.cx.get_value(), attribs.cy.get_value())
				var r: float = attribs.r.get_value()
				var points := PackedVector2Array()
				for i in range(0, 361, 2):
					var d := deg_to_rad(i)
					points.append(convert_in(c + Vector2(cos(d) * r, sin(d) * r)))
				
				if tag_idx == Interactions.hovered_tag:
					hovered_polylines.append(points)
				elif tag_idx in Interactions.selected_tags:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
				
			"ellipse":
				var c := Vector2(attribs.cx.get_value(), attribs.cy.get_value())
				var rx: float = attribs.rx.get_value()
				var ry: float = attribs.ry.get_value()
				# Squished circle.
				var points := PackedVector2Array()
				for i in range(0, 361, 2):
					var d := deg_to_rad(i)
					points.append(convert_in(c + Vector2(cos(d) * rx, sin(d) * ry)))
				
				if tag_idx == Interactions.hovered_tag:
					hovered_polylines.append(points)
				elif tag_idx in Interactions.selected_tags:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
				
			"rect":
				var x: float = attribs.x.get_value()
				var y: float = attribs.y.get_value()
				var height: float = attribs.height.get_value()
				var width: float = attribs.width.get_value()
				var rx: float = attribs.rx.get_value()
				var ry: float = attribs.ry.get_value()
				var points := PackedVector2Array()
				if rx == 0 and ry == 0:
					# Basic rectangle.
					points.append(convert_in(Vector2(x, y)))
					points.append(convert_in(Vector2(x + width, y)))
					points.append(convert_in(Vector2(x + width, y + height)))
					points.append(convert_in(Vector2(x, y + height)))
					points.append(convert_in(Vector2(x, y)))
				else:
					if rx == 0:
						rx = ry
					elif ry == 0:
						ry = rx
					rx = minf(rx, width / 2)
					ry = minf(ry, height / 2)
					# Rounded rectangle.
					points.append(convert_in(Vector2(x + rx, y)))
					points.append(convert_in(Vector2(x + width - rx, y)))
					for i in range(-88, 1, 2):
						var d := deg_to_rad(i)
						points.append(convert_in(Vector2(x + width - rx, y + ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)))
					points.append(convert_in(Vector2(x + width, y + height - ry)))
					for i in range(2, 92, 2):
						var d := deg_to_rad(i)
						points.append(convert_in(Vector2(x + width - rx, y + height - ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)))
					points.append(convert_in(Vector2(x + rx, y + height)))
					for i in range(92, 181, 2):
						var d := deg_to_rad(i)
						points.append(convert_in(Vector2(x + rx, y + height - ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)))
					points.append(convert_in(Vector2(x, y + ry)))
					for i in range(182, 272, 2):
						var d := deg_to_rad(i)
						points.append(convert_in(Vector2(x + rx, y + ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)))
				
				if tag_idx == Interactions.hovered_tag:
					hovered_polylines.append(points)
				elif tag_idx in Interactions.selected_tags:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
				
			"line":
				var x1: float = attribs.x1.get_value()
				var y1: float = attribs.y1.get_value()
				var x2: float = attribs.x2.get_value()
				var y2: float = attribs.y2.get_value()
				
				var points := PackedVector2Array()
				points.append(convert_in(Vector2(x1, y1)))
				points.append(convert_in(Vector2(x2, y2)))
				
				if tag_idx == Interactions.hovered_tag:
					hovered_polylines.append(points)
				elif tag_idx in Interactions.selected_tags:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
				
			"path":
				var pathdata: AttributePath = attribs.d
				var current_mode := -1  # Normal 0, hovered 1, selected 2.
				for cmd_idx in pathdata.get_command_count():
					# Drawing logic.
					var points := PackedVector2Array()
					var cmd := pathdata.get_command(cmd_idx)
					var relative := cmd.relative
					
					if tag_idx == Interactions.hovered_tag or\
					(Interactions.semi_hovered_tag == tag_idx and\
					Interactions.inner_hovered == cmd_idx):
						current_mode = 1
					elif tag_idx in Interactions.selected_tags or\
					(Interactions.semi_selected_tag == tag_idx and\
					cmd_idx in Interactions.inner_selections):
						current_mode = 2
					elif current_mode != 0:
						current_mode = 0
					
					match cmd.command_char.to_upper():
						"L":
							var v := Vector2(cmd.x, cmd.y)
							var end := cmd.start + v if relative else v
							points = PackedVector2Array([convert_in(cmd.start), convert_in(end)])
						"H":
							var v := Vector2(cmd.x, 0)
							var end := cmd.start + v if relative else Vector2(v.x, cmd.start.y)
							points = PackedVector2Array([convert_in(cmd.start), convert_in(end)])
						"V":
							var v := Vector2(0, cmd.y)
							var end := cmd.start + v if relative else Vector2(cmd.start.x, v.y)
							points = PackedVector2Array([convert_in(cmd.start), convert_in(end)])
						"C":
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2(cmd.x1, cmd.y1)
							var v2 := Vector2(cmd.x2, cmd.y2)
							var cp1 := cmd.start
							var cp4 := cp1 + v if relative else v
							var cp2 := v1 if relative else v1 - cp1
							var cp3 := v2 - v
							
							var tangent_color: Color
							match current_mode:
								0: tangent_color = Color(default_color, tangent_alpha)
								1: tangent_color = Color(hover_color, tangent_alpha)
								2: tangent_color = Color(selection_color, tangent_alpha)
							
							points = Utils.get_cubic_bezier_points(convert_in(cp1),
									convert_in(cp2), convert_in(cp3), convert_in(cp4))
							draw_line(convert_in(cp1), convert_in(cp1 + v1 if relative else v1),
									tangent_color, tangent_thickness, true)
							draw_line(convert_in(cp4), convert_in(cp1 + v2 if relative else v2),
									tangent_color, tangent_thickness, true)
						"S":
							if cmd_idx == 0:
								break
							var prev_cmd := pathdata.get_command(cmd_idx - 1)
							
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2() if relative else cmd.start
							if prev_cmd.command_char.to_upper() in ["C", "S"]:
								var prev_control_pt := Vector2(prev_cmd.x2, prev_cmd.y2)
								if prev_cmd.relative:
									v1 = cmd.start - prev_control_pt - prev_cmd.start if relative\
											else cmd.start * 2 - prev_control_pt - prev_cmd.start
								else:
									v1 = cmd.start - prev_control_pt if relative\
											else cmd.start * 2 - prev_control_pt
							var v2 := Vector2(cmd.x2, cmd.y2)
							
							var cp1 := cmd.start
							var cp2 := v1 if relative else v1 - cp1
							var cp3 := v2 - v
							var cp4 := cp1 + v if relative else v
							
							var tangent_color: Color
							match current_mode:
								0: tangent_color = Color(default_color, tangent_alpha)
								1: tangent_color = Color(hover_color, tangent_alpha)
								2: tangent_color = Color(selection_color, tangent_alpha)
							
							points = Utils.get_cubic_bezier_points(convert_in(cp1),
									convert_in(cp2), convert_in(cp3), convert_in(cp4))
							draw_line(convert_in(cp1), convert_in(cp1 + v1 if relative else v1),
									tangent_color, tangent_thickness, true)
							draw_line(convert_in(cp4), convert_in(cp1 + v2 if relative else v2),
									tangent_color, tangent_thickness, true)
						"Q":
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2(cmd.x1, cmd.y1)
							var cp1 := cmd.start
							var cp2 := cp1 + v1 if relative else v1
							var cp3 := cp1 + v if relative else v
							
							var tangent_color: Color
							match current_mode:
								0: tangent_color = Color(default_color, tangent_alpha)
								1: tangent_color = Color(hover_color, tangent_alpha)
								2: tangent_color = Color(selection_color, tangent_alpha)
							
							points = Utils.get_quadratic_bezier_points(
									convert_in(cp1), convert_in(cp2), convert_in(cp3))
							draw_line(convert_in(cp1), convert_in(cp1 + v1 if relative else v1),
									tangent_color, tangent_thickness, true)
							draw_line(convert_in(cp3), convert_in(cp1 + v1 if relative else v1),
									tangent_color, tangent_thickness, true)
						"T":
							var prevQ_idx := cmd_idx - 1
							var prevQ_cmd := pathdata.get_command(prevQ_idx)
							while prevQ_idx >= 0:
								if prevQ_cmd.command_char.to_upper() == "Q":
									break
								elif prevQ_cmd.command_char.to_upper() != "T":
									# Invalid T is drawn as a line.
									var end := cmd.start + Vector2(cmd.x, cmd.y) if relative\
											else Vector2(cmd.x, cmd.y)
									points.append(convert_in(cmd.start))
									points.append(convert_in(end))
									prevQ_idx = -1
									break
								else:
									prevQ_idx -= 1
									prevQ_cmd = pathdata.get_command(prevQ_idx)
							if prevQ_idx == -1:
								continue
							var prevQ_v := Vector2(prevQ_cmd.x, prevQ_cmd.y)
							var prevQ_v1 := Vector2(prevQ_cmd.x1, prevQ_cmd.y1)
							var prevQ_end := prevQ_cmd.start + prevQ_v\
									if prevQ_cmd.relative else prevQ_v
							var prevQ_control_pt := prevQ_cmd.start + prevQ_v1\
									if prevQ_cmd.relative else prevQ_v1
							
							var v := Vector2(cmd.x, cmd.y)
							var v1 := prevQ_end * 2 - prevQ_control_pt
							for T_idx in range(prevQ_idx + 1, cmd_idx):
								var T_cmd := pathdata.get_command(T_idx)
								var T_v := Vector2(T_cmd.x, T_cmd.y)
								var T_end := T_cmd.start + T_v if T_cmd.relative else T_v
								v1 = T_end * 2 - v1
							
							var cp1 := cmd.start
							var cp2 := v1
							var cp3 := cp1 + v if relative else v
							
							var tangent_color: Color
							match current_mode:
								0: tangent_color = Color(default_color, tangent_alpha)
								1: tangent_color = Color(hover_color, tangent_alpha)
								2: tangent_color = Color(selection_color, tangent_alpha)
							
							points = Utils.get_quadratic_bezier_points(
									convert_in(cp1), convert_in(cp2), convert_in(cp3))
							draw_line(convert_in(cp1), convert_in(cp2),
									tangent_color, tangent_thickness, true)
							draw_line(convert_in(cp3), convert_in(cp2),
									tangent_color, tangent_thickness, true)
						"A":
							var start := cmd.start
							var v := Vector2(cmd.x, cmd.y)
							var end := start + v if relative else v
							# Correct for out-of-range radii.
							if start == end:
								continue
							elif cmd.rx == 0 or cmd.ry == 0:
								points = PackedVector2Array([convert_in(start), convert_in(end)])
							
							var r := Vector2(cmd.rx, cmd.ry).abs()
							# Obtain center parametrization.
							var rot := deg_to_rad(cmd.rot)
							var cosine := cos(rot)
							var sine := sin(rot)
							var half := (start - end) / 2
							var x1 := half.x * cosine + half.y * sine
							var y1 := -half.x * sine + half.y * cosine
							var r2 := Vector2(r.x * r.x, r.y * r.y)
							var x12 := x1 * x1
							var y12 := y1 * y1
							var cr := x12 / r2.x + y12 / r2.y
							if cr > 1:
								cr = sqrt(cr)
								r *= cr
								r2 = Vector2(r.x * r.x, r.y * r.y)
							
							var dq := r2.x * y12 + r2.y * x12
							var pq := (r2.x * r2.y - dq) / dq
							var sc := sqrt(maxf(0, pq))
							if cmd.large_arc_flag == cmd.sweep_flag:
								sc = -sc
							
							var ct := Vector2(r.x * sc * y1 / r.y, -r.y * sc * x1 / r.x)
							var c := Vector2(ct.x * cosine - ct.y * sine,
									ct.x * sine + ct.y * cosine) + start.lerp(end, 0.5)
							var tv := Vector2(x1 - ct.x, y1 - ct.y) / r
							var theta1 := tv.angle()
							var delta_theta := fposmod(tv.angle_to(
									Vector2(-x1 - ct.x, -y1 - ct.y) / r), TAU)
							if cmd.sweep_flag == 0:
								theta1 += delta_theta
								delta_theta = TAU - delta_theta
							
							# Now we have a center parametrization (r, c, theta1, delta_theta).
							# We will approximate the elliptical arc with Bezier curves.
							# Use the method described in https://www.blog.akhil.cc/ellipse
							# (but with modifications because it wasn't working fully).
							var segments := delta_theta * 4/PI
							var n := floori(segments)
							var p1 := Utils.E(c, r, cosine, sine, theta1)
							var e1 := Utils.Et(r, cosine, sine, theta1)
							var alpha := 0.265115
							var t := theta1 + PI/4
							var cp: Array[PackedVector2Array] = []
							for _i in n:
								var p2 := Utils.E(c, r, cosine, sine, t)
								var e2 := Utils.Et(r, cosine, sine, t)
								var q1 := alpha * e1
								var q2 := -alpha * e2
								cp.append(PackedVector2Array([p1, q1, q2, p2]))
								p1 = p2
								e1 = e2
								t += PI/4
							
							if n != ceili(segments):
								t = theta1 + delta_theta
								var p2 := Utils.E(c, r, cosine, sine, t)
								var e2 := Utils.Et(r, cosine, sine, t)
								var q1 := alpha * e1
								var q2 := -alpha * e2
								cp.append(PackedVector2Array([p1, q1, q2, p2]))
							
							for p in cp:
								points += Utils.get_cubic_bezier_points(convert_in(p[0]),
										p[1] * viewbox_zoom, p[2] * viewbox_zoom, convert_in(p[3]))
						"Z":
							var prev_M_idx := cmd_idx - 1
							var prev_M_cmd := pathdata.get_command(prev_M_idx)
							while prev_M_idx >= 0:
								if prev_M_cmd.command_char.to_upper() == "M":
									break
								prev_M_idx -= 1
								prev_M_cmd = pathdata.get_command(prev_M_idx)
							if prev_M_idx == -1:
								break
							
							var end := Vector2(prev_M_cmd.x, prev_M_cmd.y)
							if prev_M_cmd.relative:
								end += prev_M_cmd.start
							
							points = PackedVector2Array([convert_in(cmd.start), convert_in(end)])
						_: continue
					
					match current_mode:
						0: normal_polylines.append(points.duplicate())
						1: hovered_polylines.append(points.duplicate())
						2: selected_polylines.append(points.duplicate())
		
		for polyline in normal_polylines:
			draw_polyline(polyline, default_color, thickness, true)
		for polyline in selected_polylines:
			draw_polyline(polyline, selection_color, thickness, true)
		for polyline in hovered_polylines:
			draw_polyline(polyline, hover_color, thickness, true)
	
	var normal_handles: Array[Handle] = []
	var selected_handles: Array[Handle] = []
	var hovered_handles: Array[Handle] = []
	for handle in handles:
		if (handle is XYHandle and handle.tag_index == Interactions.hovered_tag) or\
		(handle is PathHandle and ((handle.tag_index == Interactions.semi_hovered_tag and\
		handle.command_index == Interactions.inner_hovered) or\
		handle.tag_index == Interactions.hovered_tag)):
			hovered_handles.append(handle)
		elif (handle is XYHandle and handle.tag_index in Interactions.selected_tags) or\
		(handle is PathHandle and ((handle.tag_index == Interactions.semi_selected_tag and\
		handle.command_index in Interactions.inner_selections) or\
		handle.tag_index in Interactions.selected_tags)):
			selected_handles.append(handle)
		else:
			normal_handles.append(handle)
	
	for handle in normal_handles:
		draw_handle(handle, default_color)
	for handle in selected_handles:
		draw_handle(handle, selection_color)
	for handle in hovered_handles:
		draw_handle(handle, hover_color)

func draw_handle(handle: Handle, outer_circle_color: Color) -> void:
	match handle.display_mode:
		handle.DisplayMode.BIG:
			draw_circle(convert_in(handle.pos), 4 / zoom, outer_circle_color)
			draw_circle(convert_in(handle.pos), 2.25 / zoom, Color.WHITE)
		handle.DisplayMode.SMALL:
			draw_circle(convert_in(handle.pos), 3 / zoom, outer_circle_color)
			draw_circle(convert_in(handle.pos), 1.75 / zoom, Color.WHITE)


func get_viewbox_zoom() -> float:
	var width: float = SVG.root_tag.attributes.width.get_value()
	var height: float = SVG.root_tag.attributes.height.get_value()
	var viewbox_size: Vector2 = SVG.root_tag.attributes.viewBox.get_value().size
	return minf(width / viewbox_size.x, height / viewbox_size.y)

func convert_in(pos: Vector2) -> Vector2:
	var width: float = SVG.root_tag.attributes.width.get_value()
	var height: float = SVG.root_tag.attributes.height.get_value()
	var viewbox: Rect2 = SVG.root_tag.attributes.viewBox.get_value()
	
	pos = (size / Vector2(width, height) * pos - viewbox.position) * get_viewbox_zoom()
	if viewbox.size.x / viewbox.size.y >= width / height:
		return pos + Vector2(0, (height - width * viewbox.size.y / viewbox.size.x) / 2)
	else:
		return pos + Vector2((width - height * viewbox.size.x / viewbox.size.y) / 2, 0)

func convert_out(pos: Vector2) -> Vector2:
	var width: float = SVG.root_tag.attributes.width.get_value()
	var height: float = SVG.root_tag.attributes.height.get_value()
	var viewbox: Rect2 = SVG.root_tag.attributes.viewBox.get_value()
	
	if viewbox.size.x / viewbox.size.y >= width / height:
		pos.y -= (height - width * viewbox.size.y / viewbox.size.x) / 2
	else:
		pos.x -= (width - height * viewbox.size.x / viewbox.size.y) / 2
	return (pos / get_viewbox_zoom() + viewbox.position) * Vector2(width, height) / size


var dragged_handle: Handle = null
var hovered_handle: Handle = null
var was_handle_moved := false
var should_deselect_all = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		should_deselect_all = false
		var event_pos: Vector2 = event.position - global_position
		
		if dragged_handle != null:
			# Move the handle that's being dragged.
			var new_pos := convert_out(event_pos)
			if snap_enabled:
				new_pos = new_pos.snapped(snap_size)
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			accept_event()
		else:
			var nearest_handle := find_nearest_handle(event_pos)
			if nearest_handle != null:
				hovered_handle = nearest_handle
				if hovered_handle is XYHandle:
					Interactions.set_hovered(hovered_handle.tag_index)
				elif hovered_handle is PathHandle:
					Interactions.set_inner_hovered(hovered_handle.tag_index,
							hovered_handle.command_index)
			else:
				hovered_handle = null
				Interactions.clear_hovered()
				Interactions.clear_inner_hovered()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var event_pos: Vector2 = event.position - global_position
		var nearest_handle := find_nearest_handle(event_pos)
		if nearest_handle != null:
			hovered_handle = nearest_handle
			if hovered_handle is XYHandle:
				Interactions.set_hovered(hovered_handle.tag_index)
			elif hovered_handle is PathHandle:
				Interactions.set_inner_hovered(hovered_handle.tag_index,
						hovered_handle.command_index)
		else:
			hovered_handle = null
			Interactions.clear_hovered()
			Interactions.clear_inner_hovered()
		# React to LMB actions.
		if hovered_handle != null and event.is_pressed():
			dragged_handle = hovered_handle
			if hovered_handle is XYHandle:
				Interactions.set_selection(dragged_handle.tag_index)
			elif hovered_handle is PathHandle:
				Interactions.set_inner_selection(hovered_handle.tag_index,
						hovered_handle.command_index)
		elif dragged_handle != null and event.is_released():
			if was_handle_moved:
				var new_pos := convert_out(event_pos)
				if snap_enabled:
					new_pos = new_pos.snapped(snap_size)
				dragged_handle.set_pos(new_pos)
				was_handle_moved = false
			dragged_handle = null
		elif hovered_handle == null and event.is_pressed():
			should_deselect_all = true
		elif hovered_handle == null and event.is_released() and should_deselect_all:
			dragged_handle = null
			Interactions.clear_selection()
			Interactions.clear_inner_selection()

func find_nearest_handle(event_pos: Vector2) -> Handle:
	var max_grab_dist := 9 / zoom
	var nearest_handle: Handle = null
	var nearest_dist := max_grab_dist
	for handle in handles:
		var dist_to_handle := event_pos.distance_to(convert_in(handle.pos))
		if dist_to_handle < nearest_dist:
			nearest_dist = dist_to_handle
			nearest_handle = handle
	return nearest_handle


func _on_snapper_value_changed(new_value: float) -> void:
	snap_size = Vector2(new_value, new_value)

func _on_snap_button_toggled(toggled_on: bool) -> void:
	snap_enabled = toggled_on
