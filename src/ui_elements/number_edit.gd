## A number editor, not tied to any attribute.
extends BetterLineEdit

@export var min_value := 0.0
@export var max_value := 1.0
@export var initial_value := 0.5
@export var allow_lower := true
@export var allow_higher := true
@export var is_float := true

signal value_changed(new_value: float)
var _value := NAN

func set_value(new_value: float, emit_changed := true) -> void:
	if not is_finite(new_value):
		sync_text()
		return
	elif _value != new_value:
		if not allow_higher and new_value > max_value:
			new_value = max_value
		elif not allow_lower and new_value < min_value:
			new_value = min_value
		if _value != new_value:
			_value = new_value
			if emit_changed:
				value_changed.emit(_value)
	sync_text()

func get_value() -> float:
	return _value


func _ready() -> void:
	super()
	# Done like this so a signal isn't emitted.
	_value = initial_value
	text = String.num(_value, 4)


func _on_text_submitted(submitted_text: String) -> void:
	set_value(AttributeNumeric.evaluate_expr(submitted_text))

func sync_text() -> void:
	text = String.num(_value, 4)
