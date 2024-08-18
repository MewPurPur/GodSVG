extends PanelContainer

signal layout_changed

const SettingFrame = preload("res://src/ui_widgets/setting_frame.tscn")

var current_formatter: Formatter
var currently_edited_idx := -1

@onready var formatter_button: Button = %MainContainer/HBoxContainer/FormatterButton
@onready var name_edit: BetterLineEdit = %MainContainer/HBoxContainer/NameEdit
@onready var configs_container: VBoxContainer = %MainContainer/ConfigsContainer

func setup_theme() -> void:
	for theming in ["normal", "hover", "pressed"]:
		var stylebox := formatter_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_top -= 3
		stylebox.content_margin_bottom -= 2
		stylebox.content_margin_left += 1
		formatter_button.add_theme_stylebox_override(theming, stylebox)
	var panel_stylebox := get_theme_stylebox("panel").duplicate()
	panel_stylebox.content_margin_top = panel_stylebox.content_margin_bottom
	add_theme_stylebox_override("panel", panel_stylebox)

func _ready() -> void:
	formatter_button.pressed.connect(_on_formatter_button_pressed)
	name_edit.text_change_canceled.connect(_on_name_edit_text_change_canceled)
	name_edit.text_changed.connect(_on_name_edit_text_changed)
	name_edit.text_submitted.connect(_on_name_edit_text_submitted)
	GlobalSettings.theme_changed.connect(setup_theme)
	setup_theme()
	construct()


func _on_formatter_button_pressed() -> void:
	var formatter_idx := -1
	for idx in GlobalSettings.savedata.formatters.size():
		if GlobalSettings.savedata.formatters[idx].title == current_formatter.title:
			formatter_idx = idx
	
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Rename"),
			popup_edit_name, false, load("res://visual/icons/Rename.svg")))
	btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Delete"),
			delete.bind(formatter_idx), GlobalSettings.savedata.formatters.size() > 1,
			load("res://visual/icons/Delete.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, formatter_button.get_global_rect(),
			get_viewport())


func popup_edit_name() -> void:
	formatter_button.hide()
	name_edit.show()
	name_edit.text = current_formatter.title
	name_edit.grab_focus()
	name_edit.caret_column = name_edit.text.length()

func hide_name_edit() -> void:
	formatter_button.show()
	name_edit.hide()


func delete(idx: int) -> void:
	GlobalSettings.savedata.formatters.remove_at(idx)
	GlobalSettings.save()
	layout_changed.emit()


var current_setup_config: String


func construct() -> void:
	set_label_text(current_formatter.title)
	add_section("XML")
	current_setup_config = "xml_add_trailing_newline"
	add_checkbox(TranslationServer.translate("Add trailing newline"))
	current_setup_config = "xml_shorthand_tags"
	add_dropdown(TranslationServer.translate("Use shorthand tag syntax"))
	current_setup_config = "xml_shorthand_tags_space_out_slash"
	add_checkbox(TranslationServer.translate("Space out the slash of shorthand tags"))
	current_setup_config = "xml_pretty_formatting"
	add_checkbox(TranslationServer.translate("Use pretty formatting"))
	current_setup_config = "xml_indentation_use_spaces"
	add_checkbox(TranslationServer.translate("Use spaces instead of tabs"))
	current_setup_config = "xml_indentation_spaces"
	add_number_dropdown(TranslationServer.translate("Number of indentation spaces"),
			[2, 3, 4, 6, 8], true, false, 0, 16)
	
	add_section(TranslationServer.translate("Numbers"))
	current_setup_config = "number_remove_leading_zero"
	add_checkbox(TranslationServer.translate("Remove leading zero"))
	current_setup_config = "number_use_exponent_if_shorter"
	add_checkbox(TranslationServer.translate("Use exponential when shorter"))
	
	add_section(TranslationServer.translate("Colors"))
	current_setup_config = "color_use_named_colors"
	add_dropdown(TranslationServer.translate("Use named colors"))
	current_setup_config = "color_primary_syntax"
	add_dropdown(TranslationServer.translate("Primary syntax"))
	current_setup_config = "color_capital_hex"
	add_checkbox(TranslationServer.translate("Capitalize hexadecimal letters"))
	
	add_section(TranslationServer.translate("Pathdata"))
	current_setup_config = "pathdata_compress_numbers"
	add_checkbox(TranslationServer.translate("Compress numbers"))
	current_setup_config = "pathdata_minimize_spacing"
	add_checkbox(TranslationServer.translate("Minimize spacing"))
	current_setup_config = "pathdata_remove_spacing_after_flags"
	add_checkbox(TranslationServer.translate("Remove spacing after flags"))
	current_setup_config = "pathdata_remove_consecutive_commands"
	add_checkbox(TranslationServer.translate("Remove consecutive commands"))
	
	add_section(TranslationServer.translate("Transform lists"))
	current_setup_config = "transform_list_compress_numbers"
	add_checkbox(TranslationServer.translate("Compress numbers"))
	current_setup_config = "transform_list_minimize_spacing"
	add_checkbox(TranslationServer.translate("Minimize spacing"))
	current_setup_config = "transform_list_remove_unnecessary_params"
	add_checkbox(TranslationServer.translate("Remove unnecessary parameters"))


func add_section(section_name: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	var label := Label.new()
	label.text = section_name
	vbox.add_child(label)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2
	vbox.add_child(spacer)
	configs_container.add_child(vbox)

func add_checkbox(text: String) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_checkbox()
	add_frame(frame)
	return frame

func add_dropdown(text: String) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_dropdown(current_formatter.get_enum_texts(current_setup_config))
	add_frame(frame)
	return frame

func add_number_dropdown(text: String, values: Array[float], is_integer := false,
restricted := true, min_value := -INF, max_value := INF) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_number_dropdown(values, is_integer, restricted, min_value, max_value)
	add_frame(frame)
	return frame

func setup_frame(frame: Control) -> void:
	frame.getter = current_formatter.get.bind(current_setup_config)
	var bind := current_setup_config
	frame.setter = func(p): current_formatter.set(bind, p)
	frame.default = Formatter.new().get(current_setup_config)

func add_frame(frame: Control) -> void:
	configs_container.get_child(-1).add_child(frame)


# Update text color to red if the title won't work (because it's a duplicate).
func _on_name_edit_text_changed(new_text: String) -> void:
	var names: Array[String] = []
	for formatter in GlobalSettings.savedata.formatters:
		names.append(formatter.title)
	name_edit.add_theme_color_override("font_color", GlobalSettings.get_validity_color(
			new_text in names and new_text != current_formatter.title))

func _on_name_edit_text_submitted(new_title: String) -> void:
	new_title = new_title.strip_edges()
	var titles: Array[String] = []
	for formatter in GlobalSettings.savedata.formatters:
		titles.append(formatter.title)
	
	if not new_title.is_empty() and new_title != current_formatter.title and\
	not new_title in titles:
		current_formatter.title = new_title
	
	set_label_text(current_formatter.title)
	hide_name_edit()

func _on_name_edit_text_change_canceled() -> void:
	hide_name_edit()


func set_label_text(new_text: String) -> void:
	if new_text.is_empty():
		formatter_button.text = TranslationServer.translate("Unnamed")
		formatter_button.add_theme_color_override("font_color",
				GlobalSettings.savedata.basic_color_error)
	else:
		formatter_button.text = new_text
		formatter_button.remove_theme_color_override("font_color")
