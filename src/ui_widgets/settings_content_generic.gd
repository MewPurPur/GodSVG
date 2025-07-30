extends VBoxContainer

const SettingsMenu = preload("res://src/ui_parts/settings_menu.gd")

const SettingFrameScene = preload("res://src/ui_widgets/setting_frame.tscn")
const ProfileFrameScene = preload("res://src/ui_widgets/profile_frame.tscn")

# If there are multiple setup resources, they will be added as tabs.
var current_setup_resources: Array[ConfigResource]
var type: SettingsMenu.TabIndex

var current_setup_setting := ""
var current_setup_resource_index := 0
var setting_container: VBoxContainer
var previews: Dictionary[String, RefCounted] = {}


var current_previewed_setting := ""
signal preview_changed(node: Control)

class SettingBasicColorPreview:
	var setting_bind: String
	var text: String
	func _init(new_setting_bind: String, new_text: String) -> void:
		setting_bind = new_setting_bind
		text = new_text

class SettingTextPreview:
	enum WarningType {NONE, NO_EFFECT_IN_CURRENT_CONFIGURATION, NOT_AVAILABLE_ON_PLATFORM}
	var text: String
	var warning: WarningType
	func _init(new_text: String, new_warning := WarningType.NONE) -> void:
		text = new_text
		warning = new_warning
	
	static func get_platform_availability_warning(bad_platforms_check: bool) -> WarningType:
		return WarningType.NOT_AVAILABLE_ON_PLATFORM if bad_platforms_check else WarningType.NONE
	
	static func get_no_effect_in_configuration_warning(configuration_check: bool) -> WarningType:
		return WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION if configuration_check else WarningType.NONE

class SettingCodePreview:
	var text: String
	func _init(new_text: String) -> void:
		text = new_text

class SettingFormatterPreview:
	var resource_bind: Formatter
	var root_element: ElementRoot
	var show_only_children: bool
	func _init(new_resource_bind: ConfigResource,
	new_root_element: ElementRoot, new_show_only_children := false) -> void:
		resource_bind = new_resource_bind
		root_element = new_root_element
		show_only_children = new_show_only_children


func _ready() -> void:
	Configs.language_changed.connect(setup_content)
	if current_setup_resources.size() > 1:
		var categories := HFlowContainer.new()
		categories.alignment = FlowContainer.ALIGNMENT_CENTER
		var button_group := ButtonGroup.new()
		for idx in current_setup_resources.size():
			var btn := Button.new()
			btn.toggle_mode = true
			btn.button_group = button_group
			btn.pressed.connect(_set_current_setup_resource_index.bind(idx))
			btn.pressed.connect(setup_content)
			var update_category_button_text := func() -> void:
					btn.text = Translator.translate("Editor formatter") if\
							current_setup_resource_index == 0 else\
							Translator.translate("Export formatter")
			Configs.language_changed.connect(update_category_button_text)
			update_category_button_text.call()
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.focus_mode = Control.FOCUS_NONE
			btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			categories.add_child(btn)
		add_child(categories)
		setting_container = VBoxContainer.new()
		setting_container.add_theme_constant_override("separation", 6)
		add_child(setting_container)
		categories.get_child(0).button_pressed = true
		setup_content()
	else:
		setting_container = VBoxContainer.new()
		setting_container.add_theme_constant_override("separation", 6)
		add_child(setting_container)
		setup_content()

func _get_current_setup_resource() -> ConfigResource:
	return current_setup_resources[current_setup_resource_index]

func _set_current_setup_resource_index(new_index: int) -> void:
	current_setup_resource_index = new_index

func setup(setup_resources: Array[ConfigResource], new_type: SettingsMenu.TabIndex) -> void:
	type = new_type
	current_setup_resources = setup_resources


func setup_content() -> void:
	for child in setting_container.get_children():
		setting_container.remove_child(child)
		child.queue_free()
	
	match type:
		SettingsMenu.TabIndex.FORMATTING: setup_formatting_content()
		SettingsMenu.TabIndex.THEMING: setup_theming_content()
		SettingsMenu.TabIndex.TAB_BAR: setup_tab_bar_content()
		SettingsMenu.TabIndex.OTHER: setup_other_content()

func setup_formatting_content() -> void:
	var current_setup_resource: Formatter = _get_current_setup_resource()
	
	current_setup_setting = "preset"
	add_profile_picker(Translator.translate("Preset"),
			current_setup_resource.reset_to_default, Formatter.Preset.size(),
			Formatter.get_preset_value_text_map(), current_setup_resource.is_everything_default)
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the default values of the formatter configs.")))
	
	add_section("XML")
	current_setup_setting = "xml_keep_comments"
	add_checkbox(Translator.translate("Keep comments"))
	var xml_keep_comments_root_element := ElementRoot.new()
	xml_keep_comments_root_element.insert_child(0,
			BasicXNode.new(BasicXNode.NodeType.COMMENT, " Comment "))
	var xml_keep_comments_circle_element := ElementCircle.new()
	xml_keep_comments_circle_element.set_attribute("cx", 6)
	xml_keep_comments_circle_element.set_attribute("cy", 8)
	xml_keep_comments_circle_element.set_attribute("r", 4)
	xml_keep_comments_circle_element.set_attribute("fill", "gold")
	xml_keep_comments_root_element.insert_child(1, xml_keep_comments_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			xml_keep_comments_root_element, true))
	
	current_setup_setting = "xml_add_trailing_newline"
	add_checkbox(Translator.translate("Add trailing newline"))
	var xml_add_trailing_newline_root_element := ElementRoot.new()
	xml_add_trailing_newline_root_element.set_attribute("xmlns", "http://www.w3.org/2000/svg")
	xml_add_trailing_newline_root_element.set_attribute("width", "16")
	xml_add_trailing_newline_root_element.set_attribute("height", "16")
	var xml_add_trailing_newline_circle_element := ElementCircle.new()
	xml_add_trailing_newline_circle_element.set_attribute("cx", 6)
	xml_add_trailing_newline_circle_element.set_attribute("cy", 8)
	xml_add_trailing_newline_circle_element.set_attribute("r", 4)
	xml_add_trailing_newline_circle_element.set_attribute("fill", "gold")
	xml_add_trailing_newline_root_element.insert_child(0,
			xml_add_trailing_newline_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			xml_add_trailing_newline_root_element))
	
	current_setup_setting = "xml_shorthand_tags"
	add_dropdown(Translator.translate("Use shorthand tag syntax"),
			range(Formatter.ShorthandTags.size()),
			Formatter.get_shorthand_tags_value_text_map())
	var xml_shorthand_tags_root_element := ElementRoot.new()
	var xml_shorthand_tags_linear_gradient_element := ElementLinearGradient.new()
	xml_shorthand_tags_linear_gradient_element.set_attribute("id", "a")
	xml_shorthand_tags_linear_gradient_element.set_attribute("x1", 6)
	xml_shorthand_tags_linear_gradient_element.set_attribute("y1", 4)
	xml_shorthand_tags_linear_gradient_element.set_attribute("x2", 8)
	xml_shorthand_tags_linear_gradient_element.set_attribute("y2", 2)
	var xml_shorthand_tags_circle_element := ElementCircle.new()
	xml_shorthand_tags_circle_element.set_attribute("cx", 6)
	xml_shorthand_tags_circle_element.set_attribute("cy", 8)
	xml_shorthand_tags_circle_element.set_attribute("r", 4)
	xml_shorthand_tags_circle_element.set_attribute("fill", "url(#a)")
	xml_shorthand_tags_root_element.insert_child(0, xml_shorthand_tags_linear_gradient_element)
	xml_shorthand_tags_root_element.insert_child(1, xml_shorthand_tags_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			xml_shorthand_tags_root_element, true))
	
	current_setup_setting = "xml_shorthand_tags_space_out_slash"
	add_checkbox(Translator.translate("Space out the slash of shorthand tags"))
	var xml_shorthand_tags_space_out_slash_root_element := ElementRoot.new()
	var xml_shorthand_tags_space_out_slash_circle_element := ElementCircle.new()
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("cx", 6)
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("cy", 8)
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("r", 4)
	xml_shorthand_tags_space_out_slash_root_element.insert_child(0,
			xml_shorthand_tags_space_out_slash_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			xml_shorthand_tags_space_out_slash_root_element, true))
	
	current_setup_setting = "xml_pretty_formatting"
	add_checkbox(Translator.translate("Use pretty formatting"))
	var xml_pretty_formatting_root_element := ElementRoot.new()
	var xml_pretty_formatting_linear_gradient_element := ElementLinearGradient.new()
	xml_pretty_formatting_linear_gradient_element.set_attribute("id", "a")
	xml_pretty_formatting_linear_gradient_element.set_attribute("x1", 6)
	xml_pretty_formatting_linear_gradient_element.set_attribute("y1", 4)
	xml_pretty_formatting_linear_gradient_element.set_attribute("x2", 8)
	xml_pretty_formatting_linear_gradient_element.set_attribute("y2", 2)
	var xml_pretty_formatting_stop_1 := ElementStop.new()
	xml_pretty_formatting_stop_1.set_attribute("stop-color", "silver")
	xml_pretty_formatting_stop_1.set_attribute("offset", "0")
	var xml_pretty_formatting_stop_2 := ElementStop.new()
	xml_pretty_formatting_stop_2.set_attribute("stop-color", "gold")
	xml_pretty_formatting_stop_2.set_attribute("offset", "1")
	xml_pretty_formatting_linear_gradient_element.insert_child(0, xml_pretty_formatting_stop_1)
	xml_pretty_formatting_linear_gradient_element.insert_child(0, xml_pretty_formatting_stop_2)
	var xml_pretty_formatting_circle_element := ElementCircle.new()
	xml_pretty_formatting_circle_element.set_attribute("cx", 6)
	xml_pretty_formatting_circle_element.set_attribute("cy", 8)
	xml_pretty_formatting_circle_element.set_attribute("r", 4)
	xml_pretty_formatting_circle_element.set_attribute("fill", "url(#a)")
	xml_pretty_formatting_root_element.insert_child(0, xml_pretty_formatting_linear_gradient_element)
	xml_pretty_formatting_root_element.insert_child(1, xml_pretty_formatting_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			xml_pretty_formatting_root_element))
	
	current_setup_setting = "xml_indentation_use_spaces"
	add_checkbox(Translator.translate("Use spaces instead of tabs"),
			not current_setup_resource.xml_pretty_formatting)
	add_preview(SettingTextPreview.new(Translator.translate(
			"When enabled, uses spaces instead of a single tab for indentation."),
			SettingTextPreview.get_no_effect_in_configuration_warning(
			not current_setup_resource.xml_pretty_formatting)))
	
	current_setup_setting = "xml_indentation_spaces"
	add_number_dropdown(Translator.translate("Number of indentation spaces"),
			[2, 3, 4, 6, 8], true, false, Formatter.INDENTS_MIN, Formatter.INDENTS_MAX,
			not (current_setup_resource.xml_pretty_formatting and\
			current_setup_resource.xml_indentation_use_spaces))
	if current_setup_resource.xml_pretty_formatting and\
	current_setup_resource.xml_indentation_use_spaces:
		var xml_indentation_spaces_root_element := ElementRoot.new()
		var xml_indentation_spaces_circle_element := ElementCircle.new()
		xml_indentation_spaces_circle_element.set_attribute("cx", 6)
		xml_indentation_spaces_circle_element.set_attribute("cy", 8)
		xml_indentation_spaces_circle_element.set_attribute("r", 4)
		xml_indentation_spaces_circle_element.set_attribute("fill", "gold")
		xml_indentation_spaces_root_element.insert_child(0,
				xml_indentation_spaces_circle_element)
		add_preview(SettingFormatterPreview.new(current_setup_resource,
				xml_indentation_spaces_root_element, false))
	else:
		add_preview(SettingTextPreview.new("",
				SettingTextPreview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION))
	
	add_section(Translator.translate("Numbers"))
	current_setup_setting = "number_remove_leading_zero"
	add_checkbox(Translator.translate("Remove leading zero"))
	var number_remove_leading_zero_root_element := ElementRoot.new()
	var number_remove_leading_zero_circle_element := ElementCircle.new()
	number_remove_leading_zero_circle_element.set_attribute("cx", 0.36)
	number_remove_leading_zero_circle_element.set_attribute("cy", -0.8)
	number_remove_leading_zero_circle_element.set_attribute("r", 1.6)
	number_remove_leading_zero_circle_element.set_attribute("fill", "gold")
	number_remove_leading_zero_root_element.insert_child(0,
			number_remove_leading_zero_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			number_remove_leading_zero_root_element, true))
	
	current_setup_setting = "number_use_exponent_if_shorter"
	add_checkbox(Translator.translate("Use exponential when shorter"))
	var number_use_exponent_if_shorter_root_element := ElementRoot.new()
	var number_use_exponent_if_shorter_circle_element := ElementCircle.new()
	number_use_exponent_if_shorter_circle_element.set_attribute("cx", 800)
	number_use_exponent_if_shorter_circle_element.set_attribute("cy", -0.005)
	number_use_exponent_if_shorter_circle_element.set_attribute("r", 2000)
	number_use_exponent_if_shorter_circle_element.set_attribute("fill", "gold")
	number_use_exponent_if_shorter_root_element.insert_child(0,
			number_use_exponent_if_shorter_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			number_use_exponent_if_shorter_root_element, true))
	
	add_section(Translator.translate("Colors"))
	current_setup_setting = "color_use_named_colors"
	add_dropdown(Translator.translate("Use named colors"),
			range(Formatter.NamedColorUse.size()),
			Formatter.get_named_color_use_value_text_map())
	var color_use_named_colors_root_element := ElementRoot.new()
	var color_use_named_colors_circle_1 := ElementCircle.new()
	color_use_named_colors_circle_1.set_attribute("cx", 6)
	color_use_named_colors_circle_1.set_attribute("cy", 8)
	color_use_named_colors_circle_1.set_attribute("r", 4)
	color_use_named_colors_circle_1.set_attribute("fill", "gold")
	color_use_named_colors_circle_1.set_attribute("stroke", "crimson")
	color_use_named_colors_root_element.insert_child(0, color_use_named_colors_circle_1)
	var color_use_named_colors_circle_2 := ElementCircle.new()
	color_use_named_colors_circle_2.set_attribute("cx", 3)
	color_use_named_colors_circle_2.set_attribute("cy", 5)
	color_use_named_colors_circle_2.set_attribute("r", 2)
	color_use_named_colors_circle_2.set_attribute("fill", "turquoise")
	color_use_named_colors_root_element.insert_child(1, color_use_named_colors_circle_2)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			color_use_named_colors_root_element, true))
	
	current_setup_setting = "color_primary_syntax"
	add_dropdown(Translator.translate("Primary syntax"),
			range(Formatter.PrimaryColorSyntax.size()),
			Formatter.get_primary_color_syntax_value_text_map())
	var color_primary_syntax_root_element := ElementRoot.new()
	var color_primary_syntax_circle_element := ElementCircle.new()
	color_primary_syntax_circle_element.set_attribute("cx", 6)
	color_primary_syntax_circle_element.set_attribute("cy", 8)
	color_primary_syntax_circle_element.set_attribute("r", 4)
	color_primary_syntax_circle_element.set_attribute("fill", "#d4b")
	color_primary_syntax_circle_element.set_attribute("stroke", "#f4c4d3")
	color_primary_syntax_root_element.insert_child(0, color_primary_syntax_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			color_primary_syntax_root_element, true))
	
	current_setup_setting = "color_capital_hex"
	add_checkbox(Translator.translate("Capitalize hexadecimal letters"),
			current_setup_resource.color_primary_syntax == Formatter.PrimaryColorSyntax.RGB)
	if current_setup_resource.color_primary_syntax != Formatter.PrimaryColorSyntax.RGB:
		var color_capital_hex_root_element := ElementRoot.new()
		var color_capital_hex_circle_element := ElementCircle.new()
		color_capital_hex_circle_element.set_attribute("cx", 6)
		color_capital_hex_circle_element.set_attribute("cy", 8)
		color_capital_hex_circle_element.set_attribute("r", 4)
		color_capital_hex_circle_element.set_attribute("fill", "#decade")
		color_capital_hex_root_element.insert_child(0, color_capital_hex_circle_element)
		add_preview(SettingFormatterPreview.new(current_setup_resource,
				color_capital_hex_root_element, true))
	else:
		add_preview(SettingTextPreview.new("",
				SettingTextPreview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION))
	
	add_section(Translator.translate("Pathdata"))
	current_setup_setting = "pathdata_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	var pathdata_compress_numbers_root_element := ElementRoot.new()
	var pathdata_compress_numbers_path_element := ElementPath.new()
	pathdata_compress_numbers_path_element.set_attribute("d", "m 4 6.5 l 0.5 -0.8 v 2 z")
	pathdata_compress_numbers_path_element.set_attribute("fill", "gold")
	pathdata_compress_numbers_root_element.insert_child(0, pathdata_compress_numbers_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			pathdata_compress_numbers_root_element, true))
	
	current_setup_setting = "pathdata_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	var pathdata_minimize_spacing_root_element := ElementRoot.new()
	var pathdata_minimize_spacing_path_element := ElementPath.new()
	pathdata_minimize_spacing_path_element.set_attribute("d", "m 4 6.5 l 0.5 -0.8 v 2 z")
	pathdata_minimize_spacing_path_element.set_attribute("fill", "gold")
	pathdata_minimize_spacing_root_element.insert_child(0, pathdata_minimize_spacing_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			pathdata_minimize_spacing_root_element, true))
	
	current_setup_setting = "pathdata_remove_spacing_after_flags"
	add_checkbox(Translator.translate("Remove spacing after flags"))
	var pathdata_remove_spacing_after_flags_root_element := ElementRoot.new()
	var pathdata_remove_spacing_after_flags_path_element := ElementPath.new()
	pathdata_remove_spacing_after_flags_path_element.set_attribute("d", "m 1 3.5 a 2 3 0 1 0 4 2 z")
	pathdata_remove_spacing_after_flags_path_element.set_attribute("fill", "gold")
	pathdata_remove_spacing_after_flags_root_element.insert_child(0, pathdata_remove_spacing_after_flags_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			pathdata_remove_spacing_after_flags_root_element, true))
	
	current_setup_setting = "pathdata_remove_consecutive_commands"
	add_checkbox(Translator.translate("Remove consecutive commands"))
	var pathdata_remove_consecutive_commands_root_element := ElementRoot.new()
	var pathdata_remove_consecutive_commands_path_element := ElementPath.new()
	pathdata_remove_consecutive_commands_path_element.set_attribute("d",
			"m 4 6.5 l -1 2 l 2.5 1 q 3.5 -1 2 -2 q -1.5 0.5 -1 -2 z")
	pathdata_remove_consecutive_commands_path_element.set_attribute("fill", "gold")
	pathdata_remove_consecutive_commands_root_element.insert_child(0, pathdata_remove_consecutive_commands_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			pathdata_remove_consecutive_commands_root_element, true))
	
	add_section(Translator.translate("Transform lists"))
	current_setup_setting = "transform_list_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	var transform_list_compress_numbers_root_element := ElementRoot.new()
	var transform_list_compress_numbers_polygon_element := ElementPolygon.new()
	transform_list_compress_numbers_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_compress_numbers_polygon_element.set_attribute("fill", "gold")
	transform_list_compress_numbers_polygon_element.set_attribute("transform",
			"rotate(7.5 -0.5 0.8)")
	transform_list_compress_numbers_root_element.insert_child(0, transform_list_compress_numbers_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			transform_list_compress_numbers_root_element, true))
	
	current_setup_setting = "transform_list_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	var transform_list_minimize_spacing_root_element := ElementRoot.new()
	var transform_list_minimize_spacing_polygon_element := ElementPolygon.new()
	transform_list_minimize_spacing_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_minimize_spacing_polygon_element.set_attribute("fill", "gold")
	transform_list_minimize_spacing_polygon_element.set_attribute("transform",
			"rotate(7.5 -0.5 0.8)")
	transform_list_minimize_spacing_root_element.insert_child(0, transform_list_minimize_spacing_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			transform_list_minimize_spacing_root_element, true))
	
	current_setup_setting = "transform_list_remove_unnecessary_params"
	add_checkbox(Translator.translate("Remove unnecessary parameters"))
	var transform_list_remove_unnecessary_params_root_element := ElementRoot.new()
	var transform_list_remove_unnecessary_params_polygon_element := ElementPolygon.new()
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("fill", "gold")
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("transform",
			"scale(2 2) translate(4 0) rotate(30 0 0)")
	transform_list_remove_unnecessary_params_root_element.insert_child(0, transform_list_remove_unnecessary_params_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_resource,
			transform_list_remove_unnecessary_params_root_element, true))

func setup_theming_content() -> void:
	var current_setup_resource := Configs.savedata
	
	current_setup_setting = "theme_preset"
	add_profile_picker(Translator.translate("Theme preset"),
			current_setup_resource.reset_theme_items_to_default,
			SaveData.ThemePreset.size(), SaveData.get_theme_preset_value_text_map(),
			current_setup_resource.is_theming_default)
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the default values of theming-related settings, including the highlighter preset.")))
	
	add_section(Translator.translate("Primary theme colors"))
	current_setup_setting = "base_color"
	add_color_edit(Translator.translate("Base color"), false)
	current_setup_setting = "accent_color"
	add_color_edit(Translator.translate("Accent color"), false)
	
	add_section(Translator.translate("SVG Text colors"))
	current_setup_setting = "highlighter_preset"
	add_profile_picker(Translator.translate("Highlighter preset"),
			current_setup_resource.reset_highlighting_items_to_default,
			SaveData.HighlighterPreset.size(),
			SaveData.get_highlighter_preset_value_text_map(),
			current_setup_resource.is_highlighting_default)
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the default values of SVG highlighter settings.")))
	current_setup_setting = "highlighting_symbol_color"
	add_color_edit(Translator.translate("Symbol color"))
	add_preview(SettingCodePreview.new(
			"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
	current_setup_setting = "highlighting_element_color"
	add_color_edit(Translator.translate("Element color"))
	add_preview(SettingCodePreview.new(
			"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
	current_setup_setting = "highlighting_attribute_color"
	add_color_edit(Translator.translate("Attribute color"))
	add_preview(SettingCodePreview.new(
			"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
	current_setup_setting = "highlighting_string_color"
	add_color_edit(Translator.translate("String color"))
	add_preview(SettingCodePreview.new(
			"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
	current_setup_setting = "highlighting_comment_color"
	add_color_edit(Translator.translate("Comment color"))
	add_preview(SettingCodePreview.new(
			"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
	current_setup_setting = "highlighting_text_color"
	add_color_edit(Translator.translate("Text color"))
	add_preview(SettingCodePreview.new(
			"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
	current_setup_setting = "highlighting_cdata_color"
	add_color_edit(Translator.translate("CDATA color"))
	add_preview(SettingCodePreview.new(
			"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
	current_setup_setting = "highlighting_error_color"
	add_color_edit(Translator.translate("Error color"))
	add_preview(SettingCodePreview.new(
			"""<circle cx="6" cy="8" ==syntax error"""))
	
	add_section(Translator.translate("Handles"))
	current_setup_setting = "handle_size"
	add_number_dropdown(Translator.translate("Size"),
			[0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0], false, false,
			SaveData.HANDLE_SIZE_MIN, SaveData.HANDLE_SIZE_MAX)
	current_setup_setting = "handle_inner_color"
	add_color_edit(Translator.translate("Inside color"), false)
	current_setup_setting = "handle_color"
	add_color_edit(Translator.translate("Normal color"), false)
	current_setup_setting = "handle_hovered_color"
	add_color_edit(Translator.translate("Hovered color"), false)
	current_setup_setting = "handle_selected_color"
	add_color_edit(Translator.translate("Selected color"), false)
	current_setup_setting = "handle_hovered_selected_color"
	add_color_edit(Translator.translate("Hovered selected color"), false)
	
	add_section(Translator.translate("Selection rectangle"))
	current_setup_setting = "selection_rectangle_speed"
	add_number_dropdown(Translator.translate("Speed"),
			[0.0, 10.0, 20.0, 30.0, 50.0, 80.0, 130.0], false, false,
			-SaveData.MAX_SELECTION_RECTANGLE_SPEED,
			SaveData.MAX_SELECTION_RECTANGLE_SPEED)
	current_setup_setting = "selection_rectangle_width"
	add_number_dropdown(Translator.translate("Width"),
			[1.0, 2.0, 3.0, 4.0], false, false, 1.0,
			SaveData.MAX_SELECTION_RECTANGLE_WIDTH)
	current_setup_setting = "selection_rectangle_dash_length"
	add_number_dropdown(Translator.translate("Dash length"),
			[5.0, 10.0, 15.0, 20.0], false, false, 1.0,
			SaveData.MAX_SELECTION_RECTANGLE_DASH_LENGTH)
	current_setup_setting = "selection_rectangle_color1"
	add_color_edit(Translator.translate("Color {index}").format({"index": "1"}))
	current_setup_setting = "selection_rectangle_color2"
	add_color_edit(Translator.translate("Color {index}").format({"index": "2"}))
	
	add_section(Translator.translate("Basic colors"))
	current_setup_setting = "canvas_color"
	add_color_edit(Translator.translate("Canvas color"), false)
	current_setup_setting = "grid_color"
	add_color_edit(Translator.translate("Grid color"), false)
	
	current_setup_setting = "basic_color_valid"
	add_color_edit(Translator.translate("Valid color"))
	add_preview(SettingBasicColorPreview.new(current_setup_setting,
			Translator.translate("Valid color")))
	
	current_setup_setting = "basic_color_error"
	add_color_edit(Translator.translate("Error color"))
	add_preview(SettingBasicColorPreview.new(current_setup_setting,
			Translator.translate("Error color")))
	
	current_setup_setting = "basic_color_warning"
	add_color_edit(Translator.translate("Warning color"))
	add_preview(SettingBasicColorPreview.new(current_setup_setting,
			Translator.translate("Warning color")))

func setup_tab_bar_content() -> void:
	add_section(Translator.translate("Input"))
	current_setup_setting = "tab_mmb_close"
	add_checkbox(Translator.translate("Close tabs with middle mouse button"))
	add_preview(SettingTextPreview.new(
			Translator.translate("When enabled, clicking on a tab with the middle mouse button closes it instead of simply focusing it.")))

func setup_other_content() -> void:
	add_section(Translator.translate("Input"))
	current_setup_setting = "invert_zoom"
	add_checkbox(Translator.translate("Invert zoom direction"))
	add_preview(SettingTextPreview.new(
			Translator.translate("Swaps the scroll directions for zooming in and zooming out.")))
	current_setup_setting = "wraparound_panning"
	var wraparound_panning := add_checkbox(Translator.translate("Wrap-around panning"))
	var wraparound_panning_forced_off := not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP)
	add_preview(SettingTextPreview.new(Translator.translate(
			"Warps the cursor to the opposite side whenever it reaches a viewport boundary while panning."),
			SettingTextPreview.get_platform_availability_warning(wraparound_panning_forced_off)))
	# Disable mouse wrap if not available.
	if wraparound_panning_forced_off:
		wraparound_panning.permanent_disable_checkbox(false)
	
	current_setup_setting = "use_ctrl_for_zoom"
	add_checkbox(Translator.translate("Use CTRL for zooming"))
	add_preview(SettingTextPreview.new(
			Translator.translate("When enabled, scrolling pans the view instead of zooming in. To zoom, hold CTRL while scrolling.")))
	
	add_section(Translator.translate("Display"))
	# Prepare parameters for the UI scale setting.
	var usable_screen_size := HandlerGUI.get_usable_rect()
	var min_ui_scale := HandlerGUI.get_min_ui_scale(usable_screen_size)
	var max_ui_scale := HandlerGUI.get_max_ui_scale(usable_screen_size)
	var dropdown_values := [SaveData.ScalingApproach.AUTO]
	if min_ui_scale <= 0.75 and 0.75 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_075)
	if min_ui_scale <= 1.0 and 1.0 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_100)
	if min_ui_scale <= 1.25 and 1.25 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_125)
	if min_ui_scale <= 1.5 and 1.5 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_150)
	if min_ui_scale <= 1.75 and 1.75 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_175)
	if min_ui_scale <= 2.0 and 2.0 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_200)
	if min_ui_scale <= 2.5 and 2.5 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_250)
	if min_ui_scale <= 3.0 and 3.0 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_300)
	if min_ui_scale <= 4.0 and 4.0 <= max_ui_scale:
		dropdown_values.append(SaveData.ScalingApproach.CONSTANT_400)
	dropdown_values.append(SaveData.ScalingApproach.MAX)
	# Dictionary[SaveData.ScalingApproach, String]
	var dropdown_map: Dictionary = {
		SaveData.ScalingApproach.AUTO: "Auto (%d%%)" % (HandlerGUI.get_auto_ui_scale() * 100),
		SaveData.ScalingApproach.CONSTANT_075: "75%",
		SaveData.ScalingApproach.CONSTANT_100: "100%",
		SaveData.ScalingApproach.CONSTANT_125: "125%",
		SaveData.ScalingApproach.CONSTANT_150: "150%",
		SaveData.ScalingApproach.CONSTANT_175: "175%",
		SaveData.ScalingApproach.CONSTANT_200: "200%",
		SaveData.ScalingApproach.CONSTANT_250: "250%",
		SaveData.ScalingApproach.CONSTANT_300: "300%",
		SaveData.ScalingApproach.CONSTANT_400: "400%",
		SaveData.ScalingApproach.MAX: "Max (%d%%)" % (max_ui_scale * 100),
	}
	
	current_setup_setting = "ui_scale"
	add_dropdown(Translator.translate("UI scale"), dropdown_values, dropdown_map)
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the scale factor for the interface.")))
	
	current_setup_setting = "vsync"
	add_checkbox(Translator.translate("V-Sync"))
	add_preview(SettingTextPreview.new(
			Translator.translate("Synchronizes graphics rendering with display refresh rate to prevent screen tearing artifacts. May increase input lag slightly.")))
	
	current_setup_setting = "max_fps"
	add_fps_limit_dropdown(Translator.translate("Maximum FPS"))
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the maximum number of frames per second.")))
	
	current_setup_setting = "keep_screen_on"
	var keep_screen_on := add_checkbox(Translator.translate("Keep Screen On"))
	var keep_screen_on_forced_off := OS.has_feature("web")
	add_preview(SettingTextPreview.new(Translator.translate(
			"Keeps the screen on even after inactivity, so the screensaver does not take over."),
			SettingTextPreview.get_platform_availability_warning(keep_screen_on_forced_off)))
	if keep_screen_on_forced_off:
		keep_screen_on.permanent_disable_checkbox(false)
	
	add_section(Translator.translate("Miscellaneous"))
	current_setup_setting = "use_native_file_dialog"
	var use_native_file_dialog := add_checkbox(Translator.translate("Use native file dialog"))
	var use_native_file_dialog_forced_on := OS.has_feature("web")
	var use_native_file_dialog_forced_off :=\
			(not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE))
	add_preview(SettingTextPreview.new(Translator.translate(
			"When enabled, uses your operating system's native file dialog instead of GodSVG's built-in one."),
			SettingTextPreview.get_platform_availability_warning(
			use_native_file_dialog_forced_on or use_native_file_dialog_forced_off)))
	# Disable fallback file dialog on web, and native file dialog if not available.
	if use_native_file_dialog_forced_on:
		use_native_file_dialog.permanent_disable_checkbox(true)
	elif use_native_file_dialog_forced_off:
		use_native_file_dialog.permanent_disable_checkbox(false)
	
	current_setup_setting = "use_filename_for_window_title"
	add_checkbox(Translator.translate("Sync window title to file name"))
	add_preview(SettingTextPreview.new(
			Translator.translate("When enabled, adds the current file name before the \"GodSVG\" window title.")))


func add_section(section_name: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.theme_type_variation = "TitleLabel"
	label.text = section_name
	vbox.add_child(label)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2
	vbox.add_child(spacer)
	setting_container.add_child(vbox)

func add_profile_picker(text: String, application_callback: Callable, profile_count: int,
value_text_map: Dictionary, disabled_check_callback: Callable) -> void:
	var frame := ProfileFrameScene.instantiate()
	frame.text = text
	setup_frame(frame, false)
	frame.setup_dropdown(range(profile_count), value_text_map)
	frame.disabled_check_callback = disabled_check_callback
	frame.value_changed.connect.call_deferred(setup_content)
	frame.defaults_applied.connect(application_callback)
	frame.defaults_applied.connect(setup_content)
	add_frame(frame)
	
	var resource_permanent_ref := _get_current_setup_resource()
	resource_permanent_ref.changed_deferred.connect(frame.button_update_disabled)
	frame.tree_exited.connect(resource_permanent_ref.changed_deferred.disconnect.bind(
			frame.button_update_disabled), CONNECT_ONE_SHOT)

func add_checkbox(text: String, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_checkbox()
	add_frame(frame)
	# Some checkboxes need to update the dimness of the text of other settings.
	# There's no continuous editing with checkboxes, so it's safe to just rebuild
	# the content for them.
	frame.value_changed.connect(setup_content)
	return frame

# TODO Typed Dictionary wonkiness
func add_dropdown(text: String, values: Array[Variant],
value_text_map: Dictionary) -> Control:  # Dictionary[Variant, String]
	var frame := SettingFrameScene.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_dropdown(values, value_text_map)
	add_frame(frame)
	# Some checkboxes need to update the dimness of the text of other settings.
	# There's no continuous editing with checkboxes, so it's safe to just rebuild
	# the content for them.
	frame.value_changed.connect(setup_content)
	return frame

func add_number_dropdown(text: String, values: Array[float], is_integer := false,
restricted := true, min_value := -INF, max_value := INF, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_number_dropdown(values, is_integer, restricted, min_value, max_value)
	add_frame(frame)
	return frame

func add_fps_limit_dropdown(text: String, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_fps_limit_dropdown()
	add_frame(frame)
	return frame

func add_color_edit(text: String, enable_alpha := true) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_color(enable_alpha)
	add_frame(frame)
	return frame

func setup_frame(frame: Control, has_default := true) -> void:
	var bind := current_setup_setting
	var resource_ref := _get_current_setup_resource()
	frame.setter = func(p: Variant) -> void: resource_ref.set(bind, p)
	frame.getter = resource_ref.get.bind(bind)
	if has_default:
		frame.default = resource_ref.get_setting_default(current_setup_setting)
	frame.mouse_entered.connect(set_preview.bind(current_setup_setting))
	frame.mouse_exited.connect(remove_preview.bind(current_setup_setting))

func add_frame(frame: Control) -> void:
	if setting_container.get_child_count() > 0:
		setting_container.get_child(-1).add_child(frame)
	else:
		setting_container.add_child(frame)


func add_preview(preview: RefCounted) -> void:
	previews[current_setup_setting] = preview

func set_preview(setting: String) -> void:
	current_previewed_setting = setting
	emit_preview_changed()

func remove_preview(setting: String) -> void:
	if current_previewed_setting == setting:
		current_previewed_setting = ""
		emit_preview_changed()

func emit_preview_changed() -> void:
	if current_previewed_setting.is_empty() or not previews.has(current_previewed_setting):
		preview_changed.emit(Control.new())
		return
	
	var preview := previews[current_previewed_setting]
	if preview is SettingBasicColorPreview:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var update_label_font_color := func() -> void:
				label.add_theme_color_override("font_color",
						Configs.savedata.get(preview.setting_bind))
		Configs.basic_colors_changed.connect(update_label_font_color)
		label.tree_exiting.connect(Configs.basic_colors_changed.disconnect.bind(
				update_label_font_color), CONNECT_ONE_SHOT)
		update_label_font_color.call()
		label.text = preview.text
		preview_changed.emit(label)
	if preview is SettingTextPreview:
		var has_warning: bool = (preview.warning != preview.WarningType.NONE)
		var margin_container := MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 6)
		margin_container.add_theme_constant_override("margin_right", 6)
		margin_container.add_theme_constant_override("margin_top", 2)
		margin_container.add_theme_constant_override("margin_bottom", 4)
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.add_theme_constant_override("line_spacing", 2)
		label.text = preview.text
		var preview_font_size := get_theme_font_size("font_size", "Label")
		while label.get_line_count() >= (2 if has_warning else 3):
			preview_font_size -= 1
			label.add_theme_font_size_override("font_size", preview_font_size)
		if has_warning:
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 2)
			var no_effect_warning_label := Label.new()
			no_effect_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			no_effect_warning_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			no_effect_warning_label.add_theme_constant_override("line_spacing", 2)
			no_effect_warning_label.add_theme_color_override("font_color",
					Configs.savedata.basic_color_warning)
			match preview.warning:
				preview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION:
					no_effect_warning_label.text = Translator.translate(
							"The setting has no effect in the current configuration.")
				preview.WarningType.NOT_AVAILABLE_ON_PLATFORM:
					no_effect_warning_label.text = Translator.translate(
							"The setting can't be changed on this platform.")
				_:
					no_effect_warning_label.text = ""
			while no_effect_warning_label.get_line_count() >= 2:
				preview_font_size -= 1
				no_effect_warning_label.add_theme_font_size_override("font_size",
						preview_font_size)
				label.add_theme_font_size_override("font_size", preview_font_size)
			if not preview.text.is_empty():
				vbox.add_child(label)
			vbox.add_child(no_effect_warning_label)
			margin_container.add_child(vbox)
		else:
			margin_container.add_child(label)
		preview_changed.emit(margin_container)
	elif preview is SettingCodePreview:
		var code_preview := BetterTextEdit.new()
		code_preview.editable = false
		var update_highlighter := func() -> void:
				code_preview.syntax_highlighter = SVGHighlighter.new()
		code_preview.add_theme_color_override("font_readonly_color", Color.WHITE)
		
		var text_edit_default_stylebox := code_preview.get_theme_stylebox("normal")
		var empty_stylebox := StyleBoxEmpty.new()
		empty_stylebox.content_margin_left = text_edit_default_stylebox.content_margin_left
		empty_stylebox.content_margin_right = text_edit_default_stylebox.content_margin_right
		empty_stylebox.content_margin_top = text_edit_default_stylebox.content_margin_top
		empty_stylebox.content_margin_bottom = text_edit_default_stylebox.content_margin_bottom
		code_preview.add_theme_stylebox_override("normal", empty_stylebox)
		code_preview.add_theme_stylebox_override("read_only", empty_stylebox)
		code_preview.text = preview.text
		Configs.highlighting_colors_changed.connect(update_highlighter)
		code_preview.tree_exiting.connect(Configs.highlighting_colors_changed.disconnect.bind(
				update_highlighter), CONNECT_ONE_SHOT)
		update_highlighter.call()
		preview_changed.emit(code_preview)
	elif preview is SettingFormatterPreview:
		var code_preview := BetterTextEdit.new()
		code_preview.editable = false
		
		var update_highlighter := func() -> void:
				code_preview.syntax_highlighter = SVGHighlighter.new()
		
		var update_text := func() -> void:
				if preview.show_only_children:
					code_preview.text = SVGParser.root_children_to_text(
							preview.root_element, preview.resource_bind)
				else:
					code_preview.text = SVGParser.root_to_text(
							preview.root_element, preview.resource_bind)
		
		code_preview.add_theme_color_override("font_readonly_color", Color.WHITE)
		var text_edit_default_stylebox := code_preview.get_theme_stylebox("normal")
		var empty_stylebox := StyleBoxEmpty.new()
		empty_stylebox.content_margin_left = text_edit_default_stylebox.content_margin_left
		empty_stylebox.content_margin_right = text_edit_default_stylebox.content_margin_right
		empty_stylebox.content_margin_top = text_edit_default_stylebox.content_margin_top
		empty_stylebox.content_margin_bottom = text_edit_default_stylebox.content_margin_bottom
		code_preview.add_theme_stylebox_override("normal", empty_stylebox)
		code_preview.add_theme_stylebox_override("read_only", empty_stylebox)
		Configs.highlighting_colors_changed.connect(update_highlighter)
		code_preview.tree_exiting.connect(Configs.highlighting_colors_changed.disconnect.bind(
				update_highlighter), CONNECT_ONE_SHOT)
		update_highlighter.call()
		preview.resource_bind.changed_deferred.connect(update_text)
		code_preview.tree_exiting.connect(preview.resource_bind.changed_deferred.disconnect.bind(
				update_text), CONNECT_ONE_SHOT)
		update_text.call()
		# TODO Impressively, all this is necessary for scrollbars to work.
		# TextEdit is so damn janky.
		code_preview.hide()
		code_preview.show()
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(code_preview) and\
		not is_zero_approx(code_preview.get_v_scroll_bar().max_value):
			var tw := code_preview.create_tween().set_loops()
			tw.tween_interval(1.75)
			tw.tween_property(code_preview.get_v_scroll_bar(), ^"value",
					floorf(code_preview.get_v_scroll_bar().max_value -\
					code_preview.get_visible_line_count()), 0.5)
			tw.tween_interval(1.75)
			tw.tween_property(code_preview.get_v_scroll_bar(), ^"value", 0.0, 0.5)
		preview_changed.emit(code_preview)
