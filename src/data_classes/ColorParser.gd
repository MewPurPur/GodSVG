## Parser for SVG colors.
@abstract class_name ColorParser


## Adds a hash prefix to hex color strings if they don't already have one
static func add_hash_if_hex(color: String) -> String:
	color = color.strip_edges()
	if color.is_valid_html_color() and not color.begins_with("#"):
		color = "#" + color
	return color

## Validates if a color string is in any supported format: "#RRGGBB", "#RGB", named color, rgb(r, g, b), hsl(h, s, l%).
## If allow_alpha is true, #RRGGBBAA, #RGBA, rgba(r, g, b, a(%?)), hsla(h, s, l%, a(%?)) are considered valid.
## If allow_url is true, "url(#id)" is considered valid.
## If allow_none is true, "none" is considered valid.
## If allow_current_color is true, "currentColor" is considered valid.
static func is_valid(color: String, allow_alpha := false, allow_url := false, allow_none := false, allow_current_color := false) -> bool:
	return is_valid_hex(color, allow_alpha) or is_valid_rgb(color, allow_alpha) or is_valid_hsl(color, allow_alpha) or is_valid_named(color, allow_alpha) or\
			(allow_url and is_valid_url(color)) or (allow_none and color.strip_edges() == "none") or\
			(allow_current_color and color.strip_edges() == "currentColor")

## Validates if a color string is of #RRGGBB or #RGB format. If allow_alpha is true, also accepts #RRGGBBAA and #RGBA.
static func is_valid_hex(color: String, allow_alpha := false) -> bool:
	color = color.strip_edges()
	if color.begins_with("#") and color.is_valid_html_color():
		if color.length() == 4 or color.length() == 7 or (allow_alpha and (color.length() == 5 or color.length() == 9)):
			return true
	return false

## Validates if a color string is of rgb(r, g, b) format. If allow_alpha is true, also accepts rgba(r, g, b, a(%?)).
static func is_valid_rgb(color: String, allow_alpha := false) -> bool:
	color = color.strip_edges()
	var rgb_check := false
	
	if color.begins_with("rgb(") and color.ends_with(")"):
		var channels_str := color.substr(4, color.length() - 5)
		var channels := channels_str.split(",")
		if channels.size() == 3:
			rgb_check = _is_valid_number_or_percentage(channels[0]) and _is_valid_number_or_percentage(channels[1]) and _is_valid_number_or_percentage(channels[2])
	
	if not rgb_check and allow_alpha:
		if not color.begins_with("rgba(") or not color.ends_with(")"):
			return false
		var channels_str := color.substr(5, color.length() - 6)
		var channels := channels_str.split(",")
		if channels.size() != 4:
			return false
		return _is_valid_number_or_percentage(channels[0]) and _is_valid_number_or_percentage(channels[1]) and\
				_is_valid_number_or_percentage(channels[2]) and _is_valid_number_or_percentage(channels[3])
	return rgb_check

## Validates if a color string is of hsl(h, s, l%) format. If allow_alpha is true, also accepts hsla(h, s, l, a(%?)).
static func is_valid_hsl(color: String, allow_alpha := false) -> bool:
	color = color.strip_edges()
	
	var hsl_check := false
	if color.begins_with("hsl(") and color.ends_with(")"):
		var channels_str := color.substr(4, color.length() - 5)
		var channels := channels_str.split(",")
		if channels.size() == 3:
			hsl_check = _is_valid_number(channels[0]) and _is_valid_percentage(channels[1]) and _is_valid_percentage(channels[2])
	
	if not hsl_check and allow_alpha:
		if not color.begins_with("hsla(") or not color.ends_with(")"):
			return false
		
		var channels_str := color.substr(5, color.length() - 6)
		var channels := channels_str.split(",")
		if channels.size() != 4:
			return false
		
		return _is_valid_number(channels[0]) and _is_valid_percentage(channels[1]) and\
				_is_valid_percentage(channels[2]) and _is_valid_number_or_percentage(channels[3])
	return hsl_check

## Validates if the color is in the list of SVG color keywords at https://www.w3.org/TR/SVG11/types.html#ColorKeywords.
## If allow_alpha is true, also accepts "transparent"
static func is_valid_named(color: String, allow_alpha := false) -> bool:
	return AttributeColor.get_named_colors(allow_alpha).has(color.strip_edges())

## Validates if a color string is of hsl(h, s, l%) format. If allow_alpha is true, also accepts hsla(h, s, l, a(%?)).
static func is_valid_url(color: String) -> bool:
	color = color.strip_edges()
	if not color.begins_with("url(") or not color.ends_with(")"):
		return false
	return AttributeID.get_validity(_get_url_id(color)) != Attribute.NameValidityLevel.INVALID

## Converts a color string into a Color if its format can be represented by a color.
## If allow_alpha is true, accepts formats with an alpha channel.
## If the text describes a format that's not accepted, returns the backup color.
static func text_to_color(color: String, backup := Color.BLACK, allow_alpha := false) -> Color:
	color = color.strip_edges()
	if color == "none":
		return Color(0, 0, 0, 0)
	elif is_valid_named(color):
		return Color(AttributeColor.get_named_colors(allow_alpha)[color])
	elif is_valid_rgb(color, allow_alpha):
		var args_start_pos := color.find("(") + 1
		var inside_brackets := color.substr(args_start_pos, color.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		if not (args.size() == 3 or (args.size() == 4 and allow_alpha)):
			return backup
		
		var a0 := args[0].strip_edges(false, true)
		var a1 := args[1].strip_edges(false, true)
		var a2 := args[2].strip_edges(false, true)
		var r := a0.to_int() if _is_valid_number(a0) else int(a0.left(-1).to_float() * 2.55)
		var g := a1.to_int() if _is_valid_number(a1) else int(a1.left(-1).to_float() * 2.55)
		var b := a2.to_int() if _is_valid_number(a2) else int(a2.left(-1).to_float() * 2.55)
		if args.size() == 3:
			return Color.from_rgba8(clampi(r, 0, 255), clampi(g, 0, 255), clampi(b, 0, 255))
		else:
			var a3 := args[3].strip_edges(false, true)
			var a := int(a3.to_float() * 255) if _is_valid_number(a3) else int(a3.left(-1).to_float() * 2.55)
			return Color.from_rgba8(clampi(r, 0, 255), clampi(g, 0, 255), clampi(b, 0, 255), clampi(a, 0, 255))
	elif is_valid_hsl(color, allow_alpha):
		var args_start_pos := color.find("(") + 1
		var inside_brackets := color.substr(args_start_pos, color.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		if not (args.size() == 3 or (args.size() == 4 and allow_alpha)):
			return backup
		
		var h := posmod(args[0].to_int(), 360)
		var s := clampf(int(args[1].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		var l := clampf(int(args[2].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		if args.size() == 3:
			return Color.from_rgba8(hsl_get_r(h, s, l), hsl_get_g(h, s, l), hsl_get_b(h, s, l))
		else:
			var a3 := args[3].strip_edges(false, true)
			var a := int(a3.to_float() * 255) if _is_valid_number(a3) else int(a3.left(-1).to_float() * 2.55)
			return Color.from_rgba8(hsl_get_r(h, s, l), hsl_get_g(h, s, l), hsl_get_b(h, s, l), clampi(a, 0, 255))
	elif is_valid_hex(color, allow_alpha):
		return Color.from_string(color, backup)
	else:
		return backup

## Compares two color strings by whether they represent the same color.
static func are_colors_same(col1: String, col2: String) -> bool:
	col1 = col1.strip_edges()
	col2 = col2.strip_edges()
	# Handle color keywords that can't be represented as hex.
	if col1 == col2:
		return true
	elif col1 == "none" or col2 == "none" or col1 == "currentColor" or col2 == "currentColor":
		return false
	else:
		var is_col1_url := is_valid_url(col1)
		var is_col2_url := is_valid_url(col2)
		if is_col1_url != is_col2_url:
			return false
		elif is_col1_url and is_col2_url:
			return _get_url_id(col1) == _get_url_id(col2)
	
	# Represent both colors as 6-digit hex codes to serve as basis for comparison.
	for i in 2:
		var col := col1 if i == 0 else col2
		# Start of conversion logic.
		if is_valid_rgb(col):
			col = text_to_color(col).to_html(false)
		elif is_valid_hex(col) and col.length() == 4:
			col = col[1] + col[1] + col[2] + col[2] + col[3] + col[3]
		elif is_valid_named(col, false):
			col = AttributeColor.get_named_colors()[col]
		col = col.trim_prefix("#")
		# End of conversion logic.
		if i == 0:
			col1 = col
		elif i == 1:
			col2 = col
	return col1 == col2


static func hsl_get_r(h: int, s: float, l: float) -> int:
	return decompose_hsl(0, h, s, l)

static func hsl_get_g(h: int, s: float, l: float) -> int:
	return decompose_hsl(8, h, s, l)

static func hsl_get_b(h: int, s: float, l: float) -> int:
	return decompose_hsl(4, h, s, l)

static func decompose_hsl(n: int, h: int, s: float, l: float) -> int:
	var k := fmod(n + h/30.0, 12)
	var a := s * minf(l, 1 - l)
	return roundi((l - a * maxf(-1, minf(minf(k - 3, 9 - k), 1))) * 255)


# Helpers
static func _is_valid_number_or_percentage(numstr: String) -> bool:
	numstr = numstr.strip_edges()
	return numstr.is_valid_float() or (not numstr.is_empty() and numstr[-1] == "%" and numstr.left(-1).is_valid_float())

static func _is_valid_number(numstr: String) -> bool:
	return numstr.strip_edges().is_valid_float()

static func _is_valid_percentage(numstr: String) -> bool:
	numstr = numstr.strip_edges()
	return not numstr.is_empty() and numstr[-1] == "%" and numstr.left(-1).is_valid_float()

static func _get_url_id(stripped_color: String) -> String:
	return stripped_color.substr(4, stripped_color.length() - 5).strip_edges().right(-1)
