extends HBoxContainer

const MIN_ZOOM = 0.125
const MAX_ZOOM = 512.0

signal zoom_changed(zoom_level: float, offset: Vector2)
signal zoom_reset_pressed

@onready var zoom_out_button: Button = $ZoomOut
@onready var zoom_in_button: Button = $ZoomIn
@onready var zoom_reset_button: Button = $ZoomReset

var _zoom_level: float


func _unhandled_input(event: InputEvent) -> void:
	if ShortcutUtils.is_action_pressed(event, "zoom_in"):
		zoom_in()
	elif ShortcutUtils.is_action_pressed(event, "zoom_out"):
		zoom_out()
	elif ShortcutUtils.is_action_pressed(event, "zoom_reset"):
		zoom_reset()


func set_zoom(new_value: float, offset := Vector2(0.5, 0.5)) -> void:
	new_value = clampf(new_value, MIN_ZOOM, MAX_ZOOM)
	if _zoom_level != new_value:
		_zoom_level = new_value
		zoom_changed.emit(_zoom_level, offset)
		update_buttons_appearance()

func zoom_out(factor := 1.0, offset := Vector2(0.5, 0.5)) -> void:
	if factor == 1.0:
		set_zoom(_zoom_level / sqrt(2), offset)
	else:
		set_zoom(_zoom_level / (factor + 1), offset)

func zoom_in(factor := 1.0, offset := Vector2(0.5, 0.5)) -> void:
	if factor == 1.0:
		set_zoom(_zoom_level * sqrt(2), offset)
	else:
		set_zoom(_zoom_level * (factor + 1), offset)

# This needs a custom implementation to whatever is listening to the signal.
func zoom_reset() -> void:
	zoom_reset_pressed.emit()


func update_buttons_appearance() -> void:
	if _zoom_level < 0.1:
		zoom_reset_button.text = Utils.num_simple(_zoom_level * 100, 2) + "%"
	elif _zoom_level < 10.0:
		zoom_reset_button.text = Utils.num_simple(_zoom_level * 100, 1) + "%"
	elif _zoom_level < 100.0:
		zoom_reset_button.text = String.num_uint64(roundi(_zoom_level * 100)) + "%"
	else:
		zoom_reset_button.text = Utils.num_simple(_zoom_level, 1) + "x"
	
	var is_max_zoom := _zoom_level > MAX_ZOOM or is_equal_approx(_zoom_level, MAX_ZOOM)
	var is_min_zoom := _zoom_level < MIN_ZOOM or is_equal_approx(_zoom_level, MIN_ZOOM)
	
	zoom_in_button.disabled = is_max_zoom
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			is_max_zoom else Control.CURSOR_POINTING_HAND
	
	zoom_out_button.disabled = is_min_zoom
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			is_min_zoom else Control.CURSOR_POINTING_HAND
