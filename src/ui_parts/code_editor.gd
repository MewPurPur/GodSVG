extends VBoxContainer

const SVGFileDialog := preload("svg_file_dialog.tscn")

@onready var code_edit: CodeEdit = $ScriptEditor/CodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Padding/Label
@onready var size_label: Label = %SizeLabel

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	size_label.text = String.humanize_size(code_edit.text.length())
	code_edit.clear_undo_history()
	SVG.root_tag.attribute_changed.connect(auto_update_text)
	SVG.root_tag.child_tag_attribute_changed.connect(auto_update_text)
	SVG.root_tag.tag_added.connect(auto_update_text)
	SVG.root_tag.tag_deleted.connect(auto_update_text.unbind(1))
	SVG.root_tag.tag_moved.connect(auto_update_text.unbind(2))
	SVG.root_tag.changed_unknown.connect(auto_update_text)

func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.string
		size_label.text = String.humanize_size(code_edit.text.length())

func update_error(err: String) -> void:
	if err.is_empty():
		error_bar.hide()
		code_edit.remove_theme_stylebox_override(&"normal")
		code_edit.remove_theme_stylebox_override(&"focus")
		code_edit.custom_minimum_size.y = 96
		code_edit.size.y = 0
	else:
		# When the error is shown, the code editor's theme is changed to match up.
		error_bar.show()
		error_label.text = err
		var stylebox := ThemeDB.get_project_theme().\
				get_stylebox(&"normal", &"TextEdit").duplicate()
		stylebox.corner_radius_bottom_right = 0
		stylebox.corner_radius_bottom_left = 0
		stylebox.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(&"normal", stylebox)
		var stylebox2 := ThemeDB.get_project_theme().\
				get_stylebox(&"focus", &"CodeEdit").duplicate()
		stylebox2.corner_radius_bottom_right = 0
		stylebox2.corner_radius_bottom_left = 0
		stylebox2.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(&"focus", stylebox2)
		code_edit.custom_minimum_size.y = 75
		code_edit.size.y = 0


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)


func native_file_import(has_selected: bool, files: PackedStringArray, _filter_idx: int):
	if has_selected:
		apply_svg_from_path(files[0])

func native_file_export(has_selected: bool, files: PackedStringArray, _filter_idx: int):
	if has_selected:
		export_svg(files[0])

func _on_import_button_pressed() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		DisplayServer.file_dialog_show(
				"Import a .svg file", "", "", false,
				DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.svg"], native_file_import)
	else:
		var svg_import_dialog := SVGFileDialog.instantiate()
		get_tree().get_root().add_child(svg_import_dialog)
		svg_import_dialog.file_selected.connect(apply_svg_from_path)

func _on_export_button_pressed() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		DisplayServer.file_dialog_show(
				"Export a .svg file", OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), "", false,
				DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, ["*.svg"], native_file_export)
	else:
		var svg_export_dialog := SVGFileDialog.instantiate()
		svg_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		get_tree().get_root().add_child(svg_export_dialog)
		svg_export_dialog.file_selected.connect(export_svg)

func apply_svg_from_path(path: String) -> void:
	code_edit.text = FileAccess.open(path, FileAccess.READ).get_as_text()
	_on_code_edit_text_changed()  # Call it automatically yeah.

func export_svg(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	FA.store_string(SVG.string)


func _on_code_edit_text_changed() -> void:
	SVG.string = code_edit.text
	SVG.sync_data()
	size_label.text = String.humanize_size(code_edit.text.length())


func _input(event: InputEvent) -> void:
	if (code_edit.has_focus() and event is InputEventMouseButton and\
	not code_edit.get_global_rect().has_point(event.position)):
		code_edit.release_focus()
