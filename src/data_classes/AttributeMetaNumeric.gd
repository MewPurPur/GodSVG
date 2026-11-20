## Attribute meta that holds a number.
class_name AttributeMetaNumeric extends AttributeMeta

var _number := NAN

func sync(value: String) -> void:
	_number = text_to_number(value)

func _sync_text() -> void:
	meta_changed.emit(to_text())

func to_text(formatter := Configs.savedata.editor_formatter) -> String:
	return formatter.number_to_text(_number)

func set_number(number: float) -> void:
	_number = number
	_sync_text()

func get_number() -> float:
	return _number


static func text_to_number(text: String) -> float:
	text = text.strip_edges(false, true)
	if text.is_empty():
		return NAN
	if text.ends_with("%"):
		return text.to_float() / 100
	return text.to_float()
