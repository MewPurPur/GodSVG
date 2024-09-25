class_name ColorParser extends RefCounted


static func add_hash_if_hex(color: String) -> String:
	color = color.strip_edges()
	if color.is_valid_html_color() and not color.begins_with("#"):
		color = "#" + color
	return color

static func is_valid(color: String, allow_url := true) -> bool:
	return is_valid_hex(color) or is_valid_rgb(color) or is_valid_hsl(color) or\
			is_valid_named(color) or (allow_url and is_valid_url(color))

static func is_valid_hex(color: String) -> bool:
	color = color.strip_edges()
	return color.begins_with("#") and color.is_valid_html_color() and\
			(color.length() == 4 or color.length() == 7)

# Not applicable to attributes, but for now I guess it'll live here.
static func is_valid_hex_with_alpha(color: String) -> bool:
	color = color.strip_edges()
	return color.begins_with("#") and color.is_valid_html_color() and\
			(color.length() == 5 or color.length() == 9)

static func is_valid_rgb(color: String) -> bool:
	color = color.strip_edges()
	if not color.begins_with("rgb(") or not color.ends_with(")"):
		return false
	
	var channels_str := color.substr(4, color.length() - 5)
	var channels := channels_str.split(",")
	if channels.size() != 3:
		return false
	
	return _is_valid_number_or_percentage(channels[0]) and\
			_is_valid_number_or_percentage(channels[1]) and\
			_is_valid_number_or_percentage(channels[2])

static func is_valid_hsl(color: String) -> bool:
	color = color.strip_edges()
	if not color.begins_with("hsl(") or not color.ends_with(")"):
		return false
	
	var channels_str := color.substr(4, color.length() - 5)
	var channels := channels_str.split(",")
	if channels.size() != 3:
		return false
	
	return _is_valid_number(channels[0]) and _is_valid_percentage(channels[1]) and\
			_is_valid_percentage(channels[2])

static func is_valid_named(color: String) -> bool:
	color = color.strip_edges()
	return color in AttributeColor.special_colors or AttributeColor.named_colors.has(color)

static func is_valid_url(color: String) -> bool:
	color = color.strip_edges()
	if not color.begins_with("url(") or not color.ends_with(")"):
		return false
	var id := color.substr(4, color.length() - 5).strip_edges().trim_prefix("#")
	return AttributeID.get_validity(id) != AttributeID.ValidityLevel.INVALID

# URL doesn't have a color interpretation, so it'll give the backup.
static func text_to_color(color: String, backup := Color.BLACK,
allow_alpha := false) -> Color:
	color = color.strip_edges()
	if is_valid_named(color):
		if color in ["none", "transparent"]:
			return Color(0, 0, 0, 0)
		elif color == "currentColor":
			return backup
		else:
			return Color(AttributeColor.named_colors[color])
	elif is_valid_rgb(color):
		var inside_brackets := color.substr(4, color.length() - 5)
		var args := inside_brackets.split(",", false)
		if args.size() != 3:
			return backup
		
		var a0 := args[0].strip_edges()
		var a1 := args[1].strip_edges()
		var a2 := args[2].strip_edges()
		var r := a0.to_int() if _is_valid_number(a0) else int(a0.left(-1).to_float() * 2.55)
		var g := a1.to_int() if _is_valid_number(a1) else int(a1.left(-1).to_float() * 2.55)
		var b := a2.to_int() if _is_valid_number(a2) else int(a2.left(-1).to_float() * 2.55)
		return Color8(clampi(r, 0, 255), clampi(g, 0, 255), clampi(b, 0, 255))
	elif is_valid_hsl(color):
		var inside_brackets := color.substr(4, color.length() - 5)
		var args := inside_brackets.split(",", false)
		if args.size() != 3:
			return backup
		
		var h := posmod(args[0].strip_edges().to_int(), 360)
		var s := clampf(int(args[1].strip_edges().left(-1).to_float()) * 0.01, 0.0, 1.0)
		var l := clampf(int(args[2].strip_edges().left(-1).to_float()) * 0.01, 0.0, 1.0)
		return Color8(hsl_get_r(h, s, l), hsl_get_g(h, s, l), hsl_get_b(h, s, l))
	elif is_valid_hex(color) or (allow_alpha and is_valid_hex_with_alpha(color)):
		return Color.from_string(color, Color())
	else:
		return backup

static func are_colors_same(col1: String, col2: String) -> bool:
	col1 = col1.strip_edges()
	col2 = col2.strip_edges()
	# Ensure that the two colors aren't the same,
	# but of a type that can't be represented as hex.
	if col1 == col2:
		return true
	elif col1 in AttributeColor.special_colors or col2 in AttributeColor.special_colors:
		return false
	elif is_valid_url(col1) != is_valid_url(col2):
		return false
	
	# Represent both colors as 6-digit hex codes to serve as basis for comparison.
	for i in 2:
		var col: String = [col1, col2][i]
		# Start of conversion logic.
		if is_valid_rgb(col):
			col = text_to_color(col).to_html(false)
		elif is_valid_hex(col) and col.length() == 4:
			col = col[1] + col[1] + col[2] + col[2] + col[3] + col[3]
		elif is_valid_named(col):
			col = AttributeColor.named_colors[col]
		col = col.trim_prefix("#")
		# End of conversion logic.
		if i == 0:
			col1 = col
		elif i == 1:
			col2 = col
	return col1 == col2

# Helpers
static func _is_valid_number_or_percentage(numstr: String) -> bool:
	return _is_valid_number(numstr) or _is_valid_percentage(numstr)

static func _is_valid_number(numstr: String) -> bool:
	return numstr.strip_edges().is_valid_float()

static func _is_valid_percentage(numstr: String) -> bool:
	var value := numstr.strip_edges()
	return value.length() > 0 and value[-1] == "%" and value.left(-1).is_valid_float()

static func hsl_get_r(h: int, s: float, l: float) -> int:
	return decompose_hsl(0, h, s, l)

static func hsl_get_g(h: int, s: float, l: float) -> int:
	return decompose_hsl(8, h, s, l)

static func hsl_get_b(h: int, s: float, l: float) -> int:
	return decompose_hsl(4, h, s, l)

static func decompose_hsl(n: int, h: int, s: float, l: float) -> int:
	var k := fmod(n + h/30.0, 12)
	var a := s * minf(l, 1 - l)
	return int((l - a * maxf(-1, minf(minf(k - 3, 9 - k), 1))) * 255)
