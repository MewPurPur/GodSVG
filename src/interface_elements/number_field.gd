extends HBoxContainer

@onready var up: Button = %Up
@onready var up_buildup_timer: Timer = %Up/Timer
@onready var up_repeat_timer: Timer = %Up/Timer2
@onready var down: Button = %Down
@onready var down_buildup_timer: Timer = %Down/Timer
@onready var down_repeat_timer: Timer = %Down/Timer2
@onready var num_edit: LineEdit = $LineEdit

var min_value := 0
var max_value := 1024
var step := 1
var is_float := true

var attribute: SVGAttribute
var attribute_name: String

signal value_changed(new_value: float)
var value: float:
	set(new_value):
		var old_value := value
		value = validate(new_value)
		if value != old_value:
			value_changed.emit(new_value)


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value
		num_edit.text = str(value)
	spinner_set_disabled(down, value <= min_value)
	spinner_set_disabled(up, value >= max_value)
	num_edit.tooltip_text = attribute_name

func validate(new_value: float) -> float:
	return clampf(new_value, min_value, max_value)

func _on_value_changed(new_value: float) -> void:
	num_edit.text = str(new_value)
	spinner_set_disabled(down, new_value <= min_value)
	spinner_set_disabled(up, new_value >= max_value)
	if attribute != null:
		attribute.value = new_value
		SVG.update()


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
	if value == max_value:
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
	if value == min_value:
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
	if (num_edit.has_focus() and event is InputEventMouseButton and\
	not num_edit.get_global_rect().has_point(event.position)):
		num_edit.release_focus()

func spinner_set_disabled(spinner: Button, value: bool) -> void:
	spinner.disabled = value
	spinner.mouse_default_cursor_shape = Control.CURSOR_ARROW if value == true\
			else Control.CURSOR_POINTING_HAND
