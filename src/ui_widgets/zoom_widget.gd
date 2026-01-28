extends HBoxContainer

var min_zoom: float
var max_zoom: float

signal zoom_in_pressed
signal zoom_out_pressed
signal zoom_reset_pressed

@onready var zoom_out_button: BetterButton = $ZoomOut
@onready var zoom_in_button: BetterButton = $ZoomIn
@onready var zoom_reset_button: BetterButton = $ZoomReset


func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("zoom_in", zoom_in_pressed.emit)
	shortcuts.add_shortcut("zoom_out", zoom_out_pressed.emit)
	shortcuts.add_shortcut("zoom_reset", zoom_reset_pressed.emit)
	HandlerGUI.register_shortcuts(self, shortcuts)
	zoom_out_button.shortcuts_bind = shortcuts
	zoom_in_button.shortcuts_bind = shortcuts
	zoom_reset_button.shortcuts_bind = shortcuts
	
	HandlerGUI.register_focus_sequence(self, [zoom_out_button, zoom_reset_button, zoom_in_button])


func setup_limits(new_min_zoom: float, new_max_zoom: float) -> void:
	min_zoom = new_min_zoom
	max_zoom = new_max_zoom

func sync_to_value(new_zoom: float) -> void:
	new_zoom = clampf(new_zoom, min_zoom, max_zoom)
	if new_zoom < 0.1:
		zoom_reset_button.text = Utils.num_simple(new_zoom * 100, 2) + "%"
	elif new_zoom < 10.0:
		zoom_reset_button.text = Utils.num_simple(new_zoom * 100, 1) + "%"
	elif new_zoom < 100.0:
		zoom_reset_button.text = String.num_uint64(roundi(new_zoom * 100)) + "%"
	else:
		zoom_reset_button.text = Utils.num_simple(new_zoom, 1) + "x"
	
	var is_max_zoom := is_equal_approx(new_zoom, max_zoom)
	zoom_in_button.disabled = is_max_zoom
	zoom_in_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_max_zoom else Control.CURSOR_POINTING_HAND
	
	var is_min_zoom := is_equal_approx(new_zoom, min_zoom)
	zoom_out_button.disabled = is_min_zoom
	zoom_out_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_min_zoom else Control.CURSOR_POINTING_HAND
