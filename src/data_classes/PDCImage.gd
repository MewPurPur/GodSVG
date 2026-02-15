## A representation of a [url=https://developer.rebble.io/guides/app-resources/pdc-format/]Pebble Draw Command[/url] file.
## [br][br]
## The Pebble Draw Command format is a bespoke vector image format designed for the PebbleOS smartwatch firmware, made for
## efficient storage and drawing.
## PDCImage supports loading a binary file with [method load_from_pdc], converting them to SVGs with [method to_svg], and
## converting SVGs to PDCs with [method load_from_svg]. It doesn't support image sequences, only stills.
## [br][br]
## To convert an in-memory [PDCImage] to a binary file, use [method encode].
## [br][br]
## Implementation based on the specification at [url]https://developer.rebble.io/guides/app-resources/pdc-format/[/url] and
## [url=https://github.com/pebble-examples/cards-example/blob/master/tools/svg2pdc.py]svg2pdc.py[/url].
class_name PDCImage

## Don't change, see [url]https://developer.rebble.io/guides/app-resources/pdc-format/#pebble-draw-command-image[/url] offset 8.
const DRAW_COMMAND_VERSION = 1

enum DrawType {
	INVALID,
	PATH,
	CIRCLE,
	PRECISE_PATH,
}

enum DrawFlags {
	NONE = 0,
	HIDDEN = 1 << 0,
	# Bits 2-8 are reserved
}

enum PrecisePathMode {
	AUTODETECT,
	ONLY_PRECISE_PATHS,
	ONLY_IMPRECISE_PATHS,
}

enum PDCLoadingError {
	OK,
	UNKNOWN,
	INVALID_MAGIC_WORD,
}

var size: Vector2i
var path_angle_tolerance: float = 10.0
var precise_path_mode: PrecisePathMode
var viewbox_transform: Transform2D

var draw_commands: Array[PebbleCommand]

func _init(_size: Vector2i = Vector2i.ZERO) -> void:
	size = _size


func encode() -> PackedByteArray:
	# Magic word
	var buffer := "PDCI".to_ascii_buffer()
	# Buffer size, to be filled in later
	var size_byte_offset = buffer.size()
	buffer.resize(8)
	
	var encoded_commands := _encode_image()
	buffer.append_array(encoded_commands)
	
	buffer.encode_u32(size_byte_offset, encoded_commands.size())
	
	return buffer


func _encode_image() -> PackedByteArray:
	var buffer: PackedByteArray
	buffer.resize(8)
	buffer.encode_u8(0, DRAW_COMMAND_VERSION)
	# Must be 0 for some reason
	buffer.encode_u8(1, 0)
	# View size
	buffer.encode_s16(2, size.x)
	buffer.encode_s16(4, size.y)
	
	buffer.encode_u16(6, draw_commands.size())
	for command in draw_commands:
		buffer.append_array(command.encode())
	return buffer


const _DRAW_TYPE_DISPATCHER: Dictionary[DrawType, Script] = {
	DrawType.PATH: PebblePathCommand,
	DrawType.CIRCLE: PebbleCircleCommand,
	DrawType.PRECISE_PATH: PebblePrecisePathCommand,
}


func load_from_pdc(pdc: PackedByteArray) -> PDCLoadingError:
	var sp := StreamPeerBuffer.new()
	sp.data_array = pdc
	# 4 chars * 1 byte / char = 32 bits
	if sp.get_u32() != "PDCI".to_ascii_buffer().decode_u32(0):
		return PDCLoadingError.INVALID_MAGIC_WORD
	var _buffer_size := sp.get_u32()
	if sp.get_u8() != DRAW_COMMAND_VERSION:
		return PDCLoadingError.UNKNOWN
	if sp.get_u8() != 0:
		return PDCLoadingError.UNKNOWN
	size = Vector2i(
		sp.get_16(),
		sp.get_16(),
	)
	var draw_command_size := sp.get_u16()
	for i in draw_command_size:
		var type := sp.get_u8() as DrawType
		var flags := sp.get_u8() as DrawFlags
		var stroke_color := sp.get_u8()
		var stroke_width := sp.get_u8()
		var fill_color := sp.get_u8()
		var path_open_or_radius := sp.get_u16()
		var points_length := sp.get_u16()
		var cmd: PebbleCommand = _DRAW_TYPE_DISPATCHER[type].new()
		var starting_cursor := sp.get_position()
		cmd.decode(sp, points_length, path_open_or_radius)
		assert(sp.get_position() - starting_cursor == points_length * 4)
		cmd.stroke_color = stroke_color
		cmd.stroke_width = stroke_width
		cmd.fill_color = fill_color
		cmd.flags = flags
		add_command(cmd)
	return PDCLoadingError.OK

func add_command(command: PebbleCommand) -> void:
	draw_commands.append(command)


func add_commands(commands: Array[PebbleCommand]) -> void:
	draw_commands.append_array(commands)


@abstract class PebbleCommand:
	var stroke_color: int
	var stroke_width: float
	var fill_color: int
	var flags: DrawFlags

	func encode() -> PackedByteArray:
		var buffer: PackedByteArray
		buffer.resize(9)
		# Command type
		buffer.encode_u8(0, get_type())
		# Command flags
		buffer.encode_u8(1, flags)
		# Command stroke color
		buffer.encode_u8(2, stroke_color)
		# Command stroke width (unsigned byte)
		buffer.encode_u8(3, int(stroke_width))
		buffer.encode_u8(4, fill_color)
		buffer.encode_u16(5, get_path_open_or_radius())
		var encoded_points := encode_points(get_points())
		buffer.encode_u16(7, encoded_points.size() / 4)
		buffer.append_array(encoded_points)
		return buffer
	
	@abstract func get_type() -> DrawType
	@abstract func get_points() -> PackedVector2Array
	@abstract func get_path_open_or_radius() -> int

	func encode_points(points: PackedVector2Array) -> PackedByteArray:
		var buf: PackedByteArray
		# Allocate 4 bytes per point
		buf.resize(points.size() * 4)
		for point_index in points.size():
			var buf_index := point_index * 4
			var point := points[point_index]
			buf.encode_s16(buf_index + 0, encode_point(point.x))
			buf.encode_s16(buf_index + 2, encode_point(point.y))
		return buf
	
	func encode_point(value: float) -> int:
		return int(value)
	
	@abstract func to_svg() -> Array[Element]

	func _setup_svg_element(element: Element) -> Element:
		element.set_attribute("stroke-width", stroke_width)
		var real_stroke_color := PDCImage.from_pebble_color(stroke_color)
		var real_fill_color := PDCImage.from_pebble_color(fill_color)
		element.set_attribute("stroke", "#" + real_stroke_color.to_html(false))
		if real_stroke_color.a < 1.0:
			element.set_attribute("stroke-opacity", real_stroke_color.a)
		element.set_attribute("fill", "#" + real_fill_color.to_html(false))
		if real_fill_color.a < 1.0:
			element.set_attribute("fill-opacity", real_fill_color.a)
		element.set_attribute("stroke-linecap", "round")
		element.set_attribute("stroke-linejoin", "round")
		return element
	
	@abstract func decode(sp: StreamPeer, points_size: int, path_open_or_radius: int) -> void


class PebblePathCommand extends PebbleCommand:
	var points: PackedVector2Array
	var is_path_open: bool
	func get_type() -> DrawType: return DrawType.PATH
	func get_points() -> PackedVector2Array: return points
	func get_path_open_or_radius() -> int: return 0b1 if is_path_open else 0b0
	func to_svg() -> Array[Element]:
		var rounded_points: PackedVector2Array = points.duplicate()
		for i in rounded_points.size() - 1:
			rounded_points[i] = Vector2(
				_svg_round_value(rounded_points[i].x),
				_svg_round_value(rounded_points[i].y)
			)
		rounded_points = PDCImage.simplify_points(rounded_points)
		var path := _setup_svg_element(ElementPath.new())
		var commands: Array[PathCommand]
		commands.append(PathCommand.MoveCommand.new(rounded_points[0].x, rounded_points[0].y))
		for point_index in range(1, rounded_points.size()):
			var point := rounded_points[point_index]
			commands.append(
				PathCommand.LineCommand.new(point.x, point.y)
			)
		if not is_path_open:
			commands.append(PathCommand.CloseCommand.new())
		path.set_attribute("d", commands)
		return [path]
	
	func _svg_round_value(value: float) -> float: return floorf(value)
	
	func upgrade() -> PebblePrecisePathCommand:
		var precise_path := PebblePrecisePathCommand.new()
		precise_path.points = points
		precise_path.is_path_open = is_path_open
		precise_path.stroke_color = stroke_color
		precise_path.stroke_width = stroke_width
		precise_path.fill_color = fill_color
		precise_path.flags = flags
		return precise_path
	
	func encode_points(input_points: PackedVector2Array) -> PackedByteArray:
		var buf: PackedByteArray
		for i in input_points.size() - 1:
			input_points[i] = Vector2(
				_svg_round_value(input_points[i].x),
				_svg_round_value(input_points[i].y)
			)
		input_points = PDCImage.simplify_points(input_points)
		# Allocate 4 bytes per point
		buf.resize(input_points.size() * 4)
		for point_index in input_points.size():
			var buf_index := point_index * 4
			var point := input_points[point_index]
			buf.encode_s16(buf_index + 0, encode_point(point.x))
			buf.encode_s16(buf_index + 2, encode_point(point.y))
		return buf
	
	func decode(sp: StreamPeer, points_size: int, path_open_or_radius: int) -> void:
		is_path_open = path_open_or_radius == 1
		for point_index in points_size:
			var x := sp.get_16()
			var y := sp.get_16()
			points.append(Vector2(x, y))


class PebbleCircleCommand extends PebbleCommand:
	var center: Vector2
	var radius: int
	func get_type() -> DrawType: return DrawType.CIRCLE
	func get_points() -> PackedVector2Array: return [center]
	func get_path_open_or_radius() -> int: return radius
	func to_svg() -> Array[Element]:
		var circ := _setup_svg_element(ElementCircle.new())
		circ.set_attribute("cx", center.x)
		circ.set_attribute("cy", center.y)
		circ.set_attribute("r", radius)
		return [circ]
	
	func decode(sp: StreamPeer, _points_size: int, path_open_or_radius: int) -> void:
		radius = path_open_or_radius
		var x := sp.get_16()
		var y := sp.get_16()
		center = Vector2(x, y)


class PebblePrecisePathCommand extends PebblePathCommand:
	func get_type() -> DrawType: return DrawType.PRECISE_PATH
	func encode_point(value: float) -> int:
		return int(value * (1 << 3))
	func _svg_round_value(value: float) -> float: return floorf(value * (1 << 3)) / (1 << 3)
	
	func decode(sp: StreamPeer, points_size: int, path_open_or_radius: int) -> void:
		is_path_open = path_open_or_radius == 1
		for point_index in points_size:
			var x := float(sp.get_16()) / (1 << 3)
			var y := float(sp.get_16()) / (1 << 3)
			points.append(Vector2(x, y))


var path_generator := SVGPathUtils.AngleTolerancePathGenerator.new()


func load_from_svg(svg: ElementRoot) -> void:
	var size_float := Vector2(svg.get_attribute_num("width"), svg.get_attribute_num("height"))
	size = Vector2i(size_float)
	var viewbox := svg.get_attribute_list("viewBox")
	if viewbox.size() == 4:
		var viewbox_rect := Rect2(viewbox[0], viewbox[1], viewbox[2], viewbox[3])
		var scaling_factor := size_float / viewbox_rect.size
		viewbox_transform = Transform2D(0.0, scaling_factor, 0.0, -viewbox_rect.position * scaling_factor)
		path_generator.angle_tolerance = path_angle_tolerance
	else:
		viewbox_transform = Transform2D.IDENTITY
	for element in svg.get_all_valid_element_descendants():
		match element.name:
			"circle":
				var cmd := _setup_cmd(element, PebbleCircleCommand.new())
				cmd.center = Vector2(element.get_attribute_num("cx"), element.get_attribute_num("cy"))
				cmd.radius = int(element.get_attribute_num("r"))
				add_command(cmd)
			"ellipse":
				var cmd := _setup_cmd(element, PebbleCircleCommand.new())
				cmd.center = Vector2(element.get_attribute_num("cx"), element.get_attribute_num("cy"))
				cmd.radius = int(minf(element.get_attribute_num("rx"), element.get_attribute_num("ry")))
				add_command(cmd)
			"rect":
				var x := element.get_attribute_num("x")
				var y := element.get_attribute_num("y")
				var w := element.get_attribute_num("w")
				var h := element.get_attribute_num("h")
				var points: PackedVector2Array = [
					Vector2(x + 0, y + 0),
					Vector2(x + w, y + 0),
					Vector2(x + w, y + h),
					Vector2(x + 0, y + h),
				]
				points = Utils64Bit.transform_vector_array_mult(
					element.get_precise_transform(),
					points
				)
				var cmd := _setup_cmd(element, (PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new())
				cmd.points = points
				cmd.is_path_open = false
				add_command(cmd)
			"line":
				var points: PackedVector2Array = [
					Vector2(element.get_attribute_num("x1"), element.get_attribute_num("y1")),
					Vector2(element.get_attribute_num("x2"), element.get_attribute_num("y2")),
				]
				points = Utils64Bit.transform_vector_array_mult(
					element.get_precise_transform(),
					points
				)
				var cmd := _setup_cmd(element, (PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new())
				cmd.points = points
				cmd.is_path_open = true
				add_command(cmd)
			"polygon", "polyline":
				var points: PackedVector2Array
				var element_points := element.get_attribute_list("points")
				points.resize(element_points.size() / 2)
				for point_index in points.size():
					points[point_index].x = element_points[point_index * 2]
					points[point_index].y = element_points[point_index * 2 + 1]
				points = Utils64Bit.transform_vector_array_mult(
					element.get_precise_transform(),
					points
				)
				var cmd: PebblePathCommand = _setup_cmd(
					element,
					(PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new()
				)
				cmd.points = points
				cmd.is_path_open = element.name == "polyline"
				add_command(cmd)
			"path":
				var commands := _generate_path_commands(element)
				
				# All commands are imprecise when they come out of _generate_path_commands,
				# so upgrade the ones that need it.
				for command_index in commands.size():
					if requires_precise_path(commands[command_index].points):
						commands[command_index] = commands[command_index].upgrade()
					add_command(commands[command_index])


func _generate_path_commands(element: Element) -> Array[PebblePathCommand]:
	var pathdata: AttributePathdata = element.get_attribute("d")
	if pathdata.get_command_count() == 0 or not pathdata.get_command(0).command_char in "Mm":
		return []  # Nothing to draw.
	var commands: Array[PebblePathCommand]
	for cmd_idx in pathdata.get_command_count():
		# Drawing logic.
		var cmd := pathdata.get_command(cmd_idx)
		var relative := cmd.relative
		
		var end_path := func(is_open: bool) -> void:
			if commands.size() > 0:
				if commands[-1] == null:
					return
				commands[-1].is_path_open = is_open
			commands.append(null)
		
		var append_points := func(points: PackedVector2Array) -> void:
			if commands.size() == 0:
				commands.append(null)
			if commands[-1] == null:
				commands[-1] = _setup_cmd(element, PebblePathCommand.new())
				commands[-1].points.append_array(points)
			elif commands[-1].points.size() > 0 and points[0] == commands[-1].points[-1]:
				commands[-1].points.append_array(points.slice(1))
			else:
				commands[-1].is_path_open = true
				commands.append(null)
				commands[-1] = _setup_cmd(element, PebblePathCommand.new())
				commands[-1].points.append_array(points)
		
		match cmd.command_char.to_upper():
			"L":
				# Line contour.
				var v := Vector2(cmd.x, cmd.y)
				var end := cmd.get_start_coords() + v if relative else v
				append_points.call(PackedVector2Array([cmd.get_start_coords(), end]))
			"H":
				# Horizontal line contour.
				var v := Vector2(cmd.x, 0)
				var end := cmd.get_start_coords() + v if relative else Vector2(v.x, cmd.start_y)
				append_points.call(PackedVector2Array([cmd.get_start_coords(), end]))
			"V":
				# Vertical line contour.
				var v := Vector2(0, cmd.y)
				var end := cmd.get_start_coords() + v if relative else Vector2(cmd.start_x, v.y)
				append_points.call(PackedVector2Array([cmd.get_start_coords(), end]))
			"C":
				# Cubic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1)
				var v2 := Vector2(cmd.x2, cmd.y2)
				var cp1 := cmd.get_start_coords()
				var cp4 := cp1 + v if relative else v
				var cp2 := v1 if relative else v1 - cp1
				var cp3 := v2 - v
				
				append_points.call(path_generator.generate_cubic(cp1, cp2, cp3, cp4))
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
				
				append_points.call(path_generator.generate_cubic(cp1, cp2, cp3, cp4))
			"Q":
				# Quadratic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := Vector2(cmd.x1, cmd.y1)
				var cp1 := cmd.get_start_coords()
				var cp2 := cp1 + v1 if relative else v1
				var cp3 := cp1 + v if relative else v
				
				append_points.call(path_generator.generate_quadratic(cp1, cp2, cp3))
			"T":
				# Shorthand quadratic Bezier curve contour.
				var v := Vector2(cmd.x, cmd.y)
				var v1 := pathdata.get_implied_T_control(cmd_idx)
				
				var cp1 := cmd.get_start_coords()
				var cp2 := v1 + cp1 if relative else v1
				var cp3 := cp1 + v if relative else v
				
				if is_nan(cp2.x) and is_nan(cp2.y):
					append_points.call(PackedVector2Array([cp1, cp3]))
				else:
					append_points.call(path_generator.generate_quadratic(cp1, cp2, cp3))
			"A":
				# Elliptical arc contour.
				var start := cmd.get_start_coords()
				var v := Vector2(cmd.x, cmd.y)
				var end := start + v if relative else v
				var ellipse_points := SVGPathUtils.generate_ellipse(
					start,
					end,
					Vector2(cmd.rx, cmd.ry),
					deg_to_rad(cmd.rot),
					cmd.large_arc_flag,
					cmd.sweep_flag,
					path_generator,
				)
				ellipse_points.reverse()
				append_points.call(ellipse_points)
			"Z":
				end_path.call(false)
			"M":
				end_path.call(true)
	if commands[-1] == null:
		commands.pop_back()
	else:
		commands[-1].is_path_open = true
	var transform := viewbox_transform * element.get_transform()
	var stroke_width_scale := Utils.vector2_min_element(transform.get_scale())
	for command in commands:
		command.points = transform * command.points
		command.stroke_width *= stroke_width_scale
	return commands


static var _formatter := Formatter.new(Formatter.Preset.COMPACT)

func to_svg() -> String:
	var document := ElementRoot.new()
	document.set_attribute("width", size.x)
	document.set_attribute("height", size.y)
	for cmd in draw_commands:
		for svg_cmd in cmd.to_svg():
			document.insert_child(document.get_child_count(), svg_cmd)
	return SVGParser.root_to_markup(document, _formatter)


static var _path := PebblePathCommand.new()

func _setup_cmd(element: Element, cmd: PebbleCommand) -> PebbleCommand:
	var fill_color_no_alpha := ColorParser.text_to_color(element.get_attribute_true_color("fill"))
	cmd.fill_color = to_pebble_color(Color(fill_color_no_alpha, fill_color_no_alpha.a * element.get_attribute_num("fill-opacity")))
	var stroke_color_no_alpha := ColorParser.text_to_color(element.get_attribute_true_color("stroke"))
	cmd.stroke_color = to_pebble_color(Color(stroke_color_no_alpha, stroke_color_no_alpha.a * element.get_attribute_num("stroke-opacity")))
	cmd.stroke_width = int(element.get_attribute_num("stroke-width"))
	return cmd

func requires_precise_path(points: PackedVector2Array) -> bool:
	if precise_path_mode == PrecisePathMode.ONLY_PRECISE_PATHS:
		return true
	if precise_path_mode == PrecisePathMode.ONLY_IMPRECISE_PATHS:
		return false
	for point in points:
		if not is_equal_approx(_path.encode_point(point.x), point.x) or not is_equal_approx(_path.encode_point(point.y), point.y):
			return true
	return false


static func to_pebble_color(color: Color) -> int:
	return (0
		| int(color.r * 3.0) << 0
		| int(color.g * 3.0) << 2
		| int(color.b * 3.0) << 4
		| int(color.a * 3.0) << 6
	)


static func from_pebble_color(color: int) -> Color:
	return Color(
		((color >> 0) & 0b11) / 3.0,
		((color >> 2) & 0b11) / 3.0,
		((color >> 4) & 0b11) / 3.0,
		((color >> 6) & 0b11) / 3.0,
	)


static func simplify_points(points: PackedVector2Array) -> PackedVector2Array:
	var new_points: PackedVector2Array
	for point_index in points.size():
		if new_points.size() > 0:
			if point_index - 1 >= 0 and point_index + 1 < points.size() - 1:
				var colinear_a := new_points[-1]
				var colinear_b := points[point_index] - colinear_a
				var colinear_c := points[point_index + 1] - colinear_a
				var alignment := colinear_b.dot(colinear_c) / sqrt(colinear_b.length_squared() * colinear_c.length_squared())
				if is_equal_approx(alignment, 1.0):
					# Skip colinear points.
					continue
			if point_index > 0:
				if new_points[-1].is_equal_approx(points[point_index]):
					# Skip overlapping points.
					continue
		new_points.append(points[point_index])
	return new_points
