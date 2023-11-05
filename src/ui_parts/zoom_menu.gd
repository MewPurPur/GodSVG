extends HBoxContainer

const MIN_ZOOM = 0.125
const MAX_ZOOM = 64.0

signal zoom_changed(zoom_level: float)
signal zoom_reset_pressed()

@onready var zoom_out_button: Button = $ZoomOut
@onready var zoom_in_button: Button = $ZoomIn
@onready var zoom_reset_button: Button = $ZoomReset

var zoom_level: float:
	set(value):
		zoom_level = clampf(value, MIN_ZOOM, MAX_ZOOM)
		zoom_changed.emit(zoom_level)
		_update_buttons_appearance()


func _ready() -> void:
	zoom_reset()


func zoom_out() -> void:
	zoom_level /= sqrt(2)

func zoom_in() -> void:
	zoom_level *= sqrt(2)

# Choose an appropriate zoom level and center the camera.
func zoom_reset() -> void:
	var svg_attribs := SVG.root_tag.attributes
	zoom_level = float(nearest_po2(int(8192 / maxf(svg_attribs.width.get_value(),
			svg_attribs.height.get_value()))) / 32.0)
	zoom_reset_pressed.emit()


func _update_buttons_appearance() -> void:
	zoom_reset_button.text = String.num(zoom_level * 100,
			2 if zoom_level < 0.1 else 1 if zoom_level < 10.0 else 0) + "%"
	
	zoom_in_button.disabled = zoom_level >= MAX_ZOOM
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			zoom_in_button.disabled else Control.CURSOR_POINTING_HAND
	
	zoom_out_button.disabled = zoom_level <= MIN_ZOOM
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			zoom_out_button.disabled else Control.CURSOR_POINTING_HAND
