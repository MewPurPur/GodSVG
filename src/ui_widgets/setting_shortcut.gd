extends PanelContainer

const delete_icon := preload("res://assets/icons/Delete.svg")

@onready var label: Label = %MainContainer/Label
@onready var reset_button: Button = %MainContainer/HBoxContainer/ResetButton
@onready var shortcut_container: HBoxContainer = %ShortcutContainer
@onready var shortcut_buttons: Array[Button] = []

var action: String
var events: Array[InputEvent] = []

var listening_idx := -1
var pending_event: InputEventKey

func update_translation() -> void:
	reset_button.tooltip_text = Translator.translate("Reset to default")

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	Configs.language_changed.connect(update_translation)
	Configs.shortcuts_changed.connect(check_shortcuts_validity)
	update_translation()

func setup(new_action: String) -> void:
	action = new_action
	events = InputMap.action_get_events(action)
	sync()

# Syncs based on current events.
func sync() -> void:
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
	# Clear the existing buttons.
	shortcut_buttons.clear()
	for button in shortcut_container.get_children():
		button.queue_free()
	# Create new ones.
	for i in 3:
		var new_btn := Utils.make_standard_button()
		shortcut_container.add_child.call_deferred(new_btn)
		shortcut_buttons.append(new_btn)
		new_btn.theme_type_variation = "TranslucentButton"
		for style in ["normal", "hover", "pressed", "disabled"]:
			var shortcut_stylebox := get_theme_stylebox(style, "TranslucentButton").duplicate()
			shortcut_stylebox.content_margin_top = 0
			shortcut_stylebox.content_margin_bottom = 0
			new_btn.add_theme_stylebox_override(style, shortcut_stylebox)
		
		new_btn.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
		new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		new_btn.custom_minimum_size = Vector2(116, 24)
		
		if i < events.size():
			set_shortcut_button_text(new_btn, events[i].as_text_keycode())
			new_btn.pressed.connect(enter_listening_mode.bind(i, true))
		else:
			new_btn.begin_bulk_theme_override()
			new_btn.add_theme_color_override("font_color", Color("def6"))
			new_btn.add_theme_color_override("font_hover_color", Color("def6"))
			new_btn.add_theme_color_override("font_pressed_color", Color("def8"))
			new_btn.end_bulk_theme_override()
			set_shortcut_button_text(new_btn, Translator.translate("Unused"))
			if i == events.size():
				new_btn.tooltip_text = Translator.translate("Add shortcut")
				new_btn.pressed.connect(enter_listening_mode.bind(i))
			else:
				new_btn.disabled = true
				new_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
	check_shortcuts_validity()


func enter_listening_mode(idx: int, show_delete_button := false) -> void:
	listening_idx = idx
	var btn := shortcut_buttons[idx]
	setup_shortcut_button_font_colors(btn, Color("def"))
	btn.focus_mode = Control.FOCUS_CLICK
	btn.grab_focus()
	if btn.pressed.is_connected(enter_listening_mode):
		btn.pressed.disconnect(enter_listening_mode)
	btn.pressed.connect(cancel_listening)
	btn.focus_exited.connect(cancel_listening)
	# Workaround to show the keys pressed at the time of clicking.
	var activation_event := InputEventKey.new()
	activation_event.pressed = true
	activation_event.ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	activation_event.shift_pressed = Input.is_key_pressed(KEY_SHIFT)
	activation_event.alt_pressed = Input.is_key_pressed(KEY_ALT)
	set_shortcut_button_text(btn, activation_event.as_text_keycode().\
			trim_suffix("(Unset)").trim_suffix("+"))
	if btn.text.is_empty():
		set_shortcut_button_text(btn, Translator.translate("Press keys…"))
	# Add optional delete button.
	if show_delete_button:
		btn.icon = delete_icon
		var delete_btn := Utils.make_standard_button()
		delete_btn.theme_type_variation = "FlatButton"
		delete_btn.tooltip_text = Translator.translate("Delete")
		# Position the delete button around the delte icon. Seems like the simplest way
		# to set up something that looks like a delete button, without needing to make
		# complex node hierarchies.
		delete_btn.size = Vector2(btn.size.y - 2, btn.size.y)
		btn.add_child(delete_btn)
		delete_btn.pressed.connect(delete_shortcut.bind(idx))

func cancel_listening() -> void:
	listening_idx = -1
	sync()


func delete_shortcut(idx: int) -> void:
	events.remove_at(idx)
	update_shortcut()
	sync()

func update_shortcut() -> void:
	Configs.savedata.action_modify_shortcuts(action, events)

func _input(event: InputEvent) -> void:
	if not (listening_idx >= 0 and event is InputEventKey):
		return
	
	var shortcut_button := shortcut_buttons[listening_idx]
	if shortcut_button.icon != null:
		# Button has delete icon.
		shortcut_button.icon = null
		for child in shortcut_button.get_children():
			child.queue_free()
	
	if event.is_action("ui_cancel"):
		cancel_listening()
		pending_event = null
		setup_shortcut_button_font_colors(shortcut_button, Color("def"))
		accept_event()
	elif event.is_pressed():
		set_shortcut_button_text(shortcut_button, event.as_text_keycode())
		pending_event = event
		if pending_event.keycode & KEY_MODIFIER_MASK != 0:
			setup_shortcut_button_font_colors(shortcut_button,
					Configs.savedata.basic_color_warning)
		else:
			setup_shortcut_button_font_colors(shortcut_button, Color("def"))
		accept_event()
	elif event.is_released():
		if pending_event.keycode & KEY_MODIFIER_MASK == 0:
			if listening_idx < events.size():
				events[listening_idx] = pending_event
			else:
				events.append(pending_event)
		update_shortcut()
		sync()
		pending_event = null
		setup_shortcut_button_font_colors(shortcut_button, Color("def"))
		listening_idx = -1

func _on_reset_button_pressed() -> void:
	events = Configs.default_shortcuts[action].duplicate(true)
	update_shortcut()
	sync()

func setup_shortcut_button_font_colors(button: Button, color: Color) -> void:
	var dim_color := Color(color, 0.8)
	button.begin_bulk_theme_override()
	button.add_theme_color_override("font_color", dim_color)
	button.add_theme_color_override("font_focus_color", dim_color)
	button.add_theme_color_override("font_hover_color", dim_color)
	button.add_theme_color_override("font_pressed_color", dim_color)
	button.end_bulk_theme_override()

func set_shortcut_button_text(button: Button, new_text: String) -> void:
	button.remove_theme_font_size_override("font_size")
	while button.get_theme_font("font").get_string_size(new_text, HORIZONTAL_ALIGNMENT_LEFT,
	-1, button.get_theme_font_size("font_size")).x > button.custom_minimum_size.x:
		button.add_theme_font_size_override("font_size",
				button.get_theme_font_size("font_size") - 1)
	button.text = new_text

func check_shortcuts_validity() -> void:
	for i in events.size():
		var shortcut_btn := shortcut_buttons[i]
		if not Configs.savedata.is_shortcut_valid(events[i]):
			setup_shortcut_button_font_colors(shortcut_btn,
					Configs.savedata.basic_color_error)
			var conflicts := Configs.savedata.get_actions_with_shortcut(events[i])
			var action_pos := conflicts.find(action)
			if action_pos != -1:
				conflicts.remove_at(action_pos)
			for ii in conflicts.size():
				conflicts[ii] = TranslationUtils.get_shortcut_description(conflicts[ii])
			if conflicts.size() > 8:
				conflicts.resize(8)
				conflicts.append("...")
			shortcut_btn.tooltip_text = Translator.translate("Also used by") +\
					":\n" + "\n".join(conflicts)
		else:
			shortcut_btn.begin_bulk_theme_override()
			shortcut_btn.remove_theme_color_override("font_color")
			shortcut_btn.remove_theme_color_override("font_focus_color")
			shortcut_btn.remove_theme_color_override("font_hover_color")
			shortcut_btn.remove_theme_color_override("font_pressed_color")
			shortcut_btn.end_bulk_theme_override()
			shortcut_btn.tooltip_text = ""
