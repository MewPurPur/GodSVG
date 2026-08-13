extends PanelContainer

const delete_icon := preload("res://assets/icons/Delete.svg")

# The widget's whole purpose is to emit this signal with the way signals should be changed.
signal shortcuts_edited(new_shortcuts: Array[InputEvent])

@onready var label: Label = %MainContainer/Label
@onready var reset_button: Button = %MainContainer/HBoxContainer/ResetButton
@onready var shortcut_container: HBoxContainer = %ShortcutContainer
@onready var shortcut_buttons: Array[Button] = [%ShortcutContainer/Button, %ShortcutContainer/Button2, %ShortcutContainer/Button3]

var action: String

var listening_index := -1
var pending_event: InputEventKey


func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	Configs.language_changed.connect(sync_buttons)
	Configs.shortcuts_changed.connect(sync_buttons)
	sync_buttons()
	
	for i in 3:
		var btn := shortcut_buttons[i]
		btn.pressed.connect(enter_listening_mode.bind(i))

func sync_localization() -> void:
	reset_button.tooltip_text = Translator.translate("Reset to default")
	label.text = TranslationUtils.get_action_description(action)

# Syncs based on current events.
func sync_buttons() -> void:
	var events := InputMap.action_get_events(action)
	# Show the reset button if any of the actions don't match.
	var action_defaults: Array[InputEvent] = Configs.default_shortcuts[action]
	if events.size() != action_defaults.size():
		reset_button.show()
	else:
		var is_value_changed := false
		for i in events.size():
			if not events[i].is_match(action_defaults[i]):
				is_value_changed = true
				break
		reset_button.visible = is_value_changed
	# Sync the shortcut buttons.
	for i in 3:
		var btn := shortcut_buttons[i]
		for child in btn.get_children():
			child.queue_free()
		btn.icon = null
		
		if i < events.size():
			_set_shortcut_button_text(btn, events[i].as_text_keycode())
		else:
			btn.begin_bulk_theme_override()
			btn.add_theme_color_override("font_color", Color(ThemeUtils.editable_text_color, 0.4))
			btn.add_theme_color_override("font_hover_color", Color(ThemeUtils.editable_text_color, 0.4))
			btn.add_theme_color_override("font_pressed_color", Color(ThemeUtils.editable_text_color, 0.6))
			btn.add_theme_color_override("font_focus_color", Color(ThemeUtils.editable_text_color, 0.6))
			btn.end_bulk_theme_override()
			_set_shortcut_button_text(btn, Translator.translate("Unused"))
			if i == events.size():
				btn.tooltip_text = Translator.translate("Add shortcut")
			else:
				btn.disabled = true
				btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
	# Sync shortcut validity.
	for i in events.size():
		var event := events[i]
		var shortcut_btn := shortcut_buttons[i]
		if not Configs.savedata.is_shortcut_valid(event):
			_setup_shortcut_button_font_colors(shortcut_btn, Configs.savedata.basic_color_error)
			var conflicts := Configs.savedata.get_actions_with_shortcut(event)
			conflicts.erase(action)
			if conflicts.size() > 8:
				conflicts.resize(8)
				conflicts.append("...")
			for ii in conflicts.size():
				conflicts[ii] = TranslationUtils.get_action_description(conflicts[ii])
			shortcut_btn.tooltip_text = Translator.translate("Also used by") + ":\n" + "\n".join(conflicts)
		else:
			var already_used := false
			for ii in events.size():
				if ii != i and event.is_match(events[ii]):
					already_used = true
					break
			
			if already_used:
				_setup_shortcut_button_font_colors(shortcut_btn, Configs.savedata.basic_color_warning)
			else:
				shortcut_btn.begin_bulk_theme_override()
				shortcut_btn.remove_theme_color_override("font_color")
				shortcut_btn.remove_theme_color_override("font_focus_color")
				shortcut_btn.remove_theme_color_override("font_hover_color")
				shortcut_btn.remove_theme_color_override("font_pressed_color")
				shortcut_btn.end_bulk_theme_override()
				shortcut_btn.tooltip_text = ""
	var focus_sequence: Array[Control]
	focus_sequence.assign(shortcut_buttons)
	focus_sequence.append(reset_button)
	HandlerGUI.register_focus_sequence(self, focus_sequence)


func _input(event: InputEvent) -> void:
	if not (listening_index >= 0 and event is InputEventKey):
		if listening_index != -1 and event is InputEventMouseButton and event.is_pressed() and\
		event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and\
		not shortcut_buttons[listening_index].get_global_rect().has_point(event.global_position):
			cancel_listening()
		return
	
	var shortcut_button := shortcut_buttons[listening_index]
	if shortcut_button.icon != null:
		# Button has delete icon.
		shortcut_button.icon = null
		for child in shortcut_button.get_children():
			child.queue_free()
	
	if event.is_action("ui_cancel"):
		cancel_listening()
		_setup_shortcut_button_font_colors(shortcut_button, ThemeUtils.editable_text_color)
		accept_event()
	elif event.is_pressed():
		pending_event = event
		_set_shortcut_button_text(shortcut_button, event.as_text_keycode())
		_setup_shortcut_button_font_colors(shortcut_button, Configs.savedata.basic_color_warning if\
				(pending_event.keycode & KEY_MODIFIER_MASK != 0) else ThemeUtils.editable_text_color)
		accept_event()
	elif event.is_released():
		if pending_event.keycode & KEY_MODIFIER_MASK == 0:
			var normalized_event := InputEventKey.new()
			normalized_event.device = -1
			normalized_event.command_or_control_autoremap = (pending_event.ctrl_pressed or pending_event.meta_pressed)
			normalized_event.keycode = pending_event.keycode
			normalized_event.unicode = pending_event.unicode
			normalized_event.alt_pressed = pending_event.alt_pressed
			normalized_event.shift_pressed = pending_event.shift_pressed
			# Saves the event.
			var new_events := InputMap.action_get_events(action)
			if listening_index < new_events.size():
				new_events[listening_index] = normalized_event
			else:
				new_events.append(normalized_event)
			shortcuts_edited.emit(new_events)
		cancel_listening()


func enter_listening_mode(index: int) -> void:
	# Clicking the button we're already listening to cancels listening.
	if listening_index == index:
		cancel_listening()
		return
	# If we're listening to another button, stop that first.
	if listening_index != -1:
		cancel_listening()
	
	listening_index = index
	var btn := shortcut_buttons[index]
	_setup_shortcut_button_font_colors(btn, ThemeUtils.editable_text_color)
	# Workaround to show modifier keys pressed at the time of clicking.
	var is_shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	var is_alt_pressed := Input.is_key_pressed(KEY_ALT)
	var is_ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var is_meta_pressed := Input.is_key_pressed(KEY_META)
	if is_shift_pressed or is_alt_pressed or is_ctrl_pressed or is_meta_pressed:
		var activation_event := InputEventKey.new()
		activation_event.pressed = true
		# Need to pretend that one of the keys was pressed last. It doesn't matter which.
		if is_shift_pressed:
			activation_event.keycode = KEY_SHIFT
			activation_event.command_or_control_autoremap = is_ctrl_pressed or is_meta_pressed
			activation_event.alt_pressed = is_alt_pressed
		elif is_alt_pressed:
			activation_event.keycode = KEY_ALT
			activation_event.command_or_control_autoremap = is_ctrl_pressed or is_meta_pressed
		elif is_ctrl_pressed:
			activation_event.keycode = KEY_CTRL
		elif is_meta_pressed:
			activation_event.keycode = KEY_META
		
		_set_shortcut_button_text(btn, activation_event.as_text_keycode())
		pending_event = activation_event
	else:
		_set_shortcut_button_text(btn, Translator.translate("Press keys…"))
	# Add delete button if editing an existing shortcut.
	if index < InputMap.action_get_events(action).size():
		var delete_btn := Button.new()
		delete_btn.icon = delete_icon
		delete_btn.theme_type_variation = "FlatButton"
		const CONST_ARR: PackedStringArray = ["normal", "hover", "pressed"]
		delete_btn.begin_bulk_theme_override()
		for theme_item in CONST_ARR:
			var sb := delete_btn.get_theme_stylebox(theme_item, "FlatButton").duplicate()
			sb.set_content_margin_all(0)
			delete_btn.add_theme_stylebox_override(theme_item, sb)
		delete_btn.end_bulk_theme_override()
		delete_btn.tooltip_text = Translator.translate("Delete")
		delete_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		delete_btn.focus_mode = Control.FOCUS_NONE
		delete_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		delete_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(delete_btn)
		delete_btn.position = Vector2(1, 1)
		delete_btn.size = Vector2(btn.size.y - 2, btn.size.y - 2)
		delete_btn.pressed.connect(delete_shortcut.bind(index))
		# Fake delete icon to offset the main button's text.
		btn.icon = ImageTexture.create_from_image(Image.create(delete_icon.get_width(), delete_icon.get_height(), false, Image.FORMAT_LA8))
	queue_redraw()

func cancel_listening() -> void:
	listening_index = -1
	pending_event = null
	sync_buttons.call_deferred()
	queue_redraw()

func delete_shortcut(index: int) -> void:
	var new_events := InputMap.action_get_events(action)
	new_events.remove_at(index)
	shortcuts_edited.emit(new_events)

func _on_reset_button_pressed() -> void:
	shortcuts_edited.emit(Configs.default_shortcuts[action])


func _draw() -> void:
	# If the focus is hidden, use the focus style for the listening shortcut, otherwise add a subtle second border.
	var ci := shortcut_container.get_canvas_item()
	RenderingServer.canvas_item_clear(ci)
	if listening_index >= 0:
		var listening_stylebox: StyleBoxFlat = get_theme_stylebox("focus", "Button").duplicate()
		var btn := shortcut_buttons[listening_index]
		if btn.has_focus(true):
			listening_stylebox.border_color.a *= 0.6
			listening_stylebox.corner_radius_top_left += 2
			listening_stylebox.corner_radius_bottom_left += 2
			listening_stylebox.corner_radius_top_right += 2
			listening_stylebox.corner_radius_bottom_right += 2
			listening_stylebox.draw(ci, btn.get_rect().grow(2))
		else:
			listening_stylebox.draw(ci, btn.get_rect())

func _setup_shortcut_button_font_colors(button: Button, color: Color) -> void:
	var dim_color := Color(color, 0.8)
	button.begin_bulk_theme_override()
	button.add_theme_color_override("font_color", dim_color)
	button.add_theme_color_override("font_focus_color", dim_color)
	button.add_theme_color_override("font_hover_color", dim_color)
	button.add_theme_color_override("font_pressed_color", dim_color)
	button.end_bulk_theme_override()

func _set_shortcut_button_text(button: Button, new_text: String) -> void:
	# Make the font smaller for long shortcuts.
	button.remove_theme_font_size_override("font_size")
	while button.get_theme_font("font").get_string_size(new_text, HORIZONTAL_ALIGNMENT_LEFT,
	-1, button.get_theme_font_size("font_size")).x > button.custom_minimum_size.x:
		button.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size") - 1)
	button.text = new_text
