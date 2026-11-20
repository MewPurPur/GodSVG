## Attribute meta that holds a list of floats.
class_name AttributeMetaList extends AttributeMeta

var _list: PackedFloat64Array

func sync(new_value: String) -> void:
	_list = text_to_list(new_value)

func set_list(new_list: PackedFloat64Array) -> void:
	_list = new_list
	_sync_text()

func get_list() -> PackedFloat64Array:
	return _list

func get_list_size() -> int:
	return _list.size()


func set_list_element(index: int, new_value: float) -> void:
	_list[index] = new_value

func get_list_element(index: int) -> float:
	return _list[index] if index < _list.size() else NAN

func delete_elements(indices: PackedInt64Array) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for i in indices:
		_list.remove_at(i)
	_sync_text()

func insert_zeros(index: int, zeros_count: int) -> void:
	for i in zeros_count:
		_list.insert(index, 0.0)
	_sync_text()

func rotate_start(start_index: int) -> void:
	if _list.is_empty() or start_index == 0:
		return
	var size := _list.size()
	start_index = posmod(start_index, size)
	_list = _list.slice(start_index) + _list.slice(0, start_index)
	_sync_text()


static func text_to_list(string: String) -> PackedFloat64Array:
	var nums_parsed := PackedFloat64Array()
	var current_num_string := ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length():
		var current_char := string[pos]
		match current_char:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "+", ".", "e", "E":
				current_num_string += current_char
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


func to_text(formatter := Configs.savedata.editor_formatter) -> String:
	return formatter.list_to_text(_list)

func _sync_text() -> void:
	meta_changed.emit(to_text())
