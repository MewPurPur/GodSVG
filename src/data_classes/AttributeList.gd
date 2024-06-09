# An attribute representing a list of numbers.
class_name AttributeList extends Attribute

var _list: PackedFloat32Array

func _sync() -> void:
	_list = ListParser.text_to_list(get_value())

func set_list(new_list: PackedFloat32Array) -> void:
	_list = new_list
	super.set_value(ListParser.list_to_text(new_list))

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
	set_value(ListParser.list_to_text(_list))

func get_list_element(idx: int) -> float:
	return _list[idx] if idx < _list.size() else NAN
