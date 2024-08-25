class_name ContextPopup extends PanelContainer
## Standard popup for actions with methods for easy setup.

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


static func create_button(text: String, press_action: Callable, disabled := false,
icon: Texture2D = null, shortcut := "") -> Button:
	# Create main button.
	var main_button := Button.new()
	main_button.text = text
	if is_instance_valid(icon):
		main_button.icon = icon
	
	if not shortcut.is_empty():
		if not InputMap.has_action(shortcut):
			push_error("Non-existent shortcut was passed to ContextPopup.create_button().")
		elif InputMap.has_action(shortcut):
			var events := InputMap.action_get_events(shortcut)
			if not events.is_empty():
				# Add button with a shortcut.
				var ret_button := Button.new()
				ret_button.theme_type_variation = "ContextButton"
				ret_button.focus_mode = Control.FOCUS_NONE
				ret_button.shortcut_in_tooltip = false
				if disabled:
					main_button.disabled = true
					ret_button.disabled = true
				else:
					ret_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				for theme_item in ["normal", "hover", "pressed", "disabled"]:
					main_button.add_theme_stylebox_override(theme_item,
							main_button.get_theme_stylebox("normal", "ContextButton"))
				var internal_hbox := HBoxContainer.new()
				main_button.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Unpressable.
				internal_hbox.add_theme_constant_override("separation", 6)
				main_button.add_theme_color_override("icon_normal_color",
						ret_button.get_theme_color("icon_normal_color", "ContextButton"))
				var label_margin := MarginContainer.new()
				label_margin.add_theme_constant_override("margin_right",
						int(ret_button.get_theme_stylebox("normal").content_margin_right))
				var label := Label.new()
				label.text = events[0].as_text_keycode()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				var shortcut_text_color := ThemeUtils.common_subtle_text_color
				if disabled:
					shortcut_text_color.a *= 0.75
				label.add_theme_color_override("font_color", shortcut_text_color)
				label.add_theme_font_size_override("font_size",
						main_button.get_theme_font_size("font_size"))
				
				ret_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				internal_hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
				label_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.size_flags_horizontal = Control.SIZE_FILL
				internal_hbox.add_child(main_button)
				label_margin.add_child(label)
				internal_hbox.add_child(label_margin)
				ret_button.add_child(internal_hbox)
				ret_button.pressed.connect(press_action)
				ret_button.pressed.connect(HandlerGUI.remove_popup_overlay)
				
				var shortcut_obj := Shortcut.new()
				var action_obj := InputEventAction.new()
				action_obj.action = shortcut
				shortcut_obj.events.append(action_obj)
				ret_button.shortcut = shortcut_obj
				ret_button.shortcut_feedback = false
				return ret_button
	# Finish setting up the main button and return it if there's no shortcut.
	main_button.theme_type_variation = "ContextButton"
	main_button.focus_mode = Control.FOCUS_NONE
	if disabled:
		main_button.disabled = true
	else:
		main_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not press_action.is_null():
		main_button.pressed.connect(press_action)
	main_button.pressed.connect(HandlerGUI.remove_popup_overlay)
	return main_button

static func create_checkbox(text: String, toggle_action: Callable,
start_pressed: bool, shortcut := "") -> CheckBox:
	# Create main checkbox.
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.button_pressed = start_pressed
	checkbox.toggled.connect(toggle_action.unbind(1))
	
	if not shortcut.is_empty():
		if not InputMap.has_action(shortcut):
			push_error("Non-existent shortcut was passed to ContextPopup.create_checkbox().")
		elif InputMap.has_action(shortcut):
			var events := InputMap.action_get_events(shortcut)
			if not events.is_empty():
				# Add button with a shortcut.
				var ret_button := Button.new()
				ret_button.theme_type_variation = "ContextButton"
				ret_button.focus_mode = Control.FOCUS_NONE
				ret_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				ret_button.shortcut_in_tooltip = false
				for theme_stylebox in ["normal", "pressed"]:
					checkbox.add_theme_stylebox_override(theme_stylebox,
							checkbox.get_theme_stylebox("normal", "ContextButton"))
				var internal_hbox := HBoxContainer.new()
				checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Unpressable.
				internal_hbox.add_theme_constant_override("separation", 6)
				checkbox.add_theme_color_override("icon_normal_color",
						ret_button.get_theme_color("icon_normal_color", "ContextButton"))
				var label_margin := MarginContainer.new()
				label_margin.add_theme_constant_override("margin_right",
						int(ret_button.get_theme_stylebox("normal").content_margin_right))
				var label := Label.new()
				label.text = events[0].as_text_keycode()
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				var shortcut_text_color := ThemeUtils.common_subtle_text_color
				#if disabled:
					#shortcut_text_color.a *= 0.75
				label.add_theme_color_override("font_color", shortcut_text_color)
				label.add_theme_font_size_override("font_size",
						checkbox.get_theme_font_size("font_size"))
				
				ret_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				internal_hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
				label_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.size_flags_horizontal = Control.SIZE_FILL
				internal_hbox.add_child(checkbox)
				label_margin.add_child(label)
				internal_hbox.add_child(label_margin)
				ret_button.add_child(internal_hbox)
				ret_button.pressed.connect(
						func(): checkbox.button_pressed = not checkbox.button_pressed)
				
				var shortcut_obj := Shortcut.new()
				var action_obj := InputEventAction.new()
				action_obj.action = shortcut
				shortcut_obj.events.append(action_obj)
				ret_button.shortcut = shortcut_obj
				ret_button.shortcut_feedback = false
				return ret_button
	# Finish setting up the checkbox and return it if there's no shortcut.
	checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	checkbox.focus_mode = Control.FOCUS_NONE
	return checkbox

func _setup_button(btn: Button, align_left: bool) -> Button:
	if align_left:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.ready.connect(_order_signals.bind(btn))
	if btn.get_child_count() == 1:
		btn.get_child(0).resized.connect(_resize_button_around_child.bind(btn))
	return btn

# A hack to deal with situations where a popup is replaced by another.
func _order_signals(btn: Button) -> void:
	for connection in btn.pressed.get_connections():
		if connection.callable != HandlerGUI.remove_popup_overlay:
			btn.pressed.disconnect(connection.callable)
			btn.pressed.connect(connection.callable, CONNECT_DEFERRED)
	set_block_signals(true)

# A hack for buttons that are wrapped around a control.
func _resize_button_around_child(btn: Button) -> void:
	var child: Control = btn.get_child(0)
	btn.custom_minimum_size = child.size

func setup(buttons: Array[Button], align_left := false, min_width := -1.0,
separator_indices := PackedInt32Array()) -> void:
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
	if min_width > 0:
		custom_minimum_size.x = ceili(min_width)


func setup_with_title(buttons: Array[Button], top_title: String, align_left := false,
min_width := -1.0, separator_indices := PackedInt32Array()) -> void:
	var main_container := _common_initial_setup()
	# Add the buttons.
	if buttons.is_empty():
		return
	else:
		# Setup the title.
		var title_container := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color("#0003")
		stylebox.content_margin_bottom = 3
		stylebox.content_margin_left = 8
		stylebox.content_margin_right = 8
		stylebox.border_width_bottom = 2
		stylebox.border_color = ThemeUtils.common_panel_border_color
		title_container.add_theme_stylebox_override("panel", stylebox)
		var title_label := Label.new()
		title_label.text = top_title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.begin_bulk_theme_override()
		title_label.add_theme_color_override("font_color", Color("def"))
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.end_bulk_theme_override()
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

# Helper.
func _common_initial_setup() -> VBoxContainer:
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.shadow_color = Color(0, 0, 0, 0.08)
	stylebox.shadow_size = 8
	add_theme_stylebox_override("panel", stylebox)
	var main_container := VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("separation", 0)
	add_child(main_container)
	return main_container
