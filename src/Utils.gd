class_name Utils extends RefCounted

const named_colors := {  # Dictionary{String: Color}
	"aliceblue": Color("#f0f8ff"),
	"antiquewhite": Color("#faebd7"),
	"aqua": Color("#00ffff"),
	"aquamarine": Color("#7fffd4"),
	"azure": Color("#f0ffff"),
	"beige": Color("#f5f5dc"),
	"bisque": Color("#ffe4c4"),
	"black": Color("#000000"),
	"blanchedalmond": Color("#ffebcd"),
	"blue": Color("#0000ff"),
	"blueviolet": Color("#8a2be2"),
	"brown": Color("#a52a2a"),
	"burlywood": Color("#deb887"),
	"cadetblue": Color("#5f9ea0"),
	"chartreuse": Color("#7fff00"),
	"chocolate": Color("#d2691e"),
	"coral": Color("#ff7f50"),
	"cornflowerblue": Color("#6495ed"),
	"cornsilk": Color("#fff8dc"),
	"crimson": Color("#dc143c"),
	"cyan": Color("#00ffff"),
	"darkblue": Color("#00008b"),
	"darkcyan": Color("#008b8b"),
	"darkgoldenrod": Color("#b8860b"),
	"darkgray": Color("#a9a9a9"),
	"darkgreen": Color("#006400"),
	"darkgrey": Color("#a9a9a9"),
	"darkkhaki": Color("#bdb76b"),
	"darkmagenta": Color("#8b008b"),
	"darkolivegreen": Color("#556b2f"),
	"darkorange": Color("#ff8c00"),
	"darkorchid": Color("#9932cc"),
	"darkred": Color("#8b0000"),
	"darksalmon": Color("#e9967a"),
	"darkseagreen": Color("#8fbc8f"),
	"darkslateblue": Color("#483d8b"),
	"darkslategray": Color("#2f4f4f"),
	"darkslategrey": Color("#2f4f4f"),
	"darkturquoise": Color("#00ced1"),
	"darkviolet": Color("#9400d3"),
	"deeppink": Color("#ff1493"),
	"deepskyblue": Color("#00bfff"),
	"dimgray": Color("#696969"),
	"dimgrey": Color("#696969"),
	"dodgerblue": Color("#1e90ff"),
	"firebrick": Color("#b22222"),
	"floralwhite": Color("#fffaf0"),
	"forestgreen": Color("#228b22"),
	"fuchsia": Color("#ff00ff"),
	"gainsboro": Color("#dcdcdc"),
	"ghostwhite": Color("#f8f8ff"),
	"gold": Color("#ffd700"),
	"goldenrod": Color("#daa520"),
	"gray": Color("#808080"),
	"green": Color("#008000"),
	"greenyellow": Color("#adff2f"),
	"grey": Color("#808080"),
	"honeydew": Color("#f0fff0"),
	"hotpink": Color("#ff69b4"),
	"indianred": Color("#cd5c5c"),
	"indigo": Color("#4b0082"),
	"ivory": Color("#fffff0"),
	"khaki": Color("#f0e68c"),
	"lavender": Color("#e6e6fa"),
	"lavenderblush": Color("#fff0f5"),
	"lawngreen": Color("#7cfc00"),
	"lemonchiffon": Color("#fffacd"),
	"lightblue": Color("#add8e6"),
	"lightcoral": Color("#f08080"),
	"lightcyan": Color("#e0ffff"),
	"lightgoldenrodyellow": Color("#fafad2"),
	"lightgray": Color("#d3d3d3"),
	"lightgreen": Color("#90ee90"),
	"lightgrey": Color("#d3d3d3"),
	"lightpink": Color("#ffb6c1"),
	"lightsalmon": Color("#ffa07a"),
	"lightseagreen": Color("#20b2aa"),
	"lightskyblue": Color("#87cefa"),
	"lightslategray": Color("#778899"),
	"lightslategrey": Color("#778899"),
	"lightsteelblue": Color("#b0c4de"),
	"lightyellow": Color("#ffffe0"),
	"lime": Color("#00ff00"),
	"limegreen": Color("#32cd32"),
	"linen": Color("#faf0e6"),
	"magenta": Color("#ff00ff"),
	"maroon": Color("#800000"),
	"mediumaquamarine": Color("#66cdaa"),
	"mediumblue": Color("#0000cd"),
	"mediumorchid": Color("#ba55d3"),
	"mediumpurple": Color("#9370db"),
	"mediumseagreen": Color("#3cb371"),
	"mediumslateblue": Color("#7b68ee"),
	"mediumspringgreen": Color("#00fa9a"),
	"mediumturquoise": Color("#48d1cc"),
	"mediumvioletred": Color("#c71585"),
	"midnightblue": Color("#191970"),
	"mintcream": Color("#f5fffa"),
	"mistyrose": Color("#ffe4e1"),
	"moccasin": Color("#ffe4b5"),
	"navajowhite": Color("#ffdead"),
	"navy": Color("#000080"),
	"oldlace": Color("#fdf5e6"),
	"olive": Color("#808000"),
	"olivedrab": Color("#6b8e23"),
	"orange": Color("#ffa500"),
	"orangered": Color("#ff4500"),
	"orchid": Color("#da70d6"),
	"palegoldenrod": Color("#eee8aa"),
	"palegreen": Color("#98fb98"),
	"paleturquoise": Color("#afeeee"),
	"palevioletred": Color("#db7093"),
	"papayawhip": Color("#ffefd5"),
	"peachpuff": Color("#ffdab9"),
	"peru": Color("#cd853f"),
	"pink": Color("#ffc0cb"),
	"plum": Color("#dda0dd"),
	"powderblue": Color("#b0e0e6"),
	"purple": Color("#800080"),
	"red": Color("#ff0000"),
	"rosybrown": Color("#bc8f8f"),
	"royalblue": Color("#4169e1"),
	"saddlebrown": Color("#8b4513"),
	"salmon": Color("#fa8072"),
	"sandybrown": Color("#f4a460"),
	"seagreen": Color("#2e8b57"),
	"seashell": Color("#fff5ee"),
	"sienna": Color("#a0522d"),
	"silver": Color("#c0c0c0"),
	"skyblue": Color("#87ceeb"),
	"slateblue": Color("#6a5acd"),
	"slategray": Color("#708090"),
	"slategrey": Color("#708090"),
	"snow": Color("#fffafa"),
	"springgreen": Color("#00ff7f"),
	"steelblue": Color("#4682b4"),
	"tan": Color("#d2b48c"),
	"teal": Color("#008080"),
	"thistle": Color("#d8bfd8"),
	"tomato": Color("#ff6347"),
	"turquoise": Color("#40e0d0"),
	"violet": Color("#ee82ee"),
	"wheat": Color("#f5deb3"),
	"white": Color("#ffffff"),
	"whitesmoke": Color("#f5f5f5"),
	"yellow": Color("#ffff00"),
	"yellowgreen": Color("#9acd32")
}

static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func defocus_control_on_outside_click(control: Control, event: InputEvent) -> void:
	if (control.has_focus() and event is InputEventMouseButton and\
	not control.get_global_rect().has_point(event.position)):
		control.release_focus()

static func popup_under_control(popup: Popup, control: Control, center := false) -> void:
	var screen_h := control.get_viewport_rect().size.y
	var popup_pos := Vector2.ZERO
	var true_global_pos = control.global_position
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if true_global_pos.y + control.size.y + popup.size.y < screen_h or\
	true_global_pos.y + control.size.y / 2 <= screen_h / 2.0:
		popup_pos.y = true_global_pos.y + control.size.y
	else:
		popup_pos.y = true_global_pos.y - popup.size.y
	# Align horizontally.
	if center:
		popup_pos.x = true_global_pos.x - popup.size.x / 2.0 + control.size.x / 2
	else:
		popup_pos.x = true_global_pos.x
	popup_pos += control.get_viewport().get_screen_transform().get_origin()
	popup.popup(Rect2(popup_pos, popup.size))

static func get_cubic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2, cp4: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), cp2)
	curve.add_point(cp4, cp3)
	return curve.tessellate(5, 2)

static func get_quadratic_bezier_points(cp1: Vector2, cp2: Vector2,
cp3: Vector2) -> PackedVector2Array:
	var curve := Curve2D.new()
	curve.add_point(cp1, Vector2(), 2/3.0 * (cp2 - cp1))
	curve.add_point(cp3, 2/3.0 * (cp2 - cp3))
	return curve.tessellate(5, 2)

# Ellipse parametric equation.
static func E(c: Vector2, r: Vector2, cosine: float, sine: float, t: float) -> Vector2:
	var xt := r.x * cos(t)
	var yt := r.y * sin(t)
	return c + Vector2(xt * cosine - yt * sine, xt * sine + yt * cosine)

# Ellipse parametric equation derivative (for tangents).
static func Et(r: Vector2, cosine: float, sine: float, t: float) -> Vector2:
	var xt := -r.x * sin(t)
	var yt := r.y * cos(t)
	return Vector2(xt * cosine - yt * sine, xt * sine + yt * cosine)

# This function evaluates expressions even if "," or ";" is used as a decimal separator.
static func evaluate_numeric_expression(text: String) -> float:
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	return NAN

# [1] > [1, 2] > [1, 0] > [0]
static func compare_tids(tid1: PackedInt32Array, tid2: PackedInt32Array) -> bool:
	var smaller_tid_size := mini(tid1.size(), tid2.size())
	for i in smaller_tid_size:
		if tid1[i] < tid2[i]:
			return true
		elif tid1[i] > tid2[i]:
			return false
	return tid1.size() > smaller_tid_size

static func compare_tids_r(tid1: PackedInt32Array, tid2: PackedInt32Array) -> bool:
	return not compare_tids(tid1, tid2)

# Indirect parent, i.e. ancestor. Passing the root tag as parent will return false.
static func is_tid_parent(parent: PackedInt32Array, child: PackedInt32Array) -> bool:
	if parent.is_empty():
		return false
	var parent_size := parent.size()
	if parent_size >= child.size():
		return false
	
	for i in parent_size:
		if parent[i] != child[i]:
			return false
	return true

static func get_parent_tid(tid: PackedInt32Array) -> PackedInt32Array:
	var parent_tid := tid.duplicate()
	parent_tid.resize(tid.size() - 1)
	return parent_tid
