# This class has functionality for importing, exporting, and saving files.
class_name FileUtils extends RefCounted

enum FileState {SAME, DIFFERENT, DOES_NOT_EXIST}
enum TabCloseMode {SINGLE, ALL_OTHERS, TO_LEFT, TO_RIGHT, EMPTY, SAVED}

const GoodFileDialog = preload("res://src/ui_parts/good_file_dialog.gd")

const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")
const ConfirmDialogScene = preload("res://src/ui_widgets/confirm_dialog.tscn")
const OptionsDialogScene = preload("res://src/ui_widgets/options_dialog.tscn")
const ImportWarningMenuScene = preload("res://src/ui_parts/import_warning_menu.tscn")
const GoodFileDialogScene = preload("res://src/ui_parts/good_file_dialog.tscn")

static func reset_svg() -> void:
	var file_path := Configs.savedata.get_active_tab().svg_file_path
	if FileAccess.file_exists(file_path):
		State.apply_svg_text(FileAccess.get_file_as_string(file_path))

static func apply_svgs_from_paths(paths: PackedStringArray) -> void:
	_start_file_import_process(paths, _apply_svg, PackedStringArray(["svg"]))

static func compare_svg_to_disk_contents(idx := -1) -> FileState:
	var tab := Configs.savedata.get_active_tab() if idx == -1 else Configs.savedata.get_tab(idx)
	var content := FileAccess.get_file_as_string(tab.svg_file_path)
	if content.is_empty():
		return FileState.DOES_NOT_EXIST
	# Check if importing the file's text into GodSVG would change the current SVG text.
	# Avoid the parsing if checking the active tab.
	var state_svg_text := State.svg_text if idx == -1 else\
			SVGParser.root_to_editor_text(SVGParser.text_to_root(tab.get_true_svg_text()).svg)
	if state_svg_text == SVGParser.root_to_editor_text(SVGParser.text_to_root(content).svg):
		return FileState.SAME
	else:
		return FileState.DIFFERENT


static func _save_svg_with_custom_final_callback(final_callback: Callable) -> void:
	var active_tab := Configs.savedata.get_active_tab()
	var file_path := active_tab.svg_file_path
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		active_tab.save_to_bound_path()
		if final_callback.is_valid():
			final_callback.call()
	else:
		_save_svg_as_with_custom_final_callback(final_callback)

static func _save_svg_as_with_custom_final_callback(final_callback: Callable) -> void:
	open_export_dialog(ImageExportData.new(), final_callback)

static func save_svg() -> void:
	_save_svg_with_custom_final_callback(Callable())

static func save_svg_as() -> void:
	_save_svg_as_with_custom_final_callback(Callable())

static func open_export_dialog(export_data: ImageExportData, final_callback := Callable()) -> void:
	OS.request_permissions()
	if OS.has_feature("web"):
		var buffer: PackedByteArray
		if export_data.format == "svg":
			buffer = ImageExportData.svg_to_buffer()
		else:
			buffer = export_data.image_to_buffer(export_data.generate_image())
		_web_save(buffer, ImageExportData.image_types_dict[export_data.format])
		if final_callback.is_valid():
			final_callback.call()
	else:
		if _is_native_preferred():
			var native_callback :=\
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int) -> void:
						if has_selected:
							_finish_export(files[0], export_data)
							if final_callback.is_valid():
								final_callback.call()
			
			DisplayServer.file_dialog_show(
					TranslationUtils.get_file_dialog_save_mode_title_text(export_data.format),
					Configs.savedata.get_active_tab_dir(),
					_choose_file_name() + "." + export_data.format, false,
					DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
					PackedStringArray(["*." + export_data.format]), native_callback)
		else:
			var non_native_callback :=\
					func(paths: PackedStringArray) -> void:
						_finish_export(paths[0], export_data)
						if final_callback.is_valid():
							final_callback.call()
			
			var export_dialog := GoodFileDialogScene.instantiate()
			export_dialog.setup(Configs.savedata.get_active_tab_dir(), _choose_file_name(),
					GoodFileDialog.FileMode.SAVE, PackedStringArray([export_data.format]))
			HandlerGUI.add_menu(export_dialog)
			export_dialog.files_selected.connect(non_native_callback)

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
					TranslationUtils.get_file_dialog_save_mode_title_text("xml"),
					Configs.savedata.get_last_dir(),
					file_name + ".xml", false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
					PackedStringArray(["*.xml"]), native_callback)
		else:
			var export_dialog := GoodFileDialogScene.instantiate()
			export_dialog.setup(Configs.savedata.get_last_dir(),
					file_name, GoodFileDialog.FileMode.SAVE, PackedStringArray(["xml"]))
			HandlerGUI.add_menu(export_dialog)
			export_dialog.files_selected.connect(
					func(paths: PackedStringArray) -> void: _finish_xml_export(paths[0], xml))

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
	HandlerGUI.remove_all_menus()  # At least for now this is what's always needed.


static func _finish_xml_export(file_path: String, xml: String) -> void:
	if file_path.get_extension().is_empty():
		file_path += ".xml"
	
	Configs.savedata.add_recent_dir(file_path.get_base_dir())
	FileAccess.open(file_path, FileAccess.WRITE).store_string(xml)

static func _finish_reference_load(data: Variant, file_path: String) -> void:
	var img := Image.new()
	match file_path.get_extension().to_lower():
		"svg": img.load_svg_from_string(data)
		"png": img.load_png_from_buffer(data)
		"jpg", "jpeg": img.load_jpg_from_buffer(data)
		"webp": img.load_webp_from_buffer(data)
	load_reference_from_image(img)

static func load_reference_from_image(img: Image) -> void:
	Configs.savedata.get_active_tab().reference_image = ImageTexture.create_from_image(img)


static func _is_native_preferred() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE) and\
			Configs.savedata.use_native_file_dialog

static func _choose_file_name() -> String:
	return Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)


# No need for completion callback here yet.
static func open_svg_import_dialog() -> void:
	_open_import_dialog(PackedStringArray(["svg"]), _apply_svg, true)

static func open_image_import_dialog() -> void:
	_open_import_dialog(PackedStringArray(["png", "jpg", "jpeg", "webp", "svg"]),
			_finish_reference_load)

static func open_xml_import_dialog(completion_callback: Callable) -> void:
	_open_import_dialog(PackedStringArray(["xml"]), completion_callback)


# On web, the completion callback can't use the full file path.
static func _open_import_dialog(extensions: PackedStringArray,
completion_callback: Callable, multi_select := false) -> void:
	OS.request_permissions()
	var extensions_with_dots := PackedStringArray()
	for extension in extensions:
		extensions_with_dots.append("." + extension)
	
	if OS.has_feature("web"):
		_web_load_files(extensions, completion_callback, multi_select)
	else:
		if _is_native_preferred():
			var filters := PackedStringArray()
			for extension in extensions_with_dots:
				filters.append("*" + extension)
			
			var native_callback :=\
					func(has_selected: bool, files: PackedStringArray, _filter_idx: int) -> void:
						if has_selected:
							_start_file_import_process(files, completion_callback, extensions)
			
			DisplayServer.file_dialog_show(
					TranslationUtils.get_file_dialog_select_mode_title_text(multi_select,
					extensions), Configs.savedata.get_last_dir(), "", false,
					DisplayServer.FILE_DIALOG_MODE_OPEN_FILES if multi_select else\
					DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, native_callback)
		else:
			var import_dialog := GoodFileDialogScene.instantiate()
			import_dialog.setup(Configs.savedata.get_last_dir(), "",
					GoodFileDialog.FileMode.MULTI_SELECT if multi_select else\
					GoodFileDialog.FileMode.SELECT, extensions)
			HandlerGUI.add_menu(import_dialog)
			import_dialog.files_selected.connect(
					func(paths: PackedStringArray) -> void:
						_start_file_import_process(paths, completion_callback, extensions)
			)

# Preprocessing step where all files with wrong extensions are discarded.
static func _start_file_import_process(file_paths: PackedStringArray,
completion_callback: Callable, allowed_extensions: PackedStringArray) -> void:
	var incorrect_extension_file_paths := PackedStringArray()
	for i in range(file_paths.size() - 1, -1, -1):
		if not file_paths[i].get_extension() in allowed_extensions:
			incorrect_extension_file_paths.append(Utils.simplify_file_path(file_paths[i]))
			file_paths.remove_at(i)
	
	var proceed_callback := _file_import_proceed.bind(file_paths, completion_callback)
	
	if not incorrect_extension_file_paths.is_empty():
		var error_text := TranslationUtils.get_extension_alert_text(allowed_extensions) + "\n"
		var passed_list := PackedStringArray()  # Only pass if there are more than two.
		if incorrect_extension_file_paths.size() >= 2:
			incorrect_extension_file_paths.reverse()
			error_text += Translator.translate("The following files were discarded:")
			passed_list = incorrect_extension_file_paths
		else:
			error_text += Translator.translate("{file_name} was discarded.").format(
					{"file_name": incorrect_extension_file_paths[0].get_file()})
		
		var options_dialog := OptionsDialogScene.instantiate()
		HandlerGUI.add_dialog(options_dialog)
		options_dialog.set_text_width(360.0)
		options_dialog.setup(Translator.translate("Discarded files"), error_text, passed_list)
		options_dialog.add_cancel_option()
		if not file_paths.is_empty():
			options_dialog.add_option(Translator.translate("Proceed"), proceed_callback, true)
		return
	
	proceed_callback.call()

static func _file_import_proceed(file_paths: PackedStringArray,
completion_callback: Callable, show_file_missing_alert := true) -> void:
	var file_path := file_paths[0]
	var preserved_file_paths := file_paths.duplicate()
	file_paths.remove_at(0)
	var proceed_callback := _file_import_proceed.bind(file_paths, completion_callback,
			show_file_missing_alert)
	var retry_callback := _file_import_proceed.bind(preserved_file_paths,
			completion_callback)
	var file := WebSafeFileAccess.open(file_path, FileAccess.READ)
	
	# If it's impossible to somehow import files from multiple dirs at the same time,
	# this can be moved to the initial processing.
	Configs.savedata.add_recent_dir(file_path.get_base_dir())
	
	# If the file alert is shown, the buttons decide what happens next, so we exit early
	# to avoid any file operations. If the file alert is not shown, we should call
	# proceed_callback automatically and still exit early.
	if not file.is_valid():
		if show_file_missing_alert:
			var options_dialog := OptionsDialogScene.instantiate()
			HandlerGUI.add_dialog(options_dialog)
			var error := Translator.translate("{file_name} couldn't be opened.").format(
					{"file_name": Utils.simplify_file_path(file_path).get_file()})
			if not FileAccess.file_exists(file_path):
				error += "\n" + Translator.translate("Check if the file still exists in the selected file path.")
			if not file_paths.is_empty():
				error += "\n" + Translator.translate("Proceed with importing the rest of the files?")
			
			if file_paths.is_empty():
				options_dialog.setup(Translator.translate("Alert!"), error)
			else:
				options_dialog.setup(Translator.translate("Alert!"), error, PackedStringArray(),
						Translator.translate("Proceed for all files that can't be opened"))
			
			options_dialog.add_cancel_option()
			options_dialog.add_option(Translator.translate("Retry"), retry_callback, false,
					true, Callable(), true)
			if not file_paths.is_empty():
				options_dialog.add_option(Translator.translate("Proceed"), proceed_callback,
						true, true, _file_import_proceed.bind(file_paths, completion_callback,
						false), false, true)
			return
		else:
			if not file_paths.is_empty():
				proceed_callback.call()
			return
	
	# The XML callbacks currently happen to not need the file path.
	# The SVG callback used currently can popup extra dialogs, so they need the callable.
	match file_path.get_extension():
		"svg":
			if file_paths.is_empty():
				completion_callback.call(file.get_as_text(), file_path)
			else:
				completion_callback.call(file.get_as_text(), file_path, proceed_callback,
						false)
		"xml": completion_callback.call(file.get_as_text())
		_: completion_callback.call(file.get_buffer(file.get_length()), file_path)


static func _apply_svg(data: Variant, file_path: String, proceed_callback := Callable(),
is_last_file := true) -> void:
	var existing_tab_idx := -1
	for tab_idx in Configs.savedata.get_tab_count():
		if Configs.savedata.get_tab(tab_idx).svg_file_path == file_path:
			existing_tab_idx = tab_idx
			break
	
	if existing_tab_idx != -1:
		Configs.savedata.add_tab_with_path(file_path)
		var alert_message := Translator.translate(
				"{file_path} is already being edited inside GodSVG.").format(
					{"file_path": Utils.simplify_file_path(file_path)})
		if compare_svg_to_disk_contents(existing_tab_idx) == FileState.DIFFERENT:
			alert_message += "\n\n" + Translator.translate(
					"If you want to revert your edits since the last save, use {reset_svg}.").format(
					{"reset_svg": TranslationUtils.get_action_description("reset_svg")})
		
		if is_last_file:
			var alert_dialog := AlertDialogScene.instantiate()
			HandlerGUI.add_menu(alert_dialog)
			alert_dialog.setup(alert_message)
		else:
			var confirm_dialog := ConfirmDialogScene.instantiate()
			HandlerGUI.add_menu(confirm_dialog)
			confirm_dialog.setup(Translator.translate("Alert!"), alert_message,
					Translator.translate("Proceed"), proceed_callback)
		return
	
	# If the active tab is empty, replace it. Otherwise make it a new transient tab.
	var warning_panel := ImportWarningMenuScene.instantiate()
	if Configs.savedata.get_active_tab().empty_unsaved:
		var tab_index := Configs.savedata.get_active_tab_index()
		Configs.savedata.add_tab_with_path(file_path)
		Configs.savedata.remove_tab(tab_index)
		Configs.savedata.move_tab(Configs.savedata.get_tab_count() - 1, tab_index)
		warning_panel.canceled.connect(_on_import_panel_canceled_empty_tab_scenario)
		warning_panel.imported.connect(_on_import_panel_accepted_empty_tab_scenario.bind(
				data))
	else:
		State.transient_tab_path = file_path
		warning_panel.canceled.connect(_on_import_panel_canceled_transient_scenario)
		warning_panel.imported.connect(_on_import_panel_accepted_transient_scenario.bind(
				file_path, data))
	if not is_last_file:
		warning_panel.canceled.connect(proceed_callback)
		warning_panel.imported.connect(proceed_callback)
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
		TabCloseMode.EMPTY:
			var idx_to_append := 0
			for tab in Configs.savedata.get_tabs():
				if tab.is_empty():
					indices.append(idx_to_append)
				else:
					idx_to_append += 1
		TabCloseMode.SAVED:
			var idx_to_append := 0
			for tab in Configs.savedata.get_tabs():
				if tab.is_saved():
					indices.append(idx_to_append)
				else:
					idx_to_append += 1
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
			HandlerGUI.remove_all_menus()
			_close_tabs_internal(indices.duplicate())
	
	if tab.marked_unsaved or (tab.svg_file_path.is_empty() and not tab.empty_unsaved):
		Configs.savedata.set_active_tab_index(idx)
		var save_callback := _save_svg_with_custom_final_callback.bind(dont_save_callback)
		
		var title := ""
		var message := ""
		if tab.svg_file_path.is_empty():
			title = Translator.translate("Save the file?")
			message = Translator.translate("Do you want to save this file?")
		else:
			title = Translator.translate("Save the changes?")
			message = Translator.translate(
					"Do you want to save the changes made to {file_name}?").format(
					{"file_name": Configs.savedata.get_active_tab().presented_name}) + "\n\n" +\
					Translator.translate("Your changes will be lost if you don't save them.")
		
		var options_dialog := OptionsDialogScene.instantiate()
		HandlerGUI.add_menu(options_dialog)
		options_dialog.setup(title, message)
		if OS.get_name() == "Windows":
			options_dialog.add_option(Translator.translate("Save"), save_callback, true, false)
			options_dialog.add_option(Translator.translate("Don't save"), dont_save_callback)
			options_dialog.add_cancel_option()
		else:
			options_dialog.add_option(Translator.translate("Don't save"), dont_save_callback)
			options_dialog.add_cancel_option()
			options_dialog.add_option(Translator.translate("Save"), save_callback, true, false)
	else:
		dont_save_callback.call()


# Web-specific stuff from here on. The approach for importing multiple files at once
# on web, where I can't access the user's file paths, is to populate _web_file_data_cache
# with fake paths and data from the FileReader, and use the WebSafeFileAccess class which
# normally acts like FileAccess, but on web it accesses that cache instead.

# Global variables... Otherwise the garbage collector ruins everything.
static var _change_callback: JavaScriptObject
static var _cancel_callback: JavaScriptObject
static var _file_load_callbacks: Array[JavaScriptObject] = []

static var _web_file_data_cache: Dictionary[String, Variant] = {}

class WebSafeFileAccess:
	var _file_access: FileAccess
	var _cached_data: Variant
	var _is_web_file: bool = false
	
	static func open(file_path: String, mode: int) -> WebSafeFileAccess:
		var wrapper = WebSafeFileAccess.new()
		if OS.has_feature("web") and FileUtils._web_file_data_cache.has(file_path):
			wrapper._cached_data = FileUtils._web_file_data_cache[file_path]
			wrapper._is_web_file = true
		else:
			wrapper._file_access = FileAccess.open(file_path, mode)
		return wrapper
	
	func is_valid() -> bool:
		if _is_web_file:
			return _cached_data != null
		else:
			return is_instance_valid(_file_access)
	
	func get_as_text() -> String:
		if _is_web_file:
			return _cached_data as String
		else:
			return _file_access.get_as_text()
	
	func get_buffer(length: int) -> PackedByteArray:
		if _is_web_file:
			return _cached_data as PackedByteArray
		else:
			return _file_access.get_buffer(length)
	
	func get_length() -> int:
		if _is_web_file:
			if _cached_data is String:
				return (_cached_data as String).length()
			else:
				return (_cached_data as PackedByteArray).size()
		else:
			return _file_access.get_length()


static func _web_load_files(allowed_extensions: PackedStringArray,
completion_callback: Callable, multi_select: bool) -> void:
	var allowed_extensions_with_dots := PackedStringArray()
	for allowed_extension in allowed_extensions:
		allowed_extensions_with_dots.append("." + allowed_extension)
	
	var document := JavaScriptBridge.get_interface("document")
	
	var input: JavaScriptObject = document.createElement("INPUT")
	input.type = "file"
	input.accept = ",".join(allowed_extensions_with_dots)
	if multi_select:
		input.multiple = true
	
	# Setup and clearing previous data.
	_web_file_data_cache.clear()
	var window = JavaScriptBridge.get_interface("window")
	window.godsvgFileNames = JavaScriptBridge.create_object("Array")
	window.godsvgFileDataArray = JavaScriptBridge.create_object("Array")
	window.godsvgDialogClosed = false
	window.godsvgFilesToProcess = 0
	window.godsvgFilesProcessed = 0
	
	_change_callback = JavaScriptBridge.create_callback(_web_on_files_selected)
	input.addEventListener("change", _change_callback)
	_cancel_callback = JavaScriptBridge.create_callback(_web_on_file_dialog_canceled)
	input.addEventListener("cancel", _cancel_callback)
	
	input.click()  # Open file dialog.
	await Engine.get_main_loop().create_timer(0.5).timeout  # Wait for async JS.
	
	# Wait for all files to be processed.
	while true:
		if window.godsvgDialogClosed:
			return
		
		var files_to_process: int = window.godsvgFilesToProcess
		var files_processed: int = window.godsvgFilesProcessed
		
		if files_to_process > 0 and files_processed >= files_to_process:
			break
		await Engine.get_main_loop().create_timer(0.1).timeout
	
	# Process all loaded files.
	var file_count: int = window.godsvgFileNames.length
	if file_count == 0:
		return
	
	var file_names: Array = []
	var file_data_array: Array = []
	for i in file_count:
		var file_name: String = window.godsvgFileNames[i]
		var file_data: Variant = window.godsvgFileDataArray[i]
		file_names.append(file_name)
		file_data_array.append(file_data)
	
	# Store files in cache with fake paths and collect valid paths.
	var fake_paths := PackedStringArray()
	for i in file_names.size():
		var fake_path: String = file_names[i]
		_web_file_data_cache[fake_path] = file_data_array[i]
		fake_paths.append(fake_path)
	print(fake_paths)
	_start_file_import_process(fake_paths, completion_callback, allowed_extensions)

static func _web_on_files_selected(args: Array) -> void:
	var event: JavaScriptObject = args[0]
	var files: JavaScriptObject = event.target.files
	
	if files.length == 0:
		return
	
	# Set up tracking for multiple files.
	var window = JavaScriptBridge.get_interface("window")
	window.godsvgFilesToProcess = files.length
	window.godsvgFilesProcessed = 0
	
	_file_load_callbacks.clear()
	_file_load_callbacks.resize(files.length)
	
	# Process each file.
	for i in range(files.length):
		var file: JavaScriptObject = files.item(i)
		
		# Store the callback to prevent garbage collection.
		var reader: JavaScriptObject = JavaScriptBridge.create_object("FileReader")
		_file_load_callbacks[i] = JavaScriptBridge.create_callback(_web_on_file_loaded.bind(i))
		reader.onloadend = _file_load_callbacks[i]
		
		window.godsvgFileNames[i] = file.name
		
		# Read file based on extension.
		if file.name.get_extension().to_lower() in ["svg", "xml"]:
			reader.readAsText(file)
		else:
			reader.readAsArrayBuffer(file)

static func _web_on_file_loaded(args: Array, file_index: int) -> void:
	var event: JavaScriptObject = args[0]
	
	var FileReader := JavaScriptBridge.get_interface("FileReader")
	if event.target.readyState != FileReader.DONE:
		return
	
	var window = JavaScriptBridge.get_interface("window")
	var file_name: String = window.godsvgFileNames[file_index]
	
	# Store file data based on type.
	if file_name.get_extension().to_lower() in ["svg", "xml"]:
		# For text files, store directly
		window.godsvgFileDataArray[file_index] = event.target.result
	else:
		# For binary files, convert ArrayBuffer to Uint8Array.
		var Uint8Array = JavaScriptBridge.get_interface("Uint8Array")
		window.godsvgFileDataArray[file_index] = Uint8Array.new(event.target.result)
	
	# Increment processed counter.
	window.godsvgFilesProcessed += 1

static func _web_on_file_dialog_canceled(_args: Array) -> void:
	var window = JavaScriptBridge.get_interface("window")
	window.godsvgDialogClosed = true


static func _web_save(buffer: PackedByteArray, format_name: String) -> void:
	var file_name := Utils.get_file_name(Configs.savedata.get_active_tab().svg_file_path)
	if file_name.is_empty():
		file_name = "export"
	JavaScriptBridge.download_buffer(buffer, file_name, format_name)
