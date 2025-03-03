# This class has functionality for importing, exporting, and saving files.
class_name FileUtils extends RefCounted

enum FileState {SAME, DIFFERENT, DOES_NOT_EXIST}
enum TabCloseMode {SINGLE, TO_LEFT, TO_RIGHT, ALL_OTHERS}

const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")
const OptionsDialogScene = preload("res://src/ui_widgets/options_dialog.tscn")
const ImportWarningMenuScene = preload("res://src/ui_parts/import_warning_menu.tscn")
const GoodFileDialogScene = preload("res://src/ui_parts/good_file_dialog.tscn")

static func reset_svg() -> void:
	var file_path := Configs.savedata.get_active_tab().svg_file_path
	if FileAccess.file_exists(file_path):
		State.apply_svg_text(FileAccess.get_file_as_string(file_path))

static func apply_svg_from_path(path: String) -> void:
	_finish_file_import(path, _apply_svg, PackedStringArray(["svg"]))

static func compare_svg_to_disk_contents() -> FileState:
	var content := FileAccess.get_file_as_string(
			Configs.savedata.get_active_tab().svg_file_path)
	if content.is_empty():
		return FileState.DOES_NOT_EXIST
	# Check if importing the file's text into GodSVG would change the current SVG text.
	if State.svg_text == SVGParser.root_to_editor_text(SVGParser.text_to_root(content).svg):
		return FileState.SAME
	else:
		return FileState.DIFFERENT


static func save_svg() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	var file_path := active_tab.svg_file_path
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		active_tab.save_to_bound_path()
	else:
		save_svg_as()

static func save_svg_as() -> void:
	open_export_dialog(ImageExportData.new())

static func open_export_dialog(export_data: ImageExportData) -> void:
	OS.request_permissions()
	if OS.has_feature("web"):
		var web_format_name := ImageExportData.web_formats[export_data.format]
		if export_data.format == "svg":
			_web_save(ImageExportData.svg_to_buffer(), web_format_name)
		else:
			var img := export_data.generate_image()
			_web_save(export_data.image_to_buffer(img), web_format_name)
	else:
		if _is_native_preferred():
			var native_callback :=\
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int) -> void:
						if has_selected:
							_finish_export(files[0], export_data)
			
			DisplayServer.file_dialog_show(
					Translator.translate("Save the .\"{format}\" file").format(
					{"format": export_data.format}), Configs.savedata.get_active_tab_dir(),
					_choose_file_name() + "." + export_data.format, false,
					DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
					PackedStringArray(["*." + export_data.format]), native_callback)
		else:
			var export_dialog := GoodFileDialogScene.instantiate()
			export_dialog.setup(Configs.savedata.get_active_tab_dir(), _choose_file_name(),
					GoodFileDialog.FileMode.SAVE, PackedStringArray([export_data.format]))
			HandlerGUI.add_menu(export_dialog)
			export_dialog.file_selected.connect(
					func(path: String) -> void: _finish_export(path, export_data))

static func open_xml_export_dialog(xml: String, file_name: String) -> void:
	OS.request_permissions()
	if OS.has_feature("web"):
		_web_save(xml.to_utf8_buffer(), "application/xml")
	else:
		if _is_native_preferred():
			var native_callback :=\
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int) -> void:
						if has_selected:
							_finish_xml_export(files[0], xml)
			
			DisplayServer.file_dialog_show(
					Translator.translate("Save the .\"{format}\" file").format(
					{"format": "xml"}), Configs.savedata.get_last_dir(),
					file_name + ".xml", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
					PackedStringArray(["*.xml"]), native_callback)
		else:
			var export_dialog := GoodFileDialogScene.instantiate()
			export_dialog.setup(Configs.savedata.get_last_dir(),
					file_name, GoodFileDialog.FileMode.SAVE, PackedStringArray(["xml"]))
			HandlerGUI.add_menu(export_dialog)
			export_dialog.file_selected.connect(
					func(path: String) -> void: _finish_xml_export(path, xml))

static func _finish_export(file_path: String, export_data: ImageExportData) -> void:
	if file_path.get_extension().is_empty():
		file_path += "." + export_data.format
	
	Configs.savedata.add_recent_dir(file_path.get_base_dir())
	
	match export_data.format:
		"png": export_data.generate_image().save_png(file_path)
		"jpg", "jpeg": export_data.generate_image().save_jpg(file_path, export_data.quality)
		"webp": export_data.generate_image().save_webp(file_path, export_data.lossy, export_data.quality)
		_:
			# When saving SVG, also modify the file path to associate it
			# with the graphic being edited.
			var active_tab := Configs.savedata.get_active_tab()
			active_tab.svg_file_path = file_path
			active_tab.save_to_bound_path()
	HandlerGUI.remove_all_menus()

static func _finish_xml_export(file_path: String, xml: String) -> void:
	if file_path.get_extension().is_empty():
		file_path += ".xml"
	
	Configs.savedata.add_recent_dir(file_path.get_base_dir())
	FileAccess.open(file_path, FileAccess.WRITE).store_string(xml)
	HandlerGUI.remove_all_menus()


static func _is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE) and\
			Configs.savedata.use_native_file_dialog

static func _choose_file_name() -> String:
	return Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)


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
	OS.request_permissions()
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
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int) -> void:
						if has_selected:
							_finish_file_import(files[0], completion_callback, extensions)
			
			DisplayServer.file_dialog_show(native_dialog_title,
					Configs.savedata.get_last_dir(), "", false,
					DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, native_callback)
		else:
			var import_dialog := GoodFileDialogScene.instantiate()
			import_dialog.setup(Configs.savedata.get_last_dir(), "",
					GoodFileDialog.FileMode.SELECT, extensions)
			HandlerGUI.add_menu(import_dialog)
			import_dialog.file_selected.connect(
					func(path: String) -> void:
						_finish_file_import(path, completion_callback, extensions)
			)

static func _finish_file_import(file_path: String, completion_callback: Callable,
allowed_extensions: PackedStringArray) -> Error:
	var file := FileAccess.open(file_path, FileAccess.READ)
	var error := ""
	var file_extension := file_path.get_extension()
	
	Configs.savedata.add_recent_dir(file_path.get_base_dir())
	
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
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
		alert_dialog.setup(error)
		return ERR_FILE_CANT_OPEN
	
	# The XML callbacks happen to not need the file path.
	match file_extension:
		"svg": completion_callback.call(file.get_as_text(), file_path)
		"xml": completion_callback.call(file.get_as_text())
		_: completion_callback.call(file.get_buffer(file.get_length()), file_path)
	return OK


static func _apply_svg(data: Variant, file_path: String) -> void:
	var tab_exists := false
	for tab in Configs.savedata.get_tabs():
		if tab.svg_file_path == file_path:
			tab_exists = true
			break
	
	if tab_exists:
		Configs.savedata.add_tab_with_path(file_path)
		var alert_message := Translator.translate(
				"The imported file is already being edited inside GodSVG.")
		if compare_svg_to_disk_contents() == FileState.DIFFERENT:
			alert_message += "\n\n" + Translator.translate(
					"If you want to revert your edits since the last save, use {reset_svg}.").format(
					{"reset_svg": TranslationUtils.get_shortcut_description("reset_svg")})
		
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_menu(alert_dialog)
		alert_dialog.setup(alert_message)
		return
	
	# If the active tab is empty, replace it. Otherwise make it a new transient tab.
	# If there are already too many tabs, do nothing.
	if Configs.savedata.get_active_tab().empty_unsaved:
		var warning_panel := ImportWarningMenuScene.instantiate()
		var tab_index := Configs.savedata.get_active_tab_index()
		Configs.savedata.add_tab_with_path(file_path)
		Configs.savedata.remove_tab(tab_index)
		Configs.savedata.move_tab(Configs.savedata.get_tab_count() - 1, tab_index)
		warning_panel.canceled.connect(_on_import_panel_canceled_empty_tab_scenario)
		warning_panel.imported.connect(_on_import_panel_accepted_empty_tab_scenario.bind(
				data))
		warning_panel.set_svg(data)
		HandlerGUI.add_menu(warning_panel)
	elif Configs.savedata.get_tab_count() < SaveData.MAX_TABS:
		var warning_panel := ImportWarningMenuScene.instantiate()
		State.transient_tab_path = file_path
		warning_panel.canceled.connect(_on_import_panel_canceled_transient_scenario)
		warning_panel.imported.connect(_on_import_panel_accepted_transient_scenario.bind(
				file_path, data))
		warning_panel.set_svg(data)
		HandlerGUI.add_menu(warning_panel)

static func _on_import_panel_canceled_empty_tab_scenario() -> void:
	var tab_index := Configs.savedata.get_active_tab_index()
	Configs.savedata.add_empty_tab()
	Configs.savedata.remove_tab(tab_index)
	Configs.savedata.move_tab(Configs.savedata.get_tab_count() - 1, tab_index)

static func _on_import_panel_accepted_empty_tab_scenario(svg_text: String) -> void:
	Configs.savedata.get_active_tab().setup_svg_text(svg_text)
	State.sync_elements()

static func _on_import_panel_canceled_transient_scenario() -> void:
	State.transient_tab_path = ""

static func _on_import_panel_accepted_transient_scenario(
file_path: String, svg_text: String) -> void:
	Configs.savedata.add_tab_with_path(file_path)
	State.transient_tab_path = ""
	Configs.savedata.get_active_tab().setup_svg_text(svg_text)
	State.sync_elements()


static func open_svg(file_path: String) -> void:
	OS.shell_open(file_path)

static func open_svg_folder(file_path: String) -> void:
	OS.shell_show_in_file_manager(file_path)


static func close_tabs(initial_idx: int, tab_close_mode := TabCloseMode.SINGLE) -> void:
	var indices: Array[int] = []
	match tab_close_mode:
		TabCloseMode.SINGLE:
			indices = [initial_idx]
		TabCloseMode.TO_LEFT:
			for i in range(initial_idx - 1, -1, -1):
				indices.append(i)
		TabCloseMode.TO_RIGHT:
			for i in Configs.savedata.get_tab_count() - initial_idx - 1:
				indices.append(initial_idx + 1)
		TabCloseMode.ALL_OTHERS:
			for i in initial_idx:
				indices.append(0)
			for i in Configs.savedata.get_tab_count() - initial_idx - 1:
				indices.append(1)
	_close_tabs_internal(indices)

static func _close_tabs_internal(indices: Array[int]) -> void:
	if indices.is_empty():
		return
	
	var idx: int = indices.pop_front()
	if idx < 0 or idx >= Configs.savedata.get_tab_count():
		return
	
	var tab := Configs.savedata.get_tab(idx)
	
	var dont_save_callback := func() -> void:
			Configs.savedata.remove_tab(idx)
			_close_tabs_internal(indices.duplicate())
	
	if tab.marked_unsaved or (tab.svg_file_path.is_empty() and not tab.empty_unsaved):
		
		var save_callback := func() -> void:
				save_svg()
				dont_save_callback.call()
		
		Configs.savedata.set_active_tab_index(idx)
		var options_dialog := OptionsDialogScene.instantiate()
		HandlerGUI.add_dialog(options_dialog)
		options_dialog.setup(Translator.translate("Save the changes?"), Translator.translate(
				"Do you want to save the changes made to {file_name}?").format({"file_name":
				Configs.savedata.get_active_tab().presented_name}) + "\n\n" +\
				Translator.translate("Your changes will be lost if you don't save them."))
		options_dialog.add_option(Translator.translate("Don't save"), dont_save_callback)
		options_dialog.add_cancel_option()
		options_dialog.add_option(Translator.translate("Save"), save_callback, true)
	else:
		dont_save_callback.call()


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
	_cancel_callback = JavaScriptBridge.create_callback(_web_on_file_dialog_canceled)
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
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
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
	
	# Store the callback to prevent garbage collection.
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

static func _web_on_file_dialog_canceled(_args: Array) -> void:
	JavaScriptBridge.eval("window.godsvgDialogClosed = true;", true)


static func _web_save(buffer: PackedByteArray, format_name: String) -> void:
	var file_name := Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)
	if file_name.is_empty():
		file_name = "export"
	JavaScriptBridge.download_buffer(buffer, file_name, format_name)
