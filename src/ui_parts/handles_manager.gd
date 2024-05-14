# This script manages contour drawing and handles. 
extends Control

var normal_handle_textures: Dictionary
var hovered_handle_textures: Dictionary
var selected_handle_textures: Dictionary
var hovered_selected_handle_textures: Dictionary

const handles_svg_dict = {
	Handle.Display.BIG: """<svg width="%s" height="%s"
			xmlns="http://www.w3.org/2000/svg"><circle cx="%s" cy="%s" r="%s"
			fill="%s" stroke="%s" stroke-width="%s"/></svg>""",
	Handle.Display.SMALL: """<svg width="%s" height="%s"
		xmlns="http://www.w3.org/2000/svg"><circle cx="%s" cy="%s" r="%s"
		fill="%s" stroke="%s" stroke-width="%s"/></svg>""",
}

const DEFAULT_GRAB_DISTANCE_SQUARED := 81.0

var update_pending := false
var handles: Array[Handle]
var surface := RenderingServer.canvas_item_create()

var normal_color: Color
var hovered_color: Color
var selected_color: Color
var hovered_selected_color: Color

func render_handle_textures() -> void:
	normal_color = GlobalSettings.handle_color
	hovered_color = GlobalSettings.handle_hovered_color
	selected_color = GlobalSettings.handle_selected_color
	hovered_selected_color = GlobalSettings.handle_hovered_selected_color
	var inside_str := "#" + GlobalSettings.handle_inside_color.to_html(false)
	var normal_str := "#" + GlobalSettings.handle_color.to_html(false)
	var hovered_str := "#" + GlobalSettings.handle_hovered_color.to_html(false)
	var selected_str := "#" + GlobalSettings.handle_selected_color.to_html(false)
	var hovered_selected_str := "#" +\
			GlobalSettings.handle_hovered_selected_color.to_html(false)
	var s := GlobalSettings.handle_size  # Shorthand
	var img := Image.new()
	
	var handles_dict := {
		Handle.Display.BIG: """<svg width="%s" height="%s"
				xmlns="http://www.w3.org/2000/svg"><circle cx="%s" cy="%s" r="%s"
				fill="%s" stroke="%s" stroke-width="%s"/></svg>""" % [s * 10, s * 10,
				s * 5, s * 5, s * 3.25, "%s", "%s", s * 1.5],
		Handle.Display.SMALL: """<svg width="%s" height="%s"
			xmlns="http://www.w3.org/2000/svg"><circle cx="%s" cy="%s" r="%s"
			fill="%s" stroke="%s" stroke-width="%s"/></svg>""" % [s * 8, s * 8,
			s * 4, s * 4, s * 2.4, "%s", "%s", s * 1.2],
	}
	
	for handle_type in [Handle.Display.BIG, Handle.Display.SMALL]:
		var handle_type_svg: String = handles_dict[handle_type]
		img.load_svg_from_string(handle_type_svg % [inside_str, normal_str])
		img.fix_alpha_edges()
		normal_handle_textures[handle_type] = ImageTexture.create_from_image(img)
		img.load_svg_from_string(handle_type_svg % [inside_str, hovered_str])
		img.fix_alpha_edges()
		hovered_handle_textures[handle_type] = ImageTexture.create_from_image(img)
		img.load_svg_from_string(handle_type_svg % [inside_str, selected_str])
		img.fix_alpha_edges()
		selected_handle_textures[handle_type] = ImageTexture.create_from_image(img)
		img.load_svg_from_string(handle_type_svg % [inside_str, hovered_selected_str])
		img.fix_alpha_edges()
		hovered_selected_handle_textures[handle_type] = ImageTexture.create_from_image(img)
	
	queue_redraw()

func _ready() -> void:
	render_handle_textures()
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	SVG.root_tag.attribute_changed.connect(queue_update.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(queue_redraw.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(sync_handles.unbind(1))
	SVG.root_tag.tag_layout_changed.connect(queue_update)
	SVG.root_tag.changed_unknown.connect(queue_update)
	Indications.selection_changed.connect(queue_redraw)
	Indications.hover_changed.connect(queue_redraw)
	Indications.zoom_changed.connect(queue_redraw)
	Indications.handle_added.connect(_on_handle_added)
	queue_update()

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.HANDLE_VISUALS_CHANGED:
		render_handle_textures()


func queue_update() -> void:
	update_pending = true

func _process(_delta: float) -> void:
	if update_pending:
		update_handles()
		update_pending = false


func update_handles() -> void:
	handles.clear()
	for tid in SVG.root_tag.get_all_tids():
		var tag := SVG.root_tag.get_tag(tid)
		match tag.name:
			"circle":
				handles.append(generate_xy_handle(tid, tag, "cx", "cy", "transform"))
				handles.append(generate_delta_handle(tid, tag, "cx", "cy", "transform",
						"r", true))
			"ellipse":
				handles.append(generate_xy_handle(tid, tag, "cx", "cy", "transform"))
				handles.append(generate_delta_handle(tid, tag, "cx", "cy", "transform",
						"rx", true))
				handles.append(generate_delta_handle(tid, tag, "cx", "cy", "transform",
						"ry", false))
			"rect":
				handles.append(generate_xy_handle(tid, tag, "x", "y", "transform"))
				handles.append(generate_xy_handle(tid, tag, "x", "y", "transform"))
				handles.append(generate_delta_handle(tid, tag, "x", "y", "transform",
						"width", true))
				handles.append(generate_delta_handle(tid, tag, "x", "y", "transform",
						"height", false))
			"line":
				handles.append(generate_xy_handle(tid, tag, "x1", "y1", "transform"))
				handles.append(generate_xy_handle(tid, tag, "x2", "y2", "transform"))
			"path":
				handles += generate_path_handles(tid, tag.attributes.d,
						tag.attributes.transform)
	# Pretend the mouse was moved to update the hovering.
	var mouse_motion_event := InputEventMouseMotion.new()
	mouse_motion_event.position = get_viewport().get_mouse_position()
	respond_to_input_event(mouse_motion_event)
	queue_redraw()


func sync_handles() -> void:
	# For XYHandles, sync them. For PathHandles, they can be added and removed as an
	# attribute changes, so remove them and re-add them except for the dragged one.
	for handle_idx in range(handles.size() - 1, -1, -1):
		var handle := handles[handle_idx]
		if handle is PathHandle:
			if dragged_handle != handle:
				handles.remove_at(handle_idx)
		else:
			handle.sync()
	
	for tid in SVG.root_tag.get_all_tids():
		var tag := SVG.root_tag.get_tag(tid)
		if tag.name == "path":
			handles += generate_path_handles(tid, tag.attributes.d, tag.attributes.transform)
	queue_redraw()

func generate_path_handles(tid: PackedInt32Array, data_attrib: AttributePath,
t_attrib: AttributeTransform) -> Array[Handle]:
	var path_handles: Array[Handle] = []
	for idx in data_attrib.get_command_count():
		var path_command := data_attrib.get_command(idx)
		if not path_command.command_char in "Zz":
			path_handles.append(PathHandle.new(tid, data_attrib, t_attrib, idx))
			if path_command.command_char in "CcQq":
				var tangent := PathHandle.new(tid, data_attrib, t_attrib, idx, "x1", "y1")
				tangent.display_mode = Handle.Display.SMALL
				path_handles.append(tangent)
			if path_command.command_char in "CcSs":
				var tangent := PathHandle.new(tid, data_attrib, t_attrib, idx, "x2", "y2")
				tangent.display_mode = Handle.Display.SMALL
				path_handles.append(tangent)
	return path_handles

# Helpers for generating the handles when the tag is at hand.
func generate_xy_handle(tid: PackedInt32Array, tag: Tag, x_attrib_name: String,\
y_attrib_name: String, t_attrib_name: String) -> XYHandle:
	return XYHandle.new(tid, tag.attributes[x_attrib_name],
			tag.attributes[y_attrib_name], tag.attributes[t_attrib_name])

func generate_delta_handle(tid: PackedInt32Array, tag: Tag, x_attrib_name: String,\
y_attrib_name: String, t_attrib_name: String, delta_attrib_name: String,\
horizontal: bool) -> DeltaHandle:
	return DeltaHandle.new(tid, tag.attributes[x_attrib_name],
			tag.attributes[y_attrib_name], tag.attributes[t_attrib_name],
			tag.attributes[delta_attrib_name], horizontal)


func _draw() -> void:
	# Store contours of shapes.
	var normal_polylines: Array[PackedVector2Array] = []
	var selected_polylines: Array[PackedVector2Array] = []
	var hovered_polylines: Array[PackedVector2Array] = []
	var hovered_selected_polylines: Array[PackedVector2Array] = []
	# Store abstract contours, e.g. tangents.
	var normal_multiline := PackedVector2Array()
	var selected_multiline := PackedVector2Array()
	var hovered_multiline := PackedVector2Array()
	var hovered_selected_multiline := PackedVector2Array()
	
	for tid in SVG.root_tag.get_all_tids():
		var tag := SVG.root_tag.get_tag(tid)
		var attribs := tag.attributes
		
		# Determine if the tag is hovered/selected or has a hovered/selected parent.
		var tag_hovered := Indications.is_hovered(tid, -1, true)
		var tag_selected := Indications.is_selected(tid, -1, true)
		
		match tag.name:
			"circle":
				var c := Vector2(attribs.cx.get_num(), attribs.cy.get_num())
				var r: float = attribs.r.get_num()
				
				var points := PackedVector2Array()
				points.resize(181)
				for i in 180:
					var d := i * TAU/180
					points[i] = c + Vector2(cos(d), sin(d)) * r
				points[180] = points[0]
				var extras := PackedVector2Array([c, c + Vector2(r, 0)])
				points = attribs.transform.get_final_transform() * points
				extras = attribs.transform.get_final_transform() * extras
				
				if tag_hovered and tag_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif tag_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif tag_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"ellipse":
				var c := Vector2(attribs.cx.get_num(), attribs.cy.get_num())
				var rx: float = attribs.rx.get_num()
				var ry: float = attribs.ry.get_num()
				# Squished circle.
				var points := PackedVector2Array()
				points.resize(181)
				for i in 180:
					var d := i * TAU/180
					points[i] = c + Vector2(cos(d) * rx, sin(d) * ry)
				points[180] = points[0]
				var extras := PackedVector2Array([
						c, c + Vector2(rx, 0), c, c + Vector2(0, ry)])
				points = attribs.transform.get_final_transform() * points
				extras = attribs.transform.get_final_transform() * extras
				
				if tag_hovered and tag_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif tag_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif tag_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"rect":
				var x: float = attribs.x.get_num()
				var y: float = attribs.y.get_num()
				var rect_width: float = attribs.width.get_num()
				var rect_height: float = attribs.height.get_num()
				var rx: float = attribs.rx.get_num()
				var ry: float = attribs.ry.get_num()
				var points := PackedVector2Array()
				if rx == 0 and ry == 0:
					# Basic rectangle.
					points = [Vector2(x, y), Vector2(x + rect_width, y),
							Vector2(x + rect_width, y + rect_height),
							Vector2(x, y + rect_height), Vector2(x, y)]
				else:
					if rx == 0:
						rx = ry
					elif ry == 0:
						ry = rx
					rx = minf(rx, rect_width / 2)
					ry = minf(ry, rect_height / 2)
					# Rounded rectangle.
					points.resize(186)
					points[0] = Vector2(x + rx, y)
					points[1] = Vector2(x + rect_width - rx, y)
					for i in range(135, 180):
						var d := i * TAU/180
						points[i - 133] = Vector2(x + rect_width - rx, y + ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)
					points[47] =  Vector2(x + rect_width, y + rect_height - ry)
					for i in range(0, 45):
						var d := i * TAU/180
						points[i + 48] = Vector2(x + rect_width - rx, y + rect_height - ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)
					points[93] = Vector2(x + rx, y + rect_height)
					for i in range(45, 90):
						var d := i * TAU/180
						points[i + 49] = Vector2(x + rx, y + rect_height - ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)
					points[139] = Vector2(x, y + ry)
					for i in range(90, 135):
						var d := i * TAU/180
						points[i + 50] = Vector2(x + rx, y + ry) +\
								Vector2(cos(d) * rx, sin(d) * ry)
					points[185] = points[0]
				var extras := PackedVector2Array([Vector2(x, y), Vector2(x + rect_width, y),
						Vector2(x, y), Vector2(x, y + rect_height)])
				points = attribs.transform.get_final_transform() * points
				extras = attribs.transform.get_final_transform() * extras
				
				if tag_hovered and tag_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif tag_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif tag_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"line":
				var x1: float = attribs.x1.get_num()
				var y1: float = attribs.y1.get_num()
				var x2: float = attribs.x2.get_num()
				var y2: float = attribs.y2.get_num()
				
				var points := PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2)])
				points = attribs.transform.get_final_transform() * points
				
				if tag_hovered and tag_selected:
					hovered_selected_polylines.append(points)
				elif tag_hovered:
					hovered_polylines.append(points)
				elif tag_selected:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
			
			"path":
				var pathdata: AttributePath = attribs.d
				if pathdata.get_command_count() == 0 or\
				not pathdata.get_command(0).command_char in "Mm":
					continue  # Nothing to draw.
				
				var current_mode := Utils.InteractionType.NONE
				
				for cmd_idx in pathdata.get_command_count():
					# Drawing logic.
					var points := PackedVector2Array()
					var tangent_points := PackedVector2Array()
					var cmd := pathdata.get_command(cmd_idx)
					var relative := cmd.relative
					
					current_mode = Utils.InteractionType.NONE
					if Indications.is_hovered(tid, cmd_idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if Indications.is_selected(tid, cmd_idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.SELECTED
					
					match cmd.command_char.to_upper():
						"L":
							# Line contour.
							var v := Vector2(cmd.x, cmd.y)
							var end := cmd.start + v if relative else v
							points = PackedVector2Array([cmd.start, end])
						"H":
							# Horizontal line contour.
							var v := Vector2(cmd.x, 0)
							var end := cmd.start + v if relative else Vector2(v.x, cmd.start.y)
							points = PackedVector2Array([cmd.start, end])
						"V":
							# Vertical line contour.
							var v := Vector2(0, cmd.y)
							var end := cmd.start + v if relative else Vector2(cmd.start.x, v.y)
							points = PackedVector2Array([cmd.start, end])
						"C":
							# Cubic Bezier curve contour.
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2(cmd.x1, cmd.y1)
							var v2 := Vector2(cmd.x2, cmd.y2)
							var cp1 := cmd.start
							var cp4 := cp1 + v if relative else v
							var cp2 := v1 if relative else v1 - cp1
							var cp3 := v2 - v
							
							points = Utils.get_cubic_bezier_points(cp1, cp2, cp3, cp4)
							tangent_points.append_array(PackedVector2Array([cp1,
									cp1 + cp2, cp1 + v2 if relative else v2, cp4]))
						"S":
							# Shorthand cubic Bezier curve contour.
							if cmd_idx == 0:
								break
							
							var v := Vector2(cmd.x, cmd.y)
							var v1 := pathdata.get_implied_S_control(cmd_idx)
							var v2 := Vector2(cmd.x2, cmd.y2)
							
							var cp1 := cmd.start
							var cp4 := cp1 + v if relative else v
							var cp2 := v1 if relative else v1 - cp1
							var cp3 := v2 - v
							
							points = Utils.get_cubic_bezier_points(cp1, cp2, cp3, cp4)
							tangent_points.append_array(PackedVector2Array([cp1,
									cp1 + cp2, cp1 + v2 if relative else v2, cp4]))
						"Q":
							# Quadratic Bezier curve contour.
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2(cmd.x1, cmd.y1)
							var cp1 := cmd.start
							var cp2 := cp1 + v1 if relative else v1
							var cp3 := cp1 + v if relative else v
							
							points = Utils.get_quadratic_bezier_points(cp1, cp2, cp3)
							tangent_points.append_array(PackedVector2Array([cp1, cp2, cp2, cp3]))
						"T":
							# Shorthand quadratic Bezier curve contour.
							var v := Vector2(cmd.x, cmd.y)
							var v1 := pathdata.get_implied_T_control(cmd_idx)
							
							var cp1 := cmd.start
							var cp2 := v1 + cp1 if relative else v1
							var cp3 := cp1 + v if relative else v
							
							if is_nan(cp2.x) and is_nan(cp2.y):
								points = PackedVector2Array([cp1, cp3])
							else:
								points = Utils.get_quadratic_bezier_points(cp1, cp2, cp3)
								tangent_points.append_array(
										PackedVector2Array([cp1, cp2, cp2, cp3]))
						"A":
							# Elliptical arc contour.
							var start := cmd.start
							var v := Vector2(cmd.x, cmd.y)
							var end := start + v if relative else v
							# Correct for out-of-range radii.
							if start == end:
								continue
							elif cmd.rx == 0 or cmd.ry == 0:
								points = PackedVector2Array([start, end])
							
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
							var alpha := 0.26511478
							var t := theta1 + PI/4
							var cp: Array[PackedVector2Array] = []
							for _i in n:
								var p2 := Utils.E(c, r, cosine, sine, t)
								var e2 := Utils.Et(r, cosine, sine, t)
								cp.append(PackedVector2Array([p1, alpha * e1, -alpha * e2, p2]))
								p1 = p2
								e1 = e2
								t += PI/4
							
							if n != ceili(segments):
								t = theta1 + delta_theta
								var p2 := Utils.E(c, r, cosine, sine, t)
								var e2 := Utils.Et(r, cosine, sine, t)
								alpha *= fposmod(delta_theta, PI/4) / (PI/4)
								cp.append(PackedVector2Array([p1, alpha * e1, -alpha * e2, p2]))
							
							for p in cp:
								points += Utils.get_cubic_bezier_points(p[0], p[1], p[2], p[3])
						"Z":
							# Path closure contour.
							var prev_M_idx := cmd_idx - 1
							var prev_M_cmd := pathdata.get_command(prev_M_idx)
							while prev_M_idx >= 0:
								if prev_M_cmd.command_char in "Mm":
									break
								prev_M_idx -= 1
								prev_M_cmd = pathdata.get_command(prev_M_idx)
							if prev_M_idx == -1:
								break
							
							var end := Vector2(prev_M_cmd.x, prev_M_cmd.y)
							if prev_M_cmd.relative:
								end += prev_M_cmd.start
							
							points = PackedVector2Array([cmd.start, end])
						_: continue
					points = attribs.transform.get_final_transform() * points
					tangent_points = attribs.transform.get_final_transform() * tangent_points
					match current_mode:
						Utils.InteractionType.NONE:
							normal_polylines.append(points.duplicate())
							normal_multiline += tangent_points.duplicate()
						Utils.InteractionType.HOVERED:
							hovered_polylines.append(points.duplicate())
							hovered_multiline += tangent_points.duplicate()
						Utils.InteractionType.SELECTED:
							selected_polylines.append(points.duplicate())
							selected_multiline += tangent_points.duplicate()
						Utils.InteractionType.HOVERED_SELECTED:
							hovered_selected_polylines.append(points.duplicate())
							hovered_selected_multiline += tangent_points.duplicate()
	
	var draw_zoom := Indications.zoom * SVG.root_tag.canvas_transform.get_scale().x
	var contour_width := 1.0 / draw_zoom
	var tangent_width := 0.6 / draw_zoom
	var tangent_alpha := 0.8
	draw_set_transform_matrix(SVG.root_tag.canvas_transform)
	RenderingServer.canvas_item_set_transform(surface, Transform2D(0.0,
			Vector2(1 / Indications.zoom, 1 / Indications.zoom), 0.0, Vector2.ZERO))
	
	for polyline in normal_polylines:
		draw_polyline(polyline, normal_color, contour_width, true)
	for polyline in selected_polylines:
		draw_polyline(polyline, selected_color, contour_width, true)
	for polyline in hovered_polylines:
		draw_polyline(polyline, hovered_color, contour_width, true)
	for polyline in hovered_selected_polylines:
		draw_polyline(polyline, hovered_selected_color, contour_width, true)
	
	# TODO Change this when it's implemented in Godot.
	draw_multiline_antaliased(normal_multiline,
			Color(normal_color, tangent_alpha), tangent_width)
	draw_multiline_antaliased(selected_multiline,
			Color(selected_color, tangent_alpha), tangent_width)
	draw_multiline_antaliased(hovered_multiline,
			Color(hovered_color, tangent_alpha), tangent_width)
	draw_multiline_antaliased(hovered_selected_multiline,
			Color(hovered_selected_color, tangent_alpha), tangent_width)
	
	# First gather all handles in 4 categories, then draw them in the right order.
	var normal_handles: Array[Handle] = []
	var selected_handles: Array[Handle] = []
	var hovered_handles: Array[Handle] = []
	var hovered_selected_handles: Array[Handle] = []
	for handle in handles:
		var cmd_idx: int = handle.command_index if handle is PathHandle else -1
		var is_hovered := Indications.is_hovered(handle.tid, cmd_idx, true)
		var is_selected := Indications.is_selected(handle.tid, cmd_idx, true)
		
		if is_hovered and is_selected:
			hovered_selected_handles.append(handle)
		elif is_hovered:
			hovered_handles.append(handle)
		elif is_selected:
			selected_handles.append(handle)
		else:
			normal_handles.append(handle)
	
	RenderingServer.canvas_item_clear(surface)
	for handle in normal_handles:
		var texture: Texture2D = normal_handle_textures[handle.display_mode]
		texture.draw(surface, SVG.root_tag.canvas_to_world(handle.transform * handle.pos) *\
				Indications.zoom - texture.get_size() / 2)
	for handle in selected_handles:
		var texture: Texture2D = selected_handle_textures[handle.display_mode]
		texture.draw(surface, SVG.root_tag.canvas_to_world(handle.transform * handle.pos) *\
				Indications.zoom - texture.get_size() / 2)
	for handle in hovered_handles:
		var texture: Texture2D = hovered_handle_textures[handle.display_mode]
		texture.draw(surface, SVG.root_tag.canvas_to_world(handle.transform * handle.pos) *\
				Indications.zoom - texture.get_size() / 2)
	for handle in hovered_selected_handles:
		var texture: Texture2D = hovered_selected_handle_textures[handle.display_mode]
		texture.draw(surface, SVG.root_tag.canvas_to_world(handle.transform * handle.pos) *\
				Indications.zoom - texture.get_size() / 2)

# TODO remove this when it's implemented in Godot.
func draw_multiline_antaliased(points: PackedVector2Array, color: Color,
width: float) -> void:
	for i in int(points.size() / 2.0):
		var i2 := i * 2
		draw_line(points[i2], points[i2 + 1], color, width, true)


var dragged_handle: Handle = null
var hovered_handle: Handle = null
var was_handle_moved := false
var should_deselect_all := false

func _unhandled_input(event: InputEvent) -> void:
	respond_to_input_event(event)

func respond_to_input_event(event: InputEvent) -> void:
	if not visible:
		return
	
	# Set the nearest handle as hovered, if any handles are within range.
	if (event is InputEventMouseMotion and !is_instance_valid(dragged_handle) and\
	event.button_mask == 0) or (event is InputEventMouseButton and\
	(event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_DOWN,
	MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT])):
		var nearest_handle := find_nearest_handle(event.position / Indications.zoom +\
				get_node(^"../..").view.position)
		if is_instance_valid(nearest_handle):
			hovered_handle = nearest_handle
			if hovered_handle is PathHandle:
				Indications.set_hovered(hovered_handle.tid, hovered_handle.command_index)
			else:
				Indications.set_hovered(hovered_handle.tid)
		else:
			hovered_handle = null
			Indications.clear_hovered()
			Indications.clear_inner_hovered()
	
	var snap_enabled := GlobalSettings.save_data.snap > 0.0
	var snap_size := absf(GlobalSettings.save_data.snap)
	var snap_vector := Vector2(snap_size, snap_size)
	
	if event is InputEventMouseMotion:
		
		# Allow moving view while dragging handle.
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			return
		
		should_deselect_all = false
		var event_pos: Vector2 = event.position / Indications.zoom +\
				get_node(^"../..").view.position
		if is_instance_valid(dragged_handle):
			# Move the handle that's being dragged.
			if snap_enabled:
				event_pos = event_pos.snapped(snap_vector)
			var new_pos := dragged_handle.transform.affine_inverse() *\
					SVG.root_tag.world_to_canvas(event_pos)
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			accept_event()
	elif event is InputEventMouseButton:
		var event_pos: Vector2 = event.position / Indications.zoom +\
				get_node(^"../..").view.position
		if snap_enabled:
			event_pos = event_pos.snapped(snap_vector)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# React to LMB actions.
			if is_instance_valid(hovered_handle) and event.is_pressed():
				dragged_handle = hovered_handle
				dragged_handle.initial_pos = dragged_handle.pos
				var inner_idx := -1
				var dragged_tid := dragged_handle.tid
				if dragged_handle is PathHandle:
					inner_idx = dragged_handle.command_index
				
				if event.double_click and inner_idx != -1:
					# Unselect the tag, so then it's selected again in the subpath.
					Indications.ctrl_select(dragged_tid, inner_idx)
					var subpath_range: Vector2i =\
							dragged_handle.path_attribute.get_subpath(inner_idx)
					for idx in range(subpath_range.x, subpath_range.y + 1):
						Indications.ctrl_select(dragged_tid, idx)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(dragged_tid, inner_idx)
				elif event.shift_pressed:
					Indications.shift_select(dragged_tid, inner_idx)
				else:
					Indications.normal_select(dragged_tid, inner_idx)
			elif is_instance_valid(dragged_handle) and event.is_released():
				if was_handle_moved:
					var new_pos := dragged_handle.transform.affine_inverse() *\
							SVG.root_tag.world_to_canvas(event_pos)
					dragged_handle.set_pos(new_pos, true)
					was_handle_moved = false
				dragged_handle = null
			elif !is_instance_valid(hovered_handle) and event.is_pressed():
				should_deselect_all = true
			elif !is_instance_valid(hovered_handle) and event.is_released() and should_deselect_all:
				dragged_handle = null
				Indications.clear_all_selections()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			var vp := get_viewport()
			var popup_pos := vp.get_mouse_position()
			if !is_instance_valid(hovered_handle):
				Indications.clear_all_selections()
				HandlerGUI.popup_under_pos(create_tag_context(event_pos), popup_pos, vp)
			else:
				var hovered_tid := hovered_handle.tid
				var inner_idx := -1
				if hovered_handle is PathHandle:
					inner_idx = hovered_handle.command_index
				
				if (Indications.semi_selected_tid != hovered_tid or\
				not inner_idx in Indications.inner_selections) and\
				not hovered_tid in Indications.selected_tids:
					Indications.normal_select(hovered_tid, inner_idx)
				HandlerGUI.popup_under_pos(Indications.get_selection_context(
						HandlerGUI.popup_under_pos.bind(popup_pos, vp), Indications.SelectionContext.VIEWPORT), popup_pos, vp)

func find_nearest_handle(event_pos: Vector2) -> Handle:
	var nearest_handle: Handle = null
	var nearest_dist_squared := DEFAULT_GRAB_DISTANCE_SQUARED *\
			(GlobalSettings.handle_size * GlobalSettings.handle_size) /\
			(Indications.zoom * Indications.zoom)
	for handle in handles:
		var dist_to_handle_squared := event_pos.distance_squared_to(
					SVG.root_tag.canvas_to_world(handle.transform * handle.pos))
		if dist_to_handle_squared < nearest_dist_squared:
			nearest_dist_squared = dist_to_handle_squared
			nearest_handle = handle
	return nearest_handle

func _on_handle_added() -> void:
	if not get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		if not Indications.semi_selected_tid.is_empty():
			SVG.root_tag.get_tag(Indications.semi_selected_tid).attributes.d.\
					sync_after_commands_change(Attribute.SyncMode.FINAL)
		return
	
	update_handles()
	for handle in handles:
		if handle is PathHandle and handle.tid == Indications.semi_selected_tid and\
		handle.command_index == Indications.inner_selections[0]:
			Indications.set_hovered(handle.tid, handle.command_index)
			dragged_handle = handle
			# Move the handle that's being dragged.
			var mouse_pos := get_global_mouse_position()
			var snap_size := GlobalSettings.save_data.snap
			if snap_size > 0.0:
				mouse_pos = mouse_pos.snapped(Vector2(snap_size, snap_size))
			
			var new_pos := dragged_handle.transform.affine_inverse() *\
					SVG.root_tag.world_to_canvas(mouse_pos)
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			return

# Creates a popup for adding a shape at a position.
func create_tag_context(pos: Vector2) -> ContextPopup:
	var btn_array: Array[Button] = []
	for shape in ["path", "circle", "ellipse", "rect", "line"]:
		var btn := Utils.create_btn(shape, add_tag_at_pos.bind(shape, pos),
				false, DB.get_tag_icon(shape))
		btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
		btn_array.append(btn)
	var tag_context := ContextPopup.new()
	tag_context.setup_with_title(btn_array, TranslationServer.translate("New tag"), true)
	return tag_context

func add_tag_at_pos(tag_name: String, pos: Vector2) -> void:
	var tag: Tag
	match tag_name:
		"path": tag = TagPath.new()
		"circle": tag = TagCircle.new()
		"ellipse": tag = TagEllipse.new()
		"rect": tag = TagRect.new()
		"line": tag = TagLine.new()
	tag.user_setup(pos)
	SVG.root_tag.add_tag(tag, PackedInt32Array([SVG.root_tag.get_child_count()]))
