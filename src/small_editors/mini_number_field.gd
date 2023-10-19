extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE}

var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, emit_value_changed := true):
	var old_value := _value
	_value = validate(new_value)
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value)
	
	text = String.num(_value, 4)

func get_value() -> float:
	return _value


func _ready() -> void:
	super()
	value_changed.connect(_on_value_changed)
	text = str(get_value())

func validate(new_value: float) -> float:
	match mode:
		Mode.ONLY_POSITIVE: return maxf(new_value, 0.0001)
		Mode.ANGLE: return clampf(-360.0, new_value, 360.0)
		_: return new_value

func _on_value_changed(new_value: float) -> void:
	text = String.num(new_value, 4)


func _on_focus_exited() -> void:
	set_value(calculate_expression(text))
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(calculate_expression(submitted_text))
	super(submitted_text)

# This function evaluates expressions even if "," or ";" is used as a decimal separator.
func calculate_expression(num_text: String) -> float:
	var expr := Expression.new()
	
	var err := expr.parse(num_text.replace(",", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	
	err = expr.parse(num_text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	
	err = expr.parse(num_text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	
	return get_value()
