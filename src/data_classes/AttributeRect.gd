class_name AttributeRect extends Attribute

func _init(new_default: Variant = null, new_init: Variant = null) -> void:
	type = Type.RECT
	default = new_default
	set_value(new_init if new_init != null else new_default, false)


static func string_to_rect(string: String) -> Rect2:
	var nums_parsed: Array[float] = []
	var current_num_string: String = ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length() and nums_parsed.size() < 5:
		@warning_ignore("shadowed_global_identifier")
		var char := string[pos]
		match char:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "+", ".":
				current_num_string += char
			" ":
				if current_num_string.is_empty():
					pos += 1
					continue
				else:
					nums_parsed.append(current_num_string.to_float())
					current_num_string = ""
			",":
				if comma_exhausted or nums_parsed.size() >= 4:
					return Rect2(0, 0, 0, 0)
				elif current_num_string.is_empty():
					comma_exhausted = true
					pos += 1
					continue
				else:
					nums_parsed.append(current_num_string.to_float())
					current_num_string = ""
		pos += 1
	if not current_num_string.is_empty():
		nums_parsed.append(current_num_string.to_float())
	
	if nums_parsed.size() < 4:
		return Rect2(0, 0, 0, 0)
	else:
		return Rect2(nums_parsed[0], nums_parsed[1], nums_parsed[2], nums_parsed[3])

static func rect_to_string(rect: Rect2) -> String:
	return "%s %s %s %s" % [String.num(rect.position.x), String.num(rect.position.y),
	String.num(rect.size.x), String.num(rect.size.y)]
