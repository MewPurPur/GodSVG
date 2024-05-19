# This class has functionality for importing, exporting, and saving files.
class_name FileUtils extends RefCounted

const GoodFileDialogType = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialog := preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.tscn")
const ExportDialog = preload("res://src/ui_parts/export_dialog.tscn")

static func save_svg_to_file(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	FA.store_string(SVG.text)

static func does_svg_data_match_disk_contents() -> bool:
	# If the file doesn't exist, we get an empty string, so it's false anyway.
	return SVG.text ==\
			FileAccess.get_file_as_string(GlobalSettings.save_data.current_file_path)


static func finish_import(svg_text: String, file_path: String) -> void:
	GlobalSettings.modify_save_data("current_file_path", file_path)
	SVG.apply_svg_text(svg_text)

static func finish_export(file_path: String, extension: String, upscale_amount := 1.0,
quality := 0.8, lossless := true) -> void:
	if file_path.get_extension().is_empty():
		file_path += "." + extension
	
	GlobalSettings.modify_save_data("last_used_dir", file_path.get_base_dir())
	
	match extension:
		"png": generate_image_from_tags(upscale_amount).save_png(file_path)
		"jpg": generate_image_from_tags(upscale_amount).save_jpg(file_path, quality)
		"webp": generate_image_from_tags(upscale_amount).save_webp(file_path, !lossless, quality)
		_:
			# SVG / fallback.
			GlobalSettings.modify_save_data("current_file_path", file_path)
			save_svg_to_file(file_path)
	HandlerGUI.remove_overlay()


static func generate_image_from_tags(upscale_amount := 1.0) -> Image:
	var export_svg := SVG.root_tag.duplicate()
	if export_svg.attributes.viewBox.get_list().is_empty():
		export_svg.attributes.viewBox.set_list([0, 0, export_svg.width, export_svg.height])
	export_svg.attributes.width.set_num(export_svg.width * upscale_amount)
	export_svg.attributes.height.set_num(export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.svg_to_text(export_svg))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img


static func open_export_dialog() -> void:
	HandlerGUI.add_overlay(ExportDialog.instantiate())

static func open_save_dialog(extension: String, native_callable: Callable,
non_native_callable: Callable) -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if _is_native_preferred():
		DisplayServer.file_dialog_show(
				TranslationServer.translate("Save the .\"{extension}\" file") %\
				{"extension": extension}, Utils.get_last_dir(), Utils.get_file_name(
				GlobalSettings.save_data.current_file_path) + "." + extension, false,
				DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, ["*." + extension], native_callable)
	elif OS.has_feature("web"):
		web_save_svg()
	else:
		var svg_export_dialog := GoodFileDialog.instantiate()
		svg_export_dialog.setup(Utils.get_last_dir(),
				Utils.get_file_name(GlobalSettings.save_data.current_file_path),
				GoodFileDialogType.FileMode.SAVE, extension)
		HandlerGUI.add_overlay(svg_export_dialog)
		svg_export_dialog.file_selected.connect(non_native_callable)

static func native_file_export(has_selected: bool, files: PackedStringArray,
_filter_idx: int, extension: String, upscale_amount := 1.0) -> void:
	if has_selected:
		finish_export(files[0], extension, upscale_amount)

static func native_file_save(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		GlobalSettings.modify_save_data("current_file_path", files[0])
		GlobalSettings.modify_save_data("last_used_dir", files[0].get_base_dir())
		save_svg_to_file(files[0])


static func _is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG) and\
			GlobalSettings.use_native_file_dialog

static func open_import_dialog() -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if FileUtils._is_native_preferred():
		DisplayServer.file_dialog_show(TranslationServer.translate("Import a .svg file"),
				Utils.get_last_dir(), "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				["*.svg"], native_file_import)
	elif OS.has_feature("web"):
		HandlerGUI.web_load_svg()
	else:
		var svg_import_dialog := GoodFileDialog.instantiate()
		svg_import_dialog.setup(Utils.get_last_dir(), "",
				GoodFileDialogType.FileMode.SELECT, "svg")
		HandlerGUI.add_overlay(svg_import_dialog)
		svg_import_dialog.file_selected.connect(apply_svg_from_path)

static func open_reference_import_dialog() -> void:
	if FileUtils._is_native_preferred():
		DisplayServer.file_dialog_show(TranslationServer.translate("Import a .png file"),
				Utils.get_last_dir(), "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				["*.png"], native_file_import)
	# TODO : Add Web Support
	#elif OS.has_feature("web"):
		#HandlerGUI.web_load_svg()
	else:
		var png_import_dialog := GoodFileDialog.instantiate()
		png_import_dialog.setup(Utils.get_last_dir(), "",
			GoodFileDialogType.FileMode.SELECT, "png")
		HandlerGUI.add_overlay(png_import_dialog)
		png_import_dialog.file_selected.connect(reference_image_import)

static func native_file_import(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		if files[0].ends_with(".svg"):
			apply_svg_from_path(files[0])
		else:
			reference_image_import(files[0])

static func reference_image_import(path : String) -> void:
	GlobalSettings.modify_save_data("reference_path", path)
	Indications.imported_reference.emit()

static func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	GlobalSettings.modify_save_data("last_used_dir", path.get_base_dir())
	
	if extension.is_empty():
		error = TranslationServer.translate(
				"The file extension is empty. Only \"svg\" files are supported.")
	elif extension == "tscn":
		return ERR_FILE_CANT_OPEN
	elif extension != "svg":
		error = TranslationServer.translate(
				"\"{passed_extension}\" is a unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
	elif !is_instance_valid(svg_file):
		error = TranslationServer.translate(
				"The file couldn't be opened.\nTry checking the file path, ensure that the file is not deleted, or choose a different file.")
	
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_overlay(alert_dialog)
		alert_dialog.setup(error)
		return ERR_FILE_CANT_OPEN
	
	var svg_text := svg_file.get_as_text()
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(FileUtils.finish_import.bind(svg_text, path))
	warning_panel.set_svg(svg_text)
	HandlerGUI.add_overlay(warning_panel)
	return OK

# Web stuff. The loading logic had to remain in HandlerGUI. 

static func web_import(svg_text: String, file_name: String) -> void:
	SVG.apply_svg_text(svg_text)
	GlobalSettings.modify_save_data("current_file_path", file_name)
	JavaScriptBridge.eval("fileData = undefined;", true)

static func web_save_svg() -> void:
	_web_save(SVG.text.to_utf8_buffer(), "image/svg+xml")

static func web_save_png(img: Image) -> void:
	_web_save(img.save_png_to_buffer(), "image/png")

static func web_save_jpg(img: Image) -> void:
	_web_save(img.save_jpg_to_buffer(), "image/jpeg")

static func web_save_webp(img: Image) -> void:
	_web_save(img.save_webp_to_buffer(), "image/webp")

static func _web_save(buffer: PackedByteArray, format_name: String) -> void:
	var file_name := Utils.get_file_name(GlobalSettings.save_data.current_file_path)
	if file_name.is_empty():
		file_name = "export"
	JavaScriptBridge.download_buffer(buffer, file_name, format_name)
