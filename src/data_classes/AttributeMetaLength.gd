## Attribute meta that holds a number and a unit.
class_name AttributeMetaLength extends AttributeMeta

var _number := NAN
var _unit := ""

func sync(value: String) -> void:
	value = value.strip_edges(false, true)
	if value.is_empty():
		_unit = ""
		_number = NAN
		return
	for checked_unit in ["%", "px", "in", "cm", "mm", "pt", "pc", "em", "ex", "ch", "rem"]:
		if value.ends_with(checked_unit):
			_unit = checked_unit
			_number = value.left(-checked_unit.size()).to_float()
			return
	_unit = ""
	_number = value.to_float()

func _sync_text() -> void:
	meta_changed.emit(to_text())

func to_text(formatter := Configs.savedata.editor_formatter) -> String:
	return formatter.number_to_text(_number)

func set_length(new_number: float, new_unit: String) -> void:
	_number = new_number
	_unit = new_unit
	_sync_text()

func get_number() -> float:
	return _number

func get_unit() -> String:
	return _unit
