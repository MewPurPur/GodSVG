extends AttributeEditor

@onready var up: Button = %Up
@onready var up_buildup_timer: Timer = %Up/Timer
@onready var up_repeat_timer: Timer = %Up/Timer2
@onready var down: Button = %Down
@onready var down_buildup_timer: Timer = %Down/Timer
@onready var down_repeat_timer: Timer = %Down/Timer2
@onready var num_edit: LineEdit = $LineEdit

var min_value := 0.0
var max_value := 1024.0
var allow_lower := false
var allow_higher := false
var step := 1.0
var is_float := true

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, emit_value_changed := true):
	var old_value := _value
	_value = validate(new_value)
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value)
	elif num_edit != null:
		num_edit.text = str(_value)
		setup_spinners_state()

func get_value() -> float:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.value)
		attribute.value_changed.connect(set_value)
	num_edit.text = str(get_value())
	setup_spinners_state()
	num_edit.tooltip_text = attribute_name

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
	num_edit.text = str(new_value)
	if attribute != null:
		attribute.value = new_value


func _on_up_button_down() -> void:
	set_value(get_value() + step)
	up_buildup_timer.start(0.4)

func _on_up_button_up() -> void:
	up_buildup_timer.stop()
	up_repeat_timer.stop()

func _on_up_buildup_timer_timeout() -> void:
	up_repeat_timer.start(0.04)

func _on_up_repeat_timer_timeout() -> void:
	set_value(get_value() + step)
	if get_value() >= max_value:
		set_value(max_value)
		up_repeat_timer.stop()

func _on_down_button_down() -> void:
	set_value(get_value() - step)
	down_buildup_timer.start(0.4)

func _on_down_button_up() -> void:
	down_buildup_timer.stop()
	down_repeat_timer.stop()

func _on_down_buildup_timer_timeout() -> void:
	down_repeat_timer.start(0.04)

func _on_down_repeat_timer_timeout() -> void:
	set_value(get_value() - step)
	if get_value() <= min_value:
		set_value(min_value)
		down_repeat_timer.stop()


# Hacks to make LineEdit bearable.

func _on_focus_entered() -> void:
	get_tree().paused = true

func _on_focus_exited() -> void:
	set_value(num_edit.text.to_float())
	get_tree().paused = false

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text.to_float())
	num_edit.release_focus()

func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(num_edit, event)

func spinner_set_disabled(spinner: Button, disabling: bool) -> void:
	spinner.disabled = disabling
	spinner.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabling\
			else Control.CURSOR_POINTING_HAND

func setup_spinners_state() -> void:
	spinner_set_disabled(down, get_value() <= min_value or get_value() > max_value)
	spinner_set_disabled(up, get_value() >= max_value or get_value() < min_value)

func add_tooltip(text: String) -> void:
	if num_edit == null:
		await ready
	num_edit.tooltip_text = text


# Common setups

func remove_limits() -> void:
	allow_lower = true
	allow_higher = true
