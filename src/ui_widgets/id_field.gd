# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var element: Element
const attribute_name = "id"  # Never propagates.

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	Configs.basic_colors_changed.connect(sync)
	sync()
	element.attribute_changed.connect(_on_element_attribute_changed)
	text_changed.connect(_on_text_changed)
	setup_font()
	text_submitted.connect(_on_text_submitted)
	text_change_canceled.connect(sync)
	focus_entered.connect(_on_focus_entered)
	tooltip_text = attribute_name

func sync_localization() -> void:
	placeholder_text = Translator.translate("No ID")

func setup_font() -> void:
	if text.is_empty():
		add_theme_font_override("font", ThemeUtils.main_font)
	else:
		remove_theme_font_override("font")


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or AttributeID.get_validity(new_text) != Attribute.NameValidityLevel.INVALID:
		set_value(new_text, true)
	else:
		sync()

func _on_text_changed(new_text: String) -> void:
	var validity_level := AttributeID.get_validity(new_text)
	var font_color := Configs.savedata.get_validity_color(
			validity_level == Attribute.NameValidityLevel.INVALID,
			validity_level == Attribute.NameValidityLevel.INVALID_XML_NAMETOKEN)
	add_theme_color_override("font_color", font_color)
	setup_font()

func sync() -> void:
	text = element.get_attribute_value(attribute_name)
	remove_theme_color_override("font_color")
	setup_font()
