# TODO: I made this dialog for a purpose, but now it's unused. Re-evaluate it later on.
extends PanelContainer

@onready var title_label: Label = $MainContainer/TextContainer/Title
@onready var name_edit: BetterLineEdit = $MainContainer/TextContainer/NameEdit
@onready var rich_text_label: RichTextLabel = $MainContainer/TextContainer/RichTextLabel
@onready var cancel_button: Button = $MainContainer/ButtonContainer/CancelButton
@onready var action_button: Button = $MainContainer/ButtonContainer/ActionButton

var warning_action := Callable()

func _ready() -> void:
	cancel_button.text = TranslationServer.translate("Cancel")
	action_button.text = TranslationServer.translate("Create")
	cancel_button.pressed.connect(queue_free)
	action_button.pressed.connect(queue_free)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	name_edit.text_change_canceled.connect(queue_free)
	name_edit.text_submitted.connect(action_button.grab_focus.unbind(1))
	name_edit.add_theme_font_override("font", ThemeUtils.regular_font)
	rich_text_label.add_theme_color_override("default_color",
			GlobalSettings.savedata.basic_color_warning)

func setup(title: String, warning_callable: Callable, action: Callable) -> void:
	title_label.text = title
	action_button.pressed.connect(func(): action.call(name_edit.text))
	name_edit.grab_focus()
	name_edit.custom_minimum_size.x = 300.0
	warning_action = warning_callable
	adapt_to_text(name_edit.text)

func _on_name_edit_text_changed(new_text: String) -> void:
	adapt_to_text(new_text)

func adapt_to_text(text: String) -> void:
	var stripped_text := text.strip_edges()
	action_button.disabled = stripped_text.is_empty()
	action_button.mouse_default_cursor_shape = CURSOR_ARROW if\
			stripped_text.is_empty() else CURSOR_POINTING_HAND
	action_button.focus_mode = FOCUS_NONE if stripped_text.is_empty() else FOCUS_ALL
	var warning: String = warning_action.call(stripped_text)
	rich_text_label.visible = not warning.is_empty()
	rich_text_label.text = warning
