# An editor to be tied to an enum attribute.
extends Dropdown

var element: Element
var attribute_name: String  # May propagate.

const reload_icon = preload("res://assets/icons/Reload.svg")

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	add_theme_font_override("font", ThemeUtils.mono_font)
	super()
	Configs.basic_colors_changed.connect(sync)
	sync()
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.PROPAGATED_ATTRIBUTES:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	tooltip_text = attribute_name
	Configs.theme_changed.connect(check_placeholder_logic)
	check_placeholder_logic()

func check_placeholder_logic() -> void:
	if element.has_attribute(attribute_name):
		remove_theme_color_override("font_color")
	else:
		add_theme_color_override("font_color", get_theme_color("font_placeholder_color", "LineEdit"))
		set_text(element.get_default(attribute_name))


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		check_placeholder_logic()
		sync()


func _get_dropdown_buttons() -> Array[ContextButton]:
	var btn_arr: Array[ContextButton] = []
	# Add a default.
	var reset_btn := ContextButton.create_custom("", set_value.bind("", true), reload_icon,
			element.get_attribute_value(attribute_name).is_empty())
	reset_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_arr.append(reset_btn)
	# Add a button for each enum value.
	for enum_constant in DB.ATTRIBUTE_ENUM_VALUES[attribute_name]:
		var btn := ContextButton.create_custom(enum_constant, set_value.bind(enum_constant, true), null,
				enum_constant == element.get_attribute_value(attribute_name))
		if enum_constant == element.get_default(attribute_name):
			btn.add_theme_font_override("font", ThemeUtils.bold_font)
		btn_arr.append(btn)
	return btn_arr


func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or new_text in DB.ATTRIBUTE_ENUM_VALUES[attribute_name]:
		set_value(new_text, true)
	else:
		sync()

func _on_text_changed(new_text: String) -> void:
	line_edit.add_theme_color_override("font_color", Configs.savedata.get_validity_color(not new_text in DB.ATTRIBUTE_ENUM_VALUES[attribute_name]))

func _get_line_edit_activation_text() -> String:
	return element.get_attribute_value(attribute_name)


func sync() -> void:
	var new_value := element.get_attribute_value(attribute_name)
	set_text(new_value)
	if new_value == element.get_default(attribute_name):
		add_theme_color_override("font_color", Configs.savedata.basic_color_warning)
	else:
		check_placeholder_logic()

func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.add_theme_font_override("font", ThemeUtils.mono_font)
	label.text = for_text
	return label
