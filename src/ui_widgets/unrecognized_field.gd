# An editor to be tied to an attribute GodSVG can't recognize, allowing to still edit it.
extends BetterLineEdit

var element: Element
var attribute_name: String  # Assume it doesn't propagate.

func set_value(new_value: String, save := false) -> void:
	sync(new_value)
	element.set_attribute(attribute_name, new_value)
	if save:
		State.queue_svg_save()

func sync_to_attribute() -> void:
	set_value(element.get_attribute_value(attribute_name, true))


func _ready() -> void:
	Configs.language_changed.connect(update_translation)
	sync_to_attribute()
	update_translation()
	text_submitted.connect(set_value.bind(true))

func sync(new_value: String) -> void:
	text = new_value

func update_translation() -> void:
	tooltip_text = attribute_name + "\n(%s)" %\
			Translator.translate("GodSVG doesn’t recognize this attribute")
