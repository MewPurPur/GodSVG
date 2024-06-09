# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var tag: Tag
var attribute_name: String

func set_value(new_value: String, save := true) -> void:
	var attribute := tag.get_attribute(attribute_name)
	if not new_value.is_empty():
		sync(attribute.format(new_value))
	
	# Update the attribute.
	if attribute.get_value() != new_value:
		attribute.set_value(new_value, save)


func _ready() -> void:
	super()
	var attribute: AttributeID = tag.get_attribute(attribute_name)
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute_name
	placeholder_text = tag.get_default(attribute_name)
	text_submitted.connect(set_value)

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func _on_text_change_canceled() -> void:
	sync(tag.get_attribute(attribute_name).get_value())

func _on_text_changed(new_text: String) -> void:
	var validity_level := IDParser.get_validity(new_text)
	var font_color := GlobalSettings.get_validity_color(
			validity_level == IDParser.ValidityLevel.INVALID,
			validity_level == IDParser.ValidityLevel.INVALID_XML_NAMETOKEN)
	add_theme_color_override("font_color", font_color)

func sync(new_value: String) -> void:
	text = new_value
	remove_theme_color_override("font_color")

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)
