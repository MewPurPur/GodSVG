# This class has functionality for importing, exporting, and saving files.
class_name FileUtils extends RefCounted

enum FileState {SAME, DIFFERENT, DOES_NOT_EXIST}

const GoodFileDialogType = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")
const ImportWarningDialog = preload("res://src/ui_parts/import_warning_dialog.tscn")
const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.tscn")
const ExportDialog = preload("res://src/ui_parts/export_dialog.tscn")

static func apply_svg_from_path(path: String) -> void:
	_finish_file_import(path, _apply_svg, PackedStringArray(["svg"]))

static func save_svg_to_file(path: String) -> void:
	GlobalSettings.modify_setting("current_file_path", path)
	GlobalSettings.modify_setting("last_used_dir", path.get_base_dir())
	var FA := FileAccess.open(path, FileAccess.WRITE)
	FA.store_string(SVG.get_export_text())

static func compare_svg_to_disk_contents() -> FileState:
	var content := FileAccess.get_file_as_string(GlobalSettings.savedata.current_file_path)
	if content.is_empty():
		return FileState.DOES_NOT_EXIST
	# Check if importing the file's text into GodSVG would change the current SVG text.
	if SVG.text == SVGParser.root_to_text(SVGParser.text_to_root(content,
	GlobalSettings.savedata.editor_formatter).svg):
		return FileState.SAME
	else:
		return FileState.DIFFERENT


static func finish_export(file_path: String, extension: String, upscale_amount := 1.0,
quality := 0.8, lossy := false) -> void:
	if file_path.get_extension().is_empty():
		file_path += "." + extension
	
	GlobalSettings.modify_setting("last_used_dir", file_path.get_base_dir())
	
	match extension:
		"png": generate_image_from_elements(upscale_amount).save_png(file_path)
		"jpg": generate_image_from_elements(upscale_amount).save_jpg(file_path, quality)
		"webp":
			generate_image_from_elements(upscale_amount).save_webp(file_path, lossy, quality)
		_: save_svg_to_file(file_path)  # SVG / fallback.
	HandlerGUI.remove_menu()


static func generate_image_from_elements(upscale_amount := 1.0) -> Image:
	var export_svg := SVG.root_element.duplicate()
	if export_svg.get_attribute_list("viewBox").is_empty():
		export_svg.set_attribute("viewBox",
				PackedFloat32Array([0.0, 0.0, export_svg.width, export_svg.height]))
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
	HandlerGUI.add_menu(ExportDialog.instantiate())

static func open_save_dialog(extension: String, native_callable: Callable,
non_native_callable: Callable) -> void:
	# Open it inside a native file dialog, or our custom one if it's not available.
	if OS.has_feature("web"):
		web_save_svg()
	else:
		if _is_native_preferred():
			DisplayServer.file_dialog_show(
					Translator.translate("Save the .\"{extension}\" file").format(
					{"extension": extension}), Utils.get_last_dir(), Utils.get_file_name(
					GlobalSettings.savedata.current_file_path) + "." + extension, false,
					DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
					PackedStringArray(["*." + extension]), native_callable)
		else:
			var svg_export_dialog := GoodFileDialog.instantiate()
			svg_export_dialog.setup(Utils.get_last_dir(),
					Utils.get_file_name(GlobalSettings.savedata.current_file_path),
					GoodFileDialogType.FileMode.SAVE, PackedStringArray([extension]))
			HandlerGUI.add_menu(svg_export_dialog)
			svg_export_dialog.file_selected.connect(non_native_callable)

static func native_file_export(has_selected: bool, files: PackedStringArray,
_filter_idx: int, extension: String, upscale_amount := 1.0) -> void:
	if has_selected:
		finish_export(files[0], extension, upscale_amount)

static func native_file_save(has_selected: bool, files: PackedStringArray,
_filter_idx: int) -> void:
	if has_selected:
		save_svg_to_file(files[0])


static func _is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE) and\
			GlobalSettings.savedata.use_native_file_dialog


# No need for completion callback here yet.
static func open_svg_import_dialog() -> void:
	_open_import_dialog(PackedStringArray(["svg"]), _apply_svg)

static func open_image_import_dialog(completion_callback: Callable) -> void:
	_open_import_dialog(PackedStringArray(["png", "jpg", "jpeg", "webp", "svg"]),
			completion_callback, Translator.translate("Load an image file"))

static func open_xml_import_dialog(completion_callback: Callable) -> void:
	_open_import_dialog(PackedStringArray(["xml"]), completion_callback)


# On web, the completion callback can't use the full file path,
static func _open_import_dialog(extensions: PackedStringArray,
completion_callback: Callable, native_dialog_title := "") -> void:
	var extensions_with_dots := PackedStringArray()
	for extension in extensions:
		extensions_with_dots.append("." + extension)
	
	if native_dialog_title.is_empty():
		native_dialog_title = Translator.translate("Import a {extension} file").format(
				{"extension": " / ".join(extensions_with_dots)})
	
	if OS.has_feature("web"):
		_web_load_file(extensions, completion_callback)
	else:
		if _is_native_preferred():
			var filters := PackedStringArray()
			for extension in extensions_with_dots:
				filters.append("*" + extension)
			
			var native_callback :=\
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int):
						if has_selected:
							_finish_file_import(files[0], completion_callback, extensions)
			
			DisplayServer.file_dialog_show(native_dialog_title, Utils.get_last_dir(), "",
					false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, native_callback)
		else:
			var import_dialog := GoodFileDialog.instantiate()
			import_dialog.setup(Utils.get_last_dir(), "",
					GoodFileDialogType.FileMode.SELECT, extensions)
			HandlerGUI.add_menu(import_dialog)
			import_dialog.file_selected.connect(
					func(path): _finish_file_import(path, completion_callback, extensions))

static func _finish_file_import(file_path: String, completion_callback: Callable,
allowed_extensions: PackedStringArray) -> Error:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var error := ""
	var file_extension := file_path.get_extension()
	
	GlobalSettings.modify_setting("last_used_dir", file_path.get_base_dir())
	
	if file_extension == "tscn":
		# I asked kiisu about why he wrote this special case. He said:
		# "I think when running from the editor it would give the specific scene
		# run as first argument",
		# TODO understand what he meant and if it's still relevant.
		return ERR_FILE_CANT_OPEN
	if not file_extension in allowed_extensions:
		error = TranslationUtils.get_bad_extension_alert_text(file_extension,
				allowed_extensions)
	elif !is_instance_valid(file):
		error = Translator.translate("The file couldn't be opened.")
		if not FileAccess.file_exists(file_path):
			error += "\n" + Translator.translate("Check if the file still exists in the selected file path.")
	
	if not error.is_empty():
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_menu(alert_dialog)
		alert_dialog.setup(error)
		return ERR_FILE_CANT_OPEN
	
	var file_name := file_path.get_file()
	if file_extension in ["svg", "xml"]:
		completion_callback.call(file.get_as_text(), file_name)
	else:
		completion_callback.call(file.get_buffer(file.get_length()), file_name)
	return OK


static func _apply_svg(data: Variant, file_name: String) -> Error:
	var warning_panel := ImportWarningDialog.instantiate()
	warning_panel.imported.connect(_finish_svg_import.bind(data, file_name))
	warning_panel.set_svg(data)
	HandlerGUI.add_menu(warning_panel)
	return OK

static func _finish_svg_import(svg_text: String, file_path: String) -> void:
	GlobalSettings.modify_setting("current_file_path", file_path)
	SVG.apply_svg_text(svg_text)


static func open_svg(file_path: String) -> void:
	if file_path.get_extension() == "svg":
		OS.shell_open(file_path)


# Web stuff.

static func _web_load_file(allowed_extensions: PackedStringArray,
completion_callback: Callable) -> void:
	var allowed_extensions_with_dots := PackedStringArray()
	for allowed_extension in allowed_extensions:
		allowed_extensions_with_dots.append("." + allowed_extension)
	
	var document := JavaScriptBridge.get_interface("document")
	
	var input: JavaScriptObject = document.createElement("INPUT")
	input.type = "file"
	input.accept = ",".join(allowed_extensions_with_dots)
	
	# Clear previous data.
	JavaScriptBridge.eval("window.godsvgFileName = '';", true)
	JavaScriptBridge.eval("window.godsvgFileData = null;", true)
	JavaScriptBridge.eval("window.godsvgDialogClosed = false;", true)
	
	_change_callback = JavaScriptBridge.create_callback(_web_on_file_selected)
	input.addEventListener("change", _change_callback)
	_cancel_callback = JavaScriptBridge.create_callback(_web_on_file_dialog_cancelled)
	input.addEventListener("cancel", _cancel_callback)
	
	input.click()  # Open file dialog.
	await Engine.get_main_loop().create_timer(0.5).timeout  # Wait for async JS.
	
	var file_data: Variant
	while true:
		if JavaScriptBridge.eval("window.godsvgDialogClosed;", true):
			return
		
		file_data = JavaScriptBridge.eval("window.godsvgFileData;", true)
		if file_data != null:
			break
		await Engine.get_main_loop().create_timer(0.5).timeout
	var file_name: String = JavaScriptBridge.eval("window.godsvgFileName;", true)
	var extension := file_name.get_extension().to_lower()
	
	if not extension in allowed_extensions:
		var alert_dialog: Node = AlertDialog.instantiate()
		HandlerGUI.add_menu(alert_dialog)
		alert_dialog.setup(TranslationUtils.get_bad_extension_alert_text(extension,
				allowed_extensions))
	else:
		completion_callback.call(file_data, file_name)

static func _web_on_file_selected(args: Array) -> void:
	var event: JavaScriptObject = args[0]
	if event.target.files.length == 0:
		return
	
	var file: JavaScriptObject = event.target.files[0]
	JavaScriptBridge.eval("window.godsvgFileName = '" + file.name + "';", true)
	
	# Store the callback reference to prevent garbage collection.
	var reader: JavaScriptObject = JavaScriptBridge.create_object("FileReader")
	_file_load_callback = JavaScriptBridge.create_callback(_web_on_file_loaded)
	reader.onloadend = _file_load_callback
	if file.name.get_extension().to_lower() in ["svg", "xml"]:
		reader.readAsText(file)
	else:
		reader.readAsArrayBuffer(file)

# Global variables... Otherwise the garbage collector ruins everything.
static var _change_callback: JavaScriptObject
static var _cancel_callback: JavaScriptObject
static var _file_load_callback: JavaScriptObject

static func _web_on_file_loaded(args: Array) -> void:
	var event: JavaScriptObject = args[0]
	
	var FileReader := JavaScriptBridge.get_interface("FileReader")
	if event.target.readyState != FileReader.DONE:
		return
	
	var file_name: String = JavaScriptBridge.eval("window.godsvgFileName;", true)
	# Use proper string escaping for the file content.
	if file_name.get_extension().to_lower() in ["svg", "xml"]:
		JavaScriptBridge.eval("window.godsvgFileData = `" + event.target.result + "`;", true)
	else:
		# For binary files, the ArrayBuffer gets handled.
		JavaScriptBridge.eval("window.godsvgFileData = new Uint8Array(event.target.result);", true)

static func _web_on_file_dialog_cancelled(_args: Array) -> void:
	JavaScriptBridge.eval("window.godsvgDialogClosed = true;", true)


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
