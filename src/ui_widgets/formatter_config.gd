extends PanelContainer

const SettingFrame = preload("res://src/ui_widgets/setting_frame.tscn")
const ProfileFrame = preload("res://src/ui_widgets/profile_frame.tscn")

var current_formatter: Formatter

@onready var formatter_button: Button = %MainContainer/FormatterButton
@onready var configs_container: VBoxContainer = %MainContainer/ConfigsContainer

func setup_theme() -> void:
	formatter_button.begin_bulk_theme_override()
	for theming in ["normal", "hover", "pressed"]:
		var stylebox := formatter_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_top -= 3
		stylebox.content_margin_bottom -= 2
		stylebox.content_margin_left += 1
		formatter_button.add_theme_stylebox_override(theming, stylebox)
	formatter_button.end_bulk_theme_override()
	var panel_stylebox := get_theme_stylebox("panel").duplicate()
	panel_stylebox.content_margin_top = panel_stylebox.content_margin_bottom
	add_theme_stylebox_override("panel", panel_stylebox)

func _ready() -> void:
	formatter_button.pressed.connect(_on_formatter_button_pressed)
	Configs.theme_changed.connect(setup_theme)
	setup_theme()
	construct()


func _on_formatter_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(
			Translator.translate("Reset to default"),
			current_formatter.reset_to_default, current_formatter.is_everything_default(),
			load("res://visual/icons/Reload.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, formatter_button.get_global_rect(),
			get_viewport())


var current_setup_config: String

func construct() -> void:
	if current_formatter == Configs.savedata.editor_formatter:
		set_label_text(Translator.translate("Editor formatter"))
	else:
		set_label_text(Translator.translate("Export formatter"))
	
	# The preset field shouldn't have a reset button or a section, so set it up manually.
	var frame := ProfileFrame.instantiate()
	frame.setup_dropdown(true)
	frame.getter = current_formatter.get.bind("preset")
	frame.setter = func(p): current_formatter.set("preset", p)
	frame.text = Translator.translate("Preset")
	frame.dropdown.values = Formatter.get_enum_texts("preset")
	configs_container.add_child(frame)
	
	add_section("XML")
	current_setup_config = "xml_keep_comments"
	add_checkbox(Translator.translate("Keep comments"))
	current_setup_config = "xml_keep_unrecognized"
	add_checkbox(Translator.translate("Keep unrecognized XML structures"))
	current_setup_config = "xml_add_trailing_newline"
	add_checkbox(Translator.translate("Add trailing newline"))
	current_setup_config = "xml_shorthand_tags"
	add_dropdown(Translator.translate("Use shorthand tag syntax"))
	current_setup_config = "xml_shorthand_tags_space_out_slash"
	add_checkbox(Translator.translate("Space out the slash of shorthand tags"))
	current_setup_config = "xml_pretty_formatting"
	add_checkbox(Translator.translate("Use pretty formatting"))
	current_setup_config = "xml_indentation_use_spaces"
	add_checkbox(Translator.translate("Use spaces instead of tabs"),
			not current_formatter.xml_pretty_formatting)
	current_setup_config = "xml_indentation_spaces"
	add_number_dropdown(Translator.translate("Number of indentation spaces"),
			[2, 3, 4, 6, 8], true, false, 0, 16, not current_formatter.xml_pretty_formatting)
	
	add_section(Translator.translate("Numbers"))
	current_setup_config = "number_remove_leading_zero"
	add_checkbox(Translator.translate("Remove leading zero"))
	current_setup_config = "number_use_exponent_if_shorter"
	add_checkbox(Translator.translate("Use exponential when shorter"))
	
	add_section(Translator.translate("Colors"))
	current_setup_config = "color_use_named_colors"
	add_dropdown(Translator.translate("Use named colors"))
	current_setup_config = "color_primary_syntax"
	add_dropdown(Translator.translate("Primary syntax"))
	current_setup_config = "color_capital_hex"
	add_checkbox(Translator.translate("Capitalize hexadecimal letters"),
			current_formatter.color_primary_syntax == Formatter.PrimaryColorSyntax.RGB)
	
	add_section(Translator.translate("Pathdata"))
	current_setup_config = "pathdata_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	current_setup_config = "pathdata_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	current_setup_config = "pathdata_remove_spacing_after_flags"
	add_checkbox(Translator.translate("Remove spacing after flags"))
	current_setup_config = "pathdata_remove_consecutive_commands"
	add_checkbox(Translator.translate("Remove consecutive commands"))
	
	add_section(Translator.translate("Transform lists"))
	current_setup_config = "transform_list_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	current_setup_config = "transform_list_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	current_setup_config = "transform_list_remove_unnecessary_params"
	add_checkbox(Translator.translate("Remove unnecessary parameters"))


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

func add_checkbox(text: String, dim_text := false) -> void:
	var frame := SettingFrame.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_checkbox()
	add_frame(frame)

func add_dropdown(text: String) -> void:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_dropdown(Formatter.get_enum_texts(current_setup_config))
	add_frame(frame)

func add_number_dropdown(text: String, values: PackedFloat64Array, is_integer := false,
restricted := true, min_value := -INF, max_value := INF, dim_text := false) -> void:
	var frame := SettingFrame.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_number_dropdown(values, is_integer, restricted, min_value, max_value)
	add_frame(frame)

func setup_frame(frame: Control) -> void:
	frame.getter = current_formatter.get.bind(current_setup_config)
	var bind := current_setup_config
	frame.setter = func(p): current_formatter.set(bind, p)
	frame.default = current_formatter.get_setting_default(current_setup_config)

func add_frame(frame: Control) -> void:
	configs_container.get_child(-1).add_child(frame)



func set_label_text(new_text: String) -> void:
	formatter_button.begin_bulk_theme_override()
	if new_text.is_empty():
		formatter_button.text = Translator.translate("Unnamed")
		for style_name in ["font_color", "font_hover_color", "font_pressed_color"]:
			formatter_button.add_theme_color_override(style_name,
					Configs.savedata.theme_config.basic_color_error)
	else:
		formatter_button.text = new_text
		for style_name in ["font_color", "font_hover_color", "font_pressed_color"]:
			formatter_button.remove_theme_color_override(style_name)
	formatter_button.end_bulk_theme_override()
