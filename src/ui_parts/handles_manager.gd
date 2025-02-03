# This script manages contour drawing and handles.
extends Control

var normal_handle_textures: Dictionary[Handle.Display, Texture2D]
var hovered_handle_textures: Dictionary[Handle.Display, Texture2D]
var selected_handle_textures: Dictionary[Handle.Display, Texture2D]
var hovered_selected_handle_textures: Dictionary[Handle.Display, Texture2D]

const stroke_shader = preload("res://src/shaders/animated_stroke.gdshader")

const DEFAULT_GRAB_DISTANCE_SQUARED := 81.0
const CONTOUR_WIDTH = 1.0
const TANGENT_WIDTH = 0.65
const TANGENT_ALPHA = 0.8

var _handles_update_pending := false
var handles: Array[Handle]
var surface := RenderingServer.canvas_item_create()
var selections_surface := RenderingServer.canvas_item_create()

var normal_color: Color
var hovered_color: Color
var selected_color: Color
var hovered_selected_color: Color


func _exit_tree() -> void:
	RenderingServer.free_rid(surface)
	RenderingServer.free_rid(selections_surface)

func render_handle_textures() -> void:
	normal_color = Configs.savedata.handle_color
	hovered_color = Configs.savedata.handle_hovered_color
	selected_color = Configs.savedata.handle_selected_color
	hovered_selected_color = Configs.savedata.handle_hovered_selected_color
	var inside_str := "#" + Configs.savedata.handle_inner_color.to_html(false)
	var normal_str := "#" + Configs.savedata.handle_color.to_html(false)
	var hovered_str := "#" + Configs.savedata.handle_hovered_color.to_html(false)
	var selected_str := "#" + Configs.savedata.handle_selected_color.to_html(false)
	var hovered_selected_str := "#" +\
			Configs.savedata.handle_hovered_selected_color.to_html(false)
	var s := Configs.savedata.handle_size  # Shorthand
	var img := Image.new()
	
	var handles_dict: Dictionary[Handle.Display, String] = {
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
		var handle_type_svg := handles_dict[handle_type]
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
	Configs.handle_visuals_changed.connect(render_handle_textures)
	render_handle_textures()
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_parent(selections_surface, get_canvas_item())
	var stroke_material := ShaderMaterial.new()
	stroke_material.shader = stroke_shader
	stroke_material.set_shader_parameter("ant_color_1", Color(1, 1, 1, 0.8))
	stroke_material.set_shader_parameter("ant_color_2", Color(0, 0, 0, 0.8))
	RenderingServer.canvas_item_set_material(selections_surface, stroke_material.get_rid())
	
	# FIXME this shouldn't be needed, but otherwise the shader doesn't want to work.
	var c := Control.new()
	c.material = stroke_material
	add_child(c, false, InternalMode.INTERNAL_MODE_BACK)
	
	State.any_attribute_changed.connect(sync_handles)
	State.xnode_layout_changed.connect(queue_update_handles)
	State.svg_unknown_change.connect(queue_update_handles)
	State.selection_changed.connect(queue_redraw)
	State.hover_changed.connect(queue_redraw)
	State.zoom_changed.connect(queue_redraw)
	State.handle_added.connect(_on_handle_added)
	queue_update_handles()


func queue_update_handles() -> void:
	update_handles.call_deferred()
	_handles_update_pending = true

func update_handles() -> void:
	if not _handles_update_pending:
		return
	
	_handles_update_pending = false
	handles.clear()
	for element in State.root_element.get_all_element_descendants():
		match element.name:
			"circle":
				handles.append(XYHandle.new(element, "cx", "cy"))
				handles.append(DeltaHandle.new(element, "cx", "cy", "r", true))
			"ellipse":
				handles.append(XYHandle.new(element, "cx", "cy"))
				handles.append(DeltaHandle.new(element, "cx", "cy", "rx", true))
				handles.append(DeltaHandle.new(element, "cx", "cy", "ry", false))
			"rect":
				handles.append(XYHandle.new(element, "x", "y"))
				handles.append(DeltaHandle.new(element, "x", "y", "width", true))
				handles.append(DeltaHandle.new(element, "x", "y", "height", false))
			"line":
				handles.append(XYHandle.new(element, "x1", "y1"))
				handles.append(XYHandle.new(element, "x2", "y2"))
			"polygon", "polyline":
				handles += generate_polyhandles(element)
			"path":
				handles += generate_path_handles(element)
	# Pretend the mouse was moved to update the hovering.
	HandlerGUI.throw_mouse_motion_event()
	queue_redraw()

func sync_handles(xid: PackedInt32Array) -> void:
	var element := State.root_element.get_xnode(xid)
	if not (element is ElementPath or element is ElementPolygon or element is ElementPolyline):
		queue_redraw()
		return
	
	var new_handles: Array[Handle] = []
	for handle in handles:
		if handle.element != element:
			new_handles.append(handle)
	handles = new_handles
	handles += generate_path_handles(element)
	handles += generate_polyhandles(element)
	# Pretend the mouse was moved to update the hovering.
	HandlerGUI.throw_mouse_motion_event()
	queue_redraw()

func generate_path_handles(element: Element) -> Array[Handle]:
	var data_attrib: AttributePathdata = element.get_attribute("d")
	var path_handles: Array[Handle] = []
	for idx in range(data_attrib.get_command_count() - 1, -1, -1):
		var path_command := data_attrib.get_command(idx)
		if path_command.command_char in "Zz":
			continue
		
		if path_command.command_char in "CcQq":
			var tangent := PathHandle.new(element, idx, "x1", "y1")
			tangent.display_mode = Handle.Display.SMALL
			path_handles.append(tangent)
		if path_command.command_char in "CcSs":
			var tangent := PathHandle.new(element, idx, "x2", "y2")
			tangent.display_mode = Handle.Display.SMALL
			path_handles.append(tangent)
		path_handles.append(PathHandle.new(element, idx, "x", "y"))
	return path_handles

func generate_polyhandles(element: Element) -> Array[Handle]:
	var polyhandles: Array[Handle] = []
	for idx in element.get_attribute("points").get_list_size() / 2:
		polyhandles.append(PolyHandle.new(element, idx))
	return polyhandles


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
	
	for element: Element in State.root_element.get_all_element_descendants():
		# Determine if the element is hovered/selected or has a hovered/selected parent.
		var element_hovered := State.is_hovered(element.xid, -1, true)
		var element_selected := State.is_selected(element.xid, -1, true)
		
		match element.name:
			"circle":
				var c := Vector2(element.get_attribute_num("cx"),
						element.get_attribute_num("cy"))
				var r := element.get_attribute_num("r")
				
				var points := PackedVector2Array()
				points.resize(181)
				for i in 180:
					var d := i * TAU/180
					points[i] = c + Vector2(cos(d), sin(d)) * r
				points[180] = points[0]
				var extras := PackedVector2Array([c, c + Vector2(r, 0)])
				var final_transform := element.get_transform()
				points = final_transform * points
				extras = final_transform * extras
				
				if element_hovered and element_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif element_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif element_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"ellipse":
				var c := Vector2(element.get_attribute_num("cx"),
						element.get_attribute_num("cy"))
				# Squished circle.
				var points := PackedVector2Array()
				points.resize(181)
				for i in 180:
					var d := i * TAU/180
					points[i] = c + Vector2(cos(d) * element.get_rx(), sin(d) * element.get_ry())
				points[180] = points[0]
				var extras := PackedVector2Array([
						c, c + Vector2(element.get_rx(), 0), c, c + Vector2(0, element.get_ry())])
				var final_transform := element.get_transform()
				points = final_transform * points
				extras = final_transform * extras
				
				if element_hovered and element_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif element_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif element_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"rect":
				var x := element.get_attribute_num("x")
				var y := element.get_attribute_num("y")
				var rect_width := element.get_attribute_num("width")
				var rect_height := element.get_attribute_num("height")
				var rx: float = element.get_rx()
				var ry: float = element.get_ry()
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
				var final_transform := element.get_transform()
				points = final_transform * points
				extras = final_transform * extras
				
				if element_hovered and element_selected:
					hovered_selected_polylines.append(points)
					hovered_selected_multiline += extras
				elif element_hovered:
					hovered_polylines.append(points)
					hovered_multiline += extras
				elif element_selected:
					selected_polylines.append(points)
					selected_multiline += extras
				else:
					normal_polylines.append(points)
					normal_multiline += extras
			
			"line":
				var x1 := element.get_attribute_num("x1")
				var y1 := element.get_attribute_num("y1")
				var x2 := element.get_attribute_num("x2")
				var y2 := element.get_attribute_num("y2")
				
				var points := PackedVector2Array([Vector2(x1, y1), Vector2(x2, y2)])
				points = element.get_transform() * points
				
				if element_hovered and element_selected:
					hovered_selected_polylines.append(points)
				elif element_hovered:
					hovered_polylines.append(points)
				elif element_selected:
					selected_polylines.append(points)
				else:
					normal_polylines.append(points)
			
			"polygon", "polyline":
				var point_list := ListParser.list_to_points(element.get_attribute_list("points"))
				
				var current_mode := Utils.InteractionType.NONE
				for idx in range(1, point_list.size()):
					current_mode = Utils.InteractionType.NONE
					if State.is_hovered(element.xid, idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if State.is_selected(element.xid, idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.SELECTED
					
					var points := PackedVector2Array([point_list[idx - 1], point_list[idx]])
					points = element.get_transform() * points
					match current_mode:
						Utils.InteractionType.NONE:
							normal_polylines.append(points)
						Utils.InteractionType.HOVERED:
							hovered_polylines.append(points)
						Utils.InteractionType.SELECTED:
							selected_polylines.append(points)
						Utils.InteractionType.HOVERED_SELECTED:
							hovered_selected_polylines.append(points)
				
				if element.name == "polygon" and point_list.size() > 2:
					current_mode = Utils.InteractionType.NONE
					if State.is_hovered(element.xid, 0, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if State.is_selected(element.xid, 0, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.SELECTED
					
					var points := PackedVector2Array([point_list[-1], point_list[0]])
					points = element.get_transform() * points
					match current_mode:
						Utils.InteractionType.NONE:
							normal_polylines.append(points)
						Utils.InteractionType.HOVERED:
							hovered_polylines.append(points)
						Utils.InteractionType.SELECTED:
							selected_polylines.append(points)
						Utils.InteractionType.HOVERED_SELECTED:
							hovered_selected_polylines.append(points)
			
			"path":
				var pathdata: AttributePathdata = element.get_attribute("d")
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
					if State.is_hovered(element.xid, cmd_idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if State.is_selected(element.xid, cmd_idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.SELECTED
					
					match cmd.command_char.to_upper():
						"L":
							# Line contour.
							var v := Vector2(cmd.x, cmd.y)
							var end := cmd.get_start_coords() + v if relative else v
							points = PackedVector2Array([cmd.get_start_coords(), end])
						"H":
							# Horizontal line contour.
							var v := Vector2(cmd.x, 0)
							var end := cmd.get_start_coords() + v if\
									relative else Vector2(v.x, cmd.start_y)
							points = PackedVector2Array([cmd.get_start_coords(), end])
						"V":
							# Vertical line contour.
							var v := Vector2(0, cmd.y)
							var end := cmd.get_start_coords() + v if\
									relative else Vector2(cmd.start_x, v.y)
							points = PackedVector2Array([cmd.get_start_coords(), end])
						"C":
							# Cubic Bezier curve contour.
							var v := Vector2(cmd.x, cmd.y)
							var v1 := Vector2(cmd.x1, cmd.y1)
							var v2 := Vector2(cmd.x2, cmd.y2)
							var cp1 := cmd.get_start_coords()
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
							
							var cp1 := cmd.get_start_coords()
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
							var cp1 := cmd.get_start_coords()
							var cp2 := cp1 + v1 if relative else v1
							var cp3 := cp1 + v if relative else v
							
							points = Utils.get_quadratic_bezier_points(cp1, cp2, cp3)
							tangent_points.append_array(PackedVector2Array([cp1, cp2, cp2, cp3]))
						"T":
							# Shorthand quadratic Bezier curve contour.
							var v := Vector2(cmd.x, cmd.y)
							var v1 := pathdata.get_implied_T_control(cmd_idx)
							
							var cp1 := cmd.get_start_coords()
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
							var start := cmd.get_start_coords()
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
								end += prev_M_cmd.get_start_coords()
							
							points = PackedVector2Array([cmd.get_start_coords(), end])
						"M":
							continue
					
					var final_transform := element.get_transform()
					points = final_transform * points
					tangent_points = final_transform * tangent_points
					match current_mode:
						Utils.InteractionType.NONE:
							normal_polylines.append(points)
							normal_multiline += tangent_points
						Utils.InteractionType.HOVERED:
							hovered_polylines.append(points)
							hovered_multiline += tangent_points
						Utils.InteractionType.SELECTED:
							selected_polylines.append(points)
							selected_multiline += tangent_points
						Utils.InteractionType.HOVERED_SELECTED:
							hovered_selected_polylines.append(points)
							hovered_selected_multiline += tangent_points
	
	draw_set_transform_matrix(State.root_element.canvas_transform)
	RenderingServer.canvas_item_set_transform(surface, Transform2D(0.0,
			Vector2(1, 1) / State.zoom, 0.0, Vector2.ZERO))
	
	# First gather all handles in 4 categories, to then draw them in the right order.
	var normal_handles: Array[Handle] = []
	var selected_handles: Array[Handle] = []
	var hovered_handles: Array[Handle] = []
	var hovered_selected_handles: Array[Handle] = []
	for handle in handles:
		var inner_idx := -1
		if handle is PathHandle:
			inner_idx = handle.command_index
		elif handle is PolyHandle:
			inner_idx = handle.point_index
		var is_hovered := State.is_hovered(handle.element.xid, inner_idx, true)
		var is_selected := State.is_selected(handle.element.xid, inner_idx, true)
		
		if is_hovered and is_selected:
			hovered_selected_handles.append(handle)
		elif is_hovered:
			hovered_handles.append(handle)
		elif is_selected:
			selected_handles.append(handle)
		else:
			normal_handles.append(handle)
	
	RenderingServer.canvas_item_clear(surface)
	RenderingServer.canvas_item_clear(selections_surface)
	
	draw_objects_of_type(normal_color, normal_polylines,
			normal_multiline, normal_handles, normal_handle_textures)
	draw_objects_of_type(hovered_color, hovered_polylines,
			hovered_multiline, hovered_handles, hovered_handle_textures)
	draw_objects_of_type(selected_color, selected_polylines,
			selected_multiline, selected_handles, selected_handle_textures)
	draw_objects_of_type(hovered_selected_color, hovered_selected_polylines,
			hovered_selected_multiline, hovered_selected_handles,
			hovered_selected_handle_textures)
	
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element() and DB.is_attribute_recognized(xnode.name, "transform"):
			var bounding_box: Rect2 = xnode.get_bounding_box()
			if bounding_box.has_area():
				RenderingServer.canvas_item_add_set_transform(selections_surface,
						State.root_element.canvas_transform * xnode.get_transform())
				var grow_amount := Vector2(4, 4) / State.zoom
				grow_amount /= State.root_element.canvas_transform.get_scale()
				grow_amount /= xnode.get_transform().get_scale()
				RenderingServer.canvas_item_add_rect(selections_surface,
						bounding_box.grow_individual(grow_amount.x, grow_amount.y,
						grow_amount.x, grow_amount.y), Color.WHITE)

func draw_objects_of_type(color: Color, polylines: Array[PackedVector2Array],
multiline: PackedVector2Array, handles_array: Array[Handle],
handle_texture_dictionary: Dictionary[Handle.Display, Texture2D]) -> void:
	for polyline in polylines:
		var color_array := PackedColorArray()
		color_array.resize(polyline.size())
		color_array.fill(color)
		for idx in polyline.size():
			polyline[idx] = State.root_element.canvas_to_world(polyline[idx]) * State.zoom
		RenderingServer.canvas_item_add_polyline(surface, polyline,
				color_array, CONTOUR_WIDTH, true)
	if not multiline.is_empty():
		for idx in multiline.size():
			multiline[idx] = State.root_element.canvas_to_world(multiline[idx]) * State.zoom
		var color_array := PackedColorArray()
		color_array.resize(int(multiline.size() / 2.0))
		color_array.fill(Color(color, TANGENT_ALPHA))
		RenderingServer.canvas_item_add_multiline(surface, multiline,
				color_array, TANGENT_WIDTH, true)
	for handle in handles_array:
		var texture := handle_texture_dictionary[handle.display_mode]
		texture.draw(surface, State.root_element.canvas_to_world(
				handle.transform * handle.pos) * State.zoom - texture.get_size() / 2)


var dragged_handle: Handle = null
var hovered_handle: Handle = null
var was_handle_moved := false
var should_deselect_all := false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		hovered_handle = null
		State.clear_all_hovered()
		return
	
	# Set the nearest handle as hovered, if any handles are within range.
	if (event is InputEventMouseMotion and !is_instance_valid(dragged_handle) and\
	event.button_mask == 0) or (event is InputEventMouseButton and\
	(event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_DOWN,
	MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT])):
		var nearest_handle := find_nearest_handle(event.position / State.zoom +\
				get_parent().view.position)
		if is_instance_valid(nearest_handle):
			hovered_handle = nearest_handle
			if hovered_handle is PathHandle:
				State.set_hovered(hovered_handle.element.xid, hovered_handle.command_index)
			elif hovered_handle is PolyHandle:
				State.set_hovered(hovered_handle.element.xid, hovered_handle.point_index)
			else:
				State.set_hovered(hovered_handle.element.xid)
		else:
			hovered_handle = null
			State.clear_all_hovered()
	
	if event is InputEventMouseMotion:
		# Allow moving view while dragging handle.
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			return
		
		should_deselect_all = false
		if is_instance_valid(dragged_handle):
			# Move the handle that's being dragged.
			var event_pos := get_event_pos(event)
			var new_pos := Utils64Bit.transform_vector_mult(
					Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
					State.root_element.world_to_canvas_64_bit(event_pos))
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			accept_event()
	elif event is InputEventMouseButton:
		var event_pos := get_event_pos(event)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# React to LMB actions.
			if is_instance_valid(hovered_handle) and event.is_pressed():
				dragged_handle = hovered_handle
				var inner_idx := -1
				var dragged_xid := dragged_handle.element.xid
				if dragged_handle is PathHandle:
					inner_idx = dragged_handle.command_index
				if dragged_handle is PolyHandle:
					inner_idx = dragged_handle.point_index
				
				if event.double_click and inner_idx != -1:
					# Unselect the element, so then it's selected again in the subpath.
					if dragged_handle is PathHandle:
						var subpath_range: Vector2i =\
								dragged_handle.element.get_attribute("d").get_subpath(inner_idx)
						State.normal_select(dragged_xid, subpath_range.x)
						State.shift_select(dragged_xid, subpath_range.y)
					elif dragged_handle is PolyHandle:
						State.normal_select(dragged_xid, 0)
						State.shift_select(dragged_xid,
								dragged_handle.element.get_attribute("points").get_list_size() / 2)
				elif event.is_command_or_control_pressed():
					State.ctrl_select(dragged_xid, inner_idx)
				elif event.shift_pressed:
					State.shift_select(dragged_xid, inner_idx)
				else:
					State.normal_select(dragged_xid, inner_idx)
			elif is_instance_valid(dragged_handle) and event.is_released():
				if was_handle_moved:
					var new_pos := Utils64Bit.transform_vector_mult(
							Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
							State.root_element.world_to_canvas_64_bit(event_pos))
					dragged_handle.set_pos(new_pos)
					State.queue_svg_save()
					was_handle_moved = false
				dragged_handle = null
			elif !is_instance_valid(hovered_handle) and event.is_pressed():
				should_deselect_all = true
			elif !is_instance_valid(hovered_handle) and event.is_released() and should_deselect_all:
				dragged_handle = null
				State.clear_all_selections()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			var vp := get_viewport()
			var popup_pos := vp.get_mouse_position()
			if !is_instance_valid(hovered_handle):
				State.clear_all_selections()
				HandlerGUI.popup_under_pos(create_element_context(
						State.root_element.world_to_canvas_64_bit(event_pos)), popup_pos, vp)
			else:
				var hovered_xid := hovered_handle.element.xid
				var inner_idx := -1
				if hovered_handle is PathHandle:
					inner_idx = hovered_handle.command_index
				if hovered_handle is PolyHandle:
					inner_idx = hovered_handle.point_index
				
				if not (State.semi_selected_xid == hovered_xid and\
				inner_idx in State.inner_selections) and\
				not (inner_idx == -1 and hovered_xid in State.selected_xids):
					State.normal_select(hovered_xid, inner_idx)
				
				HandlerGUI.popup_under_pos(State.get_selection_context(
						HandlerGUI.popup_under_pos.bind(popup_pos, vp),
						State.Context.VIEWPORT), popup_pos, vp)

func find_nearest_handle(event_pos: Vector2) -> Handle:
	var nearest_handle: Handle = null
	var nearest_dist_squared := DEFAULT_GRAB_DISTANCE_SQUARED *\
			(Configs.savedata.handle_size * Configs.savedata.handle_size) /\
			(State.zoom * State.zoom)
	for handle in handles:
		var dist_to_handle_squared := event_pos.distance_squared_to(
					State.root_element.canvas_to_world(handle.transform * handle.pos))
		if dist_to_handle_squared < nearest_dist_squared:
			nearest_dist_squared = dist_to_handle_squared
			nearest_handle = handle
	return nearest_handle

# Two 64-bit coordinates instead of a Vector2.
func get_event_pos(event: InputEvent) -> PackedFloat64Array:
	return apply_snap(event.position / State.zoom + get_parent().view.position)

func apply_snap(pos: Vector2) -> PackedFloat64Array:
	var precision_snap := 0.1 ** maxi(ceili(-log(1.0 / State.zoom) / log(10)), 0)
	var configured_snap := absf(Configs.savedata.snap)
	var snap_size: float  # To be used for the snap.
	
	# If the snap is disabled, or the precision snap is bigger than the configured snap
	# and a multiple of it, use the precision snap. Otherwise use the user-configured snap.
	if Configs.savedata.snap < 0.0 or (precision_snap > configured_snap and\
	is_zero_approx(fmod(precision_snap, configured_snap))):
		snap_size = precision_snap
	else:
		snap_size = configured_snap
	
	return PackedFloat64Array([snappedf(pos.x, snap_size), snappedf(pos.y, snap_size)])


func _on_handle_added() -> void:
	if not get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		if not State.semi_selected_xid.is_empty():
			State.root_element.get_xnode(State.semi_selected_xid).get_attribute("d").\
					sync_after_commands_change()
			State.queue_svg_save()
		return
	
	update_handles()
	var first_inner_selection := State.inner_selections[0]
	if State.root_element.get_xnode(State.semi_selected_xid).get_attribute("d").\
	get_commands()[first_inner_selection].command_char in "Zz":
		State.queue_svg_save()
		return
	
	for handle in handles:
		if handle is PathHandle and handle.element.xid == State.semi_selected_xid and\
		handle.command_index == first_inner_selection:
			State.set_hovered(handle.element.xid, handle.command_index)
			dragged_handle = handle
			# Move the handle that's being dragged.
			var mouse_pos := apply_snap(get_global_mouse_position())
			var new_pos := Utils64Bit.transform_vector_mult(
					Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
					State.root_element.world_to_canvas_64_bit(mouse_pos))
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			return

# Creates a popup for adding a shape at a position.
func create_element_context(precise_pos: PackedFloat64Array) -> ContextPopup:
	var btn_array: Array[Button] = []
	for shape in ["path", "circle", "ellipse", "rect", "line", "polygon", "polyline"]:
		var btn := ContextPopup.create_button(shape,
				add_shape_at_pos.bind(shape, precise_pos), false, DB.get_element_icon(shape))
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_array.append(btn)
	var element_context := ContextPopup.new()
	element_context.setup_with_title(btn_array, Translator.translate("New shape"),
			true, -1, -1, PackedInt32Array([1, 4]))
	return element_context

func add_shape_at_pos(element_name: String, precise_pos: PackedFloat64Array) -> void:
	State.root_element.add_xnode(DB.element_with_setup(element_name, [precise_pos]),
			PackedInt32Array([State.root_element.get_child_count()]))
	State.queue_svg_save()
