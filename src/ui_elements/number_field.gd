## An editor to be tied to a numeric attribute.
extends AttributeEditor

@onready var num_edit: LineEdit = $LineEdit

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

var is_float := true

signal value_changed(new_value: float, update_type: UpdateType)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, update_type := UpdateType.REGULAR) -> void:
	if is_nan(new_value):
		num_edit.text = String.num(_value, 4)
		return
	var old_value := _value
	_value = validate(new_value)
	if update_type != UpdateType.NO_SIGNAL and\
	(_value != old_value or update_type == UpdateType.FINAL):
		value_changed.emit(_value, update_type)
	elif num_edit != null:
		update_after_change()

func get_value() -> float:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	num_edit.tooltip_text = attribute_name
	num_edit.text = str(get_value())

func validate(new_value: float) -> float:
	if allow_lower:
		if allow_higher:
			return new_value
		else:
			return minf(new_value, max_value)
	else:
		if allow_higher:
			return maxf(new_value, min_value)
		else:
			return clampf(new_value, min_value, max_value)

func _on_value_changed(new_value: float, update_type: UpdateType) -> void:
	update_after_change()
	match update_type:
		UpdateType.INTERMEDIATE:
			attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
		UpdateType.FINAL:
			attribute.set_value(new_value, Attribute.SyncMode.FINAL)
		_:
			attribute.set_value(new_value)


func _on_focus_exited() -> void:
	set_value(Utils.evaluate_numeric_expression(num_edit.text))

func _on_text_submitted(submitted_text: String) -> void:
	set_value(Utils.evaluate_numeric_expression(submitted_text))


func add_tooltip(text: String) -> void:
	if num_edit == null:
		await ready
	num_edit.tooltip_text = text

func set_text_tint() -> void:
	if num_edit != null:
		if attribute != null and get_value() == attribute.default:
			num_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			num_edit.remove_theme_color_override(&"font_color")

func update_after_change() -> void:
	if num_edit != null:
		num_edit.text = String.num(get_value(), 4)
		set_text_tint()
