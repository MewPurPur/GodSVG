## An attribute representing a color string, or an url to an ID.
class_name AttributeColor extends Attribute

# No color representation for this attribute type. There are too many quirks.

func _init(new_default: String, new_init := "") -> void:
	default = new_default
	set_value(new_init if !new_init.is_empty() else new_default, SyncMode.SILENT)

func autoformat(text: String) -> String:
	if GlobalSettings.color_enable_autoformatting:
		return ColorParser.format_text(text)
	else:
		return text


static func is_valid(color: String) -> bool:
	return is_valid_hex(color) or is_valid_rgb(color) or is_valid_named(color) or\
			is_valid_url(color)

static func is_valid_hex(color: String) -> bool:
	return color.is_valid_html_color()

static func is_valid_rgb(color: String) -> bool:
	return color.begins_with("rgb(") and color.ends_with(")")

static func is_valid_named(color: String) -> bool:
	return color == "none" or AttributeColor.named_colors.has(color)

static func is_valid_url(color: String) -> bool:
	return color.begins_with("url(#") and color.ends_with(")")

static func get_color_from_non_url(color: String) -> Color:
	if is_valid_named(color):
		if color == "none":
			return Color.TRANSPARENT
		else:
			return Color(AttributeColor.named_colors[color])
	elif is_valid_rgb(color):
		var inside_brackets := color.substr(4, color.length() - 5)
		var args := inside_brackets.split(",", false)
		if args.size() == 3:
			return Color8(args[0].to_int(), args[1].to_int(), args[2].to_int())
		else:
			return Color()
	elif is_valid_hex(color):
		return Color.from_string(color, Color())
	else:
		return Color()

static func color_equals_hex(color: String, hex: String) -> bool:
	if color == "none" or is_valid_url(color):
		return false
	
	# Ensure hex is 7-character for a baseline.
	if hex.length() == 4:
		if hex == color:
			return true
		hex = "#" + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3]
	
	if AttributeColor.is_valid_rgb(color):
		var inside_brackets := color.substr(4, color.length() - 5)
		var args := inside_brackets.split(",", false)
		color = "#" +\
				Color8(args[0].to_int(), args[1].to_int(), args[2].to_int()).to_html(false)
	elif AttributeColor.is_valid_named(color):
		color = AttributeColor.named_colors[color]
	
	return color == hex


const named_colors := {  # Dictionary{String: String}
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
