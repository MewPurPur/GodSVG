# A more complex dialog, with the ability to have any number of arbitrary options, a list, and a checkbox.
extends PanelContainer

@onready var title_label: Label = $MainContainer/TextContainer/Title
@onready var label: RichTextLabel = $MainContainer/TextContainer/Label
@onready var options_container: HBoxContainer = $MainContainer/OptionsContainer
@onready var list_panel: PanelContainer = %ListPanel
@onready var list_label: Label = %ListLabel
@onready var list_scroll_container: ScrollContainer = %ListPanel/ListScrollContainer
@onready var checkbox: CheckBox = $MainContainer/TextContainer/CheckBox

func setup(title: String, message: String, list := PackedStringArray(), checkbox_text := "") -> void:
	label.text = message
	title_label.text = title
	if not list.is_empty():
		list_panel.show()
		list_label.text = "\n".join(list)
		if list.size() == 2:
			list_scroll_container.custom_minimum_size.y = 41
		elif list.size() == 3:
			list_scroll_container.custom_minimum_size.y = 63
	if not checkbox_text.is_empty():
		checkbox.show()
		checkbox.text = checkbox_text
	options_container.child_order_changed.connect(update_focus_sequence)
	update_focus_sequence()

func update_focus_sequence() -> void:
	var focus_sequence: Array[Control] = [checkbox]
	focus_sequence.append_array(options_container.get_children())
	HandlerGUI.register_focus_sequence(self, focus_sequence)

func set_text_width(width: float) -> void:
	label.custom_minimum_size.x = width

func add_option(action_text: String, action: Callable, focused := false, free_on_click := true,
action_when_checkbox_checked := Callable(), disabled_when_checkbox_pressed := false, grab_focus_when_checkbox_pressed := false) -> void:
	var button := Button.new()
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = action_text
	button.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	
	if action_when_checkbox_checked.is_valid():
		button.pressed.connect(func() -> void:
			if checkbox.button_pressed:
				action_when_checkbox_checked.call()
			else:
				action.call()
		)
	else:
		button.pressed.connect(action)
	
	if free_on_click:
		button.pressed.connect(queue_free)
	if disabled_when_checkbox_pressed:
		checkbox.toggled.connect(get_button_disabled_callable(button))
	if grab_focus_when_checkbox_pressed:
		checkbox.toggled.connect(
			func(pressed: bool) -> void:
				if pressed:
					button.grab_focus()
		)
	options_container.add_child(button)
	if focused:
		button.grab_focus()

# For simplicity's sake.
func add_cancel_option() -> void:
	var button := Button.new()
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = Translator.translate("Cancel")
	button.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	button.pressed.connect(queue_free)
	checkbox.toggled.connect(get_button_disabled_callable(button))
	options_container.add_child(button)


func get_button_disabled_callable(button: Button) -> Callable:
	return func(disabled: bool) -> void:
		button.disabled = disabled
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
