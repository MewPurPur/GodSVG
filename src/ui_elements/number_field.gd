## An editor to be tied to a numeric attribute.
extends AttributeEditor

@onready var num_edit: LineEdit = $LineEdit

var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

var is_float := true

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, emit_value_changed := true) -> void:
	if is_nan(new_value):
		num_edit.text = String.num(_value, 4)
		return
	var old_value := _value
	_value = validate(new_value)
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value)
	elif num_edit != null:
		num_edit.text = String.num(_value, 4)
		set_text_tint()

func get_value() -> float:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
		attribute.value_changed.connect(set_value)
		set_text_tint()
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

func _on_value_changed(new_value: float) -> void:
	num_edit.text = String.num(new_value, 4)
	if attribute != null:
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
