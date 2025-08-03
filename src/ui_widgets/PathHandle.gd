# A handle that binds to one or two path parameters.
class_name PathHandle extends Handle

const pathdata_name = "d"
var command_index: int
var x_param: String
var y_param: String


func _init(new_element: Element, command_idx: int, x_name: String, y_name: String) -> void:
	element = new_element
	command_index = command_idx
	x_param = x_name
	y_param = y_name
	element.attribute_changed.connect(_on_attribute_changed)
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_pos(new_pos: PackedFloat64Array) -> void:
	if precise_pos != new_pos:
		var path_attribute: AttributePathdata = element.get_attribute(pathdata_name)
		var cmd := path_attribute.get_command(command_index)
		if Input.is_key_pressed(KEY_CTRL):
			new_pos = LineConstraint.constrain(path_attribute, command_index, new_pos, x_param, y_param)
		if cmd.relative:
			new_pos[0] -= cmd.start_x
			new_pos[1] -= cmd.start_y
		
		path_attribute.set_command_property(command_index, x_param, new_pos[0])
		path_attribute.set_command_property(command_index, y_param, new_pos[1])
		sync()

func sync() -> void:
	if command_index >= element.get_attribute(pathdata_name).get_command_count():
		# Handle might have been removed.
		return
	
	var command: PathCommand = element.get_attribute(pathdata_name).get_command(command_index)
	if x_param in command:
		var command_x: float = command.get(x_param)
		precise_pos[0] = command.start_x + command_x if command.relative else command_x
	else:
		precise_pos[0] = command.start_x
	if y_param in command:
		var command_y: float = command.get(y_param)
		precise_pos[1] = command.start_y + command_y if command.relative else command_y
	else:
		precise_pos[1] = command.start_y
	super()


func _on_attribute_changed(name: String) -> void:
	if name in [pathdata_name, "transform"]:
		sync()

class LineConstraint:
	extends RefCounted
	
	enum Mode {PREVIOUS, NEXT}
	
	const valid_prev_commands = ["c", "C", "s", "S", "q", "Q", "l", "L", "h", "H", "v", "V"]
	const prev_mode_support = ["c", "C", "q", "Q", "l", "L"]
	const valid_next_commands = ["c", "C", "q", "Q", "l", "L", "h", "H", "v", "V"]
	const next_mode_support = ["c", "C", "s", "S", "q", "Q"]
	
	static func constrain( path: AttributePathdata, idx: int, pos: PackedFloat64Array, x_param: String, y_param: String) -> PackedFloat64Array:
		var cmd := path.get_command(idx)
		
		# Move everything to a local (translated) coordinate system with the new origin at the
		# connection between the two commands.
		
		# Define a line using the connection between the 2 commands and whichever attribute we
		# care about on the other end. Use vector projection to transform the input.
		var opposite := PackedFloat64Array([0, 0])
		var mode: Mode
		
		# Determine if using next or previous command.
		if idx != 0 and path.get_command(idx - 1).command_char in valid_prev_commands and\
		cmd.command_char in prev_mode_support and not ((cmd.command_char in ["c", "C", "q", "Q"]) and\
		(x_param != "x1" or y_param != "y1")):
			mode = Mode.PREVIOUS
		elif idx < path.get_command_count() - 1 and path.get_command(idx + 1).command_char in valid_next_commands and\
		cmd.command_char in next_mode_support and not ((cmd.command_char in ["c", "C", "s", "S"]) and\
		(x_param != "x2" or y_param != "y2") or (cmd.command_char in ["q", "Q"]) and (x_param != "x1" or y_param != "y1")):
			mode = Mode.NEXT
		else:
			return pos
		
		# Get the other command and determine the translation offset.
		var other:= path.get_command(idx - 1) if mode == Mode.PREVIOUS else path.get_command(idx + 1)
		var offset: PackedFloat64Array = [cmd.start_x, cmd.start_y] if mode == Mode.PREVIOUS else [other.start_x, other.start_y]
		
		# Get the global coords of the opposite point.
		match other.command_char:
			"c", "C", "s", "S" when mode == Mode.PREVIOUS:
				opposite = [other.get("x2"), other.get("y2")]
			"q", "Q" when mode == Mode.PREVIOUS:
				opposite = [other.get("x1"), other.get("y1")]
			"l", "h", "v" when mode == Mode.PREVIOUS:
				pass
			"L", "H", "V" when mode == Mode.PREVIOUS:
				opposite = [other.start_x, other.start_y]
			"c", "C", "q", "Q" when mode == Mode.NEXT:
				opposite = [other.get("x1"), other.get("y1")]
			"l", "L" when mode == Mode.NEXT:
				opposite = [other.get("x"), other.get("y")]
			"h" when mode == Mode.NEXT:
				opposite = [other.get("x"), 0.0]
			"H" when mode == Mode.NEXT:
				opposite = [other.get("x"), other.start_y]
			"v" when mode == Mode.NEXT:
				opposite = [0.0, other.get("y")]
			"V" when mode == Mode.NEXT:
				opposite = [other.start_x, other.get("y")]
		if other.relative:
			opposite = [opposite[0] + other.start_x, opposite[1] + other.start_y]
		
		# Translate opposite point to local.
		opposite = [opposite[0] - offset[0], opposite[1] - offset[1]]
		
		# Input to local.
		pos = [pos[0] - offset[0], pos[1] - offset[1]]
		
		pos = Utils64Bit.vector_project(pos, opposite)
		
		# Input back to global.
		return [pos[0] + offset[0], pos[1] + offset[1]]
