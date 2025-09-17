# An editor to be tied to an attribute GodSVG can't recognize, allowing to still edit it.
extends BetterLineEdit

var element: Element
var attribute_name: String  # Assume it doesn't propagate.

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	sync()
	sync_localization()
	text_submitted.connect(set_value.bind(true))

func sync() -> void:
	text = element.get_attribute_value(attribute_name)

func sync_localization() -> void:
	tooltip_text = attribute_name + "\n(%s)" % Translator.translate("GodSVG doesn’t recognize this attribute")
