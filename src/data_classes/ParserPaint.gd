## Parser for SVG colors.
@abstract class_name ParserPaint

## Adds a hash prefix to hex color strings if they don't already have one
static func add_hash_if_hex(color: String) -> String:
	color = color.strip_edges()
	if color.is_valid_html_color() and not color.begins_with("#"):
		color = "#" + color
	return color

## See ParserColor.is_valid() for details.
## If allow_url is true, "url(#id)" is considered valid.
## If allow_none is true, "none" is considered valid.
## If allow_current_color is true, "currentColor" is considered valid.
static func is_valid(color: String, allow_alpha := false, allow_url := false, allow_none := false, allow_current_color := false) -> bool:
	return ParserColor.is_valid(color, allow_alpha) or (allow_url and ParserID.is_valid_url(color)) or\
			(allow_none and color.strip_edges() == "none") or (allow_current_color and color.strip_edges() == "currentColor")

## Converts a color string into a Color if its format can be represented by a color.
## If allow_alpha is true, accepts formats with an alpha channel.
## If the text describes a format that's not accepted, returns the backup color.
static func text_to_color(color: String, backup := Color.BLACK, allow_alpha := false) -> Color:
	color = color.strip_edges()
	if color in ["none", "transparent"]:
		return Color(0, 0, 0, 0)
	return ParserColor.text_to_color(color, backup, allow_alpha)

## Compares two color strings by whether they represent the same color.
static func are_colors_same(col1: String, col2: String, allow_alpha := false) -> bool:
	col1 = col1.strip_edges()
	col2 = col2.strip_edges()
	# Handle color keywords that can't be represented as hex.
	if col1 == col2:
		return true
	elif col1 == "none" or col2 == "none" or col1 == "currentColor" or col2 == "currentColor":
		return false
	else:
		var is_col1_url := ParserID.is_valid_url(col1)
		var is_col2_url := ParserID.is_valid_url(col2)
		if is_col1_url != is_col2_url:
			return false
		elif is_col1_url and is_col2_url:
			return ParserID.get_url_id(col1) == ParserID.get_url_id(col2)
	
	# Represent both colors as 6-digit hex codes to serve as basis for comparison.
	if ParserColor.is_valid_rgb(col1):
		col1 = text_to_color(col1).to_html(allow_alpha)
	elif ParserColor.is_valid_hex(col1) and col1.length() == 4:
		col1 = col1[1] + col1[1] + col1[2] + col1[2] + col1[3] + col1[3]
	elif ParserColor.is_valid_named(col1):
		col1 = ParserColor.NAMED_COLORS[col1]
	col1 = col1.trim_prefix("#")
	
	if ParserColor.is_valid_rgb(col2):
		col2 = text_to_color(col2).to_html(allow_alpha)
	elif ParserColor.is_valid_hex(col2) and col2.length() == 4:
		col2 = col2[1] + col2[1] + col2[2] + col2[2] + col2[3] + col2[3]
	elif ParserColor.is_valid_named(col2):
		col2 = ParserColor.NAMED_COLORS[col2]
	col2 = col2.trim_prefix("#")
	
	return col1 == col2
