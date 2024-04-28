class_name AttributeNumeric extends Attribute
## An attribute representing a number.

var _number := NAN
var min_value: float
var max_value: float

func _init(new_min: float, new_max: float, new_default: String, new_init := "") -> void:
	min_value = new_min
	max_value = new_max
	default = new_default
	set_value(new_init if !new_init.is_empty() else new_default, SyncMode.SILENT)

func _sync() -> void:
	_number = NumberParser.text_to_num(get_value())

func autoformat(text: String) -> String:
	if GlobalSettings.number_enable_autoformatting:
		return NumberParser.format_text(text)
	else:
		return text

func set_num(new_number: float, sync_mode := SyncMode.LOUD) -> void:
	_number = new_number
	super.set_value(NumberParser.num_to_text(new_number) if is_finite(_number) else "",
			sync_mode)

func get_num() -> float:
	return _number
