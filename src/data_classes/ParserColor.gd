## Parser for SVG colors, URLs, and paints.
@abstract class_name ParserColor

## Adds a hash prefix to hex color strings if they don't already have one
static func add_hash_if_hex(color: String) -> String:
	color = color.strip_edges()
	if color.is_valid_html_color() and not color.begins_with("#"):
		color = "#" + color
	return color

## Validates if a color string is in any supported format: "#RRGGBB", "#RGB", named color, rgb(r, g, b), hsl(h, s, l%).
## If allow_alpha is true, #RRGGBBAA, #RGBA, rgba(r, g, b, a(%?)), hsla(h, s, l%, a(%?)) are considered valid.
static func is_valid(color: String, allow_alpha := false) -> bool:
	return (allow_alpha and color.strip_edges() == "transparent") or is_valid_hex(color, allow_alpha) or\
			is_valid_rgb(color, allow_alpha) or is_valid_hsl(color, allow_alpha) or is_valid_named(color)

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
static func is_valid_named(color: String) -> bool:
	return NAMED_COLORS.has(color.strip_edges())


## Converts a color string into a Color if its format can be represented by a color.
## If allow_alpha is true, accepts formats with an alpha channel.
## If the text describes a format that's not accepted, returns the backup color.
static func text_to_color(color: String, backup := Color.BLACK, allow_alpha := false) -> Color:
	color = color.strip_edges()
	if is_valid_named(color):
		return Color(NAMED_COLORS[color])
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
	return backup


static func hsl_get_r(h: int, s: float, l: float) -> int:
	return _decompose_hsl(0, h, s, l)

static func hsl_get_g(h: int, s: float, l: float) -> int:
	return _decompose_hsl(8, h, s, l)

static func hsl_get_b(h: int, s: float, l: float) -> int:
	return _decompose_hsl(4, h, s, l)

static func _decompose_hsl(n: int, h: int, s: float, l: float) -> int:
	var k := fmod(n + h/30.0, 12)
	return roundi((l - s * minf(l, 1 - l) * maxf(-1, minf(minf(k - 3, 9 - k), 1))) * 255)


# Helpers

static func _is_valid_number_or_percentage(numstr: String) -> bool:
	numstr = numstr.strip_edges()
	return numstr.is_valid_float() or (not numstr.is_empty() and numstr[-1] == "%" and numstr.left(-1).is_valid_float())

static func _is_valid_number(numstr: String) -> bool:
	return numstr.strip_edges().is_valid_float()

static func _is_valid_percentage(numstr: String) -> bool:
	numstr = numstr.strip_edges()
	return not numstr.is_empty() and numstr[-1] == "%" and numstr.left(-1).is_valid_float()


const NAMED_COLORS: Dictionary[String, String] = {
	"aliceblue": "#f0f8ff",
	"antiquewhite": "#faebd7",
	"aqua": "#00ffff",
	"aquamarine": "#7fffd4",
	"azure": "#f0ffff",
	"beige": "#f5f5dc",
	"bisque": "#ffe4c4",
	"black": "#000000",
	"blanchedalmond": "#ffebcd",
	"blue": "#0000ff",
	"blueviolet": "#8a2be2",
	"brown": "#a52a2a",
	"burlywood": "#deb887",
	"cadetblue": "#5f9ea0",
	"chartreuse": "#7fff00",
	"chocolate": "#d2691e",
	"coral": "#ff7f50",
	"cornflowerblue": "#6495ed",
	"cornsilk": "#fff8dc",
	"crimson": "#dc143c",
	"cyan": "#00ffff",
	"darkblue": "#00008b",
	"darkcyan": "#008b8b",
	"darkgoldenrod": "#b8860b",
	"darkgray": "#a9a9a9",
	"darkgreen": "#006400",
	"darkgrey": "#a9a9a9",
	"darkkhaki": "#bdb76b",
	"darkmagenta": "#8b008b",
	"darkolivegreen": "#556b2f",
	"darkorange": "#ff8c00",
	"darkorchid": "#9932cc",
	"darkred": "#8b0000",
	"darksalmon": "#e9967a",
	"darkseagreen": "#8fbc8f",
	"darkslateblue": "#483d8b",
	"darkslategray": "#2f4f4f",
	"darkslategrey": "#2f4f4f",
	"darkturquoise": "#00ced1",
	"darkviolet": "#9400d3",
	"deeppink": "#ff1493",
	"deepskyblue": "#00bfff",
	"dimgray": "#696969",
	"dimgrey": "#696969",
	"dodgerblue": "#1e90ff",
	"firebrick": "#b22222",
	"floralwhite": "#fffaf0",
	"forestgreen": "#228b22",
	"fuchsia": "#ff00ff",
	"gainsboro": "#dcdcdc",
	"ghostwhite": "#f8f8ff",
	"gold": "#ffd700",
	"goldenrod": "#daa520",
	"gray": "#808080",
	"green": "#008000",
	"greenyellow": "#adff2f",
	"grey": "#808080",
	"honeydew": "#f0fff0",
	"hotpink": "#ff69b4",
	"indianred": "#cd5c5c",
	"indigo": "#4b0082",
	"ivory": "#fffff0",
	"khaki": "#f0e68c",
	"lavender": "#e6e6fa",
	"lavenderblush": "#fff0f5",
	"lawngreen": "#7cfc00",
	"lemonchiffon": "#fffacd",
	"lightblue": "#add8e6",
	"lightcoral": "#f08080",
	"lightcyan": "#e0ffff",
	"lightgoldenrodyellow": "#fafad2",
	"lightgray": "#d3d3d3",
	"lightgreen": "#90ee90",
	"lightgrey": "#d3d3d3",
	"lightpink": "#ffb6c1",
	"lightsalmon": "#ffa07a",
	"lightseagreen": "#20b2aa",
	"lightskyblue": "#87cefa",
	"lightslategray": "#778899",
	"lightslategrey": "#778899",
	"lightsteelblue": "#b0c4de",
	"lightyellow": "#ffffe0",
	"lime": "#00ff00",
	"limegreen": "#32cd32",
	"linen": "#faf0e6",
	"magenta": "#ff00ff",
	"maroon": "#800000",
	"mediumaquamarine": "#66cdaa",
	"mediumblue": "#0000cd",
	"mediumorchid": "#ba55d3",
	"mediumpurple": "#9370db",
	"mediumseagreen": "#3cb371",
	"mediumslateblue": "#7b68ee",
	"mediumspringgreen": "#00fa9a",
	"mediumturquoise": "#48d1cc",
	"mediumvioletred": "#c71585",
	"midnightblue": "#191970",
	"mintcream": "#f5fffa",
	"mistyrose": "#ffe4e1",
	"moccasin": "#ffe4b5",
	"navajowhite": "#ffdead",
	"navy": "#000080",
	"oldlace": "#fdf5e6",
	"olive": "#808000",
	"olivedrab": "#6b8e23",
	"orange": "#ffa500",
	"orangered": "#ff4500",
	"orchid": "#da70d6",
	"palegoldenrod": "#eee8aa",
	"palegreen": "#98fb98",
	"paleturquoise": "#afeeee",
	"palevioletred": "#db7093",
	"papayawhip": "#ffefd5",
	"peachpuff": "#ffdab9",
	"peru": "#cd853f",
	"pink": "#ffc0cb",
	"plum": "#dda0dd",
	"powderblue": "#b0e0e6",
	"purple": "#800080",
	"red": "#ff0000",
	"rosybrown": "#bc8f8f",
	"royalblue": "#4169e1",
	"saddlebrown": "#8b4513",
	"salmon": "#fa8072",
	"sandybrown": "#f4a460",
	"seagreen": "#2e8b57",
	"seashell": "#fff5ee",
	"sienna": "#a0522d",
	"silver": "#c0c0c0",
	"skyblue": "#87ceeb",
	"slateblue": "#6a5acd",
	"slategray": "#708090",
	"slategrey": "#708090",
	"snow": "#fffafa",
	"springgreen": "#00ff7f",
	"steelblue": "#4682b4",
	"tan": "#d2b48c",
	"teal": "#008080",
	"thistle": "#d8bfd8",
	"tomato": "#ff6347",
	"turquoise": "#40e0d0",
	"violet": "#ee82ee",
	"wheat": "#f5deb3",
	"white": "#ffffff",
	"whitesmoke": "#f5f5f5",
	"yellow": "#ffff00",
	"yellowgreen": "#9acd32",
}
