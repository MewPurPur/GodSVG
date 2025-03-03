extends PanelContainer

@onready var title_label: Label = $MainContainer/TextContainer/Title
@onready var label: RichTextLabel = $MainContainer/TextContainer/Label
@onready var options_container: HBoxContainer = $MainContainer/OptionsContainer

func setup(title: String, message: String) -> void:
	label.text = message
	title_label.text = title

func add_option(action_text: String, action: Callable, focused := false) -> void:
	var button := Button.new()
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = action_text
	button.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	button.pressed.connect(queue_free)
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
	options_container.add_child(button)
