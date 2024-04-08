## This singleton handles the two representations of the SVG:
## The SVG text, and the native [TagSVG] representation.
extends Node

const GoodFileDialogType = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.tscn")
const ExportDialog = preload("res://src/ui_parts/export_dialog.tscn")

const default = '<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"></svg>'

var text := ""
var root_tag := TagSVG.new()

var UR := UndoRedo.new()

signal parsing_finished(error_id: SVGParser.ParseError)

func _ready() -> void:
	UR.version_changed.connect(_on_undo_redo)
	root_tag.changed_unknown.connect(update_text.bind(false))
	root_tag.attribute_changed.connect(update_text)
	root_tag.child_attribute_changed.connect(update_text)
	root_tag.tag_layout_changed.connect(update_text)
	
	var cmdline_args := OS.get_cmdline_args()
	var load_cmdl := false
	if not (OS.is_debug_build() and not OS.has_feature("template")) and\
	cmdline_args.size() >= 1:
		load_cmdl = true
	
	await get_tree().get_root().ready  # Await tree ready to be able to add error dialogs.
	
	# Guarantee a proper SVG text first, as the import warnings dialog
	# that might pop up from command line file opening is cancellable.
	if not GlobalSettings.save_data.svg_text.is_empty():
		apply_svg_text(GlobalSettings.save_data.svg_text)
	else:
		apply_svg_text(default)
	
	if load_cmdl:
		apply_svg_from_path(cmdline_args[0])
	
	UR.clear_history()


func update_tags() -> void:
	var svg_parse_result := SVGParser.text_to_svg(text)
	parsing_finished.emit(svg_parse_result.error)
	if svg_parse_result.error == SVGParser.ParseError.OK:
		root_tag.replace_self(svg_parse_result.svg)


func update_text(undo_redo := true) -> void:
	if undo_redo:
		UR.create_action("")
		UR.add_do_property(self, "text", SVGParser.svg_to_text(root_tag))
		UR.add_undo_property(self, "text", GlobalSettings.save_data.svg_text)
		UR.commit_action()
		GlobalSettings.modify_save_data("svg_text", text)
	else:
		text = SVGParser.svg_to_text(root_tag)

func undo() -> void:
	if UR.has_undo():
		UR.undo()
		update_tags()

func redo() -> void:
	if UR.has_redo():
		UR.redo()
		update_tags()

func _on_undo_redo() -> void:
	GlobalSettings.modify_save_data("svg_text", text)


func refresh() -> void:
	SVG.root_tag.replace_self(SVG.root_tag.create_duplicate())


func is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG) and\
			GlobalSettings.use_native_file_dialog

func open_import_dialog() -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if is_native_preferred():
		DisplayServer.file_dialog_show("Import a .svg file", Utils.get_last_dir(), "", false,
				DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.svg"], native_file_import)
	elif OS.has_feature("web"):
		HandlerGUI.web_load_svg()
	else:
		var svg_import_dialog := GoodFileDialog.instantiate()
		svg_import_dialog.setup(Utils.get_last_dir(), "",
				GoodFileDialogType.FileMode.SELECT, "svg")
		HandlerGUI.add_overlay(svg_import_dialog)
		svg_import_dialog.file_selected.connect(apply_svg_from_path)

func native_file_import(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		apply_svg_from_path(files[0])


func open_export_dialog() -> void:
	HandlerGUI.add_overlay(ExportDialog.instantiate())

func open_save_dialog(extension: String, native_callable: Callable,
non_native_callable: Callable) -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if is_native_preferred():
		DisplayServer.file_dialog_show("Save the .%s file" % extension,
				Utils.get_last_dir(),
				Utils.get_file_name(GlobalSettings.save_data.current_file_path) + "." + extension,
				false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				["*." + extension], native_callable)
	elif OS.has_feature("web"):
		HandlerGUI.web_save_svg()
	else:
		var svg_export_dialog := GoodFileDialog.instantiate()
		svg_export_dialog.setup(Utils.get_last_dir(),
				Utils.get_file_name(GlobalSettings.save_data.current_file_path),
				GoodFileDialogType.FileMode.SAVE, extension)
		HandlerGUI.add_overlay(svg_export_dialog)
		svg_export_dialog.file_selected.connect(non_native_callable)

func native_file_save(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		GlobalSettings.modify_save_data("current_file_path", files[0])
		GlobalSettings.modify_save_data("last_used_dir", files[0].get_base_dir())
		save_svg_to_file(files[0])


func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	GlobalSettings.modify_save_data("last_used_dir", path.get_base_dir())
	
	if extension.is_empty():
		error = "The file extension is empty. Only \"svg\" files are supported."
	elif extension == "tscn":
		return ERR_FILE_CANT_OPEN
	elif extension != "svg":
		error = tr("\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
	elif svg_file == null:
		error = "The file couldn't be opened.\nTry checking the file path, ensure that the file is not deleted, or choose a different file."
	
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		alert_dialog.setup(error, "Alert!", 280.0)
		return ERR_FILE_CANT_OPEN
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(finish_import.bind(svg_text, path))
	warning_panel.set_svg(svg_text)
	HandlerGUI.add_overlay(warning_panel)
	return OK

func generate_image_from_tags(upscale_amount := 1.0) -> Image:
	var export_svg := SVG.root_tag.create_duplicate()
	if export_svg.attributes.viewBox.get_list().is_empty():
		export_svg.attributes.viewBox.set_list([0, 0, export_svg.width, export_svg.height])
	export_svg.attributes.width.set_num(export_svg.width * upscale_amount)
	export_svg.attributes.height.set_num(export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(export_svg))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img


func finish_import(svg_text: String, file_path: String) -> void:
	GlobalSettings.modify_save_data("current_file_path", file_path)
	apply_svg_text(svg_text)

func finish_export(file_path: String, extension: String, upscale_amount := 1.0) -> void:
	if file_path.get_extension().is_empty():
		file_path += "." + extension
	
	GlobalSettings.modify_save_data("last_used_dir", file_path.get_base_dir())
	
	match extension:
		"png":
			generate_image_from_tags(upscale_amount).save_png(file_path)
		_:
			# SVG / fallback.
			GlobalSettings.modify_save_data("current_file_path", file_path)
			save_svg_to_file(file_path)
	HandlerGUI.remove_overlay()


func save_svg_to_file(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	FA.store_string(text)

func apply_svg_text(svg_text: String,) -> void:
	text = svg_text
	GlobalSettings.modify_save_data("svg_text", text)
	update_tags()
