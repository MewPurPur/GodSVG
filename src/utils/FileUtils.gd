# This class has functionality for importing, exporting, and saving files.
class_name FileUtils extends RefCounted

const GoodFileDialogType = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.tscn")
const ExportDialog = preload("res://src/ui_parts/export_dialog.tscn")

static func save_svg_to_file(path: String) -> void:
	var FA := FileAccess.open(path, FileAccess.WRITE)
	FA.store_string(SVG.get_export_text())

static func does_svg_data_match_disk_contents() -> bool:
	# If the file doesn't exist, we get an empty string, so it's false anyway.
	return SVG.get_export_text() ==\
			FileAccess.get_file_as_string(GlobalSettings.savedata.current_file_path)


static func finish_import(svg_text: String, file_path: String) -> void:
	GlobalSettings.savedata.current_file_path = file_path
	SVG.apply_svg_text(svg_text)

static func finish_export(file_path: String, extension: String, upscale_amount := 1.0,
quality := 0.8, lossless := true) -> void:
	if file_path.get_extension().is_empty():
		file_path += "." + extension
	
	GlobalSettings.savedata.last_used_dir = file_path.get_base_dir()
	
	match extension:
		"png": generate_image_from_elements(upscale_amount).save_png(file_path)
		"jpg": generate_image_from_elements(upscale_amount).save_jpg(file_path, quality)
		"webp":
			generate_image_from_elements(upscale_amount).save_webp(file_path, !lossless,
					quality)
		_:
			# SVG / fallback.
			GlobalSettings.savedata.current_file_path = file_path
			save_svg_to_file(file_path)
	HandlerGUI.remove_overlay()


static func generate_image_from_elements(upscale_amount := 1.0) -> Image:
	var export_svg := SVG.root_element.duplicate()
	if export_svg.get_attribute_list("viewBox").is_empty():
		export_svg.set_attribute("viewBox",
				PackedFloat32Array([0, 0, export_svg.width, export_svg.height]))
	# First ensure there are dimensions.
	# Otherwise changing one side could influence the other.
	export_svg.set_attribute("width", export_svg.width)
	export_svg.set_attribute("height", export_svg.height)
	export_svg.set_attribute("width", export_svg.width * upscale_amount)
	export_svg.set_attribute("height", export_svg.height * upscale_amount)
	var img := Image.new()
	img.load_svg_from_string(SVGParser.root_to_text(export_svg, Formatter.new()))
	img.fix_alpha_edges()  # See godot issue 82579.
	return img


static func open_export_dialog() -> void:
	HandlerGUI.add_overlay(ExportDialog.instantiate())

static func open_save_dialog(extension: String, native_callable: Callable,
non_native_callable: Callable) -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if _is_native_preferred():
		DisplayServer.file_dialog_show(
				TranslationServer.translate("Save the .\"{extension}\" file").format(
				{"extension": extension}), Utils.get_last_dir(), Utils.get_file_name(
				GlobalSettings.savedata.current_file_path) + "." + extension, false,
				DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
				PackedStringArray(["*." + extension]), native_callable)
	elif OS.has_feature("web"):
		web_save_svg()
	else:
		var svg_export_dialog := GoodFileDialog.instantiate()
		svg_export_dialog.setup(Utils.get_last_dir(),
				Utils.get_file_name(GlobalSettings.savedata.current_file_path),
				GoodFileDialogType.FileMode.SAVE, PackedStringArray([extension]))
		HandlerGUI.add_overlay(svg_export_dialog)
		svg_export_dialog.file_selected.connect(non_native_callable)

static func native_file_export(has_selected: bool, files: PackedStringArray,
_filter_idx: int, extension: String, upscale_amount := 1.0) -> void:
	if has_selected:
		finish_export(files[0], extension, upscale_amount)

static func native_file_save(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		GlobalSettings.savedata.current_file_path = files[0]
		GlobalSettings.savedata.last_used_dir = files[0].get_base_dir()
		save_svg_to_file(files[0])


static func _is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE) and\
			GlobalSettings.savedata.use_native_file_dialog

static func open_import_dialog() -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if FileUtils._is_native_preferred():
		DisplayServer.file_dialog_show(TranslationServer.translate("Import a .svg file"),
				Utils.get_last_dir(), "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				["*.svg"], native_svg_import)
	elif OS.has_feature("web"):
		HandlerGUI.web_load_svg()
	else:
		var svg_import_dialog := GoodFileDialog.instantiate()
		svg_import_dialog.setup(Utils.get_last_dir(), "",
				GoodFileDialogType.FileMode.SELECT, PackedStringArray(["svg"]))
		HandlerGUI.add_overlay(svg_import_dialog)
		svg_import_dialog.file_selected.connect(apply_svg_from_path)

static func open_reference_load_dialog(callable: Callable) -> void:
	if FileUtils._is_native_preferred():
		DisplayServer.file_dialog_show(TranslationServer.translate("Load an image file"),
				Utils.get_last_dir(), "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
				PackedStringArray(["*.png,*.jpeg,*.jpg,*.webp,*.svg"]),
				native_reference_image_load.bind(callable))
	# TODO: Add Web Support
	#elif OS.has_feature("web"):
		#HandlerGUI.web_load_reference_image()
	else:
		var image_import_dialog := GoodFileDialog.instantiate()
		image_import_dialog.setup(Utils.get_last_dir(), "",
				GoodFileDialogType.FileMode.SELECT,
				PackedStringArray(["png", "jpeg", "jpg", "webp", "svg"]))
		HandlerGUI.add_overlay(image_import_dialog)
		image_import_dialog.file_selected.connect(load_reference_image.bind(callable))

static func native_svg_import(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		apply_svg_from_path(files[0])

static func native_reference_image_load(has_selected: bool, files: PackedStringArray,
_filter_idx: int, callable: Callable) -> void:
	if has_selected:
		load_reference_image(files[0], callable)

static func load_reference_image(path: String, callable: Callable) -> void:
	var img = Image.new()
	img.load(path)
	img.save_png(GlobalSettings.reference_image_path)
	callable.call()

static func apply_svg_from_path(path: String) -> int:
	var svg_file := FileAccess.open(path, FileAccess.READ)
	var error := ""
	var extension := path.get_extension()
	
	GlobalSettings.savedata.last_used_dir = path.get_base_dir()
	
	if extension.is_empty():
		error = TranslationServer.translate(
				"The file extension is empty. Only \"svg\" files are supported.")
	elif extension == "tscn":
		return ERR_FILE_CANT_OPEN
	elif extension != "svg":
		error = TranslationServer.translate(
				"\"{passed_extension}\" is an unsupported file extension. Only \"svg\" files are supported.").format({"passed_extension": extension})
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
	GlobalSettings.savedata.current_file_path = file_name
	JavaScriptBridge.eval("fileData = undefined;", true)

static func web_save_svg() -> void:
	_web_save(SVG.get_export_text().to_utf8_buffer(), "image/svg+xml")

static func web_save_png(img: Image) -> void:
	_web_save(img.save_png_to_buffer(), "image/png")

static func web_save_jpg(img: Image) -> void:
	_web_save(img.save_jpg_to_buffer(), "image/jpeg")

static func web_save_webp(img: Image) -> void:
	_web_save(img.save_webp_to_buffer(), "image/webp")

static func _web_save(buffer: PackedByteArray, format_name: String) -> void:
	var file_name := Utils.get_file_name(GlobalSettings.savedata.current_file_path)
	if file_name.is_empty():
		file_name = "export"
	JavaScriptBridge.download_buffer(buffer, file_name, format_name)
