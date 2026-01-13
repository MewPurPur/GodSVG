# This script manages contour drawing and handles.
extends Control

var handle_textures: ImageTexture
var atlas_textures: Dictionary[Utils.InteractionType, Dictionary] = {}
var handle_size: float
var half_handle_size: float

const stroke_shader = preload("res://src/shaders/animated_stroke.gdshader")
const stroke_shader_static = preload("res://src/shaders/animated_stroke_static.gdshader")

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

# FIXME this shouldn't be needed, but otherwise the shader doesn't want to work.
var animated_stroke_hacky_fix_node := Control.new()

var canvas: Canvas


func _exit_tree() -> void:
	RenderingServer.free_rid(surface)
	RenderingServer.free_rid(selections_surface)

# Generate the procedural handle textures.
func render_handle_textures() -> void:
	normal_color = Configs.savedata.handle_color
	hovered_color = Configs.savedata.handle_hovered_color
	selected_color = Configs.savedata.handle_selected_color
	hovered_selected_color = Configs.savedata.handle_hovered_selected_color
	var inner_color_string := "#" + Configs.savedata.handle_inner_color.to_html(false)
	
	var outer_color_strings: PackedStringArray = [
		"#" + Configs.savedata.handle_color.to_html(false),
		"#" + Configs.savedata.handle_hovered_color.to_html(false),
		"#" + Configs.savedata.handle_selected_color.to_html(false),
		"#" + Configs.savedata.handle_hovered_selected_color.to_html(false),
	]
	
	var atlas_svg_markup := """<svg width="20" height="40" xmlns="http://www.w3.org/2000/svg">"""
	for i in outer_color_strings.size():
		var outer_color_string := outer_color_strings[i]
		atlas_svg_markup += """<circle cx="5" cy="%d" r="3.25" stroke-width="1.5" fill="%s" stroke="%s"/>""" % [5 + i * 10, inner_color_string, outer_color_string]
		atlas_svg_markup += """<circle cx="15" cy="%d" r="2.4" stroke-width="1.2" fill="%s" stroke="%s"/>""" % [5 + i * 10, inner_color_string, outer_color_string]
	atlas_svg_markup += "</svg>"
	
	var img := Image.new()
	img.load_svg_from_string(atlas_svg_markup, Configs.savedata.handle_size)
	img.fix_alpha_edges()
	handle_textures = ImageTexture.create_from_image(img)
	
	handle_size = Configs.savedata.handle_size * 10.0
	half_handle_size = handle_size / 2.0
	atlas_textures.clear()
	for i in Handle.Display.size():
		for ii in Utils.InteractionType.size():
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = handle_textures
			atlas_texture.region = Rect2(i * handle_size, ii * handle_size, handle_size, handle_size)
			if not atlas_textures.has(ii):
				atlas_textures[ii] = {}
			atlas_textures[ii][i] = atlas_texture
	queue_redraw()

func sync_selection_rectangle_shader() -> void:
	var stroke_material := ShaderMaterial.new()
	if is_zero_approx(Configs.savedata.selection_rectangle_speed):
		stroke_material.shader = stroke_shader_static
	else:
		stroke_material.shader = stroke_shader
		stroke_material.set_shader_parameter("ant_speed", Configs.savedata.selection_rectangle_speed)
	
	stroke_material.set_shader_parameter("ant_color_1", Configs.savedata.selection_rectangle_color1)
	stroke_material.set_shader_parameter("ant_color_2", Configs.savedata.selection_rectangle_color2)
	stroke_material.set_shader_parameter("ant_width", Configs.savedata.selection_rectangle_width)
	stroke_material.set_shader_parameter("ant_length", Configs.savedata.selection_rectangle_dash_length)
	RenderingServer.canvas_item_set_material(selections_surface, stroke_material.get_rid())
	animated_stroke_hacky_fix_node.material = stroke_material
	# If the ant width was changed, the buffer must be updated.
	queue_redraw()

func _ready() -> void:
	add_child(animated_stroke_hacky_fix_node, false, InternalMode.INTERNAL_MODE_BACK)
	
	Configs.handle_visuals_changed.connect(render_handle_textures)
	render_handle_textures()
	Configs.selection_rectangle_visuals_changed.connect(sync_selection_rectangle_shader)
	sync_selection_rectangle_shader()
	
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_parent(selections_surface, get_canvas_item())
	
	State.any_attribute_changed.connect(sync_handles)
	State.xnode_layout_changed.connect(queue_update_handles)
	State.svg_unknown_change.connect(queue_update_handles)
	State.selection_changed.connect(queue_redraw)
	State.hover_changed.connect(queue_redraw)
	canvas.camera_zoom_changed.connect(queue_redraw)
	State.handle_added.connect(_on_handle_added)
	queue_update_handles()
	update_show_handles()


func update_show_handles() -> void:
	visible = canvas.show_handles
	HandlerGUI.throw_mouse_motion_event()

func queue_update_handles() -> void:
	update_handles.call_deferred()
	_handles_update_pending = true

func update_handles() -> void:
	if not _handles_update_pending:
		return
	
	_handles_update_pending = false
	handles.clear()
	for element in canvas.root_element.get_all_valid_element_descendants():
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
			"use":
				handles.append(XYHandle.new(element, "x", "y"))
			"polygon", "polyline":
				handles += generate_polyhandles(element)
			"path":
				handles += generate_path_handles(element)
	# Pretend the mouse was moved to update the hovering.
	HandlerGUI.throw_mouse_motion_event()
	queue_redraw()

func sync_handles(xid: PackedInt32Array) -> void:
	var element := canvas.root_element.get_xnode(xid)
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
	for idx: int in element.get_attribute("points").get_list_size() / 2:
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
	# Store bounding rects and the transforms needed for them.
	var selection_transforms: Array[Transform2D] = []
	var selection_rects: Array[Rect2] = []
	
	for element: Element in canvas.root_element.get_all_valid_element_descendants():
		# Determine if the element is hovered/selected or has a hovered/selected parent.
		var element_hovered := canvas.is_hovered(element.xid, -1, true)
		var element_selected := canvas.is_selected(element.xid, -1, true)
		
		match element.name:
			"circle":
				var c := Vector2(element.get_attribute_num("cx"), element.get_attribute_num("cy"))
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
				
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
			
			"ellipse":
				var c := Vector2(element.get_attribute_num("cx"), element.get_attribute_num("cy"))
				# Squished circle.
				var points := PackedVector2Array()
				points.resize(181)
				for i in 180:
					var d := i * TAU/180
					points[i] = c + Vector2(cos(d) * element.get_rx(), sin(d) * element.get_ry())
				points[180] = points[0]
				var extras := PackedVector2Array([c, c + Vector2(element.get_rx(), 0), c, c + Vector2(0, element.get_ry())])
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
				
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
			
			"rect":
				var x := element.get_attribute_num("x")
				var y := element.get_attribute_num("y")
				var rect_width := element.get_attribute_num("width")
				var rect_height := element.get_attribute_num("height")
				var rx: float = element.get_rx()
				var ry: float = element.get_ry()
				var points := PackedVector2Array()
				if rx == 0 or ry == 0:
					# Basic rectangle.
					points = [Vector2(x, y), Vector2(x + rect_width, y), Vector2(x + rect_width, y + rect_height), Vector2(x, y + rect_height), Vector2(x, y)]
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
						points[i - 133] = Vector2(x + rect_width - rx, y + ry) + Vector2(cos(d) * rx, sin(d) * ry)
					points[47] =  Vector2(x + rect_width, y + rect_height - ry)
					for i in range(0, 45):
						var d := i * TAU/180
						points[i + 48] = Vector2(x + rect_width - rx, y + rect_height - ry) + Vector2(cos(d) * rx, sin(d) * ry)
					points[93] = Vector2(x + rx, y + rect_height)
					for i in range(45, 90):
						var d := i * TAU/180
						points[i + 49] = Vector2(x + rx, y + rect_height - ry) + Vector2(cos(d) * rx, sin(d) * ry)
					points[139] = Vector2(x, y + ry)
					for i in range(90, 135):
						var d := i * TAU/180
						points[i + 50] = Vector2(x + rx, y + ry) + Vector2(cos(d) * rx, sin(d) * ry)
					points[185] = points[0]
				var extras := PackedVector2Array([Vector2(x, y), Vector2(x + rect_width, y), Vector2(x, y), Vector2(x, y + rect_height)])
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
				
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
			
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
				
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
			
			"polygon", "polyline":
				var point_list := ListParser.list_to_points(element.get_attribute_list("points"))
				
				var current_mode := Utils.InteractionType.NONE
				for idx in range(1, point_list.size()):
					current_mode = Utils.InteractionType.NONE
					if canvas.is_hovered(element.xid, idx, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if canvas.is_selected(element.xid, idx, true):
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
					if canvas.is_hovered(element.xid, 0, true):
						@warning_ignore("int_as_enum_without_cast")
						current_mode += Utils.InteractionType.HOVERED
					if canvas.is_selected(element.xid, 0, true):
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
				
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
			
			"path":
				SVGPathUtils.get_path_element_points(
					element,
					normal_polylines,
					normal_multiline,
					SVGPathUtils.default_path_generator,
					hovered_polylines,
					hovered_multiline,
					selected_polylines,
					selected_multiline,
					hovered_selected_polylines,
					hovered_selected_multiline,
					canvas,
				)
				if element_selected:
					var bounding_box: Rect2 = element.get_bounding_box()
					if bounding_box.has_area():
						var element_transform := element.get_transform()
						var canvas_transform := canvas.root_element.canvas_transform
						var canvas_scale := canvas_transform.get_scale().x
						var element_scale := element_transform.get_scale()
						var grow_amount_unscaled := (2.0 + Configs.savedata.selection_rectangle_width) / canvas.camera_zoom / canvas_scale
						var grow_amount_x := grow_amount_unscaled / element_scale.x
						var grow_amount_y := grow_amount_unscaled / element_scale.y
						selection_transforms.append(canvas_transform * element_transform)
						selection_rects.append(bounding_box.grow_individual(grow_amount_x, grow_amount_y, grow_amount_x, grow_amount_y))
	
	draw_set_transform_matrix(canvas.root_element.canvas_transform)
	RenderingServer.canvas_item_set_transform(surface, Transform2D(0.0, Vector2(1, 1) / canvas.camera_zoom, 0.0, Vector2.ZERO))
	
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
		var is_hovered := canvas.is_hovered(handle.element.xid, inner_idx, true)
		var is_selected := canvas.is_selected(handle.element.xid, inner_idx, true)
		
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
	
	draw_objects_of_interaction_type(normal_color, normal_polylines, normal_multiline, normal_handles, atlas_textures[Utils.InteractionType.NONE])
	draw_objects_of_interaction_type(hovered_color, hovered_polylines, hovered_multiline, hovered_handles, atlas_textures[Utils.InteractionType.HOVERED])
	draw_objects_of_interaction_type(selected_color, selected_polylines, selected_multiline, selected_handles, atlas_textures[Utils.InteractionType.SELECTED])
	draw_objects_of_interaction_type(hovered_selected_color, hovered_selected_polylines, hovered_selected_multiline, hovered_selected_handles,
			atlas_textures[Utils.InteractionType.HOVERED_SELECTED])
	
	for idx in selection_rects.size():
		RenderingServer.canvas_item_add_set_transform(selections_surface, selection_transforms[idx])
		RenderingServer.canvas_item_add_rect(selections_surface, selection_rects[idx], Color.WHITE)

func draw_objects_of_interaction_type(color: Color, polylines: Array[PackedVector2Array], multiline: PackedVector2Array,
handles_array: Array[Handle], atlas_textures_dict: Dictionary) -> void:
	for polyline in polylines:
		var color_array := PackedColorArray()
		color_array.resize(polyline.size())
		color_array.fill(color)
		for idx in polyline.size():
			polyline[idx] = canvas.root_element.canvas_to_world(polyline[idx]) * canvas.camera_zoom
		RenderingServer.canvas_item_add_polyline(surface, polyline, color_array, CONTOUR_WIDTH, true)
	if not multiline.is_empty():
		for idx in multiline.size():
			multiline[idx] = canvas.root_element.canvas_to_world(multiline[idx]) * canvas.camera_zoom
		var color_array := PackedColorArray()
		color_array.resize(int(multiline.size() / 2.0))
		color_array.fill(Color(color, TANGENT_ALPHA))
		RenderingServer.canvas_item_add_multiline(surface, multiline, color_array, TANGENT_WIDTH, true)
	for handle in handles_array:
		atlas_textures_dict[handle.display_mode].draw(surface,
				canvas.root_element.canvas_to_world(handle.transform * handle.pos) * canvas.camera_zoom - Vector2(half_handle_size, half_handle_size))


var dragged_handle: Handle = null
var hovered_handle: Handle = null
var was_handle_moved := false
var should_deselect_all := false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		dragged_handle = null
		hovered_handle = null
		# Mouse events on the viewport clear hovered, but other events don't.
		if ((event is InputEventMouseMotion and event.button_mask == 0) or\
		(event is InputEventMouseButton and (event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]))):
			State.clear_all_hovered()
	
	# Set the nearest handle as hovered, if any handles are within range.
	if visible and ((event is InputEventMouseMotion and not is_instance_valid(dragged_handle) and event.button_mask == 0) or\
	(event is InputEventMouseButton and (event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]))):
		var nearest_handle := find_nearest_handle(event.position / canvas.camera_zoom + canvas.get_camera_position())
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
		if visible and is_instance_valid(dragged_handle):
			# Move the handle that's being dragged.
			var event_pos := get_event_pos(event)
			var new_pos := Utils64Bit.transform_vector_mult(
					Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
					canvas.root_element.world_to_canvas_64_bit(event_pos))
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			accept_event()
	elif event is InputEventMouseButton:
		var event_pos := get_event_pos(event)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			# React to LMB actions.
			if visible and is_instance_valid(hovered_handle) and event.is_pressed():
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
						var subpath_range: Vector2i = dragged_handle.element.get_attribute("d").get_subpath(inner_idx)
						State.normal_select(dragged_xid, subpath_range.x)
						State.shift_select(dragged_xid, subpath_range.y)
					elif dragged_handle is PolyHandle:
						State.normal_select(dragged_xid, 0)
						State.shift_select(dragged_xid, dragged_handle.element.get_attribute("points").get_list_size() / 2 - 1)
				elif event.is_command_or_control_pressed():
					State.ctrl_select(dragged_xid, inner_idx)
				elif event.shift_pressed:
					State.shift_select(dragged_xid, inner_idx)
				else:
					State.normal_select(dragged_xid, inner_idx)
			elif visible and is_instance_valid(dragged_handle) and event.is_released():
				if was_handle_moved:
					var new_pos := Utils64Bit.transform_vector_mult(
							Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
							canvas.root_element.world_to_canvas_64_bit(event_pos))
					dragged_handle.set_pos(new_pos)
					State.save_svg()
					was_handle_moved = false
				dragged_handle = null
			elif not is_instance_valid(hovered_handle) and event.is_pressed():
				should_deselect_all = true
			elif not is_instance_valid(hovered_handle) and event.is_released() and should_deselect_all:
				dragged_handle = null
				State.clear_all_selections()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			var vp := get_viewport()
			var popup_pos := vp.get_mouse_position()
			if not is_instance_valid(hovered_handle):
				State.clear_all_selections()
				HandlerGUI.popup_under_pos(create_element_context(
						canvas.root_element.world_to_canvas_64_bit(event_pos)), popup_pos, vp)
			elif visible:
				var hovered_xid := hovered_handle.element.xid
				var inner_idx := -1
				if hovered_handle is PathHandle:
					inner_idx = hovered_handle.command_index
				if hovered_handle is PolyHandle:
					inner_idx = hovered_handle.point_index
				
				if not (State.semi_selected_xid == hovered_xid and inner_idx in State.inner_selections) and\
				not (inner_idx == -1 and hovered_xid in State.selected_xids):
					State.normal_select(hovered_xid, inner_idx)
				
				HandlerGUI.popup_under_pos(State.get_selection_context(HandlerGUI.popup_under_pos.bind(popup_pos, vp), Utils.LayoutPart.VIEWPORT), popup_pos, vp)

func find_nearest_handle(event_pos: Vector2) -> Handle:
	var nearest_handle: Handle = null
	var nearest_dist_squared := DEFAULT_GRAB_DISTANCE_SQUARED * (Configs.savedata.handle_size / canvas.camera_zoom) ** 2
	for handle in handles:
		var dist_to_handle_squared := event_pos.distance_squared_to(canvas.root_element.canvas_to_world(handle.transform * handle.pos))
		if dist_to_handle_squared < nearest_dist_squared:
			nearest_dist_squared = dist_to_handle_squared
			nearest_handle = handle
	return nearest_handle

# Two 64-bit coordinates instead of a Vector2.
func get_event_pos(event: InputEvent) -> PackedFloat64Array:
	return apply_snap(event.position / canvas.camera_zoom + canvas.get_camera_position())

func apply_snap(pos: Vector2) -> PackedFloat64Array:
	var precision_snap := 0.1 ** maxi(ceili(-log(1.0 / canvas.camera_zoom) / log(10)), 0)
	var configured_snap := absf(Configs.savedata.snap)
	var snap_size: float  # To be used for the snap.
	
	# If the snap is disabled, or the precision snap is bigger than the configured snap
	# and a multiple of it, use the precision snap. Otherwise use the user-configured snap.
	if Configs.savedata.snap < 0.0 or (precision_snap > configured_snap and is_zero_approx(fmod(precision_snap, configured_snap))):
		snap_size = precision_snap
	else:
		snap_size = configured_snap
	
	return PackedFloat64Array([snappedf(pos.x, snap_size), snappedf(pos.y, snap_size)])


func _on_handle_added() -> void:
	if not get_viewport_rect().has_point(get_viewport().get_mouse_position()):
		if not State.semi_selected_xid.is_empty():
			canvas.root_element.get_xnode(State.semi_selected_xid).get_attribute("d").sync_after_commands_change()
			State.save_svg()
		return
	
	update_handles()
	var first_inner_selection := State.inner_selections[0]
	if canvas.root_element.get_xnode(State.semi_selected_xid).get_attribute("d").get_commands()[first_inner_selection].command_char in "Zz":
		dragged_handle = null
		State.save_svg()
		return
	
	for handle in handles:
		if handle is PathHandle and handle.element.xid == State.semi_selected_xid and handle.command_index == first_inner_selection:
			State.set_hovered(handle.element.xid, handle.command_index)
			dragged_handle = handle
			# Move the handle that's being dragged.
			var mouse_pos := apply_snap(get_global_mouse_position())
			var new_pos := Utils64Bit.transform_vector_mult(Utils64Bit.get_transform_affine_inverse(dragged_handle.precise_transform),
					canvas.root_element.world_to_canvas_64_bit(mouse_pos))
			dragged_handle.set_pos(new_pos)
			was_handle_moved = true
			return

# Creates a popup for adding a shape at a position.
func create_element_context(precise_pos: PackedFloat64Array) -> ContextPopup:
	var btn_arr: Array[ContextButton] = []
	const CONST_ARR: PackedStringArray = ["path", "circle", "ellipse", "rect", "line", "polygon", "polyline"]
	for shape in CONST_ARR:
		var btn := ContextButton.create_custom(shape, add_shape_at_pos.bind(shape, precise_pos), DB.get_element_icon(shape))
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
		btn_arr.append(btn)
	var element_context := ContextPopup.create_with_title(btn_arr, Translator.translate("New shape"), true, -1, PackedInt32Array([1, 4]))
	return element_context

func add_shape_at_pos(element_name: String, precise_pos: PackedFloat64Array) -> void:
	canvas.root_element.add_xnode(DB.element_with_setup(element_name, [precise_pos]), PackedInt32Array([canvas.root_element.get_child_count()]))
	State.save_svg()
