## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const SVGFileDialog = preload("res://src/ui_parts/svg_file_dialog.tscn")
const ExportDialog = preload("res://src/ui_parts/export_dialog.tscn")

var text := ""
var root_tag := TagSVG.new()

var saved_text := ""
var UR := UndoRedo.new()

signal parsing_finished(error_id: StringName) 

func _ready() -> void:
	root_tag.changed_unknown.connect(update_text.bind(false))
	root_tag.attribute_changed.connect(update_text)
	root_tag.child_attribute_changed.connect(update_text)
	root_tag.tag_layout_changed.connect(update_text)
	get_window().files_dropped.connect(_on_files_dropped)
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl := false
	if not (OS.is_debug_build() and not OS.has_feature("template")) and\
	cmdline_args.size() >= 1:
		load_cmdl = true
	
	if (apply_svg_from_path(cmdline_args[0]) if load_cmdl else -1) == OK:
		pass
	elif not GlobalSettings.save_data.svg_text.is_empty():
		apply_svg_text(GlobalSettings.save_data.svg_text)
	else:
		root_tag.attributes.width.set_num(16.0, Attribute.SyncMode.SILENT)
		root_tag.attributes.height.set_num(16.0, Attribute.SyncMode.SILENT)
		update_text(false)
	UR.clear_history()


func update_tags() -> void:
	var err_id := SVGParser.get_svg_syntax_error(text)
	parsing_finished.emit(err_id)
	if err_id == &"":
		root_tag.replace_self(SVGParser.text_to_svg(text))

func update_text(undo_redo := true) -> void:
	if undo_redo:
		UR.create_action("")
		UR.add_do_property(self, &"text", SVGParser.svg_to_text(root_tag))
		UR.add_undo_property(self, &"text", saved_text)
		UR.commit_action()
		saved_text = text
	else:
		text = SVGParser.svg_to_text(root_tag)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"redo"):
		if UR.has_redo():
			UR.redo()
			update_tags()
	elif event.is_action_pressed(&"undo"):
		if UR.has_undo():
			UR.undo()
			update_tags()
	elif event.is_action_pressed(&"import"):
		open_import_dialog()
	elif event.is_action_pressed(&"export"):
		open_export_dialog()


func open_export_dialog() -> void:
	HandlerGUI.add_overlay(ExportDialog.instantiate())

func open_import_dialog() -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		DisplayServer.file_dialog_show("Import a .svg file", Utils.get_last_dir(), "", false,
				DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.svg"], native_file_import)
	else:
		var svg_import_dialog := SVGFileDialog.instantiate()
		svg_import_dialog.current_dir = Utils.get_last_dir()
		HandlerGUI.add_overlay(svg_import_dialog)
		svg_import_dialog.file_selected.connect(apply_svg_from_path)

func native_file_import(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		apply_svg_from_path(files[0])
		GlobalSettings.modify_save_data(&"last_used_dir", files[0].get_base_dir())

func non_native_file_import(file_path: String) -> void:
	apply_svg_from_path(file_path)
	GlobalSettings.modify_save_data(&"last_used_dir", file_path.get_base_dir())


func _on_files_dropped(files: PackedStringArray):
	if not HandlerGUI.has_overlay:
		apply_svg_from_path(files[0])

func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	if extension.is_empty():
		error = "#file_open_empty_extension"
	elif extension == &"tscn":
		return ERR_FILE_CANT_OPEN
	elif extension != &"svg":
		error = tr(
				"#file_open_unsupported_extension").format({"passed_extension": extension})
	elif svg_file == null:
		error = "#file_open_fail_message"
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_child(alert_dialog)
		alert_dialog.setup(error, "#alert", 280.0)
		return ERR_FILE_CANT_OPEN
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(apply_svg_text)
	warning_panel.set_svg(svg_text)
	get_tree().get_root().add_child(warning_panel)
	return OK

func apply_svg_text(svg_text: String) -> void:
	text = svg_text
	saved_text = svg_text
	update_tags()
