extends HBoxContainer

var extensions := PackedStringArray()

@onready var line_edit: BetterLineEdit = $LineEdit
@onready var button: Button = $Button

signal value_changed(new_value: String)
var value := "":
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)

func set_value(new_value: String) -> void:
	value = new_value

func _ready() -> void:
	button.pressed.connect(FileUtils.open_custom_import_dialog.bind(extensions, set_value))
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.text_changed.connect(sync_line_edit_font.unbind(1))
	line_edit.placeholder_text = Translator.translate("No file path")
	value_changed.connect(sync_line_edit.unbind(1))
	sync_line_edit()

func permanently_disable() -> void:
	line_edit.editable = false
	button.disabled = true
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW


func sync_line_edit() -> void:
	if is_instance_valid(line_edit):
		line_edit.text = Utils.simplify_file_path(value)
		sync_line_edit_font()

func sync_line_edit_font() -> void:
	if is_instance_valid(line_edit):
		if line_edit.text.is_empty():
			line_edit.add_theme_font_override("font", ThemeUtils.main_font)
		else:
			line_edit.remove_theme_font_override("font")
			# TODO This should not be needed.
			line_edit.text += " "
			await get_tree().process_frame
			line_edit.text = line_edit.text.left(-1)

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text.replace("~", Utils.get_home_dir()))
