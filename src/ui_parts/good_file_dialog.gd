## A fallback file dialog for if the native file dialog is not available.
extends PanelContainer

const AlertDialog = preload("res://src/ui_parts/alert_dialog.tscn")

signal file_selected(path: String)

const folder_icon = preload("res://visual/icons/Folder.svg")
const system_dir_icons = {
	OS.SYSTEM_DIR_DESKTOP: preload("res://visual/icons/DirDesktop.svg"),
	OS.SYSTEM_DIR_DOCUMENTS: preload("res://visual/icons/DirDocuments.svg"),
	OS.SYSTEM_DIR_DOWNLOADS: preload("res://visual/icons/DirDownloads.svg"),
	OS.SYSTEM_DIR_MOVIES: preload("res://visual/icons/DirMovies.svg"),
	OS.SYSTEM_DIR_MUSIC: preload("res://visual/icons/DirMusic.svg"),
	OS.SYSTEM_DIR_PICTURES: preload("res://visual/icons/DirPictures.svg"),
}

var item_height := 16

enum FileMode {SELECT, SAVE}
var mode: FileMode

var current_dir: String
var current_file := ""
var default_file := ""
var extension := ""

var search_text := ""

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
@onready var system_dir_list: ItemList = %SystemDirList
@onready var file_list: ItemList = %FileList
@onready var folder_up_button: Button = %FolderUpButton
@onready var refresh_button: Button = %RefreshButton
@onready var show_hidden_button: Button = %ShowHiddenButton
@onready var search_button: Button = %SearchButton

@onready var center_container: CenterContainer = $CenterContainer
@onready var alert_title_label: Label = %AlertTitleLabel
@onready var alert_label: RichTextLabel = %AlertLabel
@onready var alert_cancel_button: Button = %AlertCancelButton
@onready var alert_replace_button: Button = %AlertReplaceButton


class Actions:
	var activation_action: Callable
	var selection_action: Callable
	
	func _init(on_activation := Callable(), on_selection := Callable()) -> void:
		activation_action = on_activation
		selection_action = on_selection

func call_activation_action(actions: Actions) -> void:
	if actions != null and not actions.activation_action.is_null():
		actions.activation_action.call()

func call_selection_action(actions: Actions) -> void:
	if actions != null and not actions.selection_action.is_null():
		actions.selection_action.call()


func setup(new_dir: String, new_file: String, new_mode: FileMode,
new_extension: String) -> void:
	current_dir = new_dir
	current_file = new_file
	if new_mode == FileMode.SAVE:
		default_file = new_file
	mode = new_mode
	extension = new_extension

func _ready() -> void:
	file_list.get_v_scroll_bar().value_changed.connect(_setup_file_images.unbind(1))
	if mode == FileMode.SELECT:
		file_container.hide()
	if mode == FileMode.SAVE:
		alert_title_label.text = tr("Alert!")
		alert_cancel_button.text = tr("Cancel")
		alert_replace_button.text = tr("Replace")
	var extension_panel_stylebox := extension_panel.get_theme_stylebox("panel")
	extension_panel_stylebox.content_margin_top -= 4
	extension_panel.add_theme_stylebox_override("panel", extension_panel_stylebox)
	if GlobalSettings.save_data.file_dialog_show_hidden:
		show_hidden_button.set_pressed_no_signal(true)
	folder_up_button.tooltip_text = tr("Go to parent folder")
	refresh_button.tooltip_text = tr("Refresh files")
	show_hidden_button.tooltip_text = tr("Toggle the visibility of hidden files")
	search_button.tooltip_text = tr("Search files")
	
	title_label.text = tr("Select an SVG") if mode == FileMode.SELECT else tr("Save SVG")
	close_button.text = tr("Close")
	special_button.text = tr("Select") if mode == FileMode.SELECT else tr("Save")
	path_label.text = tr("Path") + ":"
	extension_label.text = "." + extension
	
	# Should always be safe.
	set_dir(current_dir)
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

func file_sort(file1: String, file2: String) -> bool:
	return file1.naturalnocasecmp_to(file2) == -1

# This function requires a safe input.
func set_dir(dir: String) -> void:
	file_list.clear()
	# Basic setup.
	current_dir = dir
	path_field.text = current_dir
	# Rebuild the system dirs to see if we now need to highlight the relevant one.
	system_dir_list.clear()
	for sysdir in [OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_DOCUMENTS, OS.SYSTEM_DIR_DOWNLOADS,
	OS.SYSTEM_DIR_MOVIES, OS.SYSTEM_DIR_MUSIC, OS.SYSTEM_DIR_PICTURES]:
		var dir_string := OS.get_system_dir(sysdir)
		if dir_string.is_empty():
			continue
		
		var item_idx := system_dir_list.add_item(dir_string.get_file(),
				system_dir_icons[sysdir] if sysdir in system_dir_icons else folder_icon)
		system_dir_list.set_item_metadata(item_idx,
				Actions.new(Callable(), enter_dir.bind(dir_string)))
		if current_dir == dir_string:
			system_dir_list.select(item_idx)
	# Create the DirAccess object.
	var DA := DirAccess.open(dir)
	DA.include_hidden = GlobalSettings.save_data.file_dialog_show_hidden
	# Gather the files and directories.
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
		file_list.set_item_metadata(item_idx,
				Actions.new(enter_dir.bind(current_dir.path_join(directory)), unfocus_file))
	
	for file in files:
		if file.get_extension() != extension or\
		(not search_text.is_empty() and not search_text.is_subsequence_ofn(file)):
			continue
		
		var item_idx := file_list.add_item(file, null)
		file_list.set_item_metadata(item_idx,
				Actions.new(select_file, focus_file.bind(file)))
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
	if not file.is_empty():
		if file.get_extension() != extension:
			file += "." + extension
	file_list.ensure_current_is_visible()
	current_file = file
	file_field.text = current_file

# For optimization, only generate the visible files' images.
func _setup_file_images() -> void:
	var visible_start := file_list.position.y + file_list.get_v_scroll_bar().value
	var visible_end := visible_start + file_list.size.y
	for item_idx in file_list.item_count:
		var file_rect := file_list.get_item_rect(item_idx)
		if file_list.get_item_icon(item_idx) == null and\
		file_rect.end.y > visible_start and file_rect.position.y < visible_end:
			var file := file_list.get_item_text(item_idx)
			match file.get_extension():
				"png":
					file_list.set_item_icon(item_idx, ImageTexture.create_from_image(
							Image.load_from_file(current_dir.path_join(file))))
				"svg":
					# Setup a clean SVG graphic by using the scaling parameter.
					var svg_text := FileAccess.open(current_dir.path_join(file),
							FileAccess.READ).get_as_text()
					var img := Image.new()
					img.load_svg_from_string(svg_text)
					img.load_svg_from_string(svg_text,
							item_height / maxf(img.get_width(), img.get_height()))
					file_list.set_item_icon(item_idx, ImageTexture.create_from_image(img))


func select_file() -> void:
	if mode == FileMode.SAVE and current_file in DirAccess.get_files_at(current_dir):
		alert_label.text = tr("A file named \"{file_name}\" already exists. Replacing will overwrite its contents!").format({"file_name": current_file})
		center_container.show()
		alert_replace_button.grab_focus()
	else:
		file_selected.emit(current_dir.path_join(current_file))

func focus_file(path: String) -> void:
	set_file(path.get_file())

func unfocus_file() -> void:
	set_file(default_file)

func _on_folder_up_button_pressed() -> void:
	set_dir(current_dir.get_base_dir())

func _on_file_list_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	file_list.deselect_all()
	unfocus_file()

func _on_system_dir_list_empty_clicked(_at_position: Vector2,
_mouse_button_index: int) -> void:
	system_dir_list.deselect_all()

func _on_file_list_item_activated(index: int) -> void:
	call_activation_action(file_list.get_item_metadata(index))

func _on_file_list_item_selected(index: int) -> void:
	call_selection_action(file_list.get_item_metadata(index))

func _on_system_dir_list_item_selected(index: int) -> void:
	call_selection_action(system_dir_list.get_item_metadata(index))

func _on_refresh_button_pressed() -> void:
	set_dir(current_dir)

func _on_show_hidden_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data("file_dialog_show_hidden", toggled_on)
	set_dir(current_dir)

func _on_search_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		search_field.show()
		search_field.grab_focus()
	else:
		search_field.hide()
		search_text = ""
		set_dir(current_dir)


func _on_close_button_pressed() -> void:
	queue_free()

func _on_file_selected(_path: String) -> void:
	queue_free()

func _on_special_button_pressed() -> void:
	select_file()

func _on_file_field_text_submitted(new_text: String) -> void:
	file_field.remove_theme_color_override("font_color")
	if new_text.is_valid_filename():
		current_file = new_text
	else:
		file_field.text = current_file

func _on_path_field_text_submitted(new_text: String) -> void:
	var DA := DirAccess.open(new_text)
	if DA != null:
		set_dir(new_text)
	else:
		path_field.text = current_dir

func _on_search_field_text_changed(new_text: String) -> void:
	search_text = new_text
	set_dir(current_dir)

func _on_search_field_text_change_canceled() -> void:
	search_field.text = search_text

func _on_file_field_text_changed(new_text: String) -> void:
	file_field.add_theme_color_override("font_color",
			GlobalSettings.get_validity_color(!new_text.is_valid_filename()))


func _on_alert_cancel_button_pressed() -> void:
	center_container.hide()

func _on_alert_replace_button_pressed() -> void:
	file_selected.emit(current_dir.path_join(current_file))
