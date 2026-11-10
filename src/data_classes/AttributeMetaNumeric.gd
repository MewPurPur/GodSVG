class_name AttributeMetaNumeric extends AttributeMeta

var _number := NAN

func sync(value: String) -> void:
	if not value.is_empty():
		value = value.strip_edges(false, true)
		if value.is_empty():
			_number = NAN
			return
		if value.ends_with("%"):
			_number = value.to_float() / 100
			return
		_number = value.to_float()
		return

func set_number(number: float) -> void:
	_number = number

func get_number() -> float:
	return _number
