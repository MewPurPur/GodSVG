## ContextButtons need to behave almost like buttons, but they have no pressed state and a kind of weird
## fusion between the hover state and focus. So I implemented them as a custom control.
class_name ContextButton extends Control

const PADDING = 3.0
const ICON_SPACING = 4.0
const DIM_TEXT_SPACING = 12.0

enum Type {NORMAL, CHECKBOX, ARROW}

var type := Type.NORMAL
var use_icon := true
var skip_icon_modulation := false
var action := ""
var custom_callback := Callable()
var custom_icon: Texture2D
var custom_text := ""
var custom_dim_text := ""
var toggled_on := true
var submenu_button_builders: Array[Callable] = []
var disabled := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size.y = 22
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_type_variation = "ContextButton"

static func create(new_disabled := false) -> ContextButton:
	var context_button := ContextButton.new()
	context_button.disabled = new_disabled
	return context_button

static func create_custom(new_custom_text: String, new_custom_callback: Callable, new_custom_icon: Texture2D = null, new_disabled := false) -> ContextButton:
	var context_button := ContextButton.create(new_disabled)
	context_button.custom_text = new_custom_text
	context_button.custom_callback = new_custom_callback
	context_button.custom_icon = new_custom_icon
	context_button.calibrate()
	return context_button

static func create_from_action(new_action: String, new_disabled := false) -> ContextButton:
	if not InputMap.has_action(new_action):
		push_error("Non-existent action was passed.")
		return
	
	var context_button := ContextButton.create(new_disabled)
	context_button.action = new_action
	context_button.calibrate()
	return context_button

static func create_checkbox_from_action(new_action: String, start_toggled_on: bool, new_disabled := false) -> ContextButton:
	var context_button := ContextButton.create_from_action(new_action, new_disabled)
	context_button.type = Type.CHECKBOX
	context_button.toggled_on = start_toggled_on
	context_button.calibrate()
	return context_button

static func create_arrow(new_text: String, new_submenu_button_builders: Array[Callable]) -> ContextButton:
	var context_button := ContextButton.new()
	context_button.custom_text = new_text
	context_button.type = Type.ARROW
	context_button.submenu_button_builders = new_submenu_button_builders
	
	var enter_timer := Timer.new()
	enter_timer.wait_time = 0.16
	enter_timer.one_shot = true
	context_button.add_child(enter_timer)
	var exit_timer := Timer.new()
	exit_timer.wait_time = 0.16
	exit_timer.one_shot = true
	context_button.add_child(exit_timer)
	
	context_button.mouse_entered.connect(
		func() -> void:
			exit_timer.stop()
			enter_timer.start()
	)
	enter_timer.timeout.connect(func() -> void:
		if HandlerGUI.popup_submenu_source != context_button:
			var options: Array[ContextButton] = []
			for button_builder in context_button.submenu_button_builders:
				options.append(button_builder.call())
			HandlerGUI.popup_submenu_to_right_or_left_side(ContextPopup.create(options), context_button)
	)
	
	context_button.ready.connect(
		func() -> void:
			var popup := context_button.get_parent()
			while is_instance_valid(popup) and not popup is ContextPopup:
				popup = popup.get_parent()
			
			popup.gui_input.connect(func(event: InputEvent) -> void:
				if not (enter_timer.is_stopped() or Rect2(Vector2.ZERO, context_button.size).has_point(context_button.get_local_mouse_position())):
					enter_timer.stop()
				
				if HandlerGUI.popup_submenu_source == context_button and event is InputEventMouseMotion:
					if not Rect2(Vector2.ZERO, context_button.size).has_point(context_button.get_local_mouse_position()):
						if exit_timer.is_stopped() and Rect2(Vector2.ZERO, popup.size).grow(-2).has_point(event.position):
							exit_timer.start()
			)
	)
	
	exit_timer.timeout.connect(
		func() -> void:
			var popup := context_button.get_parent()
			while is_instance_valid(popup) and not popup is ContextPopup:
				popup = popup.get_parent()
			
			if Rect2(Vector2.ZERO, popup.size).grow(-2).has_point(popup.get_local_mouse_position()):
				HandlerGUI.clear_submenu()
	)
	context_button.calibrate()
	return context_button

func calibrate() -> void:
	# Calculate min width.
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var icon := get_icon()
	var text := get_text()
	var dim_text := get_dim_text()
	
	var min_width := PADDING * 2
	if not text.is_empty():
		min_width += font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if not dim_text.is_empty():
		min_width += DIM_TEXT_SPACING + font.get_string_size(dim_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if is_instance_valid(icon) or type != Type.NORMAL:
		min_width += 16.0 + ICON_SPACING
	custom_minimum_size.x = min_width
	# Set mouse cursor shape.
	if disabled or type == Type.ARROW:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func add_custom_text(new_text: String) -> ContextButton:
	custom_text = new_text
	calibrate()
	return self

func set_icon_none() -> ContextButton:
	use_icon = false
	calibrate()
	return self

func set_icon_unmodulated() -> ContextButton:
	skip_icon_modulation = true
	calibrate()
	return self

func add_custom_icon(new_icon: Texture2D) -> ContextButton:
	custom_icon = new_icon
	calibrate()
	return self

func add_custom_dim_text(new_dim_text: String) -> ContextButton:
	custom_dim_text = new_dim_text
	calibrate()
	return self


func get_callback() -> Callable:
	return custom_callback if custom_callback.is_valid() else HandlerGUI.throw_action_event.bind(action)

func get_text() -> String:
	return custom_text if not custom_text.is_empty() else TranslationUtils.get_action_description(action, true)

func get_dim_text() -> String:
	return custom_dim_text if not custom_dim_text.is_empty() else ShortcutUtils.get_action_showcase_text(action)

func get_icon() -> Texture2D:
	if type == Type.ARROW or not use_icon:
		return null
	elif is_instance_valid(custom_icon):
		return custom_icon
	elif not action.is_empty():
		return ShortcutUtils.get_action_icon(action)
	return null
