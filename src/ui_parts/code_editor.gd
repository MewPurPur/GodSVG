extends VBoxContainer

const SVGFileDialog = preload("svg_file_dialog.tscn")
const ImportWarningDialog = preload("import_warning_dialog.tscn")
const AlertDialog = preload("alert_dialog.tscn")
const ExportDialog = preload("export_dialog.tscn")

@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var size_label: Label = %SizeLabel

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	update_size_label()
	code_edit.clear_undo_history()
	SVG.root_tag.attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.tag_layout_changed.connect(auto_update_text)
	SVG.root_tag.changed_unknown.connect(auto_update_text)

func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.text
		code_edit.clear_undo_history()
	update_size_label()

func update_error(err_id: StringName) -> void:
	if err_id == &"":
		if error_bar.visible:
			error_bar.hide()
			code_edit.remove_theme_stylebox_override(&"normal")
			code_edit.remove_theme_stylebox_override(&"focus")
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y += error_bar_real_height
			code_edit.size.y += error_bar_real_height
	else:
		# When the error is shown, the code editor's theme is changed to match up.
		if not error_bar.visible:
			error_bar.show()
			error_label.text = tr(err_id)
			for theming in [&"normal", &"focus"]:
				var stylebox := ThemeDB.get_project_theme().\
						get_stylebox(theming, &"TextEdit").duplicate()
				stylebox.corner_radius_bottom_right = 0
				stylebox.corner_radius_bottom_left = 0
				stylebox.border_width_bottom = 1
				code_edit.add_theme_stylebox_override(theming, stylebox)
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y -= error_bar_real_height
			code_edit.size.y -= error_bar_real_height


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)


func native_file_import(has_selected: bool, files: PackedStringArray, _filter_idx: int):
	if has_selected:
		apply_svg_from_path(files[0])

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
	var export_panel := ExportDialog.instantiate()
	get_tree().get_root().add_child(export_panel)

func apply_svg_from_path(path: String) -> void:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	if svg_file == null:
		var alert_dialog := AlertDialog.instantiate()
		get_tree().get_root().add_child(alert_dialog)
		alert_dialog.setup("#file_open_fail_message", "#alert", 280.0)
		return
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(set_new_text)
	warning_panel.set_svg(svg_text)
	get_tree().get_root().add_child(warning_panel)

func set_new_text(svg_text: String) -> void:
	code_edit.text = svg_text
	_on_code_edit_text_changed()  # Call it automatically yeah.


func _on_code_edit_text_changed() -> void:
	SVG.text = code_edit.text
	SVG.update_tags()


func _input(event: InputEvent) -> void:
	if (code_edit.has_focus() and event is InputEventMouseButton and\
	not code_edit.get_global_rect().has_point(event.position)):
		code_edit.release_focus()


func update_size_label() -> void:
	size_label.text = String.humanize_size(code_edit.text.length())

func _on_svg_code_edit_focus_exited() -> void:
	code_edit.text = SVG.text
	if SVG.saved_text != code_edit.text:
		SVG.update_text(true)
