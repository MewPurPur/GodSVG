class_name ContextPopup extends PanelContainer

func setup_button(btn: Button, align_left: bool) -> Button:
	if not btn is CheckBox:
		btn.theme_type_variation = "ContextButton"
		btn.pressed.connect(HandlerGUI.remove_popup_overlay)
		btn.ready.connect(_order_signals.bind(btn))
	btn.focus_mode = Control.FOCUS_NONE
	if align_left:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return btn

# A hack to deal with situations where a popup is replaced by another.
func _order_signals(btn: Button) -> void:
	for connection in btn.pressed.get_connections():
		if connection.callable != HandlerGUI.remove_popup_overlay:
			btn.pressed.disconnect(connection.callable)
			btn.pressed.connect(connection.callable, CONNECT_DEFERRED)
	set_block_signals(true)


func setup(buttons: Array[Button], align_left := false, min_width := -1.0,
separator_indices: Array[int] = []) -> void:
	var main_container := _common_initial_setup()
	# Add the buttons.
	if buttons.is_empty():
		return
	else:
		for idx in buttons.size():
			if idx in separator_indices:
				var separator := HSeparator.new()
				separator.theme_type_variation = "SmallHSeparator"
				main_container.add_child(separator)
			main_container.add_child(setup_button(buttons[idx], align_left))
		if min_width > 0:
			custom_minimum_size.x = ceili(min_width)


func setup_with_title(buttons: Array[Button], top_title: String, align_left := false,
min_width := -1.0, separator_indices: Array[int] = []) -> void:
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
		stylebox.border_color = ThemeGenerator.common_separator_color
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
			main_container.add_child(setup_button(buttons[idx], align_left))
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
