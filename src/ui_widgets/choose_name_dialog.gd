extends PanelContainer

@onready var title_label: Label = %Title
@onready var name_edit: BetterLineEdit = %NameEdit
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var cancel_button: Button = %CancelButton
@onready var action_button: Button = %ActionButton

var warning_callback: Callable
var error_callback: Callable

func _ready() -> void:
	cancel_button.text = Translator.translate("Cancel")
	action_button.text = Translator.translate("Create")
	cancel_button.pressed.connect(queue_free)
	action_button.pressed.connect(queue_free)
	name_edit.text_changed.connect(adapt_to_text)
	name_edit.text_change_canceled.connect(queue_free)
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	name_edit.add_theme_font_override("font", ThemeUtils.main_font)
	HandlerGUI.register_focus_sequence(self, [name_edit, cancel_button, action_button], true)

func _on_name_edit_text_submitted(_text: String) -> void:
	if not action_button.disabled:
		action_button.grab_focus()
	else:
		cancel_button.grab_focus()

# The error/warning callables should take the stripped text and return a string.
func setup(title: String, action: Callable, error_callable := Callable(),
warning_callable := Callable()) -> void:
	title_label.text = title
	action_button.pressed.connect(func() -> void: action.call(name_edit.text))
	name_edit.custom_minimum_size.x = 240.0
	warning_callback = warning_callable
	error_callback = error_callable
	adapt_to_text(name_edit.text)

func adapt_to_text(text: String) -> void:
	var stripped_text := text.strip_edges()
	# Set up error or warning text.
	var error: String = error_callback.call(stripped_text) if error_callback.is_valid() else ""
	var warning: String = warning_callback.call(stripped_text) if warning_callback.is_valid() else ""
	if not error.is_empty():
		rich_text_label.add_theme_color_override("default_color", Configs.savedata.basic_color_error)
		rich_text_label.text = error
	elif not warning.is_empty():
		rich_text_label.add_theme_color_override("default_color", Configs.savedata.basic_color_warning)
		rich_text_label.text = warning
	else:
		rich_text_label.text = ""
	rich_text_label.visible = not rich_text_label.text.is_empty()
	# Disable or enable the action button.
	var can_do_action := not stripped_text.is_empty() and error.is_empty()
	action_button.disabled = not can_do_action
	action_button.mouse_default_cursor_shape = CURSOR_POINTING_HAND if can_do_action else CURSOR_ARROW
