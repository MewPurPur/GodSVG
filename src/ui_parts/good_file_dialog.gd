# A fallback file dialog, always used if the native file dialog is not available.
extends PanelContainer

const ChooseNameDialog = preload("res://src/ui_parts/choose_name_dialog.tscn")
const ConfirmDialog = preload("res://src/ui_parts/confirm_dialog.tscn")
const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")

signal file_selected(path: String)

const folder_icon = preload("res://visual/icons/Folder.svg")
const broken_file_icon = preload("res://visual/icons/FileBroken.svg")
const text_file_icon = preload("res://visual/icons/TextFile.svg")

const system_dirs_to_show = [OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DOCUMENTS,
		OS.SYSTEM_DIR_DOWNLOADS, OS.SYSTEM_DIR_MOVIES, OS.SYSTEM_DIR_MUSIC,
		OS.SYSTEM_DIR_PICTURES]

enum FileMode {SELECT, SAVE}
var mode: FileMode

var current_dir := ""
var current_file := ""
var default_file := ""
var extensions := PackedStringArray()

var item_height := 16
var search_text := ""

var DA: DirAccess

@onready var close_button: Button = %CloseButton
@onready var special_button: Button = %SpecialButton
@onready var path_label: Label = %PathLabel
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var search_field: BetterLineEdit = %SearchField
@onready var path_field: BetterLineEdit = %PathField
@onready var file_container: HBoxContainer = %FileContainer
@onready var file_field: BetterLineEdit = %FileField
@onready var extension_panel: PanelContainer = %ExtensionPanel
@onready var extension_label: Label = %ExtensionLabel
@onready var drives_list: ItemList = %DrivesList
@onready var file_list: ItemList = %FileList
@onready var folder_up_button: Button = %FolderUpButton
@onready var refresh_button: Button = %RefreshButton
@onready var show_hidden_button: Button = %ShowHiddenButton
@onready var search_button: Button = %SearchButton


class Actions:
	var activation_callback: Callable
	var selection_callback: Callable
	var right_click_callback: Callable
	
	func _init(on_activation := Callable(), on_selection := Callable(),
	on_right_click := Callable()) -> void:
		activation_callback = on_activation
		selection_callback = on_selection
		right_click_callback = on_right_click

func call_activation_callback(actions: Actions) -> void:
	if is_instance_valid(actions) and actions.activation_callback.is_valid():
		actions.activation_callback.call()

func call_selection_callback(actions: Actions) -> void:
	if is_instance_valid(actions) and actions.selection_callback.is_valid():
		actions.selection_callback.call()

func call_right_click_callback(actions: Actions) -> void:
	if is_instance_valid(actions) and actions.right_click_callback.is_valid():
		actions.right_click_callback.call()


func setup(new_dir: String, new_file: String, new_mode: FileMode,
new_extensions: PackedStringArray) -> void:
	current_dir = new_dir
	current_file = new_file
	if new_mode == FileMode.SAVE:
		default_file = new_file
	mode = new_mode
	extensions = new_extensions


func _ready() -> void:
	# Signal connections.
	refresh_button.pressed.connect(refresh_dir)
	close_button.pressed.connect(queue_free)
	file_selected.connect(queue_free.unbind(1))
	special_button.pressed.connect(select_file)
	file_list.get_v_scroll_bar().value_changed.connect(_setup_file_images.unbind(1))
	# Rest of setup.
	if mode == FileMode.SELECT:
		file_container.hide()
	
	var extension_panel_stylebox := extension_panel.get_theme_stylebox("panel")
	extension_panel_stylebox.content_margin_top -= 4
	extension_panel.add_theme_stylebox_override("panel", extension_panel_stylebox)
	if GlobalSettings.savedata.file_dialog_show_hidden:
		show_hidden_button.set_pressed_no_signal(true)
	folder_up_button.tooltip_text = Translator.translate("Go to parent folder")
	refresh_button.tooltip_text = Translator.translate("Refresh files")
	show_hidden_button.tooltip_text =\
			Translator.translate("Toggle the visibility of hidden files")
	search_button.tooltip_text = Translator.translate("Search files")
	
	if mode != FileMode.SELECT:
		title_label.text = Translator.translate("Save SVG")
		extension_label.text = "." + extensions[0]
	else:
		if extensions.size() == 1 and extensions[0] == "svg":
			title_label.text = Translator.translate("Select an SVG")
		elif extensions.size() == 1 and extensions[0] == "xml":
			title_label.text = Translator.translate("Select an XML file")
		else:
			title_label.text = Translator.translate("Select an image")
	
	close_button.text = Translator.translate("Close")
	special_button.text = Translator.translate("Select") if\
			mode == FileMode.SELECT else Translator.translate("Save")
	path_label.text = Translator.translate("Path") + ":"
	
	# Should always be safe.
	refresh_dir()
	if mode == FileMode.SAVE:
		set_file(current_file)
		file_field.grab_focus()
	else:
		special_button.disabled = true
		special_button.mouse_default_cursor_shape = Control.CURSOR_ARROW


func enter_dir(dir: String) -> void:
	if search_button.button_pressed:
		search_button.button_pressed = false
	set_dir(dir)

func refresh_dir() -> void:
	set_dir(current_dir)

func file_sort(file1: String, file2: String) -> bool:
	return file1.naturalnocasecmp_to(file2) == -1

# This function requires a safe input.
func set_dir(dir: String) -> void:
	DA = DirAccess.open(dir)
	if !is_instance_valid(DA):
		return
	
	file_list.clear()
	# Basic setup.
	unfocus_file()
	current_dir = dir
	path_field.text = current_dir
	DA.include_hidden = GlobalSettings.savedata.file_dialog_show_hidden
	# Rebuild the system dirs, as we may now need to highlight the current one.
	drives_list.clear()
	for drive in system_dirs_to_show:
		var drive_path: String =  system_dir_paths[drive] if\
				system_dir_paths.has(drive) else OS.get_system_dir(drive)
		var drive_name := drive_path.get_file()
		if drive_name.is_empty():
			continue
		
		var item_idx := drives_list.add_item(drive_name, get_drive_icon(drive_path))
		drives_list.set_item_metadata(item_idx,
				Actions.new(Callable(), enter_dir.bind(drive_path)))
		if current_dir == drive_path:
			drives_list.select(item_idx)
	drives_list.sort_items_by_text()
	# Disable or enable the "Go to parent" button.
	if current_dir == current_dir.get_base_dir():
		if not folder_up_button.disabled:
			folder_up_button.disabled = true
			folder_up_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		if folder_up_button.disabled:
			folder_up_button.disabled = false
			folder_up_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Gather the files and directories. Must be sorted, so can't use PackedStringArray.
	var directories: Array[String] = []
	var files: Array[String] = []
	for directory in DA.get_directories():
		directories.append(directory)
	for file in DA.get_files():
		files.append(file)
	directories.sort_custom(file_sort)
	files.sort_custom(file_sort)
	# Populate the ItemList.
	for directory in directories:
		if not search_text.is_empty() and not search_text.is_subsequence_ofn(directory):
			continue
		var item_idx := file_list.add_item(directory, folder_icon)
		var dir_path := current_dir.path_join(directory)
		file_list.set_item_metadata(item_idx, Actions.new(
				enter_dir.bind(dir_path), unfocus_file, open_dir_context.bind(dir_path)))
	
	for file in files:
		if not file.get_extension() in extensions or\
		(not search_text.is_empty() and not search_text.is_subsequence_ofn(file)):
			continue
		
		var item_idx := file_list.add_item(file, null)
		file_list.set_item_metadata(item_idx, Actions.new(
				select_file, focus_file.bind(file), open_file_context.bind(file)))
	# If we don't await this stuff, sometimes the item_rect we get is all wrong.
	await file_list.draw
	await get_tree().process_frame
	_setup_file_images()

func set_file(file: String) -> void:
	if mode == FileMode.SELECT:
		if file.is_empty():
			special_button.disabled = true
			special_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			special_button.disabled = false
			special_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not file.is_empty() and not file.get_extension() in extensions and\
	extensions.size() == 1:
		file += "." + extensions[0]
	file_list.ensure_current_is_visible()
	current_file = file
	file_field.text = current_file

# For optimization, only generate the visible files' images.
func _setup_file_images() -> void:
	var visible_start := file_list.position.y + file_list.get_v_scroll_bar().value
	var visible_end := visible_start + file_list.size.y
	for item_idx in file_list.item_count:
		var file_rect := file_list.get_item_rect(item_idx)
		if !is_instance_valid(file_list.get_item_icon(item_idx)) and\
		file_rect.end.y > visible_start and file_rect.position.y < visible_end:
			var file := file_list.get_item_text(item_idx)
			match file.get_extension():
				"xml":
					file_list.set_item_icon(item_idx, text_file_icon)
				"svg":
					# Setup a clean SVG graphic by using the scaling parameter.
					var svg_text := FileAccess.open(current_dir.path_join(file),
							FileAccess.READ).get_as_text()
					var img := Image.new()
					img.load_svg_from_string(svg_text)
					if !is_instance_valid(img) or img.is_empty():
						file_list.set_item_icon(item_idx, broken_file_icon)
					else:
						img.load_svg_from_string(svg_text,
								item_height / maxf(img.get_width(), img.get_height()))
						file_list.set_item_icon(item_idx, ImageTexture.create_from_image(img))
				_:
					var img := Image.load_from_file(current_dir.path_join(file))
					if !is_instance_valid(img) or img.is_empty():
						file_list.set_item_icon(item_idx, broken_file_icon)
					else:
						file_list.set_item_icon(item_idx, ImageTexture.create_from_image(img))


func select_file() -> void:
	if mode == FileMode.SAVE and current_file in DirAccess.get_files_at(current_dir):
		var confirm_dialog := ConfirmDialog.instantiate()
		HandlerGUI.add_dialog(confirm_dialog)
		confirm_dialog.setup(Translator.translate("Alert!"), Translator.translate(
				"A file named \"{file_name}\" already exists. Replacing will overwrite its contents!").format(
				{"file_name": current_file}), Translator.translate("Replace"),
				_on_replace_button_pressed)
	else:
		file_selected.emit(current_dir.path_join(current_file))

func focus_file(path: String) -> void:
	set_file(path.get_file())

func unfocus_file() -> void:
	set_file(default_file)

func copy_path() -> void:
	DisplayServer.clipboard_set(current_dir.path_join(current_file))

func create_folder() -> void:
	var create_folder_dialog := ChooseNameDialog.instantiate()
	HandlerGUI.add_dialog(create_folder_dialog)
	create_folder_dialog.setup(Translator.translate("Create new folder"),
			_on_create_folder_finished, _create_folder_error)

func _create_folder_error(text: String) -> String:
	if text.is_empty():
		return ""
	if not text.is_valid_filename():
		return Translator.translate("Invalid name for a folder.")
	if DirAccess.dir_exists_absolute(current_dir.path_join(text)):
		return Translator.translate("A folder with this name already exists.")
	return ""

func _on_create_folder_finished(text: String) -> void:
	DA = DirAccess.open(current_dir)
	if !is_instance_valid(DA):
		return
	
	var err := DA.make_dir(text)
	if err == OK:
		refresh_dir()
	else:
		var alert_dialog := AlertDialog.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
		alert_dialog.setup(Translator.translate("Failed to create a folder."))


func open_dir_context(dir: String) -> void:
	var context_popup := ContextPopup.new()
	var btn_arr: Array[Button] = [
		ContextPopup.create_button(Translator.translate("Open"),
				enter_dir.bind(dir), false, load("res://visual/icons/OpenFolder.svg"),
				"ui_accept"),
		ContextPopup.create_button(Translator.translate("Copy path"),
				copy_path, false, load("res://visual/icons/Copy.svg"))]
	context_popup.setup(btn_arr, true)
	var vp := get_viewport()
	HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)

func open_file_context(file: String) -> void:
	focus_file(file)
	var btn_arr: Array[Button] = [
		ContextPopup.create_button(special_button.text,
				select_file, false, load("res://visual/icons/OpenFile.svg"), "ui_accept"),
		ContextPopup.create_button(Translator.translate("Copy path"),
				copy_path, false, load("res://visual/icons/Copy.svg"))]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	var vp := get_viewport()
	HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)


func _on_folder_up_button_pressed() -> void:
	set_dir(current_dir.get_base_dir())

func _on_file_list_empty_clicked(_at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		file_list.deselect_all()
		unfocus_file()
	if mouse_button_index == MOUSE_BUTTON_RIGHT and mode == FileMode.SAVE:
		var context_popup := ContextPopup.new()
		var btn_arr: Array[Button] = [
			ContextPopup.create_button(Translator.translate("Create new folder"),
					create_folder, false, load("res://visual/icons/CreateFolder.svg"))]
		context_popup.setup(btn_arr, true)
		var vp := get_viewport()
		HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)

func _on_file_list_item_activated(index: int) -> void:
	call_activation_callback(file_list.get_item_metadata(index))

func _on_file_list_item_selected(index: int) -> void:
	call_selection_callback(file_list.get_item_metadata(index))

func _on_file_list_item_clicked(index: int, _at_position: Vector2,
mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		call_right_click_callback(file_list.get_item_metadata(index))

func _on_drives_list_item_selected(index: int) -> void:
	call_selection_callback(drives_list.get_item_metadata(index))

func _on_show_hidden_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_setting("file_dialog_show_hidden", toggled_on)
	refresh_dir()

func _on_search_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		search_field.show()
		search_field.grab_focus()
	else:
		search_field.hide()
		search_field.clear()
		refresh_dir()


func _on_file_field_text_submitted(new_text: String) -> void:
	file_field.remove_theme_color_override("font_color")
	if new_text.is_valid_filename():
		current_file = new_text
	else:
		file_field.text = current_file

func _on_path_field_text_submitted(new_text: String) -> void:
	DA = DirAccess.open(new_text)
	if is_instance_valid(DA):
		set_dir(new_text)
	else:
		path_field.text = current_dir

func _on_search_field_text_changed(new_text: String) -> void:
	search_text = new_text
	refresh_dir()

func _on_search_field_text_change_canceled() -> void:
	search_field.text = search_text

func _on_file_field_text_changed(new_text: String) -> void:
	var is_invalid_filename := not new_text.is_valid_filename()
	if new_text.is_empty() or is_invalid_filename:
		special_button.disabled = true
		special_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		special_button.disabled = false
		special_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	file_field.add_theme_color_override("font_color",
			GlobalSettings.get_validity_color(is_invalid_filename))

func _on_file_field_text_change_canceled() -> void:
	file_field.remove_theme_color_override("font_color")


func _on_replace_button_pressed() -> void:
	file_selected.emit(current_dir.path_join(current_file))


# Helpers

func _init() -> void:
	for enum_value in [OS.SYSTEM_DIR_DCIM, OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DOCUMENTS,
	OS.SYSTEM_DIR_DOWNLOADS, OS.SYSTEM_DIR_MOVIES, OS.SYSTEM_DIR_MUSIC,
	OS.SYSTEM_DIR_PICTURES, OS.SYSTEM_DIR_RINGTONES]:
		system_dir_paths[enum_value] = OS.get_system_dir(enum_value)

var system_dir_paths := {}

func get_drive_icon(path: String) -> Texture2D:
	if path == system_dir_paths[OS.SYSTEM_DIR_DESKTOP]:
		return load("res://visual/icons/DirDesktop.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_DOCUMENTS]:
		return load("res://visual/icons/DirDocuments.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_DOWNLOADS]:
		return load("res://visual/icons/DirDownloads.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_MOVIES]:
		return load("res://visual/icons/DirMovies.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_MUSIC]:
		return load("res://visual/icons/DirMusic.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_PICTURES]:
		return load("res://visual/icons/DirPictures.svg")
	else:
		return folder_icon

func _input(event: InputEvent) -> void:
	if ShortcutUtils.is_action_pressed(event, "find"):
		search_button.button_pressed = true
		accept_event()
	elif Input.is_action_pressed("ui_accept"):
		var selected_item_indices := file_list.get_selected_items()
		if not selected_item_indices.is_empty():
			call_activation_callback(file_list.get_item_metadata(selected_item_indices[0]))
			accept_event()
