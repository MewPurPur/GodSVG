class_name PDCImage

## Don't change
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

var size: Vector2i
var curve_tolerance: float
var precise_path_mode: PrecisePathMode

var draw_commands: Array[PebbleCommand]

func _init(_size: Vector2i = Vector2i.ZERO) -> void:
	size = _size


func encode() -> PackedByteArray:
	# Magic word
	var buffer := "PDCI".to_ascii_buffer()
	# Buffer size, to be filled in later
	var size_byte_offset = buffer.size()
	buffer.resize(8)
	
	var encoded_commands := encode_image()
	buffer.append_array(encoded_commands)
	
	buffer.encode_u32(size_byte_offset, encoded_commands.size())
	
	return buffer


func encode_image() -> PackedByteArray:
	var buffer: PackedByteArray
	buffer.resize(6)
	buffer.encode_u8(0, DRAW_COMMAND_VERSION)
	# Must be 0 for some reason
	buffer.encode_u8(1, 0)
	# View size
	buffer.encode_s16(2, size.x)
	buffer.encode_s16(4, size.y)
	
	for command in draw_commands:
		buffer.append_array(command.encode())
	return buffer


func add_command(command: PebbleCommand) -> void:
	draw_commands.append(command)


@abstract class PebbleCommand:
	var stroke_color: int
	var stroke_width: int
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
		buffer.encode_u8(3, stroke_width)
		buffer.encode_u8(4, fill_color)
		buffer.encode_u16(5, get_path_open_or_radius())
		var points := get_points()
		buffer.encode_u16(7, points.size())
		buffer.append_array(encode_points(points))
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
		return element


class PebblePathCommand extends PebbleCommand:
	var points: PackedVector2Array
	var is_path_open: bool
	func get_type() -> DrawType: return DrawType.PATH
	func get_points() -> PackedVector2Array: return points
	func get_path_open_or_radius() -> int: return 0b1 if is_path_open else 0b0
	func to_svg() -> Array[Element]:
		var path := _setup_svg_element(ElementPath.new())
		var commands: Array[PathCommand]
		commands.append(PathCommand.MoveCommand.new(points[0].x, points[0].y))
		for point_index in range(1, points.size()):
			var point := points[point_index]
			commands.append(
				PathCommand.LineCommand.new(int(point.x), int(point.y))
			)
		if not is_path_open:
			commands.append(PathCommand.CloseCommand.new())
		path.set_attribute("d", commands)
		return [path]


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


class PebblePrecisePathCommand extends PebblePathCommand:
	func get_type() -> DrawType: return DrawType.PRECISE_PATH
	func encode_point(value: float) -> int:
		return int(value * (1 << 3))
	func to_svg() -> Array[Element]:
		var path := _setup_svg_element(ElementPath.new())
		var commands: Array[PathCommand]
		commands.append(PathCommand.MoveCommand.new(points[0].x, points[0].y))
		for point_index in range(1, points.size()):
			var point := points[point_index]
			commands.append(
				PathCommand.LineCommand.new(floorf(point.x * (1 << 3)) / (1 << 3), floorf(point.y * (1 << 3)) / (1 << 3))
			)
		if not is_path_open:
			commands.append(PathCommand.CloseCommand.new())
		path.set_attribute("d", commands)
		return [path]


func load_from_svg(svg: ElementRoot) -> void:
	size.x = int(svg.get_attribute_num("width"))
	size.y = int(svg.get_attribute_num("height"))
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
				var cmd := _setup_cmd(element, (PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new())
				cmd.points = points
				cmd.is_path_open = element.name == "polyline"
				add_command(cmd)
			"path":
				var polylines: Array[PackedVector2Array]
				var multilines := PackedVector2Array()
				SVGPathUtils.get_path_element_points(element, polylines, multilines, curve_tolerance)
				for points in polylines:
					var cmd := _setup_cmd(element, (PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new())
					cmd.points = points
					cmd.is_path_open = false
					add_command(cmd)
				for multiline_index in multilines.size() / 2:
					var points: PackedVector2Array = [
						multilines[multiline_index * 2],
						multilines[multiline_index * 2 + 1],
					]
					var cmd := _setup_cmd(element, (PebblePrecisePathCommand if requires_precise_path(points) else PebblePathCommand).new())
					cmd.points = points
					cmd.is_path_open = false
					add_command(cmd)


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

static func _setup_cmd(element: Element, cmd: PebbleCommand) -> PebbleCommand:
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
