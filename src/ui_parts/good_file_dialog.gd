# A fallback file dialog, always used if the native file dialog is not available.
extends PanelContainer

const DirectoryPathWidget = preload("res://src/ui_widgets/directory_path_widget.gd")

const ChooseNameDialogScene = preload("res://src/ui_widgets/choose_name_dialog.tscn")
const ConfirmDialogScene = preload("res://src/ui_widgets/confirm_dialog.tscn")
const AlertDialogScene = preload("res://src/ui_widgets/alert_dialog.tscn")

# Full absolute file paths of all selected files.
signal files_selected(paths: PackedStringArray)

const folder_icon = preload("res://assets/icons/Folder.svg")
const broken_file_icon = preload("res://assets/icons/FileBroken.svg")
const text_file_icon = preload("res://assets/icons/TextFile.svg")
const font_file_icon = preload("res://assets/icons/FontFile.svg")

const system_dirs_to_show: Array[OS.SystemDir] = [OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DOCUMENTS,
		OS.SYSTEM_DIR_DOWNLOADS, OS.SYSTEM_DIR_MOVIES, OS.SYSTEM_DIR_MUSIC, OS.SYSTEM_DIR_PICTURES]

enum FileMode {SELECT, MULTI_SELECT, SAVE}
var mode: FileMode

var current_dir := ""
var extensions := PackedStringArray()
var search_text := ""

var default_saved_file := ""  # The file you opened this dialog with.

var navigation_history := PackedStringArray()
var navigation_index := -1

var dir_cursor: DirAccess

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var search_field: BetterLineEdit = %SearchField

@onready var file_container: HBoxContainer = %FileContainer
@onready var file_field: BetterLineEdit = %FileContainer/FileField
@onready var extension_panel: PanelContainer = %FileContainer/ExtensionPanel
@onready var extension_label: Label = %FileContainer/ExtensionPanel/ExtensionLabel

@onready var drives_list: ItemList = %DrivesList
@onready var file_list: ItemList = %FileList

@onready var back_button: Button = %TopBar/BackButton
@onready var forward_button: Button = %TopBar/ForwardButton
@onready var path_panel: PanelContainer = %TopBar/PathPanel
@onready var directory_path_widget: DirectoryPathWidget = %TopBar/PathPanel/MainPathBox/DirectoryPathWidget
@onready var path_edit_button: Button = %TopBar/PathPanel/MainPathBox/PathEditButton
@onready var path_field: BetterLineEdit = %TopBar/PathField
@onready var refresh_button: Button = %TopBar/RefreshButton
@onready var show_hidden_button: Button = %TopBar/ShowHiddenButton
@onready var search_button: Button = %TopBar/SearchButton

@onready var close_button: Button = %ButtonContainer/CloseButton
@onready var action_button: Button = %ButtonContainer/ActionButton


class Actions:
	var activation_callback: Callable
	var selection_callback: Callable
	var right_click_callback: Callable
	
	func _init(on_activation := Callable(), on_selection := Callable(),
	on_right_click := Callable()) -> void:
		activation_callback = on_activation
		selection_callback = on_selection
		right_click_callback = on_right_click


# Queueing is necessary for this one because in Godot, "Enter" is hard-coded to activate the selected items.
var _activation_callback_pending := false
func call_activation_callback(actions: Actions) -> void:
	var actual_activation_callback := func() -> void:
		if not _activation_callback_pending:
			return
		_activation_callback_pending = false
		actions.activation_callback.call()
	
	if is_instance_valid(actions) and actions.activation_callback.is_valid():
		actual_activation_callback.call_deferred()
		_activation_callback_pending = true

func call_selection_callback(actions: Actions) -> void:
	if is_instance_valid(actions) and actions.selection_callback.is_valid():
		actions.selection_callback.call()

func call_right_click_callback(actions: Actions) -> void:
	if is_instance_valid(actions) and actions.right_click_callback.is_valid():
		actions.right_click_callback.call()


func setup(new_dir: String, new_file: String, new_mode: FileMode, new_extensions: PackedStringArray) -> void:
	current_dir = new_dir
	if new_mode == FileMode.SAVE:
		default_saved_file = new_file
	mode = new_mode
	extensions = new_extensions


func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("find", func() -> void: search_button.button_pressed = not search_button.button_pressed)
	shortcuts.add_shortcut("ui_accept", func() -> void:
			var selected_item_indices := file_list.get_selected_items()
			if not selected_item_indices.is_empty():
				call_activation_callback(file_list.get_item_metadata(selected_item_indices[0]))
	)
	shortcuts.add_shortcut("open_in_folder", func() -> void:
			var selected_paths := get_selected_file_paths()
			if selected_paths.is_empty():
				OS.shell_open(current_dir)
			else:
				OS.shell_show_in_file_manager(selected_paths[0], false)
	)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	sync_theming()
	
	# Signal connections.
	close_button.pressed.connect(queue_free)
	files_selected.connect(queue_free.unbind(1))
	
	file_field.text_changed.connect(_on_file_field_text_changed)
	file_field.text_change_canceled.connect(_on_file_field_text_change_canceled)
	file_field.text_submitted.connect(_on_file_field_text_submitted)
	file_list.empty_clicked.connect(_on_file_list_empty_clicked)
	file_list.item_activated.connect(_on_file_list_item_activated)
	file_list.item_clicked.connect(_on_file_list_item_clicked)
	file_list.item_selected.connect(_on_file_list_item_selected)
	file_list.multi_selected.connect(_on_file_list_item_multi_selected)
	show_hidden_button.toggled.connect(_on_show_hidden_button_toggled)
	search_button.toggled.connect(_on_search_button_toggled)
	drives_list.item_selected.connect(_on_drives_list_item_selected)
	search_field.text_changed.connect(_on_search_field_text_changed)
	search_field.text_change_canceled.connect(_on_search_field_text_change_canceled)
	refresh_button.pressed.connect(refresh_dir)
	action_button.pressed.connect(select_files)
	back_button.pressed.connect(_on_back_button_pressed)
	forward_button.pressed.connect(_on_forward_button_pressed)
	directory_path_widget.directory_selected.connect(open_dir)
	path_field.text_submitted.connect(_on_path_field_text_submitted)
	path_field.editing_toggled.connect(_on_path_field_editing_toggled)
	path_edit_button.pressed.connect(_on_path_edit_button_pressed)
	file_list.get_v_scroll_bar().value_changed.connect(_setup_file_images.unbind(1))
	
	# Rest of setup.
	if mode != FileMode.SAVE:
		file_container.hide()
		if mode == FileMode.MULTI_SELECT:
			file_list.select_mode = ItemList.SELECT_MULTI
	
	var extension_panel_stylebox := extension_panel.get_theme_stylebox("panel").duplicate()
	extension_panel_stylebox.content_margin_top -= 4.0
	extension_panel.add_theme_stylebox_override("panel", extension_panel_stylebox)
	extension_label.add_theme_color_override("font_color", ThemeUtils.dim_text_color)
	if Configs.savedata.file_dialog_show_hidden:
		show_hidden_button.set_pressed_no_signal(true)
	refresh_button.tooltip_text = Translator.translate("Refresh files")
	show_hidden_button.tooltip_text = Translator.translate("Toggle the visibility of hidden files")
	search_button.tooltip_text = Translator.translate("Search files")
	search_field.placeholder_text = Translator.translate("Search files")
	back_button.tooltip_text = Translator.translate("Go back")
	forward_button.tooltip_text = Translator.translate("Go forward")
	
	if mode == FileMode.SAVE:
		title_label.text = TranslationUtils.get_file_dialog_save_mode_title_text(extensions[0])
		extension_label.text = "." + extensions[0]
	else:
		title_label.text = TranslationUtils.get_file_dialog_select_mode_title_text(mode == FileMode.MULTI_SELECT, extensions)
	
	close_button.text = Translator.translate("Close")
	action_button.text = Translator.translate("Save") if mode == FileMode.SAVE else Translator.translate("Select")
	
	# Should always be safe.
	open_dir(current_dir)
	if mode == FileMode.SAVE:
		sync_file_field()
		file_field.grab_focus()
	else:
		action_button.disabled = true
		action_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	HandlerGUI.register_focus_sequence(self, [back_button, forward_button, path_edit_button, path_field,
			refresh_button, show_hidden_button, search_button, search_field, drives_list, file_list, file_field, close_button, action_button], true)

func sync_theming() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(3)
	stylebox.content_margin_top = 1
	stylebox.content_margin_bottom = 1
	stylebox.content_margin_left = 2
	stylebox.content_margin_right = 2
	stylebox.bg_color = ThemeUtils.overlay_panel_inner_color.lerp(ThemeUtils.extreme_theme_color, 0.2)
	path_panel.add_theme_stylebox_override("panel", stylebox)


func file_sort(file1: String, file2: String) -> bool:
	return file1.naturalnocasecmp_to(file2) == -1

func refresh_dir() -> void:
	open_dir(current_dir, false)

func update_filtering() -> void:
	open_dir(current_dir, false, true)

func open_dir(dir: String, add_to_history := true, only_filtering_update := false) -> void:
	dir_cursor = DirAccess.open(dir)
	if not is_instance_valid(dir_cursor):
		return
	
	if add_to_history:
		navigation_index += 1
		navigation_history.resize(navigation_index)
		navigation_history.append(dir)
		update_navigation_buttons()
	
	if dir != current_dir:
		current_dir = dir
		if search_button.button_pressed:
			search_button.button_pressed = false
	
	file_list.clear()
	file_list.get_v_scroll_bar().value = 0
	
	if not only_filtering_update:
		sync_to_selection()
		directory_path_widget.set_path(current_dir)
	
	dir_cursor.include_hidden = Configs.savedata.file_dialog_show_hidden
	# Rebuild the system dirs, as we may now need to highlight the current one.
	drives_list.clear()
	for drive in system_dirs_to_show:
		var drive_path: String = system_dir_paths.get(drive, OS.get_system_dir(drive))
		var drive_name := drive_path.get_file()
		if drive_name.is_empty():
			continue
		
		var item_idx := drives_list.add_item(drive_name, get_drive_icon(drive_path))
		drives_list.set_item_icon_modulate(item_idx, ThemeUtils.tinted_contrast_color)
		drives_list.set_item_metadata(item_idx, Actions.new(Callable(), open_dir.bind(drive_path)))
		if current_dir == drive_path:
			drives_list.select(item_idx)
	drives_list.sort_items_by_text()
	
	# Gather the files and directories. Must be sorted, so can't use PackedStringArray.
	var directories: Array[String] = []
	var files: Array[String] = []
	for directory in dir_cursor.get_directories():
		directories.append(directory)
	for file in dir_cursor.get_files():
		files.append(file)
	directories.sort_custom(file_sort)
	files.sort_custom(file_sort)
	# Populate the ItemList.
	for directory in directories:
		if not search_text.is_empty() and not search_text.is_subsequence_ofn(directory):
			continue
		var item_idx := file_list.add_item(directory, folder_icon)
		file_list.set_item_icon_modulate(item_idx, ThemeUtils.folder_color)
		var dir_path := current_dir.path_join(directory)
		file_list.set_item_metadata(item_idx, Actions.new(open_dir.bind(dir_path), sync_to_selection, open_dir_context.bind(dir_path)))
	
	for file in files:
		if not Utils.get_lowercase_extension(file) in extensions or (not search_text.is_empty() and not search_text.is_subsequence_ofn(file)):
			continue
		
		var item_idx := file_list.add_item(file, null)
		var file_extension := Utils.get_lowercase_extension(file)
		if file_extension == "xml":
			file_list.set_item_icon(item_idx, text_file_icon)
			file_list.set_item_icon_modulate(item_idx, ThemeUtils.text_file_color)
		elif file_extension in Utils.DYNAMIC_FONT_FORMATS:
			file_list.set_item_icon(item_idx, font_file_icon)
			file_list.set_item_icon_modulate(item_idx, ThemeUtils.text_file_color)
		file_list.set_item_metadata(item_idx, Actions.new(select_files, sync_to_selection, open_file_context))
	# If we don't await this stuff, sometimes the item_rect we get is all wrong.
	await file_list.draw
	await get_tree().process_frame
	_setup_file_images()

func sync_file_field() -> void:
	file_field.text = add_extension_if_missing(get_save_name())

func add_extension_if_missing(file_name: String) -> String:
	if not file_name.is_empty() and not Utils.get_lowercase_extension(file_name) in extensions and\
	extensions.size() >= 1:
		return file_name + "." + extensions[0]
	else:
		return file_name

func get_save_name() -> String:
	var selected_file_paths := get_selected_file_paths()
	if selected_file_paths.is_empty() or selected_file_paths[0].get_extension().is_empty():
		return default_saved_file
	else:
		return selected_file_paths[0].get_file()

# For optimization, only generate the visible files' images.
func _setup_file_images() -> void:
	var visible_start := file_list.position.y + file_list.get_v_scroll_bar().value
	var visible_end := visible_start + file_list.size.y
	for item_idx in file_list.item_count:
		var file_rect := file_list.get_item_rect(item_idx)
		if not is_instance_valid(file_list.get_item_icon(item_idx)) and file_rect.end.y > visible_start and file_rect.position.y < visible_end:
			var file := file_list.get_item_text(item_idx)
			match Utils.get_lowercase_extension(file):
				"svg":
					# Setup a clean SVG graphic by using the scaling parameter.
					var svg_text := FileAccess.get_file_as_string(current_dir.path_join(file))
					var img := Image.new()
					img.load_svg_from_string(svg_text)
					if not is_instance_valid(img) or img.is_empty():
						file_list.set_item_icon(item_idx, broken_file_icon)
					else:
						var icon_size := Vector2(file_list.fixed_icon_size)  # Prevent int division.
						var svg_texture := DPITexture.create_from_string(svg_text, minf(icon_size.x / img.get_width(), icon_size.y / img.get_height()))
						file_list.set_item_icon(item_idx, svg_texture)
				_:
					var img := Image.load_from_file(current_dir.path_join(file))
					if not is_instance_valid(img) or img.is_empty():
						file_list.set_item_icon(item_idx, broken_file_icon)
					else:
						file_list.set_item_icon(item_idx, ImageTexture.create_from_image(img))


func select_files() -> void:
	if mode == FileMode.SAVE:
		var save_name := get_save_name()
		if FileAccess.file_exists(current_dir.path_join(save_name)):
			var confirm_dialog := ConfirmDialogScene.instantiate()
			HandlerGUI.add_dialog(confirm_dialog)
			confirm_dialog.setup(Translator.translate("Alert!"), Translator.translate(
					"A file named \"{file_name}\" already exists. Replacing will overwrite its contents!").format(
					{"file_name": save_name}), Translator.translate("Replace"),
					files_selected.emit.bind(PackedStringArray([current_dir.path_join(save_name)])))
		else:
			files_selected.emit(PackedStringArray([current_dir.path_join(save_name)]))
	else:
		files_selected.emit(get_selected_file_paths())

func sync_to_selection() -> void:
	file_list.ensure_current_is_visible()
	if mode == FileMode.SAVE:
		sync_file_field()
		return
	
	var paths := get_selected_file_paths()
	if paths.is_empty():
		set_action_button_enabled(false)
		return
	
	var has_folders := false
	for path in paths:
		if path.get_extension().is_empty():
			has_folders = true
			break
	set_action_button_enabled(not has_folders)

func set_action_button_enabled(enabled: bool) -> void:
	if enabled:
		action_button.disabled = false
		action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		action_button.disabled = true
		action_button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func get_selected_file_paths() -> PackedStringArray:
	var selections := PackedStringArray()
	for selected_idx in file_list.get_selected_items():
		selections.append(current_dir.path_join(file_list.get_item_text(selected_idx)))
	return selections

func copy_file_path() -> void:
	DisplayServer.clipboard_set(get_selected_file_paths()[0])

func create_folder() -> void:
	var create_folder_dialog := ChooseNameDialogScene.instantiate()
	HandlerGUI.add_dialog(create_folder_dialog)
	create_folder_dialog.setup(Translator.translate("Create new folder"), _on_create_folder_finished, _create_folder_error)

func _create_folder_error(text: String) -> String:
	if text.is_empty():
		return ""
	if not text.is_valid_filename():
		return Translator.translate("Invalid name for a folder.")
	if DirAccess.dir_exists_absolute(current_dir.path_join(text)):
		return Translator.translate("A folder with this name already exists.")
	return ""

func _on_create_folder_finished(text: String) -> void:
	dir_cursor = DirAccess.open(current_dir)
	if not is_instance_valid(dir_cursor):
		return
	
	var err := dir_cursor.make_dir(text)
	if err == OK:
		refresh_dir()
	else:
		var alert_dialog := AlertDialogScene.instantiate()
		HandlerGUI.add_dialog(alert_dialog)
		alert_dialog.setup(Translator.translate("Failed to create a folder."))


func open_dir_context(dir: String) -> void:
	if get_selected_file_paths().size() > 1:
		return
	
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_from_action("ui_accept").add_custom_text(Translator.translate("Open")).add_custom_icon(preload("res://assets/icons/OpenFolder.svg")),
		ContextButton.create_custom(Translator.translate("Copy path"), DisplayServer.clipboard_set.bind(dir), preload("res://assets/icons/Copy.svg")),
		ContextButton.create_from_action("open_in_folder"),
	]
	var vp := get_viewport()
	HandlerGUI.popup_under_pos(ContextPopup.create(btn_arr), vp.get_mouse_position(), vp)

func open_file_context() -> void:
	sync_to_selection()
	var selected_file_paths := get_selected_file_paths()
	if selected_file_paths.size() > 1:
		# Return if any of the files is actually a folder.
		for path in selected_file_paths:
			if path.get_extension().is_empty():
				return
	
	var btn_arr: Array[ContextButton] = [
		ContextButton.create_from_action("ui_accept").add_custom_text(action_button.text).add_custom_icon(preload("res://assets/icons/OpenFile.svg"))
	]
	if selected_file_paths.size() == 1:
		btn_arr.append(ContextButton.create_custom(Translator.translate("Copy path"), copy_file_path, preload("res://assets/icons/Copy.svg")))
	btn_arr.append(ContextButton.create_from_action("open_in_folder"))
	
	var vp := get_viewport()
	HandlerGUI.popup_under_pos(ContextPopup.create(btn_arr), vp.get_mouse_position(), vp)


func _on_file_list_empty_clicked(_at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
		file_list.deselect_all()
		sync_to_selection()
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var btn_arr: Array[ContextButton] = []
		if mode == FileMode.SAVE:
			btn_arr.append(ContextButton.create_custom(Translator.translate("Create new folder"), create_folder, preload("res://assets/icons/CreateFolder.svg")))
		btn_arr.append(ContextButton.create_from_action("open_in_folder"))
		
		var vp := get_viewport()
		HandlerGUI.popup_under_pos(ContextPopup.create(btn_arr), vp.get_mouse_position(), vp)

func _on_file_list_item_activated(index: int) -> void:
	call_activation_callback(file_list.get_item_metadata(index))

func _on_file_list_item_selected(index: int) -> void:
	call_selection_callback(file_list.get_item_metadata(index))

func _on_file_list_item_multi_selected(index: int, selected: bool) -> void:
	if selected:
		call_selection_callback(file_list.get_item_metadata(index))

func _on_file_list_item_clicked(index: int, _at_position: Vector2,
mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		call_right_click_callback(file_list.get_item_metadata(index))

func _on_drives_list_item_selected(index: int) -> void:
	call_selection_callback(drives_list.get_item_metadata(index))

func _on_show_hidden_button_toggled(toggled_on: bool) -> void:
	Configs.savedata.file_dialog_show_hidden = toggled_on
	refresh_dir()

func _on_search_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		search_field.show()
		search_field.grab_focus()
	else:
		search_field.hide()
		search_field.clear()
		update_filtering()


func _on_file_field_text_submitted(new_text: String) -> void:
	file_field.remove_theme_color_override("font_color")
	if new_text.is_valid_filename():
		default_saved_file = new_text
	else:
		file_field.text = default_saved_file


func _on_search_field_text_changed(new_text: String) -> void:
	search_text = new_text
	update_filtering()

func _on_search_field_text_change_canceled() -> void:
	search_field.text = search_text

func _on_file_field_text_changed(new_text: String) -> void:
	var is_valid_filename := new_text.is_valid_filename()
	set_action_button_enabled(not new_text.is_empty() and is_valid_filename)
	file_field.add_theme_color_override("font_color", Configs.savedata.get_validity_color(not is_valid_filename))
	if search_button.button_pressed:
		# Toggling search off will refresh the directory.
		search_button.button_pressed = false

func _on_file_field_text_change_canceled() -> void:
	file_field.remove_theme_color_override("font_color")


func update_navigation_buttons() -> void:
	back_button.disabled = (navigation_index == 0)
	forward_button.disabled = (navigation_index == navigation_history.size() - 1)
	for btn: Button in [back_button, forward_button]:
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if btn.disabled else Control.CURSOR_POINTING_HAND

func _on_back_button_pressed() -> void:
	if navigation_index > 0:
		navigation_index -= 1
		open_dir(navigation_history[navigation_index], false)
		update_navigation_buttons()

func _on_forward_button_pressed() -> void:
	if navigation_index < navigation_history.size() - 1:
		navigation_index += 1
		open_dir(navigation_history[navigation_index], false)
		update_navigation_buttons()


func _on_path_field_text_submitted(new_text: String) -> void:
	new_text = new_text.replace("~", Utils.get_home_dir())
	if new_text == current_dir:
		return
	dir_cursor = DirAccess.open(new_text)
	if is_instance_valid(dir_cursor):
		open_dir(new_text)
	else:
		path_field.text = Utils.simplify_file_path(current_dir)

func _on_path_field_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		path_field.hide()
		path_panel.show()
		path_edit_button.grab_focus(true)

func _on_path_edit_button_pressed() -> void:
	path_field.show()
	path_panel.hide()
	path_field.text = Utils.simplify_file_path(current_dir)
	path_field.grab_focus()


# Helpers

func _init() -> void:
	const arr: Array[OS.SystemDir] = [OS.SYSTEM_DIR_DCIM, OS.SYSTEM_DIR_DESKTOP,
			OS.SYSTEM_DIR_DOCUMENTS, OS.SYSTEM_DIR_DOWNLOADS, OS.SYSTEM_DIR_MOVIES,
			OS.SYSTEM_DIR_MUSIC, OS.SYSTEM_DIR_PICTURES, OS.SYSTEM_DIR_RINGTONES]
	for enum_value in arr:
		system_dir_paths[enum_value] = OS.get_system_dir(enum_value)

var system_dir_paths: Dictionary[OS.SystemDir, String] = {}

func get_drive_icon(path: String) -> Texture2D:
	if path == system_dir_paths[OS.SYSTEM_DIR_DESKTOP]:
		return preload("res://assets/icons/DirDesktop.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_DOCUMENTS]:
		return preload("res://assets/icons/DirDocuments.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_DOWNLOADS]:
		return preload("res://assets/icons/DirDownloads.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_MOVIES]:
		return preload("res://assets/icons/DirMovies.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_MUSIC]:
		return preload("res://assets/icons/DirMusic.svg")
	elif path == system_dir_paths[OS.SYSTEM_DIR_PICTURES]:
		return preload("res://assets/icons/DirPictures.svg")
	else:
		return folder_icon
