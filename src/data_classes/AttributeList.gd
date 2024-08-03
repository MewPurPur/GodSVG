# An attribute representing a list of numbers.
class_name AttributeList extends Attribute

var _list: PackedFloat32Array

func _sync() -> void:
	_list = text_to_list(get_value())

func set_list(new_list: PackedFloat32Array) -> void:
	_list = new_list
	super.set_value(list_to_text(new_list))

func get_list() -> PackedFloat32Array:
	return _list

func get_list_size() -> int:
	return _list.size()

# Just a helper to handle Rect2.
func set_rect(new_rect: Rect2) -> void:
	set_list(PackedFloat32Array([new_rect.position.x, new_rect.position.y,
			new_rect.size.x, new_rect.size.y]))


func set_list_element(idx: int, new_value: float) -> void:
	_list[idx] = new_value
	set_value(list_to_text(_list))

func get_list_element(idx: int) -> float:
	return _list[idx] if idx < _list.size() else NAN


static func text_to_list(string: String) -> PackedFloat32Array:
	var nums_parsed := PackedFloat32Array()
	var current_num_string: String = ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length():
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
				if comma_exhausted:
					return nums_parsed
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
	
	return nums_parsed

func list_to_text(list: PackedFloat32Array) -> String:
	var params := PackedStringArray()
	for element in list:
		# It's fine to use this parser, AttributeList is just a list of numbers.
		params.append(NumberParser.num_to_text(element, formatter))
	return " ".join(params)
