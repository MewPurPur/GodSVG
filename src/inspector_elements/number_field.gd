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
var value: float:
	set(new_value):
		var old_value := value
		value = validate(new_value)
		if value != old_value:
			value_changed.emit(value)
		elif num_edit != null:
			num_edit.text = str(value)

func set_value_no_restraint(new_value: float) -> void:
	value = new_value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value_no_restraint(attribute.value)
		attribute.value_changed.connect(set_value_no_restraint)
	num_edit.text = str(value)
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
	setup_spinners_state()
	if attribute != null:
		attribute.value = new_value


func _on_up_button_down() -> void:
	value += step
	up_buildup_timer.start(0.5)

func _on_up_button_up() -> void:
	up_buildup_timer.stop()
	up_repeat_timer.stop()

func _on_up_buildup_timer_timeout() -> void:
	up_repeat_timer.start(0.05)

func _on_up_repeat_timer_timeout() -> void:
	value += step
	if value >= max_value:
		value = max_value
		up_repeat_timer.stop()

func _on_down_button_down() -> void:
	value -= step
	down_buildup_timer.start(0.5)

func _on_down_button_up() -> void:
	down_buildup_timer.stop()
	down_repeat_timer.stop()

func _on_down_buildup_timer_timeout() -> void:
	down_repeat_timer.start(0.05)

func _on_down_repeat_timer_timeout() -> void:
	value -= step
	if value <= min_value:
		value = min_value
		down_repeat_timer.stop()


# Hacks to make LineEdit bearable.

func _on_focus_entered() -> void:
	get_tree().paused = true

func _on_focus_exited() -> void:
	value = num_edit.text.to_float()
	get_tree().paused = false

func _on_text_submitted(new_text: String) -> void:
	value = new_text.to_float()
	num_edit.release_focus()

func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(num_edit, event)

func spinner_set_disabled(spinner: Button, disabling: bool) -> void:
	spinner.disabled = disabling
	spinner.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabling\
			else Control.CURSOR_POINTING_HAND

func setup_spinners_state() -> void:
	spinner_set_disabled(down, value <= min_value or value > max_value)
	spinner_set_disabled(up, value >= max_value or value < min_value)


# Common setups

func remove_limits() -> void:
	allow_lower = true
	allow_higher = true
