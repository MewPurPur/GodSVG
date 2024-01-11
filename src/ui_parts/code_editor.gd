extends VBoxContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const autoformat_menu = preload("res://src/ui_parts/autoformat_menu.tscn")

@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var size_label: Label = %SizeLabel
@onready var file_button: Button = %FileButton

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	update_size_label()
	update_file_button()
	setup_theme(false)
	code_edit.clear_undo_history()
	SVG.root_tag.attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.tag_layout_changed.connect(auto_update_text)
	SVG.root_tag.changed_unknown.connect(auto_update_text)
	GlobalSettings.save_data.current_file_path_changed.connect(update_file_button)

func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.text
		code_edit.clear_undo_history()
	update_size_label()

func update_error(err_id: StringName) -> void:
	if err_id == &"":
		if error_bar.visible:
			error_bar.hide()
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y += error_bar_real_height
			code_edit.size.y += error_bar_real_height
			setup_theme(false)
	else:
		# When the error is shown, the code editor's theme is changed to match up.
		if not error_bar.visible:
			error_bar.show()
			error_label.text = tr(err_id)
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y -= error_bar_real_height
			code_edit.size.y -= error_bar_real_height
			setup_theme(true)

func setup_theme(match_below: bool) -> void:
	code_edit.begin_bulk_theme_override()
	for theming in [&"normal", &"focus"]:
		var stylebox := ThemeDB.get_project_theme().\
				get_stylebox(theming, &"TextEdit").duplicate()
		stylebox.corner_radius_top_right = 0
		stylebox.corner_radius_top_left = 0
		stylebox.border_width_top = 1
		if match_below:
			stylebox.corner_radius_bottom_right = 0
			stylebox.corner_radius_bottom_left = 0
			stylebox.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(theming, stylebox)
	code_edit.end_bulk_theme_override()


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)


func _on_import_button_pressed() -> void:
	SVG.open_import_dialog()

func _on_export_button_pressed() -> void:
	SVG.open_export_dialog()

func set_new_text(svg_text: String) -> void:
	code_edit.text = svg_text
	_on_code_edit_text_changed()  # Call it automatically yeah.


func _on_code_edit_text_changed() -> void:
	SVG.text = code_edit.text
	SVG.update_tags()


func _input(event: InputEvent) -> void:
	if (code_edit.has_focus() and event is InputEventMouseButton and\
	not code_edit.get_global_rect().has_point(event.position)):
		code_edit.release_focus()


func update_size_label() -> void:
	size_label.text = String.humanize_size(code_edit.text.length())

func update_file_button() -> void:
	var file_path := GlobalSettings.save_data.current_file_path
	file_button.visible = !file_path.is_empty()
	file_button.text = file_path.get_file()

func _on_svg_code_edit_focus_exited() -> void:
	code_edit.text = SVG.text
	if GlobalSettings.save_data.svg_text != code_edit.text:
		SVG.update_text(true)


func _on_autoformat_button_pressed() -> void:
	var autoformat_menu_instance := autoformat_menu.instantiate()
	HandlerGUI.add_overlay(autoformat_menu_instance)

func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = [Utils.create_btn(tr(&"#clear"), clear_file_path)]
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_array, false, file_button.size.x)
	Utils.popup_under_control_centered(context_popup, file_button)

func clear_file_path() -> void:
	GlobalSettings.modify_save_data(&"current_file_path", "")
