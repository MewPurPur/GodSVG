# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var element: Element
const attribute_name = "id"  # Never propagates.

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync_to_attribute()
	if save:
		State.queue_svg_save()

func sync_to_attribute() -> void:
	sync(element.get_attribute_value(attribute_name))


func _ready() -> void:
	Configs.basic_colors_changed.connect(resync)
	sync_to_attribute()
	element.attribute_changed.connect(_on_element_attribute_changed)
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	text_change_canceled.connect(sync_to_attribute)
	focus_entered.connect(_on_focus_entered)
	tooltip_text = attribute_name

func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync_to_attribute()

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or\
	AttributeID.get_validity(new_text) != AttributeID.ValidityLevel.INVALID:
		set_value(new_text, true)
	else:
		sync_to_attribute()

func _on_text_changed(new_text: String) -> void:
	var validity_level := AttributeID.get_validity(new_text)
	var font_color := Configs.savedata.get_validity_color(
			validity_level == AttributeID.ValidityLevel.INVALID,
			validity_level == AttributeID.ValidityLevel.INVALID_XML_NAMETOKEN)
	add_theme_color_override("font_color", font_color)

func resync() -> void:
	sync(text)

func sync(new_value: String) -> void:
	text = new_value
	remove_theme_color_override("font_color")
