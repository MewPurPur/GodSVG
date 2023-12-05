## An attribute representing a list of numbers.
class_name AttributeList extends Attribute

var list: PackedFloat32Array

func _init() -> void:
	default = null
	set_value(null, SyncMode.SILENT)

func set_value(list_string: Variant, sync_mode := SyncMode.LOUD) -> void:
	if list_string != null:
		list = ListParser.string_to_list(list_string)
	super(list_string, sync_mode)

func set_list(new_list: PackedFloat32Array, sync_mode := SyncMode.LOUD) -> void:
	list = new_list
	super.set_value(ListParser.list_to_string(new_list), sync_mode)

func set_rect(new_rect: Rect2, sync_mode := SyncMode.LOUD) -> void:
	set_list(PackedFloat32Array([new_rect.position.x, new_rect.position.y,
			new_rect.size.x, new_rect.size.y]), sync_mode)


func set_list_element(idx: int, new_value: float, sync_mode := SyncMode.LOUD) -> void:
	list[idx] = new_value
	set_value(ListParser.list_to_string(list), sync_mode)

func get_list_element(idx: int) -> float:
	return list[idx] if idx < list.size() else NAN
