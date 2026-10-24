## An attribute representing a color string or a url to the ID of a paint element.
class_name AttributeColor extends Attribute

# No direct color representation for this attribute type. There are too many quirks.

func set_value(new_value: String) -> void:
	super(new_value if ParserPaint.is_valid(new_value, false,
			name in DB.COLOR_ATTRIBUTES_WITH_URL_ALLOWED, name in DB.COLOR_ATTRIBUTES_WITH_NONE_ALLOWED,
			name in DB.COLOR_ATTRIBUTES_WITH_CURRENT_COLOR_ALLOWED) else "")

func format(text: String, formatter: Formatter) -> String:
	text = text.strip_edges()
	
	if text.is_empty() or text in ["none", "currentColor", "transparent"]:
		return text
	elif ParserID.is_valid_url(text):
		return "url(" + text.substr(4, text.length() - 5).strip_edges() + ")"
	
	var named_colors_usage := formatter.color_use_named_colors
	# First make sure we have a 6-digit hex.
	if ParserColor.is_valid_rgb(text):
		var args_start_pos := text.find("(") + 1
		var inside_brackets := text.substr(args_start_pos, text.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		var r := String.num_uint64(args[0].strip_edges(false, true).to_int(), 16)
		var g := String.num_uint64(args[1].strip_edges(false, true).to_int(), 16)
		var b := String.num_uint64(args[2].strip_edges(false, true).to_int(), 16)
		text = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
	elif ParserColor.is_valid_hsl(text):
		var args_start_pos := text.find("(") + 1
		var inside_brackets := text.substr(args_start_pos, text.length() - args_start_pos - 1)
		var args := inside_brackets.split(",", false)
		var h := posmod(args[0].to_int(), 360)
		var s := clampf(int(args[1].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		var l := clampf(int(args[2].strip_edges(false, true).left(-1).to_float()) * 0.01, 0.0, 1.0)
		var r := String.num_uint64(ParserColor.hsl_get_r(h, s, l), 16)
		var g := String.num_uint64(ParserColor.hsl_get_g(h, s, l), 16)
		var b := String.num_uint64(ParserColor.hsl_get_b(h, s, l), 16)
		text = "#" + (r if r.length() == 2 else "0" + r) + (g if g.length() == 2 else "0" + g) + (b if b.length() == 2 else "0" + b)
	if text in ParserColor.NAMED_COLORS:
		text = ParserColor.NAMED_COLORS[text]
	if ParserColor.is_valid_hex(text) and text.length() == 4:
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
		if ParserColor.is_valid_hex(hex) and hex.length() == 4:
			hex = "#" + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3]
		
		if hex in ParserColor.NAMED_COLORS.values():
			if named_colors_usage == Formatter.NamedColorUse.ALWAYS:
				text = ParserColor.NAMED_COLORS.find_key(hex)
			else:
				var named_color_text: String = ParserColor.NAMED_COLORS.find_key(hex)
				if named_color_text.length() < text.length() or\
				(named_colors_usage == Formatter.NamedColorUse.WHEN_SHORTER_OR_EQUAL and named_color_text.length() == text.length()):
					text = named_color_text
	return text
