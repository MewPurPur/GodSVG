## An attribute representing a color string or a url to the ID of a paint element.
class_name AttributeColor extends Attribute

# No direct color representation for this attribute type. There are too many quirks.

func set_value(new_value: String) -> void:
	print(new_value, ": ", ColorParser.is_valid(new_value, false,
			name in DB.COLOR_ATTRIBUTES_WITH_URL_ALLOWED, name in DB.COLOR_ATTRIBUTES_WITH_NONE_ALLOWED,
			name in DB.COLOR_ATTRIBUTES_WITH_CURRENT_COLOR_ALLOWED))
	super(new_value if ColorParser.is_valid(new_value, false,
			name in DB.COLOR_ATTRIBUTES_WITH_URL_ALLOWED, name in DB.COLOR_ATTRIBUTES_WITH_NONE_ALLOWED,
			name in DB.COLOR_ATTRIBUTES_WITH_CURRENT_COLOR_ALLOWED) else "")

func format(text: String, formatter: Formatter) -> String:
	text = text.strip_edges()
	
	if text.is_empty() or text in ["none", "currentColor"]:
		return text
	elif ColorParser.is_valid_url(text):
		return "url(" + text.substr(4, text.length() - 5).strip_edges() + ")"
	
	var named_colors_usage := formatter.color_use_named_colors
	# First make sure we have a 6-digit hex.
	if ColorParser.is_valid_rgb(text):
		var args_start_pos := text.find("(") + 1
		var inside_brackets := text.substr(args_start_pos, text.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		var r := String.num_uint64(args[0].strip_edges(false, true).to_int(), 16)
		var g := String.num_uint64(args[1].strip_edges(false, true).to_int(), 16)
		var b := String.num_uint64(args[2].strip_edges(false, true).to_int(), 16)
		text = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
	elif ColorParser.is_valid_hsl(text):
		var args_start_pos := text.find("(") + 1
		var inside_brackets := text.substr(args_start_pos, text.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		var h := posmod(args[0].to_int(), 360)
		var s := clampf(int(args[1].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		var l := clampf(int(args[2].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		var r := String.num_uint64(ColorParser.hsl_get_r(h, s, l), 16)
		var g := String.num_uint64(ColorParser.hsl_get_g(h, s, l), 16)
		var b := String.num_uint64(ColorParser.hsl_get_b(h, s, l), 16)
		text = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
	if text in get_named_colors():
		text = get_named_colors()[text]
	if ColorParser.is_valid_hex(text) and text.length() == 4:
		text = "#" + text[1] + text[1] + text[2] + text[2] + text[3] + text[3]
	
	text = text.to_upper() if formatter.color_capital_hex else text.to_lower()
	match formatter.color_primary_syntax:
		Formatter.PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX:
			if text.length() == 7 and text[0] == "#" and\
			text[1] == text[2] and text[3] == text[4] and text[5] == text[6]:
				text = "#" + text[1] + text[3] + text[5]
		Formatter.PrimaryColorSyntax.RGB:
			text = "rgb(" + String.num_uint64(text.substr(1, 2).hex_to_int()) + ", " +\
					String.num_uint64(text.substr(3, 2).hex_to_int()) + ", " +\
					String.num_uint64(text.substr(5, 2).hex_to_int()) + ")"
	
	if named_colors_usage != Formatter.NamedColorUse.NEVER:
		var hex := text.to_lower()
		if ColorParser.is_valid_hex(hex) and hex.length() == 4:
			hex = "#" + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3]
		
		if hex in AttributeColor.get_named_colors().values():
			if named_colors_usage == Formatter.NamedColorUse.ALWAYS:
				text = AttributeColor.get_named_colors().find_key(hex)
			else:
				var named_color_text: String = AttributeColor.get_named_colors().find_key(hex)
				if named_color_text.length() < text.length() or\
				(named_colors_usage == Formatter.NamedColorUse.WHEN_SHORTER_OR_EQUAL and named_color_text.length() == text.length()):
					text = named_color_text
	return text

## Source: https://www.w3.org/TR/SVG11/types.html#ColorKeywords
static func get_named_colors(include_alpha := false) -> Dictionary:
	if include_alpha:
		var extended_named_colors := _NAMED_COLORS.duplicate()
		extended_named_colors["transparent"] = "#00000000"
		return extended_named_colors
	else:
		return _NAMED_COLORS

const _NAMED_COLORS: Dictionary[String, String] = {
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
