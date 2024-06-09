# An editor to be tied to a numeric attribute.
extends BetterLineEdit

var element: Element
const attribute_name = "id"  # Never propagates.

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		sync(new_value)
	element.set_attribute(attribute_name, new_value)
	if save:
		SVG.queue_save()


func _ready() -> void:
	set_value(element.get_attribute_value(attribute_name, true))
	element.attribute_changed.connect(_on_element_attribute_changed)
	text_changed.connect(_on_text_changed)
	text_submitted.connect(set_value.bind(true))
	text_change_canceled.connect(_on_text_change_canceled)
	focus_entered.connect(_on_focus_entered)
	tooltip_text = attribute_name

func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(element.get_attribute_value(attribute_name, true))

func _on_focus_entered() -> void:
	remove_theme_color_override("font_color")

func _on_text_change_canceled() -> void:
	sync(element.get_attribute_value(attribute_name))

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
