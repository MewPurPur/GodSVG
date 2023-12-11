extends HBoxContainer

const MIN_ZOOM = 0.125
const MAX_ZOOM = 64.0

signal zoom_changed(zoom_level: float)
signal zoom_reset_pressed

@onready var zoom_out_button: Button = $ZoomOut
@onready var zoom_in_button: Button = $ZoomIn
@onready var zoom_reset_button: Button = $ZoomReset

var zoom_level: float:
	set(value):
		zoom_level = clampf(value, MIN_ZOOM, MAX_ZOOM)
		zoom_changed.emit(zoom_level)
		update_buttons_appearance()


func zoom_out(factor: float = 1.0) -> void:
	if factor == 1.0:
		zoom_level /= sqrt(2)
	else:
		zoom_level *= 1 - _normalize_zoom_factor(factor)

func zoom_in(factor: float = 1.0) -> void:
	if factor == 1.0:
		zoom_level *= sqrt(2)
	else:
		zoom_level *= 1 + _normalize_zoom_factor(factor)

func _normalize_zoom_factor(factor: float) -> float:
	return 1 - 1 / (factor + 1)

# This needs a custom implementation to whatever is listening to the signal.
func zoom_reset() -> void:
	zoom_reset_pressed.emit()


func update_buttons_appearance() -> void:
	zoom_reset_button.text = String.num(zoom_level * 100,
			2 if zoom_level < 0.1 else 1 if zoom_level < 10.0 else 0) + "%"
	
	var is_max_zoom := zoom_level > MAX_ZOOM or is_equal_approx(zoom_level, MAX_ZOOM)
	var is_min_zoom := zoom_level < MIN_ZOOM or is_equal_approx(zoom_level, MIN_ZOOM)
	
	zoom_in_button.disabled = is_max_zoom
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			is_max_zoom else Control.CURSOR_POINTING_HAND
	
	zoom_out_button.disabled = is_min_zoom
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			is_min_zoom else Control.CURSOR_POINTING_HAND
