extends PanelContainer

@onready var label: Label = %MainContainer/Label
@onready var reset_button: Button = %MainContainer/HBoxContainer/ResetButton
@onready var shortcut_container: HBoxContainer = %ShortcutContainer
@onready var shortcut_buttons: Array[Button] = []

var action: String
var events: Array[InputEvent] = []

var listening_idx := -1

func _ready() -> void:
	reset_button.tooltip_text = TranslationServer.translate("Reset to default")

func setup(new_action: String) -> void:
	action = new_action
	events = InputMap.action_get_events(action)
	sync()

# Syncs based on current events.
func sync() -> void:
	# Show the reset button if any of the actions don't match.
	var action_defaults: Array[InputEvent] = GlobalSettings.default_input_events[action]
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
		var new_btn := Button.new()
		shortcut_container.add_child.call_deferred(new_btn)
		shortcut_buttons.append(new_btn)
		new_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		new_btn.theme_type_variation = "TranslucentButton"
		new_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		new_btn.focus_mode = Control.FOCUS_NONE
		if i < events.size():
			new_btn.text = events[i].as_text_keycode()
			new_btn.pressed.connect(popup_options.bind(i))
		else:
			new_btn.begin_bulk_theme_override()
			new_btn.add_theme_color_override("font_color", Color("#def6"))
			new_btn.add_theme_color_override("font_hover_color", Color("#def6"))
			new_btn.add_theme_color_override("font_pressed_color", Color("#def8"))
			new_btn.end_bulk_theme_override()
			new_btn.text = TranslationServer.translate("Unused")
			if i == events.size():
				new_btn.tooltip_text = TranslationServer.translate("Add shortcut")
				new_btn.pressed.connect(enter_listening_mode.bind(i))
			else:
				new_btn.disabled = true
				new_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW


func popup_options(idx: int) -> void:
	var btn_arr: Array[Button] = [
		ContextPopup.create_button(TranslationServer.translate("Edit"),
				enter_listening_mode.bind(idx), false, load("res://visual/icons/Edit.svg")),
		ContextPopup.create_button(TranslationServer.translate("Remove"),
				delete_shortcut.bind(idx), false, load("res://visual/icons/Delete.svg"))]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true, shortcut_buttons[idx].size.x)
	HandlerGUI.popup_under_rect(context_popup, shortcut_buttons[idx].get_global_rect(),
			get_viewport())


func enter_listening_mode(idx: int) -> void:
	listening_idx = idx
	var btn := shortcut_buttons[idx]
	btn.begin_bulk_theme_override()
	btn.add_theme_color_override("font_focus_color", Color("#defb"))
	btn.add_theme_color_override("font_hover_color", Color("#defb"))
	btn.add_theme_color_override("font_pressed_color", Color("#defb"))
	btn.end_bulk_theme_override()
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
	btn.text = activation_event.as_text_keycode().\
			trim_suffix("(Unset)").trim_suffix("+")
	if btn.text.is_empty():
		btn.text = TranslationServer.translate("Press keys…")

func cancel_listening() -> void:
	listening_idx = -1
	sync()


func delete_shortcut(idx: int) -> void:
	events.remove_at(idx)
	GlobalSettings.modify_keybind(action, events)
	sync()

func _unhandled_key_input(event: InputEvent) -> void:
	if listening_idx >= 0 and event is InputEventKey:
		if event.is_action("ui_cancel"):
			cancel_listening()
			accept_event()
		elif event.is_pressed():
			shortcut_buttons[listening_idx].text = event.as_text_keycode()
			accept_event()
		elif event.is_released():
			if listening_idx < events.size():
				events[listening_idx] = event
				GlobalSettings.modify_keybind(action, events)
			else:
				events.append(event)
				GlobalSettings.modify_keybind(action, events)
			sync()
			listening_idx = -1

func _on_reset_button_pressed() -> void:
	events = GlobalSettings.default_input_events[action].duplicate(true)
	GlobalSettings.modify_keybind(action, events)
	sync()
