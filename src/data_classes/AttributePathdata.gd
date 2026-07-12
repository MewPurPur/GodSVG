## The "d" attribute of ElementPath.
class_name AttributePathdata extends Attribute

# Every conversion method should be supported by every path command.
enum Conversion {
	ANY_TO_MOVEMENT,
	ANY_TO_LINE,
	ANY_TO_HORIZONTAL_LINE,
	ANY_TO_VERTICAL_LINE,
	ANY_TO_CLOSURE,
	ANY_TO_ELLIPTICAL_ARC,
	ANY_TO_QUADRATIC_BEZIER_CURVE,
	ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE,
	ANY_TO_CUBIC_BEZIER_CURVE,
	ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE,
}

var _commands: Array[PathCommand]
var subpath_start_indices: PackedInt32Array

func _sync() -> void:
	_commands = parse_pathdata(get_value())
	# Sync all related data.
	subpath_start_indices.clear()
	if _commands[0] is PathCommand.MoveCommand:
		subpath_start_indices.append(0)
	for idx in range(1, _commands.size()):
		if _commands[idx] is PathCommand.MoveCommand or _commands[idx - 1] is PathCommand.CloseCommand:
			subpath_start_indices.append(idx)

func format(text: String, formatter: Formatter) -> String:
	return path_commands_to_text(parse_pathdata(text), formatter)


func get_commands() -> Array[PathCommand]:
	return _commands

func sync_after_commands_change(apply_start_positions_sync := true) -> void:
	if apply_start_positions_sync:
		sync_start_positions()
	set_value(path_commands_to_text(_commands))


func get_command_count() -> int:
	return _commands.size()

func get_command(idx: int) -> PathCommand:
	return _commands[idx]

# Return the start and end indices of the subpath.
func get_subpath(idx: int) -> Vector2i:
	for i in range(subpath_start_indices.size() - 1, -1, -1):
		if subpath_start_indices[i] <= idx:
			return Vector2i(subpath_start_indices[i], (subpath_start_indices[i + 1] if i < subpath_start_indices.size() - 1 else get_command_count()) - 1)
	return Vector2i(-1, -1)

# Gets the implied shorthand cubic bezier curve control. Not dependent on the current path command (even if it's not a curve).
func get_implied_S_control(index: int) -> PackedFloat64Array:
	var cmd := get_command(index)
	var prev_cmd := get_command(index - 1)
	if not prev_cmd.command_char in "CcSs":
		return PackedFloat64Array([cmd.start_x, cmd.start_y])
	return PackedFloat64Array([cmd.start_x * 2 - prev_cmd.x2, cmd.start_y * 2 - prev_cmd.y2])

# Gets the implied shorthand quadratic bezier curve control. Not dependent on the current path command (even if it's not a curve).
func get_implied_T_control(index: int) -> PackedFloat64Array:
	var prevQ_idx := index - 1
	var prevQ_cmd := get_command(prevQ_idx)
	while prevQ_idx >= 0:
		if not prevQ_cmd.command_char in "Tt":
			break
		prevQ_idx -= 1
		if prevQ_idx >= 0:
			prevQ_cmd = get_command(prevQ_idx)
	
	if prevQ_idx == -1:
		return PackedFloat64Array([NAN, NAN])
	
	var control: Vector2
	match prevQ_cmd.command_char.to_upper():
		"Q": control = Vector2(prevQ_cmd.x, prevQ_cmd.y) * 2.0 - Vector2(prevQ_cmd.x1, prevQ_cmd.y1)
		"H": control = Vector2(prevQ_cmd.x, prevQ_cmd.start_y)
		"V": control = Vector2(prevQ_cmd.start_x, prevQ_cmd.y)
		"Z": control = Vector2(get_command(index).start_x, get_command(index).start_y)
		_: control = Vector2(prevQ_cmd.x, prevQ_cmd.y)
	
	for T_idx in range(prevQ_idx + 1, index):
		var T_cmd := get_command(T_idx)
		control = Vector2(T_cmd.x, T_cmd.y) * 2.0 - control
	
	return PackedFloat64Array([control.x, control.y])


func set_commands(new_commands: Array[PathCommand]) -> void:
	_commands = new_commands
	sync_after_commands_change()

# Takes in absolute coordinates.
func set_command_property(index: int, property: String, new_value: float) -> void:
	var cmd := get_command(index)
	if cmd.get(property) != new_value:
		cmd.set(property, new_value)
		sync_after_commands_change(false)

func insert_command(index: int, cmd_char: String, vec := Vector2.ZERO) -> void:
	var new_cmd: PathCommand = PathCommand.translation_dict[cmd_char.to_upper()].new()
	if Utils.is_string_lower(cmd_char):
		new_cmd.toggle_relative()
	_commands.insert(index, new_cmd)
	if not cmd_char in "Zz":
		if not cmd_char in "Vv":
			new_cmd.x = vec.x
		if not cmd_char in "Hh":
			new_cmd.y = vec.y
		if cmd_char in "Qq":
			new_cmd.x1 = lerpf(new_cmd.start_x, vec.x, 0.5)
			new_cmd.y1 = lerpf(new_cmd.start_y, vec.y, 0.5)
		elif cmd_char in "Ss":
			new_cmd.x2 = lerpf(new_cmd.start_x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(new_cmd.start_y, vec.y, 2/3.0)
		elif cmd_char in "Cc":
			new_cmd.x1 = lerpf(new_cmd.start_x, vec.x, 1/3.0)
			new_cmd.y1 = lerpf(new_cmd.start_y, vec.y, 1/3.0)
			new_cmd.x2 = lerpf(new_cmd.start_x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(new_cmd.start_y, vec.y, 2/3.0)
	sync_after_commands_change()


# Check if a conversion would affect or be affected by adjacent curves.
func _has_following_shorthand_quadratic(index: int) -> bool:
	return index + 1 < _commands.size() and _commands[index + 1].command_char in "Tt"

func _has_following_shorthand_cubic(index: int) -> bool:
	return index + 1 < _commands.size() and _commands[index + 1].command_char in "Ss"

func is_implied_T_control_on_segment(index: int, start_x: float, start_y: float, end_x: float, end_y: float) -> bool:
	var implied := get_implied_T_control(index)
	return is_point_on_segment(implied[0], implied[1], start_x, start_y, end_x, end_y)

func is_implied_S_control_on_segment(index: int, start_x: float, start_y: float, end_x: float, end_y: float) -> bool:
	var implied := get_implied_S_control(index)
	return is_point_on_segment(implied[0], implied[1], start_x, start_y, end_x, end_y)

func is_point_on_segment(point_x: float, point_y: float, start_x: float, start_y: float, end_x: float, end_y: float) -> bool:
	var a := Vector2(start_x, start_y)
	var ab := Vector2(end_x, end_y) - a
	if is_zero_approx(ab.length_squared()):
		return is_equal_approx(point_x, start_x) and is_equal_approx(point_y, start_y)
	var ac := Vector2(point_x, point_y) - a
	return is_zero_approx(ab.cross(ac)) and ac.dot(ab) >= 0.0 and ac.dot(ab) <= ab.length_squared()

func is_conversion_exact(index: int, conversion_method: Conversion, ignore_subsequent_commands := false) -> bool:
	var cmd := _commands[index]
	if cmd is PathCommand.MoveCommand:
		return conversion_method == Conversion.ANY_TO_MOVEMENT
	elif cmd is PathCommand.LineCommand or (cmd is PathCommand.EllipticalArcCommand and (cmd.rx <= 0.0 or cmd.ry <= 0.0)):
		match conversion_method:
			Conversion.ANY_TO_LINE: return true
			Conversion.ANY_TO_HORIZONTAL_LINE: return cmd.y == cmd.start_y
			Conversion.ANY_TO_VERTICAL_LINE: return cmd.x == cmd.start_x
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)) and\
						is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y)
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_cubic(index)
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_cubic(index)) and\
						is_implied_S_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y)
			_: return false
	elif cmd is PathCommand.HorizontalLineCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE, Conversion.ANY_TO_HORIZONTAL_LINE: return true
			Conversion.ANY_TO_VERTICAL_LINE: return cmd.x == cmd.start_x
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)) and\
						is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y)
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_cubic(index)
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_cubic(index)) and\
						is_implied_S_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y)
			_: return false
	elif cmd is PathCommand.VerticalLineCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE, Conversion.ANY_TO_VERTICAL_LINE: return true
			Conversion.ANY_TO_HORIZONTAL_LINE: return cmd.y == cmd.start_y
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_quadratic(index)) and\
						is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y)
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE: return ignore_subsequent_commands or not _has_following_shorthand_cubic(index)
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				return (ignore_subsequent_commands or not _has_following_shorthand_cubic(index)) and\
						is_implied_S_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y)
			_: return false
	elif cmd is PathCommand.CloseCommand:
		return conversion_method == Conversion.ANY_TO_CLOSURE
	elif cmd is PathCommand.EllipticalArcCommand:
		return conversion_method == Conversion.ANY_TO_ELLIPTICAL_ARC
	elif cmd is PathCommand.QuadraticBezierCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE:
				return is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_HORIZONTAL_LINE:
				return cmd.y == cmd.start_y and is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_VERTICAL_LINE:
				return cmd.x == cmd.start_x and is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE: return true
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				var implied := get_implied_T_control(index)
				return is_equal_approx(implied[0], cmd.x1) and is_equal_approx(implied[1], cmd.y1)
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
				return ignore_subsequent_commands or not (_has_following_shorthand_cubic(index) or _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				var implied := get_implied_S_control(index)
				var required_c1_x: float = cmd.start_x / 3 + cmd.x1 * 2/3.0
				var required_c1_y: float = cmd.start_y / 3 + cmd.y1 * 2/3.0
				return is_equal_approx(implied[0], required_c1_x) and is_equal_approx(implied[1], required_c1_y) and\
						(ignore_subsequent_commands or not (_has_following_shorthand_cubic(index) or _has_following_shorthand_quadratic(index)))
			_: return false
	elif cmd is PathCommand.ShorthandQuadraticBezierCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE:
				return is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_HORIZONTAL_LINE:
				return cmd.y == cmd.start_y and is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_VERTICAL_LINE:
				return cmd.x == cmd.start_x and is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE, Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE: return true
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
				return ignore_subsequent_commands or not (_has_following_shorthand_cubic(index) or _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				return is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						is_implied_S_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not (_has_following_shorthand_cubic(index) or _has_following_shorthand_quadratic(index)))
			_: return false
	elif cmd is PathCommand.CubicBezierCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE:
				return is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_HORIZONTAL_LINE:
				return cmd.y == cmd.start_y and is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_VERTICAL_LINE:
				return cmd.x == cmd.start_x and is_point_on_segment(cmd.x1, cmd.y1, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
				return is_equal_approx(3 * cmd.x1 - cmd.start_x, 3 * cmd.x2 - cmd.x) and is_equal_approx(3 * cmd.y1 - cmd.start_y, 3 * cmd.y2 - cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				if not (is_equal_approx(3 * cmd.x1 - cmd.start_x, 3 * cmd.x2 - cmd.x) and is_equal_approx(3 * cmd.y1 - cmd.start_y, 3 * cmd.y2 - cmd.y)):
					return false
				var implied := get_implied_T_control(index)
				return is_equal_approx(implied[0], (3 * cmd.x1 - cmd.start_x) / 2) and is_equal_approx(implied[1], (3 * cmd.y1 - cmd.start_y) / 2) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_CUBIC_BEZIER_CURVE: return true
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
				var implied_control := get_implied_S_control(index)
				return is_equal_approx(implied_control[0], cmd.x1) and is_equal_approx(implied_control[1], cmd.y1)
			_: return false
	elif cmd is PathCommand.ShorthandCubicBezierCommand:
		match conversion_method:
			Conversion.ANY_TO_LINE:
				var implied := get_implied_S_control(index)
				return is_point_on_segment(implied[0], implied[1], cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_HORIZONTAL_LINE:
				var implied := get_implied_S_control(index)
				return cmd.y == cmd.start_y and is_point_on_segment(implied[0], implied[1], cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.x, cmd.start_y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_VERTICAL_LINE:
				var implied := get_implied_S_control(index)
				return cmd.x == cmd.start_x and is_point_on_segment(implied[0], implied[1], cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						is_point_on_segment(cmd.x2, cmd.y2, cmd.start_x, cmd.start_y, cmd.start_x, cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_cubic(index))
			Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
				var implied := get_implied_S_control(index)
				return is_equal_approx(3 * implied[0] - cmd.start_x, 3 * cmd.x2 - cmd.x) and is_equal_approx(3 * implied[1] - cmd.start_y, 3 * cmd.y2 - cmd.y) and\
						(ignore_subsequent_commands or not _has_following_shorthand_quadratic(index))
			Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
				var implied := get_implied_S_control(index)
				if not (is_equal_approx(3 * implied[0] - cmd.start_x, 3 * cmd.x2 - cmd.x) and is_equal_approx(3 * implied[1] - cmd.start_y, 3 * cmd.y2 - cmd.y)):
					return false
				var implied_T := get_implied_T_control(index)
				return is_equal_approx(implied_T[0], (3 * implied[0] - cmd.start_x) / 2) and is_equal_approx(implied_T[1], (3 * implied[1] - cmd.start_y) / 2) and\
						is_implied_T_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						is_implied_S_control_on_segment(index, cmd.start_x, cmd.start_y, cmd.x, cmd.y) and\
						(ignore_subsequent_commands or not (_has_following_shorthand_cubic(index) or _has_following_shorthand_quadratic(index)))
			Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE, Conversion.ANY_TO_CUBIC_BEZIER_CURVE: return true
			_: return false
	
	return false

func _convert_commands(indices: PackedInt32Array, conversion_methods: Array[Conversion]) -> void:
	for i in indices.size():
		var cmd_index := indices[i]
		var conversion_method := conversion_methods[i]
		var cmd := _commands[cmd_index]
		var new_cmd: PathCommand
		
		if conversion_method == Conversion.ANY_TO_CLOSURE:
			new_cmd = PathCommand.CloseCommand.new(cmd.relative)
		elif cmd is PathCommand.MoveCommand:
			match conversion_method:
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), lerpf(cmd.start_y, cmd.y, 0.5), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 1/3.0), lerpf(cmd.start_y, cmd.y, 1/3.0),
							lerpf(cmd.start_x, cmd.x, 2/3.0), lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
							lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.LineCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), lerpf(cmd.start_y, cmd.y, 0.5), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 1/3.0), lerpf(cmd.start_y, cmd.y, 1/3.0),
							lerpf(cmd.start_x, cmd.x, 2/3.0), lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
							lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.HorizontalLineCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.start_y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), cmd.start_y, cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 1/3.0), cmd.start_y,
							lerpf(cmd.start_x, cmd.x, 2/3.0), cmd.start_y, cmd.x, cmd.start_y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
							cmd.start_y, cmd.x, cmd.start_y, cmd.relative)
				_: continue
		elif cmd is PathCommand.VerticalLineCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.start_x, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(cmd.start_x, lerpf(cmd.start_y, cmd.y, 0.5), cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(cmd.start_x, lerpf(cmd.start_y, cmd.y, 1/3.0),
							cmd.start_x, lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.start_x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(cmd.start_x,
							lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.start_x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.CloseCommand:
			var close_target_x := 0.0
			var close_target_y := 0.0
			for prev_idx in range(cmd_index - 1, -1, -1):
				var prev_cmd := _commands[prev_idx]
				if prev_cmd is PathCommand.MoveCommand:
					close_target_x = prev_cmd.x
					close_target_y = prev_cmd.y
					break
			
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(close_target_x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(close_target_y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, close_target_x, 0.5),
							lerpf(cmd.start_y, close_target_y, 0.5), close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(lerpf(cmd.start_x, close_target_x, 1/3.0), lerpf(cmd.start_y, close_target_y, 1/3.0),
							lerpf(cmd.start_x, close_target_x, 2/3.0), lerpf(cmd.start_y, close_target_y, 2/3.0), close_target_x, close_target_y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, close_target_x, 2/3.0),
							lerpf(cmd.start_y, close_target_y, 2/3.0), close_target_x, close_target_y, cmd.relative)
				_: continue
		elif cmd is PathCommand.EllipticalArcCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), lerpf(cmd.start_y, cmd.y, 0.5), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 1/3.0), lerpf(cmd.start_y, cmd.y, 1/3.0),
							lerpf(cmd.start_x, cmd.x, 2/3.0), lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
							lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.QuadraticBezierCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.CubicBezierCommand.new(cmd.start_x / 3 + cmd.x1 * 2/3.0, cmd.start_y / 3 + cmd.y1 * 2/3.0,
							cmd.x / 3 + cmd.x1 * 2/3.0, cmd.y / 3 + cmd.y1 * 2/3.0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					if is_conversion_exact(cmd_index, conversion_method, true):
						new_cmd = PathCommand.ShorthandCubicBezierCommand.new(cmd.x / 3 + cmd.x1 * 2/3.0, cmd.y / 3 + cmd.y1 * 2/3.0,
								cmd.x, cmd.y, cmd.relative)
					else:
						new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
								lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.ShorthandQuadraticBezierCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					var implied_control := get_implied_T_control(cmd_index)
					new_cmd = PathCommand.QuadraticBezierCommand.new(implied_control[0], implied_control[1], cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					var implied_control := get_implied_T_control(cmd_index)
					new_cmd = PathCommand.CubicBezierCommand.new(cmd.start_x / 3 + implied_control[0] * 2/3.0, cmd.start_y / 3 + implied_control[1] * 2/3.0,
							cmd.x / 3 + implied_control[0] * 2/3.0, cmd.y / 3 + implied_control[1] * 2/3.0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					var implied_q := get_implied_T_control(cmd_index)
					if is_conversion_exact(cmd_index, conversion_method):
						new_cmd = PathCommand.ShorthandCubicBezierCommand.new(cmd.x / 3 + implied_q[0] * 2/3.0,
								cmd.y / 3 + implied_q[1] * 2/3.0, cmd.x, cmd.y, cmd.relative)
					else:
						new_cmd = PathCommand.ShorthandCubicBezierCommand.new(lerpf(cmd.start_x, cmd.x, 2/3.0),
								lerpf(cmd.start_y, cmd.y, 2/3.0), cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.CubicBezierCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					if is_conversion_exact(cmd_index, conversion_method):
						new_cmd = PathCommand.QuadraticBezierCommand.new((3 * cmd.x1 - cmd.start_x) / 2, (3 * cmd.y1 - cmd.start_y) / 2, cmd.x, cmd.y, cmd.relative)
					else:
						new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), lerpf(cmd.start_y, cmd.y, 0.5), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandCubicBezierCommand.new(cmd.x2, cmd.y2, cmd.x, cmd.y, cmd.relative)
				_: continue
		elif cmd is PathCommand.ShorthandCubicBezierCommand:
			match conversion_method:
				Conversion.ANY_TO_MOVEMENT:
					new_cmd = PathCommand.MoveCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_LINE:
					new_cmd = PathCommand.LineCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_HORIZONTAL_LINE:
					new_cmd = PathCommand.HorizontalLineCommand.new(cmd.x, cmd.relative)
				Conversion.ANY_TO_VERTICAL_LINE:
					new_cmd = PathCommand.VerticalLineCommand.new(cmd.y, cmd.relative)
				Conversion.ANY_TO_ELLIPTICAL_ARC:
					new_cmd = PathCommand.EllipticalArcCommand.new(1.0, 1.0, 0.0, 0, 0, cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE:
					var implied_control := get_implied_S_control(cmd_index)
					if is_equal_approx(3 * implied_control[0] - cmd.start_x, 3 * cmd.x2 - cmd.x) and\
					is_equal_approx(3 * implied_control[1] - cmd.start_y, 3 * cmd.y2 - cmd.y):
						new_cmd = PathCommand.QuadraticBezierCommand.new((-cmd.start_x + 3 * implied_control[0]) / 2,
								(-cmd.start_y + 3 * implied_control[1]) / 2, cmd.x, cmd.y, cmd.relative)
					else:
						new_cmd = PathCommand.QuadraticBezierCommand.new(lerpf(cmd.start_x, cmd.x, 0.5), lerpf(cmd.start_y, cmd.y, 0.5), cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE:
					new_cmd = PathCommand.ShorthandQuadraticBezierCommand.new(cmd.x, cmd.y, cmd.relative)
				Conversion.ANY_TO_CUBIC_BEZIER_CURVE:
					var implied_control := get_implied_S_control(cmd_index)
					new_cmd = PathCommand.CubicBezierCommand.new(implied_control[0], implied_control[1], cmd.x2, cmd.y2, cmd.x, cmd.y, cmd.relative)
				_: continue
		
		_commands.remove_at(cmd_index)
		_commands.insert(cmd_index, new_cmd)

func convert_commands_single_method(indices: PackedInt32Array, conversion_method: Conversion) -> void:
	var conversion_methods: Array[Conversion] = []
	conversion_methods.resize(indices.size())
	conversion_methods.fill(conversion_method)
	_convert_commands(indices, conversion_methods)
	sync_after_commands_change()

func convert_commands_multi_method(indices: PackedInt32Array, conversion_methods: Array[Conversion]) -> void:
	_convert_commands(indices, conversion_methods)
	sync_after_commands_change()


func delete_commands(indices: Array[int]) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		_commands.remove_at(idx)
	sync_after_commands_change()

func toggle_relative_command(idx: int) -> void:
	_commands[idx].toggle_relative()
	sync_after_commands_change()

# Returns the permutation indices of the commands within a pathdata attribute that would emerge
# after a chunk of the commands, corresponding precisely to subpaths, are moved up or down.
func get_subpath_move_permutation(commands_to_move_indices: PackedInt32Array, down: bool) -> PackedInt32Array:
	if commands_to_move_indices.is_empty():
		return PackedInt32Array()
	
	var lengths := PackedInt32Array()
	var selected := PackedInt32Array()
	for i in subpath_start_indices.size():
		var start := subpath_start_indices[i]
		lengths.append((_commands.size() if i == subpath_start_indices.size() - 1 else subpath_start_indices[i + 1]) - start)
		if start in commands_to_move_indices:
			selected.append(i)
	
	var order := range(subpath_start_indices.size())
	if down:
		for i in range(selected.size() - 1, -1, -1):
			var subpath := selected[i]
			var pos := order.find(subpath)
			if pos < order.size() - 1 and !selected.has(order[pos + 1]):
				var tmp = order[pos]
				order[pos] = order[pos + 1]
				order[pos + 1] = tmp
	else:
		for subpath in selected:
			var pos := order.find(subpath)
			if pos > 0 and !selected.has(order[pos - 1]):
				var tmp = order[pos]
				order[pos] = order[pos - 1]
				order[pos - 1] = tmp
	
	var permutation := PackedInt32Array()
	for subpath in order:
		var start := subpath_start_indices[subpath]
		var end := start + lengths[subpath]
		for command in range(start, end):
			permutation.append(command)
	return permutation

# Reorders path commands based on a permutation of indices.
func reorder_commands(indices: PackedInt32Array) -> void:
	var new_commands: Array[PathCommand] = []
	new_commands.resize(_commands.size())
	for i in indices.size():
		new_commands[i] = _commands[indices[i]]
	_commands = new_commands
	sync_after_commands_change()


func sync_start_positions() -> void:
	var current_x := 0.0
	var current_y := 0.0
	var last_move_command_start_x := 0.0
	var last_move_command_start_y := 0.0
	
	for cmd in _commands:
		cmd.start_x = current_x
		cmd.start_y = current_y
		match cmd.command_char.to_upper():
			"M":
				current_x = cmd.x
				current_y = cmd.y
				last_move_command_start_x = current_x
				last_move_command_start_y = current_y
			"Z":
				current_x = last_move_command_start_x
				current_y = last_move_command_start_y
			"H":
				current_x = cmd.x
			"V":
				current_y = cmd.y
			"L", "Q", "T", "C", "S", "A":
				current_x = cmd.x
				current_y = cmd.y

static func parse_pathdata(text: String) -> Array[PathCommand]:
	text = text.strip_edges()
	var text_length := text.length()
	
	var commands: Array[PathCommand] = []
	var idx := 0
	var prev_command := ""
	var current_x := 0.0
	var current_y := 0.0
	var last_move_command_start_x := 0.0
	var last_move_command_start_y := 0.0
	
	while idx < text_length:
		while idx < text_length and text[idx] in " \t\n\r":
			idx += 1
		if idx >= text_length:
			break
		
		var current_char := text[idx]
		var current_command := ""
		if current_char in "MmLlHhVvAaQqTtCcSs":
			current_command = current_char
			idx += 1
		elif current_char in "Zz":
			idx += 1
			if prev_command in "Zz":
				continue
			current_command = current_char
		elif not prev_command.is_empty():
			match prev_command:
				"Z", "z": break
				"M": current_command = "L"
				"m": current_command = "l"
				_: current_command = prev_command
		else:
			break
		
		var key := current_command.to_upper()
		var arg_count := PathCommand.arg_count_dict[key]
		var nums := []
		
		if key == "A":
			var result := NumstringParser.text_to_number_arr(text, idx, 3)
			if result.is_empty():
				return commands
			var arr: PackedFloat64Array = result[0]
			idx = result[1]
			nums.append_array(arr)
			
			# Handle flags.
			for _i in 2:
				@warning_ignore("confusable_local_declaration")
				var comma_passed := false
				while idx < text_length:
					if text[idx] in " \t\n\r":
						idx += 1
					elif text[idx] == ",":
						if comma_passed:
							return commands
						comma_passed = true
						idx += 1
					else:
						break
				if idx >= text_length or not text[idx] in "01":
					return commands
				else:
					nums.append(text[idx].to_int())
					idx += 1
			
			result = NumstringParser.text_to_number_arr(text, idx, 2, true)
			if result.is_empty():
				return commands
			arr = result[0]
			idx = result[1]
			nums.append_array(arr)
		elif arg_count > 0:
			var result := NumstringParser.text_to_number_arr(text, idx, arg_count)
			if result.is_empty():
				return commands
			
			var arr: PackedFloat64Array = result[0]
			idx = result[1]
			nums.append_array(arr)
		
		var relative := Utils.is_string_lower(current_command)
		if relative:
			match key:
				"M", "L", "T":
					nums[0] += current_x
					nums[1] += current_y
				"H":
					nums[0] += current_x
				"V":
					nums[0] += current_y
				"Q":
					nums[0] += current_x
					nums[1] += current_y
					nums[2] += current_x
					nums[3] += current_y
				"S":
					nums[0] += current_x
					nums[1] += current_y
					nums[2] += current_x
					nums[3] += current_y
				"C":
					nums[0] += current_x
					nums[1] += current_y
					nums[2] += current_x
					nums[3] += current_y
					nums[4] += current_x
					nums[5] += current_y
				"A":
					nums[5] += current_x
					nums[6] += current_y
		
		var cmd_type := PathCommand.translation_dict[key]
		var new_cmd: PathCommand
		
		match arg_count:
			0: new_cmd = cmd_type.new(relative)
			1: new_cmd = cmd_type.new(nums[0], relative)
			2: new_cmd = cmd_type.new(nums[0], nums[1], relative)
			4: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], relative)
			6: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], relative)
			7: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], nums[6], relative)
			_: continue
		
		new_cmd.start_x = current_x
		new_cmd.start_y = current_y
		commands.append(new_cmd)
		
		match key:
			"M":
				current_x = nums[0]
				current_y = nums[1]
				last_move_command_start_x = current_x
				last_move_command_start_y = current_y
			"L", "T":
				current_x = nums[0]
				current_y = nums[1]
			"H":
				current_x = nums[0]
			"V":
				current_y = nums[0]
			"Q", "S":
				current_x = nums[2]
				current_y = nums[3]
			"C":
				current_x = nums[4]
				current_y = nums[5]
			"A":
				current_x = nums[5]
				current_y = nums[6]
			"Z":
				current_x = last_move_command_start_x
				current_y = last_move_command_start_y
		
		prev_command = current_command
		
		var comma_passed := false
		while idx < text_length:
			var c := text[idx]
			if c in " \t\n\r":
				idx += 1
			elif c == ",":
				if comma_passed:
					return commands
				comma_passed = true
				idx += 1
			else:
				break
	return commands


func path_commands_to_text(commands_arr: Array[PathCommand], formatter := Configs.savedata.editor_formatter) -> String:
	var output := ""
	var num_parser := NumstringParser.new()
	num_parser.compress_numbers = formatter.pathdata_compress_numbers
	num_parser.minimize_spacing = formatter.pathdata_minimize_spacing
	
	var last_command := ""
	for i in commands_arr.size():
		var cmd := commands_arr[i]
		var cmd_char_capitalized := cmd.command_char.to_upper()
		if not (formatter.pathdata_remove_consecutive_commands and ((cmd_char_capitalized != "M" and last_command == cmd.command_char) or\
		(last_command == "m" and cmd.command_char == "l") or (last_command == "M" and cmd.command_char == "L"))):
			output += cmd.command_char
			if not formatter.pathdata_minimize_spacing:
				output += " "
		elif i > 0 and formatter.pathdata_minimize_spacing:
			var current_char := ""
			var prev_numstr := ""
			var prev_cmd := commands_arr[i - 1]
			match cmd_char_capitalized:
				"A":
					current_char = num_parser.num_to_text(cmd.rx)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.y - prev_cmd.start_y if cmd.relative else prev_cmd.y)
				"C", "Q":
					current_char = num_parser.num_to_text(cmd.x1 - cmd.start_x if cmd.relative else cmd.x1)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.y - prev_cmd.start_y if cmd.relative else prev_cmd.y)
				"S":
					current_char = num_parser.num_to_text(cmd.x2 - cmd.start_x if cmd.relative else cmd.x2)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.y - prev_cmd.start_y if cmd.relative else prev_cmd.y)
				"L", "M", "T":
					current_char = num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.y - prev_cmd.start_y if cmd.relative else prev_cmd.y)
				"H":
					current_char = num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.x - prev_cmd.start_x if cmd.relative else prev_cmd.x)
				"V":
					current_char = num_parser.num_to_text(cmd.y - cmd.start_x if cmd.relative else cmd.y)[0]
					prev_numstr = num_parser.num_to_text(prev_cmd.y - prev_cmd.start_y if cmd.relative else prev_cmd.y)
			if not formatter.pathdata_minimize_spacing or not (("." in prev_numstr and current_char == ".") or current_char in "-+"):
				output += " "
		
		last_command = cmd.command_char
		match cmd_char_capitalized:
			"A":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.rx), num_parser.num_to_text(cmd.ry), num_parser.num_to_text(cmd.rot, true)])
				if formatter.pathdata_remove_spacing_after_flags:
					output += (" 0" if cmd.large_arc_flag == 0 else " 1") + ("0" if cmd.sweep_flag == 0 else "1")
				else:
					output += " 0 " if cmd.large_arc_flag == 0 else " 1 "
					if num_parser.num_to_text(cmd.x)[0] == "-":
						output += "0" if cmd.sweep_flag == 0 else "1"
					else:
						output += "0 " if cmd.sweep_flag == 0 else "1 "
				output += num_parser.numstr_arr_to_text([
					num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x), num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
				])
			"C":
				output += num_parser.numstr_arr_to_text([
					num_parser.num_to_text(cmd.x1 - cmd.start_x if cmd.relative else cmd.x1), num_parser.num_to_text(cmd.y1 - cmd.start_y if cmd.relative else cmd.y1),
					num_parser.num_to_text(cmd.x2 - cmd.start_x if cmd.relative else cmd.x2), num_parser.num_to_text(cmd.y2 - cmd.start_y if cmd.relative else cmd.y2),
					num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x), num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
				])
			"Q":
				output += num_parser.numstr_arr_to_text([
					num_parser.num_to_text(cmd.x1 - cmd.start_x if cmd.relative else cmd.x1), num_parser.num_to_text(cmd.y1 - cmd.start_y if cmd.relative else cmd.y1),
					num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x), num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
				])
			"S":
				output += num_parser.numstr_arr_to_text([
					num_parser.num_to_text(cmd.x2 - cmd.start_x if cmd.relative else cmd.x2), num_parser.num_to_text(cmd.y2 - cmd.start_y if cmd.relative else cmd.y2),
					num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x), num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
				])
			"L", "M", "T":
				output += num_parser.numstr_arr_to_text([
					num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x), num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
				])
			"H":
				output += num_parser.num_to_text(cmd.x - cmd.start_x if cmd.relative else cmd.x)
			"V":
				output += num_parser.num_to_text(cmd.y - cmd.start_y if cmd.relative else cmd.y)
			_: continue
		if not formatter.pathdata_minimize_spacing:
			output += " "
	
	output = output.rstrip(" ")
	return output
