extends HBoxContainer

const MIN_ZOOM = 0.125
const MAX_ZOOM = 512.0

signal zoom_changed(zoom_level: float)
signal zoom_reset_pressed

@onready var zoom_out_button: BetterButton = $ZoomOut
@onready var zoom_in_button: BetterButton = $ZoomIn
@onready var zoom_reset_button: BetterButton = $ZoomReset

var _zoom_level: float


func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("zoom_in", zoom_in)
	shortcuts.add_shortcut("zoom_out", zoom_out)
	shortcuts.add_shortcut("zoom_reset", zoom_reset)
	HandlerGUI.register_shortcuts(self, shortcuts)
	zoom_out_button.shortcuts_bind = shortcuts
	zoom_in_button.shortcuts_bind = shortcuts
	zoom_reset_button.shortcuts_bind = shortcuts


func set_zoom(new_value: float) -> void:
	new_value = clampf(new_value, MIN_ZOOM, MAX_ZOOM)
	if _zoom_level != new_value:
		_zoom_level = new_value
		zoom_changed.emit(_zoom_level)
		update_buttons_appearance()

func zoom_out() -> void:
	set_zoom(_zoom_level / sqrt(2))

func zoom_in() -> void:
	set_zoom(_zoom_level * sqrt(2))

# Requires a custom implementation for whatever is listening to the signal.
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
	
	var is_max_zoom := is_equal_approx(_zoom_level, MAX_ZOOM)
	var is_min_zoom := is_equal_approx(_zoom_level, MIN_ZOOM)
	
	zoom_in_button.disabled = is_max_zoom
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_max_zoom else Control.CURSOR_POINTING_HAND
	
	zoom_out_button.disabled = is_min_zoom
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_min_zoom else Control.CURSOR_POINTING_HAND
