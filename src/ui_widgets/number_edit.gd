# A number editor, not tied to any attribute.
extends BetterLineEdit

@export var min_value := 0.0:
	set(new_value):
		if min_value != new_value:
			min_value = new_value
			if _value < min_value:
				set_value(min_value)

@export var max_value := 1.0:
	set(new_value):
		if max_value != new_value:
			max_value = new_value
			if _value > max_value:
				set_value(max_value)

@export var initial_value := 1.0
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
	# Done like this so a signal isn't emitted.
	text_submitted.connect(_on_text_submitted)
	_value = initial_value
	sync_text()


func _on_text_submitted(submitted_text: String) -> void:
	set_value(NumstringParser.evaluate(submitted_text))

func sync_text() -> void:
	text = Utils.num_simple(_value, Utils.MAX_NUMERIC_PRECISION)
