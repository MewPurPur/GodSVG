## Standard popup for actions with methods for easy setup.
class_name ContextPopup extends PanelContainer

const arrow = preload("res://assets/icons/PopupArrow.svg")

static func create_shortcut_button(action: String, disabled := false, custom_text := "", custom_icon: Texture2D = null, no_modulation := false) -> Button:
	if not InputMap.has_action(action):
		push_error("Non-existent shortcut was passed.")
		return
	
	if custom_text.is_empty():
		custom_text = TranslationUtils.get_action_description(action, true)
	if not is_instance_valid(custom_icon):
		custom_icon = ShortcutUtils.get_action_icon(action)
	var btn := create_button(custom_text, HandlerGUI.throw_action_event.bind(action),
			disabled, custom_icon, no_modulation, ShortcutUtils.get_action_showcase_text(action))
	
	if not ShortcutUtils.get_action_all_valid_shortcuts(action).is_empty():
		var shortcuts := ShortcutsRegistration.new()
		shortcuts.add_shortcut(action, btn.pressed.emit)
		HandlerGUI.register_shortcuts(btn, shortcuts)
	
	return btn

static func create_shortcut_button_without_icon(action: String, disabled := false, custom_text := "") -> Button:
	if not InputMap.has_action(action):
		push_error("Non-existent shortcut was passed.")
		return
	
	if custom_text.is_empty():
		custom_text = TranslationUtils.get_action_description(action, true)
	var btn := create_button(custom_text, HandlerGUI.throw_action_event.bind(action),
			disabled, null, false, ShortcutUtils.get_action_showcase_text(action))
	
	if not ShortcutUtils.get_action_all_valid_shortcuts(action).is_empty():
		var shortcuts := ShortcutsRegistration.new()
		shortcuts.add_shortcut(action, btn.pressed.emit)
		HandlerGUI.register_shortcuts(btn, shortcuts)
	
	return btn

static func create_button(text: String, press_callback: Callable, disabled := false, icon: Texture2D = null, no_modulation := false, dim_text := "") -> Button:
	# Create main button.
	var main_button := Button.new()
	main_button.theme_type_variation = "ContextButton"
	main_button.focus_mode = Control.FOCUS_NONE
	if disabled:
		main_button.disabled = true
	else:
		main_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	main_button.text = text
	if is_instance_valid(icon):
		main_button.add_theme_constant_override("icon_max_width", 16)
		main_button.icon = icon
		if no_modulation:
			main_button.begin_bulk_theme_override()
			main_button.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.875))
			main_button.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 1))
			main_button.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 1))
			main_button.end_bulk_theme_override()
	
	if press_callback.is_valid():
		main_button.pressed.connect(press_callback, CONNECT_ONE_SHOT)
	main_button.pressed.connect(HandlerGUI.remove_popup)
	
	if not dim_text.is_empty():
		var font := main_button.get_theme_font("font")
		var font_size := main_button.get_theme_font_size("font_size")
		var dim_text_width := font.get_string_size(dim_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x
		
		var shortcut_text_color := ThemeUtils.subtle_text_color
		if disabled:
			shortcut_text_color.a *= 0.75
		
		main_button.begin_bulk_theme_override()
		var CONST_ARR: PackedStringArray = ["normal", "hover", "pressed", "disabled"]
		for theme_style in CONST_ARR:
			var sb := main_button.get_theme_stylebox(theme_style, "ContextButton").duplicate()
			sb.content_margin_right += dim_text_width + 8
			main_button.add_theme_stylebox_override(theme_style, sb)
		main_button.end_bulk_theme_override()
		
		var on_main_button_draw := func() -> void:
				var sb := ThemeDB.get_default_theme().get_stylebox("normal", "ContextButton")
				font.draw_string(main_button.get_canvas_item(), Vector2(0, sb.content_margin_top + font.get_ascent(font_size)), dim_text,
						HORIZONTAL_ALIGNMENT_RIGHT, main_button.size.x - sb.content_margin_right, font_size, shortcut_text_color)
		main_button.draw.connect(on_main_button_draw)
	
	return main_button


static func create_shortcut_checkbox(action: String, start_toggled: bool, disabled := false) -> CheckBox:
	if not InputMap.has_action(action):
		push_error("Non-existent shortcut was passed.")
		return
	
	return create_checkbox(TranslationUtils.get_action_description(action, true),
			HandlerGUI.throw_action_event.bind(action), start_toggled, disabled, ShortcutUtils.get_action_showcase_text(action))

static func create_checkbox(text: String, toggle_action: Callable, start_toggled: bool, disabled := false, dim_text := "") -> CheckBox:
	# Create main checkbox.
	var checkbox := CheckBox.new()
	checkbox.focus_mode = Control.FOCUS_NONE
	if disabled:
		checkbox.disabled = true
	else:
		checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	checkbox.text = text
	checkbox.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	checkbox.button_pressed = start_toggled
	checkbox.toggled.connect(toggle_action.unbind(1))
	
	if not dim_text.is_empty():
		var font := checkbox.get_theme_font("font")
		var font_size := checkbox.get_theme_font_size("font_size")
		var dim_text_width := font.get_string_size(dim_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x
		
		var shortcut_text_color := ThemeUtils.subtle_text_color
		if disabled:
			shortcut_text_color.a *= 0.75
		
		checkbox.begin_bulk_theme_override()
		var CONST_ARR: PackedStringArray = ["normal", "hover", "pressed", "disabled"]
		for theme_style in CONST_ARR:
			var sb := checkbox.get_theme_stylebox(theme_style, "CheckBox").duplicate()
			sb.content_margin_right += dim_text_width + 8
			checkbox.add_theme_stylebox_override(theme_style, sb)
		checkbox.end_bulk_theme_override()
		
		var on_shortcut_draw := func() -> void:
				var sb := ThemeDB.get_default_theme().get_stylebox("normal", "CheckBox")
				font.draw_string(checkbox.get_canvas_item(), Vector2(0, sb.content_margin_top + font.get_ascent(font_size)), dim_text,
						HORIZONTAL_ALIGNMENT_RIGHT, checkbox.size.x - sb.content_margin_right, font_size, shortcut_text_color)
		checkbox.draw.connect(on_shortcut_draw)
	
	return checkbox

func _setup_button(btn: Button, align_left: bool) -> Button:
	if align_left:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.ready.connect(_order_signals.bind(btn))
	return btn

# A hack to deal with situations where a popup is replaced by another.
func _order_signals(btn: Button) -> void:
	for connection in btn.pressed.get_connections():
		if connection.callable != HandlerGUI.remove_popup:
			btn.pressed.disconnect(connection.callable)
			btn.pressed.connect(connection.callable, CONNECT_DEFERRED)
	set_block_signals(true)

func setup(buttons: Array[Button], align_left := false, min_width := -1.0, separator_indices := PackedInt32Array()) -> void:
	var main_container := _common_initial_setup()
	# Add the buttons.
	if buttons.is_empty():
		return
	
	for idx in buttons.size():
		if idx in separator_indices:
			var separator := HSeparator.new()
			separator.theme_type_variation = "SmallHSeparator"
			main_container.add_child(separator)
		main_container.add_child(_setup_button(buttons[idx], align_left))
	
	# Without this delay, get_minimum_size().y was returning a value larger than expected.
	await main_container.ready
	if min_width > 0:
		custom_minimum_size.x = min_width
	
	var max_height := get_window().size.y / 2.0 - 16.0
	if get_minimum_size().y > max_height:
		custom_minimum_size.y = max_height
		main_container.get_parent().vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


func setup_with_title(buttons: Array[Button], top_title: String, align_left := false,
min_width := -1.0, max_height := -1.0, separator_indices := PackedInt32Array()) -> void:
	var main_container := _common_initial_setup()
	# Add the buttons.
	if buttons.is_empty():
		return
	
	# Setup the title.
	var title_container := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = ThemeUtils.context_button_color_disabled
	stylebox.content_margin_bottom = 3.0
	stylebox.content_margin_left = 8.0
	stylebox.content_margin_right = 8.0
	stylebox.border_width_bottom = 2
	stylebox.border_color = ThemeUtils.basic_panel_border_color
	title_container.add_theme_stylebox_override("panel", stylebox)
	var title_label := Label.new()
	title_label.text = top_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme_type_variation = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 14)
	title_container.add_child(title_label)
	main_container.add_child(title_container)
	# Continue with regular setup logic.
	for idx in buttons.size():
		if idx in separator_indices:
			var separator := HSeparator.new()
			separator.theme_type_variation = "SmallHSeparator"
			main_container.add_child(separator)
		main_container.add_child(_setup_button(buttons[idx], align_left))
	if min_width > 0:
		custom_minimum_size.x = min_width
	if max_height > 0 and max_height < get_minimum_size().y:
		custom_minimum_size.y = max_height
		main_container.get_parent().vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


# Helper.
func _common_initial_setup() -> VBoxContainer:
	# Create a ScrollContainer to allow scrolling.
	var scroll_container := ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Increase the scrollbar area on Android.
	if OS.get_name() == "Android":
		var scrollbar := scroll_container.get_v_scroll_bar()
		var stylebox := scrollbar.get_theme_stylebox("scroll").duplicate()
		stylebox.content_margin_left = 10.0
		stylebox.content_margin_right = 10.0
		scrollbar.add_theme_stylebox_override("scroll", stylebox)
	
	var main_container := VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 0)
	
	scroll_container.add_child(main_container)
	add_child(scroll_container)
	return main_container
