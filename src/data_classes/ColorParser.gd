class_name ColorParser extends RefCounted


static func add_hash_if_hex(color: String) -> String:
	color = color.strip_edges()
	if color.is_valid_html_color() and not color.begins_with("#"):
		color = "#" + color
	return color

static func is_valid(color: String) -> bool:
	return is_valid_hex(color) or is_valid_rgb(color) or is_valid_named(color) or\
			is_valid_url(color)

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
	if channels.size() == 3 or channels.size() == 4:
		for channel in channels:
			if not channel.strip_edges().is_valid_float():
				return false
		return true
	return false

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
		if color == "none":
			return Color(0, 0, 0, 0)
		else:
			return Color(AttributeColor.named_colors[color])
	elif is_valid_rgb(color):
		var inside_brackets := color.substr(4, color.length() - 5)
		var args := inside_brackets.split(",", false)
		if args.size() == 3:
			return Color8(args[0].to_int(), args[1].to_int(), args[2].to_int())
		else:
			return backup
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
			var inside_brackets := col.substr(4, col.length() - 5)
			var args := inside_brackets.split(",", false)
			col = Color8(args[0].to_int(), args[1].to_int(), args[2].to_int()).to_html(false)
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
